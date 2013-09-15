###############################################################################
##
## Copyright (c) 2006 Xilinx, Inc. All Rights Reserved.
##
## xps_bram_if_cntlr_v2_1_0.tcl
##
###############################################################################

## @BEGIN_CHANGELOG EDK_J
##
## - initial 1.00a verion 
##
## @END_CHANGELOG


#***--------------------------------***------------------------------------***
#
# 		             SYSLEVEL_DRC_PROC
#
#***--------------------------------***------------------------------------***

#
# xps_bram_if_cntlr memory controller is connected to a bram block
#
proc check_syslevel_settings { mhsinst } {

    set instname   [xget_hw_parameter_value $mhsinst  "INSTANCE"]

    set busif      [xget_hw_busif_value     $mhsinst  "PORTA"]

    if {[string length $busif] == 0} {

	puts  "\nWARNING: $instname memory controller is not connected to a bram block\n"

    }

}
