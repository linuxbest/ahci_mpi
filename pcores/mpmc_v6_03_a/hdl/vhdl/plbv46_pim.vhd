-------------------------------------------------------------------------------
-- plbv46_pim.vhd - entity/architecture pair
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
-- Filename:        plbv46_pim.vhd
-- Version:         v1.00a
-- Description:     Top level file for plbv46_pim
--
-- VHDL-Standard:   VHDL'93
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
-------------------------------------------------------------------------------
-- Author:      MW
-- History:
--  MW        01/10/2007      - Initial Version
--
--  MW        04/16/2007      - Added InitDone
--
--  MW        06/19/2007      - Added DSPLB optimization support
--                               - DSPLB will be selected even when
--                                 ISPLB or Singles is set in MPMC
--                                 until the ISPLB and Singles optimizations
--                                 can be developed and tested.
--                               - 4 word cachelines will initially be
--                                 supported in DSPLB until ISPLB is completed.
--                                 Then 4 wd caheline transactions will be
--                                 optimized out of the DSPLB design.
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
--       - Added MPMC_PIM_InitDone
-- ^^^^^^
--
--       MW        06/19/2007   - Initial Version
-- ~~~~~~
--       - Added DSPLB optimization support
-- ^^^^^^
--
--       MW        07/02/2007   - Initial Version
-- ~~~~~~
--     - Added Ad2rd_queue_data to hold off read pops until sa_valid address
--       is promoted to pa_valid and address decoder addracks
-- ^^^^^^
--
--
--       MW        08/02/2007   - Initial Version
-- ~~~~~~
--     - Added sync_mpmc_rst and sync_plb_rst to modules for timing.
--       These are pipeline delayed 2x at the repective clock.
-- ^^^^^^
--
--
--       MW        08/02/2007   - Initial Version
-- ~~~~~~
--     - Fixed the following false timing error paths when crossing clock
--       boundaries:
--       Address_decoder modules - sm_ack
--       Read Modules - sig_sl_rdack, sig_plb_rd_dreg, sig_plb_rdwdaddr_reg,
--                      sig_rdcomp_reg, sig_sl_rdbterm
--       Write Module - write path when BRAM FIFO
-- ^^^^^^
--
--       MW        08/27/2007   - Initial Version
-- ~~~~~~
--     - Added Ad2rd_clk_ratio_1_1 to Address_decoder*.vhd and rd_support*.vhd
--        ports
--     - Added new Singles only design modules for both the 32 and 64 bit PIMs
--        - Reduced logic
-- ^^^^^^
--
--     MW      09/17/2007    plbv46_pim_v2_00_a - Release 10.1
-- ~~~~~~
--     - Added Ad2rd_wdblk_xings to address_decoder and rd_support Ports for
--       read module state machine.  This fixes a testbench hang due to read
--       data from subsequent transaction being flushed when a read
--       on SAValid has been asserted for a long time.  Testbench did not take
--       into account memory width and MPMC latency on read, so this is very
--       unlikely to occur in HW.  It was added for robustness though.
-- ^^^^^^
--
--     MW      02/01/2008    plbv46_pim_v2_01_a - Release 10.1 SP1
-- ~~~~~~
--     - Increased throughput on the read module by making a change the
--       address decoder state machine
--     - Increased throughput on the write module for when the FIFO type
--       is BRAM
--        - In the SRL case, the write module will prevent the address
--          decoder from accepting the next PLB transaction until the
--          write FIFO Empty flag is asserted high
--        - In the BRAM case the write module will prevent the address
--          decoder from accepting the next PLB transaction until the
--          PLB data has been written to the write FIFO.  It will not wait
--          for the Empty flag to be asserted
--     - In the address decoder module the generate statements did not
--       take into account all of the parameter scenerios, and this
--       caused some errors in the future Xilinx parser.  This is fixed now.
--       This is not an issue with any of the current tools, and HW builds
--       work fine.
--     - Added C_SPLB_PIPE_STAGES parameter
--     - Removed Async reset in address decoder
-- ^^^^^^
--
--     MW      06/05/2008    plbv46_pim_v2_02_a - Release 11 
-- ~~~~~~
--    -  Removed dependancies on proc_common
-- ^^^^^^
--
--     MW      04/03/2009    _plbv46_pim_v2_03_a_  
-- ~~~~~~
--    -  CR#507838
--       -  Changed sample_cycle.vhd to use MAX_FANOUT Attribute setting
--          of 30 on the reset signal plb_rst_pipe
-- ^^^^^^
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

library mpmc_v6_03_a;
use mpmc_v6_03_a.all;


entity plbv46_pim is
   generic (

         --PLB to PIM generics
         C_SPLB_DWIDTH                      : integer range 32 to 128 := 64;
         C_SPLB_NATIVE_DWIDTH               : integer range 32 to 128 := 64;
         C_SPLB_AWIDTH                      : integer                 := 32;
         C_SPLB_NUM_MASTERS                 : integer range 1 to 16   := 8;
         C_SPLB_MID_WIDTH                   : integer range 0 to 4    := 3;
         C_SPLB_P2P                         : integer range 0 to 1    := 0;
         C_SPLB_SUPPORT_BURSTS              : integer range 0 to 1    := 0;
         C_SPLB_SMALLEST_MASTER             : integer range 32 to 128 := 128;
         C_SPLB_PIPE_STAGES                 : integer range 0 to 1    := 1;

         C_PLBV46_PIM_TYPE                  : string                  := "PLB"; --PLB,DPLB,IPLB

         --MPMC generics
         C_MPMC_PIM_BASEADDR                : std_logic_vector        := x"00000000";
         C_MPMC_PIM_HIGHADDR                : std_logic_vector        := x"FFFFFFFF";
         C_MPMC_PIM_OFFSET                  : std_logic_vector        := x"00000000";
         C_MPMC_PIM_DATA_WIDTH              : integer range 32 to 64  := 64;
         C_MPMC_PIM_ADDR_WIDTH              : integer                 := 32;
         C_MPMC_PIM_RDFIFO_LATENCY          : integer range 0 to 2    := 0;
         C_MPMC_PIM_RDWDADDR_WIDTH          : integer                 := 4;
         C_MPMC_PIM_SDR_DWIDTH              : integer range 8 to 128  := 128;
         C_MPMC_PIM_MEM_HAS_BE              : integer range 0 to 1    := 1;
         C_MPMC_PIM_WR_FIFO_TYPE            : string                  := "BRAM";--BRAM, SRL
         C_MPMC_PIM_RD_FIFO_TYPE            : string                  := "BRAM";--BRAM, SRL

         --Misc Generics
         C_FAMILY                           : string                  := "virtex5"

     );
     port (
         MPMC_CLK                           : in    std_logic;
         MPMC_Rst                           : in    std_logic;
         SPLB_RST                           : in    std_logic;
         SPLB_Clk                           : in    std_logic;

         SPLB_PLB_ABus                      : in    std_logic_vector (0 to C_SPLB_AWIDTH-1);
         SPLB_PLB_UABus                     : in    std_logic_vector (0 to C_SPLB_AWIDTH-1);        -- (Note: Unused)
         SPLB_PLB_PAValid                   : in    std_logic;
         SPLB_PLB_SAValid                   : in    std_logic;
         SPLB_PLB_rdPrim                    : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_wrPrim                    : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_masterID                  : in    std_logic_vector (0 to C_SPLB_MID_WIDTH-1);
         SPLB_PLB_abort                     : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_busLock                   : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_RNW                       : in    std_logic;
         SPLB_PLB_BE                        : in    std_logic_vector (0 to (C_SPLB_DWIDTH/8)-1);

         SPLB_PLB_MSize                     : in    std_logic_vector (0 to 1);
         SPLB_PLB_size                      : in    std_logic_vector (0 to 3);  --PLB transfer size word,dw,qwd
         SPLB_PLB_type                      : in    std_logic_vector (0 to 2);  --always 000 - memory transfer
         SPLB_PLB_lockErr                   : in    std_logic;                                      -- (Note: Unused)

         SPLB_PLB_wrDBus                    : in    std_logic_vector (0 to C_SPLB_DWIDTH-1);
         SPLB_PLB_wrBurst                   : in    std_logic;
         SPLB_PLB_rdBurst                   : in    std_logic;
         SPLB_PLB_wrPendReq                 : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_rdPendReq                 : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_rdPendPri                 : in    std_logic_vector (0 to 1);                      -- (Note: Unused)
         SPLB_PLB_wrPendPri                 : in    std_logic_vector (0 to 1);                      -- (Note: Unused)
         SPLB_PLB_reqPri                    : in    std_logic_vector (0 to 1);                      -- (Note: Unused)
         SPLB_PLB_TAttribute                : in    std_logic_vector (0 to 15);                     -- (Note: Unused)

         SPLB_Sl_addrAck                    : out   std_logic;
         SPLB_Sl_SSize                      : out   std_logic_vector (0 to 1);
         SPLB_Sl_wait                       : out   std_logic;
         SPLB_Sl_rearbitrate                : out   std_logic;
         SPLB_Sl_wrDack                     : out   std_logic;
         SPLB_Sl_wrComp                     : out   std_logic;
         SPLB_Sl_wrBTerm                    : out   std_logic;
         SPLB_Sl_rdDBus                     : out   std_logic_vector (0 to C_SPLB_DWIDTH-1);

         SPLB_Sl_rdWdAddr                   : out   std_logic_vector (0 to 3);
         SPLB_Sl_rdDAck                     : out   std_logic;
         SPLB_Sl_rdComp                     : out   std_logic;
         SPLB_Sl_rdBTerm                    : out   std_logic;
         SPLB_Sl_MBusy                      : out   std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);
         SPLB_Sl_MRdErr                     : out   std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);  -- (Note: Unused)
         SPLB_Sl_MWrErr                     : out   std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);  -- (Note: Unused)
         SPLB_Sl_MIRQ                       : out   std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);  -- (Note: Unused)

         MPMC_PIM_InitDone                  : in    std_logic;
         MPMC_PIM_Addr                      : out   std_logic_vector(C_MPMC_PIM_ADDR_WIDTH-1 downto 0);
         MPMC_PIM_AddrReq                   : out   std_logic;
         MPMC_PIM_AddrAck                   : in    std_logic;
         MPMC_PIM_RNW                       : out   std_logic;
         MPMC_PIM_Size                      : out   std_logic_vector(3 downto 0);

         MPMC_PIM_WrFIFO_Data               : out   std_logic_vector(C_MPMC_PIM_DATA_WIDTH-1 downto 0);
         MPMC_PIM_WrFIFO_BE                 : out   std_logic_vector(C_MPMC_PIM_DATA_WIDTH/8-1 downto 0);
         MPMC_PIM_WrFIFO_Push               : out   std_logic;
         MPMC_PIM_WrFIFO_Empty              : in    std_logic;
         MPMC_PIM_WrFIFO_AlmostFull         : in    std_logic;

         MPMC_PIM_RdFIFO_Latency            : in    std_logic_vector(1 downto 0);
         MPMC_PIM_RdFIFO_Data               : in    std_logic_vector(C_MPMC_PIM_DATA_WIDTH-1 downto 0);
         MPMC_PIM_RdFIFO_Pop                : out   std_logic;
         MPMC_PIM_RdFIFO_Empty              : in    std_logic;
         MPMC_PIM_RdFIFO_RdWd_Addr          : in    std_logic_vector(C_MPMC_PIM_RDWDADDR_WIDTH-1 downto 0);

         MPMC_PIM_RdFIFO_Data_Available     : in    std_logic;
         MPMC_PIM_RdFIFO_Flush              : out   std_logic;
         MPMC_PIM_WrFIFO_Flush              : out   std_logic;

         MPMC_PIM_RdModWr                   : out   std_logic


     );

