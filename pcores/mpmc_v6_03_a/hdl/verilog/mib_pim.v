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
// Filename:        mib_pim.v
// Version:         v1.00a
// Description      mib_pim is a port interface module that interfaces with the
//                  Memory Interface Block(MIB) of processor block.
///////////////////////////////////////////////////////////////////////////////
// Structure:
//                  mib_pim.v
///////////////////////////////////////////////////////////////////////////////
// Author:      USM
//
// History:
//        USM         04/27/2007
// ^^^^^^
//          First version of mib_pim
// ~~~~~~
//        NSK         05/30/2007
// ^^^^^^
// Modified logic for generation of MPMC_PIM_Addr_int.
// ~~~~~~
//        NSK         05/31/2007
// ^^^^^^
// Reverted back logic for generation of MPMC_PIM_Addr_int. Made it parametric.
// ~~~~~~
//        NSK         05/31/2007
// ^^^^^^
// Waiting for assertion of MPMC_PIM_AddrAck to assert mc_miaddrreadytoaccept
// for next transaction. Also holding the MPMC_PIM_AddrReq till receive 
// MPMC_PIM_AddrAck.
// ~~~~~~
//        NSK         06/04/2007
// ^^^^^^
// Holding the MPMC_PIM_RNW till receive MPMC_PIM_AddrAck.
// ~~~~~~
//        NSK         06/05/2007
// ^^^^^^
// 1. Deleted extra line spaces.
// 2. Deleted commented code.
// 3. Seperated the generation of addrReq_d1 & rnw_d1.
// ~~~~~~
//        NSK         06/05/2007
// ^^^^^^
// Corrected the logic for generation of mc_mireaddatavalid when 
// C_MPMC_PIM_BURST_LENGTH == 2 & C_MPMC_PIM_DATA_WIDTH == 32.
// ~~~~~~
//        NSK         06/08/2007
// ^^^^^^
// Modified the generation of mc_miaddrreadytoaccept using MPMC_PIM_AddrAck.
// This will generate mc_miaddrreadytoaccept 1 cycle before and save 1 cycle
// delay.
// ~~~~~~
//        NSK         06/11/2007
// ^^^^^^
// Seperated the address path (generation of MPMC_PIM_Addr, MPMC_PIM_AddrReq,
// MPMC_PIM_RNW) for C_MPMC_PIM_BURST_LENGTH = 1 & 
// C_MPMC_PIM_BURST_LENGTH != 1.
// This is to fix the issue when C_MPMC_PIM_BURST_LENGTH = 1 MIB is 
// generating two continuous mi_mcaddressvalid.
// ~~~~~~
//        NSK         06/12/2007
// ^^^^^^
// As MIB is always 128-bit data, to optimize: -
// 1. Removing the logic for C_MPMC_PIM_BURST_LENGTH = 1 when and 
//    C_MPMC_PIM_DATA_WIDTH = 32/64.
// 2. Removing the logic for C_MPMC_PIM_BURST_LENGTH = 2 when and 
//    C_MPMC_PIM_DATA_WIDTH = 32.
// 3. Default assignment changed C_MPMC_PIM_BURST_LENGTH = 2.
// ~~~~~~
//        NSK         06/13/2007
// ^^^^^^
// Clean up: -
// 1. Deleted unused internal signals - rd_cntr, push_cntr, wrFIFO_Data_d1,
//    rdFIFO_Data_d1, addrack_d1, addrack_d2, WrFIFO_BE_d1, 
//    mi_mcwritedatavalid_d1, mi_mcwritedatavalid_d2 & received_addr_ack.
// 2. Changed from reg to wire - MPMC_PIM_Addr, MPMC_PIM_Addr_int, 
//    MPMC_PIM_AddrReq, MPMC_PIM_RNW, MPMC_PIM_WrFIFO_Data & MPMC_PIM_WrFIFO_BE
// 3. Deleted logic generating received_addr_ack.
// 4. Modified logic for generating mc_miaddrreadytoaccept.
// 5. Corrected logic for generation of wrFIFO_space_available.
// ~~~~~~
//        NSK         06/14/2007
// ^^^^^^
// 1. One stage of pipeline to mc_miaddrreadytoaccept, MPMC_PIM_Addr, 
//    MPMC_PIM_AddrReq & MPMC_PIM_RNW when C_MPMC_PIM_PIPE_STAGES=1.
// 2. MPMC_PIM_RdModWr is generated only for write transaction (MPMC_PIM_RNW=0).
// ~~~~~~
//        NSK         06/15/2007
// ^^^^^^
// Updated for review comments from Khang & team: - 
// 1. The default value of C_MPMC_PIM_BURST_LENGTH changed to 4
// 2. The parameter name C_MPMC_PIM_FIFO_TYPE changed to C_MPMC_PIM_WRFIFO_TYPE.
// 3. Removed reset on rnw_d1, mi_mcaddress_d1.
// 4. Optimized wrFIFO_space_available using only 1-bit of bst_cntr.
// 5. MPMC_PIM_RdModWr is tied to 1.
// Other changes: -
// 1. Changed to reg mc_miaddrreadytoaccept
// ~~~~~~
//        NSK         06/18/2007
// ^^^^^^
// 1. Changed signal declaration to reg for MPMC_PIM_Addr, MPMC_PIM_AddrReq &
//    MPMC_PIM_RNW.
// 2. Added logic for C_MPMC_PIM_WIDTH=64 and C_MPMC_PIM_BURST_LENGTH=2.
// 3. Added logic for C_MPMC_PIM_DATA_WIDTH == 32 & C_MPMC_PIM_BURST_LENGTH == 8
//    Waiting for four WrFIFO_Push to go.
// ~~~~~~
//        USM         06/19/2007
// ^^^^^^
// Clean up.
// ~~~~~~
//        NSK         06/20/2007
// ^^^^^^
// 1. Modified code for C_MPMC_PIM_PIPE_STAGES=2. This is to reduce the two cycle
//    latency on the MPMC NPI side to one cycle.
// 2. Rearranged the code in generate blocks which are depeding on 
//    C_MPMC_PIM_PIPE_STAGES.
// 3. Changed the code C_MPMC_PIM_PIPE_STAGES=1. This now adds pipeline in 
//    MPMC NPI inerface, the pipeline for mc_miaddrreadytoaccept when
//    C_MPMC_PIM_DATA_WIDTH!=62 & C_MPMC_PIM_BURST_LENGTH!=2 is removed. The 
//    signal mc_miaddrreadytoaccept goes combinatorial.
// 4. Changed the code C_MPMC_PIM_PIPE_STAGES=2. Moved the mc_miaddrreadytoaccept
//    from C_MPMC_PIM_PIPE_STAGES=1 for C_MPMC_PIM_DATA_WIDTH!=62 & 
//    C_MPMC_PIM_BURST_LENGTH!=2 in this block .
// 5. Modified the logic for generating mc_mireaddatavalid. Now this does not 
//    depend on C_MPMC_PIM_RDFIFO_LATENCY. Using MPMC_PIM_Rd_FIFO_Latency to
//    generate this signal.
// 6. Changed mc_mireaddatavalid to reg.
// ~~~~~~
//        NSK         06/20/2007
// ^^^^^^
// Signal mc_mireaddatavalid is generated in case - changed from if else.
// ~~~~~~
//        NSK         06/26/2007
// ^^^^^^
// 1. Parameter C_MPMC_PIM_MEM_WIDTH changed to C_MPMC_PIM_MEM_DATA_WIDTH.
// 2. MPMC_PIM_AddrReq for C_MPMC_PIM_PIPE_STAGES=1/2 and 
//    C_MPMC_PIM_DATA_WIDTH=32 & C_MPMC_PIM_BURST_LENGTH=8 depends on 
//    C_MPMC_PIM_MEM_DATA_WIDTH=128.
// 3. Corrected the generate block for (C_MPMC_PIM_PIPE_STAGES == 1 | 
//    (C_MPMC_PIM_PIPE_STAGES == 2 & (C_MPMC_PIM_DATA_WIDTH != 64) & 
//    (C_MPMC_PIM_BURST_LENGTH != 2)))
// ~~~~~~
//        NSK         07/30/2007
// ^^^^^^
// Removed unused paramter C_MPMC_PIM_BE_WIDTH.
// ~~~~~~
//        NSK         07/31/2007
// ^^^^^^
// Added paramters C_MEM_BASEADDR & C_MEM_HIGHADDR - to be removed when
// it gets integrated with MPMC3.
// ~~~~~~
//        NSK         08/01/2007
// ^^^^^^
// 1. Removing the generate if C_MPMC_PIM_DATA_WIDTH=32 and 
//    C_MPMC_PIM_BURST_LENGTH=8 and C_MPMC_PIM_MEM_DATA_WIDTH == 128 as this 
//    combination is not supported now.
// 2. Removed the internal signal push_cntr as above(1) block is removed.
// 3. Parameter C_MPMC_PIM_MEM_DATA_WIDTH can be removed.
// ~~~~~~
//        NSK         09/26/2007
// ^^^^^^
// Removed unused paramter C_MEM_BASEADDR & C_MEM_HIGHADDR.
// ~~~~~~
//        NSK         10/01/2007
// ^^^^^^
// Reverted back to the original - the generation of mc_mireaddatavalid as 
// the mib_pim will be moved to mpmc v4.00.a
// 1. This now depends on parameter C_MPMC_PIM_RDFIFO_LATENCY and not on input 
//    port MPMC_PIM_Rd_FIFO_Latency.
// 2. The code is left commented for reference.
// ~~~~~~
//        NSK         10/05/2007
// ^^^^^^
// Removed unused ports listed below: -
// MPMC Ports
// 1. MPMC_PIM_RdFIFO_RdWdAddr
// 2. MPMC_PIM_WrFIFO_AlmostFull
// 3. MPMC_PIM_Rd_FIFO_Latency - left commented for reference to the commented
//    code.
// 4. MPMC_PIM_WrFIFO_Flush
// 5. MPMC_PIM_RdFIFO_Flush
// MIB Ports
// 1. mc_mibclk
// 2. mi_mcbankconflict
// 3. mi_mcrowconflict
// 4. mi_mcwritedataparity
// 5. mc_mibusy
// 5. mc_mireaddataparity
// 6. mc_mireaddataerr
// 7. mc_miwillbebusy
// 8. mc_miwritereadytoaccept
// ~~~~~~
//        NSK         10/09/2007
// ^^^^^^
// Reverting back adding some of the unused ports listed below: -
// MPMC Ports
// 1. MPMC_PIM_RdFIFO_RdWdAddr
// 2. MPMC_PIM_WrFIFO_AlmostFull
// 3. MPMC_PIM_Rd_FIFO_Latency
// 4. MPMC_PIM_WrFIFO_Flush - tied to Logic LOW.
// 5. MPMC_PIM_RdFIFO_Flush - tied to Logic LOW.
// MIB Ports
// 1. mc_mireaddataerr - tied to Logic LOW.
// ~~~~~~
//        NSK         10/11/2007
// ^^^^^^
// Reverting back adding some of the unused ports listed below: -
// MIB Ports
// 1. mi_mcbankconflict
// 2. mi_mcrowconflict
// ~~~~~~
//        NSK         10/25/2007
// ^^^^^^
// Fixed CR #451412 endian conversion of data lines: -
// 1. "MPMC_PIM_RdFIFO_Data" to "mc_mireaddata"
// 2. "mi_mcwritedata" to "MPMC_PIM_WrFIFO_Data"
// ~~~~~~
//        NSK         12/18/2007
// ^^^^^^
// Changed the logic generating signal "mc_miaddrreadytoaccept_int" when 
// C_MPMC_PIM_PIPE_STAGES=1 to fix the bug reported by Kyle.
// ~~~~~~
//        NSK         2/4/2008
// ^^^^^^
// Endian conversion of "mi_mcbyteenable" to "MPMC_PIM_WrFIFO_BE" & to support 
// the endian conversion of "mi_mcwritedata" to "MPMC_PIM_WrFIFO_Data".
// ~~~~~~

