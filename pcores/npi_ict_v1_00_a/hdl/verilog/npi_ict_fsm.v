// npi_ict_fsm.v --- 
// 
// Filename: npi_ict_fsm.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Sat Aug 11 19:12:16 2012 (+0800)
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
module npi_ict_fsm (/*AUTOARG*/
   // Outputs
   ReqPop, ReqWrBeRst, ReqWrPop, upd_last_master, current_master,
   PIM_Addr, PIM_AddrReq, PIM_RNW, PIM_Size, PIM_RdModWr,
   PIM_WrFIFO_Data, PIM_WrFIFO_BE, PIM_WrFIFO_Push, PIM_WrFIFO_Flush,
   rdsts_nr, rdsts_len, rdsts_wren, npi_ict_state,
   // Inputs
   Clk, Rst, ReqRNW, ReqSize, ReqId, ReqAddr, ReqEmpty, ReqWrEmpty,
   ReqWrData, ReqWrBE, ReqGrant, ReqPending, ReqGrant_nr, PIM_AddrAck,
   PIM_WrFIFO_Empty, PIM_WrFIFO_AlmostFull, PIM_InitDone, rdsts_afull
   );
   parameter C_NUM_PORTS = 4;
   parameter C_PIX_ADDR_WIDTH_MAX = 32;
   parameter C_MEM_DATA_WIDTH = 64;
   parameter C_MEM_BE_WIDTH = C_MEM_DATA_WIDTH/8;
   parameter C_PIM_DATA_WIDTH = 64;
   
   input Clk;
   input Rst;
   
   input [C_NUM_PORTS-1:0] ReqRNW;
   input [C_NUM_PORTS*4-1:0] ReqSize;
   input [C_NUM_PORTS*3-1:0] ReqId;
   input [C_NUM_PORTS*C_PIX_ADDR_WIDTH_MAX-1:0] ReqAddr;
   input [C_NUM_PORTS-1:0] 			ReqEmpty;
   output [C_NUM_PORTS-1:0] 			ReqPop;
   
   output [C_NUM_PORTS-1:0] 			ReqWrBeRst;
   output [C_NUM_PORTS-1:0] 			ReqWrPop;
   input [C_NUM_PORTS-1:0] 			ReqWrEmpty;
   input [C_NUM_PORTS*C_MEM_DATA_WIDTH-1:0] 	ReqWrData;
   input [C_NUM_PORTS*C_MEM_BE_WIDTH-1:0] 	ReqWrBE;

   input [C_NUM_PORTS-1:0] 			ReqGrant;
   input [C_NUM_PORTS-1:0] 			ReqPending;
   input [2:0] 					ReqGrant_nr;
   output 					upd_last_master;
   output [C_NUM_PORTS-1:0] 			current_master;

   output [31:0] 				PIM_Addr;
   output 					PIM_AddrReq;
   input 					PIM_AddrAck;
   output 					PIM_RNW;
   output [3:0] 				PIM_Size;
   output 					PIM_RdModWr;
   
   output [C_PIM_DATA_WIDTH-1:0] 		PIM_WrFIFO_Data;
   output [(C_PIM_DATA_WIDTH/8)-1:0] 		PIM_WrFIFO_BE;
   output 					PIM_WrFIFO_Push;
   output 					PIM_WrFIFO_Flush;
   input 					PIM_WrFIFO_Empty;
   input 					PIM_WrFIFO_AlmostFull;
   
   input 					PIM_InitDone;

   output [2:0] 				rdsts_nr;
   output [5:0] 				rdsts_len;
   output 					rdsts_wren;
   input 					rdsts_afull;

   output [31:0] 				npi_ict_state;
   /***************************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [31:0]		PIM_Addr;
   reg			PIM_AddrReq;
   reg			PIM_RNW;
   reg			PIM_RdModWr;
   reg [3:0]		PIM_Size;
   reg [(C_PIM_DATA_WIDTH/8)-1:0] PIM_WrFIFO_BE;
   reg [C_PIM_DATA_WIDTH-1:0] PIM_WrFIFO_Data;
   reg			PIM_WrFIFO_Push;
   reg [C_NUM_PORTS-1:0] ReqPop;
   reg [C_NUM_PORTS-1:0] ReqWrBeRst;
   reg [C_NUM_PORTS-1:0] current_master;
   reg [5:0]		rdsts_len;
   reg [2:0]		rdsts_nr;
   reg			rdsts_wren;
   reg			upd_last_master;
   // End of automatics

   /***************************************************************************/
   localparam [2:0] // synopsys enum state_info
     S_IDLE    = 3'h0,
     S_WDATA   = 3'h1,
     S_WAIT    = 3'h2,
     S_WAIT_S1 = 3'h3,
     S_ADDR    = 3'h4,
     S_WAIT_S0 = 3'h5,
     S_DONE    = 3'h6;
   reg [2:0] // synopsys enum state_info
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
   // 0: Byte, Half-word, word  4   byte,  (1  BC)
   // 1: 4word                  16  byte,  (2  BC)
   // 2: 8word                  32  byte,  (4  BC)
   // 3: 16word                 64  byte,  (8  BC)
   // 4: 32word                 128 byte,  (16 BC)
   // 5: 64word                 256 byte,  (32 BC)
   wire [31:0] Addr;
   wire [3:0]  Size;
   wire [2:0]  Id;
   wire        RNW;
   wire [63:0] WrData;
   wire [7:0]  WrBE;
   wire        WrEmpty;

   reg [4:0]   write_burst;
   wire        write_ready;
   wire        wrfifo_empty;
   reg 	       write_valid;
   reg 	       PIM_WrFIFO_Empty_r;
   always @(*)
     begin
	state_ns = state;
	case (state)
	  S_IDLE: if (|(ReqGrant & ReqPending) && ~RNW)
	    begin
	       state_ns = S_WDATA;
	    end
	  else if (|(ReqGrant & ReqPending) && RNW && ~rdsts_afull)
	    begin
	       state_ns = S_ADDR;
	    end
	  S_WDATA: if (write_burst == 1 && write_ready)
	    begin
	       state_ns = PIM_Size == 0 ? S_WAIT : S_WAIT_S1;
	    end
	  S_WAIT: if (~wrfifo_empty)
	    begin
	       state_ns = S_ADDR;
	    end
	  S_WAIT_S1: if (~write_valid)
	    begin
	       state_ns = S_ADDR;
	    end
	  S_ADDR: if (PIM_AddrAck)
	    begin
	       state_ns = PIM_Size == 0 ? S_WAIT_S0 : S_DONE;
	    end
	  S_WAIT_S0: if (PIM_WrFIFO_Empty && PIM_WrFIFO_Empty_r)
	    begin
	       state_ns = S_IDLE;
	    end
	  S_DONE:
	    begin
	       state_ns = S_IDLE;
	    end
	endcase
     end // always @ (*)
   mpmc_srl_fifo_nto1_mux #(.C_RATIO(C_NUM_PORTS),
			    .C_SEL_WIDTH(3),
			    .C_DATAOUT_WIDTH(1))
   RNW_mux (.Sel(ReqGrant_nr),
	    .In(ReqRNW),
	    .Out(RNW));
   mpmc_srl_fifo_nto1_mux #(.C_RATIO(C_NUM_PORTS),
			    .C_SEL_WIDTH(3),
			    .C_DATAOUT_WIDTH(4))
   Size_mux (.Sel(ReqGrant_nr),
	     .In(ReqSize),
	     .Out(Size));
   mpmc_srl_fifo_nto1_mux #(.C_RATIO(C_NUM_PORTS),
			    .C_SEL_WIDTH(3),
			    .C_DATAOUT_WIDTH(32))
   Addr_mux (.Sel(ReqGrant_nr),
	     .In(ReqAddr),
	     .Out(Addr));
   /***************************************************************************/
   wire [5:0] burstlen;
   assign burstlen = Size == 4'h0 ? 6'h1  :
		     Size == 4'h1 ? 6'h2  :
		     Size == 4'h2 ? 6'h4  :
		     Size == 4'h3 ? 6'h8  :
		     Size == 4'h4 ? 6'h10 :
		     Size == 4'h5 ? 6'h20 : 6'hx;
   /***************************************************************************/
   always @(posedge Clk)
     begin
	if (state == S_ADDR && ~PIM_AddrAck)
	  begin
	     PIM_AddrReq <= #1 1'b1;
	  end
	else
	  begin
	     PIM_AddrReq <= #1 1'b0;
	  end
     end // always @ (posedge Clk)
   always @(posedge Clk)
     begin
	if (state == S_IDLE)
	  begin
	     PIM_Addr   <= #1 Addr;
	     PIM_Size   <= #1 Size;
	     PIM_RNW    <= #1 RNW;
	     PIM_RdModWr<= #1 0;
	  end
     end
   /***************************************************************************/
   wire write_pop;
   wire wrfifo_afull;
   
   reg [4:0] write_grant;
   reg [3:0] write_size;
   reg [2:0] write_nr;
   
   mpmc_srl_fifo_nto1_mux #(.C_RATIO(C_NUM_PORTS),
			    .C_SEL_WIDTH(3),
			    .C_DATAOUT_WIDTH(64))
   WrData_mux (.Sel(write_nr[2:0]),
	       .In(ReqWrData),
	       .Out(WrData));
   mpmc_srl_fifo_nto1_mux #(.C_RATIO(C_NUM_PORTS),
			    .C_SEL_WIDTH(3),
			    .C_DATAOUT_WIDTH(8))
   WrBE_mux (.Sel(write_nr[2:0]),
	     .In(ReqWrBE),
	     .Out(WrBE));

   always @(posedge Clk)
     begin
	if (state == S_IDLE)
	  begin
	     write_burst <= #1 burstlen;
	     write_size  <= #1 Size;
	  end
	else if (write_pop)
	  begin
	     write_burst <= #1 write_burst - 1'b1;
	  end
     end // always @ (posedge Clk)
   
   assign ReqWrPop  = write_pop ? write_grant : 0;
   assign write_pop = write_ready && (state == S_WDATA);
   
   always @(posedge Clk)
     begin
	if (state == S_IDLE)
	  begin
	     write_grant <= #1 ReqGrant;
	     write_nr    <= #1 ReqGrant_nr;
	  end
     end

   reg 	       write_pop_d1;
   always @(posedge Clk)
     begin
	write_pop_d1 <= #1 write_pop;
	write_valid  <= #1 write_pop_d1;
     end

   wire wrfifo_rden;
   wire [63:0] wrfifo_data;
   wire [7:0]  wrfifo_be;
   srl16e_fifo_protect
     #(.c_width (72),
       .c_awidth(3),
       .c_depth (8))
   wrfifo (.Clk         (Clk),
	   .Rst         (Rst),
	   .WR_EN       (write_valid),
	   .RD_EN       (wrfifo_rden),
	   .DIN         ({WrBE, WrData}),
	   .DOUT        ({wrfifo_be, wrfifo_data}),
	   .ALMOST_FULL (wrfifo_afull),
	   .EMPTY       (wrfifo_empty));
   
   assign wrfifo_rden = ~wrfifo_empty && ((write_size == 0 && state == S_ADDR && PIM_AddrAck) ||
					  (write_size != 0));
   assign write_ready = ~wrfifo_afull;

   always @(posedge Clk)
     begin
	PIM_WrFIFO_Push <= #1 wrfifo_rden;
	PIM_WrFIFO_Data <= #1 wrfifo_data;
	PIM_WrFIFO_BE   <= #1 wrfifo_be;
	PIM_WrFIFO_Empty_r <= #1 PIM_WrFIFO_Empty;
     end
   
   always @(posedge Clk)
     begin
	if (state == S_ADDR && PIM_AddrAck)
	  begin
	     ReqPop <= #1 write_grant;
	  end
	else
	  begin
	     ReqPop <= #1 0;
	  end
     end // always @ (posedge Clk)
   always @(posedge Clk)
     begin
	upd_last_master <= #1 state == S_ADDR && PIM_AddrAck;
	current_master  <= #1 write_grant;
	ReqWrBeRst      <= #1 0;
     end
   assign PIM_WrFIFO_Flush = 1'b0;
   /***************************************************************************/
   always @(posedge Clk)
     begin
	if (state == S_IDLE)
	  begin
	     rdsts_nr <= #1 ReqGrant_nr;
	     rdsts_len<= #1 burstlen;
	  end
	rdsts_wren <= #1 state == S_ADDR && PIM_AddrAck && PIM_RNW;
     end

   assign npi_ict_state[3:0]   = state;
   assign npi_ict_state[4]     = |(ReqGrant & ReqPending);
   assign npi_ict_state[5]     = RNW;
   assign npi_ict_state[6]     = PIM_WrFIFO_Empty;
   assign npi_ict_state[7]     = rdsts_afull;
   assign npi_ict_state[15:8]  = ReqPending;
   assign npi_ict_state[23:16] = ReqGrant;
   assign npi_ict_state[31:24] = write_grant;
   /***************************************************************************/
   /*AUTOASCIIENUM("state", "state_ascii", "S_")*/
   // Beginning of automatic ASCII enum decoding
   reg [55:0]		state_ascii;		// Decode of state
   always @(state) begin
      case ({state})
	S_IDLE:    state_ascii = "idle   ";
	S_WDATA:   state_ascii = "wdata  ";
	S_WAIT:    state_ascii = "wait   ";
	S_WAIT_S1: state_ascii = "wait_s1";
	S_ADDR:    state_ascii = "addr   ";
	S_WAIT_S0: state_ascii = "wait_s0";
	S_DONE:    state_ascii = "done   ";
	default:   state_ascii = "%Error ";
      endcase
   end
   // End of automatics
endmodule
// 
// npi_ict_fsm.v ends here
