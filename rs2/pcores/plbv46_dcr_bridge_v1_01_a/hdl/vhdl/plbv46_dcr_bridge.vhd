-------------------------------------------------------------------------------
-- plbv46_dcr_bridge - entity / architecture pair
-------------------------------------------------------------------------------
--
-- ***************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2001, 2002, 2004, 2005, 2006, 2008, 2009 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
-- ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:    plbv46_dcr_bridge.vhd
-- Version:     v1.01.a
-- Description: Top level of plbv46_dcr Bridge core
--              Instantiates plbv46_dcr_bridge_core and plbv46_slave_single v1.01.a
--              as Component and interfacing
--
-------------------------------------------------------------------------------
-- Structure:
--              plbv46_dcr_bridge.vhd
--                  -- plbv46_dcr_bridge_core.vhd
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Author   : SK
-- History  :
-- ~~~~~~
-- SK         2006/09/19      -- Initial version.
-- ^^^^^^
-- ~~~~~~
-- SK         2008/12/15      -- Updated version v1_01_a, based upon v1_00_a core.
--                            -- updated proc_common_v3_00_a and plbv46_slave_
--                            -- single_v1_01_a core libraries.
-- ^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_cmb"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
-- Short Description of the plbv46_dcr_bridge.vhd code.
-- This file includes the interfacing of plbv46_dcr_bridge.vhd and
-- plbv46_single_slave_v1_00_a signals.
-------------------------------------------------------------------------------
-- Generic & Port Declarations
-------------------------------------------------------------------------------
------------------------------------------
-- == Definition of Generics == 
------------------------------------------
--      C_BASEADDR            -- User logic base address
--      C_HIGHADDR            -- User logic high address
--      C_SPLB_AWIDTH         -- PLBv46 address bus width
--      C_SPLB_DWIDTH         -- PLBv46 data bus width
--      C_FAMILY              -- Default family
--      C_SPLB_P2P            -- Selects point-to-point or shared plb topology                  
--      C_SPLB_MID_WIDTH      -- PLB Master ID Bus Width                        
--      C_SPLB_NUM_MASTERS    -- Number of PLB Masters          
--      C_SPLB_NATIVE_DWIDTH  -- Width of the slave data bus
--      C_SPLB_SUPPORT_BURSTS -- Burst support

-- Definition of Ports:
-- == 
------------------------------------------
-- PLB_ABus           -- Each master is required to provide a valid 32-bit 
--                    -- address when its request signal is asserted. The PLB
--                    -- will then arbitrate the requests and allow the highest 
--                    -- priority master’s address to be gated onto the PLB_ABus
-- PLB_PAValid        -- This signal is asserted by the PLB arbiter in response 
--                    -- to the assertion of Mn_request and to indicate
--                    -- that there is a valid primary address and transfer 
--                    -- qualifiers on the PLB outputs
-- PLB_masterID       -- These signals indicate to the slaves the identification 
--                    -- of the master of the current transfer
-- PLB_RNW            -- This signal is driven by the master and is used to 
--                    -- indicate whether the request is for a read or a write
--                    -- transfer
-- PLB_BE             -- These signals are driven by the master. For a non-line 
--                    -- and non-burst transfer they identify which
--                    -- bytes of the target being addressed are to be read 
--                    -- from or written to. Each bit corresponds to a byte
--                    -- lane on the read or write data bus
-- PLB_size           -- The PLB_size(0:3) signals are driven by the master 
--                    -- to indicate the size of the requested transfer.
-- PLB_type           -- The Mn_type signals are driven by the master and are
--                    -- used to indicate to the slave, via the PLB_type
--                    -- signals, the type of transfer being requested
-- PLB_wrDBus         -- This data bus is used to transfer data between a 
--                    -- master and a slave during a PLB write transfer
------------------------------------------
-- == SLAVE DCR BRIDGE RESPONSE SIGNALS ==
------------------------------------------
-- Sl_addrAck          -- This signal is asserted to indicate that the 
--                     -- slave has acknowledged the address and will 
--                     -- latch the address
-- Sl_SSize            -- The Sl_SSize(0:1) signals are outputs of all 
--                     -- non 32-bit PLB slaves. These signals are 
--                     -- activated by the slave with the assertion of 
--                     -- PLB_PAValid or SAValid and a valid slave 
--                     -- address decode and must remain negated at 
--                     -- all other times.           
-- Sl_wait             -- This signal is asserted to indicate that the 
--                     -- slave has recognized the PLB address as a valid address
-- Sl_rearbitrate      -- This signal is asserted to indicate that the 
--                     -- slave is unable to perform the currently 
--                     -- requested transfer and require the PLB arbiter
--                     -- to re-arbitrate the bus
-- Sl_wrDAck           -- This signal is driven by the slave for a write 
--                     -- transfer to indicate that the data currently on the
--                     -- PLB_wrDBus bus is no longer required by the slave 
--                     -- i.e. data is latched
-- Sl_wrComp           -- This signal is asserted by the slave to 
--                     -- indicate the end of the current write transfer.
-- Sl_rdDBus           -- Slave read bus
-- Sl_rdDAck           -- This signal is driven by the slave to indicate 
--                     -- that the data on the Sl_rdDBus bus is valid and 
--                     -- must be latched at the end of the current clock cycle
-- Sl_rdComp           -- This signal is driven by the slave and is used
--                     -- to indicate to the PLB arbiter that the read 
--                     -- transfer is either complete, or will be complete 
--                     -- by the end of the next clock cycle
-- Sl_MBusy            -- These signals are driven by the slave and 
--                     -- are used to indicate that the slave is either 
--                     -- busy performing a read or a write transfer, or
--                     -- has a read or write transfer pending
-- Sl_MWrErr           -- These signals are driven by the slave and 
--                     -- are used to indicate that the slave has encountered an
--                     -- error during a write transfer that was initiated 
--                     -- by this master
-- Sl_MRdErr           -- These signals are driven by the slave and are 
--                     -- used to indicate that the slave has encountered an
--                     -- error during a read transfer that was initiated 
--                     -- by this master
------------------------------------------
-- == SIGNALS FROM PLBV46DCR_CORE TO THE DCR SLAVE DEVICE -- ==
------------------------------------------
--  DCR_plbAck       -- DCR Slave ACK in
--  DCR_plbDBusIn    -- DCR to PLB data bus in

--  PLB_dcrRead      -- PLB to DCR read out to slave
--  PLB_dcrWrite     -- PLB to DCR write out to slave
--  PLB_dcrABus      -- PLB to DCR address bus out to slave
--  PLB_dcrDBusOut   -- PLB to DCR data bus out to slave
--  PLB_dcrClk       -- DCR clock for the slave devices
--  PLB_dcrRst       -- DCR reset for the slave devices
-------------------------------------------------------------------------------
library IEEE;
    use IEEE.Std_Logic_1164.all;

library proc_common_v3_00_a;
    use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;
    use proc_common_v3_00_a.ipif_pkg.INTEGER_ARRAY_TYPE;
    use proc_common_v3_00_a.ipif_pkg.calc_num_ce;

library plbv46_slave_single_v1_01_a;

library plbv46_dcr_bridge_v1_01_a;

-------------------------------------------------------------------------------
-- Entity Section
-------------------------------------------------------------------------------

entity plbv46_dcr_bridge is

  generic (
    C_FAMILY                    : STRING                        := "virtex5";

    C_BASEADDR                  : STD_LOGIC_VECTOR              := X"FFFFFFFF";
    C_HIGHADDR                  : STD_LOGIC_VECTOR              := X"00000000";
    -- PLBv46 slave single block generics
    C_SPLB_AWIDTH               : integer                       := 32;
    C_SPLB_DWIDTH               : integer                       := 32;
    C_SPLB_P2P                  : integer range 0 to 1          := 0;
    C_SPLB_MID_WIDTH            : integer range 0 to 4          := 1;
    C_SPLB_NUM_MASTERS          : integer range 1 to 16         := 1;
    C_SPLB_NATIVE_DWIDTH        : integer range 32 to 32        := 32;
    C_SPLB_SUPPORT_BURSTS       : integer range 0 to 1          := 0
    );
  port (
    --PLBv46 SLAVE SINGLE INTERFACE
    -- system signals
    SPLB_Clk                  : in  std_logic;
    SPLB_Rst                  : in  std_logic;
    -- Bus slave signals
    PLB_ABus                  : in  std_logic_vector(0 to C_SPLB_AWIDTH-1);
    PLB_PAValid               : in  std_logic;
    PLB_masterID              : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_RNW                   : in  std_logic;
    PLB_BE                    : in  std_logic_vector(0 to (C_SPLB_DWIDTH/8)-1);
    PLB_size                  : in  std_logic_vector(0 to 3);
    PLB_type                  : in  std_logic_vector(0 to 2);
    PLB_wrDBus                : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);

    --slave DCR Bridge response signals
    Sl_addrAck                : out std_logic;
    Sl_SSize                  : out std_logic_vector(0 to 1);
    Sl_wait                   : out std_logic;
    Sl_rearbitrate            : out std_logic;
    Sl_wrDAck                 : out std_logic;
    Sl_wrComp                 : out std_logic;
    Sl_rdDBus                 : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdDAck                 : out std_logic;
    Sl_rdComp                 : out std_logic;
    Sl_MBusy                  : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr                 : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr                 : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

    -- Unused Bus slave signals
    PLB_UABus                 : in  std_logic_vector(0 to 31);
    PLB_SAValid               : in  std_logic;
    PLB_rdPrim                : in  std_logic;
    PLB_wrPrim                : in  std_logic;
    PLB_abort                 : in  std_logic;
    PLB_busLock               : in  std_logic;
    PLB_MSize                 : in  std_logic_vector(0 to 1);
    PLB_lockErr               : in  std_logic;
    PLB_wrBurst               : in  std_logic;
    PLB_rdBurst               : in  std_logic;
    PLB_wrPendReq             : in  std_logic;
    PLB_rdPendReq             : in  std_logic;
    PLB_wrPendPri             : in  std_logic_vector(0 to 1);
    PLB_rdPendPri             : in  std_logic_vector(0 to 1);
    PLB_reqPri                : in  std_logic_vector(0 to 1);
    PLB_TAttribute            : in  std_logic_vector(0 to 15);

    -- Unused Slave Response Signals
    Sl_wrBTerm                : out std_logic;
    Sl_rdWdAddr               : out std_logic_vector(0 to 3);
    Sl_rdBTerm                : out std_logic;
    Sl_MIRQ                   : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

    -- signals from plbv46_dcr_core to DCR slaves
    DCR_plbAck              : in  STD_LOGIC;
    DCR_plbDBusIn           : in  STD_LOGIC_VECTOR(0 to C_SPLB_NATIVE_DWIDTH-1);
    PLB_dcrRead             : out STD_LOGIC;
    PLB_dcrWrite            : out STD_LOGIC;
    PLB_dcrABus             : out STD_LOGIC_VECTOR(0 to 9);
    PLB_dcrDBusOut          : out STD_LOGIC_VECTOR(0 to C_SPLB_NATIVE_DWIDTH-1);

    PLB_dcrClk              : out STD_LOGIC;
    PLB_dcrRst              : out STD_LOGIC
    );
               --fan-out attributes for XST
               --fan-out attributes for MPD
  -----------------------------------------------------------------------------

  ATTRIBUTE CORE_STATE                          : string;
  ATTRIBUTE CORE_STATE of plbv46_dcr_bridge     : entity is  "ACTIVE";

  ATTRIBUTE IP_GROUP                            : string;
  ATTRIBUTE IP_GROUP of plbv46_dcr_bridge       : entity is  "LOGICORE";

  ATTRIBUTE IPTYPE                              : string;
  ATTRIBUTE IPTYPE of plbv46_dcr_bridge         : entity is "BRIDGE";

  ATTRIBUTE STYLE                               : string;
  ATTRIBUTE STYLE of plbv46_dcr_bridge          : entity is  "HDL";


  ATTRIBUTE MAX_FANOUT                 : string;
  ATTRIBUTE MAX_FANOUT of SPLB_Clk     : signal is "10000";
  ATTRIBUTE MAX_FANOUT of SPLB_Rst     : signal is "10000";

  ATTRIBUTE SIGIS		       : string;
  ATTRIBUTE SIGIS of SPLB_Clk          : signal is "Clk";
  ATTRIBUTE SIGIS of SPLB_Rst          : signal is "Rst";
  ATTRIBUTE SIGIS of PLB_dcrClk        : signal is "Clk";
                                          
  ATTRIBUTE SIGVAL                     : string;
  ATTRIBUTE SIGVAL of DCR_plbAck       : signal is "DCR_Ack";
  ATTRIBUTE SIGVAL of DCR_plbDBusIn    : signal is "DCR_M_DBus";
  ATTRIBUTE SIGVAL of PLB_dcrRead      : signal is "M_dcrRead";
  ATTRIBUTE SIGVAL of PLB_dcrWrite     : signal is "M_dcrWrite";
  ATTRIBUTE SIGVAL of PLB_dcrABus      : signal is "M_dcrABus";
  ATTRIBUTE SIGVAL of PLB_dcrDBusOut   : signal is "M_dcrDBus";

  ATTRIBUTE BUSIF                      : string;
  ATTRIBUTE BUSIF  of SPLB_Clk         : signal is "SPLB";
  ATTRIBUTE BUSIF  of DCR_plbAck       : signal is "MDCR";
  ATTRIBUTE BUSIF  of DCR_plbDBusIn    : signal is "MDCR";
  ATTRIBUTE BUSIF  of PLB_dcrRead      : signal is "MDCR";
  ATTRIBUTE BUSIF  of PLB_dcrWrite     : signal is "MDCR";
  ATTRIBUTE BUSIF  of PLB_dcrABus      : signal is "MDCR";
  ATTRIBUTE BUSIF  of PLB_dcrDBusOut   : signal is "MDCR";


  ATTRIBUTE BRIDGE_TO                     : string;
  ATTRIBUTE BRIDGE_TO   of C_BASEADDR     : constant is "MDCR";

  -----------------------------------------------------------------------------
