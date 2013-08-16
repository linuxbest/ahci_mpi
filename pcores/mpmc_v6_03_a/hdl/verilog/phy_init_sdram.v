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
//Device: Virtex-5
//Purpose:
//Reference:
//   This module is the intialization control logic of the memory interface. 
//   All commands are issued from here according to the burst, CAS Latency and 
//   the user commands.
//Revision History:
//   Rev 1.0 - First revision. 4/4/07
//
//*****************************************************************************

`timescale 1ns/1ps

module phy_init_sdram #

  (
   parameter DQ_WIDTH      = 16,
   parameter BANK_WIDTH    = 2,
   parameter CKE_WIDTH     = 2,
   parameter COL_WIDTH     = 10,
   parameter CS_NUM        = 1,
   parameter ROW_WIDTH     = 13,
   parameter BURST_LEN     = 4,
   parameter BURST_TYPE    = 0,
   parameter CAS_LAT       = 5,
   parameter REG_ENABLE    = 0,
   parameter ECC_ENABLE    = 0,
   parameter SIM_ONLY      = 0
   )
  (
   input                                   clk0,
   input                                   rst0,
   input                                   ctrl_ref_flag,
   output [ROW_WIDTH-1:0]                  phy_init_addr,
   output [BANK_WIDTH-1:0]                 phy_init_ba,
   output                                  phy_init_ras_n,
   output                                  phy_init_cas_n,
   output                                  phy_init_we_n,
   output [CS_NUM-1:0]                     phy_init_cs_n,
   output [CKE_WIDTH-1:0]                  phy_init_cke,
   output reg                              phy_init_done = 0
   );

  // time to wait during initialization phase related commands
  // generic delay of 70 ns as Tfc(min) = 66 ns 

localparam  CNTNEXT   =  4'b1110;  

// local parameters for signals assignment. Next state will be assigned with 
// these parameters and eventually get assigned to "init_state_r". 
// the Present state will be compared with these parameters and signals 
// will be assigned with their appropriate values.
  localparam  INIT_IDLE                = 4'h0;
  localparam  INIT_PRECHARGE           = 4'h1;
  localparam  INIT_PRECHARGE_WAIT      = 4'h2;
  localparam  INIT_AUTO_REFRESH_1      = 4'h3;
  localparam  INIT_AUTO_REFRESH_1_WAIT = 4'h4;
  localparam  INIT_AUTO_REFRESH_2      = 4'h5;
  localparam  INIT_AUTO_REFRESH_2_WAIT = 4'h6;
  localparam  INIT_LOAD_MODE           = 4'h7;
  localparam  INIT_LOAD_MODE_WAIT      = 4'h8;
  localparam  INITIALIZATION_DONE      = 4'h9;

  reg [4:0]             cnt_100us_r;
  reg                   done_100us_r;
  reg [3:0]             cnt66_r;
  
  reg [ROW_WIDTH-1:0]   sdram_addr_r;
  reg [ROW_WIDTH-1:0]   sdram_addr_r1;
  reg [BANK_WIDTH-1:0]  sdram_ba_r;
  reg [BANK_WIDTH-1:0]  sdram_ba_r1;
  reg                   sdram_cas_n_r;
  reg                   sdram_cas_n_r1;
  reg [CKE_WIDTH-1:0]   sdram_cke_r;
  reg [CS_NUM-1:0]      sdram_cs_n_r;
  reg                   sdram_ras_n_r;
  reg                   sdram_ras_n_r1;
  reg                   sdram_we_n_r;
  reg                   sdram_we_n_r1;
  
  reg [3:0]             init_next_state;
  reg [3:0]             init_state_r /* synthesis syn_maxfan = 3 */;
  
  wire [12:0]           load_mode_reg;
  
  
  
  //***************************************************************************

  //*****************************************************************
  // Mode Register (MR):
  //   [12:10] - Reserved
  //   [9]     - Write burst mode- 0 or 1
  //   [7:8]   - Operation mode  - 0 (standard operation)
  //   [6:4]   - CAS latency     - CAS_LAT
  //   [3]     - Burst Type      - BURST_TYPE
  //   [2:0]   - Burst Length    - BURST_LEN
  //*****************************************************************

    
      assign load_mode_reg[2:0]   = (BURST_LEN == 8) ? 3'b011  : 
                                    ((BURST_LEN == 4) ? 3'b010 : 3'b111);

      assign load_mode_reg[3]     = BURST_TYPE;

      assign load_mode_reg[6:4]   = (CAS_LAT == 2) ? 3'b010  :
                                    ((CAS_LAT == 3) ? 3'b011 : 
                                    ((CAS_LAT == 4) ? 3'b100 :
                                    ((CAS_LAT == 5) ? 3'b101 : 3'b111)));


      assign load_mode_reg[12:7]  = {6{1'b0}};
  
  //***************************************************************************
  // Initial delay after power-on
  //***************************************************************************
    
// 100us counter before initialization. Tck(min)=5ns (200MHz)
  always @(posedge clk0)
    if (rst0) begin
      // skip power-up count if only simulating
      if (SIM_ONLY)
        cnt_100us_r <= 5'b00111;
      else 
        cnt_100us_r <= 5'b11011;
    end 
    else if (!done_100us_r)
      cnt_100us_r <= cnt_100us_r - 1;

  // intial 100us delay satisfied.
  always @(posedge clk0)
    if (rst0)
      done_100us_r <= 1'b0;
    else if (!done_100us_r)
      done_100us_r <= (cnt_100us_r == 5'b00000) ;


  // generate delay for various states that require it (no maximum delay
  // requirement, make sure that terminal count is large enough to cover
  // all cases)
  always @(posedge clk0) begin
    case (init_state_r)
      INIT_PRECHARGE_WAIT, INIT_AUTO_REFRESH_1_WAIT,
      INIT_AUTO_REFRESH_2_WAIT, INIT_LOAD_MODE_WAIT:
        cnt66_r <= cnt66_r + 1;
      
      default:
        cnt66_r <= 4'b0000;
    endcase
  end


 
  //synthesis attribute max_fanout of init_state_r is 3                
  always @(posedge clk0)
    if (rst0) 
      init_state_r  <= INIT_IDLE;
    else 
      init_state_r  <= init_next_state;
  
// init_state_r is the present state

  always @(*) begin     
    init_next_state = init_state_r;
      if (done_100us_r) begin  
        case (init_state_r)
          INIT_IDLE: 
            init_next_state = INIT_PRECHARGE;
          
          INIT_PRECHARGE:
              init_next_state = INIT_PRECHARGE_WAIT;

          INIT_PRECHARGE_WAIT:
            if (cnt66_r == CNTNEXT) 
              init_next_state = INIT_AUTO_REFRESH_1;
            
          INIT_AUTO_REFRESH_1: 
              init_next_state = INIT_AUTO_REFRESH_1_WAIT;

          INIT_AUTO_REFRESH_1_WAIT: 
            if (cnt66_r == CNTNEXT) 
              init_next_state = INIT_AUTO_REFRESH_2;            
              
          INIT_AUTO_REFRESH_2: 
              init_next_state = INIT_AUTO_REFRESH_2_WAIT;
            
          INIT_AUTO_REFRESH_2_WAIT: 
            if (cnt66_r == CNTNEXT) 
              init_next_state = INIT_LOAD_MODE;
              
          INIT_LOAD_MODE:
              init_next_state = INIT_LOAD_MODE_WAIT;        
              
          INIT_LOAD_MODE_WAIT:
            if (cnt66_r == CNTNEXT) 
              init_next_state = INITIALIZATION_DONE;
              
          INITIALIZATION_DONE:  
            //init_next_state = INIT_IDLE;
             init_next_state = INITIALIZATION_DONE; //VPK
        
          default: 
            init_next_state = INIT_IDLE;
            
        endcase
      end
    end
  
  //***************************************************************************
  // Memory control/address
  //***************************************************************************
  
   always @(posedge clk0)
     begin
       if ((init_state_r == INIT_PRECHARGE) ||
           (init_state_r == INIT_LOAD_MODE) ||
           (init_state_r == INIT_AUTO_REFRESH_1) ||
           (init_state_r == INIT_AUTO_REFRESH_2))
         sdram_ras_n_r <= 1'b0;
       else
         sdram_ras_n_r <= 1'b1;
     end    

   always @(posedge clk0)
     begin
       if ((init_state_r == INIT_LOAD_MODE) || 
           (init_state_r == INIT_AUTO_REFRESH_1) ||
           (init_state_r == INIT_AUTO_REFRESH_2))
         sdram_cas_n_r <= 1'b0;
       else
         sdram_cas_n_r <= 1'b1;
     end    

   always @(posedge clk0)
     begin
       if ((init_state_r == INIT_LOAD_MODE) || 
           (init_state_r == INIT_PRECHARGE))
         sdram_we_n_r <= 1'b0;
       else 
         sdram_we_n_r <= 1'b1;
     end
     

  //*****************************************************************
  // memory address during init
  //*****************************************************************

  always @(posedge clk0) begin
    if (init_state_r == INIT_PRECHARGE) 
      sdram_addr_r <= {ROW_WIDTH{1'b1}};
    else if (init_state_r == INIT_LOAD_MODE) begin
      sdram_ba_r   <= {BANK_WIDTH{1'b0}};
      sdram_addr_r <= load_mode_reg;
    end 
    else begin
      // otherwise, cry me a river
      sdram_ba_r   <= {BANK_WIDTH{1'b0}};
      sdram_addr_r <= {ROW_WIDTH{1'b0}};
    end
  end
    
  // Keep CKE asserted after reset
  // Logic for self refresh and sleep mode is not introduced as yet.
  always @(posedge clk0)
    if (rst0)
      sdram_cke_r <= {CKE_WIDTH{1'b0}};
    else  
      sdram_cke_r <= {CKE_WIDTH{1'b1}};

 
  // This block will replicate and activate all the chip select signals
   // defines by CS_NUM.
   always @(posedge clk0)
     if (rst0)
       sdram_cs_n_r <= {CS_NUM{1'b1}};
     else 
      sdram_cs_n_r <= {CS_NUM{1'b0}};
 
 // Logic for self refresh and sleep mode is not introduced as yet.
  always @(posedge clk0)
    if (rst0)
      phy_init_done <= 1'b0;  
    else if (init_state_r == INITIALIZATION_DONE)
      phy_init_done <= 1'b1;
    
  // synthesis translate_off
  always @(posedge phy_init_done)
    $display ("Calibration completed");
  // synthesis translate_on
  

  // register commands to memory. Two clock cycle delay from state -> output
  
  always @(posedge clk0) begin
    sdram_addr_r1   <= sdram_addr_r;
    sdram_ba_r1     <= sdram_ba_r;
    sdram_cas_n_r1  <= sdram_cas_n_r;
    sdram_ras_n_r1  <= sdram_ras_n_r;
    sdram_we_n_r1   <= sdram_we_n_r;
  end
  
  assign phy_init_addr      = sdram_addr_r1;
  assign phy_init_ba        = sdram_ba_r1;
  assign phy_init_cas_n     = sdram_cas_n_r1;
  assign phy_init_cke       = sdram_cke_r;
  assign phy_init_cs_n      = sdram_cs_n_r;
  assign phy_init_ras_n     = sdram_ras_n_r1;
  assign phy_init_we_n      = sdram_we_n_r1;

endmodule
