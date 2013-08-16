-----------------------------------------------------------------------------
-- (c) Copyright 2006 - 2009 Xilinx, Inc. All rights reserved.
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
-----------------------------------------------------------------------------
-- Filename:        plbv46_rd_support_isplb.vhd
--
-- Description:
--    This VHDL design implements the read support module that is part of the
-- PLBV46 PIM. The PIM is used to interface the MPMC3 to a PLBV46.
--
--
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--              plbv46_rd_support_isplb.vhd
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
--
-- History:
--   DET   1/9/2007       Initial Version
--
--     DET     1/30/2007     Initial
-- ~~~~~~
--     - Added 32-bit NPI Support
-- ^^^^^^
--
--     DET     2/8/2007     Initial
-- ~~~~~~
--     - 1:N PLB/NPI Clk Ratio support
-- ^^^^^^
--
--     DET     3/1/2007     Initial
-- ~~~~~~
--     - Fixed read data steering bug
--     - Added additional gating to sl_rdwdaddr output
-- ^^^^^^
--
--     DET     3/7/2007     Initial
-- ~~~~~~
--     - Added more gating to sl_rdwdaddr output
--     - Modified the Steer Address counter load value
--       calculation to eliminate overflows on large
--       bursts
-- ^^^^^^
--
--     DET     3/16/2007     Initial
-- ~~~~~~
--     - Fixed a bug in the Sl_rdack FLOP clear signal for the
--       Singles request case.
-- ^^^^^^
--
--     DET     3/20/2007     Initial
-- ~~~~~~
--     - Made another correction for the Sl_rdack flops. MTI
--       simulation not working correctly for register to register
--       transfer when clock edges aligned but source and dest
--       clocks are different names.
-- ^^^^^^
--
--     DET     4/10/2007     Initial
-- ~~~~~~
--     - Made significant design changes for 1:N clocking support in lue of
--       MTI simulation problem with edge aligned clocks but with different names.
-- ^^^^^^
--
--     DET     4/11/2007     Initial
-- ~~~~~~
--     - Converted all SPLB_Clk process to PI_Clk.
--     - Fixed a cacheline rdwdaddr bug.
-- ^^^^^^
--
--     DET     4/17/2007     Initial
-- ~~~~~~
--     - Added SRL FIFO for FIFO Latency support
-- ^^^^^^
--
--     DET     5/8/2007     Initial
-- ~~~~~~
--     - Fixed a bug with the NPI Read Count Load Value calculation
--       for 64-bit NPI case
-- ^^^^^^
--     DET     5/15/2007     Initial
-- ~~~~~~
--     - Replaced the use of sm_xfer_done with sig_cmd_cmplt_reg. This
--       approach provides tighter coupling between the Address Decoder
--       and the Read Support module at the completion of a Read request.
-- ^^^^^^
--
--     MW      5/18/2007     Initial
-- ~~~~~~
--     - Added a generate statements (READ_WD_ADDR_NPI32 & READ_WD_ADDR_NPI64)
--       for the REG_PLB_RDWDADDR process.  One for the 64 bit PIM support
--       which contains the original logic and the other for the 32 bit PIM
--       support which can use rdwdaddr bit 3 directly.
-- ^^^^^^
--
--     MW      06/07/2007    Initial
-- ~~~~~~
--     - Removed all logic except that needed to support DSPLB type
-- ^^^^^^
--
--     MW      07/02/2007    Initial
-- ~~~~~~
--     - Added Ad2rd_queue_data to hold off read pops until sa_valid address
--       is promoted to pa_valid and address decoder addracks
-- ^^^^^^
--
--     MW      07/11/2007    Initial
-- ~~~~~~
--     - Added register to Rd2NPI_RdFIFO_Pop to reguce levels of logic.
--       Still anded with NPI2RD_RdFIFO_Empty
--     - Above change resulted in modifcation of RD_LATENCY_0, RD_LATENCY_1,
--       and RD_LATENCY_2 logic
--     - Above change required a delay in the sig_decr_npi_rdcnt logic
-- ^^^^^^
--
--       MW        08/27/2007   - Initial Version
-- ~~~~~~
--       - Added Ad2rd_clk_ratio_1_1 to port
-- ^^^^^^
--
--     MW      10/19/2007    9.2 SP2
-- ~~~~~~
--     - Added PLB_CLK register delay to all read signals going to PLB
--       to fix false timing errors
-- ^^^^^^
--
--       MW        12/09/2007   - Initial Version
-- ~~~~~~
--       - Removed unnecessary logic based upon code coverage analysis
--          - IPLB will only support a 64bit PLB Master on a 64bit PLB Bus
--             with a 64bit NPI in a P2P configuration.  No other configuration
--             is allowed.  No other master sizes, plb bus sizes, or NPI widths
--             are supported.  The shared configuration is not supported either.
-- ^^^^^^
--
--     MW      06/05/2008    plbv46_pim_v2_02_a - Release 11 
-- ~~~~~~
--    -  Removed dependancies on proc_common
-- ^^^^^^
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
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.CONV_INTEGER;
use IEEE.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library proc_common_v3_00_a;
Use proc_common_v3_00_a.srl_fifo_f;

library mpmc_v6_03_a;
Use mpmc_v6_03_a.plbv46_data_steer_mirror;

library unisim; -- Required for Xilinx primitives
use unisim.vcomponents.all;

-------------------------------------------------------------------------------

entity plbv46_rd_support_isplb is
  generic (


    C_SPLB_NATIVE_DWIDTH      : integer range 32 to 128 := 64;
       --  Native Data Width of this PLB Slave


   -- PLBV46 parameterization
    C_SPLB_MID_WIDTH            : integer range 0 to 4:= 3;
       -- The width of the Master ID bus
       -- This is set to log2(C_SPLB_NUM_MASTERS)

    C_SPLB_NUM_MASTERS          : integer range 1 to 16 := 8;
       -- The number of Master Devices connected to the PLB bus
       -- Research this to find out default value

    C_SPLB_SMALLEST_MASTER      : integer range 32 to 128 := 64;
       -- The dwidth (in bits) of the smallest master that will
       -- access this Slave.

    C_SPLB_AWIDTH             : integer range 32 to 36  := 32;
       --  width of the PLB Address Bus (in bits)

    C_SPLB_DWIDTH             : integer range 32 to 128 := 128;
       --  Width of the PLB Data Bus (in bits)

    C_PLBV46_PIM_TYPE         : string := "PLB";
       --  Configuration Type (PLB, DPLB, IPLB)

    C_SPLB_SUPPORT_BURSTS     : integer range 0 to 1    := 0;
       --  Burst Support


    -- NPI Parameterization
    C_NPI_DWIDTH              : Integer range 32 to 128 := 64;
       -- Sets the NPI Read Data port width.

    C_PI_RDWDADDR_WIDTH       : Integer range 3 to 5 := 4;
       -- sets the bit width of the PI_RdWdAddr port


    C_PI_RDFIFO_LATENCY       : Integer range 0 to 2 := 0 ;
       -- Read Data latency (in NPI Clock periods) measured from
       -- assertion of PI_RdFIFO_Pop to data availability on the
       -- NPI2RD_RdFIFO_D input port.


    C_FAMILY                   : string := "virtex5"

    );
  port (

   -- System Ports
    SPLB_Clk                     : in  std_logic;
    SPLB_Rst                     : in  std_logic;

    PI_Clk                       : in  std_logic;
    PIM_Rst                      : in  std_logic;

   -- PLBV46 Interface
    PLB_rdBurst                  : in  std_logic;

    Sl_rdDAck                    : Out std_logic;
    Sl_rdDBus                    : out std_logic_vector(0 to
                                       C_SPLB_DWIDTH-1);
    Sl_rdWdAddr                  : out std_logic_vector(0 to 3);
    Sl_rdComp                    : Out std_logic;
    Sl_rdBTerm                   : Out std_logic;
    Sl_MRdErr                    : out std_logic_vector(0 to
                                       C_SPLB_NUM_MASTERS-1);

   -- Address Decode Interface
    Ad2Rd_PLB_NPI_Sync           : In  std_logic;
    Ad2Rd_New_Cmd                : In  std_logic;
    Ad2Rd_Strt_Addr              : in  std_logic_vector(0 to
                                       C_SPLB_AWIDTH-1);
    Ad2Rd_Xfer_Width             : in  std_logic_vector(0 to 1);
    Ad2Rd_Xfer_WdCnt             : in  std_logic_vector(0 to 7);
    Ad2Rd_Single                 : In  std_logic;
    Ad2Rd_Cacheline_4            : In  std_logic;
    Ad2Rd_Cacheline_8            : In  std_logic;
    Ad2Rd_Burst_16               : In  std_logic;
    Ad2Rd_Burst_32               : In  std_logic;
    Ad2Rd_Burst_64               : In  std_logic;
    Ad2rd_queue_data             : In  std_logic;
    Ad2Rd_clk_ratio_1_1          : In  std_logic;

    Rd2Ad_Rd_Cmplt               : out std_logic;
    Rd2Ad_Rd_Data_Cmplt          : out std_logic;
    Rd2Ad_Rd_Busy                : out std_logic;
    Rd2Ad_Rd_Error               : out std_logic;

  -- NPI Read Interface
    NPI2RD_RdFIFO_Empty          : In  std_logic;
    NPI2RD_RdFIFO_Data_Available : In  std_logic;
    NPI2RD_RdFIFO_RdWdAddr       : In  std_logic_vector(C_PI_RDWDADDR_WIDTH-1 downto 0);
    NPI2RD_RdFIFO_D              : In  std_logic_vector(C_NPI_DWIDTH-1 downto 0);
    NPI2RD_RdFIFO_Latency        : In  std_logic_vector(1 downto 0);

    Rd2NPI_RdFIFO_Flush          : Out std_logic;
    Rd2NPI_RdFIFO_Pop            : Out std_logic

    );

