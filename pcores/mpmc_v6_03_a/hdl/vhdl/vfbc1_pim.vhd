--*******************************************************************
-- (c) Copyright 2010 Xilinx, Inc. All rights reserved.
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
--  All rights reserved.
--
--******************************************************************
--
-- Filename - vfbc_pim.vhd
-- Author - , Xilinx
-- Creation - August 5, 2006
--
-- Description - VFBC Wrapper
--               This module wraps the vfbc containing records for 
--               IO and includes the backend control instance that
--               translates the VFBC MIG interface into the MPMC NPI
--               interface.
--              
--
--*******************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library work;
use work.memxlib_utils.all;
use work.p_vfbc.all;

entity vfbc1_pim is
  generic(
    VFBC_FAMILY                 : string        := "V5";  -- Device Family: S3, S6, V4, V5, V6
    ENABLE_HIF                  : boolean       := FALSE; -- Enable Host Interface
    ENABLE_CHIPSCOPE            : boolean       := FALSE; -- Enable Chipscope Instance (disabled)
    ENABLE_DEBUG                : boolean       := FALSE; -- Enabl Debug Port
    BA_SIZE                     : integer       := 2;     -- Bank Address Size in bits
    BA_LOC                      : integer       := 24;    -- ROW ADDRESS WIDTH (13) + COL ADDRESS WIDTH (10)
    VFBC_NPI_WIDTH              : integer       := 64;    -- NPI Data Width: 32, 64
    VFBC_BURST_LENGTH           : integer       := 8;     -- Burst Length in 32bit words.  Set to 32.
  -- Command Interface 0 PARAMETERS
    CMD0_PORT_ID                : integer := 0;           -- Command FIFO Port ID. Not Used.
    CMD0_FIFO_DEPTH             : integer := 8;           -- Command FIFO Depth
    CMD0_ASYNC_CLOCK            : boolean := TRUE;        -- Command FIFO use sync registers if set True.
    CMD0_AFULL_COUNT            : integer := 1;           -- Command FIFO Almost Full Threshold (depth - count)

  -- Write Data Interface 0 PARAMETERS
    WD0_ENABLE                  : boolean := TRUE;        -- Enable Write FIFO
    WD0_DATA_WIDTH              : integer := 32;          -- Write FIFO Data Width: 8,16,32,64
    WD0_FIFO_DEPTH              : integer := 8;           -- Write FIFO Depth
    WD0_ASYNC_CLOCK             : boolean := TRUE;        -- Write FIFO Use sync registers if set True.
    WD0_AFULL_COUNT             : integer := 1;           -- Write FIFO Almost Full Threshold
    WD0_BYTEEN_ENABLE           : boolean := FALSE;       -- Write FIFO Enable Byte Enables

  -- Read Data Interface 0 PARAMETERS
    RD0_ENABLE                  : boolean := TRUE;        -- Enable Read FIFO
    RD0_DATA_WIDTH              : integer := 32;          -- Read FIFO Data Width: 8,16,32,64
    RD0_FIFO_DEPTH              : integer := 8;           -- Read FIFO Depth. 
    RD0_ASYNC_CLOCK             : boolean := TRUE;        -- Read FIFO use sync registers if set True.
    RD0_AEMPTY_COUNT            : integer := 1            -- Read FIFO Almost Empty threshold
  );
  port(
    clk                 : in std_logic;                   -- VFBC Clock / MPMC_Clk0
    srst                : in std_logic;                   -- Synchronous Reset

    -- Host Interface
    hif_address         : in std_logic_vector(7 downto 0);   -- Host Interface Address
    hif_datain          : in std_logic_vector(31 downto 0);  -- Host Interface Write Data
    hif_write           : in std_logic;                      -- Host Interface Write/Not-Read. Active High=write 
    hif_dataout         : out std_logic_vector(31 downto 0); -- Host Interface Read Data

    -- Command Interfaces
    cmd0_clk            : in  std_logic;                     -- Command FIFO Write Clock
    cmd0_reset          : in  std_logic;                     -- Command FIFO Reset.  Flushes all Commands.
    cmd0_data           : in  std_logic_vector(31 downto 0); -- Command FIFO Data
    cmd0_write          : in  std_logic;                     -- Command FIFO Write Enable. Active High
    cmd0_end            : in  std_logic;                     -- Command FIFO End Cmd.  Last Command word when high.
    cmd0_full           : out std_logic;                     -- Command FIFO Full Flag
    cmd0_almost_full    : out std_logic;                     -- Command FIFO Almost Full
    cmd0_idle           : out std_logic;                     -- Command FIFO Idle.  High when no active command
        

    -- Write Fifo Interfaces 
    wd0_clk             : in  std_logic;                     -- Write FIFO Clock
    wd0_reset           : in  std_logic;                     -- Write FIFO Reset. Active High
    wd0_write           : in  std_logic;                     -- Write FIFO Write Enable. Active High
    wd0_end_burst       : in  std_logic;                     -- Write FIFO End Burst/Object. Active High denotes last data word
    wd0_flush           : in  std_logic;                     -- Write FIFO Flush. Active High
    wd0_data            : in  std_logic_vector(WD0_DATA_WIDTH-1 downto 0);   -- Write FIFO Data
    wd0_data_be         : in  std_logic_vector(WD0_DATA_WIDTH/8-1 downto 0); -- Write FIFO Byte Enables. Active High
    wd0_full            : out std_logic;                     -- Write FIFO Full
    wd0_almost_full     : out std_logic;                     -- Write FIFO Almost Full
        
        
    -- Read Fifo Interfaces
    rd0_clk             : in  std_logic;                     -- Read FIFO Clock
    rd0_reset           : in  std_logic;                     -- Read FIFO Reset. Active High.
    rd0_read            : in  std_logic;                     -- Read FIFO Read Enable.
    rd0_end_burst       : in  std_logic;                     -- Read FIFO End Burst/Object. Active High skips ahead to next burst
                                                             -- start
    rd0_flush           : in  std_logic;                     -- Read FIFO Flush. Active High.
    rd0_data            : out std_logic_vector(RD0_DATA_WIDTH-1 downto 0);  -- Read FIFO read data
    rd0_empty           : out std_logic;                     -- Read FIFO Empty Flag. Active High
    rd0_almost_empty    : out std_logic;                     -- Read FIFO Almost Empty Flag. Active High


    -- MPMC Native Port Interface (NPI)
    npi_init_done       : in  std_logic;                     -- NPI Memory Initialization Done.  Active High
    npi_addr_ack        : in  std_logic;                     -- NPI Address Acknowledge
    npi_rdfifo_word_add : in  std_logic_vector(3 downto 0);  -- RESERVED
    npi_rdfifo_data     : in  std_logic_vector(VFBC_NPI_WIDTH-1 downto 0); -- NPI Read FIFO Data
    npi_rdfifo_latency  : in  std_logic_vector(1 downto 0);  -- NPI Read FIFO latency from pop: Valid {0,1,2}
    npi_rdfifo_empty    : in  std_logic;                     -- NPI Read FIFO Empty Flag. Active High.
    npi_wrfifo_almost_full : in std_logic;                   -- NPI Write FIFO Almost Full Flag. Active High.

    npi_address         : out std_logic_vector(31 downto 0); -- NPI Address.  External Memory address
    npi_addr_req        : out std_logic;                     -- NPI Address Request. Active High
    npi_size            : out std_logic_vector(3 downto 0);  -- NPI Transfer Size   
    npi_rnw             : out std_logic;                     -- NPI Read Not Write
    npi_rdfifo_pop      : out std_logic;                     -- NPI Read FIFO Pop/Read Enable. Active High
    npi_rdfifo_flush    : out std_logic;                     -- NPI Read FIFO Flush. Active High
    npi_wrfifo_data     : out std_logic_vector(VFBC_NPI_WIDTH-1 downto 0); -- NPI Write FIFO Data. Active High
    npi_wrfifo_be       : out std_logic_vector(VFBC_NPI_WIDTH/8-1 downto 0); -- NPI Write FIFO Byte Enable. Active High
    npi_wrfifo_push     : out std_logic;                     -- NPI Write FIFO Push/Write-Enable. Active High
    npi_wrfifo_flush    : out std_logic;                     -- NPI Write FIFO Flush. Active High

    -- Debug port
    debug                : out std_logic_vector(255 downto 0) -- Debug signals. Unused

  );
