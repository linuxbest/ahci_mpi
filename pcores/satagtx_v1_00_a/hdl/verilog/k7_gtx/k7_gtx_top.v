`timescale 1ns / 1ps
`define DLY #1


//***********************************Entity Declaration************************
module k7_gtx_top (/*AUTOARG*/
   // Outputs
   TXN0_OUT, TXP0_OUT, TXN1_OUT, TXP1_OUT, refclkout, plllkdet,
   gtpclkfb, txdatak_pop0, rxdata_fis0, rxcharisk0, link_up0,
   CommInit0, gtx_txdata0, gtx_txdatak0, gtx_rxdata0, gtx_rxdatak0,
   txdatak_pop1, rxdata_fis1, rxcharisk1, link_up1, CommInit1,
   gtx_txdata1, gtx_txdatak1, gtx_rxdata1, gtx_rxdatak1, oob2dbg0,
   oob2dbg1,
   // Inputs
   GTXRESET_IN, RXN0_IN, RXP0_IN, RXN1_IN, RXP1_IN, refclk,
   dcm_locked, txusrclk0, txusrclk20, txdata_fis0, tx_charisk_fis0,
   phyreset0, phyclk0, StartComm0, gtx_tune0, txdata_fis1,
   tx_charisk_fis1, phyreset1, phyclk1, StartComm1, gtx_tune1,
   phy2cs_data0, phy2cs_k0, phy2cs_data1, phy2cs_k1
   );
   parameter EXAMPLE_SIM_GTXRESET_SPEEDUP = 0;
   parameter C_CHIPSCOPE = 0;
   parameter C_BYPASS_TXBUF = 1;
   parameter C_SATA_SPEED = 1;
