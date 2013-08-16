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
-- Description - VFBC PIM Wrapper
--               Wraps the VFBC PIM providing a minimal set of 
--               parameters for easy integration/instantiation from
--               verilog.
--******************************************************************


library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.all;

entity vfbc_pim_wrapper is
  generic
  (
    C_MPMC_BASEADDR             : integer       := 0;                   -- MPMC XPS Base Address 
    C_MPMC_HIGHADDR             : integer       := 0;                   -- MPMC XPS High Address
    C_PIM_DATA_WIDTH            : integer       := 64;                  -- NPI Data width
    C_CHIPSCOPE_ENABLE          : integer       := 1;                   -- Enable chipscope core instance
    C_FAMILY                    : string        := "spartan3adsp";      -- Device Family


    VFBC_BURST_LENGTH           : integer       := 8;                   -- NPI Burst Length.  Set to 32 above.
  -- Command Interface 0 PARAMETERS             
    CMD0_PORT_ID                : integer := 0;                         -- ID of Command Port.  Locked to 0
    CMD0_FIFO_DEPTH             : integer := 8;                         -- Command FIFO Depth in number of 4-word objects
    CMD0_ASYNC_CLOCK            : integer := 1;                         -- 1: enable synchronization logic.  2: disable
                                                                        -- synchronizers
    CMD0_AFULL_COUNT            : integer := 1;                         -- Command FIFO Number of empty slots in FIFO to assert
                                                                        -- Afull

  -- Write Data Interface 0 PARAMETERS
    WD0_ENABLE                  : integer := 1;                         -- 1: enable Write Side. 0: disable Write Side logic.
    WD0_DATA_WIDTH              : integer := 32;                        -- Write FIFO Data Width: 8,16,32,64 only
    WD0_FIFO_DEPTH              : integer := 8;                         -- Write FIFO Data Depth in number of data elements
    WD0_ASYNC_CLOCK             : integer := 1;                         -- 1: enable synchronization logic.  2: disable
                                                                        -- synchronizers
    WD0_AFULL_COUNT             : integer := 1;                         -- Write FIFO Number of empty slots in FIFO to assert Afull
    WD0_BYTEEN_ENABLE           : integer := 0;                         -- Write FIFO Byte Enables

  -- Read Data Interface 0 PARAMETERS
    RD0_ENABLE                  : integer := 1;                         -- 1: enable Read  Side. 0: disable Read  Side logic.
    RD0_DATA_WIDTH              : integer := 32;                        -- Read FIFO Data Width: 8,16,32,64 only
    RD0_FIFO_DEPTH              : integer := 8;                         -- Read FIFO Data Depth in number of data elements
    RD0_ASYNC_CLOCK             : integer := 1;                         -- 1: enable synchronization logic.  2: disable
                                                                        -- synchronizers
    RD0_AEMPTY_COUNT            : integer := 1                          -- Read FIFO Number of filled slots in FIFO to assert
                                                                        -- Aempty

  );
  port
  (
    vfbc_clk            : in std_logic;                                 -- Memory Side Clock.  Same as MPMC_Clk0
    srst                : in std_logic;                                 -- Synchronous Reset.  Active high
   
   
    -- Command Interfaces
    cmd0_clk            : in  std_logic;                                -- Command FIFO Clock Input
    cmd0_reset          : in  std_logic;                                -- Command FIFO Reset Input.  Active High
    cmd0_data           : in  std_logic_vector(31 downto 0);            -- Command FIFO Data Input
    cmd0_write          : in  std_logic;                                -- Command FIFO Write Enable Input
    cmd0_end            : in  std_logic;                                -- Command FIFO End Cmd Input.  Terminates current cmd
                                                                        -- write
    cmd0_full           : out std_logic;                                -- Command FIFO Full Flag
    cmd0_almost_full    : out std_logic;                                -- Command FIFO Almost Full Flag.  Active High
    cmd0_idle           : out std_logic;                                -- Command FIFO idle.  High when no transfer is active
    
    -- Write Fifo Interfaces 
    wd0_clk             : in  std_logic;                                -- Write FIFO Clock Input
    wd0_reset           : in  std_logic;                                -- Write FIFO Reset Input. Active High
    wd0_write           : in  std_logic;                                -- Write FIFO Write Enable Input.  Active High
    wd0_end_burst       : in  std_logic;                                -- Write FIFO End Burst Input. Terminates current burst
                                                                        -- when 1
    wd0_flush           : in  std_logic;                                -- Write FIFO Flush.  Active High
    wd0_data            : in  std_logic_vector(WD0_DATA_WIDTH-1 downto 0); -- Write FIFO Data Input
    wd0_data_be         : in  std_logic_vector((WD0_DATA_WIDTH/8)-1 downto 0);  -- Write FIFO Data Byte Enables Input
    wd0_full            : out std_logic;                                -- Write FIFO Full Flag
    wd0_almost_full     : out std_logic;                                -- Write FIFO Almost Full Flag.  Active High
    
    -- Read Fifo Interfaces
    rd0_clk             : in  std_logic;                                -- Read FIFO Clock Input
    rd0_reset           : in  std_logic;                                -- Read FIFO Reset Input. Active High
    rd0_read            : in  std_logic;                                -- Read FIFO Read Enable Input.  Active High
    rd0_end_burst       : in  std_logic;                                -- Read FIFO End Burst Input. Terminates current burst when
                                                                        -- 1
    rd0_flush           : in  std_logic;                                -- Read FIFO Flush Input.  Active High
    rd0_data            : out std_logic_vector(RD0_DATA_WIDTH-1 downto 0); -- Read FIFO Data Input
    rd0_empty           : out std_logic;                                -- Read FIFO Empty Flag
    rd0_almost_empty    : out std_logic;                                -- Read FIFO Almost Empty Flag. Active High
   
    -- MPMC Native Port Interface (NPI)
    npi_init_done       : in  std_logic;                                -- NPI Mem Initialization Complete when High
    npi_addr_ack        : in  std_logic;                                -- NPI Address Acknowledge.  Active High
    npi_rdfifo_word_add : in  std_logic_vector(3 downto 0);             -- NPI Read FIFO Word Address. Not used
    npi_rdfifo_data     : in  std_logic_vector(C_PIM_DATA_WIDTH-1 downto 0); -- NPI Read FIFO Data
    npi_rdfifo_latency  : in  std_logic_vector(1 downto 0);             -- NPI Read FIFO Latency. 0, 1 or 2 cycles
    npi_rdfifo_empty    : in  std_logic;                                -- NPI Read FIFO empty Flag
    npi_wrfifo_almost_full : in std_logic;                              -- NPI Write FIFO Almost Full Flag
    npi_address         : out std_logic_vector(31 downto 0);            -- NPI Address
    npi_addr_req        : out std_logic;                                -- NPI Address Request. Active High
    npi_size            : out std_logic_vector(3 downto 0);             -- NPI Transfer size.  Always set to 32-word burst
    npi_rnw             : out std_logic;                                -- NPI Read/Not-Write 
    npi_rdfifo_pop      : out std_logic;                                -- NPI Read FIFO Pop.  Pop Data Element from FIFO when high
    npi_rdfifo_flush    : out std_logic;                                -- NPI Read FIFO Flush.  Active High
    npi_wrfifo_data     : out std_logic_vector(C_PIM_DATA_WIDTH-1 downto 0); -- NPI Write FIFO Data
    npi_wrfifo_be       : out std_logic_vector((C_PIM_DATA_WIDTH/8)-1 downto 0); -- NPI Write FIFO Data Byte Enables
    npi_wrfifo_push     : out std_logic;                                -- NPI Write FIFO PUSH. Push Data Element onto FIFO when
                                                                        -- high
    npi_wrfifo_flush    : out std_logic                                 -- NPI Write FIFO Flush.  Active High
   
  );
