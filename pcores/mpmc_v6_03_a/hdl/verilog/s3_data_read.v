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
// MPMC Spartam3 MIG PHY Data Read
//-------------------------------------------------------------------------
//
// Description:
//   Data read operation performed through RAM8D in this module.
//
// Structure:
//   -- s3_phy.v
//     -- s3_phy_init.v
//     -- s3_infrastructure.v
//       -- s3_cal_top.v
//         -- s3_cal_ctl.v
//         -- s3_tap_dly.v
//     -- s3_phy_write.v
//     -- s3_data_path.v
//       -- s3_data_read_controller.v
//         -- s3_dqs_delay.v
//         -- s3_fifo_0_wr_en.v
//         -- s3_fifo_1_wr_en.v
//       -- s3_data_read.v
//         -- s3_rd_data_ram0.v
//         -- s3_rd_data_ram1.v
//         -- s3_gray_cntr.v
//     -- s3_iobs.v
//       -- s3_infrastructure_iobs.v
//       -- s3_controller_iobs.v
//       -- s3_data_path_iobs.v
//         -- s3_dqs_iob.v
//         -- s3_dq_iob.v
//         -- s3_dm_iobs.v
//     
//--------------------------------------------------------------------------
//
// History:
//   Jul 18 2008: Merged MIG 2.3 modifications into this file.
//
//--------------------------------------------------------------------------

