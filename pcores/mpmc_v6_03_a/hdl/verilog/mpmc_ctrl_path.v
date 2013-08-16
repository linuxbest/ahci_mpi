//-----------------------------------------------------------------------------
//-- (c) Copyright 2006 - 2009 Xilinx, Inc. All rights reserved.
//--
//-- This file contains confidential and proprietary information
//-- of Xilinx, Inc. and is protected under U.S. and
//-- international copyright and other intellectual property
//-- laws.
//--
//-- DISCLAIMER
//-- This disclaimer is not a license and does not grant any
//-- rights to the materials distributed herewith. Except as
//-- otherwise provided in a valid license issued to you by
//-- Xilinx, and to the maximum extent permitted by applicable
//-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//-- (2) Xilinx shall not be liable (whether in contract or tort,
//-- including negligence, or under any other theory of
//-- liability) for any loss or damage of any kind or nature
//-- related to, arising under or in connection with these
//-- materials, including for any direct, or any indirect,
//-- special, incidental, or consequential loss or damage
//-- (including loss of data, profits, goodwill, or any type of
//-- loss or damage suffered as a result of any action brought
//-- by a third party) even if such damage or loss was
//-- reasonably foreseeable or Xilinx had been advised of the
//-- possibility of the same.
//--
//-- CRITICAL APPLICATIONS
//-- Xilinx products are not designed or intended to be fail-
//-- safe, or for use in any application requiring fail-safe
//-- performance, such as life-support or safety devices or
//-- systems, Class III medical devices, nuclear facilities,
//-- applications related to the deployment of airbags, or any
//-- other applications that could lead to death, personal
//-- injury, or severe property or environmental damage
//-- (individually and collectively, "Critical
//-- Applications"). Customer assumes the sole risk and
//-- liability of any use of Xilinx products in Critical
//-- Applications, subject only to applicable laws and
//-- regulations governing limitations on product liability.
//--
//-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//-- PART OF THIS FILE AT ALL TIMES.
//-----------------------------------------------------------------------------
//
// Description: Control Path and Arbiter for MPMC.
//   
//--------------------------------------------------------------------------
//
// Structure:
//   mpmc_ctrl_path
//     ctrl_path
//     arbiter
//       arb_acknowledge
//       arb_bram_addr
//       arb_pattern_start
//         arb_req_pending_muxes
//         high_priority_select
//       arb_which_port
//         arb_req_pending_muxes
//         high_priority_select
//       arb_pattern_type
//         arb_pattern_type_muxes
//         arb_pattern_type_fifo
//         high_priority_select
//           mpmc_ctrl_path_fifo (currently used, better for output timing)
//           fifo_4 (not used, better for area)
//             fifo_32_rdcntr
//
//--------------------------------------------------------------------------
// History:
//
//--------------------------------------------------------------------------

`timescale 1ns/1ns
`default_nettype none

