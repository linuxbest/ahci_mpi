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
-- Description - VFBC Backend Control
--               This module controls the backend of the VFBC and
--               translates the MIG interface into the MPMC NPI 
--               interface.
--******************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library work;
use work.memxlib_utils.all;


entity vfbc_backend_control is
  generic(
        VFBC_NPI_WIDTH  : integer := 64;        -- VFBC NPI Width. 32 or 64
        VFBC_BURST_LENGTH : integer := 8;       -- VFBC Burst Length. 32
        NUM_DATA_PORTS  : integer := 1          -- Number of Data Ports
  );
  port(
    clk                 : in std_logic;         -- VFBC/MPMC_CLK0
    srst                : in std_logic;         -- Synchronous Reset

    -- VFBC FIFO Flags
    wd_reset            : in std_logic;         -- Write FIFO Reset
    wd_flush            : in std_logic;         -- Write FIFO Flush
    rd_reset            : in std_logic;         -- Read FIFO Reset
    rd_flush            : in std_logic;         -- Read FIFO Flush

    -- VFBC Memory Controller Interface
    App_Af_addr         : in std_logic_vector(35 downto 0);                -- Memory Controller Address Fifo Address
                                                                           -- (35:32=command,31:0=address)
    App_Af_wren         : in std_logic;                                    -- Memory Controller Address Fifo Address
    App_WDF_data        : in std_logic_vector(VFBC_NPI_WIDTH-1 downto 0);  -- Memory Controller Write Data FIFO Data
    App_Mask_data       : in std_logic_vector(VFBC_NPI_WIDTH/8-1 downto 0);-- Memory Controller Mask Data (One bit per data byte,
                                                                           -- opposite polarity as byte enable)
    App_WDF_wren        : in std_logic;                                    -- Memory Controller Write Data FIFO Write Enable. 
                                                                           -- Active High

    rd_active_afull     : in std_logic_vector(NUM_DATA_PORTS-1 downto 0);  -- Read FIFO Almost Full ANDed with Active Read Ports

    Read_data_valid     : out std_logic;                                   -- Memory Controller Read Data Valid. Active High
    Read_data_fifo_out  : out std_logic_vector(VFBC_NPI_WIDTH-1 downto 0); -- Memory Controller Read Data
    WDF_Almost_Full     : out std_logic;                                   -- Memory Controller Write Data FIFO Almost Full
    AF_Almost_Full      : out std_logic;                                   -- Memory Controller Address FIFO Almost Full

    -- MPMC Native Port Interface (NPI)
    npi_init_done       : in  std_logic;                                   -- NPI Memory Initialization Done.  Active High
    npi_addr_ack        : in  std_logic;                                   -- NPI Address Acknowledg
    npi_rdfifo_word_add : in  std_logic_vector(3 downto 0);                -- RESERVED
    npi_rdfifo_data     : in  std_logic_vector(VFBC_NPI_WIDTH-1 downto 0); -- NPI Read FIFO Data 
    npi_rdfifo_latency  : in  std_logic_vector(1 downto 0);                -- NPI Read FIFO latency from pop: Valid {0,1,2}
    npi_rdfifo_empty    : in  std_logic;                                   -- NPI Read FIFO Empty Flag. Active High.
    npi_wrfifo_almost_full : in std_logic;                                 -- NPI Write FIFO Almost Full Flag. Active High.

    npi_address         : out std_logic_vector(31 downto 0);               -- NPI Address.  External Memory address
    npi_addr_req        : out std_logic;                                   -- NPI Address Request. Active High
    npi_size            : out std_logic_vector(3 downto 0);                -- NPI Transfer Size
    npi_rnw             : out std_logic;                                   -- NPI Read Not Write
    npi_rdfifo_pop      : out std_logic;                                   -- NPI Read FIFO Pop/Read Enable. Active High
    npi_rdfifo_flush    : out std_logic;                                   -- NPI Read FIFO Flush. Active High
    npi_wrfifo_data     : out std_logic_vector(VFBC_NPI_WIDTH-1 downto 0); -- NPI Write FIFO Data. Active High
    npi_wrfifo_be       : out std_logic_vector(VFBC_NPI_WIDTH/8-1 downto 0); -- NPI Write FIFO Byte Enable. Active High
    npi_wrfifo_push     : out std_logic;                                   -- NPI Write FIFO Push/Write-Enable. Active High
    npi_wrfifo_flush    : out std_logic                                    -- NPI Write FIFO Flush. Active High

  );
