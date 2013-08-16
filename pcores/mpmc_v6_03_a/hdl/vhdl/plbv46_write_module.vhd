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
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "LLink_Clk", "clk_div#", "clk_#x"
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity  plbv46_write_module is
    generic (
        C_SPLB_MID_WIDTH        : integer range 0 to 4      := 3                ;
        C_SPLB_NUM_MASTERS      : integer range 1 to 16     := 8                ;
        C_SPLB_SMALLEST_MASTER  : integer range 32 to 128   := 128              ;
        C_SPLB_AWIDTH           : integer range 32 to 32    := 32               ;
        C_SPLB_DWIDTH           : integer range 32 to 128   := 128              ;
        C_SPLB_NATIVE_DWIDTH    : integer range 32 to 128   := 32               ;
        C_PLBV46_PIM_TYPE       : string                    := "PLB"            ;
        C_MPMC_WR_FIFO_TYPE     : string                    := "BRAM"           ;
        C_SPLB_SUPPORT_BURSTS   : integer range 0 to 1      := 0                ;
        C_MPMC_PIM_DATA_WIDTH   : integer range 32 to 64    := 32
    );
    port (
        SPLB_Clk                : in  std_logic                                 ;
        PI_Clk                  : in  std_logic                                 ;
        Sync_Mpmc_Rst           : in  std_logic                                 ;
        Sync_Plb_Rst            : in  std_logic                                 ;

        -- PLB Write Interface
        PLB_wrDBus              : in  std_logic_vector(0 to C_SPLB_DWIDTH-1)    ;
        PLB_wrBurst             : in  std_logic                                 ;
        Sl_wrDAck               : out std_logic                                 ;
        Sl_wrComp               : out std_logic                                 ;
        Sl_wrBTerm              : out std_logic                                 ;
        Sl_MWrErr               : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
        Sl_MIRQ                 : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

        -- Address Module Interface
        Ad2Wr_PLB_NPI_Sync      : in  std_logic                                 ;
        Ad2Wr_New_Cmd           : in  std_logic                                 ;
        AD2Wr_MID               : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1) ;
        Ad2Wr_Strt_Addr         : in  std_logic_vector(0 to C_SPLB_AWIDTH-1)    ;

        --Transmit Type
        Ad2Wr_Single            : in  std_logic                                 ;
        Ad2Wr_Cacheline_4       : in  std_logic                                 ;
        Ad2Wr_Cacheline_8       : in  std_logic                                 ;
        Ad2Wr_Burst_16          : in  std_logic                                 ;
        Ad2Wr_Burst_32          : in  std_logic                                 ;

        Ad2Wr_Xfer_WrdCnt       : in  std_logic_vector(0 to 7)                  ;
        Ad2Wr_Xfer_Width        : in  std_logic_vector(0 to 1)                  ;
        Ad2Wr_WrBE              : in  std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH/8-1)            ;
        Ad2Wr_clk_ratio_1_1     : in  std_logic;

        Wr2Ad_Wr_Cmplt          : out std_logic                                 ;
        Wr2Ad_Busy              : out std_logic                                 ;
        Wr2Ad_Error             : out std_logic                                 ;
        Wr2Ad_Block_InFIFO      : out std_logic                                 ;

        -- NPI Inteface
        PI2Wr_WrFIFO_AlmostFull : in  std_logic                                 ;
        PI2Wr_WrFIFO_Empty      : in  std_logic                                 ;

        Wr2PI_WrFIFO_Data       : out std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH-1)              ;
        Wr2PI_WrFIFO_BE         : out std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH/8-1)            ;
        Wr2PI_WrFIFO_Push       : out std_logic                                 ;
        Wr2PI_WrFIFO_Flush      : out std_logic
        );
end plbv46_write_module;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of plbv46_write_module is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
constant NUM_BYTE_LANES     : integer := C_MPMC_PIM_DATA_WIDTH/8;
constant SLICE_DATA_WIDTH   : integer := 8;

-------------------------------------------------------------------------------
-- Signal/Type Declarations
-------------------------------------------------------------------------------
signal wr2pi_wrfifo_push_i      : std_logic;
signal wr2pi_wrfifo_push_dly    : std_logic;
signal Ad2Wr_New_Cmd_dly        : std_logic;

signal wr2ad_wrfifo_be_i        : std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH/8-1);
signal wr2pi_wrfifo_be_dly      : std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH/8-1);
signal wr2ad_wr_cmplt_i         : std_logic;
signal sl_wrdack_i              : std_logic;
signal sl_wrcomp_i              : std_logic;
signal sl_wrdack_reg            : std_logic;
signal sl_wrcomp_reg            : std_logic;
signal wrfifo_empty_d1          : std_logic;
signal plb_busy_i               : std_logic;
signal wrfifo_busy              : std_logic;
signal wr2pi_wrfifo_push_d1     : std_logic;
signal write_data               : std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH-1);
signal write_data_reg           : std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH-1);
signal write_be                 : std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH/8-1);
signal wr2pi_wrfifo_push_cmb    : std_logic;
signal wr2pi_wrfifo_be_cmb      : std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH/8-1);
signal wr2pi_wrfifo_push_reg    : std_logic;
signal wr2pi_wrfifo_be_reg      : std_logic_vector
                                    (0 to C_MPMC_PIM_DATA_WIDTH/8-1);

signal strt_addr_s_h            : std_logic_vector(0 to C_SPLB_AWIDTH-1);
signal start_addr               : std_logic_vector(0 to C_SPLB_AWIDTH-1);
signal write_be_reg             : std_logic_vector(0 to C_MPMC_PIM_DATA_WIDTH/8-1);
signal load_data_pipe           : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

-- Tie unused outputs to GND
Sl_MWrErr <= (others => '0');
Sl_MIRQ   <= (others => '0');

-- NPI Error and Flush not used
Wr2Ad_Error         <= '0';
Wr2PI_WrFIFO_Flush  <= '0'; -- Not supported in the MPMC
-------------------------------------------------------------------------------
---------------------------- Singles Only Mode---------------------------------
-------------------------------------------------------------------------------
GEN_FOR_SINGLES_ONLY : if C_SPLB_SUPPORT_BURSTS = 0 and
                          (C_PLBV46_PIM_TYPE = "PLB" or  
                           C_PLBV46_PIM_TYPE = "DPLB")
                       generate

type WRITE_STATE_TYPE    is (IDLE,
                            SNGLE
                           );

signal wr_cs            : WRITE_STATE_TYPE;
signal wr_ns            : WRITE_STATE_TYPE;

signal single_cycle             : std_logic;
signal single_s_h               : std_logic;


begin
-- PLB output
Sl_wrDAck           <= sl_wrdack_reg ;
Sl_wrComp           <= sl_wrcomp_reg;
Sl_wrBTerm          <= '0';
Wr2Ad_Block_InFIFO  <= '0';

    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    S_H_XFER_TYPE : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst = '1')then
                    single_s_h      <= '0';
                    strt_addr_s_h   <= (others => '0');
                elsif(Ad2Wr_New_Cmd='1')then
                    single_s_h      <= Ad2Wr_Single;
                    strt_addr_s_h   <= Ad2Wr_Strt_Addr;
                end if;
            end if;
        end process S_H_XFER_TYPE;

    single_cycle    <= Ad2Wr_Single when Ad2Wr_New_Cmd = '1'
                    else single_s_h;

    start_addr      <= Ad2Wr_Strt_Addr when Ad2Wr_New_Cmd = '1'
                    else strt_addr_s_h;

   GEN_WRFIFO_EMPTY_BRAM : if (C_MPMC_WR_FIFO_TYPE = "BRAM") generate
   begin
       -------------------------------------------------------------------------------
       -- Busy Logic
       -- Drive busy if fifo is not empty and/or not finished with plb command
       -------------------------------------------------------------------------------
        wrfifo_busy <= '0';
   end generate;

   GEN_WRFIFO_EMPTY_NOT_BRAM : if (C_MPMC_WR_FIFO_TYPE /= "BRAM") generate
   begin
       -------------------------------------------------------------------------------
       -- Busy Logic
       -- Drive busy if fifo is not empty and/or not finished with plb command
       -------------------------------------------------------------------------------
       WRFIFO_BUSY_PROCESS : process(PI_Clk)
           begin
               if(PI_Clk'EVENT and PI_Clk='1')then
                   if(Sync_Plb_Rst = '1')then
                       wrfifo_busy <= '0';
                   elsif(wr2pi_wrfifo_push_d1='1')then
                       wrfifo_busy <= '1';
                   elsif(PI2Wr_WrFIFO_Empty='1' and Ad2Wr_PLB_NPI_Sync = '1')then
                       wrfifo_busy <= '0';
                   end if;
               end if;
           end process WRFIFO_BUSY_PROCESS;
   end generate;

    -- Set plb busy if new command and only clear when command is complete
    PLB_BUSY_PROCESS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst = '1' or sl_wrcomp_reg='1')then
                    plb_busy_i <= '0';
                elsif(Ad2Wr_New_Cmd='1')then
                    plb_busy_i <= '1';
                end if;
            end if;
        end process PLB_BUSY_PROCESS;

    -- Set busy to address module if fifo is busy or plb is busy
    Wr2Ad_Busy <= plb_busy_i or wrfifo_busy;

    -------------------------------------------------------------------------------
    -- Write State Machine
    -------------------------------------------------------------------------------
    WRITE_STATE : process(  wr_cs,
                            single_cycle,
                            Ad2Wr_WrBE,
                            Ad2Wr_New_Cmd
                            )
        begin
            wr2pi_wrfifo_push_i <= '0';
            wr2ad_wr_cmplt_i    <= '0';
            wr2ad_wrfifo_be_i   <= (others => '0');
            sl_wrdack_i         <= '0';
            sl_wrcomp_i         <= '0';
            load_data_pipe      <= '0';
            wr_ns               <= wr_cs;


            case wr_cs is
                when IDLE =>
                    if(single_cycle='1' and Ad2Wr_New_Cmd='1')then
                        load_data_pipe      <= '1';
                        wr2pi_wrfifo_push_i <= '1';
                        wr2ad_wrfifo_be_i   <= Ad2Wr_WrBE;
                        wr_ns               <= SNGLE;
                    end if;

                ---------------------------------------
                -- Single Beat Transfer
                ---------------------------------------
                when SNGLE =>
                    wr2ad_wrfifo_be_i   <= Ad2Wr_WrBE;
                    wr2ad_wr_cmplt_i    <= '1';
                    sl_wrdack_i         <= '1';
                    sl_wrcomp_i         <= '1';
                    wr_ns               <= IDLE;


                when others =>
                    wr_ns       <= IDLE;
            end case;
        end process WRITE_STATE;


    -------------------------------------------------------------------------------
    -- Resgister State Machine States/Signals
    -------------------------------------------------------------------------------
    REG_STATES : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr_cs               <= IDLE;
                else
                    wr_cs               <= wr_ns;
                end if;
            end if;
        end process REG_STATES;

    REG_STATE_SIGNALS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    sl_wrdack_reg       <= '0';
                    sl_wrcomp_reg       <= '0';
                    Wr2Ad_Wr_Cmplt      <= '0';
                else
                    sl_wrdack_reg       <= sl_wrdack_i;
                    sl_wrcomp_reg       <= sl_wrcomp_i;
                    Wr2Ad_Wr_Cmplt      <= wr2ad_wr_cmplt_i;
                end if;
            end if;
        end process REG_STATE_SIGNALS;


