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
// MPMC Spartam3 MIG PHY Calibration Control
//-------------------------------------------------------------------------
//
// Description:
//   It controlls the calibration circuit
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
//   Dec 20 2007: Merged MIG 2.1 modifications into this file.
//   Jul 18 2008: Merged MIG 2.3 modifications into this file.
//
//--------------------------------------------------------------------------

`timescale 1ns/100ps
  
module s3_cal_ctl  #
  (
   parameter C_FAMILY = "spartan3",      // Allowed Values: spartan3, spartan3e, spartan3a
   parameter integer C_SPECIAL_BOARD = 0 // Allowed Values: 0 = use default settings, 
                                         //                 1 = special placement
   )
  (
   input            clk,
   input            reset,
   input     [31:0] flop2,
   output reg [4:0] tapForDqs_rl /* synthesis syn_preserve=1 */,
   // debug signals
   output [4:0]     dbg_phase_cnt,
   output [5:0]     dbg_cnt,
   output           dbg_trans_onedtct,
   output           dbg_trans_twodtct,
   output           dbg_enb_trans_two_dtct
   );
  
  localparam tap1 = 5'b01111;
  localparam tap2 = 5'b10111;
  localparam tap3 = 5'b11011;
  localparam tap4 = 5'b11101;
  localparam tap5 = 5'b11110;
  localparam tap6 = 5'b11111;
  localparam defaultTap = tap4;
  
  reg [5:0]  cnt /* synthesis syn_preserve=1 */; 
  reg [5:0]  cnt1 /* synthesis syn_preserve=1 */; 
  
  reg        trans_oneDtct; 
  reg        trans_twoDtct; 
  
  reg [4:0]  phase_cnt /* synthesis syn_preserve=1 */;          
  reg [31:0] tap_dly_reg /* synthesis syn_preserve=1 */;        
  
  reg        enb_trans_two_dtct;   
  
  reg        reset_r/* synthesis syn_preserve=1 */;
   
  assign dbg_phase_cnt          = phase_cnt;
  assign dbg_cnt                = cnt1;
  assign dbg_trans_onedtct      = trans_oneDtct;
  assign dbg_trans_twodtct      = trans_twoDtct;
  assign dbg_enb_trans_two_dtct = enb_trans_two_dtct;
   

  always @( posedge clk )
    reset_r <= reset;
  
  always @(posedge clk) 
    begin
      if(reset_r)
        enb_trans_two_dtct <= 1'b0;
      else if(phase_cnt >= 5'd1)        
        enb_trans_two_dtct <= 1'b1;
      else
        enb_trans_two_dtct <= 1'b0;             
    end
  
  
  always @(posedge clk)
    begin
      if(reset_r)
        tap_dly_reg <= 32'd0;
      else if(cnt[5] == 1'b1)
        tap_dly_reg <= flop2;
      else
        tap_dly_reg <= tap_dly_reg;
    end
  
  // Free running counter for 32 states
  // Two parallel counters are used to fix the timing
  always @(posedge clk)
    begin
      if(reset_r || (cnt[5] == 1'b1)) 
        cnt[5:0] <= 6'b0;
      else
        cnt[5:0] <= cnt[5:0] + 1'b1;
    end
  
  always @(posedge clk)
    begin
      if(reset_r || (cnt1[5] == 1'b1)) 
        cnt1[5:0] <= 6'b0;
      else
        cnt1[5:0] <= cnt1[5:0] + 1'b1;
    end
  

  always @(posedge clk)
    begin
      if(reset_r || (cnt[5] == 1'b1))
        begin
          phase_cnt <= 5'd0;                    
        end
      else if (trans_oneDtct & (!trans_twoDtct))
        phase_cnt <= phase_cnt + 1;
      else
        phase_cnt <= phase_cnt;
    end 
  
  // Checking for the first transition
  always @(posedge clk)
    begin
      if(reset_r)
        begin
          trans_oneDtct <= 1'b0;
          trans_twoDtct <= 1'b0;
        end
      else if(cnt[5] == 1'b1)
        begin
          trans_oneDtct <= 1'b0;
          trans_twoDtct <= 1'b0;
        end
      else if (cnt[4:0] == 5'd0) 
      begin
        if ((tap_dly_reg[0]))
          begin
            trans_oneDtct <= 1'b1;
            trans_twoDtct <= 1'b0;
          end
      end
      else if ((tap_dly_reg[cnt[4:0]]) && (trans_twoDtct == 1'b0)) 
        begin
          
          if((trans_oneDtct == 1'b1) && (enb_trans_two_dtct) ) 
            begin       
              trans_twoDtct <= 1'b1;
            end
          else 
            begin
              trans_oneDtct <= 1'b1;
            end
        end 
    end 
  
  // For S3 and S3A designs
  generate
    if ((C_FAMILY == "spartan3") || (C_FAMILY == "spartan3a")) begin : gen_s3_s3a_tap
      
      always @(posedge clk)
        begin
          if(reset_r)
            tapForDqs_rl <= defaultTap;
          else if(cnt1[4] && cnt1[3] && cnt1[2] && cnt1[1] && cnt1[0])  // Count reached to 32
            begin
              if((trans_oneDtct == 1'b0) || (trans_twoDtct == 1'b0) || (phase_cnt > 5'd11))
                tapForDqs_rl <= tap4;
              else if((phase_cnt > 5'd8)) 
                tapForDqs_rl <= tap3;
              else
                tapForDqs_rl <= tap2;
            end
          else
            tapForDqs_rl <= tapForDqs_rl;
        end     
  
    end  // end Gen S3/S3A Tap
    
    else if ((C_FAMILY == "spartan3e") && (C_SPECIAL_BOARD == 0)) begin: gen_s3e_tap
      
      // For S3E designs
      always @(posedge clk)
        begin
          if(reset_r)
            tapForDqs_rl <= defaultTap;
          else if(cnt1[4] && cnt1[3] && cnt1[2] && cnt1[1] && cnt1[0])  // Count reached to 32
            begin
              if((trans_oneDtct == 1'b0) || (trans_twoDtct == 1'b0) || (phase_cnt > 5'd11))
                tapForDqs_rl <= tap6;
              else if((phase_cnt > 5'd8)) 
                tapForDqs_rl <= tap5;
              else
                tapForDqs_rl <= tap3;
            end
          else
            tapForDqs_rl <= tapForDqs_rl;
        end     

    end
    
    else if ((C_FAMILY == "spartan3e") && (C_SPECIAL_BOARD == 2)) begin: gen_s3e_special2_tap
      always @(posedge clk)
        tapForDqs_rl <= tap6;
  
    end
    
    else if ((C_FAMILY == "spartan3e") && (C_SPECIAL_BOARD == 1)) begin: gen_s3e_special1_tap
      always @(posedge clk)
        tapForDqs_rl <= tap5;
  
    end

  endgenerate
endmodule 
