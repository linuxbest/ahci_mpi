---------------------------------------------------------------------------
-- read_data_delay 
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
-- Filename:          read_data_delay.vhd
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
entity sdma_read_data_delay is
    generic(
        C_PI_RDDATA_DELAY           : integer:= 0;
        C_PI2LL_CLK_RATIO           : integer:= 1
    );
    port(
        LLink_Clk                   : in std_logic;        
        LLink_Rst                   : in std_logic;        
        PI_RdPop                    : out std_logic;       
        PI_Empty                    : in std_logic;        
        SDMA_RdPop                  : in std_logic;        
        SDMA_Empty                  : out std_logic;       
        SDMA_CL8R_Start             : in std_logic;        
        SDMA_B16R_Start             : in std_logic;        
        Delay_Reg_CE                : out std_logic; 
        extra_d_reg_ce		: out std_logic;
        PI_RdFIFO_Pop_32_bit	: in std_logic;
        PI_RdFIFO_Pop_32_bit_o	: out std_logic;
        Delay_Reg_Sel               : out std_logic_Vector(1 downto 0)           
    );
end sdma_read_data_delay;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_read_data_delay is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
constant DLY_TC             :  std_logic_vector(1 downto 0) 
                                := std_logic_vector(
                                to_unsigned(C_PI_RDDATA_DELAY 
                                / C_PI2LL_CLK_RATIO,2));
  
-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal popcount             : std_logic_vector(4 downto 0);
signal delaycount           : std_logic_vector(1 downto 0);
signal delay_cnt_inc        : std_logic;
signal delay_cnt_dec        : std_logic;

signal early_pop            : std_logic;
signal early_pop1           : std_logic;
signal early_pop2           : std_logic;
signal early_pop3           : std_logic;
signal pop_d1               : std_logic;
signal pop_d2               : std_logic;
signal pop_d3               : std_logic;
signal delay_reg_ce_i       : std_logic;
signal pi_rdpop_i           : std_logic;
signal sdma_empty_i         : std_logic;
signal delay_reg_temp         : std_logic;


-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin
Delay_Reg_CE <= delay_reg_ce_i;
PI_RdPop     <= pi_rdpop_i;
  
GEN_rx_rddata_delay2 : if ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) generate
          sdma_empty_i   <= '0' when (PI_Empty='0' and early_pop2='0') or (popcount = "00010") or (popcount = "00001")
                     else  '1';
          --pi_rdpop_i      <= (early_pop1 or (early_pop3 and not early_pop2) or SDMA_RdPop) and not PI_Empty;
           PI_RdFIFO_Pop_32_bit_o <= (early_pop2 or PI_RdFIFO_Pop_32_bit) and not PI_Empty;
           pi_rdpop_i      <= (early_pop2 or SDMA_RdPop) and not PI_Empty;
          delay_reg_ce_i<= pop_d2;-- mgg added this equation to create seperate pop for 32 bit sdma
          --delay_reg_temp <= (pop_d2 xor pop_d3);
          delay_reg_ce_i<= pop_d2;
          Delay_Reg_Sel <= delaycount;
          early_pop     <= early_pop2;
          extra_d_reg_ce<= early_pop2 and (not early_pop1);
end generate;

GEN_rx_drdata_delay1 : if (((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) 
                        or ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))) generate
          sdma_empty_i   <='0' when(PI_Empty='0' and early_pop1='0') or (popcount = "00001")
                     else '1';
                   
          pi_rdpop_i      <= (early_pop1 or SDMA_RdPop) and not PI_Empty;
          PI_RdFIFO_Pop_32_bit_o <= (early_pop1 or PI_RdFIFO_Pop_32_bit) and not PI_Empty;
         -- mgg added this equation to create seperate pop for 32 bit sdma
          delay_reg_ce_i<= pop_d1;
          Delay_Reg_Sel <= delaycount;
          early_pop     <= early_pop1;
          extra_d_reg_ce <='0';
end generate;

GEN_rddata_delay0 : if not((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) 
                  and not(((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) 
                  or      ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))) generate
          sdma_empty_i   <= PI_Empty;
          pi_rdpop_i      <= SDMA_RdPop ;
          PI_RdFIFO_Pop_32_bit_o <= PI_RdFIFO_Pop_32_bit and not PI_Empty; 
          -- mgg added this equation to create seperate pop for 32 bit sdma
          delay_reg_ce_i<= '0';
          Delay_Reg_Sel <= (others => '0');
          early_pop     <= '0';
          extra_d_reg_ce <= '0';
end generate;

REG_EMPTY : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                SDMA_Empty <= '1';
            else
              SDMA_Empty <= sdma_empty_i;
            end if;
        end if;
    end process REG_EMPTY; 

EARLY_POP1_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                early_pop1 <= '0';
            elsif(SDMA_B16R_Start = '1' or SDMA_CL8R_Start='1')then
                early_pop1 <= '1';
            elsif(PI_Empty='0')then
                early_pop1 <= '0';
            end if;
        end if;
    end process EARLY_POP1_PROCESS;
            
EARLY_POP2_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                early_pop2 <= '0';
            elsif(SDMA_B16R_Start = '1' or SDMA_CL8R_Start = '1')then
                early_pop2 <= '1';
            elsif(PI_Empty='0' and early_pop1='0')then
                early_pop2 <= '0';
            end if;
        end if;
    end process EARLY_POP2_PROCESS;

process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              early_pop3 <= '0';
              
            else
              early_pop3 <= early_pop2;
              
            end if;
          end if;
    end process; 
   
         

POP_COUNT_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                popcount <= (others => '0');
            elsif (SDMA_B16R_Start='1')then
                popcount <= "10000";    --16
            elsif (SDMA_CL8R_Start='1')then
                popcount <= "00100";     --4
            elsif (SDMA_RdPop='1')then
                popcount <= std_logic_vector(unsigned(popcount) - 1);
   
            end if;
        end if;
    end process POP_COUNT_PROCESS;

REG_POP : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                pop_d1 <= '0';
                pop_d2 <= '0';
                pop_d3 <= '0';
            else
                pop_d1 <= pi_rdpop_i;
                pop_d2 <= pop_d1;
                pop_d3 <= pop_d2;
            end if;
        end if;
    end process REG_POP;
    

delay_cnt_inc <= delay_reg_ce_i when (delaycount < DLY_TC)
            else '0';



delay_cnt_dec <= SDMA_RdPop when (delaycount /= "00")
           else '0';
   
DELAY_COUNTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1' 
            or SDMA_B16R_Start = '1' 
            or SDMA_CL8R_Start = '1')then
                delaycount <= (others => '0');
            elsif(delay_cnt_inc = '1' and delay_cnt_dec = '0')then
                delaycount <= std_logic_vector(unsigned(delaycount) + 1);
            elsif(delay_cnt_inc = '0' and delay_cnt_dec = '1')then
                delaycount <= std_logic_vector(unsigned(delaycount) - 1);
            end if;
        end if;
    end process DELAY_COUNTER;
    
end implementation;          