--    -------------------------------------------------------------------------------
--    -- PLB to NPI Clock Crossing
--    -------------------------------------------------------------------------------
--    PLB2NPI_CROSS : process(Ad2Wr_PLB_NPI_Sync,wr2pi_wrfifo_push_i,write_be)
--        begin
--            if(Ad2Wr_PLB_NPI_Sync='1')then
--                wr2pi_wrfifo_push_cmb   <= wr2pi_wrfifo_push_i;
--                wr2pi_wrfifo_be_cmb     <= write_be;
--
--            else
--                wr2pi_wrfifo_push_cmb   <= '0';
--                wr2pi_wrfifo_be_cmb     <= (others => '0');
--            end if;
--        end process PLB2NPI_CROSS;
--
--    -------------------------------------------------------------------------------
--    -------------------------------------------------------------------------------
----    REG_NPI : process(PI_Clk)
----        begin
----            if(PI_Clk'EVENT and PI_Clk = '1')then
----                if(Sync_Plb_Rst = '1')then
----                    wr2pi_wrfifo_push_d1    <= '0';
----                    Wr2PI_WrFIFO_Push       <= '0';
----                    Wr2PI_WrFIFO_BE         <= (others => '0');
----                else
----                    wr2pi_wrfifo_push_d1    <= wr2pi_wrfifo_push_cmb;
----                    Wr2PI_WrFIFO_Push       <= wr2pi_wrfifo_push_cmb;
----                    Wr2PI_WrFIFO_BE         <= wr2pi_wrfifo_be_cmb;
----                end if;
----            end if;
----        end process REG_NPI;
--

    -------------------------------------------------------------------------------
    -- 64Bit NPI
    -------------------------------------------------------------------------------
    GEN_WRITE_REG_64 : if C_MPMC_PIM_DATA_WIDTH = 64 generate

        -----------------------------------------------------------------------
        -- 128Bit PLB to 64Bit NPI - Master required to do conversion cycles
        -- and put all purtinate information on byte lanes 0 to 7.
        -----------------------------------------------------------------------
        GEN_SPLB_DWIDTH_128 : if C_SPLB_DWIDTH = 128 generate
            write_data_reg    <= PLB_wrDBus(0 to 63);
            write_be_reg      <= wr2ad_wrfifo_be_i(0 to 7);
        end generate GEN_SPLB_DWIDTH_128;

        -----------------------------------------------------------------------
        -- 64Bit PLB to 64Bit NPI - No special requirements
        -----------------------------------------------------------------------
        GEN_SPLB_DWIDTH_64 : if C_SPLB_DWIDTH = 64 generate
            write_data_reg    <= PLB_wrDBus;
            write_be_reg      <= wr2ad_wrfifo_be_i;
        end generate GEN_SPLB_DWIDTH_64;

        -----------------------------------------------------------------------
        -- 32Bit PLB to 64Bit NPI - Based on address, need to steer data and be's
        -- to correct byte lanes.
        -- Address Offsets 0, 8, 10, etc to bytelanes 0 to 3
        -- Address Offsets 4, C, 14, etc to bytelanes 4 to 7
        -----------------------------------------------------------------------
        GEN_SPLB_DWIDTH_32 : if C_SPLB_DWIDTH = 32 generate
        constant ADDR_INDEX : integer := log2(C_MPMC_PIM_DATA_WIDTH/8);

        begin
            REG_WRDATA_WRBE : process(start_addr,PLB_wrDBus,wr2ad_wrfifo_be_i)
                begin
                    if(start_addr(C_SPLB_AWIDTH -  ADDR_INDEX) = '1')then
                        write_data_reg(0 to 31)     <= (others => '0');
                        write_data_reg(32 to 63)    <= PLB_wrDBus(0 to 31);
                        write_be_reg(0 to 3)        <= (others => '0');
                        write_be_reg(4 to 7)        <= wr2ad_wrfifo_be_i(0 to 3);
                    else
                        write_data_reg(0 to 31)     <= PLB_wrDBus(0 to 31);
                        write_data_reg(32 to 63)    <= (others => '0');
                        write_be_reg(0 to 3)        <= wr2ad_wrfifo_be_i(0 to 3);
                        write_be_reg(4 to 7)        <= (others => '0');
                    end if;
                end process REG_WRDATA_WRBE;

        end generate   GEN_SPLB_DWIDTH_32;


    end generate GEN_WRITE_REG_64;

    -------------------------------------------------------------------------------
    -- 32Bit NPI
    -------------------------------------------------------------------------------
    GEN_WRITE_REG_32 : if C_MPMC_PIM_DATA_WIDTH = 32 generate

       write_data_reg     <= PLB_wrDBus(0 to 31);
       write_be_reg       <= wr2ad_wrfifo_be_i(0 to 3);
    end generate GEN_WRITE_REG_32;


    -------------------------------------------------------------------------------
    -- Byte/Half-Word Swap
    -------------------------------------------------------------------------------
    BUILD_WRITE_DATA : for byte_index in 0 to NUM_BYTE_LANES - 1 generate

        write_data(byte_index*SLICE_DATA_WIDTH to
                       byte_index*SLICE_DATA_WIDTH + 7)  <= write_data_reg(((NUM_BYTE_LANES-1)-byte_index)*SLICE_DATA_WIDTH to
                                                                           ((NUM_BYTE_LANES-1)-byte_index)*SLICE_DATA_WIDTH +7);
        write_be(byte_index)                             <= write_be_reg((NUM_BYTE_LANES-1)-byte_index);

    end generate BUILD_WRITE_DATA;

----    Wr2PI_WrFIFO_Data   <= write_data;
--
---------------------------------------------------------------------------------
---- MPMC BRAM WRITE FIFO
---- For a BRAM based write fifo the assumption is that no throttling will occur
---- on the write fifo interface, therefore allowing this simple pipe stage to work
---------------------------------------------------------------------------------
----GEN_REGPIPE_FOR_BRAM_FIFO : if (C_MPMC_WR_FIFO_TYPE = "BRAM") generate
--
--    -------------------------------------------------------------------------------
--    -------------------------------------------------------------------------------
--    -----------------------------------------------------------------------------------------------
--    -- **NOTE*****NOTE*****NOTE****NOTE*****NOTE****NOTE*****NOTE****NOTE*****NOTE****NOTE*****NOTE
--    --FOR SINGLE MODE WANTED TO REMOVE COMB LOGIC AROUND PUSH AND FULL; HENCE COMMENTED OUT
--    ------------------------------------------------------------------------------------------------
--    REG_NPI : process(PI_Clk)
--        begin
--            if(PI_Clk'EVENT and PI_Clk = '1')then
--                if(Sync_Plb_Rst = '1')then
--                    wr2pi_wrfifo_push_reg   <= '0';
--                    wr2pi_wrfifo_push_d1    <= '0';
--                    Wr2PI_WrFIFO_Push       <= '0';
--                    Wr2PI_WrFIFO_BE         <= (others => '0');
--                else
--                    wr2pi_wrfifo_push_reg   <= wr2pi_wrfifo_push_cmb;
--                    wr2pi_wrfifo_push_d1    <= wr2pi_wrfifo_push_reg;
--                    Wr2PI_WrFIFO_Push       <= wr2pi_wrfifo_push_reg;
--
--                    wr2pi_wrfifo_be_reg     <= wr2pi_wrfifo_be_cmb;
--                    Wr2PI_WrFIFO_BE         <= wr2pi_wrfifo_be_reg;
--                end if;
--            end if;
--        end process REG_NPI;
--
--    REG_WRITE_DATA : process(PI_Clk)
--        begin
--            if(PI_Clk'EVENT and PI_Clk = '1')then
--                if(Sync_Plb_Rst = '1')then
--                    Wr2PI_WrFIFO_Data <= (others => '0');
--                else
--                    Wr2PI_WrFIFO_Data   <= write_data;
--                end if;
--            end if;
--        end process REG_WRITE_DATA;
--
----end generate GEN_REGPIPE_FOR_BRAM_FIFO;


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--========================================================================
    REG_PUSH : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr2pi_wrfifo_push_dly <= '0';
                    wr2pi_wrfifo_be_dly   <= (others => '0');
                else
                    wr2pi_wrfifo_push_dly <= wr2pi_wrfifo_push_i;
                    wr2pi_wrfifo_be_dly   <= write_be;
                end if;
            end if;
        end process REG_PUSH;


    -------------------------------------------------------------------------------
    -- PLB to NPI Clock Crossing
    -------------------------------------------------------------------------------
    PLB2NPI_CROSS : process(Ad2Wr_PLB_NPI_Sync,
                            wr2pi_wrfifo_push_dly,wr2pi_wrfifo_be_dly)
        begin
            if(Ad2Wr_PLB_NPI_Sync='1')then
                wr2pi_wrfifo_push_cmb   <= wr2pi_wrfifo_push_dly;
            else
                wr2pi_wrfifo_push_cmb   <= '0';
            end if;
        end process PLB2NPI_CROSS;

    REG_NPI : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr2pi_wrfifo_push_reg   <= '0';
                    wr2pi_wrfifo_push_d1    <= '0';
                    Wr2PI_WrFIFO_Push       <= '0';
                else
                    wr2pi_wrfifo_push_reg   <= wr2pi_wrfifo_push_cmb;
                    wr2pi_wrfifo_push_d1    <= wr2pi_wrfifo_push_cmb;
                    Wr2PI_WrFIFO_Push       <= wr2pi_wrfifo_push_cmb;
                end if;
            end if;
        end process REG_NPI;

    REG_WRITE_BE : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    Wr2PI_WrFIFO_BE <= (others => '0');
                elsif wr2pi_wrfifo_push_cmb = '1' then
                    Wr2PI_WrFIFO_BE <= wr2pi_wrfifo_be_dly;
                end if;
            end if;
        end process REG_WRITE_BE;


    REG_WRITE_DATA : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    Wr2PI_WrFIFO_Data <= (others => '0');
                elsif wr2pi_wrfifo_push_cmb = '1' then
                    Wr2PI_WrFIFO_Data   <= write_data;
                end if;
            end if;
        end process REG_WRITE_DATA;
--========================================================================


-----------------------------------------------------------------------------------------------
-- **NOTE*****NOTE*****NOTE****NOTE*****NOTE****NOTE*****NOTE****NOTE*****NOTE****NOTE*****NOTE
--FOR SINGLE MODE WANTED TO REMOVE COMB LOGIC AROUND PUSH AND FULL; HENCE COMMENTED OUT
------------------------------------------------------------------------------------------------
--GENERATES FOR SRL AND BRAM SINCE BRAM REGISTERED WRITE DATA ALREADY.

---------------------------------------------------------------------------------
---- MPMC SRL WRITE FIFO
---- Throttling may occur so cannot register write data.
---------------------------------------------------------------------------------
--GEN_NOREGPIPIE_FOR_SRL_FIFO : if (C_MPMC_WR_FIFO_TYPE /= "BRAM") generate
--
--    -------------------------------------------------------------------------------
--    -------------------------------------------------------------------------------
--    REG_NPI : process(PI_Clk)
--        begin
--            if(PI_Clk'EVENT and PI_Clk = '1')then
--                if(Sync_Plb_Rst = '1' or PI2Wr_WrFIFO_AlmostFull='1')then
--                    wr2pi_wrfifo_push_d1    <= '0';
--                    Wr2PI_WrFIFO_Push       <= '0';
--                    Wr2PI_WrFIFO_BE         <= (others => '0');
--                else
--                    wr2pi_wrfifo_push_d1    <= wr2pi_wrfifo_push_cmb;
--                    Wr2PI_WrFIFO_Push       <= wr2pi_wrfifo_push_cmb;
--                    Wr2PI_WrFIFO_BE         <= wr2pi_wrfifo_be_cmb;
--                end if;
--            end if;
--        end process REG_NPI;
--
--
--    Wr2PI_WrFIFO_Data   <= write_data;
--
--end generate GEN_NOREGPIPIE_FOR_SRL_FIFO;
--

end generate GEN_FOR_SINGLES_ONLY;


-------------------------------------------------------------------------------
----------------------------- FULL BURST SUPPORT MODE -------------------------
-------------------------------------------------------------------------------
GEN_FULL_BURST_SUPPORT : if (C_SPLB_SUPPORT_BURSTS = 1 and 
                             C_PLBV46_PIM_TYPE = "PLB") generate

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

constant PAD_LSB_INDEX      : integer
                                := C_SPLB_AWIDTH - 1
                                - log2(C_MPMC_PIM_DATA_WIDTH/8);
constant PAD_MSB_INDEX      : integer := PAD_LSB_INDEX - 3;
--
--                          PAD_LSB_INDEX   PAD_MSB_INDEX
--   64 bit NPI support           25              28
--   32 bit NPI support           26              29
--

constant TTL_ZERO_COUNT     : std_logic_vector(0 to 7) := (others => '0');
constant BLK_ZERO_COUNT     : std_logic_vector(0 to 5) := (others => '0');

constant ZERO_PAD           : std_logic_vector
                                (PAD_MSB_INDEX to PAD_LSB_INDEX)
                                := (others => '0');
constant ONE_TTL_COUNT      : std_logic_vector(0 to 7)
                                := std_logic_vector(to_unsigned(1,8));
constant TWO_TTL_COUNT      : std_logic_vector(0 to 7)
                                := std_logic_vector(to_unsigned(2,8));
constant THREE_TTL_COUNT    : std_logic_vector(0 to 7)
                                := std_logic_vector(to_unsigned(3,8));

-------------------------------------------------------------------------------
-- Signal/Type Declarations
-------------------------------------------------------------------------------
type WRITE_STATE_TYPE    is (IDLE,
                            SNGLE,
                            UNALIGNED_BRST_STRT,
                            BRST,
                            UNALIGNED_BRST_END,
                            CACHE,
                            STRT_PAD,
                            END_PAD
                           );

signal wr_cs            : WRITE_STATE_TYPE;
signal wr_ns            : WRITE_STATE_TYPE;

signal ttl_word_count           : std_logic_vector(0 to 7);
signal blk_count                : std_logic_vector(0 to 5);
signal pad_count                : std_logic_vector
                                    (PAD_MSB_INDEX to PAD_LSB_INDEX);
signal blk_count_fst            : std_logic_vector(0 to 5);
signal pad_count_fst            : std_logic_vector
                                    (PAD_MSB_INDEX to PAD_LSB_INDEX);
signal fast_decr_pad_count      : std_logic;
signal fast_decr_blk_count      : std_logic;
signal decr_wrd_count           : std_logic;
signal decr_pad_count           : std_logic;
signal decr_blk_count           : std_logic;
signal wr2ad_block_infifo_i     : std_logic;
signal strt_padding             : std_logic;
signal end_padding              : std_logic;
signal addr_misaligned          : std_logic;
signal burst_cycle              : std_logic;
signal single_cycle             : std_logic;
signal cache_cycle              : std_logic;
signal xfer_width               : std_logic_vector(0 to 1);
signal burst_s_h                : std_logic;
signal single_s_h               : std_logic;
signal cache_s_h                : std_logic;
signal xfer_width_s_h           : std_logic_vector(0 to 1);
signal sl_wrbterm_i             : std_logic;
signal sl_wrbterm_reg           : std_logic;
signal new_cmd_d1               : std_logic;
signal new_cmd_d2               : std_logic;
signal fast_new_cmd             : std_logic;
signal word_count               : std_logic_vector(0 to 7);
signal block_count              : std_logic_vector(0 to 5);
signal block_count_fst          : std_logic_vector(0 to 5);
signal pack2words               : std_logic;
signal pack4words               : std_logic;
signal push_enable              : std_logic;
signal xfer_wrdcnt              : std_logic_vector(0 to 7);
signal xfer_wrdcnt_s_h          : std_logic_vector(0 to 7);
signal unaligned_start          : std_logic;
signal unaligned_end            : std_logic;
signal start_be                 : std_logic_vector(0 to C_MPMC_PIM_DATA_WIDTH/8-1);
signal end_be                   : std_logic_vector(0 to C_MPMC_PIM_DATA_WIDTH/8-1);
signal set_lsb_be               : std_logic;
signal rst_blk_count            : std_logic;

signal strt_padding_reg         : std_logic;
signal end_padding_reg          : std_logic;


signal wr2ad_block_infifo_i_dly : std_logic;
signal wait_for_sync            : std_logic;
signal ld_fast_cnt              : std_logic;
signal ld_fast_cnt_dly          : std_logic;

signal unaligned_end_dly        : std_logic;
signal sl_wrdack_reg2           : std_logic;
signal cache_cycle_dly          : std_logic;
signal single_cycle_dly         : std_logic;
signal burst_cycle_dly          : std_logic;
begin
    -- PLB output
    Sl_wrDAck           <= sl_wrdack_reg ;
    Sl_wrComp           <= sl_wrcomp_reg;
    Sl_wrBTerm          <= sl_wrbterm_reg ;


    GEN_WORD_COUNT_32BIT : if C_MPMC_PIM_DATA_WIDTH=32 generate
        word_count      <= Ad2Wr_Xfer_WrdCnt;
        block_count     <= "010000";
        block_count_fst <= "010000";
        pack2words  <= '0';
        pack4words  <= '0';
    end generate GEN_WORD_COUNT_32BIT;

    GEN_WORD_COUNT_64BIT : if C_MPMC_PIM_DATA_WIDTH=64 generate
        block_count     <= "010000";
        block_count_fst <= "010000";

        COUNT_PROCESS : process(xfer_width,xfer_wrdcnt,unaligned_start,unaligned_end)
            begin
                case xfer_width is
                    when "00" =>
                        -- Xfer is unaligned at start and end...therefore add 2 to word cnt
                        if(unaligned_start='1' and unaligned_end='1')then
                            word_count      <= std_logic_vector(unsigned(xfer_wrdcnt) + 2);
                        -- Xfer is unaligned at start or end, but not both...therefore
                        -- add 1 to word count
                        elsif(unaligned_start='1' or unaligned_end='1')then
                            word_count      <= std_logic_vector(unsigned(xfer_wrdcnt) + 1);
                        -- Xfer is aligned start and end therefore do NOT add any
                        -- extra counts.
                        else
                            word_count      <= xfer_wrdcnt;
                        end if;
                    when "01" =>
                        word_count      <= '0' & xfer_wrdcnt(0 to 6);
--mw                    when "10" =>
--mw                        word_count      <= "00" & xfer_wrdcnt(0 to 5);
                    when others =>
                        word_count      <= '0' & xfer_wrdcnt(0 to 6);
                end case;
            end process COUNT_PROCESS;

        pack2words <= '1' when xfer_width = "00"
                 else '0';

        pack4words <= '0';

    end generate GEN_WORD_COUNT_64BIT;

    -- 128Bit PIM - Currently Unused
    GEN_WORD_COUNT_128BIT : if C_MPMC_PIM_DATA_WIDTH=128 generate
        word_count      <= (others => '0');
        block_count     <= (others => '0');
        block_count_fst <= (others => '0');
        pack2words <= '1' when xfer_width = "01"
                 else '0';
        pack4words <= '1' when xfer_width = "00"
                 else '0';
    end generate GEN_WORD_COUNT_128BIT;

    -------------------------------------------------------------------------------
    -- Consolidate fixed burst types into 1 type
    -------------------------------------------------------------------------------
    S_H_XFER_TYPE : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst = '1')then
                    burst_s_h       <= '0';
                    single_s_h      <= '0';
                    cache_s_h       <= '0';
                    xfer_width_s_h  <= (others => '0');
                    xfer_wrdcnt_s_h <= (others => '0');
                    strt_addr_s_h   <= (others => '0');
                elsif(Ad2Wr_New_Cmd='1')then
                    burst_s_h       <= Ad2Wr_Burst_16 or Ad2Wr_Burst_32;
                    single_s_h      <= Ad2Wr_Single;
                    cache_s_h       <= Ad2Wr_Cacheline_4 or Ad2Wr_Cacheline_8;
                    xfer_width_s_h  <= Ad2Wr_Xfer_Width;
                    xfer_wrdcnt_s_h <= Ad2Wr_Xfer_WrdCnt;
                    strt_addr_s_h   <= Ad2Wr_Strt_Addr;
                end if;
            end if;
        end process S_H_XFER_TYPE;


    burst_cycle     <= (Ad2Wr_Burst_16 or Ad2Wr_Burst_32) when Ad2Wr_New_Cmd = '1'
                    else burst_s_h;

    single_cycle    <= Ad2Wr_Single when Ad2Wr_New_Cmd = '1'
                    else single_s_h;

    cache_cycle     <= (Ad2Wr_Cacheline_4 or Ad2Wr_Cacheline_8) when Ad2Wr_New_Cmd = '1'
                    else cache_s_h;

    xfer_width      <= Ad2Wr_Xfer_Width when Ad2Wr_New_Cmd = '1'
                    else xfer_width_s_h;

    xfer_wrdcnt     <= Ad2Wr_Xfer_WrdCnt when Ad2Wr_New_Cmd = '1'
                    else xfer_wrdcnt_s_h;

    start_addr      <= Ad2Wr_Strt_Addr when Ad2Wr_New_Cmd = '1'
                    else strt_addr_s_h;


    -------------------------------------------------------------------------------
    -- Starting address is not a MPMC block boundary
    -------------------------------------------------------------------------------
    addr_misaligned <=  or_reduce(Ad2Wr_Strt_Addr(PAD_MSB_INDEX to PAD_LSB_INDEX));

    GEN_UNALIGNED_32BIT : if C_MPMC_PIM_DATA_WIDTH = 32 generate
        unaligned_start <= '0';
        unaligned_end   <= '0';
        start_be        <= (others => '0');
        end_be          <= (others => '0');
    end generate GEN_UNALIGNED_32BIT;

    GEN_UNALIGNED_64BIT : if C_MPMC_PIM_DATA_WIDTH = 64 generate

        UNALIGNED_STR_END : process(xfer_width,xfer_wrdcnt,start_addr,burst_cycle)
            begin
                case xfer_width is
                    when "00" => -- 32 Bit Master
                        unaligned_start <= burst_cycle and start_addr(PAD_LSB_INDEX+1)  ;
                        unaligned_end   <= burst_cycle
                                      and ((not start_addr(PAD_LSB_INDEX+1) and xfer_wrdcnt(7))
                                        or (start_addr(PAD_LSB_INDEX+1) and not xfer_wrdcnt(7)));
                    when others => -- 64 Bit Master and 128 Bit Master
                        unaligned_start <= '0';
                        unaligned_end   <= '0';
                end case;
            end process UNALIGNED_STR_END;

        start_be        <= "00001111" when unaligned_start='1'
                      else "00000000";
--        end_be          <= "11110000" when unaligned_end='1'
--                      else "00000000";

        --Added for timing path thru end_be
        --Since end BE will not be until end of burst, this particular path can be can be
        --delayed one clock.  Other paths are unchanged.
        PLB_BUSY_PROCESS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst = '1')then
                    unaligned_end_dly <= '0';
                else
                    unaligned_end_dly <= unaligned_end;
                end if;
            end if;
        end process PLB_BUSY_PROCESS;

        end_be          <= "11110000" when unaligned_end_dly='1'
                      else "00000000";

    end generate GEN_UNALIGNED_64BIT;

    -- 128Bit PIM - Currently Unused
    GEN_UNALIGNED_128BIT : if C_MPMC_PIM_DATA_WIDTH = 128 generate
        unaligned_start <= '0';
        unaligned_end   <= '0';
        start_be        <= (others => '0');
        end_be          <= (others => '0');
    end generate GEN_UNALIGNED_128BIT;

   GEN_WRFIFO_EMPTY_BRAM : if (C_MPMC_WR_FIFO_TYPE = "BRAM") generate
   begin
       -------------------------------------------------------------------------------
       -- Busy Logic
       -- Drive busy if fifo is not empty and/or not finished with plb command
       -------------------------------------------------------------------------------
       WRFIFO_BUSY_PROCESS_BRAM : process(PI_Clk)
           begin
               if(PI_Clk'EVENT and PI_Clk='1')then
                   if(Sync_Plb_Rst = '1')then
                       wrfifo_busy <= '0';
                   elsif(wr2pi_wrfifo_push_d1='1')then
                       wrfifo_busy <= '1';
                   elsif(PI2Wr_WrFIFO_Empty='1' and Ad2Wr_PLB_NPI_Sync = '1')then
                       wrfifo_busy <= '0';
                   end if;
               end if;
           end process WRFIFO_BUSY_PROCESS_BRAM;
   end generate;

   GEN_WRFIFO_EMPTY_NOT_BRAM : if (C_MPMC_WR_FIFO_TYPE /= "BRAM") generate
   begin
       -------------------------------------------------------------------------------
       -- Busy Logic
       -- Drive busy if fifo is not empty and/or not finished with plb command
       -------------------------------------------------------------------------------
       WRFIFO_BUSY_PROCESS : process(PI_Clk)
           begin
               if(PI_Clk'EVENT and PI_Clk='1')then
                   if(Sync_Plb_Rst = '1')then
                       wrfifo_busy <= '0';
                   elsif(wr2pi_wrfifo_push_d1='1')then
                       wrfifo_busy <= '1';
                   elsif(PI2Wr_WrFIFO_Empty='1' and Ad2Wr_PLB_NPI_Sync = '1')then
                       wrfifo_busy <= '0';
                   end if;
               end if;
           end process WRFIFO_BUSY_PROCESS;
   end generate;

--    -------------------------------------------------------------------------------
--    -- Busy Logic
--    -- Drive busy if fifo is not empty and/or not finished with plb command
--    -------------------------------------------------------------------------------
--    WRFIFO_BUSY_PROCESS : process(PI_Clk)
--        begin
--            if(PI_Clk'EVENT and PI_Clk='1')then
--                if(Sync_Plb_Rst = '1')then
--                    wrfifo_busy <= '0';
--                elsif(wr2pi_wrfifo_push_d1='1')then
--                    wrfifo_busy <= '1';
--                elsif(PI2Wr_WrFIFO_Empty='1' and Ad2Wr_PLB_NPI_Sync = '1')then
--                    wrfifo_busy <= '0';
--                end if;
--            end if;
--        end process WRFIFO_BUSY_PROCESS;
--


    -- Set plb busy if new command and only clear when command is complete
    PLB_BUSY_PROCESS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst = '1' or sl_wrcomp_reg='1')then
                    plb_busy_i <= '0';
                elsif(Ad2Wr_New_Cmd='1')then
                    plb_busy_i <= '1';
                end if;
            end if;
        end process PLB_BUSY_PROCESS;

    -- Set busy to address module if fifo is busy or plb is busy
    Wr2Ad_Busy <= plb_busy_i or wrfifo_busy;

    -------------------------------------------------------------------------------
    -- New Command Strobe
    -- Generate a new command pulse based off of fast clock domain
    -------------------------------------------------------------------------------
    FAST_NEW_CMD_PROCESS : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(Sync_Plb_Rst = '1')then
                    new_cmd_d1 <= '0';
                else
                    new_cmd_d1 <= Ad2Wr_New_Cmd;
                end if;
            end if;
        end process FAST_NEW_CMD_PROCESS;

    fast_new_cmd <= Ad2Wr_New_Cmd and not new_cmd_d1;

    -------------------------------------------------------------------------------
    -- Total Word Count
    -- This process indicates the total number words to transfer
    -------------------------------------------------------------------------------
    TTL_WORD_CNT_PROCESS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst='1')then
                    ttl_word_count <= (others => '0');
                elsif(Ad2Wr_New_Cmd='1')then
                    ttl_word_count <= word_count;
                elsif(decr_wrd_count = '1' and ttl_word_count/=TTL_ZERO_COUNT)then
                    ttl_word_count <= std_logic_vector(unsigned(ttl_word_count) - 1);
                end if;
            end if;
        end process TTL_WORD_CNT_PROCESS;

    --needed to delay load since delayed plb with reg in BRAM.
    --This will prevent extra write on cacheline transactions since
    --start of counter decrement is delayed by one too
    DELAY_LOAD : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst='1')then
                    Ad2Wr_New_Cmd_dly <= '0';
                else
                    Ad2Wr_New_Cmd_dly <= Ad2Wr_New_Cmd;

                end if;
            end if;
        end process DELAY_LOAD;
    push_enable <= '1' when (pack2words='0' and pack4words='0')
                         or (ttl_word_count(7)='1'        and pack2words='1')
                         or (ttl_word_count(6 to 7)= "11" and pack4words='1')
              else '0';

    -------------------------------------------------------------------------------
    -- Block Word Count
    -- This process keeps track of the word count within a block
    -------------------------------------------------------------------------------
    SLOW_BLOCK_WRD_CNT : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst='1' or rst_blk_count='1')then
                    blk_count <= (others => '0');
                elsif(Ad2Wr_New_Cmd='1' or (wr2ad_block_infifo_i_dly = '1')) then
                    blk_count <= block_count;
                elsif(decr_blk_count = '1' and blk_count/=BLK_ZERO_COUNT)then
                    blk_count <= std_logic_vector(unsigned(blk_count) - 1);
                end if;
            end if;
        end process SLOW_BLOCK_WRD_CNT;

    DELAY_INFIFO_INDICATOR : process(splb_clk)
    begin
         if rising_edge(splb_clk) then
            if(Sync_Plb_Rst='1')then
               wr2ad_block_infifo_i_dly <= '0';
            else
               wr2ad_block_infifo_i_dly <= wr2ad_block_infifo_i and not wr2ad_block_infifo_i_dly;
            end if;
         end if;
    end process;

    FAST_BLOCK_WRD_CNT : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(Sync_Plb_Rst='1')then
                    blk_count_fst <= (others => '0');
                elsif(fast_new_cmd='1' or (wr2ad_block_infifo_i_dly='1' and Ad2Wr_PLB_NPI_Sync='1')) then
                    blk_count_fst <= block_count_fst;
                elsif(fast_decr_blk_count = '1' and blk_count_fst/=BLK_ZERO_COUNT)then
                    blk_count_fst <= std_logic_vector(unsigned(blk_count_fst) - 1);
                end if;
            end if;
        end process FAST_BLOCK_WRD_CNT;

    -------------------------------------------------------------------------------
    -- Pad Word Count Process
    -- This process keeps track of the pad count
    -------------------------------------------------------------------------------
    SLOW_PAD_CNT_PROCESS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst= '1')then
                    pad_count <= (others => '0');
                elsif(Ad2Wr_New_Cmd='1' and addr_misaligned = '1')then
                    pad_count <= Ad2Wr_Strt_Addr(PAD_MSB_INDEX to PAD_LSB_INDEX);
                elsif(decr_pad_count = '1' and pad_count /= ZERO_PAD)then
                    pad_count <= std_logic_vector(unsigned(pad_count) - 1);
                end if;
            end if;
        end process SLOW_PAD_CNT_PROCESS;


    FAST_PAD_CNT_PROCESS : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(Sync_Plb_Rst= '1')then
                    pad_count_fst <= (others => '0');
                elsif(fast_new_cmd='1' and addr_misaligned = '1')then
                    pad_count_fst <= Ad2Wr_Strt_Addr(PAD_MSB_INDEX to PAD_LSB_INDEX);
                elsif(fast_decr_pad_count = '1' and pad_count_fst /= ZERO_PAD)then
                    pad_count_fst <= std_logic_vector(unsigned(pad_count_fst) - 1);
                end if;
            end if;
        end process FAST_PAD_CNT_PROCESS;

    -------------------------------------------------------------------------------
    -- Write State Machine
    -------------------------------------------------------------------------------
    WRITE_STATE : process(  wr_cs,
                            burst_cycle,
                            single_cycle,
                            cache_cycle,
                            addr_misaligned,
                            ttl_word_count,
                            pad_count,
                            blk_count,
                            Ad2Wr_WrBE,
                            Ad2Wr_New_Cmd,
                            sl_wrdack_reg,
                            PI2Wr_WrFIFO_AlmostFull,
                            push_enable,
                            unaligned_start,
--                            unaligned_end,
                            unaligned_end_dly,
                            start_be,
                            end_be,
                            blk_count_fst,
                            Ad2Wr_PLB_NPI_Sync)
        begin
            wr2pi_wrfifo_push_i <= '0';
            decr_wrd_count      <= '0';
            decr_pad_count      <= '0';
            decr_blk_count      <= '0';
            wr2ad_wr_cmplt_i    <= '0';
            wr2ad_block_infifo_i<= '0';
            wr2ad_wrfifo_be_i   <= (others => '0');
            strt_padding        <= '0';
            end_padding         <= '0';
            set_lsb_be          <= '0';
            sl_wrdack_i         <= '0';
            load_data_pipe      <= '0';
            rst_blk_count       <= '0';
            wr_ns               <= wr_cs;


            case wr_cs is
                when IDLE =>
                    if(single_cycle='1' and Ad2Wr_New_Cmd='1')then
                        load_data_pipe      <= '1';
                        wr2pi_wrfifo_push_i <= '1';
                        wr2ad_wrfifo_be_i   <= Ad2Wr_WrBE;
    --                    set_lsb_be          <= '1';
                        wr_ns               <= SNGLE;
                    elsif(burst_cycle = '1' and Ad2Wr_New_Cmd='1')then
                        load_data_pipe      <= '1';
                        -- One or more start padding at PIM DWIDTH
                        if(addr_misaligned='1')then
                            wr_ns <= STRT_PAD;

                        -- Start padding at less than PIM DWIDTH
                        elsif(unaligned_start = '1')then
                            wr_ns <= UNALIGNED_BRST_STRT;

                        -- No Start Padding
                        else
                            wr_ns       <= BRST;
                        end if;
                    elsif(cache_cycle='1' and Ad2Wr_New_Cmd='1')then
                        load_data_pipe  <= '1';
                        wr_ns           <= CACHE;
                    end if;

                ---------------------------------------
                -- Single Beat Transfer
                ---------------------------------------
                when SNGLE =>
                    wr2ad_wrfifo_be_i   <= Ad2Wr_WrBE;
                    wr2ad_wr_cmplt_i    <= '1';
                    sl_wrdack_i         <= '1';
    --                set_lsb_be          <= '1';
                    wr_ns               <= IDLE;

                -- Pack 1 word of zero's to setup for unaligned start
                -- (this case will need to be modify if 128bit PIM)
                when UNALIGNED_BRST_STRT =>
                    wr2ad_wrfifo_be_i   <= start_be;
                    decr_wrd_count      <= '1';
                    set_lsb_be          <= '1';
                    wr_ns               <= BRST;

                ---------------------------------------
                -- Fixed Length Burst
                ---------------------------------------
                when BRST =>
                    wr2ad_wrfifo_be_i   <= (others => '1');
