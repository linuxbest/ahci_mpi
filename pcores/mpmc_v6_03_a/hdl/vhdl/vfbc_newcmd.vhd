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
-- Filename - vfbc_newcmd.vhd
-- Author - , Xilinx
-- Creation - July 25, 2006
--
-- Description - New Command Controlelr
--               The module reads command data from the command
--               FIFOs and writes commands into the command buffer.
--
--*******************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library work;
use work.memxlib_utils.all;


entity vfbc_newcmd is
  generic(
    NUM_CMD_PORTS          : integer := 8;              -- Number of Command Ports. Usually 1
    NUM_CMD_WORDS_PER_PORT : integer := 4;              -- Number of Command Words. 
                                                        -- Either 2 (when rect access is disabled) 
                                                        -- or 4 (when rect access is enabled)
    NUM_DATA_PORTS         : integer := 8;              -- Number of Data Ports
    FIXED_DATA_PORT_ID     : integer_array := (99,99,99,99,99,99,99,99); -- the fixed data port id of each command port.  If 99, it
                                                                         -- is not fixed.
    ARBITRATION_SCHEME     : string := "ROUNDROBIN"     -- Command Arbiter Scheme: "ROUNDROBIN" or "DEFAULT"
  );
  port(
    -- Common interface
    clk                 : in std_logic;                 -- VFBC/memory Controller Clock.  Positive Edge
    srst                : in std_logic;                 -- Synchronous Reset. Active High

    -- Command Interface
    -- cmd_data should be valid 2 cycles after cmd_gnt and cmd_addr
    cmd_in_data         : in std_logic_vector(32*NUM_CMD_PORTS-1 downto 0);     -- CMD Object to 4 words:  
                                                        -- Word0: Port ID / X size
                                                        -- Word1: WrOp / Start Address
                                                        -- Word2: Y size (optional)
                                                        -- Word3: Stride (optional)
    cmd_in_req          : in std_logic_vector(NUM_CMD_PORTS-1 downto 0); -- new command waiting, controlled by cmd_clken
    cmd_in_gnt          : out std_logic_vector(NUM_CMD_PORTS-1 downto 0); -- Pop New Command from CMD Fifo.  Active High
    cmd_in_addr         : out std_logic_vector(logbase2(NUM_CMD_WORDS_PER_PORT-1)-1 downto 0); -- identify which of the 4 words
                                                                                               -- should be sent from cmd_data; 
                                                                                               -- always count from 0 to 3
    cmd_in_clken        : out std_logic;                -- Command clk enable.  Once every 4 cycles.
  
    PortActive          : in std_logic_vector(NUM_DATA_PORTS-1 downto 0);  -- One bit per Data Port.  High denotes an active
                                                                           -- transfer

    FourCycleCounter    : in std_logic_vector(1 downto 0); -- Free running counter from 0 to 3.
    newcmd_addr         : out std_logic_vector(logbase2(NUM_DATA_PORTS*NUM_CMD_WORDS_PER_PORT-1)-1 downto 0); -- Command Buffer
                                                                                                              -- address 
    newcmd_data         : out std_logic_vector(31 downto 0);                                                  -- Command Buffer
                                                                                                              -- Data  
    newcmd_wr           : out std_logic                                                                       -- Command Buffer
                                                                                                              -- Write Enable

  );
end vfbc_newcmd;

architecture rtl of vfbc_newcmd is

type cmd_sel_array is array (natural range <>) of std_logic_vector(logbase2(NUM_CMD_PORTS-1)-1 downto 0);

