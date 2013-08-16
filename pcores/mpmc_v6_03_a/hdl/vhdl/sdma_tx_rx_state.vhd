-------------------------------------------------------------------------------
-- sdma_tx_rx_state.vhd
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
-- Filename:        sdma_tx_rx_state.vhd
-- Description:       
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
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
entity sdma_tx_rx_state is
  port(
    -- Global Signals
    LLink_Clk               : in  std_logic; 
    LLink_Rst               : in  std_logic; 
    -- Request Types
    CL8R                    : out std_logic; 
    B16                     : out std_logic; 
    CL8W                    : out std_logic; 
    -- Controls
    Channel_Reset           : in  std_logic;
    Channel_Start           : in  std_logic; 
    Channel_Read_Desc_Done  : in  std_logic; 
    Channel_Data_Done       : in  std_logic; 
    Channel_Continue        : in  std_logic; 
    Channel_Stop            : in  std_logic  
);
end sdma_tx_rx_state;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_tx_rx_state is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
type states is (IDLE, READ_DESC, RW_DATA, WRITE_DESC);
signal CS : states;

-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------
begin


   CL8R <= '1' when CS=READ_DESC    else '0';
   B16  <= '1' when CS=RW_DATA      else '0';
   CL8W <= '1' when CS=WRITE_DESC   else '0';
   
   -- Transmit/Receive State Machine
   process(LLink_Clk)
   begin
     if(LLink_Clk'event and LLink_Clk = '1')then
       if (LLink_Rst = '1') then
         CS         <= IDLE;
       else
         case (CS) is
           when IDLE       =>
             if (Channel_Start = '1' and Channel_Reset = '0') then
               CS   <= READ_DESC;
             else
               CS   <= IDLE;
             end if;
           when READ_DESC  =>
             if(Channel_Reset='1')then
                CS <= IDLE;
             elsif (Channel_Read_Desc_Done = '1') then
               CS   <= RW_DATA;
             else
               CS   <= READ_DESC;
             end if;
           when RW_DATA    =>
             if (Channel_Data_Done = '1') then
               CS   <= WRITE_DESC;
             else
               CS   <= RW_DATA;
             end if;
           when WRITE_DESC =>
             if (Channel_Stop = '1') then
               CS   <= IDLE;
             else
               if(Channel_Reset = '1')then
                 CS <= IDLE;
               elsif (Channel_Continue = '1') then
                 CS <= READ_DESC;
               else
                 CS <= WRITE_DESC;
               end if;
             end if;
           when others =>
            CS <= IDLE;
         end case; -- case(CS)
       end if;
     end if;
     end process;

   end implementation;
