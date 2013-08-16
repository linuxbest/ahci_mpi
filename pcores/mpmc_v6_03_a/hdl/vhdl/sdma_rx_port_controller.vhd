-------------------------------------------------------------------------------
-- rx_port_controller.vhd 
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
-------------------------------------------------------------------------------
-- Filename:        rx_port_controller.vhd
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
-- ^^^^^^
--  GAB     5/12/07
-- ~~~~~~
--  - Issue when next pointer was a null pointer it would also generate a
--  pointer error.  To fix this issue I qualified SDMA_Status_Detect_Nxt_Ptr_Err
--  with not being a null pointer.
-- ^^^^^^
--  GAB     6/18/07
-- ~~~~~~
--  - Qualifed SDMA_Status_Detect_Completed_Err with RX_ChannelRST so that
--  the completed error bit would not get set due to the channel being soft
--  reset after an  error was detected.
-- ^^^^^^
--  GAB     7/2/07
-- ~~~~~~
--  - Registered completed error detection to break logic loop
-- ^^^^^^
--  GAB     8/13/07
-- ~~~~~~
--  - Fixed issue where completed error was getting set incorrectly during
--  a next pointer error detection.
-- 
--  MHG     5/20/08
-- ~~~~~~
--  Updated to proc_common_v3_00_a^^^^^
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
entity sdma_rx_port_controller is
    generic(
        C_COMPLETED_ERR                   : integer                       := 1;
        C_P_BASEADDR                      : std_logic_vector(31 downto 0) := X"FFFFFFFF";
        C_P_HIGHADDR                      : std_logic_vector(31 downto 0) := X"00000000"
    );
    port(
        -- Global Signals
        LLink_Clk                               : in  std_logic;  
        LLink_Rst                               : in  std_logic;  
        -- Port Interface Signals
        AddrReq                           : out std_logic;  
        AddrAck                           : in  std_logic;  
        Addr                              : out std_logic_vector(31 downto 0); 
        RNW                               : out std_logic;  
        Size                              : out std_logic_vector(3 downto 0);  
        RdFIFO_Empty                      : in  std_logic;  
        -- RX State Signals
        CL8R                              : in  std_logic;  
        B16W                              : in  std_logic;  
        CL8W                              : in  std_logic;  
        Channel_Read_Desc_Done            : out std_logic;  
        Channel_Data_Done                 : out std_logic;  
        Channel_Continue                  : out std_logic;  
        Channel_Stop                      : out std_logic;  
        -- Port Arbiter Signals
        Read_Port_Request                 : out std_logic;  
        Read_Port_Grant                   : in  std_logic;  
        Read_Port_Busy                    : out std_logic;  
        Write_Port_Request                : out std_logic;  
        Write_Port_Grant                  : in  std_logic;  
        Write_Port_Busy                   : out std_logic;  
        -- RegFile Arbiter Signals
        RegFile_Request                   : out std_logic;  
        RegFile_Grant                     : in  std_logic;  
        RegFile_Busy                      : out std_logic;             
        -- Data Bus Select Signals
        SDMA_Sel_AddrLen                  : out std_logic_vector(1 downto 0);  
        SDMA_Sel_Data_Src                 : out std_logic_vector(1 downto 0);  
        -- Register File Controls
        SDMA_RegFile_WE                   : out std_logic;  -- O
        SDMA_RegFile_Sel_Eng              : out std_logic;  
        SDMA_RegFile_Sel_Reg              : out std_logic_vector(2 downto 0);  
        -- Counter Signals
        SDMA_RX_Address                   : in  std_logic_vector(31 downto 0); 
        SDMA_RX_Address_Load              : out std_logic;  -- O
        SDMA_RX_Length                    : in  std_logic_vector(31 downto 0); 
        SDMA_RX_Length_Load               : out std_logic; 
        -- Status Register Signals
        SDMA_Status_Detect_Nxt_Ptr_Err    : out std_logic; 
        SDMA_Status_Detect_Addr_Err       : out std_logic; 
        SDMA_Status_Detect_Completed_Err  : out std_logic; 
        SDMA_Status_Set_SDMA_Completed    : out std_logic; 
        SDMA_Status_Detect_Stop           : out std_logic; 
        SDMA_Status_Detect_Null_Ptr       : out std_logic; 
        SDMA_Status_Mem_CE                : out std_logic; 

        -- TailPointer Mode Support
        SDMA_RX_CurDesc_Ptr               : in  std_logic_vector(0 to 31);
        SDMA_RX_TailDesc_Ptr              : in  std_logic_vector(0 to 31);
        TailPntrMode                      : in  std_logic; --GAB 12/22/06 TailPointer Mod

        RX_End                            : out std_logic; 
        RX_StopOnEnd                      : in  std_logic; 
        RX_Completed                      : in  std_logic; 
        -- RX Data Handler Signals
        RX_CL8R_Start                     : out std_logic; 
        RX_CL8R_Comp                      : in  std_logic; 
        RX_RdPop                          : in  std_logic; 
        RX_B16W_Start                     : out std_logic; 
        RX_B16W_Comp                      : in  std_logic; 
        RX_CL8W_Start                     : out std_logic; 
        RX_CL8W_Comp                      : in  std_logic; 
        RX_Footer                         : in  std_logic; 
        -- Address Arbitration
        RX_Addr_Request                   : out std_logic; 
        RX_Addr_Grant                     : in  std_logic; 
        RX_Addr_Busy                      : out std_logic; 
        -- Channel Reset Signals
        RX_ChannelRST                     : in  std_logic;
        RX_ISIDLE_Reset                   : in  std_logic;
--        RX_PortCntrl_RstOut               : out std_logic;
--        RX_RdHandlerRST                   : out std_logic; 
        WrPushCount_o			  : in  std_logic_vector(4 downto 0);
        RX_Src_Rdy		          : in std_logic;
        RX_WrHandlerForce                 : out std_logic
    );
