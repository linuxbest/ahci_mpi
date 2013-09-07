// satagtx.v --- 
// 
// Filename: satagtx.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Tue Jul 20 10:20:49 2010 (+0800)
// Version: 
// Last-Updated: 
//           By: 
//     Update #: 0
// URL: 
// Keywords: 
// Compatibility: 
// 
// 

// Commentary: 
// 
// 
// 
// 

// Change log:
// 
// 
// 

// Copyright (C) 2008,2009 Beijing Soul tech.
// -------------------------------------
// Naming Conventions:
// 	active low signals                 : "*_n"
// 	clock signals                      : "clk", "clk_div#", "clk_#x"
// 	reset signals                      : "rst", "rst_n"
// 	generics                           : "C_*"
// 	user defined types                 : "*_TYPE"
// 	state machine next state           : "*_ns"
// 	state machine current state        : "*_cs"
// 	combinatorial signals              : "*_com"
// 	pipelined or register delay signals: "*_d#"
// 	counter signals                    : "*cnt*"
// 	clock enable signals               : "*_ce"
// 	internal version of output port    : "*_i"
// 	device pins                        : "*_pin"
// 	ports                              : - Names begin with Uppercase
// Code:

module satagtx (/*AUTOARG*/
   // Outputs
   TXN0_OUT, TXP0_OUT, TXN1_OUT, TXP1_OUT, refclkout, plllkdet,
   gtpclkfb, txdatak_pop0, rxdata0, rxdatak0, linkup0, plllock0,
   oob2dbg0, CommInit0, phyclk0, gtx_txdata0, gtx_txdatak0,
   gtx_rxdata0, gtx_rxdatak0, txdatak_pop1, rxdata1, rxdatak1,
   linkup1, plllock1, oob2dbg1, CommInit1, phyclk1, gtx_txdata1,
   gtx_txdatak1, gtx_rxdata1, gtx_rxdatak1,
   // Inputs
   GTXRESET_IN, RXN0_IN, RXP0_IN, RXN1_IN, RXP1_IN, refclk,
   dcm_locked, txusrclk0, txusrclk20, phyreset0, txdata0, txdatak0,
   StartComm0, gtx_tune0, phyreset1, txdata1, txdatak1, StartComm1,
   gtx_tune1
   );
   parameter C_FAMILY = "virtex5";
   parameter C_ENABLE = 1;
   parameter C_CHIPSCOPE = 0;
   parameter C_SATA_SPEED = 2;

   input                GTXRESET_IN;

   input		RXN0_IN;
   input		RXP0_IN;
   output		TXN0_OUT;
   output		TXP0_OUT;
   input		RXN1_IN;
   input		RXP1_IN;
   output		TXN1_OUT;
   output		TXP1_OUT;
  
   input                refclk;
   output		refclkout;
   output		plllkdet;
   output               gtpclkfb;

   input                dcm_locked;
   input                txusrclk0;
   input                txusrclk20;

   input                phyreset0;
   input [31:0]         txdata0;
   input                txdatak0;
   output 		txdatak_pop0;
   output [31:0]        rxdata0;
   output               rxdatak0;
   output               linkup0;
   output               plllock0; 
   output [127:0]       oob2dbg0;
   input                StartComm0;
   output               CommInit0;
   output               phyclk0;
   input [31:0]         gtx_tune0;
   output [31:0] 	gtx_txdata0;
   output [3:0] 	gtx_txdatak0;
   output [31:0] 	gtx_rxdata0;
   output [3:0] 	gtx_rxdatak0;

   input                phyreset1;
   input [31:0] 	txdata1;
   input                txdatak1;
   output 		txdatak_pop1;
   output [31:0] 	rxdata1;
   output               rxdatak1;
   output               linkup1;
   output               plllock1; 
   output [127:0] 	oob2dbg1;
   input                StartComm1;
   output               CommInit1;
   output               phyclk1;
   input [31:0] 	gtx_tune1;
   output [31:0] 	gtx_txdata1;
   output [3:0] 	gtx_txdatak1;
   output [31:0]        gtx_rxdata1;
   output [3:0] 	gtx_rxdatak1;
 
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			link_up0;		// From sata_gtx_phy of v5_gtx_top.v, ...
   wire			link_up1;		// From sata_gtx_phy of v5_gtx_top.v, ...
   wire [3:0]		rxcharisk0;		// From sata_gtx_phy of v5_gtx_top.v, ...
   wire [3:0]		rxcharisk1;		// From sata_gtx_phy of v5_gtx_top.v, ...
   wire [31:0]		rxdata_fis0;		// From sata_gtx_phy of v5_gtx_top.v, ...
   wire [31:0]		rxdata_fis1;		// From sata_gtx_phy of v5_gtx_top.v, ...
   // End of automatics

   wire [31:0]          txdata_fis0;
   wire [31:0]		cs2phy_data0;		
   wire		        fsm2phy_k0;		
   wire [31:0]	        phy2cs_data0;		
   wire		        phy2cs_k0;		
   wire                 host_rst0;

   wire [31:0]          txdata_fis1;
   wire [31:0] 		cs2phy_data1;		
   wire		        fsm2phy_k1;		
   wire [31:0] 		phy2cs_data1;		
   wire		        phy2cs_k1;		
   wire                 host_rst1;
   
   assign    cs2phy_data0 = txdata0;
   assign    fsm2phy_k0   = txdatak0;
   assign    rxdata0      = phy2cs_data0;
   assign    rxdatak0     = phy2cs_k0;
   assign    plllock0     = plllkdet;
   assign    host_rst0    = phyreset0;
   assign    linkup0      = link_up0;
   
   assign    cs2phy_data1 = txdata1;
   assign    fsm2phy_k1   = txdatak1;
   assign    rxdata1      = phy2cs_data1;
   assign    rxdatak1     = phy2cs_k1;
   assign    plllock1     = plllkdet;
   assign    host_rst1    = phyreset1;
   assign    linkup1      = link_up1;

   phy_if_gtx 
     phy_if_gtx0(
		 // Outputs
		 .phy2cs_data		(phy2cs_data0[31:0]),
		 .phy2cs_k		(phy2cs_k0),
		 .txdata_fis		(txdata_fis0[31:0]),
		 .tx_charisk_fis	(tx_charisk_fis0),
		 // Inputs
		 .clk_75m		(phyclk0),
		 .host_rst		(host_rst0),
		 .cs2phy_data		(cs2phy_data0[31:0]),
		 .link_up		(linkup0),
		 .fsm2phy_k		(fsm2phy_k0),
		 .rxdata_fis		(rxdata_fis0[31:0]),
		 .rxcharisk		(rxcharisk0[3:0]));

   phy_if_gtx 
     phy_if_gtx1(
		 // Outputs
		 .phy2cs_data		(phy2cs_data1[31:0]),
		 .phy2cs_k		(phy2cs_k1),
		 .txdata_fis		(txdata_fis1[31:0]),
		 .tx_charisk_fis	(tx_charisk_fis1),
		 // Inputs
		 .clk_75m		(phyclk1),
		 .host_rst		(host_rst1),
		 .cs2phy_data		(cs2phy_data1[31:0]),
		 .link_up		(linkup1),
		 .fsm2phy_k		(fsm2phy_k1),
		 .rxdata_fis		(rxdata_fis1[31:0]),
		 .rxcharisk		(rxcharisk1[3:0]));

