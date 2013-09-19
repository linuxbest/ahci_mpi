// tb.v --- 
// 
// Filename: tb.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 18:31:21 2012 (+0800)
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
module tb;

   wire GTXRESET_IN;
   wire RXN0_IN;
   wire RXP0_IN;   
   wire RXN1_IN;
   wire RXP1_IN;   
   wire TXN0_IN;
   wire TXP0_IN;   
   wire TXN1_IN;
   wire TXP1_IN;   

   wire dcm_locked;

   wire irq0;
   wire irq1;

   wire refclk;
   wire refclkout;
   wire plllkdet;
   wire gtpclkfb;
   
   wire [31:0] readdata0;
   wire [31:0] readdata1;
   wire [127:0] oob2dbg0;
   wire [127:0] oob2dbg1;

   wire [31:0] 	address0;
   wire [31:0] 	address1;
   wire 	write0;
   wire 	write1;
   wire [31:0] 	writedata0;
   wire [31:0] 	writedata1;
   wire		sys_clk0;
   wire 	sys_clk1;
   wire 	sys_rst0;
   wire 	sys_rst1;
   wire 	txusrclk0;
   wire 	txusrclk20;

   wire [31:0] 	PIM_RdFIFO_Data1;
   wire [1:0] 	PIM_RdFIFO_Latency1;
   wire [3:0] 	PIM_RdFIFO_RdWdAddr1;
   
   wire [127:0] Trace_FW0;
   wire [127:0] Trace_FW1;

   wire [7:0] 	err_req0;
   wire [7:0] 	err_req1;
   wire [7:0] 	err_ack0;
   wire [7:0] 	err_ack1;

   reg MPMC_Clk0;
   wire MPMC_Rst0;
   
   reg sys_clk = 0;
   reg sys_rst = 1;
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			CommInit0;		// From gtx_0 of satagtx.v
   wire			CommInit1;		// From gtx_0 of satagtx.v
   wire [31:0]		PIM_Addr0;		// From dma0 of sata_dma.v
   wire [31:0]		PIM_Addr1;		// From dma1 of sata_dma.v
   wire			PIM_AddrAck0;		// From dgio of dgio.v
   wire			PIM_AddrReq0;		// From dma0 of sata_dma.v
   wire			PIM_AddrReq1;		// From dma1 of sata_dma.v
   wire			PIM_InitDone0;		// From dgio of dgio.v
   wire			PIM_RNW0;		// From dma0 of sata_dma.v
   wire			PIM_RNW1;		// From dma1 of sata_dma.v
   wire [31:0]		PIM_RdFIFO_Data0;	// From dgio of dgio.v
   wire			PIM_RdFIFO_Empty0;	// From dgio of dgio.v
   wire			PIM_RdFIFO_Flush0;	// From dma0 of sata_dma.v
   wire			PIM_RdFIFO_Flush1;	// From dma1 of sata_dma.v
   wire [1:0]		PIM_RdFIFO_Latency0;	// From dgio of dgio.v
   wire			PIM_RdFIFO_Pop0;	// From dma0 of sata_dma.v
   wire			PIM_RdFIFO_Pop1;	// From dma1 of sata_dma.v
   wire [3:0]		PIM_RdFIFO_RdWdAddr0;	// From dgio of dgio.v
   wire			PIM_RdModWr0;		// From dma0 of sata_dma.v
   wire			PIM_RdModWr1;		// From dma1 of sata_dma.v
   wire [3:0]		PIM_Size0;		// From dma0 of sata_dma.v
   wire [3:0]		PIM_Size1;		// From dma1 of sata_dma.v
   wire			PIM_WrFIFO_AlmostFull0;	// From dgio of dgio.v
   wire [3:0]		PIM_WrFIFO_BE0;		// From dma0 of sata_dma.v
   wire [3:0]		PIM_WrFIFO_BE1;		// From dma1 of sata_dma.v
   wire [31:0]		PIM_WrFIFO_Data0;	// From dma0 of sata_dma.v
   wire [31:0]		PIM_WrFIFO_Data1;	// From dma1 of sata_dma.v
   wire			PIM_WrFIFO_Empty0;	// From dgio of dgio.v
   wire			PIM_WrFIFO_Flush0;	// From dma0 of sata_dma.v
   wire			PIM_WrFIFO_Flush1;	// From dma1 of sata_dma.v
   wire			PIM_WrFIFO_Push0;	// From dma0 of sata_dma.v
   wire			PIM_WrFIFO_Push1;	// From dma1 of sata_dma.v
   wire			StartComm0;		// From dma0 of sata_dma.v
   wire			StartComm1;		// From dma1 of sata_dma.v
   wire			TXN0_OUT;		// From gtx_0 of satagtx.v
   wire			TXN1_OUT;		// From gtx_0 of satagtx.v
   wire			TXP0_OUT;		// From gtx_0 of satagtx.v
   wire			TXP1_OUT;		// From gtx_0 of satagtx.v
   wire [31:0]		dma_state0;		// From dma0 of sata_dma.v
   wire [31:0]		dma_state1;		// From dma1 of sata_dma.v
   wire [31:0]		gtx_rxdata0;		// From gtx_0 of satagtx.v
   wire [31:0]		gtx_rxdata1;		// From gtx_0 of satagtx.v
   wire [3:0]		gtx_rxdatak0;		// From gtx_0 of satagtx.v
   wire [3:0]		gtx_rxdatak1;		// From gtx_0 of satagtx.v
   wire [31:0]		gtx_tune0;		// From dma0 of sata_dma.v
   wire [31:0]		gtx_tune1;		// From dma1 of sata_dma.v
   wire [31:0]		gtx_txdata0;		// From gtx_0 of satagtx.v
   wire [31:0]		gtx_txdata1;		// From gtx_0 of satagtx.v
   wire [3:0]		gtx_txdatak0;		// From gtx_0 of satagtx.v
   wire [3:0]		gtx_txdatak1;		// From gtx_0 of satagtx.v
   wire			linkup0;		// From gtx_0 of satagtx.v
   wire			linkup1;		// From gtx_0 of satagtx.v
   wire			phyclk0;		// From gtx_0 of satagtx.v
   wire			phyclk1;		// From gtx_0 of satagtx.v
   wire			phyreset0;		// From dma0 of sata_dma.v
   wire			phyreset1;		// From dma1 of sata_dma.v
   wire			plllock0;		// From gtx_0 of satagtx.v
   wire			plllock1;		// From gtx_0 of satagtx.v
   wire [31:0]		rxdata0;		// From gtx_0 of satagtx.v
   wire [31:0]		rxdata1;		// From gtx_0 of satagtx.v
   wire			rxdatak0;		// From gtx_0 of satagtx.v
   wire			rxdatak1;		// From gtx_0 of satagtx.v
   wire			sata_ledA0;		// From dma0 of sata_dma.v
   wire			sata_ledA1;		// From dma1 of sata_dma.v
   wire			sata_ledB0;		// From dma0 of sata_dma.v
   wire			sata_ledB1;		// From dma1 of sata_dma.v
   wire [31:0]		txdata0;		// From dma0 of sata_dma.v
   wire [31:0]		txdata1;		// From dma1 of sata_dma.v
   wire			txdatak0;		// From dma0 of sata_dma.v
   wire			txdatak1;		// From dma1 of sata_dma.v
   wire			txdatak_pop0;		// From gtx_0 of satagtx.v
   wire			txdatak_pop1;		// From gtx_0 of satagtx.v
   // End of automatics

   parameter C_FAMILY = `C_FAMILY;
   parameter C_SUBFAMILY = `C_SUBFAMILY;
   parameter C_SATA_SPEED = 2;
   
   satagtx  #(
	      .C_FAMILY(C_FAMILY),
	      .C_SUBFAMILY(C_SUBFAMILY),
	      .C_SATA_SPEED(C_SATA_SPEED)
           )
   gtx_0   (/*AUTOINST*/
	    // Outputs
	    .TXN0_OUT			(TXN0_OUT),
	    .TXP0_OUT			(TXP0_OUT),
	    .TXN1_OUT			(TXN1_OUT),
	    .TXP1_OUT			(TXP1_OUT),
	    .refclkout			(refclkout),
	    .plllkdet			(plllkdet),
	    .gtpclkfb			(gtpclkfb),
	    .txdatak_pop0		(txdatak_pop0),
	    .rxdata0			(rxdata0[31:0]),
	    .rxdatak0			(rxdatak0),
	    .linkup0			(linkup0),
	    .plllock0			(plllock0),
	    .oob2dbg0			(oob2dbg0[127:0]),
	    .CommInit0			(CommInit0),
	    .phyclk0			(phyclk0),
	    .gtx_txdata0		(gtx_txdata0[31:0]),
	    .gtx_txdatak0		(gtx_txdatak0[3:0]),
	    .gtx_rxdata0		(gtx_rxdata0[31:0]),
	    .gtx_rxdatak0		(gtx_rxdatak0[3:0]),
	    .txdatak_pop1		(txdatak_pop1),
	    .rxdata1			(rxdata1[31:0]),
	    .rxdatak1			(rxdatak1),
	    .linkup1			(linkup1),
	    .plllock1			(plllock1),
	    .oob2dbg1			(oob2dbg1[127:0]),
	    .CommInit1			(CommInit1),
	    .phyclk1			(phyclk1),
	    .gtx_txdata1		(gtx_txdata1[31:0]),
	    .gtx_txdatak1		(gtx_txdatak1[3:0]),
	    .gtx_rxdata1		(gtx_rxdata1[31:0]),
	    .gtx_rxdatak1		(gtx_rxdatak1[3:0]),
	    // Inputs
	    .GTXRESET_IN		(GTXRESET_IN),
	    .sys_clk			(sys_clk),
	    .RXN0_IN			(RXN0_IN),
	    .RXP0_IN			(RXP0_IN),
	    .RXN1_IN			(RXN1_IN),
	    .RXP1_IN			(RXP1_IN),
	    .refclk			(refclk),
	    .dcm_locked			(dcm_locked),
	    .txusrclk0			(txusrclk0),
	    .txusrclk20			(txusrclk20),
	    .phyreset0			(phyreset0),
	    .txdata0			(txdata0[31:0]),
	    .txdatak0			(txdatak0),
	    .StartComm0			(StartComm0),
	    .gtx_tune0			(gtx_tune0[31:0]),
	    .phyreset1			(phyreset1),
	    .txdata1			(txdata1[31:0]),
	    .txdatak1			(txdatak1),
	    .StartComm1			(StartComm1),
	    .gtx_tune1			(gtx_tune1[31:0]));

   /*sata_dma AUTO_TEMPLATE 
    (
    .\(.*\) (\10[]),
    )*/
   sata_dma #(
	      .C_FAMILY(C_FAMILY)
      )
     dma0 (/*AUTOINST*/
	   // Outputs
	   .gtx_tune			(gtx_tune0[31:0]),	 // Templated
	   .phyreset			(phyreset0),		 // Templated
	   .sata_ledA			(sata_ledA0),		 // Templated
	   .sata_ledB			(sata_ledB0),		 // Templated
	   .PIM_Addr			(PIM_Addr0[31:0]),	 // Templated
	   .PIM_AddrReq			(PIM_AddrReq0),		 // Templated
	   .PIM_RNW			(PIM_RNW0),		 // Templated
	   .PIM_RdFIFO_Flush		(PIM_RdFIFO_Flush0),	 // Templated
	   .PIM_RdFIFO_Pop		(PIM_RdFIFO_Pop0),	 // Templated
	   .PIM_RdModWr			(PIM_RdModWr0),		 // Templated
	   .PIM_Size			(PIM_Size0[3:0]),	 // Templated
	   .PIM_WrFIFO_BE		(PIM_WrFIFO_BE0[3:0]),	 // Templated
	   .PIM_WrFIFO_Data		(PIM_WrFIFO_Data0[31:0]), // Templated
	   .PIM_WrFIFO_Flush		(PIM_WrFIFO_Flush0),	 // Templated
	   .PIM_WrFIFO_Push		(PIM_WrFIFO_Push0),	 // Templated
	   .StartComm			(StartComm0),		 // Templated
	   .dma_state			(dma_state0[31:0]),	 // Templated
	   .err_ack			(err_ack0[7:0]),	 // Templated
	   .irq				(irq0),			 // Templated
	   .readdata			(readdata0[31:0]),	 // Templated
	   .txdata			(txdata0[31:0]),	 // Templated
	   .txdatak			(txdatak0),		 // Templated
	   // Inputs
	   .sys_clk			(sys_clk0),		 // Templated
	   .sys_rst			(sys_rst0),		 // Templated
	   .CommInit			(CommInit0),		 // Templated
	   .MPMC_Clk			(MPMC_Clk0),		 // Templated
	   .PIM_AddrAck			(PIM_AddrAck0),		 // Templated
	   .PIM_InitDone		(PIM_InitDone0),	 // Templated
	   .PIM_RdFIFO_Data		(PIM_RdFIFO_Data0[31:0]), // Templated
	   .PIM_RdFIFO_Empty		(PIM_RdFIFO_Empty0),	 // Templated
	   .PIM_RdFIFO_Latency		(PIM_RdFIFO_Latency0[1:0]), // Templated
	   .PIM_RdFIFO_RdWdAddr		(PIM_RdFIFO_RdWdAddr0[3:0]), // Templated
	   .PIM_WrFIFO_AlmostFull	(PIM_WrFIFO_AlmostFull0), // Templated
	   .PIM_WrFIFO_Empty		(PIM_WrFIFO_Empty0),	 // Templated
	   .Trace_FW			(Trace_FW0[127:0]),	 // Templated
	   .address			(address0[5:0]),	 // Templated
	   .err_req			(err_req0[7:0]),	 // Templated
	   .gtx_rxdata			(gtx_rxdata0[31:0]),	 // Templated
	   .gtx_rxdatak			(gtx_rxdatak0[3:0]),	 // Templated
	   .gtx_txdata			(gtx_txdata0[31:0]),	 // Templated
	   .gtx_txdatak			(gtx_txdatak0[3:0]),	 // Templated
	   .linkup			(linkup0),		 // Templated
	   .oob2dbg			(oob2dbg0[127:0]),	 // Templated
	   .phyclk			(phyclk0),		 // Templated
	   .plllock			(plllock0),		 // Templated
	   .rxdata			(rxdata0[31:0]),	 // Templated
	   .rxdatak			(rxdatak0),		 // Templated
	   .txdatak_pop			(txdatak_pop0),		 // Templated
	   .write			(write0),		 // Templated
	   .writedata			(writedata0[31:0]));	 // Templated

   /*sata_dma AUTO_TEMPLATE 
    (
    .\(.*\) (\11[]),
    )*/
   sata_dma #(
	      .C_FAMILY(C_FAMILY)
      )
     dma1 (/*AUTOINST*/
	   // Outputs
	   .gtx_tune			(gtx_tune1[31:0]),	 // Templated
	   .phyreset			(phyreset1),		 // Templated
	   .sata_ledA			(sata_ledA1),		 // Templated
	   .sata_ledB			(sata_ledB1),		 // Templated
	   .PIM_Addr			(PIM_Addr1[31:0]),	 // Templated
	   .PIM_AddrReq			(PIM_AddrReq1),		 // Templated
	   .PIM_RNW			(PIM_RNW1),		 // Templated
	   .PIM_RdFIFO_Flush		(PIM_RdFIFO_Flush1),	 // Templated
	   .PIM_RdFIFO_Pop		(PIM_RdFIFO_Pop1),	 // Templated
	   .PIM_RdModWr			(PIM_RdModWr1),		 // Templated
	   .PIM_Size			(PIM_Size1[3:0]),	 // Templated
	   .PIM_WrFIFO_BE		(PIM_WrFIFO_BE1[3:0]),	 // Templated
	   .PIM_WrFIFO_Data		(PIM_WrFIFO_Data1[31:0]), // Templated
	   .PIM_WrFIFO_Flush		(PIM_WrFIFO_Flush1),	 // Templated
	   .PIM_WrFIFO_Push		(PIM_WrFIFO_Push1),	 // Templated
	   .StartComm			(StartComm1),		 // Templated
	   .dma_state			(dma_state1[31:0]),	 // Templated
	   .err_ack			(err_ack1[7:0]),	 // Templated
	   .irq				(irq1),			 // Templated
	   .readdata			(readdata1[31:0]),	 // Templated
	   .txdata			(txdata1[31:0]),	 // Templated
	   .txdatak			(txdatak1),		 // Templated
	   // Inputs
	   .sys_clk			(sys_clk1),		 // Templated
	   .sys_rst			(sys_rst1),		 // Templated
	   .CommInit			(CommInit1),		 // Templated
	   .MPMC_Clk			(MPMC_Clk1),		 // Templated
	   .PIM_AddrAck			(PIM_AddrAck1),		 // Templated
	   .PIM_InitDone		(PIM_InitDone1),	 // Templated
	   .PIM_RdFIFO_Data		(PIM_RdFIFO_Data1[31:0]), // Templated
	   .PIM_RdFIFO_Empty		(PIM_RdFIFO_Empty1),	 // Templated
	   .PIM_RdFIFO_Latency		(PIM_RdFIFO_Latency1[1:0]), // Templated
	   .PIM_RdFIFO_RdWdAddr		(PIM_RdFIFO_RdWdAddr1[3:0]), // Templated
	   .PIM_WrFIFO_AlmostFull	(PIM_WrFIFO_AlmostFull1), // Templated
	   .PIM_WrFIFO_Empty		(PIM_WrFIFO_Empty1),	 // Templated
	   .Trace_FW			(Trace_FW1[127:0]),	 // Templated
	   .address			(address1[5:0]),	 // Templated
	   .err_req			(err_req1[7:0]),	 // Templated
	   .gtx_rxdata			(gtx_rxdata1[31:0]),	 // Templated
	   .gtx_rxdatak			(gtx_rxdatak1[3:0]),	 // Templated
	   .gtx_txdata			(gtx_txdata1[31:0]),	 // Templated
	   .gtx_txdatak			(gtx_txdatak1[3:0]),	 // Templated
	   .linkup			(linkup1),		 // Templated
	   .oob2dbg			(oob2dbg1[127:0]),	 // Templated
	   .phyclk			(phyclk1),		 // Templated
	   .plllock			(plllock1),		 // Templated
	   .rxdata			(rxdata1[31:0]),	 // Templated
	   .rxdatak			(rxdatak1),		 // Templated
	   .txdatak_pop			(txdatak_pop1),		 // Templated
	   .write			(write1),		 // Templated
	   .writedata			(writedata1[31:0]));	 // Templated

   /*dgio AUTO_TEMPLATE 
    (
    .\(.*\) (\10[]),
    )*/
   dgio
     dgio (/*AUTOINST*/
	   // Outputs
	   .write			(write0),		 // Templated
	   .writedata			(writedata0[31:0]),	 // Templated
	   .address			(address0[5:0]),	 // Templated
	   .PIM_AddrAck			(PIM_AddrAck0),		 // Templated
	   .PIM_RdFIFO_RdWdAddr		(PIM_RdFIFO_RdWdAddr0[3:0]), // Templated
	   .PIM_RdFIFO_Data		(PIM_RdFIFO_Data0[31:0]), // Templated
	   .PIM_RdFIFO_Empty		(PIM_RdFIFO_Empty0),	 // Templated
	   .PIM_RdFIFO_Latency		(PIM_RdFIFO_Latency0[1:0]), // Templated
	   .PIM_WrFIFO_Empty		(PIM_WrFIFO_Empty0),	 // Templated
	   .PIM_WrFIFO_AlmostFull	(PIM_WrFIFO_AlmostFull0), // Templated
	   .PIM_InitDone		(PIM_InitDone0),	 // Templated
	   // Inputs
	   .sys_clk			(sys_clk0),		 // Templated
	   .sys_rst			(sys_rst0),		 // Templated
	   .MPMC_Clk			(MPMC_Clk0),		 // Templated
	   .MPMC_Rst			(MPMC_Rst0),		 // Templated
	   .readdata			(readdata0[31:0]),	 // Templated
	   .irq				(irq0),			 // Templated
	   .PIM_Addr			(PIM_Addr0[31:0]),	 // Templated
	   .PIM_AddrReq			(PIM_AddrReq0),		 // Templated
	   .PIM_RNW			(PIM_RNW0),		 // Templated
	   .PIM_Size			(PIM_Size0[3:0]),	 // Templated
	   .PIM_RdModWr			(PIM_RdModWr0),		 // Templated
	   .PIM_RdFIFO_Flush		(PIM_RdFIFO_Flush0),	 // Templated
	   .PIM_RdFIFO_Pop		(PIM_RdFIFO_Pop0),	 // Templated
	   .PIM_WrFIFO_Data		(PIM_WrFIFO_Data0[31:0]), // Templated
	   .PIM_WrFIFO_BE		(PIM_WrFIFO_BE0[3:0]),	 // Templated
	   .PIM_WrFIFO_Push		(PIM_WrFIFO_Push0),	 // Templated
	   .PIM_WrFIFO_Flush		(PIM_WrFIFO_Flush0));	 // Templated
   
   reg 		TILE0_REFCLK_PAD_P_IN;
   localparam real 	GTP_CLK_REF    = 3333;
   initial begin
      TILE0_REFCLK_PAD_P_IN = 1'b0;
      #(GTP_CLK_REF);
      forever #(GTP_CLK_REF) TILE0_REFCLK_PAD_P_IN = ~TILE0_REFCLK_PAD_P_IN;
   end

   device_sim
     dev0 (.TXP_OUT0(RXP0_IN),
	   .TXN_OUT0(RXN0_IN),
	   .RXP_IN0 (TXP0_OUT),
	   .RXN_IN0 (TXN0_OUT));

   satagtx_clk #(
	      .C_FAMILY(C_FAMILY),
	      .C_SUBFAMILY(C_SUBFAMILY),
	      .C_SATA_SPEED(C_SATA_SPEED)
	)
     clk0 (.tile0_refclk(refclk),
           .tile0_gtpclkfb(gtpclkfb),
	   .refclkout_dcm0_locked(dcm_locked),
	   .tile0_txusrclk0(txusrclk0),
	   .tile0_txusrclk20(txusrclk20),
	   .TILE0_REFCLK_PAD_P_IN(TILE0_REFCLK_PAD_P_IN),
	   .TILE0_REFCLK_PAD_N_IN(~TILE0_REFCLK_PAD_P_IN),
	   .tile0_refclkout(refclkout),
	   .tile0_plllkdet(plllkdet));

   assign sys_clk0 = sys_clk;
   assign sys_clk1 = sys_clk;
   assign sys_rst0 = sys_rst;
   assign sys_rst1 = sys_rst;
   real sys_clk_pin_PERIOD = 10000.000000;
   real sys_rst_pin_LENGTH = 160000;

   initial begin
      sys_clk = 1'b0;
      forever #(sys_clk_pin_PERIOD/2) sys_clk = ~sys_clk;
   end
   initial begin
      sys_rst = 1'b1;
      #(sys_rst_pin_LENGTH)      sys_rst = ~sys_rst;
   end
   assign GTXRESET_IN = sys_rst;
   assign MPMC_Rst0   = sys_rst;
   initial begin
      MPMC_Clk0 = 1'b1;
      forever #(sys_clk_pin_PERIOD/4) MPMC_Clk0 = ~MPMC_Clk0;
   end

   assign err_req0 = 8'h3;
   assign err_req1 = 8'h0;
endmodule // tb
// Local Variables:
// verilog-library-directories:(".""../verilog/" "../../../../pcores/satagtx_v1_00_a/hdl/verilog/")
// verilog-library-files:(".""sata_phy")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// tb.v ends here
