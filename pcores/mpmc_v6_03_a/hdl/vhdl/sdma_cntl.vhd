---------------------------------------------------------------------------
-- sdma_cntl
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
-- Filename:          sdma_cntl.vhd
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
--  - Changed DCR slave interface to PLB v4.6
--  - Modified interrupt coalescing functionality
-- ^^^^^^
--  GAB     5/12/07
-- ~~~~~~
--  - Re-Qualified pi_rdfifo_flush with the active channel qualifier to fix
--  an issue when one channel detected and error.  This caused the rdfifo
--  to be flushed thus corrupting the other channels operations.
-- ^^^^^^
--  GAB     8/13/07
-- ~~~~~~
--  - Modified rx and tx start mechanism to prevent race condition where
--  tail pointer update could be missed if it occurred on the same clock
--  cycle as a stop condition was detected.
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
entity sdma_cntl is
    generic(
        C_COMPLETED_ERR_TX          : integer := 1                              ;            
        C_COMPLETED_ERR_RX          : integer := 1                              ;
        C_PI_BASEADDR               : std_logic_vector(0 to 31):= X"FFFFFFFF"   ;
        C_PI_HIGHADDR               : std_logic_vector(0 to 31):= X"00000000"   ;
        C_INSTANTIATE_TIMER_TX      : integer := 1                              ;
        C_INSTANTIATE_TIMER_RX      : integer := 1                              ;
        C_PRESCALAR                 : integer := 1023                           ;
        C_RX_TIMEOUT_PERIOD         : std_logic_vector(0 to 3) :="0100"         ;
        C_PI_RDDATA_DELAY           : integer := 0                              ;
        C_PI2LL_CLK_RATIO           : integer := 1                              ;
        C_NUM_CE                    : integer := 17                             ;
        C_SPLB_AWIDTH               : integer range 32 to 32    := 32           ;
        C_SPLB_NATIVE_DWIDTH        : integer range 32 to 32    := 32           ;
        C_FAMILY                    : string := "virtex5"
    );
    port(
        -- Global Signals
        LLink_Clk                                 : in  std_logic                     ;
        LLink_Rst                                 : in  std_logic                     ;

        -- IPIC Interface
        Bus2IP_Clk                          : in  std_logic                     ;
        Bus2IP_Reset                        : in  std_logic                     ;
        Bus2IP_CS                           : in  std_logic                     ;
        Bus2IP_RNW                          : in  std_logic                     ;
        Bus2IP_Addr                         : in  std_logic_vector
                                                (0 to C_SPLB_AWIDTH - 1 )       ;
        Bus2IP_Data                         : in  std_logic_vector
                                                (0 to C_SPLB_NATIVE_DWIDTH - 1 );  
        Bus2IP_RdCE                         : in  std_logic_vector
                                                (0 to C_NUM_CE-1)               ;
        Bus2IP_WrCE                         : in std_logic_vector
                                                (0 to C_NUM_CE-1)               ;
        IP2Bus_Data                         : out std_logic_vector
                                                (0 to C_SPLB_NATIVE_DWIDTH - 1 ); 
        IP2Bus_WrAck                        : out std_logic                     ;
        IP2Bus_RdAck                        : out std_logic                     ;

        -- MPMC Port Interface                                                  
        PI_Addr                             : out std_logic_vector(31 downto 0) ;
        PI_AddrReq                          : out std_logic                     ;
        PI_AddrAck                          : in  std_logic                     ;
        PI_RdModWr                          : out std_logic                     ;
        PI_RNW                              : out std_logic                     ;
        PI_Size                             : out std_logic_vector(3 downto 0)  ;
        PI_WrFIFO_BE                        : out std_logic_vector(3 downto 0)  ;
        PI_WrFIFO_Push                      : out std_logic                     ;
        PI_RdFIFO_Pop                       : out std_logic                     ;
        PI_RdFIFO_RdWdAddr                  : in  std_logic_vector(3 downto 0)  ;
        PI_WrFIFO_AlmostFull                : in  std_logic                     ;
        PI_WrFIFO_Empty                     : in  std_logic                     ;
        PI_WrFIFO_Flush                     : out std_logic                     ;
        PI_RdFIFO_DataAvailable             : in  std_logic                     ;
        PI_RdFIFO_Empty                     : in  std_logic                     ;
        PI_RdFIFO_Flush                     : out std_logic                     ;

        -- TX Local Link Interface                                              
        TX_Rem                              : out std_logic_vector(3 downto 0)  ;
        TX_SOF                              : out std_logic                     ;
        TX_EOF                              : out std_logic                     ;
        TX_SOP                              : out std_logic                     ;
        TX_EOP                              : out std_logic                     ;
        TX_Src_Rdy                          : out std_logic                     ;
        TX_Dst_Rdy                          : in  std_logic                     ;

        -- RX Local Link Interface                                              
        RX_Rem                              : in  std_logic_vector(3 downto 0)  ;
        RX_SOF                              : in  std_logic                     ;
        RX_EOF                              : in  std_logic                     ;
        RX_SOP                              : in  std_logic                     ;
        RX_EOP                              : in  std_logic                     ;
        RX_Src_Rdy                          : in  std_logic                     ;
        RX_Dst_Rdy                          : out std_logic                     ;

        -- CPU Interrupt Signal                                                 
        SDMA_Rx_IntOut                      : out std_logic                     ;
        SDMA_Tx_IntOut                      : out std_logic                     ;
        
        -- DATAPATH CONTROL SIGNALS                                             
        -- DCR Data Buses                                                       
        IPIC_WrDBus                         : out std_logic_vector(0 to 31)     ;
        IPIC_RdDBus                         : in  std_logic_vector(0 to 31)     ;
        -- Data Bus Select Signals                                              
        SDMA_Sel_AddrLen                    : out std_logic_vector(1 downto 0)  ;
        SDMA_Sel_Data_Src                   : out std_logic_vector(1 downto 0)  ;
        SDMA_Sel_PI_rdData_Pos              : out std_logic_vector(3 downto 0)  ;
        SDMA_Sel_Status_Writeback           : out std_logic_vector(1 downto 0)  ;
        -- Register File Controls                                                   
        SDMA_RegFile_WE                     : out std_logic                     ;
        SDMA_RegFile_Sel_Eng                : out std_logic                     ;
        SDMA_RegFile_Sel_Reg                : out std_logic_vector(2 downto 0)  ;

        -- Counter Signals                                                          
        SDMA_TX_Address                     : in  std_logic_vector(31 downto 0) ;
        SDMA_TX_Address_Load                : out std_logic                     ;
        SDMA_TX_Length                      : in  std_logic_vector(31 downto 0) ;
        SDMA_TX_Length_Load                 : out std_logic                     ;
        SDMA_TX_AddrLen_INC1                : out std_logic                     ;
        SDMA_TX_AddrLen_INC2                : out std_logic                     ;
        SDMA_TX_AddrLen_INC3                : out std_logic                     ;
        SDMA_TX_AddrLen_INC4                : out std_logic                     ;

        SDMA_RX_Address                     : in  std_logic_vector(31 downto 0) ;
        SDMA_RX_Address_Reg                 : in  std_logic_vector(31 downto 0) ;
        SDMA_RX_Address_Load                : out std_logic                     ;
        SDMA_RX_Length                      : in  std_logic_vector(31 downto 0) ;
        SDMA_RX_Length_Load                 : out std_logic                     ;
        SDMA_RX_AddrLen_INC1                : out std_logic                     ;
        SDMA_RX_AddrLen_INC2                : out std_logic                     ;
        SDMA_RX_AddrLen_INC3                : out std_logic                     ;
        SDMA_RX_AddrLen_INC4                : out std_logic                     ;
        -- TX Status Register Signals                                               
        SDMA_TX_Status_Detect_Busy_Wr       : out std_logic                     ;
        SDMA_TX_Status_Detect_Tail_Ptr_Err  : out std_logic                     ;
        SDMA_TX_Status_Detect_Curr_Ptr_Err  : out std_logic                     ;
        SDMA_TX_Status_Detect_Nxt_Ptr_Err   : out std_logic                     ;
        SDMA_TX_Status_Detect_Addr_Err      : out std_logic                     ;
        SDMA_TX_Status_Detect_Completed_Err : out std_logic                     ;
        SDMA_TX_Status_Set_SDMA_Completed :     out std_logic                     ;
        SDMA_TX_Status_SetBusy              : out std_logic                     ;
        SDMA_TX_Status_Detect_Stop          : out std_logic                     ;
        SDMA_TX_Status_Detect_Null_Ptr      : out std_logic                     ;
        SDMA_TX_Status_Mem_CE               : out std_logic                     ;
        SDMA_TX_Status_Out                  : in  std_logic_vector(0 to 31) ;
        -- RX Status Register Signals                                               
        SDMA_RX_Status_Detect_Busy_Wr       : out std_logic                     ;
        SDMA_RX_Status_Detect_Tail_Ptr_Err  : out std_logic                     ;
        SDMA_RX_Status_Detect_Curr_Ptr_Err  : out std_logic                     ;
        SDMA_RX_Status_Detect_Nxt_Ptr_Err   : out std_logic                     ;
        SDMA_RX_Status_Detect_Addr_Err      : out std_logic                     ;
        SDMA_RX_Status_Detect_Completed_Err : out std_logic                     ;
        SDMA_RX_Status_Set_SDMA_Completed   : out std_logic                     ;
        SDMA_RX_Status_Set_Start_Of_Packet  : out std_logic                     ;
        SDMA_RX_Status_Set_End_Of_Packet    : out std_logic                     ;
        SDMA_RX_Status_SetBusy              : out std_logic                     ;
        SDMA_RX_Status_Detect_Stop          : out std_logic                     ;
        SDMA_RX_Status_Detect_Null_Ptr      : out std_logic                     ;
        SDMA_RX_Status_Mem_CE               : out std_logic                     ;
        SDMA_RX_Status_Out                  : in  std_logic_vector(0 to 31) ;

        -- TailPointer Mode Support
        SDMA_TX_CurDesc_Ptr                 : in  std_logic_vector(0 to 31) ;
        SDMA_TX_TailDesc_Ptr                : in  std_logic_vector(0 to 31) ;
        SDMA_RX_CurDesc_Ptr                 : in  std_logic_vector(0 to 31) ;
        SDMA_RX_TailDesc_Ptr                : in  std_logic_vector(0 to 31) ;

        -- Channel Reset Signals                                                    
        SDMA_TX_ChannelRST                  : in  std_logic                     ;
        SDMA_RX_ChannelRST                  : in  std_logic                     ;
        ResetComplete                       : out std_logic                     ;
        SDMA_RX_Error_Reset                 : in  std_logic                     ;
        SDMA_TX_Error_Reset                 : in  std_logic                     ;
        SDMA_Ext_Reset                      : out std_logic                     ;
        -- TX Byte Shifter Controls                                                 
        SDMA_TX_Shifter_Byte_Sel0           : out std_logic_vector(1 downto 0)  ;
        SDMA_TX_Shifter_Byte_Sel1           : out std_logic_vector(1 downto 0)  ;
        SDMA_TX_Shifter_Byte_Sel2           : out std_logic_vector(1 downto 0)  ;
        SDMA_TX_Shifter_Byte_Sel3           : out std_logic_vector(1 downto 0)  ;
        SDMA_TX_Shifter_Byte_Reg_CE         : out std_logic_vector(3 downto 0)  ;
        -- RX Byte Shifter Controls                                                 
        SDMA_RX_Shifter_HoldReg_CE          : out std_logic                     ;
        SDMA_RX_Shifter_Byte_Sel            : out std_logic_vector(1 downto 0)  ;
        SDMA_RX_Shifter_CE                  : out std_logic_vector(7 downto 0)  ;

        IPIC_Control_Reg_WE                 : out std_logic                     ;
        IPIC_Control_Reg_RE                 : out std_logic                     ;
        IPIC_TX_Sts_Reg_RE                  : out std_logic                     ;
        IPIC_RX_Sts_Reg_RE                  : out std_logic                     ;
        IPIC_TX_Cntl_Reg_WE                 : out std_logic                     ;
        IPIC_RX_Cntl_Reg_WE                 : out std_logic                     ;
        IPIC_TX_TailPtr_Reg_WE              : out std_logic                     ;
        IPIC_RX_TailPtr_Reg_WE              : out std_logic                     ;
        SDMA_TX_Control_Reg                 : in  std_logic_vector(0 to 31)     ;
        SDMA_RX_Control_Reg                 : in  std_logic_vector(0 to 31)     ;
        SDMA_Control_Reg                    : in  std_logic_vector(0 to 31)     ;
        --32-bit signals
         d_reg_ce				: out std_logic;
        -- Additional Datapath Signals                                          
        wrDataAck_Pos                       : out std_logic                     ;
        wrDataAck_Neg                       : out std_logic                     ;
        rdDataAck_Pos                       : out std_logic                     ;
        rdDataAck_Neg                       : out std_logic                     ;
        delay_reg_ce                        : out std_logic                     ;
        delay_reg_sel                       : out std_logic_vector(1 downto 0)
    );
