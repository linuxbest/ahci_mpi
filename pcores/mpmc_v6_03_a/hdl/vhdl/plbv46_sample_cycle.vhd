-------------------------------------------------------------------------------
-- plbv46_sample_cycle.vhd - Clock Ratio and Phase detection Logic
---------------------------------------------------------------------------
-- (c) Copyright 2007 - 2009 Xilinx, Inc. All rights reserved.
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
---------------------------------------------------------------------------
-- Filename:          plbv46_sample_cycle.v
-- Description:
--       This sample cycle generator counts the number of clock edges
--       of the fast_clk in two slow_clk cycles and uses half of that as
--       the slow_clk/fast_clk ratio to generate the slow_clk sample cycle
--       signal in the next two slow_clk cycles. This scheme is used mainly to
--       provide a robust mechanism to accomocate for a 1:1 ratio between
--       slow_clk and fast_clks. The sample cycle signal is aligned to the
--       rising edge of the fast clock and is asserted for 1 fast_clk in the
--       cycle prior to the rising edge of slow_clk.
--
-- Verilog-standard:  Verilog 2001
---------------------------------------------------------------------------
-- Author:      KD
-- History:
--  KD        01/10/2007      - Initial Version
--
--  GAB       01/24/2007      - converted to vhdl
--
--  MW        03/19/2007      - added synchronous reset
--                            - added FDS flip-flop for individule modules
--                               - replaced sample_cycle with individual
--                                 module names
--
--  MW        04/16/2007      - removed FDS flip-flop for individule modules
--                               - functional simulation was not clocking
--                                  different clock domains properly
--
---------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          MW
--
-- History:
--       KD        01/10/2007      - Initial Version
--
--       GAB       01/24/2007      - Initial Version
-- ~~~~~~
--       - converted to vhdl
-- ^^^^^^
--
--       MW        03/19/2007    - Initial Version
-- ~~~~~~
--       - added synchronous reset
--       - added FDS flip-flop for individule modules
--          - replaced sample_cycle with individual
--            module names
-- ^^^^^^
--
--       MW        04/16/2007   - Initial Version
-- ~~~~~~
--       - removed FDS flip-flop for individule modules
--         - functional simulation was not clocking
--           different clock domains properly
-- ^^^^^^
--
--       MW        08/02/2007   - Initial Version
-- ~~~~~~
--       - Added 2x delay for reset from mpmc to PIm MPMC
--         and PLB clock domains for timing.
-- ^^^^^^
--
--       MW        08/27/2007   - Initial Version
-- ~~~~~~
--       - Added sc2ad_clk_ratio_1_1 to port
-- ^^^^^^
--
--       MW        11/27/2007   - Initial Version
-- ~~~~~~
--       - Added sc2wr_sample_cycle_i and sc2rd_sample_cycle_i to fix
--          warning generated in NC SIM.  Attribute needed to be applied
--          Architecture's signal not the entity port signal.
-- ^^^^^^
--
--     MW      06/05/2008    plbv46_pim_v2_02_a - Release 11 
-- ~~~~~~
--    -  Removed dependancies on proc_common
-- ^^^^^^
--
--     MW      04/03/2009    _plbv46_pim_v2_03_a_  
-- ~~~~~~
--    -  CR#507838
--       -  Changed sample_cycle.vhd to use MAX_FANOUT Attribute setting
--          of 30 on the reset signal plb_rst_pipe
-- ^^^^^^
--

-------------------------------------------------------------------------------

-- Structure:
--                   -- plbv46_pim.vhd
--                      --addr_decoder.vhd
--                         --sample_cycle.vhd
--                      --write_module.vhd
--                      --rd_support.vhd
--                         --data_steer_mirror.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;


-------------------------------------------------------------------------------
entity plbv46_sample_cycle is
    port(
        rst                : in  std_logic;
        fast_clk           : in  std_logic;
        slow_clk           : in  std_logic;
        sc2ad_sample_cycle : out std_logic;
        sc2wr_sample_cycle : out std_logic;
        sc2rd_sample_cycle : out std_logic;
        sc2ad_clk_ratio_1_1: out std_logic;
        mpmc_rst           : out std_logic;
        plb_rst            : out std_logic;
        sync_rst           : out std_logic
    );

end plbv46_sample_cycle;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of plbv46_sample_cycle is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal/Type Declarations
-------------------------------------------------------------------------------

signal clear_count          : std_logic;
signal clear_count_p1       : std_logic;
signal new_count            : std_logic_vector(0 to 4) := (others => '0');
signal count                : std_logic_vector(0 to 4) := (others => '0');
signal ratio                : std_logic_vector(0 to 4) := (others => '0');
signal ratio_minus1         : std_logic_vector(0 to 4) := (others => '0');
signal slow_clk_div2        : std_logic := '0'; -- slow_clk_div2 = half freq. of slow_clk Clock
signal slow_clk_div2_del    : std_logic := '0';
signal clk_1_to_1           : std_logic := '0';
signal scnd_slwclk_pair     : std_logic_vector(0 to 4) := (others => '0');
signal frst_slwclk_pair     : std_logic_vector(0 to 4) := (others => '0');
signal sync_rst_i           : std_logic;
--signal sample_cycle_set     : std_logic;
signal sc2ad_sample_cycle_i : std_logic;
signal sc2rd_sample_cycle_i : std_logic;
signal sc2wr_sample_cycle_i : std_logic;

