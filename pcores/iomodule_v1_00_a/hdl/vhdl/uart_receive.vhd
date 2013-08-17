-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- uart_receive.vhd - Entity and architecture
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
-- Filename:        uart_receive.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              uart_receive.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision$
-- Date:            $Date$
--
-- History:
--   goran  2007-12-18    First Version
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

entity UART_Receive is
  generic (
    C_DATA_BITS    : integer range 5 to 8 := 8;
    C_USE_PARITY   : integer              := 0;
    C_ODD_PARITY   : integer              := 1
    );
  port (
    Clk         : in std_logic;
    Reset       : in boolean;
    EN_16x_Baud : in std_logic;

    RX               : in  std_logic;
    Read_RX_Data     : in  std_logic;
    RX_Data          : out std_logic_vector(C_DATA_BITS-1 downto 0);
    RX_Data_Received : out std_logic;
    RX_Data_Exists   : out std_logic;
    RX_Frame_Error   : out std_logic;
    RX_Overrun_Error : out std_logic;
    RX_Parity_Error  : out std_logic
    );

end entity UART_Receive;

library UNISIM;
use UNISIM.vcomponents.all;

architecture IMP of UART_Receive is

  signal previous_RX             : std_logic;
  signal start_Edge_Detected     : boolean;
  signal start_Edge_Detected_Bit : std_logic;
  signal running                 : boolean;
  signal mid_Start_Bit           : std_logic;
  signal recycle                 : std_logic;
  signal sample_Point            : std_logic;
  signal stop_Bit_Position       : std_logic;

  function Calc_Length return integer is
  begin  -- function Calc_Length
    if (C_USE_PARITY = 1) then
      return 1 + C_DATA_BITS;
    else
      return C_DATA_BITS;
    end if;
  end function Calc_Length;

  constant SERIAL_TO_PAR_LENGTH : integer := Calc_Length;
  constant STOP_BIT_POS         : integer := SERIAL_TO_PAR_LENGTH;
  constant DATA_LSB_POS         : integer := SERIAL_TO_PAR_LENGTH;
  constant CALC_PAR_POS         : integer := SERIAL_TO_PAR_LENGTH;

  signal new_rx_data_write  : std_logic;
  signal new_rx_data        : std_logic_vector(0 to SERIAL_TO_PAR_LENGTH);
  signal serial_to_parallel : std_logic_vector(1 to SERIAL_TO_PAR_LENGTH);
  signal rx_data_exists_i   : std_logic;

  signal calc_Parity : std_logic;
  signal parity      : std_logic;

  signal rx_1 : std_logic;
  signal rx_2 : std_logic;

  signal rx_data_i : std_logic_vector(C_DATA_BITS-1 downto 0);
  
  -- Preserve signals after synthesis for simulation UART support
  attribute KEEP : string;
  attribute KEEP of RX_Frame_Error    : signal is "SOFT";
  attribute KEEP of RX_Parity_Error   : signal is "SOFT";
  attribute KEEP of new_rx_data_write : signal is "SOFT";
  attribute KEEP of new_rx_data       : signal is "SOFT";

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Double sample to avoid meta-stability
  -----------------------------------------------------------------------------
  RX_Sampling : process (Clk)
  begin  -- process RX_Sampling
    if Clk'event and Clk = '1' then     -- rising clock edge
      if Reset then                     -- asynchronous reset (active high)
        rx_1 <= '1';
        rx_2 <= '1';
      else
        rx_1 <= RX;
        rx_2 <= rx_1;
      end if;
    end if;
  end process RX_Sampling;

  -----------------------------------------------------------------------------
  -- Detect a falling edge on RX and start a new receiption if idle
  -----------------------------------------------------------------------------
  Prev_RX_DFF : process (Clk) is
  begin  -- process Prev_RX_DFF
    if Clk'event and Clk = '1' then     -- rising clock edge
      if Reset then
        previous_RX <= '0';
      else
        if (EN_16x_Baud = '1') then
          previous_RX <= rx_2;
        end if;
      end if;
    end if;
  end process Prev_RX_DFF;

  Start_Edge_DFF : process (Clk) is
  begin  -- process Start_Edge_DFF
    if Clk'event and Clk = '1' then     -- rising clock edge
      if Reset then
        start_Edge_Detected <= false;
      else
        if (EN_16x_Baud = '1') then
          start_Edge_Detected <= not running and (previous_RX = '1') and (rx_2 = '0');
        end if;
      end if;
    end if;
  end process Start_Edge_DFF;

  -----------------------------------------------------------------------------
  -- Running is '1' during a receiption
  -----------------------------------------------------------------------------
  Running_DFF : process (Clk) is
  begin  -- process Running_DFF
    if Clk'event and Clk = '1' then     -- rising clock edge
      if Reset then                     -- asynchronous reset (active high)
        running <= false;
      else
        if (EN_16x_Baud = '1') then
          if (start_Edge_Detected) then
            running <= true;
          elsif ((sample_Point = '1') and (stop_Bit_Position = '1')) then
            running <= false;
          end if;
        end if;
      end if;
    end if;
  end process Running_DFF;

  -----------------------------------------------------------------------------
  -- Delay start_Edge_Detected 7 clocks to get the mid-point in a bit
  -- The address needs to be 6 "0110" to get a delay of 7.
  -----------------------------------------------------------------------------

  start_Edge_Detected_Bit <= '1' when start_Edge_Detected else '0';

  Mid_Start_Bit_SRL16 : SRL16E
    -- pragma translate_off
    generic map (
      INIT => x"0000")
    -- pragma translate_on
    port map (
      CE  => EN_16x_Baud,               -- [in  std_logic]
      D   => start_Edge_Detected_Bit,   -- [in  std_logic]
      Clk => Clk,                       -- [in  std_logic]
      A0  => '0',                       -- [in  std_logic]
      A1  => '1',                       -- [in  std_logic]
      A2  => '1',                       -- [in  std_logic]
      A3  => '0',                       -- [in  std_logic]
      Q   => mid_Start_Bit);            -- [out std_logic]

  -- Keep regenerating new values into the 16 clock delay
  -- Starting with the first mid_Start_Bit and for every new sample_points
  -- until stop_Bit_Position is reached
  recycle <= not (stop_Bit_Position) and (mid_Start_Bit or sample_Point);

  Delay_16 : SRL16E
    -- pragma translate_off
    generic map (
      INIT => x"0000")
    -- pragma translate_on
    port map (
      CE  => EN_16x_Baud,               -- [in  std_logic]
      D   => recycle,                   -- [in  std_logic]
      Clk => Clk,                       -- [in  std_logic]
      A0  => '1',                       -- [in  std_logic]
      A1  => '1',                       -- [in  std_logic]
      A2  => '1',                       -- [in  std_logic]
      A3  => '1',                       -- [in  std_logic]
      Q   => sample_Point);             -- [out std_logic]

  -----------------------------------------------------------------------------
  -- Detect when the stop bit is received
  -----------------------------------------------------------------------------
  Stop_Bit_Handler : process (Clk) is
  begin  -- process Stop_Bit_Handler
    if Clk'event and Clk = '1' then     -- rising clock edge
      if Reset then                     -- asynchronous reset (active high)
        stop_Bit_Position <= '0';
      else
        if (EN_16x_Baud = '1') then
          if (stop_Bit_Position = '0') then
            -- Start bit has reached the end of the shift register (Stop bit position)
            stop_Bit_Position <= sample_Point and new_rx_data(STOP_BIT_POS);
          elsif (sample_Point = '1') then
            -- if stop_Bit_Position = '1', then clear it at the next sample_Point
            stop_Bit_Position <= '0';
          end if;
        end if;
      end if;
    end if;
  end process Stop_Bit_Handler;

  -----------------------------------------------------------------------------
  -- Parity handling
  -----------------------------------------------------------------------------
  Using_Parity : if (C_USE_PARITY = 1) generate
  begin

    Using_Odd_Parity : if (C_ODD_PARITY = 1) generate
    begin
      Parity_Bit : FDSE
        -- pragma translate_off
        generic map (
          INIT => '1')                  -- [bit]
        -- pragma translate_on
        port map (
          Q  => Parity,                 -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => EN_16x_Baud,            -- [in  std_logic]
          D  => calc_Parity,            -- [in  std_logic]
          S  => mid_Start_Bit);         -- [in std_logic]
    end generate Using_Odd_Parity;

    Using_Even_Parity : if (C_ODD_PARITY = 0) generate
    begin
      Parity_Bit : FDRE
        -- pragma translate_off
        generic map (
          INIT => '0')                  -- [bit]
        -- pragma translate_on
        port map (
          Q  => Parity,                 -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => EN_16x_Baud,            -- [in  std_logic]
          D  => calc_Parity,            -- [in  std_logic]
          R  => mid_Start_Bit);         -- [in std_logic]      
    end generate Using_Even_Parity;

    calc_Parity <= parity when (stop_Bit_Position or not sample_Point) = '1'
                   else parity xor rx_2;

    RX_Parity_Error <= (EN_16x_Baud and sample_Point) and (new_rx_data(CALC_PAR_POS)) and
                       not stop_Bit_Position
                       when running and (rx_2 /= Parity) else '0';
  end generate Using_Parity;

  Not_Using_Parity : if (C_USE_PARITY = 0) generate
  begin
    RX_Parity_Error <= '0';
  end generate Not_Using_Parity;


  -----------------------------------------------------------------------------
  -- Data part
  -----------------------------------------------------------------------------

  new_rx_data(0) <= rx_2;

  Convert_Serial_To_Parallel : for I in 1 to serial_to_parallel'length generate
  begin

    serial_to_parallel(I) <= new_rx_data(I) when (stop_Bit_Position or not sample_Point) = '1'
                             else new_rx_data(I-1);
    
    First_Bit : if (I = 1) generate
    begin
      First_Bit_I : FDSE
        -- pragma translate_off
        generic map (
          INIT => '0')                  -- [bit]
        -- pragma translate_on
        port map (
          Q  => new_rx_data(I),         -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => EN_16x_Baud,            -- [in  std_logic]
          D  => serial_to_parallel(I),  -- [in  std_logic]
          S  => mid_Start_Bit);         -- [in std_logic]
    end generate First_Bit;

    Rest_Bits : if (I /= 1) generate
    begin
      Others_I : FDRE
        -- pragma translate_off
        generic map (
          INIT => '0')                  -- [bit]
        -- pragma translate_on
        port map (
          Q  => new_rx_data(I),         -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => EN_16x_Baud,            -- [in  std_logic]
          D  => serial_to_parallel(I),  -- [in  std_logic]
          R  => mid_Start_Bit);         -- [in std_logic]
    end generate Rest_Bits;

  end generate Convert_Serial_To_Parallel;

  -----------------------------------------------------------------------------
  -- Write in the received word when the stop_bit has been received and it is a
  -- '1'
  -----------------------------------------------------------------------------
  NEW_RX_DATA_Write_DFF : process (Clk) is
  begin
    if Clk'event and Clk = '1' then
      if Reset then
        new_rx_data_write <= '0';
      else
        new_rx_data_Write <= stop_Bit_Position and rx_2 and sample_Point and EN_16x_Baud;
      end if;
    end if;
  end process NEW_RX_DATA_Write_DFF;

  Rx_Data_Exist_Handler : process (Clk) is
  begin
    if Clk'event and Clk = '1' then
      if Reset then
        rx_data_exists_i <= '0';
      else
        if (new_rx_data_write = '1') then
          rx_data_exists_i <= '1';
        end if;
        if (Read_RX_Data = '1') then
          rx_data_exists_i <= '0';
        end if;
      end if;
    end if;
  end process Rx_Data_Exist_Handler;

  Receive_Register : process (Clk) is
  begin
    if Clk'event and Clk = '1' then
      if Reset then
        rx_data_i <= (others => '0');
      elsif (NEW_RX_DATA_Write = '1') then
        rx_data_i <= new_rx_data(DATA_LSB_POS - C_DATA_BITS + 1 to DATA_LSB_POS);
      end if;
    end if;
  end process Receive_Register;

  UART_Read: process (Clk) is
  begin
    if Clk'event and Clk = '1' then 
      if Read_RX_Data = '0' then
        RX_Data <= (others => '0');
      else
        RX_Data <= rx_data_i;
      end if;
    end if;
  end process UART_Read;
  
  RX_Data_Received <= new_rx_data_write;
  RX_Frame_Error   <= stop_Bit_Position and sample_Point and EN_16x_Baud and not rx_2;
  RX_Overrun_Error <= rx_data_exists_i and new_rx_data_write;
  RX_Data_Exists   <= rx_data_exists_i;

end architecture IMP;

