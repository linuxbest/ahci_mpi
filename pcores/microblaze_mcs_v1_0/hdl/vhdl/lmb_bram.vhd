library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library microblaze_v8_20_b;
use microblaze_v8_20_b.MicroBlaze_Types.all;

library microblaze_mcs_v1_0;
use microblaze_mcs_v1_0.RAM_module_Top;

entity lmb_bram is
  generic (
    C_MEMSIZE             : integer := 16#8000#;
    C_MICROBLAZE_INSTANCE : string  := "microblaze_0";
    C_FAMILY              : string  := "virtex5");
  port (
    BRAM_Rst_A  : in  std_logic;
    BRAM_Clk_A  : in  std_logic;
    BRAM_EN_A   : in  std_logic;
    BRAM_WEN_A  : in  std_logic_vector(0 to 3);
    BRAM_Addr_A : in  std_logic_vector(0 to 31);
    BRAM_Din_A  : in  std_logic_vector(0 to 31);
    BRAM_Dout_A : out std_logic_vector(0 to 31);
    BRAM_Rst_B  : in  std_logic;
    BRAM_Clk_B  : in  std_logic;
    BRAM_EN_B   : in  std_logic;
    BRAM_WEN_B  : in  std_logic_vector(0 to 3);
    BRAM_Addr_B : in  std_logic_vector(0 to 31);
    BRAM_Din_B  : in  std_logic_vector(0 to 31);
    BRAM_Dout_B : out std_logic_vector(0 to 31));
end lmb_bram;

architecture IMP of lmb_bram is

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

  constant C_Target : TARGET_FAMILY_TYPE := String_To_Family(C_FAMILY,False);
  constant C_ADDR_WIDTH : natural := natural(log2(C_MEMSIZE)) - 2;  -- Word address width
                                             
begin

  RAM_Inst: RAM_Module_Top
  generic map (
    C_TARGET              => C_TARGET,
    C_DATA_WIDTH          => 32,
    C_WE_WIDTH            => 4,
    C_ADDR_WIDTH          => C_ADDR_WIDTH,
    C_USE_INIT_FILE       => true,
    C_MICROBLAZE_INSTANCE => C_MICROBLAZE_INSTANCE,
    C_FORCE_BRAM          => true,
    C_FORCE_LUTRAM        => false)
  port map(
    -- PORT A
    CLKA      => BRAM_Clk_A,
    WEA       => BRAM_WEN_A,
    ENA       => BRAM_EN_A,
    ADDRA     => BRAM_Addr_A(29 - C_ADDR_WIDTH + 1 to 29),
    DATA_INA  => BRAM_Din_A,
    DATA_OUTA => BRAM_Dout_A,
    -- PORT B
    CLKB      => BRAM_Clk_B,
    WEB       => BRAM_WEN_B, 
    ENB       => BRAM_EN_B, 
    ADDRB     => BRAM_Addr_B(29 - C_ADDR_WIDTH + 1 to 29),
    DATA_INB  => BRAM_Din_B,
    DATA_OUTB => BRAM_Dout_B);
  
end architecture IMP;
