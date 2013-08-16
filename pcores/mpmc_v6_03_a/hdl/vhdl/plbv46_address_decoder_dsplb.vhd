-------------------------------------------------------------------------------
-- plbv46_address_decoder_dsplb.vhd - entity/architecture pair
-------------------------------------------------------------------------------
-- (c) Copyright 2007 - 2009 Xilinx, Inc. All rights reserved.
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
-------------------------------------------------------------------------------
-- Filename:        address_decoder_dsplb.vhd
-- Version:         v1.00a
-- Description:     PLB Slave control module for interface to MPMC
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Structure:
--                 PLB - Full Up - Singles, Cacheline, and Bursts
--                   -- plbv46_pim.vhd
--                      --addr_decoder.vhd
--                         --sample_cycle.vhd
--                      --write_module.vhd
--                      --rd_support.vhd
--                         --data_steer_mirror.vhd
-------------------------------------------------------------------------------
--                 DPLB
--                   -- plbv46_pim.vhd
--                      --addr_decoder_dsplb.vhd
--                         --sample_cycle.vhd
--                      --write_module.vhd
--                      --rd_support_dsplb.vhd
--                         --data_steer_mirror.vhd
-------------------------------------------------------------------------------
--                 IPLB
--                   -- plbv46_pim.vhd
--                      --addr_decoder_isplb.vhd
--                         --sample_cycle.vhd
--                      --write_module.vhd
--                      --rd_support_isplb.vhd
--                         --data_steer_mirror.vhd
-------------------------------------------------------------------------------
--                 PLB - Single
--                   Single
--                   -- plbv46_pim.vhd
--                      --addr_decoder_single.vhd
--                         --sample_cycle.vhd
--                      --write_module.vhd
--                      --rd_support_single.vhd
--                         --data_steer_mirror.vhd
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          MW
--
-- History:
--       MW        01/10/2007   - Initial Version
--
--       MW        04/16/2007   - Initial Version
-- ~~~~~~
--       - Added Pi2ad_InitDone
-- ^^^^^^
--
--       MW        04/27/2007   - Initial Version
-- ~~~~~~
--       - Added SA_Valid
-- ^^^^^^
--
--       MW        05/15/2007   - Initial Version
-- ~~~~~~
--       - Added 32 bit pim support
-- ^^^^^^
--
--       MW        05/24/2007   - Initial Version
-- ~~~~~~
--       - Changed from High Order Address Substituition to address adder
-- ^^^^^^
--
--       MW        06/21/2007   - Initial Version
-- ~~~~~~
--       - Added fix for multi-cycle path on Pi2ad_InitDone_reg2
-- ^^^^^^
--
--
--       MW        06/22/2007   - Initial Version
-- ~~~~~~
--       - Changed C_PLBV46_PIM_TYPE parameters from PLB, DSPLB, ISPLB
--          to PLB, DPLB, IPLB
-- ^^^^^^
--
--       MW        06/26/2007   - Initial Version
-- ~~~~~~
--       - Made changes to meet 200MHz in V4 -12 part and 150MHz in V4 -10 part
--          -  Added address_hit signal to register output of address comparator
--          -  Added addr_rd_busy_sm_reg to delay rd_new_cmd one cycle
--             rddack was occuring one cycle to early on sa_valid reads
--             ( in sa_rd_xfer_type state)
--          -  Sl_rearbitrate is actively driven when P2P=0
--                Sl_rearbitrate is tied LOW when P2P=1
-- ^^^^^^
--
--     MW      07/02/2007    Initial
-- ~~~~~~
--     - Added Ad2rd_queue_data to hold off read pops until sa_valid address
--       is promoted to pa_valid and address decoder addracks
-- ^^^^^^
--
--     MW      07/05/2007    Initial
-- ~~~~~~
--     - Added pipeline register and logic for sl_addrack and sl_rearbitrate
--     - Put in logic to actively drive sl_rearbitrate when P2P=0
-- ^^^^^^
--
--     MW      07/12/2007    Initial
-- ~~~~~~
--     - Added pipeline register to signal rd2ad_rd_cmplt for timing errors
--       since this signal drove comb logic in state machine
-- ^^^^^^
--
--     MW      07/17/2007    Initial
-- ~~~~~~
--     - Made change to use sl_addrack_reg2 to filter false sl_rearbitrate
-- ^^^^^^
--
--     MW      07/31/2007    Initial
-- ~~~~~~
--     - Registered SL_Ssize
-- ^^^^^^
--
--     MW      08/02/2007    Initial
-- ~~~~~~
--     - Change to use 2x pipelined resets form sample_cycle circuit for timing.
-- ^^^^^^
--
--     MW      08/07/2007    Initial
-- ~~~~~~
--     - Added logic to use sl_wait when P2P=1 and sl_reabitrate when P2P=0
-- ^^^^^^
--
--       MW        08/27/2007   - Initial Version
-- ~~~~~~
--       - Added Ad2rd_clk_ratio_1_1 to port
-- ^^^^^^
--
--       MW        12/09/2007   - Initial Version
-- ~~~~~~
--       - Removed unnecessary logic based upon code coverage analysis
--          - DPLB will only support a 64bit PLB Master on a 64bit PLB Bus
--             with a 64bit NPI in a P2P configuration.  No other configuration
--             is allowed.  No other master sizes, plb bus sizes, or NPI widths
--             are supported.  The shared configuration is not supported either.
-- ^^^^^^
--
--       MW        01/22/2008   - Initial Version
-- ~~~~~~
--       - Made changes to increase read throughput
--          From idle state can get to sa state with sl_rearb_reg = '0'
-- ^^^^^^
--
--     MW      06/05/2008    plbv46_pim_v2_02_a - Release 11 
-- ~~~~~~
--    -  Removed dependancies on proc_common
-- ^^^^^^
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library mpmc_v6_03_a;
use mpmc_v6_03_a.all;


entity plbv46_address_decoder_dsplb is
   generic(

      --PLB to PIM generics
      C_SPLB_DWIDTH                 : integer range 32 to 128 := 64;
      C_SPLB_NATIVE_DWIDTH          : integer range 32 to 128 := 64;
      C_SPLB_AWIDTH                 : integer                 := 32;
      C_SPLB_NUM_MASTERS            : integer range 1 to 16   := 8;
      C_SPLB_MID_WIDTH              : integer range 0 to 4    := 3;
      C_SPLB_P2P                    : integer range 0 to 1    := 0;
      C_SPLB_SUPPORT_BURSTS         : integer range 0 to 1    := 0;
      C_SPLB_SMALLEST_MASTER        : integer range 32 to 128 := 128;

      C_PLBV46_PIM_TYPE             : string                  := "PLB";
                                             --PLB,DPLB,IPLB
      --MPMC generics
      C_MPMC_PIM_BASEADDR           : std_logic_vector        := x"00000000";
      C_MPMC_PIM_HIGHADDR           : std_logic_vector        := x"FFFFFFFF";
      C_MPMC_PIM_OFFSET             : std_logic_vector        := x"00000000";
      C_MPMC_PIM_DATA_WIDTH         : integer                 := 64;
      C_MPMC_PIM_ADDR_WIDTH         : integer                 := 32;
      C_MPMC_PIM_RDFIFO_LATENCY     : integer                 := 0;
      C_MPMC_PIM_RDWDADDR_WIDTH     : integer                 := 4;
      C_MPMC_PIM_SDR_DWIDTH         : integer range 8 to 128  := 128;
      C_MPMC_PIM_MEM_HAS_BE         : integer range 0 to 1    := 1;

      --Misc Generics
      C_FAMILY                      : string               := "virtex5"
             );
         port (
         -- System signals ----------------------------------------------------
            Splb_Clk                : in    std_logic;
            Splb_Rst                : in    std_logic;
            Pi_Clk                  : in    std_logic;
            Pi_rst                  : in    std_logic;

            sync_rst                : out   std_logic;
            sync_mpmc_rst           : out   std_logic;
            sync_plb_rst            : out   std_logic;

         -- PLB signals -------------------------------------------------------
            Plb_ABus                : in    std_logic_vector
                                                (0 to C_SPLB_AWIDTH-1);
            Plb_PAValid             : in    std_logic;
            Plb_SAValid             : in    std_logic;
            Plb_masterID            : in    std_logic_vector
                                                (0 to C_SPLB_MID_WIDTH-1);

            Plb_MSize               : in    std_logic_vector (0 to 1);
            Plb_size                : in    std_logic_vector (0 to 3);
            Plb_type                : in    std_logic_vector (0 to 2);

            Plb_RNW                 : in    std_logic;
            Plb_BE                  : in    std_logic_vector
                                             (0 to (C_SPLB_DWIDTH/8)-1);
            Plb_wrBurst             : in    std_logic;
            Plb_rdBurst             : in    std_logic;

         -- PLB Slave Response Signals
            Sl_addrAck              : out   std_logic;
            Sl_SSize                : out   std_logic_vector (0 to 1);
            Sl_wait                 : out   std_logic;
            Sl_rearbitrate          : out   std_logic;
            Sl_MBusy                : out   std_logic_vector
                                             (0 to C_SPLB_NUM_MASTERS-1);

         -- PIM Interconnect port signals -------------------------------------
            Pi2ad_InitDone          : in    std_logic;
            Pi2ad_AddrAck           : in    std_logic;
            Pi2ad_wrfifo_almostFull : in    std_logic;
            Pi2ad_wrFifo_empty      : in    std_logic;
            Ad2pi_Addr              : out   std_logic_vector
                                             (0 to C_MPMC_PIM_ADDR_WIDTH-1);
            Ad2pi_AddrReq           : out   std_logic;
            Ad2pi_RNW               : out   std_logic;
            Ad2pi_Size              : out   std_logic_vector(3 downto 0);

         -- Read Support Module signals ---------------------------------------
            Rd2ad_rd_cmplt          : in    std_logic;
            Rd2ad_rd_Data_cmplt     : in    std_logic;
            Rd2ad_busy              : in    std_logic;
            Rd2Ad_Rd_Error          : in    std_logic;

            Ad2rd_plb_npi_sync      : out   std_logic;
            Ad2rd_new_cmd           : out   std_logic;
            Ad2rd_mid               : out   std_logic_vector
                                                (0 to C_SPLB_MID_WIDTH-1);

            Ad2rd_strt_addr         : out   std_logic_vector
                                               (0 to C_SPLB_AWIDTH-1);
            Ad2rd_single            : out   std_logic;
            Ad2rd_cacheline_4       : out   std_logic;
            Ad2rd_cacheline_8       : out   std_logic;
            Ad2rd_burst_16          : out   std_logic;
            Ad2rd_burst_32          : out   std_logic;
            Ad2rd_burst_64          : out   std_logic;

            Ad2rd_xfer_wdcnt        : out   std_logic_vector
                                      (0 to 7);
            Ad2rd_xfer_width        : out   std_logic_vector(0 to 1);
            Ad2rd_queue_data        : out   std_logic;
            Ad2Rd_clk_ratio_1_1     : out   std_logic;

         -- Write Support Module signals --------------------------------------
            Wr2ad_block_infifo      : in    std_logic;
            Wr2ad_wr_cmplt          : in    std_logic;
            Wr2ad_busy              : in    std_logic;
            Wr2ad_error             : in    std_logic;

            Ad2wr_plb_npi_sync      : out   std_logic;
            Ad2wr_new_cmd           : out   std_logic;
            Ad2wr_mid               : out   std_logic_vector
                                                (0 to C_SPLB_MID_WIDTH-1);
            Ad2wr_strt_addr         : out   std_logic_vector
                                                (0 to C_SPLB_AWIDTH-1);
            Ad2wr_single            : out   std_logic;
            Ad2wr_cacheline_4       : out   std_logic;
            Ad2wr_cacheline_8       : out   std_logic;
            Ad2wr_burst_16          : out   std_logic;
            Ad2wr_burst_32          : out   std_logic;
            Ad2wr_burst_64          : out   std_logic;
            Ad2wr_wrbe              : out   std_logic_vector
                                                (0 to C_MPMC_PIM_DATA_WIDTH/8-1);
            Ad2wr_xfer_wrdcnt       : out   std_logic_vector
                                      (0 to 7);

            Ad2wr_xfer_width        : out   std_logic_vector(0 to 1);
            Ad2Wr_clk_ratio_1_1     : out   std_logic;


         -- ECC signals -----------------------------------------
            Ad2pi_RdModWr           : out   std_logic
        );
   end plbv46_address_decoder_dsplb;


