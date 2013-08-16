-------------------------------------------------------------------------------
-- sdma.vhd
-------------------------------------------------------------------------------
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
-- Filename:        sdma.vhd
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
--  - Converted DCR Slave interface to PLB v4.6
--  - Modified register memory/bit map to match Hardened DMA
--  - Fixed misc issues
-- ^^^^^^
--  GAB     5/9/07
-- ~~~~~~
--  - Fixed issue with CS strobe being allowed to kick off another register file
--  access during a soft reset.  This caused multiple ip2bus_rdack's to occur
--  and ultimatly caused multiple sl_rdack's and sl_rdcomp's to occur.
--  Modified ipic_if.vhd.
-- ^^^^^^
--  GAB     5/18/07
-- ~~~~~~
-- Fixed error bit ordering the tailpointer error bit was in the wrong bit
-- position which threw all other bits off by 1. modified channel_status_reg.vhd
-- ^^^^^^
--  GAB     5/12/07
-- ~~~~~~
--  - Issue when next pointer was a null pointer it would also generate a
--  pointer error.  To fix this issue I qualified SDMA_Status_Detect_Nxt_Ptr_Err
--  with not being a null pointer.  Modified tx_port_controller.vhd and
--  rx_port_controller.vhd
--  - Re-Qualified pi_rdfifo_flush with the active channel qualifier to fix
--  an issue when one channel detected and error.  This caused the rdfifo
--  to be flushed thus corrupting the other channels operations. Modified
--  sdma_cntl.vhd
-- ^^^^^^
--  GAB     6/18/07
-- ~~~~~~
--  - Fixed issue where completed error bit was getting set when a soft reset
--  was issued after an error was detected.
--  - Fixed an issue where the descriptor update tracking logic was not being
--  reset in the interrupt_register.vhd during a soft reset.
-- ^^^^^^
--  GAB     7/2/07
-- ~~~~~~
--  - Registered completed error detection to break logic loop. Modified
--  tx_port_controller.vhd and rx_port_controller.vhd
-- ^^^^^^
--  GAB     8/17/07
-- ~~~~~~
--  - Removed combinatorial logic from error flag to fix timing path.  Modified
--  channel_status_reg.vhd.
--  - Fixed issue where completed error was getting set incorrectly during
--  a next pointer error detection.  Modified tx_port_controller and 
--  rx_port_controller.
--  - Fixed corner case issue where tail pointer update could be missed if
--  it occurred on the same cycle as a stop condition
--  - Register pi_addrreq to fix a timing path.
-- ^^^^^^
--  GAB     8/30/07
-- ~~~~~~
--  - Added logic to prevent delay and coalesce counters from rolling over.  This
-- was done to fix an issue where the interrupt output de-asserted prematurely.
-- Modified interrupt_register.vhd.
-- ^^^^^^
--  GAB     9/28/07 v1_00_b
-- ~~~~~~
--  - Zero extended various vectors in summation functions to prevent truncation
--  issues.  This fixes CR450181.  Modified rx_write_handler.vhd and
--  tx_read_handler.vhd
-- ^^^^^^
--  GAB     10/22/07
-- ~~~~~~
--  - Registered PI_RdFIFO_Data for LUTRAM with pi_clk to fix long timing path.
--  Modified sdma_datapath.vhd 
--  - Mapped PI_clk to sdma_datapath.vhd.
-- ^^^^^^
--  MHG	    12/09/08
-- ~~~~~~
--	Updated to proc_common_v3_00_a.
--	Fixed lockup of MPMC, caused by SDMA making an NPI request when an invalid Buffer Address was fetched in either Tx or Rx Buffer Descriptor.
--	Fixed Rx data corruption on Rx block write, when Tx Buffer Descriptor needs to be updated.
--	Fixed Rx data corruption on Rx block write when Tx memory read was performed.
-- ^^^^^^
--  MHG	    03/23/09
-- ~~~~~~	
--  - Disabled wr_port_grant to Rx side when a descriptor update is being made
--   by the Tx side. The colaescing count is incremented once the empty flag
--   is asserted following a BD update. If the Rx side pushes data into the WR_FIFO
--   before the BD update data is read out by MPMC, then the coalescing count will 
--   be corrupted
--	- Added new reset condition for WRFIFO_BE coming from RX_write_handler.vhd
--	Without this condition the Byte enables would hold a value from a
--	previous transaction and corrupt BE's to NPI
--	- Passed plb clock directly to sdma control path instead of going
--	through IPIF as this was causing simulations to fail due to 
--	Delta step delay issues
--  - Disabled Data phase timeout in plbv46_slave_single instantiation
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

library plbv46_slave_single_v1_01_a;
use plbv46_slave_single_v1_01_a.all;

-------------------------------------------------------------------------------
entity sdma is
    generic (


        C_PI_BASEADDR           : std_logic_vector(0 to 31) := X"00000000";
        C_PI_HIGHADDR           : std_logic_vector(0 to 31) := X"FFFFFFFF";
        C_PI_ADDR_WIDTH         : integer range 32 to 32    := 32;
        C_PI_DATA_WIDTH         : integer range 32 to 32    := 32;
        C_PI_BE_WIDTH           : integer range 4 to 4      := 4;
        C_PI_RDWDADDR_WIDTH     : integer range 4 to 4      := 4;
        C_SDMA_BASEADDR         : std_logic_vector(0 to 31) := X"00000000";
        C_SDMA_HIGHADDR         : std_logic_vector(0 to 31) := X"FFFFFFFF";
        C_COMPLETED_ERR_TX      : integer range 0 to 1      := 1;
        C_COMPLETED_ERR_RX      : integer range 0 to 1      := 1;
        C_PRESCALAR             : integer range 0 to 1023   := 1023;
        C_PI_RDDATA_DELAY       : integer range 0 to 2      := 0;
        C_PI2LL_CLK_RATIO       : integer range 1 to 2      := 1;

        C_SPLB_P2P              : integer range 0 to 1      := 0;
            -- Optimize slave interface for a point to point connection
        C_SPLB_MID_WIDTH        : integer range 1 to 4      := 1;
            -- The width of the Master ID bus
            -- This is set to log2(C_SPLB_NUM_MASTERS)

        C_SPLB_NUM_MASTERS      : integer range 1 to 16     := 1;
            -- The number of Master Devices connected to the PLB bus
            -- Research this to find out default value

        C_SPLB_AWIDTH           : integer range 32 to 32    := 32;
            --  width of the PLB Address Bus (in bits)

        C_SPLB_DWIDTH           : integer range 32 to 128   := 32;
            --  Width of the PLB Data Bus (in bits)

        C_SPLB_NATIVE_DWIDTH    : integer range 32 to 32    := 32;
            --  Width of IPIF Data Bus (in bits)

        C_FAMILY                : string := "virtex5"
            -- Select the target architecture type
            -- see the family.vhd package in the proc_common
            -- library

    );
    port (

        LLink_Clk           : in  std_logic;
        PI_CLK              : in  std_logic;

        -- PLB Slave Input signals
        SPLB_Clk            : in  std_logic;
        SPLB_Rst            : in  std_logic;
        PLB_ABus            : in  std_logic_vector(0 to 31);
        PLB_UABus           : in  std_logic_vector(0 to 31);
        PLB_PAValid         : in  std_logic;
        PLB_SAValid         : in  std_logic;
        PLB_rdPrim          : in  std_logic;
        PLB_wrPrim          : in  std_logic;
        PLB_masterID        : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
        PLB_abort           : in  std_logic;
        PLB_busLock         : in  std_logic;
        PLB_RNW             : in  std_logic;
        PLB_BE              : in  std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1);
        PLB_MSize           : in  std_logic_vector(0 to 1);
        PLB_size            : in  std_logic_vector(0 to 3);
        PLB_type            : in  std_logic_vector(0 to 2);
        PLB_lockErr         : in  std_logic;
        PLB_wrDBus          : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
        PLB_wrBurst         : in  std_logic;
        PLB_rdBurst         : in  std_logic;
        PLB_wrPendReq       : in  std_logic;
        PLB_rdPendReq       : in  std_logic;
        PLB_wrPendPri       : in  std_logic_vector(0 to 1);
        PLB_rdPendPri       : in  std_logic_vector(0 to 1);
        PLB_reqPri          : in  std_logic_vector(0 to 1);
        PLB_TAttribute      : in  std_logic_vector(0 to 15);

        -- PLB Slave Response Signals
        Sln_addrAck         : out std_logic;
        Sln_SSize           : out std_logic_vector(0 to 1);
        Sln_wait            : out std_logic;
        Sln_rearbitrate     : out std_logic;
        Sln_wrDAck          : out std_logic;
        Sln_wrComp          : out std_logic;
        Sln_wrBTerm         : out std_logic;
        Sln_rdDBus          : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
        Sln_rdWdAddr        : out std_logic_vector(0 to 3);
        Sln_rdDAck          : out std_logic;
        Sln_rdComp          : out std_logic;
        Sln_rdBTerm         : out std_logic;
        Sln_MBusy           : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
        Sln_MWrErr          : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
        Sln_MRdErr          : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
        Sln_MIRQ            : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);


        -- MPMC Port Interface
        PI_Addr                 : out std_logic_vector(C_PI_ADDR_WIDTH-1 downto 0);
        PI_AddrReq              : out std_logic;
        PI_AddrAck              : in  std_logic;
        PI_RdModWr              : out std_logic;
        PI_RNW                  : out std_logic;
        PI_Size                 : out std_logic_vector(3 downto 0);
        PI_WrFIFO_Data          : out std_logic_vector(C_PI_DATA_WIDTH-1 downto 0);
        PI_WrFIFO_BE            : out std_logic_vector(C_PI_BE_WIDTH-1 downto 0);
        PI_WrFIFO_Push          : out std_logic;
        PI_RdFIFO_Data          : in  std_logic_vector(C_PI_DATA_WIDTH-1 downto 0);
        PI_RdFIFO_Pop           : out std_logic;
        PI_RdFIFO_RdWdAddr      : in  std_logic_vector(C_PI_RDWDADDR_WIDTH-1 downto 0);
        PI_WrFIFO_AlmostFull    : in  std_logic;
        PI_WrFIFO_Empty         : in  std_logic;
        PI_WrFIFO_Flush         : out std_logic;
        PI_RdFIFO_DataAvailable : in  std_logic;
        PI_RdFIFO_Empty         : in  std_logic;
        PI_RdFIFO_Flush         : out std_logic;
        
        -- TX Local Link Interface
        TX_D                    : out std_logic_vector(0 to 31);
        TX_Rem                  : out std_logic_vector(0 to 3);
        TX_SOF                  : out std_logic;
        TX_EOF                  : out std_logic;
        TX_SOP                  : out std_logic;
        TX_EOP                  : out std_logic;
        TX_Src_Rdy              : out std_logic;
        TX_Dst_Rdy              : in  std_logic;
        -- RX Local Link Interface
        RX_D                    : in  std_logic_vector(0 to 31);
        RX_Rem                  : in  std_logic_vector(0 to 3);
        RX_SOF                  : in  std_logic;
        RX_EOF                  : in  std_logic;
        RX_SOP                  : in  std_logic;
        RX_EOP                  : in  std_logic;
        RX_Src_Rdy              : in  std_logic;
        RX_Dst_Rdy              : out std_logic;
        
        -- SDMA System Interface
        SDMA_RstOut             : out std_logic;
        SDMA_Rx_IntOut          : out std_logic;
        SDMA_Tx_IntOut          : out std_logic
    );

