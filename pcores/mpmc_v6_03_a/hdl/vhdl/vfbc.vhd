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
-- Filename - vfbc.vhd
-- Author - Mankit Lo, Xilinx
-- Creation - July 27, 2006
--
-- Description - VFBC Top Level
--               Provides VFBC read/write FIFOs and command/control
--               FIFOs as well as the interface to the memory
--               controller.
--
--*******************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library work;
use work.memxlib_utils.all;

library work;
use work.p_vfbc.all;

entity vfbc is
  generic(
    VFBC_FAMILY                 : string := "V5";   -- Device Family for Async ObjFIFOs - S3, V4 or V5
    ENABLE_HIF                  : boolean := FALSE; -- Enable Host Port Interface
    ENABLE_CHIPSCOPE            : boolean := FALSE; -- Enable Chipscope - Not used
    VFBC_BURST_LENGTH           : integer := 8;     -- Burst length - Always 32 
    NUM_CMD_PORTS               : integer := 3;     -- Number of Command Ports
    NUM_DATA_PORTS              : integer := 8;     -- Number of Data Ports
    BA_SIZE                     : integer := 2;     -- Bank Address Size (Used in Arbiter)
    BA_LOC                      : integer := 10;    -- Bank Address Location (Used in Arbiter)
    MC_DATA_WIDTH               : integer := 16;    -- Memory Controller Data Width
    FIXED_DATA_PORT_ID          : integer_array := (99,99,99,99,99,99,99,99);   -- Fixed data port id of each command port.  If 99,
                                                                                -- it is not fixed.
    -- CMD PORT PARAMETERS
    CMD_PORT_FIFO_DEPTH         : integer_array := (8,8,8,8,8,8,8,8);           -- Command FIFO depth (in 4 word bursts)
    CMD_PORT_ASYNC_CLOCK        : std_logic_vector := "00000000";               -- '1' Enables, '0' disables CMD sync FFs and Gray
                                                                                -- Code pointers
    -- WR DATA PORT PARAMETERS
    WR_DATA_PORT_ENABLE         : std_logic_vector := "11111111";               -- '1' Enables, '0' disables Write Data port
    WR_DATA_FIFO_ASYNC_CLOCK    : std_logic_vector := "00000000";               -- '1' Enables, '0' disables Write Data sync FFs
                                                                                -- and Gray Code ptrs
    WR_DATA_BYTEEN_ENABLE       : std_logic_vector := "00000000";               -- '1' Enables, '0' disables Write Data byte
                                                                                -- enables
    WR_DATA_FIFO_WIDTH          : integer_array := (32,32,32,32,32,32,32,32);   -- Write FIFO data width
    WR_DATA_FIFO_DEPTH          : integer_array := (8,8,8,8,8,8,8,8);           -- Write FIFO depth (in bursts)
    WR_DATA_AFULL_COUNT         : integer_array := (1,1,1,1,1,1,1,1);           -- Write FIFO almost full count (in bursts)
    WR_DATA_SIMPLE_FIFO         : std_logic_vector := "11111111";               -- '1' Enables, '0' disables auto-producer/consumer
                                                                                -- 
    WR_DATA_FIFO_OBJ_SIZE       : integer_array := (32,32,32,32,32,32,32,32);   -- Write FIFO Size of Data Object.  Fixed to Burst
                                                                                -- Size. Not Used
    -- RD DATA PORT PARAMETERS
    RD_DATA_PORT_ENABLE         : std_logic_vector := "11111111";               -- '1' Enables, '0' disables Read Data port
    RD_DATA_FIFO_ASYNC_CLOCK    : std_logic_vector := "00000000";               -- '1' Enables, '0' disables Read Data sync FFs and
                                                                                -- Gray Code ptrs
    RD_DATA_FIFO_WIDTH          : integer_array := (32,32,32,32,32,32,32,32);   -- Read FIFO data width
    RD_DATA_FIFO_DEPTH          : integer_array := (8,8,8,8,8,8,8,8);           -- Read FIFO depth (in bursts)
    RD_DATA_AEMPTY_COUNT        : integer_array := (1,1,1,1,1,1,1,1);           -- Read FIFO almost empty count (in bursts)
    RD_DATA_SIMPLE_FIFO         : std_logic_vector := "11111111";               -- '1' Enables, '0' disables auto-producer/consumer
                                                                                -- 
    RD_DATA_FIFO_OBJ_SIZE       : integer_array := (32,32,32,32,32,32,32,32);   -- Read FIFO Size of Data Object.  Fixed to Burst
                                                                                -- Size. Not Used
    
    ENABLE_BURST_CUT            : boolean := TRUE;                              -- Enable CMD BUFFERS and Burst Cutting/merging
    ENABLE_RECT_ACCESS          : boolean := TRUE;                              -- Enable 2D transfers (False=2-CMD Words and
                                                                                -- ignores Y Size/Stride
    REAL_TIME                   : std_logic_vector := "00000000";               -- Arbiter: '1' Enables, '0' disables real-time
                                                                                -- fast arb logic for port
    CMD_ARBITRATION_SCHEME      : string := "ROUNDROBIN";                       -- Arbiter: choices are "ROUNDROBIN" and "DEFAULT"
    DATA_ARBITRATION_SCHEME     : string := "ROUNDROBIN"                        -- Arbiter: choices are "ROUNDROBIN" and "DEFAULT"
  );
  port(
    MCClk               : in std_logic;                                         -- Memory Controller Clock
    srst                : in std_logic;                                         -- Synchronous Reset (to MCClk)

    -- Host Interface Control
    HifAddress          : in std_logic_vector(7 downto 0);                      -- Host Interface Address
    HifDataIn           : in std_logic_vector(31 downto 0);                     -- Host Interface Data In
    HifDataOut          : out std_logic_vector(31 downto 0);                    -- Host Interface Data Out
    HifWrite            : in std_logic;                                         -- Host Interface Write Enable. Active High

    rd_active_afull     : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);      -- Read Data Fifo Almost Full for Active Ports

    DmaCmdPortIn        : in CmdPortInputSignalsArray(NUM_CMD_PORTS-1 downto 0);        -- Command Interface Input Record
    DmaCmdPortOut       : out CmdPortOutputSignalsArray(NUM_CMD_PORTS-1 downto 0);      -- Command Interface Output Record

    WrDataPortIn        : in WrDataFifoInputSignalsArray(NUM_DATA_PORTS-1 downto 0)     -- Write Data Port Input Record
                          := (others => ('0',(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0','0','0','0')); -- WrInRec
    WrDataPortOut       : out WrDataFifoOutputSignalsArray(NUM_DATA_PORTS-1 downto 0);  -- Write Data Port Output Record

    RdDataPortIn        : in RdDataFifoInputSignalsArray(NUM_DATA_PORTS-1 downto 0)     -- Read Data Port Input Record
                          := (others => ('0',(others=>'0'),(others=>'0'),'0','0','0')); -- Read Data Port Input Record
    RdDataPortOut       : out RdDataFifoOutputSignalsArray(NUM_DATA_PORTS-1 downto 0); -- Read Data Port Output Record

    MCBusIn : in MCBusInputSignals;                                             -- Memory Controller Input Record
    MCBusOut : out MCBusOutputSignals                                           -- Memory Controller Output Record
  );
end vfbc;

architecture rtl of vfbc is

function CalcBusWidth(DataWidth : integer; BYTEEN_ENABLE : std_logic) return integer is
begin
if (BYTEEN_ENABLE = '1') and (8*(DataWidth/8) /= DataWidth) then
  assert false report "CalcBusWidth: When BYTEEN_ENABLE is true, data width must be multiples of eight." severity error;
  return -1;
elsif (BYTEEN_ENABLE = '1') then 
  return DataWidth*9/8;
else 
  return DataWidth;
end if;
end;

function InterleaveByteEn(Data, ByteEn : std_logic_vector; BYTEEN_ENABLE : std_logic) return std_logic_vector is
variable ResultWithByteEn : std_logic_vector(Data'length+ByteEn'length-1 downto 0);
begin
if (BYTEEN_ENABLE = '1') and (8*(Data'length/8) /= Data'length) then
  assert false report "InterleaveByteEn: When BYTEEN_ENABLE is true, data width must be multiples of eight." severity error;
  return ResultWithByteEn;
elsif (BYTEEN_ENABLE = '1') and ((Data'length/8) /= ByteEn'length) then
  assert false report "InterleaveByteEn: Length of data must be eight times length of byte enable." severity error;
  return ResultWithByteEn;
elsif (BYTEEN_ENABLE = '1') then
  for i in 0 to ByteEn'length-1 loop
    ResultWithByteEn(9*i+8 downto 9*i) := ByteEn(i) & Data(8*i+7 downto 8*i);
  end loop;
  return ResultWithByteEn;
else
  return Data;
end if;
end;  

function ExtractData(DataWithByteEn : std_logic_vector; BYTEEN_ENABLE : std_logic) return std_logic_vector is
variable Result : std_logic_vector(8*DataWithByteEn'length/9-1 downto 0);
variable Temp : std_logic_vector(DataWithByteEn'length-1 downto 0);
begin
Temp := DataWithByteEn;
if (BYTEEN_ENABLE = '1') and (9*(DataWithByteEn'length/9) /= DataWithByteEn'length) then
  assert false report "ExtractData: When BYTEEN_ENABLE is true, data+byteen width must be multiples of nine." severity error;
  return Result;
elsif (BYTEEN_ENABLE = '1') then
  for i in 0 to (DataWithByteEn'length/9)-1 loop
    Result(8*i+7 downto 8*i) := Temp(9*i+7 downto 9*i);
  end loop;
  return Result;
else
  return DataWithByteEn;
end if;
end;  

function ExtractByteEn(DataWithByteEn : std_logic_vector) return std_logic_vector is
variable Result : std_logic_vector(DataWithByteEn'length/9-1 downto 0);
variable Temp : std_logic_vector(DataWithByteEn'length-1 downto 0);
begin
Temp := DataWithByteEn;
for i in 0 to (DataWithByteEn'length/9)-1 loop
  Result(i) := Temp(9*i+8);
end loop;
return Result;
end;  

function StdLogic2Boolean(A : std_logic) return boolean is
begin
if A = '1' then 
        return TRUE; 
else 
        return FALSE; 
end if;
end;

function NumWordsInCmd(RectEn : boolean) return integer is
begin
if RectEn = TRUE then
        return 4; 
else 
        return 2; 
end if;
end;

  function minimum (
    left, 
    right : integer
  )                     -- inputs
    return integer is
  begin  -- function max
    if LEFT < RIGHT then 
      return LEFT;
    else 
      return RIGHT;
    end if;
  end function minimum;

  function minimum_of_set ( 
    inputs : integer_array; 
    num : integer
  )-- inputs
    return integer is
    variable result : integer;
  begin  
    result := inputs(0);
    for i in 0 to num-2 loop
      result := minimum(result, inputs(i+1));
    end loop;

    return result;
  end function minimum_of_set;

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


type VectorArray is array (natural range <>) of std_logic_vector(999 downto 0);
type MemVectorArray is array (natural range <>) of std_logic_vector(MC_DATA_WIDTH*2-1 downto 0);
signal cmd_reset, cmd_reset_dly1, cmd_reset_dly2 : std_logic_vector(NUM_CMD_PORTS-1 downto 0);
signal cmdfifo_release : std_logic_vector(NUM_CMD_PORTS-1 downto 0);
signal cmdfifo_empty, cmdfifo_full, cmdfifo_almost_full : std_logic_vector(NUM_CMD_PORTS-1 downto 0);
signal cmd_in_data: std_logic_vector(32*NUM_CMD_PORTS-1 downto 0);
signal cmd_in_req : std_logic_vector(NUM_CMD_PORTS-1 downto 0);
signal cmd_in_addr : std_logic_vector(logbase2(NumWordsInCmd(ENABLE_RECT_ACCESS)-1)-1 downto 0);
signal cmd_in_gnt : std_logic_vector(NUM_CMD_PORTS-1 downto 0);
signal cmd_in_clken : std_logic;
signal FourCycleCounter : std_logic_vector(1 downto 0);
signal newcmd_addr : std_logic_vector(logbase2(NUM_DATA_PORTS*NumWordsInCmd(ENABLE_RECT_ACCESS)-1)-1 downto 0);
signal newcmd_data : std_logic_vector(31 downto 0);
signal newcmd_wr : std_logic;
signal rdfifo_almost_full, rdfifo_almost_empty : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal rdfifo_almost_full_dly, rdfifo_almost_empty_dly : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal rdfifo_empty, rdfifo_almost_empty_client : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal rdfifo_read_data : VectorArray(NUM_DATA_PORTS-1 downto 0);
signal wrfifo_empty, wrfifo_almost_empty, wrfifo_almost_empty_dly, wrfifo_client_full, wrfifo_client_almost_full,
 wrfifo_almost_full : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal cbuf_rd_addr : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal cbuf_wr_addr : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal arb_granted : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal arb_granted_port_id : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal arb_grant : std_logic;
signal arb_request : std_logic_vector(NUM_DATA_PORTS-1 downto 0); -- Port Request
signal arb_burst_request : std_logic_vector(NUM_DATA_PORTS-1 downto 0); -- Port Burst Request
signal arb_bank : std_logic_vector(NUM_DATA_PORTS*BA_SIZE-1 downto 0); -- Indicates the memory bank which the command is operating
                                                                       -- on
signal arb_wr_op : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal arb_clk_en : std_logic;
signal cbuf_wr_data : std_logic_vector(127 downto 0);
signal cbuf_wr : std_logic;
signal cbuf_rd_data : std_logic_vector(127 downto 0);
signal bc_valid, bc_done : std_logic;
--signal bc_valid_dly : std_logic_vector(1 downto 0);
--signal wr_sel, wr_sel_dly, wr_sel_dly2 : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal wr_sel, wr_sel_dly: std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal wr_release : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal rd_sel : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal rd_commit : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal wrfifo_data_with_byteen : std_logic_vector(MC_DATA_WIDTH*2*NUM_DATA_PORTS*9/8-1 downto 0);
signal wrfifo_num_of_buf_filled : VectorArray(NUM_DATA_PORTS-1 downto 0);
signal rdfifo_num_of_buf_avail : VectorArray(NUM_DATA_PORTS-1 downto 0);
signal wrfifo_data : std_logic_vector(MC_DATA_WIDTH*2*NUM_DATA_PORTS-1 downto 0);
signal wr_byte_mask : std_logic_vector(MC_DATA_WIDTH/4*NUM_DATA_PORTS-1 downto 0);

signal bc_update_xcount : std_logic_vector(23 downto 0);
--CJM signal wrfifo_prod_m, wrfifo_cons_m, rdfifo_prod_m, rdfifo_cons_m : std_logic_vector(2*NUM_DATA_PORTS-1 downto 0);
signal wrfifo_prod_d : std_logic_vector(256*9/8*NUM_DATA_PORTS-1 downto 0);
signal wrfifo_reset, wrfifo_reset_dly1, wrfifo_reset_dly2, rdfifo_reset, rdfifo_reset_dly1, rdfifo_reset_dly2 :
 std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal wrfifo_flush_dly1, wrfifo_flush_dly2, rdfifo_flush_dly1, rdfifo_flush_dly2 : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal wrfifo_reset_or_flush, rdfifo_reset_or_flush : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal PortActive : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal PortActive_dly1 : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal PortActive_dly2 : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
--signal PortReset : std_logic_vector(NUM_DATA_PORTS-1 downto 0);

signal memif_address    : std_logic_vector(35 downto 0);
signal memif_add_wren   : std_logic;
signal last_memif_data_out   : std_logic_vector(MC_DATA_WIDTH-1 downto 0);
signal memif_data_out   : std_logic_vector(MC_DATA_WIDTH*2-1 downto 0);
signal memif_data_out_dly   : std_logic_vector(MC_DATA_WIDTH*2-1 downto 0);
signal memif_data_in    : std_logic_vector(MC_DATA_WIDTH*2-1 downto 0);
signal memif_data_in_dly : MemVectorArray(3 downto 0);
signal memif_data_wren  : std_logic;
signal memif_data_wren_dly  : std_logic;
signal memif_data_wren_dly2 : std_logic;
signal memif_data_mask  : std_logic_vector(MC_DATA_WIDTH/4-1 downto 0);
--signal memif_data_mask_dly  : std_logic_vector(MC_DATA_WIDTH/4-1 downto 0);

signal wr_release_probe         : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal wr_sel_probe             : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal rd_sel_probe             : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal rd_commit_probe          : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal rd_data_probe            : std_logic_vector(MC_DATA_WIDTH*2-1 downto 0);
signal rd_data_valid_probe      : std_logic;
signal wr_data_probe            : std_logic_vector(MC_DATA_WIDTH*2-1 downto 0);
signal add_probe                : std_logic_vector(35 downto 0);
signal data_wren_probe          : std_logic;
signal add_wren_probe           : std_logic;
signal d_afull_probe            : std_logic;
signal a_afull_probe            : std_logic;
signal cmd_probe                : std_logic_vector(128*NUM_CMD_PORTS-1 downto 0);
--signal mc_rd_data_valid    : std_logic;
signal wrfifo0_data_probe       : std_logic_vector(31 downto 0); 
signal wrfifo0_probe            : std_logic;
signal wr_commit0_probe         : std_logic;

signal write_swap               : std_logic;
signal read_swap                : std_logic;
signal bc_raf_almost_full       : std_logic;
--constant BURST_SIZE : integer := 16; --4;  -- 40
--constant MEM_BURST_SIZE : integer := 32; -- 8;  -- 40
constant BURST_SIZE : integer := VFBC_BURST_LENGTH/2; 
--constant MEM_BURST_SIZE : integer := VFBC_BURST_LENGTH;
constant ZEROS : std_logic_vector(1023 downto 0) := (others => '0');

attribute MAX_FANOUT: string; 
attribute MAX_FANOUT of rd_sel: signal is "8";
attribute MAX_FANOUT of bc_valid: signal is "16";

attribute SYN_PRESERVE        : boolean;
attribute KEEP                : boolean;
attribute SYN_PRESERVE of wrfifo_flush_dly1 : signal is TRUE;
attribute KEEP         of wrfifo_flush_dly1 : signal is TRUE;
attribute SYN_PRESERVE of wrfifo_flush_dly2 : signal is TRUE;
attribute KEEP         of wrfifo_flush_dly2 : signal is TRUE;

attribute SYN_PRESERVE of wrfifo_reset_dly1 : signal is TRUE;
attribute KEEP         of wrfifo_reset_dly1 : signal is TRUE;
attribute SYN_PRESERVE of wrfifo_reset_dly2 : signal is TRUE;
attribute KEEP         of wrfifo_reset_dly2 : signal is TRUE;

attribute SYN_PRESERVE of rdfifo_flush_dly1 : signal is TRUE;
attribute KEEP         of rdfifo_flush_dly1 : signal is TRUE;
attribute SYN_PRESERVE of rdfifo_flush_dly2 : signal is TRUE;
attribute KEEP         of rdfifo_flush_dly2 : signal is TRUE;

attribute SYN_PRESERVE of rdfifo_reset_dly1 : signal is TRUE;
attribute KEEP         of rdfifo_reset_dly1 : signal is TRUE;
attribute SYN_PRESERVE of rdfifo_reset_dly2 : signal is TRUE;
attribute KEEP         of rdfifo_reset_dly2 : signal is TRUE;

attribute SYN_PRESERVE of wrfifo_reset          : signal is TRUE;
attribute KEEP         of wrfifo_reset          : signal is TRUE;
attribute SYN_PRESERVE of wrfifo_reset_or_flush : signal is TRUE;
attribute KEEP         of wrfifo_reset_or_flush : signal is TRUE;

attribute SYN_PRESERVE of rdfifo_reset          : signal is TRUE;
attribute KEEP         of rdfifo_reset          : signal is TRUE;
attribute SYN_PRESERVE of rdfifo_reset_or_flush : signal is TRUE;
attribute KEEP         of rdfifo_reset_or_flush : signal is TRUE;

attribute SYN_PRESERVE of PortActive_dly1       : signal is TRUE;
attribute KEEP         of PortActive_dly1       : signal is TRUE;
attribute SYN_PRESERVE of PortActive_dly2       : signal is TRUE;
attribute KEEP         of PortActive_dly2       : signal is TRUE;

attribute SYN_PRESERVE of cmd_reset_dly1        : signal is TRUE;
attribute KEEP         of cmd_reset_dly1        : signal is TRUE;
attribute SYN_PRESERVE of cmd_reset_dly2        : signal is TRUE;
attribute KEEP         of cmd_reset_dly2        : signal is TRUE;

attribute SYN_PRESERVE of memif_data_wren_dly   : signal is TRUE;
attribute KEEP         of memif_data_wren_dly   : signal is TRUE;
attribute SYN_PRESERVE of memif_data_wren_dly2  : signal is TRUE;
attribute KEEP         of memif_data_wren_dly2  : signal is TRUE;

attribute SYN_PRESERVE of wrfifo_almost_empty_dly : signal is TRUE;
attribute KEEP         of wrfifo_almost_empty_dly : signal is TRUE;

attribute SYN_PRESERVE of rdfifo_almost_full_dly  : signal is TRUE;
attribute KEEP         of rdfifo_almost_full_dly  : signal is TRUE;

attribute SYN_PRESERVE of wr_sel_dly              : signal is TRUE;
attribute KEEP         of wr_sel_dly              : signal is TRUE;

attribute SYN_PRESERVE of memif_data_out          : signal is TRUE;
attribute KEEP         of memif_data_out          : signal is TRUE;

attribute SYN_PRESERVE of last_memif_data_out     : signal is TRUE;
attribute KEEP         of last_memif_data_out     : signal is TRUE;

attribute SYN_PRESERVE of memif_data_out_dly      : signal is TRUE;
attribute KEEP         of memif_data_out_dly      : signal is TRUE;

attribute SYN_PRESERVE of memif_data_in_dly       : signal is TRUE;
attribute KEEP         of memif_data_in_dly       : signal is TRUE;

begin
------------------------------------------------------------------------------
-- Command FIFOs
------------------------------------------------------------------------------
GEN_CMD_FIFOS: for i in 0 to NUM_CMD_PORTS-1 generate
  
  UCmdFifo : entity work.ObjFifoAsyncDiffW
  generic map(
    FAMILY              => VFBC_FAMILY, 
    DATA_BITS_PROD      => 32,
    DATA_BITS_CONS      => 32,
    NO_OBJS             => CMD_PORT_FIFO_DEPTH(i),
    OBJ_SIZE_PROD       => NumWordsInCmd(ENABLE_RECT_ACCESS),
    OBJ_SIZE_CONS       => NumWordsInCmd(ENABLE_RECT_ACCESS),
    AFULL_COUNT         => 1,
    AUTO_PRODUCER       => TRUE,
    ASYNC_CLOCK         => StdLogic2Boolean(CMD_PORT_ASYNC_CLOCK(i)),
    MEM_TYPE            => BLOCK_RAMSTYLE
  )
  port map(
    sclr                => cmd_reset(i),
    Prod_Clk            => DmaCmdPortIn(i).Clk,
    Cons_Clk            => MCClk,
    Prod_Write          => DmaCmdPortIn(i).MFlagWrite,
    Prod_Read           => '0',
    Prod_Commit         => DmaCmdPortIn(i).MFlagEnd, --'0',
    Prod_A              => ZEROS(logbase2(NumWordsInCmd(ENABLE_RECT_ACCESS)-1)-1 downto 0),
    Prod_D              => DmaCmdPortIn(i).MData,
    Prod_Full           => cmdfifo_full(i), --DmaCmdPortOut(i).SFlagFull,
    Prod_AlmostFull     => cmdfifo_almost_full(i), --DmaCmdPortOut(i).SFlagAlmostFull,
    Cons_Empty          => cmdfifo_empty(i),
    Cons_Write          => '0',
    Cons_Read           => '1',
    Cons_Release        => cmdfifo_release(i),
    Cons_A              => cmd_in_addr,
    Cons_D              => ZEROS(31 downto 0),
    Cons_Q              => cmd_in_data(32*i+31 downto 32*i),

    Prod_NumObjAvail    => open,
    Prod_Q              => open,
    Cons_NumObjFilled   => open, 
    Cons_AlmostEmpty    => open

  );

  ---------------------------------------------------------------------------
  -- Sync port active to command clock domain
  ---------------------------------------------------------------------------
  process(MCClk)
  begin
    if rising_edge(MCClk) then
      if(PortActive = 0) then
        PortActive_dly1(i) <= '1';
      else
        PortActive_dly1(i) <= '0';
      end if;
    end if;
  end process;

  process(DmaCmdPortIn(i).Clk)
  begin
    if rising_edge(DmaCmdPortIn(i).Clk) then
      PortActive_dly2(i)         <= PortActive_dly1(i);
      DmaCmdPortOut(i).SFlagIdle <= PortActive_dly2(i);
    end if;
  end process;


  ---------------------------------------------------------------------------
  -- Sync command reset to VFBC clock domain
  ---------------------------------------------------------------------------
  process(MCClk)
  begin
    if rising_edge(MCClk) then
      cmd_reset_dly1(i) <= DmaCmdPortIn(i).MReset_n;
      cmd_reset_dly2(i) <= cmd_reset_dly1(i);

      if(srst = '1') then
        cmd_reset(i) <= '1';
      elsif(cmd_reset_dly2(i) = '0') then -- active low reset
        cmd_reset(i) <= '1';
      elsif (cmd_in_clken = '1' and cmd_reset_dly2(i) = '1') then
        cmd_reset(i) <= '0';
      end if;

    end if;
  end process;

  cmdfifo_release(i) <= '1' when (cmd_in_addr = (NumWordsInCmd(ENABLE_RECT_ACCESS)-1)) and (cmd_in_gnt(i) = '1') else '0';
  DmaCmdPortOut(i).SFlagFull       <= cmdfifo_full(i);
  DmaCmdPortOut(i).SFlagAlmostFull <= cmdfifo_almost_full(i);

  ---------------------------------------------------------------------------
  -- Command request generate only when command FIFO is not empty
  ---------------------------------------------------------------------------
  process(MCClk)
  begin
    if rising_edge(MCClk) then
      if (cmd_reset(i) = '1') then
        cmd_in_req(i) <= '0';
      elsif (cmd_in_clken = '1') then
        if (cmd_in_gnt(i) = '1') then
        --if ((cmd_in_gnt(i) = '1') or (cmd_reset(i) = '1')) then
          cmd_in_req(i) <= '0';
        else
          cmd_in_req(i) <= not cmdfifo_empty(i);
        end if;
      end if;
    end if;
  end process;
  
      
end generate GEN_CMD_FIFOS;


GEN_BURST_CUT: if ENABLE_BURST_CUT generate

  GEN_MULTI_PORT : if NUM_DATA_PORTS > 0 generate

    UNewCmd : entity work.vfbc_newcmd
    generic map(
      NUM_CMD_PORTS             => NUM_CMD_PORTS,
      NUM_CMD_WORDS_PER_PORT    => NumWordsInCmd(ENABLE_RECT_ACCESS),
      NUM_DATA_PORTS            => NUM_DATA_PORTS,
      FIXED_DATA_PORT_ID        => FIXED_DATA_PORT_ID,
      ARBITRATION_SCHEME        => CMD_ARBITRATION_SCHEME
    )
    port map(
      srst                      => srst,
      clk                       => MCClk,
      cmd_in_data               => cmd_in_data,
      cmd_in_req                => cmd_in_req,
      cmd_in_gnt                => cmd_in_gnt,
      cmd_in_addr               => cmd_in_addr,
      cmd_in_clken              => cmd_in_clken,
      FourCycleCounter          => FourCycleCounter,
      PortActive                => PortActive,
      newcmd_addr               => newcmd_addr,
      newcmd_data               => newcmd_data,
      newcmd_wr                 => newcmd_wr
    );
    
    UCmdFetch : entity work.vfbc_cmd_fetch
    generic map(
      WD_ENABLE                 => WR_DATA_PORT_ENABLE(0) or WR_DATA_PORT_ENABLE(1),
      RD_ENABLE                 => RD_DATA_PORT_ENABLE(0) or RD_DATA_PORT_ENABLE(1),

      NUM_CMD_PORTS             => NUM_CMD_PORTS,
      NUM_CMD_WORDS_PER_PORT    => NumWordsInCmd(ENABLE_RECT_ACCESS),
      NUM_DATA_PORTS            => NUM_DATA_PORTS,
      BA_SIZE                   => BA_SIZE,
      BA_LOC                    => BA_LOC,
      REQ_WAIT_AFTER_GNT        => 2,
      BURST_SIZE                => BURST_SIZE
    )
    port map(
      srst                      => srst,
      clk                       => MCClk,
      newcmd_addr               => newcmd_addr(logbase2(NumWordsInCmd(ENABLE_RECT_ACCESS)-1)-1 downto 0),
      newcmd_data               => newcmd_data,
      newcmd_wr                 => newcmd_wr,
      --rdfifo_almost_full        => rdfifo_almost_full,
      rdfifo_almost_full        => rdfifo_almost_full_dly,
      wrfifo_empty              => wrfifo_empty,
      wrfifo_almost_empty       => wrfifo_almost_empty_dly,
    
      mc_af_almost_full         => MCBusIn.AF_Almost_full, 
      mc_wd_almost_full         => MCBusIn.WDF_almost_full, 
      bc_raf_almost_full        => bc_raf_almost_full,
    
      cbuf_addr                 => cbuf_rd_addr,
      arb_granted               => arb_granted,
      arb_granted_port_id       => arb_granted_port_id,
      arb_grant                 => arb_grant,
      arb_request               => arb_request,
      arb_burst_request         => arb_burst_request,
      arb_bank                  => arb_bank,
      arb_wr_op                 => arb_wr_op,
      arb_clk_en                => arb_clk_en,
      bc_active_port            => cbuf_wr_addr,
      bc_update_addr            => cbuf_wr_data(62 downto 32),
      bc_update_xcount          => bc_update_xcount,
      bc_update_ycount          => cbuf_wr_data(87 downto 64),
      bc_update                 => cbuf_wr,
      bc_done                   => bc_done,
      bc_valid                  => bc_valid,
      WritePortReset            => wrfifo_reset,
      ReadPortReset             => rdfifo_reset,
      PortActive                => PortActive,
      FourCycleCounter          => FourCycleCounter
    );
    
    UArbitrator : entity work.vfbc_arbitrator
    generic map(
      NUM_PORTS                 => NUM_DATA_PORTS,
      BA_SIZE                   => BA_SIZE,
      REAL_TIME                 => REAL_TIME,
      SCHEME                    => DATA_ARBITRATION_SCHEME
    )
    port map(
      clk                       => MCClk,
      clken                     => arb_clk_en,
      srst                      => srst,
      cmd_bank                  => arb_bank,
      cmd_request               => arb_request,
      cmd_burst_request         => arb_burst_request,
      cmd_granted               => arb_granted,
      cmd_granted_port_id       => arb_granted_port_id,
      cmd_grant                 => arb_grant,
      cmd_wr_op                 => arb_wr_op,
      wr_almost_full            => wrfifo_almost_full, -- only used in "DEFAULT" not in "ROUNDROBBIN"
      wr_flush                  => ZEROS(NUM_DATA_PORTS-1 downto 0), -- not used
      rd_almost_empty           => rdfifo_almost_empty -- only used in "DEFAULT" not in "ROUNDROBBIN"
    );
    
    UCmdBuf : entity work.vfbc_cmd_buffer
    generic map(
      VFBC_FAMILY => VFBC_FAMILY, 
      NUM_CMD_WORDS_PER_PORT    => NumWordsInCmd(ENABLE_RECT_ACCESS),
      NUM_DATA_PORTS            => NUM_DATA_PORTS,
      PORT_ENABLE               => WR_DATA_PORT_ENABLE(1) & RD_DATA_PORT_ENABLE(0),
      MEM_TYPE                  => "REGISTERS"
      --MEM_TYPE                  => DIST_RAMSTYLE
      --MEM_TYPE                  => BLOCK_RAMSTYLE
    )
    port map(
      srst                      => srst,
      clk                       => MCClk,
    
      newcmd_addr               => newcmd_addr,
      newcmd_data               => newcmd_data,
      newcmd_wr                 => newcmd_wr,
    
      cmd_rd_addr               => cbuf_rd_addr, 
    
      bc_wr_addr                => cbuf_wr_addr, -- From burst controller only the active address
      bc_wr_data                => cbuf_wr_data(32*NumWordsInCmd(ENABLE_RECT_ACCESS)-1 downto 0),
      bc_write                  => cbuf_wr,
            
      -- burst controller will read, then write 2 cycles later
      -- to same address
      --cbuf_rd_addr => cbuf_rd_addr,
      bc_rd_data                => cbuf_rd_data(32*NumWordsInCmd(ENABLE_RECT_ACCESS)-1 downto 0)
    );
    
    
  end generate GEN_MULTI_PORT;

  GEN_SINGLE_PORT : if NUM_DATA_PORTS < 1 generate
    U_CMD_CTRL : entity work.vfbc_cmd_control
    generic map(
      CMD_READ_DELAY => 1 
    )
    port map(
      clk                       => MCClk,
      srst                      => srst,

      -- Command FIFO Interface
      cmd_datain                => cmd_in_data(31 downto 0),
      cmd_empty                 => cmdfifo_empty(0),
      cmd_addr                  => cmd_in_addr(1 downto 0),
      cmd_dataout               => cbuf_rd_data(32*NumWordsInCmd(ENABLE_RECT_ACCESS)-1 downto 0),
      cmd_release               => cmd_in_gnt(0), --cmd_fifo_release(0),

      -- Data FIFO Interface
      rd_almost_full            => rdfifo_almost_full_dly(0),
      rd_full                   => '0',
      wd_almost_empty           => wrfifo_almost_empty_dly(0),
      wd_empty                  => wrfifo_empty(0), -- Needed?

      -- Burst Controller Interface
      cmd_done                  => bc_done,
      cmd_update                => cbuf_wr,
      cmd_burst_datain          => cbuf_wr_data(32*NumWordsInCmd(ENABLE_RECT_ACCESS)-1 downto 0),
      cmd_valid                 => bc_valid,

      --FIFO Status 
      bctrl_rafifo_almost_full  => bc_raf_almost_full,
      mem_init_done             => '1',  --need to connect
      mem_wrfifo_almost_full    => MCBusIn.WDF_almost_full,
      mem_rd_fifo_empty         => '0' --   need to connect
    );
   
    cbuf_rd_addr <= (others => '0'); 
  end generate GEN_SINGLE_PORT;

    UBurstCtrl : entity work.vfbc_burst_control
    generic map(
      ENABLE_BURST_CUT          => ENABLE_BURST_CUT, -- Enable Burst Cutting/merging
      NUM_CMD_WORDS_PER_PORT    => NumWordsInCmd(ENABLE_RECT_ACCESS),
      NUM_DATA_PORTS            => NUM_DATA_PORTS,
      READ_FIFO_DEPTH           => minimum_of_set(RD_DATA_FIFO_DEPTH, NUM_DATA_PORTS),
      DATA_WIDTH                => MC_DATA_WIDTH,
      DM_WIDTH                  => MC_DATA_WIDTH/8,
      BURST_SIZE                => BURST_SIZE*2/(32/MC_DATA_WIDTH), 
      MEM_BURST_SIZE            => BURST_SIZE*2, -- was (MEM_BURST_SIZE), MIG supports 4 or 8
      ADDRESS_PASSTHRU          => TRUE,
      BA_SIZE                   => BA_SIZE,
      BA_LOC                    => BA_LOC
    )
    port map(
      srst                      => srst,
      clk                       => MCClk,
    
      -- Command Buffer Interface
      cbuf_rd_data              => cbuf_rd_data(32*NumWordsInCmd(ENABLE_RECT_ACCESS)-1 downto 0),
      
      cbuf_wr_addr              => cbuf_wr_addr,
      cbuf_wr_data              => cbuf_wr_data(32*NumWordsInCmd(ENABLE_RECT_ACCESS)-1 downto 0),
      cmd_update                => cbuf_wr, -- To cmd buffer and command fetch
      
      -- Command Fetch Interface
      cmd_valid                 => bc_valid, -- New CMD is valid, operate on it
    
      cbuf_addr                 => cbuf_rd_addr, -- Port ID
      cmd_raf_almost_full       => bc_raf_almost_full,
            
      -- cmd_new_addr            => bc_update_addr, -- Update includes BA -- may not need as it is in the address of the
                                                                          -- cmd_data_out
      cmd_new_addr              => open,

      cmd_done                  => bc_done,
      remaining_x_count         => bc_update_xcount,
      
      -- WRITE FIFOs Interface
      wr_byte_mask              => wr_byte_mask, --Need Fixing from wrfifo_data_with_byteen : in
                                                 -- std_logic_vector(NUM_DATA_PORTS*DM_WIDTH*2-1 downto 0);
      wr_sel                    => wr_sel,  -- To Cons_M on each Writedata fifo - Pop Write Data
      wr_release                => wr_release,  -- To Cons_M on each Writedata fifo - Pop Write Data
      
      -- READ  FIFOs Interface 
      rd_sel                    => rd_sel,  -- To Cons_M on each readdata fifo -- Push Read data
      rd_commit                 => rd_commit, -- To Cons_M on each readdata fifo -- Push Read data
      rd_flush                  => rdfifo_reset_or_flush, 
      rd_byte_mask              => open,

      -- Memory Controller FIFO Interface
      -- Burst length is an apparently an output from MIG to 
      -- indicate the burst length 
      -- "010" = burst length of 4, "011" is burst length of 8
      mc_burst_length           => MCBusIn.burst_length,       -- : in std_logic_vector(2 downto 0); 
      
      mc_rd_data_valid          => MCBusIn.Read_data_valid, -- mc_rd_data_valid, -- : in std_logic;
      
      mc_af_addr                => memif_address,              -- : out std_logic_vector(35 downto 0); -- Dynamic CMD Req, CS,
                                                                                                       -- Bank, Row, Column
      mc_af_wren                => memif_add_wren,              -- : out std_logic;
      
      mc_wd_mask_data           => memif_data_mask,        -- : out std_logic_vector(DM_WIDTH*2-1 downto 0);
      mc_wd_wren                => memif_data_wren,             -- : out std_logic;
      
      write_swap                => write_swap,
      read_swap                 => read_swap
    
      --mc_error                  => MCBusIn.Error           -- : in std_logic -- ?? DON'T SEE this on the MIG interface VHDL, just
                                                                               -- in the docs
    );
    
    MCBusOut.App_Af_addr <= memif_address;
    MCBusOut.App_Af_wren <= memif_add_wren;
    
    
    
    ---------------------------------------------------------------------------
    --CJM 2007.01.15 delay two cycles for small burst and for timing
    ---------------------------------------------------------------------------
    process(MCClk)
    begin
      if rising_edge(MCClk) then
            memif_data_wren_dly  <= memif_data_wren;
            memif_data_wren_dly2 <= memif_data_wren_dly;
      end if;
    end process;
    MCBusOut.App_Mask_data(MC_DATA_WIDTH/4-1 downto 0) <= memif_data_mask; 
    MCBusOut.App_WDF_wren <= memif_data_wren_dly2;

end generate GEN_BURST_CUT;

------------------------------------------------------------------------------
-- Write Data FIFOs
------------------------------------------------------------------------------
GEN_WRDATA_FIFOS : for i in 0 to NUM_DATA_PORTS-1 generate

  GEN_WRDATA_PORT_ENABLE : if WR_DATA_PORT_ENABLE(i) = '1' generate
  
    --wrfifo_prod_m(2*i+1 downto 2*i) <= "11" when WrDataPortIn(i).MFlagCommit = '1' else (WrDataPortIn(i).MCmd(0) & '0');
    --wrfifo_cons_m(2*i+1 downto 2*i) <= '0' & wr_sel(i);
    wrfifo_prod_d(256*9/8*i+CalcBusWidth(WR_DATA_FIFO_WIDTH(i),WR_DATA_BYTEEN_ENABLE(i))-1 downto 256*9/8*i) <= 
        InterleaveByteEn(WrDataPortIn(i).MData(WR_DATA_FIFO_WIDTH(i)-1 downto
         0),WrDataPortIn(i).MDataByteEn(WR_DATA_FIFO_WIDTH(i)/8-1 downto 0),WR_DATA_BYTEEN_ENABLE(i));

    ------------------------------------------------------------------
    -- Write FIFO Reset and flush synchronization
    ------------------------------------------------------------------
    process(MCClk)
    begin
      if rising_edge(MCClk) then
        wrfifo_reset_dly1(i) <= WrDataPortIn(i).MReset_n;
        wrfifo_reset_dly2(i) <= wrfifo_reset_dly1(i);

        wrfifo_flush_dly1(i) <= WrDataPortIn(i).MFlagFlush;
        wrfifo_flush_dly2(i) <= wrfifo_flush_dly1(i);

        wrfifo_reset(i)          <= srst or not wrfifo_reset_dly2(i);
        wrfifo_reset_or_flush(i) <= srst or (not wrfifo_reset_dly2(i)) or wrfifo_flush_dly2(i);
      end if;
    end process;
    ------------------------------------------------------------------


    UWrDataFifo: entity work.ObjFifoAsyncDiffW
      generic map(
        FAMILY          => VFBC_FAMILY, 
        DATA_BITS_PROD  => CalcBusWidth(WR_DATA_FIFO_WIDTH(i),WR_DATA_BYTEEN_ENABLE(i)),
        DATA_BITS_CONS  => CalcBusWidth(MC_DATA_WIDTH*2,WR_DATA_BYTEEN_ENABLE(i)),
        NO_OBJS         => maximum(8,WR_DATA_FIFO_DEPTH(i)),
        --OBJ_SIZE_PROD   => WR_DATA_FIFO_OBJ_SIZE(i),
        --OBJ_SIZE_CONS   => WR_DATA_FIFO_OBJ_SIZE(i)*WR_DATA_FIFO_WIDTH(i)/(MC_DATA_WIDTH*2),
        OBJ_SIZE_PROD   => (BURST_SIZE*MC_DATA_WIDTH*2)/WR_DATA_FIFO_WIDTH(i),
        OBJ_SIZE_CONS   => BURST_SIZE,
        AFULL_COUNT     => WR_DATA_AFULL_COUNT(i),
        AEMPTY_COUNT    => 2,
        AUTO_PRODUCER   => StdLogic2Boolean(WR_DATA_SIMPLE_FIFO(i)),
        AUTO_CONSUMER   => TRUE,
        ASYNC_CLOCK     => StdLogic2Boolean(WR_DATA_FIFO_ASYNC_CLOCK(i))
      )
      port map(
        sclr            => wrfifo_reset_or_flush(i),
        Prod_Clk        => WrDataPortIn(i).Clk,
        Cons_Clk        => MCClk,
        Prod_Full       => wrfifo_client_full(i), --WrDataPortOut(i).SFlagFull,
        Prod_AlmostFull => wrfifo_client_almost_full(i), --WrDataPortOut(i).SFlagAlmostFull,
        Prod_NumObjAvail=> WrDataPortOut(i).SFlagNumOfObjAvail(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0),
        Prod_Write      => WrDataPortIn(i).MCmd(0), 
        Prod_Read       => '0',
        Prod_Commit     => WrDataPortIn(i).MFlagCommit,
        --Prod_A          => WrDataPortIn(i).MAddr(logbase2(WR_DATA_FIFO_OBJ_SIZE(i)-1)-1 downto 0),
        Prod_A          => WrDataPortIn(i).MAddr(logbase2(((BURST_SIZE*MC_DATA_WIDTH*2)/WR_DATA_FIFO_WIDTH(i))-1)-1 downto 0),
        Prod_D          => wrfifo_prod_d(256*9/8*i+CalcBusWidth(WR_DATA_FIFO_WIDTH(i),WR_DATA_BYTEEN_ENABLE(i))-1 downto
         256*9/8*i),
        Prod_Q          => open,
        Cons_Empty      => wrfifo_empty(i),
        Cons_AlmostEmpty=> wrfifo_almost_empty(i),
        Cons_Write      => '0',
        Cons_Read       => wr_sel(i),
        Cons_Release    => wr_release(i), -- Need to generate release internally
        --Cons_A          => ZEROS(logbase2(WR_DATA_FIFO_OBJ_SIZE(i)*WR_DATA_FIFO_WIDTH(i)/(MC_DATA_WIDTH*2)-1)-1 downto 0),
        Cons_A          => ZEROS(logbase2(BURST_SIZE-1)-1 downto 0),
        Cons_D          => ZEROS(CalcBusWidth(MC_DATA_WIDTH*2,WR_DATA_BYTEEN_ENABLE(i))-1 downto 0),
        Cons_Q          => wrfifo_data_with_byteen(MC_DATA_WIDTH*9/8*2*i+CalcBusWidth(MC_DATA_WIDTH*2,WR_DATA_BYTEEN_ENABLE(i))-1
         downto MC_DATA_WIDTH*9/8*2*i),
        Cons_NumObjFilled=> wrfifo_num_of_buf_filled(i)(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0)
      );
  
  end generate GEN_WRDATA_PORT_ENABLE;
  
  GEM_WRDATA_PORT_DISABLE : if WR_DATA_PORT_ENABLE(i) = '0' generate
    wrfifo_reset(i) <= '1';
    wrfifo_client_full(i) <= '1';
    wrfifo_client_almost_full(i) <= '1';
    WrDataPortOut(i).SFlagNumOfObjAvail(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0) <= (others => '0');
  
    wrfifo_num_of_buf_filled(i)(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0) <= (others => '1');
    wrfifo_empty(i) <= '1';
    wrfifo_almost_empty(i) <= '1';
    wrfifo_data_with_byteen(MC_DATA_WIDTH*9/8*2*i+CalcBusWidth(MC_DATA_WIDTH*2,WR_DATA_BYTEEN_ENABLE(i))-1 downto
     MC_DATA_WIDTH*9/8*2*i) <= (others => '0');
  end generate GEM_WRDATA_PORT_DISABLE;
  
  WrDataPortOut(i).SFlagFull <= wrfifo_client_full(i);
  WrDataPortOut(i).SFlagAlmostFull <= wrfifo_client_almost_full(i);
  --wrfifo_almost_full(i) <= '1' when (wrfifo_num_of_buf_filled(i)(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0) >
  -- (3*WR_DATA_FIFO_OBJ_SIZE(i)*WR_DATA_FIFO_WIDTH(i)/(MC_DATA_WIDTH*2)/4)) else '0';
  --wrfifo_almost_empty(i) <= '1' when (wrfifo_num_of_buf_filled(i)(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0) < 2) else '0';
 
  --wrfifo_empty(i) <= '1' when (wrfifo_num_of_buf_filled(i)(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0) < 2) else '0';


   ------------------------------------------------------------------------------
   -- Write FIFO almost empty and almost full
   ------------------------------------------------------------------------------
  --wrfifo_almost_full(i) <= '1' wPertussis hen (wrfifo_num_of_buf_filled(i)(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0) >
  -- (3*WR_DATA_FIFO_DEPTH(i)/4) - 1) else '0';
    process(MCClk)
    begin
      if rising_edge(MCClk) then
        wrfifo_almost_empty_dly(i) <= wrfifo_almost_empty(i);
        if (wrfifo_num_of_buf_filled(i)(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0) > (3*WR_DATA_FIFO_DEPTH(i)/4) - 2) then
          wrfifo_almost_full(i) <= '1'; 
        else
          wrfifo_almost_full(i) <= '0';
        end if;
      end if;
    end process;


  wrfifo_data(MC_DATA_WIDTH*2*(i+1)-1 downto MC_DATA_WIDTH*2*i) <=
    ExtractData(wrfifo_data_with_byteen(       MC_DATA_WIDTH*2*i*9/8+CalcBusWidth(MC_DATA_WIDTH*2, WR_DATA_BYTEEN_ENABLE(i))-1 
                                        downto MC_DATA_WIDTH*2*i*9/8), WR_DATA_BYTEEN_ENABLE(i));
  wr_byte_mask(MC_DATA_WIDTH/4*(i+1)-1 downto MC_DATA_WIDTH/4*i) <= 
    not ExtractByteEn(wrfifo_data_with_byteen(MC_DATA_WIDTH*2*i*9/8+CalcBusWidth(MC_DATA_WIDTH*2, WR_DATA_BYTEEN_ENABLE(i))-1 
                                              downto MC_DATA_WIDTH*2*i*9/8)) 
                                      when WR_DATA_BYTEEN_ENABLE(i) = '1' else (others => '0'); -- CJM Others was '1'

end generate GEN_WRDATA_FIFOS;

------------------------------------------------------------------------------
-- Read Data FIFOs
------------------------------------------------------------------------------
--rd_active_afull <= rd_sel and rdfifo_almost_full;
process(MCClk)
begin
  if rising_edge(MCClk) then
    rdfifo_almost_full_dly <= rdfifo_almost_full;
  end if;
end process;  
rd_active_afull <= rdfifo_almost_full_dly;

GEN_RDDATA_FIFOS : for i in 0 to NUM_DATA_PORTS-1 generate

  GEN_RDDATA_PORT_ENABLE : if RD_DATA_PORT_ENABLE(i) = '1' generate

    ------------------------------------------------------------------
    -- Read FIFO Reset and flush synchronization
    ------------------------------------------------------------------
    process(MCClk)
    begin
      if rising_edge(MCClk) then
        rdfifo_reset_dly1(i) <= RdDataPortIn(i).MReset_n;
        rdfifo_reset_dly2(i) <= rdfifo_reset_dly1(i);

        rdfifo_flush_dly1(i) <= RdDataPortIn(i).MFlagFlush;
        rdfifo_flush_dly2(i) <= rdfifo_flush_dly1(i);

        rdfifo_reset(i)          <= srst or not rdfifo_reset_dly2(i);
        rdfifo_reset_or_flush(i) <= srst or (not rdfifo_reset_dly2(i)) or rdfifo_flush_dly2(i);
      end if;
    end process;
    ------------------------------------------------------------------
  
  URdDataFifo : entity work.ObjFifoAsyncDiffW
    generic map(
      FAMILY            => VFBC_FAMILY, 
      DATA_BITS_PROD    => MC_DATA_WIDTH*2,
      DATA_BITS_CONS    => RD_DATA_FIFO_WIDTH(i),
      NO_OBJS           => maximum(8,RD_DATA_FIFO_DEPTH(i)),
      --OBJ_SIZE_PROD     => RD_DATA_FIFO_OBJ_SIZE(i)*RD_DATA_FIFO_WIDTH(i)/(MC_DATA_WIDTH*2),
      --OBJ_SIZE_CONS     => RD_DATA_FIFO_OBJ_SIZE(i),
      OBJ_SIZE_PROD     => BURST_SIZE,
      OBJ_SIZE_CONS     => (BURST_SIZE*MC_DATA_WIDTH*2)/RD_DATA_FIFO_WIDTH(i),
      AEMPTY_COUNT      => RD_DATA_AEMPTY_COUNT(i),
      AFULL_COUNT       => 6,
      AUTO_PRODUCER     => TRUE,
      AUTO_CONSUMER     => StdLogic2Boolean(RD_DATA_SIMPLE_FIFO(i)),
      ASYNC_CLOCK       => StdLogic2Boolean(RD_DATA_FIFO_ASYNC_CLOCK(i))
    )
    port map(
      sclr              => rdfifo_reset_or_flush(i),
      Prod_Clk          => MCClk,
      Cons_Clk          => RdDataPortIn(i).Clk,
      Prod_Write        => rd_sel(i),
      Prod_Read         => '0',
      Prod_Commit       => rd_commit(i), -- Need to update/generate the commit internally
      --Prod_A            => ZEROS(logbase2(RD_DATA_FIFO_OBJ_SIZE(i)*RD_DATA_FIFO_WIDTH(i)/(MC_DATA_WIDTH*2)-1)-1 downto 0),
      Prod_A            => ZEROS(logbase2(BURST_SIZE-1)-1 downto 0),
      Prod_D            => memif_data_in,
      Prod_NumObjAvail  => rdfifo_num_of_buf_avail(i)(logbase2(RD_DATA_FIFO_DEPTH(i)-1) downto 0),
      Prod_AlmostFull   => rdfifo_almost_full(i),
      Prod_Full         => open,
      Prod_Q            => open,
      Cons_Empty        => rdfifo_empty(i),
      Cons_AlmostEmpty  => rdfifo_almost_empty_client(i),
      Cons_NumObjFilled => RdDataPortOut(i).SFlagNumOfObjFilled(logbase2(RD_DATA_FIFO_DEPTH(i)-1) downto 0),
      Cons_Write        => '0',
      Cons_Read         => RdDataPortIn(i).MCmd(1),
      Cons_Release      => RdDataPortIn(i).MFlagCommit,
      --Cons_A            => RdDataPortIn(i).MAddr(logbase2(RD_DATA_FIFO_OBJ_SIZE(i)-1)-1 downto 0),
      Cons_A            => RdDataPortIn(i).MAddr(logbase2(((BURST_SIZE*MC_DATA_WIDTH*2)/RD_DATA_FIFO_WIDTH(i))-1)-1 downto 0),
      Cons_D            => ZEROS(RD_DATA_FIFO_WIDTH(i)-1 downto 0),
      Cons_Q            => rdfifo_read_data(i)(RD_DATA_FIFO_WIDTH(i)-1 downto 0)
    );
  
  end generate GEN_RDDATA_PORT_ENABLE;
  
  GEN_RDDATA_PORT_DISABLE : if RD_DATA_PORT_ENABLE(i) = '0' generate
    rdfifo_reset(i) <= '1';
    rdfifo_num_of_buf_avail(i)(logbase2(RD_DATA_FIFO_DEPTH(i)-1) downto 0) <= (others => '1');
    rdfifo_almost_full(i) <= '0';
  
    RdDataPortOut(i).SFlagNumOfObjFilled(logbase2(RD_DATA_FIFO_DEPTH(i)-1) downto 0) <= (others => '0');
  
    rdfifo_empty(i) <= '1';
    rdfifo_almost_empty_client(i) <= '1';

    --RdDataPortOut(i).SData <= (others => '0');
    --RdDataPortOut(i).SData(RD_DATA_FIFO_WIDTH(i)-1 downto 0) <= (others => '0');
    rdfifo_read_data(i)(RD_DATA_FIFO_WIDTH(i)-1 downto 0) <= (others => '0');
  end generate GEN_RDDATA_PORT_DISABLE;

--rdfifo_almost_empty(i) <= '1' when (rdfifo_num_of_buf_avail(i)(logbase2(WR_DATA_FIFO_DEPTH(i)-1) downto 0) >
-- (3*WR_DATA_FIFO_OBJ_SIZE(i)*WR_DATA_FIFO_WIDTH(i)/(MC_DATA_WIDTH*2)/4)) else '0';
--rdfifo_almost_empty(i) <= '1' when (rdfifo_num_of_buf_avail(i)(logbase2(RD_DATA_FIFO_DEPTH(i)-1) downto 0) >
-- (3*RD_DATA_FIFO_DEPTH(i)/4) - 1) else '0';
    process(MCClk)
    begin
      if rising_edge(MCClk) then
        if(rdfifo_num_of_buf_avail(i)(logbase2(RD_DATA_FIFO_DEPTH(i)-1) downto 0) > (3*RD_DATA_FIFO_DEPTH(i)/4) - 2) then
          rdfifo_almost_empty(i) <= '1';
        else
          rdfifo_almost_empty(i) <= '0';
        end if;
      end if;
    end process;



--rdfifo_almost_full(i) <= '1' when (rdfifo_num_of_buf_avail(i)(logbase2(RD_DATA_FIFO_DEPTH(i)-1) downto 0) < 2) else '0';
    RdDataPortOut(i).SFlagEmpty         <= rdfifo_empty(i);
    RdDataPortOut(i).SFlagAlmostEmpty   <= rdfifo_almost_empty_client(i);
    RdDataPortOut(i).SData(RD_DATA_FIFO_WIDTH(i)-1 downto 0) <= rdfifo_read_data(i)(RD_DATA_FIFO_WIDTH(i)-1 downto 0);
end generate GEN_RDDATA_FIFOS;  

-------------------------------------------------------------------------------
-- Memory Interface
-------------------------------------------------------------------------------

-- wr_sel_dly
-- memif_data_out
process(MCClk)
variable AndOrResult : std_logic_vector(MC_DATA_WIDTH*2-1 downto 0);
begin
if rising_edge(MCClk) then
  wr_sel_dly <= wr_sel;
  --wr_sel_dly2 <= wr_sel_dly;
  AndOrResult := (others => '0');
  for i in 0 to NUM_DATA_PORTS-1 loop
    --if wr_sel_dly2(i) = '1' then
    if wr_sel_dly(i) = '1' then
      AndOrResult := AndOrResult or wrfifo_data(MC_DATA_WIDTH*2*(i+1)-1 downto MC_DATA_WIDTH*2*i);
    end if;
  end loop;
  memif_data_out(MC_DATA_WIDTH*2-1 downto 0) <= AndOrResult;
end if;
end process;


--CJM 2007.01.15
process(MCClk)
begin
  if rising_edge(MCClk) then
        last_memif_data_out <= memif_data_out(MC_DATA_WIDTH*2-1 downto MC_DATA_WIDTH);

        if(write_swap = '0') then
          memif_data_out_dly(MC_DATA_WIDTH*2-1 downto 0) <= memif_data_out;
        else
          memif_data_out_dly(MC_DATA_WIDTH-1 downto 0)               <= last_memif_data_out;
          memif_data_out_dly(MC_DATA_WIDTH*2-1 downto MC_DATA_WIDTH) <= memif_data_out(MC_DATA_WIDTH-1 downto 0);
        end if;
  end if;
end process;
MCBusOut.App_WDF_data(MC_DATA_WIDTH*2-1 downto 0) <= memif_data_out_dly;




process(MCClk)
begin
  if rising_edge(MCClk) then

    memif_data_in_dly(0)(MC_DATA_WIDTH*2-1 downto 0) <= MCBusIn.Read_data_fifo_out(MC_DATA_WIDTH*2-1 downto 0);
    memif_data_in_dly(memif_data_in_dly'high downto 1) <= memif_data_in_dly(memif_data_in_dly'high-1 downto 0);

  end if;
end process;

memif_data_in <=      memif_data_in_dly(memif_data_in_dly'high)(MC_DATA_WIDTH*2-1 downto 0) when(read_swap = '0') 
                 else   memif_data_in_dly(memif_data_in_dly'high-1)(MC_DATA_WIDTH-1 downto 0)           --Previous T-1 lower ->
                                                                                                        -- upper
                      & memif_data_in_dly(memif_data_in_dly'high)(MC_DATA_WIDTH*2-1 downto MC_DATA_WIDTH); --Current  T0  upper ->
                                                                                                           -- lower


-------------------------------------------------------------------------------
-- Enable Host Interface
-------------------------------------------------------------------------------
GEN_HIF: if(ENABLE_HIF) generate
  -- Read, CMD, Write-FIFO, Read-FIFO
  process(MCClk) 
  begin
    if rising_edge(MCClk) then
      if(srst = '1') then
        HifDataOut <= (others => '1');
      else
        HifDataOut <= (others => '1');
        -- HifAddress 0
        if(HifAddress = conv_std_logic_vector(0, HifAddress'length)) then
          HifDataOut <= X"a6" & ZEROS(23 downto cmd_in_addr'length) & cmd_in_addr; 
        end if;
        -- HifAddress 1
        if(HifAddress = conv_std_logic_vector(1, HifAddress'length)) then
          HifDataOut <= ZEROS(31 downto cmdfifo_empty'length) & cmdfifo_empty; 
        end if;
        -- HifAddress 2+NUM_CMD_PORTS
          if(HifAddress = conv_std_logic_vector(2, HifAddress'length)) then
            HifDataOut <= ZEROS(31 downto wrfifo_almost_empty'length) & wrfifo_almost_empty; 
          end if;
          if(HifAddress = conv_std_logic_vector(3, HifAddress'length)) then
            HifDataOut <=  ZEROS(15 downto wr_sel'length) & wr_sel 
                         & ZEROS(15 downto wr_sel_probe'length) & wr_sel_probe; 
          end if;
          if(HifAddress = conv_std_logic_vector(4, HifAddress'length)) then
            HifDataOut <=  ZEROS(15 downto wr_release'length) & wr_release 
                         & ZEROS(15 downto wr_release_probe'length) & wr_release_probe; 
          end if;
          if(HifAddress = conv_std_logic_vector(5, HifAddress'length)) then
            HifDataOut <= wr_data_probe(31 downto 0);
          end if;
          
          if(HifAddress = conv_std_logic_vector(6, HifAddress'length)) then
            HifDataOut <= ZEROS(31 downto rdfifo_almost_empty'length) & rdfifo_almost_empty;
          end if;
          if(HifAddress = conv_std_logic_vector(7, HifAddress'length)) then
            HifDataOut <=   ZEROS(15 downto rd_sel'length) & rd_sel
                          & ZEROS(15 downto rd_sel_probe'length) & rd_sel_probe;
          end if;
          if(HifAddress = conv_std_logic_vector(8, HifAddress'length)) then
            HifDataOut <=  ZEROS(15 downto rd_commit'length) & rd_commit
                         & ZEROS(15 downto rd_commit_probe'length) & rd_commit_probe;
          end if;
          if(HifAddress = conv_std_logic_vector(9, HifAddress'length)) then
            HifDataOut <= rd_data_probe(31 downto 0);
          end if;
        if(HifAddress = conv_std_logic_vector(10, HifAddress'length)) then
          HifDataOut <= ZEROS(31 downto 4) & add_probe(35 downto 32);
        end if;
        if(HifAddress = conv_std_logic_vector(11, HifAddress'length)) then
          HifDataOut <= add_probe(31 downto 0);
        end if;
        if(HifAddress = conv_std_logic_vector(12, HifAddress'length)) then
          --HifDataOut <= ZEROS(31 downto MCBusIn.burst_length'length) & MCBusIn.burst_length;
          HifDataOut <= wrfifo0_data_probe;
        end if;
        if(HifAddress = conv_std_logic_vector(13, HifAddress'length)) then
          HifDataOut <= ZEROS(15 downto 5) 
                        & memif_data_wren
                        & memif_add_wren
                        & MCBusIn.WDF_almost_full
                        & MCBusIn.AF_Almost_full
                        & MCBusIn.Read_data_valid
                        & ZEROS(15 downto 8) 
                        & WrDataPortIn(0).MFlagCommit
                        & wr_commit0_probe
                        & wrfifo0_probe
                        & data_wren_probe
                        & add_wren_probe
                        & d_afull_probe
                        & a_afull_probe
                        & rd_data_valid_probe;
        end if;
        if(HifAddress = conv_std_logic_vector(14, HifAddress'length)) then
        --  HifDataOut <= x"000" & '0' & RdDataPortOut(0).SFlagNumOfObjFilled(2 downto 0) & x"000" & '0' &
        -- wrfifo_num_of_buf_filled(0)(2 downto 0);
          HifDataOut <= x"0000" & x"000" & '0' & wrfifo_num_of_buf_filled(0)(2 downto 0);
        end if;

        -- HifAddress 2 - (2+NUM_CMD_PORTS-1)
        for i in 0 to NUM_CMD_PORTS-1 loop 
          for j in 0 to 3 loop 
            if(HifAddress = conv_std_logic_vector(16 + 4*i + j, HifAddress'length)) then
              --HifDataOut <= cmd_in_data(32*i+31 downto 32*i);
              HifDataOut <= cmd_probe(32*(4*i+j)+31 downto 32*(4*i+j));
            end if;
          end loop;
        end loop;
      end if;
    end if;
  end process;


  process(MCClk) 
  begin
    if rising_edge(MCClk) then
      if(srst = '1') then
        wr_release_probe        <= (others => '0');
        wr_sel_probe            <= (others => '0');
        rd_sel_probe            <= (others => '0');
        rd_commit_probe         <= (others => '0');
        rd_data_probe           <= (others => '0');
        rd_data_valid_probe     <= '0';

        wr_data_probe           <= (others => '0');
        add_probe               <= (others => '0');
        data_wren_probe         <= '0';
        add_wren_probe          <= '0';
        d_afull_probe           <= '0';
        a_afull_probe           <= '0';

        cmd_probe               <= (others => '0');

        wr_commit0_probe        <= '0';

      else
        if(wr_sel /= 0) then
          wr_sel_probe <= rd_sel;
        end if;
        if(wr_release /= 0) then
          wr_release_probe <= wr_release;
        end if;

        if(rd_sel /= 0) then
          rd_sel_probe <= rd_sel;
        end if;
        if(rd_commit /= 0) then
          rd_commit_probe <= rd_commit;
        end if;
        if(MCBusIn.WDF_almost_full /= '0') then
          d_afull_probe <= '1';
        end if;
        if(MCBusIn.AF_Almost_full /= '0') then
          a_afull_probe <= '1';
        end if;
        if(memif_data_wren /= '0') then
          data_wren_probe <= '1';
          wr_data_probe   <= memif_data_out;
        end if;
        if(memif_add_wren /= '0') then
          add_wren_probe <= '1';
          add_probe   <= memif_address;
        end if;


        if(WrDataPortIn(0).MCmd(0) /= '0') then
          wrfifo0_probe <= '1';
          wrfifo0_data_probe   <= ZEROS(31 downto minimum(32,CalcBusWidth(WR_DATA_FIFO_WIDTH(0),WR_DATA_BYTEEN_ENABLE(0)))) 
                                  & wrfifo_prod_d(minimum(32,CalcBusWidth(WR_DATA_FIFO_WIDTH(0),WR_DATA_BYTEEN_ENABLE(0)))-1 downto
                                   0);
        end if;

        if(MCBusIn.Read_data_valid /= '0') then
          rd_data_valid_probe <= '1';
          rd_data_probe <= memif_data_in;
        end if;

        if(WrDataPortIn(0).MFlagCommit /= '0') then
          wr_commit0_probe <= '1';
        end if;
       
--        for i in 0 to NUM_CMD_PORTS-1 loop 
--          for j in 0 to 3 loop 
--            if(cmd_in_addr = j) then
--              cmd_probe(32*(4*i+j)+31 downto 32*(4*i+j)) <= cmd_in_data(32*i+31 downto 32*i);
--            end if;
--          end loop;
--        end loop;

        for i in 0 to NUM_CMD_PORTS-1 loop 
          for j in 0 to 3 loop 
            if ((newcmd_wr = '1') and (newcmd_addr = (4*i+j))) then
              cmd_probe(32*(4*i+j)+31 downto 32*(4*i+j)) <= newcmd_data;
            end if;
          end loop;
        end loop;

      end if;
    end if;    
  end process;


end generate GEN_HIF;

-------------------------------------------------------------------------------
-- Disable Host Interface
-------------------------------------------------------------------------------
  GEN_NO_HIF: if(not ENABLE_HIF) generate
    HifDataOut <= (others => '0');
  end generate GEN_NO_HIF;
-------------------------------------------------------------------------------


end rtl;

