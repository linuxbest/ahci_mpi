library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library sata_v1_00_a;
use sata_v1_00_a.lmb_bram_16k_loop.ALL;

entity lmb_bram is
  generic (
    C_MEMSIZE             : integer := 16#4000#;
    C_MICROBLAZE_INSTANCE : string  := "microblaze_0";
    C_FAMILY              : string  := "virtex5");
  port (
    BRAM_Rst_A : in std_logic;
    BRAM_Clk_A : in std_logic;
    BRAM_EN_A : in std_logic;
    BRAM_WEN_A : in std_logic_vector(0 to 3);
    BRAM_Addr_A : in std_logic_vector(0 to 31);
    BRAM_Dout_A : out std_logic_vector(0 to 31);
    BRAM_Din_A : in std_logic_vector(0 to 31);
    BRAM_Rst_B : in std_logic;
    BRAM_Clk_B : in std_logic;
    BRAM_EN_B : in std_logic;
    BRAM_WEN_B : in std_logic_vector(0 to 3);
    BRAM_Addr_B : in std_logic_vector(0 to 31);
    BRAM_Dout_B : out std_logic_vector(0 to 31);
    BRAM_Din_B : in std_logic_vector(0 to 31)
  );

end lmb_bram;

architecture STRUCTURE of lmb_bram is

  component RAMB36 is
    generic (
      WRITE_MODE_A : string;
      WRITE_MODE_B : string;
--      INIT_FILE : string;
      READ_WIDTH_A : integer;
      READ_WIDTH_B : integer;
      WRITE_WIDTH_A : integer;
      WRITE_WIDTH_B : integer;
      RAM_EXTENSION_A : string;
      RAM_EXTENSION_B : string;

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
    INIT_40 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_41 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_42 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_43 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_44 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_45 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_46 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_47 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_48 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_49 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_50 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_51 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_52 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_53 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_54 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_55 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_56 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_57 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_58 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_59 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_60 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_61 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_62 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_63 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_64 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_65 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_66 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_67 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_68 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_69 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_70 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_71 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_72 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_73 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_74 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_75 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_76 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_77 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_78 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_79 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000"
    );
    port (
      ADDRA : in std_logic_vector(15 downto 0);
      CASCADEINLATA : in std_logic;
      CASCADEINREGA : in std_logic;
      CASCADEOUTLATA : out std_logic;
      CASCADEOUTREGA : out std_logic;
      CLKA : in std_logic;
      DIA : in std_logic_vector(31 downto 0);
      DIPA : in std_logic_vector(3 downto 0);
      DOA : out std_logic_vector(31 downto 0);
      DOPA : out std_logic_vector(3 downto 0);
      ENA : in std_logic;
      REGCEA : in std_logic;
      SSRA : in std_logic;
      WEA : in std_logic_vector(3 downto 0);
      ADDRB : in std_logic_vector(15 downto 0);
      CASCADEINLATB : in std_logic;
      CASCADEINREGB : in std_logic;
      CASCADEOUTLATB : out std_logic;
      CASCADEOUTREGB : out std_logic;
      CLKB : in std_logic;
      DIB : in std_logic_vector(31 downto 0);
      DIPB : in std_logic_vector(3 downto 0);
      DOB : out std_logic_vector(31 downto 0);
      DOPB : out std_logic_vector(3 downto 0);
      ENB : in std_logic;
      REGCEB : in std_logic;
      SSRB : in std_logic;
      WEB : in std_logic_vector(3 downto 0)
    );
  end component;

  -- Internal signals

  signal net_gnd0 : std_logic;
  signal net_gnd4 : std_logic_vector(3 downto 0);
  signal pgassign1 : std_logic_vector(0 to 0);
  signal pgassign2 : std_logic_vector(0 to 2);
  signal pgassign3 : std_logic_vector(0 to 23);
  signal pgassign4 : std_logic_vector(15 downto 0);
  signal pgassign5 : std_logic_vector(31 downto 0);
  signal pgassign6 : std_logic_vector(31 downto 0);
  signal pgassign7 : std_logic_vector(3 downto 0);
  signal pgassign8 : std_logic_vector(15 downto 0);
  signal pgassign9 : std_logic_vector(31 downto 0);
  signal pgassign10 : std_logic_vector(31 downto 0);
  signal pgassign11 : std_logic_vector(3 downto 0);
  signal pgassign12 : std_logic_vector(15 downto 0);
  signal pgassign13 : std_logic_vector(31 downto 0);
  signal pgassign14 : std_logic_vector(31 downto 0);
  signal pgassign15 : std_logic_vector(3 downto 0);
  signal pgassign16 : std_logic_vector(15 downto 0);
  signal pgassign17 : std_logic_vector(31 downto 0);
  signal pgassign18 : std_logic_vector(31 downto 0);
  signal pgassign19 : std_logic_vector(3 downto 0);
  signal pgassign20 : std_logic_vector(15 downto 0);
  signal pgassign21 : std_logic_vector(31 downto 0);
  signal pgassign22 : std_logic_vector(31 downto 0);
  signal pgassign23 : std_logic_vector(3 downto 0);
  signal pgassign24 : std_logic_vector(15 downto 0);
  signal pgassign25 : std_logic_vector(31 downto 0);
  signal pgassign26 : std_logic_vector(31 downto 0);
  signal pgassign27 : std_logic_vector(3 downto 0);
  signal pgassign28 : std_logic_vector(15 downto 0);
  signal pgassign29 : std_logic_vector(31 downto 0);
  signal pgassign30 : std_logic_vector(31 downto 0);
  signal pgassign31 : std_logic_vector(3 downto 0);
  signal pgassign32 : std_logic_vector(15 downto 0);
  signal pgassign33 : std_logic_vector(31 downto 0);
  signal pgassign34 : std_logic_vector(31 downto 0);
  signal pgassign35 : std_logic_vector(3 downto 0);