end entity plbv46_rd_support_isplb;


architecture implementation of plbv46_rd_support_isplb is

  -- Temporary SRL FIFO Support

   Constant SRL_FIFO_DEPTH      : integer := 16;
   Constant SRL_FIFO_ADDR_WIDTH : integer := 4;
   Constant SRL_FIFO_WIDTH      : integer := C_SPLB_NATIVE_DWIDTH +
                                             C_PI_RDWDADDR_WIDTH;







  -- Constants
  Constant STEER_ADDR_WIDTH    : integer := 10; -- allow for 9 address cntr bits

  Constant WRD_ADDR_BIT_INDEX  : integer := STEER_ADDR_WIDTH-3;
  Constant DWRD_ADDR_BIT_INDEX : integer := STEER_ADDR_WIDTH-4;

  Constant DBEAT_OF_1          : std_logic_vector(0 to 7) := "00000001";

  Constant NPI_RDCNT_SIZE        : integer := 8; -- alloted Bit width of counter

  Constant MAX_CLK_RATIO_CNT     : integer := 15; -- alloted Bit width of counter


  -- Types

       type XFER_WIDTH_TYPE is (
                 WORD,
                 DBLWRD,
                 QWRD
                 );



     type rd_state_type is (
                 IDLE,
                 PREFLUSH,
                 DATA_TO_PLB,
                 POSTFLUSH
                 );

  -- Signals

  signal Bus_Rst                     : std_logic;

  Signal sm_state_ns                 : rd_state_type;
  Signal sm_state                    : rd_state_type;

  signal sm_xfer_done_ns             : std_logic;
  signal sm_xfer_done                : std_logic;

  signal sig_doing_a_cacheln         : std_logic;
  signal sig_doing_a_cacheln_reg     : std_logic;
  signal sig_doing_a_cacheln4_reg    : std_logic;
  signal sig_doing_a_cacheln8_reg    : std_logic;

  Signal sig_plb_done                : std_logic;

  signal sig_sl_rdbterm              : std_logic;
  signal sig_sl_rdcomp               : std_logic;
  signal sig_sl_rdack                : std_logic;
  signal sig_sl_rddbus               : std_logic_vector(0 to
                                       C_SPLB_DWIDTH-1);
  Signal sig_sl_rdwdaddr             : std_logic_vector(0 to
                                       C_PI_RDWDADDR_WIDTH-1);

  signal sig_plb_rd_dreg             : std_logic_vector(0 to
                                       C_SPLB_DWIDTH-1);
  Signal sig_plb_rdwdaddr_reg        : std_logic_vector(0 to
                                       C_PI_RDWDADDR_WIDTH-1);
  Signal sig_pop_valid               : std_logic;
  signal sig_adj_pop_valid           : std_logic;

  signal sig_rdfifo_data_reg         : std_logic_vector(0 to
                                       C_NPI_DWIDTH-1);
  signal sig_rdfifo_data_bigend      : std_logic_vector(0 to
                                       C_NPI_DWIDTH-1);
  signal sig_rdwdaddr_bigend         : std_logic_vector(0 to
                                       C_PI_RDWDADDR_WIDTH-1);

  Signal sig_fifo_dreg_has_data      : std_logic;
  signal sig_clr_fifo_read_dreg      : std_logic;
  signal sig_make_fifo_dreg_stale    : std_logic;
  signal sig_fifo_data_willgo_to_plb : std_logic;
  signal sig_get_next_fifo_data      : std_logic;
  signal sig_need_new_fifo_data      : std_logic;
  Signal sig_rdwdaddr_ld_value_slv   : std_logic_vector(0 to
                                       STEER_ADDR_WIDTH-1);
  signal sig_rdwdaddr_ld_value       : integer range 0 to
                                       (2**STEER_ADDR_WIDTH)-1 := 0;

  signal sig_pop_fifo                : std_logic;
  signal sig_preflush_fifo           : std_logic;

  signal sig_rd2ad_rd_error          : std_logic;
  signal sig_xfer_go                 : std_logic;

  signal sig_plb_dbeat_cnt           : integer range 0 to 255 := 0;
  signal sig_plb_dbeat_cnt_ld_value  : integer range 0 to 255 := 0;
  signal sig_wdcnt_to_dbeats_slv     : std_logic_vector(0 to 7);
  signal sig_dbcnt_eq_2              : std_logic;
  signal sig_dbcnt_eq_0              : std_logic;
  signal sig_decr_dbeat_cnt          : std_logic;
  signal sig_dbcnt_ld_val_eq_2       : std_logic;

  signal sig_clr_rdcomp              : std_logic;
  signal sig_rdcomp_reg              : std_logic;


  Signal sig_steer_addr_ld_value_slv : std_logic_vector(0 to
                                       STEER_ADDR_WIDTH-1);
  Signal sig_steer_addr_slv          : std_logic_vector(0 to
                                       STEER_ADDR_WIDTH-1);
  Signal sig_steer_addr_ld_value     : integer range 0 to
                                       (2**STEER_ADDR_WIDTH)-1 := 0;
  Signal sig_steer_addr              : integer range 0 to
                                       (2**STEER_ADDR_WIDTH)-1 := 0;
  Signal sig_steer_addr_incr         : integer range 0 to 16  := 0;
  signal sig_incr_steer_addr         : std_logic;

  signal sig_ld_new_cmd              : std_logic;

  signal sig_cmd_cmplt_reg           : std_logic;
  signal sig_cmd_busy_reg            : std_logic;



  signal sig_sl_rdack_i              : std_logic;
  signal sig_clr_plb_rdwdaddr        : std_logic;

  signal sig_npi_rdcnt_ld_value      : integer range 0 to
                                       2**NPI_RDCNT_SIZE;
  signal sig_npi_rdcnt               : integer range 0 to
                                       2**NPI_RDCNT_SIZE;
  signal sig_decr_npi_rdcnt          : std_logic;
  signal sig_decr_npi_rdcnt_int      : std_logic;

  signal sig_npi_rdcnt_eq_0          : std_logic;
  signal sig_npi_rdcnt_neq_0         : std_logic;

  Signal sig_plb_busy_reg            : std_logic;
  signal sig_clr_plb_dreg            : std_logic;

  Signal sig_advance_data2plb        : std_logic;
  Signal sig_plb_dreg_empty          : std_logic;
  Signal sig_plb_dreg_going_empty    : std_logic;






   ----------------------------
   -- SRL FIFO stuff

  signal sig_srl_fifo_rst        : std_logic;

  signal sig_srl_fifo_write      : std_logic;

  signal sig_srl_fifo_wrdata     : std_logic_vector(0 to SRL_FIFO_WIDTH-1);
  signal sig_srl_fifo_rddata     : std_logic_vector(0 to SRL_FIFO_WIDTH-1);

  signal sig_rdfifo_rdwdaddr_reg : std_logic_vector(0 to C_PI_RDWDADDR_WIDTH-1);

  signal sig_pop_srl_fifo        : std_logic;
  signal sig_srl_fifo_empty      : std_logic;
  signal sig_srl_fifo_addr       : std_logic_vector(0 to SRL_FIFO_ADDR_WIDTH-1);
  signal sig_srl_adj_fifo_full   : std_logic;
  signal sig_srl_fifo_full       : std_logic;

  signal sig_steer_addr_loaded   : std_logic;


  signal Rd2NPI_RdFIFO_Pop_reg   : std_logic;
  Signal sig_pop_valid_reg       : std_logic;



  SIGNAL Sl_rdDAck_to_plb        : std_logic;
  signal sig_sl_rdack_i_dly      : std_logic;
  SIGNAL Sl_rdDBus_to_plb        : std_logic_vector(0 to C_SPLB_DWIDTH-1);
  SIGNAL Sl_rdWdAddr_to_plb      : std_logic_vector(0 to 3);
  SIGNAL Sl_rdComp_to_plb        : std_logic;
  SIGNAL Sl_rdBTerm_to_plb       : std_logic;

  signal sig_cmd_cmplt_reg_dly   : std_logic;
  signal sig_cmd_busy_reg_dly    : std_logic;


