-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- iomodule_core.vhd - Entity and architecture
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
-- Filename:        iomodule_core.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              iomodule_core.vhd
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
--      pipelined or register delay signals:    "*_d#" cx
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

entity Iomodule_core is
  
  generic (
    C_FREQ                 : integer               := 100000000;

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
    C_USE_FIT1             : integer               := 0;
    C_FIT1_No_CLOCKS       : integer               := 1000;
    C_FIT1_INTERRUPT       : integer               := 0;
    C_USE_FIT2             : integer               := 0;
    C_FIT2_No_CLOCKS       : integer               := 1000;
    C_FIT2_INTERRUPT       : integer               := 0;
    C_USE_FIT3             : integer               := 0;
    C_FIT3_No_CLOCKS       : integer               := 1000;
    C_FIT3_INTERRUPT       : integer               := 0;
    C_USE_FIT4             : integer               := 0;
    C_FIT4_No_CLOCKS       : integer               := 1000;
    C_FIT4_INTERRUPT       : integer               := 0;

    -- PIT generics
    C_USE_PIT1       : integer               := 0;
    C_PIT1_SIZE      : integer               := 32;
    C_PIT1_READABLE  : integer               := 1;
    C_PIT1_PRESCALER : integer range 0 to 9  := 0;
    C_PIT1_INTERRUPT : integer               := 0;
    C_USE_PIT2       : integer               := 0;
    C_PIT2_SIZE      : integer               := 32;
    C_PIT2_READABLE  : integer               := 1;
    C_PIT2_PRESCALER : integer range 0 to 9  := 0;
    C_PIT2_INTERRUPT : integer               := 0;
    C_USE_PIT3       : integer               := 0;
    C_PIT3_SIZE      : integer               := 32;
    C_PIT3_READABLE  : integer               := 1;
    C_PIT3_PRESCALER : integer range 0 to 9  := 0;
    C_PIT3_INTERRUPT : integer               := 0;
    C_USE_PIT4       : integer               := 0;
    C_PIT4_SIZE      : integer               := 32;
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
    C_INTC_POSITIVE     : std_logic_vector(15 downto 0) := X"0000"
    );

  port (
    CLK   : in std_logic;
    Rst   : in std_logic;

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
    Read_Data          : out std_logic_vector(31 downto 0)
    );

end entity Iomodule_core;

library iomodule_v1_00_a;
use iomodule_v1_00_a.all;