end vfbc1_pim;

architecture rtl of vfbc1_pim is
  function bool2slv(A : boolean; B: std_logic_vector) return std_logic_vector is
  begin
    if A = TRUE then 
      return B; 
    else 
      return "0000";
    end if;
  end;
  function maximum (
    left, 
    right : integer
  )                     -- inputs
    return integer is
  begin  -- function max
    if LEFT > RIGHT then 
      return LEFT;
    else 
      return RIGHT;
    end if;
  end function maximum;


constant ZEROS  : std_logic_vector(31 downto 0) := (others => '0');
constant NUM_DATA_PORTS : integer := 2;
constant WORD_BURST_LENGTH : integer:= VFBC_BURST_LENGTH * (64 / VFBC_NPI_WIDTH); -- 1x if 64 NPI, 2x if 32 NPI
-- Need to handle 64 bits - I think it does already.

-- The minimum number of objects in the write/read fifos is 8, thus the maimum(8,*) func!
-- Divide by 8 (bits), then divide by 128(bytes in burst) = 1/(8*128) = 1/1024
-- Add 1023 to numerator to always round up
constant WD_FIFO_DEPTH : integer := maximum(8,(1023 + (WD0_FIFO_DEPTH*WD0_DATA_WIDTH))/1024); --1024 @32bit should set 128 (burst
                                                                                              -- 8) or 32 (burst 32) 
