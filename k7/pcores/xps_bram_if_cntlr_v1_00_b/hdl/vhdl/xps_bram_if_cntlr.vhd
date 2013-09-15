-------------------------------------------------------------------------------
-- $Id: xps_bram_if_cntlr.vhd,v 1.2.2.2 2008/12/16 22:23:17 dougt Exp $
-------------------------------------------------------------------------------
-- xps_bram_if_cntlr.vhd - entity/architecture pair
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
-- Filename:        xps_bram_if_cntlr.vhd
-- Version:         v1.00a  (Initial release support for PLBV46)
-- Description:     This is the top-level design file for the XPS BRAM
--                  Interface Controller supporting the IBM CoreConnect  
--                  PLB V4.6 specification. This module provides the  
--                  interface between the PLB and the actual FPGA BRAM 
--                  resources that are instantiated by the EDK tools.
-- 
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
--
-------------------------------------------------------------------------------
-- Author:      DET
-- History:
--  DET      10-19-2006      -- V1_00_a initial version
-- ~~~~~~
--     - Incorporated use of plbv46_slave_single for use in non-burst 
--       application and 32-bit only applications
--     - Incorporated PLBV46 Slave burst for single data beats wider than 
--       32-bits, cacheline support, and Fixed Length Burst support.
--         
-- ^^^^^^
--
--     DET     2/27/2007     v1_00_a
-- ~~~~~~
--     - Revamped design to remove 2 clocks of latency. IPIFs replaced with 
--       custom design.
--     - Point to Point Mode removes Address Decode function only. No latency
--       reduction realized.
--
-- ^^^^^^
--
--     DET     5/24/2007     Jm
-- ~~~~~~
--     - Various redesign changes for the Performance Mode HDL to improve
--       Fmax results in Spartan devices.
-- ^^^^^^
--
--     DET     6/5/2007     jm.10
-- ~~~~~~
--     - Changed default value of C_SPLB_SUPPORT_BURSTS from 0 to 1.
-- ^^^^^^
--
--     DET     8/25/2008     V1_00_b
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
--     DET     11/25/2008     v1_00_b
-- ~~~~~~
--     - Removed imbedded Changelog from file header. 
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
--      combinatorial signals:                  "*_cmb"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_misc.all;
--
-- library unsigned is used for overloading of "=" which allows integer to
-- be compared to std_logic_vector
use ieee.std_logic_unsigned.all;
--

library Unisim;
use Unisim.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.family.all;
use proc_common_v3_00_a.all;


library xps_bram_if_cntlr_v1_00_b;
use xps_bram_if_cntlr_v1_00_b.xbic_slave_attach_sngl;
use xps_bram_if_cntlr_v1_00_b.xbic_slave_attach_burst;


-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:

-- Generics set by the User
--      C_BASEADDR             
          -- BRAM memory base address (width must match C_SPLB_AWIDTH)                                                                                
--      C_HIGHADDR             
          -- BRAM memory high address (width must match C_SPLB_AWIDTH)
--      C_SPLB_NATIVE_DWIDTH      
          -- Desired Data Bit Width of the BRAM (32,64 or 128)
           
-- Generics auto-calculated/set by the EDK XPS tools
--      C_SPLB_AWIDTH       
          -- PLBV46 interface address width
--      C_SPLB_DWIDTH         
          -- PLBV46 interface data width                                   
--      C_SPLB_NUM_MASTERS   
          -- number of PLB masters on the PLBV46 interconnect
--      C_SPLB_MID_WIDTH     
          -- log2(C_SPLB_NUM_MASTERS)
--      C_SPLB_SUPPORT_BURSTS  
          -- 0 = Resource optimized mode for Bursts and Cacheline transfers
          -- 1 = Performance optimized mode for Bursts and Cacheline transfers
--      C_SPLB_P2P
           -- Designates the interconnect topology of the attached 
           -- PLBV46 interface
           -- 0 = Shared bus
           -- 1 = Point to Point (no address decoding and low latency)           
