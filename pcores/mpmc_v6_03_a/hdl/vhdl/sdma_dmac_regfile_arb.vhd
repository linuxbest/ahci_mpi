-------------------------------------------------------------------------------
-- dmac_regfile_arb.vhd
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
-------------------------------------------------------------------------------
-- Filename:        dmac_regfile_arb.vhd
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
--^ ^^^^^^
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
use mpmc_v6_03_a.sdma_pkg.all;

-------------------------------------------------------------------------------
entity sdma_dmac_regfile_arb is
  port(
    LLink_Clk           : in  std_logic; 
    LLink_Rst           : in  std_logic; 
    DCR_Request         : in  std_logic;       
    DCR_Busy            : in  std_logic;       
    DCR_Grant           : out std_logic;       
    TX_Request          : in  std_logic;       
    TX_Busy             : in  std_logic;       
    TX_Grant            : out std_logic;       
    RX_Request          : in  std_logic;       
    RX_Busy             : in  std_logic;       
    RX_Grant            : out std_logic;       
    Grant_Hold          : out std_logic_vector(2 downto 0)  
    );
end sdma_dmac_regfile_arb;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_dmac_regfile_arb is
  
-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal RegFile_Busy     : std_logic;
signal Free_For_Ports   : std_logic;
signal Prev             : std_logic;
signal dcr_grant_i      : std_logic;
signal tx_grant_i       : std_logic;
signal rx_grant_i       : std_logic;
signal grant_hold_i     : std_logic_vector(2 downto 0);

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

DCR_Grant   <= dcr_grant_i;
TX_Grant    <= tx_grant_i;
RX_Grant    <= rx_grant_i;
Grant_Hold  <= grant_hold_i;

RegFile_Busy   <= DCR_Busy or TX_Busy or RX_Busy or dcr_grant_i or tx_grant_i or rx_grant_i;
Free_For_Ports <= not DCR_Request and not RegFile_Busy;

     process(LLink_Clk)
     begin
       if(LLink_Clk'event and LLink_Clk = '1')then
         if (LLink_Rst='1' or DCR_Busy='1')then-- or dcr_grant_i = '1') then--GAB
           dcr_grant_i   <= '0';
         else
           if (DCR_Request = '1' and RegFile_Busy = '0') then
             dcr_grant_i <= '1';
           end if;
         end if;
       end if;
     end process;

     process(LLink_Clk)
     begin
       if(LLink_Clk'event and LLink_Clk = '1')then
         if (LLink_Rst = '1' or tx_grant_i = '1')then
           tx_grant_i <= '0';
       else
         if (Free_For_Ports = '1' and TX_Request = '1' and (Prev = '0' or RX_Request = '0')) then
           tx_grant_i <= '1';
         end if;
       end if;
     end if;
   end process;

  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1')then
      if (LLink_Rst = '1' or rx_grant_i = '1') then
        rx_grant_i   <= '0';
      else
        if (Free_For_Ports = '1' and RX_Request = '1' and (Prev = '1' or TX_Request = '0')) then
          rx_grant_i <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Keep track of previous grant
  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1')then
      if (LLink_Rst = '1') then
        Prev   <= '0';
      else
        if (tx_grant_i = '1' or rx_grant_i = '1') then
          Prev <= tx_grant_i;
        end if;
      end if;
    end if;
  end process;

  -- Keep track of who is using RegFile
  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1')then
      if (LLink_Rst = '1') then
        grant_hold_i   <= "001";
      else
        if (dcr_grant_i = '1' or tx_grant_i = '1' or rx_grant_i = '1') then
          grant_hold_i <= rx_grant_i & tx_grant_i & dcr_grant_i;
        end if;
      end if;
    end if;
  end process;

  end implementation;