end plbv46_pim;

architecture rtl_pim of plbv46_pim is

--Constant declarations





begin

-------------------------------------------------------------------------------
-- Generate PLB Slave single transfer logic if port type is plb and bursts are
-- not supported.
-------------------------------------------------------------------------------
GENERATE_PLB_PLBV46_PIM :
   IF (C_PLBV46_PIM_TYPE = "PLB" and C_SPLB_SUPPORT_BURSTS = 1) generate

      --Signal Declarations
      signal Ad2Wr_PLB_NPI_Sync   : std_logic;
      signal Ad2Rd_PLB_NPI_Sync   : std_logic;
      signal sync_rst             : std_logic;
      signal Rd2ad_rd_cmplt       : std_logic;
      signal Rd2ad_busy           : std_logic;
      signal Rd2Ad_Rd_Data_Cmplt     : std_logic;

      signal Ad2rd_new_cmd        : std_logic;
      signal Ad2rd_mid            : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      signal Ad2rd_strt_addr      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
      signal Ad2rd_single         : std_logic;
      signal Ad2rd_cacheline_4    : std_logic;
      signal Ad2rd_cacheline_8    : std_logic;
      signal Ad2rd_burst_16       : std_logic;
      signal Ad2rd_burst_32       : std_logic;
      signal Ad2rd_burst_64       : std_logic;

      signal Ad2rd_xfer_wdcnt     : std_logic_vector(0 to 7);
      signal Ad2rd_xfer_width     : std_logic_vector(0 to 1);

      signal Wr2ad_wr_cmplt       : std_logic;
      signal Wr2ad_busy           : std_logic;
      signal Wr2ad_error          : std_logic;

      signal Ad2wr_new_cmd        : std_logic;
      signal Ad2wr_mid            : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      signal Ad2wr_strt_addr      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
      signal Ad2wr_single         : std_logic;
      signal Ad2wr_cacheline_4    : std_logic;
      signal Ad2wr_cacheline_8    : std_logic;
      signal Ad2wr_burst_16       : std_logic;
      signal Ad2wr_burst_32       : std_logic;
      signal Ad2wr_burst_64       : std_logic;
      signal Ad2wr_wrbe           : std_logic_vector(0 to C_MPMC_PIM_DATA_WIDTH/8-1);

      signal Ad2wr_xfer_wrdcnt    : std_logic_vector(0 to 7);
      signal Ad2wr_xfer_width     : std_logic_vector(0 to 1);

      signal Wr2ad_block_infifo   : std_logic;

      signal Rd2Ad_Rd_Error       : std_logic;

      signal Ad2rd_queue_data     : std_logic;
      signal Ad2rd_wdblk_xings    : std_logic_vector(0 to 2);

      signal sync_mpmc_rst        : std_logic;
      signal sync_plb_rst         : std_logic;

      signal Ad2Rd_clk_ratio_1_1  : std_logic;
      signal Ad2Wr_clk_ratio_1_1  : std_logic;