generate if (C_FAMILY == "virtex5")
begin: v5_gtx_top
   v5_gtp_top #(
	   .C_CHIPSCOPE  (C_CHIPSCOPE),
	   .C_SATA_SPEED (C_SATA_SPEED)
               )
     sata_gtx_phy(/*AUTOINST*/
		  // Outputs
		  .TXN0_OUT		(TXN0_OUT),
		  .TXP0_OUT		(TXP0_OUT),
		  .TXN1_OUT		(TXN1_OUT),
		  .TXP1_OUT		(TXP1_OUT),
		  .refclkout		(refclkout),
		  .plllkdet		(plllkdet),
		  .txdatak_pop0		(txdatak_pop0),
		  .rxdata_fis0		(rxdata_fis0[31:0]),
		  .rxcharisk0		(rxcharisk0[3:0]),
		  .link_up0		(link_up0),
		  .CommInit0		(CommInit0),
		  .gtx_txdata0		(gtx_txdata0[31:0]),
		  .gtx_txdatak0		(gtx_txdatak0[3:0]),
		  .gtx_rxdata0		(gtx_rxdata0[31:0]),
		  .gtx_rxdatak0		(gtx_rxdatak0[3:0]),
		  .txdatak_pop1		(txdatak_pop1),
		  .rxdata_fis1		(rxdata_fis1[31:0]),
		  .rxcharisk1		(rxcharisk1[3:0]),
		  .link_up1		(link_up1),
		  .CommInit1		(CommInit1),
		  .gtx_txdata1		(gtx_txdata1[31:0]),
		  .gtx_txdatak1		(gtx_txdatak1[3:0]),
		  .gtx_rxdata1		(gtx_rxdata1[31:0]),
		  .gtx_rxdatak1		(gtx_rxdatak1[3:0]),
		  .oob2dbg0		(oob2dbg0[127:0]),
		  .oob2dbg1		(oob2dbg1[127:0]),
		  // Inputs
		  .GTXRESET_IN		(GTXRESET_IN),
		  .RXN0_IN		(RXN0_IN),
		  .RXP0_IN		(RXP0_IN),
		  .RXN1_IN		(RXN1_IN),
		  .RXP1_IN		(RXP1_IN),
		  .refclk		(refclk),
		  .dcm_locked		(dcm_locked),
		  .txusrclk0		(txusrclk0),
		  .txusrclk20		(txusrclk20),
		  .txdata_fis0		(txdata_fis0[31:0]),
		  .tx_charisk_fis0	(tx_charisk_fis0),
		  .phyreset0		(phyreset0),
		  .phyclk0		(phyclk0),
		  .StartComm0		(StartComm0),
		  .gtx_tune0		(gtx_tune0[31:0]),
		  .txdata_fis1		(txdata_fis1[31:0]),
		  .tx_charisk_fis1	(tx_charisk_fis1),
		  .phyreset1		(phyreset1),
		  .phyclk1		(phyclk1),
		  .StartComm1		(StartComm1),
		  .gtx_tune1		(gtx_tune1[31:0]),
		  .phy2cs_data0		(phy2cs_data0[31:0]),
		  .phy2cs_k0		(phy2cs_k0),
		  .phy2cs_data1		(phy2cs_data1[31:0]),
		  .phy2cs_k1		(phy2cs_k1));
		  
