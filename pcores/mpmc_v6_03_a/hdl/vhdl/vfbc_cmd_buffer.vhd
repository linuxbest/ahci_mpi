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
-- Filename - vfbc_cmd_buffer.vhd
-- Creation - July 25, 2005
--
-- Description - VFBC Command Buffer
--               The module stores commands fetched from the command
--               FIFO and allows the burst controller to modify as
--               the transfers progress.
--
-- Cmd operating buffers are internal to this module
-- and enabled via the ENABLE_BURST_CUT generic/parameter
--*******************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

LIBRARY work;
USE work.memxlib_utils.ALL;

entity vfbc_cmd_buffer is
  generic(
    VFBC_FAMILY                 : string  := "S3A"; -- Device Family.  Unused
    ENABLE_BURST_CUT            : boolean := TRUE;  -- Enable Burst Cutting 
    NUM_CMD_WORDS_PER_PORT      : integer := 4;     -- Number of words per command (2 or 4)
    CMD_WIDTH                   : integer := 32;    -- Command Data Width (Always 32)
    MEM_TYPE                    : string := BLOCK_RAMSTYLE; -- Memory Type: BRAM, Distributed or Registers. Unused
    NUM_DATA_PORTS              : integer := 4;     -- Number of Data Ports
    PORT_ENABLE                 : std_logic_vector(1 downto 0) := "11" -- 0: disables command memory for port

  );
  port(
    -- Common interface
    clk                 : in std_logic;             -- VFBC/Memory Controller clock
    srst                : in std_logic;             -- Synchronous Reset

    -- Command Fetch Interface
    newcmd_addr         : in std_logic_vector(logbase2(NUM_DATA_PORTS*NUM_CMD_WORDS_PER_PORT-1)-1 downto 0); -- Command Write
                                                                                                             -- Address
    newcmd_data         : in std_logic_vector(CMD_WIDTH-1 downto 0);                                         -- Command Write Data
    newcmd_wr           : in std_logic;                                                                      -- Command Write
                                                                                                             -- Enable

    cmd_rd_addr         : in std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);                        -- Command Read
                                                                                                             -- Address
    -- Burst Control Interface
    bc_wr_addr          : in std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);                        -- Burst Controller
                                                                                                             -- Write Address
    bc_wr_data          : in std_logic_vector(CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 downto 0);                  -- Burst Controller
                                                                                                             -- Write Data
    bc_write            : in std_logic;                                                                      -- Burst Controller
                                                                                                             -- Write Enable

    bc_rd_data          : out std_logic_vector(CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 downto 0)                  -- Burst Controller
                                                                                                             -- Read Data

  );
end vfbc_cmd_buffer;
------------------------------------------------------------------------------
-- RTL Architecture
------------------------------------------------------------------------------
architecture rtl of vfbc_cmd_buffer is
------------------------------------------------------------------------------
-- Functions
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Signals
------------------------------------------------------------------------------
signal cmd_mem          : std_logic_vector(NUM_DATA_PORTS*CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 downto 0) := (others => '0');
signal cmd_mem0          : std_logic_vector(CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 downto 0) := (others => '0');
signal cmd_mem1          : std_logic_vector(CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 downto 0) := (others => '0');
--signal buf_select_bc    : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
--signal buf_select_cmd   : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
signal command_data     : std_logic_vector(CMD_WIDTH-1 downto 0);
signal bc_addr          : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal read_data        : std_logic_vector(CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 downto 0);
------------------------------------------------------------------------------
-- Processes and Logic
------------------------------------------------------------------------------
begin
  -- Must always set reserved bits to zero
  command_data <= newcmd_data;

  GEN_BURST_CUT: if(ENABLE_BURST_CUT) generate 
      GEN_ONE_PORT: if(NUM_DATA_PORTS = 1) generate
        ---------------------------------------------------------------------
        --Command buffer write
        ---------------------------------------------------------------------
        process(clk)
        begin
          if(rising_edge(clk)) then
            --if(srst = '1') then
            --  cmd_mem <= (others => '0');
            --else
  
                if(bc_write = '1') then
                    cmd_mem <= bc_wr_data;
                --elsif(newcmd_wr = '1') then
                end if;
                if(newcmd_wr = '1') then
                    --Shift registers
                    cmd_mem <=   command_data & cmd_mem(       CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 
                                                         downto CMD_WIDTH);
                end if;
  
            --end if; -- srst
          end if; -- clk
        end process;


        ---------------------------------------------------------------------
        -- Command Buffer read
        ---------------------------------------------------------------------
        bc_rd_data <= cmd_mem;
      end generate GEN_ONE_PORT;
 

      GEN_TWO_PORT: if(NUM_DATA_PORTS = 2) generate
        ---------------------------------------------------------------------
        -- Rd Command Buffer Write
        ---------------------------------------------------------------------
        GEN_PORT0: if(PORT_ENABLE(0) = '1') generate
          process(clk)
          begin
            if(rising_edge(clk)) then
              if(srst = '1') then
                cmd_mem0 <= (others => '0');
              else
                  if(newcmd_wr = '1') and (newcmd_addr(2) = '0') then
                      --Shift registers
                      cmd_mem0 <=   command_data & cmd_mem0(       CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 
                                                            downto CMD_WIDTH);
    
                  elsif(bc_write = '1') and (bc_wr_addr(0) = '0') then
                      cmd_mem0 <= bc_wr_data;
                  end if;
    
              end if; -- srst
            end if; -- clk
          end process;
        end generate GEN_PORT0;

        ---------------------------------------------------------------------
        -- Wr Command Buffer Write
        ---------------------------------------------------------------------
        GEN_PORT1: if(PORT_ENABLE(1) = '1') generate
          process(clk)
          begin
            if(rising_edge(clk)) then
              if(srst = '1') then
                cmd_mem1 <= (others => '0');
              else
                  if(newcmd_wr = '1') and (newcmd_addr(2) = '1') then
                      --Shift registers
                      cmd_mem1 <=   command_data & cmd_mem1(       CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 
                                                            downto CMD_WIDTH);
    
                  elsif(bc_write = '1') and (bc_wr_addr(0) = '1') then
                      cmd_mem1 <= bc_wr_data;
                  end if;
    
              end if; -- srst
            end if; -- clk
          end process;
        end generate GEN_PORT1;


        ---------------------------------------------------------------------
        -- Command Buffer read
        ---------------------------------------------------------------------
        bc_rd_data <= cmd_mem0 when (cmd_rd_addr(0) = '0') else cmd_mem1;
      end generate GEN_TWO_PORT;


  end generate GEN_BURST_CUT; 

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------


end rtl;

