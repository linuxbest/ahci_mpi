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
// Description: Priority encoder for arbiter.
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

module high_priority_select
  (
   Clk,     // I
   Rst,     // I
   PI_D,    // I [C_NUM_PORTS-1:0]
   PI_CE,   //
   PI_Rst,  // I [C_NUM_PORTS-1:0]
   Q        // O
   );

   parameter C_FAMILY = "virtex4";
   parameter C_NUM_PORTS = 8;  // Allowed Values: 1-8
   parameter C_PI_D_WIDTH = 1; // Allowed Values: Any integer
   
   input                                Clk;
   input                                Rst;
   input [C_NUM_PORTS*C_PI_D_WIDTH-1:0] PI_D;
   input                                PI_CE;
   input [C_NUM_PORTS-1:0]              PI_Rst;
   output [C_PI_D_WIDTH-1:0]            Q;
                   
   reg [C_NUM_PORTS*C_PI_D_WIDTH-1:0]   pi_q_i = 0;
   wire [C_NUM_PORTS-1:0]               pi_ff_rst;
   
   genvar i;

   // Instanitate FFs
   
   always @(posedge Clk) begin
      if (Rst)
        pi_q_i[C_PI_D_WIDTH-1:0] <= 0;
      if (PI_CE)
        pi_q_i[C_PI_D_WIDTH-1:0] <=  PI_D[C_PI_D_WIDTH-1:0];
   end

   generate
     if (C_NUM_PORTS > 1) begin : instantiate_ff1
         always @(posedge Clk) begin
           if (Rst)
             pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] <= 0;
	   else if (PI_CE)
	     if (PI_Rst[1])
	       pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] <= 0;
             else
               pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] <=  PI_D[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH];
         end
      end
   endgenerate
   
   generate
      if (C_NUM_PORTS > 2) begin : instantiate_ff2
         always @(posedge Clk) begin
           if (Rst)
             pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2] <= 0;
           else if (PI_CE)
             if (PI_Rst[1] | PI_Rst[2])
               pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2] <= 0;
             else
               pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2] <=  PI_D[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2];
         end
      end
   endgenerate
   
   generate
      if (C_NUM_PORTS > 3) begin : instantiate_ff3
         always @(posedge Clk) begin
            if (Rst)
              pi_q_i[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3] <= 0;
            else if (PI_CE)
              if (PI_Rst[1] | PI_Rst[2] | PI_Rst[3])
		pi_q_i[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3] <= 0;
              else
		pi_q_i[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3] <=  PI_D[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3];
         end
      end
   endgenerate
   
   generate
      if (C_NUM_PORTS > 4) begin : instantiate_ff4
         always @(posedge Clk) begin
            if (Rst)
              pi_q_i[C_PI_D_WIDTH*5-1:C_PI_D_WIDTH*4] <= 0;
            else if (PI_CE)
              if (PI_Rst[1] | PI_Rst[2] | PI_Rst[3] | PI_Rst[4])
		pi_q_i[C_PI_D_WIDTH*5-1:C_PI_D_WIDTH*4] <= 0;
              else
		pi_q_i[C_PI_D_WIDTH*5-1:C_PI_D_WIDTH*4] <=  PI_D[C_PI_D_WIDTH*5-1:C_PI_D_WIDTH*4];
         end
      end
   endgenerate
   
   generate
      if (C_NUM_PORTS > 5) begin : instantiate_ff5
         always @(posedge Clk) begin
            if (Rst)
              pi_q_i[C_PI_D_WIDTH*6-1:C_PI_D_WIDTH*5] <= 0;
            else if (PI_CE)
              if (PI_Rst[1] | PI_Rst[2] | PI_Rst[3] | PI_Rst[4] | PI_Rst[5])
		pi_q_i[C_PI_D_WIDTH*6-1:C_PI_D_WIDTH*5] <= 0;
              else
		pi_q_i[C_PI_D_WIDTH*6-1:C_PI_D_WIDTH*5] <=  PI_D[C_PI_D_WIDTH*6-1:C_PI_D_WIDTH*5];
         end
      end
   endgenerate
   
   generate
      if (C_NUM_PORTS > 6) begin : instantiate_ff6
         always @(posedge Clk) begin
            if (Rst)
              pi_q_i[C_PI_D_WIDTH*7-1:C_PI_D_WIDTH*6] <= 0;
            else if (PI_CE)
              if (PI_Rst[1] | PI_Rst[2] | PI_Rst[3] | PI_Rst[4] | PI_Rst[5] | PI_Rst[6])
		pi_q_i[C_PI_D_WIDTH*7-1:C_PI_D_WIDTH*6] <= 0;
              else
		pi_q_i[C_PI_D_WIDTH*7-1:C_PI_D_WIDTH*6] <=  PI_D[C_PI_D_WIDTH*7-1:C_PI_D_WIDTH*6];
         end
      end
   endgenerate
   
   generate
      if (C_NUM_PORTS > 7) begin : instantiate_ff7
         always @(posedge Clk) begin
            if (Rst)
              pi_q_i[C_PI_D_WIDTH*8-1:C_PI_D_WIDTH*7] <= 0;
            else if (PI_CE)
              if (PI_Rst[1] | PI_Rst[2] | PI_Rst[3] | PI_Rst[4] | PI_Rst[5] | PI_Rst[6] | PI_Rst[7])
		pi_q_i[C_PI_D_WIDTH*8-1:C_PI_D_WIDTH*7] <= 0;
              else
		pi_q_i[C_PI_D_WIDTH*8-1:C_PI_D_WIDTH*7] <=  PI_D[C_PI_D_WIDTH*8-1:C_PI_D_WIDTH*7];
         end
      end
   endgenerate

   // Instantiate OR Gate
     
   generate
      if (C_NUM_PORTS==1 && ((C_FAMILY=="virtex5") || (C_FAMILY=="virtex4") || (C_FAMILY == "virtex2p") || (C_FAMILY == "spartan3") || (C_FAMILY == "spartan3a") || (C_FAMILY == "spartan3e"))) begin : instantiate_or_for_1_port
         assign Q = pi_q_i[C_PI_D_WIDTH-1:0];
      end
      else if (C_NUM_PORTS==2 && ((C_FAMILY=="virtex5") || (C_FAMILY=="virtex4") || (C_FAMILY == "virtex2p") || (C_FAMILY == "spartan3") || (C_FAMILY == "spartan3a") || (C_FAMILY == "spartan3e"))) begin : instantiate_or_for_2_ports
         for (i=0;i<C_PI_D_WIDTH;i=i+1) begin : instantiate_or_for_2_ports_loop
            OR2 OR2_0
              (.O (Q[i]),
               .I0 (pi_q_i[i]),
               .I1 (pi_q_i[C_PI_D_WIDTH+i])
               );
         end
      end
      else if (C_NUM_PORTS==3 && ((C_FAMILY=="virtex5") || (C_FAMILY=="virtex4") || (C_FAMILY == "virtex2p") || (C_FAMILY == "spartan3") || (C_FAMILY == "spartan3a") || (C_FAMILY == "spartan3e"))) begin : instantiate_or_for_3_ports
         for (i=0;i<C_PI_D_WIDTH;i=i+1) begin : instantiate_or_for_3_ports_loop
            OR3 OR3_0
              (.O (Q[i]),
               .I0 (pi_q_i[i]),
               .I1 (pi_q_i[C_PI_D_WIDTH+i]),
               .I2 (pi_q_i[C_PI_D_WIDTH*2+i])
               );
         end
      end
      else if (C_NUM_PORTS==4 && ((C_FAMILY=="virtex5") || (C_FAMILY=="virtex4") || (C_FAMILY == "virtex2p") || (C_FAMILY == "spartan3") || (C_FAMILY == "spartan3a") || (C_FAMILY == "spartan3e"))) begin : instantiate_or_for_4_ports
         for (i=0;i<C_PI_D_WIDTH;i=i+1) begin : instantiate_or_for_4_ports_loop
            OR4 OR4_0
              (.O (Q[i]),
               .I0 (pi_q_i[i]),
               .I1 (pi_q_i[C_PI_D_WIDTH+i]),
               .I2 (pi_q_i[C_PI_D_WIDTH*2+i]),
               .I3 (pi_q_i[C_PI_D_WIDTH*3+i])
               );
         end
      end
      else if (C_NUM_PORTS==1) begin : instantiate_or_for_1_port
         assign
           Q = 
               pi_q_i[C_PI_D_WIDTH-1:0];
       end
      else if (C_NUM_PORTS==2) begin : instantiate_or_for_2_ports
         assign
           Q = 
               pi_q_i[C_PI_D_WIDTH-1:0] |
               pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH];
      end
      else if (C_NUM_PORTS==3) begin : instantiate_or_for_3_ports
         assign
           Q = 
               pi_q_i[C_PI_D_WIDTH-1:0] |
               pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] |
               pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2];
      end
      else if (C_NUM_PORTS==4) begin : instantiate_or_for_4_ports
         assign
           Q = 
               pi_q_i[C_PI_D_WIDTH-1:0] |
               pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] |
               pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2] | 
               pi_q_i[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3];
      end
      else if (C_NUM_PORTS==5) begin : instantiate_or_for_5_ports
         assign
           Q = 
               pi_q_i[C_PI_D_WIDTH-1:0] |
               pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] |
               pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2] | 
               pi_q_i[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3] |
               pi_q_i[C_PI_D_WIDTH*5-1:C_PI_D_WIDTH*4];
      end
      else if (C_NUM_PORTS==6) begin : instantiate_or_for_6_ports
         assign
           Q = 
               pi_q_i[C_PI_D_WIDTH-1:0] |
               pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] |
               pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2] | 
               pi_q_i[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3] |
               pi_q_i[C_PI_D_WIDTH*5-1:C_PI_D_WIDTH*4] |
               pi_q_i[C_PI_D_WIDTH*6-1:C_PI_D_WIDTH*5];
      end
      else if (C_NUM_PORTS==7) begin : instantiate_or_for_7_ports
         assign
           Q = 
               pi_q_i[C_PI_D_WIDTH-1:0] |
               pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] |
               pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2] | 
               pi_q_i[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3] |
               pi_q_i[C_PI_D_WIDTH*5-1:C_PI_D_WIDTH*4] |
               pi_q_i[C_PI_D_WIDTH*6-1:C_PI_D_WIDTH*5] |
               pi_q_i[C_PI_D_WIDTH*7-1:C_PI_D_WIDTH*6];
      end
      else if (C_NUM_PORTS==8) begin : instantiate_or_for_8_ports
         assign
           Q = 
               pi_q_i[C_PI_D_WIDTH-1:0] |
               pi_q_i[C_PI_D_WIDTH*2-1:C_PI_D_WIDTH] |
               pi_q_i[C_PI_D_WIDTH*3-1:C_PI_D_WIDTH*2] | 
               pi_q_i[C_PI_D_WIDTH*4-1:C_PI_D_WIDTH*3] |
               pi_q_i[C_PI_D_WIDTH*5-1:C_PI_D_WIDTH*4] |
               pi_q_i[C_PI_D_WIDTH*6-1:C_PI_D_WIDTH*5] |
               pi_q_i[C_PI_D_WIDTH*7-1:C_PI_D_WIDTH*6] |
               pi_q_i[C_PI_D_WIDTH*8-1:C_PI_D_WIDTH*7];
      end
   endgenerate

endmodule // high_priority_select

