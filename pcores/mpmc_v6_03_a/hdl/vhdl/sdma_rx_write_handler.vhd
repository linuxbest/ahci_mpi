---------------------------------------------------------------------------
-- sdma_rx_write_handler
-------------------------------------------------------------------------------
--
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2005, 2006, 2007, 2008 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--
---------------------------------------------------------------------------
-- Filename:          sdma_rx_write_handler.vhd
-- Description:       
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  sdma.vhd
--                      |- sample_cycle.vhd
--                      |- sdma_cntl.vhd
--                      |   |- ipic_if.vhd
--                      |   |   |-sample_cycle.vhd
--                      |   |- interrupt_register.vhd
--                      |   |- dmac_regfile_arb.vhd
--                      |   |- read_data_delay.vhd
--                      |   |- addr_arbiter.vhd
--                      |   |- port_arbiter.vhd
--                      |   |- tx_write_handler.vhd
--                      |   |- tx_read_handler.vhd
--                      |   |- tx_port_controller.vhd
--                      |   |- rx_read_handler.vhd
--                      |   |- rx_write_handler.vhd
--                      |   |- rx_port_controller.vhd
--                      |   |- tx_rx_state.vhd
--                      |
--                      |
--                      |- sdma_datapath.vhd
--                      |   |- reset_module.vhd
--                      |   |- channel_status_reg.vhd
--                      |   |- address_counter.vhd
--                      |   |- length_counter.vhd
--                      |   |- tx_byte_shifter.vhd
--                      |   |- rx_byte_shifter.vhd
--                  sdma_pkg.vhd
--
--
-------------------------------------------------------------------------------
-- Author:      Jeff Hao
-- History:
--  JYH     02/04/05
-- ~~~~~~
--  - Initial EDK Release
-- ^^^^^^
--  GAB     10/02/06
-- ~~~~~~
--  - Converted from verilog to vhdl
--  - Added Tail Pointer Mode
--  - Changed DCR slave interface to PLB v4.6
--  - Modified interrupt coalescing functionality
-- ^^^^^^
--  GAB     9/28/07
-- ~~~~~~
--  - Zero extended various vectors in summation functions to prevent truncation
--  issues.  This fixes CR450181.
-- 
--  MHG     5/20/08
-- ~~~~~~
--  - Updated to proc_common_v3_00_a^^^^^
--^^^^^^^
-------------------------------------------------------------------------------
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
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.ipif_pkg.all;

library unisim;
use unisim.vcomponents.all;

library mpmc_v6_03_a;
use mpmc_v6_03_a.all;
use mpmc_v6_03_a.sdma_pkg.all;

-------------------------------------------------------------------------------
entity sdma_rx_write_handler is
  generic(
    C_TIMEOUT_PERIOD            :     std_logic_vector(3 downto 0) := x"4"
    );
  port(
    -- Global Signals
    LLink_Clk                         : in  std_logic;                     -- I
    LLink_Rst                         : in  std_logic;                     -- I
    -- Port Interface Signals
    wrDataBE_Pos                : out std_logic_vector(3 downto 0);  -- O [3:0]
    wrDataBE_Neg                : out std_logic_vector(3 downto 0);  -- O [3:0]
    wrDataAck_Pos               : out std_logic;                     -- O
    wrDataAck_Neg               : out std_logic;                     -- O  
    wr_push_32bit               : out std_logic;                     -- O  -- added this port to push on every LLink clock pulse
    wrComp                      : out std_logic;                     -- O
    wr_rst                      : out std_logic;                     -- O
    wr_fifo_busy                : in  std_logic;                     -- I
    wr_fifo_almostfull          : in  std_logic;                     -- I
    -- Local Link Signals
    RX_Rem                      : in  std_logic_vector(3 downto 0);  -- I [3:0]
    RX_SOF                      : in  std_logic;                     -- I
    RX_EOF                      : in  std_logic;                     -- I
    RX_SOP                      : in  std_logic;                     -- I
    RX_EOP                      : in  std_logic;                     -- I
    RX_Src_Rdy                  : in  std_logic;                     -- I
    RX_Dst_Rdy                  : out std_logic;                     -- O
    -- Datapath Signals
    SDMA_Sel_Status_Writeback  : out std_logic_vector(1 downto 0);  -- O [1:0]
    -- Counter Signals
    SDMA_RX_Address            : in  std_logic_vector(31 downto 0);                     -- I
    SDMA_RX_Address_Load        : in  std_logic;                     -- I
    SDMA_RX_Length             : in  std_logic_vector(31 downto 0);                     -- I
    SDMA_RX_AddrLen_INC1       : out std_logic;                     -- O
    SDMA_RX_AddrLen_INC2       : out std_logic;                     -- O
    SDMA_RX_AddrLen_INC3       : out std_logic;                     -- O
    SDMA_RX_AddrLen_INC4       : out std_logic;                     -- O
    -- RX Byte Shifter Controls
    SDMA_RX_Shifter_HoldReg_CE : out std_logic;                     -- O
    SDMA_RX_Shifter_Byte_Sel   : out std_logic_vector(1 downto 0);  -- O [1:0]
    SDMA_RX_Shifter_CE         : out std_logic_vector(7 downto 0);  -- O [7:0]
    -- Port Controller Signals
    RX_CL8W_Start               : in  std_logic;                     -- I
    RX_CL8W_Comp                : out std_logic;                     -- O
    RX_B16W_Start               : in  std_logic;                     -- I
    RX_B16W_Comp                : out std_logic;                     -- O
    RX_Busy                     : in  std_logic;                     -- I
    RX_Payload                  : out std_logic;                     -- O
    RX_Footer                   : out std_logic;                     -- O
    RX_RdModWr                  : out std_logic;
    
    -- Channel Reset Signals
    RX_ChannelRST               : in  std_logic;
    RX_WrHandlerForce           : in  std_logic;                     -- I
    RX_ISIDLE_Reset             : out std_logic;
    -- Timeout Signal
    RX_Timeout                  : in  std_logic;                     -- I
    WrPushCount_o			: out std_logic_vector(4 downto 0);
    SDMA_rx_error	: in std_logic;
    -- Rem Limiting Signal
    Rem_Limiting                : out std_logic                      -- O
    );
