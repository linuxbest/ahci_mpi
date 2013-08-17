-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- gpi_module.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2011 Xilinx, Inc. All rights reserved.
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
-------------------------------------------------------------------------------
-- Filename:        gpi_module.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              gpi_module.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision$
-- Date:            $Date$
--
-- History:
--   goran  2007-12-19    First Version
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
library IEEE;
use IEEE.std_logic_1164.all;

entity GPI_Module is
  generic (
    C_USE_GPI      : integer;
    C_GPI_SIZE     : integer);
  port (
    Clk      : in  std_logic;
    Reset    : in  boolean;
    GPI_Read : in  std_logic;
    GPI      : in  std_logic_vector(C_GPI_SIZE-1 downto 0);
    GPI_In   : out std_logic_vector(C_GPI_SIZE-1 downto 0)
    );
end entity GPI_Module;

architecture IMP of GPI_Module is

begin  -- architecture IMP

  Using_GPI : if (C_USE_GPI /= 0) generate

    ----------------------------------------------------------------------------------------------
    -- Hold GPI_In signal in constant reset until we want to read the values.
    -- This allows us to just ORing all IO registers which we want to read
    ----------------------------------------------------------------------------------------------
    GPI_Sampling : process (Clk) is
    begin  -- process GPI_Sampling
      if Clk'event and Clk = '1' then  -- rising clock edge
        if (GPI_Read = '0') then       -- synchronous reset (active high)
          GPI_In <= (others => '0');
        else
          GPI_In <= GPI;
        end if;
      end if;
    end process GPI_Sampling;            
    
  end generate Using_GPI;

  No_GPI : if (C_USE_GPI = 0) generate
    GPI_In <= (others => '0');
  end generate No_GPI;
  
end architecture IMP;