end sdma;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
-- PLBV46 Slave Single Parameters
constant ARD_ADDR_RANGE_ARRAY   : SLV64_ARRAY_TYPE 
                                    := ((X"00000000" & C_SDMA_BASEADDR),
                                        (X"00000000" & C_SDMA_HIGHADDR));
                                                     
constant ARD_NUM_CE_ARRAY       : INTEGER_ARRAY_TYPE 
                                    := (0 => 17); 

constant NUM_CE                 : integer := calc_num_ce(ARD_NUM_CE_ARRAY);

-- Former Parameters fixed to constants for SDMA
constant INSTANTIATE_TIMER_TX   : integer range 0 to 1      := 1;
constant INSTANTIATE_TIMER_RX   : integer range 0 to 1      := 1;

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
-- DCR Data Buses
signal ipic_wrdbus                          : std_logic_vector(0 to 31);
signal ipic_rddbus                          : std_logic_vector(0 to 31);

-- Data Bus Select Signals
signal SDMA_Sel_AddrLen                     : std_logic_vector(1 downto 0);  
signal SDMA_Sel_Data_Src                    : std_logic_vector(1 downto 0);  
signal SDMA_Sel_PI_rdData_Pos               : std_logic_vector(3 downto 0);  
signal SDMA_Sel_Status_Writeback            : std_logic_vector(1 downto 0);  

-- Reg File Controls                                                        
signal SDMA_RegFile_WE                      : std_logic;             
signal SDMA_RegFile_Sel_Eng                 : std_logic;  
signal SDMA_RegFile_Sel_Reg                 : std_logic_vector(2 downto 0);  

-- Counter Signals                                                           
signal SDMA_TX_Address                      : std_logic_vector(31 downto 0); 
signal SDMA_TX_Address_Load                 : std_logic;             
signal SDMA_TX_Length                       : std_logic_vector(31 downto 0); 
signal SDMA_TX_Length_Load                  : std_logic;             
signal SDMA_TX_AddrLen_INC1                 : std_logic;                      
signal SDMA_TX_AddrLen_INC2                 : std_logic;             
signal SDMA_TX_AddrLen_INC3                 : std_logic;             
signal SDMA_TX_AddrLen_INC4                 : std_logic;             
signal SDMA_RX_Address                      : std_logic_vector(31 downto 0); 
signal SDMA_RX_Address_Reg                  : std_logic_vector(31 downto 0); 
signal SDMA_RX_Address_Load                 : std_logic;             
signal SDMA_RX_Length                       : std_logic_vector(31 downto 0); 
signal SDMA_RX_Length_Load                  : std_logic;             
signal SDMA_RX_AddrLen_INC1                 : std_logic;                      
signal SDMA_RX_AddrLen_INC2                 : std_logic;             
signal SDMA_RX_AddrLen_INC3                 : std_logic;             
signal SDMA_RX_AddrLen_INC4                 : std_logic;             

-- TX Status Register Signals                                                 
signal SDMA_TX_Status_Detect_Busy_Wr        : std_logic;             
signal SDMA_TX_Status_Detect_Tail_Ptr_Err   : std_logic;
signal SDMA_TX_Status_Detect_Curr_Ptr_Err   : std_logic;             
signal SDMA_TX_Status_Detect_Nxt_Ptr_Err    : std_logic;             
signal SDMA_TX_Status_Detect_Addr_Err       : std_logic;             
signal SDMA_TX_Status_Detect_Completed_Err  : std_logic;             
signal SDMA_TX_Status_Set_SDMA_Completed    : std_logic;             
signal SDMA_tx_status_setbusy               : std_logic;
signal SDMA_TX_Status_Detect_Stop           : std_logic;             
signal SDMA_TX_Status_Detect_Null_Ptr       : std_logic;             
signal SDMA_TX_Status_Mem_CE                : std_logic;             
signal SDMA_TX_Status_Out                   : std_logic_vector(0 to 31); 

-- RX Status Register Signals                                                
signal SDMA_RX_Status_Detect_Busy_Wr        : std_logic;             
signal SDMA_RX_Status_Detect_Tail_Ptr_Err   : std_logic;
signal SDMA_RX_Status_Detect_Curr_Ptr_Err   : std_logic;             
signal SDMA_RX_Status_Detect_Nxt_Ptr_Err    : std_logic;             
signal SDMA_RX_Status_Detect_Addr_Err       : std_logic;             
signal SDMA_RX_Status_Detect_Completed_Err  : std_logic;             
signal SDMA_RX_Status_Set_SDMA_Completed    : std_logic;             
signal SDMA_RX_Status_Set_Start_Of_Packet   : std_logic;             
signal SDMA_RX_Status_Set_End_Of_Packet     : std_logic;             
signal SDMA_rx_status_setbusy               : std_logic;
signal SDMA_RX_Status_Detect_Stop           : std_logic;             
signal SDMA_RX_Status_Detect_Null_Ptr       : std_logic;             
signal SDMA_RX_Status_Mem_CE                : std_logic;             
signal SDMA_RX_Status_Out                   : std_logic_vector(0 to 31); 

-- Channel Reset Signals                                                  
signal SDMA_TX_ChannelRST                   : std_logic;             
signal SDMA_RX_ChannelRST                   : std_logic;             
signal resetcomplete                        : std_logic;

-- TX Byte Shifter Controls                                            
signal SDMA_TX_Shifter_Byte_Sel0            : std_logic_vector(1 downto 0);  
signal SDMA_TX_Shifter_Byte_Sel1            : std_logic_vector(1 downto 0);  
signal SDMA_TX_Shifter_Byte_Sel2            : std_logic_vector(1 downto 0);  
signal SDMA_TX_Shifter_Byte_Sel3            : std_logic_vector(1 downto 0);  
signal SDMA_TX_Shifter_Byte_Reg_CE          : std_logic_vector(3 downto 0);  

-- RX Byte Shifter Controls                                                  
signal SDMA_RX_Shifter_HoldReg_CE           : std_logic;             
signal SDMA_RX_Shifter_Byte_Sel             : std_logic_vector(1 downto 0);  
signal SDMA_RX_Shifter_CE                   : std_logic_vector(7 downto 0);  

-- Additional Datapath Signals                                          
signal wrDataAck_Pos                        : std_logic;             
signal wrDataAck_Neg                        : std_logic;             
signal rdDataAck_Pos                        : std_logic;             
signal rdDataAck_Neg                        : std_logic;             
signal delay_reg_ce                         : std_logic;             
signal delay_reg_sel                        : std_logic_vector(1 downto 0);  