--      C_SPLB_SMALLEST_MASTER  
          -- Used to specify the data width of the 
          -- smallest master that could access this BRAM
          -- interface controller (needed for ipif resource
          -- optimization opportunity)
--      C_FAMILY   
           -- Indicates the target device architecture

                                                    
-- Definition of Ports: 

--  -- PLB input ports
--      SPLB_Clk          -- PLB system clock
--      SPLB_Rst          -- PLB system Reset
--      PLB_abort         -- PLB abort bus request indicator
--      PLB_ABus          -- PLB address bus
--      PLB_UABus         -- PLB upper (extended) address bus
--      PLB_PAValid       -- PLB primary address valid indicator
--      PLB_SAValid       -- PLB secondary address valid indicator
--      PLB_rdPrim        -- PLB secondary to primary read request indicator
--      PLB_wrPrim        -- PLB secondary to primary write request indicator
--      PLB_masterID      -- PLB current master indicator
--      PLB_abort         -- PLB abort indicator
--      PLB_busLock       -- PLB bus lock
--      PLB_RNW           -- PLB read not write
--      PLB_BE            -- PLB byte enables
--      PLB_MSize         -- PLB master data bus size
--      PLB_size          -- PLB transfer size
--      PLB_type          -- PLB transfer type
--      PLB_lockErr       -- PLB lock error indicator
--      PLB_wrDBus        -- PLB write data bus
--      PLB_wrBurst       -- PLB burst write transfer indicator
--      PLB_rdBurst       -- PLB burst read transfer indicator
--      PLB_wrPendReq     -- PLB write pending request
--      PLB_rdPendReq     -- PLB read pending request
--      PLB_wrPendPri     -- PLB write pending request priority
--      PLB_rdPendPri     -- PLB read pending request priority
--      PLB_reqPri        -- PLB request priority
--      PLB_TAttribute    -- PLB Tranfer Attribute qualifier bus

--  -- Slave Reply ports (to PLB)
--      Sl_addrAck        -- Slave address acknowledge
--      Sl_SSize          -- Slave data bus sizer
--      Sl_wait           -- Slave wait indicator
--      Sl_rearbitrate    -- Slave rearbitrate bus indicator
--      Sl_wrDAck         -- Slave write data acknowledge
--      Sl_wrComp         -- Slave write transfer complete indicator
--      Sl_wrBTerm        -- Slave terminate write burst transfer
--      Sl_rdDBus         -- Slave read bus
--      Sl_rdWdAddr       -- Slave read word address
--      Sl_rdDAck         -- Slave read data acknowledge
--      Sl_rdComp         -- Slave read transfer complete indicator
--      Sl_rdBTerm        -- Slave terminate read burst transfer
--      Sl_MBusy          -- Slave busy indicator  (one bit per PLB mstr)
--      Sl_MWrMErr        -- Slave write error indicator (one bit per PLB mstr)
--      Sl_MRdMErr        -- Slave read error indicator (one bit per PLB mstr)
--      Sl_MIRQ           -- Slave interrupt indicator (one bit per PLB mstr)

 
 
 
--  BRAM Block output ports (to BRAM Block)
--      BRAM_Rst          -- BRAM Block reset control             
--      BRAM_CLK          -- BRAM Block clock 
--      BRAM_EN           -- BRAM Block enable
--      BRAM_WEN          -- BRAM Block write enable
--      BRAM_Addr         -- BRAM Block address 
--      BRAM_Dout         -- BRAM Block write data
--
--  BRAM Block input port  (from BRAM Block)
--      BRAM_Din          -- BRAM Block read data

----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- Entity section
----------------------------------------------------------------------------

