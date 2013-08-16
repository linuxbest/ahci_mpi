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
-- Filename - vfbc_cmd_fetch.vhd
-- Author - , Xilinx
-- Creation - July 25, 2006
--
-- Description - Command Fetch
--               Generates Requests to Arbiter based on current 
--               active commands, fifo flags and tells burst controller
--               to send a burst.
--*******************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library work;
use work.memxlib_utils.all;


entity vfbc_cmd_fetch is
  generic(
    WD_ENABLE           : std_logic := '1';-- Write Port Enable
    RD_ENABLE           : std_logic := '1';-- Read Port Enable
    NUM_CMD_PORTS       : integer := 3;    -- Number of Command Ports
    NUM_CMD_WORDS_PER_PORT : integer := 4; -- Number of Command words (2 or 4)
    NUM_DATA_PORTS      : integer := 4;    -- Number of Data Ports
    BA_SIZE             : integer := 2;    -- Bank Address Size - For choosing next burst based on open bank
    BA_LOC              : integer := 10;   -- Bank Address Location 
    REQ_WAIT_AFTER_GNT  : integer := 5;    -- Number of 4 cycle sequence from grant to data fifo status change
    BURST_SIZE          : integer := 8     -- VFBC Burst Size
  );
  port(
    -- Common interface
    clk                 : in std_logic;    -- VFBC/Memory Controller Clock
    srst                : in std_logic;    -- Synchronous Reset

    -- New Command Interface
    newcmd_addr         : in std_logic_vector(logbase2(NUM_CMD_WORDS_PER_PORT-1)-1 downto 0); -- Command Buffer Address
    newcmd_data         : in std_logic_vector(31 downto 0);                                   -- Command Buffer Data
    newcmd_wr           : in std_logic;                                                       -- Command Buffer Write Enable

    -- data fifo interfaces
    rdfifo_almost_full  : in std_logic_vector(NUM_DATA_PORTS-1 downto 0);               -- Read Data FIFOs Almost Full
    wrfifo_empty        : in std_logic_vector(NUM_DATA_PORTS-1 downto 0);               -- Write Data FIFOs Empty
    wrfifo_almost_empty : in std_logic_vector(NUM_DATA_PORTS-1 downto 0);               -- Write Data FIFOs Almost Empty
    mc_af_almost_full   : in std_logic := '0';                                          -- Memory Controller Addres FIFO Almost
                                                                                        -- Full
    mc_wd_almost_full   : in std_logic := '0';                                          -- Memory Controller Write Data FIFO Almost
                                                                                        -- Full
    bc_raf_almost_full  : in std_logic := '0';                                          -- burst Controller Read Address FIFO
                                                                                        -- Almost Full

    -- Command Buffer Interface
    cbuf_addr           : out std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);  -- Command Buffer Address

 
    -- Arbitrator Interface
    arb_granted         : in  std_logic_vector(NUM_DATA_PORTS-1 downto 0);              -- Port Select (One-hot)
    arb_granted_port_id : in  std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);  -- ID of Selected Port 
    arb_grant           : in  std_logic;                                                -- Arbiter Granted Request.  Active high

    arb_request         : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);              -- Port Request
    arb_burst_request   : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);              -- Port Burst Request
    arb_bank            : out std_logic_vector(NUM_DATA_PORTS*BA_SIZE-1 downto 0);      -- Indicates the memory bank which the
                                                                                        -- command is operating on
    arb_wr_op           : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);              -- Indicates Write Operation/Transfer when
                                                                                        -- High otherwise Read
    arb_clk_en          : out std_logic;                                                -- Arbiter Clock Enable: once every 4
                                                                                        -- cycles

    -- Burst Control Interface
    bc_active_port      : in std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);   -- Burst Controller Active Port ID
    bc_update_addr      : in  std_logic_vector(30 downto 0);                            -- Burst Controller Mem Address
    bc_update_xcount    : in  std_logic_vector(23 downto 0);                            -- Burst Controller current X Size
    bc_update_ycount    : in  std_logic_vector(23 downto 0);                            -- Burst Controller current Y size
    bc_update           : in  std_logic;                                                -- burst Controller Update command buffer.
                                                                                        -- Active High
    bc_done             : in  std_logic;                                                -- Burst Controller Completed Transfer

    bc_valid            : out std_logic;                                                -- New CMD is valid, operate on it
  
    WritePortReset      : in std_logic_vector(NUM_DATA_PORTS-1 downto 0) := (others => '0'); -- Write Data FIFO Resets
    ReadPortReset       : in std_logic_vector(NUM_DATA_PORTS-1 downto 0) := (others => '0'); -- Read Data FIFO Resets
    PortActive          : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);                   -- Active Ports/transfers when high
    FourCycleCounter    : out std_logic_vector(1 downto 0)                                   -- Free running 2bit 4 cycle counter
  );
