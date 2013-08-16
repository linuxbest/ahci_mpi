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
-- Filename - p_vfbc.vhd
-- Author - Mankit Lo, Xilinx
-- Creation - July 27, 2006
--
-- Description - VFBC Package
--               Contains port records for all top level I/Os.
--
--*******************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library work;
use work.memxlib_utils.all;

package p_vfbc is

constant MAX_DATA_WIDTH : integer := 256;

type CmdPortInputSignals is record
  Clk : std_logic;                -- Command Clock
  MReset_n : std_logic;           -- Command Active-Low Reset
  MFlagWrite : std_logic;         -- Command Write Enable
  MFlagEnd   : std_logic;         -- Command End: last command word
        -- Command Data
  -- Data should be sent in the following order: x_size, address, y_size, stride.
  -- CmdPortOutputSignals.Addr should be used to determine when the content being sent.
  -- When Addr is 0, Data should be x_size two cycles later
  -- When Addr is 1, Data should be address two cycles later
  -- When Addr is 2, Data should be y_size (zero if not used) two cycles later
  -- When Addr is 3, Data should be stride (zero if not used) two cycles later
  MData : std_logic_vector(31 downto 0);

end record;

type CmdPortOutputSignals is record
  SFlagFull       : std_logic;    -- Command FIFO Full Flag        
  SFlagAlmostFull : std_logic;    -- Command FIFO Almost Full Flag 
        SFlagIdle       : std_logic;    -- command Idle: High when no commands active in queue
end record;

type CmdPortInputSignalsArray is array (integer range <>) of CmdPortInputSignals;
type CmdPortOutputSignalsArray is array (integer range <>) of CmdPortOutputSignals;

type WrDataFifoInputSignals is record
  Clk : std_logic;                        -- Write FIFO Clock
  MCmd : std_logic_vector(2 downto 0);    -- Bit 0 Connected to Write Enable. Active High
  MAddr : std_logic_vector(31 downto 0);  -- Object Address. Connected to Zero
  MData : std_logic_vector(MAX_DATA_WIDTH-1 downto 0); -- Write Data
  MDataByteEn : std_logic_vector(31 downto 0); -- Write Byte Enables. Active High
  MDataInfoCmdTag : std_logic;            -- RESERVED
  MFlagCommit : std_logic;                -- Commit Object/Burst to Write FIFO. Active High
  MFlagFlush : std_logic;                 -- Flush FIFO. Active High.
  MReset_n : std_logic;                   -- Flush FIFO and remove current Command. Active Low
end record;

type WrDataFifoOutputSignals is record
  SCmdAccept : std_logic;                 -- RESERVED
  SFlagFull : std_logic;                  -- Write FIFO Full Flag. Active High
  SFlagAlmostFull : std_logic;            -- Write FIFO Almost Full Flag. Active High
  SFlagPortIdle : std_logic;              -- RESERVED
  SFlagNumOfObjAvail : std_logic_vector(31 downto 0); -- Number of Objects Available in FIFO
end record;

type RdDataFifoInputSignals is record
  Clk : std_logic;                        -- Read FIFO Clock. Active High Edge
  MCmd : std_logic_vector(2 downto 0);    -- Bit 1: Read FIFO Read Enable. Active High
  MAddr : std_logic_vector(31 downto 0);  -- Object Address. Connect to Zero
  MFlagCommit : std_logic;                -- Release Object/Burst from Read FIFO. Active High
  MFlagFlush : std_logic;                 -- Flush FIFO. Active High.
  MReset_n : std_logic;                   -- Flush FIFO and remove current Command. Active Low
end record;

type RdDataFifoOutputSignals is record
  SCmdAccept : std_logic;                 -- RESERVED
  SData : std_logic_vector(MAX_DATA_WIDTH-1 downto 0);    -- READ Date
  SResp : std_logic;                      -- RESERVED
  SDataInfoCmdTag : std_logic;            -- RESERVED
  SFlagEmpty : std_logic;                 -- Read FIFO Empty. Active High
  SFlagAlmostEmpty : std_logic;           -- Read FIFO Almost Empty. Active High
  SFlagNumOfObjFilled : std_logic_vector(31 downto 0); -- Number of Objects Filled in FIFO
end record;

type WrDataFifoInputSignalsArray is array (integer range <>) of WrDataFifoInputSignals;
type WrDataFifoOutputSignalsArray is array (integer range <>) of WrDataFifoOutputSignals;
type RdDataFifoInputSignalsArray is array (integer range <>) of RdDataFifoInputSignals;
type RdDataFifoOutputSignalsArray is array (integer range <>) of RdDataFifoOutputSignals;

type MCBusInputSignals is record
  Burst_Length : std_logic_vector(2 downto 0); -- Memory Controller Burst Length
  Read_data_valid : std_logic;                 -- Memory Controller Read Data Valid. Active High
  Read_data_fifo_out : std_logic_vector(MAX_DATA_WIDTH-1 downto 0); -- Memory Controller Read Data
  WDF_Almost_Full : std_logic;                 -- Memory Controller Write Data FIFO Almost Full
  AF_Almost_Full : std_logic;                  -- Memory Controller Address FIFO Almost Full
  Error : std_logic;
end record;

type MCBusOutputSignals is record
  App_Af_addr : std_logic_vector(35 downto 0); -- Memory Controller Address Fifo Address (35:32=command,31:0=address)
  App_Af_wren : std_logic;                     -- Memory Controller Address Fifo Address
  App_WDF_data : std_logic_vector(MAX_DATA_WIDTH-1 downto 0); -- Memory Controller Write Data FIFO Data
  App_Mask_data : std_logic_vector(31 downto 0); -- Memory Controller Mask Data (One bit per data byte, opposite polarity as byte
                                                 -- enable)
  App_WDF_wren : std_logic;                    -- Memory Controller Write Data FIFO Write Enable.  Active High
end record;

end p_vfbc;

package body p_vfbc is
--  constant MAX_DATA_WIDTH : integer := 256;
end p_vfbc;