-- Register duplication attribute assignments

  Attribute KEEP : string; -- declaration
  Attribute EQUIVALENT_REGISTER_REMOVAL : string; -- declaration

  Attribute KEEP of sig_sl_rdack   : signal is "TRUE"; -- definition
  Attribute KEEP of sig_sl_rdack_i : signal is "TRUE"; -- definition

  Attribute EQUIVALENT_REGISTER_REMOVAL of sig_sl_rdack   : signal is "no";
  Attribute EQUIVALENT_REGISTER_REMOVAL of sig_sl_rdack_i : signal is "no";



  -- Component Declarations



begin --(architecture implementation)

  -- Remap the PLB Clock and Reset signal names for
  -- internal use
   --Bus_Clk <=  SPLB_Clk;
   --Bus_Rst <=  SPLB_Rst;


  -- Output s
   Sl_MRdErr           <= (others => '0') ; --(no errors to report to PLB)

   Sl_rdBTerm          <= Sl_rdBTerm_to_plb  ;--            sig_sl_rdbterm  ;
   Sl_rdComp           <= Sl_rdComp_to_plb   ;--            sig_sl_rdcomp   ;
   Sl_rdDAck           <= Sl_rdDAck_to_plb   ;--            sig_sl_rdack    ;
   Sl_rdDBus           <= Sl_rdDBus_to_plb   ;--            sig_plb_rd_dreg   ;
   Sl_rdWdAddr         <= Sl_rdWdAddr_to_plb ;--            sig_plb_rdwdaddr_reg ;

   Rd2Ad_Rd_Cmplt      <= sig_cmd_cmplt_reg_dly;--          sig_cmd_cmplt_reg;
   Rd2Ad_Rd_Data_Cmplt <= Sl_rdComp_to_plb   ;--            sig_sl_rdcomp;

   Rd2Ad_Rd_Busy       <= sig_plb_busy_reg ;

   Rd2Ad_Rd_Error      <= sig_rd2ad_rd_error;

   Rd2NPI_RdFIFO_Flush <= '0';  -- currently not useable by MPMC

--   Rd2NPI_RdFIFO_Pop   <= sig_pop_fifo and
--                          not(NPI2RD_RdFIFO_Empty);
   Rd2NPI_RdFIFO_Pop   <= Rd2NPI_RdFIFO_Pop_reg and
                          not(NPI2RD_RdFIFO_Empty);


   sig_ld_new_cmd      <= Ad2Rd_New_Cmd and
                          Ad2Rd_PLB_NPI_Sync;


   sig_rd2ad_rd_error     <= '0';


   sig_get_next_fifo_data <= Ad2Rd_PLB_NPI_Sync     and
                             sig_need_new_fifo_data and
                             sig_steer_addr_loaded;



  sig_doing_a_cacheln  <= Ad2Rd_Cacheline_4 or
                          Ad2Rd_Cacheline_8;


  sig_pop_fifo <=  sig_xfer_go and

                   (

                    (sig_npi_rdcnt_neq_0    and        -- reading data that will
                     not(sig_srl_adj_fifo_full))       -- go to the PLB

                   );



   REG_RD2NPI_RDFIFO_POP : Process(Pi_clk)
   begin

      if rising_edge(Pi_clk) then
         if (PIM_Rst = '1') then
            Rd2NPI_RdFIFO_Pop_reg <= '0';
         else
            Rd2NPI_RdFIFO_Pop_reg <= sig_pop_fifo and
                          not(NPI2RD_RdFIFO_Empty);
         end if;
      end if;
   end process;

  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_PLB_RD_BUSY
  --
  -- Process Description:
  -- This process implements the logic for the Busy signal sent
  -- to the Address Decoder Module. It is set when a new
  -- command is issued and deasserted when the read Complete
  -- is asserted from the PLB Read Bus.
  --
  -------------------------------------------------------------
  DO_PLB_RD_BUSY : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then

            sig_plb_busy_reg <= '0';

          Elsif (sl_rdcomp_to_plb = '1' and--sig_sl_rdcomp      = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') Then

            sig_plb_busy_reg <= '0';

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') then

            sig_plb_busy_reg <= '1';

          else
            null;  -- hold current state
          end if;
       end if;
     end process DO_PLB_RD_BUSY;


  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_XFER_GO
  --
  -- Process Description:
  --    This process implements the Transfer Go control
  --
  -------------------------------------------------------------
  DO_XFER_GO : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst      = '1' or
              --sm_xfer_done = '1') then
              sig_cmd_cmplt_reg = '1') then
            sig_xfer_go  <= '0';
          elsif (sig_ld_new_cmd = '1') then
            sig_xfer_go  <= '1';
          else
            null; -- hold current state
          end if;
       end if;
     end process DO_XFER_GO;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_CMD_CMPLT
  --
  -- Process Description:
  -- This process implements the logic for the Command complete
  -- flop. The flop asserts its output for 1 PLB clock cycle.
  --
  -- Note:  sm_xfer_done_ns is asserted only when the signal
  -- Ad2Rd_PLB_NPI_Sync is asserted.
  --
  -------------------------------------------------------------
  DO_CMD_CMPLT : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then

            sig_cmd_cmplt_reg <= '0';

          Elsif (sig_cmd_cmplt_reg  = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') Then

            sig_cmd_cmplt_reg <= '0';


          elsif (Ad2Rd_PLB_NPI_Sync      = '1' and
                 sig_rdcomp_reg          = '1' and
                 sig_sl_rdack_i          = '1' and
                 sig_cmd_busy_reg        = '1') then

            sig_cmd_cmplt_reg <= '1';


--mw          --elsif (sm_xfer_done_ns = '1') then
--mw          elsif (Ad2Rd_PLB_NPI_Sync      = '1' and
--mw                 sig_plb_done            = '1' and
--mw                 sig_cmd_busy_reg        = '1') then
--mw
--mw            sig_cmd_cmplt_reg <= '1';

          else
            null;  -- hold current state
          end if;
       end if;
     end process DO_CMD_CMPLT;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_CMD_BUSY
  --
  -- Process Description:
  -- This process implements the logic for the Command Busy
  -- flop. The flop asserts its output while the Read Module
  -- is actively processing a read command.
  --
  -- Note:  sig_cmd_cmplt_reg is asserted for 1 PLB clock
  -- period.
  --
  -------------------------------------------------------------
  DO_CMD_BUSY : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then

            sig_cmd_busy_reg <= '0';

          Elsif (sig_cmd_cmplt_reg  = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') Then

            sig_cmd_busy_reg <= '0';

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') then

            sig_cmd_busy_reg <= '1';

          else
            null;  -- hold current state
          end if;
       end if;
     end process DO_CMD_BUSY;





  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: REG_DOING_CACHELINE
  --
  -- Process Description:
  --    This process implements the registers to sample and
  -- hold the input qualifiers from the Address Decode block.
  --
  -------------------------------------------------------------
  REG_DOING_CACHELINE : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst      = '1' or
              --sm_xfer_done = '1') then
              sig_cmd_cmplt_reg = '1') then

            sig_doing_a_cacheln_reg   <= '0';
            sig_doing_a_cacheln4_reg  <= '0';
            sig_doing_a_cacheln8_reg  <= '0';

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') then

            sig_doing_a_cacheln_reg   <= sig_doing_a_cacheln;
            sig_doing_a_cacheln4_reg  <= Ad2Rd_Cacheline_4;
            sig_doing_a_cacheln8_reg  <= Ad2Rd_Cacheline_8;

          else
            null; -- hold current state
          end if;
       end if;
     end process REG_DOING_CACHELINE;


  -------------------------------------------------------------
  -- Combinational Process
  --
  -- Label: READ_SM_COMB
  --
  -- Process Description:
  -- This process implements the combinational half of the
  -- Read state machine.
  --
  -------------------------------------------------------------
  READ_SM_COMB : process (sm_state,
                          PIM_Rst,
                          sig_ld_new_cmd,
                          sig_plb_done,
                          Ad2Rd_PLB_NPI_Sync)

     begin


       If (PIM_Rst = '1') Then

         sm_state_ns          <= IDLE;
         sm_xfer_done_ns      <= '0';

       else

        -- Default values
         sm_state_ns          <= IDLE;
         sm_xfer_done_ns      <= '0';

         case sm_state is

           -----------------------
           when IDLE =>
           -----------------------

             if (sig_ld_new_cmd       = '1') then

               sm_state_ns        <= DATA_TO_PLB;

             else

              sm_state_ns      <= IDLE;

             End if;


           -----------------------
           when DATA_TO_PLB =>
           -----------------------

             If (sig_plb_done = '1') Then

               sm_state_ns      <= POSTFLUSH;

             else

               sm_state_ns      <= DATA_TO_PLB;

             End if;



           -----------------------
           when POSTFLUSH =>
           -----------------------

             If (Ad2Rd_PLB_NPI_Sync      = '1') then

               sm_state_ns      <= IDLE;
               sm_xfer_done_ns  <= '1';

             Else

               sm_state_ns      <= POSTFLUSH;

             End if;



           -----------------------
           when others =>
           -----------------------

             sm_state_ns      <= IDLE;

         end case;

       End if;

     end process READ_SM_COMB;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: READ_SM_SYNC
  --
  -- Process Description:
  -- This process implements the synchronous half of the
  -- Read state machine.
  --
  -------------------------------------------------------------
  READ_SM_SYNC : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then
            sm_state          <= IDLE;
            sm_xfer_done      <= '0' ;

          else
            sm_state          <= sm_state_ns       ;
            sm_xfer_done      <= sm_xfer_done_ns   ;

          end if;
       end if;
     end process READ_SM_SYNC;



  ---------------------------------------------------------------------
  -- Read POP Counter Logic
  -- This is used for tracking the number of fifo pops that actually
  -- are required to put read data on the PLB.  This is independent of
  -- pre-flush and post-flush operations.
  --
  ---------------------------------------------------------------------



   sig_npi_rdcnt_eq_0 <= '1'
      When (sig_npi_rdcnt = 0)
      Else '0';

    sig_npi_rdcnt_neq_0 <= not(sig_npi_rdcnt_eq_0);

