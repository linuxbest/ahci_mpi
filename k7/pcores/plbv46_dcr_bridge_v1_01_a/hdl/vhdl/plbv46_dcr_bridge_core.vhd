-------------------------------------------------------------------------------
-- plbv46_dcr_bridge_core - entity / architecture pair
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
-- Copyright 2001, 2002, 2006, 2008, 2009 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
-- ***************************************************************************--
--
-------------------------------------------------------------------------------
-- Filename:    plbv46_dcr_bridge_core.vhd
-- Version:     v1.01.a
-- Description: plbv46_dcr_bridge core
--
-------------------------------------------------------------------------------
-- Structure:
--              plbv46_dcr_bridge.vhd
--                  -- plbv46_dcr_bridge_core.vhd
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Author   : SK
-- History:
--      Initial version of  plbv46_dcr_Bridge
-- ~~~~~~
-- SK                 2006/09/19      -- Initial version
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
-----------------------------------------------------------------------------
-- Definition of Ports:
-------------------------------------------------------------------------------
--                     Definition of Ports                                   --
-------------------------------------------------------------------------------
----------------------------------------
-- IPIC INTERFACE
----------------------------------------
-- Bus2IP_Clk            - IPIC clock
-- Bus2IP_Reset          - IPIC reset
-- Bus2IP_CS             - IPIC chip select signals 
-- Bus2IP_RdCE           - IPIC read transaction chip enables 
-- Bus2IP_WrCE           - IPIC write transaction chip enables 
-- Bus2IP_Addr           - IPIC address 
-- Bus2IP_RNW            - IPIC read/write indication 
-- Bus2IP_BE             - IPIC byte enables 
-- Bus2IP_Data           - IPIC write data 

-- IP2Bus_Data           - Read data from IP to IPIC interface
-- IP2Bus_WrAck          - Write Data acknowledgment from IP to IPIC interface
-- IP2Bus_RdAck          - Read Data acknowledgment from IP to IPIC interface
-- IP2Bus_Error          - Error indication from IP to IPIC interface
----------------------------------------
-- PERIPHERAL INTERFACE
----------------------------------------
-- DCR_plbDBusIn         - DCR data bus input
-- DCR_plbAck            - DCR Ack signals
-- PLB_dcrABus           - PLB address bus to DCR
-- PLB_dcrDBusOut        - Data bus to the PLB 
-- PLB_dcrRead           - PLB read signal to DCR
-- PLB_dcrWrite          - PLB write signal to DCR
-- PLB_dcrClk            - PLB to DCR clk
-- PLB_dcrRst            - PLB to DCR reset 
-----------------------------------------------------------------------------
-- Definition of Generics
-----------------------------------------------------------------------------


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned."+";

entity plbv46_dcr_bridge_core is

  port (
    -- PLBv46_IPIF Signals
    Bus2IP_Clk          : in  std_logic;
    Bus2IP_Reset        : in  std_logic;
    Bus2IP_Addr         : in  std_logic_vector(0 to 31);
    Bus2IP_Data         : in  std_logic_vector(0 to 31);
    Bus2IP_BE           : in  std_logic_vector(0 to 3);
    Bus2IP_CS           : in  std_logic;
    Bus2IP_RdCE         : in  std_logic;
    Bus2IP_WrCE         : in  std_logic;

    IP2Bus_RdAck        : out std_logic;
    IP2Bus_WrAck        : out std_logic;
    IP2Bus_Error        : out std_logic;
    IP2Bus_Data         : out std_logic_vector(0 to 31);

    -- DCR Master Signals
    -- core signals
    DCR_plbDBusIn    : in  std_logic_vector(0 to 31);
    DCR_plbAck       : in  std_logic;

    PLB_dcrABus      : out std_logic_vector(0 to 9);
    PLB_dcrDBusOut   : out std_logic_vector(0 to 31);
    PLB_dcrRead      : out std_logic;
    PLB_dcrWrite     : out std_logic;

    PLB_dcrClk       : out std_logic;
    PLB_dcrRst       : out std_logic
    );