entity xps_bram_if_cntlr is
    generic (
      -- User configured Generics
      --- Note:  Base/High Addresses must be C_SPLB_AWIDTH bits wide
        C_BASEADDR               : std_logic_vector := X"FFFF_FFFF";
        C_HIGHADDR               : std_logic_vector := X"0000_0000";
        C_SPLB_NATIVE_DWIDTH     : Integer  range 32 to 128 := 32;

      -- Generics auto-calculated/set by the EDK XPS tools
        C_SPLB_AWIDTH            : integer  range 32 to 36  := 32; 
        C_SPLB_DWIDTH            : integer  range 32 to 128 := 32;
        C_SPLB_NUM_MASTERS       : integer  range 1 to 16   := 2;
        C_SPLB_MID_WIDTH         : integer  range 1 to 4    := 1;
        C_SPLB_SUPPORT_BURSTS    : integer  range 0 to 1    := 1;
        C_SPLB_P2P               : Integer  range 0 to 1    := 0;
        C_SPLB_SMALLEST_MASTER   : Integer  range 32 to 128 := 32;
        C_FAMILY                 : String   := "virtex5"
        );
    port (
        -- System Port Declarations *****************************************
        SPLB_Clk          : in  std_logic;
        SPLB_Rst          : in  std_logic;

        -- PLB Port Declarations ********************************************
        PLB_ABus          : in  std_logic_vector(0 to 31);
        PLB_UABus         : in  std_logic_vector(0 to 31); 
        PLB_PAValid       : in  std_logic;
        PLB_SAValid       : in  std_logic;
        PLB_rdPrim        : in  std_logic;
        PLB_wrPrim        : in  std_logic;
        PLB_masterID      : in  std_logic_vector(0 to 
                                C_SPLB_MID_WIDTH-1);
        PLB_abort         : in  std_logic;    
        PLB_busLock       : in  std_logic;
        PLB_RNW           : in  std_logic;
        PLB_BE            : in  std_logic_vector(0 to
                                (C_SPLB_DWIDTH /8) - 1);
        PLB_MSize         : in  std_logic_vector(0 to 1);
        PLB_size          : in  std_logic_vector(0 to 3);
        PLB_type          : in  std_logic_vector(0 to 2);
        PLB_lockErr       : in  std_logic;
        PLB_wrDBus        : in  std_logic_vector(0 to
                                C_SPLB_DWIDTH -1);
        PLB_wrBurst       : in  std_logic;
        PLB_rdBurst       : in  std_logic;
        PLB_wrPendReq     : in  std_logic;  
        PLB_rdPendReq     : in  std_logic;  
        PLB_wrPendPri     : in  std_logic_vector(0 to 1);   
        PLB_rdPendPri     : in  std_logic_vector(0 to 1);   
        PLB_reqPri        : in  std_logic_vector(0 to 1);
        PLB_TAttribute    : in  std_logic_vector(0 to 15);  


        -- Slave Response Signals
        Sl_addrAck        : out std_logic;
        Sl_SSize          : out std_logic_vector(0 to 1);
        Sl_wait           : out std_logic;
        Sl_rearbitrate    : out std_logic;
        Sl_wrDAck         : out std_logic;
        Sl_wrComp         : out std_logic;
        Sl_wrBTerm        : out std_logic;
        Sl_rdDBus         : out std_logic_vector(0 to
                                C_SPLB_DWIDTH -1);
        Sl_rdWdAddr       : out std_logic_vector(0 to 3);
        Sl_rdDAck         : out std_logic;
        Sl_rdComp         : out std_logic;
        Sl_rdBTerm        : out std_logic;
        Sl_MBusy          : out std_logic_vector(0 to 
                                C_SPLB_NUM_MASTERS-1);
        Sl_MWrErr         : out std_logic_vector(0 to 
                                C_SPLB_NUM_MASTERS-1); 
        Sl_MRdErr         : out std_logic_vector(0 to 
                                C_SPLB_NUM_MASTERS-1); 
        Sl_MIRQ           : out std_logic_vector(0 to 
                                C_SPLB_NUM_MASTERS-1); 



        -- User BRAM Ports 
        BRAM_Rst          : out std_logic;
        BRAM_Clk          : out std_logic;
        BRAM_EN           : out std_logic;
        BRAM_WEN          : out std_logic_vector(0 to 
                                (C_SPLB_NATIVE_DWIDTH/8)-1);
        BRAM_Addr         : out std_logic_vector(0 to 
                                C_SPLB_AWIDTH-1);
        BRAM_Din          : in  std_logic_vector(0 to 
                                C_SPLB_NATIVE_DWIDTH-1);
        BRAM_Dout         : out std_logic_vector(0 to 
                                C_SPLB_NATIVE_DWIDTH-1)
        );

    -- fan-out attributes for XST
    attribute MAX_FANOUT                    : string;
    attribute MAX_FANOUT of SPLB_Clk        : signal is "10000";
    attribute MAX_FANOUT of SPLB_Rst        : signal is "10000";

    -- PSFUtil attributes (for Auto_generation of MPD file) 
    attribute MIN_SIZE                      : string;
    attribute MIN_SIZE of C_BASEADDR        : constant is "0x04000";

    attribute SIGIS                         : string;
    attribute SIGIS of SPLB_Clk             : signal is "CLK";
    attribute SIGIS of SPLB_Rst             : signal is "RST";

    attribute SPECIAL                       : string;
    attribute SPECIAL of xps_bram_if_cntlr  : entity is "BRAM_CNTLR";

 
    
      
