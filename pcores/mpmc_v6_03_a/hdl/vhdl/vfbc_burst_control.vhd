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
-- Filename - vfbc_burst_control.vhd
-- Author - , Xilinx
-- Creation - July 25, 2006
--
-- Description - Burst Controller
--               This module cuts each 2D transfer into single bursts.
--               Each burst is selected to be the memory controller 
--               burst size.  For MPMC, the selected burst size is
--               32-word bursts (128 bytes).
--
--*******************************************************************

-- NOTES:
-- 1. Don't need to worry about Bursts that cross page/bank boundaries.
-- 2. Addresses from command do not have to be burst aligned.
--
-- Restrictions: 
-- 1. MEM_BURST_SIZE must be a power of 2
-- 2. Smallest burst size must be 4
--
-- Issues:
-- DONE 1. Problem to solve: write/read to fifos a single word (MSW, LSW) = bit flip dword_masks of "10" and "01"
-- DONE 2. Send updated address back to cmd Fetch - not start address

-- Can add a byte_mask and do the byte maskes the same way as the dword masks.

------------------------------------------------------------------------------
-- Write Pipeline Timing Was:
------------------------------------------------------------------------------
-- Cycle #  DWORD_CNT  WR_SEL  WR_RELEASE(Last) Write_swap      mc_wd_wren  mc_wd_mask_data
--  1        0           0        0             0               0               Previous
--  2        1           1        0             1               0               Previous                      
--  3        2           1        0             1               1               Valid
--  4        3           1        0             1               1               Valid
--  5        3           1        1             1               1               Valid
--  6        3           0        0             0               1               Valid
--  7        3           0        0             0               0               Previous
------------------------------------------------------------------------------
-- Write Pipeline Timing Now:
------------------------------------------------------------------------------
-- Cycle #  DWORD_CNT  WR_SEL  WR_RELEASE(Last) Write_swap      mc_wd_wren  mc_wd_mask_data
--  1        0           0        0             0               0               Previous
--  2        1           0        0             0               0               Previous                      
--  3        2           0        0             0               0               Previous
--  4        3           1        V             1               0               Previous
--  5        3           1        V             1               1               Valid
--  6        3           1        V             1               1               Valid
--  7        3           1        V             1               1               Valid
--  8        3           0        0             0               1               Valid
--  9        3           0        0             0               0               Previous

------------------------------------------------------------------------------
-- Read Pipeline Timing Was:
------------------------------------------------------------------------------
-- Cycle #  DWORD_CNT  RD_SEL  RD_COMMIT(Last)  Read_swap       mc_rd_data_valid(in) rd_byte_mask
--  1        0           0        0                             0                       Previous
--  2        0           0        0                             1                       Previous
--  3        1           0        0                             1                       Previous
--  4        2           1        V                             1                       Valid
--  5        3           1        V                             1                       Valid
--  6        3           1        V                             0                       Valid
--  7        3           1        V                             0                       Valid
--  8        3           0        0                             0                       Previous


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.CONV_STD_LOGIC_VECTOR;

LIBRARY work;
USE work.memxlib_utils.ALL;



entity vfbc_burst_control is
  generic(
    ENABLE_BURST_CUT            : boolean := TRUE; -- Enable Burst Cutting/merging
    NUM_CMD_WORDS_PER_PORT      : integer := 4;    -- Number of Command Words: 2 or 4
    CMD_WIDTH                   : integer := 32;   -- Command Width per word
    NUM_DATA_PORTS              : integer := 8;    -- Number of Data Ports
    READ_FIFO_DEPTH             : integer := 8;    -- Read Address Request FIFO Depth
    DATA_WIDTH                  : integer := 32;   -- Data Width for Byte enables. Not used
    DM_WIDTH                    : integer := 4;    -- Data Mask Width
    BURST_SIZE                  : integer := 8;    -- VFBC Burst Size: Set to 32
    MEM_BURST_SIZE              : integer := 8;    -- Memory Burst Size
    ADDRESS_PASSTHRU            : boolean := TRUE; -- True = Ignore col, row and ba. 
                                                   -- Pass through Address Unchanged
    X_MAX                       : integer := 15;   -- Maximum X size number of bits
    MC_COL_ADDR_WIDTH           : integer := 10;   -- Memory Controller Column Address Width 
    MC_BA_LOC                   : integer := 24;   -- Memory Controller Bank Address bit. col_ap_width + row_address
    BA_SIZE                     : integer := 2;    -- Memory Controller Bank Address Size. 2-bits
    BA_LOC                      : integer := 10    -- External Memory Bank Address bit.

  );
  port(
    -- Common interface
    clk                 : in std_logic;         -- Clock
    srst                : in std_logic;         -- Synchronous Reset
  
    -- Command Buffer Interface
    cbuf_rd_data        : in  std_logic_vector(CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 downto 0); -- Cmd Buffer Current Read Command
                                                                                             -- Words
    cmd_valid           : in  std_logic;                                                     -- New CMD is valid, operate on it
    
    cbuf_wr_addr        : out std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);       -- Cmd Buffer Write Address. Same as
                                                                                             -- curr Port ID 
    cbuf_wr_data        : out std_logic_vector(CMD_WIDTH*NUM_CMD_WORDS_PER_PORT-1 downto 0); -- Cmd Buffer Write Command Words
    cmd_update          : out std_logic;                                                     -- Update Cmd Buffer. To cmd buffer
                                                                                             -- and cmd fetch. Active High

    -- Command Fetch Interface
    cbuf_addr           : in  std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);       -- Current Command Port ID
    cmd_raf_almost_full : out std_logic;                                                     -- Read Request Address FIFO Almost
                                                                                             -- Full. Active High

    cmd_new_addr        : out std_logic_vector(31 downto 0);                                 -- Update includes BA 
                                                                                             -- May not need as it is in the
                                                                                             -- address of the cbuf_wr_data
    cmd_done            : out std_logic;                                                     -- Command Complete.  Active High.
                                                                                             -- Signals end of 2D Transfer
    remaining_x_count   : out std_logic_vector(23 downto 0);                                 -- Number of bytes remaining in
                                                                                             -- current line of transer

    -- WRITE FIFOs Interface
    wr_byte_mask        : in std_logic_vector(NUM_DATA_PORTS*DM_WIDTH*2-1 downto 0);         -- Write FIFOs Byte Mask. Polarity
                                                                                             -- inverted Byte Enables
    wr_sel              : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);                   -- Write FIFOs Select.
                                                                                             -- Write-enables/Pop Write Data
    wr_release          : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);                   -- Write FIFOs Release Write Data.
                                                                                             -- Active High

    -- READ  FIFOs Interface 
    rd_flush            : in std_logic_vector(NUM_DATA_PORTS-1 downto 0);                    -- Read FIFOs Flush. Active High
    rd_byte_mask        : out std_logic_vector(NUM_DATA_PORTS*DM_WIDTH*2-1 downto 0);        -- Read FIFOs Byte Mask.  Mask
                                                                                             -- unaligned bursts
    rd_sel              : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);                   -- Read FIFOs Select.
                                                                                             -- Read-enables/Push Read data
    rd_commit           : out std_logic_vector(NUM_DATA_PORTS-1 downto 0);                   -- Read FIFOs Commit Read data. Active
                                                                                             -- High
 
    -- Memory Controller FIFO Interface
    mc_burst_length     : in std_logic_vector(2 downto 0);              -- NOT USED.Burst length is an output from MIG?

    mc_rd_data_valid    : in std_logic;                                 -- Memory Controller Read Data Valid. Active High

    mc_af_addr          : out std_logic_vector(35 downto 0);            -- Memory Controller Dynamic CMD Req, CS, Bank, Row, Column
    mc_af_wren          : out std_logic;                                -- Memory Controller Address FIFO Write Enable. Active High
                                                                        --        

    mc_wd_mask_data     : out std_logic_vector(DM_WIDTH*2-1 downto 0);  -- Memory Controller Write Data Mask
    mc_wd_wren          : out std_logic;                                -- Memory Controller Write Data Write Enable/Push. Active
                                                                        -- High

    write_swap          : out std_logic;                                -- Write Transfer Swap. Active High denotes swap words for
                                                                        -- address[0]=1
    read_swap           : out std_logic                                 -- Read Transfer Swap. Active High denotes swap words for
                                                                        -- address[0]=1


  );