begin


   PIM_ADDRESS_DECODER :  entity mpmc_v6_03_a.plbv46_address_decoder
      generic map
      (
         --IPIC generics
         C_SPLB_DWIDTH                   => C_SPLB_DWIDTH                      ,
         C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH               ,
         C_SPLB_AWIDTH                   => C_SPLB_AWIDTH                      ,
         C_SPLB_NUM_MASTERS              => C_SPLB_NUM_MASTERS                 ,
         C_SPLB_MID_WIDTH                => C_SPLB_MID_WIDTH                   ,
         C_SPLB_P2P                      => C_SPLB_P2P                         ,
         C_SPLB_SUPPORT_BURSTS           => C_SPLB_SUPPORT_BURSTS              ,
         C_SPLB_SMALLEST_MASTER          => C_SPLB_SMALLEST_MASTER             ,

         C_PLBV46_PIM_TYPE               => C_PLBV46_PIM_TYPE                  ,
         --MPMC generics
         C_MPMC_PIM_BASEADDR             => C_MPMC_PIM_BASEADDR                ,
         C_MPMC_PIM_HIGHADDR             => C_MPMC_PIM_HIGHADDR                ,
         C_MPMC_PIM_OFFSET               => C_MPMC_PIM_OFFSET                  ,
         C_MPMC_PIM_DATA_WIDTH           => C_MPMC_PIM_DATA_WIDTH              ,
         C_MPMC_PIM_ADDR_WIDTH           => C_MPMC_PIM_ADDR_WIDTH              ,
         C_MPMC_PIM_RDFIFO_LATENCY       => C_MPMC_PIM_RDFIFO_LATENCY          ,
         C_MPMC_PIM_RDWDADDR_WIDTH       => C_MPMC_PIM_RDWDADDR_WIDTH          ,
         C_MPMC_PIM_SDR_DWIDTH           => C_MPMC_PIM_SDR_DWIDTH              ,
         C_MPMC_PIM_MEM_HAS_BE           => C_MPMC_PIM_MEM_HAS_BE              ,
         --Misc Generics
         C_FAMILY                        => C_FAMILY
      )
      port map
      (
         -- System signals ----------------------------------------------------
         Splb_Clk                        => SPLB_Clk                           ,
         Splb_Rst                        => SPLB_Rst                           ,
         Pi_Clk                          => MPMC_Clk                           ,
         Pi_rst                          => MPMC_Rst                           ,

         sync_rst                        => sync_rst                           ,
         sync_mpmc_rst                   => sync_mpmc_rst                      ,
         sync_plb_rst                    => sync_plb_rst                       ,
         -- PLB signals -------------------------------------------------------
         Plb_ABus                        => SPLB_PLB_ABus                      ,
         Plb_PAValid                     => SPLB_PLB_PAValid                   ,
         Plb_SAValid                     => SPLB_PLB_SAValid                   ,
         Plb_masterID                    => SPLB_PLB_masterID                  ,
         Plb_MSize                       => SPLB_PLB_MSize                     ,
         Plb_size                        => SPLB_PLB_size                      ,
         Plb_type                        => SPLB_PLB_type                      ,

         Plb_RNW                         => SPLB_PLB_RNW                       ,
         Plb_BE                          => SPLB_PLB_BE                        ,
         Plb_wrBurst                     => SPLB_PLB_wrBurst                   ,
         Plb_rdBurst                     => SPLB_PLB_rdBurst                   ,

         -- PLB Slave Response Signals
         Sl_addrAck                      => SPLB_Sl_addrAck                    ,
         Sl_SSize                        => SPLB_Sl_SSize                      ,
         Sl_wait                         => SPLB_Sl_wait                       ,
         Sl_rearbitrate                  => SPLB_Sl_rearbitrate                ,
         Sl_MBusy                        => SPLB_Sl_MBusy                      ,

         -- PIM Interconnect port signals -------------------------------------
         Pi2ad_InitDone                  => MPMC_PIM_InitDone                  ,
         Pi2ad_AddrAck                   => MPMC_PIM_AddrAck                   ,
         Pi2ad_wrfifo_almostFull         => MPMC_PIM_WrFIFO_AlmostFull         ,
         Pi2ad_wrFifo_empty              => MPMC_PIM_WrFIFO_Empty              ,
         Ad2pi_Addr                      => MPMC_PIM_Addr                      ,
         Ad2pi_AddrReq                   => MPMC_PIM_AddrReq                   ,
         Ad2pi_RNW                       => MPMC_PIM_RNW                       ,
         Ad2pi_Size                      => MPMC_PIM_Size                      ,

         -- Read Support Module signals ---------------------------------------
         Rd2ad_rd_cmplt                  => Rd2ad_rd_cmplt                     ,
         Rd2Ad_Rd_Data_Cmplt             => Rd2Ad_Rd_Data_Cmplt                ,
         Rd2ad_busy                      => Rd2ad_busy                         ,
         Rd2Ad_Rd_Error                  => Rd2Ad_Rd_Error                     ,

         Ad2rd_plb_npi_sync              => Ad2rd_plb_npi_sync                 ,
         Ad2rd_new_cmd                   => Ad2rd_new_cmd                      ,
         Ad2rd_mid                       => Ad2rd_mid                          ,
         Ad2rd_strt_addr                 => Ad2rd_strt_addr                    ,
         Ad2rd_single                    => Ad2rd_single                       ,
         Ad2rd_cacheline_4               => Ad2rd_cacheline_4                  ,
         Ad2rd_cacheline_8               => Ad2rd_cacheline_8                  ,
         Ad2rd_burst_16                  => Ad2rd_burst_16                     ,
         Ad2rd_burst_32                  => Ad2rd_burst_32                     ,
         Ad2rd_burst_64                  => Ad2rd_burst_64                     ,

         Ad2rd_xfer_wdcnt                => Ad2rd_xfer_wdcnt                   ,
         Ad2rd_xfer_width                => Ad2rd_xfer_width                   ,
         Ad2rd_queue_data                => Ad2rd_queue_data                   ,
         Ad2rd_wdblk_xings               => Ad2rd_wdblk_xings                  ,
         Ad2Rd_clk_ratio_1_1             => Ad2Rd_clk_ratio_1_1                ,


         -- Write Support Module signals --------------------------------------
         Wr2ad_block_infifo              => Wr2ad_block_infifo                 ,
         Wr2ad_wr_cmplt                  => Wr2ad_wr_cmplt                     ,
         Wr2ad_busy                      => Wr2ad_busy                         ,
         Wr2ad_error                     => Wr2ad_error                        ,

         Ad2wr_plb_npi_sync              => Ad2wr_plb_npi_sync                 ,
         Ad2wr_new_cmd                   => Ad2wr_new_cmd                      ,
         Ad2wr_mid                       => Ad2wr_mid                          ,
         Ad2wr_strt_addr                 => Ad2wr_strt_addr                    ,
         Ad2wr_single                    => Ad2wr_single                       ,
         Ad2wr_cacheline_4               => Ad2wr_cacheline_4                  ,
         Ad2wr_cacheline_8               => Ad2wr_cacheline_8                  ,
         Ad2wr_burst_16                  => Ad2wr_burst_16                     ,
         Ad2wr_burst_32                  => Ad2wr_burst_32                     ,
         Ad2wr_burst_64                  => Ad2wr_burst_64                     ,
         Ad2wr_wrbe                      => Ad2wr_wrbe                         ,

         Ad2wr_xfer_wrdcnt               => Ad2wr_xfer_wrdcnt                  ,
         Ad2wr_xfer_width                => Ad2wr_xfer_width                   ,
         Ad2Wr_clk_ratio_1_1             => Ad2Wr_clk_ratio_1_1                ,

         -- ECC signals -------------------------------------------------------
         Ad2pi_RdModWr                   => MPMC_PIM_RdModWr

     );


   PIM_WRITE_MODULE :  entity mpmc_v6_03_a.plbv46_write_module
      generic map
      (
      --IPIC generics
      -------------------------------------------------------------------------
         C_SPLB_MID_WIDTH                => C_SPLB_MID_WIDTH                   ,
         C_SPLB_NUM_MASTERS              => C_SPLB_NUM_MASTERS                 ,
         C_SPLB_SMALLEST_MASTER          => C_SPLB_SMALLEST_MASTER             ,
         C_SPLB_AWIDTH                   => C_SPLB_AWIDTH                      ,
         C_SPLB_DWIDTH                   => C_SPLB_DWIDTH                      ,
         C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH               ,
         C_PLBV46_PIM_TYPE               => C_PLBV46_PIM_TYPE                  ,
         C_MPMC_WR_FIFO_TYPE             => C_MPMC_PIM_WR_FIFO_TYPE            ,
         C_SPLB_SUPPORT_BURSTS           => C_SPLB_SUPPORT_BURSTS              ,
         C_MPMC_PIM_DATA_WIDTH           => C_MPMC_PIM_DATA_WIDTH
      )
      port map
      (
         SPLB_Clk                        => SPLB_Clk                           ,
         PI_Clk                          => MPMC_Clk                           ,
         Sync_Mpmc_Rst                   => Sync_Mpmc_Rst                      ,
         Sync_Plb_Rst                    => Sync_Plb_Rst                       ,

         -- PLB Write Interface
         PLB_wrDBus                      => SPLB_PLB_wrDBus                    ,
         PLB_wrBurst                     => SPLB_PLB_wrBurst                   ,
         Sl_wrDAck                       => SPLB_Sl_wrDack                     ,
         Sl_wrComp                       => SPLB_Sl_wrComp                     ,
         Sl_wrBTerm                      => SPLB_Sl_wrBTerm                    ,
         Sl_MWrErr                       => SPLB_Sl_MWrErr                     ,
         Sl_MIRQ                         => SPLB_Sl_MIRQ                       ,

         -- Address Module Interface
         Ad2Wr_PLB_NPI_Sync              => Ad2Wr_PLB_NPI_Sync                 ,
         Ad2Wr_New_Cmd                   => Ad2wr_new_cmd                      ,
         Ad2Wr_MID                       => Ad2wr_mid                          ,
         Ad2Wr_Strt_Addr                 => Ad2wr_strt_addr                    ,

         --Transmit Type
         Ad2Wr_Single                    => Ad2wr_single                       ,
         Ad2Wr_Cacheline_4               => Ad2wr_cacheline_4                  ,
         Ad2Wr_Cacheline_8               => Ad2wr_cacheline_8                  ,
         Ad2Wr_Burst_16                  => Ad2wr_burst_16                     ,
         Ad2Wr_Burst_32                  => Ad2wr_burst_32                     ,

         Ad2Wr_Xfer_WrdCnt               => Ad2Wr_Xfer_WrdCnt                  ,
         Ad2Wr_Xfer_Width                => Ad2Wr_Xfer_Width                   ,
         Ad2Wr_WrBE                      => Ad2Wr_WrBE                         ,
         Ad2Wr_clk_ratio_1_1             => Ad2Wr_clk_ratio_1_1                ,

         Wr2Ad_Wr_Cmplt                  => Wr2ad_wr_cmplt                     ,
         Wr2Ad_Busy                      => Wr2ad_busy                         ,
         Wr2Ad_Error                     => Wr2ad_error                        ,
         Wr2Ad_Block_InFIFO              => Wr2ad_block_infifo                 ,

         -- NPI Inteface
         PI2Wr_WrFIFO_AlmostFull         => MPMC_PIM_WrFIFO_AlmostFull         ,
         PI2Wr_WrFIFO_Empty              => MPMC_PIM_WrFIFO_Empty              ,

         Wr2PI_WrFIFO_Data               => MPMC_PIM_WrFIFO_Data               ,

         Wr2PI_WrFIFO_BE                 => MPMC_PIM_WrFIFO_BE                 ,

         Wr2PI_WrFIFO_Push               => MPMC_PIM_WrFIFO_Push               ,
         Wr2PI_WrFIFO_Flush              => MPMC_PIM_WrFIFO_Flush
      );


   PIM_READ_MODULE : entity mpmc_v6_03_a.plbv46_rd_support
      generic map
      (
                                                                                                                                                              
         C_SPLB_NATIVE_DWIDTH      => C_SPLB_NATIVE_DWIDTH,                                      
            --  Native Data Width of this PLB Slave                                              
                                                                                                 
                                                                                                 
         -- PLBV46 parameterization                                                              
         C_SPLB_MID_WIDTH          => C_SPLB_MID_WIDTH,                                          
            -- The width of the Master ID bus                                                    
            -- This is set to log2(C_SPLB_NUM_MASTERS)                                           
                                                                                                 
         C_SPLB_NUM_MASTERS        => C_SPLB_NUM_MASTERS,                                        
            -- The number of Master Devices connected to the PLB bus                             
            -- Research this to find out default value                                           
                                                                                                 
         C_SPLB_SMALLEST_MASTER    => C_SPLB_SMALLEST_MASTER,                                    
            -- The dwidth (in bits) of the smallest master that will                             
            -- access this Slave.                                                                
                                                                                                 
         C_SPLB_AWIDTH             => C_SPLB_AWIDTH,                                             
            --  width of the PLB Address Bus (in bits)                                           
                                                                                                 
         C_SPLB_DWIDTH             => C_SPLB_DWIDTH,                                             
            --  Width of the PLB Data Bus (in bits)                                              
                                                                                                 
         C_PLBV46_PIM_TYPE         => C_PLBV46_PIM_TYPE,                                         
            --  Configuration Type (PLB, DPLB, IPLB)                                             
                                                                                                 
         C_SPLB_SUPPORT_BURSTS     => C_SPLB_SUPPORT_BURSTS,                                     
            --  Burst Support                                                                    
                                                                                                 
                                                                                                 
         -- NPI Parameterization                                                                 
         C_NPI_DWIDTH              => C_MPMC_PIM_DATA_WIDTH,                                     
            -- Sets the NPI Read Data port width.                                                
                                                                                                 
         C_PI_RDWDADDR_WIDTH       => C_MPMC_PIM_RDWDADDR_WIDTH,                                 
            -- sets the bit width of the PI_RdWdAddr port                                        
                                                                                                 
                                                                                                 
         C_PI_RDFIFO_LATENCY       => C_MPMC_PIM_RDFIFO_LATENCY,                                 
            -- Read Data latency (in NPI Clock periods) measured from                            
            -- assertion of PI_RdFIFO_Pop to data availability on the                            
            -- NPI2RD_RdFIFO_D input port.                                                       

         C_FAMILY                  => C_FAMILY   
            
      )                                                                                          
      port map (                                                                                 
                                                                                                 
         -- System Ports                                                                         
         SPLB_Clk                     => SPLB_Clk                           ,
         SPLB_Rst                     => SPLB_Rst                           ,

         PI_Clk                       => MPMC_Clk                           ,
         PIM_Rst                      => sync_plb_rst                       ,

         -- PLBV46 Interface
         PLB_rdBurst                  => SPLB_PLB_rdBurst                   ,

         Sl_rdDAck                    => SPLB_Sl_rdDAck                     ,
         Sl_rdDBus                    => SPLB_Sl_rdDBus                     ,

         Sl_rdWdAddr                  => SPLB_Sl_rdWdAddr                   ,
         Sl_rdComp                    => SPLB_Sl_rdComp                     ,
         Sl_rdBTerm                   => SPLB_Sl_rdBTerm                    ,
         Sl_MRdErr                    => SPLB_Sl_MRdErr                     ,


         -- Address Decode Interface
         Ad2Rd_PLB_NPI_Sync           => Ad2Rd_PLB_NPI_Sync                 ,
         Ad2Rd_New_Cmd                => Ad2rd_new_cmd                      ,
         Ad2Rd_Strt_Addr              => Ad2rd_strt_addr                    ,

         Ad2Rd_Xfer_Width             => Ad2rd_xfer_width                   ,
         Ad2Rd_Xfer_WdCnt             => Ad2rd_xfer_wdcnt                   ,
         Ad2Rd_Single                 => Ad2rd_single                       ,
         Ad2Rd_Cacheline_4            => Ad2rd_cacheline_4                  ,
         Ad2Rd_Cacheline_8            => Ad2rd_cacheline_8                  ,
         Ad2Rd_Burst_16               => Ad2rd_burst_16                     ,
         Ad2Rd_Burst_32               => Ad2rd_burst_32                     ,
         Ad2Rd_Burst_64               => Ad2rd_burst_64                     ,
         Ad2rd_queue_data             => Ad2rd_queue_data                   ,
         Ad2rd_wdblk_xings            => Ad2rd_wdblk_xings                  ,
         Ad2Rd_clk_ratio_1_1          => Ad2Rd_clk_ratio_1_1                ,

         Rd2Ad_Rd_Cmplt               => Rd2ad_rd_cmplt                     ,
         Rd2Ad_Rd_Data_Cmplt          => Rd2Ad_Rd_Data_Cmplt                ,
         Rd2Ad_Rd_Busy                => Rd2ad_busy                         ,
         Rd2Ad_Rd_Error               => Rd2Ad_Rd_Error                     ,

         -- NPI Read Interface
         NPI2RD_RdFIFO_Empty          => MPMC_PIM_RdFIFO_Empty              ,
         NPI2RD_RdFIFO_Data_Available => MPMC_PIM_RdFIFO_Data_Available     ,
         NPI2RD_RdFIFO_RdWdAddr       => MPMC_PIM_RdFIFO_RdWd_Addr          ,
         NPI2RD_RdFIFO_D              => MPMC_PIM_RdFIFO_Data               ,
         NPI2RD_RdFIFO_Latency        => MPMC_PIM_RdFIFO_Latency            ,

         Rd2NPI_RdFIFO_Flush          => MPMC_PIM_RdFIFO_Flush              ,
         Rd2NPI_RdFIFO_Pop            => MPMC_PIM_RdFIFO_Pop

      );

end generate;

-------------------------------------------------------------------------------
-- ************************************************************************* --
-------------------------------------------------------------------------------
GENERATE_DSPLB_PLBV46_PIM :
   IF (C_PLBV46_PIM_TYPE = "DPLB") generate

      -- Constant declarations
      constant WR_MODULE_SUPPORT_BURSTS : integer := 1;

      --Signal Declarations
      signal Ad2Wr_PLB_NPI_Sync   : std_logic;
      signal Ad2Rd_PLB_NPI_Sync   : std_logic;
      signal sync_rst             : std_logic;
      signal Rd2ad_rd_cmplt       : std_logic;
      signal Rd2ad_busy           : std_logic;
      signal Rd2Ad_Rd_Data_Cmplt     : std_logic;

      signal Ad2rd_new_cmd        : std_logic;
      signal Ad2rd_mid            : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      signal Ad2rd_strt_addr      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
      signal Ad2rd_single         : std_logic;
      signal Ad2rd_cacheline_4    : std_logic;
      signal Ad2rd_cacheline_8    : std_logic;
      signal Ad2rd_burst_16       : std_logic;
      signal Ad2rd_burst_32       : std_logic;
      signal Ad2rd_burst_64       : std_logic;

      signal Ad2rd_xfer_wdcnt     : std_logic_vector(0 to 7);
      signal Ad2rd_xfer_width     : std_logic_vector(0 to 1);

      signal Wr2ad_wr_cmplt       : std_logic;
      signal Wr2ad_busy           : std_logic;
      signal Wr2ad_error          : std_logic;

      signal Ad2wr_new_cmd        : std_logic;
      signal Ad2wr_mid            : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      signal Ad2wr_strt_addr      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
      signal Ad2wr_single         : std_logic;
      signal Ad2wr_cacheline_4    : std_logic;
      signal Ad2wr_cacheline_8    : std_logic;
      signal Ad2wr_burst_16       : std_logic;
      signal Ad2wr_burst_32       : std_logic;
      signal Ad2wr_burst_64       : std_logic;
      signal Ad2wr_wrbe           : std_logic_vector(0 to C_MPMC_PIM_DATA_WIDTH/8-1);

      signal Ad2wr_xfer_wrdcnt    : std_logic_vector(0 to 7);
      signal Ad2wr_xfer_width     : std_logic_vector(0 to 1);

      signal Wr2ad_block_infifo   : std_logic;

      signal Rd2Ad_Rd_Error       : std_logic;

      signal Ad2rd_queue_data     : std_logic;


      signal sync_mpmc_rst        : std_logic;
      signal sync_plb_rst         : std_logic;

      signal Ad2Rd_clk_ratio_1_1  : std_logic;
      signal Ad2Wr_clk_ratio_1_1  : std_logic;