///////////////////////////////////////////////////////////////////////////////
// Definition of Generics:
//
//  C_MPMC_PIM_DATA_WIDTH         -- Data Bus Width
//  C_MPMC_PIM_ADDR_WIDTH         -- Address Width
//  C_MPMC_PIM_RDWDADDR_WIDTH     -- Read word Address Width
//  C_MPMC_PIM_RDFIFO_LATENCY     -- Read FIFO Latency
//  C_MPMC_PIM_MEM_DATA_WIDTH     -- Memory Width
//  C_MPMC_PIM_BURST_LENGTH       -- Burst Length
//  C_MPMC_PIM_PIPE_STAGES        -- Pipe line stages to improve frequency
//  C_MPMC_PIM_WRFIFO_TYPE        -- Type of FIFO used in MPMC NPI
//  C_MPMC_PIM_MEM_TYPE           -- Type of memory interfaced to MPMC
//  C_MPMC_PIM_OFFSET             -- Address offset
//  C_FAMILY                      -- Target FPGA family
//
// Definition of Ports
//
//  MPMC_Clk                      -- MPMC clock
//  MPMC_Rst                      -- MPMC reset
//  MPMC_PIM_AddrAck              -- Address acknowledge
//  MPMC_PIM_RdFIFO_Data          -- Read data
//  MPMC_PIM_RdFIFO_RdWdAddr      -- Indicates which word of the transfer is
//                                   being displayed on MPMC_PIM_RdFIFO_Data
//  MPMC_PIM_RdFIFO_DataAvailable -- Data is available in read FIFO
//  MPMC_PIM_RdFIFO_Empty         -- Read FIFOs are empty
//  MPMC_PIM_WrFIFO_AlmostFull    -- Write FIFO will be full on the next cycle
//  MPMC_PIM_WrFIFO_Empty         -- Write FIFO empty 
//  MPMC_PIM_InitDone             -- Memory initialization is completed
//  MPMC_PIM_Rd_FIFO_Latency      -- Number of clock cycles latency between 
//                                   MPMC_PIM_RdFIFO_Pop and valid data on
//                                   MPMC_PIM_RdFIFO_Data
//                                   MPMC_PIM_RdFIFO_RdWdAddr
//  MPMC_PIM_Addr                 -- Address
//  MPMC_PIM_AddrReq              -- Request memory transfer
//  MPMC_PIM_RNW                  -- Read not write
//  MPMC_PIM_Size                 -- Size of the transfer
//  MPMC_PIM_WrFIFO_Data          -- Write data
//  MPMC_PIM_WrFIFO_BE            -- Write data byte enables
//  MPMC_PIM_WrFIFO_Push          -- Write FIFO push
//  MPMC_PIM_RdFIFO_Pop           -- Read FIFO pop
//  MPMC_PIM_WrFIFO_Flush         -- Write FIFO flush
//  MPMC_PIM_RdFIFO_Flush         -- Read FIFO flush
//  MPMC_PIM_RdModWr              -- Read modify write
//  mi_mcaddressvalid             -- Address valid identifier
//  mi_mcaddress                  -- Address bus
//  mi_mcbankconflict             -- Indicates change of bank
//  mi_mcrowconflict              -- Indicates change of row
//  mi_mcbyteenable               -- MIB byte enables
//  mi_mcwritedata                -- Write data
//  mi_mcreadnotwrite             -- Read not write
//  mi_mcwritedatavalid           -- Write data valid identifier                             
//  mc_miaddrreadytoaccept        -- Ready to accept address indicator
//  mc_mireaddata                 -- Read data bus
//  mc_mireaddataerr              -- Read data error
//  mc_mireaddatavalid            -- Read data valid indicator
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module mib_pim(
  MPMC_Clk,                       // I
  MPMC_Rst,                       // I

  // MPMC Port Interface
  //Input
  MPMC_PIM_AddrAck,               // I
  MPMC_PIM_RdFIFO_Data,           // I [C_MPMC_MPMC_PIMM_DATA_WIDTH-1:0]
  MPMC_PIM_RdFIFO_RdWdAddr,       // I [C_MPMC_PIM_RDWDADDR_WIDTH-1:0]
  MPMC_PIM_RdFIFO_DataAvailable,  // I
  MPMC_PIM_RdFIFO_Empty,          // I
  MPMC_PIM_WrFIFO_AlmostFull,     // I
  MPMC_PIM_WrFIFO_Empty,          // I
  MPMC_PIM_InitDone,              // I
  MPMC_PIM_Rd_FIFO_Latency,       // I
  //Output
  MPMC_PIM_Addr,                  // O [C_MPMC_PIM_ADDR_WIDTH-1:0]
  MPMC_PIM_AddrReq,               // O
  MPMC_PIM_RNW,                   // O
  MPMC_PIM_Size,                  // O [3:0]
  MPMC_PIM_WrFIFO_Data,           // O [C_MPMC_PIM_DATA_WIDTH-1:0]
  MPMC_PIM_WrFIFO_BE,             // O [C_MPMC_PIM_DATA_WIDTH/8-1:0]
  MPMC_PIM_WrFIFO_Push,           // O
  MPMC_PIM_RdFIFO_Pop,            // O
  MPMC_PIM_WrFIFO_Flush,          // O
  MPMC_PIM_RdFIFO_Flush,          // O
  MPMC_PIM_RdModWr,               // O

  // MIB Port Interface
  //Input
  mi_mcaddressvalid,              // I
  mi_mcaddress,                   // I
  mi_mcbankconflict,              // I
  mi_mcrowconflict,               // I
  mi_mcbyteenable,                // I
  mi_mcwritedata,                 // I
  mi_mcreadnotwrite,              // I
  mi_mcwritedatavalid,            // I
  //Output
  mc_miaddrreadytoaccept,         // O
  mc_mireaddata,                  // O
  mc_mireaddataerr,               // O
  mc_mireaddatavalid              // O
);

   // Parameters
   parameter C_MPMC_PIM_DATA_WIDTH = 64;
   parameter C_MPMC_PIM_ADDR_WIDTH = 32;
   parameter C_MPMC_PIM_RDFIFO_LATENCY = 0;
   parameter C_MPMC_PIM_RDWDADDR_WIDTH = 4;
   parameter C_MPMC_PIM_MEM_DATA_WIDTH = 32;
   parameter C_MPMC_PIM_BURST_LENGTH = 4;
   parameter C_MPMC_PIM_PIPE_STAGES = 1;
   parameter C_MPMC_PIM_WRFIFO_TYPE = "BRAM";
   parameter C_MPMC_PIM_OFFSET = 32'h00000000;
   parameter C_FAMILY = "virtex5";

   localparam BURST_SIZE_4  = 4'b0001;
   localparam BURST_SIZE_8  = 4'b0010;
   localparam BURST_SIZE_16 = 4'b0011;

