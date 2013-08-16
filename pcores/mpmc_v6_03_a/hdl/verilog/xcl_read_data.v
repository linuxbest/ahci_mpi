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

module xcl_read_data 
#(
  parameter C_PI_SUBTYPE                = "XCL",
  parameter C_PI_DATA_WIDTH             = 32,
  parameter C_PI_RDWDADDR_WIDTH         = 4,
  parameter C_PI_RDDATA_DELAY           = 0,
  parameter C_PI_RDDATA_PIPELINE        = 0,
  parameter C_LINESIZE                  = 4,
  parameter C_MEM_SDR_DATA_WIDTH        = 8,
  parameter C_READ_FIFO_PIPE            = 1,
  parameter C_RDFIFO_EMPTY_PIPE         = 0
)
(
  input  wire                           Clk,
  input  wire                           Clk_MPMC,
  input  wire                           Rst,
  input  wire                           Clk_PI_Enable,
  input  wire [C_PI_DATA_WIDTH-1:0]     PI_RdFIFO_Data,
  output wire                           PI_RdFIFO_Pop,
  input  wire [C_PI_RDWDADDR_WIDTH-1:0] PI_RdFIFO_RdWdAddr,
  input  wire                           PI_RdFIFO_Empty,
  output wire                           PI_RdFIFO_Flush,
  input  wire [3:0]                     Target_Word,
  output wire                           Read_Data_Exists,
  output wire                           Read_Data_Control,
  output wire [0:31]                    Read_Data,
  input  wire                           Read_Data_Read,
  input  wire                           Read_Start,
  output wire                           Read_Done
);

  // Controls the width of our counters and addresses for fixed length reads
  localparam                    P_ADR_WIDTH = (C_LINESIZE == 1) ?  1 :
                                              (C_LINESIZE == 4) ?  2 :  
                                              (C_LINESIZE == 8) ?  3 :  
                                              (C_LINESIZE == 16) ? 4 :  
                                              (C_LINESIZE == 32) ? 5 :  
                                                                   6 ;

  wire [0:C_PI_DATA_WIDTH-1]    pi_rdfifo_data_i;
  reg                           ready;
  wire                          clk_crossing;
  wire                          pi_rdfifo_data_valid;
  reg                           pi_rdfifo_pop_d1;
  reg                           pi_rdfifo_pop_d2;

  wire                          read_data_exists_i;
  wire [0:31]                   read_data_i;
  wire                          read_data_read_i;
  reg  [P_ADR_WIDTH-1:0]        rd_cnt = {P_ADR_WIDTH{1'b0}};
  reg  [P_ADR_WIDTH-1:0]        pop_count = {P_ADR_WIDTH{1'b0}};



  genvar i;

  // Byte reordering within read data bus, Little Endian to Big Endian
  generate
    for (i = 0; i < C_PI_DATA_WIDTH; i = i + 8) begin : rddata_reorder
      assign pi_rdfifo_data_i[i : i+7] = PI_RdFIFO_Data[i+7 : i];
    end
  endgenerate

  always @(posedge Clk_MPMC)
    if (Rst)
      pop_count <= {P_ADR_WIDTH{1'b1}};
    else if (PI_RdFIFO_Pop)
      pop_count <= pop_count - 1'b1;

  always @(posedge Clk_MPMC)
    if (Rst)
      ready <= 1'b0;
    else
      ready <= (!(pop_count == 0 && PI_RdFIFO_Pop) && (ready)) || (Read_Start & Clk_PI_Enable);

  // If we are DXCL2 or IXCL2, then we need to pace the pop commands
  assign clk_crossing = (C_PI_SUBTYPE == "DXCL2" || C_PI_SUBTYPE == "IXCL2")
                         ? Clk_PI_Enable : 1'b1;

  // Insert a module to pop data on a registered version of empty for timing 
  generate
    if (C_RDFIFO_EMPTY_PIPE)
      begin : gen_rdfifo_empty_pipeline
        pop_generator
        #(
          .C_PI_DATA_WIDTH              (C_PI_DATA_WIDTH),
          .C_LINESIZE                   (C_LINESIZE),
          .C_MEM_SDR_DATA_WIDTH         (C_MEM_SDR_DATA_WIDTH),
          .C_CNT_WIDTH                  (P_ADR_WIDTH)
        )
        pop_generator_0
        (
          .Clk_MPMC                     (Clk_MPMC),
          .Rst                          (Rst | Read_Start),         
          .Empty                        ((PI_RdFIFO_Empty | ~ready)
                                         | ((C_PI_SUBTYPE == "DXCL2" || C_PI_SUBTYPE == "IXCL2")
                                            && !Read_Data_Read)),
          .Clk_PI_Enable                (clk_crossing),  
          .Pop                          (PI_RdFIFO_Pop)
        );
      end
    else
      begin : gen_no_rdfifo_empty_pipeline
        assign PI_RdFIFO_Pop = ~PI_RdFIFO_Empty & ready & clk_crossing
                               & ((C_PI_SUBTYPE != "DXCL2" && C_PI_SUBTYPE != "IXCL2")
                                  || Read_Data_Read);
                                                     


      end
  endgenerate

  always @(posedge Clk_MPMC)
    begin
      pi_rdfifo_pop_d1 <= PI_RdFIFO_Pop;
      pi_rdfifo_pop_d2 <= pi_rdfifo_pop_d1;
    end

  // Selects the correctly delayed output of our data.
  assign pi_rdfifo_data_valid  = (C_PI_RDDATA_DELAY == 0) ? PI_RdFIFO_Pop
                               : (C_PI_RDDATA_DELAY == 1) ? pi_rdfifo_pop_d1
                               : pi_rdfifo_pop_d2;

  // This generate block will take the data from the fifo and create
  // intermediate XCL data read signals
  generate
    // No reorder buffer
    if (C_LINESIZE == 1 || C_PI_SUBTYPE == "DXCL2" || C_PI_SUBTYPE == "IXCL2") 
      begin : NO_REORDER
        reg                           read_data_exists_hold;
        reg  [31:0]                   read_data_hold;
        
        // hold the exists on Clk_MPMC if necessary
        always @(posedge Clk_MPMC)
          if (Rst)
            read_data_exists_hold <= 1'b0;
          else
            read_data_exists_hold <= ~(read_data_read_i & Clk_PI_Enable) & (pi_rdfifo_data_valid | read_data_exists_hold);
        
        // hold the data on Clk_MPMC if necessary
        always @(posedge Clk_MPMC)
          if (pi_rdfifo_data_valid) // TODO: remove this if statement?
            read_data_hold <= pi_rdfifo_data_i;

        assign read_data_i = pi_rdfifo_data_valid ? pi_rdfifo_data_i 
                                                  : read_data_hold;
        assign read_data_exists_i = pi_rdfifo_data_valid 
                                    | read_data_exists_hold;

      end  // End gen_linesize_1

    // Cache-line or greater case, we have to re-order the data according to 
    // target word requested and output of mpmc rd fifo.  We will used a dpram 
    // and create the necessary logic to interface the fifo to the dpram.
    else begin : REORDER

      reg                           dpram_init;
      wire                          dpram_we;
      wire [3:0]                    dpram_wr_adr;
      reg  [P_ADR_WIDTH-1:0]        wr_cnt;

      reg                           data_valid_flag;
      wire                          data_valid_in;
      wire                          data_valid_out;

      reg  [3:0]                    dpram_rd_adr;

  
      // We will write to the DPRAM when data is valid
      assign dpram_we = pi_rdfifo_data_valid;

      always @(posedge Clk_MPMC)
        if (Rst)
          dpram_init <= 1;
        else if (& wr_cnt)
          dpram_init <= 0;

      // In cacheline transfers, dpram_wr_adr is controlled by RdWdAddr, in 
      // bursts transfers we use a counter, this counter also used to
      // initialize the flags on the dpram
      always @(posedge Clk_MPMC)
        if (Rst | Read_Start)
          wr_cnt <= {P_ADR_WIDTH{1'b0}};
        else if (dpram_we | dpram_init)
          wr_cnt <= wr_cnt + 1'b1;

      assign dpram_wr_adr = (dpram_init | (C_LINESIZE == 16))
                            ? wr_cnt : PI_RdFIFO_RdWdAddr;

      // A valid flag is used to determine if data is valid in the dpram. It
      // is toggled between each new NPI transaction.  
      always @(posedge Clk)
        if (Rst)
          data_valid_flag <= 1'b0;
        else if (Read_Done)
          data_valid_flag <= ~data_valid_flag;

      // assign a starting data_valid_flag value of 1
      assign data_valid_in = dpram_init ? 1'b1 : data_valid_flag; 

      // dual port memory used to reorder target word first
      dpram
      #(
        .C_WIDTH                (33),
        .C_AWIDTH               (P_ADR_WIDTH),
        .C_DEPTH                (1<<P_ADR_WIDTH)
      ) 
      xcl_reorder_buffer
      (
        .Clk(Clk_MPMC), 
        .DPO({read_data_i, data_valid_out}), 
        .SPO(),                             
        .A(dpram_wr_adr[0 +: P_ADR_WIDTH]), 
        .DI({pi_rdfifo_data_i, data_valid_in}), 
        .DPRA(dpram_rd_adr[0 +: P_ADR_WIDTH]), 
        .WE(dpram_we|dpram_init) 
      ); 

      // read data exists when data_valid_out is the same as data_valid flag
      // and we are not initializing the dpram
      assign read_data_exists_i = (data_valid_out ~^ data_valid_flag) 
                                  & ((C_READ_FIFO_PIPE == 0) | ~Read_Done)
                                  & ~dpram_init;

      // the current read address
      always @(posedge Clk)
        if (Rst) 
          dpram_rd_adr[0 +: P_ADR_WIDTH] <= {P_ADR_WIDTH{1'b0}};
        else if (Read_Start) 
          dpram_rd_adr[0 +: P_ADR_WIDTH] <= Target_Word[0 +: P_ADR_WIDTH];
        else if (read_data_read_i) 
          dpram_rd_adr[0 +: P_ADR_WIDTH] <= dpram_rd_adr[0 +: P_ADR_WIDTH] + 1'b1;

    end // End GEN_CL_RD
  endgenerate

  // This generate creates an optional output pipeline for better timing
  generate
    if (C_READ_FIFO_PIPE && !(C_PI_SUBTYPE == "XCL"))
      begin : gen_read_pipeline_mb
        reg [0:31]                    read_data_d1;
        reg                           read_data_exists_d1;

        always @(posedge Clk) 
        begin
          read_data_d1 <= read_data_i;
          read_data_exists_d1 <= read_data_exists_i;
        end

        assign Read_Data = read_data_d1;
        assign Read_Data_Exists = read_data_exists_d1;
        // Ignoring Read_Data_Read and using read_data_exists_i instead for
        // optimized timing
        assign read_data_read_i = read_data_exists_i;

      end
    else if ((C_READ_FIFO_PIPE && (C_PI_SUBTYPE == "XCL")) || C_LINESIZE == 1)
      begin : gen_read_pipeline
        fifo_pipeline
        #(
          .C_DWIDTH       (32),
          .C_INV_EXISTS   (0)
        )
        read_fifo_pipe
        (
          .Clk            (Clk),
          .Rst            (Rst),
          .FIFO_Exists    (read_data_exists_i),
          .FIFO_Read      (read_data_read_i),
          .FIFO_Data      (read_data_i),
          .PIPE_Exists    (Read_Data_Exists),
          .PIPE_Read      (Read_Data_Read && Read_Data_Exists),
          .PIPE_Data      (Read_Data)
        );
      end
    else
      begin : gen_no_read_pipeline
        assign Read_Data_Exists = read_data_exists_i;
        assign Read_Data = read_data_i;
        assign read_data_read_i = Read_Data_Read && Read_Data_Exists;
      end
  endgenerate

  // the number of reads we have counted (to signal when we are done)
  always @(posedge Clk)
    if (Rst | Read_Start) 
      rd_cnt <= 4'b0; 
    else if (Read_Data_Read && Read_Data_Exists) 
      rd_cnt[0 +: P_ADR_WIDTH] <= rd_cnt[0 +: P_ADR_WIDTH] + 1'b1;

  assign Read_Done = Read_Data_Read && Read_Data_Exists && ((& rd_cnt) || C_LINESIZE == 1); 

  // Tie off unused outputs
  assign PI_RdFIFO_Flush = 1'b0;
  assign Read_Data_Control = 1'b1;


endmodule // xcl_read_data

`default_nettype wire
