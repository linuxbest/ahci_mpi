-------------------------------------------------------------------------------
-- channel_status_reg.vhd
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
-- Filename:          channel_status_reg.vhd
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
--  - Modified bit positions in status register to match hard dma
--  - Added tail pointer error bit
-- ^^^^^^
--  GAB     5/18/07
-- ~~~~~~
-- Fixed error bit ordering the tailpointer error bit was in the wrong bit
-- position which threw all other bits off by 1.
-- ^^^^^^
--  GAB     8/13/07
-- ~~~~~~
--  - Removed combinatorial logic from error flag to fix timing path.
-- 
--  MHG     5/20/08
-- ~~~~~~
--  - Updated to proc_common_v3_00_a^^^^^
--^^^^^^
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
entity sdma_channel_status_reg is
  port(
   LLink_Clk                : in  std_logic;                   
   RST                      : in  std_logic;                   
   DI                       : in  std_logic_vector(0 to 31);   
   DO_DCR                   : out std_logic_vector(0 to 31);  
   DO_Mem                   : out std_logic_vector(0 to 31);  
   -- Control Signals
   Detect_Busy_Wr           : in  std_logic;
   Detect_Curr_Ptr_Err      : in  std_logic;
   Detect_Nxt_Ptr_Err       : in  std_logic;
   Detect_Tail_Ptr_Err      : in  std_logic;
   Detect_Addr_Err          : in  std_logic;
   Detect_Completed_Err     : in  std_logic;
   Set_SDMA_Completed       : in  std_logic;
   Set_Start_Of_Packet      : in  std_logic;
   Set_End_Of_Packet        : in  std_logic;
   Set_Busy                 : in  std_logic;
   Detect_Stop              : in  std_logic;
   Detect_Null_Ptr          : in  std_logic;
   Mem_CE                   : in  std_logic;
   Error_Reset              : out std_logic
);
end sdma_channel_status_reg;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_channel_status_reg is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal SDMA_error_i                : std_logic;
signal SDMA_int_on_end_i           : std_logic;
signal SDMA_stop_on_end_i          : std_logic;
signal SDMA_completed_i            : std_logic;
signal SDMA_start_of_packet_i      : std_logic;
signal SDMA_end_of_packet_i        : std_logic;
signal SDMA_channel_busy_i         : std_logic;
signal SDMA_channel_reset_i        : std_logic;
signal SDMA_error_o                : std_logic;
signal SDMA_int_on_end_o           : std_logic;
signal SDMA_stop_on_end_o          : std_logic;
signal SDMA_completed_o            : std_logic;
signal SDMA_start_of_packet_o      : std_logic;
signal SDMA_end_of_packet_o        : std_logic;
signal SDMA_channel_busy_o         : std_logic;
signal SDMA_channel_reset_o        : std_logic;
signal SDMA_channel_reset_o2       : std_logic;

signal completed_err                : std_logic;
signal addr_err                     : std_logic;
signal nxt_ptr_err                  : std_logic;
signal curr_ptr_err                 : std_logic;
signal busy_wr                      : std_logic;
signal tail_ptr_err                 : std_logic;

signal error_reset_reg              : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin
   
-- Input Bits
SDMA_error_i            <= DI(0);
SDMA_int_on_end_i       <= DI(1);
SDMA_stop_on_end_i      <= DI(2);
SDMA_completed_i        <= DI(3); 
SDMA_start_of_packet_i  <= DI(4);
SDMA_end_of_packet_i    <= DI(5);
SDMA_channel_busy_i     <= DI(6);
--SDMA_channel_reset_i    <= DI(7);

   -- DCR Output Bits
--    DO_DCR(0 to 7) <= SDMA_error_o & SDMA_int_on_end_o & SDMA_stop_on_end_o & SDMA_completed_o & 
--                         SDMA_start_of_packet_o & SDMA_end_of_packet_o & SDMA_channel_busy_o & SDMA_channel_reset_o;
--    DO_DCR(8 to 26) <= (others => '0');
--    DO_DCR(27 to 31) <= completed_err & addr_err & nxt_ptr_err & curr_ptr_err & busy_wr;

-- Used internal and is also what is read via IPIC
DO_DCR(0 to 9)      <= (others => '0');
DO_DCR(10 to 15)    <= tail_ptr_err & completed_err & addr_err & nxt_ptr_err & curr_ptr_err & busy_wr;
DO_DCR(16 to 23)    <= (others => '0');
DO_DCR(24 to 31)    <= SDMA_error_o & SDMA_int_on_end_o & SDMA_stop_on_end_o
                     & SDMA_completed_o & SDMA_start_of_packet_o  
                     & SDMA_end_of_packet_o & SDMA_channel_busy_o     & '0';




   -- Used to update Descriptor
--    DO_Mem(0 to 7) <= '0' & SDMA_int_on_end_o & SDMA_stop_on_end_o & SDMA_completed_o & 
--                         SDMA_start_of_packet_o & SDMA_end_of_packet_o & "00";
--    DO_Mem(8 to 31) <= (others => '0');
-- Used to update Descriptor
DO_Mem(0 to 7) <= SDMA_error_o & SDMA_int_on_end_o & SDMA_stop_on_end_o & SDMA_completed_o & 
                     SDMA_start_of_packet_o & SDMA_end_of_packet_o & "00";
DO_Mem(8 to 31) <= (others => '0');
   
   
   
   -- SDMA_ERROR Reset Control
   -- Includes all errors except busy write error because the busy write error is asynchronous
   -- to the dma functions and due to mpmc functionality it is not safe to reset the dma.
   process(LLink_Clk)
   begin
     if(rising_edge(LLink_Clk)) then
       if(RST = '1') then
           error_reset_reg <= '0';
       else
         if (Detect_Curr_Ptr_Err = '1' or Detect_Nxt_Ptr_Err = '1'   or
             Detect_Addr_Err = '1'     or Detect_completed_err = '1' or Detect_Tail_Ptr_Err='1') then
           error_reset_reg <= '1';
         end if;
       end if;
     end if;
   end process;