end sdma_rx_write_handler;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_rx_write_handler is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
constant ALL_ONES       : std_logic_vector(3 downto 0) := (others => '1');                
constant ZERO_LENGTH    : std_logic_vector(6 downto 0) := (others => '0');
constant ZERO_VECTOR    : std_logic_vector(63 downto 0) := (others => '0');
-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal WrPushCount           : std_logic_vector(4 downto 0);
signal Toggle                : std_logic;

signal CL8W_wrDataBE_Pos     : std_logic_vector(3 downto 0);
signal CL8W_wrDataBE_Neg     : std_logic_vector(3 downto 0);
signal CL8W_wrDataAck_Pos    : std_logic;
signal CL8W_wrDataAck_Neg    : std_logic;
signal CL8W_WrPush           : std_logic;
signal CL8W_wrComp           : std_logic;
signal CL8W_Active           : std_logic;
signal CL8W_AppData          : std_logic;
signal RX_Footer_d1          : std_logic;
signal RX_Footer_d2          : std_logic;
signal CL8W_FooterData       : std_logic;
--  signal CL8W_FooterData_d1    : std_logic;
--  signal CL8W_FooterData_d2    : std_logic;
signal CL8W_WrPush_Footer    : std_logic;
signal CL8W_WrPush_Footer_d1 : std_logic;
signal CL8W_WrPush_Footer_d2 : std_logic;
signal CL8W_RX_Dst_Rdy       : std_logic;

signal B16W_wrDataBE_Pos  : std_logic_vector(3 downto 0);
signal B16W_wrDataBE_Neg  : std_logic_vector(3 downto 0);
signal B16W_wrDataAck_Pos : std_logic;
signal B16W_wrDataAck_Neg : std_logic;
signal B16W_Active        : std_logic;
signal B16W_RX_Dst_Rdy    : std_logic;

signal Offset         : std_logic_vector(1 downto 0);
signal BytesHeld      : std_logic_vector(1 downto 0);


signal FirstData      : std_logic;
signal LastData       : std_logic;
signal FillFirstDone  : std_logic;
signal FillFirstDone2 : std_logic;
signal LastBurst      : std_logic;
signal Length0Fill    : std_logic;
signal Length0Start   : std_logic;
signal Length0Middle  : std_logic;
signal Address0Fill   : std_logic;
signal Address0Start  : std_logic;
signal Address0Middle : std_logic;
signal Length0        : std_logic;
signal Address0       : std_logic;
signal LastCount      : std_logic_vector(1 downto 0);

--  signal SDMA_RX_Shifter_CE          : std_logic_vector(7 downto 0);
signal SDMA_RX_Shifter_CE_p1       : std_logic_vector(7 downto 0);
signal B16W_WrPush                  : std_logic;
signal B16W_WrPush_i                : std_logic;
signal B16W_WrPush_p1               : std_logic;
signal B16W_WrPush_p2               : std_logic;
signal B16W_wrComp                  : std_logic;
signal B16W_wrComp_i                : std_logic;
signal B16W_wrComp_p1               : std_logic;
signal B16W_wrComp_p2               : std_logic;
--  signal SDMA_RX_Shifter_Byte_Sel    : std_logic_vector(1 downto 0);
signal SDMA_RX_Shifter_Byte_Sel_p1 : std_logic_vector(1 downto 0);
signal FillFirstDonePush            : std_logic;

signal RX_Between_Frames     : std_logic;
signal RX_Between_Frames_Reg : std_logic;
signal RX_Header             : std_logic;
signal RX_Header_Reg         : std_logic;
signal RX_Payload_Reg        : std_logic;
signal rx_footer_i           : std_logic;

signal wr_fifo_full   : std_logic;
signal Wr_Rst_Pending : std_logic;

signal Advance   : std_logic;
signal Length    : std_logic_vector(1 downto 0);
signal Set_Ptr   : std_logic;
signal Ptr       : std_logic_vector(2 downto 0);
signal Pointer   : std_logic_vector(2 downto 0);
signal CE        : std_logic_vector(3 downto 0);
signal CE_Shift  : std_logic_vector(3 downto 0);
signal CE_Shift2 : std_logic_vector(7 downto 0);

signal Rem_Limiting_Start : std_logic;
signal Rem_Detect         : std_logic;
signal Rem_Detect_Reg     : std_logic;
signal Rem_Decode         : std_logic_vector(1 downto 0);
signal Rem_Decode_Reg     : std_logic_vector(1 downto 0);

signal Timeout_Advance : std_logic;
signal Timeout_Detect  : std_logic;
signal Timeout_Count   : std_logic_vector(3 downto 0);

signal LastCount_Enc  : std_logic_vector(3 downto 0);
signal BytesHeld_Enc  : std_logic_vector(3 downto 0);
signal Length_Enc     : std_logic_vector(3 downto 0);
signal Rem_Enc        : std_logic_vector(3 downto 0);
signal Rem_Decode_Enc : std_logic_vector(3 downto 0);
signal Rem_Start      : std_logic;

type STATES is (IDLE,                 --      = 3'b000,
              HEADER,               --    = 3'b001,
              FILLFIRST,            -- = 3'b010,
              DATA,                 --      = 3'b011,
              FILLLAST);            --  = 3'b100;

signal CS : STATES;

signal rx_cl8w_comp_i           : std_logic;
signal rem_limiting_i           : std_logic;
signal rx_dst_rdy_i             : std_logic;
signal SDMA_rx_shifter_ce_i     : std_logic_vector(7 downto 0);
signal SDMA_rx_shftr_ce_i       : std_logic_vector(7 downto 0);
signal rx_payload_i             : std_logic;
signal rx_b16w_comp_i           : std_logic;

signal alignedstart             : std_logic;
signal even_length              : std_logic;
signal rx_rdmodwr_i             : std_logic;
signal bytesheld_8bits          : std_logic_vector(7 downto 0);
signal wr_rst_i                 : std_logic;
signal wr_rst_d1                : std_logic;
signal wr_rst_strb              : std_logic;
signal AddrPlusBytesHeld        : std_logic_vector(0 to 2);

