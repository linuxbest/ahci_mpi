////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 2.6
//  \   \         Application : 7 Series FPGAs Transceivers Wizard 
//  /   /         Filename : gtwizard_v2_6_ctle_agc_comp.v
// /___/   /\     
// \   \  /  \ 
//  \___\/\___\ 
//
//
// Module gtwizard_v2_6_ctle_agc_comp
// Generated by Xilinx 7 Series FPGAs Transceivers Wizard
// 
// 
// (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES. 


`timescale 1ns / 1ps
`define DLY #1
/////////AGC LOOP SETTLING CODE///////

module gtwizard_v2_6_ctle_agc_comp #(
	parameter AGC_TIMER = 150
	//DCLK FREQ (in MHZ) * 12.5 / (Line Rate in Gbps)
	//Max DCLK is 150MHz.  Min Line Rate is 0.5Gbps per data sheet
)
(
	input RST,          //RST low starts state machine
	output DONE,        //DONE asserted when complete, deasserted with RST high
	
	//DRP for accessing CTLE3
	input DRDY,         //Connect to Channel DRP 
	input [15:0] DO,    //Connect to Channel DRP 
	
	input DCLK,         //Connect to same clk as Channel DRP DCLK
	output [8:0] DADDR, //Connect to Channel DRP
	output [15:0] DI,   //Connect to Channel DRP
	output DEN,         //Connect to Channel DRP
	output DWE,         //Connect to Channel DRP

	//RXMONITOR to observe AGC
	input [6:0] RXMONITOR,			//Connect to RXMONITOR port
	output [1:0] RXMONITORSEL,	//Connect to RXMONITORSEL port

	//DEBUG
	output reg [3:0] curr_state
	
);

	parameter CTLE3_ADDR = 9'h83;
	parameter CTLE3_UPPER_LIMIT = 7;
	parameter CTLE3_LOWER_LIMIT = 0;
	parameter AGC_UPPER_LIMIT = 30;
	parameter AGC_LOWER_LIMIT = 1;

	parameter AGC_BW_ADDR = 9'h01D;
	parameter AGC_BW_1X = 4'b0000;
	parameter AGC_BW_4X = 4'b0010;
	parameter AGC_BW_8X = 4'b0011;

	//DCLK_FREQ is actually DCLK_FREQ * 12.5/LineRate in Gbps
	parameter UPDATE_TIMER_LIMIT = AGC_TIMER[11:0] * 4;//At 12.5Gbps, wait 240us in 8x. 12-bits multiply by 4, 14 bits
	parameter UPDATE_TIMER_LIMIT_4X = UPDATE_TIMER_LIMIT * 2;//14 bits multiply by 2. 15 bits.

	parameter IDLE        = 4'd0;
	parameter READ        = 4'd1;
	parameter WAIT_READ   = 4'd2;
	parameter DECIDE      = 4'd3;
	parameter INC         = 4'd4;
	parameter DEC         = 4'd5;
	parameter WRITE       = 4'd6;
	parameter WAIT_UPDATE = 4'd7;
	parameter DONE_ST     = 4'd8;
	parameter READ_AGC_BW = 4'd9; 	
	parameter WAIT_READ_AGC_BW  = 4'd10; 	
	parameter MODIFY_AGC_BW     = 4'd11; 	
	parameter WRITE_AGC_BW      = 4'd12; 	
	parameter WAIT_WRITE_AGC_BW = 4'd13; 	
	parameter DOWNSHIFT_4X = 4'd14;
	parameter WAIT_AGC_4X  = 4'd15;
	//parameter KEEP        = 4'b1111;
	
	reg  in_progress;
	wire in_progress_b;
	
	reg [4:0] agc_reg;
	reg [4:0] agc_reg0;

	wire [3:0] agc_bw;

	wire [3:0] ctle3_reg;
	reg  [3:0] ctle3_ld;
	
	reg [3:0] next_state;
	reg [1:0] rxmon_sel;

	reg [14:0] update_timer;
	reg [5:0] clk_div_counter; 
	//reg [10:0] clk_div_counter; 
	reg den_int, den_int2, dwe_int;
	reg [15:0] do_reg;
	reg done_drp;
	reg [15:0] di_int;
	reg [8:0] daddr_int;
	reg inc,dec;
	wire [1:0] incdec;

	wire clk_int_en, clk_timer_en;
	reg write_state, done_state, downshift_4x_state, read_state, wait_agc_4x_state;
	wire min_agc, max_agc, agc_not_railed, agc_not_railed_l;
	wire rxmon_ok_l, rxmon_ok_l_b;
	wire downshift_4x, downshift_1x;
	wire agc_railing;

	//Assign AGC BW to 4x in beginning then 1x after done adjusting CTLE3.
	assign agc_bw = downshift_1x ? AGC_BW_1X : (downshift_4x ? AGC_BW_4X : AGC_BW_8X); 
	//assign agc_bw = done_pre ? AGC_BW_1X : AGC_BW_4X; 

	always@(posedge DCLK)
	//always@(posedge clk_int)
	begin
		if(clk_int_en)
		begin
			write_state <= `DLY (curr_state == WRITE || curr_state == WRITE_AGC_BW);
			done_state <= `DLY (curr_state == DONE_ST);
			downshift_4x_state <= `DLY (curr_state == DOWNSHIFT_4X);
			wait_agc_4x_state <= `DLY (curr_state == WAIT_AGC_4X);
			read_state <= `DLY (curr_state == READ);
		end
	end

	assign incdec = {inc,dec};
	assign DWE = dwe_int;
	assign in_progress_b = ~in_progress;
	assign RXMONITORSEL = rxmon_sel;
	

	//DRP signals. Hard-code address for GTX CTLE3. AGC read is done thru RX_MONITOR
	//assign DADDR = in_progress_b ? 9'd0 : CTLE3_ADDR;
	assign DADDR = in_progress_b ? 9'd0 : daddr_int;
	assign DI = in_progress_b ? 16'd0 : di_int;

	//assign di_int[11:0]  = do_reg[11:0];
	//assign di_int[15:12] = (curr_state == WRITE || curr_state == WAIT_UPDATE) ? ctle3_ld[3:0] : ctle3_reg;

	assign ctle3_reg = do_reg[15:12];

	//Divide clock
	/*initial //For Sim
	begin
		clk_div_counter <= 1'b0;
	end*/

	always @ (posedge DCLK)
		clk_div_counter <= `DLY clk_div_counter + 1'b1;

	//State machine and most logic on divided-16 clock. Only latching of input signals and DEN are on full-rate clock.  Timers are on divided 2048 clock.
	assign clk_int_en   = (clk_div_counter[3:0] == 4'b1111); //div 16
	assign clk_timer_en = (clk_div_counter[5:0] == 6'b11_1111);//div 64 For synth
	//assign clk_timer_en = (clk_div_counter == 11'b000_0001_1111);//div 1024 For sim

	//den_int updated by divided down clock. Want DEN to be 1 DCLK cycle wide.
	assign DEN = den_int & ~den_int2;
	always @ (posedge DCLK)
		den_int2 <= `DLY den_int;

	always @ (posedge DCLK)
	begin
		if(in_progress_b)
		begin
			do_reg <= `DLY 16'd0;
			done_drp <= `DLY 1'b0;
		end
		else
		begin
			if(DRDY)
			begin
				do_reg <= `DLY DO;
				done_drp <= `DLY 1'b1;
			end
			else if(DEN)
				done_drp <= `DLY 1'b0;
		end
	end

	always @ (posedge DCLK)
	begin
		agc_reg0 <= `DLY RXMONITOR[4:0];
		agc_reg <= `DLY agc_reg0;
	end

	assign min_agc = (agc_reg[4:0] == 5'b00000); 
	assign max_agc = (agc_reg[4:0] == 5'b11111);
	assign agc_not_railed  = ~(min_agc | max_agc);


	////////////////////////////////////////////////////////////
	//SR latch. CLR is dominant.
	FDRE #(
		.INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
	) DONE_SR_FF (
		.Q(DONE),
		.C(DCLK),
		.CE(done_state),
		.R(RST),
		.D(1'b1)
	);

	////////////////////////////////////////////////////////////
	//Determine when to clear latched AGC value
	FDRE #(
		.INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
	) RXMON_OK_SR_FF (
		.Q(rxmon_ok_l),
		.C(DCLK),
		.CE(read_state),
		.R(RST),
		.D(1'b1)
		);

	////////////////////////////////////////////////////////////
	//When rxmon not OK, clock is enabled and loads 0
	//When rxmon OK, clock disabled, and only preset can set output to 1
	/*FDPE #(
		.INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
	) AGC_SR_FF (
		.Q(agc_not_railed_l),
		.C(DCLK),
		.CE(rxmon_ok_l_b),
		.PRE(agc_not_railed),
		.D(1'b0)
		);*/

	FDSE #(
		.INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
	) AGC_SR_FF (
		.Q(agc_not_railed_l),
		.C(DCLK),
		.CE(rxmon_ok_l_b),
		.S(agc_not_railed),
		.D(1'b0)
		);

	////////////////////////////////////////////////////////////
	FDRE #(
		.INIT(1'b0)
	) DOWNSHIFT_4X_SR_FF (
		.Q(downshift_4x),
		.C(DCLK),
		.CE(downshift_4x_state),
		.R(RST),
		.D(1'b1)
	);
		
	////////////////////////////////////////////////////////////
	FDRE #(
		.INIT(1'b0)
	) DOWNSHIFT_1X_SR_FF (
		.Q(downshift_1x),
		.C(DCLK),
		.CE(wait_agc_4x_state),
		.R(RST),
		.D(1'b1)
	);

	assign rxmon_ok_l_b = ~rxmon_ok_l;
	assign agc_railing = ~agc_not_railed_l;
	

	always @ (posedge DCLK or posedge RST)
	begin
		if(RST || DONE)
			in_progress <= `DLY 1'b0;
		else
			in_progress <= `DLY 1'b1;
	end

	always @ (posedge DCLK or posedge write_state)
	begin
		if(write_state)
			update_timer <= `DLY 15'd0;
		else if (clk_timer_en == 1'b1 && (curr_state == WAIT_UPDATE || curr_state == WAIT_AGC_4X))
			update_timer <= `DLY update_timer + 1'b1;

	end
		
	//State machine
	always@(posedge DCLK)
	begin
		if(clk_int_en)
			curr_state <= `DLY next_state;
	end

	always @ (*)
	begin
		//in_progress_b asserted by RST or DONE_ST state
		if(in_progress_b)
		begin
			next_state <= `DLY IDLE;
		end
		else
		begin
			case(curr_state)
				IDLE: begin
					next_state <= `DLY READ_AGC_BW;
				end	
				READ_AGC_BW: begin
					next_state <= `DLY WAIT_READ_AGC_BW;
				end
				WAIT_READ_AGC_BW: begin
					if(done_drp)
						next_state <= `DLY MODIFY_AGC_BW;
					else
						next_state <= `DLY WAIT_READ_AGC_BW;
				end
				MODIFY_AGC_BW: begin
						next_state <= `DLY WRITE_AGC_BW;
				end
				WRITE_AGC_BW: begin
						next_state <= `DLY WAIT_WRITE_AGC_BW;
				end
				WAIT_WRITE_AGC_BW: begin
					if(done_drp)
					begin
						if(downshift_1x)
							next_state <= `DLY DONE_ST; //Done setting 1x AGC so must be done.
						else if(downshift_4x)
							next_state <= `DLY WAIT_AGC_4X; //Wait for 4x AGC convergence.
						else
							next_state <= `DLY READ;  //Done setting 8x AGC. Start CTLE3 compensation.
					end
					else
						next_state <= `DLY WAIT_WRITE_AGC_BW;
				end
				READ: begin
					next_state <= `DLY WAIT_READ;
				end	
				WAIT_READ: begin
					if(done_drp)
						next_state <= `DLY DECIDE;
					else
						next_state <= `DLY WAIT_READ;
				end	
				DECIDE: begin
					//Update CTLE3 based on AGC value. 
					//Do not update if AGC not railing (e.g. OK if dithering between 0 & 1)
					if(agc_reg < AGC_LOWER_LIMIT && ctle3_reg < CTLE3_UPPER_LIMIT && agc_railing)
						next_state <= `DLY INC;
					else if(agc_reg > AGC_UPPER_LIMIT && ctle3_reg > CTLE3_LOWER_LIMIT && agc_railing)
						next_state <= `DLY DEC;
					else //Done adjusting. Go back to 4x AGC BW
						next_state <= `DLY DOWNSHIFT_4X;
				end	
				INC:  begin
					next_state <= `DLY WRITE;
				end
				DEC:  begin
					next_state <= `DLY WRITE;
				end
				WRITE: begin
						next_state <= `DLY WAIT_UPDATE;
				end
				WAIT_UPDATE: begin
					if(update_timer == UPDATE_TIMER_LIMIT)
						next_state <= `DLY READ;
					else
						next_state <= `DLY WAIT_UPDATE;
				end
				DOWNSHIFT_4X: begin
					next_state <= `DLY READ_AGC_BW;
				end
				WAIT_AGC_4X: begin
					if(update_timer == UPDATE_TIMER_LIMIT_4X)
						next_state <= `DLY READ_AGC_BW;
					else
						next_state <= `DLY WAIT_AGC_4X;
				end
				DONE_ST: begin
					next_state <= `DLY DONE_ST;
				end	
				default: begin
					next_state <= `DLY IDLE;
				end	
			endcase
		end
	end


	always@(*)
	begin
		case(curr_state)
			IDLE: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int  <= `DLY 16'd0;
				daddr_int  <= `DLY 9'd0;
				rxmon_sel <= `DLY 2'b00;
			end	
		
			READ_AGC_BW: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b1;
				dwe_int <= `DLY 1'b0;
				di_int  <= `DLY 16'd0;
				daddr_int  <= `DLY AGC_BW_ADDR;
				rxmon_sel <= `DLY 2'b00;
			end	
		
			WAIT_READ_AGC_BW: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int  <= `DLY do_reg;
				daddr_int  <= `DLY AGC_BW_ADDR;
				rxmon_sel <= `DLY 2'b00;
			end	
		
			//Modify to 4x
			MODIFY_AGC_BW: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY {agc_bw,do_reg[11:0]};
				//di_int <= `DLY {do_reg[15:7],agc_bw,do_reg[2:0]};
				daddr_int  <= `DLY AGC_BW_ADDR;
				rxmon_sel <= `DLY 2'b00;
			end	
		
			WRITE_AGC_BW: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b1;
				dwe_int <= `DLY 1'b1;
				di_int <= `DLY {agc_bw,do_reg[11:0]};
				//di_int <= `DLY {do_reg[15:7],agc_bw,do_reg[2:0]};
				daddr_int  <= `DLY AGC_BW_ADDR;
				rxmon_sel <= `DLY 2'b00;
			end	
		
			WAIT_WRITE_AGC_BW: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY {agc_bw,do_reg[11:0]};
				//di_int <= `DLY {do_reg[15:7],agc_bw,do_reg[2:0]};
				daddr_int  <= `DLY AGC_BW_ADDR;
				rxmon_sel <= `DLY 2'b00;
			end	
		
			READ: begin
				//Issue DRP read for addr x083 where ctle3_re is located.
				//1st step in READ-MODIFY-WRITE
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b1;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY do_reg;
				daddr_int  <= `DLY CTLE3_ADDR;
				rxmon_sel <= `DLY 2'b01;
			end	
			
			WAIT_READ: begin
				//Wait until see DONE_ST signal from DRP
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY do_reg;
				daddr_int  <= `DLY CTLE3_ADDR;
				rxmon_sel <= `DLY 2'b01;
			end	
			
			DECIDE: begin
				//Update CTLE3 value based on AGC value
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY do_reg;
				daddr_int  <= `DLY CTLE3_ADDR;
				rxmon_sel <= `DLY 2'b01;
			end	
	
			INC: begin
				inc <= `DLY 1'b1;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY do_reg;
				daddr_int  <= `DLY CTLE3_ADDR;
				rxmon_sel <= `DLY 2'b01;
			end
	
			DEC: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b1;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY do_reg;
				daddr_int  <= `DLY CTLE3_ADDR;
				rxmon_sel <= `DLY 2'b01;
			end

			WRITE: begin
				//Write new CTLE3 value
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b1;
				dwe_int <= `DLY 1'b1;
				di_int <= `DLY {ctle3_ld,do_reg[11:0]};
				daddr_int  <= `DLY CTLE3_ADDR;
				rxmon_sel <= `DLY 2'b01;
			end

			WAIT_UPDATE: begin
				//Wait for 1024 cycles to give time for AGC to adapt
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY {ctle3_ld,do_reg[11:0]};
				daddr_int  <= `DLY CTLE3_ADDR;
				rxmon_sel <= `DLY 2'b01;
			end	
			
			DOWNSHIFT_4X: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int  <= `DLY 16'd0;
				daddr_int  <= `DLY AGC_BW_ADDR;
				rxmon_sel <= `DLY 2'b00;
			end	

			WAIT_AGC_4X: begin
				//Wait for AGC to adapt
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int  <= `DLY 16'd0;
				daddr_int  <= `DLY AGC_BW_ADDR;
				rxmon_sel <= `DLY 2'b01;
			end	

			DONE_ST: begin
				//DONE_ST
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY 16'd0;
				daddr_int  <= `DLY 9'd0;
				rxmon_sel <= `DLY 2'b00;
			end	
			
			default: begin
				inc <= `DLY 1'b0;
				dec <= `DLY 1'b0;
				den_int <= `DLY 1'b0;
				dwe_int <= `DLY 1'b0;
				di_int <= `DLY 16'd0;
				daddr_int  <= `DLY 9'd0;
				rxmon_sel <= `DLY 2'b00;
			end	
		endcase
	end

	always @ (posedge DCLK)
	//always @ (posedge clk_int)
	begin
		if(clk_int_en)
		begin
			if(in_progress_b)
			//if(in_progress_b || time_reached)
			begin
				ctle3_ld <= `DLY ctle3_reg;
			end
			else
			begin
				case (incdec)
					2'b01:
						ctle3_ld <= `DLY ctle3_reg - 1'b1;
					2'b10:
						ctle3_ld <= `DLY ctle3_reg + 1'b1;
					default:
						ctle3_ld <= `DLY ctle3_ld;
				endcase
			end
		end
	end

endmodule

/*
//For synth: LDCE as SR latch
module LDCE #(
	parameter INIT = 1'b0
)
(
	output reg Q,
	input CLR,
	input D,
	input G,
	input GE
);

	initial
	begin
		Q <= `DLY INIT;
	end

	always @ (CLR or G)
	begin
		if(CLR)
			Q <= `DLY 1'b0;
		else if(G)
			Q <= `DLY 1'b1;
	end

endmodule */

