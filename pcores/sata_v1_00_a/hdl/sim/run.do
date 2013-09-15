#set C_FAMILY "virtex5"
#set C_FAMILY "spartan6"
set C_FAMILY "kirtex7"

do compile.do

vlog  -incr ../verilog/crc.v
vlog  -incr ../verilog/ctrl.v
vlog  -incr ../verilog/dcr_if.v
vlog  -incr ../verilog/dma.v
vlog  -incr ../verilog/fifo_36w_36r.v
vlog  -incr ../verilog/link_fsm.v {+incdir+../verilog/}
vlog  -incr ../verilog/rx_cs.v {+incdir+../verilog/}
vlog  -incr ../verilog/rxll.v 
vlog  -incr ../verilog/rxll_ctrl.v
vlog  -incr ../verilog/rxll_fifo.v
vlog  -incr ../verilog/rxll_ll.v
vlog  -incr ../verilog/sata_dma.v
vlog  -incr ../verilog/sata_link.v {+incdir+../verilog/}
vlog  -incr ../verilog/scrambler.v
vlog  -incr ../verilog/tx_cs.v {+incdir+../verilog/}
vlog  -incr ../verilog/txll.v
vlog  -incr ../verilog/txll_ctrl.v
vlog  -incr ../verilog/txll_fifo.v
vlog  -incr ../verilog/txll_ll.v
vlog  -incr ../verilog/crossdomain/signal.v
vlog  -incr ../verilog/crossdomain/reg_sync.v
vlog  -incr ../verilog/srl16e_fifo_protect.v
vlog  -incr ../verilog/npi_pi_enable.v
vlog  -incr ../../../mpmc_v6_03_a/hdl/verilog/mpmc_sample_cycle.v
vcom        ../vhdl/axi_async_fifo.vhd

sccom -work plbv46_wrapper_v1_00_a -ggdb dgio.cpp -I.
sccom -work work -ggdb dgio.cpp -I.

sccom -ggdb ../../../../sata_ip_sim/systemc/dev_fsm_base.cpp -I../../../../dg_sata/ahci/include/ -DTEST_base

set mpi "../../../../fw"
sccom -D_SIM_  -I$mpi/include -I$mpi/ -I. init.c
sccom -I$mpi/include -I$mpi/ -I. $mpi/qhsm_dis.c
sccom -I$mpi/include -I$mpi/ -I. $mpi/qhsm_ini.c
sccom -I$mpi/include -I$mpi/ -I. $mpi/qhsm_top.c
sccom -I$mpi/include -I$mpi/ -I. $mpi/qep.c
sccom -D_SIM_ -I$mpi/include -I$mpi/ -I. $mpi/sata_mpi.c -DGITVERSION=0x0

sccom -link

vlog tb.v +define+C_FAMILY=\"${C_FAMILY}\"
vlog -novopt -incr -work work $::env(XILINX)/verilog/src/glbl.v

vsim +nowarnTSCALE -novopt -t ps -L xilinxcorelib_ver -L secureip -L unisims_ver +notimingchecks tb glbl

do wave_top.do
do wave_phy.do
do wave_dma.do
do wave_end.do

run 50us
