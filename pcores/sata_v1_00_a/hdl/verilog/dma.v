// dma.v --- 
// 
// Filename: dma.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Feb 23 17:47:16 2012 (+0800)
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
module dma (/*AUTOARG*/
   // Outputs
   rxfifo_clk, rxfifo_rd_en, txfifo_clk, txfifo_data, txfifo_eof,
   txfifo_sof, txfifo_wr_en, dma_ack, PIM_Addr, PIM_AddrReq, PIM_RNW,
   PIM_Size, PIM_RdModWr, PIM_RdFIFO_Flush, PIM_RdFIFO_Pop,
   PIM_WrFIFO_Data, PIM_WrFIFO_BE, PIM_WrFIFO_Push, PIM_WrFIFO_Flush,
   rxfifo_irq, dma_state,
   // Inputs
   rxfifo_almost_empty, rxfifo_data, rxfifo_empty, rxfifo_eof,
   rxfifo_eof_rdy, rxfifo_fis_hdr, rxfifo_rd_count, rxfifo_sof,
   txfifo_almost_full, txfifo_count, txfifo_eof_poped, dma_address,
   dma_length, dma_pm, dma_data, dma_ok, dma_req, dma_wrt, dma_sync,
   dma_flush, dma_eof, dma_sof, sys_clk, sys_rst, MPMC_Clk,
   PIM_AddrAck, PIM_RdFIFO_RdWdAddr, PIM_RdFIFO_Data,
   PIM_RdFIFO_Empty, PIM_RdFIFO_Latency, PIM_WrFIFO_Empty,
   PIM_WrFIFO_AlmostFull, PIM_InitDone
   );
   input sys_clk;
   input sys_rst;
   
   /*AUTOINOUTCOMP("dcr_if", "^dma_")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		dma_ack;
   input [31:0]		dma_address;
   input [15:0]		dma_length;
   input [3:0]		dma_pm;
   input		dma_data;
   input		dma_ok;
   input		dma_req;
   input		dma_wrt;
   input		dma_sync;
   input		dma_flush;
   input		dma_eof;
   input		dma_sof;
   // End of automatics
   /*AUTOINOUTCOMP("txll", "^txfifo")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		txfifo_clk;
   output [31:0]	txfifo_data;
   output		txfifo_eof;
   output		txfifo_sof;
   output		txfifo_wr_en;
   input		txfifo_almost_full;
   input [9:0]		txfifo_count;
   input		txfifo_eof_poped;
   // End of automatics
   /*AUTOINOUTCOMP("rxll", "^rxfifo")*/
   // Beginning of automatic in/out/inouts (from specific module)
   output		rxfifo_clk;
   output		rxfifo_rd_en;
   input		rxfifo_almost_empty;
   input [31:0]		rxfifo_data;
   input		rxfifo_empty;
   input		rxfifo_eof;
   input		rxfifo_eof_rdy;
   input [11:0]		rxfifo_fis_hdr;
   input [9:0]		rxfifo_rd_count;
   input		rxfifo_sof;
   // End of automatics
   /**********************************************************************/
   input 		MPMC_Clk;
   
   output [31:0] 	PIM_Addr;
   output 		PIM_AddrReq;
   output 		PIM_RNW;
   output [3:0] 	PIM_Size;
   output 		PIM_RdModWr;   
   input 		PIM_AddrAck;
   
   input [3:0] 		PIM_RdFIFO_RdWdAddr;
   input [31:0] 	PIM_RdFIFO_Data;
   output 		PIM_RdFIFO_Flush;
   output 		PIM_RdFIFO_Pop;
   input 		PIM_RdFIFO_Empty;
   input [1:0] 		PIM_RdFIFO_Latency;
   
   output [31:0] 	PIM_WrFIFO_Data;
   output [3:0] 	PIM_WrFIFO_BE;
   output 		PIM_WrFIFO_Push;
   output 		PIM_WrFIFO_Flush;
   input 		PIM_WrFIFO_Empty;
   input 		PIM_WrFIFO_AlmostFull;
   
   input 		PIM_InitDone;
   /**********************************************************************/
   output 		rxfifo_irq;
   output [31:0] 	dma_state;
   /**********************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			PIM_AddrReq;
   reg			PIM_RNW;
   reg [3:0]		PIM_Size;
   reg			rxfifo_irq;
   // End of automatics

   /**********************************************************************/
   // 0:  1 WORD transfer
   // 1:  4 WORD transfer
   // 2:  8 WORD transfer (for Non Data FIS)
   // 3: 16 WORD transfer
   // 4: 32 WORD transfer
   // 5: 64 WORD transfer (for data fis)
   /**********************************************************************/
   localparam [3:0] // synopsys enum state_info
     S_IDLE    = 4'h0,
     S_BUS_REQ = 4'h1,
     S_WRT_REQ = 4'h2,
     S_WRT_DAT = 4'h3,
     S_WRT_ACK = 4'h4,
     S_ADR_REQ = 4'h5,
     S_WAI_DAT = 4'h6,
     S_FLUSH   = 4'h7,
     S_WAIT    = 4'h8,
     S_DONE    = 4'h9;
   reg [3:0] // synopsys enum state_info
	     state, state_ns;
   always @(posedge MPMC_Clk)
     begin
	if (sys_rst)
	  begin
	     state <= #1 S_IDLE;
	  end
	else
	  begin
	     state <= #1 state_ns;
	  end
     end // always @ (posedge MPMC_Clk)
   reg 	     frm_done;
   wire      rd_last;
   wire      rd_rdy;
   reg [6:0] rd_len;   
   wire      wr_rdy;
   wire      wr_ava;
   wire      wr_done;
   reg [6:0] wr_len;
   wire      clk_pi_enable;
   always @(*)
     begin
	state_ns = state;
	case (state)
	  S_IDLE: if (dma_req && dma_flush && clk_pi_enable)
	    begin
	       state_ns = S_FLUSH;
	    end
	  else if (dma_req && clk_pi_enable)
	    begin
	       state_ns = S_BUS_REQ;
	    end
	  S_BUS_REQ: if (dma_wrt)
	    begin
	       state_ns = S_WRT_DAT;
	    end
	  else if (~dma_wrt && ~txfifo_almost_full)
	    begin
	       state_ns = S_ADR_REQ;
	    end
	  S_WRT_DAT: if (wr_len == 1)
	    begin
	       state_ns = S_WRT_REQ;
	    end
	  S_WRT_REQ: if (PIM_AddrAck)
	    begin
	       state_ns = S_WRT_ACK;
	    end
	  S_WRT_ACK: if (frm_done)
	    begin
	       state_ns = S_DONE;
	    end
	  else if (wr_rdy && wr_ava)
	    begin
	       state_ns = S_BUS_REQ;
	    end
	  else if (wr_rdy && ~wr_ava)
	    begin
	       state_ns = S_DONE;
	    end

	  S_ADR_REQ: if (PIM_AddrAck)
	    begin
	       state_ns = S_WAI_DAT;
	    end
	  S_WAI_DAT: if (PIM_RdFIFO_Pop && rd_len == 1)
	    begin
	       state_ns = rd_last ? S_DONE : S_BUS_REQ;
	    end

	  S_DONE: if (~dma_req && clk_pi_enable)
	    begin
	       state_ns = S_IDLE;
	    end

	  S_FLUSH: if (rxfifo_eof)
	    begin
	       state_ns = S_DONE;
	    end
	endcase
     end // always @ (*)
   /**********************************************************************/
   always @(posedge MPMC_Clk)
     begin
	if ((state == S_WRT_REQ || state == S_ADR_REQ) && ~PIM_AddrAck)
	  begin
	     PIM_AddrReq <= #1 1'b1;
	  end
	else
	  begin
	     PIM_AddrReq <= #1 1'b0;
	  end
     end // always @ (posedge MPMC_Clk)
   reg [31:5] m_addr;
   reg [15:5] m_len;
   reg [4:2]  m_low;
   reg [3:0]  m_size;
   always @(posedge MPMC_Clk)
     begin
	if (state == S_IDLE)
	  begin
	     m_addr <= #1 dma_address[31:5];
	     m_len  <= #1 dma_length[15:5];
	     m_low  <= #1 dma_length[4:2];
	  end
	else if (PIM_AddrAck)
	  begin
	     m_addr <= #1 m_addr + m_size;
	     m_len  <= #1 m_len ? m_len - m_size : 0;
	     m_low  <= #1 m_len ? m_low : 0;
	  end
     end // always @ (posedge MPMC_Clk)
   always @(posedge MPMC_Clk)
     begin
	if (rxfifo_rd_en && rxfifo_eof) 
	  begin
	     frm_done <= #1 1'b1;
	  end
	else if (state == S_IDLE)
	  begin
	     frm_done <= #1 1'b0;
	  end
     end // always @ (posedge MPMC_Clk)
   assign wr_rdy          = ~rxfifo_almost_empty | rxfifo_eof_rdy;
   assign wr_ava          = m_len != 0;

   assign PIM_WrFIFO_Push = state == S_WRT_DAT;
   assign rxfifo_clk      = MPMC_Clk;
   assign rxfifo_rd_en    = PIM_WrFIFO_Push || state == S_FLUSH;
   assign PIM_WrFIFO_Data = rxfifo_data;
   assign PIM_WrFIFO_BE   = 4'hf;
   assign PIM_WrFIFO_Flush= 1'b0;
   
   always @(posedge MPMC_Clk)
     begin
	if (state == S_BUS_REQ)
	  begin
	     wr_len  <= #1 m_len == 0 ? 8 :
			   m_len == 1 ? 8 : 64;
	     PIM_Size<= #1 m_len == 0 ? 2 : 
			   m_len == 1 ? 2 : 5;
	     m_size  <= #1 m_len == 0 ? 1 :
			   m_len == 1 ? 1 : 8;
	     PIM_RNW <= #1 ~dma_wrt;
	  end
	else if (state == S_WRT_DAT)
	  begin
	     wr_len  <= #1 wr_len - 1'b1;
	  end
     end // always @ (posedge MPMC_Clk)
   assign PIM_Addr        = {m_addr, 5'h0};
   assign PIM_RdModWr     = 1'b0;
   assign PIM_RdFIFO_Flush= 1'b0;
   /**********************************************************************/
   reg sof;
   reg [15:2] rlen;
   always @(posedge MPMC_Clk)
     begin
	if (state == S_IDLE)
	  begin
	     sof <= #1 dma_sof;
	  end
	else if (txfifo_wr_en)
	  begin
	     sof <= #1 1'b0;
	  end
     end // always @ (posedge MPMC_Clk)
   always @(posedge MPMC_Clk)
     begin
	if (state == S_IDLE)
	  begin
	     rlen <= #1 dma_length[15:2];
	  end
	else if (PIM_RdFIFO_Pop && rlen)
	  begin
	     rlen <= #1 rlen - 1'b1;
	  end
     end // always @ (posedge MPMC_Clk)
   always @(posedge MPMC_Clk)
     begin
	if (state == S_BUS_REQ)
	  begin
	     rd_len <= #1 m_len == 0 ? 8 :
		          m_len == 1 ? 8 : 64;
	  end
	else if (PIM_RdFIFO_Pop)
	  begin
	     rd_len <= #1 rd_len - 1'b1;
	  end
     end // always @ (posedge MPMC_Clk)
   assign PIM_RdFIFO_Pop   = ~PIM_RdFIFO_Empty;
   
   reg pop_d1;
   reg pop_d2;
   reg eof_d1;
   reg eof_d2;
   always @(posedge MPMC_Clk)
     begin
	pop_d1 <= #1 PIM_RdFIFO_Pop && rlen;
	pop_d2 <= #1 pop_d1;
	eof_d1 <= #1 rlen == 1 && dma_eof;
	eof_d2 <= #1 eof_d1;
     end
   
   assign txfifo_wr_en = pop_d2 | (state == S_BUS_REQ && dma_data && sof);
   assign txfifo_sof   = sof;
   assign txfifo_eof   = eof_d2;
   assign txfifo_data  = sof & dma_data ? {dma_pm, 8'h46} : PIM_RdFIFO_Data;
   assign txfifo_clk   = MPMC_Clk;
   
   assign rd_last      = m_len == 0 && m_low == 0;
   /**********************************************************************/   
   // MPMC_Clk -> sysclk
   assign dma_ack      = state == S_DONE && clk_pi_enable;
   always @(posedge sys_clk)
     begin
	rxfifo_irq <= #1 ~dma_req && ~rxfifo_empty;
     end
   /************************************************************************/
   mpmc_sample_cycle sample_cycle(.sample_cycle(clk_pi_enable),
				  .fast_clk(MPMC_Clk),
				  .slow_clk(sys_clk));
   assign dma_state[3:0]   = state;
   assign dma_state[4]     = PIM_WrFIFO_Empty;
   assign dma_state[5]     = dma_req;
   assign dma_state[6]     = dma_wrt;
   assign dma_state[7]     = frm_done;
   assign dma_state[8]     = wr_rdy;
   assign dma_state[9]     = wr_ava;
   assign dma_state[10]    = rd_last;
   assign dma_state[23:16] = rd_len;
   assign dma_state[31:24] = wr_len;
   /************************************************************************/   
   /*AUTOASCIIENUM("state", "state_ascii", "S_")*/
   // Beginning of automatic ASCII enum decoding
   reg [55:0]		state_ascii;		// Decode of state
   always @(state) begin
      case ({state})
	S_IDLE:    state_ascii = "idle   ";
	S_BUS_REQ: state_ascii = "bureq  ";
	S_WRT_REQ: state_ascii = "wrt_req";
	S_WRT_DAT: state_ascii = "wrt_dat";
	S_WRT_ACK: state_ascii = "wrt_ack";
	S_ADR_REQ: state_ascii = "adr_req";
	S_WAI_DAT: state_ascii = "wai_dat";
	S_FLUSH:   state_ascii = "flush  ";
	S_WAIT:    state_ascii = "wait   ";
	S_DONE:    state_ascii = "done   ";
	default:   state_ascii = "%Error ";
      endcase
   end
   // End of automatics
endmodule
// 
// dma.v ends here