end sdma_RX_Port_Controller;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_rx_port_controller is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant ZERO_DATA : std_logic_vector(31 downto 0) := (others => '0');


-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
-- freddy
-- 1 if enable err; 0 if disable err
-- when reading from a completed descriptor

type R_STATES is (R_IDLE,              --= 4'b0000,  
                  R_REQ_SETUP,--         = 4'b0001,
                  R_SETUP,--             = 4'b0010,
                  R_WAIT_ADDRACK,--      = 4'b0011,
                  R_REQ_READ_DESC,--     = 4'b0100,
                  R_READ_DESC,--         = 4'b0101,
                  R_READ_DESC_SR,--      = 4'b0110,
                  R_READ_DESC_FINISH);-- = 4'b0111;

type W_STATES is (W_IDLE,--              = 4'b0000,
                  W_REQ_SETUP,--         = 4'b0001,
                  W_SETUP    ,--         = 4'b0010,
                  W_WAIT_ADDRACK,--      = 4'b0011,
                  W_RX_ACTIVE,--         = 4'b0100,
                  W_REQ_UPDATE_PNTR,--   = 4'b0101,
                  W_UPDATE_PNTR,--       = 4'b0110,
                  W_UPDATE_PNTR2,--      = 4'b0111,
                  W_REQ_STORE,--         = 4'b1000,
                  W_STORE);--            = 4'b1001;

signal READ_CS  : R_STATES;
signal WRITE_CS : W_STATES;

-- Datapath Control Counter Signals
signal AddrCount                         : std_logic_vector(1 downto 0);
signal AddrCount_TC                      : std_logic;
signal AddrCount_TC2                     : std_logic;
signal Load_Addr_Len                     : std_logic;
signal Load_Addr_Len_d1                  : std_logic;


signal RX_ChannelRST2                    : std_logic;
signal RX_ChannelRST_Busy                : std_logic;
signal RX_ChannelRST_Reg                 : std_logic;

signal RX_Valid_Address                  : std_logic;
signal rx_end_i                          : std_logic;
signal SDMA_status_detect_stop_i        : std_logic;
signal SDMA_status_detect_null_ptr_i    : std_logic;
signal channel_stop_i                    : std_logic;
signal SDMA_rx_length_load_i            : std_logic;
signal rx_curptr_eq_tailptr              : std_logic;

signal sdma_status_detect_completed_err_i   : std_logic;
-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------
begin

RX_End                          <= rx_end_i;
SDMA_Status_Detect_Stop         <= SDMA_status_detect_stop_i;
SDMA_Status_Detect_Null_Ptr     <= SDMA_status_detect_null_ptr_i;
Channel_Stop                    <= channel_stop_i;
SDMA_RX_Length_Load             <= SDMA_rx_length_load_i;


       

