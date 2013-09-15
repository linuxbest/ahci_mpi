-------------------------------------------------------------------------------
-- $Id: xbic_slave_attach_sngl.vhd,v 1.2.2.1 2008/12/16 22:23:17 dougt Exp $
-------------------------------------------------------------------------------
-- xbic_slave_attach_sngl.vhd
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
-- Filename:        xbic_slave_attach_sngl.vhd
-- Version:         v1_00_a
-- Description:     Custom PLB slave attachment supporting only PLB single  
--                  beat transfers.
--                  
--
-------------------------------------------------------------------------------
-- Structure:
--
--                  xps_bram_if_cntlr.vhd
--                      -- xbic_data_mirror_128.vhd
--                      -- xbic_slave_attach_sngl.vhd
--                          -- xbic_addr_reg_cntr_brst_flex.vhd
--                              -- xbic_flex_addr_cntr.vhd
--                          -- xbic_be_reset_gen.vhd
--                          -- xbic_addr_be_support.vhd
--
-------------------------------------------------------------------------------
-- Author:      D. Thorpe
-- History:
--
--      DET        Feb-9-07
-- ~~~~~~
--      -- Special version for the XPS BRAM IF Cntlr that is adapted
--         from xps_bram_if_cntlr_v1_00_b library
--      -- Bypassed input address and qualifiers registering to remove
--         one clock of latency during address phase.
--      -- Optimized for PLBV46 Baseline op mode
-- ^^^^^^
--
--     DET     6/5/2007     jm.10
-- ~~~~~~
--     - Added the request validation to the wait assertion logic.
-- ^^^^^^
--
--     DET     8/25/2008     v1_00_b
-- ~~~~~~
--     - Updated to proc_common_v3_00_a library.
--     - Updated this core's library reference to V1_00_b.
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
use xps_bram_if_cntlr_v1_00_b.xbic_addr_decode;
use xps_bram_if_cntlr_v1_00_b.xbic_addr_be_support;
use xps_bram_if_cntlr_v1_00_b.xbic_data_steer_mirror;

-------------------------------------------------------------------------------
entity xbic_slave_attach_sngl is
  generic (

    C_STEER_ADDR_SIZE       : integer := 10;
    C_ARD_ADDR_RANGE_ARRAY  : SLV64_ARRAY_type :=
       (
         X"0000_0000_7000_0000", -- IP user0 base address
         X"0000_0000_7000_00FF"  -- IP user0 high address
       );

    C_SPLB_NUM_MASTERS       : integer := 4;
    C_SPLB_MID_WIDTH         : integer := 2;
    C_SPLB_P2P               : integer := 0;
    C_SPLB_AWIDTH            : integer := 32;
    C_SPLB_DWIDTH            : Integer := 32;
    C_SPLB_NATIVE_DWIDTH     : integer := 32;
    C_SPLB_SMALLEST_MASTER   : Integer := 32;
    C_FAMILY                 : string  := "virtex4"
    );
  port(
    --System signals
    Bus_Rst           : in  std_logic;
    Bus_Clk           : in  std_logic;

    -- PLB Bus signals
    PLB_ABus          : in  std_logic_vector(0 to 31);
    PLB_UABus         : in  std_logic_vector(0 to 31);
    PLB_PAValid       : in  std_logic;
    PLB_masterID      : in  std_logic_vector
                          (0 to C_SPLB_MID_WIDTH - 1);
    PLB_RNW           : in  std_logic;
    PLB_BE            : in  std_logic_vector
                          (0 to (C_SPLB_DWIDTH/8)-1);
    PLB_Msize         : in  std_logic_vector(0 to 1);
    PLB_size          : in  std_logic_vector(0 to 3);
    PLB_type          : in  std_logic_vector(0 to 2);
    PLB_wrDBus        : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst       : in  std_logic;
    PLB_rdBurst       : in  std_logic;
    Sl_SSize          : out std_logic_vector(0 to 1);
    Sl_addrAck        : out std_logic;
    Sl_wait           : out std_logic;
    Sl_rearbitrate    : out std_logic;
    Sl_wrDAck         : out std_logic;
    Sl_wrComp         : out std_logic;
    Sl_wrBTerm        : out std_logic;
    Sl_rdDBus         : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr       : out std_logic_vector(0 to 3);
    Sl_rdDAck         : out std_logic;
    Sl_rdComp         : out std_logic;
    Sl_rdBTerm        : out std_logic;
    Sl_MBusy          : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr         : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);   
    Sl_MWrErr         : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);   

    -- Controls to the IP/IPIF modules
    Bus2Bram_CS        : out std_logic;
    Bus2Bram_WrReq     : out std_logic;
    Bus2Bram_RdReq     : out std_logic;
    Bus2Bram_Addr      : out std_logic_vector (0 to C_SPLB_AWIDTH-1);
    Bus2Bram_BE        : out std_logic_vector (0 to C_SPLB_NATIVE_DWIDTH/8-1);
    Bus2Bram_WrData    : out std_logic_vector (0 to C_SPLB_NATIVE_DWIDTH-1);

    -- Inputs from the BRAM interface logic
    Bram2Bus_RdData    : in  std_logic_vector (0 to C_SPLB_NATIVE_DWIDTH-1);
    Bram2Bus_WrAck     : in  std_logic;
    Bram2Bus_RdAck     : in  std_logic

     
    );
