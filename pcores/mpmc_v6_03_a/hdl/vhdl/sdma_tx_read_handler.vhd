-------------------------------------------------------------------------------
-- sdma_tx_read_handler.vhd
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
-- Filename:        sdma_tx_read_handler.vhd
-- Description:       
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
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
-- ^^^^^^
--  GAB     9/28/07
-- ~~~~~~
--  - Zero extended various vectors in summation functions to prevent truncation
--  issues
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
entity sdma_tx_read_handler is
  generic(
    C_TIMEOUT_PERIOD                :     integer := 4
    );
  port(
    -- Global Signals
    LLink_Clk                       : in  std_logic;  
    LLink_Rst                       : in  std_logic;  
    -- Port Interface Signals
    rdDataAck_Pos                   : out std_logic;  
    rdDataAck_Neg                   : out std_logic;  
    rdComp                          : out std_logic;  
    rd_rst                          : out std_logic;  
    rd_fifo_empty                   : in  std_logic;  
    -- Local Link Signals
    TX_Rem                          : out std_logic_vector(3 downto 0); 
    TX_SOF                          : out std_logic;
    TX_EOF                          : out std_logic;
    TX_SOP                          : out std_logic;
    TX_EOP                          : out std_logic;
    TX_Src_Rdy                      : out std_logic;
    TX_Dst_Rdy                      : in  std_logic;
    -- Datapath Signals
    SDMA_Sel_rdData_Pos            : out std_logic_vector(3 downto 0);
    -- Status Signal
    EndOfPacket                     : in  std_logic;
    -- Counter Signals
    SDMA_TX_Address                : in  std_logic_vector(31 downto 0);
    SDMA_TX_Length                 : in  std_logic_vector(31 downto 0);
    SDMA_TX_AddrLen_INC1           : out std_logic;                
    SDMA_TX_AddrLen_INC2           : out std_logic;
    SDMA_TX_AddrLen_INC3           : out std_logic;
    SDMA_TX_AddrLen_INC4           : out std_logic;
    -- TX Byte Shifter Controls
    SDMA_TX_Shifter_Byte_Sel0      : out std_logic_vector(1 downto 0);
    SDMA_TX_Shifter_Byte_Sel1      : out std_logic_vector(1 downto 0);
    SDMA_TX_Shifter_Byte_Sel2      : out std_logic_vector(1 downto 0);
    SDMA_TX_Shifter_Byte_Sel3      : out std_logic_vector(1 downto 0);
    SDMA_TX_Shifter_Byte_Reg_CE    : out std_logic_vector(3 downto 0);
    -- Port Controller Signals
    TX_CL8R_Start                   : in  std_logic;
    TX_CL8R_Comp                    : out std_logic;
    TX_B16R_Start                   : in  std_logic;
    TX_B16R_Comp                    : out std_logic;
    TX_RdPop                        : out std_logic;
    TX_Payload                      : out std_logic;
    -- Channel Reset Signals
    TX_ChannelRST                   : in  std_logic;
    TX_RdHandlerRST                 : in  std_logic;
    -- Timeout Signal
    TX_Timeout                      : in  std_logic 
    );
end sdma_tx_read_handler;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sdma_tx_read_handler is     

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant ZERO_VECTOR    : std_logic_vector(63 downto 0) := (others => '0');

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
type STATES is (IDLE,                 -- 3'b000,
              DISCARD,              -- 3'b001,
              PROCESSS,             -- 3'b010,
              BTWN_BURST,           -- 3'b011,
              WAIT_FOR_DATA,        -- 3'b100,
              BTWN_DESC );          -- 3'b101;

signal CS                   : STATES;
signal tx_payload_i         : std_logic;
signal StartOfPacket        : std_logic;

signal Rd_Rst_Pending       : std_logic;
signal RdPopCount           : std_logic_vector(4 downto 0);
signal Toggle               : std_logic;

signal CL8R_Pop             : std_logic;
signal CL8R_Active          : std_logic;

signal B16R_Pop             : std_logic;
signal TX_B16R_Comp_i       : std_logic;
signal DiscardDone_i        : std_logic;
signal DiscardDone          : std_logic;
signal Rd_Rst_Set           : std_logic;
signal StartOffset          : std_logic_vector(2 downto 0);
signal TogglePosNeg         : std_logic;
signal B16R_Sel_rdData_Pos  : std_logic_vector(3 downto 0);
signal BytesHolding         : std_logic_vector(1 downto 0);
signal Byte_Reg_CE_i        : std_logic_vector(3 downto 0);
signal B16R_Src_Rdy         : std_logic;
--freddy
signal FirstData            : std_logic;
signal oddball              : std_logic;  -- if address starts on the last word of a burst

