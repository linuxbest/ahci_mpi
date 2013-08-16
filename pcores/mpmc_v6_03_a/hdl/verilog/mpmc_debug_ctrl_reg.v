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
// Description:
//   This module is the top level for the PHY Debug Registers.  The debug
//     registers vary based on the type of PHY that is being used.  Some of
//     the registers are common across all PHY's.
//   Format:
//     RegisterName RegisterNumber
//       Bits FieldName CoreAccess DefaultValue : Description
//   All PHY's:
//     CALIB_RST_CTRL 0x00
//       [31]    REG_DEFAULT_ON_RST     R/W 1 : 1 = Upon MPMC Reset, set all
//                                                  calibration control
//                                                  registers back to default
//                                                  values (except this
//                                                  register).
//                                              0 = MPMC reset does not change
//                                                  control registers.
//   S3 DDR1/DDR2 MIG PHY:
//       [7]     VIO_OUT_DQS_EN         R/W 0 : Enable signal for strobe tap
//                                              selection.
//       [11:15] VIO_OUT_DQS            R/W F : Used to change the tap values
//                                              for strobes.
//       [23]    VIO_OUT_RST_DQS_DIV_EN R/W 0 : Enable signal for rst_dqs_div
//                                              tap selection.
//       [27:31] VIO_OUT_RST_DQS_DIV    R/W F : Used to change the tap values
//                                              for rst_dqs_div.
//     CALIB_STATUS 0x08
//       [3:7]   DBG_DELAY_SEL          R     : Tap value from the calibration
//                                              logic used to delay the strobe
//                                              and rst_dqs_div.
//       [11:15] DBG_PHASE_CNT          R     : Phase count gives the number of
//                                              LUTs in the clock phase.
//       [18:23] DBG_CNT                R     : Counter used in the calibration
//                                              logic.
//       [24]    DBG_RST_CALIB          R     : Used to stop new tap_values
//                                              from calibration logic to
//                                              strobe and rst_dqs_div.
//       [25]    DBG_TRANS_ONEDTCT      R     : Asserted when the first
//                                              transition is detected.
//       [26]    DBG_TRANS_TWODTCT      R     : Asserted when the second
//                                              transition is detected.
//       [27]    DBG_ENB_TRANS_TWO_DTCT R     : Enable signal for
//                                              DBG_TRANS_TWODTCT.
//   V4/V5 DDR1/DDR2 MIG PHY:
//       [6]     IDELAYCTRL_RDY_O       R   0 : Status of MPMC_Idelayctrl_Rdy_O
//       [7]     IDELAYCTRL_RDY_I       R   0 : Status of MPMC_Idelayctrl_Rdy_I
//       [13]    FORCE_INITDONE         R/W 0 : 1 = force MPMC INIT_DONE signal
//                                                  to be equal to
//                                                  FORCE_INITDONEVAL.
//                                              0 = Allow hardware calibration
//                                                  engine to drive MPMC
//                                                  INIT_DONE signal.
//       [14]    FORCE_INITDONE_VAL     R/W 0 : Value to set MPMC INIT_DONE to
//                                              when FORCE_INITDONE = 1
//       [15]    MIG_INIT_DONE          R   0 : Set to 1 when
//                                              MIG_HW_CALIBRATION
//                                              initialization is complete;
//                                              otherwise set to 0.  Note: HW c
//                                              alibration may be complete but
//                                              PIM's INIT_DONE may be masked
//                                              by FORCE_INITDONE signal.
//       [31]    HW_CALIB_ON_RESET      R/W 1 : 1 = Start memory hardware
//                                                  calibration engine upon
//                                                  MPMC reset.
//                                              0 = Do not run hardware
//                                                  calibration engine upon
//                                                  MPMC reset.
//     CALIB_STATUS 
//       [1:7]   BIT_ERR_INDEX          R   0 : [V5 only] When a calibration
//                                              error is reported, this field
//                                              indicates which bit DQ is
//                                              failing.
//       [12:15] DONE_STATUS            R   0 : [V5 only] 4 bit calibration
//                                              completion status.
//       [6]     SEL_DONE               R   0 : [V4 only] Indicates calibration
//                                              process of center-aligning DQS
//                                              with respect to clock is
//                                              complete.
//       [7:15]  DONE_STATUS            R   0 : [V4 only] Tap control and
//                                              pattern compare calibration
//                                              completion status, 1 bit plus 1
//                                              bit per dqs bit.
//       [28:31] ERR_STATUS             R   0 : [V5 only] 4 bit calibration
//                                              error status.
//       [23:31] ERR_STATUS             R   0 : [V4 only] Pattern compare error
//                                              completion status, 1 bit per
//                                              dqs bit.
//     ECC_DEBUG  -- Valid if C_INCLUDE_ECC_SUPPORT == 1
//       [0]     ECC_BYTE_ACCESS_EN     R/W 0 : 1 = Enable debug access to the
//                                                  ECC byte lane to read/write
//                                                  the ECC byte data directly.
//                                              0 = ECC byte data is controlled
//                                                   by the normal ECC logic.
//     ECC_READ_DATA -- Valid if C_INCLUDE_ECC_SUPPORT == 1
//       [0:7]   ECC_READ_DATA0         R   0 : Data read from ECC byte lane on
//                                              the first byte of the data in
//                                              the 4 beat memory burst.
//       [8:15]  ECC_READ_DATA1         R   0 : Data read from ECC byte lane on
//                                              the second byte of the data in
//                                              the 4 beat memory burst.
//       [16:23] ECC_READ_DATA2         R   0 : Data read from ECC byte lane on
//                                              the third byte of the data in
//                                              the 4 beat memory burst.
//       [24:31] ECC_READ_DATA3         R   0 : Data read from ECC byte lane on
//                                              the fourth byte of the data in
//                                              the 4 beat memory burst.
//     ECC_WRITE_DATA  -- Valid if C_INCLUDE_ECC_SUPPORT == 1
//       [0:7]   ECC_WRITE_DATA0        R   0 : Data write from ECC byte lane
//                                              on the first byte of the data
//                                              in the 4 beat memory burst.
//       [8:15]  ECC_WRITE_DATA1        R   0 : Data write from ECC byte lane
//                                              on the second byte of the data
//                                              in the 4 beat memory burst.
//       [16:23] ECC_WRITE_DATA2        R   0 : Data write from ECC byte lane
//                                              on the third byte of the data
//                                              in the 4 beat memory burst.
//       [24:31] ECC_WRITE_DATA3        R   0 : Data write from ECC byte lane
//                                              on the fourth byte of the data
//                                              in the 4 beat memory burst.
//     CALIB_DQS_GROUP[n]
//       [0:7]   DQ_IN_BYTE_ALIGN[n]    R/W 0 : [V4 only] Calibration bit
//                                              alignment of 8 bits within the
//                                              byte.
//       [11:15] RDEN_DLY[n]            R/W 0 : Number of cycles after read
//                                              command until read data is
//                                              valid for DQS group.
//       [19:23] GATE_DLY[n]            R/W 0 : [V5 only] Number of cycles
//                                              after read command until clock
//                                              enable for DQ byte group is
//                                              deasserted to prevent postamble
//                                              glitch for DQS group.
//       [29]    CAL_FIRST_LOOP[n]      R/W 0 : [V4 only] Indicates which
//                                              pattern compare stage found a
//                                              solution for DQS group.
//       [30]    DELAY_RD_FALL[n]       R/W   : [V4 only] Indicates relative
//                                              alignment of bytes for DQS
//                                              group.
//       [31]    RD_SEL[n]              R/W 0 : Final read capture MUX set for
//                                              positive or negative edge
//                                              capture for DQS group.
//     CALIB_DQS_TAP_CNT[n] 
//       [7]     DQS_TAP_CNT_INC[n]     W     : DQS[n] IDELAY tap count
//                                              increment, 1 tap increment per
//                                              write.
//       [15]    DQS_TAP_CNT_DEC[n]     W     : DQS[n] IDELAY tap count
//                                              decrement, 1 tap decrement per
//                                              write.
//       [26:31] DQS_TAP_CNT[n]         R   0 : DQS[n] IDELAY tap count.
//     CALIB_GATE_TAP_CNT[n]
//       [7]     GATE_TAP_CNT_INC[n]    W     : GATE[n] IDELAY tap count
//                                              increment, 1 tap increment per
//                                              write.
//       [15]    GATE_TAP_CNT_DEC[n]    W     : GATE[n] IDELAY tap count
//                                              decrement, 1 tap decrement per
//                                              write.
//       [26:31] GATE_TAP_CNT[n]        R   0 : GATE[n] IDELAY tap count.
//     CALIB_DQ_TAP_CNT[n] 
//       [7]     DQ_TAP_CNT_INC[n]      W     : DQ[n] IDELAY tap count
//                                              increment, 1 tap increment per
//                                              write.
//       [15]    DQ_TAP_CNT_DEC[n]      W     : DQ[n] IDELAY tap count
//                                              decrement, 1 tap decrement per
//                                              write.
//       [23]    DQ_DELAY_EN[n]         RW  0 : [V4 only] Alignment of bits
//                                              within a byte lane.
//       [26:31] DQ_TAP_CNT[n]          R   0 : DQ[n] IDELAY tap count.
//   STATIC PHY
//     Not supported
//   SDRAM PHY
//     Not supported
//-----------------------------------------------------------------------------

`timescale 1ns/1ns
`default_nettype none

