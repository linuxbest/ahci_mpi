---------------------------------------------------------------------------
-- port_arbiter
-------------------------------------------------------------------------------
--
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
-- Copyright 2005, 2006, 2007, 2008 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--
---------------------------------------------------------------------------
-- Filename:          port_arbiter.vhd
-- Description:       
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  sdma.vhd
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
-- Author:      Jeff Hao
-- History:
--  JYH     02/04/05
-- ~~~~~~
--  - Initial EDK Release
-- ^^^^^^
--  GAB     10/02/06
-- ~~~~~~
--  - Converted from verilog to vhdl
-- 
--  MHG     5/20/08
-- ~~~~~~
--  - Updated to proc_common_v3_00_a^^^^^
--^^^^^^^
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
use ieee.numeric_std.all;    
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.ipif_pkg.all;

library unisim;
use unisim.vcomponents.all;

library mpmc_v6_03_a;
use mpmc_v6_03_a.all;
use mpmc_v6_03_a.sdma_pkg.all;

-------------------------------------------------------------------------------
entity sdma_port_arbiter is
    generic(
        TIMEOUTPERIOD           : integer := 255  -- Default to 256 Clock Cycles
    );
    port(
        LLink_Clk               : in  std_logic;
        LLink_Rst               : in  std_logic;
        TX_Port_Request         : in  std_logic;      
        TX_Port_Grant           : out std_logic;      
        TX_Port_Busy            : in  std_logic;      
        RX_Port_Request         : in  std_logic;      
        RX_Port_Grant           : out std_logic;      
        RX_Port_Busy            : in  std_logic;      
        TXNRX_Active            : out std_logic;   
        tx_desc_update_o	: in  std_logic;
        Timeout                 : out std_logic       
    );
end sdma_port_arbiter;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_port_arbiter is


-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal busy                 : std_logic;
signal timeoutcounter       : std_logic_vector(9 downto 0);
signal tx_port_grant_i      : std_logic;
signal rx_port_grant_i      : std_logic;
signal txnrx_active_i       : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

TX_Port_Grant   <= tx_port_grant_i  ;
RX_Port_Grant   <= rx_port_grant_i  ;
TXNRX_Active    <= txnrx_active_i   ;


  Busy <= tx_port_grant_i or TX_Port_Busy or rx_port_grant_i or RX_Port_Busy;

  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1') then
      if (LLink_Rst = '1' or tx_port_grant_i = '1') then
        tx_port_grant_i   <= '0';
      else
        if (Busy = '0' and TX_Port_Request = '1' and (txnrx_active_i = '0' or RX_Port_Request = '0')) then
          tx_port_grant_i <= '1';

        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin

    if(LLink_Clk'event and LLink_Clk = '1') then
      if (LLink_Rst = '1' or rx_port_grant_i = '1') then
        rx_port_grant_i   <= '0';
      else
        if (Busy = '0' and  tx_desc_update_o = '0' and RX_Port_Request = '1' and (txnrx_active_i = '1' or TX_Port_Request = '0')) then
        -- mgg added tx_desc_update_o ='0' to equation so that coal count
        --is updated correctly
          rx_port_grant_i <= '1';
        end if;
      end if;
    end if;
  end process;


  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1') then
      if (LLink_Rst = '1') then
        txnrx_active_i   <= '0';
      else
        if (tx_port_grant_i = '1' or rx_port_grant_i = '1') then
          txnrx_active_i <= tx_port_grant_i;
        end if;
      end if;
    end if;
  end process;

  Timeout <= '1' when (to_integer(unsigned(TimeoutCounter)) = TIMEOUTPERIOD) else '0';
-- Timeout = 0;

  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1' )then
      if (LLink_Rst = '1') then
        TimeoutCounter <= (others => '0');
      elsif (((TX_Port_Busy = '1' or tx_desc_update_o ='0') and RX_Port_Request = '1' ) or (RX_Port_Busy = '1' and TX_Port_Request = '1')) then
        TimeoutCounter    <= std_logic_vector(unsigned(TimeoutCounter) + 1);
      else
        TimeoutCounter <= (others => '0');
      end if;
    end if;
  end process;
end implementation;