begin


   PIM_ADDRESS_DECODER :  entity mpmc_v6_03_a.plbv46_address_decoder_dsplb
      generic map
      (
         --IPIC generics
         C_SPLB_DWIDTH                   => C_SPLB_DWIDTH                      ,
         C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH               ,
         C_SPLB_AWIDTH                   => C_SPLB_AWIDTH                      ,
         C_SPLB_NUM_MASTERS              => C_SPLB_NUM_MASTERS                 ,
         C_SPLB_MID_WIDTH                => C_SPLB_MID_WIDTH                   ,
         C_SPLB_P2P                      => C_SPLB_P2P                         ,
         C_SPLB_SUPPORT_BURSTS           => C_SPLB_SUPPORT_BURSTS              ,
         C_SPLB_SMALLEST_MASTER          => C_SPLB_SMALLEST_MASTER             ,

         C_PLBV46_PIM_TYPE               => C_PLBV46_PIM_TYPE                  ,
         --MPMC generics
         C_MPMC_PIM_BASEADDR             => C_MPMC_PIM_BASEADDR                ,
         C_MPMC_PIM_HIGHADDR             => C_MPMC_PIM_HIGHADDR                ,
         C_MPMC_PIM_OFFSET               => C_MPMC_PIM_OFFSET                  ,
         C_MPMC_PIM_DATA_WIDTH           => C_MPMC_PIM_DATA_WIDTH              ,
         C_MPMC_PIM_ADDR_WIDTH           => C_MPMC_PIM_ADDR_WIDTH              ,
         C_MPMC_PIM_RDFIFO_LATENCY       => C_MPMC_PIM_RDFIFO_LATENCY          ,
         C_MPMC_PIM_RDWDADDR_WIDTH       => C_MPMC_PIM_RDWDADDR_WIDTH          ,
         C_MPMC_PIM_SDR_DWIDTH           => C_MPMC_PIM_SDR_DWIDTH              ,
         C_MPMC_PIM_MEM_HAS_BE           => C_MPMC_PIM_MEM_HAS_BE              ,
         --Misc Generics
         C_FAMILY                        => C_FAMILY
      )
      port map
      (
         -- System signals ----------------------------------------------------
         Splb_Clk                        => SPLB_Clk                           ,
         Splb_Rst                        => SPLB_Rst                           ,
         Pi_Clk                          => MPMC_Clk                           ,
         Pi_rst                          => MPMC_Rst                           ,

         sync_rst                        => sync_rst                           ,
         sync_mpmc_rst                   => sync_mpmc_rst                      ,
         sync_plb_rst                    => sync_plb_rst                       ,
         -- PLB signals -------------------------------------------------------
         Plb_ABus                        => SPLB_PLB_ABus                      ,
         Plb_PAValid                     => SPLB_PLB_PAValid                   ,
         Plb_SAValid                     => SPLB_PLB_SAValid                   ,
         Plb_masterID                    => SPLB_PLB_masterID                  ,
         Plb_MSize                       => SPLB_PLB_MSize                     ,
         Plb_size                        => SPLB_PLB_size                      ,
         Plb_type                        => SPLB_PLB_type                      ,

         Plb_RNW                         => SPLB_PLB_RNW                       ,
         Plb_BE                          => SPLB_PLB_BE                        ,
         Plb_wrBurst                     => SPLB_PLB_wrBurst                   ,
         Plb_rdBurst                     => SPLB_PLB_rdBurst                   ,

         -- PLB Slave Response Signals
         Sl_addrAck                      => SPLB_Sl_addrAck                    ,
         Sl_SSize                        => SPLB_Sl_SSize                      ,
         Sl_wait                         => SPLB_Sl_wait                       ,
         Sl_rearbitrate                  => SPLB_Sl_rearbitrate                ,
         Sl_MBusy                        => SPLB_Sl_MBusy                      ,

         -- PIM Interconnect port signals -------------------------------------
         Pi2ad_InitDone                  => MPMC_PIM_InitDone                  ,
         Pi2ad_AddrAck                   => MPMC_PIM_AddrAck                   ,
         Pi2ad_wrfifo_almostFull         => MPMC_PIM_WrFIFO_AlmostFull         ,
         Pi2ad_wrFifo_empty              => MPMC_PIM_WrFIFO_Empty              ,
         Ad2pi_Addr                      => MPMC_PIM_Addr                      ,
         Ad2pi_AddrReq                   => MPMC_PIM_AddrReq                   ,
         Ad2pi_RNW                       => MPMC_PIM_RNW                       ,
         Ad2pi_Size                      => MPMC_PIM_Size                      ,

         -- Read Support Module signals ---------------------------------------
         Rd2ad_rd_cmplt                  => Rd2ad_rd_cmplt                     ,
         Rd2Ad_Rd_Data_Cmplt             => Rd2Ad_Rd_Data_Cmplt                ,
         Rd2ad_busy                      => Rd2ad_busy                         ,
         Rd2Ad_Rd_Error                  => Rd2Ad_Rd_Error                     ,

         Ad2rd_plb_npi_sync              => Ad2rd_plb_npi_sync                 ,
         Ad2rd_new_cmd                   => Ad2rd_new_cmd                      ,
         Ad2rd_mid                       => Ad2rd_mid                          ,
         Ad2rd_strt_addr                 => Ad2rd_strt_addr                    ,
         Ad2rd_single                    => Ad2rd_single                       ,
         Ad2rd_cacheline_4               => Ad2rd_cacheline_4                  ,
         Ad2rd_cacheline_8               => Ad2rd_cacheline_8                  ,
         Ad2rd_burst_16                  => Ad2rd_burst_16                     ,
         Ad2rd_burst_32                  => Ad2rd_burst_32                     ,
         Ad2rd_burst_64                  => Ad2rd_burst_64                     ,

         Ad2rd_xfer_wdcnt                => Ad2rd_xfer_wdcnt                   ,
         Ad2rd_xfer_width                => Ad2rd_xfer_width                   ,
         Ad2rd_queue_data                => Ad2rd_queue_data                   ,
         Ad2Rd_clk_ratio_1_1             => Ad2Rd_clk_ratio_1_1                ,

         -- Write Support Module signals --------------------------------------
         Wr2ad_block_infifo              => Wr2ad_block_infifo                 ,
         Wr2ad_wr_cmplt                  => Wr2ad_wr_cmplt                     ,
         Wr2ad_busy                      => Wr2ad_busy                         ,
         Wr2ad_error                     => Wr2ad_error                        ,

         Ad2wr_plb_npi_sync              => Ad2wr_plb_npi_sync                 ,
         Ad2wr_new_cmd                   => Ad2wr_new_cmd                      ,
         Ad2wr_mid                       => Ad2wr_mid                          ,
         Ad2wr_strt_addr                 => Ad2wr_strt_addr                    ,
         Ad2wr_single                    => Ad2wr_single                       ,
         Ad2wr_cacheline_4               => Ad2wr_cacheline_4                  ,
         Ad2wr_cacheline_8               => Ad2wr_cacheline_8                  ,
         Ad2wr_burst_16                  => Ad2wr_burst_16                     ,
         Ad2wr_burst_32                  => Ad2wr_burst_32                     ,
         Ad2wr_burst_64                  => Ad2wr_burst_64                     ,
         Ad2wr_wrbe                      => Ad2wr_wrbe                         ,

         Ad2wr_xfer_wrdcnt               => Ad2wr_xfer_wrdcnt                  ,
         Ad2wr_xfer_width                => Ad2wr_xfer_width                   ,
         Ad2Wr_clk_ratio_1_1             => Ad2Wr_clk_ratio_1_1                ,

         -- ECC signals -------------------------------------------------------
         Ad2pi_RdModWr                   => MPMC_PIM_RdModWr

     );


   PIM_WRITE_MODULE :  entity mpmc_v6_03_a.plbv46_write_module
      generic map
      (
      --IPIC generics
      -------------------------------------------------------------------------
         C_SPLB_MID_WIDTH                => C_SPLB_MID_WIDTH                   ,
         C_SPLB_NUM_MASTERS              => C_SPLB_NUM_MASTERS                 ,
         C_SPLB_SMALLEST_MASTER          => C_SPLB_SMALLEST_MASTER             ,
         C_SPLB_AWIDTH                   => C_SPLB_AWIDTH                      ,
         C_SPLB_DWIDTH                   => C_SPLB_DWIDTH                      ,
         C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH               ,
         C_PLBV46_PIM_TYPE               => C_PLBV46_PIM_TYPE                  ,
         C_MPMC_WR_FIFO_TYPE             => C_MPMC_PIM_WR_FIFO_TYPE            ,
         C_SPLB_SUPPORT_BURSTS           => WR_MODULE_SUPPORT_BURSTS           ,
         C_MPMC_PIM_DATA_WIDTH           => C_MPMC_PIM_DATA_WIDTH
      )
      port map
      (
         SPLB_Clk                        => SPLB_Clk                           ,
         PI_Clk                          => MPMC_Clk                           ,
         Sync_Mpmc_Rst                   => Sync_Mpmc_Rst                      ,
         Sync_Plb_Rst                    => Sync_Plb_Rst                       ,

         -- PLB Write Interface
         PLB_wrDBus                      => SPLB_PLB_wrDBus                    ,
         PLB_wrBurst                     => SPLB_PLB_wrBurst                   ,
         Sl_wrDAck                       => SPLB_Sl_wrDack                     ,
         Sl_wrComp                       => SPLB_Sl_wrComp                     ,
         Sl_wrBTerm                      => SPLB_Sl_wrBTerm                    ,
         Sl_MWrErr                       => SPLB_Sl_MWrErr                     ,
         Sl_MIRQ                         => SPLB_Sl_MIRQ                       ,

         -- Address Module Interface
         Ad2Wr_PLB_NPI_Sync              => Ad2Wr_PLB_NPI_Sync                 ,
         Ad2Wr_New_Cmd                   => Ad2wr_new_cmd                      ,
         Ad2Wr_MID                       => Ad2wr_mid                          ,
         Ad2Wr_Strt_Addr                 => Ad2wr_strt_addr                    ,

         --Transmit Type
         Ad2Wr_Single                    => Ad2wr_single                       ,
         Ad2Wr_Cacheline_4               => Ad2wr_cacheline_4                  ,
         Ad2Wr_Cacheline_8               => Ad2wr_cacheline_8                  ,
         Ad2Wr_Burst_16                  => Ad2wr_burst_16                     ,
         Ad2Wr_Burst_32                  => Ad2wr_burst_32                     ,

         Ad2Wr_Xfer_WrdCnt               => Ad2Wr_Xfer_WrdCnt                  ,
         Ad2Wr_Xfer_Width                => Ad2Wr_Xfer_Width                   ,
         Ad2Wr_WrBE                      => Ad2Wr_WrBE                         ,
         Ad2Wr_clk_ratio_1_1             => Ad2Wr_clk_ratio_1_1                ,

         Wr2Ad_Wr_Cmplt                  => Wr2ad_wr_cmplt                     ,
         Wr2Ad_Busy                      => Wr2ad_busy                         ,
         Wr2Ad_Error                     => Wr2ad_error                        ,
         Wr2Ad_Block_InFIFO              => Wr2ad_block_infifo                 ,

         -- NPI Inteface
         PI2Wr_WrFIFO_AlmostFull         => MPMC_PIM_WrFIFO_AlmostFull         ,
         PI2Wr_WrFIFO_Empty              => MPMC_PIM_WrFIFO_Empty              ,

         Wr2PI_WrFIFO_Data               => MPMC_PIM_WrFIFO_Data               ,

         Wr2PI_WrFIFO_BE                 => MPMC_PIM_WrFIFO_BE                 ,

         Wr2PI_WrFIFO_Push               => MPMC_PIM_WrFIFO_Push               ,
         Wr2PI_WrFIFO_Flush              => MPMC_PIM_WrFIFO_Flush
      );


   PIM_READ_MODULE : entity mpmc_v6_03_a.plbv46_rd_support_dsplb
      generic map
      (

         C_SPLB_NATIVE_DWIDTH      => C_SPLB_NATIVE_DWIDTH,                                      
            --  Native Data Width of this PLB Slave                                              
                                                                                                 
                                                                                                 
         -- PLBV46 parameterization                                                              
         C_SPLB_MID_WIDTH          => C_SPLB_MID_WIDTH,                                          
            -- The width of the Master ID bus                                                    
            -- This is set to log2(C_SPLB_NUM_MASTERS)                                           
                                                                                                 
         C_SPLB_NUM_MASTERS        => C_SPLB_NUM_MASTERS,                                        
            -- The number of Master Devices connected to the PLB bus                             
            -- Research this to find out default value                                           
                                                                                                 
         C_SPLB_SMALLEST_MASTER    => C_SPLB_SMALLEST_MASTER,                                    
            -- The dwidth (in bits) of the smallest master that will                             
            -- access this Slave.                                                                
                                                                                                 
         C_SPLB_AWIDTH             => C_SPLB_AWIDTH,                                             
            --  width of the PLB Address Bus (in bits)                                           
                                                                                                 
         C_SPLB_DWIDTH             => C_SPLB_DWIDTH,                                             
            --  Width of the PLB Data Bus (in bits)                                              
                                                                                                 
         C_PLBV46_PIM_TYPE         => C_PLBV46_PIM_TYPE,                                         
            --  Configuration Type (PLB, DPLB, IPLB)                                             
                                                                                                 
         C_SPLB_SUPPORT_BURSTS     => C_SPLB_SUPPORT_BURSTS,                                     
            --  Burst Support                                                                    
                                                                                                 
                                                                                                 
         -- NPI Parameterization                                                                 
         C_NPI_DWIDTH              => C_MPMC_PIM_DATA_WIDTH,                                     
            -- Sets the NPI Read Data port width.                                                
                                                                                                 
         C_PI_RDWDADDR_WIDTH       => C_MPMC_PIM_RDWDADDR_WIDTH,                                 
            -- sets the bit width of the PI_RdWdAddr port                                        
                                                                                                 
                                                                                                 
         C_PI_RDFIFO_LATENCY       => C_MPMC_PIM_RDFIFO_LATENCY,                                 
            -- Read Data latency (in NPI Clock periods) measured from                            
            -- assertion of PI_RdFIFO_Pop to data availability on the                            
            -- NPI2RD_RdFIFO_D input port.                                                       

         C_FAMILY                  => C_FAMILY   
      )
      port map
      (

         -- System Ports
         SPLB_Clk                     => SPLB_Clk                           ,
         SPLB_Rst                     => SPLB_Rst                           ,

         PI_Clk                       => MPMC_Clk                           ,
         PIM_Rst                      => sync_plb_rst                       ,

         -- PLBV46 Interface
         PLB_rdBurst                  => SPLB_PLB_rdBurst                   ,

         Sl_rdDAck                    => SPLB_Sl_rdDAck                     ,
         Sl_rdDBus                    => SPLB_Sl_rdDBus                     ,

         Sl_rdWdAddr                  => SPLB_Sl_rdWdAddr                   ,
         Sl_rdComp                    => SPLB_Sl_rdComp                     ,
         Sl_rdBTerm                   => SPLB_Sl_rdBTerm                    ,
         Sl_MRdErr                    => SPLB_Sl_MRdErr                     ,


         -- Address Decode Interface
         Ad2Rd_PLB_NPI_Sync           => Ad2Rd_PLB_NPI_Sync                 ,
         Ad2Rd_New_Cmd                => Ad2rd_new_cmd                      ,
         Ad2Rd_Strt_Addr              => Ad2rd_strt_addr                    ,

         Ad2Rd_Xfer_Width             => Ad2rd_xfer_width                   ,
         Ad2Rd_Xfer_WdCnt             => Ad2rd_xfer_wdcnt                   ,
         Ad2Rd_Single                 => Ad2rd_single                       ,
         Ad2Rd_Cacheline_4            => Ad2rd_cacheline_4                  ,
         Ad2Rd_Cacheline_8            => Ad2rd_cacheline_8                  ,
         Ad2Rd_Burst_16               => Ad2rd_burst_16                     ,
         Ad2Rd_Burst_32               => Ad2rd_burst_32                     ,
         Ad2Rd_Burst_64               => Ad2rd_burst_64                     ,
         Ad2rd_queue_data             => Ad2rd_queue_data                   ,
         Ad2Rd_clk_ratio_1_1          => Ad2Rd_clk_ratio_1_1                ,

         Rd2Ad_Rd_Cmplt               => Rd2ad_rd_cmplt                     ,
         Rd2Ad_Rd_Data_Cmplt          => Rd2Ad_Rd_Data_Cmplt                ,
         Rd2Ad_Rd_Busy                => Rd2ad_busy                         ,
         Rd2Ad_Rd_Error               => Rd2Ad_Rd_Error                     ,

         -- NPI Read Interface
         NPI2RD_RdFIFO_Empty          => MPMC_PIM_RdFIFO_Empty              ,
         NPI2RD_RdFIFO_Data_Available => MPMC_PIM_RdFIFO_Data_Available     ,
         NPI2RD_RdFIFO_RdWdAddr       => MPMC_PIM_RdFIFO_RdWd_Addr          ,
         NPI2RD_RdFIFO_D              => MPMC_PIM_RdFIFO_Data               ,
         NPI2RD_RdFIFO_Latency        => MPMC_PIM_RdFIFO_Latency            ,

         Rd2NPI_RdFIFO_Flush          => MPMC_PIM_RdFIFO_Flush              ,
         Rd2NPI_RdFIFO_Pop            => MPMC_PIM_RdFIFO_Pop

         );

