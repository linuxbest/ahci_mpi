/*
 *  libahci.c - Common AHCI SATA low-level routines
 *
 *  Maintained by:  Jeff Garzik <jgarzik@pobox.com>
 *    		    Please ALWAYS copy linux-ide@vger.kernel.org
 *		    on emails.
 *
 *  Copyright 2004-2005 Red Hat, Inc.
 *
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 *
 * libata documentation is available via 'make {ps|pdf}docs',
 * as Documentation/DocBook/libata.*
 *
 * AHCI hardware documentation:
 * http://www.intel.com/technology/serialata/pdf/rev1_0.pdf
 * http://www.intel.com/technology/serialata/pdf/rev1_1.pdf
 *
 */
#define DEBUG
#include <linux/kernel.h>
#include <linux/gfp.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/blkdev.h>
#include <linux/delay.h>
#include <linux/interrupt.h>
#include <linux/dma-mapping.h>
#include <linux/device.h>
#include <scsi/scsi_host.h>
#include <scsi/scsi_cmnd.h>
#include <linux/libata.h>
#include <linux/kthread.h>

#include "ahci_mpi.h"
#include "ahci_mpi_fw.h"

static int node_detect (void *data);
static int ahci_scr_read(struct ata_link *link, unsigned int sc_reg, u32 *val);
static int ahci_scr_write(struct ata_link *link, unsigned int sc_reg, u32 val);
static unsigned int ahci_qc_issue(struct ata_queued_cmd *qc);
static bool ahci_qc_fill_rtf(struct ata_queued_cmd *qc);
static int ahci_port_start(struct ata_port *ap);
static void ahci_port_stop(struct ata_port *ap);
static void ahci_qc_prep(struct ata_queued_cmd *qc);
static int ahci_pmp_qc_defer(struct ata_queued_cmd *qc);
static void ahci_freeze(struct ata_port *ap);
static void ahci_thaw(struct ata_port *ap);
static void ahci_enable_fbs(struct ata_port *ap);
static void ahci_disable_fbs(struct ata_port *ap);
static void ahci_pmp_attach(struct ata_port *ap);
static void ahci_pmp_detach(struct ata_port *ap);
static int ahci_softreset(struct ata_link *link, unsigned int *class,
			  unsigned long deadline);
static int ahci_hardreset(struct ata_link *link, unsigned int *class,
			  unsigned long deadline);
static void ahci_postreset(struct ata_link *link, unsigned int *class);
static void ahci_error_handler(struct ata_port *ap);
static void ahci_post_internal_cmd(struct ata_queued_cmd *qc);
static int ahci_port_resume(struct ata_port *ap);
static void ahci_fill_cmd_slot(struct ahci_port_priv *pp, unsigned int tag,
			       u32 opts);
static ssize_t ahci_show_host_caps(struct device *dev,
				   struct device_attribute *attr, char *buf);
static ssize_t ahci_show_host_cap2(struct device *dev,
				   struct device_attribute *attr, char *buf);
static ssize_t ahci_show_host_version(struct device *dev,
				      struct device_attribute *attr, char *buf);
static ssize_t ahci_show_port_cmd(struct device *dev,
				  struct device_attribute *attr, char *buf);
static ssize_t ahci_show_ctrl_reg(struct device *dev,
					  struct device_attribute *attr, char *buf);
static ssize_t ahci_store_ctrl_reg(struct device *dev, struct device_attribute *attr,
				  const char *buf, size_t count);

static DEVICE_ATTR(ahci_host_caps, S_IRUGO, ahci_show_host_caps, NULL);
static DEVICE_ATTR(ahci_host_cap2, S_IRUGO, ahci_show_host_cap2, NULL);
static DEVICE_ATTR(ahci_host_version, S_IRUGO, ahci_show_host_version, NULL);
static DEVICE_ATTR(ahci_port_cmd, S_IRUGO, ahci_show_port_cmd, NULL);
static DEVICE_ATTR(ahci_ctrl_reg, 0666, ahci_show_ctrl_reg, ahci_store_ctrl_reg);

static struct device_attribute *ahci_shost_attrs[] = {
	&dev_attr_link_power_management_policy,
	&dev_attr_em_message_type,
	&dev_attr_em_message,
	&dev_attr_ahci_host_caps,
	&dev_attr_ahci_host_cap2,
	&dev_attr_ahci_host_version,
	&dev_attr_ahci_port_cmd,
	&dev_attr_ahci_ctrl_reg,
	NULL
};

static struct device_attribute *ahci_sdev_attrs[] = {
	&dev_attr_unload_heads,
	NULL
};

struct scsi_host_template ahci_sht = {
	ATA_NCQ_SHT("ahci"),
	.can_queue		= AHCI_MAX_CMDS - 1,
	.sg_tablesize		= AHCI_MAX_SG,
	.dma_boundary		= AHCI_DMA_BOUNDARY,
	.shost_attrs		= ahci_shost_attrs,
	.sdev_attrs		= ahci_sdev_attrs,
};

struct ata_port_operations ahci_ops = {
	.inherits		= &sata_pmp_port_ops,

	.qc_defer		= ahci_pmp_qc_defer,
	.qc_prep		= ahci_qc_prep,
	.qc_issue		= ahci_qc_issue,
	.qc_fill_rtf		= ahci_qc_fill_rtf,

	.freeze			= ahci_freeze,
	.thaw			= ahci_thaw,
	.softreset		= ahci_softreset,
	.hardreset		= ahci_hardreset,
	.postreset		= ahci_postreset,
	.pmp_softreset		= ahci_softreset,
	.error_handler		= ahci_error_handler,
	.post_internal_cmd	= ahci_post_internal_cmd,

	.scr_read		= ahci_scr_read,
	.scr_write		= ahci_scr_write,
	.pmp_attach		= ahci_pmp_attach,
	.pmp_detach		= ahci_pmp_detach,

	.port_start		= ahci_port_start,
	.port_stop		= ahci_port_stop,
};

static ssize_t ahci_show_host_caps(struct device *dev,
				   struct device_attribute *attr, char *buf)
{
	struct Scsi_Host *shost = class_to_shost(dev);
	struct ata_port *ap = ata_shost_to_port(shost);
	struct ahci_host_priv *hpriv = ap->host->private_data;

	return sprintf(buf, "%x\n", hpriv->cap);
}

static ssize_t ahci_show_host_cap2(struct device *dev,
				   struct device_attribute *attr, char *buf)
{
	struct Scsi_Host *shost = class_to_shost(dev);
	struct ata_port *ap = ata_shost_to_port(shost);
	struct ahci_host_priv *hpriv = ap->host->private_data;

	return sprintf(buf, "%x\n", hpriv->cap2);
}

static ssize_t ahci_show_host_version(struct device *dev,
				   struct device_attribute *attr, char *buf)
{
	struct Scsi_Host *shost = class_to_shost(dev);
	struct ata_port *ap = ata_shost_to_port(shost);
	struct ahci_host_priv *hpriv = ap->host->private_data;
	void __iomem *mmio = hpriv->mmio;

	return sprintf(buf, "%x\n", readl(mmio + HOST_VERSION));
}

static ssize_t ahci_show_port_cmd(struct device *dev,
				  struct device_attribute *attr, char *buf)
{
	struct Scsi_Host *shost = class_to_shost(dev);
	struct ata_port *ap = ata_shost_to_port(shost);
	void __iomem *port_mmio = ahci_port_base(ap);

	return sprintf(buf, "%x\n", readl(port_mmio + PORT_CMD));
}

static ssize_t ahci_show_ctrl_reg(struct device *dev,
					  struct device_attribute *attr, char *buf)
{
	struct Scsi_Host *shost = class_to_shost(dev);
	struct ata_port *ap = ata_shost_to_port(shost);
	struct ahci_host_priv *hpriv = ap->host->private_data;
	void __iomem *mmio = hpriv->mmio;
	u8 res;

	res = readl(mmio + 0x30) >> (ap->port_no * 8);
	return sprintf(buf, "%x\n", res);
}

static ssize_t ahci_store_ctrl_reg(struct device *dev, struct device_attribute *attr,
				  const char *buf, size_t count)
{
	struct Scsi_Host *shost = class_to_shost(dev);
	struct ata_port *ap = ata_shost_to_port(shost);
	struct ahci_host_priv *hpriv = ap->host->private_data;
	void __iomem *mmio = hpriv->mmio;
	u8  val;
	u32 reg32_val;

	val = simple_strtol(buf, NULL, 16);
	/* set sim err bit
	 * 0x01 data fis crcerr
	 * 0x02 non-data fis crcerr */
	VPRINTK("Ctrl REG Val: %#x\n", val);
	reg32_val = readl(mmio + 0x30);
	reg32_val &= ~(0xff << (ap->port_no * 8));
	reg32_val |= (val << (ap->port_no * 8));
	out_be32(mmio + 0x30, reg32_val);

	return count;
}

static int ahci_scr_read(struct ata_link *link, unsigned int sc_reg, u32 *val)
{
	struct ahci_port_priv *pp = link->ap->private_data;
	int res = -EINVAL;
	
	*val = pp->regs[sc_reg];
	res = 0;
	
	VPRINTK("SCR_READ: %02x val %08x, res %d\n", sc_reg, *val, res);
	return res;
}

static int ahci_scr_write(struct ata_link *link, unsigned int sc_reg, u32 val)
{
	int res = -EINVAL;
	
	/* TODO */
	res = 0;
	
	VPRINTK("SCR_WRITE: %02x val %08x, res %d\n", sc_reg, val, res);
	return res;
}

