-------------------------------------------------------------------------------
-- $Id: dcr_v29.vhd,v 1.1.4.1 2009/10/06 21:09:10 gburch Exp $
-------------------------------------------------------------------------------
-- dcr_v29.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--
-- *************************************************************************
-- **                                                                     **
-- ** DISCLAIMER OF LIABILITY                                             **
-- **                                                                     **
-- ** This text/file contains proprietary, confidential                   **
-- ** information of Xilinx, Inc., is distributed under                   **
-- ** license from Xilinx, Inc., and may be used, copied                  **
-- ** and/or disclosed only pursuant to the terms of a valid              **
-- ** license agreement with Xilinx, Inc. Xilinx hereby                   **
-- ** grants you a license to use this text/file solely for               **
-- ** design, simulation, implementation and creation of                  **
-- ** design files limited to Xilinx devices or technologies.             **
-- ** Use with non-Xilinx devices or technologies is expressly            **
-- ** prohibited and immediately terminates your license unless           **
-- ** covered by a separate agreement.                                    **
-- **                                                                     **
-- ** Xilinx is providing this design, code, or information               **
-- ** "as-is" solely for use in developing programs and                   **
-- ** solutions for Xilinx devices, with no obligation on the             **
-- ** part of Xilinx to provide support. By providing this design,        **
-- ** code, or information as one possible implementation of              **
-- ** this feature, application or standard, Xilinx is making no          **
-- ** representation that this implementation is free from any            **
-- ** claims of infringement. You are responsible for obtaining           **
-- ** any rights you may require for your implementation.                 **
-- ** Xilinx expressly disclaims any warranty whatsoever with             **
-- ** respect to the adequacy of the implementation, including            **
-- ** but not limited to any warranties or representations that this      **
-- ** implementation is free from claims of infringement, implied         **
-- ** warranties of merchantability or fitness for a particular           **
-- ** purpose.                                                            **
-- **                                                                     **
-- ** Xilinx products are not intended for use in life support            **
-- ** appliances, devices, or systems. Use in such applications is        **
-- ** expressly prohibited.                                               **
-- **                                                                     **
-- ** Any modifications that are made to the Source Code are              **
-- ** done at the user’s sole risk and will be unsupported.               **
-- ** The Xilinx Support Hotline does not have access to source           **
-- ** code and therefore cannot answer specific questions related         **
-- ** to source HDL. The Xilinx Hotline support of original source        **
-- ** code IP shall only address issues and questions related             **
-- ** to the standard Netlist version of the core (and thus               **
-- ** indirectly, the original core source).                              **
-- **                                                                     **
-- ** Copyright (c) 2003,2009 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        dcr_v29.vhd
-- Version:         v1.00b
-- Description:     IBM DCR (Device Control Register) Bus implementation
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  dcr_v29.vhd
--
-------------------------------------------------------------------------------
-- Author:          ALS
-- History:
--   ALS           4-18-02    First Version
--   ALS           4-29-02
--   ALS           4-01-03    Put in work-around for 1 DCR Slave problem with
--                            NGDBUILD
--   GAB          10-05-09    Removed reference to proc_common_v1_00_b and pulled
--                            or_gate and or_muxcy into this dcr library.
--                            Updated copyright header
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
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- Removed 10/5/09
--library proc_common_v1_00_b;
--use proc_common_v1_00_b.all;
library dcr_v29_v1_00_b;
use dcr_v29_v1_00_b.all;

library unisim;
use unisim.all;

-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_DCR_NUM_SLAVES            -- number of DCR slaves
--      C_DCR_DWIDTH                -- width of DCR data bus
--      C_DCR_AWIDTH                -- width of DCR address bus
--      C_USE_LUT_OR                -- use LUTs to implement BUS ORs instead
--                                  -- of carry-chain implementation
--
-- Definition of Ports:
--  -- Master interface
--      M_dcrABus                   -- master dcr address bus output
--      M_dcrDBus                   -- master dcr data bus output
--      M_dcrRead                   -- master dcr read output
--      M_dcrWrite                  -- master dcr write output
--      DCR_M_DBus                  -- master dcr data bus input
--      DCR_Ack                     -- master dcr ack input
--
--  -- Slave interface
--  -- Note: All slave signals are concatenated together to form a
--  -- single bus. A particular slave's connection must be indexed
--  -- into the bus
--      DCR_ABus                    --  slave address bus input
--      DCR_Sl_DBus                 --  slave data bus input
--      DCR_Read                    --  slave dcr read input
--      DCR_Write                   --  slave dcr write input
--      Sl_dcrDBus                  --  slave data bus output
--      Sl_dcrAck                   --  slave dcr ack output
-------------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------

