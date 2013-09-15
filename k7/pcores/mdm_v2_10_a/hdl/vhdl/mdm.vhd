-------------------------------------------------------------------------------
-- $Id$
-------------------------------------------------------------------------------
-- mdm.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2003-2012 Xilinx, Inc. All rights reserved.
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
-------------------------------------------------------------------------------
-- Filename:        mdm.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              mdm.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision$
-- Date:            $Date$
--
-- History:
--   goran   2006-10-27    First Version
--   stefana 2012-03-16    Added support for 32 processors and external BSCAN
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

library unisim;
use unisim.vcomponents.all;

library mdm_v2_10_a;
use mdm_v2_10_a.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.INTEGER_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.calc_num_ce;

library axi_lite_ipif_v1_01_a;
use axi_lite_ipif_v1_01_a.axi_lite_ipif;

entity MDM is
  generic (
    C_FAMILY              : string                        := "virtex2";
    C_JTAG_CHAIN          : integer                       := 2;
    C_USE_BSCAN           : integer                       := 0;
    C_USE_CONFIG_RESET    : integer                       := 0;
    C_INTERCONNECT        : integer                       := 0;
    C_BASEADDR            : std_logic_vector(0 to 31)     := X"FFFF_FFFF";
    C_HIGHADDR            : std_logic_vector(0 to 31)     := X"0000_0000";
    C_SPLB_AWIDTH         : integer                       := 32;
    C_SPLB_DWIDTH         : integer                       := 32;
    C_SPLB_P2P            : integer                       := 0;
    C_SPLB_MID_WIDTH      : integer                       := 3;
    C_SPLB_NUM_MASTERS    : integer                       := 8;
    C_SPLB_NATIVE_DWIDTH  : integer                       := 32;
    C_SPLB_SUPPORT_BURSTS : integer                       := 0;
    C_MB_DBG_PORTS        : integer                       := 1;
    C_USE_UART            : integer                       := 1;
    C_S_AXI_ADDR_WIDTH    : integer range 32 to 36        := 32;
    C_S_AXI_DATA_WIDTH    : integer range 32 to 128       := 32
  );

  port (
    -- Global signals
    Config_Reset  : in std_logic := '0';

    S_AXI_ACLK    : in std_logic;
    S_AXI_ARESETN : in std_logic;

    SPLB_Clk      : in std_logic;
    SPLB_Rst      : in std_logic;

    Interrupt     : out std_logic;
    Ext_BRK       : out std_logic;
    Ext_NM_BRK    : out std_logic;
    Debug_SYS_Rst : out std_logic;

    -- AXI signals
    S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID : in  std_logic;
    S_AXI_AWREADY : out std_logic;
    S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in  std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in  std_logic;
    S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID : in  std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in  std_logic;

    -- PLBv46 signals
    PLB_ABus       : in std_logic_vector(0 to 31);
    PLB_UABus      : in std_logic_vector(0 to 31);
    PLB_PAValid    : in std_logic;
    PLB_SAValid    : in std_logic;
    PLB_rdPrim     : in std_logic;
    PLB_wrPrim     : in std_logic;
    PLB_masterID   : in std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_abort      : in std_logic;
    PLB_busLock    : in std_logic;
    PLB_RNW        : in std_logic;
    PLB_BE         : in std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1);
    PLB_MSize      : in std_logic_vector(0 to 1);
    PLB_size       : in std_logic_vector(0 to 3);
    PLB_type       : in std_logic_vector(0 to 2);
    PLB_lockErr    : in std_logic;
    PLB_wrDBus     : in std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst    : in std_logic;
    PLB_rdBurst    : in std_logic;
    PLB_wrPendReq  : in std_logic;
    PLB_rdPendReq  : in std_logic;
    PLB_wrPendPri  : in std_logic_vector(0 to 1);
    PLB_rdPendPri  : in std_logic_vector(0 to 1);
    PLB_reqPri     : in std_logic_vector(0 to 1);
    PLB_TAttribute : in std_logic_vector(0 to 15);

    Sl_addrAck     : out std_logic;
    Sl_SSize       : out std_logic_vector(0 to 1);
    Sl_wait        : out std_logic;
    Sl_rearbitrate : out std_logic;
    Sl_wrDAck      : out std_logic;
    Sl_wrComp      : out std_logic;
    Sl_wrBTerm     : out std_logic;
    Sl_rdDBus      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr    : out std_logic_vector(0 to 3);
    Sl_rdDAck      : out std_logic;
    Sl_rdComp      : out std_logic;
    Sl_rdBTerm     : out std_logic;
    Sl_MBusy       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MIRQ        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

    -- MicroBlaze Debug Signals
    Dbg_Clk_0     : out std_logic;
    Dbg_TDI_0     : out std_logic;
    Dbg_TDO_0     : in  std_logic;
    Dbg_Reg_En_0  : out std_logic_vector(0 to 7);
    Dbg_Capture_0 : out std_logic;
    Dbg_Shift_0   : out std_logic;
    Dbg_Update_0  : out std_logic;
    Dbg_Rst_0     : out std_logic;

    Dbg_Clk_1     : out std_logic;
    Dbg_TDI_1     : out std_logic;
    Dbg_TDO_1     : in  std_logic;
    Dbg_Reg_En_1  : out std_logic_vector(0 to 7);
    Dbg_Capture_1 : out std_logic;
    Dbg_Shift_1   : out std_logic;
    Dbg_Update_1  : out std_logic;
    Dbg_Rst_1     : out std_logic;

    Dbg_Clk_2     : out std_logic;
    Dbg_TDI_2     : out std_logic;
    Dbg_TDO_2     : in  std_logic;
    Dbg_Reg_En_2  : out std_logic_vector(0 to 7);
    Dbg_Capture_2 : out std_logic;
    Dbg_Shift_2   : out std_logic;
    Dbg_Update_2  : out std_logic;
    Dbg_Rst_2     : out std_logic;

    Dbg_Clk_3     : out std_logic;
    Dbg_TDI_3     : out std_logic;
    Dbg_TDO_3     : in  std_logic;
    Dbg_Reg_En_3  : out std_logic_vector(0 to 7);
    Dbg_Capture_3 : out std_logic;
    Dbg_Shift_3   : out std_logic;
    Dbg_Update_3  : out std_logic;
    Dbg_Rst_3     : out std_logic;

    Dbg_Clk_4     : out std_logic;
    Dbg_TDI_4     : out std_logic;
    Dbg_TDO_4     : in  std_logic;
    Dbg_Reg_En_4  : out std_logic_vector(0 to 7);
    Dbg_Capture_4 : out std_logic;
    Dbg_Shift_4   : out std_logic;
    Dbg_Update_4  : out std_logic;
    Dbg_Rst_4     : out std_logic;

    Dbg_Clk_5     : out std_logic;
    Dbg_TDI_5     : out std_logic;
    Dbg_TDO_5     : in  std_logic;
    Dbg_Reg_En_5  : out std_logic_vector(0 to 7);
    Dbg_Capture_5 : out std_logic;
    Dbg_Shift_5   : out std_logic;
    Dbg_Update_5  : out std_logic;
    Dbg_Rst_5     : out std_logic;

    Dbg_Clk_6     : out std_logic;
    Dbg_TDI_6     : out std_logic;
    Dbg_TDO_6     : in  std_logic;
    Dbg_Reg_En_6  : out std_logic_vector(0 to 7);
    Dbg_Capture_6 : out std_logic;
    Dbg_Shift_6   : out std_logic;
    Dbg_Update_6  : out std_logic;
    Dbg_Rst_6     : out std_logic;

    Dbg_Clk_7     : out std_logic;
    Dbg_TDI_7     : out std_logic;
    Dbg_TDO_7     : in  std_logic;
    Dbg_Reg_En_7  : out std_logic_vector(0 to 7);
    Dbg_Capture_7 : out std_logic;
    Dbg_Shift_7   : out std_logic;
    Dbg_Update_7  : out std_logic;
    Dbg_Rst_7     : out std_logic;

    Dbg_Clk_8     : out std_logic;
    Dbg_TDI_8     : out std_logic;
    Dbg_TDO_8     : in  std_logic;
    Dbg_Reg_En_8  : out std_logic_vector(0 to 7);
    Dbg_Capture_8 : out std_logic;
    Dbg_Shift_8   : out std_logic;
    Dbg_Update_8  : out std_logic;
    Dbg_Rst_8     : out std_logic;

    Dbg_Clk_9     : out std_logic;
    Dbg_TDI_9     : out std_logic;
    Dbg_TDO_9     : in  std_logic;
    Dbg_Reg_En_9  : out std_logic_vector(0 to 7);
    Dbg_Capture_9 : out std_logic;
    Dbg_Shift_9   : out std_logic;
    Dbg_Update_9  : out std_logic;
    Dbg_Rst_9     : out std_logic;

    Dbg_Clk_10     : out std_logic;
    Dbg_TDI_10     : out std_logic;
    Dbg_TDO_10     : in  std_logic;
    Dbg_Reg_En_10  : out std_logic_vector(0 to 7);
    Dbg_Capture_10 : out std_logic;
    Dbg_Shift_10   : out std_logic;
    Dbg_Update_10  : out std_logic;
    Dbg_Rst_10     : out std_logic;

    Dbg_Clk_11     : out std_logic;
    Dbg_TDI_11     : out std_logic;
    Dbg_TDO_11     : in  std_logic;
    Dbg_Reg_En_11  : out std_logic_vector(0 to 7);
    Dbg_Capture_11 : out std_logic;
    Dbg_Shift_11   : out std_logic;
    Dbg_Update_11  : out std_logic;
    Dbg_Rst_11     : out std_logic;

    Dbg_Clk_12     : out std_logic;
    Dbg_TDI_12     : out std_logic;
    Dbg_TDO_12     : in  std_logic;
    Dbg_Reg_En_12  : out std_logic_vector(0 to 7);
    Dbg_Capture_12 : out std_logic;
    Dbg_Shift_12   : out std_logic;
    Dbg_Update_12  : out std_logic;
    Dbg_Rst_12     : out std_logic;

    Dbg_Clk_13     : out std_logic;
    Dbg_TDI_13     : out std_logic;
    Dbg_TDO_13     : in  std_logic;
    Dbg_Reg_En_13  : out std_logic_vector(0 to 7);
    Dbg_Capture_13 : out std_logic;
    Dbg_Shift_13   : out std_logic;
    Dbg_Update_13  : out std_logic;
    Dbg_Rst_13     : out std_logic;

    Dbg_Clk_14     : out std_logic;
    Dbg_TDI_14     : out std_logic;
    Dbg_TDO_14     : in  std_logic;
    Dbg_Reg_En_14  : out std_logic_vector(0 to 7);
    Dbg_Capture_14 : out std_logic;
    Dbg_Shift_14   : out std_logic;
    Dbg_Update_14  : out std_logic;
    Dbg_Rst_14     : out std_logic;

    Dbg_Clk_15     : out std_logic;
    Dbg_TDI_15     : out std_logic;
    Dbg_TDO_15     : in  std_logic;
    Dbg_Reg_En_15  : out std_logic_vector(0 to 7);
    Dbg_Capture_15 : out std_logic;
    Dbg_Shift_15   : out std_logic;
    Dbg_Update_15  : out std_logic;
    Dbg_Rst_15     : out std_logic;

    Dbg_Clk_16     : out std_logic;
    Dbg_TDI_16     : out std_logic;
    Dbg_TDO_16     : in  std_logic;
    Dbg_Reg_En_16  : out std_logic_vector(0 to 7);
    Dbg_Capture_16 : out std_logic;
    Dbg_Shift_16   : out std_logic;
    Dbg_Update_16  : out std_logic;
    Dbg_Rst_16     : out std_logic;

    Dbg_Clk_17     : out std_logic;
    Dbg_TDI_17     : out std_logic;
    Dbg_TDO_17     : in  std_logic;
    Dbg_Reg_En_17  : out std_logic_vector(0 to 7);
    Dbg_Capture_17 : out std_logic;
    Dbg_Shift_17   : out std_logic;
    Dbg_Update_17  : out std_logic;
    Dbg_Rst_17     : out std_logic;

    Dbg_Clk_18     : out std_logic;
    Dbg_TDI_18     : out std_logic;
    Dbg_TDO_18     : in  std_logic;
    Dbg_Reg_En_18  : out std_logic_vector(0 to 7);
    Dbg_Capture_18 : out std_logic;
    Dbg_Shift_18   : out std_logic;
    Dbg_Update_18  : out std_logic;
    Dbg_Rst_18     : out std_logic;

    Dbg_Clk_19     : out std_logic;
    Dbg_TDI_19     : out std_logic;
    Dbg_TDO_19     : in  std_logic;
    Dbg_Reg_En_19  : out std_logic_vector(0 to 7);
    Dbg_Capture_19 : out std_logic;
    Dbg_Shift_19   : out std_logic;
    Dbg_Update_19  : out std_logic;
    Dbg_Rst_19     : out std_logic;

    Dbg_Clk_20     : out std_logic;
    Dbg_TDI_20     : out std_logic;
    Dbg_TDO_20     : in  std_logic;
    Dbg_Reg_En_20  : out std_logic_vector(0 to 7);
    Dbg_Capture_20 : out std_logic;
    Dbg_Shift_20   : out std_logic;
    Dbg_Update_20  : out std_logic;
    Dbg_Rst_20     : out std_logic;

    Dbg_Clk_21     : out std_logic;
    Dbg_TDI_21     : out std_logic;
    Dbg_TDO_21     : in  std_logic;
    Dbg_Reg_En_21  : out std_logic_vector(0 to 7);
    Dbg_Capture_21 : out std_logic;
    Dbg_Shift_21   : out std_logic;
    Dbg_Update_21  : out std_logic;
    Dbg_Rst_21     : out std_logic;

    Dbg_Clk_22     : out std_logic;
    Dbg_TDI_22     : out std_logic;
    Dbg_TDO_22     : in  std_logic;
    Dbg_Reg_En_22  : out std_logic_vector(0 to 7);
    Dbg_Capture_22 : out std_logic;
    Dbg_Shift_22   : out std_logic;
    Dbg_Update_22  : out std_logic;
    Dbg_Rst_22     : out std_logic;

    Dbg_Clk_23     : out std_logic;
    Dbg_TDI_23     : out std_logic;
    Dbg_TDO_23     : in  std_logic;
    Dbg_Reg_En_23  : out std_logic_vector(0 to 7);
    Dbg_Capture_23 : out std_logic;
    Dbg_Shift_23   : out std_logic;
    Dbg_Update_23  : out std_logic;
    Dbg_Rst_23     : out std_logic;

    Dbg_Clk_24     : out std_logic;
    Dbg_TDI_24     : out std_logic;
    Dbg_TDO_24     : in  std_logic;
    Dbg_Reg_En_24  : out std_logic_vector(0 to 7);
    Dbg_Capture_24 : out std_logic;
    Dbg_Shift_24   : out std_logic;
    Dbg_Update_24  : out std_logic;
    Dbg_Rst_24     : out std_logic;

    Dbg_Clk_25     : out std_logic;
    Dbg_TDI_25     : out std_logic;
    Dbg_TDO_25     : in  std_logic;
    Dbg_Reg_En_25  : out std_logic_vector(0 to 7);
    Dbg_Capture_25 : out std_logic;
    Dbg_Shift_25   : out std_logic;
    Dbg_Update_25  : out std_logic;
    Dbg_Rst_25     : out std_logic;

    Dbg_Clk_26     : out std_logic;
    Dbg_TDI_26     : out std_logic;
    Dbg_TDO_26     : in  std_logic;
    Dbg_Reg_En_26  : out std_logic_vector(0 to 7);
    Dbg_Capture_26 : out std_logic;
    Dbg_Shift_26   : out std_logic;
    Dbg_Update_26  : out std_logic;
    Dbg_Rst_26     : out std_logic;

    Dbg_Clk_27     : out std_logic;
    Dbg_TDI_27     : out std_logic;
    Dbg_TDO_27     : in  std_logic;
    Dbg_Reg_En_27  : out std_logic_vector(0 to 7);
    Dbg_Capture_27 : out std_logic;
    Dbg_Shift_27   : out std_logic;
    Dbg_Update_27  : out std_logic;
    Dbg_Rst_27     : out std_logic;

    Dbg_Clk_28     : out std_logic;
    Dbg_TDI_28     : out std_logic;
    Dbg_TDO_28     : in  std_logic;
    Dbg_Reg_En_28  : out std_logic_vector(0 to 7);
    Dbg_Capture_28 : out std_logic;
    Dbg_Shift_28   : out std_logic;
    Dbg_Update_28  : out std_logic;
    Dbg_Rst_28     : out std_logic;

    Dbg_Clk_29     : out std_logic;
    Dbg_TDI_29     : out std_logic;
    Dbg_TDO_29     : in  std_logic;
    Dbg_Reg_En_29  : out std_logic_vector(0 to 7);
    Dbg_Capture_29 : out std_logic;
    Dbg_Shift_29   : out std_logic;
    Dbg_Update_29  : out std_logic;
    Dbg_Rst_29     : out std_logic;

    Dbg_Clk_30     : out std_logic;
    Dbg_TDI_30     : out std_logic;
    Dbg_TDO_30     : in  std_logic;
    Dbg_Reg_En_30  : out std_logic_vector(0 to 7);
    Dbg_Capture_30 : out std_logic;
    Dbg_Shift_30   : out std_logic;
    Dbg_Update_30  : out std_logic;
    Dbg_Rst_30     : out std_logic;

    Dbg_Clk_31     : out std_logic;
    Dbg_TDI_31     : out std_logic;
    Dbg_TDO_31     : in  std_logic;
    Dbg_Reg_En_31  : out std_logic_vector(0 to 7);
    Dbg_Capture_31 : out std_logic;
    Dbg_Shift_31   : out std_logic;
    Dbg_Update_31  : out std_logic;
    Dbg_Rst_31     : out std_logic;

    -- Connect the BSCAN's USER1 + common signals to the external pins
    -- These signals can be connected to an ICON core instantiated by the user
    -- Will not be used if the ICON is inserted within the mdm
    -- The signals are only useful for Spartan3 and Spartan3AN
    -- These signals are output when C_USE_BSCAN = 1 (ICON)
    bscan_tdi     : out std_logic;
    bscan_reset   : out std_logic;
    bscan_shift   : out std_logic;
    bscan_update  : out std_logic;
    bscan_capture : out std_logic;
    bscan_sel1    : out std_logic;
    bscan_drck1   : out std_logic;
    bscan_tdo1    : in  std_logic;

    -- External BSCAN inputs
    -- These signals are used when C_USE_BSCAN = 2 (EXTERNAL)
    bscan_ext_tdi     : in  std_logic;
    bscan_ext_reset   : in  std_logic;
    bscan_ext_shift   : in  std_logic;
    bscan_ext_update  : in  std_logic;
    bscan_ext_capture : in  std_logic;
    bscan_ext_sel     : in  std_logic;
    bscan_ext_drck    : in  std_logic;
    bscan_ext_tdo     : out std_logic;

    -- External JTAG ports
    Ext_JTAG_DRCK    : out std_logic;
    Ext_JTAG_RESET   : out std_logic;
    Ext_JTAG_SEL     : out std_logic;
    Ext_JTAG_CAPTURE : out std_logic;
    Ext_JTAG_SHIFT   : out std_logic;
    Ext_JTAG_UPDATE  : out std_logic;
    Ext_JTAG_TDI     : out std_logic;
    Ext_JTAG_TDO     : in  std_logic

  );

