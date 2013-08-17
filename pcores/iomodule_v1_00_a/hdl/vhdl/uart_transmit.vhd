-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- uart_transmit.vhd - Entity and architecture
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
-- Filename:        uart_transmit.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              uart_transmit.vhd
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

entity UART_Transmit is
  generic (
    C_DATA_BITS  : integer range 5 to 8 := 8;
    C_USE_PARITY : integer              := 0;
    C_ODD_PARITY : integer              := 1
    );
  port (
    Clk         : in std_logic;
    Reset       : in boolean;
    EN_16x_Baud : in std_logic;

    TX                  : out std_logic;
    Write_TX_Data       : in  std_logic;
    TX_Data             : in  std_logic_vector(C_DATA_BITS-1 downto 0);
    TX_Data_Transmitted : out std_logic;
    TX_Buffer_Empty     : out std_logic
    );

end entity UART_Transmit;

library ieee;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.vcomponents.all;

architecture IMP of UART_Transmit is

  -- signals for parity
  signal parity           : std_logic;
  signal calc_Parity      : std_logic;
  signal tx_Run1          : std_logic;
  signal select_Parity    : std_logic;
  signal data_to_transfer : std_logic_vector(0 to C_DATA_BITS-1);

  signal div16          : std_logic;
  signal tx_Data_Enable : std_logic;
  signal tx_Start       : std_logic;
  signal tx_DataBits    : std_logic;
  signal tx_Run         : std_logic;

  signal cnt_cy          : std_logic_vector(0 to 3);
  signal h_Cnt           : std_logic_vector(0 to 2);
  signal sum_cnt         : std_logic_vector(0 to 2);
  signal mux_sel         : std_logic_vector(0 to 2);
  signal mux_sel_is_zero : std_logic;

  constant mux_sel_init : std_logic_vector(0 to 2) :=
    std_logic_vector(to_unsigned(C_DATA_BITS-1, 3));

  signal mux_01      : std_logic;
  signal mux_23      : std_logic;
  signal mux_45      : std_logic;
  signal mux_67      : std_logic;
  signal mux_0123    : std_logic;
  signal mux_4567    : std_logic;
  signal mux_Out     : std_logic;
  signal serial_Data : std_logic;

  signal data_is_sent      : std_logic;
  signal tx_buffer_empty_i : std_logic;
  signal fifo_DOut         : std_logic_vector(0 to C_DATA_BITS-1);

  -- Preserve signals after synthesis for simulation UART support
  attribute KEEP : string;
  attribute KEEP of tx_buffer_empty_i : signal is "SOFT";
  attribute KEEP of TX                : signal is "SOFT";

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Divide the EN_16x_Baud by 16 to get the correct baudrate
  -----------------------------------------------------------------------------
  DIV16_SRL16E : SRL16E
    generic map (
      INIT => X"0001")
    port map (
      CE  => EN_16x_Baud,               -- [in  std_logic]
      D   => div16,                     -- [in  std_logic]
      Clk => Clk,                       -- [in  std_logic]
      A0  => '1',                       -- [in  std_logic]
      A1  => '1',                       -- [in  std_logic]
      A2  => '1',                       -- [in  std_logic]
      A3  => '1',                       -- [in  std_logic]
      Q   => div16);                    -- [out std_logic]

  FDRE_I : FDRE
    generic map (
      INIT => '0')                      -- [bit]
    port map (
      Q  => tx_Data_Enable,             -- [out std_logic]
      C  => Clk,                        -- [in  std_logic]
      CE => EN_16x_Baud,                -- [in  std_logic]
      D  => div16,                      -- [in  std_logic]
      R  => tx_Data_Enable);            -- [in std_logic]


  -----------------------------------------------------------------------------
  -- tx_start is '1' for the start bit in a transmission
  -----------------------------------------------------------------------------
  TX_Start_DFF : process (Clk) is
  begin  -- process TX_Start_DFF
    if Clk'event and Clk = '1' then  -- rising clock edge
      if Reset then                 -- asynchronous reset (active high)
        tx_Start <= '0';
      else
        tx_Start <= not(tx_Run) and (tx_Start or (not(tx_buffer_empty_i) and tx_Data_Enable));
      end if;
    end if;
  end process TX_Start_DFF;

  -----------------------------------------------------------------------------
  -- tx_DataBits is '1' during all databits transmission
  -----------------------------------------------------------------------------
  TX_Data_DFF : process (Clk) is
  begin  -- process TX_Data_DFF
    if Clk'event and Clk = '1' then  -- rising clock edge
      if Reset then                 -- asynchronous reset (active high)
        tx_DataBits <= '0';
      else
        tx_DataBits <= not(data_is_sent) and (tx_DataBits or (tx_Start and tx_Data_Enable));
      end if;
    end if;
  end process TX_Data_DFF;

  -- only decrement during data bits transfer
  cnt_cy(3) <= not tx_DataBits;

  Counter : for I in 2 downto 0 generate

    ---------------------------------------------------------------------------
    -- If mux_sel is zero then reload with the init value
    -- else decrement
    ---------------------------------------------------------------------------
    h_Cnt(I) <= mux_sel_init(I) when mux_sel_is_zero = '1' else not mux_sel(I);

    -- Don't need the last muxcy, cnt_cy(0) is not used anywhere
    Used_MuxCY: if I> 0 generate      
      MUXCY_L_I : MUXCY_L
        port map (
          DI => mux_sel(I),               -- [in  std_logic]
          CI => cnt_cy(I+1),              -- [in  std_logic]
          S  => h_cnt(I),                 -- [in  std_logic]
          LO => cnt_cy(I));               -- [out std_logic]
    end generate Used_MuxCY;

    XORCY_I : XORCY
      port map (
        LI => h_cnt(I),                 -- [in  std_logic]
        CI => cnt_cy(I+1),              -- [in  std_logic]
        O  => sum_cnt(I));              -- [out std_logic]
  end generate Counter;

  Mux_Addr_DFF : process (Clk) is
  begin  -- process Mux_Addr_DFF
    if Clk'event and Clk = '1' then  -- rising clock edge
      if Reset then                 -- asynchronous reset (active high)
        mux_sel <= std_logic_vector(to_unsigned(C_DATA_BITS-1, mux_sel'length));
      else
        if (tx_Data_Enable = '1') then
          mux_sel <= sum_cnt;
        end if;
      end if;
    end if;
  end process Mux_Addr_DFF;

  -- Detecting when mux_sel is zero ie. all data bits is transfered
  mux_sel_is_zero <= '1' when mux_sel = "000" else '0';

  -- Read out the next data from the transmit fifo when the data has been
  -- transmitted 
  Data_is_Sent_DFF : process (Clk) is
  begin  -- process Data_is_Sent_DFF
    if Clk'event and Clk = '1' then  -- rising clock edge
      if Reset then                 -- asynchronous reset (active high)
        data_is_sent <= '0';
      else
        data_is_sent <= tx_Data_Enable and mux_sel_is_zero;
      end if;
    end if;
  end process Data_is_Sent_DFF;

  TX_Data_Transmitted <= data_is_sent;
  
  -----------------------------------------------------------------------------
  -- Select which bit within the data word to transmit
  -----------------------------------------------------------------------------

  -- Need special treatment for inserting the parity bit because of parity generation
  Parity_Bit_Insertion : process (parity, select_Parity, fifo_DOut) is
  begin  -- process Parity_Bit_Insertion
    data_to_transfer <= fifo_DOut;
    if (select_Parity = '1') then
      data_to_transfer(C_DATA_BITS-1) <= parity;
    end if;
  end process Parity_Bit_Insertion;

  mux_01 <= data_to_transfer(1) when mux_sel(2) = '1' else data_to_transfer(0);
  mux_23 <= data_to_transfer(3) when mux_sel(2) = '1' else data_to_transfer(2);

  Data_Bits_Is_5 : if (C_DATA_BITS = 5) generate
    mux_45 <= data_to_transfer(4);
    mux_67 <= '0';
  end generate Data_Bits_Is_5;

  Data_Bits_Is_6 : if (C_DATA_BITS = 6) generate
    mux_45 <= data_to_transfer(5) when mux_sel(2) = '1' else data_to_transfer(4);
    mux_67 <= '0';
  end generate Data_Bits_Is_6;

  Data_Bits_Is_7 : if (C_DATA_BITS = 7) generate
    mux_45 <= data_to_transfer(5) when mux_sel(2) = '1' else data_to_transfer(4);
    mux_67 <= data_to_transfer(6);
  end generate Data_Bits_Is_7;

  Data_Bits_Is_8 : if (C_DATA_BITS = 8) generate
    mux_45 <= data_to_transfer(5) when mux_sel(2) = '1' else data_to_transfer(4);
    mux_67 <= data_to_transfer(7) when mux_sel(2) = '1' else data_to_transfer(6);
  end generate Data_Bits_Is_8;

  MUX_F5_1 : MUXF5
    port map (
      O  => mux_0123,                   -- [out std_logic]
      I0 => mux_01,                     -- [in  std_logic]
      I1 => mux_23,                     -- [in  std_logic]
      S  => mux_sel(1));                -- [in std_logic]

  MUX_F5_2 : MUXF5
    port map (
      O  => mux_4567,                   -- [out std_logic]
      I0 => mux_45,                     -- [in  std_logic]
      I1 => mux_67,                     -- [in  std_logic]
      S  => mux_sel(1));                -- [in std_logic]

  MUXF6_I : MUXF6
    port map (
      O  => mux_out,                    -- [out std_logic]
      I0 => mux_0123,                   -- [in  std_logic]
      I1 => mux_4567,                   -- [in  std_logic]
      S  => mux_sel(0));                -- [in std_logic]

  Serial_Data_DFF : process (Clk) is
  begin  -- process Serial_Data_DFF
    if Clk'event and Clk = '1' then  -- rising clock edge
      if Reset then                 -- asynchronous reset (active high)
        serial_Data <= '0';
      else
        serial_Data <= mux_Out;
      end if;
    end if;
  end process Serial_Data_DFF;

  -----------------------------------------------------------------------------
  -- Force a '0' when tx_start is '1', Start_bit
  -- Force a '1' when tx_run is '0',   Idle
  -- otherwise put out the serial_data
  -----------------------------------------------------------------------------
  Serial_Out_DFF : process (Clk) is
  begin  -- process Serial_Out_DFF
    if Clk'event and Clk = '1' then  -- rising clock edge
      if Reset then                 -- asynchronous reset (active high)
        TX <= '1';
      else
        TX <= (not(tx_run) or serial_Data) and not(tx_Start);
      end if;
    end if;
  end process Serial_Out_DFF;

  -----------------------------------------------------------------------------
  -- Parity handling
  -----------------------------------------------------------------------------
  Using_Parity : if (C_USE_PARITY = 1) generate

    Using_Odd_Parity : if (C_ODD_PARITY = 1) generate
      Parity_Bit : FDSE
        generic map (
          INIT => '1')                  -- [bit]
        port map (
          Q  => Parity,                 -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => tx_Data_Enable,         -- [in  std_logic]
          D  => calc_Parity,            -- [in  std_logic]
          S  => tx_Start);              -- [in std_logic]
    end generate Using_Odd_Parity;

    Using_Even_Parity : if (C_ODD_PARITY = 0) generate
      Parity_Bit : FDRE
        generic map (
          INIT => '0')                  -- [bit]
        port map (
          Q  => Parity,                 -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => tx_Data_Enable,         -- [in  std_logic]
          D  => calc_Parity,            -- [in  std_logic]
          R  => tx_Start);              -- [in std_logic]      
    end generate Using_Even_Parity;

    calc_Parity <= parity xor serial_data;

    tx_Run_DFF : process (Clk) is
    begin  -- process tx_Run_DFF
      if Clk'event and Clk = '1' then  -- rising clock edge
        if Reset then                 -- asynchronous reset (active high)
          tx_Run1 <= '0';
        else
          if (tx_Data_Enable = '1') then
            tx_Run1 <= tx_DataBits;
          end if;
        end if;
      end if;
    end process tx_Run_DFF;

    tx_Run <= tx_Run1 or tx_DataBits;

    Select_Parity_DFF : process (Clk) is
    begin  -- process Select_Parity_DFF
      if Clk'event and Clk = '1' then  -- rising clock edge
        if Reset then                 -- asynchronous reset (active high)
          select_Parity <= '0';
        else
          if (tx_Data_Enable = '1') then
            select_Parity <= mux_sel_is_zero;
          end if;
        end if;
      end if;
    end process Select_Parity_DFF;
  end generate Using_Parity;

  No_Parity : if (C_USE_PARITY = 0) generate
    tx_Run1       <= '0';
    calc_Parity   <= '0';
    parity        <= '0';
    tx_Run        <= tx_DataBits;
    select_Parity <= '0';
  end generate No_Parity;

  Data_To_Transmit: process (Clk) is
  begin
    if Clk'event and Clk = '1' then
      if Reset then
        fifo_DOut <= (others => '0');
      elsif (Write_TX_Data = '1') then
        fifo_DOut <= TX_Data;        
      end if;
    end if;
  end process Data_To_Transmit;

  TX_Reg_Status: process (Clk) is
  begin
    if Clk'event and Clk = '1' then
      if Reset then
        tx_buffer_empty_i <= '1';
      else
        if Write_TX_Data = '1' then
          tx_buffer_empty_i <= '0';
        end if;
        if (data_is_sent = '1') then
          tx_buffer_empty_i <= '1';
        end if;
      end if;
    end if;
  end process TX_Reg_Status;

  TX_Buffer_Empty <= tx_buffer_empty_i;
  
end architecture IMP;