static void ahci_start_engine(struct ata_port *ap)
{
	/*struct ahci_port_priv *pp = ap->private_data;*/
	struct sataMPI req;

	/* Used in FW, to fix the errorhandler,
	 * transport ERR_FatalTaskfile state to Ht_HostIdle
	 */
	VPRINTK("start engine\n");
	req.header = 0x200;

	ahci_mpi_to_fw(ap, &req);
}

static int ahci_stop_engine(struct ata_port *ap)
{
	VPRINTK("stop engine\n");
	/* TODO */
	return 0;
}

static void ahci_start_fis_rx(struct ata_port *ap)
{
	struct ahci_port_priv *pp = ap->private_data;
	struct sataMPI req;

	VPRINTK("start fis rx, slot dma %08x, rx fis %08x\n",
			(uint32_t)pp->cmd_slot_dma,
			(uint32_t)pp->rx_fis_dma);
	req.header = 0x3;
	req.d[0] = pp->cmd_slot_dma;
	req.d[1] = pp->rx_fis_dma;
	ahci_mpi_to_fw(ap, &req);
}

static int ahci_stop_fis_rx(struct ata_port *ap)
{
	VPRINTK("stop fis rx\n");
	/* TODO */
	return 0;
}

static void ahci_power_up(struct ata_port *ap)
{
	struct sataMPI req;

	VPRINTK("powerup\n");
	req.header = (0x10<<8);	/* startComm */
	ahci_mpi_to_fw(ap, &req);
}

static void ahci_start_port(struct ata_port *ap)
{
	/* enable FIS reception */
	ahci_start_fis_rx(ap);

	/* enable DMA */
	ahci_start_engine(ap);
}

static int ahci_deinit_port(struct ata_port *ap, const char **emsg)
{
	int rc;

	/* disable DMA */
	rc = ahci_stop_engine(ap);
	if (rc) {
		*emsg = "failed to stop engine";
		return rc;
	}

	/* disable FIS reception */
	rc = ahci_stop_fis_rx(ap);
	if (rc) {
		*emsg = "failed stop FIS RX";
		return rc;
	}

	return 0;
}

static void ahci_port_init(struct device *dev, struct ata_port *ap,
			   int port_no, void __iomem *mmio,
			   void __iomem *port_mmio)
{
	const char *emsg = NULL;
	int rc;

	/* make sure port is not active */
	rc = ahci_deinit_port(ap, &emsg);
	if (rc)
		dev_warn(dev, "%s (%d)\n", emsg, rc);
}

static void ahci_init_controller(struct ata_host *host)
{
	struct ahci_host_priv *hpriv = host->private_data;
	void __iomem *mmio = hpriv->mmio;
	int i;
	void __iomem *port_mmio;

	for (i = 0; i < host->n_ports; i++) {
		struct ata_port *ap = host->ports[i];

		port_mmio = ahci_port_base(ap);
		if (ata_port_is_dummy(ap))
			continue;

		ahci_port_init(host->dev, ap, i, mmio, port_mmio);
	}

	/* enable irq */
	out_be32(mmio + 0x4, 1);
}

static unsigned int ahci_dev_classify(struct ata_port *ap)
{
	struct ahci_port_priv *pp = ap->private_data;
	struct ata_taskfile tf;
	u32 tmp = pp->PxSIG;

	VPRINTK("dev classify\n");
	
	tf.lbah		= (tmp >> 24)	& 0xff;
	tf.lbam		= (tmp >> 16)	& 0xff;
	tf.lbal		= (tmp >> 8)	& 0xff;
	tf.nsect	= (tmp)		& 0xff;

	return ata_dev_classify(&tf);
}

static void ahci_fill_cmd_slot(struct ahci_port_priv *pp, unsigned int tag,
			       u32 opts)
{
	dma_addr_t cmd_tbl_dma;

	cmd_tbl_dma = pp->cmd_tbl_dma + tag * AHCI_CMD_TBL_SZ;

	pp->cmd_slot[tag].opts = cpu_to_be32(opts);
	pp->cmd_slot[tag].status = 0;
	pp->cmd_slot[tag].tbl_addr = cpu_to_be32(cmd_tbl_dma & 0xffffffff);
	pp->cmd_slot[tag].tbl_addr_hi = cpu_to_be32((cmd_tbl_dma >> 16) >> 16);
}

static int ahci_kick_engine(struct ata_port *ap)
{
	void __iomem *port_mmio = ahci_port_base(ap);
	struct ahci_host_priv *hpriv = ap->host->private_data;
	struct ahci_port_priv *pp = ap->private_data;
	u8 status = pp->PxTFD & 0xFF;
	u32 tmp;
	int busy, rc;
	
	VPRINTK("kick engine\n");
	/* stop engine */
	rc = ahci_stop_engine(ap);
	if (rc)
		goto out_restart;

	/* TODO */
	/* need to do CLO?
	 * always do CLO if PMP is attached (AHCI-1.3 9.2)
	 */
	busy = status & (ATA_BUSY | ATA_DRQ);
	if (!busy && !sata_pmp_attached(ap)) {
		rc = 0;
		goto out_restart;
	}

	if (!(hpriv->cap & HOST_CAP_CLO)) {
		rc = -EOPNOTSUPP;
		goto out_restart;
	}

	/* perform CLO */
	tmp = readl(port_mmio + PORT_CMD);
	tmp |= PORT_CMD_CLO;
	//writel(tmp, port_mmio + PORT_CMD);

	rc = 0;
	tmp = ata_wait_register(port_mmio + PORT_CMD,
				PORT_CMD_CLO, PORT_CMD_CLO, 1, 500);
	if (tmp & PORT_CMD_CLO)
		rc = -EIO;

	/* restart engine */
 out_restart:
	ahci_start_engine(ap);
	return rc;
}

static int ahci_exec_polled_cmd(struct ata_port *ap, int pmp,
				struct ata_taskfile *tf, int is_cmd, u16 flags,
				unsigned long timeout_msec)
{
	const u32 cmd_fis_len = 5; /* five dwords */
	struct ahci_port_priv *pp = ap->private_data;
	void __iomem *port_mmio = ahci_port_base(ap);
	u8 *fis = pp->cmd_tbl;
	u32 tmp;
	struct sataMPI req;
	
	DPRINTK("ENTER\n");
	
	/* prep the command */
	ata_tf_to_fis(tf, pmp, is_cmd, fis);
	ahci_fill_cmd_slot(pp, 0, cmd_fis_len | flags | (pmp << 12));
#ifdef DEBUG
	print_hex_dump(KERN_DEBUG, " fis :", DUMP_PREFIX_ADDRESS,
			16, 1, fis, cmd_fis_len*4, 1);
#endif
	/* issue & wait */
	req.header = 0x0101;	/* command */
	req.d[0]   = 1;		/* slot0 */
	req.d[1]   = 0;
	ahci_mpi_to_fw(ap, &req);

	if (timeout_msec) {
		/* TODO using local wait for PxCI clear */
		tmp = ata_wait_register(port_mmio + PORT_CMD_ISSUE, 0x1, 0x1,
					1, timeout_msec);
		if (tmp & 0x1) {
			ahci_kick_engine(ap);
			return -EBUSY;
		}
	}

	DPRINTK("EXIT\n");

	return 0;
}

static int ahci_do_softreset(struct ata_link *link, unsigned int *class,
		      int pmp, unsigned long deadline,
		      int (*check_ready)(struct ata_link *link))
{
	struct ata_port *ap = link->ap;
	struct ahci_host_priv *hpriv = ap->host->private_data;
	const char *reason = NULL;
	unsigned long now, msecs;
	struct ata_taskfile tf;
	int rc;

	DPRINTK("ENTER\n");

	/* prepare for SRST (AHCI-1.1 10.4.1) */
	rc = ahci_kick_engine(ap);
	if (rc && rc != -EOPNOTSUPP)
		ata_link_printk(link, KERN_WARNING,
				"failed to reset engine (errno=%d)\n", rc);

	ata_tf_init(link->device, &tf);

	/* issue the first D2H Register FIS */
	msecs = 0;
	now = jiffies;
	if (time_after(now, deadline))
		msecs = jiffies_to_msecs(deadline - now);

	tf.ctl |= ATA_SRST;
	if (ahci_exec_polled_cmd(ap, pmp, &tf, 0,
				 AHCI_CMD_RESET | AHCI_CMD_CLR_BUSY, msecs)) {
		rc = -EIO;
		reason = "1st FIS failed";
		goto fail;
	}

	/* spec says at least 5us, but be generous and sleep for 1ms */
	msleep(1);

	/* issue the second D2H Register FIS */
	tf.ctl &= ~ATA_SRST;
	ahci_exec_polled_cmd(ap, pmp, &tf, 0, 0, 0);

	/* wait for link to become ready */
	rc = ata_wait_after_reset(link, deadline, check_ready);
	if (rc == -EBUSY && hpriv->flags & AHCI_HFLAG_SRST_TOUT_IS_OFFLINE) {
		/*
		 * Workaround for cases where link online status can't
		 * be trusted.  Treat device readiness timeout as link
		 * offline.
		 */
		ata_link_printk(link, KERN_INFO,
				"device not ready, treating as offline\n");
		*class = ATA_DEV_NONE;
	} else if (rc) {
		/* link occupied, -ENODEV too is an error */
		reason = "device not ready";
		goto fail;
	} else
		*class = ahci_dev_classify(ap);

	DPRINTK("EXIT, class=%u\n", *class);
	return 0;

 fail:
	ata_link_printk(link, KERN_ERR, "softreset failed (%s)\n", reason);
	return rc;
}

static int ahci_check_ready(struct ata_link *link)
{
	struct ahci_port_priv *pp = link->ap->private_data;
	u8 status = pp->PxTFD & 0xFF;
	/* TODO */
	return ata_check_ready(status);
}