signal GrantedCmdPort : std_logic_vector(NUM_CMD_PORTS-1 downto 0);
signal GrantedCmdPortID : std_logic_vector(logbase2(NUM_CMD_PORTS-1)-1 downto 0);
signal CmdGrant : std_logic;
signal CmdGrantShort : std_logic;
signal CmdGrantDly : std_logic_vector(1 downto 0);
signal GrantedCmdPortIDDly, GrantedCmdPortIDDly2 : std_logic_vector(logbase2(NUM_CMD_PORTS-1)-1 downto 0);
signal newcmd_data_port_id : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal newcmd_data_port_id_d : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal ArbReq, ReqOk : std_logic_vector(NUM_CMD_PORTS-1 downto 0);
signal int_cmd_in_clken : std_logic;
signal FourCycleCounter_dly : std_logic_vector(1 downto 0); 
signal FourCycleCounter_dly2 : std_logic_vector(1 downto 0); 
signal FourCycleCounter_dly3 : std_logic_vector(1 downto 0); 

function DpRamWrAddr(GrantedCmdPortID, 
                     FourCycleCounter : std_logic_vector; 
                     NUM_CMD_WORDS_PER_PORT : integer; 
                     NUM_DATA_PORTS : integer
                    ) return std_logic_vector is
  variable temp : std_logic_vector(0 downto 0);
begin
  if (NUM_CMD_WORDS_PER_PORT = 2) then
    if(NUM_DATA_PORTS = 1) then
      temp(0) := (FourCycleCounter(0) and (not FourCycleCounter(1)));
      return temp;
    else
      return GrantedCmdPortID & (FourCycleCounter(0) and (not FourCycleCounter(1)));
    end if;
  elsif (NUM_CMD_WORDS_PER_PORT = 4) then
    if(NUM_DATA_PORTS = 1) then
      return FourCycleCounter;
    else
      return GrantedCmdPortiD & FourCycleCounter;
  end if;
else
  assert false report "NUM_CMD_WORDS_PER_PORT should be 2 or 4." severity error;
  return "0";
end if;
end;

constant ZEROS : std_logic_vector(99 downto 0) := (others => '0');
constant ONES  : std_logic_vector(99 downto 0) := (others => '1');

begin

-- latch Data Port ID from all command ports
process(clk)
begin
if rising_edge(clk) then
  if srst = '1' then
    ReqOk <= (others => '0');
  else
    --if (FourCycleCounter = 3) then
                --CJM Rportid=0,Wportid=1 if (FourCycleCounter = 2) then
    if (FourCycleCounter = 3) then
      ReqOk <= (others => '0');
      for i in 0 to NUM_CMD_PORTS-1 loop
        for j in 0 to NUM_DATA_PORTS-1 loop
          if FIXED_DATA_PORT_ID(i) = 99 then
            --if PortActive(j) = '0' and GrantedCmdPort(i) = '0' and j = cmd_in_data(32*i+logbase2(NUM_DATA_PORTS-1)+23 downto
            -- 32*i+24) then
--CJM Rportid=0,Wportid=1 if PortActive(j) = '0' and GrantedCmdPort(i) = '0' and j = cmd_in_data(32*i+LOG2(NUM_DATA_PORTS-1)+23
-- downto 32*i+24) then
            if PortActive(j) = '0' and GrantedCmdPort(i) = '0' and j = cmd_in_data(31 downto 31) then
            
              ReqOk(i) <= '1';            
            end if;
          else
            if PortActive(j) = '0' and GrantedCmdPort(i) = '0' and j = FIXED_DATA_PORT_ID(i) then
              ReqOk(i) <= '1';
            end if;
          end if;
        end loop;
      end loop;
    end if;  
  end if;
end if;
end process;

ArbReq <= cmd_in_req and ReqOk;

UCmdArbiter: entity work.vfbc_arbitrator
generic map(
  NUM_PORTS => NUM_CMD_PORTS,
  SCHEME => ARBITRATION_SCHEME
)
port map(
  clk                   => clk,
  clken                 => int_cmd_in_clken,
  srst                  => srst,
  cmd_request           => ArbReq,
  cmd_granted           => GrantedCmdPort,
  cmd_granted_port_id   => GrantedCmdPortID,
  cmd_grant             => CmdGrant,
  cmd_bank              => ZEROS(NUM_CMD_PORTS*2 -1  downto 0),
  cmd_burst_request     => ZEROS(NUM_CMD_PORTS -1  downto 0),
  cmd_wr_op             => ONES(NUM_CMD_PORTS -1  downto 0),
  wr_almost_full        => ZEROS(NUM_CMD_PORTS -1  downto 0),
  wr_flush              => ZEROS(NUM_CMD_PORTS -1  downto 0),
  rd_almost_empty       => ZEROS(NUM_CMD_PORTS -1  downto 0)

);

