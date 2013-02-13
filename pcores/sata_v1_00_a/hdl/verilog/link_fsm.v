// link_fsm.v --- 
// 
// Filename: link_fsm.v
// Description: 
// Author: Hu Gang, songjun, qiancheng
// Maintainer: 
// Created: Thu Aug 12 18:34:53 2010 (+0800)
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
//  DMA context (PM):
//    SATA2.6 16.3.3.7 Reducing Context Switching Complexity
//    AHCI1.3 9.35 Data FIS transfers to the device - locking the interface
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
module link_fsm(/*AUTOARG*/
   // Outputs
   link2cs_char, link2cs_chark, trn_tfifo_rst, ll2cs_sof, ll2cs_eof,
   ll2cs_datav, trn_csrc_rdy_n, trn_csrc_dsc_n, trn_cd, trn_csof_n,
   trn_ceof_n, trn_tdst_dsc_n, state_idle, lfsm_state, link_fsm2dbg,
   tx_sync,
   // Inputs
   clk_75m, host_rst, link_up, rxdata, rxdatak, txdata, txdatak,
   txdatak_pop, cs2link_crc_ok, cs2link_crc_rdy, cs2link_char,
   cs2link_kchar, rd_sof, rd_eof, rd_empty, rd_almost_empty,
   trn_cdst_rdy_n, trn_cdst_dsc_n, trn_rsof_n, trn_reof_n, trn_rd,
   trn_rsrc_rdy_n, trn_rsrc_dsc_n, trn_rdst_rdy_n, trn_rdst_dsc_n,
   trn_tsof_n, trn_teof_n, trn_td, trn_tsrc_rdy_n, trn_tsrc_dsc_n,
   trn_tdst_rdy_n
   );
