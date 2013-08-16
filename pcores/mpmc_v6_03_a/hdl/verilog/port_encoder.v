//-----------------------------------------------------------------------------
//-- (c) Copyright 2006 - 2009 Xilinx, Inc. All rights reserved.
//--
//-- This file contains confidential and proprietary information
//-- of Xilinx, Inc. and is protected under U.S. and
//-- international copyright and other intellectual property
//-- laws.
//--
//-- DISCLAIMER
//-- This disclaimer is not a license and does not grant any
//-- rights to the materials distributed herewith. Except as
//-- otherwise provided in a valid license issued to you by
//-- Xilinx, and to the maximum extent permitted by applicable
//-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//-- (2) Xilinx shall not be liable (whether in contract or tort,
//-- including negligence, or under any other theory of
//-- liability) for any loss or damage of any kind or nature
//-- related to, arising under or in connection with these
//-- materials, including for any direct, or any indirect,
//-- special, incidental, or consequential loss or damage
//-- (including loss of data, profits, goodwill, or any type of
//-- loss or damage suffered as a result of any action brought
//-- by a third party) even if such damage or loss was
//-- reasonably foreseeable or Xilinx had been advised of the
//-- possibility of the same.
//--
//-- CRITICAL APPLICATIONS
//-- Xilinx products are not designed or intended to be fail-
//-- safe, or for use in any application requiring fail-safe
//-- performance, such as life-support or safety devices or
//-- systems, Class III medical devices, nuclear facilities,
//-- applications related to the deployment of airbags, or any
//-- other applications that could lead to death, personal
//-- injury, or severe property or environmental damage
//-- (individually and collectively, "Critical
//-- Applications"). Customer assumes the sole risk and
//-- liability of any use of Xilinx products in Critical
//-- Applications, subject only to applicable laws and
//-- regulations governing limitations on product liability.
//--
//-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//-- PART OF THIS FILE AT ALL TIMES.
//-----------------------------------------------------------------------------
//
// MODULE:  port_encoder.v
//
//-----------------------------------------------
//
//Description:
//  This module takes the binary value and outputs a one_hot output.
//
//-----------------------------------------------
`timescale 1ns / 100ps
`default_nettype none

module port_encoder
#(
  parameter C_NUM_PORTS                 = 1, // Number of ports that are active
  parameter C_PORT_WIDTH                = 3  // Bit width of the port value.            1-3 valid.
)
(
  input  wire [C_PORT_WIDTH-1:0]        Port,
  output wire [C_NUM_PORTS-1:0]         Port_Encode
);

  reg   [C_NUM_PORTS-1:0]               port_encode_i;

  // Optimize each case
  generate
    if (C_NUM_PORTS == 1) begin : encode_1_port
      always @(Port) begin
          port_encode_i = 1'b1;
      end
    end
    else if (C_NUM_PORTS == 2) begin : encode_2_ports
      always @(Port) begin
        case (Port)
          1'b0:     port_encode_i = 2'b01;
          1'b1:     port_encode_i = 2'b10;
        endcase
      end
    end
    else if (C_NUM_PORTS == 3) begin : encode_3_ports
      always @(Port) begin
        case (Port)
          2'b00:    port_encode_i = 3'b001;
          2'b01:    port_encode_i = 3'b010;
          2'b10:    port_encode_i = 3'b100;
          default:  port_encode_i = 3'b001;
        endcase
      end
    end
    else if (C_NUM_PORTS == 4) begin : encode_4_ports
      always @(Port) begin
        case (Port)
          2'b00:    port_encode_i = 4'b0001;
          2'b01:    port_encode_i = 4'b0010;
          2'b10:    port_encode_i = 4'b0100;
          2'b11:    port_encode_i = 4'b1000;
        endcase
      end
    end
    else if (C_NUM_PORTS == 5) begin : encode_5_ports
      always @(Port) begin
        case (Port)
          3'b000:   port_encode_i = 5'b00001;
          3'b001:   port_encode_i = 5'b00010;
          3'b010:   port_encode_i = 5'b00100;
          3'b011:   port_encode_i = 5'b01000;
          3'b100:   port_encode_i = 5'b10000;
          default:  port_encode_i = 5'b00001;
        endcase
      end
    end
    else if (C_NUM_PORTS == 6) begin : encode_6_ports
      always @(Port) begin
        case (Port)
          3'b000:   port_encode_i = 6'b000001;
          3'b001:   port_encode_i = 6'b000010;
          3'b010:   port_encode_i = 6'b000100;
          3'b011:   port_encode_i = 6'b001000;
          3'b100:   port_encode_i = 6'b010000;
          3'b101:   port_encode_i = 6'b100000;
          default:  port_encode_i = 6'b000001;
        endcase
      end
    end
    else if (C_NUM_PORTS == 7) begin : encode_7_ports
      always @(Port) begin
        case (Port)
          3'b000:   port_encode_i = 7'b0000001;
          3'b001:   port_encode_i = 7'b0000010;
          3'b010:   port_encode_i = 7'b0000100;
          3'b011:   port_encode_i = 7'b0001000;
          3'b100:   port_encode_i = 7'b0010000;
          3'b101:   port_encode_i = 7'b0100000;
          3'b110:   port_encode_i = 7'b1000000;
          default:  port_encode_i = 7'b0000001;
        endcase
      end
    end
    else if (C_NUM_PORTS == 8) begin : encode_8_ports
      always @(Port) begin
        case (Port)
          3'b000:   port_encode_i = 8'b00000001;
          3'b001:   port_encode_i = 8'b00000010;
          3'b010:   port_encode_i = 8'b00000100;
          3'b011:   port_encode_i = 8'b00001000;
          3'b100:   port_encode_i = 8'b00010000;
          3'b101:   port_encode_i = 8'b00100000;
          3'b110:   port_encode_i = 8'b01000000;
          3'b111:   port_encode_i = 8'b10000000;
        endcase
      end
    end
  endgenerate
    
  assign Port_Encode = port_encode_i;


endmodule // port_encoder

`default_nettype wire