end entity MDM;

architecture IMP of MDM is

  --------------------------------------------------------------------------
  -- Constant declarations
  --------------------------------------------------------------------------

  constant ZEROES : std_logic_vector(31 downto 0) := X"00000000";

  constant C_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE := (
    -- Registers Base Address (not used)
    ZEROES & C_BASEADDR,
    ZEROES & (C_BASEADDR or X"0000000F")
  );

  constant C_ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE := (
    0 => 4
  );

  constant C_S_AXI_MIN_SIZE : std_logic_vector(31 downto 0) := X"0000000F";
  constant C_USE_WSTRB      : integer                       := 0;
  constant C_DPHASE_TIMEOUT : integer                       := 4;

  --------------------------------------------------------------------------
  -- Component declarations
  --------------------------------------------------------------------------  

  component MDM_Core
    generic (
      C_USE_CONFIG_RESET    : integer := 0;
      C_BASEADDR            : std_logic_vector(0 to 31);
      C_HIGHADDR            : std_logic_vector(0 to 31);
      C_INTERCONNECT        : integer := 0;
      C_SPLB_AWIDTH         : integer := 32;
      C_SPLB_DWIDTH         : integer := 32;
      C_SPLB_P2P            : integer := 0;
      C_SPLB_MID_WIDTH      : integer := 3;
      C_SPLB_NUM_MASTERS    : integer := 8;
      C_SPLB_NATIVE_DWIDTH  : integer := 32;
      C_SPLB_SUPPORT_BURSTS : integer := 0;
      C_MB_DBG_PORTS        : integer;
      C_USE_UART            : integer;
      C_UART_WIDTH          : integer := 8);

    port (
      -- Global signals
      Config_Reset  : in std_logic;

      SPLB_Clk      : in std_logic;
      SPLB_Rst      : in std_logic;

      Interrupt     : out std_logic;
      Ext_BRK       : out std_logic;
      Ext_NM_BRK    : out std_logic;
      Debug_SYS_Rst : out std_logic;

      -- PLBv46 signals
      PLB_ABus       : in std_logic_vector(0 to 31);
      PLB_UABus      : in std_logic_vector(0 to 31);
      PLB_PAValid    : in std_logic;
      PLB_SAValid    : in std_logic;
      PLB_rdPrim     : in std_logic;
      PLB_wrPrim     : in std_logic;
      PLB_masterID   : in std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      PLB_abort      : in std_logic;
      PLB_busLock    : in std_logic;
      PLB_RNW        : in std_logic;
      PLB_BE         : in std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1);
      PLB_MSize      : in std_logic_vector(0 to 1);
      PLB_size       : in std_logic_vector(0 to 3);
      PLB_type       : in std_logic_vector(0 to 2);
      PLB_lockErr    : in std_logic;
      PLB_wrDBus     : in std_logic_vector(0 to C_SPLB_DWIDTH-1);
      PLB_wrBurst    : in std_logic;
      PLB_rdBurst    : in std_logic;
      PLB_wrPendReq  : in std_logic;
      PLB_rdPendReq  : in std_logic;
      PLB_wrPendPri  : in std_logic_vector(0 to 1);
      PLB_rdPendPri  : in std_logic_vector(0 to 1);
      PLB_reqPri     : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);

      Sl_addrAck     : out std_logic;
      Sl_SSize       : out std_logic_vector(0 to 1);
      Sl_wait        : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck      : out std_logic;
      Sl_wrComp      : out std_logic;
      Sl_wrBTerm     : out std_logic;
      Sl_rdDBus      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
      Sl_rdWdAddr    : out std_logic_vector(0 to 3);
      Sl_rdDAck      : out std_logic;
      Sl_rdComp      : out std_logic;
      Sl_rdBTerm     : out std_logic;
      Sl_MBusy       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MWrErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MRdErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MIRQ        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

      -- AXI IPIC signals
      bus2ip_clk    : in  std_logic;
      bus2ip_resetn : in  std_logic;
      bus2ip_data   : in  std_logic_vector(0 to 7);
      bus2ip_rdce   : in  std_logic_vector(0 to 3);
      bus2ip_wrce   : in  std_logic_vector(0 to 3);
      bus2ip_cs     : in  std_logic;
      ip2bus_rdack  : out std_logic;
      ip2bus_wrack  : out std_logic;
      ip2bus_error  : out std_logic;
      ip2bus_data   : out std_logic_vector(0 to 7);

      -- JTAG signals
      TDI     : in  std_logic;
      RESET   : in  std_logic;
      UPDATE  : in  std_logic;
      SHIFT   : in  std_logic;
      CAPTURE : in  std_logic;
      SEL     : in  std_logic;
      DRCK    : in  std_logic;
      TDO     : out std_logic;

      -- MicroBlaze Debug Signals
      Dbg_Clk_0     : out std_logic;
      Dbg_TDI_0     : out std_logic;
      Dbg_TDO_0     : in  std_logic;
      Dbg_Reg_En_0  : out std_logic_vector(0 to 7);
      Dbg_Capture_0 : out std_logic;
      Dbg_Shift_0   : out std_logic;
      Dbg_Update_0  : out std_logic;
      Dbg_Rst_0     : out std_logic;

      Dbg_Clk_1     : out std_logic;
      Dbg_TDI_1     : out std_logic;
      Dbg_TDO_1     : in  std_logic;
      Dbg_Reg_En_1  : out std_logic_vector(0 to 7);
      Dbg_Capture_1 : out std_logic;
      Dbg_Shift_1   : out std_logic;
      Dbg_Update_1  : out std_logic;
      Dbg_Rst_1     : out std_logic;

      Dbg_Clk_2     : out std_logic;
      Dbg_TDI_2     : out std_logic;
      Dbg_TDO_2     : in  std_logic;
      Dbg_Reg_En_2  : out std_logic_vector(0 to 7);
      Dbg_Capture_2 : out std_logic;
      Dbg_Shift_2   : out std_logic;
      Dbg_Update_2  : out std_logic;
      Dbg_Rst_2     : out std_logic;

      Dbg_Clk_3     : out std_logic;
      Dbg_TDI_3     : out std_logic;
      Dbg_TDO_3     : in  std_logic;
      Dbg_Reg_En_3  : out std_logic_vector(0 to 7);
      Dbg_Capture_3 : out std_logic;
      Dbg_Shift_3   : out std_logic;
      Dbg_Update_3  : out std_logic;
      Dbg_Rst_3     : out std_logic;

      Dbg_Clk_4     : out std_logic;
      Dbg_TDI_4     : out std_logic;
      Dbg_TDO_4     : in  std_logic;
      Dbg_Reg_En_4  : out std_logic_vector(0 to 7);
      Dbg_Capture_4 : out std_logic;
      Dbg_Shift_4   : out std_logic;
      Dbg_Update_4  : out std_logic;
      Dbg_Rst_4     : out std_logic;

      Dbg_Clk_5     : out std_logic;
      Dbg_TDI_5     : out std_logic;
      Dbg_TDO_5     : in  std_logic;
      Dbg_Reg_En_5  : out std_logic_vector(0 to 7);
      Dbg_Capture_5 : out std_logic;
      Dbg_Shift_5   : out std_logic;
      Dbg_Update_5  : out std_logic;
      Dbg_Rst_5     : out std_logic;

      Dbg_Clk_6     : out std_logic;
      Dbg_TDI_6     : out std_logic;
      Dbg_TDO_6     : in  std_logic;
      Dbg_Reg_En_6  : out std_logic_vector(0 to 7);
      Dbg_Capture_6 : out std_logic;
      Dbg_Shift_6   : out std_logic;
      Dbg_Update_6  : out std_logic;
      Dbg_Rst_6     : out std_logic;

      Dbg_Clk_7     : out std_logic;
      Dbg_TDI_7     : out std_logic;
      Dbg_TDO_7     : in  std_logic;
      Dbg_Reg_En_7  : out std_logic_vector(0 to 7);
      Dbg_Capture_7 : out std_logic;
      Dbg_Shift_7   : out std_logic;
      Dbg_Update_7  : out std_logic;
      Dbg_Rst_7     : out std_logic;

      Dbg_Clk_8     : out std_logic;
      Dbg_TDI_8     : out std_logic;
      Dbg_TDO_8     : in  std_logic;
      Dbg_Reg_En_8  : out std_logic_vector(0 to 7);
      Dbg_Capture_8 : out std_logic;
      Dbg_Shift_8   : out std_logic;
      Dbg_Update_8  : out std_logic;
      Dbg_Rst_8     : out std_logic;

      Dbg_Clk_9     : out std_logic;
      Dbg_TDI_9     : out std_logic;
      Dbg_TDO_9     : in  std_logic;
      Dbg_Reg_En_9  : out std_logic_vector(0 to 7);
      Dbg_Capture_9 : out std_logic;
      Dbg_Shift_9   : out std_logic;
      Dbg_Update_9  : out std_logic;
      Dbg_Rst_9     : out std_logic;

      Dbg_Clk_10     : out std_logic;
      Dbg_TDI_10     : out std_logic;
      Dbg_TDO_10     : in  std_logic;
      Dbg_Reg_En_10  : out std_logic_vector(0 to 7);
      Dbg_Capture_10 : out std_logic;
      Dbg_Shift_10   : out std_logic;
      Dbg_Update_10  : out std_logic;
      Dbg_Rst_10     : out std_logic;

      Dbg_Clk_11     : out std_logic;
      Dbg_TDI_11     : out std_logic;
      Dbg_TDO_11     : in  std_logic;
      Dbg_Reg_En_11  : out std_logic_vector(0 to 7);
      Dbg_Capture_11 : out std_logic;
      Dbg_Shift_11   : out std_logic;
      Dbg_Update_11  : out std_logic;
      Dbg_Rst_11     : out std_logic;

      Dbg_Clk_12     : out std_logic;
      Dbg_TDI_12     : out std_logic;
      Dbg_TDO_12     : in  std_logic;
      Dbg_Reg_En_12  : out std_logic_vector(0 to 7);
      Dbg_Capture_12 : out std_logic;
      Dbg_Shift_12   : out std_logic;
      Dbg_Update_12  : out std_logic;
      Dbg_Rst_12     : out std_logic;

      Dbg_Clk_13     : out std_logic;
      Dbg_TDI_13     : out std_logic;
      Dbg_TDO_13     : in  std_logic;
      Dbg_Reg_En_13  : out std_logic_vector(0 to 7);
      Dbg_Capture_13 : out std_logic;
      Dbg_Shift_13   : out std_logic;
      Dbg_Update_13  : out std_logic;
      Dbg_Rst_13     : out std_logic;

      Dbg_Clk_14     : out std_logic;
      Dbg_TDI_14     : out std_logic;
      Dbg_TDO_14     : in  std_logic;
      Dbg_Reg_En_14  : out std_logic_vector(0 to 7);
      Dbg_Capture_14 : out std_logic;
      Dbg_Shift_14   : out std_logic;
      Dbg_Update_14  : out std_logic;
      Dbg_Rst_14     : out std_logic;

      Dbg_Clk_15     : out std_logic;
      Dbg_TDI_15     : out std_logic;
      Dbg_TDO_15     : in  std_logic;
      Dbg_Reg_En_15  : out std_logic_vector(0 to 7);
      Dbg_Capture_15 : out std_logic;
      Dbg_Shift_15   : out std_logic;
      Dbg_Update_15  : out std_logic;
      Dbg_Rst_15     : out std_logic;

      Dbg_Clk_16     : out std_logic;
      Dbg_TDI_16     : out std_logic;
      Dbg_TDO_16     : in  std_logic;
      Dbg_Reg_En_16  : out std_logic_vector(0 to 7);
      Dbg_Capture_16 : out std_logic;
      Dbg_Shift_16   : out std_logic;
      Dbg_Update_16  : out std_logic;
      Dbg_Rst_16     : out std_logic;

      Dbg_Clk_17     : out std_logic;
      Dbg_TDI_17     : out std_logic;
      Dbg_TDO_17     : in  std_logic;
      Dbg_Reg_En_17  : out std_logic_vector(0 to 7);
      Dbg_Capture_17 : out std_logic;
      Dbg_Shift_17   : out std_logic;
      Dbg_Update_17  : out std_logic;
      Dbg_Rst_17     : out std_logic;

      Dbg_Clk_18     : out std_logic;
      Dbg_TDI_18     : out std_logic;
      Dbg_TDO_18     : in  std_logic;
      Dbg_Reg_En_18  : out std_logic_vector(0 to 7);
      Dbg_Capture_18 : out std_logic;
      Dbg_Shift_18   : out std_logic;
      Dbg_Update_18  : out std_logic;
      Dbg_Rst_18     : out std_logic;

      Dbg_Clk_19     : out std_logic;
      Dbg_TDI_19     : out std_logic;
      Dbg_TDO_19     : in  std_logic;
      Dbg_Reg_En_19  : out std_logic_vector(0 to 7);
      Dbg_Capture_19 : out std_logic;
      Dbg_Shift_19   : out std_logic;
      Dbg_Update_19  : out std_logic;
      Dbg_Rst_19     : out std_logic;

      Dbg_Clk_20     : out std_logic;
      Dbg_TDI_20     : out std_logic;
      Dbg_TDO_20     : in  std_logic;
      Dbg_Reg_En_20  : out std_logic_vector(0 to 7);
      Dbg_Capture_20 : out std_logic;
      Dbg_Shift_20   : out std_logic;
      Dbg_Update_20  : out std_logic;
      Dbg_Rst_20     : out std_logic;

      Dbg_Clk_21     : out std_logic;
      Dbg_TDI_21     : out std_logic;
      Dbg_TDO_21     : in  std_logic;
      Dbg_Reg_En_21  : out std_logic_vector(0 to 7);
      Dbg_Capture_21 : out std_logic;
      Dbg_Shift_21   : out std_logic;
      Dbg_Update_21  : out std_logic;
      Dbg_Rst_21     : out std_logic;

      Dbg_Clk_22     : out std_logic;
      Dbg_TDI_22     : out std_logic;
      Dbg_TDO_22     : in  std_logic;
      Dbg_Reg_En_22  : out std_logic_vector(0 to 7);
      Dbg_Capture_22 : out std_logic;
      Dbg_Shift_22   : out std_logic;
      Dbg_Update_22  : out std_logic;
      Dbg_Rst_22     : out std_logic;

      Dbg_Clk_23     : out std_logic;
      Dbg_TDI_23     : out std_logic;
      Dbg_TDO_23     : in  std_logic;
      Dbg_Reg_En_23  : out std_logic_vector(0 to 7);
      Dbg_Capture_23 : out std_logic;
      Dbg_Shift_23   : out std_logic;
      Dbg_Update_23  : out std_logic;
      Dbg_Rst_23     : out std_logic;

      Dbg_Clk_24     : out std_logic;
      Dbg_TDI_24     : out std_logic;
      Dbg_TDO_24     : in  std_logic;
      Dbg_Reg_En_24  : out std_logic_vector(0 to 7);
      Dbg_Capture_24 : out std_logic;
      Dbg_Shift_24   : out std_logic;
      Dbg_Update_24  : out std_logic;
      Dbg_Rst_24     : out std_logic;

      Dbg_Clk_25     : out std_logic;
      Dbg_TDI_25     : out std_logic;
      Dbg_TDO_25     : in  std_logic;
      Dbg_Reg_En_25  : out std_logic_vector(0 to 7);
      Dbg_Capture_25 : out std_logic;
      Dbg_Shift_25   : out std_logic;
      Dbg_Update_25  : out std_logic;
      Dbg_Rst_25     : out std_logic;

      Dbg_Clk_26     : out std_logic;
      Dbg_TDI_26     : out std_logic;
      Dbg_TDO_26     : in  std_logic;
      Dbg_Reg_En_26  : out std_logic_vector(0 to 7);
      Dbg_Capture_26 : out std_logic;
      Dbg_Shift_26   : out std_logic;
      Dbg_Update_26  : out std_logic;
      Dbg_Rst_26     : out std_logic;

      Dbg_Clk_27     : out std_logic;
      Dbg_TDI_27     : out std_logic;
      Dbg_TDO_27     : in  std_logic;
      Dbg_Reg_En_27  : out std_logic_vector(0 to 7);
      Dbg_Capture_27 : out std_logic;
      Dbg_Shift_27   : out std_logic;
      Dbg_Update_27  : out std_logic;
      Dbg_Rst_27     : out std_logic;

      Dbg_Clk_28     : out std_logic;
      Dbg_TDI_28     : out std_logic;
      Dbg_TDO_28     : in  std_logic;
      Dbg_Reg_En_28  : out std_logic_vector(0 to 7);
      Dbg_Capture_28 : out std_logic;
      Dbg_Shift_28   : out std_logic;
      Dbg_Update_28  : out std_logic;
      Dbg_Rst_28     : out std_logic;

      Dbg_Clk_29     : out std_logic;
      Dbg_TDI_29     : out std_logic;
      Dbg_TDO_29     : in  std_logic;
      Dbg_Reg_En_29  : out std_logic_vector(0 to 7);
      Dbg_Capture_29 : out std_logic;
      Dbg_Shift_29   : out std_logic;
      Dbg_Update_29  : out std_logic;
      Dbg_Rst_29     : out std_logic;

      Dbg_Clk_30     : out std_logic;
      Dbg_TDI_30     : out std_logic;
      Dbg_TDO_30     : in  std_logic;
      Dbg_Reg_En_30  : out std_logic_vector(0 to 7);
      Dbg_Capture_30 : out std_logic;
      Dbg_Shift_30   : out std_logic;
      Dbg_Update_30  : out std_logic;
      Dbg_Rst_30     : out std_logic;

      Dbg_Clk_31     : out std_logic;
      Dbg_TDI_31     : out std_logic;
      Dbg_TDO_31     : in  std_logic;
      Dbg_Reg_En_31  : out std_logic_vector(0 to 7);
      Dbg_Capture_31 : out std_logic;
      Dbg_Shift_31   : out std_logic;
      Dbg_Update_31  : out std_logic;
      Dbg_Rst_31     : out std_logic;

      Ext_JTAG_DRCK    : out std_logic;
      Ext_JTAG_RESET   : out std_logic;
      Ext_JTAG_SEL     : out std_logic;
      Ext_JTAG_CAPTURE : out std_logic;
      Ext_JTAG_SHIFT   : out std_logic;
      Ext_JTAG_UPDATE  : out std_logic;
      Ext_JTAG_TDI     : out std_logic;
      Ext_JTAG_TDO     : in  std_logic

    );
  end component MDM_Core;

  --------------------------------------------------------------------------
  -- Functions
  --------------------------------------------------------------------------  

  --
  -- The native_bscan function returns the native BSCAN primitive for the given
  -- family. This funtion needs to be revised for every new architecture.
  --
  function native_bscan (C_FAMILY     : string)
    return proc_common_v3_00_a.family_support.primitives_type is
  begin
    if supported(C_FAMILY, u_BSCANE2) then return u_BSCANE2;  -- 7 series
    elsif supported(C_FAMILY, u_BSCAN_VIRTEX6) then return u_BSCAN_VIRTEX6;
    elsif supported(C_FAMILY, u_BSCAN_VIRTEX5) then return u_BSCAN_VIRTEX5;
    elsif supported(C_FAMILY, u_BSCAN_VIRTEX4) then return u_BSCAN_VIRTEX4;
    elsif supported(C_FAMILY, u_BSCAN_SPARTAN6) then return u_BSCAN_SPARTAN6;
    elsif supported(C_FAMILY, u_BSCAN_SPARTAN3A) then return u_BSCAN_SPARTAN3A;
    elsif supported(C_FAMILY, u_BSCAN_SPARTAN3) then return u_BSCAN_SPARTAN3;
    else
      assert false
        report "Function native_bscan : No BSCAN available for " & C_FAMILY
        severity error;
      return u_BSCANE2;  -- To prevent simulator warnings
    end if;
  end;

  --------------------------------------------------------------------------
  -- Signal declarations
  --------------------------------------------------------------------------
  signal tdi     : std_logic;
  signal reset   : std_logic;
  signal update  : std_logic;
  signal capture : std_logic;
  signal shift   : std_logic;
  signal sel     : std_logic;
  signal drck    : std_logic;
  signal tdo     : std_logic;

  signal tdo1  : std_logic;
  signal sel1  : std_logic;
  signal drck1 : std_logic;

  signal drck_i   : std_logic;
  signal drck1_i  : std_logic;
  signal update_i : std_logic;

  signal bus2ip_clk    : std_logic;
  signal bus2ip_resetn : std_logic;
  signal ip2bus_data   : std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0) := (others => '0');
  signal ip2bus_error  : std_logic                                         := '0';
  signal ip2bus_wrack  : std_logic                                         := '0';
  signal ip2bus_rdack  : std_logic                                         := '0';
  signal bus2ip_data   : std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
  signal bus2ip_cs     : std_logic_vector(((C_ARD_ADDR_RANGE_ARRAY'length)/2)-1 downto 0);
  signal bus2ip_rdce   : std_logic_vector(calc_num_ce(C_ARD_NUM_CE_ARRAY)-1 downto 0);
  signal bus2ip_wrce   : std_logic_vector(calc_num_ce(C_ARD_NUM_CE_ARRAY)-1 downto 0);

  --------------------------------------------------------------------------
  -- Attibute declarations
  --------------------------------------------------------------------------
  attribute period           : string;
  attribute period of update : signal is "200 ns";

  attribute buffer_type                : string;
  attribute buffer_type of update_i    : signal is "none";
  attribute buffer_type of update      : signal   is "none";
  attribute buffer_type of MDM_Core_I1 : label is "none";

begin  -- architecture IMP

  -- Connect USER1 signal to external ports
  Use_BSCAN_ICON : if C_USE_BSCAN = 1 generate
  begin
    tdo1          <= bscan_tdo1;
    bscan_drck1   <= drck1;
    bscan_sel1    <= sel1;
    bscan_tdi     <= tdi;
    bscan_reset   <= reset;
    bscan_shift   <= shift;
    bscan_update  <= update;
    bscan_capture <= capture;
  end generate Use_BSCAN_ICON;

  No_BSCAN_ICON : if C_USE_BSCAN /= 1 generate
  begin
    tdo1          <= '0';
    bscan_drck1   <= '0';
    bscan_sel1    <= '0';
    bscan_tdi     <= '0';
    bscan_reset   <= '0';
    bscan_shift   <= '0';
    bscan_update  <= '0';
    bscan_capture <= '0';
  end generate No_BSCAN_ICON;

  Use_Spartan3 : if native_bscan(C_FAMILY) = u_BSCAN_SPARTAN3 and C_USE_BSCAN /= 2 generate
  begin
    BSCAN_SPARTAN3_I : BSCAN_SPARTAN3
      port map (
        UPDATE  => update_i,            -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        SEL1    => sel1,                -- [out std_logic]
        DRCK1   => drck1_i,             -- [out std_logic]
        SEL2    => sel,                 -- [out std_logic]
        DRCK2   => drck_i,              -- [out std_logic]
        CAPTURE => capture,             -- [out std_logic]
        TDO1    => tdo1,                -- [in  std_logic]
        TDO2    => tdo                  -- [in  std_logic]
      );
  end generate Use_Spartan3;

  Use_Spartan3A : if native_bscan(C_FAMILY) = u_BSCAN_SPARTAN3A and C_USE_BSCAN /= 2 generate
  begin
    BSCAN_SPARTAN3A_I : BSCAN_SPARTAN3A
      port map (
        TCK     => open,                -- [out std_logic]
        TMS     => open,                -- [out std_logic]
        CAPTURE => capture,             -- [out std_logic]
        UPDATE  => update_i,            -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        SEL1    => sel1,                -- [out std_logic]
        SEL2    => sel,                 -- [out std_logic]
        DRCK1   => drck1_i,             -- [out std_logic]
        DRCK2   => drck_i,              -- [out std_logic]
        TDO1    => tdo1,                -- [in  std_logic]
        TDO2    => tdo                  -- [in  std_logic]
      );
  end generate Use_Spartan3A;

  Use_Spartan6 : if native_bscan(C_FAMILY) = u_BSCAN_SPARTAN6 and C_USE_BSCAN /= 2 generate
  begin
    BSCAN_SPARTAN6_I : BSCAN_SPARTAN6
      generic map (
        JTAG_CHAIN => C_JTAG_CHAIN)
      port map (
        CAPTURE    => capture,
        DRCK       => drck_i,
        RESET      => reset,
        RUNTEST    => open,
        SEL        => sel,
        SHIFT      => shift,
        TCK        => open,
        TDI        => tdi,
        TMS        => open,
        UPDATE     => update_i,
        TDO        => tdo);

    -- Ground signals pretending to be CHAIN 1
    -- This does not actually use CHAIN 1
    sel1    <= '0';
    drck1_i <= '0';

    -- tdo1 is unused

  end generate Use_Spartan6;

  Use_Virtex4 : if native_bscan(C_FAMILY) = u_BSCAN_VIRTEX4 and C_USE_BSCAN /= 2 generate
  begin
    BSCAN_VIRTEX4_I : BSCAN_VIRTEX4
      generic map (
        JTAG_CHAIN => C_JTAG_CHAIN)
      port map (
        TDO        => tdo,              -- [in  std_logic]
        UPDATE     => update_i,         -- [out std_logic]
        SHIFT      => shift,            -- [out std_logic]
        RESET      => reset,            -- [out std_logic]
        TDI        => tdi,              -- [out std_logic]
        SEL        => sel,              -- [out std_logic]
        DRCK       => drck_i,           -- [out std_logic]
        CAPTURE    => capture);         -- [out std_logic]

    -- Ground signals pretending to be CHAIN 1
    -- This does not actually use CHAIN 1
    sel1    <= '0';
    drck1_i <= '0';

    -- tdo1 is unused

  end generate Use_Virtex4;

  Use_Virtex5 : if native_bscan(C_FAMILY) = u_BSCAN_VIRTEX5 and C_USE_BSCAN /= 2 generate
  begin
    BSCAN_VIRTEX5_I : BSCAN_VIRTEX5
      generic map (
        JTAG_CHAIN => C_JTAG_CHAIN)
      port map (
        TDO        => tdo,              -- [in  std_logic]
        UPDATE     => update_i,         -- [out std_logic]
        SHIFT      => shift,            -- [out std_logic]
        RESET      => reset,            -- [out std_logic]
        TDI        => tdi,              -- [out std_logic]
        SEL        => sel,              -- [out std_logic]
        DRCK       => drck_i,           -- [out std_logic]
        CAPTURE    => capture);         -- [out std_logic]

    -- Ground signals pretending to be CHAIN 1
    -- This does not actually use CHAIN 1
    sel1    <= '0';
    drck1_i <= '0';

    -- tdo1 is unused

  end generate Use_Virtex5;

  Use_Virtex6 : if native_bscan(C_FAMILY) = u_BSCAN_VIRTEX6 and C_USE_BSCAN /= 2 generate
  begin
    BSCAN_VIRTEX6_I : BSCAN_VIRTEX6
      generic map (
        DISABLE_JTAG => false,
        JTAG_CHAIN   => C_JTAG_CHAIN)
      port map (
        CAPTURE      => capture,
        DRCK         => drck_i,
        RESET        => reset,
        RUNTEST      => open,
        SEL          => sel,
        SHIFT        => shift,
        TCK          => open,
        TDI          => tdi,
        TMS          => open,
        UPDATE       => update_i,
        TDO          => tdo
      );

    -- Ground signals pretending to be CHAIN 1
    -- This does not actually use CHAIN 1
    sel1    <= '0';
    drck1_i <= '0';

    -- tdo1 is unused

  end generate Use_Virtex6;

  Use_E2 : if native_bscan(C_FAMILY) = u_BSCANE2  and C_USE_BSCAN /= 2 generate
  begin
    BSCANE2_I : BSCANE2
      generic map (
        DISABLE_JTAG => "FALSE",
        JTAG_CHAIN   => C_JTAG_CHAIN)
      port map (
        CAPTURE      => capture,          -- [out std_logic]
        DRCK         => drck_i,           -- [out std_logic]
        RESET        => reset,            -- [out std_logic]
        RUNTEST      => open,             -- [out std_logic]
        SEL          => sel,              -- [out std_logic]
        SHIFT        => shift,            -- [out std_logic]
        TCK          => open,             -- [out std_logic]
        TDI          => tdi,              -- [out std_logic]
        TMS          => open,             -- [out std_logic]
        UPDATE       => update_i,         -- [out std_logic]
        TDO          => tdo);             -- [in  std_logic]

    -- Ground signals pretending to be CHAIN 1
    -- This does not actually use CHAIN 1
    sel1    <= '0';
    drck1_i <= '0';

    -- tdo1 is unused

  end generate Use_E2;

  Use_External : if C_USE_BSCAN = 2 generate
  begin
    capture       <= bscan_ext_capture;
    drck_i        <= bscan_ext_drck;
    reset         <= bscan_ext_reset;
    sel           <= bscan_ext_sel;
    shift         <= bscan_ext_shift;
    tdi           <= bscan_ext_tdi;
    update_i      <= bscan_ext_update;
    bscan_ext_tdo <= tdo;

    -- Ground signals pretending to be CHAIN 1
    -- This does not actually use CHAIN 1
    sel1    <= '0';
    drck1_i <= '0';

    -- tdo1 is unused

  end generate Use_External;

  BUFG_DRCK1 : BUFG
    port map (
      O => drck1,
      I => drck1_i
    );

-- drck1 <= drck1_i;

  BUFG_DRCK : BUFG
    port map (
      O => drck,
      I => drck_i
    );

-- drck <= drck_i;

-- BUFG_UPDATE : BUFG
-- port map (
-- O => update,
-- I => update_i
-- );

  update <= update_i;

  ---------------------------------------------------------------------------
  -- MDM core
  ---------------------------------------------------------------------------
  MDM_Core_I1 : MDM_Core
    generic map (
      C_USE_CONFIG_RESET    => C_USE_CONFIG_RESET,     -- [integer = 0]
      C_BASEADDR            => C_BASEADDR,             -- [std_logic_vector(0 to 31)]
      C_HIGHADDR            => C_HIGHADDR,             -- [std_logic_vector(0 to 31)]
      C_INTERCONNECT        => C_INTERCONNECT,
      C_SPLB_AWIDTH         => C_SPLB_AWIDTH,          -- [integer = 32]
      C_SPLB_DWIDTH         => C_SPLB_DWIDTH,          -- [integer = 32]
      C_SPLB_P2P            => C_SPLB_P2P,             -- [integer = 0]
      C_SPLB_MID_WIDTH      => C_SPLB_MID_WIDTH,       -- [integer = 3]
      C_SPLB_NUM_MASTERS    => C_SPLB_NUM_MASTERS,     -- [integer = 8]
      C_SPLB_NATIVE_DWIDTH  => C_SPLB_NATIVE_DWIDTH,   -- [integer = 32]
      C_SPLB_SUPPORT_BURSTS => C_SPLB_SUPPORT_BURSTS,  -- [integer = 0]
      C_MB_DBG_PORTS        => C_MB_DBG_PORTS,         -- [integer]
      C_USE_UART            => C_USE_UART,             -- [integer]
      C_UART_WIDTH          => 8                       -- [integer]
    )

    port map (
      -- Global signals
      Config_Reset  => Config_Reset,    -- [in  std_logic]

      SPLB_Clk      => SPLB_Clk,        -- [in  std_logic]
      SPLB_Rst      => SPLB_Rst,        -- [in  std_logic]

      Interrupt     => Interrupt,       -- [out std_logic]
      Ext_BRK       => Ext_BRK,         -- [out std_logic]
      Ext_NM_BRK    => Ext_NM_BRK,      -- [out std_logic]
      Debug_SYS_Rst => Debug_SYS_Rst,   -- [out std_logic]

      -- PLBv46 signals
      PLB_ABus       => PLB_ABus,       -- [in  std_logic_vector(0 to 31)]
      PLB_UABus      => PLB_UABus,      -- [in  std_logic_vector(0 to 31)]
      PLB_PAValid    => PLB_PAValid,    -- [in  std_logic]
      PLB_SAValid    => PLB_SAValid,    -- [in  std_logic]
      PLB_rdPrim     => PLB_rdPrim,     -- [in  std_logic]
      PLB_wrPrim     => PLB_wrPrim,     -- [in  std_logic]
      PLB_masterID   => PLB_masterID,   -- [in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1)]
      PLB_abort      => PLB_abort,      -- [in  std_logic]
      PLB_busLock    => PLB_busLock,    -- [in  std_logic]
      PLB_RNW        => PLB_RNW,        -- [in  std_logic]
      PLB_BE         => PLB_BE,         -- [in  std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1)]
      PLB_MSize      => PLB_MSize,      -- [in  std_logic_vector(0 to 1)]
      PLB_size       => PLB_size,       -- [in  std_logic_vector(0 to 3)]
      PLB_type       => PLB_type,       -- [in  std_logic_vector(0 to 2)]
      PLB_lockErr    => PLB_lockErr,    -- [in  std_logic]
      PLB_wrDBus     => PLB_wrDBus,     -- [in  std_logic_vector(0 to C_SPLB_DWIDTH-1)]
      PLB_wrBurst    => PLB_wrBurst,    -- [in  std_logic]
      PLB_rdBurst    => PLB_rdBurst,    -- [in  std_logic]
      PLB_wrPendReq  => PLB_wrPendReq,  -- [in  std_logic]
      PLB_rdPendReq  => PLB_rdPendReq,  -- [in  std_logic]
      PLB_wrPendPri  => PLB_wrPendPri,  -- [in  std_logic_vector(0 to 1)]
      PLB_rdPendPri  => PLB_rdPendPri,  -- [in  std_logic_vector(0 to 1)]
      PLB_reqPri     => PLB_reqPri,     -- [in  std_logic_vector(0 to 1)]
      PLB_TAttribute => PLB_TAttribute, -- [in  std_logic_vector(0 to 15)]

      Sl_addrAck     => Sl_addrAck,     -- [out std_logic]
      Sl_SSize       => Sl_SSize,       -- [out std_logic_vector(0 to 1)]
      Sl_wait        => Sl_wait,        -- [out std_logic]
      Sl_rearbitrate => Sl_rearbitrate, -- [out std_logic]
      Sl_wrDAck      => Sl_wrDAck,      -- [out std_logic]
      Sl_wrComp      => Sl_wrComp,      -- [out std_logic]
      Sl_wrBTerm     => Sl_wrBTerm,     -- [out std_logic]
      Sl_rdDBus      => Sl_rdDBus,      -- [out std_logic_vector(0 to C_SPLB_DWIDTH-1)]
      Sl_rdWdAddr    => Sl_rdWdAddr,    -- [out std_logic_vector(0 to 3)]
      Sl_rdDAck      => Sl_rdDAck,      -- [out std_logic]
      Sl_rdComp      => Sl_rdComp,      -- [out std_logic]
      Sl_rdBTerm     => Sl_rdBTerm,     -- [out std_logic]
      Sl_MBusy       => Sl_MBusy,       -- [out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)]
      Sl_MWrErr      => Sl_MWrErr,      -- [out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)]
      Sl_MRdErr      => Sl_MRdErr,      -- [out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)]
      Sl_MIRQ        => Sl_MIRQ,        -- [out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)]

      -- AXI IPIC signals
      bus2ip_clk    => bus2ip_clk,
      bus2ip_resetn => bus2ip_resetn,
      bus2ip_data   => bus2ip_data(7 downto 0),
      bus2ip_rdce   => bus2ip_rdce(3 downto 0),
      bus2ip_wrce   => bus2ip_wrce(3 downto 0),
      bus2ip_cs     => bus2ip_cs(0),
      ip2bus_rdack  => ip2bus_rdack,
      ip2bus_wrack  => ip2bus_wrack,
      ip2bus_error  => ip2bus_error,
      ip2bus_data   => ip2bus_data(7 downto 0),

      -- JTAG signals
      TDI     => tdi,                   -- [in  std_logic]
      RESET   => reset,                 -- [in  std_logic]
      UPDATE  => update,                -- [in  std_logic]
      SHIFT   => shift,                 -- [in  std_logic]
      CAPTURE => capture,               -- [in  std_logic]
      SEL     => sel,                   -- [in  std_logic]
      DRCK    => drck,                  -- [in  std_logic]
      TDO     => tdo,                   -- [out std_logic]

      -- MicroBlaze Debug Signals
      Dbg_Clk_0     => Dbg_Clk_0,       -- [out std_logic]
      Dbg_TDI_0     => Dbg_TDI_0,       -- [out std_logic]
      Dbg_TDO_0     => Dbg_TDO_0,       -- [in  std_logic]
      Dbg_Reg_En_0  => Dbg_Reg_En_0,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_0 => Dbg_Capture_0,   -- [out std_logic]
      Dbg_Shift_0   => Dbg_Shift_0,     -- [out std_logic]
      Dbg_Update_0  => Dbg_Update_0,    -- [out std_logic]
      Dbg_Rst_0     => Dbg_Rst_0,       -- [out std_logic]

      Dbg_Clk_1     => Dbg_Clk_1,       -- [out std_logic]
      Dbg_TDI_1     => Dbg_TDI_1,       -- [out std_logic]
      Dbg_TDO_1     => Dbg_TDO_1,       -- [in  std_logic]
      Dbg_Reg_En_1  => Dbg_Reg_En_1,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_1 => Dbg_Capture_1,   -- [out std_logic]
      Dbg_Shift_1   => Dbg_Shift_1,     -- [out std_logic]
      Dbg_Update_1  => Dbg_Update_1,    -- [out std_logic]
      Dbg_Rst_1     => Dbg_Rst_1,       -- [out std_logic]

      Dbg_Clk_2     => Dbg_Clk_2,       -- [out std_logic]
      Dbg_TDI_2     => Dbg_TDI_2,       -- [out std_logic]
      Dbg_TDO_2     => Dbg_TDO_2,       -- [in  std_logic]
      Dbg_Reg_En_2  => Dbg_Reg_En_2,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_2 => Dbg_Capture_2,   -- [out std_logic]
      Dbg_Shift_2   => Dbg_Shift_2,     -- [out std_logic]
      Dbg_Update_2  => Dbg_Update_2,    -- [out std_logic]
      Dbg_Rst_2     => Dbg_Rst_2,       -- [out std_logic]

      Dbg_Clk_3     => Dbg_Clk_3,       -- [out std_logic]
      Dbg_TDI_3     => Dbg_TDI_3,       -- [out std_logic]
      Dbg_TDO_3     => Dbg_TDO_3,       -- [in  std_logic]
      Dbg_Reg_En_3  => Dbg_Reg_En_3,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_3 => Dbg_Capture_3,   -- [out std_logic]
      Dbg_Shift_3   => Dbg_Shift_3,     -- [out std_logic]
      Dbg_Update_3  => Dbg_Update_3,    -- [out std_logic]
      Dbg_Rst_3     => Dbg_Rst_3,       -- [out std_logic]

      Dbg_Clk_4     => Dbg_Clk_4,       -- [out std_logic]
      Dbg_TDI_4     => Dbg_TDI_4,       -- [out std_logic]
      Dbg_TDO_4     => Dbg_TDO_4,       -- [in  std_logic]
      Dbg_Reg_En_4  => Dbg_Reg_En_4,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_4 => Dbg_Capture_4,   -- [out std_logic]
      Dbg_Shift_4   => Dbg_Shift_4,     -- [out std_logic]
      Dbg_Update_4  => Dbg_Update_4,    -- [out std_logic]
      Dbg_Rst_4     => Dbg_Rst_4,       -- [out std_logic]

      Dbg_Clk_5     => Dbg_Clk_5,       -- [out std_logic]
      Dbg_TDI_5     => Dbg_TDI_5,       -- [out std_logic]
      Dbg_TDO_5     => Dbg_TDO_5,       -- [in  std_logic]
      Dbg_Reg_En_5  => Dbg_Reg_En_5,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_5 => Dbg_Capture_5,   -- [out std_logic]
      Dbg_Shift_5   => Dbg_Shift_5,     -- [out std_logic]
      Dbg_Update_5  => Dbg_Update_5,    -- [out std_logic]
      Dbg_Rst_5     => Dbg_Rst_5,       -- [out std_logic]

      Dbg_Clk_6     => Dbg_Clk_6,       -- [out std_logic]
      Dbg_TDI_6     => Dbg_TDI_6,       -- [out std_logic]
      Dbg_TDO_6     => Dbg_TDO_6,       -- [in  std_logic]
      Dbg_Reg_En_6  => Dbg_Reg_En_6,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_6 => Dbg_Capture_6,   -- [out std_logic]
      Dbg_Shift_6   => Dbg_Shift_6,     -- [out std_logic]
      Dbg_Update_6  => Dbg_Update_6,    -- [out std_logic]
      Dbg_Rst_6     => Dbg_Rst_6,       -- [out std_logic]

      Dbg_Clk_7     => Dbg_Clk_7,       -- [out std_logic]
      Dbg_TDI_7     => Dbg_TDI_7,       -- [out std_logic]
      Dbg_TDO_7     => Dbg_TDO_7,       -- [in  std_logic]
      Dbg_Reg_En_7  => Dbg_Reg_En_7,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_7 => Dbg_Capture_7,   -- [out std_logic]
      Dbg_Shift_7   => Dbg_Shift_7,     -- [out std_logic]
      Dbg_Update_7  => Dbg_Update_7,    -- [out std_logic]
      Dbg_Rst_7     => Dbg_Rst_7,       -- [out std_logic]

      Dbg_Clk_8     => Dbg_Clk_8,       -- [out std_logic]
      Dbg_TDI_8     => Dbg_TDI_8,       -- [out std_logic]
      Dbg_TDO_8     => Dbg_TDO_8,       -- [in  std_logic]
      Dbg_Reg_En_8  => Dbg_Reg_En_8,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_8 => Dbg_Capture_8,   -- [out std_logic]
      Dbg_Shift_8   => Dbg_Shift_8,     -- [out std_logic]
      Dbg_Update_8  => Dbg_Update_8,    -- [out std_logic]
      Dbg_Rst_8     => Dbg_Rst_8,       -- [out std_logic]

      Dbg_Clk_9     => Dbg_Clk_9,       -- [out std_logic]
      Dbg_TDI_9     => Dbg_TDI_9,       -- [out std_logic]
      Dbg_TDO_9     => Dbg_TDO_9,       -- [in  std_logic]
      Dbg_Reg_En_9  => Dbg_Reg_En_9,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_9 => Dbg_Capture_9,   -- [out std_logic]
      Dbg_Shift_9   => Dbg_Shift_9,     -- [out std_logic]
      Dbg_Update_9  => Dbg_Update_9,    -- [out std_logic]
      Dbg_Rst_9     => Dbg_Rst_9,       -- [out std_logic]

      Dbg_Clk_10     => Dbg_Clk_10,       -- [out std_logic]
      Dbg_TDI_10     => Dbg_TDI_10,       -- [out std_logic]
      Dbg_TDO_10     => Dbg_TDO_10,       -- [in  std_logic]
      Dbg_Reg_En_10  => Dbg_Reg_En_10,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_10 => Dbg_Capture_10,   -- [out std_logic]
      Dbg_Shift_10   => Dbg_Shift_10,     -- [out std_logic]
      Dbg_Update_10  => Dbg_Update_10,    -- [out std_logic]
      Dbg_Rst_10     => Dbg_Rst_10,       -- [out std_logic]

      Dbg_Clk_11     => Dbg_Clk_11,       -- [out std_logic]
      Dbg_TDI_11     => Dbg_TDI_11,       -- [out std_logic]
      Dbg_TDO_11     => Dbg_TDO_11,       -- [in  std_logic]
      Dbg_Reg_En_11  => Dbg_Reg_En_11,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_11 => Dbg_Capture_11,   -- [out std_logic]
      Dbg_Shift_11   => Dbg_Shift_11,     -- [out std_logic]
      Dbg_Update_11  => Dbg_Update_11,    -- [out std_logic]
      Dbg_Rst_11     => Dbg_Rst_11,       -- [out std_logic]

      Dbg_Clk_12     => Dbg_Clk_12,       -- [out std_logic]
      Dbg_TDI_12     => Dbg_TDI_12,       -- [out std_logic]
      Dbg_TDO_12     => Dbg_TDO_12,       -- [in  std_logic]
      Dbg_Reg_En_12  => Dbg_Reg_En_12,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_12 => Dbg_Capture_12,   -- [out std_logic]
      Dbg_Shift_12   => Dbg_Shift_12,     -- [out std_logic]
      Dbg_Update_12  => Dbg_Update_12,    -- [out std_logic]
      Dbg_Rst_12     => Dbg_Rst_12,       -- [out std_logic]

      Dbg_Clk_13     => Dbg_Clk_13,       -- [out std_logic]
      Dbg_TDI_13     => Dbg_TDI_13,       -- [out std_logic]
      Dbg_TDO_13     => Dbg_TDO_13,       -- [in  std_logic]
      Dbg_Reg_En_13  => Dbg_Reg_En_13,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_13 => Dbg_Capture_13,   -- [out std_logic]
      Dbg_Shift_13   => Dbg_Shift_13,     -- [out std_logic]
      Dbg_Update_13  => Dbg_Update_13,    -- [out std_logic]
      Dbg_Rst_13     => Dbg_Rst_13,       -- [out std_logic]

      Dbg_Clk_14     => Dbg_Clk_14,       -- [out std_logic]
      Dbg_TDI_14     => Dbg_TDI_14,       -- [out std_logic]
      Dbg_TDO_14     => Dbg_TDO_14,       -- [in  std_logic]
      Dbg_Reg_En_14  => Dbg_Reg_En_14,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_14 => Dbg_Capture_14,   -- [out std_logic]
      Dbg_Shift_14   => Dbg_Shift_14,     -- [out std_logic]
      Dbg_Update_14  => Dbg_Update_14,    -- [out std_logic]
      Dbg_Rst_14     => Dbg_Rst_14,       -- [out std_logic]

      Dbg_Clk_15     => Dbg_Clk_15,       -- [out std_logic]
      Dbg_TDI_15     => Dbg_TDI_15,       -- [out std_logic]
      Dbg_TDO_15     => Dbg_TDO_15,       -- [in  std_logic]
      Dbg_Reg_En_15  => Dbg_Reg_En_15,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_15 => Dbg_Capture_15,   -- [out std_logic]
      Dbg_Shift_15   => Dbg_Shift_15,     -- [out std_logic]
      Dbg_Update_15  => Dbg_Update_15,    -- [out std_logic]
      Dbg_Rst_15     => Dbg_Rst_15,       -- [out std_logic]

      Dbg_Clk_16     => Dbg_Clk_16,       -- [out std_logic]
      Dbg_TDI_16     => Dbg_TDI_16,       -- [out std_logic]
      Dbg_TDO_16     => Dbg_TDO_16,       -- [in  std_logic]
      Dbg_Reg_En_16  => Dbg_Reg_En_16,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_16 => Dbg_Capture_16,   -- [out std_logic]
      Dbg_Shift_16   => Dbg_Shift_16,     -- [out std_logic]
      Dbg_Update_16  => Dbg_Update_16,    -- [out std_logic]
      Dbg_Rst_16     => Dbg_Rst_16,       -- [out std_logic]

      Dbg_Clk_17     => Dbg_Clk_17,       -- [out std_logic]
      Dbg_TDI_17     => Dbg_TDI_17,       -- [out std_logic]
      Dbg_TDO_17     => Dbg_TDO_17,       -- [in  std_logic]
      Dbg_Reg_En_17  => Dbg_Reg_En_17,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_17 => Dbg_Capture_17,   -- [out std_logic]
      Dbg_Shift_17   => Dbg_Shift_17,     -- [out std_logic]
      Dbg_Update_17  => Dbg_Update_17,    -- [out std_logic]
      Dbg_Rst_17     => Dbg_Rst_17,       -- [out std_logic]

      Dbg_Clk_18     => Dbg_Clk_18,       -- [out std_logic]
      Dbg_TDI_18     => Dbg_TDI_18,       -- [out std_logic]
      Dbg_TDO_18     => Dbg_TDO_18,       -- [in  std_logic]
      Dbg_Reg_En_18  => Dbg_Reg_En_18,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_18 => Dbg_Capture_18,   -- [out std_logic]
      Dbg_Shift_18   => Dbg_Shift_18,     -- [out std_logic]
      Dbg_Update_18  => Dbg_Update_18,    -- [out std_logic]
      Dbg_Rst_18     => Dbg_Rst_18,       -- [out std_logic]

      Dbg_Clk_19     => Dbg_Clk_19,       -- [out std_logic]
      Dbg_TDI_19     => Dbg_TDI_19,       -- [out std_logic]
      Dbg_TDO_19     => Dbg_TDO_19,       -- [in  std_logic]
      Dbg_Reg_En_19  => Dbg_Reg_En_19,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_19 => Dbg_Capture_19,   -- [out std_logic]
      Dbg_Shift_19   => Dbg_Shift_19,     -- [out std_logic]
      Dbg_Update_19  => Dbg_Update_19,    -- [out std_logic]
      Dbg_Rst_19     => Dbg_Rst_19,       -- [out std_logic]

      Dbg_Clk_20     => Dbg_Clk_20,       -- [out std_logic]
      Dbg_TDI_20     => Dbg_TDI_20,       -- [out std_logic]
      Dbg_TDO_20     => Dbg_TDO_20,       -- [in  std_logic]
      Dbg_Reg_En_20  => Dbg_Reg_En_20,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_20 => Dbg_Capture_20,   -- [out std_logic]
      Dbg_Shift_20   => Dbg_Shift_20,     -- [out std_logic]
      Dbg_Update_20  => Dbg_Update_20,    -- [out std_logic]
      Dbg_Rst_20     => Dbg_Rst_20,       -- [out std_logic]

      Dbg_Clk_21     => Dbg_Clk_21,       -- [out std_logic]
      Dbg_TDI_21     => Dbg_TDI_21,       -- [out std_logic]
      Dbg_TDO_21     => Dbg_TDO_21,       -- [in  std_logic]
      Dbg_Reg_En_21  => Dbg_Reg_En_21,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_21 => Dbg_Capture_21,   -- [out std_logic]
      Dbg_Shift_21   => Dbg_Shift_21,     -- [out std_logic]
      Dbg_Update_21  => Dbg_Update_21,    -- [out std_logic]
      Dbg_Rst_21     => Dbg_Rst_21,       -- [out std_logic]

      Dbg_Clk_22     => Dbg_Clk_22,       -- [out std_logic]
      Dbg_TDI_22     => Dbg_TDI_22,       -- [out std_logic]
      Dbg_TDO_22     => Dbg_TDO_22,       -- [in  std_logic]
      Dbg_Reg_En_22  => Dbg_Reg_En_22,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_22 => Dbg_Capture_22,   -- [out std_logic]
      Dbg_Shift_22   => Dbg_Shift_22,     -- [out std_logic]
      Dbg_Update_22  => Dbg_Update_22,    -- [out std_logic]
      Dbg_Rst_22     => Dbg_Rst_22,       -- [out std_logic]

      Dbg_Clk_23     => Dbg_Clk_23,       -- [out std_logic]
      Dbg_TDI_23     => Dbg_TDI_23,       -- [out std_logic]
      Dbg_TDO_23     => Dbg_TDO_23,       -- [in  std_logic]
      Dbg_Reg_En_23  => Dbg_Reg_En_23,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_23 => Dbg_Capture_23,   -- [out std_logic]
      Dbg_Shift_23   => Dbg_Shift_23,     -- [out std_logic]
      Dbg_Update_23  => Dbg_Update_23,    -- [out std_logic]
      Dbg_Rst_23     => Dbg_Rst_23,       -- [out std_logic]

      Dbg_Clk_24     => Dbg_Clk_24,       -- [out std_logic]
      Dbg_TDI_24     => Dbg_TDI_24,       -- [out std_logic]
      Dbg_TDO_24     => Dbg_TDO_24,       -- [in  std_logic]
      Dbg_Reg_En_24  => Dbg_Reg_En_24,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_24 => Dbg_Capture_24,   -- [out std_logic]
      Dbg_Shift_24   => Dbg_Shift_24,     -- [out std_logic]
      Dbg_Update_24  => Dbg_Update_24,    -- [out std_logic]
      Dbg_Rst_24     => Dbg_Rst_24,       -- [out std_logic]

      Dbg_Clk_25     => Dbg_Clk_25,       -- [out std_logic]
      Dbg_TDI_25     => Dbg_TDI_25,       -- [out std_logic]
      Dbg_TDO_25     => Dbg_TDO_25,       -- [in  std_logic]
      Dbg_Reg_En_25  => Dbg_Reg_En_25,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_25 => Dbg_Capture_25,   -- [out std_logic]
      Dbg_Shift_25   => Dbg_Shift_25,     -- [out std_logic]
      Dbg_Update_25  => Dbg_Update_25,    -- [out std_logic]
      Dbg_Rst_25     => Dbg_Rst_25,       -- [out std_logic]

      Dbg_Clk_26     => Dbg_Clk_26,       -- [out std_logic]
      Dbg_TDI_26     => Dbg_TDI_26,       -- [out std_logic]
      Dbg_TDO_26     => Dbg_TDO_26,       -- [in  std_logic]
      Dbg_Reg_En_26  => Dbg_Reg_En_26,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_26 => Dbg_Capture_26,   -- [out std_logic]
      Dbg_Shift_26   => Dbg_Shift_26,     -- [out std_logic]
      Dbg_Update_26  => Dbg_Update_26,    -- [out std_logic]
      Dbg_Rst_26     => Dbg_Rst_26,       -- [out std_logic]

      Dbg_Clk_27     => Dbg_Clk_27,       -- [out std_logic]
      Dbg_TDI_27     => Dbg_TDI_27,       -- [out std_logic]
      Dbg_TDO_27     => Dbg_TDO_27,       -- [in  std_logic]
      Dbg_Reg_En_27  => Dbg_Reg_En_27,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_27 => Dbg_Capture_27,   -- [out std_logic]
      Dbg_Shift_27   => Dbg_Shift_27,     -- [out std_logic]
      Dbg_Update_27  => Dbg_Update_27,    -- [out std_logic]
      Dbg_Rst_27     => Dbg_Rst_27,       -- [out std_logic]

      Dbg_Clk_28     => Dbg_Clk_28,       -- [out std_logic]
      Dbg_TDI_28     => Dbg_TDI_28,       -- [out std_logic]
      Dbg_TDO_28     => Dbg_TDO_28,       -- [in  std_logic]
      Dbg_Reg_En_28  => Dbg_Reg_En_28,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_28 => Dbg_Capture_28,   -- [out std_logic]
      Dbg_Shift_28   => Dbg_Shift_28,     -- [out std_logic]
      Dbg_Update_28  => Dbg_Update_28,    -- [out std_logic]
      Dbg_Rst_28     => Dbg_Rst_28,       -- [out std_logic]

      Dbg_Clk_29     => Dbg_Clk_29,       -- [out std_logic]
      Dbg_TDI_29     => Dbg_TDI_29,       -- [out std_logic]
      Dbg_TDO_29     => Dbg_TDO_29,       -- [in  std_logic]
      Dbg_Reg_En_29  => Dbg_Reg_En_29,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_29 => Dbg_Capture_29,   -- [out std_logic]
      Dbg_Shift_29   => Dbg_Shift_29,     -- [out std_logic]
      Dbg_Update_29  => Dbg_Update_29,    -- [out std_logic]
      Dbg_Rst_29     => Dbg_Rst_29,       -- [out std_logic]

      Dbg_Clk_30     => Dbg_Clk_30,       -- [out std_logic]
      Dbg_TDI_30     => Dbg_TDI_30,       -- [out std_logic]
      Dbg_TDO_30     => Dbg_TDO_30,       -- [in  std_logic]
      Dbg_Reg_En_30  => Dbg_Reg_En_30,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_30 => Dbg_Capture_30,   -- [out std_logic]
      Dbg_Shift_30   => Dbg_Shift_30,     -- [out std_logic]
      Dbg_Update_30  => Dbg_Update_30,    -- [out std_logic]
      Dbg_Rst_30     => Dbg_Rst_30,       -- [out std_logic]

      Dbg_Clk_31     => Dbg_Clk_31,       -- [out std_logic]
      Dbg_TDI_31     => Dbg_TDI_31,       -- [out std_logic]
      Dbg_TDO_31     => Dbg_TDO_31,       -- [in  std_logic]
      Dbg_Reg_En_31  => Dbg_Reg_En_31,    -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_31 => Dbg_Capture_31,   -- [out std_logic]
      Dbg_Shift_31   => Dbg_Shift_31,     -- [out std_logic]
      Dbg_Update_31  => Dbg_Update_31,    -- [out std_logic]
      Dbg_Rst_31     => Dbg_Rst_31,       -- [out std_logic]

      Ext_JTAG_DRCK    => Ext_JTAG_DRCK,
      Ext_JTAG_RESET   => Ext_JTAG_RESET,
      Ext_JTAG_SEL     => Ext_JTAG_SEL,
      Ext_JTAG_CAPTURE => Ext_JTAG_CAPTURE,
      Ext_JTAG_SHIFT   => Ext_JTAG_SHIFT,
      Ext_JTAG_UPDATE  => Ext_JTAG_UPDATE,
      Ext_JTAG_TDI     => Ext_JTAG_TDI,
      Ext_JTAG_TDO     => Ext_JTAG_TDO
    );

  Use_PLB : if (C_INTERCONNECT = 1) generate
  begin
    bus2ip_clk    <= '0';
    bus2ip_resetn <= '0';
    bus2ip_data   <= (others => '0');
    bus2ip_rdce   <= (others => '0');
    bus2ip_wrce   <= (others => '0');
    bus2ip_cs     <= (others => '0');

    -- Unused AXI output signals
    S_AXI_AWREADY <= '0';
    S_AXI_WREADY  <= '0';
    S_AXI_BRESP   <= (others => '0');
    S_AXI_BVALID  <= '0';
    S_AXI_ARREADY <= '0';
    S_AXI_RDATA   <= (others => '0');
    S_AXI_RRESP   <= (others => '0');
    S_AXI_RVALID  <= '0';
  end generate Use_PLB;

  Use_AXI_IPIF : if (C_INTERCONNECT = 2 and C_USE_UART = 1) generate
  begin
    -- ip2bus_data assignment - as core is using maximum of 8 bits
    ip2bus_data((C_S_AXI_DATA_WIDTH-1) downto 8) <= (others => '0');

    ---------------------------------------------------------------------------
    -- AXI lite IPIF
    ---------------------------------------------------------------------------
    AXI_LITE_IPIF_I : entity axi_lite_ipif_v1_01_a.axi_lite_ipif
      generic map (
        C_FAMILY               => C_FAMILY,
        C_S_AXI_ADDR_WIDTH     => C_S_AXI_ADDR_WIDTH,
        C_S_AXI_DATA_WIDTH     => C_S_AXI_DATA_WIDTH,
        C_S_AXI_MIN_SIZE       => C_S_AXI_MIN_SIZE,
        C_USE_WSTRB            => C_USE_WSTRB,
        C_DPHASE_TIMEOUT       => C_DPHASE_TIMEOUT,
        C_ARD_ADDR_RANGE_ARRAY => C_ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY     => C_ARD_NUM_CE_ARRAY
      )

      port map(
        S_AXI_ACLK    => S_AXI_ACLK,
        S_AXI_ARESETN => S_AXI_ARESETN,
        S_AXI_AWADDR  => S_AXI_AWADDR,
        S_AXI_AWVALID => S_AXI_AWVALID,
        S_AXI_AWREADY => S_AXI_AWREADY,
        S_AXI_WDATA   => S_AXI_WDATA,
        S_AXI_WSTRB   => S_AXI_WSTRB,
        S_AXI_WVALID  => S_AXI_WVALID,
        S_AXI_WREADY  => S_AXI_WREADY,
        S_AXI_BRESP   => S_AXI_BRESP,
        S_AXI_BVALID  => S_AXI_BVALID,
        S_AXI_BREADY  => S_AXI_BREADY,
        S_AXI_ARADDR  => S_AXI_ARADDR,
        S_AXI_ARVALID => S_AXI_ARVALID,
        S_AXI_ARREADY => S_AXI_ARREADY,
        S_AXI_RDATA   => S_AXI_RDATA,
        S_AXI_RRESP   => S_AXI_RRESP,
        S_AXI_RVALID  => S_AXI_RVALID,
        S_AXI_RREADY  => S_AXI_RREADY,

        -- IP Interconnect (IPIC) port signals
        Bus2IP_Clk    => bus2ip_clk,
        Bus2IP_Resetn => bus2ip_resetn,
        IP2Bus_Data   => ip2bus_data,
        IP2Bus_WrAck  => ip2bus_wrack,
        IP2Bus_RdAck  => ip2bus_rdack,
        IP2Bus_Error  => ip2bus_error,
        Bus2IP_Addr   => open,
        Bus2IP_Data   => bus2ip_data,
        Bus2IP_RNW    => open,
        Bus2IP_BE     => open,
        Bus2IP_CS     => bus2ip_cs,
        Bus2IP_RdCE   => bus2ip_rdce,
        Bus2IP_WrCE   => bus2ip_wrce
      );

  end generate Use_AXI_IPIF;

end architecture IMP;
