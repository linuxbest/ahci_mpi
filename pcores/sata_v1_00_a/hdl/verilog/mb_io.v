// mb_io.v --- 
// 
// Filename: mb_io.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Feb 24 15:33:26 2012 (+0800)
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
module mb_io (/*AUTOARG*/
   // Outputs
   IO_Read_Data, IO_Ready, GPI1, GPI2, GPI3, GPI4, INTC_Interrupt,
   UART_Rx, PIT1_Enable, PIT2_Enable, PIT3_Enable, PIT4_Enable, Clk,
   Reset, io_address0, io_address1, io_address2, io_address3,
   io_write0, io_write1, io_write2, io_write3, io_writedata0,
   io_writedata1, io_writedata2, io_writedata3, inband_cons_index,
   outband_prod_index, Trace_FW0, Trace_FW1, Trace_FW2, Trace_FW3,
   // Inputs
   IO_Addr_Strobe, IO_Read_Strobe, IO_Write_Strobe, IO_Address,
   IO_Byte_Enable, IO_Write_Data, GPO1, GPO2, GPO3, GPO4, INTC_IRQ,
   UART_Tx, UART_Interrupt, FIT1_Interrupt, FIT1_Toggle,
   FIT2_Interrupt, FIT2_Toggle, FIT3_Interrupt, FIT3_Toggle,
   FIT4_Interrupt, FIT4_Toggle, PIT1_Interrupt, PIT1_Toggle,
   PIT2_Interrupt, PIT2_Toggle, PIT3_Interrupt, PIT3_Toggle,
   PIT4_Interrupt, PIT4_Toggle, Trace_Instruction, Trace_Valid_Instr,
   Trace_PC, Trace_Reg_Write, Trace_Reg_Addr, Trace_MSR_Reg,
   Trace_PID_Reg, Trace_New_Reg_Value, Trace_Exception_Taken,
   Trace_Exception_Kind, Trace_Jump_Taken, Trace_Delay_Slot,
   Trace_Data_Address, Trace_Data_Access, Trace_Data_Read,
   Trace_Data_Write, Trace_Data_Write_Value, Trace_Data_Byte_Enable,
   Trace_DCache_Req, Trace_DCache_Hit, Trace_DCache_Rdy,
   Trace_DCache_Read, Trace_ICache_Req, Trace_ICache_Hit,
   Trace_ICache_Rdy, Trace_OF_PipeRun, Trace_EX_PipeRun,
   Trace_MEM_PipeRun, Trace_MB_Halted, Trace_Jump_Hit, sys_clk,
   sys_rst, io_readdata0, io_readdata1, io_readdata2, io_readdata3,
   irq0, irq1, irq2, irq3, inband_base, inband_cons_addr,
   inband_prod_index, outband_base, outband_prod_addr,
   outband_cons_index, ring_enable
   );
   parameter C_FAMILY = "virtex5";
   parameter C_XDEVICE = "xc5vlx50t";
   parameter C_XPACKAGE = "ff1136";
   parameter C_XSPEEDGRADE = "-1";
   parameter C_MICROBLAZE_INSTANCE = "microblaze_0";
   parameter C_PATH = "mb/U0";
   parameter C_FREQ = 100000000;
   
   parameter C_DEBUG_ENABLED = 1;
   parameter C_TRACE = 1;
   
   parameter C_USE_IO_BUS = 1;
   
   parameter C_USE_UART_RX = 1;
   parameter C_USE_UART_TX = 1;
   parameter C_UART_BAUDRATE = 115200;
   parameter C_UART_DATA_BITS = 8;
   parameter C_UART_USE_PARITY = 0;
   parameter C_UART_ODD_PARITY = 0;
   parameter C_UART_RX_INTERRUPT = 0;
   parameter C_UART_TX_INTERRUPT = 0;
   parameter C_UART_ERROR_INTERRUPT = 0;
   
   parameter C_USE_FIT1 = 0;
   parameter C_FIT1_No_CLOCKS = 6216;
   parameter C_FIT1_INTERRUPT = 0;
   parameter C_USE_FIT2 = 0;
   parameter C_FIT2_No_CLOCKS = 6216;
   parameter C_FIT2_INTERRUPT = 0;
   parameter C_USE_FIT3 = 0;
   parameter C_FIT3_No_CLOCKS = 6216;
   parameter C_FIT3_INTERRUPT = 0;
   parameter C_USE_FIT4 = 0;
   parameter C_FIT4_No_CLOCKS = 6216;
   parameter C_FIT4_INTERRUPT = 0;
   parameter C_USE_PIT1 = 0;
   parameter C_PIT1_SIZE = 32;
   parameter C_PIT1_READABLE = 1;
   parameter C_PIT1_PRESCALER = 0;
   parameter C_PIT1_INTERRUPT = 0;
   parameter C_USE_PIT2 = 0;
   parameter C_PIT2_SIZE = 32;
   parameter C_PIT2_READABLE = 1; 
   parameter C_PIT2_PRESCALER = 0;
   parameter C_PIT2_INTERRUPT = 0;
   parameter C_USE_PIT3 = 0;
   parameter C_PIT3_SIZE = 32;
   parameter C_PIT3_READABLE = 1;
   parameter C_PIT3_PRESCALER = 0;
   parameter C_PIT3_INTERRUPT = 0;
   parameter C_USE_PIT4 = 0;
   parameter C_PIT4_SIZE = 32;
   parameter C_PIT4_READABLE = 1;
   parameter C_PIT4_PRESCALER = 0;
   parameter C_PIT4_INTERRUPT = 0;
   
   parameter C_USE_GPO1 = 0;
   parameter C_GPO1_SIZE = 32;
   parameter[31:0] C_GPO1_INIT = 0;
   parameter C_USE_GPO2 = 0;
   parameter C_GPO2_SIZE = 32;
   parameter[31:0] C_GPO2_INIT = 0;
   parameter C_USE_GPO3 = 0;
   parameter C_GPO3_SIZE = 32;
   parameter[31:0] C_GPO3_INIT = 0;
   parameter C_USE_GPO4 = 0;
   parameter C_GPO4_SIZE = 32;
   parameter[31:0] C_GPO4_INIT = 0;
   parameter C_USE_GPI1 = 0;
   parameter C_GPI1_SIZE = 32;
   parameter C_USE_GPI2 = 0;
   parameter C_GPI2_SIZE = 32;
   parameter C_USE_GPI3 = 0;
   parameter C_GPI3_SIZE = 32;
   parameter C_USE_GPI4 = 0;
   parameter C_GPI4_SIZE = 32;
   
   parameter C_INTC_USE_EXT_INTR = 0;
   parameter C_INTC_INTR_SIZE = 16;
   parameter[15:0] C_INTC_LEVEL_EDGE = 16'h0000;
   parameter[15:0] C_INTC_POSITIVE = 16'hffff;
   
   input sys_clk;
   input sys_rst;
   
   output Clk;
   output Reset;

   /*AUTOINOUTCOMP("microblaze_mcs", "^Trace")*/
   // Beginning of automatic in/out/inouts (from specific module)
   input [0:31]		Trace_Instruction;
   input		Trace_Valid_Instr;
   input [0:31]		Trace_PC;
   input		Trace_Reg_Write;
   input [0:4]		Trace_Reg_Addr;
   input [0:14]		Trace_MSR_Reg;
   input [0:7]		Trace_PID_Reg;
   input [0:31]		Trace_New_Reg_Value;
   input		Trace_Exception_Taken;
   input [0:4]		Trace_Exception_Kind;
   input		Trace_Jump_Taken;
   input		Trace_Delay_Slot;
   input [0:31]		Trace_Data_Address;
   input		Trace_Data_Access;
   input		Trace_Data_Read;
   input		Trace_Data_Write;
   input [0:31]		Trace_Data_Write_Value;
   input [0:3]		Trace_Data_Byte_Enable;
   input		Trace_DCache_Req;
   input		Trace_DCache_Hit;
   input		Trace_DCache_Rdy;
   input		Trace_DCache_Read;
   input		Trace_ICache_Req;
   input		Trace_ICache_Hit;
   input		Trace_ICache_Rdy;
   input		Trace_OF_PipeRun;
   input		Trace_EX_PipeRun;
   input		Trace_MEM_PipeRun;
   input		Trace_MB_Halted;
   input		Trace_Jump_Hit;
   // End of automatics
   /*AUTOINOUTCOMP("microblaze_mcs", "^PIT")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		PIT1_Enable;
   output		PIT2_Enable;
   output		PIT3_Enable;
   output		PIT4_Enable;
   input		PIT1_Interrupt;
   input		PIT1_Toggle;
   input		PIT2_Interrupt;
   input		PIT2_Toggle;
   input		PIT3_Interrupt;
   input		PIT3_Toggle;
   input		PIT4_Interrupt;
   input		PIT4_Toggle;
   // End of automatics
   /*AUTOINOUTCOMP("microblaze_mcs", "^FIT")*/
   // Beginning of automatic in/out/inouts (from specific module)
   input		FIT1_Interrupt;
   input		FIT1_Toggle;
   input		FIT2_Interrupt;
   input		FIT2_Toggle;
   input		FIT3_Interrupt;
   input		FIT3_Toggle;
   input		FIT4_Interrupt;
   input		FIT4_Toggle;
   // End of automatics
   /*AUTOINOUTCOMP("microblaze_mcs", "^UART")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		UART_Rx;
   input		UART_Tx;
   input		UART_Interrupt;
   // End of automatics
   /*AUTOINOUTCOMP("microblaze_mcs", "^INTC")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [C_INTC_INTR_SIZE-1:0] INTC_Interrupt;
   input		INTC_IRQ;
   // End of automatics
   /*AUTOINOUTCOMP("microblaze_mcs", "^GP")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [C_GPI1_SIZE-1:0] GPI1;
   output [C_GPI2_SIZE-1:0] GPI2;
   output [C_GPI3_SIZE-1:0] GPI3;
   output [C_GPI4_SIZE-1:0] GPI4;
   input [C_GPO1_SIZE-1:0] GPO1;
   input [C_GPO2_SIZE-1:0] GPO2;
   input [C_GPO3_SIZE-1:0] GPO3;
   input [C_GPO4_SIZE-1:0] GPO4;
   // End of automatics
   
   /*AUTOINOUTCOMP("microblaze_mcs", "^IO")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output [31:0]	IO_Read_Data;
   output		IO_Ready;
   input		IO_Addr_Strobe;
   input		IO_Read_Strobe;
   input		IO_Write_Strobe;
   input [31:0]		IO_Address;
   input [3:0]		IO_Byte_Enable;
   input [31:0]		IO_Write_Data;
   // End of automatics

   output [5:0]		io_address0;
   output [5:0]		io_address1;
   output [5:0]		io_address2;
   output [5:0]		io_address3;
   output		io_write0;
   output		io_write1;
   output		io_write2;
   output		io_write3;
   output [31:0]	io_writedata0;
   output [31:0]	io_writedata1;
   output [31:0]	io_writedata2;
   output [31:0]	io_writedata3;
   input [31:0]		io_readdata0;
   input [31:0]		io_readdata1;
   input [31:0]		io_readdata2;
   input [31:0]		io_readdata3;
   input 		irq0;
   input 		irq1;
   input 		irq2;
   input 		irq3;
   
   input [31:0] 	inband_base;
   input [31:0] 	inband_cons_addr;
   input [11:0] 	inband_prod_index;
   output [11:0] 	inband_cons_index;
   
   input [31:0] 	outband_base;
   input [31:0] 	outband_prod_addr;
   input [11:0] 	outband_cons_index;
   output [11:0] 	outband_prod_index;

   input 		ring_enable;
   output [127:0] 	Trace_FW0;
   output [127:0] 	Trace_FW1;
   output [127:0] 	Trace_FW2;
   output [127:0] 	Trace_FW3;
   /**********************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [C_GPI1_SIZE-1:0] GPI1;
   reg [C_GPI2_SIZE-1:0] GPI2;
   reg [C_GPI3_SIZE-1:0] GPI3;
   reg [C_GPI4_SIZE-1:0] GPI4;
   reg [31:0]		IO_Read_Data;
   reg			IO_Ready;
   reg			PIT1_Enable;
   reg			PIT2_Enable;
   reg			PIT3_Enable;
   reg			PIT4_Enable;
   reg			UART_Rx;
   reg [11:0]		inband_cons_index;
   reg [11:0]		outband_prod_index;
   // End of automatics
   /**********************************************************************/
   wire [31:0] 		io_writedata8;
   reg [31:0] 		io_readdata8;   
   wire 		io_write8;
   wire [5:0] 		io_address8;
   // 0xa0000000 dma0
   // 0xa0000100 dma1
   // 0xa0000200 dma2
   // 0xa0000300 dma3
   // 0xa0000800 ctrl
   reg [31:0] 		IO_Read_Data_i;
   reg [1:0] 		IO_stb;
   always @(posedge sys_clk)
     begin
	IO_Read_Data <= #1 IO_Read_Data_i;
	IO_stb[0]    <= #1 IO_Addr_Strobe;
	IO_stb[1]    <= #1 IO_stb[0];
	IO_Ready     <= #1 IO_stb[0];
     end
   assign io_address0   = IO_Address;
   assign io_address1   = IO_Address;
   assign io_address2   = IO_Address;
   assign io_address3   = IO_Address;
   assign io_address8   = IO_Address;
   assign io_writedata0 = IO_Write_Data;
   assign io_writedata1 = IO_Write_Data;
   assign io_writedata2 = IO_Write_Data;
   assign io_writedata3 = IO_Write_Data;
   assign io_writedata8 = IO_Write_Data;
   assign io_write0     = |IO_Write_Strobe && IO_Address[11:8] == 0;
   assign io_write1     = |IO_Write_Strobe && IO_Address[11:8] == 1;
   assign io_write2     = |IO_Write_Strobe && IO_Address[11:8] == 2;
   assign io_write3     = |IO_Write_Strobe && IO_Address[11:8] == 3;
   assign io_write8     = |IO_Write_Strobe && IO_Address[11:8] == 8;
   always @(*)
     begin
	IO_Read_Data_i = 32'h0;
	case (IO_Address[11:8])
	  4'h0: IO_Read_Data_i = io_readdata0;
	  4'h1: IO_Read_Data_i = io_readdata1;
	  4'h2: IO_Read_Data_i = io_readdata2;
	  4'h3: IO_Read_Data_i = io_readdata3;
	  4'h8: IO_Read_Data_i = io_readdata8;
	endcase
     end // always @ (*)
   /**********************************************************************/
   reg [15:0] irq;
   // 00: irqstat
   // 04: irqen
   // 10: inband base
   // 04: inband cons addr
   // 18: inband prod index
   // 1C: inband cons index
   // 20: outband base
   // 24: outband prod add
   // 28: outband cons index
   // 2C: outband prod index
   reg [31:0] readdata_i;
   always @(*)
   begin
      readdata_i = 32'h0;
      case (io_address8)
	6'h0:  readdata_i = irq;
	6'h8:  readdata_i = ring_enable;
	6'h10: readdata_i = inband_base;
	6'h14: readdata_i = inband_cons_addr;
	6'h18: readdata_i = inband_prod_index;
	6'h1C: readdata_i = inband_cons_index;
	6'h20: readdata_i = outband_base;
	6'h24: readdata_i = outband_prod_addr;
	6'h28: readdata_i = outband_cons_index;
	6'h2C: readdata_i = outband_prod_index;
      endcase
   end
   reg [31:0] dbg0;
   always @(posedge sys_clk)
     begin
	if (io_write8 && io_address8 == 6'h1C)
	  inband_cons_index <= #1 io_writedata8;
	if (io_write8 && io_address8 == 6'h2C)
	  outband_prod_index <= #1 io_writedata8;
	if (io_write8 && io_address8 == 6'h30)
	  dbg0 <= #1 io_writedata8;
     end
   always @(posedge sys_clk)
     begin
	irq[0]       <= #1 irq0;
	irq[1]       <= #1 irq1;
	irq[2]       <= #1 irq2;
	irq[3]       <= #1 irq3;
	irq[15]      <= #1 inband_prod_index != inband_cons_index;
	irq[14:4]    <= #1 0;
	io_readdata8 <= #1 readdata_i;
     end
   assign INTC_Interrupt = irq;
   /**********************************************************************/
   assign Clk   = sys_clk;
   assign Reset = sys_rst;
   /**********************************************************************/
   wire [127:0] Trace;
   assign Trace[31:0]   = Trace_Instruction;
   assign Trace[63:32]  = Trace_PC;
   assign Trace[95:64]  = Trace_New_Reg_Value;
   assign Trace[96]     = Trace_Valid_Instr;
   assign Trace[97]     = Trace_Reg_Write;
   assign Trace[98]     = Trace_MB_Halted;
   assign Trace[99]     = Trace_Data_Write;
   assign Trace[100]    = Trace_Data_Read;
   assign Trace[101]    = Trace_Data_Access;
   assign Trace[102]    = Trace_Delay_Slot;
   assign Trace[103]    = Trace_Jump_Taken;
   assign Trace[108:104]= Trace_Reg_Addr;
   assign Trace[127:109]= 0;

   assign Trace_FW0 = Trace;
   assign Trace_FW1 = Trace;
   assign Trace_FW2 = Trace;
   assign Trace_FW3 = Trace;
   /**********************************************************************/
   wire 	MB_started;
   wire 	MB_stopped;
   wire 	collect_in;
   wire 	trigger_in;
   wire 	include_data;
   assign MB_stopped = 0;
   assign trigger_in = 0;
   assign include_data = 0;
   
   wire [0:17] 	encoder_data;
   wire 	collect_out;
   wire 	trigger_out;
   wire [0:31] 	dfifo_data;
   wire [0:16] 	dfifo_status;
   wire 	dfifo_reset;
   wire 	dfifo_valid;
   encoder encoder (.Clk(sys_clk),
		    .Rst(sys_rst),
		    /*AUTOINST*/
		    // Outputs
		    .encoder_data	(encoder_data[0:17]),
		    .collect_out	(collect_out),
		    .trigger_out	(trigger_out),
		    .dfifo_data		(dfifo_data[0:31]),
		    .dfifo_status	(dfifo_status[0:16]),
		    .dfifo_valid	(dfifo_valid),
		    .dfifo_reset	(dfifo_reset),
		    // Inputs
		    .Trace_Instruction	(Trace_Instruction[0:31]),
		    .Trace_Valid_Instr	(Trace_Valid_Instr),
		    .Trace_PC		(Trace_PC[0:31]),
		    .Trace_Reg_Write	(Trace_Reg_Write),
		    .Trace_Reg_Addr	(Trace_Reg_Addr[0:4]),
		    .Trace_MSR_Reg	(Trace_MSR_Reg[0:14]),
		    .Trace_PID_Reg	(Trace_PID_Reg[0:7]),
		    .Trace_New_Reg_Value(Trace_New_Reg_Value[0:31]),
		    .Trace_Exception_Taken(Trace_Exception_Taken),
		    .Trace_Exception_Kind(Trace_Exception_Kind[0:4]),
		    .Trace_Jump_Taken	(Trace_Jump_Taken),
		    .Trace_Delay_Slot	(Trace_Delay_Slot),
		    .Trace_Data_Address	(Trace_Data_Address[0:31]),
		    .Trace_Data_Write_Value(Trace_Data_Write_Value[0:31]),
		    .Trace_Data_Byte_Enable(Trace_Data_Byte_Enable[0:3]),
		    .Trace_Data_Access	(Trace_Data_Access),
		    .Trace_Data_Read	(Trace_Data_Read),
		    .Trace_Data_Write	(Trace_Data_Write),
		    .Trace_DCache_Req	(Trace_DCache_Req),
		    .Trace_DCache_Hit	(Trace_DCache_Hit),
		    .Trace_ICache_Req	(Trace_ICache_Req),
		    .Trace_ICache_Hit	(Trace_ICache_Hit),
		    .Trace_OF_PipeRun	(Trace_OF_PipeRun),
		    .Trace_EX_PipeRun	(Trace_EX_PipeRun),
		    .Trace_MEM_PipeRun	(Trace_MEM_PipeRun),
		    .MB_started		(MB_started),
		    .MB_stopped		(MB_stopped),
		    .collect_in		(collect_in),
		    .trigger_in		(trigger_in),
		    .include_data	(include_data));
endmodule
// 
// mb_io.v ends here