static int ahci_softreset(struct ata_link *link, unsigned int *class,
			  unsigned long deadline)
{
	int pmp = sata_srst_pmp(link);

	DPRINTK("ENTER\n");

	return ahci_do_softreset(link, class, pmp, deadline, ahci_check_ready);
}

static int ahci_hardreset(struct ata_link *link, unsigned int *class,
			  unsigned long deadline)
{
	const unsigned long *timing = sata_ehc_deb_timing(&link->eh_context);
	struct ata_port *ap = link->ap;
	struct ahci_port_priv *pp = ap->private_data;
	u8 *d2h_fis = pp->rx_fis + RX_FIS_D2H_REG;
	struct ata_taskfile tf;
	bool online;
	int rc;

	DPRINTK("ENTER\n");

	ahci_stop_engine(ap);

	/* clear D2H reception area to properly wait for D2H FIS */
	ata_tf_init(link->device, &tf);
	tf.command = 0x80;
	ata_tf_to_fis(&tf, 0, 0, d2h_fis);

	/* clear the SIG */
	pp->PxSIG = 0xffffffff;

	rc = sata_link_hardreset(link, timing, deadline, &online,
				 ahci_check_ready);

	ahci_start_engine(ap);

	if (online)
		*class = ahci_dev_classify(ap);

	DPRINTK("EXIT, rc=%d, class=%u\n", rc, *class);
	return rc;
}

static void ahci_postreset(struct ata_link *link, unsigned int *class)
{
	DPRINTK("ENTER\n");
	ata_std_postreset(link, class);
	DPRINTK("EXIT, class=%u\n", *class);
}

static unsigned int ahci_fill_sg(struct ata_queued_cmd *qc, void *cmd_tbl)
{
	struct scatterlist *sg;
	struct ahci_sg *ahci_sg = cmd_tbl + AHCI_CMD_TBL_HDR_SZ;
	unsigned int si;

	VPRINTK("ENTER\n");

	/*
	 * Next, the S/G list.
	 */
	for_each_sg(qc->sg, sg, qc->n_elem, si) {
		dma_addr_t addr = sg_dma_address(sg);
		u32 sg_len = sg_dma_len(sg);

		ahci_sg[si].addr = cpu_to_be32(addr & 0xffffffff);
		ahci_sg[si].addr_hi = cpu_to_be32((addr >> 16) >> 16);
		ahci_sg[si].flags_size = cpu_to_be32(sg_len - 1);
		VPRINTK("addr %08x, sz %08x\n", (u32)addr, sg_len);
	
		/* we using 64WORD burst write, so need ailgn to 256 byte */
		WARN_ON(addr & 0xff);
		WARN_ON(sg_len & 0xff);
	}

	return si;
}

static int ahci_pmp_qc_defer(struct ata_queued_cmd *qc)
{
	struct ata_port *ap = qc->ap;
	struct ahci_port_priv *pp = ap->private_data;

	if (!sata_pmp_attached(ap) || pp->fbs_enabled)
		return ata_std_qc_defer(qc);
	else
		return sata_pmp_qc_defer_cmd_switch(qc);
}

static void ahci_qc_prep(struct ata_queued_cmd *qc)
{
	struct ata_port *ap = qc->ap;
	struct ahci_port_priv *pp = ap->private_data;
	int is_atapi = ata_is_atapi(qc->tf.protocol);
	void *cmd_tbl;
	u32 opts;
	const u32 cmd_fis_len = 5; /* five dwords */
	unsigned int n_elem;

	/*
	 * Fill in command table information.  First, the header,
	 * a SATA Register - Host to Device command FIS.
	 */
	cmd_tbl = pp->cmd_tbl + qc->tag * AHCI_CMD_TBL_SZ;

	ata_tf_to_fis(&qc->tf, qc->dev->link->pmp, 1, cmd_tbl);
	if (is_atapi) {
		memset(cmd_tbl + AHCI_CMD_TBL_CDB, 0, 32);
		memcpy(cmd_tbl + AHCI_CMD_TBL_CDB, qc->cdb, qc->dev->cdb_len);
	}

	n_elem = 0;
	if (qc->flags & ATA_QCFLAG_DMAMAP)
		n_elem = ahci_fill_sg(qc, cmd_tbl);

	/*
	 * Fill in command slot information.
	 */
	opts = cmd_fis_len | n_elem << 16 | (qc->dev->link->pmp << 12);
	if (qc->tf.flags & ATA_TFLAG_WRITE)
		opts |= AHCI_CMD_WRITE;
	if (is_atapi)
		opts |= AHCI_CMD_ATAPI | AHCI_CMD_PREFETCH;

	ahci_fill_cmd_slot(pp, qc->tag, opts);

	VPRINTK("n_elem %d, pmp %d, opts %08x\n", n_elem, qc->dev->link->pmp, opts);
#ifdef DEBUG
	print_hex_dump(KERN_DEBUG, " fis :", DUMP_PREFIX_ADDRESS,
			16, 1, cmd_tbl, cmd_fis_len*4, 1);
#endif
}
#if 0
static void ahci_fbs_dec_intr(struct ata_port *ap)
{
	struct ahci_port_priv *pp = ap->private_data;
	void __iomem *port_mmio = ahci_port_base(ap);
	u32 fbs = readl(port_mmio + PORT_FBS);
	int retries = 3;

	DPRINTK("ENTER\n");
	BUG_ON(!pp->fbs_enabled);

	/* time to wait for DEC is not specified by AHCI spec,
	 * add a retry loop for safety.
	 */
	//writel(fbs | PORT_FBS_DEC, port_mmio + PORT_FBS);
	fbs = readl(port_mmio + PORT_FBS);
	while ((fbs & PORT_FBS_DEC) && retries--) {
		udelay(1);
		fbs = readl(port_mmio + PORT_FBS);
	}

	if (fbs & PORT_FBS_DEC)
		dev_printk(KERN_ERR, ap->host->dev,
			   "failed to clear device error\n");
}

static void ahci_error_intr(struct ata_port *ap, u32 irq_stat)
{
	struct ahci_host_priv *hpriv = ap->host->private_data;
	struct ahci_port_priv *pp = ap->private_data;
	struct ata_eh_info *host_ehi = &ap->link.eh_info;
	struct ata_link *link = NULL;
	struct ata_queued_cmd *active_qc;
	struct ata_eh_info *active_ehi;
	bool fbs_need_dec = false;
	u32 serror;

	/* determine active link with error */
	if (pp->fbs_enabled) {
		void __iomem *port_mmio = ahci_port_base(ap);
		u32 fbs = readl(port_mmio + PORT_FBS);
		int pmp = fbs >> PORT_FBS_DWE_OFFSET;

		if ((fbs & PORT_FBS_SDE) && (pmp < ap->nr_pmp_links) &&
		    ata_link_online(&ap->pmp_link[pmp])) {
			link = &ap->pmp_link[pmp];
			fbs_need_dec = true;
		}

	} else
		ata_for_each_link(link, ap, EDGE)
			if (ata_link_active(link))
				break;

	if (!link)
		link = &ap->link;

	active_qc = ata_qc_from_tag(ap, link->active_tag);
	active_ehi = &link->eh_info;

	/* record irq stat */
	ata_ehi_clear_desc(host_ehi);
	ata_ehi_push_desc(host_ehi, "irq_stat 0x%08x", irq_stat);

	/* AHCI needs SError cleared; otherwise, it might lock up */
	ahci_scr_read(&ap->link, SCR_ERROR, &serror);
	ahci_scr_write(&ap->link, SCR_ERROR, serror);
	host_ehi->serror |= serror;

	/* some controllers set IRQ_IF_ERR on device errors, ignore it */
	if (hpriv->flags & AHCI_HFLAG_IGN_IRQ_IF_ERR)
		irq_stat &= ~PORT_IRQ_IF_ERR;

	if (irq_stat & PORT_IRQ_TF_ERR) {
		/* If qc is active, charge it; otherwise, the active
		 * link.  There's no active qc on NCQ errors.  It will
		 * be determined by EH by reading log page 10h.
		 */
		if (active_qc)
			active_qc->err_mask |= AC_ERR_DEV;
		else
			active_ehi->err_mask |= AC_ERR_DEV;

		if (hpriv->flags & AHCI_HFLAG_IGN_SERR_INTERNAL)
			host_ehi->serror &= ~SERR_INTERNAL;
	}

	if (irq_stat & PORT_IRQ_UNK_FIS) {
		u32 *unk = (u32 *)(pp->rx_fis + RX_FIS_UNK);

		active_ehi->err_mask |= AC_ERR_HSM;
		active_ehi->action |= ATA_EH_RESET;
		ata_ehi_push_desc(active_ehi,
				  "unknown FIS %08x %08x %08x %08x" ,
				  unk[0], unk[1], unk[2], unk[3]);
	}

	if (sata_pmp_attached(ap) && (irq_stat & PORT_IRQ_BAD_PMP)) {
		active_ehi->err_mask |= AC_ERR_HSM;
		active_ehi->action |= ATA_EH_RESET;
		ata_ehi_push_desc(active_ehi, "incorrect PMP");
	}

	if (irq_stat & (PORT_IRQ_HBUS_ERR | PORT_IRQ_HBUS_DATA_ERR)) {
		host_ehi->err_mask |= AC_ERR_HOST_BUS;
		host_ehi->action |= ATA_EH_RESET;
		ata_ehi_push_desc(host_ehi, "host bus error");
	}

	if (irq_stat & PORT_IRQ_IF_ERR) {
		if (fbs_need_dec)
			active_ehi->err_mask |= AC_ERR_DEV;
		else {
			host_ehi->err_mask |= AC_ERR_ATA_BUS;
			host_ehi->action |= ATA_EH_RESET;
		}

		ata_ehi_push_desc(host_ehi, "interface fatal error");
	}

	if (irq_stat & (PORT_IRQ_CONNECT | PORT_IRQ_PHYRDY)) {
		ata_ehi_hotplugged(host_ehi);
		ata_ehi_push_desc(host_ehi, "%s",
			irq_stat & PORT_IRQ_CONNECT ?
			"connection status changed" : "PHY RDY changed");
	}

	/* okay, let's hand over to EH */

	if (irq_stat & PORT_IRQ_FREEZE)
		ata_port_freeze(ap);
	else if (fbs_need_dec) {
		ata_link_abort(link);
		ahci_fbs_dec_intr(ap);
	} else
		ata_port_abort(ap);
}