module mpmc_ctrl_path
#(
  parameter C_FAMILY           = "virtex4",
  parameter C_USE_MIG_S3_PHY   = 0,
  parameter C_USE_MIG_V4_PHY   = 0,
  parameter C_USE_MIG_V5_PHY   = 0,
  parameter C_USE_MIG_V6_PHY   = 0,
  parameter C_USE_STATIC_PHY   = 0,
  parameter C_USE_INIT_PUSH    = 0,
  parameter C_MEM_TYPE         = "INVALID",
  parameter C_MEM_CAS_LATENCY = 0,
  parameter C_ECC_ENCODE_PIPELINE  = 1'b1,
  parameter C_INCLUDE_ECC_SUPPORT = 0,
  parameter C_MEM_DDR2_ENABLE  = 1,
  parameter C_NUM_PORTS        = 8,       // Allowed Values: 1-8
  parameter C_NUM_CTRL_SIGNALS = 36,      // Allowed Values: 1-36
  parameter C_PIPELINE_ADDRACK = 8'h00,   // Allowed Values: 8'h00-8'hFF, each
                                          // bit corresponds to an individual 
                                          // port.
  parameter C_CP_PIPELINE = 1,            // Allowed Values: 0-1
  parameter C_ARB_PIPELINE = 1,           // Allowed Values: 0-1
  parameter C_MAX_REQ_ALLOWED  = 1,       // Allowed Values: Any integer
  parameter C_REQ_PENDING_CNTR_WIDTH = 2, // Allowed Values: Such that 
                                          // counter does not overflow 
                                          // when max pending 
                                          // instructions are 
                                          // acknowledged
  parameter C_REFRESH_CNT_MAX = 1560,     // Allowed Values: Any interger
  parameter C_REFRESH_CNT_WIDTH = 11,     // Allowed Values: Large enough to support C_REFRESH_CNT_MAX
  parameter C_MAINT_PRESCALER_DIV             = 0,
  parameter C_REFRESH_TIMER_DIV               = 0,
  parameter C_PERIODIC_RD_TIMER_DIV           = 0,
  parameter C_MAINT_PRESCALER_PERIOD_NS       = 0,
  parameter C_ZQ_TIMER_DIV                    = 0,
  parameter C_IS_DDR = 1'b1,              // Allowed Values: 0,1 
  parameter C_PI_DATA_WIDTH = 8'hFF,
  parameter C_MEM_DATA_WIDTH = 64,        // Allowed Values: 32,64,72
  parameter C_MEM_DM_WIDTH = C_MEM_DATA_WIDTH/8,     
  parameter C_MEM_DQS_WIDTH = C_MEM_DATA_WIDTH/8,  
  parameter C_WR_FIFO_MEM_PIPELINE = 0,
  parameter C_PORT_FOR_WRITE_TRAINING_PATTERN = 3'b001,
  parameter C_ARB0_ALGO                 = "ROUND_ROBIN",  // Allowed Values: CUSTOM, FIXED, ROUND_ROBIN
  parameter C_MEM_REG_DIMM = 0,

  // Ctrl Path Params
  parameter C_BURST_LENGTH              = 0,
  parameter C_NCK_PER_CLK               = 0,
  parameter C_CTRL_COMPLETE_INDEX           = 0,
  parameter C_CTRL_IS_WRITE_INDEX           = 0,
  parameter C_CTRL_PHYIF_RAS_N_INDEX        = 0,
  parameter C_CTRL_PHYIF_CAS_N_INDEX        = 0,
  parameter C_CTRL_PHYIF_WE_N_INDEX         = 0,
  parameter C_CTRL_RMW_INDEX                = 0,
  parameter C_CTRL_SKIP_0_INDEX             = 0,
  parameter C_CTRL_PHYIF_DQS_O_INDEX        = 0,
  parameter C_CTRL_SKIP_1_INDEX             = 0,
  parameter C_CTRL_DP_RDFIFO_PUSH_INDEX     = 0,
  parameter C_CTRL_SKIP_2_INDEX             = 0,
  parameter C_CTRL_AP_COL_CNT_LOAD_INDEX    = 0,
  parameter C_CTRL_AP_COL_CNT_ENABLE_INDEX  = 0,
  parameter C_CTRL_AP_PRECHARGE_ADDR10_INDEX= 0,
  parameter C_CTRL_AP_ROW_COL_SEL_INDEX     = 0,
  parameter C_CTRL_PHYIF_FORCE_DM_INDEX     = 0,
  parameter C_CTRL_REPEAT4_INDEX            = 0,
  parameter C_CTRL_DFI_RAS_N_0_INDEX        = 0,
  parameter C_CTRL_DFI_CAS_N_0_INDEX        = 0,
  parameter C_CTRL_DFI_WE_N_0_INDEX         = 0,
  parameter C_CTRL_DFI_RAS_N_1_INDEX        = 0,
  parameter C_CTRL_DFI_CAS_N_1_INDEX        = 0,
  parameter C_CTRL_DFI_WE_N_1_INDEX         = 0,
  parameter C_CTRL_DP_WRFIFO_POP_INDEX      = 0,
  parameter C_CTRL_DFI_WRDATA_EN_INDEX      = 0,
  parameter C_CTRL_DFI_RDDATA_EN_INDEX      = 0,
  parameter C_CTRL_AP_OTF_ADDR12_INDEX      = 0,
  parameter C_AP_PIPELINE1              = 0,
  parameter C_INIT0_STALL               = 0,
  parameter C_INIT1_STALL               = 0,
  parameter C_INIT2_STALL               = 0,
  parameter C_WORD_WRITE_SEQ            = 0,
  parameter C_WORD_READ_SEQ             = 0,
  parameter C_DOUBLEWORD_WRITE_SEQ      = 0,
  parameter C_DOUBLEWORD_READ_SEQ       = 0,
  parameter C_CL4_WRITE_SEQ             = 0,
  parameter C_CL4_READ_SEQ              = 0,
  parameter C_CL8_WRITE_SEQ             = 0,
  parameter C_CL8_READ_SEQ              = 0,
  parameter C_B16_WRITE_SEQ             = 0,
  parameter C_B16_READ_SEQ              = 0,
  parameter C_B32_WRITE_SEQ             = 0,
  parameter C_B32_READ_SEQ              = 0,
  parameter C_B64_WRITE_SEQ             = 0,
  parameter C_B64_READ_SEQ              = 0,
  parameter C_REFH_SEQ                  = 0,
  parameter C_NOP_SEQ                   = 0,
  parameter C_CTRL_ARB_RDMODWR_DELAY    = 0,
  parameter C_CTRL_AP_COL_DELAY         = 0,
  parameter C_CTRL_AP_PI_ADDR_CE_DELAY  = 0,
  parameter C_CTRL_AP_PORT_SELECT_DELAY = 0,
  parameter C_CTRL_AP_PIPELINE1_CE_DELAY        = 0,
  parameter C_CTRL_DP_RDFIFO_WHICHPORT_DELAY    = 0,
  parameter C_CTRL_DP_SIZE_DELAY                = 0,
  parameter C_CTRL_DP_WRFIFO_WHICHPORT_REP      = 1,
  parameter C_CTRL_DP_WRFIFO_WHICHPORT_DELAY    = 0,
  parameter C_CTRL_PHYIF_DUMMYREADSTART_DELAY   = 0,
  parameter C_CTRL_Q0_DELAY             = 0,
  parameter C_CTRL_Q1_DELAY             = 0,
  parameter C_CTRL_Q2_DELAY             = 0,
  parameter C_CTRL_Q3_DELAY             = 0,
  parameter C_CTRL_Q4_DELAY             = 0,
  parameter C_CTRL_Q5_DELAY             = 0,
  parameter C_CTRL_Q6_DELAY             = 0,
  parameter C_CTRL_Q7_DELAY             = 0,
  parameter C_CTRL_Q8_DELAY             = 0,
  parameter C_CTRL_Q9_DELAY             = 0,
  parameter C_CTRL_Q10_DELAY            = 0,
  parameter C_CTRL_Q11_DELAY            = 0,
  parameter C_CTRL_Q12_DELAY            = 0,
  parameter C_CTRL_Q13_DELAY            = 0,
  parameter C_CTRL_Q14_DELAY            = 0,
  parameter C_CTRL_Q15_DELAY            = 0,
  parameter C_CTRL_Q16_DELAY            = 0,
  parameter C_CTRL_Q17_DELAY            = 0,
  parameter C_CTRL_Q18_DELAY            = 0,
  parameter C_CTRL_Q19_DELAY            = 0,
  parameter C_CTRL_Q20_DELAY            = 0,
  parameter C_CTRL_Q21_DELAY            = 0,
  parameter C_CTRL_Q22_DELAY            = 0,
  parameter C_CTRL_Q23_DELAY            = 0,
  parameter C_CTRL_Q24_DELAY            = 0,
  parameter C_CTRL_Q25_DELAY            = 0,
  parameter C_CTRL_Q26_DELAY            = 0,
  parameter C_CTRL_Q27_DELAY            = 0,
  parameter C_CTRL_Q28_DELAY            = 0,
  parameter C_CTRL_Q29_DELAY            = 0,
  parameter C_CTRL_Q30_DELAY            = 0,
  parameter C_CTRL_Q31_DELAY            = 0,
  parameter C_CTRL_Q32_DELAY            = 0,
  parameter C_CTRL_Q33_DELAY            = 0,
  parameter C_CTRL_Q34_DELAY            = 0,
  parameter C_CTRL_Q35_DELAY            = 0,
  parameter C_BASEADDR_ARB0             = 9'h0,
  parameter C_HIGHADDR_ARB0             = 9'h0,
  parameter C_BASEADDR_ARB1             = 9'h0,
  parameter C_HIGHADDR_ARB1             = 9'h0,
  parameter C_BASEADDR_ARB2             = 9'h0,
  parameter C_HIGHADDR_ARB2             = 9'h0,
  parameter C_BASEADDR_ARB3             = 9'h0,
  parameter C_HIGHADDR_ARB3             = 9'h0,
  parameter C_BASEADDR_ARB4             = 9'h0,
  parameter C_HIGHADDR_ARB4             = 9'h0,
  parameter C_BASEADDR_ARB5             = 9'h0,
  parameter C_HIGHADDR_ARB5             = 9'h0,
  parameter C_BASEADDR_ARB6             = 9'h0,
  parameter C_HIGHADDR_ARB6             = 9'h0,
  parameter C_BASEADDR_ARB7             = 9'h0,
  parameter C_HIGHADDR_ARB7             = 9'h0,
  parameter C_BASEADDR_ARB8             = 9'h0,
  parameter C_HIGHADDR_ARB8             = 9'h0,
  parameter C_BASEADDR_ARB9             = 9'h0,
  parameter C_HIGHADDR_ARB9             = 9'h0,
  parameter C_BASEADDR_ARB10            = 9'h0,
  parameter C_HIGHADDR_ARB10            = 9'h0,
  parameter C_BASEADDR_ARB11            = 9'h0,
  parameter C_HIGHADDR_ARB11            = 9'h0,
  parameter C_BASEADDR_ARB12            = 9'h0,
  parameter C_HIGHADDR_ARB12            = 9'h0,
  parameter C_BASEADDR_ARB13            = 9'h0,
  parameter C_HIGHADDR_ARB13            = 9'h0,
  parameter C_BASEADDR_ARB14            = 9'h0,
  parameter C_HIGHADDR_ARB14            = 9'h0,
  parameter C_BASEADDR_ARB15            = 9'h0,
  parameter C_HIGHADDR_ARB15            = 9'h0,
  parameter C_ARB_BRAM_SRVAL_A          = 36'h0,
  parameter C_ARB_BRAM_SRVAL_B          = 36'h0,
  parameter C_ARB_BRAM_INIT_00          = 256'h0,
  parameter C_ARB_BRAM_INIT_01          = 256'h0,
  parameter C_ARB_BRAM_INIT_02          = 256'h0,
  parameter C_ARB_BRAM_INIT_03          = 256'h0,
  parameter C_ARB_BRAM_INIT_04          = 256'h0,
  parameter C_ARB_BRAM_INIT_05          = 256'h0,
  parameter C_ARB_BRAM_INIT_06          = 256'h0,
  parameter C_ARB_BRAM_INIT_07          = 256'h0,
  parameter C_ARB_BRAM_INIT_08          = 256'h0,
  parameter C_ARB_BRAM_INIT_09          = 256'h0,
  parameter C_ARB_BRAM_INIT_0A          = 256'h0,
  parameter C_ARB_BRAM_INIT_0B          = 256'h0,
  parameter C_ARB_BRAM_INIT_0C          = 256'h0,
  parameter C_ARB_BRAM_INIT_0D          = 256'h0,
  parameter C_ARB_BRAM_INIT_0E          = 256'h0,
  parameter C_ARB_BRAM_INIT_0F          = 256'h0,
  parameter C_ARB_BRAM_INIT_10          = 256'h0,
  parameter C_ARB_BRAM_INIT_11          = 256'h0,
  parameter C_ARB_BRAM_INIT_12          = 256'h0,
  parameter C_ARB_BRAM_INIT_13          = 256'h0,
  parameter C_ARB_BRAM_INIT_14          = 256'h0,
  parameter C_ARB_BRAM_INIT_15          = 256'h0,
  parameter C_ARB_BRAM_INIT_16          = 256'h0,
  parameter C_ARB_BRAM_INIT_17          = 256'h0,
  parameter C_ARB_BRAM_INIT_18          = 256'h0,
  parameter C_ARB_BRAM_INIT_19          = 256'h0,
  parameter C_ARB_BRAM_INIT_1A          = 256'h0,
  parameter C_ARB_BRAM_INIT_1B          = 256'h0,
  parameter C_ARB_BRAM_INIT_1C          = 256'h0,
  parameter C_ARB_BRAM_INIT_1D          = 256'h0,
  parameter C_ARB_BRAM_INIT_1E          = 256'h0,
  parameter C_ARB_BRAM_INIT_1F          = 256'h0,
  parameter C_ARB_BRAM_INIT_20          = 256'h0,
  parameter C_ARB_BRAM_INIT_21          = 256'h0,
  parameter C_ARB_BRAM_INIT_22          = 256'h0,
  parameter C_ARB_BRAM_INIT_23          = 256'h0,
  parameter C_ARB_BRAM_INIT_24          = 256'h0,
  parameter C_ARB_BRAM_INIT_25          = 256'h0,
  parameter C_ARB_BRAM_INIT_26          = 256'h0,
  parameter C_ARB_BRAM_INIT_27          = 256'h0,
  parameter C_ARB_BRAM_INIT_28          = 256'h0,
  parameter C_ARB_BRAM_INIT_29          = 256'h0,
  parameter C_ARB_BRAM_INIT_2A          = 256'h0,
  parameter C_ARB_BRAM_INIT_2B          = 256'h0,
  parameter C_ARB_BRAM_INIT_2C          = 256'h0,
  parameter C_ARB_BRAM_INIT_2D          = 256'h0,
  parameter C_ARB_BRAM_INIT_2E          = 256'h0,
  parameter C_ARB_BRAM_INIT_2F          = 256'h0,
  parameter C_ARB_BRAM_INIT_30          = 256'h0,
  parameter C_ARB_BRAM_INIT_31          = 256'h0,
  parameter C_ARB_BRAM_INIT_32          = 256'h0,
  parameter C_ARB_BRAM_INIT_33          = 256'h0,
  parameter C_ARB_BRAM_INIT_34          = 256'h0,
  parameter C_ARB_BRAM_INIT_35          = 256'h0,
  parameter C_ARB_BRAM_INIT_36          = 256'h0,
  parameter C_ARB_BRAM_INIT_37          = 256'h0,
  parameter C_ARB_BRAM_INIT_38          = 256'h0,
  parameter C_ARB_BRAM_INIT_39          = 256'h0,
  parameter C_ARB_BRAM_INIT_3A          = 256'h0,
  parameter C_ARB_BRAM_INIT_3B          = 256'h0,
  parameter C_ARB_BRAM_INIT_3C          = 256'h0,
  parameter C_ARB_BRAM_INIT_3D          = 256'h0,
  parameter C_ARB_BRAM_INIT_3E          = 256'h0,
  parameter C_ARB_BRAM_INIT_3F          = 256'h0,
  parameter C_ARB_BRAM_INITP_00         = 256'h0,
  parameter C_ARB_BRAM_INITP_01         = 256'h0,
  parameter C_ARB_BRAM_INITP_02         = 256'h0,
  parameter C_ARB_BRAM_INITP_03         = 256'h0,
  parameter C_ARB_BRAM_INITP_04         = 256'h0,
  parameter C_ARB_BRAM_INITP_05         = 256'h0,
  parameter C_ARB_BRAM_INITP_06         = 256'h0,
  parameter C_ARB_BRAM_INITP_07         = 256'h0,
  parameter C_USE_FIXED_BASEADDR_CTRL   = 0,
  parameter C_B16_REPEAT_CNT            = 0,
  parameter C_B32_REPEAT_CNT            = 0,
  parameter C_B64_REPEAT_CNT            = 0,
  parameter C_ZQCS_REPEAT_CNT           = 0,
  parameter C_BASEADDR_CTRL0            = 9'h0,
  parameter C_HIGHADDR_CTRL0            = 9'h0,
  parameter C_BASEADDR_CTRL1            = 9'h0,
  parameter C_HIGHADDR_CTRL1            = 9'h0,
  parameter C_BASEADDR_CTRL2            = 9'h0,
  parameter C_HIGHADDR_CTRL2            = 9'h0,
  parameter C_BASEADDR_CTRL3            = 9'h0,
  parameter C_HIGHADDR_CTRL3            = 9'h0,
  parameter C_BASEADDR_CTRL4            = 9'h0,
  parameter C_HIGHADDR_CTRL4            = 9'h0,
  parameter C_BASEADDR_CTRL5            = 9'h0,
  parameter C_HIGHADDR_CTRL5            = 9'h0,
  parameter C_BASEADDR_CTRL6            = 9'h0,
  parameter C_HIGHADDR_CTRL6            = 9'h0,
  parameter C_BASEADDR_CTRL7            = 9'h0,
  parameter C_HIGHADDR_CTRL7            = 9'h0,
  parameter C_BASEADDR_CTRL8            = 9'h0,
  parameter C_HIGHADDR_CTRL8            = 9'h0,
  parameter C_BASEADDR_CTRL9            = 9'h0,
  parameter C_HIGHADDR_CTRL9            = 9'h0,
  parameter C_BASEADDR_CTRL10           = 9'h0,
  parameter C_HIGHADDR_CTRL10           = 9'h0,
  parameter C_BASEADDR_CTRL11           = 9'h0,
  parameter C_HIGHADDR_CTRL11           = 9'h0,
  parameter C_BASEADDR_CTRL12           = 9'h0,
  parameter C_HIGHADDR_CTRL12           = 9'h0,
  parameter C_BASEADDR_CTRL13           = 9'h0,
  parameter C_HIGHADDR_CTRL13           = 9'h0,
  parameter C_BASEADDR_CTRL14           = 9'h0,
  parameter C_HIGHADDR_CTRL14           = 9'h0,
  parameter C_BASEADDR_CTRL15           = 9'h0,
  parameter C_HIGHADDR_CTRL15           = 9'h0,
  parameter C_BASEADDR_CTRL16           = 9'h0,
  parameter C_HIGHADDR_CTRL16           = 9'h0,
   // ctrl_path_table params
  parameter C_CTRL_BRAM_SRVAL    = 36'h0,
  parameter C_CTRL_BRAM_INIT_00  = 256'h0,
  parameter C_CTRL_BRAM_INIT_01  = 256'h0,
  parameter C_CTRL_BRAM_INIT_02  = 256'h0,
  parameter C_CTRL_BRAM_INIT_03  = 256'h0,
  parameter C_CTRL_BRAM_INIT_04  = 256'h0,
  parameter C_CTRL_BRAM_INIT_05  = 256'h0,
  parameter C_CTRL_BRAM_INIT_06  = 256'h0,
  parameter C_CTRL_BRAM_INIT_07  = 256'h0,
  parameter C_CTRL_BRAM_INIT_08  = 256'h0,
  parameter C_CTRL_BRAM_INIT_09  = 256'h0,
  parameter C_CTRL_BRAM_INIT_0A  = 256'h0,
  parameter C_CTRL_BRAM_INIT_0B  = 256'h0,
  parameter C_CTRL_BRAM_INIT_0C  = 256'h0,
  parameter C_CTRL_BRAM_INIT_0D  = 256'h0,
  parameter C_CTRL_BRAM_INIT_0E  = 256'h0,
  parameter C_CTRL_BRAM_INIT_0F  = 256'h0,
  parameter C_CTRL_BRAM_INIT_10  = 256'h0,
  parameter C_CTRL_BRAM_INIT_11  = 256'h0,
  parameter C_CTRL_BRAM_INIT_12  = 256'h0,
  parameter C_CTRL_BRAM_INIT_13  = 256'h0,
  parameter C_CTRL_BRAM_INIT_14  = 256'h0,
  parameter C_CTRL_BRAM_INIT_15  = 256'h0,
  parameter C_CTRL_BRAM_INIT_16  = 256'h0,
  parameter C_CTRL_BRAM_INIT_17  = 256'h0,
  parameter C_CTRL_BRAM_INIT_18  = 256'h0,
  parameter C_CTRL_BRAM_INIT_19  = 256'h0,
  parameter C_CTRL_BRAM_INIT_1A  = 256'h0,
  parameter C_CTRL_BRAM_INIT_1B  = 256'h0,
  parameter C_CTRL_BRAM_INIT_1C  = 256'h0,
  parameter C_CTRL_BRAM_INIT_1D  = 256'h0,
  parameter C_CTRL_BRAM_INIT_1E  = 256'h0,
  parameter C_CTRL_BRAM_INIT_1F  = 256'h0,
  parameter C_CTRL_BRAM_INIT_20  = 256'h0,
  parameter C_CTRL_BRAM_INIT_21  = 256'h0,
  parameter C_CTRL_BRAM_INIT_22  = 256'h0,
  parameter C_CTRL_BRAM_INIT_23  = 256'h0,
  parameter C_CTRL_BRAM_INIT_24  = 256'h0,
  parameter C_CTRL_BRAM_INIT_25  = 256'h0,
  parameter C_CTRL_BRAM_INIT_26  = 256'h0,
  parameter C_CTRL_BRAM_INIT_27  = 256'h0,
  parameter C_CTRL_BRAM_INIT_28  = 256'h0,
  parameter C_CTRL_BRAM_INIT_29  = 256'h0,
  parameter C_CTRL_BRAM_INIT_2A  = 256'h0,
  parameter C_CTRL_BRAM_INIT_2B  = 256'h0,
  parameter C_CTRL_BRAM_INIT_2C  = 256'h0,
  parameter C_CTRL_BRAM_INIT_2D  = 256'h0,
  parameter C_CTRL_BRAM_INIT_2E  = 256'h0,
  parameter C_CTRL_BRAM_INIT_2F  = 256'h0,
  parameter C_CTRL_BRAM_INIT_30  = 256'h0,
  parameter C_CTRL_BRAM_INIT_31  = 256'h0,
  parameter C_CTRL_BRAM_INIT_32  = 256'h0,
  parameter C_CTRL_BRAM_INIT_33  = 256'h0,
  parameter C_CTRL_BRAM_INIT_34  = 256'h0,
  parameter C_CTRL_BRAM_INIT_35  = 256'h0,
  parameter C_CTRL_BRAM_INIT_36  = 256'h0,
  parameter C_CTRL_BRAM_INIT_37  = 256'h0,
  parameter C_CTRL_BRAM_INIT_38  = 256'h0,
  parameter C_CTRL_BRAM_INIT_39  = 256'h0,
  parameter C_CTRL_BRAM_INIT_3A  = 256'h0,
  parameter C_CTRL_BRAM_INIT_3B  = 256'h0,
  parameter C_CTRL_BRAM_INIT_3C  = 256'h0,
  parameter C_CTRL_BRAM_INIT_3D  = 256'h0,
  parameter C_CTRL_BRAM_INIT_3E  = 256'h0,
  parameter C_CTRL_BRAM_INIT_3F  = 256'h0,
  parameter C_CTRL_BRAM_INITP_00 = 256'h0,
  parameter C_CTRL_BRAM_INITP_01 = 256'h0,
  parameter C_CTRL_BRAM_INITP_02 = 256'h0,
  parameter C_CTRL_BRAM_INITP_03 = 256'h0,
  parameter C_CTRL_BRAM_INITP_04 = 256'h0,
  parameter C_CTRL_BRAM_INITP_05 = 256'h0,
  parameter C_CTRL_BRAM_INITP_06 = 256'h0,
  parameter C_CTRL_BRAM_INITP_07 = 256'h0,
  parameter integer C_SKIP_1_VALUE = 1,
  parameter integer C_SKIP_2_VALUE = 1,
  parameter integer C_SKIP_3_VALUE = 1,
  parameter integer C_SKIP_4_VALUE = 1,
  parameter integer C_SKIP_5_VALUE = 1,
  parameter integer C_SKIP_6_VALUE = 1,
  parameter integer C_SKIP_7_VALUE = 1,
  parameter C_ARB_SEQUENCE_ENCODING_WIDTH   = 4, // Allowed Values: 4
  parameter C_ARB_PORT_ENCODING_WIDTH       = 3,
  parameter C_MEM_DM_WIDTH_INT = C_MEM_DM_WIDTH*(C_IS_DDR+1),
  parameter C_MEM_PHASE_DETECT = 1,
  parameter C_MEM_ODT_TYPE = 0
)
(
  input  wire                                     Clk,
  input  wire                                     Clk90,
  input  wire                                     Rst,
  input  wire [C_NUM_PORTS-1:0]                   PI_AddrReq,
  input  wire [C_NUM_PORTS*4-1:0]                 PI_Size,
  input  wire [C_NUM_PORTS-1:0]                   PI_RNW,
  input  wire [C_NUM_PORTS-1:0]                   PI_RdModWr,
  output wire [C_NUM_PORTS-1:0]                   PI_AddrAck,
  input  wire [C_ARB_SEQUENCE_ENCODING_WIDTH-1:0] Arb_Sequence,
  input  wire                                     Arb_LoadSequence,
  output wire                                     Arb_PatternStart,
  
  input  wire [31:0]                              AP_Ctrl_Addr,
  output wire [3:0]                               Ctrl_ECC_RdFIFO_Size,
  output wire                                     Ctrl_ECC_RdFIFO_RNW,
  output wire [31:0]                              Ctrl_ECC_RdFIFO_Addr,
  output wire                                     Ctrl_AP_Col_W,
  output wire                                     Ctrl_AP_Col_DW,
  output wire                                     Ctrl_AP_Col_CL4,
  output wire                                     Ctrl_AP_Col_CL8,
  output wire                                     Ctrl_AP_Col_B16,
  output wire                                     Ctrl_AP_Col_B32,
  output wire                                     Ctrl_AP_Col_B64,
  output wire [3:0]                               Ctrl_AP_Col_Burst_Length,
  output wire [C_NUM_PORTS-1:0]                   Ctrl_AP_PI_Addr_CE,
  output wire [C_ARB_PORT_ENCODING_WIDTH-1:0]     Ctrl_AP_Port_Select,
  output wire                                     Ctrl_AP_Col_Cnt_Load,
  output wire                                     Ctrl_AP_Col_Cnt_Enable,
  output wire                                     Ctrl_AP_Precharge_Addr10,
  output wire                                     Ctrl_AP_OTF_Addr12,
  output wire                                     Ctrl_AP_Row_Col_Sel,
  output wire                                     Ctrl_AP_Pipeline1_CE,
  output wire                                     Ctrl_AP_Assert_All_CS,
  
  input  wire [C_NUM_PORTS-1:0]                   DP_Ctrl_RdFIFO_AlmostFull,
  output wire [C_NUM_PORTS-1:0]                   Ctrl_DP_RdFIFO_WhichPort_Decode,
  output wire [C_ARB_PORT_ENCODING_WIDTH*C_CTRL_DP_WRFIFO_WHICHPORT_REP-1:0] Ctrl_DP_WrFIFO_WhichPort,
  output wire [C_NUM_PORTS-1:0]                   Ctrl_DP_WrFIFO_WhichPort_Decode,
  output reg                                      Ctrl_DP_RdFIFO_Push,
  output wire                                     Ctrl_DP_WrFIFO_Pop,
  
  input  wire                                     PhyIF_Ctrl_InitDone,
  output wire                                     Ctrl_Periodic_Rd_Mask,
  output wire                                     Ctrl_PhyIF_RAS_n,
  output wire                                     Ctrl_PhyIF_CAS_n,
  output wire                                     Ctrl_PhyIF_WE_n,
  output wire                                     Ctrl_Is_Write,
  output wire                                     Ctrl_RMW,
  output wire                                     Ctrl_PhyIF_DQS_O,
  // synthesis attribute equivalent_register_removal of Ctrl_PhyIF_Force_DM is "no"
  output reg  [C_MEM_DM_WIDTH_INT-1:0]            Ctrl_PhyIF_Force_DM,
  output reg                                      Ctrl_Refresh_Flag,
  output wire [C_NCK_PER_CLK-1:0]                 Ctrl_DFI_RAS_n,
  output wire [C_NCK_PER_CLK-1:0]                 Ctrl_DFI_CAS_n,
  output wire [C_NCK_PER_CLK-1:0]                 Ctrl_DFI_WE_n,
  output wire [C_NCK_PER_CLK-1:0]                 Ctrl_DFI_ODT,
  output wire [C_NCK_PER_CLK-1:0]                 Ctrl_DFI_CE,
  output wire                                     Ctrl_DFI_WrData_En,
  output wire                                     Ctrl_DFI_RdData_En
);

  // Internal Parameters
  localparam C_ARB_PATTERN_TYPE_WIDTH        = 4; // Allowed Values: 4
  localparam C_ARB_PATTERN_TYPE_DECODE_WIDTH = 16; // Allowed Values: 16
  localparam C_ARB_BRAM_ADDR_WIDTH           = 9; // Allowed Values: 9
  
  localparam C_MEM_DATA_WIDTH_INT = C_MEM_DATA_WIDTH*(C_IS_DDR+1);
  localparam C_MEM_DQS_WIDTH_INT = C_MEM_DQS_WIDTH*(C_IS_DDR+1);     
  localparam C_MAX_REQ_ALLOWED_INT  = 
            C_AP_PIPELINE1 ? (C_MAX_REQ_ALLOWED < 2 ? C_MAX_REQ_ALLOWED : 2) : 1;

  reg                                        Ctrl_PhyIF_DQS_O_skip = 0;
  wire [C_ARB_PORT_ENCODING_WIDTH-1:0]       Ctrl_DP_RdFIFO_WhichPort;
  wire [C_NUM_PORTS-1:0]                     ctrl_dp_rdfifo_whichport_decode_i;
  reg  [C_NUM_PORTS-1:0]                     ctrl_dp_rdfifo_whichport_decode_r;
  
  wire [C_NUM_PORTS-1:0]                     arb_whichport_decode;
  wire [C_ARB_PORT_ENCODING_WIDTH-1:0]       arb_whichport;
  wire [C_NUM_CTRL_SIGNALS-1:0]              ctrl_bram_out;
  reg                                        ctrl_initializememory = 0;
  reg                                        ctrl_refresh_i1 = 0;
  wire                                       ctrl_periodic_rd_mask_i;
  wire                                       ctrl_maint;
  wire                                       ctrl_maint_enable;
  wire                                       periodic_rd_req;
  wire                                       maint_zq_req;
  wire                                       maint_zq_wip;
  reg                                        ctrl_maint_enable_i = 0;
  reg [C_REFRESH_CNT_WIDTH-1:0]              ctrl_refresh_cnt = 0;
  wire                                       ctrl_complete;
  reg                                        ctrl_complete_i1 = 0;
  reg                                        ctrl_idle_i1 = 0;
  reg                                        ctrl_idle_i1a = 0;
  reg                                        ctrl_idle_i2 = 0;
  wire                                       ctrl_idle;
  wire                                       ctrl_almostidle;
  wire                                       ctrl_stall;
  wire [2:0]                                 ctrl_skip_value;
  wire                                       arb_patternstart_i;
  wire [C_ARB_PATTERN_TYPE_WIDTH-1:0]        arb_patterntype;
  wire [C_ARB_PATTERN_TYPE_DECODE_WIDTH-1:0] arb_patterntype_decode;
  reg  [C_NUM_PORTS-1:0]                     pi_arbpatterntype_pop = 0;
  wire                                       assert_all_cs1;
  reg                                        ctrl_phyif_force_dm_d1 = 0;
  wire                                       arb_rdmodwr;
  wire                                       arb_rdmodwr_delayed;
  
  reg [C_ARB_PATTERN_TYPE_WIDTH-1:0]         arb_patterntype_d1;
  
  wire                                       ctrl_repeat4;
  wire                                       ignore_complete;

    
  genvar i;
  genvar j;

  assign ctrl_complete             = ctrl_bram_out[C_CTRL_COMPLETE_INDEX] 
                                     & ~ignore_complete;
  assign Ctrl_Is_Write             = ctrl_bram_out[C_CTRL_IS_WRITE_INDEX];
  assign ctrl_repeat4              = ctrl_bram_out[C_CTRL_REPEAT4_INDEX];
  assign Ctrl_AP_Col_Cnt_Load      = ctrl_bram_out[C_CTRL_AP_COL_CNT_LOAD_INDEX];
  assign Ctrl_AP_Col_Cnt_Enable    = ctrl_bram_out[C_CTRL_AP_COL_CNT_ENABLE_INDEX];
  assign Ctrl_AP_Precharge_Addr10  = ctrl_bram_out[C_CTRL_AP_PRECHARGE_ADDR10_INDEX];
  assign Ctrl_AP_Row_Col_Sel       = ctrl_bram_out[C_CTRL_AP_ROW_COL_SEL_INDEX];

  generate
    if (C_USE_MIG_V6_PHY) begin : ctrl_dfi
      if (C_NCK_PER_CLK == 2) begin : cmdx2
        reg [2:0] ctrl_dp_wrfifo_pop_d;
        reg [0:0] ctrl_dfi_wrdata_en_d;
        reg [1:0] ctrl_dfi_odt_i;
        wire [1:0] ctrl_dfi_odt_i2;

        // DFI signals
        assign Ctrl_DFI_RAS_n[0]  = ctrl_bram_out[C_CTRL_DFI_RAS_N_0_INDEX];
        assign Ctrl_DFI_CAS_n[0]  = ctrl_bram_out[C_CTRL_DFI_CAS_N_0_INDEX];
        assign Ctrl_DFI_WE_n[0]   = ctrl_bram_out[C_CTRL_DFI_WE_N_0_INDEX];
        assign Ctrl_DFI_RAS_n[1]  = ctrl_bram_out[C_CTRL_DFI_RAS_N_1_INDEX];
        assign Ctrl_DFI_CAS_n[1]  = ctrl_bram_out[C_CTRL_DFI_CAS_N_1_INDEX];
        assign Ctrl_DFI_WE_n[1]   = ctrl_bram_out[C_CTRL_DFI_WE_N_1_INDEX];
        assign Ctrl_DFI_ODT[0]    = (C_MEM_ODT_TYPE == 0) ? 1'b0 : 
                                    (C_MEM_TYPE == "DDR2" & C_MEM_CAS_LATENCY < 5) ? ctrl_dfi_odt_i2[0] :
                                    ctrl_dfi_odt_i[0];
        assign Ctrl_DFI_ODT[1]    = (C_MEM_ODT_TYPE == 0) ? 1'b0 : 
                                    (C_MEM_TYPE == "DDR2" & C_MEM_CAS_LATENCY < 5) ? ctrl_dfi_odt_i2[1] :
                                    ctrl_dfi_odt_i[1];
        assign Ctrl_DFI_CE[0]     = 1'b1;
        assign Ctrl_DFI_CE[1]     = 1'b1;

        assign Ctrl_DFI_WrData_En = ctrl_bram_out[C_CTRL_DFI_WRDATA_EN_INDEX];
        assign Ctrl_DFI_RdData_En = ctrl_bram_out[C_CTRL_DFI_RDDATA_EN_INDEX];
        assign Ctrl_DP_WrFIFO_Pop = ctrl_bram_out[C_CTRL_DP_WRFIFO_POP_INDEX];

        always @(posedge Clk) begin
          ctrl_dp_wrfifo_pop_d[0] <= Ctrl_DP_WrFIFO_Pop;
          ctrl_dp_wrfifo_pop_d[1] <= ctrl_dp_wrfifo_pop_d[0];
          ctrl_dp_wrfifo_pop_d[2] <= ctrl_dp_wrfifo_pop_d[1];
        end

        always @(posedge Clk) begin
          ctrl_dfi_wrdata_en_d[0] <= Ctrl_DFI_WrData_En;
          ctrl_dfi_odt_i[0] <= Ctrl_DFI_WrData_En | ctrl_dfi_wrdata_en_d[0];
          ctrl_dfi_odt_i[1] <= Ctrl_DFI_WrData_En | ctrl_dfi_wrdata_en_d[0];
        end

        assign ctrl_dfi_odt_i2[0] = Ctrl_DFI_WrData_En | ctrl_dfi_wrdata_en_d[0];
        assign ctrl_dfi_odt_i2[1] = Ctrl_DFI_WrData_En | ctrl_dfi_wrdata_en_d[0];

        assign Ctrl_RMW         = 1'b0;
        assign ctrl_skip_value  = 3'b0;
        assign Ctrl_AP_OTF_Addr12 = ctrl_bram_out[C_CTRL_AP_OTF_ADDR12_INDEX];

        // Tie off unused outputs
        always @(posedge Clk) begin
            ctrl_phyif_force_dm_d1 <= 1'b0;
            Ctrl_DP_RdFIFO_Push <= 1'b0;
        end

        assign Ctrl_PhyIF_RAS_n = 1'b0;
        assign Ctrl_PhyIF_CAS_n = 1'b0;
        assign Ctrl_PhyIF_WE_n = 1'b0;
        assign Ctrl_PhyIF_DQS_O = 1'b0;
      end
      else begin : cmdx1
      end
    end
    else begin : ctrl_phyif
      if (C_USE_MIG_S3_PHY) begin : gen_s3_ctrl_signals
        reg Ctrl_PhyIF_RAS_n_i;
        reg Ctrl_PhyIF_CAS_n_i;
        reg Ctrl_PhyIF_WE_n_i;
        always @(negedge Clk90) begin
          Ctrl_PhyIF_RAS_n_i <= ctrl_bram_out[C_CTRL_PHYIF_RAS_N_INDEX];
          Ctrl_PhyIF_CAS_n_i <= ctrl_bram_out[C_CTRL_PHYIF_CAS_N_INDEX];
          Ctrl_PhyIF_WE_n_i  <= ctrl_bram_out[C_CTRL_PHYIF_WE_N_INDEX];
        end
        assign Ctrl_PhyIF_RAS_n = Ctrl_PhyIF_RAS_n_i;
        assign Ctrl_PhyIF_CAS_n = Ctrl_PhyIF_CAS_n_i;
        assign Ctrl_PhyIF_WE_n  = Ctrl_PhyIF_WE_n_i;
      end // gen_s3_ctrl_signals
      else begin : gen_nons3_ctrl_signals
        assign Ctrl_PhyIF_RAS_n    = ctrl_bram_out[C_CTRL_PHYIF_RAS_N_INDEX];
        assign Ctrl_PhyIF_CAS_n    = ctrl_bram_out[C_CTRL_PHYIF_CAS_N_INDEX];
        assign Ctrl_PhyIF_WE_n     = ctrl_bram_out[C_CTRL_PHYIF_WE_N_INDEX];
      end // gen_nons3_ctrl_signals
      
      if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc_skip
        always @(*) begin
          Ctrl_DP_RdFIFO_Push = ctrl_bram_out[C_CTRL_DP_RDFIFO_PUSH_INDEX];
        end
        assign Ctrl_RMW         = ctrl_bram_out[C_CTRL_RMW_INDEX] 
                                  & arb_rdmodwr_delayed;
        assign ctrl_skip_value  = {ctrl_bram_out[C_CTRL_SKIP_2_INDEX],
                                   ctrl_bram_out[C_CTRL_SKIP_1_INDEX],
                                   ctrl_bram_out[C_CTRL_SKIP_0_INDEX]};

        if (C_USE_MIG_V5_PHY && C_MEM_TYPE == "DDR2") begin : gen_v5mig

          reg Ctrl_PhyIF_DQS_O_tmp_d1;
          reg Ctrl_PhyIF_DQS_O_tmp_d2; 

          always @(posedge Clk) begin
            Ctrl_PhyIF_DQS_O_skip <= (ctrl_skip_value != 0) && ~arb_rdmodwr;
            Ctrl_PhyIF_DQS_O_tmp_d1 <= Ctrl_PhyIF_DQS_O_skip || ((ctrl_skip_value != 0) && ~arb_rdmodwr);
            Ctrl_PhyIF_DQS_O_tmp_d2 <= Ctrl_PhyIF_DQS_O_tmp_d1;
          end
          assign Ctrl_PhyIF_DQS_O = (ctrl_bram_out[C_CTRL_PHYIF_DQS_O_INDEX]
                                       || Ctrl_PhyIF_DQS_O_tmp_d2) 
                                    ? 1'b1 : 1'b0;
        end // gen_v5mig
        else begin : gen_normal
          always @(posedge Clk) begin
            Ctrl_PhyIF_DQS_O_skip <= (ctrl_skip_value != 0) && ~arb_rdmodwr;
          end
          assign Ctrl_PhyIF_DQS_O = (ctrl_bram_out[C_CTRL_PHYIF_DQS_O_INDEX]
                                       || Ctrl_PhyIF_DQS_O_skip 
                                       || ((ctrl_skip_value != 0) 
                                           && ~arb_rdmodwr)) 
                                    ? 1'b1 : 1'b0;
        end // gen_normal
      end // gen_ecc_skip
      else begin : gen_noecc_skip
        reg ctrl_phyif_dqs_o_d1;
        always @(posedge Clk) begin 
            Ctrl_DP_RdFIFO_Push <= ctrl_bram_out[C_CTRL_DP_RDFIFO_PUSH_INDEX];
            Ctrl_PhyIF_DQS_O_skip <= 1'b0;
            ctrl_phyif_dqs_o_d1 <= ctrl_bram_out[C_CTRL_PHYIF_DQS_O_INDEX];
        end
        assign Ctrl_RMW         = 1'b0;
        assign Ctrl_PhyIF_DQS_O = ctrl_phyif_dqs_o_d1;
        assign ctrl_skip_value  = 3'b0;
      end // gen_non_ecc_skip
        
        if (C_USE_MIG_S3_PHY)
           begin : gen_force_dm_noreg
              if ((C_INCLUDE_ECC_SUPPORT == 1) && (C_MEM_DDR2_ENABLE == 1) && (C_MEM_REG_DIMM == 1)) begin : gen_ecc_skip
                 always @(*) ctrl_phyif_force_dm_d1 <= ctrl_bram_out[C_CTRL_PHYIF_FORCE_DM_INDEX] || ((ctrl_skip_value != 0) && ~arb_rdmodwr);
              end
              else begin : gen_noecc_skip
                 always @(*) ctrl_phyif_force_dm_d1 <= ctrl_bram_out[C_CTRL_PHYIF_FORCE_DM_INDEX];
              end
           end
         else if ((C_ECC_ENCODE_PIPELINE == 1) && (C_INCLUDE_ECC_SUPPORT == 1))
           begin : gen_ecc_pipeline
              if (C_MEM_DDR2_ENABLE == 0)
                begin : gen_force_dm_reg_ddr
                   always @(*) ctrl_phyif_force_dm_d1 <= ctrl_bram_out[C_CTRL_PHYIF_FORCE_DM_INDEX];
                end
              else
                if (C_MEM_REG_DIMM == 1)
                begin : gen_force_dm_reg_ddr2
                   always @(*) ctrl_phyif_force_dm_d1 <= ctrl_bram_out[C_CTRL_PHYIF_FORCE_DM_INDEX] || ((ctrl_skip_value != 0) && ~arb_rdmodwr);
                end
                else
                begin : gen_force_dm_unreg_ddr2
                   always @(*) ctrl_phyif_force_dm_d1 <= ctrl_bram_out[C_CTRL_PHYIF_FORCE_DM_INDEX];// || ((ctrl_skip_value != 0) && ~arb_rdmodwr);
                end
           end
         else
           begin : gen_ecc_nopipeline
              if (C_MEM_DDR2_ENABLE == 0)
                begin : gen_force_dm_reg_ddr
                   always @(posedge Clk) ctrl_phyif_force_dm_d1 <= ctrl_bram_out[C_CTRL_PHYIF_FORCE_DM_INDEX];
                end
              else
                begin : gen_force_dm_reg_ddr2
                   if (C_INCLUDE_ECC_SUPPORT == 1) begin : gen_ecc_skip
                      always @(posedge Clk) ctrl_phyif_force_dm_d1 <= ctrl_bram_out[C_CTRL_PHYIF_FORCE_DM_INDEX] || ((ctrl_skip_value != 0) && ~arb_rdmodwr);
                   end
                   else begin : gen_noecc_skip
                      always @(posedge Clk) ctrl_phyif_force_dm_d1 <= ctrl_bram_out[C_CTRL_PHYIF_FORCE_DM_INDEX];
                   end
                end
           end
       end
  endgenerate

  always @(posedge Clk) Ctrl_PhyIF_Force_DM  <= {C_MEM_DM_WIDTH_INT{ctrl_phyif_force_dm_d1}};

  generate 
    if (C_INCLUDE_ECC_SUPPORT == 1) begin : ecc_srl_delays
      reg [3:0]     Ctrl_ECC_RdFIFO_Size_i;
      reg           Ctrl_ECC_RdFIFO_RNW_i;

      mpmc_srl_delay #(
        .C_DELAY (C_CTRL_ARB_RDMODWR_DELAY)
      )
      mpmc_srl_delay_arb_rdmodwr (
        .Clk  (Clk),
        .Data (arb_rdmodwr),
        .Q    (arb_rdmodwr_delayed)
      );

      always @(*) begin
        case (arb_patterntype_d1)
          C_WORD_WRITE_SEQ       : Ctrl_ECC_RdFIFO_Size_i = 4'h0;
          C_WORD_READ_SEQ        : Ctrl_ECC_RdFIFO_Size_i = 4'h0;
          C_DOUBLEWORD_WRITE_SEQ : Ctrl_ECC_RdFIFO_Size_i = 4'h0;
          C_DOUBLEWORD_READ_SEQ  : Ctrl_ECC_RdFIFO_Size_i = 4'h0;
          C_CL4_WRITE_SEQ        : Ctrl_ECC_RdFIFO_Size_i = 4'h1;
          C_CL4_READ_SEQ         : Ctrl_ECC_RdFIFO_Size_i = 4'h1;
          C_CL8_WRITE_SEQ        : Ctrl_ECC_RdFIFO_Size_i = 4'h2;
          C_CL8_READ_SEQ         : Ctrl_ECC_RdFIFO_Size_i = 4'h2;
          C_B16_WRITE_SEQ        : Ctrl_ECC_RdFIFO_Size_i = 4'h3;
          C_B16_READ_SEQ         : Ctrl_ECC_RdFIFO_Size_i = 4'h3;
          C_B32_WRITE_SEQ        : Ctrl_ECC_RdFIFO_Size_i = 4'h4;
          C_B32_READ_SEQ         : Ctrl_ECC_RdFIFO_Size_i = 4'h4;
          C_B64_WRITE_SEQ        : Ctrl_ECC_RdFIFO_Size_i = 4'h5;
          C_B64_READ_SEQ         : Ctrl_ECC_RdFIFO_Size_i = 4'h5;
          default                : Ctrl_ECC_RdFIFO_Size_i = 4'h0;
        endcase
      end
      
      always @(*) begin
        case (arb_patterntype_d1)
          C_WORD_WRITE_SEQ       : Ctrl_ECC_RdFIFO_RNW_i = 1'b0;
          C_WORD_READ_SEQ        : Ctrl_ECC_RdFIFO_RNW_i = 1'b1;
          C_DOUBLEWORD_WRITE_SEQ : Ctrl_ECC_RdFIFO_RNW_i = 1'b0;
          C_DOUBLEWORD_READ_SEQ  : Ctrl_ECC_RdFIFO_RNW_i = 1'b1;
          C_CL4_WRITE_SEQ        : Ctrl_ECC_RdFIFO_RNW_i = 1'b0;
          C_CL4_READ_SEQ         : Ctrl_ECC_RdFIFO_RNW_i = 1'b1;
          C_CL8_WRITE_SEQ        : Ctrl_ECC_RdFIFO_RNW_i = 1'b0;
          C_CL8_READ_SEQ         : Ctrl_ECC_RdFIFO_RNW_i = 1'b1;
          C_B16_WRITE_SEQ        : Ctrl_ECC_RdFIFO_RNW_i = 1'b0;
          C_B16_READ_SEQ         : Ctrl_ECC_RdFIFO_RNW_i = 1'b1;
          C_B32_WRITE_SEQ        : Ctrl_ECC_RdFIFO_RNW_i = 1'b0;
          C_B32_READ_SEQ         : Ctrl_ECC_RdFIFO_RNW_i = 1'b1;
          C_B64_WRITE_SEQ        : Ctrl_ECC_RdFIFO_RNW_i = 1'b0;
          C_B64_READ_SEQ         : Ctrl_ECC_RdFIFO_RNW_i = 1'b1;
          default                : Ctrl_ECC_RdFIFO_RNW_i = 1'b0;
        endcase
      end
      
      for (i=0;i<4;i=i+1) begin : instantiate_ctrl_ecc_rdfifo_Size_srls
        mpmc_srl_delay #(
          .C_DELAY (C_CTRL_DP_RDFIFO_WHICHPORT_DELAY-1)
        )
        mpmc_srl_delay_Ctrl_DP_RdFIFO_Size (
          .Clk  (Clk),
          .Data (Ctrl_ECC_RdFIFO_Size_i[i]),
          .Q    (Ctrl_ECC_RdFIFO_Size[i])
        );
      end

      mpmc_srl_delay #(
        .C_DELAY (C_CTRL_DP_RDFIFO_WHICHPORT_DELAY-1)
      )
      mpmc_srl_delay_Ctrl_DP_RdFIFO_RNW (
        .Clk  (Clk),
        .Data (Ctrl_ECC_RdFIFO_RNW_i),
        .Q    (Ctrl_ECC_RdFIFO_RNW)
      );

      for (i=0;i<32;i=i+1) begin : instantiate_ctrl_ecc_rdfifo_addr_srls
        mpmc_srl_delay #(
          .C_DELAY (C_CTRL_DP_RDFIFO_WHICHPORT_DELAY-1-C_CTRL_AP_PIPELINE1_CE_DELAY)
        )
        mpmc_srl_delay_Ctrl_DP_RdFIFO_Addr (
          .Clk  (Clk),
          .Data (AP_Ctrl_Addr[i]),
          .Q    (Ctrl_ECC_RdFIFO_Addr[i])
        );
      end
    end
    else begin : no_ecc_srl_delays
      assign arb_rdmodwr_delayed  = 1'b0;
      assign Ctrl_ECC_RdFIFO_Size = 4'h0;
      assign Ctrl_ECC_RdFIFO_RNW  = 1'b0;
      assign Ctrl_ECC_RdFIFO_Addr = 32'b0;
    end
  endgenerate

  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_AP_COL_DELAY)
      )
      mpmc_srl_delay_Ctrl_AP_Col_W
        (
         .Clk  (Clk),
         .Data ((arb_patterntype==C_WORD_WRITE_SEQ) || (arb_patterntype==C_WORD_READ_SEQ)),
         .Q    (Ctrl_AP_Col_W)
         );
  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_AP_COL_DELAY)
      )
      mpmc_srl_delay_Ctrl_AP_Col_DW
        (
         .Clk  (Clk),
         .Data ((arb_patterntype==C_DOUBLEWORD_WRITE_SEQ) || (arb_patterntype==C_DOUBLEWORD_READ_SEQ)),
         .Q    (Ctrl_AP_Col_DW)
         );
  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_AP_COL_DELAY)
      )
      mpmc_srl_delay_Ctrl_AP_Col_CL4
        (
         .Clk  (Clk),
         .Data ((arb_patterntype==C_CL4_WRITE_SEQ) || (arb_patterntype==C_CL4_READ_SEQ)),
         .Q    (Ctrl_AP_Col_CL4)
         );
  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_AP_COL_DELAY)
      )
      mpmc_srl_delay_Ctrl_AP_Col_CL8
        (
         .Clk  (Clk),
         .Data ((arb_patterntype==C_CL8_WRITE_SEQ) || (arb_patterntype==C_CL8_READ_SEQ)),
         .Q    (Ctrl_AP_Col_CL8)
         );
  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_AP_COL_DELAY)
      )
      mpmc_srl_delay_Ctrl_AP_Col_B16
        (
         .Clk  (Clk),
         .Data ((arb_patterntype==C_B16_WRITE_SEQ) || (arb_patterntype==C_B16_READ_SEQ)),
         .Q    (Ctrl_AP_Col_B16)
         );
  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_AP_COL_DELAY)
      )
      mpmc_srl_delay_Ctrl_AP_Col_B32
        (
         .Clk  (Clk),
         .Data ((arb_patterntype==C_B32_WRITE_SEQ) || (arb_patterntype==C_B32_READ_SEQ)),
         .Q    (Ctrl_AP_Col_B32)
         );
  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_AP_COL_DELAY)
      )
      mpmc_srl_delay_Ctrl_AP_Col_B64
        (
         .Clk  (Clk),
         .Data ((arb_patterntype==C_B64_WRITE_SEQ) || (arb_patterntype==C_B64_READ_SEQ)),
         .Q    (Ctrl_AP_Col_B64)
         );

  assign Ctrl_AP_Col_Burst_Length = (C_MEM_TYPE != "DDR3") ? 4'b0100 :
                                (C_MEM_DATA_WIDTH == 64) ? {(Ctrl_AP_Col_B64 | Ctrl_AP_Col_B32 | Ctrl_AP_Col_B16), 
                                                            (Ctrl_AP_Col_CL8 | Ctrl_AP_Col_CL4 | Ctrl_AP_Col_DW | Ctrl_AP_Col_W),
                                                            2'b0} : 
                                (C_MEM_DATA_WIDTH == 32) ? {(Ctrl_AP_Col_B64 | Ctrl_AP_Col_B32 | Ctrl_AP_Col_B16 | Ctrl_AP_Col_CL8), 
                                                            (Ctrl_AP_Col_CL4 | Ctrl_AP_Col_DW | Ctrl_AP_Col_W),
                                                            2'b0} : 
                                (C_MEM_DATA_WIDTH == 16) ? {(Ctrl_AP_Col_B64 | Ctrl_AP_Col_B32 | Ctrl_AP_Col_B16 | Ctrl_AP_Col_CL8 | Ctrl_AP_Col_CL4), 
                                                            (Ctrl_AP_Col_DW | Ctrl_AP_Col_W),
                                                            2'b0} : 
                                (C_MEM_DATA_WIDTH == 8 ) ? {(Ctrl_AP_Col_B64 | Ctrl_AP_Col_B32 | Ctrl_AP_Col_B16 | Ctrl_AP_Col_CL8 | Ctrl_AP_Col_CL4 | Ctrl_AP_Col_DW), 
                                                            Ctrl_AP_Col_W,
                                                            2'b0} : 4'b0100;
  generate
     for (i=0;i<C_NUM_PORTS;i=i+1) begin : instantiate_ctrl_ap_pi_addr_ce_srls
        mpmc_srl_delay
          #(
            .C_DELAY (C_CTRL_AP_PI_ADDR_CE_DELAY)
            )
            mpmc_srl_delay_Ctrl_AP_PI_Addr_CE
              (
               .Clk  (Clk),
               .Data (PI_AddrAck[i]),
               .Q    (Ctrl_AP_PI_Addr_CE[i])
         );
     end
  endgenerate

  generate
     for (i=0;i<C_ARB_PORT_ENCODING_WIDTH;i=i+1) begin : instantiate_ctrl_ap_port_select_srls
        mpmc_srl_delay
          #(
            .C_DELAY (C_CTRL_AP_PORT_SELECT_DELAY)
            )
            mpmc_srl_delay_Ctrl_AP_Port_Select
              (
               .Clk  (Clk),
               .Data (arb_whichport[i]),
               .Q    (Ctrl_AP_Port_Select[i])
               );
     end
  endgenerate

  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_AP_PIPELINE1_CE_DELAY)
      )
      mpmc_srl_delay_Ctrl_AP_Pipeline1_CE
        (
         .Clk  (Clk),
         .Data (Arb_PatternStart & ~(arb_patterntype == C_REFH_SEQ)),
         .Q    (Ctrl_AP_Pipeline1_CE)
         );

  generate
     for (i=0;i<C_ARB_PORT_ENCODING_WIDTH;i=i+1) begin : instantiate_ctrl_dp_rdfifo_whichport_srls
        mpmc_srl_delay
          #(
            .C_DELAY (C_CTRL_DP_RDFIFO_WHICHPORT_DELAY-1)
            )
            mpmc_srl_delay_Ctrl_DP_RdFIFO_WhichPort
              (
               .Clk  (Clk),
               .Data (arb_whichport[i]),
               .Q    (Ctrl_DP_RdFIFO_WhichPort[i])
               );
     end
  endgenerate

  // Create One-Hot encoded version of Arb_Which_Port_i
  port_encoder #(
    .C_NUM_PORTS        (C_NUM_PORTS),
    .C_PORT_WIDTH       (C_ARB_PORT_ENCODING_WIDTH)
  ) 
  arb_whichport_encoder (
    .Port               (Ctrl_DP_RdFIFO_WhichPort),
    .Port_Encode        (ctrl_dp_rdfifo_whichport_decode_i)
  );

  always @(posedge Clk) begin
    ctrl_dp_rdfifo_whichport_decode_r <= ctrl_dp_rdfifo_whichport_decode_i;
  end

  assign Ctrl_DP_RdFIFO_WhichPort_Decode = ctrl_dp_rdfifo_whichport_decode_r;

  always @(posedge Clk)
    arb_patterntype_d1 <= arb_patterntype;
  
  generate
     for (j=0;j<C_CTRL_DP_WRFIFO_WHICHPORT_REP;j=j+1) begin : instantiate_replicate_ctrl_dp_wrfifo_whichport
        for (i=0;i<C_ARB_PORT_ENCODING_WIDTH;i=i+1) begin : instantiate_ctrl_dp_wrfifo_whichport
           mpmc_srl_delay
             #(
               .C_DELAY (C_CTRL_DP_WRFIFO_WHICHPORT_DELAY)
               )
               mpmc_srl_delay_Ctrl_DP_WrFIFO_WhichPort
                 (
                  .Clk  (Clk),
                  .Data (arb_whichport[i]),
                  .Q    (Ctrl_DP_WrFIFO_WhichPort[j*C_ARB_PORT_ENCODING_WIDTH+i])
                  );
        end
     end
  endgenerate

  generate
     genvar r;
     for (r=0;r<C_NUM_PORTS;r=r+1) begin : instantiate_ctrl_dp_wrfifo_whichport_decode
        mpmc_srl_delay
          #(
            .C_DELAY (C_CTRL_DP_WRFIFO_WHICHPORT_DELAY)
            )
            mpmc_srl_delay_Ctrl_DP_WrFIFO_WhichPort_Decode
              (
               .Clk  (Clk),
               .Data (arb_whichport_decode[r]),
               .Q    (Ctrl_DP_WrFIFO_WhichPort_Decode[r])
               );
     end
  endgenerate


  always @(posedge Clk) begin
     ctrl_complete_i1 <= ctrl_complete;
  end
  
  generate
     for (i=0;i<C_NUM_PORTS;i=i+1) begin : instantiate_pi_arbpatterntype_pop
        always @(*)
          pi_arbpatterntype_pop[i] <= arb_whichport_decode[i] & ctrl_complete & ~ctrl_maint_enable;
     end
  endgenerate
  

  generate
    if (C_USE_MIG_V6_PHY) begin : v6_maintenance_calls

      wire                          maint_seq;
      wire                          periodic_rd_r;
      wire                          periodic_rd_ack;
      reg                           periodic_rd_wip_r;
      reg                           periodic_rd_wip_d1;
      wire                          maint_req_r;
      wire                          maint_end;
      wire                          maint_wip_ns;
      reg                           maint_wip_r;
      reg                           maint_zq_wip_r;
      wire                          maint_zq_r;
      wire                          insert_maint_r1;
      wire [7:0]                    slot_0_present;             
      wire [7:0]                    slot_1_present;
      assign slot_0_present              = 8'b000_0001;
      assign slot_1_present              = 8'b000_0000;


      // Implementing the maintenance/timer logic from MIG V6 Controller
      rank_mach #
      (
        // Parameters
        .BURST_MODE                        ("OTF"),
        .CS_WIDTH                          (1'b1),
        .DRAM_TYPE                         (C_MEM_TYPE),
        .MAINT_PRESCALER_DIV               (C_MAINT_PRESCALER_DIV),
        .nBANK_MACHS                       (1),
        .nCK_PER_CLK                       (C_NCK_PER_CLK),
        .CL                                (C_MEM_CAS_LATENCY),
        .nFAW                              (30),
        .nREFRESH_BANK                     (8),
        .nRRD                              (4),
        .nWTR                              (4),
        .PERIODIC_RD_TIMER_DIV             (C_PERIODIC_RD_TIMER_DIV),
        .RANK_BM_BV_WIDTH                  (1),
        .RANK_WIDTH                        (1),
        .RANKS                             (1),
        .PHASE_DETECT                      (C_MEM_PHASE_DETECT),//to controll periodic reads
        .REFRESH_TIMER_DIV                 (C_REFRESH_TIMER_DIV),
        .ZQ_TIMER_DIV                      (C_ZQ_TIMER_DIV)
      )
      rank_mach0
      (
        // Outputs
        .maint_req_r                     (maint_req_r),
        .periodic_rd_r                   (periodic_rd_r),
        .periodic_rd_rank_r              (), // Ignored, only using 1 rank for MPMC.
        .inhbt_act_faw_r                 (),
        .inhbt_rd_r                      (),
        .wtr_inhbt_config_r              (),
        .maint_rank_r                    (), // Ignored, only using 1 rank for MPMC.
        .maint_zq_r                      (maint_zq_r),
        // Inputs
        .act_this_rank_r                 (1'b0),
        .app_periodic_rd_req             (1'b0),
        .app_ref_req                     (1'b0),
        .app_zq_req                      (1'b0),
        .clk                             (Clk),
        .dfi_init_complete               (PhyIF_Ctrl_InitDone),
        .insert_maint_r1                 (insert_maint_r1),
        .maint_wip_r                     (maint_wip_r),
        .periodic_rd_ack_r               (periodic_rd_ack),
        .rank_busy_r                     (~ctrl_idle),            
        .rd_this_rank_r                  (Ctrl_DFI_RdData_En),     
        .rst                             (Rst),
        .sending_col                     (1'b1),
        .sending_row                     (1'b0),
        .slot_0_present                  (slot_0_present[7:0]),
        .slot_1_present                  (slot_1_present[7:0]),
        .wr_this_rank_r                  (1'b0)
      );
    
      assign maint_seq = arb_patterntype_decode[C_REFH_SEQ];
      /////////////////////////////////////////////////////////////////////////
      // Periodic Read Logic: Takes priority over refresh and zqcs
      /////////////////////////////////////////////////////////////////////////
      // If a read has not occured within the inteval specified, then
      // periodic_rd_req signal will go high. The periodic 
      assign periodic_rd_req = periodic_rd_r;
      // A periodic read work in progress will occur if a Arb_PatternStart has
      // pulsed and the Arb_PatternType is a refresh sequence and a periodic
      // rd is requested.
      always @(posedge Clk) begin
        periodic_rd_wip_r <= ~Rst && ~ctrl_complete 
                            && ((periodic_rd_req && Arb_PatternStart 
                                 && maint_seq) || periodic_rd_wip_r);
        periodic_rd_wip_d1 <= periodic_rd_wip_r;
      end
     
      // The end of a periodic read request is signaled with the
      // periodic_rd_ack 
      assign periodic_rd_ack = periodic_rd_wip_r & ~periodic_rd_wip_d1;

      /////////////////////////////////////////////////////////////////////////
      // Refresh/ZQCS request logic
      assign insert_maint_r1 = maint_seq & Arb_PatternStart & maint_wip_r 
                               & ~periodic_rd_wip_r;
      assign maint_end = ctrl_complete & maint_seq & maint_wip_r 
                         & ~periodic_rd_wip_r;
        
      assign maint_wip_ns = ~Rst && ~maint_end && (maint_wip_r || maint_req_r);

      always @(posedge Clk) begin
        maint_wip_r <= maint_wip_ns;
      end

      assign ctrl_maint = maint_wip_r | periodic_rd_req;

      assign maint_zq_req = maint_wip_r & maint_zq_r & ~maint_zq_wip_r;
      always @(posedge Clk) begin
        maint_zq_wip_r <= ~Rst && ~ctrl_complete 
                            && ((maint_zq_req && Arb_PatternStart 
                                 && maint_seq && ~periodic_rd_req) 
                                || maint_zq_wip_r);
      end

      assign maint_zq_wip = maint_zq_wip_r;
      assign ctrl_periodic_rd_mask_i = periodic_rd_wip_r & ctrl_maint_enable;

    end
    else begin : refresh_logic
      // InitDone high and and ctrl_initalizememory high indicates memory init has
      // just finished, issue a refresh 
      always @(posedge Clk) begin
        Ctrl_Refresh_Flag <= (ctrl_refresh_cnt == (C_REFRESH_CNT_MAX-1));
      end

      // Auto Refresh Logic
      always @(posedge Clk) begin
         if (Rst | Ctrl_Refresh_Flag)
           ctrl_refresh_cnt <= 0;
         else
           ctrl_refresh_cnt <= ctrl_refresh_cnt + 1'b1;
      end
      always @(posedge Clk) begin
        if (Rst)
          ctrl_refresh_i1 <= 1'b0;
        else
          ctrl_refresh_i1 <= ~(arb_patterntype_decode[C_REFH_SEQ] & ctrl_complete) & ((Ctrl_Refresh_Flag & ~ctrl_initializememory) | ctrl_refresh_i1);
      end
      assign ctrl_maint = ctrl_refresh_i1;
      assign periodic_rd_req = 1'b0;
      assign maint_zq_req = 1'b0;
      assign maint_zq_wip = 1'b0;
      assign ctrl_periodic_rd_mask_i = 1'b0;
    end
  endgenerate
  
  always @(posedge Clk) begin
    if (Rst)
      ctrl_maint_enable_i <= 1'b1;
    else
      ctrl_maint_enable_i <= (ctrl_complete & ~arb_patterntype_decode[C_REFH_SEQ]) | 
                               (ctrl_maint_enable_i & 
                                ~(Arb_PatternStart & ~arb_patterntype_decode[C_REFH_SEQ]));
  end
  assign ctrl_maint_enable = ctrl_maint_enable_i;

  mpmc_srl_delay
    #(
      .C_DELAY (C_CTRL_DP_RDFIFO_WHICHPORT_DELAY+1)
      )
      mpmc_srl_delay_Ctrl_Periodic_Rd_Mask
        (
         .Clk  (Clk),
         .Data (ctrl_periodic_rd_mask_i),
         .Q    (Ctrl_Periodic_Rd_Mask)
         );
  // Stall Logic
  assign ctrl_stall = 1'b0;
  
  // Idle Logic
  always @(posedge Clk) begin
    if (Rst)
      ctrl_idle_i1 <= 1'b1;
    else
      ctrl_idle_i1 <= ~Arb_PatternStart & (ctrl_complete_i1 | ctrl_idle_i1);
  end

  // arbiter pipeline requires ctrl_idle to be delayed
  generate
     if (C_ARB_PIPELINE == 0) begin : no_ctrl_idle_i1a_pipeline
        always @(ctrl_idle_i1) begin
           ctrl_idle_i1a <= ctrl_idle_i1;
        end
     end
     else begin : ctrl_idle_i1a_pipeline
        always @(posedge Clk) begin
           if (Rst) ctrl_idle_i1a <= 1;
           else     ctrl_idle_i1a <= ctrl_idle_i1 & ~Arb_PatternStart;
        end
     end
  endgenerate   
       
       
  always @(*) begin
     ctrl_idle_i2 <= ctrl_idle_i1a & ~Arb_PatternStart & ~arb_patternstart_i;
  end
  assign ctrl_idle = ctrl_idle_i2;
  assign ctrl_almostidle = (ctrl_idle_i1a | Rst | ctrl_idle_i1 )  & ~Arb_PatternStart & ~arb_patternstart_i;
  
  always @(posedge Clk) begin
     ctrl_initializememory <= Rst | ~PhyIF_Ctrl_InitDone;
  end
  
  ctrl_path
    #(
      .C_FAMILY                     (C_FAMILY),
      .C_IS_DDR                     (C_IS_DDR),
      .C_INCLUDE_ECC_SUPPORT        (C_INCLUDE_ECC_SUPPORT),
      .C_SKIP_1_VALUE               (C_SKIP_1_VALUE),
      .C_SKIP_2_VALUE               (C_SKIP_2_VALUE),
      .C_SKIP_3_VALUE               (C_SKIP_3_VALUE),
      .C_SKIP_4_VALUE               (C_SKIP_4_VALUE),
      .C_SKIP_5_VALUE               (C_SKIP_5_VALUE),
      .C_SKIP_6_VALUE               (C_SKIP_6_VALUE),
      .C_SKIP_7_VALUE               (C_SKIP_7_VALUE),
      .C_ARB_PATTERN_TYPE_WIDTH     (C_ARB_PATTERN_TYPE_WIDTH),
      .C_ARB_PATTERN_TYPE_DECODE_WIDTH (C_ARB_PATTERN_TYPE_DECODE_WIDTH),
      .C_NUM_CTRL_SIGNALS           (C_NUM_CTRL_SIGNALS),
      .C_USE_FIXED_BASEADDR_CTRL    (C_USE_FIXED_BASEADDR_CTRL),
      .C_B16_REPEAT_CNT             (C_B16_REPEAT_CNT),
      .C_B32_REPEAT_CNT             (C_B32_REPEAT_CNT),
      .C_B64_REPEAT_CNT             (C_B64_REPEAT_CNT),
      .C_ZQCS_REPEAT_CNT            (C_ZQCS_REPEAT_CNT),
      .C_BASEADDR_CTRL0             (C_BASEADDR_CTRL0),
      .C_HIGHADDR_CTRL0             (C_HIGHADDR_CTRL0),
      .C_BASEADDR_CTRL1             (C_BASEADDR_CTRL1),
      .C_HIGHADDR_CTRL1             (C_HIGHADDR_CTRL1),
      .C_BASEADDR_CTRL2             (C_BASEADDR_CTRL2),
      .C_HIGHADDR_CTRL2             (C_HIGHADDR_CTRL2),
      .C_BASEADDR_CTRL3             (C_BASEADDR_CTRL3),
      .C_HIGHADDR_CTRL3             (C_HIGHADDR_CTRL3),
      .C_BASEADDR_CTRL4             (C_BASEADDR_CTRL4),
      .C_HIGHADDR_CTRL4             (C_HIGHADDR_CTRL4),
      .C_BASEADDR_CTRL5             (C_BASEADDR_CTRL5),
      .C_HIGHADDR_CTRL5             (C_HIGHADDR_CTRL5),
      .C_BASEADDR_CTRL6             (C_BASEADDR_CTRL6),
      .C_HIGHADDR_CTRL6             (C_HIGHADDR_CTRL6),
      .C_BASEADDR_CTRL7             (C_BASEADDR_CTRL7),
      .C_HIGHADDR_CTRL7             (C_HIGHADDR_CTRL7),
      .C_BASEADDR_CTRL8             (C_BASEADDR_CTRL8),
      .C_HIGHADDR_CTRL8             (C_HIGHADDR_CTRL8),
      .C_BASEADDR_CTRL9             (C_BASEADDR_CTRL9),
      .C_HIGHADDR_CTRL9             (C_HIGHADDR_CTRL9),
      .C_BASEADDR_CTRL10            (C_BASEADDR_CTRL10),
      .C_HIGHADDR_CTRL10            (C_HIGHADDR_CTRL10),
      .C_BASEADDR_CTRL11            (C_BASEADDR_CTRL11),
      .C_HIGHADDR_CTRL11            (C_HIGHADDR_CTRL11),
      .C_BASEADDR_CTRL12            (C_BASEADDR_CTRL12),
      .C_HIGHADDR_CTRL12            (C_HIGHADDR_CTRL12),
      .C_BASEADDR_CTRL13            (C_BASEADDR_CTRL13),
      .C_HIGHADDR_CTRL13            (C_HIGHADDR_CTRL13),
      .C_BASEADDR_CTRL14            (C_BASEADDR_CTRL14),
      .C_HIGHADDR_CTRL14            (C_HIGHADDR_CTRL14),
      .C_BASEADDR_CTRL15            (C_BASEADDR_CTRL15),
      .C_HIGHADDR_CTRL15            (C_HIGHADDR_CTRL15),
      .C_BASEADDR_CTRL16            (C_BASEADDR_CTRL16),
      .C_HIGHADDR_CTRL16            (C_HIGHADDR_CTRL16),
      .C_WORD_WRITE_SEQ             (C_WORD_WRITE_SEQ),
      .C_WORD_READ_SEQ              (C_WORD_READ_SEQ),
      .C_DOUBLEWORD_WRITE_SEQ       (C_DOUBLEWORD_WRITE_SEQ),
      .C_DOUBLEWORD_READ_SEQ        (C_DOUBLEWORD_READ_SEQ),
      .C_CL4_WRITE_SEQ              (C_CL4_WRITE_SEQ),
      .C_CL4_READ_SEQ               (C_CL4_READ_SEQ),
      .C_CL8_WRITE_SEQ              (C_CL8_WRITE_SEQ),
      .C_CL8_READ_SEQ               (C_CL8_READ_SEQ),
      .C_B16_WRITE_SEQ              (C_B16_WRITE_SEQ),
      .C_B16_READ_SEQ               (C_B16_READ_SEQ),
      .C_B32_WRITE_SEQ              (C_B32_WRITE_SEQ),
      .C_B32_READ_SEQ               (C_B32_READ_SEQ),
      .C_B64_WRITE_SEQ              (C_B64_WRITE_SEQ),
      .C_B64_READ_SEQ               (C_B64_READ_SEQ),
      .C_REFH_SEQ                   (C_REFH_SEQ),
      .C_NOP_SEQ                    (C_NOP_SEQ),
      .C_CTRL_Q0_DELAY              (C_CTRL_Q0_DELAY),
      .C_CTRL_Q1_DELAY              (C_CTRL_Q1_DELAY),
      .C_CTRL_Q2_DELAY              (C_CTRL_Q2_DELAY),
      .C_CTRL_Q3_DELAY              (C_CTRL_Q3_DELAY),
      .C_CTRL_Q4_DELAY              (C_CTRL_Q4_DELAY),
      .C_CTRL_Q5_DELAY              (C_CTRL_Q5_DELAY),
      .C_CTRL_Q6_DELAY              (C_CTRL_Q6_DELAY),
      .C_CTRL_Q7_DELAY              (C_CTRL_Q7_DELAY),
      .C_CTRL_Q8_DELAY              (C_CTRL_Q8_DELAY),
      .C_CTRL_Q9_DELAY              (C_CTRL_Q9_DELAY),
      .C_CTRL_Q10_DELAY             (C_CTRL_Q10_DELAY),
      .C_CTRL_Q11_DELAY             (C_CTRL_Q11_DELAY),
      .C_CTRL_Q12_DELAY             (C_CTRL_Q12_DELAY),
      .C_CTRL_Q13_DELAY             (C_CTRL_Q13_DELAY),
      .C_CTRL_Q14_DELAY             (C_CTRL_Q14_DELAY),
      .C_CTRL_Q15_DELAY             (C_CTRL_Q15_DELAY),
      .C_CTRL_Q16_DELAY             (C_CTRL_Q16_DELAY),
      .C_CTRL_Q17_DELAY             (C_CTRL_Q17_DELAY),
      .C_CTRL_Q18_DELAY             (C_CTRL_Q18_DELAY),
      .C_CTRL_Q19_DELAY             (C_CTRL_Q19_DELAY),
      .C_CTRL_Q20_DELAY             (C_CTRL_Q20_DELAY),
      .C_CTRL_Q21_DELAY             (C_CTRL_Q21_DELAY),
      .C_CTRL_Q22_DELAY             (C_CTRL_Q22_DELAY),
      .C_CTRL_Q23_DELAY             (C_CTRL_Q23_DELAY),
      .C_CTRL_Q24_DELAY             (C_CTRL_Q24_DELAY),
      .C_CTRL_Q25_DELAY             (C_CTRL_Q25_DELAY),
      .C_CTRL_Q26_DELAY             (C_CTRL_Q26_DELAY),
      .C_CTRL_Q27_DELAY             (C_CTRL_Q27_DELAY),
      .C_CTRL_Q28_DELAY             (C_CTRL_Q28_DELAY),
      .C_CTRL_Q29_DELAY             (C_CTRL_Q29_DELAY),
      .C_CTRL_Q30_DELAY             (C_CTRL_Q30_DELAY),
      .C_CTRL_Q31_DELAY             (C_CTRL_Q31_DELAY),
      .C_CTRL_Q32_DELAY             (C_CTRL_Q32_DELAY),
      .C_CTRL_Q33_DELAY             (C_CTRL_Q33_DELAY),
      .C_CTRL_Q34_DELAY             (C_CTRL_Q34_DELAY),
      .C_CTRL_Q35_DELAY             (C_CTRL_Q35_DELAY),
      .C_CTRL_IS_WRITE_INDEX        (C_CTRL_IS_WRITE_INDEX),
      .C_CTRL_BRAM_SRVAL            (C_CTRL_BRAM_SRVAL),
      .C_CTRL_BRAM_INIT_00          (C_CTRL_BRAM_INIT_00),
      .C_CTRL_BRAM_INIT_01          (C_CTRL_BRAM_INIT_01),
      .C_CTRL_BRAM_INIT_02          (C_CTRL_BRAM_INIT_02),
      .C_CTRL_BRAM_INIT_03          (C_CTRL_BRAM_INIT_03),
      .C_CTRL_BRAM_INIT_04          (C_CTRL_BRAM_INIT_04),
      .C_CTRL_BRAM_INIT_05          (C_CTRL_BRAM_INIT_05),
      .C_CTRL_BRAM_INIT_06          (C_CTRL_BRAM_INIT_06),
      .C_CTRL_BRAM_INIT_07          (C_CTRL_BRAM_INIT_07),
      .C_CTRL_BRAM_INIT_08          (C_CTRL_BRAM_INIT_08),
      .C_CTRL_BRAM_INIT_09          (C_CTRL_BRAM_INIT_09),
      .C_CTRL_BRAM_INIT_0A          (C_CTRL_BRAM_INIT_0A),
      .C_CTRL_BRAM_INIT_0B          (C_CTRL_BRAM_INIT_0B),
      .C_CTRL_BRAM_INIT_0C          (C_CTRL_BRAM_INIT_0C),
      .C_CTRL_BRAM_INIT_0D          (C_CTRL_BRAM_INIT_0D),
      .C_CTRL_BRAM_INIT_0E          (C_CTRL_BRAM_INIT_0E),
      .C_CTRL_BRAM_INIT_0F          (C_CTRL_BRAM_INIT_0F),
      .C_CTRL_BRAM_INIT_10          (C_CTRL_BRAM_INIT_10),
      .C_CTRL_BRAM_INIT_11          (C_CTRL_BRAM_INIT_11),
      .C_CTRL_BRAM_INIT_12          (C_CTRL_BRAM_INIT_12),
      .C_CTRL_BRAM_INIT_13          (C_CTRL_BRAM_INIT_13),
      .C_CTRL_BRAM_INIT_14          (C_CTRL_BRAM_INIT_14),
      .C_CTRL_BRAM_INIT_15          (C_CTRL_BRAM_INIT_15),
      .C_CTRL_BRAM_INIT_16          (C_CTRL_BRAM_INIT_16),
      .C_CTRL_BRAM_INIT_17          (C_CTRL_BRAM_INIT_17),
      .C_CTRL_BRAM_INIT_18          (C_CTRL_BRAM_INIT_18),
      .C_CTRL_BRAM_INIT_19          (C_CTRL_BRAM_INIT_19),
      .C_CTRL_BRAM_INIT_1A          (C_CTRL_BRAM_INIT_1A),
      .C_CTRL_BRAM_INIT_1B          (C_CTRL_BRAM_INIT_1B),
      .C_CTRL_BRAM_INIT_1C          (C_CTRL_BRAM_INIT_1C),
      .C_CTRL_BRAM_INIT_1D          (C_CTRL_BRAM_INIT_1D),
      .C_CTRL_BRAM_INIT_1E          (C_CTRL_BRAM_INIT_1E),
      .C_CTRL_BRAM_INIT_1F          (C_CTRL_BRAM_INIT_1F),
      .C_CTRL_BRAM_INIT_20          (C_CTRL_BRAM_INIT_20),
      .C_CTRL_BRAM_INIT_21          (C_CTRL_BRAM_INIT_21),
      .C_CTRL_BRAM_INIT_22          (C_CTRL_BRAM_INIT_22),
      .C_CTRL_BRAM_INIT_23          (C_CTRL_BRAM_INIT_23),
      .C_CTRL_BRAM_INIT_24          (C_CTRL_BRAM_INIT_24),
      .C_CTRL_BRAM_INIT_25          (C_CTRL_BRAM_INIT_25),
      .C_CTRL_BRAM_INIT_26          (C_CTRL_BRAM_INIT_26),
      .C_CTRL_BRAM_INIT_27          (C_CTRL_BRAM_INIT_27),
      .C_CTRL_BRAM_INIT_28          (C_CTRL_BRAM_INIT_28),
      .C_CTRL_BRAM_INIT_29          (C_CTRL_BRAM_INIT_29),
      .C_CTRL_BRAM_INIT_2A          (C_CTRL_BRAM_INIT_2A),
      .C_CTRL_BRAM_INIT_2B          (C_CTRL_BRAM_INIT_2B),
      .C_CTRL_BRAM_INIT_2C          (C_CTRL_BRAM_INIT_2C),
      .C_CTRL_BRAM_INIT_2D          (C_CTRL_BRAM_INIT_2D),
      .C_CTRL_BRAM_INIT_2E          (C_CTRL_BRAM_INIT_2E),
      .C_CTRL_BRAM_INIT_2F          (C_CTRL_BRAM_INIT_2F),
      .C_CTRL_BRAM_INIT_30          (C_CTRL_BRAM_INIT_30),
      .C_CTRL_BRAM_INIT_31          (C_CTRL_BRAM_INIT_31),
      .C_CTRL_BRAM_INIT_32          (C_CTRL_BRAM_INIT_32),
      .C_CTRL_BRAM_INIT_33          (C_CTRL_BRAM_INIT_33),
      .C_CTRL_BRAM_INIT_34          (C_CTRL_BRAM_INIT_34),
      .C_CTRL_BRAM_INIT_35          (C_CTRL_BRAM_INIT_35),
      .C_CTRL_BRAM_INIT_36          (C_CTRL_BRAM_INIT_36),
      .C_CTRL_BRAM_INIT_37          (C_CTRL_BRAM_INIT_37),
      .C_CTRL_BRAM_INIT_38          (C_CTRL_BRAM_INIT_38),
      .C_CTRL_BRAM_INIT_39          (C_CTRL_BRAM_INIT_39),
      .C_CTRL_BRAM_INIT_3A          (C_CTRL_BRAM_INIT_3A),
      .C_CTRL_BRAM_INIT_3B          (C_CTRL_BRAM_INIT_3B),
      .C_CTRL_BRAM_INIT_3C          (C_CTRL_BRAM_INIT_3C),
      .C_CTRL_BRAM_INIT_3D          (C_CTRL_BRAM_INIT_3D),
      .C_CTRL_BRAM_INIT_3E          (C_CTRL_BRAM_INIT_3E),
      .C_CTRL_BRAM_INIT_3F          (C_CTRL_BRAM_INIT_3F),
      .C_CTRL_BRAM_INITP_00         (C_CTRL_BRAM_INITP_00),
      .C_CTRL_BRAM_INITP_01         (C_CTRL_BRAM_INITP_01),
      .C_CTRL_BRAM_INITP_02         (C_CTRL_BRAM_INITP_02),
      .C_CTRL_BRAM_INITP_03         (C_CTRL_BRAM_INITP_03),
      .C_CTRL_BRAM_INITP_04         (C_CTRL_BRAM_INITP_04),
      .C_CTRL_BRAM_INITP_05         (C_CTRL_BRAM_INITP_05),
      .C_CTRL_BRAM_INITP_06         (C_CTRL_BRAM_INITP_06),
      .C_CTRL_BRAM_INITP_07         (C_CTRL_BRAM_INITP_07),
      .C_MEM_TYPE                   (C_MEM_TYPE)
       )
      ctrl_path_0
        (
         .Clk                    (Clk),
         .Rst                    (Rst),
         .Arb_RdModWr            (arb_rdmodwr),
         .Arb_PatternType        (arb_patterntype),
         .Arb_PatternType_Decode (arb_patterntype_decode),
         .Arb_PatternStart       (Arb_PatternStart),
         .Ctrl_Idle              (ctrl_idle),
         .Ctrl_InitializeMemory  (ctrl_initializememory),
         .Ctrl_Stall             (ctrl_stall),
         .Ctrl_Complete          (ctrl_complete),
         .Ctrl_Skip_Value        (ctrl_skip_value),
         .Ctrl_AP_Col_Cnt_Load   (Ctrl_AP_Col_Cnt_Load),
         .Ctrl_Repeat4           (ctrl_repeat4),
         .Periodic_Rd_Req        (periodic_rd_req),
         .Maint_ZQ_Req           (maint_zq_req),
         .Maint_ZQ_WIP           (maint_zq_wip),
         .Ignore_Complete        (ignore_complete),
         .Ctrl_BRAM_Out          (ctrl_bram_out),
         .Assert_All_CS1         (assert_all_cs1)
         );

  assign Ctrl_AP_Assert_All_CS = assert_all_cs1;
  
  arbiter
    #(
      .C_FAMILY                        (C_FAMILY),
      .C_USE_INIT_PUSH                 (C_USE_INIT_PUSH),
      .C_INCLUDE_ECC_SUPPORT           (C_INCLUDE_ECC_SUPPORT),
      .C_NUM_PORTS                     (C_NUM_PORTS),
      .C_PI_DATA_WIDTH                 (C_PI_DATA_WIDTH),
      .C_PIPELINE_ADDRACK              (C_PIPELINE_ADDRACK),
      .C_CP_PIPELINE                   (C_CP_PIPELINE),
      .C_MAX_REQ_ALLOWED_INT           (C_MAX_REQ_ALLOWED_INT),
      .C_ARB_PORT_ENCODING_WIDTH       (C_ARB_PORT_ENCODING_WIDTH),
      .C_ARB_PATTERN_TYPE_WIDTH        (C_ARB_PATTERN_TYPE_WIDTH),
      .C_ARB_PATTERN_TYPE_DECODE_WIDTH (C_ARB_PATTERN_TYPE_DECODE_WIDTH),
      .C_ARB_SEQUENCE_ENCODING_WIDTH   (C_ARB_SEQUENCE_ENCODING_WIDTH),
      .C_ARB_BRAM_ADDR_WIDTH           (C_ARB_BRAM_ADDR_WIDTH),
      .C_ARB_PIPELINE                  (C_ARB_PIPELINE),
      .C_REQ_PENDING_CNTR_WIDTH        (C_REQ_PENDING_CNTR_WIDTH),
      .C_ARB0_ALGO                     (C_ARB0_ALGO),
      .C_BASEADDR_ARB0                 (C_BASEADDR_ARB0),
      .C_HIGHADDR_ARB0                 (C_HIGHADDR_ARB0),
      .C_BASEADDR_ARB1                 (C_BASEADDR_ARB1),
      .C_HIGHADDR_ARB1                 (C_HIGHADDR_ARB1),
      .C_BASEADDR_ARB2                 (C_BASEADDR_ARB2),
      .C_HIGHADDR_ARB2                 (C_HIGHADDR_ARB2),
      .C_BASEADDR_ARB3                 (C_BASEADDR_ARB3),
      .C_HIGHADDR_ARB3                 (C_HIGHADDR_ARB3),
      .C_BASEADDR_ARB4                 (C_BASEADDR_ARB4),
      .C_HIGHADDR_ARB4                 (C_HIGHADDR_ARB4),
      .C_BASEADDR_ARB5                 (C_BASEADDR_ARB5),
      .C_HIGHADDR_ARB5                 (C_HIGHADDR_ARB5),
      .C_BASEADDR_ARB6                 (C_BASEADDR_ARB6),
      .C_HIGHADDR_ARB6                 (C_HIGHADDR_ARB6),
      .C_BASEADDR_ARB7                 (C_BASEADDR_ARB7),
      .C_HIGHADDR_ARB7                 (C_HIGHADDR_ARB7),
      .C_BASEADDR_ARB8                 (C_BASEADDR_ARB8),
      .C_HIGHADDR_ARB8                 (C_HIGHADDR_ARB8),
      .C_BASEADDR_ARB9                 (C_BASEADDR_ARB9),
      .C_HIGHADDR_ARB9                 (C_HIGHADDR_ARB9),
      .C_BASEADDR_ARB10                (C_BASEADDR_ARB10),
      .C_HIGHADDR_ARB10                (C_HIGHADDR_ARB10),
      .C_BASEADDR_ARB11                (C_BASEADDR_ARB11),
      .C_HIGHADDR_ARB11                (C_HIGHADDR_ARB11),
      .C_BASEADDR_ARB12                (C_BASEADDR_ARB12),
      .C_HIGHADDR_ARB12                (C_HIGHADDR_ARB12),
      .C_BASEADDR_ARB13                (C_BASEADDR_ARB13),
      .C_HIGHADDR_ARB13                (C_HIGHADDR_ARB13),
      .C_BASEADDR_ARB14                (C_BASEADDR_ARB14),
      .C_HIGHADDR_ARB14                (C_HIGHADDR_ARB14),
      .C_BASEADDR_ARB15                (C_BASEADDR_ARB15),
      .C_HIGHADDR_ARB15                (C_HIGHADDR_ARB15),
      .C_ARB_BRAM_SRVAL_A              (C_ARB_BRAM_SRVAL_A),
      .C_ARB_BRAM_SRVAL_B              (C_ARB_BRAM_SRVAL_B),
      .C_ARB_BRAM_INIT_00              (C_ARB_BRAM_INIT_00),
      .C_ARB_BRAM_INIT_01              (C_ARB_BRAM_INIT_01),
      .C_ARB_BRAM_INIT_02              (C_ARB_BRAM_INIT_02),
      .C_ARB_BRAM_INIT_03              (C_ARB_BRAM_INIT_03),
      .C_ARB_BRAM_INIT_04              (C_ARB_BRAM_INIT_04),
      .C_ARB_BRAM_INIT_05              (C_ARB_BRAM_INIT_05),
      .C_ARB_BRAM_INIT_06              (C_ARB_BRAM_INIT_06),
      .C_ARB_BRAM_INIT_07              (C_ARB_BRAM_INIT_07),
      .C_ARB_BRAM_INIT_08              (C_ARB_BRAM_INIT_08),
      .C_ARB_BRAM_INIT_09              (C_ARB_BRAM_INIT_09),
      .C_ARB_BRAM_INIT_0A              (C_ARB_BRAM_INIT_0A),
      .C_ARB_BRAM_INIT_0B              (C_ARB_BRAM_INIT_0B),
      .C_ARB_BRAM_INIT_0C              (C_ARB_BRAM_INIT_0C),
      .C_ARB_BRAM_INIT_0D              (C_ARB_BRAM_INIT_0D),
      .C_ARB_BRAM_INIT_0E              (C_ARB_BRAM_INIT_0E),
      .C_ARB_BRAM_INIT_0F              (C_ARB_BRAM_INIT_0F),
      .C_ARB_BRAM_INIT_10              (C_ARB_BRAM_INIT_10),
      .C_ARB_BRAM_INIT_11              (C_ARB_BRAM_INIT_11),
      .C_ARB_BRAM_INIT_12              (C_ARB_BRAM_INIT_12),
      .C_ARB_BRAM_INIT_13              (C_ARB_BRAM_INIT_13),
      .C_ARB_BRAM_INIT_14              (C_ARB_BRAM_INIT_14),
      .C_ARB_BRAM_INIT_15              (C_ARB_BRAM_INIT_15),
      .C_ARB_BRAM_INIT_16              (C_ARB_BRAM_INIT_16),
      .C_ARB_BRAM_INIT_17              (C_ARB_BRAM_INIT_17),
      .C_ARB_BRAM_INIT_18              (C_ARB_BRAM_INIT_18),
      .C_ARB_BRAM_INIT_19              (C_ARB_BRAM_INIT_19),
      .C_ARB_BRAM_INIT_1A              (C_ARB_BRAM_INIT_1A),
      .C_ARB_BRAM_INIT_1B              (C_ARB_BRAM_INIT_1B),
      .C_ARB_BRAM_INIT_1C              (C_ARB_BRAM_INIT_1C),
      .C_ARB_BRAM_INIT_1D              (C_ARB_BRAM_INIT_1D),
      .C_ARB_BRAM_INIT_1E              (C_ARB_BRAM_INIT_1E),
      .C_ARB_BRAM_INIT_1F              (C_ARB_BRAM_INIT_1F),
      .C_ARB_BRAM_INIT_20              (C_ARB_BRAM_INIT_20),
      .C_ARB_BRAM_INIT_21              (C_ARB_BRAM_INIT_21),
      .C_ARB_BRAM_INIT_22              (C_ARB_BRAM_INIT_22),
      .C_ARB_BRAM_INIT_23              (C_ARB_BRAM_INIT_23),
      .C_ARB_BRAM_INIT_24              (C_ARB_BRAM_INIT_24),
      .C_ARB_BRAM_INIT_25              (C_ARB_BRAM_INIT_25),
      .C_ARB_BRAM_INIT_26              (C_ARB_BRAM_INIT_26),
      .C_ARB_BRAM_INIT_27              (C_ARB_BRAM_INIT_27),
      .C_ARB_BRAM_INIT_28              (C_ARB_BRAM_INIT_28),
      .C_ARB_BRAM_INIT_29              (C_ARB_BRAM_INIT_29),
      .C_ARB_BRAM_INIT_2A              (C_ARB_BRAM_INIT_2A),
      .C_ARB_BRAM_INIT_2B              (C_ARB_BRAM_INIT_2B),
      .C_ARB_BRAM_INIT_2C              (C_ARB_BRAM_INIT_2C),
      .C_ARB_BRAM_INIT_2D              (C_ARB_BRAM_INIT_2D),
      .C_ARB_BRAM_INIT_2E              (C_ARB_BRAM_INIT_2E),
      .C_ARB_BRAM_INIT_2F              (C_ARB_BRAM_INIT_2F),
      .C_ARB_BRAM_INIT_30              (C_ARB_BRAM_INIT_30),
      .C_ARB_BRAM_INIT_31              (C_ARB_BRAM_INIT_31),
      .C_ARB_BRAM_INIT_32              (C_ARB_BRAM_INIT_32),
      .C_ARB_BRAM_INIT_33              (C_ARB_BRAM_INIT_33),
      .C_ARB_BRAM_INIT_34              (C_ARB_BRAM_INIT_34),
      .C_ARB_BRAM_INIT_35              (C_ARB_BRAM_INIT_35),
      .C_ARB_BRAM_INIT_36              (C_ARB_BRAM_INIT_36),
      .C_ARB_BRAM_INIT_37              (C_ARB_BRAM_INIT_37),
      .C_ARB_BRAM_INIT_38              (C_ARB_BRAM_INIT_38),
      .C_ARB_BRAM_INIT_39              (C_ARB_BRAM_INIT_39),
      .C_ARB_BRAM_INIT_3A              (C_ARB_BRAM_INIT_3A),
      .C_ARB_BRAM_INIT_3B              (C_ARB_BRAM_INIT_3B),
      .C_ARB_BRAM_INIT_3C              (C_ARB_BRAM_INIT_3C),
      .C_ARB_BRAM_INIT_3D              (C_ARB_BRAM_INIT_3D),
      .C_ARB_BRAM_INIT_3E              (C_ARB_BRAM_INIT_3E),
      .C_ARB_BRAM_INIT_3F              (C_ARB_BRAM_INIT_3F),
      .C_ARB_BRAM_INITP_00             (C_ARB_BRAM_INITP_00),
      .C_ARB_BRAM_INITP_01             (C_ARB_BRAM_INITP_01),
      .C_ARB_BRAM_INITP_02             (C_ARB_BRAM_INITP_02),
      .C_ARB_BRAM_INITP_03             (C_ARB_BRAM_INITP_03),
      .C_ARB_BRAM_INITP_04             (C_ARB_BRAM_INITP_04),
      .C_ARB_BRAM_INITP_05             (C_ARB_BRAM_INITP_05),
      .C_ARB_BRAM_INITP_06             (C_ARB_BRAM_INITP_06),
      .C_ARB_BRAM_INITP_07             (C_ARB_BRAM_INITP_07),
      .C_WORD_WRITE_SEQ                (C_WORD_WRITE_SEQ),
      .C_WORD_READ_SEQ                 (C_WORD_READ_SEQ),
      .C_DOUBLEWORD_WRITE_SEQ          (C_DOUBLEWORD_WRITE_SEQ),
      .C_DOUBLEWORD_READ_SEQ           (C_DOUBLEWORD_READ_SEQ),
      .C_CL4_WRITE_SEQ                 (C_CL4_WRITE_SEQ),
      .C_CL4_READ_SEQ                  (C_CL4_READ_SEQ),
      .C_CL8_WRITE_SEQ                 (C_CL8_WRITE_SEQ),
      .C_CL8_READ_SEQ                  (C_CL8_READ_SEQ),
      .C_B16_WRITE_SEQ                 (C_B16_WRITE_SEQ),
      .C_B16_READ_SEQ                  (C_B16_READ_SEQ),
      .C_B32_WRITE_SEQ                 (C_B32_WRITE_SEQ),
      .C_B32_READ_SEQ                  (C_B32_READ_SEQ),
      .C_B64_WRITE_SEQ                 (C_B64_WRITE_SEQ),
      .C_B64_READ_SEQ                  (C_B64_READ_SEQ),
      .C_REFH_SEQ                      (C_REFH_SEQ),
      .C_NOP_SEQ                       (C_NOP_SEQ),
      .C_PORT_FOR_WRITE_TRAINING_PATTERN(C_PORT_FOR_WRITE_TRAINING_PATTERN)
      )
      arbiter_0
        (
         .Clk                       (Clk),
         .Rst                       (Rst),
         .PI_AddrReq                (PI_AddrReq),
         .PI_Size                   (PI_Size),
         .PI_RNW                    (PI_RNW),
         .PI_RdModWr                (PI_RdModWr),
         .PI_AddrAck                (PI_AddrAck),
         .PI_ArbPatternType_Pop     (pi_arbpatterntype_pop),
         .Ctrl_InitializeMemory     (ctrl_initializememory),
         .Ctrl_Maint                (ctrl_maint),
         .Ctrl_Maint_Enable       (ctrl_maint_enable),
         .Ctrl_Complete             (ctrl_complete),
         .Ctrl_Idle                 (ctrl_idle),
         .Ctrl_AlmostIdle           (ctrl_almostidle),
         .Ctrl_AP_Pipeline1_CE      (Ctrl_AP_Pipeline1_CE),
         .PhyIF_Ctrl_InitDone       (PhyIF_Ctrl_InitDone),
         .DP_Ctrl_RdFIFO_AlmostFull (DP_Ctrl_RdFIFO_AlmostFull),
         .Arb_Sequence              (Arb_Sequence),
         .Arb_LoadSequence          (Arb_LoadSequence),
         .Arb_PatternStart_i        (arb_patternstart_i),
         .Arb_PatternStart          (Arb_PatternStart),
         .Arb_WhichPort_Decode      (arb_whichport_decode),
         .Arb_WhichPort             (arb_whichport),
         .Arb_PatternType_Decode    (arb_patterntype_decode),
         .Arb_PatternType           (arb_patterntype),
         .Arb_RdModWr               (arb_rdmodwr)
         );
  
endmodule // mpmc_ctrl_path

`default_nettype wire
