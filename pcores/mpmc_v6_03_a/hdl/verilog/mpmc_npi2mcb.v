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
`default_nettype none
`timescale 1ps / 1ps
module mpmc_npi2mcb #(
  parameter integer C_PI_BASETYPE               = 0,
  parameter integer C_PI_ADDR_WIDTH             = 32,   // Valid Values: 32
  parameter integer C_PI_DATA_WIDTH             = 32,   // Valid Values: 32
  parameter integer C_PI_BE_WIDTH               = 4,    // Valid Values: 4
  parameter integer C_PI_RDWDADDR_WIDTH         = 4     // Valid Values: 4
  ) (

  input   wire                            Clk_MPMC,
  input   wire                            Rst_MPMC,
  // MPMC Port Interface

  input   wire [C_PI_ADDR_WIDTH-1:0]      PI_Addr,
  input   wire                            PI_AddrReq,
  output  reg                             PI_AddrAck,
  input   wire                            PI_RNW,
  input   wire                            PI_RdModWr,
  input   wire [3:0]                      PI_Size,
  output  wire                            PI_InitDone,
  input   wire [C_PI_DATA_WIDTH-1:0]      PI_WrFIFO_Data,
  input   wire [C_PI_BE_WIDTH-1:0]        PI_WrFIFO_BE,
  input   wire                            PI_WrFIFO_Push,
  output  reg  [C_PI_DATA_WIDTH-1:0]      PI_RdFIFO_Data,
  input   wire                            PI_RdFIFO_Pop,
  output  reg  [C_PI_RDWDADDR_WIDTH-1:0]  PI_RdFIFO_RdWdAddr,
  output  wire                            PI_WrFIFO_AlmostFull,
  input   wire                            PI_WrFIFO_Flush,
  output  wire                            PI_WrFIFO_Empty,
  output  wire                            PI_RdFIFO_Empty,
  input   wire                            PI_RdFIFO_Flush,
  output  wire                            PI_Error,

  ///////////////////////////////////////////////////////////////////////////////
  //CMD PORT
  output  wire                            MCB_cmd_clk,
  output  wire                            MCB_cmd_en,
  output  wire  [2:0]                     MCB_cmd_instr,
  output  wire  [5:0]                     MCB_cmd_bl,
  output  wire  [29:0]                    MCB_cmd_byte_addr,
  input   wire                            MCB_cmd_empty,
  input   wire                            MCB_cmd_full,

  ///////////////////////////////////////////////////////////////////////////////
  //DATA PORT
  output  wire                            MCB_wr_clk,
  output  wire                            MCB_wr_en,
  output  wire  [C_PI_BE_WIDTH-1:0]       MCB_wr_mask,
  output  wire  [C_PI_DATA_WIDTH - 1:0]   MCB_wr_data,
  input   wire                            MCB_wr_full,
  input   wire                            MCB_wr_empty,
  input   wire  [6:0]                     MCB_wr_count,
  input   wire                            MCB_wr_underrun,
  input   wire                            MCB_wr_error,

  output  wire                            MCB_rd_clk,
  output  wire                            MCB_rd_en,
  input   wire  [C_PI_DATA_WIDTH - 1:0]   MCB_rd_data,
  input   wire                            MCB_rd_full,
  input   wire                            MCB_rd_empty,
  input   wire  [6:0]                     MCB_rd_count,
  input   wire                            MCB_rd_overflow,
  input   wire                            MCB_rd_error,
  input   wire                            MCB_calib_done
  );

///////////////////////////////////////////////////////////////////////////////
//Read Word address counter

localparam  P_NPI_SINGLE          = 4'h0;
localparam  P_NPI_CL4             = 4'h1;
localparam  P_NPI_CL8             = 4'h2;
localparam  P_NPI_BURST16         = 4'h3;
localparam  P_NPI_BURST32         = 4'h4;
localparam  P_NPI_BURST64         = 4'h5;