static void ahci_port_intr(struct ata_port *ap)
{
	void __iomem *port_mmio = ahci_port_base(ap);
	struct ata_eh_info *ehi = &ap->link.eh_info;
	struct ahci_port_priv *pp = ap->private_data;
	struct ahci_host_priv *hpriv = ap->host->private_data;
	int resetting = !!(ap->pflags & ATA_PFLAG_RESETTING);
	u32 status, qc_active = 0;
	int rc;

	status = readl(port_mmio + PORT_IRQ_STAT);
	//writel(status, port_mmio + PORT_IRQ_STAT);

	/* ignore BAD_PMP while resetting */
	if (unlikely(resetting))
		status &= ~PORT_IRQ_BAD_PMP;

	/* If we are getting PhyRdy, this is
	 * just a power state change, we should
	 * clear out this, plus the PhyRdy/Comm
	 * Wake bits from Serror
	 */
	if ((hpriv->flags & AHCI_HFLAG_NO_HOTPLUG) &&
		(status & PORT_IRQ_PHYRDY)) {
		status &= ~PORT_IRQ_PHYRDY;
		ahci_scr_write(&ap->link, SCR_ERROR, ((1 << 16) | (1 << 18)));
	}

	if (unlikely(status & PORT_IRQ_ERROR)) {
		ahci_error_intr(ap, status);
		return;
	}

	if (status & PORT_IRQ_SDB_FIS) {
		/* If SNotification is available, leave notification
		 * handling to sata_async_notification().  If not,
		 * emulate it by snooping SDB FIS RX area.
		 *
		 * Snooping FIS RX area is probably cheaper than
		 * poking SNotification but some constrollers which
		 * implement SNotification, ICH9 for example, don't
		 * store AN SDB FIS into receive area.
		 */
		if (hpriv->cap & HOST_CAP_SNTF)
			sata_async_notification(ap);
		else {
			/* If the 'N' bit in word 0 of the FIS is set,
			 * we just received asynchronous notification.
			 * Tell libata about it.
			 *
			 * Lack of SNotification should not appear in
			 * ahci 1.2, so the workaround is unnecessary
			 * when FBS is enabled.
			 */
			if (pp->fbs_enabled)
				WARN_ON_ONCE(1);
			else {
				const __le32 *f = pp->rx_fis + RX_FIS_SDB;
				u32 f0 = le32_to_cpu(f[0]);
				if (f0 & (1 << 15))
					sata_async_notification(ap);
			}
		}
	}

	/* pp->active_link is not reliable once FBS is enabled, both
	 * PORT_SCR_ACT and PORT_CMD_ISSUE should be checked because
	 * NCQ and non-NCQ commands may be in flight at the same time.
	 */
	if (pp->fbs_enabled) {
		if (ap->qc_active) {
			qc_active = readl(port_mmio + PORT_SCR_ACT);
			qc_active |= readl(port_mmio + PORT_CMD_ISSUE);
		}
	} else {
		/* pp->active_link is valid iff any command is in flight */
		if (ap->qc_active && pp->active_link->sactive)
			qc_active = readl(port_mmio + PORT_SCR_ACT);
		else
			qc_active = readl(port_mmio + PORT_CMD_ISSUE);
	}


	rc = ata_qc_complete_multiple(ap, qc_active);

	/* while resetting, invalid completions are expected */
	if (unlikely(rc < 0 && !resetting)) {
		ehi->err_mask |= AC_ERR_HSM;
		ehi->action |= ATA_EH_RESET;
		ata_port_freeze(ap);
	}
}

static irqreturn_t ahci_interrupt(int irq, void *dev_instance)
{
	struct ata_host *host = dev_instance;
	struct ahci_host_priv *hpriv;
	unsigned int i, handled = 0;
	void __iomem *mmio;
	u32 irq_stat, irq_masked;

	VPRINTK("ENTER\n");

	hpriv = host->private_data;
	mmio = hpriv->mmio;

	/* sigh.  0xffffffff is a valid return from h/w */
	irq_stat = readl(mmio + HOST_IRQ_STAT);
	if (!irq_stat)
		return IRQ_NONE;

	irq_masked = irq_stat & hpriv->port_map;

	spin_lock(&host->lock);

	for (i = 0; i < host->n_ports; i++) {
		struct ata_port *ap;

		if (!(irq_masked & (1 << i)))
			continue;

		ap = host->ports[i];
		if (ap) {
			ahci_port_intr(ap);
			VPRINTK("port %u\n", i);
		} else {
			VPRINTK("port %u (no irq)\n", i);
			if (ata_ratelimit())
				dev_printk(KERN_WARNING, host->dev,
					"interrupt on disabled port %u\n", i);
		}

		handled = 1;
	}

	/* HOST_IRQ_STAT behaves as level triggered latch meaning that
	 * it should be cleared after all the port events are cleared;
	 * otherwise, it will raise a spurious interrupt after each
	 * valid one.  Please read section 10.6.2 of ahci 1.1 for more
	 * information.
	 *
	 * Also, use the unmasked value to clear interrupt as spurious
	 * pending event on a dummy port might cause screaming IRQ.
	 */
	//writel(irq_stat, mmio + HOST_IRQ_STAT);

	spin_unlock(&host->lock);

	VPRINTK("EXIT\n");

	return IRQ_RETVAL(handled);
}
#endif
static unsigned int ahci_qc_issue(struct ata_queued_cmd *qc)
{
	struct ata_port *ap = qc->ap;
	void __iomem *port_mmio = ahci_port_base(ap);
	struct ahci_port_priv *pp = ap->private_data;
	struct sataMPI req;
	u32 slot = 1 << qc->tag;
	u32 act = 0;

	VPRINTK("ENTER\n");
	/* Keep track of the currently active link.  It will be used
	 * in completion path to determine whether NCQ phase is in
	 * progress.
	 */
	pp->active_link = qc->dev->link;

	if (qc->tf.protocol == ATA_PROT_NCQ)
		act = slot;

	if (pp->fbs_enabled && pp->fbs_last_dev != qc->dev->link->pmp) {
		u32 fbs = readl(port_mmio + PORT_FBS);
		fbs &= ~(PORT_FBS_DEV_MASK | PORT_FBS_DEC);
		fbs |= qc->dev->link->pmp << PORT_FBS_DEV_OFFSET;
		//writel(fbs, port_mmio + PORT_FBS);
		pp->fbs_last_dev = qc->dev->link->pmp;
	}

	req.header = 0x0101;
	req.d[0]   = slot;
	req.d[1]   = act;

	return ahci_mpi_to_fw(ap, &req);
}

static bool ahci_qc_fill_rtf(struct ata_queued_cmd *qc)
{
	struct ahci_port_priv *pp = qc->ap->private_data;
	u8 *d2h_fis = pp->rx_fis + RX_FIS_D2H_REG;

	VPRINTK("ENTER\n");

	if (pp->fbs_enabled)
		d2h_fis += qc->dev->link->pmp * AHCI_RX_FIS_SZ;
#ifdef DEBUG
	print_hex_dump(KERN_DEBUG, "rfis :", DUMP_PREFIX_ADDRESS,
			16, 1, d2h_fis, 0x20, 1);
#endif
	ata_tf_from_fis(d2h_fis, &qc->result_tf);
	return true;
}

static void ahci_freeze(struct ata_port *ap)
{
	/* TODO */
	struct ahci_port_priv *pp = ap->private_data;

	/* turn fw msg handle off */
	pp->freeze = 1;
}

static void ahci_thaw(struct ata_port *ap)
{
	/* TODO */
	struct ahci_port_priv *pp = ap->private_data;

	/* turn fw msg handle on */
	pp->freeze = 0;
}

static void ahci_error_handler(struct ata_port *ap)
{
	if (!(ap->pflags & ATA_PFLAG_FROZEN)) {
		/* restart engine */
		ahci_stop_engine(ap);
		ahci_start_engine(ap);
	}

	sata_pmp_error_handler(ap);

	if (!ata_dev_enabled(ap->link.device))
		ahci_stop_engine(ap);
}

static void ahci_post_internal_cmd(struct ata_queued_cmd *qc)
{
	struct ata_port *ap = qc->ap;

	/* make DMA engine forget about the failed command */
	if (qc->flags & ATA_QCFLAG_FAILED)
		ahci_kick_engine(ap);
}

static void ahci_enable_fbs(struct ata_port *ap)
{
	struct ahci_port_priv *pp = ap->private_data;
	void __iomem *port_mmio = ahci_port_base(ap);
	u32 fbs;
	int rc;

	if (!pp->fbs_supported)
		return;

	fbs = readl(port_mmio + PORT_FBS);
	if (fbs & PORT_FBS_EN) {
		pp->fbs_enabled = true;
		pp->fbs_last_dev = -1; /* initialization */
		return;
	}

	rc = ahci_stop_engine(ap);
	if (rc)
		return;

	//writel(fbs | PORT_FBS_EN, port_mmio + PORT_FBS);
	fbs = readl(port_mmio + PORT_FBS);
	if (fbs & PORT_FBS_EN) {
		dev_printk(KERN_INFO, ap->host->dev, "FBS is enabled.\n");
		pp->fbs_enabled = true;
		pp->fbs_last_dev = -1; /* initialization */
	} else
		dev_printk(KERN_ERR, ap->host->dev, "Failed to enable FBS\n");

	ahci_start_engine(ap);
}