Architecture RTL of plbv46_address_decoder_dsplb is


-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
   -- Constants for setting rdmodwr
--   constant xwc_msb : integer := (NUM_WORD_BITS - 1);
   constant xwc_msb : integer := (C_MPMC_PIM_DATA_WIDTH/8 + 1);

   ----------------------------------------------------------------------------
   -- Signal Declarations
   ----------------------------------------------------------------------------
   -- PLB support signals
   signal   plb_abus_i             : std_logic_vector
                                      (0 to C_SPLB_AWIDTH-1);

   signal   pa_active              : std_logic;
   signal   sa_active              : std_logic;

   signal   plb_mid_i              : std_logic_vector
                                      (0 to C_SPLB_MID_WIDTH-1);

   signal   plb_mid_rd_i           : std_logic_vector
                                      (0 to C_SPLB_MID_WIDTH-1);

   signal   plb_mid_wr_i           : std_logic_vector
                                      (0 to C_SPLB_MID_WIDTH-1);

   signal   plb_rnw_i              : std_logic;

   signal   plb_be_i               : std_logic_vector
                                      (0 to (C_SPLB_DWIDTH/8)-1);

   signal   plb_msize_i            : std_logic_vector(0 to 1);
      --  00 -  32 bit
      --  01 -  64 bit
      --  10 - 128 bit
      --  11 - 256 bit

   signal   plb_size_i             : std_logic_vector(0 to 3);
      --Supported Modes
      -- 0000    Transfer 1-4 bytes of a word starting at the target address
      -- 0001    Transfer the 4-word line containing the target word.
      -- 0010    Transfer the 8-word line containing the target word.
         -- See pg27 of the IBM 128-bit Processor Local Bus Interface
         --    Version 4.6 (CoreConnect TM)
         -- for additional notes, and unsupported modes.

   signal   plb_type_i             : std_logic_vector(0 to 2);
      -- 000    Memory Transfer
         -- See pg27 of the IBM 128-bit Processor Local Bus Interface
         --    Version 4.6 (CoreConnect TM)
         -- for additional notes, and unsupported modes.

   signal   sl_addrack_i           : std_logic;
   signal   sl_addrack_reg         : std_logic;
   signal   sl_addrack_reg2        : std_logic;
   signal   wait_2clks             : std_logic;

   signal   sl_mbusy_i             : std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);
   signal   sl_rd_mbusy_i          : std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);
   signal   sl_wr_mbusy_i          : std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);

--   signal   sl_prm_mbusy_i         : std_logic_vector
--                                       (0 to C_SPLB_NUM_MASTERS-1);
   signal   sl_prm_rd_mbusy_i         : std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);
   signal   sl_prm_wr_mbusy_i         : std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);


   signal   addr_wr_busy           : std_logic;
   signal   wr2ad_busy_reg         : std_logic;
   signal   addr_wr_busy_pre       : std_logic;
--   signal   rd2ad_rd_cmplt_reg     : std_logic;
   signal   addr_rd_busy           : std_logic;
   signal   addr_rd_busy_sm        : std_logic;
--   signal   addr_rd_busy_sm_reg    : std_logic;
--   signal   addr_rd_busy_tg        : std_logic;
   signal   rd_support_busy        : std_logic;
   signal   master_id              : integer range 0 to 16;
   signal   master_id_rd           : integer range 0 to 16;
   signal   master_id_wr           : integer range 0 to 16;

   signal   valid_size             : std_logic;
   signal   valid_plb_type         : std_logic;
   signal   valid_request          : std_logic;

   -- Address Decoder State Machine Signals
   type    addr_statetype          is (idle,
                                       wait_wr_cmplt,
                                       pa_rd_xfer_type,
                                       wait_pa_rdsngl_addrack,
                                       sa_rd_xfer_type,
                                       wait_sa_rdsngl_addrack,
                                       wait_rd2ad_rd_cmplt,
                                       wait_wr_sngl_ack,
                                       initiate_single_wr,
                                       initiate_inbndry_wr);
   signal  addr_cs,addr_ns         : addr_statetype;

   signal   tb0_en                 : std_logic;

   signal   rnw_tb0_q              : std_logic;

   signal   wr_new_cmd             : std_logic;
   signal   rd_new_cmd             : std_logic;
   signal   rd_new_cmd_set         : std_logic;
   signal   rd_new_cmd_clr         : std_logic;
   signal   rd_new_cmd_reg_flag    : std_logic;

   signal   rearb_wr               : std_logic;
   signal   rearb_rd               : std_logic;
   signal   sl_rearb_i             : std_logic;
   signal   sl_rearb_reg           : std_logic;

   signal   pa_address             : std_logic_vector(0 to 31);
   signal   sa_address             : std_logic_vector(0 to 31);
   signal   address_hit            : std_logic;
   signal   addr_equal_i           : std_logic;
   
   signal   wr_new_cmd_reg         : std_logic;
   signal   wr_new_cmd_mux         : std_logic;
   signal   rd_new_cmd_reg         : std_logic;



   -- MPMC Control Support Signals
   signal   single                 : std_logic;
   signal   cacheline_8            : std_logic;

   signal   single_reg             : std_logic;
   signal   cacheline_8_reg        : std_logic;

   signal   rd_wr_module_addr      : std_logic_vector
                                       (0 to C_MPMC_PIM_ADDR_WIDTH-1);

   signal   wrblkcnt               : integer range 0 to 7;
   signal   rdblkcnt               : integer range 0 to 7;
   signal   rd_cmplt_cnt           : integer range 0 to 3;
   signal   addrackcnt             : integer range 0 to 7;
   signal   max_xings_plus1        : integer range 0 to 7;
   signal   wdblk_x_plus1          : integer range 0 to 7;

   signal   mpmc_pim_size          : std_logic_vector(0 to 3);
   signal   mpmc_pim_size_i        : integer range 0 to 7;
   signal   mpmc_size_tb0_q        : std_logic_vector(0 to 3);
   signal   mpmc_pim_rnw           : std_logic;
   signal   mpmc_pim_addr          : std_logic_vector
                                       (0 to C_MPMC_PIM_ADDR_WIDTH-1);

   signal   mpmc_addrReq           : std_logic;
   signal   mpmc_addrReq_reg       : std_logic;
   signal   mpmc_addrReq_reg2       : std_logic;

   signal   ad2wr_wrbe_i           : std_logic_vector
                                       (0 to C_MPMC_PIM_DATA_WIDTH/8-1);
-- N/A   signal   ad2rd_xfer_width_i     : std_logic_vector(0 to 1);
-- N/A   signal   ad2wr_xfer_width_i     : std_logic_vector(0 to 1);


   signal   Pi2ad_AddrAck_reg      : std_logic;
   signal   Pi2ad_wrfifo_almostFull_reg : std_logic;

   signal   sm_ack                 : std_logic;
   signal   mpmc_ackd_req          : std_logic;

   signal   rdmodwr_i              : std_logic;
   signal   rdmodwr_tb0_q          : std_logic;
   signal   rdmodwr_tb1_q          : std_logic;

   signal   Pi2ad_InitDone_reg     : std_logic;
   signal   Pi2ad_InitDone_reg2    : std_logic;

   signal   sc2ad_sample_cycle     : std_logic;
   signal   sc2wr_sample_cycle     : std_logic;
   signal   sc2rd_sample_cycle     : std_logic;
   signal   sc2ad_clk_ratio_1_1    : std_logic;

   signal   mpmc_rst               : std_logic;
   signal   plb_rst                : std_logic;

   signal   addr_wrp               : std_logic;

   signal   sa_act_reg             : std_logic;
   signal   mpmc_ack_reg           : std_logic;
   signal   pa_act_reg             : std_logic;
   signal   pa_act_reg2            : std_logic;

   signal   sa_act_set             : std_logic;
   signal   sa_act_clr             : std_logic;
   signal   mpmc_ack_set           : std_logic;
   signal   mpmc_ack_clr           : std_logic;
   signal   pa_act_set             : std_logic;
   signal   pa_act_clr             : std_logic;
   signal   sl_wait_reg            : std_logic;

begin

   CLOCK_TO_N_SAMPLE_CIRCUIT : entity mpmc_v6_03_a.plbv46_sample_cycle
   port map
   (
      rst                         => Pi_rst                                   ,
      fast_clk                    => Pi_clk                                   ,
      slow_clk                    => SPLB_Clk                                 ,
      sc2ad_sample_cycle          => sc2ad_sample_cycle                       ,
      sc2wr_sample_cycle          => sc2wr_sample_cycle                       ,
      sc2rd_sample_cycle          => sc2rd_sample_cycle                       ,
      sc2ad_clk_ratio_1_1         => sc2ad_clk_ratio_1_1                      ,
      mpmc_rst                    => mpmc_rst                                 ,
      plb_rst                     => plb_rst                                  ,
      sync_rst                    => sync_rst
   );

   sync_mpmc_rst        <= mpmc_rst;
   sync_plb_rst         <= plb_rst;

--   Sl_wait              <= '0';

--   sl_addrack           <= sl_addrack_i;
   sl_addrack           <= sl_addrack_reg;

   sl_mbusy             <= sl_mbusy_i;

   Ad2Rd_clk_ratio_1_1  <= sc2ad_clk_ratio_1_1;
   Ad2rd_plb_npi_sync   <= sc2rd_sample_cycle;
   Ad2rd_strt_addr      <= rd_wr_module_addr;
   Ad2rd_single         <= single_reg     ;
   Ad2rd_cacheline_4    <= '0';
   Ad2rd_cacheline_8    <= cacheline_8_reg;
   Ad2rd_burst_16       <= '0'   ;
   Ad2rd_burst_32       <= '0'   ;
   Ad2rd_burst_64       <= '0'   ;
   Ad2rd_xfer_width     <= "01";-- N/A ad2rd_xfer_width_i;  Only support 64bit
   Ad2rd_new_cmd        <= rd_new_cmd_reg;
   Ad2rd_mid            <= (others => '0');

   Ad2pi_Size           <= mpmc_pim_size;
   Ad2pi_RNW            <= mpmc_pim_rnw;
   Ad2pi_Addr           <= mpmc_pim_addr;
   Ad2pi_AddrReq        <= mpmc_addrReq_reg2;

   Ad2wr_strt_addr      <= rd_wr_module_addr;

   Ad2Wr_clk_ratio_1_1  <= sc2ad_clk_ratio_1_1;
   Ad2wr_plb_npi_sync   <= sc2wr_sample_cycle;
   Ad2wr_single         <= single_reg     ;
   Ad2wr_cacheline_4    <= '0';
   Ad2wr_cacheline_8    <= cacheline_8_reg;
   Ad2wr_burst_16       <= '0'   ;
   Ad2wr_burst_32       <= '0'   ;
   Ad2wr_burst_64       <= '0'   ;
   Ad2wr_xfer_width     <= "01";-- N/A ad2wr_xfer_width_i;  Only support 64bit
   Ad2wr_new_cmd        <= wr_new_cmd_mux;
   Ad2wr_mid            <= (others => '0');
   Ad2wr_wrbe           <= Ad2wr_wrbe_i;