end generate;


-------------------------------------------------------------------------------
-- ************************************************************************* --
-------------------------------------------------------------------------------
GENERATE_ISPLB_PLBV46_PIM :
   IF (C_PLBV46_PIM_TYPE = "IPLB") generate

      -- Constant declarations

      --Signal Declarations
      signal Ad2Wr_PLB_NPI_Sync   : std_logic;
      signal Ad2Rd_PLB_NPI_Sync   : std_logic;
      signal sync_rst             : std_logic;
      signal Rd2ad_rd_cmplt       : std_logic;
      signal Rd2ad_busy           : std_logic;
      signal Rd2Ad_Rd_Data_Cmplt     : std_logic;

      signal Ad2rd_new_cmd        : std_logic;
      signal Ad2rd_mid            : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      signal Ad2rd_strt_addr      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
      signal Ad2rd_single         : std_logic;
      signal Ad2rd_cacheline_4    : std_logic;
      signal Ad2rd_cacheline_8    : std_logic;
      signal Ad2rd_burst_16       : std_logic;
      signal Ad2rd_burst_32       : std_logic;
      signal Ad2rd_burst_64       : std_logic;

      signal Ad2rd_xfer_wdcnt     : std_logic_vector(0 to 7);
      signal Ad2rd_xfer_width     : std_logic_vector(0 to 1);

      signal Wr2ad_wr_cmplt       : std_logic;
      signal Wr2ad_busy           : std_logic;
      signal Wr2ad_error          : std_logic;

      signal Ad2wr_new_cmd        : std_logic;
      signal Ad2wr_mid            : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      signal Ad2wr_strt_addr      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
      signal Ad2wr_single         : std_logic;
      signal Ad2wr_cacheline_4    : std_logic;
      signal Ad2wr_cacheline_8    : std_logic;
      signal Ad2wr_burst_16       : std_logic;
      signal Ad2wr_burst_32       : std_logic;
      signal Ad2wr_burst_64       : std_logic;
      signal Ad2wr_wrbe           : std_logic_vector(0 to C_MPMC_PIM_DATA_WIDTH/8-1);

      signal Ad2wr_xfer_wrdcnt    : std_logic_vector(0 to 7);
      signal Ad2wr_xfer_width     : std_logic_vector(0 to 1);

      signal Wr2ad_block_infifo   : std_logic;

      signal Rd2Ad_Rd_Error       : std_logic;

      signal Ad2rd_queue_data     : std_logic;


      signal sync_mpmc_rst        : std_logic;
      signal sync_plb_rst         : std_logic;

      signal Ad2Rd_clk_ratio_1_1  : std_logic;
      signal Ad2Wr_clk_ratio_1_1  : std_logic;