end entity xbic_slave_attach_sngl;

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

architecture implementation of xbic_slave_attach_sngl is


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
 
 
 
Constant STEER_ADDR_SIZE : integer := 5;


                                    
-------------------------------------------------------------------------------
-- Signal and type Declarations
-------------------------------------------------------------------------------

-- Intermediate Slave Reply output signals (to PLB)
signal sl_addrack_i             : std_logic;
signal sl_wait_i                : std_logic;
signal sl_rearbitrate_i         : std_logic;
signal sl_wrdack_i              : std_logic;
signal sl_wrbterm_i             : std_logic;
signal sl_rddbus_i              : std_logic_vector(0 to C_SPLB_DWIDTH-1);
signal sl_rddack_i              : std_logic;
signal sl_rdcomp_i              : std_logic;
signal sl_mbusy_i               : std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

signal bus2ip_cs_i              : std_logic;
signal bus2ip_wrreq_i           : std_logic;
signal bus2ip_rdreq_i           : std_logic;
signal bus2ip_addr_i            : std_logic_vector(0 to 
                                  C_SPLB_AWIDTH-1);
signal bus2ip_rnw_i             : std_logic;
signal bus2ip_be_i              : std_logic_vector(0 to 
                                 (C_SPLB_NATIVE_DWIDTH/8)-1);
signal bus2ip_data_i            : std_logic_vector(0 to 
                                  C_SPLB_NATIVE_DWIDTH-1);

signal ip2bus_wrack_i           : std_logic;
signal ip2bus_rdack_i           : std_logic;
signal ip2bus_rddata_i          : std_logic_vector(0 to 
                                  C_SPLB_NATIVE_DWIDTH-1);
 
signal valid_plb_type           : boolean := False;
signal valid_plb_size           : Boolean := False;
signal single_transfer          : std_logic;
signal cacheln_transfer         : std_logic;
signal burst_transfer           : std_logic;
signal sig_valid_request        : std_logic;
 
signal sig_internal_be          : std_logic_vector(0 to 
                                 (C_SPLB_NATIVE_DWIDTH/8)-1);
signal sig_combined_abus        : std_logic_vector(0 to 
                                  C_SPLB_AWIDTH-1);
signal sig_steer_addr           : std_logic_vector(0 to 
                                  STEER_ADDR_SIZE-1);
signal sig_addr_decode_hit      : std_logic;

signal sig_clr_addrack          : std_logic;
signal sig_sl_busy              : std_logic;
signal sig_clear_sl_busy        : std_logic;
signal sig_set_sl_busy          : std_logic;
Signal sig_clr_rearbitrate      : std_logic;
-- DET signal rearbitrate_condition    : std_logic;
signal wait_condition           : std_logic;
Signal sig_clr_wait             : std_logic;

signal sig_do_cmd               : std_logic;
signal sig_cmd_cmplt            : std_logic;
signal sig_clr_qualifiers       : std_logic;

signal sig_mst_id               : std_logic_vector(0 to 
                                  C_SPLB_MID_WIDTH-1);
signal sig_mst_id_int           : integer range 0 to 
                                  C_SPLB_NUM_MASTERS-1 := 0;
signal sig_rd_dreg              : std_logic_vector(0 to 
                                  C_SPLB_DWIDTH-1);
signal sig_rd_data_mirror_steer : std_logic_vector(0 to 
                                  C_SPLB_DWIDTH-1);
signal sig_rd_data_128          : std_logic_vector(0 to 127);

Signal sig_wr_req               : std_logic;
Signal sig_ld_wr_dreg           : std_logic;
signal sig_wr_dreg              : std_logic_vector(0 to 
                                  C_SPLB_NATIVE_DWIDTH-1);