signal DataAvailable        : std_logic;
signal FirstPop             : std_logic;
signal LastData             : std_logic;
signal LastRdy              : std_logic;

signal LastBurst            : std_logic;
signal Length0Start         : std_logic;
signal Length0Middle        : std_logic;
signal Address0Start        : std_logic;
signal Address0Middle       : std_logic;
signal Length0              : std_logic;
signal Address0             : std_logic;
--signal LastCount            : std_logic_vector(1 downto 0);
--signal LastCount2           : std_logic_vector(1 downto 0);
signal LastCount            : signed(1 downto 0);
signal LastCount2           : signed(1 downto 0);

signal Rem_Active           : std_logic;
signal INC_First            : std_logic_vector(3 downto 0);
signal INC_Last             : std_logic_vector(3 downto 0);
signal INC_Internal         : std_logic_vector(3 downto 0);

signal Timeout_Advance      : std_logic;
signal Timeout_Detect       : std_logic;
signal Timeout_Count        : std_logic_vector(3 downto 0);

signal tx_rdpop_i           : std_logic;
signal tx_cl8r_comp_i       : std_logic;
signal rd_rst_i             : std_logic;
signal tx_b16r_cmp_i        : std_logic;
signal tx_eop_i             : std_logic;
signal tx_eof_i             : std_logic;
signal tx_sop_i             : std_logic;
signal tx_src_rdy_i         : std_logic;
signal bytesholding_8bits   : std_logic_vector(7 downto 0);
signal chnl_rst_strb        : std_logic;
signal chnl_rst_d1          : std_logic;

signal rd_rst_d1            : std_logic;
signal ZeroExtendAddr       : std_logic_vector(32 downto 0);
signal LastBurstLngthCalc   : std_logic_vector(32 downto 0);
signal LengthStartCalc      : std_logic_vector(8 downto 0);
signal LengthMidCalc        : std_logic_vector(8 downto 0);
-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------
begin
TX_Payload      <= tx_payload_i;                                 
TX_RdPop        <= tx_rdpop_i;
TX_CL8R_Comp    <= tx_cl8r_comp_i;
rd_rst          <= Rd_Rst_Pending or LLink_Rst;
TX_B16R_Comp    <= tx_b16r_cmp_i;
TX_EOP          <= tx_eop_i;
TX_Src_Rdy      <= tx_src_rdy_i;
TX_EOF          <= tx_eof_i;
TX_SOP          <= tx_sop_i;

DataAvailable <= (not rd_fifo_empty or Toggle);
tx_rdpop_i <= CL8R_Pop or B16R_Pop;
   
-- Port Interface Signals
rdDataAck_Pos <= tx_rdpop_i and not Toggle;
rdDataAck_Neg <= tx_rdpop_i and Toggle;
rdComp <= tx_cl8r_comp_i or TX_B16R_Comp_i;


-------------------------------------------------------------------------------
-- Reset Logic
-------------------------------------------------------------------------------
-- Read Fifo is reset by 3 things:
-- 1.  Read Byte Shifter encounters 0 length
-- 2.  TX_ChannelRST when Read Port Active
-- 3.  Read Port Timeout
rd_rst_i  <= Rd_Rst_Set or TX_ChannelRST or Timeout_Detect;

REG_RESET : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            rd_rst_d1   <=  rd_rst_i;
            chnl_rst_d1 <= TX_ChannelRST;
        end if;
    end process REG_RESET;

-- Gen reset for flushing rdfifo and for issuing a B16R comp
Rd_Rst_Pending  <= rd_rst_i and not rd_rst_d1;