-- Port Interface Signals
AddrReq             <= '1' when (((READ_CS = R_WAIT_ADDRACK) 
                             or (WRITE_CS = W_WAIT_ADDRACK))  and RX_Valid_Address ='1') 
                  else '0';
                  
                  

Addr(31 downto 7)   <= SDMA_RX_Address(31 downto 7);

Addr(6 downto 0)    <= SDMA_RX_Address(6 downto 0) when B16W = '0'
                  else "0000000";

RNW                 <= '1' when (READ_CS = R_WAIT_ADDRACK) else '0';
Size                <= '0' & B16W & '1' & '0' when (CL8R = '1' or CL8W = '1') else '0' & B16W & "00";

-- TX State Signals
Channel_Read_Desc_Done  <= RX_CL8R_Comp;
Channel_Data_Done       <= '1' when ((WRITE_CS = W_STORE) and AddrCount_TC='1' and ((SDMA_RX_Length = ZERO_DATA) or RX_Footer='1')) or (RX_ISIDLE_Reset='1') else '0';
Channel_Continue        <= '1' when rx_end_i='1' and not (SDMA_status_detect_stop_i='1' or SDMA_status_detect_null_ptr_i='1') else '0';
channel_stop_i            <= '1' when rx_end_i='1' and (SDMA_status_detect_stop_i='1' or SDMA_status_detect_null_ptr_i='1') else '0';

-- Port Arbiter Signals
Read_Port_Request       <= '1' when (CL8R='1') and (READ_CS = R_IDLE) and RX_ChannelRST='0' else '0';
Read_Port_Busy          <= '1' when (READ_CS /= R_IDLE) else '0';


Write_Port_Request      <= '1' when ((CL8W ='1'  and WRITE_CS = W_IDLE) or 
				(B16W='1' and WRITE_CS = W_IDLE and 
				((WrPushCount_o ="00000" and RX_Src_Rdy = '0') or
				  WrPushCount_o /="00000"))) else '0';
					
				--((SDMA_RX_Length <="00000000000000000000000000000100"
                                  --and RX_Src_Rdy = '0')
		               --or SDMA_RX_Length > "00000000000000000000000000000100")))
                                  --else '0';
					
Write_Port_Busy         <= '1' when (WRITE_CS /= W_IDLE) else '0';

-- RegFile Arbiter Signals


RegFile_Request <= '1' when (READ_CS = R_REQ_SETUP) or (WRITE_CS = W_REQ_SETUP) or 
                        ((READ_CS = R_REQ_READ_DESC) and RdFIFO_Empty='0') or 
                        (WRITE_CS = W_REQ_UPDATE_PNTR) or (WRITE_CS = W_REQ_STORE) else '0';

