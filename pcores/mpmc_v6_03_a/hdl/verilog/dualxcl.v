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
// Description: Dual XCL MPMC PIM
// Structure:
//  --dual_xcl
//    --sample_cycle_0
//    --dualxcl_access_0
//      --dualxcl_access_data_path_a
//        --access_fifo
//        --access_addr (fifo_pipeline)
//        --access_data (fifo_pipeline)
//      --dualxcl_access_data_path_b
//        --access_fifo
//        --access_addr (fifo_pipeline)
//        --access_data (fifo_pipeline)
//    --dualxcl_fsm_0
//    --dualxcl_read_0
//
// Verilog-standard:  Verilog 2001
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps
`default_nettype none

module dualxcl
#(
  parameter C_FAMILY                    = "virtex5",
///////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////
  parameter C_PI_A_SUBTYPE              = "DXCL2", // Valid Values: IXCL, DXCL,
                                                   //   IXCL2, DXCL2
  parameter C_PI_B_SUBTYPE              = "INACTIVE", // Valid Values: IXCL,
                                                // DXCL, IXCL2, DXCL2, INACTIVE
  parameter C_PI_BASEADDR               = 32'h00000000, // Valid address 
  parameter C_PI_HIGHADDR               = 32'h00000000, // Valid address 
  parameter C_PI_OFFSET                 = 0,    // Valid Values: offset Address
  parameter C_PI_ADDR_WIDTH             = 32,   // Valid Values: 32
  parameter C_PI_DATA_WIDTH             = 32,   // Valid Values: 32
  parameter C_PI_BE_WIDTH               = 4,    // Valid Values: 4
  parameter C_PI_RDWDADDR_WIDTH         = 4,    // Valid Values: 4
  parameter C_PI_RDDATA_DELAY           = 0,    // Valid Values: 0, 1, 2
  parameter C_XCL_A_WRITEXFER           = 1,    // Valid Values: 0, 1, 2
  parameter C_XCL_A_LINESIZE            = 8,    // Valid Values: 1, 4, 8, 16
  parameter C_XCL_B_WRITEXFER           = 1,    // Valid Values: 0, 1, 2
  parameter C_XCL_B_LINESIZE            = 8,    // Valid Values: 1, 4, 8, 16
  parameter C_XCL_PIPE_STAGES           = 3,    // Valid Values: 0, 1, 2, 3?
  parameter C_MEM_DATA_WIDTH            = 8,    // Valid Values: 8,16,32,64
  parameter C_MEM_SDR_DATA_WIDTH        = 8     // Valid Values: 8,16,32,64,128
)
(
///////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////
  // System Signals
  input  wire                           Clk,
  input  wire                           Clk_MPMC,
  input  wire                           Rst,
  // Access FSL A
  input  wire                           FSL_A_M_Clk,
  input  wire                           FSL_A_M_Write,
  input  wire [0:31]                    FSL_A_M_Data,
  input  wire                           FSL_A_M_Control,
  output wire                           FSL_A_M_Full,
  // Read Data FSL A
  input  wire                           FSL_A_S_Clk,
  input  wire                           FSL_A_S_Read,
  output wire [0:31]                    FSL_A_S_Data,
  output wire                           FSL_A_S_Control,
  output wire                           FSL_A_S_Exists,
  // Access FSL B
  input  wire                           FSL_B_M_Clk,
  input  wire                           FSL_B_M_Write,
  input  wire [0:31]                    FSL_B_M_Data,
  input  wire                           FSL_B_M_Control,
  output wire                           FSL_B_M_Full,
  // Read Data FSL B
  input  wire                           FSL_B_S_Clk,
  input  wire                           FSL_B_S_Read,
  output wire [0:31]                    FSL_B_S_Data,
  output wire                           FSL_B_S_Control,
  output wire                           FSL_B_S_Exists,

  // MPMC Port Interface
  output wire [C_PI_ADDR_WIDTH-1:0]     PI_Addr,
  output wire                           PI_AddrReq,
  input  wire                           PI_AddrAck,
  output wire                           PI_RNW,
  output wire                           PI_RdModWr,
  output wire [3:0]                     PI_Size,
  input  wire                           PI_InitDone,
  output wire [C_PI_DATA_WIDTH-1:0]     PI_WrFIFO_Data,
  output wire [C_PI_BE_WIDTH-1:0]       PI_WrFIFO_BE,
  output wire                           PI_WrFIFO_Push,
  input  wire [C_PI_DATA_WIDTH-1:0]     PI_RdFIFO_Data,
  output wire                           PI_RdFIFO_Pop,
  input  wire [C_PI_RDWDADDR_WIDTH-1:0] PI_RdFIFO_RdWdAddr,
  input  wire                           PI_WrFIFO_AlmostFull,
  output wire                           PI_WrFIFO_Flush,
  input  wire                           PI_RdFIFO_Empty,
  output wire                           PI_RdFIFO_Flush
);

///////////////////////////////////////////////////////////////////////////
// Local Params and Wires
///////////////////////////////////////////////////////////////////////////
  localparam  P_ALLOW_PIPELINES      =  (C_FAMILY == "spartan3a") || 
                                        (C_FAMILY == "spartan3e") || 
                                        (C_FAMILY == "spartan3")  || 
                                        (C_FAMILY == "virtex4")   || 
                                        (C_FAMILY == "virtex5")   || 
                                        (C_FAMILY == "virtex6");
  
  localparam  P_ACCESS_FIFO_PIPE     = (P_ALLOW_PIPELINES == 1) ? (C_XCL_PIPE_STAGES >= 3) : 0;
  localparam  P_RDFIFO_EMPTY_PIPE    = (P_ALLOW_PIPELINES == 1) ? (C_XCL_PIPE_STAGES >= 2) : 0;
  localparam  P_READ_FIFO_PIPE       = (P_ALLOW_PIPELINES == 1) ? (C_XCL_PIPE_STAGES >= 1) : 0;
  localparam  P_XCL_A_WRITEXFER      = (C_PI_A_SUBTYPE == "IXCL")  ? 0 : 
                                       (C_PI_A_SUBTYPE == "IXCL2") ? 0 : 
                                       (C_PI_A_SUBTYPE == "DXCL")  ? 1 : 
                                       (C_PI_A_SUBTYPE == "DXCL2") ? 1 
                                       : C_XCL_A_WRITEXFER;
  localparam  P_XCL_B_WRITEXFER      = (C_PI_B_SUBTYPE == "IXCL")  ? 0 : 
                                       (C_PI_B_SUBTYPE == "IXCL2") ? 0 : 
                                       (C_PI_B_SUBTYPE == "DXCL")  ? 1 : 
                                       (C_PI_B_SUBTYPE == "DXCL2") ? 1 
                                       : C_XCL_B_WRITEXFER;
  localparam   P_CNT_WIDTH_A        = (C_XCL_A_LINESIZE == 1) ?  1 :
                                      (C_XCL_A_LINESIZE == 4) ?  2 :
                                      (C_XCL_A_LINESIZE == 8) ?  3 : 4;

  localparam   P_CNT_WIDTH_B        = (C_XCL_B_LINESIZE == 1) ?  1 :
                                      (C_XCL_B_LINESIZE == 4) ?  2 :
                                      (C_XCL_B_LINESIZE == 8) ?  3 : 4;

  // P_MAX_CNTR_WIDTH Calculates the width of our counters and addresses for 
  // fixed length reads
  localparam   P_MAX_CNTR_WIDTH     = (C_XCL_B_LINESIZE > C_XCL_A_LINESIZE &&
                                    C_PI_B_SUBTYPE != "INACTIVE")
                                    ? P_CNT_WIDTH_B : P_CNT_WIDTH_A;

  localparam   P_ADDR_MASK          = C_PI_BASEADDR ^ C_PI_HIGHADDR;

  wire                  clk_pi_enable;
  reg                   addrack_hold;
  reg                   wrfifo_mask;
  wire                  pi_addrack_slowclk;
  wire                  pi_addrreq_slowclk;
  wire                  pi_wrfifo_push_slowclk;

  wire                  addr_sel_b;
  wire                  addr_sel_push;
  wire [3:0]            addr_sel_target_word;
  wire                  addr_sel_fifo_full;
  wire                  data_sel_b;

  wire                  addr_read_a;
  wire                  addr_rnw_a;
  wire                  addr_exists_a;
  wire                  data_read_a;
  wire                  data_wr_burst_a;
  wire                  data_wr_burst_early_a;
  wire                  data_exists_a;
  wire                  data_exists_early_a;

  wire                  addr_read_b;
  wire                  addr_rnw_b;
  wire                  addr_exists_b;
  wire                  data_read_b;
  wire                  data_wr_burst_b;
  wire                  data_wr_burst_early_b;
  wire                  data_exists_b;
  wire                  data_exists_early_b;

  assign PI_WrFIFO_Flush = 1'b0;

///////////////////////////////////////////////////////////////////////////
// Handle Clocking Boundaries
///////////////////////////////////////////////////////////////////////////
  mpmc_sample_cycle
    sample_cycle_0 (
      .sample_cycle(clk_pi_enable),
      .slow_clk(Clk),
      .fast_clk(Clk_MPMC)
  );

  always @(posedge Clk_MPMC)
    if (clk_pi_enable)
      addrack_hold <= 1'b0;
    else
      addrack_hold <= PI_AddrAck;

  always @(posedge Clk_MPMC)
    if (clk_pi_enable)
      wrfifo_mask <= 1'b0;
    else
      wrfifo_mask <= pi_wrfifo_push_slowclk;

  assign pi_addrack_slowclk = addrack_hold | PI_AddrAck;  // mpmc -> xcl clk
  assign PI_AddrReq = pi_addrreq_slowclk & ~addrack_hold;  // xcl -> mpmc
  assign PI_WrFIFO_Push = pi_wrfifo_push_slowclk & ~wrfifo_mask; // xcl -> mpmc

///////////////////////////////////////////////////////////////////////////
// Instantiate Modules
///////////////////////////////////////////////////////////////////////////
  dualxcl_access
  #(
    .C_PI_A_SUBTYPE             (C_PI_A_SUBTYPE),
    .C_PI_B_SUBTYPE             (C_PI_B_SUBTYPE),
    .C_ADDR_MASK                (P_ADDR_MASK),
    .C_PI_OFFSET                (C_PI_OFFSET),
    .C_PI_ADDR_WIDTH            (C_PI_ADDR_WIDTH),
    .C_PI_DATA_WIDTH            (C_PI_DATA_WIDTH),
    .C_PI_BE_WIDTH              (C_PI_BE_WIDTH),
    .C_XCL_A_WRITEXFER          (P_XCL_A_WRITEXFER),
    .C_XCL_A_LINESIZE           (C_XCL_A_LINESIZE),
    .C_XCL_B_WRITEXFER          (P_XCL_B_WRITEXFER),
    .C_XCL_B_LINESIZE           (C_XCL_B_LINESIZE),
    .C_MEM_DATA_WIDTH           (C_MEM_DATA_WIDTH),
    .C_ACCESS_FIFO_PIPE         (P_ACCESS_FIFO_PIPE)

  )
  dualxcl_access_0
  (
    .Clk                        (Clk),                  // I
    .Rst                        (Rst),                  // I
    .FSL_A_M_Clk                (FSL_A_M_Clk),          // I
    .FSL_A_M_Write              (FSL_A_M_Write),        // I
    .FSL_A_M_Data               (FSL_A_M_Data),         // I
    .FSL_A_M_Control            (FSL_A_M_Control),      // I
    .FSL_A_M_Full               (FSL_A_M_Full),         // O
    .FSL_B_M_Clk                (FSL_B_M_Clk),          // I
    .FSL_B_M_Write              (FSL_B_M_Write),        // I
    .FSL_B_M_Data               (FSL_B_M_Data),         // I
    .FSL_B_M_Control            (FSL_B_M_Control),      // I
    .FSL_B_M_Full               (FSL_B_M_Full),         // O
    .Addr_Sel_B                 (addr_sel_b),           // I
    .Addr_Sel_Target_Word       (addr_sel_target_word), // O
    .Data_Sel_B                 (data_sel_b),           // I
    .Addr_Read_A                (addr_read_a),          // I
    .Addr_RNW_A                 (addr_rnw_a),           // O
    .Addr_Exists_A              (addr_exists_a),        // O
    .Data_Read_A                (data_read_a),          // I
    .Data_Wr_Burst_A            (data_wr_burst_a),      // O
    .Data_Wr_Burst_Early_A      (data_wr_burst_early_a),// O
    .Data_Exists_A              (data_exists_a),        // O
    .Data_Exists_Early_A        (data_exists_early_a),  // O
    .Addr_Read_B                (addr_read_b),          // I
    .Addr_RNW_B                 (addr_rnw_b),           // O
    .Addr_Exists_B              (addr_exists_b),        // O
    .Data_Read_B                (data_read_b),          // I
    .Data_Wr_Burst_B            (data_wr_burst_b),      // O
    .Data_Wr_Burst_Early_B      (data_wr_burst_early_b),// O
    .Data_Exists_B              (data_exists_b),        // O
    .Data_Exists_Early_B        (data_exists_early_b),        // O
    .PI_Addr                    (PI_Addr),              // O
    .PI_RNW                     (PI_RNW),               // O
    .PI_RdModWr                 (PI_RdModWr),           // O
    .PI_Size                    (PI_Size),              // O
    .PI_WrFIFO_Data             (PI_WrFIFO_Data),       // O
    .PI_WrFIFO_BE               (PI_WrFIFO_BE)          // O
  );

  dualxcl_fsm
  #(
    .C_PI_A_SUBTYPE             (C_PI_A_SUBTYPE),
    .C_PI_B_SUBTYPE             (C_PI_B_SUBTYPE),
    .C_XCL_A_WRITEXFER          (P_XCL_A_WRITEXFER),
    .C_XCL_B_WRITEXFER          (P_XCL_B_WRITEXFER),
    .C_XCL_A_LINESIZE           (C_XCL_A_LINESIZE),
    .C_XCL_B_LINESIZE           (C_XCL_B_LINESIZE),
    .C_MAX_CNTR_WIDTH           (P_MAX_CNTR_WIDTH)
  )
  dualxcl_fsm_0
  (
    .Clk                        (Clk),                      // I
    .Rst                        (Rst),                      // I
    .Addr_Sel_Push              (addr_sel_push),            // O
    .Addr_Sel_B                 (addr_sel_b),               // O
    .Data_Sel_B                 (data_sel_b),               // O
    .Addr_Read_A                (addr_read_a),              // O
    .Addr_RNW_A                 (addr_rnw_a),               // I
    .Addr_Exists_A              (addr_exists_a),            // I
    .Data_Read_A                (data_read_a),              // O
    .Data_Wr_Burst_A            (data_wr_burst_a),          // I
    .Data_Wr_Burst_Early_A      (data_wr_burst_early_a),    // I
    .Data_Exists_A              (data_exists_a),            // I
    .Data_Exists_Early_A        (data_exists_early_a),            // I
    .Addr_Read_B                (addr_read_b),              // O
    .Addr_RNW_B                 (addr_rnw_b),               // I
    .Addr_Exists_B              (addr_exists_b),            // I
    .Addr_Sel_FIFO_Full         (addr_sel_fifo_full),       // O
    .Data_Read_B                (data_read_b),              // O
    .Data_Wr_Burst_B            (data_wr_burst_b),          // I
    .Data_Wr_Burst_Early_B      (data_wr_burst_early_b),    // I
    .Data_Exists_B              (data_exists_b),            // I
    .Data_Exists_Early_B        (data_exists_early_b),      // I
    .PI_InitDone                (PI_InitDone),              // I
    .PI_AddrAck                 (pi_addrack_slowclk),       // I
    .PI_AddrReq                 (pi_addrreq_slowclk),       // O
    .PI_WrFIFO_AlmostFull       (PI_WrFIFO_AlmostFull),     // I
    .PI_WrFIFO_Push             (pi_wrfifo_push_slowclk)    // O
  );




  dualxcl_read
  #(
    .C_PI_A_SUBTYPE             (C_PI_A_SUBTYPE),
    .C_PI_B_SUBTYPE             (C_PI_B_SUBTYPE),
    .C_PI_DATA_WIDTH            (C_PI_DATA_WIDTH),
    .C_PI_RDWDADDR_WIDTH        (C_PI_RDWDADDR_WIDTH),
    .C_PI_RDDATA_DELAY          (C_PI_RDDATA_DELAY),
    .C_XCL_A_LINESIZE           (C_XCL_A_LINESIZE),
    .C_XCL_B_LINESIZE           (C_XCL_B_LINESIZE),
    .C_MEM_SDR_DATA_WIDTH       (C_MEM_SDR_DATA_WIDTH),
    .C_READ_FIFO_PIPE           (P_READ_FIFO_PIPE),
    .C_RDFIFO_EMPTY_PIPE        (P_RDFIFO_EMPTY_PIPE),
    .C_MAX_CNTR_WIDTH           (P_MAX_CNTR_WIDTH)
  )
  dualxcl_read_0
  (
    .Clk                        (Clk),                      // I
    .Clk_MPMC                   (Clk_MPMC),                 // I
    .Rst                        (Rst),                      // I
    .Clk_PI_Enable              (clk_pi_enable),            // I
    .FSL_A_S_Read               (FSL_A_S_Read),             // I
    .FSL_A_S_Data               (FSL_A_S_Data),             // O
    .FSL_A_S_Control            (FSL_A_S_Control),          // O
    .FSL_A_S_Exists             (FSL_A_S_Exists),           // O
    .FSL_B_S_Read               (FSL_B_S_Read),             // I
    .FSL_B_S_Data               (FSL_B_S_Data),             // O
    .FSL_B_S_Control            (FSL_B_S_Control),          // O
    .FSL_B_S_Exists             (FSL_B_S_Exists),           // O
    .Addr_Sel_B                 (addr_sel_b),               // I
    .Addr_Sel_Push              (addr_sel_push),            // I
    .Addr_Sel_Target_Word       (addr_sel_target_word),     // I
    .Addr_Sel_FIFO_Full         (addr_sel_fifo_full),       // O
    .PI_RdFIFO_Data             (PI_RdFIFO_Data),           // I
    .PI_RdFIFO_Pop              (PI_RdFIFO_Pop),            // O
    .PI_RdFIFO_RdWdAddr         (PI_RdFIFO_RdWdAddr),       // I
    .PI_RdFIFO_Empty            (PI_RdFIFO_Empty),          // I
    .PI_RdFIFO_Flush            (PI_RdFIFO_Flush)           // O
  );

endmodule // dualxcl

`default_nettype wire
