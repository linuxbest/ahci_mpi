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

module dualxcl_access
#(
///////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////
  parameter C_PI_A_SUBTYPE      = "DXCL2",      // Valid Values: IXCL, DXCL, 
                                                //   IXCL2, DXCL2, XCL
  parameter C_PI_B_SUBTYPE      = "INACTIVE",   // Valid Values: IXCL, DXCL
                                                //   IXCL2, DXCL2, XCL,
                                                //   INACTIVE
  parameter C_ADDR_MASK         = 32'h00000000, // Valid Values: Address MASK
  parameter C_PI_OFFSET         = 0,            // Valid Values: offset Address
  parameter C_PI_ADDR_WIDTH     = 32,           // Valid Values: 32
  parameter C_PI_DATA_WIDTH     = 32,           // Valid Values: 32
  parameter C_PI_BE_WIDTH       = 4,            // Valid Values: 4
  parameter C_XCL_A_WRITEXFER   = 1,            // Valid Values: 0, 1, 2
  parameter C_XCL_A_LINESIZE    = 8,            // Valid Values: 1, 4, 8, 16
  parameter C_XCL_B_WRITEXFER   = 1,            // Valid Values: 0, 1, 2
  parameter C_XCL_B_LINESIZE    = 8,            // Valid Values: 1, 4, 8, 16
  parameter C_MEM_DATA_WIDTH    = 8,            // Valid Values: 8, 16, 32, 64
  parameter C_ACCESS_FIFO_PIPE  = 0             // Valid Values: 0, 1
)
(
///////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////
  // System Signals
  input  wire                           Clk,
  input  wire                           Rst,
  // Access FSL_A
  input  wire                           FSL_A_M_Clk,
  input  wire                           FSL_A_M_Write,
  input  wire [0:31]                    FSL_A_M_Data,
  input  wire                           FSL_A_M_Control,
  output wire                           FSL_A_M_Full,

  // Access FSL_B
  input  wire                           FSL_B_M_Clk,
  input  wire                           FSL_B_M_Write,
  input  wire [0:31]                    FSL_B_M_Data,
  input  wire                           FSL_B_M_Control,
  output wire                           FSL_B_M_Full,

  // FSM Control Signals
  input  wire                           Addr_Sel_B,
  output wire [3:0]                     Addr_Sel_Target_Word,
  input  wire                           Data_Sel_B,
  input  wire                           Addr_Read_A,
  output wire                           Addr_RNW_A,
  output wire                           Addr_Exists_A,
  input  wire                           Data_Read_A,
  output wire                           Data_Wr_Burst_A,
  output wire                           Data_Wr_Burst_Early_A,
  output wire                           Data_Exists_A,
  output wire                           Data_Exists_Early_A,

  input  wire                           Addr_Read_B,
  output wire                           Addr_RNW_B,
  output wire                           Addr_Exists_B,
  input  wire                           Data_Read_B,
  output wire                           Data_Wr_Burst_B,
  output wire                           Data_Wr_Burst_Early_B,
  output wire                           Data_Exists_B,
  output wire                           Data_Exists_Early_B,

  // MPMC Port Interface
  output wire [C_PI_ADDR_WIDTH-1:0]     PI_Addr,
  output wire                           PI_RNW,
  output wire [3:0]                     PI_Size,
  output wire                           PI_RdModWr,
  output wire [C_PI_DATA_WIDTH-1:0]     PI_WrFIFO_Data,
  output wire [C_PI_BE_WIDTH-1:0]       PI_WrFIFO_BE
);

  wire [3:0]                            addr_target_word_a;
  wire [3:0]                            addr_target_word_b;
  wire [C_PI_ADDR_WIDTH-1:0]            pi_addr_a;
  wire [3:0]                            pi_size_a;
  wire [C_PI_DATA_WIDTH-1:0]            pi_wrfifo_data_a;
  wire [C_PI_BE_WIDTH-1:0]              pi_wrfifo_be_a;
  wire                                  pi_rdmodwr_a;
  wire [C_PI_ADDR_WIDTH-1:0]            pi_addr_b;
  wire [3:0]                            pi_size_b;
  wire [C_PI_DATA_WIDTH-1:0]            pi_wrfifo_data_b;
  wire [C_PI_BE_WIDTH-1:0]              pi_wrfifo_be_b;
  wire                                  pi_rdmodwr_b;

  dualxcl_access_data_path
  #(
    
    .C_XCL_LINESIZE         (C_XCL_A_LINESIZE),
    .C_XCL_WRITEXFER        (C_XCL_A_WRITEXFER),
    .C_PI_SUBTYPE           (C_PI_A_SUBTYPE),
    .C_ADDR_MASK            (C_ADDR_MASK),
    .C_PI_OFFSET            (C_PI_OFFSET),
    .C_PI_ADDR_WIDTH        (C_PI_ADDR_WIDTH),
    .C_PI_DATA_WIDTH        (C_PI_DATA_WIDTH),
    .C_PI_BE_WIDTH          (C_PI_BE_WIDTH),
    .C_MEM_DATA_WIDTH       (C_MEM_DATA_WIDTH),
    .C_ACCESS_FIFO_PIPE     (C_ACCESS_FIFO_PIPE)
  ) 
  dualxcl_access_data_path_a
  (
    .Clk                    (Clk),                          // I
    .Rst                    (Rst),                          // I
    .FSL_M_Clk              (FSL_A_M_Clk),                  // I
    .FSL_M_Write            (FSL_A_M_Write),                // I
    .FSL_M_Data             (FSL_A_M_Data),                 // I
    .FSL_M_Control          (FSL_A_M_Control),              // I
    .FSL_M_Full             (FSL_A_M_Full),                 // O
    .Addr_Read              (Addr_Read_A),                  // I
    .Addr_RNW               (Addr_RNW_A),                   // O
    .Addr_Exists            (Addr_Exists_A),                // O
    .Addr_Target_Word       (addr_target_word_a),           // O
    .Data_Read              (Data_Read_A),                  // I
    .Data_Wr_Burst          (Data_Wr_Burst_A),              // O
    .Data_Wr_Burst_Early    (Data_Wr_Burst_Early_A),        // O
    .Data_Exists            (Data_Exists_A),                // O
    .Data_Exists_Early      (Data_Exists_Early_A),                // O
    .PI_Addr                (pi_addr_a),                    // O
    .PI_RdModWr             (pi_rdmodwr_a),                 // O
    .PI_Size                (pi_size_a),                    // O
    .PI_WrFIFO_Data         (pi_wrfifo_data_a),             // O
    .PI_WrFIFO_BE           (pi_wrfifo_be_a)                // O
  );

  generate 
  if (C_PI_B_SUBTYPE != "INACTIVE")
  begin : XCL_B
      dualxcl_access_data_path
      #(
        
        .C_XCL_LINESIZE         (C_XCL_B_LINESIZE),
        .C_XCL_WRITEXFER        (C_XCL_B_WRITEXFER),
        .C_PI_SUBTYPE           (C_PI_B_SUBTYPE),
        .C_ADDR_MASK            (C_ADDR_MASK),
        .C_PI_OFFSET            (C_PI_OFFSET),
        .C_PI_ADDR_WIDTH        (C_PI_ADDR_WIDTH),
        .C_PI_DATA_WIDTH        (C_PI_DATA_WIDTH),
        .C_PI_BE_WIDTH          (C_PI_BE_WIDTH),
        .C_MEM_DATA_WIDTH       (C_MEM_DATA_WIDTH),
        .C_ACCESS_FIFO_PIPE     (C_ACCESS_FIFO_PIPE)
      ) 
      dualxcl_access_data_path_b
      (
        .Clk                    (Clk),                          // I
        .Rst                    (Rst),                          // I
        .FSL_M_Clk              (FSL_B_M_Clk),                  // I
        .FSL_M_Write            (FSL_B_M_Write),                // I
        .FSL_M_Data             (FSL_B_M_Data),                 // I
        .FSL_M_Control          (FSL_B_M_Control),              // I
        .FSL_M_Full             (FSL_B_M_Full),                 // O
        .Addr_Read              (Addr_Read_B),                  // I
        .Addr_RNW               (Addr_RNW_B),                   // O
        .Addr_Exists            (Addr_Exists_B),                // O
        .Addr_Target_Word       (addr_target_word_b),           // O
        .Data_Read              (Data_Read_B),                  // I
        .Data_Wr_Burst          (Data_Wr_Burst_B),              // O
        .Data_Wr_Burst_Early    (Data_Wr_Burst_Early_B),        // O
        .Data_Exists            (Data_Exists_B),                // O
        .Data_Exists_Early      (Data_Exists_Early_B),                // O
        .PI_Addr                (pi_addr_b),                    // O
        .PI_RdModWr             (pi_rdmodwr_b),                 // O
        .PI_Size                (pi_size_b),                    // O
        .PI_WrFIFO_Data         (pi_wrfifo_data_b),             // O
        .PI_WrFIFO_BE           (pi_wrfifo_be_b)                // O
      );
  end
  else 
  begin : NO_XCL_B
      // Tie-off outputs
      assign FSL_B_M_Full       = 1'b0;
      assign Addr_RNW_B         = 1'b0;
      assign Addr_Exists_B      = 1'b0;
      assign addr_target_word_b = 4'b0;
      assign Data_Wr_Burst_B    = 1'b0;
      assign Data_Wr_Burst_Early_B = 1'b0;
      assign Data_Exists_B      = 1'b0;
      assign Data_Exists_Early_B = 1'b0;
      assign pi_addr_b          = {C_PI_ADDR_WIDTH{1'b0}};
      assign pi_rdmodwr_b       = 1'b0;
      assign pi_size_b          = 4'b0;
      assign pi_wrfifo_data_b   = {C_PI_DATA_WIDTH{1'b0}};
      assign pi_wrfifo_be_b     = {C_PI_BE_WIDTH{1'b0}};
  end
  endgenerate



  // Mux outputs
  assign Addr_Sel_Target_Word = Addr_Sel_B ? addr_target_word_b 
                                           : addr_target_word_a; 
  assign PI_Addr        = Addr_Sel_B ? pi_addr_b : pi_addr_a;
  assign PI_RNW         = Addr_Sel_B ? Addr_RNW_B : Addr_RNW_A;
  assign PI_RdModWr     = Addr_Sel_B ? pi_rdmodwr_b : pi_rdmodwr_a;
  assign PI_Size        = Addr_Sel_B ? pi_size_b : pi_size_a;

  assign PI_WrFIFO_Data = Data_Sel_B ? pi_wrfifo_data_b : pi_wrfifo_data_a;
  assign PI_WrFIFO_BE   = Data_Sel_B ? pi_wrfifo_be_b : pi_wrfifo_be_a;

  

endmodule // dualxcl_access

`default_nettype wire
