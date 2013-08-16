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
// MPMC Data Path
//-------------------------------------------------------------------------

// Description:    
//   Data Path for MPMC
//
// Structure:
//   mpmc_data_path
//     mpmc_write_fifo
//       mpmc_bram_fifo
//         mpmc_ramb16_sx_sx
//       mpmc_srl_fifo
//     mpmc_read_fifo
//       mpmc_bram_fifo
//         mpmc_ramb16_sx_sx
//       mpmc_srl_fifo
//     
//--------------------------------------------------------------------------
//
// History:
//   06/15/2007 Initial Version
//
//--------------------------------------------------------------------------
`timescale 1ns/1ns

module mpmc_read_fifo #
  (
   parameter         C_FAMILY         = "virtex4",
   parameter         C_FIFO_TYPE      = 2'b11,  // BRAM (2'b11) or SRL (2'b10)
   parameter         C_PI_PIPELINE    = 1'b1,
   parameter         C_MEM_PIPELINE   = 1'b1,
   parameter integer C_PI_ADDR_WIDTH  =   32,
   parameter integer C_PI_DATA_WIDTH  =   64,
   parameter integer C_MEM_DATA_WIDTH =  128,
   parameter         C_IS_DDR         = 1'b1
   )
  (
   // Clocks and Resets
   input                         Clk,
   input                         Rst,
   // Port Interface Control Signal Inputs
   input                         AddrAck,
   input                         RNW,
   input  [3:0]                  Size,
   input  [C_PI_ADDR_WIDTH-1:0]  Addr,
   // Read FIFO Control Signal Inputs
   input                         Flush,
   input                         Push,
   input                         Pop,
   // Read FIFO Control Signal Outputs
   output                        Empty,
   output                        AlmostFull,
   // Read FIFO Data Signals
   input  [C_MEM_DATA_WIDTH-1:0] PushData,
   output [C_PI_DATA_WIDTH-1:0]  PopData,
   output [3:0]                  RdWdAddr
   );

   localparam P_INPUT_DATA_WIDTH  = C_MEM_DATA_WIDTH;
   localparam P_OUTPUT_DATA_WIDTH = C_PI_DATA_WIDTH;
   localparam P_INPUT_PIPELINE    = C_MEM_PIPELINE;
   localparam P_OUTPUT_PIPELINE   = C_PI_PIPELINE;
  
   localparam P_WORD_XFER_SPECIAL_CASE = 
            ((P_INPUT_DATA_WIDTH ==   8) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==   8) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  16) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  16) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  32) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  32) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
                                                                            0;

   localparam P_DOUBLEWORD_XFER_SPECIAL_CASE = 
            ((P_INPUT_DATA_WIDTH ==   8) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  16) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  32) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH ==  64) && (P_OUTPUT_DATA_WIDTH == 128)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==   8)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  32)) ? 1 :
            ((P_INPUT_DATA_WIDTH == 128) && (P_OUTPUT_DATA_WIDTH ==  64)) ? 1 :
                                                                            0;
   localparam P_FIFO_ADDR_WIDTH =
        (C_FIFO_TYPE == 2'b11) ?
        (((P_INPUT_DATA_WIDTH  == 128) || (P_OUTPUT_DATA_WIDTH == 128)) ? 10 :
         ((P_INPUT_DATA_WIDTH  ==  64) || (P_OUTPUT_DATA_WIDTH ==  64)) ? 10 :
         ((P_INPUT_DATA_WIDTH  ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ? 10 :
                                                                           0) :
        (((P_INPUT_DATA_WIDTH  >=  64) || (P_OUTPUT_DATA_WIDTH >=  64)) ?  8 :
         ((P_INPUT_DATA_WIDTH  ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ?  7 :
                                                                           0);
   /*
   localparam P_FIFO_ADDR_WIDTH =
        (C_FIFO_TYPE == 2'b11) ?
        (((P_INPUT_DATA_WIDTH  == 128) || (P_OUTPUT_DATA_WIDTH == 128)) ? 13 :
         ((P_INPUT_DATA_WIDTH  ==  64) || (P_OUTPUT_DATA_WIDTH ==  64)) ? 12 :
         ((P_INPUT_DATA_WIDTH  ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ? 11 :
                                                                           0) :
        (((P_INPUT_DATA_WIDTH  >=  64) || (P_OUTPUT_DATA_WIDTH >=  64)) ?  8 :
         ((P_INPUT_DATA_WIDTH  ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ?  7 :
                                                                           0);
   */
   localparam P_PUSH_INC_VALUE = (P_INPUT_DATA_WIDTH ==   8) ?  1'd1 :
                                 (P_INPUT_DATA_WIDTH ==  16) ?  2'd2 :
                                 (P_INPUT_DATA_WIDTH ==  32) ?  3'd4 :
                                 (P_INPUT_DATA_WIDTH ==  64) ?  4'd8 :
                                 (P_INPUT_DATA_WIDTH == 128) ? 5'd16 :
                                                                1'd0;
   localparam P_POP_INC_VALUE = (P_OUTPUT_DATA_WIDTH ==   8) ?  1'd1 :
                                (P_OUTPUT_DATA_WIDTH ==  16) ?  2'd2 :
                                (P_OUTPUT_DATA_WIDTH ==  32) ?  3'd4 :
                                (P_OUTPUT_DATA_WIDTH ==  64) ?  4'd8 :
                                (P_OUTPUT_DATA_WIDTH == 128) ? 5'd16 :
                                                                0;
   localparam P_POP_LSBS_MAX_BIT = (P_INPUT_DATA_WIDTH == 128) ? 3 :
                                   (P_INPUT_DATA_WIDTH ==  64) ? 2 :
                                                                 0;
   localparam P_POP_LSBS_MIN_BIT = (P_OUTPUT_DATA_WIDTH == 64) ? 3 :
                                   (P_OUTPUT_DATA_WIDTH == 32) ? 2 :
                                                                 0;
   localparam P_POP_LSBS_NUM_BITS = 
                             ((P_POP_LSBS_MAX_BIT-P_POP_LSBS_MIN_BIT+1) == 0) ?
                             1 : 
                             P_POP_LSBS_MAX_BIT-P_POP_LSBS_MIN_BIT+1;

   localparam P_FIFOADDR_MIN_BIT = 
            ((P_INPUT_DATA_WIDTH == 128) || (P_OUTPUT_DATA_WIDTH == 128)) ? 4 :
            ((P_INPUT_DATA_WIDTH ==  64) || (P_OUTPUT_DATA_WIDTH ==  64)) ? 3 :
            ((P_INPUT_DATA_WIDTH ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ? 2 :
            ((P_INPUT_DATA_WIDTH ==  16) || (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
                                                                            0;
   localparam P_USE_SRL_CTRL_FIFO = 0;
   
   reg [4:0]                   num_xfers_in_fifo;
   wire                        idle;
   reg                         idle_d1;
   wire [4:0]                  xfer_fifo_addr;
   reg                         xfer_fifo_addr_we;
   reg [6:0]                   lutaddr_baseaddr_i;
   reg [6:0]                   lutaddr_highaddr_i;
   wire [6:0]                  lutaddr_baseaddr;
   wire [6:0]                  lutaddr_highaddr;
   reg [6:0]                   lutaddr_highaddr_d1;
   reg [6:0]                   lutaddr;
   wire                        last_pop;
   reg                         last_pop_d1;
   reg [3:0]                   rdwdaddr_i;
   reg [P_FIFO_ADDR_WIDTH:0]   pushaddr;
   reg [P_FIFO_ADDR_WIDTH:0]   popaddr;
   reg [P_FIFO_ADDR_WIDTH:0]   pushaddr_r;
   wire                        specialcasexfer_i;
   wire                        specialcasexfer;
   reg                         almostfull_i;
   reg [1:0]                   xfer_fifo_pushaddr;
   reg [1:0]                   xfer_fifo_popaddr;
   reg [P_POP_LSBS_NUM_BITS-1:0] next_pop_lsbs_i2a = 0;
   reg [P_POP_LSBS_NUM_BITS-1:0] next_pop_lsbs_i2b = 0;
   reg [P_POP_LSBS_NUM_BITS-1:0] next_pop_lsbs_i2c = 0;
   reg [P_POP_LSBS_NUM_BITS-1:0] next_pop_lsbs_i2d = 0;
   reg [P_POP_LSBS_NUM_BITS-1:0] next_pop_lsbs_i3 = 0;
   reg [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue_i3a = 0;
   reg [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue_i3b = 0;
   reg [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue_i3c = 0;
   reg [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue_i3d = 0;
   reg [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue_i4 = 0;
   reg                           flush_d1;
   wire                          flush_p;
  
   //reg                         push_r;
   //reg [P_FIFO_ADDR_WIDTH:0]   fifoaddr_empty;
   
   // Ensure that the RdWdAddr FIFO is not blocked 
   always @(posedge Clk) begin
     flush_d1 <= Flush;
   end
   assign flush_p = Flush & ~flush_d1;

   // Calculate the number of xfers in the transaction FIFO
   always @(posedge Clk) begin
      if (Rst | flush_p)
        num_xfers_in_fifo <= 0;
      else if ((xfer_fifo_addr_we) & (Pop & last_pop))
        num_xfers_in_fifo <= num_xfers_in_fifo;
      else if (Pop & last_pop)
        num_xfers_in_fifo <= num_xfers_in_fifo - 1'd1;
      else if (xfer_fifo_addr_we)
        num_xfers_in_fifo <= num_xfers_in_fifo + 1'd1;
   end
   
   // Calculate whether the read FIFOs are idle
   assign idle = (num_xfers_in_fifo == 0) ? 1'b1 : 1'b0;
   always @(posedge Clk) begin
      idle_d1 <= idle;
   end
   
   // Instantiate the transaction FIFO
   always @(posedge Clk) begin
      xfer_fifo_addr_we <= AddrAck & RNW;
   end
   generate
      if (P_USE_SRL_CTRL_FIFO == 1) begin : gen_xfer_fifo_addr_srl
        mpmc_rdcntr 
          xfer_fifo_addr_0
            (
             .rclk   (Clk),
             .rst    (Rst | flush_p),
             .wen    (xfer_fifo_addr_we),
             .ren    (Pop & last_pop),
             .raddr  (xfer_fifo_addr),
             .full   (),
             .exists ()
             );
      end
      else begin : gen_xfer_fifo_addr
        always @(posedge Clk) begin
          if (Rst | flush_p)
            xfer_fifo_pushaddr <= 0;
          else if (xfer_fifo_addr_we)
            xfer_fifo_pushaddr <= xfer_fifo_pushaddr + 1'd1;

          if (Rst | flush_p)
            xfer_fifo_popaddr <= 0;
          else if (Pop & last_pop)
            xfer_fifo_popaddr <= xfer_fifo_popaddr + 1'd1;

        end
      end
   endgenerate
   generate
      if (C_IS_DDR) begin : gen_ddr
         if (P_OUTPUT_DATA_WIDTH == 32) begin : gen_lutaddr_baseaddr_32bit
            if (P_INPUT_DATA_WIDTH == 64) begin : gen_special_64bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 22;
                    1 : lutaddr_baseaddr_i <= 0 + {Addr[3],1'b0};
                    2 : lutaddr_baseaddr_i <= 7 + {Addr[4],2'b0};
                    3 : lutaddr_baseaddr_i <= 22;
                    4 : lutaddr_baseaddr_i <= 22;
                    5 : lutaddr_baseaddr_i <= 22;
                    default : lutaddr_baseaddr_i <= 22;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 22;
                    1 : lutaddr_highaddr_i <= 3  + {Addr[3],1'b0};
                    2 : lutaddr_highaddr_i <= 14 + {Addr[4],2'b0};
                    3 : lutaddr_highaddr_i <= 37;
                    4 : lutaddr_highaddr_i <= 53;
                    5 : lutaddr_highaddr_i <= 85;
                    default : lutaddr_highaddr_i <= 22;
                  endcase
               end
            end
            else if (P_INPUT_DATA_WIDTH == 128) begin : gen_special_128bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 22;
                    1 : lutaddr_baseaddr_i <= 0;
                    2 : lutaddr_baseaddr_i <= 7 + {Addr[4],2'b0};
                    3 : lutaddr_baseaddr_i <= 22;
                    4 : lutaddr_baseaddr_i <= 22;
                    5 : lutaddr_baseaddr_i <= 22;
                    default : lutaddr_baseaddr_i <= 22;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 22;
                    1 : lutaddr_highaddr_i <= 3;
                    2 : lutaddr_highaddr_i <= 14 + {Addr[4],2'b0};
                    3 : lutaddr_highaddr_i <= 37;
                    4 : lutaddr_highaddr_i <= 53;
                    5 : lutaddr_highaddr_i <= 85;
                    default : lutaddr_highaddr_i <= 22;
                  endcase
               end
            end
            else begin : gen_normal
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 22;
                    1 : lutaddr_baseaddr_i <= 0 + {Addr[3],1'b0};
                    2 : lutaddr_baseaddr_i <= 7 + {Addr[4:3],1'b0};
                    3 : lutaddr_baseaddr_i <= 22;
                    4 : lutaddr_baseaddr_i <= 22;
                    5 : lutaddr_baseaddr_i <= 22;
                    default : lutaddr_baseaddr_i <= 22;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 22;
                    1 : lutaddr_highaddr_i <= 3  + {Addr[3],1'b0};
                    2 : lutaddr_highaddr_i <= 14 + {Addr[4:3],1'b0};
                    3 : lutaddr_highaddr_i <= 37;
                    4 : lutaddr_highaddr_i <= 53;
                    5 : lutaddr_highaddr_i <= 85;
                    default : lutaddr_highaddr_i <= 22;
                  endcase
               end
            end
         end
         else if (P_OUTPUT_DATA_WIDTH == 64) begin : gen_lutaddr_baseaddr_64bit
            if (P_INPUT_DATA_WIDTH == 64) begin : gen_special_64bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 10;
                    1 : lutaddr_baseaddr_i <= 0 + Addr[3];
                    2 : lutaddr_baseaddr_i <= 3 + {Addr[4],1'b0};
                    3 : lutaddr_baseaddr_i <= 10;
                    4 : lutaddr_baseaddr_i <= 10;
                    5 : lutaddr_baseaddr_i <= 10;
                    default : lutaddr_baseaddr_i <= 10;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 10;
                    1 : lutaddr_highaddr_i <= 1 + Addr[3];
                    2 : lutaddr_highaddr_i <= 6 + {Addr[4],1'b0};
                    3 : lutaddr_highaddr_i <= 17;
                    4 : lutaddr_highaddr_i <= 25;
                    5 : lutaddr_highaddr_i <= 41;
                    default : lutaddr_highaddr_i <= 10;
                  endcase
               end
            end
            else if (P_INPUT_DATA_WIDTH == 128) begin : gen_special_128bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 10;
                    1 : lutaddr_baseaddr_i <= 0;
                    2 : lutaddr_baseaddr_i <= 3 + {Addr[4],1'b0};
                    3 : lutaddr_baseaddr_i <= 10;
                    4 : lutaddr_baseaddr_i <= 10;
                    5 : lutaddr_baseaddr_i <= 10;
                    default : lutaddr_baseaddr_i <= 10;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 10;
                    1 : lutaddr_highaddr_i <= 1;
                    2 : lutaddr_highaddr_i <= 6 + {Addr[4],1'b0};
                    3 : lutaddr_highaddr_i <= 17;
                    4 : lutaddr_highaddr_i <= 25;
                    5 : lutaddr_highaddr_i <= 41;
                    default : lutaddr_highaddr_i <= 10;
                  endcase
               end
            end
            else begin : gen_normal
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 10;
                    1 : lutaddr_baseaddr_i <= 0 + Addr[3];
                    2 : lutaddr_baseaddr_i <= 3 + Addr[4:3];
                    3 : lutaddr_baseaddr_i <= 10;
                    4 : lutaddr_baseaddr_i <= 10;
                    5 : lutaddr_baseaddr_i <= 10;
                    default : lutaddr_baseaddr_i <= 10;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 10;
                    1 : lutaddr_highaddr_i <= 1 + Addr[3];
                    2 : lutaddr_highaddr_i <= 6 + Addr[4:3];
                    3 : lutaddr_highaddr_i <= 17;
                    4 : lutaddr_highaddr_i <= 25;
                    5 : lutaddr_highaddr_i <= 41;
                    default : lutaddr_highaddr_i <= 10;
                  endcase
               end
            end
         end
         else begin : gen_lutaddr_baseaddr_not_supported
         end
      end
      else begin : gen_sdr
         if (P_OUTPUT_DATA_WIDTH == 32) begin : gen_lutaddr_baseaddr_32bit
            if (P_INPUT_DATA_WIDTH == 32) begin : gen_special_32bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 22;
                    1 : lutaddr_baseaddr_i <= 0 + {Addr[3],1'b0};
                    2 : lutaddr_baseaddr_i <= 7 + {Addr[4],2'b0};
                    3 : lutaddr_baseaddr_i <= 22;
                    4 : lutaddr_baseaddr_i <= 22;
                    5 : lutaddr_baseaddr_i <= 22;
                    default : lutaddr_baseaddr_i <= 22;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 22;
                    1 : lutaddr_highaddr_i <= 3  + {Addr[3],1'b0};
                    2 : lutaddr_highaddr_i <= 14 + {Addr[4],2'b0};
                    3 : lutaddr_highaddr_i <= 37;
                    4 : lutaddr_highaddr_i <= 53;
                    5 : lutaddr_highaddr_i <= 85;
                    default : lutaddr_highaddr_i <= 22;
                  endcase
               end
            end
            else if (P_INPUT_DATA_WIDTH == 64) begin : gen_special_64bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 22;
                    1 : lutaddr_baseaddr_i <= 0;
                    2 : lutaddr_baseaddr_i <= 7 + {Addr[4],2'b0};
                    3 : lutaddr_baseaddr_i <= 22;
                    4 : lutaddr_baseaddr_i <= 22;
                    5 : lutaddr_baseaddr_i <= 22;
                    default : lutaddr_baseaddr_i <= 22;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 22;
                    1 : lutaddr_highaddr_i <= 3;
                    2 : lutaddr_highaddr_i <= 14 + {Addr[4],2'b0};
                    3 : lutaddr_highaddr_i <= 37;
                    4 : lutaddr_highaddr_i <= 53;
                    5 : lutaddr_highaddr_i <= 85;
                    default : lutaddr_highaddr_i <= 22;
                  endcase
               end
            end
            else if (P_INPUT_DATA_WIDTH == 128) begin : gen_special_128bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 22;
                    1 : lutaddr_baseaddr_i <= 0;
                    2 : lutaddr_baseaddr_i <= 7 + {Addr[4],2'b0};
                    3 : lutaddr_baseaddr_i <= 22;
                    4 : lutaddr_baseaddr_i <= 22;
                    5 : lutaddr_baseaddr_i <= 22;
                    default : lutaddr_baseaddr_i <= 22;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 22;
                    1 : lutaddr_highaddr_i <= 3;
                    2 : lutaddr_highaddr_i <= 14 + {Addr[4],2'b0};
                    3 : lutaddr_highaddr_i <= 37;
                    4 : lutaddr_highaddr_i <= 53;
                    5 : lutaddr_highaddr_i <= 85;
                    default : lutaddr_highaddr_i <= 22;
                  endcase
               end
            end
            else begin : gen_normal
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 22;
                    1 : lutaddr_baseaddr_i <= 0 + {Addr[3],1'b0};
                    2 : lutaddr_baseaddr_i <= 7 + {Addr[4:3],1'b0};
                    3 : lutaddr_baseaddr_i <= 22;
                    4 : lutaddr_baseaddr_i <= 22;
                    5 : lutaddr_baseaddr_i <= 22;
                    default : lutaddr_baseaddr_i <= 22;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 22;
                    1 : lutaddr_highaddr_i <= 3  + {Addr[3],1'b0};
                    2 : lutaddr_highaddr_i <= 14 + {Addr[4:3],1'b0};
                    3 : lutaddr_highaddr_i <= 37;
                    4 : lutaddr_highaddr_i <= 53;
                    5 : lutaddr_highaddr_i <= 85;
                    default : lutaddr_highaddr_i <= 22;
                  endcase
               end
            end
         end
         else if (P_OUTPUT_DATA_WIDTH == 64) begin : gen_lutaddr_baseaddr_64bit
            if (P_INPUT_DATA_WIDTH == 32) begin : gen_special_32bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 10;
                    1 : lutaddr_baseaddr_i <= 0 + Addr[3];
                    2 : lutaddr_baseaddr_i <= 3 + {Addr[4],1'b0};
                    3 : lutaddr_baseaddr_i <= 10;
                    4 : lutaddr_baseaddr_i <= 10;
                    5 : lutaddr_baseaddr_i <= 10;
                    default : lutaddr_baseaddr_i <= 10;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 10;
                    1 : lutaddr_highaddr_i <= 1 + Addr[3];
                    2 : lutaddr_highaddr_i <= 6 + {Addr[4],1'b0};
                    3 : lutaddr_highaddr_i <= 17;
                    4 : lutaddr_highaddr_i <= 25;
                    5 : lutaddr_highaddr_i <= 41;
                    default : lutaddr_highaddr_i <= 10;
                  endcase
               end
            end
           else if (P_INPUT_DATA_WIDTH == 64) begin : gen_special_64bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 10;
                    1 : lutaddr_baseaddr_i <= 0;
                    2 : lutaddr_baseaddr_i <= 3 + {Addr[4],1'b0};
                    3 : lutaddr_baseaddr_i <= 10;
                    4 : lutaddr_baseaddr_i <= 10;
                    5 : lutaddr_baseaddr_i <= 10;
                    default : lutaddr_baseaddr_i <= 10;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 10;
                    1 : lutaddr_highaddr_i <= 1;
                    2 : lutaddr_highaddr_i <= 6 + {Addr[4],1'b0};
                    3 : lutaddr_highaddr_i <= 17;
                    4 : lutaddr_highaddr_i <= 25;
                    5 : lutaddr_highaddr_i <= 41;
                    default : lutaddr_highaddr_i <= 10;
                  endcase
               end
            end
            else if (P_INPUT_DATA_WIDTH == 128) begin : gen_special_128bit
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 10;
                    1 : lutaddr_baseaddr_i <= 0;
                    2 : lutaddr_baseaddr_i <= 3 + {Addr[4],1'b0};
                    3 : lutaddr_baseaddr_i <= 10;
                    4 : lutaddr_baseaddr_i <= 10;
                    5 : lutaddr_baseaddr_i <= 10;
                    default : lutaddr_baseaddr_i <= 10;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 10;
                    1 : lutaddr_highaddr_i <= 1;
                    2 : lutaddr_highaddr_i <= 6 + {Addr[4],1'b0};
                    3 : lutaddr_highaddr_i <= 17;
                    4 : lutaddr_highaddr_i <= 25;
                    5 : lutaddr_highaddr_i <= 41;
                    default : lutaddr_highaddr_i <= 10;
                  endcase
               end
            end
            else begin : gen_normal
               // Calculate the baseaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_baseaddr_i <= 10;
                    1 : lutaddr_baseaddr_i <= 0 + Addr[3];
                    2 : lutaddr_baseaddr_i <= 3 + Addr[4:3];
                    3 : lutaddr_baseaddr_i <= 10;
                    4 : lutaddr_baseaddr_i <= 10;
                    5 : lutaddr_baseaddr_i <= 10;
                    default : lutaddr_baseaddr_i <= 10;
                  endcase
               end
               // Calculate the highaddr for the RdWdAddr LUT
               always @(*) begin
                  case (Size)
                    0 : lutaddr_highaddr_i <= 10;
                    1 : lutaddr_highaddr_i <= 1 + Addr[3];
                    2 : lutaddr_highaddr_i <= 6 + Addr[4:3];
                    3 : lutaddr_highaddr_i <= 17;
                    4 : lutaddr_highaddr_i <= 25;
                    5 : lutaddr_highaddr_i <= 41;
                    default : lutaddr_highaddr_i <= 10;
                  endcase
               end
            end
         end
         else begin : gen_lutaddr_baseaddr_not_supported
         end
      end
   endgenerate
   
  reg [6:0] lutaddr_baseaddr_i2;
  reg [6:0] lutaddr_highaddr_i2;
  reg       specialcasexfer_i2;
  always @(posedge Clk) begin
    lutaddr_baseaddr_i2 <= lutaddr_baseaddr_i;
    lutaddr_highaddr_i2 <= lutaddr_highaddr_i;
    specialcasexfer_i2  <= specialcasexfer_i;
  end
   generate
      if (P_USE_SRL_CTRL_FIFO == 1) begin : gen_xfer_fifo_srls
        SRL16E
          xfer_fifo_srls_0[7+7+1-1:0]
            (
             .CLK (Clk), 
             .CE  (xfer_fifo_addr_we),
             .A0  (xfer_fifo_addr[0]), 
             .A1  (xfer_fifo_addr[1]), 
             .A2  (xfer_fifo_addr[2]),
             .A3  (xfer_fifo_addr[3]), 
             .D   ({lutaddr_baseaddr_i2,lutaddr_highaddr_i2,specialcasexfer_i2}), 
             .Q   ({lutaddr_baseaddr,lutaddr_highaddr,specialcasexfer})
             );
      end
      else begin : gen_xfer_fifo
        reg [6:0] lutaddr_baseaddr_i2a;
        reg [6:0] lutaddr_baseaddr_i2b;
        reg [6:0] lutaddr_baseaddr_i2c;
        reg [6:0] lutaddr_baseaddr_i2d;
        reg [6:0] lutaddr_baseaddr_i3;
        reg [6:0] lutaddr_highaddr_i2a;
        reg [6:0] lutaddr_highaddr_i2b;
        reg [6:0] lutaddr_highaddr_i2c;
        reg [6:0] lutaddr_highaddr_i2d;
        reg [6:0] lutaddr_highaddr_i3;
        reg       specialcasexfer_i2a;
        reg       specialcasexfer_i2b;
        reg       specialcasexfer_i2c;
        reg       specialcasexfer_i2d;
        reg       specialcasexfer_i3;
        always @(posedge Clk) begin
          if (xfer_fifo_addr_we) begin
            case (xfer_fifo_pushaddr)
              0 : 
                begin 
                  lutaddr_baseaddr_i2a <= lutaddr_baseaddr_i2;
                  lutaddr_highaddr_i2a <= lutaddr_highaddr_i2;
                  specialcasexfer_i2a  <= specialcasexfer_i2;
                end
              1 : 
                begin 
                  lutaddr_baseaddr_i2b <= lutaddr_baseaddr_i2;
                  lutaddr_highaddr_i2b <= lutaddr_highaddr_i2;
                  specialcasexfer_i2b  <= specialcasexfer_i2;
                end
              2 : 
                begin 
                  lutaddr_baseaddr_i2c <= lutaddr_baseaddr_i2;
                  lutaddr_highaddr_i2c <= lutaddr_highaddr_i2;
                  specialcasexfer_i2c  <= specialcasexfer_i2;
                end
              3 : 
                begin 
                  lutaddr_baseaddr_i2d <= lutaddr_baseaddr_i2;
                  lutaddr_highaddr_i2d <= lutaddr_highaddr_i2;
                  specialcasexfer_i2d  <= specialcasexfer_i2;
                end
            endcase
          end
        end
        always @(*) begin
          case (xfer_fifo_popaddr)
            0 : 
              begin
                lutaddr_baseaddr_i3 <= lutaddr_baseaddr_i2a;
                lutaddr_highaddr_i3 <= lutaddr_highaddr_i2a;
                specialcasexfer_i3  <= specialcasexfer_i2a;
              end
            1 : 
              begin
                lutaddr_baseaddr_i3 <= lutaddr_baseaddr_i2b;
                lutaddr_highaddr_i3 <= lutaddr_highaddr_i2b;
                specialcasexfer_i3  <= specialcasexfer_i2b;
              end
            2 : 
              begin
                lutaddr_baseaddr_i3 <= lutaddr_baseaddr_i2c;
                lutaddr_highaddr_i3 <= lutaddr_highaddr_i2c;
                specialcasexfer_i3  <= specialcasexfer_i2c;
              end
            3 : 
              begin
                lutaddr_baseaddr_i3 <= lutaddr_baseaddr_i2d;
                lutaddr_highaddr_i3 <= lutaddr_highaddr_i2d;
                specialcasexfer_i3  <= specialcasexfer_i2d;
              end
          endcase
        end
        assign lutaddr_baseaddr = lutaddr_baseaddr_i3;
        assign lutaddr_highaddr = lutaddr_highaddr_i3;
        assign specialcasexfer  = specialcasexfer_i3;
      end
   endgenerate
  
   // Calculate the addr for the RdWdAddr LUT
   always @(posedge Clk) begin
      last_pop_d1 <= Pop & last_pop;
   end
   always @(posedge Clk) begin
      if (Rst | flush_p)
        lutaddr <= 0;
      else if (idle_d1 | last_pop_d1)
        lutaddr <= lutaddr_baseaddr;
      else if (Pop)
        lutaddr <= lutaddr + 1'd1;
   end
   
   // Calculate whether the next pop is the last pop for a particular xfer
   always @(posedge Clk) begin
      lutaddr_highaddr_d1 <= lutaddr_highaddr;
   end
   assign last_pop = (lutaddr_highaddr_d1 == lutaddr) ? 1'b1 : 1'b0;
   
   // Calculate the RdWdAddr
   generate
      if (P_OUTPUT_DATA_WIDTH == 32) begin : gen_rdwdaddr_32bit
         always @(posedge Clk) begin
            case (lutaddr)
              // CL4 Read
              0: rdwdaddr_i <= 4'h0;
              1: rdwdaddr_i <= 4'h1;
              2: rdwdaddr_i <= 4'h2;
              3: rdwdaddr_i <= 4'h3;
              4: rdwdaddr_i <= 4'h0;
              5: rdwdaddr_i <= 4'h1;
              6: rdwdaddr_i <= 4'h2;
              // CL8 Read
              7: rdwdaddr_i <= 4'h0;
              8: rdwdaddr_i <= 4'h1;
              9: rdwdaddr_i <= 4'h2;
              10: rdwdaddr_i <= 4'h3;
              11: rdwdaddr_i <= 4'h4;
              12: rdwdaddr_i <= 4'h5;
              13: rdwdaddr_i <= 4'h6;
              14: rdwdaddr_i <= 4'h7;
              15: rdwdaddr_i <= 4'h0;
              16: rdwdaddr_i <= 4'h1;
              17: rdwdaddr_i <= 4'h2;
              18: rdwdaddr_i <= 4'h3;
              19: rdwdaddr_i <= 4'h4;
              20: rdwdaddr_i <= 4'h5;
              21: rdwdaddr_i <= 4'h6;
              // Word, B16, B32, B64 Read
              default rdwdaddr_i <= 4'h0;
            endcase
         end
      end
      else if (P_OUTPUT_DATA_WIDTH == 64) begin : gen_rdwdaddr_64bit
         always @(posedge Clk) begin
            case (lutaddr)
              // CL4 Read
              0: rdwdaddr_i <= 4'h0;
              1: rdwdaddr_i <= 4'h2;
              2: rdwdaddr_i <= 4'h0;
              // CL8 Read
              3: rdwdaddr_i <= 4'h0;
              4: rdwdaddr_i <= 4'h2;
              5: rdwdaddr_i <= 4'h4;
              6: rdwdaddr_i <= 4'h6;
              7: rdwdaddr_i <= 4'h0;
              8: rdwdaddr_i <= 4'h2;
              9: rdwdaddr_i <= 4'h4;
              // Word, B16, B32, B64 Read
              default rdwdaddr_i <= 4'h0;
            endcase
         end
      end
   endgenerate
   // Implement Optional Output Pipelines for RdWdAddr
   generate
      if (P_OUTPUT_PIPELINE == 1) begin : gen_rdwdaddr_pipeline
         reg [3:0] rdwdaddr_i2;
         always @(posedge Clk)
           rdwdaddr_i2 <= rdwdaddr_i;
         assign RdWdAddr = rdwdaddr_i2;
      end
      else begin : gen_rdwdaddr_nopipeline
         assign RdWdAddr = rdwdaddr_i;
      end
   endgenerate
   // Calculate the pushaddr
   always @(posedge Clk) begin
      if (Rst | Flush)
        pushaddr <= 0;
      else if (Push)
        pushaddr <= pushaddr + P_PUSH_INC_VALUE;
   end
   generate
      if (P_INPUT_PIPELINE == 1) begin : gen_pushaddr_pipeline
         always @(posedge Clk) begin
           if (Rst | Flush)
             pushaddr_r <= 0;
           else
             pushaddr_r <= pushaddr;
            //push_r     <= Push;
         end
      end
      else begin : gen_pushaddr_nopipeline
         always @(*) begin
            pushaddr_r <= pushaddr;
            //push_r     <= Push;
         end
      end
   endgenerate
   // Calculate the popaddr
   generate
      if (((P_OUTPUT_DATA_WIDTH == 64) && 
           (P_DOUBLEWORD_XFER_SPECIAL_CASE == 1)) ||
          ((P_OUTPUT_DATA_WIDTH == 32) && 
           (P_WORD_XFER_SPECIAL_CASE == 1))) begin : gen_popaddr_special_case
         wire [P_POP_LSBS_NUM_BITS-1:0] next_pop_lsbs_i;
         wire [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue_i1;
         wire [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue_i2;
         wire [P_POP_LSBS_NUM_BITS-1:0] next_pop_lsbs;
         wire [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue;
         wire                           next_pop_is_sc_i;
         wire                           next_pop_is_sc;
         reg [P_FIFO_ADDR_WIDTH:0]      popaddr_i;
         // Logic to designate that there is a special case word read
         assign specialcasexfer_i = RNW & (Size == 4'b0);
         // Logic to skip addresses in data FIFO during word xfers
         assign next_pop_lsbs_i = 
                Addr[P_POP_LSBS_MAX_BIT:
                     P_POP_LSBS_MIN_BIT] &
                {P_POP_LSBS_NUM_BITS{(Size==4'b0) ? 1'b1 : 1'b0}};
         assign next_pop_incvalue_i1 = 
                    {1'b1,{P_POP_LSBS_MAX_BIT+1{1'b0}}} - 
                    {1'b0,Addr[P_POP_LSBS_MAX_BIT:P_POP_LSBS_MIN_BIT],
                     {P_POP_LSBS_MIN_BIT{1'b0}}};
         assign next_pop_incvalue_i2 = 
                (Size==4'h0) ? next_pop_incvalue_i1 : P_POP_INC_VALUE;
         //assign next_pop_is_sc_i = (Size==4'h0) ? 1'b1 : 1'b0;
        reg [P_POP_LSBS_NUM_BITS-1:0] next_pop_lsbs_i2;
        reg [P_POP_LSBS_MAX_BIT+1:0]  next_pop_incvalue_i3;
        always @(posedge Clk) begin
          next_pop_lsbs_i2 <= next_pop_lsbs_i;
          next_pop_incvalue_i3 <= next_pop_incvalue_i2;
        end
         if (P_USE_SRL_CTRL_FIFO == 1) begin : gen_xfer_fifo_srls
           SRL16E
             xfer_fifo_srls_0[P_POP_LSBS_NUM_BITS+P_POP_LSBS_MAX_BIT+1:0]
               (
                .CLK (Clk), 
                .CE  (xfer_fifo_addr_we),
                .A0  (xfer_fifo_addr[0]), 
                .A1  (xfer_fifo_addr[1]), 
                .A2  (xfer_fifo_addr[2]),
                .A3  (xfer_fifo_addr[3]), 
                .D   ({next_pop_lsbs_i2,next_pop_incvalue_i3}), 
                .Q   ({next_pop_lsbs,next_pop_incvalue})
                );
         end
         else begin : gen_xfer_fifo
           always @(posedge Clk) begin
             if (xfer_fifo_addr_we) begin
               case (xfer_fifo_pushaddr)
                 0 :  
                   begin 
                     next_pop_lsbs_i2a     <= next_pop_lsbs_i2;
                     next_pop_incvalue_i3a <= next_pop_incvalue_i3;
                   end
                 1 : 
                   begin 
                     next_pop_lsbs_i2b     <= next_pop_lsbs_i2;
                     next_pop_incvalue_i3b <= next_pop_incvalue_i3;
                   end
                 2 : 
                   begin 
                     next_pop_lsbs_i2c     <= next_pop_lsbs_i2;
                     next_pop_incvalue_i3c <= next_pop_incvalue_i3;
                   end
                 3 : 
                   begin 
                     next_pop_lsbs_i2d     <= next_pop_lsbs_i2;
                     next_pop_incvalue_i3d <= next_pop_incvalue_i3;
                   end
               endcase
             end
           end
           always @(*) begin
             case (xfer_fifo_popaddr)
               0 : 
                 begin
                   next_pop_lsbs_i3     <= next_pop_lsbs_i2a;
                   next_pop_incvalue_i4 <= next_pop_incvalue_i3a;
                 end
               1 : 
                 begin
                   next_pop_lsbs_i3     <= next_pop_lsbs_i2b;
                   next_pop_incvalue_i4 <= next_pop_incvalue_i3b;
                 end
               2 : 
                 begin
                   next_pop_lsbs_i3     <= next_pop_lsbs_i2c;
                   next_pop_incvalue_i4 <= next_pop_incvalue_i3c;
                 end
               3 : 
                 begin
                   next_pop_lsbs_i3     <= next_pop_lsbs_i2d;
                   next_pop_incvalue_i4 <= next_pop_incvalue_i3d;
                 end
             endcase
           end
           assign next_pop_lsbs = next_pop_lsbs_i3;
           assign next_pop_incvalue = next_pop_incvalue_i4;
         end
         always @(posedge Clk) begin
            if (Rst | Flush)
              popaddr_i <= 0;
            else if (Pop)
              popaddr_i <= popaddr + next_pop_incvalue;
         end
         always @(*) begin
            popaddr <= 
                  (next_pop_lsbs == 0) ? 
                  popaddr_i :
                  {popaddr_i[P_FIFO_ADDR_WIDTH:P_POP_LSBS_MAX_BIT+1],
                   next_pop_lsbs,
                   {P_POP_LSBS_MIN_BIT{1'b0}}};
         end
         /*
         // This has poor timing.
         always @(posedge Clk) begin
            if (Rst || Flush)
              fifoaddr_empty <= 0;
            else if (push_r && Pop && next_pop_is_sc)
              fifoaddr_empty <= fifoaddr_empty;
            else if (push_r && Pop)
              fifoaddr_empty <= fifoaddr_empty +
                                P_PUSH_INC_VALUE - P_POP_INC_VALUE;
            else if (push_r && ~Pop)
              fifoaddr_empty <= fifoaddr_empty + P_PUSH_INC_VALUE;
            else if (~push_r && Pop && next_pop_is_sc)
              fifoaddr_empty <= fifoaddr_empty - P_PUSH_INC_VALUE;
            else if (~push_r && Pop)
              fifoaddr_empty <= fifoaddr_empty - P_POP_INC_VALUE;
         end
         */
      end
      else begin : gen_popaddr_normal
         assign specialcasexfer_i = 1'b0;
         always @(posedge Clk) begin
            if (Rst | Flush)
              popaddr <= 0;
            else if (Pop)
              popaddr <= popaddr + P_POP_INC_VALUE;
         end
         /*
         // This has poor timing.
         always @(posedge Clk) begin
            if (Rst || Flush)
              fifoaddr_empty <= 0;
            else if (push_r && Pop)
              fifoaddr_empty <= fifoaddr_empty +
                                P_PUSH_INC_VALUE - P_POP_INC_VALUE;
            else if (push_r && ~Pop)
              fifoaddr_empty <= fifoaddr_empty + P_PUSH_INC_VALUE;
            else if (~push_r && Pop)
              fifoaddr_empty <= fifoaddr_empty - P_POP_INC_VALUE;
         end
         */
      end
   endgenerate

   // Calculate the empty flag
   assign Empty = (pushaddr_r[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT] == 
                   popaddr[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]) ? 
                  1'b1 : 
                  last_pop_d1;
   /*
   // This version makes timing worse due to nasty adders and comparators.
   // Improve timing by registering empty flag
   localparam P_FIFOADDR_MIN_BIT = 
            ((P_INPUT_DATA_WIDTH == 128) || (P_OUTPUT_DATA_WIDTH == 128)) ? 4 :
            ((P_INPUT_DATA_WIDTH ==  64) || (P_OUTPUT_DATA_WIDTH ==  64)) ? 3 :
            ((P_INPUT_DATA_WIDTH ==  32) || (P_OUTPUT_DATA_WIDTH ==  32)) ? 2 :
            ((P_INPUT_DATA_WIDTH ==  16) || (P_OUTPUT_DATA_WIDTH ==  16)) ? 1 :
                                                                            0;
   reg                         empty_i;
   wire [P_FIFO_ADDR_WIDTH:0]  empty_cmp_push;
   wire [P_FIFO_ADDR_WIDTH:0]  empty_cmp_pop;
   assign empty_cmp_push = pushaddr_r+P_PUSH_INC_VALUE;
   assign empty_cmp_pop  = popaddr+P_POP_INC_VALUE;
   always @(posedge Clk) begin
      if (Rst || Flush)
        empty_i <= 1'b1;
      else if (( push_r &&  Pop && 
                ((empty_cmp_push[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]) == 
                 (empty_cmp_pop[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]))) ||
               ( push_r && ~Pop && 
                ((empty_cmp_push[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]) == 
                 (popaddr[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]))) ||
               (~push_r &&  Pop && 
                ((pushaddr_r[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]) == 
                 (empty_cmp_pop[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]))) ||
               (~push_r && ~Pop && 
                ((pushaddr_r[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]) == 
                 (popaddr[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]))))            
        empty_i <= 1'b1;
      else
        empty_i <= Pop & last_pop;
   end
   assign Empty = empty_i;
   */
   /*
   // This version is better, but still makes timing worse.
   // Improve timing by calculating FIFO address.
   localparam P_FIFOADDR_MIN_BIT = (P_OUTPUT_DATA_WIDTH == 128) ? 4 :
                                   (P_OUTPUT_DATA_WIDTH ==  64) ? 3 :
                                   (P_OUTPUT_DATA_WIDTH ==  32) ? 2 :
                                   (P_OUTPUT_DATA_WIDTH ==  16) ? 1 :
                                                                  0;
   assign Empty = (fifoaddr_empty[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT]==0) ? 
                  1'b1 : 
                  last_pop_d1;
   */
   
   // Calculate the almost full flag
   generate
      if (C_FIFO_TYPE == 2'b11) begin : gen_almostfull_bram
         // NPI cannot request more data than is possible for BRAM to hold.
         assign AlmostFull = 1'b0;
         /*
         wire [P_FIFO_ADDR_WIDTH:0] fifoaddr_af;
         assign fifoaddr_af = {pushaddr[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT] -
                               popaddr[P_FIFO_ADDR_WIDTH:P_FIFOADDR_MIN_BIT],
                               {P_FIFOADDR_MIN_BIT{1'b0}}};
         always @(posedge Clk)
           if (Rst || Flush)
             almostfull_i <= 1'b0;
           else if (fifoaddr_af[P_FIFO_ADDR_WIDTH:8] == 
                    {P_FIFO_ADDR_WIDTH-7{1'b1}})
             almostfull_i <= 1'b1;
           else
             almostfull_i <= 1'b0;
         assign AlmostFull = almostfull_i;
         */
      end
      else begin : gen_almostfull_srl
         always @(posedge Clk)
           almostfull_i <= ~Empty;
         assign AlmostFull = almostfull_i;
      end
   endgenerate
   
   // Implement the Data FIFOs
   generate
      if (C_FIFO_TYPE == 2'b11) begin : gen_fifos_bram
         mpmc_bram_fifo #
           (
            .C_FAMILY            (C_FAMILY),
            .C_INPUT_PIPELINE    (P_INPUT_PIPELINE),
            .C_OUTPUT_PIPELINE   (P_OUTPUT_PIPELINE),
            .C_ADDR_WIDTH        (P_FIFO_ADDR_WIDTH),
            .C_INPUT_DATA_WIDTH  (P_INPUT_DATA_WIDTH),
            .C_OUTPUT_DATA_WIDTH (P_OUTPUT_DATA_WIDTH),
            .C_DIRECTION         ("read"),
            .C_USE_INIT_PUSH     (1'b0)
            )
           mpmc_bram_fifo_0
             (
              .PushClk    (Clk),
              .PushAddr   (pushaddr[P_FIFO_ADDR_WIDTH-1:0]),
              .Push       (Push),
              .PushData   (PushData),
              .PushParity ({P_INPUT_DATA_WIDTH/8{1'b0}}),
              .InitPush   (1'b0),
              .InitData   ({P_OUTPUT_DATA_WIDTH{1'b0}}),
              .PopClk     (Clk),
              .PopAddr    (popaddr[P_FIFO_ADDR_WIDTH-1:0]),
              .Pop        (Pop),
              .ParityRst  (1'b0),
              .PopData    (PopData),
              .PopParity  ()
              );
      end
      else begin : gen_fifos_srl
         mpmc_srl_fifo #
           (
            .C_FAMILY            (C_FAMILY),
            .C_INPUT_PIPELINE    (P_INPUT_PIPELINE),
            .C_OUTPUT_PIPELINE   (P_OUTPUT_PIPELINE),
            .C_ADDR_WIDTH        (P_FIFO_ADDR_WIDTH),
            .C_INPUT_DATA_WIDTH  (P_INPUT_DATA_WIDTH),
            .C_OUTPUT_DATA_WIDTH (P_OUTPUT_DATA_WIDTH),
            .C_DIRECTION         ("read"),
            .C_USE_INIT_PUSH     (1'b0)
            )
           mpmc_srl_fifo_0
             (
              .Clk             (Clk),
              .Rst             (Rst | Flush),
              .SpecialCaseXfer (specialcasexfer),
              .PushAddr        (pushaddr[P_FIFO_ADDR_WIDTH-1:0]),
              .Push            (Push),
              .PushData        (PushData),
              .PushParity      ({P_INPUT_DATA_WIDTH/8{1'b0}}),
              .InitDone        (1'b1),
              .InitPush        (1'b0),
              .InitData        ({P_OUTPUT_DATA_WIDTH{1'b0}}),
              .PopAddr         (popaddr[P_FIFO_ADDR_WIDTH-1:0]),
              .Pop             (Pop),
              .ParityRst       (1'b0),
              .PopData         (PopData),
              .PopParity       ()
              );
      end
   endgenerate

endmodule // mpmc_read_fifo