end sdma_cntl;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_cntl is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
-- Reordering Signals
signal PI_WrFIFO_BE_Reorder                     : std_logic_vector(0 to 3);

-- Delayed Read Data Signals
signal PI_RdFIFO_Pop_i                          : std_logic;
signal PI_RdFIFO_Empty_i                        : std_logic;

-- Status Register Signals  
signal TX_Error                                 : std_logic;
signal RX_Error                                 : std_logic;
signal TX_IntOnEnd                              : std_logic;
signal RX_IntOnEnd                              : std_logic;
signal TX_StopOnEnd                             : std_logic;
signal RX_StopOnEnd                             : std_logic;
signal TX_Completed                             : std_logic;
signal RX_Completed                             : std_logic;
signal TX_EndOfPacket                           : std_logic;
signal RX_EndOfPacket                           : std_logic;
signal TX_Busy                                  : std_logic;
signal RX_Busy                                  : std_logic;
signal TX_ChannelRSTBit                         : std_logic;
signal RX_ChannelRSTBit                         : std_logic;

signal PI_Valid_Address                         : std_logic;

-- DCR Interface Signals    
signal ipic_tx_int_reg_we                       : std_logic;
signal ipic_rx_int_reg_we                       : std_logic;
signal ipic_tx_int_reg_re                       : std_logic;
signal ipic_rx_int_reg_re                       : std_logic;


signal ipic_rddbus_in                           : std_logic_vector(31 downto 0);

-- RegFile Arbiter Signals  
signal ipic_regfile_request                      : std_logic;
signal ipic_regfile_busy                         : std_logic;
signal ipic_regfile_grant                        : std_logic;
signal TX_RegFile_Request                       : std_logic;
signal TX_RegFile_Busy                          : std_logic;
signal TX_RegFile_Grant                         : std_logic;
signal RX_RegFile_Request                       : std_logic;
signal RX_RegFile_Busy                          : std_logic;
signal RX_RegFile_Grant                         : std_logic;
signal RegFile_Grant_Hold                       : std_logic_vector(2 downto 0);

-- RegFile Muxed Datapath Signals
--signal SDMA_Sel_AddrLen                        : std_logic_vector(1 downto 0);
--signal SDMA_Sel_Data_Src                       : std_logic_vector(1 downto 0);
--signal SDMA_RegFile_WE                         : std_logic;      
--signal SDMA_RegFile_Sel_Eng                    : std_logic_vector(1 downto 0);
--signal SDMA_RegFile_Sel_Reg                    : std_logic_vector(1 downto 0);

signal ipic_sel_addrlen                         : std_logic_vector(1 downto 0); 
signal ipic_sel_data_src                        : std_logic_vector(1 downto 0); 
signal ipic_regfile_we                          : std_logic;       
signal ipic_regfile_sel_eng                     : std_logic; 
signal ipic_regfile_sel_reg                     : std_logic_vector(2 downto 0); 

signal SDMA_TX_Sel_AddrLen                     : std_logic_vector(1 downto 0); 
signal SDMA_TX_Sel_Data_Src                    : std_logic_vector(1 downto 0); 
signal SDMA_TX_RegFile_WE                      : std_logic;       
signal SDMA_TX_RegFile_Sel_Eng                 : std_logic; 
signal SDMA_TX_RegFile_Sel_Reg                 : std_logic_vector(2 downto 0); 

signal SDMA_RX_Sel_AddrLen                     : std_logic_vector(1 downto 0); 
signal SDMA_RX_Sel_Data_Src                    : std_logic_vector(1 downto 0); 
signal SDMA_RX_RegFile_WE                      : std_logic;       
signal SDMA_RX_RegFile_Sel_Eng                 : std_logic; 
signal SDMA_RX_RegFile_Sel_Reg                 : std_logic_vector(2 downto 0); 

-- Port Arbiter Signals
signal TX_Addr_Request                          : std_logic;
signal TX_Addr_Grant                            : std_logic;
signal TX_Addr_Busy                             : std_logic;
signal TX_Addr_Control                          : std_logic;
signal RX_Addr_Request                          : std_logic;
signal RX_Addr_Grant                            : std_logic;
signal RX_Addr_Busy                             : std_logic;

signal TX_Timeout                               : std_logic;
signal RX_Timeout                               : std_logic;

signal TX_Read_Port_Request                     : std_logic;
signal TX_Read_Port_Grant                       : std_logic;
signal TX_Read_Port_Busy                        : std_logic;
signal RX_Read_Port_Request                     : std_logic;
signal RX_Read_Port_Grant                       : std_logic;
signal RX_Read_Port_Busy                        : std_logic;
signal PI_Read_Port_TX_Active                   : std_logic;

signal TX_Write_Port_Request                    : std_logic;
signal TX_Write_Port_Grant                      : std_logic;
signal TX_Write_Port_Busy                       : std_logic;
signal RX_Write_Port_Request                    : std_logic;
signal RX_Write_Port_Grant                      : std_logic;
signal RX_Write_Port_Busy                       : std_logic;
signal PI_Write_Port_TX_Active                  : std_logic;

-- Port Arbiter Muxed Signals
signal SDMA_TX_Sel_Status_Writeback            : std_logic_vector(1 downto 0); 
signal SDMA_RX_Sel_Status_Writeback            : std_logic_vector(1 downto 0); 
signal SDMA_TX_Sel_rdData_Pos                  : std_logic_vector(3 downto 0); 
signal SDMA_RX_Sel_rdData_Pos                  : std_logic_vector(3 downto 0); 
                                   
-- TX Port Interface               
signal TX_AddrReq                               : std_logic;
signal TX_AddrAck                               : std_logic;
signal TX_Addr                                  : std_logic_vector(31 downto 0);
signal TX_RNW                                   : std_logic;  
signal TX_Size                                  : std_logic_vector(3 downto 0); 
signal TX_WrFIFO_BE                             : std_logic_vector(3 downto 0); 
signal TX_WrFIFO_Push                           : std_logic;  
signal TX_RdFIFO_Pop                            : std_logic;  
signal TX_RdFIFO_RdWdAddr                       : std_logic_vector(3 downto 0); 
signal TX_WrFIFO_AlmostFull                     : std_logic;
signal TX_WrFIFO_Flush                          : std_logic;
signal TX_RdFIFO_DataAvailable                  : std_logic;
signal TX_RdFIFO_Empty                          : std_logic;
signal TX_RdFIFO_Flush                          : std_logic;

-- TX Data Handler Signals          
signal TX_CL8R_Start                            : std_logic;
signal TX_CL8R_Comp                             : std_logic;
signal TX_B16R_Start                            : std_logic;
signal TX_B16R_Comp                             : std_logic;
signal TX_RdPop                                 : std_logic;
signal TX_CL8W_Start                            : std_logic;
signal TX_CL8W_Comp                             : std_logic;
signal TX_RdHandlerRST                          : std_logic;
signal TX_Payload                               : std_logic;

-- TX State Control Signals         
signal TX_CL8R                                  : std_logic;
signal TX_B16R                                  : std_logic;
signal TX_CL8W                                  : std_logic;
signal TX_Channel_Read_Desc_Done                : std_logic;
signal TX_Channel_Data_Done                     : std_logic;
signal TX_Channel_Continue                      : std_logic;
signal TX_Channel_Stop                          : std_logic;

-- RX Port Interface
signal RX_AddrReq                               : std_logic;
signal RX_AddrAck                               : std_logic;
signal RX_Addr                                  : std_logic_vector(31 downto 0);
signal rx_rdmodwr                               : std_logic;
signal RX_RNW                                   : std_logic;      
signal RX_Size                                  : std_logic_vector(3 downto 0); 
signal RX_WrFIFO_BE                             : std_logic_vector(3 downto 0); 
signal RX_WrFIFO_Push                           : std_logic;      
signal RX_RdFIFO_Pop                            : std_logic;      
signal RX_RdFIFO_RdWdAddr                       : std_logic_vector(3 downto 0); 
signal RX_WrFIFO_AlmostFull                     : std_logic;
signal RX_WrFIFO_Flush                          : std_logic;
signal RX_RdFIFO_DataAvailable                  : std_logic;
signal RX_RdFIFO_Empty                          : std_logic;
signal RX_RdFIFO_Flush                          : std_logic;

