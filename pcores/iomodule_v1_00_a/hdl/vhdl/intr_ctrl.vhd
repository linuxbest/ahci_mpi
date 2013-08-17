-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- intr_ctrl.vhd - Entity and architecture
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
-- Filename:        intr_ctrl.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              intr_ctrl.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision$
-- Date:            $Date$
--
-- History:
--   goran  2008-01-08    First Version
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
use IEEE.std_logic_unsigned.all;

entity intr_ctrl is

  generic (
    C_USE_COMB_MUX    : integer := 0;
    C_INTC_ENABLED    : std_logic_vector(31 downto 0)  := X"FFFF0000";
    C_INTC_LEVEL_EDGE : std_logic_vector(31 downto 0)  := X"0000FFFF";
    C_INTC_POSITIVE   : std_logic_vector(31 downto 0)  := X"FFFFFFFF");
  port (
    Clk             : in  std_logic;
    Reset           : in  boolean;
    INTR            : in  std_logic_vector(31 downto 0);
    INTC_WRITE_CIAR : in  std_logic;
    INTC_WRITE_CIER : in  std_logic;
    Write_Data      : in  std_logic_vector(31 downto 0);
    INTC_READ_CISR  : in  std_logic;
    INTC_READ_CIPR  : in  std_logic;
    INTC_IRQ        : out std_logic;
    INTC_CISR       : out std_logic_vector(31 downto 0);
    INTC_CIPR       : out std_logic_vector(31 downto 0));
end entity intr_ctrl;

library UNISIM;
use UNISIM.vcomponents.all;

architecture IMP of intr_ctrl is

  signal interrupt    : std_logic_vector(31 downto 0);
  signal intr_present : std_logic_vector(31 downto 0);
  signal cisr         : std_logic_vector(31 downto 0);
  signal cier         : std_logic_vector(31 downto 0);
  signal cipr         : std_logic_vector(31 downto 0);
  signal rst_cipr_rd  : std_logic;
  
  signal intr_ffs     : std_logic_vector(4  downto 0);
  signal shift        : std_logic_vector(31 downto 0);
  signal cnt          : std_logic_vector(4 downto 0);
  signal cnt_d1       : std_logic_vector(4 downto 0);
  signal locked       : std_logic;