end xps_bram_if_cntlr;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of xps_bram_if_cntlr is

 
 
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

  constant PLBV46_AWIDTH      : integer := C_SPLB_AWIDTH;
  
  Constant BASEADDR_SIZE      : integer := C_BASEADDR'length;             
  Constant HIGHADDR_SIZE      : integer := C_HIGHADDR'length;             
  
  constant ZERO_BADDR_PAD     : std_logic_vector(0 to 
                                               (64-BASEADDR_SIZE)-1) :=    
                                               (others => '0');
  
  constant ZERO_HADDR_PAD     : std_logic_vector(0 to 
                                               (64-HIGHADDR_SIZE)-1) :=    
                                               (others => '0');
   

    
  -- BRAM Constants                              
   constant BRAM              : integer := USER_00;
   constant NUM_BRAM_CS       : integer := 1;
   constant NUM_BRAM_CE       : integer := 1;
   constant NUM_BRAM_BE       : integer := C_SPLB_NATIVE_DWIDTH/8;
   
   
   
   
   
   


-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------


   signal sig_bus2ip_reset    : std_logic;
   signal sig_bus2ip_clk      : std_logic;
   signal sig_bus2ip_cs       : std_logic;
   signal sig_bus2ip_wrce     : std_logic_vector(0 to NUM_BRAM_CE-1);
   signal sig_bus2ip_rdce     : std_logic_vector(0 to NUM_BRAM_CE-1);
   signal sig_bus2ip_addr     : std_logic_vector(0 to C_SPLB_AWIDTH-1);
   signal sig_bus2ip_be       : std_logic_vector(0 to NUM_BRAM_BE-1);
   signal sig_bus2ip_rnw      : std_logic;
   signal sig_bus2ip_wrreq    : std_logic;
   signal sig_bus2ip_rdreq    : std_logic;
   signal sig_bus2ip_data     : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
   signal sig_ip2bus_rdack    : std_logic;
   signal sig_ip2bus_data     : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
   signal sig_ip2bus_wrack    : std_logic;
   signal sig_bus2ip_burst    : std_logic;
   Signal sig_bram_wr_enable  : std_logic_vector(0 to NUM_BRAM_BE-1);
   Signal sig_bram_rd_enable  : std_logic;



begin -- architecture IMP