Error_Reset <= error_reset_reg 
;--               or Detect_Curr_Ptr_Err 
--               or Detect_Nxt_Ptr_Err
--               or Detect_Addr_Err
--               or Detect_completed_err
--               or Detect_Tail_Ptr_Err;






   -- SDMA_ERROR
   process(LLink_Clk)
   begin
     if(rising_edge(LLink_Clk)) then
       if(RST = '1') then
         SDMA_error_o   <= '0';
       else
         if (Detect_Busy_Wr = '1' or Detect_Curr_Ptr_Err = '1' or Detect_Nxt_Ptr_Err = '1' or
             Detect_Addr_Err = '1' or Detect_completed_err = '1' or Detect_Tail_Ptr_Err='1') then
           SDMA_error_o <= '1';
         end if;
       end if;
     end if;
   end process;

  -- SDMA_INT_ON_END
  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        SDMA_int_on_end_o   <= '0';
      else
--        if (DCR_CE = '1' or Mem_CE = '1') then --GAB 1/8/07
        if (Mem_CE = '1') then
          SDMA_int_on_end_o <= SDMA_int_on_end_i;
        end if;
      end if;
    end if;
  end process;

  -- SDMA_STOP_ON_END
  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        SDMA_stop_on_end_o   <= '0';
      else
--        if (DCR_CE = '1' or Mem_CE = '1') then --GAB 1/8/07
        if (Mem_CE = '1') then
          SDMA_stop_on_end_o <= SDMA_stop_on_end_i;
        end if;
      end if;
    end if;
  end process;

  -- SDMA_COMPLETED
  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        SDMA_completed_o        <= '0';
      else if (Set_SDMA_Completed = '1') then
             SDMA_completed_o   <= '1';
           else
--             if (DCR_CE = '1' or Mem_CE = '1') then --GAB 1/8/07
             if (Mem_CE = '1') then
               SDMA_completed_o <= SDMA_completed_i;
             end if;
           end if;
      end if;
    end if;
  end process;

  -- SDMA_START_OF_PACKET
  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        SDMA_start_of_packet_o   <= '0';
      else
        if (Set_Start_Of_Packet = '1') then
          SDMA_start_of_packet_o <= '1';

        else
--          if (DCR_CE = '1' or Mem_CE = '1') then --GAB 1/8/07
          if (Mem_CE = '1') then
            SDMA_start_of_packet_o <= SDMA_start_of_packet_i;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- SDMA_END_OF_PACKET
  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        SDMA_end_of_packet_o     <= '0';
      else
        if (Set_End_Of_Packet = '1') then
          SDMA_end_of_packet_o   <= '1';
        else
--          if (DCR_CE = '1' or Mem_CE = '1') then --GAB 1/8/07
          if (Mem_CE = '1') then
            SDMA_end_of_packet_o <= SDMA_end_of_packet_i;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- SDMA_CHANNEL_BUSY
  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1' or SDMA_error_o = '1' or Detect_Stop = '1' or Detect_Null_Ptr = '1') then
        SDMA_channel_busy_o   <= '0';
      else
--        if (Write_Curr_Ptr = '1') then
        if (Set_Busy = '1') then
          SDMA_channel_busy_o <= '1';
        end if;
      end if;
    end if;
  end process;

  -- SDMA_CHANNEL_RESET
--GAB  process(LLink_Clk)
--GAB  begin
--GAB    if(rising_edge(LLink_Clk)) then
--GAB      if(RST = '1') then
--GAB        SDMA_channel_reset_o   <= '0';
--GAB      else
--GAB        if (DCR_CE = '1') then
--GAB          SDMA_channel_reset_o <= SDMA_channel_reset_i;
--GAB        end if;
--GAB      end if;
--GAB    end if;
--GAB  end process;
--GAB
--GAB  -- Edge Detect CHANNEL_RESET
--GAB  process(LLink_Clk)
--GAB  begin
--GAB    if(rising_edge(LLink_Clk)) then
--GAB      if(RST = '1') then
--GAB        SDMA_channel_reset_o2 <= '0';
--GAB      else
--GAB        SDMA_channel_reset_o2 <= SDMA_channel_reset_o;
--GAB      end if;
--GAB    end if;
--GAB  end process;
--GAB
--GAB  ChannelRST <= SDMA_channel_reset_o and not SDMA_channel_reset_o2;


-- Temporary Extra DCR Error Bits
  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        busy_wr   <= '0';
      else
        if (Detect_Busy_Wr = '1') then
          busy_wr <= '1';
        end if;
      end if;
    end if;
  end process;




  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        tail_ptr_err   <= '0';
      else
        if (Detect_Tail_Ptr_Err = '1') then
          tail_ptr_err <= '1';
        end if;
      end if;
    end if;
  end process;


  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        curr_ptr_err   <= '0';
      else
        if (Detect_Curr_Ptr_Err = '1') then
          curr_ptr_err <= '1';
        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        nxt_ptr_err   <= '0';
      else
        if (Detect_Nxt_Ptr_Err = '1') then
          nxt_ptr_err <= '1';
        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        addr_err   <= '0';
      else
        if (Detect_Addr_Err = '1') then
          addr_err <= '1';
        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(RST = '1') then
        completed_err   <= '0';
      else
        if (Detect_Completed_Err = '1') then
          completed_err <= '1';
        end if;
      end if;
    end if;
  end process;

  end implementation;