-- Internal MPMC2 Interface Signals
signal PI_AddrReq_i                         : std_logic;
signal PI_AddrAck_i                         : std_logic;
signal PI_WrFIFO_Push_i                     : std_logic;
signal PI_RdFIFO_Pop_i                      : std_logic;
signal PI_WrFIFO_Flush_i                    : std_logic;
signal PI_RdFIFO_Flush_i                    : std_logic;
signal pi_addrack_hold                      : std_logic;

-- Local Link Pipeline Register Signals
signal TX_Rem_i                             : std_logic_vector(3 downto 0); 
signal TX_SOF_i                             : std_logic;            
signal TX_SOP_i                             : std_logic;            
signal TX_EOP_i                             : std_logic;            
signal TX_EOF_i                             : std_logic;            
signal TX_Src_Rdy_i                         : std_logic;            

-- Channel Control Registers
signal SDMA_tx_control_reg                  : std_logic_vector(0 to 31);
signal SDMA_rx_control_reg                  : std_logic_vector(0 to 31);
signal SDMA_control_reg                     : std_logic_vector(0 to 31);

-- Clock Boundary Crossing Signals                                        
signal clk_pi_toggle                        : std_logic;            
signal clk_pi_toggle_d1                     : std_logic;            
signal clk_pi_toggle_edge                   : std_logic;            
signal clk_pi_count                         : std_logic_vector (1 downto 0);
signal clk_pi_enable                        : std_logic;

-- TailPointer Mode Support
signal SDMA_tx_curdesc_ptr                  : std_logic_vector(0 to 31);
signal SDMA_tx_taildesc_ptr                 : std_logic_vector(0 to 31);
signal SDMA_rx_curdesc_ptr                  : std_logic_vector(0 to 31);
signal SDMA_rx_taildesc_ptr                 : std_logic_vector(0 to 31);


signal ipic_control_reg_we                  : std_logic;
signal ipic_control_reg_re                  : std_logic;
signal ipic_tx_sts_reg_re                   : std_logic;
signal ipic_rx_sts_reg_re                   : std_logic;
signal ipic_tx_cntl_reg_we                  : std_logic;
signal ipic_rx_cntl_reg_we                  : std_logic;
signal ipic_tx_tailptr_reg_we               : std_logic;
signal ipic_rx_tailptr_reg_we               : std_logic;


-- IPIC Bus Interface
signal bus2ip_clk                           : std_logic;
signal bus2ip_reset                         : std_logic;
signal bus2ip_cs                            : std_logic_vector
                                                (0 to ((ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);   
signal bus2ip_rnw                           : std_logic;                                                
signal bus2ip_rdce                          : std_logic_vector
                                                (0 to NUM_CE-1);
signal bus2ip_wrce                          : std_logic_vector
                                                (0 to NUM_CE-1);
signal bus2ip_addr                          : std_logic_vector
                                                (0 to C_SPLB_AWIDTH-1);
signal bus2ip_data                          : std_logic_vector
                                                (0 to C_SPLB_NATIVE_DWIDTH-1);
signal ip2bus_data                          : std_logic_vector
                                                (0 to C_SPLB_NATIVE_DWIDTH-1);
signal ip2bus_wrack                         : std_logic;
signal ip2bus_rdack                         : std_logic;

signal llink_rst                            : std_logic;
signal pi_rst                               : std_logic;
signal pi_rst_d1                            : std_logic;
signal rst_d1                               : std_logic;

signal TX_D_i                               : std_logic_vector(31 downto 0);
signal RX_D_i                               : std_logic_vector(31 downto 0);
signal RX_Rem_i                             : std_logic_vector(3 downto 0);

signal sdma_rx_error_reset                  : std_logic;
signal sdma_tx_error_reset                  : std_logic;
signal sdma_ext_reset                       : std_logic;
signal early_pop_i			: std_logic;
signal PI_RdFIFO_Empty_i		: std_logic;
signal PI_RdFIFO_Empty_d1		: std_logic;
signal PI_RdFIFO_Empty_d2		: std_logic;
signal d_reg_ce				: std_logic;
signal early_pop_i_d1			: std_logic;
signal early_pop_i_d2			: std_logic;
signal early_pop_i_d3			: std_logic;
signal early_pop_i_d4			: std_logic;
signal early_pop_i_d5			: std_logic;
signal early_pop_i_d6			: std_logic;
signal PI_RdFIFO_Pop_temp		: std_logic;
-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

-------------------------------------------------------------------------------
--  Logic to create early pop for 32 bit operation
-------------------------------------------------------------------------------
    GEN_d_reg_ce_delay2_c1 : if ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) 
   				generate   
   
      process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              PI_rdfifo_empty_d1 <= '0';
 
            else
              PI_RdFIFO_Empty_d1 <= PI_RdFIFO_Empty;

            end if;
          end if;
    end process;
    

    
    early_pop_i <= (PI_RdFIFO_Empty_d1 and (not PI_RdFIFO_Empty)) ;  
 
 process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              early_pop_i_d1 <= '0';
              early_pop_i_d2 <= '0';
 	      early_pop_i_d3 <= '0';
 	      early_pop_i_d4 <= '0';
 	      early_pop_i_d5 <= '0';
 	      early_pop_i_d6 <= '0';
            else
              early_pop_i_d1 <= early_pop_i;
              early_pop_i_d2 <= early_pop_i_d1;
              early_pop_i_d3 <= early_pop_i_d2;
              early_pop_i_d4 <= early_pop_i_d3; 
              early_pop_i_d5 <= early_pop_i_d4;
              early_pop_i_d6 <= early_pop_i_d5; 

            end if;
          end if;
    end process; 
   
 end generate;  
   
   GEN_d_reg_ce_delay1_c1 : if ((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) 
   				generate   
   
      process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              PI_rdfifo_empty_d1 <= '0';
 
            else
              PI_RdFIFO_Empty_d1 <= PI_RdFIFO_Empty;

            end if;
          end if;
    end process;
    

    
    early_pop_i <= (PI_RdFIFO_Empty_d1 and (not PI_RdFIFO_Empty)) ;  
 
 process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              early_pop_i_d1 <= '0';
              early_pop_i_d2 <= '0';
 	      early_pop_i_d3 <= '0';
            else
              early_pop_i_d1 <= early_pop_i;
              early_pop_i_d2 <= early_pop_i_d1;
              early_pop_i_d3 <= early_pop_i_d2;

            end if;
          end if;
    end process; 
   
 end generate;  
   
   
   
   GEN_d_reg_ce_delay1_c2 : if ((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 2))
   		or ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2)) generate
   
  
process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              PI_rdfifo_empty_d1 <= '0';
              PI_RdFIFO_Empty_d2 <= '0';
 
            else
              PI_RdFIFO_Empty_d1 <= PI_RdFIFO_Empty;
		  PI_RdFIFO_Empty_d2 <= PI_RdFIFO_Empty_d1;
            end if;
          end if;
    end process;
    

    
    early_pop_i <= (PI_RdFIFO_Empty_d2 and (not PI_RdFIFO_Empty_d1)) ;  
 
 process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              early_pop_i_d1 <= '0';
              early_pop_i_d2 <= '0';
 	      early_pop_i_d3 <= '0';
            else
              early_pop_i_d1 <= early_pop_i;
              early_pop_i_d2 <= early_pop_i_d1;
              early_pop_i_d3 <= early_pop_i_d2;

            end if;
          end if;
    end process;
 
 end generate;
 
 
 GEN_d_reg_ce_delay0_c2 : if ((C_PI_RDDATA_DELAY = 0) and (C_PI2LL_CLK_RATIO = 2)) 
             		generate
 process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              PI_rdfifo_empty_d1 <= '0';
 		PI_RdFIFO_Empty_d2 <= '0';
  
             else
               PI_RdFIFO_Empty_d1 <= PI_RdFIFO_Empty;
		  PI_RdFIFO_Empty_d2 <= PI_RdFIFO_Empty_d1;
            
            end if;
          end if;
    end process;
    

    
    early_pop_i <= (PI_RdFIFO_Empty_d2 and (not PI_RdFIFO_Empty_d1)) ;   
  
end generate;

GEN_d_reg_ce_delay0_c1 : if ((C_PI_RDDATA_DELAY = 0) and (C_PI2LL_CLK_RATIO = 1)) 
                    generate
 process(LLink_Clk)
     begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
              PI_rdfifo_empty_d1 <= '0';
  
             else
               PI_RdFIFO_Empty_d1 <= PI_RdFIFO_Empty;
            
            end if;
          end if;
    end process;
    

    
    early_pop_i <= (PI_RdFIFO_Empty_d1 and (not PI_RdFIFO_Empty)) ;   
  
end generate;
SDMA_RstOut             <= sdma_ext_reset;

-- Re-Label Bits to Match Hard DMA and XPS_LL_TEMAC to avoid confusion
TX_D(0 to 31)           <= TX_D_i(31 downto 0);     -- Re-Label Bits
RX_D_i(31 downto 0)     <= RX_D(0 to 31);           -- Re-Label Bits
RX_Rem_i                <= RX_Rem(0 to 3);          -- Re-Label Bits
-------------------------------------------------------------------------------
-- Handle Clocking Boundaries
-------------------------------------------------------------------------------
SYNC_RESET2LLINK : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            rst_d1      <= SPLB_Rst;
            llink_rst   <= rst_d1;
        end if;
    end process SYNC_RESET2LLINK;
           