end entity plbv46_dcr_bridge_core;
-------------------------------------------------------------------------------
architecture implemented of plbv46_dcr_bridge_core is
-------------------------------------------------------------------------------
-- local signal declaration section
  signal plb_dcrRead_i       : std_logic;
  signal plb_dcrWrite_i      : std_logic;
  signal ip2Bus_RdAck_i      : std_logic;
  signal ip2Bus_WrAck_i      : std_logic;
  signal dcr_ack_posedge     : std_logic;
  signal dcr_plbAck_d1       : std_logic;
  signal timeout             : std_logic;
  signal ip2Bus_Error_i      : std_logic;
  signal timeout_cnt         : std_logic_vector(0 to 3);
-------------------------------------------------------------------------------
begin  -- architecture implemented
-------------------------------------------------------------------------------
  --////////////////////////////////////////////////////////////////////////////
  -- Main Body of Code
  --////////////////////////////////////////////////////////////////////////////
  -- NOTE: This design is supporting DCR reads and writes bridged from
  -- PLBV46. Since DCR reads and writes are defined on words only, the
  -- incoming PLBV46 reads and writes that are to be retargetted to the DCR bus
  -- must also be for words only. If the PLBV46 byte enables do not correspond
  -- to a word transfer, an error will be returned.

  -- DCR signals just pass through from IPIF/PLBv46, but are renamed
  -- to DCR names to help make it clear how to hook things up.
PLB_dcrClk <= Bus2IP_Clk;
PLB_dcrRst <= Bus2IP_Reset;

-------------------------------------------------------------------------------
-- PLB_DCRREAD_I_PROC
-- latch and hold read request strobe
-- synchronous reset (active high)

PLB_DCRREAD_I_PROC: process (Bus2IP_Clk) is
 begin
  if Bus2IP_Clk'EVENT and Bus2IP_Clk = '1' then
    if (Bus2IP_CS = '0' or IP2Bus_RdAck_i = '1' or 
                                       Bus2IP_Reset = '1' or timeout = '1') then
      plb_dcrRead_i <= '0';
    elsif (Bus2IP_RdCE = '1' and DCR_plbAck = '0') then
      plb_dcrRead_i <= '1';
    end if;
   end if;
end process PLB_DCRREAD_I_PROC;

PLB_dcrRead <= plb_dcrRead_i;

-------------------------------------------------------------------------------
-- PLB_DCRWRITE_I_PROC
-- latch and hold write request strobe
-- synchronous reset (active high)

PLB_DCRWRITE_I_PROC: process (Bus2IP_Clk) is
 begin
  if Bus2IP_Clk'EVENT and Bus2IP_Clk = '1' then
    if (Bus2IP_CS = '0' or IP2Bus_WrAck_i = '1' or 
                                       Bus2IP_Reset = '1' or timeout = '1') then
      plb_dcrWrite_i <= '0';
    elsif (Bus2IP_WrCE = '1' and DCR_plbAck = '0')then
      plb_dcrWrite_i <= '1';
    end if;
  end if;
end process PLB_DCRWRITE_I_PROC;

PLB_dcrWrite <= plb_dcrWrite_i;

-------------------------------------------------------------------------------
-- process REG_DCR_ABUS_PROC
-- DCR address bus is 10 bits and points to 32 bit words, so pick up the
-- corresponding address bits from PLBv46

REG_DCR_ABUS_PROC : process (Bus2IP_Clk) is
begin
  if Bus2IP_Clk'EVENT and Bus2IP_Clk = '1' then
     PLB_dcrABus <= Bus2IP_Addr(20 to 29);
  end if;
end process REG_DCR_ABUS_PROC;
-------------------------------------------------------------------------------
-- process DCR_DBUS_OUT_PROC
-- PLB_dcrDBusOut is set to 0xFFFF_FFFF during reads operations so it
-- will return 0xFFFF_FFFF when read times out. DCR specifies that timeout
-- errors are ignored back to the CPU so setting the default read to all
-- 1's will help identify timeouts. Data bus out drives 00000000 during
-- reset as required by DCR spec.

