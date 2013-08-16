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
-- Filename - vfbc_onehot.vhd
-- Author - , Xilinx
-- Creation - July 25, 2006
--
-- Description - Generic One-Hot Generator of programmable width.
--
--*******************************************************************



library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

entity vfbc_onehot is 
generic(WIDTH : integer := 5                      -- Data Width
       );
port (
  S : in  std_logic_vector(WIDTH-1 downto 0);     -- Binary Input
  X : out std_logic_vector((2**WIDTH)-1 downto 0) -- One-hot Output
);
end vfbc_onehot;

architecture rtl of vfbc_onehot is

  function pattern (
    ain : integer;
    size : integer)                     -- inputs
    return std_logic_vector is
    
    variable i : integer;
    variable tmp : integer; 
    variable tmp2 : std_logic; 
    variable xout : std_logic_vector(size-1 downto 0);
  begin  
    tmp := 2**ain; -- 1, 2, 4, 
    tmp2 := '1';
    for i in 0 to size-1 loop
      xout(i) := tmp2;
      if (tmp /= 1) then
        tmp := tmp - 1;  
      else
        tmp := 2**ain;  
  tmp2 := not(tmp2);
      end if;
    end loop;

    return xout;
  end function pattern ;
  
  type mask_array is array (WIDTH downto 0) of std_logic_vector((2**WIDTH)-1 downto 0);
  signal mask : mask_array;

begin
      mask(0) <= (others => '1');

      GEN_MASK : for i in 1 to WIDTH generate
        mask(i) <= mask(i-1) and pattern(i-1, 2**WIDTH) when (S(i-1) = '0') else mask(i-1) and (mask(0) xor pattern(i-1,
         2**WIDTH));
      end generate GEN_MASK;
      
      X <= mask(WIDTH);

end rtl;

