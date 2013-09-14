////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 2.6
//  \   \         Application : 7 Series FPGAs Transceivers Wizard 
//  /   /         Filename : gtwizard_v2_6_agc_loop_fsm.v
// /___/   /\     
// \   \  /  \ 
//  \___\/\___\ 
//
//
// Module gtwizard_v2_6_agc_loop_fsm
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

module gtwizard_v2_6_agc_loop_fsm #(
parameter usr_clk=12'd150)
(

input  DCLK,reset,DRDY,
input  [15:0] D0,
output  [15:0] DI,
output  [3:0] holds,
output  DWE,DEN,
output  [8:0] DADDR,
output  kill,

// input[7:0] usr_clk,
output[3:0] state,
output [31:0] count_lock_out,
output  lock0,lock1,lock2,lock3
//output  start,done,lock0,lock1,lock2,lock3

);


wire rd_drp;
wire wr_drp;

assign DWE=wr_drp;
assign DEN= rd_drp | wr_drp;

drp_wr_fsm I1(
.lock0(lock0),
.lock1(lock1),
.lock2(lock2),
.lock3(lock3),
.clk(DCLK),
.reset(reset),
.ready(DRDY),
.holds(holds),
.done(done),
.kill(kill),
.state(state),
.DI(DI),
.di0(D0),
.Address(DADDR),
.rd_drp(rd_drp),
.wr_drp(wr_drp)
);


lock_detect I2( 
.start(start),
.count_lock_out(count_lock_out),
.usr_clk(usr_clk),
.dclk(DCLK),
.reset(reset),
.lock0(lock0),
.lock1(lock1),
.lock2(lock2),
.lock3(lock3)
);

counter I3(.dclk(DCLK), .reset(reset) , .count_lock_out(count_lock_out),.start(start),.stop(done) );

endmodule



module drp_wr_fsm(

input lock0,lock1,lock2,lock3,clk,reset,ready,
input[15:0] di0,
output reg [3:0] holds=0,
output reg [15:0] DI=0,
output reg [8:0] Address=0,
output reg [3:0] state=0,
output reg done=0,
output reg kill=0,
output reg rd_drp=0,
output reg wr_drp=0
);



reg[15:0] store_di0;

initial store_di0=0;
parameter



load_addr_agc=      1,
rd_drp_agc=         2,
wait_drprdy_agc=    3,
mod_drp_agc=        4,
load_drp_agc =      5,
pulse_wr_agc=       6,
wait_drp_dy_agc=    7,
lock_agc=           8,
endstate        =   9,
resetstate      =   10;

initial	    holds=4'b0;
initial     DI=16'b0;
initial     Address=9'b0;
initial     wr_drp=1'b0;
initial     rd_drp=1'b0;
initial     done=1'b0;


always @(posedge clk)

if(reset)
begin
state<=resetstate;
holds<=4'b0;
DI<=16'b0;
Address<=9'b0;
wr_drp<=1'b0;
done<=1'b0;
kill<=1'b0;

end
else
if( (lock0==1'b1 || lock1==1'b1 || lock2==1'b1 || lock3==1'b1) && (!kill)  )
begin

case (state)



resetstate:      begin
state<= load_addr_agc;
done<=0;
holds<=4'b0;
end


//AGC LOOP///

load_addr_agc:    begin
Address<=9'h01E;
state<=rd_drp_agc;
end

rd_drp_agc:       begin                    // Start Read Sequence Wait for DRPRDY
rd_drp<=1'b1;
state<=wait_drprdy_agc;
end

wait_drprdy_agc:  begin                    //  Wait for DRPRDY
rd_drp<=1'b0;
if(ready==1'b1) begin
store_di0<=di0;
state<=mod_drp_agc; end
else begin
state<=wait_drprdy_agc;
end
end

mod_drp_agc:      begin


if (lock0==1'b1 & lock1==1'b0  & lock2==1'b0 & lock3==1'b0) begin
store_di0[2:0]<=3'b011;      /// 64X
state<=load_drp_agc;
end

else if (lock1==1'b1  & lock2==1'b0 & lock3==1'b0) begin
store_di0[2:0]<=3'b010;      /// 16X
state<=load_drp_agc;
end
else if(lock2==1'b1 & lock3==1'b0) begin
store_di0[2:0]<=3'b001;     // 4X
state<=load_drp_agc;
end
else if (lock3==1'b1) begin
store_di0[2:0]<=3'b000;   /// 1X
state<=load_drp_agc;
end
end


load_drp_agc: 
begin
state<=pulse_wr_agc;
DI<=store_di0;
end
                          


pulse_wr_agc:
begin
wr_drp<=1'b1;
state<=wait_drp_dy_agc;
end

wait_drp_dy_agc:
begin
wr_drp<=1'b0;
if( ready==1'b1 )
begin
DI<=store_di0;
state<=lock_agc;
end
end

lock_agc:
begin
if (done==1'b1)
begin
state<=endstate;
end

  	else if( lock0==1'b1 & lock1==1'b0)
  	begin
  	state<=mod_drp_agc;
  	end

   else if( lock1==1'b1 & lock2==1'b0)
  	begin
  	state<=mod_drp_agc;
  	end

	else if( lock2==1'b1 & lock3==1'b0 )
	begin
	state<=mod_drp_agc;
	end

	else if (lock3==1'b1)
	begin
	state<=mod_drp_agc;
	done<=1'b1;
	end
  
else state<=lock_agc;

end

endstate:
begin
holds<=4'b1011;
DI<=16'd0;
Address<=9'd0;
wr_drp<=1'b0;
rd_drp<=1'b0;
kill<=done;
end


default:  state <=  4'bx;


endcase

end
endmodule



module lock_detect ( dclk,reset,lock0,lock1,lock2,lock3,start,count_lock_out,usr_clk);
  
  output lock0,lock1,lock2,lock3,start;
  input[31:0] count_lock_out;
  input[11:0] usr_clk;
  input dclk,reset;
  reg lock0,lock1,lock2,lock3,start;
  initial start=0;
 
  initial lock0=0;
  initial lock1=0;
  initial lock2=0;
  initial lock3=0;
  
   always @ (posedge dclk)
   begin
   if (reset == 1'b1) begin
   lock0<=0;
   lock1<=0;
   lock2<=0;
   lock3<=0;
   start<=0;  
   
end

else   begin

start<=1;

if  (count_lock_out==5)
begin
lock0<=1; end


else if  (count_lock_out==(40*usr_clk))
begin
lock1<=1; end


else  if  (count_lock_out==(160*usr_clk)) begin
lock2<=1; end
else  if  (count_lock_out==(640*usr_clk)) begin
lock3<=1;
start<=0;

end


end
end

endmodule


module counter (dclk, reset, count_lock_out,start,stop);
input reset,start,stop;
input dclk ;

output [31:0] count_lock_out ;

reg [31:0] count_lock_out ;
initial count_lock_out=0;


always @ (posedge dclk)
begin : COUNTER

if (reset == 1'b1 |  stop == 1'b1) begin
count_lock_out <= 32'b0;
end

else if (start == 1'b1  ) begin
count_lock_out <= count_lock_out + 1; end
else  begin

count_lock_out<=0; end

end
endmodule