begin


   PIM_ADDRESS_DECODER :  entity mpmc_v6_03_a.plbv46_address_decoder_isplb
      generic map
      (
         --IPIC generics
         C_SPLB_DWIDTH                   => C_SPLB_DWIDTH                      ,
         C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH               ,
         C_SPLB_AWIDTH                   => C_SPLB_AWIDTH                      ,
         C_SPLB_NUM_MASTERS              => C_SPLB_NUM_MASTERS                 ,
         C_SPLB_MID_WIDTH                => C_SPLB_MID_WIDTH                   ,
         C_SPLB_P2P                      => C_SPLB_P2P                         ,
         C_SPLB_SUPPORT_BURSTS           => C_SPLB_SUPPORT_BURSTS              ,
         C_SPLB_SMALLEST_MASTER          => C_SPLB_SMALLEST_MASTER             ,

         C_PLBV46_PIM_TYPE               => C_PLBV46_PIM_TYPE                  ,
         --MPMC generics
         C_MPMC_PIM_BASEADDR             => C_MPMC_PIM_BASEADDR                ,
         C_MPMC_PIM_HIGHADDR             => C_MPMC_PIM_HIGHADDR                ,
         C_MPMC_PIM_OFFSET               => C_MPMC_PIM_OFFSET                  ,
         C_MPMC_PIM_DATA_WIDTH           => C_MPMC_PIM_DATA_WIDTH              ,
         C_MPMC_PIM_ADDR_WIDTH           => C_MPMC_PIM_ADDR_WIDTH              ,
         C_MPMC_PIM_RDFIFO_LATENCY       => C_MPMC_PIM_RDFIFO_LATENCY          ,
         C_MPMC_PIM_RDWDADDR_WIDTH       => C_MPMC_PIM_RDWDADDR_WIDTH          ,
         C_MPMC_PIM_SDR_DWIDTH           => C_MPMC_PIM_SDR_DWIDTH              ,
         C_MPMC_PIM_MEM_HAS_BE           => C_MPMC_PIM_MEM_HAS_BE              ,
         --Misc Generics
         C_FAMILY                        => C_FAMILY
      )
      port map
      (
         -- System signals ----------------------------------------------------
         Splb_Clk                        => SPLB_Clk                           ,
         Splb_Rst                        => SPLB_Rst                           ,
         Pi_Clk                          => MPMC_Clk                           ,
         Pi_rst                          => MPMC_Rst                           ,

         sync_rst                        => sync_rst                           ,
         sync_mpmc_rst                   => sync_mpmc_rst                      ,
         sync_plb_rst                    => sync_plb_rst                       ,
         -- PLB signals -------------------------------------------------------
         Plb_ABus                        => SPLB_PLB_ABus                      ,
         Plb_PAValid                     => SPLB_PLB_PAValid                   ,
         Plb_SAValid                     => SPLB_PLB_SAValid                   ,
         Plb_masterID                    => SPLB_PLB_masterID                  ,
         Plb_MSize                       => SPLB_PLB_MSize                     ,
         Plb_size                        => SPLB_PLB_size                      ,
         Plb_type                        => SPLB_PLB_type                      ,

         Plb_RNW                         => SPLB_PLB_RNW                       ,
         Plb_BE                          => SPLB_PLB_BE                        ,
         Plb_wrBurst                     => SPLB_PLB_wrBurst                   ,
         Plb_rdBurst                     => SPLB_PLB_rdBurst                   ,

         -- PLB Slave Response Signals
         Sl_addrAck                      => SPLB_Sl_addrAck                    ,
         Sl_SSize                        => SPLB_Sl_SSize                      ,
         Sl_wait                         => SPLB_Sl_wait                       ,
         Sl_rearbitrate                  => SPLB_Sl_rearbitrate                ,
         Sl_MBusy                        => SPLB_Sl_MBusy                      ,

         -- PIM Interconnect port signals -------------------------------------
         Pi2ad_InitDone                  => MPMC_PIM_InitDone                  ,
         Pi2ad_AddrAck                   => MPMC_PIM_AddrAck                   ,
         Pi2ad_wrfifo_almostFull         => MPMC_PIM_WrFIFO_AlmostFull         ,
         Pi2ad_wrFifo_empty              => MPMC_PIM_WrFIFO_Empty              ,
         Ad2pi_Addr                      => MPMC_PIM_Addr                      ,
         Ad2pi_AddrReq                   => MPMC_PIM_AddrReq                   ,
         Ad2pi_RNW                       => MPMC_PIM_RNW                       ,
         Ad2pi_Size                      => MPMC_PIM_Size                      ,

         -- Read Support Module signals ---------------------------------------
         Rd2ad_rd_cmplt                  => Rd2ad_rd_cmplt                     ,
         Rd2Ad_Rd_Data_Cmplt             => Rd2Ad_Rd_Data_Cmplt                ,
         Rd2ad_busy                      => Rd2ad_busy                         ,
         Rd2Ad_Rd_Error                  => Rd2Ad_Rd_Error                     ,

         Ad2rd_plb_npi_sync              => Ad2rd_plb_npi_sync                 ,
         Ad2rd_new_cmd                   => Ad2rd_new_cmd                      ,
         Ad2rd_mid                       => Ad2rd_mid                          ,
         Ad2rd_strt_addr                 => Ad2rd_strt_addr                    ,
         Ad2rd_single                    => Ad2rd_single                       ,
         Ad2rd_cacheline_4               => Ad2rd_cacheline_4                  ,
         Ad2rd_cacheline_8               => Ad2rd_cacheline_8                  ,
         Ad2rd_burst_16                  => Ad2rd_burst_16                     ,
         Ad2rd_burst_32                  => Ad2rd_burst_32                     ,
         Ad2rd_burst_64                  => Ad2rd_burst_64                     ,

         Ad2rd_xfer_wdcnt                => Ad2rd_xfer_wdcnt                   ,
         Ad2rd_xfer_width                => Ad2rd_xfer_width                   ,
         Ad2rd_queue_data                => Ad2rd_queue_data                   ,
         Ad2Rd_clk_ratio_1_1             => Ad2Rd_clk_ratio_1_1                ,

         -- Write Support Module signals --------------------------------------
         Wr2ad_block_infifo              => Wr2ad_block_infifo                 ,
         Wr2ad_wr_cmplt                  => Wr2ad_wr_cmplt                     ,
         Wr2ad_busy                      => Wr2ad_busy                         ,
         Wr2ad_error                     => Wr2ad_error                        ,

         Ad2wr_plb_npi_sync              => Ad2wr_plb_npi_sync                 ,
         Ad2wr_new_cmd                   => Ad2wr_new_cmd                      ,
         Ad2wr_mid                       => Ad2wr_mid                          ,
         Ad2wr_strt_addr                 => Ad2wr_strt_addr                    ,
         Ad2wr_single                    => Ad2wr_single                       ,
         Ad2wr_cacheline_4               => Ad2wr_cacheline_4                  ,
         Ad2wr_cacheline_8               => Ad2wr_cacheline_8                  ,
         Ad2wr_burst_16                  => Ad2wr_burst_16                     ,
         Ad2wr_burst_32                  => Ad2wr_burst_32                     ,
         Ad2wr_burst_64                  => Ad2wr_burst_64                     ,
         Ad2wr_wrbe                      => Ad2wr_wrbe                         ,

         Ad2wr_xfer_wrdcnt               => Ad2wr_xfer_wrdcnt                  ,
         Ad2wr_xfer_width                => Ad2wr_xfer_width                   ,
         Ad2Wr_clk_ratio_1_1             => Ad2Wr_clk_ratio_1_1                ,

         -- ECC signals -------------------------------------------------------
         Ad2pi_RdModWr                   => MPMC_PIM_RdModWr

     );


   PIM_WRITE_MODULE :  entity mpmc_v6_03_a.plbv46_write_module
      generic map
      (
      --IPIC generics
      -------------------------------------------------------------------------
         C_SPLB_MID_WIDTH                => C_SPLB_MID_WIDTH                   ,
         C_SPLB_NUM_MASTERS              => C_SPLB_NUM_MASTERS                 ,
         C_SPLB_SMALLEST_MASTER          => C_SPLB_SMALLEST_MASTER             ,
         C_SPLB_AWIDTH                   => C_SPLB_AWIDTH                      ,
         C_SPLB_DWIDTH                   => C_SPLB_DWIDTH                      ,
         C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH               ,
         C_PLBV46_PIM_TYPE               => C_PLBV46_PIM_TYPE                  ,
         C_MPMC_WR_FIFO_TYPE             => C_MPMC_PIM_WR_FIFO_TYPE            ,
         C_SPLB_SUPPORT_BURSTS           => C_SPLB_SUPPORT_BURSTS              ,
         C_MPMC_PIM_DATA_WIDTH           => C_MPMC_PIM_DATA_WIDTH
      )
      port map
      (
         SPLB_Clk                        => SPLB_Clk                           ,
         PI_Clk                          => MPMC_Clk                           ,
         Sync_Mpmc_Rst                   => Sync_Mpmc_Rst                      ,
         Sync_Plb_Rst                    => Sync_Plb_Rst                       ,

         -- PLB Write Interface
         PLB_wrDBus                      => SPLB_PLB_wrDBus                    ,
         PLB_wrBurst                     => SPLB_PLB_wrBurst                   ,
         Sl_wrDAck                       => SPLB_Sl_wrDack                     ,
         Sl_wrComp                       => SPLB_Sl_wrComp                     ,
         Sl_wrBTerm                      => SPLB_Sl_wrBTerm                    ,
         Sl_MWrErr                       => SPLB_Sl_MWrErr                     ,
         Sl_MIRQ                         => SPLB_Sl_MIRQ                       ,

         -- Address Module Interface
         Ad2Wr_PLB_NPI_Sync              => Ad2Wr_PLB_NPI_Sync                 ,
         Ad2Wr_New_Cmd                   => Ad2wr_new_cmd                      ,
         Ad2Wr_MID                       => Ad2wr_mid                          ,
         Ad2Wr_Strt_Addr                 => Ad2wr_strt_addr                    ,

         --Transmit Type
         Ad2Wr_Single                    => Ad2wr_single                       ,
         Ad2Wr_Cacheline_4               => Ad2wr_cacheline_4                  ,
         Ad2Wr_Cacheline_8               => Ad2wr_cacheline_8                  ,
         Ad2Wr_Burst_16                  => Ad2wr_burst_16                     ,
         Ad2Wr_Burst_32                  => Ad2wr_burst_32                     ,

         Ad2Wr_Xfer_WrdCnt               => Ad2Wr_Xfer_WrdCnt                  ,
         Ad2Wr_Xfer_Width                => Ad2Wr_Xfer_Width                   ,
         Ad2Wr_WrBE                      => Ad2Wr_WrBE                         ,
         Ad2Wr_clk_ratio_1_1             => Ad2Wr_clk_ratio_1_1                ,

         Wr2Ad_Wr_Cmplt                  => Wr2ad_wr_cmplt                     ,
         Wr2Ad_Busy                      => Wr2ad_busy                         ,
         Wr2Ad_Error                     => Wr2ad_error                        ,
         Wr2Ad_Block_InFIFO              => Wr2ad_block_infifo                 ,

         -- NPI Inteface
         PI2Wr_WrFIFO_AlmostFull         => MPMC_PIM_WrFIFO_AlmostFull         ,
         PI2Wr_WrFIFO_Empty              => MPMC_PIM_WrFIFO_Empty              ,

         Wr2PI_WrFIFO_Data               => MPMC_PIM_WrFIFO_Data               ,

         Wr2PI_WrFIFO_BE                 => MPMC_PIM_WrFIFO_BE                 ,

         Wr2PI_WrFIFO_Push               => MPMC_PIM_WrFIFO_Push               ,
         Wr2PI_WrFIFO_Flush              => MPMC_PIM_WrFIFO_Flush
      );


   PIM_READ_MODULE : entity mpmc_v6_03_a.plbv46_rd_support_isplb
      generic map
      (

         C_SPLB_NATIVE_DWIDTH      => C_SPLB_NATIVE_DWIDTH,                                      
            --  Native Data Width of this PLB Slave                                              
                                                                                                 
                                                                                                 
         -- PLBV46 parameterization                                                              
         C_SPLB_MID_WIDTH          => C_SPLB_MID_WIDTH,                                          
            -- The width of the Master ID bus                                                    
            -- This is set to log2(C_SPLB_NUM_MASTERS)                                           
                                                                                                 
         C_SPLB_NUM_MASTERS        => C_SPLB_NUM_MASTERS,                                        
            -- The number of Master Devices connected to the PLB bus                             
            -- Research this to find out default value                                           
                                                                                                 
         C_SPLB_SMALLEST_MASTER    => C_SPLB_SMALLEST_MASTER,                                    
            -- The dwidth (in bits) of the smallest master that will                             
            -- access this Slave.                                                                
                                                                                                 
         C_SPLB_AWIDTH             => C_SPLB_AWIDTH,                                             
            --  width of the PLB Address Bus (in bits)                                           
                                                                                                 
         C_SPLB_DWIDTH             => C_SPLB_DWIDTH,                                             
            --  Width of the PLB Data Bus (in bits)                                              
                                                                                                 
         C_PLBV46_PIM_TYPE         => C_PLBV46_PIM_TYPE,                                         
            --  Configuration Type (PLB, DPLB, IPLB)                                             
                                                                                                 
         C_SPLB_SUPPORT_BURSTS     => C_SPLB_SUPPORT_BURSTS,                                     
            --  Burst Support                                                                    
                                                                                                 
                                                                                                 
         -- NPI Parameterization                                                                 
         C_NPI_DWIDTH              => C_MPMC_PIM_DATA_WIDTH,                                     
            -- Sets the NPI Read Data port width.                                                
                                                                                                 
         C_PI_RDWDADDR_WIDTH       => C_MPMC_PIM_RDWDADDR_WIDTH,                                 
            -- sets the bit width of the PI_RdWdAddr port                                        
                                                                                                 
                                                                                                 
         C_PI_RDFIFO_LATENCY       => C_MPMC_PIM_RDFIFO_LATENCY,                                 
            -- Read Data latency (in NPI Clock periods) measured from                            
            -- assertion of PI_RdFIFO_Pop to data availability on the                            
            -- NPI2RD_RdFIFO_D input port.                                                       

         C_FAMILY                  => C_FAMILY   
      )
      port map
      (

         -- System Ports
         SPLB_Clk                     => SPLB_Clk                           ,
         SPLB_Rst                     => SPLB_Rst                           ,

         PI_Clk                       => MPMC_Clk                           ,
         PIM_Rst                      => sync_plb_rst                       ,

         -- PLBV46 Interface
         PLB_rdBurst                  => SPLB_PLB_rdBurst                   ,

         Sl_rdDAck                    => SPLB_Sl_rdDAck                     ,
         Sl_rdDBus                    => SPLB_Sl_rdDBus                     ,

         Sl_rdWdAddr                  => SPLB_Sl_rdWdAddr                   ,
         Sl_rdComp                    => SPLB_Sl_rdComp                     ,
         Sl_rdBTerm                   => SPLB_Sl_rdBTerm                    ,
         Sl_MRdErr                    => SPLB_Sl_MRdErr                     ,


         -- Address Decode Interface
         Ad2Rd_PLB_NPI_Sync           => Ad2Rd_PLB_NPI_Sync                 ,
         Ad2Rd_New_Cmd                => Ad2rd_new_cmd                      ,
         Ad2Rd_Strt_Addr              => Ad2rd_strt_addr                    ,

         Ad2Rd_Xfer_Width             => Ad2rd_xfer_width                   ,
         Ad2Rd_Xfer_WdCnt             => Ad2rd_xfer_wdcnt                   ,
         Ad2Rd_Single                 => Ad2rd_single                       ,
         Ad2Rd_Cacheline_4            => Ad2rd_cacheline_4                  ,
         Ad2Rd_Cacheline_8            => Ad2rd_cacheline_8                  ,
         Ad2Rd_Burst_16               => Ad2rd_burst_16                     ,
         Ad2Rd_Burst_32               => Ad2rd_burst_32                     ,
         Ad2Rd_Burst_64               => Ad2rd_burst_64                     ,
         Ad2rd_queue_data             => Ad2rd_queue_data                   ,
         Ad2Rd_clk_ratio_1_1          => Ad2Rd_clk_ratio_1_1                ,

         Rd2Ad_Rd_Cmplt               => Rd2ad_rd_cmplt                     ,
         Rd2Ad_Rd_Data_Cmplt          => Rd2Ad_Rd_Data_Cmplt                ,
         Rd2Ad_Rd_Busy                => Rd2ad_busy                         ,
         Rd2Ad_Rd_Error               => Rd2Ad_Rd_Error                     ,

         -- NPI Read Interface
         NPI2RD_RdFIFO_Empty          => MPMC_PIM_RdFIFO_Empty              ,
         NPI2RD_RdFIFO_Data_Available => MPMC_PIM_RdFIFO_Data_Available     ,
         NPI2RD_RdFIFO_RdWdAddr       => MPMC_PIM_RdFIFO_RdWd_Addr          ,
         NPI2RD_RdFIFO_D              => MPMC_PIM_RdFIFO_Data               ,
         NPI2RD_RdFIFO_Latency        => MPMC_PIM_RdFIFO_Latency            ,

         Rd2NPI_RdFIFO_Flush          => MPMC_PIM_RdFIFO_Flush              ,
         Rd2NPI_RdFIFO_Pop            => MPMC_PIM_RdFIFO_Pop

         );