end vfbc_cmd_fetch;

architecture rtl of vfbc_cmd_fetch is

type ArbGrantArray is array (integer range <>) of std_logic_vector(NUM_DATA_PORTS-1 downto 0);

signal CycleCounter : std_logic_vector(logbase2(BURST_SIZE-1)-1 downto 0);
signal intPortActive, WriteOp, long_burst : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal ActivePort : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal newcmd_data_dly, newcmd_data_dly2 : std_logic_vector(31 downto 0);
signal arb_granted_dly : ArbGrantArray(REQ_WAIT_AFTER_GNT downto 0);

signal bank : std_logic_vector(NUM_DATA_PORTS*BA_SIZE-1 downto 0);
signal request : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal burst_request : std_logic_vector(NUM_DATA_PORTS-1 downto 0);

attribute syn_keep : boolean;
attribute syn_keep of WriteOp, bank, request, burst_request : signal is true;

function ExtractBank(address : std_logic_vector; ba_loc, ba_size : integer) return std_logic_vector is
variable temp : std_logic_vector(address'length-1 downto 0);
begin
temp := address;
return temp(ba_size+ba_loc-1 downto ba_loc);
end;

begin

-- free running four clock cycler
process(clk)
begin
if rising_edge(clk) then
  if (srst = '1') then
    CycleCounter <= (others => '0');
  else
    if (CycleCounter = BURST_SIZE-1) then
    CycleCounter <= (others => '0');
          else
    CycleCounter <= CycleCounter + 1;
          end if;
  end if;
end if;
end process;

FourCycleCounter <= CycleCounter(1 downto 0);

process(clk)
begin
if rising_edge(clk) then
  newcmd_data_dly <= newcmd_data;
  newcmd_data_dly2 <= newcmd_data_dly;
end if;
end process;

-- intPortActive
process(clk)
begin
if rising_edge(clk) then
  if (srst = '1') then
    intPortActive <= (others => '0');
  else

    for i in 0 to NUM_DATA_PORTS-1 loop
      --BIDI if (newcmd_addr = 0) and (newcmd_wr = '1') and (i = newcmd_data(logbase2(NUM_DATA_PORTS-1)+23 downto 24)) then
      if (newcmd_addr = 1) and (newcmd_wr = '1') and (i = newcmd_data(31 downto 31)) then
        intPortActive(i) <= '1';
      elsif (   ((WriteOp(i) = '1') and (WritePortReset(i) = '1') and (intPortActive(i) = '1') and (newcmd_wr = '0') )
                               or ((WriteOp(i) = '0') and (ReadPortReset(i) = '1') and (intPortActive(i) = '1') and (newcmd_wr =
                                '0') )
                              ) then
        intPortActive(i) <= '0';
      elsif (bc_done = '1') and (i = ActivePort) then
        intPortActive(i) <= '0';
      end if;
    end loop;
  end if;
end if;
end process;

PortActive <= intPortActive;
        
-- generate arb_bank and WriteOp
Writeop(0) <= '0'; -- Always read
Writeop(1) <= '1'; -- Always write

process(clk)
begin
if rising_edge(clk) then
  if (srst = '1') then
    bank <= (others => '0');
    --BIDI WriteOp <= (others => '0');
  else
    for i in 0 to NUM_DATA_PORTS-1 loop
      if (newcmd_addr = 1) and (newcmd_wr = '1') and (i = newcmd_data_dly(logbase2(NUM_DATA_PORTS-1)+23 downto 24)) then
          bank(BA_SIZE*i+1 downto BA_SIZE*i) <= ExtractBank(newcmd_data, BA_LOC, BA_SIZE);
          --BIDI WriteOp(i) <= newcmd_data(31);
      elsif (bc_update = '1') and (i = ActivePort) then
          bank(BA_SIZE*i+1 downto BA_SIZE*i) <= ExtractBank(bc_update_addr, BA_LOC, BA_SIZE);
      end if;
    end loop;

  end if;
end if;
end process;

arb_bank <= bank;
arb_wr_op <= WriteOp;


-- generate request to arbiter
process(clk)
variable arb_grant_wait : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
variable rdpath_busy : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
variable wrpath_busy : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
variable wrpath_long_burst_busy : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
begin
if rising_edge(clk) then
  if (srst = '1') then
    request <= (others => '0');
    burst_request <= (others => '0');
    for i in 0 to REQ_WAIT_AFTER_GNT-2 loop
      arb_granted_dly(i) <= (others => '0');
    end loop;
  else
    if (CycleCounter = BURST_SIZE/2-1) then
      arb_granted_dly(0) <= arb_granted;
      for i in 1 to REQ_WAIT_AFTER_GNT-2 loop
        arb_granted_dly(i) <= arb_granted_dly(i-1);
      end loop;
                        if(REQ_WAIT_AFTER_GNT /= 0) then
        arb_grant_wait := arb_granted;
                        else
        arb_grant_wait := (others => '0');
                        end if;
      for i in 0 to REQ_WAIT_AFTER_GNT-2 loop
        arb_grant_wait := arb_granted_dly(i) or arb_grant_wait;
      end loop;
      if (bc_raf_almost_full = '0') and (mc_af_almost_full = '0') and (newcmd_wr = '0')  then
        rdpath_busy := rdfifo_almost_full;
      else
        rdpath_busy := (others => '1');
      end if;
      if (mc_wd_almost_full = '0') and (mc_af_almost_full = '0') and (newcmd_wr = '0')  then
        wrpath_busy := wrfifo_empty;
        wrpath_long_burst_busy := wrfifo_almost_empty;
      else
        wrpath_busy := (others => '1');
        wrpath_long_burst_busy := (others => '1');
      end if;

      request <=   (intPortActive and (not WriteOp) and (not rdpath_busy)             and (not ReadPortReset))
          or (intPortActive and (WriteOp)     and (not wrpath_long_burst_busy)  and (not WritePortReset))
          or (intPortActive and (WriteOp)     and (not wrpath_busy)             and (not arb_grant_wait) and (not WritePortReset));

      burst_request <=   (intPortActive and (not WriteOp) and (not rdpath_busy)            and (not ReadPortReset))
          or (intPortActive and (WriteOp)     and (not wrpath_long_burst_busy) and (not WritePortReset));

    end if;
  end if;
end if;
end process;

arb_request <= request and intPortActive;
arb_burst_request <= burst_request and intPortActive;
        
process(clk)
begin
if rising_edge(clk) then
  if srst = '1' then
    arb_clk_en <= '0';
    bc_valid <= '0';
  else
    -- enable Arbiter once every burst (last cycle of burst)
    if (CycleCounter = BURST_SIZE-1) then 
      arb_clk_en <= '1'; 
    else 
      arb_clk_en <= '0'; 
    end if;

    -- send burst controller valid signal when granted
    -- Tells Burst Controller to send a burst
    if (CycleCounter = BURST_SIZE/2-2) then 
            if(    (arb_granted and intPortActive) /= 0) 
               and ((WD_ENABLE and mc_wd_almost_full) = '0') 
               and (mc_af_almost_full = '0') 
               and ((RD_ENABLE and bc_raf_almost_full) = '0') then
              bc_valid <= '1';
            end if;
    else
      bc_valid <= '0'; 
    end if;  
  end if;
end if;
end process;

cbuf_addr <= arb_granted_port_id;

ActivePort <= bc_active_port;
end rtl;

