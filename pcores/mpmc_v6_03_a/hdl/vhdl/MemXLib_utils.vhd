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
-- Filename: MemXlib_utils.vhd
--
-- Description: Utilities for behavioral and structural use in
--              Memory Xilinx library
--
--
--                  Authors: Robert Turney
--                           Paul Schumacher
--
--                  Xilinx Research Labs
--                  Xilinx, Inc.
--
--
--                  Date:   July 21, 1999
--                  For:    Xilinx library utilities
--
--                  RESTRICTED RIGHTS LEGEND
--
--      This software has not been published by the author, and
--      has been disclosed to others for the purpose of enhancing
--      and promoting design productivity in Xilinx products.
--
--      Therefore use, duplication or disclosure, now and in the
--      future should give consideration to the productivity
--      enhancements afforded the user of this code by the author's
--      efforts.  Thank you for using our products !
--
-- Disclaimer:  THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY
--              WHATSOEVER AND XILINX SPECIFICALLY DISCLAIMS ANY
--              IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
--              A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
--
--
-- Revision:
--    07/21/99  BT  Original file creation
--
-- ************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

PACKAGE memxlib_utils IS

-- ------------------------------------------------------------------------ --
-- TYPES:                                    --
-- ------------------------------------------------------------------------ --
TYPE integer_array IS ARRAY ( NATURAL RANGE <>) OF integer;

-- ------------------------------------------------------------------------ --
-- CONSTANTS:                                  --
-- ------------------------------------------------------------------------ --

attribute INIT : string;

-- Synthesis RAM styles
-- Uncomment for XST
--constant DIST_RAMSTYLE : string := "distributed";
--constant BLOCK_RAMSTYLE : string := "block";
-- Uncomment for Synplicity
constant DIST_RAMSTYLE : string := "select_ram";
constant BLOCK_RAMSTYLE : string := "no_rw_check, area";

-- ------------------------------------------------------------------------ --
-- SIMULATION CONSTANTS:                            --
-- ------------------------------------------------------------------------ --


-- ------------------------------------------------------------------------ --
-- XNF ATTRIBUTES DECLARATIONS:                          --
-- ------------------------------------------------------------------------ --


-- ------------------------------------------------------------------------ --
-- FUNCTION PROTOTYPES:                              --
-- ------------------------------------------------------------------------ --
function logbase2(data : integer) return integer;
function CEIL_DIVIDE(a : integer; 
                     b: integer) return integer;


-- ------------------------------------------------------------------------ --
-- SIMULATION FUNCTION PROTOTYPES:                        --
-- ------------------------------------------------------------------------ --


-- ------------------------------------------------------------------------ --
-- COMPONENT DECLARATIONS:                                 --
-- ------------------------------------------------------------------------ --


END memxlib_utils;

PACKAGE BODY memxlib_utils IS
-- ------------------------------------------------------------------------
-- FUNCTIONS:
-- ------------------------------------------------------------------------
  function logbase2(data : integer) return integer is
    variable count_bits : integer := 0;
    variable data_std : std_logic_vector(31 downto 0) := CONV_STD_LOGIC_VECTOR(data,32);
  begin
    for I in data_std'range loop
      if (not (data_std = 0)) then
        count_bits := count_bits + 1;
        data_std := CONV_STD_LOGIC_VECTOR(CONV_INTEGER(data_std)/2,32);
      end if;
    end loop;

    if count_bits = 0 then
        return 1;
    else
        return count_bits;
    end if;

  end;


  function CEIL_DIVIDE(
        a : integer; 
        b: integer
        ) return integer is
  begin
        return a/b + 1 - (b - a + b*(a/b))/b;
  end;



--TYPE integer_array IS ARRAY ( NATURAL RANGE <>) OF integer;

END memxlib_utils;