begin

  All_INTR_Bits : for I in 31 downto 0 generate
  begin

    Using_Intr : if (C_INTC_ENABLED(I) = '1') generate
    begin

      -- Clean the interrupt signals
      -- All internal sources are considered clean and only external needs to be registred once
      Ext_Intr : if (I > 15) generate
      begin

        Clean_Signal : process (Clk) is
        begin  -- process Clean_Signal
          if Clk'event and Clk = '1' then  -- rising clock edge
            if Reset then                  -- synchronous reset (active high)
              interrupt(I) <= not C_INTC_POSITIVE(I);
            else
              interrupt(I) <= INTR(I);
            end if;
          end if;
        end process Clean_Signal;
        
        -- Detect External Interrupt
        Level : if (C_INTC_LEVEL_EDGE(I) = '0') generate
        begin
          intr_present(I) <= interrupt(I) xnor C_INTC_POSITIVE(I);
        end generate Level;

        Edge : if (C_INTC_LEVEL_EDGE(I) = '1') generate
        begin
          Reg_INTR : process (Clk) is
            variable s1 : std_logic;
          begin  -- process Reg_INTR
            if Clk'event and Clk = '1' then  -- rising clock edge
              if Reset then                  -- synchronous reset (active high)
                intr_present(I) <= '0';
                s1              := not C_INTC_POSITIVE(I);
              else
                intr_present(I) <= '0';
                if (C_INTC_POSITIVE(I) = '0') and (s1 = '1') and (interrupt(I) = '0') then
                  intr_present(I) <= '1';
                end if;
                if (C_INTC_POSITIVE(I) = '1') and (s1 = '0') and (interrupt(I) = '1') then
                  intr_present(I) <= '1';
                end if;
                s1 := interrupt(I);
              end if;
            end if;
          end process Reg_INTR;
        end generate Edge;
      end generate Ext_Intr;

      Internal_Intr : if (I < 16) generate
      begin
        -- Internal source is always one-clock long and active high, no need to detect an edge
        intr_present(I) <= INTR(I);
        interrupt(I)    <= '0'; -- Unused
      end generate Internal_Intr;

      CISR_Reg : process (Clk) is
      begin  -- process CISR_Reg
        if Clk'event and Clk = '1' then  -- rising clock edge
          if Reset then                  -- synchronous reset (active high)
            cisr(I) <= '0';
          else
            if (intr_present(I) = '1') then
              cisr(I) <= '1';
            elsif ((INTC_WRITE_CIAR = '1') and (Write_Data(I) = '1')) then
              cisr(I) <= '0';
            end if;
          end if;
        end if;
      end process CISR_Reg;

      CIER_Reg : process (Clk) is
      begin  -- process CIER_Reg
        if Clk'event and Clk = '1' then  -- rising clock edge
          if Reset then                  -- synchronous reset (active high)
            cier(I) <= '0';
          elsif (INTC_WRITE_CIER = '1') then
            cier(I) <= Write_Data(I);
          end if;
        end if;
      end process CIER_Reg;

      cipr(I) <= cisr(I) and cier(I);
      
    end generate Using_Intr;

    Not_Using_Intr : if (C_INTC_ENABLED(I) = '0') generate
    begin
      interrupt(I)    <= '0';
      intr_present(I) <= '0';
      cier(I)         <= '0';
      cisr(I)         <= '0';
      cipr(I)         <= '0';
    end generate Not_Using_Intr;

  end generate All_INTR_Bits;

  cisr_rd_dff : process (Clk) is
  begin  -- process cisr_rd_dff
    if Clk'event and Clk = '1' then   -- rising clock edge
      if (INTC_READ_CISR = '0') then  -- synchronous reset (active high)
        INTC_CISR <= (others => '0');
      else
        INTC_CISR <= cisr(31 downto 16) & intr_ffs & cisr(10 downto 0);
      end if;
    end if;
  end process cisr_rd_dff;

  rst_cipr_rd <= not(INTC_READ_CIPR);

  cipr_rd_dff_all : for I in 0 to 31 generate
    fdr_i : FDR
      port map (
        Q => INTC_CIPR(I),
        C => Clk,
        D => cipr(I),
        R => rst_cipr_rd);
  end generate cipr_rd_dff_all;

  INTC_IRQ <= '1' when cipr /= X"00000000" else '0';

  --------------------------------------------------------------------
  -- our intr_ffs extend
  cnt_reg: process (Clk)
  begin  -- process cnt_reg
    if Clk'event and Clk = '1' then  -- rising clock edge
      if Reset then                  -- synchronous reset (active high)
        cnt <= "00000";
      else
        cnt <= cnt + 1;
      end if;
      cnt_d1 <= cnt;
    end if;
  end process cnt_reg;

  shift_reg: process (Clk)
  begin  -- process shift_reg
    if Clk'event and Clk = '1' then  -- rising clock edge
      if cnt = "00000" then
        shift <= cisr;
      else
        shift <= '0' & shift(31 downto 1);
      end if;
    end if;
  end process shift_reg;
  
  intr_ffs_reg : process (Clk) is
  begin -- process intr_ffs_reg
    if Clk'event and Clk = '1' then   -- rising clock edge
      if shift(0) = '1' and locked = '0' then
        intr_ffs <= cnt_d1;
      end if;
    end if;     
  end process intr_ffs_reg;

  locked_reg : process (Clk) is
  begin -- process locked_reg
    if Clk'event and Clk = '1' then   -- rising clock edge
      if cnt = "00000" then
        locked <= '0';
      elsif shift(0) = '1' then
        locked <= '1';
      end if;
    end if;     
  end process locked_reg;
  
end architecture IMP;
