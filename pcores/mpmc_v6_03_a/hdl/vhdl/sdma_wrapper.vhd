-----------------------------------------------------------------------------
-- (c) Copyright 2006 - 2009 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-----------------------------------------------------------------------------
-- Filename:        sdma_wrapper.vhd
-- Description:       
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                sdma_wrapper.vhd
--                  |- sdma.vhd
--                      |- sample_cycle.vhd
--                      |- sdma_cntl.vhd
--                      |   |- ipic_if.vhd
--                      |   |   |-sample_cycle.vhd
--                      |   |- interrupt_register.vhd
--                      |   |- dmac_regfile_arb.vhd
--                      |   |- read_data_delay.vhd
--                      |   |- addr_arbiter.vhd
--                      |   |- port_arbiter.vhd
--                      |   |- tx_write_handler.vhd
--                      |   |- tx_read_handler.vhd
--                      |   |- tx_port_controller.vhd
--                      |   |- rx_read_handler.vhd
--                      |   |- rx_write_handler.vhd
--                      |   |- rx_port_controller.vhd
--                      |   |- tx_rx_state.vhd
--                      |
--                      |
--                      |- sdma_datapath.vhd
--                      |   |- reset_module.vhd
--                      |   |- channel_status_reg.vhd
--                      |   |- address_counter.vhd
--                      |   |- length_counter.vhd
--                      |   |- tx_byte_shifter.vhd
--                      |   |- rx_byte_shifter.vhd
--                  sdma_pkg.vhd
--
-------------------------------------------------------------------------------
-- @BEGIN_CHANGELOG EDK_J_SP2
--
--  Initial release
--
-- @END_CHANGELOG
-------------------------------------------------------------------------------
-- Author:      Tomai Knopp
-- History:
--  TK     06/04/07
-- ~~~~~~
--  - Initial EDK Release
-- ^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "LLink_Clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_com"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.numeric_std.all;    
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

library mpmc_v6_03_a;
use mpmc_v6_03_a.all;
use mpmc_v6_03_a.sdma_pkg.all;