end generate;

-------------------------------------------------------------------------------
-- ************************************************************************* --
-------------------------------------------------------------------------------
GENERATE_SINGLES_PLBV46_PIM :
   IF (C_PLBV46_PIM_TYPE = "PLB" and C_SPLB_SUPPORT_BURSTS = 0) generate

      -- Constant declarations

      --Signal Declarations
      signal Ad2Wr_PLB_NPI_Sync   : std_logic;
      signal Ad2Rd_PLB_NPI_Sync   : std_logic;
      signal sync_rst             : std_logic;
      signal Rd2ad_rd_cmplt       : std_logic;
      signal Rd2ad_busy           : std_logic;
      signal Rd2Ad_Rd_Data_Cmplt     : std_logic;

      signal Ad2rd_new_cmd        : std_logic;
      signal Ad2rd_mid            : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      signal Ad2rd_strt_addr      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
      signal Ad2rd_single         : std_logic;
      signal Ad2rd_cacheline_4    : std_logic;
      signal Ad2rd_cacheline_8    : std_logic;
      signal Ad2rd_burst_16       : std_logic;
      signal Ad2rd_burst_32       : std_logic;
      signal Ad2rd_burst_64       : std_logic;

      signal Ad2rd_xfer_wdcnt     : std_logic_vector(0 to 7);
      signal Ad2rd_xfer_width     : std_logic_vector(0 to 1);

      signal Wr2ad_wr_cmplt       : std_logic;
      signal Wr2ad_busy           : std_logic;
      signal Wr2ad_error          : std_logic;

      signal Ad2wr_new_cmd        : std_logic;
      signal Ad2wr_mid            : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      signal Ad2wr_strt_addr      : std_logic_vector(0 to C_SPLB_AWIDTH-1);
      signal Ad2wr_single         : std_logic;
      signal Ad2wr_cacheline_4    : std_logic;
      signal Ad2wr_cacheline_8    : std_logic;
      signal Ad2wr_burst_16       : std_logic;
      signal Ad2wr_burst_32       : std_logic;
      signal Ad2wr_burst_64       : std_logic;
      signal Ad2wr_wrbe           : std_logic_vector(0 to C_MPMC_PIM_DATA_WIDTH/8-1);

      signal Ad2wr_xfer_wrdcnt    : std_logic_vector(0 to 7);
      signal Ad2wr_xfer_width     : std_logic_vector(0 to 1);

      signal Wr2ad_block_infifo   : std_logic;

      signal Rd2Ad_Rd_Error       : std_logic;

      signal Ad2rd_queue_data     : std_logic;

      signal sync_mpmc_rst        : std_logic;
      signal sync_plb_rst         : std_logic;

      signal Ad2Rd_clk_ratio_1_1  : std_logic;
      signal Ad2Wr_clk_ratio_1_1  : std_logic;
