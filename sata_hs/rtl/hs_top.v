// hs_top.v --- 
// 
// Filename: hs_top.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Feb 24 14:39:05 2012 (+0800)
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
module hs_top (/*AUTOARG*/
   // Outputs
   txdatak3, txdatak2, txdatak1, txdatak0, txdata3, txdata2, txdata1,
   txdata0, sata_ledB3, sata_ledB2, sata_ledB1, sata_ledB0,
   sata_ledA3, sata_ledA2, sata_ledA1, sata_ledA0, phyreset3,
   phyreset2, phyreset1, phyreset0, interrupt, ilmb_BRAM_Din,
   gtx_tune3, gtx_tune2, gtx_tune1, gtx_tune0, dlmb_BRAM_Din,
   cmd_raddr3, cmd_raddr2, cmd_raddr1, cmd_raddr0, WrFIFO_Full3,
   WrFIFO_Full2, WrFIFO_Full1, WrFIFO_Full0, WrFIFO_Empty3,
   WrFIFO_Empty2, WrFIFO_Empty1, WrFIFO_Empty0, WrFIFO_DataSize3,
   WrFIFO_DataSize2, WrFIFO_DataSize1, WrFIFO_DataSize0,
   WrFIFO_DataReq3, WrFIFO_DataReq2, WrFIFO_DataReq1, WrFIFO_DataReq0,
   WrFIFO_DataId3, WrFIFO_DataId2, WrFIFO_DataId1, WrFIFO_DataId0,
   StartComm3, StartComm2, StartComm1, StartComm0, RdFIFO_Full3,
   RdFIFO_Full2, RdFIFO_Full1, RdFIFO_Full0, RdFIFO_Empty3,
   RdFIFO_Empty2, RdFIFO_Empty1, RdFIFO_Empty0, RdFIFO_DataSize3,
   RdFIFO_DataSize2, RdFIFO_DataSize1, RdFIFO_DataSize0,
   RdFIFO_DataReq3, RdFIFO_DataReq2, RdFIFO_DataReq1, RdFIFO_DataReq0,
   RdFIFO_DataId3, RdFIFO_DataId2, RdFIFO_DataId1, RdFIFO_DataId0,
   RdFIFO_Data3, RdFIFO_Data2, RdFIFO_Data1, RdFIFO_Data0,
   ICACHE_FSL_OUT_WRITE, ICACHE_FSL_OUT_DATA, ICACHE_FSL_OUT_CONTROL,
   ICACHE_FSL_OUT_CLK, ICACHE_FSL_IN_READ, ICACHE_FSL_IN_CLK,
   DCACHE_FSL_OUT_WRITE, DCACHE_FSL_OUT_DATA, DCACHE_FSL_OUT_CONTROL,
   DCACHE_FSL_OUT_CLK, DCACHE_FSL_IN_READ, DCACHE_FSL_IN_CLK, DBG_TDO,
   M_Lock, Sl_dcrDBus, Sl_dcrAck, PIM_Addr, PIM_AddrReq, PIM_RNW,
   PIM_Size, PIM_RdModWr, PIM_WrFIFO_Data, PIM_WrFIFO_BE,
   PIM_WrFIFO_Push, PIM_RdFIFO_Pop, PIM_WrFIFO_Flush,
   PIM_RdFIFO_Flush,
   // Inputs
   txdatak_pop3, txdatak_pop2, txdatak_pop1, txdatak_pop0,
   rxfifo_irq3, rxfifo_irq2, rxfifo_irq1, rxfifo_irq0, rxdatak3,
   rxdatak2, rxdatak1, rxdatak0, rxdata3, rxdata2, rxdata1, rxdata0,
   plllock3, plllock2, plllock1, plllock0, phyclk3, phyclk2, phyclk1,
   phyclk0, oob2dbg3, oob2dbg2, oob2dbg1, oob2dbg0, npi_ict_state,
   linkup3, linkup2, linkup1, linkup0, ilmb_BRAM_WEN, ilmb_BRAM_Rst,
   ilmb_BRAM_EN, ilmb_BRAM_Dout, ilmb_BRAM_Clk, ilmb_BRAM_Addr,
   gtx_txdatak3, gtx_txdatak2, gtx_txdatak1, gtx_txdatak0,
   gtx_txdata3, gtx_txdata2, gtx_txdata1, gtx_txdata0, gtx_rxdatak3,
   gtx_rxdatak2, gtx_rxdatak1, gtx_rxdatak0, gtx_rxdata3, gtx_rxdata2,
   gtx_rxdata1, gtx_rxdata0, dma_state3, dma_state2, dma_state1,
   dma_state0, dlmb_BRAM_WEN, dlmb_BRAM_Rst, dlmb_BRAM_EN,
   dlmb_BRAM_Dout, dlmb_BRAM_Clk, dlmb_BRAM_Addr, cmd_rdata3,
   cmd_rdata2, cmd_rdata1, cmd_rdata0, WrFIFO_Push3, WrFIFO_Push2,
   WrFIFO_Push1, WrFIFO_Push0, WrFIFO_DataAck3, WrFIFO_DataAck2,
   WrFIFO_DataAck1, WrFIFO_DataAck0, WrFIFO_Data3, WrFIFO_Data2,
   WrFIFO_Data1, WrFIFO_Data0, RdFIFO_Pop3, RdFIFO_Pop2, RdFIFO_Pop1,
   RdFIFO_Pop0, RdFIFO_DataAck3, RdFIFO_DataAck2, RdFIFO_DataAck1,
   RdFIFO_DataAck0, ICACHE_FSL_OUT_FULL, ICACHE_FSL_IN_EXISTS,
   ICACHE_FSL_IN_DATA, ICACHE_FSL_IN_CONTROL, DCACHE_FSL_OUT_FULL,
   DCACHE_FSL_IN_EXISTS, DCACHE_FSL_IN_DATA, DCACHE_FSL_IN_CONTROL,
   DBG_UPDATE, DBG_TDI, DBG_SHIFT, DBG_RST, DBG_REG_EN, DBG_CLK,
   DBG_CAPTURE, CommInit3, CommInit2, CommInit1, CommInit0, M_Clk,
   M_Reset, M_Error, DCR_Clk, DCR_Rst, DCR_Read, DCR_Write, DCR_ABus,
   DCR_Sl_DBus, MPMC_Clk, PIM_AddrAck, PIM_RdFIFO_Data,
   PIM_RdFIFO_RdWdAddr, PIM_WrFIFO_Empty, PIM_WrFIFO_AlmostFull,
   PIM_RdFIFO_Empty, PIM_RdFIFO_Latency, PIM_InitDone
   );
   parameter C_PORT = 4;
   parameter C_FAMILY = "virtex5";
   parameter C_DPLB_DWIDTH = 128;
   parameter C_DPLB_NATIVE_DWIDTH = 32;
   parameter C_DPLB_BURST_EN = 0;
   parameter C_DPLB_P2P = 0;
   parameter C_NUM_WIDTH = 5;
   parameter C_VERSION = 32'hdeadbeef;
   parameter C_DAT_WIDTH = 64;
   parameter C_DEBUG_ENABLED = 0;
   parameter C_SATA_CHIPSCOPE = 0;
   parameter C_XCL_CHIPSCOPE = 0;
   parameter C_NPI_CHIPSCOPE = 0;
   
   // PIM parameter start
   parameter C_NUM_PORTS = 5;

   parameter C_PIM0_DATA_WIDTH = 32;
   parameter C_PIM0_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM0_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM0_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM0_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM0_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM0_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM1_DATA_WIDTH = 32;
   parameter C_PIM1_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM1_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM1_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM1_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM1_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM1_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM2_DATA_WIDTH = 32;
   parameter C_PIM2_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM2_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM2_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM2_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM2_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM2_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM3_DATA_WIDTH = 32;
   parameter C_PIM3_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM3_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM3_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM3_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM3_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM3_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM4_DATA_WIDTH = 32;
   parameter C_PIM4_RD_FIFO_TYPE = "BRAM";
   parameter C_PIM4_WR_FIFO_TYPE = "BRAM";
   parameter C_PIM4_RD_FIFO_APP_PIPELINE = 1;
   parameter C_PIM4_RD_FIFO_MEM_PIPELINE = 1;
   parameter C_PIM4_WR_FIFO_APP_PIPELINE = 1;
   parameter C_PIM4_WR_FIFO_MEM_PIPELINE = 1;

   parameter C_PIM_DATA_WIDTH = 64;   
   // PIM parameter end
   
   input M_Clk;
   input M_Reset;
   input M_Error;
   output M_Lock;

   input  DCR_Clk;
   input  DCR_Rst;
   input  DCR_Read;
   input  DCR_Write;
   input [0:9] DCR_ABus;
   input [0:31] DCR_Sl_DBus;
   output [0:31] Sl_dcrDBus;
   output 	 Sl_dcrAck;

   wire 	 sys_clk;
   wire 	 sys_rst;
   assign sys_clk = DCR_Clk;
   
   wire          MPMC_Rst;
   assign MPMC_Rst= sys_rst;

   input 	 MPMC_Clk;
   output [31:0] PIM_Addr;
   output 	 PIM_AddrReq;
   input 	 PIM_AddrAck;
   output 	 PIM_RNW;
   output [3:0]  PIM_Size;
   output 	 PIM_RdModWr;
   output [63:0] PIM_WrFIFO_Data;
   output [7:0]  PIM_WrFIFO_BE;
   output 	 PIM_WrFIFO_Push;
   input [63:0]  PIM_RdFIFO_Data;
   output 	 PIM_RdFIFO_Pop;
   input [3:0] 	 PIM_RdFIFO_RdWdAddr;
   input 	 PIM_WrFIFO_Empty;
   input 	 PIM_WrFIFO_AlmostFull;
   output 	 PIM_WrFIFO_Flush;
   input 	 PIM_RdFIFO_Empty;
   output 	 PIM_RdFIFO_Flush;
   input [1:0] 	 PIM_RdFIFO_Latency;
   input 	 PIM_InitDone;
   
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		CommInit0;		// To dma0 of hs_if.v
   input		CommInit1;		// To dma1 of hs_if.v
   input		CommInit2;		// To dma2 of hs_if.v
   input		CommInit3;		// To dma3 of hs_if.v
   input		DBG_CAPTURE;		// To mb_top of mb_top.v
   input		DBG_CLK;		// To mb_top of mb_top.v
   input [0:7]		DBG_REG_EN;		// To mb_top of mb_top.v
   input		DBG_RST;		// To mb_top of mb_top.v
   input		DBG_SHIFT;		// To mb_top of mb_top.v
   input		DBG_TDI;		// To mb_top of mb_top.v
   input		DBG_UPDATE;		// To mb_top of mb_top.v
   input		DCACHE_FSL_IN_CONTROL;	// To mb_top of mb_top.v
   input [0:31]		DCACHE_FSL_IN_DATA;	// To mb_top of mb_top.v
   input		DCACHE_FSL_IN_EXISTS;	// To mb_top of mb_top.v
   input		DCACHE_FSL_OUT_FULL;	// To mb_top of mb_top.v
   input		ICACHE_FSL_IN_CONTROL;	// To mb_top of mb_top.v
   input [0:31]		ICACHE_FSL_IN_DATA;	// To mb_top of mb_top.v
   input		ICACHE_FSL_IN_EXISTS;	// To mb_top of mb_top.v
   input		ICACHE_FSL_OUT_FULL;	// To mb_top of mb_top.v
   input		RdFIFO_DataAck0;	// To dma0 of hs_if.v
   input		RdFIFO_DataAck1;	// To dma1 of hs_if.v
   input		RdFIFO_DataAck2;	// To dma2 of hs_if.v
   input		RdFIFO_DataAck3;	// To dma3 of hs_if.v
   input		RdFIFO_Pop0;		// To dma0 of hs_if.v
   input		RdFIFO_Pop1;		// To dma1 of hs_if.v
   input		RdFIFO_Pop2;		// To dma2 of hs_if.v
   input		RdFIFO_Pop3;		// To dma3 of hs_if.v
   input [31:0]		WrFIFO_Data0;		// To dma0 of hs_if.v
   input [31:0]		WrFIFO_Data1;		// To dma1 of hs_if.v
   input [31:0]		WrFIFO_Data2;		// To dma2 of hs_if.v
   input [31:0]		WrFIFO_Data3;		// To dma3 of hs_if.v
   input		WrFIFO_DataAck0;	// To dma0 of hs_if.v
   input		WrFIFO_DataAck1;	// To dma1 of hs_if.v
   input		WrFIFO_DataAck2;	// To dma2 of hs_if.v
   input		WrFIFO_DataAck3;	// To dma3 of hs_if.v
   input		WrFIFO_Push0;		// To dma0 of hs_if.v
   input		WrFIFO_Push1;		// To dma1 of hs_if.v
   input		WrFIFO_Push2;		// To dma2 of hs_if.v
   input		WrFIFO_Push3;		// To dma3 of hs_if.v
   input [31:0]		cmd_rdata0;		// To dma0 of hs_if.v
   input [31:0]		cmd_rdata1;		// To dma1 of hs_if.v
   input [31:0]		cmd_rdata2;		// To dma2 of hs_if.v
   input [31:0]		cmd_rdata3;		// To dma3 of hs_if.v
   input [0:31]		dlmb_BRAM_Addr;		// To mb_top of mb_top.v
   input		dlmb_BRAM_Clk;		// To mb_top of mb_top.v
   input [0:31]		dlmb_BRAM_Dout;		// To mb_top of mb_top.v
   input		dlmb_BRAM_EN;		// To mb_top of mb_top.v
   input		dlmb_BRAM_Rst;		// To mb_top of mb_top.v
   input [0:3]		dlmb_BRAM_WEN;		// To mb_top of mb_top.v
   input [31:0]		dma_state0;		// To host_if of host_if.v
   input [31:0]		dma_state1;		// To host_if of host_if.v
   input [31:0]		dma_state2;		// To host_if of host_if.v
   input [31:0]		dma_state3;		// To host_if of host_if.v
   input [31:0]		gtx_rxdata0;		// To dma0 of hs_if.v
   input [31:0]		gtx_rxdata1;		// To dma1 of hs_if.v
   input [31:0]		gtx_rxdata2;		// To dma2 of hs_if.v
   input [31:0]		gtx_rxdata3;		// To dma3 of hs_if.v
   input [3:0]		gtx_rxdatak0;		// To dma0 of hs_if.v
   input [3:0]		gtx_rxdatak1;		// To dma1 of hs_if.v
   input [3:0]		gtx_rxdatak2;		// To dma2 of hs_if.v
   input [3:0]		gtx_rxdatak3;		// To dma3 of hs_if.v
   input [31:0]		gtx_txdata0;		// To dma0 of hs_if.v
   input [31:0]		gtx_txdata1;		// To dma1 of hs_if.v
   input [31:0]		gtx_txdata2;		// To dma2 of hs_if.v
   input [31:0]		gtx_txdata3;		// To dma3 of hs_if.v
   input [3:0]		gtx_txdatak0;		// To dma0 of hs_if.v
   input [3:0]		gtx_txdatak1;		// To dma1 of hs_if.v
   input [3:0]		gtx_txdatak2;		// To dma2 of hs_if.v
   input [3:0]		gtx_txdatak3;		// To dma3 of hs_if.v
   input [0:31]		ilmb_BRAM_Addr;		// To mb_top of mb_top.v
   input		ilmb_BRAM_Clk;		// To mb_top of mb_top.v
   input [0:31]		ilmb_BRAM_Dout;		// To mb_top of mb_top.v
   input		ilmb_BRAM_EN;		// To mb_top of mb_top.v
   input		ilmb_BRAM_Rst;		// To mb_top of mb_top.v
   input [0:3]		ilmb_BRAM_WEN;		// To mb_top of mb_top.v
   input		linkup0;		// To dma0 of hs_if.v
   input		linkup1;		// To dma1 of hs_if.v
   input		linkup2;		// To dma2 of hs_if.v
   input		linkup3;		// To dma3 of hs_if.v
   input [31:0]		npi_ict_state;		// To host_if of host_if.v
   input [127:0]	oob2dbg0;		// To dma0 of hs_if.v
   input [127:0]	oob2dbg1;		// To dma1 of hs_if.v
   input [127:0]	oob2dbg2;		// To dma2 of hs_if.v
   input [127:0]	oob2dbg3;		// To dma3 of hs_if.v
   input		phyclk0;		// To dma0 of hs_if.v, ...
   input		phyclk1;		// To dma1 of hs_if.v, ...
   input		phyclk2;		// To dma2 of hs_if.v, ...
   input		phyclk3;		// To dma3 of hs_if.v, ...
   input		plllock0;		// To dma0 of hs_if.v
   input		plllock1;		// To dma1 of hs_if.v
   input		plllock2;		// To dma2 of hs_if.v
   input		plllock3;		// To dma3 of hs_if.v
   input [31:0]		rxdata0;		// To dma0 of hs_if.v
   input [31:0]		rxdata1;		// To dma1 of hs_if.v
   input [31:0]		rxdata2;		// To dma2 of hs_if.v
   input [31:0]		rxdata3;		// To dma3 of hs_if.v
   input		rxdatak0;		// To dma0 of hs_if.v
   input		rxdatak1;		// To dma1 of hs_if.v
   input		rxdatak2;		// To dma2 of hs_if.v
   input		rxdatak3;		// To dma3 of hs_if.v
   input		rxfifo_irq0;		// To dma0 of hs_if.v
   input		rxfifo_irq1;		// To dma1 of hs_if.v
   input		rxfifo_irq2;		// To dma2 of hs_if.v
   input		rxfifo_irq3;		// To dma3 of hs_if.v
   input		txdatak_pop0;		// To dma0 of hs_if.v
   input		txdatak_pop1;		// To dma1 of hs_if.v
   input		txdatak_pop2;		// To dma2 of hs_if.v
   input		txdatak_pop3;		// To dma3 of hs_if.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output		DBG_TDO;		// From mb_top of mb_top.v
   output		DCACHE_FSL_IN_CLK;	// From mb_top of mb_top.v
   output		DCACHE_FSL_IN_READ;	// From mb_top of mb_top.v
   output		DCACHE_FSL_OUT_CLK;	// From mb_top of mb_top.v
   output		DCACHE_FSL_OUT_CONTROL;	// From mb_top of mb_top.v
   output [0:31]	DCACHE_FSL_OUT_DATA;	// From mb_top of mb_top.v
   output		DCACHE_FSL_OUT_WRITE;	// From mb_top of mb_top.v
   output		ICACHE_FSL_IN_CLK;	// From mb_top of mb_top.v
   output		ICACHE_FSL_IN_READ;	// From mb_top of mb_top.v
   output		ICACHE_FSL_OUT_CLK;	// From mb_top of mb_top.v
   output		ICACHE_FSL_OUT_CONTROL;	// From mb_top of mb_top.v
   output [0:31]	ICACHE_FSL_OUT_DATA;	// From mb_top of mb_top.v
   output		ICACHE_FSL_OUT_WRITE;	// From mb_top of mb_top.v
   output [31:0]	RdFIFO_Data0;		// From dma0 of hs_if.v
   output [31:0]	RdFIFO_Data1;		// From dma1 of hs_if.v
   output [31:0]	RdFIFO_Data2;		// From dma2 of hs_if.v
   output [31:0]	RdFIFO_Data3;		// From dma3 of hs_if.v
   output [4:0]		RdFIFO_DataId0;		// From dma0 of hs_if.v
   output [4:0]		RdFIFO_DataId1;		// From dma1 of hs_if.v
   output [4:0]		RdFIFO_DataId2;		// From dma2 of hs_if.v
   output [4:0]		RdFIFO_DataId3;		// From dma3 of hs_if.v
   output		RdFIFO_DataReq0;	// From dma0 of hs_if.v
   output		RdFIFO_DataReq1;	// From dma1 of hs_if.v
   output		RdFIFO_DataReq2;	// From dma2 of hs_if.v
   output		RdFIFO_DataReq3;	// From dma3 of hs_if.v
   output [7:0]		RdFIFO_DataSize0;	// From dma0 of hs_if.v
   output [7:0]		RdFIFO_DataSize1;	// From dma1 of hs_if.v
   output [7:0]		RdFIFO_DataSize2;	// From dma2 of hs_if.v
   output [7:0]		RdFIFO_DataSize3;	// From dma3 of hs_if.v
   output		RdFIFO_Empty0;		// From dma0 of hs_if.v
   output		RdFIFO_Empty1;		// From dma1 of hs_if.v
   output		RdFIFO_Empty2;		// From dma2 of hs_if.v
   output		RdFIFO_Empty3;		// From dma3 of hs_if.v
   output		RdFIFO_Full0;		// From dma0 of hs_if.v
   output		RdFIFO_Full1;		// From dma1 of hs_if.v
   output		RdFIFO_Full2;		// From dma2 of hs_if.v
   output		RdFIFO_Full3;		// From dma3 of hs_if.v
   output		StartComm0;		// From dma0 of hs_if.v
   output		StartComm1;		// From dma1 of hs_if.v
   output		StartComm2;		// From dma2 of hs_if.v
   output		StartComm3;		// From dma3 of hs_if.v
   output [4:0]		WrFIFO_DataId0;		// From dma0 of hs_if.v
   output [4:0]		WrFIFO_DataId1;		// From dma1 of hs_if.v
   output [4:0]		WrFIFO_DataId2;		// From dma2 of hs_if.v
   output [4:0]		WrFIFO_DataId3;		// From dma3 of hs_if.v
   output		WrFIFO_DataReq0;	// From dma0 of hs_if.v
   output		WrFIFO_DataReq1;	// From dma1 of hs_if.v
   output		WrFIFO_DataReq2;	// From dma2 of hs_if.v
   output		WrFIFO_DataReq3;	// From dma3 of hs_if.v
   output [7:0]		WrFIFO_DataSize0;	// From dma0 of hs_if.v
   output [7:0]		WrFIFO_DataSize1;	// From dma1 of hs_if.v
   output [7:0]		WrFIFO_DataSize2;	// From dma2 of hs_if.v
   output [7:0]		WrFIFO_DataSize3;	// From dma3 of hs_if.v
   output		WrFIFO_Empty0;		// From dma0 of hs_if.v
   output		WrFIFO_Empty1;		// From dma1 of hs_if.v
   output		WrFIFO_Empty2;		// From dma2 of hs_if.v
   output		WrFIFO_Empty3;		// From dma3 of hs_if.v
   output		WrFIFO_Full0;		// From dma0 of hs_if.v
   output		WrFIFO_Full1;		// From dma1 of hs_if.v
   output		WrFIFO_Full2;		// From dma2 of hs_if.v
   output		WrFIFO_Full3;		// From dma3 of hs_if.v
   output [4:0]		cmd_raddr0;		// From dma0 of hs_if.v
   output [4:0]		cmd_raddr1;		// From dma1 of hs_if.v
   output [4:0]		cmd_raddr2;		// From dma2 of hs_if.v
   output [4:0]		cmd_raddr3;		// From dma3 of hs_if.v
   output [0:31]	dlmb_BRAM_Din;		// From mb_top of mb_top.v
   output [31:0]	gtx_tune0;		// From dma0 of hs_if.v
   output [31:0]	gtx_tune1;		// From dma1 of hs_if.v
   output [31:0]	gtx_tune2;		// From dma2 of hs_if.v
   output [31:0]	gtx_tune3;		// From dma3 of hs_if.v
   output [0:31]	ilmb_BRAM_Din;		// From mb_top of mb_top.v
   output		interrupt;		// From host_if of host_if.v
   output		phyreset0;		// From dma0 of hs_if.v
   output		phyreset1;		// From dma1 of hs_if.v
   output		phyreset2;		// From dma2 of hs_if.v
   output		phyreset3;		// From dma3 of hs_if.v
   output		sata_ledA0;		// From dma0 of hs_if.v
   output		sata_ledA1;		// From dma1 of hs_if.v
   output		sata_ledA2;		// From dma2 of hs_if.v
   output		sata_ledA3;		// From dma3 of hs_if.v
   output		sata_ledB0;		// From dma0 of hs_if.v
   output		sata_ledB1;		// From dma1 of hs_if.v
   output		sata_ledB2;		// From dma2 of hs_if.v
   output		sata_ledB3;		// From dma3 of hs_if.v
   output [31:0]	txdata0;		// From dma0 of hs_if.v
   output [31:0]	txdata1;		// From dma1 of hs_if.v
   output [31:0]	txdata2;		// From dma2 of hs_if.v
   output [31:0]	txdata3;		// From dma3 of hs_if.v
   output		txdatak0;		// From dma0 of hs_if.v
   output		txdatak1;		// From dma1 of hs_if.v
   output		txdatak2;		// From dma2 of hs_if.v
   output		txdatak3;		// From dma3 of hs_if.v
   // End of automatics

   wire 		irq0;
   wire 		irq1;
   wire 		irq2;
   wire 		irq3;
   wire [31:0] 		io_readdata0;
   wire [31:0] 		io_readdata1;
   wire [31:0] 		io_readdata2;
   wire [31:0] 		io_readdata3;
   wire                 PIM0_AddrReq;
   wire                 PIM1_AddrReq;
   wire                 PIM2_AddrReq;
   wire                 PIM3_AddrReq;
   wire                 PIM4_AddrReq;
   wire                 PIM0_WrFIFO_Push;
   wire                 PIM1_WrFIFO_Push;
   wire                 PIM2_WrFIFO_Push;
   wire                 PIM3_WrFIFO_Push;
   wire                 PIM4_WrFIFO_Push;
   wire                 MPMC_Clk0;
   wire                 MPMC_Clk1;
   wire                 MPMC_Clk2;
   wire                 MPMC_Clk3;
   wire                 MPMC_Clk4;
   wire                 MPMC_Rst0;
   wire                 MPMC_Rst1;
   wire                 MPMC_Rst2;
   wire                 MPMC_Rst3;
   wire                 MPMC_Rst4;
   assign MPMC_Clk0 = MPMC_Clk;
   assign MPMC_Clk1 = MPMC_Clk;
   assign MPMC_Clk2 = MPMC_Clk;
   assign MPMC_Clk3 = MPMC_Clk;
   assign MPMC_Clk4 = MPMC_Clk;
   assign MPMC_Rst0 = sys_rst;
   assign MPMC_Rst1 = sys_rst;
   assign MPMC_Rst2 = sys_rst;
   assign MPMC_Rst3 = sys_rst;
   assign MPMC_Rst4 = sys_rst;

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			DBG_STOP;		// From host_if of host_if.v
   wire [127:0]		Trace_FW0;		// From mb_top of mb_top.v
   wire [127:0]		Trace_FW1;		// From mb_top of mb_top.v
   wire [127:0]		Trace_FW2;		// From mb_top of mb_top.v
   wire [127:0]		Trace_FW3;		// From mb_top of mb_top.v
   wire [7:0]		err_ack0;		// From dma0 of hs_if.v
   wire [7:0]		err_ack1;		// From dma1 of hs_if.v
   wire [7:0]		err_ack2;		// From dma2 of hs_if.v
   wire [7:0]		err_ack3;		// From dma3 of hs_if.v
   wire [7:0]		err_req0;		// From host_if of host_if.v
   wire [7:0]		err_req1;		// From host_if of host_if.v
   wire [7:0]		err_req2;		// From host_if of host_if.v
   wire [7:0]		err_req3;		// From host_if of host_if.v
   wire [31:0]		inband_base;		// From host_if of host_if.v
   wire [31:0]		inband_cons_addr;	// From host_if of host_if.v
   wire [11:0]		inband_cons_index;	// From mb_top of mb_top.v
   wire [11:0]		inband_prod_index;	// From host_if of host_if.v
   wire [5:0]		io_address0;		// From mb_top of mb_top.v
   wire [5:0]		io_address1;		// From mb_top of mb_top.v
   wire [5:0]		io_address2;		// From mb_top of mb_top.v
   wire [5:0]		io_address3;		// From mb_top of mb_top.v
   wire			io_write0;		// From mb_top of mb_top.v
   wire			io_write1;		// From mb_top of mb_top.v
   wire			io_write2;		// From mb_top of mb_top.v
   wire			io_write3;		// From mb_top of mb_top.v
   wire [31:0]		io_writedata0;		// From mb_top of mb_top.v
   wire [31:0]		io_writedata1;		// From mb_top of mb_top.v
   wire [31:0]		io_writedata2;		// From mb_top of mb_top.v
   wire [31:0]		io_writedata3;		// From mb_top of mb_top.v
   wire [31:0]		outband_base;		// From host_if of host_if.v
   wire [11:0]		outband_cons_index;	// From host_if of host_if.v
   wire [31:0]		outband_prod_addr;	// From host_if of host_if.v
   wire [11:0]		outband_prod_index;	// From mb_top of mb_top.v
   wire			ring_enable;		// From host_if of host_if.v
   // End of automatics
   
   /*hs_if AUTO_TEMPLATE "\([0-9]\)"
    (
    .sys_clk    (sys_clk),
    .sys_rst    (sys_rst),
    .write      (io_write@[]),
    .writedata  (io_writedata@[]),
    .readdata   (io_readdata@[]),
    .address    (io_address@[]),
    .PIM_\(.*\)    (PIM@_\1[]),
    .MBPIM_\(.*\)  (PIM4_\1[]),    
    .DMAPIM_\(.*\) (PIM@_\1[]),
    .MPMCPIM_\(.*\)(PIM_\1[]),    
    .\(.*\)        (\1@[]),
    )*/
   generate if (C_PORT > 0)
     begin: aport0
	hs_if #(.C_PORT(1), .C_SATA_CHIPSCOPE(C_SATA_CHIPSCOPE), .C_FAMILY(C_FAMILY))
	         dma0 (/*AUTOINST*/
		       // Outputs
		       .gtx_tune	(gtx_tune0[31:0]),	 // Templated
		       .phyreset	(phyreset0),		 // Templated
		       .sata_ledA	(sata_ledA0),		 // Templated
		       .sata_ledB	(sata_ledB0),		 // Templated
		       .RdFIFO_Data	(RdFIFO_Data0[31:0]),	 // Templated
		       .RdFIFO_DataId	(RdFIFO_DataId0[4:0]),	 // Templated
		       .RdFIFO_DataReq	(RdFIFO_DataReq0),	 // Templated
		       .RdFIFO_DataSize	(RdFIFO_DataSize0[7:0]), // Templated
		       .RdFIFO_Empty	(RdFIFO_Empty0),	 // Templated
		       .RdFIFO_Full	(RdFIFO_Full0),		 // Templated
		       .StartComm	(StartComm0),		 // Templated
		       .WrFIFO_DataId	(WrFIFO_DataId0[4:0]),	 // Templated
		       .WrFIFO_DataReq	(WrFIFO_DataReq0),	 // Templated
		       .WrFIFO_DataSize	(WrFIFO_DataSize0[7:0]), // Templated
		       .WrFIFO_Empty	(WrFIFO_Empty0),	 // Templated
		       .WrFIFO_Full	(WrFIFO_Full0),		 // Templated
		       .cmd_raddr	(cmd_raddr0[4:0]),	 // Templated
		       .err_ack		(err_ack0[7:0]),	 // Templated
		       .irq		(irq0),			 // Templated
		       .readdata	(io_readdata0[31:0]),	 // Templated
		       .txdata		(txdata0[31:0]),	 // Templated
		       .txdatak		(txdatak0),		 // Templated
		       // Inputs
		       .sys_clk		(sys_clk),		 // Templated
		       .sys_rst		(sys_rst),		 // Templated
		       .CommInit	(CommInit0),		 // Templated
		       .RdFIFO_DataAck	(RdFIFO_DataAck0),	 // Templated
		       .RdFIFO_Pop	(RdFIFO_Pop0),		 // Templated
		       .Trace_FW	(Trace_FW0[127:0]),	 // Templated
		       .WrFIFO_Data	(WrFIFO_Data0[31:0]),	 // Templated
		       .WrFIFO_DataAck	(WrFIFO_DataAck0),	 // Templated
		       .WrFIFO_Push	(WrFIFO_Push0),		 // Templated
		       .address		(io_address0[5:0]),	 // Templated
		       .cmd_rdata	(cmd_rdata0[31:0]),	 // Templated
		       .err_req		(err_req0[7:0]),	 // Templated
		       .gtx_rxdata	(gtx_rxdata0[31:0]),	 // Templated
		       .gtx_rxdatak	(gtx_rxdatak0[3:0]),	 // Templated
		       .gtx_txdata	(gtx_txdata0[31:0]),	 // Templated
		       .gtx_txdatak	(gtx_txdatak0[3:0]),	 // Templated
		       .linkup		(linkup0),		 // Templated
		       .oob2dbg		(oob2dbg0[127:0]),	 // Templated
		       .phyclk		(phyclk0),		 // Templated
		       .plllock		(plllock0),		 // Templated
		       .rxdata		(rxdata0[31:0]),	 // Templated
		       .rxdatak		(rxdatak0),		 // Templated
		       .rxfifo_irq	(rxfifo_irq0),		 // Templated
		       .txdatak_pop	(txdatak_pop0),		 // Templated
		       .write		(io_write0),		 // Templated
		       .writedata	(io_writedata0[31:0]));	 // Templated
     end
   endgenerate

   generate if (C_PORT > 1)
     begin: aport1
	hs_if #(.C_PORT(2), .C_SATA_CHIPSCOPE(C_SATA_CHIPSCOPE), .C_FAMILY(C_FAMILY))
	         dma1 (/*AUTOINST*/
		       // Outputs
		       .gtx_tune	(gtx_tune1[31:0]),	 // Templated
		       .phyreset	(phyreset1),		 // Templated
		       .sata_ledA	(sata_ledA1),		 // Templated
		       .sata_ledB	(sata_ledB1),		 // Templated
		       .RdFIFO_Data	(RdFIFO_Data1[31:0]),	 // Templated
		       .RdFIFO_DataId	(RdFIFO_DataId1[4:0]),	 // Templated
		       .RdFIFO_DataReq	(RdFIFO_DataReq1),	 // Templated
		       .RdFIFO_DataSize	(RdFIFO_DataSize1[7:0]), // Templated
		       .RdFIFO_Empty	(RdFIFO_Empty1),	 // Templated
		       .RdFIFO_Full	(RdFIFO_Full1),		 // Templated
		       .StartComm	(StartComm1),		 // Templated
		       .WrFIFO_DataId	(WrFIFO_DataId1[4:0]),	 // Templated
		       .WrFIFO_DataReq	(WrFIFO_DataReq1),	 // Templated
		       .WrFIFO_DataSize	(WrFIFO_DataSize1[7:0]), // Templated
		       .WrFIFO_Empty	(WrFIFO_Empty1),	 // Templated
		       .WrFIFO_Full	(WrFIFO_Full1),		 // Templated
		       .cmd_raddr	(cmd_raddr1[4:0]),	 // Templated
		       .err_ack		(err_ack1[7:0]),	 // Templated
		       .irq		(irq1),			 // Templated
		       .readdata	(io_readdata1[31:0]),	 // Templated
		       .txdata		(txdata1[31:0]),	 // Templated
		       .txdatak		(txdatak1),		 // Templated
		       // Inputs
		       .sys_clk		(sys_clk),		 // Templated
		       .sys_rst		(sys_rst),		 // Templated
		       .CommInit	(CommInit1),		 // Templated
		       .RdFIFO_DataAck	(RdFIFO_DataAck1),	 // Templated
		       .RdFIFO_Pop	(RdFIFO_Pop1),		 // Templated
		       .Trace_FW	(Trace_FW1[127:0]),	 // Templated
		       .WrFIFO_Data	(WrFIFO_Data1[31:0]),	 // Templated
		       .WrFIFO_DataAck	(WrFIFO_DataAck1),	 // Templated
		       .WrFIFO_Push	(WrFIFO_Push1),		 // Templated
		       .address		(io_address1[5:0]),	 // Templated
		       .cmd_rdata	(cmd_rdata1[31:0]),	 // Templated
		       .err_req		(err_req1[7:0]),	 // Templated
		       .gtx_rxdata	(gtx_rxdata1[31:0]),	 // Templated
		       .gtx_rxdatak	(gtx_rxdatak1[3:0]),	 // Templated
		       .gtx_txdata	(gtx_txdata1[31:0]),	 // Templated
		       .gtx_txdatak	(gtx_txdatak1[3:0]),	 // Templated
		       .linkup		(linkup1),		 // Templated
		       .oob2dbg		(oob2dbg1[127:0]),	 // Templated
		       .phyclk		(phyclk1),		 // Templated
		       .plllock		(plllock1),		 // Templated
		       .rxdata		(rxdata1[31:0]),	 // Templated
		       .rxdatak		(rxdatak1),		 // Templated
		       .rxfifo_irq	(rxfifo_irq1),		 // Templated
		       .txdatak_pop	(txdatak_pop1),		 // Templated
		       .write		(io_write1),		 // Templated
		       .writedata	(io_writedata1[31:0]));	 // Templated
     end // block: aport1
   else
     begin
	assign irq1         = 1'b0;
	assign io_readdata1 = 32'h0;
	assign PIM1_AddrReq     = 1'b0;
	assign PIM1_WrFIFO_Push = 1'b0;
     end      
   endgenerate

   generate if (C_PORT > 2)
     begin: aport2
	hs_if #(.C_PORT(3), .C_SATA_CHIPSCOPE(C_SATA_CHIPSCOPE), .C_FAMILY(C_FAMILY))
	         dma2 (/*AUTOINST*/
		       // Outputs
		       .gtx_tune	(gtx_tune2[31:0]),	 // Templated
		       .phyreset	(phyreset2),		 // Templated
		       .sata_ledA	(sata_ledA2),		 // Templated
		       .sata_ledB	(sata_ledB2),		 // Templated
		       .RdFIFO_Data	(RdFIFO_Data2[31:0]),	 // Templated
		       .RdFIFO_DataId	(RdFIFO_DataId2[4:0]),	 // Templated
		       .RdFIFO_DataReq	(RdFIFO_DataReq2),	 // Templated
		       .RdFIFO_DataSize	(RdFIFO_DataSize2[7:0]), // Templated
		       .RdFIFO_Empty	(RdFIFO_Empty2),	 // Templated
		       .RdFIFO_Full	(RdFIFO_Full2),		 // Templated
		       .StartComm	(StartComm2),		 // Templated
		       .WrFIFO_DataId	(WrFIFO_DataId2[4:0]),	 // Templated
		       .WrFIFO_DataReq	(WrFIFO_DataReq2),	 // Templated
		       .WrFIFO_DataSize	(WrFIFO_DataSize2[7:0]), // Templated
		       .WrFIFO_Empty	(WrFIFO_Empty2),	 // Templated
		       .WrFIFO_Full	(WrFIFO_Full2),		 // Templated
		       .cmd_raddr	(cmd_raddr2[4:0]),	 // Templated
		       .err_ack		(err_ack2[7:0]),	 // Templated
		       .irq		(irq2),			 // Templated
		       .readdata	(io_readdata2[31:0]),	 // Templated
		       .txdata		(txdata2[31:0]),	 // Templated
		       .txdatak		(txdatak2),		 // Templated
		       // Inputs
		       .sys_clk		(sys_clk),		 // Templated
		       .sys_rst		(sys_rst),		 // Templated
		       .CommInit	(CommInit2),		 // Templated
		       .RdFIFO_DataAck	(RdFIFO_DataAck2),	 // Templated
		       .RdFIFO_Pop	(RdFIFO_Pop2),		 // Templated
		       .Trace_FW	(Trace_FW2[127:0]),	 // Templated
		       .WrFIFO_Data	(WrFIFO_Data2[31:0]),	 // Templated
		       .WrFIFO_DataAck	(WrFIFO_DataAck2),	 // Templated
		       .WrFIFO_Push	(WrFIFO_Push2),		 // Templated
		       .address		(io_address2[5:0]),	 // Templated
		       .cmd_rdata	(cmd_rdata2[31:0]),	 // Templated
		       .err_req		(err_req2[7:0]),	 // Templated
		       .gtx_rxdata	(gtx_rxdata2[31:0]),	 // Templated
		       .gtx_rxdatak	(gtx_rxdatak2[3:0]),	 // Templated
		       .gtx_txdata	(gtx_txdata2[31:0]),	 // Templated
		       .gtx_txdatak	(gtx_txdatak2[3:0]),	 // Templated
		       .linkup		(linkup2),		 // Templated
		       .oob2dbg		(oob2dbg2[127:0]),	 // Templated
		       .phyclk		(phyclk2),		 // Templated
		       .plllock		(plllock2),		 // Templated
		       .rxdata		(rxdata2[31:0]),	 // Templated
		       .rxdatak		(rxdatak2),		 // Templated
		       .rxfifo_irq	(rxfifo_irq2),		 // Templated
		       .txdatak_pop	(txdatak_pop2),		 // Templated
		       .write		(io_write2),		 // Templated
		       .writedata	(io_writedata2[31:0]));	 // Templated
     end // block: aport2
   else
     begin
	assign irq2         = 1'b0;
	assign io_readdata2 = 32'h0;
	assign PIM2_AddrReq     = 1'b0;
	assign PIM2_WrFIFO_Push = 1'b0;	
     end
   endgenerate

   generate if (C_PORT > 3)
     begin: aport3
	hs_if #(.C_PORT(4), .C_SATA_CHIPSCOPE(C_SATA_CHIPSCOPE), .C_FAMILY(C_FAMILY))
	         dma3 (/*AUTOINST*/
		       // Outputs
		       .gtx_tune	(gtx_tune3[31:0]),	 // Templated
		       .phyreset	(phyreset3),		 // Templated
		       .sata_ledA	(sata_ledA3),		 // Templated
		       .sata_ledB	(sata_ledB3),		 // Templated
		       .RdFIFO_Data	(RdFIFO_Data3[31:0]),	 // Templated
		       .RdFIFO_DataId	(RdFIFO_DataId3[4:0]),	 // Templated
		       .RdFIFO_DataReq	(RdFIFO_DataReq3),	 // Templated
		       .RdFIFO_DataSize	(RdFIFO_DataSize3[7:0]), // Templated
		       .RdFIFO_Empty	(RdFIFO_Empty3),	 // Templated
		       .RdFIFO_Full	(RdFIFO_Full3),		 // Templated
		       .StartComm	(StartComm3),		 // Templated
		       .WrFIFO_DataId	(WrFIFO_DataId3[4:0]),	 // Templated
		       .WrFIFO_DataReq	(WrFIFO_DataReq3),	 // Templated
		       .WrFIFO_DataSize	(WrFIFO_DataSize3[7:0]), // Templated
		       .WrFIFO_Empty	(WrFIFO_Empty3),	 // Templated
		       .WrFIFO_Full	(WrFIFO_Full3),		 // Templated
		       .cmd_raddr	(cmd_raddr3[4:0]),	 // Templated
		       .err_ack		(err_ack3[7:0]),	 // Templated
		       .irq		(irq3),			 // Templated
		       .readdata	(io_readdata3[31:0]),	 // Templated
		       .txdata		(txdata3[31:0]),	 // Templated
		       .txdatak		(txdatak3),		 // Templated
		       // Inputs
		       .sys_clk		(sys_clk),		 // Templated
		       .sys_rst		(sys_rst),		 // Templated
		       .CommInit	(CommInit3),		 // Templated
		       .RdFIFO_DataAck	(RdFIFO_DataAck3),	 // Templated
		       .RdFIFO_Pop	(RdFIFO_Pop3),		 // Templated
		       .Trace_FW	(Trace_FW3[127:0]),	 // Templated
		       .WrFIFO_Data	(WrFIFO_Data3[31:0]),	 // Templated
		       .WrFIFO_DataAck	(WrFIFO_DataAck3),	 // Templated
		       .WrFIFO_Push	(WrFIFO_Push3),		 // Templated
		       .address		(io_address3[5:0]),	 // Templated
		       .cmd_rdata	(cmd_rdata3[31:0]),	 // Templated
		       .err_req		(err_req3[7:0]),	 // Templated
		       .gtx_rxdata	(gtx_rxdata3[31:0]),	 // Templated
		       .gtx_rxdatak	(gtx_rxdatak3[3:0]),	 // Templated
		       .gtx_txdata	(gtx_txdata3[31:0]),	 // Templated
		       .gtx_txdatak	(gtx_txdatak3[3:0]),	 // Templated
		       .linkup		(linkup3),		 // Templated
		       .oob2dbg		(oob2dbg3[127:0]),	 // Templated
		       .phyclk		(phyclk3),		 // Templated
		       .plllock		(plllock3),		 // Templated
		       .rxdata		(rxdata3[31:0]),	 // Templated
		       .rxdatak		(rxdatak3),		 // Templated
		       .rxfifo_irq	(rxfifo_irq3),		 // Templated
		       .txdatak_pop	(txdatak_pop3),		 // Templated
		       .write		(io_write3),		 // Templated
		       .writedata	(io_writedata3[31:0]));	 // Templated
     end // block: aport3
   else
     begin
	assign irq3         = 1'b0;
	assign io_readdata3 = 32'h0;
	assign PIM3_AddrReq     = 1'b0;
	assign PIM3_WrFIFO_Push = 1'b0;		
     end
   endgenerate

   host_if
     host_if (/*AUTOINST*/
	      // Outputs
	      .sys_rst			(sys_rst),
	      .Sl_dcrDBus		(Sl_dcrDBus[0:31]),
	      .Sl_dcrAck		(Sl_dcrAck),
	      .interrupt		(interrupt),
	      .inband_base		(inband_base[31:0]),
	      .inband_cons_addr		(inband_cons_addr[31:0]),
	      .inband_prod_index	(inband_prod_index[11:0]),
	      .outband_base		(outband_base[31:0]),
	      .outband_prod_addr	(outband_prod_addr[31:0]),
	      .outband_cons_index	(outband_cons_index[11:0]),
	      .ring_enable		(ring_enable),
	      .DBG_STOP			(DBG_STOP),
	      .err_req0			(err_req0[7:0]),
	      .err_req1			(err_req1[7:0]),
	      .err_req2			(err_req2[7:0]),
	      .err_req3			(err_req3[7:0]),
	      // Inputs
	      .sys_clk			(sys_clk),
	      .DCR_Clk			(DCR_Clk),
	      .DCR_Rst			(DCR_Rst),
	      .DCR_Read			(DCR_Read),
	      .DCR_Write		(DCR_Write),
	      .DCR_ABus			(DCR_ABus[0:9]),
	      .DCR_Sl_DBus		(DCR_Sl_DBus[0:31]),
	      .inband_cons_index	(inband_cons_index[11:0]),
	      .outband_prod_index	(outband_prod_index[11:0]),
	      .err_ack0			(err_ack0[7:0]),
	      .err_ack1			(err_ack1[7:0]),
	      .err_ack2			(err_ack2[7:0]),
	      .err_ack3			(err_ack3[7:0]),
	      .phyclk0			(phyclk0),
	      .phyclk1			(phyclk1),
	      .phyclk2			(phyclk2),
	      .phyclk3			(phyclk3),
	      .dma_state0		(dma_state0[31:0]),
	      .dma_state1		(dma_state1[31:0]),
	      .dma_state2		(dma_state2[31:0]),
	      .dma_state3		(dma_state3[31:0]),
	      .npi_ict_state		(npi_ict_state[31:0]));

   mb_top #(/*AUTOINSTPARAM*/
	    // Parameters
	    .C_FAMILY			(C_FAMILY),
	    .C_DEBUG_ENABLED		(C_DEBUG_ENABLED))
   mb_top  (/*AUTOINST*/
	    // Outputs
	    .DBG_TDO			(DBG_TDO),
	    .DCACHE_FSL_IN_CLK		(DCACHE_FSL_IN_CLK),
	    .DCACHE_FSL_IN_READ		(DCACHE_FSL_IN_READ),
	    .DCACHE_FSL_OUT_CLK		(DCACHE_FSL_OUT_CLK),
	    .DCACHE_FSL_OUT_CONTROL	(DCACHE_FSL_OUT_CONTROL),
	    .DCACHE_FSL_OUT_DATA	(DCACHE_FSL_OUT_DATA[0:31]),
	    .DCACHE_FSL_OUT_WRITE	(DCACHE_FSL_OUT_WRITE),
	    .ICACHE_FSL_IN_CLK		(ICACHE_FSL_IN_CLK),
	    .ICACHE_FSL_IN_READ		(ICACHE_FSL_IN_READ),
	    .ICACHE_FSL_OUT_CLK		(ICACHE_FSL_OUT_CLK),
	    .ICACHE_FSL_OUT_CONTROL	(ICACHE_FSL_OUT_CONTROL),
	    .ICACHE_FSL_OUT_DATA	(ICACHE_FSL_OUT_DATA[0:31]),
	    .ICACHE_FSL_OUT_WRITE	(ICACHE_FSL_OUT_WRITE),
	    .Trace_FW0			(Trace_FW0[127:0]),
	    .Trace_FW1			(Trace_FW1[127:0]),
	    .Trace_FW2			(Trace_FW2[127:0]),
	    .Trace_FW3			(Trace_FW3[127:0]),
	    .dlmb_BRAM_Din		(dlmb_BRAM_Din[0:31]),
	    .ilmb_BRAM_Din		(ilmb_BRAM_Din[0:31]),
	    .inband_cons_index		(inband_cons_index[11:0]),
	    .io_address0		(io_address0[5:0]),
	    .io_address1		(io_address1[5:0]),
	    .io_address2		(io_address2[5:0]),
	    .io_address3		(io_address3[5:0]),
	    .io_write0			(io_write0),
	    .io_write1			(io_write1),
	    .io_write2			(io_write2),
	    .io_write3			(io_write3),
	    .io_writedata0		(io_writedata0[31:0]),
	    .io_writedata1		(io_writedata1[31:0]),
	    .io_writedata2		(io_writedata2[31:0]),
	    .io_writedata3		(io_writedata3[31:0]),
	    .outband_prod_index		(outband_prod_index[11:0]),
	    // Inputs
	    .sys_clk			(sys_clk),
	    .sys_rst			(sys_rst),
	    .DBG_CAPTURE		(DBG_CAPTURE),
	    .DBG_CLK			(DBG_CLK),
	    .DBG_REG_EN			(DBG_REG_EN[0:7]),
	    .DBG_RST			(DBG_RST),
	    .DBG_SHIFT			(DBG_SHIFT),
	    .DBG_STOP			(DBG_STOP),
	    .DBG_TDI			(DBG_TDI),
	    .DBG_UPDATE			(DBG_UPDATE),
	    .DCACHE_FSL_IN_CONTROL	(DCACHE_FSL_IN_CONTROL),
	    .DCACHE_FSL_IN_DATA		(DCACHE_FSL_IN_DATA[0:31]),
	    .DCACHE_FSL_IN_EXISTS	(DCACHE_FSL_IN_EXISTS),
	    .DCACHE_FSL_OUT_FULL	(DCACHE_FSL_OUT_FULL),
	    .ICACHE_FSL_IN_CONTROL	(ICACHE_FSL_IN_CONTROL),
	    .ICACHE_FSL_IN_DATA		(ICACHE_FSL_IN_DATA[0:31]),
	    .ICACHE_FSL_IN_EXISTS	(ICACHE_FSL_IN_EXISTS),
	    .ICACHE_FSL_OUT_FULL	(ICACHE_FSL_OUT_FULL),
	    .dlmb_BRAM_Addr		(dlmb_BRAM_Addr[0:31]),
	    .dlmb_BRAM_Clk		(dlmb_BRAM_Clk),
	    .dlmb_BRAM_Dout		(dlmb_BRAM_Dout[0:31]),
	    .dlmb_BRAM_EN		(dlmb_BRAM_EN),
	    .dlmb_BRAM_Rst		(dlmb_BRAM_Rst),
	    .dlmb_BRAM_WEN		(dlmb_BRAM_WEN[0:3]),
	    .ilmb_BRAM_Addr		(ilmb_BRAM_Addr[0:31]),
	    .ilmb_BRAM_Clk		(ilmb_BRAM_Clk),
	    .ilmb_BRAM_Dout		(ilmb_BRAM_Dout[0:31]),
	    .ilmb_BRAM_EN		(ilmb_BRAM_EN),
	    .ilmb_BRAM_Rst		(ilmb_BRAM_Rst),
	    .ilmb_BRAM_WEN		(ilmb_BRAM_WEN[0:3]),
	    .inband_base		(inband_base[31:0]),
	    .inband_cons_addr		(inband_cons_addr[31:0]),
	    .inband_prod_index		(inband_prod_index[11:0]),
	    .io_readdata0		(io_readdata0[31:0]),
	    .io_readdata1		(io_readdata1[31:0]),
	    .io_readdata2		(io_readdata2[31:0]),
	    .io_readdata3		(io_readdata3[31:0]),
	    .irq0			(irq0),
	    .irq1			(irq1),
	    .irq2			(irq2),
	    .irq3			(irq3),
	    .outband_base		(outband_base[31:0]),
	    .outband_cons_index		(outband_cons_index[11:0]),
	    .outband_prod_addr		(outband_prod_addr[31:0]),
	    .ring_enable		(ring_enable));

endmodule // sata
// Local Variables:
// verilog-library-directories:("." "../../pcores/sata_v1_00_a/hdl/verilog")
// verilog-library-files:(".""sata_phy")
// verilog-library-extensions:(".v" ".h")
// End:
// 
// hs_top.v ends here
