-------------------------------------------------------------------------------
-- $Id: xbic_dbeat_control.vhd,v 1.2.2.1 2008/12/16 22:23:17 dougt Exp $
-------------------------------------------------------------------------------
-- xbic_dbeat_control.vhd
-------------------------------------------------------------------------------
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
-- Copyright  2007, 2008, 2009 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Filename:        xbic_dbeat_control.vhd
-- Version:         v1_00_a
-- Description:     
-- This VHDL design implements burst support features that are used for fixed
-- length bursts and cacheline transfers.                 
--                  
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--
--             xps_bram_if_cntlr.vhd
--                 |
--                 |- xbic_slave_attach_sngl
--                 |       |
--                 |       |- xbic_addr_decode
--                 |       |- xbic_addr_be_support
--                 |       |- xbic_data_steer_mirror
--                 |
--                 |- xbic_slave_attach_burst
--                         |
--                         |- xbic_addr_decode
--                         |- xbic_addr_be_support
--                         |- xbic_data_steer_mirror
--                         |- xbic_addr_cntr
--                         |       |
--                         |       |- xbic_be_reset_gen.vhd
--                         |
--                         |- xbic_dbeat_control
--                         |- xbic_data_steer_mirror
--
--
-------------------------------------------------------------------------------
-- Author:          DET
-- Revision:        $Revision: 1.2.2.1 $
-- Date:            $5/15/2002$
--
-- History:
--
--      DET        Feb-5-07
-- ~~~~~~
--      -- Special version for the XPS BRAM IF Cntlr that is adapted
--         from plbv46_slave_burst_V1_00_a library
-- ^^^^^^
--
--     DET     8/25/2008     v1_00_b
-- ~~~~~~
--     - Updated to proc_common_v3_00_a.
-- ^^^^^^
-- 
--     DET     9/9/2008     v1_00_b for EDK 11.x release
-- ~~~~~~
--     - Updated Disclaimer in header section.
-- ^^^^^^
--
--     DET     12/16/2008     v1_01_b
-- ~~~~~~
--     - Updated eula/header to latest version.
-- ^^^^^^
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
use IEEE.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.all;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.counter_f;

-- Xilinx Primitive Library
library unisim;
use unisim.vcomponents.all;


-------------------------------------------------------------------------------

entity xbic_dbeat_control is
  generic (
    -- Generics
    C_NATIVE_DWIDTH        : integer := 32       ;
    C_FAMILY               : string  := "virtex5"
    );
  port (
    -- Input ports
    Bus_Rst                : in std_logic  ;
    Bus_clk                : in std_logic  ;
    
  -- Start Control  
    Req_Init               : in std_logic  ;
   
   -- Qualifiers 
    Doing_Single           : in std_logic  ;
    Doing_Cacheline        : in std_logic  ;
    Doing_FLBurst          : in std_logic  ;
    RNW_In                 : in std_logic  ;
    BE_In                  : in std_logic_vector(0 to 3);
    Size_In                : in std_logic_vector(0 to 3);
    MSize_In               : in std_logic_vector(0 to 1);

  -- Count Enables  
    Wr_DAck                : in std_logic  ;
    Rd_DAck                : in std_logic  ;

    -- Special Case Output signals
    Cline_Spec_1DBeat_Case : out std_logic ;
    
    -- Done State signals
    AlmostDone             : out std_logic ;
    Done                   : out std_logic
    );

end entity xbic_dbeat_control;


