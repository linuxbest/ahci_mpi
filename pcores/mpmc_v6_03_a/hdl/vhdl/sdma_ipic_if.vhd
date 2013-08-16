---------------------------------------------------------------------------
-- ipic_if
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
-- Filename:          ipic_if.vhd
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
-- Author:      Gary Burch
-- History:
--  GAB     10/02/06
-- ~~~~~~
--  - Initial Release
-- ^^^^^^
--  GAB     5/9/07
-- ~~~~~~
--  - Fixed issue with CS strobe being allowed to kick off another register file
--  access during a soft reset.  This caused multiple ip2bus_rdack's to occur
--  and ultimatly caused multiple sl_rdack's and sl_rdcomp's to occur.
-- ^^^^^^
--  GAB     5/9/07
-- ~~~~~~
--  - Fixed issue with soft reset cycle inadvertantly being entered causeing
--  misfiring of ip2bus_wracks and thus bus errors. This fixes CR446818
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
use mpmc_v6_03_a.sdma_pkg.all;

-------------------------------------------------------------------------------
entity  sdma_ipic_if is
    generic (
        C_NUM_CE                        : integer := 17                        ;
        C_SPLB_AWIDTH                   : integer range 32 to 32    := 32      ;
        C_SPLB_NATIVE_DWIDTH            : integer range 32 to 128   := 32
    );
    port (
        -- IPIC Interface
        Bus2IP_Clk                      : in  std_logic                     ;
        Bus2IP_Reset                    : in  std_logic                     ;
        Bus2IP_CS                       : in  std_logic                     ;
        Bus2IP_RNW                      : in  std_logic                     ;
        Bus2IP_Addr                     : in  std_logic_vector
                                            (0 to C_SPLB_AWIDTH - 1 )       ;
        Bus2IP_Data                     : in  std_logic_vector
                                            (0 to C_SPLB_NATIVE_DWIDTH - 1 );  
        Bus2IP_RdCE                     : in  std_logic_vector
                                            (0 to C_NUM_CE-1)               ;
        Bus2IP_WrCE                     : in std_logic_vector
                                            (0 to C_NUM_CE-1)               ;
        IP2Bus_Data                     : out std_logic_vector
                                            (0 to C_SPLB_NATIVE_DWIDTH - 1 ); 
        IP2Bus_WrAck                    : out std_logic                     ;
        IP2Bus_RdAck                    : out std_logic                     ;

        -- Global Signals                         
        LLink_Clk                       : in  std_logic                     ;
        LLink_Rst                       : in  std_logic                     ;
        ChannelRST                      : in  std_logic                     ;
        RegFileRstDone                  : out std_logic                     ;
        System_Busy                     : in  std_logic                     ;
        RX_Busy                         : in  std_logic                     ;
        TX_Busy                         : in  std_logic                     ;

        SDMA_Ext_Reset                  : out std_logic                     ;

        
        IPIC_Sel_AddrLen                : out std_logic_vector(1 downto 0)  ;
        IPIC_Sel_Data_Src               : out std_logic_vector(1 downto 0)  ;
--        IPIC_Sel_RdDBus_Src             : out std_logic                     ;
        IPIC_RegFile_WE                 : out std_logic                     ;
        IPIC_RegFile_Sel_Eng            : out std_logic                     ;
        IPIC_RegFile_Sel_Reg            : out std_logic_vector(2 downto 0)  ;

        IPIC_Control_Reg_WE             : out std_logic                     ;
        IPIC_Control_Reg_RE             : out std_logic                     ;

        IPIC_TX_Cntl_Reg_WE             : out std_logic                     ;
--        IPIC_TX_Cntl_Reg_RE             : out std_logic                     ;

        IPIC_RX_Cntl_Reg_WE             : out std_logic                     ;
--        IPIC_RX_Cntl_Reg_RE             : out std_logic                     ;

        IPIC_TX_Int_Reg_WE              : out std_logic                     ;
        IPIC_TX_Int_Reg_RE              : out std_logic                     ;

        IPIC_RX_Int_Reg_WE              : out std_logic                     ;
        IPIC_RX_Int_Reg_RE              : out std_logic                     ;

        IPIC_TX_Sts_Reg_RE              : out std_logic                     ;
        IPIC_RX_Sts_Reg_RE              : out std_logic                     ;
        
        IPIC_WrDBus                     : out std_logic_vector(0 to 31)     ;
        IPIC_RdDBus                     : in  std_logic_vector(0 to 31)     ;

        -- DCR Port Arbiter Signals               
        IPIC_RegFile_Request            : out std_logic                     ;
        IPIC_RegFile_Busy               : out std_logic                     ;
        IPIC_RegFile_Grant              : in  std_logic                     ;

        -- DCR Event Detects                      
        Write_Curr_Ptr_TX               : out std_logic                     ;
        Write_Curr_Ptr_RX               : out std_logic                     ;
        Write_Tail_Ptr_TX               : out std_logic                     ;
        Write_Tail_Ptr_RX               : out std_logic
        );