architecture IMP of iomodule_core is

  component UART_Transmit is
    generic (
      C_DATA_BITS  : integer range 5 to 8;
      C_USE_PARITY : integer;
      C_ODD_PARITY : integer);
    port (
      Clk         : in std_logic;
      Reset       : in boolean;
      EN_16x_Baud : in std_logic;

      TX                  : out std_logic;
      Write_TX_Data       : in  std_logic;
      TX_Data             : in  std_logic_vector(C_DATA_BITS-1 downto 0);
      TX_Data_Transmitted : out std_logic;
      TX_Buffer_Empty     : out std_logic);
  end component UART_Transmit;

  component UART_Receive is
    generic (
      C_DATA_BITS  : integer range 5 to 8;
      C_USE_PARITY : integer;
      C_ODD_PARITY : integer);
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
      RX_Parity_Error  : out std_logic);
  end component UART_Receive;

  component Uart_Control_Status is
    generic (
      C_USE_UART_RX     : integer;
      C_USE_UART_TX     : integer;
      C_UART_DATA_BITS  : integer range 5 to 8;
      C_UART_USE_PARITY : integer;
      C_UART_ODD_PARITY : integer);
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
      UART_Error_Interrupt : out std_logic);
  end component Uart_Control_Status;

  component FIT_Module is
    generic (
      C_USE_FIT    : integer;
      C_NO_CLOCKS  : integer;           -- The number of clocks between each interrupt
      C_INACCURACY : integer);          -- The maximum inaccuracy of the number
    port (
      Clk       : in  std_logic;
      Reset     : in  boolean;
      Toggle    : out std_logic;
      Interrupt : out std_logic);
  end component FIT_Module;
  
  component PIT_Module is
    generic (
      C_USE_PIT      : integer;
      C_PIT_SIZE     : integer;
      C_PIT_READABLE : integer);
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
  end component PIT_Module;
  
  component GPO_Module is
    generic (
      C_USE_GPO    : integer := 1;
      C_GPO_SIZE   : integer range 1 to 32 := 32;
      C_GPO_INIT   : std_logic_vector(31 downto 0) := (others => '0'));
    port (
      Clk        : in  std_logic;
      Reset      : in  boolean;
      GPO_Write  : in  std_logic;
      Write_Data : in  std_logic_vector(31 downto 0);
      GPO        : out std_logic_vector(C_GPO_SIZE-1 downto 0));    
  end component GPO_Module;

  component GPI_Module is
    generic (
      C_USE_GPI      : integer;
      C_GPI_SIZE     : integer);
    port (
      Clk      : in  std_logic;
      Reset    : in  boolean;
      GPI_Read : in  std_logic;
      GPI      : in  std_logic_vector(C_GPI_SIZE-1 downto 0);
      GPI_In   : out std_logic_vector(C_GPI_SIZE-1 downto 0));
  end component GPI_Module;

  component intr_ctrl is
    generic (
      C_INTC_ENABLED    : std_logic_vector(31 downto 0);
      C_INTC_LEVEL_EDGE : std_logic_vector(31 downto 0);
      C_INTC_POSITIVE   : std_logic_vector(31 downto 0));
    port (
      Clk             : in  std_logic;
      Reset           : in  boolean;
      INTR            : in  std_logic_vector(31 downto 0);
      INTC_WRITE_CIAR : in  std_logic;
      INTC_WRITE_CIER : in  std_logic;
      Write_Data      : in  std_logic_vector(31 downto 0);
      INTC_READ_CISR  : in  std_logic;
      INTC_READ_CIPR  : in  std_logic;
      INTC_IRQ        : out std_logic;
      INTC_CISR       : out std_logic_vector(31 downto 0);
      INTC_CIPR       : out std_logic_vector(31 downto 0));
  end component intr_ctrl;

  --------------------------------------------------------------------------------------------------
  -- Interrupt functions and constant calculation
  --------------------------------------------------------------------------------------------------
  function int2std (i : integer) return std_logic is
  begin  -- function int2std
    if (i = 0) then
      return '0';
    else
      return '1';
    end if;    
  end function int2std;  
  
  function INTR_IMPLEMENTED return std_logic_vector is
    variable t : std_logic_vector(31 downto 0);
  begin
    t(31 downto 16) := (others => '0');
    if (C_INTC_USE_EXT_INTR /= 0) then
      t(C_INTC_INTR_SIZE+15 downto 16) := (others => '1');      
    end if;
    t(15 downto 11) := "00000";
    t(10)           := int2std(C_FIT4_INTERRUPT);
    t(9)            := int2std(C_FIT3_INTERRUPT);
    t(8)            := int2std(C_FIT2_INTERRUPT);
    t(7)            := int2std(C_FIT1_INTERRUPT);
    t(6)            := int2std(C_PIT4_INTERRUPT);
    t(5)            := int2std(C_PIT3_INTERRUPT);
    t(4)            := int2std(C_PIT2_INTERRUPT);
    t(3)            := int2std(C_PIT1_INTERRUPT);
    t(2)            := int2std(C_UART_RX_INTERRUPT);
    t(1)            := int2std(C_UART_TX_INTERRUPT);
    t(0)            := int2std(C_UART_ERROR_INTERRUPT);
    return t;
  end function INTR_IMPLEMENTED;

  constant C_INTR_IMPL : std_logic_vector(31 downto 0) := INTR_IMPLEMENTED;

  signal reset   : boolean;
  --------------------------------------------------------------------------------------------------
  -- GPI signal
  --------------------------------------------------------------------------------------------------
  signal gpi1_in : std_logic_vector(C_GPI1_SIZE-1 downto 0);
  signal gpi2_in : std_logic_vector(C_GPI2_SIZE-1 downto 0);
  signal gpi3_in : std_logic_vector(C_GPI3_SIZE-1 downto 0);
  signal gpi4_in : std_logic_vector(C_GPI4_SIZE-1 downto 0);

  --------------------------------------------------------------------------------------------------
  -- Calculate FIT period for generating 16*C_UART_BAUDRATE
  --------------------------------------------------------------------------------------------------
  function FIT_PERIOD (FREQ : integer; BAUDRATE : integer ) return integer is
    constant C_BAUDRATE_16_BY_2 : integer := (16 * BAUDRATE) / 2;
    constant C_REMAINDER        : integer := FREQ rem (16 * BAUDRATE);
    constant C_RATIO            : integer := FREQ / (16 * BAUDRATE);   
  begin
    if (C_BAUDRATE_16_BY_2 < C_REMAINDER) then
      return (C_RATIO + 1);
    else  
      return C_RATIO;
    end if;
  end function FIT_PERIOD;

  --------------------------------------------------------------------------------------------------
  -- UART signals
  --------------------------------------------------------------------------------------------------
  signal en_16x_baud          : std_logic;
  signal tx_data_transmitted  : std_logic;
  signal tx_buffer_empty      : std_logic;
  signal read_uart_rx         : std_logic;
  signal uart_rx_data         : std_logic_vector(C_UART_DATA_BITS-1 downto 0);
  signal rx_data_received     : std_logic;
  signal rx_data_exists       : std_logic;
  signal rx_frame_error       : std_logic;
  signal rx_overrun_error     : std_logic;
  signal rx_parity_error      : std_logic;
  signal uart_status          : std_logic_vector(7 downto 0);
  signal uart_rx_interrupt    : std_logic;
  signal uart_tx_interrupt    : std_logic;
  signal uart_error_interrupt : std_logic;

  --------------------------------------------------------------------------------------------------
  -- FIT signals
  --------------------------------------------------------------------------------------------------
  signal fit1_interrupt_i : std_logic;
  signal fit2_interrupt_i : std_logic;
  signal fit3_interrupt_i : std_logic;
  signal fit4_interrupt_i : std_logic;

  --------------------------------------------------------------------------------------------------
  -- PIT signals
  --------------------------------------------------------------------------------------------------
  signal pit1_interrupt_i : std_logic;
  signal pit1_count_en    : std_logic;
  signal pit1_data        : std_logic_vector(C_PIT1_SIZE-1 downto 0);
  signal pit2_interrupt_i : std_logic;
  signal pit2_count_en    : std_logic;
  signal pit2_data        : std_logic_vector(C_PIT2_SIZE-1 downto 0);
  signal pit3_interrupt_i : std_logic;
  signal pit3_count_en    : std_logic;
  signal pit3_data        : std_logic_vector(C_PIT3_SIZE-1 downto 0);
  signal pit4_interrupt_i : std_logic;
  signal pit4_count_en    : std_logic;
  signal pit4_data        : std_logic_vector(C_PIT4_SIZE-1 downto 0);

  --------------------------------------------------------------------------------------------------
  -- INTC signals
  --------------------------------------------------------------------------------------------------
  signal intr      : std_logic_vector(31 downto 0);
  signal intc_cisr : std_logic_vector(31 downto 0);
  signal intc_cipr : std_logic_vector(31 downto 0);