end vfbc_backend_control;

architecture rtl of vfbc_backend_control is
signal address          : std_logic_vector(32 downto 0);
--signal address_d1       : std_logic_vector(32 downto 0);
--signal address_d2       : std_logic_vector(32 downto 0);
--signal req_pipe         : std_logic_vector(2+((VFBC_BURST_LENGTH-8)/2) downto 0);
signal req_pipe         : std_logic_vector((VFBC_BURST_LENGTH/2)-2 downto 0); -- 6 cycles + burst length. 
signal afifo_empty      : std_logic;
signal afifo_re         : std_logic;
signal afifo_afull      : std_logic;
signal npi_addr_req_int : std_logic;
signal vfbc_read_fifo_afull : std_logic;
signal rdfifo_pop       : std_logic;
signal Read_data_valid_d1 : std_logic;
signal Read_data_valid_d2 : std_logic;
signal npi_rdfifo_flush_d : std_logic_vector(1 downto 0);
signal npi_wrfifo_flush_d : std_logic_vector(1 downto 0);
signal npi_rdfifo_reset_d : std_logic_vector(1 downto 0);
signal npi_wrfifo_reset_d : std_logic_vector(1 downto 0);
signal add_fifo_reset   : std_logic;

signal wrdata_fifo_re   : std_logic;
signal wrdata_fifo_reset: std_logic;
signal wrdata_fifo_empty: std_logic;
signal wrdata_fifo_afull: std_logic;
signal wrdata_fifo_afull_d: std_logic;
signal wrdata_fifo_d    : std_logic_vector(VFBC_NPI_WIDTH*9/8 -1 downto 0);
signal wrdata_fifo_q    : std_logic_vector(VFBC_NPI_WIDTH*9/8 -1 downto 0);

--attribute SYN_PRESERVE        : boolean;
--attribute KEEP                : boolean;
--attribute KEEP         of npi_wrfifo_flush_d : signal is TRUE;
--attribute KEEP         of npi_wrfifo_reset_d : signal is TRUE;
--attribute KEEP         of npi_wrfifo_flush   : signal is TRUE;
--
--attribute KEEP         of npi_rdfifo_flush_d : signal is TRUE;
--attribute KEEP         of npi_rdfifo_reset_d : signal is TRUE;
--attribute KEEP         of npi_rdfifo_flush   : signal is TRUE;
--
--attribute SYN_PRESERVE of npi_wrfifo_flush_d : signal is TRUE;
--attribute SYN_PRESERVE of npi_wrfifo_reset_d : signal is TRUE;
--attribute SYN_PRESERVE of npi_wrfifo_flush   : signal is TRUE;
--
--attribute SYN_PRESERVE of npi_rdfifo_flush_d : signal is TRUE;
--attribute SYN_PRESERVE of npi_rdfifo_reset_d : signal is TRUE;
--attribute SYN_PRESERVE of npi_rdfifo_flush   : signal is TRUE;

begin


  -- Address
