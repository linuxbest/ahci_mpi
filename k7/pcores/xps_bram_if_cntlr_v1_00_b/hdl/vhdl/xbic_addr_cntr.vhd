-------------------------------------------------------------------------------
-- $Id: xbic_addr_cntr.vhd,v 1.2.2.1 2008/12/16 22:23:17 dougt Exp $
-------------------------------------------------------------------------------
-- xbic_addr_cntr.vhd
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
-- Filename:        xbic_addr_cntr.vhd
--
-- Description:     
--  Address Counter for XPS BRAM IF Cntlr.                
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
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.2.2.1 $
-- Date:            $5/21/2007$
--
-- History:
--   DET   5/21/2007       Initial Version
--                      
--
--     DET     6/8/2007     jm.10
-- ~~~~~~
--     - Added additional filter logic to cover bugs found with 128-bit master
--       and 64-bit Native DWidth case.
-- ^^^^^^
--
--     DET     8/25/2008     v1_00_b
-- ~~~~~~
--     - Updated library references to v1_00_b
-- ^^^^^^
-- 
--     DET     9/9/2008     v1_00_b for EDK 11.1 release
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



library xps_bram_if_cntlr_v1_00_b;
use xps_bram_if_cntlr_v1_00_b.xbic_be_reset_gen;




library unisim; -- Required for Xilinx primitives
use unisim.all;  


-------------------------------------------------------------------------------

entity xbic_addr_cntr is
  generic (
    C_SMALLEST_MASTER    : integer range 32 to 128 := 32;
    C_CACHLINE_ADDR_MODE : Integer range 0 to 1 := 0;
    C_ADDR_CNTR_WIDTH    : Integer := 32;
    C_NATIVE_DWIDTH      : Integer range 32 to 128 := 64;
    C_PLB_AWIDTH         : Integer range 32 to 36  := 32    
    );
  port (
   -- Clock and Reset
    Bus_Rst         : In  std_logic;
    Bus_clk         : In  std_logic;
  
   -- Inputs from Slave Attachment
    Mstr_Size_in    : In  std_logic_vector(0 to 1);
    PLB_Size_in     : In  std_logic_vector(0 to 3);
    PLB_RNW_in      : In  std_logic;
   
    Bus_Addr_in     : in  std_logic_vector(0 to C_PLB_AWIDTH-1);
    Addr_Load       : In  std_logic;
    Addr_Cnt_en     : In  std_logic;
    Qualifiers_Load : In  std_logic;
    
    BE_in           : In  Std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);
    --Reset_BE        : in  std_logic_vector(0 to (C_NATIVE_DWIDTH/32) - 1);    

  -- BE Outputs
    BE_out          : Out Std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);                                                                
                                                               
  -- IPIF & IP address bus source (AMUX output)
    Address_Out     : out std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1)

    );

end entity xbic_addr_cntr;


