-------------------------------------------------------------------------------
-- sdma_datapath.vhd
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
-- Filename:        sdma_datapath.vhd
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
--  - Added reset_module
--  - Added DMA Control register 
--  - Modified register memory/bit map
-- ^^^^^^
--  GAB     7/27/07
-- ~~~~~~
--  - Modifed data source for the descrete versions of current and tail desc.
--  ptr register to not source via mux containing pi_rdfifo_data.  This reduced
--  several of the paths pi_rdfifo_data needed to feed thus fixing a long timing
--  path.
-- ^^^^^^
--  GAB     10/22/07
-- ~~~~~~
--  - Registered PI_RdFIFO_Data for LUTRAM with pi_clk to fix long timing path.
-- ^^^^^^
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
entity sdma_datapath is
  generic(
    C_INSTANTIATE_TIMER_TX               : integer   := 1;
    C_INSTANTIATE_TIMER_RX               : integer   := 1;
    C_PI_RDDATA_DELAY                    : integer   := 0;
    C_PI2LL_CLK_RATIO                    : integer   := 1
    );
  port(
    -- Global Signals
    PI_clk                               : in std_logic;
    LLink_Clk                            : in std_logic;  -- I
    LLink_Rst                            : in std_logic;  -- I
    -- Port Interface Data Buses
    PI_WrFIFO_Data                       : out std_logic_vector(31 downto 0); 
    PI_RdFIFO_Data                       : in  std_logic_vector(31 downto 0); 
    -- TX Local Link Data Bus
    TX_D                                 : out std_logic_vector(31 downto 0); 
    -- RX Local Link Data Bus   
    RX_D                                 : in  std_logic_vector(31 downto 0); 
    -- DATAPATH CONTROL SIGNALS
    -- DCR Data Buses
    IPIC_WrDBus                          : in  std_logic_vector(0 to 31); 
    IPIC_RdDBus                          : out std_logic_vector(0 to 31); 
    -- Data Bus Select Signals
    SDMA_Sel_AddrLen                    : in  std_logic_vector(1 downto 0);  
    SDMA_Sel_Data_Src                   : in  std_logic_vector(1 downto 0);  
    SDMA_Sel_PI_rdData_Pos              : in  std_logic_vector(3 downto 0);  
    SDMA_Sel_Status_Writeback           : in  std_logic_vector(1 downto 0);  
    -- Register File Controls
    SDMA_RegFile_WE                     : in  std_logic;  -- I
    SDMA_RegFile_Sel_Eng                : in  std_logic;  
    SDMA_RegFile_Sel_Reg                : in  std_logic_vector(2 downto 0);  
    -- Counter Signals
    SDMA_TX_Address                     : out std_logic_vector(31 downto 0); 
    SDMA_TX_Address_Load                : in  std_logic;  -- I
    SDMA_TX_Length                      : out std_logic_vector(31 downto 0); 
    SDMA_TX_Length_Load                 : in  std_logic;  -- I
    SDMA_TX_AddrLen_INC1                : in  std_logic;  -- I               
    SDMA_TX_AddrLen_INC2                : in  std_logic;  -- I
    SDMA_TX_AddrLen_INC3                : in  std_logic;  -- I
    SDMA_TX_AddrLen_INC4                : in  std_logic;  -- I
    SDMA_RX_Address                     : out std_logic_vector(31 downto 0); 
    SDMA_RX_Address_Reg                 : out std_logic_vector(31 downto 0); 
    SDMA_RX_Address_Load                : in  std_logic;  -- I
    SDMA_RX_Length                      : out std_logic_vector(31 downto 0); 
    SDMA_RX_Length_Load                 : in  std_logic;  -- I
    SDMA_RX_AddrLen_INC1                : in  std_logic;  -- I               
    SDMA_RX_AddrLen_INC2                : in  std_logic;  -- I
    SDMA_RX_AddrLen_INC3                : in  std_logic;  -- I
    SDMA_RX_AddrLen_INC4                : in  std_logic;  -- I
    -- TX Status Register Signals
    SDMA_TX_Status_Detect_Busy_Wr       : in  std_logic;  -- I
    SDMA_TX_Status_Detect_Curr_Ptr_Err  : in  std_logic;  -- I
    SDMA_TX_Status_Detect_Tail_Ptr_Err  : in  std_logic;
    SDMA_TX_Status_Detect_Nxt_Ptr_Err   : in  std_logic;  -- I
    SDMA_TX_Status_Detect_Addr_Err      : in  std_logic;  -- I 
    SDMA_TX_Status_Detect_Completed_Err : in  std_logic;  -- I
    SDMA_TX_Status_Set_SDMA_Completed  : in  std_logic;  -- I
    SDMA_TX_Status_SetBusy              : in  std_logic;
    SDMA_TX_Status_Detect_Stop          : in  std_logic;  -- I
    SDMA_TX_Status_Detect_Null_Ptr      : in  std_logic;  -- I
    SDMA_TX_Status_Mem_CE               : in  std_logic;  -- I
    SDMA_TX_Status_Out                  : out std_logic_vector(0 to 31);  
    -- RX Status Register Signals
    SDMA_RX_Status_Detect_Busy_Wr       : in  std_logic;  -- I
    SDMA_RX_Status_Detect_Tail_Ptr_Err  : in  std_logic;
    SDMA_RX_Status_Detect_Curr_Ptr_Err  : in  std_logic;  -- I
    SDMA_RX_Status_Detect_Nxt_Ptr_Err   : in  std_logic;  -- I
    SDMA_RX_Status_Detect_Addr_Err      : in  std_logic;  -- I 
    SDMA_RX_Status_Detect_Completed_Err : in  std_logic;  -- I
    SDMA_RX_Status_Set_SDMA_Completed  : in  std_logic;  -- I
    SDMA_RX_Status_Set_Start_Of_Packet  : in  std_logic;  -- I
    SDMA_RX_Status_Set_End_Of_Packet    : in  std_logic;  -- I
    SDMA_RX_Status_SetBusy              : in  std_logic;
    SDMA_RX_Status_Detect_Stop          : in  std_logic;  -- I
    SDMA_RX_Status_Detect_Null_Ptr      : in  std_logic;  -- I
    SDMA_RX_Status_Mem_CE               : in  std_logic;  -- I
    SDMA_RX_Status_Out                  : out std_logic_vector(0 to 31);
    -- Channel Reset Signals
    SDMA_TX_ChannelRST                  : out std_logic;  -- O
    SDMA_RX_ChannelRST                  : out std_logic;  -- O
    SDMA_RX_Error_Reset                 : out std_logic;
    SDMA_TX_Error_Reset                 : out std_logic;
    ResetComplete                       : in  std_logic;
    
    -- TX Byte Shifter Controls
    SDMA_TX_Shifter_Byte_Sel0           : in  std_logic_vector(1 downto 0);  -- I (1:0)
    SDMA_TX_Shifter_Byte_Sel1           : in  std_logic_vector(1 downto 0);  -- I (1:0)
    SDMA_TX_Shifter_Byte_Sel2           : in  std_logic_vector(1 downto 0);  -- I (1:0)
    SDMA_TX_Shifter_Byte_Sel3           : in  std_logic_vector(1 downto 0);  -- I (1:0)
    SDMA_TX_Shifter_Byte_Reg_CE         : in  std_logic_vector(3 downto 0);  -- I (3:0)
    -- RX Byte Shifter Controls
    SDMA_RX_Shifter_HoldReg_CE          : in  std_logic;  -- I
    SDMA_RX_Shifter_Byte_Sel            : in  std_logic_vector(1 downto 0);  -- I (1:0)
    SDMA_RX_Shifter_CE                  : in  std_logic_vector(7 downto 0);  -- I (7:0)
    
    -- TailPointer Mode Support
    SDMA_TX_CurDesc_Ptr                 : out std_logic_vector(0 to 31);
    SDMA_TX_TailDesc_Ptr                : out std_logic_vector(0 to 31);
    SDMA_RX_CurDesc_Ptr                 : out std_logic_vector(0 to 31);
    SDMA_RX_TailDesc_Ptr                : out std_logic_vector(0 to 31);
    IPIC_Control_Reg_WE                 : in  std_logic;
    IPIC_Control_Reg_RE                 : in  std_logic                     ;
    IPIC_TX_Cntl_Reg_WE                 : in  std_logic                     ;
    IPIC_RX_Cntl_Reg_WE                 : in  std_logic                     ;
    IPIC_TX_Sts_Reg_RE                  : in  std_logic                     ;
    IPIC_RX_Sts_Reg_RE                  : in  std_logic                     ;
    IPIC_TX_TailPtr_Reg_WE              : in  std_logic                     ;
    IPIC_RX_TailPtr_Reg_WE              : in  std_logic                     ;

    SDMA_TX_Control_Reg                 : out std_logic_vector(0 to 31);
    SDMA_RX_Control_Reg                 : out std_logic_vector(0 to 31);
    SDMA_Control_Reg                    : out std_logic_vector(0 to 31);
    -- 32-bit signals
    early_pop_i				: in std_logic;
    early_pop_i_d1				: in std_logic;
    early_pop_i_d2				: in std_logic;
    early_pop_i_d3				: in std_logic;
    early_pop_i_d4				: in std_logic;  
    early_pop_i_d5				: in std_logic;
    early_pop_i_d6				: in std_logic;  
    d_reg_ce				: in std_logic;
    PI_RdFIFO_Empty         : in  std_logic;


    -- Additional Datapath Signals
    wrDataAck_Pos                       : in  std_logic;  -- I
    wrDataAck_Neg                       : in  std_logic;  -- I
    rdDataAck_Pos                       : in  std_logic;  -- I
    rdDataAck_Neg                       : in  std_logic;  -- I
    delay_reg_ce                        : in  std_logic;  -- I
    delay_reg_sel                       : in  std_logic_vector(1 downto 0)   -- I (1:0)
    );