DCR_DBUS_OUT_PROC: process (Bus2IP_Clk) is
begin
  if Bus2IP_Clk'EVENT and Bus2IP_Clk = '1' then
    if Bus2IP_Reset = '1' then
      PLB_dcrDBusOut <= (others => '0');
    elsif (plb_dcrRead_i = '1' or Bus2IP_RdCE = '1') then
      PLB_dcrDBusOut <= (others => '1');
    else
      PLB_dcrDBusOut <= Bus2IP_Data;
    end if;
  end if;
end process DCR_DBUS_OUT_PROC;
-------------------------------------------------------------------------------
-- connect input data lines to ip2bus_data, so that it will be returned to ipif
IP2Bus_Data <= DCR_plbDBusIn;

-------------------------------------------------------------------------------
-- process TIMOUT_CNT_PROC
-- Generate timeouts after 16 cycles. The timeout counter is enabled during
-- DCR operations and is reset during system reset or when an ack is sent
-- back to the IPIF. Note that an ack is sent back to the IPIF after a timeout
-- has been issued or if a DCR slave responds.

TIMOUT_CNT_PROC : process (Bus2IP_Clk) is
begin
  if Bus2IP_Clk'EVENT and Bus2IP_Clk = '1' then
    if (Bus2IP_CS = '0' or IP2Bus_RdAck_i = '1' or IP2Bus_WrAck_i = '1'
                                                     or Bus2IP_Reset = '1') then
      timeout_cnt <= "0000";
    elsif (plb_dcrRead_i = '1' or plb_dcrWrite_i = '1') then
      timeout_cnt <= timeout_cnt + 1;
    end if;
  end if;
end process TIMOUT_CNT_PROC;
-------------------------------------------------------------------------------
timeout <= '1' when timeout_cnt = "1111" else '0';

-------------------------------------------------------------------------------
-- process DCR_plbAck_PROC
-- detect only the posedge of DCR slave acks since the DCR slave may run
-- on a slower clock and thus its ack would be seen asserted for more than
-- 1 cycle

DCR_plbAck_PROC : process (Bus2IP_Clk) is
begin
  if Bus2IP_Clk'EVENT and Bus2IP_Clk = '1' then
    dcr_plbAck_d1 <= DCR_plbAck;
  end if;
end process DCR_plbAck_PROC;

dcr_ack_posedge <= DCR_plbAck and (not dcr_plbAck_d1);
-------------------------------------------------------------------------------
-- generate an ack back to the IPIF when a DCR slave responds or if a timeout
-- occurs
IP2Bus_RdAck_i <= plb_dcrRead_i and (dcr_ack_posedge or timeout);
IP2Bus_RdAck   <= IP2Bus_RdAck_i;

IP2Bus_WrAck_i <= plb_dcrWrite_i and (dcr_ack_posedge or timeout);
IP2Bus_WrAck   <= IP2Bus_WrAck_i;
-------------------------------------------------------------------------------
-- Generate a PLB error on DCR timeout or if less than a full
-- word of data is transferred (BE not 1111)
ip2Bus_Error_i <= '1' when (
                          (timeout = '1' and dcr_ack_posedge = '0')
                          or 
                          ((Bus2IP_BE /= "1111") and Bus2IP_CS = '1')
                          ) else '0';
-------------------------------------------------------------------------------
--DCR_Error_REG_PROC
--this process is to register the error signal.
-----------------------------------------------
DCR_Error_REG_PROC : process (Bus2IP_Clk) is
begin
  if Bus2IP_Clk'EVENT and Bus2IP_Clk = '1' then
    IP2Bus_Error <= ip2Bus_Error_i;
  end if;
end process DCR_Error_REG_PROC;
-------------------------------------------------------------------------------

end architecture implemented;
