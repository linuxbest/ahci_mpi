-------------------------------------------------------------------------------
-- plbv46_pim_wrapper.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2008 by Xilinx, Inc. All rights reserved.               **
--  **                                                                       **
--  **  This text contains proprietary, confidential                         **
--  **  information of Xilinx, Inc. , is distributed by                      **
--  **  under license from Xilinx, Inc., and may be used,                    **
--  **  copied and/or disclosed only pursuant to the terms                   **
--  **  of a valid license agreement with Xilinx, Inc.                       **
--  **                                                                       **
--  **  Unmodified source code is guaranteed to place and route,             **
--  **  function and run at speed according to the datasheet                 **
--  **  specification. Source code is provided "as-is", with no              **
--  **  obligation on the part of Xilinx to provide support.                 **
--  **                                                                       **
--  **  Xilinx Hotline support of source code IP shall only include          **
--  **  standard level Xilinx Hotline support, and will only address         **
--  **  issues and questions related to the standard released Netlist        **
--  **  version of the core (and thus indirectly, the original core source). **
--  **                                                                       **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Support Hotline will only be able          **
--  **  to confirm the problem in the Netlist version of the core.           **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        plbv46_pim_wrapper.vhd
-- Version:         v2.04.a
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Author:      TK
-- History:
--  TK        04/5/2007      - Initial Version
--
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Structure:   --plbv46_pim_wrapper.vhd
--                  |-- plbv46_pim.vhd                  
--                      |--addr_decoder.vhd
--                         |--sample_cycle.vhd
--                      |--write_module.vhd 
--                      |--rd_support.vhd
--                         |--data_steer_mirror.vhd
-------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;   
          
library mpmc_v6_03_a;
use mpmc_v6_03_a.all;   
                                                                  