end entity plbv46_dcr_bridge;

-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------
architecture implementation of plbv46_dcr_bridge is
-------------------------------------------------------------------------------
-- Constant Declarations

constant ZERO_PADS : std_logic_vector(0 to 31) := X"00000000";

-- Decoder address range definition constants starts
constant ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
        (
        ZERO_PADS & C_BASEADDR,
        ZERO_PADS & C_HIGHADDR
        );
constant ARD_NUM_CE_ARRAY     : INTEGER_ARRAY_TYPE :=
        (
        0 => 1
        );
-- Decoder address range definition constants ends
-------------------------------------------------------------------------------

-- local signal declaration goes here

--bus2ip signals
  signal bus2IP_Clk    : std_logic;
  signal bus2IP_Reset  : std_logic;
  signal bus2IP_Addr   : std_logic_vector(0 to C_SPLB_AWIDTH - 1 );
  signal bus2IP_BE     : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH/8 - 1 );
  signal bus2IP_CS     : std_logic_vector(0 to (ARD_ADDR_RANGE_ARRAY'LENGTH/2)-1);
  signal bus2IP_RdCE   : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
  signal bus2IP_WrCE   : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
  signal bus2IP_Data   : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH - 1 );
  signal bus2IP_RNW    : std_logic;

-- ip2bus signals
  signal ip2Bus_Data   : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH - 1 );
  signal ip2Bus_WrAck  : std_logic;
  signal ip2Bus_RdAck  : std_logic;
  signal ip2Bus_Error  : std_logic;