--  process(clk)
--  begin
--    if(rising_edge(clk)) then
--      if(srst = '1') then
--        address_d1      <= (others => '0');
--        address_d2      <= (others => '0');
--      else
--        address_d1 <= App_Af_addr(32 downto 0);
--        address_d2 <= address_d1;
--      end if;
--    end if;
--  end process;
--
--  --npi_address   <= App_Af_addr(31 downto 0);
--  --npi_rnw       <= App_Af_addr(32);
--  npi_address   <= address_d2(31 downto 0);
--  npi_rnw       <= address_d2(32);
--  --npi_addr_req  <= App_Af_wren;
--  process(clk)
--  begin
--    if(rising_edge(clk)) then
--      if(srst = '1') then
--        req_pipe        <= (others =>'0');
--        npi_addr_req    <= '0';
--      else
--        if(req_pipe(req_pipe'high) = '1') then
--          npi_addr_req <= '1';
--        elsif(npi_addr_ack = '1') then
--          npi_addr_req <= '0';
--        end if;
--
--        
--        req_pipe(req_pipe'high downto 0) <= req_pipe(req_pipe'high-1 downto 0) & App_Af_wren;
--      end if;
--    end if;
--  end process;
  --add_fifo_reset <= srst or npi_rdfifo_flush_dly(npi_rdfifo_flush_dly'high) or npi_wrfifo_flush_dly(npi_wrfifo_flush_dly'high);
  add_fifo_reset <= srst;

  Address_fifo0: entity work.synch_fifo(rtl)
     generic map (input_reg   => 1, 
                  dwidth      => 33,
                  depth       => 8,  -- 64 does not work
                  afull_count => 6, --3,
                  mem_type    => DIST_RAMSTYLE ) -- BLOCK_RAMSTYLE=no_rw_check, DIST_RAMSTYLE=select_ram, registers
                  --mem_type    => BLOCK_RAMSTYLE) -- BLOCK_RAMSTYLE=no_rw_check, DIST_RAMSTYLE=select_ram, registers
     port map (
         clk     => clk,
         sclr    => add_fifo_reset, --srst,
         d       => App_Af_addr(32 downto 0),
         we      => App_Af_wren,
         q       => address,
         re      => afifo_re,
         empty   => afifo_empty,
         afull   => afifo_afull,
         full    => open,
         aempty  => open,
         count   => open
          );
   
  AF_Almost_Full <= afifo_afull;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        req_pipe        <= (others =>'0');
        afifo_re        <= '0';
      else
        if(afifo_empty = '0') and (req_pipe(0) = '0') then
          afifo_re <= '1';
        else
          afifo_re <= '0';  
        end if;  

        if(npi_addr_ack = '1') then
          req_pipe(0) <= '0';  
        elsif(afifo_empty = '0') then
          req_pipe(0) <= '1';
        end if;

        if(npi_addr_ack = '1') then
          req_pipe(req_pipe'high downto 1) <= (others => '0');
        else  
          req_pipe(req_pipe'high downto 1) <= req_pipe(req_pipe'high-1 downto 0);
        end if;
      end if;
    end if;
  end process;

  npi_addr_req_int  <= req_pipe(req_pipe'high);
  npi_addr_req  <= npi_addr_req_int;
  npi_address   <= address(29 downto 0) & "00"; -- MPMC acepts Byte address, VFBC generates word address
  npi_rnw       <= address(32);

--  GEN_BURST8: if(VFBC_BURST_LENGTH = 8) generate
--    npi_size      <= "0010"; -- 2 = 8cache-line, 4 = 16 dwords, 5 = 32 dwords
--  end generate;
--  GEN_BURST32: if(VFBC_BURST_LENGTH = 32) generate
--    npi_size      <= "0100"; --"0010"; -- 2 = 8cache-line, 4 = 16 dwords, 5 = 32 dwords
--  end generate;
--  GEN_BURST64: if(VFBC_BURST_LENGTH = 64) generate
--    npi_size      <= "0101"; --"0010"; -- 2 = 8cache-line, 4 = 16 dwords, 5 = 32 dwords
--  end generate;
   npi_size      <= "0100"; --"0010"; -- 2 = 8cache-line, 4 = 16 dwords, 5 = 32 dwords

--  process(clk)
--  begin
--    if(rising_edge(clk)) then
--      if(srst = '1') then
--        AF_Almost_Full <= '1';
--      else
--        --if(App_Af_wren = '1') and (npi_addr_ack = '0') then
--        if(req_pipe(req_pipe'high) = '1') and (npi_addr_ack = '0') then
--          AF_Almost_Full <= '1';
--        elsif(npi_addr_ack = '1') then
--          AF_Almost_Full <= '0';
--        elsif(npi_init_done = '1') then
--          AF_Almost_Full <= '0';
--        end if;
--      end if;
--    end if;
--  end process;


  -- Write Interface
--  WDF_Almost_Full       <= '1' when(npi_init_done = '0') else npi_wrfifo_almost_full;
--  npi_wrfifo_data       <= App_WDF_data;
--  npi_wrfifo_be         <= not App_Mask_data;
--  npi_wrfifo_push       <= App_WDF_wren;
--

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        npi_wrfifo_push <= '0';
        wrdata_fifo_afull_d <= '0';
      else
        npi_wrfifo_push <= wrdata_fifo_re;
        wrdata_fifo_afull_d <= wrdata_fifo_afull;
      end if;
    end if;
  end process;

  WDF_Almost_Full       <= '1' when(npi_init_done = '0') else (npi_wrfifo_almost_full or wrdata_fifo_afull_d);
  npi_wrfifo_data       <= wrdata_fifo_q(VFBC_NPI_WIDTH-1 downto 0);
  --npi_wrfifo_be         <= not wrdata_fifo_q(VFBC_NPI_WIDTH/8 - 1 + VFBC_NPI_WIDTH downto VFBC_NPI_WIDTH);
  npi_wrfifo_be         <= (others => '1');

  wrdata_fifo_re        <= (not wrdata_fifo_empty) and (not npi_wrfifo_almost_full);


  
  --wrdata_fifo_reset     <= srst or npi_wrfifo_flush_dly(npi_wrfifo_flush_dly'high);
  wrdata_fifo_reset     <= srst;
  wrdata_fifo_d         <= App_Mask_data & App_WDF_data;
 
   
  wrdata_fifo0: entity work.synch_fifo(rtl)
     generic map (input_reg   => 0, 
                  dwidth      => VFBC_NPI_WIDTH + (VFBC_NPI_WIDTH/8),
                  depth       => 2*VFBC_BURST_LENGTH*32/VFBC_NPI_WIDTH,  -- 2 bursts worth
                  --afull_count => 1, 
                  afull_count => 1 + 3*VFBC_BURST_LENGTH*16/VFBC_NPI_WIDTH, -- 1.5 burst length
                  mem_type    => DIST_RAMSTYLE ) 
     port map (
         clk     => clk,
         sclr    => wrdata_fifo_reset, 
         d       => wrdata_fifo_d,
         we      => App_WDF_wren,
         q       => wrdata_fifo_q,
         re      => wrdata_fifo_re,
         empty   => wrdata_fifo_empty,
         afull   => wrdata_fifo_afull, -- not used we stop before it is full
         full    => open,
         aempty  => open,
         count   => open
          );


  ---------------------------------------------------------------------------
  -- NPI Write FIFO Flush
  ---------------------------------------------------------------------------
--  process(clk)
--  begin
--    if(rising_edge(clk)) then
--      npi_wrfifo_flush_d <= npi_wrfifo_flush_d(npi_wrfifo_flush_d'high-1 downto 0) & wd_flush;
--      npi_wrfifo_reset_d <= npi_wrfifo_reset_d(npi_wrfifo_reset_d'high-1 downto 0) & wd_reset;
--
--      npi_wrfifo_flush   <= npi_wrfifo_flush_d(npi_wrfifo_flush_d'high) or npi_wrfifo_reset_d(npi_wrfifo_reset_d'high);
--    end if;
--  end process;  
  npi_wrfifo_flush   <= '0';



  -- Read Interface
  --vfbc_read_fifo_afull <= '1' when (rd_active_afull /= 0) else '0';
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        vfbc_read_fifo_afull <= '1';
      else
        if(rd_active_afull /= 0) then
          vfbc_read_fifo_afull <= '1';
        else
          vfbc_read_fifo_afull <= '0';
        end if;
      end if;
    end if;
  end process;


  --npi_rdfifo_latency    <= "00"; 
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        Read_data_valid_d1       <= '0';
        Read_data_valid_d2       <= '0';
      else
        Read_data_valid_d1       <= rdfifo_pop;

        if(npi_rdfifo_latency = 2) then
          Read_data_valid_d2 <= Read_data_valid_d1;
        else
          Read_data_valid_d2 <= rdfifo_pop;
        end if;
      end if;
    end if;
  end process;

  Read_data_valid <= rdfifo_pop when(npi_rdfifo_latency = 0) else Read_data_valid_d2;

  rdfifo_pop            <= not npi_rdfifo_empty and not vfbc_read_fifo_afull;
  npi_rdfifo_pop        <= rdfifo_pop;

  Read_data_fifo_out    <= npi_rdfifo_data;


  ---------------------------------------------------------------------------
  -- NPI Read FIFO Flush
  ---------------------------------------------------------------------------
--  process(clk)
--  begin
--    if(rising_edge(clk)) then
--      npi_rdfifo_flush_d <= npi_rdfifo_flush_d(npi_rdfifo_flush_d'high-1 downto 0) & rd_flush;
--      npi_rdfifo_reset_d <= npi_rdfifo_reset_d(npi_rdfifo_reset_d'high-1 downto 0) & rd_reset;
--
--      npi_rdfifo_flush   <= npi_rdfifo_flush_d(npi_rdfifo_flush_d'high) or npi_rdfifo_reset_d(npi_rdfifo_reset_d'high);
--    end if;
--  end process;  
    npi_rdfifo_flush   <= '0';
end rtl;