entity plbv46_pim_wrapper is
   generic (
                                  
         --PLB to PIM generics                                                                          
         C_SPLB_DWIDTH                      : integer range 32 to 128 := 64;          
         C_SPLB_NATIVE_DWIDTH               : integer range 32 to 128 := 64;          
         C_SPLB_AWIDTH                      : integer                 := 32;          
         C_SPLB_NUM_MASTERS                 : integer range 1 to 16   := 8;
         C_SPLB_MID_WIDTH                   : integer range 0 to 4    := 3;
         C_SPLB_P2P                         : integer range 0 to 1    := 0;
         C_SPLB_SUPPORT_BURSTS              : integer range 0 to 1    := 0;
         C_SPLB_SMALLEST_MASTER             : integer range 32 to 128 := 128;
         
         C_PLBV46_PIM_TYPE                  : string                  := "INACTIVE"; --PLB,DSPLB,ISPLB,INACTIVE
                                                                      
         --MPMC generics                                              
         C_MPMC_PIM_BASEADDR                : integer := 0;
         C_MPMC_PIM_HIGHADDR                : integer := 0;
         C_MPMC_PIM_OFFSET                  : integer := 0;
         C_MPMC_PIM_DATA_WIDTH              : integer range 32 to 64  := 64;
         C_MPMC_PIM_ADDR_WIDTH              : integer                 := 32; 
         C_MPMC_PIM_RDFIFO_LATENCY          : integer range 0 to 2    := 0; 
         C_MPMC_PIM_RDWDADDR_WIDTH          : integer                 := 4;       
         C_MPMC_PIM_SDR_DWIDTH              : integer range 8 to 128  := 128;
         C_MPMC_PIM_MEM_HAS_BE              : integer range 0 to 1    := 1;
         C_MPMC_PIM_WR_FIFO_TYPE            : string                  := "BRAM";--BRAM, SRL
         C_MPMC_PIM_RD_FIFO_TYPE            : string                  := "BRAM";--BRAM, SRL
                                                                      
         --Misc Generics                                              
         C_FAMILY                           : string                  := "virtex4"     
         
     );
     port (    
         MPMC_CLK                           : in    std_logic;   
         MPMC_Rst                           : in    std_logic;
         SPLB_RST                           : in    std_logic;                                                                                            
         SPLB_Clk                           : in    std_logic;
                
         SPLB_PLB_ABus                      : in    std_logic_vector (0 to C_SPLB_AWIDTH-1);                        
         SPLB_PLB_UABus                     : in    std_logic_vector (0 to C_SPLB_AWIDTH-1);        -- (Note: Unused)
         SPLB_PLB_PAValid                   : in    std_logic;                                                       
         SPLB_PLB_SAValid                   : in    std_logic;                                      
         SPLB_PLB_rdPrim                    : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_wrPrim                    : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_masterID                  : in    std_logic_vector (0 to C_SPLB_MID_WIDTH-1);                     
         SPLB_PLB_abort                     : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_busLock                   : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_RNW                       : in    std_logic;                                                       
         SPLB_PLB_BE                        : in    std_logic_vector (0 to (C_SPLB_DWIDTH/8)-1);                    
         
         SPLB_PLB_MSize                     : in    std_logic_vector (0 to 1);                      
         SPLB_PLB_size                      : in    std_logic_vector (0 to 3);  --PLB transfer size word,dw,qwd              
         SPLB_PLB_type                      : in    std_logic_vector (0 to 2);  --always 000 - memory transfer
         SPLB_PLB_lockErr                   : in    std_logic;                                      -- (Note: Unused)
         
         SPLB_PLB_wrDBus                    : in    std_logic_vector (0 to C_SPLB_DWIDTH-1);                        
         SPLB_PLB_wrBurst                   : in    std_logic;                                                       
         SPLB_PLB_rdBurst                   : in    std_logic;                                                       
         SPLB_PLB_wrPendReq                 : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_rdPendReq                 : in    std_logic;                                      -- (Note: Unused)
         SPLB_PLB_rdPendPri                 : in    std_logic_vector (0 to 1);                      -- (Note: Unused)
         SPLB_PLB_wrPendPri                 : in    std_logic_vector (0 to 1);                      -- (Note: Unused)
         SPLB_PLB_reqPri                    : in    std_logic_vector (0 to 1);                      -- (Note: Unused)
         SPLB_PLB_TAttribute                : in    std_logic_vector (0 to 15);                     -- (Note: Unused)

         SPLB_Sl_addrAck                    : out   std_logic;                                                       
         SPLB_Sl_SSize                      : out   std_logic_vector (0 to 1);                                       
         SPLB_Sl_wait                       : out   std_logic;                                                       
         SPLB_Sl_rearbitrate                : out   std_logic;                                                       
         SPLB_Sl_wrDack                     : out   std_logic;                                                       
         SPLB_Sl_wrComp                     : out   std_logic;                                                       
         SPLB_Sl_wrBTerm                    : out   std_logic;     
         SPLB_Sl_rdDBus                     : out   std_logic_vector (0 to C_SPLB_DWIDTH-1);                        

         SPLB_Sl_rdWdAddr                   : out   std_logic_vector (0 to 3);                      
         SPLB_Sl_rdDAck                     : out   std_logic;                                                       
         SPLB_Sl_rdComp                     : out   std_logic;                                                       
         SPLB_Sl_rdBTerm                    : out   std_logic;                                                       
         SPLB_Sl_MBusy                      : out   std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);                   
         SPLB_Sl_MRdErr                     : out   std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);  -- (Note: Unused)                 
         SPLB_Sl_MWrErr                     : out   std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);  -- (Note: Unused)                
         SPLB_Sl_MIRQ                       : out   std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);  -- (Note: Unused)
                      
         MPMC_PIM_InitDone                  : in    std_logic;                      
         MPMC_PIM_Addr                      : out   std_logic_vector(C_MPMC_PIM_ADDR_WIDTH-1 downto 0); 
         MPMC_PIM_AddrReq                   : out   std_logic; 
         MPMC_PIM_AddrAck                   : in    std_logic;                                                    
         MPMC_PIM_RNW                       : out   std_logic; 
         MPMC_PIM_Size                      : out   std_logic_vector(3 downto 0);
                                                                    
         MPMC_PIM_WrFIFO_Data               : out   std_logic_vector(C_MPMC_PIM_DATA_WIDTH-1 downto 0);
         MPMC_PIM_WrFIFO_BE                 : out   std_logic_vector(C_MPMC_PIM_DATA_WIDTH/8-1 downto 0);
         MPMC_PIM_WrFIFO_Push               : out   std_logic;
         MPMC_PIM_WrFIFO_Empty              : in    std_logic;
         MPMC_PIM_WrFIFO_AlmostFull         : in    std_logic;                       
                 
         MPMC_PIM_RdFIFO_Latency            : in    std_logic_vector(1 downto 0);                            
         MPMC_PIM_RdFIFO_Data               : in    std_logic_vector(C_MPMC_PIM_DATA_WIDTH-1 downto 0);
         MPMC_PIM_RdFIFO_Pop                : out   std_logic;                       
         MPMC_PIM_RdFIFO_Empty              : in    std_logic; 
         MPMC_PIM_RdFIFO_RdWd_Addr          : in    std_logic_vector(C_MPMC_PIM_RDWDADDR_WIDTH-1 downto 0);
                                             
         MPMC_PIM_RdFIFO_Data_Available     : in    std_logic;
         MPMC_PIM_RdFIFO_Flush              : out   std_logic;
         MPMC_PIM_WrFIFO_Flush              : out   std_logic;
         
         MPMC_PIM_RdModWr                   : out   std_logic
           
     
     );

