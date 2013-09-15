-------------------------------------------------------------------------------
-- $Id: xbic_addr_be_support.vhd,v 1.2.2.1 2008/12/16 22:23:17 dougt Exp $
-------------------------------------------------------------------------------
-- xbic_addr_be_support.vhd
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
-- Filename:        xbic_addr_be_support.vhd
--
-- Description:     
--    This VHDL file implements the logic to combine the used portion of the 
-- PLB_UABus with the PLB_ABus to form the actual internal address bus.                 
-- The module also implements the BE Mux that is required when the Slave
-- Native Data Width is less than the PLB data Bus width
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
-- Date:            $2/12/2007$
--
-- History:
--   DET   2/12/2007       Initial Version
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


library unisim; -- Required for Xilinx primitives
use unisim.all;  


-------------------------------------------------------------------------------

entity xbic_addr_be_support is
  generic (
    C_SPLB_DWIDTH : Integer        := 32;
    C_SPLB_AWIDTH : Integer        := 32;
    C_SPLB_NATIVE_DWIDTH : Integer := 32
    );
  port (
    
   -- Inputs  from PLB
    PLB_UABus     : in std_logic_vector(0 to 31);
    PLB_ABus      : in std_logic_vector(0 to 31);
    PLB_BE        : in std_logic_vector(0 to (C_SPLB_DWIDTH/8)-1);
    PLB_Msize     : In std_logic_vector(0 to 1);
    
   -- Outputs  to Internal logic
    Internal_ABus : out std_logic_vector(0 to C_SPLB_AWIDTH-1);
    Internal_BE   : out std_logic_vector(0 to (C_SPLB_NATIVE_DWIDTH/8)-1)
  
    );

end entity xbic_addr_be_support;


architecture implementation of xbic_addr_be_support is




  -- Constants
   Constant UPPER_ADDR_SIZE  : integer := C_SPLB_AWIDTH-32;
    
 
   -- Signals
   signal sig_combined_abus    : std_logic_vector(0 to C_SPLB_AWIDTH-1);
  
  
  

begin --(architecture implementation)

 
 
 

 Internal_ABus <= sig_combined_abus;
 
 
 
 
 
 
 
 ------------------------------------------------------------
 -- If Generate
 --
 -- Label: ADDRESS_EQ_32
 --
 -- If Generate Description:
 --   This IfGen hooks up the PLB_ABus when the
 -- total number of address bits used is equal to 32.
 -- In this case, the PLB_UABus is ignored.
 ------------------------------------------------------------
 ADDRESS_EQ_32 : if (C_SPLB_AWIDTH = 32) generate
    begin
 
      sig_combined_abus <= PLB_ABus;
      
                 
    end generate ADDRESS_EQ_32;

   
      
 ------------------------------------------------------------
 -- If Generate
 --
 -- Label: ADDRESS_GT_32
 --
 -- If Generate Description:
 --   This IfGen combines the used portion of the PLB_UABus 
 -- with the PLB_ABus when the total number of address bits 
 -- used is greater than 32 but less than 64.
 --
 ------------------------------------------------------------
 ADDRESS_GT_32 : if (C_SPLB_AWIDTH > 32 and
                     C_SPLB_AWIDTH < 64) generate
     
    begin
 
     
      -------------------------------------------------------------
      -- Combinational Process
      --
      -- Label: ASSIGN_ADDR
      --
      -- Process Description:
      -- Combine the Upper and Lower address bus values into the
      -- address bus used internally.
      --
      -------------------------------------------------------------
      ASSIGN_ADDR : process (PLB_UABus,
                             PLB_ABus)
         begin
      
         -- Rip the used upper PLB addr bus bits and merge
         -- into the most significant address bits
           sig_combined_abus(0 to UPPER_ADDR_SIZE-1)  <=  
                       PLB_UABus((32-UPPER_ADDR_SIZE) to 31);
                                    
      
         -- Assign least significant addr bus bits   
           sig_combined_abus(C_SPLB_AWIDTH-32 to 
                                C_SPLB_AWIDTH-1)
                   <=  PLB_ABus;
                                                     
         end process ASSIGN_ADDR; 
      
     
    end generate ADDRESS_GT_32;



 ------------------------------------------------------------
 -- If Generate
 --
 -- Label: ADDRESS_EQ_64
 --
 -- If Generate Description:
 --   This IfGen merges the PLB_UABus and the PLB_ABus when 
 -- the total number of address bits used is equal to 64.
 --
 ------------------------------------------------------------
 ADDRESS_EQ_64 : if (C_SPLB_AWIDTH = 64) generate
    begin
 
      sig_combined_abus(0 to 31)  <= PLB_UABus ; 
      sig_combined_abus(32 to 63) <= PLB_ABus  ; 
                
    end generate ADDRESS_EQ_64;


 


------------------------------------------------------------
-- If Generate
--
-- Label: PLB_EQ_SLAVE
--
-- If Generate Description:
--   Connects the PLB Be to the internal BE bus. No muxing
-- required when the PLB and the Slave are the same data width.
--
------------------------------------------------------------
PLB_EQ_SLAVE : if (C_SPLB_DWIDTH = C_SPLB_NATIVE_DWIDTH) generate

   begin

      Internal_BE <= PLB_BE;
      
   end generate PLB_EQ_SLAVE;

 
 
------------------------------------------------------------
-- If Generate
--
-- Label: PLB64_SLAVE32
--
-- If Generate Description:
--   Muxes the PLB BE to the internal BE bus when the PLB
-- data Width is 64 bits and the Slave data width is 32 bits. 
--
------------------------------------------------------------
PLB64_SLAVE32 : if (C_SPLB_DWIDTH        = 64 and
                    C_SPLB_NATIVE_DWIDTH = 32) generate

   begin
      
     Internal_BE <= PLB_BE(4 to 7)
       When PLB_ABus(29) = '1'
       Else PLB_BE(0 to 3);
      
   end generate PLB64_SLAVE32;



------------------------------------------------------------
-- If Generate
--
-- Label: PLB128_SLAVE32
--
-- If Generate Description:
--   Muxes the PLB BE to the internal BE bus when the PLB
-- data Width is 128 bits and the Slave data width is 32 bits. 
--
------------------------------------------------------------
PLB128_SLAVE32 : if (C_SPLB_DWIDTH        = 128 and
                     C_SPLB_NATIVE_DWIDTH = 32) generate

   begin

     Internal_BE <= PLB_BE(12 to 15)
       When PLB_ABus(28 to 29) = "11"
       Else PLB_BE(8 to 11)
       When PLB_ABus(28 to 29) = "10"
       Else PLB_BE(4 to 7)
       When PLB_ABus(28 to 29) = "01"
       Else PLB_BE(0 to 3);
      
   end generate PLB128_SLAVE32;



------------------------------------------------------------
-- If Generate
--
-- Label: PLB128_SLAVE64
--
-- If Generate Description:
--   Muxes the PLB BE to the internal BE bus when the PLB
-- data Width is 128 bits and the Slave data width is 64 bits. 
--
------------------------------------------------------------
PLB128_SLAVE64 : if (C_SPLB_DWIDTH        = 128 and
                     C_SPLB_NATIVE_DWIDTH = 64) generate

   begin

     Internal_BE <= PLB_BE(8 to 15)
       When PLB_ABus(28) = '1'
       Else PLB_BE(0 to 7);
      

   end generate PLB128_SLAVE64;







 


end implementation;