-- RX Data Handler Signals      
signal RX_CL8R_Start                            : std_logic;
signal RX_CL8R_Comp                             : std_logic;
signal RX_RdPop                                 : std_logic;
signal RX_B16W_Start                            : std_logic;
signal RX_B16W_Comp                             : std_logic;
signal RX_CL8W_Start                            : std_logic;
signal RX_CL8W_Comp                             : std_logic;
signal RX_Payload                               : std_logic;
signal RX_Footer                                : std_logic;
signal RX_RdHandlerRST                          : std_logic;
signal RX_WrHandlerForce                        : std_logic;
signal RX_Rem_Limiting                          : std_logic;

-- RX State Control Signals     
signal RX_CL8R                                  : std_logic;
signal RX_B16W                                  : std_logic;
signal RX_CL8W                                  : std_logic;
signal RX_Channel_Read_Desc_Done                : std_logic;
signal RX_Channel_Data_Done                     : std_logic;
signal RX_Channel_Continue                      : std_logic;
signal RX_Channel_Stop                          : std_logic;

-- Additional Datapath Signals  
--signal rdDataAck_Pos                : std_logic;
--signal rdDataAck_Neg                : std_logic;
signal TX_rdDataAck_Pos                         : std_logic;
signal TX_rdDataAck_Neg                         : std_logic;
signal RX_rdDataAck_Pos                         : std_logic;
signal RX_rdDataAck_Neg                         : std_logic;

signal wrDataBE_Pos                             : std_logic_vector(3 downto 0);  
signal wrDataBE_Pos_i                           : std_logic_vector(3 downto 0); 
signal wrDataBE_Neg                             : std_logic_vector(3 downto 0);  
--signal wrDataAck_Pos                            : std_logic;       
--signal wrDataAck_Neg                            : std_logic;       
signal TX_wrDataBE_Pos                          : std_logic_vector(3 downto 0);  
signal TX_wrDataBE_Neg                          : std_logic_vector(3 downto 0);  
signal TX_wrDataAck_Pos                         : std_logic;       
signal TX_wrDataAck_Neg                         : std_logic;       
signal RX_wrDataBE_Pos                          : std_logic_vector(3 downto 0);  
signal RX_wrDataBE_Neg                          : std_logic_vector(3 downto 0);  
signal RX_wrDataAck_Pos                         : std_logic;       
signal RX_wrDataAck_Neg                         : std_logic;       



signal SDMA_cl8r_start                         : std_logic;
signal SDMA_b16r_start                         : std_logic;
signal tx_cl8r_i                                : std_logic;
signal tx_state_rst                             : std_logic;
signal rx_state_rst                             : std_logic;
signal rx_timeout_i                             : std_logic;

signal tx_src_rdy_i                             : std_logic;
signal tx_eof_i                                 : std_logic;
signal tx_sof_i                                 : std_logic;
signal rx_dst_rdy_i                             : std_logic;

signal SDMA_tx_status_detect_busy_wr_i         : std_logic;
signal SDMA_tx_status_detect_curr_ptr_err_i    : std_logic;
signal SDMA_tx_status_detect_nxt_ptr_err_i     : std_logic;
signal SDMA_tx_status_detect_addr_err_i        : std_logic;
signal SDMA_tx_status_detect_completed_err_i   : std_logic;
signal SDMA_rx_status_detect_busy_wr_i         : std_logic;
signal SDMA_rx_status_detect_curr_ptr_err_i    : std_logic;
signal SDMA_rx_status_detect_nxt_ptr_err_i     : std_logic;
signal SDMA_rx_status_detect_addr_err_i        : std_logic;
signal SDMA_rx_status_detect_completed_err_i   : std_logic;
signal SDMA_tx_status_write_curr_ptr_i         : std_logic;
signal SDMA_rx_status_write_curr_ptr_i         : std_logic;

signal SDMA_tx_status_write_tail_ptr_i         : std_logic;
signal SDMA_rx_status_write_tail_ptr_i         : std_logic;
signal SDMA_tx_status_detect_tail_ptr_err_i    : std_logic;
signal SDMA_rx_status_detect_tail_ptr_err_i    : std_logic;

signal ipic_wrdbus_i                             : std_logic_vector(0 to 31);
signal tx_end_i                                 : std_logic;
signal rx_end_i                                 : std_logic;
signal pi_rnw_i                                 : std_logic                     ;
signal pi_size_i                                : std_logic_vector(3 downto 0)  ;
signal rddataack_pos_i                          : std_logic;
signal rddataack_neg_i                          : std_logic;
signal wrdataack_neg_i                          : std_logic;
signal wrdataack_pos_i                          : std_logic;
signal tx_start                                 : std_logic;
signal rx_start                                 : std_logic;

signal tx_irq_reg                               : std_logic_vector(0 to 31);
signal rx_irq_reg                               : std_logic_vector(0 to 31);
signal tailpntrmode                             : std_logic;

signal tx_rst_cmplt                             : std_logic;
signal rx_rst_cmplt                             : std_logic; 
signal regfilerstdone                           : std_logic;
--signal rx_portcntrl_rstout                      : std_logic;
--signal tx_portcntrl_rstout                      : std_logic;
signal ipic_tx_cntl_reg_we_i                    : std_logic;
signal ipic_rx_cntl_reg_we_i                    : std_logic;
signal resetcomplete_i                          : std_logic;

signal rx_channel_reset                         : std_logic;
signal tx_channel_reset                         : std_logic;
signal system_busy                              : std_logic;
signal tx_busy_write                            : std_logic;
signal rx_busy_cache_write                      : std_logic;
signal rx_busy_burst_write                      : std_logic;

signal rx_isidle_reset                          : std_logic;
signal sdma_rx_status_detect_null_ptr_i         : std_logic;
signal sdma_tx_status_detect_null_ptr_i         : std_logic;
signal SDMA_RX_Address_Load_i			: std_logic;
signal extra_d_reg_ce				: std_logic;
signal RX_wr_push_32bit				: std_logic;
signal TX_wr_push_32bit				: std_logic;
signal Wr_push_32bit				: std_logic;
signal tx_desc_update_o				: std_logic;
signal ground				: std_logic;
signal PI_RdFIFO_Pop_32_bit		: std_logic ;
-- mgg added above signal to make seperate 32 bit pop signal
signal WrPushCount_o				: std_logic_vector(4 downto 0);
-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

GEN_d_reg_ce_delay2 : if ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) generate
          
     d_reg_ce <=    rdDataAck_Neg_i; -- or extra_d_reg_ce;
end generate;

GEN_d_reg_ce_delay1 : if (((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) 
                        or ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))) generate
   
   d_reg_ce <=    rdDataAck_Pos_i;
   
end generate;



GEN_d_reg_ce_delay0 : if not((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) 
                  and not(((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) 
                  or      ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))) generate
 d_reg_ce <=    rdDataAck_Neg_i;
 
end generate;

ground <='0';
SDMA_RX_Address_Load <= SDMA_RX_Address_Load_i;
TX_Src_Rdy      <= tx_src_rdy_i;
TX_EOF          <= tx_eof_i;
TX_SOF          <= tx_sof_i;
RX_Dst_Rdy      <= rx_dst_rdy_i;

SDMA_TX_Status_Detect_Busy_Wr          <= SDMA_tx_status_detect_busy_wr_i;
SDMA_TX_Status_Detect_Tail_Ptr_Err     <= SDMA_tx_status_detect_tail_ptr_err_i;
SDMA_TX_Status_Detect_Curr_Ptr_Err     <= SDMA_tx_status_detect_curr_ptr_err_i; 
SDMA_TX_Status_Detect_Nxt_Ptr_Err      <= SDMA_tx_status_detect_nxt_ptr_err_i;  
SDMA_TX_Status_Detect_Addr_Err         <= SDMA_tx_status_detect_addr_err_i;     
SDMA_TX_Status_Detect_Completed_Err    <= SDMA_tx_status_detect_completed_err_i;
SDMA_RX_Status_Detect_Busy_Wr          <= SDMA_rx_status_detect_busy_wr_i;      
SDMA_RX_Status_Detect_Tail_Ptr_Err     <= SDMA_rx_status_detect_tail_ptr_err_i;
SDMA_RX_Status_Detect_Curr_Ptr_Err     <= SDMA_rx_status_detect_curr_ptr_err_i; 
SDMA_RX_Status_Detect_Nxt_Ptr_Err      <= SDMA_rx_status_detect_nxt_ptr_err_i;  
SDMA_RX_Status_Detect_Addr_Err         <= SDMA_rx_status_detect_addr_err_i;     
SDMA_RX_Status_Detect_Completed_Err    <= SDMA_rx_status_detect_completed_err_i;

SDMA_RX_Status_Detect_Null_Ptr         <= sdma_rx_status_detect_null_ptr_i;
SDMA_TX_Status_Detect_Null_Ptr         <= sdma_tx_status_detect_null_ptr_i;

--SDMA_TX_Status_Write_Curr_Ptr          <= SDMA_tx_status_write_curr_ptr_i; --for setting busy is status
--SDMA_RX_Status_Write_Curr_Ptr          <= SDMA_rx_status_write_curr_ptr_i; --for setting busy is status
--SDMA_TX_Status_SetBusy                 <= SDMA_tx_status_write_curr_ptr_i when tailpntrmode = '0'
--                                      else SDMA_tx_status_write_tail_ptr_i;

--SDMA_RX_Status_SetBusy                 <= SDMA_rx_status_write_curr_ptr_i when tailpntrmode = '0'
--                                      else SDMA_rx_status_write_tail_ptr_i;

SDMA_RX_Status_SetBusy                  <= rx_start;
SDMA_TX_Status_SetBusy                  <= tx_start;

IPIC_WrDBus         <= ipic_wrdbus_i;
PI_RNW              <= pi_rnw_i;             
PI_Size             <= pi_size_i;
rdDataAck_Pos       <= rddataack_pos_i;
rdDataAck_neg       <= rddataack_neg_i;
wrDataAck_Neg       <= wrdataack_neg_i;

wrDataAck_Pos       <= wrdataack_pos_i;
       
IPIC_TX_Cntl_Reg_WE     <= ipic_tx_cntl_reg_we_i;
IPIC_RX_Cntl_Reg_WE     <= ipic_rx_cntl_reg_we_i;
IPIC_TX_TailPtr_Reg_WE  <= SDMA_tx_status_write_tail_ptr_i;
IPIC_RX_TailPtr_Reg_WE  <= SDMA_rx_status_write_tail_ptr_i;

-------------------------------------------------------------------------------
-- Status Register Signals   
-------------------------------------------------------------------------------
TX_Error <= SDMA_TX_Status_Out(CHNL_STS_ERROR_BIT); 
--            or SDMA_tx_status_detect_busy_wr_i  
--            or SDMA_tx_status_detect_curr_ptr_err_i 
--            or SDMA_tx_status_detect_nxt_ptr_err_i 
--            or SDMA_tx_status_detect_addr_err_i 
--            or SDMA_tx_status_detect_completed_err_i;

