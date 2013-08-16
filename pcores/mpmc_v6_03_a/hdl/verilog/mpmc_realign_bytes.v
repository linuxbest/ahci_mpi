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
// Filename:          mpmc_realign_bytes.v
// Version:           1.00.a
// Description:       This module takes the read data outputs of the phy and 
//                    ensures that the bytes are realigned such that the entire
//                    data can be pushed into the data path.  It uses the delay
//                    values of each byte to do this.  This module only will
//                    correct for up to 1 cycle of difference between byte
//                    lanes.
//                    NOTE: There is a 2 cycle delay between the time that the 
//                    Data_Delay is valid and the Data_Out holds the correct 
//                    valid.  Since Data_Delay is fixed during initialization 
//                    this should not be a problem.
// Verilog Standard:  Verilog-2001
//----------------------------------------------------------------------------
// Naming Conventions:
//   active low signals:                    "*_n"
//   clock signals:                         "clk", "clk_div#", "clk_#x"
//   reset signals:                         "rst", "rst_n"
//   generics:                              "C_*"
//   user defined types:                    "*_TYPE"
//   state machine next state:              "*_ns"
//   state machine current state:           "*_cs"
//   combinatorial signals:                 "*_com"
//   pipelined or register delay signals:   "*_d#"
//   counter signals:                       "*cnt*"
//   clock enable signals:                  "*_ce"
//   internal version of output port:       "*_i"
//   device pins:                           "*_pin"
//   ports:                                 "- Names begin with Uppercase"
//   processes:                             "*_PROCESS"
//----------------------------------------------------------------------------

`timescale 1ns/1ns
`default_nettype none

module mpmc_realign_bytes #
  (
   parameter C_IS_DDR      = 1,
   parameter C_DATA_WIDTH  = 128,
   parameter C_DELAY_WIDTH = 4
  )
  (
   input  wire                                                 Clk,
   input  wire [C_DATA_WIDTH/8*C_DELAY_WIDTH/(C_IS_DDR+1)-1:0] Data_Delay,
   input  wire [C_DATA_WIDTH-1:0]                              Data_In,
   output wire [C_DATA_WIDTH-1:0]                              Data_Out,
   input  wire [C_DATA_WIDTH/8/(C_IS_DDR+1)-1:0]               Push_In,
   output wire [C_DATA_WIDTH/8/(C_IS_DDR+1)-1:0]               Push_Out
   );

  reg [C_DATA_WIDTH/8*C_DELAY_WIDTH/(C_IS_DDR+1)-1:0] data_delay_d1;
  reg [C_DATA_WIDTH-1:0]                              data_in_d1;
  reg [C_DATA_WIDTH/8/(C_IS_DDR+1)-1:0]               push_in_d1;
  reg [C_DATA_WIDTH/8/(C_IS_DDR+1)-1:0]               needs_delay;
  
  genvar i;
  genvar j;

  // Register Data_Delay to improve timing
  always @(posedge Clk) begin
    data_delay_d1 <= Data_Delay;
  end

  // Create a registered version of the data and the push signal
  always @(posedge Clk) begin
    data_in_d1 <= Data_In;
    push_in_d1 <= Push_In;
  end
  
  generate
    for (i=0;i<C_DATA_WIDTH/8/(C_IS_DDR+1);i=i+1) begin : gen_data_out
      wire [C_DATA_WIDTH/8/(C_IS_DDR+1)-1:0] delay_compare;
      // Compare delay values for each byte.
      for (j=0;j<C_DATA_WIDTH/8/(C_IS_DDR+1);j=j+1) begin : gen_comp
        assign delay_compare[j] = 
                (data_delay_d1[(i+1)*C_DELAY_WIDTH-1:i*C_DELAY_WIDTH] <
                 data_delay_d1[(j+1)*C_DELAY_WIDTH-1:j*C_DELAY_WIDTH]) ? 1'b1 :
                                                                         1'b0;
      end
      // Use the compare logic to determine if the data and push signal needs
      // to be delayed.
      always @(posedge Clk) begin
        needs_delay[i] <= (| delay_compare);
      end
      // Re-assemble the data so that it is aligned
      assign Data_Out[(i+1)*8-1:i*8] = needs_delay[i] ? 
                                       data_in_d1[(i+1)*8-1:i*8] : 
                                       Data_In[(i+1)*8-1:i*8];
      if (C_IS_DDR==1) begin : gen_data_out_upper
        assign Data_Out[(i+1)*8+C_DATA_WIDTH/2-1:i*8+C_DATA_WIDTH/2] = 
                     needs_delay[i] ? 
                     data_in_d1[(i+1)*8+C_DATA_WIDTH/2-1:i*8+C_DATA_WIDTH/2] : 
                     Data_In[(i+1)*8+C_DATA_WIDTH/2-1:i*8+C_DATA_WIDTH/2];
      end
      // Figure out when Data_Out is valid and assign the push signal
      assign Push_Out[i] = needs_delay[i] ? push_in_d1[i] : Push_In[i];
    end
  endgenerate

endmodule   

`default_nettype wire
