// npi_ict_rd.v --- 
// 
// Filename: npi_ict_rd.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Sat Aug 11 22:05:23 2012 (+0800)
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
module npi_ict_rd (/*AUTOARG*/
   // Outputs
   PIM_RdFIFO_Pop, PIM_RdFIFO_Flush, PIM_RdFIFO_Push,
   PIM_RdFIFO_Push_Data, PIM_RdFIFO_Push_sel, rdsts_afull,
   npi_ict_dbg,
   // Inputs
   Clk, Rst, PIM_RdFIFO_Data, PIM_RdFIFO_RdWdAddr, PIM_RdFIFO_Empty,
   PIM_RdFIFO_Latency, rdsts_wren, rdsts_len, rdsts_nr
   );
   parameter C_PIM_DATA_WIDTH = 64;
   
   input Clk;
   input Rst;
   
   input [C_PIM_DATA_WIDTH-1:0] PIM_RdFIFO_Data;
   output 			PIM_RdFIFO_Pop;
   input [3:0] 			PIM_RdFIFO_RdWdAddr;
   input 			PIM_RdFIFO_Empty;
   output 			PIM_RdFIFO_Flush;
   input [1:0] 			PIM_RdFIFO_Latency;
   
   output 			PIM_RdFIFO_Push;
   output [C_PIM_DATA_WIDTH-1:0] PIM_RdFIFO_Push_Data;
   output [2:0] 		 PIM_RdFIFO_Push_sel;

   output 			 rdsts_afull;
   input 			 rdsts_wren;
   input [5:0] 			 rdsts_len;
   input [2:0] 			 rdsts_nr;

   output [15:0] 		 npi_ict_dbg;
   /***************************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			PIM_RdFIFO_Push;
   reg [C_PIM_DATA_WIDTH-1:0] PIM_RdFIFO_Push_Data;
   reg [2:0]		PIM_RdFIFO_Push_sel;
   // End of automatics

   /***************************************************************************/
   localparam [1:0] // synopsys enum state_info
     S_IDLE = 2'h0,
     S_DATA = 2'h1,
     S_POP  = 2'h2;
   reg [1:0] // synopsys enum state_info
	     state, state_ns;
   always @(posedge Clk)
     begin
	if (Rst)
	  begin
	     state <= #1 S_IDLE;
	  end
	else
	  begin
	     state <= #1 state_ns;
	  end
     end // always @ (posedge Clk)

   wire rdsts_rden;
   wire rdsts_afull;
   wire rdsts_empty;
   reg [5:0] len;
   always @(*)
     begin
	state_ns = state;
	case (state)
	  S_IDLE: if (~rdsts_empty && ~PIM_RdFIFO_Empty)
	    begin
	       state_ns = S_DATA;
	    end
	  S_DATA: if (len == 1 && ~PIM_RdFIFO_Empty)
	    begin
	       state_ns = S_POP;
	    end
	  S_POP:
	    begin
	       state_ns = S_IDLE;
	    end
	endcase
     end // always @ (*)
   assign rdsts_rden = state == S_POP;

   wire [8:0] rdsts_dout;
   always @(posedge Clk)
     begin
	if (state == S_IDLE)
	  begin
	     len <= #1 rdsts_dout[8:3];
	  end
	else if (state == S_DATA && ~PIM_RdFIFO_Empty)
	  begin
	     len <= #1 len - 1'b1;
	  end
     end // always @ (posedge Clk)

   srl16e_fifo_protect
     #(.c_width (9),
       .c_awidth(3),
       .c_depth (8))
   wrfifo (.Clk         (Clk),
	   .Rst         (Rst),
	   .WR_EN       (rdsts_wren),
	   .RD_EN       (rdsts_rden),
	   .DIN         ({rdsts_len, rdsts_nr}),
	   .DOUT        (rdsts_dout),
	   .ALMOST_FULL (rdsts_afull),
	   .EMPTY       (rdsts_empty));

   assign PIM_RdFIFO_Pop = state == S_DATA && ~PIM_RdFIFO_Empty;
   reg [2:0] id_d1;
   reg [2:0] id_d2;
   reg 	     pop_d1;
   reg 	     pop_d2;
   always @(posedge Clk)
     begin
	id_d1 <= #1 rdsts_dout[2:0];
	id_d2 <= #1 id_d1;
	pop_d1<= #1 PIM_RdFIFO_Pop;
	pop_d2<= #1 pop_d1;

	/* TODO: current only support latency is 2 or 1 */
	PIM_RdFIFO_Push_sel <= #1 PIM_RdFIFO_Latency == 2'h2 ? id_d2  : id_d1;
	PIM_RdFIFO_Push     <= #1 PIM_RdFIFO_Latency == 2'h2 ? pop_d2 : pop_d1;
	PIM_RdFIFO_Push_Data<= #1 PIM_RdFIFO_Data;
     end // always @ (posedge Clk)
   assign PIM_RdFIFO_Flush = 1'b0;

   assign npi_ict_dbg[3:0] = state;
   assign npi_ict_dbg[4]   = rdsts_empty;
   assign npi_ict_dbg[5]   = rdsts_rden;
   assign npi_ict_dbg[6]   = rdsts_afull;
   assign npi_ict_dbg[7]   = rdsts_wren;
   assign npi_ict_dbg[15:8]= rdsts_dout;
   /***************************************************************************/
   /*AUTOASCIIENUM("state", "state_ascii", "S_")*/
   // Beginning of automatic ASCII enum decoding
   reg [31:0]		state_ascii;		// Decode of state
   always @(state) begin
      case ({state})
	S_IDLE:   state_ascii = "idle";
	S_DATA:   state_ascii = "data";
	S_POP:    state_ascii = "pop ";
	default:  state_ascii = "%Err";
      endcase
   end
   // End of automatics
endmodule
// 
// npi_ict_rd.v ends here