SYNC_RESET2PI   : process(PI_Clk)
    begin
        if(PI_Clk'EVENT and PI_Clk='1')then
            pi_rst_d1   <= SPLB_Rst;
            pi_rst      <= pi_rst_d1;
        end if;
    end process SYNC_RESET2PI;

GEN_CLK_RATIO_2 : if C_PI2LL_CLK_RATIO =2 generate
        PI_CLOCK_PROCESS : process(LLink_Clk)
            begin
                if(LLink_Clk'EVENT and LLink_Clk='1')then
                    if(llink_rst='1')then
                        clk_pi_toggle <= '0';
                    else
                        clk_pi_toggle <= not clk_pi_toggle;
                    end if;
                end if;
            end process PI_CLOCK_PROCESS;


        PI_MPMC2_CLOCK_PROCESS : process(PI_CLK)
            begin
                if(PI_CLK'EVENT and PI_CLK='1')then
                    if(pi_rst='1')then
                        clk_pi_toggle_d1 <= '0';
                    else
                        clk_pi_toggle_d1 <= clk_pi_toggle;
                    end if;
                end if;
            end process PI_MPMC2_CLOCK_PROCESS;

        clk_pi_toggle_edge <= clk_pi_toggle xor clk_pi_toggle_d1;     

        PI_COUNT_PROCESS : process(PI_CLK)
            begin
                if(PI_CLK'EVENT and PI_CLK='1')then
                    if(pi_rst='1' or clk_pi_toggle_edge='1')then
                        clk_pi_count <= (others => '0');
                    else
                        clk_pi_count(0) <= not(clk_pi_count(0));
                    end if;
                end if;
            end process PI_COUNT_PROCESS;

        clk_pi_enable <= not(clk_pi_count(0));


    end generate GEN_CLK_RATIO_2;
   
-- Slow DCR -> Fast MPMC2 PI Boundary
GEN_CLK_RATIO_GRTR_2 : if C_PI2LL_CLK_RATIO > 2 generate

        PI_CLOCK_PROCESS : process(LLink_Clk)
            begin
                if(LLink_Clk'EVENT and LLink_Clk='1')then
                    if(LLink_Rst='1')then
                        clk_pi_toggle <= '0';
                    else
                        clk_pi_toggle <= not clk_pi_toggle;
                    end if;
                end if;
            end process PI_CLOCK_PROCESS;
            
        PI_MPMC2_CLOCK_PROCESS : process(PI_CLK)
            begin
                if(PI_CLK'EVENT and PI_CLK='1')then
                    if(pi_rst='1')then
                        clk_pi_toggle_d1 <= '0';
                    else
                        clk_pi_toggle_d1 <= clk_pi_toggle;
                    end if;
                end if;
            end process PI_MPMC2_CLOCK_PROCESS;
            
        clk_pi_toggle_edge <= clk_pi_toggle xor clk_pi_toggle_d1;     

        PI_COUNT_PROCESS : process(PI_CLK)
            begin
                if(PI_CLK'EVENT and PI_CLK='1')then
                    if(pi_rst='1' or clk_pi_toggle_edge='1')then
                        clk_pi_count <= (others => '0');
                    else
                        clk_pi_count <= std_logic_vector(unsigned(clk_pi_count) + 1);
                    end if;
                end if;
            end process PI_COUNT_PROCESS;

        clk_pi_enable <= '1' when clk_pi_count = std_logic_vector(
                                                 to_unsigned(
                                                 C_PI2LL_CLK_RATIO-2,2))
                    else '0';
    
end generate GEN_CLK_RATIO_GRTR_2;

FAST_MPMC2_NO_CROSS : if C_PI2LL_CLK_RATIO = 1 generate
    clk_pi_enable <= '1';
end generate FAST_MPMC2_NO_CROSS;

-------------------------------------------------------------------------------
-- Address Path Clock Boundary Crossing
-------------------------------------------------------------------------------
ADDR_CROSS : if C_PI2LL_CLK_RATIO > 1 generate
--    PI_AddrReq      <= PI_AddrReq_i and not(pi_addrack_hold);
    PI_AddrAck_i    <= PI_AddrAck or pi_addrack_hold;    

    ADDRACK_HOLD : process(PI_CLK)  
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1' or clk_pi_enable = '1')then
                    pi_addrack_hold <= '0';
                elsif(PI_AddrAck = '1')then
                    pi_addrack_hold <= '1';
                end if;
            end if;
        end process ADDRACK_HOLD;

    REG_REQ : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1' or PI_AddrAck_i = '1')then
                    PI_AddrReq <= '0';
                elsif(PI_AddrReq_i = '1')then
                    PI_AddrReq <= '1';
                end if;
            end if;
        end process REG_REQ;

end generate ADDR_CROSS;

ADDR_NO_CROSS  : if C_PI2LL_CLK_RATIO = 1 generate
--      PI_AddrReq    <= PI_AddrReq_i;
      PI_AddrAck_i  <= PI_AddrAck;

    REG_REQ : process(PI_Clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1' or PI_AddrAck = '1')then
                    PI_AddrReq <= '0';
                elsif(PI_AddrReq_i = '1')then
                    PI_AddrReq <= '1';
                end if;
            end if;
        end process REG_REQ;



end generate ADDR_NO_CROSS;


-------------------------------------------------------------------------------
-- Data Path Clock Boundary Crossing
-------------------------------------------------------------------------------
DATA_CROSS_d2_c1 : if (C_PI2LL_CLK_RATIO = 1 and C_PI_RDDATA_DELAY = 2) generate

        PI_WrFIFO_Push  <= PI_WrFIFO_Push_i;
        PI_RdFIFO_Pop   <= (PI_RdFIFO_Pop_i or early_pop_i or early_pop_i_d1 or early_pop_i_d4) and not PI_RdFIFO_Empty;
        --mgg added early pops and qualified with empty so as not to underflow
        -- the rdfifo
        PI_WrFIFO_Flush <= PI_WrFIFO_Flush_i;
    PI_RdFIFO_Flush <= PI_RdFIFO_Flush_i;
    
end generate DATA_CROSS_d2_c1;


DATA_CROSS : if (C_PI2LL_CLK_RATIO > 1 and C_PI_RDDATA_DELAY = 0) generate

    PI_WrFIFO_Push  <= PI_WrFIFO_Push_i  and clk_pi_enable;
--    PI_RdFIFO_Pop   <= PI_RdFIFO_Pop_i   and clk_pi_enable;


    S_H_FLUSH : process(PI_clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1')then
                    PI_WrFIFO_Flush <= '0';
                    PI_RdFIFO_Flush <= '0';
                elsif(clk_pi_enable='1')then
                    PI_WrFIFO_Flush <= PI_WrFIFO_Flush_i;
                    PI_RdFIFO_Flush <= PI_RdFIFO_Flush_i;
                end if;
            end if;
        end process S_H_FLUSH;

   REG_POP_PROCESS : process(PI_clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1')then
                    PI_RdFIFO_Pop_temp   <= '0';
                else
                    PI_RdFIFO_Pop_temp   <= ((PI_RdFIFO_Pop_i or early_pop_i) and not clk_pi_enable )  ; 
                    -- added PI_RdFIFO_Empty as qualifier because PI_RdFIFO_Empty 
                    -- is delayed by 1 clock cycle going into SDMA and there is no
                    -- other way to inhibit the last pop which is extra due
                    -- to the fact that we are creating an early pop
                end if;
            end if;
        end process REG_POP_PROCESS;

   PI_RdFIFO_Pop   <= PI_RdFIFO_Pop_temp and not PI_RdFIFO_Empty;
end generate DATA_CROSS;

DATA_CROSS_d1_c2 : if (C_PI2LL_CLK_RATIO > 1 and C_PI_RDDATA_DELAY = 1) generate

    PI_WrFIFO_Push  <= PI_WrFIFO_Push_i  and clk_pi_enable;
--    PI_RdFIFO_Pop   <= PI_RdFIFO_Pop_i   and clk_pi_enable;


    S_H_FLUSH : process(PI_clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1')then
                    PI_WrFIFO_Flush <= '0';
                    PI_RdFIFO_Flush <= '0';
                elsif(clk_pi_enable='1')then
                    PI_WrFIFO_Flush <= PI_WrFIFO_Flush_i;
                    PI_RdFIFO_Flush <= PI_RdFIFO_Flush_i;
                end if;
            end if;
        end process S_H_FLUSH;

   REG_POP_PROCESS : process(PI_clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1')then
                    PI_RdFIFO_Pop_temp   <= '0';
                else
                    PI_RdFIFO_Pop_temp   <= ((PI_RdFIFO_Pop_i or early_pop_i) and not clk_pi_enable) ; 
                    -- added PI_RdFIFO_Empty as qualifier because PI_RdFIFO_Empty 
                    -- is delayed by 1 clock cycle going into SDMA and there is no
                    -- other way to inhibit the last pop which is extra due
                    -- to the fact that we are creating an early pop
                end if;
            end if;
        end process REG_POP_PROCESS;

   PI_RdFIFO_Pop <= PI_RdFIFO_Pop_temp and not PI_RdFIFO_Empty;
   
end generate DATA_CROSS_d1_c2;

DATA_CROSS_d2_c2 : if (C_PI2LL_CLK_RATIO = 2 and C_PI_RDDATA_DELAY = 2) generate

    PI_WrFIFO_Push  <= PI_WrFIFO_Push_i  and clk_pi_enable;
--    PI_RdFIFO_Pop   <= PI_RdFIFO_Pop_i   and clk_pi_enable;


    S_H_FLUSH : process(PI_clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1')then
                    PI_WrFIFO_Flush <= '0';
                    PI_RdFIFO_Flush <= '0';
                elsif(clk_pi_enable='1')then
                    PI_WrFIFO_Flush <= PI_WrFIFO_Flush_i;
                    PI_RdFIFO_Flush <= PI_RdFIFO_Flush_i;
                end if;
            end if;
        end process S_H_FLUSH;

   REG_POP_PROCESS : process(PI_clk)
        begin
            if(PI_Clk'EVENT and PI_Clk='1')then
                if(pi_rst = '1')then
                    PI_RdFIFO_Pop_temp   <= '0';
                else
                    PI_RdFIFO_Pop_temp   <= ((PI_RdFIFO_Pop_i or early_pop_i  or early_pop_i_d2) and not clk_pi_enable) ; 
                    -- added PI_RdFIFO_Empty as qualifier because PI_RdFIFO_Empty 
                    -- is delayed by 1 clock cycle going into SDMA and there is no
                    -- other way to inhibit the last pop which is extra due
                    -- to the fact that we are creating an early pop
                end if;
            end if;
        end process REG_POP_PROCESS;

   PI_RdFIFO_Pop <= PI_RdFIFO_Pop_temp and not PI_RdFIFO_Empty;
   
end generate DATA_CROSS_d2_c2;

DATA_NO_CROSS : if (C_PI2LL_CLK_RATIO = 1 and C_PI_RDDATA_DELAY = 1)
		generate

    PI_WrFIFO_Push  <= PI_WrFIFO_Push_i;
    PI_RdFIFO_Pop   <= (PI_RdFIFO_Pop_i or early_pop_i or early_pop_i_d2) and not PI_RdFIFO_Empty;
    --mgg added early pops and qualified with empty so as not to underflow
    -- the rdfifo
    PI_WrFIFO_Flush <= PI_WrFIFO_Flush_i;
    PI_RdFIFO_Flush <= PI_RdFIFO_Flush_i;



end generate DATA_NO_CROSS;

DATA_NO_CROSS_d0 : if (C_PI2LL_CLK_RATIO = 1 and C_PI_RDDATA_DELAY = 0) generate

    PI_WrFIFO_Push  <= PI_WrFIFO_Push_i;
    PI_RdFIFO_Pop   <= (PI_RdFIFO_Pop_i or early_pop_i) ;
    --mgg added early pops and qualified with empty so as not to underflow
    -- the rdfifo
    PI_WrFIFO_Flush <= PI_WrFIFO_Flush_i;
    PI_RdFIFO_Flush <= PI_RdFIFO_Flush_i;



end generate DATA_NO_CROSS_d0;

EMPTY_CROSS : if ( C_PI2LL_CLK_RATIO = 1 and C_PI_RDDATA_DELAY = 1 )
		or ( C_PI2LL_CLK_RATIO = 2 and C_PI_RDDATA_DELAY = 0 ) generate
    RDFIFO_EMPTY : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst = '1')then
                    PI_RdFIFO_Empty_i <= '0';
                else
                  PI_RdFIFO_Empty_i <= PI_RdFIFO_Empty; -- delaying empty 
                  --so as to have time to do early pop and still have all 
                  --other logic timed correctly
                end if;
            end if;
        end process RDFIFO_EMPTY;
end generate EMPTY_CROSS;

EMPTY_CROSS_d2_c2 : if (C_PI_RDDATA_DELAY = 2 and C_PI2LL_CLK_RATIO = 2) generate
    RDFIFO_EMPTY : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst = '1')then
                    PI_RdFIFO_Empty_i <= '0';
                else
                  PI_RdFIFO_Empty_i <= PI_RdFIFO_Empty_d1; -- delaying empty 
                  --so as to have time to do early pop and still have all 
                  --other logic timed correctly
                end if;
            end if;
        end process RDFIFO_EMPTY;
end generate EMPTY_CROSS_d2_c2;

EMPTY_CROSS_d2_c1 : if (C_PI_RDDATA_DELAY = 2 and C_PI2LL_CLK_RATIO = 1) generate
    RDFIFO_EMPTY : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst = '1')then
                    PI_RdFIFO_Empty_i <= '0';
                else
                  PI_RdFIFO_Empty_i <= PI_RdFIFO_Empty_d1; -- delaying empty 
                  --so as to have time to do early pop and still have all 
                  --other logic timed correctly
                end if;
            end if;
        end process RDFIFO_EMPTY;
end generate EMPTY_CROSS_d2_c1;

EMPTY_CROSS_d1_c2 : if ( C_PI2LL_CLK_RATIO = 2 and C_PI_RDDATA_DELAY = 1 ) generate
    RDFIFO_EMPTY : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst = '1')then
                    PI_RdFIFO_Empty_i <= '0';
                else
                  PI_RdFIFO_Empty_i <= PI_RdFIFO_Empty; -- delaying empty 
                  --so as to have time to do early pop and still have all 
                  --other logic timed correctly
                end if;
            end if;
        end process RDFIFO_EMPTY;
end generate EMPTY_CROSS_d1_c2;

EMPTY_NO_CROSS : if (C_PI2LL_CLK_RATIO = 1 and C_PI_RDDATA_DELAY < 1) generate
    PI_RdFIFO_Empty_i <= PI_RdFIFO_Empty; -- delaying empty 
                  --so as to have time to do early pop and still have all 
                  --other logic timed correctly
end generate EMPTY_NO_CROSS;


-------------------------------------------------------------------------------
-- Local Link Pipeline Registers
-------------------------------------------------------------------------------
LLINK_REG : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk = '1')then
            if(LLink_Rst='1')then
                TX_SOF      <= '1';
                TX_SOP      <= '1';
                TX_EOP      <= '1';
                TX_EOF      <= '1';
                TX_Src_Rdy  <= '1';
                TX_Rem      <= "1111";
            elsif(TX_Dst_Rdy='0')then
                TX_SOF      <= TX_SOF_i;
                TX_SOP      <= TX_SOP_i;
                TX_EOP      <= TX_EOP_i;
                TX_EOF      <= TX_EOF_i;
                TX_Src_Rdy  <= TX_Src_Rdy_i;
                TX_Rem      <= TX_Rem_i;
            end if;
        end if;
    end process LLINK_REG;

             
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
DMA_CONTROL_I : entity mpmc_v6_03_a.sdma_cntl
    generic map(
        C_COMPLETED_ERR_TX      => C_COMPLETED_ERR_TX       ,
        C_COMPLETED_ERR_RX      => C_COMPLETED_ERR_RX       ,      
        C_PI_BASEADDR           => C_PI_BASEADDR            ,
        C_PI_HIGHADDR           => C_PI_HIGHADDR            ,
        C_INSTANTIATE_TIMER_TX  => INSTANTIATE_TIMER_TX     ,
        C_INSTANTIATE_TIMER_RX  => INSTANTIATE_TIMER_RX     ,
        C_PRESCALAR             => C_PRESCALAR              ,
        C_PI_RDDATA_DELAY       => C_PI_RDDATA_DELAY        ,
        C_PI2LL_CLK_RATIO       => C_PI2LL_CLK_RATIO        ,
        C_NUM_CE                => NUM_CE                   ,
        C_SPLB_AWIDTH           => C_SPLB_AWIDTH            ,
        C_SPLB_NATIVE_DWIDTH    => C_SPLB_NATIVE_DWIDTH     ,
        C_FAMILY                => C_FAMILY     

    )
    port map(
        LLink_Clk                           => LLink_Clk                            ,
        LLink_Rst                           => LLink_Rst                            ,

        -- IPIC Interface                                                        
        Bus2IP_Clk                          => SPLB_Clk                           ,       
        Bus2IP_Reset                        => bus2ip_reset                         ,       
        Bus2IP_CS                           => bus2ip_cs(0)                         ,
        Bus2IP_RNW                          => bus2ip_rnw                           ,
        Bus2IP_Addr                         => bus2ip_addr                          ,     
        Bus2IP_Data                         => bus2ip_data                          ,     
        Bus2IP_RdCE                         => bus2ip_rdce                          ,
        Bus2IP_WrCE                         => bus2ip_wrce                          ,        
        IP2Bus_Data                         => ip2bus_data                          ,     
        IP2Bus_WrAck                        => ip2bus_wrack                         ,     
        IP2Bus_RdAck                        => ip2bus_rdack                         ,     

        -- MPMC Port Interface                                                  
        PI_Addr                             => PI_Addr                              ,
        PI_AddrReq                          => PI_AddrReq_i                         ,
        PI_AddrAck                          => PI_AddrAck_i                         ,
        PI_RdModWr                          => PI_RdModWr                           ,
        PI_RNW                              => PI_RNW                               ,
        PI_Size                             => PI_Size                              ,
        PI_WrFIFO_BE                        => PI_WrFIFO_BE                         ,
        PI_WrFIFO_Push                      => PI_WrFIFO_Push_i                     ,
        PI_RdFIFO_Pop                       => PI_RdFIFO_Pop_i                      ,
        PI_RdFIFO_RdWdAddr                  => PI_RdFIFO_RdWdAddr                   ,
        PI_WrFIFO_AlmostFull                => PI_WrFIFO_AlmostFull                 ,
        PI_WrFIFO_Empty                     => PI_WrFIFO_Empty                      ,
        PI_WrFIFO_Flush                     => PI_WrFIFO_Flush_i                    ,
        PI_RdFIFO_DataAvailable             => PI_RdFIFO_DataAvailable              ,
        PI_RdFIFO_Empty                     => PI_RdFIFO_Empty_i                    ,
        PI_RdFIFO_Flush                     => PI_RdFIFO_Flush_i                    ,

        -- TX LL                                                                
        TX_Rem                              => TX_Rem_i                             ,
        TX_SOF                              => TX_SOF_i                             ,
        TX_EOF                              => TX_EOF_i                             ,
        TX_SOP                              => TX_SOP_i                             ,
        TX_EOP                              => TX_EOP_i                             ,
        TX_Src_Rdy                          => TX_Src_Rdy_i                         ,
        TX_Dst_Rdy                          => TX_Dst_Rdy                           ,

        -- RX LL                                                               
        RX_Rem                              => RX_Rem_i                             ,
        RX_SOF                              => RX_SOF                               ,
        RX_EOF                              => RX_EOF                               ,
        RX_SOP                              => RX_SOP                               ,
        RX_EOP                              => RX_EOP                               ,
        RX_Src_Rdy                          => RX_Src_Rdy                           ,
        RX_Dst_Rdy                          => RX_Dst_Rdy                           ,

        -- CPU Interrupt Signal                                                 
        SDMA_Rx_IntOut                      => SDMA_Rx_IntOut                       ,
        SDMA_Tx_IntOut                      => SDMA_Tx_IntOut                       ,   

        -- IPIC Data Buses
        IPIC_WrDBus                         => ipic_wrdbus                          ,
        IPIC_RdDBus                         => ipic_rddbus                          ,

        -- Data Bus Select Signals                                              
        SDMA_Sel_AddrLen                    => SDMA_Sel_AddrLen                     ,
        SDMA_Sel_Data_Src                   => SDMA_Sel_Data_Src                    ,
        SDMA_Sel_PI_rdData_Pos              => SDMA_Sel_PI_rdData_Pos               ,
        SDMA_Sel_Status_Writeback           => SDMA_Sel_Status_Writeback            ,

        -- Register File Controls                                                   
        SDMA_RegFile_WE                     => SDMA_RegFile_WE                      ,
        SDMA_RegFile_Sel_Eng                => SDMA_RegFile_Sel_Eng                 ,
        SDMA_RegFile_Sel_Reg                => SDMA_RegFile_Sel_Reg                 ,

        -- Counter Signals                                                      
        SDMA_TX_Address                     => SDMA_TX_Address                      ,
        SDMA_TX_Address_Load                => SDMA_TX_Address_Load                 ,
        SDMA_TX_Length                      => SDMA_TX_Length                       ,
        SDMA_TX_Length_Load                 => SDMA_TX_Length_Load                  ,
        SDMA_TX_AddrLen_INC1                => SDMA_TX_AddrLen_INC1                 ,
        SDMA_TX_AddrLen_INC2                => SDMA_TX_AddrLen_INC2                 ,
        SDMA_TX_AddrLen_INC3                => SDMA_TX_AddrLen_INC3                 ,
        SDMA_TX_AddrLen_INC4                => SDMA_TX_AddrLen_INC4                 ,
        SDMA_RX_Address                     => SDMA_RX_Address                      ,
        SDMA_RX_Address_Reg                 => SDMA_RX_Address_Reg                  ,
        SDMA_RX_Address_Load                => SDMA_RX_Address_Load                 ,
        SDMA_RX_Length                      => SDMA_RX_Length                       ,
        SDMA_RX_Length_Load                 => SDMA_RX_Length_Load                  ,
        SDMA_RX_AddrLen_INC1                => SDMA_RX_AddrLen_INC1                 ,
        SDMA_RX_AddrLen_INC2                => SDMA_RX_AddrLen_INC2                 ,
        SDMA_RX_AddrLen_INC3                => SDMA_RX_AddrLen_INC3                 ,
        SDMA_RX_AddrLen_INC4                => SDMA_RX_AddrLen_INC4                 ,

        -- TX Status Register Signals
        SDMA_TX_Status_Detect_Busy_Wr       => SDMA_TX_Status_Detect_Busy_Wr        ,  
        SDMA_TX_Status_Detect_Tail_Ptr_Err  => SDMA_TX_Status_Detect_Tail_Ptr_Err   ,
        SDMA_TX_Status_Detect_Curr_Ptr_Err  => SDMA_TX_Status_Detect_Curr_Ptr_Err   ,
        SDMA_TX_Status_Detect_Nxt_Ptr_Err   => SDMA_TX_Status_Detect_Nxt_Ptr_Err    ,
        SDMA_TX_Status_Detect_Addr_Err      => SDMA_TX_Status_Detect_Addr_Err       ,
        SDMA_TX_Status_Detect_Completed_Err => SDMA_TX_Status_Detect_Completed_Err  ,
        SDMA_TX_Status_Set_SDMA_Completed   => SDMA_TX_Status_Set_SDMA_Completed    ,
        SDMA_TX_Status_SetBusy              => SDMA_tx_status_setbusy               ,
        SDMA_TX_Status_Detect_Stop          => SDMA_TX_Status_Detect_Stop           ,
        SDMA_TX_Status_Detect_Null_Ptr      => SDMA_TX_Status_Detect_Null_Ptr       ,
        SDMA_TX_Status_Mem_CE               => SDMA_TX_Status_Mem_CE                ,
        SDMA_TX_Status_Out                  => SDMA_TX_Status_Out                   ,
                                                                                    
        -- RX0 Status Register Signals                                              
        SDMA_RX_Status_Detect_Busy_Wr       => SDMA_RX_Status_Detect_Busy_Wr        ,
        SDMA_RX_Status_Detect_Tail_Ptr_Err  => SDMA_RX_Status_Detect_Tail_Ptr_Err   ,
        SDMA_RX_Status_Detect_Curr_Ptr_Err  => SDMA_RX_Status_Detect_Curr_Ptr_Err   ,
        SDMA_RX_Status_Detect_Nxt_Ptr_Err   => SDMA_RX_Status_Detect_Nxt_Ptr_Err    ,
        SDMA_RX_Status_Detect_Addr_Err      => SDMA_RX_Status_Detect_Addr_Err       ,
        SDMA_RX_Status_Detect_Completed_Err => SDMA_RX_Status_Detect_Completed_Err  ,
        SDMA_RX_Status_Set_SDMA_Completed   => SDMA_RX_Status_Set_SDMA_Completed    ,
        SDMA_RX_Status_Set_Start_Of_Packet  => SDMA_RX_Status_Set_Start_Of_Packet   ,
        SDMA_RX_Status_Set_End_Of_Packet    => SDMA_RX_Status_Set_End_Of_Packet     ,
        SDMA_RX_Status_SetBusy              => SDMA_rx_status_setbusy               ,
        SDMA_RX_Status_Detect_Stop          => SDMA_RX_Status_Detect_Stop           ,
        SDMA_RX_Status_Detect_Null_Ptr      => SDMA_RX_Status_Detect_Null_Ptr       ,
        SDMA_RX_Status_Mem_CE               => SDMA_RX_Status_Mem_CE                ,
        SDMA_RX_Status_Out                  => SDMA_RX_Status_Out                   ,

        -- TailPointer Mode Support
        SDMA_TX_CurDesc_Ptr                 => SDMA_tx_curdesc_ptr                  ,
        SDMA_TX_TailDesc_Ptr                => SDMA_tx_taildesc_ptr                 ,
        SDMA_RX_CurDesc_Ptr                 => SDMA_rx_curdesc_ptr                  ,
        SDMA_RX_TailDesc_Ptr                => SDMA_rx_taildesc_ptr                 ,
        IPIC_Control_Reg_WE                 => ipic_control_reg_we                  ,
        IPIC_Control_Reg_RE                 => ipic_control_reg_re                  ,
        IPIC_TX_Cntl_Reg_WE                 => ipic_tx_cntl_reg_we                  ,
        IPIC_RX_Cntl_Reg_WE                 => ipic_rx_cntl_reg_we                  ,
        IPIC_TX_Sts_Reg_RE                  => ipic_tx_sts_reg_re                   ,    
        IPIC_RX_Sts_Reg_RE                  => ipic_rx_sts_reg_re                   ,
        IPIC_TX_TailPtr_Reg_WE              => ipic_tx_tailptr_reg_we               ,
        IPIC_RX_TailPtr_Reg_WE              => ipic_rx_tailptr_reg_we               ,
        

        -- Channel Reset Signals                                                    
        SDMA_TX_ChannelRST                  => SDMA_TX_ChannelRST                   ,
        SDMA_RX_ChannelRST                  => SDMA_RX_ChannelRST                   ,
        ResetComplete                       => resetcomplete                        ,
        SDMA_RX_Error_Reset                 => sdma_rx_error_reset                  ,
        SDMA_TX_Error_Reset                 => sdma_tx_error_reset                  ,
        SDMA_Ext_Reset                      => sdma_ext_reset                       ,
    

        -- TX Byte Shifter Controls                                                 
        SDMA_TX_Shifter_Byte_Sel0           => SDMA_TX_Shifter_Byte_Sel0            ,
        SDMA_TX_Shifter_Byte_Sel1           => SDMA_TX_Shifter_Byte_Sel1            ,
        SDMA_TX_Shifter_Byte_Sel2           => SDMA_TX_Shifter_Byte_Sel2            ,
        SDMA_TX_Shifter_Byte_Sel3           => SDMA_TX_Shifter_Byte_Sel3            ,
        SDMA_TX_Shifter_Byte_Reg_CE         => SDMA_TX_Shifter_Byte_Reg_CE          ,

        -- RX Byte Shifter Controls                                                         
        SDMA_RX_Shifter_HoldReg_CE          => SDMA_RX_Shifter_HoldReg_CE           ,
        SDMA_RX_Shifter_Byte_Sel            => SDMA_RX_Shifter_Byte_Sel             ,
        SDMA_RX_Shifter_CE                  => SDMA_RX_Shifter_CE                   ,

        SDMA_TX_Control_Reg                 => SDMA_tx_control_reg                  ,
        SDMA_RX_Control_Reg                 => SDMA_rx_control_reg                  ,
        SDMA_Control_Reg                    => SDMA_control_reg                     ,
        
        -- 32-bit signals
        d_reg_ce => d_reg_ce,
        
                                                                                 
        -- Additional Datapath Signals                                              
        wrDataAck_Pos                       => wrDataAck_Pos                        ,
        wrDataAck_Neg                       => wrDataAck_Neg                        ,
        rdDataAck_Pos                       => rdDataAck_Pos                        ,
        rdDataAck_Neg                       => rdDataAck_Neg                        ,
        delay_reg_ce                        => delay_reg_ce                         ,
        delay_reg_sel                       => delay_reg_sel                        
    );

-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
DMA_DATA_I : entity mpmc_v6_03_a.sdma_datapath
    generic map(
        C_INSTANTIATE_TIMER_TX              => INSTANTIATE_TIMER_TX                 ,
        C_INSTANTIATE_TIMER_RX              => INSTANTIATE_TIMER_RX                 ,
        C_PI_RDDATA_DELAY                   => C_PI_RDDATA_DELAY                    ,
        C_PI2LL_CLK_RATIO                   => C_PI2LL_CLK_RATIO
    )
    port map(
      PI_clk                                => PI_clk                               ,
      LLink_Clk                             => LLink_Clk                            ,                         
      LLink_Rst                             => LLink_Rst                            ,

      -- Port Interface Data Buses                                            
      PI_WrFIFO_Data                        => PI_WrFIFO_Data                       ,
      PI_RdFIFO_Data                        => PI_RdFIFO_Data                       ,

      -- TX Local Link Data Bus                                                     
      TX_D                                  => TX_D_i                               ,

      -- RX Local Link Data Bus                                                     
      RX_D                                  => RX_D_i                               ,

      -- DATAPATH CONTROL SIGNALS                                                   
      -- DCR Data Buses                                                             
      IPIC_WrDBus                           => ipic_wrdbus                          ,
      IPIC_RdDBus                           => ipic_rddbus                          ,
      -- Data Bus Select Signals                                                    
      SDMA_Sel_AddrLen                      => SDMA_Sel_AddrLen                     ,
      SDMA_Sel_Data_Src                     => SDMA_Sel_Data_Src                    ,
      SDMA_Sel_PI_rdData_Pos                => SDMA_Sel_PI_rdData_Pos               ,
      SDMA_Sel_Status_Writeback             => SDMA_Sel_Status_Writeback            ,
      -- Register File Controls                                                             
      SDMA_RegFile_WE                       => SDMA_RegFile_WE                      ,
      SDMA_RegFile_Sel_Eng                  => SDMA_RegFile_Sel_Eng                 ,
      SDMA_RegFile_Sel_Reg                  => SDMA_RegFile_Sel_Reg                 ,
      -- Counter Signals                                                                    
      SDMA_TX_Address                       => SDMA_TX_Address                      ,
      SDMA_TX_Address_Load                  => SDMA_TX_Address_Load                 ,
      SDMA_TX_Length                        => SDMA_TX_Length                       ,
      SDMA_TX_Length_Load                   => SDMA_TX_Length_Load                  ,
      SDMA_TX_AddrLen_INC1                  => SDMA_TX_AddrLen_INC1                 ,
      SDMA_TX_AddrLen_INC2                  => SDMA_TX_AddrLen_INC2                 ,
      SDMA_TX_AddrLen_INC3                  => SDMA_TX_AddrLen_INC3                 ,
      SDMA_TX_AddrLen_INC4                  => SDMA_TX_AddrLen_INC4                 ,
      SDMA_RX_Address                       => SDMA_RX_Address                      ,
      SDMA_RX_Address_Reg                   => SDMA_RX_Address_Reg                  ,
      SDMA_RX_Address_Load                  => SDMA_RX_Address_Load                 ,
      SDMA_RX_Length                        => SDMA_RX_Length                       ,
      SDMA_RX_Length_Load                   => SDMA_RX_Length_Load                  ,
      SDMA_RX_AddrLen_INC1                  => SDMA_RX_AddrLen_INC1                 ,
      SDMA_RX_AddrLen_INC2                  => SDMA_RX_AddrLen_INC2                 ,
      SDMA_RX_AddrLen_INC3                  => SDMA_RX_AddrLen_INC3                 ,
      SDMA_RX_AddrLen_INC4                  => SDMA_RX_AddrLen_INC4                 ,
      -- TX Status Register Signals                                                         
      SDMA_TX_Status_Detect_Busy_Wr         => SDMA_TX_Status_Detect_Busy_Wr        ,
      SDMA_TX_Status_Detect_Tail_Ptr_Err    => SDMA_TX_Status_Detect_Tail_Ptr_Err   ,
      SDMA_TX_Status_Detect_Curr_Ptr_Err    => SDMA_TX_Status_Detect_Curr_Ptr_Err   ,
      SDMA_TX_Status_Detect_Nxt_Ptr_Err     => SDMA_TX_Status_Detect_Nxt_Ptr_Err    ,
      SDMA_TX_Status_Detect_Addr_Err        => SDMA_TX_Status_Detect_Addr_Err       ,
      SDMA_TX_Status_Detect_Completed_Err   => SDMA_TX_Status_Detect_Completed_Err  ,
      SDMA_TX_Status_Set_SDMA_Completed     => SDMA_TX_Status_Set_SDMA_Completed    ,
      SDMA_TX_Status_SetBusy                => SDMA_tx_status_setbusy               ,
      SDMA_TX_Status_Detect_Stop            => SDMA_TX_Status_Detect_Stop           ,
      SDMA_TX_Status_Detect_Null_Ptr        => SDMA_TX_Status_Detect_Null_Ptr       ,
      SDMA_TX_Status_Mem_CE                 => SDMA_TX_Status_Mem_CE                ,
      SDMA_TX_Status_Out                    => SDMA_TX_Status_Out                   ,
      -- RX Status Register Signals                                                         
      SDMA_RX_Status_Detect_Busy_Wr         => SDMA_RX_Status_Detect_Busy_Wr        ,
      SDMA_RX_Status_Detect_Tail_Ptr_Err    => SDMA_RX_Status_Detect_Tail_Ptr_Err   ,
      SDMA_RX_Status_Detect_Curr_Ptr_Err    => SDMA_RX_Status_Detect_Curr_Ptr_Err   ,
      SDMA_RX_Status_Detect_Nxt_Ptr_Err     => SDMA_RX_Status_Detect_Nxt_Ptr_Err    ,
      SDMA_RX_Status_Detect_Addr_Err        => SDMA_RX_Status_Detect_Addr_Err       ,
      SDMA_RX_Status_Detect_Completed_Err   => SDMA_RX_Status_Detect_Completed_Err  ,
      SDMA_RX_Status_Set_SDMA_Completed     => SDMA_RX_Status_Set_SDMA_Completed    ,
      SDMA_RX_Status_Set_Start_Of_Packet    => SDMA_RX_Status_Set_Start_Of_Packet   ,
      SDMA_RX_Status_Set_End_Of_Packet      => SDMA_RX_Status_Set_End_Of_Packet     ,
      SDMA_RX_Status_SetBusy                => SDMA_rx_status_setbusy               ,
      SDMA_RX_Status_Detect_Stop            => SDMA_RX_Status_Detect_Stop           ,
      SDMA_RX_Status_Detect_Null_Ptr        => SDMA_RX_Status_Detect_Null_Ptr       ,
      SDMA_RX_Status_Mem_CE                 => SDMA_RX_Status_Mem_CE                ,
      SDMA_RX_Status_Out                    => SDMA_RX_Status_Out                   ,
      -- Channel Reset Signals                                                              
      SDMA_TX_ChannelRST                    => SDMA_TX_ChannelRST                   ,
      SDMA_RX_ChannelRST                    => SDMA_RX_ChannelRST                   ,
      ResetComplete                         => resetcomplete                        ,
      SDMA_RX_Error_Reset                   => sdma_rx_error_reset                  ,
      SDMA_TX_Error_Reset                   => sdma_tx_error_reset                  ,

      -- TX Byte Shifter Controls                                                      
      SDMA_TX_Shifter_Byte_Sel0             => SDMA_TX_Shifter_Byte_Sel0            ,
      SDMA_TX_Shifter_Byte_Sel1             => SDMA_TX_Shifter_Byte_Sel1            ,
      SDMA_TX_Shifter_Byte_Sel2             => SDMA_TX_Shifter_Byte_Sel2            ,
      SDMA_TX_Shifter_Byte_Sel3             => SDMA_TX_Shifter_Byte_Sel3            ,
      SDMA_TX_Shifter_Byte_Reg_CE           => SDMA_TX_Shifter_Byte_Reg_CE          ,
      -- RX Byte Shifter Controls                                                          
      SDMA_RX_Shifter_HoldReg_CE            => SDMA_RX_Shifter_HoldReg_CE           ,
      SDMA_RX_Shifter_Byte_Sel              => SDMA_RX_Shifter_Byte_Sel             ,
      SDMA_RX_Shifter_CE                    => SDMA_RX_Shifter_CE                   ,

      -- TailPointer Mode Support
      SDMA_TX_CurDesc_Ptr                   => SDMA_tx_curdesc_ptr                  ,
      SDMA_TX_TailDesc_Ptr                  => SDMA_tx_taildesc_ptr                 ,
      SDMA_RX_CurDesc_Ptr                   => SDMA_rx_curdesc_ptr                  ,
      SDMA_RX_TailDesc_Ptr                  => SDMA_rx_taildesc_ptr                 ,



      IPIC_Control_Reg_WE                   => ipic_control_reg_we                  ,
      IPIC_Control_Reg_RE                   => ipic_control_reg_re                  ,
      IPIC_TX_Cntl_Reg_WE                   => ipic_tx_cntl_reg_we                  ,
      IPIC_RX_Cntl_Reg_WE                   => ipic_rx_cntl_reg_we                  ,
      IPIC_TX_Sts_Reg_RE                    => ipic_tx_sts_reg_re                   ,    
      IPIC_RX_Sts_Reg_RE                    => ipic_rx_sts_reg_re                   ,
      IPIC_TX_TailPtr_Reg_WE                => ipic_tx_tailptr_reg_we               ,
      IPIC_RX_TailPtr_Reg_WE                => ipic_rx_tailptr_reg_we               ,


      SDMA_TX_Control_Reg                   => SDMA_tx_control_reg                  ,
      SDMA_RX_Control_Reg                   => SDMA_rx_control_reg                  ,
      SDMA_Control_Reg                      => SDMA_control_reg                     ,
      -- 32-bit datapath signals
	early_pop_i => early_pop_i,
	early_pop_i_d1 => early_pop_i_d1,
	early_pop_i_d2 => early_pop_i_d2,
	early_pop_i_d3 => early_pop_i_d3,
	early_pop_i_d4 => early_pop_i_d4,
	early_pop_i_d5 => early_pop_i_d5,
	early_pop_i_d6 => early_pop_i_d6,
	d_reg_ce => d_reg_ce,
	PI_RdFIFO_Empty => PI_RdFIFO_Empty_i,

      -- Additional Datapath Signals                                                
      wrDataAck_Pos                         => wrDataAck_Pos                        ,
      wrDataAck_Neg                         => wrDataAck_Neg                        ,
      rdDataAck_Pos                         => rdDataAck_Pos                        ,
      rdDataAck_Neg                         => rdDataAck_Neg                        ,
      delay_reg_ce                          => delay_reg_ce                         ,
      delay_reg_sel                         => delay_reg_sel                        
   );                                                                               



-------------------------------------------------------------------------------  
-- PLB V4.6 Slave
-------------------------------------------------------------------------------  
                            
-- Instantiate the PLB IPIF
I_IPIF_BLK : entity plbv46_slave_single_v1_01_a.plbv46_slave_single
    generic map (
        C_ARD_ADDR_RANGE_ARRAY       => ARD_ADDR_RANGE_ARRAY            ,
        C_ARD_NUM_CE_ARRAY           => ARD_NUM_CE_ARRAY                ,
        C_SPLB_P2P                   => C_SPLB_P2P                      ,
        C_BUS2CORE_CLK_RATIO         => 1                               ,
        C_SPLB_MID_WIDTH             => C_SPLB_MID_WIDTH                ,
        C_SPLB_NUM_MASTERS           => C_SPLB_NUM_MASTERS              ,
        C_SPLB_AWIDTH                => C_SPLB_AWIDTH                   ,
        C_SPLB_DWIDTH                => C_SPLB_DWIDTH                   ,
        C_SIPIF_DWIDTH               => C_SPLB_NATIVE_DWIDTH            ,
        C_INCLUDE_DPHASE_TIMER		=> 0				,
        C_FAMILY                     => C_FAMILY
    )
    port map (
  
    -- System signals ---------------------------------------------------------
                          
        SPLB_Clk            => SPLB_Clk                     ,
        SPLB_Rst            => SPLB_Rst                     ,

        -- Bus Slave Signals
        PLB_ABus            => PLB_ABus                     , 
        PLB_UABus           => PLB_UABus                    ,
        PLB_PAValid         => PLB_PAValid                  ,
        PLB_SAValid         => PLB_SAValid                  ,
        PLB_rdPrim          => PLB_rdPrim                   ,
        PLB_wrPrim          => PLB_wrPrim                   ,
        PLB_masterID        => PLB_masterID                 ,
        PLB_abort           => PLB_abort                    ,
        PLB_busLock         => PLB_busLock                  ,
        PLB_RNW             => PLB_RNW                      ,
        PLB_BE              => PLB_BE                       ,
        PLB_MSize           => PLB_MSize                    ,
        PLB_size            => PLB_size                     ,
        PLB_type            => PLB_type                     ,
        PLB_lockErr         => PLB_lockErr                  ,
        PLB_wrDBus          => PLB_wrDBus                   ,
        PLB_wrBurst         => PLB_wrBurst                  ,
        PLB_rdBurst         => PLB_rdBurst                  ,
        PLB_wrPendReq       => PLB_wrPendReq                ,
        PLB_rdPendReq       => PLB_rdPendReq                ,
        PLB_wrPendPri       => PLB_wrPendPri                ,
        PLB_rdPendPri       => PLB_rdPendPri                ,
        PLB_reqPri          => PLB_reqPri                   ,
        PLB_TAttribute      => PLB_TAttribute               ,

        Sl_addrAck          => Sln_addrAck                  ,
        Sl_SSize            => Sln_SSize                    ,
        Sl_wait             => Sln_wait                     ,
        Sl_rearbitrate      => Sln_rearbitrate              ,
        Sl_wrDAck           => Sln_wrDAck                   ,
        Sl_wrComp           => Sln_wrComp                   ,
        Sl_wrBTerm          => Sln_wrBTerm                  ,
        Sl_rdDBus           => Sln_rdDBus                   ,
        Sl_rdWdAddr         => Sln_rdWdAddr                 ,
        Sl_rdDAck           => Sln_rdDAck                   ,
        Sl_rdComp           => Sln_rdComp                   ,
        Sl_rdBTerm          => Sln_rdBTerm                  ,
        Sl_MBusy            => Sln_MBusy                    ,
        Sl_MWrErr           => Sln_MWrErr                   ,
        Sl_MRdErr           => Sln_MRdErr                   ,
        Sl_MIRQ             => Sln_MIRQ                     ,
        
    -- IP Interconnect (IPIC) port signals -----------------------------------------
        --System Signals
        Bus2IP_Clk          =>  open                  ,       
        Bus2IP_Reset        =>  bus2ip_reset                ,       
                                                            
        -- IP Slave signals
        IP2Bus_Data         =>  ip2bus_data                 ,     
        IP2Bus_WrAck        =>  ip2bus_wrack                ,     
        IP2Bus_RdAck        =>  ip2bus_rdack                ,     
        IP2Bus_Error        =>  '0'                         ,     
        Bus2IP_Addr         =>  bus2ip_addr                 ,     
        Bus2IP_Data         =>  bus2ip_data                 ,     
        Bus2IP_RNW          =>  bus2ip_rnw                  ,     
        Bus2IP_BE           =>  open                        ,     
        Bus2IP_CS           =>  bus2ip_cs                   ,
        Bus2IP_RdCE         =>  bus2ip_rdce                 ,
        Bus2IP_WrCE         =>  bus2ip_wrce          
      );



end implementation;