--    sig_decr_npi_rdcnt  <= (not(NPI2RD_RdFIFO_Empty) and   -- fifo has data
--                                                           -- reading data that will
--                            sig_npi_rdcnt_neq_0      and   -- go to PLB via SRL FIFO
--                            not(sig_srl_adj_fifo_full));       -- SRL FIFO not Full



   REG_DECR_RDCNT : process (pi_clk)
   begin

      if rising_edge(pi_clk) then
         if (PIM_Rst = '1') then
            sig_decr_npi_rdcnt_int <= '0';
         else
            sig_decr_npi_rdcnt_int <= (sig_pop_valid and   -- fifo has data
                                                           -- reading data that will
                            sig_npi_rdcnt_neq_0      and   -- go to PLB via SRL FIFO
                            not(sig_srl_adj_fifo_full));   -- SRL FIFO not Full
         end if;
      end if;
   end process;

   sig_decr_npi_rdcnt <= sig_decr_npi_rdcnt_int and
                        (not(sig_srl_adj_fifo_full));




   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: NPI_RD_COUNTER
   --
   -- Process Description:
   --   This process implements the counter that keeps track of
   -- the needed fifo pop operations for supplying the actual
   -- requested read data to the PLB.
   --
   -------------------------------------------------------------
   NPI_RD_COUNTER : process (PI_Clk)
      begin
        if (PI_Clk'event and PI_Clk = '1') then
           if (PIM_Rst = '1') then

             sig_npi_rdcnt <= 0;

           elsif (sig_ld_new_cmd = '1') then

             sig_npi_rdcnt <= sig_npi_rdcnt_ld_value;

           Elsif (sig_decr_npi_rdcnt  = '1' and
                  sig_npi_rdcnt_eq_0  = '0') Then

             sig_npi_rdcnt <= sig_npi_rdcnt-1;

           else
             null;  -- hold count value
           end if;
        end if;
      end process NPI_RD_COUNTER;


--   ------------------------------------------------------------
--   -- If Generate
--   --
--   -- Label: DO_CALC_FOR_NPI64
--   --
--   -- If Generate Description:
--   --  This ifgen implements the needed calculations for the
--   -- 64-bit NPI case.
--   --
--   --
--   ------------------------------------------------------------
   DO_CALC_FOR_NPI64 : if (C_NPI_DWIDTH = 64) generate

     begin


        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: CALC_NPI64_RDCNT
        --
        -- Process Description:
        -- This process calculates the number of NPI FIFO pops
        -- needed to transfer the requested number of data beats on
        -- the PLB for a 64-bit NPI.
        --
        -------------------------------------------------------------
        CALC_NPI64_RDCNT : process (Ad2Rd_Xfer_WdCnt,
                                    Ad2Rd_Strt_Addr,
                                    Ad2Rd_Cacheline_4,
                                    Ad2Rd_Cacheline_8)


           begin


             if (Ad2Rd_Cacheline_4 = '1') then

                sig_npi_rdcnt_ld_value <= 2;

             else --  Cacheline_8
                sig_npi_rdcnt_ld_value <= 4;


             end if;


           end process CALC_NPI64_RDCNT;



      end generate DO_CALC_FOR_NPI64;







--   ------------------------------------------------------------
--   -- If Generate
--   --
--   -- Label: DO_CALC_FOR_NPI128
--   --
--   -- If Generate Description:
--   --  This ifgen implements the needed calculations for the
--   -- 128-bit NPI case.
--   --
--   --
--   ------------------------------------------------------------
   DO_CALC_FOR_NPI128 : if (C_NPI_DWIDTH = 128) generate

     begin


        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: CALC_NPI128_RDCNT
        --
        -- Process Description:
        -- This process calculates the number of NPI FIFO pops
        -- needed to transfer the requested number of data beats on
        -- the PLB for a 128-bit NPI.
        --
        -------------------------------------------------------------
        CALC_NPI128_RDCNT : process (Ad2Rd_Xfer_WdCnt,
                                     Ad2Rd_Strt_Addr,
                                    Ad2Rd_Cacheline_4,
                                    Ad2Rd_Cacheline_8)


           begin



             if (Ad2Rd_Cacheline_4 = '1') then

                sig_npi_rdcnt_ld_value <= 1;

             else -- Cacheline_8
                sig_npi_rdcnt_ld_value <= 2;

             end if;


           end process CALC_NPI128_RDCNT;



      end generate DO_CALC_FOR_NPI128;















  ---------------------------------------------------------------------
  -- Conversion for NPI Little Endian format to PLB Big Endian Format
  ---------------------------------------------------------------------


  -- rdwdaddr Conversion
  sig_rdwdaddr_bigend <= NPI2RD_RdFIFO_RdWdAddr
   when sig_doing_a_cacheln_reg = '1'
   else (others => '0');





  -- Verilog snippet from MPMC2 PLB PIM for NPI Read FIFO Data
  -- // Byte reordering within read data bus
  -- generate
  --   for (i = 0; i < C_PI_DATA_WIDTH; i = i + 8) begin : rddata_reorder
  --     assign PI_RdFIFO_Data_i[i:i+7] = PI_RdFIFO_Data[i+7:i];
  --   end
  -- endgenerate




  -- VHDL version

  -------------------------------------------------------------
  -- Combinational Process
  --
  -- Label: DATA_ENDIAN_CONVERT
  --
  -- Process Description:
  --    This process implements the conversion from little
  -- endian format to big endian format of the Read FIFO
  -- data.
  --
  -------------------------------------------------------------
  DATA_ENDIAN_CONVERT : process (NPI2RD_RdFIFO_D)

    Variable bit_index : integer;

    begin

      for byte_index in 0 to (C_NPI_DWIDTH/8)-1 loop

        bit_index := byte_index*8;

        sig_rdfifo_data_bigend(bit_index to bit_index+7) <=
                 NPI2RD_RdFIFO_D(bit_index+7 downto bit_index);

      end loop;

    end process DATA_ENDIAN_CONVERT;


  ---------------------------------------------------------------------
  -- End Conversion for NPI Little Endian format to PLB Big Endian Format
  ---------------------------------------------------------------------





  ---------------------------------------------------------------------
  -- Start Read FIFO Data Register and Support Logic
  ---------------------------------------------------------------------



   sig_make_fifo_dreg_stale  <=  sig_advance_data2plb and
                                 sig_need_new_fifo_data;


   sig_fifo_dreg_has_data   <= not(sig_srl_fifo_empty) and Ad2rd_queue_data;




-------------------------------------------------------------------
-------------------------------------------------------------------
-- Read FIFO Data Register logic
--
-------------------------------------------------------------------

   sig_clr_fifo_read_dreg <=  (sig_rdcomp_reg  and
                               sig_sl_rdack_i  and
                               Ad2Rd_PLB_NPI_Sync) or
                               sig_plb_done;







   ------------------------------------------------------------
   -- Process Description:
   -- This process registers sig_pop_fifo and NPI2RD_RdFIFO_Empty
   --
   --
   ------------------------------------------------------------

   REG_SIG_POP_VALID : process (Pi_clk)
   begin

      if rising_edge(Pi_clk) then
         if PIM_Rst = '1' then
            sig_pop_valid_reg <= '0';
         else
            sig_pop_valid_reg <= sig_pop_fifo and
                                not(NPI2RD_RdFIFO_Empty);
         end if;
      end if;
   end process;

   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: RD_LATENCY_0
   --
   -- If Generate Description:
   -- This IfGen implements the RdFIFO Latency case of 0.
   --
   --
   ------------------------------------------------------------
   RD_LATENCY_0 : if (C_PI_RDFIFO_LATENCY = 0) generate

      -- local signals

      signal sig_srl_fifo_full_early          : std_logic;

      begin


        sig_pop_valid <=  sig_pop_valid_reg and
                          not(NPI2RD_RdFIFO_Empty);

        sig_adj_pop_valid <=  (sig_pop_valid_reg and not(NPI2RD_RdFIFO_Empty));
                               --and sig_flush_cnt_eq_0);

        sig_fifo_data_willgo_to_plb <= sig_adj_pop_valid and sig_npi_rdcnt_neq_0;
                                       --;and sig_flush_cnt_eq_0

       -- Advance FIFO Full indication by 1 so that overrun does
       -- not occur due to the 1 clock MPMC read fifo latency
       sig_srl_fifo_full_early <= '1'
         When sig_srl_fifo_addr = "1110" and
              sig_srl_fifo_full = '0'
         else '0';

        sig_srl_adj_fifo_full <= sig_srl_fifo_full_early or
                                 sig_srl_fifo_full;

      end generate RD_LATENCY_0;




   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: RD_LATENCY_1
   --
   -- If Generate Description:
   -- This IfGen implements the RdFIFO Latency case of 1.
   --
   --
   ------------------------------------------------------------
   RD_LATENCY_1 : if (C_PI_RDFIFO_LATENCY = 1) generate

      -- local signals
        signal sig_pop_valid_dly1               : std_logic;
