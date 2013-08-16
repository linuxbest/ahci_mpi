#  Simulation Model Generator
#  Xilinx EDK 12.3 EDK_MS3.70d
#  Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.
#
#  File     bfm_wave.do (Sat Aug 11 15:18:31 2012)
#
#  Wave Window DO Script File
#
#  Wave Window DO script files setup the ModelSim Wave window
#  display for viewing results of the simulation in a graphic
#  format. Comment or uncomment commands to change the set of
#  signals viewed.
#
echo  "Setting up Wave window display ..."

if { ![info exists xcmdc] } {echo "Warning : c compile command was not run"}
if { ![info exists xcmds] } {echo "Warning : s simulate command was not run"}

if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "/bfm_tb${ps}dut" }

#
#  Display top-level ports
#
set binopt {-logic}
set hexopt {-literal -hex}
eval add wave -noupdate -divider {"top-level ports"}
eval add wave -noupdate $binopt $tbpath${ps}fpga_0_clk_1_sys_clk_pin
eval add wave -noupdate $binopt $tbpath${ps}fpga_0_rst_1_sys_rst_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_Clk_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_Clk_n_pin
eval add wave -noupdate $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_CE_pin
eval add wave -noupdate $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_CS_n_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_ODT_pin
eval add wave -noupdate $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_RAS_n_pin
eval add wave -noupdate $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_CAS_n_pin
eval add wave -noupdate $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_WE_n_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_BankAddr_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_Addr_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_DQ_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_DM_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_DQS_pin
eval add wave -noupdate $hexopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_DQS_n_pin
eval add wave -noupdate $binopt $tbpath${ps}fpga_0_DDR2_SDRAM_DDR2_rst_n_pin
eval add wave -noupdate $hexopt $tbpath${ps}PIM0_Addr
eval add wave -noupdate $binopt $tbpath${ps}PIM0_AddrReq
eval add wave -noupdate $binopt $tbpath${ps}PIM0_AddrAck
eval add wave -noupdate $binopt $tbpath${ps}PIM0_RNW
eval add wave -noupdate $hexopt $tbpath${ps}PIM0_Size
eval add wave -noupdate $binopt $tbpath${ps}PIM0_RdModWr
eval add wave -noupdate $hexopt $tbpath${ps}PIM0_WrFIFO_Data
eval add wave -noupdate $hexopt $tbpath${ps}PIM0_WrFIFO_BE
eval add wave -noupdate $binopt $tbpath${ps}PIM0_WrFIFO_Push
eval add wave -noupdate $hexopt $tbpath${ps}PIM0_RdFIFO_Data
eval add wave -noupdate $binopt $tbpath${ps}PIM0_RdFIFO_Pop
eval add wave -noupdate $hexopt $tbpath${ps}PIM0_RdFIFO_RdWdAddr
eval add wave -noupdate $binopt $tbpath${ps}PIM0_WrFIFO_Empty
eval add wave -noupdate $binopt $tbpath${ps}PIM0_WrFIFO_AlmostFull
eval add wave -noupdate $binopt $tbpath${ps}PIM0_WrFIFO_Flush
eval add wave -noupdate $binopt $tbpath${ps}PIM0_RdFIFO_Empty
eval add wave -noupdate $binopt $tbpath${ps}PIM0_RdFIFO_Flush
eval add wave -noupdate $hexopt $tbpath${ps}PIM0_RdFIFO_Latency
eval add wave -noupdate $binopt $tbpath${ps}PIM0_InitDone
eval add wave -noupdate $binopt $tbpath${ps}PIM0_Clk
eval add wave -noupdate $hexopt $tbpath${ps}PIM1_Addr
eval add wave -noupdate $binopt $tbpath${ps}PIM1_AddrReq
eval add wave -noupdate $binopt $tbpath${ps}PIM1_AddrAck
eval add wave -noupdate $binopt $tbpath${ps}PIM1_RNW
eval add wave -noupdate $hexopt $tbpath${ps}PIM1_Size
eval add wave -noupdate $binopt $tbpath${ps}PIM1_RdModWr
eval add wave -noupdate $hexopt $tbpath${ps}PIM1_WrFIFO_Data
eval add wave -noupdate $hexopt $tbpath${ps}PIM1_WrFIFO_BE
eval add wave -noupdate $binopt $tbpath${ps}PIM1_WrFIFO_Push
eval add wave -noupdate $hexopt $tbpath${ps}PIM1_RdFIFO_Data
eval add wave -noupdate $binopt $tbpath${ps}PIM1_RdFIFO_Pop
eval add wave -noupdate $hexopt $tbpath${ps}PIM1_RdFIFO_RdWdAddr
eval add wave -noupdate $binopt $tbpath${ps}PIM1_WrFIFO_Empty
eval add wave -noupdate $binopt $tbpath${ps}PIM1_WrFIFO_AlmostFull
eval add wave -noupdate $binopt $tbpath${ps}PIM1_WrFIFO_Flush
eval add wave -noupdate $binopt $tbpath${ps}PIM1_RdFIFO_Empty
eval add wave -noupdate $binopt $tbpath${ps}PIM1_RdFIFO_Flush
eval add wave -noupdate $hexopt $tbpath${ps}PIM1_RdFIFO_Latency
eval add wave -noupdate $binopt $tbpath${ps}PIM1_InitDone
eval add wave -noupdate $binopt $tbpath${ps}PIM1_Clk

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
do clock_generator_0_wave.do

do proc_sys_reset_0_wave.do

do ppc440mc_ddr2_0_wave.do


#  Wave window configuration information
#
configure  wave -justifyvalue          right
configure  wave -signalnamewidth       1

TreeUpdate [SetDefaultTree]

#  Wave window setup complete
#
echo  "Wave window display setup done."