module mpmc_debug_ctrl_reg #
  (
   parameter         C_FAMILY             = "NONE",
   parameter         C_USE_MIG_S3_PHY     = 0,
   parameter         C_USE_MIG_V4_PHY     = 0,
   parameter         C_USE_MIG_V5_PHY     = 0,
   parameter         C_USE_MIG_V6_PHY     = 0,
   parameter         C_MEM_TYPE           = "NONE",
   parameter         C_INCLUDE_ECC_SUPPORT= 1'b0,
   parameter integer C_DEBUG_CTRL_NUM_REG = 200,
   parameter integer C_NUM_DQ_BITS        = 72,
   parameter integer C_NUM_DQS_BITS       = 9,
   parameter integer C_ENC_DQ_BITS        = 7,
   parameter integer C_ENC_DQS_BITS       = 4
   )
  (
   input  wire                               Clk,
   input  wire                               Clk90,
   input  wire                               Rst,
   output reg                                Rst_Phy,
   output reg                                Rst90_Phy,
   // Global debug Signals
   input  wire                               Idelayctrl_Rdy_I,
   input  wire                               Idelayctrl_Rdy_O,
   input  wire                               InitDone,
   // MIG S3 only debug Signals
   input  wire [4:0]                         dbg_calib_delay_sel,
   input  wire                               dbg_calib_phase_cnt,
   input  wire [4:0]                         dbg_calib_cnt,
   input  wire [5:0]                         dbg_calib_rst_calib,
   input  wire                               dbg_calib_trans_onedtct,
   input  wire                               dbg_calib_trans_twodtct,
   input  wire                               dbg_calib_enb_trans_two_dtct,
   output reg                                vio_out_dqs_en,
   output reg  [4:0]                         vio_out_dqs,
   output reg                                vio_out_rst_dqs_div_en,
   output reg  [4:0]                         vio_out_rst_dqs_div,
   // MIG V4 and V5 debug Signals
   output wire [((C_MEM_TYPE=="DDR2") || (C_USE_MIG_V4_PHY)) ?
    C_NUM_DQS_BITS*5-1 :
    C_NUM_DQS_BITS*2-1:0]        dbg_calib_rden_dly_value,
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_rden_dly_en,
   input  wire [((C_MEM_TYPE=="DDR2") || (C_USE_MIG_V4_PHY)) ?
    C_NUM_DQS_BITS*5-1 :
    C_NUM_DQS_BITS*2-1:0]        dbg_calib_rden_dly,
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_rd_data_sel_value,
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_rd_data_sel_en,
   input  wire [C_NUM_DQS_BITS-1:0]          dbg_calib_rd_data_sel,
   input  wire [C_NUM_DQS_BITS*6-1:0]        dbg_calib_dqs_tap_cnt,
   input  wire [C_NUM_DQ_BITS*6-1:0]         dbg_calib_dq_tap_cnt,
   output reg                                dbg_idel_up_dq,
   output reg                                dbg_idel_down_dq,
   output reg  [C_ENC_DQ_BITS-1:0]           dbg_sel_idel_dq,
   output reg                                dbg_idel_up_dqs,
   output reg                                dbg_idel_down_dqs,
   output reg  [C_ENC_DQS_BITS:0]            dbg_sel_idel_dqs,
   output reg                                dbg_idel_up_gate,
   output reg                                dbg_idel_down_gate,
   output reg  [C_ENC_DQS_BITS:0]            dbg_sel_idel_gate,
   // MIG V4 only debug Signals
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_delay_rd_fall_value,
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_delay_rd_fall_en,
   input  wire [C_NUM_DQS_BITS-1:0]          dbg_calib_delay_rd_fall,
   input  wire [C_NUM_DQS_BITS:0]            dbg_calib_done_v4,
   input  wire [C_NUM_DQS_BITS:0]            dbg_calib_err_v4,
   input  wire                               dbg_calib_sel_done,
   output wire [C_NUM_DQS_BITS*8-1:0]        dbg_calib_dq_in_byte_align_value,
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_dq_in_byte_align_en,
   input  wire [C_NUM_DQS_BITS*8-1:0]        dbg_calib_dq_in_byte_align,
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_cal_first_loop_value,
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_cal_first_loop_en,
   input  wire [C_NUM_DQS_BITS-1:0]          dbg_calib_cal_first_loop,
   output wire [C_NUM_DQ_BITS-1:0]           dbg_calib_dq_delay_en_value,
   output wire [C_NUM_DQ_BITS-1:0]           dbg_calib_dq_delay_en_en,
   input  wire [C_NUM_DQ_BITS-1:0]           dbg_calib_dq_delay_en,
   // MIG V5 only debug Signals
   output wire [(C_MEM_TYPE=="DDR2") ?
    C_NUM_DQS_BITS*5-1 :
    C_NUM_DQS_BITS*2-1:0]        dbg_calib_gate_dly_value,
   output wire [C_NUM_DQS_BITS-1:0]          dbg_calib_gate_dly_en,
   input  wire [(C_MEM_TYPE=="DDR2") ?
    C_NUM_DQS_BITS*5-1 :
    C_NUM_DQS_BITS*2-1:0]        dbg_calib_gate_dly,
   input  wire [3:0]                         dbg_calib_done_v5,
   input  wire [3:0]                         dbg_calib_err_v5,
   input  wire [6:0]                         dbg_calib_bit_err_index,
   input  wire [C_NUM_DQS_BITS*6-1:0]        dbg_calib_gate_tap_cnt,
   // ECC SW Calibration signals
   output reg                                ecc_byte_access_en,
   output reg  [7:0]                         ecc_write_data0,
   output reg  [7:0]                         ecc_write_data1,
   output reg  [7:0]                         ecc_write_data2,
   output reg  [7:0]                         ecc_write_data3,
   input  wire [7:0]                         ecc_read_data0,
   input  wire [7:0]                         ecc_read_data1,
   input  wire [7:0]                         ecc_read_data2,
   input  wire [7:0]                         ecc_read_data3,
   // Signals from/to mpmc_ctrl_if
   input  wire                               Debug_Ctrl_WE,
   input  wire [31:0]                        Debug_Ctrl_Addr,
   input  wire [0:31]                        Debug_Ctrl_In,
   output reg  [0:31]                        Debug_Ctrl_Out
   );

localparam P_GATE_DELAY_WIDTH = (C_MEM_TYPE == "DDR") ? 2 : 5;
localparam P_RDEN_DELAY_WIDTH = (C_USE_MIG_V4_PHY) ? 5 : (C_MEM_TYPE == "DDR") ? 2 : 5;

  reg                        Rst180_Phy;
  reg                        mig_init_done;
  reg                        mig_init_done_d1;
  reg                        Idelayctrl_Rdy_I_d1;
  reg                        Idelayctrl_Rdy_O_d1;
  reg                        myrst;
  wire                       reg_default_on_rst;
  reg                        force_initdone;
  reg                        force_initdone_val;
  wire                       hw_calib_on_reset;
  reg                        wait_for_initdone;
  reg                        capture_phy_settings;

  reg [P_RDEN_DELAY_WIDTH-1:0] rden_dly     [8:0];
  reg [P_GATE_DELAY_WIDTH-1:0] gate_dly     [8:0];
  reg [P_RDEN_DELAY_WIDTH-1:0] rden_dly_90  [8:0];
  reg [P_GATE_DELAY_WIDTH-1:0] gate_dly_90  [8:0];

  reg [8:0]                  delay_rd_fall;
  reg [8:0]                  rd_sel;
  reg                        dqs_tap_cnt_inc_i1;
  reg                        dqs_tap_cnt_inc_i2;
  reg                        dqs_tap_cnt_dec_i1;
  reg                        dqs_tap_cnt_dec_i2;
  reg                        gate_tap_cnt_inc_i1;
  reg                        gate_tap_cnt_inc_i2;
  reg                        gate_tap_cnt_dec_i1;
  reg                        gate_tap_cnt_dec_i2;
  reg                        dq_tap_cnt_inc_i1;
  reg                        dq_tap_cnt_inc_i2;
  reg                        dq_tap_cnt_dec_i1;
  reg                        dq_tap_cnt_dec_i2;
  reg [8:0]                  dqs_tap_cnt_inc;
  reg [8:0]                  dqs_tap_cnt_dec;
  reg [8:0]                  gate_tap_cnt_inc;
  reg [8:0]                  gate_tap_cnt_dec;
  reg [C_ENC_DQ_BITS-1:0]    dq_tap_cnt_active;
  
  reg [71:0]                 dq_tap_cnt_inc;
  reg [71:0]                 dq_tap_cnt_dec;
  reg [71:0]                 dq_delay_en;
  reg [8:0]                  done_status_v4;
  reg [8:0]                  err_status_v4;
  reg                        sel_done;
  reg [3:0]                  done_status_v5;
  reg [3:0]                  err_status_v5;
  reg [6:0]                  bit_err_index;
  reg [9*8-1:0]              dq_in_byte_align;
  reg [9-1:0]                cal_first_loop;
  reg [9*6-1:0]              dqs_tap_cnt;
  reg [9*6-1:0]              gate_tap_cnt;
  reg [72*6-1:0]             dq_tap_cnt;
  reg [4:0]                  dbg_delay_sel;
  reg                        dbg_phase_cnt;
  reg [4:0]                  dbg_cnt;
  reg [5:0]                  dbg_rst_calib;
  reg                        dbg_trans_onedtct;
  reg                        dbg_trans_twodtct;
  reg                        dbg_enb_trans_two_dtct;

  wire           clk_inc;
  wire           rst_inc;
  reg            rst270_inc;