entity dcr_v29 is
    generic (
        C_DCR_NUM_SLAVES    : integer  := 4;
        C_DCR_AWIDTH        : integer  := 10;
        C_DCR_DWIDTH        : integer  := 32;
        C_USE_LUT_OR        : integer  := 1
        );
  port (
    -- Master outputs
    M_dcrABus         : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
    M_dcrDBus         : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
    M_dcrRead         : in  std_logic;
    M_dcrWrite        : in  std_logic;

    -- Master inputs
    DCR_M_DBus      : out std_logic_vector(0 to C_DCR_DWIDTH-1);
    DCR_Ack         : out std_logic;

    -- Slave inputs
    DCR_ABus        : out  std_logic_vector(0 to C_DCR_AWIDTH*C_DCR_NUM_SLAVES-1);
    DCR_Sl_DBus     : out  std_logic_vector(0 to C_DCR_DWIDTH*C_DCR_NUM_SLAVES-1);
    DCR_Read        : out  std_logic_vector(0 to C_DCR_NUM_SLAVES-1);
    DCR_Write       : out  std_logic_vector(0 to C_DCR_NUM_SLAVES-1);

    -- slave outputs
    Sl_dcrDBus      : in  std_logic_vector(0 to C_DCR_DWIDTH*C_DCR_NUM_SLAVES-1);
    Sl_dcrAck       : in  std_logic_vector(0 to C_DCR_NUM_SLAVES-1)
    );
end entity dcr_v29;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture imp of dcr_v29 is

-----------------------------------------------------------------------------
-- Signal declarations
-----------------------------------------------------------------------------
-- internal version of DCR_Ack
signal m_dcrack_i : std_logic_vector(0 to 0);

-- dummy signal for NGDBUILD workaround which requires at least one component
-- in the NGC file when C_DCR_NUM_SLAVES=1
signal dummy      : std_logic;

-----------------------------------------------------------------------------
-- Component declarations
-----------------------------------------------------------------------------
-- Replaced with direct instantiation 10/5/09
--component or_gate is
--  generic (
--    C_OR_WIDTH   : natural range 1 to 32;
--    C_BUS_WIDTH  : natural range 1 to 64;
--    C_USE_LUT_OR : boolean := TRUE
--    );
--  port (
--    A : in  std_logic_vector(0 to C_OR_WIDTH*C_BUS_WIDTH-1);
--    Y : out std_logic_vector(0 to C_BUS_WIDTH-1)
--    );
--end component or_gate;

-- dummy buffer for NGDBUILD workaround
component BUF
  port (
    O : out std_logic;
    I : in std_logic
  );
end component;


-----------------------------------------------------------------------------
-- Begin architecture
-----------------------------------------------------------------------------

begin  -- architecture imp

-----------------------------------------------------------------------------
-- Instantiation of Dummy buffer to get through NGDBUILD
-----------------------------------------------------------------------------
DUMMY_BUF_I: BUF
    port map (O => dummy,
              I => '1'
              );

-----------------------------------------------------------------------------
-- Send the Master's Address bus and read/write signals to the slaves
-----------------------------------------------------------------------------
ABUS_RW_GEN: for i in 0 to C_DCR_NUM_SLAVES-1 generate

    DCR_Read(i) <= M_dcrRead;
    DCR_Write(i) <= M_dcrWrite;
    DCR_ABus(i*C_DCR_AWIDTH to i*C_DCR_AWIDTH+C_DCR_AWIDTH-1) <= M_dcrABus;

end generate ABUS_RW_GEN;

-----------------------------------------------------------------------------
-- Daisy chain the DCR Data bus from the Master to Slave 0, then Slave 1, etc.
-- and then back to the Master
-----------------------------------------------------------------------------
DCR_Sl_DBus(0 to C_DCR_DWIDTH-1) <= M_dcrDBus;

DBUS_DCHAIN: for i in 1 to C_DCR_NUM_SLAVES-1 generate

    DCR_Sl_DBus(i*C_DCR_DWIDTH to i*C_DCR_DWIDTH+C_DCR_DWIDTH-1)
                <= Sl_dcrDBus((i-1)*C_DCR_DWIDTH to (i-1)*C_DCR_DWIDTH+C_DCR_DWIDTH-1);
end generate;

DCR_M_DBus <= Sl_dcrDBus((C_DCR_NUM_SLAVES-1)*C_DCR_DWIDTH to
                                (C_DCR_NUM_SLAVES-1)*C_DCR_DWIDTH+C_DCR_DWIDTH-1);

-----------------------------------------------------------------------------
-- OR the slave's dcrAck signals to generate the Master's dcrAck input
-----------------------------------------------------------------------------
M_DCRACK_OR_I: entity dcr_v29_v1_00_b.or_gate
    generic map ( C_OR_WIDTH    => C_DCR_NUM_SLAVES,
                  C_BUS_WIDTH   => 1,
                  C_USE_LUT_OR  =>  C_USE_LUT_OR /= 0
                 )
    port map (
                A => Sl_dcrAck,
                Y => m_dcrack_i
              );

DCR_Ack <= m_dcrack_i(0);

end imp;

