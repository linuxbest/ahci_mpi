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
// Naming Conventions:
//   active low signals:                    "*_n"
//   clock signals:                         "clk", "clk_div#", "clk_#x"
//   reset signals:                         "rst", "rst_n"
//   generics:                              "C_*"
//   user defined types:                    "*_TYPE"
//   state machine next state:              "*_ns"
//   state machine current state:           "*_cs"
//   combinatorial signals:                 "*_com"
//   pipelined or register delay signals:   "*_d#"
//   counter signals:                       "*cnt*"
//   clock enable signals:                  "*_ce"
//   internal version of output port:       "*_i"
//   device pins:                           "*_pin"
//   ports:                                 "- Names begin with Uppercase"
//   processes:                             "*_PROCESS"
//----------------------------------------------------------------------------
`timescale 1ns/1ns

module mpmc_ctrl_logic
#(
  parameter C_ECC_NUM_REG                   = 10,
  parameter C_STATIC_PHY_NUM_REG            = 1,
  parameter C_MPMC_STATUS_NUM_REG           = 1,
  parameter C_PM_CTRL_NUM_REG               = 21,
  parameter C_SLV_AWIDTH                    = 32,
  parameter C_SLV_DWIDTH                    = 32,
  parameter C_NUM_REG                       = 12,
  parameter C_NUM_MEM                       = 4
)
(
  // MPMC Control Registers
  input   wire                                  MPMC_Clk,
  output  reg  [C_ECC_NUM_REG-1:0]              ECC_Reg_CE,
  input   wire [C_ECC_NUM_REG*32-1:0]           ECC_Reg_Out,
  output  wire [31:0]                           ECC_Reg_In,
  output  reg  [C_STATIC_PHY_NUM_REG-1:0]       Static_Phy_Reg_CE,
  input   wire [C_STATIC_PHY_NUM_REG*32-1:0]    Static_Phy_Reg_Out,
  output  wire [31:0]                           Static_Phy_Reg_In,
  output  wire [0:31]                           Debug_Ctrl_Addr,
  output  wire                                  Debug_Ctrl_WE,
  input   wire [0:31]                           Debug_Ctrl_Out,
  output  wire [0:31]                           Debug_Ctrl_In,
  output  reg  [0:C_MPMC_STATUS_NUM_REG-1]      MPMC_Status_Reg_CE,
  input   wire [0:C_MPMC_STATUS_NUM_REG*32-1]   MPMC_Status_Reg_Out,
  output  wire [0:31]                           MPMC_Status_Reg_In,
  output  reg  [C_PM_CTRL_NUM_REG-1:0]          PM_Ctrl_Reg_CE,
  input   wire [C_PM_CTRL_NUM_REG*32-1:0]       PM_Ctrl_Reg_Out,
  output  wire [31:0]                           PM_Ctrl_Reg_In,
  input   wire [31:0]                           PM_Data_Out,
  output  wire [31:0]                           PM_Data_Addr,
                                                
  // Bus protocol ports                         
  input wire                                    Bus2IP_Clk,
  input wire                                    Bus2IP_Reset,
  input wire   [0 : C_SLV_AWIDTH-1]             Bus2IP_Addr,
  input wire   [0 : C_NUM_MEM-1]                Bus2IP_CS,
  input wire                                    Bus2IP_RNW,
  input wire   [0 : C_SLV_DWIDTH-1]             Bus2IP_Data,
  input wire   [0 : C_SLV_DWIDTH/8-1]           Bus2IP_BE,          // unused
  input wire   [0 : C_NUM_REG-1]                Bus2IP_RdCE,
  input wire   [0 : C_NUM_REG-1]                Bus2IP_WrCE,
  output wire  [0 : C_SLV_DWIDTH-1]             IP2Bus_Data,
  output wire                                   IP2Bus_RdAck,
  output wire                                   IP2Bus_WrAck,
  output wire                                   IP2Bus_Error
);

//----------------------------------------------------------------------------
// Local Parameters
//----------------------------------------------------------------------------

  // To help part-select vectors
  localparam  C_ECC_CE_INDEX        = C_ECC_NUM_REG;
  localparam  C_STATIC_PHY_CE_INDEX = C_ECC_CE_INDEX + C_STATIC_PHY_NUM_REG;
  localparam  C_MPMC_STATUS_CE_INDEX= C_STATIC_PHY_CE_INDEX + C_MPMC_STATUS_NUM_REG;
  localparam  C_PM_CTRL_CE_INDEX    = C_MPMC_STATUS_CE_INDEX + C_PM_CTRL_NUM_REG;

//----------------------------------------------------------------------------
// Implementation
//----------------------------------------------------------------------------
  wire                                      clk_enable;
  wire  [C_NUM_REG-1:0]                     bus2ip_rdce_i;
  wire  [C_NUM_REG-1:0]                     bus2ip_wrce_i;
  wire  [C_SLV_DWIDTH-1:0]                  bus2ip_data_i;

  wire  [C_ECC_NUM_REG-1:0]                 ecc_reg_write_sel;
  wire  [C_ECC_NUM_REG-1:0]                 ecc_reg_read_sel;
  reg   [C_SLV_DWIDTH-1:0]                  ecc_ip2bus_data;
  wire                                      ecc_write_ack;
  wire                                      ecc_read_ack;

  wire  [C_STATIC_PHY_NUM_REG-1:0]          static_phy_reg_write_sel;
  wire  [C_STATIC_PHY_NUM_REG-1:0]          static_phy_reg_read_sel;
  reg   [C_SLV_DWIDTH-1:0]                  static_phy_ip2bus_data;
  wire                                      static_phy_write_ack;
  wire                                      static_phy_read_ack;

  wire                                      debug_ctrl_write_ack;
  reg                                       debug_ctrl_write_ack_d1;
  reg                                       debug_ctrl_write_ack_d2;
  reg                                       debug_ctrl_write_ack_d3;
  wire                                      debug_ctrl_write_ack_delayed;
  wire                                      debug_ctrl_read_ack;
  reg                                       debug_ctrl_read_ack_d1;
  reg                                       debug_ctrl_read_ack_d2;
  reg                                       debug_ctrl_read_ack_d3;
  reg                                       debug_ctrl_read_ack_d4;
  wire                                      debug_ctrl_read_ack_delayed;

  wire  [C_MPMC_STATUS_NUM_REG-1:0]         mpmc_status_reg_write_sel;
  wire  [C_MPMC_STATUS_NUM_REG-1:0]         mpmc_status_reg_read_sel;
  reg   [C_SLV_DWIDTH-1:0]                  mpmc_status_ip2bus_data;
  wire                                      mpmc_status_write_ack;
  wire                                      mpmc_status_read_ack;

  wire  [C_PM_CTRL_NUM_REG-1:0]             pm_ctrl_reg_write_sel;
  wire  [C_PM_CTRL_NUM_REG-1:0]             pm_ctrl_reg_read_sel;
  reg   [C_SLV_DWIDTH-1:0]                  pm_ctrl_ip2bus_data;
  wire                                      pm_ctrl_write_ack;
  wire                                      pm_ctrl_read_ack;
  reg   [C_SLV_DWIDTH-1 : 0]                bus2ip_data_d1;

  wire                                      pm_data_write_ack;
  wire                                      pm_data_read_ack;
  wire                                      pm_data_read_ack_delayed;
  reg                                       pm_data_read_ack_d1;
  reg                                       pm_data_read_ack_d2;
  genvar                                    ecc_index;
  genvar                                    i;


///////////////////////////////////////////////////////////////////////////
// Handle Clocking Boundaries
///////////////////////////////////////////////////////////////////////////
  mpmc_sample_cycle
    mpmc_sample_cycle_0 (
      .sample_cycle(clk_enable),
      .slow_clk(Bus2IP_Clk),
      .fast_clk(MPMC_Clk)
  ); 


  // big endian -> little endian
  generate
    for (i = 0 ; i < C_NUM_REG ; i = i + 1)
      begin : wrce_big_to_little_endian
        assign bus2ip_wrce_i[i] = Bus2IP_WrCE[i];
      end
  endgenerate

  generate
    for (i = 0 ; i < C_NUM_REG ; i = i + 1)
      begin : rdce_big_to_little_endian
        assign bus2ip_rdce_i[i] = Bus2IP_RdCE[i];
      end
  endgenerate

  assign bus2ip_data_i[C_SLV_DWIDTH-1:0] = Bus2IP_Data[0:C_SLV_DWIDTH-1];

  assign
    ecc_reg_write_sel = bus2ip_wrce_i[C_ECC_CE_INDEX-1:0],
    ecc_reg_read_sel  = bus2ip_rdce_i[C_ECC_CE_INDEX-1:0],
    ecc_write_ack     = (|ecc_reg_write_sel),
    ecc_read_ack      = (|ecc_reg_read_sel);

  assign
    static_phy_reg_write_sel = bus2ip_wrce_i[C_STATIC_PHY_CE_INDEX-1:C_ECC_CE_INDEX],
    static_phy_reg_read_sel  = bus2ip_rdce_i[C_STATIC_PHY_CE_INDEX-1:C_ECC_CE_INDEX],
    static_phy_write_ack     = (|static_phy_reg_write_sel),
    static_phy_read_ack      = (|static_phy_reg_read_sel);

  assign
    mpmc_status_reg_write_sel = bus2ip_wrce_i[C_MPMC_STATUS_CE_INDEX-1:C_STATIC_PHY_CE_INDEX],
    mpmc_status_reg_read_sel  = bus2ip_rdce_i[C_MPMC_STATUS_CE_INDEX-1:C_STATIC_PHY_CE_INDEX],
    mpmc_status_write_ack     = (|mpmc_status_reg_write_sel),
    mpmc_status_read_ack      = (|mpmc_status_reg_read_sel);

  assign
    pm_ctrl_reg_write_sel = bus2ip_wrce_i[C_PM_CTRL_CE_INDEX-1:C_MPMC_STATUS_CE_INDEX],
    pm_ctrl_reg_read_sel  = bus2ip_rdce_i[C_PM_CTRL_CE_INDEX-1:C_MPMC_STATUS_CE_INDEX],
    pm_ctrl_write_ack     = (|pm_ctrl_reg_write_sel),
    pm_ctrl_read_ack      = (|pm_ctrl_reg_read_sel);


  // Registered outputs on MPMC_Clk domain
  always @(MPMC_Clk)
    begin: REG_CE
      ECC_Reg_CE <= ecc_reg_write_sel[0 +: C_ECC_NUM_REG] & {C_ECC_NUM_REG{clk_enable}};
      Static_Phy_Reg_CE <= static_phy_reg_write_sel[0 +: C_STATIC_PHY_NUM_REG] & {C_STATIC_PHY_NUM_REG{clk_enable}};
      MPMC_Status_Reg_CE <= mpmc_status_reg_write_sel[0 +: C_MPMC_STATUS_NUM_REG] & {C_MPMC_STATUS_NUM_REG{clk_enable}};
      PM_Ctrl_Reg_CE <= pm_ctrl_reg_write_sel[0 +: C_PM_CTRL_NUM_REG] & {C_PM_CTRL_NUM_REG{clk_enable}};
    end

  always @(Bus2IP_Clk)
    begin: OUT_TO_REG
      bus2ip_data_d1 <= bus2ip_data_i;
    end

  assign ECC_Reg_In = bus2ip_data_d1;
  assign Static_Phy_Reg_In = bus2ip_data_d1;
  assign MPMC_Status_Reg_In = bus2ip_data_d1;
  assign PM_Ctrl_Reg_In = bus2ip_data_d1;

  // mux the ECC input registers
  always @(*)
    case (1'b1)
      ecc_reg_read_sel[0]:
        ecc_ip2bus_data <= ECC_Reg_Out[0*32 +:32];
      ecc_reg_read_sel[1]:
        ecc_ip2bus_data <= ECC_Reg_Out[1*32 +:32];
      ecc_reg_read_sel[2]:
        ecc_ip2bus_data <= ECC_Reg_Out[2*32 +:32];
      ecc_reg_read_sel[3]:
        ecc_ip2bus_data <= ECC_Reg_Out[3*32 +:32];
      ecc_reg_read_sel[4]:
        ecc_ip2bus_data <= ECC_Reg_Out[4*32 +:32];
      ecc_reg_read_sel[5]:
        ecc_ip2bus_data <= ECC_Reg_Out[5*32 +:32];
      ecc_reg_read_sel[6]:
        ecc_ip2bus_data <= ECC_Reg_Out[6*32 +:32];
      ecc_reg_read_sel[7]:
        ecc_ip2bus_data <= ECC_Reg_Out[7*32 +:32];
      ecc_reg_read_sel[8]:
        ecc_ip2bus_data <= ECC_Reg_Out[8*32 +:32];
      ecc_reg_read_sel[9]:
        ecc_ip2bus_data <= ECC_Reg_Out[9*32 +:32];
      default:      
        ecc_ip2bus_data <= 32'b0 ;
    endcase

  // mux the static phy input registers
  always @(*)
    case (1'b1)
      static_phy_reg_read_sel[0]:
        static_phy_ip2bus_data <= Static_Phy_Reg_Out[0*32 +:32];
      default:      
        static_phy_ip2bus_data <= Static_Phy_Reg_Out[0*32 +:32];
    endcase

  // mux the static phy input registers
  always @(*)
    case (1'b1)
      mpmc_status_reg_read_sel[0]:
        mpmc_status_ip2bus_data <= MPMC_Status_Reg_Out[0*32 +:32];
      default:      
        mpmc_status_ip2bus_data <= MPMC_Status_Reg_Out[0*32 +:32];
    endcase

  // mux the PM_ctrl registers
  // 64 bit registers must have the words swapped
  always @(*)
    case (1'b1)
      // PMCTRL
      pm_ctrl_reg_read_sel[0]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[0*32 +:32];
      // PMCLR
      pm_ctrl_reg_read_sel[1]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[1*32 +:32];
      // PMSTATUS
      pm_ctrl_reg_read_sel[2]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[2*32 +:32];
      // UNUSED
      pm_ctrl_reg_read_sel[3]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[3*32 +:32];
      // PMGCC MSB (note the indexes here are swapped)
      pm_ctrl_reg_read_sel[4]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[5*32 +:32];
      // PMGCC LSB 
      pm_ctrl_reg_read_sel[5]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[4*32 +:32];
      // UNUSED
      pm_ctrl_reg_read_sel[6]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[6*32 +:32];
      // UNUSED
      pm_ctrl_reg_read_sel[7]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[7*32 +:32];
      // PMDCC0 MSB
      pm_ctrl_reg_read_sel[8]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[9*32 +:32];
      // PMDCC0 LSB
      pm_ctrl_reg_read_sel[9]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[8*32 +:32];
      // PMDCC1 MSB
      pm_ctrl_reg_read_sel[10]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[11*32 +:32];
      // PMDCC1 LSB
      pm_ctrl_reg_read_sel[11]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[10*32 +:32];
      // PMDCC2 MSB
      pm_ctrl_reg_read_sel[12]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[13*32 +:32];
      // PMDCC2 LSB
      pm_ctrl_reg_read_sel[13]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[12*32 +:32];
      // PMDCC3 MSB
      pm_ctrl_reg_read_sel[14]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[15*32 +:32];
      // PMDCC3 LSB
      pm_ctrl_reg_read_sel[15]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[14*32 +:32];
      // PMDCC4 MSB
      pm_ctrl_reg_read_sel[16]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[17*32 +:32];
      // PMDCC4 LSB
      pm_ctrl_reg_read_sel[17]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[16*32 +:32];
      // PMDCC5 MSB
      pm_ctrl_reg_read_sel[18]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[19*32 +:32];
      // PMDCC5 LSB
      pm_ctrl_reg_read_sel[19]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[18*32 +:32];
      // PMDCC6 MSB
      pm_ctrl_reg_read_sel[20]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[21*32 +:32];
      // PMDCC6 LSB
      pm_ctrl_reg_read_sel[21]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[20*32 +:32];
      // PMDCC7 MSB
      pm_ctrl_reg_read_sel[22]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[23*32 +:32];
      // PMDCC7 LSB
      pm_ctrl_reg_read_sel[23]:
        pm_ctrl_ip2bus_data <= PM_Ctrl_Reg_Out[22*32 +:32];
      default:      
        pm_ctrl_ip2bus_data <= 32'b0;
    endcase

  // handle PM DATA memory reads
  assign Debug_Ctrl_Addr = Bus2IP_Addr;
  assign Debug_Ctrl_WE   = debug_ctrl_write_ack & ~debug_ctrl_write_ack_d1 & clk_enable;
  assign Debug_Ctrl_In   = Bus2IP_Data;
  assign debug_ctrl_write_ack   = Bus2IP_CS[2] & ~Bus2IP_RNW;
  assign debug_ctrl_read_ack    = Bus2IP_CS[2] & Bus2IP_RNW;
  always @(posedge Bus2IP_Clk)
    begin
        debug_ctrl_read_ack_d1 <= debug_ctrl_read_ack;
        debug_ctrl_read_ack_d2 <= debug_ctrl_read_ack_d1;
        debug_ctrl_read_ack_d3 <= debug_ctrl_read_ack_d2;
        debug_ctrl_read_ack_d4 <= debug_ctrl_read_ack_d3;
        debug_ctrl_write_ack_d1 <= debug_ctrl_write_ack;
        debug_ctrl_write_ack_d2 <= debug_ctrl_write_ack_d1;
        debug_ctrl_write_ack_d3 <= debug_ctrl_write_ack_d2;
    end

  assign debug_ctrl_read_ack_delayed = debug_ctrl_read_ack_d3 & ~debug_ctrl_read_ack_d4;
  assign debug_ctrl_write_ack_delayed = debug_ctrl_write_ack_d2 & ~debug_ctrl_write_ack_d3;

  // handle PM DATA memory reads
  assign PM_Data_Addr = Bus2IP_Addr;
  assign pm_data_write_ack   = Bus2IP_CS[5] & ~Bus2IP_RNW;
  assign pm_data_read_ack    = Bus2IP_CS[5] & Bus2IP_RNW;
  always @(posedge Bus2IP_Clk)
    begin
        pm_data_read_ack_d1 <= pm_data_read_ack;
        pm_data_read_ack_d2 <= pm_data_read_ack_d1;
    end

  assign pm_data_read_ack_delayed = pm_data_read_ack_d1 & ~pm_data_read_ack_d2;
  // ------------------------------------------------------------
  // drive correct output to Bus signals
  // ------------------------------------------------------------

  assign IP2Bus_Data    = ecc_read_ack ? ecc_ip2bus_data 
                        : static_phy_read_ack ? static_phy_ip2bus_data
                        : debug_ctrl_read_ack_delayed ? Debug_Ctrl_Out 
                        : mpmc_status_read_ack ? mpmc_status_ip2bus_data 
                        : pm_ctrl_read_ack ? pm_ctrl_ip2bus_data : PM_Data_Out;
  assign IP2Bus_WrAck   = ecc_write_ack | static_phy_write_ack 
                        | debug_ctrl_write_ack_delayed | mpmc_status_write_ack 
                        | pm_ctrl_write_ack | pm_data_write_ack;
  assign IP2Bus_RdAck   = ecc_read_ack | static_phy_read_ack 
                        | debug_ctrl_read_ack_delayed | mpmc_status_read_ack
                        | pm_ctrl_read_ack
                        | pm_data_read_ack_delayed;

  assign IP2Bus_Error   = 0;

endmodule
