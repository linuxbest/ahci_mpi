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

(* rom_style = "distributed" *)
module v4_phy_init_ddr2 #
  (
   parameter integer DQ_PER_DQS    = 8,
   parameter integer DQS_WIDTH     = 2,
   parameter integer BANK_WIDTH    = 2,
   parameter integer CKE_WIDTH     = 2,
   parameter integer COL_WIDTH     = 10,
   parameter integer CS_NUM        = 1,
   parameter integer ODT_WIDTH     = 2,
   parameter integer ROW_WIDTH     = 13,
   parameter integer ADDITIVE_LAT  = 0,
   parameter integer BURST_LEN     = 4,
   parameter integer BURST_TYPE    = 0,
   parameter integer CAS_LAT       = 5,
   parameter integer ODT_TYPE      = 1,
   parameter integer REDUCE_DRV    = 0,   
   parameter integer REG_ENABLE    = 0,
   parameter integer TWR           = 15000,
   parameter integer CLK_PERIOD    = 3000,
   parameter integer ECC_ENABLE    = 0,
   parameter integer DQSN_ENABLE   = 1,
   parameter integer DDR2_ENABLE   = 0,
   parameter integer DQS_GATE_EN   = 0,
   parameter integer SIM_ONLY      = 0
   )
  (
   input                                   clk0,
   input                                   rst0,
   input [3:0]                             calib_done,
   input                                   ctrl_ref_flag,
   input                                   cal_first_loop,
   output reg [3:0]                        calib_start,
   // Added for to turn on ODT one cycle earlier during initialization (CJC)
   output                                  phy_init_wren_early, 
   output reg                              phy_init_wren,
   output reg                              phy_init_rden,
   output                                  phy_init_wdf_wren,
   output [63:0]                           phy_init_wdf_data,
   output [ROW_WIDTH-1:0]                  phy_init_addr,
   output [BANK_WIDTH-1:0]                 phy_init_ba,
   output                                  phy_init_ras_n,
   output                                  phy_init_cas_n,
   output                                  phy_init_we_n,
   output [CS_NUM-1:0]                     phy_init_cs_n,
   output [CKE_WIDTH-1:0]                  phy_init_cke,
   output reg                              phy_init_done,
   output reg  [255:0]                     init_calib
   );

  localparam integer DQ_WIDTH = DQS_WIDTH * DQ_PER_DQS;
  
  // time to wait after initialization-related writes and reads (used as a
  // generic delay - exact number doesn't matter as long as it's large enough)
  localparam  CNTNEXT   =  7'b1101110;  

  // Write recovery (WR) time - is defined by 
  // tWR (in nanoseconds) by tCK (in nanoseconds) and rounding up a 
  // noninteger value to the next integer
  localparam integer WR_RECOVERY =  ((TWR + CLK_PERIOD) - 1)/CLK_PERIOD;

  localparam  INIT_IDLE                = 5'h00;
  localparam  INIT_CNT_200             = 5'h01;
  localparam  INIT_CNT_200_WAIT        = 5'h02;
  localparam  INIT_PRECHARGE           = 5'h03;
  localparam  INIT_PRECHARGE_WAIT      = 5'h04;
  localparam  INIT_LOAD_MODE           = 5'h05;
  localparam  INIT_MODE_REGISTER_WAIT  = 5'h06;
  localparam  INIT_AUTO_REFRESH        = 5'h07;
  localparam  INIT_AUTO_REFRESH_WAIT   = 5'h08;
  localparam  INIT_DEEP_MEMORY_ST      = 5'h09;
  localparam  INIT_DUMMY_ACTIVE        = 5'h0A;
  localparam  INIT_DUMMY_ACTIVE_WAIT   = 5'h0B;
  localparam  INIT_CAL1_WRITE          = 5'h0C;
  localparam  INIT_CAL1_WRITE_READ     = 5'h0D;
  localparam  INIT_CAL1_READ           = 5'h0E;
  localparam  INIT_CAL1_READ_WAIT      = 5'h0F;
  localparam  INIT_CAL2_WRITE          = 5'h10;
  localparam  INIT_CAL2_WRITE_READ     = 5'h11;
  localparam  INIT_CAL2_READ           = 5'h12;
  localparam  INIT_CAL2_READ_WAIT      = 5'h13;  
  localparam  INIT_CAL3_WRITE          = 5'h14;
  localparam  INIT_CAL3_WRITE_READ     = 5'h15;  
  localparam  INIT_CAL3_READ           = 5'h16;
  localparam  INIT_CAL3_READ_WAIT      = 5'h17;
  localparam  INIT_CAL4_READ           = 5'h18;
  localparam  INIT_CAL4_READ_WAIT      = 5'h19;
  
  reg [1:0]             burst_addr_r;
  reg [1:0]             burst_addr_r_d1;
  reg [1:0]             burst_cnt_r;
  wire [1:0]            burst_val;
  wire                  cal_read;
  wire                  cal_write;
  wire                  cal_write_i;
  wire                  cal_write_read;
  reg [15:0]            calib_start_shift0_r;             
  reg [15:0]            calib_start_shift1_r;             
  reg [15:0]            calib_start_shift2_r;                          
  reg [15:0]            calib_start_shift3_r;                          
  reg [1:0]             chip_cnt_r;
  reg [4:0]             cke_200us_cnt_r;
  reg [7:0]             cnt_200_cycle_r;
  reg                   cnt_200_cycle_done_r;
  reg [6:0]             cnt6_r;
  reg                   done_200us_r;
  reg [ROW_WIDTH-1:0]   ddr_addr_r;
  reg [ROW_WIDTH-1:0]   ddr_addr_r1;
  reg [ROW_WIDTH-1:0]   ddr_addr_r1a;
  reg [BANK_WIDTH-1:0]  ddr_ba_r;
  reg [BANK_WIDTH-1:0]  ddr_ba_r1;
  reg [BANK_WIDTH-1:0]  ddr_ba_r1a;
  reg                   ddr_cas_n_r;
  reg                   ddr_cas_n_r1;
  reg                   ddr_cas_n_r1a;
  reg [CKE_WIDTH-1:0]   ddr_cke_r;
  reg [CS_NUM-1:0]      ddr_cs_n_r;
  reg                   ddr_ras_n_r;
  reg                   ddr_ras_n_r1;
  reg                   ddr_ras_n_r1a;
  reg                   ddr_we_n_r;
  reg                   ddr_we_n_r1;
  reg                   ddr_we_n_r1a;
  wire [15:0]           ext_mode_reg;
  reg [3:0]             init_cnt_r;
  reg [4:0]             init_next_state;
  reg [4:0]             init_state_r;
  reg [4:0]             init_state_r1;
  reg [4:0]             init_state_r2;
  wire [15:0]           load_mode_reg;
  wire [3:0]            start_cal;

  reg [3:0]             init_wdf_cnt_r;
  reg [63:0]            init_data_r;
  reg                   init_done_r;
  reg                   init_wren_r;
  reg [3:0]             calib_done_r;
  wire                  cal_in_progress;
  reg                   phy_init_done_i;
  

 
  //***************************************************************************

  //*****************************************************************
  // Mode Register (MR):
  //   [15:14] - unused          - 00
  //   [13]    - reserved        - 0
  //   [12]    - Power-down mode - 0 (normal)
  //   [11:9]  - write recovery  - same value as written to CAS LAT
  //   [8]     - DLL reset       - 0 or 1
  //   [7]     - Test Mode       - 0 (normal)
  //   [6:4]   - CAS latency     - CAS_LAT
  //   [3]     - Burst Type      - BURST_TYPE
  //   [2:0]   - Burst Length    - BURST_LEN
  //*****************************************************************

  generate
    if (DDR2_ENABLE) begin: gen_load_mode_reg_ddr2  
      assign load_mode_reg[2:0]   = (BURST_LEN == 8) ? 3'b011 : 
                                    ((BURST_LEN == 4) ? 3'b010 : 3'b111);
      assign load_mode_reg[3]     = BURST_TYPE;
      assign load_mode_reg[6:4]   = (CAS_LAT == 3) ? 3'b011 : 
                                    ((CAS_LAT == 4) ? 3'b100 :
                                     ((CAS_LAT == 5) ? 3'b101 : 3'b111));
      assign load_mode_reg[7]     = 1'b0;
      assign load_mode_reg[8]     = 1'b0;    // init value only (DLL not reset)
      assign load_mode_reg[11:9]  = (WR_RECOVERY == 6) ? 3'b101 :
                                    ((WR_RECOVERY == 5) ? 3'b100 :
                                     ((WR_RECOVERY == 4) ? 3'b011 :
                                      ((WR_RECOVERY == 3) ? 3'b010 :
                                      3'b001)));
      assign load_mode_reg[15:12] = 4'b000;
    end else begin: gen_load_mode_reg_ddr1
      assign load_mode_reg[2:0]   = (BURST_LEN == 8) ? 3'b011 : 
                                    ((BURST_LEN == 4) ? 3'b010 : 
                                     ((BURST_LEN == 2) ? 3'b001 : 3'b111));
      assign load_mode_reg[3]     = BURST_TYPE;
      assign load_mode_reg[6:4]   = (CAS_LAT == 2) ? 3'b010 : 
                                    ((CAS_LAT == 3) ? 3'b011 :
                                     ((CAS_LAT == 6) ? 3'b110 : 3'b111));
      assign load_mode_reg[12:7]  = 6'b000000; // init value only 
      assign load_mode_reg[15:13]  = 3'b000;
    end
  endgenerate

   always@(posedge clk0)
     init_calib <= {250'd0, calib_start,init_state_r};
   
  //*****************************************************************
  // Extended Mode Register (MR):
  //   [15:14] - unused          - 00
  //   [13]    - reserved        - 0
  //   [12]    - output enable   - 0 (enabled)
  //   [11]    - RDQS enable     - 0 (disabled)
  //   [10]    - DQS# enable     - 0 (enabled)
  //   [9:7]   - OCD Program     - 111 or 000 (first 111, then 000 during init)
  //   [6]     - RTT[1]          - RTT[1:0] = 0(no ODT), 1(75), 2(150), 3(50)
  //   [5:3]   - Additive CAS    - ADDITIVE_CAS
  //   [2]     - RTT[0]
  //   [1]     - Output drive    - REDUCE_DRV (= 0(full), = 1 (reduced)
  //   [0]     - DLL enable      - 0 (normal)
  //*****************************************************************

  generate
    if (DDR2_ENABLE) begin: gen_ext_mode_reg_ddr2  
      assign ext_mode_reg[0]     = 1'b0;
      assign ext_mode_reg[1]     = REDUCE_DRV;
      assign ext_mode_reg[2]     = ((ODT_TYPE == 1) || (ODT_TYPE == 3)) ? 
                                   1'b1 : 1'b0;
      assign ext_mode_reg[5:3]   = (ADDITIVE_LAT == 0) ? 3'b000 : 
                                   ((ADDITIVE_LAT == 1) ? 3'b001 :
                                    ((ADDITIVE_LAT == 2) ? 3'b010 : 
                                     ((ADDITIVE_LAT == 3) ? 3'b011 :
                                      ((ADDITIVE_LAT == 4) ? 3'b100 : 
                                      3'b111))));
      assign ext_mode_reg[6]     = ((ODT_TYPE == 2) || (ODT_TYPE == 3)) ? 
                                   1'b1 : 1'b0;
      assign ext_mode_reg[9:7]   = 3'b000;
      assign ext_mode_reg[10]    = (DQSN_ENABLE == 0) ? 1'b1 : 1'b0;
      assign ext_mode_reg[15:11] = 5'b00000;
    end else begin: gen_ext_mode_reg_ddr1
      assign ext_mode_reg[0]     = 1'b0;
      assign ext_mode_reg[1]     = REDUCE_DRV;
      assign ext_mode_reg[12:2]  = 11'b00000000000;
      assign ext_mode_reg[15:13] = 3'b000;
    end
  endgenerate
  
  //***************************************************************************

  // generate pulse for each of calibration start controls
  assign start_cal[0] = ((init_state_r1 == INIT_CAL1_READ) &&
                         (init_state_r2 != INIT_CAL1_READ));
  assign start_cal[1] = ((init_state_r1 == INIT_CAL2_READ) &&
                         (init_state_r2 != INIT_CAL2_READ));
  assign start_cal[2] = ((init_state_r1 == INIT_CAL3_READ) &&
                         (init_state_r2 == INIT_CAL3_WRITE_READ));
  assign start_cal[3] = ((init_state_r1 == INIT_CAL4_READ) &&
                         (init_state_r2 == INIT_CAL3_READ_WAIT));

  // Delay start of each calibration by 16 clock cycles to
  // ensure that when calibration logic begins, that read data is already
  // appearing on the bus. Don't really need it, it's more for simulation
  // purposes. Each circuit should synthesize using an SRL16. 
  always @(posedge clk0) begin
    calib_start_shift0_r <= {calib_start_shift0_r[14:0], start_cal[0]};
    calib_start_shift1_r <= {calib_start_shift1_r[14:0], start_cal[1]};
    calib_start_shift2_r <= {calib_start_shift2_r[14:0], start_cal[2]};
    calib_start_shift3_r <= {calib_start_shift3_r[14:0], start_cal[3]};
    calib_start[0]       <= calib_start_shift0_r[15];
    calib_start[1]       <= calib_start_shift1_r[15];
    calib_start[2]       <= calib_start_shift2_r[15];
    calib_start[3]       <= calib_start_shift3_r[15];
  end

  // generate delay for various states that require it (no maximum delay
  // requirement, make sure that terminal count is large enough to cover
  // all cases)
  always @(posedge clk0) begin
    case (init_state_r)
      INIT_PRECHARGE_WAIT, 
      INIT_MODE_REGISTER_WAIT, 
      INIT_AUTO_REFRESH_WAIT, 
      INIT_DUMMY_ACTIVE_WAIT, 
      INIT_CAL1_WRITE_READ,
      INIT_CAL1_READ_WAIT, 
      INIT_CAL2_WRITE_READ, 
      INIT_CAL2_READ_WAIT,
      INIT_CAL3_WRITE_READ,
      INIT_CAL3_READ_WAIT,
      INIT_CAL4_READ_WAIT:
        cnt6_r <= cnt6_r + 1;
      default:
        cnt6_r <= 7'b000000;
    endcase
  end

  //***************************************************************************
  // Initial delay after power-on
  //***************************************************************************
    
  // 200us counter for cke
  always @(posedge clk0)
    if (rst0) begin
      // skip power-up count if only simulating
      if (SIM_ONLY)
        cke_200us_cnt_r <= 5'b00001;
      else 
        cke_200us_cnt_r <= 5'b11011;
    end else if (ctrl_ref_flag)
      cke_200us_cnt_r <= cke_200us_cnt_r - 1;

  // refresh detect in 266 MHz clock
  always @(posedge clk0)
    if (rst0)
      done_200us_r <= 1'b0;
    else if (!done_200us_r)
      done_200us_r <= (cke_200us_cnt_r == 5'b00000);

  // 200 clocks counter - count value : C8 required for initialization
  always @(posedge clk0)
    if (rst0 || (init_state_r == INIT_CNT_200))
      cnt_200_cycle_r <= 8'hC8;
    else if (cnt_200_cycle_r != 8'h00)
      cnt_200_cycle_r <= cnt_200_cycle_r - 1;

  always @(posedge clk0)
    if (rst0)
      cnt_200_cycle_done_r <= 1'b0;
    else 
      if (cnt_200_cycle_r == 8'h00)
        cnt_200_cycle_done_r <= 1'b1;
      else
        cnt_200_cycle_done_r <= 1'b0;

  //*****************************************************************
  // handle deep memory configuration:
  //   During initialization: Repeat initialization sequence once for each
  //   chip select. Note that we could perform initalization for all chip
  //   selects simulataneously. Probably fine - any potential SI issues with
  //   auto refreshing all chip selects at once?
  //   Once initialization complete, assert only CS[0] for calibration. 
  //*****************************************************************

  always @(posedge clk0)
    if (rst0) begin
      chip_cnt_r <= 2'b00;
    end else if (init_state_r == INIT_DEEP_MEMORY_ST) begin
      if (chip_cnt_r != CS_NUM)
        chip_cnt_r <= chip_cnt_r + 1;
      else
        chip_cnt_r <= 2'b00;
    end      
      
  always @(posedge clk0)
    if (rst0)
      ddr_cs_n_r <= {CS_NUM{1'b1}};
    else begin
       if (cal_in_progress == 1'b1) begin
          ddr_cs_n_r <= {CS_NUM{1'b1}};
          ddr_cs_n_r[chip_cnt_r] <= 1'b0;
       end
       else begin
         ddr_cs_n_r <= {CS_NUM{1'b0}};
       end
    end
  
  //***************************************************************************
  // Write/read burst logic
  //***************************************************************************

  assign cal_in_progress = ((init_state_r == INIT_DUMMY_ACTIVE) ||
                            (init_state_r == INIT_DUMMY_ACTIVE_WAIT) ||
                            (init_state_r == INIT_CAL1_WRITE) ||
                            (init_state_r == INIT_CAL2_WRITE) ||
                            (init_state_r == INIT_CAL3_WRITE) ||
                            (init_state_r == INIT_CAL1_WRITE_READ) ||
                            (init_state_r == INIT_CAL2_WRITE_READ) ||
                            (init_state_r == INIT_CAL3_WRITE_READ) ||
                            (init_state_r == INIT_CAL1_READ) ||
                            (init_state_r == INIT_CAL2_READ) ||
                            (init_state_r == INIT_CAL3_READ) ||
                            (init_state_r == INIT_CAL4_READ) ||
                            (init_state_r == INIT_CAL1_READ_WAIT) ||
                            (init_state_r == INIT_CAL2_READ_WAIT) ||
                            (init_state_r == INIT_CAL3_READ_WAIT) ||
                            (init_state_r == INIT_CAL4_READ_WAIT));

  generate
    if (ECC_ENABLE == 0)
      begin : gen_cal_write_i_noecc
        assign cal_write_i = ((init_state_r == INIT_CAL1_WRITE) ||
                              (init_state_r == INIT_CAL2_WRITE) ||
                              (init_state_r == INIT_CAL3_WRITE));
      end
    else
      begin : gen_cal_write_i_ecc
        assign cal_write_i = ((init_next_state == INIT_CAL1_WRITE) ||
                              (init_next_state == INIT_CAL2_WRITE) ||
                              (init_next_state == INIT_CAL3_WRITE));
      end
  endgenerate
  
  assign cal_write = ((init_state_r == INIT_CAL1_WRITE) ||
                      (init_state_r == INIT_CAL2_WRITE) ||
                      (init_state_r == INIT_CAL3_WRITE));
   
  assign cal_read = ((init_state_r == INIT_CAL1_READ) ||
                     (init_state_r == INIT_CAL2_READ) ||
                     (init_state_r == INIT_CAL3_READ) ||
                     (init_state_r == INIT_CAL4_READ));
  assign cal_write_read = cal_write | cal_read;

  assign burst_val = (BURST_LEN == 4) ? 2'b01 :
                     (BURST_LEN == 8) ? 2'b11 : 2'b00;
  
  // keep track of current address - need this if burst length < 8 for
  // stage 2-4 calibration writes and reads. Make sure value always gets
  // initialized to 0 before we enter write/read state. This is used to
  // keep track of when another burst must be issued
  always @(posedge clk0)
    if (cal_write_read)
      burst_addr_r <= burst_addr_r + 1;
    else
      burst_addr_r <= 3'b000;
  always @(posedge clk0)
      burst_addr_r_d1 <= burst_addr_r;

  // write/read burst count 
  always @(posedge clk0)
    if (cal_write_read)
      if (burst_cnt_r == 2'b00)
        burst_cnt_r <= burst_val;
      else
        burst_cnt_r <= burst_cnt_r - 1;
    else
      burst_cnt_r <= 2'b00;

  // indicate when a write is occurring
  generate 
    if (REG_ENABLE == 1) begin : gen_phy_init_wren_reg
      always @(posedge clk0)
        phy_init_wren <= cal_write_i;
    end
    else begin : gen_phy_init_wren_noreg
      always @(*)
        phy_init_wren <= cal_write_i;
    end
  endgenerate

  assign phy_init_wren_early = cal_write_i;

  // used for read enable calibration, pulse to indicate when read issued
  always @(posedge clk0)
    phy_init_rden <= cal_read;

  //***************************************************************************
  // State logic to write calibration training patterns to write data FIFO
  //***************************************************************************
  
  always @(posedge clk0) begin
    if (rst0) begin
      init_wdf_cnt_r  <= 4'd0;
      init_wren_r <= 1'b0;
      init_done_r <= 1'b0;
      init_data_r <= {64{1'bx}};
    end else begin
      init_wdf_cnt_r  <= init_wdf_cnt_r + 1;
      init_wren_r <= 1'b1;
      case (init_wdf_cnt_r)
        // First stage calibration. Pattern (rise/fall) = 1(r)->0(f)
        // The rise data and fall data are already interleaved in the manner 
        // required for data into the WDF write FIFO 
        4'h0, 4'h1, 4'h2, 4'h3:
          init_data_r <= {4{{8{1'b0}},{8{1'b1}}}};
        // Second stage calibration. Pattern = A(r)->5(f)->5(r)->A(f)
        4'h4: init_data_r <= {4{{2{4'h5}},{2{4'hA}}}};
        4'h5: init_data_r <= {4{{2{4'hA}},{2{4'h5}}}};
        4'h6: init_data_r <= {4{{2{4'h5}},{2{4'hA}}}};
        4'h7: begin
          init_data_r <= {4{{2{4'hA}},{2{4'h5}}}};
          init_done_r <= 1'b1;
          init_wdf_cnt_r  <= init_wdf_cnt_r;
          if (init_done_r) 
            init_wren_r <= 1'b0;
          else
            init_wren_r <= 1'b1;
        end
        // Third stage calibration. Pattern = FF->FF->AA->AA->55->55->00->00
        // Also make sure that last word is all zeros (because init_data_r is
        // OR'ed with app_wdf_data. 
        4'h8: init_data_r <= {64{1'b1}};
        4'h9: init_data_r <= {32{2'b10}};
        4'hA: init_data_r <= {32{2'b01}};
        // finished, stay in this state, and deassert WREN
        4'hB: begin
          init_data_r <= {64{1'b0}};
          init_done_r <= 1'b1;
          init_wdf_cnt_r  <= init_wdf_cnt_r;
          if (init_done_r) 
            init_wren_r <= 1'b0;
          else
            init_wren_r <= 1'b1;
        end
        default: begin
          init_data_r <= {64{1'bx}};
          init_wren_r <= 1'bx;
          init_done_r <= 1'bx;
          init_wdf_cnt_r  <= 4'bxxxx;
        end
      endcase
    end
  end

  //***************************************************************************
  
  //***************************************************************************
  // Initialization state machine
  //***************************************************************************

  always @(posedge clk0)
    // every time we need to initialize another rank of memory, need to
    // reset init count, and repeat the entire initialization (but not
    // calibration) sequence
    if (rst0 || (init_state_r == INIT_DEEP_MEMORY_ST))
      init_cnt_r <= 4'd0;
    else if (!DDR2_ENABLE && (init_state_r == INIT_PRECHARGE) && 
             (init_cnt_r == 4'h1))
      // skip EMR(2) and EMR(3) register loads
      init_cnt_r <= 4'h4;
    else if (!DDR2_ENABLE && (init_state_r == INIT_LOAD_MODE) &&
             (init_cnt_r == 4'h9))
      // skip OCD calibration for DDR1
      init_cnt_r <= 4'hC;
    else if ((init_state_r == INIT_LOAD_MODE) || 
             (init_state_r == INIT_PRECHARGE) || 
             (init_state_r == INIT_AUTO_REFRESH) ||
             (init_state_r == INIT_CNT_200)) 
      init_cnt_r <= init_cnt_r + 1;
  
  always @(posedge clk0)
    if ((init_state_r == INIT_IDLE) && (init_cnt_r == 4'hE))
      phy_init_done_i <= 1'b1;
    else
      phy_init_done_i <= 1'b0;

  always @(posedge clk0)
    phy_init_done <= phy_init_done_i;

  //*****************************************************************
  always @(posedge clk0)
    if (rst0) begin
      init_state_r  <= INIT_IDLE;
      init_state_r1 <= INIT_IDLE;
      init_state_r2 <= INIT_IDLE;
      calib_done_r  <= 4'b0000;
    end else begin
      init_state_r  <= init_next_state;
      init_state_r1 <= init_state_r;
      init_state_r2 <= init_state_r1;
      calib_done_r  <= calib_done; // register for timing
    end

  always @(*) begin     
    init_next_state = init_state_r;
    case (init_state_r)
      INIT_IDLE: begin
        if (done_200us_r) begin
          case (init_cnt_r) // synthesis parallel_case full_case
            4'h0: 
              init_next_state = INIT_CNT_200;
            4'h1: 
              if (cnt_200_cycle_done_r) 
                init_next_state = INIT_PRECHARGE;
            4'h2: 
              init_next_state = INIT_LOAD_MODE; // EMR(2)
            4'h3: 
              init_next_state = INIT_LOAD_MODE; // EMR(3);
            4'h4: 
              init_next_state = INIT_LOAD_MODE; // EMR, enable DLL
            4'h5: 
              init_next_state = INIT_LOAD_MODE; // MR, reset DLL
            4'h6: 
              init_next_state = INIT_PRECHARGE;
            4'h7: 
              init_next_state = INIT_AUTO_REFRESH;
            4'h8: 
              init_next_state = INIT_AUTO_REFRESH;
            4'h9: 
              init_next_state = INIT_LOAD_MODE; // MR, unreset DLL
            4'hA: 
              init_next_state = INIT_LOAD_MODE; // EMR, OCD default
            4'hB: 
              init_next_state = INIT_LOAD_MODE; // EMR, enable OCD exit
            4'hC: begin
              // Deep memory state/support disabled 
              //  if ((chip_cnt_r < CS_NUM-1)) 
              //  init_next_state = INIT_DEEP_MEMORY_ST;
              //else 
              if (cnt_200_cycle_done_r)
                init_next_state = INIT_DUMMY_ACTIVE; 
              else
                init_next_state = INIT_IDLE;
            end
            4'hD: 
              init_next_state = INIT_PRECHARGE;
            4'hE:
              init_next_state = INIT_IDLE;        
            default : 
              init_next_state = INIT_IDLE;
          endcase
        end
      end
      INIT_CNT_200: 
        init_next_state = INIT_CNT_200_WAIT;
      INIT_CNT_200_WAIT: 
        if (cnt_200_cycle_done_r) 
          init_next_state = INIT_IDLE;
      INIT_PRECHARGE: 
        init_next_state = INIT_PRECHARGE_WAIT;
      INIT_PRECHARGE_WAIT: 
        if (cnt6_r == CNTNEXT) 
          init_next_state = INIT_IDLE;
      INIT_LOAD_MODE: 
        init_next_state = INIT_MODE_REGISTER_WAIT;
      INIT_MODE_REGISTER_WAIT: 
        if (cnt6_r == CNTNEXT) 
          init_next_state = INIT_IDLE;
      INIT_AUTO_REFRESH: 
        init_next_state = INIT_AUTO_REFRESH_WAIT;
      INIT_AUTO_REFRESH_WAIT: 
        if (cnt6_r == CNTNEXT) 
          init_next_state = INIT_IDLE;
      INIT_DEEP_MEMORY_ST: 
        init_next_state = INIT_IDLE;
      // single row activate. All subsequent calibration writes and read will 
      // take place in this row      
      INIT_DUMMY_ACTIVE: 
        init_next_state = INIT_DUMMY_ACTIVE_WAIT;
      INIT_DUMMY_ACTIVE_WAIT: 
        if (cnt6_r == CNTNEXT) 
          init_next_state = INIT_CAL1_WRITE;
      // Stage 1 calibration (write and continuous read)
      INIT_CAL1_WRITE:
        if (burst_addr_r == 2'b11)
          init_next_state = INIT_CAL1_WRITE_READ;
      INIT_CAL1_WRITE_READ: 
        if (cnt6_r == CNTNEXT) 
          init_next_state = INIT_CAL1_READ;
      INIT_CAL1_READ:
        if (calib_done_r[0])
          init_next_state = INIT_CAL1_READ_WAIT;
      INIT_CAL1_READ_WAIT:
        if (cnt6_r == CNTNEXT)
          init_next_state = INIT_CAL2_WRITE;
      // Stage 2 calibration (write and continuous read)
      INIT_CAL2_WRITE:
        if (burst_addr_r == 2'b11)
          init_next_state = INIT_CAL2_WRITE_READ;
      INIT_CAL2_WRITE_READ: 
        if (cnt6_r == CNTNEXT) 
          init_next_state = INIT_CAL2_READ;
      INIT_CAL2_READ: 
	if (burst_cnt_r == 2'b01)
          init_next_state = INIT_CAL2_READ_WAIT;
      INIT_CAL2_READ_WAIT:
        if (calib_done_r[1])
          init_next_state = INIT_PRECHARGE;
        // Controller issues a second pattern calibration read
        // if the first one does not result in a successful calibration
        else if (!cal_first_loop)
          init_next_state = INIT_CAL2_READ;
      // Stage 3 calibration (write and continuous read)      
      INIT_CAL3_WRITE:
        if (burst_addr_r == 2'b11)
          init_next_state = INIT_CAL3_WRITE_READ;
      INIT_CAL3_WRITE_READ: 
        if (cnt6_r == CNTNEXT) 
          init_next_state = INIT_CAL3_READ;
      INIT_CAL3_READ: 
        if (burst_addr_r == 2'b11)
          init_next_state = INIT_CAL3_READ_WAIT;
      INIT_CAL3_READ_WAIT: begin
        if (cnt6_r == CNTNEXT)
          if (calib_done_r[2]) begin
            if (DQS_GATE_EN)
              init_next_state = INIT_CAL4_READ;
            else
              init_next_state = INIT_PRECHARGE;   
          end else
            init_next_state = INIT_CAL3_READ;
      end
      // Stage 4 calibration (continuous read only, same pattern as stage 3)
      // only used if DQS_GATE supported
      INIT_CAL4_READ: 
        if (burst_addr_r == 2'b11)
          init_next_state = INIT_CAL4_READ_WAIT;
      INIT_CAL4_READ_WAIT: begin
        if (cnt6_r == CNTNEXT)
          if (calib_done_r[3])
            init_next_state = INIT_PRECHARGE;
          else
            init_next_state = INIT_CAL4_READ;
      end                 
    endcase
  end

  //***************************************************************************
  // Memory control/address
  //***************************************************************************
  
  generate
    if (ECC_ENABLE == 0)
      begin : gen_ddr_ctrl_noecc
        always @(posedge clk0)
          if ((init_state_r == INIT_DUMMY_ACTIVE) ||
              (init_state_r == INIT_PRECHARGE) ||
              (init_state_r == INIT_LOAD_MODE) ||
              (init_state_r == INIT_AUTO_REFRESH))
            ddr_ras_n_r <= 1'b0;
          else
            ddr_ras_n_r <= 1'b1;
  
        always @(posedge clk0)
          if ((init_state_r == INIT_LOAD_MODE) || 
              (init_state_r == INIT_AUTO_REFRESH) ||
              (cal_write_read && (burst_cnt_r == 2'b00)))
            ddr_cas_n_r <= 1'b0;
          else
            ddr_cas_n_r <= 1'b1;
  
        always @(posedge clk0)
          if ((init_state_r == INIT_LOAD_MODE) || 
              (init_state_r == INIT_PRECHARGE) ||
              (cal_write && (burst_cnt_r == 2'b00)))
            ddr_we_n_r <= 1'b0;
          else 
            ddr_we_n_r <= 1'b1;
      end
    else
      begin : gen_ddr_ctrl_ecc
        always @(posedge clk0)
          if ((init_state_r == INIT_DUMMY_ACTIVE) ||
              (init_state_r == INIT_PRECHARGE) ||
              (init_state_r == INIT_LOAD_MODE) ||
              (init_state_r == INIT_AUTO_REFRESH))
            ddr_ras_n_r <= 1'b0;
          else
            ddr_ras_n_r <= 1'b1;
  
        always @(posedge clk0)
          if ((init_state_r == INIT_LOAD_MODE) || 
              (init_state_r == INIT_AUTO_REFRESH) ||
              (cal_write_read && (burst_cnt_r == 2'b01)))
            ddr_cas_n_r <= 1'b0;
          else
            ddr_cas_n_r <= 1'b1;
  
        always @(posedge clk0)
          if ((init_state_r == INIT_LOAD_MODE) || 
              (init_state_r == INIT_PRECHARGE) ||
              (cal_write && (burst_cnt_r == 2'b01)))
            ddr_we_n_r <= 1'b0;
          else 
            ddr_we_n_r <= 1'b1;
      end
  endgenerate
   
  //*****************************************************************
  // memory address during init
  //*****************************************************************

  always @(posedge clk0) begin
    if (init_state_r == INIT_PRECHARGE) begin
      // Precharge all - set A10 = 1
      ddr_addr_r <= {ROW_WIDTH{1'b0}};
      ddr_addr_r[10] <= 1'b1;             
    end else if (init_state_r == INIT_LOAD_MODE) begin
      ddr_ba_r <= {BANK_WIDTH{1'b0}};
      ddr_addr_r <= {ROW_WIDTH{1'b0}};
      case (init_cnt_r)
        // EMR (2)
        4'h2: begin
          ddr_ba_r[1:0] <= 2'b10;
          ddr_addr_r    <= {ROW_WIDTH{1'b0}};
        end
        // EMR (3)
        4'h3: begin
          ddr_ba_r[1:0] <= 2'b11;
          ddr_addr_r    <= {ROW_WIDTH{1'b0}};
        end
        // EMR write - A0 = 0 for DLL enable
        4'h4: begin
          ddr_ba_r[1:0] <= 2'b01;
          ddr_addr_r <= ext_mode_reg[ROW_WIDTH-1:0];
        end
        // MR write, reset DLL (A8=1)
        4'h5: begin
          ddr_ba_r[1:0] <= 2'b00;
          ddr_addr_r <= load_mode_reg[ROW_WIDTH-1:0];
          ddr_addr_r[8] <= 1'b1;
        end        
        // MR write, unreset DLL (A8=0)
        4'h9: begin
          ddr_ba_r[1:0] <= 2'b00;
          ddr_addr_r <= load_mode_reg[ROW_WIDTH-1:0];
        end
        // EMR write, OCD default state
        4'hA: begin
          ddr_ba_r[1:0] <= 2'b01;
          ddr_addr_r <= ext_mode_reg[ROW_WIDTH-1:0];
          ddr_addr_r[9:7] <= 3'b111;
        end    
        // EMR write - OCD exit
        4'hB: begin
          ddr_ba_r[1:0] <= 2'b01;
          ddr_addr_r <= ext_mode_reg[ROW_WIDTH-1:0];
        end
        default: begin
          ddr_ba_r <= {BANK_WIDTH{1'bx}};
          ddr_addr_r <= {ROW_WIDTH{1'bx}};
        end
      endcase
    end else if (cal_write_read) begin
      // when writing or reading for Stages 2-4, since training pattern is
      // either 4 (stage 2) or 8 (stage 3-4) long, if BURST LEN < 8, then
      // need to issue multiple bursts to read entire training pattern
      if (ECC_ENABLE == 0) begin
         //ddr_addr_r[ROW_WIDTH-1:3] <= {ROW_WIDTH-3{1'b0}};
         //ddr_addr_r[2:0]           <= {burst_addr_r, 1'b0};
         //ddr_ba_r                  <= {BANK_WIDTH{1'b0}};
         // Calibrate top of memory
         ddr_addr_r[ROW_WIDTH-1:3] <= {ROW_WIDTH-3{1'b1}};
         ddr_addr_r[2:0]           <= {burst_addr_r, 1'b0};
         ddr_ba_r                  <= {BANK_WIDTH{1'b1}};
         ddr_addr_r[10] <= 1'b0;             
      end
      else begin
         //ddr_addr_r[ROW_WIDTH-1:3] <= {ROW_WIDTH-3{1'b0}};
         //ddr_addr_r[2:0]           <= {burst_addr_r_d1, 1'b0};
         //ddr_ba_r                  <= {BANK_WIDTH{1'b0}};
         // Calibrate top of memory
         ddr_addr_r[ROW_WIDTH-1:3] <= {ROW_WIDTH-3{1'b1}};
         ddr_addr_r[2:0]           <= {burst_addr_r_d1, 1'b0};
         ddr_ba_r                  <= {BANK_WIDTH{1'b1}};
         ddr_addr_r[10] <= 1'b0;             
      end
    end else if (init_state_r == INIT_DUMMY_ACTIVE) begin
      // all calibration writing read takes place in row 0x0 only
      //ddr_ba_r   <= {BANK_WIDTH{1'b0}};
      //ddr_addr_r <= {ROW_WIDTH{1'b0}};      
      // Calibrate top of memory
      ddr_ba_r   <= {BANK_WIDTH{1'b1}};
      ddr_addr_r <= {ROW_WIDTH{1'b1}};      
    end else begin
      // otherwise, cry me a river
      ddr_ba_r   <= {BANK_WIDTH{1'bx}};
      ddr_addr_r <= {ROW_WIDTH{1'bx}};
    end
  end
    
  // Keep CKE asserted after initial power-on delay
  always @(posedge clk0)
    ddr_cke_r <= {CKE_WIDTH{done_200us_r}};

  // register commands to memory. Two clock cycle delay from state -> output
  generate
    if (ECC_ENABLE == 0) begin : gen_ctrl_out
      reg cal_write_d1;
      always @(posedge clk0) begin
        cal_write_d1  <= cal_write;
        ddr_addr_r1a  <= ddr_addr_r;
        ddr_ba_r1a    <= ddr_ba_r;
        ddr_cas_n_r1a <= ddr_cas_n_r;
        ddr_ras_n_r1a <= ddr_ras_n_r;
        ddr_we_n_r1a  <= ddr_we_n_r;
        ddr_addr_r1   <= cal_write_d1 ? ddr_addr_r1a  : ddr_addr_r;
        ddr_ba_r1     <= cal_write_d1 ? ddr_ba_r1a    : ddr_ba_r;
        ddr_cas_n_r1  <= cal_write_d1 ? ddr_cas_n_r1a : ddr_cas_n_r;
        ddr_ras_n_r1  <= cal_write_d1 ? ddr_ras_n_r1a : ddr_ras_n_r;
        ddr_we_n_r1   <= cal_write_d1 ? ddr_we_n_r1a  : ddr_we_n_r;
      end
    end
    else begin : gen_ctrl_out_ecc
      reg cal_write_d1;
      reg cal_write_d2;
      always @(posedge clk0) begin
        cal_write_d1  <= cal_write;
        cal_write_d2  <= cal_write_d1;
        ddr_addr_r1a  <= ddr_addr_r;
        ddr_ba_r1a    <= ddr_ba_r;
        ddr_cas_n_r1a <= ddr_cas_n_r;
        ddr_ras_n_r1a <= ddr_ras_n_r;
        ddr_we_n_r1a  <= ddr_we_n_r;
        ddr_addr_r1   <= cal_write_d2 ? ddr_addr_r1a  : ddr_addr_r;
        ddr_ba_r1     <= cal_write_d2 ? ddr_ba_r1a    : ddr_ba_r;
        ddr_cas_n_r1  <= cal_write_d2 ? ddr_cas_n_r1a : ddr_cas_n_r;
        ddr_ras_n_r1  <= cal_write_d2 ? ddr_ras_n_r1a : ddr_ras_n_r;
        ddr_we_n_r1   <= cal_write_d2 ? ddr_we_n_r1a  : ddr_we_n_r;
      end
    end
  endgenerate
  
  assign phy_init_addr      = ddr_addr_r1;
  assign phy_init_ba        = ddr_ba_r1;
  assign phy_init_cas_n     = ddr_cas_n_r1;
  assign phy_init_cke       = ddr_cke_r;
  assign phy_init_cs_n      = ddr_cs_n_r;
  assign phy_init_ras_n     = ddr_ras_n_r1;
  assign phy_init_we_n      = ddr_we_n_r1;
  assign phy_init_wdf_wren  = init_wren_r;
  assign phy_init_wdf_data  = init_data_r;

endmodule