static void ahci_disable_fbs(struct ata_port *ap)
{
	struct ahci_port_priv *pp = ap->private_data;
	void __iomem *port_mmio = ahci_port_base(ap);
	u32 fbs;
	int rc;

	if (!pp->fbs_supported)
		return;

	fbs = readl(port_mmio + PORT_FBS);
	if ((fbs & PORT_FBS_EN) == 0) {
		pp->fbs_enabled = false;
		return;
	}

	rc = ahci_stop_engine(ap);
	if (rc)
		return;

	//writel(fbs & ~PORT_FBS_EN, port_mmio + PORT_FBS);
	fbs = readl(port_mmio + PORT_FBS);
	if (fbs & PORT_FBS_EN)
		dev_printk(KERN_ERR, ap->host->dev, "Failed to disable FBS\n");
	else {
		dev_printk(KERN_INFO, ap->host->dev, "FBS is disabled.\n");
		pp->fbs_enabled = false;
	}

	ahci_start_engine(ap);
}

static void ahci_pmp_attach(struct ata_port *ap)
{
	void __iomem *port_mmio = ahci_port_base(ap);
	struct ahci_port_priv *pp = ap->private_data;
	u32 cmd;

	cmd = readl(port_mmio + PORT_CMD);
	cmd |= PORT_CMD_PMP;
	//writel(cmd, port_mmio + PORT_CMD);

	ahci_enable_fbs(ap);

	pp->intr_mask |= PORT_IRQ_BAD_PMP;
	//writel(pp->intr_mask, port_mmio + PORT_IRQ_MASK);
}

static void ahci_pmp_detach(struct ata_port *ap)
{
	void __iomem *port_mmio = ahci_port_base(ap);
	struct ahci_port_priv *pp = ap->private_data;
	u32 cmd;

	ahci_disable_fbs(ap);

	cmd = readl(port_mmio + PORT_CMD);
	cmd &= ~PORT_CMD_PMP;
	//writel(cmd, port_mmio + PORT_CMD);

	pp->intr_mask &= ~PORT_IRQ_BAD_PMP;
	//writel(pp->intr_mask, port_mmio + PORT_IRQ_MASK);
}

static int ahci_port_resume(struct ata_port *ap)
{
	ahci_start_port(ap);
	ahci_power_up(ap);

	if (sata_pmp_attached(ap))
		ahci_pmp_attach(ap);
	else
		ahci_pmp_detach(ap);

	return 0;
}

static int ahci_port_start(struct ata_port *ap)
{
	struct ahci_host_priv *hpriv = ap->host->private_data;
	struct device *dev = ap->host->dev;
	struct ahci_port_priv *pp;
	void *mem;
	dma_addr_t mem_dma;
	size_t dma_sz, rx_fis_sz;

	pp = devm_kzalloc(dev, sizeof(*pp), GFP_KERNEL);
	if (!pp)
		return -ENOMEM;

	/* check FBS capability */
	if ((hpriv->cap & HOST_CAP_FBS) && sata_pmp_supported(ap)) {
		void __iomem *port_mmio = ahci_port_base(ap);
		u32 cmd = readl(port_mmio + PORT_CMD);
		if (cmd & PORT_CMD_FBSCP)
			pp->fbs_supported = true;
		else
			dev_printk(KERN_WARNING, dev,
				   "The port is not capable of FBS\n");
	}

	if (pp->fbs_supported) {
		dma_sz = AHCI_PORT_PRIV_FBS_DMA_SZ;
		rx_fis_sz = AHCI_RX_FIS_SZ * 16;
	} else {
		dma_sz = AHCI_PORT_PRIV_DMA_SZ;
		rx_fis_sz = AHCI_RX_FIS_SZ;
	}

	mem = dmam_alloc_coherent(dev, dma_sz, &mem_dma, GFP_KERNEL);
	if (!mem)
		return -ENOMEM;
	memset(mem, 0, dma_sz);

	/*
	 * First item in chunk of DMA memory: 32-slot command table,
	 * 32 bytes each in size
	 */
	pp->cmd_slot = mem;
	pp->cmd_slot_dma = mem_dma;

	mem += AHCI_CMD_SLOT_SZ;
	mem_dma += AHCI_CMD_SLOT_SZ;

	/*
	 * Second item: Received-FIS area
	 */
	pp->rx_fis = mem;
	pp->rx_fis_dma = mem_dma;

	mem += rx_fis_sz;
	mem_dma += rx_fis_sz;

	/*
	 * Third item: data area for storing a single command
	 * and its scatter-gather table
	 */
	pp->cmd_tbl = mem;
	pp->cmd_tbl_dma = mem_dma;

	/*
	 * Save off initial list of interrupts to be enabled.
	 * This could be changed later
	 */
	pp->intr_mask = DEF_PORT_IRQ;

	ap->private_data = pp;

	/* engage engines, captain */
	return ahci_port_resume(ap);
}

static void ahci_port_stop(struct ata_port *ap)
{
	const char *emsg = NULL;
	int rc;

	/* de-initialize port */
	rc = ahci_deinit_port(ap, &emsg);
	if (rc)
		ata_port_printk(ap, KERN_WARNING, "%s (%d)\n", emsg, rc);
}

static void ahci_print_info(struct ata_host *host, const char *scc_s)
{
	struct ahci_host_priv *hpriv = host->private_data;
	void __iomem *mmio = hpriv->mmio;
	u32 vers, cap, cap2, impl, speed;
	const char *speed_s;

	vers = readl(mmio + 0x3c);
	cap = hpriv->cap;
	cap2 = hpriv->cap2;
	impl = hpriv->port_map;

	speed = (cap >> 20) & 0xf;
	if (speed == 1)
		speed_s = "1.5";
	else if (speed == 2)
		speed_s = "3";
	else if (speed == 3)
		speed_s = "6";
	else
		speed_s = "?";

	dev_info(host->dev,
		"AHCI %02x%02x.%02x%02x "
		"%u slots %u ports %s Gbps 0x%x impl %s mode\n"
		,

		(vers >> 24) & 0xff,
		(vers >> 16) & 0xff,
		(vers >> 8) & 0xff,
		vers & 0xff,

		((cap >> 8) & 0x1f) + 1,
		(cap & 0x1f) + 1,
		speed_s,
		impl,
		scc_s);

	dev_info(host->dev,
		"flags: "
		"%s%s%s%s%s%s%s"
		"%s%s%s%s%s%s%s"
		"%s%s%s%s%s%s\n"
		,
		cap & HOST_CAP_64 ? "64bit " : "",
		cap & HOST_CAP_NCQ ? "ncq " : "",
		cap & HOST_CAP_SNTF ? "sntf " : "",
		cap & HOST_CAP_MPS ? "ilck " : "",
		cap & HOST_CAP_SSS ? "stag " : "",
		cap & HOST_CAP_ALPM ? "pm " : "",
		cap & HOST_CAP_LED ? "led " : "",
		cap & HOST_CAP_CLO ? "clo " : "",
		cap & HOST_CAP_ONLY ? "only " : "",
		cap & HOST_CAP_PMP ? "pmp " : "",
		cap & HOST_CAP_FBS ? "fbs " : "",
		cap & HOST_CAP_PIO_MULTI ? "pio " : "",
		cap & HOST_CAP_SSC ? "slum " : "",
		cap & HOST_CAP_PART ? "part " : "",
		cap & HOST_CAP_CCC ? "ccc " : "",
		cap & HOST_CAP_EMS ? "ems " : "",
		cap & HOST_CAP_SXS ? "sxs " : "",
		cap2 & HOST_CAP2_APST ? "apst " : "",
		cap2 & HOST_CAP2_NVMHCI ? "nvmp " : "",
		cap2 & HOST_CAP2_BOH ? "boh " : ""
		);

	dev_info(host->dev, "FW version %02x.%02x.%02x.%02x, git 0x%08x, map %x\n",
		(hpriv->fw_version >> 24) & 0xff,
		(hpriv->fw_version >> 16) & 0xff,
		(hpriv->fw_version >> 8 ) & 0xff,
		(hpriv->fw_version >> 0 ) & 0xff,
		hpriv->fw_git, hpriv->port_map);
}

static int ahci_mpi_complete(struct ata_port *ap, u32 PxCI, u32 PxSACT)
{
	struct ahci_port_priv *pp = ap->private_data;
	u32 qc_active = 0;

	/* not to handle any ahci_mpi msg */
	if (pp->freeze)
		return 0;

	/* pp->active_link is not reliable once FBS is enabled, both
	 * PORT_SCR_ACT and PORT_CMD_ISSUE should be checked because
	 * NCQ and non-NCQ commands may be in flight at the same time.
	 */
	if (pp->fbs_enabled) {
		if (ap->qc_active) {
			qc_active = PxSACT;
			qc_active |= PxCI;
		}
	} else {
		/* pp->active_link is valid iff any command is in flight */
		if (ap->qc_active && pp->active_link->sactive)
			qc_active = PxSACT;
		else
			qc_active = PxCI;
	}
	return ata_qc_complete_multiple(ap, qc_active);
}

/**
 * ahci_mpi_complete_sdb - surpport NCQ ahci_mpi messages async handle
 * @ap: target port
 * @PxCI: FW PxCI REG
 * @pSActive: SActive REG from SDB Fis to indicate the finished cmd slot
 **/