--                    if(ttl_word_count = ONE_TTL_COUNT and unaligned_end = '1')then
                    if(ttl_word_count = ONE_TTL_COUNT and unaligned_end_dly = '1')then
                        wr_ns           <= UNALIGNED_BRST_END;

                    elsif(ttl_word_count /= TTL_ZERO_COUNT)then
                        if(blk_count /= BLK_ZERO_COUNT)then
                            wr2pi_wrfifo_push_i <= not PI2Wr_WrFIFO_AlmostFull and push_enable;
                            decr_blk_count      <= not PI2Wr_WrFIFO_AlmostFull and push_enable;
                            decr_wrd_count      <= not PI2Wr_WrFIFO_AlmostFull;
                            sl_wrdack_i         <= not PI2Wr_WrFIFO_AlmostFull;
                            set_lsb_be          <= not PI2Wr_WrFIFO_AlmostFull and not push_enable;
                        else
                            wr2ad_block_infifo_i <= '1';
                        end if;
                    else
                        if(blk_count /= BLK_ZERO_COUNT)then
                            wr_ns <= END_PAD ;
                        else
                            wr2ad_block_infifo_i <= '1';
                            wr2ad_wr_cmplt_i     <= '1';
                            wr_ns                <= IDLE;
                        end if;
                    end if;

                ---------------------------------------
                -- Need to do a cleanup xfer at end
                -- (this case will need to be modify if 128bit PIM)
                ---------------------------------------
                when UNALIGNED_BRST_END =>
                    wr2ad_wrfifo_be_i   <= end_be;
                    if(ttl_word_count /= TTL_ZERO_COUNT)then
                        wr2pi_wrfifo_push_i <= not PI2Wr_WrFIFO_AlmostFull;
                        decr_blk_count      <= not PI2Wr_WrFIFO_AlmostFull;
                        decr_wrd_count      <= not PI2Wr_WrFIFO_AlmostFull;
                    else
                        wr_ns               <= BRST;
                    end if;

                -- Address start is not on block boundary therefore
                -- pad start by pushing zero's
                when STRT_PAD =>
                    strt_padding <= '1';
                    if(pad_count /= ZERO_PAD)then
                        decr_pad_count      <= not PI2Wr_WrFIFO_AlmostFull;
                        decr_blk_count      <= not PI2Wr_WrFIFO_AlmostFull;
                    else
                        if(unaligned_start = '1')then
                            wr_ns <= UNALIGNED_BRST_STRT;
                        else
                            wr_ns               <= BRST;
                        end if;
                    end if;

                -- Did not end on block boundary therefore
                -- pad end by pushing zero's
                when END_PAD =>
                    end_padding <= '1';
                    -- Write Zero's
                    if(blk_count_fst= BLK_ZERO_COUNT and Ad2Wr_PLB_NPI_Sync='1')then
                        rst_blk_count       <= '1';
                        wr_ns               <= BRST;
                    end if;

                ---------------------------------------
                -- Cacheline Burst
                ---------------------------------------
                when CACHE =>
                    wr2ad_wrfifo_be_i   <= (others => '1');
                    if(ttl_word_count /= TTL_ZERO_COUNT)then

                        wr2pi_wrfifo_push_i <= not PI2Wr_WrFIFO_AlmostFull and push_enable;
                        decr_wrd_count      <= not PI2Wr_WrFIFO_AlmostFull;
                        sl_wrdack_i         <= not PI2Wr_WrFIFO_AlmostFull;
                        set_lsb_be          <= not PI2Wr_WrFIFO_AlmostFull and not push_enable;


                    else
                        wr2ad_block_infifo_i    <= '1';
                        wr2ad_wr_cmplt_i        <= '1';
                        wr_ns                   <= IDLE;
                    end if;

                when others =>
                    wr_ns       <= IDLE;
            end case;
        end process WRITE_STATE;


    -------------------------------------------------------------------------------
    -- Resgister State Machine States/Signals
    -------------------------------------------------------------------------------
    REG_STATES : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr_cs               <= IDLE;
                else
                    wr_cs               <= wr_ns;
                end if;
            end if;
        end process REG_STATES;

    REG_STATE_SIGNALS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    sl_wrdack_reg       <= '0';
                    sl_wrbterm_reg      <= '0';
                    sl_wrcomp_reg       <= '0';

                    Wr2Ad_Wr_Cmplt      <= '0';
                    Wr2Ad_Block_InFIFO  <= '0';
                else
                    sl_wrdack_reg       <= sl_wrdack_i;
                    sl_wrbterm_reg      <= sl_wrbterm_i;
                    sl_wrcomp_reg       <= sl_wrcomp_i;

                    Wr2Ad_Wr_Cmplt      <= wr2ad_wr_cmplt_i;
                    Wr2Ad_Block_InFIFO  <= wr2ad_block_infifo_i and not wr2ad_block_infifo_i_dly;
                end if;
            end if;
        end process REG_STATE_SIGNALS;

        sl_wrbterm_i <= '1' when (sl_wrdack_i = '1' and ttl_word_count=TWO_TTL_COUNT
                                    and burst_cycle='1' and unaligned_end='0')

                             or  (sl_wrdack_i = '1' and ttl_word_count=THREE_TTL_COUNT
                                    and burst_cycle='1' and unaligned_end='1')
                  else '0';


        sl_wrcomp_i <= '1' when (sl_wrdack_i = '1' and ttl_word_count=ONE_TTL_COUNT
                                and burst_cycle='0')

                             or (sl_wrdack_i = '1' and ttl_word_count=ONE_TTL_COUNT
                                and burst_cycle='1' and unaligned_end='0')

                             or (sl_wrdack_i = '1' and ttl_word_count=TWO_TTL_COUNT
                                and burst_cycle='1' and unaligned_end='1')
                  else '0';


    -------------------------------------------------------------------------------
    -- Byte/Half-Word Swap
    -------------------------------------------------------------------------------
    BUILD_WRITE_DATA : for byte_index in 0 to NUM_BYTE_LANES - 1 generate

        write_data(byte_index*SLICE_DATA_WIDTH to
                       byte_index*SLICE_DATA_WIDTH + 7)  <= write_data_reg(((NUM_BYTE_LANES-1)-byte_index)*SLICE_DATA_WIDTH to
                                                                           ((NUM_BYTE_LANES-1)-byte_index)*SLICE_DATA_WIDTH +7);
        write_be(byte_index)                             <= write_be_reg((NUM_BYTE_LANES-1)-byte_index);

    end generate BUILD_WRITE_DATA;