begin  -- architecture IMP

  Reset <= (Rst = '1');
  
  --------------------------------------------------------------------------------------------------
  -- UART Section
  --------------------------------------------------------------------------------------------------
  Using_UART_TX : if (C_USE_UART_TX /= 0) generate
    UART_TX_I1 : UART_Transmit
      generic map (
        C_DATA_BITS  => C_UART_DATA_BITS,
        C_USE_PARITY => C_UART_USE_PARITY,
        C_ODD_PARITY => C_UART_ODD_PARITY)
      port map (
        Clk         => Clk,
        Reset       => Reset,
        EN_16x_Baud => en_16x_baud,

        TX                  => UART_Tx,
        Write_TX_Data       => UART_TX_Write,
        TX_Data             => Write_Data(C_UART_DATA_BITS-1 downto 0),
        TX_Data_Transmitted => tx_data_transmitted,
        TX_Buffer_Empty     => tx_buffer_empty);
  end generate Using_UART_TX;

  No_UART_TX : if (C_USE_UART_TX = 0) generate
    tx_buffer_empty     <= '0';
    tx_data_transmitted <= '0';
    UART_Tx             <= '0';
  end generate No_UART_TX;

  Using_UART_RX : if (C_USE_UART_RX /= 0) generate
    
    UART_RX_I1 : UART_Receive
      generic map (
        C_DATA_BITS    => C_UART_DATA_BITS,
        C_USE_PARITY   => C_UART_USE_PARITY,
        C_ODD_PARITY   => C_UART_ODD_PARITY)
      port map (
        Clk         => Clk,
        Reset       => Reset,
        EN_16x_Baud => en_16x_baud,

        RX               => UART_RX,
        Read_RX_Data     => UART_Rx_Read,
        RX_Data          => uart_rx_data,
        RX_Data_Received => rx_data_received,
        RX_Data_Exists   => rx_data_exists,
        RX_Frame_Error   => rx_frame_error,
        RX_Overrun_Error => rx_overrun_error,
        RX_Parity_Error  => rx_parity_error);
  end generate Using_UART_RX;

  No_UART_RX : if (C_USE_UART_RX = 0) generate
    uart_rx_data     <= (others => '0');
    rx_data_received <= '0';
    rx_data_exists   <= '0';
    rx_frame_error   <= '0';
    rx_overrun_error <= '0';
    rx_parity_error  <= '0';
    
  end generate No_UART_RX;

  Using_UART : if ((C_USE_UART_RX /= 0) or (C_USE_UART_TX /= 0)) generate

    UART_FIT_I : FIT_Module
      generic map (
        C_USE_FIT    => 1,
        C_NO_CLOCKS  => FIT_PERIOD(C_FREQ,C_UART_BAUDRATE),
        C_INACCURACY => 0)
      port map (
        Clk       => Clk,
        Reset     => Reset,
        Toggle    => open,
        Interrupt => en_16x_baud);
    
    Uart_Control_Status_I1 : Uart_Control_Status
      generic map (
        C_USE_UART_RX     => C_USE_UART_RX,
        C_USE_UART_TX     => C_USE_UART_TX,
        C_UART_DATA_BITS  => C_UART_DATA_BITS,
        C_UART_USE_PARITY => C_UART_USE_PARITY,
        C_UART_ODD_PARITY => C_UART_ODD_PARITY)
      port map (
        CLK                  => CLK,
        Reset                => Reset,
        TX_Data_Transmitted  => tx_data_transmitted,
        TX_Buffer_Empty      => tx_buffer_empty,
        RX_Data_Received     => rx_data_received,
        RX_Data_Exists       => rx_data_exists,
        RX_Frame_Error       => rx_frame_error,
        RX_Overrun_Error     => rx_overrun_error,
        RX_Parity_Error      => rx_parity_error,
        UART_Status_Read     => UART_Status_Read,
        UART_Status          => uart_status,
        UART_Interrupt       => UART_Interrupt,
        UART_Rx_Interrupt    => uart_rx_interrupt,
        UART_Tx_Interrupt    => uart_tx_interrupt,
        UART_Error_Interrupt => uart_error_interrupt);
  end generate Using_UART;

  No_UART : if ((C_USE_UART_RX = 0) and (C_USE_UART_TX = 0)) generate
    uart_status          <= (others => '0');
    UART_Interrupt       <= '0';
    uart_rx_interrupt    <= '0';
    uart_tx_interrupt    <= '0';
    uart_error_interrupt <= '0';
  end generate No_UART;

  --------------------------------------------------------------------------------------------------
  -- FIT Section
  --------------------------------------------------------------------------------------------------
  FIT_I1 : FIT_Module
    generic map (
      C_USE_FIT    => C_USE_FIT1,
      C_NO_CLOCKS  => C_FIT1_NO_CLOCKS,
      C_INACCURACY => 0)
    port map (
      Clk       => Clk,
      Reset     => Reset,
      Toggle    => FIT1_Toggle,
      Interrupt => fit1_interrupt_i);

  FIT1_Interrupt <= fit1_interrupt_i;

  FIT_I2 : FIT_Module
    generic map (
      C_USE_FIT    => C_USE_FIT2,
      C_NO_CLOCKS  => C_FIT2_NO_CLOCKS,
      C_INACCURACY => 0)
    port map (
      Clk       => Clk,
      Reset     => Reset,
      Toggle    => FIT2_Toggle,
      Interrupt => fit2_interrupt_i);

  FIT2_Interrupt <= fit2_interrupt_i;

  FIT_I3 : FIT_Module
    generic map (
      C_USE_FIT    => C_USE_FIT3,
      C_NO_CLOCKS  => C_FIT3_NO_CLOCKS,
      C_INACCURACY => 0)
    port map (
      Clk       => Clk,
      Reset     => Reset,
      Toggle    => FIT3_Toggle,
      Interrupt => fit3_interrupt_i);

  FIT3_Interrupt <= fit3_interrupt_i;

  FIT_I4 : FIT_Module
    generic map (
      C_USE_FIT    => C_USE_FIT4,
      C_NO_CLOCKS  => C_FIT4_NO_CLOCKS,
      C_INACCURACY => 0)
    port map (
      Clk       => Clk,
      Reset     => Reset,
      Toggle    => FIT4_Toggle,
      Interrupt => fit4_interrupt_i);

  FIT4_Interrupt <= fit4_interrupt_i;

  --------------------------------------------------------------------------------------------------
  -- PIT Section
  --------------------------------------------------------------------------------------------------

  pit1_count_en <= '1'              when C_PIT1_PRESCALER = 0 else
                   fit1_interrupt_i when C_PIT1_PRESCALER = 1 else
                   fit2_interrupt_i when C_PIT1_PRESCALER = 2 else
                   fit3_interrupt_i when C_PIT1_PRESCALER = 3 else
                   fit4_interrupt_i when C_PIT1_PRESCALER = 4 else
                   pit2_interrupt_i when C_PIT1_PRESCALER = 6 else
                   pit3_interrupt_i when C_PIT1_PRESCALER = 7 else
                   pit4_interrupt_i when C_PIT1_PRESCALER = 8 else
                   PIT1_Enable      when C_PIT1_PRESCALER = 9 else
                   '0';

  PIT_I1 : PIT_Module
    generic map (
      C_USE_PIT      => C_USE_PIT1,
      C_PIT_SIZE     => C_PIT1_SIZE,
      C_PIT_READABLE => C_PIT1_READABLE)
    port map (
      Clk               => Clk,
      Reset             => Reset,
      PIT_Count_En      => pit1_count_en,
      PIT_Write_Preload => PIT1_Write_Preload,
      PIT_Write_Ctrl    => PIT1_Write_Ctrl,
      PIT_Read          => PIT1_Read,
      Write_Data        => Write_Data,
      PIT_Data          => pit1_data,
      PIT_Toggle        => PIT1_Toggle,
      PIT_Interrupt     => pit1_interrupt_i);

  PIT1_Interrupt <= pit1_interrupt_i;
  
  pit2_count_en <= '1'              when C_PIT2_PRESCALER = 0 else
                   fit1_interrupt_i when C_PIT2_PRESCALER = 1 else
                   fit2_interrupt_i when C_PIT2_PRESCALER = 2 else
                   fit3_interrupt_i when C_PIT2_PRESCALER = 3 else
                   fit4_interrupt_i when C_PIT2_PRESCALER = 4 else
                   pit1_interrupt_i when C_PIT2_PRESCALER = 5 else
                   pit3_interrupt_i when C_PIT2_PRESCALER = 7 else
                   pit4_interrupt_i when C_PIT2_PRESCALER = 8 else
                   PIT2_Enable      when C_PIT2_PRESCALER = 9 else
                   '0';

  PIT_I2 : PIT_Module
    generic map (
      C_USE_PIT      => C_USE_PIT2,
      C_PIT_SIZE     => C_PIT2_SIZE,
      C_PIT_READABLE => C_PIT2_READABLE)
    port map (
      Clk               => Clk,
      Reset             => Reset,
      PIT_Count_En      => pit2_count_en,
      PIT_Write_Preload => PIT2_Write_Preload,
      PIT_Write_Ctrl    => PIT2_Write_Ctrl,
      PIT_Read          => PIT2_Read,
      Write_Data        => Write_Data,
      PIT_Data          => pit2_data,
      PIT_Toggle        => PIT2_Toggle,
      PIT_Interrupt     => pit2_interrupt_i);

  PIT2_Interrupt <= pit2_interrupt_i;

  pit3_count_en <= '1'              when C_PIT3_PRESCALER = 0 else
                   fit1_interrupt_i when C_PIT3_PRESCALER = 1 else
                   fit2_interrupt_i when C_PIT3_PRESCALER = 2 else
                   fit3_interrupt_i when C_PIT3_PRESCALER = 3 else
                   fit4_interrupt_i when C_PIT3_PRESCALER = 4 else
                   pit1_interrupt_i when C_PIT3_PRESCALER = 5 else
                   pit2_interrupt_i when C_PIT3_PRESCALER = 6 else
                   pit4_interrupt_i when C_PIT3_PRESCALER = 8 else
                   PIT3_Enable      when C_PIT3_PRESCALER = 9 else
                   '0';

  PIT_I3 : PIT_Module
    generic map (
      C_USE_PIT      => C_USE_PIT3,
      C_PIT_SIZE     => C_PIT3_SIZE,
      C_PIT_READABLE => C_PIT3_READABLE)
    port map (
      Clk               => Clk,
      Reset             => Reset,
      PIT_Count_En      => pit3_count_en,
      PIT_Write_Preload => PIT3_Write_Preload,
      PIT_Write_Ctrl    => PIT3_Write_Ctrl,
      PIT_Read          => PIT3_Read,
      Write_Data        => Write_Data,
      PIT_Data          => pit3_data,
      PIT_Toggle        => PIT3_Toggle,
      PIT_Interrupt     => pit3_interrupt_i);

  PIT3_Interrupt <= pit3_interrupt_i;

  pit4_count_en <= '1'              when C_PIT4_PRESCALER = 0 else
                   fit1_interrupt_i when C_PIT4_PRESCALER = 1 else
                   fit2_interrupt_i when C_PIT4_PRESCALER = 2 else
                   fit3_interrupt_i when C_PIT4_PRESCALER = 3 else
                   fit4_interrupt_i when C_PIT4_PRESCALER = 4 else
                   pit1_interrupt_i when C_PIT4_PRESCALER = 5 else
                   pit2_interrupt_i when C_PIT4_PRESCALER = 6 else
                   pit3_interrupt_i when C_PIT4_PRESCALER = 7 else
                   PIT4_Enable      when C_PIT4_PRESCALER = 9 else
                   '0';

  PIT_I4 : PIT_Module
    generic map (
      C_USE_PIT      => C_USE_PIT4,
      C_PIT_SIZE     => C_PIT4_SIZE,
      C_PIT_READABLE => C_PIT4_READABLE)
    port map (
      Clk               => Clk,
      Reset             => Reset,
      PIT_Count_En      => pit4_count_en,
      PIT_Write_Preload => PIT4_Write_Preload,
      PIT_Write_Ctrl    => PIT4_Write_Ctrl,
      PIT_Read          => PIT4_Read,
      Write_Data        => Write_Data,
      PIT_Data          => pit4_data,
      PIT_Toggle        => PIT4_Toggle,
      PIT_Interrupt     => pit4_interrupt_i);

  PIT4_Interrupt <= pit4_interrupt_i;
  
  GPO_I1 : GPO_Module
    generic map (
      C_USE_GPO    => C_USE_GPO1,
      C_GPO_SIZE   => C_GPO1_SIZE,
      C_GPO_INIT   => C_GPO1_INIT)
    port map (
      Clk        => Clk,
      Reset      => Reset,
      GPO_Write  => GPO1_Write,
      Write_Data => Write_Data,
      GPO        => GPO1);

  GPO_I2 : GPO_Module
    generic map (
      C_USE_GPO    => C_USE_GPO2,
      C_GPO_SIZE   => C_GPO2_SIZE,
      C_GPO_INIT   => C_GPO2_INIT)
    port map (
      Clk        => Clk,
      Reset      => Reset,
      GPO_Write  => GPO2_Write,
      Write_Data => Write_Data,
      GPO        => GPO2);

  GPO_I3 : GPO_Module
    generic map (
      C_USE_GPO    => C_USE_GPO3,
      C_GPO_SIZE   => C_GPO3_SIZE,
      C_GPO_INIT   => C_GPO3_INIT)
    port map (
      Clk        => Clk,
      Reset      => Reset,
      GPO_Write  => GPO3_Write,
      Write_Data => Write_Data,
      GPO        => GPO3);

  GPO_I4 : GPO_Module
    generic map (
      C_USE_GPO    => C_USE_GPO4,
      C_GPO_SIZE   => C_GPO4_SIZE,
      C_GPO_INIT   => C_GPO4_INIT)
    port map (
      Clk        => Clk,
      Reset      => Reset,
      GPO_Write  => GPO4_Write,
      Write_Data => Write_Data,
      GPO        => GPO4);

  --------------------------------------------------------------------------------------------------
  -- GPI Section
  --------------------------------------------------------------------------------------------------
  GPI_I1 : GPI_Module
    generic map (
      C_USE_GPI      => C_USE_GPI1,
      C_GPI_SIZE     => C_GPI1_SIZE)
    port map (
      Clk      => Clk,
      Reset    => Reset,
      GPI_Read => GPI1_Read,
      GPI      => GPI1,
      gpi_in   => gpi1_in);

  GPI_I2 : GPI_Module
    generic map (
      C_USE_GPI      => C_USE_GPI2,
      C_GPI_SIZE     => C_GPI2_SIZE)
    port map (
      Clk      => Clk,
      Reset    => Reset,
      GPI_Read => GPI2_Read,
      GPI      => GPI2,
      gpi_in   => gpi2_in);

  GPI_I3 : GPI_Module
    generic map (
      C_USE_GPI      => C_USE_GPI3,
      C_GPI_SIZE     => C_GPI3_SIZE)
    port map (
      Clk      => Clk,
      Reset    => Reset,
      GPI_Read => GPI3_Read,
      GPI      => GPI3,
      gpi_in   => gpi3_in);

  GPI_I4 : GPI_Module
    generic map (
      C_USE_GPI      => C_USE_GPI4,
      C_GPI_SIZE     => C_GPI4_SIZE)
    port map (
      Clk      => Clk,
      Reset    => Reset,
      GPI_Read => GPI4_Read,
      GPI      => GPI4,
      gpi_in   => gpi4_in);

  --------------------------------------------------------------------------------------------------
  -- Interrupt Handler section
  --------------------------------------------------------------------------------------------------
  intr(31 downto C_INTC_INTR_SIZE+16)  <= (others => '0');
  intr(C_INTC_INTR_SIZE+15 downto 16)  <= INTC_Interrupt;
  intr(15 downto 11) <= (others => '0');
  intr(10)           <= fit4_interrupt_i;
  intr(9)            <= fit3_interrupt_i;
  intr(8)            <= fit2_interrupt_i;
  intr(7)            <= fit1_interrupt_i;
  intr(6)            <= pit4_interrupt_i;
  intr(5)            <= pit3_interrupt_i;
  intr(4)            <= pit2_interrupt_i;
  intr(3)            <= pit1_interrupt_i;
  intr(2)            <= uart_rx_interrupt;
  intr(1)            <= uart_tx_interrupt;
  intr(0)            <= uart_error_interrupt;

  intr_ctrl_I1 : intr_ctrl
    generic map (
      C_INTC_ENABLED    => C_INTR_IMPL,
      C_INTC_LEVEL_EDGE => C_INTC_LEVEL_EDGE & X"FFFF",
      C_INTC_POSITIVE   => C_INTC_POSITIVE & X"FFFF")
    port map (
      Clk             => Clk,
      Reset           => Reset,
      INTR            => intr,
      INTC_WRITE_CIAR => INTC_WRITE_CIAR,
      INTC_WRITE_CIER => INTC_WRITE_CIER,
      Write_Data      => Write_Data,
      INTC_READ_CISR  => INTC_READ_CISR,
      INTC_READ_CIPR  => INTC_READ_CIPR,
      INTC_IRQ        => INTC_IRQ,
      INTC_CISR       => intc_cisr,
      INTC_CIPR       => intc_cipr);
  
  --------------------------------------------------------------------------------------------------
  -- Read MUX section
  --------------------------------------------------------------------------------------------------
  Simple_OR_Mux : process (gpi1_in, gpi2_in, gpi3_in, gpi4_in, intc_cipr, intc_cisr, pit1_data,
                           pit2_data, pit3_data, pit4_data, uart_rx_data, uart_status) is
    variable u1  : std_logic_vector(31 downto 0);
    variable u2  : std_logic_vector(31 downto 0);
    variable gi1 : std_logic_vector(31 downto 0);
    variable gi2 : std_logic_vector(31 downto 0);
    variable gi3 : std_logic_vector(31 downto 0);
    variable gi4 : std_logic_vector(31 downto 0);
    variable pi1 : std_logic_vector(31 downto 0);
    variable pi2 : std_logic_vector(31 downto 0);
    variable pi3 : std_logic_vector(31 downto 0);
    variable pi4 : std_logic_vector(31 downto 0);
  begin  -- process Simple_OR_Mux
    u1  := (others => '0');
    u2  := (others => '0');
    gi1 := (others => '0');
    gi2 := (others => '0');
    gi3 := (others => '0');
    gi4 := (others => '0');
    pi1 := (others => '0');
    pi2 := (others => '0');
    pi3 := (others => '0');
    pi4 := (others => '0');

    if ((C_USE_UART_TX /= 0) or (C_USE_UART_RX /= 0)) then
      u1(uart_rx_data'range) := uart_rx_data;
    end if;
    
    if ((C_USE_UART_TX /= 0) or (C_USE_UART_RX /= 0)) then
      u2(uart_status'range) := uart_status;
    end if;

    if (C_USE_GPI1 /= 0) then
      gi1(gpi1_in'range) := gpi1_in;
    end if;

    if (C_USE_GPI2 /= 0) then
      gi2(gpi2_in'range) := gpi2_in;
    end if;

    if (C_USE_GPI3 /= 0) then
      gi3(gpi3_in'range) := gpi3_in;
    end if;

    if (C_USE_GPI4 /= 0) then
      gi4(gpi4_in'range) := gpi4_in;
    end if;
    
    if (C_USE_PIT2 /= 0) then
      pi1(pit1_data'range) := pit1_data;
    end if;

    if (C_USE_PIT2 /= 0) then
      pi2(pit2_data'range) := pit2_data;
    end if;

    if (C_USE_PIT3 /= 0) then
      pi3(pit3_data'range) := pit3_data;
    end if;

    if (C_USE_PIT4 /= 0) then
      pi4(pit4_data'range) := pit4_data;
    end if;

    Read_Data <= u1 or u2 or gi1 or gi2 or gi3 or gi4 or pi1 or pi2 or pi3 or pi4 or intc_cisr or intc_cipr;
    
  end process Simple_OR_Mux;

end architecture IMP;
