// sata.v --- 
// 
// Filename: sata.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Fri Aug 13 19:08:00 2010 (+0800)
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
localparam [31:0]
  P_ALIGN              = 32'h7B4A_4ABC, 
  P_CONT               = 32'h9999_AA7C,
  P_DMAT               = 32'h3636_B57C,
  P_EOF                = 32'hD5D5_B57C,
  P_HOLD               = 32'hD5D5_AA7C,
  P_HOLDA              = 32'h9595_AA7C,
  P_PMNAK              = 32'hF5F5_957C,
  P_PMREQ_P            = 32'h1717_B57C,
  P_PMREQ_S            = 32'h7575_957C,
  P_R_ERR              = 32'h5656_B57C,
  P_R_IP               = 32'h5555_B57C,
  P_R_OK               = 32'h3535_B57C,
  P_R_RDY              = 32'h4A4A_957C,
  P_SOF                = 32'h3737_B57C,
  P_SYNC               = 32'hB5B5_957C,
  P_WTRM               = 32'h5858_B57C,
  P_X_RDY              = 32'h5757_B57C;
localparam [3:0]
  C_R_OK  = 4'h1,
  C_R_ERR = 4'h2,
  C_SYNC  = 4'h3,
  C_GOOD  = 4'h4,
  C_BAD   = 4'h5,
  C_SRCV  = 4'h6;
function [4:0] encode_prim;
   input [31:0] prim;
   begin
      case (prim)
	P_ALIGN   : encode_prim = 5'h01;
	P_SYNC    : encode_prim = 5'h02;
	P_CONT    : encode_prim = 5'h03;
	P_SOF     : encode_prim = 5'h04;
	P_EOF     : encode_prim = 5'h05;
	P_HOLD    : encode_prim = 5'h06;
	P_WTRM    : encode_prim = 5'h07;
	P_HOLDA   : encode_prim = 5'h10;
	P_R_ERR   : encode_prim = 5'h11;
	P_R_IP    : encode_prim = 5'h12;
	P_R_OK    : encode_prim = 5'h13;
	P_R_RDY   : encode_prim = 5'h14;
	P_X_RDY   : encode_prim = 5'h15;
	P_DMAT    : encode_prim = 5'h1c;
	P_PMNAK   : encode_prim = 5'h1d;
	P_PMREQ_P : encode_prim = 5'h1e;
	P_PMREQ_S : encode_prim = 5'h1f;
	default   : encode_prim = 5'h00;
      endcase
   end
endfunction

function [64:0] prim2ascii;
   input [31:0] prim;
   begin
      case (prim)
	P_ALIGN   : prim2ascii = "ALIGN";
	P_SYNC    : prim2ascii = "SYNC";
	P_CONT    : prim2ascii = "CONT ";
	P_SOF     : prim2ascii = "SOF";
	P_EOF     : prim2ascii = "EOF  ";
	P_HOLD    : prim2ascii = "HOLD ";
	P_WTRM    : prim2ascii = "WTRM";
	P_HOLDA   : prim2ascii = "HOLDA";
	P_R_ERR   : prim2ascii = "R_ERR";
	P_R_IP    : prim2ascii = "R_IP";
	P_R_OK    : prim2ascii = "R_OK";
	P_R_RDY   : prim2ascii = "R_RDY";
	P_X_RDY   : prim2ascii = "X_RDY";
	P_DMAT    : prim2ascii = "DMAT ";
	P_PMNAK   : prim2ascii = "PMNAK";
	P_PMREQ_P : prim2ascii = "PMREQ_P";
	P_PMREQ_S : prim2ascii = "PMREQ_S";
	default   : prim2ascii = "       ";
      endcase
   end
endfunction //
// 
// sata.v ends here
