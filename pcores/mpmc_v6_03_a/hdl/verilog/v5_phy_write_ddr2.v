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
// MPMC V5 MIG PHY DDR2 Initialization
//-------------------------------------------------------------------------
//
// Description:
//   Handles delaying various write control signals appropriately depending
//   on CAS latency, additive latency, etc. Also splits the data and mask in
//   rise and fall buses.
//
// Structure:
//     
//--------------------------------------------------------------------------
//
// History:
//   Sep 26 2007:
//     Added WDF_RDEN_WIDTH parameter.
//     Added WDF_RDEN_EARLY parameter.
//     Moved wdf_rden to be clk0 aligned.
//     Modified such that ctrl_wren is expected one cycle earlier in the 
//     normal case and three cycles earlier in the ECC case in order to allow
//     wdf_rden to be asserted 1 or 3 cycles earlier.
//   Dec 20 2007:
//     Merged MIG 2.1 modifications into this file.
//     Did not merge wdf_ecc_mask logic in as it did not look robust for all
//       DQ_WIDTH settings.
//   Jan 14 2008:
//     Removed logic for ecc_dm_error as MIG only supports 72-bit ECC.
//
//--------------------------------------------------------------------------

`timescale 1ns/1ps

module v5_phy_write_ddr2 #
  (
   parameter DQ_WIDTH       = 64,
   parameter ADDITIVE_LAT   = 0,
   parameter CAS_LAT        = 3,
   parameter ECC_ENABLE     = 0,
   parameter ODT_TYPE       = 0,
   parameter REG_ENABLE     = 0,
   parameter DDR_TYPE       = 1,
   parameter WDF_RDEN_WIDTH = 1,
   parameter WDF_RDEN_EARLY = 0
   )
  (
   input                       clk0,
   input                       clk90,
   input                       rst90,
   input [(2*DQ_WIDTH)-1:0]    wdf_data,
   input [(2*DQ_WIDTH/8)-1:0]  wdf_mask_data,
   input                       ctrl_wren,
   input                       phy_init_wren,
   input                       phy_init_data_sel,
   output reg                  dm_ce,
   output reg [1:0]            dq_oe_n,
   output reg                  dqs_oe_n ,
   output reg                  dqs_rst_n ,
   output [WDF_RDEN_WIDTH-1:0] wdf_rden,
   output reg                  odt,
   output [DQ_WIDTH-1:0]       wr_data_rise,
   output [DQ_WIDTH-1:0]       wr_data_fall,
   output [(DQ_WIDTH/8)-1:0]   mask_data_rise,
   output [(DQ_WIDTH/8)-1:0]   mask_data_fall
   );

  localparam   MASK_WIDTH               = DQ_WIDTH/8;
  localparam   DDR1                     = 0;
  localparam   DDR2                     = 1;
  localparam   DDR3                     = 2;

  // (MIN,MAX) value of WR_LATENCY for DDR1:
  //   REG_ENABLE   = (0,1)
  //   ECC_ENABLE   = (0,1)
  //   Write latency = 1
  //   Total: (1,3)
  // (MIN,MAX) value of WR_LATENCY for DDR2:
  //   REG_ENABLE   = (0,1)
  //   ECC_ENABLE   = (0,1)
  //   Write latency = ADDITIVE_CAS + CAS_LAT - 1 = (0,4) + (3,5) - 1 = (2,8)
  //     ADDITIVE_LAT = (0,4) (JEDEC79-2B)
  //     CAS_LAT      = (3,5) (JEDEC79-2B)
  //   Total: (2,10)
  localparam WR_LATENCY = (DDR_TYPE == DDR3) ?
             (ADDITIVE_LAT + (CAS_LAT) + REG_ENABLE ) :
             (DDR_TYPE == DDR2) ?
             (ADDITIVE_LAT + (CAS_LAT-1) + REG_ENABLE ) :
             (1 + REG_ENABLE );

  // NOTE that ODT timing does not need to be delayed for registered
  // DIMM case, since like other control/address signals, it gets
  // delayed by one clock cycle at the DIMM
  localparam ODT_WR_LATENCY = WR_LATENCY - REG_ENABLE;

  wire                     dm_ce_0;
  reg                      dm_ce_r1;
  reg                      dm_ce_r2;
  wire [1:0]               dq_oe_0;
  reg [1:0]                dq_oe_n_90_r1;
  reg [1:0]                dq_oe_n_90_r2;
  reg [1:0]                dq_oe_270;
  wire                     dqs_oe_0;
  reg                      dqs_oe_270;
  reg                      dqs_oe_n_180_r1;
  reg                      dqs_oe_n_180_r2;
  wire                     dqs_rst_0;
  reg                      dqs_rst_n_180_r1;
  reg                      dqs_rst_n_180_r2;
  reg                      dqs_rst_270;
//  reg                      ecc_dm_error_r;
//  reg                      ecc_dm_error_r1;
  reg [(DQ_WIDTH-1):0]     init_data_f;
  reg [(DQ_WIDTH-1):0]     init_data_r;
  reg [3:0]                init_wdf_cnt_r;
  wire                     odt_0;
  reg                      odt_0_r1;
  reg                      odt_0_r2;
  reg                      odt_0_r3;
  reg                      rst90_r /* synthesis syn_maxfan = 10 */;
  reg [10:0]               wr_stages ;
  reg [(2*DQ_WIDTH)-1:0]   wdf_data_r;
  reg [(2*DQ_WIDTH/8)-1:0] wdf_mask_r;
//  reg [(2*DQ_WIDTH/8)-1:0] wdf_mask_r1;
  wire                     wdf_rden_0;
  reg [WDF_RDEN_WIDTH-1:0] wdf_rden_0_r1;
  reg [WDF_RDEN_WIDTH-1:0] wdf_rden_0_r2;
  wire                     calib_rden_0;
  reg                      calib_rden_90_r;
  reg                      calib_rden_90_r1;
  reg                      calib_rden_270;
  reg                      phy_init_data_sel_90;
  reg                      phy_init_data_sel_180;
  reg                      phy_init_data_sel_270;
  

  always @(posedge clk90)
      rst90_r <= rst90;

  always @(negedge clk90)
    phy_init_data_sel_270 <= phy_init_data_sel;

  always @(negedge clk0)
    phy_init_data_sel_180 <= phy_init_data_sel_270;

  always @(posedge clk90)
    phy_init_data_sel_90 <= phy_init_data_sel_180;
  
  //***************************************************************************
  // Analysis of additional pipeline delays:
  //   1. dq_oe (DQ 3-state): 1 CLK90 cyc in IOB 3-state FF
  //   2. dqs_oe (DQS 3-state): 1 CLK180 cyc in IOB 3-state FF
  //   3. dqs_rst (DQS output value reset): 1 CLK180 cyc in FF + 1 CLK180 cyc
  //      in IOB DDR
  //   4. odt (ODT control): 1 CLK0 cyc in IOB FF
  //   5. write data (output two cyc after wdf_rden - output of RAMB_FIFO w/
  //      output register enabled): 2 CLK90 cyc in OSERDES
  //***************************************************************************

  // DQS 3-state must be asserted one extra clock cycle due b/c of write
  // pre- and post-amble (extra half clock cycle for each)
  assign dqs_oe_0 = wr_stages[WR_LATENCY-1] | wr_stages[WR_LATENCY-2];

  // same goes for ODT, need to handle both pre- and post-amble (generate
  // ODT only for DDR2)
  // ODT generation for DDR2 based on write latency. The MIN write
  // latency is 2. Based on the write latency ODT is asserted.
  generate
    if ((DDR_TYPE != DDR1) && (ODT_TYPE > 0))begin: gen_odt_ddr2
       if(ODT_WR_LATENCY > 2)
         assign odt_0 =
                   wr_stages[ODT_WR_LATENCY-1] |
                   wr_stages[ODT_WR_LATENCY-2] |
                   wr_stages[ODT_WR_LATENCY-3] ;
       else
         assign odt_0 =
                  wr_stages[ODT_WR_LATENCY] |
                  wr_stages[ODT_WR_LATENCY-1] |
                  wr_stages[ODT_WR_LATENCY-2] ;
    end else
      assign odt_0 = 1'b0;
   endgenerate

  assign dq_oe_0[0]   = wr_stages[WR_LATENCY-1] | wr_stages[WR_LATENCY];
  assign dq_oe_0[1]   = wr_stages[WR_LATENCY-1] | wr_stages[WR_LATENCY-2];
  assign dqs_rst_0    = ~wr_stages[WR_LATENCY-2];
  assign dm_ce_0      = wr_stages[WR_LATENCY] | wr_stages[WR_LATENCY-1]
                        | wr_stages[WR_LATENCY-2];

  // write data fifo, read flag assertion
  generate
    if (DDR_TYPE != DDR1) begin: gen_wdf_ddr2
      if (WR_LATENCY > 2) begin: gen_wlg2
        assign wdf_rden_0 = wr_stages[WR_LATENCY-3];
        assign calib_rden_0 = wr_stages[WR_LATENCY-3];
        always @(posedge clk0) begin
          // assert wdf rden only for non calibration opertations
          wdf_rden_0_r1 <=  {WDF_RDEN_WIDTH{wdf_rden_0 &
                                            phy_init_data_sel}};
        end
        always @(posedge clk90) begin
          calib_rden_90_r1 <= calib_rden_90_r;
        end
      end else begin: gen_wl2
        assign wdf_rden_0 = wr_stages[WR_LATENCY-2];
        assign calib_rden_0 = wr_stages[WR_LATENCY-2];
        always @(*) begin
          wdf_rden_0_r1 <= {WDF_RDEN_WIDTH{wdf_rden_0
                                           & phy_init_data_sel}};
        end
        always @(*) begin
          calib_rden_90_r1 <= calib_rden_90_r;
        end
      end
    end else begin: gen_wdf_ddr1
      assign wdf_rden_0 = wr_stages[WR_LATENCY-2];
      assign calib_rden_0 = wr_stages[WR_LATENCY-2];
      always @(*) begin
        wdf_rden_0_r1 <= {WDF_RDEN_WIDTH{wdf_rden_0
                                         & phy_init_data_sel}};
      end
      always @(*) begin
        calib_rden_90_r1 <= calib_rden_90_r;
      end
    end
  endgenerate

  generate
    if (WDF_RDEN_EARLY == 1) begin: gen_wdf_rden_early
      always @(*) begin
        wdf_rden_0_r2 <= wdf_rden_0_r1;
      end
    end
    else begin: gen_wdf_rden_normal
      always @(posedge clk0) begin
        wdf_rden_0_r2 <= wdf_rden_0_r1;
      end
    end
  endgenerate

  // first stage isn't registered
  always @(*)
    wr_stages[0] = (phy_init_data_sel) ? ctrl_wren : phy_init_wren;

  always @(posedge clk0) begin
    wr_stages[1] <= wr_stages[0];
    wr_stages[2] <= wr_stages[1];
    wr_stages[3] <= wr_stages[2];
    wr_stages[4] <= wr_stages[3];
    wr_stages[5] <= wr_stages[4];
    wr_stages[6] <= wr_stages[5];
    wr_stages[7] <= wr_stages[6];
    wr_stages[8] <= wr_stages[7];
    wr_stages[9] <= wr_stages[8];
    wr_stages[10] <= wr_stages[9];
  end

  // intermediate synchronization to CLK270
  always @(negedge clk90) begin
    dq_oe_270         <= dq_oe_0;
    dqs_oe_270        <= dqs_oe_0;
    dqs_rst_270       <= dqs_rst_0;
    calib_rden_270    <= calib_rden_0;
  end

  // synchronize DQS signals to CLK180
  always @(negedge clk0) begin
    dqs_oe_n_180_r1  <= ~dqs_oe_270;
    dqs_oe_n_180_r2  <= dqs_oe_n_180_r1;
    dqs_rst_n_180_r1 <= ~dqs_rst_270;
    dqs_rst_n_180_r2 <= dqs_rst_n_180_r1;
  end

  // All write data-related signals synced to CLK90
  always @(posedge clk90) begin
    dq_oe_n_90_r1   <= ~dq_oe_270;
    calib_rden_90_r <= calib_rden_270;
  end    

  // dm CE signal to stop dm oscilation
  always @(negedge clk90)begin
    dm_ce_r1 <= dm_ce_0;
    dm_ce_r2 <= dm_ce_r1;
  end
  generate
    if (ECC_ENABLE == 1) begin : gen_dm_ce_ecc
      reg dm_ce_r3;
      reg dm_ce_r4;
      always @(negedge clk90) begin
        dm_ce_r3 <= dm_ce_r2;
        dm_ce_r4 <= dm_ce_r3;
        dm_ce <= (phy_init_data_sel_270) ? dm_ce_r4 : dm_ce_r1;
      end
    end else begin : gen_dm_ce
      always @(negedge clk90)
        dm_ce <= (phy_init_data_sel_270) ? dm_ce_r2 : dm_ce_r1;
    end
  endgenerate
  
  // When in ECC mode the upper byte [71:64] will have the
  // ECC parity. Mapping the bytes which have valid data
  // to the upper byte in ecc mode. Also in ecc mode there
  // is an extra register stage to account for timing.
  generate
    if (ECC_ENABLE) begin:gen_ecc_reg
      always @(posedge clk90) begin
        if(phy_init_data_sel_90) begin
          wdf_data_r <= wdf_data;
          wdf_mask_r <= {&wdf_mask_data[DQ_WIDTH*2/8-2:DQ_WIDTH/8], wdf_mask_data[DQ_WIDTH*2/8-2:DQ_WIDTH/8],
                         &wdf_mask_data[DQ_WIDTH/8-2:0], wdf_mask_data[DQ_WIDTH/8-2:0]};
        end else begin
          wdf_data_r <={init_data_f,init_data_r};
          wdf_mask_r <= {(2*DQ_WIDTH/8){1'b0}};
        end
      end
    end else begin
      always@(posedge clk90) begin
        if (phy_init_data_sel_90) begin
          wdf_data_r <= wdf_data;
          wdf_mask_r <= wdf_mask_data;
        end else begin
          wdf_data_r <={init_data_f,init_data_r};
          wdf_mask_r <= {(2*DQ_WIDTH/8){1'b0}};
        end
      end
    end
  endgenerate

  // Error generation block during simulation.
  // Error will be displayed when all the DM
  // bits are not zero. The error will be
  // displayed only during the start of the sequence
  // for errors that are continous over many cycles.
/*
  generate
    if (ECC_ENABLE) begin: gen_ecc_error
      always @(posedge clk90) begin
        //synthesis translate_off
        wdf_mask_r1 <= wdf_mask_r;
        if (DQ_WIDTH > 72)
          ecc_dm_error_r
            <= (
                (~wdf_mask_r1[35] && (|wdf_mask_r1[34:27])) ||
                (~wdf_mask_r1[26] && (|wdf_mask_r1[25:18])) ||
                (~wdf_mask_r1[17] && (|wdf_mask_r1[16:9])) ||
                (~wdf_mask_r1[8] &&  (|wdf_mask_r1[7:0]))) && phy_init_data_sel;
        else
          ecc_dm_error_r
            <= ((~wdf_mask_r1[17] && (|wdf_mask_r1[16:9])) ||
                (~wdf_mask_r1[8] &&  (|wdf_mask_r1[7:0]))) && phy_init_data_sel_90;
        ecc_dm_error_r1 <= ecc_dm_error_r ;
        if (ecc_dm_error_r && ~ecc_dm_error_r1) // assert the error only once.
          $display ("ECC DM ERROR. ");
        //synthesis translate_on
      end
    end
  endgenerate
*/
  //***************************************************************************
  // State logic to write calibration training patterns
  //***************************************************************************

  always @(posedge clk90) begin
    if (rst90_r) begin
      init_wdf_cnt_r  <= 4'd0;
      init_data_r <= {64{1'bx}};
      init_data_f <= {64{1'bx}};
    end else begin
      init_wdf_cnt_r  <= init_wdf_cnt_r + calib_rden_90_r1;
      casex (init_wdf_cnt_r)
        // First stage calibration. Pattern (rise/fall) = 1(r)->0(f)
        // The rise data and fall data are already interleaved in the manner
        // required for data into the WDF write FIFO
        4'b00xx: begin
          init_data_r <= {DQ_WIDTH{1'b1}};
          init_data_f <= {DQ_WIDTH{1'b0}};
        end
        // Second stage calibration. Pattern = 1(r)->1(f)->0(r)->0(f)
        4'b01x0: begin
           init_data_r <= {DQ_WIDTH{1'b1}};
           init_data_f <= {DQ_WIDTH{1'b1}};
          end
        4'b01x1: begin
           init_data_r <= {DQ_WIDTH{1'b0}};
           init_data_f <= {DQ_WIDTH{1'b0}};
        end
        // MIG 3.2: Changed Stage 3/4 training pattern
        // Third stage calibration patern = 
        //   11(r)->ee(f)->ee(r)->11(f)-ee(r)->11(f)->ee(r)->11(f)
        4'b1000: begin
          init_data_r <= {DQ_WIDTH/4{4'h1}};
          init_data_f <= {DQ_WIDTH/4{4'hE}};
        end
        4'b1001: begin
          init_data_r <= {DQ_WIDTH/4{4'hE}};
          init_data_f <= {DQ_WIDTH/4{4'h1}};
          end
        4'b1010: begin
          init_data_r <= {(DQ_WIDTH/4){4'hE}};
          init_data_f <= {(DQ_WIDTH/4){4'h1}};
        end
        4'b1011: begin
          init_data_r <= {(DQ_WIDTH/4){4'hE}};
          init_data_f <= {(DQ_WIDTH/4){4'h1}};
        end
        // Fourth stage calibration patern = 
        //   11(r)->ee(f)->ee(r)->11(f)-11(r)->ee(f)->ee(r)->11(f)
        4'b1100: begin
          init_data_r <= {DQ_WIDTH/4{4'h1}};
          init_data_f <= {DQ_WIDTH/4{4'hE}};
        end
        4'b1101: begin
          init_data_r <= {DQ_WIDTH/4{4'hE}};
          init_data_f <= {DQ_WIDTH/4{4'h1}};
          end
        4'b1110: begin
          init_data_r <= {(DQ_WIDTH/4){4'h1}};
          init_data_f <= {(DQ_WIDTH/4){4'hE}};
        end
        4'b1111: begin
          // MIG 3.5: Corrected last two writes for stage 4 calibration
          // training pattern. Previously MIG 3.3 and MIG 3.4 had the
          // incorrect pattern. This can sometimes result in a calibration
          // point with small timing margin. 
//          init_data_r <= {(DQ_WIDTH/4){4'h1}};
//          init_data_f <= {(DQ_WIDTH/4){4'hE}};
          init_data_r <= {(DQ_WIDTH/4){4'hE}};
          init_data_f <= {(DQ_WIDTH/4){4'h1}};
        end
      endcase
    end
  end

  //***************************************************************************

  always @(posedge clk90) begin
    dq_oe_n_90_r2 <= dq_oe_n_90_r1;
  end
  generate
    if (ECC_ENABLE == 1) begin : gen_dq_oe_n_ecc
      reg [1:0] dq_oe_n_90_r3;
      reg [1:0] dq_oe_n_90_r4;
      always @(posedge clk90) begin
        dq_oe_n_90_r3 <= dq_oe_n_90_r2;
        dq_oe_n_90_r4 <= dq_oe_n_90_r3;
        dq_oe_n <= (phy_init_data_sel_90) ? dq_oe_n_90_r4 : dq_oe_n_90_r1;
      end
    end else begin : gen_dq_oe_n
      always @(posedge clk90)
        dq_oe_n <= (phy_init_data_sel_90) ? dq_oe_n_90_r2 : dq_oe_n_90_r1;
    end
  endgenerate

  generate
    if (ECC_ENABLE == 1) begin : gen_dqs_oe_n_ecc
      reg dqs_rst_n_180_r3;
      reg dqs_rst_n_180_r4;
      reg dqs_oe_n_180_r3;
      reg dqs_oe_n_180_r4;
      always @(negedge clk0) begin
        dqs_oe_n_180_r3  <= dqs_oe_n_180_r2;
        dqs_oe_n_180_r4  <= dqs_oe_n_180_r3;
        dqs_oe_n  <= (phy_init_data_sel_180) ? dqs_oe_n_180_r4 : dqs_oe_n_180_r1;
        dqs_rst_n_180_r3 <= dqs_rst_n_180_r2;
        dqs_rst_n_180_r4 <= dqs_rst_n_180_r3;
        dqs_rst_n <= (phy_init_data_sel_180) ? dqs_rst_n_180_r4 : dqs_rst_n_180_r1;
      end
    end else begin : gen_dqs_oe_n
      always @(negedge clk0) begin
        dqs_oe_n  <= (phy_init_data_sel_180) ? dqs_oe_n_180_r2 : dqs_oe_n_180_r1;
        dqs_rst_n <= (phy_init_data_sel_180) ? dqs_rst_n_180_r2 : dqs_rst_n_180_r1;
      end
    end
  endgenerate

  // generate for odt. odt is asserted based on
  //  write latency. For write latency of 2
  //  the extra register stage is taken out.
  always @(posedge clk0)
  begin
      odt_0_r1 <= odt_0;
      odt_0_r3 <= odt_0_r2;
  end

  generate
    if (ODT_WR_LATENCY > 2) begin
      always @(posedge clk0)
        odt_0_r2 <= odt_0_r1;
    end else begin
      always @ (*)
        odt_0_r2 = odt_0_r1;
    end
  endgenerate
  generate
    if (ECC_ENABLE == 1) begin : gen_odt_ecc
      always @(*) begin
        odt <= (phy_init_data_sel) ? odt_0_r3 : odt_0;
      end
    end else begin : gen_odt
      always @(*)
        odt = (phy_init_data_sel) ? odt_0_r1 : odt_0;
    end
  endgenerate

  assign wdf_rden  = wdf_rden_0_r2;

  //***************************************************************************
  // Format write data/mask: Data is in format: {fall, rise}
  //***************************************************************************

  assign wr_data_rise = wdf_data_r[DQ_WIDTH-1:0];
  assign wr_data_fall = wdf_data_r[(2*DQ_WIDTH)-1:DQ_WIDTH];
  assign mask_data_rise = wdf_mask_r[MASK_WIDTH-1:0];
  assign mask_data_fall = wdf_mask_r[(2*MASK_WIDTH)-1:MASK_WIDTH];

endmodule
