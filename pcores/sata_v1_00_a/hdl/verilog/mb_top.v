// mb_top.v --- 
// 
// Filename: mb_top.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Feb 24 15:22:40 2012 (+0800)
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
module mb_top(/*AUTOARG*/
   // Outputs
   outband_prod_index, io_writedata3, io_writedata2, io_writedata1,
   io_writedata0, io_write3, io_write2, io_write1, io_write0,
   io_address3, io_address2, io_address1, io_address0,
   inband_cons_index, ilmb_BRAM_Din, dlmb_BRAM_Din, Trace_FW3,
   Trace_FW2, Trace_FW1, Trace_FW0, ICACHE_FSL_OUT_WRITE,
   ICACHE_FSL_OUT_DATA, ICACHE_FSL_OUT_CONTROL, ICACHE_FSL_OUT_CLK,
   ICACHE_FSL_IN_READ, ICACHE_FSL_IN_CLK, DCACHE_FSL_OUT_WRITE,
   DCACHE_FSL_OUT_DATA, DCACHE_FSL_OUT_CONTROL, DCACHE_FSL_OUT_CLK,
   DCACHE_FSL_IN_READ, DCACHE_FSL_IN_CLK, DBG_TDO,
   // Inputs
   ring_enable, outband_prod_addr, outband_cons_index, outband_base,
   irq3, irq2, irq1, irq0, io_readdata3, io_readdata2, io_readdata1,
   io_readdata0, inband_prod_index, inband_cons_addr, inband_base,
   ilmb_BRAM_WEN, ilmb_BRAM_Rst, ilmb_BRAM_EN, ilmb_BRAM_Dout,
   ilmb_BRAM_Clk, ilmb_BRAM_Addr, dlmb_BRAM_WEN, dlmb_BRAM_Rst,
   dlmb_BRAM_EN, dlmb_BRAM_Dout, dlmb_BRAM_Clk, dlmb_BRAM_Addr,
   ICACHE_FSL_OUT_FULL, ICACHE_FSL_IN_EXISTS, ICACHE_FSL_IN_DATA,
   ICACHE_FSL_IN_CONTROL, DCACHE_FSL_OUT_FULL, DCACHE_FSL_IN_EXISTS,
   DCACHE_FSL_IN_DATA, DCACHE_FSL_IN_CONTROL, DBG_UPDATE, DBG_TDI,
   DBG_STOP, DBG_SHIFT, DBG_RST, DBG_REG_EN, DBG_CLK, DBG_CAPTURE,
   sys_clk, sys_rst
   );
   parameter C_FAMILY = "virtex5";
   parameter C_DEBUG_ENABLED = 1;
   localparam C_XDEVICE = "xc5vlx50t";
   localparam C_XPACKAGE = "ff1136";
   localparam C_XSPEEDGRADE = "-1";
   localparam C_MICROBLAZE_INSTANCE = "microblaze_0";
   localparam C_PATH = "mb/U0";
   localparam C_FREQ = 100000000;
   
   localparam C_MEMSIZE_I = 16'h4000;
   localparam C_MEMSIZE_D = 16'h4000;   
   
   localparam C_TRACE = 1;
   
   localparam C_USE_IO_BUS = 1;
   
   localparam C_USE_UART_RX = 1;
   localparam C_USE_UART_TX = 1;
   localparam C_UART_BAUDRATE = 115200;
   localparam C_UART_DATA_BITS = 8;
   localparam C_UART_USE_PARITY = 0;
   localparam C_UART_ODD_PARITY = 0;
   localparam C_UART_RX_INTERRUPT = 0;
   localparam C_UART_TX_INTERRUPT = 0;
   localparam C_UART_ERROR_INTERRUPT = 0;
   
   localparam C_USE_FIT1 = 0;
   localparam C_FIT1_No_CLOCKS = 6216;
   localparam C_FIT1_INTERRUPT = 0;
   localparam C_USE_FIT2 = 0;
   localparam C_FIT2_No_CLOCKS = 6216;
   localparam C_FIT2_INTERRUPT = 0;
   localparam C_USE_FIT3 = 0;
   localparam C_FIT3_No_CLOCKS = 6216;
   localparam C_FIT3_INTERRUPT = 0;
   localparam C_USE_FIT4 = 0;
   localparam C_FIT4_No_CLOCKS = 6216;
   localparam C_FIT4_INTERRUPT = 0;
   localparam C_USE_PIT1 = 0;
   localparam C_PIT1_SIZE = 32;
   localparam C_PIT1_READABLE = 1;
   localparam C_PIT1_PRESCALER = 0;
   localparam C_PIT1_INTERRUPT = 0;
   localparam C_USE_PIT2 = 0;
   localparam C_PIT2_SIZE = 32;
   localparam C_PIT2_READABLE = 1; 
   localparam C_PIT2_PRESCALER = 0;
   localparam C_PIT2_INTERRUPT = 0;
   localparam C_USE_PIT3 = 0;
   localparam C_PIT3_SIZE = 32;
   localparam C_PIT3_READABLE = 1;
   localparam C_PIT3_PRESCALER = 0;
   localparam C_PIT3_INTERRUPT = 0;
   localparam C_USE_PIT4 = 0;
   localparam C_PIT4_SIZE = 32;
   localparam C_PIT4_READABLE = 1;
   localparam C_PIT4_PRESCALER = 0;
   localparam C_PIT4_INTERRUPT = 0;
   
   localparam C_USE_GPO1 = 0;
   localparam C_GPO1_SIZE = 32;
   localparam[31:0] C_GPO1_INIT = 0;
   localparam C_USE_GPO2 = 0;
   localparam C_GPO2_SIZE = 32;
   localparam[31:0] C_GPO2_INIT = 0;
   localparam C_USE_GPO3 = 0;
   localparam C_GPO3_SIZE = 32;
   localparam[31:0] C_GPO3_INIT = 0;
   localparam C_USE_GPO4 = 0;
   localparam C_GPO4_SIZE = 32;
   localparam[31:0] C_GPO4_INIT = 0;
   localparam C_USE_GPI1 = 0;
   localparam C_GPI1_SIZE = 32;
   localparam C_USE_GPI2 = 0;
   localparam C_GPI2_SIZE = 32;
   localparam C_USE_GPI3 = 0;
   localparam C_GPI3_SIZE = 32;
   localparam C_USE_GPI4 = 0;
   localparam C_GPI4_SIZE = 32;
   
   localparam C_INTC_USE_EXT_INTR = 0;
   localparam C_INTC_INTR_SIZE = 16;
   localparam[15:0] C_INTC_LEVEL_EDGE = 16'h0000;
   localparam[15:0] C_INTC_POSITIVE = 16'hffff;
   
   input sys_clk;
   input sys_rst;
   
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		DBG_CAPTURE;		// To microblaze_mcs of microblaze_mcs.v
   input		DBG_CLK;		// To microblaze_mcs of microblaze_mcs.v
   input [0:7]		DBG_REG_EN;		// To microblaze_mcs of microblaze_mcs.v
   input		DBG_RST;		// To microblaze_mcs of microblaze_mcs.v
   input		DBG_SHIFT;		// To microblaze_mcs of microblaze_mcs.v
   input		DBG_STOP;		// To microblaze_mcs of microblaze_mcs.v
   input		DBG_TDI;		// To microblaze_mcs of microblaze_mcs.v
   input		DBG_UPDATE;		// To microblaze_mcs of microblaze_mcs.v
   input		DCACHE_FSL_IN_CONTROL;	// To microblaze_mcs of microblaze_mcs.v
   input [0:31]		DCACHE_FSL_IN_DATA;	// To microblaze_mcs of microblaze_mcs.v
   input		DCACHE_FSL_IN_EXISTS;	// To microblaze_mcs of microblaze_mcs.v
   input		DCACHE_FSL_OUT_FULL;	// To microblaze_mcs of microblaze_mcs.v
   input		ICACHE_FSL_IN_CONTROL;	// To microblaze_mcs of microblaze_mcs.v
   input [0:31]		ICACHE_FSL_IN_DATA;	// To microblaze_mcs of microblaze_mcs.v
   input		ICACHE_FSL_IN_EXISTS;	// To microblaze_mcs of microblaze_mcs.v
   input		ICACHE_FSL_OUT_FULL;	// To microblaze_mcs of microblaze_mcs.v
   input [0:31]		dlmb_BRAM_Addr;		// To microblaze_mcs of microblaze_mcs.v
   input		dlmb_BRAM_Clk;		// To microblaze_mcs of microblaze_mcs.v
   input [0:31]		dlmb_BRAM_Dout;		// To microblaze_mcs of microblaze_mcs.v
   input		dlmb_BRAM_EN;		// To microblaze_mcs of microblaze_mcs.v
   input		dlmb_BRAM_Rst;		// To microblaze_mcs of microblaze_mcs.v
   input [0:3]		dlmb_BRAM_WEN;		// To microblaze_mcs of microblaze_mcs.v
   input [0:31]		ilmb_BRAM_Addr;		// To microblaze_mcs of microblaze_mcs.v
   input		ilmb_BRAM_Clk;		// To microblaze_mcs of microblaze_mcs.v
   input [0:31]		ilmb_BRAM_Dout;		// To microblaze_mcs of microblaze_mcs.v
   input		ilmb_BRAM_EN;		// To microblaze_mcs of microblaze_mcs.v
   input		ilmb_BRAM_Rst;		// To microblaze_mcs of microblaze_mcs.v
   input [0:3]		ilmb_BRAM_WEN;		// To microblaze_mcs of microblaze_mcs.v
   input [31:0]		inband_base;		// To mb_io of mb_io.v
   input [31:0]		inband_cons_addr;	// To mb_io of mb_io.v
   input [11:0]		inband_prod_index;	// To mb_io of mb_io.v
   input [31:0]		io_readdata0;		// To mb_io of mb_io.v
   input [31:0]		io_readdata1;		// To mb_io of mb_io.v
   input [31:0]		io_readdata2;		// To mb_io of mb_io.v
   input [31:0]		io_readdata3;		// To mb_io of mb_io.v
   input		irq0;			// To mb_io of mb_io.v
   input		irq1;			// To mb_io of mb_io.v
   input		irq2;			// To mb_io of mb_io.v
   input		irq3;			// To mb_io of mb_io.v
   input [31:0]		outband_base;		// To mb_io of mb_io.v
   input [11:0]		outband_cons_index;	// To mb_io of mb_io.v
   input [31:0]		outband_prod_addr;	// To mb_io of mb_io.v
   input		ring_enable;		// To mb_io of mb_io.v
   // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output		DBG_TDO;		// From microblaze_mcs of microblaze_mcs.v
   output		DCACHE_FSL_IN_CLK;	// From microblaze_mcs of microblaze_mcs.v
   output		DCACHE_FSL_IN_READ;	// From microblaze_mcs of microblaze_mcs.v
   output		DCACHE_FSL_OUT_CLK;	// From microblaze_mcs of microblaze_mcs.v
   output		DCACHE_FSL_OUT_CONTROL;	// From microblaze_mcs of microblaze_mcs.v
   output [0:31]	DCACHE_FSL_OUT_DATA;	// From microblaze_mcs of microblaze_mcs.v
   output		DCACHE_FSL_OUT_WRITE;	// From microblaze_mcs of microblaze_mcs.v
   output		ICACHE_FSL_IN_CLK;	// From microblaze_mcs of microblaze_mcs.v
   output		ICACHE_FSL_IN_READ;	// From microblaze_mcs of microblaze_mcs.v
   output		ICACHE_FSL_OUT_CLK;	// From microblaze_mcs of microblaze_mcs.v
   output		ICACHE_FSL_OUT_CONTROL;	// From microblaze_mcs of microblaze_mcs.v
   output [0:31]	ICACHE_FSL_OUT_DATA;	// From microblaze_mcs of microblaze_mcs.v
   output		ICACHE_FSL_OUT_WRITE;	// From microblaze_mcs of microblaze_mcs.v
   output [127:0]	Trace_FW0;		// From mb_io of mb_io.v
   output [127:0]	Trace_FW1;		// From mb_io of mb_io.v
   output [127:0]	Trace_FW2;		// From mb_io of mb_io.v
   output [127:0]	Trace_FW3;		// From mb_io of mb_io.v
   output [0:31]	dlmb_BRAM_Din;		// From microblaze_mcs of microblaze_mcs.v
   output [0:31]	ilmb_BRAM_Din;		// From microblaze_mcs of microblaze_mcs.v
   output [11:0]	inband_cons_index;	// From mb_io of mb_io.v
   output [5:0]		io_address0;		// From mb_io of mb_io.v
   output [5:0]		io_address1;		// From mb_io of mb_io.v
   output [5:0]		io_address2;		// From mb_io of mb_io.v
   output [5:0]		io_address3;		// From mb_io of mb_io.v
   output		io_write0;		// From mb_io of mb_io.v
   output		io_write1;		// From mb_io of mb_io.v
   output		io_write2;		// From mb_io of mb_io.v
   output		io_write3;		// From mb_io of mb_io.v
   output [31:0]	io_writedata0;		// From mb_io of mb_io.v
   output [31:0]	io_writedata1;		// From mb_io of mb_io.v
   output [31:0]	io_writedata2;		// From mb_io of mb_io.v
   output [31:0]	io_writedata3;		// From mb_io of mb_io.v
   output [11:0]	outband_prod_index;	// From mb_io of mb_io.v
   // End of automatics

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			Clk;			// From mb_io of mb_io.v
   wire			FIT1_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			FIT1_Toggle;		// From microblaze_mcs of microblaze_mcs.v
   wire			FIT2_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			FIT2_Toggle;		// From microblaze_mcs of microblaze_mcs.v
   wire			FIT3_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			FIT3_Toggle;		// From microblaze_mcs of microblaze_mcs.v
   wire			FIT4_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			FIT4_Toggle;		// From microblaze_mcs of microblaze_mcs.v
   wire [C_GPI1_SIZE-1:0] GPI1;			// From mb_io of mb_io.v
   wire [C_GPI2_SIZE-1:0] GPI2;			// From mb_io of mb_io.v
   wire [C_GPI3_SIZE-1:0] GPI3;			// From mb_io of mb_io.v
   wire [C_GPI4_SIZE-1:0] GPI4;			// From mb_io of mb_io.v
   wire [C_GPO1_SIZE-1:0] GPO1;			// From microblaze_mcs of microblaze_mcs.v
   wire [C_GPO2_SIZE-1:0] GPO2;			// From microblaze_mcs of microblaze_mcs.v
   wire [C_GPO3_SIZE-1:0] GPO3;			// From microblaze_mcs of microblaze_mcs.v
   wire [C_GPO4_SIZE-1:0] GPO4;			// From microblaze_mcs of microblaze_mcs.v
   wire			INTC_IRQ;		// From microblaze_mcs of microblaze_mcs.v
   wire [C_INTC_INTR_SIZE-1:0] INTC_Interrupt;	// From mb_io of mb_io.v
   wire			IO_Addr_Strobe;		// From microblaze_mcs of microblaze_mcs.v
   wire [31:0]		IO_Address;		// From microblaze_mcs of microblaze_mcs.v
   wire [3:0]		IO_Byte_Enable;		// From microblaze_mcs of microblaze_mcs.v
   wire [31:0]		IO_Read_Data;		// From mb_io of mb_io.v
   wire			IO_Read_Strobe;		// From microblaze_mcs of microblaze_mcs.v
   wire			IO_Ready;		// From mb_io of mb_io.v
   wire [31:0]		IO_Write_Data;		// From microblaze_mcs of microblaze_mcs.v
   wire			IO_Write_Strobe;	// From microblaze_mcs of microblaze_mcs.v
   wire			PIT1_Enable;		// From mb_io of mb_io.v
   wire			PIT1_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			PIT1_Toggle;		// From microblaze_mcs of microblaze_mcs.v
   wire			PIT2_Enable;		// From mb_io of mb_io.v
   wire			PIT2_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			PIT2_Toggle;		// From microblaze_mcs of microblaze_mcs.v
   wire			PIT3_Enable;		// From mb_io of mb_io.v
   wire			PIT3_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			PIT3_Toggle;		// From microblaze_mcs of microblaze_mcs.v
   wire			PIT4_Enable;		// From mb_io of mb_io.v
   wire			PIT4_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			PIT4_Toggle;		// From microblaze_mcs of microblaze_mcs.v
   wire			Reset;			// From mb_io of mb_io.v
   wire			Trace_DCache_Hit;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_DCache_Rdy;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_DCache_Read;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_DCache_Req;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Data_Access;	// From microblaze_mcs of microblaze_mcs.v
   wire [0:31]		Trace_Data_Address;	// From microblaze_mcs of microblaze_mcs.v
   wire [0:3]		Trace_Data_Byte_Enable;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Data_Read;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Data_Write;	// From microblaze_mcs of microblaze_mcs.v
   wire [0:31]		Trace_Data_Write_Value;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Delay_Slot;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_EX_PipeRun;	// From microblaze_mcs of microblaze_mcs.v
   wire [0:4]		Trace_Exception_Kind;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Exception_Taken;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_ICache_Hit;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_ICache_Rdy;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_ICache_Req;	// From microblaze_mcs of microblaze_mcs.v
   wire [0:31]		Trace_Instruction;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Jump_Hit;		// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Jump_Taken;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_MB_Halted;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_MEM_PipeRun;	// From microblaze_mcs of microblaze_mcs.v
   wire [0:14]		Trace_MSR_Reg;		// From microblaze_mcs of microblaze_mcs.v
   wire [0:31]		Trace_New_Reg_Value;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_OF_PipeRun;	// From microblaze_mcs of microblaze_mcs.v
   wire [0:31]		Trace_PC;		// From microblaze_mcs of microblaze_mcs.v
   wire [0:7]		Trace_PID_Reg;		// From microblaze_mcs of microblaze_mcs.v
   wire [0:4]		Trace_Reg_Addr;		// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Reg_Write;	// From microblaze_mcs of microblaze_mcs.v
   wire			Trace_Valid_Instr;	// From microblaze_mcs of microblaze_mcs.v
   wire			UART_Interrupt;		// From microblaze_mcs of microblaze_mcs.v
   wire			UART_Rx;		// From mb_io of mb_io.v
   wire			UART_Tx;		// From microblaze_mcs of microblaze_mcs.v
   // End of automatics
   
   microblaze_mcs #(/*AUTOINSTPARAM*/
		    // Parameters
		    .C_FAMILY		(C_FAMILY),
		    .C_XDEVICE		(C_XDEVICE),
		    .C_XPACKAGE		(C_XPACKAGE),
		    .C_XSPEEDGRADE	(C_XSPEEDGRADE),
		    .C_MICROBLAZE_INSTANCE(C_MICROBLAZE_INSTANCE),
		    .C_PATH		(C_PATH),
		    .C_FREQ		(C_FREQ),
		    .C_MEMSIZE_I	(C_MEMSIZE_I),
		    .C_MEMSIZE_D	(C_MEMSIZE_D),
		    .C_DEBUG_ENABLED	(C_DEBUG_ENABLED),
		    .C_TRACE		(C_TRACE),
		    .C_USE_IO_BUS	(C_USE_IO_BUS),
		    .C_USE_UART_RX	(C_USE_UART_RX),
		    .C_USE_UART_TX	(C_USE_UART_TX),
		    .C_UART_BAUDRATE	(C_UART_BAUDRATE),
		    .C_UART_DATA_BITS	(C_UART_DATA_BITS),
		    .C_UART_USE_PARITY	(C_UART_USE_PARITY),
		    .C_UART_ODD_PARITY	(C_UART_ODD_PARITY),
		    .C_UART_RX_INTERRUPT(C_UART_RX_INTERRUPT),
		    .C_UART_TX_INTERRUPT(C_UART_TX_INTERRUPT),
		    .C_UART_ERROR_INTERRUPT(C_UART_ERROR_INTERRUPT),
		    .C_USE_FIT1		(C_USE_FIT1),
		    .C_FIT1_No_CLOCKS	(C_FIT1_No_CLOCKS),
		    .C_FIT1_INTERRUPT	(C_FIT1_INTERRUPT),
		    .C_USE_FIT2		(C_USE_FIT2),
		    .C_FIT2_No_CLOCKS	(C_FIT2_No_CLOCKS),
		    .C_FIT2_INTERRUPT	(C_FIT2_INTERRUPT),
		    .C_USE_FIT3		(C_USE_FIT3),
		    .C_FIT3_No_CLOCKS	(C_FIT3_No_CLOCKS),
		    .C_FIT3_INTERRUPT	(C_FIT3_INTERRUPT),
		    .C_USE_FIT4		(C_USE_FIT4),
		    .C_FIT4_No_CLOCKS	(C_FIT4_No_CLOCKS),
		    .C_FIT4_INTERRUPT	(C_FIT4_INTERRUPT),
		    .C_USE_PIT1		(C_USE_PIT1),
		    .C_PIT1_SIZE	(C_PIT1_SIZE),
		    .C_PIT1_READABLE	(C_PIT1_READABLE),
		    .C_PIT1_PRESCALER	(C_PIT1_PRESCALER),
		    .C_PIT1_INTERRUPT	(C_PIT1_INTERRUPT),
		    .C_USE_PIT2		(C_USE_PIT2),
		    .C_PIT2_SIZE	(C_PIT2_SIZE),
		    .C_PIT2_READABLE	(C_PIT2_READABLE),
		    .C_PIT2_PRESCALER	(C_PIT2_PRESCALER),
		    .C_PIT2_INTERRUPT	(C_PIT2_INTERRUPT),
		    .C_USE_PIT3		(C_USE_PIT3),
		    .C_PIT3_SIZE	(C_PIT3_SIZE),
		    .C_PIT3_READABLE	(C_PIT3_READABLE),
		    .C_PIT3_PRESCALER	(C_PIT3_PRESCALER),
		    .C_PIT3_INTERRUPT	(C_PIT3_INTERRUPT),
		    .C_USE_PIT4		(C_USE_PIT4),
		    .C_PIT4_SIZE	(C_PIT4_SIZE),
		    .C_PIT4_READABLE	(C_PIT4_READABLE),
		    .C_PIT4_PRESCALER	(C_PIT4_PRESCALER),
		    .C_PIT4_INTERRUPT	(C_PIT4_INTERRUPT),
		    .C_USE_GPO1		(C_USE_GPO1),
		    .C_GPO1_SIZE	(C_GPO1_SIZE),
		    .C_GPO1_INIT	(C_GPO1_INIT[31:0]),
		    .C_USE_GPO2		(C_USE_GPO2),
		    .C_GPO2_SIZE	(C_GPO2_SIZE),
		    .C_GPO2_INIT	(C_GPO2_INIT[31:0]),
		    .C_USE_GPO3		(C_USE_GPO3),
		    .C_GPO3_SIZE	(C_GPO3_SIZE),
		    .C_GPO3_INIT	(C_GPO3_INIT[31:0]),
		    .C_USE_GPO4		(C_USE_GPO4),
		    .C_GPO4_SIZE	(C_GPO4_SIZE),
		    .C_GPO4_INIT	(C_GPO4_INIT[31:0]),
		    .C_USE_GPI1		(C_USE_GPI1),
		    .C_GPI1_SIZE	(C_GPI1_SIZE),
		    .C_USE_GPI2		(C_USE_GPI2),
		    .C_GPI2_SIZE	(C_GPI2_SIZE),
		    .C_USE_GPI3		(C_USE_GPI3),
		    .C_GPI3_SIZE	(C_GPI3_SIZE),
		    .C_USE_GPI4		(C_USE_GPI4),
		    .C_GPI4_SIZE	(C_GPI4_SIZE),
		    .C_INTC_USE_EXT_INTR(C_INTC_USE_EXT_INTR),
		    .C_INTC_INTR_SIZE	(C_INTC_INTR_SIZE),
		    .C_INTC_LEVEL_EDGE	(C_INTC_LEVEL_EDGE[15:0]),
		    .C_INTC_POSITIVE	(C_INTC_POSITIVE[15:0]))
   microblaze_mcs (/*AUTOINST*/
		   // Outputs
		   .IO_Addr_Strobe	(IO_Addr_Strobe),
		   .IO_Read_Strobe	(IO_Read_Strobe),
		   .IO_Write_Strobe	(IO_Write_Strobe),
		   .IO_Address		(IO_Address[31:0]),
		   .IO_Byte_Enable	(IO_Byte_Enable[3:0]),
		   .IO_Write_Data	(IO_Write_Data[31:0]),
		   .UART_Tx		(UART_Tx),
		   .UART_Interrupt	(UART_Interrupt),
		   .FIT1_Interrupt	(FIT1_Interrupt),
		   .FIT1_Toggle		(FIT1_Toggle),
		   .FIT2_Interrupt	(FIT2_Interrupt),
		   .FIT2_Toggle		(FIT2_Toggle),
		   .FIT3_Interrupt	(FIT3_Interrupt),
		   .FIT3_Toggle		(FIT3_Toggle),
		   .FIT4_Interrupt	(FIT4_Interrupt),
		   .FIT4_Toggle		(FIT4_Toggle),
		   .PIT1_Interrupt	(PIT1_Interrupt),
		   .PIT1_Toggle		(PIT1_Toggle),
		   .PIT2_Interrupt	(PIT2_Interrupt),
		   .PIT2_Toggle		(PIT2_Toggle),
		   .PIT3_Interrupt	(PIT3_Interrupt),
		   .PIT3_Toggle		(PIT3_Toggle),
		   .PIT4_Interrupt	(PIT4_Interrupt),
		   .PIT4_Toggle		(PIT4_Toggle),
		   .GPO1		(GPO1[C_GPO1_SIZE-1:0]),
		   .GPO2		(GPO2[C_GPO2_SIZE-1:0]),
		   .GPO3		(GPO3[C_GPO3_SIZE-1:0]),
		   .GPO4		(GPO4[C_GPO4_SIZE-1:0]),
		   .INTC_IRQ		(INTC_IRQ),
		   .Trace_Instruction	(Trace_Instruction[0:31]),
		   .Trace_Valid_Instr	(Trace_Valid_Instr),
		   .Trace_PC		(Trace_PC[0:31]),
		   .Trace_Reg_Write	(Trace_Reg_Write),
		   .Trace_Reg_Addr	(Trace_Reg_Addr[0:4]),
		   .Trace_MSR_Reg	(Trace_MSR_Reg[0:14]),
		   .Trace_PID_Reg	(Trace_PID_Reg[0:7]),
		   .Trace_New_Reg_Value	(Trace_New_Reg_Value[0:31]),
		   .Trace_Exception_Taken(Trace_Exception_Taken),
		   .Trace_Exception_Kind(Trace_Exception_Kind[0:4]),
		   .Trace_Jump_Taken	(Trace_Jump_Taken),
		   .Trace_Delay_Slot	(Trace_Delay_Slot),
		   .Trace_Data_Address	(Trace_Data_Address[0:31]),
		   .Trace_Data_Access	(Trace_Data_Access),
		   .Trace_Data_Read	(Trace_Data_Read),
		   .Trace_Data_Write	(Trace_Data_Write),
		   .Trace_Data_Write_Value(Trace_Data_Write_Value[0:31]),
		   .Trace_Data_Byte_Enable(Trace_Data_Byte_Enable[0:3]),
		   .Trace_DCache_Req	(Trace_DCache_Req),
		   .Trace_DCache_Hit	(Trace_DCache_Hit),
		   .Trace_DCache_Rdy	(Trace_DCache_Rdy),
		   .Trace_DCache_Read	(Trace_DCache_Read),
		   .Trace_ICache_Req	(Trace_ICache_Req),
		   .Trace_ICache_Hit	(Trace_ICache_Hit),
		   .Trace_ICache_Rdy	(Trace_ICache_Rdy),
		   .Trace_OF_PipeRun	(Trace_OF_PipeRun),
		   .Trace_EX_PipeRun	(Trace_EX_PipeRun),
		   .Trace_MEM_PipeRun	(Trace_MEM_PipeRun),
		   .Trace_MB_Halted	(Trace_MB_Halted),
		   .Trace_Jump_Hit	(Trace_Jump_Hit),
		   .DBG_TDO		(DBG_TDO),
		   .ICACHE_FSL_IN_CLK	(ICACHE_FSL_IN_CLK),
		   .ICACHE_FSL_IN_READ	(ICACHE_FSL_IN_READ),
		   .ICACHE_FSL_OUT_CLK	(ICACHE_FSL_OUT_CLK),
		   .ICACHE_FSL_OUT_WRITE(ICACHE_FSL_OUT_WRITE),
		   .ICACHE_FSL_OUT_DATA	(ICACHE_FSL_OUT_DATA[0:31]),
		   .ICACHE_FSL_OUT_CONTROL(ICACHE_FSL_OUT_CONTROL),
		   .DCACHE_FSL_IN_CLK	(DCACHE_FSL_IN_CLK),
		   .DCACHE_FSL_IN_READ	(DCACHE_FSL_IN_READ),
		   .DCACHE_FSL_OUT_CLK	(DCACHE_FSL_OUT_CLK),
		   .DCACHE_FSL_OUT_WRITE(DCACHE_FSL_OUT_WRITE),
		   .DCACHE_FSL_OUT_DATA	(DCACHE_FSL_OUT_DATA[0:31]),
		   .DCACHE_FSL_OUT_CONTROL(DCACHE_FSL_OUT_CONTROL),
		   .dlmb_BRAM_Din	(dlmb_BRAM_Din[0:31]),
		   .ilmb_BRAM_Din	(ilmb_BRAM_Din[0:31]),
		   // Inputs
		   .Clk			(Clk),
		   .Reset		(Reset),
		   .IO_Read_Data	(IO_Read_Data[31:0]),
		   .IO_Ready		(IO_Ready),
		   .UART_Rx		(UART_Rx),
		   .PIT1_Enable		(PIT1_Enable),
		   .PIT2_Enable		(PIT2_Enable),
		   .PIT3_Enable		(PIT3_Enable),
		   .PIT4_Enable		(PIT4_Enable),
		   .GPI1		(GPI1[C_GPI1_SIZE-1:0]),
		   .GPI2		(GPI2[C_GPI2_SIZE-1:0]),
		   .GPI3		(GPI3[C_GPI3_SIZE-1:0]),
		   .GPI4		(GPI4[C_GPI4_SIZE-1:0]),
		   .INTC_Interrupt	(INTC_Interrupt[C_INTC_INTR_SIZE-1:0]),
		   .DBG_CAPTURE		(DBG_CAPTURE),
		   .DBG_CLK		(DBG_CLK),
		   .DBG_REG_EN		(DBG_REG_EN[0:7]),
		   .DBG_RST		(DBG_RST),
		   .DBG_SHIFT		(DBG_SHIFT),
		   .DBG_TDI		(DBG_TDI),
		   .DBG_UPDATE		(DBG_UPDATE),
		   .DBG_STOP		(DBG_STOP),
		   .ICACHE_FSL_IN_DATA	(ICACHE_FSL_IN_DATA[0:31]),
		   .ICACHE_FSL_IN_CONTROL(ICACHE_FSL_IN_CONTROL),
		   .ICACHE_FSL_IN_EXISTS(ICACHE_FSL_IN_EXISTS),
		   .ICACHE_FSL_OUT_FULL	(ICACHE_FSL_OUT_FULL),
		   .DCACHE_FSL_IN_DATA	(DCACHE_FSL_IN_DATA[0:31]),
		   .DCACHE_FSL_IN_CONTROL(DCACHE_FSL_IN_CONTROL),
		   .DCACHE_FSL_IN_EXISTS(DCACHE_FSL_IN_EXISTS),
		   .DCACHE_FSL_OUT_FULL	(DCACHE_FSL_OUT_FULL),
		   .dlmb_BRAM_Addr	(dlmb_BRAM_Addr[0:31]),
		   .dlmb_BRAM_Clk	(dlmb_BRAM_Clk),
		   .dlmb_BRAM_Dout	(dlmb_BRAM_Dout[0:31]),
		   .dlmb_BRAM_EN	(dlmb_BRAM_EN),
		   .dlmb_BRAM_Rst	(dlmb_BRAM_Rst),
		   .dlmb_BRAM_WEN	(dlmb_BRAM_WEN[0:3]),
		   .ilmb_BRAM_Addr	(ilmb_BRAM_Addr[0:31]),
		   .ilmb_BRAM_Clk	(ilmb_BRAM_Clk),
		   .ilmb_BRAM_Dout	(ilmb_BRAM_Dout[0:31]),
		   .ilmb_BRAM_EN	(ilmb_BRAM_EN),
		   .ilmb_BRAM_Rst	(ilmb_BRAM_Rst),
		   .ilmb_BRAM_WEN	(ilmb_BRAM_WEN[0:3]));
   
   mb_io #(/*AUTOINSTPARAM*/
	   // Parameters
	   .C_FAMILY			(C_FAMILY),
	   .C_XDEVICE			(C_XDEVICE),
	   .C_XPACKAGE			(C_XPACKAGE),
	   .C_XSPEEDGRADE		(C_XSPEEDGRADE),
	   .C_MICROBLAZE_INSTANCE	(C_MICROBLAZE_INSTANCE),
	   .C_PATH			(C_PATH),
	   .C_FREQ			(C_FREQ),
	   .C_DEBUG_ENABLED		(C_DEBUG_ENABLED),
	   .C_TRACE			(C_TRACE),
	   .C_USE_IO_BUS		(C_USE_IO_BUS),
	   .C_USE_UART_RX		(C_USE_UART_RX),
	   .C_USE_UART_TX		(C_USE_UART_TX),
	   .C_UART_BAUDRATE		(C_UART_BAUDRATE),
	   .C_UART_DATA_BITS		(C_UART_DATA_BITS),
	   .C_UART_USE_PARITY		(C_UART_USE_PARITY),
	   .C_UART_ODD_PARITY		(C_UART_ODD_PARITY),
	   .C_UART_RX_INTERRUPT		(C_UART_RX_INTERRUPT),
	   .C_UART_TX_INTERRUPT		(C_UART_TX_INTERRUPT),
	   .C_UART_ERROR_INTERRUPT	(C_UART_ERROR_INTERRUPT),
	   .C_USE_FIT1			(C_USE_FIT1),
	   .C_FIT1_No_CLOCKS		(C_FIT1_No_CLOCKS),
	   .C_FIT1_INTERRUPT		(C_FIT1_INTERRUPT),
	   .C_USE_FIT2			(C_USE_FIT2),
	   .C_FIT2_No_CLOCKS		(C_FIT2_No_CLOCKS),
	   .C_FIT2_INTERRUPT		(C_FIT2_INTERRUPT),
	   .C_USE_FIT3			(C_USE_FIT3),
	   .C_FIT3_No_CLOCKS		(C_FIT3_No_CLOCKS),
	   .C_FIT3_INTERRUPT		(C_FIT3_INTERRUPT),
	   .C_USE_FIT4			(C_USE_FIT4),
	   .C_FIT4_No_CLOCKS		(C_FIT4_No_CLOCKS),
	   .C_FIT4_INTERRUPT		(C_FIT4_INTERRUPT),
	   .C_USE_PIT1			(C_USE_PIT1),
	   .C_PIT1_SIZE			(C_PIT1_SIZE),
	   .C_PIT1_READABLE		(C_PIT1_READABLE),
	   .C_PIT1_PRESCALER		(C_PIT1_PRESCALER),
	   .C_PIT1_INTERRUPT		(C_PIT1_INTERRUPT),
	   .C_USE_PIT2			(C_USE_PIT2),
	   .C_PIT2_SIZE			(C_PIT2_SIZE),
	   .C_PIT2_READABLE		(C_PIT2_READABLE),
	   .C_PIT2_PRESCALER		(C_PIT2_PRESCALER),
	   .C_PIT2_INTERRUPT		(C_PIT2_INTERRUPT),
	   .C_USE_PIT3			(C_USE_PIT3),
	   .C_PIT3_SIZE			(C_PIT3_SIZE),
	   .C_PIT3_READABLE		(C_PIT3_READABLE),
	   .C_PIT3_PRESCALER		(C_PIT3_PRESCALER),
	   .C_PIT3_INTERRUPT		(C_PIT3_INTERRUPT),
	   .C_USE_PIT4			(C_USE_PIT4),
	   .C_PIT4_SIZE			(C_PIT4_SIZE),
	   .C_PIT4_READABLE		(C_PIT4_READABLE),
	   .C_PIT4_PRESCALER		(C_PIT4_PRESCALER),
	   .C_PIT4_INTERRUPT		(C_PIT4_INTERRUPT),
	   .C_USE_GPO1			(C_USE_GPO1),
	   .C_GPO1_SIZE			(C_GPO1_SIZE),
	   .C_GPO1_INIT			(C_GPO1_INIT[31:0]),
	   .C_USE_GPO2			(C_USE_GPO2),
	   .C_GPO2_SIZE			(C_GPO2_SIZE),
	   .C_GPO2_INIT			(C_GPO2_INIT[31:0]),
	   .C_USE_GPO3			(C_USE_GPO3),
	   .C_GPO3_SIZE			(C_GPO3_SIZE),
	   .C_GPO3_INIT			(C_GPO3_INIT[31:0]),
	   .C_USE_GPO4			(C_USE_GPO4),
	   .C_GPO4_SIZE			(C_GPO4_SIZE),
	   .C_GPO4_INIT			(C_GPO4_INIT[31:0]),
	   .C_USE_GPI1			(C_USE_GPI1),
	   .C_GPI1_SIZE			(C_GPI1_SIZE),
	   .C_USE_GPI2			(C_USE_GPI2),
	   .C_GPI2_SIZE			(C_GPI2_SIZE),
	   .C_USE_GPI3			(C_USE_GPI3),
	   .C_GPI3_SIZE			(C_GPI3_SIZE),
	   .C_USE_GPI4			(C_USE_GPI4),
	   .C_GPI4_SIZE			(C_GPI4_SIZE),
	   .C_INTC_USE_EXT_INTR		(C_INTC_USE_EXT_INTR),
	   .C_INTC_INTR_SIZE		(C_INTC_INTR_SIZE),
	   .C_INTC_LEVEL_EDGE		(C_INTC_LEVEL_EDGE[15:0]),
	   .C_INTC_POSITIVE		(C_INTC_POSITIVE[15:0]))
   mb_io  (/*AUTOINST*/
	   // Outputs
	   .Clk				(Clk),
	   .Reset			(Reset),
	   .PIT1_Enable			(PIT1_Enable),
	   .PIT2_Enable			(PIT2_Enable),
	   .PIT3_Enable			(PIT3_Enable),
	   .PIT4_Enable			(PIT4_Enable),
	   .UART_Rx			(UART_Rx),
	   .INTC_Interrupt		(INTC_Interrupt[C_INTC_INTR_SIZE-1:0]),
	   .GPI1			(GPI1[C_GPI1_SIZE-1:0]),
	   .GPI2			(GPI2[C_GPI2_SIZE-1:0]),
	   .GPI3			(GPI3[C_GPI3_SIZE-1:0]),
	   .GPI4			(GPI4[C_GPI4_SIZE-1:0]),
	   .IO_Read_Data		(IO_Read_Data[31:0]),
	   .IO_Ready			(IO_Ready),
	   .io_address0			(io_address0[5:0]),
	   .io_address1			(io_address1[5:0]),
	   .io_address2			(io_address2[5:0]),
	   .io_address3			(io_address3[5:0]),
	   .io_write0			(io_write0),
	   .io_write1			(io_write1),
	   .io_write2			(io_write2),
	   .io_write3			(io_write3),
	   .io_writedata0		(io_writedata0[31:0]),
	   .io_writedata1		(io_writedata1[31:0]),
	   .io_writedata2		(io_writedata2[31:0]),
	   .io_writedata3		(io_writedata3[31:0]),
	   .inband_cons_index		(inband_cons_index[11:0]),
	   .outband_prod_index		(outband_prod_index[11:0]),
	   .Trace_FW0			(Trace_FW0[127:0]),
	   .Trace_FW1			(Trace_FW1[127:0]),
	   .Trace_FW2			(Trace_FW2[127:0]),
	   .Trace_FW3			(Trace_FW3[127:0]),
	   // Inputs
	   .sys_clk			(sys_clk),
	   .sys_rst			(sys_rst),
	   .Trace_Instruction		(Trace_Instruction[0:31]),
	   .Trace_Valid_Instr		(Trace_Valid_Instr),
	   .Trace_PC			(Trace_PC[0:31]),
	   .Trace_Reg_Write		(Trace_Reg_Write),
	   .Trace_Reg_Addr		(Trace_Reg_Addr[0:4]),
	   .Trace_MSR_Reg		(Trace_MSR_Reg[0:14]),
	   .Trace_PID_Reg		(Trace_PID_Reg[0:7]),
	   .Trace_New_Reg_Value		(Trace_New_Reg_Value[0:31]),
	   .Trace_Exception_Taken	(Trace_Exception_Taken),
	   .Trace_Exception_Kind	(Trace_Exception_Kind[0:4]),
	   .Trace_Jump_Taken		(Trace_Jump_Taken),
	   .Trace_Delay_Slot		(Trace_Delay_Slot),
	   .Trace_Data_Address		(Trace_Data_Address[0:31]),
	   .Trace_Data_Access		(Trace_Data_Access),
	   .Trace_Data_Read		(Trace_Data_Read),
	   .Trace_Data_Write		(Trace_Data_Write),
	   .Trace_Data_Write_Value	(Trace_Data_Write_Value[0:31]),
	   .Trace_Data_Byte_Enable	(Trace_Data_Byte_Enable[0:3]),
	   .Trace_DCache_Req		(Trace_DCache_Req),
	   .Trace_DCache_Hit		(Trace_DCache_Hit),
	   .Trace_DCache_Rdy		(Trace_DCache_Rdy),
	   .Trace_DCache_Read		(Trace_DCache_Read),
	   .Trace_ICache_Req		(Trace_ICache_Req),
	   .Trace_ICache_Hit		(Trace_ICache_Hit),
	   .Trace_ICache_Rdy		(Trace_ICache_Rdy),
	   .Trace_OF_PipeRun		(Trace_OF_PipeRun),
	   .Trace_EX_PipeRun		(Trace_EX_PipeRun),
	   .Trace_MEM_PipeRun		(Trace_MEM_PipeRun),
	   .Trace_MB_Halted		(Trace_MB_Halted),
	   .Trace_Jump_Hit		(Trace_Jump_Hit),
	   .PIT1_Interrupt		(PIT1_Interrupt),
	   .PIT1_Toggle			(PIT1_Toggle),
	   .PIT2_Interrupt		(PIT2_Interrupt),
	   .PIT2_Toggle			(PIT2_Toggle),
	   .PIT3_Interrupt		(PIT3_Interrupt),
	   .PIT3_Toggle			(PIT3_Toggle),
	   .PIT4_Interrupt		(PIT4_Interrupt),
	   .PIT4_Toggle			(PIT4_Toggle),
	   .FIT1_Interrupt		(FIT1_Interrupt),
	   .FIT1_Toggle			(FIT1_Toggle),
	   .FIT2_Interrupt		(FIT2_Interrupt),
	   .FIT2_Toggle			(FIT2_Toggle),
	   .FIT3_Interrupt		(FIT3_Interrupt),
	   .FIT3_Toggle			(FIT3_Toggle),
	   .FIT4_Interrupt		(FIT4_Interrupt),
	   .FIT4_Toggle			(FIT4_Toggle),
	   .UART_Tx			(UART_Tx),
	   .UART_Interrupt		(UART_Interrupt),
	   .INTC_IRQ			(INTC_IRQ),
	   .GPO1			(GPO1[C_GPO1_SIZE-1:0]),
	   .GPO2			(GPO2[C_GPO2_SIZE-1:0]),
	   .GPO3			(GPO3[C_GPO3_SIZE-1:0]),
	   .GPO4			(GPO4[C_GPO4_SIZE-1:0]),
	   .IO_Addr_Strobe		(IO_Addr_Strobe),
	   .IO_Read_Strobe		(IO_Read_Strobe),
	   .IO_Write_Strobe		(IO_Write_Strobe),
	   .IO_Address			(IO_Address[31:0]),
	   .IO_Byte_Enable		(IO_Byte_Enable[3:0]),
	   .IO_Write_Data		(IO_Write_Data[31:0]),
	   .io_readdata0		(io_readdata0[31:0]),
	   .io_readdata1		(io_readdata1[31:0]),
	   .io_readdata2		(io_readdata2[31:0]),
	   .io_readdata3		(io_readdata3[31:0]),
	   .irq0			(irq0),
	   .irq1			(irq1),
	   .irq2			(irq2),
	   .irq3			(irq3),
	   .inband_base			(inband_base[31:0]),
	   .inband_cons_addr		(inband_cons_addr[31:0]),
	   .inband_prod_index		(inband_prod_index[11:0]),
	   .outband_base		(outband_base[31:0]),
	   .outband_prod_addr		(outband_prod_addr[31:0]),
	   .outband_cons_index		(outband_cons_index[11:0]),
	   .ring_enable			(ring_enable));
   
endmodule
// 
// mb_top.v ends here