--    Wr2PI_WrFIFO_Data   <= write_data;

-------------------------------------------------------------------------------
-- MPMC BRAM WRITE FIFO
-- For a BRAM based write fifo the assumption is that no throttling will occur
-- on the write fifo interface, therefore allowing this simple pipe stage to work
-------------------------------------------------------------------------------
GEN_REGPIPE_FOR_BRAM_FIFO : if (C_MPMC_WR_FIFO_TYPE = "BRAM") generate

    REG_PUSH : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr2pi_wrfifo_push_dly <= '0';
                    wr2pi_wrfifo_be_dly   <= (others => '0');
                    strt_padding_reg  <= '0';
                    end_padding_reg   <= '0';
                else
                    wr2pi_wrfifo_push_dly <= wr2pi_wrfifo_push_i;
                    wr2pi_wrfifo_be_dly   <= write_be;
                    strt_padding_reg  <= strt_padding;
                    end_padding_reg   <= end_padding;
                end if;
            end if;
        end process REG_PUSH;

    -------------------------------------------------------------------------------
    -- PLB to NPI Clock Crossing
    -------------------------------------------------------------------------------
    PLB2NPI_CROSS : process(Ad2Wr_PLB_NPI_Sync,strt_padding_reg,end_padding_reg,
                            wr2pi_wrfifo_push_dly,write_be,strt_padding,end_padding,
                            PI2Wr_WrFIFO_AlmostFull,wr2pi_wrfifo_push_i,
                            pad_count_fst,blk_count_fst,wr2pi_wrfifo_be_dly)
        begin
            if(Ad2Wr_PLB_NPI_Sync='1' and strt_padding='0' and end_padding='0')then
                wr2pi_wrfifo_push_cmb   <= wr2pi_wrfifo_push_dly;
                wr2pi_wrfifo_be_cmb     <= wr2pi_wrfifo_be_dly;
                fast_decr_pad_count     <= '0';
                fast_decr_blk_count     <= wr2pi_wrfifo_push_dly;