-------------------------------------------------------------------------------
entity sdma_wrapper is
    generic (
        C_PI_BASEADDR           : integer := 0;
        C_PI_HIGHADDR           : integer := 0;
        C_PI_ADDR_WIDTH         : integer range 32 to 32    := 32;
        C_PI_DATA_WIDTH         : integer range 32 to 64    := 64;
        C_PI_BE_WIDTH           : integer range 4 to 8      := 8;
        C_PI_RDWDADDR_WIDTH     : integer range 4 to 4      := 4;
        C_SDMA_BASEADDR         : integer := 0;
        C_SDMA_HIGHADDR         : integer := 0;
        C_COMPLETED_ERR_TX      : integer range 0 to 1      := 1;
        C_COMPLETED_ERR_RX      : integer range 0 to 1      := 1;
        C_PRESCALAR             : integer range 0 to 1023   := 1023;
        C_PI_RDDATA_DELAY       : integer range 0 to 2      := 0;
        C_PI2LL_CLK_RATIO       : integer range 1 to 2      := 1;

        C_SPLB_P2P              : integer range 0 to 1      := 0;
            -- Optimize slave interface for a point to point connection
        C_SPLB_MID_WIDTH        : integer range 1 to 4      := 1;
            -- The width of the Master ID bus
            -- This is set to log2(C_SPLB_NUM_MASTERS)

        C_SPLB_NUM_MASTERS      : integer range 1 to 16     := 1;
            -- The number of Master Devices connected to the PLB bus
            -- Research this to find out default value

        C_SPLB_AWIDTH           : integer range 32 to 32    := 32;
            --  width of the PLB Address Bus (in bits)

        C_SPLB_DWIDTH           : integer range 32 to 128   := 32;
            --  Width of the PLB Data Bus (in bits)

        C_SPLB_NATIVE_DWIDTH    : integer range 32 to 32    := 32;
            --  Width of IPIF Data Bus (in bits)

        C_FAMILY                : string := "virtex5"
            -- Select the target architecture type
            -- see the family.vhd package in the proc_common
            -- library

    );
    port (

        LLink_Clk           : in  std_logic;
        PI_CLK              : in  std_logic;

        -- PLB Slave Input signals
        SPLB_Clk            : in  std_logic;
        SPLB_Rst            : in  std_logic;
        PLB_ABus            : in  std_logic_vector(0 to 31);
        PLB_UABus           : in  std_logic_vector(0 to 31);
        PLB_PAValid         : in  std_logic;
        PLB_SAValid         : in  std_logic;
        PLB_rdPrim          : in  std_logic;
        PLB_wrPrim          : in  std_logic;
        PLB_masterID        : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
        PLB_abort           : in  std_logic;
        PLB_busLock         : in  std_logic;
        PLB_RNW             : in  std_logic;
        PLB_BE              : in  std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1);
        PLB_MSize           : in  std_logic_vector(0 to 1);
        PLB_size            : in  std_logic_vector(0 to 3);
        PLB_type            : in  std_logic_vector(0 to 2);
        PLB_lockErr         : in  std_logic;
        PLB_wrDBus          : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
        PLB_wrBurst         : in  std_logic;
        PLB_rdBurst         : in  std_logic;
        PLB_wrPendReq       : in  std_logic;
        PLB_rdPendReq       : in  std_logic;
        PLB_wrPendPri       : in  std_logic_vector(0 to 1);
        PLB_rdPendPri       : in  std_logic_vector(0 to 1);
        PLB_reqPri          : in  std_logic_vector(0 to 1);
        PLB_TAttribute      : in  std_logic_vector(0 to 15);

        -- PLB Slave Response Signals
        Sln_addrAck         : out std_logic;
        Sln_SSize           : out std_logic_vector(0 to 1);
        Sln_wait            : out std_logic;
        Sln_rearbitrate     : out std_logic;
        Sln_wrDAck          : out std_logic;
        Sln_wrComp          : out std_logic;
        Sln_wrBTerm         : out std_logic;
        Sln_rdDBus          : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
        Sln_rdWdAddr        : out std_logic_vector(0 to 3);
        Sln_rdDAck          : out std_logic;
        Sln_rdComp          : out std_logic;
        Sln_rdBTerm         : out std_logic;
        Sln_MBusy           : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
        Sln_MWrErr          : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
        Sln_MRdErr          : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
        Sln_MIRQ            : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);


        -- MPMC Port Interface
        PI_Addr                 : out std_logic_vector(C_PI_ADDR_WIDTH-1 downto 0);
        PI_AddrReq              : out std_logic;
        PI_AddrAck              : in  std_logic;
        PI_RdModWr              : out std_logic;
        PI_RNW                  : out std_logic;
        PI_Size                 : out std_logic_vector(3 downto 0);
        PI_WrFIFO_Data          : out std_logic_vector(C_PI_DATA_WIDTH-1 downto 0);
        PI_WrFIFO_BE            : out std_logic_vector(C_PI_BE_WIDTH-1 downto 0);
        PI_WrFIFO_Push          : out std_logic;
        PI_RdFIFO_Data          : in  std_logic_vector(C_PI_DATA_WIDTH-1 downto 0);
        PI_RdFIFO_Pop           : out std_logic;
        PI_RdFIFO_RdWdAddr      : in  std_logic_vector(C_PI_RDWDADDR_WIDTH-1 downto 0);
        PI_WrFIFO_AlmostFull    : in  std_logic;
        PI_WrFIFO_Empty         : in  std_logic;
        PI_WrFIFO_Flush         : out std_logic;
        PI_RdFIFO_DataAvailable : in  std_logic;
        PI_RdFIFO_Empty         : in  std_logic;
        PI_RdFIFO_Flush         : out std_logic;
        
        -- TX Local Link Interface
        TX_D                    : out std_logic_vector(0 to 31);
        TX_Rem                  : out std_logic_vector(0 to 3);
        TX_SOF                  : out std_logic;
        TX_EOF                  : out std_logic;
        TX_SOP                  : out std_logic;
        TX_EOP                  : out std_logic;
        TX_Src_Rdy              : out std_logic;
        TX_Dst_Rdy              : in  std_logic;
        -- RX Local Link Interface
        RX_D                    : in  std_logic_vector(0 to 31);
        RX_Rem                  : in  std_logic_vector(0 to 3);
        RX_SOF                  : in  std_logic;
        RX_EOF                  : in  std_logic;
        RX_SOP                  : in  std_logic;
        RX_EOP                  : in  std_logic;
        RX_Src_Rdy              : in  std_logic;
        RX_Dst_Rdy              : out std_logic;
        
        -- SDMA System Interface
        SDMA_RstOut             : out std_logic;
        SDMA_Rx_IntOut          : out std_logic;
        SDMA_Tx_IntOut          : out std_logic
    );

