#do compile.do

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
vlog  -incr ../verilog/npi/mpmc_sample_cycle.v

sccom -work plbv46_wrapper_v1_00_a -ggdb dgio.cpp -I.
sccom -work work -ggdb dgio.cpp -I.

sccom -ggdb ../../../../dg_sata/systemc/dev_fsm_base.cpp -I../../../../dg_sata/ahci/include/ -DTEST_base

sccom -D_SIM_  -Impi/include -Impi/ -I. init.c
sccom -Impi/include -Impi/ -I. mpi/qhsm_dis.c
sccom -Impi/include -Impi/ -I. mpi/qhsm_ini.c
sccom -Impi/include -Impi/ -I. mpi/qhsm_top.c
sccom -D_SIM_ -Impi/include -Impi/ -I. mpi/sata_mpi.c -DGITVERSION=0x0

sccom -link

vlog tb.v
vlog -novopt -incr -work work "/opt/ise12.3/ISE_DS/ISE/verilog/src/glbl.v"

vsim -novopt -t ps -L xilinxcorelib_ver -L secureip -L unisims_ver +notimingchecks tb glbl

do wave_top.do
do wave_phy.do
do wave_dma.do
do wave_end.do

run 50us
