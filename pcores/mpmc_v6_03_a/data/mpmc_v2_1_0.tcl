##-----------------------------------------------------------------------------
##-- (c) Copyright 2006 - 2010 Xilinx, Inc. All rights reserved.
##--
##-- This file contains confidential and proprietary information
##-- of Xilinx, Inc. and is protected under U.S. and
##-- international copyright and other intellectual property
##-- laws.
##--
##-- DISCLAIMER
##-- This disclaimer is not a license and does not grant any
##-- rights to the materials distributed herewith. Except as
##-- otherwise provided in a valid license issued to you by
##-- Xilinx, and to the maximum extent permitted by applicable
##-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
##-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
##-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
##-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
##-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
##-- (2) Xilinx shall not be liable (whether in contract or tort,
##-- including negligence, or under any other theory of
##-- liability) for any loss or damage of any kind or nature
##-- related to, arising under or in connection with these
##-- materials, including for any direct, or any indirect,
##-- special, incidental, or consequential loss or damage
##-- (including loss of data, profits, goodwill, or any type of
##-- loss or damage suffered as a result of any action brought
##-- by a third party) even if such damage or loss was
##-- reasonably foreseeable or Xilinx had been advised of the
##-- possibility of the same.
##--
##-- CRITICAL APPLICATIONS
##-- Xilinx products are not designed or intended to be fail-
##-- safe, or for use in any application requiring fail-safe
##-- performance, such as life-support or safety devices or
##-- systems, Class III medical devices, nuclear facilities,
##-- applications related to the deployment of airbags, or any
##-- other applications that could lead to death, personal
##-- injury, or severe property or environmental damage
##-- (individually and collectively, "Critical
##-- Applications"). Customer assumes the sole risk and
##-- liability of any use of Xilinx products in Critical
##-- Applications, subject only to applicable laws and
##-- regulations governing limitations on product liability.
##--
##-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
##-- PART OF THIS FILE AT ALL TIMES.
##-----------------------------------------------------------------------------
##
## mpmc_v2_1_0.tcl
##
#############################################################################
## Order of Evalation of MPD TCL procedures
################################################
# IPLEVEL_UPDATE_VALUE_PROC (on parameters)
#   iplevel_update_mem_bits_data
#   iplevel_update_addr_width
#   iplevel_update_bankaddr_width
#   iplevel_update_bram_init
#   iplevel_update_ecc_datawidth
#   iplevel_update_ecc_dmwidth
#   iplevel_update_ecc_dqswidth
#   iplevel_update_iodelay_grp  
#   iplevel_update_mem_dm_width
#   iplevel_update_mem_dqs_width
#   iplevel_update_mem_dqs_col
#   iplevel_update_mem_parameter
#       init_memory
#           parseCSVFile
#   iplevel_update_mpmc_mcb_drp_clk_present
#   iplevel_update_pim_data_width
#   iplevel_update_splb_native_dwidth
#   iplevel_update_speedgrade
#    
# IPLEVEL_DRC_PROC (on parameters)
#   iplevel_drc_ranks_x_dimms_multiple
#   iplevel_drc_ddr2_dqsn_enable
#   iplevel_drc_partno
#       get_list_aliased_mem_parts
#   iplevel_drc_wr_fifo
#   iplevel_drc_mig_v3
#   iplevel_drc_mem_type
#       get_list_valid_mem_types
#   iplevel_drc_cas_check (workaround)
#   iplevel_drc_pim_data_width (workaround)
#   iplevel_drc_num_ports (workaround)
#   iplevel_drc_arb0_num_slots (workaround)
#   iplevel_drc_mem_data_width (workaround)
#   iplevel_drc_mem_odt_type (workaround)
#   iplevel_drc_mem_reduced_drv (workaround)
#   iplevel_drc_mem_num_ranks (workaround)
#   iplevel_drc_mem_pa_sr (workaround)
#   iplevel_drc_pim_basetype (workaround)
#
# IPLEVEL_DRC_PROC (on IP)
#   check_iplevel_drcs
#       iplevel_drc_arb0_slot    
#       iplevel_drc_fifo_pipeline 
#       iplevel_drc_fifo_type      
#       iplevel_drc_fifo_type_sdma  
#       iplevel_drc_port_validity    
#           iplevel_drc_busif_connectivity
#
# SYSLEVEL_UPDATE_VALUE_PROC (on parameters)
#   syslevel_update_ctrl_parameter
#       init_control
#           get_wr_fifo_mem_pipeline
#   syslevel_update_mmcm_loc
#   syslevel_update_idelayctrl_loc
#   syslevel_update_mem_cas_latency
#   syslevel_update_mem_cas_wr_latency
#   syslevel_update_num_idelayctrl
#   syslevel_update_pim_subtype
#   syslevel_update_training_port
#   syslevel_update_xcl_linesize
#   
# SYSLEVEL_UPDATE_PROC (on IP)
#   none
#
# SYSLEVEL_DRC_PROC (on parameters)
#   syslevel_drc_mpmc_clk0_period_ps
#   syslevel_drc_splb_native_dwidth
#   syslevel_drc_splb_subtype
#   syslevel_drc_training_port
#   syslevel_drc_mig_flow
#       get_mig_ucf_filename
#       get_mig_top_filename
#       get_pin_locs
#   syslevel_drc_micontrol
#   syslevel_drc_conflictmask 
#
# SYSLEVEL_DRC_PROC (on IP)
#   check_syslevel_drcs
#       syslevel_drc_mpmc_clk_200mhz    
#       syslevel_drc_splb_overlap
#       syslevel_drc_mig_freq
#       syslevel_drc_ppc440_virtex5
#
# PLATGEN_SYSLEVEL_UPDATE_PROC (on IP)
#   platgen_syslevel_update
#       generate_corelevel_ucf
#           generate_spartan6_mcb_constraints
#           generate_mig_phy_constraints
#           generate_v5_ddr2_mig_phy_constraints
#           generate_mmcm_loc_constraints
#           generate_idelayctrl_loc_constraints

#
################################################
# Various helper procedures
################################################
# MIG invocation related procedures
#   run_mig
#      generate_cgp_file
#      generate_mig_script
#      generate_mpmcinput_file
#          myxxml_update_subelements
#
# MPMC IP Configurator procedures (GUI)
#   filter_partno
#       init_memory
#           parseCSVFile
#   gui_drc_pim_type
#   mpmc_copy_port_addr
#   mpmc_launch_mig
#   mpmc_left_justify
#   mpmc_restore_default_addr
#   mpmc_restore_default_arb
#   mpmc_restore_default_datapath
#   mpmc_restore_default_debug
#   mpmc_update_arbitration
#   update_memory_parameters
#   update_mpmc_ctrl_highaddr
#   update_mpmc_highaddr
#   mpmc_init_rzq_zio_loc
#   gui_drc_rzq_zio_loc
#
# Various Utility Functions
#   get_list_valid_mem_types
#   get_wr_fifo_mem_pipeline
#   convert_mpmc_to_mig_mem_type
#   convert_mig_to_mpmc_mem_type
#   convert_list_mpmc_to_mig_mem_type
#   convert_list_mig_to_mpmc_mem_type
#   get_mig_version
#   get_mig_excutable
#   get_mig_memory_database
#   get_mig_fpga_database

 
# Load Library for XML parsing
xload_xilinx_library libmXMLTclIf


#***--------------------------------***------------------------------------***
#
#                        IPLEVEL_UPDATE_VALUE_PROC
#
#***--------------------------------***------------------------------------***

#-------------------------------------------
# Aliases the famlies that are supported, if 
# not recognized, pass straight through.
#-------------------------------------------
proc get_family_alias        { family } {

    switch -exact -- $family { 
        spartan3        -
        aspartan3       { return "spartan3" }
        spartan3e       -
        aspartan3e      { return "spartan3e" }
        spartan3a       - 
        aspartan3a      - 
        spartan3adsp    - 
        aspartan3adsp   { return "spartan3a" }
        virtex4         -
        qvirtex4        -
        qrvirtex4       { return "virtex4" }
        virtex5         { return "virtex5" }
        virtex6         -
        qvirtex6        -
        virtex6l        { return "virtex6" }
        qspartan6       -
        qspartan6l      -
        spartan6        -
        aspartan6       -
        spartan6l       { return "spartan6" }
        default         { return $family }
    }
}


#-------------------------------------------
# Base family is used to for most calculations
# C_FAMILY is used only for device specific 
# instantiations/flows (e.g. constraints)
#-------------------------------------------
proc iplevel_update_basefamily { param_handle } { 
    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_FAMILY"]

    return [get_family_alias $family]
}

#-------------------------------------------
# One hot parameters for each of the different phys.
#-------------------------------------------
proc iplevel_update_phy           { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set static_phy  [xget_hw_parameter_value $mhsinst "C_USE_STATIC_PHY"]
    set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set param_name  [xget_hw_name            $param_handle]

    set sdram   [string match -nocase {sdram} $mem_type]
    set lpddr   [string match -nocase {lpddr} $mem_type]
    set ddr1    [string match -nocase {ddr}  $mem_type]
    set ddr2    [string match -nocase {ddr2} $mem_type]
    set ddr3    [string match -nocase {ddr3} $mem_type]

    if {$static_phy || $sdram} { 
      if {[string match {C_USE_STATIC_PHY} $param_name]} { 
          return 1
      } else { 
          return 0
      }
    } else { 
      switch -glob -- "$param_name,$family" { 
          C_USE_MIG_S3_PHY,spartan3* -
          C_USE_MIG_V4_PHY,virtex4   -
          C_USE_MIG_V5_PHY,virtex5 { 
              return [expr {$ddr1 | $ddr2}] }
          C_USE_MIG_V6_PHY,virtex6 { 
              return [expr {$ddr2 | $ddr3}] }
          C_USE_MCB_S6_PHY,spartan6 { 
              return [expr {$lpddr | $ddr1 | $ddr2 | $ddr3}] }
          default { return 0 }
      }
   }
}
#-------------------------------------------
# update C_MEM_BITS_DATA_PER_DQS 
# if C_MEM_PART_DATA_WIDTH == 4 then 4
# else                               8
#-------------------------------------------
proc iplevel_update_mem_bits_data { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set dwidth      [xget_hw_parameter_value $mhsinst "C_MEM_PART_DATA_WIDTH"]
    set mem_dwidth      [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]

    if {($dwidth == 4) || ($mem_dwidth == 4)} {

        return 4

    } else {

        return 8

    }

}


