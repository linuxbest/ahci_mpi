-------------------------------------------------------------------------------
-- $Id: xbic_be_reset_gen.vhd,v 1.2.2.1 2008/12/16 22:23:17 dougt Exp $
-------------------------------------------------------------------------------
-- xbic_be_reset_gen - entity / architecture pair
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright  2007, 2008, 2009 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Filename:        xbic_be_reset_gen.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--
--             xps_bram_if_cntlr.vhd
--                 |
--                 |- xbic_slave_attach_sngl
--                 |       |
--                 |       |- xbic_addr_decode
--                 |       |- xbic_addr_be_support
--                 |       |- xbic_data_steer_mirror
--                 |
--                 |- xbic_slave_attach_burst
--                         |
--                         |- xbic_addr_decode
--                         |- xbic_addr_be_support
--                         |- xbic_data_steer_mirror
--                         |- xbic_addr_cntr
--                         |       |
--                         |       |- xbic_be_reset_gen.vhd
--                         |
--                         |- xbic_dbeat_control
--                         |- xbic_data_steer_mirror
--
--
-------------------------------------------------------------------------------
-- Author:          GAB
--
-- History:
--
--      DET        Feb-5-07
-- ~~~~~~
--      -- Special version for the XPS BRAM IF Cntlr that is adapted
--         from plbv46_slave_burst_V1_00_a library
-- ^^^^^^
--
--     DET     3/6/2007     Reduced latency revision
-- ~~~~~~
--  - Added missing 64-bit case for when C_SMALLEST = 32 and C_NATIVE_DWIDTH=128.
--    this cause bus2ip_be to be driven incorrectly for address offets 0x4,
--    0x5, 0x6,and 0x7.
-- ^^^^^^
--
--     DET     5/24/2007     Jm
-- ~~~~~~
--     - Changed the design to output active low BE reset mask.
--     - Modifed output Mask width to be the full width of the BE bus.
-- ^^^^^^
-- 
--     DET     9/9/2008     v1_00_b for EDK 11.x release
-- ~~~~~~
--     - Updated Disclaimer in header section.
-- ^^^^^^
--
--     DET     12/16/2008     v1_01_b
-- ~~~~~~
--     - Updated eula/header to latest version.
-- ^^^^^^
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity xbic_be_reset_gen is
    generic (
        C_NATIVE_DWIDTH   : integer := 32;
        C_SMALLEST        : integer := 32
    );
    port(
       Addr         : in std_logic_vector(0 to 1);
       MSize        : in std_logic_vector(0 to 1);
       
       BE_Sngl_Mask  : out std_logic_vector(0 to (C_NATIVE_DWIDTH/8) - 1)
    );
end entity xbic_be_reset_gen;

architecture implementation of xbic_be_reset_gen is


-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal reset_be_extended   : std_logic_vector(0 to (C_NATIVE_DWIDTH/8) - 1);


------------------------------------------------------------------------------
-- Architecture BEGIN
------------------------------------------------------------------------------
begin

BE_Sngl_Mask <= not(reset_be_extended);


GEN_FOR_SAME : if C_NATIVE_DWIDTH <= C_SMALLEST generate
    
    reset_be_extended <=  (others => '0');
    
end generate GEN_FOR_SAME;

                   
                   
---------------------
-- 64 Bit Support --
---------------------
  GEN_BE_64_32: if C_NATIVE_DWIDTH = 64 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Addr,MSize) 
     begin
 
       addr_bits <= Addr(1);   --a29
       reset_be_extended <= (others => '0');
        case addr_bits is

         when '0' => 
           case MSize is
             when "00" =>  -- 32-Bit Master 
               reset_be_extended <= "00001111";
                
             when others => null;
           end case;
             
         when '1' => 
           case MSize is
             when "00" =>  -- 32-Bit Master 
               reset_be_extended <= "11110000";
             when others => null;
           end case;
        when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_BE_64_32;

---------------------
-- 128 Bit Support --
---------------------
  GEN_BE_128_32: if C_NATIVE_DWIDTH = 128 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic_vector(0 to 1);
   begin
     CONNECT_PROC: process (addr_bits,Addr,MSize) 
     begin
 
       addr_bits <= Addr;   --  24 25 26 27 | 28 29 30 31
       reset_be_extended <= (others => '0');
        case addr_bits is
         when "00" => --0
           case MSize is
             when "00" => -- 32-Bit Master
                reset_be_extended <= "0000111111111111";
                
             when "01" => -- 64-Bit Master
                reset_be_extended <= "0000000011111111";
             when others => null;
           end case;

         when "01" => --4
           case MSize is
             when "00" => -- 32-Bit Master
                reset_be_extended <= "1111000011111111";
             when "01" => -- 64-Bit Master      -- GAB 12/22/06
                reset_be_extended <= "0000000011111111";
             when others => null;
           end case;
         when "10" => --8
           case MSize is
             when "00" => --  32-Bit Master
                reset_be_extended <= "1111111100001111";
             when "01" => --  64-Bit Master
                reset_be_extended <= "1111111100000000";
             when others => null;
           end case;
         when "11" => --C
           case MSize is
             when "00" => --32-Bit Master
                reset_be_extended <= "1111111111110000";
             when "01" => --64-Bit Master
                reset_be_extended <= "1111111100000000";
             when others => null;
           end case;
         when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_BE_128_32;

  GEN_BE_128_64: if C_NATIVE_DWIDTH = 128 and C_SMALLEST = 64 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Addr,MSize) 
     begin
       addr_bits <= Addr(0);   
       reset_be_extended <= (others => '0');
        case addr_bits is
          when '0' =>
           case MSize is
             when "01" => -- 64-Bit Master
                reset_be_extended <= "0000000011111111";
             when others => null;
           end case;

         when '1' => --8
           case MSize is
             when "01" => -- 64-Bit Master
                reset_be_extended <= "1111111100000000";
             when others => null;
           end case;
          when others =>
            null;
      end case;      
    end process CONNECT_PROC;
   end generate GEN_BE_128_64;
   
   
end implementation; -- (architecture)

