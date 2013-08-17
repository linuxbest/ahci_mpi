-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- divide_part.vhd - Entity and architecture
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
-- Filename:        divide_part.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              divide_part.vhd
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

entity Divide_part is

  generic (
    Ratio : natural;
    First : boolean := true
    );

  port (
    Clk        : in  std_logic;
    Rst        : in  std_logic;
    Clk_En     : in  std_logic;
    Clk_En_Out : out std_logic
    );

end entity Divide_part;


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.numeric_std.all;

architecture VHDL_RTL of Divide_part is

  signal loop_Bit   : std_logic;
  signal loop_Bit_i : std_logic;

  -- Set clock enable during reset
  signal Clk_En_i   : std_logic;

  -- Previous cycle reset, used to determine when to shift in a 1
  signal Rst_d1     : std_logic := '0';

  -- This prevents an X from showing up in ModelSim
  -- by simulating the default value in the hardware
  signal Clk_En_Out_i : std_logic := '0';

  constant Nr_Of_SRL16      : natural                      := 1 + ((Ratio-1)/16);
  constant Last_SRL16_Ratio : natural                      := ((Ratio-1) mod 16);
  constant A                : std_logic_vector(3 downto 0) :=
    std_logic_vector(to_unsigned(Last_SRL16_Ratio, 4));