#-------------------------------------------
# update C_MEM_ADDR_WIDTH 
# C_MEM_ADDR_WIDTH = C_MEM_PART_NUM_ROW_BITS
#-------------------------------------------
proc iplevel_update_addr_width { param_handle }  {

    set mhsinst  [xget_hw_parent_handle   $param_handle]
    set row_bits [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_ROW_BITS"]

    return $row_bits

}

#-------------------------------------------
# update C_MEM_BANKADDR_WIDTH 
# C_MEM_BANKADDR_WIDTH = C_MEM_PART_NUM_BANK_BITS
#-------------------------------------------
proc iplevel_update_bankaddr_width { param_handle }  {

    set mhsinst   [xget_hw_parent_handle   $param_handle]
    set bank_bits [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_BANK_BITS"]

    return $bank_bits

}

#-------------------------------------------
# update C_ARB_BRAM_INIT_xx by converting from string of octals to binary
#-------------------------------------------
proc iplevel_update_bram_init { param_handle }  {

    set mhsinst    [xget_hw_parent_handle   $param_handle]
    set paramname  [xget_hw_name            $param_handle]
    set paramvalue [xget_hw_value           $param_handle]
    set family     [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]

    set arb_algo   [xget_hw_parameter_value $mhsinst "C_ARB0_ALGO"]
    set slotno [xget_hw_parameter_value  $mhsinst "C_ARB0_NUM_SLOTS"]

    if {[string match -nocase {CUSTOM} $arb_algo] == 0} {
        return $paramvalue 
    } elseif {[string match -nocase {spartan6} $family]} {
        # Generate Spartan-6
      
        return [get_bram_addr_spartan6 $param_handle 0 [expr {$slotno - 1}]]
    }

    set no_0 $slotno
    set no_1 0

    if {$slotno > 8} {

        set no_0 8
        set no_1 [expr {$slotno - 8}]

    }

    # if C_ARB0_NUM_SLOT = 10
    # then C_ARB_BRAM_INIT_00 is generated from C_ARB0_SLOT0 to C_ARB0_SLOT7
    # then C_ARB_BRAM_INIT_01 is generated from C_ARB0_SLOT8 to C_ARB0_SLOT9
    if {[string compare -nocase "C_ARB_BRAM_INIT_00" $paramname] == 0} {

        return [get_bram_addr $param_handle 0 [expr {$no_0 - 1}]] 

    } elseif {[string compare -nocase "C_ARB_BRAM_INIT_01" $paramname] == 0} {

        return [get_bram_addr $param_handle 8 [expr {$no_1 + 7}]]

    } else {

        return $paramvalue

    }

}

#-------------------------------------------
# update C_ECC_DATA_WIDTH 
#-------------------------------------------
proc iplevel_update_ecc_datawidth { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set paramName   [xget_hw_name            $param_handle]
    set ecc_support [xget_hw_parameter_value $mhsinst "C_INCLUDE_ECC_SUPPORT"]
    set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set mem_dwidth  [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]

    if {$ecc_support == 0} {

        return 0

    } else {

        if {[string match -nocase {SDRAM} $mem_type]} { # SDRAM

            switch $mem_dwidth {
                8       { return 5 }
                16      { return 6 }
                32      { return 7 }
                64      { return 8 }
                default { return 8 }
            }

        } else {  # DDR/DDR2

            switch $mem_dwidth {
                8       { return 8 }
                16      { return 8 }
                32      { return 8 }
                64      { return 8 }
                default { return 8 }
            }
        }
    }

}

#-------------------------------------------
# update C_ECC_DM_WIDTH 
#-------------------------------------------
proc iplevel_update_ecc_dmwidth { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set paramName   [xget_hw_name            $param_handle]
    set ecc_support [xget_hw_parameter_value $mhsinst "C_INCLUDE_ECC_SUPPORT"]
    set mem_bits    [xget_hw_parameter_value $mhsinst "C_MEM_BITS_DATA_PER_DQS"]

    if {$ecc_support == 0} {

        return 0

    } else {

        if {$mem_bits == 4} {

            return 0

        } else {

            return 1

        }
    }
}

#-------------------------------------------
# update C_ECC_DQS_WIDTH 
#-------------------------------------------
proc iplevel_update_ecc_dqswidth { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set paramName   [xget_hw_name            $param_handle]
    set ecc_support [xget_hw_parameter_value $mhsinst "C_INCLUDE_ECC_SUPPORT"]
    set mem_bits    [xget_hw_parameter_value $mhsinst "C_MEM_BITS_DATA_PER_DQS"]
    set ecc_dwidth  [xget_hw_parameter_value $mhsinst "C_ECC_DATA_WIDTH"]

    if {$ecc_support == 0} {

        return 0

    } else {

        if {$ecc_dwidth > 4 && $mem_bits == 4} {

            return 2

        } else {

            return 1

        }
    }
}

#-------------------------------------------
# update C_IODELAY_GRP   
# Set to the same as instance name if not overridden
#-------------------------------------------
proc iplevel_update_iodelay_grp { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
    return $instname
}

#-------------------------------------------
# update C_MEM_DM_WIDTH
# if C_MEM_BITS_DATA_PER_DQS == 8 then C_MEM_DATA_WIDTH/8
# else                            then 1
#-------------------------------------------
proc iplevel_update_mem_dm_width { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set dwidth      [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]
    set bitsdata    [xget_hw_parameter_value $mhsinst "C_MEM_BITS_DATA_PER_DQS"]

    return [expr {$dwidth/$bitsdata}]

}


#-------------------------------------------
# update C_MEM_DQS_WIDTH
# = C_MEM_DATA_WIDTH/C_MEM_BITS_DATA_PER_DQS
#-------------------------------------------
proc iplevel_update_mem_dqs_width { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set dwidth      [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]
    set bitsdata    [xget_hw_parameter_value $mhsinst "C_MEM_BITS_DATA_PER_DQS"]

    return [expr {$dwidth/$bitsdata}]

}

#-------------------------------------------
# update C_MEM_NDQS_COL and C_MEM_DQS_LOC_COL,
# if C_SKIP_SIM_INIT_DELAY = 1, then seed some values to simulate correctly
# if not set do nothing, run DRCs to catch error
#-------------------------------------------
proc iplevel_update_mem_dqs_col { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set name        [xget_hw_name            $param_handle]
    set dwidth      [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]
    set skip_sim    [xget_hw_parameter_value $mhsinst "C_SKIP_SIM_INIT_DELAY"]
    set mig_flow    [xget_hw_parameter_value $mhsinst "C_USE_MIG_FLOW"]

    if {[regexp {C_MEM_NDQS_COL(\d)} $name match num]} { 
        set mig_param_name "nDQS_COL${num}"
    } elseif {[regexp {C_MEM_DQS_LOC_COL(\d)} $name match num ]} {
        set mig_param_name "DQS_LOC_COL${num}"
    } else { 
        error "Internal error parsing MPD parameter: $name" "" "mdt_error"
    }

    if {$mig_flow} { 
        set mig_out         "__xps/mig/gui"

        set mig_top [file join [pwd] $mig_out [get_mig_top_filename $mhsinst]]

        if {[catch {open $mig_top r} TOP]} { 
            # Set to ourself so we don't error out
            set self    [xget_hw_value $param_handle]
            return $self
        #    error "File $mig_top: $TOP.  Please ensure you have sucessfully run MIG\
        #           from the MPMC IP Configurator." "" "mdt_error" 
        } else { 
            while {[gets $TOP line] >= 0} { 
               if {[regexp -nocase {parameter\s+(\w+)\s*=\s*([0-9A-Fh']+),} $line match param value]} { 
                   if {[string match $mig_param_name $param]} { 
                       if {[regexp -nocase {^\d+'h(\d+)$} $value match value_stripped]} {
                           set value_found ${value_stripped}
                       } else { 
                           set value_found $value
                       }
                       # exit loop when value is found
                       break
                   }
               }
            }
            close $TOP

            if {[info exists value_found] == 0} { 
                error "Parameter $name could not be automatically determined.  Unable to parse $mig_top.  Please set\
                       this parameter by hand.  The MPMC data sheet provides details on how to set this parameter\
                       correctly." "" "mdt_error" 
            } else { 
                if {[regexp {C_MEM_DQS_LOC_COL\d} $name match]} {
                    return "0x${value_found}"
                } else { 
                    return ${value_found}
                }

            }
        }
    } elseif {$skip_sim && [string match {C_MEM_NDQS_COL0} $name]} { 
        switch $dwidth {
            8       { return 1 }
            16      { return 2 }
            32      { return 4 }
            64      { return 8 }
            default { return 1 }
        }
    } elseif {$skip_sim && [string match {C_MEM_DQS_LOC_COL0} $name]} { 
        switch $dwidth {
            8       { return 0x00 }
            16      { return 0x0100 }
            32      { return 0x03020100 }
            64      { return 0x0706050403020100 }
            default { return 0x00 }
        }
    } else { 
        set self    [xget_hw_value $param_handle]
        return $self
    }
}

#-------------------------------------------
# given C_MEM_PARTNO
# update a single memory parameter 
#-------------------------------------------
proc iplevel_update_mem_parameter { param_handle } {

    global array_partno_param

    set mhsinst    [xget_hw_parent_handle    $param_handle]
    init_memory    $mhsinst
    set partno     [string toupper [xget_hw_parameter_value  $mhsinst "C_MEM_PARTNO"]]
    set paramname  [string toupper [xget_hw_name             $param_handle]]
    set paramvalue [xget_hw_value            $param_handle]

    # MIG database workaround, remove first 5 characters (MPMC-)
    if { [string match -nocase {mpmc-*} $partno]} {
        set partno [string range $partno 5 end]
    }

    if { [string match -nocase {CUSTOM} $partno] } {
        return $paramvalue
    } elseif {[string match -nocase {NONE} $partno] } {
        return $paramvalue 
    } else {

        set key_value  [array get array_partno_param $partno,$paramname]
        set value      [lindex $key_value 1]

        if {[string length $value]} {
            return  $value
        } else {
            return  $paramvalue
        }
    }
}


#-------------------------------------------
# Update C_MPMC_MCB_DRP_CLK_PRESENT
# If spartan6 and MPMC_MCB_DRP_Clk connected set to 1
# otherwise set to 0
#-------------------------------------------
proc iplevel_update_mpmc_mcb_drp_clk_present { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set port_value  [xget_hw_port_value $mhsinst "MPMC_MCB_DRP_Clk"]

    if {[llength $port_value] == 0} {
      return 0
    } else { 
      return 1
    }

}

#------------------------------------------
# If C_BASEFAMILY == spartan6 then set C_PIMx_DATA_WIDTH 
# based on Port Config
#------------------------------------------
proc iplevel_update_pim_data_width { param_handle } { 
    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set port_config [xget_hw_parameter_value $mhsinst "C_PORT_CONFIG"]
    set param_name  [xget_hw_name            $param_handle]
    set x           [string index $param_name 5]
    set basetype    [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]
    set value       [xget_hw_value           $param_handle]
    set list_pconf  {"B32 B32 U32 U32 U32 U32" "B32 B32 B32 B32" "B64 B32 B32" "B64 B64" "B128"}
    set list_psize  {{ 32 32 32 32 32 32  0  0} \
                     { 32 32 32 32  0  0  0  0} \
                     { 64 32 32  0  0  0  0  0} \
                     { 64 64  0  0  0  0  0  0} \
                     {128  0  0  0  0  0  0  0}}
    set allowed     [lindex [lindex $list_psize $port_config] $x]
    
    if {[string match -nocase {spartan6} $family] && ($allowed == 32) || ($allowed == 64)} { 
        if {$basetype == 4 || $basetype == 6 || $basetype == 7 || $basetype == 8 || $basetype == 9 } { 
            return $allowed
        }
    }
    return $value
}

#-------------------------------------------
# Update C_SPLBx_NATIVE_DWIDTH
# If spartan6 and basetype == 2, then set according to the port configuration
# otherwise return back the current value.
#-------------------------------------------
proc iplevel_update_splb_native_dwidth { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set param_value [xget_hw_value $param_handle]
    set name        [xget_hw_name $param_handle]

    # get the port number from C_SPLBx_NATIVE_DWIDTH
    set x [string index $name 6]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]

    # Check for Spartan6 And set native_dwidth appropriately
    if {[string match -nocase {spartan6} $family]} { 
        set basetype    [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]

        if {$basetype == 2 } { 
            set port_config [xget_hw_parameter_value $mhsinst "C_PORT_CONFIG"]
            set list_psize  {{ 32 32 32 32 32 32  0  0} \
                             { 32 32 32 32  0  0  0  0} \
                             { 64 32 32  0  0  0  0  0} \
                             { 64 64  0  0  0  0  0  0} \
                             {128  0  0  0  0  0  0  0}}
            set allowed     [lindex [lindex $list_psize $port_config] $x]
            
            return $allowed
        }
    }

    # return back default value
    return $param_value

}

#-------------------------------------------
# update C_SPEEDGRADE_INT
# Remove the - from the speedgrade. Return an int.
#-------------------------------------------
proc iplevel_update_speedgrade { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set speedgrade  [xget_hw_parameter_value $mhsinst "C_SPEEDGRADE"]
    if {[ regexp {.*?(\d+).*?} $speedgrade match speedgrade_int ]} { 
        return $speedgrade_int
    } else {
        return 0
    }

}

#***--------------------------------***-----------------------------------***
#
#                          IPLEVEL_DRC_PROC (Parameters)
#
#***--------------------------------***-----------------------------------***

#------------------------------------------
# if PARAM & C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS != 0 then error
#------------------------------------------
proc iplevel_drc_ranks_x_dimms_multiple { param_handle } {

    set mhsinst     [xget_hw_parent_handle    $param_handle]
    set ranks       [xget_hw_parameter_value $mhsinst "C_MEM_NUM_RANKS"]
    set dimms       [xget_hw_parameter_value $mhsinst "C_MEM_NUM_DIMMS"]
    set my_param    [xget_value $param_handle]

    if {(${my_param} % (${ranks} * ${dimms})) != 0 } {

        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]

        error "This parameter must be set to a multiple of C_MEM_NUM_RANKS*C_MEM_NUM_DIMMS." "" "mdt_error" 

    }
}

#------------------------------------------
# if C_BASEFAMILY = virtex5 | virtex6 AND
#    C_MEM_TYPE = DDR2 AND
#    C_USE_STATIC_PHY = 0 AND
#    C_DDR2_DQSN_ENABLE = 0
# then error out
# or  
# if C_BASEFAMILY = spartan3 AND
#    C_MEM_TYPE = DDR2 AND
#    C_DDR2_DQSN_ENABLE = 1
# then error out
# or  
# if C_BASEFAMILY = aspartan3 AND
#    C_MEM_TYPE = DDR2 AND
#    C_DDR2_DQSN_ENABLE = 1
# then error out
#------------------------------------------
proc iplevel_drc_ddr2_dqsn_enable { param_handle } {

    set mhsinst     [xget_hw_parent_handle    $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set static_phy  [xget_hw_parameter_value $mhsinst "C_USE_STATIC_PHY"]
    set ddr2_dqsn   [xget_hw_parameter_value $mhsinst "C_DDR2_DQSN_ENABLE"]
    set period      [xget_hw_parameter_value $mhsinst "C_MPMC_CLK_MEM_2X_PERIOD_PS"]

    if { [ string match -nocase {spartan6} $family ] && [ string match -nocase {DDR2} $mem_type ] \
        && $ddr2_dqsn == 0 && $period <= 2500 } {

        error "This parameter must be set to 1 when using DDR2 memory on a Spartan-6 family and running above 200MHz." "" "mdt_error" 

    }
    if {([ string match -nocase {virtex5} $family ] || [ string match -nocase {virtex6} $family ]) \
        && [ string match -nocase {DDR2} $mem_type ] && $static_phy == 0 && $ddr2_dqsn == 0 } {

        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "This parameter must be set to 1 when using the DDR2 MIG PHY on a Virtex-5/Virtex-6 families." "" "mdt_error" 

    }
    if { [string match -nocase {spartan3} $family] && [string match -nocase {DDR2} $mem_type] && $ddr2_dqsn == 1 } {

        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "This parameter must be set to 0 when using DDR2 memory on Spartan-3 family.\
               This family does not support differential input with MPMC." "" "mdt_error" 

    }
}

#------------------------------------------
# check C_MEM_PARTNO 
# - The value must be set
#------------------------------------------
proc iplevel_drc_partno { param_handle } {

    global array_partno_param
    set mhsinst     [xget_hw_parent_handle    $param_handle]
    set partno [string toupper [xget_hw_value $param_handle]]
    set family [xget_hw_parameter_value $mhsinst C_BASEFAMILY]

    if { [string match -nocase {CUSTOM} $partno] || [string match -nocase {Select a part} $partno ]} {
        return
    } elseif {[string match -nocase {NONE} $partno]} {
        error "The parameter C_MEM_PARTNO must be specified.  Please open the MPMC IP Configuator and set a valid part number." "" "mdt_error" 
    }

    # MIG database workaround, remove first 5 characters (MPMC-)
    if { [string match -nocase {mpmc-*} $partno] } {
        set partno [string range $partno 5 end]
    }

    # search for arbitrary value that exists
    set list   [array get array_partno_param $partno,C_MEM_CLK_WIDTH]

    if {[string match $family "virtex6"]} { 
        set parts_list [get_list_aliased_mem_parts $mhsinst $partno]
        if {[llength $parts_list] == 1} {
            puts "WARNING: MPMC memory part number \"$partno\" has been deprecated and \"[lindex $parts_list 0]\" is a possible replacement.  Please update your design with a unambigious part number for parameter C_MEM_PARTNO."
        } elseif {[llength $parts_list] > 1} { 
            puts "WARNING: MPMC memory part number \"$partno\" has been deprecated and more than one memory in the database is similar.  Please update your design with a unambigious part number for parameter C_MEM_PARTNO."
        }
    }

    if {[llength $list] == 0} {

        error "The memory part number you have chosen, \"$partno\", is not found in the memory\
               database.  Please open the MPMC IP Configuator and set a valid part number for \
               the current architecture.  Note: The memory parts supported on \
               Virtex-6/Spartan-6 architectures differ from previous generation architectures.\
               The part numbers supplied for Virtex-6/Spartan-6 are derived directly from \
               Coregen MIG rather than from MPMCs own database. " "" "mdt_error"
   }
    
}

# Returns back a list of aliased part numbers replaceing XXX suffixes with globs in search.  Only valid
# on spartan6/virtex6
proc get_list_aliased_mem_parts { mhsinst partno } { 

    global array_partno_param
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]

    if {[string match -nocase {virtex6*} $family] || [string match -nocase {spartan6*} $family] } { 
        if {[regexp -nocase {([^X]+)([X]+)(-\w+)} $partno match prefix wild suffix]} { 
            set num_wild [string length $wild]
            set part_search $prefix
            for {set x 0} {$x < $num_wild} {incr x 1} {
                set part_search "${part_search}?"
            }
            set part_search "${part_search}${suffix}"
            set parts_match [array get array_partno_param $part_search,C_MEM_CLK_WIDTH]
            set parts_list {}
            if {[llength $parts_match]} {

                # Create a list of matching parts, excluding the original part.
                foreach {key value} $parts_match { 
                    set matching_part [lindex [split $key ,] 0]
                    if {![string match -nocase $matching_part $partno]} { 
                        lappend parts_list [lindex [split $key ,] 0]
                    }
                }
                return $parts_list
            }
        }
    }
    # No aliases found
    return {}
}
    

#------------------------------------------
# if C_PIMx_BASETYPE == 1
#    if C_PIMx_SUBTYPE != IXCL && C_XCLx_WRITEXFER > 0
#       AND C_PIx_WR_FIFO_TYPE = DISABLED
#    then error out
#    if C_XCLx_B_IN_USE == 1 
#      if C_PIMx_B_SUBTYPE != IXCL && C_XCLx_B_WRITEXFER > 0
#         AND C_PIx_WR_FIFO_TYPE = DISABLED
#      then error out
#------------------------------------------
proc iplevel_drc_wr_fifo { param_handle } {

    set mhsinst     [xget_hw_parent_handle    $param_handle]
    set name    [xget_hw_name   $param_handle]

    # Find the port number by grabbing the number from C_PIx_WR_FIFO_TYPE
    set x       [string index $name 4]

    set basetype  [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]

    if {$basetype == 1} {

        set subtype  [xget_hw_parameter_value $mhsinst "C_PIM${x}_SUBTYPE"]
        set xfer [xget_hw_parameter_value $mhsinst "C_XCL${x}_WRITEXFER"]
        set wr   [xget_hw_parameter_value $mhsinst "C_PI${x}_WR_FIFO_TYPE"]
        set b_in_use [xget_hw_parameter_value $mhsinst "C_XCL${x}_B_IN_USE"]

        if {[string match -nocase {IXCL*} $subtype] == 0 && $xfer > 0 && [string match -nocase {DISABLED} $wr]} {

            error "XCL port $x cannot be configured to be Read-Only (C_PI${x}_WR_FIFO_TYPE = DISABLED) when\
                   C_XCL${x}_WRITEXFER > 0." "" "mdt_error" 

        }

        if {$b_in_use == 1} {

            set b_subtype  [xget_hw_parameter_value $mhsinst "C_PIM${x}_B_SUBTYPE"]
            set b_xfer [xget_hw_parameter_value $mhsinst "C_XCL${x}_B_WRITEXFER"]

            if {[string match -nocase {IXCL*} $b_subtype] == 0 && $b_xfer > 0 && [string match -nocase {DISABLED} $wr]} {
            
                error "XCL port $x cannot be configured to be Read-Only (C_PI${x}_WR_FIFO_TYPE = ${wr}) when\
                       C_XCL${x}_B_IN_USE == 1 && C_XCL${x}_B_WRITEXFER > 0." "" "mdt_error" 
            
            }
        }
    }
}

#------------------------------------------
# If   iplevel_drc_mem_dq_io_ms != 0 
# then Error out;
#------------------------------------------
proc iplevel_drc_mig_v3 { param_handle } {

    set mhsinst     [xget_hw_parent_handle    $param_handle]
    set name        [xget_hw_name   $param_handle]
    set value       [xget_hw_value  $param_handle]

    if {$value != 0} {
        error "$name is deprecated as of mpmc_v5_02_a.  Please remove this parameter from your MHS. Note: Update your UCF as some constraints have been removed.  Please view the mpmc user guide for upgrade instructions."
    }
}

#------------------------------------------
# If   C_MEM_TYPE does not exist in list of valid memories for the given family
# then Error out;
#------------------------------------------
proc iplevel_drc_mem_type { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set mem_type    [xget_hw_value           $param_handle]
    
    set l_mem_types [get_list_valid_mem_types $family]
    set uc_mem_type [string toupper $mem_type]

    # search for the upper case memory type in the list, error if it's not found.
    if {[lsearch -exact -ascii $l_mem_types $uc_mem_type] == -1} { 
        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        # format the list to look nice
        if {[llength $l_mem_types] > 1} { 
            set supported_mem_types [join [lrange $l_mem_types 0 end-1] {, }]
            append supported_mem_types " and "
            append supported_mem_types [lindex $l_mem_types end]

        } else { 
            set supported_mem_types [lindex $l_mem_types 0]
        }
        error "$instname\:\:Memory type $mem_type is not supported on $family.\n\
               The supported memory types on $family are $supported_mem_types." "" "mdt_error" 
    }
}

#------------------------------------------
# If   (CAS != 0 && FREQ != 0) AND
#      (CAS >10 | CAS < 5) AND C_MEM_TYPE == DDR3 OR
#      (CAS >6  | CAS < 2) AND C_BASEFAMILY == "spartan6" OR
#      (CAS >7  | CAS < 2) AND C_BASEFAMILY != "spartan6"
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = ([xstrncmp C_MEM_TYPE  DDR3 ]*5 | ![xstrncmp C_MEM_TYPE  DDR3 ]*1.5:[xstrncmp C_MEM_TYPE  DDR3 ]*10 | [xstrncmp C_BASEFAMILY  spartan6 ]*![xstrncmp C_MEM_TYPE  DDR3 ]*6 | ![xstrncmp C_BASEFAMILY  spartan6 ]*![xstrncmp C_MEM_TYPE  DDR3 ]*7)
#
proc iplevel_drc_cas_check { param_handle } {

    set mhsinst     [xget_hw_parent_handle    $param_handle]
    set mem_type    [xget_hw_parameter_value  $mhsinst "C_MEM_TYPE"]
    set family      [xget_hw_parameter_value  $mhsinst "C_BASEFAMILY"]
    set value       [xget_hw_value            $param_handle]
    set param_name  [xget_hw_name             $param_handle]
    set param_freq  [xget_hw_parameter_value  $mhsinst "${param_name}_FMAX"]
    
    if { $value != 0 && $param_freq != 0 } {
        if {[string match -nocase {DDR3} $mem_type]} { 
            if { $value > 10 || $value < 5 } {
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "$instname\:\:CAS latency ($value) must be in the range 5 to 10 for DDR3." "" "mdt_error" 
            }
        } else {
            if {[string match -nocase {spartan6} $family]} { 
                if { $value > 6 || $value < 2 } {
                    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                    error "$instname\:\:CAS latency ($value) must be in the range 2 to 6 for Spartan-6." "" "mdt_error" 
                }
            } else {
                if { $value > 7 || $value < 2 } {
                    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                    error "$instname\:\:CAS latency ($value) must be in the range 2 to 7 for non Spartan-6." "" "mdt_error" 
                }
            }
        }
    }
}

#------------------------------------------
# If   C_BASEFAMILY != spartan6 AND C_PIMx_DATA_WIDTH > 64 OR
#      C_BASEFAMILY == spartan6 AND C_PIMx_DATA_WIDTH != "C_PORT_CONFIG.DATA_WIDTHx"
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = (32,![xstrncmp C_BASEFAMILY  spartan6 ]*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*((C_PORT_CONFIG == 2 || C_PORT_CONFIG == 3)*64 | (C_PORT_CONFIG != 2 && C_PORT_CONFIG != 3)*32), [xstrncmp C_BASEFAMILY  spartan6 ]*(C_PORT_CONFIG == 4)*128 | (C_PORT_CONFIG != 4 || ![xstrncmp C_BASEFAMILY  spartan6 ])*32)
# RANGE = (32,![xstrncmp C_BASEFAMILY  spartan6 ]*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*(C_PORT_CONFIG == 3)*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*(C_PORT_CONFIG != 3)*32)
# RANGE = (32,![xstrncmp C_BASEFAMILY  spartan6 ]*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*32)
#
proc iplevel_drc_pim_data_width { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set port_config [xget_hw_parameter_value $mhsinst "C_PORT_CONFIG"]
    set param_name  [xget_hw_name            $param_handle]
    set x           [string index $param_name 5]
    set basetype    [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]
    set value       [xget_hw_value           $param_handle]
    set list_pconf  {"B32 B32 U32 U32 U32 U32" "B32 B32 B32 B32" "B64 B32 B32" "B64 B64" "B128"}
    set list_psize  {{ 32 32 32 32 32 32  0  0} \
                     { 32 32 32 32  0  0  0  0} \
                     { 64 32 32  0  0  0  0  0} \
                     { 64 64  0  0  0  0  0  0} \
                     {128  0  0  0  0  0  0  0}}
    set allowed     [lindex [lindex $list_psize $port_config] $x]
    
    if {[string match -nocase {spartan6} $family]} { 
        if {$basetype == 4 || $basetype == 6 || $basetype == 7 || $basetype == 8 || $basetype == 9 } { 
            if { $value != $allowed } {
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "$instname\:\:PIM${x} Data width ($value) is not allowed for this port ($x) with the current PORT_CONFIG ($port_config\:[lindex $list_pconf $port_config]). It should be $allowed" "" "mdt_error" 
            }
        }
    } else {
        if { $value > 64 || $value < 32 } {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "$instname\:\:PIM${x} Data width ($value) must be in the range 32 to 64 for non Spartan-6." "" "mdt_error" 
        }
    }
}

#------------------------------------------
# If   C_BASEFAMILY == spartan6 AND
#      ( C_PORT_CONFIG == 0 AND C_NUM_PORTS > 6 OR
#      ( C_PORT_CONFIG == 1 AND C_NUM_PORTS > 4 OR
#      ( C_PORT_CONFIG == 2 AND C_NUM_PORTS > 3 OR
#      ( C_PORT_CONFIG == 3 AND C_NUM_PORTS > 2 OR
#      ( C_PORT_CONFIG == 4 AND C_NUM_PORTS > 1) 
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = (1:[xstrncmp C_BASEFAMILY  spartan6 ]*((C_PORT_CONFIG == 4)*1 | (C_PORT_CONFIG == 3)*2 | (C_PORT_CONFIG == 2)*3 | (C_PORT_CONFIG == 1)*4 | (C_PORT_CONFIG == 0)*6 ) | ![xstrncmp C_BASEFAMILY  spartan6 ]*8)
#
proc iplevel_drc_num_ports { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set port_config [xget_hw_parameter_value $mhsinst "C_PORT_CONFIG"]
    set value       [xget_hw_value           $param_handle]
    
    if {[string match -nocase {spartan6} $family]} { 
        if {( $port_config == 0 && $value > 6 ) ||
            ( $port_config == 1 && $value > 4 ) ||
            ( $port_config == 2 && $value > 3 ) ||
            ( $port_config == 3 && $value > 2 ) ||
            ( $port_config == 4 && $value > 1 )} {
            set list_pconf  {"B32 B32 U32 U32 U32 U32" "B32 B32 B32 B32" "B64 B32 B32" "B64 B64" "B128"}
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "$instname\:\:Unsupported number of ports (${value}) for current port configuration (${port_config}\:[lindex $list_pconf $port_config]) on Spartan-6." "" "mdt_error" 
        }
    }
}

#------------------------------------------
# If   C_BASEFAMILY == spartan6 AND 
#      C_ARB0_NUM_SLOTS != 10 AND
#      C_ARB0_NUM_SLOTS != 12 
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = ([xstrncmp C_BASEFAMILY  spartan6 ]*10 | ![xstrncmp C_BASEFAMILY  spartan6 ]*1:10,[xstrncmp C_BASEFAMILY  spartan6 ]*12 | ![xstrncmp C_BASEFAMILY  spartan6 ]*11:[xstrncmp C_BASEFAMILY  spartan6 ]*12 | ![xstrncmp C_BASEFAMILY  spartan6 ]*16)
#
proc iplevel_drc_arb0_num_slots { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set value       [xget_hw_value           $param_handle]
    
    if {[string match -nocase {spartan6} $family] && $value != 10 && $value != 12} { 
        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "$instname\:\:Only 10 or 12 arbitration slots can be used for Spartan-6." "" "mdt_error" 
    }
}

#------------------------------------------
# If   C_BASEFAMILY == spartan6 AND data_width > 16 OR
#      C_BASEFAMILY != spartan6 AND data_width == 4
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = ([xstrncmp C_BASEFAMILY  spartan6 ]*4 | ![xstrncmp C_BASEFAMILY  spartan6 ]*8,8,16,![xstrncmp C_BASEFAMILY  spartan6 ]*32 | [xstrncmp C_BASEFAMILY  spartan6 ]*16,![xstrncmp C_BASEFAMILY  spartan6 ]*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*16)
#
proc iplevel_drc_mem_data_width { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set mem_width   [xget_hw_value           $param_handle]
    set list_supported_mem_widths [get_list_valid_mem_widths $mhsinst $family]
    
    if {[lsearch $list_supported_mem_widths $mem_width] == -1} { 
        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        if {[llength $list_supported_mem_widths] > 1} { 
            set supported_mem_widths "are "
            append supported_mem_widths [join [lrange $list_supported_mem_widths 0 end-1] {, }]
            append supported_mem_widths " and "
            append supported_mem_widths [lindex $list_supported_mem_widths end]

        } else { 
            set supported_mem_widths "is [lindex $list_supported_mem_widths 0]"
        }
        if {[string match -nocase {spartan6} $family]} { 
            append supported_mem_widths ". The Spartan-6 hard memory controller also requires that the width of the memory part matches the total width of the controller"
        }


        error "$instname\:\:A $mem_type memory data bus width of $mem_width is not supported on ${family} with the memory part you have chosen.\n\
               The supported memory data bus width(s) on $family with $mem_type ${supported_mem_widths}." "" "mdt_error" 
    }
}

#------------------------------------------
# If   C_MEM_TYPE != DDR3 AND C_MEM_ODT_TYPE > 3
# elsif C_MEM_TYPE == DDR3 and C_BASEFAMILY == virtex6 and C_MEM_ODT_TYPE > 3 
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = (0,![xstrncmp C_MEM_TYPE  DDR3 ]*1 | [xstrncmp C_MEM_TYPE  DDR3 ]*4:![xstrncmp C_MEM_TYPE  DDR3 ]*3 | [xstrncmp C_MEM_TYPE  DDR3 ]*8)
# RZQ/12 and RZQ/8 not supported on DDR3 when not using dynamic ODT.
proc iplevel_drc_mem_odt_type { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set odt_type    [xget_hw_value           $param_handle]
    set family      [xget_hw_parameter_value  $mhsinst "C_BASEFAMILY"]
    set list_ddr2_odt    {"Disabled" "75 Ohm" "150 Ohm" "Reserved/50 Ohm" "RZQ/4" "RZQ/2" "RZQ/6" "RZQ/12" "RZQ/8"}
    set list_ddr3_odt    {"Disabled" "RZQ/4" "RZQ/2" "RZQ/6" "RZQ/12" "RZQ/8"}
    
    if {[string match -nocase {ddr3} $mem_type] == 0} { 
        if { $odt_type > 3 } {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "$instname\:\:Unsupported C_MEM_ODT_TYPE value ($odt_type\: [lindex $list_ddr3_odt $odt_type]) only allowed for DDR3." "" "mdt_error" 
        }
    } elseif {[string match -nocase {virtex6} $family]} { 
        if { $odt_type > 3 } {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "$instname\:\:Unsupported C_MEM_ODT_TYPE value ($odt_type\: [lindex $list_ddr3_odt $odt_type]) not allowed for DDR3 when dynamic ODT is disabled (default.)" "" "mdt_error" 
        }
    }


}

#------------------------------------------
# If   C_MEM_TYPE == LPDDR AND (C_MEM_REDUCED_DRV == 1 OR C_MEM_REDUCED_DRV > 4) OR
#      C_MEM_TYPE == DDR3 AND (C_MEM_REDUCED_DRV < 5 ) OR
#      C_MEM_TYPE != LPDDR AND C_MEM_TYPE != DDR3 AND C_MEM_REDUCED_DRV > 1
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = ([xstrncmp C_MEM_TYPE DDR3]*5, ![xstrncmp C_MEM_TYPE DDR3]*![xstrncmp C_MEM_TYPE LPDDR] | [xstrncmp C_MEM_TYPE LPDDR]*2 | [xstrncmp C_MEM_TYPE DDR3]*6 : ![xstrncmp C_MEM_TYPE DDR3]*![xstrncmp C_MEM_TYPE LPDDR] | [xstrncmp C_MEM_TYPE LPDDR]*4 | [xstrncmp C_MEM_TYPE DDR3]*6)
#
proc iplevel_drc_mem_reduced_drv { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set ods_type    [xget_hw_value           $param_handle]
    set list_ods    {"FULL" "REDUCED" "HALF" "QUARTER" "THREEQUARTERS" "RZQ/6" "RZQ/7"}
    
    if {[string match -nocase {lpddr} $mem_type]} { 
        if { $ods_type == 1 || $ods_type > 4} {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "$instname\:\:Unsupported C_MEM_REDUCED_DRV value ($ods_type\: [lindex $list_ods $ods_type]) for C_MEM_TYPE LPDDR." "" "mdt_error" 
        }
    } elseif {[string match -nocase {ddr3} $mem_type]} { 
        if { $ods_type > 2} {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "$instname\:\:Unsupported C_MEM_REDUCED_DRV value ($ods_type\: [lindex $list_ods $ods_type]) for C_MEM_TYPE DDR3." "" "mdt_error" 
        }
    } else { 
        if { $ods_type > 1} {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "$instname\:\:Unsupported C_MEM_REDUCED_DRV value ($ods_type\: [lindex $list_ods $ods_type]) for C_MEM_TYPE SDRAM/DDR/DDR2." "" "mdt_error" 
        }
    }
}

#------------------------------------------
# If   C_BASEFAMILY = spartan6 AND C_MEM_NUM_RANKS > 1
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = (1:[xstrncmp C_BASEFAMILY  spartan6 ]*1 | ![xstrncmp C_BASEFAMILY  spartan6 ]*2)
#
proc iplevel_drc_mem_num_ranks { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set value       [xget_hw_value           $param_handle]
    
    if {([string match -nocase {spartan6} $family]) && ($value > 1)} { 
        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "$instname\:\:Only 1 rank allowed for Spartan-6." "" "mdt_error" 
    }
}

#------------------------------------------
# If   ( C_BASEFAMILY   != spartan6 AND
#        C_MEM_PA_SR > 0 ) OR 
#      ( C_MEM_TYPE != LPDDR AND
#        C_MEM_PA_SR > 0 )
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = (0:[xstrncmp C_MEM_TYPE  LPDDR ])
#
proc iplevel_drc_mem_pa_sr { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set value       [xget_hw_value           $param_handle]
    
    if {(([string match -nocase {spartan6} $family] == 0) || ([string match -nocase {LPDDR} $mem_type] == 0))
         && ($value > 0)} { 
        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "$instname\:\:Only memory type LPDDR for Spartan-6 can use half PA." "" "mdt_error" 
    }
}

#------------------------------------------
# If   C_BASEFAMILY != spartan6 AND C_PIMx_BASETYPE == 7
# then Error out;
# if C_PIM_BASETYPE == SDMA && C_MEM_SDR_DATA_WIDTH < 32
# then Error out;
#------------------------------------------
# Workaround for:
# RANGE = (0:6+[xstrncmp C_BASEFAMILY  spartan6 ])
#
proc iplevel_drc_pim_basetype { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst       "C_BASEFAMILY"]
    set port_config [xget_hw_parameter_value $mhsinst       "C_PORT_CONFIG"]
    set base_type   [xget_hw_value           $param_handle]
    set mem_type    [xget_hw_parameter_value $mhsinst       "C_MEM_TYPE"]
    set mem_width   [xget_hw_parameter_value $mhsinst       "C_MEM_DATA_WIDTH"]
    if [string match -nocase {SDRAM} $mem_type] { 
        set mem_sdr_width $mem_width
    } else { 
        set mem_sdr_width [expr {2*$mem_width}]
    }
    set param_name  [xget_hw_name            $param_handle]
    set list_pconf  {"B32 B32 U32 U32 U32 U32" "B32 B32 B32 B32" "B64 B32 B32" "B64 B64" "B128"}
    
    # get the port number from C_PIMx_BASETYPE
    set x [string index $param_name 5]
    
    if {([string match -nocase {spartan6} $family] == 0) && ([string match -nocase {virtex6} $family] == 0) } { 
        # Check if it is a non Spartan-6 error.
        if { $base_type == 7 || $base_type == 8 || $base_type == 9 } { 
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "Port type MCB is only available for Spartan-6." "" "mdt_error" 
        }

        if { $base_type == 3 && [string match -nocase {ddr*} $mem_type] && $mem_sdr_width < 32 } {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "Port type SDMA (3) is only available with $mem_type when the external memory data width is greater than or equal to 16 bits.  " "" "mdt_error" 
        }
        if { $base_type == 3 && [string match -nocase {sdram} $mem_type] && $mem_sdr_width < 32 } {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "Port type SDMA (3) is only available with $mem_type when the external memory data width is greater than or equal to 32 bits.  " "" "mdt_error" 
        }
         
    } else  { 
        # MCB sub sets
        if { $port_config == 0 } { 
            if { $base_type == 7 && $x > 1 } { 
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "Port type MCB (Bidirectional) is not available for port $x in current PORT_CONFIG ($port_config\:[lindex $list_pconf $port_config])." "" "mdt_error" 
            }
        } else {
            if { $base_type == 8 || $base_type == 9 } { 
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "Port type MCB-Read and MCB-Write are only available for config 0 and port 2 through 4." "" "mdt_error" 
            }
        }
    }
    
}

#***--------------------------------***-----------------------------------***
#
#                               IPLEVEL_DRC_PROC (IP)
#
#***--------------------------------***-----------------------------------***

proc check_iplevel_drcs {mhsinst} {

    ## Run the arbitration DRC only for custom algorithm 
    set arb_algo [xget_hw_parameter_value $mhsinst "C_ARB0_ALGO"]
    if {[string match -nocase {CUSTOM} $arb_algo]} {
        iplevel_drc_arb0_slot     $mhsinst
    }

    iplevel_drc_fifo_pipeline     $mhsinst 
    iplevel_drc_fifo_type         $mhsinst
    iplevel_drc_fifo_type_sdma    $mhsinst
    iplevel_drc_port_validity     $mhsinst
}

#------------------------------------------
# check C_ARB0_SLOTx, x = 0:C_ARB0_NUM_SLOT 
# - the number of digit of the value 
#   must be = C_NUM_PORTS
# - each digit must be <= C_NUM_PORTS - 1
#------------------------------------------
proc iplevel_drc_arb0_slot { mhsinst } {

    set slotno   [xget_hw_parameter_value $mhsinst "C_ARB0_NUM_SLOTS"]
    set portno   [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]

    for {set x 0} {$x < $slotno} {incr x 1} {

        set value [xget_hw_parameter_value $mhsinst "C_ARB0_SLOT$x"]

        # check the number of digit of the value
        if { [string length $value] != $portno } {
            error "Invalid parameter C_ARB0_SLOT$x = $value.  The value must be $portno digits.  Please see the MPMC\
                   datasheet for details on how to properly set this parameter." "" "mdt_error"
        }

        # check each digit must be <= C_NUM_PORTS - 1
        #       no duplicate digit
        set listDigit ""

        for {set i 0} {$i < [string length $value]} {incr i 1} {

            set digit [string index $value $i]

            if {$digit >= $portno} {
                set num_ports0 [expr {$portno - 1}]
                error "Invalid parameter C_ARB0_SLOT$x = $value.  Each digit must be less than or equal to\
                       $num_ports0.  Please see the MPMC datasheet for details on how to properly set this\
                       parameter." "" "mdt_error" 
            }

            if {[lsearch $listDigit $digit] == -1} {
                lappend listDigit $digit
            } else {
                error "Invalid parameter C_ARB0_SLOT$x = $value.  Each digit must be unique.  Please see the MPMC\
                       datasheet for details on how to properly set this parameter." "" "mdt_error" 
            }
        }
    }
}

#------------------------------------------
# for ports x < C_NUM_PORTS
# C_PIx_RD_FIFO_MEM_PIPELINE must be all the same
# C_PIx_WR_FIFO_MEM_PIPELINE must be all the same
# If the FIFOs are DISABLED or if the PORT is INACTIVE, then these are not to be considered
#------------------------------------------
proc iplevel_drc_fifo_pipeline { mhsinst } {

    set portno [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]
    set rd_pipeline_mode ""
    set wr_pipeline_mode ""

    for {set x 0} {$x < $portno} {incr x 1} {

        set rd_x_fifo_type [xget_hw_parameter_value $mhsinst "C_PI${x}_RD_FIFO_TYPE"]
        set wr_x_fifo_type [xget_hw_parameter_value $mhsinst "C_PI${x}_WR_FIFO_TYPE"]

        set rd [xget_hw_parameter_value $mhsinst "C_PI${x}_RD_FIFO_MEM_PIPELINE"]
        set wr [xget_hw_parameter_value $mhsinst "C_PI${x}_WR_FIFO_MEM_PIPELINE"]

        set i_btype [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]
        set s_btype [lindex {INACTIVE XCL PLB SDMA MPMC_PIM PPC440MC VFBC} $i_btype]

        # Port is valid 
        if { [string match -nocase {INACTIVE} $s_btype] == 0 } {  

            ## Read Fifo
            # Port is not disabled
            if { [string match -nocase {DISABLED} $rd_x_fifo_type] == 0 } { 
                # Check if the initial RD fifo mode has been set
                if { [string match -nocase {} $rd_pipeline_mode] == 0 } { 
                    # Compare the pipeline set to prior ports. Fail if not matching
                    if { $rd_pipeline_mode != $rd } { 
                        error "Read Memory Pipeline setting for all MPMC ports should be same. Check the memory\
                               pipeline settings in the Data Configuration section of the Advanced tab of Memory\
                               configuration\n" "" "mdt_error"
                    }
                } else { ## This is the first valid read fifo
                    set rd_pipeline_mode $rd
                }
            }

            ## Write Fifo
            # Port is not disabled
            if { [string match -nocase {DISABLED} $wr_x_fifo_type] == 0 } { 
                # Check if the initial WR fifo mode has been set
                if { [string match -nocase {} $wr_pipeline_mode] == 0 } { 
                    # Compare the pipeline set to prior ports. Fail if not matching
                    if { $wr != $wr_pipeline_mode } { 
                         error "Write Memory Pipeline setting for all MPMC ports should be same. Check the memory\
                                pipeline settings in the Data Configuration section of the Advanced tab of Memory\
                                configuration.\n" "" "mdt_error"
                    }
                # This is the first valid write fifo
                } else { 
                    set wr_pipeline_mode $wr
                }
            }
        }
    }
}

#------------------------------------------
# for ports x < C_NUM_PORTS
# if C_PIx_RD_FIFO_TYPE = DISABLED AND 
#    C_PIx_WR_FIFO_TYPE = DISABLED
# then error out
#------------------------------------------
proc iplevel_drc_fifo_type { mhsinst } {

    set portno [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]

    for {set x 0} {$x < $portno} {incr x 1} {

        set rd [xget_hw_parameter_value $mhsinst "C_PI${x}_RD_FIFO_TYPE"]
        set wr [xget_hw_parameter_value $mhsinst "C_PI${x}_WR_FIFO_TYPE"]
        
        if {[string match -nocase {DISABLED} $rd] && [string match -nocase {DISABLED} $wr]} {

            error "Port $x cannot be configured to be both Read-Only and Write-Only." "" "mdt_error" 
        
        }
    }
}

#------------------------------------------
# check port x < C_NUM_PORTS and C_PIMx_BASETYPE = 3 (sdma)
# if C_PIx_RD_FIFO_TYPE = DISABLED OR
#    C_PIx_WR_FIFO_TYPE = DISABLED
# then error out
#------------------------------------------
proc iplevel_drc_fifo_type_sdma { mhsinst } {

    set portno [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]

    for {set x 0} {$x < $portno} {incr x 1} {

        set btype [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]

        if {$btype != 3} {
            continue
        }

        set rd    [xget_hw_parameter_value $mhsinst "C_PI${x}_RD_FIFO_TYPE"]
        set wr    [xget_hw_parameter_value $mhsinst "C_PI${x}_WR_FIFO_TYPE"]
        
        if {[string match -nocase {DISABLED} $rd] || [string match -nocase {DISABLED} $wr]} {

            error "SDMA Port $x cannot be configured to be Read-Only or Write-Only.  Please ensure that writes and\
                   reads FIFO types are SRL or BRAM." "" "mdt_error" 
        }
    }
}

#------------------------------------------
# check if multiple bus interfaces are 
# defined, but some are invalid
#------------------------------------------
proc iplevel_drc_port_validity { mhsinst } {

    # check the connectivity for bus interfaces
    # XCLx, SPLBx, SDMA_CTRLx, SDMA_LLx, MPMC_PIMx, PPC440MCx, VFBCx

    for {set x 0} {$x < 8} {incr x 1} {

        iplevel_drc_busif_connectivity $mhsinst "XCL${x}"       ${x}
        iplevel_drc_busif_connectivity $mhsinst "XCL${x}_B"     ${x}
        iplevel_drc_busif_connectivity $mhsinst "SPLB${x}"      ${x}
        iplevel_drc_busif_connectivity $mhsinst "SDMA_CTRL${x}" ${x}
        iplevel_drc_busif_connectivity $mhsinst "SDMA_LL${x}"   ${x}
        iplevel_drc_busif_connectivity $mhsinst "MPMC_PIM${x}"  ${x}
        iplevel_drc_busif_connectivity $mhsinst "PPC440MC${x}"  ${x}
        iplevel_drc_busif_connectivity $mhsinst "VFBC${x}"      ${x}
    }

}

proc iplevel_drc_busif_connectivity {mhsinst busif port} {

    set connector [xget_hw_busif_value $mhsinst $busif]

    if {[llength $connector] == 0 } {
        return
    }

    # convert BASETYPE value (0-6) to string 
    set i_btype [xget_hw_parameter_value $mhsinst "C_PIM${port}_BASETYPE"]
    set s_btype [lindex {INACTIVE XCL PLB SDMA MPMC_PIM PPC440MC VFBC} $i_btype]
    set portno  [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]

    if { $port >= $portno || [string match -nocase *${s_btype}* $busif] == 0} {

        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        set ipname   [xget_hw_option_value    $mhsinst "IPNAME"]
        puts  "WARNING:  $instname ($ipname) -  The bus interface $busif is invalid."
    }
}


#***--------------------------------***-----------------------------------***
#
#                            SYSLEVEL_UPDATE_VALUE_PROC
#
#***--------------------------------***-----------------------------------***

#-------------------------------------------
# update C_CTRL_* parameter
#-------------------------------------------
proc syslevel_update_ctrl_parameter { param_handle } {

    global array_ctrl_param

    set mhsinst    [xget_hw_parent_handle    $param_handle]
    init_control   $mhsinst
    set paramname  [xget_hw_name             $param_handle]
    set paramvalue [xget_hw_value            $param_handle]

    set newvalue   [lindex [array get array_ctrl_param $paramname] 1]

    if {[string length $newvalue] == 0} {
        return  $paramvalue
    } else {
        return  $newvalue
    }
}


#-------------------------------------------
# if C_USE_MIG_FLOW == 1 then
# update the locations from MIG UCF
# else use default value "not_set"
#-------------------------------------------
proc iplevel_update_mmcm_loc { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set mig_flow    [xget_hw_parameter_value $mhsinst "C_USE_MIG_FLOW"]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set param_name  [xget_hw_name $param_handle]

    if {$mig_flow == 1 && [string match -nocase {virtex6} $family]} {

        set mem_type [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        set mig_out         "__xps/mig/gui"

        set mig_ucf [file join [pwd] $mig_out [get_mig_ucf_filename $mhsinst]]

        if {[catch {open $mig_ucf r} UCF]} { 

            return "NOT_SET"
#            error "File $mig_ucf: $UCF.  Please ensure you have sucessfully run MIG\
#                   from the MPMC IP Configurator." "" "mdt_error" 
        } else { 
            while {[gets $UCF line] >= 0} { 
               if {[string match {C_MMCM_INT_LOC} $param_name]} { 
                   if {[regexp -nocase {inst.*u_mmcm_clk_base.*LOC.*=.*(MMCM_ADV_X\d+Y\d+)} $line match mmcm_loc]} { 
                       set loc_found $mmcm_loc
                   }
               } elseif {[string match {C_MMCM_EXT_LOC} $param_name]} {
                   if {[regexp -nocase {inst.*u_mmcm_adv.*LOC.*=.*(MMCM_ADV_X\d+Y\d+)} $line match mmcm_loc]} { 
                       set loc_found $mmcm_loc
                   }
               }
            }

            close $UCF

            if {[info exists loc_found] == 0} { 
                error "MMCM_ADV LOC constraints could not be determined.  Unable to parse $mig_ucf.  Please set\
                       this parameter by hand.  The MPMC data sheet provides details on how to set this parameter\
                       correctly." "" "mdt_error" 
            } else { 
                return $loc_found
            }
        }
    } else {
        return "NOT_SET"
    }
}

#-------------------------------------------
# if C_USE_MIG_FLOW == 1 then
# update the locations from MIG UCF
# else use default value "not_set"
#-------------------------------------------
proc syslevel_update_idelayctrl_loc { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set mig_flow    [xget_hw_parameter_value $mhsinst "C_USE_MIG_FLOW"]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]

    if {$mig_flow == 1 && ([string match {virtex4} $family] || [string match {virtex5} $family])} {

        set mem_type [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        set mig_out         "__xps/mig/gui"

        set mig_ucf [file join [pwd] $mig_out [get_mig_ucf_filename $mhsinst]]

        if {[catch {open $mig_ucf r} UCF]} { 
            error "File $mig_ucf: $UCF.  Please ensure you have sucessfully run MIG\
                   from the MPMC IP Configurator." "" "mdt_error" 
        } else { 
            while {[gets $UCF line] >= 0} { 
               if {[regexp -nocase {inst.*LOC=(IDELAYCTRL_X\d+Y\d+)} $line match idelay_loc]} { 
                   lappend locList $idelay_loc
               }
            }

            close $UCF

            if { [info exists locList] == 0 || [llength $locList] < 1 } { 
                error "IDELAYCTRL LOC constraints could not be determined.  Unable to parse $mig_ucf.  Please set\
                       this parameter by hand.  The MPMC data sheet provides details on how to set this parameter\
                       correctly " "" "mdt_error" 
            } else { 
                return [join $locList "-"]
            }
        }
    } else {
        return "NOT_SET"
    }
}

#-------------------------------------------
# update C_MEM_CAS_LATENCY
# Choose CAS Latency from list of valid CAS latencies based 
# on the lowest CAS latency that is valid for the frequency.
#-------------------------------------------
proc syslevel_update_mem_cas_latency { param_handle } {

    global array_partno_param
    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set partno      [xget_hw_parameter_value $mhsinst "C_MEM_PARTNO"]

    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    if {[string match -nocase {spartan6} $family]} { 
      set clk_period      [expr {[xget_hw_parameter_value $mhsinst "C_MPMC_CLK_MEM_2X_PERIOD_PS"]*2}]
      syslevel_drc_mpmc_clk_mem_2x_period_ps $mhsinst
    } elseif {[string match -nocase {virtex6} $family]} { 
      #set clk_period      [xget_hw_parameter_value $mhsinst "C_MPMC_CLK_MEM_PERIOD_PS"]
      set mpmc_clk_period  [xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]
      set clk_period  [expr {$mpmc_clk_period/2}]
    } else {
      set clk_period  [xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]
    }
      
    #-------------------------------------------
    #Limit the minimum frequency to 66MHz
    if {$clk_period > 15000} {
      set clk_period 15000;
    }
    set cas_a       [xget_hw_parameter_value $mhsinst "C_MEM_PART_CAS_A"]
    set cas_b       [xget_hw_parameter_value $mhsinst "C_MEM_PART_CAS_B"]
    set cas_c       [xget_hw_parameter_value $mhsinst "C_MEM_PART_CAS_C"]
    set cas_d       [xget_hw_parameter_value $mhsinst "C_MEM_PART_CAS_D"]
    set cas_a_fmax  [xget_hw_parameter_value $mhsinst "C_MEM_PART_CAS_A_FMAX"]
    set cas_b_fmax  [xget_hw_parameter_value $mhsinst "C_MEM_PART_CAS_B_FMAX"]
    set cas_c_fmax  [xget_hw_parameter_value $mhsinst "C_MEM_PART_CAS_C_FMAX"]
    set cas_d_fmax  [xget_hw_parameter_value $mhsinst "C_MEM_PART_CAS_D_FMAX"]

    # Do comparisons in time domain, convert from frequency max to period 
    # min if period min does not exist
    set cas_a_tmin [lindex [array get array_partno_param $partno,C_MEM_PART_CAS_A_TMIN ] 1]

    if {[info exists array_partno_param($partno,C_MEM_PART_CAS_A_TMIN)]} {
        set cas_a_tmin [lindex [array get array_partno_param $partno,C_MEM_PART_CAS_A_TMIN ] 1]
        set cas_a_tmin [expr {$cas_a_tmin - 1}]
    } else { 
        set cas_a_tmin [expr {floor(1000000.0/($cas_a_fmax+1))}]
    }
    if {[info exists array_partno_param($partno,C_MEM_PART_CAS_B_TMIN)]} {
        set cas_b_tmin [lindex [array get array_partno_param $partno,C_MEM_PART_CAS_B_TMIN ] 1]
        set cas_b_tmin [expr {$cas_b_tmin - 1}]
    } else { 
        set cas_b_tmin [expr {floor(1000000.0/($cas_b_fmax+1))}]
    }
    if {[info exists array_partno_param($partno,C_MEM_PART_CAS_C_TMIN)]} {
        set cas_c_tmin [lindex [array get array_partno_param $partno,C_MEM_PART_CAS_C_TMIN ] 1]
        set cas_c_tmin [expr {$cas_c_tmin - 1}]
    } else { 
        set cas_c_tmin [expr {floor(1000000.0/($cas_c_fmax+1))}]
    }
    if {[info exists array_partno_param($partno,C_MEM_PART_CAS_D_TMIN)]} {
        set cas_d_tmin [lindex [array get array_partno_param $partno,C_MEM_PART_CAS_D_TMIN ] 1]
        set cas_d_tmin [expr {$cas_d_tmin - 1}]
    } else { 
        set cas_d_tmin [expr {floor(1000000.0/($cas_d_fmax+1))}]
    }

    set freq        [expr {floor(1000000 / $clk_period)}]

    syslevel_drc_mpmc_clk0_period_ps $mhsinst

    if {$clk_period >= $cas_a_tmin} {
        return [expr {round($cas_a)}]
    } elseif {$clk_period >= $cas_b_tmin} {
        return [expr {round($cas_b)}]
    } elseif {$clk_period >= $cas_c_tmin} {
        return [expr {round($cas_c)}]
    } elseif {$clk_period >= $cas_d_tmin} {
        return [expr {round($cas_d)}]
    }

    error "Not able to find a suitable memory CAS latency for frequency ${freq}MHz (${clk_period}ps.)  If this is your\
           intended clock frequency, please ensure you have set the C_MEM_PART_CAS_\[A-D\], and\
           C_MEM_PART_CAS_\[A-D\]_FMAX parameters correctly.  Please see the MPMC data sheet for more details\
           on these parameters." "" "mdt_error"

}

#-------------------------------------------
# update C_MEM_CAS_WR_LATENCY
# DDR3 CAS Write Latency                        
# tCKavg = 2.5ns   to < 3.3 ns , CWL = 5 
# tCKavg = 1.875ns to < 2.5 ns , CWL = 6 
# tCKavg = 1.5ns   to < 1.875ns, CSL = 7 
# tCKavg = 1.25ns  to < 1.5ns  , CWL = 8
#-------------------------------------------
proc syslevel_update_mem_cas_wr_latency { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    if {[string match -nocase {spartan6} $family]} { 
      set period      [expr {[xget_hw_parameter_value $mhsinst "C_MPMC_CLK_MEM_2X_PERIOD_PS"]*2}]
    } elseif {[string match -nocase {virtex6} $family]} { 
      set period  [expr {[xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"] / 2}]
    } else {
      set period      [xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]
    }
    
    if { $period < 1500 } {
        return 8
    } elseif { $period < 1875 } {
        return 7
    } elseif { $period < 2500 } {
        return 6
    } else {
        return 5
    }
}

#-------------------------------------------
# if C_USE_MIG_FLOW == 1 then
# update from MIG verilog
# else use default value
#-------------------------------------------
proc syslevel_update_num_idelayctrl { param_handle } {

    set mhsinst     [xget_hw_parent_handle   $param_handle]
    set mig_flow    [xget_hw_parameter_value $mhsinst "C_USE_MIG_FLOW"]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]

    # only valid if using mig flow on v4/v5
    if {$mig_flow == 1 && ([string match {virtex4} $family] || [string match {virtex5} $family])} {

        set mem_type [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        set mig_out         "__xps/mig/gui"

        set mig_ucf [file join [pwd] $mig_out [get_mig_ucf_filename $mhsinst]]

        if {[catch {open $mig_ucf r} UCF]} { 
            error "File $mig_ucf: $UCF.  Please ensure you have sucessfully run MIG \
                   from the MPMC IP Configurator." "" "mdt_error" 
        } else { 
            while {[gets $UCF line] >= 0} { 
               if {[regexp -nocase {inst.*LOC=(IDELAYCTRL_X\d+Y\d+)} $line match idelay_loc]} { 
                   lappend locList $idelay_loc
               }
            }

            close $UCF

            if { [info exists locList] == 0 || [llength $locList] < 1 } { 
                error "Unable to determine number of IDELAYCTRL to instantiate." "" "mdt_error" 
                error "Unable to determine number of IDELAYCTRL to instantiate.  Unable to parse $mig_ucf.  Please set\
                       this parameter by hand.  The MPMC data sheet provides details on how to set this parameter\
                       correctly " "" "mdt_error" 
            } else { 
                return [llength $locList]
            }
        }
    } else {
        return 1
    }
}


#-------------------------------------------
# update C_PIMx_SUBTYPE, x = 0:C_NUM_PORTS - 1
#
# - if XCLx is connected
#   set to IXCL  or DXCL  if it's connected to MB
#   set to IXCL2 or DXCL2 if it's connected to MB v7.20 or greater
#
# - if SPLBx is connected for PPC405 architectures & 
#   if #master connectors = 1 && #slave connectors = 1
#   if SPLBx_NATIVE_DWIDTH == 64 && SPLBx_DATA_WIDTH == 64
#      && SPLBx_SMALLEST_MASTER == 64
#       set to DPLB, if busif = DPLB* -- * can only be 0 or 1. 
#       set to IPLB, if busif = IPLB* -- * can only be 0 or 1.
# - else
#   set to C_PIMx_BASETYPE 
#
# Note that on PPC405 architectures the bus interfaces for PLB are *PLB0 & *PLB1
#-------------------------------------------
proc syslevel_update_pim_subtype { param_handle } {

    set mpmcinst   [xget_hw_parent_handle   $param_handle]
    set param_name [xget_hw_name            $param_handle]
    set portno     [xget_hw_parameter_value $mpmcinst "C_NUM_PORTS"]
    set list_btype {INACTIVE XCL PLB SDMA NPI PPC440MC VFBC MCB MCB-Read MCB-Write}
    set x          [string index $param_name 5]
    set basetype   [xget_hw_parameter_value $mpmcinst "C_PIM${x}_BASETYPE"]

    if {$x >= $portno} {
        return [xget_hw_value $param_handle]
    }

    set mhs_handle [xget_hw_parent_handle $mpmcinst]

    # check the connectivity for bus XCLx - p2p, target vs. initiator
    if {$basetype == 1} {
        if {[string match -nocase {*PIM*_B_*} $param_name]} { 
            set b_in_use [xget_hw_parameter_value $mpmcinst "C_XCL${x}_B_IN_USE"]
            if {$b_in_use == 0} { 
                return "INACTIVE"
            }
            set connector [xget_hw_busif_value $mpmcinst "XCL${x}_B"]
            
        } else {
            set connector [xget_hw_busif_value $mpmcinst "XCL$x"]
        }
        if {[llength $connector] == 0} {
            return "INACTIVE"
        } else {
            set busifs [xget_hw_connected_busifs_handle $mhs_handle $connector "initiator"]

            if {[string length $busifs] != 0} {
                set busif_parent [xget_hw_parent_handle $busifs]
                set iptype       [xget_hw_option_value  $busif_parent "IPTYPE"]

                if { [string match -nocase {PROCESSOR} $iptype] == 1 } {
                    set bus_if_name [xget_hw_name $busifs]
                    # We are connected to microblaze determine if we are I/DXCL or I/DXCL2 
                    if {[string match -nocase {ixcl} ${bus_if_name}]} { 
                        set interface [xget_hw_parameter_value $busif_parent "C_ICACHE_INTERFACE"]
                        if {[info exists interface] == 1 && $interface == 1} { 
                            return "IXCL2"
                        } else { 
                            return "IXCL"
                        }
                    } elseif {[string match -nocase {dxcl} ${bus_if_name}]} { 
                        set interface [xget_hw_parameter_value $busif_parent "C_DCACHE_INTERFACE"]
                        if {[info exists interface] == 1 && $interface == 1} { 
                            return "DXCL2"
                        } else { 
                            return "DXCL"
                        }
                    }
                } 
            }
        }
        return "XCL"
    } elseif {$basetype == 2} {
        # check the connectivity for bus SPLBx
        set connector [xget_hw_busif_value $mpmcinst "SPLB$x"]

        if {[llength $connector] != 0} {
            set m_busifs  [xget_hw_connected_busifs_handle $mhs_handle $connector "master"]
            set s_busifs [xget_hw_connected_busifs_handle $mhs_handle $connector "slave"]

            # MASTER connectors number must be 1 
            # SLAVE connectors number must be 1 (MPMC itself)
            if {[llength $m_busifs] == 1 && [llength $s_busifs] == 1} {
                set native_dwidth [xget_hw_parameter_value $mpmcinst "C_SPLB${x}_NATIVE_DWIDTH"]
                set dwidth [xget_hw_parameter_value $mpmcinst "C_SPLB${x}_DWIDTH"]
                set smallest_master [xget_hw_parameter_value $mpmcinst "C_SPLB${x}_SMALLEST_MASTER"]
                set busif_parent [xget_hw_parent_handle $m_busifs]
                set iptype [xget_hw_option_value  $busif_parent "IPTYPE"]

                if {$native_dwidth == 64 && $dwidth == 64 && $smallest_master == 64} { 
                    if { [string compare -nocase "PROCESSOR" $iptype] == 0} {
                        set busif_name [xget_hw_name $m_busifs]

                        if {[string compare -nocase DPLB1 $busif_name] == 0 \
                            || [string compare -nocase DPLB0 $busif_name] == 0} {
                            return "DPLB"
                        } elseif {[string compare -nocase IPLB1 $busif_name] == 0 \
                                  || [string compare -nocase IPLB1 $busif_name] == 0} {
                            return "IPLB"
                        } 
                    }
                }
            }
        }
        return "PLB"
    } else {
        return [lindex $list_btype $basetype]
    }
}

#-------------------------------------------
# update C_WR_TRAINING_PORT = x, when the 
# first port (0-7) found that satisfies 
# - Not an IXCL Port
# - Not an XCL with WRITEXFER set to 0
# - Not an IPLB or INACTIVE PORT
# - Not a disabled write fifo PORT
#-------------------------------------------
proc syslevel_update_training_port { param_handle } {

    set mhsinst [xget_hw_parent_handle   $param_handle]
    set portno  [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]

    for {set x 0} {$x < $portno} {incr x 1} {

        set subtype     [xget_hw_parameter_value $mhsinst "C_PIM${x}_SUBTYPE"]
        set b_subtype   [xget_hw_parameter_value $mhsinst "C_PIM${x}_B_SUBTYPE"]
        set b_in_use    [xget_hw_parameter_value $mhsinst "C_XCL${x}_B_IN_USE"]
        set fifotype    [xget_hw_parameter_value $mhsinst "C_PI${x}_WR_FIFO_TYPE"]
        set basetype    [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]
        set writexfer   [xget_hw_parameter_value $mhsinst "C_XCL${x}_WRITEXFER"]
        set b_writexfer [xget_hw_parameter_value $mhsinst "C_XCL${x}_B_WRITEXFER"]

        # Port cannot be IXCL* and if port b is enabled, it also cannot be IXCL
        if {[string match -nocase {IXCL*} $subtype] && ($b_in_use == 0 || [string match -nocase {IXCL*} $b_subtype])} {
            continue
        }
        
        # Port cannot be XCL if all WRITEXFER settings are 0
        if {$basetype == 1 && ($writexfer == 0 && ($b_in_use == 0 || $b_writexfer == 0))} { 
            continue
        }
        
        # Port cannot be IPLB or INACTIVE
        if {[string match -nocase {IPLB} $subtype] || [string match -nocase {INACTIVE} $subtype]} {
            continue
        }

        # Port cannot have the write fifo disabled 
        if {[string match -nocase {DISABLED} $fifotype]} {
            continue
        }
        
        # if we get this far, then we've found our port
        return $x
    }

    # not found, default to 0
    return 0
}


#-------------------------------------------
# update C_PIMx_LINESIZE,
#
# - if XCLx is connected to:
#       IXCL, then assign C_XCLx_LINESIZE to C_ICACHE_LINE_LEN
#       DXCL, then assign C_XCLx_LINESIZE to C_DCACHE_LINE_LEN
#   else return vdefault value
#-------------------------------------------
proc syslevel_update_xcl_linesize { param_handle } {

    set mpmcinst   [xget_hw_parent_handle   $param_handle]
    set param_name [xget_hw_name            $param_handle]
    set portno     [xget_hw_parameter_value $mpmcinst "C_NUM_PORTS"]
    set x          [string index $param_name 5]
    set basetype   [xget_hw_parameter_value $mpmcinst "C_PIM${x}_BASETYPE"]

    # If this port isn't active, return default value
    if {$x >= $portno} {
        return [xget_hw_value $param_handle]
    }

    set mhs_handle [xget_hw_parent_handle $mpmcinst]

    # check the connectivity for bus XCLx
    if {$basetype == 1} {
        if {[string match -nocase {C_XCL*_B_LINESIZE} $param_name]} { 
            set b_in_use [xget_hw_parameter_value $mpmcinst "C_XCL${x}_B_IN_USE"]
            # if this is C_XCLx_B_LINESIZE and B_IN_USE is not enabled, return default value
            if {$b_in_use == 0} { 
                return [xget_hw_value $param_handle]
            }
            set connector [xget_hw_busif_value $mpmcinst "XCL${x}_B"]
            
        } else {
            set connector [xget_hw_busif_value $mpmcinst "XCL$x"]
        }
        # If bus is not connected return default value
        if {[llength $connector] == 0} {
            return [xget_hw_value $param_handle]
        } else {
            set busifs [xget_hw_connected_busifs_handle $mhs_handle $connector "initiator"]

            if {[string length $busifs] != 0} {
                set busif_parent [xget_hw_parent_handle $busifs]
                set iptype       [xget_hw_option_value  $busif_parent "IPTYPE"]

                if { [string match -nocase {PROCESSOR} $iptype] == 1 } {
                    set bus_if_name [xget_hw_name $busifs]
                    # We are connected to microblaze determine if we are I/DXCL or I/DXCL2 
                    if {[string match -nocase {ixcl} ${bus_if_name}]} { 
                        set line_len [xget_hw_parameter_value $busif_parent "C_ICACHE_LINE_LEN"]
                        if {[info exists line_len] == 1} { 
                            return $line_len
                        } else { 
                            return [xget_hw_value $param_handle]
                        }
                    } elseif {[string match -nocase {dxcl} ${bus_if_name}]} { 
                        set line_len [xget_hw_parameter_value $busif_parent "C_DCACHE_LINE_LEN"]
                        if {[info exists line_len] == 1} { 
                            return $line_len
                        } else { 
                            return [xget_hw_value $param_handle]
                        }
                    }
                } 
            }
        }
    }
    # return default value if we get here
    return [xget_hw_value $param_handle]
}

#***--------------------------------***-----------------------------------***
#
#                          SYSLEVEL_DRC_PROC (Parameters)
#
#***--------------------------------***-----------------------------------***

proc syslevel_drc_mpmc_clk_mem_2x_period_ps { mhsinst } {

    set family          [xget_hw_parameter_value $mhsinst C_BASEFAMILY]
    if { [string match -nocase {spartan6} $family] } { 
        util_drc_period_ps $mhsinst "MPMC_Clk_Mem_2x"
    }
}
#------------------------------------------
# Check C_MPMC_CLK0_PERIOD_PS to be sure it matches the value reported back from the tools.
#------------------------------------------
proc syslevel_drc_mpmc_clk0_period_ps { mhsinst } {

    util_drc_period_ps $mhsinst "MPMC_Clk0"
}

proc util_drc_period_ps { mhsinst clock} {

    set clock_port [xget_hw_port_handle $mhsinst $clock]
    set clock_frequency [xget_hw_subproperty_value $clock_port "CLK_FREQ_HZ"]
    set clock_param_name [string toupper "C_${clock}_period_ps"]
    set c_clk_period_ps [xget_hw_parameter_value $mhsinst $clock_param_name]

    if {$c_clk_period_ps == 1} { 
        error "Clock period for $clock is not set and cannot be derived from the system.  Please set the clock period of this input clock with the parameter $clock_param_name.  Alternatively, if this clock is a direct input to the EDK system, then ensure that the input port has the CLK_FREQ attribute set." "" "mdt_error"
    } elseif {$clock_frequency == ""} {
        set    instname   [xget_hw_parameter_value $mhsinst "INSTANCE"]
        set    ipname     [xget_hw_option_value    $mhsinst "IPNAME"]
        puts  "WARNING:  $instname ($ipname) - Could not determine clock frequency on input clock port $clock,\
               not performing clock DRCs."
    } else { 
       
        set clk_period [expr {pow(10,12) / $clock_frequency}]
        set clk_period_max [expr {pow(10,12) / ($clock_frequency - $clock_frequency * 0.001)}]
        set clk_period_min [expr {pow(10,12) / ($clock_frequency + $clock_frequency * 0.001)}]

        if { $c_clk_period_ps > $clk_period_max || $c_clk_period_ps < $clk_period_min } {
            error "The clock period specifed ($c_clk_period_ps ps) does not fall within 0.1% of the frequency\
                   $clock_frequency Hz reported on $clock.  Please check your clock frequency settings in your\
                   system." "" "mdt_error" 
        }
    }

}

#------------------------------------------
# if C_PIMx_BASETYPE == 2 (PLB) AND
#    C_SPLBx_NATIVE_DWIDTH = 32 AND 
#    C_SPLBx_DWIDTH        = 64 OR
#    C_SPLBx_DWIDTH        = 128 OR
#    C_BASEFAMILY = spartan6 AND 
#    ((C_PORT_CONFIG < 2 AND C_SPLBx_NATIVE_DWIDTH == 64) OR
#     (x > 1 AND C_SPLBx_NATIVE_DWIDTH == 64) OR
#     (C_PORT_CONFIG == 2 AND C_SPLBx_NATIVE_DWIDTH == 64 AND x == 1))
# then error out
#------------------------------------------
# Workaround for:
# RANGE = (32,![xstrncmp C_BASEFAMILY  spartan6 ]*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*((C_PORT_CONFIG == 2 || C_PORT_CONFIG == 3)*64 | (C_PORT_CONFIG != 2 && C_PORT_CONFIG != 3)*32))
# RANGE = (32,![xstrncmp C_BASEFAMILY  spartan6 ]*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*(C_PORT_CONFIG == 3)*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*(C_PORT_CONFIG != 3)*32)
# RANGE = (32,![xstrncmp C_BASEFAMILY  spartan6 ]*64 | [xstrncmp C_BASEFAMILY  spartan6 ]*32)
#
proc syslevel_drc_splb_native_dwidth { param_handle } {

    set mhsinst [xget_hw_parent_handle $param_handle]
    set name    [xget_hw_name $param_handle]

    # get the port number from C_SPLBx_NATIVE_DWIDTH
    set x [string index $name 6]
    
    set native      [xget_hw_parameter_value $mhsinst "C_SPLB${x}_NATIVE_DWIDTH"]
    set dwidth      [xget_hw_parameter_value $mhsinst "C_SPLB${x}_DWIDTH"]
    set basetype    [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]
    set port_config [xget_hw_parameter_value $mhsinst "C_PORT_CONFIG"]
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    
    # Check for Spartan6 port violations.
    if {[string match -nocase {spartan6} $family]} { 
        if {$basetype == 2 } { 
            set list_pconf  {"B32 B32 U32 U32 U32 U32" "B32 B32 B32 B32" "B64 B32 B32" "B64 B64" "B128"}
            set list_psize  {{ 32 32 32 32 32 32  0  0} \
                             { 32 32 32 32  0  0  0  0} \
                             { 64 32 32  0  0  0  0  0} \
                             { 64 64  0  0  0  0  0  0} \
                             {128  0  0  0  0  0  0  0}}
            set allowed     [lindex [lindex $list_psize $port_config] $x]
            
            if { $native != $allowed } {
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "$instname\:\:SPLB${x} Native data width ($native) is not allowed for this port ($x) with the current PORT_CONFIG ($port_config\:[lindex $list_pconf $port_config])." "" "mdt_error" 
            }
        }
    }

    # Ordinary external vs. internal data width checks.
    if {$basetype == 2 && $native == 32 && ($dwidth == 128 || $dwidth == 64 )} {

        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "$instname\:\:C_SPLB$x has native width set to 32. The bus connected to the port has width of $dwidth.\
               A 32 bit MPMC port can only be connected to a 32 bit wide bus." "" "mdt_error" 
    }
    
}


#-------------------------------------------
# - if C_SPLBx_SUBTYPE is DPLB or IPLB then 
#     if C_SPLB_NATIVE_DWIDTH != 64 then error out
#     if C_SPLB_DWIDTH != 64 then error out
#     if C_SPLB_P2P != 1 then error out 
#     if C_SPLB_SMALLEST_MASTER != 64 then error out
#
#-------------------------------------------
proc syslevel_drc_splb_subtype { param_handle } {

    set mhsinst [xget_hw_parent_handle $param_handle]
    set name    [xget_hw_name $param_handle]

    # get the port number from C_PIMx_SUBTYPE
    set x [string index $name 5]

    set basetype   [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]

    if {$basetype == 2} {

        set subtype [xget_hw_parameter_value $mhsinst "C_PIM${x}_SUBTYPE"]

        if { [string compare -nocase "IPLB" $subtype ] == 0 || [string compare -nocase "DPLB" $subtype ] == 0} {

            set native_dwidth   [xget_hw_parameter_value $mhsinst "C_SPLB${x}_NATIVE_DWIDTH"]
            set dwidth          [xget_hw_parameter_value $mhsinst "C_SPLB${x}_DWIDTH"]
            set p2p             [xget_hw_parameter_value $mhsinst "C_SPLB${x}_P2P"]
            set smallest_master [xget_hw_parameter_value $mhsinst "C_SPLB${x}_SMALLEST_MASTER"]
            set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]

            if {$native_dwidth != 64} {
                error "$instname\:\:SPLB${x} is set to DPLB or IPLB subtype but C_SPLB${x}_NATIVE_DWIDTH is not set to\
                       64.  This combination is invalid." "" "mdt_error" 
            }
            if {$dwidth != 64} {
                error "$instname\:\:SPLB${x} is set to DPLB or IPLB subtype but C_SPLB${x}_DWIDTH is not set to 64. \
                       This combination is invalid." "" "mdt_error" 
            }
            if {$p2p != 1} {
                error "$instname\:\:SPLB${x} is set to DPLB or IPLB subtype but C_SPLB${x}_P2P is not set to 1. \
                       This combination is invalid." "" "mdt_error" 
            }
            if {$smallest_master != 64} {
                error "$instname\:\:SPLB${x} is set to DPLB or IPLB subtype but C_SPLB${x}_SMALLEST_MASTER is not set\
                       to 64.  This combination is invalid." "" "mdt_error" 
            }
        }
    }
}


#-------------------------------------------
# check C_WR_TRAINING_PORT
# check that there is at least 1 writable port.
# Cannot have only IXCL and IPLB PIMs
# Port has to be writeable, C_XCL0_WRITEXFER == 0 is invalid or if 
# Wr_FIFO_TYPE is disabled
#-------------------------------------------
proc syslevel_drc_training_port { param_handle } {

    set mhsinst [xget_hw_parent_handle   $param_handle]

    # get the port number from C_WR_TRAINING_PORT
    set x       [xget_hw_value $param_handle]

    # check C_PIMx_SUBTYPE != IXCL or IPLB AND
    # C_PIx_WR_FIFO_TYPE    = BRAM or SRL
    set subtype  [xget_hw_parameter_value $mhsinst "C_PIM${x}_SUBTYPE"]
    set b_subtype  [xget_hw_parameter_value $mhsinst "C_PIM${x}_B_SUBTYPE"]
    set b_in_use   [xget_hw_parameter_value $mhsinst "C_XCL${x}_B_IN_USE"]
    set fifotype [xget_hw_parameter_value $mhsinst "C_PI${x}_WR_FIFO_TYPE"]
    set basetype  [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]
    set writexfer [xget_hw_parameter_value $mhsinst "C_XCL${x}_WRITEXFER"]
    set b_writexfer [xget_hw_parameter_value $mhsinst "C_XCL${x}_B_WRITEXFER"]

    # check xcl isn't IXCL or IXCL2
    if {$basetype == 1} {
        if {[string match -nocase {IXCL*} $subtype ] && ($b_in_use  == 0 || [string match -nocase {IXCL*} $b_subtype ])} {
            error "Port ${x} is an read only port (${subtype}) - Invalid write training port.  Please set a valid\
                   write training for this parameter." "" "mdt_error" 
        }

        if {$writexfer == 0 && ($b_in_use == 0 || $b_writexfer == 0)} { 
            error "Port ${x} is an read only port (C_XCL{x}WRITEXFER == 0) - Invalid write training port.  Please set a\
                   valid write training for this parameter." "" "mdt_error" 
        }
    }

    # check port isn't IPLB
    if {$basetype == 2 && [string match -nocase {IPLB} $subtype]} {
        error "Port ${x} has the subtype $subtype which is read only - Invalid write training port.  Please set a valid\
               write training for this parameter." "" "mdt_error" 
    }

    # check port isn't write disabled
    if {[string match -nocase {DISABLED} $fifotype]} {
        error "Port ${x} is an ready only port (C_PI${x}_WRFIFO == ${fifotype}) - Invalid write training port.  Please\
               set a valid write training for this parameter." "" "mdt_error" 
    }

    return
}


#-------------------------------------------
# Seed a CGP and MPMCINPUT xml file
# Create ucf from MIG
# Error if Pin count/placement has changed when compared to original mpmc_mig_launch
# Warning if using more than 1 CE or CS_n pin on DDR1 MIG V4 PHY.
#-------------------------------------------
proc syslevel_drc_mig_flow { param_handle } { 

    set mhsinst [xget_hw_parent_handle $param_handle]

    set mig_flow [xget_hw_value $param_handle]

    if {$mig_flow == 0} {
        return
    }


    # check if basic directory structure exists, if not create
    foreach dir [list "__xps" "__xps/mig" "__xps/mig/platgen"] {
        if {[file exists $dir] == 0} {
            file mkdir   $dir
        }
    }

    run_mig $mhsinst "platgen" "batch"

    set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set lcinstname      [string tolower $instname]
    set mig_gui         "__xps/mig/gui"
    set mig_platgen     "__xps/mig/platgen"
    set mig_tmp         "__xps/mig/tmp"
    set cwd             [pwd]

    set system_handle   [xget_hw_parent_handle $mhsinst]
    set system_name     [xget_hw_name $system_handle]
    set system_mhs      "${cwd}/${system_name}.mhs"
    set mem_type        [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set clk_width       [xget_hw_parameter_value $mhsinst "C_MEM_CLK_WIDTH"]
    set odt_width       [xget_hw_parameter_value $mhsinst "C_MEM_ODT_WIDTH"]
    set cs_n_width      [xget_hw_parameter_value $mhsinst "C_MEM_CS_N_WIDTH"]
    set ce_width        [xget_hw_parameter_value $mhsinst "C_MEM_CE_WIDTH"]
    set family          [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set clk_period      [xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]

    set ucf_filename [get_mig_ucf_filename $mhsinst]

    set ucf_gui         [file join $cwd $mig_gui ${ucf_filename}]
    set ucf_platgen     [file join $cwd $mig_platgen ${ucf_filename}]

    set ucf_gui_out     [file join $cwd $mig_platgen ${lcinstname}_mpmc_gui.ucf]
    set ucf_platgen_out [file join $cwd $mig_platgen ${lcinstname}_mpmc_platgen.ucf]
    set ucf_gui_tmp     [file join $cwd $mig_platgen ${lcinstname}_mpmc_gui.ucf.tmp]
    set ucf_platgen_tmp [file join $cwd $mig_platgen ${lcinstname}_mpmc_platgen.ucf.tmp]
    set xml_base        [file join $mig_tmp ${lcinstname}]

    if {[string match {virtex4} $family] && [string match -nocase {ddr} $mem_type] && $cs_n_width > 1} { 
        puts  "WARNING:  $instname ($ipname) - The MIG flow does not support more than 1 chip \
               select not (CS_N) memory output pin.  MIG will only generate one pinout for this \
               signal.  It is recommend that other pins are hand placed in the system.ucf."
    }
    if {[string match {virtex4} $family] && [string match -nocase {ddr} $mem_type] && $ce_width > 1} { 
        puts  "WARNING:  $instname ($ipname) - The MIG flow does not support more than 1 chip \
               enable (CE) memory output pin.  MIG will only generate one pinout for this \
               signal.  It is recommend that other pins are hand placed in the system.ucf."
    }
    if {[file exists $ucf_gui ] == 0 || [file readable $ucf_gui ] == 0} { 
        error "$ucf_gui does not exist or is not readable.  Please ensure you have properly configured and run MIG from the MPMC IP Configurator" "" "mdt_error"
    }

    if {[file exists $ucf_platgen ] == 0 || [file readable $ucf_platgen ] == 0} { 
        error "$ucf_platgen does not exist or is not readable.  Please ensure you have properly configured and run MIG from the MPMC IP Configurator" "" "mdt_error"
    }

    if {[file exists $system_mhs ] == 0|| [file readable $system_mhs ] == 0} { 
        error "MHS file $system_mhs not found or is not readable. Cannot generate UCF constraints." "" "mdt_error"
    }

    set    convert_ucf [xget_hw_pcore_dir $mhsinst]
    append convert_ucf "convert_ucf.pl"

    if {[file exists $convert_ucf ] == 0 || [file readable $convert_ucf ] == 0} { 
        error "File $convert_ucf is not found or unable to be opened for reading." "" "mdt_error" 
    }

    # Convert MIG ucfs to MPMC UCFs so we can ignore the nets we don't use
    exec xilperl $convert_ucf --batch --mpmc_clk0_period $clk_period --family $family --instance $instname --mem_type $mem_type --clk_width $clk_width --odt_width $odt_width --ce_width $ce_width --cs_n_width $cs_n_width $ucf_platgen $ucf_platgen_out
    exec xilperl $convert_ucf --batch --mpmc_clk0_period $clk_period --family $family --instance $instname --mem_type $mem_type --clk_width $clk_width --odt_width $odt_width --ce_width $ce_width --cs_n_width $cs_n_width $ucf_gui $ucf_gui_out

    array set array_gui_locs "" 
    array set array_platgen_locs "" 

    # Get an array of net/loc pairs
    get_pin_locs $ucf_gui_out array_gui_locs
    get_pin_locs $ucf_platgen_out array_platgen_locs

    # Error if the pin counts are not the same
    if { [array size array_gui_locs] != [array size array_platgen_locs]} { 
        error "There have been changes to this design that have changed the number of external memory pins for MPMC instance ${instname}.  Please re-run the MIG gui from the IP Configurator to generate the correct constraints." "" "mdt_error"
    } else {
        puts "INFO: MPMC instance $instname is using [array size array_gui_locs] pins."
    }

# Skipping this check since if the user has a custom pinout, this will fail.
#    # For each pin loc, check that it exists in the latest mig run, if not error
#    foreach {loc net} [array get array_gui_locs] { 
#        # check that pin exists in platgen and that they match or error out
#        if {![info exists array_platgen_locs($loc)]} {
#            error "Net $net is no longer at LOC $loc. There have been changes to this design that have changed the external memory pin locations for MPMC instance ${instname}.  Please re-run the MIG gui from the IP Configurator to generate the correct constraints." "" "mdt_error"
#        }
#        if {[string equal $net $array_platgen_locs($loc)] == 0} {
#            error "There have been changes to this design that have changed the external memory pin locations for MPMC instance ${instname}.  Please re-run the MIG gui from the IP Configurator to generate the correct constraints." "" "mdt_error"
#        }
#    }
    puts "INFO: syslevel_drc_mig_flow has passed!"

}

# Take a UCF and returns an array of Name/PIN LOC pairs
proc get_pin_locs { ucf arr } { 

    # Open file
    if {[file exists $ucf ] == 0 || [file readable $ucf ] == 0} { 
        error "$ucf does not exist or is not readable." "" "mdt_error"
    }
    if [catch {open $ucf r} ucfID] {
        error "File $ucf: $ucfID" "" "mdt_error" 
    }

    upvar $arr array_loc

    # go through file line by line and parse the 'NET <Net Name> LOC = <Pin Loc> ;' values in to <Net Name>, <Pin Loc> pairs
    while {[gets $ucfID line] >= 0} { 
       if {[regexp {^\s*NET\s+"([^"]+)"\s+LOC\s*=\s*"([^"]+)"} $line match net loc]} {
           set array_loc($loc) $net
       }
   }
}


# Removes the blank and comments from a ucf file
proc remove_blank_and_commented_lines { input output } { 
    if {[file exists $input ] == 0 || [file readable $input ] == 0} { 
        error "$input does not exist or is not readable. Error reading intermediate UCF." "" "mdt_error"
    }

    # Open template to read
    if [catch {open $input r} inputId] {
        error "File $input: $inputId" "" "mdt_error" 
    }

    if [catch {open $output w} outputId] {
        error "File $output: $outputId" "" "mdt_error" 
    }

    while {[gets $inputId line] >= 0} { 
       if {[regexp "^\s*#" $line ]} {
           continue
       } elseif {[regexp "^\s*$" $line]} {
           continue
       }
       puts $outputId $line
   }
   close $inputId
   close $outputId
}


    

# Sets the ucf filename appropriately
proc get_mig_ucf_filename { mhsinst } { 

    set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set ucf_filename    "${instname}.ucf"

    set ucf [file join ${instname} user_design par $ucf_filename]

    return $ucf
}

# Sets the top level filename appropriately
proc get_mig_top_filename { mhsinst } { 

    set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set top_filename    "${instname}.v"

    set top [file join ${instname} user_design rtl ip_top $top_filename]

    return $top
}

#***--------------------------------***-----------------------------------***
#
#                          SYSLEVEL_DRC_PROC (IP)
#
#***--------------------------------***-----------------------------------***

proc check_syslevel_drcs { mhsinst } {

    syslevel_drc_mpmc_clk_200mhz    $mhsinst
    syslevel_drc_splb_overlap       $mhsinst
    syslevel_drc_mig_freq           $mhsinst
    syslevel_drc_micontrol          $mhsinst
    syslevel_drc_conflictmask       $mhsinst
#    set    mig_flow   [xget_hw_parameter_value $mhsinst "C_USE_MIG_FLOW"]
#    if {$mig_flow == 1} { 
#        syslevel_drc_mig_flow
#    }

}

#------------------------------------------
# Check frequency of MPMC_Clk_200MHz is 200 MHz + or - 10MHz
#------------------------------------------
proc syslevel_drc_mpmc_clk_200mhz { mhsinst } {

    set family          [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set static_phy      [xget_hw_parameter_value $mhsinst C_USE_STATIC_PHY]
    set num_idelayctrl  [xget_hw_parameter_value $mhsinst C_NUM_IDELAYCTRL]
    set is_mig_v6_phy   [xget_hw_parameter_value $mhsinst "C_USE_MIG_V6_PHY"]
    set is_mig_v5_phy   [xget_hw_parameter_value $mhsinst "C_USE_MIG_V5_PHY"]
    set is_mig_v4_phy   [xget_hw_parameter_value $mhsinst "C_USE_MIG_V4_PHY"]

    if { ($is_mig_v4_phy ||$is_mig_v5_phy ||$is_mig_v6_phy) && $num_idelayctrl > 0} { 

        set clock_port [xget_hw_port_handle $mhsinst "MPMC_Clk_200MHz"]
        set clock_frequency [xget_hw_subproperty_value $clock_port "CLK_FREQ_HZ"]
          
        if {$clock_frequency == ""} {
            set    instname   [xget_hw_parameter_value $mhsinst "INSTANCE"]
            set    ipname     [xget_hw_option_value    $mhsinst "IPNAME"]
            puts  "WARNING:  $instname ($ipname) - Could not determine clock frequency on input clock port\
                   MPMC_Clk_200Mhz, not performing clock DRCs. \n"
        } else { 
           
            set clk_freq_max [expr {pow(10,6) * 210}]
            set clk_freq_min [expr {pow(10,6) * 190}]

            if { $clock_frequency > $clk_freq_max || $clock_frequency < $clk_freq_min } {
                error "MPMC_Clk_200Mhz -- The clock frequency is $clock_frequency Hz on this port. The clock frequency\
                       should be set to 200 MHz.  Please check your clock frequency settings in your system." "" \
                       "mdt_error" 
            }
        }
    } 
}

#------------------------------------------
# if C_ALL_PIM_SHARE_ADDRESSES
# for all valid ports
# if C_PIMx_BASETYPE == 2 (PLB) AND
#    C_PIMy_BASETYPE == 2, where x != y
# then error out
#------------------------------------------
proc syslevel_drc_splb_overlap { mhsinst } {

    set portno [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]
    set shared [xget_hw_parameter_value $mhsinst "C_ALL_PIMS_SHARE_ADDRESSES"]

    if {$shared == 0} {
        return
    }

    set x_max [expr {$portno - 1}]

    for {set x 0} {$x < $x_max} {incr x 1} {

        set y_start [expr {$x + 1}]

        for {set y $y_start} {$y < $portno} {incr y 1} {

            set pimx_basetype [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]
            set pimy_basetype [xget_hw_parameter_value $mhsinst "C_PIM${y}_BASETYPE"]

            if { $pimx_basetype == 2 && $pimy_basetype == 2 && (${x} != ${y}) } { 

                set splbx_connector [xget_hw_busif_value $mhsinst "SPLB${x}"]
                set splby_connector [xget_hw_busif_value $mhsinst "SPLB${y}"]

                if {[string compare -nocase $splbx_connector $splby_connector] == 0} {

                    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]

                    error "$instname\:\:SPLB${x} and $instname\:\:SPLB${y} are connected to the same PLB bus and have\
                           overlapping addresses." "" "mdt_error" 

                }
            }
        }
    }

}


#------------------------------------------
# Check frequency of MPMC_Clk_Mem_2x is between tmin and tmax for Spartan6.
#------------------------------------------
proc syslevel_drc_mig_freq { mhsinst } {

    global array_partno_param
    
    set family          [xget_hw_parameter_value $mhsinst C_BASEFAMILY]

    # Get partnumber.
    set partno          [string toupper [xget_hw_parameter_value  $mhsinst "C_MEM_PARTNO"]]
        
    # Check architecture and get period.
    set clk_period      0
    if { [string match -nocase {spartan6} $family] } { 
        set clk_period      [expr {[xget_hw_parameter_value $mhsinst "C_MPMC_CLK_MEM_2X_PERIOD_PS"]*2}]

    } elseif { [string match -nocase {virtex6} $family] } { 
        set clk_period      [expr {[xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"] / 2}]

    } 

    # We can only do the check for non-Custom parts.
    if { [string match -nocase {custom} $partno] == 0 && $clk_period != 0 && [string match -nocase {mpmc-*} $partno] == 0} { 
            
        set tmin            $array_partno_param($partno,C_PARTNO_TMIN)
        set tmax            $array_partno_param($partno,C_PARTNO_TMAX)
            
        # Check if frequency is inside the range.
        if { $tmin > $clk_period || $clk_period > $tmax } {
            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            puts "WARNING: ${instname}\:\:MPMC period of ${clk_period} ps is not inside range ${tmin}-${tmax} ps for memory \"${partno}\"."
        }
    }
}

#***--------------------------------***-----------------------------------***
#
#                            MI_CONTROL DRC Check
#
#***--------------------------------***-----------------------------------***
proc syslevel_drc_micontrol {mhsinst} {
        
        # print_suggestion is an internal flag
        set print_suggestion 0
        
   set mpmcname [xget_hw_name $mhsinst]
   
   # do I need to check the MPMC pim?
   
        set merged_mhs_handle [xget_hw_parent_handle    $mhsinst]

   # loop check every PPC440MC buses
   set x 0
   foreach x {0 1 2 3 4 5 6 7} { 
      set connector [xget_hw_busif_value $mhsinst "PPC440MC$x"]
      
      if {[llength $connector] == 0} {
            continue
      } else {
         set busifs [xget_hw_connected_busifs_handle $merged_mhs_handle $connector "initiator"]

         # if PPC440MC bus is connected
         if {[string length $busifs] != 0} {
             set busif_parent [xget_hw_parent_handle $busifs]
             set iptype       [xget_hw_option_value  $busif_parent "IPTYPE"]
             # $busif_parent will be used as processor handler for PPC440
             
             
             # if iptype = PROCESSOR
             if { [string match -nocase {PROCESSOR} $iptype] == 1 } {
               set bus_if_name [xget_hw_name $busifs]
               set processor_type [xget_hw_option_value $busif_parent SPECIAL]
               set processor_name [xget_hw_name $busif_parent]
                  
               # check processor is PPC440
               if {[string equal -nocase $processor_type "PPC440"] == 1 } {
               # get parameter C_PPC440MC_CONTROL of PPC440
               set param_ppc440mc_control [xget_hw_parameter_value $busif_parent C_PPC440MC_CONTROL]
               # convert HEX to Binary
               binary scan [binary format "H8" [string range $param_ppc440mc_control end-7 end]] "B32" param_ppc440mc_control_bin
               # the method to get one bit of $param_ppc440mc_control
               # puts [string index $param_ppc440mc_control_bin 1]
                

                
               } else {
                  puts "Warning: $mpmcname\(MPMC\) is not connected to a PPC440 while MPMC PIM is configured as PPC440MC. No PPC440MC parameter checks will be performed." 
                  return 0
               }


               ## Calculate Bit6
               # check Frequency of CPMMCCLK
               set cpmmcclk_handle [xget_hw_port_handle $busif_parent "CPMMCCLK"]
               set cpmmcclk_freq_hz [xget_hw_subproperty_value $cpmmcclk_handle "CLK_FREQ_HZ"]
               # check Frequency of CPMMCCLK
               set cpminterclk_handle [xget_hw_port_handle $busif_parent "CPMINTERCONNECTCLK"]
               set cpminterclk_freq_hz [xget_hw_subproperty_value $cpminterclk_handle "CLK_FREQ_HZ"]
        
               if { [llength $cpminterclk_freq_hz] > 0 && [llength $cpmmcclk_freq_hz] > 0} {
                  # integer divide then multiply to check whether the ratio is integer
                  # If not integer ratio, the divide reminder will be cut 
                  #   and the $recover won't be equal to $cpminterclk_freq_hz
                  set recover [expr {$cpminterclk_freq_hz / $cpmmcclk_freq_hz * $cpmmcclk_freq_hz}]
                  if {[string compare $cpminterclk_freq_hz $recover] == 0} {
                     set bit6_calc 0
                     # inteter ratio
                  } else {
                     error "The frequency ratio of CPMMCCLK and CPMINTERCONNECTLCK should be integer. Currently CPMMCCLK is set to $cpmmcclk_freq_hz while CPMINTERCONNECTLCK is set to $cpminterclk_freq_hz" "" "mdt_error"
                     
                  }
      
                  # compare current value against the calculated value
                  set bit6 [string index $param_ppc440mc_control_bin 6]
                  if { [string equal $bit6_calc $bit6]} {
                  } else {
                     puts "Warning: $processor_name\($processor_type\) Bit 6 of C_PPC440MC_CONTROL is set to $bit6 but only 0 is allowed according to MPMC requirements"
                     set print_suggestion 1
                  }
               } else {
                  puts "Warning: $processor_name\($processor_type\) Cannot get the frequency of CPMINTERCONNECTCLK and CLK_FREQ_HZ. The clock frequency check will be skipped."
               }
        
        

        
        
               ## Calculate Bit 8_9 Bit 10_11
               # get data from MPMC instance
               #
               #                *       C_MEM_TYPE
               #                *       C_MEM_DATA_WIDTH
               set param_mem_type [xget_hw_parameter_value $mhsinst C_MEM_TYPE]
               set param_mem_data_width [xget_hw_parameter_value $mhsinst C_MEM_DATA_WIDTH]
               set mem_type_check "$param_mem_type $param_mem_data_width"
               set bit8_9 [string range $param_ppc440mc_control_bin 8 9]
               set bit10_11 [string range $param_ppc440mc_control_bin 10 11]
        
               # define bur   st tables according to the datasheet
               
               # Bit 8:9 Burstwidth 00=128bit 01=64bit 11=32bit
               set mem_table {{SDRAM 8} {SDRAM 16} {SDRAM 32} {SDRAM 64} 
                             {DDR 8} {DDR 16} {DDR 32} {DDR 64}
                             {DDR2 8} {DDR2 16} {DDR2 32} {DDR2 64}}
               set burstwidth_table {11 11 11 01 11 11 01 01 11 11 01 01}
               # Bit 10:11 Burstlength  00: Burst length = 1 01: Burst length = 2 10: Burst length = 4 11: Burst length = 8                               
               set burstlength_table {{10 11} {10 11} {10 11} {01 10 11} {10 11} {10 11} {01 10 11} {10 11} {10 11} {10 11} {01 10 11} {10 11}}
               
               # Search $mem_type_check in $mem_table to get the index value
               set burst_index [lsearch $mem_table $mem_type_check]
        
               # If $burst_index > 0, there is a match. 
               # Then use the index to check the allowed burst width and burst length values
               if {$burst_index < 0} {
                  puts "Warning: $mpmcname(MPMC) C_MEM_TYPE and C_MEM_DATA_WIDTH of MPMC are currently set to $param_mem_type and $param_mem_data_width. Please refer to MPMC datasheet for the expected value."
               } else {
                  set bit8_9_calc [lindex $burstwidth_table $burst_index]
                  if {[string equal $bit8_9_calc $bit8_9] != 1} {
                     puts "Warning: $processor_name\($processor_type\) C_PPC440MC_CONTROL\[8:9\] Burstlength is set to $bit8_9, an incorrect setting according to the C_MEM_TYPE\($param_mem_type\) and C_MEM_DATA_WIDTH\($param_mem_data_width\) settings. The correct value should be $bit8_9_calc. Please refer to the MPMC datasheet for more details."
                     set print_suggestions 1
                  }
                  set bit10_11_group [lindex $burstlength_table $burst_index]
                  # $bit10_11_calc is not used here but for final suggestion printing.
                  set bit10_11_calc [lindex $bit10_11_group 0]
                  # If the current value is in the set of $bit10_11_group, pass. If not, warning.
                  if {[lsearch $bit10_11_group $bit10_11] < 0 } {
                     puts "Warning: $processor_name\($processor_type\) C_PPC440MC_CONTROL\[10:11\] Burstlength is set to $bit10_11, an incorrect setting according to the C_MEM_TYPE\($param_mem_type\) and C_MEM_DATA_WIDTH\($param_mem_data_width\) settings. $bit10_11_group are allowed for this parameter. Please refer to the MPMC datasheet for more details."
                     set print_suggestions 1
                  }
               }
                
               # Check all other bit values and assert warnings 
               # $i is the bit number, $j is the expected value 
               foreach {i j} {0 1 1 0 2 0 3 0 4 0 5 0 7 0 12 0 13 0 14 0 15 0 16 0 25 0 26 0 27 0 30 1 31 1} {
               if {[string equal [string index $param_ppc440mc_control_bin $i] $j] != 1} {
                  puts "Warning: $processor_name\($processor_type\) Bit $i of C_PPC440MC_CONTROL is set to [string index $param_ppc440mc_control_bin $i], but should be set to $j according to the MPMC core requirements. Please refer to the MPMC datasheet for more details."
                  set print_suggestion 1
                  }
               }
        

               if {$print_suggestion == 1} {
                  ## Combine all the calc bits
                  set bit0_5_sug 100000
                  set bit7_sug 0
                  set bit12_15_sug 0000
                  set bit16_sug 0
                  set bit17_31_sug 000000010001111
                  append mi_control_bin_calc $bit0_5_sug $bit6_calc $bit7_sug $bit8_9_calc $bit10_11_calc $bit12_15_sug $bit16_sug $bit17_31_sug
                  set mi_control_calc_hex [string map {0000 0 0001 1 0010 2 0011 3 0100 4 0101 5 0110 6 0111 7
                                    1000 8 1001 9 1010 A 1011 B 1100 C 1101 D 1110 E 1111 F} $mi_control_bin_calc]
                  append mi_control_calc "0x" $mi_control_calc_hex
                  error "The suggested value for $processor_name\($processor_type\) C_PPC440MC_CONTROL is $mi_control_calc." "" "mdt_error"
                  return 1
               }
            }
         }
      }
   }
   
   
}
#***--------------------------------***-----------------------------------***
#
#                            CONFLICT_MASK DRC Check
#
#***--------------------------------***-----------------------------------***

# MPMC PPC440MC PIM doesn't support bank/row conflict mask.
# So this function just make sure the C_PPC440MC_ROW_CONFLICT_MASK and 
# C_PPC440MC_BANK_CONFLICT_MASK in ppc440_virtex5 core are all zero.

proc syslevel_drc_conflictmask {mhsinst} {
        
   set instname [xget_hw_name $mhsinst]
   
        # conflict_mask_error is an internal flag
        set conflict_mask_error 0
        
        set merged_mhs_handle [xget_hw_parent_handle $mhsinst]

   # loop check every PPC440MC buses
   set x 0
   foreach x {0 1 2 3 4 5 6 7} { 
      set connector [xget_hw_busif_value $mhsinst "PPC440MC$x"]
      
      if {[llength $connector] == 0} {
            continue
      } else {
         set busifs [xget_hw_connected_busifs_handle $merged_mhs_handle $connector "initiator"]

         # if PPC440MC bus is connected
         if {[string length $busifs] != 0} {
            set busif_parent [xget_hw_parent_handle $busifs]
            set iptype       [xget_hw_option_value  $busif_parent "IPTYPE"]
            # $busif_parent will be used as processor handler for PPC440
            set processor_handle $busif_parent
             
             
            # if iptype = PROCESSOR
            if { [string match -nocase {PROCESSOR} $iptype] == 1 } {
               set bus_if_name [xget_hw_name $busifs]
               set processor_type [xget_hw_option_value $busif_parent SPECIAL]
               set processor_name [xget_hw_name $busif_parent]
               
              
               # check processor is PPC440
               if {[string equal -nocase $processor_type "PPC440"] == 1 } {
               # get parameter C_PPC440MC_ROW_CONFLICT_MASK of PPC440
                  set param_ppc440_row_cm [xget_hw_parameter_value $processor_handle C_PPC440MC_ROW_CONFLICT_MASK]
                  # get parameter C_PPC440MC_BANK_CONFLICT_MASK of PPC440
                  set param_ppc440_bank_cm [xget_hw_parameter_value $processor_handle C_PPC440MC_BANK_CONFLICT_MASK]
                                      
                  # Compare with zero
                  if { [string equal -nocase $param_ppc440_row_cm "0x00000000"] != 1} {
                     puts "Warning: $processor_name\($processor_type\) C_PPC440MC_ROW_CONFLICT_MASK is $param_ppc440_row_cm but it should be set to 0x00000000 as MPMC PPC440MC PIM doesn't support row/bank management."
                     set conflict_mask_error 1
                  }
                  
                  if { [string equal -nocase $param_ppc440_bank_cm "0x00000000"] != 1} {
                     puts "Warning: $processor_name\($processor_type\) C_PPC440MC_BANK_CONFLICT_MASK is $param_ppc440_bank_cm but it should be set to 0x00000000 as MPMC PPC440MC PIM doesn't support row/bank management."
                     set conflict_mask_error 1
                  }
                  
                  if {$conflict_mask_error == 1} {
                     error "$processor_name\($processor_type\) parameter C_PPC440MC_BANK_CONFLICT_MASK or C_PPC440MC_ROW_CONFLICT_MASK setting error. Please refer to the above warning for the correct values." "" "mdt_error"
                     return 1
                  }
               }   
            }
         }  
      } 
   }    
}       
        
#***--------------------------------***-----------------------------------***
#
#                          PLATGEN_SYSLEVEL_UPDATE_PROC (IP) 
#
#***--------------------------------***-----------------------------------***

proc platgen_syslevel_update { mhsinst } {
    generate_corelevel_ucf $mhsinst

}

proc generate_corelevel_ucf { mhsinst } {

    set  filePath [xget_ncf_dir $mhsinst]

    file mkdir    $filePath

    # specify file name
    set    family     [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set    instname   [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set    ipname     [xget_hw_option_value    $mhsinst "IPNAME"]
    set    name_lower [string   tolower   $instname]
    set    fileName   $name_lower
    set    mem_type   [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    append fileName   "_wrapper.ucf"
    append filePath   $fileName

    # Open a file for writing
    set    outputFile [open $filePath "w"]

    set    mig_flow   [xget_hw_parameter_value $mhsinst "C_USE_MIG_FLOW"]
    if { [string match -nocase {spartan6} $family] } {
        # Generate TIG on self refresh signal if soft calibration is enabled.
        set soft_cal [xget_hw_parameter_value $mhsinst "C_MEM_CALIBRATION_SOFT_IP"]
        if {[string match -nocase {true} $soft_cal]} {
            puts $outputFile  "NET \"${instname}/mpmc_core_0/gen_spartan6_mcb.s6_phy_top_if/mpmc_mcb_raw_wrapper_0/selfrefresh_mcb_mode\" TIG;"
        }
        if {[string match -nocase {true} $soft_cal] && [string match -nocase {ddr2} $mem_type]} {
            # Generate TIG on CKE_Train if soft calibration is enabled on ddr2
             puts $outputFile  "NET \"${instname}/mpmc_core_0/gen_spartan6_mcb.s6_phy_top_if/mpmc_mcb_raw_wrapper_0/gen_term_calib.mcb_soft_calibration_top_inst/mcb_soft_calibration_inst/CKE_Train\" TIG;"
        } elseif { [string match -nocase {ddr2} $mem_type]} { 

            # Generate TIG on cke_train_reg if soft calibration false on ddr2
             puts $outputFile  "NET \"${instname}/mpmc_core_0/gen_spartan6_mcb.s6_phy_top_if/mpmc_mcb_raw_wrapper_0/cke_train_reg\" TIG;"
        }
       
        # generate synchronizer constraints  
        generate_s6_synch_constraints $mhsinst $outputFile
        # Generate the LOC constraints.
        generate_spartan6_mcb_constraints $mhsinst $outputFile
    } elseif {$mig_flow == 1} { 
        generate_mig_phy_constraints $mhsinst $outputFile
    } else { 
        # No Longer need these constraints
        # generate_v5_ddr2_mig_phy_constraints $mhsinst $outputFile
    }

    # generate_mmcm_loc_constraints $mhsinst $outputFile
    generate_idelayctrl_loc_constraints $mhsinst $outputFile


    # Close the file
    close $outputFile
    puts  [xget_ncf_loc_info $mhsinst]

}

###############################################################################
## Generates constraints for clock cross domain crossing between mcb ui_clk and mpmc
###############################################################################
proc generate_s6_synch_constraints { mhsinst outputFile } {

    set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set num_ports       [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]
    set mcb_drp_clk     [xget_hw_parameter_value $mhsinst "C_MCB_DRP_CLK_PRESENT"]

    # If we are using clk0 for soft cal, then no tig is required.
    if {$mcb_drp_clk == 0} { 
        return
    }

    # Only generate tig on uo_done_cal_d1 if using a non mcb port used.
    for {set x ${num_ports}} {$x >= 0} {incr x -1} {
        set basetype [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]
        if {$basetype > 0 || $basetype < 7 } {

            set INST            "${instname}/mpmc_core_0/gen_spartan6_mcb.s6_phy_top_if/uo_done_cal_d1*";
            set TNM             "TNM_TIG_${instname}_S6_DONE_CAL_SYNCH";
            set TS              "TS_TIG_${instname}_S6_DONE_CAL_SYNCH";
            puts $outputFile "";
            puts $outputFile "#########################################################################";
            puts $outputFile "# TIG synchronizer signals                                              #";
            puts $outputFile "#########################################################################";
            puts $outputFile "INST \"${INST}\" TNM=\"${TNM}\";";
            puts $outputFile "TIMESPEC \"${TS}\" = FROM FFS TO \"${TNM}\" TIG;";
            set INST            "${instname}/mpmc_core_0/gen_spartan6_mcb.s6_phy_top_if/rst_d1*";
            set TNM             "TNM_TIG_${instname}_S6_SYS_RST_SYNCH";
            set TS              "TS_TIG_${instname}_S6_SYS_RST_SYNCH";
            puts $outputFile "";
            puts $outputFile "INST \"${INST}\" TNM=\"${TNM}\";";
            puts $outputFile "TIMESPEC \"${TS}\" = FROM FFS TO \"${TNM}\" TIG;";
            
            return

        }
    }
}


###############################################################################
## Opens up the Spartan-6 MIG database files for pin/bank locations on a device
## The array passed to this procedure is populate with Pad/IoType/
## ControllerNumber/SignalName in the data structure:
## array_pads(PadName,SignalName) = [list PadName IoType ControllerNumber SignalName]
## For each element in the array there is a list, index 0 ins the PadName
## ... index 3 is the SignalName.  If a pad does not have an associated
## ControllerNumber or SignalName it is filled in with {}.
###############################################################################
proc util_parse_spartan6_pkg_file { mhsinst array_pads_name } {
    # Get LOC information.
    set target_mcb       [xget_hw_parameter_value $mhsinst "C_MCB_LOC"]
   
    # Get FPGA information. 
    set family           [xget_hw_parameter_value $mhsinst "C_FAMILY"]
    set c_package        [xget_hw_parameter_value $mhsinst "C_PACKAGE"]
    set c_speedgrade     [xget_hw_parameter_value $mhsinst "C_SPEEDGRADE"]
    set c_device         [xget_hw_proj_setting "fpga_xdevice"]
    set basefamily       [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set subfamily        "6s"

    if {[string equal {} c_device]} { 
        set c_device         [xget_hw_proj_setting "fpga_partname"]
        regsub -- $c_package$c_speedgrade $c_device {} c_device
    }

    # Fix family and device to match mig
    switch -exact -- $family { 
        qspartan6       { set mig_basefamily $family }
        qspartan6l      { set mig_basefamily $family }
        spartan6        -
        aspartan6       -
        spartan6l       { set mig_basefamily "spartan6"
                          set c_device    [string trimright $c_device {l}] }
        default         { set mig_basefamily $family }
    }

    if { [string match {spartan6} $basefamily] } {
        if { $target_mcb != "NOT_SET" } {
            set db_tlib_name    [get_mig_fpga_database "${mig_basefamily}/${subfamily}/${c_device}${c_package}_tlib.xml"]
            set db_pkg_name     [get_mig_fpga_database "${mig_basefamily}/${subfamily}/${c_device}${c_package}_pkg.xml"]
            
            # Open TLIB database.
            set xmlRoot [xxml_read_file $db_tlib_name]
            if {$xmlRoot == 0} {
                error "File $db_tlib_name could not be opened or parsed." "" "mdt_error"
            } else {
                # Find data structure with the available MCBs for this FPGA.
                set xmlData [xxml_get_sub_elements $xmlRoot "MemoryControllerDetails"]
                
                if {[llength $xmlData] < 1} {
                    error "Could not find XML element <MemoryControllerDetails> in the file \"$db_tlib_name\"." "" "mdt_error" 
                } 
                set xmlData [xxml_get_sub_elements $xmlData "MEMC"]
                if {[llength $xmlData] < 1} {
                    error "Could not find XML element <MEMC> in the file \"$db_tlib_name\"." "" "mdt_error" 
                } 
                
                # Get the available MCBs for this FPGA.
                set available_mcb   [xxml_get_text $xmlData]
                set available_mcb   [split $available_mcb ","]
        
                # Cleanup xxml
                xxml_cleanup $xmlRoot
            }
        
            # Check that the requested memory is available.
            set valid_mcb   0
            set mcb_count [llength $available_mcb]
            foreach {mcb} $available_mcb {
                if { $mcb == $target_mcb  } {
                    set valid_mcb   1
                }
            }
            if { $valid_mcb == 0  } {
                error "Current architecture doesn't support the MCB instance \"$target_mcb\" (only \"[join $available_mcb "\", \""]\" are possible)." "" "mdt_error" 
            }
           
            # Parse the controller number 
            regsub {MEMC} $target_mcb {} target_mcb

            # If quad device, remap MEMC1 to Bank 5 (M5) and MEMC2 to Bank 1 (M1)
            if {$mcb_count == 4} { 
                if {[string match {1} $target_mcb]} { 
                    set target_mcb "5"
                } elseif {[string match {2} $target_mcb]} { 
                    set target_mcb "1"
                }
            }

            # Prepare the signal data base.
            upvar 1 $array_pads_name array_pads
            
            # Open PKG database.
            set xmlRoot [xxml_read_file $db_pkg_name]
            if {$xmlRoot == 0} {
                error "File $db_pkg_name could not be opened or parsed." "" "mdt_error"
            } else {
                # Find bank for our target MCB
                set xmlData [xxml_get_sub_elements $xmlRoot "BankInfo\[@Bank=$target_mcb\]"]
                if {[llength $xmlData] < 1} {
                    error "Could not find any XML element <BankInfo> in the file \"$db_pkg_name\"." "" "mdt_error" 
                } 
                
                # Scan through all banks.
                foreach {xmlBank} $xmlData {
                    # Find signal information that belongs to the MCB.
                    set xmlValue [xxml_get_sub_elements $xmlBank "PadInfo"]
                    
                    if {[llength $xmlValue] > 0} {
                        # Add all relevant signal->LOC information.
                        foreach {xmlPad} $xmlValue {
                            set pad_name [xxml_find_property $xmlPad "PADName"]
                            set io_type  [xxml_find_property $xmlPad "IOType"]
                            set controller_number  [xxml_find_property $xmlPad "ControllerNumber"]
                            set signal_name [xxml_find_property $xmlPad "SignalName"]
                            regsub {\[} $signal_name {} signal_name
                            regsub {\]} $signal_name {} signal_name
                            set array_pads($pad_name,$signal_name) [list "$pad_name" "$io_type" "$controller_number" "$signal_name"]
                            
                        }
                    } 
                    
                }
                
                # Check that some pin mapping has been found.
                if { [array size array_pads] == 0 } {
                    error "Could not find any signals of LOCs in the file \"$db_pkg_name\"." "" "mdt_error" 
                }
                
                # Cleanup xxml
                xxml_cleanup $xmlRoot
            }
        }
    }
}

###############################################################################
## Opens up the Spartan-6 MIG database files for pin/bank locations on a device
## The array passed to this procedure is populate with Pad/IoType/
## ControllerNumber/SignalName in the data structure:
## array_pads(PadName,SignalName) = [list PadName IoType ControllerNumber SignalName]
## For each element in the array there is a list, index 0 ins the PadName
## ... index 3 is the SignalName.  If a pad does not have an associated
## ControllerNumber or SignalName it is filled in with {} static for mig v3.4
###############################################################################
proc util_parse_spartan6_pkg_file_v3_4 { mhsinst array_pads_name } {
    # Get LOC information.
    set target_mcb       [xget_hw_parameter_value $mhsinst "C_MCB_LOC"]
   
    # Get FPGA information. 
    set family           [xget_hw_parameter_value $mhsinst "C_FAMILY"]
    set c_package        [xget_hw_parameter_value $mhsinst "C_PACKAGE"]
    set c_speedgrade     [xget_hw_parameter_value $mhsinst "C_SPEEDGRADE"]
    set c_device         [xget_hw_proj_setting "fpga_xdevice"]
    set basefamily       [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set subfamily        "6s"

    if {[string equal {} c_device]} { 
        set c_device         [xget_hw_proj_setting "fpga_partname"]
        regsub -- $c_package$c_speedgrade $c_device {} c_device
    }

    # Fix family and device to match mig
    switch -exact -- $family { 
        qspartan6       { set mig_basefamily $family }
        qspartan6l      { set mig_basefamily $family }
        spartan6        -
        aspartan6       -
        spartan6l       { set mig_basefamily "spartan6"
                          set c_device    [string trimright $c_device {l}] }
        default         { set mig_basefamily $family }
    }

    if { [string match {spartan6} $basefamily] } {
        if { $target_mcb != "NOT_SET" } {
            set db_tlib_name    [get_mig_fpga_database_v3_4 "${mig_basefamily}/${subfamily}/${c_device}${c_package}_tlib.xml"]
            set db_pkg_name     [get_mig_fpga_database_v3_4 "${mig_basefamily}/${subfamily}/${c_device}${c_package}_pkg.xml"]
            
            if {[string match {} $db_tlib_name] || [string match {} $db_pkg_name]} { 
                return
            }
            # Open TLIB database.
            set xmlRoot [xxml_read_file $db_tlib_name]
            if {$xmlRoot == 0} {
                error "File $db_tlib_name could not be opened or parsed." "" "mdt_error"
            } else {
                # Find data structure with the available MCBs for this FPGA.
                set xmlData [xxml_get_sub_elements $xmlRoot "MemoryControllerDetails"]
                
                if {[llength $xmlData] < 1} {
                    error "Could not find XML element <MemoryControllerDetails> in the file \"$db_tlib_name\"." "" "mdt_error" 
                } 
                set xmlData [xxml_get_sub_elements $xmlData "MEMC"]
                if {[llength $xmlData] < 1} {
                    error "Could not find XML element <MEMC> in the file \"$db_tlib_name\"." "" "mdt_error" 
                } 
                
                # Get the available MCBs for this FPGA.
                set available_mcb   [xxml_get_text $xmlData]
                set available_mcb   [split $available_mcb ","]
        
                # Cleanup xxml
                xxml_cleanup $xmlRoot
            }
        
            # Check that the requested memory is available.
            set valid_mcb   0
            set mcb_count [llength $available_mcb]
            foreach {mcb} $available_mcb {
                if { $mcb == $target_mcb  } {
                    set valid_mcb   1
                }
            }
            if { $valid_mcb == 0  } {
                error "Current architecture doesn't support the MCB instance \"$target_mcb\" (only \"[join $available_mcb "\", \""]\" are possible)." "" "mdt_error" 
            }
           
            # Parse the controller number 
            regsub {MEMC} $target_mcb {} target_mcb

            # If quad device, remap MEMC1 to Bank 5 (M5) and MEMC2 to Bank 1 (M1)
            if {$mcb_count == 4} { 
                if {[string match {1} $target_mcb]} { 
                    set target_mcb "5"
                } elseif {[string match {2} $target_mcb]} { 
                    set target_mcb "1"
                }
            }

            # Prepare the signal data base.
            upvar 1 $array_pads_name array_pads
            
            # Open PKG database.
            set xmlRoot [xxml_read_file $db_pkg_name]
            if {$xmlRoot == 0} {
                error "File $db_pkg_name could not be opened or parsed." "" "mdt_error"
            } else {
                # Find bank for our target MCB
                set xmlData [xxml_get_sub_elements $xmlRoot "BankInfo\[@Bank=$target_mcb\]"]
                if {[llength $xmlData] < 1} {
                    error "Could not find any XML element <BankInfo> in the file \"$db_pkg_name\"." "" "mdt_error" 
                } 
                
                # Scan through all banks.
                foreach {xmlBank} $xmlData {
                    # Find signal information that belongs to the MCB.
                    set xmlValue [xxml_get_sub_elements $xmlBank "PadInfo"]
                    
                    if {[llength $xmlValue] > 0} {
                        # Add all relevant signal->LOC information.
                        foreach {xmlPad} $xmlValue {
                            set pad_name [xxml_find_property $xmlPad "PADName"]
                            set io_type  [xxml_find_property $xmlPad "IOType"]
                            set controller_number  [xxml_find_property $xmlPad "ControllerNumber"]
                            set signal_name [xxml_find_property $xmlPad "SignalName"]
                            regsub {\[} $signal_name {} signal_name
                            regsub {\]} $signal_name {} signal_name
                            set array_pads($pad_name,$signal_name) [list "$pad_name" "$io_type" "$controller_number" "$signal_name"]
                            
                        }
                    } 
                    
                }
                
                # Check that some pin mapping has been found.
                if { [array size array_pads] == 0 } {
                    error "Could not find any signals of LOCs in the file \"$db_pkg_name\"." "" "mdt_error" 
                }
                
                # Cleanup xxml
                xxml_cleanup $xmlRoot
            }
        }
    }
}

# Returns back the pin location of a signal 
proc util_lookup_pin_location { array_pads_name pin_name } { 
    upvar $array_pads_name array_pads

    set list_pads [array get array_pads *,$pin_name]
    if {[llength $list_pads] == 0} { 
        puts "ERROR: Lookup for pin $pin_name failed."
    }

    return [lindex [lindex $list_pads 1] 0]
}

###############################################################################
## GUI function to return the pin location of a certain pin e.g. rzq or zio
## Returns back a string of the pin location
###############################################################################
proc util_lookup_pin_location_v3_4 { mhsinst pin_name } { 
    array set array_pads {}
    # Get array of all pads/names
    util_parse_spartan6_pkg_file_v3_4 $mhsinst array_pads
    set list_pads [array get array_pads *,$pin_name]
    return [lindex [lindex $list_pads 1] 0]
}

###############################################################################
## GUI function to return the pin location of a certain pin e.g. rzq or zio
## Returns back a string of the pin location
###############################################################################
proc gui_lookup_pin_location { mhsinst pin_name } { 
    array set array_pads {}
    # Get array of all pads/names
    util_parse_spartan6_pkg_file $mhsinst array_pads
    return [util_lookup_pin_location array_pads $pin_name]
}

###############################################################################
## GUI function to return back all the pins that can be used for RZQ or ZIO
## Returns back a tcl list of strings pin locations
###############################################################################
proc gui_get_list_of_rzq_zio_possible_pins { mhsinst } { 
    array set array_pads {}
    # Get array of all pads/names
    util_parse_spartan6_pkg_file $mhsinst array_pads
    set list_possible_pads {}
    set list_all_pads [array names array_pads {*,}]
    foreach {key} $list_all_pads {
        set io_type [lindex $array_pads($key) 1]
        if {[string match -nocase {*VCCO*} $io_type] || [string match -nocase {*VREF*} $io_type]} {
            continue
        }
        if {[string match -nocase {*AWAKE*} $io_type] || [string match -nocase {*DOUT_BUSY*} $io_type]} {
            continue
        }

        lappend list_possible_pads [lindex $array_pads($key) 0]
    }

    # Append rzq/zio to the list
    lappend list_possible_pads [util_lookup_pin_location array_pads rzq]
    lappend list_possible_pads [util_lookup_pin_location array_pads zio]

    return $list_possible_pads
}

proc generate_spartan6_mcb_constraints { mhsinst outputFile } {

    # Get handle to MHS level.
    set mhs_handle  [xget_hw_parent_handle $mhsinst]

    # List of signals that we want to find for MPMC UCF constraints.
    set list_mcb_signals    {"mcbx_dram_addr" "mcbx_dram_ba" "mcbx_dram_ras_n" "mcbx_dram_cas_n" 
                             "mcbx_dram_we_n" "mcbx_dram_cke" "mcbx_dram_clk" "mcbx_dram_clk_n" 
                             "mcbx_dram_dq" "mcbx_dram_dqs" "mcbx_dram_ldm" "mcbx_dram_dqs_n" 
                             "mcbx_dram_udqs" "mcbx_dram_udqs_n" "mcbx_dram_udm" "mcbx_dram_odt" 
                             "mcbx_dram_ddr3_rst" "rzq" "zio"}
    
    set list_fpga_signals   {"a" "ba" "ras_n" "cas_n" 
                             "we_n" "cke" "ck" "ck_n" 
                             "dq" "dqs" "dm" "dqs_n" 
                             "udqs" "udqs_n" "udm" "odt" 
                             "reset_n" "rzq" "zio"}

    set list_mcb_width      {"C_MEM_ADDR_WIDTH" "C_MEM_BANKADDR_WIDTH" "" "" 
                             "" "" "" "" 
                             "C_MEM_DATA_WIDTH" "" "" "" 
                             "" "" "" "" 
                             ""}

    set mem_type         [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    if {[string match -nocase {lpddr} $mem_type]} {
        set list_iostandards {"MOBILE_DDR" "MOBILE_DDR" "MOBILE_DDR" "MOBILE_DDR"
                              "MOBILE_DDR" "MOBILE_DDR" "DIFF_MOBILE_DDR" "DIFF_MOBILE_DDR"
                              "MOBILE_DDR" "MOBILE_DDR" "MOBILE_DDR" "MOBILE_DDR"
                              "MOBILE_DDR" "MOBILE_DDR" "MOBILE_DDR" "MOBILE_DDR"
                              "MOBILE_DDR" "MOBILE_DDR" "MOBILE_DDR"}
    } elseif {[string match -nocase {ddr} $mem_type]} {
        set list_iostandards {"SSTL2_II" "SSTL2_II" "SSTL2_II" "SSTL2_II"
                              "SSTL2_II" "SSTL2_II" "DIFF_SSTL2_II" "DIFF_SSTL2_II"
                              "SSTL2_II" "SSTL2_II" "SSTL2_II" "SSTL2_II"
                              "SSTL2_II" "SSTL2_II" "SSTL2_II" "SSTL2_II"
                              "SSTL2_II" "SSTL2_II" "SSTL2_II"}
    } elseif {[string match -nocase {ddr2} $mem_type]} {
        if {[xget_hw_parameter_value $mhsinst "C_DDR2_DQSN_ENABLE"]} { 
            set list_iostandards {"SSTL18_II" "SSTL18_II" "SSTL18_II" "SSTL18_II"
                                  "SSTL18_II" "SSTL18_II" "DIFF_SSTL18_II" "DIFF_SSTL18_II"
                                  "SSTL18_II" "DIFF_SSTL18_II" "SSTL18_II" "DIFF_SSTL18_II"
                                  "DIFF_SSTL18_II" "DIFF_SSTL18_II" "SSTL18_II" "SSTL18_II"
                                  "SSTL18_II" "SSTL18_II" "SSTL18_II"}
        } else { 
            set list_iostandards {"SSTL18_II" "SSTL18_II" "SSTL18_II" "SSTL18_II"
                                  "SSTL18_II" "SSTL18_II" "DIFF_SSTL18_II" "DIFF_SSTL18_II"
                                  "SSTL18_II" "SSTL18_II" "SSTL18_II" "SSTL18_II"
                                  "SSTL18_II" "SSTL18_II" "SSTL18_II" "SSTL18_II"
                                  "SSTL18_II" "SSTL18_II" "SSTL18_II"}
        }

    } elseif {[string match -nocase {ddr3} $mem_type]} {
        set list_iostandards {"SSTL15_II" "SSTL15_II" "SSTL15_II" "SSTL15_II"
                              "SSTL15_II" "SSTL15_II" "DIFF_SSTL15_II" "DIFF_SSTL15_II"
                              "SSTL15_II" "DIFF_SSTL15_II" "SSTL15_II" "DIFF_SSTL15_II"
                              "DIFF_SSTL15_II" "DIFF_SSTL15_II" "SSTL15_II" "SSTL15_II"
                              "SSTL15_II" "SSTL15_II" "SSTL15_II"}
    }
                     

    # Get LOC information.
    set target_mcb       [xget_hw_parameter_value $mhsinst "C_MCB_LOC"]
   
    # Get FPGA information. 
    set basefamily       [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]

    if { [string match {spartan6} $basefamily] } {
        if { $target_mcb != "NOT_SET" } {
    
            array set array_pads {}
            util_parse_spartan6_pkg_file $mhsinst array_pads
            
            # Search after connections.
            # Only apply LOC to connected signals.
            foreach {mcb_signal} $list_mcb_signals {fpga_signal} $list_fpga_signals {iostandard} $list_iostandards {
                # Get handle to the signal.
                set port          [xget_hw_port_handle $mhsinst $mcb_signal]
                
                # Check if the signal is connected to anything.
                if { [llength $port] != 0 } {
                    # Get the name of the connection (if connected).
                    set port_conn     [xget_hw_value $port]
                    
                    if { [llength $port_conn] != 0 } {
                        # Get the connection's sinks.
                        set port_mhs      [xget_hw_connected_ports_handle $mhs_handle $port_conn "sink"]
                        
                        # Find sink that doesn't belong to MPMC.
                        # (IO signals returns both external port and MPMC)
                        foreach {curr_port} $port_mhs {
                            if { $curr_port != $port } {
                                # Use this name.
                                set port_name     [xget_hw_name $curr_port]
                                set port_handle   $curr_port
                            }
                        }
                        
                        # Error out if signal isn't connected to a port.
                        if { [info exists port_name] == 0 } {
                            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                            error "$instname\:\:Signal \"${mcb_signal}->${port_conn}\" is only connected to MPMC, there must be an external connection as well (Spartan-6)." "" "mdt_error" 
                        }
                        
                        # Get width of signal.
                        # (first find associated variable if any, the get width) 
                        set signal_width_name   [lindex $list_mcb_width [lsearch $list_mcb_signals $mcb_signal]]
                        if { [llength $signal_width_name] != 0 } {
                            set signal_width    [xget_hw_parameter_value $mhsinst $signal_width_name]
                        } else {
                            set signal_width    0
                        }
                        
                        # Match the MPMC pins to their correct LOC.
                        if { $signal_width == 0 } {
                            # Single bit signal.
                            set signal_loc    [util_lookup_pin_location array_pads $fpga_signal]

                            # Override the RZQ/ZIO location if the values are set.
                            if {[string match -nocase {rzq} $fpga_signal]} { 
                                set rzq_loc [xget_hw_parameter_value $mhsinst "C_MCB_RZQ_LOC"]
                                if {![string match -nocase {NOT_SET} $rzq_loc]} { 
                                    gui_drc_rzq_zio_loc $mhsinst
                                    set signal_loc $rzq_loc
                                } else { 
                                    set old_rzq_loc [util_lookup_pin_location_v3_4 $mhsinst "rzq"]
                                    set error_string ""
                                    if {[string equal $old_rzq_loc ""]} { 
                                        set error_string ""
                                    } else { 
                                        set error_string " If you are upgrading from EDK 12.1 or older then this value was previously set to $old_rzq_loc automatically."
                                    }
                                    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                                    error "Signal $fpga_signal is connected but C_MCB_RZQ_LOC is not set.  This parameter specifies the LOC constraint for this pin. $error_string If this is a new design, please select a valid pin that is compatible with your board layout. Open the MPMC IP Configurator and in the 'Memory Interface->MCB' tab set this parameter." "" "mdt_error"

                                }
                            } elseif {[string match -nocase {zio} $fpga_signal]} { 
                                set zio_loc [xget_hw_parameter_value $mhsinst "C_MCB_ZIO_LOC"]
                                if {![string match -nocase {NOT_SET} $zio_loc]} { 
                                    gui_drc_rzq_zio_loc $mhsinst
                                    set signal_loc $zio_loc
                                } else { 
                                    set old_zio_loc [util_lookup_pin_location_v3_4 $mhsinst "zio"]
                                    set error_string ""
                                    if {[string equal $old_zio_loc ""]} { 
                                        set error_string ""
                                    } else { 
                                        set error_string " If you are upgrading from EDK 12.1 or older then this value was previously set to $old_zio_loc automatically."
                                    }
                                    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                                    error "Signal $fpga_signal is connected but C_MCB_ZIO_LOC is not set.  This parameter specifies the LOC constraint for this pin. $error_string If this is a new design, please select a valid pin that is compatible with your board layout. Open the MPMC IP Configurator and in the 'Memory Interface->MCB' tab set this parameter." "" "mdt_error"

                                }
                            }
                                
                            # Write the constraint.
                            puts $outputFile  "NET \"${mcb_signal}\" LOC = ${signal_loc} | IOSTANDARD = $iostandard;"
                        } else {
                            # Bus signal.
                            for {set x 0} { $x<$signal_width } {incr x} {

                                # Index 0 is the PAD from util_parse_spartan6_pkg_file
                                set signal_loc    [util_lookup_pin_location array_pads $fpga_signal$x]
                                
                                # Write the constraint.
                                puts $outputFile  "NET \"${mcb_signal}\[${x}\]\" LOC = ${signal_loc} | IOSTANDARD = $iostandard;"
                            }
                        }
                        
                        # Prepare for next iteration.
                        unset port_name
                    }
                }
            }
        }
    }
}


proc generate_mig_phy_constraints { mhsinst outputFile } {

    set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set lcinstname      [string tolower $instname]
    set mig_out         "__xps/mig/gui"
    set mig_tmp         "__xps/mig/tmp"
    set cwd             [pwd]

    set system_handle   [xget_hw_parent_handle $mhsinst]
    set system_name     [xget_hw_name $system_handle]
    set system_mhs      [file join ${cwd} "${system_name}.mhs"]
    set mem_type        [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set clk_width       [xget_hw_parameter_value $mhsinst "C_MEM_CLK_WIDTH"]
    set odt_width       [xget_hw_parameter_value $mhsinst "C_MEM_ODT_WIDTH"]
    set cs_n_width      [xget_hw_parameter_value $mhsinst "C_MEM_CS_N_WIDTH"]
    set ce_width        [xget_hw_parameter_value $mhsinst "C_MEM_CE_WIDTH"]
    set family          [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set clk_period      [xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]

    set ucf_filename [file join $cwd $mig_out [get_mig_ucf_filename $mhsinst]]

    set ucftmp_filename [file join $cwd $mig_tmp "${lcinstname}_mpmc.ucf"]

    if {[file exists $ucf_filename ] == 0 || [file readable $ucf_filename ] == 0} { 
        error "$ucf_filename does not exist or is not readable.  Please ensure you have properly configured and run MIG\
               from the MPMC IP Configurator" "" "mdt_error"
    }

    if {[file exists $system_mhs ] == 0|| [file readable $system_mhs ] == 0} { 
        error "MHS file $system_mhs not found or is not readable. Cannot generate UCF constraints."
    }

    set    convert_ucf [xget_hw_pcore_dir $mhsinst]
    append convert_ucf "convert_ucf.pl"

    if {[file exists $convert_ucf ] == 0 || [file readable $convert_ucf ] == 0} { 
        error "File $convert_ucf is not found or unable to be opened for reading." "" "mdt_error" 
    }

    exec xilperl $convert_ucf \
            --batch \
            --mpmc_clk0_period $clk_period \
            --family $family \
            --instance $instname \
            --mem_type $mem_type \
            --clk_width $clk_width \
            --odt_width $odt_width \
            --ce_width $ce_width \
            --cs_n_width $cs_n_width \
            $ucf_filename \
            $ucftmp_filename


    if {[catch {open $ucftmp_filename r} UCF]} { 
        error "File $ucftmp_filename: $UCF" "" "mdt_error" 
    } else { 
        while {[gets $UCF line] >= 0} { 
            puts $outputFile $line
        }
        close $UCF
    }
}

proc generate_v5_ddr2_mig_phy_constraints { mhsinst outputFile } {
    #---------------------------------------------------------------------
    #     BEGIN: V5 DDR2 MIG PHY dependent constraints
    #---------------------------------------------------------------------
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set static_phy  [xget_hw_parameter_value $mhsinst "C_USE_STATIC_PHY"]

    if { [string match -nocase {virtex5} $family] && [string match -nocase {DDR2} $mem_type] && $static_phy == 0 } {
        puts $outputFile "AREA_GROUP \"DDR_CAPTURE_FFS\" GROUP = CLOSED;"
    }
}


proc generate_mmcm_loc_constraints { mhsinst outputFile } {
    #---------------------------------------------------------------------
    #     BEGIN: MMCM_ADV         dependent constraints
    #---------------------------------------------------------------------

    set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set param_name      "C_MMCM_INT_LOC"
    set loc_value [xget_hw_parameter_value $mhsinst "C_MMCM_INT_LOC" ]  

    # the value must be set
    if { [string length $loc_value] == 0 } {
        puts  "\nWARNING:  $instname ($ipname) -\n      The parameter $param_name must be set.\n"
        # if this is not a default - "NOT_SET", then generate ucf file
    } elseif { [string match -nocase {NOT_SET} $loc_value] == 0 } {

        if { [regexp MMCM_ADV_X\[0-9\]\?\[0-9\]Y\[0-9\]\?\[0-9\] $loc_value] == 0 } {
            error "Invalid parameter $param_name = $loc_value" "" "mdt_error"
        }

        set mem_type [string tolower [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]]
        puts $outputFile "######################################################################################"
        puts $outputFile "## INTERNAL MMCM_ADV CONSTRAINTS                                                    ##"
        puts $outputFile "######################################################################################"
        puts $outputFile "INST \"${instname}/mpmc_core_0/gen_v6_${mem_type}_phy.mpmc_phy_if_0/u_phy_read/u_phy_rdclk_gen/u_mmcm_clk_base\" LOC = \"${loc_value}\";"
    }
}


proc generate_idelayctrl_loc_constraints { mhsinst outputFile } {
    #---------------------------------------------------------------------
    #     BEGIN: C_IDELAYCTRL_LOC dependent constraints
    #---------------------------------------------------------------------

    # The following constraints are parameter C_IDELAYCTRL_LOC dependent
    set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set loc_values [xget_hw_parameter_value $mhsinst "C_IDELAYCTRL_LOC" ]  

    # the value must be set
    if { [string length $loc_values] == 0 } {
        puts  "\nWARNING:  $instname ($ipname) -\n      The parameter C_IDELAYCTRL_LOC must be set.\n"
        # if this is not a default - "NOT_SET", then generate ucf file
    } elseif { [string match -nocase {NOT_SET} $loc_values] == 0 } {

        # get a list by splitting $loc_values at each "-"
        set vlist       [split $loc_values -]
        set vlist_upper [string toupper $vlist]
        set list_length [llength $vlist_upper]
        set idelay_num  [xget_hw_parameter_value $mhsinst "C_NUM_IDELAYCTRL" ] 

        # The list length must be equal to C_NUM_IDELAYCTRL
        if { [string compare $list_length $idelay_num] == 0 } {
            # check if any invalid pair value
            foreach value $vlist_upper {
                if { [regexp IDELAYCTRL_X\[0-9\]\?\[0-9\]Y\[0-9\]\?\[0-9\] $value] == 0 } {
                    error "Invalid parameter C_IDELAYCTRL_LOC = $loc_values" "" "mdt_error"
                }
            }

            set suffix 0
            foreach value $vlist_upper {

                puts $outputFile "INST \"${instname}/*gen_instantiate_idelayctrls\[${suffix}\].idelayctrl0\"   \
                                  LOC = \"${value}\";"
                incr suffix
            }  
        } else {
            error "parameter C_IDELAYCTRL_LOC must have a list of value equals to C_NUM_IDELAYCTRL" "" "mdt_error"
        }
    }
}




#***--------------------------------***-----------------------------------***
#
#                       Mig Invocoation Related Procedures
#
#***--------------------------------***-----------------------------------***

#-------------------------------------------
# Create necessary files and launch mig
# Input dir is the output directory for the mig files
# Input mode is either interactive or batch
#-------------------------------------------
proc run_mig { mhsinst dir mode } { 

    set instname        [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set lcinstname      [string tolower $instname]
    set mig_out         "__xps/mig/${dir}"
    set mig_tmp         "__xps/mig/tmp"
    set cwd             [pwd]

    set cgp_filename            [file join $cwd $mig_tmp "${lcinstname}_${mode}.cgp"]
    set xml_filename            [file join $cwd $mig_tmp "${lcinstname}_${mode}.xml"]
    set log                     [file join $cwd $mig_tmp "${lcinstname}_${mode}.log"]
    set mig_script              [file join $cwd $mig_tmp "${lcinstname}_${mode}.sh"]
    set prj_filename            [file join $cwd __xps mig gui ${instname} user_design mig.prj]
    set working_directory       [file join $cwd $mig_tmp]
    set subworking_directory    [file join $cwd $mig_out]
    set output_directory        [file join $cwd $mig_tmp]
    # Check UCF after MIG runs to verify project has completed successfully.
    set ucf_filename            [file join ${subworking_directory} [get_mig_ucf_filename $mhsinst]]


    foreach dir_tmp [list "__xps" "__xps/mig" $mig_out $mig_tmp] {
        if {[file exists $dir_tmp] == 0} {
            file mkdir   $dir_tmp
        }
    }

    if {[file exists $prj_filename]} {
        if {[string equal {interactive} $mode]} { 
            puts "INFO:  Existing MIG project found, importing project file.  If you wish to start from scratch, delete the\
                  $output_directory and re-run the Launch MIG button"
        }
        generate_cgp_file $mhsinst $cgp_filename $prj_filename $working_directory $subworking_directory $output_directory $mode
    } else {
        generate_cgp_file $mhsinst $cgp_filename "" $working_directory $subworking_directory $output_directory $mode
    }
    generate_mpmcinput_file $mhsinst $xml_filename
    set mig_cmd [generate_mig_script $mhsinst $mig_script $cgp_filename $log $xml_filename]


    puts "Launching MIG..."
    execpipe $mig_cmd
    if {[file exists $ucf_filename] == 0} {
        puts "ERROR: The MIG project was not generated.  \"$ucf_filename\" could not be found."
    } elseif {[string match {interactive} $mode]} { 
        puts "MIG project successfully generated in <EDK Project Dir>/__xps/mig/.  The MIG UCF is located at \
              ${ucf_filename}. The memory pinouts used for MPMC will be generated from this MIG project during \
              platgen, and can be removed from the main project UCF.  Do not delete the __xps directory or the \
              current MPMC pinout will be lost."
    }
}


proc generate_cgp_file {mhsinst cgpFile xmlFile workingDir subWorkingDir outputDir mode} { 

    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]

    set lcinstname [string tolower $instname]

    set template [xget_hw_pcore_dir $mhsinst]
    append template "mig_cgp.internal"

    # These array indices are crafted to match those in the XCO file
    set cgpArr(MODE)            $mode
    set cgpArr(STANDALONE)      "TRUE"

    set cgpArr(devicefamily)        [xget_hw_parameter_value $mhsinst "C_FAMILY"]
    set cgpArr(package)             [xget_hw_parameter_value $mhsinst "C_PACKAGE"]
    set cgpArr(speedgrade)          [xget_hw_parameter_value $mhsinst "C_SPEEDGRADE"]
    # To get the device, we will get the full part name and parse out the 
    # package and speedgrade
    set cgpArr(device)              [xget_hw_proj_setting "fpga_xdevice"]
    if {[string equal {} $cgpArr(device)]} { 
        set cgpArr(device)              [xget_hw_proj_setting "fpga_partname"]
        regsub -- $cgpArr(package)$cgpArr(speedgrade) $cgpArr(device) {} cgpArr(device)
    }
    puts "devicefamily is $cgpArr(devicefamily)"
    puts "package is $cgpArr(package)"
    puts "speedgrade is $cgpArr(speedgrade)"
    puts "device is $cgpArr(device)"
    set cgpArr(workingdirectory)    $workingDir
    set cgpArr(subworkingdirectory) $subWorkingDir
    set cgpArr(outputdirectory)     $outputDir
#    set cgpArr(outputdirectory)    [pwd] 
#    append cgpArr(outputdirectory) "/__xps/mig"
    ## MIG VERSION ##
    set mig_ver [get_mig_version]
    set cgpArr(component_name) $instname 
    if {[string equal $xmlFile ""] == 0} {
        set cgpArr(xml_input_file) $xmlFile
    }

    # drc checks
    foreach index [array names cgpArr] {
        if {[string equal $cgpArr($index) ""]} {
            error "$index -- $cgpArr($index) could not be determined for MIG CGP generation." "" "mdt_error"
        }
    }

    if {[file exists $template] == 0 || [file readable $template] == 0} {
        error "File $template is not found or unable to open for reading." "" "mdt_error" 
    }

    # Open template to read
    if [catch {open $template r} tmplFileId] {
        error "File $template: $tmplFileId" "" "mdt_error" 
    } else {

        # Open file to write
        if [catch {open $cgpFile w} cgpFileId] {
            error "File $cgpFile: $cgpFileId" "" "mdt_error" 
        } else {

            # Go through each line and search and replace the lines we are interested in
            while {[gets $tmplFileId line] >= 0} { 

                # pass comments straight through and non set lines
                if {[regexp "^.*#" $line ]} {
                    puts $cgpFileId $line
                    continue
                } elseif {[regexp "^\s*SET" $line] == 0 } {
                    puts $cgpFileId $line
                    continue
                }

                # split the line to parse the SET <key> = <value>
                set lline [split $line " "]

                # Loop through the values we want to replace to see if the line matches
                foreach index [array names cgpArr] {
                    # if the <key> matches our $index then replace it the new value
                    if { [string equal $index [lindex $lline 1]] } { 
                        if { [llength $lline] > 2}  {
                            set lline [lreplace $lline 2 2 $cgpArr($index)]
                            continue
                        } else {
                            lappend lline $cgpArr($index)
                        }
                    }
                }
                # print out the line
                puts $cgpFileId [join $lline " "]
            }
            close $cgpFileId
        }
        close $tmplFileId
    }
}

#***--------------------------------***-----------------------------------***
# Utility process to call a command and pipe it's output to screen.
# Used instead of Tcl's exec
proc execpipe {COMMAND} {

  if { [catch {open "| $COMMAND 2>@stdout"} FILEHANDLE] } {
    return "Can't open pipe for '$COMMAND'"
  }

  set PIPE $FILEHANDLE
  fconfigure $PIPE -buffering none
  
  set OUTPUT ""
  
  while { [gets $PIPE DATA] >= 0 } {
    puts $DATA
    append OUTPUT $DATA "\n"
  }
  
  if { [catch {close $PIPE} ERRORMSG] } {
    
    if { [string compare "$ERRORMSG" "child process exited abnormally"] == 0 } {
      # this error means there was nothing on stderr (which makes sense) and
      # there was a non-zero exit code - this is OK as we intentionally send
      # stderr to stdout, so we just do nothing here (and return the output)
    } else {
      return "Error '$ERRORMSG' on closing pipe for '$COMMAND'"
    }

  }

  regsub -all -- "\n$" $OUTPUT "" STRIPPED_STRING
  return "$STRIPPED_STRING"

}

# Generate a wrapper script to call the mig executable.  This allows us to set
# the LD_LIBRARY_PATH correctly./env
proc generate_mig_script {mhsinst shFile cgpFile logFile xmlFile} {

    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set mig_exec [get_mig_executable]
    set mig_cmd  "$mig_exec \\\n"
    append mig_cmd  "-cg_exc_inp  $cgpFile \\\n"
    append mig_cmd  "-cg_exec_out $logFile \\\n"
    append mig_cmd  "-edk_mpmc_in $xmlFile"

    if [catch {open $shFile w} shFileId] { 
        error "File $shFile: $shFileId" "" "mdt_error" 
    } else { 
        puts $shFileId "#!/bin/sh"
        puts $shFileId "# Automatically Generated File.\n"
        puts $shFileId $mig_cmd
    }
    close $shFileId

    # make script executable if linux
    set host_os [xget_hostos_platform]
    if {[string match {lin} $host_os]} { 
        file attributes $shFile -permissions "a+x"
    }
    return $mig_cmd
}



# Generate a XML file to seed the mig program.
proc generate_mpmcinput_file {mhsinst xmlFile} { 

    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set mig_exec [get_mig_executable]

    # Input File
    set tmpl [file join [file dirname $mig_exec] .. .. data mpmcinput.xml]

    if {[file exists $tmpl] == 0 || [file readable $tmpl] == 0} {
        error "File $tmpl is not found or unable to open for reading." "" "mdt_error" 
    }

    set family   [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    # If family is spartan3e or spartan3a, alias to spartan3 for MIG.
    if {[string match {spartan3*} $family]} { 
        set family    "spartan3"
    }
    set is_mig_v6_phy [xget_hw_parameter_value $mhsinst "C_USE_MIG_V6_PHY"]
    set is_mig_v4_phy [xget_hw_parameter_value $mhsinst "C_USE_MIG_V4_PHY"]
    set is_mig_s3_phy [xget_hw_parameter_value $mhsinst "C_USE_MIG_S3_PHY"]
    set mem_type [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
    set partno   [xget_hw_parameter_value $mhsinst "C_MEM_PARTNO"]
    set clk_period [xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]
    syslevel_drc_mpmc_clk0_period_ps $mhsinst

    # Values of elements (keys) that we will be replacing in the template

    if {$is_mig_v6_phy} { 
        ###  Controller Options
        global array_partnolist
        set xmlArr(ComponentName)           $instname
        set xmlArr(Memory_Name)             [convert_mpmc_to_mig_mem_type $mem_type]
        set xmlArr(TimePeriod)              [expr {round(${clk_period}/2)}]

        set key_value [array get array_partnolist $partno,*,*,*,*,*]
        set key [lindex $key_value 0]
        set mem_style [lindex [split $key ","] 1]

        if {[string match -nocase {custom} $partno] || ![string match -nocase {components} $mem_style]} { 
            set xmlArr(Memory_Type)             "Components"
            set xmlArr(Custom_Part)             "TRUE"
            if {[string equal $mem_type "DDR3"]} { 
                set xmlArr(Memory_Part)         "MT41J128M8XX-15E"
            } elseif {[string equal $mem_type "DDR2"]} { 
                set xmlArr(Memory_Part)         "MT47H64M16XX-25"
            }
        } else {

            set xmlArr(Custom_Part)             "FALSE"
            set xmlArr(Memory_Type)             $mem_style
            set xmlArr(Memory_Part)             $partno
        }
        set xmlArr(Data_Width)              [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]

        # Set Mode Registers
        if {[string match -nocase {ddr3} $mem_type]} { 
            set xmlArr(Burst_Length)            "4 OR 8 - on the fly"
        } else { 
            set xmlArr(Burst_Length)            "8"
        }

        set xmlArr(Burst_Type)              "sequential"

        set CAS_Latency_Handle              [xget_hw_parameter_handle $mhsinst "C_MEM_CAS_LATENCY"]
        set CAS_Latency                     [syslevel_update_mem_cas_latency $CAS_Latency_Handle ]
        set xmlArr(CAS_Latency)             $CAS_Latency

        set xmlArr(Mode)                    "normal"
        set xmlArr(DLL_Reset)               "no"

        set TWR                             [xget_hw_parameter_value $mhsinst "C_TWR"]
     #   set xmlArr(Write_Recovery)          [expr {ceil(($TWR + $clk_period -1) / $clk_period)}]

        # Set Extended Mode Registers
        if {[string equal $mem_type "DDR3"]} { 
            if {[xget_hw_parameter_value $mhsinst "C_MEM_REDUCED_DRV"]} { 
                set xmlArr(Output_Drive_strength) "RZQ/7"
            } else { 
                set xmlArr(Output_Drive_strength) "RZQ/6"
            }
        } elseif {[string equal $mem_type "DDR2"]} {
            if {[xget_hw_parameter_value $mhsinst "C_MEM_REDUCED_DRV"]} { 
                set xmlArr(Output_Drive_strength) "Reducedstrength"
            } else { 
                set xmlArr(Output_Drive_strength) "Fullstrength"
            }
        }

        set RTT_ODT                         [xget_hw_parameter_value $mhsinst "C_MEM_ODT_TYPE"]
        if {[string equal $mem_type "DDR2"]} { 
            if {$RTT_ODT == 0} { 
                set xmlArr(RTT_ODT)             "RTT Disabled"
            } elseif {$RTT_ODT == 1} { 
                set xmlArr(RTT_ODT)             "75ohms"
            } elseif {$RTT_ODT == 2} { 
                set xmlArr(RTT_ODT)             "150ohms"
            } elseif {$RTT_ODT == 3} { 
                set xmlArr(RTT_ODT)             "50ohms"
            }
        } else { 
            if {$RTT_ODT == 0} { 
                set xmlArr(RTT_ODT)             "Disabled"
            } elseif {$RTT_ODT == 1} { 
                set xmlArr(RTT_ODT)             "RZQ/4"
            } elseif {$RTT_ODT == 2} { 
                set xmlArr(RTT_ODT)             "RZQ/2"
            } elseif {$RTT_ODT == 3} { 
                set xmlArr(RTT_ODT)             "RZQ/6"
            } elseif {$RTT_ODT == 4} { 
                set xmlArr(RTT_ODT)             "RZQ/12"
            } elseif {$RTT_ODT == 5} { 
                set xmlArr(RTT_ODT)             "RZQ/8"
            }
        }
        set xmlArr(Additive_Latency)        "0"
        set xmlArr(Data_Mask)               "1"

        set xmlMemArr(tmrd)             [expr {[string match -nocase {ddr2} $mem_type] ? "2" : "4"}]
        set xmlMemArr(trp)              [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRP"]/ 1000.0}]
        set xmlMemArr(trfc)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRFC"]/ 1000.0}]
        set xmlMemArr(trcd)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRCD"]/ 1000.0}]
        set xmlMemArr(tras)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRAS"]/ 1000.0}]
        set xmlMemArr(trtp)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRTP"]/ 1000.0}]
        set xmlMemArr(twtr)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TWTR"]/ 1000.0}]
        set xmlMemArr(twr)              [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TWR"]/ 1000.0}]
        set xmlMemArr(NewPartName)          [xget_hw_parameter_value $mhsinst "C_MEM_PARTNO"]
        set xmlMemArr(RowAdddress)          [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_ROW_BITS"]
        set xmlMemArr(ColoumAddress)        [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_COL_BITS"]
        set xmlMemArr(BankAddress)          [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_BANK_BITS"]

#       # END VIRTEX6
    } else {  
        # Spartan3/Virtex4/Virtex5
        set xmlArr(ComponentName)           $instname
        set xmlArr(Memory_Name)             [convert_mpmc_to_mig_mem_type $mem_type]
        set xmlArr(TimePeriod)              ${clk_period}
        set xmlArr(Memory_Type)             "Components"
        if {[string equal $mem_type "DDR3"]} { 
            set xmlArr(Memory_Part)         "MT41J128M8XX-15E"
        } elseif {[string equal $mem_type "DDR2"]} { 
            set xmlArr(Memory_Part)         "MT47H64M8XX-3"
        } else { 
            set xmlArr(Memory_Part)         "MT46V32M8XX-5B"
        }

        set xmlArr(Data_Width)              [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]
        set ecc                             [xget_hw_parameter_value $mhsinst "C_INCLUDE_ECC_SUPPORT"]
        if {$ecc == 1} { 
            set xmlArr(Data_Width)          [expr {[xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"] + 8}]
        } else { 
            set xmlArr(Data_Width)          [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]
        }

        if {!$is_mig_s3_phy} { 
            set xmlArr(ECC)                 "ECC Disabled"
        }

        # Set Mode Registers
        set xmlArr(Burst_Length)            "4(010)"
        set xmlArr(Burst_Type)              "sequential(0)"
        set CAS_Latency_Handle              [xget_hw_parameter_handle $mhsinst "C_MEM_CAS_LATENCY"]
        set CAS_Latency                     [syslevel_update_mem_cas_latency $CAS_Latency_Handle ]
        if {$CAS_Latency == 2} { 
            set xmlArr(CAS_Latency)         "2(010)"
        } elseif {$CAS_Latency == 3} { 
            set xmlArr(CAS_Latency)         "3(011)"
        } elseif {$CAS_Latency == 4} { 
            set xmlArr(CAS_Latency)         "4(100)"
        } elseif {$CAS_Latency == 5} { 
            set xmlArr(CAS_Latency)         "5(101)"
        } elseif {$CAS_Latency == 6} { 
            set xmlArr(CAS_Latency)         "6(110)"
        } elseif {$CAS_Latency == 7} { 
            set xmlArr(CAS_Latency)         "7(111)"
        } else { 
            error "Cas Latency '$CAS_Latency' is not valid" "" "mdt_error"
        }


        set xmlArr(Mode)                    "normal(0)"
        if {[string equal $mem_type "DDR2"]} { 
            set xmlArr(DLL_Reset)               "no(0)"
            set TWR                             [xget_hw_parameter_value $mhsinst "C_TWR"]
            set Write_Recovery                  [expr {ceil(($TWR + $clk_period -1) / $clk_period)}]
            if {$Write_Recovery == 1} { 
                set xmlArr(Write_Recovery)      "1(000)"
            } elseif {$Write_Recovery == 2} { 
                set xmlArr(Write_Recovery)      "2(001)"
            } elseif {$Write_Recovery == 3} { 
                set xmlArr(Write_Recovery)      "3(010)"
            } elseif {$Write_Recovery == 4} { 
                set xmlArr(Write_Recovery)      "4(011)"
            } elseif {$Write_Recovery == 5} { 
                set xmlArr(Write_Recovery)      "5(100)"
            } elseif {$Write_Recovery == 6} { 
                set xmlArr(Write_Recovery)      "6(101)"
            } elseif {$Write_Recovery == 7} { 
                set xmlArr(Write_Recovery)      "7(110)"
            } elseif {$Write_Recovery == 8} { 
                set xmlArr(Write_Recovery)      "8(111)"
            }
            set xmlArr(PD_Mode)                 "fast exit(0)"
        }

        # Set Extended Mode Registers
        set xmlArr(DLL_Enable)                  "Enable-Normal(0)"

        # Drive strength values for DDR/DDR2 differ
        if {[string equal $mem_type "DDR"]} { 
            if {[xget_hw_parameter_value $mhsinst "C_MEM_REDUCED_DRV"]} { 
                set xmlArr(Output_Drive_strength) "Reduced(1)"
            } else { 
                set xmlArr(Output_Drive_strength) "Normal(0)"
            }
        } elseif {[string equal $mem_type "DDR2"]} {
            if {[xget_hw_parameter_value $mhsinst "C_MEM_REDUCED_DRV"]} { 
                set xmlArr(Output_Drive_strength) "Reducedstrength(1)"
            } else { 
                set xmlArr(Output_Drive_strength) "Fullstrength(0)"
            }
        }

        if {[string equal $mem_type "DDR2"]} { 
            set RTT_ODT                         [xget_hw_parameter_value $mhsinst "C_MEM_ODT_TYPE"]
            if {$RTT_ODT == 0} { 
                set xmlArr(RTT_ODT)             "RTT Disabled(00)"
            } elseif {$RTT_ODT == 1} { 
                set xmlArr(RTT_ODT)             "75ohms(01)"
            } elseif {$RTT_ODT == 2} { 
                set xmlArr(RTT_ODT)             "150ohms(10)"
            } elseif {$RTT_ODT == 3} { 
                set xmlArr(RTT_ODT)             "50ohms(11)"
            }
            set xmlArr(Additive_Latency)        "0(000)"
            set xmlArr(OCD)                     "OCD Exit(000)"
            set xmlArr(DQS)                     [expr {[xget_hw_parameter_value $mhsinst "C_DDR2_DQSN_ENABLE"] == 1 \
                                                 ? "Enable(0)" : "Disable(1)"}]
            set xmlArr(RDQS)                    "Disable(0)"
            set xmlArr(Outputs)                 "Enable(0)"
        }
        set xmlArr(Data_Mask)               "1"


        set xmlArr(Debug)                   "TRUE"
        set xmlArr(Custom_Part)             "TRUE"

        if {$is_mig_v4_phy} { 
            set xmlArr(Memory_Depth) [xget_hw_parameter_value $mhsinst "C_MEM_NUM_RANKS"]
        }

        #Memory Part Array
        if {[string equal $mem_type "DDR2"]} { 
            set xmlMemArr(tmrd)             2
            set xmlMemArr(trp)              [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRP"]/ 1000.0}]
            set xmlMemArr(trfc)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRFC"]/ 1000.0}]
            set xmlMemArr(trcd)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRCD"]/ 1000.0}]
            set xmlMemArr(tras)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRAS"]/ 1000.0}]
            set xmlMemArr(trtp)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRTP"]/ 1000.0}]
            set xmlMemArr(twtr)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TWTR"]/ 1000.0}]
            set xmlMemArr(twr)              [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TWR"]/ 1000.0}]
        } elseif {[string equal {DDR} $mem_type]} { 

            set xmlMemArr(tmrd)             2
            set xmlMemArr(trp)              [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRP"]/ 1000.0}]
            set xmlMemArr(trfc)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRFC"]/ 1000.0}]
            set xmlMemArr(trcd)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRCD"]/ 1000.0}]
            set xmlMemArr(tras)             [expr {[xget_hw_parameter_value $mhsinst "C_MEM_PART_TRAS"]/ 1000.0}]
        }

        set xmlMemArr(NewPartName)          [xget_hw_parameter_value $mhsinst "C_MEM_PARTNO"]
        set xmlMemArr(RowAdddress)          [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_ROW_BITS"]
        set xmlMemArr(ColoumAddress)        [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_COL_BITS"]
        set xmlMemArr(BankAddress)          [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_BANK_BITS"]
    }
    
    # Open template to read
    set xmlRoot [xxml_read_file $tmpl]
    if {$xmlRoot == 0} {
        error "File $tmpl could not be opened or parsed." "" "mdt_error"
    } else {

        # Get Element pointing to our MPMC flow tag
        set xmlMPMC [xxml_get_sub_elements $xmlRoot "MPMC"]
        if {[llength $xmlMPMC] < 1} {
            error "Could not find XML element <MPMC> in the file \"$tmpl\"." "" "mdt_error" 
        }
        if {[llength $xmlMPMC] > 1} {
            error "Found multiple matches for XML element <MPMC> in the file \"$tmple\"." "" "mdt_error" 
        }
          
        xxml_set_text $xmlMPMC TRUE

        # Get Element pointing to our FPGA Family
        set xmlFPGA [xxml_get_sub_elements $xmlRoot "FPGA\[@Family=$family\]"]
        if {[llength $xmlFPGA] < 1} {
            error "Could not find XML element <FPGA Family=$family> in the file \"$tmpl\"." "" "mdt_error" 
        }
        if {[llength $xmlFPGA] > 1} {
            error "Found multiple matches for XML element <FPGA Family=$family> in the file \"$tmpl.\"" "" "mdt_error" 
        }
          
        # Go through our list of elements to replacement, search and replace them.  If the element doesn't exist, create it 

        if [myxxml_clear_subelements $xmlFPGA] { 
            error "Error creating XML file for MIG." "" "mdt_error"
        }

        if [myxxml_update_subelements $xmlFPGA xmlArr] { 
            error "Error creating XML file for MIG." "" "mdt_error"
        }

        # Updated Custom Part Parameters
        set xmlParametersGroup [xxml_get_sub_elements $xmlFPGA "ParametersGroup"]

        if {[llength $xmlParametersGroup] > 1 } {
            error "Could not parse $tmpl correctly, foumd multiple matches for element ParametersGroup" "" "mdt_error"
        } 

        if [myxxml_clear_subelements $xmlParametersGroup] { 
            error "Error creating XML file for MIG." "" "mdt_error"
        }

        if [myxxml_update_subelements $xmlParametersGroup xmlMemArr] { 
            error "Error creating XML file for MIG." "" "mdt_error"
        }
        # Write out file 
        xxml_write_file $xmlRoot "$xmlFile"

        # Cleanup xxml
        xxml_cleanup $xmlRoot


    }
}

proc myxxml_update_subelements {xmlRoot xmlArray} { 

    upvar $xmlArray xmlArr

#    foreach $element [xxml_get_sub_elements $xmlRoot]
    # Go through our list of elements to replacement, search and replace them.  If the element doesn't exist, create it 
    foreach {element value} [array get xmlArr] { 
        if {[string equal $value ""]} {
            puts " $element value could not be determined for XML generation.\n"
            return 1
        }

        set xmlElement [xxml_get_sub_elements $xmlRoot $element]

        if {[llength $xmlElement] > 1 } {
            puts " Could not parse XML correctly, foumd multiple matches for element $element.\n"
            return 1
        } elseif {[llength $xmlElement] == 0 } {
            puts  "No match for $element found in XML file generation."
            return 1
        }

        xxml_set_text $xmlElement $value
    }

    return 0
}


# Iterate through all subelements of xmlRoot and set them to ""
proc myxxml_clear_subelements {xmlRoot} { 

    foreach xmlElement [xxml_get_sub_elements $xmlRoot] {

        if {[llength $xmlElement] > 1 } {
            puts " Could not parse XML correctly, foumd multiple matches for element $element.\n"
            return 1
        } elseif {[llength $xmlElement] == 0 } {
            puts  "No match for $element found in XML file generation."
            return 1
        }

        if {[string equal ParametersGroup [xxml_get_tag $xmlElement]] == 0}  {
            xxml_set_text $xmlElement ""
        }
    }

    return 0
}


#######################################################################
#
# Functions triggerd by the GUI
#
# filter_partno --> used when customer select the Mem Type, Density and other non MPD params
# update_memory_parameters -->  when customer selects a part in the GUI
# update_mpmc_highaddr --> Change in memory triggers High address Update
# mpmc_left_justify --> When Left Justify button is clicked
# mpmc_copy_portaddr --> Copy shared address to non-shared address
# xps_ipconfig_init --> Called by the GUI, when it is stared for the first time
#   gui_update_mem_dynamic_param
#     gui_update_mem_odt_type    
#     gui_update_mem_reduced_drv 
#     gui_update_mem_twtr        
#     gui_update_mem_width       
#     gui_update_rd_fifo_datapath
# mpmc_launch_mig --> Called by the gui when the MIG button is pressed
#
#
# Common Helper function called by both backend TCL and GUI
# 
#  --> init_memory
#
#######################################################################

#-------------------------------------------
# given Style, Type, Density, Part_Width, and Manufacturer
# update all memory path parameters
#-------------------------------------------
proc filter_partno {mhsinst} {

    global array_partnolist
    global array_partno_filter

    init_memory $mhsinst

    set family          [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set gui_list        [list G_MEM_STYLE G_MEM_TYPE G_MEM_DENSITY G_MEM_WIDTH G_MEM_MANUFACTURE]
    set part_list       "" 
    set part_list_unsorted ""
    set filter_string   "*"


    # Get the G_<params> and verify they are set.  These are the values used to filter the part numbers.
    foreach gui_param $gui_list { 
        set gui_param_value_array($gui_param) [xget_hw_parameter_value $mhsinst $gui_param]
        if {[string length $gui_param_value_array($gui_param)] == 0} { 
            error "The information for Style, Type, Density, Part_Width, or Manufacturer is incomplete." "" "mdt_error" 
        }
    }

    set Type $gui_param_value_array(G_MEM_TYPE)

    # If the G_MEM_TYPE is updated, some filter values may become invalid, set them back to * 
    foreach {gui_param gui_param_value} [array get gui_param_value_array] { 
        if { [string match {G_MEM_TYPE} $gui_param] } {
            continue
        }
        if { [llength [array names array_partno_filter "$gui_param,$gui_param_value,$Type"]] == 0 } {
            set gui_param_handle    [xget_hw_parameter_handle $mhsinst $gui_param]
            xset_hw_parameter_value $gui_param_handle "*"
            set gui_param_value_array($gui_param) "*"
        }
    }

    # Update partno filter values that appear in the drop lists
    update_memory_partno_filter $mhsinst 

    # Update list of Part Numbers that are displayed in the drop down.  
    foreach gui_param $gui_list { 
        append filter_string ",$gui_param_value_array($gui_param)"
    }

    # Array keys are in the format:  PartNo, Style, Type, Density, Part_Width, Manufacturer (no spaces)
    set part_list [array get array_partnolist $filter_string]

    # Get list of parts
    foreach {key value}  $part_list {
        set style [lindex [split $key ,] 1]
        set partno $value
        # If we are spartan6 or virtex6 and the memory is not a component filter out matches to ....XXX-23E
        if {([string match {spartan6} $family] || [string match {virtex6} $family]) 
            && ![string match -nocase {component*} $style] && [regexp -nocase {[^X]+[X]+-\w+} $partno]} { 
            continue
        }
        lappend part_list_unsorted $value 
    }

    set num_parts [llength $part_list_unsorted]
    # Create the values tag to update the part number list
    set list_partno "\(Select a part= Select a part ($num_parts)"
    append list_partno ", CUSTOM= CUSTOM "


    foreach partno [lsort $part_list_unsorted] {
        append list_partno ", "
        append list_partno "$partno= $partno" 
    }

    append list_partno "\)" 

    # Update part list values in datastructure 
    set param_handle    [xget_hw_parameter_handle $mhsinst "G_MEM_PARTNO"]
    xadd_hw_subproperty $param_handle             "VALUES" $list_partno
    # set the value to "Please select a part"
    xset_hw_parameter_value $param_handle "Select a part"

}

#-------------------------------------------
# initial memory database for lookup
#-------------------------------------------
proc init_memory {mhsinst} {

    global array_partno_family
    global array_partno_clk_period
    global array_partno_param
    global array_partnolist
    global array_partno_filter

    set family   [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]

    # Get current clock frequency.
    if {[string match -nocase {spartan6} $family]} { 
        set clk_period  [expr {[xget_hw_parameter_value $mhsinst "C_MPMC_CLK_MEM_2X_PERIOD_PS"]*2}]
    } elseif {[string match -nocase {virtex6} $family]} { 
        set clk_period  [expr {[xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]/2}]
    } else {
        set clk_period  [xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]
    }
    
    # Load database if there are no database present.
    # Reload database if there has been architecture change or 
    # frequency change, this is usually due to opening a new project.
    if { ( [array size array_partno_param] == 0 ) || 
         ( [array size array_partnolist] == 0 ) || 
         ( [string match -nocase $array_partno_family $family] == 0 ) || 
         ( $array_partno_clk_period != $clk_period ) } {
        
        # Clear any previous data.
        array unset array_partno_param  *
        array unset array_partnolist    *
        array unset array_partno_filter *
        
        # Register architecture and clock period for the database.
        set array_partno_family       $family
        set array_partno_clk_period   $clk_period

        # Workaround for MIG database, if partno starts with MPMC, then use the MPMC database.
        set mem_part [xget_hw_parameter_value $mhsinst "C_MEM_PARTNO"]
        # Select Database depending on architecture and mem_part workaround
        if {([string match -nocase {virtex6} $family] || [string match -nocase {spartan6} $family]) && [string match -nocase {mpmc-*} $mem_part] == 0} {
            # Set files that shall be scanned.
            set db_names [list [get_mig_memory_database "mem_parts.xml"]]
        
            # Use MIG database for new architectures.
            foreach {filePath}  $db_names {
                # Open and parse MIG data.
                parseXMLMIGDatabase    $filePath 0
            }
            
        } else {
            # Fallback to CSV for old architectures.
            
            # specify file name
            set    filePath [xget_hw_pcore_dir $mhsinst]
            append filePath "mpmc_memory_database.csv"
    
            if { [file exists $filePath] == 1 && [file readable $filePath] == 1} {
    
                parseCSVFile    $filePath
    
            } else {
    
                error "File $filePath is not found or unable to open for reading." "" "mdt_error" 
    
            }
        }
    }
}

#-------------------------------------------
# Update the memory pulldown filter list
#-------------------------------------------
proc update_memory_partno_filter { mhsinst } {
    global array_partno_family
    global array_partnolist
    global array_partno_filter

    set family  $array_partno_family
    set filter_keys [list G_MEM_STYLE G_MEM_DENSITY G_MEM_WIDTH G_MEM_MANUFACTURE]

    # Set the list of valid memory types.  Grab the list and convert it to a valid VALUES PSF tag.
    set g_mem_type_handle [xget_hw_parameter_handle $mhsinst "G_MEM_TYPE"]
    if {$g_mem_type_handle <= 0} {
        error "$g_mem_type_handle is not valid" "" mdt_error
    }
    set list_mem_types [get_list_valid_mem_types $family]

    foreach mem_type $list_mem_types {
        lappend list_values_mem_types "$mem_type=$mem_type"
    }
    set values_mem_types [join $list_values_mem_types {,}]

    xadd_hw_subproperty $g_mem_type_handle "VALUES" "($values_mem_types)"

    set Type [xget_hw_parameter_value $mhsinst "G_MEM_TYPE"]
    # Foreach type the in the array_partnolist database,
    # create a unique sorted list to populate the filters
    foreach filter_name $filter_keys {

        # List always includes the * glob
        set values_list [list {*=*}]
        # get list of value=value to update the values handle
        foreach filter_key [lsort -command FilterCompare [array names array_partno_filter "$filter_name,*,$Type"]] {
            set value $array_partno_filter($filter_key)
            lappend values_list "$value=$value"
        }
        set values_string [join $values_list {,}]
        set g_handle [xget_hw_parameter_handle $mhsinst $filter_name]
        xadd_hw_subproperty $g_handle "VALUES" "($values_string)"
    }

}

#-------------------------------------------
# This Compare function is used to compare filter values correctly.
# G_MEM_DENSITY is expanded out to its numeric form to correctly compare
# G_MEM_WIDTH has the preceding x removed to compare correctly as integers
#-------------------------------------------
proc FilterCompare {a b} {

    # Expect a and b to be in "G_NAME,FILTER_KEY,*" format
    set f_name  [lindex [split $a {,}] 0]
    set a_prime [lindex [split $a {,}] 1]
    set b_prime [lindex [split $b {,}] 1]

    # Convert DENSITY and WIDTH to integers for conversion
    switch -- $f_name {
        G_MEM_STYLE         -
        G_MEM_MANUFACTURE   {  }
        G_MEM_DENSITY       { 
                              regsub {^x}           $a_prime {   } a_prime
                              regsub {[m](?=[Bb])}  $a_prime { M } a_prime
                              regsub {[g](?=[Bb])}  $a_prime { G } a_prime
                              regsub {[t](?=[Bb])}  $a_prime { T } a_prime
                              regsub {bit}          $a_prime { b } a_prime
                              regsub {byte}         $a_prime { B } a_prime
                              set a_prime [convertDensity $a_prime]

                              regsub {^x}           $b_prime {   } b_prime
                              regsub {[m](?=[Bb])}  $b_prime { M } b_prime
                              regsub {[g](?=[Bb])}  $b_prime { G } b_prime
                              regsub {[t](?=[Bb])}  $b_prime { T } b_prime
                              regsub {bit}          $b_prime { b } b_prime
                              regsub {byte}         $b_prime { B } b_prime
                              set b_prime [convertDensity $b_prime]
                            }
        G_MEM_WIDTH         {
                              regsub {^x}   $a_prime {} a_prime
                              regsub {^x}   $b_prime {} b_prime
                            }
    }

    # If we are compare an integer use a math compare, otherwise use string compare
    if {[string is integer $a_prime] && [string is integer $b_prime]} {
        return [expr {$a_prime > $b_prime}]
    } else {
        return [string compare $a_prime $b_prime]
    }
}

#
# parse the XML MIG Memory Database file
#
#-------------------------------------------
# - parse a *.xml file to find supported memories
# - create database array_partno_param & array_partnolist 
#-------------------------------------------
proc parseXMLMIGDatabase {filename severity}  {
  
    # Get architecture for the current project.
    global array_partno_family
   
    # Memory types we support (MIG nomenclature)
    set list_supported_mpmc_mem_types [get_list_valid_mem_types $array_partno_family]
    set list_supported_mem_types  [convert_list_mpmc_to_mig_mem_type $list_supported_mpmc_mem_types]

    # Open database of supported memories.
    set xmlRoot [xxml_read_file $filename]
    if {$xmlRoot == 0} {
        error "File $filename could not be opened or parsed." "" "mdt_error"
    } else {

        # Find supported memory types for architecture.
        # Tag has this format: <MemoryType text="<mem type>_SDRAM" FPGA="architecture" ...>
        set xmlFPGA       [xxml_get_sub_elements $xmlRoot "MemoryType\[@FPGA=$array_partno_family\]"]
        set memory_types  [llength $xmlFPGA]

        # Parse each supported memory list.
        if { ($memory_types < 1) && ($severity != 0) } {
            error "Could not find XML element <FPGA=$array_partno_family> in the file \"$filename\"." "" "mdt_error" 
        } elseif {$memory_types >= 1} {
            # There are one or more matching memory types for this FPGA type.
            foreach {xmlMemory}  $xmlFPGA {
             
               # get the memory type to compare to out supported list 
                set mem_type_mig    [xxml_find_property $xmlMemory "text"]
                if {[lsearch -exact $list_supported_mem_types [string toupper $mem_type_mig]] == -1} {
                    continue
                }

                parseXMLMIGMemory $xmlMemory $filename $severity
            }
        }
        
        # Cleanup xxml
        xxml_cleanup $xmlRoot
    }
    
    return $memory_types
}


proc parseXMLMIGMemory {xmlMemory filename severity}  {
  
    # Get information for this memory type.
    set mem_type_mig    [xxml_find_property $xmlMemory "text"]
    
    # Remove "_SDRAM" to make it compatible with MPMC mem_type.
    set mem_type [convert_mig_to_mpmc_mem_type $mem_type_mig]
    
    # Find all memory components/dimm types.
    set xmlComp         [xxml_get_sub_elements $xmlMemory "group"]
    set memory_comps    [llength $xmlComp]
    
    # Parse the part list if any
    if { ($memory_comps < 1) && ($severity != 0) } {
        error "Could not find XML element <group> in the file \"$filename\"." "" "mdt_error" 
    } elseif {$memory_comps >= 1} {
      
        # There are one or more matching groups.
        foreach {xmlCurrentComp}  $xmlComp {
          
            # Get information for this memory type.
            set mem_style_mig [xxml_find_property $xmlCurrentComp "text"]
            set mem_style     $mem_style_mig
          
            # Find all part in the current group.
            set xmlPart       [xxml_get_sub_elements $xmlCurrentComp "Info"]
            set memory_parts  [llength $xmlPart]
            
            # Scan through all parts.
            foreach {xmlCurrentPart}  $xmlPart {
              
                # Get the part number.
                set partno          [xxml_find_property $xmlCurrentPart "PartNumber"]
                set supportedTypes  [xxml_find_property $xmlCurrentPart "supportedTypes"]
                set supportedTypes  [split $supportedTypes ","]
                set MappedParts     [xxml_find_property $xmlCurrentPart "MappedParts"]
                set MappedParts     [split $MappedParts ","]
                
                # File is derived from partno.
                set xmlFile         [get_mig_memory_database [string tolower "${mem_type_mig}/${mem_style_mig}/${partno}.xml"]]
                set xmlDescFile     [get_mig_memory_database [string tolower "${mem_type_mig}/description.xml"]]

                # Load memory spec and add to database.
                if {[llength $MappedParts] > 0}  {
                    parseXMLMIGMemoryData $xmlFile $xmlDescFile $mem_type $mem_style [concat $MappedParts $partno]
                } else { 
                    parseXMLMIGMemoryData $xmlFile $xmlDescFile $mem_type $mem_style $partno
                }
             
            }
        }
    }
}


proc parseXMLMIGMemoryData {xmlFile xmlDescFile mem_type mem_style supportedTypes}  {
  
    # Get the database variables.
    global array_partno_param
    global array_partnolist
    
    # Get clock frequncy for the current project.
    global array_partno_clk_period
    
    # Get architecture for the current project.
    global array_partno_family
    
    # Define lists that is used to find or translate parameters.
    set list_manufact   {"Micron" "Elpida" "Qimonda"}
    set list_param      {"tras" "trc" "trcd" "twr" "trp" "tmrd" "trrd" "trfc" "twtr" "trtp" "trefi"}
    set list_unit_lpddr {"ps"   "ps"  "ps"   "ps"  "ps"  "tCK"  "ps"   "ps"   "tCK"  "ps"   "ps"}
    set list_unit_other {"ps"   "ps"  "ps"   "ps"  "ps"  "tCK"  "ps"   "ps"   "ps"   "ps"   "ps"}
    set list_unit_name  {"ps" "ns" "us" "ms"}
    set list_translate  {{          1     1000 1000000 1000000000} \
                         {      0.001        1    1000    1000000} \
                         {   0.000001    0.001       1       1000} \
                         {0.000000001 0.000001   0.001          1}}
                         #  --> source unit
                         # |
                         # V target unit
  
    # Open the XML memory file to get the parameters.
    set xmlRoot [xxml_read_file $xmlFile]
    if {$xmlRoot == 0} {
        error "File $xmlFile could not be opened or parsed." "" "mdt_error"
    } else {
        # Open the XML memory description file to get the parameter units.
        set xmlDescRoot [xxml_read_file $xmlDescFile]
        if {$xmlDescRoot == 0} {
            error "File $xmlDescFile could not be opened or parsed." "" "mdt_error"
        } else {
            # Insert mem type and style (parameters)
            
            # Get unit definition per architecture.
            set xmlDescFPGA   [xxml_get_sub_elements $xmlDescRoot "MPMC"]
            
            # Calculate the "static" parameters that aren't available in the MIG DB.
            set memArr(C_MEM_PART_TDQSS)  1
            set memArr(C_MEM_PART_TAL)    0
            if { $mem_type == "DDR3" } {
                set memArr(C_MEM_PART_TCCD)   4
            } elseif { $mem_type == "DDR2" } {
                set memArr(C_MEM_PART_TCCD)   2
            } else {
                set memArr(C_MEM_PART_TCCD)   1
            }
            
            # Extract timing paramters from element attributes.
            # If it doesn't exist, set it to zero.
            # If the unit isn't defined, map it 1:1
            foreach {param} $list_param {
                # Set memory dependent unit translation.
                if { $mem_type == "LPDDR" } { 
                    set list_unit $list_unit_lpddr
                } else {
                    set list_unit $list_unit_other
                }
                
                # Get MPMC paramter unit.
                set mpmc_unit [lindex $list_unit [lsearch $list_param $param]]
                
                # Get property if available.
                set propval   [xxml_find_property $xmlRoot $param]
                if { [llength $propval] < 1 } {
                    set propval   0
                }
                
                # Find MIG unit for parameter. <ParameterName name=""...>
                set xmlDescFPGAUnit [xxml_get_sub_elements $xmlDescFPGA "ParameterName\[@name=$param\]"]
                if { [llength $xmlDescFPGAUnit] > 0  } {
                    # Get unit for MIG value.
                    set mig_unit        [xxml_find_property $xmlDescFPGAUnit "units"]
                } else {
                    # There aren't any unit definition available, 
                    # use same as MPMC to get a 1:1 translation.
                    set mig_unit        $mpmc_unit
                    
                }
                
                # Translate MIG unit to MPMC unit if necessary.
                if { $mpmc_unit != $mig_unit } {
                    if { $mpmc_unit == "tCK" } {
                        # Special case 1:
                        # Target is measured in tCK. Clock period is measured in ps.
                        # Convert input to ps and then calculate number of clock cycles.
                        set factor  [lindex [lindex $list_translate [lsearch $list_unit_name "ps"]] [lsearch $list_unit_name $mig_unit]]
                        set propval [expr {round($propval * $factor / $array_partno_clk_period)}]
                    } elseif { $mig_unit == "tCK" } {
                        # Special case 2:
                        # target is in time (ps/ns/...), source is in clock cycles.
                        # Multiply cycles with period and scale to get correct unit.
                        set factor  [lindex [lindex $list_translate [lsearch $list_unit_name $mpmc_unit]] [lsearch $list_unit_name "ps"]]
                        set propval [expr {round($propval * $array_partno_clk_period * $factor)}]
                    } else {
                        # Use table to get translation factor for the unit scaling.
                        set factor  [lindex [lindex $list_translate [lsearch $list_unit_name $mpmc_unit]] [lsearch $list_unit_name $mig_unit]]
                        set propval [expr {round($propval * $factor)}]
                    }
                } else {
                    # Round to integer.
                    set propval [expr {round($propval)}]
                }
                
                # Add to parameter array.
                set param_name  [string toupper "C_MEM_PART_${param}"]
                set memArr($param_name)       $propval
            }
            
            # Extract CAS information. <mrCasLatency>
            # Skip any entries that doesn't match the tmin,tmax syntax.
            set xmlData [xxml_get_sub_elements $xmlRoot "mrCasLatency"]
            if { [llength $xmlData] != 1 } {
                error "Could not find unique XML element group \"mrCasLatency\" in the file \"$xmlFile\"." "" "mdt_error" 
            }
            set xmlData [xxml_get_sub_elements $xmlData "value"]
            if { [llength $xmlData] < 1 } {
                error "Could not find any values in XML element group \"mrCasLatency\" in the file \"$xmlFile\"." "" "mdt_error" 
            }
            set tminlast  {}
            set tmaxlast  {}
            set cas_array {{1000000 0} {1000000 0} {1000000 0} {1000000 0}}
            set cas_index 0
            foreach {xmlValue} $xmlData {
                set tmin   [xxml_find_property $xmlValue tmin]
                set tmax   [xxml_find_property $xmlValue tmax]
                if { [llength $tmin] == 1 && [llength $tmax] == 1 } {
                    if { ( $tminlast != $tmin || $tmaxlast != $tmax ) && ( $cas_index < 4 ) } {
                        # New unique pair found. Clean it up and insert into array.
                        set cas_value [xxml_get_text $xmlValue]
                        regsub {\([01]*\)} $cas_value {} cas_value
                        set cas_array [lreplace $cas_array $cas_index $cas_index [list $tmin $cas_value]]
                        set cas_index [expr {$cas_index + 1}]
                        
                        set tminlast  $tmin
                        set tmaxlast  $tmax
                    }
                }
            }
            for {set cas_index 0} {$cas_index < 4} {incr cas_index} {
                # Add to parameter array.
                set param_name [string toupper "C_MEM_PART_CAS_[format %c [expr {65 + $cas_index}]]"]
                set param_data [lindex $cas_array $cas_index]
                set fmax   [expr {floor(1000000 / [lindex $param_data 0])}]
                set memArr(${param_name}_FMAX)  $fmax
                set memArr(${param_name}_TMIN)  [lindex $param_data 0]
                set memArr(${param_name})       [lindex $param_data 1]
            }
            
            # Extract Address bit information (Row).
            set xmlData [xxml_get_sub_elements $xmlRoot "Sets\[@name=RowAddress\]"]
            if { [llength $xmlData] != 1 } {
                error "Could not find unique XML element group \"RowAddress\" in the file \"$xmlFile\"." "" "mdt_error" 
            }
            set value [xxml_find_property $xmlData values]
            if { [llength $value] != 1 } {
                error "Could not find data for XML element group \"RowAddress\" in the file \"$xmlFile\"." "" "mdt_error" 
            }
            set value [split $value ","]
            set memArr(C_MEM_PART_NUM_ROW_BITS) [lindex $value 0]
            
            # Extract Address bit information (Column).
            set xmlData [xxml_get_sub_elements $xmlRoot "Sets\[@name=colAddress\]"]
            if { [llength $xmlData] != 1 } {
                error "Could not find unique XML element group \"colAddress\" in the file \"$xmlFile\"." "" "mdt_error" 
            }
            set value [xxml_find_property $xmlData values]
            if { [llength $value] != 1 } {
                error "Could not find data for XML element group \"colAddress\" in the file \"$xmlFile\"." "" "mdt_error" 
            }
            set value [split $value ","]
            set memArr(C_MEM_PART_NUM_COL_BITS) [lindex $value 0]
            
            # Extract Address bit information (Bank).
            set xmlData [xxml_get_sub_elements $xmlRoot "Sets\[@name=BankAddress\]"]
            if { [llength $xmlData] != 1 } {
                error "Could not find unique XML element group \"BankAddress\" in the file \"$xmlFile\"." "" "mdt_error" 
            }
            set value [xxml_find_property $xmlData values]
            if { [llength $value] != 1 } {
                error "Could not find data for XML element group \"BankAddress\" in the file \"$xmlFile\"." "" "mdt_error" 
            }
            set value [split $value ","]
            set memArr(C_MEM_PART_NUM_BANK_BITS) [lindex $value 0]
            
            # Extract constants block from XML <Sets name= "Constants">.
            set xmlConst [xxml_get_sub_elements $xmlRoot "Sets\[@name=Constants\]"]
            if { [llength $xmlConst] != 1 } {
                error "Could not find unique XML element group \"Constants\" in the file \"$xmlFile\"." "" "mdt_error" 
            } else {
                # Extract registered dimm information. <group keyword ="REGISTERED" ...> </group>
                set xmlData [xxml_get_sub_elements $xmlConst "group\[@keyword=REGISTERED\]"]
                if { [llength $xmlData] != 1 } {
                    error "Could not find unique XML element group with keyword \"REGISTERED\" in the file \"$xmlFile\"." "" "mdt_error" 
                }
                set parameter [xxml_find_property $xmlData parameter]
                set multiply  [xxml_find_property $xmlData multiply]
                if { [llength $parameter] < 1  || [llength $multiply] < 1 } {
                    set value     0
                } else {
                    set value     [expr {$parameter * $multiply}]
                }
                set memArr(C_MEM_REG_DIMM) $value
                
                # Extract component data width. <group keyword ="MEMORY_DEVICE_WIDTH" ...> </group>
                set xmlData [xxml_get_sub_elements $xmlConst "group\[@keyword=MEMORY_DEVICE_WIDTH\]"]
                if { [llength $xmlData] != 1 } {
                    error "Could not find unique XML element group with keyword \"MEMORY_DEVICE_WIDTH\" in the file \"$xmlFile\"." "" "mdt_error" 
                }
                set parameter [xxml_find_property $xmlData parameter]
                set multiply  [xxml_find_property $xmlData multiply]
                if { [llength $parameter] < 1  || [llength $multiply] < 1 } {
                    set value     0
                } else {
                    set value     [expr {$parameter * $multiply}]
                }
                set memArr(C_MEM_PART_DATA_WIDTH) $value
                
                # Extract memory density. <group keyword ="MEMORY_DENSITY" ...> </group>
                set xmlData [xxml_get_sub_elements $xmlConst "group\[@keyword=MEMORY_DENSITY\]"]
                if { [llength $xmlData] != 1 } {
                    error "Could not find unique XML element group with keyword \"MEMORY_DENSITY\" in the file \"$xmlFile\"." "" "mdt_error" 
                }
                set multiply  [xxml_find_property $xmlData multiply]
                if { [llength $multiply] < 1 } {
                    set value     0
                } else {
                    set value     $multiply
                }
                set density       "$value"
                
                # Extract the memory dencity expressed in Mb.
                set density_clean    [convertDensity $density]
                
                # Extract component density. <group keyword ="COMPONENT_DENSITY" ...> </group>
                set xmlData [xxml_get_sub_elements $xmlConst "group\[@keyword=COMPONENT_DENSITY\]"]
                if { [llength $xmlData] != 1 } {
                    error "Could not find unique XML element group with keyword \"COMPONENT_DENSITY\" in the file \"$xmlFile\"." "" "mdt_error" 
                }
                set multiply  [xxml_find_property $xmlData multiply]
                if { [llength $multiply] < 1 } {
                    set value     0
                } else {
                    set value     $multiply
                }
                set value       "x$value"
                
                # Extract the memory dencity expressed in Mb.
                set comp_density_clean    [convertDensity $value]
                
                # Extract rank. <group keyword="DUAL_RANK" parameter="1" multiply="1" ...> </group>
                set xmlData [xxml_get_sub_elements $xmlConst "group\[@keyword=DUAL_RANK\]"]
                if { [llength $xmlData] != 1 } {
                    set value     0
                } else {
                    set parameter [xxml_find_property $xmlData parameter]
                    set multiply  [xxml_find_property $xmlData multiply]
                    if { [llength $parameter] < 1  || [llength $multiply] < 1 } {
                        set value     0
                    } else {
                        set value     [expr {$parameter * $multiply}]
                    }
                }
                set memArr(C_MEM_NUM_RANKS)   [expr {1 + $value}]
                
                # Extract the manufacturer. <group keyword="*" ...> </group>
                set manfctr     "NoName"
                foreach {value}  $list_manufact {
                    set xmlData [xxml_get_sub_elements $xmlConst "group\[@keyword=[string toupper $value]\]"]
                    if { [llength $xmlData] == 1 } {
                        set manfctr     $value
                    }
                }
            }
            
            # Calculate the total memory width.
            # Only DIMM should differ from C_MEM_PART_DATA_WIDTH.
            set pwidth_clean    [expr {$memArr(C_MEM_PART_DATA_WIDTH) * $density_clean / $comp_density_clean / $memArr(C_MEM_NUM_RANKS)}]
            set pwidth          "x$pwidth_clean"
            
            
            # Extract clock width.
            set xmlDataWidth [xxml_get_sub_elements $xmlRoot "Sets\[@name=DataWidth\]"]
            if { [llength $xmlDataWidth] != 1 } {
                error "Could not find unique XML element group \"DataWidth\" in the file \"$xmlFile\"." "" "mdt_error" 
            } else {
                set xmlData [xxml_get_sub_elements $xmlDataWidth "group\[@name=Clock\]"]
                if { [llength $xmlData] != 1 } {
                    set xmlData [xxml_get_sub_elements $xmlDataWidth "virtex6\[@name=Clock\]"]
                    if { [llength $xmlData] != 1 } {
                        error "Could not find unique XML element group \"DataWidth\"/\"Clock\" in the file \"$xmlFile\"." "" "mdt_error" 
                    }
                } 
                set multiply  [xxml_find_property $xmlData multiply]
                if { [llength $multiply] < 1 } {
                    set value     1
                } else {
                    set value     [xxml_find_property $xmlData multiply]
                }
                set memArr(C_MEM_CLK_WIDTH)   $value
            }
            
            # Calculate memory density from.
            set memArr(C_MEM_PART_DATA_DEPTH)    [expr {$density_clean / $pwidth_clean}]
            
            # Extract width of control signal.
            set memArr(C_MEM_ODT_WIDTH)   $memArr(C_MEM_NUM_RANKS)
            set memArr(C_MEM_CE_WIDTH)    $memArr(C_MEM_NUM_RANKS)
            set memArr(C_MEM_CS_N_WIDTH)  $memArr(C_MEM_NUM_RANKS)
            
            # Get frequency property if available.
            # Use C_PARTNO* since C_MEM_PART* can't be used due to conflict.
            # Tmax is in ps, if not found, set to 1 second.
            set propval   [xxml_find_property $xmlRoot "tmax"]
            if { [llength $tmax] < 1 } {
                set tmax [expr {pow(10,12)}]
            }
            set memArr(C_PARTNO_TMAX)  [expr {round($tmax)}]
            set tmin   [xxml_find_property $xmlRoot "tmin"]
            if { [llength $tmin] < 1 } {
                set tmin   0
            }
            set memArr(C_PARTNO_TMIN)  [expr {round($tmin)}]
            
            # Calculate tRASMAX as 9 * tREFI
            set memArr(C_MEM_PART_TRASMAX)  [expr {$memArr(C_MEM_PART_TREFI) * 9}]
    
            # All data is added for the supported types.
            # The same file contents can be used for multiple entries.
            foreach {partno}  $supportedTypes {
                # x4 Parts not supported on Virtex-6
                if {[string match -nocase {virtex6} $array_partno_family] && [string match -nocase {x4} $pwidth]} { 
                    continue
                }
                   
                # Add to internal data base.
                set memArr(C_MEM_PARTNO) $partno
            
                set array_partnolist($partno,$mem_style,$mem_type,$density,$pwidth,$manfctr) $partno
                update_partno_filter_array $partno $mem_style $mem_type $density $pwidth $manfctr

                # Inset all data values into the supported part numbers.
                foreach index [array names memArr] {
                    set array_partno_param($partno,$index) $memArr($index)
                }
            }
            
            # Cleanup xxml.
            xxml_cleanup $xmlDescRoot
        }
        
        # Cleanup xxml.
        xxml_cleanup $xmlRoot
    }
}

#------------------------------
# Update array_partno_filter used for quick lookups
#------------------------------
proc update_partno_filter_array { partno mem_style mem_type density pwidth manfctr } {
    global array_partno_filter
    set array_partno_filter(G_MEM_STYLE,$mem_style,$mem_type)     $mem_style
    set array_partno_filter(G_MEM_DENSITY,$density,$mem_type)     $density
    set array_partno_filter(G_MEM_WIDTH,$pwidth,$mem_type)        $pwidth
    set array_partno_filter(G_MEM_MANUFACTURE,$manfctr,$mem_type) $manfctr
}

proc convertDensity {density}  {
    
    # Remove prefix (x) and suffix (Mb etc.).
    regsub -all -- {[a-zA-Z]*} $density {} density_clean
    regsub {[x0-9]*} $density {} value
    
    # Scale the value to Mb density.
    if { $value == "GB" } {
        set density_clean [expr {$density_clean * 8192}]
    } elseif { $value == "Gb" } {
        set density_clean [expr {$density_clean * 1024}]
    } elseif { $value == "MB" } {
        set density_clean [expr {$density_clean * 8}]
    } elseif { $value != "Mb" } {
        error "Unknown suffix \"$value\" on value \"$density\"." "" "mdt_error" 
    }
    
    return $density_clean
}


#
# parse the CSV file
#
#-------------------------------------------
# - parse the mpmc_memory_database.csv file 
# - create database array_partno_param & array_partnolist 
#-------------------------------------------
proc parseCSVFile {filename}  {

    global array_partno_param
    global array_partnolist
    set infID       [open $filename r]
    set listNames   ""
    
    while {[gets $infID line] >= 0 } {

        if { [llength $listNames] == 0 } {

            # split on commas
            set listNames [split $line ,]

        } else {

            set listData [split $line ,]
            set partno   [lindex $listData [lsearch $listNames "C_MEM_PARTNO"]]
            set partno   [string toupper   $partno]
            set style    [lindex $listData [lsearch $listNames "Style"]]
            set type     [lindex $listData [lsearch $listNames "Type"]]
            set density  [lindex $listData [lsearch $listNames "Density"]]
            set pwidth   [lindex $listData [lsearch $listNames "Part_Width"]]
            set manfctr  [lindex $listData [lsearch $listNames "Manufacturer"]]

            # create database for array_partnolist
            set array_partnolist($partno,$style,$type,$density,$pwidth,$manfctr) $partno

            update_partno_filter_array $partno $style $type $density $pwidth $manfctr
            # create database for array_partno_param
            for {set i 0} {$i < [llength $listData]} {incr i 1} {
            
                set param_name [string toupper [lindex $listNames $i]]

                if { [string match -nocase C_MEM* $param_name] == 1} {
                    
                    set array_partno_param($partno,$param_name) [lindex $listData $i]
                }

            }

        }

    }

    close $infID

}


proc gui_drc_pim_type { mhsinst } {
    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    set subfamily      [xget_hw_parameter_value $mhsinst "C_SUBFAMILY"]

    for {set i 0} {$i < 8} {incr i 1} {

        set param_handle [xget_hw_parameter_handle $mhsinst "C_PIM${i}_BASETYPE"]
        set my_param [xget_hw_value $param_handle ]

        if { ([string match -nocase {virtex5} $family] == 0 || \
                   [string match -nocase {fx} $subfamily] == 0) && \
                   [string match -nocase {5} $my_param] } {
            xset_hw_parameter_value $param_handle 0
            error "Port type PPC440MC is not supported on ${family}${subfamily}" "" "mdt_error"
        }
    } 

    # C_NUM_PORTS
    update_portno        $mhsinst
    mpmc_update_arbitration  $mhsinst
}


#-------------------------------------------
# convert C_ARBx_SLOTx to C_ART_BRAM_INIT_xx string
#-------------------------------------------
proc get_bram_addr {param_handle startSlot endSlot} {

    set mhsinst    [xget_hw_parent_handle    $param_handle]

    # the digit number of C_ARB0_SLOTx = C_NUM_PORTS
    # ex. if C_NUM_PORTS = 3 then C_ARB0_SLOT0 = "012" - 3 digits
    set portno     [xget_hw_parameter_value  $mhsinst "C_NUM_PORTS"]

    set slotno     [expr {$endSlot - $startSlot + 1}]
    set max_slotno       8
    set unused_slot_pads "00000000111111111111111111111111"

    if {$slotno == 0} {

        for {set i $slotno} {$i < $max_slotno } {incr i 1} {

            append addr $unused_slot_pads
        }

        return [format "0b%s" $addr]

    }

    set bram_addr       ""
    set slot_head       "00000000"
    set templatePort    ""
    set list_port       ""
    set used_slot_list  ""

    # update C_ARB_BRAM_INIT_xx, convert from C_ARB0_SLOTx, x = startSlot:endSlot
    for {set x $endSlot} {$x >= $startSlot} {incr x -1} {

        lappend used_slot_list [xget_hw_parameter_value $mhsinst "C_ARB0_SLOT$x"]

    }

    #---------------------
    # fill up unused slots
    #---------------------
    for {set i $slotno} {$i < $max_slotno } {incr i 1} {

        append bram_addr $unused_slot_pads
    }

    #---------------------
    # fill up used slots
    #---------------------
    # 1. fill up unused pads to a used slot
    set unused_pad  ""

    for {set i $portno} {$i < 8 } {incr i 1} {
        append unused_pad "111"
    }

    append slot_head $unused_pad

    # 2. get the used slot
    set list_slot ""

    for {set i 0} {$i < $slotno} {incr i 1} {

        set slot          [lindex $used_slot_list $i]
        set binary_format $slot_head

        for {set m [expr {[string length $slot] - 1}]} {$m >= 0} {incr m -1} {

            append binary_format [convert_num_to_binary [string index $slot $m] 3]

        }

        lappend list_slot $binary_format
    }

    for {set i 0} {$i < $slotno } {incr i 1} {

        append bram_addr [lindex $list_slot $i]
    }

    return [format "0b%s" $bram_addr]
}


#-------------------------------------------
# convert C_ARBx_SLOTx to C_ART_BRAM_INIT_00 string for Spartan-6
#-------------------------------------------
proc get_bram_addr_spartan6 {param_handle startSlot endSlot} {

    set mhsinst     [xget_hw_parent_handle    $param_handle]
    set portno      [xget_hw_parameter_value  $mhsinst "C_NUM_PORTS"]
    set port_config [xget_hw_parameter_value  $mhsinst "C_PORT_CONFIG"]
    set list_pnum   {{ 0 1 2 3 4 5} \
                     { 0 1 2 4 } \
                     { 0 2 4} \
                     { 0 2} \
                     { 0}}
                     
    set translate   [lrange [lindex $list_pnum $port_config] 0 [expr {$portno - 1}]]

    set binary_format "1111111111111111111111111111111111111111"
    if { $endSlot < 11 } {
        append binary_format "111111111111111111111111111111111111"
    }
    
    for {set x $endSlot} {$x >= $startSlot} {incr x -1} {
        
        set slot [xget_hw_parameter_value $mhsinst "C_ARB0_SLOT$x"]
        
        for {set m 5} {$m >= 0} {incr m -1} {
            if { $m < [string length $slot] } {
                # Translate and append.
                append binary_format [convert_num_to_binary [lindex $translate [string index $slot $m]] 3]
                
            } else {
                # Pad.
                append binary_format "111"
            } 
        }
    }
    
    return [format "0b%s" $binary_format]
}


#-------------------------------------------
# convert a number to a binary
# @ value       a number
# @ length      number of digit in binary
#-------------------------------------------
proc convert_num_to_binary {value length} {

    if {$length == 0} {

         error "xconvert_num_to_binary expects lenght to be a positive number" "" "mdt_error"
        return
    }

    set retval ""

    while {$value > 0} {

        set tval [expr {$value + 1}]
        set val_by_2 [expr {$value/2}]
        set tval_by_2 [expr {$tval/2}]
        if {$val_by_2 == $tval_by_2} {
            # means $val is even
            set retval [format "0%s" $retval]
        } else {
            # means $val is odd
            set retval [format "1%s" $retval]
        }
        set value [expr {$value/2}]
    }

    while {$length > [string length $retval]} {
        set retval [format "0%s" $retval]
    }

    return $retval
}


#***--------------------------------***------------------------------------***
#
#                        Update Control Path Parameters 
#
#***--------------------------------***------------------------------------***

#-------------------------------------------
# initial control database for lookup
#-------------------------------------------
proc init_control {mhsinst} {

    global array_ctrl_param
    global array_mpmcinst
    
    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set mpmclist [array get array_mpmcinst $instname]

    set family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]
    if {[string match -nocase {spartan6} $family]} { 
      return
    }
    
    if {[string length $mpmclist] == 0} {

        set array_mpmcinst($instname) $instname
        array unset array_ctrl_param
    } else {

        return
    }

    if { [array size array_ctrl_param] == 0 } {

        set mem_partno_handle [xget_hw_parameter_handle $mhsinst "C_MEM_PARTNO"]

        iplevel_drc_partno $mem_partno_handle

        # PERL script is called to generate a mpmc_ctrl_path_params.v file
        set    perlPath [xget_hw_pcore_dir $mhsinst]
        append perlPath "generate_ctrl_path_table.pl"

        if { [file exists $perlPath] == 1 && [file readable $perlPath] == 1} {

            if {[file exists __xps] == 0} {
                file mkdir   __xps 
            }
            set cwd [pwd]
            set    verFile [file join $cwd __xps "${instname}_ctrl_path_params.v"]
            set    txtFile [file join $cwd __xps "${instname}_ctrl_path_table.txt"]
            set    errFile [file join $cwd __xps "${instname}_ctrl_path_generation_errors.txt"]

            syslevel_drc_mpmc_clk0_period_ps $mhsinst

            set clk_period  [xget_hw_parameter_value $mhsinst "C_MPMC_CLK0_PERIOD_PS"]
            #-------------------------------------------
            #Limit the minimum frequency to 66MHz
            if {$clk_period > 15000} {
              set clk_period 15000;
            }

            set freq        [expr {1000000.0 / $clk_period}]
            set mem_type    [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
            
            # set burst length 8 if DDR3
            if { [string match -nocase {ddr3} $mem_type] } {
                set burst_length 8
            } else { 
                set burst_length 4
            }


            # execute perl script
        exec xilperl $perlPath \
            -family      [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]                          \
            -enable_ecc  [xget_hw_parameter_value $mhsinst "C_INCLUDE_ECC_SUPPORT"]             \
            -tRAS        [xget_hw_parameter_value $mhsinst "C_MEM_PART_TRAS"]                   \
            -part_data_width [xget_hw_parameter_value $mhsinst "C_MEM_PART_DATA_WIDTH"]         \
            -cas_latency [syslevel_update_mem_cas_latency [xget_hw_parameter_handle $mhsinst "C_MEM_CAS_LATENCY"]] \
            -cas_wr_latency [syslevel_update_mem_cas_wr_latency [xget_hw_parameter_handle $mhsinst "C_MEM_CAS_WR_LATENCY"]] \
            -memory_burst_length $burst_length                                                  \
            -tRC    [xget_hw_parameter_value $mhsinst "C_MEM_PART_TRC"]                         \
            -tRCD   [xget_hw_parameter_value $mhsinst "C_MEM_PART_TRCD"]                        \
            -nDQSS  [xget_hw_parameter_value $mhsinst "C_MEM_PART_TDQSS"]                       \
            -tWR    [xget_hw_parameter_value $mhsinst "C_MEM_PART_TWR"]                         \
            -tRP    [xget_hw_parameter_value $mhsinst "C_MEM_PART_TRP"]                         \
            -tRRD   [xget_hw_parameter_value $mhsinst "C_MEM_PART_TRRD"]                        \
            -tRFC   [xget_hw_parameter_value $mhsinst "C_MEM_PART_TRFC"]                        \
            -nAL    [xget_hw_parameter_value $mhsinst "C_MEM_PART_TAL"]                         \
            -nCCD   [xget_hw_parameter_value $mhsinst "C_MEM_PART_TCCD"]                        \
            -tWTR   [xget_hw_parameter_value $mhsinst "C_MEM_PART_TWTR"]                        \
            -tRTP   [xget_hw_parameter_value $mhsinst "C_MEM_PART_TRTP"]                        \
            -nZQCS  [xget_hw_parameter_value $mhsinst "C_MEM_PART_TZQCS"]                       \
            -c      $clk_period                                                                 \
            -reg    [xget_hw_parameter_value $mhsinst "C_MEM_REG_DIMM"]                         \
            -m      [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]                             \
            -d      [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]                       \
            -f_txt  $txtFile                                                                    \
            -f_err  $errFile                                                                    \
            -f_ver  $verFile                                                                    \
            -static_phy [xget_hw_parameter_value $mhsinst "C_USE_STATIC_PHY"]                   \
            -wr_mem_pipeline [get_wr_fifo_mem_pipeline $mhsinst]

            if { [file exists $verFile] == 1 && [file readable $verFile] == 1} {
                parsePerlFile $verFile
            } else {
                error "File $verFile is not found or unable to open for reading." "" "mdt_error" 
            }
        } else {
            error "File $perlPath is not found or unable to open for reading." "" "mdt_error" 
        }
    }
}

#-------------------------------------------
# - parse the mpmc_ctrl_path_params.v file 
# - create database array_ctrl_param 
#-------------------------------------------
proc parsePerlFile {filePath}  {

    global array_ctrl_param

    set infID       [open $filePath r]
    
    while {[gets $infID line] >= 0 } {

        if {[string length $line] == 0 || [string first "//" $line 0] != -1} {

            continue
        }

        if {[string match -nocase PARAMETER* $line] == 1} {

            set line_trim    [string trim $line ";"]
            set list [split  $line_trim   " "] 
            set param_name   ""
            set param_value  ""
            set size         [llength $list]

            # create database for array_partno_param
            for {set i 0} {$i < $size} {incr i 1} {
            
                set item [lindex $list $i]

                if { [string match -nocase C_* $item] == 1 } {
                    
                    set param_name $item
                    break
                } 

            }

            # get the parameter value
            set vlog_value [lindex $list [expr {$size - 1}]]

            if {[string match "*'h*" $vlog_value] == 1} {

                set hex_value [lindex [split $vlog_value "'h"] 2]
                set array_ctrl_param($param_name) [format "0x%s" $hex_value]

            } elseif {[string match "*'d*" $vlog_value] == 1} {

                set dec_value [lindex [split $vlog_value "'d"] 2]
                set array_ctrl_param($param_name) $dec_value

            } else {

                set array_ctrl_param($param_name) $vlog_value

            }
        }
    }

    close $infID

}


#-------------------------------------------
# - Compute the HIGHADDR based on BASEADDR 
# - Compute C_NUM_PORTS 
#-------------------------------------------
proc xps_ipconfig_accept {mhsinst} {

    # C_NUM_PORTS
    update_portno        $mhsinst

    # C_SDMA_CTRL_HIGHADDR
    update_sdma_ctrl_highaddr $mhsinst

    # C_MPMC_CTRL_HIGHADDR
    # The update of MPMC Control High address will be done when the base address is changed
    # The UI file will directly make the call

    # update_mpmc_ctrl_highaddr $mhsinst

}

# C_NUM_PORTS
# find the highest active port + 1
proc update_portno {mhsinst} {

    for {set x 7} {$x >= 0} {incr x -1} {

        set basetype [xget_hw_parameter_value $mhsinst "C_PIM${x}_BASETYPE"]

        if {$basetype != 0} {

            set parm_handle [xget_hw_parameter_handle $mhsinst "C_NUM_PORTS"]
            xset_hw_parameter_value $parm_handle [expr {$x + 1}]
            return
        }
    }

    xset_hw_parameter_value $parm_handle 0
}

proc compute_mem_size {mhsinst} {
    set dwidth   [xget_hw_parameter_value $mhsinst "C_MEM_DATA_WIDTH"]
    set bankbits [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_BANK_BITS"]
    set rowbits  [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_ROW_BITS"]
    set colbits  [xget_hw_parameter_value $mhsinst "C_MEM_PART_NUM_COL_BITS"]
    set dimmsno  [xget_hw_parameter_value $mhsinst "C_MEM_NUM_DIMMS"]
    set ranksno  [xget_hw_parameter_value $mhsinst "C_MEM_NUM_RANKS"]
    set exponent [expr {$bankbits + $rowbits + $colbits + $dimmsno + $ranksno - 2}]

    if {[string length $dwidth] == 0 || [string length $bankbits] == 0 
            || [string length $rowbits] == 0 || [string length $colbits] == 0 
            || [string length $dimmsno] == 0 || [string length $ranksno] == 0} {
        return 0
    }

    # this will give you the memory size in Bytes
    set m_size   [format "0x%08lx" [expr {wide(round(($dwidth/8.0)*(pow(2,$exponent))))}]]

    return $m_size
}

proc addresses_not_set {mhsinst bus} {
    set base [xget_hw_parameter_value $mhsinst "C_${bus}_BASEADDR"]
    set high [xget_hw_parameter_value $mhsinst "C_${bus}_HIGHADDR"]

    if {($high == 0x0) && ($base == 0xffffffff)} {
            return 1
    }

    if {[string equal $base ""]} {
            return 1
    }

    return 0
}

proc is_aligned { base size } {

        if {$base & ($size - 1)} {
                return 0;
        }
        return 1;
}

proc update_highaddr {mhsinst bus size} {

    set baseaddr 0
    if { [addresses_not_set $mhsinst $bus] } {
        set baseaddr 0
    } else {
        set baseaddr_str [xget_hw_parameter_value $mhsinst "C_${bus}_BASEADDR"]
        set baseaddr     [xformat_address_string  $baseaddr_str]
    }

    # check to see if we have alignment/overflow issues
    set overflow_error 0
    set aligned_error 0
    
    ## The and with 0xFFFFFFFF is required in order to ensure that we
    ## support 64 bit machines. The addresses dont wrap around on that.

    if {$baseaddr > (($baseaddr + $size - 1) & 0xffffffff )} {
        set baseaddr 0
        set overflow_error 1
    } elseif { ![is_aligned $baseaddr $size] } {
        set baseaddr 0
        set aligned_error 1
    }

    set highaddr [expr {$baseaddr + $size - 1}]

    # set C_BUS_HIGHADDR
    set high_handle [xget_hw_parameter_handle $mhsinst "C_${bus}_HIGHADDR"]
    xset_hw_parameter_value $high_handle [format "0x%08X" $highaddr]

    # set C_BUS_BASEADDR
    set base_handle [xget_hw_parameter_handle $mhsinst "C_${bus}_BASEADDR"]
    xset_hw_parameter_value $base_handle [format "0x%08X" $baseaddr]

    if { $overflow_error } {
        error "Auto-computed high address overflows the 32-bit address space. Setting C_${bus}_BASEADDR to 0x00000000." ""\
              "mdt_error"
    }

    if { $aligned_error } {
        error "Parameter changes affected the ${bus} base and high address of this memory system. The base address is not\
               aligned to the to the size of the bus '${size}' in an even power of 2. The C_${bus}_BASEADDR has been reset to 0x00000000." \
               "" "mdt_error"
    }
}


proc update_mpmc_highaddr {mhsinst} {
    # compute memory size from parameters in MHS
    set m_size   [compute_mem_size $mhsinst]

    # print out size in MB units in the GUI
    set msize_handle [xget_hw_parameter_handle $mhsinst "G_MEM_SIZE"]
    set convertor    [expr {int(pow(2,20))}]
    set final_val    [expr {$m_size/$convertor}]
    append           final_val "MB"
    xset_hw_parameter_value $msize_handle $final_val

    update_highaddr $mhsinst "MPMC" $m_size
}


# C_SDMA_CTRL_HIGHADDR = 64k (0x10000) + C_SDMA_CTRL_BASEADDR
proc update_sdma_ctrl_highaddr {mhsinst} {

    update_highaddr $mhsinst "SDMA_CTRL" 0x10000
}

# C_MPMC_CTRL_HIGHADDR = 64k (0x10000) + C_MPMC_CTRL_BASEADDR
proc update_mpmc_ctrl_highaddr {mhsinst} {

    update_highaddr $mhsinst "MPMC_CTRL" 0x10000
}

#-------------------------------------------
# Populates RZQ and ZIO pins with the possible locations
# Sets the RZQ and ZIO pins to the MHS values if  they exist
# -------------------------------------------
proc mpmc_init_rzq_zio_loc {mhsinst} { 
    set c_rzq_value [xget_hw_parameter_value $mhsinst "C_MCB_RZQ_LOC"]
    set c_zio_value [xget_hw_parameter_value $mhsinst "C_MCB_ZIO_LOC"]

    mpmc_populate_rzq_zio_loc $mhsinst

    set c_rzq_handle [xget_hw_parameter_handle $mhsinst "C_MCB_RZQ_LOC"]
    set c_zio_handle [xget_hw_parameter_handle $mhsinst "C_MCB_ZIO_LOC"]  
        
    if { $c_rzq_value != "" } {
        xset_hw_parameter_value $c_rzq_handle $c_rzq_value  
    }

    if { $c_zio_value != "" } {
        xset_hw_parameter_value $c_zio_handle $c_zio_value     
    }    
}
#-------------------------------------------
# Populate RZQ, ZIO gui params based on MCB location
# Sets those values to the recommended values
# Also shows the recommended vlaue in the labels
#-------------------------------------------

proc mpmc_populate_rzq_zio_loc {mhsinst} {             
    set c_rzq_handle [xget_hw_parameter_handle $mhsinst "C_MCB_RZQ_LOC"]
    set c_zio_handle [xget_hw_parameter_handle $mhsinst "C_MCB_ZIO_LOC"]     
      
    set rzq_values_list "NOT_SET=NOT_SET"
    set zio_values_list "NOT_SET=NOT_SET"
    
    #Reset the pins list and label
    xadd_hw_subproperty $c_rzq_handle "VALUES" "($rzq_values_list)"
    xadd_hw_subproperty $c_zio_handle "VALUES" "($zio_values_list)"   
#    xadd_hw_subproperty $c_rzq_handle "LABEL" "MCB RZQ Pin Location " 
#    xadd_hw_subproperty $c_zio_handle "LABEL" "MCB ZIO Pin Location "  

    if {[string match [xget_hw_parameter_value $mhsinst "C_MCB_LOC"] "NOT_SET"]} return 

    #Get the recommended pin values
    set rzq_recommended_pin  [gui_lookup_pin_location $mhsinst "rzq"]
    set zio_recommended_pin  [gui_lookup_pin_location $mhsinst "zio"]   
  
   
    #Get the pins list         
    set rzq_zio_pins_list [gui_get_list_of_rzq_zio_possible_pins $mhsinst]
    
    # Set list to blank
    set rzq_values_list ""
    set zio_values_list ""
    #Attach mpd default value to the list             
    foreach pin [lsort $rzq_zio_pins_list] {
        if {[string match $rzq_recommended_pin $pin] } { 
           # lappend rzq_values_list "$pin=$pin (Recommended)"
            set rzq_values_list [linsert $rzq_values_list 0 "$pin=$pin (Recommended)"]
        } else { 
            lappend rzq_values_list "$pin=$pin"
        }
        if {[string match $zio_recommended_pin $pin]} { 
            set zio_values_list [linsert $zio_values_list 0 "$pin=$pin (Recommended)"]
        } else { 
            lappend zio_values_list "$pin=$pin"
        }
    }               
    # Add not set to top of list
    set rzq_values_list [linsert $rzq_values_list 0 "NOT_SET=Not Set"]
    set zio_values_list [linsert $zio_values_list 0 "NOT_SET=Not Set"]
    
    #Populate the gui params with the pins list               
    xadd_hw_subproperty $c_rzq_handle "VALUES" "([join $rzq_values_list {,}])"     
    xadd_hw_subproperty $c_zio_handle "VALUES" "([join $zio_values_list {,}])" 

    
#    set rzq_label "MCB RZQ Pin Location (Recommended Pin = $rzq_recommended_pin)"   
#    set zio_label "MCB ZIO Pin Location (Recommended Pin = $zio_recommended_pin)"       
    
#    puts "List length [llength $rzq_zio_pins_list]"
#    #Show the recommended values if the list exists 
#    if {[llength $rzq_zio_pins_list] > 0} {   
        #xadd_hw_subproperty $c_rzq_handle "LABEL" $rzq_label  
        #xadd_hw_subproperty $c_zio_handle "LABEL" $zio_label    
        # 
        #xset_hw_parameter_value $c_rzq_handle $rzq_recommended_pin  
        #xset_hw_parameter_value $c_zio_handle $zio_recommended_pin     
#     }
}


#-------------------------------------------
# 1) Checks if RZQ and ZIO pins are set to the same location
# Returns an error if they are same
# 2) Checks if RZQ and ZIO are valid, if they are not valid locations return an error.
# -------------------------------------------
proc gui_drc_rzq_zio_loc {mhsinst} { 
    set c_rzq_value [xget_hw_parameter_value $mhsinst "C_MCB_RZQ_LOC"]
    set c_zio_value [xget_hw_parameter_value $mhsinst "C_MCB_ZIO_LOC"]  
    set list_possible_pins [ gui_get_list_of_rzq_zio_possible_pins $mhsinst ]
    set error_msg ""
    lappend list_possible_pins "NOT_SET"
        
    if {[string match "$c_rzq_value" "$c_zio_value"] && [string compare {NOT_SET} "$c_rzq_value"]} {
        set error_msg "RZQ and ZIO cannot have the same value \"$c_rzq_value\"."
    }   
    if { [lsearch -exact $list_possible_pins $c_rzq_value] == -1 } { 
        set error_msg "$error_msg The value \"$c_rzq_value\" of parameter C_MCB_RZQ_LOC is not a valid RZQ pin location.  Please select a valid value for C_MCB_RZQ_LOC using the MPMC IP Configurator."
    }
    if { [lsearch -exact $list_possible_pins $c_zio_value] == -1 } { 
        set error_msg "$error_msg  The value \"$c_zio_value\" of parameter C_MCB_ZIO_LOC is not a valid ZIO pin location.  Please select a valid value for C_MCB_ZIO_LOC using the MPMC IP Configurator."
    }
    if {[string length $error_msg] > 0} { 
        error $error_msg
    }

}

#-------------------------------------------
# if C_ALL_PIMS_SHARE_ADDRESSES = 0, then
#   - set C_PIMx_BASEADDR with C_MPMC_BASEADDR 
#   - set C_SDMA_CTRLx_BASEADDR with C_SDMA_CTRL_BASEADDR 
#-------------------------------------------
proc mpmc_copy_port_addr {mhsinst} {

    set share_addr [xget_hw_parameter_value $mhsinst "C_ALL_PIMS_SHARE_ADDRESSES"]

    if {$share_addr != 0 } {

        return 
    }

    set mpmc_baseaddr [xget_hw_parameter_value $mhsinst "C_MPMC_BASEADDR"]
    set mpmc_highaddr [xget_hw_parameter_value $mhsinst "C_MPMC_HIGHADDR"]
    
    set sdma_baseaddr [xget_hw_parameter_value $mhsinst "C_SDMA_CTRL_BASEADDR"]
    set sdma_highaddr [xget_hw_parameter_value $mhsinst "C_SDMA_CTRL_HIGHADDR"]

    for {set x 0} {$x < 8} {incr x 1} {
        
        set pim_basehandle  [xget_hw_parameter_handle $mhsinst "C_PIM${x}_BASEADDR"]
        set pim_highhandle  [xget_hw_parameter_handle $mhsinst "C_PIM${x}_HIGHADDR"]

        set sdma_basehandle [xget_hw_parameter_handle $mhsinst "C_SDMA_CTRL${x}_BASEADDR"]
        set sdma_highhandle [xget_hw_parameter_handle $mhsinst "C_SDMA_CTRL${x}_HIGHADDR"]
        xset_hw_parameter_value $pim_basehandle  $mpmc_baseaddr
        xset_hw_parameter_value $pim_highhandle  $mpmc_highaddr
        xset_hw_parameter_value $sdma_basehandle $sdma_baseaddr
        xset_hw_parameter_value $sdma_highhandle $sdma_highaddr

    }
}


#-------------------------------------------
# Left Justify
# Scan through all C_PIM*_BASETYPE parameters, 
# if there is any hole between active ports,
# then shift ports left to eliminate the holes.
#-------------------------------------------
proc mpmc_left_justify {mhsinst} {

    set last 0

    for {set index 0} {$index < 8 } {incr index 1} {

        set index_handle [xget_hw_parameter_handle $mhsinst C_PIM${index}_BASETYPE]
        set index_value  [xget_hw_value            $index_handle]

        if {$index_value != 0} {

            if {$last != $index} {

                set last_handle  [xget_hw_parameter_handle $mhsinst C_PIM${last}_BASETYPE]
                set last_value   [xget_hw_value            $last_handle]

                # swap C_PIM${index}_BASETYPE with C_PIM${last}_BASETYPE
                xset_hw_parameter_value  $index_handle $last_value
                xset_hw_parameter_value  $last_handle  $index_value

                # shift parameters
                shift_parameters $mhsinst $index $last 

                # shift external connectors
                shift_external_connectors $mhsinst $index $last 

            }
            incr last 1

        }
    }
}

# shift port specific paramters
proc shift_parameters {mhsinst index last} {

    swap_parameter_values $mhsinst "C_PIM" "_BASEADDR" $index $last
    swap_parameter_values $mhsinst "C_PIM" "_HIGHADDR" $index $last
    swap_parameter_values $mhsinst "C_PIM" "_OFFSET" $index $last
    swap_parameter_values $mhsinst "C_PIM" "_DATA_WIDTH" $index $last
    # basetype already updated, don't swap.
#    swap_parameter_values $mhsinst "C_PIM" "_BASETYPE" $index $last
    swap_parameter_values $mhsinst "C_PIM" "_SUBTYPE" $index $last
    swap_parameter_values $mhsinst "C_XCL" "_LINESIZE" $index $last
    swap_parameter_values $mhsinst "C_XCL" "_WRITEXFER" $index $last
    swap_parameter_values $mhsinst "C_XCL" "_PIPE_STAGES" $index $last
    swap_parameter_values $mhsinst "C_XCL" "_B_IN_USE" $index $last
    swap_parameter_values $mhsinst "C_PIM" "_B_SUBTYPE" $index $last
    swap_parameter_values $mhsinst "C_XCL" "_B_LINESIZE" $index $last
    swap_parameter_values $mhsinst "C_XCL" "_B_WRITEXFER" $index $last
    swap_parameter_values $mhsinst "C_SPLB" "_AWIDTH" $index $last
    swap_parameter_values $mhsinst "C_SPLB" "_DWIDTH" $index $last
    swap_parameter_values $mhsinst "C_SPLB" "_NATIVE_DWIDTH" $index $last
    swap_parameter_values $mhsinst "C_SPLB" "_NUM_MASTERS" $index $last
    swap_parameter_values $mhsinst "C_SPLB" "_MID_WIDTH" $index $last
    swap_parameter_values $mhsinst "C_SPLB" "_P2P" $index $last
    swap_parameter_values $mhsinst "C_SPLB" "_SUPPORT_BURSTS" $index $last
    swap_parameter_values $mhsinst "C_SPLB" "_SMALLEST_MASTER" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_BASEADDR" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_HIGHADDR" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_AWIDTH" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_DWIDTH" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_NATIVE_DWIDTH" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_NUM_MASTERS" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_MID_WIDTH" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_P2P" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_SUPPORT_BURSTS" $index $last
    swap_parameter_values $mhsinst "C_SDMA_CTRL" "_SMALLEST_MASTER" $index $last
    swap_parameter_values $mhsinst "C_SDMA" "_COMPLETED_ERR_TX" $index $last
    swap_parameter_values $mhsinst "C_SDMA" "_COMPLETED_ERR_RX" $index $last
    swap_parameter_values $mhsinst "C_SDMA" "_PRESCALAR" $index $last
    swap_parameter_values $mhsinst "C_SDMA" "_PI2LL_CLK_RATIO" $index $last
    swap_parameter_values $mhsinst "C_PPC440MC" "_BURST_LENGTH" $index $last
    swap_parameter_values $mhsinst "C_PPC440MC" "_PIPE_STAGES" $index $last
    swap_parameter_values $mhsinst "C_VFBC" "_CMD_FIFO_DEPTH" $index $last
    swap_parameter_values $mhsinst "C_VFBC" "_CMD_AFULL_COUNT" $index $last
    swap_parameter_values $mhsinst "C_VFBC" "_RDWD_DATA_WIDTH" $index $last
    swap_parameter_values $mhsinst "C_VFBC" "_RDWD_FIFO_DEPTH" $index $last
    swap_parameter_values $mhsinst "C_VFBC" "_RD_AEMPTY_WD_AFULL_COUNT" $index $last
    swap_parameter_values $mhsinst "C_PI" "_RD_FIFO_TYPE" $index $last
    swap_parameter_values $mhsinst "C_PI" "_WR_FIFO_TYPE" $index $last
    swap_parameter_values $mhsinst "C_PI" "_ADDRACK_PIPELINE" $index $last
    swap_parameter_values $mhsinst "C_PI" "_RD_FIFO_APP_PIPELINE" $index $last
    swap_parameter_values $mhsinst "C_PI" "_RD_FIFO_MEM_PIPELINE" $index $last
    swap_parameter_values $mhsinst "C_PI" "_WR_FIFO_APP_PIPELINE" $index $last
    swap_parameter_values $mhsinst "C_PI" "_WR_FIFO_MEM_PIPELINE" $index $last
    swap_parameter_values $mhsinst "C_PI" "_PM_USED" $index $last
    swap_parameter_values $mhsinst "C_PI" "_PM_DC_CNTR" $index $last

}

# shift port specific external connectors
# XCLx, SPLBx, SDMA_CTRLx, SDMA_LLx, MPMC_PIMx, PPC440MCx, VFBCx
proc shift_external_connectors {mhsinst index last} {

    swap_connectors $mhsinst "XCL"       $index $last
    swap_connectors $mhsinst "XCL"       "${index}_B" "${last}_B"
    swap_connectors $mhsinst "SPLB"      $index $last
    swap_connectors $mhsinst "SDMA_CTRL" $index $last
    swap_connectors $mhsinst "SDMA_LL"   $index $last
    swap_connectors $mhsinst "MPMC_PIM"  $index $last
    swap_connectors $mhsinst "PPC440MC"  $index $last
    swap_connectors $mhsinst "VFBC"      $index $last
    swap_port_values $mhsinst "SDMA" "_Clk" $index $last
    swap_port_values $mhsinst "SDMA" "_Rx_IntOut" $index $last
    swap_port_values $mhsinst "SDMA" "_Tx_IntOut" $index $last


}


proc swap_connectors {mhsinst bus index last} {

    set last_bus_connector  [xget_hw_busif_value $mhsinst $bus$last]
    set index_bus_connector [xget_hw_busif_value $mhsinst $bus$index]

    xadd_hw_ipinst_busif    $mhsinst $bus$index  "No Connection"
    xadd_hw_ipinst_busif    $mhsinst $bus$last   $index_bus_connector

}

proc swap_parameter_values {mhsinst head tail index last} {

    set last_name    $head$last$tail
    set last_handle  [xget_hw_parameter_handle $mhsinst $last_name]
    set last_value   [xget_hw_value            $last_handle]

    set index_name   $head$index$tail
    set index_handle [xget_hw_parameter_handle $mhsinst $index_name]
    set index_value  [xget_hw_value            $index_handle]

    xset_hw_parameter_value  $index_handle $last_value
    xset_hw_parameter_value  $last_handle  $index_value

}

proc swap_port_values {mhsinst head tail index last} {

    set last_name    $head$last$tail
    set index_name   $head$index$tail

    set last_handle  [xget_hw_port_handle $mhsinst $last_name]
    set last_value   [xget_hw_port_value  $mhsinst $last_name]

    set index_handle [xget_hw_port_handle $mhsinst $index_name]
    set index_value  [xget_hw_port_value  $mhsinst $index_name]

    if {[string length $last_value] == 0} {
        set $last_value "No Connection"
    } 

    if {[string length $index_value] == 0} {
        set $index_value "No Connection"
    } 
    xset_hw_port_value  $index_handle "$last_value"
    xset_hw_port_value  $last_handle  "$index_value"
}

#-------------------------------------------
# Restore following parameters to their default value 
#-------------------------------------------

proc mpmc_restore_default_addr {mhsinst} {

    restore_param_default [xget_hw_parameter_handle  $mhsinst "C_MPMC_BASEADDR"]
    restore_param_default [xget_hw_parameter_handle  $mhsinst "C_SDMA_CTRL_BASEADDR"]
    restore_param_default [xget_hw_parameter_handle  $mhsinst "C_ALL_PIMS_SHARE_ADDRESSES"]

}

proc mpmc_restore_default_datapath {mhsinst} {

    for {set x 0} {$x < 8 } {incr x 1} {
        restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PIM${x}_DATA_WIDTH"]
    }

    for {set x 0} {$x < 8 } {incr x 1} {
 
        restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PI${x}_RD_FIFO_TYPE"]
    }

    for {set x 0} {$x < 8 } {incr x 1} {
 
        restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PI${x}_WR_FIFO_TYPE"]
    }

    for {set x 0} {$x < 8 } {incr x 1} {
 
        restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PI${x}_RD_FIFO_MEM_PIPELINE"]
    }

    for {set x 0} {$x < 8 } {incr x 1} {
 
        restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PI${x}_RD_FIFO_APP_PIPELINE"]
    }

    for {set x 0} {$x < 8 } {incr x 1} {
 
        restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PI${x}_WR_FIFO_MEM_PIPELINE"]
    }

    for {set x 0} {$x < 8 } {incr x 1} {
 
        restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PI${x}_WR_FIFO_APP_PIPELINE"]
    }

    for {set x 0} {$x < 8 } {incr x 1} {
 
        restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PI${x}_ADDRACK_PIPELINE"]
    }

}

proc mpmc_restore_default_arb {mhsinst} {

    restore_param_default [xget_hw_parameter_handle  $mhsinst "C_ARB0_ALGO"]
    restore_param_default [xget_hw_parameter_handle  $mhsinst "C_ARB_PIPELINE"]
    mpmc_update_arbitration  $mhsinst

}


proc mpmc_restore_default_debug {mhsinst} {

    restore_param_default [xget_hw_parameter_handle  $mhsinst "C_PM_ENABLE"]
    restore_param_default [xget_hw_parameter_handle  $mhsinst "C_INCLUDE_ECC_SUPPORT"]
    restore_param_default [xget_hw_parameter_handle  $mhsinst "C_DEBUG_REG_ENABLE"]

}

proc restore_param_default {param_handle} {

    set param_default [xget_hw_subproperty_value $param_handle "MPD_VALUE"]
    xset_hw_parameter_value  $param_handle $param_default

}


####
#
# load_memory_parameters
#
# Loads all memory parameters from the database. It does call INIT to
# check if the database is initialized or not
#
# Called by : XPS GUI Only. No backend (platgen or DRC call)
# 
###

proc load_memory_parameters {mhsinst forceOverwrite} {

    global array_partno_param
    global array_partnolist

    init_memory $mhsinst
    
    set partno [string toupper [xget_hw_parameter_value  $mhsinst "C_MEM_PARTNO"]]

    # MIG database workaround, remove first 5 characters (MPMC-)
    if { [string match -nocase {mpmc-*} $partno] } {
        set partno [string range $partno 5 end]
    }
    
    if { [string match -nocase {CUSTOM} $partno] ||  [string match -nocase {NONE} $partno]  } {

        # Update the memory type so that all paramters that are dependent get their ranges correct.
        set mem_type      [string toupper [xget_hw_parameter_value  $mhsinst "G_MEM_TYPE"]]
        set param_handle  [xget_hw_parameter_handle $mhsinst "C_MEM_TYPE"]
        xset_hw_parameter_value $param_handle $mem_type
        
        return
    } 

    set list   [array get array_partno_param $partno,*]


    foreach {key value}  $list {

        set param  [lindex [split $key ,] 1]
        if { ![string match -nocase C_MEM_PART_CAS_?_TMIN $param] && [string match -nocase C_MEM* $param] } {

            set param_handle [xget_hw_parameter_handle  $mhsinst $param]
            set mhs_value    [xget_hw_subproperty_value $param_handle "MHS_VALUE"]

            if { $forceOverwrite == 1 || [string length $mhs_value] == 0 } {
                xset_hw_parameter_value  $param_handle $value
            }
        }
    }

    # update VALUES tag to G_MEM_TYPE
    set list [array get array_partnolist $partno,*,*,*,*,*]
    set key  [lindex $list 0]
    set type [lindex [split $key ,] 2]

    set param_handle [xget_hw_parameter_handle $mhsinst "C_MEM_TYPE"]
    xset_hw_parameter_value $param_handle $type

}


proc mpmc_launch_mig {mhsinst} { 

    run_mig $mhsinst "gui" "interactive"
}

#-------------------------------------------
# called by MPMC Gui before gui is up
#-------------------------------------------
proc xps_ipconfig_init {mhsinst} {

    gui_init                     $mhsinst
    update_memory_parameters     $mhsinst
    filter_partno                $mhsinst 
    mpmc_update_arbitration      $mhsinst
    gui_update_mem_dynamic_param $mhsinst
    mpmc_init_rzq_zio_loc        $mhsinst   
}

proc gui_init {mhsinst} {
    set family              [ xget_hw_parameter_value  $mhsinst "C_BASEFAMILY"     ] 
    set subfamily           [ xget_hw_parameter_value  $mhsinst "C_SUBFAMILY"  ] 
    set g_is_s6_handle      [ xget_hw_parameter_handle $mhsinst "G_IS_S6"      ] 
    set g_is_s6_bool_handle [ xget_hw_parameter_handle $mhsinst "G_IS_S6_BOOL" ] 
    set g_is_v6_bool_handle [ xget_hw_parameter_handle $mhsinst "G_IS_V6_BOOL" ]  


    set c_port_config_handle [xget_hw_parameter_handle $mhsinst "C_PORT_CONFIG"]
    if { [string match -nocase {spartan6} $family] } {
        xset_hw_parameter_value $g_is_s6_handle "1"
        xset_hw_parameter_value $g_is_s6_bool_handle "1"
        mpmc_enable_ports $mhsinst [xget_hw_value $c_port_config_handle] "0"
    } elseif { [string match -nocase {virtex6} $family] } {
        xset_hw_parameter_value $g_is_v6_bool_handle "1"
    } else {
        xset_hw_parameter_value $g_is_s6_handle "0"
        xset_hw_parameter_value $g_is_s6_bool_handle "0"
        xset_hw_parameter_value $g_is_v6_bool_handle "0"
    }

    for {set x 0} {$x < 8} {incr x 1} {
        set param_name "C_PIM${x}_BASETYPE"
        set param_handle    [xget_hw_parameter_handle $mhsinst $param_name]

        if { [string match -nocase {virtex5} $family] && \
                   [string match -nocase {fx} $subfamily] } {
        } elseif { [string match -nocase {spartan6} $family]} {
            #xadd_hw_subproperty $param_handle "VALUES" \
            #    "(0=INACTIVE, 1=XCL, 2=PLBV46, 3=SDMA, 4=NPI, 5=PPC440MC-NA, 6=VFBC, 7=MCB)"
        } else {
            xadd_hw_subproperty $param_handle "VALUES" \
                "(0=INACTIVE, 1=XCL, 2=PLBV46, 3=SDMA, 4=NPI, 5=PPC440MC-NA, 6=VFBC, 7=MCB-NA)"
        }
    }
}
#-------------------------------------------
# given C_MEM_PARTNO and                
# update all memory path parameters  
# Only called by XPS GUI
#-------------------------------------------
proc update_memory_parameters {mhsinst} {

    set param_handle [xget_hw_parameter_handle $mhsinst "C_MEM_PARTNO"]
    set g_value      [xget_hw_parameter_value  $mhsinst "G_MEM_PARTNO"]
    set c_value      [xget_hw_parameter_value  $mhsinst "C_MEM_PARTNO"]
    set partno       [string toupper $g_value]

    if { [string compare -nocase $partno "Select a part"] == 0} {
        return
    }

    set forceOverwrite 0
    if { [string match -nocase {CUSTOM} $g_value] == 0 &&
         [string match -nocase {CUSTOM} $c_value] } {
        set forceOverwrite 1
    }
    
    #--------------------------------------------
    #
    # The value from G_MEM_PARTNO should not be set in the C_MEM_PARTNO during the init phase
    # The value of C_MEM_TYPE is also set into the filter at init stage
    #
    #--------------------------------------------

    if { [string match -nocase {NONE} $g_value] } {
        ## Copy the C_MEM_TYPE to G_MEM_TYPE during INIT Phase
        set c_mem_type_value  [xget_hw_parameter_value $mhsinst "C_MEM_TYPE"]
        set g_mem_type_handle [xget_hw_parameter_handle $mhsinst "G_MEM_TYPE"]
        xset_hw_parameter_value $g_mem_type_handle $c_mem_type_value
    } else {
        ## During INIT, do not copy the G_MEM_PARTNO to C_MEM_PARTNO
        xset_hw_parameter_value $param_handle $partno

    }


    # if Memory part has changed, output a notice message.
    if { [string match -nocase {NONE} $g_value] == 0} {
        puts "INFO: Please remember to update your CE, ODT, Clock, and CSn widths to match your pin layout on your board configuration."
    }

    load_memory_parameters $mhsinst $forceOverwrite
    update_mpmc_highaddr $mhsinst

    # Update paramter comboboxe that are depending on mem_type.
    gui_update_mem_dynamic_param $mhsinst
}

proc mpmc_update_arbitration {mhsinst} {
    set algo [xget_hw_parameter_value $mhsinst "C_ARB0_ALGO"]
    set portno [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]
    set numslots [xget_hw_parameter_handle $mhsinst "C_ARB0_NUM_SLOTS"]
    set family     [xget_hw_parameter_value $mhsinst "C_BASEFAMILY"]

    if { [string match -nocase {ROUND_ROBIN} $algo] } {
        xset_hw_parameter_value $numslots $portno
        for {set x 0} {$x<16} {incr x 1} {
            set param_name "C_ARB0_SLOT$x"
            set param_handle [xget_hw_parameter_handle $mhsinst $param_name]
            xset_hw_parameter_value $param_handle [mpmc_generate_arbitration_string $portno $x]
        }
    } elseif { [string match -nocase {FIXED} $algo] } {
        xset_hw_parameter_value $numslots 1
        set param_handle [xget_hw_parameter_handle $mhsinst "C_ARB0_SLOT0"]
        xset_hw_parameter_value $param_handle [mpmc_generate_arbitration_string $portno 0]
        for {set x 1} {$x<16} {incr x 1} {
            set param_name "C_ARB0_SLOT$x"
            set param_handle [xget_hw_parameter_handle $mhsinst $param_name]
            xset_hw_parameter_value $param_handle ""
        }
    } elseif { [string match -nocase {spartan6} $family] && [string match -nocase {CUSTOM} $algo] } {
        set param_handle [xget_hw_parameter_handle $mhsinst "C_ARB0_NUM_SLOTS"]
        xadd_hw_subproperty $param_handle "VALUES" "(10=10,12=12)"
        xset_hw_parameter_value $param_handle "10"
    }
}

proc mpmc_update_gui_port {mhsinst} {
    set c_port_config [xget_hw_parameter_value $mhsinst "C_PORT_CONFIG"]
    mpmc_enable_ports $mhsinst $c_port_config "0"
}

proc mpmc_enable_ports {mhsinst c_port_config forceInactive} {
    set max_port [list "6" "4" "3" "2" "1"]
    set config4 [list "0=INACTIVE,7=MCB"]
    set config3 [list "0=INACTIVE,2=PLBV46,4=NPI,6=VFBC,7=MCB" "0=INACTIVE,2=PLBV46,4=NPI,6=VFBC,7=MCB"]
    set config2 [list "0=INACTIVE,2=PLBV46,4=NPI,6=VFBC,7=MCB" "0=INACTIVE,1=XCL,2=PLBV46,3=SDMA,4=NPI,6=VFBC,7=MCB" "0=INACTIVE,1=XCL,2=PLBV46,3=SDMA,4=NPI,6=VFBC,7=MCB"]
    set config1 [list "0=INACTIVE,1=XCL,2=PLBV46,3=SDMA,4=NPI,6=VFBC,7=MCB" "0=INACTIVE,1=XCL,2=PLBV46,3=SDMA,4=NPI,6=VFBC,7=MCB" "0=INACTIVE,1=XCL,2=PLBV46,3=SDMA,4=NPI,6=VFBC,7=MCB" "0=INACTIVE,1=XCL,2=PLBV46,3=SDMA,4=NPI,6=VFBC,7=MCB"]
    set config0 [list "0=INACTIVE,1=XCL,2=PLBV46,3=SDMA,4=NPI,6=VFBC,7=MCB" "0=INACTIVE,1=XCL,2=PLBV46,3=SDMA,4=NPI,6=VFBC,7=MCB" "0=INACTIVE,8=MCB-Read,9=MCB-Write" "0=INACTIVE,8=MCB-Read,9=MCB-Write" "0=INACTIVE,8=MCB-Read,9=MCB-Write" "0=INACTIVE,8=MCB-Read,9=MCB-Write"]
    set config_map [list $config0 $config1 $config2 $config3 $config4]

    #set c_num_ports_handle [xget_hw_parameter_handle $mhsinst "C_NUM_PORTS"]
    #xset_hw_parameter_value ${c_num_ports_handle} [lindex $max_port $c_port_config]

    for {set x 0} {$x < 8} {incr x 1} {
        set g_pim_handle [xget_hw_parameter_handle $mhsinst "G_PIM${x}"]
        set c_pim_basetype_handle [xget_hw_parameter_handle $mhsinst "C_PIM${x}_BASETYPE"]

        if { $x >= [lindex $max_port $c_port_config] } {
            xset_hw_parameter_value $g_pim_handle "0"
            xset_hw_parameter_value $c_pim_basetype_handle "0"
            continue
        } else {
            xset_hw_parameter_value $g_pim_handle "1"
            if { [ string match -nocase $forceInactive "1"] } {
                xset_hw_parameter_value $c_pim_basetype_handle "0"
            }
        }

        set values [lindex [lindex $config_map $c_port_config] $x]
        xadd_hw_subproperty $c_pim_basetype_handle "VALUES" "(${values})"
    }

    # Update splb native dwidths
    for {set x 0} {$x < 8} {incr x 1} { 
        set splb_handle [xget_hw_parameter_handle $mhsinst "C_SPLB${x}_NATIVE_DWIDTH"]
        set splb_value  [iplevel_update_splb_native_dwidth $splb_handle]
        xset_hw_parameter_value $splb_handle $splb_value
    }
}

proc mpmc_generate_arbitration_string {number start} {
    set listDigit ""
    if { $start < $number } {
        for {set x 0} {$x < $number} {incr x 1} {
            set digit [ expr {$x + $start} ]
            if { $digit >= $number } {
                set digit [ expr {$digit - $number} ]
            } 
                append listDigit $digit
        }
    }
    return $listDigit
}

proc gui_update_mem_dynamic_param {mhsinst} {
    gui_update_mem_odt_type     $mhsinst
    gui_update_mem_reduced_drv  $mhsinst
    gui_update_mem_twtr         $mhsinst
    gui_update_mem_width        $mhsinst
    gui_update_fifo_datapath    $mhsinst
}

proc gui_update_mem_odt_type {mhsinst} {
  
    set mem_type      [xget_hw_parameter_value  $mhsinst "C_MEM_TYPE"]
    set param_handle  [xget_hw_parameter_handle $mhsinst "C_MEM_ODT_TYPE"]
    
    if { [string match -nocase {ddr3} $mem_type] } {
        xadd_hw_subproperty $param_handle "VALUES" \
            "(0= Disabled , 1= RZQ/4 , 2= RZQ/2 , 3= RZQ/6, 4= RZQ/12, 5= RZQ/8)"
    } elseif { [string match -nocase {ddr2} $mem_type] } {
        xadd_hw_subproperty $param_handle "VALUES" \
            "(0= Disabled , 1= 75 Ohm , 2= 150 Ohm , 3= Reseved/50 Ohm)"
    }
}

proc gui_update_fifo_datapath {mhsinst} {
  
    set family        [xget_hw_parameter_value  $mhsinst "C_BASEFAMILY"]
    
    if {[string match -nocase {spartan6*} $family]} { 
        for {set i 0} {$i < 8} {incr i 1} {
            set param_handle  [xget_hw_parameter_handle $mhsinst "C_PI${i}_RD_FIFO_TYPE"]
            xadd_hw_subproperty $param_handle "VALUES" "(BRAM= ENABLED, DISABLED= DISABLED)"

            set param_handle  [xget_hw_parameter_handle $mhsinst "C_PI${i}_WR_FIFO_TYPE"]
            xadd_hw_subproperty $param_handle "VALUES" "(BRAM= ENABLED, DISABLED= DISABLED)"
        }
    }
}

proc gui_update_mem_reduced_drv {mhsinst} {
  
    set mem_type      [xget_hw_parameter_value  $mhsinst "C_MEM_TYPE"]
    set param_handle  [xget_hw_parameter_handle $mhsinst "C_MEM_REDUCED_DRV"]

    if { [string match -nocase {ddr3} $mem_type] } {
        xadd_hw_subproperty $param_handle "VALUES" \
            "(0= RZQ/6, 1= RZQ/7)"
    } elseif { [string match -nocase {lpddr} $mem_type] } {
        xadd_hw_subproperty $param_handle "VALUES" \
            "(0= FULL, 1= HALF, 2= QUARTER, 3= THREEQUARTERS)"
    } else {
        xadd_hw_subproperty $param_handle "VALUES" \
            "(0= FULL, 1= REDUCED)"
    }
}

proc gui_update_mem_twtr {mhsinst} {
  
    set mem_type      [xget_hw_parameter_value  $mhsinst "C_MEM_TYPE"]
    set param_handle  [xget_hw_parameter_handle $mhsinst "G_SET_SELECT_TWTR"]

    if { [string match -nocase {lpddr} $mem_type] } {
        xset_hw_parameter_value $param_handle "1"
    } else {
        xset_hw_parameter_value $param_handle "0"
    }
}

proc gui_update_mem_width {mhsinst} {

    set mem_type        [xget_hw_parameter_value  $mhsinst "C_MEM_TYPE"]
    set family          [xget_hw_parameter_value  $mhsinst "C_BASEFAMILY"]
    # Update C_MEM_DATA_WIDTH values
    set valid_data_widths_list [get_list_valid_mem_widths $mhsinst $family]
    set mem_width_values_list ""
    foreach data_width $valid_data_widths_list {
        lappend mem_width_values_list "$data_width=$data_width"
    }
    set mem_dwidth_handle [xget_hw_parameter_handle $mhsinst "C_MEM_DATA_WIDTH"]
    xadd_hw_subproperty $mem_dwidth_handle "VALUES" "([join $mem_width_values_list {,}])"
}

# Returns list of valid memory types for the given family
proc get_list_valid_mem_types { family } { 

    switch -glob -- $family {
        spartan3*   -
        virtex4     -
        virtex5     { return [list         "SDRAM" "DDR" "DDR2"       ] }
        spartan6    { return [list "LPDDR"         "DDR" "DDR2" "DDR3"] }
        virtex6     { return [list                       "DDR2" "DDR3"] }
        default     { return [list "LPDDR" "SDRAM" "DDR" "DDR2" "DDR3"] }
    }
}

# Returns list of valid memory widths for the given family
proc get_list_valid_mem_widths { mhsinst family } { 

    switch -glob -- $family {
        spartan3*   -
        virtex4     -
        virtex5     { return [list   8 16 32 64] }
        spartan6    { return [list 4 8 16      ] }
        virtex6     { return [list   8 16 32   ] }
        default     { return [list 4 8 16 32 64] }
    }
}

#-------------------------------------------
# Return back the first valid C_PIx_WR_FIFO_MEM_PIPELINE value.  This assumes 
# all ports must have the same value set.
#-------------------------------------------
proc get_wr_fifo_mem_pipeline { mhsinst } {

    set portno      [xget_hw_parameter_value $mhsinst "C_NUM_PORTS"]

    for {set i 0} {$i < $portno} {incr i 1} {

        set wr   [xget_hw_parameter_value $mhsinst "C_PI${i}_WR_FIFO_TYPE"]
        if {[string match -nocase {DISABLED} $wr] == 0} { 
            return [xget_hw_parameter_value $mhsinst "C_PI${i}_WR_FIFO_MEM_PIPELINE"]
        }
    }
    return 1
}

# Convert MPMC MEM Type nomenclature to MIG MEM Type nomenclature
proc convert_mpmc_to_mig_mem_type { mpmc_mem_type } {
    switch -exact -- [string toupper $mpmc_mem_type] {
        DDR     { return "DDR_SDRAM" }
        DDR2    { return "DDR2_SDRAM" }
        DDR3    { return "DDR3_SDRAM" }
        LPDDR   { return "LPDDR" }
        default { return $mpmc_mem_type }
    }
}

# Convert MIG MEM Type nomenclature to MPMC MEM Type nomenclature
proc convert_mig_to_mpmc_mem_type { mig_mem_type } {
    switch -exact -- [string toupper $mig_mem_type] {
        DDR_SDRAM   { return "DDR"          }
        DDR2_SDRAM  { return "DDR2"         }
        DDR3_SDRAM  { return "DDR3"         }
        LPDDR       { return "LPDDR"        }
        default     { return $mig_mem_type  }
    }
}

# Convert MPMC MEM Type nomenclature to MIG MEM Type nomenclature
proc convert_list_mpmc_to_mig_mem_type { list_mpmc_mem_type } {
    foreach mem_type $list_mpmc_mem_type {
        lappend list_mig_mem_type [convert_mpmc_to_mig_mem_type $mem_type]
    }
    return $list_mig_mem_type
}

# Convert mig mem type nomenclature to mpmc mem type nomenclature
proc convert_list_mig_to_mpmc_mem_type { list_mig_mem_type } {
    foreach mem_type $list_mig_mem_type {
        lappend list_mpmc_mem_type [convert_mig_to_mpmc_mem_type $mem_type]
    }
    return $list_mpmc_mem_type
}

# Returns MIG version in <Major Ver>_<Minor_Ver> format.
# Spartan-6/Virtex-6 families use 3_7, older families use 3_61
proc get_mig_version { } {
    global array_partno_family
    switch -exact -- [string tolower $array_partno_family] {
        virtex6     -
        spartan6    { return "3_7"         } 
        default     { return "3_61"         }
    }
}

# Finds and returns the mig executable.
proc get_mig_executable { } { 

    set host_os [xget_hostos_platform]
    set host_exec_suffix [xget_hostos_exec_suffix]
    set mig_ver [get_mig_version]
    set relative_mig_path "coregen/ip/xilinx/other/com/xilinx/ip/mig_v${mig_ver}/bin/${host_os}/mig"
    if {[string length $host_exec_suffix]} { 
        append relative_mig_path ".${host_exec_suffix}"
    }

    set mig_exec [xfind_file_in_xilinx_install $relative_mig_path]
    if {[file exists $mig_exec] == 0 || [file executable $mig_exec] == 0} { 
        error "The MIG executable does not exist or is not executable.  Please check that the relative path: '${relative_mig_path}' is in your\
               \$XILINX environment variable." "" "mdt_error"
    }
    return [file join $mig_exec]
}

# Finds and returns the path of to the mig memory database.
proc get_mig_memory_database { db_name } { 

    set mig_ver [get_mig_version]
    set relative_mig_path "coregen/ip/xilinx/other/com/xilinx/ip/mig_v${mig_ver}/data/mem_tlib/${db_name}"
    set mig_db [xfind_file_in_xilinx_install $relative_mig_path]
    
    if {[file exists $mig_db] == 0 || [file readable $mig_db] == 0} { 
        error "The MIG database does not exist.  Please check that the relative path: '${relative_mig_path}' is in your\
               \$XILINX environment variable." "" "mdt_error"
    }
    
    return [file join $mig_db]
}

# Finds and returns the path to the mig fpga database
proc get_mig_fpga_database { db_name } { 

    set mig_ver [get_mig_version]
    set relative_mig_path "coregen/ip/xilinx/other/com/xilinx/ip/mig_v${mig_ver}/data/fpga_tlib/${db_name}"
    set mig_db [xfind_file_in_xilinx_install $relative_mig_path]

    if {[file exists $mig_db] == 0 || [file readable $mig_db] == 0} { 
        error "The MIG database does not exist.  Please check that the relative path: '${relative_mig_path}' is in your\
               \$XILINX environment variable." "" "mdt_error"
    }
    
    return [file join $mig_db]
}

# Finds and returns the path to the mig fpga database
proc get_mig_fpga_database_v3_4 { db_name } { 

    set mig_ver "3_4"
    set relative_mig_path "coregen/ip/xilinx/other/com/xilinx/ip/mig_v${mig_ver}/data/fpga_tlib/${db_name}"
    set mig_db [xfind_file_in_xilinx_install $relative_mig_path]

    if {[file exists $mig_db] == 0 || [file readable $mig_db] == 0} { 
        return ""
    }
    
    return [file join $mig_db]
}

######################################################################
#
# Arrays required for storing values & data
#
######################################################################
array set array_mpmcinst  ""

#-----------------------------------
# array_ctrl_param:   
# (key  value) = ($param_name   $param_value)
#-----------------------------------
array set array_ctrl_param   ""

#-----------------------------------
# array_partno_family: 
#  Set to the selected architecture when database was loaded
#-----------------------------------
set array_partno_family ""

#-----------------------------------
# array_partno_clk_period: 
#  Set to the period time when database was loaded
#-----------------------------------
set array_partno_clk_period ""

#-----------------------------------
# array_partno_param: 
# (key  value) = ($partno_value,$param_value $param_value)
#-----------------------------------
array set array_partno_param ""

#-----------------------------------
# array_partnolist:   
# (key  value) = ($partno,$Style,$Type,$Density,
#                 $Part_Width,$Manufacturer       $partno )
#-----------------------------------
array set array_partnolist   ""

#-----------------------------------
# array_partnolist:   
# (key  value) = ($G_Filter_Name,$G_Filter_Value,$mem_type $G_Filter_Value)
#-----------------------------------
array set array_partno_filter  ""
