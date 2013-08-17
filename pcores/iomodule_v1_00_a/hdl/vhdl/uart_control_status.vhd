-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- uart_control_status.vhd - Entity and architecture
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
-- Filename:        uart_control_status.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              uart_control_status.vhd
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

entity Uart_Control_Status is
  generic (
    C_USE_UART_RX     : integer              := 1;
    C_USE_UART_TX     : integer              := 1;
    C_UART_DATA_BITS  : integer range 5 to 8 := 8;
    C_UART_USE_PARITY : integer              := 0;
    C_UART_ODD_PARITY : integer              := 0
    );
  port (
    CLK   : in std_logic;
    Reset : in boolean;

    TX_Data_Transmitted : in std_logic;
    TX_Buffer_Empty     : in std_logic;
    RX_Data_Received    : in std_logic;
    RX_Data_Exists      : in std_logic;
    RX_Frame_Error      : in std_logic;
    RX_Overrun_Error    : in std_logic;
    RX_Parity_Error     : in std_logic;

    UART_Status_Read     : in  std_logic;
    UART_Status          : out std_logic_vector(7 downto 0);
    UART_Interrupt       : out std_logic;
    UART_Rx_Interrupt    : out std_logic;
    UART_Tx_Interrupt    : out std_logic;
    UART_Error_Interrupt : out std_logic
    );

end entity Uart_Control_Status;

architecture IMP of Uart_Control_Status is

  signal parity_error  : std_logic;
  signal frame_error   : std_logic;
  signal overrun_error : std_logic;

  signal error_interrupt : std_logic;

begin  -- architecture IMP

  --------------------------------------------------------------------------------------------------
  -- Status register
  --------------------------------------------------------------------------------------------------
  UART_Status_DFF: process (Clk) is
  begin  -- process UART_Status_DFF
    if Clk'event and Clk = '1' then    -- rising clock edge
      if (UART_Status_Read = '0')then  -- synchronous reset (active high)
        UART_Status <= (others => '0');
      else
        if ((C_USE_UART_RX = 0) or (C_UART_USE_PARITY = 0)) then
          UART_Status(7) <= '0';
        else
          UART_Status(7) <= parity_error;
        end if;
        if (C_USE_UART_RX = 0) then
          UART_Status(6) <= '0';
          UART_Status(5) <= '0';
        else
          UART_Status(6) <= frame_error;
          UART_Status(5) <= overrun_error;
        end if;
        UART_Status(4) <= '0';
        if (C_USE_UART_TX = 0) then
          UART_Status(3) <= '0';
        else
          UART_Status(3) <= not TX_Buffer_Empty;
        end if;
        UART_Status(2) <= '0';
        UART_Status(1) <= '0';
        if (C_USE_UART_RX = 0) then
          UART_Status(0) <= '0';
        else
          UART_Status(0) <= RX_Data_Exists;
        end if;
      end if;
    end if;
  end process UART_Status_DFF;

  --------------------------------------------------------------------------------------------------
  -- Keep track of errors
  --------------------------------------------------------------------------------------------------
  Error_Flags : process (Clk) is
  begin  -- process Error_Flags
    if Clk'event and Clk = '1' then     -- rising clock edge
      if Reset then                     -- synchronous reset (active high)
        parity_error    <= '0';
        frame_error     <= '0';
        overrun_error   <= '0';
        error_interrupt <= '0';
      else
        error_interrupt <= '0';
        if ((C_USE_UART_RX = 0) or (UART_Status_Read = '1')) then
          parity_error  <= '0';
          frame_error   <= '0';
          overrun_error <= '0';
        end if;
        if ((C_USE_UART_RX /= 0) and (RX_Frame_Error = '1')) then
          frame_error     <= '1';
          error_interrupt <= '1';
        end if;
        if ((C_USE_UART_RX /= 0) and (RX_Overrun_Error = '1')) then
          overrun_error   <= '1';
          error_interrupt <= '1';
        end if;
        if ((C_USE_UART_RX /= 0) and (C_UART_USE_PARITY /= 0) and (RX_Parity_Error = '1')) then
          parity_error    <= '1';
          error_interrupt <= '1';
        end if;
      end if;
    end if;
  end process Error_Flags;

  --------------------------------------------------------------------------------------------------
  -- Interrupt generation
  --------------------------------------------------------------------------------------------------
  UART_Error_Interrupt <= error_interrupt;
  UART_Rx_Interrupt    <= RX_Data_Received;
  UART_Tx_Interrupt    <= TX_Data_Transmitted;
  UART_Interrupt       <= error_interrupt or RX_Data_Received or TX_Data_Transmitted;
end architecture IMP;
