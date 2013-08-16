#  Simulation Model Generator
#  Xilinx EDK 12.3 EDK_MS3.70d
#  Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.
#
#  File     clock_generator_0_wave.do (Sat Aug 11 15:18:31 2012)
#
#  Module   clock_generator_0_wrapper
#  Instance clock_generator_0
set binopt {-logic}
set hexopt {-literal -hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "/bfm_tb${ps}dut" }

  eval add wave -noupdate -divider {"clock_generator_0"}
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKIN
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKFBIN
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT0
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT1
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT2
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT3
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT4
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT5
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT6
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT7
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT8
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT9
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT10
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT11
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT12
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT13
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT14
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT15
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}CLKFBOUT
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}PSCLK
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}PSEN
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}PSINCDEC
# eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}PSDONE
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}RST
  eval add wave -noupdate $binopt $tbpath${ps}clock_generator_0${ps}LOCKED

