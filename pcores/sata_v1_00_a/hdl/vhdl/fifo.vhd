--SINGLE_FILE_TAG
-------------------------------------------------------------------------------
-- $Id: fifo.vhd,v 1.1.2.1 2008/06/30 15:52:32 jece Exp $
-------------------------------------------------------------------------------
-- Xilinx MicroBlaze Trace Encoder FIFO - entity/architecture
-------------------------------------------------------------------------------
--
-- ****************************************************************************
-- ** Copyright(C) 2001-2005 by Xilinx, Inc. All rights reserved.
-- **
-- ** This text contains proprietary, confidential information of
-- ** Xilinx, Inc. , is distributed by under license from Xilinx, Inc.,
-- ** and may be used, copied and/or disclosed only pursuant to the
-- ** terms of a valid license agreement with Xilinx, Inc.
-- **
-- ** Unmodified source code is guaranteed to place and route,
-- ** function and run at speed according to the datasheet
-- ** specification. Source code is provided "as-is", with no
-- ** obligation on the part of Xilinx to provide support.
-- **
-- ** Xilinx Hotline support of source code IP shall only include
-- ** standard level Xilinx Hotline support, and will only address
-- ** issues and questions related to the standard released Netlist
-- ** version of the core (and thus indirectly, the original core source
-- **
-- ** The Xilinx Support Hotline does not have access to source
-- ** code and therefore cannot answer specific questions related
-- ** to source HDL. The Xilinx Support Hotline will only be able
-- ** to confirm the problem in the Netlist version of the core.
-- **
-- ** This copyright and support notice must be retained as part
-- ** of this text at all times.
-- ****************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        fifo.vhd
-- Version:         v1.00a
-- Description:     Xilinx MicroBlaze Trace Encoder FIFO
--                  
-- VHDL-Standard: VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              fifo.vhd
--                      dyn_shift_reg.vhd
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "*_clk"
--      reset signals:                          "rst", "*_rst", "reset"
--      generics:                               All uppercase, starting with: "C_"
--      constants:                              All uppercase, not starting with: "C_"
--      state machine next state:               "*_next_state"
--      state machine current state:            "*_curr_state"
--      pipelined signals:                      "*_d#"
--      counter signals:                        "*_cnt_*" , "*_counter_*", "*_count_*"
--      internal version of output port:        "*_i"
--      ports:                                  Names begin with uppercase
--      component instantiations:               "<ENTITY>_I#|<FUNC>" , "<ENTITY>_I"
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

library UNISIM;
use UNISIM.VComponents.all;

entity fifo is
  generic (
    DATA_WIDTH :    integer := 1
  );
  port (
    Clk        : in std_logic;
    Rst        : in std_logic;

    DATA_IN      : in  std_logic_vector(0 to DATA_WIDTH-1);
    DATA_OUT     : out std_logic_vector(0 to DATA_WIDTH-1);
    WR_EN        : in  std_logic;
    RD_EN        : in  std_logic;
    FULL         : out std_logic;
    EMPTY        : out std_logic;
    ALMOST_FULL  : out std_logic;
    ALMOST_EMPTY : out std_logic
  );
end entity fifo;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture IMP of fifo is

-- component dyn_shift_reg
-- generic (
-- A_WIDTH : integer := 4               -- Size of SRL is 2**4 = 16
--     );
--     port (
--       Q         : out std_logic;
--       A         : in  std_logic_vector(A_WIDTH-1 downto 0);
--       CE        : in  std_logic;
--       CLK       : in  std_logic;
--       D         : in  std_logic
--     );
--   end component;

  signal srl_en          : std_logic;
  signal srl_addr        : std_logic_vector(3 downto 0) := (others => '0');
  signal is_empty        : std_logic                    := '1';
  signal is_full         : std_logic;
  signal is_almost_empty : std_logic;
  signal is_almost_full  : std_logic;

begin

  DSR_GENERATE : for i in 0 to DATA_WIDTH-1 generate

    DSR_INST : SRL16E
      generic map (
        INIT => X"0000"
-- A_WIDTH => 4
      )
      port map (
        Q    => DATA_OUT(i),
        A0   => srl_addr(0),
        A1   => srl_addr(1),
        A2   => srl_addr(2),
        A3   => srl_addr(3),
-- A => srl_addr,
        CE   => srl_en,
        CLK  => Clk,
        D    => DATA_IN(i)
      );

  end generate;

  -- Sequential logic
  address_counter : process (Clk, Rst)
  begin
    if Rst = '1' then
      srl_addr       <= "0000";
      is_empty       <= '1';
    else
      if Clk'event and Clk = '1' then
        if WR_EN = '1' and RD_EN = '0' and is_full = '0' then
          if is_empty = '0' then
            srl_addr <= unsigned(srl_addr) + 1;
          end if;
          is_empty   <= '0';
        elsif WR_EN = '0' and RD_EN = '1' and is_empty = '0' then
          if srl_addr = "0000" then
            is_empty <= '1';
          else
            srl_addr <= unsigned(srl_addr) - 1;
          end if;
        end if;
      end if;
    end if;
  end process address_counter;

  -- Combinational logic
  srl_en          <= WR_EN and not is_full;
  is_full         <= '1' when srl_addr = "1111"                    else '0';
  is_almost_full  <= '1' when srl_addr = "1110"                    else '0';
  is_almost_empty <= '1' when srl_addr = "0000" and is_empty = '0' else '0';

  -- Outputs
  FULL         <= is_full;
  EMPTY        <= is_empty;
  ALMOST_FULL  <= is_almost_full;
  ALMOST_EMPTY <= is_almost_empty;

end architecture IMP;