constant RD_FIFO_DEPTH : integer := maximum(8,(1023 + (RD0_FIFO_DEPTH*RD0_DATA_WIDTH))/1024); --1024 @32bit should set 128 (burst
                                                                                              -- 8) or 32 (burst 32) 
constant CMD_FIFO_DEPTH : integer := (3 + CMD0_FIFO_DEPTH)/4; 

signal MCBusIn        : MCBusInputSignals;
signal MCBusOut       : MCBusOutputSignals;

--signal    DmaCmdPortIn        : CmdPortInputSignalsArray(0 downto 0);
--signal    DmaCmdPortOut       : CmdPortOutputSignalsArray(0 downto 0);
--
signal    WrDataPortIn        : WrDataFifoInputSignalsArray(NUM_DATA_PORTS-1 downto 0);
signal    WrDataPortOut       : WrDataFifoOutputSignalsArray(NUM_DATA_PORTS-1 downto 0);

signal    RdDataPortIn        : RdDataFifoInputSignalsArray(NUM_DATA_PORTS-1 downto 0);
signal    RdDataPortOut       : RdDataFifoOutputSignalsArray(NUM_DATA_PORTS-1 downto 0);

signal    DmaCmdPortIn        : CmdPortInputSignals;
signal    DmaCmdPortOut       : CmdPortOutputSignals;

--signal    WrDataPortIn        : WrDataFifoInputSignals;
--signal    WrDataPortOut       : WrDataFifoOutputSignals;
--
--signal    RdDataPortIn        : RdDataFifoInputSignals;
--signal    RdDataPortOut       : RdDataFifoOutputSignals;

signal rd_active_afull  : std_logic_vector(NUM_DATA_PORTS-1 downto 0);