static int ahci_mpi_complete_sdb(struct ata_port *ap, u32 PxCI, u32 pSActive)
{
	struct ahci_port_priv *pp = ap->private_data;
	u32 qc_active = 0;

	/* not to handle any ahci_mpi msg */
	if (pp->freeze)
		return 0;

	/* pp->active_link is not reliable once FBS is enabled, both
	 * PORT_SCR_ACT and PORT_CMD_ISSUE should be checked because
	 * NCQ and non-NCQ commands may be in flight at the same time.
	 */
	if (pp->fbs_enabled) {
		if (ap->qc_active) {
			qc_active = ap->qc_active;
			qc_active |= PxCI;
		}
	} else {
		/* pp->active_link is valid iff any command is in flight */
		if (ap->qc_active && pp->active_link->sactive) {
			qc_active = ap->qc_active;
			qc_active &= ~pSActive;
		} else
			qc_active = PxCI;
	}
	return ata_qc_complete_multiple(ap, qc_active);
}

static int ahci_mpi_crc_error(struct ata_port *ap)
{
	/*struct ahci_host_priv *hpriv = ap->host->private_data;*/
	struct ahci_port_priv *pp = ap->private_data;
	struct ata_eh_info *host_ehi = &ap->link.eh_info;
	struct ata_link *link = NULL;
	struct ata_queued_cmd *active_qc;
	struct ata_eh_info *active_ehi;
	bool fbs_need_dec = false;

	/* determine active link with error */
	if (pp->fbs_enabled) {
		/* TODO */
	} else {
		ata_for_each_link(link, ap, EDGE)
			if (ata_link_active(link))
				break;
	}

	if (!link)
		link = &ap->link;

	active_qc = ata_qc_from_tag(ap, link->active_tag);
	active_ehi = &link->eh_info;

	if (fbs_need_dec) {
		/* TODO */
		//active_ehi->err_mask |= AC_ERR_DEV;
	} else {
		host_ehi->err_mask |= AC_ERR_ATA_BUS;
		host_ehi->action |= ATA_EH_RESET;
	}

	if (fbs_need_dec) {
		/* TODO */
	} else {
		ata_port_freeze(ap);
	}

	return 0;
}

static int ahci_mpi_regfis_error(struct ata_port *ap,
		struct ata_taskfile *tf, u8 tag)
{
	/*struct ahci_host_priv *hpriv = ap->host->private_data;*/
	struct ahci_port_priv *pp = ap->private_data;
	struct ata_link *link = NULL;
	struct ata_queued_cmd *active_qc;
	struct ata_eh_info *active_ehi;
	bool fbs_need_dec = false;

	/* determine active link with error */
	if (pp->fbs_enabled) {
		/* TODO */
	} else {
		ata_for_each_link(link, ap, EDGE)
			if (ata_link_active(link))
				break;
	}

	if (!link)
		link = &ap->link;

	active_qc = ata_qc_from_tag(ap, link->active_tag);
	active_ehi = &link->eh_info;

	/* If qc is active, charge it; otherwise, the active
	 * link.  There's no active qc on NCQ errors.  It will
	 * be determined by EH by reading log page 10h.
	 */
	if (active_qc)
		active_qc->err_mask |= AC_ERR_DEV;
	else
		active_ehi->err_mask |= AC_ERR_DEV;


	if (fbs_need_dec) {
		/* TODO */
	} else {
		ata_port_abort(ap);
	}

	return 0;
}

static int ahci_mpi_regfis(struct ata_port *ap, struct sataMPI *rx)
{
	struct ahci_port_priv *pp = ap->private_data;
	u8 *d2h_fis = pp->rx_fis + 0x00;
	struct ata_taskfile tf;
	
	uint8_t reason = rx->d[0];
	u8 pmp = rx->d[6] >> 8;
	int res = -EINVAL;

	if (pp->fbs_enabled)
		d2h_fis += pmp * AHCI_RX_FIS_SZ;
#ifdef DEBUG
	print_hex_dump(KERN_DEBUG, "rfis :", DUMP_PREFIX_ADDRESS,
		       16, 1, d2h_fis, 0x20, 1);
#endif

	ata_tf_from_fis(d2h_fis, &tf);	
	DPRINTK("%d, reason:%d-%s\n", __LINE__, reason,
		(reason == 0x1) ? "error" : ((reason == 0x2) ? "update sig" : "ok"));
	switch (reason) {
	case 0x0: /* Interrupt bit */
		res = ahci_mpi_complete(ap, rx->d[1], rx->d[4]);
		break;
	case 0x1:
		ahci_mpi_regfis_error(ap, &tf, rx->d[5]);
		break;
	case 0x2: /* pUpdateSig */
		pp->PxSIG = (tf.lbah << 24) | (tf.lbam << 16) |
			(tf.lbal << 8)  | tf.nsect;
		res = 0;
		break;
	}

	return res;
}

static int ahci_mpi_piofis(struct ata_port *ap, struct sataMPI *rx)
{
	struct ahci_port_priv *pp = ap->private_data;
	u8 *d2h_fis = pp->rx_fis + 0x80;
	struct ata_taskfile tf;
	
	uint8_t reason = rx->d[0];
	u8 pmp = rx->d[6] >> 8;
	int res = -EINVAL;

	if (pp->fbs_enabled)
		d2h_fis += pmp * AHCI_RX_FIS_SZ;
#ifdef DEBUG
	print_hex_dump(KERN_DEBUG, "pio :", DUMP_PREFIX_ADDRESS,
		       16, 1, d2h_fis, 0x20, 1);
#endif
	ata_tf_from_fis(d2h_fis, &tf);	

	DPRINTK("%d, reason:%d-%s\n", __LINE__, reason,
		(reason) ? "error" : "ok");

	switch (reason) {
	case 0x0: /* Interrupt bit */
		res = ahci_mpi_complete(ap, rx->d[1], rx->d[4]);
		break;
	case 0x1: /* Stage 1 error */
	case 0x2: /* Stage 2 error */
		BUG_ON(1);
		break;
	}

	return res;
}

static int ahci_mpi_sdbfis(struct ata_port *ap, struct sataMPI *rx)
{
	struct ahci_port_priv *pp = ap->private_data;
	struct ahci_host_priv *hpriv = ap->host->private_data;
	u8 *d2h_fis = pp->rx_fis + 0x20;
	struct ata_taskfile tf;
	
	uint8_t reason = rx->d[0];
	u8 pmp = rx->d[6] >> 8;
	int res = -EINVAL;

	if (pp->fbs_enabled)
		d2h_fis += pmp * AHCI_RX_FIS_SZ;
#ifdef DEBUG
	print_hex_dump(KERN_DEBUG, "sdb :", DUMP_PREFIX_ADDRESS,
		       16, 1, d2h_fis, 0x20, 1);
#endif
	ata_tf_from_fis(d2h_fis, &tf);	

	DPRINTK("%d, reason:%d-%s\n", __LINE__, reason,
		(reason == 0x1) ? "error" : ((reason == 0x2) ? "notification" : "ok"));

	switch (reason) {
	case 0x0: /* Interrupt bit */
		res = ahci_mpi_complete_sdb(ap, rx->d[1], rx->d[4]);
		break;
	case 0x1: /* 1 error */
		ahci_mpi_regfis_error(ap, &tf, rx->d[5]);
		break;
	case 0x2: /* 2 notification */
		if (hpriv->cap & HOST_CAP_SNTF)
			sata_async_notification(ap);
		else {
			if (pp->fbs_enabled)
				WARN_ON_ONCE(1);
			else {
				const __le32 *f = pp->rx_fis + RX_FIS_SDB;
				u32 f0 = le32_to_cpu(f[0]);
				if (f0 & (1 << 15))
					sata_async_notification(ap);
			}
		}
		break;
	}

	return res;
}

static char *sig_str[] = {
	"0",			/* 0 */
	"1",			/* 1 */
	"2",			/* 2 */
	"3",			/* 3 */

	"LINKUP",		/* 4 */
	"LINKDOWN",		/* 5 */
	"StartComm",		/* 6 */
	"RXFIFO",		/* 7 */
	"RXData",		/* 8 */
	"RxGOOD",		/* 9 */
	"RxBad",		/* a */
	"TxRok",		/* b */
	"TxRerr",		/* c */
	"TxSync",		/* d */
	"TxSrcv",		/* e */
	"DmaDone",		/* f */
	"HCmd",			/* 10 */
	"Tick",			/* 11 */
};

static char *mesg_type[] = {
	"INTC_IDLE",		/* 0 */
	"INTC_LINK",		/* 1 */
	"INTC_REJECT", 		/* 2 */
	"INTC_RERR", 		/* 3 */
	"INTC_CRCERR", 		/* 4 */
	"INTC_REGFIS", 		/* 5 */
	"INTC_SDBFIS", 		/* 6 */
	"INTC_PIOSFIS", 	/* 7 */
	"INTC_UFIS", 		/* 8 */
	"INTC_PANIC", 		/* 9 */
	"INTC_TRACE", 		/* a */
};

static char *data_str[] = {
	"C_DATA   ", 		/* 0 */
	"C_PxCI   ", 		/* 1 */
	"C_PxTFD  ", 		/* 2 */
	"C_PxSSTS ", 		/* 3 */
	"C_PxSACT ", 		/* 4 */
	"C_SLOT   ", 		/* 5 */
	"C_FIS    ", 		/* 6 */
};

static char *fw_main[] = {
	"tx_dma_start",
	"rx_dma_start",
	"cx_fifo_ack",
	"hw_oob",
};

static char *sata_mpi[] = {
	"QHsmSata_top",
	"do_port_idle",
	"do_cfis_xmit",
	"do_cfis_done",
	"pio_done",
	"pio_update",
	"dr_done",
	"hw_dispatch",
};

