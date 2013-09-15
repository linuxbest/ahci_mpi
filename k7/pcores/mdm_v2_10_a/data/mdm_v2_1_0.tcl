###############################################################################
##
## (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and 
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
###############################################################################
##
## mdm_v2_1_0.tcl
##
###############################################################################

#***--------------------------------***------------------------------------***
#
#                        SYSLEVEL_DRC_PROC
#
#***--------------------------------***------------------------------------***

proc check_syslevel_settings { mhsinst } {

  set inst_name [xget_hw_parameter_value $mhsinst "INSTANCE"]
  set port_name Debug_SYS_Rst

  set error_str "To be able to reset the system from the debugger, connect the PORT $port_name in $inst_name to the PORT MB_Debug_SYS_Rst in proc_sys_reset"

  if {[check_connected_port $mhsinst $port_name] == 0 && [check_microblaze_present $mhsinst] == 1} {
    error $error_str "" "mdt_error"  
  }

  # Do not allow PLBv46 for 7-series and later families
  set interconnect [xget_hw_parameter_value $mhsinst "C_INTERCONNECT"]
  set use_uart     [xget_hw_parameter_value $mhsinst "C_USE_UART"]
  set family       [xget_hw_parameter_value $mhsinst "C_FAMILY"]
  set error_str "PLBv46 interconnect is not available for $family. Please select AXI interconnect instead."
  #if {$interconnect == 1 && $use_uart == 1 && [series_greater_or_equal $mhsinst 7]} {
  #  error $error_str "" "mdt_error"
  #}
}

proc check_connected_port { mhsinst port_name } {

  set connector [xget_hw_port_value $mhsinst $port_name]

  if {[llength $connector] == 0 || [xcheck_constant_signal $connector]} {
    return 0
  } else {
    return 1
  }

}

proc check_microblaze_present { mhsinst } {

  set mhs_handle [xget_hw_parent_handle $mhsinst]
  set mhsinst_list [xget_hw_ipinst_handle $mhs_handle *]
  
  foreach mhsinst $mhsinst_list {
    set mhsinst_type [xget_hw_value $mhsinst]
    if { $mhsinst_type == "microblaze" } {
	    return 1
    }
  }
  return 0

}

#***--------------------------------***------------------------------------***
#
#                   SAV PROC (XPS GUI IP instantiation)
#
#***--------------------------------***------------------------------------***

# Set a parameter value or add a parameter with a new value to an IP instance
proc set_or_add_parameter_value {mhsinst parameter value} {
   set param_handle [xget_hw_parameter_handle $mhsinst $parameter]
   if {[string length $param_handle] == 0} {
      xadd_hw_ipinst_parameter $mhsinst $parameter $value
   } else {
      xset_hw_parameter_value $param_handle $value
   }
}

# Check if actual family series is greater than or equal to a given series
proc series_greater_or_equal {mhsinst series} {
   if {[string length $mhsinst] == 0} {
      return 0
   }
   set ip_family [xget_hw_parameter_value $mhsinst "C_FAMILY"]
   if {[string length $ip_family] == 0} {
      return 0
   }
   if {[regexp {[A-Za-z]*([0-9]*)[A-Za-z]*} $ip_family match number] == 0} {
      return 0
   }
   if {$number >= $series || $ip_family == "zynq"} {
      return 1
   }
   return 0
}

# Automatically called by XPS when MDM is instantiated
proc xps_sav_add_new_mhsinst {mergedmhs mhsinst mpd} {

   # Set AXI interconnect in MHS for series >= "7"
   set paramvallist {{"C_INTERCONNECT" 2 }}
   set mergedmhsinst [xget_hw_ipinst_handle $mergedmhs [xget_hw_name $mhsinst]]

   foreach paramval $paramvallist {
      if {[series_greater_or_equal $mergedmhsinst "7"]} {
         set_or_add_parameter_value $mhsinst [lindex $paramval 0] [lindex $paramval 1]
      }
   }
}