end vfbc_burst_control;
------------------------------------------------------------------------------
-- RTL Architecture
------------------------------------------------------------------------------
architecture rtl of vfbc_burst_control is
------------------------------------------------------------------------------
-- Functions
------------------------------------------------------------------------------
  function is_4 (
    cmd_width: integer)                     -- inputs
    return integer is
  begin  -- function
    if cmd_width>=4 then 
      return 1;
    else 
      return 0;
    end if;
  end function is_4;

  function is_2 (
    cmd_width: integer)                     -- inputs
    return integer is
  begin  -- function
    if cmd_width<4 then 
      return 1;
    else 
      return 0;
    end if;
  end function is_2;

  function minimum (
    left, 
    right : integer
  )                     -- inputs
    return integer is
  begin  -- function max
    if LEFT < RIGHT then 
      return LEFT;
    else 
      return RIGHT;
    end if;
  end function minimum;

  function maximum (
    left, 
    right : integer
  )                     -- inputs
    return integer is
  begin  -- function max
    if LEFT > RIGHT then 
      return LEFT;
    else 
      return RIGHT;
    end if;
  end function maximum;

------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------
--constant NUM_PORTS      : integer := NUM_WRITE_PORTS + NUM_READ_PORTS;
--
--
--constant X_BIT          : integer :=  0*(is_4(NUM_CMD_WORDS_PER_PORT)) + 24*(is_2(NUM_CMD_WORDS_PER_PORT));
constant BYTES_PER_WORD : integer := DM_WIDTH;

constant X_BIT          : integer :=  0;
constant ADDRESS_BIT    : integer := 32;
constant WRITE_BIT      : integer := 63;
--constant Y_BIT          : integer := 64*(is_4(NUM_CMD_WORDS_PER_PORT)) + 24*(is_2(NUM_CMD_WORDS_PER_PORT));
--constant STRIDE_BIT     : integer := 96*(is_4(NUM_CMD_WORDS_PER_PORT)) + 28*(is_2(NUM_CMD_WORDS_PER_PORT));
constant Y_BIT          : integer := 64; -- not used in Non-rect
constant STRIDE_BIT     : integer := 96; -- not used in Non-rect
constant XOFF_BIT2      : integer := (X_BIT+24)*(is_4(NUM_CMD_WORDS_PER_PORT)) + 28*(is_2(NUM_CMD_WORDS_PER_PORT));
constant XOFF_BIT1      : integer := (STRIDE_BIT+24)*(is_4(NUM_CMD_WORDS_PER_PORT)) + 24*(is_2(NUM_CMD_WORDS_PER_PORT));
constant XOFF_BIT0      : integer := (Y_BIT+24)*(is_4(NUM_CMD_WORDS_PER_PORT)) + 16*(is_2(NUM_CMD_WORDS_PER_PORT));

constant ADDRESS_LENGTH : integer := 31;
--constant X_LENGTH       : integer := 24;
--constant X_LENGTH       : integer := 24*(is_4(NUM_CMD_WORDS_PER_PORT)) + 16*(is_2(NUM_CMD_WORDS_PER_PORT));
constant X_LENGTH       : integer := minimum(24,X_MAX)*(is_4(NUM_CMD_WORDS_PER_PORT)) +
 minimum(16,X_MAX)*(is_2(NUM_CMD_WORDS_PER_PORT));
constant Y_LENGTH       : integer := 24; -- 24*(is_4(NUM_CMD_WORDS_PER_PORT)) + 4*(is_2(NUM_CMD_WORDS_PER_PORT));
constant STRIDE_LENGTH  : integer := 24; -- 24*(is_4(NUM_CMD_WORDS_PER_PORT)) + 4*(is_2(NUM_CMD_WORDS_PER_PORT));

--constant ZEROS          : std_logic_vector(CMD_WIDTH-1 downto 0) := (others => '0');
--constant ZEROS          : std_logic_vector(logbase2(MEM_BURST_SIZE*4-1)-1 downto 0) := (others => '0');
constant ZEROS          : std_logic_vector(logbase2(BURST_SIZE-1)-1 downto 0) := (others => '0');
constant USE_WORD  : integer := (MEM_BURST_SIZE - BURST_SIZE)/32; -- 0 or 1 
constant X_LOWER_SIZE   : integer := 10; --was 7;
constant Y_LOWER_SIZE   : integer := 6; --*(is_4(NUM_CMD_WORDS_PER_PORT)) + 2*(is_2(NUM_CMD_WORDS_PER_PORT));
constant O_LOWER_SIZE   : integer := 10; -- was 6
constant A_LOWER_SIZE   : integer := 6; --*(is_4(NUM_CMD_WORDS_PER_PORT)) + 2*(is_2(NUM_CMD_WORDS_PER_PORT));
------------------------------------------------------------------------------
-- Signals
------------------------------------------------------------------------------
signal address_stage1   : std_logic_vector(ADDRESS_LENGTH-1     downto 0);
signal address_stage2   : std_logic_vector(ADDRESS_LENGTH-1     downto 0);
signal address_out      : std_logic_vector(ADDRESS_LENGTH-1     downto 0);
signal write_stage1     : std_logic;
signal write_out        : std_logic;
signal x_offset_stage1  : std_logic_vector(X_LENGTH-1           downto 0);
signal x_offset_stage2  : std_logic_vector(X_LENGTH-1           downto 0);
signal x_offset_out     : std_logic_vector(X_LENGTH-1           downto 0);
signal x_size_stage2    : std_logic_vector(X_LENGTH-1           downto 0);
signal x_size_stage1    : std_logic_vector(X_LENGTH-1           downto 0);
signal x_size_out       : std_logic_vector(X_LENGTH-1           downto 0);
signal y_size_stage1    : std_logic_vector(Y_LENGTH-1           downto 0);
signal y_size_stage2    : std_logic_vector(Y_LENGTH-1           downto 0);
signal y_size_out       : std_logic_vector(Y_LENGTH-1           downto 0);
signal stride_stage1    : std_logic_vector(STRIDE_LENGTH-1      downto 0);
signal stride_out       : std_logic_vector(STRIDE_LENGTH-1      downto 0);

signal address_lower_next       : std_logic_vector(A_LOWER_SIZE-1 downto 0);
signal a_with_carry             : std_logic_vector(A_LOWER_SIZE downto 0);