#if 0
static char *state_str[] = {
	"top",			/* 0 */
	"linkdown",		/* 1 */
	"hostidle"		/* 2 */
	"CmdFis",		/* 3 */
	"RegFis",		/* 4 */
	"DbFis",		/* 5 */
	"DmaFis",		/* 6 */
	"PsFis",		/* 7 */
	"DsFis",		/* 8 */
	"Ufis",			/* 9 */
	"Dx",			/* a */
	"DmaO",			/* b */
	"DmaI",			/* c */
	"d",
	"e",
	"f",
};
#endif
static int ahci_mpi_trace(struct ata_port *ap, struct sataMPI *rx)
{
	int res = -EINVAL;
	uint32_t d0   = rx->d[0];
	uint8_t port  = (rx->header >> 16);
	uint16_t line = d0 & 0xffff;
	uint8_t fun   = (d0 >> 16) & 0x0f;
	
	if ((d0 & 0x80000000) == 0x80000000) {/* fw_main.c */
		printk("  p#%x fw_main.c %s() line %d, ",
			port, fw_main[fun], line);
		switch (fun) {
		case _tx_dma_start:
			printk("address %08x, opt %08x\n",
					rx->d[1], rx->d[2]);
			break;
		case _rx_dma_start:
			printk("address %08x, opt %08x\n",
					rx->d[1], rx->d[2]);
			break;
		case _cx_fifo_ack:
			printk("ok %08x\n", rx->d[1]);
			break;
		case _hw_oob:
			printk("\n");
			break;
		default:
			printk("\n");
			break;
		}
	} else {
		printk("  p#%x sata_mpi.c %s() line %d\n",
			port, sata_mpi[fun], line);
		switch (fun) {
		case _QHsmSata_top:
			break;
		case _do_port_idle:
			break;
		case _do_cfis_xmit:
			break;
		case _do_cfis_done:
			break;
		case _pio_done:
			break;
		case _pio_update:
			break;
		case _dr_done:
			break;
		case _hw_dispatch:
			{
			uint8_t sig  = rx->d[1] & 0xf;
			printk("  p#%x QHsm_dispatch: %x(%s)\n",
				port, sig, sig_str[sig]);
			}
			break;
		default:
			break;
		}
	}
	res = 0;
	return res;
}

static int ahci_mpi_from_fw(struct ata_port *ap, struct sataMPI *rx)
{
	int res = -EINVAL;
	uint8_t port, type, valid;
	struct ahci_port_priv *pp = ap->private_data;
	
	port  = (rx->header >> 16);
	type  = (rx->header >> 8);
	valid = rx->header;
	
	if (ap->port_no != port)
		return -ENODEV;
	
	switch (type) {
	case 0x0:		/* IDLE */
		break;
	case 0x1:		/* LINK */
		VPRINTK("p#%02x link %s(%d)\n", port, rx->d[0] ? "down" : "up", rx->d[0]);
		if (rx->d[0] == 0x0) { /* LINK UP */
			pp->regs[SCR_CONTROL] = rx->d[3];
			pp->regs[SCR_STATUS]  = rx->d[3];
		} else {
			pp->regs[SCR_CONTROL] = 0;
			pp->regs[SCR_STATUS]  = 0;
		}
		break;
	case 0x2:		/* REJECT */
		VPRINTK("REJECT C_DATA(%d) PxCI(%08x) SLOT(%d)\n",
			rx->d[0], rx->d[1], rx->d[5]);
		break;
	case 0x3:		/* RERR */
		VPRINTK("RERR Detected\n");
		break;
	case 0x4:		/* CRCERR */
		VPRINTK("CRC ERR Detected\n");
		res = ahci_mpi_crc_error(ap);
		break;
	case 0x5:		/* REG FIS */
		res = ahci_mpi_regfis(ap, rx);
		break;
	case 0x6:		/* SDB FIS */
		res = ahci_mpi_sdbfis(ap, rx);
		break;
	case 0x7: 		/* PIO FIS */
		res = ahci_mpi_piofis(ap, rx);
		break;
	case 0x8:		/* unknown FIS */
		break;
	case 0x9:		/* PANIC */
		break;
	case 0xa:               /* DEBUG */
		res = ahci_mpi_trace(ap, rx);
	default:
		break;
	}
	
	return res;
}

#include <linux/of_device.h>
#include <linux/of_platform.h>
#include "ahci.h"

#define ROLL_LENGTH      (1<<12)
#define ROLL(index, end) ((index)=(((index)+1) & ((end)-1)))

static int ahci_mpi_to_fw(struct ata_port *ap, struct sataMPI *req)
{
	struct ahci_host_priv *hpriv = ap->host->private_data;
	void __iomem *mmio = hpriv->mmio;
	struct sataRing *ring = &hpriv->outband;
	struct sataMPI *tx = &ring->mem[ring->ProdIndex];
	
	DPRINTK("outband: prod %d, cons %d, p#%02x\n", 
		ring->ProdIndex, *ring->cons_index, ap->port_no);

	req->header |= (ap->port_no<<16);
	memcpy(tx, req, sizeof(*tx));

	ring->ConsIndex = *ring->cons_index;
	WARN_ON(ring->ProdIndex + 1 == ring->ConsIndex);

	ROLL(ring->ProdIndex, ROLL_LENGTH);
	
	out_be32(mmio + 0x18, ring->ProdIndex);

	return 0;
}
static void ahci_print_rx(struct ahci_host_priv *hpriv)
{
	uint8_t port, type, valid;
	int i;
	struct sataRing *ring = &hpriv->inband;
	struct sataMPI *rx = &ring->mem[ring->ConsIndex];

	if ((rx->header & 0xff000000) != 0x01000000) {
		/* TODO */
		print_hex_dump(KERN_DEBUG, "AHCI MSG :", DUMP_PREFIX_ADDRESS,
				16, 1, rx, 0x20, 1);
		return;
	}
	port  = (rx->header >> 16);
	type  = (rx->header >> 8);
	valid = rx->header;

	pr_debug("pi[%03x] p#%02x, type %02x(%s), valid %02x, header %08x\n",
				 ring->ConsIndex, port, type, mesg_type[type], valid, rx->header);
	pr_debug("  %08x(%04d), %08x, %08x  %08x, %08x, %08x, %08x\n",
				 rx->d[0], rx->d[0] & 0xffff, rx->d[1], rx->d[2],
				 rx->d[3], rx->d[4], rx->d[5], rx->d[6]);
	for (i = 0; i < 7 ;i++){
		if (valid & (1<<i))
			pr_debug("  %s:%08x", data_str[i], rx->d[i]);
	}
}

static void ahci_inband_irq(struct ahci_host_priv *hpriv)
{
	struct sataRing *ring = &hpriv->inband;
	void __iomem *mmio = hpriv->mmio;

	printk("program run to line %d\n", __LINE__);
	ring->ProdIndex = *ring->prod_index;
	if (ring->ConsIndex  == ring->ProdIndex + 3) {
		WARN_ON(1);
	}
	while (ring->ConsIndex != ring->ProdIndex) {
		struct sataMPI *rx = &ring->mem[ring->ConsIndex];
		uint8_t port;

		ahci_print_rx(hpriv);

		port = (rx->header >> 16);
		WARN_ON(((1<<port) & hpriv->port_map) == 0);
		if ((1<<port) & hpriv->port_map) {
			struct ata_host *host = hpriv->host;
			struct ata_port *ap = host->ports[port];
			ahci_mpi_from_fw(ap, rx);
		}
		ROLL(ring->ConsIndex, ROLL_LENGTH);
	}
	out_be32(mmio + 0x28, ring->ConsIndex);
	out_be32(mmio + (NODE0<<12) + 0x200, 0x8);
}

static irqreturn_t ahci_mpi_irq(int irq, void *dev_instance)
{
	struct ata_host *host = dev_instance;
	struct ahci_host_priv *hpriv;
	void __iomem *mmio;
	u32 irq_stat;
	unsigned int handled = 0;
	
	printk("program run to line %d\n", __LINE__);
	VPRINTK("ENTER\n");
	hpriv = host->private_data;
	mmio = hpriv->mmio;
	
	irq_stat = in_be32(mmio + 0x0);
	if (!irq_stat)
		return IRQ_NONE;

	spin_lock(&host->lock);

	ahci_inband_irq(hpriv);
	handled = 1;

	spin_unlock(&host->lock);

	VPRINTK("EXIT\n");

	return IRQ_RETVAL(handled);
}

static void ahci_mpi_stop(struct ahci_host_priv *hpriv)
{
	struct device *dev = hpriv->dev;
	void __iomem *mmio = hpriv->mmio;
	/* reset the fw */
	out_be32(mmio + 0x8, 6);
	dma_free_coherent(dev,
			  hpriv->inband.rsz, 
			  hpriv->inband.mem,
			  hpriv->inband.mem_base);
	dma_free_coherent(dev,
			  hpriv->outband.rsz, 
			  hpriv->outband.mem,
			  hpriv->outband.mem_base);
}

static int ahci_mpi_ring_init(struct device *dev, struct sataRing *ring)
{
	int rsz = sizeof(struct sataMPI) * ROLL_LENGTH;
	void *ptr;
	
	rsz = rsz + 128;
	ptr = dma_alloc_coherent(dev, rsz, &ring->mem_base, GFP_KERNEL);
	if (ptr == NULL)
		return -ENOMEM;
	
	ring->rsz = rsz;
	ring->mem = ptr;
	
	ring->prod_index      = ptr + rsz;
	ring->prod_index_base = ring->mem_base + rsz;
	ring->cons_index      = ptr + rsz + 64;	
	ring->cons_index_base = ring->mem_base + rsz + 64;
	
	*ring->cons_index = 0;
	*ring->prod_index = 0;

	ring->ProdIndex = 0;
	ring->ConsIndex = 0;
	return 0;
}

static int memcpy_be32(uint32_t *dst, uint32_t *src, int sz)
{
	int i = 0;
	for (i = 0; i < sz/4; i ++) {
		*dst = cpu_to_le32(*src);
		dst ++;
		src ++;
	}
	return 0;
}