signal LastBurstLngthCalc       : std_logic_vector(32 downto 0);
signal ZeroExtendAddr           : std_logic_vector(32 downto 0);
signal AddrCalc                 : std_logic_vector(7 downto 0);
signal no_bytes_left		: std_logic;
signal SDMA_RX_Address_Load_d1  : std_logic;
signal remainder		: std_logic_vector(31 downto 0);
signal SDMA_RX_Address_start            :std_logic_vector(31 downto 0);                     -- I
signal SDMA_rx_shifter_ce_i_OR  : std_logic;
signal Last_Wrd_BEnotSet        : std_logic;

begin

RX_CL8W_Comp        <= rx_cl8w_comp_i;
RX_B16W_Comp        <= rx_b16w_comp_i;
RX_Footer           <= rx_footer_i;
RX_Payload          <= rx_payload_i;
Rem_Limiting        <= rem_limiting_i;
RX_Dst_Rdy          <= rx_dst_rdy_i;
SDMA_RX_Shifter_CE <= SDMA_rx_shifter_ce_i;

-- Combine CL8W and B16W Signals
wrDataBE_Pos    <= CL8W_wrDataBE_Pos    
                or (B16W_wrDataBE_Pos and not(CL8W_Active&CL8W_Active&CL8W_Active&CL8W_Active));

wrDataBE_Neg    <= CL8W_wrDataBE_Neg    
                or (B16W_wrDataBE_Neg and not(CL8W_Active&CL8W_Active&CL8W_Active&CL8W_Active));
                
wrDataAck_Pos   <= CL8W_wrDataAck_Pos   or B16W_wrDataAck_Pos;
wrDataAck_Neg   <= CL8W_wrDataAck_Neg   or B16W_wrDataAck_Neg;
wrComp          <= rx_cl8w_comp_i or B16W_wrComp;
WrPushCount_o <= WrPushCount;
wr_push_32bit <= CL8W_WrPush or B16W_WrPush;

-------------------------------------------------------------------------------
-- Holding RX start address to calculate bytes pushed in case of timeout
-------------------------------------------------------------------------------
 -- mgg fix for holding correct number of bytes
 --when Write port needs to be given up
process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1') then
          SDMA_RX_Address_Load_d1 <='0';
        elsif ( SDMA_RX_Address_Load='1') then
        SDMA_RX_Address_Load_d1 <= '1';
        end if;
      end if;
    end process;
    
    process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              SDMA_RX_Address_start <= (others => '0');
            elsif (SDMA_RX_Address_Load_d1='1') then
            SDMA_RX_Address_start <= SDMA_RX_Address;
            end if;
          end if;
    end process;
    
-------------------------------------------------------------------------------
-- in case of timeout calculate bytes pushed
------------------------------------------------------------------------------- 
 -- mgg fix for holding correct number of bytes
 --when Write port needs to be given up
remainder <= std_logic_vector(unsigned(SDMA_RX_Address) - unsigned(SDMA_RX_Address_start));
    no_bytes_left <= '1' when (remainder(2 downto 0) = "000" and Timeout_Detect = '1') else '0';

-------------------------------------------------------------------------------
-- Reset Generation
-------------------------------------------------------------------------------


wr_rst_i <= '1' when (RX_ChannelRST='1' and B16W_WrPush='0' and CL8W_WrPush='0' and WrPushCount="00000")
                  or (RX_WrHandlerForce='1')
       else '0';

WR_RST_REG : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            wr_rst_d1 <= wr_rst_i;
        end if;
    end process WR_RST_REG;

wr_rst_strb <= wr_rst_i and not wr_rst_d1;

RX_ISIDLE_Reset <= wr_rst_strb;

-------------------------------------------------------------------------------
-- Detect Read/Modify Write Condition
-------------------------------------------------------------------------------
alignedstart    <= '1' when B16W_wrDataBE_Pos = ALL_ONES and B16W_wrDataBE_Neg = ALL_ONES
              else '0';

even_length     <= '1' when SDMA_RX_Length(6 downto 0) = ZERO_LENGTH
              else '0';


S_H_AT_START : process(LLink_Clk)
    begin   
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or rx_b16w_comp_i = '1')then
                rx_rdmodwr_i    <= '0';
            elsif(RX_B16W_Start='1')then
                rx_rdmodwr_i    <= not(alignedstart) or not(even_length);
            end if;
        end if;
    end process S_H_AT_START;