RegFile_Busy    <= '1' when (READ_CS = R_SETUP) or (READ_CS = R_READ_DESC) or (READ_CS = R_READ_DESC_SR) or 
                        (WRITE_CS = W_SETUP) or (WRITE_CS = W_STORE) or (WRITE_CS = W_UPDATE_PNTR) or 
                        (WRITE_CS = W_UPDATE_PNTR2) else '0';
   
                                        -- Datapath Control Counter
    process(LLink_Clk)
    begin
      if(LLink_Clk'event and LLink_Clk = '1') then
        if (LLink_Rst = '1' or RX_ChannelRST2 = '1' or (READ_CS = R_REQ_READ_DESC) or (WRITE_CS = W_REQ_UPDATE_PNTR)) then
          AddrCount <= "00"; --Next Descriptor Pointer
        elsif (((WRITE_CS = W_REQ_SETUP) and B16W = '1') or (WRITE_CS = W_REQ_STORE)) then
          AddrCount <= "01"; --Current Buffer Address
        elsif ((READ_CS = R_REQ_SETUP) or ((WRITE_CS = W_REQ_SETUP) and CL8W='1') or (WRITE_CS = W_UPDATE_PNTR))  then
          AddrCount <= "11"; --Current Descriptor Pointer
        elsif (((READ_CS = R_READ_DESC) and RX_RdPop='1') or (READ_CS = R_SETUP) or (WRITE_CS = W_SETUP) or (WRITE_CS = W_STORE))  then
          AddrCount <= std_logic_vector(unsigned(AddrCount) + 1);
        end if;
      end if;
    end process;

    AddrCount_TC  <= '1' when (AddrCount = "10") else '0';
    AddrCount_TC2 <= '1' when (AddrCount = "00") else '0';
   
   -- Data Bus Select Signals
    SDMA_Sel_AddrLen <= '1' & not AddrCount(0);
    SDMA_Sel_Data_Src(0) <= '0';
    SDMA_Sel_Data_Src(1) <= '1' when (READ_CS = R_READ_DESC) or (READ_CS = R_READ_DESC_SR) else '0';

   -- Reg File Controls
--    SDMA_RegFile_WE <= '1' when (READ_CS = R_READ_DESC) or (WRITE_CS = W_STORE) or 
--                             ((WRITE_CS = W_UPDATE_PNTR2) and not (RX_Error='1' or channel_stop_i='1')) else '0';

    SDMA_RegFile_WE <= '1' when (READ_CS = R_READ_DESC) or (WRITE_CS = W_STORE) or 
                             ((WRITE_CS = W_UPDATE_PNTR2) and not (channel_stop_i='1' and TailPntrMode='0')) else '0';




--    SDMA_RegFile_Sel_Eng <= "01";
--    SDMA_RegFile_Sel_Reg <= AddrCount;

    SDMA_RegFile_Sel_Eng <= '1';
    SDMA_RegFile_Sel_Reg <= '0' & AddrCount;


   -- Counter Signals
    Load_Addr_Len <= '1' when (READ_CS = R_SETUP) or (WRITE_CS = W_SETUP) or (WRITE_CS = W_UPDATE_PNTR) else '0';

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or RX_ChannelRST2='1') then
          Load_Addr_Len_d1 <= '0';
        else
          Load_Addr_Len_d1 <= Load_Addr_Len;
        end if;
      end if;
    end process;
   
    SDMA_RX_Address_Load <= Load_Addr_Len and not Load_Addr_Len_d1;
    SDMA_rx_length_load_i <= Load_Addr_Len and Load_Addr_Len_d1;

   -- Status Register Signals
    RX_Valid_Address <= '1' when (SDMA_RX_Address >= C_P_BASEADDR) and (SDMA_RX_Address <= C_P_HIGHADDR)
                   else '0';

    
    SDMA_Status_Detect_Nxt_Ptr_Err <= '1' when (WRITE_CS = W_UPDATE_PNTR2)  
                                             and((SDMA_RX_Address(4 downto 0) /= "00000") or RX_Valid_Address='0')
                                             and SDMA_status_detect_null_ptr_i='0'
                                  else '0';
    
    SDMA_Status_Detect_Addr_Err <= B16W and SDMA_rx_length_load_i and not RX_Valid_Address;
    
--GAB 7/2/07 Registered completed error to break logic loop
--    SDMA_Status_Detect_Completed_Err <= '1' when C_COMPLETED_ERR=1 
--                                            and (RX_Completed='1' and RX_CL8R_Comp='1') 
--                                            and LLink_Rst = '0'
--
--                                    else '0';
-- A completed error is generated if the complete bit is set in the fetched descriptor
GEN_CMPLTED_ERROR : if C_COMPLETED_ERR = 1 generate

    sdma_status_detect_completed_err_i <= '1' when (RX_Completed='1' and RX_CL8R_Comp='1') 
                                              and LLink_Rst = '0' and RX_ChannelRST = '0' --8/13 qual w/ chnl rst
                                    else '0';
    
    REG_CMPLT_ERR_PROCESS : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst = '1' or RX_ChannelRST='1')then --8/13 added reset
                    SDMA_Status_Detect_Completed_Err <= '0';
                else
                    SDMA_Status_Detect_Completed_Err <= sdma_status_detect_completed_err_i;
                end if;
            end if;
        end process REG_CMPLT_ERR_PROCESS;
        
end generate GEN_CMPLTED_ERROR;      

GEN_NO_CMPLTED_ERROR : if C_COMPLETED_ERR = 0 generate
    sdma_status_detect_completed_err_i  <= '0';
    SDMA_Status_Detect_Completed_Err    <= '0';