wire  [8:0]                         dbg_calib_done_v4_expand;
wire  [8:0]                         dbg_calib_err_v4_expand;
wire  [71:0]                        dq_delay_en_expand;
wire  [72*6-1:0]                    dbg_calib_dq_tap_cnt_expand;
wire  [8:0]                         dbg_calib_delay_rd_fall_expand;
wire  [8*9-1:0]                     dbg_calib_dq_in_byte_align_expand;
wire  [8:0]                         dbg_calib_cal_first_loop_expand;
wire  [8:0]                         dbg_calib_rd_data_sel_expand;
wire  [9*6-1:0]                     dbg_calib_dqs_tap_cnt_expand;
wire  [(9*P_RDEN_DELAY_WIDTH)-1:0]  dbg_calib_rden_dly_expand;
wire  [(9*P_GATE_DELAY_WIDTH)-1:0]  dbg_calib_gate_dly_expand;
wire  [9*6-1:0]                     dbg_calib_gate_tap_cnt_expand;

wire  [15:0]                        gate_tap_cnt_inc_expand;
wire  [15:0]                        gate_tap_cnt_dec_expand;
wire  [(6*16)-1:0]                  gate_tap_cnt_expand;
wire  [15:0]                        dqs_tap_cnt_inc_expand;
wire  [15:0]                        dqs_tap_cnt_dec_expand;
wire  [(6*16)-1:0]                  dqs_tap_cnt_expand;
wire  [(8*16)-1:0]                  dq_in_byte_align_expand;
wire  [(P_RDEN_DELAY_WIDTH*16)-1:0] rden_dly_expand;
wire  [15:0]                        cal_first_loop_expand;
wire  [15:0]                        delay_rd_fall_expand;
wire  [15:0]                        rd_sel_expand;
wire  [(P_GATE_DELAY_WIDTH*16)-1:0] gate_dly_expand;
wire  [127:0]                       dq_tap_cnt_inc_expand;
wire  [127:0]                       dq_tap_cnt_dec_expand;
wire  [(6*128)-1:0]                 dq_tap_cnt_expand;


////////////////////////////////////////////////////////////////
//Read Channel
reg   [31:2]  ctrl_addr;
reg   [31:2]  ctrl_addr_inc;
reg           ctrl_we;
reg           ctrl_we_inc;
reg   [31:0]  dq_rd_data;

