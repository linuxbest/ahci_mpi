-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- iomodule.vhd - Entity and architecture
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
-- Filename:        iomodule.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              iomodule.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision$
-- Date:            $Date$
--
-- History:
--   goran  2008-01-08    First Version
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
use IEEE.numeric_std.all;

library iomodule_v1_00_a;
use iomodule_v1_00_a.iomodule_core;
use iomodule_v1_00_a.pselect_mask;

entity iomodule is
  generic (
    C_FAMILY                   : string                    := "Virtex5";
    C_FREQ                     : integer                   := 100000000;
    C_INSTANCE                 : string                    := "iomodule";

    -- Local Memory Bus generics
    C_HIGHADDR                 : std_logic_vector(0 to 31) := X"00000000";
    C_BASEADDR                 : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_MASK                     : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_IO_HIGHADDR              : std_logic_vector(0 to 31) := X"00000000";
    C_IO_BASEADDR              : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_IO_MASK                  : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_LMB_AWIDTH               : integer                   := 32;
    C_LMB_DWIDTH               : integer                   := 32;

    -- IO Bus
    C_USE_IO_BUS           : integer               := 0;
    
    -- UART generics
    C_USE_UART_RX          : integer               := 0;
    C_USE_UART_TX          : integer               := 0;
    C_UART_BAUDRATE        : integer               := 9600;
    C_UART_DATA_BITS       : integer range 5 to 8  := 8;
    C_UART_USE_PARITY      : integer               := 0;
    C_UART_ODD_PARITY      : integer               := 0;
    C_UART_RX_INTERRUPT    : integer               := 0;
    C_UART_TX_INTERRUPT    : integer               := 0;
    C_UART_ERROR_INTERRUPT : integer               := 0;
    
    -- FIT generics
    C_USE_FIT1        : integer               := 0;
    C_FIT1_No_CLOCKS  : integer               := 6216;
    C_FIT1_INTERRUPT  : integer               := 0;
    C_USE_FIT2        : integer               := 0;
    C_FIT2_No_CLOCKS  : integer               := 6216;
    C_FIT2_INTERRUPT  : integer               := 0;
    C_USE_FIT3        : integer               := 0;
    C_FIT3_No_CLOCKS  : integer               := 6216;
    C_FIT3_INTERRUPT  : integer               := 0;
    C_USE_FIT4        : integer               := 0;
    C_FIT4_No_CLOCKS  : integer               := 6216;
    C_FIT4_INTERRUPT  : integer               := 0;

    -- PIT generics
    C_USE_PIT1       : integer               := 0;
    C_PIT1_SIZE      : integer range 1 to 32 := 32;
    C_PIT1_READABLE  : integer               := 1;
    C_PIT1_PRESCALER : integer range 0 to 9  := 0;
    C_PIT1_INTERRUPT : integer               := 0;
    C_USE_PIT2       : integer               := 0;
    C_PIT2_SIZE      : integer range 1 to 32 := 32;
    C_PIT2_READABLE  : integer               := 1;
    C_PIT2_PRESCALER : integer range 0 to 9  := 0;
    C_PIT2_INTERRUPT : integer               := 0;
    C_USE_PIT3       : integer               := 0;
    C_PIT3_SIZE      : integer range 1 to 32 := 32;
    C_PIT3_READABLE  : integer               := 1;
    C_PIT3_PRESCALER : integer range 0 to 9  := 0;
    C_PIT3_INTERRUPT : integer               := 0;
    C_USE_PIT4       : integer               := 0;
    C_PIT4_SIZE      : integer range 1 to 32 := 32;
    C_PIT4_READABLE  : integer               := 1;
    C_PIT4_PRESCALER : integer range 0 to 9  := 0;
    C_PIT4_INTERRUPT : integer               := 0;

    -- GPO Generics
    C_USE_GPO1  : integer := 0;
    C_GPO1_SIZE : integer range 1 to 32 := 32;
    C_GPO1_INIT : std_logic_vector(31 downto 0) := (others => '0');
    C_USE_GPO2  : integer := 0;
    C_GPO2_SIZE : integer range 1 to 32 := 32;
    C_GPO2_INIT : std_logic_vector(31 downto 0) := (others => '0');
    C_USE_GPO3  : integer := 0;
    C_GPO3_SIZE : integer range 1 to 32 := 32;
    C_GPO3_INIT : std_logic_vector(31 downto 0) := (others => '0');
    C_USE_GPO4  : integer := 0;
    C_GPO4_SIZE : integer range 1 to 32 := 32;
    C_GPO4_INIT : std_logic_vector(31 downto 0) := (others => '0');

    -- GPI Generics
    C_USE_GPI1  : integer := 0;
    C_GPI1_SIZE : integer range 1 to 32 := 32;
    C_USE_GPI2  : integer := 0;
    C_GPI2_SIZE : integer range 1 to 32 := 32;
    C_USE_GPI3  : integer := 0;
    C_GPI3_SIZE : integer range 1 to 32 := 32;
    C_USE_GPI4  : integer := 0;
    C_GPI4_SIZE : integer range 1 to 32 := 32;

    -- Interrupt Handler Generics
    C_INTC_USE_EXT_INTR : integer                   := 0;
    C_INTC_INTR_SIZE    : integer range 1 to 16     := 1;
    C_INTC_LEVEL_EDGE   : std_logic_vector(15 downto 0) := X"0000";
    C_INTC_POSITIVE     : std_logic_vector(15 downto 0) := X"FFFF"
    );
  port (
    Clk : in std_logic;
    Rst : in std_logic;

    -- IO Interface
    IO_Addr_Strobe  : out std_logic;
    IO_Read_Strobe  : out std_logic;
    IO_Write_Strobe : out std_logic;
    IO_Address      : out std_logic_vector(C_LMB_AWIDTH-1 downto 0);
    IO_Byte_Enable  : out std_logic_vector((C_LMB_DWIDTH/8 - 1) downto 0);
    IO_Write_Data   : out std_logic_vector(C_LMB_DWIDTH-1 downto 0);
    IO_Read_Data    : in  std_logic_vector(C_LMB_DWIDTH-1 downto 0);
    IO_Ready        : in  std_logic;
    
    -- UART I/O
    UART_Rx        : in  std_logic;
    UART_Tx        : out std_logic;
    UART_Interrupt : out std_logic;

    -- FIT I/O
    FIT1_Interrupt : out std_logic;
    FIT1_Toggle    : out std_logic;
    FIT2_Interrupt : out std_logic;
    FIT2_Toggle    : out std_logic;
    FIT3_Interrupt : out std_logic;
    FIT3_Toggle    : out std_logic;
    FIT4_Interrupt : out std_logic;
    FIT4_Toggle    : out std_logic;
    
    -- PIT I/O
    PIT1_Enable    : in  std_logic;
    PIT1_Interrupt : out std_logic;
    PIT1_Toggle    : out std_logic;
    PIT2_Enable    : in  std_logic;
    PIT2_Interrupt : out std_logic;
    PIT2_Toggle    : out std_logic;
    PIT3_Enable    : in  std_logic;
    PIT3_Interrupt : out std_logic;
    PIT3_Toggle    : out std_logic;
    PIT4_Enable    : in  std_logic;
    PIT4_Interrupt : out std_logic;
    PIT4_Toggle    : out std_logic;
    
    -- GPO IO
    GPO1 : out std_logic_vector(C_GPO1_SIZE-1 downto 0);
    GPO2 : out std_logic_vector(C_GPO2_SIZE-1 downto 0);
    GPO3 : out std_logic_vector(C_GPO3_SIZE-1 downto 0);
    GPO4 : out std_logic_vector(C_GPO4_SIZE-1 downto 0);

    -- GPI IO
    GPI1 : in std_logic_vector(C_GPI1_SIZE-1 downto 0);
    GPI2 : in std_logic_vector(C_GPI2_SIZE-1 downto 0);
    GPI3 : in std_logic_vector(C_GPI3_SIZE-1 downto 0);
    GPI4 : in std_logic_vector(C_GPI4_SIZE-1 downto 0);

    -- Interrupt I0
    INTC_Interrupt : in  std_logic_vector(C_INTC_INTR_SIZE-1 downto 0);
    INTC_IRQ       : out std_logic;

    -- Local Memory Bus, LMB
    LMB_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB_AddrStrobe  : in  std_logic;
    LMB_ReadStrobe  : in  std_logic;
    LMB_WriteStrobe : in  std_logic;
    LMB_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl_Ready        : out std_logic;
    Sl_Wait         : out std_logic;
    Sl_UE           : out std_logic;
    Sl_CE           : out std_logic
    );