begin  -- architecture VHDL_RTL
  
  One_SRL16 : if (Nr_Of_SRL16 = 1) generate
  begin
    SRL16E_I : SRL16E
      generic map (
        INIT => X"0001")                -- [bit_vector]
      port map (
        CE  => Clk_En_i,                -- [in  std_logic]
        D   => loop_Bit_i,              -- [in  std_logic]
        Clk => Clk,                     -- [in  std_logic]
        A0  => A(0),                    -- [in  std_logic]
        A1  => A(1),                    -- [in  std_logic]
        A2  => A(2),                    -- [in  std_logic]
        A3  => A(3),                    -- [in  std_logic]
        Q   => loop_Bit);               -- [out std_logic]
  end generate One_SRL16;

  Two_SRL16 : if (Nr_Of_SRL16 = 2) generate

    signal shift   : std_logic;
    signal shift_i : std_logic;
    -- signal Emptys : std_logic_vector(0 to Nr_Of_SRL16);
  begin
    -- Shift in 0's during reset
    shift_i <= shift;

    -- The first SRLC16E
    SRLC16E_1 : SRLC16E
      generic map (
        INIT => X"0001")                -- [bit_vector]
      port map (
        CE  => Clk_En_i,                -- [in  std_logic]
        D   => loop_Bit_i,              -- [in  std_logic]
        Clk => Clk,                     -- [in  std_logic]
        A0  => '1',                     -- [in  std_logic]
        A1  => '1',                     -- [in  std_logic]
        A2  => '1',                     -- [in  std_logic]
        A3  => '1',                     -- [in  std_logic]
        Q15 => shift,                   -- [out  std_logic]
        Q   => open);                   -- [out std_logic]

    SRL16E_2 : SRL16E
      generic map (
        INIT => X"0000")                -- [bit_vector]
      port map (
        CE  => Clk_En_i,                -- [in  std_logic]
        D   => shift_i,                 -- [in  std_logic]
        Clk => Clk,                     -- [in  std_logic]
        A0  => A(0),                    -- [in  std_logic]
        A1  => A(1),                    -- [in  std_logic]
        A2  => A(2),                    -- [in  std_logic]
        A3  => A(3),                    -- [in  std_logic]
        Q   => loop_Bit);               -- [out std_logic]
  end generate Two_SRL16;

  More_Than_Two : if (Nr_Of_SRL16 > 2) generate

    signal shifts   : std_logic_vector(1 to Nr_Of_SRL16-1);
    signal shifts_i : std_logic_vector(1 to Nr_Of_SRL16-1);
    -- signal Emptys : std_logic_vector(0 to Nr_Of_SRL16);
  begin

    -- Shift in 0's during reset
    Shifts_I_Rst : for I in 1 to Nr_Of_SRL16-1 generate
       shifts_i(I) <= shifts(I);
    end generate Shifts_I_Rst;

    -- The first SRLC16E
    SRLC16E_1 : SRLC16E
      generic map (
        INIT => X"0001")                -- [bit_vector]
      port map (
        CE  => Clk_En_i,                -- [in  std_logic]
        D   => loop_Bit_i,              -- [in  std_logic]
        Clk => Clk,                     -- [in  std_logic]
        A0  => '1',                     -- [in  std_logic]
        A1  => '1',                     -- [in  std_logic]
        A2  => '1',                     -- [in  std_logic]
        A3  => '1',                     -- [in  std_logic]
        Q15 => shifts(1),               -- [out  std_logic]
        Q   => open);                   -- [out std_logic]

    The_Rest : for I in 1 to Nr_Of_SRL16-2 generate
    begin
      SRLC16E_I : SRLC16E
        generic map (
          INIT => X"0000")              -- [bit_vector]
        port map (
          CE  => Clk_En_i,              -- [in  std_logic]
          D   => shifts_i(I),           -- [in  std_logic]
          Clk => Clk,                   -- [in  std_logic]
          A0  => '1',                   -- [in  std_logic]
          A1  => '1',                   -- [in  std_logic]
          A2  => '1',                   -- [in  std_logic]
          A3  => '1',                   -- [in  std_logic]
          Q15 => shifts(I+1),           -- [out  std_logic]
          Q   => open);                 -- [out std_logic]

    end generate The_Rest;

    -- The last SRL16
    SRL16E_n : SRL16E
      generic map (
        INIT => X"0000")                -- [bit_vector]
      port map (
        CE  => Clk_En_i,                -- [in  std_logic]
        D   => shifts_i(Nr_Of_SRL16-1), -- [in  std_logic]
        Clk => Clk,                     -- [in  std_logic]
        A0  => A(0),                    -- [in  std_logic]
        A1  => A(1),                    -- [in  std_logic]
        A2  => A(2),                    -- [in  std_logic]
        A3  => A(3),                    -- [in  std_logic]
        Q   => loop_Bit);               -- [out std_logic]

  end generate More_Than_Two;

  -- Store if the previous cycle was a reset
  Clk_Rst_D1 : process (Clk) is
  begin
    if Clk'event and Clk = '1' then   -- rising clock edge
      Rst_d1 <= Rst;
    end if;
  end process Clk_Rst_D1;

  -- Set clock enable during reset, Rst_d1 is necessary to load
  -- the 1 bit in from loop_bit_i
  clk_en_i   <= Clk_En;-- or Rst or Rst_d1;

  -- Loops around from previous interrupt, or inserts after reset
  -- The reset pulse must be at least 17 cycles
  loop_Bit_i <= loop_Bit; --(loop_Bit or Rst_d1);

  -- Same signal, but internal version has default value for
  -- simulation
  Clk_En_Out <= Clk_En_Out_i;

  -----------------------------------------------------------------------------
  -- If the SRL16 is the first in a series then the output is a clean single
  -- clock pulse
  -----------------------------------------------------------------------------
  Is_First : if (First) generate
    Clk_En_Out_i <= loop_Bit;
  end generate Is_First;


  -----------------------------------------------------------------------------
  -- If not the first the output has to be masked so that it produce a single
  -- clock pulse
  -----------------------------------------------------------------------------
  not_First : if (not First) generate
    signal Out1 : std_logic;
  begin

    Out1_DFF : process (Clk) is
    begin  -- process Out1_DFF
      if Clk'event and Clk = '1' then   -- rising clock edge
        Out1 <= loop_Bit;
      end if;
    end process Out1_DFF;

    Out2_DFF : process (Clk) is
    begin  -- process Out2_DFF
      if Clk'event and Clk = '1' then   -- rising clock edge
        if (Out1 = '1') then
          Clk_En_Out_i <= Clk_En;
        end if;
      end if;
    end process Out2_DFF;
    
  end generate not_First;
end architecture VHDL_RTL;