RX_Error <= SDMA_RX_Status_Out(CHNL_STS_ERROR_BIT); 
--            or SDMA_rx_status_detect_busy_wr_i  
--            or SDMA_rx_status_detect_curr_ptr_err_i 
--            or SDMA_rx_status_detect_nxt_ptr_err_i 
--            or SDMA_rx_status_detect_addr_err_i 
--            or SDMA_rx_status_detect_completed_err_i;
            
TX_IntOnEnd         <= SDMA_TX_Status_Out(CHNL_STS_IOE_BIT);
RX_IntOnEnd         <= SDMA_RX_Status_Out(CHNL_STS_IOE_BIT);

TX_StopOnEnd        <= SDMA_TX_Status_Out(CHNL_STS_SOE_BIT);
RX_StopOnEnd        <= SDMA_RX_Status_Out(CHNL_STS_SOE_BIT);

TX_Completed        <= SDMA_TX_Status_Out(CHNL_STS_CMPLT_BIT);
RX_Completed        <= SDMA_RX_Status_Out(CHNL_STS_CMPLT_BIT);

TX_EndOfPacket      <= SDMA_TX_Status_Out(CHNL_STS_EOP_BIT);
RX_EndOfPacket      <= SDMA_RX_Status_Out(CHNL_STS_EOP_BIT);

TX_Busy             <= SDMA_TX_Status_Out(CHNL_STS_ENGBUSY_BIT);
RX_Busy             <= SDMA_RX_Status_Out(CHNL_STS_ENGBUSY_BIT);

TX_ChannelRSTBit    <= SDMA_Control_Reg(DMA_CNTRL_SWRESET_BIT);
RX_ChannelRSTBit    <= SDMA_Control_Reg(DMA_CNTRL_SWRESET_BIT);