-- Gen reset for for issuing a CL8R comp during channel reset
chnl_rst_strb   <= TX_ChannelRST and not chnl_rst_d1;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or tx_cl8r_comp_i='1' or tx_b16r_cmp_i='1') then
              RdPopCount <= (others =>'0');
            elsif (tx_rdpop_i='1') then
              RdPopCount <= std_logic_vector(unsigned(RdPopCount) + 1);
            end if;
          end if;
        end process;
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or tx_cl8r_comp_i='1' or tx_b16r_cmp_i='1') then
              Toggle <= '0';
            elsif (tx_rdpop_i='1') then
              Toggle <= not Toggle;
            end if;
          end if;
        end process;

   -- Local Link Signals
    TX_SOF <= '1' when not ((to_integer(unsigned(RdPopCount)) = 0) and CL8R_Active='1' and tx_payload_i='0') else '0';
    --TX_SOF <= '0' when ((to_integer(unsigned(RdPopCount)) = 0) and CL8R_Active='1' and tx_payload_i='0')
    --     else '1';
   -- freddy
    tx_sop_i <= not (FirstData and StartOfPacket and not oddball);
   --  TX_SOP = not (FirstData and StartOfPacket);
    tx_eop_i <= not (Length0 and EndOfPacket);

        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
              tx_eof_i <= '1';
            elsif (TX_Dst_Rdy='0' and tx_src_rdy_i='0') then
              tx_eof_i <= tx_eop_i;
            end if;
          end if;
        end process;
        --freddy
        tx_src_rdy_i <= not ((CL8R_Active and DataAvailable and not tx_payload_i) or B16R_Src_Rdy) and tx_eof_i;
        -- TX_Src_Rdy = not ((CL8R_Active and not TX_Payload) or B16R_Src_Rdy) and TX_EOF and TX_SOP;

        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or (tx_eof_i='0' and TX_Dst_Rdy='0' and tx_src_rdy_i='0')) then
              tx_payload_i <= '0';
            elsif (tx_cl8r_comp_i='1') then
              tx_payload_i <= '1';
            end if;
          end if;
        end process;
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or (tx_sop_i='0' and TX_Dst_Rdy='0' and tx_src_rdy_i='0')) then
              StartOfPacket <= '0';
              -- freddy
            elsif (tx_cl8r_comp_i='1' and tx_payload_i='0') then
              StartOfPacket <= '1';
            end if;
            --else if (TX_CL8R_Comp) StartOfPacket <= 1;
          end if;
        end process;
        
-- Datapath Signals
SDMA_Sel_rdData_Pos <= (others => not(Toggle)) when CL8R_Active='1' else B16R_Sel_rdData_Pos;

-- CL8R
CL8R_Pop <= CL8R_Active and (tx_payload_i or not TX_Dst_Rdy) and DataAvailable;

tx_cl8r_comp_i <= '1' when ((to_integer(unsigned(RdPopCount)) = 7) and CL8R_Pop='1')
                         or (chnl_rst_strb='1')
             else '0';

    process(LLink_Clk)
    begin
      if(LLink_Clk'EVENT and LLink_Clk='1')then
        if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or tx_cl8r_comp_i='1') then
          CL8R_Active <= '0';
        elsif (TX_CL8R_Start='1') then
          CL8R_Active <= '1';
        end if;
      end if;
    end process;

-- B16R
TX_B16R_Comp_i  <= Address0 and B16R_Pop;
--tx_b16r_cmp_i   <= TX_B16R_Comp_i or rd_rst_i;
tx_b16r_cmp_i   <= TX_B16R_Comp_i or Rd_Rst_Pending;
Rd_Rst_Set      <= Length0 and not TX_Dst_Rdy and DataAvailable;

process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if ((CS = DISCARD) and DataAvailable='1') then
                if(RdPopCount = std_logic_vector(unsigned(SDMA_TX_Address(6 downto 2)) - 1)) then
                    DiscardDone_i   <= '1';
                else
                    DiscardDone_i   <= '0';
                end if;
            elsif (CS /= DISCARD) then
                if(to_integer(unsigned(SDMA_TX_Address(6 downto 2))) = 0) then
                    DiscardDone_i   <= '1';
                else
                    DiscardDone_i   <= '0';
                end if;
            end if;
        end if;
    end process;

    DiscardDone <= DiscardDone_i and DataAvailable;
   
   -- StartOffset controls how bytes are twisted
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or (CS = IDLE)) then
              StartOffset <= (others => '0');
            elsif (CS = DISCARD) then
              StartOffset <= std_logic_vector(unsigned(SDMA_TX_Address(2 downto 0)) - unsigned(bytesholding_8bits(2 downto 0)));
            end if;
          end if;
        end process;

   -- Control Byte Shifter
        process(StartOffset, TogglePosNeg)
          variable a,b,c,d : std_logic_Vector(2 downto 0);
          begin
            a := (std_logic_vector(0 + unsigned(StartOffset(2 downto 0)))) xor (TogglePosNeg & "00");
            b := (std_logic_vector(1 + unsigned(StartOffset(2 downto 0)))) xor (TogglePosNeg & "00");
            c := (std_logic_vector(2 + unsigned(StartOffset(2 downto 0)))) xor (TogglePosNeg & "00");
            d := (std_logic_vector(3 + unsigned(StartOffset(2 downto 0)))) xor (TogglePosNeg & "00");
            B16R_Sel_rdData_Pos(0)<= a(2);
            B16R_Sel_rdData_Pos(1)<= b(2);
            B16R_Sel_rdData_Pos(2)<= c(2);
            B16R_Sel_rdData_Pos(3)<= d(2);
            SDMA_TX_Shifter_Byte_Sel3<=a(1 downto 0);
            SDMA_TX_Shifter_Byte_Sel2<=b(1 downto 0);
            SDMA_TX_Shifter_Byte_Sel1<=c(1 downto 0);
            SDMA_TX_Shifter_Byte_Sel0<=d(1 downto 0);
        end process;

   -- TogglePosNeg
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or (CS = IDLE) or (CS = BTWN_DESC)) then
              TogglePosNeg <= '1';
              --freddy
            elsif (TX_Dst_Rdy='0' and tx_src_rdy_i='0') then
              TogglePosNeg <= not TogglePosNeg;
              --else if (not TX_Dst_Rdy and not TX_Src_Rdy and not (FirstData and LastData)) TogglePosNeg = not TogglePosNeg;
            end if;
          end if;
        end process;
        
        -- BytesHolding keeps track of how many bytes are being held
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
              BytesHolding <= "00";
            elsif (LastData='1' and TX_Dst_Rdy='0' and DataAvailable='1') then