end generate GEN_NO_CMPLTED_ERROR;
    
    SDMA_Status_Set_SDMA_Completed    <= '1' when (WRITE_CS = W_STORE) and AddrCount_TC = '1' and ((SDMA_RX_Length = ZERO_DATA) or RX_Footer='1')
                                      else '0';

    REG_PNTR_COMPARE : process(LLink_clk)
        begin
            if(LLink_clk'EVENT and LLink_clk='1')then
                if(LLink_Rst = '1')then
                    rx_curptr_eq_tailptr <= '0';
                elsif(SDMA_RX_CurDesc_Ptr = SDMA_RX_TailDesc_Ptr)then
                    rx_curptr_eq_tailptr <= '1';
                else
                    rx_curptr_eq_tailptr <= '0';
                end if;
            end if;
        end process REG_PNTR_COMPARE;
--    rx_curptr_eq_tailptr <= '1' when SDMA_RX_CurDesc_Ptr = SDMA_RX_TailDesc_Ptr
--                       else '0';


--GAB 1/19/07                                
--    SDMA_status_detect_stop_i <= '1' when rx_end_i='1' and RX_StopOnEnd='1' else '0';
    SDMA_status_detect_stop_i <= (rx_end_i and RX_StopOnEnd and not(TailPntrMode))
                               or (rx_end_i and rx_curptr_eq_tailptr and TailPntrMode);
    
    SDMA_status_detect_null_ptr_i <= '1' when (WRITE_CS = W_UPDATE_PNTR2) and (SDMA_RX_Address = ZERO_DATA) else '0';
    SDMA_Status_Mem_CE <= '1' when (READ_CS = R_READ_DESC_SR) else '0'; 
    rx_end_i <= '1' when (WRITE_CS = W_UPDATE_PNTR2) else '0';
   
   -- RX Data Handler Signals
    RX_CL8R_Start <= '1' when (READ_CS = R_REQ_READ_DESC) and RegFile_Grant='1' else '0';
   --  RX_B16W_Start = (WRITE_CS = W_SETUP) and AddrCount_TC;
    RX_B16W_Start <= not Load_Addr_Len and Load_Addr_Len_d1 and B16W;
    RX_CL8W_Start <= '1' when (WRITE_CS = W_SETUP) and AddrCount_TC2='1' else '0';

   -- Address Arbitration
    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or RX_Addr_Grant='1' ) then
          RX_Addr_Request <= '0';
        else
          if (((READ_CS = R_SETUP) and AddrCount_TC2='1') or ((WRITE_CS = W_RX_ACTIVE) and (RX_CL8W_Comp='1' or RX_B16W_Comp='1'))) then
            RX_Addr_Request <= '1';
          end if;
        end if;
      end if;
    end process;

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or AddrAck='1') then
          RX_Addr_Busy <= '0';
        else
          if (RX_Addr_Grant='1') then
            RX_Addr_Busy <= '1';
          end if;
        end if;
      end if;
    end process;
    
   -- Channel Reset Signals
    RX_ChannelRST_Busy  <= '1' when (READ_CS = R_WAIT_ADDRACK) or (WRITE_CS = W_WAIT_ADDRACK) or (WRITE_CS = W_RX_ACTIVE) else '0';
    RX_ChannelRST2      <= '1' when (RX_ChannelRST='1' or RX_ChannelRST_Reg='1') and RX_ChannelRST_Busy = '0' else '0';
--    RX_RdHandlerRST     <= '1' when (RX_ChannelRST='1' or RX_ChannelRST_Reg='1') and RX_ChannelRST_Busy = '0' and (READ_CS /= R_IDLE) else '0';
--    RX_WrHandlerForce   <= '1' when (RX_ChannelRST_Reg='1' and RX_ChannelRST_Busy='1' and (WRITE_CS /= W_IDLE)) or (RX_Error ='1') else '0';
    RX_WrHandlerForce   <= '1' when RX_ChannelRST_Reg='1' and RX_ChannelRST_Busy='1' and (WRITE_CS /= W_IDLE) else '0';
    
--    RX_PortCntrl_RstOut <= RX_ChannelRST2;

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or RX_ChannelRST2='1') then
          RX_ChannelRST_Reg <= '0';
        else
          if (RX_ChannelRST='1' or RX_ISIDLE_Reset='1') then
            RX_ChannelRST_Reg <= '1';
          end if;
        end if;
      end if;
    end process;

    -- Read Port Controller State Machine
    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