--                fast_decr_blk_count     <= wr2pi_wrfifo_push_i;

            elsif(strt_padding_reg='1' and pad_count_fst /= ZERO_PAD)then
                wr2pi_wrfifo_push_cmb   <= not PI2Wr_WrFIFO_AlmostFull;
                wr2pi_wrfifo_be_cmb     <= (others => '0');
                fast_decr_pad_count     <= not PI2Wr_WrFIFO_AlmostFull;
                fast_decr_blk_count     <= not PI2Wr_WrFIFO_AlmostFull;

            elsif(end_padding_reg='1' and blk_count_fst /= BLK_ZERO_COUNT)then
                wr2pi_wrfifo_push_cmb   <= not PI2Wr_WrFIFO_AlmostFull;
                wr2pi_wrfifo_be_cmb     <= (others => '0');
                fast_decr_pad_count     <= '0';
                fast_decr_blk_count     <= not PI2Wr_WrFIFO_AlmostFull;
            else
                wr2pi_wrfifo_push_cmb   <= '0';
                wr2pi_wrfifo_be_cmb     <= (others => '0');
                fast_decr_pad_count     <= '0';
                fast_decr_blk_count     <= '0';
            end if;
        end process PLB2NPI_CROSS;

--========================================================================
    REG_NPI : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr2pi_wrfifo_push_reg   <= '0';
                    wr2pi_wrfifo_push_d1    <= '0';
                    Wr2PI_WrFIFO_Push       <= '0';
                else
                    wr2pi_wrfifo_push_reg   <= wr2pi_wrfifo_push_cmb;
                    wr2pi_wrfifo_push_d1    <= wr2pi_wrfifo_push_cmb;
                    Wr2PI_WrFIFO_Push       <= wr2pi_wrfifo_push_cmb;
                end if;
            end if;
        end process REG_NPI;


    REG_WRITE_BE : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1') then
                    Wr2PI_WrFIFO_BE <= (others => '0');
                elsif wr2pi_wrfifo_push_cmb = '1' then
                    Wr2PI_WrFIFO_BE <= wr2pi_wrfifo_be_cmb;
                else
                    Wr2PI_WrFIFO_BE <= (others => '0');
                end if;
            end if;
        end process REG_WRITE_BE;


    REG_WRITE_DATA : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    Wr2PI_WrFIFO_Data <= (others => '0');
                elsif wr2pi_wrfifo_push_cmb = '1' then
                    Wr2PI_WrFIFO_Data   <= write_data;
                else
                    Wr2PI_WrFIFO_Data <= (others => '0');
                end if;
            end if;
        end process REG_WRITE_DATA;