cmd_in_gnt <= GrantedCmdPort;

GEN_RECT4: if(NUM_CMD_WORDS_PER_PORT /= 2) generate
 CmdGrantShort <= CmdGrant;
end generate;
GEN_LIN2: if(NUM_CMD_WORDS_PER_PORT = 2) generate
 CmdGrantShort <= CmdGrant when ((FourCycleCounter = 1) or (FourCycleCounter = 2)) else '0';
end generate;


process(clk)
begin
if rising_edge(clk) then
  if srst = '1' then
    CmdGrantDly <= (others => '0');    
  else
    CmdGrantDly <= CmdGrantDly(CmdGrantDly'high-1 downto 0) & CmdGrantShort;
  end if;
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
  GrantedCmdPortIDDly <= GrantedCmdPortID;
  GrantedCmdPortIDDly2 <= GrantedCmdPortIDDly;
end if;
end process;

-----------------------------------------------------------------------------
-- Command Clock enable.  Only High on cycle 3 (0,1,2,3) = 4th cycle
-----------------------------------------------------------------------------
process(clk)
begin
if rising_edge(clk) then
  if (FourCycleCounter = 3) then 
    int_cmd_in_clken <= '1'; 
  else 
    int_cmd_in_clken <= '0'; 
  end if;
end if;
end process;

cmd_in_clken <= int_cmd_in_clken;

process(clk)
begin
if rising_edge(clk) then  
  FourCycleCounter_dly <= FourCycleCounter;
  FourCycleCounter_dly2 <= FourCycleCounter_dly;
  FourCycleCounter_dly3 <= FourCycleCounter_dly2;
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
  if (NUM_CMD_WORDS_PER_PORT = 4) then
    cmd_in_addr <= FourCycleCounter(1 downto 0);
  else
    cmd_in_addr(0) <= FourCycleCounter(0) and (not FourCycleCounter(1));
  end if;
end if;  
end process;

--CJM newcmd_addr <= DpRamWrAddr(newcmd_data_port_id, FourCycleCounter, NUM_CMD_WORDS_PER_PORT);
  newcmd_addr <= DpRamWrAddr(newcmd_data_port_id_d, FourCycleCounter_dly3, NUM_CMD_WORDS_PER_PORT,NUM_DATA_PORTS);

newcmd_wr <= CmdGrantDly(CmdGrantDly'high);

process(clk)
begin
if rising_edge(clk) then
  if srst = '1' then
    newcmd_data <= (others => '0');
    newcmd_data_port_id <= (others => '0');
    newcmd_data_port_id_d <= (others => '0');
  else
    if (CmdGrantDly(0) = '1') then
      newcmd_data <= cmd_in_data(32*0+31 downto 32*0);
    end if;

    if (CmdGrantDly(0) = '0') then
      if FourCycleCounter=3 then
        if FIXED_DATA_PORT_ID(0) = 99 then
          newcmd_data_port_id(0) <= cmd_in_data(31);
        else
          newcmd_data_port_id <= conv_std_logic_vector(FIXED_DATA_PORT_ID(0),newcmd_data_port_id'length);
        end if;
      end if;
    end if;

    if (CmdGrantDly(0) = '1') then
      if FIXED_DATA_PORT_ID(0) = 99 then
        newcmd_data_port_id_d(0) <= newcmd_data_port_id(0);
      else
        newcmd_data_port_id_d <= conv_std_logic_vector(FIXED_DATA_PORT_ID(0),newcmd_data_port_id'length);
      end if;
    end if;

  end if;
end if;
end process;


end rtl;