--GAB
--              BytesHolding <= LastCount;
             BytesHolding <= std_logic_vector(LastCount);
            elsif ((FirstData='1' and TX_Dst_Rdy='0' and tx_src_rdy_i='0') or (CS = IDLE)) then
              BytesHolding <= "00";
            end if;
          end if;
        end process;


bytesholding_8bits <= "000000" & BytesHolding;
        
        -- Generate Clock Enables for Saving Bytes
        process(BytesHolding)
        begin
          case (BytesHolding) is
            when "00"=> Byte_Reg_CE_i <= "1111";
            when "01"=> Byte_Reg_CE_i <= "0111";
            when "10"=> Byte_Reg_CE_i <= "0011";
            when "11"=> Byte_Reg_CE_i <= "0001";
            when others => Byte_Reg_CE_i <= "0000";
          end case; -- case(BytesHolding)
        end process;

    SDMA_TX_Shifter_Byte_Reg_CE <= Byte_Reg_CE_i when TX_Dst_Rdy='0' and DataAvailable='1' else (others => '0');

   -- Src_Rdy
    B16R_Src_Rdy <= '1' when (CS = PROCESSS) and (LastData='0' or LastRdy='1') and DataAvailable='1' else '0';
--GAB
--    LastRdy <= '1' when (Length0='1' and EndOfPacket='1') or (to_integer(unsigned(LastCount)) = 0) else '0';
    LastRdy <= '1' when (Length0='1' and EndOfPacket='1') or (to_integer(signed(LastCount)) = 0) else '0';

   -- RdPop
   -- freddy
    B16R_Pop <= '1' when ((CS = DISCARD) and DataAvailable='1' and DiscardDone='0') 
                      or ((CS = PROCESSS) and TX_Dst_Rdy='0' and (FirstData='0' or FirstPop='1') 
                            and DataAvailable='1') else '0';
   
   -- B16R_Pop = ((CS = DISCARD) and not DiscardDone) or ((CS = PROCESSS) and not TX_Dst_Rdy and (not FirstData or FirstPop) 
   --                                                    and not (LastData and FirstData) );

        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
              FirstPop <= '0';
            else
              if((SDMA_TX_Address(1 downto 0) >= BytesHolding)) then
                FirstPop <= '1';
              else
                FirstPop <= '0';
              end if;
            end if;
          end if;
        end process;
  
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or Timeout_Detect='1') then
              FirstData <= '0';
            elsif (((CS = DISCARD) and DiscardDone='1') or ((CS = BTWN_BURST) and TX_B16R_Start='1')) then
              FirstData <= '1';
            elsif (TX_Dst_Rdy='0' and tx_src_rdy_i='0') then
              FirstData <= '0';
            end if;
          end if;
        end process;
        
   -- freddy
    oddball <= FirstData and LastData and not LastRdy;
   
   
    LastData <= Length0 or Address0;

    -- 9/28/07 GAB - Added a carryover bit to the addition to fix potential truncation issue
    ZeroExtendAddr <= ZERO_VECTOR(25 downto 0) & SDMA_TX_Address(6 downto 0);
    LastBurstLngthCalc <= std_logic_vector(unsigned(ZeroExtendAddr) + unsigned('0' & SDMA_TX_Length));

        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
              LastBurst <= '0';
            elsif (TX_B16R_Start='1') then