tailpntrmode        <= SDMA_Control_Reg(DMA_CNTRL_TAILPTR_BIT);







 
-------------------------------------------------------------------------------
-- System Busy with writes detection    
-------------------------------------------------------------------------------
TX_BUSY_WRITING_PROCESS : process(LLink_clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(tx_channel_reset='1' or TX_CL8W_Comp='1')then
                tx_busy_write <= '0';
            elsif(TX_CL8W_Start='1')then
                tx_busy_write <= '1';
            end if;
        end if;
    end process TX_BUSY_WRITING_PROCESS;

RX_BUSY_WRITING_PROCESS1 : process(LLink_clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(rx_channel_reset='1' or RX_B16W_Comp='1')then
                rx_busy_cache_write <= '0';
            elsif(RX_CL8W_Start='1')then
                rx_busy_cache_write <= '1';
            end if;
        end if;
    end process RX_BUSY_WRITING_PROCESS1;

RX_BUSY_WRITING_PROCESS2 : process(LLink_clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(rx_channel_reset='1' or RX_B16W_Comp='1')then
                rx_busy_burst_write <= '0';
            elsif(RX_B16W_Start='1')then
                rx_busy_burst_write <= '1';
            end if;
        end if;
    end process RX_BUSY_WRITING_PROCESS2;

REG_SYS_BUSY : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            system_busy <= tx_busy_write 
                            or rx_busy_cache_write 
                            or rx_busy_burst_write;
        end if;
    end process REG_SYS_BUSY;

-------------------------------------------------------------------------------
-- Gracefull Reset Logic
-------------------------------------------------------------------------------
TX_RST_COMPLETE: process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk = '1')then
            if(SDMA_TX_ChannelRST='0' or LLink_Rst = '1' or regfilerstdone='0') then
                tx_rst_cmplt <= '0';
            elsif(regfilerstdone='1')then
                tx_rst_cmplt <= '1';
            end if;
        end if;
    end process TX_RST_COMPLETE;


RX_RST_COMPLETE: process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk = '1')then
            if(SDMA_RX_ChannelRST='0' or LLink_Rst = '1' or regfilerstdone='0' ) then
                rx_rst_cmplt <= '0';
            elsif(regfilerstdone='1')then
                rx_rst_cmplt <= '1';
            end if;
        end if;
    end process RX_RST_COMPLETE;

resetcomplete_i <= tx_rst_cmplt and rx_rst_cmplt;
ResetComplete   <= resetcomplete_i;


rx_channel_reset <= LLink_Rst or SDMA_RX_Error_Reset;
tx_channel_reset <= LLink_Rst or SDMA_TX_Error_Reset;
-------------------------------------------------------------------------------
-- Detect Write to Current Descriptor Pointer while Busy or Reseting
-------------------------------------------------------------------------------
SDMA_tx_status_detect_busy_wr_i <= SDMA_tx_status_write_curr_ptr_i
                                    and (TX_Busy or TX_ChannelRSTBit);
                                    
SDMA_rx_status_detect_busy_wr_i <= SDMA_rx_status_write_curr_ptr_i
                                    and (RX_Busy or RX_ChannelRSTBit);
   
-------------------------------------------------------------------------------
-- Detect Write to Current Descriptor Pointer with Invalid Address
-------------------------------------------------------------------------------
PI_Valid_Address <= '1' when (ipic_wrdbus_i >= C_PI_BASEADDR) 
                         and (ipic_wrdbus_i <= C_PI_HIGHADDR)
               else '0';

SDMA_tx_status_detect_curr_ptr_err_i <= '1' when SDMA_tx_status_write_curr_ptr_i = '1' 
                                           and (ipic_wrdbus_i(27 to 31) /= "00000" 
                                                 or PI_Valid_Address = '0')
                                  else '0';
                              
SDMA_rx_status_detect_curr_ptr_err_i <= '1' when SDMA_rx_status_write_curr_ptr_i = '1' 
                                           and (ipic_wrdbus_i(27 to 31) /= "00000" 
                                                 or PI_Valid_Address = '0')
                                  else '0';
                              

-------------------------------------------------------------------------------
-- Detect Write to Tail Descriptor Pointer with Invalid Address
-------------------------------------------------------------------------------
SDMA_tx_status_detect_tail_ptr_err_i <= '1' when SDMA_tx_status_write_tail_ptr_i = '1' 
                                           and (ipic_wrdbus_i(27 to 31) /= "00000" 
                                                 or PI_Valid_Address = '0')
                                  else '0';

SDMA_rx_status_detect_tail_ptr_err_i <= '1' when SDMA_rx_status_write_tail_ptr_i = '1' 
                                           and (ipic_wrdbus_i(27 to 31) /= "00000" 
                                                 or PI_Valid_Address = '0')
                                  else '0';
-------------------------------------------------------------------------------
-- RX Local Link Status Signals
-------------------------------------------------------------------------------
REG_STATUS_BITS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(rx_channel_reset = '1')then
                SDMA_RX_Status_Set_Start_Of_Packet <=  '0';
                SDMA_RX_Status_Set_End_Of_Packet   <=  '0';
            else
                SDMA_RX_Status_Set_Start_Of_Packet <=  not RX_SOP;
                SDMA_RX_Status_Set_End_Of_Packet   <= RX_Rem_Limiting;
            end if;
        end if;
    end process REG_STATUS_BITS;
    

-------------------------------------------------------------------------------
-- DMA IPIC Interface
-------------------------------------------------------------------------------
IPIC_IF : entity mpmc_v6_03_a.sdma_ipic_if
    generic map (
        C_NUM_CE                        => C_NUM_CE             ,
        C_SPLB_AWIDTH                   => C_SPLB_AWIDTH        ,
        C_SPLB_NATIVE_DWIDTH            => C_SPLB_NATIVE_DWIDTH 
    )
    port map (
      -- Global Signals
        LLink_Clk                       => LLink_Clk            ,                         
        LLink_Rst                       => LLink_Rst            ,                         

        -- Reset Support
        ChannelRST                      => SDMA_TX_ChannelRST   ,
        RegFileRstDone                  => RegFileRstDone       ,
        System_Busy                     => system_busy          ,        
        RX_Busy                         => RX_Busy              ,
        TX_Busy                         => TX_Busy              ,
        SDMA_Ext_Reset                  => SDMA_Ext_Reset       ,
        
        -- IPIC Interface                                                        
        Bus2IP_Clk                      => bus2ip_clk           ,       
        Bus2IP_Reset                    => bus2ip_reset         ,       
        Bus2IP_CS                       => bus2ip_cs            ,
        Bus2IP_RNW                      => bus2ip_rnw           ,
        Bus2IP_Addr                     => bus2ip_addr          ,     
        Bus2IP_Data                     => bus2ip_data          ,     
        Bus2IP_RdCE                     => bus2ip_rdce          ,
        Bus2IP_WrCE                     => bus2ip_wrce          ,        
        IP2Bus_Data                     => ip2bus_data          ,     
        IP2Bus_WrAck                    => ip2bus_wrack         ,     
        IP2Bus_RdAck                    => ip2bus_rdack         ,     

        -- DCR RegFile and Status Reg Controls
        IPIC_Sel_AddrLen                => ipic_sel_addrlen     ,       
        IPIC_Sel_Data_Src               => ipic_sel_data_src    ,      
        IPIC_RegFile_WE                 => ipic_regfile_we      ,        
        IPIC_RegFile_Sel_Eng            => ipic_regfile_sel_eng ,   
        IPIC_RegFile_Sel_Reg            => ipic_regfile_sel_reg ,   

        IPIC_Control_Reg_WE             => IPIC_Control_Reg_WE  ,
        IPIC_Control_Reg_RE             => IPIC_Control_Reg_RE  ,
        IPIC_TX_Cntl_Reg_WE             => ipic_tx_cntl_reg_we_i,
        IPIC_RX_Cntl_Reg_WE             => ipic_rx_cntl_reg_we_i,

        IPIC_TX_Int_Reg_WE              => ipic_tx_int_reg_we   ,
        IPIC_RX_Int_Reg_WE              => ipic_rx_int_reg_we   ,
        IPIC_TX_Int_Reg_RE              => ipic_tx_int_reg_re   ,
        IPIC_RX_Int_Reg_RE              => ipic_rx_int_reg_re   ,
        IPIC_TX_Sts_Reg_RE              => IPIC_TX_Sts_Reg_RE   ,
        IPIC_RX_Sts_Reg_RE              => IPIC_RX_Sts_Reg_RE   ,


        IPIC_WrDBus                     => ipic_wrdbus_i        ,                  
        IPIC_RdDBus                     => ipic_rddbus_in       ,                
        
        -- DCR Port Arbiter Signals
        IPIC_RegFile_Request            => ipic_regfile_request ,         
        IPIC_RegFile_Busy               => ipic_regfile_busy    ,            
        IPIC_RegFile_Grant              => ipic_regfile_grant   ,
        
        -- DCR Event Detects
        Write_Curr_Ptr_TX               => SDMA_tx_status_write_curr_ptr_i,   
        Write_Curr_Ptr_RX               => SDMA_rx_status_write_curr_ptr_i,
        Write_Tail_Ptr_TX               => SDMA_tx_status_write_tail_ptr_i,
        Write_Tail_Ptr_RX               => SDMA_rx_status_write_tail_ptr_i
   );


IPIC_RDBUS_MUX : process(ipic_tx_int_reg_re,ipic_rx_int_reg_re,
                        tx_irq_reg,rx_irq_reg,IPIC_RdDBus)
    begin
        if(ipic_tx_int_reg_re = '1')then
            ipic_rddbus_in <= tx_irq_reg;
        elsif(ipic_rx_int_reg_re = '1')then
            ipic_rddbus_in <= rx_irq_reg;
        else
            ipic_rddbus_in <= IPIC_RdDBus;
        end if;
    end process IPIC_RDBUS_MUX;
            
            
            
-- Mux Interrupt Reg Output with Status Reg and RegFile Output
--ipic_rddbus_in    <= DCR_Int_Reg_Out when DCR_Int_Reg_Sel='1'
--                else IPIC_RdDBus;
  
-------------------------------------------------------------------------------
-- Interrupt Register
-------------------------------------------------------------------------------
INTR_REG_I : entity mpmc_v6_03_a.sdma_interrupt_register
    generic map (
        C_PRESCALAR                 => C_PRESCALAR              ,
        C_INSTANTIATE_TIMER_TX      => C_INSTANTIATE_TIMER_TX   ,
        C_INSTANTIATE_TIMER_RX      => C_INSTANTIATE_TIMER_RX   ,
        C_FAMILY                    => C_FAMILY                 
    )
    port map(
        LLink_Clk           => LLink_Clk                        ,                    
        LLink_Rst           => LLink_Rst                        ,                    

        PI_WrFIFO_Empty     => PI_WrFIFO_Empty                  ,
        
        IPIC_TX_Int_Reg_WE  => ipic_tx_int_reg_we               ,
        IPIC_RX_Int_Reg_WE  => ipic_rx_int_reg_we               ,
        IPIC_TX_Cntl_Reg_WE => ipic_tx_cntl_reg_we_i            ,
        IPIC_RX_Cntl_Reg_WE => ipic_rx_cntl_reg_we_i            ,
        IPIC_WrDBus         => Bus2IP_Data                      ,             

        -- Transmit Qualifiers
        TX_End              => tx_end_i                         ,                 
        TX_IntOnEnd         => TX_IntOnEnd                      ,            
        TX_ChannelRST       => SDMA_TX_ChannelRST               ,    
        TX_Control_Reg      => SDMA_TX_Control_Reg              ,
        TX_SOF              => tx_sof_i                         ,
        TX_EOF              => tx_eof_i                         ,
        Tx_Error_Int_Detect => TX_Error                         ,
        Tx_IRQ_Reg          => tx_irq_reg                       ,

        -- Receive Qualifiers
        RX_End              => rx_end_i                         ,                 
        RX_IntOnEnd         => RX_IntOnEnd                      ,            
        RX_ChannelRST       => SDMA_RX_ChannelRST               ,    
        RX_Control_Reg      => SDMA_RX_Control_Reg              ,
        RX_SOF              => RX_SOF                           ,
        RX_EOF              => RX_EOF                           , 
        Rx_Error_Int_Detect => RX_Error                         ,
        Rx_IRQ_Reg          => rx_irq_reg                       ,
        
        -- CDMAC Interrupt Out
        SDMA_Rx_IntOut      => SDMA_Rx_IntOut                   ,
        tx_desc_update_o	=> tx_desc_update_o		,
        SDMA_Tx_IntOut      => SDMA_Tx_IntOut
   );   

-------------------------------------------------------------------------------
-- Register File/Status Register Arbiter between DCR, TX, RX, TX1, and RX1
-------------------------------------------------------------------------------
REG_ARBITER_I : entity mpmc_v6_03_a.sdma_dmac_regfile_arb
    port map(
        LLink_Clk           => LLink_Clk,                      
        LLink_Rst           => LLink_Rst,                      
        DCR_Request         => ipic_regfile_request,      
        DCR_Busy            => ipic_regfile_busy,         
        DCR_Grant           => ipic_regfile_grant,        
        TX_Request          => TX_RegFile_Request,       
        TX_Busy             => TX_RegFile_Busy,          
        TX_Grant            => TX_RegFile_Grant,         
        RX_Request          => RX_RegFile_Request,       
        RX_Busy             => RX_RegFile_Busy,          
        RX_Grant            => RX_RegFile_Grant,         
        Grant_Hold          => RegFile_Grant_Hold        
   );

-------------------------------------------------------------------------------
-- Mux RegFile Control Signals
-------------------------------------------------------------------------------
REG_FILE_CONTROL : process(RegFile_Grant_Hold,ipic_sel_addrlen,
                           SDMA_TX_Sel_AddrLen,SDMA_RX_Sel_AddrLen)
    begin
        case RegFile_Grant_Hold is
            when "001" =>
                SDMA_Sel_AddrLen <= ipic_sel_addrlen;

            when "010" =>
                SDMA_Sel_AddrLen <= SDMA_TX_Sel_AddrLen;

            when "100" =>
                SDMA_Sel_AddrLen <= SDMA_RX_Sel_AddrLen;
            
            when others =>
                SDMA_Sel_AddrLen <= (others => '0');
        end case;
    end process REG_FILE_CONTROL;
            
-------------------------------------------------------------------------------
-- Arbitration Grant Hold
-------------------------------------------------------------------------------
GRANT_HOLD_PROCESS : process(RegFile_Grant_Hold,
                            ipic_sel_data_src,SDMA_TX_Sel_Data_Src,
                            SDMA_RX_Sel_Data_Src,

                            ipic_regfile_we,SDMA_TX_RegFile_WE,
                            SDMA_RX_RegFile_WE,

                            ipic_regfile_sel_eng,SDMA_TX_RegFile_Sel_Eng,
                            SDMA_RX_RegFile_Sel_Eng,
                            
                            ipic_regfile_sel_reg,SDMA_TX_RegFile_Sel_Reg,
                            SDMA_RX_RegFile_Sel_Reg) 
    begin
        case RegFile_Grant_Hold is
            when "001" =>
                SDMA_Sel_Data_Src      <= ipic_sel_data_src;
                SDMA_RegFile_WE        <= ipic_regfile_we;
                SDMA_RegFile_Sel_Eng   <= ipic_regfile_sel_eng;
                SDMA_RegFile_Sel_Reg   <= ipic_regfile_sel_reg;
                
            when "010" =>
                SDMA_Sel_Data_Src      <= SDMA_TX_Sel_Data_Src;
                SDMA_RegFile_WE        <= SDMA_TX_RegFile_WE;
                SDMA_RegFile_Sel_Eng   <= SDMA_TX_RegFile_Sel_Eng;
                SDMA_RegFile_Sel_Reg   <= SDMA_TX_RegFile_Sel_Reg;
            
            when "100" =>
                SDMA_Sel_Data_Src      <= SDMA_RX_Sel_Data_Src;
                SDMA_RegFile_WE        <= SDMA_RX_RegFile_WE;
                SDMA_RegFile_Sel_Eng   <= SDMA_RX_RegFile_Sel_Eng;
                SDMA_RegFile_Sel_Reg   <= SDMA_RX_RegFile_Sel_Reg;
            
            when others =>
                SDMA_Sel_Data_Src      <= (others => '0');
                SDMA_RegFile_WE        <= '0';
                SDMA_RegFile_Sel_Eng   <= '0';
                SDMA_RegFile_Sel_Reg   <= (others => '0');
        end case;
    end process GRANT_HOLD_PROCESS;

-------------------------------------------------------------------------------
-- PI_Read_Data_Delay
-------------------------------------------------------------------------------
SDMA_cl8r_start <= '1' when PI_AddrAck = '1' and pi_rnw_i = '1' and pi_size_i = "0010"
            else    '0';

SDMA_b16r_start <= '1' when PI_AddrAck = '1' and pi_rnw_i = '1' and pi_size_i = "0100"
            else    '0';


READ_DATA_DELAY_I : entity mpmc_v6_03_a.sdma_read_data_delay
    generic map (
        C_PI_RDDATA_DELAY           => C_PI_RDDATA_DELAY,
        C_PI2LL_CLK_RATIO           => C_PI2LL_CLK_RATIO
    )
    port map (
        LLink_Clk           => LLink_Clk            ,
        LLink_Rst           => LLink_Rst            ,
        PI_RdPop            => open        ,
        PI_Empty            => PI_RdFIFO_Empty      ,
        SDMA_RdPop          => PI_RdFIFO_Pop_i      ,
        PI_RdFIFO_Pop_32_bit => PI_RdFIFO_Pop_32_bit,
        PI_RdFIFO_Pop_32_bit_o => PI_RdFIFO_Pop ,
        -- mgg changed above port mapping to pass 32 bit pop
        SDMA_Empty          => PI_RdFIFO_Empty_i    ,
        SDMA_CL8R_Start     => SDMA_cl8r_start      ,
        SDMA_B16R_Start     => SDMA_b16r_start      ,
        Delay_Reg_CE        => delay_reg_ce         ,
        extra_d_reg_ce	=> extra_d_reg_ce,
        Delay_Reg_Sel       => delay_reg_sel    
   );

-------------------------------------------------------------------------------
-- Address Aribter
-------------------------------------------------------------------------------
ADDR_ARBITER_I : entity mpmc_v6_03_a.sdma_addr_arbiter
    port map(
        LLink_Clk           => LLink_Clk            ,               
        LLink_Rst           => LLink_Rst            ,               
        TX_Addr_Request     => TX_Addr_Request      ,   
        TX_Addr_Grant       => TX_Addr_Grant        ,     
        TX_Addr_Busy        => TX_Addr_Busy         ,      
        TX_Addr_Control     => tx_addr_control      ,   
        RX_Addr_Request     => RX_Addr_Request      ,   
        RX_Addr_Grant       => RX_Addr_Grant        ,     
        RX_Addr_Busy        => RX_Addr_Busy       
    );
   
-------------------------------------------------------------------------------
-- Read Arbiter
-------------------------------------------------------------------------------
READ_ARBITER_I : entity mpmc_v6_03_a.sdma_port_arbiter
    port map(
        LLink_Clk           => LLink_Clk                ,     
        LLink_Rst           => LLink_Rst                ,     
        TX_Port_Request     => TX_Read_Port_Request     ,     
        TX_Port_Grant       => TX_Read_Port_Grant       ,     
        TX_Port_Busy        => TX_Read_Port_Busy        ,     
        RX_Port_Request     => RX_Read_Port_Request     ,     
        RX_Port_Grant       => RX_Read_Port_Grant       ,     
        RX_Port_Busy        => RX_Read_Port_Busy        ,     
        TXNRX_Active        => PI_Read_Port_TX_Active   , 
                tx_desc_update_o	=> ground	,
        Timeout             => TX_Timeout                     
   );

-------------------------------------------------------------------------------
-- Write Arbiter
-------------------------------------------------------------------------------
WRITE_ARBITER_I : entity mpmc_v6_03_a.sdma_port_arbiter
    port map(
        LLink_Clk           => LLink_Clk                ,     
        LLink_Rst           => LLink_Rst                ,     
        TX_Port_Request     => TX_Write_Port_Request    ,     
        TX_Port_Grant       => TX_Write_Port_Grant      ,     
        TX_Port_Busy        => TX_Write_Port_Busy       ,     
        RX_Port_Request     => RX_Write_Port_Request    ,     
        RX_Port_Grant       => RX_Write_Port_Grant      ,     
        RX_Port_Busy        => RX_Write_Port_Busy       ,     
        TXNRX_Active        => PI_Write_Port_TX_Active  ,
        tx_desc_update_o	=> tx_desc_update_o	,
        Timeout             => open                    
   );
   
-------------------------------------------------------------------------------
-- Mux Port Control Signals
-------------------------------------------------------------------------------
    PI_AddrReq     <= tx_addrreq when tx_addr_control='1'
                  else rx_addrreq;
   
    PI_Addr         <= TX_Addr when tx_addr_control='1'
                  else RX_Addr;
   
    PI_RdModWr      <= '1';
   
    pi_rnw_i          <= TX_RNW when tx_addr_control = '1'
                    else RX_RNW;

    pi_size_i         <= TX_Size when tx_addr_control ='1' 
                  else RX_Size;

    TX_AddrAck      <= PI_AddrAck and tx_addr_control;
    
    RX_AddrAck      <= PI_AddrAck and not(tx_addr_control);

PI_RdFIFO_Pop_i <= rddataack_pos_i; -- mgg equation for 64-bit left intact

   PI_RdFIFO_Pop_32_bit <= (TX_rdDataAck_Pos or TX_rdDataAck_Neg) when PI_Read_Port_TX_Active = '1' 
                  else (RX_rdDataAck_Pos or RX_rdDataAck_Neg); -- mgg changed equation
                  -- to produce continuous pops for 32-bit operation
                  
                  
    PI_RdFIFO_Flush <= TX_RdFIFO_Flush when PI_Read_Port_TX_Active = '1' 
                  else RX_RdFIFO_Flush;
--    PI_RdFIFO_Flush <= TX_RdFIFO_Flush or RX_RdFIFO_Flush;
                  
                  
   TX_RdFIFO_Empty  <= PI_RdFIFO_Empty_i or not PI_Read_Port_TX_Active;
   
   RX_RdFIFO_Empty  <= PI_RdFIFO_Empty_i or PI_Read_Port_TX_Active;

   rddataack_pos_i    <= TX_rdDataAck_Pos when PI_Read_Port_TX_Active = '1' 
                  else RX_rdDataAck_Pos;
                  
   rdDataAck_Neg_i    <= TX_rdDataAck_Neg when PI_Read_Port_TX_Active = '1' 
                  else RX_rdDataAck_Neg;
                  

------------------------------------------------------------------------------------------------------------
-- Muxing values for WR_FIFO_BE depending on which word is being sent out
------------------------------------------------------------------------------------------------------------
   
   wrDataBE_Pos_i <= wrDataBE_Pos;
   PI_WrFIFO_BE_Reorder(0 to 3) <= wrDataBE_Pos_i when wrdataack_pos_i = '1' 
   				   else wrDataBE_Neg;
 --  PI_WrFIFO_BE_Reorder(0 to 3) <= wrDataBE_Pos_i; -- for 64-bit
 --  PI_WrFIFO_BE_Reorder(4 to 7) <= wrDataBE_Neg; -- for 64-bit

WRFIFO_BE_BITSWAP : process(PI_WrFIFO_BE_Reorder)
    begin
        for i in 0 to 3 loop
            PI_WrFIFO_BE(i) <= PI_WrFIFO_BE_Reorder(i);
        end loop;
    end process WRFIFO_BE_BITSWAP;

   PI_WrFIFO_Push               <= Wr_push_32bit; -- mgg changed this for 32 bit
   
 --PI_WrFIFO_Push               <= wrdataack_neg_i; -- mgg orig statement for 64 bit

   PI_WrFIFO_Flush      <= TX_WrFIFO_Flush when PI_Write_Port_TX_Active = '1'
                      else RX_WrFIFO_Flush;
      
   
   TX_WrFIFO_AlmostFull <= '1' when PI_WrFIFO_AlmostFull = '1' 
                                and PI_Write_Port_TX_Active ='1'
                      else '0';
                      
   RX_WrFIFO_AlmostFull <= '1' when PI_WrFIFO_AlmostFull = '1' 
                                and PI_Write_Port_TX_Active = '0'
                      else '0';

   
   wrDataBE_Pos     <= TX_wrDataBE_Pos when PI_Write_Port_TX_Active  = '1' 
                  else RX_wrDataBE_Pos;
                  
   wrDataBE_Neg     <= TX_wrDataBE_Neg when PI_Write_Port_TX_Active  = '1' 
                  else RX_wrDataBE_Neg;
                  
   wrdataack_pos_i   <= TX_wrDataAck_Pos when PI_Write_Port_TX_Active = '1'  
                  else RX_wrDataAck_Pos;
                  
   wrdataack_neg_i    <= TX_wrDataAck_Neg when PI_Write_Port_TX_Active = '1'  
                  else RX_wrDataAck_Neg;

   Wr_push_32bit <=  TX_Wr_push_32bit	when PI_Write_Port_TX_Active = '1' 			
			else RX_Wr_push_32bit;

   SDMA_Sel_Status_Writeback <= SDMA_TX_Sel_Status_Writeback 
                            when PI_Write_Port_TX_Active = '1'
                            else SDMA_RX_Sel_Status_Writeback;
                                 
   SDMA_Sel_PI_rdData_Pos    <= SDMA_TX_Sel_rdData_Pos 
                            when PI_Read_Port_TX_Active = '1'
                            else SDMA_RX_Sel_rdData_Pos;

-------------------------------------------------------------------------------
-- Register for Byte Enables for 64-bti sdma
-------------------------------------------------------------------------------
--REG_BE_PROCESS : process(LLink_Clk)
--    begin
--        if(LLink_Clk'EVENT and LLink_Clk = '1')then
--            if (LLink_Rst = '1')then
--                wrDataBE_Pos_i <= (others => '0');
--            elsif(wrdataack_pos_i='1')then
--                wrDataBE_Pos_i <= wrDataBE_Pos;
--            end if;
--        end if;
--    end process REG_BE_PROCESS;
   
-------------------------------------------------------------------------------
-- Transmit Write Handler
-------------------------------------------------------------------------------
TX_WR_HANDLER_I : entity mpmc_v6_03_a.sdma_tx_write_handler
    port map (
        -- Global Signals
        LLink_Clk                   => LLink_Clk                        ,
        LLink_Rst                   => tx_channel_reset                 ,

        -- Port Interface Signals                                       
        wrDataBE_Pos                => TX_wrDataBE_Pos                  ,
        wrDataBE_Neg                => TX_wrDataBE_Neg                  ,
        Wr_push_32bit		=> TX_Wr_push_32bit			,
        wrDataAck_Pos               => TX_wrDataAck_Pos                 ,
        wrDataAck_Neg               => TX_wrDataAck_Neg                 ,
        wrComp                      => open                             ,
        wr_rst                      => TX_WrFIFO_Flush                  ,
        wr_fifo_busy                => '0'                              ,
        wr_fifo_almostfull          => TX_WrFIFO_AlmostFull             ,

        -- Port Controller Signals                                      
        TX_CL8W_Start               => TX_CL8W_Start                    ,
        TX_CL8W_Comp                => TX_CL8W_Comp                     ,

        -- Channel Reset Signals                                        
--        TX_ChannelRST               => '0'                              ,
        TX_ChannelRST               => resetcomplete_i                  ,

        -- Datapath Signals                                             
        SDMA_Sel_Status_Writeback  => SDMA_TX_Sel_Status_Writeback    
    );

-------------------------------------------------------------------------------
-- Transmit Read Handler
-------------------------------------------------------------------------------
TX_RD_HANDLER_I : entity mpmc_v6_03_a.sdma_tx_read_handler
    port map (
        -- Global Signals
        LLink_Clk                       => LLink_Clk                    ,
        LLink_Rst                       => tx_channel_reset             ,
        -- Port Interface Signals                                       
        rdDataAck_Pos                   => TX_rdDataAck_Pos             ,
        rdDataAck_Neg                   => TX_rdDataAck_Neg             ,
        rdComp                          => open                         ,
        rd_rst                          => TX_RdFIFO_Flush              ,
        rd_fifo_empty                   => TX_RdFIFO_Empty              ,
        -- Local Link Signals                                           
        TX_Rem                          => TX_Rem                       ,
        TX_SOF                          => tx_sof_i                     ,
        TX_EOF                          => tx_eof_i                     ,
        TX_SOP                          => TX_SOP                       ,
        TX_EOP                          => TX_EOP                       ,
        TX_Src_Rdy                      => tx_src_rdy_i                 ,
        TX_Dst_Rdy                      => TX_Dst_Rdy                   ,
        -- Datapath Signals                                             
        SDMA_Sel_rdData_Pos             => SDMA_TX_Sel_rdData_Pos       ,
        -- Status Signal                                                
        EndOfPacket                     => TX_EndOfPacket               ,
        -- Counter Signals                                              
        SDMA_TX_Address                 => SDMA_TX_Address              ,
        SDMA_TX_Length                  => SDMA_TX_Length               ,
        SDMA_TX_AddrLen_INC1            => SDMA_TX_AddrLen_INC1         ,
        SDMA_TX_AddrLen_INC2            => SDMA_TX_AddrLen_INC2         ,
        SDMA_TX_AddrLen_INC3            => SDMA_TX_AddrLen_INC3         ,
        SDMA_TX_AddrLen_INC4            => SDMA_TX_AddrLen_INC4         ,
        -- TX Byte Shifter Controls                                        
        SDMA_TX_Shifter_Byte_Sel0       => SDMA_TX_Shifter_Byte_Sel0    ,
        SDMA_TX_Shifter_Byte_Sel1       => SDMA_TX_Shifter_Byte_Sel1    ,
        SDMA_TX_Shifter_Byte_Sel2       => SDMA_TX_Shifter_Byte_Sel2    ,
        SDMA_TX_Shifter_Byte_Sel3       => SDMA_TX_Shifter_Byte_Sel3    ,
        SDMA_TX_Shifter_Byte_Reg_CE     => SDMA_TX_Shifter_Byte_Reg_CE  ,
        -- Port Controller Signals                                      
        TX_CL8R_Start                   => TX_CL8R_Start                ,
        TX_CL8R_Comp                    => TX_CL8R_Comp                 ,
        TX_B16R_Start                   => TX_B16R_Start                ,
        TX_B16R_Comp                    => TX_B16R_Comp                 ,
        TX_RdPop                        => TX_RdPop                     ,
        TX_Payload                      => TX_Payload                   ,
        -- Channel Reset Signals                                        
        TX_ChannelRST                   => SDMA_TX_ChannelRST           ,
--        TX_RdHandlerRST                 => TX_RdHandlerRST              ,
        TX_RdHandlerRST                 => '0'              ,
        -- Timeout Signal
        TX_Timeout                      => RX_Read_Port_Request        
   );


-------------------------------------------------------------------------------
-- Transmit Port Controller
-------------------------------------------------------------------------------
tx_cl8r_i <= TX_CL8R and tx_eof_i;

TX_PORT_CNTRL_I : entity mpmc_v6_03_a.sdma_tx_port_controller
    generic map (
        C_P_BASEADDR                        => C_PI_BASEADDR                ,
        C_P_HIGHADDR                        => C_PI_HIGHADDR                ,
        C_COMPLETED_ERR                     => C_COMPLETED_ERR_TX
    )   
    port map (
        -- Global Signals
        LLink_Clk                           => LLink_Clk                    ,                       
        LLink_Rst                           => tx_channel_reset             ,

        -- Port Interface Signals                                           
        AddrReq                             => TX_AddrReq                   ,
        AddrAck                             => TX_AddrAck                   ,
        Addr                                => TX_Addr                      ,
        RNW                                 => TX_RNW                       ,
        Size                                => TX_Size                      ,
        RdFIFO_Empty                        => TX_RdFIFO_Empty              ,

        -- TX State Signals                                                 
        CL8R                                => tx_cl8r_i                    ,
        B16R                                => TX_B16R                      ,
        CL8W                                => TX_CL8W                      ,
        Channel_Read_Desc_Done              => TX_Channel_Read_Desc_Done    ,
        Channel_Data_Done                   => TX_Channel_Data_Done         ,
        Channel_Continue                    => TX_Channel_Continue          ,
        Channel_Stop                        => TX_Channel_Stop              ,

        -- Port Arbiter Signals                                             
        Read_Port_Request                   => TX_Read_Port_Request         ,
        Read_Port_Grant                     => TX_Read_Port_Grant           ,
        Read_Port_Busy                      => TX_Read_Port_Busy            ,
        Write_Port_Request                  => TX_Write_Port_Request        ,
        Write_Port_Grant                    => TX_Write_Port_Grant          ,
        Write_Port_Busy                     => TX_Write_Port_Busy           ,

        -- RegFile Arbiter Signals                                          
        RegFile_Request                     => TX_RegFile_Request           ,
        RegFile_Grant                       => TX_RegFile_Grant             ,
        RegFile_Busy                        => TX_RegFile_Busy              ,

        -- Data Bus Select Signals                                          
        SDMA_Sel_AddrLen                   => SDMA_TX_Sel_AddrLen         ,
        SDMA_Sel_Data_Src                  => SDMA_TX_Sel_Data_Src        ,

        -- Register File Controls                                           
        SDMA_RegFile_WE                    => SDMA_TX_RegFile_WE          ,
        SDMA_RegFile_Sel_Eng               => SDMA_TX_RegFile_Sel_Eng     ,
        SDMA_RegFile_Sel_Reg               => SDMA_TX_RegFile_Sel_Reg     ,


        -- TailPointer Mode Support
        TailPntrMode                        => tailpntrmode                 ,
        SDMA_TX_CurDesc_Ptr                => SDMA_TX_CurDesc_Ptr         ,
        SDMA_TX_TailDesc_Ptr               => SDMA_TX_TailDesc_Ptr        ,


        -- Counter Signals                                                  
        SDMA_TX_Address                    => SDMA_TX_Address             ,
        SDMA_TX_Address_Load               => SDMA_TX_Address_Load        ,
        SDMA_TX_Length                     => SDMA_TX_Length              ,
        SDMA_TX_Length_Load                => SDMA_TX_Length_Load         ,

        -- Status Register Signals                                          
        SDMA_Status_Detect_Nxt_Ptr_Err     => SDMA_tx_status_detect_nxt_ptr_err_i  ,
        SDMA_Status_Detect_Addr_Err        => SDMA_tx_status_detect_addr_err_i     ,
        SDMA_Status_Detect_Completed_Err   => SDMA_tx_status_detect_completed_err_i,
        SDMA_Status_Set_SDMA_Completed     => SDMA_TX_Status_Set_SDMA_Completed ,
        SDMA_Status_Detect_Stop            => SDMA_TX_Status_Detect_Stop         ,            
        SDMA_Status_Detect_Null_Ptr        => sdma_tx_status_detect_null_ptr_i     ,
        SDMA_Status_Mem_CE                 => SDMA_TX_Status_Mem_CE        ,
        TX_End                              => tx_end_i                        ,
        TX_Completed                        => TX_Completed                  ,
        TX_StopOnEnd                        => TX_StopOnEnd                  ,
    

        -- TX Data Handler Signals                                           
        TX_CL8R_Start                       => TX_CL8R_Start                 ,
        TX_CL8R_Comp                        => TX_CL8R_Comp                  ,
        TX_B16R_Start                       => TX_B16R_Start                 ,
        TX_B16R_Comp                        => TX_B16R_Comp                  ,
        TX_RdPop                            => TX_RdPop                      ,
        TX_CL8W_Start                       => TX_CL8W_Start                 ,
        TX_CL8W_Comp                        => TX_CL8W_Comp                  ,
        TX_Dst_Rdy                          => TX_Dst_Rdy                    ,
        TX_Payload                          => TX_Payload                    ,

        -- Address Arbitration                                               
        TX_Addr_Request                     => TX_Addr_Request               ,
        TX_Addr_Grant                       => TX_Addr_Grant                 ,
        TX_Addr_Busy                        => TX_Addr_Busy                  ,

        -- Channel Reset Signals                                             
        TX_ChannelRST                       => SDMA_TX_ChannelRST           ,
--        TX_PortCntrl_RstOut                 => tx_portcntrl_rstout,
        TX_RdHandlerRST                     => open              

   );


-------------------------------------------------------------------------------
-- Transmit State Machine
-------------------------------------------------------------------------------
--tx_state_rst <= LLink_Rst or tx_portcntrl_rstout or TX_Error;
tx_state_rst <= LLink_Rst or resetcomplete_i or tx_channel_reset;

--GAB 01/02/07 TailPointer Mod
--tx_start     <= '1' when (SDMA_tx_status_write_curr_ptr_i = '1' and tailpntrmode = '0')
--                      or (SDMA_tx_status_write_tail_ptr_i = '1' and tailpntrmode = '1')
--           else '0';

-- Modified 8/13 to fix issue with tailpointer write being missed if occuring on same
-- cycle as channel_stop.
TX_START_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(tx_state_rst = '1' or TX_CL8R='1' or sdma_tx_status_detect_null_ptr_i='1')then
                tx_start <= '0';
            elsif((SDMA_tx_status_write_curr_ptr_i = '1' and tailpntrmode = '0')
                or(SDMA_tx_status_write_tail_ptr_i='1'   and tailpntrmode = '1'))then
                    tx_start <= '1';
            end if;
        end if;
    end process TX_START_PROCESS;


TX_STATE_I : entity mpmc_v6_03_a.sdma_tx_rx_state
    port map (
        -- Global Signals
        LLink_Clk                   => LLink_Clk                        ,                       
        LLink_Rst                   => tx_state_rst                     ,
        -- Request Types                                                
        CL8R                        => TX_CL8R                          ,
        B16                         => TX_B16R                          ,
        CL8W                        => TX_CL8W                          ,
        -- Controls                                                     
        Channel_Reset               => SDMA_TX_ChannelRST               ,
        Channel_Start               => tx_start                         ,
        Channel_Read_Desc_Done      => TX_Channel_Read_Desc_Done        ,
        Channel_Data_Done           => TX_Channel_Data_Done             ,
        Channel_Continue            => TX_Channel_Continue              ,
        Channel_Stop                => TX_Channel_Stop               
    );   
   
-------------------------------------------------------------------------------
-- Receive Write Handler
-------------------------------------------------------------------------------
rx_timeout_i <= (TX_AddrReq and not(TX_RNW)) or TX_Write_Port_Request;



RX_WR_HANDLER_I : entity mpmc_v6_03_a.sdma_rx_write_handler
    generic map (
        C_TIMEOUT_PERIOD            => C_RX_TIMEOUT_PERIOD  
    )
    port map (
        -- Global inputs
        LLink_Clk                       => LLink_Clk                    ,                       
        LLink_Rst                       => rx_channel_reset             ,
        -- Port Interface Signals                                       
        wrDataBE_Pos                    => RX_wrDataBE_Pos              ,
        wrDataBE_Neg                    => RX_wrDataBE_Neg              ,
        wrDataAck_Pos                   => RX_wrDataAck_Pos             ,
        wrDataAck_Neg                   => RX_wrDataAck_Neg             ,
        wr_push_32bit			=> RX_wr_push_32bit		,
        wrComp                          => open                         ,
        wr_rst                          => RX_WrFIFO_Flush              ,
        wr_fifo_busy                    => '0'                          ,
        wr_fifo_almostfull              => RX_WrFIFO_AlmostFull         ,
        -- Local Link Signals                                           
        RX_Rem                          => RX_Rem                       ,
        RX_SOF                          => RX_SOF                       ,
        RX_EOF                          => RX_EOF                       ,
        RX_SOP                          => RX_SOP                       ,
        RX_EOP                          => RX_EOP                       ,
        RX_Src_Rdy                      => RX_Src_Rdy                   ,
        RX_Dst_Rdy                      => rx_dst_rdy_i                   ,
        -- Datapath Signals                                             
        SDMA_Sel_Status_Writeback      => SDMA_RX_Sel_Status_Writeback,
        -- Counter Signals                                              
        SDMA_RX_Address                => SDMA_RX_Address             ,
        SDMA_RX_Address_Load            => SDMA_RX_Address_Load_i        ,
        SDMA_RX_Length                 => SDMA_RX_Length              ,
        SDMA_RX_AddrLen_INC1           => SDMA_RX_AddrLen_INC1        ,
        SDMA_RX_AddrLen_INC2           => SDMA_RX_AddrLen_INC2        ,
        SDMA_RX_AddrLen_INC3           => SDMA_RX_AddrLen_INC3        ,
        SDMA_RX_AddrLen_INC4           => SDMA_RX_AddrLen_INC4        ,
        -- RX Byte Shifter Controls                                     
        SDMA_RX_Shifter_HoldReg_CE     => SDMA_RX_Shifter_HoldReg_CE  ,
        SDMA_RX_Shifter_Byte_Sel       => SDMA_RX_Shifter_Byte_Sel    ,
        SDMA_RX_Shifter_CE             => SDMA_RX_Shifter_CE          ,
        -- Port Controller Signals                                      
        RX_CL8W_Start                   => RX_CL8W_Start                ,
        RX_CL8W_Comp                    => RX_CL8W_Comp                 ,
        RX_B16W_Start                   => RX_B16W_Start                ,
        RX_B16W_Comp                    => RX_B16W_Comp                 ,
        RX_Busy                         => RX_Busy                      ,
        RX_Payload                      => RX_Payload                   ,
        RX_Footer                       => RX_Footer                    ,
        
        RX_RdModWr                      => rx_rdmodwr                   ,
        -- Channel Reset Signals                                        
        RX_ChannelRST                   => SDMA_RX_ChannelRST           ,            
        RX_WrHandlerForce               => resetcomplete_i              ,
        RX_ISIDLE_Reset                 => rx_isidle_reset              ,
        WrPushCount_o			=> WrPushCount_o		,
        SDMA_rx_error	=> SDMA_RX_Status_Out(24),
        -- Timeout Signal                                               
        RX_Timeout                      => rx_timeout_i                 ,
        -- Rem Limiting Signal                                          
        Rem_Limiting                    => RX_Rem_Limiting              
    );
   
-------------------------------------------------------------------------------
-- Receive Read Handler
-------------------------------------------------------------------------------
RX_RD_HANDLER_I : entity mpmc_v6_03_a.sdma_rx_read_handler
    port map (
        -- Global Signals
        LLink_Clk                       => LLink_Clk                    ,
        LLink_Rst                       => rx_channel_reset             ,
        -- Port Interface Signals                                       
        rdDataAck_Pos                   => RX_rdDataAck_Pos             ,
        rdDataAck_Neg                   => RX_rdDataAck_Neg             ,
        rdComp                          => open                         ,
        rd_rst                          => RX_RdFIFO_Flush              ,
        rd_fifo_empty                   => RX_RdFIFO_Empty              ,
        -- Datapath Signals                                             
        SDMA_Sel_rdData_Pos             => SDMA_RX_Sel_rdData_Pos       ,
        -- Port Controller Signals                                      
        RX_CL8R_Start                   => RX_CL8R_Start                ,
        RX_CL8R_Comp                    => RX_CL8R_Comp                 ,
        RX_RdPop                        => RX_RdPop                     ,
        -- Channel Reset Signals                                        
        RX_ChannelRST                   =>SDMA_RX_ChannelRST            
--        RX_RdHandlerRST                 => RX_RdHandlerRST              
   );
   
-------------------------------------------------------------------------------
-- Receive Port Controller
-------------------------------------------------------------------------------
RX_PORT_CNTRL_I : entity mpmc_v6_03_a.sdma_rx_port_controller
    generic map (
        C_P_BASEADDR                    => C_PI_BASEADDR                ,
        C_P_HIGHADDR                    => C_PI_HIGHADDR                ,
        C_COMPLETED_ERR                 => C_COMPLETED_ERR_RX
    )
    port map (
        -- Global Signals
        LLink_Clk                       => LLink_Clk                    ,            
        LLink_Rst                       => rx_channel_reset             ,          
        -- Port Interface Signals                                       
        AddrReq                         => RX_AddrReq                   ,          
        AddrAck                         => RX_AddrAck                   ,          
        Addr                            => RX_Addr                      ,          
        RNW                             => RX_RNW                       ,
        Size                            => RX_Size                      ,
        RdFIFO_Empty                    => RX_RdFIFO_Empty              ,
        -- RX State Signals                                             
        CL8R                            => RX_CL8R                      ,
        B16W                            => RX_B16W                      ,
        CL8W                            => RX_CL8W                      ,
        Channel_Read_Desc_Done          => RX_Channel_Read_Desc_Done    ,
        Channel_Data_Done               => RX_Channel_Data_Done         ,
        Channel_Continue                => RX_Channel_Continue          ,
        Channel_Stop                    => RX_Channel_Stop              ,
        -- Port Arbiter Signals                                         
        Read_Port_Request               => RX_Read_Port_Request         ,
        Read_Port_Grant                 => RX_Read_Port_Grant           ,
        Read_Port_Busy                  => RX_Read_Port_Busy            ,
        Write_Port_Request              => RX_Write_Port_Request        ,
        Write_Port_Grant                => RX_Write_Port_Grant          ,
        Write_Port_Busy                 => RX_Write_Port_Busy           ,
        -- RegFile Arbiter Signals                                      
        RegFile_Request                 => RX_RegFile_Request           ,
        RegFile_Grant                   => RX_RegFile_Grant             ,
        RegFile_Busy                    => RX_RegFile_Busy              ,
        -- Data Bus Select Signals                                      
        SDMA_Sel_AddrLen                => SDMA_RX_Sel_AddrLen         ,
        SDMA_Sel_Data_Src               => SDMA_RX_Sel_Data_Src        ,
        -- Register File Controls                                           
        SDMA_RegFile_WE                 => SDMA_RX_RegFile_WE          ,
        SDMA_RegFile_Sel_Eng            => SDMA_RX_RegFile_Sel_Eng     ,
        SDMA_RegFile_Sel_Reg            => SDMA_RX_RegFile_Sel_Reg     ,
        -- Counter Signals                                                  
        SDMA_RX_Address                 => SDMA_RX_Address_Reg         ,
        SDMA_RX_Address_Load            => SDMA_RX_Address_Load_i        ,
        SDMA_RX_Length                  => SDMA_RX_Length              ,
        SDMA_RX_Length_Load             => SDMA_RX_Length_Load         ,
        -- Status Register Signals
        SDMA_Status_Detect_Nxt_Ptr_Err  => SDMA_rx_status_detect_nxt_ptr_err_i       ,
        SDMA_Status_Detect_Addr_Err     => SDMA_rx_status_detect_addr_err_i          ,
        SDMA_Status_Detect_Completed_Err=> SDMA_rx_status_detect_completed_err_i ,
        SDMA_Status_Set_SDMA_Completed  => SDMA_RX_Status_Set_SDMA_Completed  ,
        SDMA_Status_Detect_Stop         => SDMA_RX_Status_Detect_Stop              ,
        SDMA_Status_Detect_Null_Ptr     => sdma_rx_status_detect_null_ptr_i          ,
        SDMA_Status_Mem_CE              => SDMA_RX_Status_Mem_CE                   ,

        -- TailPointer Mode Support
        TailPntrMode                    => tailpntrmode                 ,
        SDMA_RX_CurDesc_Ptr             => SDMA_RX_CurDesc_Ptr         ,
        SDMA_RX_TailDesc_Ptr            => SDMA_RX_TailDesc_Ptr        ,


        RX_End                          => rx_end_i                       , 
        RX_StopOnEnd                    => RX_StopOnEnd                 , 
        RX_Completed                    => RX_Completed                 , 
        -- RX Data Handler Signals                                      
        RX_CL8R_Start                   => RX_CL8R_Start                , 
        RX_CL8R_Comp                    => RX_CL8R_Comp                 , 
        RX_RdPop                        => RX_RdPop                     , 
        RX_B16W_Start                   => RX_B16W_Start                , 
        RX_B16W_Comp                    => RX_B16W_Comp                 , 
        RX_CL8W_Start                   => RX_CL8W_Start                , 
        RX_CL8W_Comp                    => RX_CL8W_Comp                 , 
        RX_Footer                       => RX_Footer                    , 
        -- Address Arbitration                                          
        RX_Addr_Request                 => RX_Addr_Request              , 
        RX_Addr_Grant                   => RX_Addr_Grant                , 
        RX_Addr_Busy                    => RX_Addr_Busy                 , 
        -- Channel Reset Signals                                        
        RX_ChannelRST                   => SDMA_RX_ChannelRST           , 
        RX_ISIDLE_Reset                 => rx_isidle_reset              ,
        RX_Src_Rdy			=>RX_Src_Rdy			,
        WrPushCount_o			=> WrPushCount_o		,
--        RX_PortCntrl_RstOut             => rx_portcntrl_rstout          ,
--        RX_RdHandlerRST                 => RX_RdHandlerRST              , 
--        RX_WrHandlerForce               => RX_WrHandlerForce            ,
        RX_WrHandlerForce               => open                           
   );
   
-------------------------------------------------------------------------------
--Receive State Machine
-------------------------------------------------------------------------------
--rx_state_rst <= LLink_Rst or SDMA_RX_ChannelRST or RX_Error;
--rx_state_rst <= LLink_Rst or rx_portcntrl_rstout or RX_Error;
rx_state_rst <= LLink_Rst or resetcomplete_i or rx_channel_reset;


--GAB 01/19/07 TailPointer Mod
--rx_start     <= '1' when (SDMA_rx_status_write_curr_ptr_i = '1' and tailpntrmode = '0')
--                      or (SDMA_rx_status_write_tail_ptr_i = '1' and tailpntrmode = '1')
--           else '0';
-- Modified 8/13 to fix issue with tailpointer write being missed if occuring on same
-- cycle as channel_stop.
RX_START_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(rx_state_rst = '1' or RX_CL8R='1' or sdma_rx_status_detect_null_ptr_i='1')then
                rx_start <= '0';
            elsif((SDMA_rx_status_write_curr_ptr_i = '1' and tailpntrmode = '0')
                or(SDMA_rx_status_write_tail_ptr_i='1'   and tailpntrmode = '1'))then
                    rx_start <= '1';
            end if;
        end if;
    end process RX_START_PROCESS;


RX_STATE_I : entity mpmc_v6_03_a.sdma_tx_rx_state
    port map (
      -- Global Signals
      LLink_Clk                         => LLink_Clk                        ,   
      LLink_Rst                         => rx_state_rst                     ,       
      -- Request Types                                                      
      CL8R                              => RX_CL8R                          ,
      B16                               => RX_B16W                          ,
      CL8W                              => RX_CL8W                          ,
      -- Controls                                                           
      Channel_Reset                     => SDMA_RX_ChannelRST               ,
      Channel_Start                     => rx_start                         ,
      Channel_Read_Desc_Done            => RX_Channel_Read_Desc_Done        ,
      Channel_Data_Done                 => RX_Channel_Data_Done             ,
      Channel_Continue                  => RX_Channel_Continue              ,
      Channel_Stop                      => RX_Channel_Stop                  
   );
   
end implementation; -- sdma_cntl






