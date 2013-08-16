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
-- Filename - vfbc_arbiter.vhd
-- Author - Mankit Lo, Xilinx
-- Creation - July 25th, 2006
--
--*******************************************************************
--
-- Description - VFBC Arbiter
--               This is an almost combinational arbiter.  
--               VFBC only need an arbitration result every 4 cycles.
--               As a result, a simple arbiter like this can be used.
--               The request is expected to be cleared by the grant 
--               signal within 4 cycles too.
--
--*******************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.memxlib_utils.all;

entity vfbc_arbitrator is 
  generic(
    NUM_PORTS   : natural := 8;         -- Number of Ports
    BA_SIZE     : natural := 2;         -- Bank Address Size
    REAL_TIME   : std_logic_vector := "1010101010101010"; -- Port is Real Time when high
    LOW_LATENCY : std_logic_vector := "0000000000000000"; -- Port is Low Latency when high
    SCHEME      : string := "DEFAULT" -- Choices are "ROUNDROBIN" and "DEFAULT"
  );
  port(
    -- Common interface
    clk                 : in  std_logic; -- VFBC/MPMC_CLk0 Clock
    clken               : in  std_logic; -- Clock Enable
    srst                : in  std_logic; -- Synchronous Reset

    -- Command Interface

    cmd_bank            : in  std_logic_vector(NUM_PORTS*BA_SIZE-1 downto 0) := (others => '0'); -- Indicates the memory bank which
                                                                                                 -- the command is operating on
    cmd_request         : in  std_logic_vector(NUM_PORTS-1 downto 0);                    -- Port Request           
    cmd_burst_request   : in  std_logic_vector(NUM_PORTS-1 downto 0) := (others => '0'); -- Port Long Burst Request
    cmd_granted         : out std_logic_vector(NUM_PORTS-1 downto 0);                    -- Selected Port. One-hot. Active High
    cmd_granted_port_id : out std_logic_vector(logbase2(NUM_PORTS-1)-1 downto 0);        -- Port ID of the granted port
    cmd_grant           : out std_logic;                                                 -- a grant has been asserted.
    cmd_wr_op           : in  std_logic_vector(NUM_PORTS-1 downto 0) := (others => '1'); -- Current command is a write transfer.
                                                                                         -- Active high

    -- WRITE FIFOs Interface
    wr_almost_full      : in  std_logic_vector(NUM_PORTS-1 downto 0) := (others => '0'); -- Write FIFOs Almost Full Flags
    wr_flush            : in  std_logic_vector(NUM_PORTS-1 downto 0) := (others => '0'); -- Request write flush on port
                                                                                         -- In command or in tag bits in ObjFIFO
    -- READ  FIFOs Interface 
    rd_almost_empty     : in std_logic_vector(NUM_PORTS-1 downto 0) := (others => '0')   -- Read FIFOs Almost Empty Flags
  );
end vfbc_arbitrator;

architecture rtl of vfbc_arbitrator is

signal    AlmostFullEmpty : std_logic_vector(NUM_PORTS-1 downto 0);
signal    Flush : std_logic_vector(NUM_PORTS-1 downto 0);

signal XFF_intGranted : std_logic_vector(NUM_PORTS-1 downto 0);
signal XFF_intGrantedPortID : std_logic_vector(logbase2(NUM_PORTS-1)-1 downto 0);
signal XFF_GrantedBank : std_logic_vector(BA_SIZE-1 downto 0);
signal XFF_PrevAccessIsWrite : std_logic;

constant ZEROS : std_logic_vector(99 downto 0) := (others => '0');

begin

AlmostFullEmpty <= (cmd_wr_op and wr_almost_full) or ((not cmd_wr_op) and rd_almost_empty);
--Flush <= cmd_wr_op and wr_flush;