--              if(to_integer(unsigned('0'& SDMA_TX_Address(6 downto 0)) + unsigned(SDMA_TX_Length)) <= 128) then
              if(LastBurstLngthCalc(32) = '0' 
              and to_integer(unsigned(LastBurstLngthCalc(31 downto 0))) <= 128) then
                LastBurst <= '1';
              else
                LastBurst <= '0';
              end if;
            end if;
          end if;
        end process;

    -- 9/28/07 GAB - Added a carryover bit to the addition to fix potential truncation issue
    LengthStartCalc <= std_logic_vector(unsigned('0' & SDMA_TX_Length(7 downto 0)) + unsigned('0' & bytesholding_8bits));
        -- Length0 Detect
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
              Length0Start <= '0';
            else
--              if( (to_integer(unsigned(SDMA_TX_Length(7 downto 0)) + unsigned(bytesholding_8bits)) <= 4)) then
              if( to_integer(unsigned(LengthStartCalc)) <= 4) then
                Length0Start <= '1' ;
              else
                Length0Start <= '0';
              end if;
            end if;
          end if;
        end process;

    -- 9/28/07 GAB - Added a carryover bit to the addition to fix potential truncation issue
    LengthMidCalc <= std_logic_vector(unsigned('0' & SDMA_TX_Length(7 downto 0)) + unsigned('0' & bytesholding_8bits));
        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
              Length0Middle <= '0';
            elsif (TX_Dst_Rdy='0' and tx_src_rdy_i='0') then
--              if(to_integer(unsigned(SDMA_TX_Length(7 downto 0)) + unsigned(bytesholding_8bits)) <= 8) then
              if(to_integer(unsigned(LengthMidCalc)) <= 8) then
                Length0Middle <= '1';
              else
                Length0Middle<='0';
              end if;
            end if;
          end if;
        end process;

   -- Address0 Detect


process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
                Address0Start <= '0';
            else
                if(to_integer(unsigned(SDMA_TX_Address(6 downto 0))) >= (124 + to_integer(unsigned(BytesHolding)))) then
                    Address0Start <= '1';
                else
                    Address0Start <= '0';
                end if;
            end if;
        end if;
    end process;

        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
              Address0Middle <= '0';
            elsif (TX_Dst_Rdy='0' and tx_src_rdy_i='0') then
              if(to_integer(unsigned(SDMA_TX_Address(6 downto 0))) >= (120 + to_integer(unsigned(BytesHolding)))) then
                Address0Middle <= '1';
              else
                Address0Middle <= '0';
              end if;
            end if;
          end if;
        end process;
   
    Length0     <= '1' when (CS = PROCESSS) and LastBurst='1'   
                            and ((Length0Start='1'  and FirstData='1') 
                            or (Length0Middle='1'    and FirstData='0'))
              else '0';
              
    Address0    <= '1' when (CS = PROCESSS) and LastBurst='0'   
                            and ((Address0Start='1' and FirstData='1') 
                            or (Address0Middle='1'   and FirstData='0')) 
              else '0';

        process(BytesHolding, SDMA_TX_Address, SDMA_TX_Length, LastBurst)
          begin
            if(LastBurst='1') then
--GAB
--              LastCount  <= std_logic_vector(unsigned(SDMA_TX_Length(1 downto 0)) + unsigned(BytesHolding));
--              LastCount2 <= SDMA_TX_Length(1 downto 0);
              LastCount  <= signed(SDMA_TX_Length(1 downto 0)) + signed(BytesHolding);
              LastCount2 <= signed(SDMA_TX_Length(1 downto 0));
            else
