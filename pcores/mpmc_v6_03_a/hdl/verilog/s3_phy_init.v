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
// MPMC Spartam3 MIG PHY Initialization
//-------------------------------------------------------------------------
//
// Description:
//   This module is the intialization control logic of the memory interface. 
//   All commands are issued from here acoording to the burst, CAS Latency and 
//   the user commands.
//   This file is also used to initialize the Static PHY.
//
// Structure:
//   -- s3_phy.v
//     -- s3_phy_init.v
//     -- s3_infrastructure.v
//       -- s3_cal_top.v
//         -- s3_cal_ctl.v
//         -- s3_tap_dly.v
//     -- s3_phy_write.v
//     -- s3_data_path.v
//       -- s3_data_read_controller.v
//         -- s3_dqs_delay.v
//         -- s3_fifo_0_wr_en.v
//         -- s3_fifo_1_wr_en.v
//       -- s3_data_read.v
//         -- s3_rd_data_ram0.v
//         -- s3_rd_data_ram1.v
//         -- s3_gray_cntr.v
//     -- s3_iobs.v
//       -- s3_infrastructure_iobs.v
//       -- s3_controller_iobs.v
//       -- s3_data_path_iobs.v
//         -- s3_dqs_iob.v
//         -- s3_dq_iob.v
//         -- s3_dm_iobs.v
//     
//--------------------------------------------------------------------------
//
// History:
//
//--------------------------------------------------------------------------