architecture implementation of xbic_addr_cntr is

  -- Constants
   Constant CLINE_CNTR_WIDTH : integer := 5;
   Constant CLINE_GEN_MUX_WIDTH : integer := 4;
   Constant CLINE_8_ADDR_MUX_BIT_OFFSET: integer := 5;
   
   
  -- Types
  -- Signals
   signal single               : std_logic;
   signal flburst              : std_logic;
   signal cacheln_4            : std_logic;
   signal cacheln_8            : std_logic;
   signal words                : std_logic;
   signal dblwrds              : std_logic;
   signal qwdwrds              : std_logic; 
   signal master_32            : std_logic;   
   signal master_64            : std_logic;   
   signal master_128           : std_logic;  
   signal flbrst_inc_value     : std_logic_vector(0 to 4);
   signal cline_inc_value      : std_logic_vector(0 to 4);
   
   -- Sample and hold signals
   signal single_s_h           : std_logic;
   signal flburst_s_h          : std_logic;
   signal cacheln_4_s_h        : std_logic;
   signal cacheln_8_s_h        : std_logic;
   signal words_s_h            : std_logic;
   signal dblwrds_s_h          : std_logic;
   signal qwdwrds_s_h          : std_logic; 
   signal msize_s_h            : std_logic_vector(0 to 1);
   signal rnw_s_h              : std_logic;
   signal master_32_s_h        : std_logic;   
   signal master_64_s_h        : std_logic;   
   signal master_128_s_h       : std_logic;  
   signal flbrst_inc_value_s_h : std_logic_vector(0 to 4);
   signal cline_inc_value_s_h  : std_logic_vector(0 to 4);
   

   
   Signal sig_cline_slice_cntr     : unsigned(0 to CLINE_CNTR_WIDTH-1);
   Signal sig_addr_cntr            : unsigned(0 to C_ADDR_CNTR_WIDTH-1);
   
   signal sig_addr_inc_value       : unsigned(0 to C_ADDR_CNTR_WIDTH-1);
   signal sig_cline_inc_value      : unsigned(0 to CLINE_CNTR_WIDTH-1);
   signal sig_cline_ld_value       : unsigned(0 to CLINE_CNTR_WIDTH-1);
   signal sig_cline_addr_slice_slv : std_logic_vector(0 to CLINE_CNTR_WIDTH-1);
   signal sig_cline_addr_ld_mask_final   : std_logic_vector(0 to CLINE_CNTR_WIDTH-1);
   signal sig_cline_addr_ld_mask         : std_logic_vector(0 to CLINE_CNTR_WIDTH-1);
   --signal sig_cline_addr_slice           : std_logic_vector(0 to CLINE_CNTR_WIDTH-1);


   signal sig_ld_addr_cntr         : std_logic;
   signal sig_incr_addr_cntr       : std_logic;
   
   signal sig_ld_cline_addr_cntr   : std_logic;
   signal sig_incr_cline_addr_cntr : std_logic;
   
   signal sig_address_out          : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
   
   signal sig_s_h_qualifiers       : std_logic;
   Signal sig_addr_4_3_s_h         : std_logic_vector(0 to 1);
   Signal sig_singles_be_mask      : std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);
   signal sig_be_in_s_h            : std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);
   signal sig_masked_be            : std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);
   --signal sig_burst_be_s_h         : std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);
   signal sig_cline_burst_be       : std_logic_vector(0 to (C_NATIVE_DWIDTH/8)-1);

            
            
            
begin --(architecture implementation)

   
   
   ------------------------------------------------------------------
   -- Output BE assignment logic
   --
   --
   ------------------------------------------------------------------
  
       
    
   --  BE_out <= sig_burst_be_s_h
   --    when single_s_h = '1'
   --    Else (others => '1')
   --    When (cacheln_4_s_h = '1' or
   --          cacheln_8_s_h = '1')
   --    Else sig_burst_be;

   
   
   -- Select the appropriate BE source for the transfer case                    
   BE_out <= (others => '1')  -- set to all ones
     when rnw_s_h = '1'       -- for all reads
     Else sig_masked_be
     When single_s_h = '1'    -- single beat write
     Else sig_cline_burst_be; -- bursts and cacheline writes


   
    sig_masked_be <= sig_be_in_s_h and sig_singles_be_mask;
    
    
    
    
 
    master_32   <= not(Mstr_Size_in(0)) and
                   not(Mstr_Size_in(1));
              
   
    master_64   <= not(Mstr_Size_in(0)) and
                       Mstr_Size_in(1);   
 