----------------------------------------------------------------
-- Assign the BRAM backend interface ports --------------------
----------------------------------------------------------------

  
  Sl_MIRQ <= (others => '0');
  
  
  
  
  -- Connect BRAM output Ports 
  BRAM_Rst          <=  SPLB_Rst            ;  
  BRAM_Clk          <=  SPLB_Clk            ;  
  BRAM_EN           <=  sig_bus2ip_cs       ;  
  BRAM_WEN          <=  sig_bram_wr_enable  ;  
  BRAM_Addr         <=  sig_bus2ip_addr     ;  
  BRAM_Dout         <=  sig_bus2ip_data     ;  
  
  -- Connect BRAM input Data Port 
  sig_ip2bus_data   <=  BRAM_Din    ;                        


 
 
 
  
  
  
  
  
 ------------------------------------------------------------
 -- If Generate
 --
 -- Label: SINGLES_ONLY_SUPPORT
 --
 -- If Generate Description:
 --     This IfGen instantiates a custom Slave Attachment which
 --  has been optimized for size and single data beats. It
 --  also requires the Native DWIDTH of the core to be 32-bits.
 --
 ------------------------------------------------------------
 SINGLES_ONLY_SUPPORT : if (C_SPLB_SUPPORT_BURSTS = 0 and 
                            C_SPLB_NATIVE_DWIDTH  = 32) generate
 
   -- Local Constants
   Constant STEER_ADDR_SIZE : integer := 5;
    
    
   -- local signals
   signal sig_bus2ip_wrreq_dly1       : std_logic;
   signal sig_bus2ip_wrreq_dly2       : std_logic;
   signal sig_bus2ip_rdreq_dly1       : std_logic;
   signal sig_bus2ip_rdreq_dly2       : std_logic;
   Signal sig_write_enable            : std_logic;

   ------------------------------------------------------------
   begin

 
     sig_bram_rd_enable   <= sig_bus2ip_cs; 
  
     sig_ip2bus_rdack     <=  sig_bus2ip_rdreq_dly1 and
                             not(sig_bus2ip_rdreq_dly2);
   
     sig_ip2bus_wrack     <=  sig_bus2ip_wrreq and
                             not(sig_bus2ip_wrreq_dly1);
   
     sig_write_enable     <=  sig_bus2ip_wrreq_dly1;
                              
     
     
                              
     -------------------------------------------------------------
     -- Synchronous Process with Sync Reset
     --
     -- Label: REG_WR_REQ1
     --
     -- Process Description:
     --     This process registers the Write Request signal.
     --
     -------------------------------------------------------------
     REG_WR_REQ1 : process (SPLB_Clk)
        begin
          if (SPLB_Clk'event and SPLB_Clk = '1') then
             if (SPLB_Rst              = '1' or
                 sig_bus2ip_wrreq      = '0'  or
                 sig_bus2ip_wrreq_dly1 = '1') then
               
               sig_bus2ip_wrreq_dly1 <= '0';
             
             else
               
               sig_bus2ip_wrreq_dly1 <= sig_bus2ip_wrreq;
             
             end if; 
          end if;       
        end process REG_WR_REQ1; 
     
     
    
     -------------------------------------------------------------
     -- Combinational Process
     --
     -- Label: GEN_WR_ENABLES
     --
     -- Process Description:
     --     This process generates the BRAM write enable controls
     -- based on the number of byte enables available.
     --
     -------------------------------------------------------------
     GEN_WR_ENABLES : process (sig_bus2ip_be,
                               sig_write_enable)
        begin
     
           for be_index in 0 to NUM_BRAM_BE-1 loop
           
             sig_bram_wr_enable(be_index) <= sig_bus2ip_be(be_index) and 
                                             sig_write_enable;
                  
           end loop;
     
        end process GEN_WR_ENABLES; 
     
     
     
 
 

 
 
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: REG_RD_REQ1
      --
      -- Process Description:
      --     This process registers the Read Request signal for 
      -- one high pulse only.
      --
      -------------------------------------------------------------
        REG_RD_REQ : process (SPLB_Clk)
          begin
          if (SPLB_Clk'event and SPLB_Clk = '1') then
             if (SPLB_Rst              = '1' or
                 sig_bus2ip_rdreq      = '0' or
                 sig_bus2ip_rdreq_dly1 = '1' or
                 sig_bus2ip_rdreq_dly2 = '1') then
               
               sig_bus2ip_rdreq_dly1 <= '0';
             
             else
               
               sig_bus2ip_rdreq_dly1 <= sig_bus2ip_rdreq;
             
             end if; 
          end if;       
          end process REG_RD_REQ;

       
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: REG_RD_REQ2
      --
      -- Process Description:
      --     This process samples and holds the delayed Read 
      -- Request signal when it goes high.
      --
      -------------------------------------------------------------
        REG_RD_REQ2 : process (SPLB_Clk)
          begin
          if (SPLB_Clk'event and SPLB_Clk = '1') then
             if (SPLB_Rst         = '1' or
                 sig_bus2ip_rdreq = '0') then
               
               sig_bus2ip_rdreq_dly2 <= '0';
             
             else
               
               sig_bus2ip_rdreq_dly2 <= sig_bus2ip_rdreq_dly1;
             
             end if; 
          end if;       
          end process REG_RD_REQ2;
 
 
                                            
       sig_bus2ip_burst <= '0';
       sig_bus2ip_rnw   <= '0';
      
      
      I_SLAVE_SINGLE_ATTACH : entity xps_bram_if_cntlr_v1_00_b.xbic_slave_attach_sngl
          generic map (

              C_STEER_ADDR_SIZE        =>  STEER_ADDR_SIZE,  
              C_ARD_ADDR_RANGE_ARRAY   =>  (ZERO_BADDR_PAD & C_BASEADDR,
                                            ZERO_HADDR_PAD & C_HIGHADDR),  
              C_SPLB_NUM_MASTERS       =>  C_SPLB_NUM_MASTERS    ,  
              C_SPLB_MID_WIDTH         =>  C_SPLB_MID_WIDTH      ,  
              C_SPLB_P2P               =>  C_SPLB_P2P            ,  
              C_SPLB_AWIDTH            =>  C_SPLB_AWIDTH         ,  
              C_SPLB_DWIDTH            =>  C_SPLB_DWIDTH         ,  
              C_SPLB_NATIVE_DWIDTH     =>  C_SPLB_NATIVE_DWIDTH  ,  
              C_SPLB_SMALLEST_MASTER   =>  C_SPLB_SMALLEST_MASTER 
              )
          port map (
              --System signals
              Bus_Rst             =>  SPLB_Rst      ,  
              Bus_Clk             =>  SPLB_Clk      ,  

              -- PLB Bus signals
              PLB_ABus            =>  PLB_ABus      ,  
              PLB_UABus           =>  PLB_UABus     ,  
              PLB_PAValid         =>  PLB_PAValid   ,  
              PLB_masterID        =>  PLB_masterID  ,  
                                                       
              PLB_RNW             =>  PLB_RNW       ,  
              PLB_BE              =>  PLB_BE        ,  
                                                       
              PLB_Msize           =>  PLB_MSize     ,  
              PLB_size            =>  PLB_size      ,  
              PLB_type            =>  PLB_type      ,  
              PLB_wrDBus          =>  PLB_wrDBus    ,  
              PLB_wrBurst         =>  PLB_wrBurst   ,  
              PLB_rdBurst         =>  PLB_rdBurst   ,  
              Sl_SSize            =>  Sl_SSize      ,  
              Sl_addrAck          =>  Sl_addrAck    ,  
              Sl_wait             =>  Sl_wait       ,  
              Sl_rearbitrate      =>  Sl_rearbitrate,  
              Sl_wrDAck           =>  Sl_wrDAck     ,  
              Sl_wrComp           =>  Sl_wrComp     ,  
              Sl_wrBTerm          =>  Sl_wrBTerm    ,  
              Sl_rdDBus           =>  Sl_rdDBus     ,  
              Sl_rdWdAddr         =>  Sl_rdWdAddr   ,  
              Sl_rdDAck           =>  Sl_rdDAck     ,  
              Sl_rdComp           =>  Sl_rdComp     ,  
              Sl_rdBTerm          =>  Sl_rdBTerm    ,  
              Sl_MBusy            =>  Sl_MBusy      ,  
              Sl_MRdErr           =>  Sl_MRdErr     ,    
              Sl_MWrErr           =>  Sl_MWrErr     ,    

              -- Controls to the IP/IPIF modules
              Bus2Bram_CS         =>  sig_bus2ip_cs     ,  
              Bus2Bram_WrReq      =>  sig_bus2ip_wrreq  ,  
              Bus2Bram_RdReq      =>  sig_bus2ip_rdreq  ,  
              Bus2Bram_Addr       =>  sig_bus2ip_addr   ,  
              Bus2Bram_BE         =>  sig_bus2ip_be     ,  
              Bus2Bram_WrData     =>  sig_bus2ip_data   ,  

              -- Inputs from the BRAM interface logic
              Bram2Bus_RdData     =>  sig_ip2bus_data   ,  
              Bram2Bus_WrAck      =>  sig_ip2bus_wrack  ,  
              Bram2Bus_RdAck      =>  sig_ip2bus_rdack     

             
          );
           
       

 
    end generate SINGLES_ONLY_SUPPORT;
       
       
       
       
 
 ------------------------------------------------------------
 -- If Generate
 --
 -- Label: INCLUDE_BURST_SUPPORT
 --
 -- If Generate Description:
 --     This IfGen instantiates a PLBV46 Slave Attachment
 -- which incorporates singles, fixed length bursts, and
 -- cacheline transfers. It may also have a Native DWIDTH of
 -- 32, 64, and 128 bits.
 --
 --
 ------------------------------------------------------------
 INCLUDE_BURST_SUPPORT : if (C_SPLB_SUPPORT_BURSTS = 1 or
                             C_SPLB_NATIVE_DWIDTH > 32) generate
 
    -- Local Constants
    
   -- PLBV46 Slave Standard IPIF ARD Array overloads --------------------------------------------
                                    
     constant ARD_ADDR_RANGE_ARRAY   : SLV64_ARRAY_TYPE :=
             (
              ZERO_BADDR_PAD & C_BASEADDR ,   -- BRAM Base Address
              ZERO_HADDR_PAD & C_HIGHADDR     -- BRAM High Address
             );
 
      
 -- Cacheline read address mode
     Constant CACHLINE_ADDR_MODE : integer := 0; -- Legacy mode
       -- Selects the addressing mode to use for Cacheline Read
       -- operations.
       -- 0 = Legacy Read mode (target word first)
       -- 1 = Realign target word address to Cacheline aligned and
       --     then do a linear incrementing addressing from start  
       --     to end of the Cacheline (PCI Bridge enhancement).
   
   
     Constant STEER_ADDR_SIZE : integer := 5;
    
    
    
    begin
 
 
     -------------------------------------------------------------
     -- Combinational Process
     --
     -- Label: GEN_WR_ENABLES
     --
     -- Process Description:
     --     This process generates the BRAM write enable controls
     -- based on the number of byte enables available.
     --
     -------------------------------------------------------------
     GEN_WR_ENABLES : process (sig_bus2ip_be,
                               sig_bus2ip_wrreq)
        begin
     
           for be_index in 0 to NUM_BRAM_BE-1 loop
           
             sig_bram_wr_enable(be_index) <= sig_bus2ip_be(be_index) and 
                                             sig_bus2ip_wrreq;
                  
           end loop;
     
        end process GEN_WR_ENABLES; 
     
     
      
     
      
      
     -- Instantiate the Slave Burst Attachnebt using direct entity instantiation
      
      I_SLAVE_BURST_ATTACH : entity xps_bram_if_cntlr_v1_00_b.xbic_slave_attach_burst
        generic map (
          
          --C_STEER_ADDR_SIZE        =>  STEER_ADDR_SIZE,
          C_ARD_ADDR_RANGE_ARRAY   =>  ARD_ADDR_RANGE_ARRAY, 
          C_SPLB_NUM_MASTERS       =>  C_SPLB_NUM_MASTERS, 
          C_SPLB_MID_WIDTH         =>  C_SPLB_MID_WIDTH, 
          C_SPLB_P2P               =>  C_SPLB_P2P, 
          C_SPLB_AWIDTH            =>  C_SPLB_AWIDTH, 
          C_SPLB_DWIDTH            =>  C_SPLB_DWIDTH, 
          C_SPLB_NATIVE_DWIDTH     =>  C_SPLB_NATIVE_DWIDTH, 
          C_SPLB_SMALLEST_MASTER   =>  C_SPLB_SMALLEST_MASTER, 
          C_CACHLINE_ADDR_MODE     =>  CACHLINE_ADDR_MODE, 
          C_FAMILY                 =>  C_FAMILY 
          )                        
        port map (
      
        -- System signals ------------------------------------------------
                              
            Bus_Rst          =>  SPLB_Rst   ,
            Bus_Clk          =>  SPLB_Clk   ,
            
            
        -- PLBV46 Slave input signals ------------------------------------
        
            PLB_ABus          =>  PLB_ABus        ,
            PLB_UABus         =>  PLB_UABus       ,
            PLB_PAValid       =>  PLB_PAValid     ,
            PLB_masterID      =>  PLB_masterID    ,
            PLB_RNW           =>  PLB_RNW         ,
            PLB_BE            =>  PLB_BE          ,
            PLB_MSize         =>  PLB_MSize       ,
            PLB_size          =>  PLB_size        ,
            PLB_type          =>  PLB_type        ,
            PLB_wrDBus        =>  PLB_wrDBus      ,
            PLB_wrBurst       =>  PLB_wrBurst     ,
            PLB_rdBurst       =>  PLB_rdBurst     ,
            
         -- PLBV46 Slave reply signals   
            Sl_SSize          =>  Sl_SSize        ,
            Sl_addrAck        =>  Sl_addrAck      ,
            Sl_wait           =>  Sl_wait         ,
            Sl_rearbitrate    =>  Sl_rearbitrate  ,
            Sl_wrDAck         =>  Sl_wrDAck       ,
            Sl_wrComp         =>  Sl_wrComp       ,
            Sl_wrBTerm        =>  Sl_wrBTerm      ,
            Sl_rdDBus         =>  Sl_rdDBus       ,
            Sl_rdWdAddr       =>  Sl_rdWdAddr     ,
            Sl_rdDAck         =>  Sl_rdDAck       ,
            Sl_rdComp         =>  Sl_rdComp       ,
            Sl_rdBTerm        =>  Sl_rdBTerm      ,
            Sl_MBusy          =>  Sl_MBusy        ,
            Sl_MWrErr         =>  Sl_MWrErr       ,
            Sl_MRdErr         =>  Sl_MRdErr       ,
            
 
                    
         -- BRAM Interconnect port signals ---------------------------
            
            -- Controls to the IP/IPIF modules
            Bus2Bram_CS           =>  sig_bus2ip_cs    ,  
            Bus2Bram_WrReq        =>  sig_bus2ip_wrreq ,  
            Bus2Bram_RdReq        =>  sig_bus2ip_rdreq ,  
            Bus2Bram_Addr         =>  sig_bus2ip_addr  ,  
            Bus2Bram_BE           =>  sig_bus2ip_be    ,  
            Bus2Bram_WrData       =>  sig_bus2ip_data  ,  

            -- Inputs from the BRAM interface logic
            Bram2Bus_RdData       =>  sig_ip2bus_data ,  
            Bram2Bus_WrAck        =>  '0',  -- unused
            Bram2Bus_RdAck        =>  '0'  -- unused

               
          );
 
      
 
    end generate INCLUDE_BURST_SUPPORT;





    
end implementation;