end sdma_datapath;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_datapath is
  
-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
-- Disabled rx fifo overflow error(27), Disable tx fifo_overflow error(28),
-- and enable tail pointer mode(29)
constant DEFAULT_CNTRL_SETTING      : std_logic_vector(0 to 31) := X"0000001C"; 
constant CHNL_CNTRL_REG_DEFAULT     : std_logic_vector(0 to 31) := X"FFFF0000";

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal PI_RdFIFO_Data_Reorder       : std_logic_vector(0 to 63); 
signal PI_RdFIFO_Data_reg	    : std_logic_vector(31 downto 0);
signal PI_RdFIFO_Data_muxed	    : std_logic_vector(63 downto 0);
signal PI_RdFIFO_Data_muxed_HOreg   : std_logic_vector(63 downto 32);

signal rdFIFO_Data                  : std_logic_vector(63 downto 0);    
signal rdFIFO_Data_d1               : std_logic_vector(63 downto 0);    
signal rdFIFO_Data_d2               : std_logic_vector(63 downto 0);    
signal PI_rdData_d1                 : std_logic_vector(31 downto 0);    
signal PI_rdData                    : std_logic_vector(31 downto 0);    
signal PI_rdData_i                  : std_logic_vector(31 downto 0);    
signal PI_rdData_reg                : std_logic_vector(31 downto 0);    
signal rdData_sel                   : std_logic;    

signal SDMA_AddrLenMux_Out          : std_logic_vector(31 downto 0);    
signal SDMA_RegFile_Status_DI       : std_logic_vector(31 downto 0);    
signal SDMA_RegFile_DO              : std_logic_vector(31 downto 0);    

signal SDMA_TX_Status_Out_Mem       : std_logic_vector(0 to 31);    
signal SDMA_RX_Status_Out_Mem       : std_logic_vector(0 to 31);    
signal SDMA_TX_Status_Out_DCR       : std_logic_vector(0 to 31);    
signal SDMA_RX_Status_Out_DCR       : std_logic_vector(0 to 31);    
signal SDMA_discrete_reg_data       : std_logic_vector(0 to 31);    

signal PI_WrFIFO_Data_UpperByte     : std_logic_vector(7 downto 0);     
signal PI_WrFIFO_Data_Reorder       : std_logic_vector(0 to 31);        
signal PI_WrFIFO_Data_i             : std_logic_vector(63 downto 0);    

signal sig_tx_status_reset          : std_logic;
signal sig_rx_status_reset          : std_logic;
signal SDMA_tx_address_i            : std_logic_vector(31 downto 0);
signal SDMA_tx_length_i             : std_logic_vector(31 downto 0);
signal SDMA_rx_address_i            : std_logic_vector(31 downto 0);
signal SDMA_rx_length_i             : std_logic_vector(31 downto 0);
signal SDMA_tx_channelrst_i         : std_logic;
signal SDMA_rx_channelrst_i         : std_logic;

signal regfile_addr                 : std_logic_vector(0 to 3);
signal channel_reset_i              : std_logic;
signal SDMA_control_reg_i           : std_logic_vector(0 to 31);
signal SDMA_tx_control_reg_i        : std_logic_vector(0 to 31);
signal SDMA_rx_control_reg_i        : std_logic_vector(0 to 31);

signal rx_error_reset_i             : std_logic;
signal tx_error_reset_i             : std_logic;
signal rx_datapath_rst              : std_logic;
signal tx_datapath_rst              : std_logic;
signal d_reg_ce_d1              : std_logic;
signal d_reg_ce_d2              : std_logic;
signal PI_RdFIFO_Empty_d1              : std_logic;
--signal early_pop_i_d3              : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

