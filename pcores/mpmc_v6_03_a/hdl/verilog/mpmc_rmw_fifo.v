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
//Purpose:
//   FIFOs used for read-modify-write.
//   Maximum depth of FIFOs is 256 bytes.
//
//Reference:
//Revision History:
//
//-----------------------------------------------------------------------------
`timescale 1ns/1ns

module mpmc_rmw_fifo #
  (
   parameter         C_FAMILY    = "virtex4",
   parameter integer C_WDF_RDEN_EARLY = 0,
   parameter integer C_DATA_WIDTH = 128 // Must be one of: 8,16,32,64,128.
   )
  (
   input                     Clk,
   input                     Rst,
   input                     Push,
   input                     Pop,
   input  [C_DATA_WIDTH-1:0] D,
   output [C_DATA_WIDTH-1:0] Q
   );

   localparam C_USE_BRAM_FIFO = 1'b1;
   localparam C_MAX_FIFO_DEPTH = 256;  // Must be set to 256.
   localparam C_ADDR_WIDTH     = 8;    // Must be set to 8.
   localparam C_PUSH_CNT_VALUE = C_DATA_WIDTH/8; // Count in bytes
   localparam C_POP_CNT_VALUE  = C_DATA_WIDTH/8; // Count in bytes
   
   wire                   pop_i;
   reg                    pop_d1 = 0;
   reg                    pop_d2 = 0;
   reg [C_ADDR_WIDTH:0]   push_addr = {C_ADDR_WIDTH+1{1'b0}};
   reg [C_ADDR_WIDTH:0]   pop_addr  = {C_ADDR_WIDTH+1{1'b0}};

   genvar i;
   
   always @(posedge Clk)
     begin
        pop_d1 <= Pop;
        pop_d2 <= pop_d1;
     end
   generate
      if (C_WDF_RDEN_EARLY == 1)
        begin : gen_pop_early
           assign pop_i = pop_d1;
        end
      else
        begin : gen_pop_normal
           assign pop_i = Pop;
        end
   endgenerate
   
   // On Push, count up by specified number of bytes.
   // Wrap around at 256 bytes.
   always @(posedge Clk)
     begin
        if (Rst)
          push_addr <= {C_ADDR_WIDTH+1{1'b0}};
        else if (Push)
          push_addr <= push_addr + C_PUSH_CNT_VALUE;
     end

   // On Pop, count up by specified number of bytes.
   // Wrap around at 256 bytes.
   always @(posedge Clk)
     begin
        if (Rst)
          pop_addr <= {C_ADDR_WIDTH+1{1'b0}};
        else if (pop_i)
          pop_addr <= pop_addr + C_POP_CNT_VALUE;
     end

   generate
      if (C_DATA_WIDTH == 128)
        begin : gen_fifo_128bit
           for (i=0;i<4;i=i+1)
             begin : gen_rep_fifo
                bram_fifo_32bit
                  bram_fifo_32bit_0
                    (
                     .Clk       (Clk),
                     .Push      (Push),
                     .Push_Addr ({{9-(C_ADDR_WIDTH-4){1'b0}},push_addr[C_ADDR_WIDTH-1:4]}),
                     .D         (D[(i+1)*32-1:i*32]),
                     .Pop       (pop_i),
                     .Pop_Addr  ({{9-(C_ADDR_WIDTH-4){1'b0}},pop_addr[C_ADDR_WIDTH-1:4]}),
                     .Q         (Q[(i+1)*32-1:i*32])
                     );
             end
        end
      else if (C_DATA_WIDTH == 64)
        begin : gen_fifo_64bit
           for (i=0;i<2;i=i+1)
             begin : gen_rep_fifo
                bram_fifo_32bit
                  bram_fifo_32bit_0
                    (
                     .Clk       (Clk),
                     .Push      (Push),
                     .Push_Addr ({{9-(C_ADDR_WIDTH-3){1'b0}},push_addr[C_ADDR_WIDTH-1:3]}),
                     .D         (D[(i+1)*32-1:i*32]),
                     .Pop       (pop_i),
                     .Pop_Addr  ({{9-(C_ADDR_WIDTH-3){1'b0}},pop_addr[C_ADDR_WIDTH-1:3]}),
                     .Q         (Q[(i+1)*32-1:i*32])
                     );
             end
        end
      else if (C_DATA_WIDTH == 32)
        begin : gen_fifo_32bit
           bram_fifo_32bit
             bram_fifo_32bit_0
               (
                .Clk       (Clk),
                .Push      (Push),
                .Push_Addr ({{9-(C_ADDR_WIDTH-2){1'b0}},push_addr[C_ADDR_WIDTH-1:2]}),
                .D         (D[31:0]),
                .Pop       (pop_i),
                .Pop_Addr  ({{9-(C_ADDR_WIDTH-2){1'b0}},pop_addr[C_ADDR_WIDTH-1:2]}),
                .Q         (Q[31:0])
                );
        end
      else if (C_DATA_WIDTH == 16)
        begin : gen_fifo_16bit
	   wire [15:0] Q_tmp;
           bram_fifo_32bit
             bram_fifo_32bit_0
               (
                .Clk       (Clk),
                .Push      (Push),
                .Push_Addr ({{9-(C_ADDR_WIDTH-1){1'b0}},push_addr[C_ADDR_WIDTH-1:1]}),
                .D         ({16'b0,D[15:0]}),
                .Pop       (pop_i),
                .Pop_Addr  ({{9-(C_ADDR_WIDTH-1){1'b0}},pop_addr[C_ADDR_WIDTH-1:1]}),
                .Q         ({Q_tmp,Q[15:0]})
                );
        end
      else if (C_DATA_WIDTH == 8)
        begin : gen_fifo_8bit
	   wire [23:0] Q_tmp;
           bram_fifo_32bit
             bram_fifo_32bit_0
               (
                .Clk       (Clk),
                .Push      (Push),
                .Push_Addr ({{9-(C_ADDR_WIDTH-0){1'b0}},push_addr[C_ADDR_WIDTH-1:0]}),
                .D         ({24'b0,D[7:0]}),
                .Pop       (pop_i),
                .Pop_Addr  ({{9-(C_ADDR_WIDTH-0){1'b0}},pop_addr[C_ADDR_WIDTH-1:0]}),
                .Q         ({Q_tmp,Q[7:0]})
                );
        end
   endgenerate
   
endmodule