RX_RdModWr <= rx_rdmodwr_i;  


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
RX_Dst_Rdy_i <= (CL8W_RX_Dst_Rdy and B16W_RX_Dst_Rdy) or not RX_Busy;
   
    -- CL8W
    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or rx_cl8w_comp_i='1') then
          CL8W_Active <= '0';
        elsif (RX_CL8W_Start='1') then
          CL8W_Active <= '1';
        end if;
      end if;
    end process;

    CL8W_wrDataBE_Pos <= CL8W_FooterData & CL8W_FooterData & CL8W_FooterData & CL8W_FooterData;
    CL8W_wrDataBE_Neg(2 downto 0) <= CL8W_FooterData&CL8W_FooterData&CL8W_FooterData;
    CL8W_wrDataBE_Neg(3) <= '1' when ((((WrPushCount = "00011") and RX_Footer_d2='0') or CL8W_FooterData='1') and CL8W_Active='1') else '0';
    CL8W_wrDataAck_Pos <= CL8W_WrPush and not Toggle;
    CL8W_wrDataAck_Neg <= CL8W_WrPush and Toggle;
    CL8W_WrPush <= (CL8W_Active and not RX_Footer_d2 and not wr_fifo_full) or (CL8W_WrPush_Footer_d2 and not wr_fifo_full);
    rx_cl8w_comp_i <= '1' when ((WrPushCount = "00111") and CL8W_WrPush='1') or (wr_rst_strb='1') else '0';
    
    SDMA_Sel_Status_Writeback <= "11" when (WrPushCount = "00011") and CL8W_Active='1' else "00";

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or rx_cl8w_comp_i='1') then
          CL8W_AppData <= '0';
        elsif ((WrPushCount = "00010") and CL8W_WrPush='1') then
          CL8W_AppData <= '1';
        end if;
      end if;
    end process;

    CL8W_FooterData <= CL8W_AppData and RX_Footer_d2;
    CL8W_WrPush_Footer <= CL8W_Active and rx_footer_i and not RX_Src_Rdy and not CL8W_RX_Dst_Rdy;

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1') then
          RX_Footer_d1 <= '0';
          RX_Footer_d2 <= '0';        
        else
          RX_Footer_d1 <= rx_footer_i;
          RX_Footer_d2 <= RX_Footer_d1;        
        end if;
      end if;
    end process;

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1') then
          CL8W_WrPush_Footer_d1 <= '0';
          CL8W_WrPush_Footer_d2 <= '0';
        elsif ( wr_fifo_full='0') then
          CL8W_WrPush_Footer_d1 <= CL8W_WrPush_Footer;
          CL8W_WrPush_Footer_d2 <= CL8W_WrPush_Footer_d1;
        end if;
      end if;
    end process;
    
    --/********************************************************************/
    
    -- B16W
    B16W_Active <= '1' when (CS /= IDLE) else '0';

    -- Offset
    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or wr_rst_strb='1') then
          Offset <= (others => '0');
        elsif (RX_B16W_Start='1') then
          Offset <= std_logic_vector(unsigned(SDMA_RX_Address(1 downto 0)) + unsigned(BytesHeld));
        end if;
      end if;
    end process;

    -- BytesHeld
    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or wr_rst_strb='1' or rem_limiting_i='1') or 
        (Timeout_Detect='1' and no_bytes_left ='1' and WrPushCount /= "00000") then
        --GAB 3/23/07 had removed timeout detect from equation
        -- 12/12/08 mg added back timout_detect and other qualifiers required for the bytes
        -- held to be reset
          BytesHeld <= (others => '0');
        elsif (LastData='1' and FillFirstDone='1') then
          BytesHeld <= std_logic_vector(unsigned(BytesHeld) - unsigned(LastCount));
        elsif (LastData='1' and FillFirstDone='0') then
          BytesHeld <= std_logic_vector(0-unsigned(LastCount));--??
          
          -- 2's comp of LastCount
--          BytesHeld <= std_logic_vector( signed("11" xor LastCount) + 1);
        end if;
      end if;
    end process;

    -- FillFirstDone - Up front padding is complete
    FillFirstDone <= '1' when FillFirstDone2='1' and (CS = FILLFIRST) and wr_fifo_full='0' else '0';

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or (CS /= FILLFIRST)) then
          if(SDMA_RX_Address(6 downto 2) = "00000") then
            FillFirstDone2 <= '1';
          else
            FillFirstDone2 <= '0';
          end if;
        elsif ((CS = FILLFIRST) and wr_fifo_full='0') then
          if(WrPushCount = std_logic_vector(signed(SDMA_RX_Address(6 downto 2)) - 1)) then
            FillFirstDone2 <= '1';
          else
            FillFirstDone2 <= '0';
          end if;
        end if;
      end if;             
    end process;

    -- 9/28/07 GAB - Added a carryover bit to the addition to fix potential truncation issue
    ZeroExtendAddr <= ZERO_VECTOR(25 downto 0) & SDMA_RX_Address(6 downto 0);
    LastBurstLngthCalc <= std_logic_vector(unsigned(ZeroExtendAddr) + unsigned('0' & SDMA_RX_Length));

   -- LastBurst - Indicates this is the last set of 16 to transfer
    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or wr_rst_strb='1')then
            LastBurst <= '0';
        elsif (RX_B16W_Start='1') then
            if(LastBurstLngthCalc(32) ='0' 
            and to_integer(unsigned(LastBurstLngthCalc(31 downto 0))) <= 128) then
                LastBurst <= '1';
            else
                LastBurst <= '0';
            end if;
        end if;
    end if;
   end process;

   -- FirstData
    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or wr_rst_strb='1') then
          FirstData <= '0';
        elsif (FillFirstDone='1') then
          FirstData <= '1';
        elsif (B16W_RX_Dst_Rdy='0' and RX_Src_Rdy='0') then
          FirstData <= '0';
        end if;
      end if;        
    end process;

   -- LastData
--    LastData <= LastBurst ? Length0  :  Address0;
    LastData <= Length0 when LastBurst = '1'
          else Address0;


--    LastCount <= LastBurst ? SDMA_RX_Length(1 downto 0) : -SDMA_RX_Address(1 downto 0);
    
    -- Number of bytes to transfer at end of transfer
    LastCount <= SDMA_RX_Length(1 downto 0) when LastBurst ='1'
          else  std_logic_vector(0-unsigned(SDMA_RX_Address(1 downto 0)));

    -- Length0 Detect
    Length0 <= '1' when ((CS = DATA) and ((Length0Start='1' and FirstData='1') or (Length0Middle='1' and FirstData='0'))) or (FillFirstDone='1' and Length0Fill='1')
        else '0';

    bytesheld_8bits <= "000000" & BytesHeld;

process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
                Length0Fill     <= '0';
                Length0Start    <= '0';
                Length0Middle   <= '0';
            else
                if(SDMA_RX_Length(7 downto 0) <= bytesheld_8bits) then
                    Length0Fill <= '1';
                else
                    Length0Fill <= '0';
                end if;
          
                if(SDMA_RX_Length(7 downto 0) <= std_logic_vector(unsigned(bytesheld_8bits) + 4)) then
                    Length0Start <= '1';
                else
                    Length0Start <= '0';
                end if;
          
                if (B16W_RX_Dst_Rdy ='0' and RX_Src_Rdy='0') then
                    if(SDMA_RX_Length(7 downto 0) <= "00001000") then
                        Length0Middle <= '1';
                    else
                        Length0Middle <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

   -- Address0 Detect
    Address0 <= '1' when ((CS = DATA) and ((Address0Start='1' and FirstData='1') 
                                        or (Address0Middle='1' and FirstData='0'))) 
                                        or (FillFirstDone='1' and Address0Fill='1') else '0';

    -- 9/28/07 GAB - Added a carryover bit to the addition to fix potential truncation issue
    AddrCalc <= std_logic_vector(unsigned('0' & SDMA_RX_Address(6 downto 0)) + to_integer(unsigned(bytesheld_8bits)));

    process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1')then
                Address0Fill <= '0';
                Address0Start <= '0';
                Address0Middle <= '0';
            else