SDMA_TX_Status_Out <= SDMA_TX_Status_Out_DCR;
SDMA_RX_Status_Out <= SDMA_RX_Status_Out_DCR;

SDMA_TX_Address    <= SDMA_tx_address_i   ;
SDMA_TX_Length     <= SDMA_tx_length_i    ;
SDMA_RX_Address    <= SDMA_rx_address_i   ;
SDMA_RX_Length     <= SDMA_rx_length_i    ;
SDMA_TX_ChannelRST <= SDMA_tx_channelrst_i;
SDMA_RX_ChannelRST <= SDMA_rx_channelrst_i;

SDMA_RX_Error_Reset<= rx_error_reset_i;
SDMA_TX_Error_Reset<= tx_error_reset_i;


rx_datapath_rst <= rx_error_reset_i or ResetComplete;
tx_datapath_rst <= tx_error_reset_i or ResetComplete;

-------------------------------------------------------------------------------   
-- for 32-bit datapath
-------------------------------------------------------------------------------   
GEN_READ_DELAY_2_c1 : if ((C_PI_RDDATA_DELAY = 2) and
                          (C_PI2LL_CLK_RATIO = 1)) generate

PI_RdFIFO_Data_muxed(63 downto 32) <= PI_RdFIFO_Data_muxed_HOreg when
         (early_pop_i_d2 = '1' or early_pop_i_d4 ='1' or early_pop_i_d6 ='1' or
         (d_reg_ce_d2 ='1' and (PI_RdFIFO_Empty_d1 ='0'))) else
          PI_RdFIFO_Data(31 downto 0);

    process(LLink_Clk)
        begin
             if(LLink_Clk'EVENT and LLink_Clk='1')then
               if (LLink_Rst='1') then
                   PI_RdFIFO_Data_muxed_HOreg(63 downto 32) <= (others => '0');
               elsif(not((early_pop_i_d2 = '1' or early_pop_i_d4 ='1' or
                     early_pop_i_d6 ='1' or
                   (d_reg_ce_d2 ='1' and (PI_RdFIFO_Empty_d1 ='0'))))) then
                   PI_RdFIFO_Data_muxed_HOreg(63 downto 32) <= PI_RdFIFO_Data;
               end if;
             end if;
    end process;
    
    process(LLink_Clk)
        begin
             if(LLink_Clk'EVENT and LLink_Clk='1')then
               if (LLink_Rst='1') then
                 d_reg_ce_d1 <= '0';
                 d_reg_ce_d2 <= '0';
                 PI_RdFIFO_Empty_d1 <= '0';
    	      
               else
                 d_reg_ce_d1 <= d_reg_ce;
                 d_reg_ce_d2 <= d_reg_ce_d1;
                 PI_RdFIFO_Empty_d1 <= PI_RdFIFO_Empty;
   
               end if;
             end if;
    end process;

register_data: process(LLink_clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst='1')then
                PI_RdFIFO_Data_reg(31 downto 0) <= (others => '0');
            elsif (early_pop_i_d2 = '1' or early_pop_i_d4 ='1' or early_pop_i_d6 ='1' or (d_reg_ce_d2 ='1' and (PI_RdFIFO_Empty_d1 ='0')))then
              PI_RdFIFO_Data_reg(31 downto 0) <= PI_RdFIFO_Data(31 downto 0);
            end if;
        end if;
    end process register_data;

PI_RdFIFO_Data_muxed(31 downto 0) <= PI_RdFIFO_Data_reg(31 downto 0); 

end generate GEN_READ_DELAY_2_c1;

GEN_READ_DELAY_1_c2 : if ((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 2)) generate

PI_RdFIFO_Data_muxed(63 downto 32) <= PI_RdFIFO_Data(31 downto 0);
    
    process(LLink_Clk)
        begin
             if(LLink_Clk'EVENT and LLink_Clk='1')then
               if (LLink_Rst='1') then
                 d_reg_ce_d1 <= '0';
                 d_reg_ce_d2 <= '0';
    	      
               else
                 d_reg_ce_d1 <= d_reg_ce;
                 d_reg_ce_d2 <= d_reg_ce_d1;
   
               end if;
             end if;
    end process;

register_data: process(LLink_clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst='1')then
                PI_RdFIFO_Data_reg(31 downto 0) <= (others => '0');
            elsif(early_pop_i = '1' or (d_reg_ce ='1' and (PI_RdFIFO_Empty ='0')))then
              PI_RdFIFO_Data_reg(31 downto 0) <= PI_RdFIFO_Data(31 downto 0);
            end if;
        end if;
    end process register_data;

PI_RdFIFO_Data_muxed(31 downto 0) <= PI_RdFIFO_Data(31 downto 0) when (early_pop_i = '1' or (d_reg_ce ='1' and (PI_RdFIFO_Empty ='0'))) else PI_RdFIFO_Data_reg(31 downto 0); 

end generate GEN_READ_DELAY_1_c2;

GEN_READ_DELAY_1_c1 : if ((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) generate
 
PI_RdFIFO_Data_muxed(63 downto 32) <= PI_RdFIFO_Data(31 downto 0);
    
    process(LLink_Clk)
        begin
             if(LLink_Clk'EVENT and LLink_Clk='1')then
               if (LLink_Rst='1') then
                 d_reg_ce_d1 <= '0';
                 d_reg_ce_d2 <= '0';
    	      
               else
                 d_reg_ce_d1 <= d_reg_ce;
                 d_reg_ce_d2 <= d_reg_ce_d1;
   
               end if;
             end if;
    end process;

register_data: process(LLink_clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst='1')then
                PI_RdFIFO_Data_reg(31 downto 0) <= (others => '0');
            elsif(early_pop_i_d1 ='1' or early_pop_i_d3 ='1' or (d_reg_ce_d2 ='1' and (PI_RdFIFO_Empty ='0')))then
              PI_RdFIFO_Data_reg(31 downto 0) <= PI_RdFIFO_Data(31 downto 0);
            end if;
        end if;
    end process register_data;

PI_RdFIFO_Data_muxed(31 downto 0) <= PI_RdFIFO_Data_reg(31 downto 0); 

end generate GEN_READ_DELAY_1_c1;

GEN_READ_DELAY_2_c2 : if ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))	generate

PI_RdFIFO_Data_muxed(63 downto 32) <= PI_RdFIFO_Data(31 downto 0);
    
    process(LLink_Clk)
        begin
             if(LLink_Clk'EVENT and LLink_Clk='1')then
               if (LLink_Rst='1') then
                 d_reg_ce_d1 <= '0';
                 d_reg_ce_d2 <= '0';
    	      
               else
                 d_reg_ce_d1 <= d_reg_ce;
                 d_reg_ce_d2 <= d_reg_ce_d1;
   
               end if;
             end if;
    end process;

register_data: process(LLink_clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst='1')then
                PI_RdFIFO_Data_reg(31 downto 0) <= (others => '0');
            elsif(early_pop_i_d1 ='1' or early_pop_i_d3 ='1' or (d_reg_ce_d2 ='1' and (PI_RdFIFO_Empty ='0')))then
              PI_RdFIFO_Data_reg(31 downto 0) <= PI_RdFIFO_Data(31 downto 0);
            end if;
        end if;
    end process register_data;

PI_RdFIFO_Data_muxed(31 downto 0) <= PI_RdFIFO_Data(31 downto 0) when (early_pop_i_d1 ='1' or early_pop_i_d3 ='1' or (d_reg_ce_d2 ='1' and (PI_RdFIFO_Empty ='0'))) else PI_RdFIFO_Data_reg(31 downto 0); 

end generate GEN_READ_DELAY_2_c2;

GEN_READ_DELAY_zero : if (C_PI_RDDATA_DELAY = 0) generate

PI_RdFIFO_Data_muxed(63 downto 32) <= PI_RdFIFO_Data(31 downto 0);

register_data: process(LLink_clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst='1')then
                PI_RdFIFO_Data_reg(31 downto 0) <= (others => '0');
            elsif(early_pop_i ='1' or (d_reg_ce ='1' and (PI_RdFIFO_Empty ='0')))then
              PI_RdFIFO_Data_reg(31 downto 0) <= PI_RdFIFO_Data(31 downto 0);
            end if;
        end if;
    end process register_data;

PI_RdFIFO_Data_muxed(31 downto 0) <= PI_RdFIFO_Data(31 downto 0) when (early_pop_i ='1' or (d_reg_ce ='1' and (PI_RdFIFO_Empty ='0'))) else PI_RdFIFO_Data_reg(31 downto 0); 

end generate GEN_READ_DELAY_zero;
-------------------------------------------------------------------------------   
-- Mux Address and Length Inputs to Register File
-------------------------------------------------------------------------------   
ADDR_LNGTH_MUX : process(SDMA_Sel_AddrLen, SDMA_tx_address_i, SDMA_tx_length_i, SDMA_rx_address_i, SDMA_rx_length_i)
    begin
        case SDMA_Sel_AddrLen is
            when "00" => 
                SDMA_AddrLenMux_Out <= SDMA_tx_address_i;
            when "01" => 
                SDMA_AddrLenMux_Out <= SDMA_tx_length_i;
            when "10" => 
                SDMA_AddrLenMux_Out <= SDMA_rx_address_i;
            when "11" => 
                SDMA_AddrLenMux_Out <= SDMA_rx_length_i;
            when others => 
                SDMA_AddrLenMux_Out <= (others => '0');
        end case;
    end process ADDR_LNGTH_MUX;

-------------------------------------------------------------------------------   
-- Byte reordering within read data bus
-------------------------------------------------------------------------------   
GEN_RDDATA_REORDER : for i in 0 to 7 generate
    PI_RdFIFO_Data_Reorder((i*8) to (i*8)+7) <= PI_RdFIFO_Data_muxed((i*8)+7 downto (i*8));
end generate;
   
-------------------------------------------------------------------------------   
-- Register Data for 2 Clock FIFO Latency
-------------------------------------------------------------------------------   
GEN_READ_DELAY_2 : if ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) generate
    REG_READ_DATA : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst='1') then
                    rdFIFO_Data_d1 <= (others => '0');
                    rdFIFO_Data_d2 <= (others => '0');
                elsif (delay_reg_ce='1') then
                    rdFIFO_Data_d1 <= PI_RdFIFO_Data_Reorder;
                    rdFIFO_Data_d2 <= rdFIFO_Data_d1;
                end if;
            end if;
        end process REG_READ_DATA;

                 
    READ_DATA_MUX : process(delay_reg_sel, PI_RdFIFO_Data_Reorder, rdFIFO_Data_d1, rdFIFO_Data_d2)
        begin
            case delay_reg_sel is
                when "00" => 
                    rdFIFO_Data <= PI_RdFIFO_Data_Reorder;
                when "01" => 
                    rdFIFO_Data <= rdFIFO_Data_d1;
                when "10" => 
                    rdFIFO_Data <= rdFIFO_Data_d2;
                when others => 
                    rdFIFO_Data <= (others => '0');
            end case;
        end process;
end generate GEN_READ_DELAY_2;
                
-------------------------------------------------------------------------------   
-- Register Data for 1 Clock FIFO Latency
-------------------------------------------------------------------------------   
GEN_READ_DELAY_1 : if (((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) or
               ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))) generate

    REG_READ_DATA : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst='1') then
                    rdFIFO_Data_d1 <= (others => '0');
                elsif (delay_reg_ce='1') then
                    rdFIFO_Data_d1 <= PI_RdFIFO_Data_Reorder;
                end if;
           end if;
       end process REG_READ_DATA;

    READ_DATA_MUX : process(delay_reg_sel, PI_RdFIFO_Data_Reorder, rdFIFO_Data_d1)
        begin
            case delay_reg_sel is
                when "00" => 
                    rdFIFO_Data <= PI_RdFIFO_Data_Reorder;
                when "01" => 
                    rdFIFO_Data <= rdFIFO_Data_d1;
                when others => 
                    rdFIFO_Data <= (others => '0');
            end case;
        end process READ_DATA_MUX;