end entity iomodule;

architecture IMP of iomodule is

  -----------------------------------------------------------------------------
  -- Converts an integer to a decimal string
  -----------------------------------------------------------------------------
  function To_String(from : integer) return string is
  begin
    return integer'image(from);
  end function To_String;

  -----------------------------------------------------------------------------
  -- Converts a std_logic_vector to a hexadecimal string with leading "0x"
  -----------------------------------------------------------------------------
  function To_String(from : std_logic_vector) return String is
    type INT_TO_CHAR_TYPE is array (integer range 0 to 15) of character;
    constant INT_TO_STRHEX_TABLE : INT_TO_CHAR_TYPE :=
      ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

    variable value   : unsigned(0 to ((from'length + 3) / 4) * 4 - 1) := (others => '0');
    variable result  : string(1 to value'length / 4);
    variable v_index : integer := value'high;
    variable r_index : integer := result'high;
  begin
    value(value'high - from'length + 1 to value'high) := unsigned(from);
    while r_index > 0 loop
      result(r_index) := INT_TO_STRHEX_TABLE(to_integer(value(v_index - 3 to v_index)));
      v_index := v_index - 4;
      r_index := r_index - 1;
    end loop;
    return "0x" & result;
  end function To_String;

  constant C_CORE_GENERATION_INFO : string := C_INSTANCE & ",IOModule,{"
      & "c_instance="              & C_INSTANCE
      & ",c_family="               & C_FAMILY
      & ",c_freq="                 & To_String(C_FREQ)
      & ",c_highaddr="             & To_String(C_HIGHADDR)
      & ",c_baseaddr="             & To_String(C_BASEADDR)
      & ",c_mask="                 & To_String(C_MASK)
      & ",c_io_highaddr="          & To_String(C_IO_HIGHADDR)
      & ",c_io_baseaddr="          & To_String(C_IO_BASEADDR)
      & ",c_io_mask="              & To_String(C_IO_MASK)
      & ",c_lmb_awidth="           & To_String(C_LMB_AWIDTH)
      & ",c_lmb_dwidth="           & To_String(C_LMB_DWIDTH)
      & ",c_use_uart_rx="          & To_String(C_USE_UART_RX)
      & ",c_use_uart_tx="          & To_String(C_USE_UART_TX)
      & ",c_uart_baudrate="        & To_String(C_UART_BAUDRATE)
      & ",c_uart_data_bits="       & To_String(C_UART_DATA_BITS)
      & ",c_uart_use_parity="      & To_String(C_UART_USE_PARITY)
      & ",c_uart_odd_parity="      & To_String(C_UART_ODD_PARITY)
      & ",c_uart_rx_interrupt="    & To_String(C_UART_RX_INTERRUPT)
      & ",c_uart_tx_interrupt="    & To_String(C_UART_TX_INTERRUPT)
      & ",c_uart_error_interrupt=" & To_String(C_UART_ERROR_INTERRUPT)
      & ",c_use_fit1="             & To_String(C_USE_FIT1)
      & ",c_fit1_no_clocks="       & To_String(C_FIT1_No_CLOCKS)
      & ",c_fit1_interrupt="       & To_String(C_FIT1_INTERRUPT)
      & ",c_use_fit2="             & To_String(C_USE_FIT2)
      & ",c_fit2_no_clocks="       & To_String(C_FIT2_No_CLOCKS)
      & ",c_fit2_interrupt="       & To_String(C_FIT2_INTERRUPT)
      & ",c_use_fit3="             & To_String(C_USE_FIT3)
      & ",c_fit3_no_clocks="       & To_String(C_FIT3_No_CLOCKS)
      & ",c_fit3_interrupt="       & To_String(C_FIT3_INTERRUPT)
      & ",c_use_fit4="             & To_String(C_USE_FIT4)
      & ",c_fit4_no_clocks="       & To_String(C_FIT4_No_CLOCKS)
      & ",c_fit4_interrupt="       & To_String(C_FIT4_INTERRUPT)
      & ",c_use_pit1="             & To_String(C_USE_PIT1)
      & ",c_pit1_size="            & To_String(C_PIT1_SIZE)
      & ",c_pit1_readable="        & To_String(C_PIT1_READABLE)
      & ",c_pit1_prescaler="       & To_String(C_PIT1_PRESCALER)
      & ",c_pit1_interrupt="       & To_String(C_PIT1_INTERRUPT)
      & ",c_use_pit2="             & To_String(C_USE_PIT2)
      & ",c_pit2_size="            & To_String(C_PIT2_SIZE)
      & ",c_pit2_readable="        & To_String(C_PIT2_READABLE)
      & ",c_pit2_prescaler="       & To_String(C_PIT2_PRESCALER)
      & ",c_pit2_interrupt="       & To_String(C_PIT2_INTERRUPT)
      & ",c_use_pit3="             & To_String(C_USE_PIT3)
      & ",c_pit3_size="            & To_String(C_PIT3_SIZE)
      & ",c_pit3_readable="        & To_String(C_PIT3_READABLE)
      & ",c_pit3_prescaler="       & To_String(C_PIT3_PRESCALER)
      & ",c_pit3_interrupt="       & To_String(C_PIT3_INTERRUPT)
      & ",c_use_pit4="             & To_String(C_USE_PIT4)
      & ",c_pit4_size="            & To_String(C_PIT4_SIZE)
      & ",c_pit4_readable="        & To_String(C_PIT4_READABLE)
      & ",c_pit4_prescaler="       & To_String(C_PIT4_PRESCALER)
      & ",c_pit4_interrupt="       & To_String(C_PIT4_INTERRUPT)
      & ",c_use_gpo1="             & To_String(C_USE_GPO1)
      & ",c_gpo1_size="            & To_String(C_GPO1_SIZE)
      & ",c_gpo1_init="            & To_String(C_GPO1_INIT)
      & ",c_use_gpo2="             & To_String(C_USE_GPO2)
      & ",c_gpo2_size="            & To_String(C_GPO2_SIZE)
      & ",c_gpo2_init="            & To_String(C_GPO2_INIT)
      & ",c_use_gpo3="             & To_String(C_USE_GPO3)
      & ",c_gpo3_size="            & To_String(C_GPO3_SIZE)
      & ",c_gpo3_init="            & To_String(C_GPO3_INIT)
      & ",c_use_gpo4="             & To_String(C_USE_GPO4)
      & ",c_gpo4_size="            & To_String(C_GPO4_SIZE)
      & ",c_gpo4_init="            & To_String(C_GPO4_INIT)
      & ",c_use_gpi1="             & To_String(C_USE_GPI1)
      & ",c_gpi1_size="            & To_String(C_GPI1_SIZE)
      & ",c_use_gpi2="             & To_String(C_USE_GPI2)
      & ",c_gpi2_size="            & To_String(C_GPI2_SIZE)
      & ",c_use_gpi3="             & To_String(C_USE_GPI3)
      & ",c_gpi3_size="            & To_String(C_GPI3_SIZE)
      & ",c_use_gpi4="             & To_String(C_USE_GPI4)
      & ",c_gpi4_size="            & To_String(C_GPI4_SIZE)
      & ",c_intc_use_ext_intr="    & To_String(C_INTC_USE_EXT_INTR)
      & ",c_intc_intr_size="       & To_String(C_INTC_INTR_SIZE)
      & ",c_intc_level_edge="      & To_String(C_INTC_LEVEL_EDGE)
      & ",c_intc_positive="        & To_String(C_INTC_POSITIVE)
      & "}";

  --attribute CORE_GENERATION_INFO : string;
  --attribute CORE_GENERATION_INFO of IMP : architecture is C_CORE_GENERATION_INFO;

  component iomodule_core is
    generic (
      C_FREQ : integer := 100000000;

      -- UART generics
      C_USE_UART_RX          : integer;
      C_USE_UART_TX          : integer;
      C_UART_BAUDRATE        : integer;
      C_UART_DATA_BITS       : integer range 5 to 8;
      C_UART_USE_PARITY      : integer;
      C_UART_ODD_PARITY      : integer;
      C_UART_RX_INTERRUPT    : integer;
      C_UART_TX_INTERRUPT    : integer;
      C_UART_ERROR_INTERRUPT : integer;

      -- FIT generics
      C_USE_FIT1        : integer;
      C_FIT1_No_CLOCKS  : integer;
      C_FIT1_INTERRUPT  : integer;
      C_USE_FIT2        : integer;
      C_FIT2_No_CLOCKS  : integer;
      C_FIT2_INTERRUPT  : integer;
      C_USE_FIT3        : integer;
      C_FIT3_No_CLOCKS  : integer;
      C_FIT3_INTERRUPT  : integer;
      C_USE_FIT4        : integer;
      C_FIT4_No_CLOCKS  : integer;
      C_FIT4_INTERRUPT  : integer;

      -- PIT generics
      C_USE_PIT1       : integer;
      C_PIT1_SIZE      : integer;
      C_PIT1_READABLE  : integer;
      C_PIT1_PRESCALER : integer range 0 to 9;
      C_PIT1_INTERRUPT : integer;
      C_USE_PIT2       : integer;
      C_PIT2_SIZE      : integer;
      C_PIT2_READABLE  : integer;
      C_PIT2_PRESCALER : integer range 0 to 9;
      C_PIT2_INTERRUPT : integer;
      C_USE_PIT3       : integer;
      C_PIT3_SIZE      : integer;
      C_PIT3_READABLE  : integer;
      C_PIT3_PRESCALER : integer range 0 to 9;
      C_PIT3_INTERRUPT : integer;
      C_USE_PIT4       : integer;
      C_PIT4_SIZE      : integer;
      C_PIT4_READABLE  : integer;
      C_PIT4_PRESCALER : integer range 0 to 9;
      C_PIT4_INTERRUPT : integer;

      -- GPO Generics
      C_USE_GPO1  : integer := 0;
      C_GPO1_SIZE : integer range 1 to 32 := 32;
      C_GPO1_INIT : std_logic_vector(31 downto 0) := (others => '0');
      C_USE_GPO2  : integer := 0;
      C_GPO2_SIZE : integer range 1 to 32 := 32;
      C_GPO2_INIT : std_logic_vector(31 downto 0) := (others => '0');
      C_USE_GPO3  : integer := 0;
      C_GPO3_SIZE : integer range 1 to 32 := 32;
      C_GPO3_INIT : std_logic_vector(31 downto 0) := (others => '0');
      C_USE_GPO4  : integer := 0;
      C_GPO4_SIZE : integer range 1 to 32 := 32;
      C_GPO4_INIT : std_logic_vector(31 downto 0) := (others => '0');

      -- GPI Generics
      C_USE_GPI1  : integer := 0;
      C_GPI1_SIZE : integer range 1 to 32 := 32;
      C_USE_GPI2  : integer := 0;
      C_GPI2_SIZE : integer range 1 to 32 := 32;
      C_USE_GPI3  : integer := 0;
      C_GPI3_SIZE : integer range 1 to 32 := 32;
      C_USE_GPI4  : integer := 0;
      C_GPI4_SIZE : integer range 1 to 32 := 32;

      -- Interrupt Handler Generics
      C_INTC_USE_EXT_INTR : integer;
      C_INTC_INTR_SIZE    : integer range 1 to 16;
      C_INTC_LEVEL_EDGE   : std_logic_vector(15 downto 0);
      C_INTC_POSITIVE     : std_logic_vector(15 downto 0));
    port (
      CLK : in std_logic;
      Rst : in std_logic;

      -- UART I/O
      UART_Rx        : in  std_logic;
      UART_Tx        : out std_logic;
      UART_Interrupt : out std_logic;

      -- FIT I/O
      FIT1_Interrupt : out std_logic;
      FIT1_Toggle    : out std_logic;
      FIT2_Interrupt : out std_logic;
      FIT2_Toggle    : out std_logic;
      FIT3_Interrupt : out std_logic;
      FIT3_Toggle    : out std_logic;
      FIT4_Interrupt : out std_logic;
      FIT4_Toggle    : out std_logic;
    
      -- PIT I/O
      PIT1_Enable    : in  std_logic;
      PIT1_Interrupt : out std_logic;
      PIT1_Toggle    : out std_logic;
      PIT2_Enable    : in  std_logic;
      PIT2_Interrupt : out std_logic;
      PIT2_Toggle    : out std_logic;
      PIT3_Enable    : in  std_logic;
      PIT3_Interrupt : out std_logic;
      PIT3_Toggle    : out std_logic;
      PIT4_Enable    : in  std_logic;
      PIT4_Interrupt : out std_logic;
      PIT4_Toggle    : out std_logic;

      -- GPO IO
      GPO1 : out std_logic_vector(C_GPO1_SIZE-1 downto 0);
      GPO2 : out std_logic_vector(C_GPO2_SIZE-1 downto 0);
      GPO3 : out std_logic_vector(C_GPO3_SIZE-1 downto 0);
      GPO4 : out std_logic_vector(C_GPO4_SIZE-1 downto 0);

      -- GPI IO
      GPI1 : in  std_logic_vector(C_GPI1_SIZE-1 downto 0);
      GPI2 : in  std_logic_vector(C_GPI2_SIZE-1 downto 0);
      GPI3 : in  std_logic_vector(C_GPI3_SIZE-1 downto 0);
      GPI4 : in  std_logic_vector(C_GPI4_SIZE-1 downto 0);

      -- Interrupt I0
      INTC_Interrupt : in  std_logic_vector(C_INTC_INTR_SIZE-1 downto 0);
      INTC_IRQ       : out std_logic;

      -- Register access
      PIT1_Read          : in  std_logic;
      PIT1_Write_Preload : in  std_logic;
      PIT1_Write_Ctrl    : in  std_logic;
      PIT2_Read          : in  std_logic;
      PIT2_Write_Preload : in  std_logic;
      PIT2_Write_Ctrl    : in  std_logic;
      PIT3_Read          : in  std_logic;
      PIT3_Write_Preload : in  std_logic;
      PIT3_Write_Ctrl    : in  std_logic;
      PIT4_Read          : in  std_logic;
      PIT4_Write_Preload : in  std_logic;
      PIT4_Write_Ctrl    : in  std_logic;
      GPI1_Read          : in  std_logic;
      GPI2_Read          : in  std_logic;
      GPI3_Read          : in  std_logic;
      GPI4_Read          : in  std_logic;
      UART_TX_Write      : in  std_logic;
      GPO1_Write         : in  std_logic;
      GPO2_Write         : in  std_logic;
      GPO3_Write         : in  std_logic;
      GPO4_Write         : in  std_logic;
      UART_Status_Read   : in  std_logic;
      UART_Rx_Read       : in  std_logic;
      INTC_WRITE_CIAR    : in  std_logic;
      INTC_WRITE_CIER    : in  std_logic;
      INTC_READ_CISR     : in  std_logic;
      INTC_READ_CIPR     : in  std_logic;
      Write_Data         : in  std_logic_vector(31 downto 0);
      Read_Data          : out std_logic_vector(31 downto 0));
  end component iomodule_core;

  component pselect_mask
    generic (
      C_AW   : integer                   := 32;
      C_BAR  : std_logic_vector(0 to 31) := X"00000000";
      C_MASK : std_logic_vector(0 to 31) := X"00800000");
    port (
      A     : in  std_logic_vector(0 to 31);
      CS    : out std_logic;
      Valid : in  std_logic);
  end component;

  function c_use(size : integer) return integer is
  begin
    if size = 0 then
      return 0;
    else
      return 1;
    end if;
  end function c_use;

  -- Register Address Map
  constant C_UART_RX      : std_logic_vector(0 to 4) := "00000";
  constant C_UART_TX      : std_logic_vector(0 to 4) := "00001";
  constant C_UART_STATUS  : std_logic_vector(0 to 4) := "00010";
  constant C_UART_CONTROL : std_logic_vector(0 to 4) := "00011";
  constant C_GPO1         : std_logic_vector(0 to 4) := "00100";
  constant C_GPO2         : std_logic_vector(0 to 4) := "00101";
  constant C_GPO3         : std_logic_vector(0 to 4) := "00110";
  constant C_GPO4         : std_logic_vector(0 to 4) := "00111";
  constant C_GPI1         : std_logic_vector(0 to 4) := "01000";
  constant C_GPI2         : std_logic_vector(0 to 4) := "01001";
  constant C_GPI3         : std_logic_vector(0 to 4) := "01010";
  constant C_GPI4         : std_logic_vector(0 to 4) := "01011";
  constant C_IRQ_STATUS   : std_logic_vector(0 to 4) := "01100";
  constant C_IRQ_PENDING  : std_logic_vector(0 to 4) := "01101";
  constant C_IRQ_ENABLE   : std_logic_vector(0 to 4) := "01110";
  constant C_IRQ_ACK      : std_logic_vector(0 to 4) := "01111";
  constant C_PIT1_PRELOAD : std_logic_vector(0 to 4) := "10000";
  constant C_PIT1_COUNTER : std_logic_vector(0 to 4) := "10001";
  constant C_PIT1_CONTROL : std_logic_vector(0 to 4) := "10010";
  constant C_SPARE1       : std_logic_vector(0 to 4) := "10011";
  constant C_PIT2_PRELOAD : std_logic_vector(0 to 4) := "10100";
  constant C_PIT2_COUNTER : std_logic_vector(0 to 4) := "10101";
  constant C_PIT2_CONTROL : std_logic_vector(0 to 4) := "10110";
  constant C_SPARE2       : std_logic_vector(0 to 4) := "10111";
  constant C_PIT3_PRELOAD : std_logic_vector(0 to 4) := "11000";
  constant C_PIT3_COUNTER : std_logic_vector(0 to 4) := "11001";
  constant C_PIT3_CONTROL : std_logic_vector(0 to 4) := "11010";
  constant C_SPARE3       : std_logic_vector(0 to 4) := "11011";
  constant C_PIT4_PRELOAD : std_logic_vector(0 to 4) := "11100";
  constant C_PIT4_COUNTER : std_logic_vector(0 to 4) := "11101";
  constant C_PIT4_CONTROL : std_logic_vector(0 to 4) := "11110";
  constant C_SPARE4       : std_logic_vector(0 to 4) := "11111";

  signal lmb_reg_select     : std_logic;
  signal lmb_io_select      : std_logic;
  signal lmb_io_select_keep : std_logic;
  signal lmb_abus_Q         : std_logic_vector(0 to 4);
  signal lmb_reg_read       : std_logic;
  signal lmb_reg_read_Q     : std_logic;
  signal lmb_reg_write      : std_logic;
  signal io_ready_Q         : std_logic;
  signal io_bus_read_data   : std_logic_vector(C_LMB_DWIDTH-1 downto 0);
  
  -- Register access
  signal pit1_read          : std_logic;
  signal pit1_write_preload : std_logic;
  signal pit1_write_ctrl    : std_logic;
  signal pit2_read          : std_logic;
  signal pit2_write_preload : std_logic;
  signal pit2_write_ctrl    : std_logic;
  signal pit3_read          : std_logic;
  signal pit3_write_preload : std_logic;
  signal pit3_write_ctrl    : std_logic;
  signal pit4_read          : std_logic;
  signal pit4_write_preload : std_logic;
  signal pit4_write_ctrl    : std_logic;
  signal gpi1_read          : std_logic;
  signal gpi2_read          : std_logic;
  signal gpi3_read          : std_logic;
  signal gpi4_read          : std_logic;
  signal uart_tx_write      : std_logic;
  signal gpo1_write         : std_logic;
  signal gpo2_write         : std_logic;
  signal gpo3_write         : std_logic;
  signal gpo4_write         : std_logic;
  signal uart_status_read   : std_logic;
  signal uart_rx_read       : std_logic;
  signal intc_write_ciar    : std_logic;
  signal intc_write_cier    : std_logic;
  signal intc_read_cisr     : std_logic;
  signal intc_read_cipr     : std_logic;
  signal write_data         : std_logic_vector(31 downto 0);
  signal io_reg_read_data   : std_logic_vector(31 downto 0);

  signal fit1_interrupt_i : std_logic;
  signal fit2_interrupt_i : std_logic;
  signal fit3_interrupt_i : std_logic;
  signal fit4_interrupt_i : std_logic;
  signal pit1_interrupt_i : std_logic;
  signal pit2_interrupt_i : std_logic;
  signal pit3_interrupt_i : std_logic;
  signal pit4_interrupt_i : std_logic;

  signal One : std_logic;               -- tied to '1';

  -- Preserve signals after synthesis for simulation UART support
  attribute KEEP : string;
  attribute KEEP of uart_tx_write : signal is "SOFT";
  attribute KEEP of write_data    : signal is "SOFT";

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Do the LMB address decoding
  -----------------------------------------------------------------------------
  One <= '1';
  -- Detect if IO Module register is accessed
  pselect_mask_reg : pselect_mask
    generic map (
      C_AW   => LMB_ABus'length,
      C_BAR  => C_BASEADDR,
      C_MASK => C_MASK)
    port map (
      A     => LMB_ABus,
      CS    => lmb_reg_select,
      Valid => One);

  -- Remember address, read, write and write data
  AccessReg : process(Clk) is
  begin
    if (Clk'event and Clk = '1') then
      lmb_abus_Q <= LMB_ABus(LMB_ABus'high-LMB_ABus_Q'length+1-2 to LMB_ABus'high-2);

      lmb_reg_read_Q <= lmb_reg_read;
      lmb_reg_read   <= LMB_ReadStrobe  and lmb_reg_select and LMB_AddrStrobe;
      lmb_reg_write  <= LMB_WriteStrobe and lmb_reg_select and LMB_AddrStrobe;

      Write_Data(31 downto 0) <= LMB_WriteDBus(0 to 31);  -- Data to write to IO module
    end if;
  end process AccessReg;

  Using_IO_Bus : if (C_USE_IO_BUS /= 0) generate

    signal io_read_keep   : std_logic;

  begin
    
    -- Detect if IO Module IO extension is accessed
    pselect_mask_io : pselect_mask
      generic map (
        C_AW   => LMB_ABus'length,
        C_BAR  => C_IO_BASEADDR,
        C_MASK => C_IO_MASK)
      port map (
        A     => LMB_ABus,
        CS    => lmb_io_select,
        Valid => One);

    AccessIO : process(Clk) is
    begin
      if (Clk'event and Clk = '1') then
        if Rst = '1' then
          IO_Addr_Strobe     <= '0';
          IO_Read_Strobe     <= '0';
          IO_Write_Strobe    <= '0';
          IO_Address         <= (others => '0');
          IO_Byte_Enable     <= (others => '0');
          IO_Write_Data      <= (others => '0');
          lmb_io_select_keep <= '0';
          io_read_keep       <= '0';
        elsif lmb_io_select = '1' and LMB_AddrStrobe = '1' then
          IO_Addr_Strobe     <= '1';
          IO_Read_Strobe     <= LMB_ReadStrobe;
          IO_Write_Strobe    <= LMB_WriteStrobe;
          IO_Address         <= LMB_ABus;
          IO_Byte_Enable     <= LMB_BE;
          IO_Write_Data      <= LMB_WriteDBus;
          lmb_io_select_keep <= '1';
          io_read_keep       <= LMB_ReadStrobe;
        else
          if IO_Ready = '1' then
            lmb_io_select_keep <= '0';
            io_read_keep       <= '0';
          end if;
          IO_Addr_Strobe  <= '0';
          IO_Read_Strobe  <= '0';
          IO_Write_Strobe <= '0';
        end if;
      end if;
    end process AccessIO;

    ReadyReg : process(Clk) is
    begin
      if (Clk'event and Clk = '1') then
        io_ready_Q <= lmb_io_select_keep and IO_Ready;
      end if;
    end process ReadyReg;

    ReadDataReg : process(Clk) is
    begin
      if (Clk'event and Clk = '1') then
        if IO_Ready = '1' and io_read_keep = '1' then
          io_bus_read_data <= IO_Read_Data;
        else
          io_bus_read_data <= (others => '0');
        end if;
      end if;
    end process ReadDataReg;
    
  end generate Using_IO_Bus;
  
  Not_Using_IO_Bus : if (C_USE_IO_BUS = 0) generate
    io_ready_Q         <= '0';
    io_bus_read_data   <= (others => '0');
    lmb_io_select      <= '0';
    lmb_io_select_keep <= '0';
    IO_Addr_Strobe     <= '0';
    IO_Read_Strobe     <= '0';
    IO_Write_Strobe    <= '0';
    IO_Address         <= (others => '0');
    IO_Byte_Enable     <= (others => '0');
    IO_Write_Data      <= (others => '0');
  end generate Not_Using_IO_Bus;
  
  -- Data read from IO module
  Sl_DBus(0 to 31) <= io_reg_read_data(31 downto 0) or io_bus_read_data(31 downto 0);

  Sl_Wait <= lmb_reg_read or lmb_io_select_keep;

  Sl_UE   <= '0'; -- No Uncorrectable Errors
  Sl_CE   <= '0'; -- No Correctable Errors

  Sl_Ready <= '1' when lmb_reg_write  = '1' or lmb_reg_read_Q = '1' or io_ready_Q = '1' else
              '0';

  uart_rx_read       <= '1' when lmb_abus_Q = C_UART_RX      and lmb_reg_read  = '1' else '0'; 
  uart_tx_write      <= '1' when lmb_abus_Q = C_UART_TX      and lmb_reg_write = '1' else '0';
  uart_status_read   <= '1' when lmb_abus_Q = C_UART_STATUS  and lmb_reg_read  = '1' else '0';
  gpo1_write         <= '1' when lmb_abus_Q = C_GPO1         and lmb_reg_write = '1' else '0';
  gpo2_write         <= '1' when lmb_abus_Q = C_GPO2         and lmb_reg_write = '1' else '0';
  gpo3_write         <= '1' when lmb_abus_Q = C_GPO3         and lmb_reg_write = '1' else '0';
  gpo4_write         <= '1' when lmb_abus_Q = C_GPO4         and lmb_reg_write = '1' else '0';
  gpi1_read          <= '1' when lmb_abus_Q = C_GPI1         and lmb_reg_read  = '1' else '0';
  gpi2_read          <= '1' when lmb_abus_Q = C_GPI2         and lmb_reg_read  = '1' else '0';
  gpi3_read          <= '1' when lmb_abus_Q = C_GPI3         and lmb_reg_read  = '1' else '0';
  gpi4_read          <= '1' when lmb_abus_Q = C_GPI4         and lmb_reg_read  = '1' else '0';
  intc_write_ciar    <= '1' when lmb_abus_Q = C_IRQ_ACK      and lmb_reg_write = '1' else '0';
  intc_write_cier    <= '1' when lmb_abus_Q = C_IRQ_ENABLE   and lmb_reg_write = '1' else '0';
  intc_read_cisr     <= '1' when lmb_abus_Q = C_IRQ_STATUS   and lmb_reg_read  = '1' else '0';
  intc_read_cipr     <= '1' when lmb_abus_Q = C_IRQ_PENDING  and lmb_reg_read  = '1' else '0';
  pit1_read          <= '1' when lmb_abus_Q = C_PIT1_COUNTER and lmb_reg_read  = '1' else '0';
  pit1_write_preload <= '1' when lmb_abus_Q = C_PIT1_PRELOAD and lmb_reg_write = '1' else '0';
  pit1_write_ctrl    <= '1' when lmb_abus_Q = C_PIT1_CONTROL and lmb_reg_write = '1' else '0';
  pit2_read          <= '1' when lmb_abus_Q = C_PIT2_COUNTER and lmb_reg_read  = '1' else '0';
  pit2_write_preload <= '1' when lmb_abus_Q = C_PIT2_PRELOAD and lmb_reg_write = '1' else '0';
  pit2_write_ctrl    <= '1' when lmb_abus_Q = C_PIT2_CONTROL and lmb_reg_write = '1' else '0';
  pit3_read          <= '1' when lmb_abus_Q = C_PIT3_COUNTER and lmb_reg_read  = '1' else '0';
  pit3_write_preload <= '1' when lmb_abus_Q = C_PIT3_PRELOAD and lmb_reg_write = '1' else '0';
  pit3_write_ctrl    <= '1' when lmb_abus_Q = C_PIT3_CONTROL and lmb_reg_write = '1' else '0';
  pit4_read          <= '1' when lmb_abus_Q = C_PIT4_COUNTER and lmb_reg_read  = '1' else '0';
  pit4_write_preload <= '1' when lmb_abus_Q = C_PIT4_PRELOAD and lmb_reg_write = '1' else '0';
  pit4_write_ctrl    <= '1' when lmb_abus_Q = C_PIT4_CONTROL and lmb_reg_write = '1' else '0';

  IOModule_Core_I1: iomodule_core
    generic map (
      C_FREQ                 => C_FREQ,

      -- UART generics
      C_USE_UART_RX          => C_USE_UART_RX,           -- [integer]
      C_USE_UART_TX          => C_USE_UART_TX,           -- [integer]
      C_UART_BAUDRATE        => C_UART_BAUDRATE,         -- [integer]
      C_UART_DATA_BITS       => C_UART_DATA_BITS,        -- [integer range 5 to 8]
      C_UART_USE_PARITY      => C_UART_USE_PARITY,       -- [integer]
      C_UART_ODD_PARITY      => C_UART_ODD_PARITY,       -- [integer]
      C_UART_RX_INTERRUPT    => C_UART_RX_INTERRUPT,     -- [integer]
      C_UART_TX_INTERRUPT    => C_UART_TX_INTERRUPT,     -- [integer]
      C_UART_ERROR_INTERRUPT => C_UART_ERROR_INTERRUPT,  -- [integer]

      -- FIT generics
      C_USE_FIT1        => C_USE_FIT1,         -- [integer]
      C_FIT1_No_CLOCKS  => C_FIT1_No_CLOCKS,   -- [integer]
      C_FIT1_INTERRUPT  => C_FIT1_INTERRUPT,   -- [integer]
      C_USE_FIT2        => C_USE_FIT2,         -- [integer]
      C_FIT2_No_CLOCKS  => C_FIT2_No_CLOCKS,   -- [integer]
      C_FIT2_INTERRUPT  => C_FIT2_INTERRUPT,   -- [integer]
      C_USE_FIT3        => C_USE_FIT3,         -- [integer]
      C_FIT3_No_CLOCKS  => C_FIT3_No_CLOCKS,   -- [integer]
      C_FIT3_INTERRUPT  => C_FIT3_INTERRUPT,   -- [integer]
      C_USE_FIT4        => C_USE_FIT4,         -- [integer]
      C_FIT4_No_CLOCKS  => C_FIT4_No_CLOCKS,   -- [integer]
      C_FIT4_INTERRUPT  => C_FIT4_INTERRUPT,   -- [integer]

      -- PIT generics
      C_USE_PIT1           => C_USE_PIT1,            -- [integer]
      C_PIT1_SIZE          => C_PIT1_SIZE,           -- [integer]
      C_PIT1_READABLE      => C_PIT1_READABLE,       -- [integer]
      C_PIT1_PRESCALER     => C_PIT1_PRESCALER,      -- [integer range 0 to 9]
      C_PIT1_INTERRUPT     => C_PIT1_INTERRUPT,      -- [integer]
      C_USE_PIT2           => C_USE_PIT2,            -- [integer]
      C_PIT2_SIZE          => C_PIT2_SIZE,           -- [integer]
      C_PIT2_READABLE      => C_PIT2_READABLE,       -- [integer]
      C_PIT2_PRESCALER     => C_PIT2_PRESCALER,      -- [integer range 0 to 9]
      C_PIT2_INTERRUPT     => C_PIT2_INTERRUPT,      -- [integer]
      C_USE_PIT3           => C_USE_PIT3,            -- [integer]
      C_PIT3_SIZE          => C_PIT3_SIZE,           -- [integer]
      C_PIT3_READABLE      => C_PIT3_READABLE,       -- [integer]
      C_PIT3_PRESCALER     => C_PIT3_PRESCALER,      -- [integer range 0 to 9]
      C_PIT3_INTERRUPT     => C_PIT3_INTERRUPT,      -- [integer]
      C_USE_PIT4           => C_USE_PIT4,            -- [integer]
      C_PIT4_SIZE          => C_PIT4_SIZE,           -- [integer]
      C_PIT4_READABLE      => C_PIT4_READABLE,       -- [integer]
      C_PIT4_PRESCALER     => C_PIT4_PRESCALER,      -- [integer range 0 to 9]
      C_PIT4_INTERRUPT     => C_PIT4_INTERRUPT,      -- [integer]

      -- GPO Generics
      C_USE_GPO1  => C_USE_GPO1,
      C_GPO1_SIZE => C_GPO1_SIZE,
      C_GPO1_INIT => C_GPO1_INIT,
      C_USE_GPO2  => C_USE_GPO2,
      C_GPO2_SIZE => C_GPO2_SIZE,
      C_GPO2_INIT => C_GPO2_INIT,
      C_USE_GPO3  => C_USE_GPO3,
      C_GPO3_SIZE => C_GPO3_SIZE,
      C_GPO3_INIT => C_GPO3_INIT,
      C_USE_GPO4  => C_USE_GPO4,
      C_GPO4_SIZE => C_GPO4_SIZE,
      C_GPO4_INIT => C_GPO4_INIT,

      -- GPI Generics
      C_USE_GPI1  => C_USE_GPI1,
      C_GPI1_SIZE => C_GPI1_SIZE,
      C_USE_GPI2  => C_USE_GPI2, 
      C_GPI2_SIZE => C_GPI2_SIZE,
      C_USE_GPI3  => C_USE_GPI3, 
      C_GPI3_SIZE => C_GPI3_SIZE,
      C_USE_GPI4  => C_USE_GPI4, 
      C_GPI4_SIZE => C_GPI4_SIZE,

      -- Interrupt Handler Generics
      C_INTC_USE_EXT_INTR => C_INTC_USE_EXT_INTR,
      C_INTC_INTR_SIZE    => C_INTC_INTR_SIZE,
      C_INTC_LEVEL_EDGE   => C_INTC_LEVEL_EDGE,
      C_INTC_POSITIVE     => C_INTC_POSITIVE)
    
    port map (
      CLK => CLK,
      Rst => Rst,

      -- UART I/O
      UART_Rx        => UART_Rx,
      UART_Tx        => UART_Tx,
      UART_Interrupt => UART_Interrupt,

      -- FIT I/O
      FIT1_Interrupt => fit1_interrupt_i,
      FIT1_Toggle    => FIT1_Toggle,
      FIT2_Interrupt => fit2_interrupt_i,
      FIT2_Toggle    => FIT2_Toggle,
      FIT3_Interrupt => fit3_interrupt_i,
      FIT3_Toggle    => FIT3_Toggle,
      FIT4_Interrupt => fit4_interrupt_i,
      FIT4_Toggle    => FIT4_Toggle,
      
      -- PIT I/O
      PIT1_Enable    => PIT1_Enable,
      PIT1_Interrupt => pit1_interrupt_i,
      PIT1_Toggle    => PIT1_Toggle,
      PIT2_Enable    => PIT2_Enable,
      PIT2_Interrupt => pit2_interrupt_i,
      PIT2_Toggle    => PIT2_Toggle,
      PIT3_Enable    => PIT3_Enable,
      PIT3_Interrupt => pit3_interrupt_i,
      PIT3_Toggle    => PIT3_Toggle,
      PIT4_Enable    => PIT4_Enable,
      PIT4_Interrupt => pit4_interrupt_i,
      PIT4_Toggle    => PIT4_Toggle,
      
      -- GPO IO
      GPO1 => GPO1,
      GPO2 => GPO2,
      GPO3 => GPO3,
      GPO4 => GPO4,

      -- GPI IO
      GPI1 => GPI1,
      GPI2 => GPI2,
      GPI3 => GPI3,
      GPI4 => GPI4,

      -- Interrupt I0
      INTC_Interrupt => INTC_Interrupt,
      INTC_IRQ       => INTC_IRQ,

      -- Register access
      PIT1_Read          => pit1_read,
      PIT1_Write_Preload => pit1_write_preload,
      PIT1_Write_Ctrl    => pit1_write_ctrl,
      PIT2_Read          => pit2_read,
      PIT2_Write_Preload => pit2_write_preload,
      PIT2_Write_Ctrl    => pit2_write_ctrl,
      PIT3_Read          => pit3_read,
      PIT3_Write_Preload => pit3_write_preload,
      PIT3_Write_Ctrl    => pit3_write_ctrl,
      PIT4_Read          => pit4_read,
      PIT4_Write_Preload => pit4_write_preload,
      PIT4_Write_Ctrl    => pit4_write_ctrl,
      GPI1_Read          => gpi1_read,
      GPI2_Read          => gpi2_read,
      GPI3_Read          => gpi3_read,
      GPI4_Read          => gpi4_read,
      UART_TX_Write      => uart_tx_write,
      GPO1_Write         => gpo1_write,
      GPO2_Write         => gpo2_write,
      GPO3_Write         => gpo3_write,
      GPO4_Write         => gpo4_write,
      UART_Status_Read   => uart_status_read,
      UART_Rx_Read       => uart_rx_read,
      INTC_WRITE_CIAR    => intc_write_ciar,
      INTC_WRITE_CIER    => intc_write_cier,
      INTC_READ_CISR     => intc_read_cisr,
      INTC_READ_CIPR     => intc_read_cipr,
      Write_Data         => write_data,
      Read_Data          => io_reg_read_data);


   FIT1_Interrupt <= fit1_interrupt_i;
   FIT2_Interrupt <= fit2_interrupt_i;
   FIT3_Interrupt <= fit3_interrupt_i;
   FIT4_Interrupt <= fit4_interrupt_i;
   PIT1_Interrupt <= pit1_interrupt_i;
   PIT2_Interrupt <= pit2_interrupt_i;
   PIT3_Interrupt <= pit3_interrupt_i;
   PIT4_Interrupt <= pit4_interrupt_i;
  
end architecture IMP;
