-------------------------------------------------------------------------------
-- $Id: xbic_slave_attach_burst.vhd,v 1.2.2.1 2008/12/16 22:23:17 dougt Exp $
-------------------------------------------------------------------------------
-- xbic_slave_attach_burst.vhd
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
-- Filename:        xbic_slave_attach_burst.vhd
-- Version:         v1_00_a
-- Description:     Custom PLB slave attachment supporting only PLB single  
--                  beat transfers.
--                  
--
-------------------------------------------------------------------------------
-- Structure:
--
--                 xbic_slave_attach_burst.vhd
--                    |
--                    |- xbic_addr_be_support
--                    |- xbic_addr_decode
--                    |- xbic_be_reset_gen.vhd
--                    |- xbic_addr_reg_cntr_brst_flex.vhd
--                         |-- xbic_flex_addr_cntr.vhd
--                    |- xbic_dbeat_control
--                    |- xbic_data_steer_mirror.vhd
--
-------------------------------------------------------------------------------
-- Author:      D. Thorpe
-- History:
--
--      DET        Feb-9-07
-- ~~~~~~
--      -- Custom Slave Attachment version for the XPS BRAM IF Cntlr 
--      -- Bypassed input address and qualifiers registering to remove
--         one clock of latency during address phase.
--      -- Optimized for PLBV46 Performance op mode.
-- ^^^^^^
--
--     DET     5/1/2007     Update for Jm
-- ~~~~~~
--     - Corrected a bug that caused a spurious Sl_wrBTerm to be generated if
--       Fixed Length Burst Write of 2 data beats was on the PLB but not 
--       addressed to the XPS BRAM IF Cntlr addresss space.
-- ^^^^^^
--
--     DET     5/16/2007     Jm
-- ~~~~~~
--     - Revamped qualifier validation and address decoding to improve Fmax
--       in Spartan devices.
-- ^^^^^^
--
--     DET     6/8/2007     jm.10
-- ~~~~~~
--     - Zeroed out the MSBit of the Sl_rdwdaddr(0:3) bus since 16 word
--       cachelines are not supported.
-- ^^^^^^
--
--     DET     6/13/2007     Jm.10
-- ~~~~~~
--     - More Fmax optimizations.
--     - Had to remove indeterminate burst screening from request validation
--       to meet 99MHz in Spartan
-- ^^^^^^
--
--     DET     6/25/2007     Jm.11
-- ~~~~~~
--     - Added Sl_rearbitrate_i to clear condition of sig_force_wrbterm flop
--       im each of the  32-bit, 64-bit, and 128-bit generates.
-- ^^^^^^
--
--     DET     8/25/2008     v1_00_b
-- ~~~~~~
--     - Updated to proc_common_v3_00_a library reference.
--     - Updated this core's library reference to v1_00_b.
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
--      user defined types:                     "*_type"
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
use ieee.std_logic_unsigned.all;



-- Xilinx Primitive Library
library unisim;
use unisim.vcomponents.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.family_support.all;


library xps_bram_if_cntlr_v1_00_b;
use xps_bram_if_cntlr_v1_00_b.xbic_addr_be_support;
use xps_bram_if_cntlr_v1_00_b.xbic_addr_decode;
use xps_bram_if_cntlr_v1_00_b.xbic_be_reset_gen;
Use xps_bram_if_cntlr_v1_00_b.xbic_addr_cntr;                 -- new for timing debug
Use xps_bram_if_cntlr_v1_00_b.xbic_dbeat_control;
use xps_bram_if_cntlr_v1_00_b.xbic_data_steer_mirror;

-------------------------------------------------------------------------------
entity xbic_slave_attach_burst is
  generic (

    C_ARD_ADDR_RANGE_ARRAY  : SLV64_ARRAY_type :=
       (
         X"0000_0000_7000_0000", -- IP user0 base address
         X"0000_0000_7000_00FF"  -- IP user0 high address
       );

    C_SPLB_NUM_MASTERS       : integer := 4;
    C_SPLB_MID_WIDTH         : integer := 2;
    C_SPLB_P2P               : integer Range 0 to 1 := 0;
    C_SPLB_AWIDTH            : integer := 32;
    C_SPLB_DWIDTH            : Integer := 32;
    C_SPLB_NATIVE_DWIDTH     : integer := 32;
    C_SPLB_SMALLEST_MASTER   : Integer := 32;
    C_CACHLINE_ADDR_MODE     : Integer range 0 to 1 := 0;
    C_FAMILY                 : string  := "virtex4"
    );
  port(
    
    --System signals
    Bus_Rst         : in  std_logic;
    Bus_Clk         : in  std_logic;

    -- PLB Bus signals
    PLB_ABus        : in  std_logic_vector(0 to 31);
    PLB_UABus       : in  std_logic_vector(0 to 31);
    PLB_PAValid     : in  std_logic;
    PLB_masterID    : in  std_logic_vector
                        (0 to C_SPLB_MID_WIDTH - 1);
    PLB_RNW         : in  std_logic;
    PLB_BE          : in  std_logic_vector
                        (0 to (C_SPLB_DWIDTH/8)-1);
    PLB_Msize       : in  std_logic_vector(0 to 1);
    PLB_size        : in  std_logic_vector(0 to 3);
    PLB_type        : in  std_logic_vector(0 to 2);
    PLB_wrDBus      : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst     : in  std_logic;
    PLB_rdBurst     : in  std_logic;
    Sl_SSize        : out std_logic_vector(0 to 1);
    Sl_addrAck      : out std_logic;
    Sl_wait         : out std_logic;
    Sl_rearbitrate  : out std_logic;
    Sl_wrDAck       : out std_logic;
    Sl_wrComp       : out std_logic;
    Sl_wrBTerm      : out std_logic;
    Sl_rdDBus       : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr     : out std_logic_vector(0 to 3);
    Sl_rdDAck       : out std_logic;
    Sl_rdComp       : out std_logic;
    Sl_rdBTerm      : out std_logic;
    Sl_MBusy        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);   
    Sl_MWrErr       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);   

    -- Controls to the IP/IPIF modules
    Bus2Bram_CS     : out std_logic;
    Bus2Bram_WrReq  : out std_logic;
    Bus2Bram_RdReq  : out std_logic;
    Bus2Bram_Addr   : out std_logic_vector (0 to C_SPLB_AWIDTH-1);
    Bus2Bram_BE     : out std_logic_vector (0 to C_SPLB_NATIVE_DWIDTH/8-1);
    Bus2Bram_WrData : out std_logic_vector (0 to C_SPLB_NATIVE_DWIDTH-1);

    -- Inputs from the BRAM interface logic
    Bram2Bus_RdData : in  std_logic_vector (0 to C_SPLB_NATIVE_DWIDTH-1);
    Bram2Bus_WrAck  : in  std_logic;
    Bram2Bus_RdAck  : in  std_logic

   
    );
end entity xbic_slave_attach_burst;

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

architecture implementation of xbic_slave_attach_burst is


