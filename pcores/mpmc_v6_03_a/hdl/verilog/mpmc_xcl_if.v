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
// Description:       MPMC to XCL Interface Module Top level Module
// Structure:   
//  --mpmc_xcl_if
//      --mpmc_sample_cycle
//      --xcl_addr
//      --xcl_write_data
//      --xcl_read_data
//          --pop_generator
//          --RAM16X1D (read fifo)
//          --fifo_pipeline
//      --SRL16E (access_fifo)
//      --mpmc_rdcntr
//      --fifo_pipeline
//
// Verilog-standard:  Verilog 2001
//
///////////////////////////////////////////////////////////////////////////////
//
// @BEGIN_CHANGELOG EDK_Jm_SP1
// Fixed target word first read transactions when C_LINESIZE = 16.  
// Fixed read corruption when C_WRITEXFER = 2 and C_LINESIZE > 1.
// @END_CHANGELOG
//
// @BEGIN_CHANGELOG EDK_Jm_SP2
// Fixed back to back writes in XCL PIM for C_WRITEXFER = 2 and C_LINESIZE
// > 1.
// XCL PIM updated to sample Read_Data_Read signal for non-IXCL and non-DXCL
// pim subtypes.
// @END_CHANGELOG
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps
`default_nettype none

module mpmc_xcl_if 
#(
///////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////
  parameter C_PI_SUBTYPE                = "XCL",// Valid Values: XCL, IXCL, DXCL
  parameter C_PI_OFFSET                 = 0,    // Valid Values: offset Address
  parameter C_PI_ADDR_WIDTH             = 32,   // Valid Values: 32
  parameter C_PI_DATA_WIDTH             = 32,   // Valid Values: 32
  parameter C_PI_BE_WIDTH               = 4,    // Valid Values: 4
  parameter C_PI_RDWDADDR_WIDTH         = 4,    // Valid Values: 4
  parameter C_PI_RDDATA_DELAY           = 0,    // Valid Values: 0, 1, 2
  parameter C_WRITEXFER                 = 1,    // Valid Values: 0,1,2
  parameter C_LINESIZE                  = 8,    // Valid Values: 1, 4, 8, 16
  parameter C_PIPE_STAGES               = 3,    // Valid Values: 0, 1, 2, 3
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
  // Access FSL
  input  wire                           Access_FSL_M_Clk,
  input  wire                           Access_FSL_M_Write,
  input  wire [0:31]                    Access_FSL_M_Data,
  input  wire                           Access_FSL_M_Control,
  output wire                           Access_FSL_M_Full,
  // Read Data FSL
  input  wire                           Read_Data_FSL_S_Clk,
  input  wire                           Read_Data_FSL_S_Read,
  output wire [0:31]                    Read_Data_FSL_S_Data,
  output wire                           Read_Data_FSL_S_Control, // unused
  output wire                           Read_Data_FSL_S_Exists,       
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

  localparam  P_ACCESS_FIFO_PIPE     = (C_PIPE_STAGES >= 3);
  localparam  P_RDFIFO_EMPTY_PIPE    = (C_PIPE_STAGES >= 2);
  localparam  P_READ_FIFO_PIPE       = (C_PIPE_STAGES >= 1);

  wire [C_PI_ADDR_WIDTH-1:0] pi_addr_i;
  wire        clk_pi_enable;

  wire        access_exists_i;
  wire        access_ren_i;
  wire        access_control_i;
  wire [0:31] access_data_i;

  wire        access_exists;
  wire        access_ren_addr;
  wire        access_ren_write;
  wire        access_control;
  wire [0:31] access_data;

  wire [4:0]  access_raddr;
  wire        read_start;
  wire        read_done;
  wire        write_start;
  wire        write_done;

 
///////////////////////////////////////////////////////////////////////////
// Handle Clocking Boundaries
///////////////////////////////////////////////////////////////////////////
  mpmc_sample_cycle
    mpmc_sample_cycle_0 (
      .sample_cycle(clk_pi_enable),
      .slow_clk(Clk),
      .fast_clk(Clk_MPMC)
  );

///////////////////////////////////////////////////////////////////////////
// Handle Address Path Signals
///////////////////////////////////////////////////////////////////////////
  xcl_addr #(
    .C_PI_OFFSET(C_PI_OFFSET),
    .C_WRITEXFER(C_WRITEXFER),
    .C_LINESIZE(C_LINESIZE)
  ) 
  xcl_addr_0 (
    .Clk(Clk),                           // I
    .Clk_MPMC(Clk_MPMC),                 // I
    .Rst(Rst),                           // I
    .Clk_PI_Enable(clk_pi_enable),       // I
    .PI_Addr(pi_addr_i),                 // O
    .PI_AddrReq(PI_AddrReq),             // O
    .PI_AddrAck(PI_AddrAck),             // I
    .PI_RNW(PI_RNW),                     // O
    .PI_RdModWr(PI_RdModWr),             // O
    .PI_Size(PI_Size),                   // O [3:0]
    .PI_InitDone(PI_InitDone),           // I
    .Access_Data(access_data),           // I
    .Access_Exists(access_exists),       // I
    .Access_Control(access_control),     // I
    .Access_REN_Addr(access_ren_addr),   // O
    .Write_Start(write_start),           // I
    .Read_Start(read_start),             // I
    .Read_Done(read_done),               // O
    .Write_Done(write_done)              // O
  );

  // Aligned the address appropriate for writes and burst reads
  generate 
    case ({C_WRITEXFER, C_LINESIZE})

      // Align the Write only to 4 word boundary
      {32'd2, 32'd4}:
      begin : ADDR_ALIGN_4W_W
        assign PI_Addr = ~PI_RNW ? {pi_addr_i[C_PI_ADDR_WIDTH-1:4], 4'b0} 
                                 : pi_addr_i;
      end

      // Align the Write only to 8 word boundary
      {32'd2, 32'd8}:
      begin : ADDR_ALIGN_8W_W
        assign PI_Addr = ~PI_RNW ? {pi_addr_i[C_PI_ADDR_WIDTH-1:5], 5'b0} 
                                : pi_addr_i;
      end

      // Align read only XCL to 16 word boundary
      {32'd0, 32'd16}:
      begin : ADDR_ALIGN_16_RO
        assign PI_Addr = {pi_addr_i[C_PI_ADDR_WIDTH-1:6], 6'b0};
      end

      // Align the Read only to 16 word boundary
      {32'd1, 32'd16}:
      begin : ADDR_ALIGN_16W_R
        assign PI_Addr = PI_RNW ? {pi_addr_i[C_PI_ADDR_WIDTH-1:6], 6'b0} 
                                : pi_addr_i;
      end

      {32'd2, 32'd16}:
      begin : ADDR_ALIGN_16_RW
        assign PI_Addr = {pi_addr_i[C_PI_ADDR_WIDTH-1:6], 6'b0};
      end

      // else no alignment necessary
      default:
      begin : NO_ADDR_ALIGN
        assign PI_Addr = pi_addr_i;
      end
    endcase
  endgenerate

///////////////////////////////////////////////////////////////////////////
// Handle Write Data Path Signals
///////////////////////////////////////////////////////////////////////////
  generate
    if (C_WRITEXFER == 0) begin : no_xcl_write_data_inst
      // tie off outputs
      assign PI_WrFIFO_Data = 0;
      assign PI_WrFIFO_BE = 0;
      assign PI_WrFIFO_Push = 0;
      assign PI_WrFIFO_Flush = 0;
      assign access_ren_write = 0;
      assign write_done = 0; 
    end
  else 
    begin : xcl_write_data_inst
      xcl_write_data #(
        .C_PI_DATA_WIDTH(C_PI_DATA_WIDTH),
        .C_PI_BE_WIDTH(C_PI_BE_WIDTH),
        .C_WRITEXFER(C_WRITEXFER),
        .C_LINESIZE(C_LINESIZE)
      ) 
      xcl_write_data_0 (
        .Clk(Clk),                                // I
        .Clk_MPMC(Clk_MPMC),                      // I
        .Rst(Rst),                                // I
        .Clk_PI_Enable(clk_pi_enable),            // I
        .PI_WrFIFO_Data(PI_WrFIFO_Data),          // O [C_PI_DATA_WIDTH-1:0]
        .PI_WrFIFO_BE(PI_WrFIFO_BE),              // O [C_PI_BE_WIDTH-1:0]
        .PI_WrFIFO_Push(PI_WrFIFO_Push),          // O
        .PI_WrFIFO_AlmostFull(PI_WrFIFO_AlmostFull), // I 
        .PI_WrFIFO_Flush(PI_WrFIFO_Flush),        // O
        .Access_Exists(access_exists),            // I
        .Access_Control(access_control),          // I
        .Access_Data(access_data),                // I [0:31]
        .Access_REN_Write_Data(access_ren_write), // O
        .Write_Start(write_start),                // I
        .Write_Done(write_done)                   // O
      );
    end
  endgenerate
  
///////////////////////////////////////////////////////////////////////////
// Handle Read Data Path Signals
///////////////////////////////////////////////////////////////////////////
  xcl_read_data #(
    .C_PI_DATA_WIDTH        (C_PI_DATA_WIDTH),
    .C_PI_RDWDADDR_WIDTH    (C_PI_RDWDADDR_WIDTH),
    .C_PI_RDDATA_DELAY      (C_PI_RDDATA_DELAY),
    .C_LINESIZE             (C_LINESIZE),
    .C_MEM_SDR_DATA_WIDTH   (C_MEM_SDR_DATA_WIDTH),
    .C_READ_FIFO_PIPE       (P_READ_FIFO_PIPE),
    .C_RDFIFO_EMPTY_PIPE    (P_RDFIFO_EMPTY_PIPE)
  ) 
  xcl_read_data_0 (
    .Clk                (Clk),                      // I
    .Clk_MPMC           (Clk_MPMC),                 // I
    .Rst                (Rst),                      // I
    .Clk_PI_Enable      (clk_pi_enable),            // I
    .PI_RdFIFO_Data     (PI_RdFIFO_Data),           // I [C_PI_DATA_WIDTH-1:0]
    .PI_RdFIFO_Pop      (PI_RdFIFO_Pop),            // O
    .PI_RdFIFO_RdWdAddr (PI_RdFIFO_RdWdAddr),     // I [C_PI_RDWDADDR_WIDTH-1:0]
    .PI_RdFIFO_Empty    (PI_RdFIFO_Empty),          // I 
    .PI_RdFIFO_Flush    (PI_RdFIFO_Flush),          // O
    .Target_Word        (access_data[26:29]),       // I 
    .Read_Data_Exists   (Read_Data_FSL_S_Exists),   // O
    .Read_Data_Control  (Read_Data_FSL_S_Control),  // O
    .Read_Data          (Read_Data_FSL_S_Data),     // O
    .Read_Data_Read     (Read_Data_FSL_S_Read),     // I
    .Read_Start         (read_start),               // I
    .Read_Done          (read_done)                 // O
  );

///////////////////////////////////////////////////////////////////////////
// Instantiate FSL FIFOs
///////////////////////////////////////////////////////////////////////////

  // Access FSL FIFO
  SRL16E access_fifo[0:32] (
    .CLK(Clk), 
    .CE(Access_FSL_M_Write),
    .D({Access_FSL_M_Control, Access_FSL_M_Data}), 
    .A0(access_raddr[0]), 
    .A1(access_raddr[1]), 
    .A2(access_raddr[2]),
    .A3(access_raddr[3]), 
    .Q({access_control_i, access_data_i})
  );

  // Access FSL read counter
  mpmc_rdcntr access_raddr_cntr (
    .rclk(Clk), 
    .rst(Rst), 
    .ren(access_ren_i), 
    .wen(Access_FSL_M_Write), 
    .raddr(access_raddr),
    .full(Access_FSL_M_Full),
    .exists(access_exists_i)
  );

// registering the output of the output fifos
  generate 
    if (P_ACCESS_FIFO_PIPE == 1)
      begin : gen_access_pipeline

        fifo_pipeline
        #(
          .C_DWIDTH       (33),
          .C_INV_EXISTS   (0)
        )
        access_fifo_pipe
        (
          .Clk            (Clk),
          .Rst            (Rst),
          .FIFO_Exists    (access_exists_i),
          .FIFO_Read      (access_ren_i),
          .FIFO_Data      ({access_control_i, access_data_i}),
          .PIPE_Exists    (access_exists),
          .PIPE_Read      (access_ren_addr | access_ren_write),
          .PIPE_Data      ({access_control, access_data})
        );

      end
    else 
    begin : gen_no_access_pipe
        assign access_exists = access_exists_i;
        assign access_ren_i = access_ren_addr | access_ren_write;
        assign access_control = access_control_i;
        assign access_data = access_data_i;
    end
  endgenerate

  
endmodule // mpmc_xcl_if

`default_nettype wire
