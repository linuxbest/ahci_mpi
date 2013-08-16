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
// Description:       XCL Write Data Module
//   Pops data out of the access fifos and pushes data into the MPMC write fifos
// Verilog-standard:  Verilog 2001
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps
`default_nettype none

module xcl_write_data 
#(
  parameter C_PI_DATA_WIDTH         = 64,
  parameter C_PI_BE_WIDTH           = 8,
  parameter C_WRITEXFER             = 1,
  parameter C_LINESIZE              = 1
)
(
  input  wire                       Clk,
  input  wire                       Clk_MPMC,
  input  wire                       Rst,
  input  wire                       Clk_PI_Enable,
  output wire [C_PI_DATA_WIDTH-1:0] PI_WrFIFO_Data,
  output wire [C_PI_BE_WIDTH-1:0]   PI_WrFIFO_BE,
  output wire                       PI_WrFIFO_Push,
  input  wire                       PI_WrFIFO_AlmostFull,  
  output wire                       PI_WrFIFO_Flush,
  input  wire                       Access_Exists,
  input  wire                       Access_Control,
  input  wire [0:31]                Access_Data,
  output wire                       Access_REN_Write_Data,
  input  wire                       Write_Start,
  output reg                        Write_Done
);

  localparam                    P_ADR_WIDTH = (C_LINESIZE == 1) ? 1 :
                                              (C_LINESIZE == 4) ? 2 :  
                                              (C_LINESIZE == 8) ? 3 :  
                                                                  4 ;
  reg  [0:1]                    access_be_hold;
  reg  [0:1]                    access_data_d1;
  wire [0:C_PI_DATA_WIDTH-1]    pi_wrfifo_data_i;
  reg  [0:C_PI_BE_WIDTH-1]      pi_wrfifo_be_i;
  wire [C_PI_BE_WIDTH-1:0]      pi_wrfifo_be_i1;
  reg                           pi_wrfifo_push_i;
  reg  [3:0]                    wr_cnt;
  reg                           write_start_hold_i;
  wire                          write_start_hold;
  reg                           access_ren_write_data_i;
  genvar i;

  always @(posedge Clk)
    access_data_d1 <= Access_Data[30:31];

  // save the byte encoding that is fed in from the address 
  always @(posedge Clk)
    if (Rst)
      access_be_hold <= 0;
    else if (Write_Start)
      access_be_hold <= access_data_d1;

  // Wire Write Data
  assign pi_wrfifo_data_i[0:31] = Access_Data;

  // Generate Byte Enables
  always @(Access_Control or access_be_hold) 
    begin
      case ({Access_Control, access_be_hold})
        3'd0: pi_wrfifo_be_i <= 4'b1111;
        3'd1: pi_wrfifo_be_i <= 4'b1100;
        3'd2: pi_wrfifo_be_i <= 4'b0000; // Invalid Case
        3'd3: pi_wrfifo_be_i <= 4'b0011;
        3'd4: pi_wrfifo_be_i <= 4'b1000;
        3'd5: pi_wrfifo_be_i <= 4'b0100;
        3'd6: pi_wrfifo_be_i <= 4'b0010;
        3'd7: pi_wrfifo_be_i <= 4'b0001;
        default: begin 
          pi_wrfifo_be_i <= 4'b0000;    // Invalid Case
        end
      endcase
    end   

  // Check for invalid case during simulation
  // synopsys translate_off
  always @(posedge Clk)
  begin
    if (PI_WrFIFO_Push && PI_WrFIFO_BE == 4'h0)
      $display("%t : ERROR : %m : Invalid WrFIFO_BE combination during \
                WrFIFO_Push. Check Access_Control, Access_Data[30:31]", $time);
  end
  // synopsys translate_on
  //
  // Byte reordering within write data bus
  generate
    for (i = 0; i < C_PI_DATA_WIDTH; i = i + 8) begin : wrdata_reorder
      assign PI_WrFIFO_Data[i+7:i] = pi_wrfifo_data_i[i:i+7];
    end
  endgenerate

  // Bit reordering within byte enables
  generate
    for (i = 0; i < C_PI_BE_WIDTH; i = i + 1) begin : wrbe_reorder
      assign pi_wrfifo_be_i1[i] = pi_wrfifo_be_i[i];
    end
  endgenerate

  assign PI_WrFIFO_BE = (C_WRITEXFER == 1) ? pi_wrfifo_be_i1 
                                           : {C_PI_BE_WIDTH{1'b1}};

  generate 
    if ((C_WRITEXFER == 1) || (C_LINESIZE == 1)) begin : WORD_WRITE_DATA
      // hold the start signal in case access fifo is empty or wrfifo is full
      always @(posedge Clk_MPMC)
        if (Rst | PI_WrFIFO_Push)
          write_start_hold_i <= 0;
        else if (Write_Start)
          write_start_hold_i <= 1;

      // need to invalidate write_start_hold once we receive a Push
      assign write_start_hold = write_start_hold_i & ~PI_WrFIFO_Push;
       
      // Push the data out 
      always @(posedge Clk_MPMC)
        if (PI_WrFIFO_Push)
          pi_wrfifo_push_i <= 0;
        else if ((Write_Start | write_start_hold) 
                 & Clk_PI_Enable & Access_Exists)
          pi_wrfifo_push_i <= 1;
        else
          pi_wrfifo_push_i <= 0;

      assign PI_WrFIFO_Push = pi_wrfifo_push_i;
       
      // generate our done signal
      always @(posedge Clk)
        if ((Write_Start | write_start_hold) & Access_Exists)
          Write_Done <= 1;
        else
          Write_Done <= 0;

      // pop the fifo
      assign Access_REN_Write_Data = Write_Done; 
    end
    else begin : WRITEXFER_LINESIZE

      // Enable Writing
      always @(posedge Clk)
        if (Rst)
          write_start_hold_i <= 1'b0;
	else
	  write_start_hold_i <= ~Write_Done & (Write_Start | write_start_hold_i);

      assign write_start_hold = write_start_hold_i | Write_Start;

      // Push the data into the MPMC FIFO
      always @(posedge Clk_MPMC)
        pi_wrfifo_push_i <= (write_start_hold & Clk_PI_Enable & Access_Exists 
                             & ~PI_WrFIFO_AlmostFull & ~Write_Done);

      assign PI_WrFIFO_Push = pi_wrfifo_push_i & ~Write_Done;
         
      // Pop the data out of the accesss FIFO 
      always @(posedge Clk)  
        if (write_start_hold & Clk_PI_Enable & Access_Exists 
            & ~PI_WrFIFO_AlmostFull & ~Write_Done)
          access_ren_write_data_i <= 1;
        else
          access_ren_write_data_i <= 0;

      assign Access_REN_Write_Data = access_ren_write_data_i & ~Write_Done;

      // Count the number of writes
      always @(posedge Clk)
        if (Rst)
          wr_cnt <= 4'b0;
        else if (Access_REN_Write_Data)
          wr_cnt <= wr_cnt + 1'b1;
          
      always @(posedge Clk)
        if (& wr_cnt[0 +: P_ADR_WIDTH] & Access_REN_Write_Data)
          Write_Done <= 1;
        else
          Write_Done <= 0;
    end
    
  endgenerate
  // Tie off unused Signals
  assign PI_WrFIFO_Flush = 0;

endmodule // xcl_write_data

`default_nettype wire