end sdma_ipic_if;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_ipic_if is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
constant ALL_ONES               : std_logic_vector(0 to 3) := (others => '1');

-------------------------------------------------------------------------------
-- Signal/Type Declarations
-------------------------------------------------------------------------------
signal channelrst_d1            : std_logic;
signal channelrst_start         : std_logic;
signal ipic_regfile_we_i        : std_logic;
signal addr_i                   : std_logic_vector(0 to 3);



signal ll2plb_clk_toggle        : std_logic;
signal rdack                    : std_logic;
signal wrack                    : std_logic;
signal wrack_d1                 : std_logic;
signal wrack_strb               : std_logic;
signal ipic_regfile_busy_i      : std_logic;
signal ipic_regfile_request_i   : std_logic;
signal grant_hold               : std_logic;

signal bus2ip_cs_d1             : std_logic;
signal bus2ip_cs_strb           : std_logic;
signal regfile_sel              : std_logic_vector(0 to 2);
signal regfile_enable           : std_logic;
signal bus2ip_cs_reg            : std_logic;
signal regfilerstdone_i         : std_logic;
signal regfilerstdone_d1        : std_logic;
signal start_reset              : std_logic;
signal inhibit_regfile_write    : std_logic;
signal select_reset             : std_logic;
signal ll2plb_clk_toggle_i      : std_logic;
-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

SMPL_CLK_I : entity mpmc_v6_03_a.sdma_sample_cycle
    port map(
        fast_clk        => LLink_Clk            ,
        slow_clk        => Bus2IP_Clk           ,
        sample_cycle    => ll2plb_clk_toggle_i
    );
    
ll2plb_clk_toggle <= ll2plb_clk_toggle_i after 1 ps; -- Modelsim workaround

-------------------------------------------------------------------------------
-- Generate strobe on rising edge of CS to prevent multiple requests to LUTRAM
-------------------------------------------------------------------------------
BUS2IP_CS_DLY : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or ChannelRST='1' or select_reset='1')then
                bus2ip_cs_d1    <= '0';
                bus2ip_cs_strb  <= '0';
            else
                bus2ip_cs_d1    <= Bus2IP_CS;
                bus2ip_cs_strb  <= Bus2IP_CS and not bus2ip_cs_d1;
            end if;
        end if;
    end process BUS2IP_CS_DLY;
--GAB 5/9/07 moved into register process above to prevent strobe during a reset
--bus2ip_cs_strb <= Bus2IP_CS and not bus2ip_cs_d1;

BUS2IP_CS_DLY2 : process(Bus2IP_Clk)
    begin
        if(Bus2IP_Clk'EVENT and Bus2IP_Clk='1')then
            if(LLink_Rst = '1' or ChannelRST='1' or select_reset='1')then
                bus2ip_cs_reg <= '0';
            else
                bus2ip_cs_reg <= Bus2IP_CS;
            end if;
        end if;
    end process BUS2IP_CS_DLY2;

-------------------------------------------------------------------------------
-- Decode between descrete registers and regfile access
-------------------------------------------------------------------------------
--regfile_enable <= '1' when (Bus2IP_Addr(25) = '0' and Bus2IP_Addr(27) = '0')
--                        or (Bus2IP_Addr(27) = '1' and Bus2IP_Addr(28) = '0' and Bus2IP_Addr(29) = '0')
--          else '0';

regfile_sel <= Bus2IP_Addr(25) & Bus2IP_Addr(27 to 28);
REGFILE_ACCESS : process(regfile_sel)
    begin
        case regfile_sel is
            when "011" | "100" =>       -- Offset: 0x18,0x1c,0x38,0x3c, and 0x40 
                regfile_enable <= '0';
            when others =>              -- Offset: 0x00 to 0x14, 0x20 to 0x34
                regfile_enable <= '1';
         end case;
     end process REGFILE_ACCESS;


-------------------------------------------------------------------------------
-- Request access to the LUTRAM for access to the LUTRAM, address offset
-- 0x00 to 0x14 and 0x20 to 0x34.
-------------------------------------------------------------------------------
REGFILE_REQUEST : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or IPIC_RegFile_Grant='1')then
                ipic_regfile_request_i <= '0';
            elsif((regfile_enable = '1' and bus2ip_cs_strb='1')
            or (channelrst_start='1'))then
                ipic_regfile_request_i <= '1';
            end if;
        end if;
    end process REGFILE_REQUEST;
            

