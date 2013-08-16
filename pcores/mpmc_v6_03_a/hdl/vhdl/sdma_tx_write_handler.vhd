-------------------------------------------------------------------------------
-- sdma_tx_write_handler.vhd
-------------------------------------------------------------------------------
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
----------------------------------------------------------------------------
-- Filename:        sdma_tx_write_handler.vhd
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
entity sdma_tx_write_handler is
  port(
    -- Global Signals
    LLink_Clk                       : in  std_logic;                
    LLink_Rst                       : in  std_logic;                

    -- Port Interface Signals
    wrDataBE_Pos                    : out std_logic_vector(3 downto 0);   
    wrDataBE_Neg                    : out std_logic_vector(3 downto 0);   
    wrDataAck_Pos                   : out std_logic;                      
    wrDataAck_Neg                   : out std_logic;                      
    Wr_push_32bit		: out std_logic;  
    wrComp                          : out std_logic;                      
    wr_rst                          : out std_logic;                      
    wr_fifo_busy                    : in  std_logic;                      
    wr_fifo_almostfull              : in  std_logic;                      

    -- Port Controller Signals
    TX_CL8W_Start                   : in  std_logic;                      
    TX_CL8W_Comp                    : out std_logic;                      

    -- Channel Reset Signals
    TX_ChannelRST                   : in  std_logic;                      

    -- Datapath Signals
    SDMA_Sel_Status_Writeback      : out std_logic_vector(1 downto 0)    
    );
end sdma_tx_write_handler;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_tx_write_handler is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
signal WrPushCount          : std_logic_vector(2 downto 0);
signal WrPush               : std_logic;
signal Active               : std_logic;
signal Toggle               : std_logic;
signal wr_fifo_full         : std_logic;
signal Wr_Rst_Pending       : std_logic;
signal tx_cl8w_comp_i       : std_logic;

-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------
begin
TX_CL8W_Comp <= tx_cl8w_comp_i;

wrDataBE_Pos               <= "0000";
wrDataBE_Neg(2 downto 0)   <= "000";
wrDataBE_Neg(3)            <= '1'  when (to_integer(unsigned(WrPushCount)) = 3) else '0';
WrPush                     <= Active and not wr_fifo_full;
wrDataAck_Pos              <= WrPush and not Toggle;
wrDataAck_Neg              <= WrPush and Toggle;
Wr_push_32bit		<= WrPush;
wrComp                     <= '1'  when (to_integer(unsigned(WrPushCount)) = 7) and WrPush = '1' else '0';
SDMA_Sel_Status_Writeback <= "10" when (to_integer(unsigned(WrPushCount)) = 3)                  else "00";

tx_cl8w_comp_i <= '1' when (to_integer(unsigned(WrPushCount)) = 7) and WrPush = '1' else '0';

  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1')then
      if (LLink_Rst = '1' or TX_ChannelRST = '1' or tx_cl8w_comp_i = '1') then  
--      if (LLink_Rst = '1' or tx_cl8w_comp_i = '1') then --GAB 1/6/07
        Active   <= '0';
      else
        if (TX_CL8W_Start = '1') then
          Active <= '1';
        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    -- Write Push Counter
    if(LLink_Clk'event and LLink_Clk = '1')then
--      if (LLink_Rst = '1') then
      if (LLink_Rst = '1' or TX_ChannelRST = '1') then
        WrPushCount   <= (others =>'0');
      else
        if (WrPush = '1') then
          WrPushCount <= std_logic_vector(unsigned(WrPushCount) + 1);

        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    -- Toggle Pushes Between Pos and Neg
    if(LLink_Clk'event and LLink_Clk = '1')then
--      if (LLink_Rst = '1') then
      if (LLink_Rst = '1' or TX_ChannelRST = '1') then
        Toggle   <= '0';
      else
        if (WrPush = '1') then
          Toggle <= not Toggle;
        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    -- Delay Write Fifo Full Signals
    if(LLink_Clk'event and LLink_Clk = '1')then
      if (LLink_Rst = '1') then
        wr_fifo_full <= '0';
      else
        wr_fifo_full <= wr_fifo_almostfull;
      end if;
    end if;
  end process;

  wr_rst <= '0';

end implementation;
