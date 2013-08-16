
do bfm_setup.do
#c

vlog -novopt -incr -work work "gen_npi.v"
vlog -novopt -incr -work work "ddr2_dimm.v"
vlog -incr +incdir+. +define+x1Gb +define+sg3 +define+x8 "ddr2_model.v"

vlog -novopt -incr -work work "ppc440mc_ddr2_0_wrapper.v"
vlog -novopt -incr -work work "bfm_tb.v"
vlog -novopt -incr -work work "bfm.v"

vlog -novopt -incr -work work "npi_ict_top.v"
vlog -novopt -incr -work work "../*.v"

s
eval add wave -noupdate -asc /bfm_tb/cmd_ascii

w

#do wave_npi_port.do /bfm_tb 0
do wave_mpmc.do

do wave_npi_ict.do

run 20us