GenDefault: IF SCHEME = "DEFAULT" GENERATE
process(clk)
variable ArbDone : std_logic;
variable temp_y : natural;
variable y : natural range 0 to NUM_PORTS-1;
begin
if rising_edge(clk) then
        if srst = '1' then
            XFF_intGranted <= (others => '0');
            cmd_grant <= '0';
            XFF_intGrantedPortID <= (others => '0');
            XFF_GrantedBank <= (others => '0');
            XFF_PrevAccessIsWrite <= '0';
        elsif (clken = '1') then

            ArbDone := '0';
            XFF_intGranted <= (others => '0');
            XFF_intGrantedPortID <= (others => '0');
            XFF_GrantedBank <= (others => '0');
            XFF_PrevAccessIsWrite <= '0';
            -- Low Latency Loop
            for x in 0 to NUM_PORTS-1 loop
                temp_y := conv_integer(XFF_intGrantedPortID) + x + 1;
                if temp_y >= NUM_PORTS then
                    y := temp_y - NUM_PORTS;
                else
                    y := temp_y;
                end if;
                if ArbDone = '0' and cmd_request(y) = '1' and (XFF_intGranted(y) /= '1') and LOW_LATENCY(y) = '1' then
                    XFF_intGranted(y) <= '1'; 
                    XFF_intGrantedPortID <= conv_std_logic_vector(y,XFF_intGrantedPortID'length); 
                    ArbDone := '1'; 
                    XFF_GrantedBank <= cmd_bank(2*y+1 downto 2*y);
                    XFF_PrevAccessIsWrite <= cmd_wr_op(y);
                elsif ArbDone = '0' and cmd_burst_request(y) = '1' and LOW_LATENCY(y) = '1' then -- okay to grant the same device
                                                                                                 -- again if it is a burst request
                    XFF_intGranted(y) <= '1'; 
                    XFF_intGrantedPortID <= conv_std_logic_vector(y,XFF_intGrantedPortID'length); 
                    ArbDone := '1'; 
                    XFF_GrantedBank <= cmd_bank(2*y+1 downto 2*y);
                    XFF_PrevAccessIsWrite <= cmd_wr_op(y);
                end if;
            end loop;
            for x in 0 to NUM_PORTS-1 loop
                if ArbDone = '0' and XFF_intGranted(x) = '0' and cmd_request(x) = '1'  and LOW_LATENCY(x) = '0' then
                    if REAL_TIME(x) = '1' and AlmostFullEmpty(x) = '1' and (cmd_bank(2*x+1 downto 2*x) /= XFF_GrantedBank) and
                     (XFF_PrevAccessIsWrite = cmd_wr_op(x)) then
                        XFF_intGranted(x) <= '1'; 
                        XFF_intGrantedPortID <= conv_std_logic_vector(x,XFF_intGrantedPortID'length); 
                        ArbDone := '1'; 
                        XFF_GrantedBank <= cmd_bank(2*x+1 downto 2*x);
                        XFF_PrevAccessIsWrite <= cmd_wr_op(x);
                    end if;
                end if;
            end loop;
            for x in 0 to NUM_PORTS-1 loop
                if ArbDone = '0' and XFF_intGranted(x) = '0' and cmd_request(x) = '1'  and LOW_LATENCY(x) = '0' then
                    if REAL_TIME(x) = '1' and AlmostFullEmpty(x) = '1' and (XFF_PrevAccessIsWrite = cmd_wr_op(x)) then
                        XFF_intGranted(x) <= '1'; 
                        XFF_intGrantedPortID <= conv_std_logic_vector(x,XFF_intGrantedPortID'length); 
                        ArbDone := '1'; 
                        XFF_GrantedBank <= cmd_bank(2*x+1 downto 2*x);
                        XFF_PrevAccessIsWrite <= cmd_wr_op(x);
                    end if;
                end if;
            end loop;
            for x in 0 to NUM_PORTS-1 loop
                if ArbDone = '0' and XFF_intGranted(x) = '0' and cmd_request(x) = '1'  and LOW_LATENCY(x) = '0' then
                    if REAL_TIME(x) = '1' and AlmostFullEmpty(x) = '1' then
                        XFF_intGranted(x) <= '1'; 
                        XFF_intGrantedPortID <= conv_std_logic_vector(x,XFF_intGrantedPortID'length); 
                        ArbDone := '1'; 
                        XFF_GrantedBank <= cmd_bank(2*x+1 downto 2*x);
                        XFF_PrevAccessIsWrite <= cmd_wr_op(x);
                    end if;
                end if;
            end loop;
            for x in 0 to NUM_PORTS-1 loop
                if ArbDone = '0' and XFF_intGranted(x) = '0' and cmd_request(x) = '1'  and LOW_LATENCY(x) = '0' then
                    if AlmostFullEmpty(x) = '1' and (cmd_bank(2*x+1 downto 2*x) /= XFF_GrantedBank) and (XFF_PrevAccessIsWrite =
                     cmd_wr_op(x)) then
                        XFF_intGranted(x) <= '1'; 
                        XFF_intGrantedPortID <= conv_std_logic_vector(x,XFF_intGrantedPortID'length); 
                        ArbDone := '1'; 
                        XFF_GrantedBank <= cmd_bank(2*x+1 downto 2*x);
                        XFF_PrevAccessIsWrite <= cmd_wr_op(x);
                    end if;
                end if;
            end loop;
            for x in 0 to NUM_PORTS-1 loop
                if ArbDone = '0' and XFF_intGranted(x) = '0' and cmd_request(x) = '1'  and LOW_LATENCY(x) = '0' then
                    if AlmostFullEmpty(x) = '1' and (XFF_PrevAccessIsWrite = cmd_wr_op(x)) then
                        XFF_intGranted(x) <= '1'; 
                        XFF_intGrantedPortID <= conv_std_logic_vector(x,XFF_intGrantedPortID'length); 
                        ArbDone := '1'; 
                        XFF_GrantedBank <= cmd_bank(2*x+1 downto 2*x);
                        XFF_PrevAccessIsWrite <= cmd_wr_op(x);
                    end if;
                end if;
            end loop;
            for x in 0 to NUM_PORTS-1 loop
                if ArbDone = '0' and XFF_intGranted(x) = '0' and cmd_request(x) = '1'  and LOW_LATENCY(x) = '0' then
                    if AlmostFullEmpty(x) = '1' then
                        XFF_intGranted(x) <= '1'; 
                        XFF_intGrantedPortID <= conv_std_logic_vector(x,XFF_intGrantedPortID'length); 
                        ArbDone := '1';
                        XFF_GrantedBank <= cmd_bank(2*x+1 downto 2*x);
                        XFF_PrevAccessIsWrite <= cmd_wr_op(x);
                    end if;
                end if;
            end loop;
            for x in 0 to NUM_PORTS-1 loop
                if ArbDone = '0' and XFF_intGranted(x) = '0' and cmd_request(x) = '1'  and LOW_LATENCY(x) = '0' then
                        XFF_intGranted(x) <= '1'; 
                        XFF_intGrantedPortID <= conv_std_logic_vector(x,XFF_intGrantedPortID'length); 
                        ArbDone := '1'; 
                        XFF_GrantedBank <= cmd_bank(2*x+1 downto 2*x);
                        XFF_PrevAccessIsWrite <= cmd_wr_op(x);
                end if;
            end loop;
            for x in 0 to NUM_PORTS-1 loop
                if ArbDone = '0' and cmd_burst_request(x) = '1' and LOW_LATENCY(x) = '0' then -- okay to grant the same device
                                                                                              -- again if it is a burst request
                        XFF_intGranted(x) <= '1'; 
                        XFF_intGrantedPortID <= conv_std_logic_vector(x,XFF_intGrantedPortID'length); 
                        ArbDone := '1'; 
                        XFF_GrantedBank <= cmd_bank(2*x+1 downto 2*x);
                        XFF_PrevAccessIsWrite <= cmd_wr_op(x);
                end if;
            end loop;            
            cmd_grant <= ArbDone;
        end if;
end if;
end process;

END GENERATE;

GenRoundRobin : IF SCHEME = "ROUNDROBIN" GENERATE
process(clk)
variable ArbDone : std_logic;
variable temp_y : natural;
variable y : natural range 0 to NUM_PORTS-1;
begin
if rising_edge(clk) then
    if srst = '1' then
        XFF_intGranted <= (others => '0');
        cmd_grant <= '0';
        XFF_intGrantedPortID <= (others => '0');
    elsif (clken = '1') then
        ArbDone := '0';
        XFF_intGranted <= (others => '0');
        XFF_intGrantedPortID <= (others => '0');
        -- Low Latency Loop
        for x in 0 to NUM_PORTS-1 loop
            temp_y := conv_integer(XFF_intGrantedPortID) + x + 1;
            if temp_y >= NUM_PORTS then
                y := temp_y - NUM_PORTS;
            else
                y := temp_y;
            end if;
            if ArbDone = '0' and cmd_request(y) = '1' and (XFF_intGranted(y) /= '1') and LOW_LATENCY(y) = '1' then
                XFF_intGranted(y) <= '1'; 
                XFF_intGrantedPortID <= conv_std_logic_vector(y,XFF_intGrantedPortID'length); 
                ArbDone := '1'; 
            elsif ArbDone = '0' and cmd_burst_request(y) = '1' and LOW_LATENCY(y) = '1' then -- okay to grant the same device again
                                                                                             -- if it is a burst request
                XFF_intGranted(y) <= '1'; 
                XFF_intGrantedPortID <= conv_std_logic_vector(y,XFF_intGrantedPortID'length); 
                ArbDone := '1'; 
            end if;
        end loop;
        -- Regular Loop
        for x in 0 to NUM_PORTS-1 loop
            temp_y := conv_integer(XFF_intGrantedPortID) + x + 1;
            if temp_y >= NUM_PORTS then
                y := temp_y - NUM_PORTS;
            else
                y := temp_y;
            end if;
            if ArbDone = '0' and cmd_request(y) = '1' and (XFF_intGranted(y) /= '1') and LOW_LATENCY(y) = '0' then
                XFF_intGranted(y) <= '1'; 
                XFF_intGrantedPortID <= conv_std_logic_vector(y,XFF_intGrantedPortID'length); 
                ArbDone := '1'; 
            elsif ArbDone = '0' and cmd_burst_request(y) = '1'  and LOW_LATENCY(y) = '0' then -- okay to grant the same device
                                                                                              -- again if it is a burst request
                XFF_intGranted(y) <= '1'; 
                XFF_intGrantedPortID <= conv_std_logic_vector(y,XFF_intGrantedPortID'length); 
                ArbDone := '1'; 
            end if;
        end loop;
        cmd_grant <= ArbDone;
    end if;
end if;
end process;
END GENERATE;

cmd_granted_port_id <= XFF_intGrantedPortID;
cmd_granted <= XFF_intGranted(NUM_PORTS-1 downto 0);

end rtl;

