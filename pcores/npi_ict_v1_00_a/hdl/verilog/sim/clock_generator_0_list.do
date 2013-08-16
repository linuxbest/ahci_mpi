#  Simulation Model Generator
#  Xilinx EDK 12.3 EDK_MS3.70d
#  Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.
#
#  File     clock_generator_0_list.do (Sat Aug 11 15:18:31 2012)
#
#  Module   clock_generator_0_wrapper
#  Instance clock_generator_0
set binopt {-bin}
set hexopt {-hex}
if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "/bfm_tb${ps}dut" }

  eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKIN
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKFBIN
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT0
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT1
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT2
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT3
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT4
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT5
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT6
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT7
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT8
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT9
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT10
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT11
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT12
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT13
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT14
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKOUT15
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}CLKFBOUT
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}PSCLK
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}PSEN
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}PSINCDEC
# eval add list $binopt $tbpath${ps}clock_generator_0${ps}PSDONE
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}RST
  eval add list $binopt $tbpath${ps}clock_generator_0${ps}LOCKED