signal sig_clr_rdack            : std_logic;
signal sig_plb_done             : std_logic;

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
Sl_wrComp           <= sl_wrdack_i          ;
Sl_wrBTerm          <= '0'                  ; 
Sl_rdDBus           <= sl_rddbus_i          ;
Sl_rdWdAddr         <= (others => '0')      ;
Sl_rdDAck           <= sl_rddack_i          ;
Sl_rdComp           <= sl_rdcomp_i          ;
Sl_rdBTerm          <= '0'                  ;
Sl_MBusy            <= sl_mbusy_i           ;
Sl_MRdErr           <= (others => '0')      ;
Sl_MWrErr           <= (others => '0')      ;

Sl_SSize  <= SLAVE_SIZE
  when (sig_set_sl_busy = '1')
  Else "00";


sl_rddbus_i         <= sig_rd_dreg;  
sl_rdcomp_i         <= ip2bus_rdack_i;
sl_rearbitrate_i    <= '0';




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

                                   
                                   
--GAB - was kicking off a cycle even when the cycle was not a valid cycle, i.e. cachelines etc.
--GAB sig_do_cmd         <=  (sig_addr_decode_hit and 
--GAB                       not(sig_sl_busy)) or
--GAB                       (sig_addr_decode_hit and
--GAB                        sig_clear_sl_busy);

sig_do_cmd         <=  sig_valid_request and
                     (
                        (sig_addr_decode_hit and 
                       not(sig_sl_busy)) or
                       (sig_addr_decode_hit and
                        sig_clear_sl_busy)
                     );
 
 
-- DET -- Rearbitrate if another address hit occurs and slave is busy
-- DET rearbitrate_condition   <=  sig_addr_decode_hit
-- DET                             and sig_sl_busy             
-- DET                             and not(sig_clear_sl_busy);




sig_mst_id_int <= CONV_INTEGER(sig_mst_id);



sig_clr_qualifiers <= sig_clear_sl_busy and 
                      not(sig_do_cmd);