--N/A -- ***********************************************************************  --
--N/A -- *************          PLB Shared - Generate Statement        *********  --
--N/A -- ***********************************************************************  --
--N/A GENERATE_SHARED_REGISTERS : if C_SPLB_P2P = 0 generate
--N/A
--N/A    ---------------------------------------------------------------------------
--N/A    -- Signal Declarations
--N/A    ---------------------------------------------------------------------------
--N/A    signal plb_abus_pipe      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
--N/A
--N/A    signal plb_pavalid_pipe   : std_logic;
--N/A    signal plb_savalid_pipe   : std_logic;
--N/A
--N/A    signal pa_active_shared   : std_logic;
--N/A    signal sa_active_shared   : std_logic;
--N/A
--N/A    signal plb_masterid_pipe  : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
--N/A    signal plb_masterid_rd_pipe: std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
--N/A    signal plb_masterid_wr_pipe: std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
--N/A
--N/A    signal plb_rnw_pipe       : std_logic;
--N/A
--N/A    signal plb_be_pipe        : std_logic_vector(0 to (C_SPLB_DWIDTH/8)-1);
--N/A
--N/A    signal plb_msize_pipe     : std_logic_vector(0 to 1);
--N/A       --  00 -  32 bit
--N/A       --  01 -  64 bit
--N/A       --  10 - 128 bit
--N/A       --  11 - 256 bit
--N/A
--N/A    signal plb_size_pipe      : std_logic_vector(0 to 3);
--N/A       --Supported Modes
--N/A       -- 0000    Transfer 1-4 bytes of a word starting at the target address
--N/A       -- 0001    Transfer the 4-word line containing the target word.
--N/A       -- 0010    Transfer the 8-word line containing the target word.
--N/A          -- See pg27 of the IBM 128-bit Processor Local Bus Interface
--N/A          --    Version 4.6 (CoreConnect TM)
--N/A          -- for additional notes, and unsupported modes.
--N/A
--N/A    signal plb_type_pipe      : std_logic_vector(0 to 2);
--N/A       -- 000    Memory Transfer
--N/A          -- See pg27 of the IBM 128-bit Processor Local Bus Interface
--N/A          --    Version 4.6 (CoreConnect TM)
--N/A          -- for additional notes, and unsupported modes.
--N/A
--N/A
--N/A begin
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Wires for shared bus- see register stages for shared bus below.
--N/A    ----------------------------------------------------------------------------
--N/A    plb_abus_i     <= plb_abus_pipe;
--N/A    plb_mid_i      <= plb_masterid_pipe;
--N/A    plb_mid_rd_i   <= plb_masterid_rd_pipe;
--N/A    plb_mid_wr_i   <= plb_masterid_wr_pipe;
--N/A    plb_rnw_i      <= plb_rnw_pipe;
--N/A    plb_be_i       <= plb_be_pipe;
--N/A    plb_msize_i    <= plb_msize_pipe;
--N/A    plb_size_i     <= plb_size_pipe;
--N/A    plb_type_i     <= plb_type_pipe;
--N/A    PA_Active      <= pa_active_shared;
--N/A    SA_Active      <= sa_active_shared;
--N/A --   Sl_rearbitrate <= (rearb_wr or rearb_rd) when Plb_PAValid = '1' else '0';
--N/A    Sl_rearbitrate <= sl_rearb_reg;
--N/A    Sl_wait        <= '0';
--N/A
--N/A   ----------------------------------------------------------------------------
--N/A   -- Register Master ID
--N/A   ----------------------------------------------------------------------------
--N/A   PLB_MASTERID_REG : process (splb_clk)
--N/A   begin
--N/A
--N/A      if rising_edge(splb_clk) then
--N/A         if plb_rst = '1' or Pi2ad_InitDone_reg = '0' then
--N/A            plb_masterid_pipe <= (others => '0');
--N/A         else
--N/A            plb_masterid_pipe <= PLB_masterID;
--N/A         end if;
--N/A      end if;
--N/A   end process;
--N/A
--N/A    PLB_MASTERID_RD_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' or Pi2ad_InitDone_reg = '0' then
--N/A             plb_masterid_rd_pipe <= (others => '0');
--N/A          else
--N/A             if addr_rd_busy = '0' then
--N/A                plb_masterid_rd_pipe <= PLB_masterID;
--N/A             else
--N/A                plb_masterid_rd_pipe <= plb_masterid_rd_pipe;
--N/A             end if;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A -------------------------------------------------------------------------------
--N/A --  addr_wr_busy is LOW until sl_addrack_i is asserted
--N/A -------------------------------------------------------------------------------
--N/A    PLB_MASTERID_WR_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' or Pi2ad_InitDone_reg = '0' then
--N/A             plb_masterid_wr_pipe <= (others => '0');
--N/A          else
--N/A             if addr_wr_busy = '0' then
--N/A                plb_masterid_wr_pipe <= PLB_masterID;
--N/A             else
--N/A                plb_masterid_wr_pipe <= plb_masterid_wr_pipe;
--N/A             end if;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Register PLB Address
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_ADDRESS_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' then
--N/A             plb_abus_pipe <= (others => '0');
--N/A          else
--N/A             plb_abus_pipe <= plb_abus;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Register Primary Address Valid
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_PAVALID_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' then
--N/A             plb_pavalid_pipe <= '0';
--N/A          else
--N/A             if (sl_rearb_reg = '1') then
--N/A --            if (rearb_wr = '1' or rearb_rd = '1') then
--N/A                plb_pavalid_pipe <= '0';
--N/A             else
--N/A                plb_pavalid_pipe <= plb_pavalid;
--N/A             end if;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Register Secondary Address Valid
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_SAVALID_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' then
--N/A             plb_savalid_pipe <= '0';
--N/A          else
--N/A             plb_savalid_pipe <= plb_savalid;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Register Read notWrite
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_RNW_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' then
--N/A             plb_rnw_pipe <= '0';
--N/A          else
--N/A             plb_rnw_pipe <= plb_rnw;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Register PLB Byte Enables
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_BE_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' then
--N/A             plb_be_pipe <= (others => '0');
--N/A          else
--N/A             plb_be_pipe <= plb_be;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Register the masters Size
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_MSIZE_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' then
--N/A             plb_msize_pipe <= (others => '0');
--N/A          else
--N/A             plb_msize_pipe <= plb_msize;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Register the PLB transfer size
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_SIZE_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' then
--N/A             plb_size_pipe <= (others => '0');
--N/A          else
--N/A             plb_size_pipe <= plb_size;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Register the PLB type
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_TYPE_REG : process (splb_clk)
--N/A    begin
--N/A
--N/A       if rising_edge(splb_clk) then
--N/A          if plb_rst = '1' then
--N/A             plb_type_pipe <= (others => '0');
--N/A          else
--N/A             plb_type_pipe <= plb_type;
--N/A          end if;
--N/A       end if;
--N/A    end process;
--N/A
--N/A
--N/A    ----------------------------------------------------------------------------
--N/A    -- Decode the PLB address if shared bus
--N/A    ----------------------------------------------------------------------------
--N/A    PLB_PA_ADDRESS_DECODE : process (plb_pavalid_pipe,plb_abus_i)
--N/A    begin
--N/A
--N/A       if plb_pavalid_pipe = '1' then
--N/A          if plb_abus_i >=  C_MPMC_PIM_BASEADDR and
--N/A             plb_abus_i <=  C_MPMC_PIM_HIGHADDR then
--N/A             pa_active_shared <= '1';
--N/A          else
--N/A             pa_active_shared <= '0';
--N/A          end if;
--N/A       else
--N/A          pa_active_shared <= '0';
--N/A       end if;
--N/A    end process;
--N/A
--N/A    PLB_SA_ADDRESS_DECODE : process (plb_savalid_pipe,plb_abus_i)
--N/A    begin
--N/A
--N/A       if plb_savalid_pipe = '1' then
--N/A          if plb_abus_i >=  C_MPMC_PIM_BASEADDR and
--N/A             plb_abus_i <=  C_MPMC_PIM_HIGHADDR then
--N/A             sa_active_shared <= '1';
--N/A          else
--N/A             sa_active_shared <= '0';
--N/A          end if;
--N/A       else
--N/A          sa_active_shared <= '0';
--N/A       end if;
--N/A    end process;
--N/A
--N/A
--N/A end generate;
--N/A -- ************************************************************************  --
--N/A
--N/A -- ************************************************************************  --
--N/A -- ***********          PLB P2P - Generate Statement        ***************  --
--N/A -- ************************************************************************  --
--N/A    ----------------------------------------------------------------------------
--N/A    -- Wires for P2P bus- see register stages for shared bus below.
--N/A    ----------------------------------------------------------------------------
--N/A GENERATE_P2P_WIRES : if C_SPLB_P2P = 1 generate
--N/A begin
--N/A
   plb_abus_i     <= plb_abus;
   PA_Active      <= plb_pavalid;
   SA_Active      <= plb_savalid;
   plb_mid_i      <= PLB_masterID;
   plb_mid_rd_i   <= PLB_masterID;
   plb_mid_wr_i   <= PLB_masterID;
   plb_rnw_i      <= PLB_RNW;
   plb_be_i       <= PLB_BE;
   plb_msize_i    <= PLB_MSize;
   plb_size_i     <= PLB_size;
   plb_type_i     <= PLB_type;
   Sl_rearbitrate <= '0';
   Sl_wait        <= sl_wait_reg;

   ----------------------------------------------------------------------------
   --  added to use sl_wait when P2P=1 instead of sl_rearbitrate
   ----------------------------------------------------------------------------
   SPLB_SL_WAIT : process (splb_clk)
   begin

      if rising_edge(splb_clk) then
         if (plb_rst = '1' or sl_addrack_reg = '1') then
            sl_wait_reg <= '0';
         elsif sl_rearb_reg = '1' then
            sl_wait_reg <= '1';
         else
            sl_wait_reg <= sl_wait_reg;
         end if;
      end if;
   end process;


-- N/A end generate;

master_id         <= to_integer(unsigned(plb_mid_i));
master_id_rd      <= to_integer(unsigned(plb_mid_rd_i));
master_id_wr      <= to_integer(unsigned(plb_mid_wr_i));


-- ************************************************************************  --
-- ************** 64bit NPI Size Logic - Generate Statement ***************  --
-- ************************************************************************  --
GENERATE_MPMC_SIZE_64BIT_NPI : if C_MPMC_PIM_DATA_WIDTH = 64 generate

   constant SEVEN                  :  std_logic_vector(0 to 9)
                                       := std_logic_vector(
                                       to_unsigned(7,10));

-- N/A   constant THREE                  :  std_logic_vector(0 to 9)
-- N/A                                       := std_logic_vector(
-- N/A                                       to_unsigned(3,10));

   constant ONE                    :  std_logic_vector(0 to 9)
                                       := std_logic_vector(
                                       to_unsigned(1,10));

   signal   addr_tb0_q             : unsigned(0 to 31);
   signal   addr_strt              : std_logic_vector(0 to 6);
   signal   addr_zeroes_sngl       : std_logic_vector(0 to 2);
   signal   addr_zeroes_brst       : std_logic_vector(0 to 6);

   signal   end_address            : integer range 0 to 511;

   signal   xfer_wdcnt             : std_logic_vector(0 to 9);
   signal   xfer_wdcnt_i           : std_logic_vector(0 to 9);

   signal   xfer_byte_cnt_i        : std_logic_vector(0 to 7);
   signal   cross_bndry_bits       : std_logic_vector(0 to 8);

