#
set TOPDIR "../../../../"

vlib satagtx_clk_v1_00_a
vlib satagtx_v1_00_a
vlib plbv46_wrapper_v1_00_a
vlib work

vlog ${TOPDIR}/pcores/satagtx_clk_v1_00_a/hdl/verilog/satagtx_clk.v
vlog ${TOPDIR}/pcores/satagtx_clk_v1_00_a/hdl/verilog/mgt_usrclk_source.v

vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/ML505_GTX_speed_negotiation.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/cross_signal.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/frame_check.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/frame_gen.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/gtx_oob.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/oob_control.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/phy_if_gtx.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/rocketio_wrapper.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/rocketio_wrapper_tile.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/rocketio_wrapper_top.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/satagtx.v
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/satagtx_top.v +incdir+${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/
vlog ${TOPDIR}/pcores/satagtx_v1_00_a/hdl/verilog/tx_sync.v

vlog ${TOPDIR}/sata_ip_sim/device_sim.v
vlog ${TOPDIR}/sata_ip_sim/sata_device/phy_if_gtp.v
vlog ${TOPDIR}/sata_ip_sim/sata_device/shdd_model_phy.v
vlog ${TOPDIR}/sata_ip_sim/sata_device/oob_device.v
vlog ${TOPDIR}/sata_ip_sim/sata_device/mgt_usrclk_source.v
vlog ${TOPDIR}/sata_ip_sim/fifo/fifo_control.v
vlog ${TOPDIR}/sata_ip_sim/fifo/tpram.v
vlog ${TOPDIR}/sata_ip_sim/fifo/synchronizer_flop.v


