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

module dualxcl_access_data_path
#(
///////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////
  parameter C_XCL_LINESIZE      = 1,        // Valid Values: 1, 4, 8, 16
  parameter C_XCL_WRITEXFER     = 1,        // Valid Values: 0, 1, 2
  parameter C_PI_SUBTYPE        = "IXCL",   // Valid Values: IXCL, IXCL2, DXCL,
                                            //               DXCL2, XCL,INACTIVE
  parameter C_ADDR_MASK         = 32'h00000000,  // Valid Values: Address MASK
  parameter C_PI_OFFSET         = 0,        // Valid Values: offset Address
  parameter C_PI_ADDR_WIDTH     = 32,       // Valid Values: 32
  parameter C_PI_DATA_WIDTH     = 32,       // Valid Values: 32
  parameter C_PI_BE_WIDTH       = 4,        // Valid Values: 4
  parameter C_MEM_DATA_WIDTH    = 8,        // Valid Values: 8, 16, 32, 64
  parameter C_ACCESS_FIFO_PIPE  = 0         // Valid Values: 0, 1
)
(
///////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////
  // System Signals
  input  wire                       Clk,
  input  wire                       Rst,

  // Access FSL
  input  wire                       FSL_M_Clk,
  input  wire                       FSL_M_Write,
  input  wire [0:31]                FSL_M_Data,
  input  wire                       FSL_M_Control,
  output wire                       FSL_M_Full,

  // FSM control
  input  wire                       Addr_Read,
  output wire                       Addr_RNW,
  output wire                       Addr_Exists,
  output wire [3:0]                 Addr_Target_Word,
  input  wire                       Data_Read,
  output wire                       Data_Exists,
  output wire                       Data_Exists_Early,
  output wire                       Data_Wr_Burst,
  output wire                       Data_Wr_Burst_Early,

  // MPMC Port Interface
  output wire [C_PI_ADDR_WIDTH-1:0] PI_Addr,
  output wire                       PI_RdModWr,
  output wire [3:0]                 PI_Size,
  output wire [C_PI_DATA_WIDTH-1:0] PI_WrFIFO_Data,
  output wire [C_PI_BE_WIDTH-1:0]   PI_WrFIFO_BE
);

///////////////////////////////////////////////////////////////////////////
// Local Params and Wires
///////////////////////////////////////////////////////////////////////////
  localparam  [3:0]             P_SIZE_DECODE = (C_XCL_LINESIZE == 1) ? 4'd0 :
                                                (C_XCL_LINESIZE == 4) ? 4'd1 :
                                                (C_XCL_LINESIZE == 8) ? 4'd2 :
                                                                    4'd3;
  localparam                    P_ADDR_INDEX  = (C_XCL_LINESIZE == 1) ? 4'd2 :
                                                P_SIZE_DECODE + 3;

  wire                          fsl_m_write_i;
  wire [0:31]                   fsl_m_data_i;
  wire                          fsl_m_control_i;
  wire                          fsl_m_full_i;
  wire [0:31]                   addr;
  wire                          addr_control;
  wire [0:31]                   data;
  wire                          data_control;
  wire                          addr_empty;
  wire                          data_empty;

  // npi wires
  wire [C_PI_ADDR_WIDTH-1:0]    pi_addr_i;
  wire [C_PI_ADDR_WIDTH-1:0]    pi_addr_word_aligned;
  wire [C_PI_ADDR_WIDTH-1:0]    pi_addr_burst_aligned;
  reg  [0:C_PI_BE_WIDTH-1]      pi_wrfifo_be_i;
  genvar                        i;