begin


--   Sl_SSize          <= "01" when valid_request = '1' else "00";
   Ad2rd_xfer_wdcnt  <= "0" & xfer_wdcnt(3 to 9); --send only the relevant PLB_BE shifted left 2x - 64 words max - 6 bits
   Ad2wr_xfer_wrdcnt <= "0" & xfer_wdcnt(3 to 9); --send only the relevant PLB_BE shifted left 2x - 64 words max - 6 bits

   -------------------------------------------------------------------------------
   -- Register Slave Size
   -------------------------------------------------------------------------------
   REG_SL_SIZE : process(splb_clk)
   begin

      if rising_edge(splb_clk) then
         if plb_rst = '1' then
            Sl_SSize     <= "00";
         else
            if (sl_addrack_i = '1' and sl_rearb_reg = '0') then -- and valid_request = '1') then
               Sl_SSize <= "01";
            else
               Sl_SSize <= "00";
            end if;
         end if;
      end if;
   end process;

   ----------------------------------------------------------------------------
   -- Register PLB BE for Write Module
   ----------------------------------------------------------------------------

-- N/A   WR_BE_SM32 : if C_SPLB_SMALLEST_MASTER = 32 generate
-- N/A   begin
-- N/A
-- N/A      REGISTER_WR_BE : process (splb_clk)
-- N/A      begin
-- N/A
-- N/A         if rising_edge(splb_clk) then
-- N/A            if plb_rst = '1' then
-- N/A               Ad2wr_wrbe_i <= (others => '0');
-- N/A            elsif tb0_en = '1' and plb_rnw = '0' then
-- N/A               case Plb_MSize_i is
-- N/A                  when "00" => --32 bit master
-- N/A                     if single = '1' then
-- N/A                        if plb_abus_i(29) = '1' then
-- N/A                           Ad2wr_wrbe_i <= "0000" & plb_be_i(0 to 3);
-- N/A                        else
-- N/A                           Ad2wr_wrbe_i <= plb_be_i(0 to 3) & "0000";
-- N/A                        end if;
-- N/A                     else
-- N/A                        Ad2wr_wrbe_i <= "1111" & "0000";
-- N/A                     end if;
-- N/A                  when "01" => --64 bit master
-- N/A                     if single = '1' then
-- N/A                        Ad2wr_wrbe_i <= plb_be_i(0 to 7);
-- N/A                     else
-- N/A                        Ad2wr_wrbe_i <= (others => '1');
-- N/A                     end if;
-- N/A                  when "10" => --128 bit master
-- N/A                     if single = '1' then
-- N/A                        if plb_abus_i(28) = '1' then
-- N/A                           Ad2wr_wrbe_i <= plb_be_i(8 to 15);
-- N/A                        else
-- N/A                           Ad2wr_wrbe_i <= plb_be_i(0 to 7);
-- N/A                        end if;
-- N/A                     else
-- N/A                        Ad2wr_wrbe_i <= (others => '1');
-- N/A                     end if;
-- N/A                  when others => null;
-- N/A               end case;
-- N/A            else
-- N/A               Ad2wr_wrbe_i <= Ad2wr_wrbe_i;
-- N/A            end if;
-- N/A         end if;
-- N/A      end process;
-- N/A   end generate;
-- N/A
-- N/A   WR_BE_SM64 : if C_SPLB_SMALLEST_MASTER = 64 generate
-- N/A   begin
-- N/A
-- N/A      REGISTER_WR_BE : process (splb_clk)
-- N/A      begin
-- N/A
-- N/A         if rising_edge(splb_clk) then
-- N/A            if plb_rst = '1' then
-- N/A               Ad2wr_wrbe_i <= (others => '0');
-- N/A            elsif tb0_en = '1' and plb_rnw = '0' then
-- N/A               case Plb_MSize_i is
-- N/A                  when "01" => --64 bit master
-- N/A                     if single = '1' then
-- N/A                        Ad2wr_wrbe_i <= plb_be_i(0 to 7);
-- N/A                     else
-- N/A                        Ad2wr_wrbe_i <= (others => '1');
-- N/A                     end if;
-- N/A                  when "10" => --128 bit master
-- N/A                     if single = '1' then
-- N/A                        if plb_abus_i(28) = '1' then
-- N/A                           Ad2wr_wrbe_i <= plb_be_i(8 to 15);
-- N/A                        else
-- N/A                           Ad2wr_wrbe_i <= plb_be_i(0 to 7);
-- N/A                        end if;
-- N/A                     else
-- N/A                        Ad2wr_wrbe_i <= (others => '1');
-- N/A                     end if;
-- N/A                  when others => null;
-- N/A               end case;
-- N/A            else
-- N/A               Ad2wr_wrbe_i <= Ad2wr_wrbe_i;
-- N/A            end if;
-- N/A         end if;
-- N/A      end process;
-- N/A   end generate;
-- N/A
-- N/A
-- N/A   WR_BE_SM128 : if C_SPLB_SMALLEST_MASTER = 128 generate
-- N/A   begin
-- N/A
-- N/A      REGISTER_WR_BE : process (splb_clk)
-- N/A      begin
-- N/A
-- N/A         if rising_edge(splb_clk) then
-- N/A            if plb_rst = '1' then
-- N/A               Ad2wr_wrbe_i <= (others => '0');
-- N/A            elsif tb0_en = '1' and plb_rnw = '0' then
-- N/A               case Plb_MSize_i is
-- N/A                  when "10" => --128 bit master
-- N/A                     if single = '1' then
-- N/A                        if plb_abus_i(28) = '1' then
-- N/A                           Ad2wr_wrbe_i <= plb_be_i(8 to 15);
-- N/A                        else
-- N/A                           Ad2wr_wrbe_i <= plb_be_i(0 to 7);
-- N/A                        end if;
-- N/A                     else
-- N/A                        Ad2wr_wrbe_i <= (others => '1');
-- N/A                     end if;
-- N/A                  when others => null;
-- N/A               end case;
-- N/A            else
-- N/A               Ad2wr_wrbe_i <= Ad2wr_wrbe_i;
-- N/A            end if;
-- N/A         end if;
-- N/A      end process;
-- N/A   end generate;

   WR_BE_SM64_PLB64 : if (C_SPLB_SMALLEST_MASTER = 64 and C_SPLB_DWIDTH = 64) generate
   begin

      REGISTER_WR_BE : process (splb_clk)
      begin

         if rising_edge(splb_clk) then
            if plb_rst = '1' then
               Ad2wr_wrbe_i <= (others => '0');
            elsif tb0_en = '1' and plb_rnw = '0' then
               case Plb_MSize_i is
                  when "01" => --64 bit master
                     if single = '1' then
                        Ad2wr_wrbe_i <= plb_be_i(0 to 7);
                     else
                        Ad2wr_wrbe_i <= (others => '1');
                     end if;
                  when others => null;
               end case;
            else
               Ad2wr_wrbe_i <= Ad2wr_wrbe_i;
            end if;
         end if;
      end process;
   end generate;



-- N/A    ----------------------------------------------------------------------------
-- N/A    -- Register the masters size for the read module
-- N/A    -- The size to the read module must never be greater than
-- N/A    --  C_MPMC_PIM_DATA_WIDTH
-- N/A    ----------------------------------------------------------------------------
-- N/A   RD_MOD_SIZE : process (splb_clk)
-- N/A   begin
-- N/A
-- N/A      if rising_edge(splb_clk) then
-- N/A         if plb_rst = '1' then
-- N/A            ad2rd_xfer_width_i <= (others => '0');
-- N/A         elsif tb0_en = '1' and plb_rnw = '1' then
-- N/A            if Plb_MSize_i = "00" then
-- N/A               ad2rd_xfer_width_i <= "00";
-- N/A            else
-- N/A               ad2rd_xfer_width_i <= "01";
-- N/A            end if;
-- N/A         else
-- N/A            ad2rd_xfer_width_i <= ad2rd_xfer_width_i;
-- N/A         end if;
-- N/A      end if;
-- N/A   end process;
-- N/A


-- N/A   ----------------------------------------------------------------------------
-- N/A   -- Register the masters size for the write module
-- N/A   -- The size to the read module must never be greater than
-- N/A   --  C_MPMC_PIM_DATA_WIDTH
-- N/A   ----------------------------------------------------------------------------
-- N/A   WR_MOD_SIZE : process (splb_clk)
-- N/A   begin
-- N/A
-- N/A      if rising_edge(splb_clk) then
-- N/A         if plb_rst = '1' then
-- N/A            ad2wr_xfer_width_i <= (others => '0');
-- N/A         elsif tb0_en = '1' and plb_rnw = '0' then
-- N/A            if Plb_MSize_i = "00" then
-- N/A               ad2wr_xfer_width_i <= "00";
-- N/A            else
-- N/A               ad2wr_xfer_width_i <= "01";
-- N/A            end if;
-- N/A         else
-- N/A            ad2wr_xfer_width_i <= ad2wr_xfer_width_i;
-- N/A         end if;
-- N/A      end if;
-- N/A   end process;



   ----------------------------------------------------------------------------
   -- MPMC SIZE TYPE
   -- plb_size_i will stay walid until Sl_addrack
   ----------------------------------------------------------------------------
   MPMC_SIZE : process (plb_msize,plb_size_i,mpmc_pim_size_i)
   begin

         case plb_size_i is
            when "0000" => mpmc_pim_size_i <= 0; --plb_size is word
                           valid_size        <= '1';
                           single            <= '1';
                           cacheline_8       <= '0';
            when "0010" => mpmc_pim_size_i <= 2;  --plb_size is 8wd cacheline
                           valid_size        <= '1';
                           single            <= '0';
                           cacheline_8       <= '1';
            when others => mpmc_pim_size_i <= 0; --reserved
                           valid_size        <= '0';
                           single            <= '0';
                           cacheline_8       <= '0';
         end case;
   end process;

   ----------------------------------------------------------------------------
   -- MPMC Transfer in words
   -- plb_size_i will stay walid until Sl_addrack
   ----------------------------------------------------------------------------
    XFER_WORD_COUNT : process (plb_size_i,plb_be_i,plb_msize_i)
       begin

          xfer_wdcnt_i         <= (others => '0');

          case plb_size_i Is
            -- 1 word xfer
-- N/A            when "0000" =>
-- N/A               if (plb_msize_i = "00") then
-- N/A                   xfer_wdcnt_i   <= (others => '0');
-- N/A               else --64 or 128 bit master
-- N/A                   xfer_wdcnt_i   <= ONE;
-- N/A               end if;
-- N/A            -- 4 word xfer (2 double words)
-- N/A             when "0001" => xfer_wdcnt_i <= THREE;
             -- 8 word xfer (4 double words)
            when "0010" => xfer_wdcnt_i <= SEVEN;
            -- Burst transfer of words and double words
            -- Undefined operations so assume 1 data beat
            when others   =>
                   xfer_wdcnt_i   <= ONE;
-- N/A                xfer_wdcnt_i       <= (others => '0');
          end case;

       end process XFER_WORD_COUNT;

    ---------------------------------------------------------------------------
    -- Add 1 to send actual number of transfer words to rd/wr modules
    ---------------------------------------------------------------------------
    REGISTER_WDCNT : process (splb_clk)
    begin

       if rising_edge(splb_clk) then
         if plb_rst = '1' then
            xfer_wdcnt <= (others => '0');
         elsif (tb0_en = '1') then
            xfer_wdcnt <= std_logic_vector(unsigned(xfer_wdcnt_i) + 1);
         else
            xfer_wdcnt <= xfer_wdcnt;
         end if;
       end if;

    end process;