end sdma_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_wrapper is

  begin
    comp_sdma : entity mpmc_v6_03_a.sdma
      generic map(
          C_PI_BASEADDR           => conv_std_logic_vector(C_PI_BASEADDR, 30) & "00",
          C_PI_HIGHADDR           => conv_std_logic_vector(C_PI_HIGHADDR, 30) & "11",
          C_PI_ADDR_WIDTH         => C_PI_ADDR_WIDTH,
          C_PI_DATA_WIDTH         => C_PI_DATA_WIDTH,
          C_PI_BE_WIDTH           => C_PI_BE_WIDTH,
          C_PI_RDWDADDR_WIDTH     => C_PI_RDWDADDR_WIDTH,
          C_SDMA_BASEADDR         => conv_std_logic_vector(C_SDMA_BASEADDR, 30) & "00",
          C_SDMA_HIGHADDR         => conv_std_logic_vector(C_SDMA_HIGHADDR, 30) & "11",
          C_COMPLETED_ERR_TX      => C_COMPLETED_ERR_TX,
          C_COMPLETED_ERR_RX      => C_COMPLETED_ERR_RX,
          C_PRESCALAR             => C_PRESCALAR,          
          C_PI_RDDATA_DELAY       => C_PI_RDDATA_DELAY ,   
          C_PI2LL_CLK_RATIO       => C_PI2LL_CLK_RATIO,    
          C_SPLB_P2P              => C_SPLB_P2P,           
          C_SPLB_MID_WIDTH        => C_SPLB_MID_WIDTH,     
          C_SPLB_NUM_MASTERS      => C_SPLB_NUM_MASTERS,   
          C_SPLB_AWIDTH           => C_SPLB_AWIDTH,        
          C_SPLB_DWIDTH           => C_SPLB_DWIDTH,        
          C_SPLB_NATIVE_DWIDTH    => C_SPLB_NATIVE_DWIDTH, 
          C_FAMILY                => C_FAMILY             
      )
      port map(
          LLink_Clk           => LLink_Clk          , 
          PI_CLK              => PI_CLK             , 
          SPLB_Clk            => SPLB_Clk           , 
          SPLB_Rst            => SPLB_Rst           , 
          PLB_ABus            => PLB_ABus           , 
          PLB_UABus           => PLB_UABus          , 
          PLB_PAValid         => PLB_PAValid        , 
          PLB_SAValid         => PLB_SAValid        , 
          PLB_rdPrim          => PLB_rdPrim         , 
          PLB_wrPrim          => PLB_wrPrim         , 
          PLB_masterID        => PLB_masterID       , 
          PLB_abort           => PLB_abort          , 
          PLB_busLock         => PLB_busLock        , 
          PLB_RNW             => PLB_RNW            , 
          PLB_BE              => PLB_BE             , 
          PLB_MSize           => PLB_MSize          , 
          PLB_size            => PLB_size           , 
          PLB_type            => PLB_type           , 
          PLB_lockErr         => PLB_lockErr        , 
          PLB_wrDBus          => PLB_wrDBus         , 
          PLB_wrBurst         => PLB_wrBurst        , 
          PLB_rdBurst         => PLB_rdBurst        , 
          PLB_wrPendReq       => PLB_wrPendReq      , 
          PLB_rdPendReq       => PLB_rdPendReq      , 
          PLB_wrPendPri       => PLB_wrPendPri      , 
          PLB_rdPendPri       => PLB_rdPendPri      , 
          PLB_reqPri          => PLB_reqPri         , 
          PLB_TAttribute      => PLB_TAttribute     , 
          Sln_addrAck         => Sln_addrAck        , 
          Sln_SSize           => Sln_SSize          , 
          Sln_wait            => Sln_wait           , 
          Sln_rearbitrate     => Sln_rearbitrate    , 
          Sln_wrDAck          => Sln_wrDAck         , 
          Sln_wrComp          => Sln_wrComp         , 
          Sln_wrBTerm         => Sln_wrBTerm        , 
          Sln_rdDBus          => Sln_rdDBus         , 
          Sln_rdWdAddr        => Sln_rdWdAddr       , 
          Sln_rdDAck          => Sln_rdDAck         , 
          Sln_rdComp          => Sln_rdComp         , 
          Sln_rdBTerm         => Sln_rdBTerm        , 
          Sln_MBusy           => Sln_MBusy          , 
          Sln_MWrErr          => Sln_MWrErr         , 
          Sln_MRdErr          => Sln_MRdErr         , 
          Sln_MIRQ            => Sln_MIRQ           , 
          PI_Addr                 => PI_Addr                , 
          PI_AddrReq              => PI_AddrReq             , 
          PI_AddrAck              => PI_AddrAck             , 
          PI_RdModWr              => PI_RdModWr             , 
          PI_RNW                  => PI_RNW                 , 
          PI_Size                 => PI_Size                , 
          PI_WrFIFO_Data          => PI_WrFIFO_Data         , 
          PI_WrFIFO_BE            => PI_WrFIFO_BE           , 
          PI_WrFIFO_Push          => PI_WrFIFO_Push         , 
          PI_RdFIFO_Data          => PI_RdFIFO_Data         , 
          PI_RdFIFO_Pop           => PI_RdFIFO_Pop          , 
          PI_RdFIFO_RdWdAddr      => PI_RdFIFO_RdWdAddr     , 
          PI_WrFIFO_AlmostFull    => PI_WrFIFO_AlmostFull   , 
          PI_WrFIFO_Empty         => PI_WrFIFO_Empty        , 
          PI_WrFIFO_Flush         => PI_WrFIFO_Flush        , 
          PI_RdFIFO_DataAvailable => PI_RdFIFO_DataAvailable, 
          PI_RdFIFO_Empty         => PI_RdFIFO_Empty        , 
          PI_RdFIFO_Flush         => PI_RdFIFO_Flush        , 
          TX_D                    => TX_D                   , 
          TX_Rem                  => TX_Rem                 , 
          TX_SOF                  => TX_SOF                 , 
          TX_EOF                  => TX_EOF                 , 
          TX_SOP                  => TX_SOP                 , 
          TX_EOP                  => TX_EOP                 , 
          TX_Src_Rdy              => TX_Src_Rdy             , 
          TX_Dst_Rdy              => TX_Dst_Rdy             , 
          RX_D                    => RX_D                   , 
          RX_Rem                  => RX_Rem                 , 
          RX_SOF                  => RX_SOF                 , 
          RX_EOF                  => RX_EOF                 , 
          RX_SOP                  => RX_SOP                 , 
          RX_EOP                  => RX_EOP                 , 
          RX_Src_Rdy              => RX_Src_Rdy             , 
          RX_Dst_Rdy              => RX_Dst_Rdy             , 
          SDMA_RstOut             => SDMA_RstOut            , 
          SDMA_Rx_IntOut          => SDMA_Rx_IntOut         , 
          SDMA_Tx_IntOut          => SDMA_Tx_IntOut          
      );

end implementation;