architecture implementation of xbic_dbeat_control is

  -- functions
    -- none
 
  
  -- Constants
  --Constant COUNTER_SIZE     : integer := 5;
  constant DBEAT_CNTR_SIZE  : integer := 4;
  Constant CNTR_LD_ZEROS    : std_logic_vector(0 to 
                              DBEAT_CNTR_SIZE-1):= (others => '0');
  
  
  Constant LOGIC_LOW        : std_logic := '0';
  Constant LOGIC_HIGH       : std_logic := '1';
  Constant ZERO             : integer := 0;
  Constant ONE              : integer := 1;
  
  
                          
  Constant COUNT_ZERO     : std_logic_vector(0 to DBEAT_CNTR_SIZE-1)
                            := std_logic_vector(to_unsigned(ZERO, DBEAT_CNTR_SIZE));
                          
  Constant CYCLE_CNT_ZERO : std_logic_vector(0 to DBEAT_CNTR_SIZE-1)
                            := std_logic_vector(to_unsigned(ZERO, DBEAT_CNTR_SIZE));
                          
  Constant CYCLE_CNT_ONE  : std_logic_vector(0 to DBEAT_CNTR_SIZE-1)
                            := std_logic_vector(to_unsigned(ONE, DBEAT_CNTR_SIZE));
                    
  -- Types
  
  
   
  -- Signals
  
    signal req_init_reg               : std_logic;
    signal req_init_strt              : std_logic;
    signal dbeat_cnt_en               : std_logic;
    signal dbeat_cnt_init             : std_logic;
    signal dbeat_count                : std_logic_vector(0 to 
                                        DBEAT_CNTR_SIZE-1);
    signal almst_done_cline_value     : std_logic_vector(0 to 
                                        DBEAT_CNTR_SIZE-1);
    signal almst_done_flburst_value   : std_logic_vector(0 to 
                                        DBEAT_CNTR_SIZE-1);
    signal almst_done_comp_value_reg  : std_logic_vector(0 to 
                                        DBEAT_CNTR_SIZE-1);
    signal dbeat_cnt_almst_done_raw   : std_logic;
    signal dbeat_cnt_almst_done       : std_logic;
    signal dbeat_cnt_done             : std_logic;
    signal mult_by_done               : std_logic;
    signal mult_by_almost_done        : std_logic;
    signal mult_by_1                  : std_logic;
    signal mult_by_2                  : std_logic;
    signal mult_by_4                  : std_logic;
    signal doing_multi_dbeat          : std_logic;
    
    signal mult_cnt_sreg              : std_logic_vector(0 to 3);
    
    signal Cline_special_case1        : std_logic;
    signal Cline_special_case2        : std_logic;
    signal Burst_special_case1        : std_logic;
    signal Burst_special_case2        : std_logic;
    
    signal Cline_special_case1_reg    : std_logic;
    signal Cline_special_case2_reg    : std_logic;
    signal Burst_special_case1_reg    : std_logic;
    signal Burst_special_case2_reg    : std_logic;
    
    
