//*****************************************************************************
// Copyright (c) 2008 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, Inc.
// All Rights Reserved
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: $Name: OOB_control_v1_0 $
//  \   \         Application: XAPP870
//  /   /         Filename: OOB_control.v
// /___/   /\     Date Last Modified: $Date: 2008/12/4 00:00:00 $
// \   \  /  \    Date Created: Wed Jan 2 2008
//  \___\/\___\
//
//Device: Virtex-5 LXT
//Design Name: OOB_control
//Purpose:
// This module handles the Out-Of-Band (OOB) handshake requirements
//    
//Reference:
//Revision History: rev1.1
//*****************************************************************************
`timescale 1 ns / 1 ps
//`include "sim.inc" 

module oob_control (/*AUTOARG*/
   // Outputs
   txcomstart, txcomtype, txelecidle, tx_dataout, tx_charisk,
   rx_dataout, rx_charisk_out, linkup, rxreset, CurrentState_out,
   align_det_out, sync_det_out, rx_sof_det_out, rx_eof_det_out,
   oob2dbg, CommInit, StartComm_reg, trig_o,
   // Inouts
   CONTROL,
   // Inputs
   clk, reset, link_reset, rx_locked, tx_sync_done, rxstatus,
   rxelecidle, tx_datain, rx_charisk, rx_datain, rxbyteisaligned,
   gen2, phyreset, StartComm, trig_i
   );
   parameter C_CHIPSCOPE = 0;

   input		clk;
   input 		reset;
   input 		link_reset;
   input 		rx_locked;
   input                tx_sync_done;
   input [2:0] 		rxstatus;
   input		rxelecidle;
   input [9:0] 		tx_datain;
   input [3:0] 		rx_charisk;   		
   input [31:0] 	rx_datain; 	
   input		rxbyteisaligned;
   input 		gen2;	
   input 		phyreset;
   
   output		txcomstart;
   output		txcomtype;
   output 		txelecidle;
   output [31:0] 	tx_dataout;
   output 		tx_charisk;
   
   output [31:0] 	rx_dataout;
   output [3:0] 	rx_charisk_out; 	                        
   output 		linkup;
   output		rxreset;
   output [3:0] 	CurrentState_out;
   output 		align_det_out;
   output 		sync_det_out;
   output 		rx_sof_det_out;
   output 		rx_eof_det_out;
   output [31:0] 	oob2dbg;
   input 		StartComm;
   output 		CommInit;
   output 		StartComm_reg;
   
   inout [35:0] 	CONTROL;
   output 		trig_o;
   input 		trig_i;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			txcomstart;
   reg			txcomtype;
   reg			txelecidle;
   // End of automatics
   
   parameter [3:0]
		host_comreset		= 4'h0,
		wait_dev_cominit	= 4'h1,
		host_comwake 		= 4'h2, 
		wait_dev_comwake 	= 4'h3,
		wait_after_comwake 	= 4'h4,
		wait_after_comwake1 	= 4'h5,
		host_d10_2 		= 4'h6,
		host_send_align 	= 4'h7,
		link_ready 		= 4'h8,
		host_retry              = 4'h9;
   
   wire [15:0] 		count_1us;
   wire [15:0] 		count_880us;
   wire [15:0] 		count_53ns;
   parameter [15:0] 
		C_COUNT_1US   = 16'h0288,
		C_COUNT_880US = 16'hffff, /* GEN1 32768 dwords */
		C_COUNT_53NS  = 16'h0003; /* GEN1 2     dwords */
   assign count_1us  = gen2 ? C_COUNT_1US   : C_COUNT_1US   << 1;
   assign count_880us= gen2 ? C_COUNT_880US : C_COUNT_880US << 1;
   assign count_53ns = gen2 ? C_COUNT_53NS  : C_COUNT_53NS  << 1;
   
   reg [3:0] 		CurrentState, NextState;
   reg [7:0] 		count160;
   reg [15:0] 		count;
   reg [4:0] 		count160_round;
   reg [3:0] 		align_char_cnt_reg;
   reg 			align_char_cnt_rst, align_char_cnt_inc;
   reg 			count_en;
   reg 			send_d10_2_r, send_align_r; 
   reg 			tx_charisk;
   reg 			txelecidle_r;
   reg 			count160_done, count160_go;
   reg [1:0] 		align_count;
   reg 			linkup_r;
   reg 			rxreset; 
   reg [31:0] 		rx_datain_r1;
   reg [31:0] 		tx_datain_r1, tx_datain_r2, tx_datain_r3, tx_datain_r4; // TX data registers
   reg [31:0] 		tx_dataout;
   reg [31:0] 		rx_dataout;
   reg 			tx_align_halfword;
   reg [3:0] 		rx_charisk_out;
   reg 			txcomstart_r, txcomtype_r;
   wire                 device_comwake_released;

   wire 		align_det, tree_nonalign_det;
   wire 		comreset_done, dev_cominit_done, host_comwake_done, dev_comwake_done;
   wire 		rx_sof_det, rx_eof_det;
   wire 		align_cnt_en;
   
   reg 			StartComm_reg;
   always @ (*)
     begin : SM_mux
	count_en = 1'b0;
	NextState = host_comreset;
	txcomstart_r =1'b0;
	txcomtype_r = 1'b0;
	txelecidle_r = 1'b1;
	send_d10_2_r = 1'b0;
	send_align_r = 1'b0;
	rxreset = 1'b0;	
	case (CurrentState)
	  host_retry:
	    begin
	       txcomstart_r =1'b0;	
	       txcomtype_r = 1'b0;
	       NextState = host_comreset;
	    end
	  host_comreset:
	    begin
	       if (rx_locked && StartComm_reg)
		 begin 
		    if (count == count_1us)
		      begin
			 txcomstart_r = 1'b0;	
			 txcomtype_r  = 1'b0;
			 NextState    = wait_dev_cominit;
		      end
		    else
		      begin
			 txcomstart_r = 1'b1;	
			 txcomtype_r  = 1'b0;
			 count_en     = 1'b1;
		      end
		 end
	       else
		 begin
		    txcomstart_r = 1'b0;	
		    txcomtype_r  = 1'b0;
		    NextState    = host_comreset;
		 end									
	    end						
	  wait_dev_cominit: //1
	    begin
	       if (rxstatus == 3'b100) //device cominit detected
		 begin
		    NextState = host_comwake;
		 end
	       else
		 begin
`ifdef SIM
		    if(count == 18'h001ff) 
`else
		    if(count == count_880us) 
		      //restart comreset after no cominit for at least 880us
`endif
			begin
			   count_en = 1'b0;
			   NextState = host_retry;
			end
		    else
		      begin
			 count_en = 1'b1;
			 NextState = wait_dev_cominit;
		      end
		 end
	    end
	  host_comwake: //2
	    begin
	       if (count == count_1us)
		 begin
		    txcomstart_r =1'b0;	
		    txcomtype_r = 1'b0;
		    NextState = wait_dev_comwake;
		 end
	       else
		 begin
		    txcomstart_r =1'b1;	
		    txcomtype_r = 1'b1;
		    count_en = 1'b1;
		    NextState = host_comwake;						
		 end
	    end
	  wait_dev_comwake: //3 
	    begin
	       if (rxstatus == 3'b010) //device comwake detected
		 begin
		    NextState = wait_after_comwake;
		 end
	       else
		 begin
		    if (count == count_880us) 
		      //restart comreset after no cominit for 880us
		      begin
			 count_en = 1'b0;
			 NextState = host_retry;
		      end
		    else
		      begin
			 count_en = 1'b1;
			 NextState = wait_dev_comwake;
		      end
		 end
	    end
	  wait_after_comwake: // 4
	    begin
	       if (device_comwake_released)
		 begin
		    rxreset = 1'b1;    // reset the PCS, to sure rx clock sync
		    NextState = wait_after_comwake1;
		 end
	       else
		 begin
		    count_en = 1'b1;
		    NextState = wait_after_comwake;
		 end
	    end
	  wait_after_comwake1: //5
	    begin
		 NextState = host_d10_2; 	
	    end
	  host_d10_2: //6
	    begin
	       send_d10_2_r = 1'b1;
	       txelecidle_r = 1'b0;
	       if (align_det)
		 begin
		    send_d10_2_r = 1'b0;
		    NextState = host_send_align;
		 end
	       else
		 begin
		    if(count == count_880us) // restart comreset after 880us
		      begin
			 count_en = 1'b0;
			 NextState = host_retry;						
		      end
		    else
		      begin
			 count_en = 1'b1;
			 NextState = host_d10_2;
		      end
		 end				
	    end					
	  host_send_align: //7
	    begin
	       send_align_r = 1'b1;
	       txelecidle_r = 1'b0;
	       if (tree_nonalign_det) // tree back-back non algin prim detected
		 begin
		    send_align_r = 1'b0;
		    NextState = link_ready;
		 end
	       else
		 NextState = host_send_align;
	    end						
	  link_ready: // 8
	    begin
	       txelecidle_r = 1'b0;
	       if (rxelecidle)
		 begin
		    NextState = host_retry;
		 end
	       else
		 begin
		    NextState = link_ready;
		 end
	    end
	  default : NextState = host_comreset;	
	endcase
     end // block: SM_mux
   
   // must need async reset, the clk is not stable.
   always@(posedge clk or posedge reset)
     begin
	if (reset)
	  begin
	     StartComm_reg <= #1 1'b0;
	  end
	else if (CurrentState == host_comreset && StartComm)
	  begin
	     StartComm_reg <= #1 1'b1;
	  end
     end // always@ (posedge clk or posedge reset)
   
   reg CommInit;
   always@(posedge clk or posedge reset)
     begin
	if (reset)  
          begin
	     CommInit <= #1 0;
	  end
	else if (rxstatus == 3'b100)
	  begin
	     CommInit <= #1 ~CommInit;
	  end
     end // always@ (posedge clk)
   
   always@(posedge clk or posedge reset)
     begin : SEQ
	if (reset)
	  CurrentState <= host_comreset;
	else
	  CurrentState <= NextState;
     end
   
   always @(posedge clk)
     linkup_r <= #1 CurrentState == link_ready;
   
   always @(posedge clk)
     begin
	tx_dataout <= #1 send_d10_2_r ? 32'h4a4a_4a4a : 32'h7b4a_4abc;
	tx_charisk <= #1 send_d10_2_r ? 1'b0          : 1'b1;
	txcomstart <= #1 txcomstart_r;
	txcomtype  <= #1 txcomtype_r;
	txelecidle <= #1 txelecidle_r;
     end // always @ (posedge clk)
   
   always@(posedge clk)
     begin
	if (count_en)
	  begin  
	     count = count + 1;
	  end
     	else
     	  begin
	     count = 18'b0;
	  end
     end

   assign comreset_done = (CurrentState == host_comreset && count160_round == 5'h15) ? 1'b1 : 1'b0;
   assign host_comwake_done = (CurrentState == host_comwake && count160_round == 5'h0b) ? 1'b1 : 1'b0;
   
   //Primitive detection
   assign align_det =((rx_datain == 32'h7B4A_4ABC && rx_charisk == 4'b0001) | 
		      (rx_datain == 32'h4A4A_BC7B && rx_charisk == 4'b0010) | 
		      (rx_datain == 32'h4ABC_7B4A && rx_charisk == 4'b0100) | 
		      (rx_datain == 32'hBC7B_4A4A && rx_charisk == 4'b1000)) & 
		     rxbyteisaligned;//prevent invalid align at wrong speed
   
   assign rx_sof_det = (rx_datain == 32'h3737B57C);
   assign rx_eof_det = (rx_datain == 32'hD5D5B57C);
   
   wire nonalign_prim;		// K28.3
   assign nonalign_prim = ((rx_charisk == 4'b0001 && rx_datain[07:00] == 8'h7C) |
			   (rx_charisk == 4'b0010 && rx_datain[15:08] == 8'h7C) | 
			   (rx_charisk == 4'b0100 && rx_datain[23:16] == 8'h7C) |
			   (rx_charisk == 4'b1000 && rx_datain[31:24] == 8'h7C));
   
   reg [2:0] nonalign_prim_shift;
   always @(posedge clk)
     begin
	nonalign_prim_shift <= #1 {nonalign_prim_shift[1:0], 
				   nonalign_prim && 
				   CurrentState == host_send_align && 
				   rxbyteisaligned};
     end
   assign tree_nonalign_det = &nonalign_prim_shift;

   reg [15:0] device_comwake_sync;
   always @(posedge clk)
     begin
	device_comwake_sync <= #1 {device_comwake_sync[14:0], rxelecidle};
     end
   assign device_comwake_released = device_comwake_sync == 16'h0;
   
   assign align_cnt_en     = ~send_d10_2_r;
   assign linkup           = linkup_r;
   assign CurrentState_out = CurrentState;
   assign align_det_out    = align_det;
   assign sync_det_out     = 1'b0;
   assign rx_sof_det_out   = rx_sof_det;
   assign rx_eof_det_out   = rx_eof_det;
   
   assign oob2dbg[7:0] = CurrentState;
   assign oob2dbg[8]   = rxelecidle;
   assign oob2dbg[9]   = txcomstart_r;
   assign oob2dbg[10]  = txcomtype_r;
   assign oob2dbg[11]  = StartComm_reg;
   assign oob2dbg[12]  = StartComm;
   assign oob2dbg[31:15]= count;
   
   wire [127:0] dbg;
   wire		trig_o;
   generate if (C_CHIPSCOPE == 1)
     begin
	chipscope_ila_128x1
	  dbX2 (.TRIG_OUT (trig_o),
		.CONTROL  (CONTROL[35:0]),
		.CLK      (clk),
		.TRIG0    (dbg));
	assign dbg[127] = trig_i;
	assign dbg[126] = reset;
	assign dbg[125] = rx_locked;
	assign dbg[31:0]= rx_datain;
	assign dbg[63:32]=tx_dataout;
	assign dbg[71:64]=rx_charisk;
	assign dbg[79:72]=tx_charisk;
	assign dbg[87:80]=CurrentState;
	assign dbg[103:88]=count;
	assign dbg[111:104]=rxstatus;
	assign dbg[112]  = txcomstart;
	assign dbg[113]  = txcomtype;
	assign dbg[114]  = txelecidle;
	assign dbg[115]  = link_reset;
	assign dbg[116]  = rxelecidle;
	assign dbg[117]  = StartComm_reg;
	assign dbg[118]  = tx_sync_done;
	assign dbg[119]  = tree_nonalign_det;
	assign dbg[120]  = rxbyteisaligned;
	assign dbg[121]  = linkup;
	assign dbg[122]  = rxreset;
	assign dbg[123]  = align_det_out;
	assign dbg[124]  = sync_det_out;
     end
   endgenerate
endmodule