-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------

 -- Functions Declarations
   -------------------------------------------------------------------
   -- Function
   --
   -- Function Name: encode_slave_size
   --
   -- Function Description:
   --     This function encodes the Slave Native Data Width into 
   -- a 2-bit field for PLB_Ssize output.
   --
   -------------------------------------------------------------------
   function encode_slave_size(native_dwidth : integer) 
            return std_logic_vector is
   
     variable temp_size : std_logic_vector(0 to 1);
   
   begin
   
     case native_dwidth is
       when 64 =>
         temp_size := "01"; -- 64 bits wide
       when 128 =>
         temp_size := "10"; -- 128 bits wide
       when others =>
         temp_size := "00"; -- 32 bits wide
     end case;
     
     Return(temp_size);
      
   end function encode_slave_size;
     


-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------


-- Fix the Slave Size response to the PLB DBus width
-- note "00" = 32 bits wide
--      "01" = 64 bits wide
--      "10" = 128 bits wide
constant SLAVE_SIZE    : std_logic_vector(0 to 1) :=
                           encode_slave_size(C_SPLB_NATIVE_DWIDTH);
 
 
 
Constant STEER_ADDR_SIZE : integer := 6;


                                    
-------------------------------------------------------------------------------
-- Signal and type Declarations
-------------------------------------------------------------------------------

-- Intermediate Slave Replyut signals (to PLB)
signal sl_addrack_i        : std_logic;
signal sl_wait_i           : std_logic;
signal sl_rearbitrate_i    : std_logic;
signal sl_wrdack_i         : std_logic;
signal sl_wrcomp_i         : std_logic;
signal sl_wrbterm_i        : std_logic;
signal sl_rddbus_i         : std_logic_vector(0 to C_SPLB_DWIDTH-1);
signal sl_rdwdaddr_i       : std_logic_vector(0 to 3);
signal sl_rddack_i         : std_logic;
signal sl_rdcomp_i         : std_logic;
signal sl_rdbterm_i        : std_logic;
signal sl_mbusy_i          : std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

signal bus2ip_cs_i         : std_logic;
signal bus2ip_wrreq_i      : std_logic;
signal bus2ip_rdreq_i      : std_logic;
signal bus2ip_addr_i       : std_logic_vector(0 to C_SPLB_AWIDTH-1);
signal bus2ip_rnw_i        : std_logic;
signal bus2ip_be_i         : std_logic_vector(0 to (C_SPLB_NATIVE_DWIDTH/8)-1);
signal bus2ip_data_i       : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);

signal ip2bus_wrack_i      : std_logic;
signal ip2bus_rdack_i      : std_logic;
signal ip2bus_rddata_i     : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
 
signal valid_plb_type      : boolean := False;
signal valid_plb_size      : Boolean := False;
signal single_transfer     : std_logic;
signal cacheln_transfer    : std_logic;
signal burst_transfer      : std_logic;
signal indeterminate_burst : std_logic;
signal sig_valid_request   : std_logic;
signal sig_good_request    : std_logic;
 
signal sig_internal_be     : std_logic_vector(0 to (C_SPLB_NATIVE_DWIDTH/8)-1);
signal sig_combined_abus   : std_logic_vector(0 to C_SPLB_AWIDTH-1);
signal sig_steer_addr      : std_logic_vector(0 to STEER_ADDR_SIZE-1);
signal sig_steer_addr_reg  : std_logic_vector(0 to STEER_ADDR_SIZE-1);
signal sig_addr_decode_hit : std_logic;

signal sig_clr_addrack     : std_logic;
signal sig_sl_busy         : std_logic;
signal sig_clear_sl_busy   : std_logic;
signal sig_set_sl_busy     : std_logic;
Signal sig_clr_rearbitrate : std_logic;
signal rearb_condition     : std_logic;
signal not_rearb_condition : std_logic;
signal wait_condition      : std_logic;
Signal sig_clr_wait        : std_logic;

signal sig_do_cmd          : std_logic;
signal sig_do_cmd_reg      : std_logic;
signal sig_clr_qualifiers  : std_logic;

signal sig_mst_id               : std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
signal sig_mst_id_int           : integer range 0 to C_SPLB_NUM_MASTERS-1 := 0;
signal sig_rd_dreg              : std_logic_vector(0 to C_SPLB_DWIDTH-1);
signal sig_rd_data_mirror_steer : std_logic_vector(0 to C_SPLB_DWIDTH-1);
signal sig_rd_data_128          : std_logic_vector(0 to 127);

Signal sig_wr_req               : std_logic;
Signal sig_ld_wr_dreg           : std_logic;
signal sig_wr_dreg              : std_logic_vector(0 to 
                                  C_SPLB_NATIVE_DWIDTH-1);

Signal sig_wr_req_reg           : std_logic;
Signal sig_rd_req_reg           : std_logic;

signal sig_clr_rdack            : std_logic;
signal sig_plb_done             : std_logic;

signal sig_xfer_done            : std_logic;
signal sig_xfer_done_dly1       : std_logic;
signal sig_xfer_almost_done     : std_logic;
signal sig_ld_addr_cntr         : std_logic;
signal sig_combined_dack        : std_logic;
-- Signal sig_be_mask              : std_logic_vector(0 to 
--                                   (C_SPLB_NATIVE_DWIDTH/32) - 1);

Signal sig_internal_wrdack        : std_logic;
Signal sig_internal_rddack        : std_logic;
signal sig_clear_rdack_erly1      : std_logic;
Signal sig_internal_rddack_early1 : std_logic;
signal sig_clear_rdack_erly2      : std_logic;
Signal sig_internal_rddack_early2 : std_logic;
signal sig_rdcomp_erly            : std_logic;
signal sig_clr_rdcomp             : std_logic;
signal sig_clear_wrack            : std_logic;
signal sig_clear_rdack            : std_logic;
signal doing_flburst_reg          : std_logic;
signal doing_single_reg           : std_logic;
signal doing_cacheln_reg          : std_logic;
signal sig_force_wrbterm          : std_logic;
signal sig_init_db_cntr           : std_logic;
signal sig_clr_wrreq              : std_logic;
signal sig_clear_wrack_dly1       : std_logic;
--signal sig_cmd_done               : std_logic;
signal sig_clr_rdbterm            : std_logic;
signal sig_set_rdbterm            : std_logic;
signal sig_cline_spec_1dbeat_case : std_logic;





-------------------------------------------------------------------------------
-- begin the architecture logic
-------------------------------------------------------------------------------
begin



------------------------------------------------------------------
-- Misc. Logic Assignments
------------------------------------------------------------------

-- PLB Output port connections
Sl_addrAck          <= sl_addrack_i         ;
Sl_wait             <= sl_wait_i            ;
Sl_rearbitrate      <= sl_rearbitrate_i     ;
Sl_wrDAck           <= sl_wrdack_i          ;
Sl_wrComp           <= sl_wrcomp_i          ;
Sl_wrBTerm          <= sl_wrbterm_i         ; 
Sl_rdDBus           <= sl_rddbus_i          ;
Sl_rdWdAddr         <= sl_rdwdaddr_i        ;
Sl_rdDAck           <= sl_rddack_i          ;
Sl_rdComp           <= sl_rdcomp_i          ;
Sl_rdBTerm          <= sl_rdbterm_i         ;
Sl_MBusy            <= sl_mbusy_i           ;
Sl_MRdErr           <= (others => '0')      ;
Sl_MWrErr           <= (others => '0')      ;