// inputs from NPI of MPMC 
   input                                   MPMC_Clk;
   input                                   MPMC_Rst;
   input                                   MPMC_PIM_AddrAck;
   input [(C_MPMC_PIM_DATA_WIDTH-1):0]     MPMC_PIM_RdFIFO_Data;
   input [(C_MPMC_PIM_RDWDADDR_WIDTH-1):0] MPMC_PIM_RdFIFO_RdWdAddr;
   input                                   MPMC_PIM_RdFIFO_DataAvailable;
   input                                   MPMC_PIM_RdFIFO_Empty;
   input                                   MPMC_PIM_WrFIFO_AlmostFull;
   input                                   MPMC_PIM_WrFIFO_Empty;
   input                                   MPMC_PIM_InitDone;
   input [1:0]                             MPMC_PIM_Rd_FIFO_Latency;

// outputs to NPI of MPMC 
   output [(C_MPMC_PIM_ADDR_WIDTH-1):0]    MPMC_PIM_Addr;
   output                                  MPMC_PIM_AddrReq;
   output                                  MPMC_PIM_RNW;
   output [3:0]                            MPMC_PIM_Size;
   output [(C_MPMC_PIM_DATA_WIDTH-1):0]    MPMC_PIM_WrFIFO_Data;
   output [(C_MPMC_PIM_DATA_WIDTH/8-1):0]  MPMC_PIM_WrFIFO_BE;
   output                                  MPMC_PIM_WrFIFO_Push;
   output                                  MPMC_PIM_RdFIFO_Pop;
   output                                  MPMC_PIM_WrFIFO_Flush;
   output                                  MPMC_PIM_RdFIFO_Flush;
   output                                  MPMC_PIM_RdModWr;