-------------------------------------------------------------------------------
--  HIGH Address cannot be exceeded on single and cacheline transactions.
--  It can only be eceeded on burts trab=nsactions that cross into the next
--  when the largest word block.
-------------------------------------------------------------------------------
   ADDR_THROTTLE_BUF0 : process(splb_clk)
   begin

      if rising_edge(splb_clk) then
         if plb_rst = '1' then
            addr_tb0_q <= (others => '0');
         else
            if tb0_en = '1' then
               addr_tb0_q <= unsigned(Plb_ABus) - unsigned(C_MPMC_PIM_BASEADDR) + unsigned(C_MPMC_PIM_OFFSET);
            else
               addr_tb0_q <= addr_tb0_q;
            end if;
         end if;
      end if;
   end process;

   ----------------------------------------------------------------------------
   -- Address Generation/Throttling Logic Block
   ----------------------------------------------------------------------------
      addr_zeroes_sngl <= (others => '0'); --3bits

   ----------------------------------------------------------------------------
   -- Mux the primary address or the secondary address(es) if necessary
   ----------------------------------------------------------------------------
      mpmc_pim_addr <= std_logic_vector(addr_tb0_q(0 to 28)) &
                        addr_zeroes_sngl;
   ----------------------------------------------------------------------------
   -- Mux appropriate MPMC_PIM_SIZE signal
   ----------------------------------------------------------------------------
      mpmc_pim_size <= mpmc_size_tb0_q;

end generate;


-- ************************************************************************  --

---------------------------------------------------------------------------------
----  Register rd2ad_rd_cmplt in the PLB clock domain for timing.
---------------------------------------------------------------------------------
--REG_RD2AD_RD_CMPLT : process(splb_clk)
--begin
--
--   if rising_edge(splb_clk) then
--      if plb_rst = '1' then
--         rd2ad_rd_cmplt_reg <= '0';
--      else
--         rd2ad_rd_cmplt_reg <= Rd2ad_rd_cmplt;
--      end if;
--   end if;
--end process;

-------------------------------------------------------------------------------
-- PLB Size Validation
-- This combinatorial process validates the PLB request attribute PLB_type
-- that is supported by this slave.
-------------------------------------------------------------------------------
VALIDATE_TYPE : process (plb_type_i)
begin

   if(plb_type_i="000")then
      valid_plb_type <= '1';
   else
      valid_plb_type <= '0';
   end if;
end process VALIDATE_type;

-------------------------------------------------------------------------------
-- Access Validation
-- This combinatorial process validates the PLB request attributes that are
-- supported by this slave.
-------------------------------------------------------------------------------
VALIDATE_REQUEST : process (pa_active,sa_active,valid_size,valid_plb_type)--,
                            --indeterminate_burst,valid_blength)
begin

   if (pa_active = '1' or sa_active = '1') and  -- Address Request
      (valid_size = '1') and                    -- and a valid plb_size
      (valid_plb_type = '1') then --and                      -- and a memory xfer
      valid_request <= '1';
   else
      valid_request <= '0';
   end if;
end process VALIDATE_REQUEST;

-------------------------------------------------------------------------------
-- Process to bridge the busy signal after the assertion of sl_addrack until
-- the assertion of wr2ad_busy
-------------------------------------------------------------------------------
BRIDGE_WRBUSY_SIGNAL : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         addr_wr_busy_pre <= '0';
      elsif (sl_addrack_i = '1' and plb_rnw_i = '0') then
         addr_wr_busy_pre <= '1';
      elsif  (Wr2ad_wr_cmplt = '1') then
         addr_wr_busy_pre <= '0';
      else
         addr_wr_busy_pre <= addr_wr_busy_pre;
      end if;
   end if;

end process;

--needed to meet timing  0629_2007
REG_WRBUSY_SIGNAL : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         wr2ad_busy_reg <= '0';
      else
         wr2ad_busy_reg <= Wr2ad_busy;
      end if;
   end if;

end process;


addr_wr_busy <= addr_wr_busy_pre or wr2ad_busy_reg;

-------------------------------------------------------------------------------
-- Process to bridge the busy signal after the assertion of sl_addrack until
-- the assertion of Rd2ad_rd_Data_cmplt
-------------------------------------------------------------------------------
BRIDGE_RDBUSY_SIGNAL : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         addr_rd_busy <= '0';
      elsif sl_addrack_i = '1' and plb_rnw_i = '1' then
         addr_rd_busy <= '1';
      elsif  (Rd2ad_rd_Data_cmplt = '1') then
         addr_rd_busy <= '0';
      else
         addr_rd_busy <= addr_rd_busy;
      end if;
   end if;

end process;

-------------------------------------------------------------------------------
--  Needed for SA_VALID stuff
-------------------------------------------------------------------------------
SM_RDBUSY_SIGNAL : process(splb_clk)
begin

--   if rising_edge(splb_clk) then
--      if plb_rst = '1' then
--         addr_rd_busy_sm <= '0';
--         addr_rd_busy_tg <= '0';
--      elsif sl_addrack_i = '1' and plb_rnw_i = '1' and rd2ad_rd_cmplt_reg = '1' then
--         addr_rd_busy_sm <= '0';
--         addr_rd_busy_tg <= '1';
--      elsif (sl_addrack_i = '1' and plb_rnw_i = '1') or addr_rd_busy_tg = '1' then
--         addr_rd_busy_sm <= '1';
--         addr_rd_busy_tg <= '0';
--      elsif  (rd2ad_rd_cmplt_reg = '1') then
--         addr_rd_busy_sm <= '0';
--         addr_rd_busy_tg <= '0';
--      else
--         addr_rd_busy_sm <= addr_rd_busy_sm;
--         addr_rd_busy_tg <= '0';
--      end if;
--   end if;

    if rising_edge(splb_clk) then
      if plb_rst = '1' then
         addr_rd_busy_sm <= '0';
      elsif (rd_new_cmd = '1' )  then
         addr_rd_busy_sm <= '1';
--      elsif  (rd2ad_rd_cmplt_reg = '1') then
      elsif  (Rd2ad_rd_cmplt = '1') then
         addr_rd_busy_sm <= '0';
      else
         addr_rd_busy_sm <= addr_rd_busy_sm;
      end if;
   end if;

end process;

-------------------------------------------------------------------------------
--  Allow rd module to queue up data
--  on sa_valid read transfers
-------------------------------------------------------------------------------
Ad2rd_queue_data <= wait_2clks;--rd_support_busy;

-------------------------------------------------------------------------------
--  Rd module is rdacking to PLB too soon, so use this signal to delay it one
--  cycle
-------------------------------------------------------------------------------
--SM_RDBUSY_SIGNAL_REG : process(splb_clk)
--begin
--
--   if rising_edge(splb_clk) then
--      if plb_rst = '1' then
--         addr_rd_busy_sm_reg <= '0';
--      else
--         addr_rd_busy_sm_reg <= addr_rd_busy_sm;
--      end if;
--   end if;
--
--end process;

-------------------------------------------------------------------------------
--  Counter for asserting rd_support_busy.
-- SA_Valid Support
-------------------------------------------------------------------------------
READ_COMPLETE_CNT : process(splb_clk)
   begin
      if rising_edge (splb_clk) Then
         if plb_rst = '1' then
            rd_cmplt_cnt <= 0;
--         elsif rd2ad_rd_cmplt_reg = '1' and sl_addrack_i = '1' and plb_rnw_i = '1' then
         elsif Rd2ad_rd_cmplt = '1' and sl_addrack_i = '1' and plb_rnw_i = '1' then
            rd_cmplt_cnt <= rd_cmplt_cnt;  --Hold value if the rd_cmplt occurs with addrack
         elsif sl_addrack_i = '1' and plb_rnw_i = '1' and rd_support_busy = '0' then
            rd_cmplt_cnt     <= 1;                 -- Load
         elsif sl_addrack_i = '1' and plb_rnw_i = '1' and rd_support_busy = '1' then
            rd_cmplt_cnt     <= rd_cmplt_cnt + 1;  --increment
--         elsif rd2ad_rd_cmplt_reg = '1' then
         elsif Rd2ad_rd_cmplt = '1' then
            rd_cmplt_cnt <= rd_cmplt_cnt - 1;      --decrement
         else
            rd_cmplt_cnt <= rd_cmplt_cnt;          --hold
         end if;
      end if;
end process READ_COMPLETE_CNT;


-------------------------------------------------------------------------------
-- Process for asserting rd_support_busy
-- This signal is asserted for the duration that the read support module cannot
-- accept a new command.
-------------------------------------------------------------------------------
BRIDGE_RDBUSY_SM_SIGNAL2 : process(splb_clk)
   begin
      if rising_edge (splb_clk) Then
         if plb_rst = '1' then
            rd_support_busy <= '0';
         elsif sl_addrack_i = '1' and plb_rnw_i = '1' then
            rd_support_busy <= '1';
         elsif rd_cmplt_cnt = 0 then
            rd_support_busy <= '0';
         else
            rd_support_busy <= '1';
         end if;
      end if;
end process;


-------------------------------------------------------------------------------
-- Need to wait for a dead cycle after addrack to enable read module.
-------------------------------------------------------------------------------
HOLD_OFF_RD_SUPPORT_START : process(splb_clk)
   begin
      if rising_edge (splb_clk) Then
         if plb_rst = '1' then
            wait_2clks <= '0';
         elsif sl_addrack_reg2 = '1' and rd_support_busy = '1' then
            wait_2clks <= '1';
         elsif rd_cmplt_cnt = 0 then
            wait_2clks <= '0';
         else
            wait_2clks <= wait_2clks;
         end if;
      end if;
end process;

---------------------------------------------------------------------------------
----  Set the busy bit for the master
---------------------------------------------------------------------------------
--GEN_SL_MBUSY_FOR_PRIMING : process(plb_rst,master_id,sl_addrack_i,addr_rd_busy,addr_wr_busy)
--begin
--   for i in 0 to C_SPLB_NUM_MASTERS - 1 loop
--      if (plb_rst = '1' or addr_rd_busy= '1' or addr_wr_busy = '1' ) then
--         sl_prm_mbusy_i(i)   <= '0';
--      elsif (i=master_id)then
--         if (sl_addrack_i = '1') Then
--            sl_prm_mbusy_i(i)  <= '1';-- set bit for req master
--         else
--            sl_prm_mbusy_i(i)   <= '0';
--         end if;
--      else
--         sl_prm_mbusy_i(i) <= '0';
--      end if;
--   end loop;
--end process GEN_SL_MBUSY_FOR_PRIMING;

-------------------------------------------------------------------------------
--  Set the busy bit for the master
-------------------------------------------------------------------------------
GEN_SL_MBUSY_FOR_PRIMING_WR : process(plb_rst,master_id,sl_addrack_i,plb_rnw_i,
                                       addr_wr_busy)
begin
   for i in 0 to C_SPLB_NUM_MASTERS - 1 loop
      if (plb_rst = '1' or addr_wr_busy = '1' ) then
         sl_prm_wr_mbusy_i(i)   <= '0';
      elsif (i=master_id)then
         if (sl_addrack_i = '1'and plb_rnw_i = '0') Then
            sl_prm_wr_mbusy_i(i)  <= '1';-- set bit for req master
         else
            sl_prm_wr_mbusy_i(i)   <= '0';
         end if;
      else
         sl_prm_wr_mbusy_i(i) <= '0';
      end if;
   end loop;