begin


   PIM_ADDRESS_DECODER :  entity mpmc_v6_03_a.plbv46_address_decoder_single
      generic map
      (
         --IPIC generics
         C_SPLB_DWIDTH                   => C_SPLB_DWIDTH                      ,
         C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH               ,
         C_SPLB_AWIDTH                   => C_SPLB_AWIDTH                      ,
         C_SPLB_NUM_MASTERS              => C_SPLB_NUM_MASTERS                 ,
         C_SPLB_MID_WIDTH                => C_SPLB_MID_WIDTH                   ,
         C_SPLB_P2P                      => C_SPLB_P2P                         ,
         C_SPLB_SUPPORT_BURSTS           => C_SPLB_SUPPORT_BURSTS              ,
         C_SPLB_SMALLEST_MASTER          => C_SPLB_SMALLEST_MASTER             ,

         C_PLBV46_PIM_TYPE               => C_PLBV46_PIM_TYPE                  ,
         --MPMC generics
         C_MPMC_PIM_BASEADDR             => C_MPMC_PIM_BASEADDR                ,
         C_MPMC_PIM_HIGHADDR             => C_MPMC_PIM_HIGHADDR                ,
         C_MPMC_PIM_OFFSET               => C_MPMC_PIM_OFFSET                  ,
         C_MPMC_PIM_DATA_WIDTH           => C_MPMC_PIM_DATA_WIDTH              ,
         C_MPMC_PIM_ADDR_WIDTH           => C_MPMC_PIM_ADDR_WIDTH              ,
         C_MPMC_PIM_RDFIFO_LATENCY       => C_MPMC_PIM_RDFIFO_LATENCY          ,
         C_MPMC_PIM_RDWDADDR_WIDTH       => C_MPMC_PIM_RDWDADDR_WIDTH          ,
         C_MPMC_PIM_SDR_DWIDTH           => C_MPMC_PIM_SDR_DWIDTH              ,
         C_MPMC_PIM_MEM_HAS_BE           => C_MPMC_PIM_MEM_HAS_BE              ,
         --Misc Generics
         C_FAMILY                        => C_FAMILY
      )
      port map
      (
         -- System signals ----------------------------------------------------
         Splb_Clk                        => SPLB_Clk                           ,
         Splb_Rst                        => SPLB_Rst                           ,
         Pi_Clk                          => MPMC_Clk                           ,
         Pi_rst                          => MPMC_Rst                           ,

         sync_rst                        => sync_rst                           ,
         sync_mpmc_rst                   => sync_mpmc_rst                      ,
         sync_plb_rst                    => sync_plb_rst                       ,
         -- PLB signals -------------------------------------------------------
         Plb_ABus                        => SPLB_PLB_ABus                      ,
         Plb_PAValid                     => SPLB_PLB_PAValid                   ,
         Plb_SAValid                     => SPLB_PLB_SAValid                   ,
         Plb_masterID                    => SPLB_PLB_masterID                  ,
         Plb_MSize                       => SPLB_PLB_MSize                     ,
         Plb_size                        => SPLB_PLB_size                      ,
         Plb_type                        => SPLB_PLB_type                      ,

         Plb_RNW                         => SPLB_PLB_RNW                       ,
         Plb_BE                          => SPLB_PLB_BE                        ,
         Plb_wrBurst                     => SPLB_PLB_wrBurst                   ,
         Plb_rdBurst                     => SPLB_PLB_rdBurst                   ,

         -- PLB Slave Response Signals
         Sl_addrAck                      => SPLB_Sl_addrAck                    ,
         Sl_SSize                        => SPLB_Sl_SSize                      ,
         Sl_wait                         => SPLB_Sl_wait                       ,
         Sl_rearbitrate                  => SPLB_Sl_rearbitrate                ,
         Sl_MBusy                        => SPLB_Sl_MBusy                      ,

         -- PIM Interconnect port signals -------------------------------------
         Pi2ad_InitDone                  => MPMC_PIM_InitDone                  ,
         Pi2ad_AddrAck                   => MPMC_PIM_AddrAck                   ,
         Pi2ad_wrfifo_almostFull         => MPMC_PIM_WrFIFO_AlmostFull         ,
         Pi2ad_wrFifo_empty              => MPMC_PIM_WrFIFO_Empty              ,
         Ad2pi_Addr                      => MPMC_PIM_Addr                      ,
         Ad2pi_AddrReq                   => MPMC_PIM_AddrReq                   ,
         Ad2pi_RNW                       => MPMC_PIM_RNW                       ,
         Ad2pi_Size                      => MPMC_PIM_Size                      ,

         -- Read Support Module signals ---------------------------------------
         Rd2ad_rd_cmplt                  => Rd2ad_rd_cmplt                     ,
         Rd2Ad_Rd_Data_Cmplt             => Rd2Ad_Rd_Data_Cmplt                ,
         Rd2ad_busy                      => Rd2ad_busy                         ,
         Rd2Ad_Rd_Error                  => Rd2Ad_Rd_Error                     ,

         Ad2rd_plb_npi_sync              => Ad2rd_plb_npi_sync                 ,
         Ad2rd_new_cmd                   => Ad2rd_new_cmd                      ,
         Ad2rd_mid                       => Ad2rd_mid                          ,
         Ad2rd_strt_addr                 => Ad2rd_strt_addr                    ,
         Ad2rd_single                    => Ad2rd_single                       ,
         Ad2rd_cacheline_4               => Ad2rd_cacheline_4                  ,
         Ad2rd_cacheline_8               => Ad2rd_cacheline_8                  ,
         Ad2rd_burst_16                  => Ad2rd_burst_16                     ,
         Ad2rd_burst_32                  => Ad2rd_burst_32                     ,
         Ad2rd_burst_64                  => Ad2rd_burst_64                     ,

         Ad2rd_xfer_wdcnt                => Ad2rd_xfer_wdcnt                   ,
         Ad2rd_xfer_width                => Ad2rd_xfer_width                   ,
         Ad2rd_queue_data                => Ad2rd_queue_data                   ,
         Ad2Rd_clk_ratio_1_1             => Ad2Rd_clk_ratio_1_1                ,

         -- Write Support Module signals --------------------------------------
         Wr2ad_block_infifo              => Wr2ad_block_infifo                 ,
         Wr2ad_wr_cmplt                  => Wr2ad_wr_cmplt                     ,
         Wr2ad_busy                      => Wr2ad_busy                         ,
         Wr2ad_error                     => Wr2ad_error                        ,

         Ad2wr_plb_npi_sync              => Ad2wr_plb_npi_sync                 ,
         Ad2wr_new_cmd                   => Ad2wr_new_cmd                      ,
         Ad2wr_mid                       => Ad2wr_mid                          ,
         Ad2wr_strt_addr                 => Ad2wr_strt_addr                    ,
         Ad2wr_single                    => Ad2wr_single                       ,
         Ad2wr_cacheline_4               => Ad2wr_cacheline_4                  ,
         Ad2wr_cacheline_8               => Ad2wr_cacheline_8                  ,
         Ad2wr_burst_16                  => Ad2wr_burst_16                     ,
         Ad2wr_burst_32                  => Ad2wr_burst_32                     ,
         Ad2wr_burst_64                  => Ad2wr_burst_64                     ,
         Ad2wr_wrbe                      => Ad2wr_wrbe                         ,

         Ad2wr_xfer_wrdcnt               => Ad2wr_xfer_wrdcnt                  ,
         Ad2wr_xfer_width                => Ad2wr_xfer_width                   ,
         Ad2Wr_clk_ratio_1_1             => Ad2Wr_clk_ratio_1_1                ,

         -- ECC signals -------------------------------------------------------
         Ad2pi_RdModWr                   => MPMC_PIM_RdModWr

     );


   PIM_WRITE_MODULE :  entity mpmc_v6_03_a.plbv46_write_module
      generic map
      (
      --IPIC generics
      -------------------------------------------------------------------------
         C_SPLB_MID_WIDTH                => C_SPLB_MID_WIDTH                   ,
         C_SPLB_NUM_MASTERS              => C_SPLB_NUM_MASTERS                 ,
         C_SPLB_SMALLEST_MASTER          => C_SPLB_SMALLEST_MASTER             ,
         C_SPLB_AWIDTH                   => C_SPLB_AWIDTH                      ,
         C_SPLB_DWIDTH                   => C_SPLB_DWIDTH                      ,
         C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH               ,
         C_PLBV46_PIM_TYPE               => C_PLBV46_PIM_TYPE                  ,
         C_MPMC_WR_FIFO_TYPE             => C_MPMC_PIM_WR_FIFO_TYPE            ,
         C_SPLB_SUPPORT_BURSTS           => C_SPLB_SUPPORT_BURSTS              ,
         C_MPMC_PIM_DATA_WIDTH           => C_MPMC_PIM_DATA_WIDTH
      )
      port map
      (
         SPLB_Clk                        => SPLB_Clk                           ,
         PI_Clk                          => MPMC_Clk                           ,
         Sync_Mpmc_Rst                   => Sync_Mpmc_Rst                      ,
         Sync_Plb_Rst                    => Sync_Plb_Rst                       ,

         -- PLB Write Interface
         PLB_wrDBus                      => SPLB_PLB_wrDBus                    ,
         PLB_wrBurst                     => SPLB_PLB_wrBurst                   ,
         Sl_wrDAck                       => SPLB_Sl_wrDack                     ,
         Sl_wrComp                       => SPLB_Sl_wrComp                     ,
         Sl_wrBTerm                      => SPLB_Sl_wrBTerm                    ,
         Sl_MWrErr                       => SPLB_Sl_MWrErr                     ,
         Sl_MIRQ                         => SPLB_Sl_MIRQ                       ,

         -- Address Module Interface
         Ad2Wr_PLB_NPI_Sync              => Ad2Wr_PLB_NPI_Sync                 ,
         Ad2Wr_New_Cmd                   => Ad2wr_new_cmd                      ,
         Ad2Wr_MID                       => Ad2wr_mid                          ,
         Ad2Wr_Strt_Addr                 => Ad2wr_strt_addr                    ,

         --Transmit Type
         Ad2Wr_Single                    => Ad2wr_single                       ,
         Ad2Wr_Cacheline_4               => Ad2wr_cacheline_4                  ,
         Ad2Wr_Cacheline_8               => Ad2wr_cacheline_8                  ,
         Ad2Wr_Burst_16                  => Ad2wr_burst_16                     ,
         Ad2Wr_Burst_32                  => Ad2wr_burst_32                     ,

         Ad2Wr_Xfer_WrdCnt               => Ad2Wr_Xfer_WrdCnt                  ,
         Ad2Wr_Xfer_Width                => Ad2Wr_Xfer_Width                   ,
         Ad2Wr_WrBE                      => Ad2Wr_WrBE                         ,
         Ad2Wr_clk_ratio_1_1             => Ad2Wr_clk_ratio_1_1                ,

         Wr2Ad_Wr_Cmplt                  => Wr2ad_wr_cmplt                     ,
         Wr2Ad_Busy                      => Wr2ad_busy                         ,
         Wr2Ad_Error                     => Wr2ad_error                        ,
         Wr2Ad_Block_InFIFO              => Wr2ad_block_infifo                 ,

         -- NPI Inteface
         PI2Wr_WrFIFO_AlmostFull         => MPMC_PIM_WrFIFO_AlmostFull         ,
         PI2Wr_WrFIFO_Empty              => MPMC_PIM_WrFIFO_Empty              ,

         Wr2PI_WrFIFO_Data               => MPMC_PIM_WrFIFO_Data               ,

         Wr2PI_WrFIFO_BE                 => MPMC_PIM_WrFIFO_BE                 ,

         Wr2PI_WrFIFO_Push               => MPMC_PIM_WrFIFO_Push               ,
         Wr2PI_WrFIFO_Flush              => MPMC_PIM_WrFIFO_Flush
      );


   PIM_READ_MODULE : entity mpmc_v6_03_a.plbv46_rd_support_single
      generic map
      (

         C_SPLB_NATIVE_DWIDTH      => C_SPLB_NATIVE_DWIDTH,                                      
            --  Native Data Width of this PLB Slave                                              
                                                                                                 
                                                                                                 
         -- PLBV46 parameterization                                                              
         C_SPLB_MID_WIDTH          => C_SPLB_MID_WIDTH,                                          
            -- The width of the Master ID bus                                                    
            -- This is set to log2(C_SPLB_NUM_MASTERS)                                           
                                                                                                 
         C_SPLB_NUM_MASTERS        => C_SPLB_NUM_MASTERS,                                        
            -- The number of Master Devices connected to the PLB bus                             
            -- Research this to find out default value                                           
                                                                                                 
         C_SPLB_SMALLEST_MASTER    => C_SPLB_SMALLEST_MASTER,                                    
            -- The dwidth (in bits) of the smallest master that will                             
            -- access this Slave.                                                                
                                                                                                 
         C_SPLB_AWIDTH             => C_SPLB_AWIDTH,                                             
            --  width of the PLB Address Bus (in bits)                                           
                                                                                                 
         C_SPLB_DWIDTH             => C_SPLB_DWIDTH,                                             
            --  Width of the PLB Data Bus (in bits)                                              
                                                                                                 
         C_PLBV46_PIM_TYPE         => C_PLBV46_PIM_TYPE,                                         
            --  Configuration Type (PLB, DPLB, IPLB)                                             
                                                                                                 
         C_SPLB_SUPPORT_BURSTS     => C_SPLB_SUPPORT_BURSTS,                                     
            --  Burst Support                                                                    
                                                                                                 
                                                                                                 
         -- NPI Parameterization                                                                 
         C_NPI_DWIDTH              => C_MPMC_PIM_DATA_WIDTH,                                     
            -- Sets the NPI Read Data port width.                                                
                                                                                                 
         C_PI_RDWDADDR_WIDTH       => C_MPMC_PIM_RDWDADDR_WIDTH,                                 
            -- sets the bit width of the PI_RdWdAddr port                                        
                                                                                                 
                                                                                                 
         C_PI_RDFIFO_LATENCY       => C_MPMC_PIM_RDFIFO_LATENCY,                                 
            -- Read Data latency (in NPI Clock periods) measured from                            
            -- assertion of PI_RdFIFO_Pop to data availability on the                            
            -- NPI2RD_RdFIFO_D input port.                                                       

         C_FAMILY                  => C_FAMILY   
      )
      port map
      (

         -- System Ports
         SPLB_Clk                     => SPLB_Clk                           ,
         SPLB_Rst                     => SPLB_Rst                           ,

         PI_Clk                       => MPMC_Clk                           ,
         PIM_Rst                      => sync_plb_rst                       ,

         -- PLBV46 Interface
         PLB_rdBurst                  => SPLB_PLB_rdBurst                   ,

         Sl_rdDAck                    => SPLB_Sl_rdDAck                     ,
         Sl_rdDBus                    => SPLB_Sl_rdDBus                     ,

         Sl_rdWdAddr                  => SPLB_Sl_rdWdAddr                   ,
         Sl_rdComp                    => SPLB_Sl_rdComp                     ,
         Sl_rdBTerm                   => SPLB_Sl_rdBTerm                    ,
         Sl_MRdErr                    => SPLB_Sl_MRdErr                     ,


         -- Address Decode Interface
         Ad2Rd_PLB_NPI_Sync           => Ad2Rd_PLB_NPI_Sync                 ,
         Ad2Rd_New_Cmd                => Ad2rd_new_cmd                      ,
         Ad2Rd_Strt_Addr              => Ad2rd_strt_addr                    ,

         Ad2Rd_Xfer_Width             => Ad2rd_xfer_width                   ,
         Ad2Rd_Xfer_WdCnt             => Ad2rd_xfer_wdcnt                   ,
         Ad2Rd_Single                 => Ad2rd_single                       ,
         Ad2Rd_Cacheline_4            => Ad2rd_cacheline_4                  ,
         Ad2Rd_Cacheline_8            => Ad2rd_cacheline_8                  ,
         Ad2Rd_Burst_16               => Ad2rd_burst_16                     ,
         Ad2Rd_Burst_32               => Ad2rd_burst_32                     ,
         Ad2Rd_Burst_64               => Ad2rd_burst_64                     ,
         Ad2rd_queue_data             => Ad2rd_queue_data                   ,
         Ad2Rd_clk_ratio_1_1          => Ad2Rd_clk_ratio_1_1                ,

         Rd2Ad_Rd_Cmplt               => Rd2ad_rd_cmplt                     ,
         Rd2Ad_Rd_Data_Cmplt          => Rd2Ad_Rd_Data_Cmplt                ,
         Rd2Ad_Rd_Busy                => Rd2ad_busy                         ,
         Rd2Ad_Rd_Error               => Rd2Ad_Rd_Error                     ,

         -- NPI Read Interface
         NPI2RD_RdFIFO_Empty          => MPMC_PIM_RdFIFO_Empty              ,
         NPI2RD_RdFIFO_Data_Available => MPMC_PIM_RdFIFO_Data_Available     ,
         NPI2RD_RdFIFO_RdWdAddr       => MPMC_PIM_RdFIFO_RdWd_Addr          ,
         NPI2RD_RdFIFO_D              => MPMC_PIM_RdFIFO_Data               ,
         NPI2RD_RdFIFO_Latency        => MPMC_PIM_RdFIFO_Latency            ,

         Rd2NPI_RdFIFO_Flush          => MPMC_PIM_RdFIFO_Flush              ,
         Rd2NPI_RdFIFO_Pop            => MPMC_PIM_RdFIFO_Pop

         );

end generate;


end rtl_pim;





