--                if((to_integer(unsigned(SDMA_RX_Address(6 downto 0))) + to_integer(unsigned(bytesheld_8bits(6 downto 0)))) >= 128) then
                if(to_integer(unsigned(AddrCalc)) >= 128) then
                    Address0Fill <= '1';
                else
                    Address0Fill <= '0';
                end if;

--                if((to_integer(unsigned(SDMA_RX_Address(6 downto 0))) + to_integer(unsigned(bytesheld_8bits(6 downto 0)))) >= 124) then
                if(to_integer(unsigned(AddrCalc)) >= 124) then
                    Address0Start <= '1';
                else
                    Address0Start <= '0';
                end if;

                if (B16W_RX_Dst_Rdy='0' and RX_Src_Rdy='0') then
                    if( to_integer(unsigned(SDMA_RX_Address(6 downto 0))) >= 120) then
                        Address0Middle <='1';
                    else
                        Address0Middle <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
   
   -- Counter Signals
    SDMA_RX_AddrLen_INC4 <= '1' when (Length = "00") and Advance='1' else '0';
    SDMA_RX_AddrLen_INC3 <= '1' when (Length = "11") and Advance='1' else '0';
    SDMA_RX_AddrLen_INC2 <= '1' when (Length = "10") and Advance='1' else '0';
    SDMA_RX_AddrLen_INC1 <= '1' when (Length = "01") and Advance='1' else '0';

   -- Pipeline Signals
    SDMA_rx_shifter_ce_i <= SDMA_rx_shftr_ce_i when wr_fifo_full='0'
                      else (others => '0');