--              LastCount  <= std_logic_vector(unsigned(BytesHolding)-unsigned(SDMA_TX_Address(1 downto 0)));
--              LastCount2 <= std_logic_vector(0-unsigned(SDMA_TX_Address(1 downto 0)));
              LastCount  <= signed(BytesHolding)-signed(SDMA_TX_Address(1 downto 0));
              LastCount2 <= 0-signed(SDMA_TX_Address(1 downto 0));
            end if;
        end process;

        -- Counter Increment Signals
        process(FirstData, LastData, INC_Last, INC_First)
        begin
          if (LastData='1') then
            INC_Internal <= INC_Last;
          else
            INC_Internal <= INC_First;
          end if;
        end process;

        process(INC_Internal, TX_Dst_Rdy, CS, DataAvailable)
          variable a : std_logic_vector(3 downto 0);
        begin
          if(CS=PROCESSS and DataAvailable='1' and TX_Dst_Rdy='0') then
            a:=INC_Internal;-- and (not(TX_Dst_Rdy)&not(TX_Dst_Rdy)&not(TX_Dst_Rdy)&not(TX_Dst_Rdy));
          else
            a:=(others => '0');
          end if;
          
          SDMA_TX_AddrLen_INC4 <= a(3);
          SDMA_TX_AddrLen_INC3 <= a(2);
          SDMA_TX_AddrLen_INC2 <= a(1);
          SDMA_TX_AddrLen_INC1 <= a(0);
        end process;   

        process(BytesHolding)
        begin
          case (BytesHolding) is
            when "00"=> INC_First <= "1000";
            when "01"=> INC_First <= "0100";
            when "10"=> INC_First <= "0010";
            when "11"=> INC_First <= "0001";
            when others => INC_First <= "0000";
          end case; -- case(BytesHolding)
        end process;

        process(LastCount2)
        begin
          case (LastCount2) is
            when "00"=> INC_Last <= "1000";
            when "01"=> INC_Last <= "0001";
            when "10"=> INC_Last <= "0010";
            when "11"=> INC_Last <= "0100";
            when others => INC_Last <= "0000";
          end case; -- case(LastCount2)
        end process;
        
        -- Rem Signal Generation
    Rem_Active <= Length0 and EndOfPacket;
   
        process(LastCount, Rem_Active)
        begin
          if (Rem_Active='1') then
            case ((LastCount)) is
              when "00"=> TX_Rem <= "0000";
              when "01"=> TX_Rem <= "0111";
              when "10"=> TX_Rem <= "0011";
              when "11"=> TX_Rem <= "0001";
              when others => TX_Rem <= "0000";
            end case;
          else
            TX_Rem <= "0000";
          end if;
        end process;
        
     process(LLink_Clk)
     begin
       if(LLink_Clk'EVENT and LLink_Clk='1')then
         if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1') then
           CS <= IDLE;
         else
           case (CS) is
             when IDLE=>
               if (TX_B16R_Start='1') then
                 CS <= DISCARD;
               else
                 CS <= IDLE;
               end if;
             when DISCARD=>
               if (DiscardDone='1') then
                 CS <= PROCESSS;
               else
                 CS <= DISCARD;
               end if;
             when PROCESSS=>
               if (Length0='1' and EndOfPacket='1' and TX_Dst_Rdy='0' and DataAvailable='1') then
                 CS <= IDLE;
               elsif (Length0='1' and EndOfPacket='0' and TX_Dst_Rdy='0' and DataAvailable='1') then
                 CS <= BTWN_DESC;
               elsif (Address0='1' and TX_Dst_Rdy='0' and DataAvailable='1') then
                 CS <= BTWN_BURST;
               elsif (Timeout_Detect='1') then
                 CS <= BTWN_DESC;
               else
                 CS <= PROCESSS;
               end if;
             when BTWN_BURST=>
               if (TX_B16R_Start='1') then
                 CS <= WAIT_FOR_DATA;
               else
                 CS <= BTWN_BURST;
               end if;
             when WAIT_FOR_DATA=>
               if (DataAvailable='1') then
                 CS <= PROCESSS;
               else
                 CS <= WAIT_FOR_DATA;
               end if;
             when BTWN_DESC=>
               if (TX_B16R_Start='1') then
                 CS <= DISCARD;
               else
                 CS <= BTWN_DESC;
               end if;
           end case; -- case(CS)
         end if;
       end if;
     end process;

   -- Timeout Counter
    Timeout_Advance <= '1' when TX_Timeout='1' and TX_Dst_Rdy='1' and (CS = PROCESSS) else '0';
    Timeout_Detect  <= '1' when Timeout_Advance='1' and (to_integer(unsigned(Timeout_Count)) = C_TIMEOUT_PERIOD) else '0';

        process(LLink_Clk)
        begin
          if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1' or TX_RdHandlerRST='1' or Timeout_Detect='1' or Timeout_Advance='0') then
              Timeout_Count <= (others => '0');
            elsif (Timeout_Advance='1') then
              Timeout_Count <= std_logic_vector(unsigned(Timeout_Count) + 1);
            end if;
          end if;
        end process;

end implementation;
 
