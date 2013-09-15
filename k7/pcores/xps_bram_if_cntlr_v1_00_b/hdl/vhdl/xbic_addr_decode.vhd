-------------------------------------------------------------------------------
-- $Id: xbic_addr_decode.vhd,v 1.2.2.1 2008/12/16 22:23:17 dougt Exp $
-------------------------------------------------------------------------------
-- xbic_addr_decode.vhd
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
-- Filename:        xbic_addr_decode.vhd
-- Version:         v1_00_a
-- Description:     Simple address decoder function for one Base Addr Pair.
--
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
-- Author:      D. Thorpe
-- History:
--
--      DET        Feb-5-07
-- ~~~~~~
--      -- Special version for the XPS BRAM IF Cntlr that is adapted
--         from xps_bram_if_cntlr_v1_00_a library
--      -- Bypassed input address and qualifiers registering to remove
--         one clock of latency during address phase.
-- ^^^^^^
--
--     DET     5/24/2007     Jm
-- ~~~~~~
--     - Recoded to utilize behavorial address decode instead of calling
--       the pselect_f module from proc common. This reduced the timing
--       problem paths found with the pselect_f decoder in Spartan3x
--       devices.
-- ^^^^^^
--
--     DET     8/25/2008     v1_00_b
-- ~~~~~~
--     - Updated to proc_common_v3_00_a library.
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
--      user defined types:                     "*_type"
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
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.family_support.all;

-- Xilinx Primitive Library
library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity xbic_addr_decode is
    generic (
        C_SPLB_AWIDTH           : integer := 32;
        C_SPLB_NATIVE_DWIDTH    : integer := 32;
        C_ARD_ADDR_RANGE_ARRAY  : SLV64_ARRAY_TYPE :=                              
          (                                                            
           X"0000_0000_1000_0000", --  IP user0 base address       
           X"0000_0000_1000_01FF"  --  IP user0 high address       
          );                                                                    
        C_FAMILY                : string  := "virtex5"
    );   
  port (
        -- PLB Interface signals
        Address_In          : in  std_logic_vector(0 to 
                                  C_SPLB_AWIDTH-1);
        Address_Valid       : in  std_logic;

    
        -- Decode output signals
        Addr_Match          : out std_logic
         
    );
end entity xbic_addr_decode;

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

architecture implementation of xbic_addr_decode is


-- local type declarations ----------------------------------------------------
type decode_bit_array_type is Array(natural range 0 to (
                           (C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1) of 
                           integer;

type short_addr_array_type is Array(natural range 0 to 
                           C_ARD_ADDR_RANGE_ARRAY'LENGTH-1) of 
                           std_logic_vector(0 to C_SPLB_AWIDTH-1);

 
 
 
-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- This function converts a 64 bit address range array to a AWIDTH bit 
-- address range array.
-------------------------------------------------------------------------------
function slv64_2_slv_awidth(slv64_addr_array   : SLV64_ARRAY_TYPE;
                            awidth             : integer) 
                        return short_addr_array_type is

    variable temp_addr   : std_logic_vector(0 to 63);
    variable slv_array   : short_addr_array_type;
    begin
        for array_index in 0 to slv64_addr_array'length-1 loop
            temp_addr := slv64_addr_array(array_index);
            slv_array(array_index) := temp_addr((64-awidth) to 63);
        end loop; 
        return(slv_array);
    end function slv64_2_slv_awidth;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function Addr_Bits (x,y : std_logic_vector(0 to C_SPLB_AWIDTH-1)) 
                    return integer is
    variable addr_nor : std_logic_vector(0 to C_SPLB_AWIDTH-1);
    begin
        addr_nor := x xor y;
        for i in 0 to C_SPLB_AWIDTH-1 loop
            if addr_nor(i)='1' then 
                return i;
            end if;
        end loop;
        return(C_SPLB_AWIDTH);
    end function Addr_Bits;

 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function Get_Addr_Bits (baseaddrs : short_addr_array_type) 
                        return decode_bit_array_type is
 
    variable num_bits : decode_bit_array_type;
    begin
        for i in 0 to ((baseaddrs'length)/2)-1 loop
   
            num_bits(i) :=  Addr_Bits (baseaddrs(i*2), 
                                       baseaddrs(i*2+1));
        end loop;
        return(num_bits);
    end function Get_Addr_Bits;
 
 
 
 
 
 
 
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

constant ARD_ADDR_RANGE_ARRAY   : short_addr_array_type :=
                                    slv64_2_slv_awidth(C_ARD_ADDR_RANGE_ARRAY,
                                                       C_SPLB_AWIDTH);

constant DECODE_BITS         : decode_bit_array_type := 
                                    Get_Addr_Bits(ARD_ADDR_RANGE_ARRAY);
 
 Constant NUM_BITS_TO_DECODE : integer := DECODE_BITS(0);
 
 
 constant BASE_ADDR_BITS_TO_USE : unsigned(0 to NUM_BITS_TO_DECODE-1) := 
              UNSIGNED(ARD_ADDR_RANGE_ARRAY(0)(0 to NUM_BITS_TO_DECODE-1));

 
 
 ----------------------------------------------------------------
 -- Signals
 ----------------------------------------------------------------
 
 signal decode_hit       : std_logic;
 Signal sig_input_addr_bits_to_use : unsigned(0 to NUM_BITS_TO_DECODE-1);
  
 
 
 
-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin -- architecture IMP
  
 
  Addr_Match <= decode_hit;
 
  -- rip only the bits needed for the address range decode
  sig_input_addr_bits_to_use <= UNSIGNED(Address_In(0 to NUM_BITS_TO_DECODE-1));
 
  -- Behavorial compare of input address decode bits to the Base address
  -- decode bits
  decode_hit <= '1'
    When (sig_input_addr_bits_to_use = BASE_ADDR_BITS_TO_USE)
    Else '0';




end implementation;