signal y_size_lower_next        : std_logic_vector(Y_LOWER_SIZE-1 downto 0);
signal y_with_carry             : std_logic_vector(Y_LOWER_SIZE downto 0);

signal x_offset_lower_next      : std_logic_vector(O_LOWER_SIZE-1 downto 0);
signal x_offset_upper_plus_one  : std_logic_vector(X_LENGTH-O_LOWER_SIZE-1 downto 0);
signal o_with_carry             : std_logic_vector(O_LOWER_SIZE downto 0);

signal x_size_lower_next        : std_logic_vector(X_LOWER_SIZE-1 downto 0);
signal x_size_upper_plus_one    : std_logic_vector(X_LENGTH-X_LOWER_SIZE-1 downto 0);
signal x_with_carry             : std_logic_vector(X_LOWER_SIZE downto 0);

------------------------------------------------------------------------------
signal mc_word_address  : std_logic_vector(ADDRESS_LENGTH-1-logbase2(BYTES_PER_WORD-1+USE_WORD)   downto 0);
signal mc_address       : std_logic_vector(ADDRESS_LENGTH-1-logbase2(BYTES_PER_WORD-1+USE_WORD)-BA_SIZE downto 0);

signal x_size_curr      : std_logic_vector(X_LENGTH-1           downto 0); -- Wire only
signal x_offset_curr    : std_logic_vector(X_LENGTH-1           downto 0); -- Wire only
signal address_curr     : std_logic_vector(ADDRESS_LENGTH-1      downto 0); -- Wire only
signal write_curr       : std_logic;
signal stride_curr      : std_logic_vector(STRIDE_LENGTH-1      downto 0); -- Wire only
signal y_size_curr      : std_logic_vector(Y_LENGTH-1           downto 0); -- Wire only

signal extra_bursts     : std_logic_vector(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)+1 downto 0);
--signal x_size_full      : std_logic_vector(X_LENGTH-1           downto 0);

signal o_carry          : std_logic;
signal x_carry          : std_logic;
signal y_carry          : std_logic;
signal a_carry          : std_logic;
------------------------------------------------------------------------------
signal port_id          : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal port_id_d        : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);

--signal write_release_comb : std_logic;
signal write_release    : std_logic;
signal write_release_d1 : std_logic;
signal write_release_d2 : std_logic;
signal read_commit      : std_logic;

--signal fifo_select      : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
signal fifo_select      : std_logic_vector(2**logbase2(NUM_DATA_PORTS-1) -1     downto 0);
signal write_select     : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
signal read_select      : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
signal read_select_d1   : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
signal read_select_d2   : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
--signal read_port_id_one_hot : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
signal read_port_id_one_hot : std_logic_vector(2**logbase2(NUM_DATA_PORTS-1) -1     downto 0);
signal wr_pop           : std_logic_vector(NUM_DATA_PORTS-1     downto 0);
signal rd_push          : std_logic_vector(NUM_DATA_PORTS-1     downto 0);


signal stage_burst      : std_logic;
signal stage_burst_reg  : std_logic;
signal start_burst      : std_logic;
signal end_burst        : std_logic;
signal command_done     : std_logic;
signal read_command_done: std_logic;

signal first_transfer     : std_logic;
signal last_transfer_comb : std_logic;
signal last_transfer      : std_logic;
signal dword_cnt        : std_logic_vector(logbase2(MEM_BURST_SIZE/2-1) -1 downto 0);

signal last_burst_data_num : std_logic_vector(logbase2(MEM_BURST_SIZE-1)-1 downto 0);
signal data_num         : std_logic_vector(logbase2(MEM_BURST_SIZE-1)-1 downto 0);

signal dword_mask       : std_logic_vector(1 downto 0);
signal dword_mask_dlast : std_logic_vector(1 downto 0);
signal dword_mask_afirst: std_logic_vector(1 downto 0);

signal byte_mask_out    : std_logic_vector(DM_WIDTH*2-1 downto 0);
signal word_address     : std_logic_vector(logbase2(MEM_BURST_SIZE-1)-1 downto 0);

signal add_wren                 : std_logic;
signal mc_rd_data_valid_pulse   : std_logic;
signal rd_id_enable             : std_logic;


signal read_dword_cnt   : std_logic_vector(logbase2(MEM_BURST_SIZE/2-1) -1 downto 0);
signal read_dword_cnt_dly: std_logic_vector(logbase2(MEM_BURST_SIZE/2-1) -1 downto 0);
signal read_save_data_d : std_logic_vector(logbase2(NUM_DATA_PORTS-1) + 2*logbase2(MEM_BURST_SIZE-1)+3 - 1 downto 0);
signal read_save_data   : std_logic_vector(logbase2(NUM_DATA_PORTS-1) + 2*logbase2(MEM_BURST_SIZE-1)+3 - 1 downto 0);

signal read_first_transfer      : std_logic;
signal read_last_transfer       : std_logic;
signal read_port_id             : std_logic_vector(logbase2(NUM_DATA_PORTS-1)-1 downto 0);
signal read_word_address        : std_logic_vector(logbase2(MEM_BURST_SIZE-1)-1 downto 0);
signal read_data_num            : std_logic_vector(logbase2(MEM_BURST_SIZE-1)-1 downto 0);

signal read_dword_mask       : std_logic_vector(1 downto 0);
signal read_dword_mask_dly   : std_logic_vector(1 downto 0);
signal read_dword_mask_dly2  : std_logic_vector(1 downto 0);
signal read_dword_mask_dlast : std_logic_vector(1 downto 0);
signal read_dword_mask_afirst: std_logic_vector(1 downto 0);

signal byte_mask_in     : std_logic_vector(DM_WIDTH*2-1 downto 0);

signal data_wren        : std_logic;
signal data_wren_dly    : std_logic_vector(3 downto 0);
signal read_control_afull : std_logic;
signal rcontrol_write_ptr       : std_logic_vector(logbase2(maximum(2,128/MEM_BURST_SIZE)-1) downto 0);
signal rcontrol_read_ptr        : std_logic_vector(logbase2(maximum(2,128/MEM_BURST_SIZE)-1) downto 0);

signal stage_burst_int : std_logic;
signal stage_burst_int_reg : std_logic;
signal write_swap_words : std_logic_vector(2 downto 0);
signal read_swap_words : std_logic_vector(2 downto 0);
signal advance_one      : std_logic;
--signal burst_cnt        : std_logic_vector(logbase2(BURST_SIZE/(MEM_BURST_SIZE/2)-1)-1 downto 0);
signal burst_cnt        : std_logic_vector(0 downto 0);
signal mc_rd_data_valid_dly : std_logic_vector(3 downto 0);

signal wr_sel_d1, wr_sel_d2 : std_logic_vector(NUM_DATA_PORTS-1 downto 0);
signal mc_wd_mask_data_pre1 : std_logic_vector(DM_WIDTH*2-1 downto 0);
signal mc_wd_mask_data_pre2 : std_logic_vector(DM_WIDTH*2-1 downto 0);
signal read_fifo_reset  : std_logic;

attribute MAX_FANOUT: string; 
attribute MAX_FANOUT of last_transfer_comb: signal is "16";
attribute MAX_FANOUT of command_done: signal is "16";