`include "sata_define.v"

   //system signal
   input         clk_75m;
   input         host_rst;
   input         link_up;

   input [31:0]  rxdata;
   input         rxdatak;
   input [31:0]  txdata;
   input         txdatak;
   input 	 txdatak_pop;
   
   input 	 cs2link_crc_ok;
   input 	 cs2link_crc_rdy;
   input [31:0]  cs2link_char;
   input         cs2link_kchar;
   output [31:0] link2cs_char;
   output        link2cs_chark;
   output        trn_tfifo_rst;

   wire          phy2link_rdy;
   assign        phy2link_rdy = 1'b1; /* TODO */

   output 	 ll2cs_sof;
   output 	 ll2cs_eof;
   output 	 ll2cs_datav;

   input 	 rd_sof;
   input 	 rd_eof;
   input 	 rd_empty;
   input 	 rd_almost_empty;
   
   input         trn_cdst_rdy_n;
   input         trn_cdst_dsc_n;
   output        trn_csrc_rdy_n;
   output        trn_csrc_dsc_n;
   output [31:0] trn_cd;
   output        trn_csof_n;
   output        trn_ceof_n;

   input         trn_rsof_n;
   input         trn_reof_n;
   input [31:0]  trn_rd;
   input 	 trn_rsrc_rdy_n;
   input 	 trn_rsrc_dsc_n;
   input 	 trn_rdst_rdy_n;
   input 	 trn_rdst_dsc_n;
   
   input 	 trn_tsof_n;
   input 	 trn_teof_n;
   input [31:0]  trn_td;
   input 	 trn_tsrc_rdy_n;
   input 	 trn_tsrc_dsc_n;
   input 	 trn_tdst_rdy_n;   
   output 	 trn_tdst_dsc_n;   

   output        state_idle;
   output [7:0]  lfsm_state;
   output        tx_sync;
   /**************************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [31:0]		link2cs_char;
   reg			link2cs_chark;
   reg [31:0]		trn_cd;
   reg			trn_ceof_n;
   reg			trn_csof_n;
   reg			trn_csrc_dsc_n;
   reg			trn_csrc_rdy_n;
   reg			trn_tdst_dsc_n;
   reg			trn_tfifo_rst;
   // End of automatics
   /*********************************************************/
   wire          trn_rd_rdy;
   wire          trn_rd_rdy1;
   wire          trn_rd_rdy2;
   assign        trn_rd_rdy1= (rd_empty | rd_almost_empty) && rd_eof;
   assign        trn_rd_rdy2= ~(rd_empty | rd_almost_empty) && ~rd_eof;
   assign        trn_rd_rdy = trn_rd_rdy1 || trn_rd_rdy2;
   localparam [4:0]       // synopsys enum state_info
     S_IDLE               = 5'h00,
     S_H_SENDCHKRDY       = 5'h01,
     S_L_SENDSOF          = 5'h02,
     S_L_SENDDATA         = 5'h03, 
     S_L_RCVRHOLD         = 5'h04, 
     S_L_SENDHOLD         = 5'h05,
     S_L_SENDCRC          = 5'h06,
     S_L_SENDEOF          = 5'h07,
     S_L_WAIT             = 5'h08,
     S_L_SYNCESCAPE       = 5'h09,
     S_L_RCVWAITFIFO      = 5'h0a,
     S_L_RCVCHKRDY        = 5'h0b,
     S_L_RCVDATA          = 5'h0c,
     S_L_HOLD             = 5'h0d,
     S_L_RCVHOLD          = 5'h0e,
     S_L_RCVEOF           = 5'h0f,
     S_L_GOODCRC          = 5'h10,
     S_L_GOODEND          = 5'h11,
     S_L_BADEND           = 5'h12,
     S_PM_DENY            = 5'h13,
     S_L_NoCommErr        = 5'h14,
     S_L_NoComm           = 5'h15,
     S_L_SendAlign        = 5'h16,
     S_L_SEND_RCV         = 5'h18, // receive P_X_RDY unassert trn_tdst_rdy_n
     S_L_SEND_SYNC        = 5'h19, // receive P_SYNC, assert   trn_tdst_dsc_n 
     S_L_SEND_RERR        = 5'h1a, // receive P_RERR, 
     S_L_SEND_ROK         = 5'h1b, // receive P_ROK
     S_L_RCV_SYNC         = 5'h1c, // receive P_SYNC
     S_L_RCV_GOOD         = 5'h1d, // receive CRC GOOD
     S_L_RCV_BAD          = 5'h1e, // receive CRC BAD
     S_L_RCV_ABORT        = 5'h1f; // received side abort, must clear the fifo, then assert trn_tdst_rdy_n
   reg [4:0]             // synopsys enum state_info
			 state, next_state;
   always @(posedge clk_75m)
     begin
	if (host_rst || ~link_up)
	  begin
	     state <= S_IDLE;
	  end
	else
	  begin
	     state <= next_state; 
	  end
     end
   
   always @(*)
     begin
	next_state  = state;
	case (state)
          S_IDLE: 
            begin
               if (rd_sof && ~rd_empty && // L1:1a
		   phy2link_rdy)
		 begin
                    next_state = S_H_SENDCHKRDY;
		 end
	       else if (cs2link_kchar && cs2link_char == P_X_RDY && 
			phy2link_rdy)
		 begin		// L1:4
		    next_state = S_L_RCVWAITFIFO;
		 end	
               else if ((cs2link_char == P_PMREQ_P && cs2link_kchar) | // L1:5
			(cs2link_char == P_PMREQ_S && cs2link_kchar))
		 begin
		    next_state = S_PM_DENY;
		 end
	       else if (~phy2link_rdy) // L1:8
		 begin
		    next_state = S_L_NoCommErr;
		 end
            end // case: S_IDLE
          S_L_SYNCESCAPE:
            begin
	       if (cs2link_kchar &&
		   (cs2link_char == P_SYNC |
		    cs2link_char == P_X_RDY))
		 begin		// L2:2
                    next_state = S_IDLE;
                 end
	       else if (~phy2link_rdy)
		 begin		// L2:3
		    next_state = S_L_NoCommErr;
		 end
	    end
	  S_L_NoCommErr:
	    begin
	       next_state = S_L_NoComm;
	    end
	  S_L_NoComm:
	    begin
	       if (~phy2link_rdy)
		 begin
		    next_state = S_L_NoComm;
		 end
	       else
		 begin
		    next_state = S_L_SendAlign;
		 end
	    end // case: S_L_NoComm
	  S_L_SendAlign:
	    begin
	       if (~phy2link_rdy)
		 begin
		    next_state = S_L_NoCommErr;
		 end
	       else
		 begin
		    next_state = S_IDLE;
		 end
	    end
          S_PM_DENY:
            begin
               if (cs2link_kchar && 
		   (cs2link_char != P_PMREQ_P ||
		    cs2link_char != P_PMREQ_S))
		 begin
                    next_state = S_IDLE;
		 end	
            end
          S_H_SENDCHKRDY:
            begin
               if (cs2link_kchar && cs2link_char == P_R_RDY &&
		   phy2link_rdy && 
		   ~rd_empty &&
	           rd_sof)
		 begin		// LT2:1
                    next_state = S_L_SENDSOF;
		 end	
               else if (cs2link_kchar && cs2link_char == P_X_RDY &&
			phy2link_rdy)
		 begin		// LT2:2
		    next_state = S_L_SEND_RCV;
		 end
	       else if (~phy2link_rdy)
		 begin		// LT2:3
		    next_state = S_L_NoCommErr;
		 end
            end // case: S_H_SENDCHKRDY
	  S_L_SEND_RCV:
	    begin
	       if (trn_cdst_rdy_n == 1'b0)
		 begin
	            next_state = S_L_RCVWAITFIFO;
		 end
	    end
          S_L_SENDSOF:
            begin
	       if (~phy2link_rdy)
		 begin		// LT3:2
		    next_state = S_L_NoCommErr;
		 end
               else if (cs2link_kchar && cs2link_char == P_SYNC)
		 begin		// LT3:3
                    next_state = S_L_SEND_SYNC;
                 end
	       else if (phy2link_rdy && 
			~rd_empty &&
			rd_sof &&
			txdatak_pop)
		 begin		// LT3:1
		    next_state = S_L_SENDDATA;
		 end
	    end // case: S_L_SENDSOF
          S_L_SENDDATA:
            begin
               if (trn_rd_rdy2 &&
		   cs2link_kchar && cs2link_char == P_HOLD)
		 begin		// LT4:2
                    next_state = S_L_RCVRHOLD;
                 end
	       else if ((rd_empty | rd_almost_empty) &&
		        ~rd_eof &&
			cs2link_kchar && cs2link_char != P_SYNC)
		 begin		// LT4:3
		    next_state = S_L_SENDHOLD;
		 end
	       else if (~rd_empty &&
			rd_eof &&
			cs2link_kchar && cs2link_char != P_SYNC)
		 begin
		    next_state = S_L_SENDCRC;
		 end
               else if (cs2link_kchar && cs2link_char == P_SYNC)
		 begin		// LT4:5
                    next_state = S_L_SEND_SYNC;
                 end
	       else if (~phy2link_rdy)
		 begin		// LT4:6
		    next_state = S_L_NoCommErr;
		 end
               else if (trn_tsrc_dsc_n == 1'b0)
		 begin		// LT4:7
                    next_state = S_L_SYNCESCAPE;
                 end
            end
          S_L_RCVRHOLD:
            begin
	       if (trn_rd_rdy &&
		   (cs2link_kchar &&
		    ~(cs2link_char == P_HOLD ||
		      cs2link_char == P_SYNC)) &&
		   phy2link_rdy)
		 begin		// LT5:1
		    next_state = S_L_SENDDATA;
		 end
	       else if (~rd_empty &&
			cs2link_kchar && cs2link_char == P_HOLD)
		 begin		// LT5:2
                    next_state = S_L_RCVRHOLD;
                 end
               else if (~rd_empty &&
			cs2link_kchar && cs2link_char == P_SYNC)
		 begin		// LT5:3
                    next_state = S_L_SEND_SYNC;
                 end
	       else if (~phy2link_rdy)
		 begin		// LT5:5
		    next_state = S_L_NoCommErr;
		 end
               else if (trn_tsrc_dsc_n == 1'b0)
		 begin		// LT5:6
                    next_state = S_L_SYNCESCAPE;
                 end
	       else if (cs2link_kchar && cs2link_char == P_SYNC)
		 begin		// LT5:7
		    next_state = S_L_SEND_SYNC;
		 end
            end // case: S_L_RCVRHOLD
	  S_L_SEND_SYNC:
	    begin
	       if (trn_cdst_rdy_n == 1'b0) 
		 begin
	            next_state = S_IDLE;
		 end
	    end
          S_L_SENDHOLD:
            begin
	       if (trn_rd_rdy &&
		   cs2link_kchar &&
		   ~(cs2link_char == P_HOLD ||
		     cs2link_char == P_SYNC) &&
		   txdatak_pop)
		 begin		// LT6:1
		    next_state = S_L_SENDDATA;
		 end
               else if (~rd_empty &&
			cs2link_kchar && cs2link_char == P_HOLD)
		 begin		// LT6:2
                    next_state = S_L_RCVRHOLD;
                 end
               else if (cs2link_kchar && cs2link_char == P_SYNC)
		 begin		// LT6:5
                    next_state = S_L_SEND_SYNC;
                 end
	       else if (~phy2link_rdy)
		 begin		// LT6:6
		    next_state = S_L_NoCommErr;
		 end
               else if (trn_tsrc_dsc_n == 1'b0)
		 begin		// LT6:7
                    next_state = S_L_SYNCESCAPE;
                 end
            end
          S_L_SENDCRC:
            begin
               if (phy2link_rdy &&
		   cs2link_kchar && cs2link_char != P_SYNC &&
		   txdatak_pop)
		 begin		// LT7:1
		    next_state = S_L_SENDEOF;
		 end
	       else if (~phy2link_rdy)
		 begin		// LT7:2
		    next_state = S_L_NoCommErr;
		 end
	       else if (phy2link_rdy &&
			cs2link_kchar && cs2link_char == P_SYNC)
		 begin		// LT7:3
                    next_state = S_L_SEND_SYNC;
                 end
            end
          S_L_SENDEOF:
            begin
	       if (phy2link_rdy &&
		   cs2link_kchar && cs2link_char != P_SYNC &&
		   txdatak_pop)
		 begin		// LT8:1
		    next_state = S_L_WAIT;
		 end		
	       else if (~phy2link_rdy)
		 begin		// LT8:2
		    next_state = S_L_NoCommErr;
		 end
	       else if (phy2link_rdy &&
			cs2link_kchar & cs2link_char == P_SYNC)
		 begin		// LT8:3
                    next_state = S_L_SEND_SYNC;
                 end
            end
          S_L_WAIT:
            begin
               if (cs2link_kchar && cs2link_char == P_R_OK)
		 begin		// LT9:1
                    next_state = S_L_SEND_ROK;
                 end
               else if (cs2link_kchar && cs2link_char == P_R_ERR)
		 begin		// LT9:2
                    next_state = S_L_SEND_RERR;
                 end
               else if (cs2link_kchar && cs2link_char == P_SYNC)
		 begin		// LT9:3
                    next_state = S_L_SEND_SYNC;
                 end
	       else if (~phy2link_rdy)
		 begin		// LT9:5
		    next_state = S_L_NoCommErr;
		 end
            end // case: S_L_WAIT
	  S_L_SEND_RERR:
	    begin
	       if (trn_cdst_rdy_n == 1'b0)
		 begin
		    next_state = S_IDLE;
		 end
	    end
	  S_L_SEND_ROK:
	    begin
	       if (trn_cdst_rdy_n == 1'b0)
		 begin
		    next_state = S_IDLE;
		 end
	    end
          S_L_RCVWAITFIFO:
            begin
               if (cs2link_kchar && cs2link_char == P_X_RDY &&
		   trn_rdst_rdy_n == 1'b0)
		 begin		// LR2:1
                    next_state = S_L_RCVCHKRDY;
                 end
	       else if (cs2link_kchar && cs2link_char == P_X_RDY &&
			trn_rdst_rdy_n == 1'b1)
		 begin		// LR2:2
                    next_state = S_L_RCVWAITFIFO;
                 end
               else if (cs2link_kchar && cs2link_char != P_X_RDY)
		 begin		// LR2:3
                    next_state = S_IDLE;
                 end
	       else if (~phy2link_rdy)
		 begin		// LR2:4
		    next_state = S_L_NoCommErr;
		 end
            end
          S_L_RCVCHKRDY:
            begin
	       if (cs2link_char == P_X_RDY && cs2link_kchar) 
		 begin		// LR1:1
                    next_state = S_L_RCVCHKRDY;
                 end
	       else if (cs2link_char == P_SOF && cs2link_kchar)
		 begin		// LR1:2
		    next_state = S_L_RCVDATA;
		 end
	       else if (cs2link_kchar && 
			(cs2link_char != P_SOF ||
			 cs2link_char != P_X_RDY))
		 begin		// LR1:3
                    next_state = S_IDLE;
                 end
	       else if (~phy2link_rdy)
		 begin		// LR1:4
		    next_state = S_L_NoCommErr;
		 end
            end // case: S_L_RCVCHKRDY
          S_L_RCVDATA:
            begin
	       if (cs2link_char == P_HOLDA && cs2link_kchar)
		 begin		// LR3:1
		    next_state = S_L_RCVDATA;
		 end
               else if (cs2link_char == P_EOF && cs2link_kchar)
		 begin		// LR3:4
                    next_state = S_L_RCVEOF;
                 end
               else if (trn_rdst_rdy_n == 1'b1)
		 begin		// LR3:2
                    next_state = S_L_HOLD;
                 end
               else if (cs2link_char == P_HOLD && cs2link_kchar)
		 begin		// LR3:3
                    next_state = S_L_RCVHOLD;
                 end
               else if (cs2link_char == P_WTRM && cs2link_kchar)
		 begin		// LR3:5
                    next_state = S_L_BADEND;
                 end
               else if (cs2link_char == P_SYNC && cs2link_kchar)
		 begin		// LR3:6
                    next_state = S_L_RCV_SYNC; 
                 end
	       else if (~phy2link_rdy)
		 begin		// LR3:8
		    next_state = S_L_NoCommErr;
		 end
               else if (trn_rdst_dsc_n == 1'b0)
		 begin		// LR3:9
                    next_state = S_L_RCV_ABORT;
                 end
            end // case: S_L_RCVDATA
          S_L_HOLD:
            begin
               if (trn_rdst_rdy_n == 1'b0 &&
		   cs2link_char == P_HOLD && cs2link_kchar)
		 begin		// LR4:2
                    next_state = S_L_RCVHOLD;
                 end
	       else if (cs2link_char == P_EOF && cs2link_kchar)
		 begin		// LR4:3
                    next_state = S_L_RCVEOF;
                 end
	       else if (~phy2link_rdy)
		 begin		// LR4:5
		    next_state = S_L_NoCommErr;
		 end
               else if (cs2link_char == P_SYNC && cs2link_kchar)
		 begin		// LR4:6
                    next_state = S_L_RCV_SYNC;
                 end
               else if (trn_rdst_dsc_n == 1'b0)
		 begin		// LR4:7
                    next_state = S_L_RCV_ABORT;
                 end
               else if (trn_rdst_rdy_n == 1'b0)
		 begin		// LR4:1
                    next_state = S_L_RCVDATA;
                 end
            end
          S_L_RCVHOLD:
            begin
	       if (cs2link_char == P_HOLD && cs2link_kchar)
		 begin		// LR5:2
		    next_state = S_L_RCVHOLD;
		 end
	       else if (cs2link_char == P_EOF && cs2link_kchar)
		 begin		// LR5:3
                    next_state = S_L_RCVEOF;
                 end
               else if (cs2link_char == P_SYNC && cs2link_kchar)
		 begin		// LR5:4
                    next_state = S_L_RCV_SYNC;
                 end
	       else if (~phy2link_rdy)
		 begin		// LR5:5
		    next_state = S_L_NoCommErr;
		 end
               else if (trn_rdst_dsc_n == 1'b0)
		 begin		// LR5:6
                    next_state = S_IDLE;
                 end
	       else             // LR5:1
		 begin
		    next_state = S_L_RCVDATA;
		 end
            end // case: S_L_RCVHOLD
          S_L_RCVEOF:
            begin
               if (cs2link_crc_ok && cs2link_crc_rdy)
		 begin
                    next_state = S_L_GOODCRC;
                 end
               else if (~cs2link_crc_ok && cs2link_crc_rdy)
		 begin
                    next_state = S_L_BADEND;
                 end
            end // case: S_L_RCVEOF
          S_L_GOODCRC:
            begin
	       begin		// LR7:1
		  if (cs2link_char == P_SYNC && cs2link_kchar)
		    begin
		       next_state = S_L_RCV_SYNC;
		    end
		  else
		    begin
                       next_state = S_L_RCV_GOOD;
		    end
	       end
            end // case: S_L_GOODCRC
	  S_L_RCV_GOOD:
	    begin
	       if (cs2link_char == P_SYNC && cs2link_kchar)
		 begin
		    next_state = S_L_RCV_SYNC;
		 end
	       else if (trn_cdst_rdy_n == 1'b0 && trn_cdst_dsc_n == 1'b1)
		 begin
		    next_state = S_L_GOODEND;
		 end
	       else if (trn_cdst_rdy_n == 1'b0 && trn_cdst_dsc_n == 1'b0)
		 begin
		    next_state = S_L_RCV_ABORT;		    
		 end
	    end // case: S_L_RCV_GOOD
          S_L_GOODEND:
            begin
               if (cs2link_char == P_SYNC && cs2link_kchar)
		 begin		// LR8:1
                    next_state = S_IDLE;
                 end
	       else if (~phy2link_rdy)
		 begin		// LR8:3
		    next_state = S_L_NoCommErr;
		 end
            end
          S_L_BADEND:
            begin
	       if (cs2link_char == P_SYNC && cs2link_kchar)
		 begin		// LR9:1
                    next_state = S_L_RCV_BAD;
                 end
	       else if (~phy2link_rdy)
		 begin		// LR9:3
		    next_state = S_L_NoCommErr;
		 end
            end // case: S_L_BADEND
	  S_L_RCV_ABORT:
	    begin
	       if (trn_cdst_dsc_n == 1'b1)
		 begin
		    next_state = S_IDLE;
		 end
	    end
	  S_L_RCV_SYNC:
	    begin
	       if (trn_cdst_rdy_n == 1'b0)
		 begin
		    next_state = S_IDLE;
		 end
	    end
	  S_L_RCV_BAD:
	    begin
	       if (trn_cdst_rdy_n == 1'b0)
		 begin
		    next_state = S_IDLE;
		 end
	    end
        endcase
     end // always @ (*)
   /**************************************************************************/
   always @(posedge clk_75m)
     begin
	if (state == S_L_SEND_RCV)
	  begin
	     trn_csrc_rdy_n <= #1 1'b0;
	     trn_csrc_dsc_n <= #1 1'b1;
	     trn_csof_n     <= #1 1'b0;
	     trn_ceof_n     <= #1 1'b0;
	     trn_cd         <= #1 C_SRCV;	     
	     trn_tfifo_rst  <= #1 1'b1;
	  end
	else if (state == S_L_SEND_SYNC)
	  begin
	     trn_csrc_rdy_n <= #1 1'b0;
	     trn_csrc_dsc_n <= #1 1'b1;
	     trn_csof_n     <= #1 1'b0;
	     trn_ceof_n     <= #1 1'b0;
	     trn_cd         <= #1 C_SYNC;
	     trn_tfifo_rst  <= #1 1'b1;
	  end
	else if (state == S_L_SEND_ROK)
	  begin
	     trn_csrc_rdy_n <= #1 1'b0;
	     trn_csrc_dsc_n <= #1 1'b1;
	     trn_csof_n     <= #1 1'b0;
	     trn_ceof_n     <= #1 1'b0;
	     trn_cd         <= #1 C_R_OK;
	     trn_tfifo_rst  <= #1 1'b1;
	  end
	else if (state == S_L_SEND_RERR)
	  begin
	     trn_csrc_rdy_n <= #1 1'b0;
	     trn_csrc_dsc_n <= #1 1'b1;
	     trn_csof_n     <= #1 1'b0;
	     trn_ceof_n     <= #1 1'b0;
	     trn_cd         <= #1 C_R_ERR;
	     trn_tfifo_rst  <= #1 1'b1;
	  end
	else if (state == S_L_RCV_SYNC)
	  begin
	     trn_csrc_rdy_n <= #1 1'b0;
	     trn_csrc_dsc_n <= #1 1'b1;
	     trn_csof_n     <= #1 1'b0;
	     trn_ceof_n     <= #1 1'b0;
	     trn_cd         <= #1 C_SYNC;
	     trn_tfifo_rst  <= #1 1'b1;
	  end
	else if (state == S_L_RCV_GOOD)
	  begin
	     trn_csrc_rdy_n <= #1 1'b0;
	     trn_csrc_dsc_n <= #1 1'b1;	     
	     trn_csof_n     <= #1 1'b0;
	     trn_ceof_n     <= #1 1'b0;
	     trn_cd         <= #1 C_GOOD;
	     trn_tfifo_rst  <= #1 1'b1;
	  end
	else if (state == S_L_RCV_BAD)
	  begin
	     trn_csrc_rdy_n <= #1 1'b0;
	     trn_csrc_dsc_n <= #1 1'b1;
	     trn_csof_n     <= #1 1'b0;
	     trn_ceof_n     <= #1 1'b0;
	     trn_cd         <= #1 C_BAD;	     	     	     
	     trn_tfifo_rst  <= #1 1'b1;
	  end
	else
	  begin
	     trn_csrc_rdy_n <= #1 1'b1;
	     trn_csrc_dsc_n <= #1 1'b1;
	     trn_csof_n     <= #1 1'b1;
	     trn_ceof_n     <= #1 1'b1;
	     trn_cd         <= #1 8'h0;
	     trn_tfifo_rst  <= #1 ~link_up;
	  end
     end // always @ (posedge clk_75m)
   always @(posedge clk_75m)
     begin
	if (state == S_L_RCVWAITFIFO ||
	    state == S_L_RCVCHKRDY ||
	    state == S_L_RCVDATA ||
	    state == S_L_HOLD    ||
	    state == S_L_RCVHOLD ||
	    state == S_L_RCVEOF  ||
	    state == S_L_GOODCRC ||
	    state == S_L_GOODEND ||
	    state == S_L_BADEND  ||
	    state == S_L_RCV_ABORT ||
	    state == S_L_RCV_SYNC  ||
	    state == S_L_RCV_GOOD  ||
	    state == S_L_RCV_BAD)
	  begin
	     trn_tdst_dsc_n <= #1 1'b0;	     
	  end
	else
	  begin
	     trn_tdst_dsc_n <= #1 1'b1;	     
	  end
     end // always @ (posedge clk_75m)
   // synthesis attribute ASYNC_REG of trn_tdst_dsc_n is TRUE;
   /**************************************************************************/
   //main state fsm
   always @(posedge clk_75m)
     begin
        case (next_state)
          S_IDLE: 
            begin
               link2cs_char      <= P_SYNC;
               link2cs_chark     <= 1'b1;
            end
          S_L_SYNCESCAPE:
            begin
               link2cs_char      <= P_SYNC;
               link2cs_chark     <= 1'b1;
            end 
	  S_L_NoCommErr:
            begin
            end 
	  S_L_NoComm, S_L_SendAlign:
            begin
               link2cs_char      <= P_ALIGN;
               link2cs_chark     <= 1'b1;
            end 
          S_PM_DENY:
            begin
               link2cs_char      <= P_PMNAK;
               link2cs_chark     <= 1'b1;
            end
          S_H_SENDCHKRDY:
            begin
               link2cs_char      <= P_X_RDY;
               link2cs_chark     <= 1'b1;
            end
	  S_L_SENDSOF:
	    begin
               link2cs_char      <= P_SOF;
               link2cs_chark     <= 1'b1;
	    end
	  S_L_SENDDATA:
	    begin
	       link2cs_char      <= 32'h0;
               link2cs_chark     <= 1'b0;	       	       	       
	    end
	  S_L_SENDCRC:
	    begin
	       link2cs_char      <= 32'h0;
               link2cs_chark     <= 1'b0;
	    end
	  S_L_SENDEOF:
	    begin
	       link2cs_char      <= P_EOF;
               link2cs_chark     <= 1'b1;
	    end
          S_L_RCVRHOLD:
            begin
               link2cs_char      <= P_HOLDA;
               link2cs_chark     <= 1'b1;                 
            end
          S_L_SENDHOLD:
            begin
               link2cs_char      <= P_HOLD;
               link2cs_chark     <= 1'b1;
            end           
          S_L_WAIT:
            begin
               link2cs_char      <= P_WTRM;
               link2cs_chark     <= 1'b1;  
            end
          S_L_RCVWAITFIFO:
            begin
               link2cs_char      <= P_SYNC;
               link2cs_chark     <= 1'b1;
            end
          S_L_RCVCHKRDY:
            begin
               link2cs_char      <= P_R_RDY;
               link2cs_chark     <= 1'b1;
            end
          S_L_RCVDATA:
            begin
               link2cs_char      <= P_R_IP;
               link2cs_chark     <= 1'b1;
            end
          S_L_HOLD:
            begin
               link2cs_char      <= P_HOLD;
               link2cs_chark     <= 1'b1;
            end        
          S_L_RCVHOLD:
            begin
               link2cs_char      <= P_HOLDA;
               link2cs_chark     <= 1'b1;
            end 
          S_L_RCVEOF:
            begin
               link2cs_char      <= P_R_IP;
               link2cs_chark     <= 1'b1;
            end          
          S_L_GOODCRC:
            begin
               link2cs_char      <= P_R_IP;
               link2cs_chark     <= 1'b1;
            end            
          S_L_GOODEND:
            begin
               link2cs_char      <= P_R_OK;
               link2cs_chark     <= 1'b1;
            end
          S_L_RCV_GOOD:
            begin
               link2cs_char      <= P_R_IP;
               link2cs_chark     <= 1'b1;
            end	  
          S_L_BADEND:
            begin
               link2cs_char      <= P_R_ERR;
               link2cs_chark     <= 1'b1;
            end
          S_L_SEND_RCV, S_L_SEND_SYNC, S_L_SEND_RERR, S_L_SEND_ROK:
	    begin
               link2cs_char      <= P_SYNC;
               link2cs_chark     <= 1'b1;	       
	    end
	  S_L_RCV_SYNC, S_L_RCV_BAD, S_L_RCV_ABORT:
	    begin
               link2cs_char      <= P_SYNC;
               link2cs_chark     <= 1'b1;	       	       
	    end
        endcase
     end // always @ (posedge clk_75m)
   assign ll2cs_sof = state == S_L_RCVCHKRDY && 
		      cs2link_char == P_SOF && cs2link_kchar;
   assign ll2cs_eof = (state == S_L_RCVDATA  ||
		       state == S_L_HOLD     ||
		       state == S_L_RCVHOLD) && 
		      cs2link_char == P_EOF && cs2link_kchar;
   assign ll2cs_datav=(state == S_L_RCVDATA && ~cs2link_kchar) |
		      (state == S_L_RCVHOLD && ~cs2link_kchar) |
		      (state == S_L_HOLD    && ~cs2link_kchar);
   assign state_idle = state == S_IDLE;
   assign lfsm_state = state;
   /**************************************************************************/
   wire dead_lock;
   reg [8:0] dead_cnt;
   always @(posedge clk_75m)
     begin
	if (state == S_L_RCVRHOLD ||
		 state == S_L_SENDHOLD ||
		 state == S_L_RCVRHOLD ||
		 state == S_L_HOLD ||
		 state == S_L_WAIT)
	  begin
	     dead_cnt <= #1 dead_cnt + 1'b1;
	  end
	else
	  begin
	     dead_cnt <= #1 0;
	  end
     end // always @ (posedge clk_75m)
   assign dead_lock = &dead_cnt;
   reg tx_sync;
   always @(posedge clk_75m)
     begin
        if (next_state == S_L_SEND_SYNC && state != S_L_SEND_SYNC)
	  tx_sync <= #1 1;
	else 
	  tx_sync <= #1 0;
     end
   output [127:0] link_fsm2dbg;
   assign link_fsm2dbg[7:0]  = state;
   assign link_fsm2dbg[15:8] = encode_prim(cs2link_char);
   assign link_fsm2dbg[23:16]= encode_prim(link2cs_char);
   assign link_fsm2dbg[24]   = cs2link_crc_ok;
   assign link_fsm2dbg[25]   = cs2link_crc_rdy;
   assign link_fsm2dbg[26]   = trn_rsof_n;
   assign link_fsm2dbg[27]   = trn_reof_n;
   assign link_fsm2dbg[28]   = trn_rsrc_rdy_n;
   assign link_fsm2dbg[29]   = trn_rdst_rdy_n;
   assign link_fsm2dbg[30]   = trn_rsrc_dsc_n;
   assign link_fsm2dbg[31]   = trn_rdst_dsc_n;
   assign link_fsm2dbg[63:32]= trn_rd;
   assign link_fsm2dbg[95:64]= trn_td;
   assign link_fsm2dbg[96]   = txdatak;
   assign link_fsm2dbg[97]   = trn_tsof_n;
   assign link_fsm2dbg[98]   = trn_teof_n;
   assign link_fsm2dbg[99]   = trn_tsrc_rdy_n;
   assign link_fsm2dbg[100]  = trn_tsrc_dsc_n;
   assign link_fsm2dbg[101]  = trn_tdst_rdy_n;
   assign link_fsm2dbg[102]  = trn_tdst_dsc_n;
   assign link_fsm2dbg[103]  = trn_cdst_rdy_n;
   assign link_fsm2dbg[104]  = trn_cdst_dsc_n;
   assign link_fsm2dbg[105]  = trn_csrc_rdy_n;
   assign link_fsm2dbg[106]  = dead_lock;
   assign link_fsm2dbg[107]  = trn_csof_n;
   assign link_fsm2dbg[108]  = trn_ceof_n;
   assign link_fsm2dbg[112:109]=trn_cd;
   assign link_fsm2dbg[113]  = 1'b0;
   reg [63:0] cs2link_char_ascii;
   reg [63:0] link2cs_char_ascii;
   always @(*)
     begin
	cs2link_char_ascii = prim2ascii(cs2link_char);
	link2cs_char_ascii = prim2ascii(link2cs_char);
     end
   /*AUTOASCIIENUM("state", "state_ascii", "S_")*/
   // Beginning of automatic ASCII enum decoding
   reg [103:0]		state_ascii;		// Decode of state
   always @(state) begin
      case ({state})
	S_IDLE:          state_ascii = "idle         ";
	S_H_SENDCHKRDY:  state_ascii = "h_sendchkrdy ";
	S_L_SENDSOF:     state_ascii = "l_sendsof    ";
	S_L_SENDDATA:    state_ascii = "l_senddata   ";
	S_L_RCVRHOLD:    state_ascii = "l_rcvrhold   ";
	S_L_SENDHOLD:    state_ascii = "l_sendhold   ";
	S_L_SENDCRC:     state_ascii = "l_sendcrc    ";
	S_L_SENDEOF:     state_ascii = "l_sendeof    ";
	S_L_WAIT:        state_ascii = "l_wait       ";
	S_L_SYNCESCAPE:  state_ascii = "l_syncescape ";
	S_L_RCVWAITFIFO: state_ascii = "l_rcvwaitfifo";
	S_L_RCVCHKRDY:   state_ascii = "l_rcvchkrdy  ";
	S_L_RCVDATA:     state_ascii = "l_rcvdata    ";
	S_L_HOLD:        state_ascii = "l_hold       ";
	S_L_RCVHOLD:     state_ascii = "l_rcvhold    ";
	S_L_RCVEOF:      state_ascii = "l_rcveof     ";
	S_L_GOODCRC:     state_ascii = "l_goodcrc    ";
	S_L_GOODEND:     state_ascii = "l_goodend    ";
	S_L_BADEND:      state_ascii = "l_badend     ";
	S_PM_DENY:       state_ascii = "pm_deny      ";
	S_L_NoCommErr:   state_ascii = "l_nocommerr  ";
	S_L_NoComm:      state_ascii = "l_nocomm     ";
	S_L_SendAlign:   state_ascii = "l_sendalign  ";
	S_L_SEND_RCV:    state_ascii = "l_send_rcv   ";
	S_L_SEND_SYNC:   state_ascii = "l_send_sync  ";
	S_L_SEND_RERR:   state_ascii = "l_send_rerr  ";
	S_L_SEND_ROK:    state_ascii = "l_send_rok   ";
	S_L_RCV_SYNC:    state_ascii = "l_rcv_sync   ";
	S_L_RCV_GOOD:    state_ascii = "l_rcv_good   ";
	S_L_RCV_BAD:     state_ascii = "l_rcv_bad    ";
	S_L_RCV_ABORT:   state_ascii = "l_rcv_abort  ";
	default:         state_ascii = "%Error       ";
      endcase
   end
   // End of automatics
endmodule
