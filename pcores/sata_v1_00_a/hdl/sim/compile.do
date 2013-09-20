#
set TOPDIR "../../../../"

vlib satagtx_clk_v1_00_a
vlib satagtx_v1_00_a
vlib plbv46_wrapper_v1_00_a
vlib work

vlog ${TOPDIR}/pcores/satagtx_clk_v1_00_a/hdl/verilog/satagtx_clk.v
vlog ${TOPDIR}/pcores/satagtx_clk_v1_00_a/hdl/verilog/mgt_usrclk_source.v
vlog ${TOPDIR}/pcores/satagtx_clk_v1_00_a/hdl/verilog/mgt_usrclk_source_pll.v

vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/cross_signal.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/gtx_oob.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/phy_if_gtx.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/satagtx.v

vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtx/v5_gtx_top.v +incdir+${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtx/rocketio_wrapper.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtx/rocketio_wrapper_tile.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtx/tx_sync.v

vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/s6_gtp/s6_gtp_top.v +incdir+${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/s6_gtp/s6_gtpwizard_v1_11.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/s6_gtp/s6_gtpwizard_v1_11_tile.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/s6_gtp/s6_gtpwizard_v1_11_tx_sync.v

vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/k7_gtx/k7_gtx_top.v  +incdir+${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/k7_gtx/gtwizard_v2_6_init.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/k7_gtx/gtwizard_v2_6.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/k7_gtx/gtwizard_v2_6_gt.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/k7_gtx/gtwizard_v2_6_tx_startup_fsm.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/k7_gtx/gtwizard_v2_6_rx_startup_fsm.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/k7_gtx/gtwizard_v2_6_sync_block.v

vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtp/v5_gtp_top.v  +incdir+${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtp/v5_gtpwizard_v2_1.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtp/v5_gtpwizard_v2_1_tile.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtp/gtp_tx_sync.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtp/mpmc_sample_cycle.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/v5_gtp/gtp_oob.v

vlog ${TOPDIR}/sata_ip_sim/device_sim.v
vlog ${TOPDIR}/sata_ip_sim/sata_device/phy_if_gtp.v
vlog ${TOPDIR}/sata_ip_sim/sata_device/shdd_model_phy.v
vlog ${TOPDIR}/sata_ip_sim/sata_device/oob_device.v
vlog ${TOPDIR}/sata_ip_sim/sata_device/mgt_usrclk_source.v
vlog ${TOPDIR}/sata_ip_sim/fifo/fifo_control.v
vlog ${TOPDIR}/sata_ip_sim/fifo/tpram.v
vlog ${TOPDIR}/sata_ip_sim/fifo/synchronizer_flop.v