Sl_SSize  <= SLAVE_SIZE
  when (sig_set_sl_busy = '1')
  Else "00";


sl_rddbus_i         <= sig_rd_dreg;  

sl_wrcomp_i         <= sig_xfer_done and
                       sig_wr_req_reg;

sl_wrbterm_i        <= (sig_force_wrbterm and
                        sig_set_sl_busy)  or
                       (doing_flburst_reg and
                        sig_wr_req_reg    and
                        sig_xfer_almost_done);



-- Backend output signals
 Bus2Bram_CS        <= bus2ip_cs_i    ;
 Bus2Bram_WrReq     <= bus2ip_wrreq_i ;
 Bus2Bram_RdReq     <= bus2ip_rdreq_i ;
 Bus2Bram_Addr      <= bus2ip_addr_i  ;
 Bus2Bram_BE        <= bus2ip_be_i    ;
 Bus2Bram_WrData    <= bus2ip_data_i  ;

 -- Backend input signals
 ip2bus_wrack_i     <= Bram2Bus_WrAck  ; 
 ip2bus_rdack_i     <= Bram2Bus_RdAck  ; 
 ip2bus_rddata_i    <= Bram2Bus_RdData ; 

 bus2ip_data_i      <= sig_wr_dreg; 

 bus2ip_rdreq_i     <= sig_rd_req_reg;                              
 
 
 
 
-- Fmax mod to remove address decode from validation path                                  
 --   --sig_do_cmd         <=  (sig_addr_decode_hit and
 
-- Fmax Mod to simplify implimentation  
 --   sig_do_cmd         <=  (sig_good_request and 
 --                          not(sig_sl_busy)) or
 --                          --(sig_addr_decode_hit and
 --                          (sig_good_request and
 --                           sig_clear_sl_busy);

-- Fmax Mod to simplify implimentation  
 -- Maybe this is better for implementation tools and Fmax ?
  sig_do_cmd  <=  sig_good_request and sig_clear_sl_busy
    When  sig_sl_busy = '1'
    Else  sig_good_request;
 
 
 
  
  
  
 sig_mst_id_int <= CONV_INTEGER(sig_mst_id);



 sig_clr_qualifiers <= sig_clear_sl_busy and 
                       not(sig_do_cmd);

 sig_combined_dack <= bus2ip_wrreq_i or
                      sig_internal_rddack_early2;
 
 
 
 
 -- Rearbitrate if 
 --    - another address hit occurs  
 --    - and the slave attach is busy 
 --    - and the current command is not nearing completion
 --rearb_condition   <=   sig_addr_decode_hit  and
 rearb_condition   <=   sig_good_request     and
                        sig_sl_busy          and            
                        not(sig_clear_sl_busy    or
                            sig_xfer_almost_done or
                            sig_xfer_done);


 not_rearb_condition <= not(rearb_condition or 
                            sl_rearbitrate_i);
 
 
 -- Rearbitrate FLOP
  
  sig_clr_rearbitrate <= Bus_Rst or
                         sl_rearbitrate_i;
 
  I_FLOP_REARB : FDRE 
     port map(
       Q     =>  sl_rearbitrate_i      ,        
       C     =>  Bus_clk               ,        
       CE    =>  rearb_condition ,        
       D     =>  '1'                   ,        
       R     =>  sig_clr_rearbitrate            
     );
 
 
  
 -- Wait FLOP
  
--GAB  --wait_condition  <=  sig_addr_decode_hit        
--GAB  wait_condition  <=  sig_good_request        
--GAB                      and sig_sl_busy and
--GAB                      not(sig_clear_sl_busy);
--GAB
--GAB  sig_clr_wait    <= Bus_Rst or
--GAB                     sig_set_sl_busy or
--GAB                     sl_rearbitrate_i;
--GAB
--GAB  I_FLOP_WAIT : FDRE 
--GAB     port map(
--GAB       Q     =>  sl_wait_i       ,  
--GAB       C     =>  Bus_clk         ,  
--GAB       CE    =>  wait_condition  ,  
--GAB       D     =>  '1'             ,  
--GAB       R     =>  sig_clr_wait       
--GAB     );
--GAB TEMP
sl_wait_i <= '0';

 
 
 -- Address Acknowledge Flops (incorporates register duplication)
 
  sig_clr_addrack <=  Bus_Rst or
                      sig_set_sl_busy or
                      (sig_sl_busy and
                      not(sig_clear_sl_busy));
                      
  
    
 
  I_FLOP_ADDRACK : FDRE 
     port map(
       Q     =>  sl_addrack_i   ,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_do_cmd     ,        
       --D     =>  '1'            ,        
       D     =>  not_rearb_condition,        
       R     =>  sig_clr_addrack         
     );
     

   
 
  I_FLOP_SET_SLBUSY : FDRE 
     port map(
       Q     =>  sig_set_sl_busy,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_do_cmd     ,        
       --D     =>  '1'            ,        
       D     =>  not_rearb_condition,        
       R     =>  sig_clr_addrack         
     );
     
 
 
 
  sig_plb_done <=  (sig_xfer_done and 
                    sig_internal_wrdack) or
                   (sig_xfer_done and
                    sig_internal_rddack_early1);
 
  
  I_FLOP_CLR_SL_BUSY : FDRE 
     port map(
       Q     =>  sig_clear_sl_busy,        
       C     =>  Bus_clk          ,        
       CE    =>  sig_plb_done     ,        
       D     =>  '1'              ,        
       R     =>  sig_clear_sl_busy         
     );
     
 
 
 
 
 
 
 
     
 ------------------------------------------------------------
 -- Instance: I_ADDR_BE_SUPRT 
 --
 -- Description:
 -- This instantiates the address and be support module.    
 --
 ------------------------------------------------------------
  I_ADDR_BE_SUPRT : entity xps_bram_if_cntlr_v1_00_b.xbic_addr_be_support
  generic map (
    C_SPLB_DWIDTH        =>  C_SPLB_DWIDTH       ,  
    C_SPLB_AWIDTH        =>  C_SPLB_AWIDTH       ,  
    C_SPLB_NATIVE_DWIDTH =>  C_SPLB_NATIVE_DWIDTH  
    )
  port map (

   -- Inputs  from PLB
    PLB_UABus     =>  PLB_UABus,  
    PLB_ABus      =>  PLB_ABus ,  
    PLB_BE        =>  PLB_BE   ,  
    PLB_Msize     =>  PLB_Msize,  
    
   -- Outputs  to Internal logic
    Internal_ABus =>  sig_combined_abus,  
    Internal_BE   =>  sig_internal_be     
  
    );

    
----------------------------------------------------------------
-- PLB Size Validation
-- This combinatorial process validates the PLB request 
-- attribute PLB_Size that is supported by this slave.
--  
-- Unsupported transfers are:
--   Indeterminate length bursts
--   Fixed length Bursts of byte width
--   Fixed length bursts of half word width
--   Cacheline 16
----------------------------------------------------------------
VALIDATE_SIZE : process (PLB_Size)
    begin
      case PLB_Size is
        -- single data beat transfer
        when "0000" =>   -- one to eight bytes
            valid_plb_size   <= true;
            single_transfer  <= '1';
            cacheln_transfer <= '0';
            burst_transfer   <= '0';

        -- cacheline transfer
        when "0001" |    -- 4 word cache-line
             "0010"  =>  -- 8 word cache-line
       
            valid_plb_size   <= true;
            single_transfer  <= '0';
            cacheln_transfer <= '1';
            burst_transfer   <= '0';
       
        -- burst transfer (fixed length)
        when "1010" |    -- word burst transfer
             "1011" |    -- double word burst transfer                 
             "1100" =>   -- quad word burst transfer                   
       
            valid_plb_size   <= true;
            single_transfer  <= '0';
            cacheln_transfer <= '0';
            burst_transfer   <= '1';

        when others   =>

            valid_plb_size   <= false;
            single_transfer  <= '0';
            cacheln_transfer <= '0';
            burst_transfer   <= '0';

          end case;

        end process VALIDATE_SIZE;

 
 
 
 
-------------------------------------------------------------------------------
-- PLB Size Validation
-- This combinatorial process validates the PLB request attribute PLB_type
-- that is supported by this slave.
-------------------------------------------------------------------------------
VALIDATE_type : process (PLB_type)
    begin
        if(PLB_type="000")then
            valid_plb_type <= true;
        else
            valid_plb_type <= false;
        end if;
    end process VALIDATE_type;


-------------------------------------------------------------------------------
-- Indeterminate Burst
-- This slave attachment does NOT support indeterminate burst.  Cycles which
-- are determined to be indeterminate will not be responded to by this slave.
-- Note that PLBV46 simplificatons require that only BE(0 to 3) be monitored
-- because fixed length burst data beat counts cannot exceed 16.
-------------------------------------------------------------------------------
  VALIDATE_BURST : process (--burst_transfer, 
                            PLB_BE,
                            PLB_Size)
                            --sig_internal_be)
     begin
            
       --if (burst_transfer = '1' and
       if (PLB_Size(0) = '1' and
           --sig_internal_be(0 to 3) = "0000") then  -- indetirminate burst
           PLB_BE(0 to 3) = "0000") then  -- indetirminate burst
         indeterminate_burst <= '1';
       else
         indeterminate_burst <= '0';
       end if;

     end process VALIDATE_BURST;





-------------------------------------------------------------------------------
-- Access Validation
-- This combinatorial process validates the PLB request attributes that are
-- supported by this slave.
-------------------------------------------------------------------------------
VALIDATE_REQUEST : process (PLB_PAvalid,
                            valid_plb_size,
                            valid_plb_type) --,
                            --indeterminate_burst)
    begin
        -- temp DET  if (PLB_PAvalid = '1') and          -- Address Request
        -- temp DET     (valid_plb_size)    and          -- a valid plb_size
        -- temp DET     (valid_plb_type)    and          -- a valid plb type
        -- temp DET     (indeterminate_burst = '0') then -- and a memory xfer
        -- temp DET      
        -- temp DET      sig_valid_request <= '1';
        -- temp DET
        -- temp DET  else
        -- temp DET      
        -- temp DET      sig_valid_request <= '0';
        -- temp DET
        -- temp DET  end if;
        
        if (PLB_PAvalid = '1'  and     -- Address Request
            valid_plb_size     and     -- a valid plb_size
            valid_plb_type) then       -- a valid plb type
            
            sig_valid_request <= '1';
        
        else
            
            sig_valid_request <= '0';
        
        end if;
  end process VALIDATE_REQUEST;



    
    
    