--GAB    master_128  <= Mstr_Size_in(0) and
--GAB                   Mstr_Size_in(1);
    master_128  <= Mstr_Size_in(0) and
                   not(Mstr_Size_in(1));
 
 
  
    
    
   ------------------------------------------------------------------
   -- Output address assignment logic
   --
   -- The Lower 4 LSBs of the address are muxed between the main address
   -- counter and the 4 lsbs of the Cacheline address counter during
   -- any cachline operation.
   --
   -- The 5th lsb bit is muxed between the Main address counter and
   -- the cachline mux based on cacheline 8wd execution
   ------------------------------------------------------------------
  
     Address_Out <=  sig_address_out;
    
     
     
    
    
     -- rip the main address counter bits that are used for all transfers
     sig_address_out(0 to C_ADDR_CNTR_WIDTH-(CLINE_GEN_MUX_WIDTH+2)) <=
        STD_LOGIC_VECTOR(sig_addr_cntr(0 to C_ADDR_CNTR_WIDTH-
                                      (CLINE_GEN_MUX_WIDTH+2)));
     
     -- Mux the address bit that is needed for only cachline 8
     sig_address_out(C_ADDR_CNTR_WIDTH-CLINE_8_ADDR_MUX_BIT_OFFSET) 
             <= STD_LOGIC(sig_cline_slice_cntr(CLINE_CNTR_WIDTH-CLINE_8_ADDR_MUX_BIT_OFFSET))
       When (cacheln_8_s_h = '1')
       Else STD_LOGIC(sig_addr_cntr(C_ADDR_CNTR_WIDTH-CLINE_8_ADDR_MUX_BIT_OFFSET));
    
     -- Mux the address bits that are needed for cachline 8 and cacheline 4
     sig_address_out(C_ADDR_CNTR_WIDTH-CLINE_GEN_MUX_WIDTH to 
                      C_ADDR_CNTR_WIDTH-1) 
           <= STD_LOGIC_VECTOR(sig_cline_slice_cntr(CLINE_CNTR_WIDTH-CLINE_GEN_MUX_WIDTH to CLINE_CNTR_WIDTH-1))
       When (cacheln_4_s_h = '1' or
             cacheln_8_s_h = '1')
       Else STD_LOGIC_VECTOR(sig_addr_cntr(C_ADDR_CNTR_WIDTH-CLINE_GEN_MUX_WIDTH to 
                                           C_ADDR_CNTR_WIDTH-1));
     
   
   
   sig_s_h_qualifiers <= Qualifiers_Load;
   
   
   

   ------------------------------------------------------------------
   -- Use size bits to determine transfer type
   --
   ------------------------------------------------------------------
    
    -- PLB_Size = "0000"
    single        <=  not(PLB_Size_in(0)) and
                      not(PLB_Size_in(1)) and
                      not(PLB_Size_in(2)) and
                      not(PLB_Size_in(3));        
                      
                      
    -- PLB_Size = "0X00"
    flburst        <= PLB_Size_in(0);        
                      
                      
    -- PLB_Size = "1XXX"
    cacheln_4     <=  not(PLB_Size_in(0)) and 
                      not(PLB_Size_in(2)) and 
                      PLB_Size_in(3); 
    
    -- PLB_Size = "0X10"
    cacheln_8     <=  not(PLB_Size_in(0)) and 
                      PLB_Size_in(2)      and 
                      not(PLB_Size_in(3)); 
    
   -- not supported
   --   -- PLB_Size = "0X11"
   --   cacheln_16    <=  not(PLB_Size_in(0)) and
   --                     PLB_Size_in(2)      and
   --                     not(PLB_Size_in(3);    
                      

   ------------------------------------------------------------------
   -- Case for BRAM Native DWidth of 32 bits
   --
   ------------------------------------------------------------------
   GEN_NATIVE_WIDTH32 : if (C_NATIVE_DWIDTH = 32) generate    
       -- PLB_Size = "1010"
       -- words      <=  PLB_Size_in(0)      and
       --                not(PLB_Size_in(1)) and
       --                PLB_Size_in(2)      and
       --                not(PLB_Size_in(3));  
       
       -- always 32-bit transfer for Burst and cachelines
       words      <=  '1'; 
    
       -- not supported
       dblwrds    <=  '0';   
    
       -- not supported
       qwdwrds    <=  '0';   
       
       -- always 4 bytes/dbeat
       flbrst_inc_value <= "00100";   
       
       -- always 4 bytes/dbeat
       cline_inc_value <= "00100";   
    
       sig_cline_addr_ld_mask <= "11100";
       
       -- Burst and Cline BE's will always be set 
       sig_cline_burst_be <= (others => '1');
       
       -- No masking required
       sig_singles_be_mask <= (others => '1');
       
       
   end generate GEN_NATIVE_WIDTH32;


   ------------------------------------------------------------------
   -- Case for BRAM Native DWidth of 64 bits
   --
   ------------------------------------------------------------------
   GEN_NATIVE_WIDTH64 : if (C_NATIVE_DWIDTH = 64) generate    
       -- PLB_Size = "1010"
       -- words      <=  PLB_Size_in(0)      and
       --                not(PLB_Size_in(1)) and
       --                PLB_Size_in(2)      and
       --                not(PLB_Size_in(3));   
    
         words      <=  '1'
          When  (PLB_Size_in = "1010" or
                (master_32   = '1' and
                (cacheln_4   = '1' or
                 cacheln_8   = '1')))
          Else '0';
       
       
       -- -- PLB_Size = "1011"
       -- dblwrds    <=  PLB_Size_in(0)      and
       --                not(PLB_Size_in(1)) and
       --                PLB_Size_in(2)      and
       --                PLB_Size_in(3);   
    
       dblwrds    <=  '1'
          When  ((PLB_Size_in = "1011"  or
                  PLB_Size_in = "1100") or
                ((master_64   = '1' or
                  master_128  = '1') and
                (cacheln_4   = '1' or
                 cacheln_8   = '1')))
          Else '0';
       
       
       -- not supported
       qwdwrds    <=  '0';   
       
       
       
       -- either 4 or 8 bytes/dbeat
       flbrst_inc_value <= "01000" -- 8
         when dblwrds = '1'
         else "00100";             -- 4
       
       -- either 4 or 8 bytes/dbeat
       cline_inc_value  <= "01000" -- 8
         when (master_64   = '1' or -- 64-bit master or
               master_128  = '1')   -- 128-bit master 
         else "00100";              -- else 32-bit master
    
       sig_cline_addr_ld_mask <= "11100"
         When master_32   = '1' -- 32-bit master limited
         Else "11000";            -- 64-bit xfer 
    
    
    
    
    
      -------------------------------------------------------------
      -- Combinational Process
      --
      -- Label: GEN_BURST_CLINE_BE_N64
      --
      -- Process Description:
      -- This process generates the 8 BE bits needed during fixed
      -- length burst writes and Cacheline writes. Since the 
      -- Native DWIDTH is 64 for this IfGen, then only Word transfers
      -- require special handling.
      --
      -------------------------------------------------------------
      GEN_BURST_CLINE_BE_N64 : process (words_s_h,
                                        --dblwrds_s_h,
                                        --qwdwrds_s_h,
                                        sig_address_out)
         begin
      
           if (words_s_h = '1') then
             
             if (sig_address_out(C_ADDR_CNTR_WIDTH-3) = '1') then
             
                sig_cline_burst_be <= "00001111";
             
             else
             
                sig_cline_burst_be <= "11110000";
             
             end if;
             
           else  -- dwrds or quad words
             sig_cline_burst_be <= (others => '1');
           end if;
   
      end process GEN_BURST_CLINE_BE_N64; 
   
      
      
      ----------------------------------------------------------------------
      -- I_BE_MASK_GEN_64:
      -- Singles BE Mask Generation Logic
      -- This special logic is needed for the case when a Master that is 
      -- narrower than the BRAM Native Dwidth is doing a single data beat 
      -- write.
      --
      -----------------------------------------------------------------------
      I_BE_MASK_GEN_64 : entity xps_bram_if_cntlr_v1_00_b.xbic_be_reset_gen
        generic map (
          C_NATIVE_DWIDTH  =>   C_NATIVE_DWIDTH  ,  
          C_SMALLEST       =>   C_SMALLEST_MASTER   
        )
        port map (
          Addr         =>   sig_addr_4_3_s_h ,      
          MSize        =>   msize_s_h        ,      
                         
          BE_Sngl_Mask =>   sig_singles_be_mask     
        );
        
       
    
    
    
   end generate GEN_NATIVE_WIDTH64;


      
   ------------------------------------------------------------------
   -- Case for BRAM Native DWidth of 128 bits
   --
   ------------------------------------------------------------------
   GEN_NATIVE_WIDTH128 : if (C_NATIVE_DWIDTH = 128) generate    
    
      signal sig_addr_bits_128  : std_logic_vector(0 to 1);
    
    
     begin
      
       -- -- PLB_Size = "1010"
       -- words      <=  PLB_Size_in(0)      and
       --                not(PLB_Size_in(1)) and
       --                PLB_Size_in(2)      and
       --                not(PLB_Size_in(3));   
    
         words      <=  '1'
          When  (PLB_Size_in = "1010" or
                (master_32   = '1' and
                (cacheln_4   = '1' or
                 cacheln_8   = '1')))
          Else '0';
       
       
       -- -- PLB_Size = "1011"
       -- dblwrds    <=  PLB_Size_in(0)      and
       --                not(PLB_Size_in(1)) and
       --                PLB_Size_in(2)      and
       --                PLB_Size_in(3);   
    
       dblwrds    <=  '1'
          When  (PLB_Size_in = "1011" or
                (master_64   = '1' and
                (cacheln_4   = '1' or
                 cacheln_8   = '1')))
          Else '0';
       
       
       -- -- PLB_Size = "1100"
       -- qwdwrds    <=  PLB_Size_in(0)      and
       --                PLB_Size_in(1)      and
       --                not(PLB_Size_in(2)) and
       --                not(PLB_Size_in(3)); 
       
       qwdwrds    <=   '1'
          When  (PLB_Size_in = "1100" or
                (master_128  = '1' and
                (cacheln_4   = '1' or
                 cacheln_8   = '1')))
          Else '0'; 
       
                        
                                            
       -- either 4, 8, or 16 bytes/dbeat
       flbrst_inc_value <= "10000" -- 16
         When qwdwrds = '1'
         Else  "01000"             -- 8
         when dblwrds = '1'
         else "00100";             -- 4
       
                                            
                                            
       -- either 4, 8, or 16 bytes/dbeat     
       
       cline_inc_value  <= "10000" -- 16 bytes/dbeat
         When master_128  = '1'    -- 128-bit master
         Else  "01000"             -- 8 bytes/dbeat
         when master_64   = '1'    -- 64-bit master
         else "00100";             -- 4 bytes/dbeat
    
       sig_cline_addr_ld_mask <= "10000" -- 16 bytes/dbeat
         When master_128  = '1'  -- 128-bit master
         Else  "11000"           -- 8 bytes/dbeat
         when master_64   = '1'  -- 64-bit master
         else "11100";           -- 32-bit master
    
      
      
      
      -------------------------------------------------------------
      -- Combinational Process
      --
      -- Label: GEN_BURST_CLINE_BE_N128
      --
      -- Process Description:
      -- This process generates the 16 BE bits needed during fixed
      -- length burst writes and Cacheline writes. Since the 
      -- Native DWIDTH is 128 for this IfGen, then Word and Dblwrd
      -- transfers require special handling based on address.
      -- 
      --
      -------------------------------------------------------------
      GEN_BURST_CLINE_BE_N128 : process (words_s_h,
                                         dblwrds_s_h,
                                         --qwdwrds_s_h,
                                         sig_address_out,
                                         sig_addr_bits_128)
         
         begin
      
           sig_addr_bits_128 <= sig_address_out(C_ADDR_CNTR_WIDTH-4 to 
                                                C_ADDR_CNTR_WIDTH-3);
           
           
           if (words_s_h = '1') then
             
             case sig_addr_bits_128 is
               when "01" =>
                   sig_cline_burst_be <= "0000111100000000";
               when "10" =>
                   sig_cline_burst_be <= "0000000011110000";
               when "11" =>
                   sig_cline_burst_be <= "0000000000001111";
               when others =>
                   sig_cline_burst_be <= "1111000000000000";
             end case;
             
          Elsif (dblwrds_s_h = '1') Then
             
             if (sig_address_out(C_ADDR_CNTR_WIDTH-4) = '1') then
                sig_cline_burst_be <= "0000000011111111";
             else
                sig_cline_burst_be <= "1111111100000000";
             end if;
             
           else  -- quad words
             sig_cline_burst_be <= (others => '1');
           end if;
   
      end process GEN_BURST_CLINE_BE_N128; 
   
     
     
      ----------------------------------------------------------------------
      -- I_BE_MASK_GEN_128:
      -- Singles BE Mask Generation Logic
      -- This special logic is needed for the case when a Master that is 
      -- narrower than the BRAM Native Dwidth is doing a single data beat 
      -- write.
      --
      -----------------------------------------------------------------------
      I_BE_MASK_GEN_128 : entity xps_bram_if_cntlr_v1_00_b.xbic_be_reset_gen
        generic map (
          C_NATIVE_DWIDTH  =>   C_NATIVE_DWIDTH  ,  
          C_SMALLEST       =>   C_SMALLEST_MASTER   
        )
        port map (
          Addr         =>   sig_addr_4_3_s_h ,      
          MSize        =>   msize_s_h        ,      
                         
          BE_Sngl_Mask =>   sig_singles_be_mask     
        );
        
                                            
   end generate GEN_NATIVE_WIDTH128;
  
  
  
  
  
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: SAMP_HOLD_REG
  --
  -- Process Description:
  -- This process samples and holds the needed qualifiers for
  -- the duration of the transfer data phase.
  --
  -------------------------------------------------------------
  SAMP_HOLD_REG : process (bus_clk)
     begin
       if (Bus_Clk'event and Bus_Clk = '1') then
          if (Bus_Rst = '1') then
            single_s_h           <=  '0';              --  : std_logic;
            flburst_s_h          <=  '0';              --  : std_logic;
            cacheln_4_s_h        <=  '0';              --  : std_logic;
            cacheln_8_s_h        <=  '0';              --  : std_logic;
            words_s_h            <=  '0';              --  : std_logic;
            dblwrds_s_h          <=  '0';              --  : std_logic;
            qwdwrds_s_h          <=  '0';              --  : std_logic; 
            msize_s_h            <=  (others => '0');
            sig_be_in_s_h        <=  (others => '0');
            rnw_s_h              <= '0';
            master_32_s_h        <=  '0';              --  : std_logic;   
            master_64_s_h        <=  '0';              --  : std_logic;   
            master_128_s_h       <=  '0';              --  : std_logic;  
            flbrst_inc_value_s_h <=  (others => '0');  --  : std_logic_vector(0 to 4);
            cline_inc_value_s_h  <=  (others => '0');  --  : std_logic_vector(0 to 4);
            --sig_burst_be_s_h     <=  (others => '0');
            sig_addr_4_3_s_h     <=  (others => '0');
            
          elsif (sig_s_h_qualifiers = '1') then

            single_s_h           <=  single          ;  --  : std_logic;
            flburst_s_h          <=  flburst         ;  --  : std_logic;
            cacheln_4_s_h        <=  cacheln_4       ;  --  : std_logic;
            cacheln_8_s_h        <=  cacheln_8       ;  --  : std_logic;
            words_s_h            <=  words           ;  --  : std_logic;
            dblwrds_s_h          <=  dblwrds         ;  --  : std_logic;
            qwdwrds_s_h          <=  qwdwrds         ;  --  : std_logic; 
            msize_s_h            <=  Mstr_Size_in    ;
            sig_be_in_s_h        <=  BE_in           ;
            rnw_s_h              <=  PLB_RNW_in      ;
            master_32_s_h        <=  master_32       ;  --  : std_logic;   
            master_64_s_h        <=  master_64       ;  --  : std_logic;   
            master_128_s_h       <=  master_128      ;  --  : std_logic;  
            flbrst_inc_value_s_h <=  flbrst_inc_value;  --  : std_logic_vector(0 to 4);
            cline_inc_value_s_h  <=  cline_inc_value ;  --  : std_logic_vector(0 to 4);
            --sig_burst_be_s_h     <=  BE_in           ; 
            sig_addr_4_3_s_h     <=  Bus_Addr_in(C_PLB_AWIDTH-4 to C_PLB_AWIDTH-3);
          
          else
            null;  -- hold current values
          end if; 
       end if;       
     end process SAMP_HOLD_REG; 
  
  
  
  
     
     -----------------------------------------------------------------
     -- Main Address counter logic
     --
     --
     -----------------------------------------------------------------
     
     sig_addr_inc_value(0 to C_ADDR_CNTR_WIDTH-6) 
           <= (others => '0');
           
     sig_addr_inc_value(C_ADDR_CNTR_WIDTH-5 to C_ADDR_CNTR_WIDTH-1) 
           <= UNSIGNED(flbrst_inc_value_s_h);
     
     
     sig_ld_addr_cntr   <=  Addr_Load;
     sig_incr_addr_cntr <=  Addr_Cnt_en and 
                            flburst_s_h;
     
     
     -------------------------------------------------------------
     -- Synchronous Process with Sync Reset
     --
     -- Label: GEN_ADDR_CNTR
     --
     -- Process Description:
     -- This process implements the main address counter.
     --
     -------------------------------------------------------------
     GEN_ADDR_CNTR : process (bus_clk)
        begin
          if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst = '1') then
               
               sig_addr_cntr <= (others => '0');
             
             elsif (sig_ld_addr_cntr = '1') then
               
               sig_addr_cntr <= UNSIGNED(Bus_Addr_in);
             
             Elsif (sig_incr_addr_cntr = '1') Then
             
               sig_addr_cntr <=  sig_addr_cntr + 
                                 sig_addr_inc_value;
             
             else
               null; -- hold current value
             end if; 
          end if;       
        end process GEN_ADDR_CNTR; 
  
  
  
  
     -----------------------------------------------------------------
     -- Cacheline Address counter logic
     --
     --
     -----------------------------------------------------------------
 
 
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: LEGACY_CACHLINE_ADDR_MODE
     --
     -- If Generate Description:
     --   This IfGen implements the legacy starting address mode
     -- for Cacheline operations which is Line word first for 
     -- writes and target word first for reads.
     --
     --
     ------------------------------------------------------------
     LEGACY_CACHLINE_ADDR_MODE : if (C_CACHLINE_ADDR_MODE = 0) generate
     
     -- Local Constants
     -- Local variables
     -- local signals
     -- local components
     
     begin
     
      -- Rip the applicable bits from the input address
      -- for the starting cacheline address 
       sig_cline_addr_slice_slv <= 
               Bus_Addr_in(C_ADDR_CNTR_WIDTH-CLINE_CNTR_WIDTH to 
                           C_ADDR_CNTR_WIDTH-1);
     
       -- -- always zero ls 2 bits of the input address for cachelines 
       --  sig_cline_addr_slice_slv(CLINE_CNTR_WIDTH-2 to 
       --                           CLINE_CNTR_WIDTH-1) <= (others => '0');
     
        sig_cline_addr_ld_mask_final <=  sig_cline_addr_ld_mask;
        
        
     end generate LEGACY_CACHLINE_ADDR_MODE;
     
     
     
      
      
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: LINEAR_CACHLINE_ADDR_MODE
     --
     -- If Generate Description:
     --   This IfGen implements the linear starting address mode
     -- for Cacheline operations which is Line word first for 
     -- both writes and reads.
     --
     ------------------------------------------------------------
     LINEAR_CACHLINE_ADDR_MODE : if (C_CACHLINE_ADDR_MODE = 1) generate
     
     -- constant WORD_ADDR_BIT          : natural := CLINE_CNTR_WIDTH - 3;
     -- constant DBLWORD_ADDR_BIT       : natural := CLINE_CNTR_WIDTH - 4;
     -- constant QUAD_WORD_ADDR_BIT     : natural := CLINE_CNTR_WIDTH - 5;
     --constant OCT_WORD_ADDR_BIT      : natural := C_ADDR_CNTR_WIDTH - 6;
       
     begin
         
         
       -------------------------------------------------------------
       -- REALIGN_CACHELINE_ADDR
       -- This process implements the Cacheline starting address
       -- realignment function.
       -------------------------------------------------------------
       REALIGN_CACHELINE_ADDR : process (Bus_Addr_in,
                                         -- cacheln_8,
                                         cacheln_4)
       
         begin
             
             
          -- -- Rip the applicable bits from the input address
          -- -- for the starting cacheline address 
          --  sig_cline_addr_slice_slv(0 to CLINE_CNTR_WIDTH-3) <= 
          --          Bus_Addr_in(C_ADDR_CNTR_WIDTH-CLINE_CNTR_WIDTH to 
          --                      C_ADDR_CNTR_WIDTH-3);
          -- 
          --  -- always zero ls 2 bits of the input address for cachelines 
          --   sig_cline_addr_slice_slv(CLINE_CNTR_WIDTH-2 to 
          --                            CLINE_CNTR_WIDTH-1) <= (others => '0');
          -- 
          -- 
          --    
          --    -- Clear applicable address bits to align address to the
          --    -- requested cacheline size  
          --    if (cacheln_4 = '1') then -- realign to Cacheline 4
          --        sig_cline_addr_slice_slv(WORD_ADDR_BIT)        <= '0';
          --        sig_cline_addr_slice_slv(DBLWORD_ADDR_BIT)     <= '0';
          --    elsif (cacheln_8 = '1') then -- realign to Cacheline 8
          --        sig_cline_addr_slice_slv(WORD_ADDR_BIT)        <= '0';
          --        sig_cline_addr_slice_slv(DBLWORD_ADDR_BIT)     <= '0';
          --        sig_cline_addr_slice_slv(QUAD_WORD_ADDR_BIT)   <= '0';
          --    -- elsif (cacheln_16 = '1') then -- realign to Cacheline 16 
          --    --     sig_cline_addr_slice_slv(WORD_ADDR_BIT)        <= '0';
          --    --     sig_cline_addr_slice_slv(DBLWORD_ADDR_BIT)     <= '0';
          --    --     sig_cline_addr_slice_slv(QUAD_WORD_ADDR_BIT)   <= '0';
          --    --     sig_cline_addr_slice_slv(OCT_WORD_ADDR_BIT)    <= '0';
          --    else -- not a cacheline op
          --        null; -- do nothing else
          --    end if;
          -- 
        
        
           -- Rip the applicable bits from the input address
           -- for the starting cacheline address 
            sig_cline_addr_slice_slv <= 
                    Bus_Addr_in(C_ADDR_CNTR_WIDTH-CLINE_CNTR_WIDTH to 
                                C_ADDR_CNTR_WIDTH-1);
          
             
             -- Clear applicable address bits to align address to the
             -- requested cacheline size  
             if (cacheln_4 = '1') then -- realign to Cacheline 4
               sig_cline_addr_ld_mask_final <=  "10000";
             else -- realign to cacheline 8
               sig_cline_addr_ld_mask_final <=  "00000";
             end if;
             
             
             
         end process REALIGN_CACHELINE_ADDR;
         
     end generate LINEAR_CACHLINE_ADDR_MODE;
     
     
     
     sig_cline_ld_value  <= UNSIGNED(sig_cline_addr_slice_slv and
                                     sig_cline_addr_ld_mask_final);
     
     sig_cline_inc_value <= UNSIGNED(cline_inc_value_s_h);
           
     
     
     sig_ld_cline_addr_cntr   <=  Addr_Load;
     sig_incr_cline_addr_cntr <=  Addr_Cnt_en and 
                                  (cacheln_4_s_h or
                                   cacheln_8_s_h);
     
     
     -------------------------------------------------------------
     -- Synchronous Process with Sync Reset
     --
     -- Label: GEN_CLINE_ADDR_CNTR
     --
     -- Process Description:
     -- This process implements the main address counter.
     --
     -------------------------------------------------------------
     GEN_CLINE_ADDR_CNTR : process (bus_clk)
        begin
          if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst = '1') then
               
               sig_cline_slice_cntr <= (others => '0');
             
             elsif (sig_ld_cline_addr_cntr = '1') then
               
               sig_cline_slice_cntr <= sig_cline_ld_value;
             
             Elsif (sig_incr_cline_addr_cntr = '1') Then
             
               sig_cline_slice_cntr <=  sig_cline_slice_cntr + 
                                        sig_cline_inc_value;
             
             else
               null; -- hold current value
             end if; 
          end if;       
        end process GEN_CLINE_ADDR_CNTR; 
  
  
  
  
  
  
 
end implementation;