localparam  P_SINGLE_BEAT_COUNT   = 1;
localparam  P_CL4_BEAT_COUNT      = (C_PI_DATA_WIDTH == 32) ? 4  : 2;
localparam  P_CL8_BEAT_COUNT      = (C_PI_DATA_WIDTH == 32) ? 8  : 4;
localparam  P_BURST16_BEAT_COUNT  = (C_PI_DATA_WIDTH == 32) ? 16 : 8;
localparam  P_BURST32_BEAT_COUNT  = (C_PI_DATA_WIDTH == 32) ? 32 : 16;
localparam  P_BURST64_BEAT_COUNT  = (C_PI_DATA_WIDTH == 32) ? 64 : 32;
localparam  P_VFBC_BASETYPE       = (C_PI_BASETYPE == 6);
localparam  P_XCL_BASETYPE        = (C_PI_BASETYPE == 1);
localparam  P_PLB_BASETYPE        = (C_PI_BASETYPE == 2);
localparam  P_SDMA_BASETYPE       = (C_PI_BASETYPE == 3);
localparam  P_NPI_BASETYPE        = (C_PI_BASETYPE == 4);
localparam  P_SRL_ADDR_OFFSET     = (C_PI_BASETYPE == 3) ? 0 : 8;


reg   [6:0] lutaddr;
wire  [6:0] lutaddr_baseaddr;
reg   [6:0] lutaddr_baseaddr_i;
reg   [6:0] lutaddr_baseaddr_i2;
reg         xfer_fifo_addr_we;
wire  [4:0] xfer_fifo_addr;
reg   [4:0] num_xfers_in_fifo;

wire  [6:0] lutaddr_highaddr;
reg   [6:0] lutaddr_highaddr_i;
reg   [6:0] lutaddr_highaddr_i2;
reg   [6:0] lutaddr_highaddr_d1;
reg         sdma_read_fifo_hold;
reg         last_pop_d1;
wire        highaddr_eq_lutaddr;
wire        num_xfers_in_fifo_lte_one;
wire        num_xfers_in_fifo_eq_zero;
reg         num_xfers_in_fifo_eq_zero_q;
reg         bridge_flush_hold;
wire        pop_to_mcb;
reg  [29:0] modified_pi_addr;
wire        read_transfer;
wire        rd_count_eq_highaddr;
reg  [5:0]  cmd_bl;
reg         wrfifo_almostfull_q;
reg         mcb_wr_count_lt_watermark;
wire        npi_single_transfer;


