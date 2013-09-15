-------------------------------------------------------------------------------
-- $Id: mdm_core.vhd,v 1.1.2.2 2010/11/30 08:14:03 stefana Exp $
-------------------------------------------------------------------------------
-- mdm_core.vhd - Entity and architecture
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
-- Filename:        mdm_core.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              mdm_core.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision$
-- Date:            $Date$
--
-- History:
--   goran   2003-02-13    First Version
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
entity MDM_Core is

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
    C_UART_WIDTH          : integer := 8
  );

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

    -- IPIC signals
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
end entity MDM_Core;

library proc_common_v3_00_a;
use proc_common_v3_00_a.pselect;

library unisim;
use unisim.vcomponents.all;

library mdm_v2_10_a;
use mdm_v2_10_a.all;

architecture IMP of MDM_CORE is

  component pselect
    generic (
      C_AB   :     integer;
      C_AW   :     integer;
      C_BAR  :     std_logic_vector
    );
    port (
      A      : in  std_logic_vector(0 to C_AW-1);
      AValid : in  std_logic;
      cs     : out std_logic
    );
  end component pselect;

  -- Returns at least 1
  function MakePos (a : integer) return integer is
  begin
    if a < 1 then
      return 1;
    else
      return a;
    end if;
  end function MakePos;

  constant C_EN_WIDTH : integer := MakePos(C_MB_DBG_PORTS);

  component JTAG_CONTROL
    generic (
      C_MB_DBG_PORTS     : integer;
      C_USE_CONFIG_RESET : integer;
      C_USE_UART         : integer;
      C_UART_WIDTH       : integer;
      C_EN_WIDTH         : integer := 1
    );
    port (
      -- Global signals
      Config_Reset    : in std_logic;

      Clk             : in std_logic;
      Rst             : in std_logic;

      Clear_Ext_BRK   : in  std_logic;
      Ext_BRK         : out std_logic;
      Ext_NM_BRK      : out std_logic;
      Debug_SYS_Rst   : out std_logic;
      Debug_Rst       : out std_logic;

      Read_RX_FIFO    : in  std_logic;
      Reset_RX_FIFO   : in  std_logic;
      RX_Data         : out std_logic_vector(0 to C_UART_WIDTH-1);
      RX_Data_Present : out std_logic;
      RX_Buffer_Full  : out std_logic;

      Write_TX_FIFO   : in  std_logic;
      Reset_TX_FIFO   : in  std_logic;
      TX_Data         : in  std_logic_vector(0 to C_UART_WIDTH-1);
      TX_Buffer_Full  : out std_logic;
      TX_Buffer_Empty : out std_logic;

      -- MDM signals
      TDI     : in  std_logic;
      RESET   : in  std_logic;
      UPDATE  : in  std_logic;
      SHIFT   : in  std_logic;
      CAPTURE : in  std_logic;
      SEL     : in  std_logic;
      DRCK    : in  std_logic;
      TDO     : out std_logic;

      -- MicroBlaze Debug Signals
      MB_Debug_Enabled : out std_logic_vector(C_EN_WIDTH-1 downto 0);
      Dbg_Clk          : out std_logic;
      Dbg_TDI          : out std_logic;
      Dbg_TDO          : in  std_logic;
      Dbg_Reg_En       : out std_logic_vector(0 to 7);
      Dbg_Capture      : out std_logic;
      Dbg_Shift        : out std_logic;
      Dbg_Update       : out std_logic

    );
  end component JTAG_CONTROL;


  -- Returns the minimum value of the two parameters
  function IntMin (a, b : integer) return integer is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function IntMin;

  constant RX_FIFO_ADR    : std_logic_vector(0 to 1) := "00";
  constant TX_FIFO_ADR    : std_logic_vector(0 to 1) := "01";
  constant STATUS_REG_ADR : std_logic_vector(0 to 1) := "10";
  constant CTRL_REG_ADR   : std_logic_vector(0 to 1) := "11";

  -- Read Only
  signal status_Reg : std_logic_vector(0 to 7);
  -- bit 7 rx_Data_Present
  -- bit 6 rx_Buffer_Full
  -- bit 5 tx_Buffer_Empty
  -- bit 4 tx_Buffer_Full
  -- bit 3 enable_interrupts

  -- Write Only
  -- Control Register
  -- bit 0-2 Dont'Care
  -- bit 3   enable_interrupts
  -- bit 4   Dont'Care
  -- bit 5   Clear Ext BRK signal
  -- bit 6   Reset_RX_FIFO
  -- bit 7   Reset_TX_FIFO

  signal config_reset_i    : std_logic;
  signal clear_Ext_BRK     : std_logic;

  signal enable_interrupts : std_logic;
  signal read_RX_FIFO      : std_logic;
  signal reset_RX_FIFO     : std_logic;

  signal rx_Data         : std_logic_vector(0 to C_UART_WIDTH-1);
  signal rx_Data_Present : std_logic;
  signal rx_Buffer_Full  : std_logic;

  signal tx_Data         : std_logic_vector(0 to C_UART_WIDTH-1);
  signal write_TX_FIFO   : std_logic;
  signal reset_TX_FIFO   : std_logic;
  signal tx_Buffer_Full  : std_logic;
  signal tx_Buffer_Empty : std_logic;

  signal xfer_Ack   : std_logic;
  signal mdm_Dbus_i : std_logic_vector(0 to 31);  -- Check!

  signal mdm_CS   : std_logic;  -- Valid address in a address phase
  signal mdm_CS_1 : std_logic;  -- Active as long as mdm_CS is active
  signal mdm_CS_2 : std_logic;
  signal mdm_CS_3 : std_logic;
  
  signal valid_access           : std_logic;  -- Active during the address phase (2 clock cycles)
  signal valid_access_1         : std_logic;  -- Will be a 1 clock delayed valid_access signal
  signal valid_access_2         : std_logic;  -- Active only 1 clock cycle
  signal reading                : std_logic;  -- Valid reading access
  signal valid_access_2_reading : std_logic;  -- signal to drive out data bus on a read access
  signal sl_rdDAck_i            : std_logic;
  signal sl_wrDAck_i            : std_logic;

  constant C_AWIDTH : natural := 32;

  function Addr_Bits (x, y : std_logic_vector(0 to C_AWIDTH-1)) return integer is
    variable addr_nor      : std_logic_vector(0 to C_AWIDTH-1);
  begin
    addr_nor := x xor y;
    for i in 0 to C_AWIDTH-1 loop
      if addr_nor(i) = '1' then return i;
      end if;
    end loop;
    return(C_AWIDTH);
  end function Addr_Bits;

  constant C_AB : integer := Addr_Bits(C_HIGHADDR, C_BASEADDR);

  signal TDO_i : std_logic;

  signal MB_Debug_Enabled : std_logic_vector(C_EN_WIDTH-1 downto 0);  -- [out]
  signal Dbg_Clk          : std_logic;                                -- [out]
  signal Dbg_TDI          : std_logic;                                -- [out]
  signal Dbg_TDO          : std_logic;                                -- [in]
  signal Dbg_Reg_En       : std_logic_vector(0 to 7);                 -- [out]
  signal Dbg_Capture      : std_logic;                                -- [out]
  signal Dbg_Shift        : std_logic;                                -- [out]
  signal Dbg_Update       : std_logic;                                -- [out]

  signal Debug_Rst_i : std_logic;

  subtype Reg_En_TYPE is std_logic_vector(0 to 7);
  type Reg_EN_ARRAY is array(0 to 31) of Reg_En_TYPE;

  signal Dbg_TDO_I    : std_logic_vector(0 to 31);
  signal Dbg_Reg_En_I : Reg_EN_ARRAY;
  signal Dbg_Rst_I    : std_logic_vector(0 to 31);

  signal PORT_Selector   : std_logic_vector(3 downto 0) := (others => '0');
  signal PORT_Selector_1 : std_logic_vector(3 downto 0) := (others => '0');
  signal TDI_Shifter     : std_logic_vector(3 downto 0) := (others => '0');
  signal Sl_rdDBus_int   : std_logic_vector(0 to 31);

  signal bus_clk : std_logic;
  signal bus_rst : std_logic;
  
  -----------------------------------------------------------------------------
  -- Register mapping
  -----------------------------------------------------------------------------

  -- Magic string "01000010" + "00000000" + No of Jtag peripheral units "0010"
  -- + MDM Version no "00000110"
  --
  -- MDM Versions table:
  --  0,1,2,3: Not used
  --        4: opb_mdm v3
  --        5: mdm v1
  --        6: mdm v2
  
  constant New_MDM_Config_Word : std_logic_vector(31 downto 0) :=
    "01000010000000000000001000000110";

  signal Config_Reg : std_logic_vector(31 downto 0) := New_MDM_Config_Word;

  signal MDM_SEL : std_logic;

  signal Old_MDM_DRCK    : std_logic;
  signal Old_MDM_TDI     : std_logic;
  signal Old_MDM_TDO     : std_logic;
  signal Old_MDM_SEL     : std_logic;
  signal Old_MDM_SHIFT   : std_logic;
  signal Old_MDM_UPDATE  : std_logic;
  signal Old_MDM_RESET   : std_logic;
  signal Old_MDM_CAPTURE : std_logic;

  signal JTAG_Dec_Sel : std_logic_vector(15 downto 0);

