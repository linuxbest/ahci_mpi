-------------------------------------------------------------------------------
-- uartlite_rx - entity/architecture pair
-------------------------------------------------------------------------------
--
   -- *******************************************************************
-- -- ** (c) Copyright [2007] - [2011] Xilinx, Inc. All rights reserved.*
-- -- **                                                                *
-- -- ** This file contains confidential and proprietary information    *
-- -- ** of Xilinx, Inc. and is protected under U.S. and                *
-- -- ** international copyright and other intellectual property        *
-- -- ** laws.                                                          *
-- -- **                                                                *
-- -- ** DISCLAIMER                                                     *
-- -- ** This disclaimer is not a license and does not grant any        *
-- -- ** rights to the materials distributed herewith. Except as        *
-- -- ** otherwise provided in a valid license issued to you by         *
-- -- ** Xilinx, and to the maximum extent permitted by applicable      *
-- -- ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
-- -- ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
-- -- ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
-- -- ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
-- -- ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
-- -- ** (2) Xilinx shall not be liable (whether in contract or tort,   *
-- -- ** including negligence, or under any other theory of             *
-- -- ** liability) for any loss or damage of any kind or nature        *
-- -- ** related to, arising under or in connection with these          *
-- -- ** materials, including for any direct, or any indirect,          *
-- -- ** special, incidental, or consequential loss or damage           *
-- -- ** (including loss of data, profits, goodwill, or any type of     *
-- -- ** loss or damage suffered as a result of any action brought      *
-- -- ** by a third party) even if such damage or loss was              *
-- -- ** reasonably foreseeable or Xilinx had been advised of the       *
-- -- ** possibility of the same.                                       *
-- -- **                                                                *
-- -- ** CRITICAL APPLICATIONS                                          *
-- -- ** Xilinx products are not designed or intended to be fail-       *
-- -- ** safe, or for use in any application requiring fail-safe        *
-- -- ** performance, such as life-support or safety devices or         *
-- -- ** systems, Class III medical devices, nuclear facilities,        *
-- -- ** applications related to the deployment of airbags, or any      *
-- -- ** other applications that could lead to death, personal          *
-- -- ** injury, or severe property or environmental damage             *
-- -- ** (individually and collectively, "Critical                      *
-- -- ** Applications"). Customer assumes the sole risk and             *
-- -- ** liability of any use of Xilinx products in Critical            *
-- -- ** Applications, subject only to applicable laws and              *
-- -- ** regulations governing limitations on product liability.        *
-- -- **                                                                *
-- -- ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
-- -- ** PART OF THIS FILE AT ALL TIMES.                                *
   -- *******************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        uartlite_rx.vhd
-- Version:         v1.02a
-- Description:     UART Lite Receive Interface Module
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   This section shows the hierarchical structure of xps_uartlite.
--
--              xps_uartlite.vhd
--                 --plbv46_slave_single.vhd
--                 --uartlite_core.vhd
--                    --uartlite_tx.vhd
--                    --uartlite_rx.vhd
--                    --baudrate.vhd
-------------------------------------------------------------------------------
-- Author:          MZC
--
-- History:
--  MZC     11/17/06
-- ^^^^^^
--  - Initial release of v1.00.a
-- ~~~~~~
--  NSK     01/24/07
-- ^^^^^^
-- Checking-in FLO modified files.
-- ~~~~~~
--  NSK     01/25/07
-- ^^^^^^
-- 1. Code clean up.
-- 2. Added FIFO write/read inhibit when FIFO is FULL/EMPTY.
-- ~~~~~~
--  NSK     01/29/07
-- ^^^^^^
-- 1. Removed End of file statement.
-- 2. Added comments for signal RX_Overrun_Error.
-- ~~~~~~
--  NSK     02/02/07
-- ^^^^^^
-- In the process USING_PARITY for the generation of "parity". In the 
-- assignment parity <=  bo2sl(C_USE_PARITY = 1);. The parameter C_USE_PARITY 
-- is replaced by C_ODD_PARITY.
-- ~~~~~~
--  NSK     02/09/07
-- ^^^^^^
-- All asynchronous reset is changed to synchronous reset.
-- ~~~~~~
--  USM     08/22/08
-- ^^^^^^
-- Modified to fix linting errors.
-- ~~~~~~
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

library proc_common_v3_00_a;
-- dynshreg_i_f refered from proc_common_v3_00_a
use proc_common_v3_00_a.dynshreg_i_f;
-- srl_fifo_f refered from proc_common_v3_00_a
use proc_common_v3_00_a.srl_fifo_f;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics :
-------------------------------------------------------------------------------
-- UART Lite generics
--  C_DATA_BITS           -- The number of data bits in the serial frame
--  C_USE_PARITY          -- Determines whether parity is used or not
--  C_ODD_PARITY          -- If parity is used determines whether parity
--                           is even or odd
--
-- PLBv46 Slave Single block generics
--  C_FAMILY              -- Xilinx FPGA Family
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Ports :
-------------------------------------------------------------------------------
-- System Signals
--  Clk                 --  Clock signal
--  Rst                 --  Reset signal
-- UART Lite interface
--  RX                  --  Receive Data

-- Internal UART interface signals
--  EN_16x_Baud         --  Enable signal which is 16x times baud rate
--  Read_RX_FIFO        --  Read receive FIFO
--  Reset_RX_FIFO       --  Reset receive FIFO
--  RX_Data             --  Receive data output
--  RX_Data_Present     --  Receive data present
--  RX_BUFFER_FULL      --  Receive buffer full
--  RX_Frame_Error      --  Receive frame signal error
--  RX_Overrun_Error    --  Receive overrun error
--  RX_Parity_Error     --  Receive parity error

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Entity Section
-------------------------------------------------------------------------------
entity uartlite_rx is
  generic 
   (
    C_DATA_BITS      : integer range 5 to 8 := 8;
    C_USE_PARITY     : integer range 0 to 1 := 1;
    C_ODD_PARITY     : integer range 0 to 1 := 1;
    C_FAMILY         : string               := "virtex5"
   );
  port 
   (
    Clk              : in  std_logic;
    Reset            : in  std_logic;
    EN_16x_Baud      : in  std_logic;
    RX               : in  std_logic;
    Read_RX_FIFO     : in  std_logic;
    Reset_RX_FIFO    : in  std_logic;
    RX_Data          : out std_logic_vector(0 to C_DATA_BITS-1);
    RX_Data_Present  : out std_logic;
    RX_BUFFER_FULL   : out std_logic;
    RX_Frame_Error   : out std_logic;
    RX_Overrun_Error : out std_logic;
    RX_Parity_Error  : out std_logic
   );
end entity uartlite_rx;

-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------
architecture imp of uartlite_rx is

    type     bo2sl_type is array(boolean) of std_logic;
    type     bo2na_type is array(boolean) of natural;
    
    constant bo2sl      :  bo2sl_type := (false => '0', true => '1');
    constant bo2na      :  bo2na_type := (false => 0, true => 1);

    ---------------------------------------------------------------------------
    -- Constant declarations
    ---------------------------------------------------------------------------
    constant SERIAL_TO_PAR_LENGTH : integer := 
                                    C_DATA_BITS + bo2na(C_USE_PARITY=1);
    constant STOP_BIT_POS         : integer := SERIAL_TO_PAR_LENGTH;
    constant DATA_LSB_POS         : integer := SERIAL_TO_PAR_LENGTH;
    constant CALC_PAR_POS         : integer := SERIAL_TO_PAR_LENGTH;

    ---------------------------------------------------------------------------
    -- Signal declarations
    ---------------------------------------------------------------------------
    signal previous_rx             : std_logic;
    signal start_Edge_Detected     : boolean;
    signal start_Edge_Detected_Bit : std_logic;
    signal running                 : boolean;
    signal mid_Start_Bit           : std_logic;
    signal recycle                 : std_logic;
    signal sample_Point            : std_logic;
    signal stop_Bit_Position       : std_logic;
    signal fifo_Write              : std_logic;
    
    signal fifo_din             : std_logic_vector(0 to SERIAL_TO_PAR_LENGTH);
    signal serial_to_Par        : std_logic_vector(1 to SERIAL_TO_PAR_LENGTH);
    signal calc_parity          : std_logic;
    signal parity               : std_logic;
    signal rx_Buffer_Full_I     : std_logic;
    signal rx_1                 : std_logic;
    signal rx_2                 : std_logic;
    signal rx_Data_Empty        : std_logic := '0';
    signal fifo_wr              : std_logic;
    signal fifo_rd              : std_logic;

begin  -- architecture IMP

    ---------------------------------------------------------------------------
    -- RX_SAMPLING : Double sample RX to avoid meta-stability
    ---------------------------------------------------------------------------
    RX_SAMPLING: process (Clk) is
    begin  -- process RX_Sampling
        if Clk'event and Clk = '1' then -- rising clock edge
            if Reset = '1' then         -- synchronous reset (active high)
                rx_1 <= '1';
                rx_2 <= '1';
            else 
                rx_1 <= RX;
                rx_2 <= rx_1;
            end if;
        end if;
    end process RX_SAMPLING;

-------------------------------------------------------------------------------
-- Detect a falling edge on RX and start a new reception if idle
-------------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- PREV_RX_DFF : Detect a falling edge on RX
    ---------------------------------------------------------------------------
    PREV_RX_DFF : process (Clk) is
    begin  -- process Prev_RX_DFF
        if Clk'event and Clk = '1' then  -- rising clock edge
            if (Reset = '1') then
                previous_rx <= '0';
            elsif (EN_16x_Baud = '1') then
                previous_rx <= rx_2;
            end if;
        end if;
    end process PREV_RX_DFF;

    ---------------------------------------------------------------------------
    -- START_EDGE_DFF : Start a new reception if idle
    ---------------------------------------------------------------------------
    START_EDGE_DFF : process (Clk) is
    begin  -- process Start_Edge_DFF
        if Clk'event and Clk = '1' then  -- rising clock edge
            if (Reset = '1') then
                start_Edge_Detected <= false;
            elsif (EN_16x_Baud = '1') then
                start_Edge_Detected <= not running and (previous_rx = '1')
                                                   and (rx_2 = '0');
            end if;
        end if;
    end process START_EDGE_DFF;

    ---------------------------------------------------------------------------
    -- RUNNING_DFF : Running is '1' during a reception
    ---------------------------------------------------------------------------
    RUNNING_DFF : process (Clk) is
    begin  -- process Running_DFF
        if Clk'event and Clk = '1' then -- rising clock edge
            if Reset = '1' then         -- synchronous reset (active high)
                running <= false;
            elsif (EN_16x_Baud = '1') then
                if (start_Edge_Detected) then
                    running <= true;
                elsif ((sample_Point = '1') and (stop_Bit_Position = '1')) then
                    running <= false;
                end if;
            end if;
        end if;
    end process RUNNING_DFF;

    start_Edge_Detected_Bit <= '1' when start_Edge_Detected else '0';

    ---------------------------------------------------------------------------
    --MID_START_BIT_SRL16_I: Delay start_Edge_Detected 7 clocks to get the 
    --                       mid-point in a bit. The address needs to be
    --                       6 "0110" to get a delay of 7.
    ---------------------------------------------------------------------------
    MID_START_BIT_SRL16_I : entity proc_common_v3_00_a.dynshreg_i_f
      generic map 
       (
        C_DEPTH  => 16,
        C_DWIDTH => 1,
        C_FAMILY => C_FAMILY
       )
      port map
       (
        Clk      => Clk,
        Clken    => EN_16x_Baud,
        Addr     => "0110",
        Din(0)   => start_Edge_Detected_Bit,
        Dout(0)  => mid_Start_Bit
       );


    recycle <= not (stop_Bit_Position) and (mid_Start_Bit or sample_Point);

    -------------------------------------------------------------------------
    -- DELAY_16_I : Keep regenerating new values into the 16 clock delay, 
    --              Starting with the first mid_Start_Bit and for every new 
    --              sample_points until stop_Bit_Position is reached
    -------------------------------------------------------------------------
    DELAY_16_I : entity proc_common_v3_00_a.dynshreg_i_f
      generic map 
       (
        C_DEPTH  => 16,
        C_DWIDTH => 1,
        C_FAMILY => C_FAMILY
       )
      port map
       (
        Clk      => Clk,
        Clken    => EN_16x_Baud,
        Addr     => "1111",
        Din(0)   => recycle,
        Dout(0)  => sample_Point
       );

    ---------------------------------------------------------------------------
    -- STOP_BIT_HANDLER : Detect when the stop bit is received
    ---------------------------------------------------------------------------
    STOP_BIT_HANDLER : process (Clk) is
    begin  -- process Stop_Bit_Handler
        if Clk'event and Clk = '1' then -- rising clock edge
            if (Reset = '1') then       -- synchronous reset (active high)
                stop_Bit_Position <= '0';
            elsif (EN_16x_Baud = '1') then
                if (stop_Bit_Position = '0') then
                  -- Start bit has reached the end of the shift register 
                  -- (Stop bit position)
                    stop_Bit_Position <= sample_Point and 
                                         fifo_din(STOP_BIT_POS);
                elsif (sample_Point = '1') then
                  -- if stop_Bit_Position = '1', then 
                  -- clear it at the next sample_Point
                    stop_Bit_Position <= '0';
                end if;
            end if;
        end if;
    end process STOP_BIT_HANDLER;

    ---------------------------------------------------------------------------
    -- USING_PARITY : Generate parity handling when C_USE_PARITY = 1
    ---------------------------------------------------------------------------
    USING_PARITY : if (C_USE_PARITY = 1) generate

        PARITY_DFF: Process (Clk) is
        begin
            if (Clk'event and Clk = '1') then
                if (mid_Start_Bit = '1') then
                    parity <=  bo2sl(C_ODD_PARITY = 1);
                elsif (EN_16x_Baud = '1') then
                    parity <= calc_parity;
                end if;
            end if;
        end process PARITY_DFF;
      
        calc_parity <= parity when (stop_Bit_Position or not sample_Point) = '1'
                       else parity xor rx_2;

        RX_Parity_Error <= (EN_16x_Baud and sample_Point) and
                           (fifo_din(CALC_PAR_POS)) and not stop_Bit_Position
                           when running and (rx_2 /= parity) else '0';

    end generate USING_PARITY;

    fifo_din(0) <= rx_2;

    ---------------------------------------------------------------------------
    -- SERIAL_TO_PARALLEL : Serial to parrallel conversion data part
    ---------------------------------------------------------------------------
    SERIAL_TO_PARALLEL : for i in 1 to serial_to_Par'length generate
    
        serial_to_Par(i) <= fifo_din(i) when (stop_Bit_Position or 
                                              not sample_Point) = '1'
                            else fifo_din(i-1);

        BIT_I: Process (Clk) is
        begin
            if (Clk'event and Clk = '1') then
                if (mid_Start_Bit = '1') then
                    fifo_din(i) <= bo2sl(i=1); -- Bit 1 resets to '1'; 
                                               -- others to '0'
                elsif (EN_16x_Baud = '1') then
                    fifo_din(i) <= serial_to_Par(i);
                end if;
            end if;
        end process BIT_I;

    end generate SERIAL_TO_PARALLEL;

    --------------------------------------------------------------------------
    -- FIFO_WRITE_DFF : Write in the received word when the stop_bit has been 
    --                  received and it is a '1'
    --------------------------------------------------------------------------
    FIFO_WRITE_DFF : process (Clk) is
    begin  -- process FIFO_Write_DFF
        if Clk'event and Clk = '1' then  -- rising clock edge
            if Reset = '1' then          -- synchronous reset (active high)
                fifo_Write <= '0';
            else
                fifo_Write <= stop_Bit_Position and rx_2 and sample_Point 
                                                and EN_16x_Baud;
            end if;
        end if;
    end process FIFO_WRITE_DFF;

    RX_Frame_Error <= stop_Bit_Position and sample_Point and EN_16x_Baud 
                      and not rx_2;

    ---------------------------------------------------------------------------
    -- SRL_FIFO_I : Receive FIFO Interface
    ---------------------------------------------------------------------------
    fifo_wr <= fifo_Write and (not rx_Buffer_Full_I);
    fifo_rd <= Read_RX_FIFO and (not rx_Data_Empty);

    SRL_FIFO_I : entity proc_common_v3_00_a.srl_fifo_f
      generic map
       (
        C_DWIDTH   => C_DATA_BITS,
        C_DEPTH    => 16,
        C_FAMILY   => C_FAMILY
       )
      port map
       (
        Clk        => Clk,
        Reset      => Reset_RX_FIFO,
        FIFO_Write => fifo_wr,
        Data_In    => fifo_din(DATA_LSB_POS - C_DATA_BITS + 1 to DATA_LSB_POS),
        FIFO_Read  => fifo_rd,
        Data_Out   => RX_Data,
        FIFO_Full  => rx_Buffer_Full_I,
        FIFO_Empty => rx_Data_Empty,
        Addr       => open
       );

    RX_Data_Present  <= not rx_Data_Empty;
    RX_Overrun_Error <= rx_Buffer_Full_I and fifo_write;  -- Note that if
        -- the RX FIFO is read on the same cycle as it is written while full,
        -- there is no loss of data. However this case is not optimized and
        -- is also reported as an overrun.
    RX_BUFFER_FULL   <= rx_Buffer_Full_I;

end architecture imp;
