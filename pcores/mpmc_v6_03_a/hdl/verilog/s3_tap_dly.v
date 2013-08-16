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
// MPMC Spartam3 MIG PHY Tap Delay
//-------------------------------------------------------------------------
//
// Description:
//   Internal dqs delay structure for ddr sdram controller
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

`timescale 1ns/100ps

module s3_tap_dly #
  (
   parameter integer SIM_ONLY = 0
   )
  (
   input         clk,
   input         reset,
   input         tapIn,
   output [31:0] flop2
   );
  
  wire [31:0] #(0.4) tap_delay;
  wire [31:0]        tap/* synthesis syn_keep=1 */;
  wire [31:0]        flop1/* synthesis syn_keep=1 */;
  
  wire               high;
  
  genvar tap_i;

  assign high = 1'b1;
  
  generate
    
    if (SIM_ONLY == 0) begin: gen_no_sim
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l0    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tapIn), 
           .O(tap[0])
           );
      
      LUT4 #
        (
         .INIT(16'h4000)
         ) 
        l1    
          (
           .I0(tap[0]), 
           .I1(high), 
           .I2(high), 
           .I3(high), 
           .O(tap[1])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l2    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[1]), 
           .O(tap[2])
           );
      
      LUT4 #
        (
         .INIT(16'h0800)
         ) 
        l3    
          (
           .I0(high), 
           .I1(high), 
           .I2(tap[2]), 
           .I3(high), 
           .O(tap[3])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l4    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[3]), 
           .O(tap[4])
           );
      
      LUT4 #
        (
         .INIT(16'h0800)
         ) 
        l5    
          (
           .I0(high), 
           .I1(high), 
           .I2(tap[4]), 
           .I3(high), 
           .O(tap[5])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l6    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[5]), 
           .O(tap[6])
           );
      
      LUT4 #
        (
         .INIT(16'h4000)
         ) 
        l7    
          (
           .I0(tap[6]), 
           .I1(high), 
           .I2(high), 
           .I3(high), 
           .O(tap[7])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l8    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[7]), 
           .O(tap[8])
           );
      
      LUT4 #
        (
         .INIT(16'h4000)
         ) 
        l9    
          (
           .I0(tap[8]), 
           .I1(high), 
           .I2(high), 
           .I3(high), 
           .O(tap[9])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l10    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[9]), 
           .O(tap[10])
           );
      
      LUT4 #
        (
         .INIT(16'h0800)
         ) 
        l11    
          (
           .I0(high), 
           .I1(high), 
           .I2(tap[10]), 
           .I3(high), 
           .O(tap[11])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l12    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[11]), 
           .O(tap[12])
           );

      LUT4 #
        (
         .INIT(16'h0800)
         ) 
        l13    
          (
           .I0(high), 
           .I1(high), 
           .I2(tap[12]), 
           .I3(high), 
           .O(tap[13])
           );

      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l14    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[13]), 
           .O(tap[14])
           );
      
      LUT4 #
        (
         .INIT(16'h4000)
         ) 
        l15    
          (
           .I0(tap[14]), 
           .I1(high), 
           .I2(high), 
           .I3(high), 
           .O(tap[15])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l16    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[15]), 
           .O(tap[16])
           );
      
      LUT4 #
        (
         .INIT(16'h0800)
         ) 
        l17    
          (
           .I0(high), 
           .I1(high), 
           .I2(tap[16]), 
           .I3(high), 
           .O(tap[17])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l18    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[17]), 
           .O(tap[18])
           );
      
      LUT4 #
        (
         .INIT(16'h0800)
         ) 
        l19    
          (
           .I0(high), 
           .I1(high), 
           .I2(tap[18]), 
           .I3(high), 
           .O(tap[19])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l20    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[19]), 
           .O(tap[20])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l21    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[20]), 
           .O(tap[21])
           );
      
      LUT4 #
        (
         .INIT(16'h4000)
         ) 
        l22    
          (
           .I0(tap[21]), 
           .I1(high), 
           .I2(high), 
           .I3(high), 
           .O(tap[22])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l23    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[22]), 
           .O(tap[23])
           );
      
      LUT4 #
        (
         .INIT(16'h0800)
         ) 
        l24    
          (
           .I0(high), 
           .I1(high), 
           .I2(tap[23]), 
           .I3(high), 
           .O(tap[24])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l25    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[24]), 
           .O(tap[25])
           );
      
      LUT4 #
        (
         .INIT(16'h0800)
         ) 
        l26    
          (
           .I0(high), 
           .I1(high), 
           .I2(tap[25]), 
           .I3(high), 
           .O(tap[26])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l27    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[26]), 
           .O(tap[27])
           );
      
      LUT4 #
        (
         .INIT(16'h4000)
         ) 
        l28    
          (
           .I0(tap[27]), 
           .I1(high), 
           .I2(high), 
           .I3(high), 
           .O(tap[28])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l29    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[28]), 
           .O(tap[29])
           );
      
      LUT4 #
        (
         .INIT(16'h4000)
         ) 
        l30    
          (
           .I0(tap[29]), 
           .I1(high), 
           .I2(high), 
           .I3(high), 
           .O(tap[30])
           );
      
      LUT4 #
        (
         .INIT(16'h0080)
         ) 
        l31    
          (
           .I0(high), 
           .I1(high), 
           .I2(high), 
           .I3(tap[30]), 
           .O(tap[31])
           );
      
      
      for(tap_i = 0; tap_i < 32;  tap_i = tap_i + 1) begin: gen_tap1
        FDR r 
          (
           .Q (flop1[tap_i]),
           .C (clk), 
           .D (tap[tap_i]), 
           .R (reset)
           );
      end
      
    end
    else
      begin: gen_sim_delay
        
        assign tap_delay[0] = tapIn;
        assign tap_delay[1] = tap_delay[0];
        assign tap_delay[2] = tap_delay[1];
        assign tap_delay[3] = tap_delay[2];
        assign tap_delay[4] = tap_delay[3];
        assign tap_delay[5] = tap_delay[4];
        assign tap_delay[6] = tap_delay[5];
        assign tap_delay[7] = tap_delay[6];
        assign tap_delay[8] = tap_delay[7];
        assign tap_delay[9] = tap_delay[8];
        assign tap_delay[10] = tap_delay[9];
        assign tap_delay[11] = tap_delay[10];
        assign tap_delay[12] = tap_delay[11];
        assign tap_delay[13] = tap_delay[12];
        assign tap_delay[14] = tap_delay[13];
        assign tap_delay[15] = tap_delay[14];
        assign tap_delay[16] = tap_delay[15];
        assign tap_delay[17] = tap_delay[16];
        assign tap_delay[18] = tap_delay[17];
        assign tap_delay[19] = tap_delay[18];
        assign tap_delay[20] = tap_delay[19];
        assign tap_delay[21] = tap_delay[20];
        assign tap_delay[22] = tap_delay[21];
        assign tap_delay[23] = tap_delay[22];
        assign tap_delay[24] = tap_delay[23];
        assign tap_delay[25] = tap_delay[24];
        assign tap_delay[26] = tap_delay[25];
        assign tap_delay[27] = tap_delay[26];
        assign tap_delay[28] = tap_delay[27];
        assign tap_delay[29] = tap_delay[28];
        assign tap_delay[30] = tap_delay[29];
        assign tap_delay[31] = tap_delay[30];

        for(tap_i = 0; tap_i < 32;  tap_i = tap_i + 1) begin: gen_tap1
          FDR r 
            (
             .Q (flop1[tap_i]),
             .C (clk), 
             .D (tap_delay[tap_i]), 
             .R (reset)
             );
        end

      end
  endgenerate
  
  
  
  genvar tap1_i;
  generate for(tap1_i = 0; tap1_i < 31;  tap1_i = tap1_i + 1) begin: gen_tap2
    FDR u  
      ( 
        .Q (flop2[tap1_i]),
        .C (clk), 
        .D (flop1[tap1_i] ~^ flop1[tap1_i + 1]),
        .R (reset)
        );
  end
  endgenerate

  FDR u31  
    ( 
      .Q (flop2[31]),
      .C (clk),
      .D (flop1[31]), 
      .R (reset)
      );

endmodule