sig_ld_wr_dreg <=  sig_set_sl_busy and
                   sig_wr_req;




 -- Wait FLOP
  
  -- DET This logic was not screening invalid requests
  -- DET 
  -- DET wait_condition  <=  sig_addr_decode_hit        
  -- DET                     and sig_sl_busy;

  wait_condition  <=  sig_valid_request   and
                      sig_addr_decode_hit and        
                      sig_sl_busy;

  sig_clr_wait    <= Bus_Rst or
                     sig_set_sl_busy;

  I_FLOP_REARB : FDRE 
     port map(
       Q     =>  sl_wait_i       ,  
       C     =>  Bus_clk         ,  
       CE    =>  wait_condition  ,  
       D     =>  '1'             ,  
       R     =>  sig_clr_wait       
     );
     
     



 
 
 -- Address Acknowledge Flops (needed for register duplication)
 
  -- sig_clr_addrack <=  Bus_Rst or
  --                     sig_set_sl_busy or
  --                     sig_sl_busy;
  
  sig_clr_addrack <=  Bus_Rst or
                      sig_set_sl_busy or
                      (sig_sl_busy and
                      not(sig_clear_sl_busy));
                      
  
  
 
  I_FLOP_ADDRACK : FDRE 
     port map(
       Q     =>  sl_addrack_i   ,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_do_cmd     ,        
       D     =>  '1'            ,        
       R     =>  sig_clr_addrack         
     );
     

   
 
  I_FLOP_SET_SLBUSY : FDRE 
     port map(
       Q     =>  sig_set_sl_busy,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_do_cmd     ,        
       D     =>  '1'            ,        
       R     =>  sig_clr_addrack         
     );
     
 
 
 
 -- Write Acknowledge FLOP (WrAck is Same as Address Acknowledge signal) 
 -- Requires register duplication
  
  sig_wr_req <= not(PLB_RNW);
 
 
 
  I_FLOP_WRACK : FDRE 
     port map(
       Q     =>  sl_wrdack_i    ,        
       C     =>  Bus_clk        ,        
       CE    =>  sig_do_cmd     ,        
       D     =>  sig_wr_req     ,        
       R     =>  sig_clr_addrack         
     );
     
     
 
 
 
 -- Read Acknowledge FLOPS needed for register duplication
 
  sig_clr_rdack <= Bus_Rst or
                   not(bus2ip_rdreq_i);

 
 
  I_FLOP_RDACK : FDRE 
     port map(
       Q     =>  sl_rddack_i    ,        
       C     =>  Bus_clk        ,        
       CE    =>  bus2ip_rdreq_i ,        
       D     =>  ip2bus_rdack_i ,        
       R     =>  sig_clr_rdack           
     );
     
 
  sig_plb_done <=  (ip2bus_rdack_i  and bus2ip_rdreq_i) or
                   (ip2bus_wrack_i  and bus2ip_wrreq_i);
 
  
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

    
-------------------------------------------------------------------------------
-- PLB Size Validation
-- This combinatorial process validates the PLB request attribute PLB_Size
-- that is supported by this slave. Slave Single only responds to single
-- data beat requests.
-------------------------------------------------------------------------------
VALIDATE_SIZE : process (PLB_Size)
    begin
        case PLB_Size is
            -- single data beat transfer
            when "0000" =>   -- one to eight bytes
                valid_plb_size   <= true;
                single_transfer  <= '1';
                cacheln_transfer <= '0';
                burst_transfer   <= '0';

           --  -- cacheline transfer
           --  when "0001" |   -- 4 word cache-line
           --       "0010" |   -- 8 word cache-line
           --       "0011" =>  -- 16 word cache-line
           -- 
           --      valid_plb_size   <= true;
           --      single_transfer  <= '0';
           --      cacheln_transfer <= '1';
           --      burst_transfer   <= '0';
           -- 
           --  -- burst transfer (fixed length)
           --  when "1000" |    -- byte burst transfer
           --       "1001" |    -- halfword burst transfer
           --       "1010" |    -- word burst transfer
           --       "1011" |    -- double word burst transfer                 
           --       "1100" =>   -- quad word burst transfer                   
           --                   -- octal widths are not allowed (256 wide bus)
           -- 
           --      valid_plb_size   <= true;
           --      single_transfer  <= '0';
           --      cacheln_transfer <= '0';
           --      burst_transfer   <= '1';

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
-- Access Validation
-- This combinatorial process validates the PLB request attributes that are
-- supported by this slave.
-------------------------------------------------------------------------------
VALIDATE_REQUEST : process (PLB_PAvalid,
                            valid_plb_size,
                            valid_plb_type)
    begin
        if (PLB_PAvalid = '1') and      -- Address Request
           (valid_plb_size)    and      -- and a valid plb_size
           (valid_plb_type) then        -- and a memory xfer
            
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
      
    -- Address Decoder Removed in P2P mode  
      sig_addr_decode_hit <= sig_valid_request;
     
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
      
     ------------------------------------------------------------------
     -- Address Decoder Component Instance
     -- This component decodes the specified base address pair and 
     -- outputs the decode hit indication.
     ------------------------------------------------------------------
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
             Address_Valid       =>  sig_valid_request,  
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
           
           bus2ip_cs_i     <=  '0';  
           bus2ip_wrreq_i  <=  '0';  
           bus2ip_rdreq_i  <=  '0';  
           bus2ip_addr_i   <=  (others => '0');  
           bus2ip_be_i     <=  (others => '0');
           sig_mst_id      <=  (others => '0');
           sig_steer_addr  <=  (others => '0');
                  
          elsif (sig_do_cmd = '1') then
           
           bus2ip_cs_i     <=  '1';  
           bus2ip_wrreq_i  <=  not(PLB_RNW);  
           bus2ip_rdreq_i  <=  PLB_RNW;  
           bus2ip_addr_i   <=  sig_combined_abus;  
           bus2ip_be_i     <=  sig_internal_be;  
           sig_mst_id      <=  PLB_masterID;
           sig_steer_addr  <=  sig_combined_abus(C_SPLB_AWIDTH - 
                                                 C_STEER_ADDR_SIZE to
                                                 C_SPLB_AWIDTH-1); 
                  
          else
            null;  -- hold state
          end if; 
       end if;       
     end process REG_XFER_QUALIFIERS; 
 
 
   
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
                bus2ip_wrreq_i = '0') then
              sig_wr_dreg <= (others => '0');
            elsif (sig_ld_wr_dreg = '1') then
              sig_wr_dreg <= PLB_wrDBus(0 to C_SPLB_NATIVE_DWIDTH-1);
            else
              null;  -- hold current state
            end if; 
         end if;       
       end process DO_WR_DREG; 
   
   
   
   
   
   
   
   
   
   

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
           elsif (ip2bus_rdack_i = '1') then
             sig_rd_dreg <= sig_rd_data_mirror_steer;
           else
             sig_rd_dreg    <= (others => '0');
           end if; 
        end if;       
      end process RD_DATA_REG; 
    
      

 
       
   ------------------------------------------------------------
   -- Instance: I_MIRROR_STEER 
   --
   -- Description:
   --   This instantiates a parameterizable Mirror ands Steering
   -- support module.    
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
    
      Steer_Addr_In    =>  sig_steer_addr           ,  
      Data_In          =>  ip2bus_rddata_i          ,  
      Data_Out         =>  sig_rd_data_mirror_steer   
    
      );
  
 
 


end implementation;
