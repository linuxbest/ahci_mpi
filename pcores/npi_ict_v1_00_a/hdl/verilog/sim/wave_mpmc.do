set binopt {-logic}
set hexopt {-literal -hex}
set ascopt {-literal -asc}

if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists mpmc] } { set mpmc "/bfm_tb/dut/ppc440mc_ddr2_0/ppc440mc_ddr2_0/mpmc_core_0" }

eval add wave -noupdate $binopt $mpmc${ps}Clk0

eval add wave -noupdate $hexopt $mpmc${ps}wdf_data
eval add wave -noupdate $hexopt $mpmc${ps}wdf_mask_data

eval add wave -noupdate -divider {"write fifo"}
set wrfifo "$mpmc${ps}gen_paths${ps}mpmc_data_path_0${ps}gen_write_fifos\[0\]${ps}gen_fifos${ps}mpmc_write_fifo_0"

eval add wave -noupdate $binopt {$wrfifo${ps}Clk}
eval add wave -noupdate $binopt {$wrfifo${ps}Rst}

eval add wave -noupdate $binopt {$wrfifo${ps}AddrAck}
eval add wave -noupdate $binopt {$wrfifo${ps}RNW}
eval add wave -noupdate $binopt {$wrfifo${ps}Size}
eval add wave -noupdate $hexopt {$wrfifo${ps}Addr}

eval add wave -noupdate $binopt {$wrfifo${ps}Flush}
eval add wave -noupdate $binopt {$wrfifo${ps}BE_Rst}

eval add wave -noupdate $binopt {$wrfifo${ps}Push}
eval add wave -noupdate $hexopt {$wrfifo${ps}PushData}
eval add wave -noupdate $hexopt {$wrfifo${ps}PushBE}

eval add wave -noupdate $binopt {$wrfifo${ps}AlmostFull}
eval add wave -noupdate $binopt {$wrfifo${ps}Empty}

eval add wave -noupdate $binopt {$wrfifo${ps}Pop}
eval add wave -noupdate $hexopt {$wrfifo${ps}PopData}
eval add wave -noupdate $hexopt {$wrfifo${ps}PopBE}

eval add wave -noupdate -divider {"read fifo"}
set rdfifo "$mpmc${ps}gen_paths${ps}mpmc_data_path_0${ps}gen_read_fifos\[0\]${ps}gen_fifos${ps}mpmc_read_fifo_0"
eval add wave -noupdate $binopt {$rdfifo${ps}Clk}
eval add wave -noupdate $binopt {$rdfifo${ps}Rst}

eval add wave -noupdate $binopt {$rdfifo${ps}AddrAck}
eval add wave -noupdate $binopt {$rdfifo${ps}RNW}
eval add wave -noupdate $binopt {$rdfifo${ps}Size}
eval add wave -noupdate $hexopt {$rdfifo${ps}Addr}

eval add wave -noupdate $binopt {$rdfifo${ps}Push}
eval add wave -noupdate $hexopt {$rdfifo${ps}PushData}

eval add wave -noupdate $binopt {$rdfifo${ps}AlmostFull}
eval add wave -noupdate $binopt {$rdfifo${ps}Empty}

eval add wave -noupdate $binopt {$rdfifo${ps}Pop}
eval add wave -noupdate $hexopt {$rdfifo${ps}PopData}