--========================================================================

end generate GEN_REGPIPE_FOR_BRAM_FIFO;

-------------------------------------------------------------------------------
-- MPMC SRL WRITE FIFO
-- Throttling may occur so cannot register write data.
-------------------------------------------------------------------------------
GEN_NOREGPIPIE_FOR_SRL_FIFO : if (C_MPMC_WR_FIFO_TYPE /= "BRAM") generate

    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    -- PLB to NPI Clock Crossing
    -------------------------------------------------------------------------------
    PLB2NPI_CROSS : process(Ad2Wr_PLB_NPI_Sync,strt_padding,end_padding,
                            wr2pi_wrfifo_push_i,write_be,
                            PI2Wr_WrFIFO_AlmostFull,
                            pad_count_fst,blk_count_fst)
        begin
            if(Ad2Wr_PLB_NPI_Sync='1' and strt_padding='0' and end_padding='0')then
                wr2pi_wrfifo_push_cmb   <= wr2pi_wrfifo_push_i;
                wr2pi_wrfifo_be_cmb     <= write_be;
                fast_decr_pad_count     <= '0';
                fast_decr_blk_count     <= wr2pi_wrfifo_push_i;

            elsif(strt_padding='1' and pad_count_fst /= ZERO_PAD)then
                wr2pi_wrfifo_push_cmb   <= not PI2Wr_WrFIFO_AlmostFull;
                wr2pi_wrfifo_be_cmb     <= (others => '0');
                fast_decr_pad_count     <= not PI2Wr_WrFIFO_AlmostFull;
                fast_decr_blk_count     <= not PI2Wr_WrFIFO_AlmostFull;

            elsif(end_padding='1' and blk_count_fst /= BLK_ZERO_COUNT)then
                wr2pi_wrfifo_push_cmb   <= not PI2Wr_WrFIFO_AlmostFull;
                wr2pi_wrfifo_be_cmb     <= (others => '0');
                fast_decr_pad_count     <= '0';
                fast_decr_blk_count     <= not PI2Wr_WrFIFO_AlmostFull;
            else
                wr2pi_wrfifo_push_cmb   <= '0';
                wr2pi_wrfifo_be_cmb     <= (others => '0');
                fast_decr_pad_count     <= '0';
                fast_decr_blk_count     <= '0';
            end if;
        end process PLB2NPI_CROSS;

    REG_NPI : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk = '1')then
                if(Sync_Plb_Rst = '1' or PI2Wr_WrFIFO_AlmostFull='1')then
                    wr2pi_wrfifo_push_d1    <= '0';
                    Wr2PI_WrFIFO_Push       <= '0';
                    Wr2PI_WrFIFO_BE         <= (others => '0');
                else
                    wr2pi_wrfifo_push_d1    <= wr2pi_wrfifo_push_cmb;
                    Wr2PI_WrFIFO_Push       <= wr2pi_wrfifo_push_cmb;
                    Wr2PI_WrFIFO_BE         <= wr2pi_wrfifo_be_cmb;
                end if;
            end if;
        end process REG_NPI;


    Wr2PI_WrFIFO_Data   <= write_data;

end generate GEN_NOREGPIPIE_FOR_SRL_FIFO;





    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    GEN_WRITE_REG_64 : if C_MPMC_PIM_DATA_WIDTH = 64 generate
    signal lwr_byteln_data  : std_logic_vector(0 to 31);
    signal lwr_byteln_be    : std_logic_vector(0 to 3);
    begin

        REG_LWR_DATA : process(SPLB_Clk)
            begin
                if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                    if(Sync_Plb_Rst = '1')then
                        lwr_byteln_data  <= (others => '0');
                    elsif((load_data_pipe='1' and Ad2Wr_PLB_NPI_Sync='1')
                       or (sl_wrdack_reg='1' and push_enable='1' and Ad2Wr_PLB_NPI_Sync='1'))then
                        lwr_byteln_data  <= PLB_wrDBus(0 to 31);
                    end if;
                end if;
            end process REG_LWR_DATA;

        REG_LWR_BE : process(SPLB_Clk)
            begin
                if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                    if(Sync_Plb_Rst = '1')then
                        lwr_byteln_be    <= (others => '0');
                    elsif(set_lsb_be='1' and Ad2Wr_PLB_NPI_Sync='1')then
                        lwr_byteln_be    <= wr2ad_wrfifo_be_i(0 to 3);
                    end if;
                end if;
            end process REG_LWR_BE;


        -- Pack Write Data
        write_data_reg(0  to 31)    <= lwr_byteln_data when xfer_width = "00"
                                 else PLB_wrDBus(0 to 31);

        GEN_SPLB_DWIDTH_64_128 : if C_SPLB_DWIDTH = 64 or C_SPLB_DWIDTH = 128 generate
            write_data_reg(32 to 63)    <= PLB_wrDBus(32 to 63);
            write_be_reg(4 to 7)        <= wr2ad_wrfifo_be_i(4 to 7);
        end generate GEN_SPLB_DWIDTH_64_128;

        GEN_SPLB_DWIDTH_32 : if C_SPLB_DWIDTH = 32 generate
            write_data_reg(32 to 63)    <= PLB_wrDBus(0 to 31);
            write_be_reg(4 to 7)        <= wr2ad_wrfifo_be_i(0 to 3);
        end generate   GEN_SPLB_DWIDTH_32;


        -- Pack BE's
        write_be_reg(0 to 3)        <= lwr_byteln_be when xfer_width = "00" and single_cycle='0'
                                else  wr2ad_wrfifo_be_i(0 to 3);


    end generate GEN_WRITE_REG_64;

    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    GEN_WRITE_REG_32 : if C_MPMC_PIM_DATA_WIDTH = 32 generate

       write_data_reg     <= PLB_wrDBus(0 to 31);
       write_be_reg       <= wr2ad_wrfifo_be_i(0 to 3);
    end generate GEN_WRITE_REG_32;
end generate GEN_FULL_BURST_SUPPORT;





-------------------------------------------------------------------------------
---------------------------- DPLB BURST SUPPORT MODE -------------------------
-------------------------------------------------------------------------------
GEN_DPLB_BURST_SUPPORT : if (C_SPLB_SUPPORT_BURSTS = 1 and
                             C_PLBV46_PIM_TYPE = "DPLB") generate


-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
constant TTL_ZERO_COUNT     : std_logic_vector(0 to 7) := (others => '0');

constant ONE_TTL_COUNT      : std_logic_vector(0 to 7)
                                := std_logic_vector(to_unsigned(1,8));

-------------------------------------------------------------------------------
-- Signal/Type Declarations
-------------------------------------------------------------------------------
type WRITE_STATE_TYPE    is (IDLE,
                            SNGLE,
                            CACHE
                           );

signal wr_cs            : WRITE_STATE_TYPE;
signal wr_ns            : WRITE_STATE_TYPE;

signal ttl_word_count           : std_logic_vector(0 to 7);
signal decr_wrd_count           : std_logic;
signal wr2ad_block_infifo_i     : std_logic;
signal single_cycle             : std_logic;
signal cache_cycle              : std_logic;
signal xfer_width               : std_logic_vector(0 to 1);
signal single_s_h               : std_logic;
signal cache_s_h                : std_logic;
signal xfer_width_s_h           : std_logic_vector(0 to 1);
signal new_cmd_d1               : std_logic;
signal new_cmd_d2               : std_logic;
signal fast_new_cmd             : std_logic;
signal word_count               : std_logic_vector(0 to 7);
signal pack2words               : std_logic;
signal pack4words               : std_logic;
signal push_enable              : std_logic;
signal xfer_wrdcnt              : std_logic_vector(0 to 7);
signal xfer_wrdcnt_s_h          : std_logic_vector(0 to 7);
-- N/A signal set_lsb_be               : std_logic;
signal rst_blk_count            : std_logic;



begin
    -- PLB output
    Sl_wrDAck           <= sl_wrdack_reg ;
    Sl_wrComp           <= sl_wrcomp_reg;
    Sl_wrBTerm          <= '0' ;


