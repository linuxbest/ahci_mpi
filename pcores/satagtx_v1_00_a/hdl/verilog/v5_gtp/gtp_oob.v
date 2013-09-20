// gtx_oob.v --- 
// 
// Filename: gtx_oob.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Dec  9 11:15:51 2010 (+0800)
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
//  xapp870.pdf
//  SATA 2.6 OOB 8.4.1
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
module gtp_oob (/*AUTOARG*/
   // Outputs
   CommInit, link_up, txcomstart, txcomtype, txelecidle, rxreset,
   txdata, txdatak, txdatak_pop, trig_o,
   // Inouts
   CONTROL,
   // Inputs
   sys_clk, sys_rst, clk_pi_enable, StartComm, txdata_ll, txdatak_ll,
   rxstatus, rxbyteisaligned, rxelecidle, plllkdet, tx_sync_done,
   rxdata, rxdatak, gtx_tune, trig_i
   );
   parameter C_CHIPSCOPE = 0;
   
   input sys_clk;		// tile0_txusrclk20
   input sys_rst;		
   input clk_pi_enable;
   
   // StartComm is signal from the port state machine, it tell us doing transmits COMRESET
   input StartComm;		// ASYNC 
   output CommInit;
   output link_up;
   
   // oob transmit control
   output txcomstart;
   output txcomtype;
   output txelecidle;
   output rxreset;
   output [31:0] txdata;
   output [3:0]	 txdatak;
   
   input [31:0]  txdata_ll;
   input 	 txdatak_ll;
   output 	 txdatak_pop;
   
   // oob receive
   input [2:0] rxstatus;
   input       rxbyteisaligned;
   input       rxelecidle;

   input       plllkdet;
   input       tx_sync_done;
   
   input [31:0] rxdata;
   input [3:0] 	rxdatak;

   input [31:0] gtx_tune;
   
   inout [35:0] CONTROL;
   output 	trig_o;
   input 	trig_i;
   /**********************************************************************/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			link_up;
   reg			rxreset;
   reg			txcomstart;
   reg			txcomtype;
   reg [31:0]		txdata;
   reg [3:0]		txdatak;
   reg			txelecidle;
   // End of automatics

   /**********************************************************************/
   localparam [3:0]// synopsys enum state_info
     S_IDLE               = 4'h0,
     S_HR_Reset           = 4'h1,
     S_HR_AwaitCOMINIT    = 4'h2,
     S_HR_AwaitNoCOMINIT  = 4'h3,
     S_HR_Calibrate       = 4'h4,
     S_HR_COMWAKE         = 4'h5,
     S_HR_AwaitCOMWAKE    = 4'h6,
     S_HR_AwaitNoCOMWAKE  = 4'h7,
     S_HR_AwaitAlign      = 4'h8,
     S_HR_SendAlign       = 4'h9,
     S_HR_Ready           = 4'ha,
     S_HR_Partial         = 4'hb,
     S_HR_Slumber         = 4'hc,
     S_HR_AdjustSpeed     = 4'hd;
   reg [7:0] 		// synopsys enum state_info
			state, state_ns;
   wire StartComm_sync;
   always @(posedge sys_clk or posedge StartComm)
     begin
	if (StartComm)
	  state <= #1 S_IDLE;
	else
	  state <= #1 state_ns;
     end
   wire phy_ready;
   wire await_comreset_done;
   wire await_comwake_done;
   wire await_cominit_timeout;
   wire await_comwake_timeout;
   wire await_align_timeout;
   wire align_det;
   wire tree_nonalign_prim_det;
   always @(*)
     begin
	state_ns = state;
	case (state)
	  S_IDLE: if (phy_ready) 
	    begin
	       state_ns = S_HR_Reset;
	    end
	  S_HR_Reset: if (await_comreset_done)
	    begin
	       state_ns = S_HR_AwaitCOMINIT;
	    end
	  S_HR_AwaitCOMINIT:
	    casex ({rxstatus[2], await_cominit_timeout})
	      {1'b1, 1'bx}: state_ns = S_HR_AwaitNoCOMINIT;
	      {1'b0, 1'b1}: state_ns = S_IDLE;
	    endcase // casex ({rxstatus[2], await_cominit_timeout})
	  S_HR_AwaitNoCOMINIT: if (rxstatus[2] == 1'b0)
	    begin
	       state_ns = S_HR_Calibrate;
	    end
	  S_HR_Calibrate:
	    begin
	       state_ns = S_HR_COMWAKE;
	    end
	  S_HR_COMWAKE: 
	    case ({rxstatus[1], await_comwake_done})
	      {1'b0, 1'b1}: state_ns = S_HR_AwaitCOMWAKE;
	      {1'b1, 1'b1}: state_ns = S_HR_AwaitNoCOMINIT;
	    endcase // casex ({rxstatus[1], rxstatus[0]})
	  S_HR_AwaitCOMWAKE:
	    casex ({rxstatus[1], await_comwake_timeout})
	      {1'b1, 1'bx}: state_ns = S_HR_AwaitNoCOMWAKE;
	      {1'b0, 1'b1}: state_ns = S_IDLE;
	    endcase // casex ({rxstatus[1], await_comwake_timeout})
	  S_HR_AwaitNoCOMWAKE: if (rxstatus[1] == 1'b0)
	    begin
	       state_ns = S_HR_AwaitAlign;
	    end
	  S_HR_AwaitAlign: 
	    casex ({align_det, await_align_timeout})
	      {1'b1, 1'bx}: state_ns = S_HR_AdjustSpeed;
	      {1'b0, 1'b1}: state_ns = S_IDLE;
	    endcase // casex ({align_det, await_align_timeout})
	  S_HR_SendAlign: if (tree_nonalign_prim_det)
	    begin
	       state_ns = S_HR_Ready;
	    end
	  S_HR_AdjustSpeed:
	    begin
	       state_ns = S_HR_SendAlign;
	    end
	  S_HR_Ready: if (rxelecidle)
	    begin
	       state_ns = S_IDLE;
	    end
	  S_HR_Partial:
	    begin
	    end
	  S_HR_Slumber:
	    begin
	    end
	endcase
     end // always @ (*)
   /**********************************************************************/
   reg [15:0] count;
   always @(posedge sys_clk)
     begin
	if (state == state_ns && 
	    (state == S_HR_Reset ||
	     state == S_HR_AwaitCOMINIT ||
	     state == S_HR_COMWAKE ||
	     state == S_HR_AwaitCOMWAKE ||
	     state == S_HR_AwaitAlign) && clk_pi_enable)
	  begin
	     count <= #1 count + 1'b1;
	  end
	else if (clk_pi_enable)
	  begin
	     count <= #1 16'h0;
	  end
     end // always @ (posedge sys_clk)
   assign await_cominit_timeout = count == 16'hffff;
   assign await_comwake_timeout = count == 16'hffff;
   assign await_align_timeout   = count == 16'hffff; // 873.8 us, 32768 GEN1 dword
   assign await_comreset_done   = count == 16'h0288 | rxstatus[0];
   assign await_comwake_done    = count == 16'h0288 | rxstatus[0];
   assign align_det = (((rxdatak[0] && rxdata == 32'h7B4A_4ABC) |
		        (rxdatak[1] && rxdata == 32'h4A4A_BC7B) |
		        (rxdatak[2] && rxdata == 32'h4ABC_7B4A) |
		        (rxdatak[3] && rxdata == 32'hBC7B_4A4A)) && rxbyteisaligned && clk_pi_enable);
   wire nonalign_prim;
   assign nonalign_prim = (((rxdatak[0] && rxdata[07:00] == 8'h7C) |
			    (rxdatak[1] && rxdata[15:08] == 8'h7C) |
			    (rxdatak[2] && rxdata[23:16] == 8'h7C) |
			    (rxdatak[3] && rxdata[31:24] == 8'h7C)) && rxbyteisaligned && clk_pi_enable);
   reg [2:0] nonalign_prim_sync;
   always @(posedge sys_clk)
     begin
	if (clk_pi_enable)
	  begin
	     nonalign_prim_sync <= #1 {nonalign_prim_sync[1:0], 
				       nonalign_prim && state == S_HR_SendAlign};
	  end
     end
   assign tree_nonalign_prim_det = nonalign_prim_sync == 3'b111;
   /**********************************************************************/
   reg [31:0] txdata_o;
   reg 	      txdatak_o;
   always @(posedge sys_clk)
     begin
	case (state)
	  S_IDLE:
	    begin
	       txelecidle <= #1 1'b0;
	       txcomtype  <= #1 1'b0;
	       txcomstart <= #1 1'b0;
	       link_up    <= #1 1'b0;	       
	    end
	  S_HR_Reset:		// Transmit COMRESET
	    begin
	       txelecidle <= #1 1'b1;
	       txcomtype  <= #1 1'b0;
	       txcomstart <= #1 1'b1;
	    end
	  S_HR_AwaitCOMINIT,
	    S_HR_AwaitNoCOMINIT,
	    S_HR_AwaitCOMWAKE,
	    S_HR_AwaitNoCOMWAKE:	// interface quiescent
	      begin
		 txelecidle <= #1 1'b1;
		 txcomstart <= #1 1'b0;
	      end
	  S_HR_COMWAKE:		// Transmit COMWAKE
	    begin
	       txelecidle <= #1 1'b1;
	       txcomtype  <= #1 1'b1;
	       txcomstart <= #1 1'b1;	       
	    end
	  S_HR_AwaitAlign: 	// Transmit D10.2
	    begin
	       txelecidle <= #1 1'b0;
	       txcomstart <= #1 1'b0;
	    end
	  S_HR_SendAlign:	// Trasnmit ALIGNp
	    begin
	       txelecidle <= #1 1'b0;
	       txcomstart <= #1 1'b0;
	    end
	  S_HR_Ready:
	    begin
	       txelecidle <= #1 1'b0;
	       link_up    <= #1 1'b1;
	    end
	endcase
     end // always @ (posedge sys_clk)
   reg [7:0] align_cnt;
   always @(posedge sys_clk)
     begin
	if (state != S_HR_Ready || txdatak_ll)
	  begin
	     align_cnt <= #1 8'h01;
	  end
	else if (state == S_HR_Ready && gtx_tune[31])
	  begin
	     align_cnt <= #1 align_cnt + 1'b1;
	  end
     end // always @ (posedge sys_clk)
   wire algin_req;
   assign align_req   = (align_cnt == 0 || (&align_cnt)) && ~txdatak_ll;
   assign txdatak_pop = ~align_req;
   always @(posedge sys_clk)
     begin
	case (state)
	  S_HR_AwaitAlign:
	    begin
	       txdata_o   <= #1 32'h4A4A_4A4A;
	       txdatak_o  <= #1 1'b0;
	    end
	  S_HR_SendAlign:
	    begin
	       txdata_o   <= #1 32'h7B4A_4ABC;
	       txdatak_o  <= #1 1'b1;
	    end
	  S_HR_Ready:
	    begin
	       txdata_o   <= #1 align_req ? 32'h7B4A_4ABC : txdata_ll;
	       txdatak_o  <= #1 align_req ? 1'b1          : txdatak_ll;
	    end
	  default:
	    begin
	       txdata_o   <= #1 32'h7B4A_4ABC;
	       txdatak_o  <= #1 1'b1;
	    end
	endcase
     end // always @ (posedge sys_clk)
   always @(posedge sys_clk)
     begin
	txdata  <= #1 ~clk_pi_enable ? txdata_o[31:16] : txdata_o[15:0];
	txdatak <= #1 clk_pi_enable && txdatak_o;
     end
   cross_signal 
     StartComm_0 (.clkA(),
		  .signalIn(StartComm),
		  .clkB(sys_clk),
		  .signalOut(StartComm_sync));
   assign phy_ready = plllkdet && /*StartComm_sync && */tx_sync_done;
   assign CommInit = rxstatus[2];
   /**********************************************************************/
   /*AUTOASCIIENUM("state", "state_ascii", "S_")*/
   // Beginning of automatic ASCII enum decoding
   reg [135:0]		state_ascii;		// Decode of state
   always @(state) begin
      case ({state})
	S_IDLE:              state_ascii = "idle             ";
	S_HR_Reset:          state_ascii = "hr_reset         ";
	S_HR_AwaitCOMINIT:   state_ascii = "hr_awaitcominit  ";
	S_HR_AwaitNoCOMINIT: state_ascii = "hr_awaitnocominit";
	S_HR_Calibrate:      state_ascii = "hr_calibrate     ";
	S_HR_COMWAKE:        state_ascii = "hr_comwake       ";
	S_HR_AwaitCOMWAKE:   state_ascii = "hr_awaitcomwake  ";
	S_HR_AwaitNoCOMWAKE: state_ascii = "hr_awaitnocomwake";
	S_HR_AwaitAlign:     state_ascii = "hr_awaitalign    ";
	S_HR_SendAlign:      state_ascii = "hr_sendalign     ";
	S_HR_Ready:          state_ascii = "hr_ready         ";
	S_HR_Partial:        state_ascii = "hr_partial       ";
	S_HR_Slumber:        state_ascii = "hr_slumber       ";
	S_HR_AdjustSpeed:    state_ascii = "hr_adjustspeed   ";
	default:             state_ascii = "%Error           ";
      endcase
   end
   // End of automatics

   wire [127:0] dbg;
   wire		trig_o;
   generate if (C_CHIPSCOPE == 1)
     begin
	chipscope_ila_128x1
	  dbX2 (.TRIG_OUT (trig_o),
		.CONTROL  (CONTROL[35:0]),
		.CLK      (sys_clk),
		.TRIG0    (dbg));
	assign dbg[127] = trig_i;
	assign dbg[126] = sys_rst;
	assign dbg[125] = plllkdet;
	assign dbg[31:0]= rxdata;
	assign dbg[63:32]=txdata;
	assign dbg[71:64]=rxdatak;
	assign dbg[79:72]=txdatak;
	assign dbg[87:80]=state;
	assign dbg[103:88]=count;
	assign dbg[111:104]=rxstatus;
	assign dbg[112]  = txcomstart;
	assign dbg[113]  = txcomtype;
	assign dbg[114]  = txelecidle;
	assign dbg[115]  = phy_ready;
	assign dbg[116]  = rxelecidle;
	assign dbg[117]  = StartComm_sync;
	assign dbg[118]  = tx_sync_done;
	assign dbg[119]  = tree_nonalign_prim_det;
	assign dbg[120]  = rxbyteisaligned;
	assign dbg[121]  = link_up;
	assign dbg[122]  = rxreset;
	assign dbg[123]  = align_det;
	assign dbg[124]  = 1'b0;
     end
   endgenerate   
   /* synthesis attribute keep of txdata_o  is "true" */
   /* synthesis attribute keep of txdatak_o is "true" */
endmodule
// 
// gtx_oob.v ends here