`timescale 1ns/1ps

module s3_phy_init #
  (
   parameter integer DQ_PER_DQS    = 8,
   parameter integer DQS_WIDTH     = 2,
   parameter integer BANK_WIDTH    = 2,
   parameter integer CKE_WIDTH     = 2,
   parameter integer COL_WIDTH     = 10,
   parameter integer CS_WIDTH      = 1,
   parameter integer ODT_WIDTH     = 2,
   parameter integer ROW_WIDTH     = 13,
   parameter integer ADDITIVE_LAT  = 0,
   parameter integer BURST_LEN     = 4,
   parameter integer BURST_TYPE    = 0,
   parameter integer CAS_LAT       = 3,
   parameter integer ODT_TYPE      = 0,
   parameter integer REDUCE_DRV    = 0,
   parameter integer DQSN_ENABLE   = 0,         // Enables differential DQS
   parameter integer DDR2_ENABLE   = 1,
   parameter integer REG_ENABLE    = 0,
   parameter integer TWR           = 15000,
   parameter integer CLK_PERIOD    = 3000,
   parameter integer STATIC_PHY    = 0,
   parameter integer SIM_ONLY      = 0
   )
  (
   input                   clk0,
   input                   clk180,
   input                   rst0,
   input                   ctrl_ref_flag,
   output [ROW_WIDTH-1:0]  phy_init_addr,
   output [BANK_WIDTH-1:0] phy_init_ba,
   output                  phy_init_ras_n,
   output                  phy_init_cas_n,
   output                  phy_init_we_n,
   output [CS_WIDTH-1:0]   phy_init_cs_n,
   output [CKE_WIDTH-1:0]  phy_init_cke,
   output reg              phy_init_done        
   );

  // Write recovery (WR) time - is defined by 
  // tWR (in nanoseconds) by tCK (in nanoseconds) and rounding up a 
  // noninteger value to the next integer
  localparam integer WR_RECOVERY =  ((TWR + CLK_PERIOD) - 1)/CLK_PERIOD;

  // time to wait after initialization-related writes and reads (used as a
  // generic delay - exact number doesn't matter as long as it's large enough)
  localparam  CNTNEXT   =  6'b101011;  

  localparam  INIT_IDLE                = 5'h00;
  localparam  INIT_CNT_200             = 5'h01;
  localparam  INIT_CNT_200_WAIT        = 5'h02;
  localparam  INIT_PRECHARGE           = 5'h03;
  localparam  INIT_PRECHARGE_WAIT      = 5'h04;
  localparam  INIT_LOAD_MODE           = 5'h05;
  localparam  INIT_MODE_REGISTER_WAIT  = 5'h06;
  localparam  INIT_AUTO_REFRESH        = 5'h07;
  localparam  INIT_AUTO_REFRESH_WAIT   = 5'h08;

  reg [1:0]             chip_cnt_r;
  reg [4:0]             cke_200us_cnt_r;
  reg [7:0]             cnt_200_cycle_r;
  reg                   cnt_200_cycle_done_r;
  reg [5:0]             cnt6_r;
  reg                   done_200us_r;
  reg [ROW_WIDTH-1:0]   ddr_addr_r;
  reg [ROW_WIDTH-1:0]   ddr_addr_r1;
  reg [BANK_WIDTH-1:0]  ddr_ba_r;
  reg [BANK_WIDTH-1:0]  ddr_ba_r1;
  reg                   ddr_cas_n_r;
  reg                   ddr_cas_n_r1;
  reg [CKE_WIDTH-1:0]   ddr_cke_r;
  reg [CS_WIDTH-1:0]    ddr_cs_n_r;
  reg                   ddr_ras_n_r;
  reg                   ddr_ras_n_r1;
  reg                   ddr_we_n_r;
  reg                   ddr_we_n_r1;
  wire [15:0]           ext_mode_reg;
  reg [3:0]             init_cnt_r;
  reg [4:0]             init_next_state;
  reg [4:0]             init_state_r;
  reg [4:0]             init_state_r1;
  reg [4:0]             init_state_r2;
  wire [15:0]           load_mode_reg;

   

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
  
  assign load_mode_reg[2:0] = (BURST_LEN == 8) ? 3'b011 : 
                              ((BURST_LEN == 4) ? 3'b010 : 3'b001);
  assign load_mode_reg[3]     = BURST_TYPE;

  // Generate allowable CAS LAT values based on memory type
  generate
    if (DDR2_ENABLE == 0) begin: gen_cas_ddr
      assign load_mode_reg[6:4] = (CAS_LAT == 2) ? 3'b010 : 3'b011;
      assign load_mode_reg[11:9]  = 3'b0;
    end
    else begin: gen_cas_ddr2
      assign load_mode_reg[6:4] = (CAS_LAT == 3) ? 3'b011 :
                                  ((CAS_LAT == 4) ? 3'b100 :
                                   ((CAS_LAT == 5) ? 3'b101 : 3'b011));
      assign load_mode_reg[11:9]  = (WR_RECOVERY == 6) ? 3'b101 :
                                    ((WR_RECOVERY == 5) ? 3'b100 :
                                     ((WR_RECOVERY == 4) ? 3'b011 :
                                      ((WR_RECOVERY == 3) ? 3'b010 :
                                      3'b001)));
    end
  endgenerate

  assign load_mode_reg[7]     = 1'b0;
  assign load_mode_reg[8]     = 1'b0;    
  assign load_mode_reg[15:12] = 4'b000;
  
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
    
  // Create EMR for DDR2 memory
  generate
    if (DDR2_ENABLE == 1) begin: gen_ddr2_emr
      assign ext_mode_reg[0]     = 1'b0;
      assign ext_mode_reg[1]     = REDUCE_DRV;
      assign ext_mode_reg[2]     = ((ODT_TYPE == 1) || (ODT_TYPE == 3)) ? 
                                   1'b1 : 1'b0;
      assign ext_mode_reg[5:3]   = (ADDITIVE_LAT == 0) ? 3'b000 : 
                                   ((ADDITIVE_LAT == 1) ? 3'b001 :
                                    ((ADDITIVE_LAT == 2) ? 3'b010 : 
                                     ((ADDITIVE_LAT == 3) ? 3'b011 : 3'b100)));
      assign ext_mode_reg[6]     = ((ODT_TYPE == 2) || (ODT_TYPE == 3)) ? 
                                   1'b1 : 1'b0;
      assign ext_mode_reg[9:7]   = 3'b000;
      // Add support for diffential DQS 
      assign ext_mode_reg[10]    = (DQSN_ENABLE == 0) ? 1'b1 : 1'b0;
      assign ext_mode_reg[15:11] = 6'b00000;
    end
    // Create EMR for DDR memory
    else begin: gen_ddr_emr
      assign ext_mode_reg[0] = 1'b0;
      assign ext_mode_reg[1] = REDUCE_DRV;
      assign ext_mode_reg[15:2] = 14'b00000000000000;  
    end
  endgenerate
  
  //**************************************************************************
  // generate delay for various states that require it (no maximum delay
  // requirement, make sure that terminal count is large enough to cover
  // all cases)
  always @(posedge clk0) begin
    case (init_state_r)
      INIT_PRECHARGE_WAIT, 
      INIT_MODE_REGISTER_WAIT, 
      INIT_AUTO_REFRESH_WAIT:
        cnt6_r <= cnt6_r + 1;
      default:
        cnt6_r <= 6'b000000;
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
  
  always @(posedge clk0)
    if (rst0)
      ddr_cs_n_r <= {CS_WIDTH{1'b1}};
    else begin
      ddr_cs_n_r <= {CS_WIDTH{1'b0}};
    end
  
  //***************************************************************************
  // Initialization state machine
  //***************************************************************************
  // synthesis attribute max_fanout of init_cnt_r is 1
  always @(posedge clk0)
    // every time we need to initialize another rank of memory, need to
    // reset init count, and repeat the entire initialization (but not
    // calibration) sequence
    if (rst0) // || (init_state_r == INIT_DEEP_MEMORY_ST))
      init_cnt_r <= 4'd0;
  
    else if (!DDR2_ENABLE && (init_state_r == INIT_PRECHARGE) && 
             (init_cnt_r == 4'h1))
      
      // For DDR1 => skip EMR(2) and EMR(3) register loads
      init_cnt_r <= 4'h4;
  
    else if (!DDR2_ENABLE && (init_state_r == INIT_IDLE) &&
             (init_cnt_r == 4'hA))
      
      // For DDR1 => skip OCD calibration
      init_cnt_r <= 4'hD;
  
    else if ((init_state_r == INIT_LOAD_MODE) || 
             (init_state_r == INIT_PRECHARGE) || 
             (init_state_r == INIT_AUTO_REFRESH) ||
             (init_state_r == INIT_CNT_200)) 
      init_cnt_r <= init_cnt_r + 1;
  
  always @(posedge clk0)
    // Since removing deep memory initialization requirements, can
    if (((init_state_r == INIT_IDLE) && (init_cnt_r == 4'hC)) || (!DDR2_ENABLE && (init_cnt_r == 4'hE)))
      phy_init_done <= 1'b1;
    else
      phy_init_done <= 1'b0;
  
  //*****************************************************************
  
  always @(posedge clk0)
    if (rst0) begin
      init_state_r  <= INIT_IDLE;
      init_state_r1 <= INIT_IDLE;
      init_state_r2 <= INIT_IDLE;
    end else begin
      init_state_r  <= init_next_state;
      init_state_r1 <= init_state_r;
      init_state_r2 <= init_state_r1;
    end
  
  // Main init state machine
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
              init_next_state = INIT_LOAD_MODE;         // EMR(2)
            4'h3: 
              init_next_state = INIT_LOAD_MODE;         // EMR(3);
            4'h4: 
              init_next_state = INIT_LOAD_MODE;         // EMR, enable DLL
            4'h5: 
              init_next_state = INIT_LOAD_MODE;         // MR, reset DLL
            4'h6: 
              init_next_state = INIT_PRECHARGE;
            4'h7: 
              init_next_state = INIT_AUTO_REFRESH;
            4'h8: 
              init_next_state = INIT_AUTO_REFRESH;
            4'h9: 
              init_next_state = INIT_LOAD_MODE;         // MR, unreset DLL
            4'hA:
              if (DDR2_ENABLE == 1)
                init_next_state = INIT_LOAD_MODE;       // EMR, OCD default
              else
                init_next_state = INIT_IDLE;            // skip OCD calibration
            4'hB: 
              init_next_state = INIT_LOAD_MODE;         // EMR, enable OCD exit
            4'hC: 
                init_next_state = INIT_IDLE;
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
    endcase
  end  
  
  
  //***************************************************************************
  // Memory control/address
  //***************************************************************************
  
  always @(posedge clk0)
    if ((init_state_r == INIT_PRECHARGE) ||
        (init_state_r == INIT_LOAD_MODE) ||
        (init_state_r == INIT_AUTO_REFRESH))
      ddr_ras_n_r <= 1'b0;
    else
      ddr_ras_n_r <= 1'b1;
  
  always @(posedge clk0)
    if ((init_state_r == INIT_LOAD_MODE) || 
        (init_state_r == INIT_AUTO_REFRESH)) 
      ddr_cas_n_r <= 1'b0;
    else
      ddr_cas_n_r <= 1'b1;

  always @(posedge clk0)
    if ((init_state_r == INIT_LOAD_MODE) || 
        (init_state_r == INIT_PRECHARGE))  
      ddr_we_n_r <= 1'b0;
    else 
      ddr_we_n_r <= 1'b1;
  
  //*****************************************************************
  // memory address during init
  //*****************************************************************

  // Create memory address during init for DDR2 memory
  generate
    if (DDR2_ENABLE == 1) begin: gen_ddr2_addr
      
      always @(posedge clk0) begin
        if (init_state_r == INIT_PRECHARGE) begin
          
          // Precharge all - set A10 = 1
          ddr_addr_r <= {ROW_WIDTH{1'b0}};
          ddr_addr_r[10] <= 1'b1;             
        end 
        
        else if (init_state_r == INIT_LOAD_MODE) begin
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
        end 
        else begin
          // otherwise, cry me a river
          ddr_ba_r   <= {BANK_WIDTH{1'bx}};
          ddr_addr_r <= {ROW_WIDTH{1'bx}};
        end
      end
  
    end         // end DDR2 generate
    
    // Create memory address during init for DDR memory
    else begin: gen_ddr_addr    
      
      always @(posedge clk0) begin
        if (init_state_r == INIT_PRECHARGE) begin
          
          // Precharge all - set A10 = 1
          ddr_addr_r <= {ROW_WIDTH{1'b0}};
          ddr_addr_r[10] <= 1'b1;             
        end 
        
        else if (init_state_r == INIT_LOAD_MODE) begin
          ddr_ba_r <= {BANK_WIDTH{1'b0}};
          ddr_addr_r <= {ROW_WIDTH{1'b0}};
          
          case (init_cnt_r) 
            
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
            
            default: begin
              ddr_ba_r <= {BANK_WIDTH{1'bx}};
              ddr_addr_r <= {ROW_WIDTH{1'bx}};
            end
          endcase
        end 
        else begin
          ddr_ba_r   <= {BANK_WIDTH{1'bx}};
          ddr_addr_r <= {ROW_WIDTH{1'bx}};
                        end
      end
  
    end         // end DDR generate
    
  endgenerate
  
  
  // Keep CKE asserted after initial power-on delay
  always @(posedge clk0)
    ddr_cke_r <= {CKE_WIDTH{done_200us_r}};
  
  generate
    if (STATIC_PHY == 0) begin: gen_out_on_clk180
      always @(posedge clk180) begin
        ddr_addr_r1   <= ddr_addr_r;
        ddr_ba_r1     <= ddr_ba_r;
        ddr_cas_n_r1  <= ddr_cas_n_r;
        ddr_ras_n_r1  <= ddr_ras_n_r;
        ddr_we_n_r1   <= ddr_we_n_r;
      end
    end
    else begin: gen_out_on_clk0
      always @(*) ddr_addr_r1   <= ddr_addr_r;
      always @(*) ddr_ba_r1     <= ddr_ba_r;
      always @(*) ddr_cas_n_r1  <= ddr_cas_n_r;
      always @(*) ddr_ras_n_r1  <= ddr_ras_n_r;
      always @(*) ddr_we_n_r1   <= ddr_we_n_r;
    end
  endgenerate

  assign phy_init_addr  = ddr_addr_r1;
  assign phy_init_ba    = ddr_ba_r1;
  assign phy_init_cas_n = ddr_cas_n_r1;
  assign phy_init_cke   = ddr_cke_r;
  assign phy_init_cs_n  = ddr_cs_n_r;
  assign phy_init_ras_n = ddr_ras_n_r1;
  assign phy_init_we_n  = ddr_we_n_r1;
  
endmodule
