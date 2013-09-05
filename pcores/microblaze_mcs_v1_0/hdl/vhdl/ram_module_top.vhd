-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- ram_module_top.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2006-2011 Xilinx, Inc. All rights reserved.
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
-- Filename:        ram_module_top.vhd
--
-- Description:     This file contains instantiations of various block RAM
--                  and an HDL implementation of distributed RAM, and
--                  allows initialization for simulation with INIT_FILE.
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              ram_module_top.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision$
-- Date:            $Date$
--
-- History:
--   goran    2006-08-09    First Version
--   rolandp  2011-06-20    Added support for INIT_FILE
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

-- pragma xilinx_rtl_off
library unisim;
use unisim.vcomponents.all;
-- pragma xilinx_rtl_on
library Microblaze_v8_20_b;
use Microblaze_v8_20_b.MicroBlaze_Types.all;

-------------------------------------------------------------------------------
-- *************** RESTRICTIONS ***********************
-- Only supports BRAM with the same size on both PORTA and PORTB
-- Only supports address widths up to 14 bits
-------------------------------------------------------------------------------
-- Write enable use:
-- - When C_WE_WIDTH = 1:
--     WEx(0) is used for DATA_INx(0 to C_DATA_WIDTH - 1)
-- - When C_DATA_WIDTH / C_WE_WIDTH = 8:
--     WEx(n) is used for DATA_INx(n*8 to n*8+7)
-- - When C_DATA_WIDTH / C_WE_WIDTH = 9
--     WEx(n) is used for DATA_INx(n*8 to n*8+7) & DATA_INx(C_WE_WIDTH*8+n)
-- All other combinations are illegal, and cause an assertion
-------------------------------------------------------------------------------
entity RAM_Module_Top is
  generic (
    C_TARGET              : TARGET_FAMILY_TYPE;
    C_DATA_WIDTH          : positive              := 18;  -- No upper limit
    C_WE_WIDTH            : positive              := 1;
    C_ADDR_WIDTH          : natural range 1 to 14 := 11;
    C_USE_INIT_FILE       : boolean               := false;
    C_MICROBLAZE_INSTANCE : string                := "microblaze_0";
    C_FORCE_BRAM          : boolean               := true;
    C_FORCE_LUTRAM        : boolean               := false);
  port (
    -- PORT A
    CLKA      : in  std_logic;
    WEA       : in  std_logic_vector(0 to C_WE_WIDTH-1);
    ENA       : in  std_logic;
    ADDRA     : in  std_logic_vector(0 to C_ADDR_WIDTH-1);
    DATA_INA  : in  std_logic_vector(0 to C_DATA_WIDTH-1);
    DATA_OUTA : out std_logic_vector(0 to C_DATA_WIDTH-1);
    -- PORT B
    CLKB      : in  std_logic;
    WEB       : in  std_logic_vector(0 to C_WE_WIDTH-1);
    ENB       : in  std_logic;
    ADDRB     : in  std_logic_vector(0 to C_ADDR_WIDTH-1);
    DATA_INB  : in  std_logic_vector(0 to C_DATA_WIDTH-1);
    DATA_OUTB : out std_logic_vector(0 to C_DATA_WIDTH-1)
    );