-- end of local signal declaration

begin  -- architecture implementation

----------------------------------
-- INSTANTIATE PLBv46 SLAVE SINGLE
----------------------------------
   PLBv46_IPIF_I : entity plbv46_slave_single_v1_01_a.plbv46_slave_single
     generic map
      (
       C_BUS2CORE_CLK_RATIO        => 1,
       C_INCLUDE_DPHASE_TIMER      => 1,

       C_ARD_ADDR_RANGE_ARRAY      => ARD_ADDR_RANGE_ARRAY,
       C_ARD_NUM_CE_ARRAY          => ARD_NUM_CE_ARRAY,

       C_SPLB_P2P                  => C_SPLB_P2P,
       C_SPLB_MID_WIDTH            => C_SPLB_MID_WIDTH,
       C_SPLB_NUM_MASTERS          => C_SPLB_NUM_MASTERS,
       C_SPLB_AWIDTH               => C_SPLB_AWIDTH,
       C_SPLB_DWIDTH               => C_SPLB_DWIDTH,
       C_SIPIF_DWIDTH              => C_SPLB_NATIVE_DWIDTH,
       C_FAMILY                    => C_FAMILY
      )
     port map
      (
      -- System signals ---------------------------------------------------
      SPLB_Clk                     => SPLB_Clk,
      SPLB_Rst                     => SPLB_Rst,
      -- Bus Slave signals ------------------------------------------------
      PLB_ABus                     => PLB_ABus,
      PLB_UABus                    => PLB_UABus,
      PLB_PAValid                  => PLB_PAValid,
      PLB_SAValid                  => PLB_SAValid,
      PLB_rdPrim                   => PLB_rdPrim,
      PLB_wrPrim                   => PLB_wrPrim,
      PLB_masterID                 => PLB_masterID,
      PLB_abort                    => PLB_abort,
      PLB_busLock                  => PLB_busLock,
      PLB_RNW                      => PLB_RNW,
      PLB_BE                       => PLB_BE,
      PLB_MSize                    => PLB_MSize,
      PLB_size                     => PLB_size,
      PLB_type                     => PLB_type,
      PLB_lockErr                  => PLB_lockErr,
      PLB_wrDBus                   => PLB_wrDBus,
      PLB_wrBurst                  => PLB_wrBurst,
      PLB_rdBurst                  => PLB_rdBurst,
      PLB_wrPendReq                => PLB_wrPendReq,
      PLB_rdPendReq                => PLB_rdPendReq,
      PLB_wrPendPri                => PLB_wrPendPri,
      PLB_rdPendPri                => PLB_rdPendPri,
      PLB_reqPri                   => PLB_reqPri,
      PLB_TAttribute               => PLB_TAttribute,
      -- Slave Response Signals -------------------------------------------
      Sl_addrAck                   => Sl_addrAck,
      Sl_SSize                     => Sl_SSize,
      Sl_wait                      => Sl_wait,
      Sl_rearbitrate               => Sl_rearbitrate,
      Sl_wrDAck                    => Sl_wrDAck,
      Sl_wrComp                    => Sl_wrComp,
      Sl_wrBTerm                   => Sl_wrBTerm,
      Sl_rdDBus                    => Sl_rdDBus,
      Sl_rdWdAddr                  => Sl_rdWdAddr,
      Sl_rdDAck                    => Sl_rdDAck,
      Sl_rdComp                    => Sl_rdComp,
      Sl_rdBTerm                   => Sl_rdBTerm,
      Sl_MBusy                     => Sl_MBusy,
      Sl_MWrErr                    => Sl_MWrErr,
      Sl_MRdErr                    => Sl_MRdErr,
      Sl_MIRQ                      => Sl_MIRQ,
      -- IP Interconnect (IPIC) port signals ------------------------------
      IP2Bus_Data                  => ip2Bus_Data,
      IP2Bus_WrAck                 => ip2Bus_WrAck,
      IP2Bus_RdAck                 => ip2Bus_RdAck,
      IP2Bus_Error                 => ip2Bus_Error,
      Bus2IP_Addr                  => bus2IP_Addr,
      Bus2IP_Data                  => bus2IP_Data,
      Bus2IP_RNW                   => bus2IP_RNW,
      Bus2IP_BE                    => bus2IP_BE,
      Bus2IP_CS                    => bus2IP_CS,
      Bus2IP_RdCE                  => bus2IP_RdCE,
      Bus2IP_WrCE                  => bus2IP_WrCE,
      Bus2IP_Clk                   => bus2IP_Clk,
      Bus2IP_Reset                 => bus2IP_Reset
      );