`timescale 1ns/100ps

module s3_data_read #
  (
   parameter integer DQS_WIDTH     = 8,      // # of DQS strobes
   parameter integer DQ_BITS       = 5,      // # of data bits 
   parameter integer DQ_PER_DQS    = 8,      // # of DQ data bits per strobe
   parameter integer SIM_ONLY      = 0,
   parameter         C_FAMILY  = "spartan3", // Allowed Values: spartan3, spartan3e, spartan3a
   parameter integer C_SPECIAL_BOARD = 0     // Allowed Values: 0 = use default settings, 
                                             //                 1 = special placement
   )
  (
   input                      clk0,
   input                      clk90,
   input                      clk180,
   input                      rst,
   input                      rst90,
   input [(DQ_BITS-1):0]      ddr_dq_in,   
   input [(DQS_WIDTH-1):0]    fifo_0_wr_en,     
   input [(DQS_WIDTH-1):0]    fifo_1_wr_en,
   input                      rst_dqs_div_in,   
   input                      rst_rd_fifo,
   input [(DQS_WIDTH-1):0]    dqs_delayed_col0, 
   input [(DQS_WIDTH-1):0]    dqs_delayed_col1,  
   input                      read_fifo_rden, 
   output [((DQ_BITS*2)-1):0] user_output_data,
   output                     user_data_valid
   ); 

  reg [(DQS_WIDTH*DQ_PER_DQS)-1:0]  fifo_0_data_out_r/* synthesis syn_preserve=1 */;
  reg [(DQS_WIDTH*DQ_PER_DQS)-1:0]  fifo_1_data_out_r/* synthesis syn_preserve=1 */;
  
  reg [((DQ_BITS*2)-1):0]           first_sdr_data;
  reg                               read_fifo_rden_180r0; 
  reg                               read_fifo_rden_90r1; 
  reg                               read_fifo_rden_90r2; 
  reg                               read_fifo_rden_90r3; 
  reg                               read_fifo_rden_0r4; 
  reg                               read_fifo_rden_0r5; 
  reg                               read_fifo_rden_0r6; 
  
  wire [(DQS_WIDTH*DQ_PER_DQS)-1:0] fifo_0_data_out;
  wire [(DQS_WIDTH*DQ_PER_DQS)-1:0] fifo_1_data_out;
  
  wire [3:0]                        fifo_0_wr_addr [(DQS_WIDTH-1):0];   
  wire [3:0]                        fifo_1_wr_addr [(DQS_WIDTH-1):0];   
  
  wire [3:0]                        fifo_0_wr_addr_out [(DQS_WIDTH-1):0];
  wire [3:0]                        fifo_1_wr_addr_out [(DQS_WIDTH-1):0];
  
  wire [3:0]                   #(1) fifo_0_wr_addr_sim [(DQS_WIDTH-1):0];
  wire [3:0]                   #(1) fifo_1_wr_addr_sim [(DQS_WIDTH-1):0];
  
  reg [3:0]                         fifo_0_wr_addr_d [(DQS_WIDTH-1):0]; 
  reg [3:0]                         fifo_1_wr_addr_d [(DQS_WIDTH-1):0]; 
  
  reg [3:0]                         fifo_0_wr_addr_d2 [(DQS_WIDTH-1):0];
  reg [3:0]                         fifo_1_wr_addr_d2 [(DQS_WIDTH-1):0];
  
  reg [3:0]                         fifo_0_wr_addr_d3 [(DQS_WIDTH-1):0];
  reg [3:0]                         fifo_1_wr_addr_d3 [(DQS_WIDTH-1):0];
  
  wire [3:0]                        fifo_0_rd_addr [(DQS_WIDTH-1):0];   
  wire [3:0]                        fifo_1_rd_addr [(DQS_WIDTH-1):0];   
  
  reg [3:0]                         fifo_0_rd_addr_d [(DQS_WIDTH-1):0]/* synthesis syn_preserve=1 */; 
  reg [3:0]                         fifo_1_rd_addr_d [(DQS_WIDTH-1):0]/* synthesis syn_preserve=1 */; 

  wire [(DQS_WIDTH-1):0]            dqs_delayed_col0_n;
  wire [(DQS_WIDTH-1):0]            dqs_delayed_col1_n;
  
  
  wire                              wr_addr_rst;
  reg                               wr_addr_rst_d1;
  wire                              rd_addr_rst;
  reg                               rd_addr_rst_reg = 0;
        
  assign dqs_delayed_col0_n = ~dqs_delayed_col0;
  assign dqs_delayed_col1_n = ~dqs_delayed_col1;
  
  assign user_output_data = first_sdr_data;
  assign user_data_valid  = read_fifo_rden_0r6;
  
  // Read fifo read enable signal phase is changed from 0 to 90 clock domain 
   always@(posedge clk180) begin
     if(rst)begin
         read_fifo_rden_180r0 <= 1'b0;
      end
      else begin
         read_fifo_rden_180r0 <= read_fifo_rden;
      end
   end
   always@(posedge clk90) begin
      if(rst90)begin
         read_fifo_rden_90r1 <= 1'b0;
         read_fifo_rden_90r2 <= 1'b0;
         read_fifo_rden_90r3 <= 1'b0;
      end
      else begin
         read_fifo_rden_90r1 <= read_fifo_rden_180r0;
         read_fifo_rden_90r2 <= read_fifo_rden_90r1;
         read_fifo_rden_90r3 <= read_fifo_rden_90r2;
      end
   end
   always@(posedge clk0) begin
      if(rst)begin
         read_fifo_rden_0r4 <= 1'b0;
         read_fifo_rden_0r5 <= 1'b0;
         read_fifo_rden_0r6 <= 1'b0;
      end else begin
         read_fifo_rden_0r4 <= read_fifo_rden_90r3;
         read_fifo_rden_0r5 <= read_fifo_rden_0r4;
         read_fifo_rden_0r6 <= read_fifo_rden_0r5;
      end
   end
  always@(posedge clk90) begin
    if (rst90) begin
      fifo_0_data_out_r <= 64'd0;
      fifo_1_data_out_r <= 64'd0;
    end
    else begin
      fifo_0_data_out_r <= fifo_0_data_out;
      fifo_1_data_out_r <= fifo_1_data_out;
    end
  end
  
  always @( posedge clk0 ) begin
    if (rst) begin
      first_sdr_data   <= 64'd0;  
    end
    else begin
      if (read_fifo_rden_0r5) begin
        first_sdr_data  <= { fifo_1_data_out_r, fifo_0_data_out_r };
      end
    end
  end

  // Use RAM16X1D components to cross clock domains
  // Data is captured with dqs_delayed signals on the FIFO write port
  // Data needs to be read using the FPGA clk0 signal.
  
  genvar data_i;
  generate
    for (data_i = 0; data_i < DQS_WIDTH; data_i = data_i+1) begin: gen_data
      
      if (C_SPECIAL_BOARD > 0) begin: gen_special_board
        
        if (data_i == 0) begin: gen_data_i0
          
          // Use s3_rd_data_ram0 to specifically place DQ (0:7) 
          // based on I/O pad placement
          
          // Replace with distributed RAM components
          // Due to capturing data using dqs_delayed and registering
          // on Clk90
          s3_rd_data_ram0 #
            (
             .C_FAMILY  (C_FAMILY)
             )
            strobe0   
              ( 
                .DOUT  (fifo_0_data_out[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
                .DIN   (ddr_dq_in[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
                .WCLK0 (dqs_delayed_col0[data_i]), 
                .WCLK1 (dqs_delayed_col1[data_i]),
                .WE    (fifo_0_wr_en[data_i]),
                .WADDR (fifo_0_wr_addr[data_i]),
                .RADDR (fifo_0_rd_addr_d[data_i])
                );
          
          s3_rd_data_ram0 #
            (
             .C_FAMILY (C_FAMILY)
             )
            strobe0_n 
              (
               .DOUT  (fifo_1_data_out[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
               .DIN   (ddr_dq_in[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
               .WCLK0 (dqs_delayed_col0_n[data_i]), 
               .WCLK1 (dqs_delayed_col1_n[data_i]),
               .WE    (fifo_1_wr_en[data_i]),
               .WADDR (fifo_1_wr_addr[data_i]),
               .RADDR (fifo_1_rd_addr_d[data_i])
               );
          
        end
        else begin: gen_data_i
          
          // Use s3_rd_data_ram1 to specifically place DQ (8:15) 
          // based on I/O pad placement
          
          // Replace with distributed RAM components
          // Due to capturing data using dqs_delayed and registering
          // on Clk90
          s3_rd_data_ram1 #
            (
             .C_FAMILY (C_FAMILY)
             )
            strobe0   
              ( 
                .DOUT  (fifo_0_data_out[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
                .DIN   (ddr_dq_in[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
                .WCLK0 (dqs_delayed_col0[data_i]), 
                .WCLK1 (dqs_delayed_col1[data_i]),
                .WE    (fifo_0_wr_en[data_i]),
                .WADDR (fifo_0_wr_addr[data_i]),
                .RADDR (fifo_0_rd_addr_d[data_i])
                );
          
          s3_rd_data_ram1 #
            (
             .C_FAMILY (C_FAMILY)
             )
            strobe0_n 
              ( 
                .DOUT   (fifo_1_data_out[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
                .DIN    (ddr_dq_in[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
                .WCLK0  (dqs_delayed_col0_n[data_i]), 
                .WCLK1  (dqs_delayed_col1_n[data_i]),
                .WE     (fifo_1_wr_en[data_i]),
                .WADDR  (fifo_1_wr_addr[data_i]),
                .RADDR  (fifo_1_rd_addr_d[data_i])
                );              
          
        end
      end
      
      // C_SPECIAL_BOARD = 0
      // Use default column location constraints & default clocks on DQ FIFOs
      else begin: gen_data_ram
        
        // Replace with distributed RAM components
        // Due to capturing data using dqs_delayed and registering
        // on Clk90
        // Use s3_rd_data_ram module only with default COL placement
        s3_rd_data_ram
          strobe0   
            ( 
              .DOUT  (fifo_0_data_out[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
              .DIN   (ddr_dq_in[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
              .WCLK0 (dqs_delayed_col0[data_i]), 
              .WCLK1 (dqs_delayed_col1[data_i]),
              .WE    (fifo_0_wr_en[data_i]),
              .WADDR (fifo_0_wr_addr[data_i]),
              .RADDR (fifo_0_rd_addr_d[data_i])
              );
        
        s3_rd_data_ram
          strobe0_n 
            (
             .DOUT  (fifo_1_data_out[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
             .DIN   (ddr_dq_in[((data_i+1)*DQ_PER_DQS)-1:(data_i*DQ_PER_DQS)]), 
             .WCLK0 (dqs_delayed_col0_n[data_i]), 
             .WCLK1 (dqs_delayed_col1_n[data_i]),
             .WE    (fifo_1_wr_en[data_i]),
             .WADDR (fifo_1_wr_addr[data_i]),
             .RADDR (fifo_1_rd_addr_d[data_i])
             );                                 
        
      end
      
      
    end
  endgenerate
  
  always @ (posedge clk90) begin
    rd_addr_rst_reg = rd_addr_rst;
  end
  
  assign wr_addr_rst = rst;
  assign rd_addr_rst = rst90;
  always @(posedge clk0) begin
    wr_addr_rst_d1 <= wr_addr_rst;
  end
  
  // FIFO write address generation logic
  genvar wr_addr_i;
  generate
    
    for (wr_addr_i = 0; wr_addr_i < DQS_WIDTH; wr_addr_i = wr_addr_i+1) begin: gen_wr_addr
      
      s3_gray_cntr 
        u_fifo_0_wr_addr
          (
           .clk      (dqs_delayed_col0[wr_addr_i]), 
           .reset    (wr_addr_rst_d1), 
           .cnt_en   (fifo_0_wr_en[wr_addr_i]),
           .gcnt_out (fifo_0_wr_addr_out[wr_addr_i])
           );
      
      s3_gray_cntr 
        u_fifo_1_wr_addr
          (
           .clk         (dqs_delayed_col1_n[wr_addr_i]), 
           .reset               (wr_addr_rst_d1), 
           .cnt_en              (fifo_1_wr_en[wr_addr_i]),
           .gcnt_out    (fifo_1_wr_addr_out[wr_addr_i])
           );
      
      
      // For simulation purposes
      // Model net/LUT delays
      if (SIM_ONLY == 0) begin: gen_no_sim
        assign fifo_0_wr_addr[wr_addr_i] = fifo_0_wr_addr_out[wr_addr_i];
        assign fifo_1_wr_addr[wr_addr_i] = fifo_1_wr_addr_out[wr_addr_i];
      end
      else begin: gen_sim
        
        assign fifo_0_wr_addr_sim[wr_addr_i] = fifo_0_wr_addr_out[wr_addr_i];
        assign fifo_1_wr_addr_sim[wr_addr_i] = fifo_1_wr_addr_out[wr_addr_i];
        
        assign fifo_0_wr_addr[wr_addr_i] = fifo_0_wr_addr_sim[wr_addr_i];
        assign fifo_1_wr_addr[wr_addr_i] = fifo_1_wr_addr_sim[wr_addr_i];
        
      end
      
      
      // Register FIFO write address
      always @(posedge clk90) begin
        if (rd_addr_rst) begin
          fifo_0_wr_addr_d[wr_addr_i]  <= 4'd0;
          fifo_1_wr_addr_d[wr_addr_i]  <= 4'd0;
          fifo_0_wr_addr_d2[wr_addr_i] <= 4'd0;
          fifo_1_wr_addr_d2[wr_addr_i] <= 4'd0;
          fifo_0_wr_addr_d3[wr_addr_i] <= 4'd0;
          fifo_1_wr_addr_d3[wr_addr_i] <= 4'd0;
        end
        else begin
          fifo_0_wr_addr_d[wr_addr_i]  <= fifo_0_wr_addr[wr_addr_i];
          fifo_1_wr_addr_d[wr_addr_i]  <= fifo_1_wr_addr[wr_addr_i];
          fifo_0_wr_addr_d2[wr_addr_i] <= fifo_0_wr_addr_d[wr_addr_i];
          fifo_1_wr_addr_d2[wr_addr_i] <= fifo_1_wr_addr_d[wr_addr_i];
          fifo_0_wr_addr_d3[wr_addr_i] <= fifo_0_wr_addr_d2[wr_addr_i];
          fifo_1_wr_addr_d3[wr_addr_i] <= fifo_1_wr_addr_d2[wr_addr_i];
        end
      end               
  
    end
  endgenerate

  // Generate FIFO read address logic
  genvar rd_addr_i;
  generate
    
    for (rd_addr_i = 0; rd_addr_i < DQS_WIDTH; rd_addr_i = rd_addr_i+1) begin: gen_rd_addr
      
      // Async reset, so use registered reset signal
      // rd address gray counters
      s3_gray_cntr 
        fifo0_rd_addr_inst 
          (
           .clk      (clk90), 
           .reset    (rd_addr_rst_reg), 
           .cnt_en   (read_fifo_rden_90r3), 
           .gcnt_out (fifo_0_rd_addr[rd_addr_i])
           );
      
      s3_gray_cntr 
        fifo1_rd_addr_inst 
          (
           .clk      (clk90), 
           .reset    (rd_addr_rst_reg), 
           .cnt_en   (read_fifo_rden_90r3), 
           .gcnt_out (fifo_1_rd_addr[rd_addr_i])
           );
      
      always @(posedge clk90) begin
        if (rd_addr_rst) begin          
          fifo_0_rd_addr_d[rd_addr_i] <= 4'b0000;
          fifo_1_rd_addr_d[rd_addr_i] <= 4'b0000;
        end
        else begin
          fifo_0_rd_addr_d[rd_addr_i] <= fifo_0_rd_addr[rd_addr_i];
          fifo_1_rd_addr_d[rd_addr_i] <= fifo_1_rd_addr[rd_addr_i];
        end
        
      end               
    end         
  endgenerate
  

endmodule 

