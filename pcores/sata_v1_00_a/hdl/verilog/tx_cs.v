// tx_cs.v --- 
// 
// Filename: tx_cs.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Thu Aug 12 22:00:58 2010 (+0800)
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
module tx_cs (/*AUTOARG*/
   // Outputs
   trn_tdst_rdy_n, txdata, txdatak, rd_sof, rd_eof, rd_empty,
   rd_almost_empty, tx_cs2dbg, err_ack_dfis_tx, err_ack_ndfis_tx,
   // Inputs
   clk_75m, host_rst, link2cs_char, link2cs_chark, trn_tsof_n,
   trn_teof_n, trn_td, trn_tsrc_rdy_n, trn_tsrc_dsc_n, trn_tdst_dsc_n,
   trn_tfifo_rst, txdatak_pop, gtx_tune, err_req, link_up, tx_sync
   );
   parameter C_HW_CRC = 0;
   parameter C_HW_FAKE_ERROR = 1;
`include "sata_define.v"

   input clk_75m;
   input host_rst;
   input link_up;
   input tx_sync;

   // from link fsm
   input [31:0] link2cs_char;
   input 	link2cs_chark;
   
   input        trn_tsof_n;
   input        trn_teof_n;
   input [31:0] trn_td;
   input        trn_tsrc_rdy_n;
   output 	trn_tdst_rdy_n;
   input 	trn_tsrc_dsc_n;
   input 	trn_tdst_dsc_n;
   input        trn_tfifo_rst;

   // to phy
   output [31:0] txdata;
   output 	 txdatak;
   input 	 txdatak_pop;
   
   output 	 rd_sof;
   output 	 rd_eof;
   output 	 rd_empty;
   output 	 rd_almost_empty;

   input [31:0]  gtx_tune;

   input [7:0] 	 err_req;
   output 	 err_ack_dfis_tx;
   output 	 err_ack_ndfis_tx;

   reg  	 err_ack_dfis_tx;
   reg  	 err_ack_ndfis_tx;
   reg           txcs_rst;

   // [33] SOF
   // [32] EOF
   wire [31:0] rd_do;
   wire        rd_sof;
   wire        rd_eof;
   wire        rd_en;
   wire        rd_empty;
   wire        rd_almost_empty;
   wire        wr_almost_full;
   wire        wr_full;
   wire        align_send;
   
   reg [31:0]  wr_di;
   reg 	       wr_sof;
   reg 	       wr_eof;
   reg 	       wr_en;
   reg [31:0] link2cs_char_d;
   reg        prim_insert;
   srl16e_fifo_protect
     cs_fifo (
	      // Outputs
	      .DOUT			({rd_eof, rd_sof, rd_do}),
	      .ALMOST_FULL		(wr_almost_full),
	      .FULL			(wr_full),
	      .ALMOST_EMPTY		(rd_almost_empty),
	      .EMPTY			(rd_empty),
	      // Inputs
	      .Clk			(clk_75m),
	      .Rst			(host_rst | trn_tfifo_rst),
	      .WR_EN			(wr_en),
	      .RD_EN			(rd_en),
	      .DIN			({wr_eof, wr_sof, wr_di}));
   defparam cs_fifo.c_width = 34;
   defparam cs_fifo.c_awidth= 4;
   defparam cs_fifo.c_depth = 16;
   
   assign trn_tdst_rdy_n = ~(~(wr_almost_full|wr_full) && trn_tsrc_rdy_n == 1'b0);
  
   wire [31:0] trn_scrambler;
   wire [31:0] trn_crc_lut;
   wire [31:0] trn_crc_int;
   wire        trn_rst;
   wire        trn_xfer;
   assign trn_rst  = trn_tsrc_rdy_n == 1'b1 && trn_tsof_n == 1'b0;
   assign trn_xfer = trn_tdst_rdy_n == 1'b0 && trn_tsrc_rdy_n == 1'b0;
   scrambler
     cs_scrambler (.scrambler (trn_scrambler),
		   .clk_75m   (clk_75m),
		   .crc_rst   (txcs_rst || tx_sync),
		   .data_valid(trn_xfer));
   reg [31:0]  trn_td_swap;
   wire [31:0] trn_crc_hw;
   reg [31:0]  trn_crc_inv;

generate if (C_HW_CRC == 0)
begin
   crc
     cs_crc       (.crc_out   (trn_crc_lut),
		   .clk_75m   (clk_75m),
		   .crc_rst   (txcs_rst || tx_sync),
		   .data_valid(trn_xfer),
		   .data_in   (trn_td));
   assign trn_crc_int = trn_crc_lut;
end
endgenerate

generate if (C_HW_CRC == 1)
begin
   CRC32
     hw_crc (.CRCOUT      (trn_crc_hw),
	     .CRCCLK      (clk_75m),
	     .CRCDATAVALID(trn_xfer),
	     .CRCIN       (trn_td_swap),
	     .CRCRESET    (txcs_rst || tx_sync),
	     .CRCDATAWIDTH(3'b011));
   defparam hw_crc.CRC_INIT = 32'h5232_5032;
   always @(*)
     begin
        trn_crc_inv[31:24] = Swap_inv(trn_crc_hw[31:24]);
        trn_crc_inv[23:16] = Swap_inv(trn_crc_hw[23:16]);
        trn_crc_inv[15:08] = Swap_inv(trn_crc_hw[15:08]);
        trn_crc_inv[07:00] = Swap_inv(trn_crc_hw[07:00]);
	trn_td_swap[31:24] = Swap(trn_td[31:24]);
	trn_td_swap[23:16] = Swap(trn_td[23:16]);
	trn_td_swap[15:08] = Swap(trn_td[15:08]);
	trn_td_swap[07:00] = Swap(trn_td[07:00]);
     end // always @ (*)
   assign trn_crc_int = trn_crc_inv;
end
endgenerate   

   reg 	       eof_reg, eof_reg_d;
   always @(posedge clk_75m)
     begin
	eof_reg <= #1 trn_xfer && trn_teof_n == 1'b0;
	eof_reg_d <= #1 eof_reg;
     end

   reg fake_crc_err_dfis_tx;
   reg fake_crc_err_ndfis_tx;
   wire fake_crc_en;
   wire [31:0] crc_xor;
   assign fake_crc_en = fake_crc_err_dfis_tx | fake_crc_err_ndfis_tx;
   assign crc_xor = trn_scrambler ^ trn_crc_int;
   // Write Side
   always @(posedge clk_75m)
     begin
        if (host_rst)
          begin
             wr_en <= #1 1'b0;
             txcs_rst <= #1 1'b1;
          end
        else if (trn_xfer)
          begin
             wr_en  <= #1 1'b1;
             wr_di  <= #1 trn_scrambler ^ trn_td;
             wr_sof <= #1 ~trn_tsof_n;
             wr_eof <= #1 ~trn_teof_n;
             txcs_rst <= #1 1'b0;
          end
        else if (eof_reg_d)
          begin
             wr_di  <= #1 fake_crc_en ? ~crc_xor : crc_xor;
             wr_en  <= #1 1'b1;
             txcs_rst <= #1 1'b1;
          end
        else
          begin
             wr_en <= #1 1'b0;
             txcs_rst <= #1 1'b0;
          end
     end // always @ (posedge clk_75m)

   // Read Side   
   reg trn_eof_reg;
   always @(posedge clk_75m)
     begin
	if (rd_eof && rd_en)
	  begin
	     trn_eof_reg <= #1 1'b1;
	  end
	else if (rd_sof)
	  begin
	     trn_eof_reg <= #1 1'b0;
	  end
     end // always @ (posedge clk_75m)
   reg link2cs_chark_d1, link2cs_chark_d2;
   wire data_insert0;
   wire data_insert1;
 
   assign rd_en  =(~link2cs_chark && ~align_send && ~prim_insert) | data_insert0 | data_insert1 ;
   assign txdatak= (link2cs_chark | align_send | prim_insert) && ~data_insert0 && ~data_insert1; 
   assign txdata = align_send ? P_ALIGN : 
		   (~align_send && ~data_insert0 && ~data_insert1 && prim_insert)? link2cs_char_d :
		   ((data_insert0|data_insert1) && ~trn_eof_reg) ? rd_do :
		   ((data_insert0|data_insert1) && trn_eof_reg) ? wr_di :
		   link2cs_chark ? link2cs_char :
		   trn_eof_reg? wr_di  :  rd_do;
 
  
generate if (C_HW_FAKE_ERROR == 1)
  begin
   always @(posedge clk_75m)
     begin
	if (host_rst || trn_eof_reg)
	  begin
	     fake_crc_err_dfis_tx  <= #1 1'b0;
	     fake_crc_err_ndfis_tx <= #1 1'b0;
	  end
	else if (trn_xfer && (trn_tsof_n == 1'b0))
	  begin
	     fake_crc_err_dfis_tx  <= #1 err_req[4] && trn_td[7:0] == 8'h46;
	     fake_crc_err_ndfis_tx <= #1 err_req[5] && trn_td[7:0] != 8'h46;
	  end
     end // always @ (posedge clk_75m)
  end // if (C_HW_FAKE_ERROR == 1)
endgenerate
generate if (C_HW_FAKE_ERROR == 0)
  begin
     always @(posedge clk_75m)
     begin
	fake_crc_err_dfis_tx  <= #1 1'b0;	
	fake_crc_err_ndfis_tx <= #1 1'b0;
     end
  end
endgenerate   

   reg fake_crc_err_dfis_d1;
   reg fake_crc_err_ndfis_d1;
   always @(posedge clk_75m)
     begin
	fake_crc_err_dfis_d1  <= #1 fake_crc_err_dfis_tx;
	fake_crc_err_ndfis_d1 <= #1 fake_crc_err_ndfis_tx;
	
	err_ack_dfis_tx  <= #1 fake_crc_err_dfis_d1 ^ fake_crc_err_dfis_tx;
	err_ack_ndfis_tx <= #1 fake_crc_err_ndfis_d1 ^ fake_crc_err_ndfis_tx;
     end

   always @(posedge clk_75m)
     begin
	link2cs_chark_d1 <= link2cs_chark;
        link2cs_chark_d2 <= link2cs_chark_d1;
     end

   always @(posedge clk_75m)
     begin
	if ((align_send | data_insert0 | data_insert1) && link2cs_chark && (link2cs_char == P_SOF | 
		link2cs_char == P_EOF))
	   begin
	     link2cs_char_d <= link2cs_char;
	     prim_insert <= 1;
	   end
	else if (~align_send && (data_insert0|data_insert1) && prim_insert)
	   begin
	     prim_insert <= 1;
           end
	else if (~align_send | host_rst)
	   begin
	     prim_insert <= 0;
	   end
     end

   reg [7:0] align_cnt;
   assign data_insert0 = align_cnt == 1 && ~link2cs_chark_d2;

   assign data_insert1 = align_cnt == 2 && ~link2cs_chark_d2;

 
   assign align_send = align_cnt == 0 | &align_cnt;
   always @(posedge clk_75m)
     begin
	if (host_rst | ~link_up)
	   begin
	     align_cnt <= 1;
	   end 
	else
	   begin
	     align_cnt <= align_cnt + 1;
	   end
     end

   output [127:0] tx_cs2dbg;
endmodule
// 
// tx_cs.v ends here