// inputs from MIB of PPC 
   input                                   mi_mcaddressvalid;
   input [0:35]                            mi_mcaddress;
   input                                   mi_mcbankconflict;
   input                                   mi_mcrowconflict;
   input [0:15]                            mi_mcbyteenable;
   input [0:127]                           mi_mcwritedata;
   input                                   mi_mcreadnotwrite;
   input                                   mi_mcwritedatavalid;

// outputs to MIB of PPC 
   output                                  mc_miaddrreadytoaccept;
   output [0:127]                          mc_mireaddata;
   output                                  mc_mireaddataerr;
   output                                  mc_mireaddatavalid;

// reg declarations
   reg                                     rdFIFO_Pop_d1;
   reg                                     rdFIFO_Pop_d2;
   reg  [0:C_MPMC_PIM_ADDR_WIDTH-1]        mi_mcaddress_d1;
   reg                                     addrReq_d1;
   reg                                     rnw_d1;
   reg  [3:0]                              bst_cntr;
   reg                                     mc_miaddrreadytoaccept;
   reg   [(C_MPMC_PIM_ADDR_WIDTH-1):0]     MPMC_PIM_Addr;
   reg                                     MPMC_PIM_AddrReq;
   reg                                     MPMC_PIM_RNW;
   reg                                     req_1;
   reg                                     req_2;
   reg                                     received_first_ack;
   reg                                     rnw_1;
   reg                                     rnw_2;
   reg [31:0]                              addr_1;
   reg [31:0]                              addr_2;
   reg                                     mc_miaddrreadytoaccept_int;
//   reg [1:0]                               push_cntr;
   reg                                     mc_mireaddatavalid;
// wire declarations
   wire  [(C_MPMC_PIM_ADDR_WIDTH-1):0]     MPMC_PIM_Addr_int;
   wire  [(C_MPMC_PIM_DATA_WIDTH-1):0]     MPMC_PIM_WrFIFO_Data;
   wire  [(C_MPMC_PIM_DATA_WIDTH/8-1):0]   MPMC_PIM_WrFIFO_BE;
   wire                                    MPMC_PIM_WrFIFO_Flush;
   wire                                    MPMC_PIM_RdFIFO_Flush;
   wire                                    MPMC_PIM_WrFIFO_Push;
   wire                                    MPMC_PIM_RdFIFO_Pop;
   wire                                    MPMC_PIM_RdModWr;
   wire [0:127]                            mc_mireaddata;
   wire [3:0]                              MPMC_PIM_Size;
   wire                                    wrFIFO_space_available;
   wire                                    mc_mireaddataerr;


///////////////////////////////////////////////////////////////////////////////
//////////////////////////////  NOTE  /////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// Size=0 - word - address is double word aligned --- Not supported ///////////
// C_MPMC_PIM_BURST_LENGTH=1                                -- Not supported //
// C_MPMC_PIM_BURST_LENGTH=2 & C_MPMC_PIM_DATA_WIDTH=32     -- Not supported //
//
// Size=1 - 4-word cache-line - address is double word aligned ////////////////
// Size=2 - 8-word cache-line - address is  double word aligned ///////////////
// Size=3 - 16-word - address is 16-word aligned //////////////////////////////
///////////////////////////////////////////////////////////////////////////////


                     /*****************************
                     ***** ADDRESS PATH LOGIC *****
                     *****************************/
