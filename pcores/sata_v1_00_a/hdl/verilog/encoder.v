// encoder.v --- 
// 
// Filename: encoder.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Wed Mar 14 20:18:19 2012 (+0800)
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
// 	internal version of input port    : "*_i"
// 	device pins                        : "*_pin"
// 	ports                              : - Names begin with Uppercase
// Code:
module encoder (/*AUTOARG*/
   // Outputs
   encoder_data, collect_out, trigger_out, dfifo_data, dfifo_valid,
   dfifo_reset,
   // Inputs
   Clk, Rst, Trace_Instruction, Trace_Valid_Instr, Trace_PC,
   Trace_Reg_Write, Trace_Reg_Addr, Trace_MSR_Reg, Trace_PID_Reg,
   Trace_New_Reg_Value, Trace_Exception_Taken, Trace_Exception_Kind,
   Trace_Jump_Taken, Trace_Delay_Slot, Trace_Data_Address,
   Trace_Data_Write_Value, Trace_Data_Byte_Enable, Trace_Data_Access,
   Trace_Data_Read, Trace_Data_Write, Trace_DCache_Req,
   Trace_DCache_Hit, Trace_ICache_Req, Trace_ICache_Hit,
   Trace_OF_PipeRun, Trace_EX_PipeRun, Trace_MEM_PipeRun, MB_started,
   MB_stopped, collect_in, trigger_in, include_data
   );
   parameter C_EXT_RESET_HIGH = 1;
   parameter C_ALWAYS_COLLECT = 1;
   input Clk;
   input Rst;

   input [0:31] Trace_Instruction;
   input 	Trace_Valid_Instr;
   input [0:31] Trace_PC;
   input 	Trace_Reg_Write;
   input [0:4] 	Trace_Reg_Addr;
   input [0:14] Trace_MSR_Reg;
   input [0:7] 	Trace_PID_Reg;
   input [0:31] Trace_New_Reg_Value;
   input 	Trace_Exception_Taken;
   input [0:4] 	Trace_Exception_Kind;
   input 	Trace_Jump_Taken;
   input 	Trace_Delay_Slot;
   input [0:31] Trace_Data_Address;
   input [0:31] Trace_Data_Write_Value;
   input [0:3] 	Trace_Data_Byte_Enable;
   input 	Trace_Data_Access;
   input 	Trace_Data_Read;
   input 	Trace_Data_Write;

   input 	Trace_DCache_Req;
   input 	Trace_DCache_Hit;
   input 	Trace_ICache_Req;
   input 	Trace_ICache_Hit;
   input 	Trace_OF_PipeRun;
   input 	Trace_EX_PipeRun;
   input 	Trace_MEM_PipeRun;
   
   input 	MB_started;
   input 	MB_stopped;

   input 	collect_in;
   input 	trigger_in;
   input 	include_data;

   output [0:17] encoder_data;
   output 	 collect_out;
   output 	 trigger_out;

   output [0:31] dfifo_data;
   output [0:16] dfifo_status;
   output 	 dfifo_valid;
   output 	 dfifo_reset;
endmodule
// 
// encoder.v ends here
