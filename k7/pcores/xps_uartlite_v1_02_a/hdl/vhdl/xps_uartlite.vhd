-------------------------------------------------------------------------------
-- xps_uartlite - entity/architecture pair
-------------------------------------------------------------------------------
--
   -- *******************************************************************
-- -- ** (c) Copyright [2007] - [2011] Xilinx, Inc. All rights reserved.*
-- -- **                                                                *
-- -- ** This file contains confidential and proprietary information    *
-- -- ** of Xilinx, Inc. and is protected under U.S. and                *
-- -- ** international copyright and other intellectual property        *
-- -- ** laws.                                                          *
-- -- **                                                                *
-- -- ** DISCLAIMER                                                     *
-- -- ** This disclaimer is not a license and does not grant any        *
-- -- ** rights to the materials distributed herewith. Except as        *
-- -- ** otherwise provided in a valid license issued to you by         *
-- -- ** Xilinx, and to the maximum extent permitted by applicable      *
-- -- ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
-- -- ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
-- -- ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
-- -- ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
-- -- ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
-- -- ** (2) Xilinx shall not be liable (whether in contract or tort,   *
-- -- ** including negligence, or under any other theory of             *
-- -- ** liability) for any loss or damage of any kind or nature        *
-- -- ** related to, arising under or in connection with these          *
-- -- ** materials, including for any direct, or any indirect,          *
-- -- ** special, incidental, or consequential loss or damage           *
-- -- ** (including loss of data, profits, goodwill, or any type of     *
-- -- ** loss or damage suffered as a result of any action brought      *
-- -- ** by a third party) even if such damage or loss was              *
-- -- ** reasonably foreseeable or Xilinx had been advised of the       *
-- -- ** possibility of the same.                                       *
-- -- **                                                                *
-- -- ** CRITICAL APPLICATIONS                                          *
-- -- ** Xilinx products are not designed or intended to be fail-       *
-- -- ** safe, or for use in any application requiring fail-safe        *
-- -- ** performance, such as life-support or safety devices or         *
-- -- ** systems, Class III medical devices, nuclear facilities,        *
-- -- ** applications related to the deployment of airbags, or any      *
-- -- ** other applications that could lead to death, personal          *
-- -- ** injury, or severe property or environmental damage             *
-- -- ** (individually and collectively, "Critical                      *
-- -- ** Applications"). Customer assumes the sole risk and             *
-- -- ** liability of any use of Xilinx products in Critical            *
-- -- ** Applications, subject only to applicable laws and              *
-- -- ** regulations governing limitations on product liability.        *
-- -- **                                                                *
-- -- ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
-- -- ** PART OF THIS FILE AT ALL TIMES.                                *
   -- *******************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        xps_uartlite.vhd
-- Version:         v1.02a
-- Description:     XPS UART Lite Interface
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   This section shows the hierarchical structure of xps_uartlite.
--
--              xps_uartlite.vhd
--                 --plbv46_slave_single.vhd
--                 --uartlite_core.vhd
--                    --uartlite_tx.vhd
--                    --uartlite_rx.vhd
--                    --baudrate.vhd
-------------------------------------------------------------------------------
-- Author:          MZC
--
-- History:
--  MZC     11/17/06
-- ^^^^^^
--  - Initial release of xps_uartlite based on opb uartlite v1.00b
-- ~~~~~~
--  NSK     01/24/07
-- ^^^^^^
-- Checking-in FLO modified files.
-- ~~~~~~
--  NSK     01/25/07
-- ^^^^^^
-- 1. Code clean up.
-- 2. Renamed parameter C_CLK_FREQ to C_SPLB_CLK_FREQ_HZ.
-- ~~~~~~
--  NSK     01/29/07
-- ^^^^^^
-- 1. Removed End of file statement.
-- 2. Removed the generation of ip2bus_error signal.
-- 3. Added port map for ip2bus_error signal in the instance of uartlite_core.
-- ~~~~~~
--  USM     08/22/08
-- ^^^^^^
-- 1. Modified the version from xps_uartlite_v1_00_a to xps_uartlite_v1_01_a.
-- 2. Changed the library proc_common_v2_00_a to proc_common_v3_00_a and
--    the library plbv46_slave_single_v1_00_a to plbv46_slave_single_v1_01_a.
-- 3. Fixed CR474640 - Modified the baud rate calculation that rounds the
--    ratio instead of truncating.
-- 4. Fixed CR467040 - Modified the initial/reset value of status register to
--    zero.
-- 5. Modified to fix linting errors.
-- 6. Modified plbv46_slave_single instantiation to include 
--    C_BUS2CORE_CLK_RATIO. & C_INCLUDE_DPHASE_TIMER.
-- ~~~~~~
--  USM     12/16/08
-- ^^^^^^
-- Fixed CR500637 - Removed error generation when a partial word access 
-- is requested.
-- ~~~~~~
-- NLR     08/02/2010
-- ^^^^^^
-- 1.Modified the version from xps_uartlite_v1_01_a to xps_uartlite_v1_02_a.  
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
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
library IEEE;
use IEEE.std_logic_1164.all;

library proc_common_v3_00_a;
-- SLV64_ARRAY_TYPE refered from ipif_pkg
use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;
-- INTEGER_ARRAY_TYPE refered from ipif_pkg
use proc_common_v3_00_a.ipif_pkg.INTEGER_ARRAY_TYPE;
-- calc_num_ce comoponent refered from ipif_pkg
use proc_common_v3_00_a.ipif_pkg.calc_num_ce;

library plbv46_slave_single_v1_01_a;
-- plbv46_slave_single refered from plbv46_slave_single_v1_01_a
use plbv46_slave_single_v1_01_a.plbv46_slave_single;

library xps_uartlite_v1_02_a;
-- uartlite_core refered from xps_uartlite_v1_02_a
use xps_uartlite_v1_02_a.uartlite_core;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics :
-------------------------------------------------------------------------------
-- UART Lite generics
--  C_DATA_BITS           -- The number of data bits in the serial frame
--  C_SPLB_CLK_FREQ_HZ    -- System clock frequency driving UART lite
--                           peripheral in Hz
--  C_BAUDRATE            -- Baud rate of UART Lite in bits per second
--  C_USE_PARITY          -- Determines whether parity is used or not
--  C_ODD_PARITY          -- If parity is used determines whether parity
--                           is even or odd
-- PLBv46 Slave Single block generics
--  C_FAMILY              -- Xilinx FPGA Family
--  C_BASEADDR            -- Base address of the core
--  C_HIGHADDR            -- Permits alias of address space
--                           by making greater than x0F
--  C_SPPB_AWIDTH         -- Width of SPLB Address Bus (in bits)
--  C_SPLB_DWIDTH         -- Width of the SPLB Data Bus (in bits)
--  C_SPLB_P2P            -- Selects point-to-point bus topology
--  C_SPLB_MID_WIDTH      -- PLB Master ID Bus width
--  C_SPLB_NUM_MASTERS    -- Number of PLB Masters
--  C_SPLB_SUPPORT_BURSTS -- Enables burst mode of operation
--  C_SPLB_NATIVE_DWIDTH  -- Width of the slave data bus
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Ports :
-------------------------------------------------------------------------------
-- System Signals
--  SPLB_Clk              --  SPLB Clock
--  SPLB_Rst              --  Reset Signal
-- UART Lite interface
--  Interrupt             --  UART Interrupt
--  RX                    --  Receive Data
--  TX                    --  Transmit Data
-- PLBv46 slave single interface
-- PLB Slave Signals 
--  PLB_ABus              -- PLB address bus
--  PLB_UABus             -- PLB upper address bus
--  PLB_PAValid           -- PLB primary address valid
--  PLB_SAValid           -- PLB secondary address valid
--  PLB_rdPrim            -- PLB secondary to primary read request
--  PLB_wrPrim            -- PLB secondary to primary write request
--  PLB_masterID          -- PLB current master identifier
--  PLB_abort             -- PLB abort request
--  PLB_busLock           -- PLB bus lock
--  PLB_RNW               -- PLB read not write
--  PLB_BE                -- PLB byte enable
--  PLB_MSize             -- PLB data bus width indicator
--  PLB_size              -- PLB transfer size
--  PLB_type              -- PLB transfer type
--  PLB_lockErr           -- PLB lock error
--  PLB_wrDBus            -- PLB write data bus
--  PLB_wrBurst           -- PLB burst write transfer
--  PLB_rdBurst           -- PLB burst read transfer
--  PLB_wrPendReq         -- PLB pending bus write request
--  PLB_rdPendReq         -- PLB pending bus read request
--  PLB_wrPendPri         -- PLB pending bus write request priority
--  PLB_rdPendPri         -- PLB pending bus read request priority
--  PLB_reqPri            -- PLB current request 
--  PLB_TAttribute        -- PLB transfer attribute
-- Slave Response Signal
--  Sl_addrAck            -- Salve address ack
--  Sl_SSize              -- Slave data bus size
--  Sl_wait               -- Salve wait indicator
--  Sl_rearbitrate        -- Salve rearbitrate
--  Sl_wrDAck             -- Slave write data ack
--  Sl_wrComp             -- Salve write complete
--  Sl_wrBTerm            -- Salve terminate write burst transfer
--  Sl_rdDBus             -- Slave read data bus
--  Sl_rdWdAddr           -- Slave read word address
--  Sl_rdDAck             -- Salve read data ack
--  Sl_rdComp             -- Slave read complete
--  Sl_rdBTerm            -- Salve terminate read burst transfer
--  Sl_MBusy              -- Slave busy
--  Sl_MWrErr             -- Slave write error
--  Sl_MRdErr             -- Slave read error
--  Sl_MIRQ               -- Master interrput 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Entity Section
-------------------------------------------------------------------------------
entity xps_uartlite is
  generic 
   (
--  -- System Parameter
    C_FAMILY              : string                    := "virtex5";
    C_SPLB_CLK_FREQ_HZ    : integer                   := 100_000_000;
--  -- PLB Parameters
    C_BASEADDR            : std_logic_vector(0 to 31) := X"FFFF_FFFF";
    C_HIGHADDR            : std_logic_vector(0 to 31) := X"0000_0000";
    C_SPLB_AWIDTH         : integer range 32 to 36    := 32;
    C_SPLB_DWIDTH         : integer range 32 to 128   := 32;
    C_SPLB_P2P            : integer range 0 to 1      := 0;
    C_SPLB_MID_WIDTH      : integer range 0 to 4      := 1;
    C_SPLB_NUM_MASTERS    : integer range 1 to 16     := 1;
    C_SPLB_SUPPORT_BURSTS : integer                   := 0;
    C_SPLB_NATIVE_DWIDTH  : integer range 32 to 32    := 32;
--  -- UARTLite Parameters
    C_BAUDRATE            : integer                   := 9600;
    C_DATA_BITS           : integer range 5 to 8      := 8;
    C_USE_PARITY          : integer range 0 to 1      := 1;
    C_ODD_PARITY          : integer range 0 to 1      := 1
   );
  port
   (
--  -- System Signals
    SPLB_Clk       : in  std_logic;
    SPLB_Rst       : in  std_logic;
--  -- PLB Interface Signals
    PLB_ABus       : in  std_logic_vector(0 to 31);
    PLB_PAValid    : in  std_logic;
    PLB_masterID   : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_RNW        : in  std_logic;
    PLB_BE         : in  std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1);
    PLB_size       : in  std_logic_vector(0 to 3);
    PLB_type       : in  std_logic_vector(0 to 2);
    PLB_wrDBus     : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
--  -- Unused PLB Interface Signals
    PLB_UABus      : in  std_logic_vector(0 to 31);
    PLB_SAValid    : in  std_logic;
    PLB_rdPrim     : in  std_logic;
    PLB_wrPrim     : in  std_logic;
    PLB_abort      : in  std_logic;
    PLB_busLock    : in  std_logic;
    PLB_MSize      : in  std_logic_vector(0 to 1);
    PLB_lockErr    : in  std_logic;
    PLB_wrBurst    : in  std_logic;
    PLB_rdBurst    : in  std_logic;
    PLB_wrPendReq  : in  std_logic;
    PLB_rdPendReq  : in  std_logic;
    PLB_wrPendPri  : in  std_logic_vector(0 to 1);
    PLB_rdPendPri  : in  std_logic_vector(0 to 1);
    PLB_reqPri     : in  std_logic_vector(0 to 1);
    PLB_TAttribute : in  std_logic_vector(0 to 15);
--  -- PLB Slave Interface Signals
    Sl_addrAck     : out std_logic;
    Sl_SSize       : out std_logic_vector(0 to 1);
    Sl_wait        : out std_logic;
    Sl_rearbitrate : out std_logic;
    Sl_wrDAck      : out std_logic;
    Sl_wrComp      : out std_logic;
    Sl_rdDBus      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdDAck      : out std_logic;
    Sl_rdComp      : out std_logic;
    Sl_MBusy       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
--  -- Unused PLB Slave Interface Signals
    Sl_wrBTerm     : out std_logic;
    Sl_rdWdAddr    : out std_logic_vector(0 to 3);
    Sl_rdBTerm     : out std_logic;
    Sl_MIRQ        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
--  -- UARTLite Interface Signals
    RX             : in  std_logic;
    TX             : out std_logic;
    Interrupt      : out std_logic
   );