--    SDMA_rx_shifter_ce_i <= SDMA_rx_shftr_ce_i;--gab 3/23/07
                      
    B16W_WrPush <= B16W_WrPush_i and not wr_fifo_full;
    B16W_wrComp <= B16W_wrComp_i and not wr_fifo_full;

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
--        if (LLink_Rst='1') then
        if (LLink_Rst='1' or wr_rst_strb='1'or SDMA_rx_error ='1')then
          SDMA_rx_shftr_ce_i <= (others => '0');
          B16W_WrPush_p1 <= '0';
          B16W_WrPush_i <= '0';
          B16W_wrComp_p1 <= '0';
          B16W_wrComp_i <= '0';
          SDMA_RX_Shifter_Byte_Sel <= (others => '0');
        else
          if (wr_fifo_full='0') then
            SDMA_rx_shftr_ce_i          <= SDMA_RX_Shifter_CE_p1;
            B16W_WrPush_p1              <= B16W_WrPush_p2;
            B16W_WrPush_i               <= B16W_WrPush_p1;
            B16W_wrComp_p1              <= rx_b16w_comp_i;
            B16W_wrComp_i               <= B16W_wrComp_p1;
            SDMA_RX_Shifter_Byte_Sel    <= SDMA_RX_Shifter_Byte_Sel_p1;
          end if;
        end if;
      end if;
    end process;

   -- Byte Shifter Controls
    SDMA_RX_Shifter_HoldReg_CE <= (not B16W_RX_Dst_Rdy and not RX_Src_Rdy) or CL8W_WrPush_Footer;
    SDMA_RX_Shifter_Byte_Sel_p1 <= Offset and B16W_Active&B16W_Active;
    SDMA_RX_Shifter_CE_p1 <= CE_Shift2 when Advance='1'
                        else (others => '0');

   -- CE Controls (advance, length, set_ptr, ptr)   
    Advance <= '1' when (FillFirstDone='1' and (BytesHeld /= "00")) or (B16W_RX_Dst_Rdy='0' and RX_Src_Rdy='0') or CL8W_WrPush_Footer='1' else '0';
    Set_Ptr <= RX_B16W_Start or RX_CL8W_Start;
    Ptr <= SDMA_RX_Address(2 downto 0);

    process(LLink_Clk)
      begin
   if(LLink_Clk'EVENT and LLink_Clk='1')then
      if (LLink_Rst='1' or wr_rst_strb='1') then
        Pointer <= (others => '0');
      elsif (Set_Ptr='1') then
        Pointer <= Ptr;
      elsif (Advance='1') then
        if(Length="00") then
          Pointer <= std_logic_vector(unsigned(Pointer) + unsigned('1' & Length));
        else
          Pointer <= std_logic_vector(unsigned(Pointer) + unsigned('0' & Length));
        end if;
      end if;
   end if;
   end process;

      process(Length)
      begin
        case Length is
          when "00" => CE <= x"F";
          when "01" => CE <= x"8";
          when "10" => CE <= x"C";
          when "11" => CE <= x"E";
          when others => null;
        end case; -- case(Length)
      end process;

      process(Pointer(1 downto 0),CE)
      begin
        case Pointer(1 downto 0) is
          when "00" => CE_Shift <= CE;
          when "01" => CE_Shift <= CE(0)& CE(3 downto 1);
          when "10" => CE_Shift <= CE(1 downto 0)& CE(3 downto 2);
          when "11" => CE_Shift <= CE(2 downto 0)& CE(3);
          when others => null;
        end case; -- case(Pointer(1:0))
      end process;-- always @ (Pointer(1:0) or CE)

    CE_Shift2(7) <= '1' when CE_Shift(3)='1' and ((Pointer(2 downto 0) = "000") or (Pointer(2 downto 0) = "111") or (Pointer(2 downto 0) = "110") or (Pointer(2 downto 0) = "101")) else '0';
    CE_Shift2(6) <= '1' when CE_Shift(2)='1' and ((Pointer(2 downto 0) = "001") or (Pointer(2 downto 0) = "000") or (Pointer(2 downto 0) = "111") or (Pointer(2 downto 0) = "110")) else '0';
    CE_Shift2(5) <= '1' when CE_Shift(1)='1' and ((Pointer(2 downto 0) = "010") or (Pointer(2 downto 0) = "001") or (Pointer(2 downto 0) = "000") or (Pointer(2 downto 0) = "111")) else '0';
    CE_Shift2(4) <= '1' when CE_Shift(0)='1' and ((Pointer(2 downto 0) = "011") or (Pointer(2 downto 0) = "010") or (Pointer(2 downto 0) = "001") or (Pointer(2 downto 0) = "000")) else '0';
    CE_Shift2(3) <= '1' when CE_Shift(3)='1' and ((Pointer(2 downto 0) = "100") or (Pointer(2 downto 0) = "011") or (Pointer(2 downto 0) = "010") or (Pointer(2 downto 0) = "001")) else '0';
    CE_Shift2(2) <= '1' when CE_Shift(2)='1' and ((Pointer(2 downto 0) = "101") or (Pointer(2 downto 0) = "100") or (Pointer(2 downto 0) = "011") or (Pointer(2 downto 0) = "010")) else '0';
    CE_Shift2(1) <= '1' when CE_Shift(1)='1' and ((Pointer(2 downto 0) = "110") or (Pointer(2 downto 0) = "101") or (Pointer(2 downto 0) = "100") or (Pointer(2 downto 0) = "011")) else '0';
    CE_Shift2(0) <= '1' when CE_Shift(0)='1' and ((Pointer(2 downto 0) = "111") or (Pointer(2 downto 0) = "110") or (Pointer(2 downto 0) = "101") or (Pointer(2 downto 0) = "100")) else '0';

      -- Length Logic
      process(LastCount)
      begin
        case LastCount is
          when "00"=> LastCount_Enc <= "1111";
          when "01"=> LastCount_Enc <= "0001";
          when "10"=> LastCount_Enc <= "0011";
          when "11"=> LastCount_Enc <= "0111";
          when others => LastCount_Enc <= "0000";
            
        end case; -- case(LastCount)
      end process;
      
      
      process(BytesHeld)
      begin
        case BytesHeld is
          when "00"=> BytesHeld_Enc <= "1111";
          when "01"=> BytesHeld_Enc <= "0001";
          when "10"=> BytesHeld_Enc <= "0011";
          when "11"=> BytesHeld_Enc <= "0111";
          when others => BytesHeld_Enc <= "0000";
        end case; -- case(BytesHeld)
      end process;

      process(Length_Enc)
      begin
        case (Length_Enc) is
          when "1111"=> Length <= "00";
          when "0001"=> Length <= "01";
          when "0011"=> Length <= "10";
          when "0111"=> Length <= "11";
          when others => Length <= (others => '0');
        end case; -- case(Length_Enc)
      end process;

      process(RX_Rem)
      begin
        case (RX_Rem) is
          when "0000"=> Rem_Enc <= "1111";
          when "0001"=> Rem_Enc <= "0111";
          when "0011"=> Rem_Enc <= "0011";
          when "0111"=> Rem_Enc <= "0001";
          when others => Rem_Enc <= (others => '0');
        end case; -- case(RX_Rem)
      end process;

      process(Rem_Decode_Reg)
      begin
        case Rem_Decode_Reg is
          when "00"=> Rem_Decode_Enc <= "1111";
          when "01"=> Rem_Decode_Enc <= "0001";
          when "10"=> Rem_Decode_Enc <= "0011";
          when "11"=> Rem_Decode_Enc <= "0111";
          when others => Rem_Decode_Enc <= (others => '0');
        end case; -- case(Rem_Decode_Reg)
      end process;
      
      
      
    Length_Enc <= "1111" and not ((LastData&LastData&LastData&LastData) and not LastCount_Enc) 
                         and not ((FillFirstDone&FillFirstDone&FillFirstDone&FillFirstDone) and not BytesHeld_Enc) 
                         and not ((Rem_Detect&Rem_Detect&Rem_Detect&Rem_Detect) and not Rem_Enc) 
                         and not ((Rem_Start&Rem_Start&Rem_Start&Rem_Start) and not Rem_Decode_Enc);


--    Length_Enc <= "1111" when  (LastData='0'        or LastCount_Enc="1111") 
--                           and (FillFirstDone='0'   or BytesHeld_Enc="1111") 
--                           and (Rem_Detect='0'      or Rem_Enc="1111") 
--                           and (Rem_Start='0'       or Rem_Decode_Enc="1111")
--             else "0000";

   -- Handle Rem
    Rem_Detect <= not RX_EOP and not RX_Src_Rdy and not RX_Dst_Rdy_i;
    Rem_Start <= FillFirstDone and Rem_Detect_Reg;
    rem_limiting_i <= '1' when (Rem_Detect='1' and (Rem_Decode = Length)) 
                            or (Rem_Start='1' and (Rem_Decode_Reg = Length))
                 else '0';

   process(RX_Rem) begin
      case (RX_Rem) is
      when "0000"=> Rem_Decode <= "00";
      when "0001"=> Rem_Decode <= "11";
      when "0011"=> Rem_Decode <= "10";
      when "0111"=> Rem_Decode <= "01";
      when others => Rem_Decode <= (others => '0');
      end case; -- case(RX_Rem)
   end process;

      process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1') then
            Rem_Decode_Reg <= (others => '0');
          elsif (Rem_Detect='1') then
            Rem_Decode_Reg <= std_logic_vector(unsigned(Rem_Decode) - unsigned(Length));
          elsif (Rem_Detect_Reg='1' and Advance='1') then
            Rem_Decode_Reg <= std_logic_vector(unsigned(Rem_Decode_Reg) - unsigned(Length));
          end if;
        end if;
      end process;

      process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1') then
            Rem_Detect_Reg <= '0';
          elsif (Rem_Detect='1') then
            Rem_Detect_Reg <= '1';
          elsif (Rem_Decode_Reg = "00") then
            Rem_Detect_Reg <= '0';
          end if;
        end if;
      end process;
   
-- Generate OR of SDMA_rx_shifter_ce_i 
   SDMA_rx_shifter_ce_i_OR <= SDMA_rx_shifter_ce_i(0) or 
                              SDMA_rx_shifter_ce_i(1) or
                              SDMA_rx_shifter_ce_i(2) or
                              SDMA_rx_shifter_ce_i(3) or
                              SDMA_rx_shifter_ce_i(4) or
                              SDMA_rx_shifter_ce_i(5) or
                              SDMA_rx_shifter_ce_i(6) or
                              SDMA_rx_shifter_ce_i(7);

-- Generate flag for throttling on eop 04/21/09 MLL
process(LLink_Clk)
   begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
         if(LLink_Rst='1' or wr_rst_strb='1' or
           (RX_B16W_Start ='1' and BytesHeld = "00") or
           (SDMA_rx_shifter_ce_i_OR = '1' and Last_Wrd_BEnotSet = '1' and BytesHeld = "00")) then
            Last_Wrd_BEnotSet <= '0';
         elsif(RX_EOP = '0' and RX_Src_Rdy = '0' and rx_dst_rdy_i = '0') then
            Last_Wrd_BEnotSet <= '1';
         end if;
      end if;
   end process;

   -- Generate Byte Enables
      process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1' or RX_B16W_Start ='1')then 
            B16W_wrDataBE_Pos(3) <= '0';
          elsif (SDMA_rx_shifter_ce_i(7)='1' and (RX_Footer_d2='0' or
                 (RX_Footer_d2='1' and Last_Wrd_BEnotSet = '1'))) then
            B16W_wrDataBE_Pos(3) <= '1';
          elsif (B16W_wrDataAck_Pos='1') then
            B16W_wrDataBE_Pos(3) <= '0';
          end if;
          
          if (LLink_Rst='1' or wr_rst_strb='1' or RX_B16W_Start ='1')then 
            B16W_wrDataBE_Pos(2) <= '0';
          elsif (SDMA_rx_shifter_ce_i(6)='1' and (RX_Footer_d2='0' or
                 (RX_Footer_d2='1' and Last_Wrd_BEnotSet = '1'))) then
            B16W_wrDataBE_Pos(2) <= '1';
          elsif (B16W_wrDataAck_Pos='1') then
            B16W_wrDataBE_Pos(2) <= '0';
          end if;

          if (LLink_Rst='1' or wr_rst_strb='1' or RX_B16W_Start ='1')then 
            B16W_wrDataBE_Pos(1) <= '0';
          elsif (SDMA_rx_shifter_ce_i(5)='1' and (RX_Footer_d2='0' or
                 (RX_Footer_d2='1' and Last_Wrd_BEnotSet = '1'))) then
            B16W_wrDataBE_Pos(1) <= '1';
          elsif (B16W_wrDataAck_Pos='1') then
            B16W_wrDataBE_Pos(1) <= '0';
          end if;

          if (LLink_Rst='1' or wr_rst_strb='1' or RX_B16W_Start ='1')then 
            B16W_wrDataBE_Pos(0) <= '0';
          elsif (SDMA_rx_shifter_ce_i(4)='1' and (RX_Footer_d2='0' or
                 (RX_Footer_d2='1' and Last_Wrd_BEnotSet = '1'))) then
            B16W_wrDataBE_Pos(0) <= '1';
          elsif (B16W_wrDataAck_Pos='1') then
            B16W_wrDataBE_Pos(0) <= '0';
          end if;

          if (LLink_Rst='1' or wr_rst_strb='1' or RX_B16W_Start ='1')then 
            B16W_wrDataBE_Neg(3) <= '0';
          elsif (SDMA_rx_shifter_ce_i(3)='1' and (RX_Footer_d2='0' or
                 (RX_Footer_d2='1' and Last_Wrd_BEnotSet = '1'))) then
            B16W_wrDataBE_Neg(3) <= '1';
          elsif (B16W_wrDataAck_Neg='1') then
            B16W_wrDataBE_Neg(3) <= '0';
          end if;

          if (LLink_Rst='1' or wr_rst_strb='1' or RX_B16W_Start ='1')then 
            B16W_wrDataBE_Neg(2) <= '0';
          elsif (SDMA_rx_shifter_ce_i(2)='1' and (RX_Footer_d2='0' or
                 (RX_Footer_d2='1' and Last_Wrd_BEnotSet = '1'))) then
            B16W_wrDataBE_Neg(2) <= '1';
          elsif (B16W_wrDataAck_Neg='1') then
            B16W_wrDataBE_Neg(2) <= '0';
          end if;

          if (LLink_Rst='1' or wr_rst_strb='1' or RX_B16W_Start ='1')then 
            B16W_wrDataBE_Neg(1) <= '0';
          elsif (SDMA_rx_shifter_ce_i(1)='1' and (RX_Footer_d2='0' or
                 (RX_Footer_d2='1' and Last_Wrd_BEnotSet = '1'))) then
            B16W_wrDataBE_Neg(1) <= '1';
          elsif (B16W_wrDataAck_Neg='1') then
            B16W_wrDataBE_Neg(1) <= '0';
          end if;

          if (LLink_Rst='1' or wr_rst_strb='1' or RX_B16W_Start ='1')then 
            B16W_wrDataBE_Neg(0) <= '0';
          elsif (SDMA_rx_shifter_ce_i(0)='1' and (RX_Footer_d2='0' or
                 (RX_Footer_d2='1' and Last_Wrd_BEnotSet = '1'))) then
            B16W_wrDataBE_Neg(0) <= '1';
          elsif (B16W_wrDataAck_Neg='1') then
            B16W_wrDataBE_Neg(0) <= '0';
          end if;
        end if;
      end process;
    -- 9/28/07 GAB - Added a carryover bit to the addition to fix truncation issue
    AddrPlusBytesHeld <= std_logic_vector(unsigned('0' & SDMA_RX_Address(1 downto 0)) + unsigned('0' & BytesHeld));

   -- FillFirstDonePush
      process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1')then 
            FillFirstDonePush <= '0';
          elsif (RX_B16W_Start='1') then
            if(to_integer(unsigned(AddrPlusBytesHeld)) > 3) then
              FillFirstDonePush <= '1';
            else
              FillFirstDonePush <= '0';
            end if;
          end if;
        end if;
      end process;
      
    B16W_wrDataAck_Pos <= B16W_WrPush and not Toggle;
    B16W_wrDataAck_Neg <= B16W_WrPush and Toggle;
    B16W_WrPush_p2 <= '1' when (FillFirstDone='1' and FillFirstDonePush='1') 
                            or (B16W_RX_Dst_Rdy='0' and RX_Src_Rdy='0')  
                            or ((CS = FILLFIRST) and FillFirstDone='0' and wr_fifo_full='0') 
                            or ((CS = FILLLAST) and wr_fifo_full='0') else '0';
                           
                           

    rx_b16w_comp_i <= '1' when ((to_integer(unsigned(WrPushCount)) = 31) and B16W_WrPush_p2='1') or (wr_rst_strb='1') else '0';

   -- Write Handler State Machine
      process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1')then 
            CS <= IDLE;
          else
            case (CS) is
              when   IDLE=>
                if (RX_B16W_Start='1' and rx_payload_i='1') then
                  CS <= FILLFIRST;
                elsif (RX_B16W_Start='1' and rx_payload_i='0') then
                  CS <= HEADER;
                else
                  CS <= IDLE;
                end if;
              when   HEADER=>
                if (Timeout_Detect='1' or wr_rst_strb='1') then
                  CS <= FILLLAST;
                elsif (rx_payload_i='1') then
                  CS <= FILLFIRST;
                else
                  CS <= HEADER;
                end if;
              when   FILLFIRST=>
                if (rx_b16w_comp_i='1') then
                  CS <= IDLE;
                elsif (((LastData='1' or rem_limiting_i='1') and wr_fifo_full='0') or Timeout_Detect='1' or wr_rst_strb='1') then
                  CS <= FILLLAST;
                elsif (FillFirstDone='1') then
                  CS <= DATA;
                else
                  CS <= FILLFIRST;
                end if;
              when   DATA=>
                if (rx_b16w_comp_i='1') then
                  CS <= IDLE;
                elsif (((LastData='1' or rem_limiting_i='1') and B16W_RX_Dst_Rdy='0' and RX_Src_Rdy='0') or Timeout_Detect='1' or wr_rst_strb='1') then
                  CS <= FILLLAST;
                else
                  CS <= DATA;
                end if;
              when   FILLLAST=>
                if (rx_b16w_comp_i='1') then
                  CS <= IDLE;
                else
                  CS <= FILLLAST;
                end if;
            end case; -- case(CS)
          end if;
        end if;
      end process;
   
   -- RX LL
    CL8W_RX_Dst_Rdy <= '1' when not (((rx_footer_i='1' and CL8W_Active='1' and  wr_fifo_full='0') or RX_Header='1' or RX_Between_Frames='1') and wr_rst_strb='0') else '0';
    B16W_RX_Dst_Rdy <= '1' when not ((CS = DATA) and rx_payload_i='1' and wr_fifo_full='0')
                    else '0';
    
    
    
    RX_Header <= '1' when (RX_Header_Reg='1' and not (RX_SOP='0' and RX_Src_Rdy='0')) or (RX_SOF='0' and RX_Src_Rdy='0') else '0';
    rx_payload_i <= RX_Payload_Reg or (not RX_SOP and not RX_Src_Rdy);
    RX_Between_Frames <= RX_Between_Frames_Reg and not (not RX_SOF and not RX_Src_Rdy);

      Process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1' or (RX_SOP='0' and RX_Src_Rdy='0')) then
            RX_Header_Reg <= '0';
          elsif (RX_SOF='0' and RX_Src_Rdy='0') then
            RX_Header_Reg <= '1';
          end if;
        end if;
      end process;
      
      Process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1' or (rem_limiting_i='1' and wr_fifo_full='0')) then
            RX_Payload_Reg <= '0';
          elsif (RX_SOP='0' and RX_Src_Rdy='0') then
            RX_Payload_Reg <= '1';
          end if;
        end if;
      end process;

      -- not the actual footer
      Process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1' or ( RX_EOF='0' and RX_Src_Rdy='0')) then
            rx_footer_i <= '0';
          elsif (rem_limiting_i='1' and wr_fifo_full='0') then
            rx_footer_i <= '1';
          end if;
        end if;
      end process;

      Process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1' or (RX_EOF='0' and RX_Src_Rdy='0')) then
            RX_Between_Frames_Reg <= '1';
          elsif (RX_SOF='0' and RX_Src_Rdy='0') then
            RX_Between_Frames_Reg <= '0';
          end if;
        end if;
      end process;
      
      -- Write Push Counter
      Process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1' or rx_cl8w_comp_i='1' or B16W_wrComp='1') then
            WrPushCount <= "00000";
          elsif (CL8W_WrPush='1' or B16W_WrPush_p2='1') then
            WrPushCount <= std_logic_vector(unsigned(WrPushCount) + 1);
          end if;
        end if;
      end process;

      -- Toggle Pushes Between Pos and Neg
      Process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1')then
            Toggle <= '0';
          elsif (CL8W_WrPush='1' or B16W_WrPush='1') then
            Toggle <= not Toggle;
          end if;
        end if;
      end process;

      -- Delay Write Fifo Full Signals
      Process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1') then
            wr_fifo_full <= '0';
          else
            wr_fifo_full <= wr_fifo_almostfull;
          end if;
        end if;
      end process;
      

      wr_rst <= '0';
      
      -- Timeout Counter
      Timeout_Advance <= RX_Timeout and RX_Src_Rdy;
      Timeout_Detect <= '1' when (Timeout_Advance='1' and (Timeout_Count = C_TIMEOUT_PERIOD) and SDMA_RX_Length /="00000000000000000000000000000000") else '0';
      
      Process(LLink_Clk)
      begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
          if (LLink_Rst='1' or wr_rst_strb='1' or Timeout_Detect='1' or Timeout_Advance='0' or (Timeout_Count > C_TIMEOUT_PERIOD)) then
            Timeout_Count <= (others => '0');
          elsif (Timeout_Advance='1') then
            Timeout_Count <= std_logic_vector(unsigned(Timeout_Count) + 1);
          end if;
        end if;
      end process;


end implementation;