static int ahci_mpi_start(struct ahci_host_priv *hpriv)
{
	struct device *dev = hpriv->dev;
	int res, nport = 0;
	void __iomem *mmio = hpriv->mmio;
	struct sataRing *ring = &hpriv->inband;
	
	/* Pull DBG_STOP */
	out_be32(mmio + 0x8, 6);
	
	res = ahci_mpi_ring_init(dev, &hpriv->inband);
	if (res != 0)
		return -ENOMEM;
	
	res = ahci_mpi_ring_init(dev, &hpriv->outband);
	if (res != 0)
		return -ENOMEM;

	printk("outband base %08x, cons base %08x\n", 
		 (u32)hpriv->outband.mem_base,
		 (u32)hpriv->outband.cons_index_base);
	printk("inband  base %08x, prod base %08x\n", 
		 (u32)hpriv->inband.mem_base,
		 (u32)hpriv->inband.prod_index_base);

	/* HOST => MB */
	out_be32(mmio + 0x10, hpriv->outband.mem_base);
	out_be32(mmio + 0x14, hpriv->outband.cons_index_base);
	out_be32(mmio + 0x18, 0);
	/* MB => HOST */
	out_be32(mmio + 0x20, hpriv->inband.mem_base);
	out_be32(mmio + 0x24, hpriv->inband.prod_index_base);
	out_be32(mmio + 0x28, 0);

	/* Rst the FW CPU & enable it */
	out_be32(mmio + 0x8, 3);
	
	/* wait for port fsm init message */
	msleep(10000);
	
	/* if not got any message disable the port */
	if (*hpriv->inband.prod_index == 0) {
		ahci_mpi_stop(hpriv);
		return -ENODEV;
	}

	/* disable it start */
	out_be32(mmio + 0x8, 0);

	ring->ProdIndex = *ring->prod_index;
	
	while (ring->ConsIndex != ring->ProdIndex) {
		struct sataMPI *rx = &ring->mem[ring->ConsIndex];
		uint8_t port, type, valid;
		port  = (rx->header >> 16);
		type  = (rx->header >> 8);
		valid = rx->header;
		if (type == 0x0 && valid == 0x03) {
			pr_debug("pi[%03x] p#%02x, type %02x, valid %02x, version %08x\n", 
					ring->ConsIndex, port, type, valid, rx->d[0]);
			hpriv->fw_git = rx->d[0];
			hpriv->fw_version = rx->d[1];
		}
		if (type == 0x01 && valid == 0x1) {
			hpriv->port_map |= (1<<nport);
			nport ++;
		}
		ROLL(ring->ConsIndex, ROLL_LENGTH);
	}
	out_be32(mmio + 0x28, ring->ConsIndex);

	hpriv->cap = 0x201f00;	/* 3.0Gbps, 4port, 32slot */
	hpriv->cap|= nport-1;
	hpriv->cap|= HOST_CAP_NCQ;
	hpriv->cap|= HOST_CAP_SNTF;
	hpriv->cap|= HOST_CAP_CLO;
	hpriv->cap|= HOST_CAP_PMP;
	
#if 0
	hpriv->cap|= HOST_CAP_FBS;
#endif

	return nport;
}

static int __init ahci_probe(struct of_device *ofdev, const struct
		of_device_id *match)
{
	printk("%s()--%d\n", __func__, __LINE__);
	struct device *dev = &ofdev->dev;
	struct ahci_host_priv *hpriv;
	struct node_res_struct *node_res;
	struct ata_port_info pi = {
		.flags		= AHCI_FLAG_COMMON,
		.pio_mask	= ATA_PIO4,
		.udma_mask	= ATA_UDMA6,
		.port_ops	= &ahci_ops,
	};
	int rc;
	struct resource r_irq_struct;
	struct resource r_mem_struct;
	struct resource *r_irq = &r_irq_struct; /* Interrupt resources */
	struct resource *r_mem = &r_mem_struct; /* IO mem resources */
#if 0
	static int done = 0;
	
	if (done)
		return -ENODEV;
	done ++;
#endif
	/* Get iospace for the device */
	rc = of_address_to_resource(ofdev->node, 0, r_mem);
	if (rc) {
		dev_warn(&ofdev->dev, "invalid address\n");
		return -ENODEV;
	}
	/* Get IRQ for the device */
	rc = of_irq_to_resource(ofdev->node, 0, r_irq);
	if (rc == NO_IRQ) {
		dev_warn(&ofdev->dev, "no IRQ found.\n");
		return -ENODEV;
	}

	hpriv = devm_kzalloc(dev, sizeof(*hpriv), GFP_KERNEL);
	if (!hpriv) {
		dev_err(dev, "can't alloc ahci_host_priv\n");
		return -ENOMEM;
	}
	hpriv->dev    = dev;
	hpriv->flags |= (unsigned long)pi.private_data;

	hpriv->mmio = devm_ioremap_nocache(dev, r_mem->start, resource_size(r_mem));
	if (!hpriv->mmio) {
		dev_err(dev, "can't map %pR\n", r_mem);
		return -ENOMEM;
	}
	node_res = kzalloc(sizeof(*node_res), GFP_KERNEL);
	if (!node_res) {
		dev_err(dev, "node error\n");
		return -ENOMEM;
	}
	node_res->node_host_priv 	= hpriv;
	memcpy(&node_res->r_irq_struct, r_irq, sizeof(*r_irq));
	memcpy(&node_res->r_mem_struct, r_mem, sizeof(*r_mem));
	
	kthread_run(node_detect,node_res,"exp_downnode_det");
}

static int node_detect(void * node) {
	printk("%s()--%d\n", __func__, __LINE__);
	struct node_res_struct *node_res= (struct node_res_struct *)node; 
	struct device *dev = node_res->node_host_priv->dev;
	struct ahci_host_priv *hpriv = node_res->node_host_priv;
	struct resource *r_irq = &node_res->irq_struct;
	void __iomem *mmio = hpriv->mmio;
	struct ata_host *host;
	struct ata_port_info pi = {
		.flags		= AHCI_FLAG_COMMON,
		.pio_mask	= ATA_PIO4,
		.udma_mask	= ATA_UDMA6,
		.port_ops	= &ahci_ops,
	};
	const struct ata_port_info *ppi[] = { &pi, NULL };
	int n_ports;
	int rc;
	u32 aurora_chan_stat;	
	u32 node_stat;
	/*host reset*/
	out_be32(mmio + 0xc00,0x1);
	msleep(1000);
	
	/*open host irq, node0 irq*/
	out_be32(mmio + 0x800, 0xff);
	out_be32(mmio + (NODE0<<12) + 0x300, 0xff);

	/*prepare local bram*/
	memcpy_be32(mmio + 0x4000, (uint32_t *)fw_mpi, fw_mpi_size);
 
	/*wait channel up int*/ 
	do {
		aurora_chan_stat = in_be32(mmio + 0x400);
	} while (!(aurora_chan_stat & 0x10));

	/*send node0 cfg pkg*/
	out_be32(mmio + 0x400, 0x10);
	out_be32(mmio + (NODE0<<12) + 0x100, 0x1);
	
	/*wait node0 cfg done*/
	do {
		node_stat = in_be32(mmio + (NODE0<<12) + 0x200);
	} while (!(node_stat & 0x1));

	out_be32(mmio + (NODE0<<12) + 0x200, 0x1);
	//hpriv->mmio = hpriv->mmio + 0x80; //now only sata1 works

	printk("program run to line %d\n", __LINE__);
        /*now back to sata operation*/
	n_ports = ahci_mpi_start(hpriv);
	if (n_ports <= 0) {
		dev_err(dev, "can't start\n");
		return -ENOMEM;
	}
	
	pi.flags |= ATA_FLAG_NCQ;
	pi.flags |= ATA_FLAG_PMP;
	
	host = ata_host_alloc_pinfo(dev, ppi, n_ports);
	if (!host) {
		rc = -ENOMEM;
		goto err0;
	}
	hpriv->host = host;
	host->private_data = hpriv;
	
	ahci_init_controller(host);
	ahci_print_info(host, "platform");

	rc = ata_host_activate(host, r_irq->start, ahci_mpi_irq, IRQF_SHARED,
			       &ahci_sht);
	printk("program run to line %d\n", __LINE__);
	if (rc)
		goto err0;

	return 0;
err0:
	return rc;

}

static int __devexit ahci_remove(struct of_device *ofdev)
{
	printk("%s()--%d\n", __func__, __LINE__);
	struct device *dev = &ofdev->dev;
	struct ata_host *host = dev_get_drvdata(dev);
	
	ata_host_detach(host);
	ahci_mpi_stop(host->private_data);

	return 0;
}

static struct of_device_id ahci_of_match[] = {
	{ .compatible = "xlnx,ahci-mpi-1.00.a", },
	{ },
};
static struct of_platform_driver ahci_driver = {
	.name        = "ahci_mpi",
	.match_table = ahci_of_match,
	.probe       = ahci_probe,
	.remove      = __devexit_p(ahci_remove),
};

static int __init ahci_init(void)
{
	printk("%s()--%d\n", __func__, __LINE__);
	return of_register_platform_driver(&ahci_driver);
}
module_init(ahci_init);

static void __exit ahci_exit(void)
{
	printk("%s()--%d\n", __func__, __LINE__);
	of_unregister_platform_driver(&ahci_driver);
}
module_exit(ahci_exit);

MODULE_DESCRIPTION("AHCI SATA platform driver");
MODULE_AUTHOR("Anton Vorontsov <avorontsov@ru.mvista.com>");
MODULE_LICENSE("GPL");
MODULE_ALIAS("platform:ahci");