-------------------------------------------------------------------------------
-- Attributes
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
  -- Fan-Out attributes for XST
-------------------------------------------------------------------------------
    ATTRIBUTE MAX_FANOUT              : string;
    ATTRIBUTE MAX_FANOUT  of SPLB_Clk : signal is "10000";
    ATTRIBUTE MAX_FANOUT  of SPLB_Rst : signal is "10000";

-------------------------------------------------------------------------------
  -- PSFUtil MPD attributes
-------------------------------------------------------------------------------
    ATTRIBUTE IP_GROUP                     : string;
    ATTRIBUTE IP_GROUP     of xps_uartlite : entity is "LOGICORE";

    ATTRIBUTE IPTYPE                       : string;
    ATTRIBUTE IPTYPE       of xps_uartlite : entity is "PERIPHERAL";

    ATTRIBUTE HDL                          : string;
    ATTRIBUTE HDL          of xps_uartlite : entity is "VHDL";

    ATTRIBUTE STYLE                        : string;
    ATTRIBUTE STYLE        of xps_uartlite : entity is "HDL";

    ATTRIBUTE IMP_NETLIST                  : string;
    ATTRIBUTE IMP_NETLIST  of xps_uartlite : entity is "TRUE";

    ATTRIBUTE RUN_NGCBUILD                 : string;
    ATTRIBUTE RUN_NGCBUILD of xps_uartlite : entity is "TRUE";

    ATTRIBUTE ADDR_TYPE                    : string;
    ATTRIBUTE ADDR_TYPE    of C_BASEADDR   : constant is "REGISTER";
    ATTRIBUTE ADDR_TYPE    of C_HIGHADDR   : constant is "REGISTER";

    ATTRIBUTE ASSIGNMENT                   : string;
    ATTRIBUTE ASSIGNMENT   of C_BASEADDR   : constant is "REQUIRE";
    ATTRIBUTE ASSIGNMENT   of C_HIGHADDR   : constant is "REQUIRE";

    ATTRIBUTE SIGIS                        : string;
    ATTRIBUTE SIGIS        of SPLB_Clk     : signal   is  "CLK";
    ATTRIBUTE SIGIS        of SPLB_Rst     : signal   is  "RST";
    ATTRIBUTE SIGIS        of Interrupt    : signal   is  "INTR_EDGE_RISING";

    ATTRIBUTE MIN_SIZE                     : string;
    ATTRIBUTE MIN_SIZE     of C_BASEADDR   : constant is  "0x00010";

    ATTRIBUTE SIM_MODELS                   : string;
    ATTRIBUTE SIM_MODELS   of xps_uartlite : entity   is  "BEHAVIORAL";

    ATTRIBUTE XRANGE                       : string;
    ATTRIBUTE XRANGE       of C_DATA_BITS  : constant is "(5:8)";
    ATTRIBUTE XRANGE       of C_USE_PARITY : constant is "(0,1)";
    ATTRIBUTE XRANGE       of C_ODD_PARITY : constant is "(0,1)";