-------------------------------------------------------------------------------
begin --(architecture implementation)

  -- Misc assignments

  AlmostDone <= (dbeat_cnt_almst_done and mult_by_almost_done)
   When (Cline_special_case1_reg = '1')
   else (dbeat_cnt_almst_done and mult_by_done);
   
   
  Done       <= dbeat_cnt_done and mult_by_done;
  
  
  
   
  -- Detect a FLBurst of 2 data beats as a special case 
   Burst_special_case1 <= '1'
     when (BE_In = "0001" and
           Doing_FLBurst = '1')
     Else '0';
   
  -- Detect a FLBurst of 3 data beats as a special case 
   Burst_special_case2 <= '1'
     when (BE_In = "0010" and
           Doing_FLBurst = '1')
     Else '0';
   
   
   -- DET req_init_strt    <=  Req_Init and
   -- DET                      not(req_init_reg);
   
   req_init_strt      <=  Req_Init;
   
   
   
   dbeat_cnt_init     <= Bus_Rst or 
                         req_init_strt or 
                         --(not(mult_by_done) and
                         dbeat_cnt_done or
                         Cline_special_case1_reg or
                         Burst_special_case1_reg;            
               
   doing_multi_dbeat  <= Doing_Cacheline or
                         Doing_FLBurst;
                                   
   dbeat_cnt_en       <= Wr_DAck or
                         Rd_DAck;
                   
                               
   mult_by_done         <=  mult_cnt_sreg(0);
             
   mult_by_almost_done  <=  mult_cnt_sreg(0) or 
                            mult_cnt_sreg(1);          
               
   dbeat_cnt_almst_done_raw <= '1'
     when (dbeat_count = almst_done_comp_value_reg)
     Else '0';
               
   
   
   
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_REQ_INIT
   --
   -- Process Description:
   --
   --
   -------------------------------------------------------------
   REG_REQ_INIT : process (bus_clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
          if (Bus_Rst = '1') then
            req_init_reg <= '0';
          else
            req_init_reg <= Req_Init;
          end if; 
        end if;       
      end process REG_REQ_INIT; 
   
  
  
  
   
   
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: REG_SPEC_CASES
    --
    -- Process Description:
    --
    --
    -------------------------------------------------------------
    REG_SPEC_CASES : process (bus_clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Rst        = '1' or
               (dbeat_cnt_done = '1'and
                mult_by_done   = '1' and
                req_init_strt  = '0')) then
              
              Cline_special_case1_reg  <= '0';
              Cline_special_case2_reg  <= '0';
              Burst_special_case1_reg  <= '0';
              Burst_special_case2_reg  <= '0';
              Cline_Spec_1DBeat_Case   <= '0';
                        
            elsif (req_init_strt = '1') then
              
              Cline_special_case1_reg  <= Cline_special_case1;
              Cline_special_case2_reg  <= Cline_special_case2;
              Burst_special_case1_reg  <= Burst_special_case1;
              Burst_special_case2_reg  <= Burst_special_case2;
              Cline_Spec_1DBeat_Case   <= Cline_special_case1 and
                                          mult_by_1;
              
                        
            else
              null;  --  hold current state
            end if; 
         end if;       
       end process REG_SPEC_CASES; 
   
   
   
   
   
   
   
   -------------------------------------------------------------
   -- Combinational Process
   --
   -- Label: CALC_FLB_DONE_COMP_VALUE
   --
   -- Process Description:
   -- This process is a simple lookup table for generating the 
   -- compare to value for the data beat up-counter during 
   -- Fixed Length Burst Operations.
   --
   -------------------------------------------------------------
   CALC_FLB_DONE_COMP_VALUE : process (BE_In)
      begin
   
        case BE_In is
          -- when "0001" =>
          --     almst_done_flburst_value <= "0000"
          -- when "0010" =>
          --     almst_done_flburst_value <= "0000"
          when "0011" =>
              almst_done_flburst_value <= "0001";
          when "0100" =>
              almst_done_flburst_value <= "0010";
          when "0101" =>
              almst_done_flburst_value <= "0011";
          when "0110" =>
              almst_done_flburst_value <= "0100";
          when "0111" =>
              almst_done_flburst_value <= "0101";
          when "1000" =>
              almst_done_flburst_value <= "0110";
          when "1001" =>
              almst_done_flburst_value <= "0111";
          when "1010" =>
              almst_done_flburst_value <= "1000";
          when "1011" =>
              almst_done_flburst_value <= "1001";
          when "1100" =>
              almst_done_flburst_value <= "1010";
          when "1101" =>
              almst_done_flburst_value <= "1011";
          when "1110" =>
              almst_done_flburst_value <= "1100";
          when "1111" =>
              almst_done_flburst_value <= "1101";
          when others =>
              almst_done_flburst_value <= "0000";
        end case;
         
      end process CALC_FLB_DONE_COMP_VALUE; 
   
   
   
   
   
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_COMP_VALUE
   --
   -- Process Description:
   --
   --
   -------------------------------------------------------------
   REG_COMP_VALUE : process (bus_clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst      = '1' or
              (Req_Init     = '1' and
               Doing_Single = '1')) then
             
             almst_done_comp_value_reg <= (others => '0');
           
           elsif (Req_Init      = '1' and
                  Doing_FLBurst = '1') then
             
             almst_done_comp_value_reg <= almst_done_flburst_value;
           
           Elsif (Req_Init        = '1' and
                  Doing_Cacheline = '1') Then

             almst_done_comp_value_reg <= almst_done_cline_value;
                      
           else
             null;  -- hold current value
           end if; 
        end if;       
      end process REG_COMP_VALUE; 
   
   
   
   
   
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_DONE_FLAGS
   --
   -- Process Description:
   -- This process implements the almost_done and done flags.
   --
   -------------------------------------------------------------
   REG_DONE_FLAGS : process (bus_clk)
     begin
       if (Bus_Clk'event and Bus_Clk = '1') then
          if (Bus_Rst         = '1' or 
              (dbeat_cnt_en   = '1' and 
               dbeat_cnt_done = '1' and
               mult_by_done   = '1')) then
            
            dbeat_cnt_almst_done <= '0';
            dbeat_cnt_done       <= '0';
          
          -- Special case Singles
          Elsif (req_init_strt = '1' and
                 Doing_Single  = '1') Then

            --dbeat_cnt_almst_done <= '0';
            dbeat_cnt_almst_done <= '1';
            dbeat_cnt_done       <= '1';
          
          -- Special case Cachelines (1 data beat case)
          Elsif (req_init_strt       = '1' and
                 --mult_by_1           = '1' and
                 Doing_Cacheline     = '1' and
                 Cline_special_case1 = '1') Then

            --dbeat_cnt_almst_done <= '0';
            dbeat_cnt_almst_done <= '1';
            dbeat_cnt_done       <= '1';
          
          -- Special case Cachelines (2 data beat case)
          Elsif (req_init_strt       = '1' and
                 --mult_by_1           = '1' and
                 Doing_Cacheline     = '1' and
                 Cline_special_case2 = '1') Then

            dbeat_cnt_almst_done <= '1';
            dbeat_cnt_done       <= '0';
          
          -- Special case Fixed Length Burst (2 data beat case)
          Elsif (req_init_strt       = '1' and
                 --mult_by_1           = '1' and
                 Doing_FLBurst       = '1' and 
                 Burst_special_case1 = '1') Then

            dbeat_cnt_almst_done <= '1';
            dbeat_cnt_done       <= '0';
          
          -- Starting a non-special case cacheline or flburst     -- new DET
          Elsif (req_init_strt       = '1') Then                  -- new DET
                                                                  -- new DET
            dbeat_cnt_almst_done <= '0';                          -- new DET
            dbeat_cnt_done       <= '0';                          -- new DET
                                                                  -- new DET
          -- Normal termination case based on Dbeat Counter
          elsif (dbeat_cnt_en  = '1') then
          
            dbeat_cnt_almst_done <= (dbeat_cnt_almst_done_raw and 
                                     not(dbeat_cnt_almst_done)) or
                                    Cline_special_case1_reg;
                                    
            dbeat_cnt_done       <= dbeat_cnt_almst_done;
          
          else
          
            null;  -- hold current state
          
          end if; 
       end if;       
     end process REG_DONE_FLAGS; 
   
   
               
               
   ----------------------------------------------------------------------------
   -- Data Beat Counter Logic
   -- This counter is reset at command start and counts up with every data 
   -- acknowledge assertion. A primary requirement for its implementation is
   -- that it be ready to count a Write data acknowledge on the same clock
   -- cycle that the Sl_Addrack is being asserted to the PLB.
   ----------------------------------------------------------------------------
          
   -- RESP_LOAD_VALUE : process(Num_Data_Beats)
   --  begin
   --      if(C_MAX_DBEAT_CNT > Num_Data_Beats)then
   --          resp_db_load_value <= std_logic_vector(to_unsigned(Num_Data_Beats, DBEAT_CNTR_SIZE));
   --      else
   --          resp_db_load_value <= std_logic_vector(to_unsigned(C_MAX_DBEAT_CNT-1,DBEAT_CNTR_SIZE));
   --      end if;
   --  end process RESP_LOAD_VALUE;
   -- 
   -- resp_db_cnten <= Target_DataAck and 
   --                  not(Response_Done_i);
                    

    I_DBEAT_CNTR : entity proc_common_v3_00_a.counter_f 
        generic map(
            C_NUM_BITS      => DBEAT_CNTR_SIZE,
            C_FAMILY        => C_FAMILY
            )
        port map (
            Clk             =>  Bus_clk,
            Rst             =>  dbeat_cnt_init,
            Load_In         => CNTR_LD_ZEROS,
            Count_Enable    => dbeat_cnt_en,
            Count_Load      => LOGIC_LOW,
            Count_Down      => '0', -- count up
            Count_Out       => dbeat_count,
            Carry_Out       => open
            );

    
 
   
   
               
               
               
               
    
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: BLE_32_BIT_SLAVE
    --
    -- If Generate Description:
    -- Detirmine the Burst Length Expansion factor when the 
    -- Slave width is 32.
    --
    --
    ------------------------------------------------------------
    BLE_32_BIT_SLAVE : if (C_NATIVE_DWIDTH = 32) generate
    
       begin
    
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: CALC_CLINE_DONE_COMP_VALUE_S32
         --
         -- Process Description:
         -- This process is a simple lookup table for generating the 
         -- compare to value for the data beat up-counter during 
         -- Cacheline Operations.
         --
         --
         -- 32-bit Slave can transfer 1 wds per data beat
         -------------------------------------------------------------
         CALC_CLINE_DONE_COMP_VALUE_S32 : process (Size_In)
            begin
         
              Cline_special_case1  <= '0';
              Cline_special_case2  <= '0';
              
              case Size_In is
                when "0001" =>  -- Cacheline 4wrds (4 dbeats)
                    almst_done_cline_value <= "0001";
                when "0010" =>  -- Cacheline 8wrds (8 dbeats)
                    almst_done_cline_value <= "0101";
                when "0011" =>  -- Cacheline 16wrds (16 dbeats)
                    almst_done_cline_value <= "1101";
                when others =>
                    almst_done_cline_value <= "0000";
              end case;
               
            end process CALC_CLINE_DONE_COMP_VALUE_S32; 
         
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: GET_MULT_BY_S32
         --
         -- Process Description:
         -- Detirmine the Burst Length Expansion factor when the 
         -- Slave width is 32.
         --
         -------------------------------------------------------------
         GET_MULT_BY_S32 : process (Doing_FLBurst,
                                    Doing_Cacheline,
                                    --MSize_In,
                                    Size_In)
           begin
         
             mult_by_1  <= '1';
             mult_by_2  <= '0';
             mult_by_4  <= '0';
         
             If (Doing_FLBurst = '1') Then
      
               case Size_In is
                 -- when "1010" =>  -- 32-bit burst request
                 -- 
                 --    mult_by_1  <= '1';
                 -- 
                 when "1011" =>  -- 64-bit burst request
                 
                    mult_by_1  <= '0';
                    mult_by_2  <= '1';
                 
                 when "1100" =>  -- 128-bit burst request
                 
                    mult_by_1  <= '0';
                    mult_by_4  <= '1';
                 
                 when others =>  -- default to 32-bit
                 
                    null;   -- use defaults
               
               end case;
               
             Elsif (Doing_Cacheline = '1') Then
               
               mult_by_1  <= '1';
               
               -- case MSize_In is
               --   when "00" =>  -- 32-bit master/32-bit slave
               --   
               --      mult_by_1  <= '1';
               -- 
               --   when "01" =>  -- 64-bit Master/32-bit slave
               --   
               --      mult_by_1  <= '0';
               --      mult_by_2  <= '1';
               --   
               --   when others =>  -- 128 bit master/32-bit slave
               --   
               --      mult_by_1  <= '0';
               --      mult_by_4  <= '1';
               -- 
               -- end case;
              
             End if;
         
         
           end process GET_MULT_BY_S32; 
        
       
     end generate BLE_32_BIT_SLAVE;
             
               
               
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: BLE_64_BIT_SLAVE
    --
    -- If Generate Description:
    -- Detirmine the Burst Length Expansion factor when the 
    -- Slave width is 64.
    --
    --
    ------------------------------------------------------------
    BLE_64_BIT_SLAVE : if (C_NATIVE_DWIDTH = 64) generate
    
       begin
    
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: CALC_CLINE_DONE_COMP_VALUE_S64
         --
         -- Process Description:
         -- This process is a simple lookup table for generating the 
         -- compare to value for the data beat up-counter during 
         -- Cacheline Operations.
         --
         -- 64-bit Slave can transfer 2 wds per data beat but if
         -- requesting Master is 32-bits, then only 32-bits per
         -- data beat.
         --
         -- Cline_special_case1 is asserted when the resolved dbeat
         -- count is 1 data beat (only possible with 128-bit Master and
         -- 128-bit Slave and 4wrd cacheline)
         -- Cline_special_case12 is asserted when the resolved dbeat
         -- count is 2 data beats 
         -------------------------------------------------------------
         CALC_CLINE_DONE_COMP_VALUE_S64 : process (Size_In) 
                                                   --,MSize_In)
            begin
         
              Cline_special_case1  <= '0';
              Cline_special_case2  <= '0';
              
              case Size_In is
                when "0001" =>  -- Cacheline 4wrds (2 dbeats minimum)
                   
                  almst_done_cline_value <= "0001"; -- special case value
                  Cline_special_case1    <= '0';
                  Cline_special_case2    <= '1';
                  
                  -- If (MSize_In = "00") Then -- 32-bit Master
                  --                           -- requires 4 data beats
                  -- 
                  --   almst_done_cline_value <= "0001"; -- special case value
                  --   Cline_special_case1  <= '0';
                  --   Cline_special_case2  <= '1';
                  --   
                  -- else  -- 64 or 128-bit Master (only 2 data beats)
                  -- 
                  --   --almst_done_cline_value <= "0000";
                  --   almst_done_cline_value <= "0000";
                  --   Cline_special_case1    <= '0';
                  --   Cline_special_case2    <= '1';
                  -- 
                  -- 
                  -- End if;
                    
                when "0010" =>  -- Cacheline 8wrds (4 dbeats)
                    almst_done_cline_value <= "0001";
                when "0011" =>  -- Cacheline 16wrds (8 dbeats)
                    almst_done_cline_value <= "0101";
                when others =>
                    almst_done_cline_value <= "0000";
              end case;
               
            end process CALC_CLINE_DONE_COMP_VALUE_S64; 
         
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: GET_MULT_BY_S64
         --
         -- Process Description:
         -- Detirmine the Burst Length Expansion factor when the 
         -- Slave width is 64.
         --
         -------------------------------------------------------------
         GET_MULT_BY_S64 : process (Doing_FLBurst,
                                    Doing_Cacheline,
                                    MSize_In,
                                    Size_In)
           begin
         
             mult_by_1  <= '1';
             mult_by_2  <= '0';
             mult_by_4  <= '0';
         
             If (Doing_FLBurst = '1') Then
      
               case Size_In is
                 when "1100" =>  -- 128-bit burst request
                 
                    mult_by_1  <= '0';
                    mult_by_2  <= '1';
             
                 -- when "1010" =>  -- 32-bit burst request
                 -- 
                 --    mult_by_1  <= '1';
                 -- 
                 -- when "1011" =>  -- 64-bit burst request
                 -- 
                 --    mult_by_1  <= '1';
                 
                 when others =>  -- default to 32 or 64 bit burst request
                 
                    null;  -- use defaults
                    -- mult_by_1  <= '0';
                    -- mult_by_2  <= '1';
               
               end case;
            
             Elsif (Doing_Cacheline = '1') Then
            
               case MSize_In is
                 when "00" =>  -- 32-bit master/64-bit Slave
                 
                    mult_by_1  <= '0';
                    mult_by_2  <= '1';
             
                 -- when "01" =>  -- 64-bit Master/64-bit Slave
                 -- 
                 --    mult_by_1  <= '1';
                 
                 when others =>  -- 128 bit master/64-bit Slave
                 
                    null;  -- use defaults
                    -- mult_by_1  <= '1';
               
               end case;
              
             End if;
         
         
           end process GET_MULT_BY_S64; 
         
         
        
         
       end generate BLE_64_BIT_SLAVE;
               
               
               
               
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: BLE_128_BIT_SLAVE
    --
    -- If Generate Description:
    -- Detirmine the Burst Length Expansion factor when the 
    -- Slave width is 128. Will always be 1 in this case.
    --
    --
    ------------------------------------------------------------
    BLE_128_BIT_SLAVE : if (C_NATIVE_DWIDTH = 128) generate
    
       begin
    
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: CALC_CLINE_DONE_COMP_VALUE_S128
         --
         -- Process Description:
         -- This process is a simple lookup table for generating the 
         -- compare to value for the data beat up-counter during 
         -- Cacheline Operations.
         --
         -- 128-bit Slave can transfer 4 wds per data beat
         -------------------------------------------------------------
         CALC_CLINE_DONE_COMP_VALUE_S128 : process (Size_In)
            begin
         
              Cline_special_case1  <= '0';
              Cline_special_case2  <= '0';
              
              case Size_In is
                when "0001" =>  -- Cacheline 4wrds (1 dbeat minimum)
                    Cline_special_case1    <= '1';
                    almst_done_cline_value <= "0000";
                when "0010" =>  -- Cacheline 8wrds (2 dbeats minimum)
                    Cline_special_case2    <= '1';
                    --almst_done_cline_value <= "0000";
                    almst_done_cline_value <= "0001"; -- special case
                when "0011" =>  -- Cacheline 16wrds (4 dbeats minimum)
                    almst_done_cline_value <= "0001";
                when others =>
                    almst_done_cline_value <= "0000";
              end case;
               
            end process CALC_CLINE_DONE_COMP_VALUE_S128; 
         
        
        
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: GET_MULT_BY_S128
         --
         -- Process Description:
         -- Detirmine the Burst Length Expansion factor when the 
         -- Slave width is 128.
         --
         -------------------------------------------------------------
         GET_MULT_BY_S128 : process (Doing_Cacheline,
                                     MSize_In)
           begin
         
             mult_by_1  <= '1';
             mult_by_2  <= '0';
             mult_by_4  <= '0';
         
             if (Doing_Cacheline = '1') Then
            
               case MSize_In is
                 when "00" =>  -- 32-bit master/128-bit Slave
                 
                    mult_by_1  <= '0';
                    mult_by_4  <= '1';          
             
                 when "01" =>  -- 64-bit Master/128-bit Slave
                 
                    mult_by_1  <= '0';
                    mult_by_2  <= '1';
                 
                 when others =>  -- 128 bit master/128-bit Slave
                 
                    null;  -- use defaults
                    -- mult_by_1  <= '1';
               
               end case;
            
            End if;
         
         
           end process GET_MULT_BY_S128; 
         
         
         
       end generate BLE_128_BIT_SLAVE;
               
               
               
               
               
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: MULT_CNTR
    --
    -- Process Description:
    -- This process implements a shift register that is set at  
    -- command start to the appropriate multipy value for 
    -- multi-data beat commands.
    -- This is needed to support Burst Length Expansion, a 
    -- requirement when the requesting Master is wider than the 
    -- Slave's native data width.
    -- 
    -------------------------------------------------------------
    MULT_CNTR : process (bus_clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst = '1') then
             mult_cnt_sreg <= (others => '0');
           
           elsif (Req_Init = '1') then
             
             mult_cnt_sreg(0) <= mult_by_1;
             mult_cnt_sreg(1) <= mult_by_2;
             mult_cnt_sreg(2) <= '0';
             mult_cnt_sreg(3) <= mult_by_4;              
           
           Elsif (dbeat_cnt_en   = '1' and
                  dbeat_cnt_done = '1') Then
           
           -- shift the set pulse down shift register
             mult_cnt_sreg(0) <= mult_cnt_sreg(1);
             mult_cnt_sreg(1) <= mult_cnt_sreg(2);
             mult_cnt_sreg(2) <= mult_cnt_sreg(3);
             mult_cnt_sreg(3) <= '0';              
                       
           else
             null;  -- hold current state
           end if; 
         end if;       
       end process MULT_CNTR; 
 
 
 
 
   
end implementation;
