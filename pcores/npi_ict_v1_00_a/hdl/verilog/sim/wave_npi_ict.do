set binopt {-logic}
set hexopt {-literal -hex}
set ascopt {-literal -asc}

if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists ict] } { set ict "/bfm_tb/npi_ict_top/npi_ict" }

do wave_npi_port.do $ict 0
do wave_npi_port.do $ict 1
do wave_npi_port.do $ict 2
do wave_npi_port.do $ict 3
do wave_npi_port.do $ict 4

eval add wave -noupdate -divider {"npi ict fsm"}
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}Clk
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}Rst

eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}ReqRNW
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}ReqSize
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}ReqAddr
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}ReqPop

eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}ReqWrBeRst
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}ReqWrPop
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}ReqWrEmpty
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}ReqWrData
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}ReqWrBE

eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}ReqGrant
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}ReqGrant_nr
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}ReqPending

eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}RNW
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}Size
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}WrData
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}WrBE

eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}write_size
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}write_nr
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}write_grant
eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}write_burst
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}write_pop
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}write_valid
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}wrfifo_empty
eval add wave -noupdate $binopt $ict${ps}npi_ict_fsm${ps}wrfifo_afull

eval add wave -noupdate $hexopt $ict${ps}npi_ict_fsm${ps}state
eval add wave -noupdate $ascopt $ict${ps}npi_ict_fsm${ps}state_ascii

eval add wave -noupdate -divider {"npi ict rd "}
eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}Clk
eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}Rst

eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}rdsts_afull
eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}rdsts_wren
eval add wave -noupdate $hexopt $ict${ps}npi_ict_rd${ps}rdsts_len
eval add wave -noupdate $hexopt $ict${ps}npi_ict_rd${ps}rdsts_nr

eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}rdsts_empty
eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}rdsts_rden
eval add wave -noupdate $hexopt $ict${ps}npi_ict_rd${ps}len

eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}pop_d1
eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}id_d1

eval add wave -noupdate $hexopt $ict${ps}npi_ict_rd${ps}state
eval add wave -noupdate $ascopt $ict${ps}npi_ict_rd${ps}state_ascii

eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}PIM_RdFIFO_Pop
eval add wave -noupdate $binopt $ict${ps}npi_ict_rd${ps}PIM_RdFIFO_Push
eval add wave -noupdate $hexopt $ict${ps}npi_ict_rd${ps}PIM_RdFIFO_Push_sel
eval add wave -noupdate $hexopt $ict${ps}npi_ict_rd${ps}PIM_RdFIFO_Push_Data

do wave_npi_port.do $ict ""