end entity vfbc_pim_wrapper;


architecture IMP of vfbc_pim_wrapper is
function Integer2Boolean(A : integer) return boolean is
begin
  if A = 1 then 
    return TRUE; 
  else 
    return FALSE; 
  end if;
end;

function familyConv(A : string) return string is
begin
  if A = "virtex5" then 
    return "V5"; 
  elsif A = "virtex4" then
    return "V4"; 
  elsif A = "spartan3adsp" then
    return "S3"; 
  else 
    return "S3"; 
  end if;
end;

constant ZEROS  : std_logic_vector(31 downto 0) := (others => '0');
constant mpmc_baseaddr : std_logic_vector(31 downto 0) := conv_std_logic_vector(C_MPMC_BASEADDR, 32);

signal wd0_full_int          : std_logic;
signal wd0_almost_full_int  : std_logic; 
signal cmd0_full_int        : std_logic;
signal cmd0_almost_full_int  : std_logic;
signal cmd0_idle_int        : std_logic; 

signal npi_address_int     : std_logic_vector(31 downto 0);

begin


VFBC1_PIM_NGC : entity work.vfbc1_pim
generic map(
    VFBC_FAMILY                 => familyConv(C_FAMILY),
    VFBC_NPI_WIDTH              => C_PIM_DATA_WIDTH,
    ENABLE_CHIPSCOPE            => Integer2Boolean(C_CHIPSCOPE_ENABLE),
    VFBC_BURST_LENGTH           => VFBC_BURST_LENGTH,

  -- Command Interface 0 PARAMETERS
    CMD0_PORT_ID                => CMD0_PORT_ID,
    CMD0_FIFO_DEPTH             => CMD0_FIFO_DEPTH,
    CMD0_ASYNC_CLOCK            => Integer2Boolean(CMD0_ASYNC_CLOCK),
    CMD0_AFULL_COUNT            => CMD0_AFULL_COUNT,

  -- Write Data Interface 0 PARAMETERS
    WD0_ENABLE                  => Integer2Boolean(WD0_ENABLE),
    WD0_DATA_WIDTH              => WD0_DATA_WIDTH,
    WD0_FIFO_DEPTH              => WD0_FIFO_DEPTH,
    WD0_ASYNC_CLOCK             => Integer2Boolean(WD0_ASYNC_CLOCK),
    WD0_AFULL_COUNT             => WD0_AFULL_COUNT,
    WD0_BYTEEN_ENABLE           => Integer2Boolean(WD0_BYTEEN_ENABLE),

  -- Read Data Interface 0 PARAMETERS
    RD0_ENABLE                  => Integer2Boolean(RD0_ENABLE),
    RD0_DATA_WIDTH              => RD0_DATA_WIDTH,
    RD0_FIFO_DEPTH              => RD0_FIFO_DEPTH,
    RD0_ASYNC_CLOCK             => Integer2Boolean(RD0_ASYNC_CLOCK),
    RD0_AEMPTY_COUNT            => RD0_AEMPTY_COUNT

)
port map
(
    clk                 => vfbc_clk,
    srst                => srst,
   
    -- Host Interface
    hif_address         => ZEROS(7 downto 0),
    hif_datain          => ZEROS(31 downto 0),
    hif_write           => '0',
    hif_dataout         => open,
   
    -- Command Interfaces
    cmd0_clk            => cmd0_clk,
    cmd0_reset          => cmd0_reset,
    cmd0_data           => cmd0_data,
    cmd0_write          => cmd0_write,
    cmd0_end            => cmd0_end,
    cmd0_full           => cmd0_full_int,
    cmd0_almost_full    => cmd0_almost_full_int,
    cmd0_idle           => cmd0_idle_int,
   
    -- Write Fifo Interfaces 
    wd0_clk             => wd0_clk,
    wd0_reset           => wd0_reset,
    wd0_write           => wd0_write,
    wd0_end_burst       => wd0_end_burst,
    wd0_flush           => wd0_flush,
    wd0_data            => wd0_data,
    wd0_data_be         => wd0_data_be,
    wd0_full            => wd0_full_int,
    wd0_almost_full     => wd0_almost_full_int,
   
    -- Read Fifo Interfaces
    rd0_clk             => rd0_clk,
    rd0_reset           => rd0_reset,
    rd0_read            => rd0_read,
    rd0_end_burst       => rd0_end_burst,
    rd0_flush           => rd0_flush,
    rd0_data            => rd0_data,
    rd0_empty           => rd0_empty,
    rd0_almost_empty    => rd0_almost_empty,
   
    -- MPMC Native Port Interface (NPI)
    npi_init_done               => npi_init_done,
    npi_addr_ack                => npi_addr_ack,
    npi_rdfifo_word_add         => npi_rdfifo_word_add,
    npi_rdfifo_data             => npi_rdfifo_data,
    npi_rdfifo_latency          => npi_rdfifo_latency,
    npi_rdfifo_empty            => npi_rdfifo_empty,
    npi_wrfifo_almost_full      => npi_wrfifo_almost_full,
    npi_address                 => npi_address_int,
    npi_addr_req                => npi_addr_req,
    npi_size                    => npi_size,
    npi_rnw                     => npi_rnw,
    npi_rdfifo_pop              => npi_rdfifo_pop,
    npi_rdfifo_flush            => npi_rdfifo_flush,
    npi_wrfifo_data             => npi_wrfifo_data,
    npi_wrfifo_be               => npi_wrfifo_be,
    npi_wrfifo_push             => npi_wrfifo_push,
    npi_wrfifo_flush            => npi_wrfifo_flush,
   
    -- Debug port
    debug                       => open
);

cmd0_full          <= cmd0_full_int;
cmd0_almost_full  <= cmd0_almost_full_int;
cmd0_idle         <= cmd0_idle_int;

wd0_full          <= wd0_full_int;
wd0_almost_full    <= wd0_almost_full_int;

npi_address <= mpmc_baseaddr(mpmc_baseaddr'high) & npi_address_int(30 downto 0);
end IMP;

