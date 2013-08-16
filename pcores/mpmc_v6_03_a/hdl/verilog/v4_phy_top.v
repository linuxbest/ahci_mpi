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

`timescale 1ns/1ps

module v4_phy_top #
  (
   parameter integer TBY4TAPVALUE      = 17,
   parameter integer WDF_RDEN_EARLY = 0,
   parameter integer WDF_RDEN_WIDTH = 1,
   parameter integer BANK_WIDTH     = 2,
   parameter integer CLK_WIDTH      = 1,
   parameter integer CKE_WIDTH      = 1,
   parameter integer COL_WIDTH      = 10,
   parameter integer CS_NUM         = 1,
   parameter integer CS_WIDTH       = 1,
   parameter integer DM_WIDTH       = 2,
   parameter integer DQ_WIDTH       = 16,
   parameter integer DQ_BITS        = 4,
   parameter integer DQ_PER_DQS     = 8,
   parameter integer DQS_WIDTH      = 2,
   parameter integer DQS_BITS       = 1,
   parameter integer ODT_WIDTH      = 1,
   parameter integer ROW_WIDTH      = 13,   
   parameter integer ADDITIVE_LAT   = 0,
   parameter integer BURST_LEN      = 4,   
   parameter integer BURST_TYPE     = 0,
   parameter integer CAS_LAT        = 5,
   parameter integer ECC_ENABLE     = 0,
   parameter         ECC_ENCODE_PIPELINE = 1'b0,
   parameter integer DQSN_ENABLE    = 1, 
   parameter integer ODT_TYPE       = 1,
   parameter integer REDUCE_DRV     = 0,
   parameter integer REG_ENABLE     = 0,
   parameter integer TWR            = 15000,
   parameter integer CLK_PERIOD     = 3000,   
   parameter integer DDR2_ENABLE    = 1,
   parameter integer DQS_GATE_EN    = 0,
   parameter         IDEL_HIGH_PERF = "TRUE",
   parameter integer SIM_ONLY       = 0,
   parameter         DEBUG_EN       = 0
   )
  (
   input                                  clk0,
   input                                  clk90,
   input                                  rst0,
   input                                  rst90,
   input                                  ctrl_wren,     // When write data is ready.  Basically DQS.
   input [ROW_WIDTH-1:0]                  ctrl_addr,     // 
   input [BANK_WIDTH-1:0]                 ctrl_ba,
   input                                  ctrl_ras_n,
   input                                  ctrl_cas_n,
   input                                  ctrl_we_n,
   input [CS_NUM-1:0]                     ctrl_cs_n,
   input                                  ctrl_rden,     // Set high for number of read data beats.  Needs to be high one cycle before ctrl_cas/ras/we specify read command.
   input                                  ctrl_ref_flag, // Refresh flag.  One cycle pulse.  Used for initialization counters for 200 us delay.  Assert every 7.8 us.
   input [(2*DQS_WIDTH*DQ_PER_DQS)-1:0]   wdf_data,      // Write training and write data.  Look at phy init module.
   input [(2*DM_WIDTH)-1:0]               wdf_mask_data,
   output [WDF_RDEN_WIDTH-1:0]            wdf_rden,      // Pop signal to FIFO.
   output                                 phy_init_done, // High once initialization done.
   output [DQS_WIDTH-1:0]                 phy_calib_rden,    // When read data is valid.
   output                                 phy_init_wdf_wren, // Push for write training pattern.
   output [63:0]                          phy_init_wdf_data, // Data for write training pattern
   output [(DQS_WIDTH*DQ_PER_DQS)-1:0]    rd_data_rise,      // LSB's
   output [(DQS_WIDTH*DQ_PER_DQS)-1:0]    rd_data_fall,      // MSB's
   output [CLK_WIDTH-1:0]                 ddr_ck,
   output [CLK_WIDTH-1:0]                 ddr_ck_n,
   output [ROW_WIDTH-1:0]                 ddr_addr,
   output [BANK_WIDTH-1:0]                ddr_ba,
   output                                 ddr_ras_n,
   output                                 ddr_cas_n,
   output                                 ddr_we_n,
   output [CS_WIDTH-1:0]                  ddr_cs_n,
   output [CKE_WIDTH-1:0]                 ddr_cke,
   output [ODT_WIDTH-1:0]                 ddr_odt,
   output [DM_WIDTH-1:0]                  ddr_dm,
   inout [DQS_WIDTH-1:0]                  ddr_dqs,
   inout [DQS_WIDTH-1:0]                  ddr_dqs_n,
   inout [DQ_WIDTH-1:0]                   ddr_dq,
   // Debug signals (optional use)
   output [DQS_WIDTH:0]                   dbg_calib_done,
   output [DQS_WIDTH:0]                   dbg_calib_err,
   output wire                            dbg_calib_sel_done,
   input  wire [DQS_WIDTH*8-1:0]          dbg_calib_dq_in_byte_align_value,
   input  wire [DQS_WIDTH-1:0]            dbg_calib_dq_in_byte_align_en,
   output wire [DQS_WIDTH*8-1:0]          dbg_calib_dq_in_byte_align,
   input  wire [DQS_WIDTH-1:0]            dbg_calib_cal_first_loop_value,
   input  wire [DQS_WIDTH-1:0]            dbg_calib_cal_first_loop_en,
   output wire [DQS_WIDTH-1:0]            dbg_calib_cal_first_loop,
   input  [(5*DQS_WIDTH)-1:0]             dbg_calib_rden_dly_value,
   input  [(DQS_WIDTH)-1:0]               dbg_calib_rden_dly_en,
   output [(5*DQS_WIDTH)-1:0]             dbg_calib_rden_dly,
   input  [DQS_WIDTH-1:0]                 dbg_calib_rd_data_sel_value,
   input  [DQS_WIDTH-1:0]                 dbg_calib_rd_data_sel_en,
   output [DQS_WIDTH-1:0]                 dbg_calib_rd_data_sel,

   input                                  dbg_idel_up_dq,
   input                                  dbg_idel_down_dq,
   input [DQ_BITS-1:0]                    dbg_sel_idel_dq,
   output [(6*DQ_WIDTH)-1:0]              dbg_calib_dq_tap_cnt,
   input  wire [DQS_WIDTH-1:0]            dbg_calib_delay_rd_fall_value,
   input  wire [DQS_WIDTH-1:0]            dbg_calib_delay_rd_fall_en,
   output wire [DQS_WIDTH-1:0]            dbg_calib_delay_rd_fall,
   input  wire [DQ_WIDTH-1:0]             dbg_calib_dq_delay_en_value,
   input  wire [DQ_WIDTH-1:0]             dbg_calib_dq_delay_en_en,
   output wire [DQ_WIDTH-1:0]             dbg_calib_dq_delay_en
   );  

  function integer log2( input integer x );
    begin
      if (x <= 2)
        log2 = 1;
      else if (x <= 4)
        log2 = 2;
      else if (x <= 8)
        log2 = 3;
      else if (x <= 16)
        log2 = 4;
      else if (x <= 32)
        log2 = 5;
      else if (x <= 64)
        log2 = 6;
      else if (x <= 128)
        log2 = 7;
      else if (x <= 256)
        log2 = 8;
    end
  endfunction

  wire [3:0]                              calib_done;
  reg                                     calib_done_d1;
  wire [3:0]                              calib_start;
  wire                                    calib_done_tmp;
  reg                                     calib_done_tmp_d1;
  reg                                     calib_done_tmp_d2;
  reg                                     calib_done_tmp_d3;
  reg                                     calib_done_tmp_d4;
  reg                                     calib_done_tmp_d5;
  reg                                     calib_done_tmp_d6;
  reg                                     ctrl_dummyread_start;
  wire                                    dq_oe_n;
  wire                                    dqs_oe;
  wire                                    dqs_rst;
  wire [DM_WIDTH-1:0]                     mask_data_fall;
  wire [DM_WIDTH-1:0]                     mask_data_rise;
  wire [DQS_WIDTH*DQ_PER_DQS-1:0]         wdf_data_rise;
  wire [DQS_WIDTH*DQ_PER_DQS-1:0]         wdf_data_fall;
  wire [DQS_WIDTH*DQ_PER_DQS/8-1:0]       wdf_mask_data_rise;
  wire [DQS_WIDTH*DQ_PER_DQS/8-1:0]       wdf_mask_data_fall;
  wire [ROW_WIDTH-1:0]                    phy_init_addr;
  wire [BANK_WIDTH-1:0]                   phy_init_ba;
  wire                                    phy_init_cas_n;
  wire [CKE_WIDTH-1:0]                    phy_init_cke;
  wire [CS_NUM-1:0]                       phy_init_cs_n;
  wire                                    phy_init_ras_n;
  wire                                    phy_init_rden;
  wire                                    phy_init_we_n;
  wire                                    phy_init_wren_early;
  wire                                    phy_init_wren_tmp;
  reg                                     phy_init_wren_tmp_d1;
  reg                                     phy_init_wren_tmp_d2;
  reg                                     phy_init_wren_tmp_d3;
  reg                                     phy_init_wren_tmp_d4;
  reg                                     phy_init_wren_i;
  wire                                    phy_init_wren;
  reg                                     phy_init_wren_d1;
  reg                                     phy_init_wren_d2;
  reg                                     phy_init_wren_d3;
  reg                                     phy_init_wren_d1_270;
  reg                                     phy_init_wren_d2_90;
  reg                                     phy_init_wren_d3_90;
  reg                                     phy_init_wren_d4_90;
  reg                                     phy_init_wren_d5_90;
  reg                                     phy_init_wren_d6_90;
  reg                                     phy_init_wren_d7_90;
  wire [DQ_WIDTH-1:0]                     wr_data_fall;
  wire [DQ_WIDTH-1:0]                     wr_data_rise;
  wire [DQS_WIDTH-1:0]                    dqs_delayed;
  wire [DQ_WIDTH-1:0]                     data_idelay_inc;
  wire [DQ_WIDTH-1:0]                     data_idelay_ce;
  wire [DQ_WIDTH-1:0]                     data_idelay_rst;
  wire [ODT_WIDTH-1:0]                    odt;
  wire [(DQS_WIDTH*DQ_PER_DQS/8)-1:0]     comp_done;
  wire [(DQS_WIDTH*DQ_PER_DQS/8)-1:0]     first_rising;
  wire [(DQS_WIDTH*DQ_PER_DQS/8)-1:0]     rd_en_rise;
  wire [(DQS_WIDTH*DQ_PER_DQS/8)-1:0]     rd_en_fall;
  reg [(DQS_WIDTH*DQ_PER_DQS/8)-1:0]      rd_en_fall_d1;
  reg [(DQS_WIDTH*DQ_PER_DQS/8)-1:0]      rd_en_fall_d2;
  
  reg                                     ctrl_wren_r/* synthesis syn_preserve = 1 */;
  reg                                     ctrl_wren_r_phy_write/* synthesis syn_preserve = 1 *//* synthesis syn_maxfan = 3 */;
  reg                                     ctrl_wren_r1_270;
  reg                                     ctrl_wren_r2_90;
  reg                                     ctrl_wren_r3_90;
  reg                                     ctrl_wren_r4_90;
  reg                                     ctrl_wren_r5_90;
  reg                                     ctrl_wren_d1;
  reg                                     ctrl_wren_d2;
  reg                                     ctrl_wren_d3;
  reg                                     ctrl_wren_d4;
  reg                                     ctrl_wren_d5;
  reg                                     ctrl_wren_d6;
  reg                                     ctrl_wren_d7;
  reg                                     ctrl_wren_d8;
  reg                                     ctrl_wren_d9;
  reg                                     ctrl_wren_d10;
  reg                                     phy_init_done_270;
  reg                                     phy_init_done_90;
  wire [(DQS_WIDTH*DQ_PER_DQS)-1:0]       rd_data_rise_i;
  reg [(DQS_WIDTH*DQ_PER_DQS)-1:0]        rd_data_rise_d1;
  reg [(DQS_WIDTH*DQ_PER_DQS)-1:0]        rd_data_rise_d2;
  wire [(DQS_WIDTH*DQ_PER_DQS)-1:0]       rd_data_fall_i;
  reg [(DQS_WIDTH*DQ_PER_DQS)-1:0]        rd_data_fall_d1;
  reg [(DQS_WIDTH*DQ_PER_DQS)-1:0]        rd_data_fall_d2;
  reg                                     ctrl_dqs_rst/* synthesis syn_preserve = 1 */;
  reg                                     ctrl_dqs_en/* synthesis syn_preserve = 1 */;
  reg                                     ctrl_odt/* synthesis syn_preserve = 1 */;
  reg [1:0]                               wr_en_i;
  reg [1:0]                               phy_init_wr_en_i;
  reg [1:0]                               wr_en/* synthesis syn_preserve = 1 */;
  reg                                     detect_fall;
  reg [(DQS_WIDTH*DQ_PER_DQS/8)-1:0]      delay_rd_fall;
  
  wire [DQ_WIDTH-1:0]                     per_bit_skew;
  wire [DQ_WIDTH-1:0]                     delay_enable;
  wire [DQS_WIDTH-1:0]                    comp_error;
  reg                                     cal_first_loop;
  wire [DQS_WIDTH-1:0]                    cal_first_loop_i;
  reg [DQS_WIDTH-1:0]                     cal_first_loop_r2;

  genvar i;
  genvar j;
  
  always @(posedge clk0)
    begin
      ctrl_wren_d1 <= ctrl_wren;
      ctrl_wren_d2 <= ctrl_wren_d1;
      ctrl_wren_d3 <= ctrl_wren_d2;
      ctrl_wren_d4 <= ctrl_wren_d3;
      ctrl_wren_d5 <= ctrl_wren_d4;
      ctrl_wren_d6 <= ctrl_wren_d5;
      ctrl_wren_d7 <= ctrl_wren_d6;
      ctrl_wren_d8 <= ctrl_wren_d7;
      ctrl_wren_d9 <= ctrl_wren_d8;
      ctrl_wren_d10 <= ctrl_wren_d9;
    end
  always @(posedge clk0)
    begin
      phy_init_wren_d1 <= phy_init_wren;
      phy_init_wren_d2 <= phy_init_wren_d1;
      phy_init_wren_d3 <= phy_init_wren_d2;   
    end
  
  always @(negedge clk90)
    begin
      ctrl_wren_r1_270    <= ctrl_wren_r;       
      phy_init_done_270    <= phy_init_done;
      phy_init_wren_d1_270 <= phy_init_wren;  
    end
  always @(posedge clk90)
    begin
      ctrl_wren_r2_90     <= ctrl_wren_r1_270;          
      ctrl_wren_r3_90     <= ctrl_wren_r2_90;   
      ctrl_wren_r4_90     <= ctrl_wren_r3_90;   
      ctrl_wren_r5_90     <= ctrl_wren_r4_90;   
      phy_init_done_90     <= phy_init_done_270;
      phy_init_wren_d2_90 <= phy_init_wren_d1_270;    
      phy_init_wren_d3_90 <= phy_init_wren_d2_90;     
      phy_init_wren_d4_90 <= phy_init_wren_d3_90;     
      phy_init_wren_d5_90 <= phy_init_wren_d4_90;     
      phy_init_wren_d6_90 <= phy_init_wren_d5_90;     
      phy_init_wren_d7_90 <= phy_init_wren_d6_90;     
    end
  
  generate
    if (DDR2_ENABLE==1)
      begin : gen_ctrl_wren_r_ddr2
        if ((ECC_ENABLE == 1) && (ECC_ENCODE_PIPELINE == 1))
          begin : gen_ctrl_wren_r_phy_write_eccpipeline
            always @(posedge clk0)
              begin
                case (ADDITIVE_LAT + CAS_LAT + REG_ENABLE + ECC_ENABLE - 1)
                  4'h3 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d1 : (ECC_ENABLE == 0 ? phy_init_wren : phy_init_wren_d1);
                  4'h4 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d2 : (ECC_ENABLE == 0 ? phy_init_wren : phy_init_wren_d1);
                  4'h5 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d3 : (ECC_ENABLE == 0 ? phy_init_wren : phy_init_wren_d1);
                  4'h6 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d4 : (ECC_ENABLE == 0 ? phy_init_wren : phy_init_wren_d1);
                  4'h7 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d5 : (ECC_ENABLE == 0 ? phy_init_wren : phy_init_wren_d1);
                  4'h8 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d6 : (ECC_ENABLE == 0 ? phy_init_wren : phy_init_wren_d1);
                  4'h9 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d7 : (ECC_ENABLE == 0 ? phy_init_wren : phy_init_wren_d1);
                  4'ha : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d8 : (ECC_ENABLE == 0 ? phy_init_wren : phy_init_wren_d1);
                  default : ctrl_wren_r_phy_write <= 1'b0;
                endcase
              end
            end
        else
          begin : gen_ctrl_wren_r_phy_write_noeccpipeline
            always @(posedge clk0)
              begin
                case (ADDITIVE_LAT + CAS_LAT + REG_ENABLE + ECC_ENABLE)
                  4'h3 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d1 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  4'h4 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d2 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  4'h5 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d3 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  4'h6 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d4 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  4'h7 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d5 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  4'h8 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d6 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  4'h9 : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d7 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  4'ha : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d8 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  4'hb : ctrl_wren_r_phy_write <= phy_init_done ? ctrl_wren_d9 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
                  default : ctrl_wren_r_phy_write <= 1'b0;
                endcase
              end
            end
        always @(posedge clk0)
          begin
            case (ADDITIVE_LAT + CAS_LAT + REG_ENABLE + ECC_ENABLE)
              4'h3 : ctrl_wren_r <= phy_init_done ? ctrl_wren_d1 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              4'h4 : ctrl_wren_r <= phy_init_done ? ctrl_wren_d2 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              4'h5 : ctrl_wren_r <= phy_init_done ? ctrl_wren_d3 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              4'h6 : ctrl_wren_r <= phy_init_done ? ctrl_wren_d4 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              4'h7 : ctrl_wren_r <= phy_init_done ? ctrl_wren_d5 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              4'h8 : ctrl_wren_r <= phy_init_done ? ctrl_wren_d6 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              4'h9 : ctrl_wren_r <= phy_init_done ? ctrl_wren_d7 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              4'ha : ctrl_wren_r <= phy_init_done ? ctrl_wren_d8 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              4'hb : ctrl_wren_r <= phy_init_done ? ctrl_wren_d9 : (ECC_ENABLE == 0 ? phy_init_wren_d1 : phy_init_wren_d2);
              default : ctrl_wren_r <= 1'b0;
            endcase
            case (ADDITIVE_LAT + CAS_LAT + REG_ENABLE + ECC_ENABLE + ECC_ENABLE)
              4'h3 : ctrl_dqs_en <= phy_init_done ? ctrl_wren    | ctrl_wren_d1 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'h4 : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d1 | ctrl_wren_d2 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'h5 : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d2 | ctrl_wren_d3 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'h6 : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d3 | ctrl_wren_d4 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'h7 : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d4 | ctrl_wren_d5 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'h8 : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d5 | ctrl_wren_d6 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'h9 : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d6 | ctrl_wren_d7 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'hA : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d7 | ctrl_wren_d8 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'hB : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d8 | ctrl_wren_d9 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              4'hC : ctrl_dqs_en <= phy_init_done ? ctrl_wren_d9 | ctrl_wren_d10 : (ECC_ENABLE == 0 ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_d2 | phy_init_wren_d3);
              default : ctrl_dqs_en <= 1'b0;
            endcase
            case (ADDITIVE_LAT + CAS_LAT + REG_ENABLE + ECC_ENABLE + ECC_ENABLE)
              4'h3 : ctrl_dqs_rst <= phy_init_done ? ~ctrl_wren_d1 : (ECC_ENABLE == 0 ? ~phy_init_wren_d1 : ~phy_init_wren_d3);
              4'h4 : ctrl_dqs_rst <= phy_init_done ? ~ctrl_wren_d2 : (ECC_ENABLE == 0 ? ~phy_init_wren_d1 : ~phy_init_wren_d3);
              4'h5 : ctrl_dqs_rst <= phy_init_done ? ~ctrl_wren_d3 : (ECC_ENABLE == 0 ? ~phy_init_wren_d1 : ~phy_init_wren_d3);
              4'h6 : ctrl_dqs_rst <= phy_init_done ? ~ctrl_wren_d4 : (ECC_ENABLE == 0 ? ~phy_init_wren_d1 : ~phy_init_wren_d3);
              4'h7 : ctrl_dqs_rst <= phy_init_done ? ~ctrl_wren_d5 : (ECC_ENABLE == 0 ? ~phy_init_wren_d1 : ~phy_init_wren_d3);
              4'h8 : ctrl_dqs_rst <= phy_init_done ? ~ctrl_wren_d6 : (ECC_ENABLE == 0 ? ~phy_init_wren_d1 : ~phy_init_wren_d3);
              4'h9 : ctrl_dqs_rst <= phy_init_done ? ~ctrl_wren_d7 : (ECC_ENABLE == 0 ? ~phy_init_wren_d1 : ~phy_init_wren_d3);
              4'hA : ctrl_dqs_rst <= phy_init_done ? ~ctrl_wren_d8 : (ECC_ENABLE == 0 ? ~phy_init_wren_d1 : ~phy_init_wren_d3);
              default : ctrl_dqs_rst <= 1'b0;
            endcase
            // REG_ENABLE purposely left out of this statement to assert ODT
            // one cycle earlier when using a registered memory. -CC 01/12/2009
            case (ADDITIVE_LAT + CAS_LAT)
              4'h3 : ctrl_odt <= phy_init_done ? ctrl_wren    | ctrl_wren_d1 : (REG_ENABLE == 0) ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_early | phy_init_wren;
              4'h4 : ctrl_odt <= phy_init_done ? ctrl_wren_d1 | ctrl_wren_d2 : (REG_ENABLE == 0) ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_early | phy_init_wren;
              4'h5 : ctrl_odt <= phy_init_done ? ctrl_wren_d2 | ctrl_wren_d3 : (REG_ENABLE == 0) ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_early | phy_init_wren;
              4'h6 : ctrl_odt <= phy_init_done ? ctrl_wren_d3 | ctrl_wren_d4 : (REG_ENABLE == 0) ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_early | phy_init_wren;
              4'h7 : ctrl_odt <= phy_init_done ? ctrl_wren_d4 | ctrl_wren_d5 : (REG_ENABLE == 0) ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_early | phy_init_wren;
              4'h8 : ctrl_odt <= phy_init_done ? ctrl_wren_d5 | ctrl_wren_d6 : (REG_ENABLE == 0) ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_early | phy_init_wren;
              4'h9 : ctrl_odt <= phy_init_done ? ctrl_wren_d6 | ctrl_wren_d7 : (REG_ENABLE == 0) ? phy_init_wren | phy_init_wren_d1 : phy_init_wren_early | phy_init_wren;
              default : ctrl_odt <= 1'b0;
            endcase
          end
        always @(*)
          begin
            wr_en_i[0] <= (ECC_ENABLE == 0 ? (ctrl_wren_r3_90 | ctrl_wren_r4_90) : (ctrl_wren_r4_90|ctrl_wren_r5_90));
            wr_en_i[1] <= (ECC_ENABLE == 0 ? (ctrl_wren_r2_90 | ctrl_wren_r3_90) : (ctrl_wren_r3_90 | ctrl_wren_r4_90));
          end
        always @(posedge clk90)
          begin
            phy_init_wr_en_i[0] <= (ECC_ENABLE == 0 ? (phy_init_wren_d4_90 |phy_init_wren_d5_90): (phy_init_wren_d6_90 | phy_init_wren_d7_90));
            phy_init_wr_en_i[1] <= (ECC_ENABLE == 0 ? (phy_init_wren_d3_90 |phy_init_wren_d4_90): (phy_init_wren_d5_90 | phy_init_wren_d6_90));
          end
      end
    else
      begin : gen_ctrl_wren_r_ddr
        if (REG_ENABLE==0)
          begin : gen_noreg
            always @(posedge clk0)
              begin
                ctrl_wren_r_phy_write  <= phy_init_done ? (((ECC_ENABLE == 0) || ((ECC_ENABLE == 1) && (ECC_ENCODE_PIPELINE == 1))) ? ctrl_wren : ctrl_wren_d1) : (((ECC_ENABLE == 1) && (ECC_ENCODE_PIPELINE == 1)) ? phy_init_wren : phy_init_wren_d1);
                ctrl_wren_r  <= phy_init_done ?  ((ECC_ENABLE == 0) ? ctrl_wren : ctrl_wren_d1) : phy_init_wren_d1;
                ctrl_dqs_rst <= phy_init_done ? (ECC_ENABLE == 0 ? ~ctrl_wren_d1 : ~ctrl_wren_d3) : (ECC_ENABLE == 0 ? ~phy_init_wren_d2 : ~phy_init_wren_d3);
                ctrl_dqs_en  <= phy_init_done ?  (ECC_ENABLE == 0 ? ctrl_wren | ctrl_wren_d1 : ctrl_wren_d2 | ctrl_wren_d3) :  (ECC_ENABLE == 0 ? phy_init_wren_d1 | phy_init_wren_d2 : phy_init_wren_d2 | phy_init_wren_d3);
                ctrl_odt     <= 1'b0;
              end
           end
        else
          begin : gen_reg
            always @(posedge clk0)
              begin
                ctrl_wren_r_phy_write  <= phy_init_done ? (((ECC_ENABLE == 0) || ((ECC_ENABLE == 1) && (ECC_ENCODE_PIPELINE == 1))) ? ctrl_wren_d1 : ctrl_wren_d2) : (((ECC_ENABLE == 1) && (ECC_ENCODE_PIPELINE == 1)) ? phy_init_wren : phy_init_wren_d1);
                ctrl_wren_r  <= phy_init_done ?  ((ECC_ENABLE == 0) ? ctrl_wren_d1 : ctrl_wren_d2) : phy_init_wren_d1;
                ctrl_dqs_rst <= phy_init_done ? (ECC_ENABLE == 0 ? ~ctrl_wren_d2 : ~ctrl_wren_d4) : (ECC_ENABLE == 0 ? ~phy_init_wren_d2 : ~phy_init_wren_d3);
                ctrl_dqs_en  <= phy_init_done ?  (ECC_ENABLE == 0 ? ctrl_wren_d1 | ctrl_wren_d2 : ctrl_wren_d3 | ctrl_wren_d4) :  (ECC_ENABLE == 0 ? phy_init_wren_d1 | phy_init_wren_d2 : phy_init_wren_d2 | phy_init_wren_d3);
                ctrl_odt     <= 1'b0;
              end
          end
        always @(*)
          begin
            wr_en_i[0] <= (ECC_ENABLE == 0 ? (ctrl_wren_r3_90 | ctrl_wren_r4_90) : (ctrl_wren_r4_90 | ctrl_wren_r5_90));
            wr_en_i[1] <= (ECC_ENABLE == 0 ? (ctrl_wren_r2_90 | ctrl_wren_r3_90) : (ctrl_wren_r3_90 | ctrl_wren_r4_90));
          end
        always @(posedge clk90)
          begin
            phy_init_wr_en_i[0] <= (ECC_ENABLE == 0 ? (phy_init_wren_d4_90 | phy_init_wren_d5_90) : (phy_init_wren_d5_90 | phy_init_wren_d6_90));
            phy_init_wr_en_i[1] <= (ECC_ENABLE == 0 ? (phy_init_wren_d3_90 | phy_init_wren_d4_90) : (phy_init_wren_d4_90 | phy_init_wren_d5_90));
          end
      end
  endgenerate
  always @(posedge clk90) begin
    wr_en <= phy_init_done_90 ? wr_en_i : phy_init_wr_en_i;
  end
  
  assign wdf_data_rise = wdf_data[DQS_WIDTH*DQ_PER_DQS-1:0];
  assign wdf_data_fall = wdf_data[DQS_WIDTH*DQ_PER_DQS*2-1:DQS_WIDTH*DQ_PER_DQS];
  assign wdf_mask_data_rise = wdf_mask_data[DQS_WIDTH*DQ_PER_DQS/8-1:0];
  assign wdf_mask_data_fall = wdf_mask_data[DQS_WIDTH*DQ_PER_DQS/8*2-1:DQS_WIDTH*DQ_PER_DQS/8];
  
  v4_phy_write  #
    (
     .WDF_RDEN_EARLY  (WDF_RDEN_EARLY),
     .WDF_RDEN_WIDTH  (WDF_RDEN_WIDTH),
     .DDR2_ENABLE     (DDR2_ENABLE),
     .ODT_TYPE        (ODT_TYPE),
     .ODT_WIDTH       (ODT_WIDTH),
     .dq_width        (DQ_WIDTH),
     .dm_width        (DM_WIDTH)
     )
    data_write_0
      (
       .CLK                  (clk0),
       .CLK90                (clk90),
       .RESET90              (rst90),
       .WDF_DATA_RISE        (wdf_data_rise[DQ_WIDTH-1:0]),
       .WDF_DATA_FALL        (wdf_data_fall[DQ_WIDTH-1:0]),
       .MASK_DATA_RISE       (wdf_mask_data_rise[DM_WIDTH-1:0]),
       .MASK_DATA_FALL       (wdf_mask_data_fall[DM_WIDTH-1:0]),
       .CTRL_WREN            (ctrl_wren_r_phy_write),
       .CTRL_DQS_RST         (ctrl_dqs_rst),
       .CTRL_DQS_EN          (ctrl_dqs_en),
       .CTRL_ODT             (ctrl_odt),
       .odt                  (odt),
       .dqs_rst              (dqs_rst),
       .dqs_en               (dqs_oe),
       .wr_en                (wdf_rden),
       .wr_data_rise         (wr_data_rise),
       .wr_data_fall         (wr_data_fall),
       .wr_mask_data_rise    (mask_data_rise),
       .wr_mask_data_fall    (mask_data_fall)
       );
  
  assign dbg_calib_done = {calib_done_tmp,comp_done};
  assign dbg_calib_err = {1'b0,comp_error};
  
  assign calib_done = {{2{1'b0}},(& comp_done),calib_done_tmp};
  always @(posedge clk0) begin
    calib_done_d1 <= & comp_done;
    calib_done_tmp_d1 <= calib_done_tmp;
    calib_done_tmp_d2 <= calib_done_tmp_d1;
    calib_done_tmp_d3 <= calib_done_tmp_d2;
    calib_done_tmp_d4 <= calib_done_tmp_d3;
    calib_done_tmp_d5 <= calib_done_tmp_d4;
    calib_done_tmp_d6 <= calib_done_tmp_d5;
  end
  v4_phy_tap_logic #
    (
     .data_width        (DQ_WIDTH),
     .data_bits         (DQ_BITS),
     .data_strobe_width (DQS_WIDTH),
     .tby4tapvalue      (TBY4TAPVALUE),
     .DatabitsPerStrobe (DQ_PER_DQS),
     .DEBUG_EN          (DEBUG_EN)
     )
    tap_logic_0
      (
       .CLK                   (clk0),
       .RESET0                (rst0),
       .CTRL_DUMMYREAD_START  (ctrl_dummyread_start),
       .calibration_dq        (rd_data_rise_i[DQ_WIDTH-1:0]),
       .data_idelay_inc       (data_idelay_inc),
       .data_idelay_ce        (data_idelay_ce),
       .data_idelay_rst       (data_idelay_rst),
       .SEL_DONE              (calib_done_tmp),
       .per_bit_skew          (per_bit_skew),
       .dbg_idel_up_all       (1'b0),
       .dbg_idel_down_all     (1'b0),
       .dbg_idel_up_dq        (dbg_idel_up_dq),
       .dbg_idel_down_dq      (dbg_idel_down_dq),
       .dbg_sel_idel_dq       (dbg_sel_idel_dq),
       .dbg_sel_all_idel_dq   (1'b0),
       .dbg_calib_dq_tap_cnt  (dbg_calib_dq_tap_cnt),
       .dbg_data_tap_inc_done (),
       .dbg_sel_done          (dbg_calib_sel_done)
       );
  
  v4_phy_iobs #
    (
     .DQSN_ENABLE       (DQSN_ENABLE),
     .DDR2_ENABLE       (DDR2_ENABLE),
     .clk_width         (CLK_WIDTH),
     .data_strobe_width (DQS_WIDTH),
     .data_width        (DQ_WIDTH),
     .data_mask_width   (DM_WIDTH),
     .row_address       (ROW_WIDTH),
     .bank_address      (BANK_WIDTH),
     .cs_width          (CS_WIDTH),
     .cke_width         (CKE_WIDTH),
     .odt_width         (ODT_WIDTH)
     )
    iobs_0
      (
       .DDR_CK                (ddr_ck),
       .DDR_CK_N              (ddr_ck_n),
       .CLK                   (clk0),
       .CLK90                 (clk90),
       .RESET0                (rst0),
       .data_idelay_inc       (data_idelay_inc),
       .data_idelay_ce        (data_idelay_ce),
       .data_idelay_rst       (data_idelay_rst),
       .delay_enable          (delay_enable),
       .dqs_rst               (dqs_rst),
       .dqs_en                (dqs_oe),
       .wr_en                 (wr_en),
       .wr_data_rise          (wr_data_rise),
       .wr_data_fall          (wr_data_fall),
       .mask_data_rise        (mask_data_rise),
       .mask_data_fall        (mask_data_fall),
       .rd_data_rise          (rd_data_rise_i[DQ_WIDTH-1:0]),
       .rd_data_fall          (rd_data_fall_i[DQ_WIDTH-1:0]),
       .dqs_delayed           (dqs_delayed),
       .DDR_DQ                (ddr_dq),
       .DDR_DQS               (ddr_dqs),
       .DDR_DQS_L             (ddr_dqs_n),
       .DDR_DM                (ddr_dm),
       .ctrl_ddr2_address     (phy_init_done ? ctrl_addr : phy_init_addr),
       .ctrl_ddr2_ba          (phy_init_done ? ctrl_ba : phy_init_ba),
       .ctrl_ddr2_ras_L       (phy_init_done ? ctrl_ras_n : phy_init_ras_n),
       .ctrl_ddr2_cas_L       (phy_init_done ? ctrl_cas_n : phy_init_cas_n),
       .ctrl_ddr2_we_L        (phy_init_done ? ctrl_we_n : phy_init_we_n),
       .ctrl_ddr2_cs_L        ({CS_WIDTH/CS_NUM{phy_init_done ? ctrl_cs_n : phy_init_cs_n}}),
       .ctrl_ddr2_cke         (phy_init_cke),
       .ctrl_ddr2_odt         (odt),
       .DDR_ADDRESS           (ddr_addr),
       .DDR_BA                (ddr_ba),
       .DDR_RAS_L             (ddr_ras_n),
       .DDR_CAS_L             (ddr_cas_n),
       .DDR_WE_L              (ddr_we_n),
       .DDR_CKE               (ddr_cke),
       .DDR_ODT               (ddr_odt),
       .ddr_cs_L              (ddr_cs_n)
       );
  
  always @(posedge clk0) begin
    if (rst0)
      detect_fall <= 1'b0;
    else
      detect_fall <= (| rd_en_fall);
  end

  always @(posedge clk0) begin
    rd_data_rise_d1 <= rd_data_rise_i;
    rd_data_rise_d2 <= rd_data_rise_d1;
    rd_data_fall_d1 <= rd_data_fall_i;
    rd_data_fall_d2 <= rd_data_fall_d1;
    rd_en_fall_d1 <= rd_en_fall & {(DQS_WIDTH*DQ_PER_DQS/8){phy_init_done}};
    rd_en_fall_d2 <= rd_en_fall_d1;
  end

assign dbg_calib_delay_rd_fall = delay_rd_fall;
  
  generate
    for (i=0;i<DQS_WIDTH*DQ_PER_DQS/8;i=i+1)
      begin : gen_pattern_compare
        if (DEBUG_EN) begin : gen_dbg
          reg dbg_ovr;
          always @(posedge clk0) begin
            if (rst0) begin
              dbg_ovr <= 1'b0;
              delay_rd_fall[i] <= 1'b0;
            end else begin
              if (dbg_calib_delay_rd_fall_en[i]) begin
                dbg_ovr <= 1'b1;
                delay_rd_fall[i] <= dbg_calib_delay_rd_fall_value[i];
              end else if (dbg_ovr==1'b0) begin
                delay_rd_fall[i] <= (~detect_fall & rd_en_fall[i] & 
                                     ~(& rd_en_fall)) | delay_rd_fall[i];
              end
            end
          end
        end else begin : gen_nodbg
          always @(posedge clk0) begin
            if (rst0)
              delay_rd_fall[i] <= 1'b0;
            else delay_rd_fall[i] <= (~detect_fall & rd_en_fall[i] & 
                                      ~(& rd_en_fall)) | delay_rd_fall[i];
          end
        end
        assign phy_calib_rden[i] = delay_rd_fall[i] ? 
                                   rd_en_fall_d2[i] :
                                   rd_en_fall_d1[i];
        assign rd_data_rise[(i+1)*8-1:i*8] = first_rising[i] ? 
               (delay_rd_fall[i] ? rd_data_fall_d2[(i+1)*8-1:i*8] :
                                   rd_data_fall_d1[(i+1)*8-1:i*8]) :
               rd_data_rise_d2[(i+1)*8-1:i*8];
        assign rd_data_fall[(i+1)*8-1:i*8] = first_rising[i] ? 
               (delay_rd_fall[i] ? rd_data_rise_d2[(i+1)*8-1:i*8] : 
                                   rd_data_rise_d1[(i+1)*8-1:i*8]) : 
               rd_data_fall_d1[(i+1)*8-1:i*8];
        v4_phy_pattern_compare8 #
          (
           .DEBUG_EN (DEBUG_EN)
           )
          u_pattern_compare
            (
             .clk                      (clk0),
             .rst                      (rst0),
             .ctrl_rden                (phy_init_done ? ctrl_rden : 
                                        phy_init_rden & calib_done_tmp_d6),
             .calib_done               (calib_done_d1),
             .rd_data_rise             (rd_data_rise_i[(i+1)*8-1:i*8]),
             .rd_data_fall             (rd_data_fall_i[(i+1)*8-1:i*8]),
             .per_bit_skew             (per_bit_skew[(i+1)*8-1:i*8]),
             .delay_enable             (delay_enable[(i+1)*8-1:i*8]),
             .comp_error               (comp_error[i]),
             .comp_done                (comp_done[i]),
             .first_rising             (first_rising[i]),
             .rd_en_rise               (rd_en_rise[i]),
             .rd_en_fall               (rd_en_fall[i]),
             .cal_first_loop           (cal_first_loop_i[i]),
             .dbg_calib_rden_dly_value (dbg_calib_rden_dly_value[i*5+:5]),
             .dbg_calib_rden_dly_en    (dbg_calib_rden_dly_en[i]),
             .dbg_calib_rden_dly       (dbg_calib_rden_dly[i*5+:5]),
             .dbg_calib_dq_in_byte_align_value(dbg_calib_dq_in_byte_align_value[i*8+:8]),
             .dbg_calib_dq_in_byte_align_en(dbg_calib_dq_in_byte_align_en[i]),
             .dbg_calib_rd_data_sel_value  (dbg_calib_rd_data_sel_value[i]),
             .dbg_calib_rd_data_sel_en     (dbg_calib_rd_data_sel_en[i])
             );
      end
  endgenerate
  assign dbg_calib_dq_in_byte_align = delay_enable;
  assign dbg_calib_cal_first_loop = cal_first_loop_i;
  assign dbg_calib_rd_data_sel = first_rising;
 
  //***************************************************************************
  // cal_first_loop: Flag for controller to issue a second pattern calibration
  // read if the first one does not result in a successful calibration.
  // Second pattern calibration command is issued to all DQS sets by NANDing
  // of CAL_FIRST_LOOP from all PATTERN_COMPARE modules. The set calibrated on
  // first pattern calibration command ignores the second calibration command,
  // since it will in CAL_DONE state (in PATTERN_COMPARE module) for the ones
  // calibrated. The set that is not calibrated on first pattern calibration
  // command, is calibrated on second calibration command.
  //***************************************************************************

  always @(posedge clk0)
    cal_first_loop_r2 <= cal_first_loop_i;

  always @(posedge clk0)
    if(rst0)
      cal_first_loop <= 1'b1;
    else
      cal_first_loop <= ~((cal_first_loop_r2 != cal_first_loop_i) && (~&cal_first_loop_i));


  always @(posedge clk0)
    begin
      if (rst0)
        ctrl_dummyread_start <= 1'b0;
      else
        ctrl_dummyread_start <=  ~(|calib_done) & (calib_start[0] | ctrl_dummyread_start);
    end
  generate
    if (DDR2_ENABLE == 1)
      begin : gen_phy_init_ddr2
        v4_phy_init_ddr2 #
          (
           .DQS_WIDTH    (DQS_WIDTH),
           .DQ_PER_DQS   (DQ_PER_DQS),
           .BANK_WIDTH   (BANK_WIDTH),
           .CKE_WIDTH    (CKE_WIDTH),
           .COL_WIDTH    (COL_WIDTH),
           .CS_NUM       (CS_NUM),
           .ODT_WIDTH    (ODT_WIDTH),
           .ROW_WIDTH    (ROW_WIDTH),
           .ADDITIVE_LAT (ADDITIVE_LAT),
           .BURST_LEN    (BURST_LEN),
           .BURST_TYPE   (BURST_TYPE),
           .CAS_LAT      (CAS_LAT),
           .ODT_TYPE     (ODT_TYPE),
           .REDUCE_DRV   (REDUCE_DRV),
           .REG_ENABLE   (REG_ENABLE),
           .TWR          (TWR),
           .CLK_PERIOD   (CLK_PERIOD),
           .ECC_ENABLE   (ECC_ENABLE),
           .DQSN_ENABLE  (DQSN_ENABLE),
           .DDR2_ENABLE  (DDR2_ENABLE),
           .DQS_GATE_EN  (DQS_GATE_EN),
           .SIM_ONLY     (SIM_ONLY)
           )
          u_phy_init
            (
             .clk0                (clk0),
             .rst0                (rst0),
             .calib_done          (calib_done),
             .ctrl_ref_flag       (ctrl_ref_flag),
             .cal_first_loop      (cal_first_loop),
             .calib_start         (calib_start),
             .phy_init_wren_early (phy_init_wren_early),
             .phy_init_wren       (phy_init_wren_tmp),
             .phy_init_rden       (phy_init_rden),
             .phy_init_wdf_wren   (phy_init_wdf_wren),
             .phy_init_wdf_data   (phy_init_wdf_data),
             .phy_init_addr       (phy_init_addr),
             .phy_init_ba         (phy_init_ba),
             .phy_init_ras_n      (phy_init_ras_n),
             .phy_init_cas_n      (phy_init_cas_n),
             .phy_init_we_n       (phy_init_we_n),
             .phy_init_cs_n       (phy_init_cs_n),
             .phy_init_cke        (phy_init_cke),
             .phy_init_done       (phy_init_done),
             .init_calib          ()
             );
        always @(posedge clk0) begin
          phy_init_wren_tmp_d1 <= phy_init_wren_tmp;
          phy_init_wren_tmp_d2 <= phy_init_wren_tmp_d1;
          phy_init_wren_tmp_d3 <= phy_init_wren_tmp_d2;
          phy_init_wren_tmp_d4 <= phy_init_wren_tmp_d3;           
        end
        always @(*) begin
          case (CAS_LAT)
            4'h3 : phy_init_wren_i <= phy_init_wren_tmp;
            4'h4 : phy_init_wren_i <= phy_init_wren_tmp_d1;
            4'h5 : phy_init_wren_i <= phy_init_wren_tmp_d2;
            4'h6 : phy_init_wren_i <= phy_init_wren_tmp_d3;
            4'h7 : phy_init_wren_i <= phy_init_wren_tmp_d4;
          endcase
        end
        assign phy_init_wren = phy_init_wren_i;
      end
    else
      begin : gen_phy_init_ddr1
        v4_phy_init_ddr1 #
          (
           .DQ_WIDTH     (DQ_WIDTH),
           .DQS_WIDTH    (DQS_WIDTH),
           .BANK_WIDTH   (BANK_WIDTH),
           .CKE_WIDTH    (CKE_WIDTH),
           .COL_WIDTH    (COL_WIDTH),
           .CS_NUM       (CS_NUM),
           .ODT_WIDTH    (ODT_WIDTH),
           .ROW_WIDTH    (ROW_WIDTH),
           .ADDITIVE_LAT (ADDITIVE_LAT),
           .BURST_LEN    (BURST_LEN),
           .BURST_TYPE   (BURST_TYPE),
           .CAS_LAT      (CAS_LAT),
           .ODT_TYPE     (ODT_TYPE),
           .REDUCE_DRV   (REDUCE_DRV),
           .REG_ENABLE   (REG_ENABLE),
           .ECC_ENABLE   (ECC_ENABLE),
           .DDR2_ENABLE  (DDR2_ENABLE),
           .DQS_GATE_EN  (DQS_GATE_EN),
           .SIM_ONLY     (SIM_ONLY)
           )
          u_phy_init
            (
             .clk0                (clk0),
             .rst0                (rst0),
             .calib_done          (calib_done),
             .ctrl_ref_flag       (ctrl_ref_flag),
             .cal_first_loop      (cal_first_loop),
             .calib_start         (calib_start),
             .phy_init_wren       (phy_init_wren),
             .phy_init_rden       (phy_init_rden),
             .phy_init_wdf_wren   (phy_init_wdf_wren),
             .phy_init_wdf_data   (phy_init_wdf_data),
             .phy_init_addr       (phy_init_addr),
             .phy_init_ba         (phy_init_ba),
             .phy_init_ras_n      (phy_init_ras_n),
             .phy_init_cas_n      (phy_init_cas_n),
             .phy_init_we_n       (phy_init_we_n),
             .phy_init_cs_n       (phy_init_cs_n),
             .phy_init_cke        (phy_init_cke),
             .phy_init_done       (phy_init_done)
             );
      end
  endgenerate
endmodule