signal mpmc_rst_pipe        : std_logic_vector(0 to 1);
signal plb_rst_pipe         : std_logic_vector(0 to 1);




-------------------------------------------------------------------------------
-- Attribute Declarations
-------------------------------------------------------------------------------
-- Register duplication attribute assignments
Attribute KEEP : string; -- declaration
Attribute KEEP of sc2ad_sample_cycle_i   : signal is "TRUE"; -- definition
Attribute KEEP of sc2rd_sample_cycle_i   : signal is "TRUE"; -- definition
Attribute KEEP of sc2wr_sample_cycle_i   : signal is "TRUE"; -- definition

Attribute EQUIVALENT_REGISTER_REMOVAL : string;
Attribute EQUIVALENT_REGISTER_REMOVAL of sc2ad_sample_cycle_i : signal is "no";
Attribute EQUIVALENT_REGISTER_REMOVAL of sc2rd_sample_cycle_i : signal is "no";
Attribute EQUIVALENT_REGISTER_REMOVAL of sc2wr_sample_cycle_i : signal is "no";

Attribute MAX_FANOUT : string;
Attribute MAX_FANOUT of plb_rst_pipe : signal is "30";


-------------------------------------------------------------------------------
begin

-- #1 is for simulation, build a toggle FF in
-- slow_clk. This creates a half frequency signal.
SLOW_CLOCK_TGL : process(slow_clk)
    begin
        if(slow_clk'EVENT and slow_clk='1')then
            slow_clk_div2 <= not slow_clk_div2;
        end if;
    end process SLOW_CLOCK_TGL;

-- align slow clocked toggle signal into fast clk.
ALIGN_TO_FAST : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            slow_clk_div2_del <= slow_clk_div2;
        end if;
    end process ALIGN_TO_FAST;

-- Detect the rising edge of the slow_clk_div2 to clear the slow_clk sample counter.
clear_count <= (slow_clk_div2 and not slow_clk_div2_del);

SMPL_COUNTER : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if(clear_count = '1')then
                count <= (others => '0');
            else
                count <= std_logic_vector(unsigned(count) + 1);
            end if;
        end if;
    end process SMPL_COUNTER;

GRAB_RATIO : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if(clear_count = '1')then
                ratio <= count;
            end if;
        end if;
    end process GRAB_RATIO;

-- Create a new counter that runs earlier than above counter.
-- This counter runs ahead to find the cycle just before
-- the slow clock's rising edge transitions

RATIO_SUB1 : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            ratio_minus1 <= std_logic_vector(unsigned(ratio) - 1);
        end if;
    end process RATIO_SUB1;

clear_count_p1 <= '1' when count(0 to 4) = ratio_minus1
             else '0';

NEW_COUNTER : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if (clear_count_p1='1')then
                new_count <= "00001";
            else
                new_count <= std_logic_vector(unsigned(new_count) + 1);
            end if;
        end if;
    end process NEW_COUNTER;


CLK1TO1 : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if(ratio(0 to 3) = "0000")then
                clk_1_to_1 <= '1';
            else
                clk_1_to_1 <= '0';
            end if;
        end if;
    end process CLK1TO1;

    sc2ad_clk_ratio_1_1 <= clk_1_to_1;

-- Generate sample_cycle signal and drive from the output of a FF for better timing.
-- implement sample_cycle as a Flip Flop with Set input

scnd_slwclk_pair <= ratio(0 to 3) & '1';
frst_slwclk_pair <= '0' & ratio(0 to 3);

--SMPL_CYCLE : process(fast_clk)
--    begin
--        if(fast_clk'EVENT and fast_clk='1')then
--            if (clk_1_to_1 = '1')then
--                sample_cycle_i <= '1';                       -- 1:1 slow_clk/fast_clk ratios
--            elsif(new_count = scnd_slwclk_pair or          -- Second slow_clk cycle in the pair
--                  new_count = frst_slwclk_pair)then        -- First slow_clk cycle in the pair
--                sample_cycle_i <= '1';
--            else
--                sample_cycle_i <= '0';
--            end if;
--        end if;
--    end process SMPL_CYCLE;
--
--    sample_cycle <= sample_cycle_i;
--

SMPL_CYCLE_ASM : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if (clk_1_to_1 = '1')then
                sc2ad_sample_cycle_i <= '1';                       -- 1:1 slow_clk/fast_clk ratios
            elsif(new_count = scnd_slwclk_pair or          -- Second slow_clk cycle in the pair
                  new_count = frst_slwclk_pair)then        -- First slow_clk cycle in the pair
                sc2ad_sample_cycle_i <= '1';
            else
                sc2ad_sample_cycle_i <= '0';
            end if;
        end if;
    end process SMPL_CYCLE_ASM;

    sc2ad_sample_cycle <= sc2ad_sample_cycle_i;


SMPL_CYCLE_RSM : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if (clk_1_to_1 = '1')then
                sc2rd_sample_cycle_i <= '1';                       -- 1:1 slow_clk/fast_clk ratios
            elsif(new_count = scnd_slwclk_pair or          -- Second slow_clk cycle in the pair
                  new_count = frst_slwclk_pair)then        -- First slow_clk cycle in the pair
                sc2rd_sample_cycle_i <= '1';
            else
                sc2rd_sample_cycle_i <= '0';
            end if;
        end if;
    end process SMPL_CYCLE_RSM;
    sc2rd_sample_cycle <= sc2rd_sample_cycle_i;


SMPL_CYCLE_WSM : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if (clk_1_to_1 = '1')then
                sc2wr_sample_cycle_i <= '1';                       -- 1:1 slow_clk/fast_clk ratios
            elsif(new_count = scnd_slwclk_pair or          -- Second slow_clk cycle in the pair
                  new_count = frst_slwclk_pair)then        -- First slow_clk cycle in the pair
                sc2wr_sample_cycle_i <= '1';
            else
                sc2wr_sample_cycle_i <= '0';
            end if;
        end if;
    end process SMPL_CYCLE_WSM;
   sc2wr_sample_cycle <= sc2wr_sample_cycle_i;


-------------------------------------------------------------------------------
-- Create a synchronous reset for the read and write modules
-- Deasserts reset when sample cycle is asserted after reset
-------------------------------------------------------------------------------
RESET_EXTEND : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if rst = '1' then
                sync_rst_i <= '1';
            elsif (sync_rst_i = '1' and sc2ad_sample_cycle_i = '1') then
                sync_rst_i <= '0';
            else
                sync_rst_i <= sync_rst_i;
            end if;
        end if;
    end process;

    sync_rst <= sync_rst_i;

-------------------------------------------------------------------------------
-- Create a synchronous reset for the read and write modules
-- Deasserts reset when sample cycle is asserted after reset
-------------------------------------------------------------------------------
MPMC_RESET_EXTEND : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if rst = '1' then
                mpmc_rst_pipe(0) <= '1';
                mpmc_rst_pipe(1) <= '1';
            else
                mpmc_rst_pipe(0) <= '0';
                mpmc_rst_pipe(1) <= mpmc_rst_pipe(0);
            end if;
        end if;
    end process;

    mpmc_rst <= mpmc_rst_pipe(1);

-------------------------------------------------------------------------------
-- Create a synchronous reset for the read and write modules
-- Deasserts reset when sample cycle is asserted after reset
-------------------------------------------------------------------------------
PLB_RESET_EXTEND : process(slow_clk)
    begin
        if(slow_clk'EVENT and slow_clk='1')then
            if rst = '1' then
                plb_rst_pipe(0) <= '1';
                plb_rst_pipe(1) <= '1';
            else
                plb_rst_pipe(0) <= '0';
                plb_rst_pipe(1) <= plb_rst_pipe(0);
            end if;
        end if;
    end process;

    plb_rst <= plb_rst_pipe(1);


-- START -code for direct instantiation of flip flops
---------------------------------------------------------------------------------
----  Set Logic for Direct Flip-Flop instantiations
---------------------------------------------------------------------------------
--    sample_cycle_set <=
--      '1' when clk_1_to_1 = '1' or
--               (new_count = scnd_slwclk_pair or new_count = frst_slwclk_pair)
--          else
--      '0';
--
---------------------------------------------------------------------------------
----  Individual sample cycle signal for address_decoder.vhd
---------------------------------------------------------------------------------
--     ASM_SAMPLE_CYCLE : FDS
--        port map(
--          Q     =>  sc2ad_sample_cycle_i, -- : out std_logic;
--          C     =>  fast_clk      ,     -- : in  std_logic;
--          D     =>  '0'           ,     -- : in  std_logic;
--          S     =>  sample_cycle_set    -- : in  std_logic
--        );
--
--     sc2ad_sample_cycle <= sc2ad_sample_cycle_i;
--
---------------------------------------------------------------------------------
----  Individual sample cycle signal for write_module.vhd
---------------------------------------------------------------------------------
--     WSM_SAMPLE_CYCLE : FDS
--        port map(
--          Q     =>  sc2wr_sample_cycle, -- : out std_logic;
--          C     =>  fast_clk      ,     -- : in  std_logic;
--          D     =>  '0'           ,     -- : in  std_logic;
--          S     =>  sample_cycle_set    -- : in  std_logic
--        );
--
---------------------------------------------------------------------------------
----  Individual sample cycle signal for rd_support.vhd
---------------------------------------------------------------------------------
--     RSM_SAMPLE_CYCLE : FDS
--        port map(
--          Q     =>  sc2rd_sample_cycle, -- : out std_logic;
--          C     =>  fast_clk      ,     -- : in  std_logic;
--          D     =>  '0'           ,     -- : in  std_logic;
--          S     =>  sample_cycle_set    -- : in  std_logic
--        );
-- END -code for direct instantiation of flip flops


end implementation;