------------------------------------------------------------
-- If Generate
--
-- Label: P2P_MODE_ENABLED
--
-- If Generate Description:
--   P2P Mode enabled so this IfGen removes the Address 
-- Decoding function.
--
--
------------------------------------------------------------
P2P_MODE_ENABLED : if (C_SPLB_P2P = 1) generate

   begin
     
     sig_good_request <= sig_valid_request and 
                         not(indeterminate_burst); 
     
      
    -- Address Decoder Removed in P2P mode  
      --sig_addr_decode_hit <= sig_valid_request;
     
   end generate P2P_MODE_ENABLED;




------------------------------------------------------------
-- If Generate
--
-- Label: SHARED_MODE_ENABLED
--
-- If Generate Description:
--  Shared bus mode so include Address Decoder.
--
--
------------------------------------------------------------
SHARED_MODE_ENABLED : if (C_SPLB_P2P = 0) generate

   begin
     
       
     sig_good_request <= sig_addr_decode_hit and
                         sig_valid_request and 
                         not(indeterminate_burst); 
    
    
      
     -------------------------------------------------------------------
     -- Address Decoder Component Instance
     -- This component decodes the specified base address pair and 
     -- outputs the decode hit indication.
     -------------------------------------------------------------------
     I_ADDR_DECODER : entity xps_bram_if_cntlr_v1_00_b.xbic_addr_decode
         generic map(
             C_SPLB_AWIDTH           =>  C_SPLB_AWIDTH         ,  
             C_SPLB_NATIVE_DWIDTH    =>  C_SPLB_NATIVE_DWIDTH  ,  
             C_ARD_ADDR_RANGE_ARRAY  =>  C_ARD_ADDR_RANGE_ARRAY,                              
             C_FAMILY                =>  C_FAMILY                 
         )   
       port map(
             -- PLB Interface signals
             Address_In          =>  sig_combined_abus,   
             --Address_Valid       =>  sig_valid_request,  
             Address_Valid       =>  PLB_PAValid,  
             -- Decode output signals
             Addr_Match          =>  sig_addr_decode_hit 
              
         );
      
      
     
   end generate SHARED_MODE_ENABLED;





    
 
 