--        signal sig_flush_cnt_eq_0_dly1          : std_logic;
        signal sig_npi_rdcnt_neq_0_dly1         : std_logic;
        signal sig_srl_fifo_full_early          : std_logic;


      begin


        sig_pop_valid <=  sig_pop_valid_reg and
                          not(NPI2RD_RdFIFO_Empty);

        sig_adj_pop_valid <=  (sig_pop_valid_dly1);
                               --and sig_flush_cnt_eq_0_dly1);

        sig_fifo_data_willgo_to_plb <= sig_adj_pop_valid  and sig_npi_rdcnt_neq_0_dly1;
                                      --;and sig_flush_cnt_eq_0_dly1

       -- Advance FIFO Full indication by 2 so that overrun does
       -- not occur due to the 2 clock MPMC read fifo latency
        sig_srl_fifo_full_early <= '1'
         When (sig_srl_fifo_addr = "1101" or
               sig_srl_fifo_addr = "1110") and
               sig_srl_fifo_full = '0'
         else '0';

        sig_srl_adj_fifo_full <= sig_srl_fifo_full_early or
                                 sig_srl_fifo_full;



        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: DELAY_FIFO_POP_1
        --
        -- Process Description:
        -- Delay the Rd FIFO Pop by 1 clock to generate the data
        -- valid indicator
        --
        -------------------------------------------------------------
        DELAY_FIFO_POP_1 : process (PI_Clk)
           begin
             if (PI_Clk'event and PI_Clk = '1') then
                if (PIM_Rst = '1') then
                  sig_pop_valid_dly1   <= '0';
--                  sig_flush_cnt_eq_0_dly1 <= '0';
                  sig_npi_rdcnt_neq_0_dly1 <= '0';
                else
                  sig_pop_valid_dly1 <= sig_pop_valid;

--                  sig_flush_cnt_eq_0_dly1 <= sig_flush_cnt_eq_0;

                  sig_npi_rdcnt_neq_0_dly1 <= sig_npi_rdcnt_neq_0;


                end if;
             end if;
           end process DELAY_FIFO_POP_1;

    end generate RD_LATENCY_1;

   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: RD_LATENCY_2
   --
   -- If Generate Description:
   -- This IfGen implements the RdFIFO Latency case of 2.
   --
   --
   ------------------------------------------------------------
   RD_LATENCY_2 : if (C_PI_RDFIFO_LATENCY = 2) generate

      -- local signals
        signal sig_pop_valid_dly1               : std_logic;
        signal sig_pop_valid_dly2               : std_logic;
--        signal sig_flush_cnt_eq_0_dly1          : std_logic;
--        signal sig_flush_cnt_eq_0_dly2          : std_logic;
        signal sig_npi_rdcnt_neq_0_dly1         : std_logic;
        signal sig_npi_rdcnt_neq_0_dly2         : std_logic;
        signal sig_srl_fifo_full_early          : std_logic;


      begin



        sig_pop_valid <=  sig_pop_valid_reg and
                          not(NPI2RD_RdFIFO_Empty);

        sig_adj_pop_valid <=  (sig_pop_valid_dly2);
                               --and sig_flush_cnt_eq_0_dly2);

        sig_fifo_data_willgo_to_plb <= sig_adj_pop_valid  and sig_npi_rdcnt_neq_0_dly2;
                                       --sig_flush_cnt_eq_0_dly2 and;

       -- Advance FIFO Full indication by 2 so that overrun does
       -- not occur due to the 2 clock MPMC read fifo latency
        sig_srl_fifo_full_early <= '1'
         When (sig_srl_fifo_addr = "1100" or
               sig_srl_fifo_addr = "1101" or
               sig_srl_fifo_addr = "1110") and
               sig_srl_fifo_full = '0'
         else '0';

        sig_srl_adj_fifo_full <= sig_srl_fifo_full_early or
                                 sig_srl_fifo_full;



        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: DELAY_FIFO_POP_1
        --
        -- Process Description:
        -- Delay the Rd FIFO Pop by 1 clock to generate the data
        -- valid indicator
        --
        -------------------------------------------------------------
        DELAY_FIFO_POP_1 : process (PI_Clk)
           begin
             if (PI_Clk'event and PI_Clk = '1') then
                if (PIM_Rst = '1') then
                  sig_pop_valid_dly1   <= '0';
                  sig_pop_valid_dly2   <= '0';
--                  sig_flush_cnt_eq_0_dly1 <= '0';
--                  sig_flush_cnt_eq_0_dly2 <= '0';
                  sig_npi_rdcnt_neq_0_dly1 <= '0';
                  sig_npi_rdcnt_neq_0_dly2 <= '0';
                else
                  sig_pop_valid_dly1 <= sig_pop_valid;
                  sig_pop_valid_dly2 <= sig_pop_valid_dly1;

--                  sig_flush_cnt_eq_0_dly1 <= sig_flush_cnt_eq_0;
--                  sig_flush_cnt_eq_0_dly2 <= sig_flush_cnt_eq_0_dly1;

                  sig_npi_rdcnt_neq_0_dly1 <= sig_npi_rdcnt_neq_0;
                  sig_npi_rdcnt_neq_0_dly2 <= sig_npi_rdcnt_neq_0_dly1;


                end if;
             end if;
           end process DELAY_FIFO_POP_1;

      end generate RD_LATENCY_2;





-------------------------------------------------------------------
-------------------------------------------------------------------
  -- Start PLB Read Bus Controls


   sig_sl_rdbterm   <='0';

   sig_sl_rdcomp    <=  sig_rdcomp_reg and
                        sig_sl_rdack_i;


-------------------------------------------------------------------
-------------------------------------------------------------------
-- PLB Read Data Steering Address Counter Logic
--
-------------------------------------------------------------------

   -------------------------------------------------------------
   -- Combinational Process
   --
   -- Label: GEN_RDWDADDR_LD_VAL
   --
   -- Process Description:
   --    This process formats the value that is loaded
   -- into the Steering Address Counter during Cacheline
   -- read operations.
   --
   -------------------------------------------------------------
   GEN_RDWDADDR_LD_VAL : process (sig_rdfifo_rdwdaddr_reg)
      begin

       -- Default to zeros
        sig_rdwdaddr_ld_value_slv <= (others => '0');

       -- Now overload the applicable bits
        sig_rdwdaddr_ld_value_slv((STEER_ADDR_WIDTH-2)-
                                   C_PI_RDWDADDR_WIDTH to
                                 STEER_ADDR_WIDTH-3) <=
                sig_rdfifo_rdwdaddr_reg;

      end process GEN_RDWDADDR_LD_VAL;


   sig_rdwdaddr_ld_value <=
             CONV_INTEGER('0' & sig_rdwdaddr_ld_value_slv);



   -------------------------------------------------------------
   -- Combinational Process
   --
   -- Label: RIP_STEER_ADDR
   --
   -- Process Description:
   -- This process rips the lower 4 bits of the starting address
   -- and overlays them into the lower 4 bits of the Steering
   -- Address Load value
   --
   -------------------------------------------------------------
   RIP_STEER_ADDR : process (Ad2Rd_Strt_Addr)
     begin

       -- Init to zeros
       sig_steer_addr_ld_value_slv <= (others => '0');

       -- Now rip 4 address bits
       sig_steer_addr_ld_value_slv(STEER_ADDR_WIDTH-4 to
                                   STEER_ADDR_WIDTH-1)
           <= Ad2Rd_Strt_Addr(C_SPLB_AWIDTH-4 to
                              C_SPLB_AWIDTH-1);


     end process RIP_STEER_ADDR;





   sig_steer_addr_ld_value <=
        CONV_INTEGER('0' & sig_steer_addr_ld_value_slv);


    sig_incr_steer_addr  <= sig_advance_data2plb;


    sig_steer_addr_slv <=
        CONV_STD_LOGIC_VECTOR(sig_steer_addr,
                              STEER_ADDR_WIDTH);





   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: DO_STEER_ADDR_CNTR
   --
   -- Process Description:
   --   This process implements the Read Data Steering address
   -- counter.
   --
   -------------------------------------------------------------
   DO_STEER_ADDR_CNTR : process (PI_Clk)
      begin
        if (PI_Clk'event and PI_Clk = '1') then

           if (PIM_Rst            = '1' or
              (sig_cmd_cmplt_reg  = '1' and
               Ad2Rd_PLB_NPI_Sync = '1')) then

             sig_steer_addr        <= 0;
             sig_steer_addr_loaded <= '0';

           elsif (sig_ld_new_cmd      = '1' and
                  Ad2Rd_PLB_NPI_Sync  = '1') then

             sig_steer_addr        <= sig_steer_addr_ld_value;
             sig_steer_addr_loaded <= not(sig_doing_a_cacheln);

           Elsif (sig_doing_a_cacheln_reg = '1' and          --mw catch first cl addr - early
                  sig_steer_addr_loaded   = '0' and
                  sig_fifo_dreg_has_data  = '1' and
                  Ad2Rd_PLB_NPI_Sync      = '1') Then

              sig_steer_addr        <= sig_rdwdaddr_ld_value;
              sig_steer_addr_loaded <= '1';

           Elsif (sig_doing_a_cacheln_reg = '1' and          --mw catch subsequent cl addr
                  sig_pop_srl_fifo        = '1' ) Then

              sig_steer_addr        <= sig_rdwdaddr_ld_value;
              sig_steer_addr_loaded <= '1';

           Elsif (sig_incr_steer_addr = '1') Then

             sig_steer_addr <= sig_steer_addr +
                               sig_steer_addr_incr;
             sig_steer_addr_loaded <= '1';

           else
             null;  -- hold current value
           end if;
        end if;
      end process DO_STEER_ADDR_CNTR;



--   ------------------------------------------------------------
--   -- If Generate
--   --
--   -- Label: DATA_LOOKAHEAD_NPI32
--   --
--   -- If Generate Description:
--   --   This IfGen implements the logic needed to request more
--   -- FIFO data relative to the PLB Data transfer width.
--   -- In this case the NPI width is 32 so new FIFO data will be
--   -- needed every PLB data beat.
--   --
--   ------------------------------------------------------------
--   DATA_LOOKAHEAD_NPI32 : if (C_NPI_DWIDTH = 32) generate
--
--      begin
--
--         sig_need_new_fifo_data <= '1';
--         sig_steer_addr_incr    <= 4;
--
--         sig_inhib_get_second <= '0';
--
--      end generate DATA_LOOKAHEAD_NPI32;



   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: DATA_LOOKAHEAD_NPI64
   --
   -- If Generate Description:
   --   This IfGen implements the logic needed to request more
   -- FIFO data relative to the PLB Data transfer width.
   -- In this case the NPI width is 64 so new FIFO data will be
   -- needed every other PLB data beat if the transfer width is
   -- 32, or every data beat if the transfer width is 64.
   --
   ------------------------------------------------------------
   DATA_LOOKAHEAD_NPI64 : if (C_NPI_DWIDTH = 64) generate

      signal lsig_xfer_mode  : XFER_WIDTH_TYPE;

      begin

         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: S_H_TRANSFER_MODE_64
         --
         -- Process Description:
         --     This process samples and holds the PLB transfer width
         -- for the ensuing Read data phase.
         --
         -------------------------------------------------------------
         S_H_TRANSFER_MODE_64 : process (PI_Clk)
            begin
              if (PI_Clk'event and PI_Clk = '1') then
                 if (PIM_Rst      = '1' or
                     --sm_xfer_done = '1') then
                     sig_cmd_cmplt_reg = '1') then

                   lsig_xfer_mode      <= WORD;
                   sig_steer_addr_incr <= 4;

                 elsif (sig_ld_new_cmd     = '1' and
                        Ad2Rd_PLB_NPI_Sync = '1') then
--N/A Only 64 bit master on 64 bit bus with a 64 bit NPI is going to be supported
--N/A                   If (Ad2Rd_Xfer_Width = "00") Then
--N/A
--N/A                     lsig_xfer_mode      <= WORD; -- 32 bit xfer
--N/A                     sig_steer_addr_incr <= 4;
--N/A
--N/A                   else
--N/A
                     lsig_xfer_mode      <= DBLWRD; -- 64 bit xfer
                     sig_steer_addr_incr <= 8;

--N/A                   End if;

                 else
                   null; -- hold current state
                 end if;
              end if;
            end process S_H_TRANSFER_MODE_64;


         sig_need_new_fifo_data <=
                    sig_steer_addr_slv(WRD_ADDR_BIT_INDEX)
          when  (lsig_xfer_mode = WORD)
          else '1';   -- DWRD Xfer


      end generate DATA_LOOKAHEAD_NPI64;



   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: DATA_LOOKAHEAD_NPI128
   --
   -- If Generate Description:
   --   This IfGen implements the logic needed to request more
   -- FIFO data relative to the PLB Data transfer width and the
   -- state of the data steering address counter.
   -- In this case the NPI width is 128 so new FIFO data will be
   -- needed on:
   --  - Every 4th PLB data beat if the transfer width is 32
   --  - Every 2nd PLB data beat if the transfer width is 64
   --  - Every PLB data beat if the transfer width is 128.
   --
   ------------------------------------------------------------
   DATA_LOOKAHEAD_NPI128 : if (C_NPI_DWIDTH = 128) generate


       signal lsig_xfer_mode   : XFER_WIDTH_TYPE;
       Signal lsig_addr45_and  : std_logic;
       Signal lsig_addr4       : std_logic;


      begin


         lsig_addr45_and <= sig_steer_addr_slv(DWRD_ADDR_BIT_INDEX) and
                            sig_steer_addr_slv(WRD_ADDR_BIT_INDEX);

         lsig_addr4      <= sig_steer_addr_slv(DWRD_ADDR_BIT_INDEX);




         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: S_H_TRANSFER_MODE_128
         --
         -- Process Description:
         --     This process samples and holds the PLB transfer width
         -- for the ensuing Read data phase.
         --
         -------------------------------------------------------------
         S_H_TRANSFER_MODE_128 : process (PI_Clk)
            begin
              if (PI_Clk'event and PI_Clk = '1') then
                 if (PIM_Rst           = '1' or
                     --sm_xfer_done = '1') then
                     sig_cmd_cmplt_reg = '1') then

                   lsig_xfer_mode      <= WORD;
                   sig_steer_addr_incr <= 4;

                 elsif (sig_ld_new_cmd     = '1' and
                        Ad2Rd_PLB_NPI_Sync = '1') then

                   If (Ad2Rd_Xfer_Width = "00") Then

                     lsig_xfer_mode      <= WORD; -- 32 bit xfer
                     sig_steer_addr_incr <= 4;

                   elsif (Ad2Rd_Xfer_Width = "01") Then

                     lsig_xfer_mode      <= DBLWRD; -- 64 bit xfer
                     sig_steer_addr_incr <= 8;

                   else

                     lsig_xfer_mode      <= QWRD; -- 128 bit xfer
                     sig_steer_addr_incr <= 16;

                   End if;

                 else
                   null; -- hold current state
                 end if;
              end if;
            end process S_H_TRANSFER_MODE_128;


         sig_need_new_fifo_data <= lsig_addr45_and
          when (lsig_xfer_mode = WORD)
          Else lsig_addr4
          When (lsig_xfer_mode = DBLWRD)
          Else '1';     -- QWRD xfer


      end generate DATA_LOOKAHEAD_NPI128;

-------------------------------------------------------------------
-------------------------------------------------------------------
-- PLB Data Beat Counter Logic
--
-------------------------------------------------------------------


  sig_wdcnt_to_dbeats_slv <= Ad2Rd_Xfer_WdCnt
     when Ad2Rd_Xfer_Width = "00" -- 32 bits
     Else '0' & Ad2Rd_Xfer_WdCnt(0 to 6)
     when Ad2Rd_Xfer_Width = "01" -- 64 bits
     Else "00" & Ad2Rd_Xfer_WdCnt(0 to 5); -- 128 bits

  sig_plb_dbeat_cnt_ld_value <= CONV_INTEGER('0' & sig_wdcnt_to_dbeats_slv);

  sig_decr_dbeat_cnt <= sig_sl_rdack_i and
                        Ad2Rd_PLB_NPI_Sync;


  sig_dbcnt_ld_val_eq_2 <= '1'
    When sig_plb_dbeat_cnt_ld_value = 2
    Else '0';

  sig_dbcnt_eq_2 <= '1'
    when  sig_plb_dbeat_cnt = 2
    Else '0';

  sig_dbcnt_eq_0 <= '1'
    when  sig_plb_dbeat_cnt = 0
    Else '0';


  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_PLB_DBEAT_CNT
  --
  -- Process Description:
  --    This process implements the PLB Read data beat counter.
  --
  -------------------------------------------------------------
  DO_PLB_DBEAT_CNT : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then

            sig_plb_dbeat_cnt <= 0;

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') then

            sig_plb_dbeat_cnt <= sig_plb_dbeat_cnt_ld_value;

          Elsif (sig_decr_dbeat_cnt = '1' and
                 sig_dbcnt_eq_0     = '0') Then

            sig_plb_dbeat_cnt <= sig_plb_dbeat_cnt - 1;

          else

            null; -- hold current value

          end if;
       end if;
     end process DO_PLB_DBEAT_CNT;






---------------------------------------------------------------------
---------------------------------------------------------------------
---- PLB Read Burst Terminate Logic
----
---------------------------------------------------------------------
--
--
--
--  sig_clr_bterm  <=  sig_bterm_reg   and
--                     sig_sl_rdack_i  and
--                     Ad2Rd_PLB_NPI_Sync;
--
--
--
--  -------------------------------------------------------------
--  -- Synchronous Process with Sync Reset
--  --
--  -- Label: DO_RD_BTERM
--  --
--  -- Process Description:
--  --  This process implements the flop that generates the read
--  -- burst terminate signal.
--  --
--  -------------------------------------------------------------
--  DO_RD_BTERM : process (PI_Clk)
--     begin
--       if (PI_Clk'event and PI_Clk = '1') then
--          if (PIM_Rst       = '1' or
--              sig_clr_bterm = '1') then
--
--            sig_bterm_reg <= '0';
--
--          elsif (sig_ld_new_cmd        = '1' and
--                 Ad2Rd_PLB_NPI_Sync    = '1' and
--                 sig_dbcnt_ld_val_eq_2 = '1' and
--                 sig_doing_burst       = '1') then
--
--            sig_bterm_reg <= '1';
--
--          Elsif (sig_dbcnt_eq_3      = '1' and
--                 Ad2Rd_PLB_NPI_Sync  = '1' and
--                 sig_sl_rdack_i      = '1' and
--                 sig_doing_burst_s_h = '1') Then
--
--            sig_bterm_reg <= '1';
--
--          else
--
--            null;  -- hold state
--
--          end if;
--       end if;
--     end process DO_RD_BTERM;







-------------------------------------------------------------------
-------------------------------------------------------------------
-- PLB Read Complete Logic
--
-------------------------------------------------------------------



   sig_clr_rdcomp <= sig_rdcomp_reg   and
                     sig_sl_rdack_i   and
                     Ad2Rd_PLB_NPI_Sync;




  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_RD_COMP
  --
  -- Process Description:
  --  This process implements the flop that generates the read
  -- complete signal.
  --
  -------------------------------------------------------------
  DO_RD_COMP : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst        = '1' or
              sig_clr_rdcomp = '1') then

            sig_rdcomp_reg <= '0';


          Elsif (Ad2Rd_PLB_NPI_Sync  = '1' and
                 sig_sl_rdack_i      = '1' and
                 sig_dbcnt_eq_2      = '1') Then

            sig_rdcomp_reg <= '1';

          else
            null; -- hold state
          end if;
       end if;
     end process DO_RD_COMP;




  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_PLB_DONE
  --
  -- Process Description:
  --    This process implements the flop that generates the
  -- flag indicating the PLB Read Data Phase is complete for
  -- the last request from the Address Decoder.
  --
  -------------------------------------------------------------
  DO_PLB_DONE : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst             = '1' or
              (sig_ld_new_cmd     = '1' and
               Ad2Rd_PLB_NPI_Sync = '1')) then

            sig_plb_done <= '0';

          elsif (Ad2Rd_PLB_NPI_Sync = '1' and
                 sig_rdcomp_reg     = '1' and
                 sig_sl_rdack_i     = '1') then

            sig_plb_done  <= '1';

          else
            null;  -- hold state
          end if;
       end if;
     end process DO_PLB_DONE;





  ------------------------------------------------------------
  -- Instance: I_DATA_SUPPORT
  --
  -- Description:
  --    This module performs the required read data bus
  -- mirroring and steering functionality for connection
  -- to the PLBV46.
  --
  ------------------------------------------------------------
   I_DATA_SUPPORT : entity mpmc_v6_03_a.plbv46_data_steer_mirror
   generic map (
     C_STEER_ADDR_WIDTH   =>  STEER_ADDR_WIDTH      ,
     C_SPLB_DWIDTH        =>  C_SPLB_DWIDTH         ,
     C_SPLB_NATIVE_DWIDTH =>  C_SPLB_NATIVE_DWIDTH  ,
     C_SMALLEST_MASTER    =>  C_SPLB_SMALLEST_MASTER
     )
   port map (

     Steer_Addr_In   =>  sig_steer_addr_slv ,
     Data_In         =>  sig_rdfifo_data_reg,
     Data_Out        =>  sig_sl_rddbus
     );








   ---------------------------------------------------------------
   --
   -- PLB Read Data Register Logic
   --
   sig_plb_dreg_going_empty <= sig_sl_rdack_i and
                               Ad2Rd_PLB_NPI_Sync;

   sig_advance_data2plb <=  sig_steer_addr_loaded  and
                            sig_fifo_dreg_has_data and
                            Ad2Rd_PLB_NPI_Sync;




   sig_clr_plb_dreg <=  PIM_Rst or
                        sig_plb_done or
                        (
                         sig_sl_rdack_i     and
                         Ad2Rd_PLB_NPI_Sync and
                          (
                            not(sig_fifo_dreg_has_data) or
                            sig_rdcomp_reg
                          )
                        );


   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_PLB_RD_DATA
   --
   -- Process Description:
   -- This process implements the PLB Read Data Register. The
   -- PLB Read data is mirrored and Steered prior to input to
   -- this register.
   --
   -------------------------------------------------------------
   REG_PLB_RD_DATA : process (PI_Clk)
      begin
        if (PI_Clk'event and PI_Clk = '1') then
           if (sig_clr_plb_dreg = '1') then

             sig_plb_rd_dreg      <= (others => '0');
             sig_sl_rdack         <= '0';
             sig_sl_rdack_i       <= '0';

           Elsif (sig_advance_data2plb = '1') Then

             sig_plb_rd_dreg      <= sig_sl_rddbus;
             sig_sl_rdack         <= '1'; -- to bus
             sig_sl_rdack_i       <= '1'; -- internal use

           else

             null;  -- hold state

           end if;
        end if;
      end process REG_PLB_RD_DATA;

         -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_PLB_RD_DATA
   --
   -- Process Description:
   -- This process implements the PLB Read Data Register. The
   -- PLB Read data is mirrored and Steered prior to input to
   -- this register.
   --
   -------------------------------------------------------------
   REG_PLB_RD_DATA_TO_PLB : process (SPLB_Clk)
      begin
        if (SPLB_Clk'event and SPLB_Clk = '1') then
           if (pim_rst = '1') then
             Sl_rdDAck_to_plb    <= '0';
             sig_sl_rdack_i_dly  <= '0';
             Sl_rdDBus_to_plb    <= (others => '0');
             Sl_rdWdAddr_to_plb  <= (others => '0');
             Sl_rdComp_to_plb    <= '0';
             Sl_rdBTerm_to_plb   <= '0';

             sig_cmd_cmplt_reg_dly <= '0';
             sig_cmd_busy_reg_dly  <= '0';
           Else
             Sl_rdDAck_to_plb    <= sig_sl_rdack;
             sig_sl_rdack_i_dly  <= sig_sl_rdack_i;
             Sl_rdDBus_to_plb    <= sig_plb_rd_dreg;
             Sl_rdWdAddr_to_plb  <= sig_plb_rdwdaddr_reg;
             Sl_rdComp_to_plb    <= sig_sl_rdcomp;
             Sl_rdBTerm_to_plb   <= sig_sl_rdbterm;

             sig_cmd_cmplt_reg_dly <= sig_cmd_cmplt_reg;
             sig_cmd_busy_reg_dly  <= sig_cmd_busy_reg;
           end if;
        end if;
      end process REG_PLB_RD_DATA_TO_PLB;



    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: GEN_PLB_DREG_EMPTY
    --
    -- Process Description:
    -- This process generates a registered flag that keeps track
    -- of the data freshness in the PLB Data register.
    --
    -------------------------------------------------------------
    GEN_PLB_DREG_EMPTY : process (PI_Clk)
       begin
         if (PI_Clk'event and PI_Clk = '1') then
            if (PIM_Rst          = '1' or
                sig_clr_plb_dreg = '1') then

              sig_plb_dreg_empty <= '1';

            elsif (Ad2Rd_New_Cmd      = '1' and
                   Ad2Rd_PLB_NPI_Sync = '1') then

              sig_plb_dreg_empty  <= '1';

            Elsif (sig_advance_data2plb = '1') Then

              sig_plb_dreg_empty <= '0';

            Elsif (sig_plb_dreg_going_empty = '1') Then

              sig_plb_dreg_empty <= not(sig_fifo_dreg_has_data);

            else
              null;  -- hold current state
            end if;
         end if;
       end process GEN_PLB_DREG_EMPTY;



















   -------------------------------------------------------------
   --
   -- RDWDADDR stuff


   sig_sl_rdwdaddr  <= sig_steer_addr_slv((STEER_ADDR_WIDTH-2)-
                                           C_PI_RDWDADDR_WIDTH to
                                          STEER_ADDR_WIDTH-3);

   sig_clr_plb_rdwdaddr <= PIM_Rst or
                           (
                            Ad2Rd_PLB_NPI_Sync  and
                            (sig_clr_fifo_read_dreg        or
                             not(sig_fifo_dreg_has_data)  or
                             not(sig_doing_a_cacheln_reg))
                           );


   READ_WD_ADDR_NPI64 : if (C_NPI_DWIDTH = 64) generate
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_PLB_RDWDADDR
   --
   -- Process Description:
   -- This process implements the register for the rdwdaddr
   -- output onto the PLB during non-cacheline ops.
   --
   --  Bit 3 toggles with sig_steer_addr_slv(7) which is the
   --  lsb since the addr is shifted left 2x.  This is needed for
   --  when the master size is less than the PIM size.
   -------------------------------------------------------------
   REG_PLB_RDWDADDR : process (PI_Clk)
      begin
        if (PI_Clk'event and PI_Clk = '1') then

           if (sig_clr_plb_rdwdaddr = '1') then

             sig_plb_rdwdaddr_reg <= (others => '0');

           Elsif (sig_advance_data2plb = '1') Then

             sig_plb_rdwdaddr_reg(0) <= '0'; -- cacheline 16 not supported
             sig_plb_rdwdaddr_reg(1) <= sig_rdfifo_rdwdaddr_reg(1) and
                                        sig_doing_a_cacheln8_reg;
             sig_plb_rdwdaddr_reg(2) <= sig_rdfifo_rdwdaddr_reg(2);
             sig_plb_rdwdaddr_reg(3) <= sig_rdfifo_rdwdaddr_reg(3) or
                                        sig_steer_addr_slv(STEER_ADDR_WIDTH-3);

           else

             null;  -- hold state

           end if;
        end if;
      end process REG_PLB_RDWDADDR;
    end generate;


--   READ_WD_ADDR_NPI32 : if (C_NPI_DWIDTH = 32) generate
--   -------------------------------------------------------------
--   -- Synchronous Process with Sync Reset
--   --
--   -- Label: REG_PLB_RDWDADDR
--   --
--   -- Process Description:
--   -- This process implements the register for the rdwdaddr
--   -- output onto the PLB during non-cacheline ops.
--   -- Bit 3 does not need to toggle since the master size is
--   -- equal to the pim size
--   -------------------------------------------------------------
--   REG_PLB_RDWDADDR : process (PI_Clk)
--      begin
--        if (PI_Clk'event and PI_Clk = '1') then
--
--           if (sig_clr_plb_rdwdaddr = '1') then
--
--             sig_plb_rdwdaddr_reg <= (others => '0');
--
--           Elsif (sig_advance_data2plb = '1') Then
--
--             sig_plb_rdwdaddr_reg(0) <= '0'; -- cacheline 16 not supported
--             sig_plb_rdwdaddr_reg(1) <= sig_rdfifo_rdwdaddr_reg(1) and
--                                        sig_doing_a_cacheln8_reg;
--             sig_plb_rdwdaddr_reg(2) <= sig_rdfifo_rdwdaddr_reg(2);
--             sig_plb_rdwdaddr_reg(3) <= sig_rdfifo_rdwdaddr_reg(3);
--           else
--
--             null;  -- hold state
--
--           end if;
--        end if;
--      end process REG_PLB_RDWDADDR;
--    end generate;




  ------------------------------------------------------------
  -- Temporary approach to use intermediate SRL FIFO for


  sig_srl_fifo_rst    <=  PIM_Rst or sig_cmd_cmplt_reg;

  sig_srl_fifo_write  <= sig_fifo_data_willgo_to_plb;

  sig_srl_fifo_wrdata <= sig_rdfifo_data_bigend &
                         sig_rdwdaddr_bigend;


  sig_rdfifo_data_reg      <= sig_srl_fifo_rddata(0 to (SRL_FIFO_WIDTH-
                                                    C_PI_RDWDADDR_WIDTH)-1);
  sig_rdfifo_rdwdaddr_reg  <= sig_srl_fifo_rddata((SRL_FIFO_WIDTH-
                                                   C_PI_RDWDADDR_WIDTH) to
                                                   SRL_FIFO_WIDTH-1);
  sig_pop_srl_fifo   <= (Ad2Rd_PLB_NPI_Sync      and
                         sig_get_next_fifo_data  and
                         not(sig_srl_fifo_empty) and
                         Ad2rd_queue_data);


  ------------------------------------------------------------
  -- Instance: I_SRL_FIFO_BUF
  --
  -- Description:
  -- SRL FIFO to rate change the read data betweeen the PLB
  -- and the MPMC time domains
  --
  ------------------------------------------------------------
   I_SRL_FIFO_BUF : entity proc_common_v3_00_a.srl_fifo_f
   generic map (
    C_DWIDTH     =>  SRL_FIFO_WIDTH ,  -- : natural;
    C_DEPTH      =>  SRL_FIFO_DEPTH ,  -- : positive := 16;
    C_FAMILY     =>  C_FAMILY          -- : string := "nofamily"
     )
   port map (
    Clk           =>  PI_Clk                ,  -- : in  std_logic;
    Reset         =>  sig_srl_fifo_rst      ,  -- : in  std_logic;
    FIFO_Write    =>  sig_srl_fifo_write    ,  -- : in  std_logic;
    Data_In       =>  sig_srl_fifo_wrdata   ,  -- : in  std_logic_vector(0 to C_DWIDTH-1);
    FIFO_Read     =>  sig_pop_srl_fifo      ,  -- : in  std_logic;
    Data_Out      =>  sig_srl_fifo_rddata   ,  -- : out std_logic_vector(0 to C_DWIDTH-1);
    FIFO_Empty    =>  sig_srl_fifo_empty    ,  -- : out std_logic;
    FIFO_Full     =>  sig_srl_fifo_full     ,  -- : out std_logic;
    Addr          =>  sig_srl_fifo_addr        -- : out std_logic_vector(0 to log2(C_DEPTH)-1)
     );



end implementation;