end entity RAM_Module_Top;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of RAM_Module_Top is

  component RAM_Module_Top is
    generic (
      C_TARGET              : TARGET_FAMILY_TYPE;
      C_DATA_WIDTH          : positive              := 18;  -- No upper limit
      C_WE_WIDTH            : positive              := 1;
      C_ADDR_WIDTH          : natural range 1 to 14 := 11;
      C_USE_INIT_FILE       : boolean               := false;
      C_MICROBLAZE_INSTANCE : string                := "microblaze_0";
      C_FORCE_BRAM          : boolean               := true;
      C_FORCE_LUTRAM        : boolean               := false);
    port (
      -- PORT A
      CLKA      : in  std_logic;
      WEA       : in  std_logic_vector(0 to C_WE_WIDTH-1);
      ENA       : in  std_logic;
      ADDRA     : in  std_logic_vector(0 to C_ADDR_WIDTH-1);
      DATA_INA  : in  std_logic_vector(0 to C_DATA_WIDTH-1);
      DATA_OUTA : out std_logic_vector(0 to C_DATA_WIDTH-1);
      -- PORT B
      CLKB      : in  std_logic;
      WEB       : in  std_logic_vector(0 to C_WE_WIDTH-1);
      ENB       : in  std_logic;
      ADDRB     : in  std_logic_vector(0 to C_ADDR_WIDTH-1);
      DATA_INB  : in  std_logic_vector(0 to C_DATA_WIDTH-1);
      DATA_OUTB : out std_logic_vector(0 to C_DATA_WIDTH-1)
      );
  end component RAM_Module_Top;
  
  -----------------------------------------------------------------------------
  -- The component declaration is needed since the RAMB16BWE primitives does
  -- NOT exists in unisim.vcomponents.all unless you target a spartan3a and
  -- have an EA package for Spartan3A.
  -----------------------------------------------------------------------------

  component RAMB16BWE
    generic (
      DATA_WIDTH_A : integer := 0;
      DATA_WIDTH_B : integer := 0;

      INIT_00 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_10 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_11 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_12 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_13 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_14 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_15 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_16 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_17 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_18 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_19 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_20 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_21 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_22 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_23 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_24 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_25 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_26 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_27 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_28 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_29 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_30 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_31 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_32 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_33 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_34 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_35 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_36 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_37 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_38 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_39 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";

      INIT_A : bit_vector := X"000000000";
      INIT_B : bit_vector := X"000000000";

      INITP_00 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_01 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_02 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_03 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_04 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_05 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_06 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_07 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";

      INIT_FILE : string := "NONE";

      SIM_COLLISION_CHECK : string := "ALL";

      SRVAL_A : bit_vector := X"000000000";
      SRVAL_B : bit_vector := X"000000000";

      WRITE_MODE_A : string := "WRITE_FIRST";
      WRITE_MODE_B : string := "WRITE_FIRST"
      );
    port (
      DOA   : out std_logic_vector (31 downto 0);
      DOB   : out std_logic_vector (31 downto 0);
      DOPA  : out std_logic_vector (3 downto 0);
      DOPB  : out std_logic_vector (3 downto 0);
      ADDRA : in  std_logic_vector (13 downto 0);
      ADDRB : in  std_logic_vector (13 downto 0);
      CLKA  : in  std_ulogic;
      CLKB  : in  std_ulogic;
      DIA   : in  std_logic_vector (31 downto 0);
      DIB   : in  std_logic_vector (31 downto 0);
      DIPA  : in  std_logic_vector (3 downto 0);
      DIPB  : in  std_logic_vector (3 downto 0);
      ENA   : in  std_ulogic;
      ENB   : in  std_ulogic;
      SSRA  : in  std_ulogic;
      SSRB  : in  std_ulogic;
      WEA   : in  std_logic_vector (3 downto 0);
      WEB   : in  std_logic_vector (3 downto 0));
  end component;

  function init_string (Index : integer) return string is
  begin
    if C_USE_INIT_FILE then
      return C_MICROBLAZE_INSTANCE & ".lmb_bram_" & integer'image(Index) & ".mem";
    else
      return "NONE";
    end if;
  end function init_string;

  constant byte_enable_bram_arch : boolean := Has_Target(C_TARGET, BRAM_WITH_BYTE_ENABLE);
  constant arch_36kbit_bram      : boolean := Has_Target(C_TARGET, BRAM_36k);
  constant arch_16kbit_we_bram   : boolean := Has_Target(C_TARGET, BRAM_16K_WE);
  constant using_parity          : boolean := C_DATA_WIDTH / C_WE_WIDTH = 9 and C_WE_WIDTH > 1;

  constant write_mode     : string := "READ_FIRST";
  constant sim_check_mode : string := "NONE";

  type bram_kind is (DISTRAM, B16_S1, B16_S2, B16_S4, B16_S9, B16_S18, B16_S36, B36_S1, B36_S2, B36_S4,
                     B36_S9, B36_S18, B36_S36);

  type BRAM_TYPE is record
    What_Kind   : bram_kind;
    Data_size   : natural;
    Addr_size   : natural;
    Parity_size : natural;
    Par_Padding : natural;
  end record BRAM_TYPE;

  type ramb36_index_vector_type is array (boolean) of natural;
  constant ramb36_index_vector : ramb36_index_vector_type := (false => 0, true => 6);
  constant is_ram36            : natural                  := ramb36_index_vector(arch_36kbit_bram);

  type ram_addr_vector is array (natural range 1 to 14) of integer;
  type kind_type is (mixed, bram, lutram);
  type ram_select_vector is array (kind_type) of ram_addr_vector;
  constant ram_select_lookup : ram_select_vector :=
    (mixed  => (1, 2, 3, 4, 5, 6, 7, 8, 9+is_ram36, 10+is_ram36, 11+is_ram36, 12+is_ram36,
                13+is_ram36, 14+is_ram36),
     bram   => (9+is_ram36, 9+is_ram36, 9+is_ram36, 9+is_ram36, 9+is_ram36, 9+is_ram36,
                9+is_ram36, 9+is_ram36, 9+is_ram36, 10+is_ram36, 11+is_ram36, 12+is_ram36,
                13+is_ram36, 14+is_ram36),
     lutram => (1, 2, 3, 4, 5, 6, 7, 8, 22, 23, 24, 25, 26, 27));

  type bram_type_vector is array (natural range 1 to 27) of BRAM_TYPE;
  constant bram_type_lookup : bram_type_vector :=
    (1  => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 1,  Parity_size => 0, Par_Padding => 0),
     2  => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 2,  Parity_size => 0, Par_Padding => 0),
     3  => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 3,  Parity_size => 0, Par_Padding => 0),
     4  => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 4,  Parity_size => 0, Par_Padding => 0),
     5  => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 5,  Parity_size => 0, Par_Padding => 0),
     6  => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 6,  Parity_size => 0, Par_Padding => 0),
     7  => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 7,  Parity_size => 0, Par_Padding => 0),
     8  => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 8,  Parity_size => 0, Par_Padding => 0),

     9  => (what_kind => B16_S36, Data_size => 32, Addr_size => 9,  Parity_size => 4, Par_Padding => 0),
     10 => (what_kind => B16_S18, Data_size => 16, Addr_size => 10, Parity_size => 2, Par_Padding => 0),
     11 => (what_kind => B16_S9,  Data_size => 8,  Addr_size => 11, Parity_size => 1, Par_Padding => 0),
     12 => (what_kind => B16_S4,  Data_size => 4,  Addr_size => 12, Parity_size => 0, Par_Padding => 1),
     13 => (what_kind => B16_S2,  Data_size => 2,  Addr_size => 13, Parity_size => 0, Par_Padding => 1),
     14 => (what_kind => B16_S1,  Data_size => 1,  Addr_size => 14, Parity_size => 0, Par_Padding => 1),

     15 => (what_kind => B36_S36, Data_size => 32, Addr_size => 10, Parity_size => 4, Par_Padding => 0),
     16 => (what_kind => B36_S36, Data_size => 32, Addr_size => 10, Parity_size => 4, Par_Padding => 0),
     17 => (what_kind => B36_S18, Data_size => 16, Addr_size => 11, Parity_size => 2, Par_Padding => 0),
     18 => (what_kind => B36_S9,  Data_size => 8,  Addr_size => 12, Parity_size => 1, Par_Padding => 0),
     19 => (what_kind => B36_S4,  Data_size => 4,  Addr_size => 13, Parity_size => 0, Par_Padding => 1),
     20 => (what_kind => B36_S2,  Data_size => 2,  Addr_size => 14, Parity_size => 0, Par_Padding => 1),
     21 => (what_kind => B36_S1,  Data_size => 1,  Addr_size => 15, Parity_size => 0, Par_Padding => 1),

     22 => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 9,  Parity_size => 0, Par_Padding => 0),
     23 => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 10, Parity_size => 0, Par_Padding => 0),
     24 => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 11, Parity_size => 0, Par_Padding => 0),
     25 => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 12, Parity_size => 0, Par_Padding => 0),
     26 => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 13, Parity_size => 0, Par_Padding => 0),
     27 => (what_kind => DISTRAM, Data_size => 8,  Addr_size => 14, Parity_size => 0, Par_Padding => 0)
     );

  function select_kind (force_bram : boolean; force_lutram : boolean) return kind_type is
  begin
    if force_bram then
      return bram;
    elsif force_lutram then
      return lutram;
    end if;
    return mixed;
  end function select_kind;

  function calc_nr_of_brams (data_size : natural; parity_size : natural; using_parity : boolean) return natural is
    constant bram_full_data_width : natural := data_size + parity_size;
  begin
    if C_WE_WIDTH = 1 or using_parity then
      return (C_DATA_WIDTH + bram_full_data_width - 1) / bram_full_data_width;
    else
      return (C_DATA_WIDTH + data_size - 1) / data_size;
    end if;
  end function calc_nr_of_brams;

  constant What_Kind : kind_type := select_kind(C_FORCE_BRAM, C_FORCE_LUTRAM);

  constant What_BRAM : BRAM_TYPE := bram_type_lookup(ram_select_lookup(What_Kind)(C_ADDR_WIDTH));

  constant nr_of_brams         : natural := calc_nr_of_brams(What_BRAM.Data_size, What_BRAM.Parity_size, using_parity);
  constant just_data_bits_size : natural := nr_of_brams * What_BRAM.Data_size;
  constant just_par_bits_size  : natural := nr_of_brams * What_BRAM.Parity_size + What_BRAM.Par_Padding;
  constant din_parity_bits     : natural := (C_DATA_WIDTH / C_WE_WIDTH - 8) * C_WE_WIDTH * boolean'pos(using_parity);
  constant parity_brams        : natural := din_parity_bits / (What_BRAM.Data_size + What_BRAM.Parity_size);
  constant extra_parity_brams  : natural := din_parity_bits - parity_brams;

  procedure assign (signal output : out std_logic_vector; signal input : in std_logic_vector) is
  begin
    if input'length = 1 then
      output <= (output'range => input(input'left));
    elsif input'length > output'length then
      output <= input(input'left to input'left + output'length - 1);
    else
      output <= (output'range => '0');
      output(output'left to output'left + input'length - 1) <= input;
    end if;
  end procedure assign;

  -- local signals for padding if the size doesn't match perfectly
  signal addra_i      : std_logic_vector(0 to What_BRAM.Addr_size-1);
  signal addrb_i      : std_logic_vector(0 to What_BRAM.Addr_size-1);

  signal data_ina_i   : std_logic_vector(0 to just_data_bits_size-1);
  signal data_inb_i   : std_logic_vector(0 to just_data_bits_size-1);
  signal data_outa_i  : std_logic_vector(0 to just_data_bits_size-1) := (others => '0');
  signal data_outb_i  : std_logic_vector(0 to just_data_bits_size-1) := (others => '0');

  signal data_inpa_i  : std_logic_vector(0 to just_par_bits_size-1);
  signal data_inpb_i  : std_logic_vector(0 to just_par_bits_size-1);
  signal data_outpa_i : std_logic_vector(0 to just_par_bits_size-1);
  signal data_outpb_i : std_logic_vector(0 to just_par_bits_size-1);

begin  -- architecture IMP

  assert C_WE_WIDTH = 1 or
         (C_DATA_WIDTH / C_WE_WIDTH = 8 and
          C_DATA_WIDTH - (C_DATA_WIDTH / C_WE_WIDTH) * C_WE_WIDTH = 0) or
         (C_DATA_WIDTH / C_WE_WIDTH = 9 and
          C_DATA_WIDTH - (C_DATA_WIDTH / C_WE_WIDTH) * C_WE_WIDTH = 0)
    report   "ram_module_top: illegal combination of C_WE_WIDTH and C_DATA_WIDTH"
    severity failure;

  Data_Size_Less_Than_Bram_Size: if (C_DATA_WIDTH < just_data_bits_size) generate
  begin
    padding_vectors : process(ADDRA, ADDRB, DATA_INA, DATA_INB, data_outa_i,
                              data_outb_i, data_outpa_i, data_outpb_i) is
    begin  -- process padding_vectors
      addra_i              <= (others => '0');
      addra_i(ADDRA'range) <= ADDRA;
      addrb_i              <= (others => '0');
      addrb_i(ADDRB'range) <= ADDRB;

      -- Default drive the parity inputs to '0'
      data_inpa_i <= (others => '0');
      data_inpb_i <= (others => '0');

      data_ina_i                 <= (others => '0');
      data_ina_i(DATA_INA'range) <= DATA_INA;
      DATA_OUTA                  <= data_outa_i(DATA_OUTA'range);
      data_inb_i                 <= (others => '0');
      data_inb_i(DATA_INB'range) <= DATA_INB;
      DATA_OUTB                  <= data_outb_i(DATA_OUTB'range);
    end process padding_vectors;    
  end generate Data_Size_Less_Than_Bram_Size;

  Data_Size_Larger_Than_BRAM_Size: if (C_DATA_WIDTH > just_data_bits_size) generate
  begin
    padding_vectors : process(ADDRA, ADDRB, DATA_INA, DATA_INB, data_outa_i,
                              data_outb_i, data_outpa_i, data_outpb_i) is
      constant data_size : integer := What_BRAM.Data_size;
      constant par_size  : integer := What_BRAM.Parity_size + What_BRAM.Par_Padding;
      constant bits_size : integer := data_size + par_size;
      variable I, D, P   : integer;
    begin  -- process padding_vectors
      addra_i              <= (others => '0');
      addra_i(ADDRA'range) <= ADDRA;
      addrb_i              <= (others => '0');
      addrb_i(ADDRB'range) <= ADDRB;

      -- Default drive the data and parity inputs to '0'
      data_ina_i  <= (others => '0');
      data_inpa_i <= (others => '0');
      data_inb_i  <= (others => '0');
      data_inpb_i <= (others => '0');

      data_ina_i  <= DATA_INA(data_ina_i'range);
      assign(data_inpa_i, DATA_INA(data_ina_i'right + 1 to C_DATA_WIDTH - 1));
      DATA_OUTA   <= data_outa_i & data_outpa_i(0 to C_DATA_WIDTH - data_outa_i'length - 1);
      data_inb_i  <= DATA_INB(data_inb_i'range);
      assign(data_inpb_i, DATA_INB(data_inb_i'right + 1 to C_DATA_WIDTH - 1));
      DATA_OUTB   <= data_outb_i & data_outpb_i(0 to C_DATA_WIDTH - data_outb_i'length - 1);
    end process padding_vectors;
  end generate Data_Size_Larger_Than_BRAM_Size;

  Data_Size_Equal_To_BRAM_Size: if (C_DATA_WIDTH = just_data_bits_size) generate
  begin
    padding_vectors : process(ADDRA, ADDRB, DATA_INA, DATA_INB, data_outa_i,
                              data_outb_i, data_outpa_i, data_outpb_i) is
    begin  -- process padding_vectors
      addra_i              <= (others => '0');
      addra_i(ADDRA'range) <= ADDRA;
      addrb_i              <= (others => '0');
      addrb_i(ADDRB'range) <= ADDRB;

      -- Default drive the parity inputs to '0'
      data_inpa_i <= (others => '0');
      data_inpb_i <= (others => '0');

      data_ina_i <= DATA_INA;
      DATA_OUTA  <= data_outa_i;
      data_inb_i <= DATA_INB;
      DATA_OUTB  <= data_outb_i;
    end process padding_vectors;    
  end generate Data_Size_Equal_To_BRAM_Size;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  --  BRAM organized as x36
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  Using_B16_S36 : if (What_BRAM.What_Kind = B16_S36) or (What_BRAM.What_Kind = B36_S36) generate
  begin
    Using_RAMB36 : if (arch_36kbit_bram) generate
      signal wea_i   : std_logic_vector(0 to nr_of_brams*4-1);
      signal web_i   : std_logic_vector(0 to nr_of_brams*4-1);
      signal addra_i : std_logic_vector(15 downto 0);
      signal addrb_i : std_logic_vector(15 downto 0);
    begin

      Pad_RAMB36_Signals : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB36_Signals
        assign(wea_i, WEA);
        assign(web_i, WEB);

        -- Address bit 15 is only used when BRAMs are cascaded, and must otherwise
        -- be set to '1' since the tools may not always do it automatically. All
        -- other unused bits should also be set to '1'.
        addra_i                            <= (others => '1');
        addra_i(14 downto 15-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '1');
        addrb_i(14 downto 15-C_ADDR_WIDTH) <= ADDRB;
      end process Pad_RAMB36_Signals;

      The_BRAMs : for I in 0 to nr_of_brams-1 generate
      begin
        RAMB36_I1 : RAMB36
          generic map (
            DOA_REG             => 0,               -- [integer]
            DOB_REG             => 0,               -- [integer]
            RAM_EXTENSION_A     => "NONE",          -- [string]
            RAM_EXTENSION_B     => "NONE",          -- [string]
      -- pragma translate_off
            INIT_FILE           => init_string(I),
      -- pragma translate_on
            READ_WIDTH_A        => 36,              -- [integer]
            READ_WIDTH_B        => 36,              -- [integer]
            SIM_COLLISION_CHECK => sim_check_mode,  -- [string]
            WRITE_MODE_A        => write_mode,      -- [string]
            WRITE_MODE_B        => write_mode,      -- [string]
            WRITE_WIDTH_A       => 36,              -- [integer]
            WRITE_WIDTH_B       => 36)              -- [integer]
          port map (
            CLKA => CLKA,                                   -- [in  std_ulogic]
            ENA  => ENA,                                    -- [in  std_ulogic]

            ADDRA          => addra_i,                      -- [in  std_logic_vector (15 downto 0)]
            WEA            => wea_i(I*4 to I*4+3),          -- [in  std_logic_vector (3 downto 0)]
            DIA            => data_ina_i(I*32 to I*32+31),  -- [in  std_logic_vector (31 downto 0)]
            DIPA           => data_inpa_i(I*4 to I*4+3),    -- [in  std_logic_vector (3 downto 0)]
            DOA            => data_outa_i(I*32 to I*32+31), -- [out std_logic_vector (31 downto 0)]
            DOPA           => data_outpa_i(I*4 to I*4+3),   -- [out std_logic_vector (3 downto 0)]
            SSRA           => '0',                          -- [in  std_ulogic]
            REGCEA         => '1',                          -- [in  std_ulogic]
            CASCADEOUTLATA => open,                         -- [out std_ulogic]
            CASCADEINLATA  => '0',                          -- [in  std_ulogic]
            CASCADEINREGA  => '0',                          -- [in  std_ulogic]
            CASCADEOUTREGA => open,                         -- [out std_ulogic]

            CLKB => CLKB,                                   -- [in  std_ulogic]            
            ENB  => ENB,                                    -- [in  std_ulogic]

            ADDRB          => addrb_i,                      -- [in  std_logic_vector (15 downto 0)]
            WEB            => web_i(I*4 to I*4+3),          -- [in  std_logic_vector (3 downto 0)]
            DIB            => data_inb_i(I*32 to I*32+31),  -- [in  std_logic_vector (31 downto 0)]
            DIPB           => data_inpb_i(I*4 to I*4+3),    -- [in  std_logic_vector (3 downto 0)]
            DOB            => data_outb_i(I*32 to I*32+31), -- [out std_logic_vector (31 downto 0)]
            DOPB           => data_outpb_i(I*4 to I*4+3),   -- [out std_logic_vector (3 downto 0)]
            SSRB           => '0',                          -- [in  std_ulogic]
            REGCEB         => '1',                          -- [in  std_ulogic]
            CASCADEOUTLATB => open,                         -- [out std_ulogic]
            CASCADEINLATB  => '0',                          -- [in  std_ulogic]
            CASCADEINREGB  => '0',                          -- [in  std_ulogic]
            CASCADEOUTREGB => open);                        -- [out std_ulogic]
      end generate The_BRAMs;
    end generate Using_RAMB36;

    Using_S36_Virtex4 : if (C_TARGET = VIRTEX4) generate
      signal wea_i   : std_logic_vector(0 to nr_of_brams*4-1);
      signal web_i   : std_logic_vector(0 to nr_of_brams*4-1);
      signal addra_i : std_logic_vector(14 downto 0);
      signal addrb_i : std_logic_vector(14 downto 0);
    begin

      Pad_RAMB16_Signals : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB16_Signals
        assign(wea_i, WEA);
        assign(web_i, WEB);

        -- Address bit 14 is only used when BRAMs are cascaded
        addra_i                            <= (others => '0');
        addra_i(13 downto 14-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '0');
        addrb_i(13 downto 14-C_ADDR_WIDTH) <= ADDRB;
      end process Pad_RAMB16_Signals;

      The_BRAMs : for I in 0 to nr_of_brams-1 generate
      begin
        RAMB16_I1 : RAMB16
          generic map (
            READ_WIDTH_A        => 36,    -- [integer]
            READ_WIDTH_B        => 36,    -- [integer]
            WRITE_WIDTH_A       => 36,    -- [integer]
            WRITE_WIDTH_B       => 36,
      -- pragma translate_off
            INIT_FILE           => init_string(I),
      -- pragma translate_on
            SIM_COLLISION_CHECK => sim_check_mode,
            WRITE_MODE_A        => write_mode,
            WRITE_MODE_B        => write_mode
            )                             -- [integer]
          port map (
            -- Port A
            CLKA        => CLKA,                         -- [in  std_ulogic]
            ADDRA       => addra_i,                      -- [in  std_logic_vector (14 downto 0)]
            ENA         => ENA,                          -- [in  std_ulogic]
            WEA         => wea_i(I*4 to I*4+3),          -- [in  std_logic_vector (3 downto 0)]
            DIA         => data_ina_i(I*32 to I*32+31),  -- [in  std_logic_vector (31 downto 0)]
            DIPA        => data_inpa_i(I*4 to I*4+3),    -- [in  std_logic_vector (3 downto 0)]
            DOA         => data_outa_i(I*32 to I*32+31), -- [out std_logic_vector (31 downto 0)]
            DOPA        => data_outpa_i(I*4 to I*4+3),   -- [out std_logic_vector (3 downto 0)]
            SSRA        => '0',                          -- [in  std_ulogic]
            REGCEA      => '1',                          -- [in  std_ulogic]
            CASCADEOUTA => open,                         -- [out std_ulogic]
            CASCADEINA  => '0',                          -- [in  std_ulogic]

            -- Port B
            CLKB        => CLKB,                         -- [in  std_ulogic]
            ADDRB       => addrb_i,                      -- [in  std_logic_vector (14 downto 0)]
            ENB         => ENB,                          -- [in  std_ulogic]
            WEB         => web_i(I*4 to I*4+3),          -- [in  std_logic_vector (3 downto 0)]
            DIB         => data_inb_i(I*32 to I*32+31),  -- [in  std_logic_vector (31 downto 0)]
            DIPB        => data_inpb_i(I*4 to I*4+3),    -- [in  std_logic_vector (3 downto 0)]
            DOB         => data_outb_i(I*32 to I*32+31), -- [out std_logic_vector (31 downto 0)]
            DOPB        => data_outpb_i(I*4 to I*4+3),   -- [out std_logic_vector (3 downto 0)]
            SSRB        => '0',                          -- [in  std_ulogic]
            REGCEB      => '1',                          -- [in  std_ulogic]
            CASCADEOUTB => open,                         -- [out std_ulogic]
            CASCADEINB  => '0'                           -- [in  std_ulogic]
            );
      end generate The_BRAMs;
    end generate Using_S36_Virtex4;

    Using_S36_Spartan3A : if (arch_16kbit_we_bram) generate
      signal wea_i   : std_logic_vector(0 to nr_of_brams*4-1);
      signal web_i   : std_logic_vector(0 to nr_of_brams*4-1);
      signal addra_i : std_logic_vector(13 downto 0);
      signal addrb_i : std_logic_vector(13 downto 0);
    begin

      Pad_RAMB16_Signals : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB16_Signals
        assign(wea_i, WEA);
        assign(web_i, WEB);

        addra_i                            <= (others => '0');
        addra_i(13 downto 14-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '0');
        addrb_i(13 downto 14-C_ADDR_WIDTH) <= ADDRB;
      end process Pad_RAMB16_Signals;

      The_BRAMs : for I in 0 to nr_of_brams-1 generate
      begin
        RAMB16BWE_I1 : RAMB16BWE
          generic map (
            DATA_WIDTH_A        => 36,    -- [integer]
            DATA_WIDTH_B        => 36,    -- [integer]
            SIM_COLLISION_CHECK => sim_check_mode,
      -- pragma translate_off
            INIT_FILE           => init_string(I),
      -- pragma translate_on
            WRITE_MODE_A        => write_mode,
            WRITE_MODE_B        => write_mode
            )                             -- [integer]
          port map (
            -- Port A
            CLKA  => CLKA,                         -- [in  std_ulogic]
            ADDRA => addra_i,                      -- [in  std_logic_vector (13 downto 0)]
            ENA   => ENA,                          -- [in  std_ulogic]
            WEA   => wea_i(I*4 to I*4+3),          -- [in  std_logic_vector (3 downto 0)]
            DIA   => data_ina_i(I*32 to I*32+31),  -- [in  std_logic_vector (31 downto 0)]
            DIPA  => data_inpa_i(I*4 to I*4+3),    -- [in  std_logic_vector (3 downto 0)]
            DOA   => data_outa_i(I*32 to I*32+31), -- [out std_logic_vector (31 downto 0)]
            DOPA  => data_outpa_i(I*4 to I*4+3),   -- [out std_logic_vector (3 downto 0)]
            SSRA  => '0',                          -- [in  std_ulogic]

            -- Port B
            CLKB  => CLKB,                         -- [in  std_ulogic]
            ADDRB => addrb_i,                      -- [in  std_logic_vector (13 downto 0)]
            ENB   => ENB,                          -- [in  std_ulogic]
            WEB   => web_i(I*4 to I*4+3),          -- [in  std_logic_vector (3 downto 0)]
            DIB   => data_inb_i(I*32 to I*32+31),  -- [in  std_logic_vector (31 downto 0)]
            DIPB  => data_inpb_i(I*4 to I*4+3),    -- [in  std_logic_vector (3 downto 0)]
            DOB   => data_outb_i(I*32 to I*32+31), -- [out std_logic_vector (31 downto 0)]
            DOPB  => data_outpb_i(I*4 to I*4+3),   -- [out std_logic_vector (3 downto 0)]
            SSRB  => '0'                           -- [in  std_ulogic]
            );
      end generate The_BRAMs;
    end generate Using_S36_Spartan3A;


    Not_Using_Byte_Enable_BRAM36 : if (not byte_enable_bram_arch) generate
      signal wea_i : std_logic_vector(0 to nr_of_brams-1);
      signal web_i : std_logic_vector(0 to nr_of_brams-1);
    begin
      assert not using_parity
        report "ram_module_top: parity not supported for this architecture"
        severity failure;

      -- Write enables are tied to one for each bram block
      The_BRAMs : for I in 0 to nr_of_brams-1 generate
      begin

        Pad_RAMB16_S36_S36_Signals : process (WEA, WEB) is
        begin  -- process Pad_RAMB16_S36_S36_Signals
          assign(wea_i, WEA);
          assign(web_i, WEB);
        end process Pad_RAMB16_S36_S36_Signals;

        RAMB16_S36_S36_1 : RAMB16_S36_S36
          generic map (
            SIM_COLLISION_CHECK => sim_check_mode,
            WRITE_MODE_A        => write_mode,
            WRITE_MODE_B        => write_mode
            )
          port map (
            -- Port A
            CLKA  => CLKA,                         -- [in  std_ulogic]
            ENA   => ENA,                          -- [in  std_ulogic]
            WEA   => wea_i(I),                     -- [in  std_ulogic]
            DIA   => data_ina_i(I*32 to I*32+31),  -- [in  std_logic_vector (31 downto 0)]
            DIPA  => data_inpa_i(I*4 to I*4+3),    -- [in  std_logic_vector (3 downto 0)]
            ADDRA => addra_i,                      -- [in  std_logic_vector (8 downto 0)]
            DOA   => data_outa_i(I*32 to I*32+31), -- [out std_logic_vector (31 downto 0)]
            DOPA  => data_outpa_i(I*4 to I*4+3),   -- [out std_logic_vector (3 downto 0)]
            SSRA  => '0',                          -- [in  std_ulogic]
            -- Port B
            CLKB  => CLKB,                         -- [in  std_ulogic]
            ENB   => ENB,                          -- [in  std_ulogic]
            WEB   => web_i(I),                     -- [in  std_ulogic]
            DIB   => data_inb_i(I*32 to I*32+31),  -- [in  std_logic_vector (31 downto 0)]
            DIPB  => data_inpb_i(I*4 to I*4+3),    -- [in  std_logic_vector (3 downto 0)]
            ADDRB => addrb_i,                      -- [in  std_logic_vector (8 downto 0)]
            DOB   => data_outb_i(I*32 to I*32+31), -- [out std_logic_vector (31 downto 0)]
            DOPB  => data_outpb_i(I*4 to I*4+3),   -- [out std_logic_vector (3 downto 0)]
            SSRB  => '0'                           -- [in  std_ulogic]
            );
      end generate The_BRAMs;
    end generate Not_Using_Byte_Enable_BRAM36;
  end generate Using_B16_S36;


  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  --  BRAM organized as x18
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  Using_B16_S18 : if (What_BRAM.What_Kind = B16_S18) or (What_BRAM.What_Kind = B36_S18) generate
  begin

    Using_RAMB36 : if (arch_36kbit_bram) generate
      signal wea_i   : std_logic_vector(0 to nr_of_brams*2-1);
      signal web_i   : std_logic_vector(0 to nr_of_brams*2-1);
      signal addra_i : std_logic_vector(15 downto 0);
      signal addrb_i : std_logic_vector(15 downto 0);
    begin

      Pad_RAMB36_Signals : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB36_Signals
        assign(wea_i, WEA);
        assign(web_i, WEB);

        -- Address bit 15 is only used when BRAMs are cascaded, and must otherwise
        -- be set to '1' since the tools may not always do it automatically.  All
        -- other unused bits should also be set to '1'.
        addra_i                            <= (others => '1');
        addra_i(14 downto 15-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '1');
        addrb_i(14 downto 15-C_ADDR_WIDTH) <= ADDRB;
      end process Pad_RAMB36_Signals;

      The_BRAMs : for I in 0 to nr_of_brams-1 generate
        signal wea_ii : std_logic_vector(0 to 3);
        signal dia_i  : std_logic_vector(0 to 31);
        signal diap_i : std_logic_vector(0 to 3);
        signal doa_i  : std_logic_vector(0 to 31);
        signal doap_i : std_logic_vector(0 to 3);
        signal web_ii : std_logic_vector(0 to 3);
        signal dib_i  : std_logic_vector(0 to 31);
        signal dibp_i : std_logic_vector(0 to 3);
        signal dob_i  : std_logic_vector(0 to 31);
        signal dobp_i : std_logic_vector(0 to 3);
      begin

        wea_ii                       <= wea_i(I*2 to I*2+1) & wea_i(I*2 to I*2+1);
        dia_i                        <= "0000000000000000" & data_ina_i(I*16 to I*16+15);
        diap_i                       <= "00" & data_inpa_i(I*2 to I*2+1);
        data_outa_i(I*16 to I*16+15) <= doa_i(16 to 31);
        data_outpa_i(I*2 to I*2+1)   <= doap_i(2 to 3);
        web_ii                       <= web_i(I*2 to I*2+1) & web_i(I*2 to I*2+1);
        dib_i                        <= "0000000000000000" & data_inb_i(I*16 to I*16+15);
        dibp_i                       <= "00" & data_inpb_i(I*2 to I*2+1);
        data_outb_i(I*16 to I*16+15) <= dob_i(16 to 31);
        data_outpb_i(I*2 to I*2+1)   <= dobp_i(2 to 3);

        RAMB36_I1 : RAMB36
          generic map (
            DOA_REG             => 0,               -- [integer]
            DOB_REG             => 0,               -- [integer]
            RAM_EXTENSION_A     => "NONE",          -- [string]
            RAM_EXTENSION_B     => "NONE",          -- [string]
      -- pragma translate_off
            INIT_FILE           => init_string(I),
      -- pragma translate_on
            READ_WIDTH_A        => 18,              -- [integer]
            READ_WIDTH_B        => 18,              -- [integer]
            SIM_COLLISION_CHECK => sim_check_mode,  -- [string]
            WRITE_MODE_A        => write_mode,      -- [string]
            WRITE_MODE_B        => write_mode,      -- [string]
            WRITE_WIDTH_A       => 18,              -- [integer]
            WRITE_WIDTH_B       => 18)              -- [integer]
          port map (
            CLKA => CLKA,                           -- [in  std_ulogic]
            ENA  => ENA,                            -- [in  std_ulogic]

            ADDRA          => addra_i,  -- [in  std_logic_vector (15 downto 0)]
            WEA            => wea_ii,   -- [in  std_logic_vector (3 downto 0)]
            DIA            => dia_i,    -- [in  std_logic_vector (31 downto 0)]
            DIPA           => diap_i,   -- [in  std_logic_vector (3 downto 0)]
            DOA            => doa_i,    -- [out std_logic_vector (31 downto 0)]
            DOPA           => doap_i,   -- [out std_logic_vector (3 downto 0)]
            SSRA           => '0',      -- [in  std_ulogic]
            REGCEA         => '1',      -- [in  std_ulogic]
            CASCADEOUTLATA => open,     -- [out std_ulogic]
            CASCADEINLATA  => '0',      -- [in  std_ulogic]
            CASCADEINREGA  => '0',      -- [in  std_ulogic]
            CASCADEOUTREGA => open,     -- [out std_ulogic]

            CLKB => CLKB,               -- [in  std_ulogic]            
            ENB  => ENB,                -- [in  std_ulogic]

            ADDRB          => addrb_i,  -- [in  std_logic_vector (15 downto 0)]
            WEB            => web_ii,   -- [in  std_logic_vector (3 downto 0)]
            DIB            => dib_i,    -- [in  std_logic_vector (31 downto 0)]
            DIPB           => dibp_i,   -- [in  std_logic_vector (3 downto 0)]
            DOB            => dob_i,    -- [out std_logic_vector (31 downto 0)]
            DOPB           => dobp_i,   -- [out std_logic_vector (3 downto 0)]
            SSRB           => '0',      -- [in  std_ulogic]
            REGCEB         => '1',      -- [in  std_ulogic]
            CASCADEOUTLATB => open,     -- [out std_ulogic]
            CASCADEINLATB  => '0',      -- [in  std_ulogic]
            CASCADEINREGB  => '0',      -- [in  std_ulogic]
            CASCADEOUTREGB => open);    -- [out std_ulogic]
      end generate The_BRAMs;

    end generate Using_RAMB36;

    Using_S18_Virtex4 : if (C_TARGET = VIRTEX4) generate
      signal wea_i   : std_logic_vector(0 to nr_of_brams*2-1);
      signal web_i   : std_logic_vector(0 to nr_of_brams*2-1);
      signal addra_i : std_logic_vector(14 downto 0);
      signal addrb_i : std_logic_vector(14 downto 0);
    begin

      Pad_RAMB16_Signals : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB16_Signals
        assign(wea_i, WEA);
        assign(web_i, WEB);

        addra_i                            <= (others => '0');
        addra_i(13 downto 14-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '0');
        addrb_i(13 downto 14-C_ADDR_WIDTH) <= ADDRB;
      end process Pad_RAMB16_Signals;

      The_BRAMs : for I in 0 to nr_of_brams-1 generate
        signal wea_ii : std_logic_vector(0 to 3);
        signal dia_i  : std_logic_vector(0 to 31);
        signal diap_i : std_logic_vector(0 to 3);
        signal doa_i  : std_logic_vector(0 to 31);
        signal doap_i : std_logic_vector(0 to 3);
        signal web_ii : std_logic_vector(0 to 3);
        signal dib_i  : std_logic_vector(0 to 31);
        signal dibp_i : std_logic_vector(0 to 3);
        signal dob_i  : std_logic_vector(0 to 31);
        signal dobp_i : std_logic_vector(0 to 3);
      begin

        wea_ii                       <= wea_i(I*2 to I*2+1) & wea_i(I*2 to I*2+1);
        dia_i                        <= "0000000000000000" & data_ina_i(I*16 to I*16+15);
        diap_i                       <= "00" & data_inpa_i(I*2 to I*2+1);
        data_outa_i(I*16 to I*16+15) <= doa_i(16 to 31);
        data_outpa_i(I*2 to I*2+1)   <= doap_i(2 to 3);
        web_ii                       <= web_i(I*2 to I*2+1) & web_i(I*2 to I*2+1);
        dib_i                        <= "0000000000000000" & data_inb_i(I*16 to I*16+15);
        dibp_i                       <= "00" & data_inpb_i(I*2 to I*2+1);
        data_outb_i(I*16 to I*16+15) <= dob_i(16 to 31);
        data_outpb_i(I*2 to I*2+1)   <= dobp_i(2 to 3);


        RAMB16_I1 : RAMB16
          generic map (
            READ_WIDTH_A        => 18,  -- [integer]
            READ_WIDTH_B        => 18,  -- [integer]
            WRITE_WIDTH_A       => 18,  -- [integer]
            WRITE_WIDTH_B       => 18,
      -- pragma translate_off
            INIT_FILE           => init_string(I),
      -- pragma translate_on
            SIM_COLLISION_CHECK => sim_check_mode,
            WRITE_MODE_A        => write_mode,
            WRITE_MODE_B        => write_mode
            )                           -- [integer]
          port map (
            -- Port A
            CLKA        => CLKA,        -- [in  std_ulogic]
            ADDRA       => addra_i,     -- [in  std_logic_vector (14 downto 0)]
            ENA         => ENA,         -- [in  std_ulogic]
            WEA         => wea_ii,      -- [in  std_logic_vector (3 downto 0)]
            DIA         => dia_i,       -- [in  std_logic_vector (31 downto 0)]
            DIPA        => diap_i,      -- [in  std_logic_vector (3 downto 0)]
            DOA         => doa_i,       -- [out std_logic_vector (31 downto 0)]
            DOPA        => doap_i,      -- [out std_logic_vector (3 downto 0)]
            SSRA        => '0',         -- [in  std_ulogic]
            REGCEA      => '1',         -- [in  std_ulogic]
            CASCADEOUTA => open,        -- [out std_ulogic]
            CASCADEINA  => '0',         -- [in  std_ulogic]

            -- Port B
            CLKB        => CLKB,        -- [in  std_ulogic]
            ADDRB       => addrb_i,     -- [in  std_logic_vector (14 downto 0)]
            ENB         => ENB,         -- [in  std_ulogic]
            WEB         => web_ii,      -- [in  std_logic_vector (3 downto 0)]
            DIB         => dib_i,       -- [in  std_logic_vector (31 downto 0)]
            DIPB        => dibp_i,      -- [in  std_logic_vector (3 downto 0)]
            DOB         => dob_i,       -- [out std_logic_vector (31 downto 0)]
            DOPB        => dobp_i,      -- [out std_logic_vector (3 downto 0)]
            SSRB        => '0',         -- [in  std_ulogic]
            REGCEB      => '1',         -- [in  std_ulogic]
            CASCADEOUTB => open,        -- [out std_ulogic]
            CASCADEINB  => '0'          -- [in  std_ulogic]
            );
      end generate The_BRAMs;
    end generate Using_S18_Virtex4;

    Using_S18_Spartan3A : if (arch_16kbit_we_bram) generate
      signal wea_i   : std_logic_vector(0 to nr_of_brams*2-1);
      signal web_i   : std_logic_vector(0 to nr_of_brams*2-1);
      signal addra_i : std_logic_vector(13 downto 0);
      signal addrb_i : std_logic_vector(13 downto 0);
    begin

      Pad_RAMB16_Signals : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB16_Signals
        assign(wea_i, WEA);
        assign(web_i, WEB);

        addra_i                            <= (others => '0');
        addra_i(13 downto 14-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '0');
        addrb_i(13 downto 14-C_ADDR_WIDTH) <= ADDRB;
      end process Pad_RAMB16_Signals;

      The_BRAMs : for I in 0 to nr_of_brams-1 generate
        signal wea_ii : std_logic_vector(0 to 3);
        signal dia_i  : std_logic_vector(0 to 31);
        signal diap_i : std_logic_vector(0 to 3);
        signal doa_i  : std_logic_vector(0 to 31);
        signal doap_i : std_logic_vector(0 to 3);
        signal web_ii : std_logic_vector(0 to 3);
        signal dib_i  : std_logic_vector(0 to 31);
        signal dibp_i : std_logic_vector(0 to 3);
        signal dob_i  : std_logic_vector(0 to 31);
        signal dobp_i : std_logic_vector(0 to 3);
      begin

        wea_ii                       <= wea_i(I*2 to I*2+1) & wea_i(I*2 to I*2+1);
        dia_i                        <= "0000000000000000" & data_ina_i(I*16 to I*16+15);
        diap_i                       <= "00" & data_inpa_i(I*2 to I*2+1);
        data_outa_i(I*16 to I*16+15) <= doa_i(16 to 31);
        data_outpa_i(I*2 to I*2+1)   <= doap_i(2 to 3);
        web_ii                       <= web_i(I*2 to I*2+1) & web_i(I*2 to I*2+1);
        dib_i                        <= "0000000000000000" & data_inb_i(I*16 to I*16+15);
        dibp_i                       <= "00" & data_inpb_i(I*2 to I*2+1);
        data_outb_i(I*16 to I*16+15) <= dob_i(16 to 31);
        data_outpb_i(I*2 to I*2+1)   <= dobp_i(2 to 3);


        RAMB16BWE_I1 : RAMB16BWE
          generic map (
            DATA_WIDTH_A        => 18,  -- [integer]
            DATA_WIDTH_B        => 18,  -- [integer]
            SIM_COLLISION_CHECK => sim_check_mode,
      -- pragma translate_off
            INIT_FILE           => init_string(I),
      -- pragma translate_on
            WRITE_MODE_A        => write_mode,
            WRITE_MODE_B        => write_mode
            )                           -- [integer]
          port map (
            -- Port A
            CLKA  => CLKA,              -- [in  std_ulogic]
            ADDRA => addra_i,           -- [in  std_logic_vector (13 downto 0)]
            ENA   => ENA,               -- [in  std_ulogic]
            WEA   => wea_ii,            -- [in  std_logic_vector (3 downto 0)]
            DIA   => dia_i,             -- [in  std_logic_vector (31 downto 0)]
            DIPA  => diap_i,            -- [in  std_logic_vector (3 downto 0)]
            DOA   => doa_i,             -- [out std_logic_vector (31 downto 0)]
            DOPA  => doap_i,            -- [out std_logic_vector (3 downto 0)]
            SSRA  => '0',               -- [in  std_ulogic]

            -- Port B
            CLKB  => CLKB,              -- [in  std_ulogic]
            ADDRB => addrb_i,           -- [in  std_logic_vector (13 downto 0)]
            ENB   => ENB,               -- [in  std_ulogic]
            WEB   => web_ii,            -- [in  std_logic_vector (3 downto 0)]
            DIB   => dib_i,             -- [in  std_logic_vector (31 downto 0)]
            DIPB  => dibp_i,            -- [in  std_logic_vector (3 downto 0)]
            DOB   => dob_i,             -- [out std_logic_vector (31 downto 0)]
            DOPB  => dobp_i,            -- [out std_logic_vector (3 downto 0)]
            SSRB  => '0'                -- [in  std_ulogic]
            );
      end generate The_BRAMs;
    end generate Using_S18_Spartan3A;


    Not_Using_Byte_Enable_BRAM16 : if (not byte_enable_bram_arch) generate
      signal wea_i : std_logic_vector(0 to nr_of_brams-1);
      signal web_i : std_logic_vector(0 to nr_of_brams-1);
    begin
      assert not using_parity
        report "ram_module_top: parity not supported for this architecture"
        severity failure;

      -- Write enables are tied to one for each bram block
      The_BRAMs : for I in 0 to nr_of_brams-1 generate
      begin

        Pad_RAMB16_S18_S18_Signals : process (WEA, WEB) is
        begin  -- process Pad_RAMB16_S18_S18_Signals
          assign(wea_i, WEA);
          assign(web_i, WEB);
        end process Pad_RAMB16_S18_S18_Signals;

        RAMB16_S18_1 : RAMB16_S18_S18
          generic map (
            SIM_COLLISION_CHECK => sim_check_mode,
            WRITE_MODE_A        => write_mode,
            WRITE_MODE_B        => write_mode
            )
          port map (
            -- Port A
            CLKA  => CLKA,                         -- [in  std_ulogic]
            ENA   => ENA,                          -- [in  std_ulogic]
            WEA   => wea_i(I),                     -- [in  std_ulogic]
            DIA   => data_ina_i(I*16 to I*16+15),  -- [in  std_logic_vector (15 downto 0)]
            DIPA  => data_inpa_i(I*2 to I*2+1),    -- [in  std_logic_vector (1 downto 0)]
            ADDRA => addra_i,                      -- [in  std_logic_vector (9 downto 0)]
            DOA   => data_outa_i(I*16 to I*16+15), -- [out std_logic_vector (15 downto 0)]
            DOPA  => data_outpa_i(I*2 to I*2+1),   -- [out std_logic_vector (1 downto 0)]
            SSRA  => '0',                          -- [in  std_ulogic]
            -- Port B
            CLKB  => CLKB,                         -- [in  std_ulogic]
            ENB   => ENB,                          -- [in  std_ulogic]
            WEB   => web_i(I),                     -- [in  std_ulogic]
            DIB   => data_inb_i(I*16 to I*16+15),  -- [in  std_logic_vector (15 downto 0)]
            DIPB  => data_inpb_i(I*2 to I*2+1),    -- [in  std_logic_vector (1 downto 0)]
            ADDRB => addrb_i,                      -- [in  std_logic_vector (9 downto 0)]
            DOB   => data_outb_i(I*16 to I*16+15), -- [out std_logic_vector (15 downto 0)]
            DOPB  => data_outpb_i(I*2 to I*2+1),   -- [out std_logic_vector (1 downto 0)]
            SSRB  => '0'                           -- [in  std_ulogic]
            );
      end generate The_BRAMs;
    end generate Not_Using_Byte_Enable_BRAM16;
  end generate Using_B16_S18;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  --  BRAM organized as x9
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  Using_B36_S9 : if (What_BRAM.What_Kind = B36_S9) generate
    signal addra_i : std_logic_vector(15 downto 0);
    signal addrb_i : std_logic_vector(15 downto 0);
    signal wea_i   : std_logic_vector(0 to nr_of_brams-1);
    signal web_i   : std_logic_vector(0 to nr_of_brams-1);
  begin

    Pad_RAMB36_Addresses : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB36_Addresses
        assign(wea_i, WEA);
        assign(web_i, WEB);

        -- Address bit 15 is only used when BRAMs are cascaded
        addra_i                            <= (others => '0');
        addra_i(14 downto 15-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '0');
        addrb_i(14 downto 15-C_ADDR_WIDTH) <= ADDRB;
    end process Pad_RAMB36_Addresses;


    The_BRAMs : for I in 0 to nr_of_brams-1 generate
      signal wea_ii : std_logic_vector(0 to 3);
      signal dia_i  : std_logic_vector(0 to 31);
      signal diap_i : std_logic_vector(0 to 3);
      signal doa_i  : std_logic_vector(0 to 31);
      signal doap_i : std_logic_vector(0 to 3);
      signal web_ii : std_logic_vector(0 to 3);
      signal dib_i  : std_logic_vector(0 to 31);
      signal dibp_i : std_logic_vector(0 to 3);
      signal dob_i  : std_logic_vector(0 to 31);
      signal dobp_i : std_logic_vector(0 to 3);
    begin

      wea_ii                    <= (others => wea_i(I));
      dia_i                     <= "000000000000000000000000" & data_ina_i(I*8 to I*8+7);
      diap_i                    <= "000" & data_inpa_i(I);
      data_outa_i(I*8 to I*8+7) <= doa_i(24 to 31);
      data_outpa_i(I)           <= doap_i(3);

      web_ii                    <= (others => web_i(I));
      dib_i                     <= "000000000000000000000000" & data_inb_i(I*8 to I*8+7);
      dibp_i                    <= "000" & data_inpb_i(I);
      data_outb_i(I*8 to I*8+7) <= dob_i(24 to 31);
      data_outpb_i(I)           <= dobp_i(3);

      RAMB36_I1 : RAMB36
        generic map (
          DOA_REG             => 0,               -- [integer]
          DOB_REG             => 0,               -- [integer]
          RAM_EXTENSION_A     => "NONE",          -- [string]
          RAM_EXTENSION_B     => "NONE",          -- [string]
      -- pragma translate_off
          INIT_FILE           => init_string(I),
      -- pragma translate_on
          READ_WIDTH_A        => 9,               -- [integer]
          READ_WIDTH_B        => 9,               -- [integer]
          SIM_COLLISION_CHECK => sim_check_mode,  -- [string]
          WRITE_MODE_A        => write_mode,      -- [string]
          WRITE_MODE_B        => write_mode,      -- [string]
          WRITE_WIDTH_A       => 9,               -- [integer]
          WRITE_WIDTH_B       => 9)               -- [integer]
        port map (
          CLKA => CLKA,                           -- [in  std_ulogic]
          ENA  => ENA,                            -- [in  std_ulogic]

          ADDRA          => addra_i,    -- [in  std_logic_vector (15 downto 0)]
          WEA            => wea_ii,     -- [in  std_logic_vector (3 downto 0)]
          DIA            => dia_i,      -- [in  std_logic_vector (31 downto 0)]
          DIPA           => diap_i,     -- [in  std_logic_vector (3 downto 0)]
          DOA            => doa_i,      -- [out std_logic_vector (31 downto 0)]
          DOPA           => doap_i,     -- [out std_logic_vector (3 downto 0)]
          SSRA           => '0',        -- [in  std_ulogic]
          REGCEA         => '1',        -- [in  std_ulogic]
          CASCADEOUTLATA => open,       -- [out std_ulogic]
          CASCADEINLATA  => '0',        -- [in  std_ulogic]
          CASCADEINREGA  => '0',        -- [in  std_ulogic]
          CASCADEOUTREGA => open,       -- [out std_ulogic]

          CLKB => CLKB,                 -- [in  std_ulogic]            
          ENB  => ENB,                  -- [in  std_ulogic]

          ADDRB          => addrb_i,    -- [in  std_logic_vector (15 downto 0)]
          WEB            => web_ii,     -- [in  std_logic_vector (3 downto 0)]
          DIB            => dib_i,      -- [in  std_logic_vector (31 downto 0)]
          DIPB           => dibp_i,     -- [in  std_logic_vector (3 downto 0)]
          DOB            => dob_i,      -- [out std_logic_vector (31 downto 0)]
          DOPB           => dobp_i,     -- [out std_logic_vector (3 downto 0)]
          SSRB           => '0',        -- [in  std_ulogic]
          REGCEB         => '1',        -- [in  std_ulogic]
          CASCADEOUTLATB => open,       -- [out std_ulogic]
          CASCADEINLATB  => '0',        -- [in  std_ulogic]
          CASCADEINREGB  => '0',        -- [in  std_ulogic]
          CASCADEOUTREGB => open);      -- [out std_ulogic]
    end generate The_BRAMs;
  end generate Using_B36_S9;

  Using_B16_S9 : if (What_BRAM.What_Kind = B16_S9) generate
    signal wea_i : std_logic_vector(0 to nr_of_brams-1);
    signal web_i : std_logic_vector(0 to nr_of_brams-1);
  begin
    -- Write enables are tied to one for each bram block
    The_BRAMs : for I in 0 to nr_of_brams-1 generate
    begin

      Pad_RAMB16_S9_S9_Signals : process (WEA, WEB) is
      begin  -- process Pad_RAMB16_S9_S9_Signals
        assign(wea_i, WEA);
        assign(web_i, WEB);
      end process Pad_RAMB16_S9_S9_Signals;

      RAMB16_S9_1 : RAMB16_S9_S9
        generic map (
          SIM_COLLISION_CHECK => sim_check_mode,
          WRITE_MODE_A        => write_mode,
          WRITE_MODE_B        => write_mode
          )
        port map (
          -- Port A
          CLKA  => CLKA,                      -- [in  std_ulogic]
          ENA   => ENA,                       -- [in  std_ulogic]
          WEA   => wea_i(I),                  -- [in  std_ulogic]
          DIA   => data_ina_i(I*8 to I*8+7),  -- [in  std_logic_vector (7 downto 0)]
          DIPA  => data_inpa_i(I to I),       -- [in  std_logic_vector (0 downto 0)]
          ADDRA => addra_i,                   -- [in  std_logic_vector (10 downto 0)]
          DOA   => data_outa_i(I*8 to I*8+7), -- [out std_logic_vector (7 downto 0)]
          DOPA  => data_outpa_i(I to I),      -- [out std_logic_vector (0 downto 0)]
          SSRA  => '0',                       -- [in  std_ulogic]
          -- Port B
          CLKB  => CLKB,                      -- [in  std_ulogic]
          ENB   => ENB,                       -- [in  std_ulogic]
          WEB   => web_i(I),                  -- [in  std_ulogic]
          DIB   => data_inb_i(I*8 to I*8+7),  -- [in  std_logic_vector (7 downto 0)]
          DIPB  => data_inpb_i(I to I),       -- [in  std_logic_vector (0 downto 0)]
          ADDRB => addrb_i,                   -- [in  std_logic_vector (10 downto 0)]
          DOB   => data_outb_i(I*8 to I*8+7), -- [out std_logic_vector (7 downto 0)]
          DOPB  => data_outpb_i(I to I),      -- [out std_logic_vector (0 downto 0)]
          SSRB  => '0'                        -- [in  std_ulogic]
          );
    end generate The_BRAMs;
  end generate Using_B16_S9;


  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  --  BRAM organized as x4
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  Using_B36_S4 : if (What_BRAM.What_Kind = B36_S4) generate
    signal addra_i : std_logic_vector(15 downto 0);
    signal addrb_i : std_logic_vector(15 downto 0);
    signal wea_i   : std_logic_vector(0 to (nr_of_brams+1)/2-1);
    signal web_i   : std_logic_vector(0 to (nr_of_brams+1)/2-1);
  begin

    Pad_RAMB36_Addresses : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB36_Addresses
        assign(wea_i, WEA);
        assign(web_i, WEB);

        -- Address bit 15 is only used when BRAMs are cascaded
        addra_i                            <= (others => '0');
        addra_i(14 downto 15-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '0');
        addrb_i(14 downto 15-C_ADDR_WIDTH) <= ADDRB;
    end process Pad_RAMB36_Addresses;

    The_BRAMs : for I in 0 to nr_of_brams+extra_parity_brams-1 generate
      signal wea_ii : std_logic_vector(0 to 3);
      signal dia_i  : std_logic_vector(0 to 31);
      signal diap_i : std_logic_vector(0 to 3);
      signal doa_i  : std_logic_vector(0 to 31);
      signal doap_i : std_logic_vector(0 to 3);
      signal web_ii : std_logic_vector(0 to 3);
      signal dib_i  : std_logic_vector(0 to 31);
      signal dibp_i : std_logic_vector(0 to 3);
      signal dob_i  : std_logic_vector(0 to 31);
      signal dobp_i : std_logic_vector(0 to 3);
    begin

      Pad_RAMB36_Data_WE : if I < nr_of_brams - parity_brams generate
      begin
        -- Data BRAMs
        wea_ii                    <= (others => wea_i(I/2));
        dia_i                     <= "0000000000000000000000000000" & data_ina_i(I*4 to I*4+3);
        diap_i                    <= "0000";
        data_outa_i(I*4 to I*4+3) <= doa_i(28 to 31);

        web_ii                    <= (others => web_i(I/2));
        dib_i                     <= "0000000000000000000000000000" & data_inb_i(I*4 to I*4+3);
        dibp_i                    <= "0000";
        data_outb_i(I*4 to I*4+3) <= dob_i(28 to 31);
      end generate Pad_RAMB36_Data_WE;

      Pad_RAMB36_Parity_WE : if I >= nr_of_brams - parity_brams generate
        constant parity_we_index : integer := I - nr_of_brams + parity_brams;
        constant data_index      : integer := C_DATA_WIDTH - din_parity_bits + parity_we_index;
      begin
        -- Parity BRAMs: One BRAM for each parity bit and write enable bit
        wea_ii                    <= (others => wea_i(parity_we_index));
        dia_i                     <= "0000000000000000000000000000000" & data_ina_i(data_index);
        diap_i                    <= "0000";
        data_outa_i(data_index)   <= doa_i(31);

        web_ii                    <= (others => web_i(parity_we_index));
        dib_i                     <= "0000000000000000000000000000000" & data_inb_i(data_index);
        dibp_i                    <= "0000";
        data_outb_i(data_index)   <= dob_i(31);
      end generate Pad_RAMB36_Parity_WE;

      RAMB36_I1 : RAMB36
        generic map (
          DOA_REG             => 0,               -- [integer]
          DOB_REG             => 0,               -- [integer]
          RAM_EXTENSION_A     => "NONE",          -- [string]
          RAM_EXTENSION_B     => "NONE",          -- [string]
      -- pragma translate_off
          INIT_FILE           => init_string(I),
      -- pragma translate_on
          READ_WIDTH_A        => 4,               -- [integer]
          READ_WIDTH_B        => 4,               -- [integer]
          SIM_COLLISION_CHECK => sim_check_mode,  -- [string]
          WRITE_MODE_A        => write_mode,      -- [string]
          WRITE_MODE_B        => write_mode,      -- [string]
          WRITE_WIDTH_A       => 4,               -- [integer]
          WRITE_WIDTH_B       => 4)               -- [integer]
        port map (
          CLKA => CLKA,                           -- [in  std_ulogic]
          ENA  => ENA,                            -- [in  std_ulogic]

          ADDRA          => addra_i,    -- [in  std_logic_vector (15 downto 0)]
          WEA            => wea_ii,     -- [in  std_logic_vector (3 downto 0)]
          DIA            => dia_i,      -- [in  std_logic_vector (31 downto 0)]
          DIPA           => diap_i,     -- [in  std_logic_vector (3 downto 0)]
          DOA            => doa_i,      -- [out std_logic_vector (31 downto 0)]
          DOPA           => open,       -- [out std_logic_vector (3 downto 0)]
          SSRA           => '0',        -- [in  std_ulogic]
          REGCEA         => '1',        -- [in  std_ulogic]
          CASCADEOUTLATA => open,       -- [out std_ulogic]
          CASCADEINLATA  => '0',        -- [in  std_ulogic]
          CASCADEINREGA  => '0',        -- [in  std_ulogic]
          CASCADEOUTREGA => open,       -- [out std_ulogic]

          CLKB => CLKB,                 -- [in  std_ulogic]            
          ENB  => ENB,                  -- [in  std_ulogic]

          ADDRB          => addrb_i,    -- [in  std_logic_vector (15 downto 0)]
          WEB            => web_ii,     -- [in  std_logic_vector (3 downto 0)]
          DIB            => dib_i,      -- [in  std_logic_vector (31 downto 0)]
          DIPB           => dibp_i,     -- [in  std_logic_vector (3 downto 0)]
          DOB            => dob_i,      -- [out std_logic_vector (31 downto 0)]
          DOPB           => open,       -- [out std_logic_vector (3 downto 0)]
          SSRB           => '0',        -- [in  std_ulogic]
          REGCEB         => '1',        -- [in  std_ulogic]
          CASCADEOUTLATB => open,       -- [out std_ulogic]
          CASCADEINLATB  => '0',        -- [in  std_ulogic]
          CASCADEINREGB  => '0',        -- [in  std_ulogic]
          CASCADEOUTREGB => open);      -- [out std_ulogic]
    end generate The_BRAMs;
  end generate Using_B36_S4;

  Using_B16_S4 : if (What_BRAM.What_Kind = B16_S4) generate
    signal wea_i : std_logic_vector(0 to (nr_of_brams+1)/2-1);
    signal web_i : std_logic_vector(0 to (nr_of_brams+1)/2-1);
  begin

    Pad_RAMB16_S4_S4_Signals : process (WEA, WEB) is
    begin  -- process Pad_RAMB16_S4_S4_Signals
      assign(wea_i, WEA);
      assign(web_i, WEB);
    end process Pad_RAMB16_S4_S4_Signals;

    -- Write enables are tied to one for each two bram block (to support byte enables)
    The_BRAMs : for I in 0 to nr_of_brams+extra_parity_brams-1 generate
      signal wea_ii : std_logic;
      signal dia_i  : std_logic_vector(0 to 3);
      signal doa_i  : std_logic_vector(0 to 3);
      signal web_ii : std_logic;
      signal dib_i  : std_logic_vector(0 to 3);
      signal dob_i  : std_logic_vector(0 to 3);
    begin

      Pad_RAMB16_S4_S4_Data_WE : if I < nr_of_brams - parity_brams generate
      begin
        -- Data BRAMs
        wea_ii                    <= wea_i(I/2);
        dia_i                     <= data_ina_i(I*4 to I*4+3);
        data_outa_i(I*4 to I*4+3) <= doa_i;

        web_ii                    <= web_i(I/2);
        dib_i                     <= data_inb_i(I*4 to I*4+3);
        data_outb_i(I*4 to I*4+3) <= dob_i;
      end generate Pad_RAMB16_S4_S4_Data_WE;

      Pad_RAMB16_S4_S4_Parity_WE : if I >= nr_of_brams - parity_brams generate
        constant parity_we_index : integer := I - nr_of_brams + parity_brams;
        constant data_index      : integer := C_DATA_WIDTH - din_parity_bits + parity_we_index;
      begin
        -- Parity BRAMs: One BRAM for each parity bit and write enable bit
        wea_ii                    <= wea_i(parity_we_index);
        dia_i                     <= "000" & data_ina_i(data_index);
        data_outa_i(data_index)   <= doa_i(3);

        web_ii                    <= web_i(parity_we_index);
        dib_i                     <= "000" & data_inb_i(data_index);
        data_outb_i(data_index)   <= dob_i(3);
      end generate Pad_RAMB16_S4_S4_Parity_WE;

      RAMB16_S4_1 : RAMB16_S4_S4
        generic map (
          SIM_COLLISION_CHECK => sim_check_mode,
          WRITE_MODE_A        => write_mode,
          WRITE_MODE_B        => write_mode)
        port map (
          -- Port A
          CLKA  => CLKA,     -- [in  std_ulogic]
          ENA   => ENA,      -- [in  std_ulogic]
          WEA   => wea_ii,   -- [in  std_ulogic]
          DIA   => dia_i,    -- [in  std_logic_vector (3 downto 0)]
          ADDRA => addra_i,  -- [in  std_logic_vector (11 downto 0)]
          DOA   => doa_i,    -- [out std_logic_vector (3 downto 0)]
          SSRA  => '0',      -- [in  std_ulogic]
          -- Port B
          CLKB  => CLKB,     -- [in  std_ulogic]
          ENB   => ENB,      -- [in  std_ulogic]
          WEB   => web_ii,   -- [in  std_ulogic]
          DIB   => dib_i,    -- [in  std_logic_vector (3 downto 0)]
          ADDRB => addrb_i,  -- [in  std_logic_vector (11 downto 0)]
          DOB   => dob_i,    -- [out std_logic_vector (3 downto 0)]
          SSRB  => '0'       -- [in  std_ulogic]
          );
    end generate The_BRAMs;
  end generate Using_B16_S4;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  --  BRAM organized as x2
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  Using_B36_S2 : if (What_BRAM.What_Kind = B36_S2) generate
    signal addra_i : std_logic_vector(15 downto 0);
    signal addrb_i : std_logic_vector(15 downto 0);
    signal wea_i   : std_logic_vector(0 to (nr_of_brams+3)/4-1);
    signal web_i   : std_logic_vector(0 to (nr_of_brams+3)/4-1);
  begin

    Pad_RAMB36_Addresses : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB36_Addresses
        assign(wea_i, WEA);
        assign(web_i, WEB);

        -- Address bit 15 is only used when BRAMs are cascaded
        addra_i                            <= (others => '0');
        addra_i(14 downto 15-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '0');
        addrb_i(14 downto 15-C_ADDR_WIDTH) <= ADDRB;
    end process Pad_RAMB36_Addresses;

    The_BRAMs : for I in 0 to nr_of_brams+extra_parity_brams-1 generate
      signal wea_ii : std_logic_vector(0 to 3);
      signal dia_i  : std_logic_vector(0 to 31);
      signal diap_i : std_logic_vector(0 to 3);
      signal doa_i  : std_logic_vector(0 to 31);
      signal doap_i : std_logic_vector(0 to 3);
      signal web_ii : std_logic_vector(0 to 3);
      signal dib_i  : std_logic_vector(0 to 31);
      signal dibp_i : std_logic_vector(0 to 3);
      signal dob_i  : std_logic_vector(0 to 31);
      signal dobp_i : std_logic_vector(0 to 3);
    begin

      Pad_RAMB36_Data_WE : if I < nr_of_brams - parity_brams generate
      begin
        -- Data BRAMs
        wea_ii                    <= (others => wea_i(I/4));
        dia_i                     <= "000000000000000000000000000000" & data_ina_i(I*2 to I*2+1);
        diap_i                    <= "0000";
        data_outa_i(I*2 to I*2+1) <= doa_i(30 to 31);

        web_ii                    <= (others => web_i(I/4));
        dib_i                     <= "000000000000000000000000000000" & data_inb_i(I*2 to I*2+1);
        dibp_i                    <= "0000";
        data_outb_i(I*2 to I*2+1) <= dob_i(30 to 31);
      end generate Pad_RAMB36_Data_WE;

      Pad_RAMB36_Parity_WE : if I >= nr_of_brams - parity_brams generate
        constant parity_we_index : integer := I - nr_of_brams + parity_brams;
        constant data_index      : integer := C_DATA_WIDTH - din_parity_bits + parity_we_index;
      begin
        -- Parity BRAMs: One BRAM for each parity bit and write enable bit
        wea_ii                    <= (others => wea_i(parity_we_index));
        dia_i                     <= "0000000000000000000000000000000" & data_ina_i(data_index);
        diap_i                    <= "0000";
        data_outa_i(data_index)   <= doa_i(31);

        web_ii                    <= (others => web_i(parity_we_index));
        dib_i                     <= "0000000000000000000000000000000" & data_inb_i(data_index);
        dibp_i                    <= "0000";
        data_outb_i(data_index)   <= dob_i(31);
      end generate Pad_RAMB36_Parity_WE;

      RAMB36_I1 : RAMB36
        generic map (
          DOA_REG             => 0,               -- [integer]
          DOB_REG             => 0,               -- [integer]
          RAM_EXTENSION_A     => "NONE",          -- [string]
          RAM_EXTENSION_B     => "NONE",          -- [string]
      -- pragma translate_off
          INIT_FILE           => init_string(I),
      -- pragma translate_on
          READ_WIDTH_A        => 2,               -- [integer]
          READ_WIDTH_B        => 2,               -- [integer]
          SIM_COLLISION_CHECK => sim_check_mode,  -- [string]
          WRITE_MODE_A        => write_mode,      -- [string]
          WRITE_MODE_B        => write_mode,      -- [string]
          WRITE_WIDTH_A       => 2,               -- [integer]
          WRITE_WIDTH_B       => 2)               -- [integer]
        port map (
          CLKA => CLKA,                           -- [in  std_ulogic]
          ENA  => ENA,                            -- [in  std_ulogic]

          ADDRA          => addra_i,    -- [in  std_logic_vector (15 downto 0)]
          WEA            => wea_ii,     -- [in  std_logic_vector (3 downto 0)]
          DIA            => dia_i,      -- [in  std_logic_vector (31 downto 0)]
          DIPA           => diap_i,     -- [in  std_logic_vector (3 downto 0)]
          DOA            => doa_i,      -- [out std_logic_vector (31 downto 0)]
          DOPA           => open,       -- [out std_logic_vector (3 downto 0)]
          SSRA           => '0',        -- [in  std_ulogic]
          REGCEA         => '1',        -- [in  std_ulogic]
          CASCADEOUTLATA => open,       -- [out std_ulogic]
          CASCADEINLATA  => '0',        -- [in  std_ulogic]
          CASCADEINREGA  => '0',        -- [in  std_ulogic]
          CASCADEOUTREGA => open,       -- [out std_ulogic]

          CLKB => CLKB,                 -- [in  std_ulogic]            
          ENB  => ENB,                  -- [in  std_ulogic]

          ADDRB          => addrb_i,    -- [in  std_logic_vector (15 downto 0)]
          WEB            => web_ii,     -- [in  std_logic_vector (3 downto 0)]
          DIB            => dib_i,      -- [in  std_logic_vector (31 downto 0)]
          DIPB           => dibp_i,     -- [in  std_logic_vector (3 downto 0)]
          DOB            => dob_i,      -- [out std_logic_vector (31 downto 0)]
          DOPB           => open,       -- [out std_logic_vector (3 downto 0)]
          SSRB           => '0',        -- [in  std_ulogic]
          REGCEB         => '1',        -- [in  std_ulogic]
          CASCADEOUTLATB => open,       -- [out std_ulogic]
          CASCADEINLATB  => '0',        -- [in  std_ulogic]
          CASCADEINREGB  => '0',        -- [in  std_ulogic]
          CASCADEOUTREGB => open);      -- [out std_ulogic]
    end generate The_BRAMs;
  end generate Using_B36_S2;

  Using_B16_S2 : if (What_BRAM.What_Kind = B16_S2) generate
    signal wea_i : std_logic_vector(0 to (nr_of_brams+3)/4-1);
    signal web_i : std_logic_vector(0 to (nr_of_brams+3)/4-1);
  begin

    Pad_RAMB16_S2_S2_Signals : process (WEA, WEB) is
    begin  -- process Pad_RAMB16_S2_S2_Signals
      assign(wea_i, WEA);
      assign(web_i, WEB);
    end process Pad_RAMB16_S2_S2_Signals;

    -- Write enables are tied to one for each four bram block (to support byte enables)
    The_BRAMs : for I in 0 to nr_of_brams+extra_parity_brams-1 generate
      signal wea_ii : std_logic;
      signal dia_i  : std_logic_vector(0 to 1);
      signal doa_i  : std_logic_vector(0 to 1);
      signal web_ii : std_logic;
      signal dib_i  : std_logic_vector(0 to 1);
      signal dob_i  : std_logic_vector(0 to 1);
    begin

      Pad_RAMB16_S2_S2_Data_WE : if I < nr_of_brams - parity_brams generate
      begin
        -- Data BRAMs
        wea_ii                    <= wea_i(I/4);
        dia_i                     <= data_ina_i(I*2 to I*2+1);
        data_outa_i(I*2 to I*2+1) <= doa_i;

        web_ii                    <= web_i(I/4);
        dib_i                     <= data_inb_i(I*2 to I*2+1);
        data_outb_i(I*2 to I*2+1) <= dob_i;
      end generate Pad_RAMB16_S2_S2_Data_WE;

      Pad_RAMB16_S2_S2_Parity_WE : if I >= nr_of_brams - parity_brams generate
        constant parity_we_index : integer := I - nr_of_brams + parity_brams;
        constant data_index      : integer := C_DATA_WIDTH - din_parity_bits + parity_we_index;
      begin
        -- Parity BRAMs: One BRAM for each parity bit and write enable bit
        wea_ii                    <= wea_i(parity_we_index);
        dia_i                     <= "0" & data_ina_i(data_index);
        data_outa_i(data_index)   <= doa_i(1);

        web_ii                    <= web_i(parity_we_index);
        dib_i                     <= "0" & data_inb_i(data_index);
        data_outb_i(data_index)   <= dob_i(1);
      end generate Pad_RAMB16_S2_S2_Parity_WE;

      RAMB16_S2_1 : RAMB16_S2_S2
        generic map (
          SIM_COLLISION_CHECK => sim_check_mode,
          WRITE_MODE_A        => write_mode,
          WRITE_MODE_B        => write_mode)
        port map (
          -- Port A
          CLKA  => CLKA,     -- [in  std_ulogic]
          ENA   => ENA,      -- [in  std_ulogic]
          WEA   => wea_ii,   -- [in  std_ulogic]
          DIA   => dia_i,    -- [in  std_logic_vector (1 downto 0)]
          ADDRA => addra_i,  -- [in  std_logic_vector (12 downto 0)]
          DOA   => doa_i,    -- [out std_logic_vector (1 downto 0)]
          SSRA  => '0',      -- [in  std_ulogic]
          -- Port B
          CLKB  => CLKB,     -- [in  std_ulogic]
          ENB   => ENB,      -- [in  std_ulogic]
          WEB   => web_ii,   -- [in  std_ulogic]
          DIB   => dib_i,    -- [in  std_logic_vector (1 downto 0)]
          ADDRB => addrb_i,  -- [in  std_logic_vector (12 downto 0)]
          DOB   => dob_i,    -- [out std_logic_vector (1 downto 0)]
          SSRB  => '0'       -- [in  std_ulogic]
          );
    end generate The_BRAMs;
  end generate Using_B16_S2;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  --  BRAM organized as x1
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  Using_B36_S1 : if (What_BRAM.What_Kind = B36_S1) generate
    signal addra_i : std_logic_vector(15 downto 0);
    signal addrb_i : std_logic_vector(15 downto 0);
    signal wea_i   : std_logic_vector(0 to (nr_of_brams+7)/8-1);
    signal web_i   : std_logic_vector(0 to (nr_of_brams+7)/8-1);
  begin

    Pad_RAMB36_Addresses : process (ADDRA, ADDRB, WEA, WEB) is
      begin  -- process Pad_RAMB36_Addresses
        assign(wea_i, WEA);
        assign(web_i, WEB);

        -- Address bit 15 is only used when BRAMs are cascaded
        addra_i                            <= (others => '0');
        addra_i(14 downto 15-C_ADDR_WIDTH) <= ADDRA;
        addrb_i                            <= (others => '0');
        addrb_i(14 downto 15-C_ADDR_WIDTH) <= ADDRB;
    end process Pad_RAMB36_Addresses;

    The_BRAMs : for I in 0 to nr_of_brams-1 generate
      signal wea_ii : std_logic_vector(0 to 3);
      signal dia_i  : std_logic_vector(0 to 31);
      signal diap_i : std_logic_vector(0 to 3);
      signal doa_i  : std_logic_vector(0 to 31);
      signal doap_i : std_logic_vector(0 to 3);
      signal web_ii : std_logic_vector(0 to 3);
      signal dib_i  : std_logic_vector(0 to 31);
      signal dibp_i : std_logic_vector(0 to 3);
      signal dob_i  : std_logic_vector(0 to 31);
      signal dobp_i : std_logic_vector(0 to 3);
    begin

      Pad_RAMB36_Data_WE : if I < nr_of_brams - parity_brams generate
      begin
        -- Data BRAMs
        wea_ii <= (others => wea_i(I/8));
        web_ii <= (others => web_i(I/8));
      end generate Pad_RAMB36_Data_WE;

      Pad_RAMB36_Parity_WE : if I >= nr_of_brams - parity_brams generate
        constant parity_we_index : integer := I - nr_of_brams + parity_brams;
      begin
        -- Parity BRAMs: One BRAM for each parity bit and write enable bit
        wea_ii <= (others => wea_i(parity_we_index));
        web_ii <= (others => web_i(parity_we_index));
      end generate Pad_RAMB36_Parity_WE;

      dia_i          <= "0000000000000000000000000000000" & data_ina_i(I);
      diap_i         <= "0000";
      data_outa_i(I) <= doa_i(31);

      dib_i          <= "0000000000000000000000000000000" & data_inb_i(I);
      dibp_i         <= "0000";
      data_outb_i(I) <= dob_i(31);

      RAMB36_I1 : RAMB36
        generic map (
          DOA_REG             => 0,               -- [integer]
          DOB_REG             => 0,               -- [integer]
          RAM_EXTENSION_A     => "NONE",          -- [string]
          RAM_EXTENSION_B     => "NONE",          -- [string]
      -- pragma translate_off
          INIT_FILE           => init_string(I),
      -- pragma translate_on
          READ_WIDTH_A        => 1,               -- [integer]
          READ_WIDTH_B        => 1,               -- [integer]
          SIM_COLLISION_CHECK => sim_check_mode,  -- [string]
          WRITE_MODE_A        => write_mode,      -- [string]
          WRITE_MODE_B        => write_mode,      -- [string]
          WRITE_WIDTH_A       => 1,               -- [integer]
          WRITE_WIDTH_B       => 1)               -- [integer]
        port map (
          CLKA => CLKA,                           -- [in  std_ulogic]
          ENA  => ENA,                            -- [in  std_ulogic]

          ADDRA          => addra_i,    -- [in  std_logic_vector(15 downto 0)]
          WEA            => wea_ii,     -- [in  std_logic_vector(3 downto 0)]
          DIA            => dia_i,      -- [in  std_logic_vector (31 downto 0)]
          DIPA           => diap_i,     -- [in  std_logic_vector (3 downto 0)]
          DOA            => doa_i,      -- [out std_logic_vector (31 downto 0)]
          DOPA           => open,       -- [out std_logic_vector (3 downto 0)]
          SSRA           => '0',        -- [in  std_ulogic]
          REGCEA         => '1',        -- [in  std_ulogic]
          CASCADEOUTLATA => open,       -- [out std_ulogic]
          CASCADEINLATA  => '0',        -- [in  std_ulogic]
          CASCADEINREGA  => '0',        -- [in  std_ulogic]
          CASCADEOUTREGA => open,       -- [out std_ulogic]

          CLKB => CLKB,                 -- [in  std_ulogic]            
          ENB  => ENB,                  -- [in  std_ulogic]

          ADDRB          => addrb_i,    -- [in  std_logic_vector(15 downto 0)]
          WEB            => web_ii,     -- [in  std_logic_vector(3 downto 0)]
          DIB            => dib_i,      -- [in  std_logic_vector (31 downto 0)]
          DIPB           => dibp_i,     -- [in  std_logic_vector (3 downto 0)]
          DOB            => dob_i,      -- [out std_logic_vector (31 downto 0)]
          DOPB           => open,       -- [out std_logic_vector (3 downto 0)]
          SSRB           => '0',        -- [in  std_ulogic]
          REGCEB         => '1',        -- [in  std_ulogic]
          CASCADEOUTLATB => open,       -- [out std_ulogic]
          CASCADEINLATB  => '0',        -- [in  std_ulogic]
          CASCADEINREGB  => '0',        -- [in  std_ulogic]
          CASCADEOUTREGB => open);      -- [out std_ulogic]
    end generate The_BRAMs;
  end generate Using_B36_S1;

  Using_B16_S1 : if (What_BRAM.What_Kind = B16_S1) generate
    signal wea_i : std_logic_vector(0 to (nr_of_brams+7)/8-1);
    signal web_i : std_logic_vector(0 to (nr_of_brams+7)/8-1);
  begin
    -- Write enables are tied to one for each four bram block (to support byte enables)
    The_BRAMs : for I in 0 to nr_of_brams-1 generate
      signal wea_ii : std_logic;
      signal web_ii : std_logic;
    begin

      Pad_RAMB16_S1_S1_Signals : process (WEA, WEB) is
      begin  -- process Pad_RAMB16_S1_S1_Signals
        assign(wea_i, WEA);
        assign(web_i, WEB);
      end process Pad_RAMB16_S1_S1_Signals;

      Pad_RAMB16_Data_WE : if I < nr_of_brams - parity_brams generate
      begin
        -- Data BRAMs
        wea_ii <= wea_i(I/8);
        web_ii <= web_i(I/8);
      end generate Pad_RAMB16_Data_WE;

      Pad_RAMB16_Parity_WE : if I >= nr_of_brams - parity_brams generate
        constant parity_we_index : integer := I - nr_of_brams + parity_brams;
      begin
        -- Parity BRAMs: One BRAM for each parity bit and write enable bit
        wea_ii <= wea_i(parity_we_index);
        web_ii <= web_i(parity_we_index);
      end generate Pad_RAMB16_Parity_WE;

      RAMB16_S1_1 : RAMB16_S1_S1
        generic map (
          SIM_COLLISION_CHECK => sim_check_mode,
          WRITE_MODE_A        => write_mode,
          WRITE_MODE_B        => write_mode)
        port map (
          -- Port A
          CLKA  => CLKA,                -- [in  std_ulogic]
          ENA   => ENA,                 -- [in  std_ulogic]
          WEA   => wea_ii,              -- [in  std_ulogic]
          DIA   => data_ina_i(I to I),  -- [in  std_logic_vector (0 downto 0)]
          ADDRA => addra_i,             -- [in  std_logic_vector (13 downto 0)]
          DOA   => data_outa_i(I to I), -- [out std_logic_vector (0 downto 0)]
          SSRA  => '0',                 -- [in  std_ulogic]
          -- Port B
          CLKB  => CLKB,                -- [in  std_ulogic]
          ENB   => ENB,                 -- [in  std_ulogic]
          WEB   => web_ii,              -- [in  std_ulogic]
          DIB   => data_inb_i(I to I),  -- [in  std_logic_vector (0 downto 0)]
          ADDRB => addrb_i,             -- [in  std_logic_vector (13 downto 0)]
          DOB   => data_outb_i(I to I), -- [out std_logic_vector (0 downto 0)]
          SSRB  => '0'                  -- [in  std_ulogic]
          );
    end generate The_BRAMs;
  end generate Using_B16_S1;

  Using_DistRAM : if (What_BRAM.What_Kind = DISTRAM) generate
    constant native_max_addr_size : integer := 7;
  begin
    Recursive : if (What_BRAM.Addr_size > native_max_addr_size) generate
      constant num_ram_modules : integer:= 2 ** ( What_BRAM.Addr_size - native_max_addr_size );
      type ram_output is array (0 to num_ram_modules - 1) of std_logic_vector(0 to just_data_bits_size-1);
      
      signal addra_cmb  : std_logic_vector(0 to What_BRAM.Addr_size - native_max_addr_size - 1);
      signal addrb_cmb  : std_logic_vector(0 to What_BRAM.Addr_size - native_max_addr_size - 1);
      signal addra_q    : std_logic_vector(0 to What_BRAM.Addr_size - native_max_addr_size - 1);
      signal addrb_q    : std_logic_vector(0 to What_BRAM.Addr_size - native_max_addr_size - 1);
      signal data_a     : ram_output;
      signal data_b     : ram_output;
    begin
      -- Extract module address.
      addra_cmb <= addra_i(addra_i'left to addra_i'right - native_max_addr_size);
      addrb_cmb <= addrb_i(addrb_i'left to addrb_i'right - native_max_addr_size);

      -- Instantiate all modules needed for the memory.
      The_RAM_INSTs : for J in 0 to num_ram_modules-1 generate
        signal wea_i : std_logic_vector(0 to C_WE_WIDTH-1);
        signal web_i : std_logic_vector(0 to C_WE_WIDTH-1);
      begin

        -- Generate local write enable
        wea_i <= WEA when to_integer(unsigned(addra_cmb)) = J else (others=>'0');
        web_i <= WEB when to_integer(unsigned(addrb_cmb)) = J else (others=>'0');
 
        RAM_Inst: RAM_Module_Top
          generic map (
            C_TARGET        => C_TARGET,
            C_DATA_WIDTH    => just_data_bits_size,
            C_WE_WIDTH      => C_WE_WIDTH,
            C_ADDR_WIDTH    => native_max_addr_size,
            C_USE_INIT_FILE => C_USE_INIT_FILE,
            C_FORCE_BRAM    => C_FORCE_BRAM,
            C_FORCE_LUTRAM  => C_FORCE_LUTRAM)
          port map(
            -- PORT A
            CLKA      => CLKA,
            WEA       => wea_i,
            ENA       => ENA,
            ADDRA     => addra_i(addra_i'right - native_max_addr_size + 1 to addra_i'right),
            DATA_INA  => data_ina_i,
            DATA_OUTA => data_a(J),
            -- PORT B
            CLKB      => CLKB,
            WEB       => web_i,
            ENB       => ENB,
            ADDRB     => addrb_i(addrb_i'right - native_max_addr_size + 1 to addrb_i'right),
            DATA_INB  => data_inb_i,
            DATA_OUTB => data_b(J)
            );
      end generate The_RAM_INSTs;

      -- Clock address for multiplexing the delayed memory data.
      PortA : process(CLKA)
      begin
        if CLKA'event and CLKA = '1' then
          if ENA = '1' then
            addra_q <= addra_cmb;
          end if;
        end if;
      end process PortA;

      PortB : process(CLKB)
      begin
        if CLKB'event and CLKB = '1' then
          if ENB = '1' then
            addrb_q <= addrb_cmb;
          end if;
        end if;
      end process PortB;

      -- Multiplex data from memory.
      data_outa_i <= data_a(to_integer(unsigned(addra_q)));
      data_outb_i <= data_b(to_integer(unsigned(addrb_q)));

    end generate Recursive;

    Native : if (What_BRAM.Addr_size <= native_max_addr_size) generate
      signal web_i : std_logic_vector(0 to nr_of_brams-1);
    begin
      The_DistRAMs : for I in 0 to nr_of_brams-1 generate
      begin

        Pad_DistRAM_Signal : process (WEB) is
        begin  -- process Pad_DistRAM_Signal
          assign(web_i, WEB);
        end process Pad_DistRAM_Signal;

        Block_DistRAM : block
          type RAM_Type is
            array (0 to 2**C_ADDR_WIDTH - 1) of std_logic_vector(0 to 7);

          signal RAM : RAM_Type := (others => "00000000");

          attribute ram_style        : string;
          attribute ram_style of RAM : signal is "distributed";
        begin

          PortA : process(CLKA)
          begin
            if CLKA'event and CLKA = '1' then
              -- Assume that write port A is not used
              if ENA = '1' then
                data_outa_i(I*8 to I*8+7) <= RAM(to_integer(unsigned(addra_i)));
              end if;
            end if;
          end process PortA;

          PortB : process(CLKB)
          begin
            if CLKB'event and CLKB = '1' then
              if ENB = '1' and web_i(I) = '1' then
                RAM(to_integer(unsigned(addrb_i))) <= data_inb_i(I*8 to I*8+7);
                data_outb_i(I*8 to I*8+7) <= RAM(to_integer(unsigned(addrb_i)));
              elsif ENB = '1' then
                data_outb_i(I*8 to I*8+7) <= RAM(to_integer(unsigned(addrb_i)));
              end if;
            end if;
          end process PortB;

        end block Block_DistRAM;
      end generate The_DistRAMS;
    end generate Native;
  end generate Using_DistRAM;

end architecture IMP;