assign highaddr_eq_lutaddr = (lutaddr_highaddr_d1 == lutaddr);
assign num_xfers_in_fifo_lte_one = (num_xfers_in_fifo <= 1);
assign num_xfers_in_fifo_eq_zero = (num_xfers_in_fifo == 0);
assign pop_to_mcb = (PI_RdFIFO_Pop | (bridge_flush_hold && !MCB_rd_empty));
assign read_transfer = (PI_RNW == 1'b1);

assign rd_count_eq_highaddr = (MCB_rd_count == (lutaddr_highaddr - P_SRL_ADDR_OFFSET + 1));
assign npi_single_transfer = (PI_Size == P_NPI_SINGLE);

always @(posedge Clk_MPMC) begin
  num_xfers_in_fifo_eq_zero_q <= num_xfers_in_fifo_eq_zero;
  ///////////////////////////////////////////////////////////////////////////////
  //On a read push an entry onto the RD FIFO
  xfer_fifo_addr_we <= PI_AddrAck & read_transfer;

  ///////////////////////////////////////////////////////////////////////////////
  //Pipeline the base address.
  lutaddr_baseaddr_i2 <= lutaddr_baseaddr_i;
  lutaddr_highaddr_i2 <= lutaddr_highaddr_i;
  lutaddr_highaddr_d1 <= lutaddr_highaddr;
  last_pop_d1 <= pop_to_mcb & highaddr_eq_lutaddr;

  ///////////////////////////////////////////////////////////////////////////////
  //Pipeline the data out off MCB
  PI_RdFIFO_Data <= MCB_rd_data;
  ///////////////////////////////////////////////////////////////////////////////
  //
  if (Rst_MPMC) begin
    lutaddr <= 7'h00;
    num_xfers_in_fifo <= 0;
    bridge_flush_hold <= 1'b0;
    sdma_read_fifo_hold <= 1'b0;
    wrfifo_almostfull_q <= 1'b0;
    mcb_wr_count_lt_watermark <= 1'b0;
  end else begin
    ///////////////////////////////////////////////////////////////////////////////
    //Timing path from MCB count to almost full
    wrfifo_almostfull_q <= (MCB_wr_count >= 7'd62);
    ///////////////////////////////////////////////////////////////////////////////
    //Flop the number of entries in the WR queue since the timing path out of the 
    // MCB is too long
    mcb_wr_count_lt_watermark <= (MCB_wr_count < 7'd33);

    ///////////////////////////////////////////////////////////////////////////////
    //If there is a flush then the rest of the beats from MCB must be dropped.
    if (PI_RdFIFO_Flush && !num_xfers_in_fifo_eq_zero && !last_pop_d1) begin
      bridge_flush_hold <= 1'b1;
    end else if (last_pop_d1) begin
      bridge_flush_hold <= 1'b0;
    end
    ///////////////////////////////////////////////////////////////////////////////
    //update the lutaddr when the last pop or there are no xfers pending
    if (last_pop_d1 || num_xfers_in_fifo_eq_zero_q) begin
      lutaddr <= lutaddr_baseaddr;
    end else if (pop_to_mcb) begin
      ///////////////////////////////////////////////////////////////////////////////
      //When there is a pop then increment the address
      lutaddr <= lutaddr + 1'b1;
    end

    ///////////////////////////////////////////////////////////////////////////////
    //Count the number of entries in the fifo
    if ((xfer_fifo_addr_we) & (pop_to_mcb & highaddr_eq_lutaddr)) begin
      num_xfers_in_fifo <= num_xfers_in_fifo;
    end else if (pop_to_mcb & highaddr_eq_lutaddr) begin
      num_xfers_in_fifo <= num_xfers_in_fifo - 1'b1;
    end else if (xfer_fifo_addr_we) begin
      num_xfers_in_fifo <= num_xfers_in_fifo + 1'b1;
    end

    ///////////////////////////////////////////////////////////////////////////////
    //SDMA cannot handle back pressure, so the Empty must be held asserted until the
    // entire transfer is received.
    if (P_SDMA_BASETYPE == 1) begin
      if (xfer_fifo_addr_we) begin
        sdma_read_fifo_hold <= 1'b1;
      end else if (rd_count_eq_highaddr) begin
        sdma_read_fifo_hold <= 1'b0;
      end
    end else begin
      sdma_read_fifo_hold <= 1'b0;
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  // Calculate the base/highaddr for the RdWdAddr LUT
  case (lutaddr)
    0: begin
      PI_RdFIFO_RdWdAddr <= 4'h0;
    end
    1: begin
      if (C_PI_DATA_WIDTH == 32) begin
        PI_RdFIFO_RdWdAddr <= 4'h1;
      end else begin
        PI_RdFIFO_RdWdAddr <= 4'h2;
      end
    end
    2: begin
      if (C_PI_DATA_WIDTH == 32) begin
        PI_RdFIFO_RdWdAddr <= 4'h2;
      end else begin
        PI_RdFIFO_RdWdAddr <= 4'h4;
      end
    end
    3: begin
      if (C_PI_DATA_WIDTH == 32) begin
        PI_RdFIFO_RdWdAddr <= 4'h3;
      end else begin
        PI_RdFIFO_RdWdAddr <= 4'h6;
      end
    end
    4: begin
      if (C_PI_DATA_WIDTH == 32) begin
        PI_RdFIFO_RdWdAddr <= 4'h4;
      end else begin
        PI_RdFIFO_RdWdAddr <= 4'h0;
      end
    end
    5: begin
      if (C_PI_DATA_WIDTH == 32) begin
        PI_RdFIFO_RdWdAddr <= 4'h5;
      end else begin
        PI_RdFIFO_RdWdAddr <= 4'h0;
      end
    end
    6: begin
      if (C_PI_DATA_WIDTH == 32) begin
        PI_RdFIFO_RdWdAddr <= 4'h6;
      end else begin
        PI_RdFIFO_RdWdAddr <= 4'h0;
      end
    end
    7: begin
      if (C_PI_DATA_WIDTH == 32) begin
        PI_RdFIFO_RdWdAddr <= 4'h7;
      end else begin
        PI_RdFIFO_RdWdAddr <= 4'h0;
      end
    end
    // Word, B16, B32, B64 Read
    default PI_RdFIFO_RdWdAddr <= 4'h0;
  endcase
end

///////////////////////////////////////////////////////////////////////////////
// Calculate the RdWdAddr
always @(PI_Size) begin
  case (PI_Size)
    P_NPI_SINGLE : begin
      lutaddr_baseaddr_i = P_SRL_ADDR_OFFSET;
      lutaddr_highaddr_i = P_SRL_ADDR_OFFSET;
    end
    P_NPI_CL4 : begin
      lutaddr_baseaddr_i = 0;
      lutaddr_highaddr_i = P_CL4_BEAT_COUNT-1;
    end
    P_NPI_CL8 : begin
      lutaddr_baseaddr_i = 0;
      lutaddr_highaddr_i = P_CL8_BEAT_COUNT-1;
    end
    P_NPI_BURST16 : begin
      lutaddr_baseaddr_i = P_SRL_ADDR_OFFSET;
      lutaddr_highaddr_i = P_SRL_ADDR_OFFSET+P_BURST16_BEAT_COUNT-1;
    end
    P_NPI_BURST32 : begin
      lutaddr_baseaddr_i = P_SRL_ADDR_OFFSET;
      lutaddr_highaddr_i = P_SRL_ADDR_OFFSET+P_BURST32_BEAT_COUNT-1;
    end
    P_NPI_BURST64 : begin
      lutaddr_baseaddr_i = P_SRL_ADDR_OFFSET;
      lutaddr_highaddr_i = P_SRL_ADDR_OFFSET+P_BURST64_BEAT_COUNT-1;
    end
    default : begin
      lutaddr_baseaddr_i = P_SRL_ADDR_OFFSET;
      lutaddr_highaddr_i = P_SRL_ADDR_OFFSET;
    end
  endcase
end

mpmc_rdcntr XFER_FIFO_ADDR (
  .rclk   (Clk_MPMC),
  .rst    (Rst_MPMC),
  .wen    (xfer_fifo_addr_we),
  .ren    (pop_to_mcb & highaddr_eq_lutaddr),
  .raddr  (xfer_fifo_addr),
  .full   (),
  .exists ()
  );


SRL16E XFER_FIFO_SRL[13:0] (
  .CLK (Clk_MPMC),
  .CE  (xfer_fifo_addr_we),
  .A0  (xfer_fifo_addr[0]),
  .A1  (xfer_fifo_addr[1]),
  .A2  (xfer_fifo_addr[2]),
  .A3  (xfer_fifo_addr[3]),
  .D   ({lutaddr_baseaddr_i2,lutaddr_highaddr_i2}),
  .Q   ({lutaddr_baseaddr,lutaddr_highaddr})
  );


///////////////////////////////////////////////////////////////////////////////
//NPI CMD channel
assign PI_InitDone = MCB_calib_done;
assign PI_Error = MCB_rd_error || MCB_rd_overflow || MCB_wr_underrun || MCB_wr_error || PI_WrFIFO_Flush;

///////////////////////////////////////////////////////////////////////////////
//NPI WR channel
assign PI_WrFIFO_Empty = MCB_wr_empty;
assign PI_WrFIFO_AlmostFull = wrfifo_almostfull_q;

///////////////////////////////////////////////////////////////////////////////
//NPI RD channel
assign PI_RdFIFO_Empty = MCB_rd_empty | bridge_flush_hold | sdma_read_fifo_hold;

///////////////////////////////////////////////////////////////////////////////
//Pass thru clocks
assign MCB_cmd_clk = Clk_MPMC;
assign MCB_wr_clk = Clk_MPMC;
assign MCB_rd_clk = Clk_MPMC;


///////////////////////////////////////////////////////////////////////////////
//When C_PI_DATA_WIDTH is 32, the CL must mask out the bottom bits
always @(PI_Size or PI_Addr) begin
  case (PI_Size)
    P_NPI_CL4:  modified_pi_addr = {PI_Addr[29:4],4'h0};
    P_NPI_CL8:  modified_pi_addr = {PI_Addr[29:5],5'h00};
    default:    modified_pi_addr = {PI_Addr[29:2],2'b00};
  endcase
end

localparam PLB_IDLE           = 2'b00;
localparam PLB_SINGLE_PENDING = 2'b01;
localparam PLB_PENDING        = 2'b10;

generate 
  if (P_PLB_BASETYPE == 1) begin : PLB_DELAY_CMD
    ///////////////////////////////////////////////////////////////////////////////
    //PLB uses a simplification of NPI and always issue singles after Command, however,
    // unlike XCL the number of cycles varries.
    // 
    // The PLB command is AddrAcked and the cmd_enable must be delayed until the push
    // of the write data
    reg [29:0]  modified_pi_addr_q;
    reg         PI_AddrAck_q;
    reg  [1:0]  plb_xfer_state;
    reg  [5:0]  cmd_bl_q;
    reg         read_transfer_q;

    always @(posedge Clk_MPMC) begin
      if (PI_AddrAck) begin
        modified_pi_addr_q <= modified_pi_addr;
        cmd_bl_q <= cmd_bl;
        read_transfer_q <= read_transfer;
      end
      ///////////////////////////////////////////////////////////////////////////////
      //If the transfer is a single and it is a write then there is a special case.
      // The bridge must hold off asserting the cmd_en until the wr_en is seen.
      //
      // The PLB PIM cannot start the next transaction until the first has completed the write.
      case (plb_xfer_state)
        PLB_IDLE : begin
          PI_AddrAck_q <= 1'b0;
          if (PI_AddrAck) begin
            if (npi_single_transfer && !read_transfer) begin
              plb_xfer_state <= PLB_SINGLE_PENDING;
            end else begin
              plb_xfer_state <= PLB_PENDING;
              PI_AddrAck_q <= 1'b1;
            end
          end else begin
            plb_xfer_state <= PLB_IDLE;
          end
        end
        PLB_PENDING : begin
          if (!MCB_cmd_full) begin
            plb_xfer_state <= PLB_IDLE;
            PI_AddrAck_q <= 1'b0;
          end else begin
            plb_xfer_state <= PLB_PENDING;
          end
        end
        PLB_SINGLE_PENDING : begin
          if (!MCB_cmd_full && PI_WrFIFO_Push) begin
            plb_xfer_state <= PLB_IDLE;
            PI_AddrAck_q <= 1'b1;
          end else begin
            plb_xfer_state <= PLB_SINGLE_PENDING;
          end
        end
        default : begin
          plb_xfer_state <= PLB_IDLE;
          PI_AddrAck_q <= 1'b0;
        end
      endcase
    end

    assign MCB_cmd_byte_addr = modified_pi_addr_q;
    assign MCB_cmd_en = PI_AddrAck_q;
    assign MCB_cmd_bl = cmd_bl_q;
    assign MCB_cmd_instr = (read_transfer_q) ? 3'b001 : 3'b000;
  end else if (P_XCL_BASETYPE == 1) begin : XCL_DELAY_CMD
    ///////////////////////////////////////////////////////////////////////////////
    //XCL could take a simplification of NPI and always issue singles after
    // Command
    reg [29:0]  modified_pi_addr_q;
    reg         PI_AddrAck_q;
    reg  [5:0]  cmd_bl_q;
    reg         read_transfer_q;

    always @(posedge Clk_MPMC) begin
      PI_AddrAck_q <= PI_AddrAck || (PI_AddrAck_q && MCB_cmd_full);
      if (PI_AddrAck) begin
        modified_pi_addr_q <= modified_pi_addr;
        cmd_bl_q <= cmd_bl;
        read_transfer_q <= read_transfer;
      end
    end

    assign MCB_cmd_byte_addr = modified_pi_addr_q;
    assign MCB_cmd_en = PI_AddrAck_q;
    assign MCB_cmd_bl = cmd_bl_q;
    assign MCB_cmd_instr = (read_transfer_q) ? 3'b001 : 3'b000;
  end else begin : NO_DELAY_CMD
    ///////////////////////////////////////////////////////////////////////////////
    //MCB CMD channel
    assign MCB_cmd_instr = (read_transfer) ? 3'b001 : 3'b000;
    assign MCB_cmd_byte_addr = modified_pi_addr;
    assign MCB_cmd_en = PI_AddrAck;
    assign MCB_cmd_bl = cmd_bl;
  end
endgenerate


generate
  if (P_SDMA_BASETYPE == 1) begin : SDMA_CASE
    always @(read_transfer or MCB_cmd_full or PI_AddrReq or num_xfers_in_fifo_eq_zero or mcb_wr_count_lt_watermark) begin
      if (read_transfer) begin
        PI_AddrAck = !MCB_cmd_full && PI_AddrReq && num_xfers_in_fifo_eq_zero;
      end else begin
        PI_AddrAck = !MCB_cmd_full && PI_AddrReq && mcb_wr_count_lt_watermark;
      end
    end
  end else if (P_XCL_BASETYPE == 1) begin : XCL_CASE
    always @(MCB_cmd_full or PI_AddrReq) begin
      PI_AddrAck = PI_AddrReq && !MCB_cmd_full;
    end
  end else if ((P_NPI_BASETYPE == 1) && (C_PI_DATA_WIDTH == 32)) begin : NPI32_CASE
    reg PI_AddrReq_internal;
    ///////////////////////////////////////////////////////////////////////////////
    //Flop the incoming request so that bubles can be inserted.
    always @(posedge Clk_MPMC) begin
      if (Rst_MPMC) begin
        PI_AddrReq_internal <= 1'b0;
      end else begin
        if (PI_AddrAck) begin
          PI_AddrReq_internal <= 1'b0;
        end else begin
          PI_AddrReq_internal <= PI_AddrReq;
        end
      end
    end
    ///////////////////////////////////////////////////////////////////////////////
    //Back-to-back reads on NPI32 with sizes Burst64 can cause buffer overruns
    always @(read_transfer or MCB_cmd_full or PI_AddrReq_internal or PI_AddrReq or num_xfers_in_fifo_eq_zero) begin
      if (read_transfer) begin
        PI_AddrAck = !MCB_cmd_full && PI_AddrReq_internal && num_xfers_in_fifo_eq_zero;
      end else begin
        PI_AddrAck = !MCB_cmd_full && PI_AddrReq;
      end
    end
  end else if (P_VFBC_BASETYPE == 1) begin : VFBC_CASE
    always @(read_transfer or MCB_cmd_full or PI_AddrReq or num_xfers_in_fifo_lte_one) begin
      if (read_transfer) begin
        PI_AddrAck = !MCB_cmd_full && PI_AddrReq && num_xfers_in_fifo_lte_one;
      end else begin
        PI_AddrAck = !MCB_cmd_full && PI_AddrReq;
      end
    end
  end else begin : OTHER_CASE
    always @(read_transfer or MCB_cmd_full or PI_AddrReq or num_xfers_in_fifo_eq_zero) begin
      if (read_transfer) begin
        PI_AddrAck = !MCB_cmd_full && PI_AddrReq && num_xfers_in_fifo_eq_zero;
      end else begin
        PI_AddrAck = !MCB_cmd_full && PI_AddrReq;
      end
    end
  end
endgenerate

///////////////////////////////////////////////////////////////////////////////
//The BL is different base on the NPI width
always @(PI_Size) begin
  case (PI_Size)
    P_NPI_SINGLE  : cmd_bl = P_SINGLE_BEAT_COUNT - 1; //SINGLE
    P_NPI_CL4     : cmd_bl = P_CL4_BEAT_COUNT - 1; //CL4
    P_NPI_CL8     : cmd_bl = P_CL8_BEAT_COUNT - 1; //CL8
    P_NPI_BURST16 : cmd_bl = P_BURST16_BEAT_COUNT - 1; //BL16
    P_NPI_BURST32 : cmd_bl = P_BURST32_BEAT_COUNT - 1; //BL32
    P_NPI_BURST64 : cmd_bl = P_BURST64_BEAT_COUNT - 1; //BL64
    default : cmd_bl = 6'h00;
  endcase
end

///////////////////////////////////////////////////////////////////////////////
//MCB WR channel
generate 
  if (C_PI_BASETYPE == 3) begin : SDMA_PIPELINE
    reg [C_PI_DATA_WIDTH-1:0] pi_wrfifo_data_q;
    reg [C_PI_BE_WIDTH-1:0]   pi_wrfifo_mask_q;
    reg                       pi_wrfifo_push_q;
    ///////////////////////////////////////////////////////////////////////////////
    //Pipeline the write data
    always @(posedge Clk_MPMC) begin
      if (Rst_MPMC) begin
        pi_wrfifo_push_q <= 1'b0;
      end else begin
        pi_wrfifo_push_q <= PI_WrFIFO_Push;
      end
      pi_wrfifo_data_q = PI_WrFIFO_Data;
      pi_wrfifo_mask_q = ~PI_WrFIFO_BE;
    end
    assign MCB_wr_data = pi_wrfifo_data_q;
    assign MCB_wr_mask = pi_wrfifo_mask_q;
    assign MCB_wr_en = pi_wrfifo_push_q;
  end else begin : NO_PIPLINE
    assign MCB_wr_data = PI_WrFIFO_Data;
    assign MCB_wr_mask = ~PI_WrFIFO_BE;
    assign MCB_wr_en = PI_WrFIFO_Push;
  end
endgenerate

///////////////////////////////////////////////////////////////////////////////
//MCB RD channel
assign MCB_rd_en = pop_to_mcb;

endmodule
`default_nettype wire