-- component plbv46_dcr_bridge_core interface starts here

plbv46_dcr_bridge_core_1 : entity plbv46_dcr_bridge_v1_01_a.plbv46_dcr_bridge_core
    port map (
      -- IP Interconnect (IPIC) port signals ----
      Bus2IP_Clk                   => bus2IP_Clk,
      Bus2IP_Reset                 => bus2IP_Reset,

      Bus2IP_Addr                  => bus2IP_Addr,
      Bus2IP_Data                  => bus2IP_Data,
      Bus2IP_BE                    => bus2IP_BE,
      Bus2IP_CS                    => bus2IP_CS(0),
      Bus2IP_RdCE                  => bus2IP_RdCE(0),
      Bus2IP_WrCE                  => bus2IP_WrCE(0),

      IP2Bus_RdAck                 => ip2Bus_RdAck,
      IP2Bus_WrAck                 => ip2Bus_WrAck,

      IP2Bus_Error                 => ip2Bus_Error,
      IP2Bus_Data                  => ip2Bus_Data,

      -- signals from plbv46dcr_core --
      DCR_plbDBusIn                => DCR_plbDBusIn,
      DCR_plbAck                   => DCR_plbAck,

      PLB_dcrABus                  => PLB_dcrABus,
      PLB_dcrDBusOut               => PLB_dcrDBusOut,
      PLB_dcrRead                  => PLB_dcrRead,
      PLB_dcrWrite                 => PLB_dcrWrite,

      PLB_dcrRst                   => PLB_dcrRst,
      PLB_dcrClk                   => PLB_dcrClk
      );
-- component interfacing ends here.

end architecture implementation;