begin

  -- Internal assignments
  pgassign1(0 to 0) <= B"1";
  pgassign2(0 to 2) <= B"000";
  pgassign3(0 to 23) <= B"000000000000000000000000";
  pgassign4(15 downto 15) <= B"1";
  pgassign4(14 downto 3) <= BRAM_Addr_A(18 to 29);
  pgassign4(2 downto 0) <= B"000";
  pgassign5(31 downto 8) <= B"000000000000000000000000";
  pgassign5(7 downto 0) <= BRAM_Din_A(0 to 7);
  BRAM_Dout_A(0 to 7) <= pgassign6(7 downto 0);
  pgassign7(3 downto 3) <= BRAM_WEN_A(0 to 0);
  pgassign7(2 downto 2) <= BRAM_WEN_A(0 to 0);
  pgassign7(1 downto 1) <= BRAM_WEN_A(0 to 0);
  pgassign7(0 downto 0) <= BRAM_WEN_A(0 to 0);
  pgassign8(15 downto 15) <= B"1";
  pgassign8(14 downto 3) <= BRAM_Addr_B(18 to 29);
  pgassign8(2 downto 0) <= B"000";
  pgassign9(31 downto 8) <= B"000000000000000000000000";
  pgassign9(7 downto 0) <= BRAM_Din_B(0 to 7);
  BRAM_Dout_B(0 to 7) <= pgassign10(7 downto 0);
  pgassign11(3 downto 3) <= BRAM_WEN_B(0 to 0);
  pgassign11(2 downto 2) <= BRAM_WEN_B(0 to 0);
  pgassign11(1 downto 1) <= BRAM_WEN_B(0 to 0);
  pgassign11(0 downto 0) <= BRAM_WEN_B(0 to 0);
  pgassign12(15 downto 15) <= B"1";
  pgassign12(14 downto 3) <= BRAM_Addr_A(18 to 29);
  pgassign12(2 downto 0) <= B"000";
  pgassign13(31 downto 8) <= B"000000000000000000000000";
  pgassign13(7 downto 0) <= BRAM_Din_A(8 to 15);
  BRAM_Dout_A(8 to 15) <= pgassign14(7 downto 0);
  pgassign15(3 downto 3) <= BRAM_WEN_A(1 to 1);
  pgassign15(2 downto 2) <= BRAM_WEN_A(1 to 1);
  pgassign15(1 downto 1) <= BRAM_WEN_A(1 to 1);
  pgassign15(0 downto 0) <= BRAM_WEN_A(1 to 1);
  pgassign16(15 downto 15) <= B"1";
  pgassign16(14 downto 3) <= BRAM_Addr_B(18 to 29);
  pgassign16(2 downto 0) <= B"000";
  pgassign17(31 downto 8) <= B"000000000000000000000000";
  pgassign17(7 downto 0) <= BRAM_Din_B(8 to 15);
  BRAM_Dout_B(8 to 15) <= pgassign18(7 downto 0);
  pgassign19(3 downto 3) <= BRAM_WEN_B(1 to 1);
  pgassign19(2 downto 2) <= BRAM_WEN_B(1 to 1);
  pgassign19(1 downto 1) <= BRAM_WEN_B(1 to 1);
  pgassign19(0 downto 0) <= BRAM_WEN_B(1 to 1);
  pgassign20(15 downto 15) <= B"1";
  pgassign20(14 downto 3) <= BRAM_Addr_A(18 to 29);
  pgassign20(2 downto 0) <= B"000";
  pgassign21(31 downto 8) <= B"000000000000000000000000";
  pgassign21(7 downto 0) <= BRAM_Din_A(16 to 23);
  BRAM_Dout_A(16 to 23) <= pgassign22(7 downto 0);
  pgassign23(3 downto 3) <= BRAM_WEN_A(2 to 2);
  pgassign23(2 downto 2) <= BRAM_WEN_A(2 to 2);
  pgassign23(1 downto 1) <= BRAM_WEN_A(2 to 2);
  pgassign23(0 downto 0) <= BRAM_WEN_A(2 to 2);
  pgassign24(15 downto 15) <= B"1";
  pgassign24(14 downto 3) <= BRAM_Addr_B(18 to 29);
  pgassign24(2 downto 0) <= B"000";
  pgassign25(31 downto 8) <= B"000000000000000000000000";
  pgassign25(7 downto 0) <= BRAM_Din_B(16 to 23);
  BRAM_Dout_B(16 to 23) <= pgassign26(7 downto 0);
  pgassign27(3 downto 3) <= BRAM_WEN_B(2 to 2);
  pgassign27(2 downto 2) <= BRAM_WEN_B(2 to 2);
  pgassign27(1 downto 1) <= BRAM_WEN_B(2 to 2);
  pgassign27(0 downto 0) <= BRAM_WEN_B(2 to 2);
  pgassign28(15 downto 15) <= B"1";
  pgassign28(14 downto 3) <= BRAM_Addr_A(18 to 29);
  pgassign28(2 downto 0) <= B"000";
  pgassign29(31 downto 8) <= B"000000000000000000000000";
  pgassign29(7 downto 0) <= BRAM_Din_A(24 to 31);
  BRAM_Dout_A(24 to 31) <= pgassign30(7 downto 0);
  pgassign31(3 downto 3) <= BRAM_WEN_A(3 to 3);
  pgassign31(2 downto 2) <= BRAM_WEN_A(3 to 3);
  pgassign31(1 downto 1) <= BRAM_WEN_A(3 to 3);
  pgassign31(0 downto 0) <= BRAM_WEN_A(3 to 3);
  pgassign32(15 downto 15) <= B"1";
  pgassign32(14 downto 3) <= BRAM_Addr_B(18 to 29);
  pgassign32(2 downto 0) <= B"000";
  pgassign33(31 downto 8) <= B"000000000000000000000000";
  pgassign33(7 downto 0) <= BRAM_Din_B(24 to 31);
  BRAM_Dout_B(24 to 31) <= pgassign34(7 downto 0);
  pgassign35(3 downto 3) <= BRAM_WEN_B(3 to 3);
  pgassign35(2 downto 2) <= BRAM_WEN_B(3 to 3);
  pgassign35(1 downto 1) <= BRAM_WEN_B(3 to 3);
  pgassign35(0 downto 0) <= BRAM_WEN_B(3 to 3);
  net_gnd0 <= '0';
  net_gnd4(3 downto 0) <= B"0000";

  ramb36_0 : RAMB36
    generic map (
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
--      INIT_FILE => "lmb_bram_instr_combined_0.mem",
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
      WRITE_WIDTH_A => 9,
      WRITE_WIDTH_B => 9,
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",

INIT_00 => lmb_bram_lmb_bram_ramb36_0_INIT_00,
INIT_01 => lmb_bram_lmb_bram_ramb36_0_INIT_01,
INIT_02 => lmb_bram_lmb_bram_ramb36_0_INIT_02,
INIT_03 => lmb_bram_lmb_bram_ramb36_0_INIT_03,
INIT_04 => lmb_bram_lmb_bram_ramb36_0_INIT_04,
INIT_05 => lmb_bram_lmb_bram_ramb36_0_INIT_05,
INIT_06 => lmb_bram_lmb_bram_ramb36_0_INIT_06,
INIT_07 => lmb_bram_lmb_bram_ramb36_0_INIT_07,
INIT_08 => lmb_bram_lmb_bram_ramb36_0_INIT_08,
INIT_09 => lmb_bram_lmb_bram_ramb36_0_INIT_09,
INIT_0A => lmb_bram_lmb_bram_ramb36_0_INIT_0A,
INIT_0B => lmb_bram_lmb_bram_ramb36_0_INIT_0B,
INIT_0C => lmb_bram_lmb_bram_ramb36_0_INIT_0C,
INIT_0D => lmb_bram_lmb_bram_ramb36_0_INIT_0D,
INIT_0E => lmb_bram_lmb_bram_ramb36_0_INIT_0E,
INIT_0F => lmb_bram_lmb_bram_ramb36_0_INIT_0F,
INIT_10 => lmb_bram_lmb_bram_ramb36_0_INIT_10,
INIT_11 => lmb_bram_lmb_bram_ramb36_0_INIT_11,
INIT_12 => lmb_bram_lmb_bram_ramb36_0_INIT_12,
INIT_13 => lmb_bram_lmb_bram_ramb36_0_INIT_13,
INIT_14 => lmb_bram_lmb_bram_ramb36_0_INIT_14,
INIT_15 => lmb_bram_lmb_bram_ramb36_0_INIT_15,
INIT_16 => lmb_bram_lmb_bram_ramb36_0_INIT_16,
INIT_17 => lmb_bram_lmb_bram_ramb36_0_INIT_17,
INIT_18 => lmb_bram_lmb_bram_ramb36_0_INIT_18,
INIT_19 => lmb_bram_lmb_bram_ramb36_0_INIT_19,
INIT_1A => lmb_bram_lmb_bram_ramb36_0_INIT_1A,
INIT_1B => lmb_bram_lmb_bram_ramb36_0_INIT_1B,
INIT_1C => lmb_bram_lmb_bram_ramb36_0_INIT_1C,
INIT_1D => lmb_bram_lmb_bram_ramb36_0_INIT_1D,
INIT_1E => lmb_bram_lmb_bram_ramb36_0_INIT_1E,
INIT_1F => lmb_bram_lmb_bram_ramb36_0_INIT_1F,
INIT_20 => lmb_bram_lmb_bram_ramb36_0_INIT_20,
INIT_21 => lmb_bram_lmb_bram_ramb36_0_INIT_21,
INIT_22 => lmb_bram_lmb_bram_ramb36_0_INIT_22,
INIT_23 => lmb_bram_lmb_bram_ramb36_0_INIT_23,
INIT_24 => lmb_bram_lmb_bram_ramb36_0_INIT_24,
INIT_25 => lmb_bram_lmb_bram_ramb36_0_INIT_25,
INIT_26 => lmb_bram_lmb_bram_ramb36_0_INIT_26,
INIT_27 => lmb_bram_lmb_bram_ramb36_0_INIT_27,
INIT_28 => lmb_bram_lmb_bram_ramb36_0_INIT_28,
INIT_29 => lmb_bram_lmb_bram_ramb36_0_INIT_29,
INIT_2A => lmb_bram_lmb_bram_ramb36_0_INIT_2A,
INIT_2B => lmb_bram_lmb_bram_ramb36_0_INIT_2B,
INIT_2C => lmb_bram_lmb_bram_ramb36_0_INIT_2C,
INIT_2D => lmb_bram_lmb_bram_ramb36_0_INIT_2D,
INIT_2E => lmb_bram_lmb_bram_ramb36_0_INIT_2E,
INIT_2F => lmb_bram_lmb_bram_ramb36_0_INIT_2F,
INIT_30 => lmb_bram_lmb_bram_ramb36_0_INIT_30,
INIT_31 => lmb_bram_lmb_bram_ramb36_0_INIT_31,
INIT_32 => lmb_bram_lmb_bram_ramb36_0_INIT_32,
INIT_33 => lmb_bram_lmb_bram_ramb36_0_INIT_33,
INIT_34 => lmb_bram_lmb_bram_ramb36_0_INIT_34,
INIT_35 => lmb_bram_lmb_bram_ramb36_0_INIT_35,
INIT_36 => lmb_bram_lmb_bram_ramb36_0_INIT_36,
INIT_37 => lmb_bram_lmb_bram_ramb36_0_INIT_37,
INIT_38 => lmb_bram_lmb_bram_ramb36_0_INIT_38,
INIT_39 => lmb_bram_lmb_bram_ramb36_0_INIT_39,
INIT_3A => lmb_bram_lmb_bram_ramb36_0_INIT_3A,
INIT_3B => lmb_bram_lmb_bram_ramb36_0_INIT_3B,
INIT_3C => lmb_bram_lmb_bram_ramb36_0_INIT_3C,
INIT_3D => lmb_bram_lmb_bram_ramb36_0_INIT_3D,
INIT_3E => lmb_bram_lmb_bram_ramb36_0_INIT_3E,
INIT_3F => lmb_bram_lmb_bram_ramb36_0_INIT_3F,
INIT_40 => lmb_bram_lmb_bram_ramb36_0_INIT_40,
INIT_41 => lmb_bram_lmb_bram_ramb36_0_INIT_41,
INIT_42 => lmb_bram_lmb_bram_ramb36_0_INIT_42,
INIT_43 => lmb_bram_lmb_bram_ramb36_0_INIT_43,
INIT_44 => lmb_bram_lmb_bram_ramb36_0_INIT_44,
INIT_45 => lmb_bram_lmb_bram_ramb36_0_INIT_45,
INIT_46 => lmb_bram_lmb_bram_ramb36_0_INIT_46,
INIT_47 => lmb_bram_lmb_bram_ramb36_0_INIT_47,
INIT_48 => lmb_bram_lmb_bram_ramb36_0_INIT_48,
INIT_49 => lmb_bram_lmb_bram_ramb36_0_INIT_49,
INIT_4A => lmb_bram_lmb_bram_ramb36_0_INIT_4A,
INIT_4B => lmb_bram_lmb_bram_ramb36_0_INIT_4B,
INIT_4C => lmb_bram_lmb_bram_ramb36_0_INIT_4C,
INIT_4D => lmb_bram_lmb_bram_ramb36_0_INIT_4D,
INIT_4E => lmb_bram_lmb_bram_ramb36_0_INIT_4E,
INIT_4F => lmb_bram_lmb_bram_ramb36_0_INIT_4F,
INIT_50 => lmb_bram_lmb_bram_ramb36_0_INIT_50,
INIT_51 => lmb_bram_lmb_bram_ramb36_0_INIT_51,
INIT_52 => lmb_bram_lmb_bram_ramb36_0_INIT_52,
INIT_53 => lmb_bram_lmb_bram_ramb36_0_INIT_53,
INIT_54 => lmb_bram_lmb_bram_ramb36_0_INIT_54,
INIT_55 => lmb_bram_lmb_bram_ramb36_0_INIT_55,
INIT_56 => lmb_bram_lmb_bram_ramb36_0_INIT_56,
INIT_57 => lmb_bram_lmb_bram_ramb36_0_INIT_57,
INIT_58 => lmb_bram_lmb_bram_ramb36_0_INIT_58,
INIT_59 => lmb_bram_lmb_bram_ramb36_0_INIT_59,
INIT_5A => lmb_bram_lmb_bram_ramb36_0_INIT_5A,
INIT_5B => lmb_bram_lmb_bram_ramb36_0_INIT_5B,
INIT_5C => lmb_bram_lmb_bram_ramb36_0_INIT_5C,
INIT_5D => lmb_bram_lmb_bram_ramb36_0_INIT_5D,
INIT_5E => lmb_bram_lmb_bram_ramb36_0_INIT_5E,
INIT_5F => lmb_bram_lmb_bram_ramb36_0_INIT_5F,
INIT_60 => lmb_bram_lmb_bram_ramb36_0_INIT_60,
INIT_61 => lmb_bram_lmb_bram_ramb36_0_INIT_61,
INIT_62 => lmb_bram_lmb_bram_ramb36_0_INIT_62,
INIT_63 => lmb_bram_lmb_bram_ramb36_0_INIT_63,
INIT_64 => lmb_bram_lmb_bram_ramb36_0_INIT_64,
INIT_65 => lmb_bram_lmb_bram_ramb36_0_INIT_65,
INIT_66 => lmb_bram_lmb_bram_ramb36_0_INIT_66,
INIT_67 => lmb_bram_lmb_bram_ramb36_0_INIT_67,
INIT_68 => lmb_bram_lmb_bram_ramb36_0_INIT_68,
INIT_69 => lmb_bram_lmb_bram_ramb36_0_INIT_69,
INIT_6A => lmb_bram_lmb_bram_ramb36_0_INIT_6A,
INIT_6B => lmb_bram_lmb_bram_ramb36_0_INIT_6B,
INIT_6C => lmb_bram_lmb_bram_ramb36_0_INIT_6C,
INIT_6D => lmb_bram_lmb_bram_ramb36_0_INIT_6D,
INIT_6E => lmb_bram_lmb_bram_ramb36_0_INIT_6E,
INIT_6F => lmb_bram_lmb_bram_ramb36_0_INIT_6F,
INIT_70 => lmb_bram_lmb_bram_ramb36_0_INIT_70,
INIT_71 => lmb_bram_lmb_bram_ramb36_0_INIT_71,
INIT_72 => lmb_bram_lmb_bram_ramb36_0_INIT_72,
INIT_73 => lmb_bram_lmb_bram_ramb36_0_INIT_73,
INIT_74 => lmb_bram_lmb_bram_ramb36_0_INIT_74,
INIT_75 => lmb_bram_lmb_bram_ramb36_0_INIT_75,
INIT_76 => lmb_bram_lmb_bram_ramb36_0_INIT_76,
INIT_77 => lmb_bram_lmb_bram_ramb36_0_INIT_77,
INIT_78 => lmb_bram_lmb_bram_ramb36_0_INIT_78,
INIT_79 => lmb_bram_lmb_bram_ramb36_0_INIT_79,
INIT_7A => lmb_bram_lmb_bram_ramb36_0_INIT_7A,
INIT_7B => lmb_bram_lmb_bram_ramb36_0_INIT_7B,
INIT_7C => lmb_bram_lmb_bram_ramb36_0_INIT_7C,
INIT_7D => lmb_bram_lmb_bram_ramb36_0_INIT_7D,
INIT_7E => lmb_bram_lmb_bram_ramb36_0_INIT_7E,
INIT_7F => lmb_bram_lmb_bram_ramb36_0_INIT_7F
    )
    port map (
      ADDRA => pgassign4,
      CASCADEINLATA => net_gnd0,
      CASCADEINREGA => net_gnd0,
      CASCADEOUTLATA => open,
      CASCADEOUTREGA => open,
      CLKA => BRAM_Clk_A,
      DIA => pgassign5,
      DIPA => net_gnd4,
      DOA => pgassign6,
      DOPA => open,
      ENA => BRAM_EN_A,
      REGCEA => net_gnd0,
      SSRA => BRAM_Rst_A,
      WEA => pgassign7,
      ADDRB => pgassign8,
      CASCADEINLATB => net_gnd0,
      CASCADEINREGB => net_gnd0,
      CASCADEOUTLATB => open,
      CASCADEOUTREGB => open,
      CLKB => BRAM_Clk_B,
      DIB => pgassign9,
      DIPB => net_gnd4,
      DOB => pgassign10,
      DOPB => open,
      ENB => BRAM_EN_B,
      REGCEB => net_gnd0,
      SSRB => BRAM_Rst_B,
      WEB => pgassign11
    );

  ramb36_1 : RAMB36
    generic map (
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
--      INIT_FILE => "lmb_bram_instr_combined_1.mem",
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
      WRITE_WIDTH_A => 9,
      WRITE_WIDTH_B => 9,
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",

INIT_00 => lmb_bram_lmb_bram_ramb36_1_INIT_00,
INIT_01 => lmb_bram_lmb_bram_ramb36_1_INIT_01,
INIT_02 => lmb_bram_lmb_bram_ramb36_1_INIT_02,
INIT_03 => lmb_bram_lmb_bram_ramb36_1_INIT_03,
INIT_04 => lmb_bram_lmb_bram_ramb36_1_INIT_04,
INIT_05 => lmb_bram_lmb_bram_ramb36_1_INIT_05,
INIT_06 => lmb_bram_lmb_bram_ramb36_1_INIT_06,
INIT_07 => lmb_bram_lmb_bram_ramb36_1_INIT_07,
INIT_08 => lmb_bram_lmb_bram_ramb36_1_INIT_08,
INIT_09 => lmb_bram_lmb_bram_ramb36_1_INIT_09,
INIT_0A => lmb_bram_lmb_bram_ramb36_1_INIT_0A,
INIT_0B => lmb_bram_lmb_bram_ramb36_1_INIT_0B,
INIT_0C => lmb_bram_lmb_bram_ramb36_1_INIT_0C,
INIT_0D => lmb_bram_lmb_bram_ramb36_1_INIT_0D,
INIT_0E => lmb_bram_lmb_bram_ramb36_1_INIT_0E,
INIT_0F => lmb_bram_lmb_bram_ramb36_1_INIT_0F,
INIT_10 => lmb_bram_lmb_bram_ramb36_1_INIT_10,
INIT_11 => lmb_bram_lmb_bram_ramb36_1_INIT_11,
INIT_12 => lmb_bram_lmb_bram_ramb36_1_INIT_12,
INIT_13 => lmb_bram_lmb_bram_ramb36_1_INIT_13,
INIT_14 => lmb_bram_lmb_bram_ramb36_1_INIT_14,
INIT_15 => lmb_bram_lmb_bram_ramb36_1_INIT_15,
INIT_16 => lmb_bram_lmb_bram_ramb36_1_INIT_16,
INIT_17 => lmb_bram_lmb_bram_ramb36_1_INIT_17,
INIT_18 => lmb_bram_lmb_bram_ramb36_1_INIT_18,
INIT_19 => lmb_bram_lmb_bram_ramb36_1_INIT_19,
INIT_1A => lmb_bram_lmb_bram_ramb36_1_INIT_1A,
INIT_1B => lmb_bram_lmb_bram_ramb36_1_INIT_1B,
INIT_1C => lmb_bram_lmb_bram_ramb36_1_INIT_1C,
INIT_1D => lmb_bram_lmb_bram_ramb36_1_INIT_1D,
INIT_1E => lmb_bram_lmb_bram_ramb36_1_INIT_1E,
INIT_1F => lmb_bram_lmb_bram_ramb36_1_INIT_1F,
INIT_20 => lmb_bram_lmb_bram_ramb36_1_INIT_20,
INIT_21 => lmb_bram_lmb_bram_ramb36_1_INIT_21,
INIT_22 => lmb_bram_lmb_bram_ramb36_1_INIT_22,
INIT_23 => lmb_bram_lmb_bram_ramb36_1_INIT_23,
INIT_24 => lmb_bram_lmb_bram_ramb36_1_INIT_24,
INIT_25 => lmb_bram_lmb_bram_ramb36_1_INIT_25,
INIT_26 => lmb_bram_lmb_bram_ramb36_1_INIT_26,
INIT_27 => lmb_bram_lmb_bram_ramb36_1_INIT_27,
INIT_28 => lmb_bram_lmb_bram_ramb36_1_INIT_28,
INIT_29 => lmb_bram_lmb_bram_ramb36_1_INIT_29,
INIT_2A => lmb_bram_lmb_bram_ramb36_1_INIT_2A,
INIT_2B => lmb_bram_lmb_bram_ramb36_1_INIT_2B,
INIT_2C => lmb_bram_lmb_bram_ramb36_1_INIT_2C,
INIT_2D => lmb_bram_lmb_bram_ramb36_1_INIT_2D,
INIT_2E => lmb_bram_lmb_bram_ramb36_1_INIT_2E,
INIT_2F => lmb_bram_lmb_bram_ramb36_1_INIT_2F,
INIT_30 => lmb_bram_lmb_bram_ramb36_1_INIT_30,
INIT_31 => lmb_bram_lmb_bram_ramb36_1_INIT_31,
INIT_32 => lmb_bram_lmb_bram_ramb36_1_INIT_32,
INIT_33 => lmb_bram_lmb_bram_ramb36_1_INIT_33,
INIT_34 => lmb_bram_lmb_bram_ramb36_1_INIT_34,
INIT_35 => lmb_bram_lmb_bram_ramb36_1_INIT_35,
INIT_36 => lmb_bram_lmb_bram_ramb36_1_INIT_36,
INIT_37 => lmb_bram_lmb_bram_ramb36_1_INIT_37,
INIT_38 => lmb_bram_lmb_bram_ramb36_1_INIT_38,
INIT_39 => lmb_bram_lmb_bram_ramb36_1_INIT_39,
INIT_3A => lmb_bram_lmb_bram_ramb36_1_INIT_3A,
INIT_3B => lmb_bram_lmb_bram_ramb36_1_INIT_3B,
INIT_3C => lmb_bram_lmb_bram_ramb36_1_INIT_3C,
INIT_3D => lmb_bram_lmb_bram_ramb36_1_INIT_3D,
INIT_3E => lmb_bram_lmb_bram_ramb36_1_INIT_3E,
INIT_3F => lmb_bram_lmb_bram_ramb36_1_INIT_3F,
INIT_40 => lmb_bram_lmb_bram_ramb36_1_INIT_40,
INIT_41 => lmb_bram_lmb_bram_ramb36_1_INIT_41,
INIT_42 => lmb_bram_lmb_bram_ramb36_1_INIT_42,
INIT_43 => lmb_bram_lmb_bram_ramb36_1_INIT_43,
INIT_44 => lmb_bram_lmb_bram_ramb36_1_INIT_44,
INIT_45 => lmb_bram_lmb_bram_ramb36_1_INIT_45,
INIT_46 => lmb_bram_lmb_bram_ramb36_1_INIT_46,
INIT_47 => lmb_bram_lmb_bram_ramb36_1_INIT_47,
INIT_48 => lmb_bram_lmb_bram_ramb36_1_INIT_48,
INIT_49 => lmb_bram_lmb_bram_ramb36_1_INIT_49,
INIT_4A => lmb_bram_lmb_bram_ramb36_1_INIT_4A,
INIT_4B => lmb_bram_lmb_bram_ramb36_1_INIT_4B,
INIT_4C => lmb_bram_lmb_bram_ramb36_1_INIT_4C,
INIT_4D => lmb_bram_lmb_bram_ramb36_1_INIT_4D,
INIT_4E => lmb_bram_lmb_bram_ramb36_1_INIT_4E,
INIT_4F => lmb_bram_lmb_bram_ramb36_1_INIT_4F,
INIT_50 => lmb_bram_lmb_bram_ramb36_1_INIT_50,
INIT_51 => lmb_bram_lmb_bram_ramb36_1_INIT_51,
INIT_52 => lmb_bram_lmb_bram_ramb36_1_INIT_52,
INIT_53 => lmb_bram_lmb_bram_ramb36_1_INIT_53,
INIT_54 => lmb_bram_lmb_bram_ramb36_1_INIT_54,
INIT_55 => lmb_bram_lmb_bram_ramb36_1_INIT_55,
INIT_56 => lmb_bram_lmb_bram_ramb36_1_INIT_56,
INIT_57 => lmb_bram_lmb_bram_ramb36_1_INIT_57,
INIT_58 => lmb_bram_lmb_bram_ramb36_1_INIT_58,
INIT_59 => lmb_bram_lmb_bram_ramb36_1_INIT_59,
INIT_5A => lmb_bram_lmb_bram_ramb36_1_INIT_5A,
INIT_5B => lmb_bram_lmb_bram_ramb36_1_INIT_5B,
INIT_5C => lmb_bram_lmb_bram_ramb36_1_INIT_5C,
INIT_5D => lmb_bram_lmb_bram_ramb36_1_INIT_5D,
INIT_5E => lmb_bram_lmb_bram_ramb36_1_INIT_5E,
INIT_5F => lmb_bram_lmb_bram_ramb36_1_INIT_5F,
INIT_60 => lmb_bram_lmb_bram_ramb36_1_INIT_60,
INIT_61 => lmb_bram_lmb_bram_ramb36_1_INIT_61,
INIT_62 => lmb_bram_lmb_bram_ramb36_1_INIT_62,
INIT_63 => lmb_bram_lmb_bram_ramb36_1_INIT_63,
INIT_64 => lmb_bram_lmb_bram_ramb36_1_INIT_64,
INIT_65 => lmb_bram_lmb_bram_ramb36_1_INIT_65,
INIT_66 => lmb_bram_lmb_bram_ramb36_1_INIT_66,
INIT_67 => lmb_bram_lmb_bram_ramb36_1_INIT_67,
INIT_68 => lmb_bram_lmb_bram_ramb36_1_INIT_68,
INIT_69 => lmb_bram_lmb_bram_ramb36_1_INIT_69,
INIT_6A => lmb_bram_lmb_bram_ramb36_1_INIT_6A,
INIT_6B => lmb_bram_lmb_bram_ramb36_1_INIT_6B,
INIT_6C => lmb_bram_lmb_bram_ramb36_1_INIT_6C,
INIT_6D => lmb_bram_lmb_bram_ramb36_1_INIT_6D,
INIT_6E => lmb_bram_lmb_bram_ramb36_1_INIT_6E,
INIT_6F => lmb_bram_lmb_bram_ramb36_1_INIT_6F,
INIT_70 => lmb_bram_lmb_bram_ramb36_1_INIT_70,
INIT_71 => lmb_bram_lmb_bram_ramb36_1_INIT_71,
INIT_72 => lmb_bram_lmb_bram_ramb36_1_INIT_72,
INIT_73 => lmb_bram_lmb_bram_ramb36_1_INIT_73,
INIT_74 => lmb_bram_lmb_bram_ramb36_1_INIT_74,
INIT_75 => lmb_bram_lmb_bram_ramb36_1_INIT_75,
INIT_76 => lmb_bram_lmb_bram_ramb36_1_INIT_76,
INIT_77 => lmb_bram_lmb_bram_ramb36_1_INIT_77,
INIT_78 => lmb_bram_lmb_bram_ramb36_1_INIT_78,
INIT_79 => lmb_bram_lmb_bram_ramb36_1_INIT_79,
INIT_7A => lmb_bram_lmb_bram_ramb36_1_INIT_7A,
INIT_7B => lmb_bram_lmb_bram_ramb36_1_INIT_7B,
INIT_7C => lmb_bram_lmb_bram_ramb36_1_INIT_7C,
INIT_7D => lmb_bram_lmb_bram_ramb36_1_INIT_7D,
INIT_7E => lmb_bram_lmb_bram_ramb36_1_INIT_7E,
INIT_7F => lmb_bram_lmb_bram_ramb36_1_INIT_7F

    )
    port map (
      ADDRA => pgassign12,
      CASCADEINLATA => net_gnd0,
      CASCADEINREGA => net_gnd0,
      CASCADEOUTLATA => open,
      CASCADEOUTREGA => open,
      CLKA => BRAM_Clk_A,
      DIA => pgassign13,
      DIPA => net_gnd4,
      DOA => pgassign14,
      DOPA => open,
      ENA => BRAM_EN_A,
      REGCEA => net_gnd0,
      SSRA => BRAM_Rst_A,
      WEA => pgassign15,
      ADDRB => pgassign16,
      CASCADEINLATB => net_gnd0,
      CASCADEINREGB => net_gnd0,
      CASCADEOUTLATB => open,
      CASCADEOUTREGB => open,
      CLKB => BRAM_Clk_B,
      DIB => pgassign17,
      DIPB => net_gnd4,
      DOB => pgassign18,
      DOPB => open,
      ENB => BRAM_EN_B,
      REGCEB => net_gnd0,
      SSRB => BRAM_Rst_B,
      WEB => pgassign19
    );

  ramb36_2 : RAMB36
    generic map (
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
--      INIT_FILE => "lmb_bram_instr_combined_2.mem",
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
      WRITE_WIDTH_A => 9,
      WRITE_WIDTH_B => 9,
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",

INIT_00 => lmb_bram_lmb_bram_ramb36_2_INIT_00,
INIT_01 => lmb_bram_lmb_bram_ramb36_2_INIT_01,
INIT_02 => lmb_bram_lmb_bram_ramb36_2_INIT_02,
INIT_03 => lmb_bram_lmb_bram_ramb36_2_INIT_03,
INIT_04 => lmb_bram_lmb_bram_ramb36_2_INIT_04,
INIT_05 => lmb_bram_lmb_bram_ramb36_2_INIT_05,
INIT_06 => lmb_bram_lmb_bram_ramb36_2_INIT_06,
INIT_07 => lmb_bram_lmb_bram_ramb36_2_INIT_07,
INIT_08 => lmb_bram_lmb_bram_ramb36_2_INIT_08,
INIT_09 => lmb_bram_lmb_bram_ramb36_2_INIT_09,
INIT_0A => lmb_bram_lmb_bram_ramb36_2_INIT_0A,
INIT_0B => lmb_bram_lmb_bram_ramb36_2_INIT_0B,
INIT_0C => lmb_bram_lmb_bram_ramb36_2_INIT_0C,
INIT_0D => lmb_bram_lmb_bram_ramb36_2_INIT_0D,
INIT_0E => lmb_bram_lmb_bram_ramb36_2_INIT_0E,
INIT_0F => lmb_bram_lmb_bram_ramb36_2_INIT_0F,
INIT_10 => lmb_bram_lmb_bram_ramb36_2_INIT_10,
INIT_11 => lmb_bram_lmb_bram_ramb36_2_INIT_11,
INIT_12 => lmb_bram_lmb_bram_ramb36_2_INIT_12,
INIT_13 => lmb_bram_lmb_bram_ramb36_2_INIT_13,
INIT_14 => lmb_bram_lmb_bram_ramb36_2_INIT_14,
INIT_15 => lmb_bram_lmb_bram_ramb36_2_INIT_15,
INIT_16 => lmb_bram_lmb_bram_ramb36_2_INIT_16,
INIT_17 => lmb_bram_lmb_bram_ramb36_2_INIT_17,
INIT_18 => lmb_bram_lmb_bram_ramb36_2_INIT_18,
INIT_19 => lmb_bram_lmb_bram_ramb36_2_INIT_19,
INIT_1A => lmb_bram_lmb_bram_ramb36_2_INIT_1A,
INIT_1B => lmb_bram_lmb_bram_ramb36_2_INIT_1B,
INIT_1C => lmb_bram_lmb_bram_ramb36_2_INIT_1C,
INIT_1D => lmb_bram_lmb_bram_ramb36_2_INIT_1D,
INIT_1E => lmb_bram_lmb_bram_ramb36_2_INIT_1E,
INIT_1F => lmb_bram_lmb_bram_ramb36_2_INIT_1F,
INIT_20 => lmb_bram_lmb_bram_ramb36_2_INIT_20,
INIT_21 => lmb_bram_lmb_bram_ramb36_2_INIT_21,
INIT_22 => lmb_bram_lmb_bram_ramb36_2_INIT_22,
INIT_23 => lmb_bram_lmb_bram_ramb36_2_INIT_23,
INIT_24 => lmb_bram_lmb_bram_ramb36_2_INIT_24,
INIT_25 => lmb_bram_lmb_bram_ramb36_2_INIT_25,
INIT_26 => lmb_bram_lmb_bram_ramb36_2_INIT_26,
INIT_27 => lmb_bram_lmb_bram_ramb36_2_INIT_27,
INIT_28 => lmb_bram_lmb_bram_ramb36_2_INIT_28,
INIT_29 => lmb_bram_lmb_bram_ramb36_2_INIT_29,
INIT_2A => lmb_bram_lmb_bram_ramb36_2_INIT_2A,
INIT_2B => lmb_bram_lmb_bram_ramb36_2_INIT_2B,
INIT_2C => lmb_bram_lmb_bram_ramb36_2_INIT_2C,
INIT_2D => lmb_bram_lmb_bram_ramb36_2_INIT_2D,
INIT_2E => lmb_bram_lmb_bram_ramb36_2_INIT_2E,
INIT_2F => lmb_bram_lmb_bram_ramb36_2_INIT_2F,
INIT_30 => lmb_bram_lmb_bram_ramb36_2_INIT_30,
INIT_31 => lmb_bram_lmb_bram_ramb36_2_INIT_31,
INIT_32 => lmb_bram_lmb_bram_ramb36_2_INIT_32,
INIT_33 => lmb_bram_lmb_bram_ramb36_2_INIT_33,
INIT_34 => lmb_bram_lmb_bram_ramb36_2_INIT_34,
INIT_35 => lmb_bram_lmb_bram_ramb36_2_INIT_35,
INIT_36 => lmb_bram_lmb_bram_ramb36_2_INIT_36,
INIT_37 => lmb_bram_lmb_bram_ramb36_2_INIT_37,
INIT_38 => lmb_bram_lmb_bram_ramb36_2_INIT_38,
INIT_39 => lmb_bram_lmb_bram_ramb36_2_INIT_39,
INIT_3A => lmb_bram_lmb_bram_ramb36_2_INIT_3A,
INIT_3B => lmb_bram_lmb_bram_ramb36_2_INIT_3B,
INIT_3C => lmb_bram_lmb_bram_ramb36_2_INIT_3C,
INIT_3D => lmb_bram_lmb_bram_ramb36_2_INIT_3D,
INIT_3E => lmb_bram_lmb_bram_ramb36_2_INIT_3E,
INIT_3F => lmb_bram_lmb_bram_ramb36_2_INIT_3F,
INIT_40 => lmb_bram_lmb_bram_ramb36_2_INIT_40,
INIT_41 => lmb_bram_lmb_bram_ramb36_2_INIT_41,
INIT_42 => lmb_bram_lmb_bram_ramb36_2_INIT_42,
INIT_43 => lmb_bram_lmb_bram_ramb36_2_INIT_43,
INIT_44 => lmb_bram_lmb_bram_ramb36_2_INIT_44,
INIT_45 => lmb_bram_lmb_bram_ramb36_2_INIT_45,
INIT_46 => lmb_bram_lmb_bram_ramb36_2_INIT_46,
INIT_47 => lmb_bram_lmb_bram_ramb36_2_INIT_47,
INIT_48 => lmb_bram_lmb_bram_ramb36_2_INIT_48,
INIT_49 => lmb_bram_lmb_bram_ramb36_2_INIT_49,
INIT_4A => lmb_bram_lmb_bram_ramb36_2_INIT_4A,
INIT_4B => lmb_bram_lmb_bram_ramb36_2_INIT_4B,
INIT_4C => lmb_bram_lmb_bram_ramb36_2_INIT_4C,
INIT_4D => lmb_bram_lmb_bram_ramb36_2_INIT_4D,
INIT_4E => lmb_bram_lmb_bram_ramb36_2_INIT_4E,
INIT_4F => lmb_bram_lmb_bram_ramb36_2_INIT_4F,
INIT_50 => lmb_bram_lmb_bram_ramb36_2_INIT_50,
INIT_51 => lmb_bram_lmb_bram_ramb36_2_INIT_51,
INIT_52 => lmb_bram_lmb_bram_ramb36_2_INIT_52,
INIT_53 => lmb_bram_lmb_bram_ramb36_2_INIT_53,
INIT_54 => lmb_bram_lmb_bram_ramb36_2_INIT_54,
INIT_55 => lmb_bram_lmb_bram_ramb36_2_INIT_55,
INIT_56 => lmb_bram_lmb_bram_ramb36_2_INIT_56,
INIT_57 => lmb_bram_lmb_bram_ramb36_2_INIT_57,
INIT_58 => lmb_bram_lmb_bram_ramb36_2_INIT_58,
INIT_59 => lmb_bram_lmb_bram_ramb36_2_INIT_59,
INIT_5A => lmb_bram_lmb_bram_ramb36_2_INIT_5A,
INIT_5B => lmb_bram_lmb_bram_ramb36_2_INIT_5B,
INIT_5C => lmb_bram_lmb_bram_ramb36_2_INIT_5C,
INIT_5D => lmb_bram_lmb_bram_ramb36_2_INIT_5D,
INIT_5E => lmb_bram_lmb_bram_ramb36_2_INIT_5E,
INIT_5F => lmb_bram_lmb_bram_ramb36_2_INIT_5F,
INIT_60 => lmb_bram_lmb_bram_ramb36_2_INIT_60,
INIT_61 => lmb_bram_lmb_bram_ramb36_2_INIT_61,
INIT_62 => lmb_bram_lmb_bram_ramb36_2_INIT_62,
INIT_63 => lmb_bram_lmb_bram_ramb36_2_INIT_63,
INIT_64 => lmb_bram_lmb_bram_ramb36_2_INIT_64,
INIT_65 => lmb_bram_lmb_bram_ramb36_2_INIT_65,
INIT_66 => lmb_bram_lmb_bram_ramb36_2_INIT_66,
INIT_67 => lmb_bram_lmb_bram_ramb36_2_INIT_67,
INIT_68 => lmb_bram_lmb_bram_ramb36_2_INIT_68,
INIT_69 => lmb_bram_lmb_bram_ramb36_2_INIT_69,
INIT_6A => lmb_bram_lmb_bram_ramb36_2_INIT_6A,
INIT_6B => lmb_bram_lmb_bram_ramb36_2_INIT_6B,
INIT_6C => lmb_bram_lmb_bram_ramb36_2_INIT_6C,
INIT_6D => lmb_bram_lmb_bram_ramb36_2_INIT_6D,
INIT_6E => lmb_bram_lmb_bram_ramb36_2_INIT_6E,
INIT_6F => lmb_bram_lmb_bram_ramb36_2_INIT_6F,
INIT_70 => lmb_bram_lmb_bram_ramb36_2_INIT_70,
INIT_71 => lmb_bram_lmb_bram_ramb36_2_INIT_71,
INIT_72 => lmb_bram_lmb_bram_ramb36_2_INIT_72,
INIT_73 => lmb_bram_lmb_bram_ramb36_2_INIT_73,
INIT_74 => lmb_bram_lmb_bram_ramb36_2_INIT_74,
INIT_75 => lmb_bram_lmb_bram_ramb36_2_INIT_75,
INIT_76 => lmb_bram_lmb_bram_ramb36_2_INIT_76,
INIT_77 => lmb_bram_lmb_bram_ramb36_2_INIT_77,
INIT_78 => lmb_bram_lmb_bram_ramb36_2_INIT_78,
INIT_79 => lmb_bram_lmb_bram_ramb36_2_INIT_79,
INIT_7A => lmb_bram_lmb_bram_ramb36_2_INIT_7A,
INIT_7B => lmb_bram_lmb_bram_ramb36_2_INIT_7B,
INIT_7C => lmb_bram_lmb_bram_ramb36_2_INIT_7C,
INIT_7D => lmb_bram_lmb_bram_ramb36_2_INIT_7D,
INIT_7E => lmb_bram_lmb_bram_ramb36_2_INIT_7E,
INIT_7F => lmb_bram_lmb_bram_ramb36_2_INIT_7F
    )
    port map (
      ADDRA => pgassign20,
      CASCADEINLATA => net_gnd0,
      CASCADEINREGA => net_gnd0,
      CASCADEOUTLATA => open,
      CASCADEOUTREGA => open,
      CLKA => BRAM_Clk_A,
      DIA => pgassign21,
      DIPA => net_gnd4,
      DOA => pgassign22,
      DOPA => open,
      ENA => BRAM_EN_A,
      REGCEA => net_gnd0,
      SSRA => BRAM_Rst_A,
      WEA => pgassign23,
      ADDRB => pgassign24,
      CASCADEINLATB => net_gnd0,
      CASCADEINREGB => net_gnd0,
      CASCADEOUTLATB => open,
      CASCADEOUTREGB => open,
      CLKB => BRAM_Clk_B,
      DIB => pgassign25,
      DIPB => net_gnd4,
      DOB => pgassign26,
      DOPB => open,
      ENB => BRAM_EN_B,
      REGCEB => net_gnd0,
      SSRB => BRAM_Rst_B,
      WEB => pgassign27
    );

  ramb36_3 : RAMB36
    generic map (
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
--      INIT_FILE => "lmb_bram_instr_combined_3.mem",
      READ_WIDTH_A => 9,
      READ_WIDTH_B => 9,
      WRITE_WIDTH_A => 9,
      WRITE_WIDTH_B => 9,
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",

INIT_00 => lmb_bram_lmb_bram_ramb36_3_INIT_00,
INIT_01 => lmb_bram_lmb_bram_ramb36_3_INIT_01,
INIT_02 => lmb_bram_lmb_bram_ramb36_3_INIT_02,
INIT_03 => lmb_bram_lmb_bram_ramb36_3_INIT_03,
INIT_04 => lmb_bram_lmb_bram_ramb36_3_INIT_04,
INIT_05 => lmb_bram_lmb_bram_ramb36_3_INIT_05,
INIT_06 => lmb_bram_lmb_bram_ramb36_3_INIT_06,
INIT_07 => lmb_bram_lmb_bram_ramb36_3_INIT_07,
INIT_08 => lmb_bram_lmb_bram_ramb36_3_INIT_08,
INIT_09 => lmb_bram_lmb_bram_ramb36_3_INIT_09,
INIT_0A => lmb_bram_lmb_bram_ramb36_3_INIT_0A,
INIT_0B => lmb_bram_lmb_bram_ramb36_3_INIT_0B,
INIT_0C => lmb_bram_lmb_bram_ramb36_3_INIT_0C,
INIT_0D => lmb_bram_lmb_bram_ramb36_3_INIT_0D,
INIT_0E => lmb_bram_lmb_bram_ramb36_3_INIT_0E,
INIT_0F => lmb_bram_lmb_bram_ramb36_3_INIT_0F,
INIT_10 => lmb_bram_lmb_bram_ramb36_3_INIT_10,
INIT_11 => lmb_bram_lmb_bram_ramb36_3_INIT_11,
INIT_12 => lmb_bram_lmb_bram_ramb36_3_INIT_12,
INIT_13 => lmb_bram_lmb_bram_ramb36_3_INIT_13,
INIT_14 => lmb_bram_lmb_bram_ramb36_3_INIT_14,
INIT_15 => lmb_bram_lmb_bram_ramb36_3_INIT_15,
INIT_16 => lmb_bram_lmb_bram_ramb36_3_INIT_16,
INIT_17 => lmb_bram_lmb_bram_ramb36_3_INIT_17,
INIT_18 => lmb_bram_lmb_bram_ramb36_3_INIT_18,
INIT_19 => lmb_bram_lmb_bram_ramb36_3_INIT_19,
INIT_1A => lmb_bram_lmb_bram_ramb36_3_INIT_1A,
INIT_1B => lmb_bram_lmb_bram_ramb36_3_INIT_1B,
INIT_1C => lmb_bram_lmb_bram_ramb36_3_INIT_1C,
INIT_1D => lmb_bram_lmb_bram_ramb36_3_INIT_1D,
INIT_1E => lmb_bram_lmb_bram_ramb36_3_INIT_1E,
INIT_1F => lmb_bram_lmb_bram_ramb36_3_INIT_1F,
INIT_20 => lmb_bram_lmb_bram_ramb36_3_INIT_20,
INIT_21 => lmb_bram_lmb_bram_ramb36_3_INIT_21,
INIT_22 => lmb_bram_lmb_bram_ramb36_3_INIT_22,
INIT_23 => lmb_bram_lmb_bram_ramb36_3_INIT_23,
INIT_24 => lmb_bram_lmb_bram_ramb36_3_INIT_24,
INIT_25 => lmb_bram_lmb_bram_ramb36_3_INIT_25,
INIT_26 => lmb_bram_lmb_bram_ramb36_3_INIT_26,
INIT_27 => lmb_bram_lmb_bram_ramb36_3_INIT_27,
INIT_28 => lmb_bram_lmb_bram_ramb36_3_INIT_28,
INIT_29 => lmb_bram_lmb_bram_ramb36_3_INIT_29,
INIT_2A => lmb_bram_lmb_bram_ramb36_3_INIT_2A,
INIT_2B => lmb_bram_lmb_bram_ramb36_3_INIT_2B,
INIT_2C => lmb_bram_lmb_bram_ramb36_3_INIT_2C,
INIT_2D => lmb_bram_lmb_bram_ramb36_3_INIT_2D,
INIT_2E => lmb_bram_lmb_bram_ramb36_3_INIT_2E,
INIT_2F => lmb_bram_lmb_bram_ramb36_3_INIT_2F,
INIT_30 => lmb_bram_lmb_bram_ramb36_3_INIT_30,
INIT_31 => lmb_bram_lmb_bram_ramb36_3_INIT_31,
INIT_32 => lmb_bram_lmb_bram_ramb36_3_INIT_32,
INIT_33 => lmb_bram_lmb_bram_ramb36_3_INIT_33,
INIT_34 => lmb_bram_lmb_bram_ramb36_3_INIT_34,
INIT_35 => lmb_bram_lmb_bram_ramb36_3_INIT_35,
INIT_36 => lmb_bram_lmb_bram_ramb36_3_INIT_36,
INIT_37 => lmb_bram_lmb_bram_ramb36_3_INIT_37,
INIT_38 => lmb_bram_lmb_bram_ramb36_3_INIT_38,
INIT_39 => lmb_bram_lmb_bram_ramb36_3_INIT_39,
INIT_3A => lmb_bram_lmb_bram_ramb36_3_INIT_3A,
INIT_3B => lmb_bram_lmb_bram_ramb36_3_INIT_3B,
INIT_3C => lmb_bram_lmb_bram_ramb36_3_INIT_3C,
INIT_3D => lmb_bram_lmb_bram_ramb36_3_INIT_3D,
INIT_3E => lmb_bram_lmb_bram_ramb36_3_INIT_3E,
INIT_3F => lmb_bram_lmb_bram_ramb36_3_INIT_3F,
INIT_40 => lmb_bram_lmb_bram_ramb36_3_INIT_40,
INIT_41 => lmb_bram_lmb_bram_ramb36_3_INIT_41,
INIT_42 => lmb_bram_lmb_bram_ramb36_3_INIT_42,
INIT_43 => lmb_bram_lmb_bram_ramb36_3_INIT_43,
INIT_44 => lmb_bram_lmb_bram_ramb36_3_INIT_44,
INIT_45 => lmb_bram_lmb_bram_ramb36_3_INIT_45,
INIT_46 => lmb_bram_lmb_bram_ramb36_3_INIT_46,
INIT_47 => lmb_bram_lmb_bram_ramb36_3_INIT_47,
INIT_48 => lmb_bram_lmb_bram_ramb36_3_INIT_48,
INIT_49 => lmb_bram_lmb_bram_ramb36_3_INIT_49,
INIT_4A => lmb_bram_lmb_bram_ramb36_3_INIT_4A,
INIT_4B => lmb_bram_lmb_bram_ramb36_3_INIT_4B,
INIT_4C => lmb_bram_lmb_bram_ramb36_3_INIT_4C,
INIT_4D => lmb_bram_lmb_bram_ramb36_3_INIT_4D,
INIT_4E => lmb_bram_lmb_bram_ramb36_3_INIT_4E,
INIT_4F => lmb_bram_lmb_bram_ramb36_3_INIT_4F,
INIT_50 => lmb_bram_lmb_bram_ramb36_3_INIT_50,
INIT_51 => lmb_bram_lmb_bram_ramb36_3_INIT_51,
INIT_52 => lmb_bram_lmb_bram_ramb36_3_INIT_52,
INIT_53 => lmb_bram_lmb_bram_ramb36_3_INIT_53,
INIT_54 => lmb_bram_lmb_bram_ramb36_3_INIT_54,
INIT_55 => lmb_bram_lmb_bram_ramb36_3_INIT_55,
INIT_56 => lmb_bram_lmb_bram_ramb36_3_INIT_56,
INIT_57 => lmb_bram_lmb_bram_ramb36_3_INIT_57,
INIT_58 => lmb_bram_lmb_bram_ramb36_3_INIT_58,
INIT_59 => lmb_bram_lmb_bram_ramb36_3_INIT_59,
INIT_5A => lmb_bram_lmb_bram_ramb36_3_INIT_5A,
INIT_5B => lmb_bram_lmb_bram_ramb36_3_INIT_5B,
INIT_5C => lmb_bram_lmb_bram_ramb36_3_INIT_5C,
INIT_5D => lmb_bram_lmb_bram_ramb36_3_INIT_5D,
INIT_5E => lmb_bram_lmb_bram_ramb36_3_INIT_5E,
INIT_5F => lmb_bram_lmb_bram_ramb36_3_INIT_5F,
INIT_60 => lmb_bram_lmb_bram_ramb36_3_INIT_60,
INIT_61 => lmb_bram_lmb_bram_ramb36_3_INIT_61,
INIT_62 => lmb_bram_lmb_bram_ramb36_3_INIT_62,
INIT_63 => lmb_bram_lmb_bram_ramb36_3_INIT_63,
INIT_64 => lmb_bram_lmb_bram_ramb36_3_INIT_64,
INIT_65 => lmb_bram_lmb_bram_ramb36_3_INIT_65,
INIT_66 => lmb_bram_lmb_bram_ramb36_3_INIT_66,
INIT_67 => lmb_bram_lmb_bram_ramb36_3_INIT_67,
INIT_68 => lmb_bram_lmb_bram_ramb36_3_INIT_68,
INIT_69 => lmb_bram_lmb_bram_ramb36_3_INIT_69,
INIT_6A => lmb_bram_lmb_bram_ramb36_3_INIT_6A,
INIT_6B => lmb_bram_lmb_bram_ramb36_3_INIT_6B,
INIT_6C => lmb_bram_lmb_bram_ramb36_3_INIT_6C,
INIT_6D => lmb_bram_lmb_bram_ramb36_3_INIT_6D,
INIT_6E => lmb_bram_lmb_bram_ramb36_3_INIT_6E,
INIT_6F => lmb_bram_lmb_bram_ramb36_3_INIT_6F,
INIT_70 => lmb_bram_lmb_bram_ramb36_3_INIT_70,
INIT_71 => lmb_bram_lmb_bram_ramb36_3_INIT_71,
INIT_72 => lmb_bram_lmb_bram_ramb36_3_INIT_72,
INIT_73 => lmb_bram_lmb_bram_ramb36_3_INIT_73,
INIT_74 => lmb_bram_lmb_bram_ramb36_3_INIT_74,
INIT_75 => lmb_bram_lmb_bram_ramb36_3_INIT_75,
INIT_76 => lmb_bram_lmb_bram_ramb36_3_INIT_76,
INIT_77 => lmb_bram_lmb_bram_ramb36_3_INIT_77,
INIT_78 => lmb_bram_lmb_bram_ramb36_3_INIT_78,
INIT_79 => lmb_bram_lmb_bram_ramb36_3_INIT_79,
INIT_7A => lmb_bram_lmb_bram_ramb36_3_INIT_7A,
INIT_7B => lmb_bram_lmb_bram_ramb36_3_INIT_7B,
INIT_7C => lmb_bram_lmb_bram_ramb36_3_INIT_7C,
INIT_7D => lmb_bram_lmb_bram_ramb36_3_INIT_7D,
INIT_7E => lmb_bram_lmb_bram_ramb36_3_INIT_7E,
INIT_7F => lmb_bram_lmb_bram_ramb36_3_INIT_7F
    )
    port map (
      ADDRA => pgassign28,
      CASCADEINLATA => net_gnd0,
      CASCADEINREGA => net_gnd0,
      CASCADEOUTLATA => open,
      CASCADEOUTREGA => open,
      CLKA => BRAM_Clk_A,
      DIA => pgassign29,
      DIPA => net_gnd4,
      DOA => pgassign30,
      DOPA => open,
      ENA => BRAM_EN_A,
      REGCEA => net_gnd0,
      SSRA => BRAM_Rst_A,
      WEA => pgassign31,
      ADDRB => pgassign32,
      CASCADEINLATB => net_gnd0,
      CASCADEINREGB => net_gnd0,
      CASCADEOUTLATB => open,
      CASCADEOUTREGB => open,
      CLKB => BRAM_Clk_B,
      DIB => pgassign33,
      DIPB => net_gnd4,
      DOB => pgassign34,
      DOPB => open,
      ENB => BRAM_EN_B,
      REGCEB => net_gnd0,
      SSRB => BRAM_Rst_B,
      WEB => pgassign35
    );

end architecture STRUCTURE;