-- N/A    GEN_WORD_COUNT_32BIT : if C_MPMC_PIM_DATA_WIDTH=32 generate
-- N/A        word_count      <= Ad2Wr_Xfer_WrdCnt;
-- N/A        pack2words  <= '0';
-- N/A        pack4words  <= '0';
-- N/A    end generate GEN_WORD_COUNT_32BIT;

    GEN_WORD_COUNT_64BIT : if C_MPMC_PIM_DATA_WIDTH=64 generate

       word_count <= '0' & xfer_wrdcnt(0 to 6);
       pack2words <= '0';
       pack4words <= '0';
-- N/A  Word_count will always be above line since only a 64bit master will be supported
-- N/A   This means xfer_width will always be set to "01"
-- N/A        COUNT_PROCESS : process(xfer_width,xfer_wrdcnt)
-- N/A            begin
-- N/A                case xfer_width is
-- N/A                    when "00" =>
-- N/A                        word_count      <= xfer_wrdcnt;
-- N/A                    when "01" =>
-- N/A                        word_count      <= '0' & xfer_wrdcnt(0 to 6);
-- N/A                    when "10" =>
-- N/A                        word_count      <= "00" & xfer_wrdcnt(0 to 5);
-- N/A                    when others =>
-- N/A                        word_count      <= '0' & xfer_wrdcnt(0 to 6);
-- N/A                end case;
-- N/A            end process COUNT_PROCESS;

-- N/A  Only support 64 bit masters
-- N/A    This means xfer_width will always be set to "01"
-- N/A        pack2words <= '1' when xfer_width = "00"
-- N/A                  else '0';
-- N/A        pack4words <= '0';

    end generate GEN_WORD_COUNT_64BIT;

-- N/A    -- 128Bit PIM - Currently Unused
-- N/A    GEN_WORD_COUNT_128BIT : if C_MPMC_PIM_DATA_WIDTH=128 generate
-- N/A        word_count      <= (others => '0');
-- N/A        pack2words <= '1' when xfer_width = "01"
-- N/A                 else '0';
-- N/A        pack4words <= '1' when xfer_width = "00"
-- N/A                 else '0';
-- N/A    end generate GEN_WORD_COUNT_128BIT;

    -------------------------------------------------------------------------------
    -- Consolidate fixed burst types into 1 type
    -------------------------------------------------------------------------------
    S_H_XFER_TYPE : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst = '1')then
                    single_s_h      <= '0';
                    cache_s_h       <= '0';
                    xfer_width_s_h  <= (others => '0');
                    xfer_wrdcnt_s_h <= (others => '0');
                elsif(Ad2Wr_New_Cmd='1')then
                    single_s_h      <= Ad2Wr_Single;
                    cache_s_h       <= Ad2Wr_Cacheline_4 or Ad2Wr_Cacheline_8;
                    xfer_width_s_h  <= Ad2Wr_Xfer_Width;
                    xfer_wrdcnt_s_h <= Ad2Wr_Xfer_WrdCnt;
                end if;
            end if;
        end process S_H_XFER_TYPE;


    single_cycle    <= Ad2Wr_Single when Ad2Wr_New_Cmd = '1'
                    else single_s_h;

    cache_cycle     <= (Ad2Wr_Cacheline_4 or Ad2Wr_Cacheline_8) when Ad2Wr_New_Cmd = '1'
                    else cache_s_h;

    xfer_width      <= Ad2Wr_Xfer_Width when Ad2Wr_New_Cmd = '1'
                    else xfer_width_s_h;

    xfer_wrdcnt     <= Ad2Wr_Xfer_WrdCnt when Ad2Wr_New_Cmd = '1'
                    else xfer_wrdcnt_s_h;


   GEN_WRFIFO_EMPTY_BRAM : if (C_MPMC_WR_FIFO_TYPE = "BRAM") generate
   begin
       -------------------------------------------------------------------------------
       -- Busy Logic
       -- Drive busy if fifo is not empty and/or not finished with plb command
       -------------------------------------------------------------------------------
       WRFIFO_BUSY_PROCESS_BRAM : process(PI_Clk)
           begin
               if(PI_Clk'EVENT and PI_Clk='1')then
                   if(Sync_Plb_Rst = '1')then
                       wrfifo_busy <= '0';
                   elsif(wr2pi_wrfifo_push_d1='1')then
                       wrfifo_busy <= '1';
                   elsif(PI2Wr_WrFIFO_Empty='1' and Ad2Wr_PLB_NPI_Sync = '1')then
                       wrfifo_busy <= '0';
                   end if;
               end if;
           end process WRFIFO_BUSY_PROCESS_BRAM;

   end generate;

   GEN_WRFIFO_EMPTY_NOT_BRAM : if (C_MPMC_WR_FIFO_TYPE /= "BRAM") generate
   begin
       -------------------------------------------------------------------------------
       -- Busy Logic
       -- Drive busy if fifo is not empty and/or not finished with plb command
       -------------------------------------------------------------------------------
       WRFIFO_BUSY_PROCESS : process(PI_Clk)
           begin
               if(PI_Clk'EVENT and PI_Clk='1')then
                   if(Sync_Plb_Rst = '1')then
                       wrfifo_busy <= '0';
                   elsif(wr2pi_wrfifo_push_d1='1')then
                       wrfifo_busy <= '1';
                   elsif(PI2Wr_WrFIFO_Empty='1' and Ad2Wr_PLB_NPI_Sync = '1')then
                       wrfifo_busy <= '0';
                   end if;
               end if;
           end process WRFIFO_BUSY_PROCESS;
   end generate;


--    -------------------------------------------------------------------------------
--    -- Busy Logic
--    -- Drive busy if fifo is not empty and/or not finished with plb command
--    -------------------------------------------------------------------------------
--    WRFIFO_BUSY_PROCESS : process(PI_Clk)
--        begin
--            if(PI_Clk'EVENT and PI_Clk='1')then
--                if(Sync_Plb_Rst = '1')then
--                    wrfifo_busy <= '0';
--                elsif(wr2pi_wrfifo_push_d1='1')then
--                    wrfifo_busy <= '1';
--                elsif(PI2Wr_WrFIFO_Empty='1' and Ad2Wr_PLB_NPI_Sync = '1')then
--                    wrfifo_busy <= '0';
--                end if;
--            end if;
--        end process WRFIFO_BUSY_PROCESS;
--


    -- Set plb busy if new command and only clear when command is complete
    PLB_BUSY_PROCESS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst = '1' or sl_wrcomp_reg='1')then
                    plb_busy_i <= '0';
                elsif(Ad2Wr_New_Cmd='1')then
                    plb_busy_i <= '1';
                end if;
            end if;
        end process PLB_BUSY_PROCESS;

    -- Set busy to address module if fifo is busy or plb is busy
    Wr2Ad_Busy <= plb_busy_i or wrfifo_busy;

    -------------------------------------------------------------------------------
    -- New Command Strobe
    -- Generate a new command pulse based off of fast clock domain
    -------------------------------------------------------------------------------
    FAST_NEW_CMD_PROCESS : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(Sync_Plb_Rst = '1')then
                    new_cmd_d1 <= '0';
                else
                    new_cmd_d1 <= Ad2Wr_New_Cmd;
                end if;
            end if;
        end process FAST_NEW_CMD_PROCESS;

    fast_new_cmd <= Ad2Wr_New_Cmd and not new_cmd_d1;

    -------------------------------------------------------------------------------
    -- Total Word Count
    -- This process indicates the total number words to transfer
    -------------------------------------------------------------------------------
    TTL_WORD_CNT_PROCESS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk='1')then
                if(Sync_Plb_Rst='1')then
                    ttl_word_count <= (others => '0');
                elsif(Ad2Wr_New_Cmd='1')then
                    ttl_word_count <= word_count;
                elsif(decr_wrd_count = '1' and ttl_word_count/=TTL_ZERO_COUNT)then
                    ttl_word_count <= std_logic_vector(unsigned(ttl_word_count) - 1);
                end if;
            end if;
        end process TTL_WORD_CNT_PROCESS;

-- N/A    push_enable <= '1' when (pack2words='0' and pack4words='0')
-- N/A                         or (ttl_word_count(7)='1'        and pack2words='1')
-- N/A                         or (ttl_word_count(6 to 7)= "11" and pack4words='1')
-- N/A              else '0';
    push_enable <= '1';



    -------------------------------------------------------------------------------
    -- Write State Machine
    -------------------------------------------------------------------------------
    WRITE_STATE : process(  wr_cs,
                            single_cycle,
                            cache_cycle,
                            ttl_word_count,
                            Ad2Wr_WrBE,
                            Ad2Wr_New_Cmd,
                            PI2Wr_WrFIFO_AlmostFull,
                            push_enable)
        begin
            wr2pi_wrfifo_push_i <= '0';
            decr_wrd_count      <= '0';
            wr2ad_wr_cmplt_i    <= '0';
            wr2ad_block_infifo_i<= '0';
            wr2ad_wrfifo_be_i   <= (others => '0');
-- N/A            set_lsb_be          <= '0';
            sl_wrdack_i         <= '0';
-- N/A            load_data_pipe      <= '0';
            wr_ns               <= wr_cs;


            case wr_cs is
                when IDLE =>
                    if(single_cycle='1' and Ad2Wr_New_Cmd='1')then
-- N/A                        load_data_pipe      <= '1';
                        wr2pi_wrfifo_push_i <= '1';
                        wr2ad_wrfifo_be_i   <= Ad2Wr_WrBE;
                        wr_ns               <= SNGLE;

                    elsif(cache_cycle='1' and Ad2Wr_New_Cmd='1')then
-- N/A                        load_data_pipe  <= '1';
                        wr_ns           <= CACHE;
                    end if;

                ---------------------------------------
                -- Single Beat Transfer
                ---------------------------------------
                when SNGLE =>
                    wr2ad_wrfifo_be_i   <= Ad2Wr_WrBE;
                    wr2ad_wr_cmplt_i    <= '1';
                    sl_wrdack_i         <= '1';
                    wr_ns               <= IDLE;


                ---------------------------------------
                -- Cacheline Burst
                ---------------------------------------
                when CACHE =>
                    wr2ad_wrfifo_be_i   <= (others => '1');
                    if(ttl_word_count /= TTL_ZERO_COUNT)then

-- N/A                        wr2pi_wrfifo_push_i <= not PI2Wr_WrFIFO_AlmostFull and push_enable;
                        wr2pi_wrfifo_push_i <= not PI2Wr_WrFIFO_AlmostFull;
                        decr_wrd_count      <= not PI2Wr_WrFIFO_AlmostFull;
                        sl_wrdack_i         <= not PI2Wr_WrFIFO_AlmostFull;
-- N/A                        set_lsb_be          <= not PI2Wr_WrFIFO_AlmostFull and not push_enable;


                    else
                        wr2ad_block_infifo_i    <= '1';
                        wr2ad_wr_cmplt_i        <= '1';
                        wr_ns                   <= IDLE;
                    end if;

                when others =>
                    wr_ns       <= IDLE;
            end case;
        end process WRITE_STATE;

    -------------------------------------------------------------------------------
    -- Resgister State Machine States/Signals
    -------------------------------------------------------------------------------
    REG_STATES : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr_cs               <= IDLE;
                else
                    wr_cs               <= wr_ns;
                end if;
            end if;
        end process REG_STATES;

    REG_STATE_SIGNALS : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    sl_wrdack_reg       <= '0';
                    sl_wrcomp_reg       <= '0';

                    Wr2Ad_Wr_Cmplt      <= '0';
                    Wr2Ad_Block_InFIFO  <= '0';
                else
                    sl_wrdack_reg       <= sl_wrdack_i;
                    sl_wrcomp_reg       <= sl_wrcomp_i;

                    Wr2Ad_Wr_Cmplt      <= wr2ad_wr_cmplt_i;
                    Wr2Ad_Block_InFIFO  <= wr2ad_block_infifo_i;
                end if;
            end if;
        end process REG_STATE_SIGNALS;

        sl_wrcomp_i <= '1' when (sl_wrdack_i = '1' and ttl_word_count=ONE_TTL_COUNT)
                  else '0';


    -------------------------------------------------------------------------------
    -- Byte/Half-Word Swap
    -------------------------------------------------------------------------------
    BUILD_WRITE_DATA : for byte_index in 0 to NUM_BYTE_LANES - 1 generate

        write_data(byte_index*SLICE_DATA_WIDTH to
                       byte_index*SLICE_DATA_WIDTH + 7)  <= write_data_reg(((NUM_BYTE_LANES-1)-byte_index)*SLICE_DATA_WIDTH to
                                                                           ((NUM_BYTE_LANES-1)-byte_index)*SLICE_DATA_WIDTH +7);
        write_be(byte_index)                             <= write_be_reg((NUM_BYTE_LANES-1)-byte_index);

    end generate BUILD_WRITE_DATA;

-------------------------------------------------------------------------------
-- MPMC BRAM WRITE FIFO
-- For a BRAM based write fifo the assumption is that no throttling will occur
-- on the write fifo interface, therefore allowing this simple pipe stage to work
-------------------------------------------------------------------------------
GEN_REGPIPE_FOR_BRAM_FIFO : if (C_MPMC_WR_FIFO_TYPE = "BRAM") generate

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--========================================================================
    REG_PUSH : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr2pi_wrfifo_push_dly <= '0';
                    wr2pi_wrfifo_be_dly   <= (others => '0');
                else
                    wr2pi_wrfifo_push_dly <= wr2pi_wrfifo_push_i;
                    wr2pi_wrfifo_be_dly   <= write_be;
                end if;
            end if;
        end process REG_PUSH;


    -------------------------------------------------------------------------------
    -- PLB to NPI Clock Crossing
    -------------------------------------------------------------------------------
    PLB2NPI_CROSS : process(Ad2Wr_PLB_NPI_Sync,
                            wr2pi_wrfifo_push_dly,wr2pi_wrfifo_be_dly)
        begin
            if(Ad2Wr_PLB_NPI_Sync='1')then
                wr2pi_wrfifo_push_cmb   <= wr2pi_wrfifo_push_dly;
            else
                wr2pi_wrfifo_push_cmb   <= '0';
            end if;
        end process PLB2NPI_CROSS;

    REG_NPI : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    wr2pi_wrfifo_push_reg   <= '0';
                    wr2pi_wrfifo_push_d1    <= '0';
                    Wr2PI_WrFIFO_Push       <= '0';
                else
                    wr2pi_wrfifo_push_reg   <= wr2pi_wrfifo_push_cmb;
                    wr2pi_wrfifo_push_d1    <= wr2pi_wrfifo_push_cmb;
                    Wr2PI_WrFIFO_Push       <= wr2pi_wrfifo_push_cmb;
                end if;
            end if;
        end process REG_NPI;

    REG_WRITE_BE : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    Wr2PI_WrFIFO_BE <= (others => '0');
                elsif wr2pi_wrfifo_push_cmb = '1' then
                    Wr2PI_WrFIFO_BE <= wr2pi_wrfifo_be_dly;
                end if;
            end if;
        end process REG_WRITE_BE;


    REG_WRITE_DATA : process(SPLB_Clk)
        begin
            if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
                if(Sync_Plb_Rst = '1')then
                    Wr2PI_WrFIFO_Data <= (others => '0');
                elsif wr2pi_wrfifo_push_cmb = '1' then
                    Wr2PI_WrFIFO_Data   <= write_data;
                end if;
            end if;
        end process REG_WRITE_DATA;
--========================================================================

end generate GEN_REGPIPE_FOR_BRAM_FIFO;

-------------------------------------------------------------------------------
-- MPMC SRL WRITE FIFO
-- Throttling may occur so cannot register write data.
-------------------------------------------------------------------------------
GEN_NOREGPIPIE_FOR_SRL_FIFO : if (C_MPMC_WR_FIFO_TYPE /= "BRAM")  generate

    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
        -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    -- PLB to NPI Clock Crossing
    -------------------------------------------------------------------------------
    PLB2NPI_CROSS : process(Ad2Wr_PLB_NPI_Sync,wr2pi_wrfifo_push_i,write_be)
        begin
            if(Ad2Wr_PLB_NPI_Sync='1')then
                wr2pi_wrfifo_push_cmb   <= wr2pi_wrfifo_push_i;
                wr2pi_wrfifo_be_cmb     <= write_be;

            else
                wr2pi_wrfifo_push_cmb   <= '0';
                wr2pi_wrfifo_be_cmb     <= (others => '0');
            end if;
        end process PLB2NPI_CROSS;

    REG_NPI : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk = '1')then
                if(Sync_Plb_Rst = '1' or PI2Wr_WrFIFO_AlmostFull='1')then
                    wr2pi_wrfifo_push_d1    <= '0';
                    Wr2PI_WrFIFO_Push       <= '0';
                    Wr2PI_WrFIFO_BE         <= (others => '0');
                else
                    wr2pi_wrfifo_push_d1    <= wr2pi_wrfifo_push_cmb;
                    Wr2PI_WrFIFO_Push       <= wr2pi_wrfifo_push_cmb;
                    Wr2PI_WrFIFO_BE         <= wr2pi_wrfifo_be_cmb;
                end if;
            end if;
        end process REG_NPI;


    Wr2PI_WrFIFO_Data   <= write_data;