///////////////////////////////////////////////////////////////////////////
// Begin logic
///////////////////////////////////////////////////////////////////////////

  // Instantiate 16 deep FIFO if C_ACCESS_FIFO_PIPE == 1 if we are not IXCL or 
  // IXCL2.
  generate
    if (C_ACCESS_FIFO_PIPE == 0 || C_PI_SUBTYPE == "IXCL" 
        || C_PI_SUBTYPE == "IXCL2")
    begin : NO_ACCESS_FIFO

      assign fsl_m_write_i   = FSL_M_Write;
      assign fsl_m_data_i    = FSL_M_Data;
      assign fsl_m_control_i = FSL_M_Control;
      assign FSL_M_Full      = fsl_m_full_i;
    end
    else
    begin : ACCESS_FIFO

      wire          fifo_empty;

      srl16e_fifo
      #(
        .c_width    (33),
        .c_awidth   (4),
        .c_depth    (16)
      )
      access_fifo
      (
        .Clk        (Clk),                  // I
        .Rst        (Rst),                  // I
        .WR_EN      (FSL_M_Write),          // I
        .RD_EN      (fsl_m_write_i),        // I
        .DIN        ({FSL_M_Control, FSL_M_Data}),     // I
        .DOUT       ({fsl_m_control_i, fsl_m_data_i}), // O
        .FULL       (FSL_M_Full),           // O
        .EMPTY      (fifo_empty)            // O
      );

      assign fsl_m_write_i = ~fifo_empty & ~fsl_m_full_i;

    end
  endgenerate
  
  // Instantiate registers to hold address and data.
  generate 
    if (C_PI_SUBTYPE == "IXCL" || C_PI_SUBTYPE == "IXCL2")
    begin : IXCL


      srl16e_fifo
      #(
        .c_width    (32),
        .c_awidth   (1),
        .c_depth    (1)
      )
      access_fifo
      (
        .Clk        (Clk),                  // I
        .Rst        (Rst),                  // I
        .WR_EN      (fsl_m_write_i),          // I
        .RD_EN      (Addr_Read),            // I
        .DIN        (fsl_m_data_i),           // I
        .DOUT       (addr),                 // O
        .FULL       (fsl_m_full_i),           // O
        .EMPTY      (addr_empty)            // O
      );


      // Tie offs 
      assign addr_control   = 1'b0;
      assign data_empty     = 1'b1;
      assign data_control   = 1'b0;
      assign data           = 32'b0;
      assign Data_Exists_Early = 1'b0;
    end
    else
    begin : DXCL
      wire          addr_wr_en;
      wire          data_wr_en;
      wire          addr_full;
      wire          data_full;
      reg  [3:0]    line_cnt;
      reg           line_cnt_done;


      assign addr_wr_en = fsl_m_write_i & (~Addr_Exists | Addr_Read);
      assign data_wr_en = fsl_m_write_i & Addr_Exists & addr_control  & ~Addr_Read;
      assign Data_Exists_Early = data_wr_en;
      assign fsl_m_full_i = (addr_full & ~Addr_Read) & (~addr_control | line_cnt_done
                                       | (data_full & ~Data_Read));
      srl16e_fifo
      #(
        .c_width    (33),
        .c_awidth   (1),
        .c_depth    (1)
      )
      addr_reg
      (
        .Clk        (Clk),                          // I
        .Rst        (Rst),                          // I
        .WR_EN      (addr_wr_en),                   // I
        .RD_EN      (Addr_Read),                    // I
        .DIN        ({fsl_m_control_i, fsl_m_data_i}),  // I
        .DOUT       ({addr_control, addr}),         // O
        .FULL       (addr_full),                    // O
        .EMPTY      (addr_empty)                    // O
      );

      srl16e_fifo
      #(
        .c_width    (33),
        .c_awidth   (1),
        .c_depth    (1)
      )
      data_reg
      (
        .Clk        (Clk),                          // I
        .Rst        (Rst),                          // I
        .WR_EN      (data_wr_en),                   // I
        .RD_EN      (Data_Read),                    // I
        .DIN        ({fsl_m_control_i, fsl_m_data_i}),  // I
        .DOUT       ({data_control, data}),         // O
        .FULL       (data_full),                    // O
        .EMPTY      (data_empty)                    // O
      );

      always @(posedge Clk)
      begin
        if (Rst || Addr_Read) begin
          line_cnt <= 0;
        end
        else if (data_wr_en) begin
          line_cnt <= line_cnt + 1'b1;
        end
      end
      
      always @(posedge Clk)
      begin
        if (Rst || Addr_Read) begin
          line_cnt_done <= 1'b0;
        end
        else if ((line_cnt[0 +: (P_SIZE_DECODE + 1)] == C_XCL_LINESIZE-1) && data_wr_en) begin
          line_cnt_done <= 1'b1;
        end
      end
    end


  endgenerate

  assign Addr_Exists    = ~addr_empty;
  assign Data_Exists    = ~data_empty;

  assign Addr_RNW = ~addr_control;

  // Indicates we are doing a write burst (if Addr_RNW is low)
  assign Data_Wr_Burst = (({data_control, addr[30:31]} == 3'd2) 
                           && (C_PI_SUBTYPE == "DXCL2")) 
                         || (C_XCL_WRITEXFER == 2 && C_XCL_LINESIZE > 1
                             && C_PI_SUBTYPE == "XCL");

  // Indicates we are doing a write burst (if Addr_RNW is low)
  assign Data_Wr_Burst_Early = (({fsl_m_control_i, addr[30:31]} == 3'd2) 
                           && (C_PI_SUBTYPE == "DXCL2")) 
                         || (C_XCL_WRITEXFER == 2 && C_XCL_LINESIZE > 1
                             && C_PI_SUBTYPE == "XCL");

///////////////////////////////////////////////////////////////////////////
// Generate Address Alignment
///////////////////////////////////////////////////////////////////////////
  // NOTE: Adding a non-zero offset could adversely affect max frequency
  assign pi_addr_i = (addr & C_ADDR_MASK) + C_PI_OFFSET;

  // Aligned the address appropriate for writes and burst reads
  assign pi_addr_word_aligned = {pi_addr_i[C_PI_ADDR_WIDTH-1:2], 2'b0};
  assign pi_addr_burst_aligned = {pi_addr_i[C_PI_ADDR_WIDTH-1:P_ADDR_INDEX], 
                                  {P_ADDR_INDEX{1'b0}}};


  generate 
  if (C_PI_SUBTYPE == "IXCL" || C_PI_SUBTYPE == "DXCL")
  begin : IDXCL_ADDR_ALIGN
    assign PI_Addr = pi_addr_word_aligned;
  end
  else if (C_PI_SUBTYPE == "IXCL2" || C_PI_SUBTYPE == "DXCL2")
  begin : IDXCL2_ADDR_ALIGN
    assign PI_Addr = pi_addr_word_aligned;
  end
  // MPMC only supports 16W boundary aligned reads, no target word first
  else if (C_XCL_LINESIZE == 16)
  begin : XCL_ADDR_ALIGN_16W
    assign PI_Addr = (Addr_RNW | Data_Wr_Burst) ? pi_addr_burst_aligned
                                                : pi_addr_word_aligned;
  end
  else
  begin : XCL_ADDR_ALIGN_DEFAULT
    assign PI_Addr = ( Data_Wr_Burst ) ? pi_addr_burst_aligned 
                                       : pi_addr_word_aligned;
  end
  endgenerate

  assign Addr_Target_Word = pi_addr_i[5:2];

///////////////////////////////////////////////////////////////////////////
// Generate PI_Size
///////////////////////////////////////////////////////////////////////////
  // If we are a doing a write word, then size is 1, otherwise C_XCL_LINESIZE
  assign PI_Size = (~Addr_RNW & ~Data_Wr_Burst) ? 4'd0 : P_SIZE_DECODE;
  
///////////////////////////////////////////////////////////////////////////
// Generate Byte Enables
///////////////////////////////////////////////////////////////////////////
  // Generate Byte Enables (Big Endian)
  always @(data_control or addr[30:31])
    begin
      case ({data_control, addr[30:31]})
        3'd0: pi_wrfifo_be_i <= 4'b1111;
        3'd1: pi_wrfifo_be_i <= 4'b1100;
        3'd2: pi_wrfifo_be_i <= 4'b1111; 
        3'd3: pi_wrfifo_be_i <= 4'b0011;
        3'd4: pi_wrfifo_be_i <= 4'b1000;
        3'd5: pi_wrfifo_be_i <= 4'b0100;
        3'd6: pi_wrfifo_be_i <= 4'b0010;
        3'd7: pi_wrfifo_be_i <= 4'b0001;
        default: begin 
          pi_wrfifo_be_i <= 4'b1111;    
        end
      endcase
    end   

  generate
    if (C_PI_SUBTYPE == "IXCL" || C_PI_SUBTYPE == "IXCL2" || C_XCL_WRITEXFER == 0)
    begin : BE_LOW
      assign PI_WrFIFO_BE = 4'b0000;
    end
    else if (C_XCL_WRITEXFER == 2)
    begin : BE_HIGH
      assign PI_WrFIFO_BE = 4'b1111;
    end
    else
    begin : BE_DECODE
      // Bit reordering within byte enables (Big Endian -> Little Endian)
      for (i = 0; i < C_PI_BE_WIDTH; i = i + 1) begin : BE_REORDER
        assign PI_WrFIFO_BE[i] = pi_wrfifo_be_i[i];
      end
    end
  endgenerate

///////////////////////////////////////////////////////////////////////////
// Byte reordering within write data bus (Big Endian -> Little Endian)
///////////////////////////////////////////////////////////////////////////
  generate
    for (i = 0; i < C_PI_DATA_WIDTH; i = i + 8) begin : DATA_REORDER
      assign PI_WrFIFO_Data[i+7:i] = data[i:i+7];
    end
  endgenerate


///////////////////////////////////////////////////////////////////////////
// Generate PI_RdModWr
///////////////////////////////////////////////////////////////////////////
  generate
    if (C_MEM_DATA_WIDTH == 8)
    begin : DW8
      assign PI_RdModWr = (PI_WrFIFO_BE == 4'b1111) ? 1'b0 : 1'b1;
    end
    else if ((C_MEM_DATA_WIDTH <= 32 && C_XCL_LINESIZE >= 4))
    begin : DW16
      assign PI_RdModWr = Data_Wr_Burst ? 1'b0 : 1'b1;
    end
    else if (C_MEM_DATA_WIDTH <= 64 && C_XCL_LINESIZE >= 8)
    begin : DW64
      assign PI_RdModWr = Data_Wr_Burst ? 1'b0 : 1'b1;
    end
    else
    begin : RDMODWR_ALWAYS
      assign PI_RdModWr = 1'b1;
    end
  endgenerate

endmodule // dualxcl_access_data_path

`default_nettype wire
