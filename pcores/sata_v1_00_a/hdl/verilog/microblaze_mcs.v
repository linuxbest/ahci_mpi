module microblaze_mcs(/*AUTOARG*/
   // Outputs
   IO_Addr_Strobe, IO_Read_Strobe, IO_Write_Strobe, IO_Address,
   IO_Byte_Enable, IO_Write_Data, UART_Tx, UART_Interrupt,
   FIT1_Interrupt, FIT1_Toggle, FIT2_Interrupt, FIT2_Toggle,
   FIT3_Interrupt, FIT3_Toggle, FIT4_Interrupt, FIT4_Toggle,
   PIT1_Interrupt, PIT1_Toggle, PIT2_Interrupt, PIT2_Toggle,
   PIT3_Interrupt, PIT3_Toggle, PIT4_Interrupt, PIT4_Toggle, GPO1,
   GPO2, GPO3, GPO4, INTC_IRQ, Trace_Instruction, Trace_Valid_Instr,
   Trace_PC, Trace_Reg_Write, Trace_Reg_Addr, Trace_MSR_Reg,
   Trace_PID_Reg, Trace_New_Reg_Value, Trace_Exception_Taken,
   Trace_Exception_Kind, Trace_Jump_Taken, Trace_Delay_Slot,
   Trace_Data_Address, Trace_Data_Access, Trace_Data_Read,
   Trace_Data_Write, Trace_Data_Write_Value, Trace_Data_Byte_Enable,
   Trace_DCache_Req, Trace_DCache_Hit, Trace_DCache_Rdy,
   Trace_DCache_Read, Trace_ICache_Req, Trace_ICache_Hit,
   Trace_ICache_Rdy, Trace_OF_PipeRun, Trace_EX_PipeRun,
   Trace_MEM_PipeRun, Trace_MB_Halted, Trace_Jump_Hit, DBG_TDO,
   ICACHE_FSL_IN_CLK, ICACHE_FSL_IN_READ, ICACHE_FSL_OUT_CLK,
   ICACHE_FSL_OUT_WRITE, ICACHE_FSL_OUT_DATA, ICACHE_FSL_OUT_CONTROL,
   DCACHE_FSL_IN_CLK, DCACHE_FSL_IN_READ, DCACHE_FSL_OUT_CLK,
   DCACHE_FSL_OUT_WRITE, DCACHE_FSL_OUT_DATA, DCACHE_FSL_OUT_CONTROL,
   dlmb_BRAM_Din, ilmb_BRAM_Din,
   // Inputs
   Clk, Reset, IO_Read_Data, IO_Ready, UART_Rx, PIT1_Enable,
   PIT2_Enable, PIT3_Enable, PIT4_Enable, GPI1, GPI2, GPI3, GPI4,
   INTC_Interrupt, DBG_CAPTURE, DBG_CLK, DBG_REG_EN, DBG_RST,
   DBG_SHIFT, DBG_TDI, DBG_UPDATE, DBG_STOP, ICACHE_FSL_IN_DATA,
   ICACHE_FSL_IN_CONTROL, ICACHE_FSL_IN_EXISTS, ICACHE_FSL_OUT_FULL,
   DCACHE_FSL_IN_DATA, DCACHE_FSL_IN_CONTROL, DCACHE_FSL_IN_EXISTS,
   DCACHE_FSL_OUT_FULL, dlmb_BRAM_Addr, dlmb_BRAM_Clk, dlmb_BRAM_Dout,
   dlmb_BRAM_EN, dlmb_BRAM_Rst, dlmb_BRAM_WEN, ilmb_BRAM_Addr,
   ilmb_BRAM_Clk, ilmb_BRAM_Dout, ilmb_BRAM_EN, ilmb_BRAM_Rst,
   ilmb_BRAM_WEN
   );

   parameter C_FAMILY;
   parameter C_XDEVICE;
   parameter C_XPACKAGE;
   parameter C_XSPEEDGRADE;
   parameter C_MICROBLAZE_INSTANCE;
   parameter C_PATH;
   parameter C_FREQ;
   parameter C_MEMSIZE_I;
   parameter C_MEMSIZE_D;
   parameter C_DEBUG_ENABLED;
   parameter C_TRACE;
   parameter C_USE_IO_BUS;
   parameter C_USE_UART_RX;
   parameter C_USE_UART_TX;
   parameter C_UART_BAUDRATE;
   parameter C_UART_DATA_BITS;
   parameter C_UART_USE_PARITY;
   parameter C_UART_ODD_PARITY;
   parameter C_UART_RX_INTERRUPT;
   parameter C_UART_TX_INTERRUPT;
   parameter C_UART_ERROR_INTERRUPT;
   parameter C_USE_FIT1;
   parameter C_FIT1_No_CLOCKS;
   parameter C_FIT1_INTERRUPT;
   parameter C_USE_FIT2;
   parameter C_FIT2_No_CLOCKS;
   parameter C_FIT2_INTERRUPT;
   parameter C_USE_FIT3;
   parameter C_FIT3_No_CLOCKS;
   parameter C_FIT3_INTERRUPT;
   parameter C_USE_FIT4;
   parameter C_FIT4_No_CLOCKS;
   parameter C_FIT4_INTERRUPT;
   parameter C_USE_PIT1;
   parameter C_PIT1_SIZE;
   parameter C_PIT1_READABLE;
   parameter C_PIT1_PRESCALER;
   parameter C_PIT1_INTERRUPT;
   parameter C_USE_PIT2;
   parameter C_PIT2_SIZE;
   parameter C_PIT2_READABLE;
   parameter C_PIT2_PRESCALER;
   parameter C_PIT2_INTERRUPT;
   parameter C_USE_PIT3;
   parameter C_PIT3_SIZE;
   parameter C_PIT3_READABLE;
   parameter C_PIT3_PRESCALER;
   parameter C_PIT3_INTERRUPT;
   parameter C_USE_PIT4;
   parameter C_PIT4_SIZE;
   parameter C_PIT4_READABLE;
   parameter C_PIT4_PRESCALER;
   parameter C_PIT4_INTERRUPT;
   parameter C_USE_GPO1;
   parameter C_GPO1_SIZE;
   parameter[31:0] C_GPO1_INIT;
   parameter C_USE_GPO2;
   parameter C_GPO2_SIZE;
   parameter[31:0] C_GPO2_INIT;
   parameter C_USE_GPO3;
   parameter C_GPO3_SIZE;
   parameter[31:0] C_GPO3_INIT;
   parameter C_USE_GPO4;
   parameter C_GPO4_SIZE;
   parameter[31:0] C_GPO4_INIT;
   parameter C_USE_GPI1;
   parameter C_GPI1_SIZE;
   parameter C_USE_GPI2;
   parameter C_GPI2_SIZE;
   parameter C_USE_GPI3;
   parameter C_GPI3_SIZE;
   parameter C_USE_GPI4;
   parameter C_GPI4_SIZE;
   parameter C_INTC_USE_EXT_INTR;
   parameter C_INTC_INTR_SIZE;
   parameter[15:0] C_INTC_LEVEL_EDGE;
   parameter[15:0] C_INTC_POSITIVE;

   input Clk;
   input Reset;
   
   output IO_Addr_Strobe;
   output IO_Read_Strobe;
   output IO_Write_Strobe;
   output [31:0] IO_Address;
   output [3:0]  IO_Byte_Enable;
   output [31:0] IO_Write_Data;
   input [31:0]  IO_Read_Data;
   
   input 	 IO_Ready;
   input 	 UART_Rx;
   output 	 UART_Tx;
   output 	 UART_Interrupt;
   output 	 FIT1_Interrupt;
   output 	 FIT1_Toggle;
   output 	 FIT2_Interrupt;
   output 	 FIT2_Toggle;
   output 	 FIT3_Interrupt;
   output 	 FIT3_Toggle;
   output 	 FIT4_Interrupt;
   output 	 FIT4_Toggle;
   input 	 PIT1_Enable;
   
   output 	 PIT1_Interrupt;
   output 	 PIT1_Toggle;
   input 	 PIT2_Enable;
   
   output 	 PIT2_Interrupt;
   output 	 PIT2_Toggle;
   input 	 PIT3_Enable;
   
   output 	 PIT3_Interrupt;
   output 	 PIT3_Toggle;
   input 	 PIT4_Enable;
   
   output 	 PIT4_Interrupt;
   output 	 PIT4_Toggle;
   output [C_GPO1_SIZE - 1:0] GPO1;
   output [C_GPO2_SIZE - 1:0] GPO2;
   output [C_GPO3_SIZE - 1:0] GPO3;
   output [C_GPO4_SIZE - 1:0] GPO4;
   input [C_GPI1_SIZE - 1:0]  GPI1;
   input [C_GPI2_SIZE - 1:0]  GPI2;
   input [C_GPI3_SIZE - 1:0]  GPI3;
   input [C_GPI4_SIZE - 1:0]  GPI4;
   input [C_INTC_INTR_SIZE - 1:0] INTC_Interrupt;
   output 			  INTC_IRQ;
   
   output [0:31]		  Trace_Instruction;
   output 			  Trace_Valid_Instr;
   output [0:31]		  Trace_PC;
   output 			  Trace_Reg_Write;
   output [0:4] 		  Trace_Reg_Addr;
   output [0:14] 		  Trace_MSR_Reg;
   output [0:7] 		  Trace_PID_Reg;
   output [0:31] 		  Trace_New_Reg_Value;
   output 			  Trace_Exception_Taken;
   output [0:4] 		  Trace_Exception_Kind;
   output 			  Trace_Jump_Taken;
   output 			  Trace_Delay_Slot;
   output [0:31] 		  Trace_Data_Address;
   output 			  Trace_Data_Access;
   output 			  Trace_Data_Read;
   output 			  Trace_Data_Write;
   output [0:31] 		  Trace_Data_Write_Value;
   output [0:3] 		  Trace_Data_Byte_Enable;
   output 			  Trace_DCache_Req;
   output 			  Trace_DCache_Hit;
   output 			  Trace_DCache_Rdy;
   output 			  Trace_DCache_Read;
   output 			  Trace_ICache_Req;
   output 			  Trace_ICache_Hit;
   output 			  Trace_ICache_Rdy;
   output 			  Trace_OF_PipeRun;
   output 			  Trace_EX_PipeRun;
   output 			  Trace_MEM_PipeRun;
   output 			  Trace_MB_Halted;
   output 			  Trace_Jump_Hit;
   
   input 			  DBG_CAPTURE;
   input 			  DBG_CLK;
   input [0:7] 			  DBG_REG_EN;
   input 			  DBG_RST;
   input 			  DBG_SHIFT;
   input 			  DBG_TDI;
   input 			  DBG_UPDATE;
   output 			  DBG_TDO;
   input 			  DBG_STOP;
   
   // Data PLB interface
   output 			  ICACHE_FSL_IN_CLK;
   output 			  ICACHE_FSL_IN_READ;
   input [0:31] 		  ICACHE_FSL_IN_DATA;
   input 			  ICACHE_FSL_IN_CONTROL;
   input 			  ICACHE_FSL_IN_EXISTS;
   output 			  ICACHE_FSL_OUT_CLK;
   output 			  ICACHE_FSL_OUT_WRITE;
   output [0:31] 		  ICACHE_FSL_OUT_DATA;
   output 			  ICACHE_FSL_OUT_CONTROL;
   input 			  ICACHE_FSL_OUT_FULL;

   output 			  DCACHE_FSL_IN_CLK;
   output 			  DCACHE_FSL_IN_READ;
   input [0:31] 		  DCACHE_FSL_IN_DATA;
   input 			  DCACHE_FSL_IN_CONTROL;
   input 			  DCACHE_FSL_IN_EXISTS;
   output 			  DCACHE_FSL_OUT_CLK;
   output 			  DCACHE_FSL_OUT_WRITE;
   output [0:31] 		  DCACHE_FSL_OUT_DATA;
   output 			  DCACHE_FSL_OUT_CONTROL;
   input 			  DCACHE_FSL_OUT_FULL;
   
   input [0:31] 			dlmb_BRAM_Addr;
   input 				dlmb_BRAM_Clk;
   output [0:31] 			dlmb_BRAM_Din;
   input [0:31] 			dlmb_BRAM_Dout;
   input 				dlmb_BRAM_EN;
   input 				dlmb_BRAM_Rst;
   input [0:3] 				dlmb_BRAM_WEN;

   input [0:31] 			ilmb_BRAM_Addr;
   input 				ilmb_BRAM_Clk;
   output [0:31] 			ilmb_BRAM_Din;
   input [0:31] 			ilmb_BRAM_Dout;
   input 				ilmb_BRAM_EN;
   input 				ilmb_BRAM_Rst;
   input [0:3] 				ilmb_BRAM_WEN;
   
endmodule
