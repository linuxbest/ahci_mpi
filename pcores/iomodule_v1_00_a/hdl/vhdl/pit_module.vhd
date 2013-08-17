-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- pit_module.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2011 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and 
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-- Filename:        pit_module.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              pit_module.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision$
-- Date:            $Date$
--
-- History:
--   goran  2007-12-19    First Version
--
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

entity PIT_Module is
  generic (
    C_USE_PIT      : integer := 0;
    C_PIT_SIZE     : integer := 16;
    C_PIT_READABLE : integer := 1
    );
  port (
    Clk               : in  std_logic;
    Reset             : in  boolean;
    PIT_Count_En      : in  std_logic;
    PIT_Write_Preload : in  std_logic;
    PIT_Write_Ctrl    : in  std_logic;
    PIT_Read          : in  std_logic;
    Write_Data        : in  std_logic_vector(31 downto 0);
    PIT_Data          : out std_logic_vector(C_PIT_SIZE-1 downto 0);
    PIT_Toggle        : out std_logic;
    PIT_Interrupt     : out std_logic);
end entity PIT_Module;

library unisim;
use unisim.vcomponents.all;

architecture IMP of PIT_Module is
begin  -- architecture IMP

  Using_PIT : if (C_USE_PIT /= 0) generate
    signal preload_value   : std_logic_vector(C_PIT_SIZE-1 downto 0);
    signal preload_written : std_logic;

    signal reload   : std_logic;
    signal count_en : std_logic;

    signal count_enabled : std_logic;

    -- Counter signals
    signal count_load_n    : std_logic;
    signal cnt             : std_logic_vector(C_PIT_SIZE-1 downto 0);
    signal new_cnt         : std_logic_vector(C_PIT_SIZE-1 downto 0);
    signal new_cnt_di      : std_logic_vector(C_PIT_SIZE-1 downto 0);
    signal carry           : std_logic_vector(C_PIT_SIZE   downto 0);
    signal count           : std_logic_vector(C_PIT_SIZE-1 downto 0);
    signal count_wrap      : std_logic;
    signal pit_interrupt_i : std_logic;
    signal pit_toggle_i    : std_logic;
  begin

    --------------------------------------------------------------------------------------------------
    -- Preload register
    --------------------------------------------------------------------------------------------------
    PreLoad_Handler : process (Clk) is
    begin  -- process PreLoad_Handler
      if Clk'event and Clk = '1' then   -- rising clock edge
        if Reset then                   -- synchronous reset (active high)
          preload_value <= (others => '0');
        elsif (PIT_Write_Preload = '1') then
          preload_value <= Write_Data(C_PIT_SIZE-1 downto 0);
        end if;
      end if;
    end process PreLoad_Handler;

    --------------------------------------------------------------------------------------------------
    -- Control Register
    --------------------------------------------------------------------------------------------------
    Ctrl_Handler : process (Clk) is
    begin  -- process Ctrl_Handler
      if Clk'event and Clk = '1' then   -- rising clock edge
        if Reset then                   -- synchronous reset (active high)
          reload          <= '0';
          count_en        <= '0';
          count_load_n    <= '1';
          preload_written <= '0';
        else
          preload_written <= PIT_Write_Preload;
          if (PIT_Write_Ctrl = '1') then
            reload   <= Write_Data(1);
            count_en <= Write_Data(0);
          end if;
          if ((count_wrap = '1') and (reload = '0') and (count_enabled = '1') and (count_load_n = '1')) then
            count_en <= '0';
          end if;

          -- reach -1 and will load_counter with preload value
          if ((count_wrap = '1') and (reload = '1') and (count_enabled = '1')) then
            count_load_n <= '0';
          end if;

          -- if we have written to preload register, load counter with preload value next time we count
          if (preload_written = '1') then
            count_load_n <= '0';
          end if;

          -- Counter is now loaded so remove count_load_n
          if (count_load_n = '0') and (count_enabled = '1') then
            count_load_n <= '1';
          end if;

        end if;
      end if;
    end process Ctrl_Handler;

    count_enabled <= count_en and PIT_Count_En;

    --------------------------------------------------------------------------------------------------
    -- Counter
    --------------------------------------------------------------------------------------------------
    carry(0) <= '0';

    All_Bits : for I in 0 to C_PIT_SIZE - 1 generate
    begin

      Count_LUT : LUT3
        generic map(
          INIT => X"72"
          )
        port map (
          O  => new_cnt(I),             -- [out]
          I0 => count_load_n,           -- [in]
          I1 => count(I),               -- [in]
          I2 => preload_value(I));      -- [in]

      MULT_AND_I : MULT_AND
        port map (
          I0 => count_load_n,           -- [in]
          I1 => count(I),               -- [in]
          LO => new_cnt_di(I));         -- [out]

      MUXCY_L_I1 : MUXCY_L
        port map (
          DI => new_cnt_di(I),          -- [in  std_logic S = 0]
          CI => carry(I),               -- [in  std_logic S = 1]
          S  => new_cnt(I),             -- [in  std_logic (Select)]
          LO => carry(I+1));            -- [out std_logic]

      -- cnt counts down
      XORCY_I1 : XORCY
        port map (
          LI => new_cnt(I),             -- [in  std_logic]
          CI => carry(I),               -- [in  std_logic]
          O  => cnt(I));                -- [out std_logic]

    end generate All_Bits;

    count_wrap <= not carry(C_PIT_SIZE);

    Counter : process (Clk) is
    begin  -- process Counter
      if Clk'event and Clk = '1' then   -- rising clock edge
        if Reset then
          count <= (others => '0');
        elsif (count_enabled = '1') then
          count <= cnt;
        end if;
      end if;
    end process Counter;

    Interrupt_Handler : process (Clk) is
    begin  -- process Interrupt_Handler
      if Clk'event and Clk = '1' then   -- rising clock edge
        if Reset then                   -- synchronous reset (active high)
          pit_interrupt_i <= '0';
        else
          pit_interrupt_i <= count_wrap and count_enabled and count_load_n;
        end if;
      end if;
    end process Interrupt_Handler;

    PIT_Interrupt <= pit_interrupt_i;

    Toggle_Handler : process (Clk) is
    begin 
      if Clk'event and Clk = '1' then 
        if Reset then
          pit_toggle_i <= '0';
        elsif pit_interrupt_i = '1' then
          pit_toggle_i <= not pit_toggle_i;
        end if;
      end if;
    end process Toggle_Handler;

    PIT_Toggle <= pit_toggle_i;
    
    --------------------------------------------------------------------------------------------------
    -- Read register
    --------------------------------------------------------------------------------------------------
    Readable_Counter : if (C_PIT_READABLE /= 0) generate
    begin

      PIT_Read_Handler : process (Clk) is
      begin  -- process PIT_Read_Handler
        if Clk'event and Clk = '1' then  -- rising clock edge
          if PIT_Read = '0' then
            PIT_Data <= (others => '0');
          else
            PIT_Data                        <= (others => '0');
            PIT_Data(C_PIT_SIZE-1 downto 0) <= count;
          end if;
        end if;
      end process PIT_Read_Handler;

    end generate Readable_Counter;

    Dont_Read_Counter: if (C_PIT_READABLE = 0) generate
      PIT_Data <= (others => '0');
    end generate Dont_Read_Counter;

  end generate Using_PIT;

  Not_Using_Pit : if (C_USE_PIT = 0) generate
  begin
    PIT_Data      <= (others => '0');
    PIT_Interrupt <= '0';
    PIT_Toggle    <= '0';
  end generate Not_Using_Pit;

end architecture IMP;