/******************************************************************************
*****************Generate for C_MPMC_PIM_PIPE_STAGES = 0  *********************
******************************************************************************/
generate if (C_MPMC_PIM_PIPE_STAGES == 0) 
begin

/////////// Addr Ready to accept generation ///////////////////////////////////
/// This signal goes high when memory initialization is completed and there is
//  space available in NPI wrFIFO and no pending request.
///////////////////////////////////////////////////////////////////////////////
    always@* mc_miaddrreadytoaccept =  MPMC_PIM_InitDone & wrFIFO_space_available
                                     & (~ MPMC_PIM_AddrReq | MPMC_PIM_AddrAck);

// ADDRESS GENERATION//////////////////////////////////////////////////////////
// Register the address from MIB, when the address valid signal goes high /////
    always@(posedge MPMC_Clk)
    begin
        if(mi_mcaddressvalid == 1'b1)
            mi_mcaddress_d1 <= mi_mcaddress[(35-C_MPMC_PIM_ADDR_WIDTH+1):35];
        else
            mi_mcaddress_d1 <= mi_mcaddress_d1;
    end

// The address from MIB is directly passed to NPI interface when the address //
// valid is high. When the address valid is low, the registered address is  //
// sent.
    assign MPMC_PIM_Addr_int = mi_mcaddressvalid ? 
                                 mi_mcaddress[(35-C_MPMC_PIM_ADDR_WIDTH+1):35] 
                                 : mi_mcaddress_d1;

    always@* MPMC_PIM_Addr = MPMC_PIM_Addr_int + C_MPMC_PIM_OFFSET;

///////////////////////////////////////////////////////////////////////////////
// Address Req generation /////////////////////////////////////////////////////
// addrReq_d1 becomes high when address valid goes high, and stays high till //
// address ack become high ////////////////////////////////////////////////////
    always@(posedge MPMC_Clk)
    begin
        if (MPMC_Rst == 1'b1 )
            addrReq_d1 <= 1'b0;
        else
            addrReq_d1 <= ~(MPMC_PIM_AddrAck == 1'b1) & 
                          ((mi_mcaddressvalid == 1'b1) | addrReq_d1);
    end

// When address valid is high, address request goes high, when the address ////
// valid is low, the addrReq_d1 is passed /////////////////////////////////////
    always@* MPMC_PIM_AddrReq = mi_mcaddressvalid | addrReq_d1; 

///////////////////////////////////////////////////////////////////////////////
/////// RNW Generation ////////////////////////////////////////////////////////
// When address valid is high, read not write is same as MIB read not write, /
// when the address valid is low, the rnw_d1 is passed ////////////////////////
    always@(posedge MPMC_Clk)
    begin
        if (mi_mcaddressvalid == 1'b1)
            rnw_d1 <= mi_mcreadnotwrite;
        else
            rnw_d1 <=  rnw_d1;
    end

    always@* MPMC_PIM_RNW = mi_mcaddressvalid ? mi_mcreadnotwrite : rnw_d1;

end
endgenerate
/******************************************************************************
*************** END Generate for C_MPMC_PIM_PIPE_STAGES = 0  ******************
******************************************************************************/

/******************************************************************************
*****************Generate for C_MPMC_PIM_PIPE_STAGES = 1  *********************
******************************************************************************/
generate if (C_MPMC_PIM_PIPE_STAGES == 1)
begin

    // Generating mc_miaddrreadytoaccept
    always@(posedge MPMC_Clk)
    begin
        if ((MPMC_Rst == 1'b1) | (mi_mcaddressvalid == 1'b1) | 
            (MPMC_PIM_InitDone == 1'b0) | (wrFIFO_space_available == 1'b0))
            mc_miaddrreadytoaccept_int <= 1'b0;
        else
            if (MPMC_PIM_AddrReq == 1'b1)
                mc_miaddrreadytoaccept_int <= MPMC_PIM_AddrAck;
            else
                mc_miaddrreadytoaccept_int <= 1'b1;
    end
    
    always@* mc_miaddrreadytoaccept <= mc_miaddrreadytoaccept_int & 
                                       ~ mi_mcaddressvalid;

end
endgenerate
/******************************************************************************
*************** END Generate for C_MPMC_PIM_PIPE_STAGES = 1  ******************
******************************************************************************/

/******************************************************************************
************    Generate for C_MPMC_PIM_PIPE_STAGES = 1 OR ********************
**********(C_MPMC_PIM_PIPE_STAGES = 2 AND *************************************
*******(C_MPMC_PIM_DATA_WIDTH != 64) AND (C_MPMC_PIM_BURST_LENGTH != 2))*******
******************************************************************************/
generate if (C_MPMC_PIM_PIPE_STAGES == 1 | 
             (C_MPMC_PIM_PIPE_STAGES == 2 & 
              (C_MPMC_PIM_DATA_WIDTH == 32 | 
              (C_MPMC_PIM_DATA_WIDTH == 64 & C_MPMC_PIM_BURST_LENGTH != 2))))
begin

    /////////////////////////////////////////////////////////////////////////
    // Address Req generation ///////////////////////////////////////////////
    // addrReq_d1 becomes high when address valid goes high, and stays high /
    // till address ack become high /////////////////////////////////////////
    always@(posedge MPMC_Clk)
    begin
      if (MPMC_Rst == 1'b1 )
          addrReq_d1 <= 1'b0;
      else
          addrReq_d1 <= ~(MPMC_PIM_AddrAck == 1'b1) & 
                        ((mi_mcaddressvalid == 1'b1) | addrReq_d1);
    end

    // ADDRESS GENERATION////////////////////////////////////////////////////
    // Register the address from MIB, when the address valid signal goes high
    always@(posedge MPMC_Clk)
    begin
        if(mi_mcaddressvalid == 1'b1)
            mi_mcaddress_d1 <= mi_mcaddress[(35-C_MPMC_PIM_ADDR_WIDTH+1):35]
                                + C_MPMC_PIM_OFFSET;
        else
            mi_mcaddress_d1 <= mi_mcaddress_d1;
    end

    always@* MPMC_PIM_Addr = mi_mcaddress_d1;

    /////////////////////////////////////////////////////////////////////////
    /////// RNW Generation //////////////////////////////////////////////////
    // When address valid is high, read not write is same as MIB            /
    // read not write, when the address valid is low, the rnw_d1 is passed //
    always@(posedge MPMC_Clk)
    begin
        if (mi_mcaddressvalid == 1'b1)
            rnw_d1 <= mi_mcreadnotwrite;
        else
            rnw_d1 <=  rnw_d1;
    end

    always@* MPMC_PIM_RNW = rnw_d1;
    
////  Generate if C_MPMC_PIM_DATA_WIDTH=32 and C_MPMC_PIM_BURST_LENGTH=8 and 
////  C_MPMC_PIM_MEM_DATA_WIDTH == 128
//    if (C_MPMC_PIM_DATA_WIDTH == 32 & C_MPMC_PIM_BURST_LENGTH == 8 & 
//         C_MPMC_PIM_MEM_DATA_WIDTH == 128) 
//    begin
//
//          // Counting number of MPMC_PIM_WrFIFO_Push/mi_mcwritedatavalid
//          always@(posedge MPMC_Clk)
//          begin
//              if (MPMC_Rst == 1'b1 | mi_mcaddressvalid == 1'b1)
//                  push_cntr <= 0;
//              else
//                  if (mi_mcwritedatavalid == 1'b1 & push_cntr[1] == 1'b0)
//                      push_cntr <=  push_cntr + 1;
//          end  
//         
//          // Counting number of MPMC_PIM_WrFIFO_Push/mi_mcwritedatavalid
//          always@(posedge MPMC_Clk)
//          begin
//              if (MPMC_Rst == 1'b1)
//                  MPMC_PIM_AddrReq <= 0;
//              else
//                  if(MPMC_PIM_AddrAck == 1'b1)
//                    MPMC_PIM_AddrReq <= 1'b0;
//                  else
//                      if (push_cntr[1] == 1'b1)
//                          MPMC_PIM_AddrReq <=  addrReq_d1;
//          end 
//
//    end
//
////  Generate if C_MPMC_PIM_DATA_WIDTH!=32 & C_MPMC_PIM_BURST_LENGTH!=8
//    else
    always@* MPMC_PIM_AddrReq = addrReq_d1; 

end
endgenerate
/******************************************************************************
********** End of generate for C_MPMC_PIM_PIPE_STAGES = 1 OR ******************
**********(C_MPMC_PIM_PIPE_STAGES = 2 AND *************************************
*******(C_MPMC_PIM_DATA_WIDTH != 64) AND (C_MPMC_PIM_BURST_LENGTH != 2))*******
******************************************************************************/

/******************************************************************************
*****************Generate for C_MPMC_PIM_PIPE_STAGES = 2  *********************
******************************************************************************/
generate if (C_MPMC_PIM_PIPE_STAGES == 2) 
begin

//  Generate if C_MPMC_PIM_DATA_WIDTH=64 & C_MPMC_PIM_BURST_LENGTH=2
    if (C_MPMC_PIM_DATA_WIDTH == 64 & C_MPMC_PIM_BURST_LENGTH == 2)
    begin
        // Generating mc_miaddrreadytoaccept
        ////////////////////////////////////
        always@(posedge MPMC_Clk)
        begin
            if (MPMC_Rst == 1'b1 )
                mc_miaddrreadytoaccept <= 0;
            else
                mc_miaddrreadytoaccept <=  MPMC_PIM_InitDone & wrFIFO_space_available
                                           & ~ (mi_mcaddressvalid | req_1)
                                           & (~req_2 | req_2 & MPMC_PIM_AddrAck);
        end

      // Generating MPMC_PIM_AddrReq
        ////////////////////////////////////
        // Generating req_1
        always@(posedge MPMC_Clk)
        begin
            if (MPMC_Rst == 1'b1 | (req_1 == 1 & MPMC_PIM_AddrAck == 1 & 
                                    received_first_ack == 0))
                req_1 <= 0;
            else 
                if (mi_mcaddressvalid == 1 & (req_2 == 1 | received_first_ack == 0))
                    req_1 <= 1;
                else
                    req_1 <= req_1;
        end

        // Generating req_2
        always@(posedge MPMC_Clk)
        begin
            if (MPMC_Rst == 1'b1 | (received_first_ack == 1 & MPMC_PIM_AddrAck == 1))
                req_2 <= 0;
            else 
                if (mi_mcaddressvalid == 1 & (req_1 == 1 | received_first_ack == 1))
                    req_2 <= 1;
                else
                    req_2 <= req_2;
        end

        always@(posedge MPMC_Clk)
        begin
            if (mi_mcaddressvalid == 1)
                MPMC_PIM_AddrReq <= 1;
            else
                if (req_1 == 1 & MPMC_PIM_AddrAck == 1)
                    MPMC_PIM_AddrReq <= req_2;
                else
                    if (req_2 == 1 & MPMC_PIM_AddrAck == 1)
                        MPMC_PIM_AddrReq <= req_1;
                    else
                        MPMC_PIM_AddrReq <= req_1 | req_2;
        end

        // Generating received_first_ack
        always@(posedge MPMC_Clk)
        begin
            if (MPMC_Rst == 1'b1 | (received_first_ack == 1 & MPMC_PIM_AddrAck == 1))
                received_first_ack <= 0;
            else
                if (req_1 == 1 & MPMC_PIM_AddrAck == 1)
                    received_first_ack <= 1;
                else
                    received_first_ack <= received_first_ack;
        end

      // Generating MPMC_PIM_Addr & MPMC_PIM_RNW
      ////////////////////////////////////
        // Generating rnw_1
        always@(posedge MPMC_Clk)
        begin
            if(MPMC_Rst == 1'b1)
                rnw_1 <= 0;
            else 
                if (mi_mcaddressvalid == 1 & req_1 == 0)
                    rnw_1 <= mi_mcreadnotwrite;
        end

        // Generating addr_1 & rnw_1
        always@(posedge MPMC_Clk)
        begin
            if (mi_mcaddressvalid == 1 & req_1 == 0)
                addr_1 <= mi_mcaddress[(35-C_MPMC_PIM_ADDR_WIDTH+1):35]
                                    + C_MPMC_PIM_OFFSET;
        end

        // Generating rnw_2
        always@(posedge MPMC_Clk)
        begin
            if(MPMC_Rst == 1'b1)
                rnw_2 <= 0;
            else 
                if (mi_mcaddressvalid == 1 & (req_1 == 1 | received_first_ack == 1)
                  & req_2 == 0)
                    rnw_2 <= mi_mcreadnotwrite;
        end

        // Generating addr_2 & rnw_2
        always@(posedge MPMC_Clk)
        begin
            if (mi_mcaddressvalid == 1 & (req_1 == 1 | received_first_ack == 1)
                  & req_2 == 0)
                addr_2 <= mi_mcaddress[(35-C_MPMC_PIM_ADDR_WIDTH+1):35]
                                    + C_MPMC_PIM_OFFSET;
        end

        // Generating MPMC_PIM_Addr & MPMC_PIM_RNW
        always@(posedge MPMC_Clk)
        begin
            if (mi_mcaddressvalid == 1 & req_1 == 0 & req_2 == 0)
            begin
                MPMC_PIM_Addr <= mi_mcaddress[(35-C_MPMC_PIM_ADDR_WIDTH+1):35];
                MPMC_PIM_RNW <= mi_mcreadnotwrite;
            end
            else
                if ((req_1 == 1 & MPMC_PIM_AddrAck == 1) | received_first_ack == 1)
                begin
                    MPMC_PIM_Addr <= addr_2;
                    MPMC_PIM_RNW <= rnw_2;
                end
                else
                begin
                    MPMC_PIM_Addr <= addr_1;
                    MPMC_PIM_RNW <= rnw_1;
                end
        end
    end

    else
//  Generate if C_MPMC_PIM_DATA_WIDTH!=64 & C_MPMC_PIM_BURST_LENGTH!=2
      // Generating mc_miaddrreadytoaccept
        always@(posedge MPMC_Clk)
        begin
            if (MPMC_Rst == 1'b1 )
                mc_miaddrreadytoaccept <= 0;
            else
                mc_miaddrreadytoaccept <=  MPMC_PIM_InitDone & wrFIFO_space_available
                                         & ~ mi_mcaddressvalid 
                                         & (~ MPMC_PIM_AddrReq | MPMC_PIM_AddrAck);
        end 

end
endgenerate
/******************************************************************************
*************** END Generate for C_MPMC_PIM_PIPE_STAGES = 2  ******************
******************************************************************************/

//
// Size generation for C_MPMC_PIM_DATA_WIDTH == 64 ////////////////////////////
generate 
    if (C_MPMC_PIM_DATA_WIDTH == 64 & C_MPMC_PIM_BURST_LENGTH == 2 )
        assign MPMC_PIM_Size = BURST_SIZE_4;
    else if (C_MPMC_PIM_DATA_WIDTH == 64 & C_MPMC_PIM_BURST_LENGTH == 4 )
        assign MPMC_PIM_Size = BURST_SIZE_8;
    else if (C_MPMC_PIM_DATA_WIDTH == 64 & C_MPMC_PIM_BURST_LENGTH == 8 )
        assign MPMC_PIM_Size = BURST_SIZE_16;
        
// Size generation for C_MPMC_PIM_DATA_WIDTH == 32 ////////////////////////////
    else if (C_MPMC_PIM_DATA_WIDTH == 32 & C_MPMC_PIM_BURST_LENGTH == 4)
        assign MPMC_PIM_Size = BURST_SIZE_4;
    else if (C_MPMC_PIM_DATA_WIDTH == 32 & C_MPMC_PIM_BURST_LENGTH == 8 )
        assign MPMC_PIM_Size = BURST_SIZE_8;
endgenerate

//////////////// RdModWr Generation ///////////////////////////////////////////
    assign MPMC_PIM_RdModWr = 1'b1;

                  /************************************
                  ***** END of ADDRESS PATH LOGIC *****
                  *************************************/


                 /*************************************
                 ******** WRITE DATA PATH LOGIC *******
                 *************************************/
    genvar i;
    // Byte reordering within write data bus, Big Endian to Little Endian
    generate
      for (i = 0; i < C_MPMC_PIM_DATA_WIDTH; i = i + 8) begin : wrdata_reorder
        assign MPMC_PIM_WrFIFO_Data[i+7 : i] = mi_mcwritedata[i : i+7];
      end
    endgenerate

    genvar k;
    // Big Endian to Little Endian conversion for Byte Enable
    generate
      for (k = 0; k < (C_MPMC_PIM_DATA_WIDTH/8); k = k + 1) begin : be_reorder
        assign MPMC_PIM_WrFIFO_BE[k] = mi_mcbyteenable[k];
      end
    endgenerate


    assign MPMC_PIM_WrFIFO_Push = mi_mcwritedatavalid;

///////////////////////////////////////////////////////////////////////////////

//////////// Generation of wrFIFO_space_available /////////////////////////////
// When the type of the FIFO used in NPI is serial, the depth is 16. The
// space available in the FIFO when the burst length is 8 is for 2 8-word
// transactions, for burst length is 2 or 4 the space available is for 4 4-word
// transactions. When the burst length is 1, the space available is for 16
// double-word transactions.
generate
    if (C_MPMC_PIM_WRFIFO_TYPE == "SRL")
    begin
    
    // Counter that gets reset when the FIFO is empty or when reset is high, gets
    // incremented for every push of data
        always@(posedge MPMC_Clk)
        begin
            if(MPMC_Rst == 1'b1 | MPMC_PIM_WrFIFO_Empty == 1'b1)
                bst_cntr <= 0;
            else
                if (mi_mcaddressvalid == 1'b1 & mi_mcreadnotwrite == 1'b0)
                    bst_cntr <= bst_cntr + 1;
                else
                    bst_cntr <= bst_cntr;
        end
    
    // Logic for generating the signal wrFIFO_space_available depending on the
    // bst_cntr
    //////////////////////////////////////////////////////
    // The original code below is using four flops. //////
    //////////////////////////////////////////////////////
    /*
        if (C_MPMC_PIM_BURST_LENGTH == 2)
            assign wrFIFO_space_available = (bst_cntr == 4'b1000) ? 1'b0 : 1'b1;
        else if (C_MPMC_PIM_BURST_LENGTH == 4)
            assign wrFIFO_space_available = (bst_cntr == 4'b0100) ? 1'b0 : 1'b1;
        else if (C_MPMC_PIM_BURST_LENGTH == 8)
            assign wrFIFO_space_available = (bst_cntr[1] == 4'b0010) ? 1'b0 : 1'b1;
    */
    //////////////////////////////////////////////////////////////////////////
    // To reduce the numbe of Flops original code above is change as below. //
    //////////////////////////////////////////////////////////////////////////
        if (C_MPMC_PIM_BURST_LENGTH == 2)
            assign wrFIFO_space_available = ~ ( bst_cntr[3] );
        else if (C_MPMC_PIM_BURST_LENGTH == 4)
            assign wrFIFO_space_available = ~ ( bst_cntr[2] );
        else if (C_MPMC_PIM_BURST_LENGTH == 8)
            assign wrFIFO_space_available = ~ ( bst_cntr[1] );

    end
    else
        assign wrFIFO_space_available = 1'b1;

endgenerate
              /********************************************
              ***** END of WRITE DATA Data PATH LOGIC *****
              ********************************************/


             /*********************************************
             ************* READ DATA PATH LOGIC ***********
             *********************************************/

    // Read FIFO Pop generation //////////////////////////////////////////////
    // Whenever the Read FIFO is not empty, data can be popped out.
    assign MPMC_PIM_RdFIFO_Pop = ~MPMC_PIM_RdFIFO_Empty;

// When C_MPMC_PIM_RDFIFO_LATENCY is set to 0, Data and RdWdAddr are valid in /
// the same cycle as the pop signal. When C_MPMC_PIM_RDFIFO_LATENCY is set to /
// 1, Data and RdWdAddr are valid in the cycle following the pop signal. When /
// C_MPMC_PIM_RDFIFO_LATENCY is set to 2, Data and RdWdAddr are valid in two  /
// cycles following the pop signal.

//*****************************************************************************
// The original code below is commented to remove the dependency on 
// C_MPMC_PIM_RDFIFO_LATENCY as this parameter is not available in MPD on 
// MPMC2 NPI for user access.
// Later in MPMC3 when MIB PIM gets integrated this can be reverted back to
// origianl code below.
//*****************************************************************************
generate

    // When Latency=0
    if (C_MPMC_PIM_RDFIFO_LATENCY == 0)
        always@* mc_mireaddatavalid = MPMC_PIM_RdFIFO_Pop;

    // When Latency=1
    else if (C_MPMC_PIM_RDFIFO_LATENCY == 1)
// Logic for delaying the read FIFO pop signal ////////////////////////////////
        always@(posedge MPMC_Clk)
           if(MPMC_Rst == 1'b1)
               mc_mireaddatavalid <= 0;
           else
               mc_mireaddatavalid <= MPMC_PIM_RdFIFO_Pop;

    // When Latency=2
    else if (C_MPMC_PIM_RDFIFO_LATENCY == 2)
    begin
// Logic for delaying the read FIFO pop signal ////////////////////////////////
        always@(posedge MPMC_Clk)
        begin
           if(MPMC_Rst == 1'b1)
               begin
                   rdFIFO_Pop_d1 <= 0;
                   mc_mireaddatavalid <= 0;
               end
           else
               begin
                   rdFIFO_Pop_d1 <= MPMC_PIM_RdFIFO_Pop;
                   mc_mireaddatavalid <= rdFIFO_Pop_d1;
               end
        end
    end

endgenerate

//*****************************************************************************
// Below is the replacement of the origianl code above. The original code 
// above has to be retained when MIB PIM is integrated in MPMC3 and the code
// below has to be removed.
//*****************************************************************************
// Logic for delaying the read FIFO pop signal ////////////////////////////////
/*
    always@(posedge MPMC_Clk)
    begin
       if(MPMC_Rst == 1'b1)
           begin
               rdFIFO_Pop_d1 <= 0;
               rdFIFO_Pop_d2 <= 0;
           end
       else
           begin
               rdFIFO_Pop_d1 <= MPMC_PIM_RdFIFO_Pop;
               rdFIFO_Pop_d2 <= rdFIFO_Pop_d1;
           end
    end

    always@ (MPMC_PIM_Rd_FIFO_Latency or MPMC_PIM_RdFIFO_Pop or rdFIFO_Pop_d1 
                 or rdFIFO_Pop_d2)
    begin
       case (MPMC_PIM_Rd_FIFO_Latency)
           2'b00   : mc_mireaddatavalid = MPMC_PIM_RdFIFO_Pop;
           2'b01   : mc_mireaddatavalid = rdFIFO_Pop_d1;
           2'b10   : mc_mireaddatavalid = rdFIFO_Pop_d2;
           default : mc_mireaddatavalid = MPMC_PIM_RdFIFO_Pop;
       endcase
    end
*/
    genvar j;
    // Byte reordering within read data bus, Little Endian to Big Endian
    generate
      for (j = 0; j < C_MPMC_PIM_DATA_WIDTH; j = j + 8) begin : rddata_reorder
        assign mc_mireaddata[j : j+7] = MPMC_PIM_RdFIFO_Data[j+7 : j];
      end
    endgenerate

             /*********************************************
             ********* END of READ DATA PATH LOGIC ********
             *********************************************/

    assign mc_mireaddataerr      = 1'b0;
    assign MPMC_PIM_WrFIFO_Flush = 1'b0;
    assign MPMC_PIM_RdFIFO_Flush = 1'b0;


endmodule