REGFILE_BUSY : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or (ipic_regfile_request_i = '0' and ll2plb_clk_toggle='1' and regfilerstdone_i='1'))then
                ipic_regfile_busy_i <= '0';
            elsif(IPIC_RegFile_Grant = '1')then
                ipic_regfile_busy_i <= '1';
            end if;
        end if;
    end process REGFILE_BUSY;
            
IPIC_RegFile_Busy       <= ipic_regfile_busy_i;            
IPIC_RegFile_Request    <= ipic_regfile_request_i;


-------------------------------------------------------------------------------
-- Issue Data Acknowledge to the IPIF Slave
-------------------------------------------------------------------------------
ACK_PROCESS : process(Bus2IP_Clk)
    begin
        if(Bus2IP_Clk'EVENT and Bus2IP_Clk = '1')then
            if(Bus2IP_Reset = '1' or ChannelRST='1' or select_reset='1')then
                wrack <= '0';
                rdack <= '0';
            
            --Ack regfile access
            elsif((Bus2IP_CS = '1' and ipic_regfile_busy_i = '1' and ll2plb_clk_toggle='1')
            
            --Ack descrete register access
            or (Bus2IP_CS = '1' and bus2ip_cs_reg = '0'
            and regfile_enable='0' and ll2plb_clk_toggle='1'))then

                wrack <= not bus2ip_rnw;
                rdack <= bus2ip_rnw;
            else
                wrack <= '0';
                rdack <= '0';
            end if;
        end if;
    end process ACK_PROCESS;

IP2Bus_WrAck    <= wrack;
--IP2Bus_RdAck    <= rdack;

REG_RDACK : process(Bus2IP_Clk)
    begin
        if(Bus2IP_Clk'EVENT and Bus2IP_Clk='1')then
            if(Bus2IP_Reset = '1')then
                IP2Bus_RdAck <= '0';
            else
                IP2Bus_RdAck    <= rdack;
            end if;
        end if;
    end process REG_RDACK;

READ_BUS : process(Bus2IP_clk)
    begin
        if(Bus2IP_Clk'EVENT and Bus2IP_Clk = '1')then
            if(Bus2IP_Reset = '1')then
                IP2Bus_Data <= (others => '0');
            elsif(rdack='1')then
                IP2Bus_Data <= IPIC_RdDBus;
            else
                IP2Bus_Data <= (others => '0');
            end if;
        end if;
    end process READ_BUS;

--READ_MUX : process(rdack)
--    begin
--        if(rdack='1')then
--            IP2Bus_Data <= IPIC_RdDBus;
--        else
--            IP2Bus_Data <= (others => '0');
--        end if;
--    end process READ_MUX;

    
      
STRB_WRACK : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or ChannelRST='1')then
                wrack_d1 <= '0';
            else
                wrack_d1 <= wrack;
            end if;
        end if;
    end process STRB_WRACK;
    
wrack_strb <= wrack and not wrack_d1;    

   
IPIC_Sel_AddrLen         <= "00";
IPIC_Sel_Data_Src        <= "01";   

-- 0x20 to 0x3F (Read MUX Select between LUTRAM and Status Registers '1')
ipic_regfile_we_i          <= '1' when ipic_regfile_busy_i = '1' and Bus2IP_RNW='0' 
                                        and inhibit_regfile_write='0'
                         else '0';
                      
-- If the transmit engine is busy then do not allow a write 
-- to tx_nxtdesc,tx_curbuf_addr,tx_curbuf_length, tx_curdesc registers                         .
-- If the receive engine is buys then do not allow a write
-- to rx_nxtdesc,rx_curbuf_addr,rx_curbuf_length, rx_curdesc registers                         .
--inhibit_regfile_write <= '1' when (RX_Busy='1' and Bus2ip_Addr(27 to 28)="01")
--                               or (TX_Busy='1' and Bus2IP_Addr(27 to 28)="10")
--                    else '0';
                         
inhibit_regfile_write <= '1' when (RX_Busy='1' and Bus2ip_Addr(25 to 27)="010")
                               or (TX_Busy='1' and Bus2IP_Addr(25 to 27)="000")
                    else '0';
                         

-- Interrupt Status Register Read/Write Control   
IPIC_TX_Int_Reg_WE  <= Bus2IP_WrCE(TX_IRQ_CE) and wrack_strb;
IPIC_RX_Int_Reg_WE  <= Bus2IP_WrCE(RX_IRQ_CE) and wrack_strb;

IPIC_TX_Int_Reg_RE  <= Bus2IP_RdCE(TX_IRQ_CE);
IPIC_RX_Int_Reg_RE  <= Bus2IP_RdCE(RX_IRQ_CE);

-- Detect when CPU writes Current Descriptor Pointer
Write_Curr_Ptr_TX   <= Bus2IP_WrCE(TX_CURDESC_PTR_CE) and wrack_strb;
Write_Curr_Ptr_RX   <= Bus2IP_WrCE(RX_CURDESC_PTR_CE) and wrack_strb;

-- Tail Pointer Register Write Control
Write_Tail_Ptr_TX   <= Bus2IP_WrCE(TX_TAILDESC_PTR_CE) and wrack_strb;
Write_Tail_Ptr_RX   <= Bus2IP_WrCE(RX_TAILDESC_PTR_CE) and wrack_strb;

IPIC_TX_Cntl_Reg_WE <= Bus2IP_WrCE(TX_CHNL_CTRL_CE) and wrack_strb;
--IPIC_TX_Cntl_Reg_RE <= Bus2IP_RdCE(TX_CHNL_CTRL_CE);
--
IPIC_RX_Cntl_Reg_WE <= Bus2IP_WrCE(RX_CHNL_CTRL_CE) and wrack_strb;
--IPIC_RX_Cntl_Reg_RE <= Bus2IP_RdCE(RX_CHNL_CTRL_CE);



IPIC_TX_Sts_Reg_RE  <= Bus2IP_RdCE(TX_CHNL_STS_CE);
IPIC_RX_Sts_Reg_RE  <= Bus2IP_RdCE(RX_CHNL_STS_CE);

-- DMA Control Register Write control
IPIC_Control_Reg_WE  <= Bus2IP_WrCE(DMA_CNTRL_CE) and wrack_strb;
IPIC_Control_Reg_RE  <= Bus2IP_RdCE(DMA_CNTRL_CE);

-------------------------------------------------------------------------------
-- Register FILE Reset Logic
-------------------------------------------------------------------------------
--STRB_RESET_SRC : process(LLink_Clk)
--    begin
--        if(LLink_Clk'EVENT and LLink_Clk = '1')then
--            if(LLink_Rst = '1')then
--                channelrst_d1       <= '0';
--                regfilerstdone_d1   <= '0';
--            else
--                channelrst_d1       <= ChannelRST; 
--                regfilerstdone_d1   <= regfilerstdone_i;
--            end if;
--        end if;
--    end process STRB_RESET_SRC;


STRB_RESET_SRC : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk = '1')then
            if(LLink_Rst = '1')then
                start_reset     <= '0';
                channelrst_d1   <= '0';
            else
                start_reset     <= ChannelRST and not System_Busy;
                channelrst_d1   <= start_reset;
            end if;
        end if;
    end process STRB_RESET_SRC;

REG_RST_FOR_STRBS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk = '1')then
            if(LLink_Rst = '1')then
                regfilerstdone_d1   <= '0';
            else
                regfilerstdone_d1   <= regfilerstdone_i;
            end if;
        end if;
    end process REG_RST_FOR_STRBS;

--channelrst_start <= ChannelRST and not channelrst_d1;
channelrst_start <= start_reset and not channelrst_d1;

LUTRAM_ADDR : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1')then
                addr_i              <= (others => '1');
                regfilerstdone_i    <= '1';
                select_reset        <= '0';
            elsif(channelrst_start='1')then
                addr_i              <= (others => '0');
                regfilerstdone_i    <= '0';
                select_reset        <= '1';
            elsif(addr_i = ALL_ONES) then
                addr_i              <= (others => '1');
                regfilerstdone_i    <= '1';
                select_reset        <= '0';
            -- Qualified with select_reset = 1 to prevent enter elsif clause unless
            -- actual soft reset commanded. CR446818
            elsif(ipic_regfile_busy_i='1' and select_reset='1')then
                addr_i              <= std_logic_vector(unsigned(addr_i) + 1);
                regfilerstdone_i    <= '0';
                select_reset        <= '1';
            end if;
        end if;
    end process LUTRAM_ADDR;

REG_DRIVE_EXT_RST : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            SDMA_Ext_Reset <= select_reset;
        end if;
    end process REG_DRIVE_EXT_RST;


RegFileRstDone  <= regfilerstdone_i and not regfilerstdone_d1;

IPIC_RegFile_WE           <= '1' when select_reset = '1'
                        else ipic_regfile_we_i;

IPIC_RegFile_Sel_Eng      <= addr_i(3) when select_reset = '1'
                        else Bus2IP_Addr(26);
                        
IPIC_RegFile_Sel_Reg      <= addr_i(0 to 2) when select_reset='1'
                        else Bus2IP_Addr(27 to 29);
        
IPIC_WrDBus             <= (others => '0') when select_reset = '1'
                        else Bus2IP_Data(0 to 22) & '0' & Bus2IP_Data(24 to 31) when Bus2IP_WrCE(RX_CHNL_CTRL_CE)='1' or Bus2IP_WrCE(TX_CHNL_CTRL_CE)='1'
                        else Bus2IP_Data;



end implementation;