---------------------------------------------------------------------
-- Generate the Slave Busy
-- This process implements the FLOP that indicates the Slave is Busy
-- with a command. The output of the FLOP is used internally.
---------------------------------------------------------------------
GENERATE_SL_BUSY : process (Bus_clk)
    begin
      if (Bus_clk'EVENT and Bus_clk = '1') Then
        if (Bus_Rst         = '1' or 
            sig_clear_sl_busy = '1') then
          sig_sl_busy         <= '0';
        elsif (sig_set_sl_busy = '1') Then
          sig_sl_busy         <= '1';
        else
          null;  -- hold current state
        end if;
      end if;
    end process GENERATE_SL_BUSY;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_SL_MBUSY
  --
  -- Process Description:
  -- This process implements the flops that drive the SL_MBusy
  -- to the PLB. There is one FLOP per Master.
  --
  -------------------------------------------------------------
DO_SL_MBUSY : process(Bus_clk)
    begin
      if (Bus_clk'EVENT and Bus_clk = '1') Then
        for i in 0 to C_SPLB_NUM_MASTERS - 1 loop
          if (Bus_Rst = '1') then
            sl_mbusy_i(i)   <= '0';
          elsif (i=sig_mst_id_int)then
            if (sig_set_sl_busy = '1') Then
              sl_mbusy_i(i)   <= '1';  -- set specific bit for req master
            elsif (sig_clear_sl_busy = '1') Then
              sl_mbusy_i(i)   <= '0';  -- clear specific bit for req master
            end if;
          else
            sl_mbusy_i(i) <= '0';
          end if;
        end loop;
      end if;
    end process DO_SL_MBUSY;

 
  
  
  
  
  
  
  
 
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: REG_XFER_QUALIFIERS
  --
  -- Process Description:
  -- This process implements the register that samples and holds
  -- the command qualifiers
  --
  -------------------------------------------------------------
  REG_XFER_QUALIFIERS : process (bus_clk)
     begin
       if (Bus_Clk'event and Bus_Clk = '1') then
          if (Bus_Rst            = '1' or
              sig_clr_qualifiers = '1') then
           
           bus2ip_cs_i          <=  '0';  
           sig_wr_req_reg       <=  '0';  
           sig_rd_req_reg       <=  '0';  
           sig_mst_id           <=  (others => '0');
           doing_flburst_reg    <= '0';
           doing_single_reg     <= '0';
           doing_cacheln_reg    <= '0';
                  
          elsif (sig_do_cmd = '1') then
           
           bus2ip_cs_i          <=  '1';  
           sig_wr_req_reg       <=  not(PLB_RNW);  
           sig_rd_req_reg       <=  PLB_RNW;  
           sig_mst_id           <=  PLB_masterID;
           doing_flburst_reg    <= burst_transfer;
           doing_single_reg     <= single_transfer;
           doing_cacheln_reg    <= cacheln_transfer;
                  
          else
            null;  -- hold state
          end if; 
       end if;       
     end process REG_XFER_QUALIFIERS; 
 
 
    
   -- -------------------------------------------------------------------------------
   -- -- BE Reset Generator
   -- -- The following entity generates a mask for inhibiting mirrored BE's.  
   -- -- The BE's of smaller masters are mirrored to the upper byte lanes
   -- -- so based on the master's size and  the address presented, all un-needed 
   -- -- BE's are cleared in the address counter at qualifier load time.
   -- -- Otherwise, single data beat write requests from smaller Masters can corrupt 
   -- -- data in wider Slaves as a result of Mirrored BEs being set.
   -- -------------------------------------------------------------------------------
   -- BE_RESET_I : entity xps_bram_if_cntlr_v1_00_b.xbic_be_reset_gen
   --     generic map(
   --         C_DWIDTH     => C_SPLB_NATIVE_DWIDTH,
   --         C_AWIDTH     => C_SPLB_AWIDTH,
   --         C_SMALLEST   => C_SPLB_SMALLEST_MASTER
   --     )
   --     port map(
   --        Addr             => sig_combined_abus,
   --        MSize            => PLB_Msize,
   --        
   --        Reset_BE         => sig_be_mask
   --     );
       




    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: REG_DO_CMD
    --
    -- Process Description:
    --
    --
    -------------------------------------------------------------
    REG_DO_CMD : process (bus_clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Rst = '1' or
                sig_clear_sl_busy = '1') then
              sig_do_cmd_reg <= '0';
            else
              sig_do_cmd_reg <= sig_do_cmd;
            end if; 
         end if;       
       end process REG_DO_CMD; 


-- Fmax Mod to reduce serial timing paths  
    --sig_ld_addr_cntr <= (sig_do_cmd and 
    --                     not(sig_set_sl_busy or sig_sl_busy))  or
    --                    (sig_do_cmd and sig_clear_sl_busy);
       
    
-- Fmax Mod to reduce serial timing paths  
  sig_ld_addr_cntr <= PLB_PAValid and sig_clear_sl_busy
    When (sig_sl_busy = '1')
    Else (PLB_PAValid and
          not(sig_set_sl_busy));
   
   
   
      
   --   -- Address Counter Clr
   --    sig_cmd_done <=  (sig_xfer_done_dly1 and 
   --                      bus2ip_wrreq_i) or
   --                   -- (sig_xfer_almost_done and 
   --                   --  sig_internal_wrdack) or
   --                   (sig_xfer_done and
   --                    sig_internal_rddack_early1);

   
   
   
    
       
   ------------------------------------------------------------
   -- Instance: I_ADDR_CNTR 
   --
   -- Description:
   -- This instance incorporates the Address counter that is needed
   -- during Burst and Cacheline transfers    
   --
   ------------------------------------------------------------
    I_ADDR_CNTR : entity xps_bram_if_cntlr_v1_00_b.xbic_addr_cntr
    generic map (
      C_SMALLEST_MASTER    =>  C_SPLB_SMALLEST_MASTER,
      C_CACHLINE_ADDR_MODE =>  C_CACHLINE_ADDR_MODE,  
      C_ADDR_CNTR_WIDTH    =>  C_SPLB_AWIDTH       ,
      C_NATIVE_DWIDTH      =>  C_SPLB_NATIVE_DWIDTH,
      C_PLB_AWIDTH         =>  C_SPLB_AWIDTH       
      )
    port map (
     -- Clock and Reset
      Bus_Rst           =>  Bus_Rst,  -- : In  std_logic;
      Bus_clk           =>  Bus_Clk,  -- : In  std_logic;
    
    -- Inputs from Slave Attachment
      Mstr_Size_in      => PLB_MSize ,
      PLB_Size_in       => PLB_Size  ,
      PLB_RNW_in        => PLB_RNW   ,
                      
      Bus_Addr_in       => sig_combined_abus  ,
      Addr_Load         => sig_ld_addr_cntr   ,
      Addr_Cnt_en       => sig_combined_dack  ,
      Qualifiers_Load   => sig_ld_addr_cntr   ,
                      
      BE_in             => sig_internal_be    ,
      --Reset_BE          => sig_be_mask        ,
                      
     -- BE Outputs
      BE_out            => bus2ip_be_i        ,
      
     -- IPIF & IP address bus source (AMUX output)
      Address_Out      => bus2ip_addr_i
      
      );
  
    
  
--    ------------------------------------------------------------
--    -- Instance: I_ADDR_CNTR 
--    --
--    -- Description:
--    -- This instance incorporates the Address counter that is needed
--    -- during Burst and Cacheline transfers    
--    --
--    ------------------------------------------------------------
--     I_ADDR_CNTR : entity xps_bram_if_cntlr_v1_00_b.xbic_addr_reg_cntr_brst_flex
--     generic map (
--       C_CACHLINE_ADDR_MODE =>  C_CACHLINE_ADDR_MODE,  -- : Integer range 0 to 1 := 0;
--       --C_SPLB_P2P           =>  C_SPLB_P2P          ,  -- : integer range 0 to 1 := 0;
--       C_SPLB_P2P           =>  1                   ,  -- set to 1 to reduce address load latency
--       C_NUM_ADDR_BITS      =>  C_SPLB_AWIDTH       ,  -- : Integer := 32;   -- bits
--       C_PLB_DWIDTH         =>  C_SPLB_NATIVE_DWIDTH   -- : Integer := 64    -- bits
--       )
--     port map (
--      -- Clock and Reset
--       Bus_reset          =>  Bus_Rst,  -- : In  std_logic;
--       Bus_clk            =>  Bus_Clk,  -- : In  std_logic;
--     
--     
--      -- Inputs from Slave Attachment
--       Single             =>  single_transfer    ,  -- : In  std_logic;
--       Cacheln            =>  cacheln_transfer   ,  -- : In  std_logic;
--       Burst              =>  burst_transfer     ,  -- : In  std_logic;
--       S_H_Qualifiers     =>  sig_ld_addr_cntr   ,  -- : In  std_logic;
--       Xfer_done          =>  sig_cmd_done       ,  -- : In  std_logic;
--       Addr_Load          =>  sig_ld_addr_cntr   ,  -- : In  std_logic;
--       Addr_Cnt_en        =>  sig_combined_dack  ,  -- : In  std_logic;
--       Addr_Cnt_Size      =>  PLB_Size           ,  -- : In  Std_logic_vector(0 to 3);
--       Addr_Cnt_Size_Erly =>  PLB_Size           ,  -- : in  std_logic_vector(0 to 3);
--       Mstr_SSize         =>  PLB_MSize          ,  -- : in  std_logic_vector(0 to 1);
--       Address_In         =>  sig_combined_abus  ,  -- : in  std_logic_vector(0 to C_NUM_ADDR_BITS-1);
--       BE_in              =>  sig_internal_be    ,  -- : In  Std_logic_vector(0 to (C_PLB_DWIDTH/8)-1);
--       Reset_BE           =>  sig_be_mask        ,  -- : in  std_logic_vector(0 to (C_PLB_DWIDTH/32) - 1);    
--  
--      -- BE Outputs
--       BE_out             =>  bus2ip_be_i        ,  -- : Out Std_logic_vector(0 to (C_PLB_DWIDTH/8)-1);                                                                
--                                                                     
--     -- IPIF & IP address bus source (AMUX output)
--       Address_Out        =>  bus2ip_addr_i        -- : out std_logic_vector(0 to C_NUM_ADDR_BITS-1)
-- 
--       );
  
    
  
  
  
  
 ------------------------------------------------------------
-- Data beat controller logic
  
-- Fmax Mod to reduce serial timing paths  
  -- DET sig_init_db_cntr <=  sig_do_cmd and
  -- DET                      not(sig_set_sl_busy);
                                  
    
-- Fmax Mod to reduce serial timing paths  
  sig_init_db_cntr <= PLB_PAValid and sig_clear_sl_busy
    When (sig_sl_busy = '1')
    Else (PLB_PAValid and
          not(sig_set_sl_busy));
   
   
   
                                  
    
 ------------------------------------------------------------
 -- Instance: I_DBEAT_CONTROL 
 --
 -- Description:
 --      This HDL instantiates the data beat controller that
 -- calculates the data acknowledges for the given request.    
 --  It outputs a done and almost done control flag that is
 --  used to terminate Singles, Cachelines, and Fixed Length 
 -- Bursts at the appropriate timing needed for PLB protcol.
 ------------------------------------------------------------
  I_DBEAT_CONTROL : entity xps_bram_if_cntlr_v1_00_b.xbic_dbeat_control
  generic map (
    -- Generics
    C_NATIVE_DWIDTH         =>  C_SPLB_NATIVE_DWIDTH,  
    C_FAMILY                =>  C_FAMILY               
    )
  port map (
    -- Input ports
    Bus_Rst                 =>  Bus_Rst     ,  
    Bus_clk                 =>  Bus_Clk     ,  
    
  -- Start Control  
    Req_Init                =>  sig_init_db_cntr ,  
   
   -- Qualifiers 
    Doing_Single            =>  single_transfer  ,  
    Doing_Cacheline         =>  cacheln_transfer ,  
    Doing_FLBurst           =>  burst_transfer   ,  
    RNW_In                  =>  PLB_RNW          ,  
    --BE_In                   =>  sig_internal_be(0 to 3),  
    BE_In                   =>  PLB_BE(0 to 3)   ,  
    Size_In                 =>  PLB_Size         ,  
    MSize_In                =>  PLB_Msize        ,  

  -- Count Enables  
    Wr_DAck                 =>  sig_internal_wrdack,  
    Rd_DAck                 =>  sig_internal_rddack_early1,  

    -- Special Case Output signals
    Cline_Spec_1DBeat_Case  =>  sig_cline_spec_1dbeat_case,
    
    
    -- Done State output signals
    AlmostDone              =>  sig_xfer_almost_done,  
    Done                    =>  sig_xfer_done           
    );

  
  
    
 -------------------------------------------------------------
 -- Synchronous Process with Sync Reset
 --
 -- Label: REG_XFER_DONE
 --
 -- Process Description:
 -- This process registers the Xfer done Flag to delay it by
 -- one Bus Clk period.
 --
 -------------------------------------------------------------
 REG_XFER_DONE : process (bus_clk)
    begin
      if (Bus_Clk'event and Bus_Clk = '1') then
         if (Bus_Rst = '1') then
           sig_xfer_done_dly1 <= '0';
         else
           sig_xfer_done_dly1 <= sig_xfer_done;
         end if; 
      end if;       
    end process REG_XFER_DONE; 
 
 
 
    
    
 ------------------------------------------------------------
 -- Write Acknowledge FLOP (WrAck is Same as Address Acknowledge signal) 
 -- Requires register duplication
  
  sig_wr_req       <= not(PLB_RNW) and
                      not_rearb_condition;
                      
  sig_clear_wrack  <= Bus_Rst or 
                     (sig_xfer_done and 
                      sig_internal_wrdack);
                      
  sig_clr_wrreq    <= Bus_Rst or
                      sig_clear_wrack_dly1;
  
  
  
  
  -- Generate Wrack to the PLB
  I_FLOP_WRACK_2BUS : FDRE 
     port map(
       Q     =>  sl_wrdack_i    ,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_do_cmd     ,        
       D     =>  sig_wr_req     ,        
       R     =>  sig_clear_wrack         
     );
 
     
  -- register duplication for internal Wrdack use   
  I_FLOP_WRACK : FDRE 
     port map(
       Q     =>  sig_internal_wrdack ,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_do_cmd     ,        
       D     =>  sig_wr_req     ,        
       R     =>  sig_clear_wrack         
     );
 
 
 
 
     
 
  -- -- register duplication for internal Wrdack use   
  -- I_FLOP_CLR_WRREQ : FDRE 
  --    port map(
  --      Q     =>  sig_clear_wrack_dly1 ,        
  --      C     =>  Bus_clk        ,        
  --      CE    =>  sig_do_cmd     ,        
  --      D     =>  sig_wr_req     ,        
  --      R     =>  sig_clear_wrack         
  --    );
     
 
  
  
  
  -- Generate the Write Enable to the BRAM   
  I_FLOP_WREN : FDRE 
     port map(
       Q     =>  bus2ip_wrreq_i ,        
       C     =>  Bus_clk        ,        
       CE    =>  '1' ,        
       D     =>  sig_internal_wrdack,        
       R     =>  Bus_Rst         
     );
     
 
 
 
 -- Read Acknowledge FLOPS 
 
  sig_clear_rdack_erly1  <= Bus_Rst or 
                          (sig_xfer_done and 
                           sig_internal_rddack_early1);
 
  
 
  I_FLOP_RDACK_2BUS : FDRE 
     port map(
       Q     =>  sl_rddack_i    ,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_rd_req_reg ,        
       D     =>  sig_internal_rddack_early1 ,        
       R     =>  Bus_Rst           
     );
     
 
  I_FLOP_RDACK_EARLY1 : FDRE 
     port map(
       Q     =>  sig_internal_rddack_early1,        
       C     =>  Bus_clk         ,        
       CE    =>  sig_set_sl_busy ,        
       D     =>  PLB_RNW         ,        
       R     =>  sig_clear_rdack_erly1           
     );

     
  sig_clear_rdack_erly2  <= Bus_Rst or 
                           (sig_xfer_almost_done and 
                            sig_internal_rddack_early2 and
                            not(sig_set_sl_busy));
 
  I_FLOP_RDACK_EARLY2 : FDRE 
     port map(
       Q     =>  sig_internal_rddack_early2,        
       C     =>  Bus_clk         ,        
       CE    =>  sig_do_cmd      ,        
       D     =>  PLB_RNW         ,        
       R     =>  sig_clear_rdack_erly2           
     );
     
    
    
  sig_rdcomp_erly <= ((doing_single_reg or
                       sig_cline_spec_1dbeat_case) and
                      sig_internal_rddack_early2) or
                     (sig_xfer_almost_done and   
                      sig_internal_rddack_early1);          
 
  sig_clr_rdcomp <= sig_clear_rdack_erly1 or 
                    sl_rdcomp_i;
    
  -- Read Complete Flop  
  I_FLOP_RDCOMP : FDRE 
     port map(
       Q     =>  sl_rdcomp_i    ,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_rd_req_reg ,        
       D     =>  sig_rdcomp_erly,        
       --R     =>  sig_clear_rdack_erly1           
       R     =>  sig_clr_rdcomp           
     );
     




 -- Read burst terminate FLOP
  sig_set_rdbterm     <=  doing_flburst_reg and
                          sig_rd_req_reg    and
                          sig_xfer_almost_done and
                          sig_internal_rddack_early1;

 sig_clr_rdbterm      <=  Bus_Rst or
                          not(doing_flburst_reg) or
                          sl_rdbterm_i;
 
  -- Read BTERM Flop  
  I_FLOP_RDBTERM : FDRE 
     port map(
       Q     =>  sl_rdbterm_i    ,        
       C     =>  Bus_clk         ,        
       CE    =>  sig_set_rdbterm ,        
       D     =>  '1',        
       R     =>  sig_clear_rdack_erly1           
     );
     
 
 
 
 
 
 
 
 
  
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: SLAVE_32_SPECIAL
  --
  -- If Generate Description:
  -- This IfGen implements the special condition case for a
  -- Fixed length Burst write of 2 data beats and a Slave width
  -- of 32 bits. 
  --
  ------------------------------------------------------------
  SLAVE_32_SPECIAL : if (C_SPLB_NATIVE_DWIDTH = 32) generate
  
     begin
  
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: SPECIAL_WRBTERM_32
      --
      -- Process Description:
      -- Special Write Burst Termination check for Slave 32
      -- Because of the optimized Write data acknowledge response 
      -- during the Sl_AddrAck asertion, the Write Burst case of 
      -- length 2 must be detected early so that the Sl_wrBTerm can 
      -- be asserted in conjunction with the first Sl_wrDAck assertion.
      --
      -- Note:
      -- If the requested transfer width is wider than the 
      -- Native Slave width, then Burst Length Expansion is required
      -- and Burst Terminate is not asserted immediately.
      -------------------------------------------------------------
      SPECIAL_WRBTERM_32 : process (bus_clk)
         begin
           if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst = '1' or
                (sig_force_wrbterm = '1' and
                 sig_internal_wrdack = '1') or
                 sl_rearbitrate_i = '1') then

               sig_force_wrbterm <= '0';
               
             --elsif (sig_addr_decode_hit     = '1' and
             elsif (sig_good_request        = '1' and
                    PLB_RNW                 = '0' and 
                    burst_transfer          = '1' and
                    --sig_internal_be(0 to 3) = "0001") then
                    PLB_BE(0 to 3) = "0001") then

               case PLB_size is
                 when "1010" =>  -- word xfer
                   
                   sig_force_wrbterm <= '1';
                 
                 -- when "1011" => -- double word xfer
                 --   
                 --   sig_force_wrbterm <= '0';
                 -- 
                 -- when "1011" => -- quad word xfer
                 --   
                 --   sig_force_wrbterm <= '0';
                 
                 when others =>  -- burst length expansion case
                   
                   sig_force_wrbterm <= '0';
                 
               end case;
             
             else
               null; -- hold current state
             end if; 
           end if;       
         end process SPECIAL_WRBTERM_32; 

      
     end generate SLAVE_32_SPECIAL;
    
    
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: SLAVE_64_SPECIAL
  --
  -- If Generate Description:
  -- This IfGen implements the special condition case for a
  -- Fixed length Burst write of 2 data beats and a Slave width
  -- of 64 bits. 
  --
  ------------------------------------------------------------
  SLAVE_64_SPECIAL : if (C_SPLB_NATIVE_DWIDTH = 64) generate
  
     begin
  
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: SPECIAL_WRBTERM_64
      --
      -- Process Description:
      -- Special Write Burst Termination check for Slave 64
      -- Because of the optimized Write data acknowledge response 
      -- during the Sl_AddrAck asertion, the Write Burst case of 
      -- length 2 must be detected early so that the Sl_wrBTerm can 
      -- be asserted in conjunction with the first Sl_wrDAck assertion.
      --
      -- Note:
      -- If the requested transfer width is wider than the 
      -- Native Slave width, then Burst Length Expansion is required
      -- and Burst Terminate is not asserted immediately.
      -------------------------------------------------------------
      SPECIAL_WRBTERM_64 : process (bus_clk)
         begin
           if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst = '1' or
                (sig_force_wrbterm = '1' and
                 sig_internal_wrdack = '1') or
                 sl_rearbitrate_i = '1') then

               sig_force_wrbterm <= '0';
               
             --elsif (sig_addr_decode_hit     = '1' and
             elsif (sig_good_request        = '1' and
                    PLB_RNW                 = '0' and 
                    burst_transfer          = '1' and
                    --sig_internal_be(0 to 3) = "0001") then
                    PLB_BE(0 to 3) = "0001") then

               case PLB_size is
                 when "1010" =>  -- word xfer
                   
                   sig_force_wrbterm <= '1';
                 
                 when "1011" => -- double word xfer
                   
                   sig_force_wrbterm <= '1';
                 
                 -- when "1011" => -- quad word xfer
                 --   
                 --   sig_force_wrbterm <= '0';
                 
                 when others => -- burst length expansion case
                   
                   sig_force_wrbterm <= '0';
                 
               end case;
             
             else
               null; -- hold current state
             end if; 
           end if;       
         end process SPECIAL_WRBTERM_64; 

      
     end generate SLAVE_64_SPECIAL;
      
       

    
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: SLAVE_128_SPECIAL
  --
  -- If Generate Description:
  -- This IfGen implements the special condition case for a
  -- Fixed length Burst write of 2 data beats and a Slave width
  -- of 128 bits. 
  --
  ------------------------------------------------------------
  SLAVE_128_SPECIAL : if (C_SPLB_NATIVE_DWIDTH = 128) generate
  
     begin
  
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: SPECIAL_WRBTERM_128
      --
      -- Process Description:
      -- Special Write Burst Termination check for Slave 128
      -- Because of the optimized Write data acknowledge response 
      -- during the Sl_AddrAck asertion, the Write Burst case of 
      -- length 2 must be detected early so that the Sl_wrBTerm can 
      -- be asserted in conjunction with the first Sl_wrDAck assertion.
      --
      -- Note:
      -- Since the Slave is 128 bits wide, burst length expansion
      -- will never occur so the WrBTerm must be asserted immediately.
      -------------------------------------------------------------
      SPECIAL_WRBTERM_128 : process (bus_clk)
         begin
           if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst = '1' or
                (sig_force_wrbterm = '1' and
                 sig_internal_wrdack = '1') or
                 sl_rearbitrate_i = '1') then

               sig_force_wrbterm <= '0';
               
             elsif (sig_good_request  = '1' and
                    PLB_RNW           = '0' and 
                    burst_transfer    = '1' and
                    --sig_internal_be(0 to 3) = "0001") then
                    PLB_BE(0 to 3)    = "0001") then

               sig_force_wrbterm <= '1';
             
             else
               null; -- hold current state
             end if; 
           end if;       
         end process SPECIAL_WRBTERM_128; 

      
     end generate SLAVE_128_SPECIAL;
      
       

    
    
    
  -------------------------------------------------------------
  -- Write Data Bus logic
  --
  --
  -------------------------------------------------------------
   
    

    sig_ld_wr_dreg <= sig_internal_wrdack; 
    
    
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: DO_WR_DREG
    --
    -- Process Description:
    --  This process implements the Write Data Register.
    --
    -------------------------------------------------------------
    DO_WR_DREG : process (bus_clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Rst        = '1' or
                sig_wr_req_reg = '0') then
              sig_wr_dreg <= (others => '0');
            elsif (sig_ld_wr_dreg = '1') then
              sig_wr_dreg <= PLB_wrDBus(0 to C_SPLB_NATIVE_DWIDTH-1);
            else
              null;  -- hold current state
            end if; 
         end if;       
       end process DO_WR_DREG; 
   
   
   
   
   
   
   
   
  -------------------------------------------------------------
  -- Read Data Bus logic
  --
  --
  -------------------------------------------------------------
   

  -- Rip the Read Data Bus Steering address from the address
  -- counter output
   sig_steer_addr    <=  bus2ip_addr_i(C_SPLB_AWIDTH - 
                                       STEER_ADDR_SIZE to
                                       C_SPLB_AWIDTH-1); 
 
   
   
   
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_STEER_ADDR
   --
   -- Process Description:
   --   This process registers the read data steer address to 
   -- delay it by 1 clock. THis aligns the address with the 
   -- corresponding data value out of the BRAM.
   --
   -------------------------------------------------------------
   REG_STEER_ADDR : process (bus_clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst = '1') then
             sig_steer_addr_reg <= (others => '0');
           elsif (sig_internal_rddack_early2 = '1') then
             sig_steer_addr_reg  <= sig_steer_addr;
           else
             null; -- hold current state
           end if; 
        end if;       
      end process REG_STEER_ADDR; 
   
   
    
    
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_RDWDADDR
   --
   -- Process Description:
   --   This process registers the needed address bits from the
   -- registered Steer Address to geneate the Sl_rdwdAdr output
   -- that is required for Cacheline Read operations.
   --
   -------------------------------------------------------------
   REG_RDWDADDR : process (bus_clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst                    = '1' or
               doing_cacheln_reg          = '0' or
               sig_internal_rddack_early1 = '0') then
             sl_rdwdaddr_i  <= (others => '0');
           else
             -- DET sl_rdwdaddr_i  <= 
             -- DET       sig_steer_addr_reg(STEER_ADDR_SIZE-6 to 
             -- DET                          STEER_ADDR_SIZE-3);
             
             -- DET  Zero MSBit since Cacheline 16 is not supported
             sl_rdwdaddr_i(1 to 3)  <= 
                   sig_steer_addr_reg(STEER_ADDR_SIZE-5 to 
                                      STEER_ADDR_SIZE-3);
           end if; 
        end if;       
      end process REG_RDWDADDR; 
   
   
       
    ------------------------------------------------------------
    -- Instance: I_MIRROR_STEER 
    --
    -- Description:
    --   This instantiates a parameterizable Mirror ands Steering
    -- support module for the Read Data. This is needed when
    -- a wide Slave is providing Read data to a narrow Master.   
    --
    ------------------------------------------------------------
    I_MIRROR_STEER : entity xps_bram_if_cntlr_v1_00_b.xbic_data_steer_mirror
    generic map (
      C_STEER_ADDR_WIDTH    =>  STEER_ADDR_SIZE        ,  
      C_SPLB_DWIDTH         =>  C_SPLB_DWIDTH          ,  
      C_SPLB_NATIVE_DWIDTH  =>  C_SPLB_NATIVE_DWIDTH   ,  
      C_SMALLEST_MASTER     =>  C_SPLB_SMALLEST_MASTER    
      )
    port map (
    
      Steer_Addr_In    =>  sig_steer_addr_reg       ,  
      Data_In          =>  ip2bus_rddata_i          ,  
      Data_Out         =>  sig_rd_data_mirror_steer   
    
      );
  
 
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: RD_DATA_REG
   --
   -- Process Description:
   --  This process implements the Read Data Register.
   --  Mirroring and Steeering is assumed to be done on the 
   --  input data to the register.
   -------------------------------------------------------------
   RD_DATA_REG : process (bus_clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst  = '1') then
             sig_rd_dreg    <= (others => '0');
           elsif (sig_internal_rddack_early1 = '1') then
             sig_rd_dreg <= sig_rd_data_mirror_steer;
           else
             sig_rd_dreg    <= (others => '0');
           end if; 
        end if;       
      end process RD_DATA_REG; 
    
  
      

 


end implementation;