end generate GEN_READ_DELAY_1;

-------------------------------------------------------------------------------   
-- Register Data for 0 Clock FIFO Latency
-------------------------------------------------------------------------------   
GEN_READ_DELAY_0 : if not((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) and
                      not(((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) or
                         ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))) generate
    rdFIFO_Data <= PI_RdFIFO_Data_Reorder;
end generate;
         
   
-------------------------------------------------------------------------------   
-- Register Half of Read Data
-------------------------------------------------------------------------------   
REG_PI_RD_DATA : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1') then
            if(LLink_Rst='1') then
                PI_rdData_reg <= (others => '0');
            elsif (rdDataAck_Pos = '1') then
                PI_rdData_reg <= rdFIFO_Data(31 downto 0);
            end if;
        end if;
    end process REG_PI_RD_DATA;

REG_RDSEL : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1') then
            if(LLink_Rst='1' or rdDataAck_Neg='1') then
                rdData_sel <= '0';
            elsif (rdDataAck_Pos = '1') then
                rdData_sel <= '1';
            end if;
        end if;
    end process REG_RDSEL;

PI_rdData_i <= PI_rdData_reg when rdData_sel='1' else rdFIFO_Data(31 downto 0);
   
-------------------------------------------------------------------------------
-- Mux Port RdData between Pos and Neg by Byte
-------------------------------------------------------------------------------
PI_rdData(31 downto 24) <= rdFIFO_Data(63 downto 56) when SDMA_Sel_PI_rdData_Pos(3)='1'  
                      else PI_rdData_i(31 downto 24);

