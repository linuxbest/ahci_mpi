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
// Filename:     mpmc_pm_npi_if.v
// 
// Description:    
//   This module is MPMC Native Port Interface to Perfomance Monitor hookup. 
//
// Design Notes:
//
`timescale 1ns / 1ns
`default_nettype none

module mpmc_pm_npi_if 
#(
  parameter C_PM_USED               = 8'b10101011,
  parameter C_NPI2PM_BUF_AWIDTH     = 2,
  parameter C_NPI2PM_BUF_DEPTH      = 4,
// default is to allow max of two transactions at once  
  parameter C_PM_WR_TIMER_AWIDTH    = 1,   
  parameter C_PM_WR_TIMER_DEPTH     = 1 << C_PM_WR_TIMER_AWIDTH,
  parameter C_PM_RD_TIMER_AWIDTH    = 1,
  parameter C_PM_RD_TIMER_DEPTH     = 1 << C_PM_RD_TIMER_AWIDTH,
// This is the buffer before we write to the BRAM on the pm side
  parameter C_PM_BUF_AWIDTH         = 3*C_PM_WR_TIMER_AWIDTH, 
  parameter C_PM_BUF_DEPTH          = 1 << C_PM_BUF_AWIDTH,
  parameter C_PM_SHIFT_CNT_BY       = 1,      // Valid values 0-3
  parameter C_PM_DC_CNTR            = 8'b11111111,
  parameter C_PM_DC_WIDTH           = 48,    
  parameter C_PM_GC_CNTR            = 1'b1,
  parameter C_PM_GC_WIDTH           = 48,     
  parameter C_NUM_PORTS             = 0,
  parameter C_PI_DATA_WIDTH         = 8'hFF,
  parameter C_PI_RD_FIFO_TYPE       = 16'hFFFF,
  parameter C_PI_WR_FIFO_TYPE       = 16'hFFFF,
  parameter C_PIM_BASETYPE          = 0
)
(
  input  wire                       Rst,
  input  wire                       PI_Clk,
  input  wire [C_NUM_PORTS-1:0]     PI_AddrReq,
  input  wire [C_NUM_PORTS*4-1:0]   PI_Size,
  input  wire [C_NUM_PORTS-1:0]     PI_RNW,
  input  wire [C_NUM_PORTS-1:0]     PI_AddrAck,
  input  wire [C_NUM_PORTS-1:0]     PI_WrFIFO_Push,
  input  wire [C_NUM_PORTS-1:0]     PI_RdFIFO_Pop,
  input  wire [C_NUM_PORTS-1:0]     PI_WrFIFO_Flush,
  input  wire [C_NUM_PORTS-1:0]     PI_RdFIFO_Flush,

  input  wire                       Host_Clk,
  input  wire [31:0]                PMCTRL_Reg_In,
  output reg  [31:0]                PMCTRL_Reg_Out,
  input  wire                       PMCTRL_Reg_Wr,
  input  wire [31:0]                PMCLR_Reg_In,
  input  wire [31:0]                PMSTATUS_Reg_In,
  output wire [31:0]                PMSTATUS_Reg_Out,
  input  wire                       PMSTATUS_Reg_Wr,
  output wire [63:0]                PMGCC_Reg_Out,
  output wire [(8*64)-1:0]          PMDCC_Reg_Out,

  input  wire [31:0]                PMBRAM_address,
  output reg  [31:0]                PMBRAM_data_out
  
);



  // reg and wires
  reg [C_PM_GC_WIDTH-1:0]   PM_GC_cntr;
  reg [C_PM_GC_WIDTH-1:0]   pmgcc_reg_out_i;
  wire[(8*64)-1:0]          dead_cycle_cnt_out;
  reg [(8*64)-1:0]          pmdcc_reg_out_i;

  wire [8-1:0]    wr_start;
  wire [8-1:0]    wr_stop;
  wire [8-1:0]    wr_flush;
  wire [8*4-1:0]  wr_qualifier;
  wire [8-1:0]    wr_dead_cycle;
  wire [8-1:0]    rd_start;
  wire [8-1:0]    rd_stop;
  wire [8-1:0]    rd_flush;
  wire [8*4-1:0]  rd_qualifier;
  wire [8-1:0]    rd_dead_cycle;

  reg  [8-1:0]    AddrReq_d1;
  reg  [8*4-1:0]  Size_d1;
  reg  [8-1:0]    RNW_d1;
  reg  [8-1:0]    AddrAck_d1;
  reg  [8-1:0]    RdFIFO_Pop_d1;
  reg  [8-1:0]    WrFIFO_Push_d1;
  reg  [8-1:0]    RdFIFO_Flush_d1;
  reg  [8-1:0]    WrFIFO_Flush_d1;

  wire [36*8-1:0]           Host_BRAM_data_out;

  genvar i;

  generate 
    for (i = 0; i < 8; i=i+1)
      begin : npi2pm_reg
        if (C_PM_USED[i] && C_NUM_PORTS > i)
          begin : npi2pm_reg_inst
            always @(posedge PI_Clk) begin
              AddrReq_d1[i] <= PI_AddrReq[i];
              Size_d1[i*4 +:4] <= PI_Size[i*4 +:4]; 
              RNW_d1[i]  <= PI_RNW[i] ;
              AddrAck_d1[i] <= PI_AddrAck[i];
              WrFIFO_Push_d1[i] <= PI_WrFIFO_Push[i];
              WrFIFO_Flush_d1[i] <= PI_WrFIFO_Flush[i];
              RdFIFO_Pop_d1[i] <= PI_RdFIFO_Pop[i];
              RdFIFO_Flush_d1[i] <= PI_RdFIFO_Flush[i];
            end
          end
      end
  endgenerate
  generate 
    for (i = 0; i < 8; i=i+1)
      begin : npi2pm_wr_cond
        if (C_PM_USED[i] && C_NUM_PORTS > i && C_PI_WR_FIFO_TYPE[i*2 +: 2] > 2'b00)
          begin : npi2pm_wr_inst
          mpmc_npi2pm_wr
           #(
             .C_PIM_BASETYPE        (C_PIM_BASETYPE[i*4 +: 4]),
             .C_DATA_WIDTH          (C_PI_DATA_WIDTH[i])
            )
            NPI2PM
            (
             .Clk                   (PI_Clk),
             .Rst                   (Rst),
             .AddrReq               (AddrReq_d1[i] & ~RNW_d1[i]), 
             .AddrAck               (AddrAck_d1[i] & ~RNW_d1[i]),   
             .Size                  (Size_d1[i*4 +: 4]),    
             .WrFIFO_Push           (WrFIFO_Push_d1[i]), 
  
             .start                 (wr_start[i]),
             .stop                  (wr_stop[i]),
             .flush                 (wr_flush[i]),
             .qualifier             (wr_qualifier[i*4 +: 4]),
             .dead_cycle            (wr_dead_cycle[i])
            );
          end
        else
          begin : no_npi2pm_wr_inst
            assign wr_start[i] = 1'b0;
            assign wr_stop[i] = 1'b0;
            assign wr_flush[i] = 1'b0;
            assign wr_qualifier[i*4 +: 4] = 4'h0;
            assign wr_dead_cycle[i] = 1'b0;
          end
      end
  endgenerate
  
  generate 
    for (i = 0; i < 8; i=i+1)
      begin : npi2pm_rd_cond
        if (C_PM_USED[i] && C_NUM_PORTS > i && C_PI_RD_FIFO_TYPE[i*2 +: 2] > 2'b00)
          begin : npi2pm_rd_inst
          mpmc_npi2pm_rd
           #(
             .C_NPI2PM_BUF_AWIDTH   (C_NPI2PM_BUF_AWIDTH),
             .C_NPI2PM_BUF_DEPTH    (C_NPI2PM_BUF_DEPTH), 
             .C_PIM_BASETYPE        (C_PIM_BASETYPE[i*4 +: 4]),
             .C_DATA_WIDTH          (C_PI_DATA_WIDTH[i])
            )
            NPI2PM
            (
             .Clk                   (PI_Clk),
             .Rst                   (Rst),
             .targeted              (RNW_d1[i]),
             .AddrReq               (AddrReq_d1[i]), 
             .Size                  (Size_d1[i*4 +: 4]),    
             .RNW                   (1'b1),      
             .AddrAck               (AddrAck_d1[i]),   
             .FIFO_Cmd              (RdFIFO_Pop_d1[i]), 
             .FIFO_Flush            (RdFIFO_Flush_d1[i]),  
  
             .start                 (rd_start[i]),
             .stop                  (rd_stop[i]),
             .flush                 (rd_flush[i]),
             .qualifier             (rd_qualifier[i*4 +: 4]),
             .dead_cycle            (rd_dead_cycle[i])
            );
          end
        else
          begin : no_npi2pm_rd_inst
            assign rd_start[i] = 1'b0;
            assign rd_stop [i] = 1'b0;
            assign rd_flush[i] = 1'b0;
            assign rd_qualifier[i*4 +: 4] = 4'h0;
            assign rd_dead_cycle[i] = 1'b0;
          end
      end
  endgenerate
  
  generate 
    for (i = 0; i < 8; i=i+1)
      begin : pm_inst
        if (C_PM_USED[i] && C_NUM_PORTS > i)
          begin : pm_cond
          mpmc_pm 
           #(
              .C_PM_WR_TIMER_AWIDTH    (C_PM_WR_TIMER_AWIDTH),
              .C_PM_WR_TIMER_DEPTH     (C_PM_WR_TIMER_DEPTH),
              .C_PM_RD_TIMER_AWIDTH    (C_PM_RD_TIMER_AWIDTH),
              .C_PM_RD_TIMER_DEPTH     (C_PM_RD_TIMER_DEPTH),
              .C_PM_BUF_AWIDTH         (C_PM_BUF_AWIDTH),
              .C_PM_BUF_DEPTH          (C_PM_BUF_DEPTH),
              .C_PM_SHIFT_CNT_BY       (C_PM_SHIFT_CNT_BY),
              .C_PM_DC_CNTR            (C_PM_DC_CNTR[i]),
              .C_PM_DC_WIDTH           (C_PM_DC_WIDTH),
              .C_PI_RD_FIFO_TYPE       (C_PI_RD_FIFO_TYPE[i*2 +: 2]),
              .C_PI_WR_FIFO_TYPE       (C_PI_WR_FIFO_TYPE[i*2 +: 2])
            )
            MPMC_PM
            (
              .PM_Clk                (PI_Clk),
              .Host_Clk              (Host_Clk),
              .Rst                   (Rst),
              .wr_start              (wr_start[i]),
              .wr_stop               (wr_stop[i]),
              .wr_flush              (wr_flush[i]),
              .wr_qualifier          (wr_qualifier[i*4 +:4]),
              .rd_start              (rd_start[i]),
              .rd_stop               (rd_stop[i]),
              .rd_flush              (rd_flush[i]),
              .rd_qualifier          (rd_qualifier[i*4 +:4]),
              .dead_cycle            (rd_dead_cycle[i]||wr_dead_cycle[i]),
              .PM_BRAM_enable        (PMCTRL_Reg_Out[31-i]),
              .Dead_Cycle_Cnt_Clr    (PMCLR_Reg_In[15-i]),
              .Dead_Cycle_Cnt_Out    (dead_cycle_cnt_out[i*64 +:64]),
              .Host_BRAM_address     (PMBRAM_address[11:3]),
              .Host_BRAM_Clr         (PMCLR_Reg_In[31-i]),
              .Host_BRAM_data_out    (Host_BRAM_data_out[i*36+: 36]),
              .Host_BRAM_status      (PMSTATUS_Reg_Out[31-i]),
              .Host_BRAM_status_tog  (PMSTATUS_Reg_In[31-i] & PMSTATUS_Reg_Wr)
            );
          end
        else
          begin : no_pm
            
            assign PMSTATUS_Reg_Out[31-i] = 1'b0;
            assign dead_cycle_cnt_out[(i*64) +: 64] = 64'b0;
            assign Host_BRAM_data_out[i*36 +: 36] = 36'b0;
          end
      end
  endgenerate

  always @(posedge Host_Clk) begin
    pmdcc_reg_out_i <= dead_cycle_cnt_out;
  end

  assign PMDCC_Reg_Out = pmdcc_reg_out_i;

  assign PMSTATUS_Reg_Out[0 +: 24] = 0;

  always @(*)
    case ({PMBRAM_address[14:12], PMBRAM_address[2]})
      4'd0: 
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(0*36+32) +: 4]};//MSB
      4'd1: 
        PMBRAM_data_out <=             Host_BRAM_data_out[(0*36)    +:32];// LSB
      4'd2: 
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(1*36+32) +: 4]};//MSB
      4'd3: 
        PMBRAM_data_out <=             Host_BRAM_data_out[(1*36)    +:32];// LSB
      4'd4: 
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(2*36+32) +: 4]};//MSB
      4'd5: 
        PMBRAM_data_out <=             Host_BRAM_data_out[(2*36)    +:32];// LSB
      4'd6: 
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(3*36+32) +: 4]};//MSB
      4'd7: 
        PMBRAM_data_out <=             Host_BRAM_data_out[(3*36)    +:32];// LSB
      4'd8: 
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(4*36+32) +: 4]};//MSB
      4'd9: 
        PMBRAM_data_out <=             Host_BRAM_data_out[(4*36)    +:32];// LSB
      4'd10: 
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(5*36+32) +: 4]};//MSB
      4'd11: 
        PMBRAM_data_out <=             Host_BRAM_data_out[(5*36)    +:32];// LSB
      4'd12: 
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(6*36+32) +: 4]};//MSB
      4'd13: 
        PMBRAM_data_out <=             Host_BRAM_data_out[(6*36)    +:32];// LSB
      4'd14: 
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(7*36+32) +: 4]};//MSB
      4'd15: 
        PMBRAM_data_out <=             Host_BRAM_data_out[(7*36)    +:32];// LSB
      default:
        PMBRAM_data_out <= {{28{1'b0}},Host_BRAM_data_out[(0*36+32) +: 4]};//MSB
        
    endcase
    
  generate
    for (i = 0 ; i < C_NUM_PORTS ; i = i + 1) begin : PM_CTRL_REG_
      always @(posedge Host_Clk)
        if (Rst)
          PMCTRL_Reg_Out[31-i] <= 1'b0;
        else if (PMCTRL_Reg_Wr)
          PMCTRL_Reg_Out[31-i] <= PMCTRL_Reg_In[31-i] & C_PM_USED[i];
    end
    for (i = C_NUM_PORTS ; i < 32 ; i = i + 1) begin : PM_CTRL_REG_NULL_
      always @(posedge Host_Clk)
        if (Rst)
          PMCTRL_Reg_Out[31-i] <= 1'b0;
        else if (PMCTRL_Reg_Wr)
          PMCTRL_Reg_Out[31-i] <= 1'b0;
    end
  endgenerate
        
    
  
        
  // global counter
  generate
    if (C_PM_GC_CNTR == 1)
      begin : global_cycle_cntr_instantiate
        always @(posedge PI_Clk)
          if ( Rst | PMCLR_Reg_In[16])
             PM_GC_cntr <= 0;
          else if (| PMCTRL_Reg_Out[31:24])
             PM_GC_cntr <= PM_GC_cntr + 1;
      end
    else
      begin : no_gc_cntr
        always @ ( Rst )
            PM_GC_cntr <= 0;
      end
  endgenerate

  // Clock the register output slower clock
  always @(posedge Host_Clk) begin
    pmgcc_reg_out_i <= PM_GC_cntr;
  end

  assign PMGCC_Reg_Out = C_PM_GC_CNTR ? {{(64-C_PM_GC_WIDTH){1'b0}}, pmgcc_reg_out_i}
                                      : 64'b0;

endmodule

`default_nettype wire 