begin  -- architecture IMP

  config_reset_i <= Config_Reset when C_USE_CONFIG_RESET /= 0 else '0';

  -----------------------------------------------------------------------------
  -- TDI Shift Register
  -----------------------------------------------------------------------------
  -- Shifts data in when PORT 0 is selected. PORT 0 does not actually
  -- exist externaly, but gets selected after asserting the SELECT signal.
  -- The first value shifted in after SELECT goes high will select the new
  -- PORT. 
  JTAG_Mux_Shifting : process (DRCK, SEL, config_reset_i)
  begin
    if SEL = '0' or config_reset_i = '1' then
      TDI_Shifter   <= (others => '0');
    elsif DRCK'event and DRCK = '1' then
      if MDM_SEL = '1' and SHIFT = '1' then
        TDI_Shifter <= TDI & TDI_Shifter(3 downto 1);
      end if;
    end if;
  end process JTAG_Mux_Shifting;

  -----------------------------------------------------------------------------
  -- PORT Selector Register
  -----------------------------------------------------------------------------
  -- Captures the shifted data when PORT 0 is selected. The data is captured at
  -- the end of the BSCAN transaction (i.e. when the update signal goes low) to
  -- prevent any other BSCAN signals to assert incorrectly.
  -- Reference : XAPP 139  
  PORT_Selector_Updating : process (UPDATE, SEL, config_reset_i)
  begin
    if SEL = '0' or config_reset_i = '1' then
      PORT_Selector   <= (others => '0');
    elsif Update'event and Update = '0' then
      PORT_Selector <= Port_Selector_1;
    end if;
  end process PORT_Selector_Updating;

  PORT_Selector_Updating_1 : process (UPDATE, SEL, config_reset_i)
  begin
    if SEL = '0' or config_reset_i = '1' then
      PORT_Selector_1   <= (others => '0');
    elsif Update'event and Update = '1' then
      if MDM_SEL = '1' then
        PORT_Selector_1 <= TDI_Shifter;
      end if;
    end if;
  end process PORT_Selector_Updating_1;

  -----------------------------------------------------------------------------
  -- Configuration register
  -----------------------------------------------------------------------------
  -- TODO Can be replaced by SRLs
  Config_Shifting : process (DRCK, SHIFT, config_reset_i)
  begin
    if SHIFT = '0' or config_reset_i = '1' then
      Config_Reg <= New_MDM_Config_Word;
    elsif DRCK'event and DRCK = '1' then   -- rising clock edge
      Config_Reg <= '0' & Config_Reg(31 downto 1);
    end if;
  end process Config_Shifting;

  -----------------------------------------------------------------------------
  -- Muxing and demuxing of JTAG Bscan User 1/2/3/4 signals
  --
  -- This block enables the older MDM/JTAG to co-exist with the newer
  -- JTAG multiplexer
  -- block
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- TDO Mux
  -----------------------------------------------------------------------------
  with PORT_Selector select
    TDO_i <=
    Config_Reg(0) when "0000",
    Old_MDM_TDO   when "0001",
    Ext_JTAG_TDO  when "0010",
    '1'           when others;

  TDO <= TDO_i;

  -----------------------------------------------------------------------------
  -- SELECT Decoder
  -----------------------------------------------------------------------------
  MDM_SEL      <= SEL when PORT_Selector = "0000" else '0';
  Old_MDM_SEL  <= SEL when PORT_Selector = "0001" else '0';
  Ext_JTAG_SEL <= SEL when PORT_Selector = "0010" else '0';

  -----------------------------------------------------------------------------
  -- Old MDM signals
  -----------------------------------------------------------------------------
  Old_MDM_DRCK    <= DRCK;
  Old_MDM_TDI     <= TDI;
  Old_MDM_CAPTURE <= CAPTURE;
  Old_MDM_SHIFT   <= SHIFT;
  Old_MDM_UPDATE  <= UPDATE;
  Old_MDM_RESET   <= RESET;

  -----------------------------------------------------------------------------
  -- External JTAG signals
  -----------------------------------------------------------------------------
  Ext_JTAG_DRCK    <= DRCK;
  Ext_JTAG_TDI     <= TDI;
  Ext_JTAG_CAPTURE <= CAPTURE;
  Ext_JTAG_SHIFT   <= SHIFT;
  Ext_JTAG_UPDATE  <= UPDATE;
  Ext_JTAG_RESET   <= RESET;

  -----------------------------------------------------------------------------
  -- PLBv46 bus interface
  -----------------------------------------------------------------------------
  PLB_Interconnect : if (C_INTERCONNECT = 1 and C_USE_UART = 1) generate
    signal abus : std_logic_vector(0 to 1);
  begin
    -- Ignoring these signals
    -- PLB_abort, PLB_UABus, PLB_busLock, PLB_lockErr, PLB_rdPendPri,
    -- PLB_wrPendPri, PLB_rdPendReq, PLB_wrPendReq, PLB_rdBurst, PLB_rdPrim,
    -- PLB_reqPri, PLB_SAValid, PLB_Msize, PLB_TAttribute, PLB_type,
    -- PLB_wrBurst, PLB_wrPrim

    -- Drive these signals to constant values
    Sl_MIRQ        <= (others => '0');
    Sl_rdBTerm     <= '0';
    Sl_rdWdAddr    <= (others => '0');
    Sl_wrBTerm     <= '0';
    Sl_SSize       <= "00";
    Sl_wait        <= '0';              -- The core will respond in the 2nd
                                        -- cycle with sl_AddrAck
    Sl_rearbitrate <= '0';              -- No rearbitration is needed
    Sl_MBusy       <= (others => '0');  -- There is no queue of outstanding
                                        -- accesses
    Sl_MRdErr      <= (others => '0');  -- There is no read errors accesses
    Sl_MWrErr      <= (others => '0');  -- There is no write errors accesses

    -- Do the PLBv46 address decoding
    pselect_I : pselect
      generic map (
        C_AB   => C_AB,                 -- [integer]
        C_AW   => 32,                   -- [integer]
        C_BAR  => C_BASEADDR)           -- [std_logic_vector]
      port map (
        A      => PLB_ABus,             -- [in  std_logic_vector(0 to C_AW-1)]
        AValid => PLB_PAValid,          -- [in  std_logic]
        cs     => mdm_CS);              -- [out std_logic]

    valid_access <= mdm_CS when (PLB_size = "0000") else '0';

    -- Respond to Valid Address
    AddrAck : process (SPLB_Clk) is
    begin  -- process AddrAck
      if SPLB_Clk'event and SPLB_Clk = '1' then  -- rising clock edge
        if SPLB_Rst = '1' then          -- synchronous reset (active high)
          Sl_addrAck <= '0';
        else
          Sl_addrAck <= valid_access;
        end if;
      end if;
    end process AddrAck;

    Handle_Access : process (SPLB_Clk) is
    begin  -- process Handle_Access
      if SPLB_Clk'event and SPLB_Clk = '1' then  -- rising clock edge
        if SPLB_Rst = '1' then          -- synchronous reset (active high)
          Reading <= PLB_RNW;
          abus    <= (others => '0');
        elsif (valid_access = '1') then
          Reading <= PLB_RNW;
          abus    <= PLB_ABus(28 to 29);
        end if;
      end if;
    end process Handle_Access;

    valid_access_DFF : process (SPLB_Clk) is
    begin  -- process valid_access_DFF
      if SPLB_Clk'event and SPLB_Clk = '1' then  -- rising clock edge
        if SPLB_Rst = '1' then          -- synchronous reset (active high)
          valid_access_1 <= '0';
          valid_access_2 <= '0';
        else
          valid_access_1 <= valid_access;
          valid_access_2 <= valid_access_1 and not valid_access_2;
        end if;
      end if;
    end process valid_access_DFF;

    ---------------------------------------------------------------------------
    -- Status register handling
    ---------------------------------------------------------------------------
    status_Reg(7)      <= rx_Data_Present;
    status_Reg(6)      <= rx_Buffer_Full;
    status_Reg(5)      <= tx_Buffer_Empty;
    status_Reg(4)      <= tx_Buffer_Full;
    status_Reg(3)      <= enable_interrupts;
    status_Reg(0 to 2) <= "000";

    ---------------------------------------------------------------------------
    -- Control Register Handling 
    ---------------------------------------------------------------------------
    Ctrl_Reg_DFF : process (SPLB_Clk) is
    begin  -- process Ctrl_Reg_DFF
      if SPLB_Clk'event and SPLB_Clk = '1' then  -- rising clock edge
        if SPLB_Rst = '1' then                   -- synchronous reset (active high)
          reset_TX_FIFO       <= '1';
          reset_RX_FIFO       <= '1';
          enable_interrupts   <= '0';
          clear_Ext_BRK       <= '0';
        else
          reset_TX_FIFO       <= '0';
          reset_RX_FIFO       <= '0';
          clear_Ext_BRK       <= '0';
          if (valid_access_2 = '1') and (Reading = '0') and
            (abus = CTRL_REG_ADR) then
            reset_RX_FIFO     <= PLB_wrDBus(30);
            reset_TX_FIFO     <= PLB_wrDBus(31);
            enable_interrupts <= PLB_wrDBus(27);
            clear_Ext_BRK     <= PLB_wrDBus(29);
          end if;
        end if;
      end if;
    end process Ctrl_Reg_DFF;

    ---------------------------------------------------------------------------
    -- Read bus interface
    ---------------------------------------------------------------------------

    Read_Mux : process (status_reg, abus, rx_Data) is
    begin  -- process Read_Mux
      mdm_Dbus_i                          <= (others => '0');
      if (abus = STATUS_REG_ADR) then
        mdm_Dbus_i(24 to 31)              <= status_reg;
      else
        mdm_Dbus_i(32-C_UART_WIDTH to 31) <= rx_Data;
      end if;
    end process Read_Mux;

    Sl_rdDBus(0 to 31) <= Sl_rdDBus_int(0 to 31);

    Mirror_64bitBus : if (C_SPLB_DWIDTH = 64) generate
    begin
      Sl_rdDBus(32 to 63) <= Sl_rdDBus_int(0 to 31);
    end generate Mirror_64bitBus;
    
    Mirror_128bitBus : if (C_SPLB_DWIDTH = 128) generate
    begin
      Sl_rdDBus(32 to 63)  <= Sl_rdDBus_int(0 to 31);
      Sl_rdDBus(64 to 95)  <= Sl_rdDBus_int(0 to 31);
      Sl_rdDBus(96 to 127) <= Sl_rdDBus_int(0 to 31);
    end generate Mirror_128bitBus;

    Not_All_32_Bits_Are_Used : if (C_UART_WIDTH < 32) generate
    begin
      Sl_rdDBus_int(0 to 31-C_UART_WIDTH) <= (others => '0');
    end generate Not_All_32_Bits_Are_Used;

    valid_access_2_reading <= valid_access_2 and reading;

    PLBv46_rdDBus_DFF   : for I in 32-C_UART_WIDTH to 31 generate
    begin
      PLBv46_rdBus_FDRE : FDRE
        port map (
          Q  => Sl_rdDBus_int(I),        -- [out std_logic]
          C  => SPLB_Clk,                -- [in  std_logic]
          CE => valid_access_2_reading,  -- [in  std_logic]
          D  => mdm_Dbus_i(I),           -- [in  std_logic]
          R  => sl_rdDAck_i);            -- [in std_logic]
    end generate PLBv46_rdDBus_DFF;

    -- Write interface
    tx_Data <= PLB_wrDBus(32-C_UART_WIDTH to 31);
    
    -- Generating read and write pulses to the FIFOs
    write_TX_FIFO <= valid_access_2 and (not reading) when
                     (abus = TX_FIFO_ADR) else '0';

    read_RX_FIFO  <= valid_access_2 and reading       when
                     (abus = RX_FIFO_ADR) else '0';

    End_of_Transfer_Control : process (SPLB_Clk) is
    begin  -- process End_of_Transfer_Control
      if SPLB_Clk'event and SPLB_Clk = '1' then  -- rising clock edge
        if SPLB_Rst = '1' then          -- asynchronous reset (active high)
          sl_rdDAck_i <= '0';
          sl_wrDAck_i <= '0';
        else
          sl_rdDAck_i <= valid_access_2 and reading;
          sl_wrDAck_i <= valid_access_2 and not reading;
        end if;
      end if;
    end process End_of_Transfer_Control;

    Sl_rdDAck <= sl_rdDAck_i;
    Sl_rdComp <= sl_rdDAck_i;
    Sl_wrDAck <= sl_wrDAck_i;
    Sl_wrComp <= sl_wrDAck_i;

    ---------------------------------------------------------------------------
    -- Clock and reset
    ---------------------------------------------------------------------------
    bus_clk <= SPLB_Clk;
    bus_rst <= SPLB_Rst;

    ---------------------------------------------------------------------------
    -- Unused AXI (IPIC) output signals
    ---------------------------------------------------------------------------
    ip2bus_rdack <= '0';
    ip2bus_wrack <= '0';
    ip2bus_error <= '0';
    ip2bus_data  <= (others => '0');

  end generate PLB_Interconnect;

  -----------------------------------------------------------------------------
  -- AXI bus interface
  -----------------------------------------------------------------------------

  AXI_Interconnect : if (C_INTERCONNECT = 2 and C_USE_UART = 1) generate
  begin
    ---------------------------------------------------------------------------
    -- Acknowledgement and error signals
    ---------------------------------------------------------------------------
    ip2bus_rdack <= bus2ip_rdce(0) or bus2ip_rdce(2) or bus2ip_rdce(1)
                    or bus2ip_rdce(3);

    ip2bus_wrack <= bus2ip_wrce(1) or bus2ip_wrce(3) or bus2ip_wrce(0)
                    or bus2ip_wrce(2);

    ip2bus_error <= ((bus2ip_rdce(0) and not rx_Data_Present) or
                     (bus2ip_wrce(1) and tx_Buffer_Full) );
    
    ---------------------------------------------------------------------------
    -- Status register
    ---------------------------------------------------------------------------
    status_Reg(7)      <= rx_Data_Present;
    status_Reg(6)      <= rx_Buffer_Full;
    status_Reg(5)      <= tx_Buffer_Empty;
    status_Reg(4)      <= tx_Buffer_Full;
    status_Reg(3)      <= enable_interrupts;
    status_Reg(0 to 2) <= "000";

    ---------------------------------------------------------------------------
    -- Control Register    
    ---------------------------------------------------------------------------
    CTRL_REG_DFF : process (bus2ip_clk, bus2ip_resetn) is
    begin
      if bus2ip_clk'event and bus2ip_clk = '1' then -- rising clock edge
        if bus2ip_resetn = '0' then            -- synchronous reset (active high)
          reset_TX_FIFO     <= '1';
          reset_RX_FIFO     <= '1';
          enable_interrupts <= '0';
          clear_Ext_BRK     <= '0';
        elsif (bus2ip_wrce(3) = '1') then  -- Control Register is reg 3
           reset_RX_FIFO     <= bus2ip_data(6); -- Bit 6 in control reg
           reset_TX_FIFO     <= bus2ip_data(7); -- Bit 7 in control reg
           enable_interrupts <= bus2ip_data(3); -- Bit 3 in control reg
           clear_Ext_BRK     <= bus2ip_data(5); -- Bit 5 in control reg
        else
          reset_TX_FIFO <= '0';
          reset_RX_FIFO <= '0';
          clear_Ext_BRK <= '0';
        end if;
      end if;
    end process CTRL_REG_DFF;
                               
    ---------------------------------------------------------------------------
    -- Read bus interface
    ---------------------------------------------------------------------------
    READ_MUX : process (status_reg, bus2ip_rdce(2), bus2ip_rdce(0), rx_Data) is
    begin
      if (bus2ip_rdce(2) = '1') then    -- Status register is reg 2
        ip2bus_data <= status_reg;
      elsif (bus2ip_rdce(0) = '1') then -- RX FIFO is reg 0
        ip2bus_data((8-C_UART_WIDTH) to 7) <= rx_Data;
      else
        ip2bus_data <= (others => '0');
      end if;
    end process READ_MUX;
    
    ---------------------------------------------------------------------------
    -- Write bus interface
    ---------------------------------------------------------------------------
    tx_Data <=  bus2ip_data(8-C_UART_WIDTH to 7);
    
    ---------------------------------------------------------------------------
    -- Read and write pulses to the FIFOs
    ----------------------------------------------------------------------------
    write_TX_FIFO <= bus2ip_wrce(1);    -- TX FIFO is reg 1
    read_RX_FIFO  <= bus2ip_rdce(0);    -- RX FIFO is reg 0

    ---------------------------------------------------------------------------
    -- Clock and reset
    ---------------------------------------------------------------------------
    bus_clk <= bus2ip_clk;
    bus_rst <= not bus2ip_resetn;

    ---------------------------------------------------------------------------
    -- Unused PLBv46 output signals
    ---------------------------------------------------------------------------
    Sl_addrAck     <= '0';
    Sl_SSize       <= (others => '0');
    Sl_wait        <= '0';
    Sl_rearbitrate <= '0';
    Sl_wrDAck      <= '0';
    Sl_wrComp      <= '0';
    Sl_wrBTerm     <= '0';
    Sl_rdDBus      <= (others => '0');
    Sl_rdWdAddr    <= (others => '0');
    Sl_rdDAck      <= '0';
    Sl_rdComp      <= '0';
    Sl_rdBTerm     <= '0';
    Sl_MBusy       <= (others => '0');
    Sl_MWrErr      <= (others => '0');
    Sl_MRdErr      <= (others => '0');
    Sl_MIRQ        <= (others => '0');

  end generate AXI_Interconnect;

  ---------------------------------------------------------------------------
  -- Interrupt handling
  ---------------------------------------------------------------------------

  No_UART : if (C_USE_UART = 0) generate
  begin
    Interrupt         <= '0';

    status_Reg        <= (others => '0');
    reset_TX_FIFO     <= '1';
    reset_RX_FIFO     <= '1';
    enable_interrupts <= '0';
    clear_Ext_BRK     <= '0';
    tx_Data           <= (others => '0');
    write_TX_FIFO     <= '0';
    read_RX_FIFO      <= '0';
    bus_clk           <= '0';
    bus_rst           <= '0';

    ---------------------------------------------------------------------------
    -- Unused PLBv46 output signals
    ---------------------------------------------------------------------------
    Sl_addrAck     <= '0';
    Sl_SSize       <= (others => '0');
    Sl_wait        <= '0';
    Sl_rearbitrate <= '0';
    Sl_wrDAck      <= '0';
    Sl_wrComp      <= '0';
    Sl_wrBTerm     <= '0';
    Sl_rdDBus      <= (others => '0');
    Sl_rdWdAddr    <= (others => '0');
    Sl_rdDAck      <= '0';
    Sl_rdComp      <= '0';
    Sl_rdBTerm     <= '0';
    Sl_MBusy       <= (others => '0');
    Sl_MWrErr      <= (others => '0');
    Sl_MRdErr      <= (others => '0');
    Sl_MIRQ        <= (others => '0');

    ---------------------------------------------------------------------------
    -- Unused AXI (IPIC) output signals
    ---------------------------------------------------------------------------
    ip2bus_rdack <= '0';
    ip2bus_wrack <= '0';
    ip2bus_error <= '0';
    ip2bus_data  <= (others => '0');

  end generate No_UART;

  Use_UART : if (C_USE_UART = 1) generate
    signal tx_Buffer_Empty_Pre : std_logic;
  begin
    -- Sample the tx_Buffer_Empty signal in order to detect a rising edge 
    TX_Buffer_Empty_FDRE : FDRE
      port map (
        Q  => tx_Buffer_Empty_Pre, 
        C  => bus_clk,
        CE => '1',
        D  => tx_Buffer_Empty,
        R  => write_TX_FIFO);

    Interrupt <= enable_interrupts and ( rx_Data_Present or
                                         ( tx_Buffer_Empty and
                                           not tx_Buffer_Empty_Pre ) );
  end generate Use_UART;

  ---------------------------------------------------------------------------
  -- Instantiating the receive and transmit modules
  ---------------------------------------------------------------------------
  JTAG_CONTROL_I : JTAG_CONTROL
    generic map (
      C_MB_DBG_PORTS     => C_MB_DBG_PORTS,
      C_USE_CONFIG_RESET => C_USE_CONFIG_RESET,
      C_USE_UART         => C_USE_UART,
      C_UART_WIDTH       => C_UART_WIDTH,
      C_EN_WIDTH         => C_EN_WIDTH
    )
    port map (
      Config_Reset    => config_reset_i,   -- [in  std_logic]

      Clk             => bus_clk,          -- [in  std_logic]
      Rst             => bus_rst,          -- [in  std_logic]

      Clear_Ext_BRK   => clear_Ext_BRK,    -- [in  std_logic]
      Ext_BRK         => Ext_BRK,          -- [out  std_logic]
      Ext_NM_BRK      => Ext_NM_BRK,       -- [out  std_logic]
      Debug_SYS_Rst   => Debug_SYS_Rst,    -- [out  std_logic]
      Debug_Rst       => Debug_Rst_i,      -- [out  std_logic]

      Read_RX_FIFO    => read_RX_FIFO,     -- [in  std_logic]
      Reset_RX_FIFO   => reset_RX_FIFO,    -- [in  std_logic]
      RX_Data         => rx_Data,          -- [out std_logic_vector(0 to 7)]
      RX_Data_Present => rx_Data_Present,  -- [out std_logic]
      RX_Buffer_Full  => rx_Buffer_Full,   -- [out std_logic]

      Write_TX_FIFO   => write_TX_FIFO,    -- [in  std_logic]
      Reset_TX_FIFO   => reset_TX_FIFO,    -- [in  std_logic]
      TX_Data         => tx_Data,          -- [in  std_logic_vector(0 to 7)]
      TX_Buffer_Full  => tx_Buffer_Full,   -- [out std_logic]
      TX_Buffer_Empty => tx_Buffer_Empty,  -- [out std_logic]

      -- MDM signals
      TDI     => Old_MDM_TDI,         -- [in  std_logic]
      RESET   => Old_MDM_RESET,       -- [in  std_logic]
      UPDATE  => Old_MDM_UPDATE,      -- [in  std_logic]
      SHIFT   => Old_MDM_SHIFT,       -- [in  std_logic]
      CAPTURE => Old_MDM_CAPTURE,     -- [in  std_logic]
      SEL     => Old_MDM_SEL,         -- [in  std_logic]
      DRCK    => Old_MDM_DRCK,        -- [in  std_logic]
      TDO     => Old_MDM_TDO,         -- [out std_logic]

      -- MicroBlaze Debug Signals
      MB_Debug_Enabled => MB_Debug_Enabled,  -- [out std_logic_vector(7 downto 0)]
      Dbg_Clk          => Dbg_Clk,           -- [out std_logic]
      Dbg_TDI          => Dbg_TDI,           -- [in  std_logic]
      Dbg_TDO          => Dbg_TDO,           -- [out std_logic]
      Dbg_Reg_En       => Dbg_Reg_En,        -- [out std_logic_vector(0 to 7)]
      Dbg_Capture      => Dbg_Capture,       -- [out std_logic]
      Dbg_Shift        => Dbg_Shift,         -- [out std_logic]
      Dbg_Update       => Dbg_Update         -- [out std_logic]
    );

  -----------------------------------------------------------------------------
  -- Enables for each debug port
  -----------------------------------------------------------------------------
  Generate_Dbg_Port_Signals : process (MB_Debug_Enabled, Dbg_Reg_En,
                                       Dbg_TDO_I, Debug_Rst_I)

    variable dbg_tdo_or : std_logic;

  begin  -- process Generate_Dbg_Port_Signals
    dbg_tdo_or   := '0';
    for I in 0 to C_EN_WIDTH-1 loop
      if (MB_Debug_Enabled(I) = '1') then
        Dbg_Reg_En_I(I) <= Dbg_Reg_En;
        Dbg_Rst_I(I)    <= Debug_Rst_i;
      else
        Dbg_Reg_En_I(I) <= (others => '0');
        Dbg_Rst_I(I)    <= '0';
      end if;
      dbg_tdo_or := dbg_tdo_or or Dbg_TDO_I(I);
    end loop;  -- I
    Dbg_TDO             <= dbg_tdo_or;
  end process Generate_Dbg_Port_Signals;

  Dbg_Clk_0     <= Dbg_Clk;
  Dbg_TDI_0     <= Dbg_TDI;
  Dbg_Reg_En_0  <= Dbg_Reg_En_I(0);
  Dbg_Capture_0 <= Dbg_Capture;
  Dbg_Shift_0   <= Dbg_Shift;
  Dbg_Update_0  <= Dbg_Update;
  Dbg_Rst_0     <= Dbg_Rst_I(0);
  Dbg_TDO_I(0)  <= Dbg_TDO_0;

  Dbg_Clk_1     <= Dbg_Clk;
  Dbg_TDI_1     <= Dbg_TDI;
  Dbg_Reg_En_1  <= Dbg_Reg_En_I(1);
  Dbg_Capture_1 <= Dbg_Capture;
  Dbg_Shift_1   <= Dbg_Shift;
  Dbg_Update_1  <= Dbg_Update;
  Dbg_Rst_1     <= Dbg_Rst_I(1);
  Dbg_TDO_I(1)  <= Dbg_TDO_1;

  Dbg_Clk_2     <= Dbg_Clk;
  Dbg_TDI_2     <= Dbg_TDI;
  Dbg_Reg_En_2  <= Dbg_Reg_En_I(2);
  Dbg_Capture_2 <= Dbg_Capture;
  Dbg_Shift_2   <= Dbg_Shift;
  Dbg_Update_2  <= Dbg_Update;
  Dbg_Rst_2     <= Dbg_Rst_I(2);
  Dbg_TDO_I(2)  <= Dbg_TDO_2;

  Dbg_Clk_3     <= Dbg_Clk;
  Dbg_TDI_3     <= Dbg_TDI;
  Dbg_Reg_En_3  <= Dbg_Reg_En_I(3);
  Dbg_Capture_3 <= Dbg_Capture;
  Dbg_Shift_3   <= Dbg_Shift;
  Dbg_Update_3  <= Dbg_Update;
  Dbg_Rst_3     <= Dbg_Rst_I(3);
  Dbg_TDO_I(3)  <= Dbg_TDO_3;

  Dbg_Clk_4     <= Dbg_Clk;
  Dbg_TDI_4     <= Dbg_TDI;
  Dbg_Reg_En_4  <= Dbg_Reg_En_I(4);
  Dbg_Capture_4 <= Dbg_Capture;
  Dbg_Shift_4   <= Dbg_Shift;
  Dbg_Update_4  <= Dbg_Update;
  Dbg_Rst_4     <= Dbg_Rst_I(4);
  Dbg_TDO_I(4)  <= Dbg_TDO_4;

  Dbg_Clk_5     <= Dbg_Clk;
  Dbg_TDI_5     <= Dbg_TDI;
  Dbg_Reg_En_5  <= Dbg_Reg_En_I(5);
  Dbg_Capture_5 <= Dbg_Capture;
  Dbg_Shift_5   <= Dbg_Shift;
  Dbg_Update_5  <= Dbg_Update;
  Dbg_Rst_5     <= Dbg_Rst_I(5);
  Dbg_TDO_I(5)  <= Dbg_TDO_5;

  Dbg_Clk_6     <= Dbg_Clk;
  Dbg_TDI_6     <= Dbg_TDI;
  Dbg_Reg_En_6  <= Dbg_Reg_En_I(6);
  Dbg_Capture_6 <= Dbg_Capture;
  Dbg_Shift_6   <= Dbg_Shift;
  Dbg_Update_6  <= Dbg_Update;
  Dbg_Rst_6     <= Dbg_Rst_I(6);
  Dbg_TDO_I(6)  <= Dbg_TDO_6;

  Dbg_Clk_7     <= Dbg_Clk;
  Dbg_TDI_7     <= Dbg_TDI;
  Dbg_Reg_En_7  <= Dbg_Reg_En_I(7);
  Dbg_Capture_7 <= Dbg_Capture;
  Dbg_Shift_7   <= Dbg_Shift;
  Dbg_Update_7  <= Dbg_Update;
  Dbg_Rst_7     <= Dbg_Rst_I(7);
  Dbg_TDO_I(7)  <= Dbg_TDO_7;

  Dbg_Clk_8     <= Dbg_Clk;
  Dbg_TDI_8     <= Dbg_TDI;
  Dbg_Reg_En_8  <= Dbg_Reg_En_I(8);
  Dbg_Capture_8 <= Dbg_Capture;
  Dbg_Shift_8   <= Dbg_Shift;
  Dbg_Update_8  <= Dbg_Update;
  Dbg_Rst_8     <= Dbg_Rst_I(8);
  Dbg_TDO_I(8)  <= Dbg_TDO_8;

  Dbg_Clk_9     <= Dbg_Clk;
  Dbg_TDI_9     <= Dbg_TDI;
  Dbg_Reg_En_9  <= Dbg_Reg_En_I(9);
  Dbg_Capture_9 <= Dbg_Capture;
  Dbg_Shift_9   <= Dbg_Shift;
  Dbg_Update_9  <= Dbg_Update;
  Dbg_Rst_9     <= Dbg_Rst_I(9);
  Dbg_TDO_I(9)  <= Dbg_TDO_9;

  Dbg_Clk_10     <= Dbg_Clk;
  Dbg_TDI_10     <= Dbg_TDI;
  Dbg_Reg_En_10  <= Dbg_Reg_En_I(10);
  Dbg_Capture_10 <= Dbg_Capture;
  Dbg_Shift_10   <= Dbg_Shift;
  Dbg_Update_10  <= Dbg_Update;
  Dbg_Rst_10     <= Dbg_Rst_I(10);
  Dbg_TDO_I(10)  <= Dbg_TDO_10;

  Dbg_Clk_11     <= Dbg_Clk;
  Dbg_TDI_11     <= Dbg_TDI;
  Dbg_Reg_En_11  <= Dbg_Reg_En_I(11);
  Dbg_Capture_11 <= Dbg_Capture;
  Dbg_Shift_11   <= Dbg_Shift;
  Dbg_Update_11  <= Dbg_Update;
  Dbg_Rst_11     <= Dbg_Rst_I(11);
  Dbg_TDO_I(11)  <= Dbg_TDO_11;

  Dbg_Clk_12     <= Dbg_Clk;
  Dbg_TDI_12     <= Dbg_TDI;
  Dbg_Reg_En_12  <= Dbg_Reg_En_I(12);
  Dbg_Capture_12 <= Dbg_Capture;
  Dbg_Shift_12   <= Dbg_Shift;
  Dbg_Update_12  <= Dbg_Update;
  Dbg_Rst_12     <= Dbg_Rst_I(12);
  Dbg_TDO_I(12)  <= Dbg_TDO_12;

  Dbg_Clk_13     <= Dbg_Clk;
  Dbg_TDI_13     <= Dbg_TDI;
  Dbg_Reg_En_13  <= Dbg_Reg_En_I(13);
  Dbg_Capture_13 <= Dbg_Capture;
  Dbg_Shift_13   <= Dbg_Shift;
  Dbg_Update_13  <= Dbg_Update;
  Dbg_Rst_13     <= Dbg_Rst_I(13);
  Dbg_TDO_I(13)  <= Dbg_TDO_13;

  Dbg_Clk_14     <= Dbg_Clk;
  Dbg_TDI_14     <= Dbg_TDI;
  Dbg_Reg_En_14  <= Dbg_Reg_En_I(14);
  Dbg_Capture_14 <= Dbg_Capture;
  Dbg_Shift_14   <= Dbg_Shift;
  Dbg_Update_14  <= Dbg_Update;
  Dbg_Rst_14     <= Dbg_Rst_I(14);
  Dbg_TDO_I(14)  <= Dbg_TDO_14;

  Dbg_Clk_15     <= Dbg_Clk;
  Dbg_TDI_15     <= Dbg_TDI;
  Dbg_Reg_En_15  <= Dbg_Reg_En_I(15);
  Dbg_Capture_15 <= Dbg_Capture;
  Dbg_Shift_15   <= Dbg_Shift;
  Dbg_Update_15  <= Dbg_Update;
  Dbg_Rst_15     <= Dbg_Rst_I(15);
  Dbg_TDO_I(15)  <= Dbg_TDO_15;

  Dbg_Clk_16     <= Dbg_Clk;
  Dbg_TDI_16     <= Dbg_TDI;
  Dbg_Reg_En_16  <= Dbg_Reg_En_I(16);
  Dbg_Capture_16 <= Dbg_Capture;
  Dbg_Shift_16   <= Dbg_Shift;
  Dbg_Update_16  <= Dbg_Update;
  Dbg_Rst_16     <= Dbg_Rst_I(16);
  Dbg_TDO_I(16)  <= Dbg_TDO_16;

  Dbg_Clk_17     <= Dbg_Clk;
  Dbg_TDI_17     <= Dbg_TDI;
  Dbg_Reg_En_17  <= Dbg_Reg_En_I(17);
  Dbg_Capture_17 <= Dbg_Capture;
  Dbg_Shift_17   <= Dbg_Shift;
  Dbg_Update_17  <= Dbg_Update;
  Dbg_Rst_17     <= Dbg_Rst_I(17);
  Dbg_TDO_I(17)  <= Dbg_TDO_17;

  Dbg_Clk_18     <= Dbg_Clk;
  Dbg_TDI_18     <= Dbg_TDI;
  Dbg_Reg_En_18  <= Dbg_Reg_En_I(18);
  Dbg_Capture_18 <= Dbg_Capture;
  Dbg_Shift_18   <= Dbg_Shift;
  Dbg_Update_18  <= Dbg_Update;
  Dbg_Rst_18     <= Dbg_Rst_I(18);
  Dbg_TDO_I(18)  <= Dbg_TDO_18;

  Dbg_Clk_19     <= Dbg_Clk;
  Dbg_TDI_19     <= Dbg_TDI;
  Dbg_Reg_En_19  <= Dbg_Reg_En_I(19);
  Dbg_Capture_19 <= Dbg_Capture;
  Dbg_Shift_19   <= Dbg_Shift;
  Dbg_Update_19  <= Dbg_Update;
  Dbg_Rst_19     <= Dbg_Rst_I(19);
  Dbg_TDO_I(19)  <= Dbg_TDO_19;

  Dbg_Clk_20     <= Dbg_Clk;
  Dbg_TDI_20     <= Dbg_TDI;
  Dbg_Reg_En_20  <= Dbg_Reg_En_I(20);
  Dbg_Capture_20 <= Dbg_Capture;
  Dbg_Shift_20   <= Dbg_Shift;
  Dbg_Update_20  <= Dbg_Update;
  Dbg_Rst_20     <= Dbg_Rst_I(20);
  Dbg_TDO_I(20)  <= Dbg_TDO_20;

  Dbg_Clk_21     <= Dbg_Clk;
  Dbg_TDI_21     <= Dbg_TDI;
  Dbg_Reg_En_21  <= Dbg_Reg_En_I(21);
  Dbg_Capture_21 <= Dbg_Capture;
  Dbg_Shift_21   <= Dbg_Shift;
  Dbg_Update_21  <= Dbg_Update;
  Dbg_Rst_21     <= Dbg_Rst_I(21);
  Dbg_TDO_I(21)  <= Dbg_TDO_21;

  Dbg_Clk_22     <= Dbg_Clk;
  Dbg_TDI_22     <= Dbg_TDI;
  Dbg_Reg_En_22  <= Dbg_Reg_En_I(22);
  Dbg_Capture_22 <= Dbg_Capture;
  Dbg_Shift_22   <= Dbg_Shift;
  Dbg_Update_22  <= Dbg_Update;
  Dbg_Rst_22     <= Dbg_Rst_I(22);
  Dbg_TDO_I(22)  <= Dbg_TDO_22;

  Dbg_Clk_23     <= Dbg_Clk;
  Dbg_TDI_23     <= Dbg_TDI;
  Dbg_Reg_En_23  <= Dbg_Reg_En_I(23);
  Dbg_Capture_23 <= Dbg_Capture;
  Dbg_Shift_23   <= Dbg_Shift;
  Dbg_Update_23  <= Dbg_Update;
  Dbg_Rst_23     <= Dbg_Rst_I(23);
  Dbg_TDO_I(23)  <= Dbg_TDO_23;

  Dbg_Clk_24     <= Dbg_Clk;
  Dbg_TDI_24     <= Dbg_TDI;
  Dbg_Reg_En_24  <= Dbg_Reg_En_I(24);
  Dbg_Capture_24 <= Dbg_Capture;
  Dbg_Shift_24   <= Dbg_Shift;
  Dbg_Update_24  <= Dbg_Update;
  Dbg_Rst_24     <= Dbg_Rst_I(24);
  Dbg_TDO_I(24)  <= Dbg_TDO_24;

  Dbg_Clk_25     <= Dbg_Clk;
  Dbg_TDI_25     <= Dbg_TDI;
  Dbg_Reg_En_25  <= Dbg_Reg_En_I(25);
  Dbg_Capture_25 <= Dbg_Capture;
  Dbg_Shift_25   <= Dbg_Shift;
  Dbg_Update_25  <= Dbg_Update;
  Dbg_Rst_25     <= Dbg_Rst_I(25);
  Dbg_TDO_I(25)  <= Dbg_TDO_25;

  Dbg_Clk_26     <= Dbg_Clk;
  Dbg_TDI_26     <= Dbg_TDI;
  Dbg_Reg_En_26  <= Dbg_Reg_En_I(26);
  Dbg_Capture_26 <= Dbg_Capture;
  Dbg_Shift_26   <= Dbg_Shift;
  Dbg_Update_26  <= Dbg_Update;
  Dbg_Rst_26     <= Dbg_Rst_I(26);
  Dbg_TDO_I(26)  <= Dbg_TDO_26;

  Dbg_Clk_27     <= Dbg_Clk;
  Dbg_TDI_27     <= Dbg_TDI;
  Dbg_Reg_En_27  <= Dbg_Reg_En_I(27);
  Dbg_Capture_27 <= Dbg_Capture;
  Dbg_Shift_27   <= Dbg_Shift;
  Dbg_Update_27  <= Dbg_Update;
  Dbg_Rst_27     <= Dbg_Rst_I(27);
  Dbg_TDO_I(27)  <= Dbg_TDO_27;

  Dbg_Clk_28     <= Dbg_Clk;
  Dbg_TDI_28     <= Dbg_TDI;
  Dbg_Reg_En_28  <= Dbg_Reg_En_I(28);
  Dbg_Capture_28 <= Dbg_Capture;
  Dbg_Shift_28   <= Dbg_Shift;
  Dbg_Update_28  <= Dbg_Update;
  Dbg_Rst_28     <= Dbg_Rst_I(28);
  Dbg_TDO_I(28)  <= Dbg_TDO_28;

  Dbg_Clk_29     <= Dbg_Clk;
  Dbg_TDI_29     <= Dbg_TDI;
  Dbg_Reg_En_29  <= Dbg_Reg_En_I(29);
  Dbg_Capture_29 <= Dbg_Capture;
  Dbg_Shift_29   <= Dbg_Shift;
  Dbg_Update_29  <= Dbg_Update;
  Dbg_Rst_29     <= Dbg_Rst_I(29);
  Dbg_TDO_I(29)  <= Dbg_TDO_29;

  Dbg_Clk_30     <= Dbg_Clk;
  Dbg_TDI_30     <= Dbg_TDI;
  Dbg_Reg_En_30  <= Dbg_Reg_En_I(30);
  Dbg_Capture_30 <= Dbg_Capture;
  Dbg_Shift_30   <= Dbg_Shift;
  Dbg_Update_30  <= Dbg_Update;
  Dbg_Rst_30     <= Dbg_Rst_I(30);
  Dbg_TDO_I(30)  <= Dbg_TDO_30;

  Dbg_Clk_31     <= Dbg_Clk;
  Dbg_TDI_31     <= Dbg_TDI;
  Dbg_Reg_En_31  <= Dbg_Reg_En_I(31);
  Dbg_Capture_31 <= Dbg_Capture;
  Dbg_Shift_31   <= Dbg_Shift;
  Dbg_Update_31  <= Dbg_Update;
  Dbg_Rst_31     <= Dbg_Rst_I(31);
  Dbg_TDO_I(31)  <= Dbg_TDO_31;

end architecture IMP;
