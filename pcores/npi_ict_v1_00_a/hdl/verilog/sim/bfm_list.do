#  Simulation Model Generator
#  Xilinx EDK 12.3 EDK_MS3.70d
#  Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.
#
#  File     bfm_list.do (Sat Aug 11 15:18:31 2012)
#
#  List Window DO Script File
#
#  List Window DO script files setup the ModelSim List window
#  display for viewing results of the simulation in a tabular
#  format. Comment or uncomment commands to change the set of
#  data values viewed.
#
echo  "Setting up List window display ..."

if { ![info exists xcmdc] } {echo "Warning : c compile command was not run"}
if { ![info exists xcmds] } {echo "Warning : s simulate command was not run"}

onerror { resume }

if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "/bfm_tb${ps}dut" }

#
#  Display top-level ports
#
set binopt {-bin}
set hexopt {-hex}
eval add list $binopt $tbpath${ps}fpga_0_clk_1_sys_clk_pin
eval add list $binopt $tbpath${ps}fpga_0_rst_1_sys_rst_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_Clk_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_Clk_n_pin
eval add list $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_CE_pin
eval add list $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_CS_n_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_ODT_pin
eval add list $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_RAS_n_pin
eval add list $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_CAS_n_pin
eval add list $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_WE_n_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_BankAddr_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_Addr_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_DQ_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_DM_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_DQS_pin
eval add list $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_DQS_n_pin
eval add list $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_rst_n_pin
eval add list $hexopt $tbpath${ps}PIM0_Addr
eval add list $binopt $tbpath${ps}PIM0_AddrReq
eval add list $binopt $tbpath${ps}PIM0_AddrAck
eval add list $binopt $tbpath${ps}PIM0_RNW
eval add list $hexopt $tbpath${ps}PIM0_Size
eval add list $binopt $tbpath${ps}PIM0_RdModWr
eval add list $hexopt $tbpath${ps}PIM0_WrFIFO_Data
eval add list $hexopt $tbpath${ps}PIM0_WrFIFO_BE
eval add list $binopt $tbpath${ps}PIM0_WrFIFO_Push
eval add list $hexopt $tbpath${ps}PIM0_RdFIFO_Data
eval add list $binopt $tbpath${ps}PIM0_RdFIFO_Pop
eval add list $hexopt $tbpath${ps}PIM0_RdFIFO_RdWdAddr
eval add list $binopt $tbpath${ps}PIM0_WrFIFO_Empty
eval add list $binopt $tbpath${ps}PIM0_WrFIFO_AlmostFull
eval add list $binopt $tbpath${ps}PIM0_WrFIFO_Flush
eval add list $binopt $tbpath${ps}PIM0_RdFIFO_Empty
eval add list $binopt $tbpath${ps}PIM0_RdFIFO_Flush
eval add list $hexopt $tbpath${ps}PIM0_RdFIFO_Latency
eval add list $binopt $tbpath${ps}PIM0_InitDone
eval add list $binopt $tbpath${ps}PIM0_Clk
eval add list $hexopt $tbpath${ps}PIM1_Addr
eval add list $binopt $tbpath${ps}PIM1_AddrReq
eval add list $binopt $tbpath${ps}PIM1_AddrAck
eval add list $binopt $tbpath${ps}PIM1_RNW
eval add list $hexopt $tbpath${ps}PIM1_Size
eval add list $binopt $tbpath${ps}PIM1_RdModWr
eval add list $hexopt $tbpath${ps}PIM1_WrFIFO_Data
eval add list $hexopt $tbpath${ps}PIM1_WrFIFO_BE
eval add list $binopt $tbpath${ps}PIM1_WrFIFO_Push
eval add list $hexopt $tbpath${ps}PIM1_RdFIFO_Data
eval add list $binopt $tbpath${ps}PIM1_RdFIFO_Pop
eval add list $hexopt $tbpath${ps}PIM1_RdFIFO_RdWdAddr
eval add list $binopt $tbpath${ps}PIM1_WrFIFO_Empty
eval add list $binopt $tbpath${ps}PIM1_WrFIFO_AlmostFull
eval add list $binopt $tbpath${ps}PIM1_WrFIFO_Flush
eval add list $binopt $tbpath${ps}PIM1_RdFIFO_Empty
eval add list $binopt $tbpath${ps}PIM1_RdFIFO_Flush
eval add list $hexopt $tbpath${ps}PIM1_RdFIFO_Latency
eval add list $binopt $tbpath${ps}PIM1_InitDone
eval add list $binopt $tbpath${ps}PIM1_Clk

#
#  Display bus signal ports
#
#
#  Display processor ports
#
#
#  Display processor registers
#

#
#  Display IP and peripheral ports
#
do clock_generator_0_list.do

do proc_sys_reset_0_list.do

do ppc440mc_ddr2_0_list.do


#  List window configuration information
#
configure list -delta                 none
configure list -usesignaltriggers     0

#  Define the simulation strobe and period, if used.

configure list -usestrobe             0
configure list -strobestart           {0 ps}  -strobeperiod {0 ps}

configure list -usegating             1

# Configure the gated clock.
# configure list -gateexpr <<signal_name>>

#  List window setup complete
#
echo  "List window display setup done."
