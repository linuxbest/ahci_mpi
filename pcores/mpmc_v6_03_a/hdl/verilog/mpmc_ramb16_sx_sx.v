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
// MPMC Data Path
//-------------------------------------------------------------------------

// Description:    
//   Data Path for MPMC
//
// Structure:
//   mpmc_data_path
//     mpmc_write_fifo
//       mpmc_bram_fifo
//         mpmc_ramb16_sx_sx
//       mpmc_srl_fifo
//     mpmc_read_fifo
//       mpmc_bram_fifo
//         mpmc_ramb16_sx_sx
//       mpmc_srl_fifo
//     
//--------------------------------------------------------------------------
//
// History:
//   06/15/2007 Initial Version
//
//--------------------------------------------------------------------------
`timescale 1ns/1ns

module mpmc_ramb16_sx_sx #
  (
   parameter C_DATA_WIDTH_A   = 32,
   parameter C_DATA_WIDTH_B   = 32,
   parameter C_PARITY_WIDTH_A = 4,
   parameter C_PARITY_WIDTH_B = 4
  )
  (
   input                         CLKA,
   input                         WEA,
   input  [13:0]                 ADDRA,
   input  [C_DATA_WIDTH_A-1:0]   DIA,
   input  [C_PARITY_WIDTH_A-1:0] DIPA,
   output [C_DATA_WIDTH_A-1:0]   DOA,
   output [C_PARITY_WIDTH_A-1:0] DOPA,
   input                         ENA,
   input                         SSRA,
   input                         CLKB,
   input                         WEB,
   input  [13:0]                 ADDRB,
   input  [C_DATA_WIDTH_B-1:0]   DIB,
   input  [C_PARITY_WIDTH_B-1:0] DIPB,
   output [C_DATA_WIDTH_B-1:0]   DOB,
   output [C_PARITY_WIDTH_B-1:0] DOPB,
   input                         ENB,
   input                         SSRB
   );

   localparam P_ADDR_WIDTH_A = (C_DATA_WIDTH_A ==  1) ? 14 :
                               (C_DATA_WIDTH_A ==  2) ? 13 :
                               (C_DATA_WIDTH_A ==  4) ? 12 :
                               (C_DATA_WIDTH_A ==  8) ? 11 :
                               (C_DATA_WIDTH_A == 16) ? 10 :
                               (C_DATA_WIDTH_A == 32) ?  9 :
                                                               0;
   localparam P_ADDR_WIDTH_B = (C_DATA_WIDTH_B ==  1) ? 14 :
                               (C_DATA_WIDTH_B ==  2) ? 13 :
                               (C_DATA_WIDTH_B ==  4) ? 12 :
                               (C_DATA_WIDTH_B ==  8) ? 11 :
                               (C_DATA_WIDTH_B == 16) ? 10 :
                               (C_DATA_WIDTH_B == 32) ?  9 :
                                                               0;
   
   wire [P_ADDR_WIDTH_A-1:0] ADDRA_tmp;
   wire [P_ADDR_WIDTH_B-1:0] ADDRB_tmp;
   
   generate
      if      (C_DATA_WIDTH_A ==  1) begin : gen_porta_signals_1
         assign ADDRA_tmp = ADDRA[13:0];
      end
      else if (C_DATA_WIDTH_A ==  2) begin : gen_porta_signals_2
         assign ADDRA_tmp = ADDRA[13:1];
      end
      else if (C_DATA_WIDTH_A ==  4) begin : gen_porta_signals_4
         assign ADDRA_tmp = ADDRA[13:2];
      end
      else if (C_DATA_WIDTH_A ==  8) begin : gen_porta_signals_8
         assign ADDRA_tmp = ADDRA[13:3];
      end
      else if (C_DATA_WIDTH_A == 16) begin : gen_porta_signals_16
         assign ADDRA_tmp = ADDRA[13:4];
      end
      else if (C_DATA_WIDTH_A == 32) begin : gen_porta_signals_32
         assign ADDRA_tmp = ADDRA[13:5];
      end
   endgenerate
   generate
      if      (C_DATA_WIDTH_B ==  1) begin : gen_portb_signals_1
         assign ADDRB_tmp = ADDRB[13:0];
      end
      else if (C_DATA_WIDTH_B ==  2) begin : gen_portb_signals_2
         assign ADDRB_tmp = ADDRB[13:1];
      end
      else if (C_DATA_WIDTH_B ==  4) begin : gen_portb_signals_4
         assign ADDRB_tmp = ADDRB[13:2];
      end
      else if (C_DATA_WIDTH_B ==  8) begin : gen_portb_signals_8
         assign ADDRB_tmp = ADDRB[13:3];
      end
      else if (C_DATA_WIDTH_B == 16) begin : gen_portb_signals_16
         assign ADDRB_tmp = ADDRB[13:4];
      end
      else if (C_DATA_WIDTH_B == 32) begin : gen_portb_signals_32
         assign ADDRB_tmp = ADDRB[13:5];
      end
   endgenerate
   generate
      if      ((C_DATA_WIDTH_A ==  1) && (C_DATA_WIDTH_B ==  1)) 
        begin : gen_ramb16_s1_s1
           RAMB16_S1_S1 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),            .DOB(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  1) && (C_DATA_WIDTH_B ==  2)) 
        begin : gen_ramb16_s1_s2
           RAMB16_S1_S2 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),            .DOB(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  1) && (C_DATA_WIDTH_B ==  4)) 
        begin : gen_ramb16_s1_s4
           RAMB16_S1_S4 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),            .DOB(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  1) && (C_DATA_WIDTH_B ==  8)) 
        begin : gen_ramb16_s1_s9
           RAMB16_S1_S9 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  1) && (C_DATA_WIDTH_B == 16)) 
        begin : gen_ramb16_s1_s18
           RAMB16_S1_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  1) && (C_DATA_WIDTH_B == 32)) 
        begin : gen_ramb16_s1_s36
           RAMB16_S1_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  2) && (C_DATA_WIDTH_B ==  1)) 
        begin : gen_ramb16_s2_s1
           RAMB16_S1_S2 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),            .DOB(DOA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  2) && (C_DATA_WIDTH_B ==  2)) 
        begin : gen_ramb16_s2_s2
           RAMB16_S2_S2 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),            .DOB(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  2) && (C_DATA_WIDTH_B ==  4)) 
        begin : gen_ramb16_s2_s4
           RAMB16_S2_S4 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),            .DOB(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  2) && (C_DATA_WIDTH_B ==  8)) 
        begin : gen_ramb16_s2_s9
           RAMB16_S2_S9 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  2) && (C_DATA_WIDTH_B == 16)) 
        begin : gen_ramb16_s2_s18
           RAMB16_S2_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  2) && (C_DATA_WIDTH_B == 32)) 
        begin : gen_ramb16_s2_s36
           RAMB16_S2_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  4) && (C_DATA_WIDTH_B ==  1)) 
        begin : gen_ramb16_s4_s1
           RAMB16_S1_S4 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),            .DOB(DOA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  4) && (C_DATA_WIDTH_B ==  2)) 
        begin : gen_ramb16_s4_s2
           RAMB16_S2_S4 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),            .DOB(DOA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  4) && (C_DATA_WIDTH_B ==  4)) 
        begin : gen_ramb16_s4_s4
           RAMB16_S4_S4 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),            .DOB(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  4) && (C_DATA_WIDTH_B ==  8)) 
        begin : gen_ramb16_s4_s9
           RAMB16_S4_S9 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  4) && (C_DATA_WIDTH_B == 16)) 
        begin : gen_ramb16_s4_s18
           RAMB16_S4_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  4) && (C_DATA_WIDTH_B == 32)) 
        begin : gen_ramb16_s4_s36
           RAMB16_S4_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),            .DOA(DOA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  8) && (C_DATA_WIDTH_B ==  1)) 
        begin : gen_ramb16_s9_s1
           RAMB16_S1_S9 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  8) && (C_DATA_WIDTH_B ==  2)) 
        begin : gen_ramb16_s9_s2
           RAMB16_S2_S9 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  8) && (C_DATA_WIDTH_B ==  4)) 
        begin : gen_ramb16_s9_s4
           RAMB16_S4_S9 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  8) && (C_DATA_WIDTH_B ==  8)) 
        begin : gen_ramb16_s9_s9
           RAMB16_S9_S9 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),.DIPA(DIPA),.DOA(DOA),.DOPA(DOPA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  8) && (C_DATA_WIDTH_B == 16)) 
        begin : gen_ramb16_s9_s18
           RAMB16_S9_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),.DIPA(DIPA),.DOA(DOA),.DOPA(DOPA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A ==  8) && (C_DATA_WIDTH_B == 32)) 
        begin : gen_ramb16_s9_s36
           RAMB16_S9_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),.DIPA(DIPA),.DOA(DOA),.DOPA(DOPA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 16) && (C_DATA_WIDTH_B ==  1)) 
        begin : gen_ramb16_s18_s1
           RAMB16_S1_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 16) && (C_DATA_WIDTH_B ==  2)) 
        begin : gen_ramb16_s18_s2
           RAMB16_S2_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 16) && (C_DATA_WIDTH_B ==  4)) 
        begin : gen_ramb16_s18_s4
           RAMB16_S4_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 16) && (C_DATA_WIDTH_B ==  8)) 
        begin : gen_ramb16_s18_s9
           RAMB16_S9_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),.DIPA(DIPB),.DOA(DOB),.DOPA(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 16) && (C_DATA_WIDTH_B == 16)) 
        begin : gen_ramb16_s18_s18
           RAMB16_S18_S18 #(.SIM_COLLISION_CHECK ("NONE"),
                            .WRITE_MODE_A        ("READ_FIRST"),
                            .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),.DIPA(DIPA),.DOA(DOA),.DOPA(DOPA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 16) && (C_DATA_WIDTH_B == 32)) 
        begin : gen_ramb16_s18_s36
           RAMB16_S18_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                          .WRITE_MODE_A        ("READ_FIRST"),
                          .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),.DIPA(DIPA),.DOA(DOA),.DOPA(DOPA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 32) && (C_DATA_WIDTH_B ==  1)) 
        begin : gen_ramb16_s36_s1
           RAMB16_S1_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 32) && (C_DATA_WIDTH_B ==  2)) 
        begin : gen_ramb16_s36_s2
           RAMB16_S2_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 32) && (C_DATA_WIDTH_B ==  4)) 
        begin : gen_ramb16_s36_s4
           RAMB16_S4_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),            .DOA(DOB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 32) && (C_DATA_WIDTH_B ==  8)) 
        begin : gen_ramb16_s36_s9
           RAMB16_S9_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                           .WRITE_MODE_A        ("READ_FIRST"),
                           .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),.DIPA(DIPB),.DOA(DOB),.DOPA(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 32) && (C_DATA_WIDTH_B == 16)) 
        begin : gen_ramb16_s36_s18
           RAMB16_S18_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                            .WRITE_MODE_A        ("READ_FIRST"),
                            .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKB(CLKA),.ENB(ENA),.SSRB(SSRA),.ADDRB(ADDRA_tmp),
                  .WEB(WEA),.DIB(DIA),.DIPB(DIPA),.DOB(DOA),.DOPB(DOPA),
                  .CLKA(CLKB),.ENA(ENB),.SSRA(SSRB),.ADDRA(ADDRB_tmp),
                  .WEA(WEB),.DIA(DIB),.DIPA(DIPB),.DOA(DOB),.DOPA(DOPB)
                  );
        end
      else if ((C_DATA_WIDTH_A == 32) && (C_DATA_WIDTH_B == 32)) 
        begin : gen_ramb16_s36_s36
           RAMB16_S36_S36 #(.SIM_COLLISION_CHECK ("NONE"),
                            .WRITE_MODE_A        ("READ_FIRST"),
                            .WRITE_MODE_B        ("READ_FIRST")) 
             bram(.CLKA(CLKA),.ENA(ENA),.SSRA(SSRA),.ADDRA(ADDRA_tmp),
                  .WEA(WEA),.DIA(DIA),.DIPA(DIPA),.DOA(DOA),.DOPA(DOPA),
                  .CLKB(CLKB),.ENB(ENB),.SSRB(SSRB),.ADDRB(ADDRB_tmp),
                  .WEB(WEB),.DIB(DIB),.DIPB(DIPB),.DOB(DOB),.DOPB(DOPB)
                  );
        end
   endgenerate
endmodule // mpmc_ramb16_sx_sx