------------------------------------------------------------------------------
-- Processes and Logic
------------------------------------------------------------------------------
begin
--  process(clk)
--  begin
--    if(rising_edge(clk)) then
--      if(srst = '1') then
--        burst_cnt        <= conv_std_logic_vector(BURST_SIZE/(MEM_BURST_SIZE/2)-1,burst_cnt'length);
--      else
--        if(stage_burst = '1') then
--          burst_cnt      <= conv_std_logic_vector(BURST_SIZE/(MEM_BURST_SIZE/2)-1,burst_cnt'length);
--        elsif(stage_burst_int = '1') then
--          burst_cnt      <= burst_cnt - 1;
--        end if;
--      end if;
--    end if;
--  end process;
   burst_cnt        <= (others => '0');




  ------------------------------------------------------------------------------

  cbuf_wr_addr <= port_id;
  cmd_raf_almost_full <= read_control_afull;
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        port_id    <= (others => '0');
        port_id_d  <= (others => '0');
      else
        port_id_d <= port_id;
        if(stage_burst = '1') then -- only on cmd_valid
          port_id  <= cbuf_addr;
        end if;

      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Fifo Select
  ------------------------------------------------------------------------------
  VFBC_ONEHOT0 : entity work.vfbc_onehot
  generic map(
    WIDTH => logbase2(NUM_DATA_PORTS-1)
  )
  port map(
    S => port_id_d,
    X => fifo_select
  );

  write_select  <= fifo_select(NUM_DATA_PORTS-1 downto 0);

  --wr_sel        <= wr_pop when(dword_mask /= "11") else (others => '0');
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        wr_sel_d1 <= (others => '0');
        wr_sel_d2 <= (others => '0');
      else
        if(dword_mask /= "11") then
          wr_sel_d1 <= wr_pop;
        else
          wr_sel_d1 <= (others => '0');
        end if;
        wr_sel_d2 <= wr_sel_d1;
      end if;
    end if;
  end process;
  wr_sel <= wr_sel_d2;

  rd_sel        <= rd_push; 
  ------------------------------------------------------------------------------
  -- State Machine
  ------------------------------------------------------------------------------
--inputs:
--
--  client side
--  cmd valid
--        cmd counter
--
--  start_address
--  x  size
--  y size
--  stride
--  max burst
--
--  bank size
--
--  memory side:
--  almost full
--
--
--
--outputs:
--
--  address
--  bank address
--  mc address write enable
--      mc data write enable
--      data masks (maybe)
--      mask all
--  done


  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        remaining_x_count <= (others => '0');
      else
        remaining_x_count(X_LENGTH-1 downto 0) <= x_size_stage2 - x_offset_stage2;
      end if;
    end if;
  end process;


  stage_burst <= cmd_valid;
  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        stage_burst_int_reg <= '0';
      else

        if(    (dword_cnt = 1) 
           and (command_done = '0')
           and (burst_cnt /= 0)
          ) then
          stage_burst_int_reg <= '1';
        else
          stage_burst_int_reg <= '0';
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  stage_burst_int <= stage_burst_int_reg;
  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        stage_burst_reg <= '0';
      else
        stage_burst_reg <= stage_burst or stage_burst_int;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  start_burst <= stage_burst_reg;

  ------------------------------------------------------------------------------
  -- address bits
  -- [1:0]                      byte address  
  -- [logbase2(MEM_BURST_SIZE-1)+1:2]   word address

  ------------------------------------------------------------------------------
  -- Combinational Logic for command calc
  ------------------------------------------------------------------------------
  GEN_RECT: if(NUM_CMD_WORDS_PER_PORT = 4) generate
    process(stage_burst,cbuf_rd_data,x_size_out,x_offset_out,write_out,address_out,y_size_out,stride_out)
    begin
      if(stage_burst = '1') then
        x_size_curr   <= cbuf_rd_data(X_LENGTH      -1+X_BIT downto X_BIT);
        x_offset_curr <=  cbuf_rd_data(XOFF_BIT2+X_LENGTH/3-1 downto XOFF_BIT2)
                        & cbuf_rd_data(XOFF_BIT1+X_LENGTH/3-1 downto XOFF_BIT1)
                        & cbuf_rd_data(XOFF_BIT0+X_LENGTH/3-1 downto XOFF_BIT0);
        write_curr    <= cbuf_rd_data(WRITE_BIT);
        address_curr  <= cbuf_rd_data(ADDRESS_LENGTH-1+ADDRESS_BIT downto ADDRESS_BIT);
        y_size_curr   <= cbuf_rd_data(Y_LENGTH      -1+Y_BIT       downto Y_BIT);
        stride_curr   <= cbuf_rd_data(STRIDE_LENGTH -1+STRIDE_BIT  downto STRIDE_BIT);
      else
        x_size_curr   <= x_size_out;
        x_offset_curr <= x_offset_out; 
        write_curr    <= write_out;
        address_curr  <= address_out;
        y_size_curr   <= y_size_out;
        stride_curr   <= stride_out;
      end if;
    end process;
  end generate;

  GEN_NONRECT: if(NUM_CMD_WORDS_PER_PORT = 2) generate
    y_size_curr   <= (others => '0');
    stride_curr   <= (others => '0');

    process(stage_burst,cbuf_rd_data,x_size_out,x_offset_out,write_out,address_out)
    begin
      if(stage_burst = '1') then
        x_size_curr   <= cbuf_rd_data(X_LENGTH      -1+X_BIT downto X_BIT);
        x_offset_curr <= cbuf_rd_data(X_LENGTH      -1+XOFF_BIT0 downto XOFF_BIT0);
        write_curr    <= cbuf_rd_data(WRITE_BIT);
        address_curr  <= cbuf_rd_data(ADDRESS_LENGTH-1+ADDRESS_BIT downto ADDRESS_BIT);
      else
        x_size_curr   <= x_size_out;
        x_offset_curr <= x_offset_out; 
        write_curr    <= write_out;
        address_curr  <= address_out;
      end if;
    end process;
  end generate;

  ------------------------------------------------------------------------------
  x_offset_stage2(X_LENGTH-1 downto O_LOWER_SIZE) <= x_offset_stage1(X_LENGTH-1 downto O_LOWER_SIZE) when o_carry = '0' 
                        else x_offset_upper_plus_one;
  x_offset_stage2(O_LOWER_SIZE-1 downto 0)        <= x_offset_lower_next(O_LOWER_SIZE-1 downto 0);

  y_size_stage2(Y_LENGTH-1 downto Y_LOWER_SIZE)   <= y_size_stage1(Y_LENGTH-1 downto Y_LOWER_SIZE) - y_carry;
  y_size_stage2(Y_LOWER_SIZE-1 downto 0)          <= y_size_lower_next(Y_LOWER_SIZE-1 downto 0);

  x_size_stage2(X_LENGTH-1 downto X_LOWER_SIZE)   <= x_size_stage1(X_LENGTH-1 downto X_LOWER_SIZE) when x_carry = '0'
                        else x_size_upper_plus_one;
  x_size_stage2(X_LOWER_SIZE-1 downto 0)          <= x_size_lower_next(X_LOWER_SIZE-1 downto 0);

  address_stage2(ADDRESS_LENGTH-1 downto A_LOWER_SIZE) <=  address_stage1(ADDRESS_LENGTH-1 downto A_LOWER_SIZE) 
                                                                 + stride_stage1(STRIDE_LENGTH-1 downto A_LOWER_SIZE) 
                                                                 + a_carry;
  address_stage2(A_LOWER_SIZE-1 downto 0)              <= address_lower_next(A_LOWER_SIZE-1 downto 0);

  y_with_carry <= ("0" & y_size_curr(Y_LOWER_SIZE-1 downto 0)) - 1;

  o_with_carry <= ("0" & x_offset_curr(O_LOWER_SIZE-1 downto 0))
                 + (MEM_BURST_SIZE*BYTES_PER_WORD);

  a_with_carry <= ("0" & address_curr(A_LOWER_SIZE-1 downto 0)) + stride_curr(A_LOWER_SIZE-1 downto 0);

  extra_bursts <= ("00" & x_size_curr(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)-1 downto 0))
                 + address_curr(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)-1 downto 0)
                 + (MEM_BURST_SIZE*BYTES_PER_WORD-1);
                 

  x_with_carry(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)-1 downto 0) <= (others => '0');
  -- extra_bursts will be 1 or 2 only for round up
  x_with_carry(x_with_carry'high downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)) 
               <=  ("0" & x_size_curr(X_LOWER_SIZE-1 downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1))) 
                 + extra_bursts(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)+1 downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)); 
                                                                                                                               
  --x_with_carry(x_with_carry'high downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)) 
  --             <=  ("0" & x_size_curr((X_LENGTH+1)/2-1 downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1))) 
  --               + extra_bursts(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)+1 downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)) 
  --               + 1; 


  last_transfer_comb <= '1' when (  x_offset_stage2(x_offset_stage2'high downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)) 
                                  = x_size_stage2(x_size_stage2'high downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1))
                                 ) 
                            else '0';
  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        address_stage1  <= (others => '0');
        address_out     <= (others => '0');
        x_size_stage1   <= (others => '0');
        x_size_out      <= (others => '0');
        x_offset_stage1 <= (others => '0');
        x_offset_out    <= (others => '0');
        y_size_stage1   <= (others => '0');
        y_size_out      <= (others => '0');
        stride_stage1   <= (others => '0');
        stride_out      <= (others => '0');
        write_stage1    <= '0';
        write_out       <= '0';

        y_size_lower_next   <= (others => '0');
        x_size_lower_next   <= (others => '0');
        x_size_upper_plus_one <= conv_std_logic_vector(1,x_size_upper_plus_one'length);
        x_offset_lower_next <= (others => '0');
        x_offset_upper_plus_one <= conv_std_logic_vector(1,x_offset_upper_plus_one'length);
        address_lower_next  <= (others => '0');

        y_carry         <= '0';
        a_carry         <= '0';
        x_carry         <= '0';
        o_carry         <= '0';

        last_transfer       <= '0';
        first_transfer      <= '0';
      else
        if((stage_burst = '1') or (stage_burst_int = '1')) then
          x_size_stage1    <= x_size_curr;
          x_offset_stage1 <= x_offset_curr;
          write_stage1     <= write_curr;
          address_stage1   <= address_curr;
          y_size_stage1    <= y_size_curr;
          stride_stage1    <= stride_curr;

          --o_carry & x_offset_stage1(X_LENGTH/2-1 downto 0)        <= ("0" & x_offset_curr(X_LENGTH/2-1 downto 0))
          o_carry <= o_with_carry(o_with_carry'high);
          x_offset_lower_next <= o_with_carry(O_LOWER_SIZE-1 downto 0);
          x_offset_upper_plus_one <= x_offset_curr(x_offset_curr'high downto O_LOWER_SIZE) + 1;

          --y_carry & y_size_lower_next  <= ("0" & cbuf_rd_data(Y_LENGTH/2-1+Y_BIT downto Y_BIT)) - 1;
          y_carry <= y_with_carry(y_with_carry'high);
          y_size_lower_next <= y_with_carry(Y_LOWER_SIZE-1 downto 0);

          --a_carry & address_lower_next <= ("0" & address_curr((ADDRESS_LENGTH+1)/2-1 downto 0)) +
          -- stride_curr((ADDRESS_LENGTH+1)/2-1 downto 0);
          a_carry <= a_with_carry(a_with_carry'high);
          address_lower_next <= a_with_carry(A_LOWER_SIZE-1 downto 0);
        

          x_size_lower_next(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)-1 downto 0) <= (others => '0');

          -- extra_bursts will be 1 or 2 only for round up
          --x_carry & x_size_lower_next(x_size_lower_next'high downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)) 
          --  <=  ("0" & x_size_curr((X_LENGTH+1)/2-1 downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1))) 
          --    + extra_bursts(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)+1 downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1));
          
          x_carry <= x_with_carry(x_with_carry'high);
          x_size_lower_next(x_size_lower_next'high downto 0) <= x_with_carry(x_size_lower_next'high downto 0);
          x_size_upper_plus_one <= x_size_curr(x_size_curr'high downto X_LOWER_SIZE) + 1;

 
        end if;  

        if(start_burst = '1') then
          write_out     <= write_stage1;
          stride_out    <= stride_stage1;
          x_size_out    <= x_size_stage1;

          if(x_offset_stage1 = 0) then
            first_transfer <= '1';
          else
            first_transfer <= '0';
          end if;


          last_transfer <= last_transfer_comb;

          if(last_transfer_comb = '1') then
            x_offset_out <= (others => '0');
            y_size_out   <= y_size_stage2;
            address_out  <= address_stage2;
          else 
            x_offset_out <= x_offset_stage2;
            y_size_out   <= y_size_stage1;
            address_out  <= address_stage1;
          end if;
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --x_size_full <= x_size + (word_address&"00");
  ------------------------------------------------------------------------------
  cmd_done   <= add_wren and command_done;
  cmd_update <= add_wren and not command_done;
  mc_af_wren <= add_wren;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        data_wren_dly  <= (others => '0');
      else
        data_wren_dly  <= data_wren_dly(data_wren_dly'high-1 downto 0) & data_wren;
      end if;
    end if;
  end process;    
  mc_wd_wren <= data_wren_dly(data_wren_dly'high);


  -- Write X_SIZE out for rect access, or write out the x_offset only
  -- Do not write out the Y size and do not write the stride for 
  -- Non rect access as these are not used.
  GEN_RECT_OUT: if(NUM_CMD_WORDS_PER_PORT = 4) generate

    cbuf_wr_data(Y_LENGTH      -1+Y_BIT           downto Y_BIT)           <= y_size_out; 
    cbuf_wr_data(STRIDE_LENGTH -1+STRIDE_BIT      downto STRIDE_BIT)      <= stride_out; 

    cbuf_wr_data(X_LENGTH/3    -1+XOFF_BIT0    downto XOFF_BIT0)       <= x_offset_out(  X_LENGTH/3-1 downto 0); 
    cbuf_wr_data(X_LENGTH/3    -1+XOFF_BIT1    downto XOFF_BIT1)       <= x_offset_out(2*X_LENGTH/3-1 downto X_LENGTH/3); 
    cbuf_wr_data(X_LENGTH/3    -1+XOFF_BIT2    downto XOFF_BIT2)       <= x_offset_out(  X_LENGTH-1   downto 2*X_LENGTH/3); 
  end generate;
  GEN_NONRECT_OUT: if(NUM_CMD_WORDS_PER_PORT = 2) generate
    cbuf_wr_data(X_LENGTH    -1+XOFF_BIT0    downto XOFF_BIT0)       <= x_offset_out(X_LENGTH-1 downto 0); 
  end generate;


  cbuf_wr_data(X_LENGTH      -1+X_BIT           downto X_BIT) <= x_size_out;

  cbuf_wr_data(ADDRESS_LENGTH-1+ADDRESS_BIT     downto ADDRESS_BIT)     <= address_out;
  cbuf_wr_data(WRITE_BIT)                                               <= write_out;
  

  cmd_new_addr <= '0' & address_out;

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        command_done        <= '0';
      else
        if((stage_burst = '1') or (stage_burst_int = '1')) then
            command_done   <= '0';
        elsif(start_burst = '1') then
          if((y_size_stage1 = 0) and (last_transfer_comb = '1')) then -- Check where in rect we are
            command_done   <= '1';
          end if;
        end if; 
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        last_burst_data_num     <= (others => '0');
      else
        if(start_burst = '1') then
          -- timing Fix moved address_stage1 before reg      
          last_burst_data_num <= x_size_stage1(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)-1 downto logbase2(BYTES_PER_WORD-1))
                                + (x_size_stage1(1) or x_size_stage1(0))  -- update for non word aligned
                                + address_stage1(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)-1 downto logbase2(BYTES_PER_WORD-1)); 
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        word_address <= (others => '0');
      else
        if(start_burst = '1') then
          word_address <= address_stage1(logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)-1 downto logbase2(BYTES_PER_WORD-1));
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        dword_cnt <= (others => '1'); -- Initialize to (MEM_BURST_SIZE/2-1)
        end_burst <= '0';
      else
          if((start_burst = '0') and (dword_cnt = ((MEM_BURST_SIZE/2)-1))) then
            end_burst <= '1';
          else
            end_burst <= '0';
          end if;


          if(dword_cnt < ((MEM_BURST_SIZE/2)-1)) then
            dword_cnt <= dword_cnt + 1;
          elsif(start_burst = '1') then
            dword_cnt <= (others => '0'); -- or burst start address from address
          end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        read_dword_cnt          <= (others => '0'); 
        read_dword_cnt_dly      <= (others => '0'); 
        mc_rd_data_valid_dly    <= (others => '0');
      else
          mc_rd_data_valid_dly <= mc_rd_data_valid_dly(mc_rd_data_valid_dly'high-1 downto 0) & mc_rd_data_valid;

          if(mc_rd_data_valid = '1') then -- look at the current read fifo only 
            read_dword_cnt <= read_dword_cnt + 1;
          end if;

          if(mc_rd_data_valid_dly(1) = '1') then -- look at the current read fifo only 
            read_dword_cnt_dly <= read_dword_cnt_dly + 1;
          end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Write data fifos control
  ------------------------------------------------------------------------------

  WR_POP_MUX0: process(clk)
  begin
    if(rising_edge(clk)) then
      for i in 0 to NUM_DATA_PORTS-1 loop
        if(write_select(i) = '1') then
          wr_pop(i) <= data_wren;
        else
          wr_pop(i) <= '0';
        end if;
      end loop;
    end if;
  end process;

  ------------------------------------------------------------------------------
--  write_release_comb <= '1' when ((write_stage1 = '1') and (dword_cnt = MEM_BURST_SIZE/2-2) and (command_done = '1')) else '0';
--
--  process(clk)
--  begin
--    if(rising_edge(clk)) then
--      if(srst = '1') then
--        wr_release <= (others => '0');
--        write_release <= '0';
--      else
--        write_release <= write_release_comb;
--
--        for i in 0 to NUM_DATA_PORTS-1 loop
--          if(write_select(i) = '1') then
--            wr_release(i) <= write_release;
--          else
--            wr_release(i) <= '0';
--          end if;
--        end loop;
--
--      end if;
--    end if;
--  end process;


  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        wr_release <= (others => '0');
        write_release <= '0';
        write_release_d1 <= '0';
        write_release_d2 <= '0';
      else
        if(    (command_done = '1') 
           and (write_stage1 = '1')
           --and (data_num /= 0)
           --and (data_wren_dly(data_wren_dly'high-2) = '1') 
           and (dword_cnt = (data_num(data_num'high downto 1)-1))
          ) then
          write_release <= '1';
        else
          write_release <= '0';
        end if;
        write_release_d1 <= write_release;
        write_release_d2 <= write_release_d1;


        for i in 0 to NUM_DATA_PORTS-1 loop
          if(write_select(i) = '1') then
            wr_release(i) <= write_release_d1 and not write_release_d2;
          else
            wr_release(i) <= '0';
          end if;
        end loop;

      end if;
    end if;
  end process;


  ------------------------------------------------------------------------------
  -- Read data fifos control
  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        rd_id_enable            <= '0';
      else
          if((start_burst = '1') and (write_stage1 = '0')) then
            rd_id_enable        <= '1';
          else 
            rd_id_enable        <= '0';
          end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        rd_commit <= (others => '0');
        read_commit <= '0';
      else

--        --if((read_dword_cnt_d2 = MEM_BURST_SIZE/2-1) and (read_command_done = '1')) then
        if(    (read_command_done = '1')
           --and (read_data_num /= 0)
           and (mc_rd_data_valid_dly(1) = '1')
           and (read_dword_cnt_dly = (read_data_num(read_data_num'high downto 1)-1))
          ) then
          read_commit <= '1';
        else
          read_commit <= '0';
        end if;

        for i in 0 to NUM_DATA_PORTS-1 loop
          if(read_select_d1(i) = '1') then
--            if(    (read_command_done = '1')
--               --and (read_data_num /= 0)
--               and (read_dword_cnt_dly = read_data_num(read_data_num'high downto 1))
--              ) then
--              rd_commit(i) <= '1';
--            else
--              rd_commit(i) <= '0';
--            end if;


            rd_commit(i) <= read_commit;
          else
            rd_commit(i) <= '0';
          end if;
        end loop;

      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
 
  mc_rd_data_valid_pulse <= '1' when ((mc_rd_data_valid = '1') and (read_dword_cnt = 0)) else '0';


  ------------------------------------------------------------------------------
  read_save_data_d      <= command_done & first_transfer & last_transfer & port_id_d & word_address & data_num;

  read_command_done     <= read_save_data(read_save_data'high);
  read_first_transfer   <= read_save_data(read_save_data'high-1);
  read_last_transfer    <= read_save_data(read_save_data'high-2);
  read_port_id          <= read_save_data(read_save_data'high-3 downto 2*logbase2(MEM_BURST_SIZE-1));
  read_word_address     <= read_save_data(2*logbase2(MEM_BURST_SIZE-1)-1 downto logbase2(MEM_BURST_SIZE-1));
  read_data_num         <= read_save_data(logbase2(MEM_BURST_SIZE-1)-1 downto 0);

  VFBC_ONEHOT1 : entity work.vfbc_onehot
  generic map(
    WIDTH => logbase2(NUM_DATA_PORTS-1)
  )
  port map(
    S => read_port_id,
    X => read_port_id_one_hot
  );


  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        read_select_d1 <= (others => '0');
        read_select_d2 <= (others => '0');
      else
        read_select_d1 <= read_port_id_one_hot(NUM_DATA_PORTS-1 downto 0);
        read_select_d2 <= read_select_d1;
      end if;
    end if;
  end process;

  read_select <= read_select_d2;

  -- May take up too much resources.. May create the logic for this
  -- May need fifo to be at least 24/(MEM_BURST_SIZE/2) deep.  This is the number of cycles between the address and data
  -- Needs to be a power of two deep (= 32 for now).
   --BIDI read_fifo_reset <= '1' when ((srst = '1') or (rd_flush /= 0)) else '0';
   read_fifo_reset <= '1' when ((srst = '1') or (rd_flush(0) /= '0')) else '0';

   READPORT_SEL_FIFO0 : entity work.synch_fifo(rtl)
     generic map (input_reg   => 1, 
                  dwidth      => logbase2(NUM_DATA_PORTS-1) + 2*logbase2(MEM_BURST_SIZE-1) + 3,
                  --depth       => maximum(2,256/(MEM_BURST_SIZE/4)), --maximum(2,32/(MEM_BURST_SIZE/4)),
                  --depth       => READ_FIFO_DEPTH,
                  depth       => 8,
                  --afull_count => BURST_SIZE,--maybe should be BURST_SIZE/(MEM_BURST_SIZE/2)
                  afull_count => 2, --2,--maybe should be BURST_SIZE/(MEM_BURST_SIZE/2)
                  mem_type    => DIST_RAMSTYLE ) -- BLOCK_RAMSTYLE=no_rw_check, DIST_RAMSTYLE=select_ram, registers
     port map (
         clk     => clk,
         sclr    => read_fifo_reset, --srst,
         d       => read_save_data_d,
         re      => mc_rd_data_valid_pulse,
         q       => read_save_data,
         we      => rd_id_enable,
         afull   => read_control_afull,
         empty   => open,
         full    => open,
         aempty  => open,
         count   => open
          );


  ------------------------------------------------------------------------------
  RD_PUSH_MUX_COMB0: process(read_select, mc_rd_data_valid_dly, read_dword_mask)
  begin
      for i in 0 to NUM_DATA_PORTS-1 loop
        if(read_select(i) = '1') then
          if(read_dword_mask /= "11") then
            rd_push(i) <= mc_rd_data_valid_dly(mc_rd_data_valid_dly'high); --mc_rd_data_valid; -- May need to delay valid by one
                                                                                               -- cycle
          else
            rd_push(i) <= '0';
          end if;

        else
          rd_push(i) <= '0';
        end if;
      end loop;
  end process;
  

  ------------------------------------------------------------------------------
  -- memory controller control
  ------------------------------------------------------------------------------
  mc_word_address <= (address_stage1(address_stage1'high downto logbase2(MEM_BURST_SIZE*BYTES_PER_WORD-1)) &
   ZEROS(logbase2(BURST_SIZE-1)-1 downto 0)) 
             + x_offset_stage1(x_offset_stage1'high downto logbase2(BYTES_PER_WORD-1+USE_WORD)); -- was x_offset_stage1

  mc_address <= mc_word_address(mc_word_address'high downto BA_LOC+BA_SIZE) & mc_word_address(BA_LOC-1 downto 0);

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        add_wren        <= '0';
        mc_af_addr      <= (others => '0');
      else

        if(start_burst = '1') then -- Load address
          -- chip select, bank address, row address, col address -- need to calc
          -- 432 10 
          -- 000 00
          --mc_af_addr(30 downto 0)  <=   (cmd_address(cmd_address'length-1 downto 2 + logbase2(MEM_BURST_SIZE-1)) & "00000") 
          --                            + cmd_x_offset;
          -- Word Address
          if(ADDRESS_PASSTHRU) then
            mc_af_addr(mc_word_address'high downto 0)             <= mc_word_address;
          else
            mc_af_addr(MC_BA_LOC+BA_SIZE-1 downto MC_BA_LOC)      <= mc_word_address(BA_LOC+BA_SIZE-1 downto BA_LOC);
            mc_af_addr(MC_COL_ADDR_WIDTH-1 downto 0)              <= mc_address(MC_COL_ADDR_WIDTH-1 downto 0);
            mc_af_addr(MC_BA_LOC-1 downto MC_COL_ADDR_WIDTH+1)    <= mc_address(MC_BA_LOC-2 downto MC_COL_ADDR_WIDTH);
          end if;
                                     
        end if;

        if(start_burst = '1') then
          add_wren              <= '1';

          if(write_stage1 = '1') then
            mc_af_addr(34 downto 32) <= "100"; -- command: read/write, load mode, precharge, refresh, Activate
          else
            mc_af_addr(34 downto 32) <= "101"; -- command: read/write, precharge, refresh, etc
          end if;
        else
          add_wren <= '0';
        end if;

      end if;
    end if;
  end process;

  process(write_out, end_burst)
  begin
        if((write_out = '1') and (end_burst = '0')) then
          data_wren <= '1';
        else
          data_wren <= '0';
        end if;
  end process;

  ------------------------------------------------------------------------------



  ------------------------------------------------------------------------------
  -- Fix for size of transfer for first burst
  -- if address is non-burst aligned 
  -- and if the data length is less than the burst length
  ------------------------------------------------------------------------------
  --data_num <= last_burst_data_num + word_address;
  data_num <= last_burst_data_num;
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
            -- dword_mask 
            --         dword_cnt
            --LDNUM-   00 01 10 11
            ----------------------------------
            -- 000 -   00 00 00 00 
            -- 001 -   01 11 11 11 
            -- 010 -   00 11 11 11 
            -- 011 -   00 01 11 11 
            -- 100 -   00 00 11 11 
            -- 101 -   00 00 01 11 
            -- 110 -   00 00 00 11 
            -- 111 -   00 00 00 01 



  --DWORD_MASK_COMB0: process(dword_cnt, data_num, last_transfer)
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        dword_mask_dlast <= (others => '0');
      else
        --if(x_offset_curr >= x_size_full) then -- if on last transfer per line
        if((last_transfer = '1') and (data_num /= 0)) then -- if on last transfer per line
            if(dword_cnt = data_num(data_num'high downto 1)) then
              if(data_num(0) = '0') then
                dword_mask_dlast <= "11";
              else
                dword_mask_dlast <= "01";
              end if;      
            elsif(dword_cnt < data_num(data_num'high downto 1)) then
              dword_mask_dlast <= "00";
            else
              dword_mask_dlast <= "11";
            end if;
        else
          dword_mask_dlast <= "00";
        end if;
      end if;
    end if;
  end process;

            -- dword_mask 
            --         dword_cnt
            --WDADD-   00 01 10 11
            ----------------------------------
            -- 000 -   00 00 00 00 
            -- 001 -   10 00 00 00 
            -- 010 -   11 00 00 00 
            -- 011 -   11 10 00 00 
            -- 100 -   11 11 00 00 
            -- 101 -   11 11 10 00 
            -- 110 -   11 11 11 00 
            -- 111 -   11 11 11 10 


  --DWORD_MASK_COMB1: process(dword_cnt, word_address, first_transfer)
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        dword_mask_afirst <= (others => '0');
      else
        --if(x_offset_curr = (MEM_BURST_SIZE*4)) then -- if on first transfer per line
        if(first_transfer = '1') then -- if on first transfer per line
            if(dword_cnt = word_address(word_address'high downto 1)) then
              if(word_address(0) = '0') then
                dword_mask_afirst <= "00";
              else
                dword_mask_afirst <= "10";
              end if;      
            elsif(dword_cnt < word_address(word_address'high downto 1)) then
              dword_mask_afirst <= "11";
            else
              dword_mask_afirst <= "00";
            end if;
        else
          dword_mask_afirst <= "00";
        end if;
      end if;
    end if;
  end process;


  dword_mask <= dword_mask_afirst or dword_mask_dlast;

  ------------------------------------------------------------------------------
  -- Swap Write words
  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      write_swap_words <= write_swap_words(write_swap_words'high-1 downto 0) & word_address(0);
    end if;
  end process;

  write_swap <= write_swap_words(write_swap_words'high);
  ------------------------------------------------------------------------------
--  MASK_MUX_COMB0: process(write_select, wr_byte_mask)
--  begin
--      for i in 0 to NUM_DATA_PORTS-1 loop
--        if(write_select(i) = '1') then
--          byte_mask_out <= wr_byte_mask(DM_WIDTH*2*(i+1)-1 downto DM_WIDTH*2*i);
--        end if;
--      end loop;
--      if(write_select = 0) then
--        byte_mask_out <= (others => '1'); -- Mask all other ports
--      end if;
--  end process;

  MASK_MUX_COMB0: process(write_select, wr_byte_mask)
  begin
      if(write_select(1) = '1') then
        byte_mask_out <= wr_byte_mask(DM_WIDTH*2*(1+1)-1 downto DM_WIDTH*2*1);
      else
        byte_mask_out <= (others => '1'); -- Mask all other ports
      end if;
  end process;

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        mc_wd_mask_data_pre1 <= (others => '0');
        --mc_wd_mask_data_pre2 <= (others => '0');
        mc_wd_mask_data      <= (others => '0');
      else
        --mc_wd_mask_data_pre2 <= mc_wd_mask_data_pre1;
        --mc_wd_mask_data      <= mc_wd_mask_data_pre2;
        mc_wd_mask_data      <= mc_wd_mask_data_pre1;

        if(dword_mask(1) = '1') then
          mc_wd_mask_data_pre1(DM_WIDTH-1 downto 0) <= (others => '1');
        else
          mc_wd_mask_data_pre1(DM_WIDTH-1 downto 0) <= byte_mask_out(DM_WIDTH-1 downto 0);
        end if;

        if(dword_mask(0) = '1') then
          mc_wd_mask_data_pre1(DM_WIDTH*2-1 downto DM_WIDTH) <= (others => '1');
        else
          mc_wd_mask_data_pre1(DM_WIDTH*2-1 downto DM_WIDTH) <= byte_mask_out(DM_WIDTH*2-1 downto DM_WIDTH);
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
            -- dword_mask 
            --         dword_cnt
            --LDNUM-   00 01 10 11
            ----------------------------------
            -- 000 -   00 00 00 00 
            -- 001 -   01 11 11 11 
            -- 010 -   00 11 11 11 
            -- 011 -   00 01 11 11 
            -- 100 -   00 00 11 11 
            -- 101 -   00 00 01 11 
            -- 110 -   00 00 00 11 
            -- 111 -   00 00 00 01 

  READ_DWORD_MASK_COMB0: process(read_dword_cnt_dly, read_data_num, read_last_transfer)
  begin

    if((read_last_transfer = '1') and (read_data_num /= 0)) then -- if on last transfer per line
        if(read_dword_cnt_dly = read_data_num(read_data_num'high downto 1)) then
          if(read_data_num(0) = '0') then
            read_dword_mask_dlast <= "11";
          else
            read_dword_mask_dlast <= "01";
          end if;      
        elsif(read_dword_cnt_dly < read_data_num(read_data_num'high downto 1)) then
          read_dword_mask_dlast <= "00";
        else
          read_dword_mask_dlast <= "11";
        end if;
    else
      read_dword_mask_dlast <= "00";
    end if;
  end process;

            -- dword_mask 
            --         dword_cnt
            --WDADD-   00 01 10 11
            ----------------------------------
            -- 000 -   00 00 00 00 
            -- 001 -   10 00 00 00 
            -- 010 -   11 00 00 00 
            -- 011 -   11 10 00 00 
            -- 100 -   11 11 00 00 
            -- 101 -   11 11 10 00 
            -- 110 -   11 11 11 00 
            -- 111 -   11 11 11 10 


  READ_DWORD_MASK_COMB1: process(read_dword_cnt_dly, read_word_address, read_first_transfer)
  begin

    if(read_first_transfer = '1') then -- if on first transfer per line
        if(read_dword_cnt_dly = read_word_address(read_word_address'high downto 1)) then
          if(read_word_address(0) = '0') then
            read_dword_mask_afirst <= "00";
          else
            read_dword_mask_afirst <= "10";
          end if;      
        elsif(read_dword_cnt_dly < read_word_address(read_word_address'high downto 1)) then
          read_dword_mask_afirst <= "11";
        else
          read_dword_mask_afirst <= "00";
        end if;
    else
      read_dword_mask_afirst <= "00";
    end if;
  end process;



  process(clk)
  begin
    if(rising_edge(clk)) then
      if(srst = '1') then
        read_dword_mask_dly <= (others => '0');
        read_dword_mask_dly2 <= (others => '0');
      else
        read_dword_mask_dly  <= read_dword_mask_afirst or read_dword_mask_dlast;
        read_dword_mask_dly2 <= read_dword_mask_dly;

      end if;
    end if;
  end process;

  read_dword_mask <= read_dword_mask_dly2;

--  read_dword_mask <= read_dword_mask_afirst or read_dword_mask_dlast;

  ------------------------------------------------------------------------------
  -- Swap read words
  ------------------------------------------------------------------------------
  read_swap <= read_word_address(0);

  ------------------------------------------------------------------------------
  --READ_BYTE_MASK_COMB0: process(read_dword_mask)
  process(clk)
  begin
    if(rising_edge(clk)) then
        if(read_dword_mask(1) = '1') then
          byte_mask_in(DM_WIDTH-1 downto 0) <= (others => '1');
        else
          byte_mask_in(DM_WIDTH-1 downto 0) <= (others => '0');
        end if;

        if(read_dword_mask(0) = '1') then
          byte_mask_in(DM_WIDTH*2-1 downto DM_WIDTH) <= (others => '1');
        else
          byte_mask_in(DM_WIDTH*2-1 downto DM_WIDTH) <= (others => '0');
        end if;
    end if;
  end process;
  ------------------------------------------------------------------------------
  --READ_MASK_MUX_COMB0: process(read_select, byte_mask_in)
  process(clk)
  begin
    if(rising_edge(clk)) then
      for i in 0 to NUM_DATA_PORTS-1 loop
        if(read_select(i) = '1') then
          rd_byte_mask(DM_WIDTH*2*(i+1)-1 downto DM_WIDTH*2*i) <= byte_mask_in;
        else 
          rd_byte_mask <= (others => '1'); -- Mask all other ports
        end if;
      end loop;
    end if;  
  end process;

end rtl;