end generate GEN_NOREGPIPIE_FOR_SRL_FIFO;

    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    GEN_WRITE_REG_64 : if C_MPMC_PIM_DATA_WIDTH = 64 generate
-- N/A    signal lwr_byteln_data  : std_logic_vector(0 to 31);
-- N/A    signal lwr_byteln_be    : std_logic_vector(0 to 3);
    begin

        write_data_reg(0  to 63)    <= PLB_wrDBus(0 to 63);
        write_be_reg(0 to 7)        <= wr2ad_wrfifo_be_i(0 to 7);

-- N/A        REG_LWR_DATA : process(SPLB_Clk)
-- N/A            begin
-- N/A                if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
-- N/A                    if(Sync_Plb_Rst = '1')then
-- N/A                        lwr_byteln_data  <= (others => '0');
-- N/A                    elsif((load_data_pipe='1' and Ad2Wr_PLB_NPI_Sync='1')
-- N/A                       or (sl_wrdack_reg='1' and push_enable='1' and Ad2Wr_PLB_NPI_Sync='1'))then
-- N/A                        lwr_byteln_data  <= PLB_wrDBus(0 to 31);
-- N/A                    end if;
-- N/A                end if;
-- N/A            end process REG_LWR_DATA;
-- N/A
-- N/A        REG_LWR_BE : process(SPLB_Clk)
-- N/A            begin
-- N/A                if(SPLB_Clk'EVENT and SPLB_Clk = '1')then
-- N/A                    if(Sync_Plb_Rst = '1')then
-- N/A                        lwr_byteln_be    <= (others => '0');
-- N/A                    elsif(set_lsb_be='1' and Ad2Wr_PLB_NPI_Sync='1')then
-- N/A                        lwr_byteln_be    <= wr2ad_wrfifo_be_i(0 to 3);
-- N/A                    end if;
-- N/A                end if;
-- N/A            end process REG_LWR_BE;
-- N/A
-- N/A
-- N/A        -- Pack Write Data
-- N/A        write_data_reg(0  to 31)    <= lwr_byteln_data when xfer_width = "00"
-- N/A                                 else PLB_wrDBus(0 to 31);
-- N/A
-- N/A        GEN_SPLB_DWIDTH_64_128 : if C_SPLB_DWIDTH = 64 or C_SPLB_DWIDTH = 128 generate
-- N/A            write_data_reg(32 to 63)    <= PLB_wrDBus(32 to 63);
-- N/A            write_be_reg(4 to 7)        <= wr2ad_wrfifo_be_i(4 to 7);
-- N/A        end generate GEN_SPLB_DWIDTH_64_128;
-- N/A
-- N/A        GEN_SPLB_DWIDTH_32 : if C_SPLB_DWIDTH = 32 generate
-- N/A            write_data_reg(32 to 63)    <= PLB_wrDBus(0 to 31);
-- N/A            write_be_reg(4 to 7)        <= wr2ad_wrfifo_be_i(0 to 3);
-- N/A        end generate   GEN_SPLB_DWIDTH_32;
-- N/A
-- N/A
-- N/A        -- Pack BE's
-- N/A        write_be_reg(0 to 3)        <= lwr_byteln_be when xfer_width = "00"
-- N/A                                            and single_cycle='0'
-- N/A                                else  wr2ad_wrfifo_be_i(0 to 3);

    end generate GEN_WRITE_REG_64;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
-- N/A    GEN_WRITE_REG_32 : if C_MPMC_PIM_DATA_WIDTH = 32 generate
-- N/A
-- N/A       write_data_reg     <= PLB_wrDBus(0 to 31);
-- N/A       write_be_reg       <= wr2ad_wrfifo_be_i(0 to 3);
-- N/A    end generate GEN_WRITE_REG_32;

end generate GEN_DPLB_BURST_SUPPORT;


-------------------------------------------------------------------------------
------------------------- NO WRITE MODULE SUPPORT  ----------------------------
-------------------------------------------------------------------------------
GEN_NO_WRITEMOD_SUPPORT : if (C_PLBV46_PIM_TYPE = "IPLB") generate
    Sl_wrDAck               <= '0';
    Sl_wrComp               <= '0';
    Sl_wrBTerm              <= '0';
    Wr2Ad_Wr_Cmplt          <= '0';
    Wr2Ad_Busy              <= '0';
    Wr2Ad_Block_InFIFO      <= '0';
    Wr2PI_WrFIFO_Data       <= (others => '0');
    Wr2PI_WrFIFO_BE         <= (others => '0');
    Wr2PI_WrFIFO_Push       <= '0';
end generate GEN_NO_WRITEMOD_SUPPORT;

end implementation;

