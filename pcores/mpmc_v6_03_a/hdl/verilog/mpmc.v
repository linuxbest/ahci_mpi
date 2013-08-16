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
//Reference:
//    MPMC User Guide, UG253
//Module Structure:
//  module mpmc
//    #(
//      MPMC Core Parameters
//      MPMC PIM Parameters
//      MPMC Auto-Computed Parameters
//    )
//    (
//      MPMC PIM Signals
//      MPMC Core Signals
//    )
//      MPMC Core Local Parameters
//      MPMC PIM  Local Parameters
//      MPMC Static Local Parameters
//
//      Reg/Wire Declarations
//
//      Reset and IdelayCtrl Logic
//      MPMC Core Instantiation
//      MPMC PIM Instantiaions
//      MPMC Ctrl IF Instantiation
//      MPMC PM Instantiation
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/100ps
`default_nettype none

/////////////////
// MPMC Macros //
/////////////////

// Macro to calculate the native data width of the port based on the PIM type
`define GetDataWidth(SUBTYPE, SPLB_DWIDTH, NPI_DWIDTH, MEM_DWIDTH_INT) \
        (SUBTYPE == "INACTIVE") ? 32 : \
        (SUBTYPE == "XCL" || SUBTYPE == "IXCL" || SUBTYPE == "DXCL") ? 32 : \
        (SUBTYPE == "DXCL2" || SUBTYPE == "IXCL2") ? 32 : \
        (SUBTYPE == "PLB") ? SPLB_DWIDTH : \
        (SUBTYPE == "DPLB" || SUBTYPE == "IPLB") ? 64 : \
        (SUBTYPE == "SDMA") ? 32 : \
        (SUBTYPE == "NPI") ?  NPI_DWIDTH : \
        (SUBTYPE == "PPC440MC" && (MEM_DWIDTH_INT == 128 || MEM_DWIDTH_INT ==  64 )) ? 64 : \
        (SUBTYPE == "PPC440MC") ? 32 : \
        (SUBTYPE == "VFBC") ? NPI_DWIDTH : \
        (SUBTYPE == "MCB") ? NPI_DWIDTH : \
        (SUBTYPE == "MCB-Write") ? NPI_DWIDTH : \
        (SUBTYPE == "MCB-Read") ? NPI_DWIDTH : \
        -1  // indicates INVALID SUBTYPE

module mpmc
#(
  //////////////////////////
  // MPMC Core Parameters //
  //////////////////////////
  parameter         C_FAMILY                        = "NONE",
  parameter         C_BASEFAMILY                    = "NONE",
  parameter integer C_SPEEDGRADE_INT                = 2,
  parameter         C_NUM_PORTS                     = 3'b0,
  parameter         C_ALL_PIMS_SHARE_ADDRESSES      = 1'b0,
  parameter integer C_MPMC_BASEADDR                 = 32'hFFFFFFFF,
  parameter integer C_MPMC_HIGHADDR                 = 32'h00000000,
  parameter integer C_SDMA_CTRL_BASEADDR            = 32'hFFFFFFFF,
  parameter integer C_SDMA_CTRL_HIGHADDR            = 32'h00000000,
  parameter integer C_MPMC_CTRL_BASEADDR            = 32'hFFFFFFFF,
  parameter integer C_MPMC_CTRL_HIGHADDR            = 32'h00000000,
  parameter integer C_MPMC_CTRL_AWIDTH              = 0,
  parameter integer C_MPMC_CTRL_DWIDTH              = 0,
  parameter integer C_MPMC_CTRL_NATIVE_DWIDTH       = 0,
  parameter integer C_MPMC_CTRL_NUM_MASTERS         = 0,
  parameter integer C_MPMC_CTRL_MID_WIDTH           = 0,
  parameter         C_MPMC_CTRL_P2P                 = 1'b0,
  parameter         C_MPMC_CTRL_SUPPORT_BURSTS      = 1'b0,
  parameter integer C_MPMC_CTRL_SMALLEST_MASTER     = 0,
  parameter integer C_NUM_IDELAYCTRL                = 0,
  parameter         C_IODELAY_GRP                   = "NOT_SET",
  parameter integer C_MAX_REQ_ALLOWED               = 0,
  parameter         C_ARB_PIPELINE                  = 1'b0,
  parameter         C_WR_DATAPATH_TML_PIPELINE      = 1'b0,
  parameter integer C_RD_DATAPATH_TML_MAX_FANOUT    = 0,
  parameter integer C_ARB_USE_DEFAULT               = 0,
  parameter         C_ARB0_ALGO                     = "NONE",
  parameter integer C_ARB0_NUM_SLOTS                = 0,
  parameter         C_PM_ENABLE                     = 1'b0,
  parameter integer C_PM_DC_WIDTH                   = 0,
  parameter integer C_PM_GC_CNTR                    = 0,
  parameter integer C_PM_GC_WIDTH                   = 0,
  parameter integer C_PM_SHIFT_CNT_BY               = 0,
  parameter         C_SKIP_SIM_INIT_DELAY           = 1'b0,
  parameter         C_USE_MIG_S3_PHY                = 1'b0,
  parameter         C_USE_MIG_V4_PHY                = 1'b0,
  parameter         C_USE_MIG_V5_PHY                = 1'b0,
  parameter         C_USE_MIG_V6_PHY                = 1'b0,
  parameter         C_USE_MCB_S6_PHY                = 1'b0,
  parameter         C_USE_STATIC_PHY                = 1'b0,
  parameter         C_STATIC_PHY_RDDATA_CLK_SEL     = 1'b0,
  parameter         C_STATIC_PHY_RDDATA_SWAP_RISE   = 1'b0,
  parameter         C_STATIC_PHY_RDEN_DELAY         = 4'b0,
  parameter         C_DEBUG_REG_ENABLE              = 1'b0,
  parameter         C_SPECIAL_BOARD                 = "NONE",
  parameter integer C_PORT_CONFIG                   = 1,
  parameter         C_MEM_ADDR_ORDER                = "BANK_ROW_COLUMN",
  parameter integer C_MEM_CALIBRATION_MODE          = 1,
  parameter         C_MEM_CALIBRATION_DELAY         = "HALF",
  parameter         C_MEM_CALIBRATION_SOFT_IP       = "TRUE",
  parameter         C_MEM_SKIP_IN_TERM_CAL          = 1'b1,
  parameter         C_MEM_SKIP_DYNAMIC_CAL          = 1'b1,
  parameter         C_MEM_SKIP_DYN_IN_TERM          = 1'b1,
  parameter         C_MEM_INCDEC_THRESHOLD          = 8'h02,  // parameter for the threshold which triggers an inc/dec to occur
  parameter         C_MEM_CHECK_MAX_INDELAY         = 1'b0,   // provides option to check the values of the max_value and input delays for the specified IO
  parameter         C_MEM_CHECK_MAX_TAP_REG         = 1'b0,   // provides option to check the values of the max_value for all DQ and DQS IOI's
  parameter         C_MEM_TZQINIT_MAXCNT            = 10'h200,
  parameter         C_MEM_CALIBRATION_BYPASS        = "NO",
  parameter         C_MPMC_MCB_DRP_CLK_PRESENT      = 0,
  parameter integer C_MPMC_CLK_MEM_2X_PERIOD_PS     = 1,
  parameter integer C_MCB_USE_EXTERNAL_BUFPLL       = 0,

  parameter         C_MCB_LDQSP_TAP_DELAY_VAL       = 0,  // 0 to 255 inclusive
  parameter         C_MCB_UDQSP_TAP_DELAY_VAL       = 0,  // 0 to 255 inclusive
  parameter         C_MCB_LDQSN_TAP_DELAY_VAL       = 0,  // 0 to 255 inclusive
  parameter         C_MCB_UDQSN_TAP_DELAY_VAL       = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ0_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ1_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ2_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ3_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ4_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ5_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ6_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ7_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ8_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ9_TAP_DELAY_VAL         = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ10_TAP_DELAY_VAL        = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ11_TAP_DELAY_VAL        = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ12_TAP_DELAY_VAL        = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ13_TAP_DELAY_VAL        = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ14_TAP_DELAY_VAL        = 0,  // 0 to 255 inclusive
  parameter         C_MCB_DQ15_TAP_DELAY_VAL        = 0,  // 0 to 255 inclusive





  // Memory parameters
  parameter         C_MEM_TYPE                      = "NONE",
  parameter         C_MEM_DQS_IO_COL                = 18'b0,
  parameter         C_MEM_DQ_IO_MS                  = 72'b0,
  parameter integer C_MEM_CAS_LATENCY               = 0,
  parameter integer C_MEM_ODT_TYPE                  = 0,
  parameter         C_MEM_REDUCED_DRV               = 1'b0,
  parameter         C_MEM_REG_DIMM                  = 1'b0,
  parameter integer C_MPMC_CLK0_PERIOD_PS           = 0,
  parameter integer C_MEM_CLK_WIDTH                 = 0,
  parameter integer C_MEM_ODT_WIDTH                 = 0,
  parameter integer C_MEM_CE_WIDTH                  = 0,
  parameter integer C_MEM_CS_N_WIDTH                = 0,
  parameter integer C_MEM_ADDR_WIDTH                = 0,
  parameter integer C_MEM_BANKADDR_WIDTH            = 0,
  parameter integer C_MEM_DATA_WIDTH                = 0,
  parameter integer C_MEM_DM_WIDTH                  = 0,
  parameter integer C_MEM_DQS_WIDTH                 = 0,
  parameter integer C_MEM_BITS_DATA_PER_DQS         = 0,
  parameter integer C_MEM_NUM_DIMMS                 = 0,
  parameter integer C_MEM_NUM_RANKS                 = 0,
  parameter         C_DDR2_DQSN_ENABLE              = 1'b0,
  parameter         C_INCLUDE_ECC_SUPPORT           = 1'b0,
  parameter         C_ECC_DEFAULT_ON                = 1'b0,
  parameter         C_INCLUDE_ECC_TEST              = 1'b0,
  parameter integer C_ECC_SEC_THRESHOLD             = 0,
  parameter integer C_ECC_DEC_THRESHOLD             = 0,
  parameter integer C_ECC_PEC_THRESHOLD             = 0,
  parameter integer C_ECC_DATA_WIDTH                = 0,
  parameter integer C_ECC_DM_WIDTH                  = 0,
  parameter integer C_ECC_DQS_WIDTH                 = 0,
  parameter integer C_MEM_PART_NUM_BANK_BITS        = 0,
  parameter integer C_MEM_PART_NUM_ROW_BITS         = 0,
  parameter integer C_MEM_PART_NUM_COL_BITS         = 0,
  parameter integer C_MEM_PART_TWR                  = 0,
  parameter integer C_MEM_PART_TREFI                = 0,
  parameter integer C_MEM_PART_TRAS                 = 0,
  parameter integer C_MEM_PART_TRCD                 = 0,
  parameter integer C_MEM_PART_TRP                  = 0,
  parameter integer C_MEM_PART_TRFC                 = 0,
  parameter integer C_MEM_PART_TWTR                 = 0,
  parameter integer C_MEM_PART_TRTP                 = 0,
  parameter integer C_MEM_PART_TPRDI                = 0,
  parameter integer C_MEM_PART_TZQI                 = 0,
  parameter integer C_TBY4TAPVALUE     = (C_MPMC_CLK0_PERIOD_PS/32'd4)/78.125,
  parameter         C_MEM_PA_SR                     = "FULL",
  parameter integer C_MEM_CAS_WR_LATENCY            = 5,
  parameter         C_MEM_AUTO_SR                   = "ENABLED",
  parameter         C_MEM_HIGH_TEMP_SR              = "NORMAL",
  parameter         C_MEM_DYNAMIC_WRITE_ODT         = "OFF",
  parameter integer C_MEM_WRLVL                     = 0,
  parameter         C_IDELAY_CLK_FREQ               = "DEFAULT",
  parameter         C_MEM_PHASE_DETECT              = "DEFAULT",
  parameter         C_MEM_IBUF_LPWR_MODE            = "DEFAULT",
  parameter         C_MEM_IODELAY_HP_MODE           = "DEFAULT",
  parameter         C_MEM_SIM_INIT_OPTION           = "DEFAULT",
  parameter         C_MEM_SIM_CAL_OPTION            = "DEFAULT",
  parameter         C_MEM_CAL_WIDTH                 = "DEFAULT",
  parameter integer C_MEM_NDQS_COL0                 = 0,
  parameter integer C_MEM_NDQS_COL1                 = 0,
  parameter integer C_MEM_NDQS_COL2                 = 0,
  parameter integer C_MEM_NDQS_COL3                 = 0,
  parameter [143:0] C_MEM_DQS_LOC_COL0              = 144'h00000000000000000000000000000000,
  parameter [143:0] C_MEM_DQS_LOC_COL1              = 144'h00000000000000000000000000000000,
  parameter [143:0] C_MEM_DQS_LOC_COL2              = 144'h00000000000000000000000000000000,
  parameter [143:0] C_MEM_DQS_LOC_COL3              = 144'h00000000000000000000000000000000,
  parameter integer C_MAINT_PRESCALER_PERIOD        = 0,


  /////////////////////////
  // MPMC PIM Parameters //
  /////////////////////////
  // PORT 0
  parameter         C_PIM0_BASEADDR                 = 32'hFFFFFFFF,
  parameter         C_PIM0_HIGHADDR                 = 32'h00000000,
  parameter         C_PIM0_OFFSET                   = 32'h00000000,
  parameter integer C_PIM0_DATA_WIDTH               = 0,
  parameter integer C_PIM0_BASETYPE                 = 0,
  parameter         C_PIM0_SUBTYPE                  = "NONE",
  parameter         C_PIM0_B_SUBTYPE                = "NONE",
  parameter integer C_XCL0_LINESIZE                 = 0,
  parameter integer C_XCL0_WRITEXFER                = 0,
  parameter integer C_XCL0_PIPE_STAGES              = 0,
  parameter integer C_XCL0_B_IN_USE                 = 0,
  parameter integer C_XCL0_B_LINESIZE               = 0,
  parameter integer C_XCL0_B_WRITEXFER              = 0,
  parameter integer C_SPLB0_AWIDTH                  = 0,
  parameter integer C_SPLB0_DWIDTH                  = 0,
  parameter integer C_SPLB0_NATIVE_DWIDTH           = 0,
  parameter integer C_SPLB0_NUM_MASTERS             = 0,
  parameter integer C_SPLB0_MID_WIDTH               = 0,
  parameter         C_SPLB0_P2P                     = 1'b0,
  parameter         C_SPLB0_SUPPORT_BURSTS          = 1'b0,
  parameter integer C_SPLB0_SMALLEST_MASTER         = 0,
  parameter         C_SDMA_CTRL0_BASEADDR           = 32'hFFFFFFFF,
  parameter         C_SDMA_CTRL0_HIGHADDR           = 32'h00000000,
  parameter integer C_SDMA_CTRL0_AWIDTH             = 0,
  parameter integer C_SDMA_CTRL0_DWIDTH             = 0,
  parameter integer C_SDMA_CTRL0_NATIVE_DWIDTH      = 0,
  parameter integer C_SDMA_CTRL0_NUM_MASTERS        = 0,
  parameter integer C_SDMA_CTRL0_MID_WIDTH          = 0,
  parameter         C_SDMA_CTRL0_P2P                = 1'b0,
  parameter         C_SDMA_CTRL0_SUPPORT_BURSTS     = 1'b0,
  parameter integer C_SDMA_CTRL0_SMALLEST_MASTER    = 0,
  parameter         C_SDMA0_COMPLETED_ERR_TX        = 1'b0,
  parameter         C_SDMA0_COMPLETED_ERR_RX        = 1'b0,
  parameter integer C_SDMA0_PRESCALAR               = 0,
  parameter integer C_SDMA0_PI2LL_CLK_RATIO         = 0,
  parameter integer C_PPC440MC0_BURST_LENGTH        = 0,
  parameter integer C_PPC440MC0_PIPE_STAGES         = 0,
  parameter integer C_VFBC0_CMD_FIFO_DEPTH          = 0,
  parameter integer C_VFBC0_CMD_AFULL_COUNT         = 0,
  parameter integer C_VFBC0_RDWD_DATA_WIDTH         = 0,
  parameter integer C_VFBC0_RDWD_FIFO_DEPTH         = 0,
  parameter integer C_VFBC0_RD_AEMPTY_WD_AFULL_COUNT= 0,
  parameter         C_PI0_ADDRACK_PIPELINE          = 1'b0,
  parameter         C_PI0_RD_FIFO_TYPE              = "NONE",
  parameter         C_PI0_WR_FIFO_TYPE              = "NONE",
  parameter         C_PI0_RD_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI0_RD_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI0_WR_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI0_WR_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI0_PM_USED                   = 1'b0,
  parameter integer C_PI0_PM_DC_CNTR                = 0,

  // PORT 1
  parameter         C_PIM1_BASEADDR                 = 32'hFFFFFFFF,
  parameter         C_PIM1_HIGHADDR                 = 32'h00000000,
  parameter         C_PIM1_OFFSET                   = 32'h00000000,
  parameter integer C_PIM1_DATA_WIDTH               = 0,
  parameter integer C_PIM1_BASETYPE                 = 0,
  parameter         C_PIM1_SUBTYPE                  = "NONE",
  parameter         C_PIM1_B_SUBTYPE                = "NONE",
  parameter integer C_XCL1_LINESIZE                 = 0,
  parameter integer C_XCL1_WRITEXFER                = 0,
  parameter integer C_XCL1_PIPE_STAGES              = 0,
  parameter integer C_XCL1_B_IN_USE                 = 0,
  parameter integer C_XCL1_B_LINESIZE               = 0,
  parameter integer C_XCL1_B_WRITEXFER              = 0,
  parameter integer C_SPLB1_AWIDTH                  = 0,
  parameter integer C_SPLB1_DWIDTH                  = 0,
  parameter integer C_SPLB1_NATIVE_DWIDTH           = 0,
  parameter integer C_SPLB1_NUM_MASTERS             = 0,
  parameter integer C_SPLB1_MID_WIDTH               = 0,
  parameter         C_SPLB1_P2P                     = 1'b0,
  parameter         C_SPLB1_SUPPORT_BURSTS          = 1'b0,
  parameter integer C_SPLB1_SMALLEST_MASTER         = 0,
  parameter         C_SDMA_CTRL1_BASEADDR           = 32'hFFFFFFFF,
  parameter         C_SDMA_CTRL1_HIGHADDR           = 32'h00000000,
  parameter integer C_SDMA_CTRL1_AWIDTH             = 0,
  parameter integer C_SDMA_CTRL1_DWIDTH             = 0,
  parameter integer C_SDMA_CTRL1_NATIVE_DWIDTH      = 0,
  parameter integer C_SDMA_CTRL1_NUM_MASTERS        = 0,
  parameter integer C_SDMA_CTRL1_MID_WIDTH          = 0,
  parameter         C_SDMA_CTRL1_P2P                = 1'b0,
  parameter         C_SDMA_CTRL1_SUPPORT_BURSTS     = 1'b0,
  parameter integer C_SDMA_CTRL1_SMALLEST_MASTER    = 0,
  parameter         C_SDMA1_COMPLETED_ERR_TX        = 1'b0,
  parameter         C_SDMA1_COMPLETED_ERR_RX        = 1'b0,
  parameter integer C_SDMA1_PRESCALAR               = 0,
  parameter integer C_SDMA1_PI2LL_CLK_RATIO         = 0,
  parameter integer C_PPC440MC1_BURST_LENGTH        = 0,
  parameter integer C_PPC440MC1_PIPE_STAGES         = 0,
  parameter integer C_VFBC1_CMD_FIFO_DEPTH          = 0,
  parameter integer C_VFBC1_CMD_AFULL_COUNT         = 0,
  parameter integer C_VFBC1_RDWD_DATA_WIDTH         = 0,
  parameter integer C_VFBC1_RDWD_FIFO_DEPTH         = 0,
  parameter integer C_VFBC1_RD_AEMPTY_WD_AFULL_COUNT= 0,
  parameter         C_PI1_ADDRACK_PIPELINE          = 1'b0,
  parameter         C_PI1_RD_FIFO_TYPE              = "NONE",
  parameter         C_PI1_WR_FIFO_TYPE              = "NONE",
  parameter         C_PI1_RD_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI1_RD_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI1_WR_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI1_WR_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI1_PM_USED                   = 1'b0,
  parameter integer C_PI1_PM_DC_CNTR                = 0,

  // PORT 2
  parameter         C_PIM2_BASEADDR                 = 32'hFFFFFFFF,
  parameter         C_PIM2_HIGHADDR                 = 32'h00000000,
  parameter         C_PIM2_OFFSET                   = 32'h00000000,
  parameter integer C_PIM2_DATA_WIDTH               = 0,
  parameter integer C_PIM2_BASETYPE                 = 0,
  parameter         C_PIM2_SUBTYPE                  = "NONE",
  parameter         C_PIM2_B_SUBTYPE                = "NONE",
  parameter integer C_XCL2_LINESIZE                 = 0,
  parameter integer C_XCL2_WRITEXFER                = 0,
  parameter integer C_XCL2_PIPE_STAGES              = 0,
  parameter integer C_XCL2_B_IN_USE                 = 0,
  parameter integer C_XCL2_B_LINESIZE               = 0,
  parameter integer C_XCL2_B_WRITEXFER              = 0,
  parameter integer C_SPLB2_AWIDTH                  = 0,
  parameter integer C_SPLB2_DWIDTH                  = 0,
  parameter integer C_SPLB2_NATIVE_DWIDTH           = 0,
  parameter integer C_SPLB2_NUM_MASTERS             = 0,
  parameter integer C_SPLB2_MID_WIDTH               = 0,
  parameter         C_SPLB2_P2P                     = 1'b0,
  parameter         C_SPLB2_SUPPORT_BURSTS          = 1'b0,
  parameter integer C_SPLB2_SMALLEST_MASTER         = 0,
  parameter         C_SDMA_CTRL2_BASEADDR           = 32'hFFFFFFFF,
  parameter         C_SDMA_CTRL2_HIGHADDR           = 32'h00000000,
  parameter integer C_SDMA_CTRL2_AWIDTH             = 0,
  parameter integer C_SDMA_CTRL2_DWIDTH             = 0,
  parameter integer C_SDMA_CTRL2_NATIVE_DWIDTH      = 0,
  parameter integer C_SDMA_CTRL2_NUM_MASTERS        = 0,
  parameter integer C_SDMA_CTRL2_MID_WIDTH          = 0,
  parameter         C_SDMA_CTRL2_P2P                = 1'b0,
  parameter         C_SDMA_CTRL2_SUPPORT_BURSTS     = 1'b0,
  parameter integer C_SDMA_CTRL2_SMALLEST_MASTER    = 0,
  parameter integer C_SDMA2_COMPLETED_ERR_TX        = 0,
  parameter integer C_SDMA2_COMPLETED_ERR_RX        = 0,
  parameter integer C_SDMA2_PRESCALAR               = 0,
  parameter integer C_SDMA2_PI2LL_CLK_RATIO         = 0,
  parameter integer C_PPC440MC2_BURST_LENGTH        = 0,
  parameter integer C_PPC440MC2_PIPE_STAGES         = 0,
  parameter integer C_VFBC2_CMD_FIFO_DEPTH          = 0,
  parameter integer C_VFBC2_CMD_AFULL_COUNT         = 0,
  parameter integer C_VFBC2_RDWD_DATA_WIDTH         = 0,
  parameter integer C_VFBC2_RDWD_FIFO_DEPTH         = 0,
  parameter integer C_VFBC2_RD_AEMPTY_WD_AFULL_COUNT= 0,
  parameter integer C_PI2_ADDRACK_PIPELINE          = 0,
  parameter         C_PI2_RD_FIFO_TYPE              = "NONE",
  parameter         C_PI2_WR_FIFO_TYPE              = "NONE",
  parameter         C_PI2_RD_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI2_RD_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI2_WR_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI2_WR_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI2_PM_USED                   = 1'b0,
  parameter integer C_PI2_PM_DC_CNTR                = 0,

  // PORT 3
  parameter         C_PIM3_BASEADDR                 = 32'hFFFFFFFF,
  parameter         C_PIM3_HIGHADDR                 = 32'h00000000,
  parameter         C_PIM3_OFFSET                   = 32'h00000000,
  parameter integer C_PIM3_DATA_WIDTH               = 0,
  parameter integer C_PIM3_BASETYPE                 = 0,
  parameter         C_PIM3_SUBTYPE                  = "NONE",
  parameter         C_PIM3_B_SUBTYPE                = "NONE",
  parameter integer C_XCL3_LINESIZE                 = 0,
  parameter integer C_XCL3_WRITEXFER                = 0,
  parameter integer C_XCL3_PIPE_STAGES              = 0,
  parameter integer C_XCL3_B_IN_USE                 = 0,
  parameter integer C_XCL3_B_LINESIZE               = 0,
  parameter integer C_XCL3_B_WRITEXFER              = 0,
  parameter integer C_SPLB3_AWIDTH                  = 0,
  parameter integer C_SPLB3_DWIDTH                  = 0,
  parameter integer C_SPLB3_NATIVE_DWIDTH           = 0,
  parameter integer C_SPLB3_NUM_MASTERS             = 0,
  parameter integer C_SPLB3_MID_WIDTH               = 0,
  parameter         C_SPLB3_P2P                     = 1'b0,
  parameter         C_SPLB3_SUPPORT_BURSTS          = 1'b0,
  parameter integer C_SPLB3_SMALLEST_MASTER         = 0,
  parameter         C_SDMA_CTRL3_BASEADDR           = 32'hFFFFFFFF,
  parameter         C_SDMA_CTRL3_HIGHADDR           = 32'h00000000,
  parameter integer C_SDMA_CTRL3_AWIDTH             = 0,
  parameter integer C_SDMA_CTRL3_DWIDTH             = 0,
  parameter integer C_SDMA_CTRL3_NATIVE_DWIDTH      = 0,
  parameter integer C_SDMA_CTRL3_NUM_MASTERS        = 0,
  parameter integer C_SDMA_CTRL3_MID_WIDTH          = 0,
  parameter         C_SDMA_CTRL3_P2P                = 1'b0,
  parameter         C_SDMA_CTRL3_SUPPORT_BURSTS     = 1'b0,
  parameter integer C_SDMA_CTRL3_SMALLEST_MASTER    = 0,
  parameter integer C_SDMA3_COMPLETED_ERR_TX        = 0,
  parameter integer C_SDMA3_COMPLETED_ERR_RX        = 0,
  parameter integer C_SDMA3_PRESCALAR               = 0,
  parameter integer C_SDMA3_PI2LL_CLK_RATIO         = 0,
  parameter integer C_PPC440MC3_BURST_LENGTH        = 0,
  parameter integer C_PPC440MC3_PIPE_STAGES         = 0,
  parameter integer C_VFBC3_CMD_FIFO_DEPTH          = 0,
  parameter integer C_VFBC3_CMD_AFULL_COUNT         = 0,
  parameter integer C_VFBC3_RDWD_DATA_WIDTH         = 0,
  parameter integer C_VFBC3_RDWD_FIFO_DEPTH         = 0,
  parameter integer C_VFBC3_RD_AEMPTY_WD_AFULL_COUNT= 0,
  parameter         C_PI3_ADDRACK_PIPELINE          = 1'b0,
  parameter         C_PI3_RD_FIFO_TYPE              = "NONE",
  parameter         C_PI3_WR_FIFO_TYPE              = "NONE",
  parameter         C_PI3_RD_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI3_RD_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI3_WR_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI3_WR_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI3_PM_USED                   = 1'b0,
  parameter integer C_PI3_PM_DC_CNTR                = 0,

  // PORT 4
  parameter         C_PIM4_BASEADDR                 = 32'hFFFFFFFF,
  parameter         C_PIM4_HIGHADDR                 = 32'h00000000,
  parameter         C_PIM4_OFFSET                   = 32'h00000000,
  parameter integer C_PIM4_DATA_WIDTH               = 0,
  parameter integer C_PIM4_BASETYPE                 = 0,
  parameter         C_PIM4_SUBTYPE                  = "NONE",
  parameter         C_PIM4_B_SUBTYPE                = "NONE",
  parameter integer C_XCL4_LINESIZE                 = 0,
  parameter integer C_XCL4_WRITEXFER                = 0,
  parameter integer C_XCL4_PIPE_STAGES              = 0,
  parameter integer C_XCL4_B_IN_USE                 = 0,
  parameter integer C_XCL4_B_LINESIZE               = 0,
  parameter integer C_XCL4_B_WRITEXFER              = 0,
  parameter integer C_SPLB4_AWIDTH                  = 0,
  parameter integer C_SPLB4_DWIDTH                  = 0,
  parameter integer C_SPLB4_NATIVE_DWIDTH           = 0,
  parameter integer C_SPLB4_NUM_MASTERS             = 0,
  parameter integer C_SPLB4_MID_WIDTH               = 0,
  parameter         C_SPLB4_P2P                     = 1'b0,
  parameter         C_SPLB4_SUPPORT_BURSTS          = 1'b0,
  parameter integer C_SPLB4_SMALLEST_MASTER         = 0,
  parameter         C_SDMA_CTRL4_BASEADDR           = 32'hFFFFFFFF,
  parameter         C_SDMA_CTRL4_HIGHADDR           = 32'h00000000,
  parameter integer C_SDMA_CTRL4_AWIDTH             = 0,
  parameter integer C_SDMA_CTRL4_DWIDTH             = 0,
  parameter integer C_SDMA_CTRL4_NATIVE_DWIDTH      = 0,
  parameter integer C_SDMA_CTRL4_NUM_MASTERS        = 0,
  parameter integer C_SDMA_CTRL4_MID_WIDTH          = 0,
  parameter         C_SDMA_CTRL4_P2P                = 1'b0,
  parameter         C_SDMA_CTRL4_SUPPORT_BURSTS     = 1'b0,
  parameter integer C_SDMA_CTRL4_SMALLEST_MASTER    = 0,
  parameter integer C_SDMA4_COMPLETED_ERR_TX        = 0,
  parameter integer C_SDMA4_COMPLETED_ERR_RX        = 0,
  parameter integer C_SDMA4_PRESCALAR               = 0,
  parameter integer C_SDMA4_PI2LL_CLK_RATIO         = 0,
  parameter integer C_PPC440MC4_BURST_LENGTH        = 0,
  parameter integer C_PPC440MC4_PIPE_STAGES         = 0,
  parameter integer C_VFBC4_CMD_FIFO_DEPTH          = 0,
  parameter integer C_VFBC4_CMD_AFULL_COUNT         = 0,
  parameter integer C_VFBC4_RDWD_DATA_WIDTH         = 0,
  parameter integer C_VFBC4_RDWD_FIFO_DEPTH         = 0,
  parameter integer C_VFBC4_RD_AEMPTY_WD_AFULL_COUNT= 0,
  parameter         C_PI4_ADDRACK_PIPELINE          = 1'b0,
  parameter         C_PI4_RD_FIFO_TYPE              = "NONE",
  parameter         C_PI4_WR_FIFO_TYPE              = "NONE",
  parameter         C_PI4_RD_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI4_RD_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI4_WR_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI4_WR_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI4_PM_USED                   = 1'b0,
  parameter integer C_PI4_PM_DC_CNTR                = 0,

  // PORT 5
  parameter         C_PIM5_BASEADDR                 = 32'hFFFFFFFF,
  parameter         C_PIM5_HIGHADDR                 = 32'h00000000,
  parameter         C_PIM5_OFFSET                   = 32'h00000000,
  parameter integer C_PIM5_DATA_WIDTH               = 0,
  parameter integer C_PIM5_BASETYPE                 = 0,
  parameter         C_PIM5_SUBTYPE                  = "NONE",
  parameter         C_PIM5_B_SUBTYPE                = "NONE",
  parameter integer C_XCL5_LINESIZE                 = 0,
  parameter integer C_XCL5_WRITEXFER                = 0,
  parameter integer C_XCL5_PIPE_STAGES              = 0,
  parameter integer C_XCL5_B_IN_USE                 = 0,
  parameter integer C_XCL5_B_LINESIZE               = 0,
  parameter integer C_XCL5_B_WRITEXFER              = 0,
  parameter integer C_SPLB5_AWIDTH                  = 0,
  parameter integer C_SPLB5_DWIDTH                  = 0,
  parameter integer C_SPLB5_NATIVE_DWIDTH           = 0,
  parameter integer C_SPLB5_NUM_MASTERS             = 0,
  parameter integer C_SPLB5_MID_WIDTH               = 0,
  parameter         C_SPLB5_P2P                     = 1'b0,
  parameter         C_SPLB5_SUPPORT_BURSTS          = 1'b0,
  parameter integer C_SPLB5_SMALLEST_MASTER         = 0,
  parameter         C_SDMA_CTRL5_BASEADDR           = 32'hFFFFFFFF,
  parameter         C_SDMA_CTRL5_HIGHADDR           = 32'h00000000,
  parameter integer C_SDMA_CTRL5_AWIDTH             = 0,
  parameter integer C_SDMA_CTRL5_DWIDTH             = 0,
  parameter integer C_SDMA_CTRL5_NATIVE_DWIDTH      = 0,
  parameter integer C_SDMA_CTRL5_NUM_MASTERS        = 0,
  parameter integer C_SDMA_CTRL5_MID_WIDTH          = 0,
  parameter         C_SDMA_CTRL5_P2P                = 1'b0,
  parameter         C_SDMA_CTRL5_SUPPORT_BURSTS     = 1'b0,
  parameter integer C_SDMA_CTRL5_SMALLEST_MASTER    = 0,
  parameter integer C_SDMA5_COMPLETED_ERR_TX        = 0,
  parameter integer C_SDMA5_COMPLETED_ERR_RX        = 0,
  parameter integer C_SDMA5_PRESCALAR               = 0,
  parameter integer C_SDMA5_PI2LL_CLK_RATIO         = 0,
  parameter integer C_PPC440MC5_BURST_LENGTH        = 0,
  parameter integer C_PPC440MC5_PIPE_STAGES         = 0,
  parameter integer C_VFBC5_CMD_FIFO_DEPTH          = 0,
  parameter integer C_VFBC5_CMD_AFULL_COUNT         = 0,
  parameter integer C_VFBC5_RDWD_DATA_WIDTH         = 0,
  parameter integer C_VFBC5_RDWD_FIFO_DEPTH         = 0,
  parameter integer C_VFBC5_RD_AEMPTY_WD_AFULL_COUNT= 0,
  parameter         C_PI5_ADDRACK_PIPELINE          = 1'b0,
  parameter         C_PI5_RD_FIFO_TYPE              = "NONE",
  parameter         C_PI5_WR_FIFO_TYPE              = "NONE",
  parameter         C_PI5_RD_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI5_RD_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI5_WR_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI5_WR_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI5_PM_USED                   = 1'b0,
  parameter integer C_PI5_PM_DC_CNTR                = 0,

  // PORT 6
  parameter         C_PIM6_BASEADDR                 = 32'hFFFFFFFF,
  parameter         C_PIM6_HIGHADDR                 = 32'h00000000,
  parameter         C_PIM6_OFFSET                   = 32'h00000000,
  parameter integer C_PIM6_DATA_WIDTH               = 0,
  parameter integer C_PIM6_BASETYPE                 = 0,
  parameter         C_PIM6_SUBTYPE                  = "NONE",
  parameter         C_PIM6_B_SUBTYPE                = "NONE",
  parameter integer C_XCL6_LINESIZE                 = 0,
  parameter integer C_XCL6_WRITEXFER                = 0,
  parameter integer C_XCL6_PIPE_STAGES              = 0,
  parameter integer C_XCL6_B_IN_USE                 = 0,
  parameter integer C_XCL6_B_LINESIZE               = 0,
  parameter integer C_XCL6_B_WRITEXFER              = 0,
  parameter integer C_SPLB6_AWIDTH                  = 0,
  parameter integer C_SPLB6_DWIDTH                  = 0,
  parameter integer C_SPLB6_NATIVE_DWIDTH           = 0,
  parameter integer C_SPLB6_NUM_MASTERS             = 0,
  parameter integer C_SPLB6_MID_WIDTH               = 0,
  parameter         C_SPLB6_P2P                     = 1'b0,
  parameter         C_SPLB6_SUPPORT_BURSTS          = 1'b0,
  parameter integer C_SPLB6_SMALLEST_MASTER         = 0,
  parameter         C_SDMA_CTRL6_BASEADDR           = 32'hFFFFFFFF,
  parameter         C_SDMA_CTRL6_HIGHADDR           = 32'h00000000,
  parameter integer C_SDMA_CTRL6_AWIDTH             = 0,
  parameter integer C_SDMA_CTRL6_DWIDTH             = 0,
  parameter integer C_SDMA_CTRL6_NATIVE_DWIDTH      = 0,
  parameter integer C_SDMA_CTRL6_NUM_MASTERS        = 0,
  parameter integer C_SDMA_CTRL6_MID_WIDTH          = 0,
  parameter         C_SDMA_CTRL6_P2P                = 1'b0,
  parameter         C_SDMA_CTRL6_SUPPORT_BURSTS     = 1'b0,
  parameter integer C_SDMA_CTRL6_SMALLEST_MASTER    = 0,
  parameter integer C_SDMA6_COMPLETED_ERR_TX        = 0,
  parameter integer C_SDMA6_COMPLETED_ERR_RX        = 0,
  parameter integer C_SDMA6_PRESCALAR               = 0,
  parameter integer C_SDMA6_PI2LL_CLK_RATIO         = 0,
  parameter integer C_PPC440MC6_BURST_LENGTH        = 0,
  parameter integer C_PPC440MC6_PIPE_STAGES         = 0,
  parameter integer C_VFBC6_CMD_FIFO_DEPTH          = 0,
  parameter integer C_VFBC6_CMD_AFULL_COUNT         = 0,
  parameter integer C_VFBC6_RDWD_DATA_WIDTH         = 0,
  parameter integer C_VFBC6_RDWD_FIFO_DEPTH         = 0,
  parameter integer C_VFBC6_RD_AEMPTY_WD_AFULL_COUNT= 0,
  parameter         C_PI6_ADDRACK_PIPELINE          = 1'b0,
  parameter         C_PI6_RD_FIFO_TYPE              = "NONE",
  parameter         C_PI6_WR_FIFO_TYPE              = "NONE",
  parameter         C_PI6_RD_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI6_RD_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI6_WR_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI6_WR_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI6_PM_USED                   = 1'b0,
  parameter integer C_PI6_PM_DC_CNTR                = 0,

  // PORT 7
  parameter         C_PIM7_BASEADDR                 = 32'hFFFFFFFF,
  parameter         C_PIM7_HIGHADDR                 = 32'h00000000,
  parameter         C_PIM7_OFFSET                   = 32'h00000000,
  parameter integer C_PIM7_DATA_WIDTH               = 0,
  parameter integer C_PIM7_BASETYPE                 = 0,
  parameter         C_PIM7_SUBTYPE                  = "NONE",
  parameter         C_PIM7_B_SUBTYPE                = "NONE",
  parameter integer C_XCL7_LINESIZE                 = 0,
  parameter integer C_XCL7_WRITEXFER                = 0,
  parameter integer C_XCL7_PIPE_STAGES              = 0,
  parameter integer C_XCL7_B_IN_USE                 = 0,
  parameter integer C_XCL7_B_LINESIZE               = 0,
  parameter integer C_XCL7_B_WRITEXFER              = 0,
  parameter integer C_SPLB7_AWIDTH                  = 0,
  parameter integer C_SPLB7_DWIDTH                  = 0,
  parameter integer C_SPLB7_NATIVE_DWIDTH           = 0,
  parameter integer C_SPLB7_NUM_MASTERS             = 0,
  parameter integer C_SPLB7_MID_WIDTH               = 0,
  parameter         C_SPLB7_P2P                     = 1'b0,
  parameter         C_SPLB7_SUPPORT_BURSTS          = 1'b0,
  parameter integer C_SPLB7_SMALLEST_MASTER         = 0,
  parameter         C_SDMA_CTRL7_BASEADDR           = 32'hFFFFFFFF,
  parameter         C_SDMA_CTRL7_HIGHADDR           = 32'h00000000,
  parameter integer C_SDMA_CTRL7_AWIDTH             = 0,
  parameter integer C_SDMA_CTRL7_DWIDTH             = 0,
  parameter integer C_SDMA_CTRL7_NATIVE_DWIDTH      = 0,
  parameter integer C_SDMA_CTRL7_NUM_MASTERS        = 0,
  parameter integer C_SDMA_CTRL7_MID_WIDTH          = 0,
  parameter         C_SDMA_CTRL7_P2P                = 1'b0,
  parameter         C_SDMA_CTRL7_SUPPORT_BURSTS     = 1'b0,
  parameter integer C_SDMA_CTRL7_SMALLEST_MASTER    = 0,
  parameter integer C_SDMA7_COMPLETED_ERR_TX        = 0,
  parameter integer C_SDMA7_COMPLETED_ERR_RX        = 0,
  parameter integer C_SDMA7_PRESCALAR               = 0,
  parameter integer C_SDMA7_PI2LL_CLK_RATIO         = 0,
  parameter integer C_PPC440MC7_BURST_LENGTH        = 0,
  parameter integer C_PPC440MC7_PIPE_STAGES         = 0,
  parameter integer C_VFBC7_CMD_FIFO_DEPTH          = 0,
  parameter integer C_VFBC7_CMD_AFULL_COUNT         = 0,
  parameter integer C_VFBC7_RDWD_DATA_WIDTH         = 0,
  parameter integer C_VFBC7_RDWD_FIFO_DEPTH         = 0,
  parameter integer C_VFBC7_RD_AEMPTY_WD_AFULL_COUNT= 0,
  parameter         C_PI7_ADDRACK_PIPELINE          = 1'b0,
  parameter         C_PI7_RD_FIFO_TYPE              = "NONE",
  parameter         C_PI7_WR_FIFO_TYPE              = "NONE",
  parameter         C_PI7_RD_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI7_RD_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI7_WR_FIFO_APP_PIPELINE      = 1'b0,
  parameter         C_PI7_WR_FIFO_MEM_PIPELINE      = 1'b0,
  parameter         C_PI7_PM_USED                   = 1'b0,
  parameter integer C_PI7_PM_DC_CNTR                = 0,

  ///////////////////////////////////
  // MPMC Auto-Computed Parameters //
  ///////////////////////////////////
  parameter         C_WR_TRAINING_PORT              = 3'b0,
  parameter         C_ARB_BRAM_INIT_00              = 256'h0,
  parameter         C_ARB_BRAM_INIT_01              = 256'h0,
  parameter         C_ARB_BRAM_INIT_02              = 256'h0,
  parameter         C_ARB_BRAM_INIT_03              = 256'h0,
  parameter         C_ARB_BRAM_INIT_04              = 256'h0,
  parameter         C_ARB_BRAM_INIT_05              = 256'h0,
  parameter         C_ARB_BRAM_INIT_06              = 256'h0,
  parameter         C_ARB_BRAM_INIT_07              = 256'h0,
  parameter         C_NCK_PER_CLK                   = 1,
  parameter         C_TWR                           = 0,
  parameter integer C_CTRL_COMPLETE_INDEX           = 0,
  parameter integer C_CTRL_IS_WRITE_INDEX           = 1,
  parameter integer C_CTRL_PHYIF_RAS_N_INDEX        = 2,
  parameter integer C_CTRL_PHYIF_CAS_N_INDEX        = 3,
  parameter integer C_CTRL_PHYIF_WE_N_INDEX         = 4,
  parameter integer C_CTRL_RMW_INDEX                = 6,
  parameter integer C_CTRL_SKIP_0_INDEX             = 7,
  parameter integer C_CTRL_PHYIF_DQS_O_INDEX        = 8,
  parameter integer C_CTRL_SKIP_1_INDEX             = 9,
  parameter integer C_CTRL_DP_RDFIFO_PUSH_INDEX     = 10,
  parameter integer C_CTRL_SKIP_2_INDEX             = 11,
  parameter integer C_CTRL_AP_COL_CNT_LOAD_INDEX    = 12,
  parameter integer C_CTRL_AP_COL_CNT_ENABLE_INDEX  = 13,
  parameter integer C_CTRL_AP_PRECHARGE_ADDR10_INDEX= 14,
  parameter integer C_CTRL_AP_ROW_COL_SEL_INDEX     = 15,
  parameter integer C_CTRL_PHYIF_FORCE_DM_INDEX     = 16,
  parameter integer C_CTRL_REPEAT4_INDEX            = 17,
  parameter integer C_CTRL_DFI_RAS_N_0_INDEX        = 0,
  parameter integer C_CTRL_DFI_CAS_N_0_INDEX        = 0,
  parameter integer C_CTRL_DFI_WE_N_0_INDEX         = 0,
  parameter integer C_CTRL_DFI_RAS_N_1_INDEX        = 0,
  parameter integer C_CTRL_DFI_CAS_N_1_INDEX        = 0,
  parameter integer C_CTRL_DFI_WE_N_1_INDEX         = 0,
  parameter integer C_CTRL_DP_WRFIFO_POP_INDEX      = 0,
  parameter integer C_CTRL_DFI_WRDATA_EN_INDEX      = 0,
  parameter integer C_CTRL_DFI_RDDATA_EN_INDEX      = 0,
  parameter integer C_CTRL_AP_OTF_ADDR12_INDEX      = 0,
  parameter integer C_CTRL_ARB_RDMODWR_DELAY        = 0,
  parameter integer C_CTRL_AP_COL_DELAY             = 0,
  parameter integer C_CTRL_AP_PI_ADDR_CE_DELAY      = 0,
  parameter integer C_CTRL_AP_PORT_SELECT_DELAY     = 0,
  parameter integer C_CTRL_AP_PIPELINE1_CE_DELAY    = 0,
  parameter integer C_CTRL_DP_LOAD_RDWDADDR_DELAY   = 0,
  parameter integer C_CTRL_DP_RDFIFO_WHICHPORT_DELAY= 0,
  parameter integer C_CTRL_DP_SIZE_DELAY            = 0,
  parameter integer C_CTRL_DP_WRFIFO_WHICHPORT_DELAY= 0,
  parameter integer C_CTRL_PHYIF_DUMMYREADSTART_DELAY = 0,
  parameter integer C_CTRL_Q0_DELAY                 = 0,
  parameter integer C_CTRL_Q1_DELAY                 = 0,
  parameter integer C_CTRL_Q2_DELAY                 = 0,
  parameter integer C_CTRL_Q3_DELAY                 = 0,
  parameter integer C_CTRL_Q4_DELAY                 = 0,
  parameter integer C_CTRL_Q5_DELAY                 = 0,
  parameter integer C_CTRL_Q6_DELAY                 = 0,
  parameter integer C_CTRL_Q7_DELAY                 = 0,
  parameter integer C_CTRL_Q8_DELAY                 = 0,
  parameter integer C_CTRL_Q9_DELAY                 = 0,
  parameter integer C_CTRL_Q10_DELAY                = 0,
  parameter integer C_CTRL_Q11_DELAY                = 0,
  parameter integer C_CTRL_Q12_DELAY                = 0,
  parameter integer C_CTRL_Q13_DELAY                = 0,
  parameter integer C_CTRL_Q14_DELAY                = 0,
  parameter integer C_CTRL_Q15_DELAY                = 0,
  parameter integer C_CTRL_Q16_DELAY                = 0,
  parameter integer C_CTRL_Q17_DELAY                = 0,
  parameter integer C_CTRL_Q18_DELAY                = 0,
  parameter integer C_CTRL_Q19_DELAY                = 0,
  parameter integer C_CTRL_Q20_DELAY                = 0,
  parameter integer C_CTRL_Q21_DELAY                = 0,
  parameter integer C_CTRL_Q22_DELAY                = 0,
  parameter integer C_CTRL_Q23_DELAY                = 0,
  parameter integer C_CTRL_Q24_DELAY                = 0,
  parameter integer C_CTRL_Q25_DELAY                = 0,
  parameter integer C_CTRL_Q26_DELAY                = 0,
  parameter integer C_CTRL_Q27_DELAY                = 0,
  parameter integer C_CTRL_Q28_DELAY                = 0,
  parameter integer C_CTRL_Q29_DELAY                = 0,
  parameter integer C_CTRL_Q30_DELAY                = 0,
  parameter integer C_CTRL_Q31_DELAY                = 0,
  parameter integer C_CTRL_Q32_DELAY                = 0,
  parameter integer C_CTRL_Q33_DELAY                = 0,
  parameter integer C_CTRL_Q34_DELAY                = 0,
  parameter integer C_CTRL_Q35_DELAY                = 0,
  parameter         C_SKIP_1_VALUE                  = 9'h0,
  parameter         C_SKIP_2_VALUE                  = 9'h0,
  parameter         C_SKIP_3_VALUE                  = 9'h0,
  parameter         C_SKIP_4_VALUE                  = 9'h0,
  parameter         C_SKIP_5_VALUE                  = 9'h0,
  parameter         C_SKIP_6_VALUE                  = 9'h0,
  parameter         C_SKIP_7_VALUE                  = 9'h0,
  parameter         C_B16_REPEAT_CNT                = 0,
  parameter         C_B32_REPEAT_CNT                = 0,
  parameter         C_B64_REPEAT_CNT                = 0,
  parameter         C_ZQCS_REPEAT_CNT               = 0,
  parameter         C_BASEADDR_CTRL0                = 9'h0,
  parameter         C_HIGHADDR_CTRL0                = 9'h0,
  parameter         C_BASEADDR_CTRL1                = 9'h0,
  parameter         C_HIGHADDR_CTRL1                = 9'h0,
  parameter         C_BASEADDR_CTRL2                = 9'h0,
  parameter         C_HIGHADDR_CTRL2                = 9'h0,
  parameter         C_BASEADDR_CTRL3                = 9'h0,
  parameter         C_HIGHADDR_CTRL3                = 9'h0,
  parameter         C_BASEADDR_CTRL4                = 9'h0,
  parameter         C_HIGHADDR_CTRL4                = 9'h0,
  parameter         C_BASEADDR_CTRL5                = 9'h0,
  parameter         C_HIGHADDR_CTRL5                = 9'h0,
  parameter         C_BASEADDR_CTRL6                = 9'h0,
  parameter         C_HIGHADDR_CTRL6                = 9'h0,
  parameter         C_BASEADDR_CTRL7                = 9'h0,
  parameter         C_HIGHADDR_CTRL7                = 9'h0,
  parameter         C_BASEADDR_CTRL8                = 9'h0,
  parameter         C_HIGHADDR_CTRL8                = 9'h0,
  parameter         C_BASEADDR_CTRL9                = 9'h0,
  parameter         C_HIGHADDR_CTRL9                = 9'h0,
  parameter         C_BASEADDR_CTRL10               = 9'h0,
  parameter         C_HIGHADDR_CTRL10               = 9'h0,
  parameter         C_BASEADDR_CTRL11               = 9'h0,
  parameter         C_HIGHADDR_CTRL11               = 9'h0,
  parameter         C_BASEADDR_CTRL12               = 9'h0,
  parameter         C_HIGHADDR_CTRL12               = 9'h0,
  parameter         C_BASEADDR_CTRL13               = 9'h0,
  parameter         C_HIGHADDR_CTRL13               = 9'h0,
  parameter         C_BASEADDR_CTRL14               = 9'h0,
  parameter         C_HIGHADDR_CTRL14               = 9'h0,
  parameter         C_BASEADDR_CTRL15               = 9'h0,
  parameter         C_HIGHADDR_CTRL15               = 9'h0,
  parameter         C_BASEADDR_CTRL16               = 9'h0,
  parameter         C_HIGHADDR_CTRL16               = 9'h0,
  parameter         C_CTRL_BRAM_SRVAL               = 36'h0,
  parameter         C_CTRL_BRAM_INIT_00             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_01             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_02             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_03             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_04             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_05             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_06             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_07             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_08             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_09             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_0A             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_0B             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_0C             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_0D             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_0E             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_0F             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_10             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_11             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_12             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_13             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_14             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_15             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_16             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_17             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_18             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_19             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_1A             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_1B             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_1C             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_1D             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_1E             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_1F             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_20             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_21             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_22             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_23             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_24             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_25             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_26             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_27             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_28             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_29             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_2A             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_2B             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_2C             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_2D             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_2E             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_2F             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_30             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_31             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_32             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_33             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_34             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_35             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_36             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_37             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_38             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_39             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_3A             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_3B             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_3C             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_3D             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_3E             = 256'h0,
  parameter         C_CTRL_BRAM_INIT_3F             = 256'h0,
  parameter         C_CTRL_BRAM_INITP_00            = 256'h0,
  parameter         C_CTRL_BRAM_INITP_01            = 256'h0,
  parameter         C_CTRL_BRAM_INITP_02            = 256'h0,
  parameter         C_CTRL_BRAM_INITP_03            = 256'h0,
  parameter         C_CTRL_BRAM_INITP_04            = 256'h0,
  parameter         C_CTRL_BRAM_INITP_05            = 256'h0,
  parameter         C_CTRL_BRAM_INITP_06            = 256'h0,
  parameter         C_CTRL_BRAM_INITP_07            = 256'h0
)
(
  /////////////////////////////
  // PIM Signal Declarations //
  /////////////////////////////
  // Port 0
  input  wire                                   FSL0_M_Clk,
  input  wire                                   FSL0_M_Write,
  input  wire [0:31]                            FSL0_M_Data,
  input  wire                                   FSL0_M_Control,
  output wire                                   FSL0_M_Full,
  input  wire                                   FSL0_S_Clk,
  input  wire                                   FSL0_S_Read,
  output wire [0:31]                            FSL0_S_Data,
  output wire                                   FSL0_S_Control,
  output wire                                   FSL0_S_Exists,
  input  wire                                   FSL0_B_M_Clk,
  input  wire                                   FSL0_B_M_Write,
  input  wire [0:31]                            FSL0_B_M_Data,
  input  wire                                   FSL0_B_M_Control,
  output wire                                   FSL0_B_M_Full,
  input  wire                                   FSL0_B_S_Clk,
  input  wire                                   FSL0_B_S_Read,
  output wire [0:31]                            FSL0_B_S_Data,
  output wire                                   FSL0_B_S_Control,
  output wire                                   FSL0_B_S_Exists,

  input  wire                                   SPLB0_Rst,
  input  wire                                   SPLB0_Clk,
  input  wire [0:31]                            SPLB0_PLB_ABus,
  input  wire                                   SPLB0_PLB_PAValid,
  input  wire                                   SPLB0_PLB_SAValid,
  input  wire [0:(C_SPLB0_MID_WIDTH-1)]         SPLB0_PLB_masterID,
  input  wire                                   SPLB0_PLB_RNW,
  input  wire [0:(C_SPLB0_DWIDTH/8-1)]          SPLB0_PLB_BE,
  input  wire [0:31]                            SPLB0_PLB_UABus,
  input  wire                                   SPLB0_PLB_rdPrim,
  input  wire                                   SPLB0_PLB_wrPrim,
  input  wire                                   SPLB0_PLB_abort,
  input  wire                                   SPLB0_PLB_busLock,
  input  wire [0:1]                             SPLB0_PLB_MSize,
  input  wire [0:3]                             SPLB0_PLB_size,
  input  wire [0:2]                             SPLB0_PLB_type,
  input  wire                                   SPLB0_PLB_lockErr,
  input  wire                                   SPLB0_PLB_wrPendReq,
  input  wire [0:1]                             SPLB0_PLB_wrPendPri,
  input  wire                                   SPLB0_PLB_rdPendReq,
  input  wire [0:1]                             SPLB0_PLB_rdPendPri,
  input  wire [0:1]                             SPLB0_PLB_reqPri,
  input  wire [0:15]                            SPLB0_PLB_TAttribute,
  input  wire                                   SPLB0_PLB_rdBurst,
  input  wire                                   SPLB0_PLB_wrBurst,
  input  wire [0:(C_SPLB0_DWIDTH-1)]            SPLB0_PLB_wrDBus,
  output wire                                   SPLB0_Sl_addrAck,
  output wire [0:1]                             SPLB0_Sl_SSize,
  output wire                                   SPLB0_Sl_wait,
  output wire                                   SPLB0_Sl_rearbitrate,
  output wire                                   SPLB0_Sl_wrDAck,
  output wire                                   SPLB0_Sl_wrComp,
  output wire                                   SPLB0_Sl_wrBTerm,
  output wire [0:(C_SPLB0_DWIDTH-1)]            SPLB0_Sl_rdDBus,
  output wire [0:3]                             SPLB0_Sl_rdWdAddr,
  output wire                                   SPLB0_Sl_rdDAck,
  output wire                                   SPLB0_Sl_rdComp,
  output wire                                   SPLB0_Sl_rdBTerm,
  output wire [0:(C_SPLB0_NUM_MASTERS-1)]       SPLB0_Sl_MBusy,
  output wire [0:(C_SPLB0_NUM_MASTERS-1)]       SPLB0_Sl_MRdErr,
  output wire [0:(C_SPLB0_NUM_MASTERS-1)]       SPLB0_Sl_MWrErr,
  output wire [0:(C_SPLB0_NUM_MASTERS-1)]       SPLB0_Sl_MIRQ,

  input  wire                                   SDMA0_Clk,
  output wire                                   SDMA0_Rx_IntOut,
  output wire                                   SDMA0_Tx_IntOut,
  output wire                                   SDMA0_RstOut,
  output wire [0:31]                            SDMA0_TX_D,
  output wire [0:3]                             SDMA0_TX_Rem,
  output wire                                   SDMA0_TX_SOF,
  output wire                                   SDMA0_TX_EOF,
  output wire                                   SDMA0_TX_SOP,
  output wire                                   SDMA0_TX_EOP,
  output wire                                   SDMA0_TX_Src_Rdy,
  input  wire                                   SDMA0_TX_Dst_Rdy,
  input  wire [0:31]                            SDMA0_RX_D,
  input  wire [0:3]                             SDMA0_RX_Rem,
  input  wire                                   SDMA0_RX_SOF,
  input  wire                                   SDMA0_RX_EOF,
  input  wire                                   SDMA0_RX_SOP,
  input  wire                                   SDMA0_RX_EOP,
  input  wire                                   SDMA0_RX_Src_Rdy,
  output wire                                   SDMA0_RX_Dst_Rdy,
  input  wire                                   SDMA_CTRL0_Rst,
  input  wire                                   SDMA_CTRL0_Clk,
  input  wire [0:31]                            SDMA_CTRL0_PLB_ABus,
  input  wire                                   SDMA_CTRL0_PLB_PAValid,
  input  wire                                   SDMA_CTRL0_PLB_SAValid,
  input  wire [0:(C_SDMA_CTRL0_MID_WIDTH-1)]    SDMA_CTRL0_PLB_masterID,
  input  wire                                   SDMA_CTRL0_PLB_RNW,
  input  wire [0:(C_SDMA_CTRL0_DWIDTH/8-1)]     SDMA_CTRL0_PLB_BE,
  input  wire [0:31]                            SDMA_CTRL0_PLB_UABus,
  input  wire                                   SDMA_CTRL0_PLB_rdPrim,
  input  wire                                   SDMA_CTRL0_PLB_wrPrim,
  input  wire                                   SDMA_CTRL0_PLB_abort,
  input  wire                                   SDMA_CTRL0_PLB_busLock,
  input  wire [0:1]                             SDMA_CTRL0_PLB_MSize,
  input  wire [0:3]                             SDMA_CTRL0_PLB_size,
  input  wire [0:2]                             SDMA_CTRL0_PLB_type,
  input  wire                                   SDMA_CTRL0_PLB_lockErr,
  input  wire                                   SDMA_CTRL0_PLB_wrPendReq,
  input  wire [0:1]                             SDMA_CTRL0_PLB_wrPendPri,
  input  wire                                   SDMA_CTRL0_PLB_rdPendReq,
  input  wire [0:1]                             SDMA_CTRL0_PLB_rdPendPri,
  input  wire [0:1]                             SDMA_CTRL0_PLB_reqPri,
  input  wire [0:15]                            SDMA_CTRL0_PLB_TAttribute,
  input  wire                                   SDMA_CTRL0_PLB_rdBurst,
  input  wire                                   SDMA_CTRL0_PLB_wrBurst,
  input  wire [0:(C_SDMA_CTRL0_DWIDTH-1)]       SDMA_CTRL0_PLB_wrDBus,
  output wire                                   SDMA_CTRL0_Sl_addrAck,
  output wire [0:1]                             SDMA_CTRL0_Sl_SSize,
  output wire                                   SDMA_CTRL0_Sl_wait,
  output wire                                   SDMA_CTRL0_Sl_rearbitrate,
  output wire                                   SDMA_CTRL0_Sl_wrDAck,
  output wire                                   SDMA_CTRL0_Sl_wrComp,
  output wire                                   SDMA_CTRL0_Sl_wrBTerm,
  output wire [0:(C_SDMA_CTRL0_DWIDTH-1)]       SDMA_CTRL0_Sl_rdDBus,
  output wire [0:3]                             SDMA_CTRL0_Sl_rdWdAddr,
  output wire                                   SDMA_CTRL0_Sl_rdDAck,
  output wire                                   SDMA_CTRL0_Sl_rdComp,
  output wire                                   SDMA_CTRL0_Sl_rdBTerm,
  output wire [0:(C_SDMA_CTRL0_NUM_MASTERS-1)]  SDMA_CTRL0_Sl_MBusy,
  output wire [0:(C_SDMA_CTRL0_NUM_MASTERS-1)]  SDMA_CTRL0_Sl_MRdErr,
  output wire [0:(C_SDMA_CTRL0_NUM_MASTERS-1)]  SDMA_CTRL0_Sl_MWrErr,
  output wire [0:(C_SDMA_CTRL0_NUM_MASTERS-1)]  SDMA_CTRL0_Sl_MIRQ,

  input  wire [31:0]                            PIM0_Addr,
  input  wire                                   PIM0_AddrReq,
  output wire                                   PIM0_AddrAck,
  input  wire                                   PIM0_RNW,
  input  wire [3:0]                             PIM0_Size,
  input  wire                                   PIM0_RdModWr,
  input  wire [C_PIM0_DATA_WIDTH-1:0]           PIM0_WrFIFO_Data,
  input  wire [(C_PIM0_DATA_WIDTH/8)-1:0]       PIM0_WrFIFO_BE,
  input  wire                                   PIM0_WrFIFO_Push,
  output wire [C_PIM0_DATA_WIDTH-1:0]           PIM0_RdFIFO_Data,
  input  wire                                   PIM0_RdFIFO_Pop,
  output wire [3:0]                             PIM0_RdFIFO_RdWdAddr,
  output wire                                   PIM0_WrFIFO_Empty,
  output wire                                   PIM0_WrFIFO_AlmostFull,
  input  wire                                   PIM0_WrFIFO_Flush,
  output wire                                   PIM0_RdFIFO_Empty,
  input  wire                                   PIM0_RdFIFO_Flush,
  output wire [1:0]                             PIM0_RdFIFO_Latency,
  output wire                                   PIM0_InitDone,

  input  wire                                   PPC440MC0_MIMCReadNotWrite,
  input  wire [0:35]                            PPC440MC0_MIMCAddress,
  input  wire                                   PPC440MC0_MIMCAddressValid,
  input  wire [0:127]                           PPC440MC0_MIMCWriteData,
  input  wire                                   PPC440MC0_MIMCWriteDataValid,
  input  wire [0:15]                            PPC440MC0_MIMCByteEnable,
  input  wire                                   PPC440MC0_MIMCBankConflict,
  input  wire                                   PPC440MC0_MIMCRowConflict,
  output wire [0:127]                           PPC440MC0_MCMIReadData,
  output wire                                   PPC440MC0_MCMIReadDataValid,
  output wire                                   PPC440MC0_MCMIReadDataErr,
  output wire                                   PPC440MC0_MCMIAddrReadyToAccept,

  input  wire                                   VFBC0_Cmd_Clk,
  input  wire                                   VFBC0_Cmd_Reset,
  input  wire [31:0]                            VFBC0_Cmd_Data,
  input  wire                                   VFBC0_Cmd_Write,
  input  wire                                   VFBC0_Cmd_End,
  output wire                                   VFBC0_Cmd_Full,
  output wire                                   VFBC0_Cmd_Almost_Full,
  output wire                                   VFBC0_Cmd_Idle,
  input  wire                                   VFBC0_Wd_Clk,
  input  wire                                   VFBC0_Wd_Reset,
  input  wire                                   VFBC0_Wd_Write,
  input  wire                                   VFBC0_Wd_End_Burst,
  input  wire                                   VFBC0_Wd_Flush,
  input  wire [C_VFBC0_RDWD_DATA_WIDTH-1:0]     VFBC0_Wd_Data,
  input  wire [C_VFBC0_RDWD_DATA_WIDTH/8-1:0]   VFBC0_Wd_Data_BE,
  output wire                                   VFBC0_Wd_Full,
  output wire                                   VFBC0_Wd_Almost_Full,
  input  wire                                   VFBC0_Rd_Clk,
  input  wire                                   VFBC0_Rd_Reset,
  input  wire                                   VFBC0_Rd_Read,
  input  wire                                   VFBC0_Rd_End_Burst,
  input  wire                                   VFBC0_Rd_Flush,
  output wire [C_VFBC0_RDWD_DATA_WIDTH-1:0]     VFBC0_Rd_Data,
  output wire                                   VFBC0_Rd_Empty,
  output wire                                   VFBC0_Rd_Almost_Empty,

  input  wire                                   MCB0_cmd_clk,
  input  wire                                   MCB0_cmd_en,
  input  wire [2:0]                             MCB0_cmd_instr,
  input  wire [5:0]                             MCB0_cmd_bl,
  input  wire [29:0]                            MCB0_cmd_byte_addr,
  output wire                                   MCB0_cmd_empty,
  output wire                                   MCB0_cmd_full,
  input  wire                                   MCB0_wr_clk,
  input  wire                                   MCB0_wr_en,
  input  wire [C_PIM0_DATA_WIDTH/8-1:0]         MCB0_wr_mask,
  input  wire [C_PIM0_DATA_WIDTH-1:0]           MCB0_wr_data,
  output wire                                   MCB0_wr_full,
  output wire                                   MCB0_wr_empty,
  output wire [6:0]                             MCB0_wr_count,
  output wire                                   MCB0_wr_underrun,
  output wire                                   MCB0_wr_error,
  input  wire                                   MCB0_rd_clk,
  input  wire                                   MCB0_rd_en,
  output wire [C_PIM0_DATA_WIDTH-1:0]           MCB0_rd_data,
  output wire                                   MCB0_rd_full,
  output wire                                   MCB0_rd_empty,
  output wire [6:0]                             MCB0_rd_count,
  output wire                                   MCB0_rd_overflow,
  output wire                                   MCB0_rd_error,

  // Port 1
  input  wire                                   FSL1_M_Clk,
  input  wire                                   FSL1_M_Write,
  input  wire [0:31]                            FSL1_M_Data,
  input  wire                                   FSL1_M_Control,
  output wire                                   FSL1_M_Full,
  input  wire                                   FSL1_S_Clk,
  input  wire                                   FSL1_S_Read,
  output wire [0:31]                            FSL1_S_Data,
  output wire                                   FSL1_S_Control,
  output wire                                   FSL1_S_Exists,
  input  wire                                   FSL1_B_M_Clk,
  input  wire                                   FSL1_B_M_Write,
  input  wire [0:31]                            FSL1_B_M_Data,
  input  wire                                   FSL1_B_M_Control,
  output wire                                   FSL1_B_M_Full,
  input  wire                                   FSL1_B_S_Clk,
  input  wire                                   FSL1_B_S_Read,
  output wire [0:31]                            FSL1_B_S_Data,
  output wire                                   FSL1_B_S_Control,
  output wire                                   FSL1_B_S_Exists,

  input  wire                                   SPLB1_Rst,
  input  wire                                   SPLB1_Clk,
  input  wire [0:31]                            SPLB1_PLB_ABus,
  input  wire                                   SPLB1_PLB_PAValid,
  input  wire                                   SPLB1_PLB_SAValid,
  input  wire [0:(C_SPLB1_MID_WIDTH-1)]         SPLB1_PLB_masterID,
  input  wire                                   SPLB1_PLB_RNW,
  input  wire [0:(C_SPLB1_DWIDTH/8-1)]          SPLB1_PLB_BE,
  input  wire [0:31]                            SPLB1_PLB_UABus,
  input  wire                                   SPLB1_PLB_rdPrim,
  input  wire                                   SPLB1_PLB_wrPrim,
  input  wire                                   SPLB1_PLB_abort,
  input  wire                                   SPLB1_PLB_busLock,
  input  wire [0:1]                             SPLB1_PLB_MSize,
  input  wire [0:3]                             SPLB1_PLB_size,
  input  wire [0:2]                             SPLB1_PLB_type,
  input  wire                                   SPLB1_PLB_lockErr,
  input  wire                                   SPLB1_PLB_wrPendReq,
  input  wire [0:1]                             SPLB1_PLB_wrPendPri,
  input  wire                                   SPLB1_PLB_rdPendReq,
  input  wire [0:1]                             SPLB1_PLB_rdPendPri,
  input  wire [0:1]                             SPLB1_PLB_reqPri,
  input  wire [0:15]                            SPLB1_PLB_TAttribute,
  input  wire                                   SPLB1_PLB_rdBurst,
  input  wire                                   SPLB1_PLB_wrBurst,
  input  wire [0:(C_SPLB1_DWIDTH-1)]            SPLB1_PLB_wrDBus,
  output wire                                   SPLB1_Sl_addrAck,
  output wire [0:1]                             SPLB1_Sl_SSize,
  output wire                                   SPLB1_Sl_wait,
  output wire                                   SPLB1_Sl_rearbitrate,
  output wire                                   SPLB1_Sl_wrDAck,
  output wire                                   SPLB1_Sl_wrComp,
  output wire                                   SPLB1_Sl_wrBTerm,
  output wire [0:(C_SPLB1_DWIDTH-1)]            SPLB1_Sl_rdDBus,
  output wire [0:3]                             SPLB1_Sl_rdWdAddr,
  output wire                                   SPLB1_Sl_rdDAck,
  output wire                                   SPLB1_Sl_rdComp,
  output wire                                   SPLB1_Sl_rdBTerm,
  output wire [0:(C_SPLB1_NUM_MASTERS-1)]       SPLB1_Sl_MBusy,
  output wire [0:(C_SPLB1_NUM_MASTERS-1)]       SPLB1_Sl_MRdErr,
  output wire [0:(C_SPLB1_NUM_MASTERS-1)]       SPLB1_Sl_MWrErr,
  output wire [0:(C_SPLB1_NUM_MASTERS-1)]       SPLB1_Sl_MIRQ,

  input  wire                                   SDMA1_Clk,
  output wire                                   SDMA1_Rx_IntOut,
  output wire                                   SDMA1_Tx_IntOut,
  output wire                                   SDMA1_RstOut,
  output wire [0:31]                            SDMA1_TX_D,
  output wire [0:3]                             SDMA1_TX_Rem,
  output wire                                   SDMA1_TX_SOF,
  output wire                                   SDMA1_TX_EOF,
  output wire                                   SDMA1_TX_SOP,
  output wire                                   SDMA1_TX_EOP,
  output wire                                   SDMA1_TX_Src_Rdy,
  input  wire                                   SDMA1_TX_Dst_Rdy,
  input  wire [0:31]                            SDMA1_RX_D,
  input  wire [0:3]                             SDMA1_RX_Rem,
  input  wire                                   SDMA1_RX_SOF,
  input  wire                                   SDMA1_RX_EOF,
  input  wire                                   SDMA1_RX_SOP,
  input  wire                                   SDMA1_RX_EOP,
  input  wire                                   SDMA1_RX_Src_Rdy,
  output wire                                   SDMA1_RX_Dst_Rdy,
  input  wire                                   SDMA_CTRL1_Rst,
  input  wire                                   SDMA_CTRL1_Clk,
  input  wire [0:31]                            SDMA_CTRL1_PLB_ABus,
  input  wire                                   SDMA_CTRL1_PLB_PAValid,
  input  wire                                   SDMA_CTRL1_PLB_SAValid,
  input  wire [0:(C_SDMA_CTRL1_MID_WIDTH-1)]    SDMA_CTRL1_PLB_masterID,
  input  wire                                   SDMA_CTRL1_PLB_RNW,
  input  wire [0:(C_SDMA_CTRL1_DWIDTH/8-1)]     SDMA_CTRL1_PLB_BE,
  input  wire [0:31]                            SDMA_CTRL1_PLB_UABus,
  input  wire                                   SDMA_CTRL1_PLB_rdPrim,
  input  wire                                   SDMA_CTRL1_PLB_wrPrim,
  input  wire                                   SDMA_CTRL1_PLB_abort,
  input  wire                                   SDMA_CTRL1_PLB_busLock,
  input  wire [0:1]                             SDMA_CTRL1_PLB_MSize,
  input  wire [0:3]                             SDMA_CTRL1_PLB_size,
  input  wire [0:2]                             SDMA_CTRL1_PLB_type,
  input  wire                                   SDMA_CTRL1_PLB_lockErr,
  input  wire                                   SDMA_CTRL1_PLB_wrPendReq,
  input  wire [0:1]                             SDMA_CTRL1_PLB_wrPendPri,
  input  wire                                   SDMA_CTRL1_PLB_rdPendReq,
  input  wire [0:1]                             SDMA_CTRL1_PLB_rdPendPri,
  input  wire [0:1]                             SDMA_CTRL1_PLB_reqPri,
  input  wire [0:15]                            SDMA_CTRL1_PLB_TAttribute,
  input  wire                                   SDMA_CTRL1_PLB_rdBurst,
  input  wire                                   SDMA_CTRL1_PLB_wrBurst,
  input  wire [0:(C_SDMA_CTRL1_DWIDTH-1)]       SDMA_CTRL1_PLB_wrDBus,
  output wire                                   SDMA_CTRL1_Sl_addrAck,
  output wire [0:1]                             SDMA_CTRL1_Sl_SSize,
  output wire                                   SDMA_CTRL1_Sl_wait,
  output wire                                   SDMA_CTRL1_Sl_rearbitrate,
  output wire                                   SDMA_CTRL1_Sl_wrDAck,
  output wire                                   SDMA_CTRL1_Sl_wrComp,
  output wire                                   SDMA_CTRL1_Sl_wrBTerm,
  output wire [0:(C_SDMA_CTRL1_DWIDTH-1)]       SDMA_CTRL1_Sl_rdDBus,
  output wire [0:3]                             SDMA_CTRL1_Sl_rdWdAddr,
  output wire                                   SDMA_CTRL1_Sl_rdDAck,
  output wire                                   SDMA_CTRL1_Sl_rdComp,
  output wire                                   SDMA_CTRL1_Sl_rdBTerm,
  output wire [0:(C_SDMA_CTRL1_NUM_MASTERS-1)]  SDMA_CTRL1_Sl_MBusy,
  output wire [0:(C_SDMA_CTRL1_NUM_MASTERS-1)]  SDMA_CTRL1_Sl_MRdErr,
  output wire [0:(C_SDMA_CTRL1_NUM_MASTERS-1)]  SDMA_CTRL1_Sl_MWrErr,
  output wire [0:(C_SDMA_CTRL1_NUM_MASTERS-1)]  SDMA_CTRL1_Sl_MIRQ,

  input  wire [31:0]                            PIM1_Addr,
  input  wire                                   PIM1_AddrReq,
  output wire                                   PIM1_AddrAck,
  input  wire                                   PIM1_RNW,
  input  wire [3:0]                             PIM1_Size,
  input  wire                                   PIM1_RdModWr,
  input  wire [C_PIM1_DATA_WIDTH-1:0]           PIM1_WrFIFO_Data,
  input  wire [(C_PIM1_DATA_WIDTH/8)-1:0]       PIM1_WrFIFO_BE,
  input  wire                                   PIM1_WrFIFO_Push,
  output wire [C_PIM1_DATA_WIDTH-1:0]           PIM1_RdFIFO_Data,
  input  wire                                   PIM1_RdFIFO_Pop,
  output wire [3:0]                             PIM1_RdFIFO_RdWdAddr,
  output wire                                   PIM1_WrFIFO_Empty,
  output wire                                   PIM1_WrFIFO_AlmostFull,
  input  wire                                   PIM1_WrFIFO_Flush,
  output wire                                   PIM1_RdFIFO_Empty,
  input  wire                                   PIM1_RdFIFO_Flush,
  output wire [1:0]                             PIM1_RdFIFO_Latency,
  output wire                                   PIM1_InitDone,

  input  wire                                   PPC440MC1_MIMCReadNotWrite,
  input  wire [0:35]                            PPC440MC1_MIMCAddress,
  input  wire                                   PPC440MC1_MIMCAddressValid,
  input  wire [0:127]                           PPC440MC1_MIMCWriteData,
  input  wire                                   PPC440MC1_MIMCWriteDataValid,
  input  wire [0:15]                            PPC440MC1_MIMCByteEnable,
  input  wire                                   PPC440MC1_MIMCBankConflict,
  input  wire                                   PPC440MC1_MIMCRowConflict,
  output wire [0:127]                           PPC440MC1_MCMIReadData,
  output wire                                   PPC440MC1_MCMIReadDataValid,
  output wire                                   PPC440MC1_MCMIReadDataErr,
  output wire                                   PPC440MC1_MCMIAddrReadyToAccept,

  input  wire                                   VFBC1_Cmd_Clk,
  input  wire                                   VFBC1_Cmd_Reset,
  input  wire [31:0]                            VFBC1_Cmd_Data,
  input  wire                                   VFBC1_Cmd_Write,
  input  wire                                   VFBC1_Cmd_End,
  output wire                                   VFBC1_Cmd_Full,
  output wire                                   VFBC1_Cmd_Almost_Full,
  output wire                                   VFBC1_Cmd_Idle,
  input  wire                                   VFBC1_Wd_Clk,
  input  wire                                   VFBC1_Wd_Reset,
  input  wire                                   VFBC1_Wd_Write,
  input  wire                                   VFBC1_Wd_End_Burst,
  input  wire                                   VFBC1_Wd_Flush,
  input  wire [C_VFBC1_RDWD_DATA_WIDTH-1:0]     VFBC1_Wd_Data,
  input  wire [C_VFBC1_RDWD_DATA_WIDTH/8-1:0]   VFBC1_Wd_Data_BE,
  output wire                                   VFBC1_Wd_Full,
  output wire                                   VFBC1_Wd_Almost_Full,
  input  wire                                   VFBC1_Rd_Clk,
  input  wire                                   VFBC1_Rd_Reset,
  input  wire                                   VFBC1_Rd_Read,
  input  wire                                   VFBC1_Rd_End_Burst,
  input  wire                                   VFBC1_Rd_Flush,
  output wire [C_VFBC1_RDWD_DATA_WIDTH-1:0]     VFBC1_Rd_Data,
  output wire                                   VFBC1_Rd_Empty,
  output wire                                   VFBC1_Rd_Almost_Empty,

  input  wire                                   MCB1_cmd_clk,
  input  wire                                   MCB1_cmd_en,
  input  wire [2:0]                             MCB1_cmd_instr,
  input  wire [5:0]                             MCB1_cmd_bl,
  input  wire [29:0]                            MCB1_cmd_byte_addr,
  output wire                                   MCB1_cmd_empty,
  output wire                                   MCB1_cmd_full,
  input  wire                                   MCB1_wr_clk,
  input  wire                                   MCB1_wr_en,
  input  wire [C_PIM1_DATA_WIDTH/8-1:0]         MCB1_wr_mask,
  input  wire [C_PIM1_DATA_WIDTH-1:0]           MCB1_wr_data,
  output wire                                   MCB1_wr_full,
  output wire                                   MCB1_wr_empty,
  output wire [6:0]                             MCB1_wr_count,
  output wire                                   MCB1_wr_underrun,
  output wire                                   MCB1_wr_error,
  input  wire                                   MCB1_rd_clk,
  input  wire                                   MCB1_rd_en,
  output wire [C_PIM1_DATA_WIDTH-1:0]           MCB1_rd_data,
  output wire                                   MCB1_rd_full,
  output wire                                   MCB1_rd_empty,
  output wire [6:0]                             MCB1_rd_count,
  output wire                                   MCB1_rd_overflow,
  output wire                                   MCB1_rd_error,

  // Port 2
  input  wire                                   FSL2_M_Clk,
  input  wire                                   FSL2_M_Write,
  input  wire [0:31]                            FSL2_M_Data,
  input  wire                                   FSL2_M_Control,
  output wire                                   FSL2_M_Full,
  input  wire                                   FSL2_S_Clk,
  input  wire                                   FSL2_S_Read,
  output wire [0:31]                            FSL2_S_Data,
  output wire                                   FSL2_S_Control,
  output wire                                   FSL2_S_Exists,
  input  wire                                   FSL2_B_M_Clk,
  input  wire                                   FSL2_B_M_Write,
  input  wire [0:31]                            FSL2_B_M_Data,
  input  wire                                   FSL2_B_M_Control,
  output wire                                   FSL2_B_M_Full,
  input  wire                                   FSL2_B_S_Clk,
  input  wire                                   FSL2_B_S_Read,
  output wire [0:31]                            FSL2_B_S_Data,
  output wire                                   FSL2_B_S_Control,
  output wire                                   FSL2_B_S_Exists,

  input  wire                                   SPLB2_Rst,
  input  wire                                   SPLB2_Clk,
  input  wire [0:31]                            SPLB2_PLB_ABus,
  input  wire                                   SPLB2_PLB_PAValid,
  input  wire                                   SPLB2_PLB_SAValid,
  input  wire [0:(C_SPLB2_MID_WIDTH-1)]         SPLB2_PLB_masterID,
  input  wire                                   SPLB2_PLB_RNW,
  input  wire [0:(C_SPLB2_DWIDTH/8-1)]          SPLB2_PLB_BE,
  input  wire [0:31]                            SPLB2_PLB_UABus,
  input  wire                                   SPLB2_PLB_rdPrim,
  input  wire                                   SPLB2_PLB_wrPrim,
  input  wire                                   SPLB2_PLB_abort,
  input  wire                                   SPLB2_PLB_busLock,
  input  wire [0:1]                             SPLB2_PLB_MSize,
  input  wire [0:3]                             SPLB2_PLB_size,
  input  wire [0:2]                             SPLB2_PLB_type,
  input  wire                                   SPLB2_PLB_lockErr,
  input  wire                                   SPLB2_PLB_wrPendReq,
  input  wire [0:1]                             SPLB2_PLB_wrPendPri,
  input  wire                                   SPLB2_PLB_rdPendReq,
  input  wire [0:1]                             SPLB2_PLB_rdPendPri,
  input  wire [0:1]                             SPLB2_PLB_reqPri,
  input  wire [0:15]                            SPLB2_PLB_TAttribute,
  input  wire                                   SPLB2_PLB_rdBurst,
  input  wire                                   SPLB2_PLB_wrBurst,
  input  wire [0:(C_SPLB2_DWIDTH-1)]            SPLB2_PLB_wrDBus,
  output wire                                   SPLB2_Sl_addrAck,
  output wire [0:1]                             SPLB2_Sl_SSize,
  output wire                                   SPLB2_Sl_wait,
  output wire                                   SPLB2_Sl_rearbitrate,
  output wire                                   SPLB2_Sl_wrDAck,
  output wire                                   SPLB2_Sl_wrComp,
  output wire                                   SPLB2_Sl_wrBTerm,
  output wire [0:(C_SPLB2_DWIDTH-1)]            SPLB2_Sl_rdDBus,
  output wire [0:3]                             SPLB2_Sl_rdWdAddr,
  output wire                                   SPLB2_Sl_rdDAck,
  output wire                                   SPLB2_Sl_rdComp,
  output wire                                   SPLB2_Sl_rdBTerm,
  output wire [0:(C_SPLB2_NUM_MASTERS-1)]       SPLB2_Sl_MBusy,
  output wire [0:(C_SPLB2_NUM_MASTERS-1)]       SPLB2_Sl_MRdErr,
  output wire [0:(C_SPLB2_NUM_MASTERS-1)]       SPLB2_Sl_MWrErr,
  output wire [0:(C_SPLB2_NUM_MASTERS-1)]       SPLB2_Sl_MIRQ,

  input  wire                                   SDMA2_Clk,
  output wire                                   SDMA2_Rx_IntOut,
  output wire                                   SDMA2_Tx_IntOut,
  output wire                                   SDMA2_RstOut,
  output wire [0:31]                            SDMA2_TX_D,
  output wire [0:3]                             SDMA2_TX_Rem,
  output wire                                   SDMA2_TX_SOF,
  output wire                                   SDMA2_TX_EOF,
  output wire                                   SDMA2_TX_SOP,
  output wire                                   SDMA2_TX_EOP,
  output wire                                   SDMA2_TX_Src_Rdy,
  input  wire                                   SDMA2_TX_Dst_Rdy,
  input  wire [0:31]                            SDMA2_RX_D,
  input  wire [0:3]                             SDMA2_RX_Rem,
  input  wire                                   SDMA2_RX_SOF,
  input  wire                                   SDMA2_RX_EOF,
  input  wire                                   SDMA2_RX_SOP,
  input  wire                                   SDMA2_RX_EOP,
  input  wire                                   SDMA2_RX_Src_Rdy,
  output wire                                   SDMA2_RX_Dst_Rdy,
  input  wire                                   SDMA_CTRL2_Rst,
  input  wire                                   SDMA_CTRL2_Clk,
  input  wire [0:31]                            SDMA_CTRL2_PLB_ABus,
  input  wire                                   SDMA_CTRL2_PLB_PAValid,
  input  wire                                   SDMA_CTRL2_PLB_SAValid,
  input  wire [0:(C_SDMA_CTRL2_MID_WIDTH-1)]    SDMA_CTRL2_PLB_masterID,
  input  wire                                   SDMA_CTRL2_PLB_RNW,
  input  wire [0:(C_SDMA_CTRL2_DWIDTH/8-1)]     SDMA_CTRL2_PLB_BE,
  input  wire [0:31]                            SDMA_CTRL2_PLB_UABus,
  input  wire                                   SDMA_CTRL2_PLB_rdPrim,
  input  wire                                   SDMA_CTRL2_PLB_wrPrim,
  input  wire                                   SDMA_CTRL2_PLB_abort,
  input  wire                                   SDMA_CTRL2_PLB_busLock,
  input  wire [0:1]                             SDMA_CTRL2_PLB_MSize,
  input  wire [0:3]                             SDMA_CTRL2_PLB_size,
  input  wire [0:2]                             SDMA_CTRL2_PLB_type,
  input  wire                                   SDMA_CTRL2_PLB_lockErr,
  input  wire                                   SDMA_CTRL2_PLB_wrPendReq,
  input  wire [0:1]                             SDMA_CTRL2_PLB_wrPendPri,
  input  wire                                   SDMA_CTRL2_PLB_rdPendReq,
  input  wire [0:1]                             SDMA_CTRL2_PLB_rdPendPri,
  input  wire [0:1]                             SDMA_CTRL2_PLB_reqPri,
  input  wire [0:15]                            SDMA_CTRL2_PLB_TAttribute,
  input  wire                                   SDMA_CTRL2_PLB_rdBurst,
  input  wire                                   SDMA_CTRL2_PLB_wrBurst,
  input  wire [0:(C_SDMA_CTRL2_DWIDTH-1)]       SDMA_CTRL2_PLB_wrDBus,
  output wire                                   SDMA_CTRL2_Sl_addrAck,
  output wire [0:1]                             SDMA_CTRL2_Sl_SSize,
  output wire                                   SDMA_CTRL2_Sl_wait,
  output wire                                   SDMA_CTRL2_Sl_rearbitrate,
  output wire                                   SDMA_CTRL2_Sl_wrDAck,
  output wire                                   SDMA_CTRL2_Sl_wrComp,
  output wire                                   SDMA_CTRL2_Sl_wrBTerm,
  output wire [0:(C_SDMA_CTRL2_DWIDTH-1)]       SDMA_CTRL2_Sl_rdDBus,
  output wire [0:3]                             SDMA_CTRL2_Sl_rdWdAddr,
  output wire                                   SDMA_CTRL2_Sl_rdDAck,
  output wire                                   SDMA_CTRL2_Sl_rdComp,
  output wire                                   SDMA_CTRL2_Sl_rdBTerm,
  output wire [0:(C_SDMA_CTRL2_NUM_MASTERS-1)]  SDMA_CTRL2_Sl_MBusy,
  output wire [0:(C_SDMA_CTRL2_NUM_MASTERS-1)]  SDMA_CTRL2_Sl_MRdErr,
  output wire [0:(C_SDMA_CTRL2_NUM_MASTERS-1)]  SDMA_CTRL2_Sl_MWrErr,
  output wire [0:(C_SDMA_CTRL2_NUM_MASTERS-1)]  SDMA_CTRL2_Sl_MIRQ,

  input  wire [31:0]                            PIM2_Addr,
  input  wire                                   PIM2_AddrReq,
  output wire                                   PIM2_AddrAck,
  input  wire                                   PIM2_RNW,
  input  wire [3:0]                             PIM2_Size,
  input  wire                                   PIM2_RdModWr,
  input  wire [C_PIM2_DATA_WIDTH-1:0]           PIM2_WrFIFO_Data,
  input  wire [(C_PIM2_DATA_WIDTH/8)-1:0]       PIM2_WrFIFO_BE,
  input  wire                                   PIM2_WrFIFO_Push,
  output wire [C_PIM2_DATA_WIDTH-1:0]           PIM2_RdFIFO_Data,
  input  wire                                   PIM2_RdFIFO_Pop,
  output wire [3:0]                             PIM2_RdFIFO_RdWdAddr,
  output wire                                   PIM2_WrFIFO_Empty,
  output wire                                   PIM2_WrFIFO_AlmostFull,
  input  wire                                   PIM2_WrFIFO_Flush,
  output wire                                   PIM2_RdFIFO_Empty,
  input  wire                                   PIM2_RdFIFO_Flush,
  output wire [1:0]                             PIM2_RdFIFO_Latency,
  output wire                                   PIM2_InitDone,

  input  wire                                   PPC440MC2_MIMCReadNotWrite,
  input  wire [0:35]                            PPC440MC2_MIMCAddress,
  input  wire                                   PPC440MC2_MIMCAddressValid,
  input  wire [0:127]                           PPC440MC2_MIMCWriteData,
  input  wire                                   PPC440MC2_MIMCWriteDataValid,
  input  wire [0:15]                            PPC440MC2_MIMCByteEnable,
  input  wire                                   PPC440MC2_MIMCBankConflict,
  input  wire                                   PPC440MC2_MIMCRowConflict,
  output wire [0:127]                           PPC440MC2_MCMIReadData,
  output wire                                   PPC440MC2_MCMIReadDataValid,
  output wire                                   PPC440MC2_MCMIReadDataErr,
  output wire                                   PPC440MC2_MCMIAddrReadyToAccept,

  input  wire                                   VFBC2_Cmd_Clk,
  input  wire                                   VFBC2_Cmd_Reset,
  input  wire [31:0]                            VFBC2_Cmd_Data,
  input  wire                                   VFBC2_Cmd_Write,
  input  wire                                   VFBC2_Cmd_End,
  output wire                                   VFBC2_Cmd_Full,
  output wire                                   VFBC2_Cmd_Almost_Full,
  output wire                                   VFBC2_Cmd_Idle,
  input  wire                                   VFBC2_Wd_Clk,
  input  wire                                   VFBC2_Wd_Reset,
  input  wire                                   VFBC2_Wd_Write,
  input  wire                                   VFBC2_Wd_End_Burst,
  input  wire                                   VFBC2_Wd_Flush,
  input  wire [C_VFBC2_RDWD_DATA_WIDTH-1:0]     VFBC2_Wd_Data,
  input  wire [C_VFBC2_RDWD_DATA_WIDTH/8-1:0]   VFBC2_Wd_Data_BE,
  output wire                                   VFBC2_Wd_Full,
  output wire                                   VFBC2_Wd_Almost_Full,
  input  wire                                   VFBC2_Rd_Clk,
  input  wire                                   VFBC2_Rd_Reset,
  input  wire                                   VFBC2_Rd_Read,
  input  wire                                   VFBC2_Rd_End_Burst,
  input  wire                                   VFBC2_Rd_Flush,
  output wire [C_VFBC2_RDWD_DATA_WIDTH-1:0]     VFBC2_Rd_Data,
  output wire                                   VFBC2_Rd_Empty,
  output wire                                   VFBC2_Rd_Almost_Empty,

  input  wire                                   MCB2_cmd_clk,
  input  wire                                   MCB2_cmd_en,
  input  wire [2:0]                             MCB2_cmd_instr,
  input  wire [5:0]                             MCB2_cmd_bl,
  input  wire [29:0]                            MCB2_cmd_byte_addr,
  output wire                                   MCB2_cmd_empty,
  output wire                                   MCB2_cmd_full,
  input  wire                                   MCB2_wr_clk,
  input  wire                                   MCB2_wr_en,
  input  wire [C_PIM2_DATA_WIDTH/8-1:0]         MCB2_wr_mask,
  input  wire [C_PIM2_DATA_WIDTH-1:0]           MCB2_wr_data,
  output wire                                   MCB2_wr_full,
  output wire                                   MCB2_wr_empty,
  output wire [6:0]                             MCB2_wr_count,
  output wire                                   MCB2_wr_underrun,
  output wire                                   MCB2_wr_error,
  input  wire                                   MCB2_rd_clk,
  input  wire                                   MCB2_rd_en,
  output wire [C_PIM2_DATA_WIDTH-1:0]           MCB2_rd_data,
  output wire                                   MCB2_rd_full,
  output wire                                   MCB2_rd_empty,
  output wire [6:0]                             MCB2_rd_count,
  output wire                                   MCB2_rd_overflow,
  output wire                                   MCB2_rd_error,

  // Port 3
  input  wire                                   FSL3_M_Clk,
  input  wire                                   FSL3_M_Write,
  input  wire [0:31]                            FSL3_M_Data,
  input  wire                                   FSL3_M_Control,
  output wire                                   FSL3_M_Full,
  input  wire                                   FSL3_S_Clk,
  input  wire                                   FSL3_S_Read,
  output wire [0:31]                            FSL3_S_Data,
  output wire                                   FSL3_S_Control,
  output wire                                   FSL3_S_Exists,
  input  wire                                   FSL3_B_M_Clk,
  input  wire                                   FSL3_B_M_Write,
  input  wire [0:31]                            FSL3_B_M_Data,
  input  wire                                   FSL3_B_M_Control,
  output wire                                   FSL3_B_M_Full,
  input  wire                                   FSL3_B_S_Clk,
  input  wire                                   FSL3_B_S_Read,
  output wire [0:31]                            FSL3_B_S_Data,
  output wire                                   FSL3_B_S_Control,
  output wire                                   FSL3_B_S_Exists,

  input  wire                                   SPLB3_Rst,
  input  wire                                   SPLB3_Clk,
  input  wire [0:31]                            SPLB3_PLB_ABus,
  input  wire                                   SPLB3_PLB_PAValid,
  input  wire                                   SPLB3_PLB_SAValid,
  input  wire [0:(C_SPLB3_MID_WIDTH-1)]         SPLB3_PLB_masterID,
  input  wire                                   SPLB3_PLB_RNW,
  input  wire [0:(C_SPLB3_DWIDTH/8-1)]          SPLB3_PLB_BE,
  input  wire [0:31]                            SPLB3_PLB_UABus,
  input  wire                                   SPLB3_PLB_rdPrim,
  input  wire                                   SPLB3_PLB_wrPrim,
  input  wire                                   SPLB3_PLB_abort,
  input  wire                                   SPLB3_PLB_busLock,
  input  wire [0:1]                             SPLB3_PLB_MSize,
  input  wire [0:3]                             SPLB3_PLB_size,
  input  wire [0:2]                             SPLB3_PLB_type,
  input  wire                                   SPLB3_PLB_lockErr,
  input  wire                                   SPLB3_PLB_wrPendReq,
  input  wire [0:1]                             SPLB3_PLB_wrPendPri,
  input  wire                                   SPLB3_PLB_rdPendReq,
  input  wire [0:1]                             SPLB3_PLB_rdPendPri,
  input  wire [0:1]                             SPLB3_PLB_reqPri,
  input  wire [0:15]                            SPLB3_PLB_TAttribute,
  input  wire                                   SPLB3_PLB_rdBurst,
  input  wire                                   SPLB3_PLB_wrBurst,
  input  wire [0:(C_SPLB3_DWIDTH-1)]            SPLB3_PLB_wrDBus,
  output wire                                   SPLB3_Sl_addrAck,
  output wire [0:1]                             SPLB3_Sl_SSize,
  output wire                                   SPLB3_Sl_wait,
  output wire                                   SPLB3_Sl_rearbitrate,
  output wire                                   SPLB3_Sl_wrDAck,
  output wire                                   SPLB3_Sl_wrComp,
  output wire                                   SPLB3_Sl_wrBTerm,
  output wire [0:(C_SPLB3_DWIDTH-1)]            SPLB3_Sl_rdDBus,
  output wire [0:3]                             SPLB3_Sl_rdWdAddr,
  output wire                                   SPLB3_Sl_rdDAck,
  output wire                                   SPLB3_Sl_rdComp,
  output wire                                   SPLB3_Sl_rdBTerm,
  output wire [0:(C_SPLB3_NUM_MASTERS-1)]       SPLB3_Sl_MBusy,
  output wire [0:(C_SPLB3_NUM_MASTERS-1)]       SPLB3_Sl_MRdErr,
  output wire [0:(C_SPLB3_NUM_MASTERS-1)]       SPLB3_Sl_MWrErr,
  output wire [0:(C_SPLB3_NUM_MASTERS-1)]       SPLB3_Sl_MIRQ,

  input  wire                                   SDMA3_Clk,
  output wire                                   SDMA3_Rx_IntOut,
  output wire                                   SDMA3_Tx_IntOut,
  output wire                                   SDMA3_RstOut,
  output wire [0:31]                            SDMA3_TX_D,
  output wire [0:3]                             SDMA3_TX_Rem,
  output wire                                   SDMA3_TX_SOF,
  output wire                                   SDMA3_TX_EOF,
  output wire                                   SDMA3_TX_SOP,
  output wire                                   SDMA3_TX_EOP,
  output wire                                   SDMA3_TX_Src_Rdy,
  input  wire                                   SDMA3_TX_Dst_Rdy,
  input  wire [0:31]                            SDMA3_RX_D,
  input  wire [0:3]                             SDMA3_RX_Rem,
  input  wire                                   SDMA3_RX_SOF,
  input  wire                                   SDMA3_RX_EOF,
  input  wire                                   SDMA3_RX_SOP,
  input  wire                                   SDMA3_RX_EOP,
  input  wire                                   SDMA3_RX_Src_Rdy,
  output wire                                   SDMA3_RX_Dst_Rdy,
  input  wire                                   SDMA_CTRL3_Rst,
  input  wire                                   SDMA_CTRL3_Clk,
  input  wire [0:31]                            SDMA_CTRL3_PLB_ABus,
  input  wire                                   SDMA_CTRL3_PLB_PAValid,
  input  wire                                   SDMA_CTRL3_PLB_SAValid,
  input  wire [0:(C_SDMA_CTRL3_MID_WIDTH-1)]    SDMA_CTRL3_PLB_masterID,
  input  wire                                   SDMA_CTRL3_PLB_RNW,
  input  wire [0:(C_SDMA_CTRL3_DWIDTH/8-1)]     SDMA_CTRL3_PLB_BE,
  input  wire [0:31]                            SDMA_CTRL3_PLB_UABus,
  input  wire                                   SDMA_CTRL3_PLB_rdPrim,
  input  wire                                   SDMA_CTRL3_PLB_wrPrim,
  input  wire                                   SDMA_CTRL3_PLB_abort,
  input  wire                                   SDMA_CTRL3_PLB_busLock,
  input  wire [0:1]                             SDMA_CTRL3_PLB_MSize,
  input  wire [0:3]                             SDMA_CTRL3_PLB_size,
  input  wire [0:2]                             SDMA_CTRL3_PLB_type,
  input  wire                                   SDMA_CTRL3_PLB_lockErr,
  input  wire                                   SDMA_CTRL3_PLB_wrPendReq,
  input  wire [0:1]                             SDMA_CTRL3_PLB_wrPendPri,
  input  wire                                   SDMA_CTRL3_PLB_rdPendReq,
  input  wire [0:1]                             SDMA_CTRL3_PLB_rdPendPri,
  input  wire [0:1]                             SDMA_CTRL3_PLB_reqPri,
  input  wire [0:15]                            SDMA_CTRL3_PLB_TAttribute,
  input  wire                                   SDMA_CTRL3_PLB_rdBurst,
  input  wire                                   SDMA_CTRL3_PLB_wrBurst,
  input  wire [0:(C_SDMA_CTRL3_DWIDTH-1)]       SDMA_CTRL3_PLB_wrDBus,
  output wire                                   SDMA_CTRL3_Sl_addrAck,
  output wire [0:1]                             SDMA_CTRL3_Sl_SSize,
  output wire                                   SDMA_CTRL3_Sl_wait,
  output wire                                   SDMA_CTRL3_Sl_rearbitrate,
  output wire                                   SDMA_CTRL3_Sl_wrDAck,
  output wire                                   SDMA_CTRL3_Sl_wrComp,
  output wire                                   SDMA_CTRL3_Sl_wrBTerm,
  output wire [0:(C_SDMA_CTRL3_DWIDTH-1)]       SDMA_CTRL3_Sl_rdDBus,
  output wire [0:3]                             SDMA_CTRL3_Sl_rdWdAddr,
  output wire                                   SDMA_CTRL3_Sl_rdDAck,
  output wire                                   SDMA_CTRL3_Sl_rdComp,
  output wire                                   SDMA_CTRL3_Sl_rdBTerm,
  output wire [0:(C_SDMA_CTRL3_NUM_MASTERS-1)]  SDMA_CTRL3_Sl_MBusy,
  output wire [0:(C_SDMA_CTRL3_NUM_MASTERS-1)]  SDMA_CTRL3_Sl_MRdErr,
  output wire [0:(C_SDMA_CTRL3_NUM_MASTERS-1)]  SDMA_CTRL3_Sl_MWrErr,
  output wire [0:(C_SDMA_CTRL3_NUM_MASTERS-1)]  SDMA_CTRL3_Sl_MIRQ,

  input  wire [31:0]                            PIM3_Addr,
  input  wire                                   PIM3_AddrReq,
  output wire                                   PIM3_AddrAck,
  input  wire                                   PIM3_RNW,
  input  wire [3:0]                             PIM3_Size,
  input  wire                                   PIM3_RdModWr,
  input  wire [C_PIM3_DATA_WIDTH-1:0]           PIM3_WrFIFO_Data,
  input  wire [(C_PIM3_DATA_WIDTH/8)-1:0]       PIM3_WrFIFO_BE,
  input  wire                                   PIM3_WrFIFO_Push,
  output wire [C_PIM3_DATA_WIDTH-1:0]           PIM3_RdFIFO_Data,
  input  wire                                   PIM3_RdFIFO_Pop,
  output wire [3:0]                             PIM3_RdFIFO_RdWdAddr,
  output wire                                   PIM3_WrFIFO_Empty,
  output wire                                   PIM3_WrFIFO_AlmostFull,
  input  wire                                   PIM3_WrFIFO_Flush,
  output wire                                   PIM3_RdFIFO_Empty,
  input  wire                                   PIM3_RdFIFO_Flush,
  output wire [1:0]                             PIM3_RdFIFO_Latency,
  output wire                                   PIM3_InitDone,

  input  wire                                   PPC440MC3_MIMCReadNotWrite,
  input  wire [0:35]                            PPC440MC3_MIMCAddress,
  input  wire                                   PPC440MC3_MIMCAddressValid,
  input  wire [0:127]                           PPC440MC3_MIMCWriteData,
  input  wire                                   PPC440MC3_MIMCWriteDataValid,
  input  wire [0:15]                            PPC440MC3_MIMCByteEnable,
  input  wire                                   PPC440MC3_MIMCBankConflict,
  input  wire                                   PPC440MC3_MIMCRowConflict,
  output wire [0:127]                           PPC440MC3_MCMIReadData,
  output wire                                   PPC440MC3_MCMIReadDataValid,
  output wire                                   PPC440MC3_MCMIReadDataErr,
  output wire                                   PPC440MC3_MCMIAddrReadyToAccept,

  input  wire                                   VFBC3_Cmd_Clk,
  input  wire                                   VFBC3_Cmd_Reset,
  input  wire [31:0]                            VFBC3_Cmd_Data,
  input  wire                                   VFBC3_Cmd_Write,
  input  wire                                   VFBC3_Cmd_End,
  output wire                                   VFBC3_Cmd_Full,
  output wire                                   VFBC3_Cmd_Almost_Full,
  output wire                                   VFBC3_Cmd_Idle,
  input  wire                                   VFBC3_Wd_Clk,
  input  wire                                   VFBC3_Wd_Reset,
  input  wire                                   VFBC3_Wd_Write,
  input  wire                                   VFBC3_Wd_End_Burst,
  input  wire                                   VFBC3_Wd_Flush,
  input  wire [C_VFBC3_RDWD_DATA_WIDTH-1:0]     VFBC3_Wd_Data,
  input  wire [C_VFBC3_RDWD_DATA_WIDTH/8-1:0]   VFBC3_Wd_Data_BE,
  output wire                                   VFBC3_Wd_Full,
  output wire                                   VFBC3_Wd_Almost_Full,
  input  wire                                   VFBC3_Rd_Clk,
  input  wire                                   VFBC3_Rd_Reset,
  input  wire                                   VFBC3_Rd_Read,
  input  wire                                   VFBC3_Rd_End_Burst,
  input  wire                                   VFBC3_Rd_Flush,
  output wire [C_VFBC3_RDWD_DATA_WIDTH-1:0]     VFBC3_Rd_Data,
  output wire                                   VFBC3_Rd_Empty,
  output wire                                   VFBC3_Rd_Almost_Empty,

  input  wire                                   MCB3_cmd_clk,
  input  wire                                   MCB3_cmd_en,
  input  wire [2:0]                             MCB3_cmd_instr,
  input  wire [5:0]                             MCB3_cmd_bl,
  input  wire [29:0]                            MCB3_cmd_byte_addr,
  output wire                                   MCB3_cmd_empty,
  output wire                                   MCB3_cmd_full,
  input  wire                                   MCB3_wr_clk,
  input  wire                                   MCB3_wr_en,
  input  wire [C_PIM3_DATA_WIDTH/8-1:0]         MCB3_wr_mask,
  input  wire [C_PIM3_DATA_WIDTH-1:0]           MCB3_wr_data,
  output wire                                   MCB3_wr_full,
  output wire                                   MCB3_wr_empty,
  output wire [6:0]                             MCB3_wr_count,
  output wire                                   MCB3_wr_underrun,
  output wire                                   MCB3_wr_error,
  input  wire                                   MCB3_rd_clk,
  input  wire                                   MCB3_rd_en,
  output wire [C_PIM3_DATA_WIDTH-1:0]           MCB3_rd_data,
  output wire                                   MCB3_rd_full,
  output wire                                   MCB3_rd_empty,
  output wire [6:0]                             MCB3_rd_count,
  output wire                                   MCB3_rd_overflow,
  output wire                                   MCB3_rd_error,

  // Port 4
  input  wire                                   FSL4_M_Clk,
  input  wire                                   FSL4_M_Write,
  input  wire [0:31]                            FSL4_M_Data,
  input  wire                                   FSL4_M_Control,
  output wire                                   FSL4_M_Full,
  input  wire                                   FSL4_S_Clk,
  input  wire                                   FSL4_S_Read,
  output wire [0:31]                            FSL4_S_Data,
  output wire                                   FSL4_S_Control,
  output wire                                   FSL4_S_Exists,
  input  wire                                   FSL4_B_M_Clk,
  input  wire                                   FSL4_B_M_Write,
  input  wire [0:31]                            FSL4_B_M_Data,
  input  wire                                   FSL4_B_M_Control,
  output wire                                   FSL4_B_M_Full,
  input  wire                                   FSL4_B_S_Clk,
  input  wire                                   FSL4_B_S_Read,
  output wire [0:31]                            FSL4_B_S_Data,
  output wire                                   FSL4_B_S_Control,
  output wire                                   FSL4_B_S_Exists,

  input  wire                                   SPLB4_Rst,
  input  wire                                   SPLB4_Clk,
  input  wire [0:31]                            SPLB4_PLB_ABus,
  input  wire                                   SPLB4_PLB_PAValid,
  input  wire                                   SPLB4_PLB_SAValid,
  input  wire [0:(C_SPLB4_MID_WIDTH-1)]         SPLB4_PLB_masterID,
  input  wire                                   SPLB4_PLB_RNW,
  input  wire [0:(C_SPLB4_DWIDTH/8-1)]          SPLB4_PLB_BE,
  input  wire [0:31]                            SPLB4_PLB_UABus,
  input  wire                                   SPLB4_PLB_rdPrim,
  input  wire                                   SPLB4_PLB_wrPrim,
  input  wire                                   SPLB4_PLB_abort,
  input  wire                                   SPLB4_PLB_busLock,
  input  wire [0:1]                             SPLB4_PLB_MSize,
  input  wire [0:3]                             SPLB4_PLB_size,
  input  wire [0:2]                             SPLB4_PLB_type,
  input  wire                                   SPLB4_PLB_lockErr,
  input  wire                                   SPLB4_PLB_wrPendReq,
  input  wire [0:1]                             SPLB4_PLB_wrPendPri,
  input  wire                                   SPLB4_PLB_rdPendReq,
  input  wire [0:1]                             SPLB4_PLB_rdPendPri,
  input  wire [0:1]                             SPLB4_PLB_reqPri,
  input  wire [0:15]                            SPLB4_PLB_TAttribute,
  input  wire                                   SPLB4_PLB_rdBurst,
  input  wire                                   SPLB4_PLB_wrBurst,
  input  wire [0:(C_SPLB4_DWIDTH-1)]            SPLB4_PLB_wrDBus,
  output wire                                   SPLB4_Sl_addrAck,
  output wire [0:1]                             SPLB4_Sl_SSize,
  output wire                                   SPLB4_Sl_wait,
  output wire                                   SPLB4_Sl_rearbitrate,
  output wire                                   SPLB4_Sl_wrDAck,
  output wire                                   SPLB4_Sl_wrComp,
  output wire                                   SPLB4_Sl_wrBTerm,
  output wire [0:(C_SPLB4_DWIDTH-1)]            SPLB4_Sl_rdDBus,
  output wire [0:3]                             SPLB4_Sl_rdWdAddr,
  output wire                                   SPLB4_Sl_rdDAck,
  output wire                                   SPLB4_Sl_rdComp,
  output wire                                   SPLB4_Sl_rdBTerm,
  output wire [0:(C_SPLB4_NUM_MASTERS-1)]       SPLB4_Sl_MBusy,
  output wire [0:(C_SPLB4_NUM_MASTERS-1)]       SPLB4_Sl_MRdErr,
  output wire [0:(C_SPLB4_NUM_MASTERS-1)]       SPLB4_Sl_MWrErr,
  output wire [0:(C_SPLB4_NUM_MASTERS-1)]       SPLB4_Sl_MIRQ,

  input  wire                                   SDMA4_Clk,
  output wire                                   SDMA4_Rx_IntOut,
  output wire                                   SDMA4_Tx_IntOut,
  output wire                                   SDMA4_RstOut,
  output wire [0:31]                            SDMA4_TX_D,
  output wire [0:3]                             SDMA4_TX_Rem,
  output wire                                   SDMA4_TX_SOF,
  output wire                                   SDMA4_TX_EOF,
  output wire                                   SDMA4_TX_SOP,
  output wire                                   SDMA4_TX_EOP,
  output wire                                   SDMA4_TX_Src_Rdy,
  input  wire                                   SDMA4_TX_Dst_Rdy,
  input  wire [0:31]                            SDMA4_RX_D,
  input  wire [0:3]                             SDMA4_RX_Rem,
  input  wire                                   SDMA4_RX_SOF,
  input  wire                                   SDMA4_RX_EOF,
  input  wire                                   SDMA4_RX_SOP,
  input  wire                                   SDMA4_RX_EOP,
  input  wire                                   SDMA4_RX_Src_Rdy,
  output wire                                   SDMA4_RX_Dst_Rdy,
  input  wire                                   SDMA_CTRL4_Rst,
  input  wire                                   SDMA_CTRL4_Clk,
  input  wire [0:31]                            SDMA_CTRL4_PLB_ABus,
  input  wire                                   SDMA_CTRL4_PLB_PAValid,
  input  wire                                   SDMA_CTRL4_PLB_SAValid,
  input  wire [0:(C_SDMA_CTRL4_MID_WIDTH-1)]    SDMA_CTRL4_PLB_masterID,
  input  wire                                   SDMA_CTRL4_PLB_RNW,
  input  wire [0:(C_SDMA_CTRL4_DWIDTH/8-1)]     SDMA_CTRL4_PLB_BE,
  input  wire [0:31]                            SDMA_CTRL4_PLB_UABus,
  input  wire                                   SDMA_CTRL4_PLB_rdPrim,
  input  wire                                   SDMA_CTRL4_PLB_wrPrim,
  input  wire                                   SDMA_CTRL4_PLB_abort,
  input  wire                                   SDMA_CTRL4_PLB_busLock,
  input  wire [0:1]                             SDMA_CTRL4_PLB_MSize,
  input  wire [0:3]                             SDMA_CTRL4_PLB_size,
  input  wire [0:2]                             SDMA_CTRL4_PLB_type,
  input  wire                                   SDMA_CTRL4_PLB_lockErr,
  input  wire                                   SDMA_CTRL4_PLB_wrPendReq,
  input  wire [0:1]                             SDMA_CTRL4_PLB_wrPendPri,
  input  wire                                   SDMA_CTRL4_PLB_rdPendReq,
  input  wire [0:1]                             SDMA_CTRL4_PLB_rdPendPri,
  input  wire [0:1]                             SDMA_CTRL4_PLB_reqPri,
  input  wire [0:15]                            SDMA_CTRL4_PLB_TAttribute,
  input  wire                                   SDMA_CTRL4_PLB_rdBurst,
  input  wire                                   SDMA_CTRL4_PLB_wrBurst,
  input  wire [0:(C_SDMA_CTRL4_DWIDTH-1)]       SDMA_CTRL4_PLB_wrDBus,
  output wire                                   SDMA_CTRL4_Sl_addrAck,
  output wire [0:1]                             SDMA_CTRL4_Sl_SSize,
  output wire                                   SDMA_CTRL4_Sl_wait,
  output wire                                   SDMA_CTRL4_Sl_rearbitrate,
  output wire                                   SDMA_CTRL4_Sl_wrDAck,
  output wire                                   SDMA_CTRL4_Sl_wrComp,
  output wire                                   SDMA_CTRL4_Sl_wrBTerm,
  output wire [0:(C_SDMA_CTRL4_DWIDTH-1)]       SDMA_CTRL4_Sl_rdDBus,
  output wire [0:3]                             SDMA_CTRL4_Sl_rdWdAddr,
  output wire                                   SDMA_CTRL4_Sl_rdDAck,
  output wire                                   SDMA_CTRL4_Sl_rdComp,
  output wire                                   SDMA_CTRL4_Sl_rdBTerm,
  output wire [0:(C_SDMA_CTRL4_NUM_MASTERS-1)]  SDMA_CTRL4_Sl_MBusy,
  output wire [0:(C_SDMA_CTRL4_NUM_MASTERS-1)]  SDMA_CTRL4_Sl_MRdErr,
  output wire [0:(C_SDMA_CTRL4_NUM_MASTERS-1)]  SDMA_CTRL4_Sl_MWrErr,
  output wire [0:(C_SDMA_CTRL4_NUM_MASTERS-1)]  SDMA_CTRL4_Sl_MIRQ,

  input  wire [31:0]                            PIM4_Addr,
  input  wire                                   PIM4_AddrReq,
  output wire                                   PIM4_AddrAck,
  input  wire                                   PIM4_RNW,
  input  wire [3:0]                             PIM4_Size,
  input  wire                                   PIM4_RdModWr,
  input  wire [C_PIM4_DATA_WIDTH-1:0]           PIM4_WrFIFO_Data,
  input  wire [(C_PIM4_DATA_WIDTH/8)-1:0]       PIM4_WrFIFO_BE,
  input  wire                                   PIM4_WrFIFO_Push,
  output wire [C_PIM4_DATA_WIDTH-1:0]           PIM4_RdFIFO_Data,
  input  wire                                   PIM4_RdFIFO_Pop,
  output wire [3:0]                             PIM4_RdFIFO_RdWdAddr,
  output wire                                   PIM4_WrFIFO_Empty,
  output wire                                   PIM4_WrFIFO_AlmostFull,
  input  wire                                   PIM4_WrFIFO_Flush,
  output wire                                   PIM4_RdFIFO_Empty,
  input  wire                                   PIM4_RdFIFO_Flush,
  output wire [1:0]                             PIM4_RdFIFO_Latency,
  output wire                                   PIM4_InitDone,

  input  wire                                   PPC440MC4_MIMCReadNotWrite,
  input  wire [0:35]                            PPC440MC4_MIMCAddress,
  input  wire                                   PPC440MC4_MIMCAddressValid,
  input  wire [0:127]                           PPC440MC4_MIMCWriteData,
  input  wire                                   PPC440MC4_MIMCWriteDataValid,
  input  wire [0:15]                            PPC440MC4_MIMCByteEnable,
  input  wire                                   PPC440MC4_MIMCBankConflict,
  input  wire                                   PPC440MC4_MIMCRowConflict,
  output wire [0:127]                           PPC440MC4_MCMIReadData,
  output wire                                   PPC440MC4_MCMIReadDataValid,
  output wire                                   PPC440MC4_MCMIReadDataErr,
  output wire                                   PPC440MC4_MCMIAddrReadyToAccept,

  input  wire                                   VFBC4_Cmd_Clk,
  input  wire                                   VFBC4_Cmd_Reset,
  input  wire [31:0]                            VFBC4_Cmd_Data,
  input  wire                                   VFBC4_Cmd_Write,
  input  wire                                   VFBC4_Cmd_End,
  output wire                                   VFBC4_Cmd_Full,
  output wire                                   VFBC4_Cmd_Almost_Full,
  output wire                                   VFBC4_Cmd_Idle,
  input  wire                                   VFBC4_Wd_Clk,
  input  wire                                   VFBC4_Wd_Reset,
  input  wire                                   VFBC4_Wd_Write,
  input  wire                                   VFBC4_Wd_End_Burst,
  input  wire                                   VFBC4_Wd_Flush,
  input  wire [C_VFBC4_RDWD_DATA_WIDTH-1:0]     VFBC4_Wd_Data,
  input  wire [C_VFBC4_RDWD_DATA_WIDTH/8-1:0]   VFBC4_Wd_Data_BE,
  output wire                                   VFBC4_Wd_Full,
  output wire                                   VFBC4_Wd_Almost_Full,
  input  wire                                   VFBC4_Rd_Clk,
  input  wire                                   VFBC4_Rd_Reset,
  input  wire                                   VFBC4_Rd_Read,
  input  wire                                   VFBC4_Rd_End_Burst,
  input  wire                                   VFBC4_Rd_Flush,
  output wire [C_VFBC4_RDWD_DATA_WIDTH-1:0]     VFBC4_Rd_Data,
  output wire                                   VFBC4_Rd_Empty,
  output wire                                   VFBC4_Rd_Almost_Empty,

  input  wire                                   MCB4_cmd_clk,
  input  wire                                   MCB4_cmd_en,
  input  wire [2:0]                             MCB4_cmd_instr,
  input  wire [5:0]                             MCB4_cmd_bl,
  input  wire [29:0]                            MCB4_cmd_byte_addr,
  output wire                                   MCB4_cmd_empty,
  output wire                                   MCB4_cmd_full,
  input  wire                                   MCB4_wr_clk,
  input  wire                                   MCB4_wr_en,
  input  wire [C_PIM4_DATA_WIDTH/8-1:0]         MCB4_wr_mask,
  input  wire [C_PIM4_DATA_WIDTH-1:0]           MCB4_wr_data,
  output wire                                   MCB4_wr_full,
  output wire                                   MCB4_wr_empty,
  output wire [6:0]                             MCB4_wr_count,
  output wire                                   MCB4_wr_underrun,
  output wire                                   MCB4_wr_error,
  input  wire                                   MCB4_rd_clk,
  input  wire                                   MCB4_rd_en,
  output wire [C_PIM4_DATA_WIDTH-1:0]           MCB4_rd_data,
  output wire                                   MCB4_rd_full,
  output wire                                   MCB4_rd_empty,
  output wire [6:0]                             MCB4_rd_count,
  output wire                                   MCB4_rd_overflow,
  output wire                                   MCB4_rd_error,

  // Port 5
  input  wire                                   FSL5_M_Clk,
  input  wire                                   FSL5_M_Write,
  input  wire [0:31]                            FSL5_M_Data,
  input  wire                                   FSL5_M_Control,
  output wire                                   FSL5_M_Full,
  input  wire                                   FSL5_S_Clk,
  input  wire                                   FSL5_S_Read,
  output wire [0:31]                            FSL5_S_Data,
  output wire                                   FSL5_S_Control,
  output wire                                   FSL5_S_Exists,
  input  wire                                   FSL5_B_M_Clk,
  input  wire                                   FSL5_B_M_Write,
  input  wire [0:31]                            FSL5_B_M_Data,
  input  wire                                   FSL5_B_M_Control,
  output wire                                   FSL5_B_M_Full,
  input  wire                                   FSL5_B_S_Clk,
  input  wire                                   FSL5_B_S_Read,
  output wire [0:31]                            FSL5_B_S_Data,
  output wire                                   FSL5_B_S_Control,
  output wire                                   FSL5_B_S_Exists,

  input  wire                                   SPLB5_Rst,
  input  wire                                   SPLB5_Clk,
  input  wire [0:31]                            SPLB5_PLB_ABus,
  input  wire                                   SPLB5_PLB_PAValid,
  input  wire                                   SPLB5_PLB_SAValid,
  input  wire [0:(C_SPLB5_MID_WIDTH-1)]         SPLB5_PLB_masterID,
  input  wire                                   SPLB5_PLB_RNW,
  input  wire [0:(C_SPLB5_DWIDTH/8-1)]          SPLB5_PLB_BE,
  input  wire [0:31]                            SPLB5_PLB_UABus,
  input  wire                                   SPLB5_PLB_rdPrim,
  input  wire                                   SPLB5_PLB_wrPrim,
  input  wire                                   SPLB5_PLB_abort,
  input  wire                                   SPLB5_PLB_busLock,
  input  wire [0:1]                             SPLB5_PLB_MSize,
  input  wire [0:3]                             SPLB5_PLB_size,
  input  wire [0:2]                             SPLB5_PLB_type,
  input  wire                                   SPLB5_PLB_lockErr,
  input  wire                                   SPLB5_PLB_wrPendReq,
  input  wire [0:1]                             SPLB5_PLB_wrPendPri,
  input  wire                                   SPLB5_PLB_rdPendReq,
  input  wire [0:1]                             SPLB5_PLB_rdPendPri,
  input  wire [0:1]                             SPLB5_PLB_reqPri,
  input  wire [0:15]                            SPLB5_PLB_TAttribute,
  input  wire                                   SPLB5_PLB_rdBurst,
  input  wire                                   SPLB5_PLB_wrBurst,
  input  wire [0:(C_SPLB5_DWIDTH-1)]            SPLB5_PLB_wrDBus,
  output wire                                   SPLB5_Sl_addrAck,
  output wire [0:1]                             SPLB5_Sl_SSize,
  output wire                                   SPLB5_Sl_wait,
  output wire                                   SPLB5_Sl_rearbitrate,
  output wire                                   SPLB5_Sl_wrDAck,
  output wire                                   SPLB5_Sl_wrComp,
  output wire                                   SPLB5_Sl_wrBTerm,
  output wire [0:(C_SPLB5_DWIDTH-1)]            SPLB5_Sl_rdDBus,
  output wire [0:3]                             SPLB5_Sl_rdWdAddr,
  output wire                                   SPLB5_Sl_rdDAck,
  output wire                                   SPLB5_Sl_rdComp,
  output wire                                   SPLB5_Sl_rdBTerm,
  output wire [0:(C_SPLB5_NUM_MASTERS-1)]       SPLB5_Sl_MBusy,
  output wire [0:(C_SPLB5_NUM_MASTERS-1)]       SPLB5_Sl_MRdErr,
  output wire [0:(C_SPLB5_NUM_MASTERS-1)]       SPLB5_Sl_MWrErr,
  output wire [0:(C_SPLB5_NUM_MASTERS-1)]       SPLB5_Sl_MIRQ,

  input  wire                                   SDMA5_Clk,
  output wire                                   SDMA5_Rx_IntOut,
  output wire                                   SDMA5_Tx_IntOut,
  output wire                                   SDMA5_RstOut,
  output wire [0:31]                            SDMA5_TX_D,
  output wire [0:3]                             SDMA5_TX_Rem,
  output wire                                   SDMA5_TX_SOF,
  output wire                                   SDMA5_TX_EOF,
  output wire                                   SDMA5_TX_SOP,
  output wire                                   SDMA5_TX_EOP,
  output wire                                   SDMA5_TX_Src_Rdy,
  input  wire                                   SDMA5_TX_Dst_Rdy,
  input  wire [0:31]                            SDMA5_RX_D,
  input  wire [0:3]                             SDMA5_RX_Rem,
  input  wire                                   SDMA5_RX_SOF,
  input  wire                                   SDMA5_RX_EOF,
  input  wire                                   SDMA5_RX_SOP,
  input  wire                                   SDMA5_RX_EOP,
  input  wire                                   SDMA5_RX_Src_Rdy,
  output wire                                   SDMA5_RX_Dst_Rdy,
  input  wire                                   SDMA_CTRL5_Rst,
  input  wire                                   SDMA_CTRL5_Clk,
  input  wire [0:31]                            SDMA_CTRL5_PLB_ABus,
  input  wire                                   SDMA_CTRL5_PLB_PAValid,
  input  wire                                   SDMA_CTRL5_PLB_SAValid,
  input  wire [0:(C_SDMA_CTRL5_MID_WIDTH-1)]    SDMA_CTRL5_PLB_masterID,
  input  wire                                   SDMA_CTRL5_PLB_RNW,
  input  wire [0:(C_SDMA_CTRL5_DWIDTH/8-1)]     SDMA_CTRL5_PLB_BE,
  input  wire [0:31]                            SDMA_CTRL5_PLB_UABus,
  input  wire                                   SDMA_CTRL5_PLB_rdPrim,
  input  wire                                   SDMA_CTRL5_PLB_wrPrim,
  input  wire                                   SDMA_CTRL5_PLB_abort,
  input  wire                                   SDMA_CTRL5_PLB_busLock,
  input  wire [0:1]                             SDMA_CTRL5_PLB_MSize,
  input  wire [0:3]                             SDMA_CTRL5_PLB_size,
  input  wire [0:2]                             SDMA_CTRL5_PLB_type,
  input  wire                                   SDMA_CTRL5_PLB_lockErr,
  input  wire                                   SDMA_CTRL5_PLB_wrPendReq,
  input  wire [0:1]                             SDMA_CTRL5_PLB_wrPendPri,
  input  wire                                   SDMA_CTRL5_PLB_rdPendReq,
  input  wire [0:1]                             SDMA_CTRL5_PLB_rdPendPri,
  input  wire [0:1]                             SDMA_CTRL5_PLB_reqPri,
  input  wire [0:15]                            SDMA_CTRL5_PLB_TAttribute,
  input  wire                                   SDMA_CTRL5_PLB_rdBurst,
  input  wire                                   SDMA_CTRL5_PLB_wrBurst,
  input  wire [0:(C_SDMA_CTRL5_DWIDTH-1)]       SDMA_CTRL5_PLB_wrDBus,
  output wire                                   SDMA_CTRL5_Sl_addrAck,
  output wire [0:1]                             SDMA_CTRL5_Sl_SSize,
  output wire                                   SDMA_CTRL5_Sl_wait,
  output wire                                   SDMA_CTRL5_Sl_rearbitrate,
  output wire                                   SDMA_CTRL5_Sl_wrDAck,
  output wire                                   SDMA_CTRL5_Sl_wrComp,
  output wire                                   SDMA_CTRL5_Sl_wrBTerm,
  output wire [0:(C_SDMA_CTRL5_DWIDTH-1)]       SDMA_CTRL5_Sl_rdDBus,
  output wire [0:3]                             SDMA_CTRL5_Sl_rdWdAddr,
  output wire                                   SDMA_CTRL5_Sl_rdDAck,
  output wire                                   SDMA_CTRL5_Sl_rdComp,
  output wire                                   SDMA_CTRL5_Sl_rdBTerm,
  output wire [0:(C_SDMA_CTRL5_NUM_MASTERS-1)]  SDMA_CTRL5_Sl_MBusy,
  output wire [0:(C_SDMA_CTRL5_NUM_MASTERS-1)]  SDMA_CTRL5_Sl_MRdErr,
  output wire [0:(C_SDMA_CTRL5_NUM_MASTERS-1)]  SDMA_CTRL5_Sl_MWrErr,
  output wire [0:(C_SDMA_CTRL5_NUM_MASTERS-1)]  SDMA_CTRL5_Sl_MIRQ,

  input  wire [31:0]                            PIM5_Addr,
  input  wire                                   PIM5_AddrReq,
  output wire                                   PIM5_AddrAck,
  input  wire                                   PIM5_RNW,
  input  wire [3:0]                             PIM5_Size,
  input  wire                                   PIM5_RdModWr,
  input  wire [C_PIM5_DATA_WIDTH-1:0]           PIM5_WrFIFO_Data,
  input  wire [(C_PIM5_DATA_WIDTH/8)-1:0]       PIM5_WrFIFO_BE,
  input  wire                                   PIM5_WrFIFO_Push,
  output wire [C_PIM5_DATA_WIDTH-1:0]           PIM5_RdFIFO_Data,
  input  wire                                   PIM5_RdFIFO_Pop,
  output wire [3:0]                             PIM5_RdFIFO_RdWdAddr,
  output wire                                   PIM5_WrFIFO_Empty,
  output wire                                   PIM5_WrFIFO_AlmostFull,
  input  wire                                   PIM5_WrFIFO_Flush,
  output wire                                   PIM5_RdFIFO_Empty,
  input  wire                                   PIM5_RdFIFO_Flush,
  output wire [1:0]                             PIM5_RdFIFO_Latency,
  output wire                                   PIM5_InitDone,

  input  wire                                   PPC440MC5_MIMCReadNotWrite,
  input  wire [0:35]                            PPC440MC5_MIMCAddress,
  input  wire                                   PPC440MC5_MIMCAddressValid,
  input  wire [0:127]                           PPC440MC5_MIMCWriteData,
  input  wire                                   PPC440MC5_MIMCWriteDataValid,
  input  wire [0:15]                            PPC440MC5_MIMCByteEnable,
  input  wire                                   PPC440MC5_MIMCBankConflict,
  input  wire                                   PPC440MC5_MIMCRowConflict,
  output wire [0:127]                           PPC440MC5_MCMIReadData,
  output wire                                   PPC440MC5_MCMIReadDataValid,
  output wire                                   PPC440MC5_MCMIReadDataErr,
  output wire                                   PPC440MC5_MCMIAddrReadyToAccept,

  input  wire                                   VFBC5_Cmd_Clk,
  input  wire                                   VFBC5_Cmd_Reset,
  input  wire [31:0]                            VFBC5_Cmd_Data,
  input  wire                                   VFBC5_Cmd_Write,
  input  wire                                   VFBC5_Cmd_End,
  output wire                                   VFBC5_Cmd_Full,
  output wire                                   VFBC5_Cmd_Almost_Full,
  output wire                                   VFBC5_Cmd_Idle,
  input  wire                                   VFBC5_Wd_Clk,
  input  wire                                   VFBC5_Wd_Reset,
  input  wire                                   VFBC5_Wd_Write,
  input  wire                                   VFBC5_Wd_End_Burst,
  input  wire                                   VFBC5_Wd_Flush,
  input  wire [C_VFBC5_RDWD_DATA_WIDTH-1:0]     VFBC5_Wd_Data,
  input  wire [C_VFBC5_RDWD_DATA_WIDTH/8-1:0]   VFBC5_Wd_Data_BE,
  output wire                                   VFBC5_Wd_Full,
  output wire                                   VFBC5_Wd_Almost_Full,
  input  wire                                   VFBC5_Rd_Clk,
  input  wire                                   VFBC5_Rd_Reset,
  input  wire                                   VFBC5_Rd_Read,
  input  wire                                   VFBC5_Rd_End_Burst,
  input  wire                                   VFBC5_Rd_Flush,
  output wire [C_VFBC5_RDWD_DATA_WIDTH-1:0]     VFBC5_Rd_Data,
  output wire                                   VFBC5_Rd_Empty,
  output wire                                   VFBC5_Rd_Almost_Empty,

  input  wire                                   MCB5_cmd_clk,
  input  wire                                   MCB5_cmd_en,
  input  wire [2:0]                             MCB5_cmd_instr,
  input  wire [5:0]                             MCB5_cmd_bl,
  input  wire [29:0]                            MCB5_cmd_byte_addr,
  output wire                                   MCB5_cmd_empty,
  output wire                                   MCB5_cmd_full,
  input  wire                                   MCB5_wr_clk,
  input  wire                                   MCB5_wr_en,
  input  wire [C_PIM5_DATA_WIDTH/8-1:0]         MCB5_wr_mask,
  input  wire [C_PIM5_DATA_WIDTH-1:0]           MCB5_wr_data,
  output wire                                   MCB5_wr_full,
  output wire                                   MCB5_wr_empty,
  output wire [6:0]                             MCB5_wr_count,
  output wire                                   MCB5_wr_underrun,
  output wire                                   MCB5_wr_error,
  input  wire                                   MCB5_rd_clk,
  input  wire                                   MCB5_rd_en,
  output wire [C_PIM5_DATA_WIDTH-1:0]           MCB5_rd_data,
  output wire                                   MCB5_rd_full,
  output wire                                   MCB5_rd_empty,
  output wire [6:0]                             MCB5_rd_count,
  output wire                                   MCB5_rd_overflow,
  output wire                                   MCB5_rd_error,

  // Port 6
  input  wire                                   FSL6_M_Clk,
  input  wire                                   FSL6_M_Write,
  input  wire [0:31]                            FSL6_M_Data,
  input  wire                                   FSL6_M_Control,
  output wire                                   FSL6_M_Full,
  input  wire                                   FSL6_S_Clk,
  input  wire                                   FSL6_S_Read,
  output wire [0:31]                            FSL6_S_Data,
  output wire                                   FSL6_S_Control,
  output wire                                   FSL6_S_Exists,
  input  wire                                   FSL6_B_M_Clk,
  input  wire                                   FSL6_B_M_Write,
  input  wire [0:31]                            FSL6_B_M_Data,
  input  wire                                   FSL6_B_M_Control,
  output wire                                   FSL6_B_M_Full,
  input  wire                                   FSL6_B_S_Clk,
  input  wire                                   FSL6_B_S_Read,
  output wire [0:31]                            FSL6_B_S_Data,
  output wire                                   FSL6_B_S_Control,
  output wire                                   FSL6_B_S_Exists,

  input  wire                                   SPLB6_Rst,
  input  wire                                   SPLB6_Clk,
  input  wire [0:31]                            SPLB6_PLB_ABus,
  input  wire                                   SPLB6_PLB_PAValid,
  input  wire                                   SPLB6_PLB_SAValid,
  input  wire [0:(C_SPLB6_MID_WIDTH-1)]         SPLB6_PLB_masterID,
  input  wire                                   SPLB6_PLB_RNW,
  input  wire [0:(C_SPLB6_DWIDTH/8-1)]          SPLB6_PLB_BE,
  input  wire [0:31]                            SPLB6_PLB_UABus,
  input  wire                                   SPLB6_PLB_rdPrim,
  input  wire                                   SPLB6_PLB_wrPrim,
  input  wire                                   SPLB6_PLB_abort,
  input  wire                                   SPLB6_PLB_busLock,
  input  wire [0:1]                             SPLB6_PLB_MSize,
  input  wire [0:3]                             SPLB6_PLB_size,
  input  wire [0:2]                             SPLB6_PLB_type,
  input  wire                                   SPLB6_PLB_lockErr,
  input  wire                                   SPLB6_PLB_wrPendReq,
  input  wire [0:1]                             SPLB6_PLB_wrPendPri,
  input  wire                                   SPLB6_PLB_rdPendReq,
  input  wire [0:1]                             SPLB6_PLB_rdPendPri,
  input  wire [0:1]                             SPLB6_PLB_reqPri,
  input  wire [0:15]                            SPLB6_PLB_TAttribute,
  input  wire                                   SPLB6_PLB_rdBurst,
  input  wire                                   SPLB6_PLB_wrBurst,
  input  wire [0:(C_SPLB6_DWIDTH-1)]            SPLB6_PLB_wrDBus,
  output wire                                   SPLB6_Sl_addrAck,
  output wire [0:1]                             SPLB6_Sl_SSize,
  output wire                                   SPLB6_Sl_wait,
  output wire                                   SPLB6_Sl_rearbitrate,
  output wire                                   SPLB6_Sl_wrDAck,
  output wire                                   SPLB6_Sl_wrComp,
  output wire                                   SPLB6_Sl_wrBTerm,
  output wire [0:(C_SPLB6_DWIDTH-1)]            SPLB6_Sl_rdDBus,
  output wire [0:3]                             SPLB6_Sl_rdWdAddr,
  output wire                                   SPLB6_Sl_rdDAck,
  output wire                                   SPLB6_Sl_rdComp,
  output wire                                   SPLB6_Sl_rdBTerm,
  output wire [0:(C_SPLB6_NUM_MASTERS-1)]       SPLB6_Sl_MBusy,
  output wire [0:(C_SPLB6_NUM_MASTERS-1)]       SPLB6_Sl_MRdErr,
  output wire [0:(C_SPLB6_NUM_MASTERS-1)]       SPLB6_Sl_MWrErr,
  output wire [0:(C_SPLB6_NUM_MASTERS-1)]       SPLB6_Sl_MIRQ,

  input  wire                                   SDMA6_Clk,
  output wire                                   SDMA6_Rx_IntOut,
  output wire                                   SDMA6_Tx_IntOut,
  output wire                                   SDMA6_RstOut,
  output wire [0:31]                            SDMA6_TX_D,
  output wire [0:3]                             SDMA6_TX_Rem,
  output wire                                   SDMA6_TX_SOF,
  output wire                                   SDMA6_TX_EOF,
  output wire                                   SDMA6_TX_SOP,
  output wire                                   SDMA6_TX_EOP,
  output wire                                   SDMA6_TX_Src_Rdy,
  input  wire                                   SDMA6_TX_Dst_Rdy,
  input  wire [0:31]                            SDMA6_RX_D,
  input  wire [0:3]                             SDMA6_RX_Rem,
  input  wire                                   SDMA6_RX_SOF,
  input  wire                                   SDMA6_RX_EOF,
  input  wire                                   SDMA6_RX_SOP,
  input  wire                                   SDMA6_RX_EOP,
  input  wire                                   SDMA6_RX_Src_Rdy,
  output wire                                   SDMA6_RX_Dst_Rdy,
  input  wire                                   SDMA_CTRL6_Rst,
  input  wire                                   SDMA_CTRL6_Clk,
  input  wire [0:31]                            SDMA_CTRL6_PLB_ABus,
  input  wire                                   SDMA_CTRL6_PLB_PAValid,
  input  wire                                   SDMA_CTRL6_PLB_SAValid,
  input  wire [0:(C_SDMA_CTRL6_MID_WIDTH-1)]    SDMA_CTRL6_PLB_masterID,
  input  wire                                   SDMA_CTRL6_PLB_RNW,
  input  wire [0:(C_SDMA_CTRL6_DWIDTH/8-1)]     SDMA_CTRL6_PLB_BE,
  input  wire [0:31]                            SDMA_CTRL6_PLB_UABus,
  input  wire                                   SDMA_CTRL6_PLB_rdPrim,
  input  wire                                   SDMA_CTRL6_PLB_wrPrim,
  input  wire                                   SDMA_CTRL6_PLB_abort,
  input  wire                                   SDMA_CTRL6_PLB_busLock,
  input  wire [0:1]                             SDMA_CTRL6_PLB_MSize,
  input  wire [0:3]                             SDMA_CTRL6_PLB_size,
  input  wire [0:2]                             SDMA_CTRL6_PLB_type,
  input  wire                                   SDMA_CTRL6_PLB_lockErr,
  input  wire                                   SDMA_CTRL6_PLB_wrPendReq,
  input  wire [0:1]                             SDMA_CTRL6_PLB_wrPendPri,
  input  wire                                   SDMA_CTRL6_PLB_rdPendReq,
  input  wire [0:1]                             SDMA_CTRL6_PLB_rdPendPri,
  input  wire [0:1]                             SDMA_CTRL6_PLB_reqPri,
  input  wire [0:15]                            SDMA_CTRL6_PLB_TAttribute,
  input  wire                                   SDMA_CTRL6_PLB_rdBurst,
  input  wire                                   SDMA_CTRL6_PLB_wrBurst,
  input  wire [0:(C_SDMA_CTRL6_DWIDTH-1)]       SDMA_CTRL6_PLB_wrDBus,
  output wire                                   SDMA_CTRL6_Sl_addrAck,
  output wire [0:1]                             SDMA_CTRL6_Sl_SSize,
  output wire                                   SDMA_CTRL6_Sl_wait,
  output wire                                   SDMA_CTRL6_Sl_rearbitrate,
  output wire                                   SDMA_CTRL6_Sl_wrDAck,
  output wire                                   SDMA_CTRL6_Sl_wrComp,
  output wire                                   SDMA_CTRL6_Sl_wrBTerm,
  output wire [0:(C_SDMA_CTRL6_DWIDTH-1)]       SDMA_CTRL6_Sl_rdDBus,
  output wire [0:3]                             SDMA_CTRL6_Sl_rdWdAddr,
  output wire                                   SDMA_CTRL6_Sl_rdDAck,
  output wire                                   SDMA_CTRL6_Sl_rdComp,
  output wire                                   SDMA_CTRL6_Sl_rdBTerm,
  output wire [0:(C_SDMA_CTRL6_NUM_MASTERS-1)]  SDMA_CTRL6_Sl_MBusy,
  output wire [0:(C_SDMA_CTRL6_NUM_MASTERS-1)]  SDMA_CTRL6_Sl_MRdErr,
  output wire [0:(C_SDMA_CTRL6_NUM_MASTERS-1)]  SDMA_CTRL6_Sl_MWrErr,
  output wire [0:(C_SDMA_CTRL6_NUM_MASTERS-1)]  SDMA_CTRL6_Sl_MIRQ,

  input  wire [31:0]                            PIM6_Addr,
  input  wire                                   PIM6_AddrReq,
  output wire                                   PIM6_AddrAck,
  input  wire                                   PIM6_RNW,
  input  wire [3:0]                             PIM6_Size,
  input  wire                                   PIM6_RdModWr,
  input  wire [C_PIM6_DATA_WIDTH-1:0]           PIM6_WrFIFO_Data,
  input  wire [(C_PIM6_DATA_WIDTH/8)-1:0]       PIM6_WrFIFO_BE,
  input  wire                                   PIM6_WrFIFO_Push,
  output wire [C_PIM6_DATA_WIDTH-1:0]           PIM6_RdFIFO_Data,
  input  wire                                   PIM6_RdFIFO_Pop,
  output wire [3:0]                             PIM6_RdFIFO_RdWdAddr,
  output wire                                   PIM6_WrFIFO_Empty,
  output wire                                   PIM6_WrFIFO_AlmostFull,
  input  wire                                   PIM6_WrFIFO_Flush,
  output wire                                   PIM6_RdFIFO_Empty,
  input  wire                                   PIM6_RdFIFO_Flush,
  output wire [1:0]                             PIM6_RdFIFO_Latency,
  output wire                                   PIM6_InitDone,

  input  wire                                   PPC440MC6_MIMCReadNotWrite,
  input  wire [0:35]                            PPC440MC6_MIMCAddress,
  input  wire                                   PPC440MC6_MIMCAddressValid,
  input  wire [0:127]                           PPC440MC6_MIMCWriteData,
  input  wire                                   PPC440MC6_MIMCWriteDataValid,
  input  wire [0:15]                            PPC440MC6_MIMCByteEnable,
  input  wire                                   PPC440MC6_MIMCBankConflict,
  input  wire                                   PPC440MC6_MIMCRowConflict,
  output wire [0:127]                           PPC440MC6_MCMIReadData,
  output wire                                   PPC440MC6_MCMIReadDataValid,
  output wire                                   PPC440MC6_MCMIReadDataErr,
  output wire                                   PPC440MC6_MCMIAddrReadyToAccept,

  input  wire                                   VFBC6_Cmd_Clk,
  input  wire                                   VFBC6_Cmd_Reset,
  input  wire [31:0]                            VFBC6_Cmd_Data,
  input  wire                                   VFBC6_Cmd_Write,
  input  wire                                   VFBC6_Cmd_End,
  output wire                                   VFBC6_Cmd_Full,
  output wire                                   VFBC6_Cmd_Almost_Full,
  output wire                                   VFBC6_Cmd_Idle,
  input  wire                                   VFBC6_Wd_Clk,
  input  wire                                   VFBC6_Wd_Reset,
  input  wire                                   VFBC6_Wd_Write,
  input  wire                                   VFBC6_Wd_End_Burst,
  input  wire                                   VFBC6_Wd_Flush,
  input  wire [C_VFBC6_RDWD_DATA_WIDTH-1:0]     VFBC6_Wd_Data,
  input  wire [C_VFBC6_RDWD_DATA_WIDTH/8-1:0]   VFBC6_Wd_Data_BE,
  output wire                                   VFBC6_Wd_Full,
  output wire                                   VFBC6_Wd_Almost_Full,
  input  wire                                   VFBC6_Rd_Clk,
  input  wire                                   VFBC6_Rd_Reset,
  input  wire                                   VFBC6_Rd_Read,
  input  wire                                   VFBC6_Rd_End_Burst,
  input  wire                                   VFBC6_Rd_Flush,
  output wire [C_VFBC6_RDWD_DATA_WIDTH-1:0]     VFBC6_Rd_Data,
  output wire                                   VFBC6_Rd_Empty,
  output wire                                   VFBC6_Rd_Almost_Empty,

  input  wire                                   MCB6_cmd_clk,
  input  wire                                   MCB6_cmd_en,
  input  wire [2:0]                             MCB6_cmd_instr,
  input  wire [5:0]                             MCB6_cmd_bl,
  input  wire [29:0]                            MCB6_cmd_byte_addr,
  output wire                                   MCB6_cmd_empty,
  output wire                                   MCB6_cmd_full,
  input  wire                                   MCB6_wr_clk,
  input  wire                                   MCB6_wr_en,
  input  wire [C_PIM6_DATA_WIDTH/8-1:0]         MCB6_wr_mask,
  input  wire [C_PIM6_DATA_WIDTH-1:0]           MCB6_wr_data,
  output wire                                   MCB6_wr_full,
  output wire                                   MCB6_wr_empty,
  output wire [6:0]                             MCB6_wr_count,
  output wire                                   MCB6_wr_underrun,
  output wire                                   MCB6_wr_error,
  input  wire                                   MCB6_rd_clk,
  input  wire                                   MCB6_rd_en,
  output wire [C_PIM6_DATA_WIDTH-1:0]           MCB6_rd_data,
  output wire                                   MCB6_rd_full,
  output wire                                   MCB6_rd_empty,
  output wire [6:0]                             MCB6_rd_count,
  output wire                                   MCB6_rd_overflow,
  output wire                                   MCB6_rd_error,

  // Port 7
  input  wire                                   FSL7_M_Clk,
  input  wire                                   FSL7_M_Write,
  input  wire [0:31]                            FSL7_M_Data,
  input  wire                                   FSL7_M_Control,
  output wire                                   FSL7_M_Full,
  input  wire                                   FSL7_S_Clk,
  input  wire                                   FSL7_S_Read,
  output wire [0:31]                            FSL7_S_Data,
  output wire                                   FSL7_S_Control,
  output wire                                   FSL7_S_Exists,
  input  wire                                   FSL7_B_M_Clk,
  input  wire                                   FSL7_B_M_Write,
  input  wire [0:31]                            FSL7_B_M_Data,
  input  wire                                   FSL7_B_M_Control,
  output wire                                   FSL7_B_M_Full,
  input  wire                                   FSL7_B_S_Clk,
  input  wire                                   FSL7_B_S_Read,
  output wire [0:31]                            FSL7_B_S_Data,
  output wire                                   FSL7_B_S_Control,
  output wire                                   FSL7_B_S_Exists,

  input  wire                                   SPLB7_Rst,
  input  wire                                   SPLB7_Clk,
  input  wire [0:31]                            SPLB7_PLB_ABus,
  input  wire                                   SPLB7_PLB_PAValid,
  input  wire                                   SPLB7_PLB_SAValid,
  input  wire [0:(C_SPLB7_MID_WIDTH-1)]         SPLB7_PLB_masterID,
  input  wire                                   SPLB7_PLB_RNW,
  input  wire [0:(C_SPLB7_DWIDTH/8-1)]          SPLB7_PLB_BE,
  input  wire [0:31]                            SPLB7_PLB_UABus,
  input  wire                                   SPLB7_PLB_rdPrim,
  input  wire                                   SPLB7_PLB_wrPrim,
  input  wire                                   SPLB7_PLB_abort,
  input  wire                                   SPLB7_PLB_busLock,
  input  wire [0:1]                             SPLB7_PLB_MSize,
  input  wire [0:3]                             SPLB7_PLB_size,
  input  wire [0:2]                             SPLB7_PLB_type,
  input  wire                                   SPLB7_PLB_lockErr,
  input  wire                                   SPLB7_PLB_wrPendReq,
  input  wire [0:1]                             SPLB7_PLB_wrPendPri,
  input  wire                                   SPLB7_PLB_rdPendReq,
  input  wire [0:1]                             SPLB7_PLB_rdPendPri,
  input  wire [0:1]                             SPLB7_PLB_reqPri,
  input  wire [0:15]                            SPLB7_PLB_TAttribute,
  input  wire                                   SPLB7_PLB_rdBurst,
  input  wire                                   SPLB7_PLB_wrBurst,
  input  wire [0:(C_SPLB7_DWIDTH-1)]            SPLB7_PLB_wrDBus,
  output wire                                   SPLB7_Sl_addrAck,
  output wire [0:1]                             SPLB7_Sl_SSize,
  output wire                                   SPLB7_Sl_wait,
  output wire                                   SPLB7_Sl_rearbitrate,
  output wire                                   SPLB7_Sl_wrDAck,
  output wire                                   SPLB7_Sl_wrComp,
  output wire                                   SPLB7_Sl_wrBTerm,
  output wire [0:(C_SPLB7_DWIDTH-1)]            SPLB7_Sl_rdDBus,
  output wire [0:3]                             SPLB7_Sl_rdWdAddr,
  output wire                                   SPLB7_Sl_rdDAck,
  output wire                                   SPLB7_Sl_rdComp,
  output wire                                   SPLB7_Sl_rdBTerm,
  output wire [0:(C_SPLB7_NUM_MASTERS-1)]       SPLB7_Sl_MBusy,
  output wire [0:(C_SPLB7_NUM_MASTERS-1)]       SPLB7_Sl_MRdErr,
  output wire [0:(C_SPLB7_NUM_MASTERS-1)]       SPLB7_Sl_MWrErr,
  output wire [0:(C_SPLB7_NUM_MASTERS-1)]       SPLB7_Sl_MIRQ,

  input  wire                                   SDMA7_Clk,
  output wire                                   SDMA7_Rx_IntOut,
  output wire                                   SDMA7_Tx_IntOut,
  output wire                                   SDMA7_RstOut,
  output wire [0:31]                            SDMA7_TX_D,
  output wire [0:3]                             SDMA7_TX_Rem,
  output wire                                   SDMA7_TX_SOF,
  output wire                                   SDMA7_TX_EOF,
  output wire                                   SDMA7_TX_SOP,
  output wire                                   SDMA7_TX_EOP,
  output wire                                   SDMA7_TX_Src_Rdy,
  input  wire                                   SDMA7_TX_Dst_Rdy,
  input  wire [0:31]                            SDMA7_RX_D,
  input  wire [0:3]                             SDMA7_RX_Rem,
  input  wire                                   SDMA7_RX_SOF,
  input  wire                                   SDMA7_RX_EOF,
  input  wire                                   SDMA7_RX_SOP,
  input  wire                                   SDMA7_RX_EOP,
  input  wire                                   SDMA7_RX_Src_Rdy,
  output wire                                   SDMA7_RX_Dst_Rdy,
  input  wire                                   SDMA_CTRL7_Rst,
  input  wire                                   SDMA_CTRL7_Clk,
  input  wire [0:31]                            SDMA_CTRL7_PLB_ABus,
  input  wire                                   SDMA_CTRL7_PLB_PAValid,
  input  wire                                   SDMA_CTRL7_PLB_SAValid,
  input  wire [0:(C_SDMA_CTRL7_MID_WIDTH-1)]    SDMA_CTRL7_PLB_masterID,
  input  wire                                   SDMA_CTRL7_PLB_RNW,
  input  wire [0:(C_SDMA_CTRL7_DWIDTH/8-1)]     SDMA_CTRL7_PLB_BE,
  input  wire [0:31]                            SDMA_CTRL7_PLB_UABus,
  input  wire                                   SDMA_CTRL7_PLB_rdPrim,
  input  wire                                   SDMA_CTRL7_PLB_wrPrim,
  input  wire                                   SDMA_CTRL7_PLB_abort,
  input  wire                                   SDMA_CTRL7_PLB_busLock,
  input  wire [0:1]                             SDMA_CTRL7_PLB_MSize,
  input  wire [0:3]                             SDMA_CTRL7_PLB_size,
  input  wire [0:2]                             SDMA_CTRL7_PLB_type,
  input  wire                                   SDMA_CTRL7_PLB_lockErr,
  input  wire                                   SDMA_CTRL7_PLB_wrPendReq,
  input  wire [0:1]                             SDMA_CTRL7_PLB_wrPendPri,
  input  wire                                   SDMA_CTRL7_PLB_rdPendReq,
  input  wire [0:1]                             SDMA_CTRL7_PLB_rdPendPri,
  input  wire [0:1]                             SDMA_CTRL7_PLB_reqPri,
  input  wire [0:15]                            SDMA_CTRL7_PLB_TAttribute,
  input  wire                                   SDMA_CTRL7_PLB_rdBurst,
  input  wire                                   SDMA_CTRL7_PLB_wrBurst,
  input  wire [0:(C_SDMA_CTRL7_DWIDTH-1)]       SDMA_CTRL7_PLB_wrDBus,
  output wire                                   SDMA_CTRL7_Sl_addrAck,
  output wire [0:1]                             SDMA_CTRL7_Sl_SSize,
  output wire                                   SDMA_CTRL7_Sl_wait,
  output wire                                   SDMA_CTRL7_Sl_rearbitrate,
  output wire                                   SDMA_CTRL7_Sl_wrDAck,
  output wire                                   SDMA_CTRL7_Sl_wrComp,
  output wire                                   SDMA_CTRL7_Sl_wrBTerm,
  output wire [0:(C_SDMA_CTRL7_DWIDTH-1)]       SDMA_CTRL7_Sl_rdDBus,
  output wire [0:3]                             SDMA_CTRL7_Sl_rdWdAddr,
  output wire                                   SDMA_CTRL7_Sl_rdDAck,
  output wire                                   SDMA_CTRL7_Sl_rdComp,
  output wire                                   SDMA_CTRL7_Sl_rdBTerm,
  output wire [0:(C_SDMA_CTRL7_NUM_MASTERS-1)]  SDMA_CTRL7_Sl_MBusy,
  output wire [0:(C_SDMA_CTRL7_NUM_MASTERS-1)]  SDMA_CTRL7_Sl_MRdErr,
  output wire [0:(C_SDMA_CTRL7_NUM_MASTERS-1)]  SDMA_CTRL7_Sl_MWrErr,
  output wire [0:(C_SDMA_CTRL7_NUM_MASTERS-1)]  SDMA_CTRL7_Sl_MIRQ,

  input  wire [31:0]                            PIM7_Addr,
  input  wire                                   PIM7_AddrReq,
  output wire                                   PIM7_AddrAck,
  input  wire                                   PIM7_RNW,
  input  wire [3:0]                             PIM7_Size,
  input  wire                                   PIM7_RdModWr,
  input  wire [C_PIM7_DATA_WIDTH-1:0]           PIM7_WrFIFO_Data,
  input  wire [(C_PIM7_DATA_WIDTH/8)-1:0]       PIM7_WrFIFO_BE,
  input  wire                                   PIM7_WrFIFO_Push,
  output wire [C_PIM7_DATA_WIDTH-1:0]           PIM7_RdFIFO_Data,
  input  wire                                   PIM7_RdFIFO_Pop,
  output wire [3:0]                             PIM7_RdFIFO_RdWdAddr,
  output wire                                   PIM7_WrFIFO_Empty,
  output wire                                   PIM7_WrFIFO_AlmostFull,
  input  wire                                   PIM7_WrFIFO_Flush,
  output wire                                   PIM7_RdFIFO_Empty,
  input  wire                                   PIM7_RdFIFO_Flush,
  output wire [1:0]                             PIM7_RdFIFO_Latency,
  output wire                                   PIM7_InitDone,

  input  wire                                   PPC440MC7_MIMCReadNotWrite,
  input  wire [0:35]                            PPC440MC7_MIMCAddress,
  input  wire                                   PPC440MC7_MIMCAddressValid,
  input  wire [0:127]                           PPC440MC7_MIMCWriteData,
  input  wire                                   PPC440MC7_MIMCWriteDataValid,
  input  wire [0:15]                            PPC440MC7_MIMCByteEnable,
  input  wire                                   PPC440MC7_MIMCBankConflict,
  input  wire                                   PPC440MC7_MIMCRowConflict,
  output wire [0:127]                           PPC440MC7_MCMIReadData,
  output wire                                   PPC440MC7_MCMIReadDataValid,
  output wire                                   PPC440MC7_MCMIReadDataErr,
  output wire                                   PPC440MC7_MCMIAddrReadyToAccept,

  input  wire                                   VFBC7_Cmd_Clk,
  input  wire                                   VFBC7_Cmd_Reset,
  input  wire [31:0]                            VFBC7_Cmd_Data,
  input  wire                                   VFBC7_Cmd_Write,
  input  wire                                   VFBC7_Cmd_End,
  output wire                                   VFBC7_Cmd_Full,
  output wire                                   VFBC7_Cmd_Almost_Full,
  output wire                                   VFBC7_Cmd_Idle,
  input  wire                                   VFBC7_Wd_Clk,
  input  wire                                   VFBC7_Wd_Reset,
  input  wire                                   VFBC7_Wd_Write,
  input  wire                                   VFBC7_Wd_End_Burst,
  input  wire                                   VFBC7_Wd_Flush,
  input  wire [C_VFBC7_RDWD_DATA_WIDTH-1:0]     VFBC7_Wd_Data,
  input  wire [C_VFBC7_RDWD_DATA_WIDTH/8-1:0]   VFBC7_Wd_Data_BE,
  output wire                                   VFBC7_Wd_Full,
  output wire                                   VFBC7_Wd_Almost_Full,
  input  wire                                   VFBC7_Rd_Clk,
  input  wire                                   VFBC7_Rd_Reset,
  input  wire                                   VFBC7_Rd_Read,
  input  wire                                   VFBC7_Rd_End_Burst,
  input  wire                                   VFBC7_Rd_Flush,
  output wire [C_VFBC7_RDWD_DATA_WIDTH-1:0]     VFBC7_Rd_Data,
  output wire                                   VFBC7_Rd_Empty,
  output wire                                   VFBC7_Rd_Almost_Empty,

  input  wire                                   MCB7_cmd_clk,
  input  wire                                   MCB7_cmd_en,
  input  wire [2:0]                             MCB7_cmd_instr,
  input  wire [5:0]                             MCB7_cmd_bl,
  input  wire [29:0]                            MCB7_cmd_byte_addr,
  output wire                                   MCB7_cmd_empty,
  output wire                                   MCB7_cmd_full,
  input  wire                                   MCB7_wr_clk,
  input  wire                                   MCB7_wr_en,
  input  wire [C_PIM7_DATA_WIDTH/8-1:0]         MCB7_wr_mask,
  input  wire [C_PIM7_DATA_WIDTH-1:0]           MCB7_wr_data,
  output wire                                   MCB7_wr_full,
  output wire                                   MCB7_wr_empty,
  output wire [6:0]                             MCB7_wr_count,
  output wire                                   MCB7_wr_underrun,
  output wire                                   MCB7_wr_error,
  input  wire                                   MCB7_rd_clk,
  input  wire                                   MCB7_rd_en,
  output wire [C_PIM7_DATA_WIDTH-1:0]           MCB7_rd_data,
  output wire                                   MCB7_rd_full,
  output wire                                   MCB7_rd_empty,
  output wire [6:0]                             MCB7_rd_count,
  output wire                                   MCB7_rd_overflow,
  output wire                                   MCB7_rd_error,

  ///////////////////////
  // MPMC Core Signals //
  ///////////////////////
  input  wire                                   MPMC_CTRL_Clk,
  input  wire                                   MPMC_CTRL_Rst,
  input  wire [0:31]                            MPMC_CTRL_PLB_ABus,
  input  wire                                   MPMC_CTRL_PLB_PAValid,
  input  wire                                   MPMC_CTRL_PLB_SAValid,
  input  wire [0:(C_MPMC_CTRL_MID_WIDTH-1)]     MPMC_CTRL_PLB_masterID,
  input  wire                                   MPMC_CTRL_PLB_RNW,
  input  wire [0:(C_MPMC_CTRL_DWIDTH/8-1)]      MPMC_CTRL_PLB_BE,
  input  wire [0:31]                            MPMC_CTRL_PLB_UABus,
  input  wire                                   MPMC_CTRL_PLB_rdPrim,
  input  wire                                   MPMC_CTRL_PLB_wrPrim,
  input  wire                                   MPMC_CTRL_PLB_abort,
  input  wire                                   MPMC_CTRL_PLB_busLock,
  input  wire [0:1]                             MPMC_CTRL_PLB_MSize,
  input  wire [0:3]                             MPMC_CTRL_PLB_size,
  input  wire [0:2]                             MPMC_CTRL_PLB_type,
  input  wire                                   MPMC_CTRL_PLB_lockErr,
  input  wire                                   MPMC_CTRL_PLB_wrPendReq,
  input  wire [0:1]                             MPMC_CTRL_PLB_wrPendPri,
  input  wire                                   MPMC_CTRL_PLB_rdPendReq,
  input  wire [0:1]                             MPMC_CTRL_PLB_rdPendPri,
  input  wire [0:1]                             MPMC_CTRL_PLB_reqPri,
  input  wire [0:15]                            MPMC_CTRL_PLB_TAttribute,
  input  wire                                   MPMC_CTRL_PLB_rdBurst,
  input  wire                                   MPMC_CTRL_PLB_wrBurst,
  input  wire [0:(C_MPMC_CTRL_DWIDTH-1)]        MPMC_CTRL_PLB_wrDBus,
  output wire                                   MPMC_CTRL_Sl_addrAck,
  output wire [0:1]                             MPMC_CTRL_Sl_SSize,
  output wire                                   MPMC_CTRL_Sl_wait,
  output wire                                   MPMC_CTRL_Sl_rearbitrate,
  output wire                                   MPMC_CTRL_Sl_wrDAck,
  output wire                                   MPMC_CTRL_Sl_wrComp,
  output wire                                   MPMC_CTRL_Sl_wrBTerm,
  output wire [0:(C_MPMC_CTRL_DWIDTH-1)]        MPMC_CTRL_Sl_rdDBus,
  output wire [0:3]                             MPMC_CTRL_Sl_rdWdAddr,
  output wire                                   MPMC_CTRL_Sl_rdDAck,
  output wire                                   MPMC_CTRL_Sl_rdComp,
  output wire                                   MPMC_CTRL_Sl_rdBTerm,
  output wire [0:(C_MPMC_CTRL_NUM_MASTERS-1)]   MPMC_CTRL_Sl_MBusy,
  output wire [0:(C_MPMC_CTRL_NUM_MASTERS-1)]   MPMC_CTRL_Sl_MRdErr,
  output wire [0:(C_MPMC_CTRL_NUM_MASTERS-1)]   MPMC_CTRL_Sl_MWrErr,
  output wire [0:(C_MPMC_CTRL_NUM_MASTERS-1)]   MPMC_CTRL_Sl_MIRQ,

  input  wire                                   MPMC_Clk0,
  input  wire                                   MPMC_Clk0_DIV2,
  input  wire                                   MPMC_Clk90,
  input  wire                                   MPMC_Clk_200MHz,
  input  wire                                   MPMC_Clk_Mem,
  input  wire                                   MPMC_Clk_Mem_2x,
  input  wire                                   MPMC_Clk_Mem_2x_180,
  input  wire                                   MPMC_Clk_Mem_2x_CE0,
  input  wire                                   MPMC_Clk_Mem_2x_CE90,
  output wire                                   MPMC_Clk_Mem_2x_bufpll_o,
  output wire                                   MPMC_Clk_Mem_2x_180_bufpll_o,
  output wire                                   MPMC_Clk_Mem_2x_CE0_bufpll_o,
  output wire                                   MPMC_Clk_Mem_2x_CE90_bufpll_o,
  output wire                                   MPMC_PLL_Lock_bufpll_o,
  input  wire                                   MPMC_Clk_Rd_Base,
  input  wire                                   MPMC_PLL_Lock,
  input  wire                                   MPMC_Rst,
  input  wire                                   MPMC_Idelayctrl_Rdy_I,
  output wire                                   MPMC_Idelayctrl_Rdy_O,
  output wire                                   MPMC_InitDone,
  output wire                                   MPMC_ECC_Intr,
  output wire                                   MPMC_DCM_PSEN,
  output wire                                   MPMC_DCM_PSINCDEC,
  input  wire                                   MPMC_DCM_PSDONE,
  input  wire                                   MPMC_MCB_DRP_Clk,


  // Memory Interface Signals
  // SDRAM
  output wire [C_MEM_CLK_WIDTH-1:0]             SDRAM_Clk,
  output wire [C_MEM_CE_WIDTH-1:0]              SDRAM_CE,
  output wire [C_MEM_CS_N_WIDTH-1:0]            SDRAM_CS_n,
  output wire                                   SDRAM_RAS_n,
  output wire                                   SDRAM_CAS_n,
  output wire                                   SDRAM_WE_n,
  output wire [C_MEM_BANKADDR_WIDTH-1:0]        SDRAM_BankAddr,
  output wire [C_MEM_ADDR_WIDTH-1:0]            SDRAM_Addr,
  inout  wire [C_MEM_DATA_WIDTH+C_ECC_DATA_WIDTH-1:0]   SDRAM_DQ,
  output wire [C_MEM_DM_WIDTH+C_ECC_DM_WIDTH-1:0]       SDRAM_DM,
  // DDR
  output wire [C_MEM_CLK_WIDTH-1:0]             DDR_Clk,
  output wire [C_MEM_CLK_WIDTH-1:0]             DDR_Clk_n,
  output wire [C_MEM_CE_WIDTH-1:0]              DDR_CE,
  output wire [C_MEM_CS_N_WIDTH-1:0]            DDR_CS_n,
  output wire                                   DDR_RAS_n,
  output wire                                   DDR_CAS_n,
  output wire                                   DDR_WE_n,
  output wire [C_MEM_BANKADDR_WIDTH-1:0]        DDR_BankAddr,
  output wire [C_MEM_ADDR_WIDTH-1:0]            DDR_Addr,
  inout  wire [C_MEM_DATA_WIDTH+C_ECC_DATA_WIDTH-1:0]   DDR_DQ,
  output wire [C_MEM_DM_WIDTH+C_ECC_DM_WIDTH-1:0]       DDR_DM,
  inout  wire [C_MEM_DQS_WIDTH+C_ECC_DQS_WIDTH-1:0]     DDR_DQS,
  output wire                                   DDR_DQS_Div_O,
  input  wire                                   DDR_DQS_Div_I,
  // DDR2
  output wire [C_MEM_CLK_WIDTH-1:0]             DDR2_Clk,
  output wire [C_MEM_CLK_WIDTH-1:0]             DDR2_Clk_n,
  output wire [C_MEM_CE_WIDTH-1:0]              DDR2_CE,
  output wire [C_MEM_CS_N_WIDTH-1:0]            DDR2_CS_n,
  output wire [C_MEM_ODT_WIDTH-1:0]             DDR2_ODT,
  output wire                                   DDR2_RAS_n,
  output wire                                   DDR2_CAS_n,
  output wire                                   DDR2_WE_n,
  output wire [C_MEM_BANKADDR_WIDTH-1:0]        DDR2_BankAddr,
  output wire [C_MEM_ADDR_WIDTH-1:0]            DDR2_Addr,
  inout  wire [C_MEM_DATA_WIDTH+C_ECC_DATA_WIDTH-1:0]   DDR2_DQ,
  output wire [C_MEM_DM_WIDTH+C_ECC_DM_WIDTH-1:0]       DDR2_DM,
  inout  wire [C_MEM_DQS_WIDTH+C_ECC_DQS_WIDTH-1:0]     DDR2_DQS,
  inout  wire [C_MEM_DQS_WIDTH+C_ECC_DQS_WIDTH-1:0]     DDR2_DQS_n,
  output wire                                   DDR2_DQS_Div_O,
  input  wire                                   DDR2_DQS_Div_I,

  // DDR3
  output wire [C_MEM_CLK_WIDTH-1:0]             DDR3_Clk,
  output wire [C_MEM_CLK_WIDTH-1:0]             DDR3_Clk_n,
  output wire [C_MEM_CE_WIDTH-1:0]              DDR3_CE,
  output wire [C_MEM_CS_N_WIDTH-1:0]            DDR3_CS_n,
  output wire [C_MEM_ODT_WIDTH-1:0]             DDR3_ODT,
  output wire                                   DDR3_RAS_n,
  output wire                                   DDR3_CAS_n,
  output wire                                   DDR3_WE_n,
  output wire [C_MEM_BANKADDR_WIDTH-1:0]        DDR3_BankAddr,
  output wire [C_MEM_ADDR_WIDTH-1:0]            DDR3_Addr,
  inout  wire [C_MEM_DATA_WIDTH+C_ECC_DATA_WIDTH-1:0]   DDR3_DQ,
  output wire [C_MEM_DM_WIDTH+C_ECC_DM_WIDTH-1:0]       DDR3_DM,
  output wire                                           DDR3_Reset_n,
  inout  wire [C_MEM_DQS_WIDTH+C_ECC_DQS_WIDTH-1:0]     DDR3_DQS,
  inout  wire [C_MEM_DQS_WIDTH+C_ECC_DQS_WIDTH-1:0]     DDR3_DQS_n,

  // Spartan6
  output wire [C_MEM_ADDR_WIDTH-1:0]            mcbx_dram_addr,
  output wire [C_MEM_BANKADDR_WIDTH-1:0]        mcbx_dram_ba,
  output wire                                   mcbx_dram_ras_n,
  output wire                                   mcbx_dram_cas_n,
  output wire                                   mcbx_dram_we_n,

  output wire                                   mcbx_dram_cke,
  output wire                                   mcbx_dram_clk,
  output wire                                   mcbx_dram_clk_n,
  inout  wire [C_MEM_DATA_WIDTH-1:0]            mcbx_dram_dq,
  inout  wire                                   mcbx_dram_dqs,
  inout  wire                                   mcbx_dram_dqs_n,
  inout  wire                                   mcbx_dram_udqs,
  inout  wire                                   mcbx_dram_udqs_n,

  output wire                                   mcbx_dram_udm,
  output wire                                   mcbx_dram_ldm,
  output wire                                   mcbx_dram_odt,
  output wire                                   mcbx_dram_ddr3_rst,

  // Spartan6 Calibration & other signals
  input  wire                                   selfrefresh_enter,
  output wire                                   selfrefresh_mode,
  input  wire                                   calib_recal,     // Input signal to trigger calibration
  inout  wire                                   rzq,
  inout  wire                                   zio

);
  ////////////////////////////////
  // MPMC Core Local Parameters //
  ////////////////////////////////

  localparam P_REQ_PENDING_CNTR_WIDTH   = (C_MAX_REQ_ALLOWED == 1) ? 1 :
                                          (C_MAX_REQ_ALLOWED == 2) ? 2 :
                                          (C_MAX_REQ_ALLOWED == 4) ? 3 :
                                          (C_MAX_REQ_ALLOWED == 8) ? 4 :
                                                                     5 ;
  // Assume that the memory is dual data rate if it is not SDRAM
  localparam P_MEM_IS_DDR               = (C_MEM_TYPE == "SDRAM") ? 1'b0 :
                                                                    1'b1 ;
  localparam P_SPECIAL_BOARD            = (C_SPECIAL_BOARD == "S3E_STKIT")? 1 :
                                          (C_SPECIAL_BOARD == "S3E_1600E")? 2 :
                                          (C_SPECIAL_BOARD == "S3A_STKIT")? 3 :
                                                                            0 ;
  localparam P_NUM_IDELAYCTRL           = (C_USE_MIG_V4_PHY || C_USE_MIG_V5_PHY || C_USE_MIG_V6_PHY)
                                          ? C_NUM_IDELAYCTRL : 0;
  localparam P_MEM_DQS_MATCHED          = 1'b0;
  localparam P_MEM_CAS_LATENCY1         = 0;
  localparam P_MEM_BURST_LENGTH         = (C_MEM_TYPE == "DDR3") ? 4'b1000 : 4'b0100;
  localparam P_MEM_ADDITIVE_LATENCY     = 0;
  localparam P_MEM_DQSN_ENABLE          = (C_MEM_TYPE == "DDR2") ?
                                            C_DDR2_DQSN_ENABLE  :
                                          (C_MEM_TYPE == "DDR3") ? 1'b1: 1'b0;
  localparam P_MEM_DDR2_ENABLE          = (C_MEM_TYPE == "DDR2") ? 1'b1 : 1'b0;
  localparam P_MEM_DQS_GATE_EN          = (C_MEM_TYPE == "DDR2") ? 1'b0 : 1'b1;
  localparam P_MEM_IDEL_HIGH_PERF       = "FALSE";
  localparam P_MEM_DATA_WIDTH_INT       = C_MEM_DATA_WIDTH*(P_MEM_IS_DDR+1)*C_NCK_PER_CLK;
  localparam P_ECC_DM_WIDTH_INT         = C_ECC_DM_WIDTH*(P_MEM_IS_DDR+1)*C_NCK_PER_CLK;
  localparam P_MEM_DM_WIDTH_INT         = C_MEM_DM_WIDTH*(P_MEM_IS_DDR+1)*C_NCK_PER_CLK;
  localparam P_ECC_DQS_WIDTH_INT        = C_ECC_DQS_WIDTH*(P_MEM_IS_DDR+1)*C_NCK_PER_CLK;
  localparam P_MEM_DQS_WIDTH_INT        = C_MEM_DQS_WIDTH*(P_MEM_IS_DDR+1)*C_NCK_PER_CLK;
  localparam P_MEM_HAS_BE               = (C_INCLUDE_ECC_SUPPORT == 0) ? 1 : 0;
  localparam P_ECC_DATA_WIDTH_INT       = (C_INCLUDE_ECC_SUPPORT == 0) ? 0 :
                                          (C_MEM_DATA_WIDTH == 8)  ? 5*(P_MEM_IS_DDR+1) :
                                          (C_MEM_DATA_WIDTH == 16) ? 6*(P_MEM_IS_DDR+1) :
                                          (C_MEM_DATA_WIDTH == 32) ? 7*(P_MEM_IS_DDR+1) :
                                          (C_MEM_DATA_WIDTH == 64) ? 8*(P_MEM_IS_DDR+1) :
                                          0;
  localparam P_MEM_CAS_WR_LATENCY       = C_MEM_TYPE == "DDR3" ? C_MEM_CAS_WR_LATENCY :
                                          C_MEM_TYPE == "DDR2" ? C_MEM_CAS_LATENCY - 1: // Used for V6
                                          C_MEM_TYPE == "DDR" ? 1 :         // Unused
                                          C_MEM_TYPE == "SDRAM" ? 0 : -1;   // Unused
  localparam P_PIX_ADDR_WIDTH_MAX       = 32;
  localparam P_PIX_RDWDADDR_WIDTH_MAX   = 4;
  localparam P_AP_PIPELINE1             = 1'b1;
  localparam P_AP_PIPELINE2             = 1'b1;
  localparam P_PIPELINE_ADDRACK         = { C_PI7_ADDRACK_PIPELINE[0],
                                            C_PI6_ADDRACK_PIPELINE[0],
                                            C_PI5_ADDRACK_PIPELINE[0],
                                            C_PI4_ADDRACK_PIPELINE[0],
                                            C_PI3_ADDRACK_PIPELINE[0],
                                            C_PI2_ADDRACK_PIPELINE[0],
                                            C_PI1_ADDRACK_PIPELINE[0],
                                            C_PI0_ADDRACK_PIPELINE[0] };
  localparam P_CP_PIPELINE                  = 1'b1;
  localparam P_MEM_SUPPORTED_COL_OFFSETS    = (C_MEM_DATA_WIDTH == 8)  ?
                                                32'h00000001 :
                                              (C_MEM_DATA_WIDTH == 16) ?
                                                32'h00000002 :
                                              (C_MEM_DATA_WIDTH == 32) ?
                                                32'h00000004 :
                                                32'h00000008 ;
  localparam P_MEM_SUPPORTED_ROW_OFFSETS    = P_MEM_SUPPORTED_COL_OFFSETS
                                                << C_MEM_PART_NUM_COL_BITS;
  localparam P_MEM_SUPPORTED_BANK_OFFSETS   = P_MEM_SUPPORTED_ROW_OFFSETS
                                                << C_MEM_PART_NUM_ROW_BITS;
  localparam P_MEM_SUPPORTED_RANK_OFFSETS   = P_MEM_SUPPORTED_BANK_OFFSETS
                                                << C_MEM_PART_NUM_BANK_BITS;
  localparam P_MEM_SUPPORTED_DIMM_OFFSETS   = P_MEM_SUPPORTED_BANK_OFFSETS
                                                << (C_MEM_PART_NUM_BANK_BITS +
                                                    C_MEM_NUM_RANKS-1);
  localparam P_MEM_SUPPORTED_TOTAL_OFFSETS  = P_MEM_SUPPORTED_DIMM_OFFSETS
                                                << (C_MEM_NUM_DIMMS-1);
  localparam integer    P_REFRESH_CNT_MAX   = (C_MEM_PART_TREFI/
                                               C_MPMC_CLK0_PERIOD_PS);
  localparam P_REFRESH_CNT_WIDTH        = (P_REFRESH_CNT_MAX <    16) ? 4 :
                                          (P_REFRESH_CNT_MAX <    32) ? 5 :
                                          (P_REFRESH_CNT_MAX <    64) ? 6 :
                                          (P_REFRESH_CNT_MAX <   128) ? 7 :
                                          (P_REFRESH_CNT_MAX <   256) ? 8 :
                                          (P_REFRESH_CNT_MAX <   512) ? 9 :
                                          (P_REFRESH_CNT_MAX <  1024) ? 10 :
                                          (P_REFRESH_CNT_MAX <  2048) ? 11 :
                                          (P_REFRESH_CNT_MAX <  4096) ? 12 :
                                          (P_REFRESH_CNT_MAX <  8192) ? 13 :
                                          (P_REFRESH_CNT_MAX < 16384) ? 14 :
                                          (P_REFRESH_CNT_MAX < 32768) ? 15 :
                                          (P_REFRESH_CNT_MAX < 65535) ? 16 :
                                                                        0;
  // Maintenance functions.
  localparam P_MAINT_PRESCALER_DIV       = C_MAINT_PRESCALER_PERIOD/(C_MPMC_CLK0_PERIOD_PS);  // Round down.
  localparam P_REFRESH_TIMER_DIV         = (C_MEM_PART_TREFI-(16*C_MPMC_CLK0_PERIOD_PS))/C_MAINT_PRESCALER_PERIOD;
  localparam P_PERIODIC_RD_TIMER_DIV     = C_MEM_PART_TPRDI/C_MAINT_PRESCALER_PERIOD;
  localparam P_MAINT_PRESCALER_PERIOD_NS = C_MAINT_PRESCALER_PERIOD / 1000;
  localparam P_ZQ_TIMER_DIV              = C_MEM_PART_TZQI/P_MAINT_PRESCALER_PERIOD_NS;

  localparam P_PM_USED                  = { C_PI7_PM_USED[0], C_PI6_PM_USED[0],
                                            C_PI5_PM_USED[0], C_PI4_PM_USED[0],
                                            C_PI3_PM_USED[0], C_PI2_PM_USED[0],
                                            C_PI1_PM_USED[0], C_PI0_PM_USED[0]};
  localparam P_PM_DC_CNTR               = { C_PI7_PM_DC_CNTR[0],
                                            C_PI6_PM_DC_CNTR[0],
                                            C_PI5_PM_DC_CNTR[0],
                                            C_PI4_PM_DC_CNTR[0],
                                            C_PI3_PM_DC_CNTR[0],
                                            C_PI2_PM_DC_CNTR[0],
                                            C_PI1_PM_DC_CNTR[0],
                                            C_PI0_PM_DC_CNTR[0] };
  // Theses should be adjusted in max_req_allowed is increased
  localparam P_PM_WR_TIMER_AWIDTH       = 1;
  localparam P_PM_WR_TIMER_DEPTH        = 2;
  localparam P_PM_RD_TIMER_AWIDTH       = 1;
  localparam P_PM_RD_TIMER_DEPTH        = 2;
  localparam P_PM_BUF_AWIDTH            = 3;
  localparam P_PM_BUF_DEPTH             = 8;
  localparam P_NPI2PM_BUF_AWIDTH        = 2;
  localparam P_NPI2PM_BUF_DEPTH         = 4;
  // When using shared addresses, each SDMA CTRL BASE ADDR will be offset by
  // this amount.
  localparam P_SDMA_CTRL_SHARED_OFFSET  = 32'h80;

  // MPMC Ctrl register settings (NOTE: NUM value must be a power of 2)
  localparam P_ECC_NUM_REG              = 16;
  localparam P_ECC_REG_OFFSET           = 32'h0;
  localparam P_ECC_REG_SIZE             = 32'h40;
  localparam P_STATIC_PHY_NUM_REG       = 1;
  localparam P_STATIC_PHY_REG_OFFSET    = 32'h1000;
  localparam P_STATIC_PHY_REG_SIZE      = 32'h4;
  // This value is 1, because we are not using CEs.
  localparam P_DEBUG_CTRL_MEM_OFFSET    = 32'h2000;
  localparam P_DEBUG_CTRL_MEM_SIZE      = 32'h1000;
  localparam P_MPMC_STATUS_NUM_REG      = 1;
  localparam P_MPMC_STATUS_REG_OFFSET   = 32'h3000;
  localparam P_MPMC_STATUS_REG_SIZE     = 32'h4;
  localparam P_PM_CTRL_NUM_REG          = 32;
  localparam P_PM_CTRL_REG_OFFSET       = 32'h7000;
  localparam P_PM_CTRL_REG_SIZE         = 32'h80;
  localparam P_PM_DATA_MEM_OFFSET       = 32'h8000;
  localparam P_PM_DATA_MEM_SIZE         = 32'h8000;

  localparam P_ECC_REG_BASEADDR         = (C_MPMC_CTRL_BASEADDR +
                                           P_ECC_REG_OFFSET);
  localparam P_ECC_REG_HIGHADDR         = (P_ECC_REG_BASEADDR +
                                           P_ECC_REG_SIZE - 1);
  localparam P_STATIC_PHY_REG_BASEADDR  = (C_MPMC_CTRL_BASEADDR +
                                           P_STATIC_PHY_REG_OFFSET);
  localparam P_STATIC_PHY_REG_HIGHADDR  = (P_STATIC_PHY_REG_BASEADDR +
                                           P_STATIC_PHY_REG_SIZE - 1);
  localparam P_DEBUG_CTRL_MEM_BASEADDR  = (C_MPMC_CTRL_BASEADDR +
                                           P_DEBUG_CTRL_MEM_OFFSET);
  localparam P_DEBUG_CTRL_MEM_HIGHADDR  = (P_DEBUG_CTRL_MEM_BASEADDR +
                                           P_DEBUG_CTRL_MEM_SIZE - 1);
  localparam P_MPMC_STATUS_REG_BASEADDR = (C_MPMC_CTRL_BASEADDR +
                                           P_MPMC_STATUS_REG_OFFSET);
  localparam P_MPMC_STATUS_REG_HIGHADDR = (P_MPMC_STATUS_REG_BASEADDR +
                                           P_MPMC_STATUS_REG_SIZE - 1);
  localparam P_PM_CTRL_REG_BASEADDR     = (C_MPMC_CTRL_BASEADDR +
                                           P_PM_CTRL_REG_OFFSET);
  localparam P_PM_CTRL_REG_HIGHADDR     = (P_PM_CTRL_REG_BASEADDR +
                                           P_PM_CTRL_REG_SIZE - 1);
  localparam P_PM_DATA_MEM_BASEADDR     = (C_MPMC_CTRL_BASEADDR +
                                           P_PM_DATA_MEM_OFFSET);
  localparam P_PM_DATA_MEM_HIGHADDR     = (P_PM_DATA_MEM_BASEADDR +
                                           P_PM_DATA_MEM_SIZE - 1);

  ///////////////////////////////
  // MPMC PIM Local Parameters //
  ///////////////////////////////
  // Port 0
  localparam P_PIM0_BASEADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_BASEADDR : C_PIM0_BASEADDR;
  localparam P_PIM0_HIGHADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_HIGHADDR : C_PIM0_HIGHADDR;
  localparam P_PIM0_B_SUBTYPE           = (C_XCL0_B_IN_USE == 1) ? C_PIM0_B_SUBTYPE : "INACTIVE";
  localparam P_SDMA_CTRL0_BASEADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 0*P_SDMA_CTRL_SHARED_OFFSET    : C_SDMA_CTRL0_BASEADDR;
  localparam P_SDMA_CTRL0_HIGHADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 1*P_SDMA_CTRL_SHARED_OFFSET - 1: C_SDMA_CTRL0_HIGHADDR;
  localparam P_PIM0_ADDR_WIDTH          = 32;
  localparam P_PIM0_DATA_WIDTH          = `GetDataWidth(C_PIM0_SUBTYPE,C_SPLB0_NATIVE_DWIDTH,C_PIM0_DATA_WIDTH, P_MEM_DATA_WIDTH_INT);
  localparam P_PIM0_BE_WIDTH            = P_PIM0_DATA_WIDTH/8;
  localparam P_PIM0_RDWDADDR_WIDTH      = 4;
  localparam P_PIM0_RD_FIFO_LATENCY     = (C_USE_MCB_S6_PHY) ? 2'b01 : C_PI0_RD_FIFO_APP_PIPELINE + 2'b01;
  localparam P_PI0_RD_FIFO_TYPE         = (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI0_RD_FIFO_TYPE;
  localparam P_PI0_WR_FIFO_TYPE         = (C_PIM0_SUBTYPE == "IXCL"  && C_XCL0_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM0_SUBTYPE == "IXCL2" && C_XCL0_B_IN_USE == 0) ? "DISABLED"
                                          : (C_XCL0_WRITEXFER == 0 && C_XCL0_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM0_SUBTYPE == "IPLB") ? "DISABLED"
                                          : (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI0_WR_FIFO_TYPE;
  localparam P_VFBC0_CHIPSCOPE_ENABLE   = 0;
  localparam P_VFBC0_CMD_PORT_ID        = 0;
  localparam P_VFBC0_WD_BYTEEN_ENABLE   = 1;
  localparam P_VFBC0_BURST_LENGTH       = 32;
  localparam P_VFBC0_ASYNC_CLOCK        = 1;
  localparam P_VFBC0_WD_ENABLE          = (C_PI0_WR_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC0_WD_DATA_WIDTH      = C_VFBC0_RDWD_DATA_WIDTH;
  localparam P_VFBC0_WD_FIFO_DEPTH      = C_VFBC0_RDWD_FIFO_DEPTH;
  localparam P_VFBC0_WD_AFULL_COUNT     = C_VFBC0_RD_AEMPTY_WD_AFULL_COUNT;
  localparam P_VFBC0_RD_ENABLE          = (C_PI0_RD_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC0_RD_DATA_WIDTH      = C_VFBC0_RDWD_DATA_WIDTH;
  localparam P_VFBC0_RD_FIFO_DEPTH      = C_VFBC0_RDWD_FIFO_DEPTH;
  localparam P_VFBC0_RD_AEMPTY_COUNT    = C_VFBC0_RD_AEMPTY_WD_AFULL_COUNT;

  // Port 1
  localparam P_PIM1_BASEADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_BASEADDR : C_PIM1_BASEADDR;
  localparam P_PIM1_HIGHADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_HIGHADDR : C_PIM1_HIGHADDR;
  localparam P_PIM1_B_SUBTYPE           = (C_XCL1_B_IN_USE == 1) ? C_PIM1_B_SUBTYPE : "INACTIVE";
  localparam P_SDMA_CTRL1_BASEADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 1*P_SDMA_CTRL_SHARED_OFFSET    : C_SDMA_CTRL1_BASEADDR;
  localparam P_SDMA_CTRL1_HIGHADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 2*P_SDMA_CTRL_SHARED_OFFSET - 1: C_SDMA_CTRL1_HIGHADDR;
  localparam P_PIM1_ADDR_WIDTH          = 32;
  localparam P_PIM1_DATA_WIDTH          = `GetDataWidth(C_PIM1_SUBTYPE,C_SPLB1_NATIVE_DWIDTH,C_PIM1_DATA_WIDTH, P_MEM_DATA_WIDTH_INT);
  localparam P_PIM1_BE_WIDTH            = P_PIM1_DATA_WIDTH/8;
  localparam P_PIM1_RDWDADDR_WIDTH      = 4;
  localparam P_PIM1_RD_FIFO_LATENCY     = (C_USE_MCB_S6_PHY) ? 2'b01 : C_PI1_RD_FIFO_APP_PIPELINE + 2'b01;
  localparam P_PI1_RD_FIFO_TYPE         = (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI1_RD_FIFO_TYPE;
  localparam P_PI1_WR_FIFO_TYPE         = (C_PIM1_SUBTYPE == "IXCL"  && C_XCL1_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM1_SUBTYPE == "IXCL2" && C_XCL1_B_IN_USE == 0) ? "DISABLED"
                                          : (C_XCL1_WRITEXFER == 0 && C_XCL1_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM1_SUBTYPE == "IPLB") ? "DISABLED"
                                          : (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI1_WR_FIFO_TYPE;
  localparam P_VFBC1_CHIPSCOPE_ENABLE   = 0;
  localparam P_VFBC1_CMD_PORT_ID        = 0;
  localparam P_VFBC1_WD_BYTEEN_ENABLE   = 1;
  localparam P_VFBC1_BURST_LENGTH       = 32;
  localparam P_VFBC1_ASYNC_CLOCK        = 1;
  localparam P_VFBC1_WD_ENABLE          = (C_PI1_WR_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC1_WD_DATA_WIDTH      = C_VFBC1_RDWD_DATA_WIDTH;
  localparam P_VFBC1_WD_FIFO_DEPTH      = C_VFBC1_RDWD_FIFO_DEPTH;
  localparam P_VFBC1_WD_AFULL_COUNT     = C_VFBC1_RD_AEMPTY_WD_AFULL_COUNT;
  localparam P_VFBC1_RD_ENABLE          = (C_PI1_RD_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC1_RD_DATA_WIDTH      = C_VFBC1_RDWD_DATA_WIDTH;
  localparam P_VFBC1_RD_FIFO_DEPTH      = C_VFBC1_RDWD_FIFO_DEPTH;
  localparam P_VFBC1_RD_AEMPTY_COUNT    = C_VFBC1_RD_AEMPTY_WD_AFULL_COUNT;


  // Port 2
  localparam P_PIM2_BASEADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_BASEADDR : C_PIM2_BASEADDR;
  localparam P_PIM2_HIGHADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_HIGHADDR : C_PIM2_HIGHADDR;
  localparam P_PIM2_B_SUBTYPE           = (C_XCL2_B_IN_USE == 1) ? C_PIM2_B_SUBTYPE : "INACTIVE";
  localparam P_SDMA_CTRL2_BASEADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 2*P_SDMA_CTRL_SHARED_OFFSET    : C_SDMA_CTRL2_BASEADDR;
  localparam P_SDMA_CTRL2_HIGHADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 3*P_SDMA_CTRL_SHARED_OFFSET - 1: C_SDMA_CTRL2_HIGHADDR;
  localparam P_PIM2_ADDR_WIDTH          = 32;
  localparam P_PIM2_DATA_WIDTH          = `GetDataWidth(C_PIM2_SUBTYPE,C_SPLB2_NATIVE_DWIDTH,C_PIM2_DATA_WIDTH, P_MEM_DATA_WIDTH_INT);
  localparam P_PIM2_BE_WIDTH            = P_PIM2_DATA_WIDTH/8;
  localparam P_PIM2_RDWDADDR_WIDTH      = 4;
  localparam P_PIM2_RD_FIFO_LATENCY     = (C_USE_MCB_S6_PHY) ? 2'b01 : C_PI2_RD_FIFO_APP_PIPELINE + 2'b01;
  localparam P_PI2_RD_FIFO_TYPE         = (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI2_RD_FIFO_TYPE;
  localparam P_PI2_WR_FIFO_TYPE         = (C_PIM2_SUBTYPE == "IXCL"  && C_XCL2_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM2_SUBTYPE == "IXCL2" && C_XCL2_B_IN_USE == 0) ? "DISABLED"
                                          : (C_XCL2_WRITEXFER == 0 && C_XCL2_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM2_SUBTYPE == "IPLB") ? "DISABLED"
                                          : (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI2_WR_FIFO_TYPE;
  localparam P_VFBC2_CHIPSCOPE_ENABLE   = 0;
  localparam P_VFBC2_CMD_PORT_ID        = 0;
  localparam P_VFBC2_WD_BYTEEN_ENABLE   = 1;
  localparam P_VFBC2_BURST_LENGTH       = 32;
  localparam P_VFBC2_ASYNC_CLOCK        = 1;
  localparam P_VFBC2_WD_ENABLE          = (C_PI2_WR_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC2_WD_DATA_WIDTH      = C_VFBC2_RDWD_DATA_WIDTH;
  localparam P_VFBC2_WD_FIFO_DEPTH      = C_VFBC2_RDWD_FIFO_DEPTH;
  localparam P_VFBC2_WD_AFULL_COUNT     = C_VFBC2_RD_AEMPTY_WD_AFULL_COUNT;
  localparam P_VFBC2_RD_ENABLE          = (C_PI2_RD_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC2_RD_DATA_WIDTH      = C_VFBC2_RDWD_DATA_WIDTH;
  localparam P_VFBC2_RD_FIFO_DEPTH      = C_VFBC2_RDWD_FIFO_DEPTH;
  localparam P_VFBC2_RD_AEMPTY_COUNT    = C_VFBC2_RD_AEMPTY_WD_AFULL_COUNT;


  // Port 3
  localparam P_PIM3_BASEADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_BASEADDR : C_PIM3_BASEADDR;
  localparam P_PIM3_HIGHADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_HIGHADDR : C_PIM3_HIGHADDR;
  localparam P_PIM3_B_SUBTYPE           = (C_XCL3_B_IN_USE == 1) ? C_PIM3_B_SUBTYPE : "INACTIVE";
  localparam P_SDMA_CTRL3_BASEADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 3*P_SDMA_CTRL_SHARED_OFFSET    : C_SDMA_CTRL3_BASEADDR;
  localparam P_SDMA_CTRL3_HIGHADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 4*P_SDMA_CTRL_SHARED_OFFSET - 1: C_SDMA_CTRL3_HIGHADDR;
  localparam P_PIM3_ADDR_WIDTH          = 32;
  localparam P_PIM3_DATA_WIDTH          = `GetDataWidth(C_PIM3_SUBTYPE,C_SPLB3_NATIVE_DWIDTH,C_PIM3_DATA_WIDTH, P_MEM_DATA_WIDTH_INT);
  localparam P_PIM3_BE_WIDTH            = P_PIM3_DATA_WIDTH/8;
  localparam P_PIM3_RDWDADDR_WIDTH      = 4;
  localparam P_PIM3_RD_FIFO_LATENCY     = (C_USE_MCB_S6_PHY) ? 2'b01 : C_PI3_RD_FIFO_APP_PIPELINE + 2'b01;
  localparam P_PI3_RD_FIFO_TYPE         = (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI3_RD_FIFO_TYPE;
  localparam P_PI3_WR_FIFO_TYPE         = (C_PIM3_SUBTYPE == "IXCL"  && C_XCL3_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM3_SUBTYPE == "IXCL2" && C_XCL3_B_IN_USE == 0) ? "DISABLED"
                                          : (C_XCL3_WRITEXFER == 0 && C_XCL3_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM3_SUBTYPE == "IPLB") ? "DISABLED"
                                          : (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI3_WR_FIFO_TYPE;
  localparam P_VFBC3_CHIPSCOPE_ENABLE   = 0;
  localparam P_VFBC3_CMD_PORT_ID        = 0;
  localparam P_VFBC3_WD_BYTEEN_ENABLE   = 1;
  localparam P_VFBC3_BURST_LENGTH       = 32;
  localparam P_VFBC3_ASYNC_CLOCK        = 1;
  localparam P_VFBC3_WD_ENABLE          = (C_PI3_WR_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC3_WD_DATA_WIDTH      = C_VFBC3_RDWD_DATA_WIDTH;
  localparam P_VFBC3_WD_FIFO_DEPTH      = C_VFBC3_RDWD_FIFO_DEPTH;
  localparam P_VFBC3_WD_AFULL_COUNT     = C_VFBC3_RD_AEMPTY_WD_AFULL_COUNT;
  localparam P_VFBC3_RD_ENABLE          = (C_PI3_RD_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC3_RD_DATA_WIDTH      = C_VFBC3_RDWD_DATA_WIDTH;
  localparam P_VFBC3_RD_FIFO_DEPTH      = C_VFBC3_RDWD_FIFO_DEPTH;
  localparam P_VFBC3_RD_AEMPTY_COUNT    = C_VFBC3_RD_AEMPTY_WD_AFULL_COUNT;

  // Port 4
  localparam P_PIM4_BASEADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_BASEADDR : C_PIM4_BASEADDR;
  localparam P_PIM4_HIGHADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_HIGHADDR : C_PIM4_HIGHADDR;
  localparam P_PIM4_B_SUBTYPE           = (C_XCL4_B_IN_USE == 1) ? C_PIM4_B_SUBTYPE : "INACTIVE";
  localparam P_SDMA_CTRL4_BASEADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 4*P_SDMA_CTRL_SHARED_OFFSET    : C_SDMA_CTRL4_BASEADDR;
  localparam P_SDMA_CTRL4_HIGHADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 5*P_SDMA_CTRL_SHARED_OFFSET - 1: C_SDMA_CTRL4_HIGHADDR;
  localparam P_PIM4_ADDR_WIDTH          = 32;
  localparam P_PIM4_DATA_WIDTH          = `GetDataWidth(C_PIM4_SUBTYPE,C_SPLB4_NATIVE_DWIDTH,C_PIM4_DATA_WIDTH, P_MEM_DATA_WIDTH_INT);
  localparam P_PIM4_BE_WIDTH            = P_PIM4_DATA_WIDTH/8;
  localparam P_PIM4_RDWDADDR_WIDTH      = 4;
  localparam P_PIM4_RD_FIFO_LATENCY     = (C_USE_MCB_S6_PHY) ? 2'b01 : C_PI4_RD_FIFO_APP_PIPELINE + 2'b01;
  localparam P_PI4_RD_FIFO_TYPE         = (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI4_RD_FIFO_TYPE;
  localparam P_PI4_WR_FIFO_TYPE         = (C_PIM4_SUBTYPE == "IXCL"  && C_XCL4_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM4_SUBTYPE == "IXCL2" && C_XCL4_B_IN_USE == 0) ? "DISABLED"
                                          : (C_XCL4_WRITEXFER == 0 && C_XCL4_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM4_SUBTYPE == "IPLB") ? "DISABLED"
                                          : (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI4_WR_FIFO_TYPE;
  localparam P_VFBC4_CHIPSCOPE_ENABLE   = 0;
  localparam P_VFBC4_CMD_PORT_ID        = 0;
  localparam P_VFBC4_WD_BYTEEN_ENABLE   = 1;
  localparam P_VFBC4_BURST_LENGTH       = 32;
  localparam P_VFBC4_ASYNC_CLOCK        = 1;
  localparam P_VFBC4_WD_ENABLE          = (C_PI4_WR_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC4_WD_DATA_WIDTH      = C_VFBC4_RDWD_DATA_WIDTH;
  localparam P_VFBC4_WD_FIFO_DEPTH      = C_VFBC4_RDWD_FIFO_DEPTH;
  localparam P_VFBC4_WD_AFULL_COUNT     = C_VFBC4_RD_AEMPTY_WD_AFULL_COUNT;
  localparam P_VFBC4_RD_ENABLE          = (C_PI4_RD_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC4_RD_DATA_WIDTH      = C_VFBC4_RDWD_DATA_WIDTH;
  localparam P_VFBC4_RD_FIFO_DEPTH      = C_VFBC4_RDWD_FIFO_DEPTH;
  localparam P_VFBC4_RD_AEMPTY_COUNT    = C_VFBC4_RD_AEMPTY_WD_AFULL_COUNT;

  // Port 5
  localparam P_PIM5_BASEADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_BASEADDR : C_PIM5_BASEADDR;
  localparam P_PIM5_HIGHADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_HIGHADDR : C_PIM5_HIGHADDR;
  localparam P_PIM5_B_SUBTYPE           = (C_XCL5_B_IN_USE == 1) ? C_PIM5_B_SUBTYPE : "INACTIVE";
  localparam P_SDMA_CTRL5_BASEADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 5*P_SDMA_CTRL_SHARED_OFFSET    : C_SDMA_CTRL5_BASEADDR;
  localparam P_SDMA_CTRL5_HIGHADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 6*P_SDMA_CTRL_SHARED_OFFSET - 1: C_SDMA_CTRL5_HIGHADDR;
  localparam P_PIM5_ADDR_WIDTH          = 32;
  localparam P_PIM5_DATA_WIDTH          = `GetDataWidth(C_PIM5_SUBTYPE,C_SPLB5_NATIVE_DWIDTH,C_PIM5_DATA_WIDTH, P_MEM_DATA_WIDTH_INT);
  localparam P_PIM5_BE_WIDTH            = P_PIM5_DATA_WIDTH/8;
  localparam P_PIM5_RDWDADDR_WIDTH      = 4;
  localparam P_PIM5_RD_FIFO_LATENCY     = (C_USE_MCB_S6_PHY) ? 2'b01 : C_PI5_RD_FIFO_APP_PIPELINE + 2'b01;
  localparam P_PI5_RD_FIFO_TYPE         = (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI5_RD_FIFO_TYPE;
  localparam P_PI5_WR_FIFO_TYPE         = (C_PIM5_SUBTYPE == "IXCL"  && C_XCL5_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM5_SUBTYPE == "IXCL2" && C_XCL5_B_IN_USE == 0) ? "DISABLED"
                                          : (C_XCL5_WRITEXFER == 0 && C_XCL5_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM5_SUBTYPE == "IPLB") ? "DISABLED"
                                          : (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI5_WR_FIFO_TYPE;
  localparam P_VFBC5_CHIPSCOPE_ENABLE   = 0;
  localparam P_VFBC5_CMD_PORT_ID        = 0;
  localparam P_VFBC5_WD_BYTEEN_ENABLE   = 1;
  localparam P_VFBC5_BURST_LENGTH       = 32;
  localparam P_VFBC5_ASYNC_CLOCK        = 1;
  localparam P_VFBC5_WD_ENABLE          = (C_PI5_WR_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC5_WD_DATA_WIDTH      = C_VFBC5_RDWD_DATA_WIDTH;
  localparam P_VFBC5_WD_FIFO_DEPTH      = C_VFBC5_RDWD_FIFO_DEPTH;
  localparam P_VFBC5_WD_AFULL_COUNT     = C_VFBC5_RD_AEMPTY_WD_AFULL_COUNT;
  localparam P_VFBC5_RD_ENABLE          = (C_PI5_RD_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC5_RD_DATA_WIDTH      = C_VFBC5_RDWD_DATA_WIDTH;
  localparam P_VFBC5_RD_FIFO_DEPTH      = C_VFBC5_RDWD_FIFO_DEPTH;
  localparam P_VFBC5_RD_AEMPTY_COUNT    = C_VFBC5_RD_AEMPTY_WD_AFULL_COUNT;

  // Port 6
  localparam P_PIM6_BASEADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_BASEADDR : C_PIM6_BASEADDR;
  localparam P_PIM6_HIGHADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_HIGHADDR : C_PIM6_HIGHADDR;
  localparam P_PIM6_B_SUBTYPE           = (C_XCL6_B_IN_USE == 1) ? C_PIM6_B_SUBTYPE : "INACTIVE";
  localparam P_SDMA_CTRL6_BASEADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 6*P_SDMA_CTRL_SHARED_OFFSET    : C_SDMA_CTRL6_BASEADDR;
  localparam P_SDMA_CTRL6_HIGHADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 7*P_SDMA_CTRL_SHARED_OFFSET - 1: C_SDMA_CTRL6_HIGHADDR;
  localparam P_PIM6_ADDR_WIDTH          = 32;
  localparam P_PIM6_DATA_WIDTH          = `GetDataWidth(C_PIM6_SUBTYPE,C_SPLB6_NATIVE_DWIDTH,C_PIM6_DATA_WIDTH, P_MEM_DATA_WIDTH_INT);
  localparam P_PIM6_BE_WIDTH            = P_PIM6_DATA_WIDTH/8;
  localparam P_PIM6_RDWDADDR_WIDTH      = 4;
  localparam P_PIM6_RD_FIFO_LATENCY     = (C_USE_MCB_S6_PHY) ? 2'b01 : C_PI6_RD_FIFO_APP_PIPELINE + 2'b01;
  localparam P_PI6_RD_FIFO_TYPE         = (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI6_RD_FIFO_TYPE;
  localparam P_PI6_WR_FIFO_TYPE         = (C_PIM6_SUBTYPE == "IXCL"  && C_XCL6_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM6_SUBTYPE == "IXCL2" && C_XCL6_B_IN_USE == 0) ? "DISABLED"
                                          : (C_XCL6_WRITEXFER == 0 && C_XCL6_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM6_SUBTYPE == "IPLB") ? "DISABLED"
                                          : (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI6_WR_FIFO_TYPE;
  localparam P_VFBC6_CHIPSCOPE_ENABLE   = 0;
  localparam P_VFBC6_CMD_PORT_ID        = 0;
  localparam P_VFBC6_WD_BYTEEN_ENABLE   = 1;
  localparam P_VFBC6_BURST_LENGTH       = 32;
  localparam P_VFBC6_ASYNC_CLOCK        = 1;
  localparam P_VFBC6_WD_ENABLE          = (C_PI6_WR_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC6_WD_DATA_WIDTH      = C_VFBC6_RDWD_DATA_WIDTH;
  localparam P_VFBC6_WD_FIFO_DEPTH      = C_VFBC6_RDWD_FIFO_DEPTH;
  localparam P_VFBC6_WD_AFULL_COUNT     = C_VFBC6_RD_AEMPTY_WD_AFULL_COUNT;
  localparam P_VFBC6_RD_ENABLE          = (C_PI6_RD_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC6_RD_DATA_WIDTH      = C_VFBC6_RDWD_DATA_WIDTH;
  localparam P_VFBC6_RD_FIFO_DEPTH      = C_VFBC6_RDWD_FIFO_DEPTH;
  localparam P_VFBC6_RD_AEMPTY_COUNT    = C_VFBC6_RD_AEMPTY_WD_AFULL_COUNT;

  // Port 7
  localparam P_PIM7_BASEADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_BASEADDR : C_PIM7_BASEADDR;
  localparam P_PIM7_HIGHADDR            = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_MPMC_HIGHADDR : C_PIM7_HIGHADDR;
  localparam P_PIM7_B_SUBTYPE           = (C_XCL7_B_IN_USE == 1) ? C_PIM7_B_SUBTYPE : "INACTIVE";
  localparam P_SDMA_CTRL7_BASEADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 7*P_SDMA_CTRL_SHARED_OFFSET    : C_SDMA_CTRL7_BASEADDR;
  localparam P_SDMA_CTRL7_HIGHADDR      = (C_ALL_PIMS_SHARE_ADDRESSES == 1)
                                            ? C_SDMA_CTRL_BASEADDR + 8*P_SDMA_CTRL_SHARED_OFFSET - 1: C_SDMA_CTRL7_HIGHADDR;
  localparam P_PIM7_ADDR_WIDTH          = 32;
  localparam P_PIM7_DATA_WIDTH          = `GetDataWidth(C_PIM7_SUBTYPE,C_SPLB7_NATIVE_DWIDTH,C_PIM7_DATA_WIDTH, P_MEM_DATA_WIDTH_INT);

  localparam P_PIM7_BE_WIDTH            = P_PIM7_DATA_WIDTH/8;
  localparam P_PIM7_RDWDADDR_WIDTH      = 4;
  localparam P_PIM7_RD_FIFO_LATENCY     = (C_USE_MCB_S6_PHY) ? 2'b01 : C_PI7_RD_FIFO_APP_PIPELINE + 2'b01;
  localparam P_PI7_RD_FIFO_TYPE         = (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI7_RD_FIFO_TYPE;
  localparam P_PI7_WR_FIFO_TYPE         = (C_PIM7_SUBTYPE == "IXCL"  && C_XCL7_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM7_SUBTYPE == "IXCL2" && C_XCL7_B_IN_USE == 0) ? "DISABLED"
                                          : (C_XCL7_WRITEXFER == 0 && C_XCL7_B_IN_USE == 0) ? "DISABLED"
                                          : (C_PIM7_SUBTYPE == "IPLB") ? "DISABLED"
                                          : (C_USE_MCB_S6_PHY) ? "SRL"
                                          : C_PI7_WR_FIFO_TYPE;
  localparam P_VFBC7_CHIPSCOPE_ENABLE   = 0;
  localparam P_VFBC7_CMD_PORT_ID        = 0;
  localparam P_VFBC7_WD_BYTEEN_ENABLE   = 1;
  localparam P_VFBC7_BURST_LENGTH       = 32;
  localparam P_VFBC7_ASYNC_CLOCK        = 1;
  localparam P_VFBC7_WD_ENABLE          = (C_PI7_WR_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC7_WD_DATA_WIDTH      = C_VFBC7_RDWD_DATA_WIDTH;
  localparam P_VFBC7_WD_FIFO_DEPTH      = C_VFBC7_RDWD_FIFO_DEPTH;
  localparam P_VFBC7_WD_AFULL_COUNT     = C_VFBC7_RD_AEMPTY_WD_AFULL_COUNT;
  localparam P_VFBC7_RD_ENABLE          = (C_PI7_RD_FIFO_TYPE == "DISABLED") ? 0 : 1;
  localparam P_VFBC7_RD_DATA_WIDTH      = C_VFBC7_RDWD_DATA_WIDTH;
  localparam P_VFBC7_RD_FIFO_DEPTH      = C_VFBC7_RDWD_FIFO_DEPTH;
  localparam P_VFBC7_RD_AEMPTY_COUNT    = C_VFBC7_RD_AEMPTY_WD_AFULL_COUNT;

  // Bus up some of the port parameters
  localparam P_PIM_RD_FIFO_LATENCY      = { P_PIM7_RD_FIFO_LATENCY[1:0],
                                            P_PIM6_RD_FIFO_LATENCY[1:0],
                                            P_PIM5_RD_FIFO_LATENCY[1:0],
                                            P_PIM4_RD_FIFO_LATENCY[1:0],
                                            P_PIM3_RD_FIFO_LATENCY[1:0],
                                            P_PIM2_RD_FIFO_LATENCY[1:0],
                                            P_PIM1_RD_FIFO_LATENCY[1:0],
                                            P_PIM0_RD_FIFO_LATENCY[1:0]
                                          };


  ////////////////////////////
  // MPMC Static Parameters //
  ////////////////////////////
  localparam P_BASEADDR_ARB0            = 9'h000;
  localparam P_HIGHADDR_ARB0            = P_BASEADDR_ARB0 + C_ARB0_NUM_SLOTS -1;
  localparam P_BASEADDR_ARB1            = 9'h010;
  localparam P_HIGHADDR_ARB1            = 9'h01F;
  localparam P_BASEADDR_ARB2            = 9'h020;
  localparam P_HIGHADDR_ARB2            = 9'h02F;
  localparam P_BASEADDR_ARB3            = 9'h030;
  localparam P_HIGHADDR_ARB3            = 9'h03F;
  localparam P_BASEADDR_ARB4            = 9'h040;
  localparam P_HIGHADDR_ARB4            = 9'h04F;
  localparam P_BASEADDR_ARB5            = 9'h050;
  localparam P_HIGHADDR_ARB5            = 9'h05F;
  localparam P_BASEADDR_ARB6            = 9'h060;
  localparam P_HIGHADDR_ARB6            = 9'h06F;
  localparam P_BASEADDR_ARB7            = 9'h070;
  localparam P_HIGHADDR_ARB7            = 9'h07F;
  localparam P_BASEADDR_ARB8            = 9'h080;
  localparam P_HIGHADDR_ARB8            = 9'h08F;
  localparam P_BASEADDR_ARB9            = 9'h090;
  localparam P_HIGHADDR_ARB9            = 9'h09F;
  localparam P_BASEADDR_ARB10           = 9'h0A0;
  localparam P_HIGHADDR_ARB10           = 9'h0AF;
  localparam P_BASEADDR_ARB11           = 9'h0B0;
  localparam P_HIGHADDR_ARB11           = 9'h0BF;
  localparam P_BASEADDR_ARB12           = 9'h0C0;
  localparam P_HIGHADDR_ARB12           = 9'h0CF;
  localparam P_BASEADDR_ARB13           = 9'h0D0;
  localparam P_HIGHADDR_ARB13           = 9'h0DF;
  localparam P_BASEADDR_ARB14           = 9'h0E0;
  localparam P_HIGHADDR_ARB14           = 9'h0EF;
  localparam P_BASEADDR_ARB15           = 9'h0F0;
  localparam P_HIGHADDR_ARB15           = 9'h0FF;
  localparam P_ARB_BRAM_SRVAL_A         = 36'h0;
  localparam P_ARB_BRAM_SRVAL_B         = 36'h0;
  localparam P_ARB_BRAM_INIT_08         = 256'h0;
  localparam P_ARB_BRAM_INIT_09         = 256'h0;
  localparam P_ARB_BRAM_INIT_0A         = 256'h0;
  localparam P_ARB_BRAM_INIT_0B         = 256'h0;
  localparam P_ARB_BRAM_INIT_0C         = 256'h0;
  localparam P_ARB_BRAM_INIT_0D         = 256'h0;
  localparam P_ARB_BRAM_INIT_0E         = 256'h0;
  localparam P_ARB_BRAM_INIT_0F         = 256'h0;
  localparam P_ARB_BRAM_INIT_10         = 256'h0;
  localparam P_ARB_BRAM_INIT_11         = 256'h0;
  localparam P_ARB_BRAM_INIT_12         = 256'h0;
  localparam P_ARB_BRAM_INIT_13         = 256'h0;
  localparam P_ARB_BRAM_INIT_14         = 256'h0;
  localparam P_ARB_BRAM_INIT_15         = 256'h0;
  localparam P_ARB_BRAM_INIT_16         = 256'h0;
  localparam P_ARB_BRAM_INIT_17         = 256'h0;
  localparam P_ARB_BRAM_INIT_18         = 256'h0;
  localparam P_ARB_BRAM_INIT_19         = 256'h0;
  localparam P_ARB_BRAM_INIT_1A         = 256'h0;
  localparam P_ARB_BRAM_INIT_1B         = 256'h0;
  localparam P_ARB_BRAM_INIT_1C         = 256'h0;
  localparam P_ARB_BRAM_INIT_1D         = 256'h0;
  localparam P_ARB_BRAM_INIT_1E         = 256'h0;
  localparam P_ARB_BRAM_INIT_1F         = 256'h0;
  localparam P_ARB_BRAM_INIT_20         = 256'h0;
  localparam P_ARB_BRAM_INIT_21         = 256'h0;
  localparam P_ARB_BRAM_INIT_22         = 256'h0;
  localparam P_ARB_BRAM_INIT_23         = 256'h0;
  localparam P_ARB_BRAM_INIT_24         = 256'h0;
  localparam P_ARB_BRAM_INIT_25         = 256'h0;
  localparam P_ARB_BRAM_INIT_26         = 256'h0;
  localparam P_ARB_BRAM_INIT_27         = 256'h0;
  localparam P_ARB_BRAM_INIT_28         = 256'h0;
  localparam P_ARB_BRAM_INIT_29         = 256'h0;
  localparam P_ARB_BRAM_INIT_2A         = 256'h0;
  localparam P_ARB_BRAM_INIT_2B         = 256'h0;
  localparam P_ARB_BRAM_INIT_2C         = 256'h0;
  localparam P_ARB_BRAM_INIT_2D         = 256'h0;
  localparam P_ARB_BRAM_INIT_2E         = 256'h0;
  localparam P_ARB_BRAM_INIT_2F         = 256'h0;
  localparam P_ARB_BRAM_INIT_30         = 256'h0;
  localparam P_ARB_BRAM_INIT_31         = 256'h0;
  localparam P_ARB_BRAM_INIT_32         = 256'h0;
  localparam P_ARB_BRAM_INIT_33         = 256'h0;
  localparam P_ARB_BRAM_INIT_34         = 256'h0;
  localparam P_ARB_BRAM_INIT_35         = 256'h0;
  localparam P_ARB_BRAM_INIT_36         = 256'h0;
  localparam P_ARB_BRAM_INIT_37         = 256'h0;
  localparam P_ARB_BRAM_INIT_38         = 256'h0;
  localparam P_ARB_BRAM_INIT_39         = 256'h0;
  localparam P_ARB_BRAM_INIT_3A         = 256'h0;
  localparam P_ARB_BRAM_INIT_3B         = 256'h0;
  localparam P_ARB_BRAM_INIT_3C         = 256'h0;
  localparam P_ARB_BRAM_INIT_3D         = 256'h0;
  localparam P_ARB_BRAM_INIT_3E         = 256'h0;
  localparam P_ARB_BRAM_INIT_3F         = 256'h0;
  localparam P_ARB_BRAM_INITP_00        = 256'h0;
  localparam P_ARB_BRAM_INITP_01        = 256'h0;
  localparam P_ARB_BRAM_INITP_02        = 256'h0;
  localparam P_ARB_BRAM_INITP_03        = 256'h0;
  localparam P_ARB_BRAM_INITP_04        = 256'h0;
  localparam P_ARB_BRAM_INITP_05        = 256'h0;
  localparam P_ARB_BRAM_INITP_06        = 256'h0;
  localparam P_ARB_BRAM_INITP_07        = 256'h0;

  localparam P_NUM_CTRL_SIGNALS         = 36;
  localparam P_WORD_WRITE_SEQ           = 0;
  localparam P_WORD_READ_SEQ            = 1;
  localparam P_DOUBLEWORD_WRITE_SEQ     = 2;
  localparam P_DOUBLEWORD_READ_SEQ      = 3;
  localparam P_CL4_WRITE_SEQ            = 4;
  localparam P_CL4_READ_SEQ             = 5;
  localparam P_CL8_WRITE_SEQ            = 6;
  localparam P_CL8_READ_SEQ             = 7;
  localparam P_B16_WRITE_SEQ            = 8;
  localparam P_B16_READ_SEQ             = 9;
  localparam P_B32_WRITE_SEQ            = 10;
  localparam P_B32_READ_SEQ             = 11;
  localparam P_B64_WRITE_SEQ            = 12;
  localparam P_B64_READ_SEQ             = 13;
  localparam P_REFH_SEQ                 = 14;
  localparam P_NOP_SEQ                  = 15;
  localparam P_USE_FIXED_BASEADDR_CTRL  = 0;
  localparam P_IDELAY_CTRL_RDY_HIGHBIT  = (P_NUM_IDELAYCTRL > 0) ?
                                            P_NUM_IDELAYCTRL - 1 : 0;
  // These parameters have to be calculate last
  localparam P_PIX_DATA_WIDTH_MAX      = (C_NUM_PORTS > 0 && P_PIM0_DATA_WIDTH == 64) ? 64
                                       : (C_NUM_PORTS > 1 && P_PIM1_DATA_WIDTH == 64) ? 64
                                       : (C_NUM_PORTS > 2 && P_PIM2_DATA_WIDTH == 64) ? 64
                                       : (C_NUM_PORTS > 3 && P_PIM3_DATA_WIDTH == 64) ? 64
                                       : (C_NUM_PORTS > 4 && P_PIM4_DATA_WIDTH == 64) ? 64
                                       : (C_NUM_PORTS > 5 && P_PIM5_DATA_WIDTH == 64) ? 64
                                       : (C_NUM_PORTS > 6 && P_PIM6_DATA_WIDTH == 64) ? 64
                                       : (C_NUM_PORTS > 7 && P_PIM7_DATA_WIDTH == 64) ? 64
                                       : 32;
  localparam P_PIX_BE_WIDTH_MAX         = P_PIX_DATA_WIDTH_MAX/8;

  localparam  P_PI_DATA_WIDTH = {((P_PIM7_DATA_WIDTH == 64) ? 1'b1 : 1'b0),
                                 ((P_PIM6_DATA_WIDTH == 64) ? 1'b1 : 1'b0),
                                 ((P_PIM5_DATA_WIDTH == 64) ? 1'b1 : 1'b0),
                                 ((P_PIM4_DATA_WIDTH == 64) ? 1'b1 : 1'b0),
                                 ((P_PIM3_DATA_WIDTH == 64) ? 1'b1 : 1'b0),
                                 ((P_PIM2_DATA_WIDTH == 64) ? 1'b1 : 1'b0),
                                 ((P_PIM1_DATA_WIDTH == 64) ? 1'b1 : 1'b0),
                                 ((P_PIM0_DATA_WIDTH == 64) ? 1'b1 : 1'b0)};
  // Per port FIFO parameters
  localparam P_PI_WR_FIFO_TYPE={((P_PI7_WR_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI7_WR_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI6_WR_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI6_WR_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI5_WR_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI5_WR_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI4_WR_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI4_WR_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI3_WR_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI3_WR_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI2_WR_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI2_WR_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI1_WR_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI1_WR_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI0_WR_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI0_WR_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10)};
  localparam P_PI_RD_FIFO_TYPE={((P_PI7_RD_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI7_RD_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI6_RD_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI6_RD_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI5_RD_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI5_RD_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI4_RD_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI4_RD_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI3_RD_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI3_RD_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI2_RD_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI2_RD_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI1_RD_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI1_RD_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10),
                                ((P_PI0_RD_FIFO_TYPE == "DISABLED") ? 2'b00 :
                                 (P_PI0_RD_FIFO_TYPE == "BRAM")     ? 2'b11 :
                                                                      2'b10)};

  // FIFO localparams
  localparam P_RD_FIFO_APP_PIPELINE = {
                C_PI7_RD_FIFO_APP_PIPELINE[0], C_PI6_RD_FIFO_APP_PIPELINE[0],
                C_PI5_RD_FIFO_APP_PIPELINE[0], C_PI4_RD_FIFO_APP_PIPELINE[0],
                C_PI3_RD_FIFO_APP_PIPELINE[0], C_PI2_RD_FIFO_APP_PIPELINE[0],
                C_PI1_RD_FIFO_APP_PIPELINE[0], C_PI0_RD_FIFO_APP_PIPELINE[0]};
  localparam P_RD_FIFO_MEM_PIPELINE = {
                C_PI7_RD_FIFO_MEM_PIPELINE[0], C_PI6_RD_FIFO_MEM_PIPELINE[0],
                C_PI5_RD_FIFO_MEM_PIPELINE[0], C_PI4_RD_FIFO_MEM_PIPELINE[0],
                C_PI3_RD_FIFO_MEM_PIPELINE[0], C_PI2_RD_FIFO_MEM_PIPELINE[0],
                C_PI1_RD_FIFO_MEM_PIPELINE[0], C_PI0_RD_FIFO_MEM_PIPELINE[0]};
  localparam P_WR_FIFO_APP_PIPELINE = {
                C_PI7_WR_FIFO_APP_PIPELINE[0], C_PI6_WR_FIFO_APP_PIPELINE[0],
                C_PI5_WR_FIFO_APP_PIPELINE[0], C_PI4_WR_FIFO_APP_PIPELINE[0],
                C_PI3_WR_FIFO_APP_PIPELINE[0], C_PI2_WR_FIFO_APP_PIPELINE[0],
                C_PI1_WR_FIFO_APP_PIPELINE[0], C_PI0_WR_FIFO_APP_PIPELINE[0]};
  localparam P_WR_FIFO_MEM_PIPELINE = {
                C_PI7_WR_FIFO_MEM_PIPELINE[0], C_PI6_WR_FIFO_MEM_PIPELINE[0],
                C_PI5_WR_FIFO_MEM_PIPELINE[0], C_PI4_WR_FIFO_MEM_PIPELINE[0],
                C_PI3_WR_FIFO_MEM_PIPELINE[0], C_PI2_WR_FIFO_MEM_PIPELINE[0],
                C_PI1_WR_FIFO_MEM_PIPELINE[0], C_PI0_WR_FIFO_MEM_PIPELINE[0]};

  // Values are combined to pass into Performance Monitors
  localparam P_PIM_BASETYPE = {
                C_PIM7_BASETYPE[3:0], C_PIM6_BASETYPE[3:0],
                C_PIM5_BASETYPE[3:0], C_PIM4_BASETYPE[3:0],
                C_PIM3_BASETYPE[3:0], C_PIM2_BASETYPE[3:0],
                C_PIM1_BASETYPE[3:0], C_PIM0_BASETYPE[3:0]};


  // V4 MIG PHY local params.
  localparam integer P_TBY4TAPVALUE     = (C_TBY4TAPVALUE == 9999) ? (C_MPMC_CLK0_PERIOD_PS/4)/78.125 : C_TBY4TAPVALUE;

  ///////////////////////////
  // Reg/Wire Declarations //
  ///////////////////////////
  // intermediate memory wires between the mpmc_core and the ports
  wire [C_MEM_CLK_WIDTH-1:0]                     MEM_Clk;
  wire [C_MEM_CLK_WIDTH-1:0]                     MEM_Clk_n;
  wire [C_MEM_CE_WIDTH-1:0]                      MEM_CE;
  wire [C_MEM_CS_N_WIDTH-1:0]                    MEM_CS_n;
  wire [C_MEM_ODT_WIDTH-1:0]                     MEM_ODT;
  wire                                           MEM_RAS_n;
  wire                                           MEM_CAS_n;
  wire                                           MEM_WE_n;
  wire [C_MEM_BANKADDR_WIDTH-1:0]                MEM_BankAddr;
  wire [C_MEM_ADDR_WIDTH-1:0]                    MEM_Addr;
  wire [C_MEM_DATA_WIDTH+C_ECC_DATA_WIDTH-1:0]   MEM_DQ;
  wire [C_MEM_DM_WIDTH+C_ECC_DM_WIDTH-1:0]       MEM_DM;
  wire                                           MEM_Reset_n;
  wire [C_MEM_DQS_WIDTH+C_ECC_DQS_WIDTH-1:0]     MEM_DQS;
  wire [C_MEM_DQS_WIDTH+C_ECC_DQS_WIDTH-1:0]     MEM_DQS_n;
  wire                                           MEM_DQS_Div_O;
  wire                                           MEM_DQS_Div_I;

  // MPMC_Ctrl Wires
  wire [P_ECC_NUM_REG-1:0]              ECC_Reg_CE;
  wire [31:0]                           ECC_Reg_In;
  wire [P_ECC_NUM_REG*32-1:0]           ECC_Reg_Out;
  wire [P_STATIC_PHY_NUM_REG-1:0]       Static_Phy_Reg_CE;
  wire [31:0]                           Static_Phy_Reg_In;
  wire [P_STATIC_PHY_NUM_REG*32-1:0]    Static_Phy_Reg_Out;
  wire [0:31]                           Debug_Ctrl_Addr;
  wire                                  Debug_Ctrl_WE;
  wire [0:31]                           Debug_Ctrl_In;
  wire [0:31]                           Debug_Ctrl_Out;
  // The two wire below are not connected because MPMC_Status is read only
  wire [P_MPMC_STATUS_NUM_REG-1:0]      MPMC_Status_Reg_CE;
  wire [31:0]                           MPMC_Status_Reg_In;
  wire [P_MPMC_STATUS_NUM_REG*32-1:0]   MPMC_Status_Reg_Out;
  wire [P_PM_CTRL_NUM_REG-1:0]          PM_Ctrl_Reg_CE;
  wire [31:0]                           PM_Ctrl_Reg_In;
  wire [P_PM_CTRL_NUM_REG*32-1:0]       PM_Ctrl_Reg_Out;
  wire [0:31]                           PM_Data_Out;
  wire [0:31]                           PM_Data_Addr;

  wire [0:31]                           MPMC_Status_Reg0;

  wire [C_NUM_PORTS-1:0]                        NPI_InitDone;
  wire [C_NUM_PORTS*P_PIX_ADDR_WIDTH_MAX-1:0]   NPI_Addr;
  wire [C_NUM_PORTS-1:0]                        NPI_AddrReq;
  wire [C_NUM_PORTS-1:0]                        NPI_AddrAck;
  wire [C_NUM_PORTS-1:0]                        NPI_RNW;
  wire [C_NUM_PORTS*4-1:0]                      NPI_Size;
  wire [C_NUM_PORTS-1:0]                        NPI_RdModWr;
  wire [C_NUM_PORTS*P_PIX_DATA_WIDTH_MAX-1:0]   NPI_WrFIFO_Data;
  wire [C_NUM_PORTS*P_PIX_BE_WIDTH_MAX-1:0]     NPI_WrFIFO_BE;
  wire [C_NUM_PORTS-1:0]                        NPI_WrFIFO_Push;
  wire [C_NUM_PORTS*P_PIX_DATA_WIDTH_MAX-1:0]   NPI_RdFIFO_Data;
  wire [C_NUM_PORTS-1:0]                        NPI_RdFIFO_Pop;
  wire [C_NUM_PORTS*P_PIX_RDWDADDR_WIDTH_MAX-1:0]   NPI_RdFIFO_RdWdAddr;
  wire [C_NUM_PORTS-1:0]                        NPI_WrFIFO_Empty;
  wire [C_NUM_PORTS-1:0]                        NPI_WrFIFO_AlmostFull;
  wire [C_NUM_PORTS-1:0]                        NPI_WrFIFO_Flush;
  wire [C_NUM_PORTS-1:0]                        NPI_RdFIFO_Empty;
  wire [C_NUM_PORTS-1:0]                        NPI_RdFIFO_Flush;
  wire [C_NUM_PORTS-1:0]                        NPI_RdFIFO_DataAvailable;
  wire [C_NUM_PORTS*2-1:0]                      NPI_RdFIFO_Latency;

  // Reset and Idelay wires/regs
  wire [7:0]                        pim_rst;
  reg  [C_NUM_PORTS*2+4:0]          Rst_tocore  = {C_NUM_PORTS*2+5{1'b1}}   /* synthesis syn_maxfan = 20 */;
  reg                               Rst_tocore_tmp = 1   /* synthesis syn_maxfan = 20 */;
  reg  [C_NUM_PORTS-1:0]            Rst_topim = {C_NUM_PORTS{1'b1}}   /* synthesis syn_maxfan = 20 */;
  // synthesis attribute equivalent_register_removal of Rst_tocore is "no"
  // synthesis attribute equivalent_register_removal of Rst_topim is "no"
  reg                               idelay_ctrl_rdy_d1 = 0;
  reg                               idelay_ctrl_rdy_d2 = 0;
  reg                               Rst270 = 1;
  reg                               Rst90 = 1;
  wire [P_IDELAY_CTRL_RDY_HIGHBIT:0]idelay_ctrl_rdy;
  reg                               Rst_d1 = 1;
  reg                               Rst_d2 = 1;
  genvar i;


  /////////////////////////////////
  //  Reset and IdelayCtrl Logic //
  /////////////////////////////////
  always @(posedge MPMC_Clk0)
    begin
      Rst_d1 <= MPMC_Rst | (| pim_rst);
      Rst_d2 <= Rst_d1;
    end

  generate
    for (i=0;i<C_NUM_PORTS;i=i+1) begin : replicate_mpmc_pim_reset
      always @(posedge MPMC_Clk0)
        Rst_topim[i] <= Rst_d2;
    end
  endgenerate

  generate
    if (P_NUM_IDELAYCTRL>0)
      begin : gen_rst_idelayctrl
        always @(posedge MPMC_Clk0)
          Rst_tocore_tmp <= Rst_d2 | ~idelay_ctrl_rdy_d2;

        always @(posedge MPMC_Clk0)
          begin
            idelay_ctrl_rdy_d1 <= (& idelay_ctrl_rdy) & MPMC_Idelayctrl_Rdy_I;
            idelay_ctrl_rdy_d2 <= idelay_ctrl_rdy_d1;
          end

        assign MPMC_Idelayctrl_Rdy_O = & idelay_ctrl_rdy;
      end
    else
      begin : gen_rst_noidelayctrl
        assign MPMC_Idelayctrl_Rdy_O = MPMC_Idelayctrl_Rdy_I;
        always @(posedge MPMC_Clk0)
          Rst_tocore_tmp <= Rst_d2;
      end
  endgenerate

  generate
    for (i=0;i<C_NUM_PORTS*2+5;i=i+1) begin : replicate_mpmc_reset
      if (P_NUM_IDELAYCTRL>0)
        begin : gen_rst_idelayctrl
          always @(posedge MPMC_Clk0)
            Rst_tocore[i] <= Rst_d2 | ~idelay_ctrl_rdy_d2;
        end
      else
        begin : gen_rst_noidelayctrl
          always @(posedge MPMC_Clk0)
            Rst_tocore[i] <= Rst_d2;
        end
    end
  endgenerate

  always @(negedge MPMC_Clk90)
    Rst270 <= Rst_tocore_tmp;

  always @(posedge MPMC_Clk90)
    Rst90 <= Rst270;

  generate
     if (C_USE_MIG_V6_PHY) begin : gen_iodelay_grp
         for (i=0;i<P_NUM_IDELAYCTRL;i=i+1) begin : gen_instantiate_idelayctrls
         (* IODELAY_GROUP = C_IODELAY_GRP *) IDELAYCTRL
              idelayctrl0 (
                            .RDY(idelay_ctrl_rdy[i]),
                            .REFCLK(MPMC_Clk_200MHz),
                            .RST(Rst_d1)
                          );
         end
       end else begin : gen_no_iodelay_grp
         for (i=0;i<P_NUM_IDELAYCTRL;i=i+1) begin : gen_instantiate_idelayctrls
            IDELAYCTRL
              idelayctrl0 (
                            .RDY(idelay_ctrl_rdy[i]),
                            .REFCLK(MPMC_Clk_200MHz),
                            .RST(Rst_d1)
                          );
         end
       end
  endgenerate

  // wiring for the output memory signals, bidirections are not wired up here, but passed straight through
  generate
    if (C_MEM_TYPE == "DDR3") begin : DDR3_Memory
      assign DDR3_Clk      = MEM_Clk;
      assign DDR3_Clk_n    = MEM_Clk_n;
      assign DDR3_CE       = MEM_CE;
      assign DDR3_CS_n     = MEM_CS_n;
      assign DDR3_RAS_n    = MEM_RAS_n;
      assign DDR3_CAS_n    = MEM_CAS_n;
      assign DDR3_WE_n     = MEM_WE_n;
      assign DDR3_BankAddr = MEM_BankAddr;
      assign DDR3_Addr     = MEM_Addr;
      assign DDR3_DM       = MEM_DM;
      assign DDR3_ODT      = MEM_ODT;
      assign DDR3_Reset_n  = MEM_Reset_n;
      assign MEM_DQS_Div_I = 1'b0;
    end
    else if (C_MEM_TYPE == "DDR2") begin : DDR2_Memory
      assign DDR2_Clk       = MEM_Clk;
      assign DDR2_Clk_n     = MEM_Clk_n;
      assign DDR2_CE        = MEM_CE;
      assign DDR2_CS_n      = MEM_CS_n;
      assign DDR2_RAS_n     = MEM_RAS_n;
      assign DDR2_CAS_n     = MEM_CAS_n;
      assign DDR2_WE_n      = MEM_WE_n;
      assign DDR2_BankAddr  = MEM_BankAddr;
      assign DDR2_Addr      = MEM_Addr;
      assign DDR2_DM        = MEM_DM;
      assign DDR2_ODT       = MEM_ODT;
      assign DDR2_DQS_Div_O = MEM_DQS_Div_O;
      assign MEM_DQS_Div_I  = DDR2_DQS_Div_I;
    end
    else if (C_MEM_TYPE == "DDR") begin : DDR_Memory
      assign DDR_Clk       = MEM_Clk;
      assign DDR_Clk_n     = MEM_Clk_n;
      assign DDR_CE        = MEM_CE;
      assign DDR_CS_n      = MEM_CS_n;
      assign DDR_RAS_n     = MEM_RAS_n;
      assign DDR_CAS_n     = MEM_CAS_n;
      assign DDR_WE_n      = MEM_WE_n;
      assign DDR_BankAddr  = MEM_BankAddr;
      assign DDR_Addr      = MEM_Addr;
      assign DDR_DM        = MEM_DM;
      assign DDR_DQS_Div_O = MEM_DQS_Div_O;
      assign MEM_DQS_Div_I = DDR_DQS_Div_I;
    end
    else if (C_MEM_TYPE == "SDRAM") begin : SDRAM_Memory
      assign SDRAM_Clk      = MEM_Clk;
      assign SDRAM_CE       = MEM_CE;
      assign SDRAM_CS_n     = MEM_CS_n;
      assign SDRAM_RAS_n    = MEM_RAS_n;
      assign SDRAM_CAS_n    = MEM_CAS_n;
      assign SDRAM_WE_n     = MEM_WE_n;
      assign SDRAM_BankAddr = MEM_BankAddr;
      assign SDRAM_Addr     = MEM_Addr;
      assign SDRAM_DM       = MEM_DM;
    end
  endgenerate

  assign NPI_RdFIFO_Latency[C_NUM_PORTS*2-1:0] = (C_USE_MCB_S6_PHY) ? {C_NUM_PORTS{2'b01}} :
                                    P_PIM_RD_FIFO_LATENCY[C_NUM_PORTS*2-1:0];

  // These outputs are no longer part of mpmc_core, tie them off.
  assign NPI_RdFIFO_DataAvailable[C_NUM_PORTS-1:0] = {C_NUM_PORTS{1'b0}};

  // MPMC_STATUS Registers (Read-Only)
  assign MPMC_Status_Reg0[0]     = C_INCLUDE_ECC_SUPPORT ? 1'b1 : 1'b0;
  assign MPMC_Status_Reg0[1]     = C_USE_STATIC_PHY      ? 1'b1 : 1'b0;
  assign MPMC_Status_Reg0[2]     = C_DEBUG_REG_ENABLE    ? 1'b1 : 1'b0;
  assign MPMC_Status_Reg0[3]     = 1'b1;
  assign MPMC_Status_Reg0[4:6]   = 3'b0;
  assign MPMC_Status_Reg0[7]     = C_PM_ENABLE           ? 1'b1 : 1'b0;
  assign MPMC_Status_Reg0[8:15]  = 8'h0;
  assign MPMC_Status_Reg0[16:19] = (C_MEM_TYPE == "SDRAM") ? 4'h0 :
                                   (C_MEM_TYPE == "DDR")   ? 4'h1 :
                                   (C_MEM_TYPE == "DDR2")  ? 4'h2 :
                                   (C_MEM_TYPE == "DDR3")  ? 4'h3 :
                                   (C_MEM_TYPE == "LPDDR") ? 4'h4 :
                                   4'hF;
  assign MPMC_Status_Reg0[20:23] = (C_MEM_DATA_WIDTH ==  8) ? 4'h3 :
                                   (C_MEM_DATA_WIDTH == 16) ? 4'h4 :
                                   (C_MEM_DATA_WIDTH == 32) ? 4'h5 :
                                   (C_MEM_DATA_WIDTH == 64) ? 4'h6 :
                                   4'hF;
  assign MPMC_Status_Reg0[24]    = 1'b0;
  assign MPMC_Status_Reg0[25:27] = (C_NUM_PORTS[2:0] - 3'b1);
  assign MPMC_Status_Reg0[28:31] = (C_BASEFAMILY == "spartan3")  ? 4'h0 :
                                   (C_BASEFAMILY == "spartan3a") ? 4'h0 :
                                   (C_BASEFAMILY == "spartan3e") ? 4'h0 :
                                   (C_BASEFAMILY == "virtex4")   ? 4'h1 :
                                   (C_BASEFAMILY == "virtex5")   ? 4'h2 :
                                   (C_BASEFAMILY == "virtex6")   ? 4'h3 :
                                   (C_BASEFAMILY == "spartan6")  ? 4'h4 :
                                   4'hF;

  /////////////////////////////
  // MPMC Core Instantiation //
  /////////////////////////////
  mpmc_core
  #(
    .C_FAMILY                          ( C_BASEFAMILY                          ) ,
    .C_USE_MIG_S3_PHY                  ( C_USE_MIG_S3_PHY                  ) ,
    .C_USE_MIG_V4_PHY                  ( C_USE_MIG_V4_PHY                  ) ,
    .C_USE_MIG_V5_PHY                  ( C_USE_MIG_V5_PHY                  ) ,
    .C_USE_MIG_V6_PHY                  ( C_USE_MIG_V6_PHY                  ) ,
    .C_USE_MCB_S6_PHY                  ( C_USE_MCB_S6_PHY                  ) ,
    .C_IODELAY_GRP                     ( C_IODELAY_GRP                     ) ,
    .C_SPEEDGRADE_INT                  ( C_SPEEDGRADE_INT                  ) ,
    .C_MEM_TYPE                        ( C_MEM_TYPE                        ) ,
    // synopsys translate_off
    .C_SKIP_INIT_DELAY                 ( C_SKIP_SIM_INIT_DELAY             ) ,
    // synopsys translate_on
    .C_DEBUG_REG_ENABLE                ( C_DEBUG_REG_ENABLE                ) ,
    .C_USE_STATIC_PHY                  ( C_USE_STATIC_PHY                  ) ,
    .C_STATIC_PHY_RDDATA_CLK_SEL       ( C_STATIC_PHY_RDDATA_CLK_SEL       ) ,
    .C_STATIC_PHY_RDDATA_SWAP_RISE     ( C_STATIC_PHY_RDDATA_SWAP_RISE     ) ,
    .C_STATIC_PHY_RDEN_DELAY           ( C_STATIC_PHY_RDEN_DELAY           ) ,
    .C_MEM_PART_NUM_COL_BITS           ( C_MEM_PART_NUM_COL_BITS           ) ,
    .C_ARB0_NUM_SLOTS                  ( C_ARB0_NUM_SLOTS                  ) ,
    .C_PORT_CONFIG                     ( C_PORT_CONFIG                     ) ,
    .C_MEM_ADDR_ORDER                  ( C_MEM_ADDR_ORDER                  ) ,
    .C_MEM_CALIBRATION_MODE            ( C_MEM_CALIBRATION_MODE            ) ,
    .C_MEM_CALIBRATION_DELAY           ( C_MEM_CALIBRATION_DELAY           ) ,
    .C_MEM_CALIBRATION_SOFT_IP         ( C_MEM_CALIBRATION_SOFT_IP         ) ,
    .C_MEM_SKIP_IN_TERM_CAL            ( C_MEM_SKIP_IN_TERM_CAL            ) ,
    .C_MEM_SKIP_DYNAMIC_CAL            ( C_MEM_SKIP_DYNAMIC_CAL            ) ,
    .C_MEM_SKIP_DYN_IN_TERM            ( C_MEM_SKIP_DYN_IN_TERM            ) ,
    .C_MEM_CALIBRATION_BYPASS          ( C_MEM_CALIBRATION_BYPASS          ) ,
    .C_MCB_DRP_CLK_PRESENT             ( C_MPMC_MCB_DRP_CLK_PRESENT        ) ,
    .C_MEM_TZQINIT_MAXCNT              ( C_MEM_TZQINIT_MAXCNT              ) ,
    .C_MCB_LDQSP_TAP_DELAY_VAL         ( C_MCB_LDQSP_TAP_DELAY_VAL         ),  // 0 to 255 inclusive
    .C_MCB_UDQSP_TAP_DELAY_VAL         ( C_MCB_UDQSP_TAP_DELAY_VAL         ),  // 0 to 255 inclusive
    .C_MCB_LDQSN_TAP_DELAY_VAL         ( C_MCB_LDQSN_TAP_DELAY_VAL         ),  // 0 to 255 inclusive
    .C_MCB_UDQSN_TAP_DELAY_VAL         ( C_MCB_UDQSN_TAP_DELAY_VAL         ),  // 0 to 255 inclusive
    .C_MCB_DQ0_TAP_DELAY_VAL           ( C_MCB_DQ0_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ1_TAP_DELAY_VAL           ( C_MCB_DQ1_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ2_TAP_DELAY_VAL           ( C_MCB_DQ2_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ3_TAP_DELAY_VAL           ( C_MCB_DQ3_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ4_TAP_DELAY_VAL           ( C_MCB_DQ4_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ5_TAP_DELAY_VAL           ( C_MCB_DQ5_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ6_TAP_DELAY_VAL           ( C_MCB_DQ6_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ7_TAP_DELAY_VAL           ( C_MCB_DQ7_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ8_TAP_DELAY_VAL           ( C_MCB_DQ8_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ9_TAP_DELAY_VAL           ( C_MCB_DQ9_TAP_DELAY_VAL           ),  // 0 to 255 inclusive
    .C_MCB_DQ10_TAP_DELAY_VAL          ( C_MCB_DQ10_TAP_DELAY_VAL          ),  // 0 to 255 inclusive
    .C_MCB_DQ11_TAP_DELAY_VAL          ( C_MCB_DQ11_TAP_DELAY_VAL          ),  // 0 to 255 inclusive
    .C_MCB_DQ12_TAP_DELAY_VAL          ( C_MCB_DQ12_TAP_DELAY_VAL          ),  // 0 to 255 inclusive
    .C_MCB_DQ13_TAP_DELAY_VAL          ( C_MCB_DQ13_TAP_DELAY_VAL          ),  // 0 to 255 inclusive
    .C_MCB_DQ14_TAP_DELAY_VAL          ( C_MCB_DQ14_TAP_DELAY_VAL          ),  // 0 to 255 inclusive
    .C_MCB_DQ15_TAP_DELAY_VAL          ( C_MCB_DQ15_TAP_DELAY_VAL          ),  // 0 to 255 inclusive

    .C_MPMC_CLK_MEM_2X_PERIOD_PS       ( C_MPMC_CLK_MEM_2X_PERIOD_PS       ) ,
    .C_MCB_USE_EXTERNAL_BUFPLL         ( C_MCB_USE_EXTERNAL_BUFPLL         ) ,
    .C_INCLUDE_ECC_SUPPORT             ( C_INCLUDE_ECC_SUPPORT             ) ,
    .C_INCLUDE_ECC_TEST                ( C_INCLUDE_ECC_TEST                ) ,
    .C_ECC_DEFAULT_ON                  ( C_ECC_DEFAULT_ON                  ) ,
    .C_ECC_SEC_THRESHOLD               ( C_ECC_SEC_THRESHOLD               ) ,
    .C_ECC_DEC_THRESHOLD               ( C_ECC_DEC_THRESHOLD               ) ,
    .C_ECC_PEC_THRESHOLD               ( C_ECC_PEC_THRESHOLD               ) ,
    .C_IS_DDR                          ( P_MEM_IS_DDR                      ) ,
    .C_SPECIAL_BOARD                   ( P_SPECIAL_BOARD                   ) ,
    .C_MEM_PA_SR                       ( C_MEM_PA_SR                       ) ,
    .C_MEM_CAS_WR_LATENCY              ( P_MEM_CAS_WR_LATENCY              ) ,
    .C_MEM_AUTO_SR                     ( C_MEM_AUTO_SR                     ) ,
    .C_MEM_HIGH_TEMP_SR                ( C_MEM_HIGH_TEMP_SR                ) ,
    .C_MEM_DYNAMIC_WRITE_ODT           ( C_MEM_DYNAMIC_WRITE_ODT           ) ,
    .C_MEM_WRLVL                       ( C_MEM_WRLVL                       ) ,
    .C_IDELAY_CLK_FREQ                 ( C_IDELAY_CLK_FREQ                 ) ,
    .C_MEM_PHASE_DETECT                ( C_MEM_PHASE_DETECT                ) ,
    .C_MEM_IBUF_LPWR_MODE              ( C_MEM_IBUF_LPWR_MODE              ) ,
    .C_MEM_IODELAY_HP_MODE             ( C_MEM_IODELAY_HP_MODE             ) ,
    .C_MEM_SIM_INIT_OPTION             ( C_MEM_SIM_INIT_OPTION             ) ,
    .C_MEM_SIM_CAL_OPTION              ( C_MEM_SIM_CAL_OPTION              ) ,
    .C_MEM_CAL_WIDTH                   ( C_MEM_CAL_WIDTH                   ) ,
    .C_MEM_NDQS_COL0                   ( C_MEM_NDQS_COL0                   ) ,
    .C_MEM_NDQS_COL1                   ( C_MEM_NDQS_COL1                   ) ,
    .C_MEM_NDQS_COL2                   ( C_MEM_NDQS_COL2                   ) ,
    .C_MEM_NDQS_COL3                   ( C_MEM_NDQS_COL3                   ) ,
    .C_MEM_DQS_LOC_COL0                ( C_MEM_DQS_LOC_COL0                ) ,
    .C_MEM_DQS_LOC_COL1                ( C_MEM_DQS_LOC_COL1                ) ,
    .C_MEM_DQS_LOC_COL2                ( C_MEM_DQS_LOC_COL2                ) ,
    .C_MEM_DQS_LOC_COL3                ( C_MEM_DQS_LOC_COL3                ) ,
    .C_NUM_PORTS                       ( C_NUM_PORTS                       ) ,
    .C_MEM_DQS_IO_COL                  ( C_MEM_DQS_IO_COL                  ) ,
    .C_MEM_DQ_IO_MS                    ( C_MEM_DQ_IO_MS                    ) ,
    .C_MEM_DQS_MATCHED                 ( P_MEM_DQS_MATCHED                 ) ,
    .C_MEM_CAS_LATENCY0                ( C_MEM_CAS_LATENCY                 ) ,
    .C_MEM_CAS_LATENCY1                ( P_MEM_CAS_LATENCY1                ) ,
    .C_MEM_BURST_LENGTH                ( P_MEM_BURST_LENGTH                ) ,
    .C_MEM_ADDITIVE_LATENCY            ( P_MEM_ADDITIVE_LATENCY            ) ,
    .C_MEM_ODT_TYPE                    ( C_MEM_ODT_TYPE                    ) ,
    .C_MEM_REDUCED_DRV                 ( C_MEM_REDUCED_DRV                 ) ,
    .C_MEM_REG_DIMM                    ( C_MEM_REG_DIMM                    ) ,
    .C_MPMC_CLK_PERIOD                 ( C_MPMC_CLK0_PERIOD_PS             ) ,
    .C_MEM_PART_TRAS                   ( C_MEM_PART_TRAS                   ) ,
    .C_MEM_PART_TRCD                   ( C_MEM_PART_TRCD                   ) ,
    .C_MEM_PART_TWR                    ( C_MEM_PART_TWR                    ) ,
    .C_MEM_PART_TREFI                  ( C_MEM_PART_TREFI                  ) ,
    .C_MEM_PART_TRP                    ( C_MEM_PART_TRP                    ) ,
    .C_MEM_PART_TRFC                   ( C_MEM_PART_TRFC                   ) ,
    .C_MEM_PART_TWTR                   ( C_MEM_PART_TWTR                   ) ,
    .C_MEM_PART_TRTP                   ( C_MEM_PART_TRTP                   ) ,
    .C_MEM_PART_TPRDI                  ( C_MEM_PART_TPRDI                  ) ,
    .C_MEM_PART_TZQI                   ( C_MEM_PART_TZQI                   ) ,
    .C_MEM_DDR2_ENABLE                 ( P_MEM_DDR2_ENABLE                 ) ,
    .C_MEM_DQSN_ENABLE                 ( P_MEM_DQSN_ENABLE                 ) ,
    .C_MEM_DQS_GATE_EN                 ( P_MEM_DQS_GATE_EN                 ) ,
    .C_MEM_IDEL_HIGH_PERF              ( P_MEM_IDEL_HIGH_PERF              ) ,
    .C_MEM_CLK_WIDTH                   ( C_MEM_CLK_WIDTH                   ) ,
    .C_MEM_ODT_WIDTH                   ( C_MEM_ODT_WIDTH                   ) ,
    .C_MEM_CE_WIDTH                    ( C_MEM_CE_WIDTH                    ) ,
    .C_MEM_CS_N_WIDTH                  ( C_MEM_CS_N_WIDTH                  ) ,
    .C_MEM_ADDR_WIDTH                  ( C_MEM_ADDR_WIDTH                  ) ,
    .C_MEM_BANKADDR_WIDTH              ( C_MEM_BANKADDR_WIDTH              ) ,
    .C_ECC_DATA_WIDTH_INT              ( P_ECC_DATA_WIDTH_INT              ) ,
    .C_ECC_DATA_WIDTH                  ( C_ECC_DATA_WIDTH                  ) ,
    .C_ECC_DM_WIDTH                    ( C_ECC_DM_WIDTH                    ) ,
    .C_ECC_DM_WIDTH_INT                ( P_ECC_DM_WIDTH_INT                ) ,
    .C_ECC_DQS_WIDTH                   ( C_ECC_DQS_WIDTH                   ) ,
    .C_ECC_DQS_WIDTH_INT               ( P_ECC_DQS_WIDTH_INT               ) ,
    .C_MEM_DATA_WIDTH                  ( C_MEM_DATA_WIDTH                  ) ,
    .C_MEM_DATA_WIDTH_INT              ( P_MEM_DATA_WIDTH_INT              ) ,
    .C_MEM_DM_WIDTH                    ( C_MEM_DM_WIDTH                    ) ,
    .C_MEM_DM_WIDTH_INT                ( P_MEM_DM_WIDTH_INT                ) ,
    .C_MEM_DQS_WIDTH                   ( C_MEM_DQS_WIDTH                   ) ,
    .C_MEM_DQS_WIDTH_INT               ( P_MEM_DQS_WIDTH_INT               ) ,
    .C_MEM_BITS_DATA_PER_DQS           ( C_MEM_BITS_DATA_PER_DQS           ) ,
    .C_MEM_NUM_DIMMS                   ( C_MEM_NUM_DIMMS                   ) ,
    .C_MEM_NUM_RANKS                   ( C_MEM_NUM_RANKS                   ) ,
    .C_MEM_SUPPORTED_TOTAL_OFFSETS     ( P_MEM_SUPPORTED_TOTAL_OFFSETS     ) ,
    .C_MEM_SUPPORTED_DIMM_OFFSETS      ( P_MEM_SUPPORTED_DIMM_OFFSETS      ) ,
    .C_MEM_SUPPORTED_RANK_OFFSETS      ( P_MEM_SUPPORTED_RANK_OFFSETS      ) ,
    .C_MEM_SUPPORTED_BANK_OFFSETS      ( P_MEM_SUPPORTED_BANK_OFFSETS      ) ,
    .C_MEM_SUPPORTED_ROW_OFFSETS       ( P_MEM_SUPPORTED_ROW_OFFSETS       ) ,
    .C_MEM_SUPPORTED_COL_OFFSETS       ( P_MEM_SUPPORTED_COL_OFFSETS       ) ,
    .C_WR_TRAINING_PORT                ( C_WR_TRAINING_PORT                ) ,
    .C_PIX_ADDR_WIDTH_MAX              ( P_PIX_ADDR_WIDTH_MAX              ) ,
    .C_PIX_DATA_WIDTH_MAX              ( P_PIX_DATA_WIDTH_MAX              ) ,
    .C_PI_DATA_WIDTH                   ( P_PI_DATA_WIDTH                   ) ,
    .C_PI_RD_FIFO_TYPE                 ( P_PI_RD_FIFO_TYPE                 ) ,
    .C_PI_WR_FIFO_TYPE                 ( P_PI_WR_FIFO_TYPE                 ) ,
    .C_RD_FIFO_APP_PIPELINE            ( P_RD_FIFO_APP_PIPELINE            ) ,
    .C_RD_FIFO_MEM_PIPELINE            ( P_RD_FIFO_MEM_PIPELINE            ) ,
    .C_WR_FIFO_APP_PIPELINE            ( P_WR_FIFO_APP_PIPELINE            ) ,
    .C_WR_FIFO_MEM_PIPELINE            ( P_WR_FIFO_MEM_PIPELINE            ) ,
    .C_PIX_BE_WIDTH_MAX                ( P_PIX_BE_WIDTH_MAX                ) ,
    .C_PIX_RDWDADDR_WIDTH_MAX          ( P_PIX_RDWDADDR_WIDTH_MAX          ) ,
    .C_WR_DATAPATH_TML_PIPELINE        ( C_WR_DATAPATH_TML_PIPELINE        ) ,
    .C_RD_DATAPATH_TML_MAX_FANOUT      ( C_RD_DATAPATH_TML_MAX_FANOUT      ) ,
    .C_AP_PIPELINE1                    ( P_AP_PIPELINE1                    ) ,
    .C_AP_PIPELINE2                    ( P_AP_PIPELINE2                    ) ,
    .C_NUM_CTRL_SIGNALS                ( P_NUM_CTRL_SIGNALS                ) ,
    .C_PIPELINE_ADDRACK                ( P_PIPELINE_ADDRACK                ) ,
    .C_CP_PIPELINE                     ( P_CP_PIPELINE                     ) ,
    .C_ARB_PIPELINE                    ( C_ARB_PIPELINE                    ) ,
    .C_MAX_REQ_ALLOWED                 ( C_MAX_REQ_ALLOWED                 ) ,
    .C_REQ_PENDING_CNTR_WIDTH          ( P_REQ_PENDING_CNTR_WIDTH          ) ,
    .C_REFRESH_CNT_MAX                 ( P_REFRESH_CNT_MAX                 ) ,
    .C_REFRESH_CNT_WIDTH               ( P_REFRESH_CNT_WIDTH               ) ,
    .C_MAINT_PRESCALER_DIV             ( P_MAINT_PRESCALER_DIV             ) ,
    .C_REFRESH_TIMER_DIV               ( P_REFRESH_TIMER_DIV               ) ,
    .C_PERIODIC_RD_TIMER_DIV           ( P_PERIODIC_RD_TIMER_DIV           ) ,
    .C_MAINT_PRESCALER_PERIOD_NS       ( P_MAINT_PRESCALER_PERIOD_NS       ) ,
    .C_ZQ_TIMER_DIV                    ( P_ZQ_TIMER_DIV                    ) ,
    .C_ECC_NUM_REG                     ( P_ECC_NUM_REG                     ) ,
    .C_STATIC_PHY_NUM_REG              ( P_STATIC_PHY_NUM_REG              ) ,
    // Ctrl Path Params
    .C_WORD_WRITE_SEQ                  ( P_WORD_WRITE_SEQ                  ) ,
    .C_WORD_READ_SEQ                   ( P_WORD_READ_SEQ                   ) ,
    .C_DOUBLEWORD_WRITE_SEQ            ( P_DOUBLEWORD_WRITE_SEQ            ) ,
    .C_DOUBLEWORD_READ_SEQ             ( P_DOUBLEWORD_READ_SEQ             ) ,
    .C_CL4_WRITE_SEQ                   ( P_CL4_WRITE_SEQ                   ) ,
    .C_CL4_READ_SEQ                    ( P_CL4_READ_SEQ                    ) ,
    .C_CL8_WRITE_SEQ                   ( P_CL8_WRITE_SEQ                   ) ,
    .C_CL8_READ_SEQ                    ( P_CL8_READ_SEQ                    ) ,
    .C_B16_WRITE_SEQ                   ( P_B16_WRITE_SEQ                   ) ,
    .C_B16_READ_SEQ                    ( P_B16_READ_SEQ                    ) ,
    .C_B32_WRITE_SEQ                   ( P_B32_WRITE_SEQ                   ) ,
    .C_B32_READ_SEQ                    ( P_B32_READ_SEQ                    ) ,
    .C_B64_WRITE_SEQ                   ( P_B64_WRITE_SEQ                   ) ,
    .C_B64_READ_SEQ                    ( P_B64_READ_SEQ                    ) ,
    .C_NOP_SEQ                         ( P_NOP_SEQ                         ) ,
    .C_REFH_SEQ                        ( P_REFH_SEQ                        ) ,
    .C_NCK_PER_CLK                     ( C_NCK_PER_CLK                     ) ,
    .C_TWR                             ( C_TWR                             ) ,
    .C_CTRL_COMPLETE_INDEX             ( C_CTRL_COMPLETE_INDEX             ) ,
    .C_CTRL_IS_WRITE_INDEX             ( C_CTRL_IS_WRITE_INDEX             ) ,
    .C_CTRL_PHYIF_RAS_N_INDEX          ( C_CTRL_PHYIF_RAS_N_INDEX          ) ,
    .C_CTRL_PHYIF_CAS_N_INDEX          ( C_CTRL_PHYIF_CAS_N_INDEX          ) ,
    .C_CTRL_PHYIF_WE_N_INDEX           ( C_CTRL_PHYIF_WE_N_INDEX           ) ,
    .C_CTRL_RMW_INDEX                  ( C_CTRL_RMW_INDEX                  ) ,
    .C_CTRL_SKIP_0_INDEX               ( C_CTRL_SKIP_0_INDEX               ) ,
    .C_CTRL_PHYIF_DQS_O_INDEX          ( C_CTRL_PHYIF_DQS_O_INDEX          ) ,
    .C_CTRL_SKIP_1_INDEX               ( C_CTRL_SKIP_1_INDEX               ) ,
    .C_CTRL_DP_RDFIFO_PUSH_INDEX       ( C_CTRL_DP_RDFIFO_PUSH_INDEX       ) ,
    .C_CTRL_SKIP_2_INDEX               ( C_CTRL_SKIP_2_INDEX               ) ,
    .C_CTRL_AP_COL_CNT_LOAD_INDEX      ( C_CTRL_AP_COL_CNT_LOAD_INDEX      ) ,
    .C_CTRL_AP_COL_CNT_ENABLE_INDEX    ( C_CTRL_AP_COL_CNT_ENABLE_INDEX    ) ,
    .C_CTRL_AP_PRECHARGE_ADDR10_INDEX  ( C_CTRL_AP_PRECHARGE_ADDR10_INDEX  ) ,
    .C_CTRL_AP_ROW_COL_SEL_INDEX       ( C_CTRL_AP_ROW_COL_SEL_INDEX       ) ,
    .C_CTRL_PHYIF_FORCE_DM_INDEX       ( C_CTRL_PHYIF_FORCE_DM_INDEX       ) ,
    .C_CTRL_REPEAT4_INDEX              ( C_CTRL_REPEAT4_INDEX              ) ,
    .C_CTRL_DFI_RAS_N_0_INDEX          ( C_CTRL_DFI_RAS_N_0_INDEX          ) ,
    .C_CTRL_DFI_CAS_N_0_INDEX          ( C_CTRL_DFI_CAS_N_0_INDEX          ) ,
    .C_CTRL_DFI_WE_N_0_INDEX           ( C_CTRL_DFI_WE_N_0_INDEX           ) ,
    .C_CTRL_DFI_RAS_N_1_INDEX          ( C_CTRL_DFI_RAS_N_1_INDEX          ) ,
    .C_CTRL_DFI_CAS_N_1_INDEX          ( C_CTRL_DFI_CAS_N_1_INDEX          ) ,
    .C_CTRL_DFI_WE_N_1_INDEX           ( C_CTRL_DFI_WE_N_1_INDEX           ) ,
    .C_CTRL_DP_WRFIFO_POP_INDEX        ( C_CTRL_DP_WRFIFO_POP_INDEX        ) ,
    .C_CTRL_DFI_WRDATA_EN_INDEX        ( C_CTRL_DFI_WRDATA_EN_INDEX        ) ,
    .C_CTRL_DFI_RDDATA_EN_INDEX        ( C_CTRL_DFI_RDDATA_EN_INDEX        ) ,
    .C_CTRL_AP_OTF_ADDR12_INDEX        ( C_CTRL_AP_OTF_ADDR12_INDEX        ) ,
    .C_CTRL_ARB_RDMODWR_DELAY          ( C_CTRL_ARB_RDMODWR_DELAY          ) ,
    .C_CTRL_AP_COL_DELAY               ( C_CTRL_AP_COL_DELAY               ) ,
    .C_CTRL_AP_PI_ADDR_CE_DELAY        ( C_CTRL_AP_PI_ADDR_CE_DELAY        ) ,
    .C_CTRL_AP_PORT_SELECT_DELAY       ( C_CTRL_AP_PORT_SELECT_DELAY       ) ,
    .C_CTRL_AP_PIPELINE1_CE_DELAY      ( C_CTRL_AP_PIPELINE1_CE_DELAY      ) ,
    .C_CTRL_DP_LOAD_RDWDADDR_DELAY     ( C_CTRL_DP_LOAD_RDWDADDR_DELAY     ) ,
    .C_CTRL_DP_RDFIFO_WHICHPORT_DELAY  ( C_CTRL_DP_RDFIFO_WHICHPORT_DELAY  ) ,
    .C_CTRL_DP_SIZE_DELAY              ( C_CTRL_DP_SIZE_DELAY              ) ,
    .C_CTRL_DP_WRFIFO_WHICHPORT_DELAY  ( C_CTRL_DP_WRFIFO_WHICHPORT_DELAY  ) ,
    .C_CTRL_PHYIF_DUMMYREADSTART_DELAY ( C_CTRL_PHYIF_DUMMYREADSTART_DELAY ) ,
    .C_CTRL_Q0_DELAY                   ( C_CTRL_Q0_DELAY                   ) ,
    .C_CTRL_Q1_DELAY                   ( C_CTRL_Q1_DELAY                   ) ,
    .C_CTRL_Q2_DELAY                   ( C_CTRL_Q2_DELAY                   ) ,
    .C_CTRL_Q3_DELAY                   ( C_CTRL_Q3_DELAY                   ) ,
    .C_CTRL_Q4_DELAY                   ( C_CTRL_Q4_DELAY                   ) ,
    .C_CTRL_Q5_DELAY                   ( C_CTRL_Q5_DELAY                   ) ,
    .C_CTRL_Q6_DELAY                   ( C_CTRL_Q6_DELAY                   ) ,
    .C_CTRL_Q7_DELAY                   ( C_CTRL_Q7_DELAY                   ) ,
    .C_CTRL_Q8_DELAY                   ( C_CTRL_Q8_DELAY                   ) ,
    .C_CTRL_Q9_DELAY                   ( C_CTRL_Q9_DELAY                   ) ,
    .C_CTRL_Q10_DELAY                  ( C_CTRL_Q10_DELAY                  ) ,
    .C_CTRL_Q11_DELAY                  ( C_CTRL_Q11_DELAY                  ) ,
    .C_CTRL_Q12_DELAY                  ( C_CTRL_Q12_DELAY                  ) ,
    .C_CTRL_Q13_DELAY                  ( C_CTRL_Q13_DELAY                  ) ,
    .C_CTRL_Q14_DELAY                  ( C_CTRL_Q14_DELAY                  ) ,
    .C_CTRL_Q15_DELAY                  ( C_CTRL_Q15_DELAY                  ) ,
    .C_CTRL_Q16_DELAY                  ( C_CTRL_Q16_DELAY                  ) ,
    .C_CTRL_Q17_DELAY                  ( C_CTRL_Q17_DELAY                  ) ,
    .C_CTRL_Q18_DELAY                  ( C_CTRL_Q18_DELAY                  ) ,
    .C_CTRL_Q19_DELAY                  ( C_CTRL_Q19_DELAY                  ) ,
    .C_CTRL_Q20_DELAY                  ( C_CTRL_Q20_DELAY                  ) ,
    .C_CTRL_Q21_DELAY                  ( C_CTRL_Q21_DELAY                  ) ,
    .C_CTRL_Q22_DELAY                  ( C_CTRL_Q22_DELAY                  ) ,
    .C_CTRL_Q23_DELAY                  ( C_CTRL_Q23_DELAY                  ) ,
    .C_CTRL_Q24_DELAY                  ( C_CTRL_Q24_DELAY                  ) ,
    .C_CTRL_Q25_DELAY                  ( C_CTRL_Q25_DELAY                  ) ,
    .C_CTRL_Q26_DELAY                  ( C_CTRL_Q26_DELAY                  ) ,
    .C_CTRL_Q27_DELAY                  ( C_CTRL_Q27_DELAY                  ) ,
    .C_CTRL_Q28_DELAY                  ( C_CTRL_Q28_DELAY                  ) ,
    .C_CTRL_Q29_DELAY                  ( C_CTRL_Q29_DELAY                  ) ,
    .C_CTRL_Q30_DELAY                  ( C_CTRL_Q30_DELAY                  ) ,
    .C_CTRL_Q31_DELAY                  ( C_CTRL_Q31_DELAY                  ) ,
    .C_CTRL_Q32_DELAY                  ( C_CTRL_Q32_DELAY                  ) ,
    .C_CTRL_Q33_DELAY                  ( C_CTRL_Q33_DELAY                  ) ,
    .C_CTRL_Q34_DELAY                  ( C_CTRL_Q34_DELAY                  ) ,
    .C_CTRL_Q35_DELAY                  ( C_CTRL_Q35_DELAY                  ) ,
    .C_ARB0_ALGO                       ( C_ARB0_ALGO                       ) ,
    .C_BASEADDR_ARB0                   ( P_BASEADDR_ARB0                   ) ,
    .C_HIGHADDR_ARB0                   ( P_HIGHADDR_ARB0                   ) ,
    .C_BASEADDR_ARB1                   ( P_BASEADDR_ARB1                   ) ,
    .C_HIGHADDR_ARB1                   ( P_HIGHADDR_ARB1                   ) ,
    .C_BASEADDR_ARB2                   ( P_BASEADDR_ARB2                   ) ,
    .C_HIGHADDR_ARB2                   ( P_HIGHADDR_ARB2                   ) ,
    .C_BASEADDR_ARB3                   ( P_BASEADDR_ARB3                   ) ,
    .C_HIGHADDR_ARB3                   ( P_HIGHADDR_ARB3                   ) ,
    .C_BASEADDR_ARB4                   ( P_BASEADDR_ARB4                   ) ,
    .C_HIGHADDR_ARB4                   ( P_HIGHADDR_ARB4                   ) ,
    .C_BASEADDR_ARB5                   ( P_BASEADDR_ARB5                   ) ,
    .C_HIGHADDR_ARB5                   ( P_HIGHADDR_ARB5                   ) ,
    .C_BASEADDR_ARB6                   ( P_BASEADDR_ARB6                   ) ,
    .C_HIGHADDR_ARB6                   ( P_HIGHADDR_ARB6                   ) ,
    .C_BASEADDR_ARB7                   ( P_BASEADDR_ARB7                   ) ,
    .C_HIGHADDR_ARB7                   ( P_HIGHADDR_ARB7                   ) ,
    .C_BASEADDR_ARB8                   ( P_BASEADDR_ARB8                   ) ,
    .C_HIGHADDR_ARB8                   ( P_HIGHADDR_ARB8                   ) ,
    .C_BASEADDR_ARB9                   ( P_BASEADDR_ARB9                   ) ,
    .C_HIGHADDR_ARB9                   ( P_HIGHADDR_ARB9                   ) ,
    .C_BASEADDR_ARB10                  ( P_BASEADDR_ARB10                  ) ,
    .C_HIGHADDR_ARB10                  ( P_HIGHADDR_ARB10                  ) ,
    .C_BASEADDR_ARB11                  ( P_BASEADDR_ARB11                  ) ,
    .C_HIGHADDR_ARB11                  ( P_HIGHADDR_ARB11                  ) ,
    .C_BASEADDR_ARB12                  ( P_BASEADDR_ARB12                  ) ,
    .C_HIGHADDR_ARB12                  ( P_HIGHADDR_ARB12                  ) ,
    .C_BASEADDR_ARB13                  ( P_BASEADDR_ARB13                  ) ,
    .C_HIGHADDR_ARB13                  ( P_HIGHADDR_ARB13                  ) ,
    .C_BASEADDR_ARB14                  ( P_BASEADDR_ARB14                  ) ,
    .C_HIGHADDR_ARB14                  ( P_HIGHADDR_ARB14                  ) ,
    .C_BASEADDR_ARB15                  ( P_BASEADDR_ARB15                  ) ,
    .C_HIGHADDR_ARB15                  ( P_HIGHADDR_ARB15                  ) ,
    .C_ARB_BRAM_SRVAL_A                ( P_ARB_BRAM_SRVAL_A                ) ,
    .C_ARB_BRAM_SRVAL_B                ( P_ARB_BRAM_SRVAL_B                ) ,
    .C_ARB_BRAM_INIT_00                ( C_ARB_BRAM_INIT_00                ) ,
    .C_ARB_BRAM_INIT_01                ( C_ARB_BRAM_INIT_01                ) ,
    .C_ARB_BRAM_INIT_02                ( C_ARB_BRAM_INIT_02                ) ,
    .C_ARB_BRAM_INIT_03                ( C_ARB_BRAM_INIT_03                ) ,
    .C_ARB_BRAM_INIT_04                ( C_ARB_BRAM_INIT_04                ) ,
    .C_ARB_BRAM_INIT_05                ( C_ARB_BRAM_INIT_05                ) ,
    .C_ARB_BRAM_INIT_06                ( C_ARB_BRAM_INIT_06                ) ,
    .C_ARB_BRAM_INIT_07                ( C_ARB_BRAM_INIT_07                ) ,
    .C_ARB_BRAM_INIT_08                ( P_ARB_BRAM_INIT_08                ) ,
    .C_ARB_BRAM_INIT_09                ( P_ARB_BRAM_INIT_09                ) ,
    .C_ARB_BRAM_INIT_0A                ( P_ARB_BRAM_INIT_0A                ) ,
    .C_ARB_BRAM_INIT_0B                ( P_ARB_BRAM_INIT_0B                ) ,
    .C_ARB_BRAM_INIT_0C                ( P_ARB_BRAM_INIT_0C                ) ,
    .C_ARB_BRAM_INIT_0D                ( P_ARB_BRAM_INIT_0D                ) ,
    .C_ARB_BRAM_INIT_0E                ( P_ARB_BRAM_INIT_0E                ) ,
    .C_ARB_BRAM_INIT_0F                ( P_ARB_BRAM_INIT_0F                ) ,
    .C_ARB_BRAM_INIT_10                ( P_ARB_BRAM_INIT_10                ) ,
    .C_ARB_BRAM_INIT_11                ( P_ARB_BRAM_INIT_11                ) ,
    .C_ARB_BRAM_INIT_12                ( P_ARB_BRAM_INIT_12                ) ,
    .C_ARB_BRAM_INIT_13                ( P_ARB_BRAM_INIT_13                ) ,
    .C_ARB_BRAM_INIT_14                ( P_ARB_BRAM_INIT_14                ) ,
    .C_ARB_BRAM_INIT_15                ( P_ARB_BRAM_INIT_15                ) ,
    .C_ARB_BRAM_INIT_16                ( P_ARB_BRAM_INIT_16                ) ,
    .C_ARB_BRAM_INIT_17                ( P_ARB_BRAM_INIT_17                ) ,
    .C_ARB_BRAM_INIT_18                ( P_ARB_BRAM_INIT_18                ) ,
    .C_ARB_BRAM_INIT_19                ( P_ARB_BRAM_INIT_19                ) ,
    .C_ARB_BRAM_INIT_1A                ( P_ARB_BRAM_INIT_1A                ) ,
    .C_ARB_BRAM_INIT_1B                ( P_ARB_BRAM_INIT_1B                ) ,
    .C_ARB_BRAM_INIT_1C                ( P_ARB_BRAM_INIT_1C                ) ,
    .C_ARB_BRAM_INIT_1D                ( P_ARB_BRAM_INIT_1D                ) ,
    .C_ARB_BRAM_INIT_1E                ( P_ARB_BRAM_INIT_1E                ) ,
    .C_ARB_BRAM_INIT_1F                ( P_ARB_BRAM_INIT_1F                ) ,
    .C_ARB_BRAM_INIT_20                ( P_ARB_BRAM_INIT_20                ) ,
    .C_ARB_BRAM_INIT_21                ( P_ARB_BRAM_INIT_21                ) ,
    .C_ARB_BRAM_INIT_22                ( P_ARB_BRAM_INIT_22                ) ,
    .C_ARB_BRAM_INIT_23                ( P_ARB_BRAM_INIT_23                ) ,
    .C_ARB_BRAM_INIT_24                ( P_ARB_BRAM_INIT_24                ) ,
    .C_ARB_BRAM_INIT_25                ( P_ARB_BRAM_INIT_25                ) ,
    .C_ARB_BRAM_INIT_26                ( P_ARB_BRAM_INIT_26                ) ,
    .C_ARB_BRAM_INIT_27                ( P_ARB_BRAM_INIT_27                ) ,
    .C_ARB_BRAM_INIT_28                ( P_ARB_BRAM_INIT_28                ) ,
    .C_ARB_BRAM_INIT_29                ( P_ARB_BRAM_INIT_29                ) ,
    .C_ARB_BRAM_INIT_2A                ( P_ARB_BRAM_INIT_2A                ) ,
    .C_ARB_BRAM_INIT_2B                ( P_ARB_BRAM_INIT_2B                ) ,
    .C_ARB_BRAM_INIT_2C                ( P_ARB_BRAM_INIT_2C                ) ,
    .C_ARB_BRAM_INIT_2D                ( P_ARB_BRAM_INIT_2D                ) ,
    .C_ARB_BRAM_INIT_2E                ( P_ARB_BRAM_INIT_2E                ) ,
    .C_ARB_BRAM_INIT_2F                ( P_ARB_BRAM_INIT_2F                ) ,
    .C_ARB_BRAM_INIT_30                ( P_ARB_BRAM_INIT_30                ) ,
    .C_ARB_BRAM_INIT_31                ( P_ARB_BRAM_INIT_31                ) ,
    .C_ARB_BRAM_INIT_32                ( P_ARB_BRAM_INIT_32                ) ,
    .C_ARB_BRAM_INIT_33                ( P_ARB_BRAM_INIT_33                ) ,
    .C_ARB_BRAM_INIT_34                ( P_ARB_BRAM_INIT_34                ) ,
    .C_ARB_BRAM_INIT_35                ( P_ARB_BRAM_INIT_35                ) ,
    .C_ARB_BRAM_INIT_36                ( P_ARB_BRAM_INIT_36                ) ,
    .C_ARB_BRAM_INIT_37                ( P_ARB_BRAM_INIT_37                ) ,
    .C_ARB_BRAM_INIT_38                ( P_ARB_BRAM_INIT_38                ) ,
    .C_ARB_BRAM_INIT_39                ( P_ARB_BRAM_INIT_39                ) ,
    .C_ARB_BRAM_INIT_3A                ( P_ARB_BRAM_INIT_3A                ) ,
    .C_ARB_BRAM_INIT_3B                ( P_ARB_BRAM_INIT_3B                ) ,
    .C_ARB_BRAM_INIT_3C                ( P_ARB_BRAM_INIT_3C                ) ,
    .C_ARB_BRAM_INIT_3D                ( P_ARB_BRAM_INIT_3D                ) ,
    .C_ARB_BRAM_INIT_3E                ( P_ARB_BRAM_INIT_3E                ) ,
    .C_ARB_BRAM_INIT_3F                ( P_ARB_BRAM_INIT_3F                ) ,
    .C_ARB_BRAM_INITP_00               ( P_ARB_BRAM_INITP_00               ) ,
    .C_ARB_BRAM_INITP_01               ( P_ARB_BRAM_INITP_01               ) ,
    .C_ARB_BRAM_INITP_02               ( P_ARB_BRAM_INITP_02               ) ,
    .C_ARB_BRAM_INITP_03               ( P_ARB_BRAM_INITP_03               ) ,
    .C_ARB_BRAM_INITP_04               ( P_ARB_BRAM_INITP_04               ) ,
    .C_ARB_BRAM_INITP_05               ( P_ARB_BRAM_INITP_05               ) ,
    .C_ARB_BRAM_INITP_06               ( P_ARB_BRAM_INITP_06               ) ,
    .C_ARB_BRAM_INITP_07               ( P_ARB_BRAM_INITP_07               ) ,
    .C_USE_FIXED_BASEADDR_CTRL         ( P_USE_FIXED_BASEADDR_CTRL         ) ,
    .C_SKIP_1_VALUE                    ( C_SKIP_1_VALUE                    ) ,
    .C_SKIP_2_VALUE                    ( C_SKIP_2_VALUE                    ) ,
    .C_SKIP_3_VALUE                    ( C_SKIP_3_VALUE                    ) ,
    .C_SKIP_4_VALUE                    ( C_SKIP_4_VALUE                    ) ,
    .C_SKIP_5_VALUE                    ( C_SKIP_5_VALUE                    ) ,
    .C_SKIP_6_VALUE                    ( C_SKIP_6_VALUE                    ) ,
    .C_SKIP_7_VALUE                    ( C_SKIP_7_VALUE                    ) ,
    .C_B16_REPEAT_CNT                  ( C_B16_REPEAT_CNT                  ) ,
    .C_B32_REPEAT_CNT                  ( C_B32_REPEAT_CNT                  ) ,
    .C_B64_REPEAT_CNT                  ( C_B64_REPEAT_CNT                  ) ,
    .C_ZQCS_REPEAT_CNT                 ( C_ZQCS_REPEAT_CNT                 ) ,
    .C_BASEADDR_CTRL0                  ( C_BASEADDR_CTRL0                  ) ,
    .C_HIGHADDR_CTRL0                  ( C_HIGHADDR_CTRL0                  ) ,
    .C_BASEADDR_CTRL1                  ( C_BASEADDR_CTRL1                  ) ,
    .C_HIGHADDR_CTRL1                  ( C_HIGHADDR_CTRL1                  ) ,
    .C_BASEADDR_CTRL2                  ( C_BASEADDR_CTRL2                  ) ,
    .C_HIGHADDR_CTRL2                  ( C_HIGHADDR_CTRL2                  ) ,
    .C_BASEADDR_CTRL3                  ( C_BASEADDR_CTRL3                  ) ,
    .C_HIGHADDR_CTRL3                  ( C_HIGHADDR_CTRL3                  ) ,
    .C_BASEADDR_CTRL4                  ( C_BASEADDR_CTRL4                  ) ,
    .C_HIGHADDR_CTRL4                  ( C_HIGHADDR_CTRL4                  ) ,
    .C_BASEADDR_CTRL5                  ( C_BASEADDR_CTRL5                  ) ,
    .C_HIGHADDR_CTRL5                  ( C_HIGHADDR_CTRL5                  ) ,
    .C_BASEADDR_CTRL6                  ( C_BASEADDR_CTRL6                  ) ,
    .C_HIGHADDR_CTRL6                  ( C_HIGHADDR_CTRL6                  ) ,
    .C_BASEADDR_CTRL7                  ( C_BASEADDR_CTRL7                  ) ,
    .C_HIGHADDR_CTRL7                  ( C_HIGHADDR_CTRL7                  ) ,
    .C_BASEADDR_CTRL8                  ( C_BASEADDR_CTRL8                  ) ,
    .C_HIGHADDR_CTRL8                  ( C_HIGHADDR_CTRL8                  ) ,
    .C_BASEADDR_CTRL9                  ( C_BASEADDR_CTRL9                  ) ,
    .C_HIGHADDR_CTRL9                  ( C_HIGHADDR_CTRL9                  ) ,
    .C_BASEADDR_CTRL10                 ( C_BASEADDR_CTRL10                 ) ,
    .C_HIGHADDR_CTRL10                 ( C_HIGHADDR_CTRL10                 ) ,
    .C_BASEADDR_CTRL11                 ( C_BASEADDR_CTRL11                 ) ,
    .C_HIGHADDR_CTRL11                 ( C_HIGHADDR_CTRL11                 ) ,
    .C_BASEADDR_CTRL12                 ( C_BASEADDR_CTRL12                 ) ,
    .C_HIGHADDR_CTRL12                 ( C_HIGHADDR_CTRL12                 ) ,
    .C_BASEADDR_CTRL13                 ( C_BASEADDR_CTRL13                 ) ,
    .C_HIGHADDR_CTRL13                 ( C_HIGHADDR_CTRL13                 ) ,
    .C_BASEADDR_CTRL14                 ( C_BASEADDR_CTRL14                 ) ,
    .C_HIGHADDR_CTRL14                 ( C_HIGHADDR_CTRL14                 ) ,
    .C_BASEADDR_CTRL15                 ( C_BASEADDR_CTRL15                 ) ,
    .C_HIGHADDR_CTRL15                 ( C_HIGHADDR_CTRL15                 ) ,
    .C_BASEADDR_CTRL16                 ( C_BASEADDR_CTRL16                 ) ,
    .C_HIGHADDR_CTRL16                 ( C_HIGHADDR_CTRL16                 ) ,
    .C_CTRL_BRAM_SRVAL                 ( C_CTRL_BRAM_SRVAL                 ) ,
    .C_CTRL_BRAM_INIT_00               ( C_CTRL_BRAM_INIT_00               ) ,
    .C_CTRL_BRAM_INIT_01               ( C_CTRL_BRAM_INIT_01               ) ,
    .C_CTRL_BRAM_INIT_02               ( C_CTRL_BRAM_INIT_02               ) ,
    .C_CTRL_BRAM_INIT_03               ( C_CTRL_BRAM_INIT_03               ) ,
    .C_CTRL_BRAM_INIT_04               ( C_CTRL_BRAM_INIT_04               ) ,
    .C_CTRL_BRAM_INIT_05               ( C_CTRL_BRAM_INIT_05               ) ,
    .C_CTRL_BRAM_INIT_06               ( C_CTRL_BRAM_INIT_06               ) ,
    .C_CTRL_BRAM_INIT_07               ( C_CTRL_BRAM_INIT_07               ) ,
    .C_CTRL_BRAM_INIT_08               ( C_CTRL_BRAM_INIT_08               ) ,
    .C_CTRL_BRAM_INIT_09               ( C_CTRL_BRAM_INIT_09               ) ,
    .C_CTRL_BRAM_INIT_0A               ( C_CTRL_BRAM_INIT_0A               ) ,
    .C_CTRL_BRAM_INIT_0B               ( C_CTRL_BRAM_INIT_0B               ) ,
    .C_CTRL_BRAM_INIT_0C               ( C_CTRL_BRAM_INIT_0C               ) ,
    .C_CTRL_BRAM_INIT_0D               ( C_CTRL_BRAM_INIT_0D               ) ,
    .C_CTRL_BRAM_INIT_0E               ( C_CTRL_BRAM_INIT_0E               ) ,
    .C_CTRL_BRAM_INIT_0F               ( C_CTRL_BRAM_INIT_0F               ) ,
    .C_CTRL_BRAM_INIT_10               ( C_CTRL_BRAM_INIT_10               ) ,
    .C_CTRL_BRAM_INIT_11               ( C_CTRL_BRAM_INIT_11               ) ,
    .C_CTRL_BRAM_INIT_12               ( C_CTRL_BRAM_INIT_12               ) ,
    .C_CTRL_BRAM_INIT_13               ( C_CTRL_BRAM_INIT_13               ) ,
    .C_CTRL_BRAM_INIT_14               ( C_CTRL_BRAM_INIT_14               ) ,
    .C_CTRL_BRAM_INIT_15               ( C_CTRL_BRAM_INIT_15               ) ,
    .C_CTRL_BRAM_INIT_16               ( C_CTRL_BRAM_INIT_16               ) ,
    .C_CTRL_BRAM_INIT_17               ( C_CTRL_BRAM_INIT_17               ) ,
    .C_CTRL_BRAM_INIT_18               ( C_CTRL_BRAM_INIT_18               ) ,
    .C_CTRL_BRAM_INIT_19               ( C_CTRL_BRAM_INIT_19               ) ,
    .C_CTRL_BRAM_INIT_1A               ( C_CTRL_BRAM_INIT_1A               ) ,
    .C_CTRL_BRAM_INIT_1B               ( C_CTRL_BRAM_INIT_1B               ) ,
    .C_CTRL_BRAM_INIT_1C               ( C_CTRL_BRAM_INIT_1C               ) ,
    .C_CTRL_BRAM_INIT_1D               ( C_CTRL_BRAM_INIT_1D               ) ,
    .C_CTRL_BRAM_INIT_1E               ( C_CTRL_BRAM_INIT_1E               ) ,
    .C_CTRL_BRAM_INIT_1F               ( C_CTRL_BRAM_INIT_1F               ) ,
    .C_CTRL_BRAM_INIT_20               ( C_CTRL_BRAM_INIT_20               ) ,
    .C_CTRL_BRAM_INIT_21               ( C_CTRL_BRAM_INIT_21               ) ,
    .C_CTRL_BRAM_INIT_22               ( C_CTRL_BRAM_INIT_22               ) ,
    .C_CTRL_BRAM_INIT_23               ( C_CTRL_BRAM_INIT_23               ) ,
    .C_CTRL_BRAM_INIT_24               ( C_CTRL_BRAM_INIT_24               ) ,
    .C_CTRL_BRAM_INIT_25               ( C_CTRL_BRAM_INIT_25               ) ,
    .C_CTRL_BRAM_INIT_26               ( C_CTRL_BRAM_INIT_26               ) ,
    .C_CTRL_BRAM_INIT_27               ( C_CTRL_BRAM_INIT_27               ) ,
    .C_CTRL_BRAM_INIT_28               ( C_CTRL_BRAM_INIT_28               ) ,
    .C_CTRL_BRAM_INIT_29               ( C_CTRL_BRAM_INIT_29               ) ,
    .C_CTRL_BRAM_INIT_2A               ( C_CTRL_BRAM_INIT_2A               ) ,
    .C_CTRL_BRAM_INIT_2B               ( C_CTRL_BRAM_INIT_2B               ) ,
    .C_CTRL_BRAM_INIT_2C               ( C_CTRL_BRAM_INIT_2C               ) ,
    .C_CTRL_BRAM_INIT_2D               ( C_CTRL_BRAM_INIT_2D               ) ,
    .C_CTRL_BRAM_INIT_2E               ( C_CTRL_BRAM_INIT_2E               ) ,
    .C_CTRL_BRAM_INIT_2F               ( C_CTRL_BRAM_INIT_2F               ) ,
    .C_CTRL_BRAM_INIT_30               ( C_CTRL_BRAM_INIT_30               ) ,
    .C_CTRL_BRAM_INIT_31               ( C_CTRL_BRAM_INIT_31               ) ,
    .C_CTRL_BRAM_INIT_32               ( C_CTRL_BRAM_INIT_32               ) ,
    .C_CTRL_BRAM_INIT_33               ( C_CTRL_BRAM_INIT_33               ) ,
    .C_CTRL_BRAM_INIT_34               ( C_CTRL_BRAM_INIT_34               ) ,
    .C_CTRL_BRAM_INIT_35               ( C_CTRL_BRAM_INIT_35               ) ,
    .C_CTRL_BRAM_INIT_36               ( C_CTRL_BRAM_INIT_36               ) ,
    .C_CTRL_BRAM_INIT_37               ( C_CTRL_BRAM_INIT_37               ) ,
    .C_CTRL_BRAM_INIT_38               ( C_CTRL_BRAM_INIT_38               ) ,
    .C_CTRL_BRAM_INIT_39               ( C_CTRL_BRAM_INIT_39               ) ,
    .C_CTRL_BRAM_INIT_3A               ( C_CTRL_BRAM_INIT_3A               ) ,
    .C_CTRL_BRAM_INIT_3B               ( C_CTRL_BRAM_INIT_3B               ) ,
    .C_CTRL_BRAM_INIT_3C               ( C_CTRL_BRAM_INIT_3C               ) ,
    .C_CTRL_BRAM_INIT_3D               ( C_CTRL_BRAM_INIT_3D               ) ,
    .C_CTRL_BRAM_INIT_3E               ( C_CTRL_BRAM_INIT_3E               ) ,
    .C_CTRL_BRAM_INIT_3F               ( C_CTRL_BRAM_INIT_3F               ) ,
    .C_CTRL_BRAM_INITP_00              ( C_CTRL_BRAM_INITP_00              ) ,
    .C_CTRL_BRAM_INITP_01              ( C_CTRL_BRAM_INITP_01              ) ,
    .C_CTRL_BRAM_INITP_02              ( C_CTRL_BRAM_INITP_02              ) ,
    .C_CTRL_BRAM_INITP_03              ( C_CTRL_BRAM_INITP_03              ) ,
    .C_CTRL_BRAM_INITP_04              ( C_CTRL_BRAM_INITP_04              ) ,
    .C_CTRL_BRAM_INITP_05              ( C_CTRL_BRAM_INITP_05              ) ,
    .C_CTRL_BRAM_INITP_06              ( C_CTRL_BRAM_INITP_06              ) ,
    .C_CTRL_BRAM_INITP_07              ( C_CTRL_BRAM_INITP_07              ) ,

    // PIM parameters
    // Port 0
    .C_PIM0_BASETYPE                   ( C_PIM0_BASETYPE                   ) ,
    .C_PI0_ADDR_WIDTH                  ( P_PIM0_ADDR_WIDTH                 ) ,
    .C_PI0_DATA_WIDTH                  ( C_PIM0_DATA_WIDTH                 ) ,
    .C_PI0_BE_WIDTH                    ( C_PIM0_DATA_WIDTH/8               ) ,
    .C_PI0_RDWDADDR_WIDTH              ( P_PIM0_RDWDADDR_WIDTH             ) ,
    // Port 1
    .C_PIM1_BASETYPE                   ( C_PIM1_BASETYPE                   ) ,
    .C_PI1_ADDR_WIDTH                  ( P_PIM1_ADDR_WIDTH                 ) ,
    .C_PI1_DATA_WIDTH                  ( C_PIM1_DATA_WIDTH                 ) ,
    .C_PI1_BE_WIDTH                    ( C_PIM1_DATA_WIDTH/8               ) ,
    .C_PI1_RDWDADDR_WIDTH              ( P_PIM1_RDWDADDR_WIDTH             ) ,
    // Port 2
    .C_PIM2_BASETYPE                   ( C_PIM2_BASETYPE                   ) ,
    .C_PI2_ADDR_WIDTH                  ( P_PIM2_ADDR_WIDTH                 ) ,
    .C_PI2_DATA_WIDTH                  ( C_PIM2_DATA_WIDTH                 ) ,
    .C_PI2_BE_WIDTH                    ( C_PIM2_DATA_WIDTH/8               ) ,
    .C_PI2_RDWDADDR_WIDTH              ( P_PIM2_RDWDADDR_WIDTH             ) ,
    // Port 3
    .C_PIM3_BASETYPE                   ( C_PIM3_BASETYPE                   ) ,
    .C_PI3_ADDR_WIDTH                  ( P_PIM3_ADDR_WIDTH                 ) ,
    .C_PI3_DATA_WIDTH                  ( C_PIM3_DATA_WIDTH                 ) ,
    .C_PI3_BE_WIDTH                    ( C_PIM3_DATA_WIDTH/8               ) ,
    .C_PI3_RDWDADDR_WIDTH              ( P_PIM3_RDWDADDR_WIDTH             ) ,
    // Port 4
    .C_PIM4_BASETYPE                   ( C_PIM4_BASETYPE                   ) ,
    .C_PI4_ADDR_WIDTH                  ( P_PIM4_ADDR_WIDTH                 ) ,
    .C_PI4_DATA_WIDTH                  ( C_PIM4_DATA_WIDTH                 ) ,
    .C_PI4_BE_WIDTH                    ( C_PIM4_DATA_WIDTH/8               ) ,
    .C_PI4_RDWDADDR_WIDTH              ( P_PIM4_RDWDADDR_WIDTH             ) ,
    // Port 5
    .C_PIM5_BASETYPE                   ( C_PIM5_BASETYPE                   ) ,
    .C_PI5_ADDR_WIDTH                  ( P_PIM5_ADDR_WIDTH                 ) ,
    .C_PI5_DATA_WIDTH                  ( C_PIM5_DATA_WIDTH                 ) ,
    .C_PI5_BE_WIDTH                    ( C_PIM5_DATA_WIDTH/8               ) ,
    .C_PI5_RDWDADDR_WIDTH              ( P_PIM5_RDWDADDR_WIDTH             ) ,
    // Port 6
    .C_PI6_ADDR_WIDTH                  ( P_PIM6_ADDR_WIDTH                 ) ,
    .C_PI6_DATA_WIDTH                  ( C_PIM6_DATA_WIDTH                 ) ,
    .C_PI6_BE_WIDTH                    ( C_PIM6_DATA_WIDTH/8               ) ,
    .C_PI6_RDWDADDR_WIDTH              ( P_PIM6_RDWDADDR_WIDTH             ) ,
    // Port 7
    .C_PI7_ADDR_WIDTH                  ( P_PIM7_ADDR_WIDTH                 ) ,
    .C_PI7_DATA_WIDTH                  ( C_PIM7_DATA_WIDTH                 ) ,
    .C_PI7_BE_WIDTH                    ( C_PIM7_DATA_WIDTH/8               ) ,
    .C_PI7_RDWDADDR_WIDTH              ( P_PIM7_RDWDADDR_WIDTH             ) ,
    .C_TBY4TAPVALUE                    ( P_TBY4TAPVALUE                    )
  )
  mpmc_core_0
  (
    // System Signals
    .Clk0                     ( MPMC_Clk0             ) ,
    .Clk0_DIV2                ( MPMC_Clk0_DIV2        ) ,
    .Clk90                    ( MPMC_Clk90            ) ,
    .Clk_200MHz               ( MPMC_Clk_200MHz       ) ,
    .Clk_Mem                  ( MPMC_Clk_Mem          ) ,
    .Clk_Mem_2x               ( MPMC_Clk_Mem_2x       ) ,
    .Clk_Mem_2x_180           ( MPMC_Clk_Mem_2x_180   ) ,
    .Clk_Mem_2x_CE0           ( MPMC_Clk_Mem_2x_CE0   ) ,
    .Clk_Mem_2x_CE90          ( MPMC_Clk_Mem_2x_CE90  ) ,
    .Clk_Mem_2x_bufpll_o      ( MPMC_Clk_Mem_2x_bufpll_o       ) ,
    .Clk_Mem_2x_180_bufpll_o  ( MPMC_Clk_Mem_2x_180_bufpll_o   ) ,
    .Clk_Mem_2x_CE0_bufpll_o  ( MPMC_Clk_Mem_2x_CE0_bufpll_o   ) ,
    .Clk_Mem_2x_CE90_bufpll_o ( MPMC_Clk_Mem_2x_CE90_bufpll_o  ) ,
    .Clk_Rd_Base              ( MPMC_Clk_Rd_Base        ) ,
    .pll_locked               ( MPMC_PLL_Lock         ) ,
    .pll_lock                 ( MPMC_PLL_Lock_bufpll_o) ,
    .InitDone                 ( MPMC_InitDone         ) ,
    .Rst                      ( Rst_tocore            ) ,
    .Rst90                    ( Rst90                 ) ,
    .Rst270                   ( Rst270                ) ,
    .ECC_Intr                 ( MPMC_ECC_Intr         ) ,
    .DCM_PSEN                 ( MPMC_DCM_PSEN         ) ,
    .DCM_PSINCDEC             ( MPMC_DCM_PSINCDEC     ) ,
    .DCM_PSDONE               ( MPMC_DCM_PSDONE       ) ,
    .MCB_DRP_Clk              ( MPMC_MCB_DRP_Clk      ) ,
    .Idelayctrl_Rdy_I         ( MPMC_Idelayctrl_Rdy_I ) ,
    .Idelayctrl_Rdy_O         ( MPMC_Idelayctrl_Rdy_O ) ,
    // SDRAM/DDR/DDR2 Memory Interface Signals
    .Mem_Clk_O                ( MEM_Clk               ) ,
    .Mem_Clk_n_O              ( MEM_Clk_n             ) ,
    .Mem_CE_O                 ( MEM_CE                ) ,
    .Mem_CS_n_O               ( MEM_CS_n              ) ,
    .Mem_ODT_O                ( MEM_ODT               ) ,
    .Mem_RAS_n_O              ( MEM_RAS_n             ) ,
    .Mem_CAS_n_O              ( MEM_CAS_n             ) ,
    .Mem_WE_n_O               ( MEM_WE_n              ) ,
    .Mem_BankAddr_O           ( MEM_BankAddr          ) ,
    .Mem_Addr_O               ( MEM_Addr              ) ,
    .Mem_DM_O                 ( MEM_DM                ) ,
    .Mem_Reset_n_O            ( MEM_Reset_n           ) ,
    .Mem_DQS_Div_I            ( MEM_DQS_Div_I         ) ,
    .Mem_DQS_Div_O            ( MEM_DQS_Div_O         ) ,
    .DDR3_DQS                 ( DDR3_DQS              ) ,
    .DDR3_DQS_n               ( DDR3_DQS_n            ) ,
    .DDR3_DQ                  ( DDR3_DQ               ) ,
    .DDR2_DQS                 ( DDR2_DQS              ) ,
    .DDR2_DQS_n               ( DDR2_DQS_n            ) ,
    .DDR2_DQ                  ( DDR2_DQ               ) ,
    .DDR_DQS                  ( DDR_DQS               ) ,
    .DDR_DQ                   ( DDR_DQ                ) ,
    .SDRAM_DQ                 ( SDRAM_DQ              ) ,
    // Spartan6
    .mcbx_dram_addr           ( mcbx_dram_addr        ) ,
    .mcbx_dram_ba             ( mcbx_dram_ba          ) ,
    .mcbx_dram_ras_n          ( mcbx_dram_ras_n       ) ,
    .mcbx_dram_cas_n          ( mcbx_dram_cas_n       ) ,
    .mcbx_dram_we_n           ( mcbx_dram_we_n        ) ,
    .mcbx_dram_cke            ( mcbx_dram_cke         ) ,
    .mcbx_dram_clk            ( mcbx_dram_clk         ) ,
    .mcbx_dram_clk_n          ( mcbx_dram_clk_n       ) ,
    .mcbx_dram_dq             ( mcbx_dram_dq          ) ,
    .mcbx_dram_dqs            ( mcbx_dram_dqs         ) ,
    .mcbx_dram_dqs_n          ( mcbx_dram_dqs_n       ) ,
    .mcbx_dram_udqs           ( mcbx_dram_udqs        ) ,
    .mcbx_dram_udqs_n         ( mcbx_dram_udqs_n      ) ,
    .mcbx_dram_udm            ( mcbx_dram_udm         ) ,
    .mcbx_dram_ldm            ( mcbx_dram_ldm         ) ,
    .mcbx_dram_odt            ( mcbx_dram_odt         ) ,
    .mcbx_dram_ddr3_rst       ( mcbx_dram_ddr3_rst    ) ,
    .calib_recal              ( calib_recal           ) ,
    .selfrefresh_enter        ( 1'b0                  ) ,
    .selfrefresh_mode         ( selfrefresh_mode      ) ,
    .rzq                      ( rzq                   ) ,
    .zio                      ( zio                   ) ,
    // Native MCB signals
    .MCB0_cmd_clk             ( MCB0_cmd_clk          ) ,
    .MCB0_cmd_en              ( MCB0_cmd_en           ) ,
    .MCB0_cmd_instr           ( MCB0_cmd_instr        ) ,
    .MCB0_cmd_bl              ( MCB0_cmd_bl           ) ,
    .MCB0_cmd_byte_addr       ( MCB0_cmd_byte_addr    ) ,
    .MCB0_cmd_empty           ( MCB0_cmd_empty        ) ,
    .MCB0_cmd_full            ( MCB0_cmd_full         ) ,
    .MCB0_wr_clk              ( MCB0_wr_clk           ) ,
    .MCB0_wr_en               ( MCB0_wr_en            ) ,
    .MCB0_wr_mask             ( MCB0_wr_mask          ) ,
    .MCB0_wr_data             ( MCB0_wr_data          ) ,
    .MCB0_wr_full             ( MCB0_wr_full          ) ,
    .MCB0_wr_empty            ( MCB0_wr_empty         ) ,
    .MCB0_wr_count            ( MCB0_wr_count         ) ,
    .MCB0_wr_underrun         ( MCB0_wr_underrun      ) ,
    .MCB0_wr_error            ( MCB0_wr_error         ) ,
    .MCB0_rd_clk              ( MCB0_rd_clk           ) ,
    .MCB0_rd_en               ( MCB0_rd_en            ) ,
    .MCB0_rd_data             ( MCB0_rd_data          ) ,
    .MCB0_rd_full             ( MCB0_rd_full          ) ,
    .MCB0_rd_empty            ( MCB0_rd_empty         ) ,
    .MCB0_rd_count            ( MCB0_rd_count         ) ,
    .MCB0_rd_overflow         ( MCB0_rd_overflow      ) ,
    .MCB0_rd_error            ( MCB0_rd_error         ) ,
    .MCB1_cmd_clk             ( MCB1_cmd_clk          ) ,
    .MCB1_cmd_en              ( MCB1_cmd_en           ) ,
    .MCB1_cmd_instr           ( MCB1_cmd_instr        ) ,
    .MCB1_cmd_bl              ( MCB1_cmd_bl           ) ,
    .MCB1_cmd_byte_addr       ( MCB1_cmd_byte_addr    ) ,
    .MCB1_cmd_empty           ( MCB1_cmd_empty        ) ,
    .MCB1_cmd_full            ( MCB1_cmd_full         ) ,
    .MCB1_wr_clk              ( MCB1_wr_clk           ) ,
    .MCB1_wr_en               ( MCB1_wr_en            ) ,
    .MCB1_wr_mask             ( MCB1_wr_mask          ) ,
    .MCB1_wr_data             ( MCB1_wr_data          ) ,
    .MCB1_wr_full             ( MCB1_wr_full          ) ,
    .MCB1_wr_empty            ( MCB1_wr_empty         ) ,
    .MCB1_wr_count            ( MCB1_wr_count         ) ,
    .MCB1_wr_underrun         ( MCB1_wr_underrun      ) ,
    .MCB1_wr_error            ( MCB1_wr_error         ) ,
    .MCB1_rd_clk              ( MCB1_rd_clk           ) ,
    .MCB1_rd_en               ( MCB1_rd_en            ) ,
    .MCB1_rd_data             ( MCB1_rd_data          ) ,
    .MCB1_rd_full             ( MCB1_rd_full          ) ,
    .MCB1_rd_empty            ( MCB1_rd_empty         ) ,
    .MCB1_rd_count            ( MCB1_rd_count         ) ,
    .MCB1_rd_overflow         ( MCB1_rd_overflow      ) ,
    .MCB1_rd_error            ( MCB1_rd_error         ) ,
    .MCB2_cmd_clk             ( MCB2_cmd_clk          ) ,
    .MCB2_cmd_en              ( MCB2_cmd_en           ) ,
    .MCB2_cmd_instr           ( MCB2_cmd_instr        ) ,
    .MCB2_cmd_bl              ( MCB2_cmd_bl           ) ,
    .MCB2_cmd_byte_addr       ( MCB2_cmd_byte_addr    ) ,
    .MCB2_cmd_empty           ( MCB2_cmd_empty        ) ,
    .MCB2_cmd_full            ( MCB2_cmd_full         ) ,
    .MCB2_wr_clk              ( MCB2_wr_clk           ) ,
    .MCB2_wr_en               ( MCB2_wr_en            ) ,
    .MCB2_wr_mask             ( MCB2_wr_mask          ) ,
    .MCB2_wr_data             ( MCB2_wr_data          ) ,
    .MCB2_wr_full             ( MCB2_wr_full          ) ,
    .MCB2_wr_empty            ( MCB2_wr_empty         ) ,
    .MCB2_wr_count            ( MCB2_wr_count         ) ,
    .MCB2_wr_underrun         ( MCB2_wr_underrun      ) ,
    .MCB2_wr_error            ( MCB2_wr_error         ) ,
    .MCB2_rd_clk              ( MCB2_rd_clk           ) ,
    .MCB2_rd_en               ( MCB2_rd_en            ) ,
    .MCB2_rd_data             ( MCB2_rd_data          ) ,
    .MCB2_rd_full             ( MCB2_rd_full          ) ,
    .MCB2_rd_empty            ( MCB2_rd_empty         ) ,
    .MCB2_rd_count            ( MCB2_rd_count         ) ,
    .MCB2_rd_overflow         ( MCB2_rd_overflow      ) ,
    .MCB2_rd_error            ( MCB2_rd_error         ) ,
    .MCB3_cmd_clk             ( MCB3_cmd_clk          ) ,
    .MCB3_cmd_en              ( MCB3_cmd_en           ) ,
    .MCB3_cmd_instr           ( MCB3_cmd_instr        ) ,
    .MCB3_cmd_bl              ( MCB3_cmd_bl           ) ,
    .MCB3_cmd_byte_addr       ( MCB3_cmd_byte_addr    ) ,
    .MCB3_cmd_empty           ( MCB3_cmd_empty        ) ,
    .MCB3_cmd_full            ( MCB3_cmd_full         ) ,
    .MCB3_wr_clk              ( MCB3_wr_clk           ) ,
    .MCB3_wr_en               ( MCB3_wr_en            ) ,
    .MCB3_wr_mask             ( MCB3_wr_mask          ) ,
    .MCB3_wr_data             ( MCB3_wr_data          ) ,
    .MCB3_wr_full             ( MCB3_wr_full          ) ,
    .MCB3_wr_empty            ( MCB3_wr_empty         ) ,
    .MCB3_wr_count            ( MCB3_wr_count         ) ,
    .MCB3_wr_underrun         ( MCB3_wr_underrun      ) ,
    .MCB3_wr_error            ( MCB3_wr_error         ) ,
    .MCB3_rd_clk              ( MCB3_rd_clk           ) ,
    .MCB3_rd_en               ( MCB3_rd_en            ) ,
    .MCB3_rd_data             ( MCB3_rd_data          ) ,
    .MCB3_rd_full             ( MCB3_rd_full          ) ,
    .MCB3_rd_empty            ( MCB3_rd_empty         ) ,
    .MCB3_rd_count            ( MCB3_rd_count         ) ,
    .MCB3_rd_overflow         ( MCB3_rd_overflow      ) ,
    .MCB3_rd_error            ( MCB3_rd_error         ) ,
    .MCB4_cmd_clk             ( MCB4_cmd_clk          ) ,
    .MCB4_cmd_en              ( MCB4_cmd_en           ) ,
    .MCB4_cmd_instr           ( MCB4_cmd_instr        ) ,
    .MCB4_cmd_bl              ( MCB4_cmd_bl           ) ,
    .MCB4_cmd_byte_addr       ( MCB4_cmd_byte_addr    ) ,
    .MCB4_cmd_empty           ( MCB4_cmd_empty        ) ,
    .MCB4_cmd_full            ( MCB4_cmd_full         ) ,
    .MCB4_wr_clk              ( MCB4_wr_clk           ) ,
    .MCB4_wr_en               ( MCB4_wr_en            ) ,
    .MCB4_wr_mask             ( MCB4_wr_mask          ) ,
    .MCB4_wr_data             ( MCB4_wr_data          ) ,
    .MCB4_wr_full             ( MCB4_wr_full          ) ,
    .MCB4_wr_empty            ( MCB4_wr_empty         ) ,
    .MCB4_wr_count            ( MCB4_wr_count         ) ,
    .MCB4_wr_underrun         ( MCB4_wr_underrun      ) ,
    .MCB4_wr_error            ( MCB4_wr_error         ) ,
    .MCB4_rd_clk              ( MCB4_rd_clk           ) ,
    .MCB4_rd_en               ( MCB4_rd_en            ) ,
    .MCB4_rd_data             ( MCB4_rd_data          ) ,
    .MCB4_rd_full             ( MCB4_rd_full          ) ,
    .MCB4_rd_empty            ( MCB4_rd_empty         ) ,
    .MCB4_rd_count            ( MCB4_rd_count         ) ,
    .MCB4_rd_overflow         ( MCB4_rd_overflow      ) ,
    .MCB4_rd_error            ( MCB4_rd_error         ) ,
    .MCB5_cmd_clk             ( MCB5_cmd_clk          ) ,
    .MCB5_cmd_en              ( MCB5_cmd_en           ) ,
    .MCB5_cmd_instr           ( MCB5_cmd_instr        ) ,
    .MCB5_cmd_bl              ( MCB5_cmd_bl           ) ,
    .MCB5_cmd_byte_addr       ( MCB5_cmd_byte_addr    ) ,
    .MCB5_cmd_empty           ( MCB5_cmd_empty        ) ,
    .MCB5_cmd_full            ( MCB5_cmd_full         ) ,
    .MCB5_wr_clk              ( MCB5_wr_clk           ) ,
    .MCB5_wr_en               ( MCB5_wr_en            ) ,
    .MCB5_wr_mask             ( MCB5_wr_mask          ) ,
    .MCB5_wr_data             ( MCB5_wr_data          ) ,
    .MCB5_wr_full             ( MCB5_wr_full          ) ,
    .MCB5_wr_empty            ( MCB5_wr_empty         ) ,
    .MCB5_wr_count            ( MCB5_wr_count         ) ,
    .MCB5_wr_underrun         ( MCB5_wr_underrun      ) ,
    .MCB5_wr_error            ( MCB5_wr_error         ) ,
    .MCB5_rd_clk              ( MCB5_rd_clk           ) ,
    .MCB5_rd_en               ( MCB5_rd_en            ) ,
    .MCB5_rd_data             ( MCB5_rd_data          ) ,
    .MCB5_rd_full             ( MCB5_rd_full          ) ,
    .MCB5_rd_empty            ( MCB5_rd_empty         ) ,
    .MCB5_rd_count            ( MCB5_rd_count         ) ,
    .MCB5_rd_overflow         ( MCB5_rd_overflow      ) ,
    .MCB5_rd_error            ( MCB5_rd_error         ) ,
    // MPMC_CTRL registers
    .Debug_Ctrl_Addr          ( Debug_Ctrl_Addr       ) ,
    .Debug_Ctrl_WE            ( Debug_Ctrl_WE         ) ,
    .Debug_Ctrl_In            ( Debug_Ctrl_In         ) ,
    .Debug_Ctrl_Out           ( Debug_Ctrl_Out        ) ,
    .ECC_Reg_CE               ( ECC_Reg_CE            ) ,
    .ECC_Reg_In               ( ECC_Reg_In            ) ,
    .ECC_Reg_Out              ( ECC_Reg_Out           ) ,
    .Static_Phy_Reg_CE        ( Static_Phy_Reg_CE     ) ,
    .Static_Phy_Reg_In        ( Static_Phy_Reg_In     ) ,
    .Static_Phy_Reg_Out       ( Static_Phy_Reg_Out    ) ,
    // Port Interface Signals
    .PI_InitDone              ( NPI_InitDone          ) ,
    .PI_Addr                  ( NPI_Addr              ) ,
    .PI_AddrReq               ( NPI_AddrReq           ) ,
    .PI_AddrAck               ( NPI_AddrAck           ) ,
    .PI_RNW                   ( NPI_RNW               ) ,
    .PI_Size                  ( NPI_Size              ) ,
    .PI_RdModWr               ( NPI_RdModWr           ) ,
    .PI_WrFIFO_Data           ( NPI_WrFIFO_Data       ) ,
    .PI_WrFIFO_BE             ( NPI_WrFIFO_BE         ) ,
    .PI_WrFIFO_Push           ( NPI_WrFIFO_Push       ) ,
    .PI_RdFIFO_Data           ( NPI_RdFIFO_Data       ) ,
    .PI_RdFIFO_Pop            ( NPI_RdFIFO_Pop        ) ,
    .PI_RdFIFO_RdWdAddr       ( NPI_RdFIFO_RdWdAddr   ) ,
    .PI_WrFIFO_Empty          ( NPI_WrFIFO_Empty      ) ,
    .PI_WrFIFO_AlmostFull     ( NPI_WrFIFO_AlmostFull ) ,
    .PI_WrFIFO_Flush          ( NPI_WrFIFO_Flush      ) ,
    .PI_RdFIFO_Empty          ( NPI_RdFIFO_Empty      ) ,
    .PI_RdFIFO_Flush          ( NPI_RdFIFO_Flush      )

  );
  /////////////////////////////
  // MPMC PIM Instantiations //
  /////////////////////////////
  generate
  if (C_NUM_PORTS > 0 && C_PIM0_BASETYPE == 1) begin : DUALXCL0_INST
      assign pim_rst[0] = 1'b0;
      dualxcl
      #(
        .C_FAMILY                   (C_BASEFAMILY),
        .C_PI_A_SUBTYPE             (C_PIM0_SUBTYPE),
        .C_PI_B_SUBTYPE             (P_PIM0_B_SUBTYPE),
        .C_PI_BASEADDR              (P_PIM0_BASEADDR),
        .C_PI_HIGHADDR              (P_PIM0_HIGHADDR),
        .C_PI_OFFSET                (C_PIM0_OFFSET),
        .C_PI_ADDR_WIDTH            (P_PIM0_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM0_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM0_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM0_RDWDADDR_WIDTH),
        .C_PI_RDDATA_DELAY          (P_PIM0_RD_FIFO_LATENCY),
        .C_XCL_A_WRITEXFER          (C_XCL0_WRITEXFER),
        .C_XCL_A_LINESIZE           (C_XCL0_LINESIZE),
        .C_XCL_B_WRITEXFER          (C_XCL0_B_WRITEXFER),
        .C_XCL_B_LINESIZE           (C_XCL0_B_LINESIZE),
        .C_XCL_PIPE_STAGES          (C_XCL0_PIPE_STAGES),
        .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
        .C_MEM_SDR_DATA_WIDTH       (P_MEM_DATA_WIDTH_INT)
      )
      dualxcl_0
      (
        .Clk                        (FSL0_M_Clk),
        .Clk_MPMC                   (MPMC_Clk0),
        .Rst                        (Rst_topim[0]),
        .FSL_A_M_Clk                (FSL0_M_Clk),
        .FSL_A_M_Write              (FSL0_M_Write),
        .FSL_A_M_Data               (FSL0_M_Data),
        .FSL_A_M_Control            (FSL0_M_Control),
        .FSL_A_M_Full               (FSL0_M_Full),
        .FSL_A_S_Clk                (FSL0_S_Clk),
        .FSL_A_S_Read               (FSL0_S_Read),
        .FSL_A_S_Data               (FSL0_S_Data),
        .FSL_A_S_Control            (FSL0_S_Control),
        .FSL_A_S_Exists             (FSL0_S_Exists),
        .FSL_B_M_Clk                (FSL0_B_M_Clk),
        .FSL_B_M_Write              (FSL0_B_M_Write),
        .FSL_B_M_Data               (FSL0_B_M_Data),
        .FSL_B_M_Control            (FSL0_B_M_Control),
        .FSL_B_M_Full               (FSL0_B_M_Full),
        .FSL_B_S_Clk                (FSL0_B_S_Clk),
        .FSL_B_S_Read               (FSL0_B_S_Read),
        .FSL_B_S_Data               (FSL0_B_S_Data),
        .FSL_B_S_Control            (FSL0_B_S_Control),
        .FSL_B_S_Exists             (FSL0_B_S_Exists),
        .PI_Addr                    (NPI_Addr[0*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[0]),
        .PI_AddrAck                 (NPI_AddrAck[0]),
        .PI_RNW                     (NPI_RNW[0]),
        .PI_RdModWr                 (NPI_RdModWr[0]),
        .PI_Size                    (NPI_Size[0*4 +: 4]),
        .PI_InitDone                (NPI_InitDone[0]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[0*P_PIX_BE_WIDTH_MAX +: P_PIM0_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[0]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[0]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[0*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIM0_RDWDADDR_WIDTH]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[0]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[0]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[0]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[0])
      );
    end
  else if (C_NUM_PORTS > 0 && C_PIM0_BASETYPE == 2) begin : PLB_0_INST
      assign pim_rst[0] = SPLB0_Rst;
      plbv46_pim_wrapper
      #(
        .C_SPLB_DWIDTH              (C_SPLB0_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SPLB0_NATIVE_DWIDTH),
        .C_SPLB_AWIDTH              (C_SPLB0_AWIDTH),
        .C_SPLB_NUM_MASTERS         (C_SPLB0_NUM_MASTERS),
        .C_SPLB_MID_WIDTH           (C_SPLB0_MID_WIDTH),
        .C_SPLB_P2P                 (C_SPLB0_P2P),
        .C_SPLB_SUPPORT_BURSTS      (C_SPLB0_SUPPORT_BURSTS),
        .C_SPLB_SMALLEST_MASTER     (C_SPLB0_SMALLEST_MASTER),
        .C_PLBV46_PIM_TYPE          (C_PIM0_SUBTYPE),
        .C_MPMC_PIM_BASEADDR        (P_PIM0_BASEADDR[31:2]),
        .C_MPMC_PIM_HIGHADDR        (P_PIM0_HIGHADDR[31:2]),
        .C_MPMC_PIM_OFFSET          (C_PIM0_OFFSET[31:2]),
        .C_MPMC_PIM_DATA_WIDTH      (P_PIM0_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH      (P_PIM0_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY  (P_PIM0_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH  (P_PIM0_RDWDADDR_WIDTH),
        .C_MPMC_PIM_SDR_DWIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_MEM_HAS_BE      (P_MEM_HAS_BE),
        .C_MPMC_PIM_WR_FIFO_TYPE    (P_PI0_WR_FIFO_TYPE),
        .C_MPMC_PIM_RD_FIFO_TYPE    (P_PI0_RD_FIFO_TYPE),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      plbv46_pim_0
      (
        .MPMC_CLK                   (MPMC_Clk0),
        .MPMC_Rst                   (Rst_topim[0]),
        .SPLB_Clk                   (SPLB0_Clk),
        .SPLB_Rst                   (Rst_topim[0]),
        .SPLB_PLB_ABus              (SPLB0_PLB_ABus),
        .SPLB_PLB_UABus             (SPLB0_PLB_UABus),
        .SPLB_PLB_PAValid           (SPLB0_PLB_PAValid),
        .SPLB_PLB_SAValid           (SPLB0_PLB_SAValid),
        .SPLB_PLB_rdPrim            (SPLB0_PLB_rdPrim),
        .SPLB_PLB_wrPrim            (SPLB0_PLB_wrPrim),
        .SPLB_PLB_masterID          (SPLB0_PLB_masterID),
        .SPLB_PLB_abort             (SPLB0_PLB_abort),
        .SPLB_PLB_busLock           (SPLB0_PLB_busLock),
        .SPLB_PLB_RNW               (SPLB0_PLB_RNW),
        .SPLB_PLB_BE                (SPLB0_PLB_BE),
        .SPLB_PLB_MSize             (SPLB0_PLB_MSize),
        .SPLB_PLB_size              (SPLB0_PLB_size),
        .SPLB_PLB_type              (SPLB0_PLB_type),
        .SPLB_PLB_lockErr           (SPLB0_PLB_lockErr),
        .SPLB_PLB_wrDBus            (SPLB0_PLB_wrDBus),
        .SPLB_PLB_wrBurst           (SPLB0_PLB_wrBurst),
        .SPLB_PLB_rdBurst           (SPLB0_PLB_rdBurst),
        .SPLB_PLB_wrPendReq         (SPLB0_PLB_wrPendReq),
        .SPLB_PLB_rdPendReq         (SPLB0_PLB_rdPendReq),
        .SPLB_PLB_wrPendPri         (SPLB0_PLB_wrPendPri),
        .SPLB_PLB_rdPendPri         (SPLB0_PLB_rdPendPri),
        .SPLB_PLB_reqPri            (SPLB0_PLB_reqPri),
        .SPLB_PLB_TAttribute        (SPLB0_PLB_TAttribute),
        .SPLB_Sl_addrAck            (SPLB0_Sl_addrAck),
        .SPLB_Sl_SSize              (SPLB0_Sl_SSize),
        .SPLB_Sl_wait               (SPLB0_Sl_wait),
        .SPLB_Sl_rearbitrate        (SPLB0_Sl_rearbitrate),
        .SPLB_Sl_wrDAck             (SPLB0_Sl_wrDAck),
        .SPLB_Sl_wrComp             (SPLB0_Sl_wrComp),
        .SPLB_Sl_wrBTerm            (SPLB0_Sl_wrBTerm),
        .SPLB_Sl_rdDBus             (SPLB0_Sl_rdDBus),
        .SPLB_Sl_rdWdAddr           (SPLB0_Sl_rdWdAddr),
        .SPLB_Sl_rdDAck             (SPLB0_Sl_rdDAck),
        .SPLB_Sl_rdComp             (SPLB0_Sl_rdComp),
        .SPLB_Sl_rdBTerm            (SPLB0_Sl_rdBTerm),
        .SPLB_Sl_MBusy              (SPLB0_Sl_MBusy),
        .SPLB_Sl_MWrErr             (SPLB0_Sl_MWrErr),
        .SPLB_Sl_MRdErr             (SPLB0_Sl_MRdErr),
        .SPLB_Sl_MIRQ               (SPLB0_Sl_MIRQ),
        .MPMC_PIM_InitDone          (NPI_InitDone[0]),
        .MPMC_PIM_Addr              (NPI_Addr[0*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq           (NPI_AddrReq[0]),
        .MPMC_PIM_AddrAck           (NPI_AddrAck[0]),
        .MPMC_PIM_RNW               (NPI_RNW[0]),
        .MPMC_PIM_Size              (NPI_Size[0*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data       (NPI_WrFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE         (NPI_WrFIFO_BE[0*P_PIX_BE_WIDTH_MAX +: P_PIM0_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push       (NPI_WrFIFO_Push[0]),
        .MPMC_PIM_WrFIFO_Empty      (NPI_WrFIFO_Empty[0]),
        .MPMC_PIM_WrFIFO_AlmostFull (NPI_WrFIFO_AlmostFull[0]),
        .MPMC_PIM_RdFIFO_Latency    (NPI_RdFIFO_Latency[0*2 +: 2]),
        .MPMC_PIM_RdFIFO_Data       (NPI_RdFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop        (NPI_RdFIFO_Pop[0]),
        .MPMC_PIM_RdFIFO_Empty      (NPI_RdFIFO_Empty[0]),
        .MPMC_PIM_RdFIFO_RdWd_Addr  (NPI_RdFIFO_RdWdAddr[0*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_RdFIFO_Data_Available  (NPI_RdFIFO_DataAvailable[0]),
        .MPMC_PIM_RdFIFO_Flush      (NPI_RdFIFO_Flush[0]),
        .MPMC_PIM_WrFIFO_Flush      (NPI_WrFIFO_Flush[0]),
        .MPMC_PIM_RdModWr           (NPI_RdModWr[0])
      );
  end
  else if (C_NUM_PORTS > 0 && (C_PIM0_BASETYPE == 3)) begin : SDMA0_INST
      assign pim_rst[0] = SDMA_CTRL0_Rst;
      sdma_wrapper
      #(
        .C_PI_BASEADDR              (P_PIM0_BASEADDR[31:2]),
        .C_PI_HIGHADDR              (P_PIM0_HIGHADDR[31:2]),
        .C_PI_ADDR_WIDTH            (P_PIM0_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM0_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM0_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM0_RDWDADDR_WIDTH),
        .C_SDMA_BASEADDR            (P_SDMA_CTRL0_BASEADDR[31:2]),
        .C_SDMA_HIGHADDR            (P_SDMA_CTRL0_HIGHADDR[31:2]),
        .C_COMPLETED_ERR_TX         (C_SDMA0_COMPLETED_ERR_TX),
        .C_COMPLETED_ERR_RX         (C_SDMA0_COMPLETED_ERR_RX),
        .C_PRESCALAR                (C_SDMA0_PRESCALAR),
        .C_PI_RDDATA_DELAY          (P_PIM0_RD_FIFO_LATENCY),
        .C_PI2LL_CLK_RATIO          (C_SDMA0_PI2LL_CLK_RATIO),
        .C_SPLB_P2P                 (C_SDMA_CTRL0_P2P),
        .C_SPLB_MID_WIDTH           (C_SDMA_CTRL0_MID_WIDTH),
        .C_SPLB_NUM_MASTERS         (C_SDMA_CTRL0_NUM_MASTERS),
        .C_SPLB_AWIDTH              (C_SDMA_CTRL0_AWIDTH),
        .C_SPLB_DWIDTH              (C_SDMA_CTRL0_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SDMA_CTRL0_NATIVE_DWIDTH),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      mpmc_sdma_0
      (
        .LLink_Clk                  (SDMA0_Clk),
        .PI_Clk                     (MPMC_Clk0),
        // PLBv46 Signals
        .SPLB_Clk                   (SDMA_CTRL0_Clk),
        .SPLB_Rst                   (Rst_topim[0]),
        .PLB_ABus                   (SDMA_CTRL0_PLB_ABus),
        .PLB_UABus                  (SDMA_CTRL0_PLB_UABus),
        .PLB_PAValid                (SDMA_CTRL0_PLB_PAValid),
        .PLB_SAValid                (SDMA_CTRL0_PLB_SAValid),
        .PLB_rdPrim                 (SDMA_CTRL0_PLB_rdPrim),
        .PLB_wrPrim                 (SDMA_CTRL0_PLB_wrPrim),
        .PLB_masterID               (SDMA_CTRL0_PLB_masterID),
        .PLB_abort                  (SDMA_CTRL0_PLB_abort),
        .PLB_busLock                (SDMA_CTRL0_PLB_busLock),
        .PLB_RNW                    (SDMA_CTRL0_PLB_RNW),
        .PLB_BE                     (SDMA_CTRL0_PLB_BE),
        .PLB_MSize                  (SDMA_CTRL0_PLB_MSize),
        .PLB_size                   (SDMA_CTRL0_PLB_size),
        .PLB_type                   (SDMA_CTRL0_PLB_type),
        .PLB_lockErr                (SDMA_CTRL0_PLB_lockErr),
        .PLB_wrDBus                 (SDMA_CTRL0_PLB_wrDBus),
        .PLB_wrBurst                (SDMA_CTRL0_PLB_wrBurst),
        .PLB_rdBurst                (SDMA_CTRL0_PLB_rdBurst),
        .PLB_wrPendReq              (SDMA_CTRL0_PLB_wrPendReq),
        .PLB_rdPendReq              (SDMA_CTRL0_PLB_rdPendReq),
        .PLB_wrPendPri              (SDMA_CTRL0_PLB_wrPendPri),
        .PLB_rdPendPri              (SDMA_CTRL0_PLB_rdPendPri),
        .PLB_reqPri                 (SDMA_CTRL0_PLB_reqPri),
        .PLB_TAttribute             (SDMA_CTRL0_PLB_TAttribute),
        .Sln_addrAck                 (SDMA_CTRL0_Sl_addrAck),
        .Sln_SSize                   (SDMA_CTRL0_Sl_SSize),
        .Sln_wait                    (SDMA_CTRL0_Sl_wait),
        .Sln_rearbitrate             (SDMA_CTRL0_Sl_rearbitrate),
        .Sln_wrDAck                  (SDMA_CTRL0_Sl_wrDAck),
        .Sln_wrComp                  (SDMA_CTRL0_Sl_wrComp),
        .Sln_wrBTerm                 (SDMA_CTRL0_Sl_wrBTerm),
        .Sln_rdDBus                  (SDMA_CTRL0_Sl_rdDBus),
        .Sln_rdWdAddr                (SDMA_CTRL0_Sl_rdWdAddr),
        .Sln_rdDAck                  (SDMA_CTRL0_Sl_rdDAck),
        .Sln_rdComp                  (SDMA_CTRL0_Sl_rdComp),
        .Sln_rdBTerm                 (SDMA_CTRL0_Sl_rdBTerm),
        .Sln_MBusy                   (SDMA_CTRL0_Sl_MBusy),
        .Sln_MWrErr                  (SDMA_CTRL0_Sl_MWrErr),
        .Sln_MRdErr                  (SDMA_CTRL0_Sl_MRdErr),
        .Sln_MIRQ                    (SDMA_CTRL0_Sl_MIRQ),
        // MPMC NPI Signals
        .PI_Addr                    (NPI_Addr[0*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[0]),
        .PI_AddrAck                 (NPI_AddrAck[0]),
        .PI_RdModWr                 (NPI_RdModWr[0]),
        .PI_RNW                     (NPI_RNW[0]),
        .PI_Size                    (NPI_Size[0*4 +: 4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[0*P_PIX_BE_WIDTH_MAX +: P_PIM0_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[0]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[0]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[0*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[0]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[0]),
        .PI_WrFIFO_Empty            (NPI_WrFIFO_Empty[0]),
        .PI_RdFIFO_DataAvailable    (NPI_RdFIFO_DataAvailable[0]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[0]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[0]),
        //.PI_InitDone                (NPI_InitDone[0]),
        // SDMA Signals
        .TX_D                       (SDMA0_TX_D),
        .TX_Rem                     (SDMA0_TX_Rem),
        .TX_SOF                     (SDMA0_TX_SOF),
        .TX_EOF                     (SDMA0_TX_EOF),
        .TX_SOP                     (SDMA0_TX_SOP),
        .TX_EOP                     (SDMA0_TX_EOP),
        .TX_Src_Rdy                 (SDMA0_TX_Src_Rdy),
        .TX_Dst_Rdy                 (SDMA0_TX_Dst_Rdy),
        .RX_D                       (SDMA0_RX_D),
        .RX_Rem                     (SDMA0_RX_Rem),
        .RX_SOF                     (SDMA0_RX_SOF),
        .RX_EOF                     (SDMA0_RX_EOF),
        .RX_SOP                     (SDMA0_RX_SOP),
        .RX_EOP                     (SDMA0_RX_EOP),
        .RX_Src_Rdy                 (SDMA0_RX_Src_Rdy),
        .RX_Dst_Rdy                 (SDMA0_RX_Dst_Rdy),
        .SDMA_RstOut                (SDMA0_RstOut),
        .SDMA_Rx_IntOut             (SDMA0_Rx_IntOut),
        .SDMA_Tx_IntOut             (SDMA0_Tx_IntOut)
      );
  end
  else if (C_NUM_PORTS > 0 && (C_PIM0_BASETYPE == 4)) begin : NPI0_INST
      // do nothing, pass signals straight through
      assign pim_rst[0] = 1'b0;
      assign PIM0_InitDone = NPI_InitDone[0];
      assign NPI_AddrReq[0] = PIM0_AddrReq;
      assign PIM0_AddrAck = NPI_AddrAck[0];
      assign NPI_Addr[0*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]    = PIM0_Addr;
      assign NPI_RNW[0] = PIM0_RNW;
      assign NPI_Size[0*4 +: 4] = PIM0_Size;
      assign NPI_RdModWr[0] = PIM0_RdModWr;
      assign NPI_WrFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH] = PIM0_WrFIFO_Data;
      assign NPI_WrFIFO_BE[0*P_PIX_BE_WIDTH_MAX +: P_PIM0_BE_WIDTH] = PIM0_WrFIFO_BE;
      assign NPI_WrFIFO_Push[0] = PIM0_WrFIFO_Push;
      assign PIM0_RdFIFO_Data = NPI_RdFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH];
      assign NPI_RdFIFO_Pop[0] = PIM0_RdFIFO_Pop;
      assign PIM0_RdFIFO_RdWdAddr = NPI_RdFIFO_RdWdAddr[0*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX];
      assign PIM0_WrFIFO_Empty = NPI_WrFIFO_Empty[0];
      assign PIM0_WrFIFO_AlmostFull = NPI_WrFIFO_AlmostFull[0];
      assign NPI_WrFIFO_Flush[0] = PIM0_WrFIFO_Flush;
      assign PIM0_RdFIFO_Empty = NPI_RdFIFO_Empty[0];
      assign NPI_RdFIFO_Flush[0] = PIM0_RdFIFO_Flush;
      assign PIM0_RdFIFO_Latency = NPI_RdFIFO_Latency[0*2 +: 2];
  end
  else if (C_NUM_PORTS > 0 && (C_PIM0_BASETYPE == 5)) begin : PPC440MC0_INST
      assign pim_rst[0] = 1'b0;
      mib_pim
      #(
        .C_MPMC_PIM_DATA_WIDTH          (P_PIM0_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH          (P_PIM0_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY      (P_PIM0_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH      (P_PIM0_RDWDADDR_WIDTH),
        .C_MPMC_PIM_MEM_DATA_WIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_BURST_LENGTH        (C_PPC440MC0_BURST_LENGTH),
        .C_MPMC_PIM_PIPE_STAGES         (C_PPC440MC0_PIPE_STAGES),
        .C_MPMC_PIM_WRFIFO_TYPE         (P_PI0_WR_FIFO_TYPE),
        .C_MPMC_PIM_OFFSET              (C_PIM0_OFFSET),
        .C_FAMILY                       (C_BASEFAMILY)
      )
      ppc440mc
      (
        .MPMC_Clk                       (MPMC_Clk0),
        .MPMC_Rst                       (Rst_topim[0]),
        .MPMC_PIM_Addr                  (NPI_Addr[0*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq               (NPI_AddrReq[0]),
        .MPMC_PIM_AddrAck               (NPI_AddrAck[0]),
        .MPMC_PIM_RdModWr               (NPI_RdModWr[0]),
        .MPMC_PIM_RNW                   (NPI_RNW[0]),
        .MPMC_PIM_Size                  (NPI_Size[0*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data           (NPI_WrFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE             (NPI_WrFIFO_BE[0*P_PIX_BE_WIDTH_MAX +: P_PIM0_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push           (NPI_WrFIFO_Push[0]),
        .MPMC_PIM_RdFIFO_Data           (NPI_RdFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop            (NPI_RdFIFO_Pop[0]),
        .MPMC_PIM_RdFIFO_RdWdAddr       (NPI_RdFIFO_RdWdAddr[0*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_WrFIFO_AlmostFull     (NPI_WrFIFO_AlmostFull[0]),
        .MPMC_PIM_WrFIFO_Flush          (NPI_WrFIFO_Flush[0]),
        .MPMC_PIM_WrFIFO_Empty          (NPI_WrFIFO_Empty[0]),
        .MPMC_PIM_RdFIFO_DataAvailable  (NPI_RdFIFO_DataAvailable[0]),
        .MPMC_PIM_RdFIFO_Empty          (NPI_RdFIFO_Empty[0]),
        .MPMC_PIM_RdFIFO_Flush          (NPI_RdFIFO_Flush[0]),
        .MPMC_PIM_InitDone              (NPI_InitDone[0]),
        .MPMC_PIM_Rd_FIFO_Latency       (NPI_RdFIFO_Latency[0*2 +: 2]),
        .mi_mcaddressvalid              (PPC440MC0_MIMCAddressValid),
        .mi_mcaddress                   (PPC440MC0_MIMCAddress),
        .mi_mcbankconflict              (PPC440MC0_MIMCBankConflict),
        .mi_mcrowconflict               (PPC440MC0_MIMCRowConflict),
        .mi_mcbyteenable                (PPC440MC0_MIMCByteEnable),
        .mi_mcwritedata                 (PPC440MC0_MIMCWriteData),
        .mi_mcreadnotwrite              (PPC440MC0_MIMCReadNotWrite),
        .mi_mcwritedatavalid            (PPC440MC0_MIMCWriteDataValid),
        .mc_miaddrreadytoaccept         (PPC440MC0_MCMIAddrReadyToAccept),
        .mc_mireaddata                  (PPC440MC0_MCMIReadData),
        .mc_mireaddataerr               (PPC440MC0_MCMIReadDataErr),
        .mc_mireaddatavalid             (PPC440MC0_MCMIReadDataValid)
    );
  end
  else if (C_NUM_PORTS > 0 && (C_PIM0_BASETYPE == 6)) begin : VFBC0_INST
      assign pim_rst[0] = 1'b0;
      assign NPI_RdModWr[0] = 1'b1;
      vfbc_pim_wrapper
      #(
        .C_MPMC_BASEADDR  (C_MPMC_BASEADDR[31:2]),
        .C_MPMC_HIGHADDR  (C_MPMC_HIGHADDR[31:2]),
        .C_PIM_DATA_WIDTH               (P_PIM0_DATA_WIDTH),
        .C_CHIPSCOPE_ENABLE             (P_VFBC0_CHIPSCOPE_ENABLE),
        .C_FAMILY                       (C_BASEFAMILY),
        .VFBC_BURST_LENGTH              (P_VFBC0_BURST_LENGTH),
        .CMD0_PORT_ID                   (P_VFBC0_CMD_PORT_ID),
        .CMD0_FIFO_DEPTH                (C_VFBC0_CMD_FIFO_DEPTH),
        .CMD0_ASYNC_CLOCK               (P_VFBC0_ASYNC_CLOCK),
        .CMD0_AFULL_COUNT               (C_VFBC0_CMD_AFULL_COUNT),
        .WD0_ENABLE                     (P_VFBC0_WD_ENABLE),
        .WD0_DATA_WIDTH                 (P_VFBC0_WD_DATA_WIDTH),
        .WD0_FIFO_DEPTH                 (P_VFBC0_WD_FIFO_DEPTH),
        .WD0_ASYNC_CLOCK                (P_VFBC0_ASYNC_CLOCK),
        .WD0_AFULL_COUNT                (P_VFBC0_WD_AFULL_COUNT),
        .WD0_BYTEEN_ENABLE              (P_VFBC0_WD_BYTEEN_ENABLE),
        .RD0_ENABLE                     (P_VFBC0_RD_ENABLE),
        .RD0_DATA_WIDTH                 (P_VFBC0_RD_DATA_WIDTH),
        .RD0_FIFO_DEPTH                 (P_VFBC0_RD_FIFO_DEPTH),
        .RD0_ASYNC_CLOCK                (P_VFBC0_ASYNC_CLOCK),
        .RD0_AEMPTY_COUNT               (P_VFBC0_RD_AEMPTY_COUNT)
      )
      vfbc
      (
        .vfbc_clk                       (MPMC_Clk0),
        .srst                           (Rst_topim[0]),
        .cmd0_clk                       (VFBC0_Cmd_Clk),
        .cmd0_reset                     (VFBC0_Cmd_Reset),
        .cmd0_data                      (VFBC0_Cmd_Data),
        .cmd0_write                     (VFBC0_Cmd_Write),
        .cmd0_end                       (VFBC0_Cmd_End),
        .cmd0_full                      (VFBC0_Cmd_Full),
        .cmd0_almost_full               (VFBC0_Cmd_Almost_Full),
        .cmd0_idle                      (VFBC0_Cmd_Idle),
        .wd0_clk                        (VFBC0_Wd_Clk),
        .wd0_reset                      (VFBC0_Wd_Reset),
        .wd0_write                      (VFBC0_Wd_Write),
        .wd0_end_burst                  (VFBC0_Wd_End_Burst),
        .wd0_flush                      (VFBC0_Wd_Flush),
        .wd0_data                       (VFBC0_Wd_Data),
        .wd0_data_be                    (VFBC0_Wd_Data_BE),
        .wd0_full                       (VFBC0_Wd_Full),
        .wd0_almost_full                (VFBC0_Wd_Almost_Full),
        .rd0_clk                        (VFBC0_Rd_Clk),
        .rd0_reset                      (VFBC0_Rd_Reset),
        .rd0_read                       (VFBC0_Rd_Read),
        .rd0_end_burst                  (VFBC0_Rd_End_Burst),
        .rd0_flush                      (VFBC0_Rd_Flush),
        .rd0_data                       (VFBC0_Rd_Data),
        .rd0_empty                      (VFBC0_Rd_Empty),
        .rd0_almost_empty               (VFBC0_Rd_Almost_Empty),
        .npi_init_done                  (NPI_InitDone[0]),
        .npi_addr_ack                   (NPI_AddrAck[0]),
        .npi_rdfifo_word_add            (NPI_RdFIFO_RdWdAddr[0*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .npi_rdfifo_data                (NPI_RdFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .npi_rdfifo_latency             (NPI_RdFIFO_Latency[0*2 +: 2]),
        .npi_rdfifo_empty               (NPI_RdFIFO_Empty[0]),
        .npi_wrfifo_almost_full         (NPI_WrFIFO_AlmostFull[0]),
        .npi_address                    (NPI_Addr[0*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .npi_addr_req                   (NPI_AddrReq[0]),
        .npi_size                       (NPI_Size[0*4 +: 4]),
        .npi_rnw                        (NPI_RNW[0]),
        .npi_rdfifo_pop                 (NPI_RdFIFO_Pop[0]),
        .npi_rdfifo_flush               (NPI_RdFIFO_Flush[0]),
        .npi_wrfifo_data                (NPI_WrFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH]),
        .npi_wrfifo_be                  (NPI_WrFIFO_BE[0*P_PIX_BE_WIDTH_MAX +: P_PIM0_BE_WIDTH]),
        .npi_wrfifo_push                (NPI_WrFIFO_Push[0]),
        .npi_wrfifo_flush               (NPI_WrFIFO_Flush[0])
//        .npi_rdmodwr                    (NPI_RdModWr[0])
    );
  end
  else begin : INACTIVE_0
      // tie off unused inputs to mpmc_core
      assign pim_rst[0] = 1'b0;
      if (C_NUM_PORTS > 0) begin : TIE_OFF_0
        assign NPI_Addr[0*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX] = 0;
        assign NPI_AddrReq[0] = 0;
        assign NPI_RNW[0] = 0;
        assign NPI_Size[0*4 +: 4] = 0;
        assign NPI_WrFIFO_Data[0*P_PIX_DATA_WIDTH_MAX +: P_PIM0_DATA_WIDTH] = 0;
        assign NPI_WrFIFO_BE[0*P_PIX_BE_WIDTH_MAX +: P_PIM0_BE_WIDTH] = 0;
        assign NPI_WrFIFO_Push[0] = 0;
        assign NPI_WrFIFO_Flush[0] = 0;
        assign NPI_RdFIFO_Pop[0] = 0;
        assign NPI_RdFIFO_Flush[0] = 0;
      end
    end
  endgenerate
  generate
  if (C_NUM_PORTS > 1 && C_PIM1_BASETYPE == 1)
    begin : DUALXCL1_INST
      assign pim_rst[1] = 1'b0;
      dualxcl
      #(
        .C_FAMILY                   (C_BASEFAMILY),
        .C_PI_A_SUBTYPE             (C_PIM1_SUBTYPE),
        .C_PI_B_SUBTYPE             (P_PIM1_B_SUBTYPE),
        .C_PI_BASEADDR              (P_PIM1_BASEADDR),
        .C_PI_HIGHADDR              (P_PIM1_HIGHADDR),
        .C_PI_OFFSET                (C_PIM1_OFFSET),
        .C_PI_ADDR_WIDTH            (P_PIM1_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM1_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM1_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM1_RDWDADDR_WIDTH),
        .C_PI_RDDATA_DELAY          (P_PIM1_RD_FIFO_LATENCY),
        .C_XCL_A_WRITEXFER          (C_XCL1_WRITEXFER),
        .C_XCL_A_LINESIZE           (C_XCL1_LINESIZE),
        .C_XCL_B_WRITEXFER          (C_XCL1_B_WRITEXFER),
        .C_XCL_B_LINESIZE           (C_XCL1_B_LINESIZE),
        .C_XCL_PIPE_STAGES          (C_XCL1_PIPE_STAGES),
        .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
        .C_MEM_SDR_DATA_WIDTH       (P_MEM_DATA_WIDTH_INT)
      )
      dualxcl_1
      (
        .Clk                        (FSL1_M_Clk),
        .Clk_MPMC                   (MPMC_Clk0),
        .Rst                        (Rst_topim[1]),
        .FSL_A_M_Clk                (FSL1_M_Clk),
        .FSL_A_M_Write              (FSL1_M_Write),
        .FSL_A_M_Data               (FSL1_M_Data),
        .FSL_A_M_Control            (FSL1_M_Control),
        .FSL_A_M_Full               (FSL1_M_Full),
        .FSL_A_S_Clk                (FSL1_S_Clk),
        .FSL_A_S_Read               (FSL1_S_Read),
        .FSL_A_S_Data               (FSL1_S_Data),
        .FSL_A_S_Control            (FSL1_S_Control),
        .FSL_A_S_Exists             (FSL1_S_Exists),
        .FSL_B_M_Clk                (FSL1_B_M_Clk),
        .FSL_B_M_Write              (FSL1_B_M_Write),
        .FSL_B_M_Data               (FSL1_B_M_Data),
        .FSL_B_M_Control            (FSL1_B_M_Control),
        .FSL_B_M_Full               (FSL1_B_M_Full),
        .FSL_B_S_Clk                (FSL1_B_S_Clk),
        .FSL_B_S_Read               (FSL1_B_S_Read),
        .FSL_B_S_Data               (FSL1_B_S_Data),
        .FSL_B_S_Control            (FSL1_B_S_Control),
        .FSL_B_S_Exists             (FSL1_B_S_Exists),
        .PI_Addr                    (NPI_Addr[1*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[1]),
        .PI_AddrAck                 (NPI_AddrAck[1]),
        .PI_RNW                     (NPI_RNW[1]),
        .PI_RdModWr                 (NPI_RdModWr[1]),
        .PI_Size                    (NPI_Size[1*4 +: 4]),
        .PI_InitDone                (NPI_InitDone[1]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[1*P_PIX_BE_WIDTH_MAX +: P_PIM1_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[1]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[1]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[1*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIM1_RDWDADDR_WIDTH]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[1]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[1]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[1]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[1])
      );
    end
  else if (C_NUM_PORTS > 1 && C_PIM1_BASETYPE == 2) begin : PLB_1_INST
      assign pim_rst[1] = SPLB1_Rst;
      plbv46_pim_wrapper
      #(
        .C_SPLB_DWIDTH              (C_SPLB1_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SPLB1_NATIVE_DWIDTH),
        .C_SPLB_AWIDTH              (C_SPLB1_AWIDTH),
        .C_SPLB_NUM_MASTERS         (C_SPLB1_NUM_MASTERS),
        .C_SPLB_MID_WIDTH           (C_SPLB1_MID_WIDTH),
        .C_SPLB_P2P                 (C_SPLB1_P2P),
        .C_SPLB_SUPPORT_BURSTS      (C_SPLB1_SUPPORT_BURSTS),
        .C_SPLB_SMALLEST_MASTER     (C_SPLB1_SMALLEST_MASTER),
        .C_PLBV46_PIM_TYPE          (C_PIM1_SUBTYPE),
        .C_MPMC_PIM_BASEADDR        (P_PIM1_BASEADDR[31:2]),
        .C_MPMC_PIM_HIGHADDR        (P_PIM1_HIGHADDR[31:2]),
        .C_MPMC_PIM_OFFSET          (C_PIM1_OFFSET[31:2]),
        .C_MPMC_PIM_DATA_WIDTH      (P_PIM1_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH      (P_PIM1_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY  (P_PIM1_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH  (P_PIM1_RDWDADDR_WIDTH),
        .C_MPMC_PIM_SDR_DWIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_MEM_HAS_BE      (P_MEM_HAS_BE),
        .C_MPMC_PIM_WR_FIFO_TYPE    (P_PI1_WR_FIFO_TYPE),
        .C_MPMC_PIM_RD_FIFO_TYPE    (P_PI1_RD_FIFO_TYPE),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      plbv46_pim_1
      (
        .MPMC_CLK                   (MPMC_Clk0),
        .MPMC_Rst                   (Rst_topim[1]),
        .SPLB_Clk                   (SPLB1_Clk),
        .SPLB_Rst                   (Rst_topim[1]),
        .SPLB_PLB_ABus              (SPLB1_PLB_ABus),
        .SPLB_PLB_UABus             (SPLB1_PLB_UABus),
        .SPLB_PLB_PAValid           (SPLB1_PLB_PAValid),
        .SPLB_PLB_SAValid           (SPLB1_PLB_SAValid),
        .SPLB_PLB_rdPrim            (SPLB1_PLB_rdPrim),
        .SPLB_PLB_wrPrim            (SPLB1_PLB_wrPrim),
        .SPLB_PLB_masterID          (SPLB1_PLB_masterID),
        .SPLB_PLB_abort             (SPLB1_PLB_abort),
        .SPLB_PLB_busLock           (SPLB1_PLB_busLock),
        .SPLB_PLB_RNW               (SPLB1_PLB_RNW),
        .SPLB_PLB_BE                (SPLB1_PLB_BE),
        .SPLB_PLB_MSize             (SPLB1_PLB_MSize),
        .SPLB_PLB_size              (SPLB1_PLB_size),
        .SPLB_PLB_type              (SPLB1_PLB_type),
        .SPLB_PLB_lockErr           (SPLB1_PLB_lockErr),
        .SPLB_PLB_wrDBus            (SPLB1_PLB_wrDBus),
        .SPLB_PLB_wrBurst           (SPLB1_PLB_wrBurst),
        .SPLB_PLB_rdBurst           (SPLB1_PLB_rdBurst),
        .SPLB_PLB_wrPendReq         (SPLB1_PLB_wrPendReq),
        .SPLB_PLB_rdPendReq         (SPLB1_PLB_rdPendReq),
        .SPLB_PLB_wrPendPri         (SPLB1_PLB_wrPendPri),
        .SPLB_PLB_rdPendPri         (SPLB1_PLB_rdPendPri),
        .SPLB_PLB_reqPri            (SPLB1_PLB_reqPri),
        .SPLB_PLB_TAttribute        (SPLB1_PLB_TAttribute),
        .SPLB_Sl_addrAck            (SPLB1_Sl_addrAck),
        .SPLB_Sl_SSize              (SPLB1_Sl_SSize),
        .SPLB_Sl_wait               (SPLB1_Sl_wait),
        .SPLB_Sl_rearbitrate        (SPLB1_Sl_rearbitrate),
        .SPLB_Sl_wrDAck             (SPLB1_Sl_wrDAck),
        .SPLB_Sl_wrComp             (SPLB1_Sl_wrComp),
        .SPLB_Sl_wrBTerm            (SPLB1_Sl_wrBTerm),
        .SPLB_Sl_rdDBus             (SPLB1_Sl_rdDBus),
        .SPLB_Sl_rdWdAddr           (SPLB1_Sl_rdWdAddr),
        .SPLB_Sl_rdDAck             (SPLB1_Sl_rdDAck),
        .SPLB_Sl_rdComp             (SPLB1_Sl_rdComp),
        .SPLB_Sl_rdBTerm            (SPLB1_Sl_rdBTerm),
        .SPLB_Sl_MBusy              (SPLB1_Sl_MBusy),
        .SPLB_Sl_MWrErr             (SPLB1_Sl_MWrErr),
        .SPLB_Sl_MRdErr             (SPLB1_Sl_MRdErr),
        .SPLB_Sl_MIRQ               (SPLB1_Sl_MIRQ),
        .MPMC_PIM_InitDone          (NPI_InitDone[1]),
        .MPMC_PIM_Addr              (NPI_Addr[1*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq           (NPI_AddrReq[1]),
        .MPMC_PIM_AddrAck           (NPI_AddrAck[1]),
        .MPMC_PIM_RNW               (NPI_RNW[1]),
        .MPMC_PIM_Size              (NPI_Size[1*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data       (NPI_WrFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE         (NPI_WrFIFO_BE[1*P_PIX_BE_WIDTH_MAX +: P_PIM1_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push       (NPI_WrFIFO_Push[1]),
        .MPMC_PIM_WrFIFO_Empty      (NPI_WrFIFO_Empty[1]),
        .MPMC_PIM_WrFIFO_AlmostFull (NPI_WrFIFO_AlmostFull[1]),
        .MPMC_PIM_RdFIFO_Latency    (NPI_RdFIFO_Latency[1*2 +: 2]),
        .MPMC_PIM_RdFIFO_Data       (NPI_RdFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop        (NPI_RdFIFO_Pop[1]),
        .MPMC_PIM_RdFIFO_Empty      (NPI_RdFIFO_Empty[1]),
        .MPMC_PIM_RdFIFO_RdWd_Addr  (NPI_RdFIFO_RdWdAddr[1*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_RdFIFO_Data_Available  (NPI_RdFIFO_DataAvailable[1]),
        .MPMC_PIM_RdFIFO_Flush      (NPI_RdFIFO_Flush[1]),
        .MPMC_PIM_WrFIFO_Flush      (NPI_WrFIFO_Flush[1]),
        .MPMC_PIM_RdModWr           (NPI_RdModWr[1])
      );
  end
  else if (C_NUM_PORTS > 1 && (C_PIM1_BASETYPE == 3)) begin : SDMA1_INST
      assign pim_rst[1] = SDMA_CTRL1_Rst;
      sdma_wrapper
      #(
        .C_PI_BASEADDR              (P_PIM1_BASEADDR[31:2]),
        .C_PI_HIGHADDR              (P_PIM1_HIGHADDR[31:2]),
        .C_PI_ADDR_WIDTH            (P_PIM1_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM1_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM1_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM1_RDWDADDR_WIDTH),
        .C_SDMA_BASEADDR            (P_SDMA_CTRL1_BASEADDR[31:2]),
        .C_SDMA_HIGHADDR            (P_SDMA_CTRL1_HIGHADDR[31:2]),
        .C_COMPLETED_ERR_TX         (C_SDMA1_COMPLETED_ERR_TX),
        .C_COMPLETED_ERR_RX         (C_SDMA1_COMPLETED_ERR_RX),
        .C_PRESCALAR                (C_SDMA1_PRESCALAR),
        .C_PI_RDDATA_DELAY          (P_PIM1_RD_FIFO_LATENCY),
        .C_PI2LL_CLK_RATIO          (C_SDMA1_PI2LL_CLK_RATIO),
        .C_SPLB_P2P                 (C_SDMA_CTRL1_P2P),
        .C_SPLB_MID_WIDTH           (C_SDMA_CTRL1_MID_WIDTH),
        .C_SPLB_NUM_MASTERS         (C_SDMA_CTRL1_NUM_MASTERS),
        .C_SPLB_AWIDTH              (C_SDMA_CTRL1_AWIDTH),
        .C_SPLB_DWIDTH              (C_SDMA_CTRL1_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SDMA_CTRL1_NATIVE_DWIDTH),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      mpmc_sdma_1
      (
        .LLink_Clk                  (SDMA1_Clk),
        .PI_Clk                     (MPMC_Clk0),
        // PLBv46 Signals
        .SPLB_Clk                   (SDMA_CTRL1_Clk),
        .SPLB_Rst                   (Rst_topim[1]),
        .PLB_ABus                   (SDMA_CTRL1_PLB_ABus),
        .PLB_UABus                  (SDMA_CTRL1_PLB_UABus),
        .PLB_PAValid                (SDMA_CTRL1_PLB_PAValid),
        .PLB_SAValid                (SDMA_CTRL1_PLB_SAValid),
        .PLB_rdPrim                 (SDMA_CTRL1_PLB_rdPrim),
        .PLB_wrPrim                 (SDMA_CTRL1_PLB_wrPrim),
        .PLB_masterID               (SDMA_CTRL1_PLB_masterID),
        .PLB_abort                  (SDMA_CTRL1_PLB_abort),
        .PLB_busLock                (SDMA_CTRL1_PLB_busLock),
        .PLB_RNW                    (SDMA_CTRL1_PLB_RNW),
        .PLB_BE                     (SDMA_CTRL1_PLB_BE),
        .PLB_MSize                  (SDMA_CTRL1_PLB_MSize),
        .PLB_size                   (SDMA_CTRL1_PLB_size),
        .PLB_type                   (SDMA_CTRL1_PLB_type),
        .PLB_lockErr                (SDMA_CTRL1_PLB_lockErr),
        .PLB_wrDBus                 (SDMA_CTRL1_PLB_wrDBus),
        .PLB_wrBurst                (SDMA_CTRL1_PLB_wrBurst),
        .PLB_rdBurst                (SDMA_CTRL1_PLB_rdBurst),
        .PLB_wrPendReq              (SDMA_CTRL1_PLB_wrPendReq),
        .PLB_rdPendReq              (SDMA_CTRL1_PLB_rdPendReq),
        .PLB_wrPendPri              (SDMA_CTRL1_PLB_wrPendPri),
        .PLB_rdPendPri              (SDMA_CTRL1_PLB_rdPendPri),
        .PLB_reqPri                 (SDMA_CTRL1_PLB_reqPri),
        .PLB_TAttribute             (SDMA_CTRL1_PLB_TAttribute),
        .Sln_addrAck                 (SDMA_CTRL1_Sl_addrAck),
        .Sln_SSize                   (SDMA_CTRL1_Sl_SSize),
        .Sln_wait                    (SDMA_CTRL1_Sl_wait),
        .Sln_rearbitrate             (SDMA_CTRL1_Sl_rearbitrate),
        .Sln_wrDAck                  (SDMA_CTRL1_Sl_wrDAck),
        .Sln_wrComp                  (SDMA_CTRL1_Sl_wrComp),
        .Sln_wrBTerm                 (SDMA_CTRL1_Sl_wrBTerm),
        .Sln_rdDBus                  (SDMA_CTRL1_Sl_rdDBus),
        .Sln_rdWdAddr                (SDMA_CTRL1_Sl_rdWdAddr),
        .Sln_rdDAck                  (SDMA_CTRL1_Sl_rdDAck),
        .Sln_rdComp                  (SDMA_CTRL1_Sl_rdComp),
        .Sln_rdBTerm                 (SDMA_CTRL1_Sl_rdBTerm),
        .Sln_MBusy                   (SDMA_CTRL1_Sl_MBusy),
        .Sln_MWrErr                  (SDMA_CTRL1_Sl_MWrErr),
        .Sln_MRdErr                  (SDMA_CTRL1_Sl_MRdErr),
        .Sln_MIRQ                    (SDMA_CTRL1_Sl_MIRQ),
        // MPMC NPI Signals
        .PI_Addr                    (NPI_Addr[1*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[1]),
        .PI_AddrAck                 (NPI_AddrAck[1]),
        .PI_RdModWr                 (NPI_RdModWr[1]),
        .PI_RNW                     (NPI_RNW[1]),
        .PI_Size                    (NPI_Size[1*4 +: 4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[1*P_PIX_BE_WIDTH_MAX +: P_PIM1_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[1]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[1]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[1*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[1]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[1]),
        .PI_WrFIFO_Empty            (NPI_WrFIFO_Empty[1]),
        .PI_RdFIFO_DataAvailable    (NPI_RdFIFO_DataAvailable[1]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[1]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[1]),
        //.PI_InitDone                (NPI_InitDone[1]),
        // SDMA Signals
        .TX_D                       (SDMA1_TX_D),
        .TX_Rem                     (SDMA1_TX_Rem),
        .TX_SOF                     (SDMA1_TX_SOF),
        .TX_EOF                     (SDMA1_TX_EOF),
        .TX_SOP                     (SDMA1_TX_SOP),
        .TX_EOP                     (SDMA1_TX_EOP),
        .TX_Src_Rdy                 (SDMA1_TX_Src_Rdy),
        .TX_Dst_Rdy                 (SDMA1_TX_Dst_Rdy),
        .RX_D                       (SDMA1_RX_D),
        .RX_Rem                     (SDMA1_RX_Rem),
        .RX_SOF                     (SDMA1_RX_SOF),
        .RX_EOF                     (SDMA1_RX_EOF),
        .RX_SOP                     (SDMA1_RX_SOP),
        .RX_EOP                     (SDMA1_RX_EOP),
        .RX_Src_Rdy                 (SDMA1_RX_Src_Rdy),
        .RX_Dst_Rdy                 (SDMA1_RX_Dst_Rdy),
        .SDMA_RstOut                (SDMA1_RstOut),
        .SDMA_Rx_IntOut             (SDMA1_Rx_IntOut),
        .SDMA_Tx_IntOut             (SDMA1_Tx_IntOut)
      );
  end
  else if (C_NUM_PORTS > 1 && (C_PIM1_BASETYPE == 4)) begin : NPI1_INST
      // do nothing, pass signals straight through
      assign pim_rst[1] = 1'b0;
      assign PIM1_InitDone = NPI_InitDone[1];
      assign NPI_AddrReq[1] = PIM1_AddrReq;
      assign PIM1_AddrAck = NPI_AddrAck[1];
      assign NPI_Addr[1*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]    = PIM1_Addr;
      assign NPI_RNW[1] = PIM1_RNW;
      assign NPI_Size[1*4 +: 4] = PIM1_Size;
      assign NPI_RdModWr[1] = PIM1_RdModWr;
      assign NPI_WrFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH] = PIM1_WrFIFO_Data;
      assign NPI_WrFIFO_BE[1*P_PIX_BE_WIDTH_MAX +: P_PIM1_BE_WIDTH] = PIM1_WrFIFO_BE;
      assign NPI_WrFIFO_Push[1] = PIM1_WrFIFO_Push;
      assign PIM1_RdFIFO_Data = NPI_RdFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH];
      assign NPI_RdFIFO_Pop[1] = PIM1_RdFIFO_Pop;
      assign PIM1_RdFIFO_RdWdAddr = NPI_RdFIFO_RdWdAddr[1*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX];
      assign PIM1_WrFIFO_Empty = NPI_WrFIFO_Empty[1];
      assign PIM1_WrFIFO_AlmostFull = NPI_WrFIFO_AlmostFull[1];
      assign NPI_WrFIFO_Flush[1] = PIM1_WrFIFO_Flush;
      assign PIM1_RdFIFO_Empty = NPI_RdFIFO_Empty[1];
      assign NPI_RdFIFO_Flush[1] = PIM1_RdFIFO_Flush;
      assign PIM1_RdFIFO_Latency = NPI_RdFIFO_Latency[1*2 +: 2];
  end
  else if (C_NUM_PORTS > 1 && (C_PIM1_BASETYPE == 5)) begin : PPC440MC1_INST
      assign pim_rst[1] = 1'b0;
      mib_pim
      #(
        .C_MPMC_PIM_DATA_WIDTH          (P_PIM1_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH          (P_PIM1_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY      (P_PIM1_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH      (P_PIM1_RDWDADDR_WIDTH),
        .C_MPMC_PIM_MEM_DATA_WIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_BURST_LENGTH        (C_PPC440MC1_BURST_LENGTH),
        .C_MPMC_PIM_PIPE_STAGES         (C_PPC440MC1_PIPE_STAGES),
        .C_MPMC_PIM_WRFIFO_TYPE         (P_PI1_WR_FIFO_TYPE),
        .C_MPMC_PIM_OFFSET              (C_PIM1_OFFSET),
        .C_FAMILY                       (C_BASEFAMILY)
      )
      ppc440mc
      (
        .MPMC_Clk                       (MPMC_Clk0),
        .MPMC_Rst                       (Rst_topim[1]),
        .MPMC_PIM_Addr                  (NPI_Addr[1*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq               (NPI_AddrReq[1]),
        .MPMC_PIM_AddrAck               (NPI_AddrAck[1]),
        .MPMC_PIM_RdModWr               (NPI_RdModWr[1]),
        .MPMC_PIM_RNW                   (NPI_RNW[1]),
        .MPMC_PIM_Size                  (NPI_Size[1*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data           (NPI_WrFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE             (NPI_WrFIFO_BE[1*P_PIX_BE_WIDTH_MAX +: P_PIM1_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push           (NPI_WrFIFO_Push[1]),
        .MPMC_PIM_RdFIFO_Data           (NPI_RdFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop            (NPI_RdFIFO_Pop[1]),
        .MPMC_PIM_RdFIFO_RdWdAddr       (NPI_RdFIFO_RdWdAddr[1*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_WrFIFO_AlmostFull     (NPI_WrFIFO_AlmostFull[1]),
        .MPMC_PIM_WrFIFO_Flush          (NPI_WrFIFO_Flush[1]),
        .MPMC_PIM_WrFIFO_Empty          (NPI_WrFIFO_Empty[1]),
        .MPMC_PIM_RdFIFO_DataAvailable  (NPI_RdFIFO_DataAvailable[1]),
        .MPMC_PIM_RdFIFO_Empty          (NPI_RdFIFO_Empty[1]),
        .MPMC_PIM_RdFIFO_Flush          (NPI_RdFIFO_Flush[1]),
        .MPMC_PIM_InitDone              (NPI_InitDone[1]),
        .MPMC_PIM_Rd_FIFO_Latency       (NPI_RdFIFO_Latency[1*2 +: 2]),
        .mi_mcaddressvalid              (PPC440MC1_MIMCAddressValid),
        .mi_mcaddress                   (PPC440MC1_MIMCAddress),
        .mi_mcbankconflict              (PPC440MC1_MIMCBankConflict),
        .mi_mcrowconflict               (PPC440MC1_MIMCRowConflict),
        .mi_mcbyteenable                (PPC440MC1_MIMCByteEnable),
        .mi_mcwritedata                 (PPC440MC1_MIMCWriteData),
        .mi_mcreadnotwrite              (PPC440MC1_MIMCReadNotWrite),
        .mi_mcwritedatavalid            (PPC440MC1_MIMCWriteDataValid),
        .mc_miaddrreadytoaccept         (PPC440MC1_MCMIAddrReadyToAccept),
        .mc_mireaddata                  (PPC440MC1_MCMIReadData),
        .mc_mireaddataerr               (PPC440MC1_MCMIReadDataErr),
        .mc_mireaddatavalid             (PPC440MC1_MCMIReadDataValid)
    );
  end
  else if (C_NUM_PORTS > 1 && (C_PIM1_BASETYPE == 6)) begin : VFBC1_INST
      assign pim_rst[1] = 1'b0;
      assign NPI_RdModWr[1] = 1'b1;
      vfbc_pim_wrapper
      #(
        .C_MPMC_BASEADDR  (C_MPMC_BASEADDR[31:2]),
        .C_MPMC_HIGHADDR  (C_MPMC_HIGHADDR[31:2]),
        .C_PIM_DATA_WIDTH               (P_PIM1_DATA_WIDTH),
        .C_CHIPSCOPE_ENABLE             (P_VFBC1_CHIPSCOPE_ENABLE),
        .C_FAMILY                       (C_BASEFAMILY),
        .VFBC_BURST_LENGTH              (P_VFBC1_BURST_LENGTH),
        .CMD0_PORT_ID                   (P_VFBC1_CMD_PORT_ID),
        .CMD0_FIFO_DEPTH                (C_VFBC1_CMD_FIFO_DEPTH),
        .CMD0_ASYNC_CLOCK               (P_VFBC1_ASYNC_CLOCK),
        .CMD0_AFULL_COUNT               (C_VFBC1_CMD_AFULL_COUNT),
        .WD0_ENABLE                     (P_VFBC1_WD_ENABLE),
        .WD0_DATA_WIDTH                 (P_VFBC1_WD_DATA_WIDTH),
        .WD0_FIFO_DEPTH                 (P_VFBC1_WD_FIFO_DEPTH),
        .WD0_ASYNC_CLOCK                (P_VFBC1_ASYNC_CLOCK),
        .WD0_AFULL_COUNT                (P_VFBC1_WD_AFULL_COUNT),
        .WD0_BYTEEN_ENABLE              (P_VFBC1_WD_BYTEEN_ENABLE),
        .RD0_ENABLE                     (P_VFBC1_RD_ENABLE),
        .RD0_DATA_WIDTH                 (P_VFBC1_RD_DATA_WIDTH),
        .RD0_FIFO_DEPTH                 (P_VFBC1_RD_FIFO_DEPTH),
        .RD0_ASYNC_CLOCK                (P_VFBC1_ASYNC_CLOCK),
        .RD0_AEMPTY_COUNT               (P_VFBC1_RD_AEMPTY_COUNT)
      )
      vfbc
      (
        .vfbc_clk                       (MPMC_Clk0),
        .srst                           (Rst_topim[1]),
        .cmd0_clk                       (VFBC1_Cmd_Clk),
        .cmd0_reset                     (VFBC1_Cmd_Reset),
        .cmd0_data                      (VFBC1_Cmd_Data),
        .cmd0_write                     (VFBC1_Cmd_Write),
        .cmd0_end                       (VFBC1_Cmd_End),
        .cmd0_full                      (VFBC1_Cmd_Full),
        .cmd0_almost_full               (VFBC1_Cmd_Almost_Full),
        .cmd0_idle                      (VFBC1_Cmd_Idle),
        .wd0_clk                        (VFBC1_Wd_Clk),
        .wd0_reset                      (VFBC1_Wd_Reset),
        .wd0_write                      (VFBC1_Wd_Write),
        .wd0_end_burst                  (VFBC1_Wd_End_Burst),
        .wd0_flush                      (VFBC1_Wd_Flush),
        .wd0_data                       (VFBC1_Wd_Data),
        .wd0_data_be                    (VFBC1_Wd_Data_BE),
        .wd0_full                       (VFBC1_Wd_Full),
        .wd0_almost_full                (VFBC1_Wd_Almost_Full),
        .rd0_clk                        (VFBC1_Rd_Clk),
        .rd0_reset                      (VFBC1_Rd_Reset),
        .rd0_read                       (VFBC1_Rd_Read),
        .rd0_end_burst                  (VFBC1_Rd_End_Burst),
        .rd0_flush                      (VFBC1_Rd_Flush),
        .rd0_data                       (VFBC1_Rd_Data),
        .rd0_empty                      (VFBC1_Rd_Empty),
        .rd0_almost_empty               (VFBC1_Rd_Almost_Empty),
        .npi_init_done                  (NPI_InitDone[1]),
        .npi_addr_ack                   (NPI_AddrAck[1]),
        .npi_rdfifo_word_add            (NPI_RdFIFO_RdWdAddr[1*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .npi_rdfifo_data                (NPI_RdFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .npi_rdfifo_latency             (NPI_RdFIFO_Latency[1*2 +: 2]),
        .npi_rdfifo_empty               (NPI_RdFIFO_Empty[1]),
        .npi_wrfifo_almost_full         (NPI_WrFIFO_AlmostFull[1]),
        .npi_address                    (NPI_Addr[1*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .npi_addr_req                   (NPI_AddrReq[1]),
        .npi_size                       (NPI_Size[1*4 +: 4]),
        .npi_rnw                        (NPI_RNW[1]),
        .npi_rdfifo_pop                 (NPI_RdFIFO_Pop[1]),
        .npi_rdfifo_flush               (NPI_RdFIFO_Flush[1]),
        .npi_wrfifo_data                (NPI_WrFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH]),
        .npi_wrfifo_be                  (NPI_WrFIFO_BE[1*P_PIX_BE_WIDTH_MAX +: P_PIM1_BE_WIDTH]),
        .npi_wrfifo_push                (NPI_WrFIFO_Push[1]),
        .npi_wrfifo_flush               (NPI_WrFIFO_Flush[1])
//        .npi_rdmodwr                    (NPI_RdModWr[1])
    );
  end
  else begin : INACTIVE_1
      // tie off unused inputs to mpmc_core
      assign pim_rst[1] = 1'b0;
      if (C_NUM_PORTS > 1) begin : TIE_OFF_1
        assign NPI_Addr[1*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX] = 0;
        assign NPI_AddrReq[1] = 0;
        assign NPI_RNW[1] = 0;
        assign NPI_Size[1*4 +: 4] = 0;
        assign NPI_WrFIFO_Data[1*P_PIX_DATA_WIDTH_MAX +: P_PIM1_DATA_WIDTH] = 0;
        assign NPI_WrFIFO_BE[1*P_PIX_BE_WIDTH_MAX +: P_PIM1_BE_WIDTH] = 0;
        assign NPI_WrFIFO_Push[1] = 0;
        assign NPI_WrFIFO_Flush[1] = 0;
        assign NPI_RdFIFO_Pop[1] = 0;
        assign NPI_RdFIFO_Flush[1] = 0;
      end
    end
  endgenerate
  generate
  if (C_NUM_PORTS > 2 && C_PIM2_BASETYPE == 1)
    begin : DUALXCL2_INST
      assign pim_rst[2] = 1'b0;
      dualxcl
      #(
        .C_FAMILY                   (C_BASEFAMILY),
        .C_PI_A_SUBTYPE             (C_PIM2_SUBTYPE),
        .C_PI_B_SUBTYPE             (P_PIM2_B_SUBTYPE),
        .C_PI_BASEADDR              (P_PIM2_BASEADDR),
        .C_PI_HIGHADDR              (P_PIM2_HIGHADDR),
        .C_PI_OFFSET                (C_PIM2_OFFSET),
        .C_PI_ADDR_WIDTH            (P_PIM2_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM2_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM2_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM2_RDWDADDR_WIDTH),
        .C_PI_RDDATA_DELAY          (P_PIM2_RD_FIFO_LATENCY),
        .C_XCL_A_WRITEXFER          (C_XCL2_WRITEXFER),
        .C_XCL_A_LINESIZE           (C_XCL2_LINESIZE),
        .C_XCL_B_WRITEXFER          (C_XCL2_B_WRITEXFER),
        .C_XCL_B_LINESIZE           (C_XCL2_B_LINESIZE),
        .C_XCL_PIPE_STAGES          (C_XCL2_PIPE_STAGES),
        .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
        .C_MEM_SDR_DATA_WIDTH       (P_MEM_DATA_WIDTH_INT)
      )
      dualxcl_2
      (
        .Clk                        (FSL2_M_Clk),
        .Clk_MPMC                   (MPMC_Clk0),
        .Rst                        (Rst_topim[2]),
        .FSL_A_M_Clk                (FSL2_M_Clk),
        .FSL_A_M_Write              (FSL2_M_Write),
        .FSL_A_M_Data               (FSL2_M_Data),
        .FSL_A_M_Control            (FSL2_M_Control),
        .FSL_A_M_Full               (FSL2_M_Full),
        .FSL_A_S_Clk                (FSL2_S_Clk),
        .FSL_A_S_Read               (FSL2_S_Read),
        .FSL_A_S_Data               (FSL2_S_Data),
        .FSL_A_S_Control            (FSL2_S_Control),
        .FSL_A_S_Exists             (FSL2_S_Exists),
        .FSL_B_M_Clk                (FSL2_B_M_Clk),
        .FSL_B_M_Write              (FSL2_B_M_Write),
        .FSL_B_M_Data               (FSL2_B_M_Data),
        .FSL_B_M_Control            (FSL2_B_M_Control),
        .FSL_B_M_Full               (FSL2_B_M_Full),
        .FSL_B_S_Clk                (FSL2_B_S_Clk),
        .FSL_B_S_Read               (FSL2_B_S_Read),
        .FSL_B_S_Data               (FSL2_B_S_Data),
        .FSL_B_S_Control            (FSL2_B_S_Control),
        .FSL_B_S_Exists             (FSL2_B_S_Exists),
        .PI_Addr                    (NPI_Addr[2*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[2]),
        .PI_AddrAck                 (NPI_AddrAck[2]),
        .PI_RNW                     (NPI_RNW[2]),
        .PI_RdModWr                 (NPI_RdModWr[2]),
        .PI_Size                    (NPI_Size[2*4 +: 4]),
        .PI_InitDone                (NPI_InitDone[2]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[2*P_PIX_BE_WIDTH_MAX +: P_PIM2_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[2]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[2]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[2*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIM2_RDWDADDR_WIDTH]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[2]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[2]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[2]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[2])
      );
    end
  else if (C_NUM_PORTS > 2 && C_PIM2_BASETYPE == 2) begin : PLB_2_INST
      assign pim_rst[2] = SPLB2_Rst;
      plbv46_pim_wrapper
      #(
        .C_SPLB_DWIDTH              (C_SPLB2_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SPLB2_NATIVE_DWIDTH),
        .C_SPLB_AWIDTH              (C_SPLB2_AWIDTH),
        .C_SPLB_NUM_MASTERS         (C_SPLB2_NUM_MASTERS),
        .C_SPLB_MID_WIDTH           (C_SPLB2_MID_WIDTH),
        .C_SPLB_P2P                 (C_SPLB2_P2P),
        .C_SPLB_SUPPORT_BURSTS      (C_SPLB2_SUPPORT_BURSTS),
        .C_SPLB_SMALLEST_MASTER     (C_SPLB2_SMALLEST_MASTER),
        .C_PLBV46_PIM_TYPE          (C_PIM2_SUBTYPE),
        .C_MPMC_PIM_BASEADDR        (P_PIM2_BASEADDR[31:2]),
        .C_MPMC_PIM_HIGHADDR        (P_PIM2_HIGHADDR[31:2]),
        .C_MPMC_PIM_OFFSET          (C_PIM2_OFFSET[31:2]),
        .C_MPMC_PIM_DATA_WIDTH      (P_PIM2_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH      (P_PIM2_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY  (P_PIM2_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH  (P_PIM2_RDWDADDR_WIDTH),
        .C_MPMC_PIM_SDR_DWIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_MEM_HAS_BE      (P_MEM_HAS_BE),
        .C_MPMC_PIM_WR_FIFO_TYPE    (P_PI2_WR_FIFO_TYPE),
        .C_MPMC_PIM_RD_FIFO_TYPE    (P_PI2_RD_FIFO_TYPE),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      plbv46_pim_2
      (
        .MPMC_CLK                   (MPMC_Clk0),
        .MPMC_Rst                   (Rst_topim[2]),
        .SPLB_Clk                   (SPLB2_Clk),
        .SPLB_Rst                   (Rst_topim[2]),
        .SPLB_PLB_ABus              (SPLB2_PLB_ABus),
        .SPLB_PLB_UABus             (SPLB2_PLB_UABus),
        .SPLB_PLB_PAValid           (SPLB2_PLB_PAValid),
        .SPLB_PLB_SAValid           (SPLB2_PLB_SAValid),
        .SPLB_PLB_rdPrim            (SPLB2_PLB_rdPrim),
        .SPLB_PLB_wrPrim            (SPLB2_PLB_wrPrim),
        .SPLB_PLB_masterID          (SPLB2_PLB_masterID),
        .SPLB_PLB_abort             (SPLB2_PLB_abort),
        .SPLB_PLB_busLock           (SPLB2_PLB_busLock),
        .SPLB_PLB_RNW               (SPLB2_PLB_RNW),
        .SPLB_PLB_BE                (SPLB2_PLB_BE),
        .SPLB_PLB_MSize             (SPLB2_PLB_MSize),
        .SPLB_PLB_size              (SPLB2_PLB_size),
        .SPLB_PLB_type              (SPLB2_PLB_type),
        .SPLB_PLB_lockErr           (SPLB2_PLB_lockErr),
        .SPLB_PLB_wrDBus            (SPLB2_PLB_wrDBus),
        .SPLB_PLB_wrBurst           (SPLB2_PLB_wrBurst),
        .SPLB_PLB_rdBurst           (SPLB2_PLB_rdBurst),
        .SPLB_PLB_wrPendReq         (SPLB2_PLB_wrPendReq),
        .SPLB_PLB_rdPendReq         (SPLB2_PLB_rdPendReq),
        .SPLB_PLB_wrPendPri         (SPLB2_PLB_wrPendPri),
        .SPLB_PLB_rdPendPri         (SPLB2_PLB_rdPendPri),
        .SPLB_PLB_reqPri            (SPLB2_PLB_reqPri),
        .SPLB_PLB_TAttribute        (SPLB2_PLB_TAttribute),
        .SPLB_Sl_addrAck            (SPLB2_Sl_addrAck),
        .SPLB_Sl_SSize              (SPLB2_Sl_SSize),
        .SPLB_Sl_wait               (SPLB2_Sl_wait),
        .SPLB_Sl_rearbitrate        (SPLB2_Sl_rearbitrate),
        .SPLB_Sl_wrDAck             (SPLB2_Sl_wrDAck),
        .SPLB_Sl_wrComp             (SPLB2_Sl_wrComp),
        .SPLB_Sl_wrBTerm            (SPLB2_Sl_wrBTerm),
        .SPLB_Sl_rdDBus             (SPLB2_Sl_rdDBus),
        .SPLB_Sl_rdWdAddr           (SPLB2_Sl_rdWdAddr),
        .SPLB_Sl_rdDAck             (SPLB2_Sl_rdDAck),
        .SPLB_Sl_rdComp             (SPLB2_Sl_rdComp),
        .SPLB_Sl_rdBTerm            (SPLB2_Sl_rdBTerm),
        .SPLB_Sl_MBusy              (SPLB2_Sl_MBusy),
        .SPLB_Sl_MWrErr             (SPLB2_Sl_MWrErr),
        .SPLB_Sl_MRdErr             (SPLB2_Sl_MRdErr),
        .SPLB_Sl_MIRQ               (SPLB2_Sl_MIRQ),
        .MPMC_PIM_InitDone          (NPI_InitDone[2]),
        .MPMC_PIM_Addr              (NPI_Addr[2*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq           (NPI_AddrReq[2]),
        .MPMC_PIM_AddrAck           (NPI_AddrAck[2]),
        .MPMC_PIM_RNW               (NPI_RNW[2]),
        .MPMC_PIM_Size              (NPI_Size[2*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data       (NPI_WrFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE         (NPI_WrFIFO_BE[2*P_PIX_BE_WIDTH_MAX +: P_PIM2_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push       (NPI_WrFIFO_Push[2]),
        .MPMC_PIM_WrFIFO_Empty      (NPI_WrFIFO_Empty[2]),
        .MPMC_PIM_WrFIFO_AlmostFull (NPI_WrFIFO_AlmostFull[2]),
        .MPMC_PIM_RdFIFO_Latency    (NPI_RdFIFO_Latency[2*2 +: 2]),
        .MPMC_PIM_RdFIFO_Data       (NPI_RdFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop        (NPI_RdFIFO_Pop[2]),
        .MPMC_PIM_RdFIFO_Empty      (NPI_RdFIFO_Empty[2]),
        .MPMC_PIM_RdFIFO_RdWd_Addr  (NPI_RdFIFO_RdWdAddr[2*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_RdFIFO_Data_Available  (NPI_RdFIFO_DataAvailable[2]),
        .MPMC_PIM_RdFIFO_Flush      (NPI_RdFIFO_Flush[2]),
        .MPMC_PIM_WrFIFO_Flush      (NPI_WrFIFO_Flush[2]),
        .MPMC_PIM_RdModWr           (NPI_RdModWr[2])
      );
  end
  else if (C_NUM_PORTS > 2 && (C_PIM2_BASETYPE == 3)) begin : SDMA2_INST
      assign pim_rst[2] = SDMA_CTRL2_Rst;
      sdma_wrapper
      #(
        .C_PI_BASEADDR              (P_PIM2_BASEADDR[31:2]),
        .C_PI_HIGHADDR              (P_PIM2_HIGHADDR[31:2]),
        .C_PI_ADDR_WIDTH            (P_PIM2_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM2_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM2_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM2_RDWDADDR_WIDTH),
        .C_SDMA_BASEADDR            (P_SDMA_CTRL2_BASEADDR[31:2]),
        .C_SDMA_HIGHADDR            (P_SDMA_CTRL2_HIGHADDR[31:2]),
        .C_COMPLETED_ERR_TX         (C_SDMA2_COMPLETED_ERR_TX),
        .C_COMPLETED_ERR_RX         (C_SDMA2_COMPLETED_ERR_RX),
        .C_PRESCALAR                (C_SDMA2_PRESCALAR),
        .C_PI_RDDATA_DELAY          (P_PIM2_RD_FIFO_LATENCY),
        .C_PI2LL_CLK_RATIO          (C_SDMA2_PI2LL_CLK_RATIO),
        .C_SPLB_P2P                 (C_SDMA_CTRL2_P2P),
        .C_SPLB_MID_WIDTH           (C_SDMA_CTRL2_MID_WIDTH),
        .C_SPLB_NUM_MASTERS         (C_SDMA_CTRL2_NUM_MASTERS),
        .C_SPLB_AWIDTH              (C_SDMA_CTRL2_AWIDTH),
        .C_SPLB_DWIDTH              (C_SDMA_CTRL2_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SDMA_CTRL2_NATIVE_DWIDTH),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      mpmc_sdma_2
      (
        .LLink_Clk                  (SDMA2_Clk),
        .PI_Clk                     (MPMC_Clk0),
        // PLBv46 Signals
        .SPLB_Clk                   (SDMA_CTRL2_Clk),
        .SPLB_Rst                   (Rst_topim[2]),
        .PLB_ABus                   (SDMA_CTRL2_PLB_ABus),
        .PLB_UABus                  (SDMA_CTRL2_PLB_UABus),
        .PLB_PAValid                (SDMA_CTRL2_PLB_PAValid),
        .PLB_SAValid                (SDMA_CTRL2_PLB_SAValid),
        .PLB_rdPrim                 (SDMA_CTRL2_PLB_rdPrim),
        .PLB_wrPrim                 (SDMA_CTRL2_PLB_wrPrim),
        .PLB_masterID               (SDMA_CTRL2_PLB_masterID),
        .PLB_abort                  (SDMA_CTRL2_PLB_abort),
        .PLB_busLock                (SDMA_CTRL2_PLB_busLock),
        .PLB_RNW                    (SDMA_CTRL2_PLB_RNW),
        .PLB_BE                     (SDMA_CTRL2_PLB_BE),
        .PLB_MSize                  (SDMA_CTRL2_PLB_MSize),
        .PLB_size                   (SDMA_CTRL2_PLB_size),
        .PLB_type                   (SDMA_CTRL2_PLB_type),
        .PLB_lockErr                (SDMA_CTRL2_PLB_lockErr),
        .PLB_wrDBus                 (SDMA_CTRL2_PLB_wrDBus),
        .PLB_wrBurst                (SDMA_CTRL2_PLB_wrBurst),
        .PLB_rdBurst                (SDMA_CTRL2_PLB_rdBurst),
        .PLB_wrPendReq              (SDMA_CTRL2_PLB_wrPendReq),
        .PLB_rdPendReq              (SDMA_CTRL2_PLB_rdPendReq),
        .PLB_wrPendPri              (SDMA_CTRL2_PLB_wrPendPri),
        .PLB_rdPendPri              (SDMA_CTRL2_PLB_rdPendPri),
        .PLB_reqPri                 (SDMA_CTRL2_PLB_reqPri),
        .PLB_TAttribute             (SDMA_CTRL2_PLB_TAttribute),
        .Sln_addrAck                 (SDMA_CTRL2_Sl_addrAck),
        .Sln_SSize                   (SDMA_CTRL2_Sl_SSize),
        .Sln_wait                    (SDMA_CTRL2_Sl_wait),
        .Sln_rearbitrate             (SDMA_CTRL2_Sl_rearbitrate),
        .Sln_wrDAck                  (SDMA_CTRL2_Sl_wrDAck),
        .Sln_wrComp                  (SDMA_CTRL2_Sl_wrComp),
        .Sln_wrBTerm                 (SDMA_CTRL2_Sl_wrBTerm),
        .Sln_rdDBus                  (SDMA_CTRL2_Sl_rdDBus),
        .Sln_rdWdAddr                (SDMA_CTRL2_Sl_rdWdAddr),
        .Sln_rdDAck                  (SDMA_CTRL2_Sl_rdDAck),
        .Sln_rdComp                  (SDMA_CTRL2_Sl_rdComp),
        .Sln_rdBTerm                 (SDMA_CTRL2_Sl_rdBTerm),
        .Sln_MBusy                   (SDMA_CTRL2_Sl_MBusy),
        .Sln_MWrErr                  (SDMA_CTRL2_Sl_MWrErr),
        .Sln_MRdErr                  (SDMA_CTRL2_Sl_MRdErr),
        .Sln_MIRQ                    (SDMA_CTRL2_Sl_MIRQ),
        // MPMC NPI Signals
        .PI_Addr                    (NPI_Addr[2*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[2]),
        .PI_AddrAck                 (NPI_AddrAck[2]),
        .PI_RdModWr                 (NPI_RdModWr[2]),
        .PI_RNW                     (NPI_RNW[2]),
        .PI_Size                    (NPI_Size[2*4 +: 4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[2*P_PIX_BE_WIDTH_MAX +: P_PIM2_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[2]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[2]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[2*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[2]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[2]),
        .PI_WrFIFO_Empty            (NPI_WrFIFO_Empty[2]),
        .PI_RdFIFO_DataAvailable    (NPI_RdFIFO_DataAvailable[2]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[2]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[2]),
        //.PI_InitDone                (NPI_InitDone[2]),
        // SDMA Signals
        .TX_D                       (SDMA2_TX_D),
        .TX_Rem                     (SDMA2_TX_Rem),
        .TX_SOF                     (SDMA2_TX_SOF),
        .TX_EOF                     (SDMA2_TX_EOF),
        .TX_SOP                     (SDMA2_TX_SOP),
        .TX_EOP                     (SDMA2_TX_EOP),
        .TX_Src_Rdy                 (SDMA2_TX_Src_Rdy),
        .TX_Dst_Rdy                 (SDMA2_TX_Dst_Rdy),
        .RX_D                       (SDMA2_RX_D),
        .RX_Rem                     (SDMA2_RX_Rem),
        .RX_SOF                     (SDMA2_RX_SOF),
        .RX_EOF                     (SDMA2_RX_EOF),
        .RX_SOP                     (SDMA2_RX_SOP),
        .RX_EOP                     (SDMA2_RX_EOP),
        .RX_Src_Rdy                 (SDMA2_RX_Src_Rdy),
        .RX_Dst_Rdy                 (SDMA2_RX_Dst_Rdy),
        .SDMA_RstOut                (SDMA2_RstOut),
        .SDMA_Rx_IntOut             (SDMA2_Rx_IntOut),
        .SDMA_Tx_IntOut             (SDMA2_Tx_IntOut)
      );
  end
  else if (C_NUM_PORTS > 2 && (C_PIM2_BASETYPE == 4)) begin : NPI2_INST
      // do nothing, pass signals straight through
      assign pim_rst[2] = 1'b0;
      assign PIM2_InitDone = NPI_InitDone[2];
      assign NPI_AddrReq[2] = PIM2_AddrReq;
      assign PIM2_AddrAck = NPI_AddrAck[2];
      assign NPI_Addr[2*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]    = PIM2_Addr;
      assign NPI_RNW[2] = PIM2_RNW;
      assign NPI_Size[2*4 +: 4] = PIM2_Size;
      assign NPI_RdModWr[2] = PIM2_RdModWr;
      assign NPI_WrFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH] = PIM2_WrFIFO_Data;
      assign NPI_WrFIFO_BE[2*P_PIX_BE_WIDTH_MAX +: P_PIM2_BE_WIDTH] = PIM2_WrFIFO_BE;
      assign NPI_WrFIFO_Push[2] = PIM2_WrFIFO_Push;
      assign PIM2_RdFIFO_Data = NPI_RdFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH];
      assign NPI_RdFIFO_Pop[2] = PIM2_RdFIFO_Pop;
      assign PIM2_RdFIFO_RdWdAddr = NPI_RdFIFO_RdWdAddr[2*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX];
      assign PIM2_WrFIFO_Empty = NPI_WrFIFO_Empty[2];
      assign PIM2_WrFIFO_AlmostFull = NPI_WrFIFO_AlmostFull[2];
      assign NPI_WrFIFO_Flush[2] = PIM2_WrFIFO_Flush;
      assign PIM2_RdFIFO_Empty = NPI_RdFIFO_Empty[2];
      assign NPI_RdFIFO_Flush[2] = PIM2_RdFIFO_Flush;
      assign PIM2_RdFIFO_Latency = NPI_RdFIFO_Latency[2*2 +: 2];
  end
  else if (C_NUM_PORTS > 2 && (C_PIM2_BASETYPE == 5)) begin : PPC440MC2_INST
      assign pim_rst[2] = 1'b0;
      mib_pim
      #(
        .C_MPMC_PIM_DATA_WIDTH          (P_PIM2_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH          (P_PIM2_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY      (P_PIM2_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH      (P_PIM2_RDWDADDR_WIDTH),
        .C_MPMC_PIM_MEM_DATA_WIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_BURST_LENGTH        (C_PPC440MC2_BURST_LENGTH),
        .C_MPMC_PIM_PIPE_STAGES         (C_PPC440MC2_PIPE_STAGES),
        .C_MPMC_PIM_WRFIFO_TYPE         (P_PI2_WR_FIFO_TYPE),
        .C_MPMC_PIM_OFFSET              (C_PIM2_OFFSET),
        .C_FAMILY                       (C_BASEFAMILY)
      )
      ppc440mc
      (
        .MPMC_Clk                       (MPMC_Clk0),
        .MPMC_Rst                       (Rst_topim[2]),
        .MPMC_PIM_Addr                  (NPI_Addr[2*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq               (NPI_AddrReq[2]),
        .MPMC_PIM_AddrAck               (NPI_AddrAck[2]),
        .MPMC_PIM_RdModWr               (NPI_RdModWr[2]),
        .MPMC_PIM_RNW                   (NPI_RNW[2]),
        .MPMC_PIM_Size                  (NPI_Size[2*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data           (NPI_WrFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE             (NPI_WrFIFO_BE[2*P_PIX_BE_WIDTH_MAX +: P_PIM2_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push           (NPI_WrFIFO_Push[2]),
        .MPMC_PIM_RdFIFO_Data           (NPI_RdFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop            (NPI_RdFIFO_Pop[2]),
        .MPMC_PIM_RdFIFO_RdWdAddr       (NPI_RdFIFO_RdWdAddr[2*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_WrFIFO_AlmostFull     (NPI_WrFIFO_AlmostFull[2]),
        .MPMC_PIM_WrFIFO_Flush          (NPI_WrFIFO_Flush[2]),
        .MPMC_PIM_WrFIFO_Empty          (NPI_WrFIFO_Empty[2]),
        .MPMC_PIM_RdFIFO_DataAvailable  (NPI_RdFIFO_DataAvailable[2]),
        .MPMC_PIM_RdFIFO_Empty          (NPI_RdFIFO_Empty[2]),
        .MPMC_PIM_RdFIFO_Flush          (NPI_RdFIFO_Flush[2]),
        .MPMC_PIM_InitDone              (NPI_InitDone[2]),
        .MPMC_PIM_Rd_FIFO_Latency       (NPI_RdFIFO_Latency[2*2 +: 2]),
        .mi_mcaddressvalid              (PPC440MC2_MIMCAddressValid),
        .mi_mcaddress                   (PPC440MC2_MIMCAddress),
        .mi_mcbankconflict              (PPC440MC2_MIMCBankConflict),
        .mi_mcrowconflict               (PPC440MC2_MIMCRowConflict),
        .mi_mcbyteenable                (PPC440MC2_MIMCByteEnable),
        .mi_mcwritedata                 (PPC440MC2_MIMCWriteData),
        .mi_mcreadnotwrite              (PPC440MC2_MIMCReadNotWrite),
        .mi_mcwritedatavalid            (PPC440MC2_MIMCWriteDataValid),
        .mc_miaddrreadytoaccept         (PPC440MC2_MCMIAddrReadyToAccept),
        .mc_mireaddata                  (PPC440MC2_MCMIReadData),
        .mc_mireaddataerr               (PPC440MC2_MCMIReadDataErr),
        .mc_mireaddatavalid             (PPC440MC2_MCMIReadDataValid)
    );
  end
  else if (C_NUM_PORTS > 2 && (C_PIM2_BASETYPE == 6)) begin : VFBC2_INST
      assign pim_rst[2] = 1'b0;
      assign NPI_RdModWr[2] = 1'b1;
      vfbc_pim_wrapper
      #(
        .C_MPMC_BASEADDR  (C_MPMC_BASEADDR[31:2]),
        .C_MPMC_HIGHADDR  (C_MPMC_HIGHADDR[31:2]),
        .C_PIM_DATA_WIDTH               (P_PIM2_DATA_WIDTH),
        .C_CHIPSCOPE_ENABLE             (P_VFBC2_CHIPSCOPE_ENABLE),
        .C_FAMILY                       (C_BASEFAMILY),
        .VFBC_BURST_LENGTH              (P_VFBC2_BURST_LENGTH),
        .CMD0_PORT_ID                   (P_VFBC2_CMD_PORT_ID),
        .CMD0_FIFO_DEPTH                (C_VFBC2_CMD_FIFO_DEPTH),
        .CMD0_ASYNC_CLOCK               (P_VFBC2_ASYNC_CLOCK),
        .CMD0_AFULL_COUNT               (C_VFBC2_CMD_AFULL_COUNT),
        .WD0_ENABLE                     (P_VFBC2_WD_ENABLE),
        .WD0_DATA_WIDTH                 (P_VFBC2_WD_DATA_WIDTH),
        .WD0_FIFO_DEPTH                 (P_VFBC2_WD_FIFO_DEPTH),
        .WD0_ASYNC_CLOCK                (P_VFBC2_ASYNC_CLOCK),
        .WD0_AFULL_COUNT                (P_VFBC2_WD_AFULL_COUNT),
        .WD0_BYTEEN_ENABLE              (P_VFBC2_WD_BYTEEN_ENABLE),
        .RD0_ENABLE                     (P_VFBC2_RD_ENABLE),
        .RD0_DATA_WIDTH                 (P_VFBC2_RD_DATA_WIDTH),
        .RD0_FIFO_DEPTH                 (P_VFBC2_RD_FIFO_DEPTH),
        .RD0_ASYNC_CLOCK                (P_VFBC2_ASYNC_CLOCK),
        .RD0_AEMPTY_COUNT               (P_VFBC2_RD_AEMPTY_COUNT)
      )
      vfbc
      (
        .vfbc_clk                       (MPMC_Clk0),
        .srst                           (Rst_topim[2]),
        .cmd0_clk                       (VFBC2_Cmd_Clk),
        .cmd0_reset                     (VFBC2_Cmd_Reset),
        .cmd0_data                      (VFBC2_Cmd_Data),
        .cmd0_write                     (VFBC2_Cmd_Write),
        .cmd0_end                       (VFBC2_Cmd_End),
        .cmd0_full                      (VFBC2_Cmd_Full),
        .cmd0_almost_full               (VFBC2_Cmd_Almost_Full),
        .cmd0_idle                      (VFBC2_Cmd_Idle),
        .wd0_clk                        (VFBC2_Wd_Clk),
        .wd0_reset                      (VFBC2_Wd_Reset),
        .wd0_write                      (VFBC2_Wd_Write),
        .wd0_end_burst                  (VFBC2_Wd_End_Burst),
        .wd0_flush                      (VFBC2_Wd_Flush),
        .wd0_data                       (VFBC2_Wd_Data),
        .wd0_data_be                    (VFBC2_Wd_Data_BE),
        .wd0_full                       (VFBC2_Wd_Full),
        .wd0_almost_full                (VFBC2_Wd_Almost_Full),
        .rd0_clk                        (VFBC2_Rd_Clk),
        .rd0_reset                      (VFBC2_Rd_Reset),
        .rd0_read                       (VFBC2_Rd_Read),
        .rd0_end_burst                  (VFBC2_Rd_End_Burst),
        .rd0_flush                      (VFBC2_Rd_Flush),
        .rd0_data                       (VFBC2_Rd_Data),
        .rd0_empty                      (VFBC2_Rd_Empty),
        .rd0_almost_empty               (VFBC2_Rd_Almost_Empty),
        .npi_init_done                  (NPI_InitDone[2]),
        .npi_addr_ack                   (NPI_AddrAck[2]),
        .npi_rdfifo_word_add            (NPI_RdFIFO_RdWdAddr[2*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .npi_rdfifo_data                (NPI_RdFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .npi_rdfifo_latency             (NPI_RdFIFO_Latency[2*2 +: 2]),
        .npi_rdfifo_empty               (NPI_RdFIFO_Empty[2]),
        .npi_wrfifo_almost_full         (NPI_WrFIFO_AlmostFull[2]),
        .npi_address                    (NPI_Addr[2*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .npi_addr_req                   (NPI_AddrReq[2]),
        .npi_size                       (NPI_Size[2*4 +: 4]),
        .npi_rnw                        (NPI_RNW[2]),
        .npi_rdfifo_pop                 (NPI_RdFIFO_Pop[2]),
        .npi_rdfifo_flush               (NPI_RdFIFO_Flush[2]),
        .npi_wrfifo_data                (NPI_WrFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH]),
        .npi_wrfifo_be                  (NPI_WrFIFO_BE[2*P_PIX_BE_WIDTH_MAX +: P_PIM2_BE_WIDTH]),
        .npi_wrfifo_push                (NPI_WrFIFO_Push[2]),
        .npi_wrfifo_flush               (NPI_WrFIFO_Flush[2])
//        .npi_rdmodwr                    (NPI_RdModWr[2])
    );
  end
  else begin : INACTIVE_2
      // tie off unused inputs to mpmc_core
      assign pim_rst[2] = 1'b0;
      if (C_NUM_PORTS > 2) begin : TIE_OFF_2
        assign NPI_Addr[2*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX] = 0;
        assign NPI_AddrReq[2] = 0;
        assign NPI_RNW[2] = 0;
        assign NPI_Size[2*4 +: 4] = 0;
        assign NPI_WrFIFO_Data[2*P_PIX_DATA_WIDTH_MAX +: P_PIM2_DATA_WIDTH] = 0;
        assign NPI_WrFIFO_BE[2*P_PIX_BE_WIDTH_MAX +: P_PIM2_BE_WIDTH] = 0;
        assign NPI_WrFIFO_Push[2] = 0;
        assign NPI_WrFIFO_Flush[2] = 0;
        assign NPI_RdFIFO_Pop[2] = 0;
        assign NPI_RdFIFO_Flush[2] = 0;
      end
    end
  endgenerate
  generate
  if (C_NUM_PORTS > 3 && C_PIM3_BASETYPE == 1)
    begin : DUALXCL3_INST
      assign pim_rst[3] = 1'b0;
      dualxcl
      #(
        .C_FAMILY                   (C_BASEFAMILY),
        .C_PI_A_SUBTYPE             (C_PIM3_SUBTYPE),
        .C_PI_B_SUBTYPE             (P_PIM3_B_SUBTYPE),
        .C_PI_BASEADDR              (P_PIM3_BASEADDR),
        .C_PI_HIGHADDR              (P_PIM3_HIGHADDR),
        .C_PI_OFFSET                (C_PIM3_OFFSET),
        .C_PI_ADDR_WIDTH            (P_PIM3_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM3_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM3_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM3_RDWDADDR_WIDTH),
        .C_PI_RDDATA_DELAY          (P_PIM3_RD_FIFO_LATENCY),
        .C_XCL_A_WRITEXFER          (C_XCL3_WRITEXFER),
        .C_XCL_A_LINESIZE           (C_XCL3_LINESIZE),
        .C_XCL_B_WRITEXFER          (C_XCL3_B_WRITEXFER),
        .C_XCL_B_LINESIZE           (C_XCL3_B_LINESIZE),
        .C_XCL_PIPE_STAGES          (C_XCL3_PIPE_STAGES),
        .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
        .C_MEM_SDR_DATA_WIDTH       (P_MEM_DATA_WIDTH_INT)
      )
      dualxcl_3
      (
        .Clk                        (FSL3_M_Clk),
        .Clk_MPMC                   (MPMC_Clk0),
        .Rst                        (Rst_topim[3]),
        .FSL_A_M_Clk                (FSL3_M_Clk),
        .FSL_A_M_Write              (FSL3_M_Write),
        .FSL_A_M_Data               (FSL3_M_Data),
        .FSL_A_M_Control            (FSL3_M_Control),
        .FSL_A_M_Full               (FSL3_M_Full),
        .FSL_A_S_Clk                (FSL3_S_Clk),
        .FSL_A_S_Read               (FSL3_S_Read),
        .FSL_A_S_Data               (FSL3_S_Data),
        .FSL_A_S_Control            (FSL3_S_Control),
        .FSL_A_S_Exists             (FSL3_S_Exists),
        .FSL_B_M_Clk                (FSL3_B_M_Clk),
        .FSL_B_M_Write              (FSL3_B_M_Write),
        .FSL_B_M_Data               (FSL3_B_M_Data),
        .FSL_B_M_Control            (FSL3_B_M_Control),
        .FSL_B_M_Full               (FSL3_B_M_Full),
        .FSL_B_S_Clk                (FSL3_B_S_Clk),
        .FSL_B_S_Read               (FSL3_B_S_Read),
        .FSL_B_S_Data               (FSL3_B_S_Data),
        .FSL_B_S_Control            (FSL3_B_S_Control),
        .FSL_B_S_Exists             (FSL3_B_S_Exists),
        .PI_Addr                    (NPI_Addr[3*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[3]),
        .PI_AddrAck                 (NPI_AddrAck[3]),
        .PI_RNW                     (NPI_RNW[3]),
        .PI_RdModWr                 (NPI_RdModWr[3]),
        .PI_Size                    (NPI_Size[3*4 +: 4]),
        .PI_InitDone                (NPI_InitDone[3]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[3*P_PIX_BE_WIDTH_MAX +: P_PIM3_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[3]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[3]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[3*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIM3_RDWDADDR_WIDTH]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[3]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[3]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[3]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[3])
      );
    end
  else if (C_NUM_PORTS > 3 && C_PIM3_BASETYPE == 2) begin : PLB_3_INST
      assign pim_rst[3] = SPLB3_Rst;
      plbv46_pim_wrapper
      #(
        .C_SPLB_DWIDTH              (C_SPLB3_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SPLB3_NATIVE_DWIDTH),
        .C_SPLB_AWIDTH              (C_SPLB3_AWIDTH),
        .C_SPLB_NUM_MASTERS         (C_SPLB3_NUM_MASTERS),
        .C_SPLB_MID_WIDTH           (C_SPLB3_MID_WIDTH),
        .C_SPLB_P2P                 (C_SPLB3_P2P),
        .C_SPLB_SUPPORT_BURSTS      (C_SPLB3_SUPPORT_BURSTS),
        .C_SPLB_SMALLEST_MASTER     (C_SPLB3_SMALLEST_MASTER),
        .C_PLBV46_PIM_TYPE          (C_PIM3_SUBTYPE),
        .C_MPMC_PIM_BASEADDR        (P_PIM3_BASEADDR[31:2]),
        .C_MPMC_PIM_HIGHADDR        (P_PIM3_HIGHADDR[31:2]),
        .C_MPMC_PIM_OFFSET          (C_PIM3_OFFSET[31:2]),
        .C_MPMC_PIM_DATA_WIDTH      (P_PIM3_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH      (P_PIM3_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY  (P_PIM3_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH  (P_PIM3_RDWDADDR_WIDTH),
        .C_MPMC_PIM_SDR_DWIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_MEM_HAS_BE      (P_MEM_HAS_BE),
        .C_MPMC_PIM_WR_FIFO_TYPE    (P_PI3_WR_FIFO_TYPE),
        .C_MPMC_PIM_RD_FIFO_TYPE    (P_PI3_RD_FIFO_TYPE),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      plbv46_pim_3
      (
        .MPMC_CLK                   (MPMC_Clk0),
        .MPMC_Rst                   (Rst_topim[3]),
        .SPLB_Clk                   (SPLB3_Clk),
        .SPLB_Rst                   (Rst_topim[3]),
        .SPLB_PLB_ABus              (SPLB3_PLB_ABus),
        .SPLB_PLB_UABus             (SPLB3_PLB_UABus),
        .SPLB_PLB_PAValid           (SPLB3_PLB_PAValid),
        .SPLB_PLB_SAValid           (SPLB3_PLB_SAValid),
        .SPLB_PLB_rdPrim            (SPLB3_PLB_rdPrim),
        .SPLB_PLB_wrPrim            (SPLB3_PLB_wrPrim),
        .SPLB_PLB_masterID          (SPLB3_PLB_masterID),
        .SPLB_PLB_abort             (SPLB3_PLB_abort),
        .SPLB_PLB_busLock           (SPLB3_PLB_busLock),
        .SPLB_PLB_RNW               (SPLB3_PLB_RNW),
        .SPLB_PLB_BE                (SPLB3_PLB_BE),
        .SPLB_PLB_MSize             (SPLB3_PLB_MSize),
        .SPLB_PLB_size              (SPLB3_PLB_size),
        .SPLB_PLB_type              (SPLB3_PLB_type),
        .SPLB_PLB_lockErr           (SPLB3_PLB_lockErr),
        .SPLB_PLB_wrDBus            (SPLB3_PLB_wrDBus),
        .SPLB_PLB_wrBurst           (SPLB3_PLB_wrBurst),
        .SPLB_PLB_rdBurst           (SPLB3_PLB_rdBurst),
        .SPLB_PLB_wrPendReq         (SPLB3_PLB_wrPendReq),
        .SPLB_PLB_rdPendReq         (SPLB3_PLB_rdPendReq),
        .SPLB_PLB_wrPendPri         (SPLB3_PLB_wrPendPri),
        .SPLB_PLB_rdPendPri         (SPLB3_PLB_rdPendPri),
        .SPLB_PLB_reqPri            (SPLB3_PLB_reqPri),
        .SPLB_PLB_TAttribute        (SPLB3_PLB_TAttribute),
        .SPLB_Sl_addrAck            (SPLB3_Sl_addrAck),
        .SPLB_Sl_SSize              (SPLB3_Sl_SSize),
        .SPLB_Sl_wait               (SPLB3_Sl_wait),
        .SPLB_Sl_rearbitrate        (SPLB3_Sl_rearbitrate),
        .SPLB_Sl_wrDAck             (SPLB3_Sl_wrDAck),
        .SPLB_Sl_wrComp             (SPLB3_Sl_wrComp),
        .SPLB_Sl_wrBTerm            (SPLB3_Sl_wrBTerm),
        .SPLB_Sl_rdDBus             (SPLB3_Sl_rdDBus),
        .SPLB_Sl_rdWdAddr           (SPLB3_Sl_rdWdAddr),
        .SPLB_Sl_rdDAck             (SPLB3_Sl_rdDAck),
        .SPLB_Sl_rdComp             (SPLB3_Sl_rdComp),
        .SPLB_Sl_rdBTerm            (SPLB3_Sl_rdBTerm),
        .SPLB_Sl_MBusy              (SPLB3_Sl_MBusy),
        .SPLB_Sl_MWrErr             (SPLB3_Sl_MWrErr),
        .SPLB_Sl_MRdErr             (SPLB3_Sl_MRdErr),
        .SPLB_Sl_MIRQ               (SPLB3_Sl_MIRQ),
        .MPMC_PIM_InitDone          (NPI_InitDone[3]),
        .MPMC_PIM_Addr              (NPI_Addr[3*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq           (NPI_AddrReq[3]),
        .MPMC_PIM_AddrAck           (NPI_AddrAck[3]),
        .MPMC_PIM_RNW               (NPI_RNW[3]),
        .MPMC_PIM_Size              (NPI_Size[3*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data       (NPI_WrFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE         (NPI_WrFIFO_BE[3*P_PIX_BE_WIDTH_MAX +: P_PIM3_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push       (NPI_WrFIFO_Push[3]),
        .MPMC_PIM_WrFIFO_Empty      (NPI_WrFIFO_Empty[3]),
        .MPMC_PIM_WrFIFO_AlmostFull (NPI_WrFIFO_AlmostFull[3]),
        .MPMC_PIM_RdFIFO_Latency    (NPI_RdFIFO_Latency[3*2 +: 2]),
        .MPMC_PIM_RdFIFO_Data       (NPI_RdFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop        (NPI_RdFIFO_Pop[3]),
        .MPMC_PIM_RdFIFO_Empty      (NPI_RdFIFO_Empty[3]),
        .MPMC_PIM_RdFIFO_RdWd_Addr  (NPI_RdFIFO_RdWdAddr[3*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_RdFIFO_Data_Available  (NPI_RdFIFO_DataAvailable[3]),
        .MPMC_PIM_RdFIFO_Flush      (NPI_RdFIFO_Flush[3]),
        .MPMC_PIM_WrFIFO_Flush      (NPI_WrFIFO_Flush[3]),
        .MPMC_PIM_RdModWr           (NPI_RdModWr[3])
      );
  end
  else if (C_NUM_PORTS > 3 && (C_PIM3_BASETYPE == 3)) begin : SDMA3_INST
      assign pim_rst[3] = SDMA_CTRL3_Rst;
      sdma_wrapper
      #(
        .C_PI_BASEADDR              (P_PIM3_BASEADDR[31:2]),
        .C_PI_HIGHADDR              (P_PIM3_HIGHADDR[31:2]),
        .C_PI_ADDR_WIDTH            (P_PIM3_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM3_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM3_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM3_RDWDADDR_WIDTH),
        .C_SDMA_BASEADDR            (P_SDMA_CTRL3_BASEADDR[31:2]),
        .C_SDMA_HIGHADDR            (P_SDMA_CTRL3_HIGHADDR[31:2]),
        .C_COMPLETED_ERR_TX         (C_SDMA3_COMPLETED_ERR_TX),
        .C_COMPLETED_ERR_RX         (C_SDMA3_COMPLETED_ERR_RX),
        .C_PRESCALAR                (C_SDMA3_PRESCALAR),
        .C_PI_RDDATA_DELAY          (P_PIM3_RD_FIFO_LATENCY),
        .C_PI2LL_CLK_RATIO          (C_SDMA3_PI2LL_CLK_RATIO),
        .C_SPLB_P2P                 (C_SDMA_CTRL3_P2P),
        .C_SPLB_MID_WIDTH           (C_SDMA_CTRL3_MID_WIDTH),
        .C_SPLB_NUM_MASTERS         (C_SDMA_CTRL3_NUM_MASTERS),
        .C_SPLB_AWIDTH              (C_SDMA_CTRL3_AWIDTH),
        .C_SPLB_DWIDTH              (C_SDMA_CTRL3_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SDMA_CTRL3_NATIVE_DWIDTH),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      mpmc_sdma_3
      (
        .LLink_Clk                  (SDMA3_Clk),
        .PI_Clk                     (MPMC_Clk0),
        // PLBv46 Signals
        .SPLB_Clk                   (SDMA_CTRL3_Clk),
        .SPLB_Rst                   (Rst_topim[3]),
        .PLB_ABus                   (SDMA_CTRL3_PLB_ABus),
        .PLB_UABus                  (SDMA_CTRL3_PLB_UABus),
        .PLB_PAValid                (SDMA_CTRL3_PLB_PAValid),
        .PLB_SAValid                (SDMA_CTRL3_PLB_SAValid),
        .PLB_rdPrim                 (SDMA_CTRL3_PLB_rdPrim),
        .PLB_wrPrim                 (SDMA_CTRL3_PLB_wrPrim),
        .PLB_masterID               (SDMA_CTRL3_PLB_masterID),
        .PLB_abort                  (SDMA_CTRL3_PLB_abort),
        .PLB_busLock                (SDMA_CTRL3_PLB_busLock),
        .PLB_RNW                    (SDMA_CTRL3_PLB_RNW),
        .PLB_BE                     (SDMA_CTRL3_PLB_BE),
        .PLB_MSize                  (SDMA_CTRL3_PLB_MSize),
        .PLB_size                   (SDMA_CTRL3_PLB_size),
        .PLB_type                   (SDMA_CTRL3_PLB_type),
        .PLB_lockErr                (SDMA_CTRL3_PLB_lockErr),
        .PLB_wrDBus                 (SDMA_CTRL3_PLB_wrDBus),
        .PLB_wrBurst                (SDMA_CTRL3_PLB_wrBurst),
        .PLB_rdBurst                (SDMA_CTRL3_PLB_rdBurst),
        .PLB_wrPendReq              (SDMA_CTRL3_PLB_wrPendReq),
        .PLB_rdPendReq              (SDMA_CTRL3_PLB_rdPendReq),
        .PLB_wrPendPri              (SDMA_CTRL3_PLB_wrPendPri),
        .PLB_rdPendPri              (SDMA_CTRL3_PLB_rdPendPri),
        .PLB_reqPri                 (SDMA_CTRL3_PLB_reqPri),
        .PLB_TAttribute             (SDMA_CTRL3_PLB_TAttribute),
        .Sln_addrAck                 (SDMA_CTRL3_Sl_addrAck),
        .Sln_SSize                   (SDMA_CTRL3_Sl_SSize),
        .Sln_wait                    (SDMA_CTRL3_Sl_wait),
        .Sln_rearbitrate             (SDMA_CTRL3_Sl_rearbitrate),
        .Sln_wrDAck                  (SDMA_CTRL3_Sl_wrDAck),
        .Sln_wrComp                  (SDMA_CTRL3_Sl_wrComp),
        .Sln_wrBTerm                 (SDMA_CTRL3_Sl_wrBTerm),
        .Sln_rdDBus                  (SDMA_CTRL3_Sl_rdDBus),
        .Sln_rdWdAddr                (SDMA_CTRL3_Sl_rdWdAddr),
        .Sln_rdDAck                  (SDMA_CTRL3_Sl_rdDAck),
        .Sln_rdComp                  (SDMA_CTRL3_Sl_rdComp),
        .Sln_rdBTerm                 (SDMA_CTRL3_Sl_rdBTerm),
        .Sln_MBusy                   (SDMA_CTRL3_Sl_MBusy),
        .Sln_MWrErr                  (SDMA_CTRL3_Sl_MWrErr),
        .Sln_MRdErr                  (SDMA_CTRL3_Sl_MRdErr),
        .Sln_MIRQ                    (SDMA_CTRL3_Sl_MIRQ),
        // MPMC NPI Signals
        .PI_Addr                    (NPI_Addr[3*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[3]),
        .PI_AddrAck                 (NPI_AddrAck[3]),
        .PI_RdModWr                 (NPI_RdModWr[3]),
        .PI_RNW                     (NPI_RNW[3]),
        .PI_Size                    (NPI_Size[3*4 +: 4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[3*P_PIX_BE_WIDTH_MAX +: P_PIM3_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[3]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[3]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[3*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[3]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[3]),
        .PI_WrFIFO_Empty            (NPI_WrFIFO_Empty[3]),
        .PI_RdFIFO_DataAvailable    (NPI_RdFIFO_DataAvailable[3]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[3]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[3]),
        //.PI_InitDone                (NPI_InitDone[3]),
        // SDMA Signals
        .TX_D                       (SDMA3_TX_D),
        .TX_Rem                     (SDMA3_TX_Rem),
        .TX_SOF                     (SDMA3_TX_SOF),
        .TX_EOF                     (SDMA3_TX_EOF),
        .TX_SOP                     (SDMA3_TX_SOP),
        .TX_EOP                     (SDMA3_TX_EOP),
        .TX_Src_Rdy                 (SDMA3_TX_Src_Rdy),
        .TX_Dst_Rdy                 (SDMA3_TX_Dst_Rdy),
        .RX_D                       (SDMA3_RX_D),
        .RX_Rem                     (SDMA3_RX_Rem),
        .RX_SOF                     (SDMA3_RX_SOF),
        .RX_EOF                     (SDMA3_RX_EOF),
        .RX_SOP                     (SDMA3_RX_SOP),
        .RX_EOP                     (SDMA3_RX_EOP),
        .RX_Src_Rdy                 (SDMA3_RX_Src_Rdy),
        .RX_Dst_Rdy                 (SDMA3_RX_Dst_Rdy),
        .SDMA_RstOut                (SDMA3_RstOut),
        .SDMA_Rx_IntOut             (SDMA3_Rx_IntOut),
        .SDMA_Tx_IntOut             (SDMA3_Tx_IntOut)
      );
  end
  else if (C_NUM_PORTS > 3 && (C_PIM3_BASETYPE == 4)) begin : NPI3_INST
      // do nothing, pass signals straight through
      assign pim_rst[3] = 1'b0;
      assign PIM3_InitDone = NPI_InitDone[3];
      assign NPI_AddrReq[3] = PIM3_AddrReq;
      assign PIM3_AddrAck = NPI_AddrAck[3];
      assign NPI_Addr[3*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]    = PIM3_Addr;
      assign NPI_RNW[3] = PIM3_RNW;
      assign NPI_Size[3*4 +: 4] = PIM3_Size;
      assign NPI_RdModWr[3] = PIM3_RdModWr;
      assign NPI_WrFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH] = PIM3_WrFIFO_Data;
      assign NPI_WrFIFO_BE[3*P_PIX_BE_WIDTH_MAX +: P_PIM3_BE_WIDTH] = PIM3_WrFIFO_BE;
      assign NPI_WrFIFO_Push[3] = PIM3_WrFIFO_Push;
      assign PIM3_RdFIFO_Data = NPI_RdFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH];
      assign NPI_RdFIFO_Pop[3] = PIM3_RdFIFO_Pop;
      assign PIM3_RdFIFO_RdWdAddr = NPI_RdFIFO_RdWdAddr[3*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX];
      assign PIM3_WrFIFO_Empty = NPI_WrFIFO_Empty[3];
      assign PIM3_WrFIFO_AlmostFull = NPI_WrFIFO_AlmostFull[3];
      assign NPI_WrFIFO_Flush[3] = PIM3_WrFIFO_Flush;
      assign PIM3_RdFIFO_Empty = NPI_RdFIFO_Empty[3];
      assign NPI_RdFIFO_Flush[3] = PIM3_RdFIFO_Flush;
      assign PIM3_RdFIFO_Latency = NPI_RdFIFO_Latency[3*2 +: 2];
  end
  else if (C_NUM_PORTS > 3 && (C_PIM3_BASETYPE == 5)) begin : PPC440MC3_INST
      assign pim_rst[3] = 1'b0;
      mib_pim
      #(
        .C_MPMC_PIM_DATA_WIDTH          (P_PIM3_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH          (P_PIM3_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY      (P_PIM3_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH      (P_PIM3_RDWDADDR_WIDTH),
        .C_MPMC_PIM_MEM_DATA_WIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_BURST_LENGTH        (C_PPC440MC3_BURST_LENGTH),
        .C_MPMC_PIM_PIPE_STAGES         (C_PPC440MC3_PIPE_STAGES),
        .C_MPMC_PIM_WRFIFO_TYPE         (P_PI3_WR_FIFO_TYPE),
        .C_MPMC_PIM_OFFSET              (C_PIM3_OFFSET),
        .C_FAMILY                       (C_BASEFAMILY)
      )
      ppc440mc
      (
        .MPMC_Clk                       (MPMC_Clk0),
        .MPMC_Rst                       (Rst_topim[3]),
        .MPMC_PIM_Addr                  (NPI_Addr[3*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq               (NPI_AddrReq[3]),
        .MPMC_PIM_AddrAck               (NPI_AddrAck[3]),
        .MPMC_PIM_RdModWr               (NPI_RdModWr[3]),
        .MPMC_PIM_RNW                   (NPI_RNW[3]),
        .MPMC_PIM_Size                  (NPI_Size[3*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data           (NPI_WrFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE             (NPI_WrFIFO_BE[3*P_PIX_BE_WIDTH_MAX +: P_PIM3_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push           (NPI_WrFIFO_Push[3]),
        .MPMC_PIM_RdFIFO_Data           (NPI_RdFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop            (NPI_RdFIFO_Pop[3]),
        .MPMC_PIM_RdFIFO_RdWdAddr       (NPI_RdFIFO_RdWdAddr[3*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_WrFIFO_AlmostFull     (NPI_WrFIFO_AlmostFull[3]),
        .MPMC_PIM_WrFIFO_Flush          (NPI_WrFIFO_Flush[3]),
        .MPMC_PIM_WrFIFO_Empty          (NPI_WrFIFO_Empty[3]),
        .MPMC_PIM_RdFIFO_DataAvailable  (NPI_RdFIFO_DataAvailable[3]),
        .MPMC_PIM_RdFIFO_Empty          (NPI_RdFIFO_Empty[3]),
        .MPMC_PIM_RdFIFO_Flush          (NPI_RdFIFO_Flush[3]),
        .MPMC_PIM_InitDone              (NPI_InitDone[3]),
        .MPMC_PIM_Rd_FIFO_Latency       (NPI_RdFIFO_Latency[3*2 +: 2]),
        .mi_mcaddressvalid              (PPC440MC3_MIMCAddressValid),
        .mi_mcaddress                   (PPC440MC3_MIMCAddress),
        .mi_mcbankconflict              (PPC440MC3_MIMCBankConflict),
        .mi_mcrowconflict               (PPC440MC3_MIMCRowConflict),
        .mi_mcbyteenable                (PPC440MC3_MIMCByteEnable),
        .mi_mcwritedata                 (PPC440MC3_MIMCWriteData),
        .mi_mcreadnotwrite              (PPC440MC3_MIMCReadNotWrite),
        .mi_mcwritedatavalid            (PPC440MC3_MIMCWriteDataValid),
        .mc_miaddrreadytoaccept         (PPC440MC3_MCMIAddrReadyToAccept),
        .mc_mireaddata                  (PPC440MC3_MCMIReadData),
        .mc_mireaddataerr               (PPC440MC3_MCMIReadDataErr),
        .mc_mireaddatavalid             (PPC440MC3_MCMIReadDataValid)
    );
  end
  else if (C_NUM_PORTS > 3 && (C_PIM3_BASETYPE == 6)) begin : VFBC3_INST
      assign pim_rst[3] = 1'b0;
      assign NPI_RdModWr[3] = 1'b1;
      vfbc_pim_wrapper
      #(
        .C_MPMC_BASEADDR  (C_MPMC_BASEADDR[31:2]),
        .C_MPMC_HIGHADDR  (C_MPMC_HIGHADDR[31:2]),
        .C_PIM_DATA_WIDTH               (P_PIM3_DATA_WIDTH),
        .C_CHIPSCOPE_ENABLE             (P_VFBC3_CHIPSCOPE_ENABLE),
        .C_FAMILY                       (C_BASEFAMILY),
        .VFBC_BURST_LENGTH              (P_VFBC3_BURST_LENGTH),
        .CMD0_PORT_ID                   (P_VFBC3_CMD_PORT_ID),
        .CMD0_FIFO_DEPTH                (C_VFBC3_CMD_FIFO_DEPTH),
        .CMD0_ASYNC_CLOCK               (P_VFBC3_ASYNC_CLOCK),
        .CMD0_AFULL_COUNT               (C_VFBC3_CMD_AFULL_COUNT),
        .WD0_ENABLE                     (P_VFBC3_WD_ENABLE),
        .WD0_DATA_WIDTH                 (P_VFBC3_WD_DATA_WIDTH),
        .WD0_FIFO_DEPTH                 (P_VFBC3_WD_FIFO_DEPTH),
        .WD0_ASYNC_CLOCK                (P_VFBC3_ASYNC_CLOCK),
        .WD0_AFULL_COUNT                (P_VFBC3_WD_AFULL_COUNT),
        .WD0_BYTEEN_ENABLE              (P_VFBC3_WD_BYTEEN_ENABLE),
        .RD0_ENABLE                     (P_VFBC3_RD_ENABLE),
        .RD0_DATA_WIDTH                 (P_VFBC3_RD_DATA_WIDTH),
        .RD0_FIFO_DEPTH                 (P_VFBC3_RD_FIFO_DEPTH),
        .RD0_ASYNC_CLOCK                (P_VFBC3_ASYNC_CLOCK),
        .RD0_AEMPTY_COUNT               (P_VFBC3_RD_AEMPTY_COUNT)
      )
      vfbc
      (
        .vfbc_clk                       (MPMC_Clk0),
        .srst                           (Rst_topim[3]),
        .cmd0_clk                       (VFBC3_Cmd_Clk),
        .cmd0_reset                     (VFBC3_Cmd_Reset),
        .cmd0_data                      (VFBC3_Cmd_Data),
        .cmd0_write                     (VFBC3_Cmd_Write),
        .cmd0_end                       (VFBC3_Cmd_End),
        .cmd0_full                      (VFBC3_Cmd_Full),
        .cmd0_almost_full               (VFBC3_Cmd_Almost_Full),
        .cmd0_idle                      (VFBC3_Cmd_Idle),
        .wd0_clk                        (VFBC3_Wd_Clk),
        .wd0_reset                      (VFBC3_Wd_Reset),
        .wd0_write                      (VFBC3_Wd_Write),
        .wd0_end_burst                  (VFBC3_Wd_End_Burst),
        .wd0_flush                      (VFBC3_Wd_Flush),
        .wd0_data                       (VFBC3_Wd_Data),
        .wd0_data_be                    (VFBC3_Wd_Data_BE),
        .wd0_full                       (VFBC3_Wd_Full),
        .wd0_almost_full                (VFBC3_Wd_Almost_Full),
        .rd0_clk                        (VFBC3_Rd_Clk),
        .rd0_reset                      (VFBC3_Rd_Reset),
        .rd0_read                       (VFBC3_Rd_Read),
        .rd0_end_burst                  (VFBC3_Rd_End_Burst),
        .rd0_flush                      (VFBC3_Rd_Flush),
        .rd0_data                       (VFBC3_Rd_Data),
        .rd0_empty                      (VFBC3_Rd_Empty),
        .rd0_almost_empty               (VFBC3_Rd_Almost_Empty),
        .npi_init_done                  (NPI_InitDone[3]),
        .npi_addr_ack                   (NPI_AddrAck[3]),
        .npi_rdfifo_word_add            (NPI_RdFIFO_RdWdAddr[3*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .npi_rdfifo_data                (NPI_RdFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .npi_rdfifo_latency             (NPI_RdFIFO_Latency[3*2 +: 2]),
        .npi_rdfifo_empty               (NPI_RdFIFO_Empty[3]),
        .npi_wrfifo_almost_full         (NPI_WrFIFO_AlmostFull[3]),
        .npi_address                    (NPI_Addr[3*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .npi_addr_req                   (NPI_AddrReq[3]),
        .npi_size                       (NPI_Size[3*4 +: 4]),
        .npi_rnw                        (NPI_RNW[3]),
        .npi_rdfifo_pop                 (NPI_RdFIFO_Pop[3]),
        .npi_rdfifo_flush               (NPI_RdFIFO_Flush[3]),
        .npi_wrfifo_data                (NPI_WrFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH]),
        .npi_wrfifo_be                  (NPI_WrFIFO_BE[3*P_PIX_BE_WIDTH_MAX +: P_PIM3_BE_WIDTH]),
        .npi_wrfifo_push                (NPI_WrFIFO_Push[3]),
        .npi_wrfifo_flush               (NPI_WrFIFO_Flush[3])
//        .npi_rdmodwr                    (NPI_RdModWr[3])
    );
  end
  else begin : INACTIVE_3
      // tie off unused inputs to mpmc_core
      assign pim_rst[3] = 1'b0;
      if (C_NUM_PORTS > 3) begin : TIE_OFF_3
        assign NPI_Addr[3*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX] = 0;
        assign NPI_AddrReq[3] = 0;
        assign NPI_RNW[3] = 0;
        assign NPI_Size[3*4 +: 4] = 0;
        assign NPI_WrFIFO_Data[3*P_PIX_DATA_WIDTH_MAX +: P_PIM3_DATA_WIDTH] = 0;
        assign NPI_WrFIFO_BE[3*P_PIX_BE_WIDTH_MAX +: P_PIM3_BE_WIDTH] = 0;
        assign NPI_WrFIFO_Push[3] = 0;
        assign NPI_WrFIFO_Flush[3] = 0;
        assign NPI_RdFIFO_Pop[3] = 0;
        assign NPI_RdFIFO_Flush[3] = 0;
      end
    end
  endgenerate
  generate
  if (C_NUM_PORTS > 4 && C_PIM4_BASETYPE == 1)
    begin : DUALXCL4_INST
      assign pim_rst[4] = 1'b0;
      dualxcl
      #(
        .C_FAMILY                   (C_BASEFAMILY),
        .C_PI_A_SUBTYPE             (C_PIM4_SUBTYPE),
        .C_PI_B_SUBTYPE             (P_PIM4_B_SUBTYPE),
        .C_PI_BASEADDR              (P_PIM4_BASEADDR),
        .C_PI_HIGHADDR              (P_PIM4_HIGHADDR),
        .C_PI_OFFSET                (C_PIM4_OFFSET),
        .C_PI_ADDR_WIDTH            (P_PIM4_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM4_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM4_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM4_RDWDADDR_WIDTH),
        .C_PI_RDDATA_DELAY          (P_PIM4_RD_FIFO_LATENCY),
        .C_XCL_A_WRITEXFER          (C_XCL4_WRITEXFER),
        .C_XCL_A_LINESIZE           (C_XCL4_LINESIZE),
        .C_XCL_B_WRITEXFER          (C_XCL4_B_WRITEXFER),
        .C_XCL_B_LINESIZE           (C_XCL4_B_LINESIZE),
        .C_XCL_PIPE_STAGES          (C_XCL4_PIPE_STAGES),
        .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
        .C_MEM_SDR_DATA_WIDTH       (P_MEM_DATA_WIDTH_INT)
      )
      dualxcl_4
      (
        .Clk                        (FSL4_M_Clk),
        .Clk_MPMC                   (MPMC_Clk0),
        .Rst                        (Rst_topim[4]),
        .FSL_A_M_Clk                (FSL4_M_Clk),
        .FSL_A_M_Write              (FSL4_M_Write),
        .FSL_A_M_Data               (FSL4_M_Data),
        .FSL_A_M_Control            (FSL4_M_Control),
        .FSL_A_M_Full               (FSL4_M_Full),
        .FSL_A_S_Clk                (FSL4_S_Clk),
        .FSL_A_S_Read               (FSL4_S_Read),
        .FSL_A_S_Data               (FSL4_S_Data),
        .FSL_A_S_Control            (FSL4_S_Control),
        .FSL_A_S_Exists             (FSL4_S_Exists),
        .FSL_B_M_Clk                (FSL4_B_M_Clk),
        .FSL_B_M_Write              (FSL4_B_M_Write),
        .FSL_B_M_Data               (FSL4_B_M_Data),
        .FSL_B_M_Control            (FSL4_B_M_Control),
        .FSL_B_M_Full               (FSL4_B_M_Full),
        .FSL_B_S_Clk                (FSL4_B_S_Clk),
        .FSL_B_S_Read               (FSL4_B_S_Read),
        .FSL_B_S_Data               (FSL4_B_S_Data),
        .FSL_B_S_Control            (FSL4_B_S_Control),
        .FSL_B_S_Exists             (FSL4_B_S_Exists),
        .PI_Addr                    (NPI_Addr[4*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[4]),
        .PI_AddrAck                 (NPI_AddrAck[4]),
        .PI_RNW                     (NPI_RNW[4]),
        .PI_RdModWr                 (NPI_RdModWr[4]),
        .PI_Size                    (NPI_Size[4*4 +: 4]),
        .PI_InitDone                (NPI_InitDone[4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[4*P_PIX_BE_WIDTH_MAX +: P_PIM4_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[4]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[4]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[4*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIM4_RDWDADDR_WIDTH]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[4]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[4]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[4]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[4])
      );
    end
  else if (C_NUM_PORTS > 4 && C_PIM4_BASETYPE == 2) begin : PLB_4_INST
      assign pim_rst[4] = SPLB4_Rst;
      plbv46_pim_wrapper
      #(
        .C_SPLB_DWIDTH              (C_SPLB4_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SPLB4_NATIVE_DWIDTH),
        .C_SPLB_AWIDTH              (C_SPLB4_AWIDTH),
        .C_SPLB_NUM_MASTERS         (C_SPLB4_NUM_MASTERS),
        .C_SPLB_MID_WIDTH           (C_SPLB4_MID_WIDTH),
        .C_SPLB_P2P                 (C_SPLB4_P2P),
        .C_SPLB_SUPPORT_BURSTS      (C_SPLB4_SUPPORT_BURSTS),
        .C_SPLB_SMALLEST_MASTER     (C_SPLB4_SMALLEST_MASTER),
        .C_PLBV46_PIM_TYPE          (C_PIM4_SUBTYPE),
        .C_MPMC_PIM_BASEADDR        (P_PIM4_BASEADDR[31:2]),
        .C_MPMC_PIM_HIGHADDR        (P_PIM4_HIGHADDR[31:2]),
        .C_MPMC_PIM_OFFSET          (C_PIM4_OFFSET[31:2]),
        .C_MPMC_PIM_DATA_WIDTH      (P_PIM4_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH      (P_PIM4_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY  (P_PIM4_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH  (P_PIM4_RDWDADDR_WIDTH),
        .C_MPMC_PIM_SDR_DWIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_MEM_HAS_BE      (P_MEM_HAS_BE),
        .C_MPMC_PIM_WR_FIFO_TYPE    (P_PI4_WR_FIFO_TYPE),
        .C_MPMC_PIM_RD_FIFO_TYPE    (P_PI4_RD_FIFO_TYPE),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      plbv46_pim_4
      (
        .MPMC_CLK                   (MPMC_Clk0),
        .MPMC_Rst                   (Rst_topim[4]),
        .SPLB_Clk                   (SPLB4_Clk),
        .SPLB_Rst                   (Rst_topim[4]),
        .SPLB_PLB_ABus              (SPLB4_PLB_ABus),
        .SPLB_PLB_UABus             (SPLB4_PLB_UABus),
        .SPLB_PLB_PAValid           (SPLB4_PLB_PAValid),
        .SPLB_PLB_SAValid           (SPLB4_PLB_SAValid),
        .SPLB_PLB_rdPrim            (SPLB4_PLB_rdPrim),
        .SPLB_PLB_wrPrim            (SPLB4_PLB_wrPrim),
        .SPLB_PLB_masterID          (SPLB4_PLB_masterID),
        .SPLB_PLB_abort             (SPLB4_PLB_abort),
        .SPLB_PLB_busLock           (SPLB4_PLB_busLock),
        .SPLB_PLB_RNW               (SPLB4_PLB_RNW),
        .SPLB_PLB_BE                (SPLB4_PLB_BE),
        .SPLB_PLB_MSize             (SPLB4_PLB_MSize),
        .SPLB_PLB_size              (SPLB4_PLB_size),
        .SPLB_PLB_type              (SPLB4_PLB_type),
        .SPLB_PLB_lockErr           (SPLB4_PLB_lockErr),
        .SPLB_PLB_wrDBus            (SPLB4_PLB_wrDBus),
        .SPLB_PLB_wrBurst           (SPLB4_PLB_wrBurst),
        .SPLB_PLB_rdBurst           (SPLB4_PLB_rdBurst),
        .SPLB_PLB_wrPendReq         (SPLB4_PLB_wrPendReq),
        .SPLB_PLB_rdPendReq         (SPLB4_PLB_rdPendReq),
        .SPLB_PLB_wrPendPri         (SPLB4_PLB_wrPendPri),
        .SPLB_PLB_rdPendPri         (SPLB4_PLB_rdPendPri),
        .SPLB_PLB_reqPri            (SPLB4_PLB_reqPri),
        .SPLB_PLB_TAttribute        (SPLB4_PLB_TAttribute),
        .SPLB_Sl_addrAck            (SPLB4_Sl_addrAck),
        .SPLB_Sl_SSize              (SPLB4_Sl_SSize),
        .SPLB_Sl_wait               (SPLB4_Sl_wait),
        .SPLB_Sl_rearbitrate        (SPLB4_Sl_rearbitrate),
        .SPLB_Sl_wrDAck             (SPLB4_Sl_wrDAck),
        .SPLB_Sl_wrComp             (SPLB4_Sl_wrComp),
        .SPLB_Sl_wrBTerm            (SPLB4_Sl_wrBTerm),
        .SPLB_Sl_rdDBus             (SPLB4_Sl_rdDBus),
        .SPLB_Sl_rdWdAddr           (SPLB4_Sl_rdWdAddr),
        .SPLB_Sl_rdDAck             (SPLB4_Sl_rdDAck),
        .SPLB_Sl_rdComp             (SPLB4_Sl_rdComp),
        .SPLB_Sl_rdBTerm            (SPLB4_Sl_rdBTerm),
        .SPLB_Sl_MBusy              (SPLB4_Sl_MBusy),
        .SPLB_Sl_MWrErr             (SPLB4_Sl_MWrErr),
        .SPLB_Sl_MRdErr             (SPLB4_Sl_MRdErr),
        .SPLB_Sl_MIRQ               (SPLB4_Sl_MIRQ),
        .MPMC_PIM_InitDone          (NPI_InitDone[4]),
        .MPMC_PIM_Addr              (NPI_Addr[4*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq           (NPI_AddrReq[4]),
        .MPMC_PIM_AddrAck           (NPI_AddrAck[4]),
        .MPMC_PIM_RNW               (NPI_RNW[4]),
        .MPMC_PIM_Size              (NPI_Size[4*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data       (NPI_WrFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE         (NPI_WrFIFO_BE[4*P_PIX_BE_WIDTH_MAX +: P_PIM4_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push       (NPI_WrFIFO_Push[4]),
        .MPMC_PIM_WrFIFO_Empty      (NPI_WrFIFO_Empty[4]),
        .MPMC_PIM_WrFIFO_AlmostFull (NPI_WrFIFO_AlmostFull[4]),
        .MPMC_PIM_RdFIFO_Latency    (NPI_RdFIFO_Latency[4*2 +: 2]),
        .MPMC_PIM_RdFIFO_Data       (NPI_RdFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop        (NPI_RdFIFO_Pop[4]),
        .MPMC_PIM_RdFIFO_Empty      (NPI_RdFIFO_Empty[4]),
        .MPMC_PIM_RdFIFO_RdWd_Addr  (NPI_RdFIFO_RdWdAddr[4*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_RdFIFO_Data_Available  (NPI_RdFIFO_DataAvailable[4]),
        .MPMC_PIM_RdFIFO_Flush      (NPI_RdFIFO_Flush[4]),
        .MPMC_PIM_WrFIFO_Flush      (NPI_WrFIFO_Flush[4]),
        .MPMC_PIM_RdModWr           (NPI_RdModWr[4])
      );
  end
  else if (C_NUM_PORTS > 4 && (C_PIM4_BASETYPE == 3)) begin : SDMA4_INST
      assign pim_rst[4] = SDMA_CTRL4_Rst;
      sdma_wrapper
      #(
        .C_PI_BASEADDR              (P_PIM4_BASEADDR[31:2]),
        .C_PI_HIGHADDR              (P_PIM4_HIGHADDR[31:2]),
        .C_PI_ADDR_WIDTH            (P_PIM4_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM4_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM4_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM4_RDWDADDR_WIDTH),
        .C_SDMA_BASEADDR            (P_SDMA_CTRL4_BASEADDR[31:2]),
        .C_SDMA_HIGHADDR            (P_SDMA_CTRL4_HIGHADDR[31:2]),
        .C_COMPLETED_ERR_TX         (C_SDMA4_COMPLETED_ERR_TX),
        .C_COMPLETED_ERR_RX         (C_SDMA4_COMPLETED_ERR_RX),
        .C_PRESCALAR                (C_SDMA4_PRESCALAR),
        .C_PI_RDDATA_DELAY          (P_PIM4_RD_FIFO_LATENCY),
        .C_PI2LL_CLK_RATIO          (C_SDMA4_PI2LL_CLK_RATIO),
        .C_SPLB_P2P                 (C_SDMA_CTRL4_P2P),
        .C_SPLB_MID_WIDTH           (C_SDMA_CTRL4_MID_WIDTH),
        .C_SPLB_NUM_MASTERS         (C_SDMA_CTRL4_NUM_MASTERS),
        .C_SPLB_AWIDTH              (C_SDMA_CTRL4_AWIDTH),
        .C_SPLB_DWIDTH              (C_SDMA_CTRL4_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SDMA_CTRL4_NATIVE_DWIDTH),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      mpmc_sdma_4
      (
        .LLink_Clk                  (SDMA4_Clk),
        .PI_Clk                     (MPMC_Clk0),
        // PLBv46 Signals
        .SPLB_Clk                   (SDMA_CTRL4_Clk),
        .SPLB_Rst                   (Rst_topim[4]),
        .PLB_ABus                   (SDMA_CTRL4_PLB_ABus),
        .PLB_UABus                  (SDMA_CTRL4_PLB_UABus),
        .PLB_PAValid                (SDMA_CTRL4_PLB_PAValid),
        .PLB_SAValid                (SDMA_CTRL4_PLB_SAValid),
        .PLB_rdPrim                 (SDMA_CTRL4_PLB_rdPrim),
        .PLB_wrPrim                 (SDMA_CTRL4_PLB_wrPrim),
        .PLB_masterID               (SDMA_CTRL4_PLB_masterID),
        .PLB_abort                  (SDMA_CTRL4_PLB_abort),
        .PLB_busLock                (SDMA_CTRL4_PLB_busLock),
        .PLB_RNW                    (SDMA_CTRL4_PLB_RNW),
        .PLB_BE                     (SDMA_CTRL4_PLB_BE),
        .PLB_MSize                  (SDMA_CTRL4_PLB_MSize),
        .PLB_size                   (SDMA_CTRL4_PLB_size),
        .PLB_type                   (SDMA_CTRL4_PLB_type),
        .PLB_lockErr                (SDMA_CTRL4_PLB_lockErr),
        .PLB_wrDBus                 (SDMA_CTRL4_PLB_wrDBus),
        .PLB_wrBurst                (SDMA_CTRL4_PLB_wrBurst),
        .PLB_rdBurst                (SDMA_CTRL4_PLB_rdBurst),
        .PLB_wrPendReq              (SDMA_CTRL4_PLB_wrPendReq),
        .PLB_rdPendReq              (SDMA_CTRL4_PLB_rdPendReq),
        .PLB_wrPendPri              (SDMA_CTRL4_PLB_wrPendPri),
        .PLB_rdPendPri              (SDMA_CTRL4_PLB_rdPendPri),
        .PLB_reqPri                 (SDMA_CTRL4_PLB_reqPri),
        .PLB_TAttribute             (SDMA_CTRL4_PLB_TAttribute),
        .Sln_addrAck                 (SDMA_CTRL4_Sl_addrAck),
        .Sln_SSize                   (SDMA_CTRL4_Sl_SSize),
        .Sln_wait                    (SDMA_CTRL4_Sl_wait),
        .Sln_rearbitrate             (SDMA_CTRL4_Sl_rearbitrate),
        .Sln_wrDAck                  (SDMA_CTRL4_Sl_wrDAck),
        .Sln_wrComp                  (SDMA_CTRL4_Sl_wrComp),
        .Sln_wrBTerm                 (SDMA_CTRL4_Sl_wrBTerm),
        .Sln_rdDBus                  (SDMA_CTRL4_Sl_rdDBus),
        .Sln_rdWdAddr                (SDMA_CTRL4_Sl_rdWdAddr),
        .Sln_rdDAck                  (SDMA_CTRL4_Sl_rdDAck),
        .Sln_rdComp                  (SDMA_CTRL4_Sl_rdComp),
        .Sln_rdBTerm                 (SDMA_CTRL4_Sl_rdBTerm),
        .Sln_MBusy                   (SDMA_CTRL4_Sl_MBusy),
        .Sln_MWrErr                  (SDMA_CTRL4_Sl_MWrErr),
        .Sln_MRdErr                  (SDMA_CTRL4_Sl_MRdErr),
        .Sln_MIRQ                    (SDMA_CTRL4_Sl_MIRQ),
        // MPMC NPI Signals
        .PI_Addr                    (NPI_Addr[4*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[4]),
        .PI_AddrAck                 (NPI_AddrAck[4]),
        .PI_RdModWr                 (NPI_RdModWr[4]),
        .PI_RNW                     (NPI_RNW[4]),
        .PI_Size                    (NPI_Size[4*4 +: 4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[4*P_PIX_BE_WIDTH_MAX +: P_PIM4_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[4]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[4]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[4*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[4]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[4]),
        .PI_WrFIFO_Empty            (NPI_WrFIFO_Empty[4]),
        .PI_RdFIFO_DataAvailable    (NPI_RdFIFO_DataAvailable[4]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[4]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[4]),
        //.PI_InitDone                (NPI_InitDone[4]),
        // SDMA Signals
        .TX_D                       (SDMA4_TX_D),
        .TX_Rem                     (SDMA4_TX_Rem),
        .TX_SOF                     (SDMA4_TX_SOF),
        .TX_EOF                     (SDMA4_TX_EOF),
        .TX_SOP                     (SDMA4_TX_SOP),
        .TX_EOP                     (SDMA4_TX_EOP),
        .TX_Src_Rdy                 (SDMA4_TX_Src_Rdy),
        .TX_Dst_Rdy                 (SDMA4_TX_Dst_Rdy),
        .RX_D                       (SDMA4_RX_D),
        .RX_Rem                     (SDMA4_RX_Rem),
        .RX_SOF                     (SDMA4_RX_SOF),
        .RX_EOF                     (SDMA4_RX_EOF),
        .RX_SOP                     (SDMA4_RX_SOP),
        .RX_EOP                     (SDMA4_RX_EOP),
        .RX_Src_Rdy                 (SDMA4_RX_Src_Rdy),
        .RX_Dst_Rdy                 (SDMA4_RX_Dst_Rdy),
        .SDMA_RstOut                (SDMA4_RstOut),
        .SDMA_Rx_IntOut             (SDMA4_Rx_IntOut),
        .SDMA_Tx_IntOut             (SDMA4_Tx_IntOut)
      );
  end
  else if (C_NUM_PORTS > 4 && (C_PIM4_BASETYPE == 4)) begin : NPI4_INST
      // do nothing, pass signals straight through
      assign pim_rst[4] = 1'b0;
      assign PIM4_InitDone = NPI_InitDone[4];
      assign NPI_AddrReq[4] = PIM4_AddrReq;
      assign PIM4_AddrAck = NPI_AddrAck[4];
      assign NPI_Addr[4*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]    = PIM4_Addr;
      assign NPI_RNW[4] = PIM4_RNW;
      assign NPI_Size[4*4 +: 4] = PIM4_Size;
      assign NPI_RdModWr[4] = PIM4_RdModWr;
      assign NPI_WrFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH] = PIM4_WrFIFO_Data;
      assign NPI_WrFIFO_BE[4*P_PIX_BE_WIDTH_MAX +: P_PIM4_BE_WIDTH] = PIM4_WrFIFO_BE;
      assign NPI_WrFIFO_Push[4] = PIM4_WrFIFO_Push;
      assign PIM4_RdFIFO_Data = NPI_RdFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH];
      assign NPI_RdFIFO_Pop[4] = PIM4_RdFIFO_Pop;
      assign PIM4_RdFIFO_RdWdAddr = NPI_RdFIFO_RdWdAddr[4*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX];
      assign PIM4_WrFIFO_Empty = NPI_WrFIFO_Empty[4];
      assign PIM4_WrFIFO_AlmostFull = NPI_WrFIFO_AlmostFull[4];
      assign NPI_WrFIFO_Flush[4] = PIM4_WrFIFO_Flush;
      assign PIM4_RdFIFO_Empty = NPI_RdFIFO_Empty[4];
      assign NPI_RdFIFO_Flush[4] = PIM4_RdFIFO_Flush;
      assign PIM4_RdFIFO_Latency = NPI_RdFIFO_Latency[4*2 +: 2];
  end
  else if (C_NUM_PORTS > 4 && (C_PIM4_BASETYPE == 5)) begin : PPC440MC4_INST
      assign pim_rst[4] = 1'b0;
      mib_pim
      #(
        .C_MPMC_PIM_DATA_WIDTH          (P_PIM4_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH          (P_PIM4_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY      (P_PIM4_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH      (P_PIM4_RDWDADDR_WIDTH),
        .C_MPMC_PIM_MEM_DATA_WIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_BURST_LENGTH        (C_PPC440MC4_BURST_LENGTH),
        .C_MPMC_PIM_PIPE_STAGES         (C_PPC440MC4_PIPE_STAGES),
        .C_MPMC_PIM_WRFIFO_TYPE         (P_PI4_WR_FIFO_TYPE),
        .C_MPMC_PIM_OFFSET              (C_PIM4_OFFSET),
        .C_FAMILY                       (C_BASEFAMILY)
      )
      ppc440mc
      (
        .MPMC_Clk                       (MPMC_Clk0),
        .MPMC_Rst                       (Rst_topim[4]),
        .MPMC_PIM_Addr                  (NPI_Addr[4*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq               (NPI_AddrReq[4]),
        .MPMC_PIM_AddrAck               (NPI_AddrAck[4]),
        .MPMC_PIM_RdModWr               (NPI_RdModWr[4]),
        .MPMC_PIM_RNW                   (NPI_RNW[4]),
        .MPMC_PIM_Size                  (NPI_Size[4*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data           (NPI_WrFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE             (NPI_WrFIFO_BE[4*P_PIX_BE_WIDTH_MAX +: P_PIM4_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push           (NPI_WrFIFO_Push[4]),
        .MPMC_PIM_RdFIFO_Data           (NPI_RdFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop            (NPI_RdFIFO_Pop[4]),
        .MPMC_PIM_RdFIFO_RdWdAddr       (NPI_RdFIFO_RdWdAddr[4*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_WrFIFO_AlmostFull     (NPI_WrFIFO_AlmostFull[4]),
        .MPMC_PIM_WrFIFO_Flush          (NPI_WrFIFO_Flush[4]),
        .MPMC_PIM_WrFIFO_Empty          (NPI_WrFIFO_Empty[4]),
        .MPMC_PIM_RdFIFO_DataAvailable  (NPI_RdFIFO_DataAvailable[4]),
        .MPMC_PIM_RdFIFO_Empty          (NPI_RdFIFO_Empty[4]),
        .MPMC_PIM_RdFIFO_Flush          (NPI_RdFIFO_Flush[4]),
        .MPMC_PIM_InitDone              (NPI_InitDone[4]),
        .MPMC_PIM_Rd_FIFO_Latency       (NPI_RdFIFO_Latency[4*2 +: 2]),
        .mi_mcaddressvalid              (PPC440MC4_MIMCAddressValid),
        .mi_mcaddress                   (PPC440MC4_MIMCAddress),
        .mi_mcbankconflict              (PPC440MC4_MIMCBankConflict),
        .mi_mcrowconflict               (PPC440MC4_MIMCRowConflict),
        .mi_mcbyteenable                (PPC440MC4_MIMCByteEnable),
        .mi_mcwritedata                 (PPC440MC4_MIMCWriteData),
        .mi_mcreadnotwrite              (PPC440MC4_MIMCReadNotWrite),
        .mi_mcwritedatavalid            (PPC440MC4_MIMCWriteDataValid),
        .mc_miaddrreadytoaccept         (PPC440MC4_MCMIAddrReadyToAccept),
        .mc_mireaddata                  (PPC440MC4_MCMIReadData),
        .mc_mireaddataerr               (PPC440MC4_MCMIReadDataErr),
        .mc_mireaddatavalid             (PPC440MC4_MCMIReadDataValid)
    );
  end
  else if (C_NUM_PORTS > 4 && (C_PIM4_BASETYPE == 6)) begin : VFBC4_INST
      assign pim_rst[4] = 1'b0;
      assign NPI_RdModWr[4] = 1'b1;
      vfbc_pim_wrapper
      #(
        .C_MPMC_BASEADDR  (C_MPMC_BASEADDR[31:2]),
        .C_MPMC_HIGHADDR  (C_MPMC_HIGHADDR[31:2]),
        .C_PIM_DATA_WIDTH               (P_PIM4_DATA_WIDTH),
        .C_CHIPSCOPE_ENABLE             (P_VFBC4_CHIPSCOPE_ENABLE),
        .C_FAMILY                       (C_BASEFAMILY),
        .VFBC_BURST_LENGTH              (P_VFBC4_BURST_LENGTH),
        .CMD0_PORT_ID                   (P_VFBC4_CMD_PORT_ID),
        .CMD0_FIFO_DEPTH                (C_VFBC4_CMD_FIFO_DEPTH),
        .CMD0_ASYNC_CLOCK               (P_VFBC4_ASYNC_CLOCK),
        .CMD0_AFULL_COUNT               (C_VFBC4_CMD_AFULL_COUNT),
        .WD0_ENABLE                     (P_VFBC4_WD_ENABLE),
        .WD0_DATA_WIDTH                 (P_VFBC4_WD_DATA_WIDTH),
        .WD0_FIFO_DEPTH                 (P_VFBC4_WD_FIFO_DEPTH),
        .WD0_ASYNC_CLOCK                (P_VFBC4_ASYNC_CLOCK),
        .WD0_AFULL_COUNT                (P_VFBC4_WD_AFULL_COUNT),
        .WD0_BYTEEN_ENABLE              (P_VFBC4_WD_BYTEEN_ENABLE),
        .RD0_ENABLE                     (P_VFBC4_RD_ENABLE),
        .RD0_DATA_WIDTH                 (P_VFBC4_RD_DATA_WIDTH),
        .RD0_FIFO_DEPTH                 (P_VFBC4_RD_FIFO_DEPTH),
        .RD0_ASYNC_CLOCK                (P_VFBC4_ASYNC_CLOCK),
        .RD0_AEMPTY_COUNT               (P_VFBC4_RD_AEMPTY_COUNT)
      )
      vfbc
      (
        .vfbc_clk                       (MPMC_Clk0),
        .srst                           (Rst_topim[4]),
        .cmd0_clk                       (VFBC4_Cmd_Clk),
        .cmd0_reset                     (VFBC4_Cmd_Reset),
        .cmd0_data                      (VFBC4_Cmd_Data),
        .cmd0_write                     (VFBC4_Cmd_Write),
        .cmd0_end                       (VFBC4_Cmd_End),
        .cmd0_full                      (VFBC4_Cmd_Full),
        .cmd0_almost_full               (VFBC4_Cmd_Almost_Full),
        .cmd0_idle                      (VFBC4_Cmd_Idle),
        .wd0_clk                        (VFBC4_Wd_Clk),
        .wd0_reset                      (VFBC4_Wd_Reset),
        .wd0_write                      (VFBC4_Wd_Write),
        .wd0_end_burst                  (VFBC4_Wd_End_Burst),
        .wd0_flush                      (VFBC4_Wd_Flush),
        .wd0_data                       (VFBC4_Wd_Data),
        .wd0_data_be                    (VFBC4_Wd_Data_BE),
        .wd0_full                       (VFBC4_Wd_Full),
        .wd0_almost_full                (VFBC4_Wd_Almost_Full),
        .rd0_clk                        (VFBC4_Rd_Clk),
        .rd0_reset                      (VFBC4_Rd_Reset),
        .rd0_read                       (VFBC4_Rd_Read),
        .rd0_end_burst                  (VFBC4_Rd_End_Burst),
        .rd0_flush                      (VFBC4_Rd_Flush),
        .rd0_data                       (VFBC4_Rd_Data),
        .rd0_empty                      (VFBC4_Rd_Empty),
        .rd0_almost_empty               (VFBC4_Rd_Almost_Empty),
        .npi_init_done                  (NPI_InitDone[4]),
        .npi_addr_ack                   (NPI_AddrAck[4]),
        .npi_rdfifo_word_add            (NPI_RdFIFO_RdWdAddr[4*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .npi_rdfifo_data                (NPI_RdFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .npi_rdfifo_latency             (NPI_RdFIFO_Latency[4*2 +: 2]),
        .npi_rdfifo_empty               (NPI_RdFIFO_Empty[4]),
        .npi_wrfifo_almost_full         (NPI_WrFIFO_AlmostFull[4]),
        .npi_address                    (NPI_Addr[4*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .npi_addr_req                   (NPI_AddrReq[4]),
        .npi_size                       (NPI_Size[4*4 +: 4]),
        .npi_rnw                        (NPI_RNW[4]),
        .npi_rdfifo_pop                 (NPI_RdFIFO_Pop[4]),
        .npi_rdfifo_flush               (NPI_RdFIFO_Flush[4]),
        .npi_wrfifo_data                (NPI_WrFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH]),
        .npi_wrfifo_be                  (NPI_WrFIFO_BE[4*P_PIX_BE_WIDTH_MAX +: P_PIM4_BE_WIDTH]),
        .npi_wrfifo_push                (NPI_WrFIFO_Push[4]),
        .npi_wrfifo_flush               (NPI_WrFIFO_Flush[4])
//        .npi_rdmodwr                    (NPI_RdModWr[4])
    );
  end
  else begin : INACTIVE_4
      // tie off unused inputs to mpmc_core
      assign pim_rst[4] = 1'b0;
      if (C_NUM_PORTS > 4) begin : TIE_OFF_4
        assign NPI_Addr[4*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX] = 0;
        assign NPI_AddrReq[4] = 0;
        assign NPI_RNW[4] = 0;
        assign NPI_Size[4*4 +: 4] = 0;
        assign NPI_WrFIFO_Data[4*P_PIX_DATA_WIDTH_MAX +: P_PIM4_DATA_WIDTH] = 0;
        assign NPI_WrFIFO_BE[4*P_PIX_BE_WIDTH_MAX +: P_PIM4_BE_WIDTH] = 0;
        assign NPI_WrFIFO_Push[4] = 0;
        assign NPI_WrFIFO_Flush[4] = 0;
        assign NPI_RdFIFO_Pop[4] = 0;
        assign NPI_RdFIFO_Flush[4] = 0;
      end
    end
  endgenerate
  generate
  if (C_NUM_PORTS > 5 && C_PIM5_BASETYPE == 1)
    begin : DUALXCL5_INST
      assign pim_rst[5] = 1'b0;
      dualxcl
      #(
        .C_FAMILY                   (C_BASEFAMILY),
        .C_PI_A_SUBTYPE             (C_PIM5_SUBTYPE),
        .C_PI_B_SUBTYPE             (P_PIM5_B_SUBTYPE),
        .C_PI_BASEADDR              (P_PIM5_BASEADDR),
        .C_PI_HIGHADDR              (P_PIM5_HIGHADDR),
        .C_PI_OFFSET                (C_PIM5_OFFSET),
        .C_PI_ADDR_WIDTH            (P_PIM5_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM5_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM5_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM5_RDWDADDR_WIDTH),
        .C_PI_RDDATA_DELAY          (P_PIM5_RD_FIFO_LATENCY),
        .C_XCL_A_WRITEXFER          (C_XCL5_WRITEXFER),
        .C_XCL_A_LINESIZE           (C_XCL5_LINESIZE),
        .C_XCL_B_WRITEXFER          (C_XCL5_B_WRITEXFER),
        .C_XCL_B_LINESIZE           (C_XCL5_B_LINESIZE),
        .C_XCL_PIPE_STAGES          (C_XCL5_PIPE_STAGES),
        .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
        .C_MEM_SDR_DATA_WIDTH       (P_MEM_DATA_WIDTH_INT)
      )
      dualxcl_5
      (
        .Clk                        (FSL5_M_Clk),
        .Clk_MPMC                   (MPMC_Clk0),
        .Rst                        (Rst_topim[5]),
        .FSL_A_M_Clk                (FSL5_M_Clk),
        .FSL_A_M_Write              (FSL5_M_Write),
        .FSL_A_M_Data               (FSL5_M_Data),
        .FSL_A_M_Control            (FSL5_M_Control),
        .FSL_A_M_Full               (FSL5_M_Full),
        .FSL_A_S_Clk                (FSL5_S_Clk),
        .FSL_A_S_Read               (FSL5_S_Read),
        .FSL_A_S_Data               (FSL5_S_Data),
        .FSL_A_S_Control            (FSL5_S_Control),
        .FSL_A_S_Exists             (FSL5_S_Exists),
        .FSL_B_M_Clk                (FSL5_B_M_Clk),
        .FSL_B_M_Write              (FSL5_B_M_Write),
        .FSL_B_M_Data               (FSL5_B_M_Data),
        .FSL_B_M_Control            (FSL5_B_M_Control),
        .FSL_B_M_Full               (FSL5_B_M_Full),
        .FSL_B_S_Clk                (FSL5_B_S_Clk),
        .FSL_B_S_Read               (FSL5_B_S_Read),
        .FSL_B_S_Data               (FSL5_B_S_Data),
        .FSL_B_S_Control            (FSL5_B_S_Control),
        .FSL_B_S_Exists             (FSL5_B_S_Exists),
        .PI_Addr                    (NPI_Addr[5*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[5]),
        .PI_AddrAck                 (NPI_AddrAck[5]),
        .PI_RNW                     (NPI_RNW[5]),
        .PI_RdModWr                 (NPI_RdModWr[5]),
        .PI_Size                    (NPI_Size[5*4 +: 4]),
        .PI_InitDone                (NPI_InitDone[5]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[5*P_PIX_BE_WIDTH_MAX +: P_PIM5_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[5]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[5]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[5*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIM5_RDWDADDR_WIDTH]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[5]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[5]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[5]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[5])
      );
    end
  else if (C_NUM_PORTS > 5 && C_PIM5_BASETYPE == 2) begin : PLB_5_INST
      assign pim_rst[5] = SPLB5_Rst;
      plbv46_pim_wrapper
      #(
        .C_SPLB_DWIDTH              (C_SPLB5_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SPLB5_NATIVE_DWIDTH),
        .C_SPLB_AWIDTH              (C_SPLB5_AWIDTH),
        .C_SPLB_NUM_MASTERS         (C_SPLB5_NUM_MASTERS),
        .C_SPLB_MID_WIDTH           (C_SPLB5_MID_WIDTH),
        .C_SPLB_P2P                 (C_SPLB5_P2P),
        .C_SPLB_SUPPORT_BURSTS      (C_SPLB5_SUPPORT_BURSTS),
        .C_SPLB_SMALLEST_MASTER     (C_SPLB5_SMALLEST_MASTER),
        .C_PLBV46_PIM_TYPE          (C_PIM5_SUBTYPE),
        .C_MPMC_PIM_BASEADDR        (P_PIM5_BASEADDR[31:2]),
        .C_MPMC_PIM_HIGHADDR        (P_PIM5_HIGHADDR[31:2]),
        .C_MPMC_PIM_OFFSET          (C_PIM5_OFFSET[31:2]),
        .C_MPMC_PIM_DATA_WIDTH      (P_PIM5_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH      (P_PIM5_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY  (P_PIM5_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH  (P_PIM5_RDWDADDR_WIDTH),
        .C_MPMC_PIM_SDR_DWIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_MEM_HAS_BE      (P_MEM_HAS_BE),
        .C_MPMC_PIM_WR_FIFO_TYPE    (P_PI5_WR_FIFO_TYPE),
        .C_MPMC_PIM_RD_FIFO_TYPE    (P_PI5_RD_FIFO_TYPE),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      plbv46_pim_5
      (
        .MPMC_CLK                   (MPMC_Clk0),
        .MPMC_Rst                   (Rst_topim[5]),
        .SPLB_Clk                   (SPLB5_Clk),
        .SPLB_Rst                   (Rst_topim[5]),
        .SPLB_PLB_ABus              (SPLB5_PLB_ABus),
        .SPLB_PLB_UABus             (SPLB5_PLB_UABus),
        .SPLB_PLB_PAValid           (SPLB5_PLB_PAValid),
        .SPLB_PLB_SAValid           (SPLB5_PLB_SAValid),
        .SPLB_PLB_rdPrim            (SPLB5_PLB_rdPrim),
        .SPLB_PLB_wrPrim            (SPLB5_PLB_wrPrim),
        .SPLB_PLB_masterID          (SPLB5_PLB_masterID),
        .SPLB_PLB_abort             (SPLB5_PLB_abort),
        .SPLB_PLB_busLock           (SPLB5_PLB_busLock),
        .SPLB_PLB_RNW               (SPLB5_PLB_RNW),
        .SPLB_PLB_BE                (SPLB5_PLB_BE),
        .SPLB_PLB_MSize             (SPLB5_PLB_MSize),
        .SPLB_PLB_size              (SPLB5_PLB_size),
        .SPLB_PLB_type              (SPLB5_PLB_type),
        .SPLB_PLB_lockErr           (SPLB5_PLB_lockErr),
        .SPLB_PLB_wrDBus            (SPLB5_PLB_wrDBus),
        .SPLB_PLB_wrBurst           (SPLB5_PLB_wrBurst),
        .SPLB_PLB_rdBurst           (SPLB5_PLB_rdBurst),
        .SPLB_PLB_wrPendReq         (SPLB5_PLB_wrPendReq),
        .SPLB_PLB_rdPendReq         (SPLB5_PLB_rdPendReq),
        .SPLB_PLB_wrPendPri         (SPLB5_PLB_wrPendPri),
        .SPLB_PLB_rdPendPri         (SPLB5_PLB_rdPendPri),
        .SPLB_PLB_reqPri            (SPLB5_PLB_reqPri),
        .SPLB_PLB_TAttribute        (SPLB5_PLB_TAttribute),
        .SPLB_Sl_addrAck            (SPLB5_Sl_addrAck),
        .SPLB_Sl_SSize              (SPLB5_Sl_SSize),
        .SPLB_Sl_wait               (SPLB5_Sl_wait),
        .SPLB_Sl_rearbitrate        (SPLB5_Sl_rearbitrate),
        .SPLB_Sl_wrDAck             (SPLB5_Sl_wrDAck),
        .SPLB_Sl_wrComp             (SPLB5_Sl_wrComp),
        .SPLB_Sl_wrBTerm            (SPLB5_Sl_wrBTerm),
        .SPLB_Sl_rdDBus             (SPLB5_Sl_rdDBus),
        .SPLB_Sl_rdWdAddr           (SPLB5_Sl_rdWdAddr),
        .SPLB_Sl_rdDAck             (SPLB5_Sl_rdDAck),
        .SPLB_Sl_rdComp             (SPLB5_Sl_rdComp),
        .SPLB_Sl_rdBTerm            (SPLB5_Sl_rdBTerm),
        .SPLB_Sl_MBusy              (SPLB5_Sl_MBusy),
        .SPLB_Sl_MWrErr             (SPLB5_Sl_MWrErr),
        .SPLB_Sl_MRdErr             (SPLB5_Sl_MRdErr),
        .SPLB_Sl_MIRQ               (SPLB5_Sl_MIRQ),
        .MPMC_PIM_InitDone          (NPI_InitDone[5]),
        .MPMC_PIM_Addr              (NPI_Addr[5*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq           (NPI_AddrReq[5]),
        .MPMC_PIM_AddrAck           (NPI_AddrAck[5]),
        .MPMC_PIM_RNW               (NPI_RNW[5]),
        .MPMC_PIM_Size              (NPI_Size[5*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data       (NPI_WrFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE         (NPI_WrFIFO_BE[5*P_PIX_BE_WIDTH_MAX +: P_PIM5_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push       (NPI_WrFIFO_Push[5]),
        .MPMC_PIM_WrFIFO_Empty      (NPI_WrFIFO_Empty[5]),
        .MPMC_PIM_WrFIFO_AlmostFull (NPI_WrFIFO_AlmostFull[5]),
        .MPMC_PIM_RdFIFO_Latency    (NPI_RdFIFO_Latency[5*2 +: 2]),
        .MPMC_PIM_RdFIFO_Data       (NPI_RdFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop        (NPI_RdFIFO_Pop[5]),
        .MPMC_PIM_RdFIFO_Empty      (NPI_RdFIFO_Empty[5]),
        .MPMC_PIM_RdFIFO_RdWd_Addr  (NPI_RdFIFO_RdWdAddr[5*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_RdFIFO_Data_Available  (NPI_RdFIFO_DataAvailable[5]),
        .MPMC_PIM_RdFIFO_Flush      (NPI_RdFIFO_Flush[5]),
        .MPMC_PIM_WrFIFO_Flush      (NPI_WrFIFO_Flush[5]),
        .MPMC_PIM_RdModWr           (NPI_RdModWr[5])
      );
  end
  else if (C_NUM_PORTS > 5 && (C_PIM5_BASETYPE == 3)) begin : SDMA5_INST
      assign pim_rst[5] = SDMA_CTRL5_Rst;
      sdma_wrapper
      #(
        .C_PI_BASEADDR              (P_PIM5_BASEADDR[31:2]),
        .C_PI_HIGHADDR              (P_PIM5_HIGHADDR[31:2]),
        .C_PI_ADDR_WIDTH            (P_PIM5_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM5_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM5_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM5_RDWDADDR_WIDTH),
        .C_SDMA_BASEADDR            (P_SDMA_CTRL5_BASEADDR[31:2]),
        .C_SDMA_HIGHADDR            (P_SDMA_CTRL5_HIGHADDR[31:2]),
        .C_COMPLETED_ERR_TX         (C_SDMA5_COMPLETED_ERR_TX),
        .C_COMPLETED_ERR_RX         (C_SDMA5_COMPLETED_ERR_RX),
        .C_PRESCALAR                (C_SDMA5_PRESCALAR),
        .C_PI_RDDATA_DELAY          (P_PIM5_RD_FIFO_LATENCY),
        .C_PI2LL_CLK_RATIO          (C_SDMA5_PI2LL_CLK_RATIO),
        .C_SPLB_P2P                 (C_SDMA_CTRL5_P2P),
        .C_SPLB_MID_WIDTH           (C_SDMA_CTRL5_MID_WIDTH),
        .C_SPLB_NUM_MASTERS         (C_SDMA_CTRL5_NUM_MASTERS),
        .C_SPLB_AWIDTH              (C_SDMA_CTRL5_AWIDTH),
        .C_SPLB_DWIDTH              (C_SDMA_CTRL5_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SDMA_CTRL5_NATIVE_DWIDTH),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      mpmc_sdma_5
      (
        .LLink_Clk                  (SDMA5_Clk),
        .PI_Clk                     (MPMC_Clk0),
        // PLBv46 Signals
        .SPLB_Clk                   (SDMA_CTRL5_Clk),
        .SPLB_Rst                   (Rst_topim[5]),
        .PLB_ABus                   (SDMA_CTRL5_PLB_ABus),
        .PLB_UABus                  (SDMA_CTRL5_PLB_UABus),
        .PLB_PAValid                (SDMA_CTRL5_PLB_PAValid),
        .PLB_SAValid                (SDMA_CTRL5_PLB_SAValid),
        .PLB_rdPrim                 (SDMA_CTRL5_PLB_rdPrim),
        .PLB_wrPrim                 (SDMA_CTRL5_PLB_wrPrim),
        .PLB_masterID               (SDMA_CTRL5_PLB_masterID),
        .PLB_abort                  (SDMA_CTRL5_PLB_abort),
        .PLB_busLock                (SDMA_CTRL5_PLB_busLock),
        .PLB_RNW                    (SDMA_CTRL5_PLB_RNW),
        .PLB_BE                     (SDMA_CTRL5_PLB_BE),
        .PLB_MSize                  (SDMA_CTRL5_PLB_MSize),
        .PLB_size                   (SDMA_CTRL5_PLB_size),
        .PLB_type                   (SDMA_CTRL5_PLB_type),
        .PLB_lockErr                (SDMA_CTRL5_PLB_lockErr),
        .PLB_wrDBus                 (SDMA_CTRL5_PLB_wrDBus),
        .PLB_wrBurst                (SDMA_CTRL5_PLB_wrBurst),
        .PLB_rdBurst                (SDMA_CTRL5_PLB_rdBurst),
        .PLB_wrPendReq              (SDMA_CTRL5_PLB_wrPendReq),
        .PLB_rdPendReq              (SDMA_CTRL5_PLB_rdPendReq),
        .PLB_wrPendPri              (SDMA_CTRL5_PLB_wrPendPri),
        .PLB_rdPendPri              (SDMA_CTRL5_PLB_rdPendPri),
        .PLB_reqPri                 (SDMA_CTRL5_PLB_reqPri),
        .PLB_TAttribute             (SDMA_CTRL5_PLB_TAttribute),
        .Sln_addrAck                 (SDMA_CTRL5_Sl_addrAck),
        .Sln_SSize                   (SDMA_CTRL5_Sl_SSize),
        .Sln_wait                    (SDMA_CTRL5_Sl_wait),
        .Sln_rearbitrate             (SDMA_CTRL5_Sl_rearbitrate),
        .Sln_wrDAck                  (SDMA_CTRL5_Sl_wrDAck),
        .Sln_wrComp                  (SDMA_CTRL5_Sl_wrComp),
        .Sln_wrBTerm                 (SDMA_CTRL5_Sl_wrBTerm),
        .Sln_rdDBus                  (SDMA_CTRL5_Sl_rdDBus),
        .Sln_rdWdAddr                (SDMA_CTRL5_Sl_rdWdAddr),
        .Sln_rdDAck                  (SDMA_CTRL5_Sl_rdDAck),
        .Sln_rdComp                  (SDMA_CTRL5_Sl_rdComp),
        .Sln_rdBTerm                 (SDMA_CTRL5_Sl_rdBTerm),
        .Sln_MBusy                   (SDMA_CTRL5_Sl_MBusy),
        .Sln_MWrErr                  (SDMA_CTRL5_Sl_MWrErr),
        .Sln_MRdErr                  (SDMA_CTRL5_Sl_MRdErr),
        .Sln_MIRQ                    (SDMA_CTRL5_Sl_MIRQ),
        // MPMC NPI Signals
        .PI_Addr                    (NPI_Addr[5*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[5]),
        .PI_AddrAck                 (NPI_AddrAck[5]),
        .PI_RdModWr                 (NPI_RdModWr[5]),
        .PI_RNW                     (NPI_RNW[5]),
        .PI_Size                    (NPI_Size[5*4 +: 4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[5*P_PIX_BE_WIDTH_MAX +: P_PIM5_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[5]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[5]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[5*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[5]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[5]),
        .PI_WrFIFO_Empty            (NPI_WrFIFO_Empty[5]),
        .PI_RdFIFO_DataAvailable    (NPI_RdFIFO_DataAvailable[5]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[5]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[5]),
        //.PI_InitDone                (NPI_InitDone[5]),
        // SDMA Signals
        .TX_D                       (SDMA5_TX_D),
        .TX_Rem                     (SDMA5_TX_Rem),
        .TX_SOF                     (SDMA5_TX_SOF),
        .TX_EOF                     (SDMA5_TX_EOF),
        .TX_SOP                     (SDMA5_TX_SOP),
        .TX_EOP                     (SDMA5_TX_EOP),
        .TX_Src_Rdy                 (SDMA5_TX_Src_Rdy),
        .TX_Dst_Rdy                 (SDMA5_TX_Dst_Rdy),
        .RX_D                       (SDMA5_RX_D),
        .RX_Rem                     (SDMA5_RX_Rem),
        .RX_SOF                     (SDMA5_RX_SOF),
        .RX_EOF                     (SDMA5_RX_EOF),
        .RX_SOP                     (SDMA5_RX_SOP),
        .RX_EOP                     (SDMA5_RX_EOP),
        .RX_Src_Rdy                 (SDMA5_RX_Src_Rdy),
        .RX_Dst_Rdy                 (SDMA5_RX_Dst_Rdy),
        .SDMA_RstOut                (SDMA5_RstOut),
        .SDMA_Rx_IntOut             (SDMA5_Rx_IntOut),
        .SDMA_Tx_IntOut             (SDMA5_Tx_IntOut)
      );
  end
  else if (C_NUM_PORTS > 5 && (C_PIM5_BASETYPE == 4)) begin : NPI5_INST
      // do nothing, pass signals straight through
      assign pim_rst[5] = 1'b0;
      assign PIM5_InitDone = NPI_InitDone[5];
      assign NPI_AddrReq[5] = PIM5_AddrReq;
      assign PIM5_AddrAck = NPI_AddrAck[5];
      assign NPI_Addr[5*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]    = PIM5_Addr;
      assign NPI_RNW[5] = PIM5_RNW;
      assign NPI_Size[5*4 +: 4] = PIM5_Size;
      assign NPI_RdModWr[5] = PIM5_RdModWr;
      assign NPI_WrFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH] = PIM5_WrFIFO_Data;
      assign NPI_WrFIFO_BE[5*P_PIX_BE_WIDTH_MAX +: P_PIM5_BE_WIDTH] = PIM5_WrFIFO_BE;
      assign NPI_WrFIFO_Push[5] = PIM5_WrFIFO_Push;
      assign PIM5_RdFIFO_Data = NPI_RdFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH];
      assign NPI_RdFIFO_Pop[5] = PIM5_RdFIFO_Pop;
      assign PIM5_RdFIFO_RdWdAddr = NPI_RdFIFO_RdWdAddr[5*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX];
      assign PIM5_WrFIFO_Empty = NPI_WrFIFO_Empty[5];
      assign PIM5_WrFIFO_AlmostFull = NPI_WrFIFO_AlmostFull[5];
      assign NPI_WrFIFO_Flush[5] = PIM5_WrFIFO_Flush;
      assign PIM5_RdFIFO_Empty = NPI_RdFIFO_Empty[5];
      assign NPI_RdFIFO_Flush[5] = PIM5_RdFIFO_Flush;
      assign PIM5_RdFIFO_Latency = NPI_RdFIFO_Latency[5*2 +: 2];
  end
  else if (C_NUM_PORTS > 5 && (C_PIM5_BASETYPE == 5)) begin : PPC440MC5_INST
      assign pim_rst[5] = 1'b0;
      mib_pim
      #(
        .C_MPMC_PIM_DATA_WIDTH          (P_PIM5_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH          (P_PIM5_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY      (P_PIM5_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH      (P_PIM5_RDWDADDR_WIDTH),
        .C_MPMC_PIM_MEM_DATA_WIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_BURST_LENGTH        (C_PPC440MC5_BURST_LENGTH),
        .C_MPMC_PIM_PIPE_STAGES         (C_PPC440MC5_PIPE_STAGES),
        .C_MPMC_PIM_WRFIFO_TYPE         (P_PI5_WR_FIFO_TYPE),
        .C_MPMC_PIM_OFFSET              (C_PIM5_OFFSET),
        .C_FAMILY                       (C_BASEFAMILY)
      )
      ppc440mc
      (
        .MPMC_Clk                       (MPMC_Clk0),
        .MPMC_Rst                       (Rst_topim[5]),
        .MPMC_PIM_Addr                  (NPI_Addr[5*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq               (NPI_AddrReq[5]),
        .MPMC_PIM_AddrAck               (NPI_AddrAck[5]),
        .MPMC_PIM_RdModWr               (NPI_RdModWr[5]),
        .MPMC_PIM_RNW                   (NPI_RNW[5]),
        .MPMC_PIM_Size                  (NPI_Size[5*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data           (NPI_WrFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE             (NPI_WrFIFO_BE[5*P_PIX_BE_WIDTH_MAX +: P_PIM5_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push           (NPI_WrFIFO_Push[5]),
        .MPMC_PIM_RdFIFO_Data           (NPI_RdFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop            (NPI_RdFIFO_Pop[5]),
        .MPMC_PIM_RdFIFO_RdWdAddr       (NPI_RdFIFO_RdWdAddr[5*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_WrFIFO_AlmostFull     (NPI_WrFIFO_AlmostFull[5]),
        .MPMC_PIM_WrFIFO_Flush          (NPI_WrFIFO_Flush[5]),
        .MPMC_PIM_WrFIFO_Empty          (NPI_WrFIFO_Empty[5]),
        .MPMC_PIM_RdFIFO_DataAvailable  (NPI_RdFIFO_DataAvailable[5]),
        .MPMC_PIM_RdFIFO_Empty          (NPI_RdFIFO_Empty[5]),
        .MPMC_PIM_RdFIFO_Flush          (NPI_RdFIFO_Flush[5]),
        .MPMC_PIM_InitDone              (NPI_InitDone[5]),
        .MPMC_PIM_Rd_FIFO_Latency       (NPI_RdFIFO_Latency[5*2 +: 2]),
        .mi_mcaddressvalid              (PPC440MC5_MIMCAddressValid),
        .mi_mcaddress                   (PPC440MC5_MIMCAddress),
        .mi_mcbankconflict              (PPC440MC5_MIMCBankConflict),
        .mi_mcrowconflict               (PPC440MC5_MIMCRowConflict),
        .mi_mcbyteenable                (PPC440MC5_MIMCByteEnable),
        .mi_mcwritedata                 (PPC440MC5_MIMCWriteData),
        .mi_mcreadnotwrite              (PPC440MC5_MIMCReadNotWrite),
        .mi_mcwritedatavalid            (PPC440MC5_MIMCWriteDataValid),
        .mc_miaddrreadytoaccept         (PPC440MC5_MCMIAddrReadyToAccept),
        .mc_mireaddata                  (PPC440MC5_MCMIReadData),
        .mc_mireaddataerr               (PPC440MC5_MCMIReadDataErr),
        .mc_mireaddatavalid             (PPC440MC5_MCMIReadDataValid)
    );
  end
  else if (C_NUM_PORTS > 5 && (C_PIM5_BASETYPE == 6)) begin : VFBC5_INST
      assign pim_rst[5] = 1'b0;
      assign NPI_RdModWr[5] = 1'b1;
      vfbc_pim_wrapper
      #(
        .C_MPMC_BASEADDR  (C_MPMC_BASEADDR[31:2]),
        .C_MPMC_HIGHADDR  (C_MPMC_HIGHADDR[31:2]),
        .C_PIM_DATA_WIDTH               (P_PIM5_DATA_WIDTH),
        .C_CHIPSCOPE_ENABLE             (P_VFBC5_CHIPSCOPE_ENABLE),
        .C_FAMILY                       (C_BASEFAMILY),
        .VFBC_BURST_LENGTH              (P_VFBC5_BURST_LENGTH),
        .CMD0_PORT_ID                   (P_VFBC5_CMD_PORT_ID),
        .CMD0_FIFO_DEPTH                (C_VFBC5_CMD_FIFO_DEPTH),
        .CMD0_ASYNC_CLOCK               (P_VFBC5_ASYNC_CLOCK),
        .CMD0_AFULL_COUNT               (C_VFBC5_CMD_AFULL_COUNT),
        .WD0_ENABLE                     (P_VFBC5_WD_ENABLE),
        .WD0_DATA_WIDTH                 (P_VFBC5_WD_DATA_WIDTH),
        .WD0_FIFO_DEPTH                 (P_VFBC5_WD_FIFO_DEPTH),
        .WD0_ASYNC_CLOCK                (P_VFBC5_ASYNC_CLOCK),
        .WD0_AFULL_COUNT                (P_VFBC5_WD_AFULL_COUNT),
        .WD0_BYTEEN_ENABLE              (P_VFBC5_WD_BYTEEN_ENABLE),
        .RD0_ENABLE                     (P_VFBC5_RD_ENABLE),
        .RD0_DATA_WIDTH                 (P_VFBC5_RD_DATA_WIDTH),
        .RD0_FIFO_DEPTH                 (P_VFBC5_RD_FIFO_DEPTH),
        .RD0_ASYNC_CLOCK                (P_VFBC5_ASYNC_CLOCK),
        .RD0_AEMPTY_COUNT               (P_VFBC5_RD_AEMPTY_COUNT)
      )
      vfbc
      (
        .vfbc_clk                       (MPMC_Clk0),
        .srst                           (Rst_topim[5]),
        .cmd0_clk                       (VFBC5_Cmd_Clk),
        .cmd0_reset                     (VFBC5_Cmd_Reset),
        .cmd0_data                      (VFBC5_Cmd_Data),
        .cmd0_write                     (VFBC5_Cmd_Write),
        .cmd0_end                       (VFBC5_Cmd_End),
        .cmd0_full                      (VFBC5_Cmd_Full),
        .cmd0_almost_full               (VFBC5_Cmd_Almost_Full),
        .cmd0_idle                      (VFBC5_Cmd_Idle),
        .wd0_clk                        (VFBC5_Wd_Clk),
        .wd0_reset                      (VFBC5_Wd_Reset),
        .wd0_write                      (VFBC5_Wd_Write),
        .wd0_end_burst                  (VFBC5_Wd_End_Burst),
        .wd0_flush                      (VFBC5_Wd_Flush),
        .wd0_data                       (VFBC5_Wd_Data),
        .wd0_data_be                    (VFBC5_Wd_Data_BE),
        .wd0_full                       (VFBC5_Wd_Full),
        .wd0_almost_full                (VFBC5_Wd_Almost_Full),
        .rd0_clk                        (VFBC5_Rd_Clk),
        .rd0_reset                      (VFBC5_Rd_Reset),
        .rd0_read                       (VFBC5_Rd_Read),
        .rd0_end_burst                  (VFBC5_Rd_End_Burst),
        .rd0_flush                      (VFBC5_Rd_Flush),
        .rd0_data                       (VFBC5_Rd_Data),
        .rd0_empty                      (VFBC5_Rd_Empty),
        .rd0_almost_empty               (VFBC5_Rd_Almost_Empty),
        .npi_init_done                  (NPI_InitDone[5]),
        .npi_addr_ack                   (NPI_AddrAck[5]),
        .npi_rdfifo_word_add            (NPI_RdFIFO_RdWdAddr[5*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .npi_rdfifo_data                (NPI_RdFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .npi_rdfifo_latency             (NPI_RdFIFO_Latency[5*2 +: 2]),
        .npi_rdfifo_empty               (NPI_RdFIFO_Empty[5]),
        .npi_wrfifo_almost_full         (NPI_WrFIFO_AlmostFull[5]),
        .npi_address                    (NPI_Addr[5*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .npi_addr_req                   (NPI_AddrReq[5]),
        .npi_size                       (NPI_Size[5*4 +: 4]),
        .npi_rnw                        (NPI_RNW[5]),
        .npi_rdfifo_pop                 (NPI_RdFIFO_Pop[5]),
        .npi_rdfifo_flush               (NPI_RdFIFO_Flush[5]),
        .npi_wrfifo_data                (NPI_WrFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH]),
        .npi_wrfifo_be                  (NPI_WrFIFO_BE[5*P_PIX_BE_WIDTH_MAX +: P_PIM5_BE_WIDTH]),
        .npi_wrfifo_push                (NPI_WrFIFO_Push[5]),
        .npi_wrfifo_flush               (NPI_WrFIFO_Flush[5])
//        .npi_rdmodwr                    (NPI_RdModWr[5])
    );
  end
  else begin : INACTIVE_5
      // tie off unused inputs to mpmc_core
      assign pim_rst[5] = 1'b0;
      if (C_NUM_PORTS > 5) begin : TIE_OFF_5
        assign NPI_Addr[5*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX] = 0;
        assign NPI_AddrReq[5] = 0;
        assign NPI_RNW[5] = 0;
        assign NPI_Size[5*4 +: 4] = 0;
        assign NPI_WrFIFO_Data[5*P_PIX_DATA_WIDTH_MAX +: P_PIM5_DATA_WIDTH] = 0;
        assign NPI_WrFIFO_BE[5*P_PIX_BE_WIDTH_MAX +: P_PIM5_BE_WIDTH] = 0;
        assign NPI_WrFIFO_Push[5] = 0;
        assign NPI_WrFIFO_Flush[5] = 0;
        assign NPI_RdFIFO_Pop[5] = 0;
        assign NPI_RdFIFO_Flush[5] = 0;
      end
    end
  endgenerate
  generate
  if (C_NUM_PORTS > 6 && C_PIM6_BASETYPE == 1)
    begin : DUALXCL6_INST
      assign pim_rst[6] = 1'b0;
      dualxcl
      #(
        .C_FAMILY                   (C_BASEFAMILY),
        .C_PI_A_SUBTYPE             (C_PIM6_SUBTYPE),
        .C_PI_B_SUBTYPE             (P_PIM6_B_SUBTYPE),
        .C_PI_BASEADDR              (P_PIM6_BASEADDR),
        .C_PI_HIGHADDR              (P_PIM6_HIGHADDR),
        .C_PI_OFFSET                (C_PIM6_OFFSET),
        .C_PI_ADDR_WIDTH            (P_PIM6_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM6_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM6_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM6_RDWDADDR_WIDTH),
        .C_PI_RDDATA_DELAY          (P_PIM6_RD_FIFO_LATENCY),
        .C_XCL_A_WRITEXFER          (C_XCL6_WRITEXFER),
        .C_XCL_A_LINESIZE           (C_XCL6_LINESIZE),
        .C_XCL_B_WRITEXFER          (C_XCL6_B_WRITEXFER),
        .C_XCL_B_LINESIZE           (C_XCL6_B_LINESIZE),
        .C_XCL_PIPE_STAGES          (C_XCL6_PIPE_STAGES),
        .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
        .C_MEM_SDR_DATA_WIDTH       (P_MEM_DATA_WIDTH_INT)
      )
      dualxcl_6
      (
        .Clk                        (FSL6_M_Clk),
        .Clk_MPMC                   (MPMC_Clk0),
        .Rst                        (Rst_topim[6]),
        .FSL_A_M_Clk                (FSL6_M_Clk),
        .FSL_A_M_Write              (FSL6_M_Write),
        .FSL_A_M_Data               (FSL6_M_Data),
        .FSL_A_M_Control            (FSL6_M_Control),
        .FSL_A_M_Full               (FSL6_M_Full),
        .FSL_A_S_Clk                (FSL6_S_Clk),
        .FSL_A_S_Read               (FSL6_S_Read),
        .FSL_A_S_Data               (FSL6_S_Data),
        .FSL_A_S_Control            (FSL6_S_Control),
        .FSL_A_S_Exists             (FSL6_S_Exists),
        .FSL_B_M_Clk                (FSL6_B_M_Clk),
        .FSL_B_M_Write              (FSL6_B_M_Write),
        .FSL_B_M_Data               (FSL6_B_M_Data),
        .FSL_B_M_Control            (FSL6_B_M_Control),
        .FSL_B_M_Full               (FSL6_B_M_Full),
        .FSL_B_S_Clk                (FSL6_B_S_Clk),
        .FSL_B_S_Read               (FSL6_B_S_Read),
        .FSL_B_S_Data               (FSL6_B_S_Data),
        .FSL_B_S_Control            (FSL6_B_S_Control),
        .FSL_B_S_Exists             (FSL6_B_S_Exists),
        .PI_Addr                    (NPI_Addr[6*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[6]),
        .PI_AddrAck                 (NPI_AddrAck[6]),
        .PI_RNW                     (NPI_RNW[6]),
        .PI_RdModWr                 (NPI_RdModWr[6]),
        .PI_Size                    (NPI_Size[6*4 +: 4]),
        .PI_InitDone                (NPI_InitDone[6]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[6*P_PIX_BE_WIDTH_MAX +: P_PIM6_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[6]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[6]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[6*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIM6_RDWDADDR_WIDTH]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[6]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[6]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[6]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[6])
      );
    end
  else if (C_NUM_PORTS > 6 && C_PIM6_BASETYPE == 2) begin : PLB_6_INST
      assign pim_rst[6] = SPLB6_Rst;
      plbv46_pim_wrapper
      #(
        .C_SPLB_DWIDTH              (C_SPLB6_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SPLB6_NATIVE_DWIDTH),
        .C_SPLB_AWIDTH              (C_SPLB6_AWIDTH),
        .C_SPLB_NUM_MASTERS         (C_SPLB6_NUM_MASTERS),
        .C_SPLB_MID_WIDTH           (C_SPLB6_MID_WIDTH),
        .C_SPLB_P2P                 (C_SPLB6_P2P),
        .C_SPLB_SUPPORT_BURSTS      (C_SPLB6_SUPPORT_BURSTS),
        .C_SPLB_SMALLEST_MASTER     (C_SPLB6_SMALLEST_MASTER),
        .C_PLBV46_PIM_TYPE          (C_PIM6_SUBTYPE),
        .C_MPMC_PIM_BASEADDR        (P_PIM6_BASEADDR[31:2]),
        .C_MPMC_PIM_HIGHADDR        (P_PIM6_HIGHADDR[31:2]),
        .C_MPMC_PIM_OFFSET          (C_PIM6_OFFSET[31:2]),
        .C_MPMC_PIM_DATA_WIDTH      (P_PIM6_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH      (P_PIM6_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY  (P_PIM6_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH  (P_PIM6_RDWDADDR_WIDTH),
        .C_MPMC_PIM_SDR_DWIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_MEM_HAS_BE      (P_MEM_HAS_BE),
        .C_MPMC_PIM_WR_FIFO_TYPE    (P_PI6_WR_FIFO_TYPE),
        .C_MPMC_PIM_RD_FIFO_TYPE    (P_PI6_RD_FIFO_TYPE),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      plbv46_pim_6
      (
        .MPMC_CLK                   (MPMC_Clk0),
        .MPMC_Rst                   (Rst_topim[6]),
        .SPLB_Clk                   (SPLB6_Clk),
        .SPLB_Rst                   (Rst_topim[6]),
        .SPLB_PLB_ABus              (SPLB6_PLB_ABus),
        .SPLB_PLB_UABus             (SPLB6_PLB_UABus),
        .SPLB_PLB_PAValid           (SPLB6_PLB_PAValid),
        .SPLB_PLB_SAValid           (SPLB6_PLB_SAValid),
        .SPLB_PLB_rdPrim            (SPLB6_PLB_rdPrim),
        .SPLB_PLB_wrPrim            (SPLB6_PLB_wrPrim),
        .SPLB_PLB_masterID          (SPLB6_PLB_masterID),
        .SPLB_PLB_abort             (SPLB6_PLB_abort),
        .SPLB_PLB_busLock           (SPLB6_PLB_busLock),
        .SPLB_PLB_RNW               (SPLB6_PLB_RNW),
        .SPLB_PLB_BE                (SPLB6_PLB_BE),
        .SPLB_PLB_MSize             (SPLB6_PLB_MSize),
        .SPLB_PLB_size              (SPLB6_PLB_size),
        .SPLB_PLB_type              (SPLB6_PLB_type),
        .SPLB_PLB_lockErr           (SPLB6_PLB_lockErr),
        .SPLB_PLB_wrDBus            (SPLB6_PLB_wrDBus),
        .SPLB_PLB_wrBurst           (SPLB6_PLB_wrBurst),
        .SPLB_PLB_rdBurst           (SPLB6_PLB_rdBurst),
        .SPLB_PLB_wrPendReq         (SPLB6_PLB_wrPendReq),
        .SPLB_PLB_rdPendReq         (SPLB6_PLB_rdPendReq),
        .SPLB_PLB_wrPendPri         (SPLB6_PLB_wrPendPri),
        .SPLB_PLB_rdPendPri         (SPLB6_PLB_rdPendPri),
        .SPLB_PLB_reqPri            (SPLB6_PLB_reqPri),
        .SPLB_PLB_TAttribute        (SPLB6_PLB_TAttribute),
        .SPLB_Sl_addrAck            (SPLB6_Sl_addrAck),
        .SPLB_Sl_SSize              (SPLB6_Sl_SSize),
        .SPLB_Sl_wait               (SPLB6_Sl_wait),
        .SPLB_Sl_rearbitrate        (SPLB6_Sl_rearbitrate),
        .SPLB_Sl_wrDAck             (SPLB6_Sl_wrDAck),
        .SPLB_Sl_wrComp             (SPLB6_Sl_wrComp),
        .SPLB_Sl_wrBTerm            (SPLB6_Sl_wrBTerm),
        .SPLB_Sl_rdDBus             (SPLB6_Sl_rdDBus),
        .SPLB_Sl_rdWdAddr           (SPLB6_Sl_rdWdAddr),
        .SPLB_Sl_rdDAck             (SPLB6_Sl_rdDAck),
        .SPLB_Sl_rdComp             (SPLB6_Sl_rdComp),
        .SPLB_Sl_rdBTerm            (SPLB6_Sl_rdBTerm),
        .SPLB_Sl_MBusy              (SPLB6_Sl_MBusy),
        .SPLB_Sl_MWrErr             (SPLB6_Sl_MWrErr),
        .SPLB_Sl_MRdErr             (SPLB6_Sl_MRdErr),
        .SPLB_Sl_MIRQ               (SPLB6_Sl_MIRQ),
        .MPMC_PIM_InitDone          (NPI_InitDone[6]),
        .MPMC_PIM_Addr              (NPI_Addr[6*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq           (NPI_AddrReq[6]),
        .MPMC_PIM_AddrAck           (NPI_AddrAck[6]),
        .MPMC_PIM_RNW               (NPI_RNW[6]),
        .MPMC_PIM_Size              (NPI_Size[6*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data       (NPI_WrFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE         (NPI_WrFIFO_BE[6*P_PIX_BE_WIDTH_MAX +: P_PIM6_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push       (NPI_WrFIFO_Push[6]),
        .MPMC_PIM_WrFIFO_Empty      (NPI_WrFIFO_Empty[6]),
        .MPMC_PIM_WrFIFO_AlmostFull (NPI_WrFIFO_AlmostFull[6]),
        .MPMC_PIM_RdFIFO_Latency    (NPI_RdFIFO_Latency[6*2 +: 2]),
        .MPMC_PIM_RdFIFO_Data       (NPI_RdFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop        (NPI_RdFIFO_Pop[6]),
        .MPMC_PIM_RdFIFO_Empty      (NPI_RdFIFO_Empty[6]),
        .MPMC_PIM_RdFIFO_RdWd_Addr  (NPI_RdFIFO_RdWdAddr[6*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_RdFIFO_Data_Available  (NPI_RdFIFO_DataAvailable[6]),
        .MPMC_PIM_RdFIFO_Flush      (NPI_RdFIFO_Flush[6]),
        .MPMC_PIM_WrFIFO_Flush      (NPI_WrFIFO_Flush[6]),
        .MPMC_PIM_RdModWr           (NPI_RdModWr[6])
      );
  end
  else if (C_NUM_PORTS > 6 && (C_PIM6_BASETYPE == 3)) begin : SDMA6_INST
      assign pim_rst[6] = SDMA_CTRL6_Rst;
      sdma_wrapper
      #(
        .C_PI_BASEADDR              (P_PIM6_BASEADDR[31:2]),
        .C_PI_HIGHADDR              (P_PIM6_HIGHADDR[31:2]),
        .C_PI_ADDR_WIDTH            (P_PIM6_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM6_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM6_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM6_RDWDADDR_WIDTH),
        .C_SDMA_BASEADDR            (P_SDMA_CTRL6_BASEADDR[31:2]),
        .C_SDMA_HIGHADDR            (P_SDMA_CTRL6_HIGHADDR[31:2]),
        .C_COMPLETED_ERR_TX         (C_SDMA6_COMPLETED_ERR_TX),
        .C_COMPLETED_ERR_RX         (C_SDMA6_COMPLETED_ERR_RX),
        .C_PRESCALAR                (C_SDMA6_PRESCALAR),
        .C_PI_RDDATA_DELAY          (P_PIM6_RD_FIFO_LATENCY),
        .C_PI2LL_CLK_RATIO          (C_SDMA6_PI2LL_CLK_RATIO),
        .C_SPLB_P2P                 (C_SDMA_CTRL6_P2P),
        .C_SPLB_MID_WIDTH           (C_SDMA_CTRL6_MID_WIDTH),
        .C_SPLB_NUM_MASTERS         (C_SDMA_CTRL6_NUM_MASTERS),
        .C_SPLB_AWIDTH              (C_SDMA_CTRL6_AWIDTH),
        .C_SPLB_DWIDTH              (C_SDMA_CTRL6_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SDMA_CTRL6_NATIVE_DWIDTH),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      mpmc_sdma_6
      (
        .LLink_Clk                  (SDMA6_Clk),
        .PI_Clk                     (MPMC_Clk0),
        // PLBv46 Signals
        .SPLB_Clk                   (SDMA_CTRL6_Clk),
        .SPLB_Rst                   (Rst_topim[6]),
        .PLB_ABus                   (SDMA_CTRL6_PLB_ABus),
        .PLB_UABus                  (SDMA_CTRL6_PLB_UABus),
        .PLB_PAValid                (SDMA_CTRL6_PLB_PAValid),
        .PLB_SAValid                (SDMA_CTRL6_PLB_SAValid),
        .PLB_rdPrim                 (SDMA_CTRL6_PLB_rdPrim),
        .PLB_wrPrim                 (SDMA_CTRL6_PLB_wrPrim),
        .PLB_masterID               (SDMA_CTRL6_PLB_masterID),
        .PLB_abort                  (SDMA_CTRL6_PLB_abort),
        .PLB_busLock                (SDMA_CTRL6_PLB_busLock),
        .PLB_RNW                    (SDMA_CTRL6_PLB_RNW),
        .PLB_BE                     (SDMA_CTRL6_PLB_BE),
        .PLB_MSize                  (SDMA_CTRL6_PLB_MSize),
        .PLB_size                   (SDMA_CTRL6_PLB_size),
        .PLB_type                   (SDMA_CTRL6_PLB_type),
        .PLB_lockErr                (SDMA_CTRL6_PLB_lockErr),
        .PLB_wrDBus                 (SDMA_CTRL6_PLB_wrDBus),
        .PLB_wrBurst                (SDMA_CTRL6_PLB_wrBurst),
        .PLB_rdBurst                (SDMA_CTRL6_PLB_rdBurst),
        .PLB_wrPendReq              (SDMA_CTRL6_PLB_wrPendReq),
        .PLB_rdPendReq              (SDMA_CTRL6_PLB_rdPendReq),
        .PLB_wrPendPri              (SDMA_CTRL6_PLB_wrPendPri),
        .PLB_rdPendPri              (SDMA_CTRL6_PLB_rdPendPri),
        .PLB_reqPri                 (SDMA_CTRL6_PLB_reqPri),
        .PLB_TAttribute             (SDMA_CTRL6_PLB_TAttribute),
        .Sln_addrAck                 (SDMA_CTRL6_Sl_addrAck),
        .Sln_SSize                   (SDMA_CTRL6_Sl_SSize),
        .Sln_wait                    (SDMA_CTRL6_Sl_wait),
        .Sln_rearbitrate             (SDMA_CTRL6_Sl_rearbitrate),
        .Sln_wrDAck                  (SDMA_CTRL6_Sl_wrDAck),
        .Sln_wrComp                  (SDMA_CTRL6_Sl_wrComp),
        .Sln_wrBTerm                 (SDMA_CTRL6_Sl_wrBTerm),
        .Sln_rdDBus                  (SDMA_CTRL6_Sl_rdDBus),
        .Sln_rdWdAddr                (SDMA_CTRL6_Sl_rdWdAddr),
        .Sln_rdDAck                  (SDMA_CTRL6_Sl_rdDAck),
        .Sln_rdComp                  (SDMA_CTRL6_Sl_rdComp),
        .Sln_rdBTerm                 (SDMA_CTRL6_Sl_rdBTerm),
        .Sln_MBusy                   (SDMA_CTRL6_Sl_MBusy),
        .Sln_MWrErr                  (SDMA_CTRL6_Sl_MWrErr),
        .Sln_MRdErr                  (SDMA_CTRL6_Sl_MRdErr),
        .Sln_MIRQ                    (SDMA_CTRL6_Sl_MIRQ),
        // MPMC NPI Signals
        .PI_Addr                    (NPI_Addr[6*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[6]),
        .PI_AddrAck                 (NPI_AddrAck[6]),
        .PI_RdModWr                 (NPI_RdModWr[6]),
        .PI_RNW                     (NPI_RNW[6]),
        .PI_Size                    (NPI_Size[6*4 +: 4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[6*P_PIX_BE_WIDTH_MAX +: P_PIM6_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[6]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[6]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[6*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[6]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[6]),
        .PI_WrFIFO_Empty            (NPI_WrFIFO_Empty[6]),
        .PI_RdFIFO_DataAvailable    (NPI_RdFIFO_DataAvailable[6]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[6]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[6]),
        //.PI_InitDone                (NPI_InitDone[6]),
        // SDMA Signals
        .TX_D                       (SDMA6_TX_D),
        .TX_Rem                     (SDMA6_TX_Rem),
        .TX_SOF                     (SDMA6_TX_SOF),
        .TX_EOF                     (SDMA6_TX_EOF),
        .TX_SOP                     (SDMA6_TX_SOP),
        .TX_EOP                     (SDMA6_TX_EOP),
        .TX_Src_Rdy                 (SDMA6_TX_Src_Rdy),
        .TX_Dst_Rdy                 (SDMA6_TX_Dst_Rdy),
        .RX_D                       (SDMA6_RX_D),
        .RX_Rem                     (SDMA6_RX_Rem),
        .RX_SOF                     (SDMA6_RX_SOF),
        .RX_EOF                     (SDMA6_RX_EOF),
        .RX_SOP                     (SDMA6_RX_SOP),
        .RX_EOP                     (SDMA6_RX_EOP),
        .RX_Src_Rdy                 (SDMA6_RX_Src_Rdy),
        .RX_Dst_Rdy                 (SDMA6_RX_Dst_Rdy),
        .SDMA_RstOut                (SDMA6_RstOut),
        .SDMA_Rx_IntOut             (SDMA6_Rx_IntOut),
        .SDMA_Tx_IntOut             (SDMA6_Tx_IntOut)
      );
  end
  else if (C_NUM_PORTS > 6 && (C_PIM6_BASETYPE == 4)) begin : NPI6_INST
      // do nothing, pass signals straight through
      assign pim_rst[6] = 1'b0;
      assign PIM6_InitDone = NPI_InitDone[6];
      assign NPI_AddrReq[6] = PIM6_AddrReq;
      assign PIM6_AddrAck = NPI_AddrAck[6];
      assign NPI_Addr[6*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]    = PIM6_Addr;
      assign NPI_RNW[6] = PIM6_RNW;
      assign NPI_Size[6*4 +: 4] = PIM6_Size;
      assign NPI_RdModWr[6] = PIM6_RdModWr;
      assign NPI_WrFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH] = PIM6_WrFIFO_Data;
      assign NPI_WrFIFO_BE[6*P_PIX_BE_WIDTH_MAX +: P_PIM6_BE_WIDTH] = PIM6_WrFIFO_BE;
      assign NPI_WrFIFO_Push[6] = PIM6_WrFIFO_Push;
      assign PIM6_RdFIFO_Data = NPI_RdFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH];
      assign NPI_RdFIFO_Pop[6] = PIM6_RdFIFO_Pop;
      assign PIM6_RdFIFO_RdWdAddr = NPI_RdFIFO_RdWdAddr[6*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX];
      assign PIM6_WrFIFO_Empty = NPI_WrFIFO_Empty[6];
      assign PIM6_WrFIFO_AlmostFull = NPI_WrFIFO_AlmostFull[6];
      assign NPI_WrFIFO_Flush[6] = PIM6_WrFIFO_Flush;
      assign PIM6_RdFIFO_Empty = NPI_RdFIFO_Empty[6];
      assign NPI_RdFIFO_Flush[6] = PIM6_RdFIFO_Flush;
      assign PIM6_RdFIFO_Latency = NPI_RdFIFO_Latency[6*2 +: 2];
  end
  else if (C_NUM_PORTS > 6 && (C_PIM6_BASETYPE == 5)) begin : PPC440MC6_INST
      assign pim_rst[6] = 1'b0;
      mib_pim
      #(
        .C_MPMC_PIM_DATA_WIDTH          (P_PIM6_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH          (P_PIM6_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY      (P_PIM6_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH      (P_PIM6_RDWDADDR_WIDTH),
        .C_MPMC_PIM_MEM_DATA_WIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_BURST_LENGTH        (C_PPC440MC6_BURST_LENGTH),
        .C_MPMC_PIM_PIPE_STAGES         (C_PPC440MC6_PIPE_STAGES),
        .C_MPMC_PIM_WRFIFO_TYPE         (P_PI6_WR_FIFO_TYPE),
        .C_MPMC_PIM_OFFSET              (C_PIM6_OFFSET),
        .C_FAMILY                       (C_BASEFAMILY)
      )
      ppc440mc
      (
        .MPMC_Clk                       (MPMC_Clk0),
        .MPMC_Rst                       (Rst_topim[6]),
        .MPMC_PIM_Addr                  (NPI_Addr[6*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq               (NPI_AddrReq[6]),
        .MPMC_PIM_AddrAck               (NPI_AddrAck[6]),
        .MPMC_PIM_RdModWr               (NPI_RdModWr[6]),
        .MPMC_PIM_RNW                   (NPI_RNW[6]),
        .MPMC_PIM_Size                  (NPI_Size[6*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data           (NPI_WrFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE             (NPI_WrFIFO_BE[6*P_PIX_BE_WIDTH_MAX +: P_PIM6_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push           (NPI_WrFIFO_Push[6]),
        .MPMC_PIM_RdFIFO_Data           (NPI_RdFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop            (NPI_RdFIFO_Pop[6]),
        .MPMC_PIM_RdFIFO_RdWdAddr       (NPI_RdFIFO_RdWdAddr[6*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_WrFIFO_AlmostFull     (NPI_WrFIFO_AlmostFull[6]),
        .MPMC_PIM_WrFIFO_Flush          (NPI_WrFIFO_Flush[6]),
        .MPMC_PIM_WrFIFO_Empty          (NPI_WrFIFO_Empty[6]),
        .MPMC_PIM_RdFIFO_DataAvailable  (NPI_RdFIFO_DataAvailable[6]),
        .MPMC_PIM_RdFIFO_Empty          (NPI_RdFIFO_Empty[6]),
        .MPMC_PIM_RdFIFO_Flush          (NPI_RdFIFO_Flush[6]),
        .MPMC_PIM_InitDone              (NPI_InitDone[6]),
        .MPMC_PIM_Rd_FIFO_Latency       (NPI_RdFIFO_Latency[6*2 +: 2]),
        .mi_mcaddressvalid              (PPC440MC6_MIMCAddressValid),
        .mi_mcaddress                   (PPC440MC6_MIMCAddress),
        .mi_mcbankconflict              (PPC440MC6_MIMCBankConflict),
        .mi_mcrowconflict               (PPC440MC6_MIMCRowConflict),
        .mi_mcbyteenable                (PPC440MC6_MIMCByteEnable),
        .mi_mcwritedata                 (PPC440MC6_MIMCWriteData),
        .mi_mcreadnotwrite              (PPC440MC6_MIMCReadNotWrite),
        .mi_mcwritedatavalid            (PPC440MC6_MIMCWriteDataValid),
        .mc_miaddrreadytoaccept         (PPC440MC6_MCMIAddrReadyToAccept),
        .mc_mireaddata                  (PPC440MC6_MCMIReadData),
        .mc_mireaddataerr               (PPC440MC6_MCMIReadDataErr),
        .mc_mireaddatavalid             (PPC440MC6_MCMIReadDataValid)
    );
  end
  else if (C_NUM_PORTS > 6 && (C_PIM6_BASETYPE == 6)) begin : VFBC6_INST
      assign pim_rst[6] = 1'b0;
      assign NPI_RdModWr[6] = 1'b1;
      vfbc_pim_wrapper
      #(
        .C_MPMC_BASEADDR  (C_MPMC_BASEADDR[31:2]),
        .C_MPMC_HIGHADDR  (C_MPMC_HIGHADDR[31:2]),
        .C_PIM_DATA_WIDTH               (P_PIM6_DATA_WIDTH),
        .C_CHIPSCOPE_ENABLE             (P_VFBC6_CHIPSCOPE_ENABLE),
        .C_FAMILY                       (C_BASEFAMILY),
        .VFBC_BURST_LENGTH              (P_VFBC6_BURST_LENGTH),
        .CMD0_PORT_ID                   (P_VFBC6_CMD_PORT_ID),
        .CMD0_FIFO_DEPTH                (C_VFBC6_CMD_FIFO_DEPTH),
        .CMD0_ASYNC_CLOCK               (P_VFBC6_ASYNC_CLOCK),
        .CMD0_AFULL_COUNT               (C_VFBC6_CMD_AFULL_COUNT),
        .WD0_ENABLE                     (P_VFBC6_WD_ENABLE),
        .WD0_DATA_WIDTH                 (P_VFBC6_WD_DATA_WIDTH),
        .WD0_FIFO_DEPTH                 (P_VFBC6_WD_FIFO_DEPTH),
        .WD0_ASYNC_CLOCK                (P_VFBC6_ASYNC_CLOCK),
        .WD0_AFULL_COUNT                (P_VFBC6_WD_AFULL_COUNT),
        .WD0_BYTEEN_ENABLE              (P_VFBC6_WD_BYTEEN_ENABLE),
        .RD0_ENABLE                     (P_VFBC6_RD_ENABLE),
        .RD0_DATA_WIDTH                 (P_VFBC6_RD_DATA_WIDTH),
        .RD0_FIFO_DEPTH                 (P_VFBC6_RD_FIFO_DEPTH),
        .RD0_ASYNC_CLOCK                (P_VFBC6_ASYNC_CLOCK),
        .RD0_AEMPTY_COUNT               (P_VFBC6_RD_AEMPTY_COUNT)
      )
      vfbc
      (
        .vfbc_clk                       (MPMC_Clk0),
        .srst                           (Rst_topim[6]),
        .cmd0_clk                       (VFBC6_Cmd_Clk),
        .cmd0_reset                     (VFBC6_Cmd_Reset),
        .cmd0_data                      (VFBC6_Cmd_Data),
        .cmd0_write                     (VFBC6_Cmd_Write),
        .cmd0_end                       (VFBC6_Cmd_End),
        .cmd0_full                      (VFBC6_Cmd_Full),
        .cmd0_almost_full               (VFBC6_Cmd_Almost_Full),
        .cmd0_idle                      (VFBC6_Cmd_Idle),
        .wd0_clk                        (VFBC6_Wd_Clk),
        .wd0_reset                      (VFBC6_Wd_Reset),
        .wd0_write                      (VFBC6_Wd_Write),
        .wd0_end_burst                  (VFBC6_Wd_End_Burst),
        .wd0_flush                      (VFBC6_Wd_Flush),
        .wd0_data                       (VFBC6_Wd_Data),
        .wd0_data_be                    (VFBC6_Wd_Data_BE),
        .wd0_full                       (VFBC6_Wd_Full),
        .wd0_almost_full                (VFBC6_Wd_Almost_Full),
        .rd0_clk                        (VFBC6_Rd_Clk),
        .rd0_reset                      (VFBC6_Rd_Reset),
        .rd0_read                       (VFBC6_Rd_Read),
        .rd0_end_burst                  (VFBC6_Rd_End_Burst),
        .rd0_flush                      (VFBC6_Rd_Flush),
        .rd0_data                       (VFBC6_Rd_Data),
        .rd0_empty                      (VFBC6_Rd_Empty),
        .rd0_almost_empty               (VFBC6_Rd_Almost_Empty),
        .npi_init_done                  (NPI_InitDone[6]),
        .npi_addr_ack                   (NPI_AddrAck[6]),
        .npi_rdfifo_word_add            (NPI_RdFIFO_RdWdAddr[6*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .npi_rdfifo_data                (NPI_RdFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .npi_rdfifo_latency             (NPI_RdFIFO_Latency[6*2 +: 2]),
        .npi_rdfifo_empty               (NPI_RdFIFO_Empty[6]),
        .npi_wrfifo_almost_full         (NPI_WrFIFO_AlmostFull[6]),
        .npi_address                    (NPI_Addr[6*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .npi_addr_req                   (NPI_AddrReq[6]),
        .npi_size                       (NPI_Size[6*4 +: 4]),
        .npi_rnw                        (NPI_RNW[6]),
        .npi_rdfifo_pop                 (NPI_RdFIFO_Pop[6]),
        .npi_rdfifo_flush               (NPI_RdFIFO_Flush[6]),
        .npi_wrfifo_data                (NPI_WrFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH]),
        .npi_wrfifo_be                  (NPI_WrFIFO_BE[6*P_PIX_BE_WIDTH_MAX +: P_PIM6_BE_WIDTH]),
        .npi_wrfifo_push                (NPI_WrFIFO_Push[6]),
        .npi_wrfifo_flush               (NPI_WrFIFO_Flush[6])
//        .npi_rdmodwr                    (NPI_RdModWr[6])
    );
  end
  else begin : INACTIVE_6
      // tie off unused inputs to mpmc_core
      assign pim_rst[6] = 1'b0;
      if (C_NUM_PORTS > 6) begin : TIE_OFF_6
        assign NPI_Addr[6*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX] = 0;
        assign NPI_AddrReq[6] = 0;
        assign NPI_RNW[6] = 0;
        assign NPI_Size[6*4 +: 4] = 0;
        assign NPI_WrFIFO_Data[6*P_PIX_DATA_WIDTH_MAX +: P_PIM6_DATA_WIDTH] = 0;
        assign NPI_WrFIFO_BE[6*P_PIX_BE_WIDTH_MAX +: P_PIM6_BE_WIDTH] = 0;
        assign NPI_WrFIFO_Push[6] = 0;
        assign NPI_WrFIFO_Flush[6] = 0;
        assign NPI_RdFIFO_Pop[6] = 0;
        assign NPI_RdFIFO_Flush[6] = 0;
      end
    end
  endgenerate
  generate
  if (C_NUM_PORTS > 7 && C_PIM7_BASETYPE == 1)
    begin : DUALXCL7_INST
      assign pim_rst[7] = 1'b0;
      dualxcl
      #(
        .C_FAMILY                   (C_BASEFAMILY),
        .C_PI_A_SUBTYPE             (C_PIM7_SUBTYPE),
        .C_PI_B_SUBTYPE             (P_PIM7_B_SUBTYPE),
        .C_PI_BASEADDR              (P_PIM7_BASEADDR),
        .C_PI_HIGHADDR              (P_PIM7_HIGHADDR),
        .C_PI_OFFSET                (C_PIM7_OFFSET),
        .C_PI_ADDR_WIDTH            (P_PIM7_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM7_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM7_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM7_RDWDADDR_WIDTH),
        .C_PI_RDDATA_DELAY          (P_PIM7_RD_FIFO_LATENCY),
        .C_XCL_A_WRITEXFER          (C_XCL7_WRITEXFER),
        .C_XCL_A_LINESIZE           (C_XCL7_LINESIZE),
        .C_XCL_B_WRITEXFER          (C_XCL7_B_WRITEXFER),
        .C_XCL_B_LINESIZE           (C_XCL7_B_LINESIZE),
        .C_XCL_PIPE_STAGES          (C_XCL7_PIPE_STAGES),
        .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
        .C_MEM_SDR_DATA_WIDTH       (P_MEM_DATA_WIDTH_INT)
      )
      dualxcl_7
      (
        .Clk                        (FSL7_M_Clk),
        .Clk_MPMC                   (MPMC_Clk0),
        .Rst                        (Rst_topim[7]),
        .FSL_A_M_Clk                (FSL7_M_Clk),
        .FSL_A_M_Write              (FSL7_M_Write),
        .FSL_A_M_Data               (FSL7_M_Data),
        .FSL_A_M_Control            (FSL7_M_Control),
        .FSL_A_M_Full               (FSL7_M_Full),
        .FSL_A_S_Clk                (FSL7_S_Clk),
        .FSL_A_S_Read               (FSL7_S_Read),
        .FSL_A_S_Data               (FSL7_S_Data),
        .FSL_A_S_Control            (FSL7_S_Control),
        .FSL_A_S_Exists             (FSL7_S_Exists),
        .FSL_B_M_Clk                (FSL7_B_M_Clk),
        .FSL_B_M_Write              (FSL7_B_M_Write),
        .FSL_B_M_Data               (FSL7_B_M_Data),
        .FSL_B_M_Control            (FSL7_B_M_Control),
        .FSL_B_M_Full               (FSL7_B_M_Full),
        .FSL_B_S_Clk                (FSL7_B_S_Clk),
        .FSL_B_S_Read               (FSL7_B_S_Read),
        .FSL_B_S_Data               (FSL7_B_S_Data),
        .FSL_B_S_Control            (FSL7_B_S_Control),
        .FSL_B_S_Exists             (FSL7_B_S_Exists),
        .PI_Addr                    (NPI_Addr[7*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[7]),
        .PI_AddrAck                 (NPI_AddrAck[7]),
        .PI_RNW                     (NPI_RNW[7]),
        .PI_RdModWr                 (NPI_RdModWr[7]),
        .PI_Size                    (NPI_Size[7*4 +: 4]),
        .PI_InitDone                (NPI_InitDone[7]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[7*P_PIX_BE_WIDTH_MAX +: P_PIM7_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[7]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[7]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[7*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIM7_RDWDADDR_WIDTH]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[7]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[7]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[7]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[7])
      );
    end
  else if (C_NUM_PORTS > 7 && C_PIM7_BASETYPE == 2) begin : PLB_7_INST
      assign pim_rst[7] = SPLB7_Rst;
      plbv46_pim_wrapper
      #(
        .C_SPLB_DWIDTH              (C_SPLB7_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SPLB7_NATIVE_DWIDTH),
        .C_SPLB_AWIDTH              (C_SPLB7_AWIDTH),
        .C_SPLB_NUM_MASTERS         (C_SPLB7_NUM_MASTERS),
        .C_SPLB_MID_WIDTH           (C_SPLB7_MID_WIDTH),
        .C_SPLB_P2P                 (C_SPLB7_P2P),
        .C_SPLB_SUPPORT_BURSTS      (C_SPLB7_SUPPORT_BURSTS),
        .C_SPLB_SMALLEST_MASTER     (C_SPLB7_SMALLEST_MASTER),
        .C_PLBV46_PIM_TYPE          (C_PIM7_SUBTYPE),
        .C_MPMC_PIM_BASEADDR        (P_PIM7_BASEADDR[31:2]),
        .C_MPMC_PIM_HIGHADDR        (P_PIM7_HIGHADDR[31:2]),
        .C_MPMC_PIM_OFFSET          (C_PIM7_OFFSET[31:2]),
        .C_MPMC_PIM_DATA_WIDTH      (P_PIM7_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH      (P_PIM7_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY  (P_PIM7_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH  (P_PIM7_RDWDADDR_WIDTH),
        .C_MPMC_PIM_SDR_DWIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_MEM_HAS_BE      (P_MEM_HAS_BE),
        .C_MPMC_PIM_WR_FIFO_TYPE    (P_PI7_WR_FIFO_TYPE),
        .C_MPMC_PIM_RD_FIFO_TYPE    (P_PI7_RD_FIFO_TYPE),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      plbv46_pim_7
      (
        .MPMC_CLK                   (MPMC_Clk0),
        .MPMC_Rst                   (Rst_topim[7]),
        .SPLB_Clk                   (SPLB7_Clk),
        .SPLB_Rst                   (Rst_topim[7]),
        .SPLB_PLB_ABus              (SPLB7_PLB_ABus),
        .SPLB_PLB_UABus             (SPLB7_PLB_UABus),
        .SPLB_PLB_PAValid           (SPLB7_PLB_PAValid),
        .SPLB_PLB_SAValid           (SPLB7_PLB_SAValid),
        .SPLB_PLB_rdPrim            (SPLB7_PLB_rdPrim),
        .SPLB_PLB_wrPrim            (SPLB7_PLB_wrPrim),
        .SPLB_PLB_masterID          (SPLB7_PLB_masterID),
        .SPLB_PLB_abort             (SPLB7_PLB_abort),
        .SPLB_PLB_busLock           (SPLB7_PLB_busLock),
        .SPLB_PLB_RNW               (SPLB7_PLB_RNW),
        .SPLB_PLB_BE                (SPLB7_PLB_BE),
        .SPLB_PLB_MSize             (SPLB7_PLB_MSize),
        .SPLB_PLB_size              (SPLB7_PLB_size),
        .SPLB_PLB_type              (SPLB7_PLB_type),
        .SPLB_PLB_lockErr           (SPLB7_PLB_lockErr),
        .SPLB_PLB_wrDBus            (SPLB7_PLB_wrDBus),
        .SPLB_PLB_wrBurst           (SPLB7_PLB_wrBurst),
        .SPLB_PLB_rdBurst           (SPLB7_PLB_rdBurst),
        .SPLB_PLB_wrPendReq         (SPLB7_PLB_wrPendReq),
        .SPLB_PLB_rdPendReq         (SPLB7_PLB_rdPendReq),
        .SPLB_PLB_wrPendPri         (SPLB7_PLB_wrPendPri),
        .SPLB_PLB_rdPendPri         (SPLB7_PLB_rdPendPri),
        .SPLB_PLB_reqPri            (SPLB7_PLB_reqPri),
        .SPLB_PLB_TAttribute        (SPLB7_PLB_TAttribute),
        .SPLB_Sl_addrAck            (SPLB7_Sl_addrAck),
        .SPLB_Sl_SSize              (SPLB7_Sl_SSize),
        .SPLB_Sl_wait               (SPLB7_Sl_wait),
        .SPLB_Sl_rearbitrate        (SPLB7_Sl_rearbitrate),
        .SPLB_Sl_wrDAck             (SPLB7_Sl_wrDAck),
        .SPLB_Sl_wrComp             (SPLB7_Sl_wrComp),
        .SPLB_Sl_wrBTerm            (SPLB7_Sl_wrBTerm),
        .SPLB_Sl_rdDBus             (SPLB7_Sl_rdDBus),
        .SPLB_Sl_rdWdAddr           (SPLB7_Sl_rdWdAddr),
        .SPLB_Sl_rdDAck             (SPLB7_Sl_rdDAck),
        .SPLB_Sl_rdComp             (SPLB7_Sl_rdComp),
        .SPLB_Sl_rdBTerm            (SPLB7_Sl_rdBTerm),
        .SPLB_Sl_MBusy              (SPLB7_Sl_MBusy),
        .SPLB_Sl_MWrErr             (SPLB7_Sl_MWrErr),
        .SPLB_Sl_MRdErr             (SPLB7_Sl_MRdErr),
        .SPLB_Sl_MIRQ               (SPLB7_Sl_MIRQ),
        .MPMC_PIM_InitDone          (NPI_InitDone[7]),
        .MPMC_PIM_Addr              (NPI_Addr[7*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq           (NPI_AddrReq[7]),
        .MPMC_PIM_AddrAck           (NPI_AddrAck[7]),
        .MPMC_PIM_RNW               (NPI_RNW[7]),
        .MPMC_PIM_Size              (NPI_Size[7*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data       (NPI_WrFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE         (NPI_WrFIFO_BE[7*P_PIX_BE_WIDTH_MAX +: P_PIM7_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push       (NPI_WrFIFO_Push[7]),
        .MPMC_PIM_WrFIFO_Empty      (NPI_WrFIFO_Empty[7]),
        .MPMC_PIM_WrFIFO_AlmostFull (NPI_WrFIFO_AlmostFull[7]),
        .MPMC_PIM_RdFIFO_Latency    (NPI_RdFIFO_Latency[7*2 +: 2]),
        .MPMC_PIM_RdFIFO_Data       (NPI_RdFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop        (NPI_RdFIFO_Pop[7]),
        .MPMC_PIM_RdFIFO_Empty      (NPI_RdFIFO_Empty[7]),
        .MPMC_PIM_RdFIFO_RdWd_Addr  (NPI_RdFIFO_RdWdAddr[7*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_RdFIFO_Data_Available  (NPI_RdFIFO_DataAvailable[7]),
        .MPMC_PIM_RdFIFO_Flush      (NPI_RdFIFO_Flush[7]),
        .MPMC_PIM_WrFIFO_Flush      (NPI_WrFIFO_Flush[7]),
        .MPMC_PIM_RdModWr           (NPI_RdModWr[7])
      );
  end
  else if (C_NUM_PORTS > 7 && (C_PIM7_BASETYPE == 3)) begin : SDMA7_INST
      assign pim_rst[7] = SDMA_CTRL7_Rst;
      sdma_wrapper
      #(
        .C_PI_BASEADDR              (P_PIM7_BASEADDR[31:2]),
        .C_PI_HIGHADDR              (P_PIM7_HIGHADDR[31:2]),
        .C_PI_ADDR_WIDTH            (P_PIM7_ADDR_WIDTH),
        .C_PI_DATA_WIDTH            (P_PIM7_DATA_WIDTH),
        .C_PI_BE_WIDTH              (P_PIM7_BE_WIDTH),
        .C_PI_RDWDADDR_WIDTH        (P_PIM7_RDWDADDR_WIDTH),
        .C_SDMA_BASEADDR            (P_SDMA_CTRL7_BASEADDR[31:2]),
        .C_SDMA_HIGHADDR            (P_SDMA_CTRL7_HIGHADDR[31:2]),
        .C_COMPLETED_ERR_TX         (C_SDMA7_COMPLETED_ERR_TX),
        .C_COMPLETED_ERR_RX         (C_SDMA7_COMPLETED_ERR_RX),
        .C_PRESCALAR                (C_SDMA7_PRESCALAR),
        .C_PI_RDDATA_DELAY          (P_PIM7_RD_FIFO_LATENCY),
        .C_PI2LL_CLK_RATIO          (C_SDMA7_PI2LL_CLK_RATIO),
        .C_SPLB_P2P                 (C_SDMA_CTRL7_P2P),
        .C_SPLB_MID_WIDTH           (C_SDMA_CTRL7_MID_WIDTH),
        .C_SPLB_NUM_MASTERS         (C_SDMA_CTRL7_NUM_MASTERS),
        .C_SPLB_AWIDTH              (C_SDMA_CTRL7_AWIDTH),
        .C_SPLB_DWIDTH              (C_SDMA_CTRL7_DWIDTH),
        .C_SPLB_NATIVE_DWIDTH       (C_SDMA_CTRL7_NATIVE_DWIDTH),
        .C_FAMILY                   (C_BASEFAMILY)
      )
      mpmc_sdma_7
      (
        .LLink_Clk                  (SDMA7_Clk),
        .PI_Clk                     (MPMC_Clk0),
        // PLBv46 Signals
        .SPLB_Clk                   (SDMA_CTRL7_Clk),
        .SPLB_Rst                   (Rst_topim[7]),
        .PLB_ABus                   (SDMA_CTRL7_PLB_ABus),
        .PLB_UABus                  (SDMA_CTRL7_PLB_UABus),
        .PLB_PAValid                (SDMA_CTRL7_PLB_PAValid),
        .PLB_SAValid                (SDMA_CTRL7_PLB_SAValid),
        .PLB_rdPrim                 (SDMA_CTRL7_PLB_rdPrim),
        .PLB_wrPrim                 (SDMA_CTRL7_PLB_wrPrim),
        .PLB_masterID               (SDMA_CTRL7_PLB_masterID),
        .PLB_abort                  (SDMA_CTRL7_PLB_abort),
        .PLB_busLock                (SDMA_CTRL7_PLB_busLock),
        .PLB_RNW                    (SDMA_CTRL7_PLB_RNW),
        .PLB_BE                     (SDMA_CTRL7_PLB_BE),
        .PLB_MSize                  (SDMA_CTRL7_PLB_MSize),
        .PLB_size                   (SDMA_CTRL7_PLB_size),
        .PLB_type                   (SDMA_CTRL7_PLB_type),
        .PLB_lockErr                (SDMA_CTRL7_PLB_lockErr),
        .PLB_wrDBus                 (SDMA_CTRL7_PLB_wrDBus),
        .PLB_wrBurst                (SDMA_CTRL7_PLB_wrBurst),
        .PLB_rdBurst                (SDMA_CTRL7_PLB_rdBurst),
        .PLB_wrPendReq              (SDMA_CTRL7_PLB_wrPendReq),
        .PLB_rdPendReq              (SDMA_CTRL7_PLB_rdPendReq),
        .PLB_wrPendPri              (SDMA_CTRL7_PLB_wrPendPri),
        .PLB_rdPendPri              (SDMA_CTRL7_PLB_rdPendPri),
        .PLB_reqPri                 (SDMA_CTRL7_PLB_reqPri),
        .PLB_TAttribute             (SDMA_CTRL7_PLB_TAttribute),
        .Sln_addrAck                 (SDMA_CTRL7_Sl_addrAck),
        .Sln_SSize                   (SDMA_CTRL7_Sl_SSize),
        .Sln_wait                    (SDMA_CTRL7_Sl_wait),
        .Sln_rearbitrate             (SDMA_CTRL7_Sl_rearbitrate),
        .Sln_wrDAck                  (SDMA_CTRL7_Sl_wrDAck),
        .Sln_wrComp                  (SDMA_CTRL7_Sl_wrComp),
        .Sln_wrBTerm                 (SDMA_CTRL7_Sl_wrBTerm),
        .Sln_rdDBus                  (SDMA_CTRL7_Sl_rdDBus),
        .Sln_rdWdAddr                (SDMA_CTRL7_Sl_rdWdAddr),
        .Sln_rdDAck                  (SDMA_CTRL7_Sl_rdDAck),
        .Sln_rdComp                  (SDMA_CTRL7_Sl_rdComp),
        .Sln_rdBTerm                 (SDMA_CTRL7_Sl_rdBTerm),
        .Sln_MBusy                   (SDMA_CTRL7_Sl_MBusy),
        .Sln_MWrErr                  (SDMA_CTRL7_Sl_MWrErr),
        .Sln_MRdErr                  (SDMA_CTRL7_Sl_MRdErr),
        .Sln_MIRQ                    (SDMA_CTRL7_Sl_MIRQ),
        // MPMC NPI Signals
        .PI_Addr                    (NPI_Addr[7*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .PI_AddrReq                 (NPI_AddrReq[7]),
        .PI_AddrAck                 (NPI_AddrAck[7]),
        .PI_RdModWr                 (NPI_RdModWr[7]),
        .PI_RNW                     (NPI_RNW[7]),
        .PI_Size                    (NPI_Size[7*4 +: 4]),
        .PI_WrFIFO_Data             (NPI_WrFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .PI_WrFIFO_BE               (NPI_WrFIFO_BE[7*P_PIX_BE_WIDTH_MAX +: P_PIM7_BE_WIDTH]),
        .PI_WrFIFO_Push             (NPI_WrFIFO_Push[7]),
        .PI_RdFIFO_Data             (NPI_RdFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .PI_RdFIFO_Pop              (NPI_RdFIFO_Pop[7]),
        .PI_RdFIFO_RdWdAddr         (NPI_RdFIFO_RdWdAddr[7*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .PI_WrFIFO_AlmostFull       (NPI_WrFIFO_AlmostFull[7]),
        .PI_WrFIFO_Flush            (NPI_WrFIFO_Flush[7]),
        .PI_WrFIFO_Empty            (NPI_WrFIFO_Empty[7]),
        .PI_RdFIFO_DataAvailable    (NPI_RdFIFO_DataAvailable[7]),
        .PI_RdFIFO_Empty            (NPI_RdFIFO_Empty[7]),
        .PI_RdFIFO_Flush            (NPI_RdFIFO_Flush[7]),
        //.PI_InitDone                (NPI_InitDone[7]),
        // SDMA Signals
        .TX_D                       (SDMA7_TX_D),
        .TX_Rem                     (SDMA7_TX_Rem),
        .TX_SOF                     (SDMA7_TX_SOF),
        .TX_EOF                     (SDMA7_TX_EOF),
        .TX_SOP                     (SDMA7_TX_SOP),
        .TX_EOP                     (SDMA7_TX_EOP),
        .TX_Src_Rdy                 (SDMA7_TX_Src_Rdy),
        .TX_Dst_Rdy                 (SDMA7_TX_Dst_Rdy),
        .RX_D                       (SDMA7_RX_D),
        .RX_Rem                     (SDMA7_RX_Rem),
        .RX_SOF                     (SDMA7_RX_SOF),
        .RX_EOF                     (SDMA7_RX_EOF),
        .RX_SOP                     (SDMA7_RX_SOP),
        .RX_EOP                     (SDMA7_RX_EOP),
        .RX_Src_Rdy                 (SDMA7_RX_Src_Rdy),
        .RX_Dst_Rdy                 (SDMA7_RX_Dst_Rdy),
        .SDMA_RstOut                (SDMA7_RstOut),
        .SDMA_Rx_IntOut             (SDMA7_Rx_IntOut),
        .SDMA_Tx_IntOut             (SDMA7_Tx_IntOut)
      );
  end
  else if (C_NUM_PORTS > 7 && (C_PIM7_BASETYPE == 4)) begin : NPI7_INST
      // do nothing, pass signals straight through
      assign pim_rst[7] = 1'b0;
      assign PIM7_InitDone = NPI_InitDone[7];
      assign NPI_AddrReq[7] = PIM7_AddrReq;
      assign PIM7_AddrAck = NPI_AddrAck[7];
      assign NPI_Addr[7*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]    = PIM7_Addr;
      assign NPI_RNW[7] = PIM7_RNW;
      assign NPI_Size[7*4 +: 4] = PIM7_Size;
      assign NPI_RdModWr[7] = PIM7_RdModWr;
      assign NPI_WrFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH] = PIM7_WrFIFO_Data;
      assign NPI_WrFIFO_BE[7*P_PIX_BE_WIDTH_MAX +: P_PIM7_BE_WIDTH] = PIM7_WrFIFO_BE;
      assign NPI_WrFIFO_Push[7] = PIM7_WrFIFO_Push;
      assign PIM7_RdFIFO_Data = NPI_RdFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH];
      assign NPI_RdFIFO_Pop[7] = PIM7_RdFIFO_Pop;
      assign PIM7_RdFIFO_RdWdAddr = NPI_RdFIFO_RdWdAddr[7*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX];
      assign PIM7_WrFIFO_Empty = NPI_WrFIFO_Empty[7];
      assign PIM7_WrFIFO_AlmostFull = NPI_WrFIFO_AlmostFull[7];
      assign NPI_WrFIFO_Flush[7] = PIM7_WrFIFO_Flush;
      assign PIM7_RdFIFO_Empty = NPI_RdFIFO_Empty[7];
      assign NPI_RdFIFO_Flush[7] = PIM7_RdFIFO_Flush;
      assign PIM7_RdFIFO_Latency = NPI_RdFIFO_Latency[7*2 +: 2];
  end
  else if (C_NUM_PORTS > 7 && (C_PIM7_BASETYPE == 5)) begin : PPC440MC7_INST
      assign pim_rst[7] = 1'b0;
      mib_pim
      #(
        .C_MPMC_PIM_DATA_WIDTH          (P_PIM7_DATA_WIDTH),
        .C_MPMC_PIM_ADDR_WIDTH          (P_PIM7_ADDR_WIDTH),
        .C_MPMC_PIM_RDFIFO_LATENCY      (P_PIM7_RD_FIFO_LATENCY),
        .C_MPMC_PIM_RDWDADDR_WIDTH      (P_PIM7_RDWDADDR_WIDTH),
        .C_MPMC_PIM_MEM_DATA_WIDTH      (P_MEM_DATA_WIDTH_INT),
        .C_MPMC_PIM_BURST_LENGTH        (C_PPC440MC7_BURST_LENGTH),
        .C_MPMC_PIM_PIPE_STAGES         (C_PPC440MC7_PIPE_STAGES),
        .C_MPMC_PIM_WRFIFO_TYPE         (P_PI7_WR_FIFO_TYPE),
        .C_MPMC_PIM_OFFSET              (C_PIM7_OFFSET),
        .C_FAMILY                       (C_BASEFAMILY)
      )
      ppc440mc
      (
        .MPMC_Clk                       (MPMC_Clk0),
        .MPMC_Rst                       (Rst_topim[7]),
        .MPMC_PIM_Addr                  (NPI_Addr[7*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .MPMC_PIM_AddrReq               (NPI_AddrReq[7]),
        .MPMC_PIM_AddrAck               (NPI_AddrAck[7]),
        .MPMC_PIM_RdModWr               (NPI_RdModWr[7]),
        .MPMC_PIM_RNW                   (NPI_RNW[7]),
        .MPMC_PIM_Size                  (NPI_Size[7*4 +: 4]),
        .MPMC_PIM_WrFIFO_Data           (NPI_WrFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .MPMC_PIM_WrFIFO_BE             (NPI_WrFIFO_BE[7*P_PIX_BE_WIDTH_MAX +: P_PIM7_BE_WIDTH]),
        .MPMC_PIM_WrFIFO_Push           (NPI_WrFIFO_Push[7]),
        .MPMC_PIM_RdFIFO_Data           (NPI_RdFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .MPMC_PIM_RdFIFO_Pop            (NPI_RdFIFO_Pop[7]),
        .MPMC_PIM_RdFIFO_RdWdAddr       (NPI_RdFIFO_RdWdAddr[7*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .MPMC_PIM_WrFIFO_AlmostFull     (NPI_WrFIFO_AlmostFull[7]),
        .MPMC_PIM_WrFIFO_Flush          (NPI_WrFIFO_Flush[7]),
        .MPMC_PIM_WrFIFO_Empty          (NPI_WrFIFO_Empty[7]),
        .MPMC_PIM_RdFIFO_DataAvailable  (NPI_RdFIFO_DataAvailable[7]),
        .MPMC_PIM_RdFIFO_Empty          (NPI_RdFIFO_Empty[7]),
        .MPMC_PIM_RdFIFO_Flush          (NPI_RdFIFO_Flush[7]),
        .MPMC_PIM_InitDone              (NPI_InitDone[7]),
        .MPMC_PIM_Rd_FIFO_Latency       (NPI_RdFIFO_Latency[7*2 +: 2]),
        .mi_mcaddressvalid              (PPC440MC7_MIMCAddressValid),
        .mi_mcaddress                   (PPC440MC7_MIMCAddress),
        .mi_mcbankconflict              (PPC440MC7_MIMCBankConflict),
        .mi_mcrowconflict               (PPC440MC7_MIMCRowConflict),
        .mi_mcbyteenable                (PPC440MC7_MIMCByteEnable),
        .mi_mcwritedata                 (PPC440MC7_MIMCWriteData),
        .mi_mcreadnotwrite              (PPC440MC7_MIMCReadNotWrite),
        .mi_mcwritedatavalid            (PPC440MC7_MIMCWriteDataValid),
        .mc_miaddrreadytoaccept         (PPC440MC7_MCMIAddrReadyToAccept),
        .mc_mireaddata                  (PPC440MC7_MCMIReadData),
        .mc_mireaddataerr               (PPC440MC7_MCMIReadDataErr),
        .mc_mireaddatavalid             (PPC440MC7_MCMIReadDataValid)
    );
  end
  else if (C_NUM_PORTS > 7 && (C_PIM7_BASETYPE == 6)) begin : VFBC7_INST
      assign pim_rst[7] = 1'b0;
      assign NPI_RdModWr[7] = 1'b1;
      vfbc_pim_wrapper
      #(
        .C_MPMC_BASEADDR  (C_MPMC_BASEADDR[31:2]),
        .C_MPMC_HIGHADDR  (C_MPMC_HIGHADDR[31:2]),
        .C_PIM_DATA_WIDTH               (P_PIM7_DATA_WIDTH),
        .C_CHIPSCOPE_ENABLE             (P_VFBC7_CHIPSCOPE_ENABLE),
        .C_FAMILY                       (C_BASEFAMILY),
        .VFBC_BURST_LENGTH              (P_VFBC7_BURST_LENGTH),
        .CMD0_PORT_ID                   (P_VFBC7_CMD_PORT_ID),
        .CMD0_FIFO_DEPTH                (C_VFBC7_CMD_FIFO_DEPTH),
        .CMD0_ASYNC_CLOCK               (P_VFBC7_ASYNC_CLOCK),
        .CMD0_AFULL_COUNT               (C_VFBC7_CMD_AFULL_COUNT),
        .WD0_ENABLE                     (P_VFBC7_WD_ENABLE),
        .WD0_DATA_WIDTH                 (P_VFBC7_WD_DATA_WIDTH),
        .WD0_FIFO_DEPTH                 (P_VFBC7_WD_FIFO_DEPTH),
        .WD0_ASYNC_CLOCK                (P_VFBC7_ASYNC_CLOCK),
        .WD0_AFULL_COUNT                (P_VFBC7_WD_AFULL_COUNT),
        .WD0_BYTEEN_ENABLE              (P_VFBC7_WD_BYTEEN_ENABLE),
        .RD0_ENABLE                     (P_VFBC7_RD_ENABLE),
        .RD0_DATA_WIDTH                 (P_VFBC7_RD_DATA_WIDTH),
        .RD0_FIFO_DEPTH                 (P_VFBC7_RD_FIFO_DEPTH),
        .RD0_ASYNC_CLOCK                (P_VFBC7_ASYNC_CLOCK),
        .RD0_AEMPTY_COUNT               (P_VFBC7_RD_AEMPTY_COUNT)
      )
      vfbc
      (
        .vfbc_clk                       (MPMC_Clk0),
        .srst                           (Rst_topim[7]),
        .cmd0_clk                       (VFBC7_Cmd_Clk),
        .cmd0_reset                     (VFBC7_Cmd_Reset),
        .cmd0_data                      (VFBC7_Cmd_Data),
        .cmd0_write                     (VFBC7_Cmd_Write),
        .cmd0_end                       (VFBC7_Cmd_End),
        .cmd0_full                      (VFBC7_Cmd_Full),
        .cmd0_almost_full               (VFBC7_Cmd_Almost_Full),
        .cmd0_idle                      (VFBC7_Cmd_Idle),
        .wd0_clk                        (VFBC7_Wd_Clk),
        .wd0_reset                      (VFBC7_Wd_Reset),
        .wd0_write                      (VFBC7_Wd_Write),
        .wd0_end_burst                  (VFBC7_Wd_End_Burst),
        .wd0_flush                      (VFBC7_Wd_Flush),
        .wd0_data                       (VFBC7_Wd_Data),
        .wd0_data_be                    (VFBC7_Wd_Data_BE),
        .wd0_full                       (VFBC7_Wd_Full),
        .wd0_almost_full                (VFBC7_Wd_Almost_Full),
        .rd0_clk                        (VFBC7_Rd_Clk),
        .rd0_reset                      (VFBC7_Rd_Reset),
        .rd0_read                       (VFBC7_Rd_Read),
        .rd0_end_burst                  (VFBC7_Rd_End_Burst),
        .rd0_flush                      (VFBC7_Rd_Flush),
        .rd0_data                       (VFBC7_Rd_Data),
        .rd0_empty                      (VFBC7_Rd_Empty),
        .rd0_almost_empty               (VFBC7_Rd_Almost_Empty),
        .npi_init_done                  (NPI_InitDone[7]),
        .npi_addr_ack                   (NPI_AddrAck[7]),
        .npi_rdfifo_word_add            (NPI_RdFIFO_RdWdAddr[7*P_PIX_RDWDADDR_WIDTH_MAX +: P_PIX_RDWDADDR_WIDTH_MAX]),
        .npi_rdfifo_data                (NPI_RdFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .npi_rdfifo_latency             (NPI_RdFIFO_Latency[7*2 +: 2]),
        .npi_rdfifo_empty               (NPI_RdFIFO_Empty[7]),
        .npi_wrfifo_almost_full         (NPI_WrFIFO_AlmostFull[7]),
        .npi_address                    (NPI_Addr[7*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX]),
        .npi_addr_req                   (NPI_AddrReq[7]),
        .npi_size                       (NPI_Size[7*4 +: 4]),
        .npi_rnw                        (NPI_RNW[7]),
        .npi_rdfifo_pop                 (NPI_RdFIFO_Pop[7]),
        .npi_rdfifo_flush               (NPI_RdFIFO_Flush[7]),
        .npi_wrfifo_data                (NPI_WrFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH]),
        .npi_wrfifo_be                  (NPI_WrFIFO_BE[7*P_PIX_BE_WIDTH_MAX +: P_PIM7_BE_WIDTH]),
        .npi_wrfifo_push                (NPI_WrFIFO_Push[7]),
        .npi_wrfifo_flush               (NPI_WrFIFO_Flush[7])
//        .npi_rdmodwr                    (NPI_RdModWr[7])
    );
  end
  else begin : INACTIVE_7
      // tie off unused inputs to mpmc_core
      assign pim_rst[7] = 1'b0;
      if (C_NUM_PORTS > 7) begin : TIE_OFF_7
        assign NPI_Addr[7*P_PIX_ADDR_WIDTH_MAX +: P_PIX_ADDR_WIDTH_MAX] = 0;
        assign NPI_AddrReq[7] = 0;
        assign NPI_RNW[7] = 0;
        assign NPI_Size[7*4 +: 4] = 0;
        assign NPI_WrFIFO_Data[7*P_PIX_DATA_WIDTH_MAX +: P_PIM7_DATA_WIDTH] = 0;
        assign NPI_WrFIFO_BE[7*P_PIX_BE_WIDTH_MAX +: P_PIM7_BE_WIDTH] = 0;
        assign NPI_WrFIFO_Push[7] = 0;
        assign NPI_WrFIFO_Flush[7] = 0;
        assign NPI_RdFIFO_Pop[7] = 0;
        assign NPI_RdFIFO_Flush[7] = 0;
      end
    end
  endgenerate

  generate
    if ((C_INCLUDE_ECC_SUPPORT == 1) || (C_PM_ENABLE  == 1) || (C_USE_STATIC_PHY  == 1) || (C_DEBUG_REG_ENABLE == 1))
      begin : mpmc_ctrl_inst

        assign MPMC_Status_Reg_Out[31:0] = MPMC_Status_Reg0[0:31];

        mpmc_ctrl_if
        #(
           .C_ECC_NUM_REG                   (P_ECC_NUM_REG),
           .C_STATIC_PHY_NUM_REG            (P_STATIC_PHY_NUM_REG),
           .C_MPMC_STATUS_NUM_REG           (P_MPMC_STATUS_NUM_REG),
           .C_PM_CTRL_NUM_REG               (P_PM_CTRL_NUM_REG),
           .C_ECC_REG_BASEADDR              (P_ECC_REG_BASEADDR),
           .C_ECC_REG_HIGHADDR              (P_ECC_REG_HIGHADDR),
           .C_STATIC_PHY_REG_BASEADDR       (P_STATIC_PHY_REG_BASEADDR),
           .C_STATIC_PHY_REG_HIGHADDR       (P_STATIC_PHY_REG_HIGHADDR),
           .C_DEBUG_CTRL_MEM_BASEADDR       (P_DEBUG_CTRL_MEM_BASEADDR),
           .C_DEBUG_CTRL_MEM_HIGHADDR       (P_DEBUG_CTRL_MEM_HIGHADDR),
           .C_MPMC_STATUS_REG_BASEADDR      (P_MPMC_STATUS_REG_BASEADDR),
           .C_MPMC_STATUS_REG_HIGHADDR      (P_MPMC_STATUS_REG_HIGHADDR),
           .C_PM_CTRL_REG_BASEADDR          (P_PM_CTRL_REG_BASEADDR),
           .C_PM_CTRL_REG_HIGHADDR          (P_PM_CTRL_REG_HIGHADDR),
           .C_PM_DATA_MEM_BASEADDR          (P_PM_DATA_MEM_BASEADDR),
           .C_PM_DATA_MEM_HIGHADDR          (P_PM_DATA_MEM_HIGHADDR),
           .C_SPLB_AWIDTH                   (C_MPMC_CTRL_AWIDTH),
           .C_SPLB_DWIDTH                   (C_MPMC_CTRL_DWIDTH),
           .C_SPLB_NUM_MASTERS              (C_MPMC_CTRL_NUM_MASTERS),
           .C_SPLB_MID_WIDTH                (C_MPMC_CTRL_MID_WIDTH),
           .C_SPLB_NATIVE_DWIDTH            (C_MPMC_CTRL_NATIVE_DWIDTH),
           .C_SPLB_P2P                      (C_MPMC_CTRL_P2P),
           .C_SPLB_SUPPORT_BURSTS           (C_MPMC_CTRL_SUPPORT_BURSTS),
           .C_SPLB_SMALLEST_MASTER          (C_MPMC_CTRL_SMALLEST_MASTER),
           .C_FAMILY                        (C_BASEFAMILY)
        )
        mpmc_ctrl_if_0
        (
           .MPMC_Clk                        (MPMC_Clk0),
           .ECC_Reg_CE                      (ECC_Reg_CE),
           .ECC_Reg_In                      (ECC_Reg_In),
           .ECC_Reg_Out                     (ECC_Reg_Out),
           .Static_Phy_Reg_CE               (Static_Phy_Reg_CE),
           .Static_Phy_Reg_In               (Static_Phy_Reg_In),
           .Static_Phy_Reg_Out              (Static_Phy_Reg_Out),
           .Debug_Ctrl_Addr                 (Debug_Ctrl_Addr),
           .Debug_Ctrl_WE                   (Debug_Ctrl_WE),
           .Debug_Ctrl_In                   (Debug_Ctrl_In),
           .Debug_Ctrl_Out                  (Debug_Ctrl_Out),
           .MPMC_Status_Reg_CE              (MPMC_Status_Reg_CE),
           .MPMC_Status_Reg_In              (MPMC_Status_Reg_In),
           .MPMC_Status_Reg_Out             (MPMC_Status_Reg_Out),
           .PM_Ctrl_Reg_CE                  (PM_Ctrl_Reg_CE),
           .PM_Ctrl_Reg_In                  (PM_Ctrl_Reg_In),
           .PM_Ctrl_Reg_Out                 (PM_Ctrl_Reg_Out),
           .PM_Data_Out                     (PM_Data_Out),
           .PM_Data_Addr                    (PM_Data_Addr),
           .SPLB_Clk                        (MPMC_CTRL_Clk),
           .SPLB_Rst                        (Rst_d2),
           .PLB_ABus                        (MPMC_CTRL_PLB_ABus),
           .PLB_UABus                       (MPMC_CTRL_PLB_UABus),
           .PLB_PAValid                     (MPMC_CTRL_PLB_PAValid),
           .PLB_SAValid                     (MPMC_CTRL_PLB_SAValid),
           .PLB_rdPrim                      (MPMC_CTRL_PLB_rdPrim),
           .PLB_wrPrim                      (MPMC_CTRL_PLB_wrPrim),
           .PLB_masterID                    (MPMC_CTRL_PLB_masterID),
           .PLB_abort                       (MPMC_CTRL_PLB_abort),
           .PLB_busLock                     (MPMC_CTRL_PLB_busLock),
           .PLB_RNW                         (MPMC_CTRL_PLB_RNW),
           .PLB_BE                          (MPMC_CTRL_PLB_BE),
           .PLB_MSize                       (MPMC_CTRL_PLB_MSize),
           .PLB_size                        (MPMC_CTRL_PLB_size),
           .PLB_type                        (MPMC_CTRL_PLB_type),
           .PLB_lockErr                     (MPMC_CTRL_PLB_lockErr),
           .PLB_wrDBus                      (MPMC_CTRL_PLB_wrDBus),
           .PLB_wrBurst                     (MPMC_CTRL_PLB_wrBurst),
           .PLB_rdBurst                     (MPMC_CTRL_PLB_rdBurst),
           .PLB_wrPendReq                   (MPMC_CTRL_PLB_wrPendReq),
           .PLB_rdPendReq                   (MPMC_CTRL_PLB_rdPendReq),
           .PLB_wrPendPri                   (MPMC_CTRL_PLB_wrPendPri),
           .PLB_rdPendPri                   (MPMC_CTRL_PLB_rdPendPri),
           .PLB_reqPri                      (MPMC_CTRL_PLB_reqPri),
           .PLB_TAttribute                  (MPMC_CTRL_PLB_TAttribute),
           .Sl_addrAck                      (MPMC_CTRL_Sl_addrAck),
           .Sl_SSize                        (MPMC_CTRL_Sl_SSize),
           .Sl_wait                         (MPMC_CTRL_Sl_wait),
           .Sl_rearbitrate                  (MPMC_CTRL_Sl_rearbitrate),
           .Sl_wrDAck                       (MPMC_CTRL_Sl_wrDAck),
           .Sl_wrComp                       (MPMC_CTRL_Sl_wrComp),
           .Sl_wrBTerm                      (MPMC_CTRL_Sl_wrBTerm),
           .Sl_rdDBus                       (MPMC_CTRL_Sl_rdDBus),
           .Sl_rdWdAddr                     (MPMC_CTRL_Sl_rdWdAddr),
           .Sl_rdDAck                       (MPMC_CTRL_Sl_rdDAck),
           .Sl_rdComp                       (MPMC_CTRL_Sl_rdComp),
           .Sl_rdBTerm                      (MPMC_CTRL_Sl_rdBTerm),
           .Sl_MBusy                        (MPMC_CTRL_Sl_MBusy),
           .Sl_MWrErr                       (MPMC_CTRL_Sl_MWrErr),
           .Sl_MRdErr                       (MPMC_CTRL_Sl_MRdErr),
           .Sl_MIRQ                         (MPMC_CTRL_Sl_MIRQ)
        );
      end
      else begin : no_mpmc_ctrl_inst
        assign ECC_Reg_CE               = 1'b0;
        assign ECC_Reg_In               = {P_ECC_NUM_REG*32{1'b0}};
        assign Static_Phy_Reg_CE        = 1'b0;
        assign Static_Phy_Reg_In        = {P_STATIC_PHY_NUM_REG*32{1'b0}};
        assign Debug_Ctrl_Addr          = 32'b0;
        assign Debug_Ctrl_WE            = 1'b0;
        assign Debug_Ctrl_In            = 32'b0;
        assign MPMC_Status_Reg_CE       = 1'b0;
        assign MPMC_Status_Reg_In       = {P_MPMC_STATUS_NUM_REG*32{1'b0}};
        assign PM_Ctrl_Reg_CE           = 1'b0;
        assign PM_Ctrl_Reg_In           = {P_PM_CTRL_NUM_REG*32{1'b0}};
        assign PM_Data_Addr             = 32'b0;
        assign MPMC_CTRL_Sl_addrAck     = 1'b0;
        assign MPMC_CTRL_Sl_SSize       = 2'b0;
        assign MPMC_CTRL_Sl_wait        = 1'b0;
        assign MPMC_CTRL_Sl_rearbitrate = 1'b0;
        assign MPMC_CTRL_Sl_wrDAck      = 1'b0;
        assign MPMC_CTRL_Sl_wrComp      = 1'b0;
        assign MPMC_CTRL_Sl_wrBTerm     = 1'b0;
        assign MPMC_CTRL_Sl_rdDBus      = {C_MPMC_CTRL_DWIDTH{1'b0}};
        assign MPMC_CTRL_Sl_rdWdAddr    = 4'b0;
        assign MPMC_CTRL_Sl_rdDAck      = 1'b0;
        assign MPMC_CTRL_Sl_rdComp      = 1'b0;
        assign MPMC_CTRL_Sl_rdBTerm     = 1'b0;
        assign MPMC_CTRL_Sl_MBusy       = {C_MPMC_CTRL_NUM_MASTERS{1'b0}};
        assign MPMC_CTRL_Sl_MWrErr      = {C_MPMC_CTRL_NUM_MASTERS{1'b0}};
        assign MPMC_CTRL_Sl_MRdErr      = {C_MPMC_CTRL_NUM_MASTERS{1'b0}};
        assign MPMC_CTRL_Sl_MIRQ        = {C_MPMC_CTRL_NUM_MASTERS{1'b0}};
      end
  endgenerate

  generate
  if (C_PM_ENABLE == 1) begin : INST_PM
    mpmc_pm_npi_if
     #(
       .C_PM_USED                     (P_PM_USED),
       .C_PM_DC_CNTR                  (P_PM_DC_CNTR),
       .C_PM_DC_WIDTH                 (C_PM_DC_WIDTH),
       .C_PM_GC_CNTR                  (C_PM_GC_CNTR),
       .C_PM_GC_WIDTH                 (C_PM_GC_WIDTH),
       .C_PM_WR_TIMER_AWIDTH          (P_PM_WR_TIMER_AWIDTH),
       .C_PM_WR_TIMER_DEPTH           (P_PM_WR_TIMER_DEPTH),
       .C_PM_RD_TIMER_AWIDTH          (P_PM_RD_TIMER_AWIDTH),
       .C_PM_RD_TIMER_DEPTH           (P_PM_RD_TIMER_DEPTH),
       .C_PM_BUF_AWIDTH               (P_PM_BUF_AWIDTH),
       .C_PM_BUF_DEPTH                (P_PM_BUF_DEPTH),
       .C_PM_SHIFT_CNT_BY             (C_PM_SHIFT_CNT_BY),
       .C_NPI2PM_BUF_AWIDTH           (P_NPI2PM_BUF_AWIDTH),
       .C_NPI2PM_BUF_DEPTH            (P_NPI2PM_BUF_DEPTH),
       .C_NUM_PORTS                   (C_NUM_PORTS),
       .C_PI_DATA_WIDTH               (P_PI_DATA_WIDTH),
       .C_PI_RD_FIFO_TYPE             (P_PI_RD_FIFO_TYPE),
       .C_PI_WR_FIFO_TYPE             (P_PI_WR_FIFO_TYPE),
       .C_PIM_BASETYPE                 (P_PIM_BASETYPE)
      )
      mpmc_pm_npi_if_0
        (
          .PI_Clk                  (MPMC_Clk0),
          .PI_AddrReq              (NPI_AddrReq),
          .PI_AddrAck              (NPI_AddrAck),
          .PI_RNW                  (NPI_RNW),
          .PI_Size                 (NPI_Size),
          .PI_WrFIFO_Push          (NPI_WrFIFO_Push),
          .PI_RdFIFO_Pop           (NPI_RdFIFO_Pop),
          .PI_WrFIFO_Flush         (NPI_WrFIFO_Flush),
          .PI_RdFIFO_Flush         (NPI_RdFIFO_Flush),

          // Offset 0x0
          .PMCTRL_Reg_In            (PM_Ctrl_Reg_In),
          .PMCTRL_Reg_Out           (PM_Ctrl_Reg_Out[0*32 +:32]),
          .PMCTRL_Reg_Wr            (PM_Ctrl_Reg_CE[0]),
          // Offset 0x4
          .PMCLR_Reg_In             (PM_Ctrl_Reg_In & {32{PM_Ctrl_Reg_CE[1]}}),
          // Offset 0x8
          .PMSTATUS_Reg_In          (PM_Ctrl_Reg_In),
          .PMSTATUS_Reg_Out         (PM_Ctrl_Reg_Out[2*32 +:32]),
          .PMSTATUS_Reg_Wr          (PM_Ctrl_Reg_CE[2]),
          // Offset 0x10 - 0x14
          .PMGCC_Reg_Out            (PM_Ctrl_Reg_Out[4*32 +:32*2]),
          // Offset 0x20 - 0x5c
          .PMDCC_Reg_Out            (PM_Ctrl_Reg_Out[8*32 +:32*2*8]),
          .PMBRAM_address           (PM_Data_Addr),
          .PMBRAM_data_out          (PM_Data_Out),

          .Host_Clk                 (MPMC_CTRL_Clk),
          .Rst                      (Rst_d2)
        );

        // Tie off unused Registers
        assign PM_Ctrl_Reg_Out[1*32 +: 32] = 0;
        assign PM_Ctrl_Reg_Out[3*32 +: 32] = 0;
        assign PM_Ctrl_Reg_Out[6*32 +: 32*2] = 0;
        // sets the 8 registers 24-32 to 0's
        assign PM_Ctrl_Reg_Out[24*32 +: 32*8] = 0;


    end

  endgenerate


endmodule // mpmc

`default_nettype wire