always @(posedge Clk) begin
  if ((C_USE_MIG_V4_PHY) || (C_USE_MIG_V5_PHY)) begin
    dq_rd_data <= {7'b0,dq_tap_cnt_inc_expand[ctrl_addr[8:2]],7'b0,dq_tap_cnt_dec_expand[ctrl_addr[8:2]],10'b0,dq_tap_cnt_expand[ctrl_addr[8:2]*6 +:6]};
  end
end

always @(posedge Clk) begin
  if (myrst) begin
    Debug_Ctrl_Out <= 32'h00000000;
    ctrl_addr <= 30'h00000000;
    ctrl_we <= 1'b0;
  end else begin
    ctrl_addr <= Debug_Ctrl_Addr[31:2];
    ctrl_we <= Debug_Ctrl_WE;
    casex(ctrl_addr[11:2])
      10'h000: Debug_Ctrl_Out <= {31'b0,reg_default_on_rst};
      10'h004: begin
        if (C_INCLUDE_ECC_SUPPORT == 1'b1) begin
          Debug_Ctrl_Out <= {ecc_byte_access_en,31'b0};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      10'h005: begin
        if (C_INCLUDE_ECC_SUPPORT == 1'b1) begin
          Debug_Ctrl_Out <= {ecc_read_data0,ecc_read_data1,ecc_read_data2,ecc_read_data3};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      10'h006: begin
        if (C_INCLUDE_ECC_SUPPORT == 1'b1) begin
          Debug_Ctrl_Out <= {ecc_write_data0,ecc_write_data1,ecc_write_data2,ecc_write_data3};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      ////////////////////////////////////////////////////////////////
      //S3
      10'h010: begin
        if (C_USE_MIG_S3_PHY) begin
          Debug_Ctrl_Out <= {7'b0,vio_out_dqs_en,3'b0,vio_out_dqs,7'b0,vio_out_rst_dqs_div_en,3'b0,vio_out_rst_dqs_div};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      10'h011: begin
        if (C_USE_MIG_S3_PHY) begin
          Debug_Ctrl_Out <= {3'b0,dbg_delay_sel,3'b0,dbg_phase_cnt,2'b0,dbg_cnt,dbg_rst_calib,dbg_trans_onedtct,dbg_trans_twodtct,dbg_enb_trans_two_dtct,4'b0};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
  
      ////////////////////////////////////////////////////////////////
      //V4
      10'h040: begin
        if (C_USE_MIG_V4_PHY) begin
          Debug_Ctrl_Out <= {6'b0,Idelayctrl_Rdy_O_d1,Idelayctrl_Rdy_I_d1,5'b0,force_initdone,force_initdone_val,mig_init_done,15'b0,hw_calib_on_reset};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      10'h041: begin
        if (C_USE_MIG_V4_PHY) begin
          Debug_Ctrl_Out <= {6'b0,sel_done,done_status_v4,7'b0,err_status_v4};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
  
      ////////////////////////////////////////////////////////////////
      //DQS GROUP
      10'b0001010xxx,
      10'b0001011000: begin
        if (C_USE_MIG_V4_PHY) begin
          Debug_Ctrl_Out <= {dq_in_byte_align_expand[ctrl_addr[5:2] *8 +: 8],3'b0,rden_dly_expand[ctrl_addr[5:2] *P_RDEN_DELAY_WIDTH +: P_RDEN_DELAY_WIDTH],13'b0,cal_first_loop_expand[ctrl_addr[5:2]],delay_rd_fall_expand[ctrl_addr[5:2]],rd_sel_expand[ctrl_addr[5:2]]};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      10'b0001100xxx,
      10'b0001101000: begin
        if (C_USE_MIG_V4_PHY) begin
          Debug_Ctrl_Out <= {7'b0,dqs_tap_cnt_inc_expand[ctrl_addr[5:2]],7'b0,dqs_tap_cnt_dec_expand[ctrl_addr[5:2]],10'b0,dqs_tap_cnt_expand[ctrl_addr[5:2] * 6 +:6]};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      
      ////////////////////////////////////////////////////////////////
      //DQ GROUP
      10'b001xxxxxxx: begin
        if (C_USE_MIG_V4_PHY) begin
          Debug_Ctrl_Out <= dq_rd_data;
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
  
      ////////////////////////////////////////////////////////////////
      //V5
      10'h100: begin
        if (C_USE_MIG_V5_PHY) begin
          Debug_Ctrl_Out <= {6'b0,Idelayctrl_Rdy_O_d1,Idelayctrl_Rdy_I_d1,5'b0,force_initdone,force_initdone_val,mig_init_done,15'b0,hw_calib_on_reset};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      10'h101: begin
        if (C_USE_MIG_V5_PHY) begin
          Debug_Ctrl_Out <= {1'b0,bit_err_index,4'b0,done_status_v5,12'b0,err_status_v5};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      ////////////////////////////////////////////////////////////////
      //DQS GROUP
      10'b0100010xxx,
      10'b0100011000: begin
        if (C_USE_MIG_V5_PHY) begin
          if (C_MEM_TYPE == "DDR") begin
            Debug_Ctrl_Out <= {14'b0,rden_dly_expand[ctrl_addr[5:2]*P_RDEN_DELAY_WIDTH+:P_RDEN_DELAY_WIDTH],6'b0,gate_dly_expand[ctrl_addr[5:2]*P_GATE_DELAY_WIDTH+:P_GATE_DELAY_WIDTH],7'b0,1'b0};
          end else begin
            Debug_Ctrl_Out <= {11'b0,rden_dly_expand[ctrl_addr[5:2]*P_RDEN_DELAY_WIDTH+:P_RDEN_DELAY_WIDTH],3'b0,gate_dly_expand[ctrl_addr[5:2]*P_GATE_DELAY_WIDTH+:P_GATE_DELAY_WIDTH],7'b0,rd_sel_expand[ctrl_addr[5:2]]};
          end
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
  
      10'b0100100xxx,
      10'b0100101000: begin
        if (C_USE_MIG_V5_PHY) begin
          Debug_Ctrl_Out <= {7'b0,dqs_tap_cnt_inc_expand[ctrl_addr[5:2]],7'b0,dqs_tap_cnt_dec_expand[ctrl_addr[5:2]],10'b0,dqs_tap_cnt_expand[ctrl_addr[5:2]*6 +:6]};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end      
  
      10'b0100110xxx,
      10'b0100111000: begin
        if (C_USE_MIG_V5_PHY) begin
          Debug_Ctrl_Out <= {7'b0,gate_tap_cnt_inc_expand[ctrl_addr[5:2]],7'b0,gate_tap_cnt_dec_expand[ctrl_addr[5:2]],10'b0,gate_tap_cnt_expand[ctrl_addr[5:2]*6 +:6]};
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
  
      ////////////////////////////////////////////////////////////////
      //DQ GROUP
      10'b011xxxxxxx: begin
        if (C_USE_MIG_V5_PHY) begin
          Debug_Ctrl_Out <= dq_rd_data;
        end else begin
          Debug_Ctrl_Out <= 32'h00000000;
        end
      end
      default: begin
        Debug_Ctrl_Out <= 32'hdeadbeef;
      end
    endcase
  end
end


/////////////////////////////////////////////////////////////////////////////
//S3 Registers
//---------------------------------------------------------------------------
// S3 DDR1/DDR2 MIG PHY:
//   CALIB_REG 0x04
//     [7]     VIO_OUT_DQS_EN         R/W 0 : Enable signal for strobe tap
//                                            selection.
//     [11:15] VIO_OUT_DQS            R/W F : Used to change the tap values
//                                            for strobes.
//     [23]    VIO_OUT_RST_DQS_DIV_EN R/W 0 : Enable signal for rst_dqs_div
//                                            tap selection.
//     [27:31] VIO_OUT_RST_DQS_DIV    R/W F : Used to change the tap values
//                                            for rst_dqs_div.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// S3 DDR1/DDR2 MIG PHY:
//   CALIB_STATUS 0x08
//     [3:7]   DBG_DELAY_SEL          R     : Tap value from the calibration
//                                            logic used to delay the strobe
//                                            and rst_dqs_div.
//     [11:15] DBG_PHASE_CNT          R     : Phase count gives the number of
//                                            LUTs in the clock phase.
//     [18:23] DBG_CNT                R     : Counter used in the calibration
//                                            logic.
//     [24]    DBG_RST_CALIB          R     : Used to stop new tap_values
//                                            from calibration logic to
//                                            strobe and rst_dqs_div.
//     [25]    DBG_TRANS_ONEDTCT      R     : Asserted when the first
//                                            transition is detected.
//     [26]    DBG_TRANS_TWODTCT      R     : Asserted when the second
//                                            transition is detected.
//     [27]    DBG_ENB_TRANS_TWO_DTCT R     : Enable signal for
//                                            DBG_TRANS_TWODTCT.
//---------------------------------------------------------------------------
always @(posedge Clk) begin
  if (myrst) begin
    vio_out_dqs_en <= 1'b0;
    vio_out_dqs <= 5'b01111;
    vio_out_rst_dqs_div_en <= 1'b0;
    vio_out_rst_dqs_div <= 5'b01111;
  end else if (C_USE_MIG_S3_PHY) begin
    if (ctrl_we) begin
      casex(ctrl_addr[11:2])
        10'h010: begin
          vio_out_dqs_en <= Debug_Ctrl_In[7];
          vio_out_dqs <= Debug_Ctrl_In[11:15];
          vio_out_rst_dqs_div_en <= Debug_Ctrl_In[23];
          vio_out_rst_dqs_div <= Debug_Ctrl_In[27:31];
        end
      endcase
    end
  end else begin
    vio_out_dqs_en <= 1'b0;
    vio_out_dqs <= 5'b01111;
    vio_out_rst_dqs_div_en <= 1'b0;
    vio_out_rst_dqs_div <= 5'b01111;
  end

  if (C_USE_MIG_S3_PHY) begin
    dbg_delay_sel <= dbg_calib_delay_sel;
    dbg_phase_cnt <= dbg_calib_phase_cnt;
    dbg_cnt <= dbg_calib_cnt;
    dbg_rst_calib <= dbg_calib_rst_calib;
    dbg_trans_onedtct <= dbg_calib_trans_onedtct;
    dbg_trans_twodtct <= dbg_calib_trans_twodtct;
    dbg_enb_trans_two_dtct <= dbg_calib_enb_trans_two_dtct;
  end else begin
    dbg_delay_sel <= 0;
    dbg_phase_cnt <= 0;
    dbg_cnt <= 0;
    dbg_rst_calib <= 0;
    dbg_trans_onedtct <= 0;
    dbg_trans_twodtct <= 0;
    dbg_enb_trans_two_dtct <= 0;
  end

end


/////////////////////////////////////////////////////////////////////////////
//V4/V5 Registers
//     [6]     IDELAYCTRL_RDY_O       R   0 : Status of MPMC_Idelayctrl_Rdy_O
//     [7]     IDELAYCTRL_RDY_I       R   0 : Status of MPMC_Idelayctrl_Rdy_I
//     [13]    FORCE_INITDONE         R/W 0 : 1 = force MPMC INIT_DONE signal
//                                                to be equal to
//                                                FORCE_INITDONEVAL.
//                                            0 = Allow hardware calibration
//                                                engine to drive MPMC
//                                                INIT_DONE signal.
//     [14]    FORCE_INITDONE_VAL     R/W 0 : Value to set MPMC INIT_DONE to
//                                            when FORCE_INITDONE = 1
//     [15]    MIG_INIT_DONE          R   0 : Set to 1 when
//                                            MIG_HW_CALIBRATION
//                                            initialization is complete;
//                                            otherwise set to 0.  Note: HW c
//                                            alibration may be complete but
//                                            PIM's INIT_DONE may be masked
//                                            by FORCE_INITDONE signal.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_STATUS 0x08
//     [6]     SEL_DONE               R   0 : [V4 only] Indicates calibration
//                                            process of center-aligning DQS
//                                            with respect to clock is
//                                            complete.
//     [7:15]  DONE_STATUS            R   0 : [V4 only] Tap control and
//                                            pattern compare calibration
//                                            completion status, 1 bit plus 1
//                                            bit per dqs bit.
//     [23:31] ERR_STATUS             R   0 : [V4 only] Pattern compare error
//                                            completion status, 1 bit per
//                                            dqs bit.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_DQ_TAP_CNT[n] 0x200 - 0x31C
//     [7]     DQ_TAP_CNT_INC[n]      W     : DQ[n] IDELAY tap count
//                                            increment, 1 tap increment per
//                                            write.
//     [15]    DQ_TAP_CNT_DEC[n]      W     : DQ[n] IDELAY tap count
//                                            decrement, 1 tap decrement per
//                                            write.
//---------------------------------------------------------------------------


genvar i;
genvar cnt_dq;
genvar exp_cnt_dqs;
genvar exp_cnt_dq;

generate
  for (exp_cnt_dq=0;exp_cnt_dq<128;exp_cnt_dq=exp_cnt_dq+1) begin : gen_dq_exp
    if (C_NUM_DQ_BITS > exp_cnt_dq) begin : gen_dqs_exp_active
      assign dq_tap_cnt_inc_expand[exp_cnt_dq] = dq_tap_cnt_inc[exp_cnt_dq];
      assign dq_tap_cnt_dec_expand[exp_cnt_dq] = dq_tap_cnt_dec[exp_cnt_dq];
      assign dq_tap_cnt_expand[exp_cnt_dq*6+:6] = dq_tap_cnt[exp_cnt_dq*6+:6];
    end else begin : gen_dq_exp_inactive
      assign dq_tap_cnt_inc_expand[exp_cnt_dq] = 1'b0;
      assign dq_tap_cnt_dec_expand[exp_cnt_dq] = 1'b0;
      assign dq_tap_cnt_expand[exp_cnt_dq*6+:6] = 6'h00;
    end
  end

  for (exp_cnt_dqs=0;exp_cnt_dqs<16;exp_cnt_dqs=exp_cnt_dqs+1) begin : gen_dqs_exp
    if (C_NUM_DQS_BITS > exp_cnt_dqs) begin : gen_dqs_exp_active
      assign gate_tap_cnt_inc_expand[exp_cnt_dqs] = gate_tap_cnt_inc[exp_cnt_dqs];
      assign gate_tap_cnt_dec_expand[exp_cnt_dqs] = gate_tap_cnt_dec[exp_cnt_dqs];
      assign gate_tap_cnt_expand[exp_cnt_dqs*6+:6] = gate_tap_cnt[exp_cnt_dqs*6+:6];
      assign dqs_tap_cnt_inc_expand[exp_cnt_dqs] = dqs_tap_cnt_inc[exp_cnt_dqs];
      assign dqs_tap_cnt_dec_expand[exp_cnt_dqs] = dqs_tap_cnt_dec[exp_cnt_dqs];
      assign dqs_tap_cnt_expand[exp_cnt_dqs*6+:6] = dqs_tap_cnt[exp_cnt_dqs*6+:6];
      assign gate_dly_expand[exp_cnt_dqs*P_GATE_DELAY_WIDTH+:P_GATE_DELAY_WIDTH] = gate_dly_90[exp_cnt_dqs];
      assign dq_in_byte_align_expand[exp_cnt_dqs*8+:8] = dq_in_byte_align[exp_cnt_dqs*8+:8];
      assign rden_dly_expand[exp_cnt_dqs*P_RDEN_DELAY_WIDTH+:P_RDEN_DELAY_WIDTH] = rden_dly_90[exp_cnt_dqs];
      assign cal_first_loop_expand[exp_cnt_dqs] = cal_first_loop[exp_cnt_dqs];
      assign delay_rd_fall_expand[exp_cnt_dqs] = delay_rd_fall[exp_cnt_dqs];
      assign rd_sel_expand[exp_cnt_dqs] = rd_sel[exp_cnt_dqs];
    end else begin : gen_dqs_exp_inactive
      assign gate_tap_cnt_inc_expand[exp_cnt_dqs] = 1'b0;
      assign gate_tap_cnt_dec_expand[exp_cnt_dqs] = 1'b0;
      assign gate_tap_cnt_expand[exp_cnt_dqs*6+:6] = 6'h00;
      assign dqs_tap_cnt_inc_expand[exp_cnt_dqs] = 1'b0;
      assign dqs_tap_cnt_dec_expand[exp_cnt_dqs] = 1'b0;
      assign dqs_tap_cnt_expand[exp_cnt_dqs*6+:6] = 6'h00;
      assign gate_dly_expand[exp_cnt_dqs*P_GATE_DELAY_WIDTH+:P_GATE_DELAY_WIDTH] = {P_GATE_DELAY_WIDTH{1'b0}};
      assign dq_in_byte_align_expand[exp_cnt_dqs*8+:8] = 8'h00;
      assign rden_dly_expand[exp_cnt_dqs*P_RDEN_DELAY_WIDTH+:P_RDEN_DELAY_WIDTH] = {P_RDEN_DELAY_WIDTH{1'b0}};
      assign cal_first_loop_expand[exp_cnt_dqs] = 1'b0;
      assign delay_rd_fall_expand[exp_cnt_dqs] = 1'b0;
      assign rd_sel_expand[exp_cnt_dqs] = 1'b0;
    end
  end

  for (cnt_dq=0;cnt_dq<72;cnt_dq=cnt_dq+1) begin : gen_dq_bits
    if (C_NUM_DQ_BITS > cnt_dq) begin : NUM_DQ_BITS
      assign dq_delay_en_expand[cnt_dq] = dbg_calib_dq_delay_en[cnt_dq];
      assign dbg_calib_dq_tap_cnt_expand[cnt_dq*6+:6] = dbg_calib_dq_tap_cnt[cnt_dq*6+:6];
    end else begin
      assign dq_delay_en_expand = 1'b0;
      assign dbg_calib_dq_tap_cnt_expand[cnt_dq*6+:6] = 6'h00;
    end
  end
  for (i=0;i<9;i=i+1) begin : gen_dqs_bits
    if (C_NUM_DQS_BITS > i) begin : gen_active
      assign dbg_calib_delay_rd_fall_expand[i] = dbg_calib_delay_rd_fall[i];
      assign dbg_calib_dq_in_byte_align_expand[i*8+:8] = dbg_calib_dq_in_byte_align[i*8+:8];
      assign dbg_calib_cal_first_loop_expand[i] = dbg_calib_cal_first_loop[i];
      assign dbg_calib_rd_data_sel_expand[i] = dbg_calib_rd_data_sel[i];
      assign dbg_calib_dqs_tap_cnt_expand[i*6+:6] = dbg_calib_dqs_tap_cnt[i*6+:6];
      assign dbg_calib_gate_tap_cnt_expand[i*6+:6] = dbg_calib_gate_tap_cnt[i*6+:6];
      assign dbg_calib_rden_dly_expand[i*P_RDEN_DELAY_WIDTH+:P_RDEN_DELAY_WIDTH] = dbg_calib_rden_dly[i*P_RDEN_DELAY_WIDTH+:P_RDEN_DELAY_WIDTH];
      if (C_USE_MIG_V5_PHY) begin
        assign dbg_calib_gate_dly_expand[i*P_GATE_DELAY_WIDTH+:P_GATE_DELAY_WIDTH] = dbg_calib_gate_dly[i*P_GATE_DELAY_WIDTH+:P_GATE_DELAY_WIDTH];
      end else begin
        assign dbg_calib_gate_dly_expand[i*P_GATE_DELAY_WIDTH+:P_GATE_DELAY_WIDTH] = {P_GATE_DELAY_WIDTH{1'b0}};
      end
      assign dbg_calib_done_v4_expand[i] = dbg_calib_done_v4[i];
      assign dbg_calib_err_v4_expand[i] = dbg_calib_err_v4[i];
    end else begin : gen_inactive
      assign dbg_calib_delay_rd_fall_expand[i] = 1'b0;
      assign dbg_calib_dq_in_byte_align_expand[i*8+:8] = 8'h00;
      assign dbg_calib_cal_first_loop_expand[i] = 1'b0;
      assign dbg_calib_rd_data_sel_expand[i] = 1'b0;
      assign dbg_calib_dqs_tap_cnt_expand[i*6+:6] = 6'h00;
      assign dbg_calib_gate_tap_cnt_expand[i*6+:6] = 6'h00;
      assign dbg_calib_rden_dly_expand[i*P_RDEN_DELAY_WIDTH+:P_RDEN_DELAY_WIDTH] = {P_RDEN_DELAY_WIDTH{1'b0}};
      assign dbg_calib_gate_dly_expand[i*P_GATE_DELAY_WIDTH+:P_GATE_DELAY_WIDTH] = {P_GATE_DELAY_WIDTH{1'b0}};
      assign dbg_calib_done_v4_expand[i] = 1'b0;
      assign dbg_calib_err_v4_expand[i] = 1'b0;
    end
  end

endgenerate


//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_DQS_TAP_CNT[n] 0x100 - 0x120
//     [7]     DQS_TAP_CNT_INC[n]     W     : DQS[n] IDELAY tap count
//                                            increment, 1 tap increment per
//                                            write.
//     [15]    DQS_TAP_CNT_DEC[n]     W     : DQS[n] IDELAY tap count
//                                            decrement, 1 tap decrement per
//                                            write.
//     [26:31] DQS_TAP_CNT[n]         R   0 : DQS[n] IDELAY tap count.
//---------------------------------------------------------------------------

always @(posedge Clk) begin
  if (C_USE_MIG_V4_PHY || C_USE_MIG_V5_PHY) begin
    Idelayctrl_Rdy_I_d1 <= Idelayctrl_Rdy_I;
    Idelayctrl_Rdy_O_d1 <= Idelayctrl_Rdy_O;
    mig_init_done <= InitDone;
    dqs_tap_cnt <= dbg_calib_dqs_tap_cnt_expand;
    dq_tap_cnt <= dbg_calib_dq_tap_cnt_expand;
  end else begin
    Idelayctrl_Rdy_I_d1 <= 0;
    Idelayctrl_Rdy_O_d1 <= 0;
    mig_init_done <= 0;
    dqs_tap_cnt <= {9*6{1'b0}};
    dq_tap_cnt <= {{72*6}{1'b0}};
  end

  if (C_USE_MIG_V4_PHY) begin
    dq_in_byte_align <= dbg_calib_dq_in_byte_align_expand;
    cal_first_loop <= dbg_calib_cal_first_loop_expand;
    sel_done       <= dbg_calib_sel_done;
    done_status_v4 <= dbg_calib_done_v4_expand;
    err_status_v4  <= dbg_calib_err_v4_expand;
  end else begin
    dq_in_byte_align <= {9*8{1'b0}};
    cal_first_loop <= {9{1'b0}};
    sel_done       <= 1'b0;
    done_status_v4 <= {9{1'b0}};
    err_status_v4  <= {9{1'b0}};
  end

  if (C_USE_MIG_V5_PHY) begin
    bit_err_index  <= dbg_calib_bit_err_index;
    done_status_v5 <= dbg_calib_done_v5;
    err_status_v5  <= dbg_calib_err_v5;
    gate_tap_cnt <= dbg_calib_gate_tap_cnt_expand;
  end else begin
    bit_err_index  <= 0;
    done_status_v5 <= 0;
    err_status_v5  <= 0;
    gate_tap_cnt <= {(9*6){1'b0}};
  end


  if (myrst) begin
    force_initdone <= 1'b0;
    force_initdone_val <= 1'b0;
    dq_tap_cnt_inc[71:0] <= 72'h000000000000000000;
    dq_tap_cnt_dec[71:0] <= 72'h000000000000000000;
    dq_tap_cnt_active <= {C_ENC_DQ_BITS{1'b0}};
    dqs_tap_cnt_inc <= 9'h000;
    dqs_tap_cnt_dec <= 9'h000;
    dq_delay_en <= 72'h000000000000000000;
    delay_rd_fall <= 9'h000;
    rd_sel <= 9'h000;
    gate_tap_cnt_inc <= 9'h00;
    gate_tap_cnt_dec <= 9'h00;
  end else begin
    if (C_USE_MIG_V4_PHY) begin
      dq_delay_en <= dq_delay_en_expand;
      if (capture_phy_settings) begin
        delay_rd_fall <= dbg_calib_delay_rd_fall_expand;
      end else if (ctrl_we) begin
        casex(ctrl_addr[11:2])
          10'b0001010xxx,
          10'b0001011000: begin
            delay_rd_fall[ctrl_addr[5:2]] <= Debug_Ctrl_In[30];
          end
        endcase
      end
    end else begin
      dq_delay_en <= 72'h000000000000000000;
      delay_rd_fall <= 9'h000;
    end
    if (C_USE_MIG_V5_PHY) begin
      if (ctrl_we) begin
        casex(ctrl_addr[11:2])
          10'b0100110xxx,
          10'b0100111000: begin
            gate_tap_cnt_inc[ctrl_addr[5:2]] <= Debug_Ctrl_In[7];
            gate_tap_cnt_dec[ctrl_addr[5:2]] <= Debug_Ctrl_In[15];
          end
        endcase
      end else begin
        gate_tap_cnt_inc <= 9'h00;
        gate_tap_cnt_dec <= 9'h00;      
      end
    end else begin
      gate_tap_cnt_inc <= 9'h00;
      gate_tap_cnt_dec <= 9'h00;
    end
    if (C_USE_MIG_V4_PHY || (C_USE_MIG_V5_PHY && (C_MEM_TYPE == "DDR2"))) begin
      if (capture_phy_settings) begin
        rd_sel <= dbg_calib_rd_data_sel_expand;
      end else if (ctrl_we) begin
        casex(ctrl_addr[11:2])
          10'b0001010xxx,
          10'b0001011000,
          10'b0100010xxx,
          10'b0100011000: begin
            rd_sel[ctrl_addr[5:2]] <= Debug_Ctrl_In[31];
          end
        endcase
      end
    end else begin
      rd_sel <= 9'h000;
    end

    if (ctrl_we) begin
      casex(ctrl_addr[11:2])
        10'h040: begin
          if (C_USE_MIG_V4_PHY) begin
            force_initdone <= Debug_Ctrl_In[13];
            force_initdone_val <= Debug_Ctrl_In[14];
          end
        end
        10'h100: begin
          if (C_USE_MIG_V5_PHY) begin
            force_initdone <= Debug_Ctrl_In[13];
            force_initdone_val <= Debug_Ctrl_In[14];
          end
        end
        10'b0001100xxx,
        10'b0001101000: begin
          if (C_USE_MIG_V4_PHY) begin
            dqs_tap_cnt_inc[ctrl_addr[5:2]] <= Debug_Ctrl_In[7];
            dqs_tap_cnt_dec[ctrl_addr[5:2]] <= Debug_Ctrl_In[15];
          end
        end
        10'b0010xxxxxx: begin
          if (C_USE_MIG_V4_PHY) begin
            dq_tap_cnt_inc[ctrl_addr[8:2]] <= Debug_Ctrl_In[7];
            dq_tap_cnt_dec[ctrl_addr[8:2]] <= Debug_Ctrl_In[15];
            if (Debug_Ctrl_In[15] | Debug_Ctrl_In[7]) begin
              dq_tap_cnt_active <= ctrl_addr[C_ENC_DQ_BITS+1:2];
            end
          end 
        end
        10'b0011000xxx: begin
          if (C_USE_MIG_V4_PHY) begin
            dq_tap_cnt_inc[ctrl_addr[8:2]] <= Debug_Ctrl_In[7];
            dq_tap_cnt_dec[ctrl_addr[8:2]] <= Debug_Ctrl_In[15];
            if (Debug_Ctrl_In[15] | Debug_Ctrl_In[7]) begin
              dq_tap_cnt_active <= ctrl_addr[C_ENC_DQ_BITS+1:2];
            end
          end 
        end
        10'b0100100xxx,
        10'b0100101000: begin
          if (C_USE_MIG_V5_PHY) begin
            dqs_tap_cnt_inc[ctrl_addr[5:2]] <= Debug_Ctrl_In[7];
            dqs_tap_cnt_dec[ctrl_addr[5:2]] <= Debug_Ctrl_In[15];
          end
        end
  
        10'b0110xxxxxx: begin
          if (C_USE_MIG_V5_PHY) begin
            dq_tap_cnt_inc[ctrl_addr[8:2]] <= Debug_Ctrl_In[7];
            dq_tap_cnt_dec[ctrl_addr[8:2]] <= Debug_Ctrl_In[15];
            if (Debug_Ctrl_In[15] | Debug_Ctrl_In[7]) begin
              dq_tap_cnt_active <= ctrl_addr[C_ENC_DQ_BITS+1:2];
            end
          end
        end
        10'b0111000xxx: begin
          if (C_USE_MIG_V5_PHY) begin
            dq_tap_cnt_inc[ctrl_addr[8:2]] <= Debug_Ctrl_In[7];
            dq_tap_cnt_dec[ctrl_addr[8:2]] <= Debug_Ctrl_In[15];
            if (Debug_Ctrl_In[15] | Debug_Ctrl_In[7]) begin
              dq_tap_cnt_active <= ctrl_addr[C_ENC_DQ_BITS+1:2];
            end
          end
        end
      endcase
    end else begin
      dqs_tap_cnt_inc <= 9'h000;
      dqs_tap_cnt_dec <= 9'h000;
      dq_tap_cnt_inc <= 72'h000000000000000000;
      dq_tap_cnt_dec <= 72'h000000000000000000;
    end
  end
end

reg [8:0] dbg_calib_rden_dly_en_i;
reg [8:0] dbg_calib_rden_dly_en_i2;
reg [8:0] dbg_calib_gate_dly_en_i;
reg [8:0] dbg_calib_gate_dly_en_i2;
reg [8:0] dbg_calib_rd_data_sel_en_i;
reg [8:0] dbg_calib_rd_data_sel_en_i2;

always @(posedge Clk) begin
  if (C_USE_MIG_V4_PHY || (C_USE_MIG_V5_PHY && (C_MEM_TYPE == "DDR2"))) begin
    if (ctrl_we) begin
      casex(ctrl_addr[11:2])
        10'b0001010xxx,
        10'b0001011000,
        10'b0100010xxx,
        10'b0100011000: begin
          dbg_calib_rd_data_sel_en_i <= 9'h001 << ctrl_addr[5:2];
        end
      endcase
    end else begin
      dbg_calib_rd_data_sel_en_i <= {C_NUM_DQS_BITS{1'b0}};
    end
    dbg_calib_rd_data_sel_en_i2 <= dbg_calib_rd_data_sel_en_i;
  end else begin
    dbg_calib_rd_data_sel_en_i <= {C_NUM_DQS_BITS{1'b0}};
    dbg_calib_rd_data_sel_en_i2 <= {C_NUM_DQS_BITS{1'b0}};
  end
end

integer cnt;

always @(posedge clk_inc) begin
  ctrl_addr_inc <= Debug_Ctrl_Addr[31:2];
  ctrl_we_inc <= Debug_Ctrl_WE;
  if (C_USE_MIG_V4_PHY || C_USE_MIG_V5_PHY) begin
    if (ctrl_we_inc) begin
      casex(ctrl_addr_inc[11:2])
        10'b0001010xxx,
        10'b0001011000,
        10'b0100010xxx,
        10'b0100011000: begin
          dbg_calib_rden_dly_en_i <= 9'h001 << ctrl_addr_inc[5:2];
        end
        10'b0100110xxx,
        10'b0100111000: begin
          if (C_USE_MIG_V5_PHY) begin
            dbg_calib_gate_dly_en_i <= 9'h001 << ctrl_addr_inc[5:2];
          end
        end
      endcase
    end else begin
      dbg_calib_rden_dly_en_i <= {C_NUM_DQS_BITS{1'b0}};
      dbg_calib_gate_dly_en_i <= {C_NUM_DQS_BITS{1'b0}};
    end
    dbg_calib_rden_dly_en_i2 <= dbg_calib_rden_dly_en_i;
    dbg_calib_gate_dly_en_i2 <= dbg_calib_gate_dly_en_i;
  end else begin
    dbg_calib_rden_dly_en_i <= {C_NUM_DQS_BITS{1'b0}};
    dbg_calib_rden_dly_en_i2 <= {C_NUM_DQS_BITS{1'b0}};
    dbg_calib_gate_dly_en_i <= {C_NUM_DQS_BITS{1'b0}};
    dbg_calib_gate_dly_en_i2 <= {C_NUM_DQS_BITS{1'b0}};
  end

  if (rst_inc) begin
    for (cnt = 0; cnt < 9;cnt=cnt+1) begin
      rden_dly[cnt] <= {P_RDEN_DELAY_WIDTH{1'b0}};
      gate_dly[cnt] <= {P_GATE_DELAY_WIDTH{1'b0}};
    end
  end else if (C_USE_MIG_V4_PHY || C_USE_MIG_V5_PHY) begin    
    if (capture_phy_settings) begin
      for (cnt = 0; cnt < 9;cnt=cnt+1) begin
        rden_dly[cnt] <= dbg_calib_rden_dly_expand[cnt*P_RDEN_DELAY_WIDTH +: P_RDEN_DELAY_WIDTH];
        gate_dly[cnt] <= dbg_calib_gate_dly_expand[cnt*P_GATE_DELAY_WIDTH +: P_GATE_DELAY_WIDTH];
      end
    end else if (ctrl_we_inc) begin
      casex(ctrl_addr_inc[11:2])
        10'b0001010xxx,
        10'b0001011000,
        10'b0100010xxx,
        10'b0100011000: begin
          rden_dly[ctrl_addr_inc[5:2]] <= Debug_Ctrl_In[16-P_RDEN_DELAY_WIDTH:15];
          if (C_USE_MIG_V5_PHY) begin
            gate_dly[ctrl_addr_inc[5:2]] <= Debug_Ctrl_In[24-P_GATE_DELAY_WIDTH:23];
          end
        end
      endcase
    end
  end
end



//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_REG 0x04
//     [31]    HW_CALIB_ON_RESET      R/W 1 : 1 = Start memory hardware
//                                                calibration engine upon
//                                                MPMC reset.
//                                            0 = Do not run hardware
//                                                calibration engine upon
//                                                MPMC reset.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_DQ_TAP_CNT[n] 0x200 - 0x31C
//     [26:31] DQ_TAP_CNT[n]          R   0 : DQ[n] IDELAY tap count.
//---------------------------------------------------------------------------
generate
  if (C_USE_MIG_V4_PHY || C_USE_MIG_V5_PHY) begin : gen_hw_calib_on_reset
    FDRSE #
      (
       .INIT (1'b1)
       )
      u_hw_calib_on_reset
        (
         .C  (Clk),
         .CE (ctrl_we && ((ctrl_addr[11:2] == 10'h040) || (ctrl_addr[11:2] == 10'h100))),
         .R  (1'b0),
         .S  (1'b0),
         .D  (Debug_Ctrl_In[31]),
         .Q  (hw_calib_on_reset)
         );

  end else begin : NO_V4_V5
    assign hw_calib_on_reset = 1'b0;
  end
endgenerate


  //---------------------------------------------------------------------------
  // All PHY's:
  //   CALIB_RST_CTRL 0x00
  //     [31]    REG_DEFAULT_ON_RST     R/W 1 : 1 = Upon MPMC Reset, set all
  //                                                calibration control
  //                                                registers back to default
  //                                                values (except this
  //                                                register).
  //                                            0 = MPMC reset does not change
  //                                                control registers.
  //---------------------------------------------------------------------------
  FDRSE #
    (
     .INIT (1'b1)
     )
    u_reg_default_on_rst
      (
       .C  (Clk),
       .CE (ctrl_we && (ctrl_addr[11:2] == 10'h000)),
       .R  (1'b0),
       .S  (1'b0),
       .D  (Debug_Ctrl_In[31]),
       .Q  (reg_default_on_rst)
       );
  always @(posedge Clk) begin
    myrst <= Rst & reg_default_on_rst;
  end

  //---------------------------------------------------------------------------
  // V4/V5 DDR1/DDR2 MIG PHY:
  //   Assign output registers.
  //---------------------------------------------------------------------------

  generate
    if (C_USE_MIG_V4_PHY || C_USE_MIG_V5_PHY) begin : gen_output_reg_vx
      if (C_USE_MIG_V5_PHY && (C_MEM_TYPE == "DDR2")) begin : gen_v5ddr2
        always @(posedge Clk) begin
          dqs_tap_cnt_inc_i1  <= |dqs_tap_cnt_inc;
          dqs_tap_cnt_inc_i2  <= dqs_tap_cnt_inc_i1;
          dqs_tap_cnt_dec_i1  <= |dqs_tap_cnt_dec;
          dqs_tap_cnt_dec_i2  <= dqs_tap_cnt_dec_i1;
          gate_tap_cnt_inc_i1 <= |gate_tap_cnt_inc;
          gate_tap_cnt_inc_i2 <= gate_tap_cnt_inc_i1;
          gate_tap_cnt_dec_i1 <= |gate_tap_cnt_dec;
          gate_tap_cnt_dec_i2 <= gate_tap_cnt_dec_i1;
          dq_tap_cnt_inc_i1   <= |dq_tap_cnt_inc;
          dq_tap_cnt_inc_i2   <= dq_tap_cnt_inc_i1;
          dq_tap_cnt_dec_i1   <= |dq_tap_cnt_dec;
          dq_tap_cnt_dec_i2   <= dq_tap_cnt_dec_i1;
          dbg_idel_up_dqs     <= dqs_tap_cnt_inc_i1  | dqs_tap_cnt_inc_i2;
          dbg_idel_down_dqs   <= dqs_tap_cnt_dec_i1  | dqs_tap_cnt_dec_i2;
          dbg_idel_up_gate    <= gate_tap_cnt_inc_i1 | gate_tap_cnt_inc_i2;
          dbg_idel_down_gate  <= gate_tap_cnt_dec_i1 | gate_tap_cnt_dec_i2;
          dbg_idel_up_dq      <= dq_tap_cnt_inc_i1   | dq_tap_cnt_inc_i2;
          dbg_idel_down_dq    <= dq_tap_cnt_dec_i1   | dq_tap_cnt_dec_i2;
        end
      end else if (C_USE_MIG_V5_PHY && (C_MEM_TYPE == "DDR")) begin : gen_v5ddr1
        always @(posedge clk_inc) begin
          dbg_idel_up_dqs    <= |dqs_tap_cnt_inc;
          dbg_idel_down_dqs  <= |dqs_tap_cnt_dec;
          dbg_idel_up_gate   <= |gate_tap_cnt_inc;
          dbg_idel_down_gate <= |gate_tap_cnt_dec;
          dbg_idel_up_dq     <= |dq_tap_cnt_inc;
          dbg_idel_down_dq   <= |dq_tap_cnt_dec;
        end
      end else begin : gen_other
        always @(posedge Clk) begin
          dbg_idel_up_dqs    <= |dqs_tap_cnt_inc;
          dbg_idel_down_dqs  <= |dqs_tap_cnt_dec;
          dbg_idel_up_gate   <= |gate_tap_cnt_inc;
          dbg_idel_down_gate <= |gate_tap_cnt_dec;
          dbg_idel_up_dq     <= |dq_tap_cnt_inc;
          dbg_idel_down_dq   <= |dq_tap_cnt_dec;
        end
      end
      if (C_USE_MIG_V5_PHY && (C_MEM_TYPE == "DDR")) begin : gen_v5_ddr1_clk
        assign clk_inc = ~Clk90;
        assign rst_inc = rst270_inc;
        always @(negedge Clk90) begin
          rst270_inc <= myrst;
        end
      end else begin : gen_other_clk
        assign clk_inc = Clk;
        assign rst_inc = myrst;
      end
      always @(posedge clk_inc) begin
        if (rst_inc) begin
          dbg_sel_idel_dqs  <= 0;
          dbg_sel_idel_gate <= 0;
          dbg_sel_idel_dq   <= 0;
        end else begin
          case (1'b1)
            dqs_tap_cnt_inc[0] | dqs_tap_cnt_dec[0]:  dbg_sel_idel_dqs <= 0;
            dqs_tap_cnt_inc[1] | dqs_tap_cnt_dec[1]:  dbg_sel_idel_dqs <= 1;
            dqs_tap_cnt_inc[2] | dqs_tap_cnt_dec[2]:  dbg_sel_idel_dqs <= 2;
            dqs_tap_cnt_inc[3] | dqs_tap_cnt_dec[3]:  dbg_sel_idel_dqs <= 3;
            dqs_tap_cnt_inc[4] | dqs_tap_cnt_dec[4]:  dbg_sel_idel_dqs <= 4;
            dqs_tap_cnt_inc[5] | dqs_tap_cnt_dec[5]:  dbg_sel_idel_dqs <= 5;
            dqs_tap_cnt_inc[6] | dqs_tap_cnt_dec[6]:  dbg_sel_idel_dqs <= 6;
            dqs_tap_cnt_inc[7] | dqs_tap_cnt_dec[7]:  dbg_sel_idel_dqs <= 7;
            dqs_tap_cnt_inc[8] | dqs_tap_cnt_dec[8]:  dbg_sel_idel_dqs <= 8;
            default: dbg_sel_idel_dqs <= dbg_sel_idel_dqs;
          endcase
          case (1'b1)
            gate_tap_cnt_inc[0] | gate_tap_cnt_dec[0]: dbg_sel_idel_gate <= 0;
            gate_tap_cnt_inc[1] | gate_tap_cnt_dec[1]: dbg_sel_idel_gate <= 1;
            gate_tap_cnt_inc[2] | gate_tap_cnt_dec[2]: dbg_sel_idel_gate <= 2;
            gate_tap_cnt_inc[3] | gate_tap_cnt_dec[3]: dbg_sel_idel_gate <= 3;
            gate_tap_cnt_inc[4] | gate_tap_cnt_dec[4]: dbg_sel_idel_gate <= 4;
            gate_tap_cnt_inc[5] | gate_tap_cnt_dec[5]: dbg_sel_idel_gate <= 5;
            gate_tap_cnt_inc[6] | gate_tap_cnt_dec[6]: dbg_sel_idel_gate <= 6;
            gate_tap_cnt_inc[7] | gate_tap_cnt_dec[7]: dbg_sel_idel_gate <= 7;
            gate_tap_cnt_inc[8] | gate_tap_cnt_dec[8]: dbg_sel_idel_gate <= 8;
            default: dbg_sel_idel_gate <= dbg_sel_idel_gate;
          endcase
          dbg_sel_idel_dq <= dq_tap_cnt_active;
        end
      end
    end
  endgenerate

  //---------------------------------------------------------------------------
  // V4/V5 DDR1/DDR2 MIG PHY:
  //   Figure out if HW reset is in progress and provide signal to debug
  //   registers to capture final HW reset values.
  //---------------------------------------------------------------------------
  generate
    if (C_USE_MIG_V4_PHY || C_USE_MIG_V5_PHY) begin : gen_capture_phy_settings
      always @(negedge Clk) begin
        Rst180_Phy <= Rst_Phy;
      end
      always @(posedge Clk90) begin
        Rst90_Phy <= Rst180_Phy;
      end
      always @(posedge Clk) begin
        Rst_Phy <= Rst & hw_calib_on_reset;
        mig_init_done_d1 <= mig_init_done;
        if (Rst & hw_calib_on_reset)
          wait_for_initdone <= 1'b1;
        else if (mig_init_done & ~mig_init_done_d1)
          wait_for_initdone <= 1'b0;
        capture_phy_settings <= mig_init_done & ~mig_init_done_d1 & wait_for_initdone;
      end
    end else begin : gen_capture_phy_settings_s3
      always @(posedge Clk) begin
        Rst_Phy <= Rst;
      end
      always @(negedge Clk) begin
        Rst180_Phy <= Rst_Phy;
      end
      always @(posedge Clk90) begin
        Rst90_Phy <= Rst180_Phy;
      end
    end
  endgenerate

//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_STATUS 0x08
//     [1:7]   BIT_ERR_INDEX          R   0 : [V5 only] When a calibration
//                                            error is reported, this field
//                                            indicates which bit DQ is
//                                            failing.
//     [12:15] DONE_STATUS            R   0 : [V5 only] 4 bit calibration
//                                            completion status.
//     [28:31] ERR_STATUS             R   0 : [V5 only] 4 bit calibration
//                                            error status.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_DQS_GROUP[n] 0x40 - 0x60
//     [19:23] GATE_DLY[n]            R/W 0 : [V5 only] Number of cycles
//                                            after read command until clock
//                                            enable for DQ byte group is
//                                            deasserted to prevent postamble
//                                            glitch for DQS group.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_GATE_TAP_CNT[n] 0x180 - 0x1A0
//     [7]     GATE_TAP_CNT_INC[n]    W     : GATE[n] IDELAY tap count
//                                            increment, 1 tap increment per
//                                            write.
//     [15]    GATE_TAP_CNT_DEC[n]    W     : GATE[n] IDELAY tap count
//                                            decrement, 1 tap decrement per
//                                            write.
//     [26:31] GATE_TAP_CNT[n]        R   0 : GATE[n] IDELAY tap count.
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//   ECC_DEBUG 0x10 -- Valid if C_INCLUDE_ECC_SUPPORT == 1
//     [0]     ECC_BYTE_ACCESS_EN     R/W 0 : 1 = Enable debug access to the
//                                                ECC byte lane to read/write
//                                                the ECC byte data directly.
//                                            0 = ECC byte data is controlled
//                                                 by the normal ECC logic.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//   ECC_READ_DATA 0x14 -- Valid if C_INCLUDE_ECC_SUPPORT == 1
//     [0:7]   ECC_READ_DATA0         R   0 : Data read from ECC byte lane on
//                                            the first byte of the data in
//                                            the 4 beat memory burst.
//     [8:15]  ECC_READ_DATA1         R   0 : Data read from ECC byte lane on
//                                            the second byte of the data in
//                                            the 4 beat memory burst.
//     [16:23] ECC_READ_DATA2         R   0 : Data read from ECC byte lane on
//                                            the third byte of the data in
//                                            the 4 beat memory burst.
//     [24:31] ECC_READ_DATA3         R   0 : Data read from ECC byte lane on
//                                            the fourth byte of the data in
//                                            the 4 beat memory burst.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//   ECC_WRITE_DATA 0x18 -- Valid if C_INCLUDE_ECC_SUPPORT == 1
//     [0:7]   ECC_WRITE_DATA0        R   0 : Data write from ECC byte lane
//                                            on the first byte of the data
//                                            in the 4 beat memory burst.
//     [8:15]  ECC_WRITE_DATA1        R   0 : Data write from ECC byte lane
//                                            on the second byte of the data
//                                            in the 4 beat memory burst.
//     [16:23] ECC_WRITE_DATA2        R   0 : Data write from ECC byte lane
//                                            on the third byte of the data
//                                            in the 4 beat memory burst.
//     [24:31] ECC_WRITE_DATA3        R   0 : Data write from ECC byte lane
//                                            on the fourth byte of the data
//                                            in the 4 beat memory burst.
//---------------------------------------------------------------------------
always @(posedge Clk) begin
  if (myrst) begin
    ecc_byte_access_en <= 1'b0;
    ecc_write_data0 <= 8'h0;
    ecc_write_data1 <= 8'h0;
    ecc_write_data2 <= 8'h0;
    ecc_write_data3 <= 8'h0;
  end else if (C_INCLUDE_ECC_SUPPORT == 1'b1) begin
    if (ctrl_we) begin
      casex(ctrl_addr[11:2])
        10'h004: begin
          ecc_byte_access_en <= Debug_Ctrl_In[0];
        end
        10'h006: begin
          ecc_write_data0 <= Debug_Ctrl_In[0:7];
          ecc_write_data1 <= Debug_Ctrl_In[8:15];
          ecc_write_data2 <= Debug_Ctrl_In[16:23];
          ecc_write_data3 <= Debug_Ctrl_In[24:31];
        end
      endcase
    end
  end else begin
    ecc_byte_access_en <= 1'b0;
    ecc_write_data0 <= 8'h0;
    ecc_write_data1 <= 8'h0;
    ecc_write_data2 <= 8'h0;
    ecc_write_data3 <= 8'h0;
  end
end



//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_DQS_GROUP[n] 0x40 - 0x60
//     [0:7]   DQ_IN_BYTE_ALIGN[n]    R/W 0 : [V4 only] Calibration bit
//                                            alignment of 8 bits within the
//                                            byte.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_DQS_GROUP[n] 0x40 - 0x60
//     [29]    CAL_FIRST_LOOP[n]      R     : [V4 only] Indicates which
//                                            pattern compare stage found a
//                                            solution for DQS group.
//     [30]    DELAY_RD_FALL[n]       R/W   : [V4 only] Indicates relative
//                                            alignment of bytes for DQS
//                                            group.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// V4 DDR1/DDR2 MIG PHY:
//   CALIB_DQ_TAP_CNT[n] 0x200 - 0x31C
//     [23]    DQ_DELAY_EN[n]         RW  0 : [V4 only] Alignment of bits
//                                            within a byte lane.
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_DQS_GROUP[n] 0x40 - 0x60
//     [11:15] RDEN_DLY[n]            R/W 0 : Number of cycles after read
//                                            command until read data is
//                                            valid for DQS group.
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
// V4/V5 DDR1/DDR2 MIG PHY:
//   CALIB_DQS_GROUP[n] 0x40 - 0x60
//     [31]    RD_SEL[n]              R/W 0 : Final read capture MUX set for
//                                            positive or negative edge
//                                            capture for DQS group.
//---------------------------------------------------------------------------
generate
    for (i=0;i<9;i=i+1) begin : gen_index
      if (C_NUM_DQS_BITS > i) begin : gen_active
        if ((C_USE_MIG_V5_PHY) && (C_MEM_TYPE == "DDR")) begin : gen_inc_dly
          always @(posedge Clk90) begin
            rden_dly_90[i] <= rden_dly[i];
            gate_dly_90[i] <= gate_dly[i];
          end
        end else begin : no_inc_dly
          always @(rden_dly[i] or gate_dly[i]) begin
            rden_dly_90[i] = rden_dly[i];
            gate_dly_90[i] = gate_dly[i];
          end
        end
        
        if (C_USE_MIG_V5_PHY) begin : gen_calib_status_virtex5
          assign dbg_calib_gate_dly_en[i] = dbg_calib_gate_dly_en_i[i] | dbg_calib_gate_dly_en_i2[i];
          assign dbg_calib_gate_dly_value[(i+1)*P_GATE_DELAY_WIDTH-1:i*P_GATE_DELAY_WIDTH] = gate_dly[i];
        end else begin : no_gen_calib_status_virtex5
          assign dbg_calib_gate_dly_en[i] = 1'b0;
          assign dbg_calib_gate_dly_value[(i+1)*P_GATE_DELAY_WIDTH-1:i*P_GATE_DELAY_WIDTH] = {P_GATE_DELAY_WIDTH{1'b0}};
        end
        if (C_USE_MIG_V4_PHY) begin : V4_ACTIVE
          assign dbg_calib_delay_rd_fall_value[i] = delay_rd_fall[i];              
          assign dbg_calib_delay_rd_fall_en[i] = dbg_calib_rd_data_sel_en_i[i] | dbg_calib_rd_data_sel_en_i2[i];
          assign dbg_calib_dq_in_byte_align_value[(i+1)*8-1:i*8] = Debug_Ctrl_In[0:7];
          assign dbg_calib_dq_in_byte_align_en[i] = ((ctrl_addr[11:6] == 6'b000101) && (ctrl_addr[5:2] == i) && ctrl_we) ? 1'b1 : 1'b0;
          assign dbg_calib_cal_first_loop_value[i] = Debug_Ctrl_In[29];
          assign dbg_calib_cal_first_loop_en[i] = ((ctrl_addr[11:6] == 6'b000101) && (ctrl_addr[5:2] == i) && ctrl_we) ? 1'b1 : 1'b0;
        end else begin : NO_V4_ACTIVE
          assign dbg_calib_delay_rd_fall_value[i] = 1'b0;
          assign dbg_calib_dq_in_byte_align_en[i] = 1'b0;
          assign dbg_calib_dq_in_byte_align_value[(i+1)*8-1:i*8] = 8'h00;
          assign dbg_calib_dq_in_byte_align_en[i] =  1'b0;
          assign dbg_calib_cal_first_loop_value[i] = 1'b0;
          assign dbg_calib_cal_first_loop_en[i] = 1'b0;
        end
        if (C_USE_MIG_V4_PHY || C_USE_MIG_V5_PHY) begin : gen_rden_dly
          assign dbg_calib_rden_dly_en[i] = dbg_calib_rden_dly_en_i[i] | dbg_calib_rden_dly_en_i2[i];
          assign dbg_calib_rden_dly_value[(i+1)*P_RDEN_DELAY_WIDTH-1:i*P_RDEN_DELAY_WIDTH] = rden_dly[i];
        end else begin : no_gen_rden_dly
          assign dbg_calib_rden_dly_en[i] = 1'b0;
          assign dbg_calib_rden_dly_value[(i+1)*P_RDEN_DELAY_WIDTH-1:i*P_RDEN_DELAY_WIDTH] = {P_RDEN_DELAY_WIDTH{1'b0}};
        end
        if (C_USE_MIG_V4_PHY || (C_USE_MIG_V5_PHY && (C_MEM_TYPE == "DDR2"))) begin : gen_rd_sel
          assign dbg_calib_rd_data_sel_en[i] = dbg_calib_rd_data_sel_en_i[i] | dbg_calib_rd_data_sel_en_i2[i];
          assign dbg_calib_rd_data_sel_value[i] = rd_sel[i];
        end else begin : no_gen_rd_sel
          assign dbg_calib_rd_data_sel_en[i] = 0;
          assign dbg_calib_rd_data_sel_value[i] = 0;
        end
        
      end
    end

  if (C_USE_MIG_V4_PHY) begin : V4_ACTIVE

    for (cnt_dq=0;cnt_dq<72;cnt_dq=cnt_dq+1) begin : gen_dq_index
      if (C_NUM_DQ_BITS > cnt_dq) begin : gen_active
        assign dbg_calib_dq_delay_en_value[cnt_dq] = Debug_Ctrl_In[23];
        assign dbg_calib_dq_delay_en_en[cnt_dq]    = ((ctrl_addr[11:9] == 3'b001) && (ctrl_addr[8:2] == cnt_dq) && ctrl_we) ? 1'b1 : 1'b0;
      end
    end
  end
endgenerate

endmodule