end process GEN_SL_MBUSY_FOR_PRIMING_WR;

-------------------------------------------------------------------------------
--  Set the busy bit for the master
-------------------------------------------------------------------------------
GEN_SL_MBUSY_FOR_PRIMING_RD : process(plb_rst,master_id,sl_addrack_i,plb_rnw_i,
                                       addr_rd_busy)
begin
   for i in 0 to C_SPLB_NUM_MASTERS - 1 loop
      if (plb_rst = '1' or addr_rd_busy= '1') then
         sl_prm_rd_mbusy_i(i)   <= '0';
      elsif (i=master_id) then
         if (sl_addrack_i = '1' and plb_rnw_i='1') Then
            sl_prm_rd_mbusy_i(i)  <= '1';-- set bit for req master
         else
            sl_prm_rd_mbusy_i(i)   <= '0';
         end if;
      else
         sl_prm_rd_mbusy_i(i) <= '0';
      end if;
   end loop;
end process GEN_SL_MBUSY_FOR_PRIMING_RD;


-------------------------------------------------------------------------------
--  Set the busy bit for the master
-------------------------------------------------------------------------------
GEN_SL_MBUSY_FOR_RD : process(plb_rst,Rd2ad_rd_Data_cmplt,master_id_rd,sl_addrack_i,plb_rnw_i,addr_rd_busy)
begin
   for i in 0 to C_SPLB_NUM_MASTERS - 1 loop
      if (plb_rst = '1' or Rd2ad_rd_Data_cmplt = '1') then
         sl_rd_mbusy_i(i)   <= '0';
      elsif (i=master_id_rd)then
         if (sl_addrack_i = '1' and plb_rnw_i = '1') or addr_rd_busy = '1' Then
            sl_rd_mbusy_i(i)  <= '1';-- set bit for req master
         else
            sl_rd_mbusy_i(i)   <= '0';
         end if;
      else
         sl_rd_mbusy_i(i) <= '0';
      end if;
   end loop;
end process GEN_SL_MBUSY_FOR_RD;

-------------------------------------------------------------------------------
--  Set the busy bit for the master
-------------------------------------------------------------------------------
GEN_SL_MBUSY_FOR_WR : process(plb_rst,master_id_wr,sl_addrack_i,plb_rnw_i,addr_wr_busy)
begin
   for i in 0 to C_SPLB_NUM_MASTERS - 1 loop
      if (plb_rst = '1' ) then
         sl_wr_mbusy_i(i)   <= '0';
      elsif (i=master_id_wr)then
         if (sl_addrack_i = '1' and plb_rnw_i = '0') or addr_wr_busy = '1' Then
            sl_wr_mbusy_i(i)  <= '1';-- set bit for req master
         else
            sl_wr_mbusy_i(i)   <= '0';
         end if;
      else
         sl_wr_mbusy_i(i) <= '0';
      end if;
   end loop;
end process GEN_SL_MBUSY_FOR_WR;

-------------------------------------------------------------------------------
--  Set the busy bit for the master
-------------------------------------------------------------------------------
GEN_SL_MBUSY : process(splb_clk)
begin
   if rising_edge (splb_clk) Then
      for i in 0 to C_SPLB_NUM_MASTERS - 1 loop
         sl_mbusy_i(i) <= sl_prm_rd_mbusy_i(i) or sl_prm_wr_mbusy_i(i) or
                           sl_rd_mbusy_i(i) or sl_wr_mbusy_i(i);
      end loop;
   end if;
end process GEN_SL_MBUSY;

------------------------------------------------------------------------------
-- Sample and Hold rnw for the initial transfer
-------------------------------------------------------------------------------
RNW_THROTTLE_BUF0 : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         rnw_tb0_q <= '0';
      else
         if tb0_en = '1' then
            rnw_tb0_q <= plb_rnw_i;
         else
            rnw_tb0_q <= rnw_tb0_q;
         end if;
      end if;
   end if;
end process;



-------------------------------------------------------------------------------
-- Mux appropriate rnw signal if a word block boundary is crossed
-------------------------------------------------------------------------------
MUX_PRIMARY_RNW : process(rnw_tb0_q)
begin


      MPMC_PIM_RNW <= rnw_tb0_q;

end process;

-------------------------------------------------------------------------------
-- Delay the rnw signal to align it with the mpmc_pim_addr, MPMC_PIM_RNW
-------------------------------------------------------------------------------
MPMC_SIZE_THROTTLE_BUF0 : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         mpmc_size_tb0_q <= (others => '0');
      else
         if tb0_en = '1' then
            mpmc_size_tb0_q <=std_logic_vector(to_unsigned(mpmc_pim_size_i,4));
         else
            mpmc_size_tb0_q <=mpmc_size_tb0_q;
         end if;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Sample and hold plb address for comparison of address hit for sa_active