PI_rdData(23 downto 16) <= rdFIFO_Data(55 downto 48) when SDMA_Sel_PI_rdData_Pos(2)='1'  
                      else PI_rdData_i(23 downto 16);

PI_rdData(15 downto 8)  <= rdFIFO_Data(47 downto 40) when SDMA_Sel_PI_rdData_Pos(1)='1'  
                      else PI_rdData_i(15 downto 8);

PI_rdData(7 downto 0)   <= rdFIFO_Data(39 downto 32) when SDMA_Sel_PI_rdData_Pos(0)='1'  
                      else PI_rdData_i(7 downto 0);


-------------------------------------------------------------------------------
-- Pipeline for cases when clk ration is greater than 1 to fix long timing
-- path.
-------------------------------------------------------------------------------
GEN_FOR_RATIO_GRTR1 : if C_PI2LL_CLK_RATIO > 1 generate
    REG_RDDATA4RAM : process(PI_clk)
        begin
            if(PI_clk'EVENT and PI_clk='1')then

                PI_rdData_d1 <= PI_rdData;
            end if;
        end process REG_RDDATA4RAM;
end generate GEN_FOR_RATIO_GRTR1;

GEN_FOR_RATIO_ONE : if C_PI2LL_CLK_RATIO = 1 generate
    PI_rdData_d1 <= PI_rdData;
end generate GEN_FOR_RATIO_ONE;


-------------------------------------------------------------------------------
-- Mux Address and Length Inputs to Register File
-------------------------------------------------------------------------------
REG_FILE_MUX : process(SDMA_Sel_Data_Src, SDMA_AddrLenMux_Out, IPIC_WrDBus, PI_rdData_d1)
     begin
       case SDMA_Sel_Data_Src is
        when "00" => 
            SDMA_RegFile_Status_DI <= SDMA_AddrLenMux_Out;
        when "01" => 
            SDMA_RegFile_Status_DI <= IPIC_WrDBus;
        when "10" => 
--            SDMA_RegFile_Status_DI <= PI_rdData;
            SDMA_RegFile_Status_DI <= PI_rdData_d1;
        when others => 
            SDMA_RegFile_Status_DI <= (others => '0');
       end case;
   end process REG_FILE_MUX;


-------------------------------------------------------------------------------
-- LUT RAM
-- Use a lut RAM if the selected device supports LUT RAM's and the Address
-- width is within the bounds of a LUT RAM.
-------------------------------------------------------------------------------
COMP_DMAC_RegFile : for i in 31 downto 0  generate
    LUT_RAM : RAM16X1S
        generic map
        (
            INIT    => X"0000"
        )
        port map
        (
            WE      => SDMA_RegFile_WE             ,
            D       => SDMA_RegFile_Status_DI(i)   ,
            WCLK    => LLink_Clk        ,
            A0      => SDMA_RegFile_Sel_Reg(0)     ,
            A1      => SDMA_RegFile_Sel_Reg(1)     ,
            A2      => SDMA_RegFile_Sel_Reg(2)     ,
            A3      => SDMA_RegFile_Sel_Eng        ,
            O       => SDMA_RegFile_DO(i)
        );
end generate COMP_DMAC_RegFile;


-------------------------------------------------------------------------------
-- Transmit Current Descriptor Register (Copy of RegFile entry - offset 0x0C)
-------------------------------------------------------------------------------
regfile_addr    <= SDMA_RegFile_Sel_Eng
                 & SDMA_RegFile_Sel_Reg(2)
                 & SDMA_RegFile_Sel_Reg(1) 
                 & SDMA_RegFile_Sel_Reg(0);
                 
--TX_CURDESC_REGISTER : process(LLink_Clk)
--    begin
--        if(LLink_Clk'EVENT and LLink_Clk='1')then
--            if(LLink_Rst = '1')then
--                SDMA_TX_CurDesc_Ptr <= (others => '0');
--            elsif(regfile_addr=TX_CURDESC_PTR and SDMA_RegFile_WE='1')then
--                SDMA_TX_CurDesc_Ptr <= SDMA_RegFile_Status_DI;
--            end if;
--        end if;
--    end process TX_CURDESC_REGISTER;
-- GAB - Modifed 7/27 to fix a long timing path
-- Only a plb access or an internal pointer update writes to currect desc. ptr
TX_CURDESC_REGISTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1')then
                SDMA_TX_CurDesc_Ptr <= (others => '0');
            elsif(regfile_addr=TX_CURDESC_PTR and SDMA_RegFile_WE='1' )then
                if(SDMA_Sel_Data_Src="00")then
                    SDMA_TX_CurDesc_Ptr <= SDMA_AddrLenMux_Out;
                else
                    SDMA_TX_CurDesc_Ptr <= IPIC_WrDBus;
                end if;
            end if;
        end if;
    end process TX_CURDESC_REGISTER;



-------------------------------------------------------------------------------
-- Transmit Tail Descriptor Register  (Copy of RegFile entry - offset 0x10)
-------------------------------------------------------------------------------
--TX_TAILPTR_REGISTER : process(LLink_Clk)
--    begin
--        if(LLink_Clk'EVENT and LLink_Clk='1')then
--            if(LLink_Rst = '1')then
--                SDMA_TX_TailDesc_Ptr <= (others => '0');
--            elsif(IPIC_TX_TailPtr_Reg_WE='1')then
--                SDMA_TX_TailDesc_Ptr <= SDMA_RegFile_Status_DI;
--            end if;
--        end if;
--    end process TX_TAILPTR_REGISTER;
-- GAB - Modifed 7/27 to fix a long timing path
-- Only a plb access writes to tail desc. ptr
TX_TAILPTR_REGISTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1')then
                SDMA_TX_TailDesc_Ptr <= (others => '0');
            elsif(IPIC_TX_TailPtr_Reg_WE='1')then
                SDMA_TX_TailDesc_Ptr <= IPIC_WrDBus;
            end if;
        end if;
    end process TX_TAILPTR_REGISTER;

-------------------------------------------------------------------------------
-- Receive Current Descriptor Register (Copy of RegFile entry - offset 0x2C)
-------------------------------------------------------------------------------
--RX_CURDESC_REGISTER : process(LLink_Clk)
--    begin
--        if(LLink_Clk'EVENT and LLink_Clk='1')then
--            if(LLink_Rst = '1')then
--                SDMA_RX_CurDesc_Ptr <= (others => '0');
--            elsif(regfile_addr=RX_CURDESC_PTR and SDMA_RegFile_WE='1')then
--                SDMA_RX_CurDesc_Ptr <= SDMA_RegFile_Status_DI;
--            end if;
--        end if;
--    end process RX_CURDESC_REGISTER;
-- GAB - Modifed 7/27 to fix a long timing path
-- Only a plb access or an internal pointer update writes to currect desc. ptr
RX_CURDESC_REGISTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1')then
                SDMA_RX_CurDesc_Ptr <= (others => '0');
            elsif(regfile_addr=RX_CURDESC_PTR and SDMA_RegFile_WE='1')then
                if(SDMA_Sel_Data_Src="00")then
                    SDMA_RX_CurDesc_Ptr <= SDMA_AddrLenMux_Out;
                else
                    SDMA_RX_CurDesc_Ptr <= IPIC_WrDBus;
                end if;
            end if;
        end if;
    end process RX_CURDESC_REGISTER;

-------------------------------------------------------------------------------
-- Receive Tail Descriptor Register (Copy of RegFile entry - offset 0x30)
-------------------------------------------------------------------------------
--RX_TAILPTR_REGISTER : process(LLink_Clk)
--    begin
--        if(LLink_Clk'EVENT and LLink_Clk='1')then
--            if(LLink_Rst = '1' or ResetComplete='1')then
--                SDMA_RX_TailDesc_Ptr <= (others => '0');
--            elsif(IPIC_RX_TailPtr_Reg_WE='1')then
--                SDMA_RX_TailDesc_Ptr <= SDMA_RegFile_Status_DI;
--            end if;
--        end if;
--    end process RX_TAILPTR_REGISTER;
-- GAB - Modifed 7/27 to fix a long timing path
-- Only a plb access writes to tail desc. ptr
RX_TAILPTR_REGISTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or ResetComplete='1')then
                SDMA_RX_TailDesc_Ptr <= (others => '0');
            elsif(IPIC_RX_TailPtr_Reg_WE='1')then
                SDMA_RX_TailDesc_Ptr <= IPIC_WrDBus;
            end if;
        end if;
    end process RX_TAILPTR_REGISTER;

-------------------------------------------------------------------------------
-- Transmit Channel Control Register (Copy of RegFile entry - offset 0x14)
-------------------------------------------------------------------------------
TX_CONTROL_REGISTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or ResetComplete='1')then
                SDMA_TX_Control_Reg <= (others => '0');
            elsif(IPIC_TX_Cntl_Reg_WE='1')then
                SDMA_TX_Control_Reg <= IPIC_WrDBus;
            end if;
        end if;
    end process TX_CONTROL_REGISTER;

-------------------------------------------------------------------------------
-- Receive Channel Control Register (Copy of RegFile entry - offset 0x14)
-------------------------------------------------------------------------------
RX_CONTROL_REGISTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or ResetComplete='1')then
                SDMA_RX_Control_Reg <= (others => '0');
            elsif(IPIC_RX_Cntl_Reg_WE='1')then
                SDMA_RX_Control_Reg <= IPIC_WrDBus;
            end if;
        end if;
    end process RX_CONTROL_REGISTER;

-------------------------------------------------------------------------------
-- DMA Control Register  (Discrete Register - offset 0x40)
-------------------------------------------------------------------------------
DMA_CONTROL_REGISTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1')then
                SDMA_control_reg_i <= (others => '0');
            elsif(ResetComplete = '1')then
                SDMA_control_reg_i <= DEFAULT_CNTRL_SETTING(0 to 30) & '0';
            elsif(IPIC_Control_Reg_WE='1')then
                SDMA_control_reg_i <= DEFAULT_CNTRL_SETTING(0 to 30) 
                                        & IPIC_WrDBus(DMA_CNTRL_SWRESET_BIT);
            end if;
        end if;
    end process DMA_CONTROL_REGISTER;

SDMA_Control_Reg <= SDMA_control_reg_i;

-------------------------------------------------------------------------------
-- Reset Module
-- Handles registration of a reset and continued assertion of the reset
-- internally until the full system has been reset.
-------------------------------------------------------------------------------
RST_MODULE_I : entity mpmc_v6_03_a.sdma_reset_module
    port map(
        -- Global Signals
        LLink_Clk           => LLink_Clk                                ,
        LLink_Rst           => LLink_Rst                                ,
        SWRst_In            => SDMA_control_reg_i(DMA_CNTRL_SWRESET_BIT) ,
        ResetComplete       => ResetComplete                            ,
        ChannelRST          => channel_reset_i                          
    );

SDMA_tx_channelrst_i   <= channel_reset_i;
SDMA_rx_channelrst_i   <= channel_reset_i;

-------------------------------------------------------------------------------
-- Transmit Channel Status Register
-------------------------------------------------------------------------------
-- TX Status Reg
--sig_tx_status_reset <= LLink_Rst or SDMA_tx_channelrst_i;
sig_tx_status_reset <= LLink_Rst or ResetComplete; --GAB 4/10/07

COMP_TX_STATUS_REG : entity mpmc_v6_03_a.sdma_channel_status_reg
    PORT MAP (
        LLink_Clk               => LLink_Clk,                                 
        RST                     => sig_tx_status_reset,
        DI                      => SDMA_RegFile_Status_DI,             
        DO_DCR                  => SDMA_TX_Status_Out_DCR,             
        DO_Mem                  => SDMA_TX_Status_Out_Mem,             
                                  
        -- Control Signals        
        Detect_Busy_Wr          => SDMA_TX_Status_Detect_Busy_Wr,      
        Detect_Tail_Ptr_Err     => SDMA_TX_Status_Detect_Tail_Ptr_Err,
        Detect_Curr_Ptr_Err     => SDMA_TX_Status_Detect_Curr_Ptr_Err, 
        Detect_Nxt_Ptr_Err      => SDMA_TX_Status_Detect_Nxt_Ptr_Err,  
        Detect_Addr_Err         => SDMA_TX_Status_Detect_Addr_Err,     
        Detect_Completed_Err    => SDMA_TX_Status_Detect_Completed_Err,
        Set_SDMA_Completed      => SDMA_TX_Status_Set_SDMA_Completed, 
        Set_Start_Of_Packet     => '0',
        Set_End_Of_Packet       => '0',
        Set_Busy                => SDMA_TX_Status_SetBusy,
        Detect_Stop             => SDMA_TX_Status_Detect_Stop,         
        Detect_Null_Ptr         => SDMA_TX_Status_Detect_Null_Ptr,     
        Mem_CE                  => SDMA_TX_Status_Mem_CE,
        Error_Reset             => tx_error_reset_i
    );

-------------------------------------------------------------------------------
-- Recieve Channel Status Register
-------------------------------------------------------------------------------
-- RX Status Reg
--sig_rx_status_reset <= LLink_Rst or  SDMA_rx_channelrst_i;
sig_rx_status_reset <= LLink_Rst or ResetComplete; --GAB 4/10/07
COMP_RX_STATUS_REG : entity mpmc_v6_03_a.sdma_channel_status_reg
    PORT MAP (
        LLink_Clk               => LLink_Clk,                                 
        RST                     => sig_rx_status_reset,
        DI                      => SDMA_RegFile_Status_DI,             
        DO_DCR                  => SDMA_RX_Status_Out_DCR,             
        DO_Mem                  => SDMA_RX_Status_Out_Mem,             
                                  
        -- Control Signals        
        Detect_Busy_Wr          => SDMA_RX_Status_Detect_Busy_Wr,      
        Detect_Tail_Ptr_Err     => SDMA_RX_Status_Detect_Tail_Ptr_Err,
        Detect_Curr_Ptr_Err     => SDMA_RX_Status_Detect_Curr_Ptr_Err, 
        Detect_Nxt_Ptr_Err      => SDMA_RX_Status_Detect_Nxt_Ptr_Err,  
        Detect_Addr_Err         => SDMA_RX_Status_Detect_Addr_Err,     
        Detect_Completed_Err    => SDMA_RX_Status_Detect_Completed_Err,
        Set_SDMA_Completed      => SDMA_RX_Status_Set_SDMA_Completed, 
        Set_Start_Of_Packet     => SDMA_RX_Status_Set_Start_Of_Packet, 
        Set_End_Of_Packet       => SDMA_RX_Status_Set_End_Of_Packet,   
        Set_Busy                => SDMA_RX_Status_SetBusy,
        Detect_Stop             => SDMA_RX_Status_Detect_Stop,         
        Detect_Null_Ptr         => SDMA_RX_Status_Detect_Null_Ptr,     
        Mem_CE                  => SDMA_RX_Status_Mem_CE,             
        Error_Reset             => rx_error_reset_i
    );

-------------------------------------------------------------------------------
-- Mux Between Status Register Outputs
-------------------------------------------------------------------------------
--STS_REG_MUX : process(IPIC_Sel_Discrete_Reg,SDMA_TX_Status_Out_DCR, SDMA_RX_Status_Out_DCR)
--    begin
--        case IPIC_Sel_Discrete_Reg is
--            when "00" => 
--                SDMA_discrete_reg_data <= SDMA_TX_Status_Out_DCR;
--            when "01 => 
--                SDMA_discrete_reg_data <= SDMA_RX_Status_Out_DCR;
--            when "10" => 
--                SDMA_discrete_reg_data <= SDMA_Control_Reg;
--            when others =>  
--                SDMA_discrete_reg_data <= (others => '0');
--            end case;
--   end process STS_REG_MUX;
-- Mux Between Register File and Status Register for DCR
-- Read MUX between LUT RAM and discrete registers
--IPIC_RdDBus <= SDMA_discrete_reg_data when  IPIC_Sel_RdDBus_Src = '1' 
--          else SDMA_RegFile_DO;

DISCRETE_READ_MUX : process(IPIC_Control_Reg_RE,
                            IPIC_TX_Sts_Reg_RE,
                            IPIC_RX_Sts_Reg_RE,
                            SDMA_control_reg_i,
                            SDMA_TX_Status_Out_DCR,
                            SDMA_RX_Status_Out_DCR,
                            SDMA_RegFile_DO)
    begin
        if(IPIC_Control_Reg_RE = '1')then
            IPIC_RdDBus <= SDMA_control_reg_i;
        elsif(IPIC_TX_Sts_Reg_RE='1')then
            IPIC_RdDBus <= SDMA_TX_Status_Out_DCR;
        elsif(IPIC_RX_Sts_Reg_RE='1')then
            IPIC_RdDBus <= SDMA_RX_Status_Out_DCR;
        else
            IPIC_RdDBus <= SDMA_RegFile_DO;
        end if;
    end process DISCRETE_READ_MUX;



-------------------------------------------------------------------------------
-- Transmit Address Counters
-------------------------------------------------------------------------------
COMP_TX_ADDRESS_COUNTER : entity mpmc_v6_03_a.sdma_address_counter
    PORT MAP (
        LLink_Clk           => LLink_Clk,                       -- I
        LLink_Rst           => tx_datapath_rst,                 -- I
        Address_In          => SDMA_RegFile_DO,                 -- I (31:0)
        Address_Out         => SDMA_tx_address_i,               -- O (31:0)
        Address_Load        => SDMA_TX_Address_Load,            -- I
        INC1                => SDMA_TX_AddrLen_INC1,            -- I                     
        INC2                => SDMA_TX_AddrLen_INC2,            -- I
        INC3                => SDMA_TX_AddrLen_INC3,            -- I
        INC4                => SDMA_TX_AddrLen_INC4             -- I
    );

-------------------------------------------------------------------------------
-- Transmit Length Counters
-------------------------------------------------------------------------------
COMP_TX_LENGTH_COUNTER : entity mpmc_v6_03_a.sdma_length_counter
    PORT MAP (
        LLink_Clk           => LLink_Clk,                       -- I
        LLink_Rst           => tx_datapath_rst ,                -- I
        Length_In           => SDMA_RegFile_DO,                 -- I (31:0)
        Length_Out          => SDMA_tx_length_i,                -- O (31:0)
        Length_Load         => SDMA_TX_Length_Load,             -- I
        DEC1                => SDMA_TX_AddrLen_INC1,            -- I           
        DEC2                => SDMA_TX_AddrLen_INC2,            -- I
        DEC3                => SDMA_TX_AddrLen_INC3,            -- I
        DEC4                => SDMA_TX_AddrLen_INC4             -- I
    );

-------------------------------------------------------------------------------
-- Receive Address Register
-------------------------------------------------------------------------------
RX_ADDR_REG : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst='1' or rx_datapath_rst='1') then
                SDMA_RX_Address_Reg <= (others => '0');
            else
                if (SDMA_RX_Address_Load='1') then
                    SDMA_RX_Address_Reg <= SDMA_RegFile_DO;
                end if;
            end if;
        end if;
    end process RX_ADDR_REG;
   
-------------------------------------------------------------------------------
-- Receive Address Counter
-------------------------------------------------------------------------------
COMP_RX_ADDRESS_COUNTER : entity mpmc_v6_03_a.sdma_address_counter
    PORT MAP (
        LLink_Clk       => LLink_Clk,                 
        LLink_Rst       => rx_datapath_rst,           
        Address_In      => SDMA_RegFile_DO,           
        Address_Out     => SDMA_rx_address_i,         
        Address_Load    => SDMA_RX_Address_Load,      
        INC1            => SDMA_RX_AddrLen_INC1,         
        INC2            => SDMA_RX_AddrLen_INC2,      
        INC3            => SDMA_RX_AddrLen_INC3,      
        INC4            => SDMA_RX_AddrLen_INC4       
    );

-------------------------------------------------------------------------------
-- Receive Length Counter
-------------------------------------------------------------------------------
COMP_RX_LENGTH_COUNTER : entity mpmc_v6_03_a.sdma_length_counter
    PORT MAP (
        LLink_Clk       => LLink_Clk,                
        LLink_Rst       => rx_datapath_rst,          
        Length_In       => SDMA_RegFile_DO,          
        Length_Out      => SDMA_rx_length_i,         
        Length_Load     => SDMA_RX_Length_Load,      
        DEC1            => SDMA_RX_AddrLen_INC1,        
        DEC2            => SDMA_RX_AddrLen_INC2,     
        DEC3            => SDMA_RX_AddrLen_INC3,     
        DEC4            => SDMA_RX_AddrLen_INC4      
    );


-------------------------------------------------------------------------------
-- Transmit Byte Shifter
-------------------------------------------------------------------------------
COMP_TX_BYTE_SHIFTER : entity mpmc_v6_03_a.sdma_tx_byte_shifter
    port map (
        -- Global Inputs
        LLink_Clk       => LLink_Clk,                    
        LLink_Rst       => tx_datapath_rst,              

        -- Byte Shifter Control Signals
        Byte_Sel0       => SDMA_TX_Shifter_Byte_Sel0,    
        Byte_Sel1       => SDMA_TX_Shifter_Byte_Sel1,    
        Byte_Sel2       => SDMA_TX_Shifter_Byte_Sel2,    
        Byte_Sel3       => SDMA_TX_Shifter_Byte_Sel3,    
        Byte_Reg_CE     => SDMA_TX_Shifter_Byte_Reg_CE,  
        
        -- Data Inputs
        Port_RdData     => PI_rdData,                    
        
        -- Data Output
        Port_TX_Out     => TX_D                          
    );
   
-------------------------------------------------------------------------------
-- Recieve Byte Shifter
-------------------------------------------------------------------------------
COMP_RX_BYTE_SHIFTER : entity mpmc_v6_03_a.sdma_RX_Byte_Shifter
    port map (
        -- Global Inputs
        LLink_Clk       => LLink_Clk,                     
        LLink_Rst       => rx_datapath_rst,               
      
        -- Control Inputs
        HoldReg_CE      => SDMA_RX_Shifter_HoldReg_CE,    
        Byte_Sel        => SDMA_RX_Shifter_Byte_Sel,      
        CE              => SDMA_RX_Shifter_CE,            
      
        -- Data Inputs
        Rx_DataIn       => RX_D,                          
      
        -- Data Outputs
        WrDataBus_Pos   => PI_WrFIFO_Data_i(63 downto 32),
        WrDataBus_Neg   => PI_WrFIFO_Data_i(31 downto 0)  
    );

-------------------------------------------------------------------------------
-- Mux Status Register Outputs with RX Byte Shifter Data
-------------------------------------------------------------------------------
PI_WRFIFO_MUX : process(SDMA_Sel_Status_Writeback, PI_WrFIFO_Data_i, 
                        SDMA_TX_Status_Out_Mem, SDMA_RX_Status_Out_Mem)
    begin
        case SDMA_Sel_Status_Writeback is
            when "00" => 
                PI_WrFIFO_Data_UpperByte <= PI_WrFIFO_Data_i(31 downto 24);
            when "01" => 
                PI_WrFIFO_Data_UpperByte <= PI_WrFIFO_Data_i(31 downto 24);
            when "10" => 
--                PI_WrFIFO_Data_UpperByte <= SDMA_TX_Status_Out_Mem(31 downto 24); --GAB
                PI_WrFIFO_Data_UpperByte <= SDMA_TX_Status_Out_Mem(0 to 7);
            when "11" => 
--                PI_WrFIFO_Data_UpperByte <= SDMA_RX_Status_Out_Mem(31 downto 24); --GAB
                PI_WrFIFO_Data_UpperByte <= SDMA_RX_Status_Out_Mem(0 to 7);
            when others =>  
                PI_WrFIFO_Data_UpperByte <= (others => '0');
        end case;
    end process PI_WRFIFO_MUX;



-------------------------------------------------------------------------------
--  Write datapath for 32 bit npi width
-------------------------------------------------------------------------------

             
------------------------------------------
-- Mux for data output
-----------------------------------------

PI_WrFIFO_Data_Reorder(0 to 31) 
		<= PI_WrFIFO_Data_i (63 downto 32) when wrDataAck_Pos = '1'
		else PI_WrFIFO_Data_UpperByte & PI_WrFIFO_Data_i(23 downto 0); 

WR_BYTE_SWAP : process(PI_WrFIFO_Data_Reorder)
    begin
        for i in 0 to 3 loop 
            PI_WrFIFO_Data((i*8)+7 downto (i*8)) <= PI_WrFIFO_Data_Reorder((i*8) to (i*8)+7);
        end loop;
end process WR_BYTE_SWAP;

-------------------------------------------------------------------------------
--  Write datapath for 64 bit npi width ( remove comment marks and add generates to add 64-bit functionality)
-------------------------------------------------------------------------------
--WR_HIGH_WORD : process(LLink_Clk)
--    begin
--        if(LLink_Clk'EVENT and LLink_Clk='1')then
--            if (LLink_Rst='1') then
--                PI_WrFIFO_Data_Reorder(0 to 31) <= (others => '0');
--            elsif (wrDataAck_Pos='1') then
--                PI_WrFIFO_Data_Reorder(0 to 31) <= PI_WrFIFO_Data_i(63 downto 32);
--            end if;
--        end if;
--    end process WR_HIGH_WORD;
--   
--WR_LOW_WORD : process(PI_WrFIFO_Data_UpperByte, PI_WrFIFO_Data_i)
--    begin
--        PI_WrFIFO_Data_Reorder(32 to 63) <= PI_WrFIFO_Data_UpperByte 
--                                          & PI_WrFIFO_Data_i(23 downto 0);
--end process WR_LOW_WORD;

-- Byte reordering within write data bus
--WR_BYTE_SWAP : process(PI_WrFIFO_Data_Reorder)
--    begin
--        for i in 0 to 7 loop 
--            PI_WrFIFO_Data((i*8)+7 downto (i*8)) <= PI_WrFIFO_Data_Reorder((i*8) to (i*8)+7);
--        end loop;
--end process WR_BYTE_SWAP;




end implementation;
