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

`timescale 1ns/100ps
`default_nettype none

module dualxcl_read
#(
  parameter C_PI_A_SUBTYPE              = "XCL",    // Valid Values: IXCL, IXCL2
                                                    // DXCL, DXCL2, XCL
  parameter C_PI_B_SUBTYPE              = "INACTIVE", // Valid Values: INACTIVE,
                                                    // IXCL, IXCL2, DXCL,
                                                    // DXCL2, XCL
  parameter C_PI_DATA_WIDTH             = 32,   // Valid Values: 32
  parameter C_PI_RDWDADDR_WIDTH         = 4,    // Valid Values: 4
  parameter C_PI_RDDATA_DELAY           = 0,    // Valid Values: 0, 1, 2
  parameter C_XCL_A_LINESIZE            = 4,    // Valid Values: 1, 4, 8, 16
  parameter C_XCL_B_LINESIZE            = 4,    // Valid Values: 1, 4, 8, 16
  parameter C_MEM_SDR_DATA_WIDTH        = 8,    // Valid Values: 8, 16, 32, 64, 
                                                // 128
  parameter C_READ_FIFO_PIPE            = 1,    // Valid Values: 0, 1
  parameter C_RDFIFO_EMPTY_PIPE         = 0,    // Valid Values: 0, 1
  parameter C_MAX_CNTR_WIDTH            = 4     // Valid Values: 1, 2, 3, 4
)
(
  input  wire                           Clk,
  input  wire                           Clk_MPMC,
  input  wire                           Rst,
  input  wire                           Clk_PI_Enable,

  // FSL Ports
  output wire                           FSL_A_S_Exists,
  output wire                           FSL_A_S_Control,
  output wire [0:31]                    FSL_A_S_Data,
  input  wire                           FSL_A_S_Read,

  output wire                           FSL_B_S_Exists,
  output wire                           FSL_B_S_Control,
  output wire [0:31]                    FSL_B_S_Data,
  input  wire                           FSL_B_S_Read,

  // Control Signals
  input  wire                           Addr_Sel_B,
  input  wire                           Addr_Sel_Push,
  input  wire [3:0]                     Addr_Sel_Target_Word,
  output wire                           Addr_Sel_FIFO_Full,

  input  wire [C_PI_DATA_WIDTH-1:0]     PI_RdFIFO_Data,
  output wire                           PI_RdFIFO_Pop,
  input  wire                           PI_RdFIFO_Empty,
  input  wire [C_PI_RDWDADDR_WIDTH-1:0] PI_RdFIFO_RdWdAddr,
  output wire                           PI_RdFIFO_Flush

);

  localparam P_NO_TARGET_WORD            = (C_PI_A_SUBTYPE == "IXCL2" 
                                           || C_PI_A_SUBTYPE == "DXCL2")
                                          && (C_PI_B_SUBTYPE == "IXCL2"
                                              || C_PI_B_SUBTYPE == "DXCL2"
                                              || C_PI_B_SUBTYPE == "INACTIVE");

  localparam P_DUAL_XCL                  = (C_PI_B_SUBTYPE != "INACTIVE");

  localparam P_FIFO_WIDTH                = (P_NO_TARGET_WORD && !P_DUAL_XCL) ? 0
                                          : (P_NO_TARGET_WORD && P_DUAL_XCL) ? 1
                                          : (!P_NO_TARGET_WORD && !P_DUAL_XCL) 
                                          ? C_MAX_CNTR_WIDTH
                                          : C_MAX_CNTR_WIDTH + 1;
                                          


  // inputs to the xcl_read_data from fifo
  // inputs to the xcl_read_data from fifo
  wire [3:0]                            target_word_out;
  wire                                  addr_sel_b_out;
  wire                                  read_start;

  // outputs of the xcl_read_data
  wire                                  read_done_a;
  wire                                  read_done_b;
  wire                                  read_done;
  reg                                   read_done_d1;
  wire                                  pi_rdfifo_pop_a;
  wire                                  pi_rdfifo_pop_b;


  // Instantiate a 4 deep fifo to contain both the target word first and the 
  // port expecting the next set of read data.  Reduce the size of the FIFO if 
  // port B does not exist or if we don't have a target word first.
  generate
  if (P_FIFO_WIDTH > 0)
  begin : FIFO

    wire                                read_done_i;
    wire [4:0]                          fifo_input;    
    wire [4:0]                          fifo_output_i;
    wire                                fifo_empty_i;
    wire                                fifo_almost_full;
    wire                                fifo_full;
    wire                                read_sel_fifo_empty;
    reg                                 read_sel_fifo_empty_d1;

    wire [4:0]                          fifo_output;   

    assign fifo_input[0 +: P_FIFO_WIDTH] 
                        = (P_NO_TARGET_WORD && P_DUAL_XCL) ? Addr_Sel_B
                        : (!P_NO_TARGET_WORD && !P_DUAL_XCL) 
                        ? Addr_Sel_Target_Word[0 +: C_MAX_CNTR_WIDTH]
                        : {Addr_Sel_Target_Word[0 +: C_MAX_CNTR_WIDTH], 
                           Addr_Sel_B};

    srl16e_fifo_protect
    #(
      .c_width    (P_FIFO_WIDTH),
      .c_awidth   (2),
      .c_depth    (4)
    )
    read_sel_fifo
    (
      .Clk        (Clk),                                // I
      .Rst        (Rst),                                // I
      .WR_EN      (Addr_Sel_Push),                      // I
      .RD_EN      (read_done_i),                        // I
      .DIN        (fifo_input[0 +: P_FIFO_WIDTH]),      // I
      .DOUT       (fifo_output_i[ 0 +: P_FIFO_WIDTH]),  // O
      .ALMOST_FULL(fifo_almost_full),                   // O
      .FULL       (fifo_full),                          // O
      .ALMOST_EMPTY(),                                  // O
      .EMPTY      (fifo_empty_i)                        // O
    );

    assign Addr_Sel_FIFO_Full = fifo_almost_full | fifo_full;

    fifo_pipeline
    #(
      .C_DWIDTH       (P_FIFO_WIDTH),
      .C_INV_EXISTS   (1)
    )
    addr_fifo_pipe
    (
      .Clk            (Clk),
      .Rst            (Rst),
      .FIFO_Exists    (fifo_empty_i),
      .FIFO_Read      (read_done_i),
      .FIFO_Data      (fifo_output_i[0 +: P_FIFO_WIDTH]),
      .PIPE_Exists    (read_sel_fifo_empty),
      .PIPE_Read      (read_done_a | read_done_b),
      .PIPE_Data      (fifo_output[0 +: P_FIFO_WIDTH])
    );

    always @(posedge Clk)
      read_sel_fifo_empty_d1 <= read_sel_fifo_empty;

    assign target_word_out = (P_NO_TARGET_WORD) ? 4'b0 
                             : (C_MAX_CNTR_WIDTH < 4) 
                             ? {{4-C_MAX_CNTR_WIDTH{1'b0}},
                                fifo_output[P_DUAL_XCL +: C_MAX_CNTR_WIDTH]}
                             : fifo_output[P_DUAL_XCL +: C_MAX_CNTR_WIDTH];

    assign addr_sel_b_out = (!P_DUAL_XCL) ? 1'b0 : fifo_output[0];

    assign read_start = (~read_sel_fifo_empty & read_sel_fifo_empty_d1)
                        | (~read_sel_fifo_empty & read_done_d1);
  end
  else
  begin : NO_FIFO
    reg rst_d1;

    always @(posedge Clk)
      rst_d1 <= Rst;

    assign target_word_out = 4'b0;
    assign addr_sel_b_out = 1'b0;
    assign read_start = rst_d1 | read_done_d1;
    assign Addr_Sel_FIFO_Full = 1'b0;
  end
  endgenerate





  xcl_read_data #(
    .C_PI_SUBTYPE           (C_PI_A_SUBTYPE),
    .C_PI_DATA_WIDTH        (C_PI_DATA_WIDTH),
    .C_PI_RDWDADDR_WIDTH    (C_PI_RDWDADDR_WIDTH),
    .C_PI_RDDATA_DELAY      (C_PI_RDDATA_DELAY),
    .C_LINESIZE             (C_XCL_A_LINESIZE),
    .C_MEM_SDR_DATA_WIDTH   (C_MEM_SDR_DATA_WIDTH),
    .C_READ_FIFO_PIPE       (C_READ_FIFO_PIPE),
    .C_RDFIFO_EMPTY_PIPE    (C_RDFIFO_EMPTY_PIPE)
  ) 
  xcl_read_data_a (
    .Clk                (Clk),                      // I
    .Clk_MPMC           (Clk_MPMC),                 // I
    .Rst                (Rst),                      // I
    .Clk_PI_Enable      (Clk_PI_Enable),            // I
    .PI_RdFIFO_Data     (PI_RdFIFO_Data),           // I
    .PI_RdFIFO_Pop      (pi_rdfifo_pop_a),          // O
    .PI_RdFIFO_RdWdAddr (PI_RdFIFO_RdWdAddr),       // I
    .PI_RdFIFO_Empty    (PI_RdFIFO_Empty),          // I 
    .PI_RdFIFO_Flush    (),          // O
    .Target_Word        (target_word_out),          // I 
    .Read_Data_Exists   (FSL_A_S_Exists),           // O
    .Read_Data_Control  (FSL_A_S_Control),          // O
    .Read_Data          (FSL_A_S_Data),             // O
    .Read_Data_Read     (FSL_A_S_Read),             // I
    .Read_Start         (read_start & ~addr_sel_b_out),// I
    .Read_Done          (read_done_a)               // O
  );

  generate 
  if (C_PI_B_SUBTYPE != "INACTIVE")
  begin : XCL_B
  xcl_read_data #(
    .C_PI_SUBTYPE           (C_PI_B_SUBTYPE),
    .C_PI_DATA_WIDTH        (C_PI_DATA_WIDTH),
    .C_PI_RDWDADDR_WIDTH    (C_PI_RDWDADDR_WIDTH),
    .C_PI_RDDATA_DELAY      (C_PI_RDDATA_DELAY),
    .C_LINESIZE             (C_XCL_B_LINESIZE),
    .C_MEM_SDR_DATA_WIDTH   (C_MEM_SDR_DATA_WIDTH),
    .C_READ_FIFO_PIPE       (C_READ_FIFO_PIPE),
    .C_RDFIFO_EMPTY_PIPE    (C_RDFIFO_EMPTY_PIPE)
  ) 
  xcl_read_data_b (
    .Clk                (Clk),                      // I
    .Clk_MPMC           (Clk_MPMC),                 // I
    .Rst                (Rst),                      // I
    .Clk_PI_Enable      (Clk_PI_Enable),            // I
    .PI_RdFIFO_Data     (PI_RdFIFO_Data),           // I
    .PI_RdFIFO_Pop      (pi_rdfifo_pop_b),          // O
    .PI_RdFIFO_RdWdAddr (PI_RdFIFO_RdWdAddr),       // I
    .PI_RdFIFO_Empty    (PI_RdFIFO_Empty),          // I 
    .PI_RdFIFO_Flush    (PI_RdFIFO_Flush),          // O
    .Target_Word        (target_word_out),          // I 
    .Read_Data_Exists   (FSL_B_S_Exists),           // O
    .Read_Data_Control  (FSL_B_S_Control),          // O
    .Read_Data          (FSL_B_S_Data),             // O
    .Read_Data_Read     (FSL_B_S_Read),             // I
    .Read_Start         (read_start & addr_sel_b_out),// I
    .Read_Done          (read_done_b)               // O
  );
  end
  else
  begin : NO_XCL_B
      assign pi_rdfifo_pop_b = 1'b0;
      assign PI_RdFIFO_Flush = 1'b0;
      assign FSL_B_S_Exists  = 1'b0;
      assign FSL_B_S_Control = 1'b0;
      assign FSL_B_S_Data    = 32'b0;
      assign read_done_b     = 1'b0;
  end
  endgenerate

  assign PI_RdFIFO_Pop = pi_rdfifo_pop_b | pi_rdfifo_pop_a;
      
  assign read_done = read_done_a | read_done_b;

  always @(posedge Clk)
    read_done_d1 <= read_done;


endmodule // dualxcl_read_data

`default_nettype wire