-------------------------------------------------------------------------------
Primary_Address : process (splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         pa_address <= (others => '0');
      elsif pa_active = '1' then
         pa_address <= plb_abus_i;
      else
         pa_address <= pa_address;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Sample and hold plb address for comparison of address hit for pa_active
-------------------------------------------------------------------------------
Secondary_Address : process (splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         sa_address <= (others => '0');
      elsif sa_active = '1' then
         sa_address <= plb_abus_i;
      else
         sa_address <= sa_address;
      end if;
   end if;
end process;


-------------------------------------------------------------------------------
--  Register compare output - Needed to meet timing
-------------------------------------------------------------------------------
addr_equal_i <= '1' when (pa_address = sa_address) else '0';
ADDRESS_COMPARE : process (splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         address_hit <= '0';
      else
        address_hit <= addr_equal_i;
      end if;
   end if;
end process;



--*****************************************************************************
-------------------------------------------------------------------------------
-- Address Support Module State Machine
-------------------------------------------------------------------------------
--*****************************************************************************

ADDR_SM_COMB : process(addr_cs,pa_active,sa_active,plb_rnw_i,
                       single,
                       cacheline_8,
                       rdblkcnt,mpmc_ack_reg,sa_address,pa_address,sm_ack,
                       max_xings_plus1,AddrAckCnt,wrBlkCnt,valid_request,
                       addr_wr_busy,
                       Wr2ad_wr_cmplt,
                       pa_act_reg,
                       pa_act_reg2,
                       Pi2ad_wrfifo_almostFull_reg,
                       Pi2ad_InitDone_reg2,
                       sa_act_reg,
                       rd_support_busy,
                       addr_rd_busy,
                       addr_rd_busy_sm,
--                       addr_rd_busy_sm_reg,
                       mpmc_pim_rnw,
--                       rd2ad_rd_cmplt_reg,
                       Rd2ad_rd_cmplt,
                       single_reg,
                       cacheline_8_reg,
                       rd_cmplt_cnt,
                       rd_new_cmd_reg_flag,
                       address_hit,
                       sl_rearb_reg
                       )
begin
      sl_addrack_i   <= '0';
      mpmc_addrReq   <= '0';
      wr_new_cmd     <= '0';
      rd_new_cmd     <= '0';

      rearb_wr       <= '0';
      rearb_rd       <= '0';

      tb0_en         <= '0';

      sa_act_set     <= '0';
      sa_act_clr     <= '0';
      pa_act_set     <= '0';
      pa_act_clr     <= '0';

      mpmc_ack_set   <= '0';
      mpmc_ack_clr   <= '0';

      rd_new_cmd_set <= '0';
      rd_new_cmd_clr <= '0';

   case addr_cs is


      when idle =>

             if pa_active = '1' and plb_rnw_i = '0' and valid_request = '1' and Pi2ad_InitDone_reg2 = '1' then
               if (single = '1') then
                  mpmc_addrReq   <= '0'; --wait for tbo_en data to become valid
                  wr_new_cmd     <= '0';
                  rd_new_cmd     <= '0';
                  rearb_rd       <= '0';
                  sa_act_set     <= '0';
                  pa_act_set     <= '0';

                  if addr_wr_busy = '0' and Pi2ad_wrfifo_almostFull_reg = '0' and sl_rearb_reg = '0' then
                     sl_addrack_i <= '1';
                     tb0_en       <= '1';
                     rearb_wr     <= '0';
                     addr_ns      <= initiate_single_wr;
                  else
                     sl_addrack_i <= '0';
                     tb0_en       <= '0';
                     rearb_wr     <= pa_active;
                     addr_ns      <= idle;
                  end if;
               else  --cacheline
                  mpmc_addrReq   <= '0'; --wait for tbo_en data to become valid
                  wr_new_cmd     <= '0';
                  rd_new_cmd     <= '0';
                  rearb_rd       <= '0';
                  sa_act_set     <= '0';
                  pa_act_set     <= '0';
                  if addr_wr_busy = '0' and sl_rearb_reg = '0' then
                     sl_addrack_i <= '1';
                     tb0_en       <= '1';
                     rearb_wr     <= '0';
                     addr_ns      <= initiate_inbndry_wr;
                  else
                     sl_addrack_i <= '0';
                     tb0_en       <= '0';
                     rearb_wr     <= pa_active;
                     addr_ns      <= idle;
                  end if;
               end if;
         elsif pa_active = '1' and plb_rnw_i = '1' and valid_request = '1' and Pi2ad_InitDone_reg2 = '1' then
            sl_addrack_i   <= '0';
            mpmc_addrReq   <= '0';
            wr_new_cmd     <= '0';
            rd_new_cmd     <= '0';
            rearb_wr       <= '0';
            sa_act_set     <= '0';
            if rd_support_busy = '0' and sl_rearb_reg = '0' then
               tb0_en     <= '1';
               rearb_rd   <= '0';
               pa_act_set <= '1';
               pa_act_clr <= '0';
               addr_ns    <= pa_rd_xfer_type;
            else
               tb0_en     <= '0';
               rearb_rd   <= '1';
               pa_act_set <= '0';
               pa_act_clr <= '1';
               addr_ns    <= idle;
            end if;
         elsif sa_active = '1' and plb_rnw_i = '1' and valid_request = '1' and Pi2ad_InitDone_reg2 = '1' then
            sl_addrack_i   <= '0';
            mpmc_addrReq   <= '0';
            wr_new_cmd     <= '0';
            rd_new_cmd     <= '0';
            rearb_wr       <= '0';
            pa_act_set     <= '0';
--            if addr_rd_busy_sm = '1' and rd2ad_rd_cmplt_reg = '0' and sl_rearb_reg = '0' then
            if sl_rearb_reg = '0' then
               tb0_en     <= '1';
               rearb_rd   <= '0';
               sa_act_set <= '1';
               addr_ns    <= sa_rd_xfer_type;
            else
               tb0_en     <= '0';
               rearb_rd   <= '1';
               sa_act_set <= '0';
               addr_ns    <= idle;
            end if;
         else
            sl_addrack_i   <= '0';
            mpmc_addrReq   <= '0';
            wr_new_cmd     <= '0';
            rd_new_cmd     <= '0';

--            if (pa_active = '1' or sa_active = '1') and plb_rnw_i = '1' then
            if (pa_active = '1' ) and plb_rnw_i = '1' and valid_request = '1' then
-- N/A               rearb_rd <= rd_support_busy or not Pi2ad_InitDone_reg2;
               rearb_rd <= not Pi2ad_InitDone_reg2;
            else
               rearb_rd <= '0';
            end if;

            if pa_active = '1' and plb_rnw_i = '0' and valid_request = '1' then
-- N/A               rearb_wr <= addr_wr_busy or not Pi2ad_InitDone_reg2;
               rearb_wr <= not Pi2ad_InitDone_reg2;
            else
               rearb_wr <= '0';
            end if;
            tb0_en     <= '0';
            sa_act_set <= '0';
            pa_act_set <= '0';
            addr_ns    <= idle;
         end if;

       --*************************
       --*****        read portion
       --*************************
      when pa_rd_xfer_type =>
--mw         if sl_rearb_reg = '0' then
            tb0_en       <= '0';
            sa_act_set   <= '0';
            sl_addrack_i <= '1';
            mpmc_addrreq <= '1';
            rd_new_cmd   <= '1';
            pa_act_set   <= '1';
            pa_act_clr   <= '0';
            addr_ns      <= wait_pa_rdsngl_addrack;
--mw         else
--mw            tb0_en       <= '0';
--mw            sa_act_set   <= '0';
--mw            sl_addrack_i <= '0';
--mw            mpmc_addrreq <= '0';
--mw            rd_new_cmd   <= '0';
--mw            pa_act_set   <= '0';
--mw            pa_act_clr   <= '0';
--mw            addr_ns      <= idle;
--mw         end if;

      when  wait_pa_rdsngl_addrack =>
         sl_addrack_i <= '0';
         tb0_en       <= '0';
         rd_new_cmd   <= '0';

         if sa_active = '1' and plb_rnw_i = '1' then
            rearb_rd <= '0';
            sa_act_set <= '1';
         elsif pa_active = '1' and plb_rnw_i = '1' then
            rearb_rd <= '1';
            sa_act_set <= '0';
         else
            rearb_rd <= '0';
            sa_act_set <= '0';
         end if;

         if pa_active = '1' and plb_rnw_i = '0' then
            rearb_wr <= '1';
         else
            rearb_wr <= '0';
         end if;

         if sm_ack = '1' then
            if sa_act_reg = '1' then
               tb0_en       <= '1';
               mpmc_addrreq <= '0';
               sa_act_clr   <= '0';
               pa_act_set   <= '0';
               pa_act_clr   <= '1';
               addr_ns      <= wait_rd2ad_rd_cmplt;
            else
               tb0_en       <= '0';
               mpmc_addrreq <= '1';
               sa_act_clr   <= '1';
               pa_act_set   <= '0';
               pa_act_clr   <= '1';
               addr_ns      <= idle;
            end if;
         else
            tb0_en       <= '0';
            mpmc_addrreq <= '1';
            sa_act_clr   <= '0';
            pa_act_set   <= '1';
            pa_act_clr   <= '0';
            addr_ns      <= wait_pa_rdsngl_addrack;
         end if;

      when wait_rd2ad_rd_cmplt =>
         tb0_en       <= '0';
         wr_new_cmd   <= '0';
         mpmc_addrreq <= '1';

         if pa_active = '1' and pa_act_reg2 = '1' and plb_rnw_i = '1' then
            rearb_rd <= '1'; --reg2 needed to delay 1 clock
         else                --prevents rearbing promoted address
            rearb_rd <= '0'; --after asserting sl_addrack
         end if;

         if pa_active = '1' and plb_rnw_i = '0' then
            rearb_wr <= '1';
         else
            rearb_wr <= '0';
         end if;

         if(sm_ack = '1' and mpmc_pim_rnw = '1') then   --ackd but not promoted
            mpmc_ack_set <= '1';
         else
            mpmc_ack_set <= '0';
         end if;

         if pa_active = '1' and pa_act_reg = '0' and plb_rnw_i = '1' and
            address_hit = '1' then
            sl_addrack_i <= '1';
            pa_act_set   <= '1';
            sa_act_clr   <= '1';
            sa_act_set   <= '0';
         else
            sl_addrack_i <= '0';
            pa_act_set   <= '0';
            sa_act_clr   <= '0';
            if pa_act_reg = '0' then
               sa_act_set <= '1';
            else
               sa_act_set <= '0';
            end if;
         end if;

--         if rd2ad_rd_cmplt_reg = '1' and pa_act_reg = '1' then
         if Rd2ad_rd_cmplt = '1' and pa_act_reg = '1' then
            rd_new_cmd <= '1';
         else
            rd_new_cmd <= '0';
         end if;

--         if rd2ad_rd_cmplt_reg = '1' then
         if Rd2ad_rd_cmplt = '1' then
            -- Do single or cacheline transaction
            addr_ns <= wait_sa_rdsngl_addrack;
         else
            addr_ns <= wait_rd2ad_rd_cmplt;
         end if;

      when sa_rd_xfer_type =>
         tb0_en       <= '0';
         wr_new_cmd   <= '0';
         mpmc_addrreq <= '1';

         if pa_active = '1' and pa_act_reg2 = '1' and plb_rnw_i = '1' then
            rearb_rd <= '1';
         else
            rearb_rd <= '0';
         end if;

         if pa_active = '1' and plb_rnw_i = '0' then
            rearb_wr <= '1';
         else
            rearb_wr <= '0';
         end if;

         if(sm_ack = '1' and mpmc_pim_rnw = '1') then   --ackd but not promoted
            mpmc_ack_set <= '1';
         else
            mpmc_ack_set <= '0';
         end if;

         if pa_active = '1' and pa_act_reg = '0' and plb_rnw_i = '1' and
            address_hit = '1' then
            sl_addrack_i <= '1';
            pa_act_set   <= '1';
            sa_act_clr   <= '1';
            sa_act_set   <= '0';
         else
            sl_addrack_i <= '0';
            pa_act_set   <= '0';
            sa_act_clr   <= '0';
            sa_act_set   <= '1';
         end if;

         if addr_rd_busy_sm = '0' then
--         if addr_rd_busy_sm_reg = '0' then
            -- Do single or cacheline transaction
            rd_new_cmd     <= '1';
            rd_new_cmd_set <= '1';
            addr_ns        <= wait_sa_rdsngl_addrack;
         else
            rd_new_cmd     <= '0';
            rd_new_cmd_set <= '0';
            addr_ns        <= sa_rd_xfer_type;
         end if;

--         if addr_rd_busy_sm = '0' then
--            -- Do single or cacheline transaction
--            addr_ns        <= wait_sa_rdsngl_addrack;
--         else
--            addr_ns        <= sa_rd_xfer_type;
--         end if;
--

      when wait_sa_rdsngl_addrack =>

         tb0_en         <= '0';

--         if pa_act_reg = '1' and pa_act_reg2 = '0' and mpmc_pim_rnw = '1' then  --detect rising edge for pulse
--            rd_new_cmd   <= '1';
--         else
--            rd_new_cmd   <= '0';
--         end if;

         if rd_new_cmd_reg_flag = '1' then
            rd_new_cmd   <= '0';
         elsif pa_act_reg = '1' and pa_act_reg2 = '0' and mpmc_pim_rnw = '1' then  --detect rising edge for pulse
            rd_new_cmd   <= '1';
         else
            rd_new_cmd   <= '0';
         end if;

         wr_new_cmd   <= '0';

         -- rearb the rest of reads, but not the current one
         if (pa_active = '1') and plb_rnw_i = '1' and pa_act_reg2 = '1' then
            rearb_rd <= '1';
         else
            rearb_rd <= '0';
         end if;

         --rearb all writes
         if pa_active = '1' and plb_rnw_i = '0' then
            rearb_wr <= '1';
         else
            rearb_wr <= '0';
         end if;

         if(sm_ack = '1' and mpmc_pim_rnw = '1') then   --ackd but not promoted
            mpmc_ack_set <= '1';
            mpmc_addrreq <= '0';
         elsif mpmc_ack_reg = '1' then
            mpmc_ack_set <= '1';
            mpmc_addrreq <= '0';
         else
            mpmc_ack_set <= '0';
            mpmc_addrreq <= '1';
         end if;

         if pa_active = '1' and pa_act_reg = '0' and plb_rnw_i = '1' and
            address_hit = '1' then
            pa_act_set   <= '1';
            sl_addrack_i <= '1';
         else
            pa_act_set   <= '0';
            sl_addrack_i <= '0';
         end if;

         if ((mpmc_ack_reg = '1' and pa_act_reg = '1')) then
            mpmc_ack_clr   <= '1';
            pa_act_clr     <= '1';
            sa_act_clr     <= '1';
            sa_act_set     <= '0';
            rd_new_cmd_clr <= '1';
            addr_ns        <= idle;
         else
            mpmc_ack_clr   <= '0';
            pa_act_clr     <= '0';
            sa_act_clr     <= '0';
            sa_act_set     <= '1';
            rd_new_cmd_clr <= '0';
            addr_ns        <= wait_sa_rdsngl_addrack;
         end if;

       --*************************
       --*****       write portion
       --*************************

      when initiate_single_wr =>
         sl_addrack_i <= '0';
         mpmc_addrReq <= '1';
         rd_new_cmd   <= '0';
         tb0_en       <= '0';
         sa_act_set   <= '0';
         pa_act_set   <= '0';

         if (pa_active = '1') and plb_rnw_i = '1' then
            rearb_rd <= '1';
         else
            rearb_rd <= '0';
         end if;

         if pa_active = '1' and plb_rnw_i = '0' then
            rearb_wr <= '1';
         else
            rearb_wr <= '0';
         end if;

         if sm_ack = '1' then
            addr_ns     <= idle;
         else
            addr_ns     <= initiate_single_wr;
         end if;

      when initiate_inbndry_wr =>
         sl_addrack_i <= '0';
         mpmc_addrReq <= '0';

         wr_new_cmd   <= '1';
         rd_new_cmd   <= '0';

         tb0_en       <= '0';

         sa_act_set   <= '0';
         pa_act_set   <= '0';

         addr_ns      <= wait_wr_cmplt;


      when wait_wr_cmplt =>
         sl_addrack_i <= '0';
         wr_new_cmd   <= '0';
         rd_new_cmd   <= '0';

         if (pa_active = '1') and plb_rnw_i = '1' then
            rearb_rd <= '1';
         else
            rearb_rd <= '0';
         end if;

         if pa_active = '1' and plb_rnw_i = '0' then
            rearb_wr <= '1';
         else
            rearb_wr <= '0';
         end if;

         tb0_en       <= '0';

         sa_act_set   <= '0';
         pa_act_set   <= '0';

         if Wr2ad_wr_cmplt = '1' and sm_ack = '1' then
            mpmc_addrReq <= '1';
            addr_ns      <= idle;
         elsif Wr2ad_wr_cmplt = '1' then
            mpmc_addrReq <= '1';
            addr_ns      <= wait_wr_sngl_ack;
         else
            mpmc_addrReq <= '0';
            addr_ns      <= wait_wr_cmplt;
         end if;

      when wait_wr_sngl_ack =>
         sl_addrack_i <= '0';
         mpmc_addrReq <= '1';
         wr_new_cmd   <= '0';

         if (pa_active = '1') and plb_rnw_i = '1' then
            rearb_rd <= '1';
         else
            rearb_rd <= '0';
         end if;

         if pa_active = '1' and plb_rnw_i = '0' then
            rearb_wr <= '1';
         else
            rearb_wr <= '0';
         end if;

         if sm_ack = '1' then
            addr_ns <= idle;
         else
            addr_ns <= wait_wr_sngl_ack;
         end if;

      when others =>
            addr_ns <= idle;
   end case;
end process;

-------------------------------------------------------------------------------
-- Address Decoder State Machine Sequencer
-------------------------------------------------------------------------------
ADDR_SM_SEQ : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         addr_cs <= idle;
      else
         addr_cs <= addr_ns;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Register output to state machine indicating when secondary address is valid
-- The set and reset signals are driven from the state machine
-------------------------------------------------------------------------------
SA_ACTIVE_LOAD_REG : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if sa_act_clr = '1' or plb_rst = '1' then
         sa_act_reg <= '0';
      elsif sa_act_set = '1' then
         sa_act_reg <= '1';
      else
         sa_act_reg <= sa_act_reg;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Register output to state machine indicating when MPMC has ackd a request
-- This signal is used in the secondary address states of the state machine
-- The set and reset signals are driven from the state machine
-------------------------------------------------------------------------------
SA_ACTIVE_ACK_FLAG : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if mpmc_ack_clr = '1' or plb_rst = '1' then
         mpmc_ack_reg <= '0';
      elsif mpmc_ack_set = '1' then
         mpmc_ack_reg <= '1';
      else
         mpmc_ack_reg <= mpmc_ack_reg;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Register output to state machine used to filter out subsequent generation of
-- the rd_new_cmd signal.
-- This signal is used in the secondary address states of the state machine
-- The set and reset signals are driven from the state machine
-------------------------------------------------------------------------------
RD_NEW_CMD_FLAG : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if rd_new_cmd_clr = '1' or plb_rst = '1' then
         rd_new_cmd_reg_flag <= '0';
      elsif rd_new_cmd_set = '1' then
         rd_new_cmd_reg_flag <= '1';
      else
         rd_new_cmd_reg_flag <= rd_new_cmd_reg_flag;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Register output to state machine used to indicate when the primary address
-- is active on read transactions
-- This signal is used in the secondary address states of the state machine
-- The set and reset signals are driven from the state machine
-------------------------------------------------------------------------------
PA_ACTIVE_FLAG : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if pa_act_clr = '1' or plb_rst = '1' then
         pa_act_reg <= '0';
      elsif pa_act_set = '1' then
         pa_act_reg <= '1';
      else
         pa_act_reg <= pa_act_reg;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Register output to state machine used to indicate when the primary address
-- is active on read transactions for edge detection
-- This signal is used in the secondary address states of the state machine
-------------------------------------------------------------------------------
READ_BURST_PA_ACTIVE_FLAG2 : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if pa_act_clr = '1' or plb_rst = '1' then
         pa_act_reg2 <= '0';
      else
         pa_act_reg2 <= pa_act_reg;
      end if;
   end if;
end process;

sl_rearb_i <= (rearb_wr or rearb_rd)
            when
               (Plb_PAValid = '1' and
                (sl_addrack_reg = '0' and sl_addrack_reg2 = '0')) else '0';

-------------------------------------------------------------------------------
-- Register State machine signals
-------------------------------------------------------------------------------
REG_SM_SIGNALS : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         wr_new_cmd_reg     <= '0';
         rd_new_cmd_reg     <= '0';
         sl_addrack_reg     <= '0';
         sl_addrack_reg2    <= '0';
         sl_rearb_reg       <= '0';
      else
         wr_new_cmd_reg     <= wr_new_cmd    ;
         rd_new_cmd_reg     <= rd_new_cmd    ;

         if (sl_addrack_i = '1' and sl_rearb_reg = '0') then
            sl_addrack_reg     <= '1';
         else
            sl_addrack_reg <= '0';
         end if;
         sl_addrack_reg2 <= sl_addrack_reg;

         if (sl_rearb_i = '1' and sl_rearb_reg = '0' ) and (sl_addrack_i = '0' and sl_addrack_reg = '0')then
            sl_rearb_reg <=  '1';
         else
            sl_rearb_reg <= '0';
         end if;

      end if;
   end if;
end process;


   wr_new_cmd_mux <= sm_ack when (single_reg = '1' and mpmc_pim_rnw = '0') else wr_new_cmd_reg;--to decrease latency on singles

-------------------------------------------------------------------------------
-- Sample and hold register for size control signals goint to rd/wr modules
-------------------------------------------------------------------------------
SIZE_CONTROL_S_H : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         single_reg      <= '0';
         cacheline_8_reg <= '0';
      elsif tb0_en = '1' then
         single_reg      <= single;
         cacheline_8_reg <= cacheline_8;
      else
         single_reg      <= single_reg     ;
         cacheline_8_reg <= cacheline_8_reg;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Send the full address to the read and write modules aligned with *_new_cmd
-------------------------------------------------------------------------------
START_ADDR_RD_WR_MODULES2 : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         rd_wr_module_addr <= (others => '0');
      else
         if tb0_en = '1' then
            rd_wr_module_addr <= plb_abus_i;
         else
            rd_wr_module_addr <= rd_wr_module_addr;
         end if;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Register mpmc_addrreq from the state machine and use the delayed version to
-- set the address request to MPMC.
-------------------------------------------------------------------------------
REG_REQ : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         mpmc_addrReq_reg <= '0';
      else
         mpmc_addrReq_reg <= mpmc_addrReq;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
--  Register MPMC's Pi2ad_AddrAck signal.  Use the delayed version to
--  asynchronously clear the address request to MPMC
-------------------------------------------------------------------------------
REG_ADDRACK : process(Pi_Clk)
begin

   if rising_edge(Pi_Clk) then
      Pi2ad_AddrAck_reg <= Pi2ad_AddrAck;
   end if;
end process;

-------------------------------------------------------------------------------
-- Set the MPMC Address request at the first assertion Sample cycle after
-- mpmc_addrReq is asserted.  Clear the request when MPMC addrAcks.
-------------------------------------------------------------------------------
REG_REQ2 : process(Pi_Clk)
begin

   if rising_edge(Pi_Clk) then
      if plb_rst = '1' or Pi2ad_AddrAck = '1' then
         mpmc_addrReq_reg2 <= '0';
      elsif mpmc_addrReq = '1' and mpmc_addrReq_reg = '0' and sc2ad_sample_cycle = '1' then
         mpmc_addrReq_reg2 <= '1';
      else
         mpmc_addrReq_reg2 <= mpmc_addrReq_reg2;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
--  Process for detecting when the MPMC addrAcked.
--  It is set with MPMC's Pi2ad_AddrAck and held until the state machine
--  acknowledge has been generated and sample cycle has been asserted.
-------------------------------------------------------------------------------
ACKD_REQ : process(Pi_Clk)
begin

   if rising_edge(Pi_Clk) then
      if plb_rst = '1' then
          mpmc_ackd_req <= '0';
      elsif Pi2ad_AddrAck = '1' then
         mpmc_ackd_req <= '1';
      elsif sm_ack = '1' and sc2ad_sample_cycle = '1' then
          mpmc_ackd_req <= '0';
      else
         mpmc_ackd_req <= mpmc_ackd_req;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Take the MPMC addrAck that is at the same or faster clock frequency than the
-- plb clock and generate an acknowledge for the state machine in the PLB clock
-- domain
-------------------------------------------------------------------------------
REG_REQ2Sm : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if sc2ad_sample_cycle = '1' then
         if Pi2ad_AddrAck = '1' then
            sm_ack <= '1';
         elsif (sm_ack = '0' and mpmc_ackd_req = '1' and mpmc_addrReq = '1') then
            sm_ack <= '1';
         else
            sm_ack <= '0';
         end if;
      else
         sm_ack <= sm_ack;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
--  Cross clock boundaries from MPMC fast clock to PLB slow clock at
--  sample cycle
-------------------------------------------------------------------------------
REG_WRFIFO_ALMOSTFULL : process(Pi_Clk)
begin

   if rising_edge(Pi_Clk) then
      if sc2ad_sample_cycle = '1' then
         Pi2ad_wrfifo_almostFull_reg <= Pi2ad_wrfifo_almostFull;
      else
         Pi2ad_wrfifo_almostFull_reg <= Pi2ad_wrfifo_almostFull_reg;
      end if;
   end if;
end process;



-------------------------------------------------------------------------------
-- Read Modify Write Logic
-------------------------------------------------------------------------------
--
-- For write transactions where byte enables are not all on or all off across
-- the ECC word size, a read-modify-write transactions is needed. This requires
-- you to dynamically set a signal called MPMC2_PIM_<PortNum>_RdModWr when
-- you assert AddrReq as needed. For example if DDR mem is 32 bits wide, SDR
-- bus inside MPMC is 64 bits. Ecc word size is 64 bits. On a single word
-- transactions, byte enables may not be all on or all off over 64 bits so
-- RdModWr = 1. On a burst of doublewords, byte enables are all on so
-- RdModWr = 0. On a burst of words, RdModWr is 0 if start address is
-- doubleword aligned and number of words is even number else RdModWr=1.
-- If you are unsure of a setting, setting RdModWr to 1 is the safest setting.
-------------------------------------------------------------------------------
RMW_DETECT : process (cacheline_8)


begin

   if cacheline_8 = '1' then
      rdmodwr_i <= '0';
   else
      rdmodwr_i <= '1';
   end if;
end process;
--RMW_DETECT : process (plb_msize_i, cacheline_4,cacheline_8,
--                      burst,plb_abus_i,xfer_wdcnt)
--begin
--   case plb_msize_i is
--      when "00" =>
--         if cacheline_4 = '1' or cacheline_8 = '1' then
--            rdmodwr_i <= '0';
--         elsif burst = '1' and
--               (plb_abus_i(29) = '0' and xfer_wdcnt(xwc_msb) = '0') then
--            rdmodwr_i <= '0'; --burst and dwd aligned and even number of transfers
--         else
--            rdmodwr_i <= '1';
--         end if;
--      when "01" | "10" =>
--         if cacheline_4 = '1' or cacheline_8 = '1' then
--            rdmodwr_i <= '0';
--         elsif burst = '1' then
----         elsif burst = '1' and
----               (plb_abus_i(29) = '0' and xfer_wdcnt(xwc_msb) = '0') then
--
--            rdmodwr_i <= '0';
--         else
--            rdmodwr_i <= '1';
--         end if;
--      when others => null;
--   end case;
--end process;
--




-------------------------------------------------------------------------------
-- Sample and Hold rnw for the initial transfer
-------------------------------------------------------------------------------
RMW_THROTTLE_BUF0 : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         rdmodwr_tb0_q <= '0';
      else
         if tb0_en = '1' then
            rdmodwr_tb0_q <= rdmodwr_i;
         else
            rdmodwr_tb0_q <= rdmodwr_tb0_q;
         end if;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- Mux appropriate rnw signal if a word block boundary is crossed
-------------------------------------------------------------------------------
MUX_PRIMARY_RMW : process(rdmodwr_tb0_q)
begin

   Ad2pi_RdModWr <= rdmodwr_tb0_q;
end process;


-------------------------------------------------------------------------------
-- do not allow the state machine to start until MPMC initialization is complete
-- Sync signal with plb clock
-------------------------------------------------------------------------------
Initialization_Done : process(pi_clk)
begin

   if rising_edge(pi_clk) then
      if plb_rst = '1' then
         Pi2ad_InitDone_reg <= '0';
      else
         if sc2ad_sample_cycle = '1' then
            Pi2ad_InitDone_reg <= Pi2ad_InitDone;
         else
            Pi2ad_InitDone_reg <= Pi2ad_InitDone_reg;
         end if;
      end if;
   end if;
end process;

-------------------------------------------------------------------------------
-- do not allow the state machine to start until MPMC initialization is complete
-- Sync signal with plb clock
--  Added to fix multi-cycle path
-------------------------------------------------------------------------------
Initialization_Done_PLB_Rate : process(splb_clk)
begin

   if rising_edge(splb_clk) then
      if plb_rst = '1' then
         Pi2ad_InitDone_reg2 <= '0';
      else
         Pi2ad_InitDone_reg2 <= Pi2ad_InitDone_reg;
      end if;
   end if;
end process;


end RTL;




