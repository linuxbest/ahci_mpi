// rx_cs.v --- 
// 
// Filename: rx_cs.v
// Description: 
// Author: Hu Gang
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
module rx_cs (/*AUTOARG*/
   // Outputs
   cs2link_char, cs2link_kchar, cs2link_crc_ok, cs2link_crc_rdy,
   trn_rsof_n, trn_reof_n, trn_rd, trn_rsrc_rdy_n, trn_rsrc_dsc_n,
   cs2dcr_prim, cs2dcr_cnt, err_ack_dfis, err_ack_ndfis, rx_cs2dbg,
   // Inputs
   clk_75m, host_rst, phy2cs_k, phy2cs_data, trn_rdst_rdy_n,
   trn_rdst_dsc_n, ll2cs_sof, ll2cs_eof, ll2cs_datav, dcr2cs_pop,
   dcr2cs_clk, txdatak, txdata, state_idle, lfsm_state, port_state,
   gtx_txdata, gtx_txdatak, gtx_rxdata, gtx_rxdatak, err_req
   );
   parameter C_LINKFSM_DEBUG = 0;
   parameter C_HW_CRC = 0;
   parameter C_HW_FAKE_ERROR = 0;
   
`include "sata_define.v"

   input clk_75m;
   input host_rst;

   input phy2cs_k;
   input [31:0] phy2cs_data;
   
   output [31:0] cs2link_char;
   output        cs2link_kchar;
   
   output 	 cs2link_crc_ok;
   output 	 cs2link_crc_rdy;
   
   output 	 trn_rsof_n;
   output 	 trn_reof_n;
   output [31:0] trn_rd;
   output 	 trn_rsrc_rdy_n;
   output        trn_rsrc_dsc_n;
   input 	 trn_rdst_rdy_n;
   input 	 trn_rdst_dsc_n;
  
   input         ll2cs_sof;
   input         ll2cs_eof;
   input         ll2cs_datav;

   output [35:0] cs2dcr_prim;
   output [8:0]  cs2dcr_cnt;
   input         dcr2cs_pop;
   input         dcr2cs_clk;

   input 	 txdatak;
   input [31:0]  txdata;
   input 	 state_idle;
   input [7:0]   lfsm_state;
   input [7:0]   port_state;

   input [31:0]  gtx_txdata;
   input [3:0] 	 gtx_txdatak;
   input [31:0]  gtx_rxdata;
   input [3:0] 	 gtx_rxdatak;

   input [7:0] 	 err_req;
   output 	 err_ack_dfis;
   output 	 err_ack_ndfis;
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			cs2link_crc_ok;
   reg			cs2link_crc_rdy;
   reg			err_ack_dfis;
   reg			err_ack_ndfis;
   reg [31:0]		trn_rd;
   reg			trn_reof_n;
   reg			trn_rsof_n;
   reg			trn_rsrc_dsc_n;
   reg			trn_rsrc_rdy_n;
   // End of automatics

   /**************************************************************************/
   wire cs_sof;
   wire cs_eof;
   wire cs_datav;
   assign cs_sof = ll2cs_sof;
   assign cs_eof = ll2cs_eof;
   assign cs_datav=ll2cs_datav;
   reg  cs_kvalid;
   reg  cs_kvalid1;
   reg  cs_kvalid2;
   reg 	cs_kchar;
   reg [31:0] cs_char;
   reg 	cs_kchar_d1;
   reg [31:0] cs_char_d1;
   reg 	      cs_cont_mask;
   always @(posedge clk_75m)
     begin
	if (host_rst)
	  begin
	     cs_cont_mask<= #1 1'b0;
	     cs_kchar    <= #1 1'b0;
	     cs_kvalid   <= #1 1'b0;
	  end
	else if (phy2cs_k && phy2cs_data == P_CONT)
	  begin
	     cs_cont_mask<= #1 1'b1;
	     cs_kvalid   <= #1 1'b1;
	  end
	else if (phy2cs_k && phy2cs_data == P_ALIGN)
	  begin /* making P_SYNC/CONT/XXXX/ALGIN */
	     cs_kvalid   <= #1 1'b0;
	  end
	else if ((phy2cs_k && phy2cs_data != P_CONT) ||
		 (~cs_cont_mask))
	  begin
	     cs_cont_mask<= #1 1'b0;
	     cs_kvalid   <= #1 1'b1;
	     cs_kchar    <= #1 phy2cs_k;
	     cs_kchar_d1 <= #1 cs_kchar;
	     cs_char     <= #1 phy2cs_data;
	     cs_char_d1  <= #1 cs_char;
	  end
     end // always @ (posedge clk_75m)
   assign cs2link_char = cs_char;
   assign cs2link_kchar= cs_kchar;

   wire [31:0] scrambler_out;
   wire [31:0] crc_out;
   wire        crc_rdy;
   scrambler
     rx_scrambler (.scrambler(scrambler_out),
		   .clk_75m(clk_75m),
		   .crc_rst(cs_sof),
		   .data_valid(cs_datav && cs_kvalid));
   
   // [33] SOF
   // [32] EOF
   wire [31:0] rd_do;
   wire        rd_sof;
   wire        rd_eof;
   wire        rd_en;
   wire        rd_empty;
   
   reg [31:0]  wr_di;
   reg 	       wr_sof;
   reg 	       wr_eof;
   reg 	       wr_en;
   wire        wr_almost_full;
   srl16e_fifo_protect
     rx_fifo (
	      // Outputs
	      .DOUT			({rd_sof, rd_eof, rd_do}),
	      .ALMOST_FULL		(wr_almost_full),
	      .FULL			(),
	      .ALMOST_EMPTY		(),
	      .EMPTY			(rd_empty),
	      // Inputs
	      .Clk			(clk_75m),
	      .Rst			(host_rst),
	      .WR_EN			(wr_en),
	      .RD_EN			(rd_en),
	      .DIN			({wr_sof, wr_eof, wr_di}));
   defparam rx_fifo.c_width = 34;
   defparam rx_fifo.c_depth = 16;
   defparam rx_fifo.c_awidth= 4;
   always @(posedge clk_75m)
     begin
	if (cs_sof)
	  begin
	     wr_en  <= #1 1'b1;
	     wr_sof <= #1 1'b1;
	     wr_eof <= #1 1'b0;
	     wr_di  <= #1 32'h0;
	  end
	else if (cs_datav && cs_kvalid)
	  begin
	     wr_en  <= #1 1'b1;
	     wr_sof <= #1 1'b0;
	     wr_eof <= #1 1'b0;
	     wr_di  <= #1 scrambler_out ^ cs_char;
	  end
	else if (cs_eof)
	  begin
	     wr_en  <= #1 1'b1;
	     wr_sof <= #1 1'b0;
	     wr_eof <= #1 1'b1;
	  end
	else
	  begin
	     wr_en  <= #1 1'b0;	     
	  end
     end // always @ (posedge clk_75m)

   assign rd_en = wr_almost_full | (wr_eof && ~rd_empty);

   reg rd_sof1;
   reg rd_sof2;
   reg rd_sof3;   
   reg rd_eof1;
   reg rd_eof2;
   reg rd_eof3;
   reg [31:0] rd_do1;
   reg [31:0] rd_do2;
   reg [31:0] rd_do3;
   reg 	      rd_rdy1;
   reg 	      rd_rdy2;
   reg 	      rd_rdy3;
   always @(posedge clk_75m)
     begin
	rd_sof1 <= #1 rd_sof;
	rd_eof1 <= #1 rd_eof;
	rd_do1  <= #1 rd_do;
	rd_rdy1 <= #1 rd_en;
	
	rd_sof2 <= #1 rd_sof1;
	rd_eof2 <= #1 rd_eof1;
	rd_do2  <= #1 rd_do1;
	rd_rdy2 <= #1 rd_rdy1;

	rd_sof3 <= #1 rd_sof2;
	rd_eof3 <= #1 rd_eof2;
	rd_do3  <= #1 rd_do2;
	rd_rdy3 <= #1 rd_rdy2;
     end // always @ (posedge clk_75m)

   reg eof_sent;
   wire rdy_case;
   wire eof_case;
   assign rdy_case = rd_rdy3 && ~eof_sent;
   assign eof_case = rd_eof;
   always @(posedge clk_75m)
     begin
	if (cs_sof)
	  begin
	     eof_sent <= #1 1'b0;
	  end
	else if (rdy_case && eof_case)
	  begin
	     eof_sent <= #1 1'b1;
	  end
     end // always @ (posedge clk_75m)
   always @(posedge clk_75m)
     begin
	trn_rd         <= #1 rd_do2;
	trn_rsrc_rdy_n <= #1 ~rdy_case;
	trn_rsof_n     <= #1 ~(rdy_case && rd_sof3);
	trn_reof_n     <= #1 ~(rdy_case && eof_case);
     end

   wire crc_valid;
   assign crc_valid = wr_en && wr_sof == 1'b0 && wr_eof == 1'b0;

   wire [31:0] crc_out_hw;
   wire [31:0] crc_out_lut;
   reg [31:0]  crc_out_inv;
   reg [31:0]  wr_di_swap;

generate if (C_HW_CRC == 0)
begin
   crc
     rx_crc (.crc_out(crc_out_lut),
	     .clk_75m(clk_75m),
	     .crc_rst(cs_sof),
	     .data_in(wr_di),
	     .data_valid(crc_valid));
   assign crc_out = crc_out_lut;
   assign crc_rdy = cs_eof;
end
endgenerate

generate if (C_HW_CRC == 1)
begin
   CRC32
     hw_crc (.CRCOUT(crc_out_hw),
	     .CRCCLK(clk_75m),
	     .CRCDATAVALID(crc_valid),
	     .CRCIN(wr_di_swap),
	     .CRCRESET(cs_sof),
	     .CRCDATAWIDTH(3'b011));
   defparam hw_crc.CRC_INIT = 32'h5232_5032;
   always @(*)
     begin
	crc_out_inv[31:24] = Swap_inv(crc_out_hw[31:24]);
	crc_out_inv[23:16] = Swap_inv(crc_out_hw[23:16]);
	crc_out_inv[15:08] = Swap_inv(crc_out_hw[15:08]);
	crc_out_inv[07:00] = Swap_inv(crc_out_hw[07:00]);
	wr_di_swap[31:24] = Swap(wr_di[31:24]);
	wr_di_swap[23:16] = Swap(wr_di[23:16]);
	wr_di_swap[15:08] = Swap(wr_di[15:08]);
	wr_di_swap[07:00] = Swap(wr_di[07:00]);	
     end // always @ (*)
   assign crc_out = crc_out_inv;
   assign crc_rdy = wr_en && wr_eof;
end // if (C_HW_CRC == 1)
endgenerate

   reg fake_crc_err_dfis;
   reg fake_crc_err_ndfis;
   
generate if (C_HW_FAKE_ERROR == 1)
  begin
   always @(posedge clk_75m)
     begin
	if (host_rst || crc_rdy)
	  begin
	     fake_crc_err_dfis  <= #1 1'b0;
	     fake_crc_err_ndfis <= #1 1'b0;
	  end
	else if (trn_rsof_n == 1'b0)
	  begin
	     fake_crc_err_dfis  <= #1 err_req[0] && trn_rd[7:0] == 8'h46;
	     fake_crc_err_ndfis <= #1 err_req[1] && trn_rd[7:0] != 8'h46;
	  end
     end // always @ (posedge clk_75m)
  end // if (C_HW_FAKE_ERROR == 1)
endgenerate
generate if (C_HW_FAKE_ERROR == 0)
  begin
     always @(posedge clk_75m)
     begin
	fake_crc_err_dfis  <= #1 1'b0;	
	fake_crc_err_ndfis <= #1 1'b0;
     end
  end
endgenerate   

   reg fake_crc_err_dfis_d0;
   reg fake_crc_err_ndfis_d0;
   always @(posedge clk_75m)
     begin
	fake_crc_err_dfis_d0  <= #1 fake_crc_err_dfis;
	fake_crc_err_ndfis_d0 <= #1 fake_crc_err_ndfis;
	
	err_ack_dfis  <= #1 fake_crc_err_dfis_d0 ^ fake_crc_err_dfis;
	err_ack_ndfis <= #1 fake_crc_err_ndfis_d0 ^ fake_crc_err_ndfis;
     end
   
   always @(posedge clk_75m)
     begin
	if (crc_rdy)
	  begin
	     cs2link_crc_ok <= #1 crc_out == wr_di && ~(fake_crc_err_dfis | fake_crc_err_ndfis);
	     cs2link_crc_rdy<= #1 1'b1;
	  end
	else if (cs_sof)
	  begin
	     cs2link_crc_rdy<= #1 1'b0;
	     cs2link_crc_ok <= #1 1'b0;
	  end
     end // always @ (posedge clk_75m)

   ////////////////////////////////////////////////////////////////////////////////////////
   // PRIM debug
   reg [7:0]  rx_wi;
   reg 	      rx_we;
   reg [7:0]  tx_wi;
   reg 	      tx_we;
   reg [31:0] phy2cs_data_d1;
   reg [31:0] txdata_d1;
   always @(posedge clk_75m)
     begin
	if (state_idle)
	  begin
	     txdata_d1 <= #1 32'h0;
	  end
	else if (txdatak)
	  begin
	     txdata_d1 <= #1 txdata;
	  end
     end
   always @(posedge clk_75m)
     begin
	if (state_idle)
	  begin
	     phy2cs_data_d1<= #1 32'h0;
	  end
	else if (phy2cs_k && phy2cs_data != P_CONT)
	  begin
	     phy2cs_data_d1 <= #1 phy2cs_data;
	  end
     end // always @ (posedge clk_75m)
   always @(posedge clk_75m)
     begin
	if (phy2cs_k &&
	    phy2cs_data_d1 != phy2cs_data &&
	    phy2cs_data != P_ALIGN &&
            ~state_idle)
	  begin
	     rx_wi[6:0] <= #1 encode_prim(phy2cs_data);
	     rx_wi[7]   <= #1 1'b1;
	     rx_we      <= #1 1'b1;
	  end
	else
	  begin
	     rx_wi[6:0] <= #1 encode_prim(phy2cs_data);
	     rx_wi[7]   <= #1 1'b0;
	     rx_we      <= #1 1'b0;
	  end
     end // always @ (posedge clk_75m)
   always @(posedge clk_75m)
     begin
	if (txdatak &&
	    txdata_d1 != txdata &&
	    ~state_idle)
	  begin
	     tx_wi[6:0] <= #1 encode_prim(txdata);
	     tx_wi[7]   <= #1 1'b1;
	     tx_we      <= #1 1'b1;
	  end
	else
	  begin
	     tx_wi[6:0] <= #1 encode_prim(txdata);
	     tx_wi[7]   <= #1 1'b0;
	     tx_we      <= #1 1'b0;
	  end
     end // always @ (posedge clk_75m)
   wire cs2dcr_we;
   wire [35:0] cs2dcr_wi;
   assign cs2dcr_wi[7:0] = rx_wi;
   assign cs2dcr_wi[15:8]= tx_wi;
   assign cs2dcr_wi[23:16]=lfsm_state;
   assign cs2dcr_wi[31:24]=port_state;
   assign cs2dcr_wi[35:32]=4'h0;
   assign cs2dcr_we = rx_we | tx_we;
   wire [8:0]		cs2dcr_cnt;
   wire [35:0]		cs2dcr_prim;
generate if (C_LINKFSM_DEBUG)
begin
   fifo_36w_36r
     prim_dbg (
	       // Outputs
	       .dout			(cs2dcr_prim[34:0]),
	       .full			(),
	       .almost_full		(),
	       .empty			(cs2dcr_prim[35]),
	       .almost_empty		(),
	       .rd_data_count		(cs2dcr_cnt),
	       .wr_data_count		(),
	       // Inputs
	       .rst			(state_idle),
	       .wr_clk			(clk_75m),
	       .rd_clk			(dcr2cs_clk),
	       .din			(cs2dcr_wi),
	       .wr_en			(cs2dcr_we),
	       .rd_en			(dcr2cs_pop));
end
endgenerate
   /**************************************************************************/
   reg [63:0] phy2cs_ascii;
   always @(*)
   begin
	phy2cs_ascii = prim2ascii(phy2cs_data);
   end
   output [127:0] rx_cs2dbg;
   assign rx_cs2dbg[31:0] = phy2cs_data;
   assign rx_cs2dbg[32]   = phy2cs_k;
   assign rx_cs2dbg[64:33]= trn_rd;
   assign rx_cs2dbg[65]   = trn_rsrc_rdy_n;
   assign rx_cs2dbg[66]   = trn_rdst_rdy_n;
   assign rx_cs2dbg[67]   = trn_rdst_dsc_n;
   assign rx_cs2dbg[68]   = trn_rsof_n;
   assign rx_cs2dbg[69]   = trn_reof_n;
endmodule // rx_cs
// 
// rx_cs.v ends here