--        if (LLink_Rst='1' or RX_ChannelRST2='1') then
        if (LLink_Rst='1' or RX_ChannelRST='1') then
          READ_CS <= R_IDLE;
        else
          case (READ_CS) is
            when R_IDLE =>  
              if (Read_Port_Grant='1') then 
                READ_CS <= R_REQ_SETUP;
              else 
                READ_CS <= R_IDLE;
              end if;
            
            when R_REQ_SETUP =>  
              if (RegFile_Grant='1') then 
                READ_CS <= R_SETUP;
              else 
                READ_CS <= R_REQ_SETUP; 
              end if;
              
            when R_SETUP =>  
              if (AddrCount_TC2='1') then 
                READ_CS <= R_WAIT_ADDRACK;
              else 
                READ_CS <= R_SETUP; 
              end if;
                
            when R_WAIT_ADDRACK =>  
              if (AddrAck='1') then 
                READ_CS <= R_REQ_READ_DESC;
              else 
                READ_CS <= R_WAIT_ADDRACK; 
              end if;
            
            when R_REQ_READ_DESC =>  
              if (RegFile_Grant='1') then 
                READ_CS <= R_READ_DESC;
              else 
                READ_CS <= R_REQ_READ_DESC; 
              end if;
              
            when R_READ_DESC =>  
              if (AddrCount_TC='1' and RX_RdPop='1') then 
                READ_CS <= R_READ_DESC_SR;
              else 
                READ_CS <= R_READ_DESC; 
              end if;
            
            when R_READ_DESC_SR => 
              if (RX_RdPop='1') then 
                READ_CS <= R_READ_DESC_FINISH;
              else 
                READ_CS <= R_READ_DESC_SR; 
              end if;
              
            when R_READ_DESC_FINISH =>  
              if (RX_CL8R_Comp='1') then 
                READ_CS <= R_IDLE;
              else 
                READ_CS <= R_READ_DESC_FINISH; 
              end if;
            when others =>
                READ_CS <= R_IDLE;

          end case; -- case(READ_CS)
        end if;
      end if;
    end process;

-- Write Port Controller State Machine
WRITE_PORT_SM : process(LLink_Clk)
begin
    if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or RX_ChannelRST2='1' or RX_ISIDLE_Reset='1') then
            WRITE_CS <= W_IDLE;
        else 
            case (WRITE_CS) is
                when W_IDLE =>  
                    if (Write_Port_Grant='1') then  
                        WRITE_CS <= W_REQ_SETUP;
                    else 
                        WRITE_CS <= W_IDLE; 
                    end if;
                when W_REQ_SETUP =>  
                    if (RegFile_Grant='1') then 
                        WRITE_CS <= W_SETUP;
                    else 
                        WRITE_CS <= W_REQ_SETUP;   
                    end if;       
                
                when W_SETUP => 
                    if (AddrCount_TC = '1' or AddrCount_TC2 = '1') then 
                        WRITE_CS <= W_RX_ACTIVE;
                    else 
                        WRITE_CS <= W_SETUP; 
                    end if;
                
                when W_RX_ACTIVE => 
                    if (RX_CL8W_Comp='1' or RX_B16W_Comp='1') then 
                        WRITE_CS <= W_WAIT_ADDRACK;
                    else 
                        WRITE_CS <= W_RX_ACTIVE; 
                    end if;
        
                when W_WAIT_ADDRACK => 
                    if (AddrAck='1' and CL8W='1') then 
                        WRITE_CS <= W_REQ_UPDATE_PNTR;
                    elsif (AddrAck='1' and B16W='1') then 
                        WRITE_CS <= W_REQ_STORE;
                    else 
                        WRITE_CS <= W_WAIT_ADDRACK; 
                    end if;
                
                when W_REQ_UPDATE_PNTR =>  
                    if (RegFile_Grant='1') then 
                        WRITE_CS <= W_UPDATE_PNTR;
                    else 
                        WRITE_CS <= W_REQ_UPDATE_PNTR; 
                    end if;
        
                when W_UPDATE_PNTR =>  
                    WRITE_CS <= W_UPDATE_PNTR2;
        
                when W_UPDATE_PNTR2 =>  
                    WRITE_CS <= W_IDLE;
        
                when W_REQ_STORE => 
                    if (RegFile_Grant='1') then 
                        WRITE_CS <= W_STORE;
                    else 
                        WRITE_CS <= W_REQ_STORE; 
                    end if;
        
                when W_STORE => 
                    if (AddrCount_TC='1') then 
                        WRITE_CS <= W_IDLE;
                    else 
                        WRITE_CS <= W_STORE; 
                    end if;
                when others =>
                    WRITE_CS <= W_IDLE;
            end case; -- case(WRITE_CS)
        end if;
    end if;
end process WRITE_PORT_SM;
    
end implementation;