signal npi_init_done_cmd_dly : std_logic_vector(2 downto 0);
signal npi_init_done_rd_dly : std_logic_vector(2 downto 0);
signal npi_init_done_wd_dly : std_logic_vector(2 downto 0);

attribute KEEP                : boolean;
attribute KEEP         of npi_init_done_cmd_dly : signal is TRUE;
attribute KEEP         of npi_init_done_rd_dly : signal is TRUE;
attribute KEEP         of npi_init_done_wd_dly : signal is TRUE;

begin

------------------------------------------------------------------------------
-- Init Done Sync to CMD Clock Domain
------------------------------------------------------------------------------
  process(cmd0_clk)
  begin
    if(rising_edge(cmd0_clk)) then
      npi_init_done_cmd_dly <= npi_init_done_cmd_dly(npi_init_done_cmd_dly'high - 1 downto 0) & npi_init_done;
    end if;
  end process;
  
------------------------------------------------------------------------------
-- Init Done Sync to Read Clock Domain
------------------------------------------------------------------------------
  process(rd0_clk)
  begin
    if(rising_edge(rd0_clk)) then
      npi_init_done_rd_dly <= npi_init_done_rd_dly(npi_init_done_rd_dly'high - 1 downto 0) & npi_init_done;
    end if;
  end process;

------------------------------------------------------------------------------
-- Init Done Sync to Write Clock Domain
------------------------------------------------------------------------------
  process(wd0_clk)
  begin
    if(rising_edge(wd0_clk)) then
      npi_init_done_wd_dly <= npi_init_done_wd_dly(npi_init_done_wd_dly'high - 1 downto 0) & npi_init_done;
    end if;
  end process;

------------------------------------------------------------------------------
-- Command Signals
------------------------------------------------------------------------------
DmaCmdPortIn.Clk        <= cmd0_clk;
DmaCmdPortIn.MReset_n   <= not cmd0_reset;
DmaCmdPortIn.MData      <= cmd0_data;
DmaCmdPortIn.MFlagWrite <= cmd0_write;
DmaCmdPortIn.MFlagEnd   <= cmd0_end;

cmd0_full               <= DmaCmdPortOut.SFlagFull or not npi_init_done_cmd_dly(npi_init_done_cmd_dly'high);
cmd0_almost_full        <= DmaCmdPortOut.SFlagAlmostFull or not npi_init_done_cmd_dly(npi_init_done_cmd_dly'high);
cmd0_idle               <= DmaCmdPortOut.SFlagIdle;

------------------------------------------------------------------------------
-- Data Write Signals
------------------------------------------------------------------------------
WrDataPortIn(1).Clk                                        <= wd0_clk;
WrDataPortIn(1).MReset_n                                   <= not wd0_reset;
WrDataPortIn(1).MCmd                                       <= "00" & wd0_write;
WrDataPortIn(1).MAddr                                      <= (others => '0');
WrDataPortIn(1).MData(WD0_DATA_WIDTH-1 downto 0)           <= wd0_data;
WrDataPortIn(1).MDataByteEn(WD0_DATA_WIDTH/8-1 downto 0)   <= wd0_data_be;
WrDataPortIn(1).MFlagCommit                                <= wd0_end_burst;
WrDataPortIn(1).MFlagFlush                                 <= wd0_flush;

wd0_full                                                <= WrDataPortOut(1).SFlagFull 
                                                           or not npi_init_done_wd_dly(npi_init_done_wd_dly'high);
wd0_almost_full                                         <= WrDataPortOut(1).SFlagAlmostFull 
                                                           or not npi_init_done_wd_dly(npi_init_done_wd_dly'high);
------------------------------------------------------------------------------
-- Data Read Signals
------------------------------------------------------------------------------
RdDataPortIn(0).Clk                                        <= rd0_clk;
RdDataPortIn(0).MReset_n                                   <= not rd0_reset;
RdDataPortIn(0).MCmd                                       <= '0' & rd0_read & '0';
RdDataPortIn(0).MAddr                                      <= (others => '0');
RdDataPortIn(0).MFlagCommit                                <= rd0_end_burst;
RdDataPortIn(0).MFlagFlush                                 <= rd0_flush;

rd0_data                        <= RdDataPortOut(0).SData(RD0_DATA_WIDTH-1 downto 0);
rd0_empty                       <= RdDataPortOut(0).SFlagEmpty or not npi_init_done_rd_dly(npi_init_done_rd_dly'high);
rd0_almost_empty                <= RdDataPortOut(0).SFlagAlmostEmpty or not npi_init_done_rd_dly(npi_init_done_rd_dly'high);


------------------------------------------------------------------------------
-- VFBC
------------------------------------------------------------------------------
UVFBC: entity work.vfbc
generic map(
        VFBC_FAMILY                     => VFBC_FAMILY,
        ENABLE_HIF                      => ENABLE_HIF,
        ENABLE_CHIPSCOPE                => ENABLE_CHIPSCOPE,
        VFBC_BURST_LENGTH               => WORD_BURST_LENGTH,
        NUM_CMD_PORTS                   => 1,
        NUM_DATA_PORTS                  => NUM_DATA_PORTS,
        BA_SIZE                         => BA_SIZE,
        BA_LOC                          => BA_LOC,
        MC_DATA_WIDTH                   => VFBC_NPI_WIDTH/2,
        --FIXED_DATA_PORT_ID              => (CMD0_PORT_ID,1),
        CMD_PORT_ASYNC_CLOCK            => bool2slv(CMD0_ASYNC_CLOCK,"1111"),
        CMD_PORT_FIFO_DEPTH             => (CMD_FIFO_DEPTH,CMD_FIFO_DEPTH,CMD_FIFO_DEPTH,CMD_FIFO_DEPTH),
        WR_DATA_PORT_ENABLE             => bool2slv(WD0_ENABLE,"0110"),
        WR_DATA_FIFO_ASYNC_CLOCK        => bool2slv(WD0_ASYNC_CLOCK, "0110"),
        WR_DATA_FIFO_WIDTH              => (WD0_DATA_WIDTH,WD0_DATA_WIDTH,WD0_DATA_WIDTH,WD0_DATA_WIDTH),
        WR_DATA_FIFO_DEPTH              => (WD_FIFO_DEPTH,WD_FIFO_DEPTH,WD_FIFO_DEPTH,WD_FIFO_DEPTH),
        WR_DATA_AFULL_COUNT             => (WD0_AFULL_COUNT,WD0_AFULL_COUNT,WD0_AFULL_COUNT,WD0_AFULL_COUNT),
        WR_DATA_SIMPLE_FIFO             => "1111",
        RD_DATA_PORT_ENABLE             => bool2slv(RD0_ENABLE, "1001"),
        RD_DATA_FIFO_ASYNC_CLOCK        => bool2slv(RD0_ASYNC_CLOCK, "1001"),
        RD_DATA_FIFO_WIDTH              => (RD0_DATA_WIDTH,RD0_DATA_WIDTH,RD0_DATA_WIDTH,RD0_DATA_WIDTH),
        RD_DATA_FIFO_DEPTH              => (RD_FIFO_DEPTH,RD_FIFO_DEPTH,RD_FIFO_DEPTH,RD_FIFO_DEPTH),
        RD_DATA_AEMPTY_COUNT            => (RD0_AEMPTY_COUNT,RD0_AEMPTY_COUNT,RD0_AEMPTY_COUNT,RD0_AEMPTY_COUNT),
        RD_DATA_SIMPLE_FIFO             => "1111",
        REAL_TIME                       => "0000"
)
port map(
        MCClk           => clk, 
        srst            => srst,

    -- Host Interface Control
        HifAddress      => hif_address,
        HifDataIn       => hif_datain,
        HifDataOut      => hif_dataout,
        HifWrite        => hif_write, 

        rd_active_afull => rd_active_afull,

        DmaCmdPortIn(0) => DmaCmdPortIn,
        DmaCmdPortOut(0)=> DmaCmdPortOut,

        WrDataPortIn    => WrDataPortIn,
        WrDataPortOut   => WrDataPortOut,

        RdDataPortIn    => RdDataPortIn,
        RdDataPortOut   => RdDataPortOut,

        MCBusIn         => MCBusIn,
        MCBusOut        => MCBusOut
);


------------------------------------------------------------------------------
-- VFBC Backend Control
------------------------------------------------------------------------------
UVFBC_BACKEND_CTRL: entity work.vfbc_backend_control
generic map(
                VFBC_NPI_WIDTH => VFBC_NPI_WIDTH,
                VFBC_BURST_LENGTH => WORD_BURST_LENGTH,
                NUM_DATA_PORTS => NUM_DATA_PORTS
           )
port map(
    clk                 => clk,
    srst                => srst,

    -- VFBC FIFO Flags
    wd_reset            => wd0_reset,
    wd_flush            => wd0_flush,
    rd_reset            => rd0_reset,
    rd_flush            => rd0_flush,


    -- VFBC Memory Controller Interface
    App_Af_addr         => MCBusOut.App_Af_addr,
    App_Af_wren         => MCBusOut.App_Af_wren,
    App_WDF_data        => MCBusOut.App_WDF_data(VFBC_NPI_WIDTH-1 downto 0),
    App_Mask_data       => MCBusOut.App_Mask_data(VFBC_NPI_WIDTH/8-1 downto 0),
    App_WDF_wren        => MCBusOut.App_WDF_wren,

    rd_active_afull     => "00", --rd_active_afull, 

    Read_data_valid     => MCBusIn.Read_data_valid,
    Read_data_fifo_out  => MCBusIn.Read_data_fifo_out(VFBC_NPI_WIDTH-1 downto 0),
    WDF_Almost_Full     => MCBusIn.WDF_Almost_Full,
    AF_Almost_Full      => MCBusIn.AF_Almost_Full,


    -- MPMC Native Port Interface (NPI)
    npi_init_done       => npi_init_done,
    npi_addr_ack        => npi_addr_ack,
    npi_rdfifo_word_add => npi_rdfifo_word_add,
    npi_rdfifo_data     => npi_rdfifo_data,
    npi_rdfifo_empty    => npi_rdfifo_empty,
    npi_wrfifo_almost_full => npi_wrfifo_almost_full,

    npi_address         => npi_address,
    npi_addr_req        => npi_addr_req,
    npi_size            => npi_size,
    npi_rnw             => npi_rnw,
    npi_rdfifo_pop      => npi_rdfifo_pop,
    npi_rdfifo_flush    => npi_rdfifo_flush,
    npi_rdfifo_latency  => npi_rdfifo_latency,
    npi_wrfifo_data     => npi_wrfifo_data,
    npi_wrfifo_be       => npi_wrfifo_be,
    npi_wrfifo_push     => npi_wrfifo_push,
    npi_wrfifo_flush    => npi_wrfifo_flush
        );
  GEN_DEBUG: if(ENABLE_DEBUG) generate
    debug(NUM_DATA_PORTS-1 downto 0) <= rd_active_afull;
    debug(NUM_DATA_PORTS) <= MCBusIn.Read_data_valid;
    debug(NUM_DATA_PORTS+1) <= MCBusIn.AF_Almost_Full;
    debug(15 downto NUM_DATA_PORTS+2) <= (others => '1');
    debug(16+VFBC_NPI_WIDTH-1 downto 16) <= MCBusIn.Read_data_fifo_out(VFBC_NPI_WIDTH-1 downto 0);
    debug(debug'high downto 16+VFBC_NPI_WIDTH) <= (others => '1');
  end generate;  
end rtl;