end entity xps_uartlite;

-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------
architecture imp of xps_uartlite is

    --------------------------------------------------------------------------
    -- Constant declarations
    --------------------------------------------------------------------------
    constant ZEROES                 : std_logic_vector(0 to 31) := X"00000000";

    constant C_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
            (
              -- UARTLite registers Base Address
              ZEROES & C_BASEADDR,
              ZEROES & (C_BASEADDR or X"0000000F") 
            );

    constant C_ARD_NUM_CE_ARRAY     : INTEGER_ARRAY_TYPE :=
            (
              0 => 4
            );

    --------------------------------------------------------------------------
    -- Signal declarations
    --------------------------------------------------------------------------
    signal bus2ip_clk   : std_logic;
    signal bus2ip_reset : std_logic;
    signal ip2bus_data  : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH - 1):= 
                          (others  => '0');
    signal ip2bus_error : std_logic := '0';
    signal ip2bus_wrack : std_logic := '0';
    signal ip2bus_rdack : std_logic := '0';
    signal bus2ip_data  : std_logic_vector
                          (0 to C_SPLB_NATIVE_DWIDTH - 1);
    signal bus2ip_addr  : std_logic_vector(0 to C_SPLB_AWIDTH - 1 );
    signal bus2ip_be    : std_logic_vector
                          (0 to C_SPLB_NATIVE_DWIDTH / 8 - 1 );
    signal bus2ip_cs    : std_logic_vector
                          (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
    signal bus2ip_rdce  : std_logic_vector
                          (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1);
    signal bus2ip_wrce  : std_logic_vector
                          (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1);

begin  -- architecture IMP

    --------------------------------------------------------------------------
    -- Instansiating the UART core
    --------------------------------------------------------------------------
    UARTLITE_CORE_I : entity xps_uartlite_v1_02_a.uartlite_core
      generic map
       (
        C_DATA_BITS        => C_DATA_BITS,
        C_SPLB_CLK_FREQ_HZ => C_SPLB_CLK_FREQ_HZ,
        C_BAUDRATE         => C_BAUDRATE,
        C_USE_PARITY       => C_USE_PARITY,
        C_ODD_PARITY       => C_ODD_PARITY,
        C_FAMILY           => C_FAMILY
       )
      port map
       (
        Clk          => bus2ip_clk,
        Reset        => bus2ip_reset,
        bus2ip_data  => bus2ip_data(C_SPLB_NATIVE_DWIDTH-8 
                                    to C_SPLB_NATIVE_DWIDTH-1),
        bus2ip_rdce  => bus2ip_rdce(0 to 3),
        bus2ip_wrce  => bus2ip_wrce(0 to 3),
        bus2ip_be    => bus2ip_be,
        bus2ip_cs    => bus2ip_cs(0),
        ip2bus_rdack => ip2bus_rdack,
        ip2bus_wrack => ip2bus_wrack,
        ip2bus_error => ip2bus_error,
        SIn_DBus     => ip2bus_data(C_SPLB_NATIVE_DWIDTH-8 
                                    to C_SPLB_NATIVE_DWIDTH-1),
        RX           => RX,
        TX           => TX,
        Interrupt    => Interrupt
       );

    --------------------------------------------------------------------------
    -- INSTANTIATE PLBV46 SLAVE SINGLE
    --------------------------------------------------------------------------
    PLBV46_I : entity plbv46_slave_single_v1_01_a.plbv46_slave_single
      generic map
       (
        C_ARD_ADDR_RANGE_ARRAY => C_ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY     => C_ARD_NUM_CE_ARRAY,
        C_SPLB_P2P             => C_SPLB_P2P,
        C_BUS2CORE_CLK_RATIO   => 1,
        C_INCLUDE_DPHASE_TIMER => 1,
        C_SPLB_MID_WIDTH       => C_SPLB_MID_WIDTH,
        C_SPLB_NUM_MASTERS     => C_SPLB_NUM_MASTERS,
        C_SPLB_AWIDTH          => C_SPLB_AWIDTH,
        C_SPLB_DWIDTH          => C_SPLB_DWIDTH,
        C_SIPIF_DWIDTH         => C_SPLB_NATIVE_DWIDTH,
        C_FAMILY               => C_FAMILY
       )
     port map
       (
        -- System signals 
        SPLB_Clk       => SPLB_Clk,
        SPLB_Rst       => SPLB_Rst,
        -- Bus Slave signals
        PLB_ABus       => PLB_ABus,
        PLB_UABus      => PLB_UABus,
        PLB_PAValid    => PLB_PAValid,
        PLB_SAValid    => PLB_SAValid,
        PLB_rdPrim     => PLB_rdPrim,
        PLB_wrPrim     => PLB_wrPrim,
        PLB_masterID   => PLB_masterID,
        PLB_abort      => PLB_abort,
        PLB_busLock    => PLB_busLock,
        PLB_RNW        => PLB_RNW,
        PLB_BE         => PLB_BE,
        PLB_MSize      => PLB_MSize,
        PLB_size       => PLB_size,
        PLB_type       => PLB_type,
        PLB_lockErr    => PLB_lockErr,
        PLB_wrDBus     => PLB_wrDBus,
        PLB_wrBurst    => PLB_wrBurst,
        PLB_rdBurst    => PLB_rdBurst,
        PLB_wrPendReq  => PLB_wrPendReq,
        PLB_rdPendReq  => PLB_rdPendReq,
        PLB_wrPendPri  => PLB_wrPendPri,
        PLB_rdPendPri  => PLB_rdPendPri,
        PLB_reqPri     => PLB_reqPri,
        PLB_TAttribute => PLB_TAttribute,
        -- Slave Response Signals 
        Sl_addrAck     => Sl_addrAck,
        Sl_SSize       => Sl_SSize,
        Sl_wait        => Sl_wait,
        Sl_rearbitrate => Sl_rearbitrate,
        Sl_wrDAck      => Sl_wrDAck,
        Sl_wrComp      => Sl_wrComp,
        Sl_wrBTerm     => Sl_wrBTerm,
        Sl_rdDBus      => Sl_rdDBus,
        Sl_rdWdAddr    => Sl_rdWdAddr,
        Sl_rdDAck      => Sl_rdDAck,
        Sl_rdComp      => Sl_rdComp,
        Sl_rdBTerm     => Sl_rdBTerm,
        Sl_MBusy       => Sl_MBusy,
        Sl_MWrErr      => Sl_MWrErr,
        Sl_MRdErr      => Sl_MRdErr,
        Sl_MIRQ        => Sl_MIRQ,
        -- IP Interconnect (IPIC) port signals 
        Bus2IP_Clk     => bus2ip_clk,
        Bus2IP_Reset   => bus2ip_reset,
        IP2Bus_Data    => ip2bus_data,
        IP2Bus_WrAck   => ip2bus_wrack,
        IP2Bus_RdAck   => ip2bus_rdack,
        IP2Bus_Error   => ip2bus_error,
        Bus2IP_Addr    => bus2ip_addr,
        Bus2IP_Data    => bus2ip_data,
        Bus2IP_RNW     => open,
        Bus2IP_BE      => bus2ip_be,
        Bus2IP_CS      => bus2ip_cs,
        Bus2IP_RdCE    => bus2ip_rdce,
        Bus2IP_WrCE    => bus2ip_wrce
       );

end architecture imp;