end plbv46_pim_wrapper;

architecture rtl_pim of plbv46_pim_wrapper is
                       
--Constant declarations
                        
begin

comp_plbv46_pim : entity mpmc_v6_03_a.plbv46_pim
   generic map(
         C_SPLB_DWIDTH                      => C_SPLB_DWIDTH             , 
         C_SPLB_NATIVE_DWIDTH               => C_SPLB_NATIVE_DWIDTH      , 
         C_SPLB_AWIDTH                      => C_SPLB_AWIDTH             , 
         C_SPLB_NUM_MASTERS                 => C_SPLB_NUM_MASTERS        , 
         C_SPLB_MID_WIDTH                   => C_SPLB_MID_WIDTH          , 
         C_SPLB_P2P                         => C_SPLB_P2P                , 
         C_SPLB_SUPPORT_BURSTS              => C_SPLB_SUPPORT_BURSTS     , 
         C_SPLB_SMALLEST_MASTER             => C_SPLB_SMALLEST_MASTER    , 
         C_PLBV46_PIM_TYPE                  => C_PLBV46_PIM_TYPE         , 
         C_MPMC_PIM_BASEADDR                => conv_std_logic_vector(C_MPMC_PIM_BASEADDR, 30) & "00"       ,
         C_MPMC_PIM_HIGHADDR                => conv_std_logic_vector(C_MPMC_PIM_HIGHADDR, 30) & "11"       , 
         C_MPMC_PIM_OFFSET                  => conv_std_logic_vector(C_MPMC_PIM_OFFSET, 30) & "00"         , 
         C_MPMC_PIM_DATA_WIDTH              => C_MPMC_PIM_DATA_WIDTH     , 
         C_MPMC_PIM_ADDR_WIDTH              => C_MPMC_PIM_ADDR_WIDTH     , 
         C_MPMC_PIM_RDFIFO_LATENCY          => C_MPMC_PIM_RDFIFO_LATENCY , 
         C_MPMC_PIM_RDWDADDR_WIDTH          => C_MPMC_PIM_RDWDADDR_WIDTH , 
         C_MPMC_PIM_SDR_DWIDTH              => C_MPMC_PIM_SDR_DWIDTH     ,
         C_MPMC_PIM_MEM_HAS_BE              => C_MPMC_PIM_MEM_HAS_BE     ,
         C_MPMC_PIM_WR_FIFO_TYPE            => C_MPMC_PIM_WR_FIFO_TYPE   ,
         C_MPMC_PIM_RD_FIFO_TYPE            => C_MPMC_PIM_RD_FIFO_TYPE   ,
         C_FAMILY                           => C_FAMILY
     )
     port map(    
         MPMC_CLK                           => MPMC_CLK                        , 
         MPMC_Rst                           => MPMC_Rst                        , 
         SPLB_RST                           => SPLB_RST                        , 
         SPLB_Clk                           => SPLB_Clk                        , 
         SPLB_PLB_ABus                      => SPLB_PLB_ABus                   , 
         SPLB_PLB_UABus                     => SPLB_PLB_UABus                  , 
         SPLB_PLB_PAValid                   => SPLB_PLB_PAValid                , 
         SPLB_PLB_SAValid                   => SPLB_PLB_SAValid                , 
         SPLB_PLB_rdPrim                    => SPLB_PLB_rdPrim                 , 
         SPLB_PLB_wrPrim                    => SPLB_PLB_wrPrim                 , 
         SPLB_PLB_masterID                  => SPLB_PLB_masterID               , 
         SPLB_PLB_abort                     => SPLB_PLB_abort                  , 
         SPLB_PLB_busLock                   => SPLB_PLB_busLock                , 
         SPLB_PLB_RNW                       => SPLB_PLB_RNW                    , 
         SPLB_PLB_BE                        => SPLB_PLB_BE                     , 
         SPLB_PLB_MSize                     => SPLB_PLB_MSize                  , 
         SPLB_PLB_size                      => SPLB_PLB_size                   ,  
         SPLB_PLB_type                      => SPLB_PLB_type                   , 
         SPLB_PLB_lockErr                   => SPLB_PLB_lockErr                , 
         SPLB_PLB_wrDBus                    => SPLB_PLB_wrDBus                 , 
         SPLB_PLB_wrBurst                   => SPLB_PLB_wrBurst                , 
         SPLB_PLB_rdBurst                   => SPLB_PLB_rdBurst                , 
         SPLB_PLB_wrPendReq                 => SPLB_PLB_wrPendReq              , 
         SPLB_PLB_rdPendReq                 => SPLB_PLB_rdPendReq              , 
         SPLB_PLB_rdPendPri                 => SPLB_PLB_rdPendPri              , 
         SPLB_PLB_wrPendPri                 => SPLB_PLB_wrPendPri              , 
         SPLB_PLB_reqPri                    => SPLB_PLB_reqPri                 , 
         SPLB_PLB_TAttribute                => SPLB_PLB_TAttribute             , 
         SPLB_Sl_addrAck                    => SPLB_Sl_addrAck                 , 
         SPLB_Sl_SSize                      => SPLB_Sl_SSize                   , 
         SPLB_Sl_wait                       => SPLB_Sl_wait                    , 
         SPLB_Sl_rearbitrate                => SPLB_Sl_rearbitrate             , 
         SPLB_Sl_wrDack                     => SPLB_Sl_wrDack                  , 
         SPLB_Sl_wrComp                     => SPLB_Sl_wrComp                  , 
         SPLB_Sl_wrBTerm                    => SPLB_Sl_wrBTerm                 , 
         SPLB_Sl_rdDBus                     => SPLB_Sl_rdDBus                  , 
         SPLB_Sl_rdWdAddr                   => SPLB_Sl_rdWdAddr                , 
         SPLB_Sl_rdDAck                     => SPLB_Sl_rdDAck                  , 
         SPLB_Sl_rdComp                     => SPLB_Sl_rdComp                  , 
         SPLB_Sl_rdBTerm                    => SPLB_Sl_rdBTerm                 , 
         SPLB_Sl_MBusy                      => SPLB_Sl_MBusy                   , 
         SPLB_Sl_MRdErr                     => SPLB_Sl_MRdErr                  ,          
         SPLB_Sl_MWrErr                     => SPLB_Sl_MWrErr                  ,         
         SPLB_Sl_MIRQ                       => SPLB_Sl_MIRQ                    , 
         MPMC_PIM_InitDone                  => MPMC_PIM_InitDone               , 
         MPMC_PIM_Addr                      => MPMC_PIM_Addr                   , 
         MPMC_PIM_AddrReq                   => MPMC_PIM_AddrReq                , 
         MPMC_PIM_AddrAck                   => MPMC_PIM_AddrAck                , 
         MPMC_PIM_RNW                       => MPMC_PIM_RNW                    , 
         MPMC_PIM_Size                      => MPMC_PIM_Size                   , 
         MPMC_PIM_WrFIFO_Data               => MPMC_PIM_WrFIFO_Data            , 
         MPMC_PIM_WrFIFO_BE                 => MPMC_PIM_WrFIFO_BE              , 
         MPMC_PIM_WrFIFO_Push               => MPMC_PIM_WrFIFO_Push            , 
         MPMC_PIM_WrFIFO_Empty              => MPMC_PIM_WrFIFO_Empty           , 
         MPMC_PIM_WrFIFO_AlmostFull         => MPMC_PIM_WrFIFO_AlmostFull      , 
         MPMC_PIM_RdFIFO_Latency            => MPMC_PIM_RdFIFO_Latency         , 
         MPMC_PIM_RdFIFO_Data               => MPMC_PIM_RdFIFO_Data            , 
         MPMC_PIM_RdFIFO_Pop                => MPMC_PIM_RdFIFO_Pop             , 
         MPMC_PIM_RdFIFO_Empty              => MPMC_PIM_RdFIFO_Empty           , 
         MPMC_PIM_RdFIFO_RdWd_Addr          => MPMC_PIM_RdFIFO_RdWd_Addr       , 
         MPMC_PIM_RdFIFO_Data_Available     => MPMC_PIM_RdFIFO_Data_Available  , 
         MPMC_PIM_RdFIFO_Flush              => MPMC_PIM_RdFIFO_Flush           , 
         MPMC_PIM_WrFIFO_Flush              => MPMC_PIM_WrFIFO_Flush           , 
         MPMC_PIM_RdModWr                   => MPMC_PIM_RdModWr                 
           
     
     );

end rtl_pim;
