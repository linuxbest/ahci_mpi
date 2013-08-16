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
-- Description - Alternate Command Control Module (Currently Not USED)
--               This would take the place of the new command,
--               command fetch, command buffer and the arbiter.
--******************************************************************


-- must turn on registering the output of the command interface rams.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

LIBRARY work;
USE work.memxlib_utils.ALL;



entity vfbc_cmd_control is
  generic
  (
    CMD_READ_DELAY              : integer := 2            
  );
  port
  (
    clk                     : in  std_logic;
    srst                    : in  std_logic;

    -- Command FIFO Interface
    cmd_datain              : in  std_logic_vector(31 downto 0);
    cmd_empty               : in  std_logic;
    cmd_addr                : out std_logic_vector(1 downto 0);
    cmd_dataout             : out std_logic_vector(127 downto 0);
    cmd_release             : out std_logic;

    -- Data FIFO Interface
    rd_almost_full          : in std_logic;
    rd_full                 : in std_logic;
    wd_almost_empty         : in std_logic;
    wd_empty                : in std_logic;

    -- Burst Controller Interface
    cmd_done                : in  std_logic;
    cmd_update              : in  std_logic;
    cmd_burst_datain        : in  std_logic_vector(127 downto 0);
    cmd_valid               : out std_logic;

    --FIFO Status 
    bctrl_rafifo_almost_full: in  std_logic; -- From Burst Control
    mem_init_done           : in  std_logic;
    mem_wrfifo_almost_full  : in  std_logic;
    mem_rd_fifo_empty       : in  std_logic
  );
end vfbc_cmd_control;
------------------------------------------------------------------------------
-- RTL Architecture
------------------------------------------------------------------------------
architecture rtl of vfbc_cmd_control is
  signal port_active            : std_logic;
  signal cmd_write              : std_logic;
  signal cycle_cnt              : std_logic_vector(1 downto 0);
  signal cmd_valid_int          : std_logic;
  signal cmd_valid_int_d        : std_logic;
  signal cmd_dataout_int        : std_logic_vector(127 downto 0);
  signal cmd_dataout_int_d      : std_logic_vector(127 downto 0);

begin
  cmd_release <= cmd_done;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        cycle_cnt <= (others => '0');
      else
        cycle_cnt <= cycle_cnt + 1;
      end if;
    end if;
  end process;
  cmd_addr <= cycle_cnt;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        cmd_dataout_int <= (others => '0');
        cmd_write   <= '0';
      else
        if(cycle_cnt = 3) then
          cmd_write <= cmd_datain(31);
        end if;

        if(cmd_update = '1') then
          cmd_dataout_int <= cmd_burst_datain;
        elsif(port_active = '0') and (cmd_valid_int = '0') then 
          cmd_dataout_int <= cmd_datain & cmd_dataout_int(127 downto 32);
        end if;
      end if;
    end if;
  end process;

--  process(clk)
--  begin
--    if(rising_edge(clk)) then
--      if(srst = '1') then
--        cmd_dataout_int_d <= (others => '0');
--      else
--        if(cmd_update = '1') then
--          cmd_dataout_int_d <= cmd_burst_datain;
--        elsif(cmd_valid_int_d = '1') then
--          cmd_dataout_int_d <= cmd_dataout_int;
--        end if;
--      end if;
--    end if;
--  end process;
--
--  cmd_dataout <= cmd_dataout_int_d;
  cmd_dataout <= cmd_dataout_int;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        cmd_valid_int   <= '0';
        --cmd_valid_int_d <= '0';
      else
        --cmd_valid_int_d <= cmd_valid_int;

        --if(    (port_active   = '0')
        if(    
               (cmd_valid_int = '0')
           and (cycle_cnt     = (CMD_READ_DELAY-1))
           and (cmd_empty     = '0')
           and (mem_init_done = '1')
           and (   ((cmd_write = '0') and (mem_rd_fifo_empty = '0') and (bctrl_rafifo_almost_full = '0') and (rd_almost_full =
            '0'))
                or ((cmd_write = '1') and (mem_wrfifo_almost_full = '0') and (wd_almost_empty = '0'))
               )
          ) then
          cmd_valid_int <= '1';
        else
          cmd_valid_int <= '0';
        end if;          
      end if;
    end if;
  end process;
  --cmd_valid <= cmd_valid_int_d;
  cmd_valid <= cmd_valid_int;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        port_active <= '0';
      else
        if(cmd_valid_int = '1') then
          port_active <= '1';
        elsif(cmd_done = '1') then
          port_active <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;