`include "sata.v"
//***********************************Ports Declaration*******************************
   input           GTXRESET_IN;
   input           RXN0_IN;
   input           RXP0_IN;
   output          TXN0_OUT;
   output          TXP0_OUT;
   input           RXN1_IN;
   input           RXP1_IN;
   output          TXN1_OUT;
   output          TXP1_OUT;

   input           refclk;
   output 	   refclkout;
   output 	   plllkdet;
   output          gtpclkfb;
   
   input 	   dcm_locked;
   input 	   txusrclk0;
   input 	   txusrclk20;

   input [31:0]    txdata_fis0;
   input           tx_charisk_fis0;
   output 	   txdatak_pop0;
   output [31:0]   rxdata_fis0;
   output [3:0]    rxcharisk0;
   input           phyreset0;
   input           phyclk0;
   output 	   link_up0;
   input           StartComm0;
   output          CommInit0;
   input [31:0]    gtx_tune0;
   output [31:0]   gtx_txdata0;
   output [3:0]	   gtx_txdatak0;
   output [31:0]   gtx_rxdata0;
   output [3:0]	   gtx_rxdatak0;
   
   input [31:0]    txdata_fis1;
   input           tx_charisk_fis1;
   output 	   txdatak_pop1;   
   output [31:0]   rxdata_fis1;
   output [3:0]    rxcharisk1;
   input           phyreset1;
   input           phyclk1;
   output 	   link_up1;
   input           StartComm1;
   output          CommInit1;   
   input [31:0]    gtx_tune1;
   output [31:0]   gtx_txdata1;
   output [3:0]	   gtx_txdatak1;
   output [31:0]   gtx_rxdata1;
   output [3:0]	   gtx_rxdatak1;   

   input [31:0]    phy2cs_data0;
   input           phy2cs_k0;
   input [31:0]    phy2cs_data1;
   input           phy2cs_k1;

   output [127:0]  oob2dbg0;
   output [127:0]  oob2dbg1;

`include "k7_gtx.v" 

   wire [35:0] CONTROL0;
   wire [35:0] CONTROL1;
   wire [35:0] CONTROL2;
   wire trig0;
   wire trig1;
   wire trig2;
   reg [31:0] gtx_txdata0;
   reg [3:0]  gtx_txdatak0;
   reg [31:0] gtx_rxdata0;
   reg [3:0]  gtx_rxdatak0;
   reg [31:0] gtx_txdata1;
   reg [3:0]  gtx_txdatak1;
   reg [31:0] gtx_rxdata1;
   reg [3:0]  gtx_rxdatak1;
   //************************** OOB0 ****************************
   assign rxdata_fis0        = tile0_rxdata0_i;
   assign rxcharisk0         = tile0_rxcharisk0_i;
   gtx_oob #(.C_CHIPSCOPE(C_CHIPSCOPE))
   gtx_oob_0
     (
      // Outputs
      .CommInit				(CommInit0),
      .link_up				(link_up0),
      .txcomstart			(tile0_txcomstart0_i),
      .txcomtype			(tile0_txcomtype0_i),
      .txelecidle			(tile0_txelecidle0_i),
      .rxreset				(/*tile0_rxreset0_i*/),
      .txdata				(tile0_txdata0_i),
      .txdatak				(tile0_txcharisk0_i),
      .txdatak_pop                      (txdatak_pop0),
      .trig_o				(trig0),
      // Inouts
      .CONTROL				(CONTROL0[35:0]),
      // Inputs
      .sys_clk				(tile0_txusrclk20_i),
      .sys_rst				(phyreset0),
      .StartComm			(StartComm0),
      .rxstatus				(tile0_rxstatus0_i[2:0]),
      .rxbyteisaligned			(tile0_rxbyteisaligned0_i),
      .plllkdet				(plllkdet),
      .rxdata				(gtx_rxdata0[31:0]),
      .rxdatak				(gtx_rxdatak0[3:0]),
      .rxelecidle                       (tile0_rxelecidle0_i),
      .tx_sync_done                     (tile0_tx_sync_done0_i),
      .txdata_ll                        (txdata_fis0),
      .txdatak_ll                       (tx_charisk_fis0),
      .gtx_tune                         (gtx_tune0),
      .trig_i				(trig2));
   //************************** OOB1 ****************************
   assign rxdata_fis1        = tile0_rxdata1_i;
   assign rxcharisk1         = tile0_rxcharisk1_i;
   gtx_oob #(.C_CHIPSCOPE(C_CHIPSCOPE))
   gtx_oob_1
     (
      // Outputs
      .CommInit				(CommInit1),
      .link_up				(link_up1),
      .txcomstart			(tile0_txcomstart1_i),
      .txcomtype			(tile0_txcomtype1_i),
      .txelecidle			(tile0_txelecidle1_i),
      .rxreset				(/*tile0_rxreset1_i*/),
      .txdata				(tile0_txdata1_i),
      .txdatak				(tile0_txcharisk1_i),
      .txdatak_pop                      (txdatak_pop1),
      .trig_o				(trig1),
      // Inouts
      .CONTROL				(CONTROL1[35:0]),
      // Inputs
      .sys_clk				(tile0_txusrclk20_i),
      .sys_rst				(phyreset1),
      .StartComm			(StartComm1),
      .rxstatus				(tile0_rxstatus1_i[2:0]),
      .rxbyteisaligned			(tile0_rxbyteisaligned1_i),
      .plllkdet				(plllkdet),
      .rxdata				(gtx_rxdata1[31:0]),
      .rxdatak				(gtx_rxdatak1[3:0]),
      .rxelecidle                       (tile0_rxelecidle1_i),
      .tx_sync_done                     (tile0_tx_sync_done1_i),
      .txdata_ll                        (txdata_fis1),
      .txdatak_ll                       (tx_charisk_fis1),      
      .gtx_tune                         (gtx_tune1),
      .trig_i				(trig2));
   assign  tile0_gtxreset_i = GTXRESET_IN;

    // assign resets for frame_gen modules
    assign  tile0_tx_system_reset0_c = !tile0_tx_sync_done0_i;
    assign  tile0_tx_system_reset1_c = !tile0_tx_sync_done1_i;

    // assign resets for frame_check modules
    assign  tile0_rx_system_reset0_c = !tile0_rx_resetdone0_r2;
    assign  tile0_rx_system_reset1_c = !tile0_rx_resetdone1_r2;

    assign  gtxreset_i                      =  tied_to_ground_i;
    assign  user_tx_reset_i                 =  tied_to_ground_i;
    assign  user_rx_reset_i                 =  tied_to_ground_i;

    assign  tile0_loopback0_i               =  gtx_tune0[2:0];
    assign  tile0_txdiffctrl0_i             =  gtx_tune0[5:3];
    assign  tile0_txpreemphasis0_i          =  gtx_tune0[8:6];
    assign  tile0_rxeqmix0_i                =  gtx_tune0[17:16];
    assign  tile0_loopback1_i               =  gtx_tune1[2:0];
    assign  tile0_txdiffctrl1_i             =  gtx_tune1[5:3];
    assign  tile0_txpreemphasis1_i          =  gtx_tune1[8:6];
    assign  tile0_rxeqmix1_i                =  gtx_tune1[17:16];

    assign  tile0_rxenmcommaalign0_i = 1'b1;
    assign  tile0_rxenmcommaalign1_i = 1'b1;
    assign  tile0_rxenpcommaalign0_i = 1'b1;
    assign  tile0_rxenpcommaalign1_i = 1'b1;

   assign refclkout               = tile0_gtpclkout0_i[0];
   assign gtpclkfb                = tile0_gtpclkfbwest_i[0];
   assign plllkdet                = tile0_plllkdet_i;
   assign refclkout_dcm0_locked_i = dcm_locked;
   assign tile0_txusrclk0_i       = txusrclk0;
   assign tile0_txusrclk20_i      = txusrclk20;
   assign tile0_refclk_i          = refclk;

   /* synthesis attribute keep of txusrclk0  is "true" */
   /* synthesis attribute keep of txusrclk20 is "true" */
   always @(posedge tile0_txusrclk20_i)
     begin
	gtx_txdata0  <= #1 tile0_txdata0_i;
	gtx_txdatak0 <= #1 tile0_txcharisk0_i;
	gtx_rxdata0  <= #1 tile0_rxdata0_i;
	gtx_rxdatak0 <= #1 tile0_rxcharisk0_i;

	gtx_txdata1  <= #1 tile0_txdata1_i;
	gtx_txdatak1 <= #1 tile0_txcharisk1_i;
	gtx_rxdata1  <= #1 tile0_rxdata1_i;
	gtx_rxdatak1 <= #1 tile0_rxcharisk1_i;
     end
    /* synthesis attribute keep of gtx_rxdata0 is "true" */
    /* synthesis attribute keep of gtx_rxdatak0 is "true" */
    /* synthesis attribute keep of gtx_rxdata1 is "true" */
    /* synthesis attribute keep of gtx_rxdatak1 is "true" */

   assign oob2dbg0[31:0]  = tile0_txdata0_i;
   assign oob2dbg0[63:32] = tile0_rxdata0_i;
   assign oob2dbg0[67:64] = tile0_txcharisk0_i;
   assign oob2dbg0[71:68] = tile0_rxcharisk0_i;
   assign oob2dbg0[79:72] = encode_prim(tile0_txdata0_i);
   assign oob2dbg0[87:80] = encode_prim(tile0_rxdata0_i);
   assign oob2dbg0[119:88]= phy2cs_data0;
   assign oob2dbg0[120]   = phy2cs_k0;

   assign oob2dbg1[31:0]  = tile0_txdata1_i;
   assign oob2dbg1[63:32] = tile0_rxdata1_i;
   assign oob2dbg1[67:64] = tile0_txcharisk1_i;
   assign oob2dbg1[71:68] = tile0_rxcharisk1_i;
   assign oob2dbg1[79:72] = encode_prim(tile0_txdata1_i);
   assign oob2dbg1[87:80] = encode_prim(tile0_rxdata1_i);
   assign oob2dbg1[119:88]= phy2cs_data1;
   assign oob2dbg1[120]   = phy2cs_k1;
   
     wire [127:0] dbg2;
generate if (C_CHIPSCOPE == 1)
begin
	chipscope_icon3
	icon (.CONTROL0   (CONTROL0[35:0]),
	      .CONTROL1   (CONTROL1[35:0]),
	      .CONTROL2   (CONTROL2[35:0]));
	chipscope_ila_128x1
	dbX2 (.TRIG_OUT (trig2),
	      .CONTROL  (CONTROL2[35:0]),
	      .CLK      (phyclk0),
	      .TRIG0    (dbg2));
        assign dbg2[127] = trig0;
	assign dbg2[126] = trig1;
	assign dbg2[31:0]= tile0_txdata0_i;
	assign dbg2[63:32]=tile0_rxdata0_i;
	assign dbg2[71:64]=tile0_txcharisk0_i;
	assign dbg2[79:72]=tile0_rxcharisk0_i;
	assign dbg2[87:80]=4'h0;
	assign dbg2[111:88]=phy2cs_data0;
	assign dbg2[120]   =phy2cs_k0;
end
endgenerate

endmodule