// synopsys translate_off
   defparam sata_gtx_phy.EXAMPLE_SIM_GTXRESET_SPEEDUP = 1;
// synopsys translate_on

end
else if (C_FAMILY == "spartan6")
begin: s6_gtp_top
   s6_gtp_top #(
	   .C_CHIPSCOPE  (C_CHIPSCOPE),
	   .C_SATA_SPEED (C_SATA_SPEED)
               )
     sata_gtx_phy(/*AUTOINST*/
		  // Outputs
		  .TXN0_OUT		(TXN0_OUT),
		  .TXP0_OUT		(TXP0_OUT),
		  .TXN1_OUT		(TXN1_OUT),
		  .TXP1_OUT		(TXP1_OUT),
		  .refclkout		(refclkout),
		  .plllkdet		(plllkdet),
		  .gtpclkfb		(gtpclkfb),
		  .txdatak_pop0		(txdatak_pop0),
		  .rxdata_fis0		(rxdata_fis0[31:0]),
		  .rxcharisk0		(rxcharisk0[3:0]),
		  .link_up0		(link_up0),
		  .CommInit0		(CommInit0),
		  .gtx_txdata0		(gtx_txdata0[31:0]),
		  .gtx_txdatak0		(gtx_txdatak0[3:0]),
		  .gtx_rxdata0		(gtx_rxdata0[31:0]),
		  .gtx_rxdatak0		(gtx_rxdatak0[3:0]),
		  .txdatak_pop1		(txdatak_pop1),
		  .rxdata_fis1		(rxdata_fis1[31:0]),
		  .rxcharisk1		(rxcharisk1[3:0]),
		  .link_up1		(link_up1),
		  .CommInit1		(CommInit1),
		  .gtx_txdata1		(gtx_txdata1[31:0]),
		  .gtx_txdatak1		(gtx_txdatak1[3:0]),
		  .gtx_rxdata1		(gtx_rxdata1[31:0]),
		  .gtx_rxdatak1		(gtx_rxdatak1[3:0]),
		  .oob2dbg0		(oob2dbg0[127:0]),
		  .oob2dbg1		(oob2dbg1[127:0]),
		  // Inputs
		  .GTXRESET_IN		(GTXRESET_IN),
		  .RXN0_IN		(RXN0_IN),
		  .RXP0_IN		(RXP0_IN),
		  .RXN1_IN		(RXN1_IN),
		  .RXP1_IN		(RXP1_IN),
		  .refclk		(refclk),
		  .dcm_locked		(dcm_locked),
		  .txusrclk0		(txusrclk0),
		  .txusrclk20		(txusrclk20),
		  .txdata_fis0		(txdata_fis0[31:0]),
		  .tx_charisk_fis0	(tx_charisk_fis0),
		  .phyreset0		(phyreset0),
		  .phyclk0		(phyclk0),
		  .StartComm0		(StartComm0),
		  .gtx_tune0		(gtx_tune0[31:0]),
		  .txdata_fis1		(txdata_fis1[31:0]),
		  .tx_charisk_fis1	(tx_charisk_fis1),
		  .phyreset1		(phyreset1),
		  .phyclk1		(phyclk1),
		  .StartComm1		(StartComm1),
		  .gtx_tune1		(gtx_tune1[31:0]),
		  .phy2cs_data0		(phy2cs_data0[31:0]),
		  .phy2cs_k0		(phy2cs_k0),
		  .phy2cs_data1		(phy2cs_data1[31:0]),
		  .phy2cs_k1		(phy2cs_k1));

// synopsys translate_off
   defparam sata_gtx_phy.EXAMPLE_SIM_GTXRESET_SPEEDUP = 1;
// synopsys translate_on

end
else if (C_FAMILY == "virtex6")
begin
end
else if (C_FAMILY == "kirtex6")
begin
end
endgenerate

   assign phyclk0 = txusrclk20;
   assign phyclk1 = txusrclk20;
endmodule
// Local Variables:
// verilog-library-directories:("." "s6_gtp" "v5_gtx")
// verilog-library-files:(".")
// verilog-library-extensions:(".v" ".h")
// End:
