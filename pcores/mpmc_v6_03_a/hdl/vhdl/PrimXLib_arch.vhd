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
-- Filename - dp_ram_async_diffw_ramb.vhd
-- Author - CJM, Xilinx
-- Creation - 8 Nov 2005
--
--
-- ************************************************************************
--
-- INDEX
--
--  001 dp_ram_async_diffw  --  Dual-port RAM (with common clock; BlockRAM, Dist RAM, or Registers)
-- ************************************************************************

-- ************************************************************************
--
--  *001*   Asynchronous Asymmetric Dual-Port RAM Macro 
--
-- Description: Dual-Port RAM
--              With Asynchronous Clocks
--              And with Different Data Widths
-- Technology: RTL/Gate Primative
--
-- Author: Chris Martin
-- Revision: 1.15
--
-- ************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

LIBRARY work;
USE work.memxlib_utils.ALL;

entity dp_ram_async_diffw is
    generic( FAMILY     :  string := "V4";           -- S3, V2, V4, V5
             input_reg  : integer := 0;              -- Add Output Pipeline Register
             dwidtha    : integer := 8;              -- Side A Data Width
             dwidthb    : integer := 32;             -- Side B Data Width
             mem_sizea  : integer := 1024;           -- Side A Memory Size
             mem_sizeb  : integer := 256;            -- Side B Memory Size
             mem_type   : string  := BLOCK_RAMSTYLE; -- Memory Type: BRAM, Distributed or registers
             WRITEMODEA : string  := "WRITE_FIRST";  -- WRITE_FIRST, READ_FIRST, or NO_CHANGE
             WRITEMODEB : string  := "WRITE_FIRST"   -- WRITE_FIRST, READ_FIRST, or NO_CHANGE
    );
    port (da        : in std_logic_vector(dwidtha-1 downto 0);               -- Side A Data Input
          db        : in std_logic_vector(dwidthb-1 downto 0);               -- Side B Data Input
          addra     : in std_logic_vector(logbase2(mem_sizea-1)-1 downto 0); -- Side A Address Input
          addrb     : in std_logic_vector(logbase2(mem_sizeb-1)-1 downto 0); -- Side B Address Input
          clka      : in std_logic;                                          -- Side A Clock Input
          clkb      : in std_logic;                                          -- Side B Clock Input
          wea       : in std_logic;                                          -- Side A Write Enable Input. Active High
          web       : in std_logic;                                          -- Side B Write Enable Input. Active High   
          qa        : out std_logic_vector(dwidtha-1 downto 0);              -- Side A Data Output,1 cycle dly if input_reg=1
          qb        : out std_logic_vector(dwidthb-1 downto 0)               -- Side B Data Output,1 cycle dly if input_reg=1
    );
end dp_ram_async_diffw;



architecture ramb of dp_ram_async_diffw is
  function maximum (
    left, 
    right : integer)                     -- inputs
    return integer is
  begin  -- function max
    if LEFT > RIGHT then 
      return LEFT;
    else 
      return RIGHT;
    end if;
  end function maximum;

  function minimum (
    left, 
    right : integer)                     -- inputs
    return integer is
  begin  -- function max
    if LEFT < RIGHT then 
      return LEFT;
    else 
      return RIGHT;
    end if;
  end function minimum;


  function gcd(
    left, 
    right : integer)                     -- inputs
    return integer is

    variable t : integer;
    variable a : integer;
    variable b : integer;
  begin  -- function max
    b := right;
    a := left;
    while(b /= 0) loop
      t := b;
      b := a mod b;
      a := t; 
    end loop;
    return a;
  end function gcd;

  function lcm(
    left, 
    right : integer)                     -- inputs
    return integer is

  begin  -- function max
    return left*right / gcd(left, right);
  end function lcm;

  function gcd2(data : integer) return integer is
    variable count_bits : integer := 0;
    variable data_std : std_logic_vector(31 downto 0) := CONV_STD_LOGIC_VECTOR(data,32);
    variable found_one : integer := 0;
  begin
    for I in data_std'range loop
      if ((data_std(0) = '0') and (found_one = 0)) then
        count_bits := count_bits + 1;
        data_std := CONV_STD_LOGIC_VECTOR(CONV_INTEGER(data_std)/2,32);
      else
        found_one := 1;
      end if;
    end loop;

    return 2 ** count_bits;

  end;

  function limit_width(width, ratio, depth : integer) return integer is
    variable limited_width: integer := 0;
  begin
      
      limited_width := width; 
      -- Limit by width 
      -- If largest width is greater than 32, then we must divide into other block rams
      while (limited_width*ratio > 32) loop
        limited_width := limited_width/2;
      end loop;
      
      if(limited_width <= 0) then
        assert false report "DP_RAM: Memory Width Ratio is Too Large!"
severity error;
      end if;

      -- Limit by depth
      -- If there is is not enough block ram spread across more rams
      --while (depth*limited_width > 32768) loop
      while (depth*limited_width > 16384) loop
        limited_width := limited_width/2;
      end loop;
      
       
      if(limited_width <= 0) then
        assert false report "DP_RAM: Memory Depth is Too Large!" severity
error;
      end if;

    return maximum(1,limited_width);

  end;

--------------------------------------------------------------------------------
constant dwidth_narrow   : integer := minimum(dwidtha,dwidthb);
constant dwidth_wide    : integer := maximum(dwidtha,dwidthb);

constant addwidth_narrow : integer := logbase2(maximum(mem_sizea,mem_sizeb)-1);
constant addwidth_wide  : integer := logbase2(minimum(mem_sizea,mem_sizeb)-1);
constant width_ratio    : integer := dwidth_wide/dwidth_narrow;
constant ideal_width: integer := gcd2(dwidth_narrow); 
constant ram_narrow_width: integer := limit_width(ideal_width, width_ratio, maximum(mem_sizea,mem_sizeb));
--constant num_of_ramb16 : integer := maximum(1,mem_sizea * dwidtha / 16 / 1024);
--constant ram_narrow_width : integer := dwidth_narrow / num_of_ramb16;
constant ram_wide_width : integer := ram_narrow_width * width_ratio;

constant a_width : integer := ram_narrow_width + (ram_narrow_width/8);
constant b_width : integer := ram_wide_width  + (ram_wide_width/8);

constant dws32  : integer := minimum(32,dwidth_narrow);
constant dww32  : integer := minimum(32,dwidth_wide);


constant mem_size_slvs  : std_logic_vector(addwidth_narrow-1 downto 0) :=
 CONV_STD_LOGIC_VECTOR(maximum(mem_sizea,mem_sizeb)-1,addwidth_narrow);
constant mem_size_slvw  : std_logic_vector(addwidth_wide -1 downto 0) :=
 CONV_STD_LOGIC_VECTOR(minimum(mem_sizea,mem_sizeb)-1,addwidth_wide);
constant dead           : std_logic_vector(255 downto 0) := x"deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef";

constant gnd            : std_logic_vector(31 downto 0) := x"00000000";

--type mem_array is array (mem_sizea -1 downto 0) of std_logic_vector (dwidth_narrow-1 downto 0);
----signal mem : mem_array;
--shared variable mem : mem_array;
signal addra_int : std_logic_vector(addwidth_narrow-1 downto 0);
signal addrb_int : std_logic_vector(addwidth_narrow-1 downto 0);
signal addra_int2 : std_logic_vector(addwidth_narrow-1 downto 0);
signal addrb_int2 : std_logic_vector(addwidth_narrow-1 downto 0);
signal da_int : std_logic_vector(dwidth_narrow-1 downto 0);
signal da_guard : std_logic_vector(dwidth_narrow-1 downto 0);
signal wea_int : std_logic;
signal db_int : std_logic_vector(dwidth_narrow-1 downto 0);
signal db_guard : std_logic_vector(dwidth_narrow-1 downto 0);
signal web_int : std_logic;

signal addra_guard : std_logic_vector(addwidth_narrow-1 downto 0);
signal addrb_guard : std_logic_vector(addwidth_narrow-1 downto 0);

type dq_array is array (dwidth_narrow-1 downto 0) of std_logic_vector(31 downto 0);
signal ramb_q_narrow   : dq_array;
signal ramb_q_wide     : dq_array;
signal ramb_d_narrow   : dq_array;
signal ramb_d_wide     : dq_array;
signal t_ramb_q_narrow : dq_array;
signal t_ramb_q_wide   : dq_array;

signal d_narrow         : std_logic_vector(dwidth_narrow-1 downto 0);
signal d_wide           : std_logic_vector(dwidth_wide-1 downto 0);

signal d_narrow_guard   : std_logic_vector(dwidth_narrow-1 downto 0);
signal d_wide_guard     : std_logic_vector(dwidth_wide-1 downto 0);

signal d_wide_temp      : std_logic_vector(dwidth_wide-1 downto 0);

signal q_narrow         : std_logic_vector(dwidth_narrow-1 downto 0);
signal q_wide           : std_logic_vector(dwidth_wide-1 downto 0);

signal q_wide_temp      : std_logic_vector(dwidth_wide-1 downto 0);

signal addr_narrow      : std_logic_vector(addwidth_narrow-1 downto 0);
signal addr_wide        : std_logic_vector(addwidth_wide-1 downto 0);

signal addr_narrow_guard : std_logic_vector(14 downto 0);
signal addr_wide_guard   : std_logic_vector(14 downto 0);

signal we_narrow        : std_logic;
signal we_wide          : std_logic;

signal clk_narrow       : std_logic;
signal clk_wide         : std_logic;


signal s3_addr_narrow_guard      : std_logic_vector(13 downto 0);
signal s3_addr_wide_guard        : std_logic_vector(13 downto 0);

--attribute syn_ramstyle          : string;
--attribute syn_ramstyle of mem   : variable is mem_type;
--attribute ram_style             : string;
--attribute ram_style of mem      : variable is mem_type;

begin
  GEN_DIFFERENT_WIDTH: if(dwidthb /= dwidtha) generate

    --------------------------------------------------------------------------- 
    --------------------------------------------------------------------------- 

    GEN_NARROW_ADDR_EQ_1: if(ram_narrow_width = 1) generate
      addr_narrow_guard       <= gnd(14 downto 14) & addr_narrow;
    end generate GEN_NARROW_ADDR_EQ_1;

    GEN_NARROW_ADDR_NEQ_1: if(ram_narrow_width /= 1) generate
      addr_narrow_guard       <= gnd(14 downto addwidth_narrow + logbase2(ram_narrow_width-1)) & addr_narrow &
       gnd(logbase2(ram_narrow_width-1)-1 downto 0);
    end generate GEN_NARROW_ADDR_NEQ_1;

    GEN_WIDE_ADDR_EQ_1: if(ram_narrow_width*width_ratio = 1) generate
      addr_wide_guard         <= gnd(14 downto 14) & addr_wide;
    end generate GEN_WIDE_ADDR_EQ_1;

    GEN_WIDE_ADDR_NEQ_1: if(ram_narrow_width*width_ratio /= 1) generate
      addr_wide_guard         <= gnd(14 downto addwidth_wide + logbase2(ram_narrow_width*width_ratio-1)) & addr_wide &
       gnd(logbase2(ram_narrow_width*width_ratio-1)-1 downto 0);
    end generate GEN_WIDE_ADDR_NEQ_1;

    guard:process(addr_narrow,addr_wide,d_narrow,d_wide)
    begin
        s3_addr_narrow_guard     <= gnd(13 downto addr_narrow'length) & addr_narrow;
        s3_addr_wide_guard      <= gnd(13 downto addr_wide'length) & addr_wide;



        d_narrow_guard          <= d_narrow;
        d_wide_guard            <= d_wide;

--    -- synopsys translate_off
--        if addr_narrow > mem_size_slvs then
--          addr_narrow_guard <= (others => '0');
--          d_narrow_guard    <= dead(dwidth_narrow-1 downto 0);
--    --    assert false report "Address outside range on port A." severity warning;
--        end if;
--        if addr_wide > mem_size_slvw then
--          addr_wide_guard <= (others => '0');
--          d_wide_guard    <= dead(dwidth_wide-1 downto 0);
--    --    assert false report "Address outside range on port B." severity warning;
--        end if;
--    -- synopsys translate_on
    end process;



    --------------------------------------------------------------------------- 
    --------------------------------------------------------------------------- 
    gen_b_wide: if(dwidthb >= dwidtha) generate
      d_narrow     <= da;
      d_wide      <= db;
  
      qa          <= q_narrow;
      qb          <= q_wide;
    
      addr_narrow  <= addra;
      addr_wide   <= addrb;
      
      we_narrow    <= wea;
      we_wide     <= web; 
  
      clk_narrow   <= clka; 
      clk_wide    <= clkb;
    end generate;
  
    --------------------------------------------------------------------------- 
    --------------------------------------------------------------------------- 
    gen_a_wide: if(dwidtha > dwidthb) generate
      d_narrow     <= db;
      d_wide      <= da;
  
      qb          <= q_narrow;
      qa          <= q_wide;
    
      addr_narrow  <= addrb;
      addr_wide   <= addra;
      
      we_narrow    <= web;
      we_wide     <= wea; 
  
      clk_narrow   <= clkb; 
      clk_wide    <= clka;
    end generate;
  
    --------------------------------------------------------------------------- 
    -- Power or 2 or Non-power of 2
    --------------------------------------------------------------------------- 
    gen_ram_ibit: for i in 0 to ((dwidth_narrow/ram_narrow_width)-1) generate
  
      -- RAM A Data inputs
      ramb_d_narrow(i) <= gnd(31 downto ram_narrow_width) & d_narrow_guard((ram_narrow_width*(i+1))-1 downto ram_narrow_width*i);
  
      -- RAM B Data inputs
      gen_d_wide:  for j in 0 to width_ratio-1 generate
        d_wide_temp(       ((width_ratio*i + j+1)*ram_narrow_width)-1 
                    downto (width_ratio*i + j)*ram_narrow_width      ) <= d_wide_guard(       ((i+1)*ram_narrow_width +
                     (j*dwidth_narrow))-1 
                                                                                      downto i*ram_narrow_width + (j*dwidth_narrow)
                                                                                              ); 
      end generate;
  
      GEN_32BIT: if(ram_wide_width = 32) generate
        ramb_d_wide(i)  <= d_wide_temp((ram_wide_width*(i+1))-1 downto ram_wide_width*i);
      end generate GEN_32BIT;

      GEN_LT32BIT: if(ram_wide_width < 32) generate
        ramb_d_wide(i)  <= gnd(31 downto ram_wide_width) & d_wide_temp((ram_wide_width*(i+1))-1 downto ram_wide_width*i);
      end generate GEN_LT32BIT;
      
      GEN_VIRTEX4_RAM: if((FAMILY /= "S3") and (FAMILY /= "V2")) generate
        -- RAM Insts
        ramb16_i: ramb16
        generic map(
          DOA_REG => input_reg,
          DOB_REG => input_reg,
          SRVAL_A => "000000000000000000000000000000000000",
          WRITE_MODE_A => WRITEMODEA,
          SRVAL_B => "000000000000000000000000000000000000",
          WRITE_MODE_B => WRITEMODEB,
          READ_WIDTH_A  => a_width,
          WRITE_WIDTH_A => a_width,
          READ_WIDTH_B  => b_width,
          WRITE_WIDTH_B => b_width,
          SIM_COLLISION_CHECK => "NONE"
        )
        port map (
          DIA => ramb_d_narrow(i),
          DOA => ramb_q_narrow(i),
      
          DOPA => open,  
          CASCADEOUTA => open,
          CASCADEOUTB => open,
          DIPA(0) => '0',
          DIPA(1) => '0',
          DIPA(2) => '0',
          DIPA(3) => '0',
          ADDRA => addr_narrow_guard,
          ENA => '1',
          REGCEA => '1',
          WEA(0) => we_narrow,
          WEA(1) => we_narrow,
          WEA(2) => we_narrow,
          WEA(3) => we_narrow,
          SSRA => '0',
          CLKA => clk_narrow,
          CASCADEINA => '0',
      
          DIB => ramb_d_wide(i),
          DIPB(0) => '0',
          DIPB(1) => '0',
          DIPB(2) => '0',
          DIPB(3) => '0',
          DOB => ramb_q_wide(i),
          DOPB => open,
      
          ADDRB => addr_wide_guard,
          ENB => '1',
          REGCEB => '1',
          WEB(0) => we_wide,
          WEB(1) => we_wide,
          WEB(2) => we_wide,
          WEB(3) => we_wide,
          SSRB => '0',
          CLKB => clk_wide,
          CASCADEINB => '0'
        );
      end generate; 
      -------------------------------------------------------------------------------
      -- Spartan 3 Block Rams
      -------------------------------------------------------------------------------
      GEN_SPARTAN3_RAM: if((FAMILY = "S3") or (FAMILY = "V2")) generate
        outreg_gen : if (input_reg = 1) generate
           Output_Reg : process(clk_wide)
           begin
              if (clk_wide'event) and (clk_wide = '1') then
                 ramb_q_wide(i)  <= t_ramb_q_wide(i);
                 ramb_q_narrow(i) <= t_ramb_q_narrow(i);
              end if;
           end process;
        end generate;
        no_outreg_gen : if (input_reg = 0) generate
           Passthru: process(t_ramb_q_narrow, t_ramb_q_wide)
           begin
              ramb_q_wide(i)  <= t_ramb_q_wide(i);
              ramb_q_narrow(i) <= t_ramb_q_narrow(i);
           end process;
        end generate;
  
        -------------------------------------------------------------------------------
        GEN_S36_S36_RAM: if(a_width = 36) generate
           S3_BRAM_INST : RAMB16_S36_S36
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(8 downto 0),
              DIA      => ramb_d_narrow(i),
              WEA      => we_narrow,
              DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i),
              DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(8 downto 0),
              DIB      => ramb_d_wide(i),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i),
              DOPB     => open
           );

        end generate GEN_S36_S36_RAM;
        -------------------------------------------------------------------------------
        GEN_S18_S18_RAM: if((a_width = 18) and (b_width = 18)) generate
           S3_BRAM_INST : RAMB16_S18_S18
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB 
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(9 downto 0),
              DIA      => ramb_d_narrow(i)(15 downto 0),
              WEA      => we_narrow,
              DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(15 downto 0),
              DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(9 downto 0),
              DIB      => ramb_d_wide(i)(15 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(15 downto 0),
              DOPB     => open
           );

        end generate GEN_S18_S18_RAM;
        -------------------------------------------------------------------------------
        GEN_S18_S36_RAM: if((a_width = 18) and (b_width = 36)) generate
           S3_BRAM_INST : RAMB16_S18_S36
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(9 downto 0),
              DIA      => ramb_d_narrow(i)(15 downto 0),
              WEA      => we_narrow,
              DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(15 downto 0),
              DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(8 downto 0),
              DIB      => ramb_d_wide(i),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i),
              DOPB     => open
           );

        end generate GEN_S18_S36_RAM;
        -------------------------------------------------------------------------------
        GEN_S9_S9_RAM: if((a_width = 9) and (b_width = 9)) generate
           S3_BRAM_INST : RAMB16_S9_S9
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(10 downto 0),
              DIA      => ramb_d_narrow(i)(7 downto 0),
              WEA      => we_narrow,
              DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(7 downto 0),
              DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(10 downto 0),
              DIB      => ramb_d_wide(i)(7 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(7 downto 0),
              DOPB     => open
           );

        end generate GEN_S9_S9_RAM;
        -------------------------------------------------------------------------------
        GEN_S9_S18_RAM: if((a_width = 9) and (b_width = 18)) generate
           S3_BRAM_INST : RAMB16_S9_S18
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(10 downto 0),
              DIA      => ramb_d_narrow(i)(7 downto 0),
              WEA      => we_narrow,
              DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(7 downto 0),
              DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(9 downto 0),
              DIB      => ramb_d_wide(i)(15 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(15 downto 0),
              DOPB     => open
           );

        end generate GEN_S9_S18_RAM;
        -------------------------------------------------------------------------------
        GEN_S9_S36_RAM: if((a_width = 9) and (b_width = 36)) generate
           S3_BRAM_INST : RAMB16_S9_S36
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(10 downto 0),
              DIA      => ramb_d_narrow(i)(7 downto 0),
              WEA      => we_narrow,
              DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(7 downto 0),
              DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(8 downto 0),
              DIB      => ramb_d_wide(i),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i),
              DOPB     => open
           );

        end generate GEN_S9_S36_RAM;
        -------------------------------------------------------------------------------
        GEN_S4_S4_RAM: if((a_width = 4) and (b_width = 4)) generate
           S3_BRAM_INST : RAMB16_S4_S4
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(11 downto 0),
              DIA      => ramb_d_narrow(i)(3 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(3 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(11 downto 0),
              DIB      => ramb_d_wide(i)(3 downto 0),
              WEB      => we_wide,
              --DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(3 downto 0)
              --DOPB     => open
           );

        end generate GEN_S4_S4_RAM;
        -------------------------------------------------------------------------------
        GEN_S4_S9_RAM: if((a_width = 4) and (b_width = 9)) generate
           S3_BRAM_INST : RAMB16_S4_S9
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(11 downto 0),
              DIA      => ramb_d_narrow(i)(3 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(3 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(10 downto 0),
              DIB      => ramb_d_wide(i)(7 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(7 downto 0),
              DOPB     => open
           );

        end generate GEN_S4_S9_RAM;
        -------------------------------------------------------------------------------
        GEN_S4_S18_RAM: if((a_width = 4) and (b_width = 18)) generate
           S3_BRAM_INST : RAMB16_S4_S18
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(11 downto 0),
              DIA      => ramb_d_narrow(i)(3 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(3 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(9 downto 0),
              DIB      => ramb_d_wide(i)(15 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(15 downto 0),
              DOPB     => open
           );

        end generate GEN_S4_S18_RAM;
        -------------------------------------------------------------------------------
        GEN_S4_S36_RAM: if((a_width = 4) and (b_width = 36)) generate
           S3_BRAM_INST : RAMB16_S4_S36
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(11 downto 0),
              DIA      => ramb_d_narrow(i)(3 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(3 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(8 downto 0),
              DIB      => ramb_d_wide(i),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i),
              DOPB     => open
           );

        end generate GEN_S4_S36_RAM;
        -------------------------------------------------------------------------------
        GEN_S2_S2_RAM: if((a_width = 2) and (b_width = 2)) generate
           S3_BRAM_INST : RAMB16_S2_S2
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(12 downto 0),
              DIA      => ramb_d_narrow(i)(1 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(1 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(12 downto 0),
              DIB      => ramb_d_wide(i)(1 downto 0),
              WEB      => we_wide,
              --DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(1 downto 0)
              --DOPB     => open
           );

        end generate GEN_S2_S2_RAM;
        -------------------------------------------------------------------------------
        GEN_S2_S4_RAM: if((a_width = 2) and (b_width = 4)) generate
           S3_BRAM_INST : RAMB16_S2_S4
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA, 
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(12 downto 0),
              DIA      => ramb_d_narrow(i)(1 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(1 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(11 downto 0),
              DIB      => ramb_d_wide(i)(3 downto 0),
              WEB      => we_wide,
              --DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(3 downto 0)
              --DOPB     => open
           );

        end generate GEN_S2_S4_RAM;
        -------------------------------------------------------------------------------
        GEN_S2_S9_RAM: if((a_width = 2) and (b_width = 9)) generate
           S3_BRAM_INST : RAMB16_S2_S9
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(12 downto 0),
              DIA      => ramb_d_narrow(i)(1 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(1 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(10 downto 0),
              DIB      => ramb_d_wide(i)(7 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(7 downto 0),
              DOPB     => open
           );

        end generate GEN_S2_S9_RAM;
        -------------------------------------------------------------------------------
        GEN_S2_S18_RAM: if((a_width = 2) and (b_width = 18)) generate
           S3_BRAM_INST : RAMB16_S2_S18
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(12 downto 0),
              DIA      => ramb_d_narrow(i)(1 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(1 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard( 9 downto 0),
              DIB      => ramb_d_wide(i)(15 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(15 downto 0),
              DOPB     => open
           );

        end generate GEN_S2_S18_RAM;
        -------------------------------------------------------------------------------
        GEN_S2_S36_RAM: if((a_width = 2) and (b_width = 36)) generate
           S3_BRAM_INST : RAMB16_S2_S36
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(12 downto 0),
              DIA      => ramb_d_narrow(i)(1 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(1 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard( 8 downto 0),
              DIB      => ramb_d_wide(i),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i),
              DOPB     => open
           );

        end generate GEN_S2_S36_RAM;
        -------------------------------------------------------------------------------
        GEN_S1_S1_RAM: if((a_width = 1) and (b_width = 1)) generate
           S3_BRAM_INST : RAMB16_S1_S1
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(13 downto 0),
              DIA      => ramb_d_narrow(i)(0 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(0 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(13 downto 0),
              DIB      => ramb_d_wide(i)(0 downto 0),
              WEB      => we_wide,
              --DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(0 downto 0)
              --DOPB     => open
           );

        end generate GEN_S1_S1_RAM;
        -------------------------------------------------------------------------------
        GEN_S1_S2_RAM: if((a_width = 1) and (b_width = 2)) generate
           S3_BRAM_INST : RAMB16_S1_S2
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(13 downto 0),
              DIA      => ramb_d_narrow(i)(0 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(0 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(12 downto 0),
              DIB      => ramb_d_wide(i)(1 downto 0),
              WEB      => we_wide,
              --DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(1 downto 0)
              --DOPB     => open
           );

        end generate GEN_S1_S2_RAM;
        -------------------------------------------------------------------------------
        GEN_S1_S4_RAM: if((a_width = 1) and (b_width = 4)) generate
           S3_BRAM_INST : RAMB16_S1_S4
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(13 downto 0),
              DIA      => ramb_d_narrow(i)(0 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(0 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(11 downto 0),
              DIB      => ramb_d_wide(i)(3 downto 0),
              WEB      => we_wide,
              --DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(3 downto 0)
              --DOPB     => open
           );

        end generate GEN_S1_S4_RAM;
        -------------------------------------------------------------------------------
        GEN_S1_S9_RAM: if((a_width = 1) and (b_width = 9)) generate
           S3_BRAM_INST : RAMB16_S1_S9
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(13 downto 0),
              DIA      => ramb_d_narrow(i)(0 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(0 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard(10 downto 0),
              DIB      => ramb_d_wide(i)(7 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(7 downto 0),
              DOPB     => open
           );

        end generate GEN_S1_S9_RAM;
        -------------------------------------------------------------------------------
        GEN_S1_S18_RAM: if((a_width = 1) and (b_width = 18)) generate
           S3_BRAM_INST : RAMB16_S1_S18
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(13 downto 0),
              DIA      => ramb_d_narrow(i)(0 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(0 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard( 9 downto 0),
              DIB      => ramb_d_wide(i)(15 downto 0),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i)(15 downto 0),
              DOPB     => open
           );

        end generate GEN_S1_S18_RAM;
        -------------------------------------------------------------------------------
        GEN_S1_S36_RAM: if((a_width = 1) and (b_width = 36)) generate
           S3_BRAM_INST : RAMB16_S1_S36
           generic map
           (
              SIM_COLLISION_CHECK => "NONE",
              WRITE_MODE_A => WRITEMODEA,
              WRITE_MODE_B => WRITEMODEB
           )
           port map 
           (
              SSRA     => '0',
              ENA      => '1',
              ADDRA    => s3_addr_narrow_guard(13 downto 0),
              DIA      => ramb_d_narrow(i)(0 downto 0),
              WEA      => we_narrow,
              --DIPA     => (others => '0'),
              CLKA     => clk_narrow,
              DOA      => t_ramb_q_narrow(i)(0 downto 0),
              --DOPA     => open,
        
              SSRB     => '0',
              ENB      => '1',
              ADDRB    => s3_addr_wide_guard( 8 downto 0),
              DIB      => ramb_d_wide(i),
              WEB      => we_wide,
              DIPB     => (others => '0'),
              CLKB     => clk_wide,
              DOB      => t_ramb_q_wide(i),
              DOPB     => open
           );

        end generate GEN_S1_S36_RAM;
        -------------------------------------------------------------------------------

      end generate GEN_SPARTAN3_RAM; 
      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------

      -- Build QA output
      q_narrow((ram_narrow_width*(i+1))-1 downto ram_narrow_width*i) <= ramb_q_narrow(i)(ram_narrow_width-1 downto 0);
  
      -- Build QB output 
      q_wide_temp((ram_wide_width*(i+1))-1 downto ram_wide_width*i) <= ramb_q_wide(i)(ram_wide_width-1 downto 0);
  
      gen_q_wide:  for j in 0 to width_ratio-1 generate
        q_wide(       ((i+1)*ram_narrow_width + (j*dwidth_narrow))-1 
               downto i*ram_narrow_width + (j*dwidth_narrow)        ) <= q_wide_temp(       ((width_ratio*i +
                j+1)*ram_narrow_width)-1 
                                                                                   downto (width_ratio*i + j)*ram_narrow_width     
                                                                                    );
      end generate;
       
    end generate;

  end generate GEN_DIFFERENT_WIDTH;

  --------------------------------------------------------------------------- 
  --------------------------------------------------------------------------- 
  GEN_SAME_WIDTH: if(dwidthb = dwidtha) generate
    mem0: entity work.dp_ram_async
    generic map( 
      input_reg     => input_reg,
      dwidth        => dwidtha,
      mem_size      => mem_sizea,
      mem_type      => MEM_TYPE,
      write_mode_a  => WRITEMODEA,
      write_mode_b  => WRITEMODEB
    )
    port map (
      clka        => clka,
      clkb        => clkb,
      da          => da,
      db          => db,
      addra       => addra,
      addrb       => addrb,
      wea         => wea,
      web         => web,
      ena         => '1',
      enb         => '1',
      qa          => qa,
      qb          => qb
    );

  end generate GEN_SAME_WIDTH;

end ramb;

-- *********************************************
--  *010* add_your_new_macro  Macro
--
-- *********************************************
