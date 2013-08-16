------------------------------------------------------------------------------
-- mpmc_ctrl_if.vhd - entity/architecture pair
------------------------------------------------------------------------------
-- ***************************************************************************
-- ** Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          mpmc_ctrl_if.vhd
-- Version:           1.00.a
-- Description:       Top level design, instantiates library components and user logic.
-- Date:              Mon Jul  2 14:27:26 2007 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library plbv46_slave_single_v1_01_a;
use plbv46_slave_single_v1_01_a.plbv46_slave_single;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_BASEADDR                   -- PLBv46 slave: base address
--   C_HIGHADDR                   -- PLBv46 slave: high address
--   C_SPLB_AWIDTH                -- PLBv46 slave: address bus width
--   C_SPLB_DWIDTH                -- PLBv46 slave: data bus width
--   C_SPLB_NUM_MASTERS           -- PLBv46 slave: Number of masters
--   C_SPLB_MID_WIDTH             -- PLBv46 slave: master ID bus width
--   C_SPLB_NATIVE_DWIDTH         -- PLBv46 slave: internal native data bus width
--   C_SPLB_P2P                   -- PLBv46 slave: point to point interconnect scheme
--   C_SPLB_SUPPORT_BURSTS        -- PLBv46 slave: support bursts
--   C_SPLB_SMALLEST_MASTER       -- PLBv46 slave: width of the smallest master
--   C_SPLB_CLK_PERIOD_PS         -- PLBv46 slave: bus clock in picoseconds
--   C_FAMILY                     -- Xilinx FPGA family
--
-- Definition of Ports:
--   SPLB_Clk                     -- PLB main bus clock
--   SPLB_Rst                     -- PLB main bus reset
--   PLB_ABus                     -- PLB address bus
--   PLB_UABus                    -- PLB upper address bus
--   PLB_PAValid                  -- PLB primary address valid indicator
--   PLB_SAValid                  -- PLB secondary address valid indicator
--   PLB_rdPrim                   -- PLB secondary to primary read request indicator
--   PLB_wrPrim                   -- PLB secondary to primary write request indicator
--   PLB_masterID                 -- PLB current master identifier
--   PLB_abort                    -- PLB abort request indicator
--   PLB_busLock                  -- PLB bus lock
--   PLB_RNW                      -- PLB read/not write
--   PLB_BE                       -- PLB byte enables
--   PLB_MSize                    -- PLB master data bus size
--   PLB_size                     -- PLB transfer size
--   PLB_type                     -- PLB transfer type
--   PLB_lockErr                  -- PLB lock error indicator
--   PLB_wrDBus                   -- PLB write data bus
--   PLB_wrBurst                  -- PLB burst write transfer indicator
--   PLB_rdBurst                  -- PLB burst read transfer indicator
--   PLB_wrPendReq                -- PLB write pending bus request indicator
--   PLB_rdPendReq                -- PLB read pending bus request indicator
--   PLB_wrPendPri                -- PLB write pending request priority
--   PLB_rdPendPri                -- PLB read pending request priority
--   PLB_reqPri                   -- PLB current request priority
--   PLB_TAttribute               -- PLB transfer attribute
--   Sl_addrAck                   -- Slave address acknowledge
--   Sl_SSize                     -- Slave data bus size
--   Sl_wait                      -- Slave wait indicator
--   Sl_rearbitrate               -- Slave re-arbitrate bus indicator
--   Sl_wrDAck                    -- Slave write data acknowledge
--   Sl_wrComp                    -- Slave write transfer complete indicator
--   Sl_wrBTerm                   -- Slave terminate write burst transfer
--   Sl_rdDBus                    -- Slave read data bus
--   Sl_rdWdAddr                  -- Slave read word address
--   Sl_rdDAck                    -- Slave read data acknowledge
--   Sl_rdComp                    -- Slave read transfer complete indicator
--   Sl_rdBTerm                   -- Slave terminate read burst transfer
--   Sl_MBusy                     -- Slave busy indicator
--   Sl_MWrErr                    -- Slave write error indicator
--   Sl_MRdErr                    -- Slave read error indicator
--   Sl_MIRQ                      -- Slave interrupt indicator
------------------------------------------------------------------------------

entity mpmc_ctrl_if is
  generic
  (
    C_ECC_NUM_REG                  : integer              := 10;
    C_STATIC_PHY_NUM_REG           : integer              := 1;
    C_MPMC_STATUS_NUM_REG          : integer              := 1;
    C_PM_CTRL_NUM_REG              : integer              := 11;
    C_ECC_REG_BASEADDR             : integer;
    C_ECC_REG_HIGHADDR             : integer;
    C_STATIC_PHY_REG_BASEADDR      : integer;
    C_STATIC_PHY_REG_HIGHADDR      : integer;
    C_DEBUG_CTRL_MEM_BASEADDR      : integer;
    C_DEBUG_CTRL_MEM_HIGHADDR      : integer;
    C_MPMC_STATUS_REG_BASEADDR     : integer;
    C_MPMC_STATUS_REG_HIGHADDR     : integer;
    C_PM_CTRL_REG_BASEADDR         : integer;
    C_PM_CTRL_REG_HIGHADDR         : integer;
    C_PM_DATA_MEM_BASEADDR         : integer;
    C_PM_DATA_MEM_HIGHADDR         : integer;
    -- Bus protocol parameters
    C_SPLB_AWIDTH                  : integer              := 32;
    C_SPLB_DWIDTH                  : integer              := 128;
    C_SPLB_NUM_MASTERS             : integer              := 8;
    C_SPLB_MID_WIDTH               : integer              := 3;
    C_SPLB_NATIVE_DWIDTH           : integer              := 32;
    C_SPLB_P2P                     : integer              := 0;
    C_SPLB_SUPPORT_BURSTS          : integer              := 0;
    C_SPLB_SMALLEST_MASTER         : integer              := 32;
    C_SPLB_CLK_PERIOD_PS           : integer              := 10000;
    C_FAMILY                       : string               := "virtex5"
  );
  port
  (
    MPMC_Clk                       : in std_logic;
    ECC_Reg_CE                     : out std_logic_vector(C_ECC_NUM_REG-1 downto 0);
    ECC_Reg_In                     : out std_logic_vector(31 downto 0);
    ECC_Reg_Out                    : in  std_logic_vector(C_ECC_NUM_REG*32-1 downto 0);
    Static_Phy_Reg_CE              : out std_logic_vector(C_STATIC_PHY_NUM_REG-1 downto 0);
    Static_Phy_Reg_In              : out std_logic_vector(31 downto 0);
    Static_Phy_Reg_Out             : in  std_logic_vector(C_STATIC_PHY_NUM_REG*32-1 downto 0);
    Debug_Ctrl_Addr                : out std_logic_vector(31 downto 0);
    Debug_Ctrl_WE                  : out std_logic;
    Debug_Ctrl_In                  : out std_logic_vector(31 downto 0);
    Debug_Ctrl_Out                 : in  std_logic_vector(31 downto 0);
    MPMC_Status_Reg_CE             : out std_logic_vector(C_MPMC_STATUS_NUM_REG-1 downto 0);
    MPMC_Status_Reg_In             : out std_logic_vector(31 downto 0);
    MPMC_Status_Reg_Out            : in  std_logic_vector(C_MPMC_STATUS_NUM_REG*32-1 downto 0);
    PM_Ctrl_Reg_CE                 : out std_logic_vector(C_PM_CTRL_NUM_REG-1 downto 0);
    PM_Ctrl_Reg_In                 : out std_logic_vector(31 downto 0);
    PM_Ctrl_Reg_Out                : in  std_logic_vector(C_PM_CTRL_NUM_REG*32-1 downto 0);
    PM_Data_Out                    : in  std_logic_vector(31 downto 0);
    PM_Data_Addr                   : out std_logic_vector(31 downto 0);
    SPLB_Clk                       : in  std_logic;
    SPLB_Rst                       : in  std_logic;
    PLB_ABus                       : in  std_logic_vector(0 to 31);
    PLB_UABus                      : in  std_logic_vector(0 to 31);
    PLB_PAValid                    : in  std_logic;
    PLB_SAValid                    : in  std_logic;
    PLB_rdPrim                     : in  std_logic;
    PLB_wrPrim                     : in  std_logic;
    PLB_masterID                   : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_abort                      : in  std_logic;
    PLB_busLock                    : in  std_logic;
    PLB_RNW                        : in  std_logic;
    PLB_BE                         : in  std_logic_vector(0 to C_SPLB_DWIDTH/8-1);
    PLB_MSize                      : in  std_logic_vector(0 to 1);
    PLB_size                       : in  std_logic_vector(0 to 3);
    PLB_type                       : in  std_logic_vector(0 to 2);
    PLB_lockErr                    : in  std_logic;
    PLB_wrDBus                     : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst                    : in  std_logic;
    PLB_rdBurst                    : in  std_logic;
    PLB_wrPendReq                  : in  std_logic;
    PLB_rdPendReq                  : in  std_logic;
    PLB_wrPendPri                  : in  std_logic_vector(0 to 1);
    PLB_rdPendPri                  : in  std_logic_vector(0 to 1);
    PLB_reqPri                     : in  std_logic_vector(0 to 1);
    PLB_TAttribute                 : in  std_logic_vector(0 to 15);
    Sl_addrAck                     : out std_logic;
    Sl_SSize                       : out std_logic_vector(0 to 1);
    Sl_wait                        : out std_logic;
    Sl_rearbitrate                 : out std_logic;
    Sl_wrDAck                      : out std_logic;
    Sl_wrComp                      : out std_logic;
    Sl_wrBTerm                     : out std_logic;
    Sl_rdDBus                      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr                    : out std_logic_vector(0 to 3);
    Sl_rdDAck                      : out std_logic;
    Sl_rdComp                      : out std_logic;
    Sl_rdBTerm                     : out std_logic;
    Sl_MBusy                       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MIRQ                        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)
  );

  attribute SIGIS : string;
  attribute SIGIS of MPMC_Clk      : signal is "CLK";
  attribute SIGIS of SPLB_Clk      : signal is "CLK";
  attribute SIGIS of SPLB_Rst      : signal is "RST";

end entity mpmc_ctrl_if;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of mpmc_ctrl_if is

  ------------------------------------------
  -- Array of base/high address pairs for each address range
  ------------------------------------------
  constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 31) := (others => '0');

  constant IPIF_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE     := 
    (
      ZERO_ADDR_PAD & conv_std_logic_vector(C_ECC_REG_BASEADDR, 32),           -- user logic slave space base address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_ECC_REG_HIGHADDR, 32),           -- user logic slave space high address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_STATIC_PHY_REG_BASEADDR, 32),    -- user logic memory space 0 base address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_STATIC_PHY_REG_HIGHADDR, 32),    -- user logic memory space 0 high address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_DEBUG_CTRL_MEM_BASEADDR, 32),    -- user logic memory space 1 base address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_DEBUG_CTRL_MEM_HIGHADDR, 32),    -- user logic memory space 1 high address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_MPMC_STATUS_REG_BASEADDR, 32),   -- user logic memory space 2 base address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_MPMC_STATUS_REG_HIGHADDR, 32),   -- user logic memory space 2 high address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_PM_CTRL_REG_BASEADDR, 32),       -- user logic memory space 3 base address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_PM_CTRL_REG_HIGHADDR, 32),       -- user logic memory space 3 high address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_PM_DATA_MEM_BASEADDR, 32),       -- user logic memory space 4 base address
      ZERO_ADDR_PAD & conv_std_logic_vector(C_PM_DATA_MEM_HIGHADDR, 32)        -- user logic memory space 4 high address
    );

  ------------------------------------------
  -- Array of desired number of chip enables for each address range
  ------------------------------------------
  --constant C_ECC_NUM_REG                  : integer              := 10;
  --constant C_STATIC_PHY_NUM_REG           : integer              := 1;
  --constant C_PM_CTRL_NUM_REG              : integer              := 11;
  constant USER_NUM_REG                   : integer              := C_ECC_NUM_REG + C_STATIC_PHY_NUM_REG + C_MPMC_STATUS_NUM_REG + C_PM_CTRL_NUM_REG;
  constant USER_NUM_MEM                   : integer              := 6;  -- ECC, STATIC PHY, DEBUG, MPMC_STATUS, PM_CTRL, PM_DATA

  constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   := 
    (
      0  => pad_power2(C_ECC_NUM_REG),    -- number of ce for user logic slave space
      1  => pad_power2(C_STATIC_PHY_NUM_REG),    -- number of ce for user logic slave space
      2  => 0,                                  -- number of ce for user logic slave space (DEBUG_CTRL)
      3  => pad_power2(C_MPMC_STATUS_NUM_REG),   -- number of ce for user logic slave space
      4  => pad_power2(C_PM_CTRL_NUM_REG),    -- number of ce for user logic slave space
      5  => 0                             -- number of ce for user logic memory space 3 (PM_DATA)
    );

  ------------------------------------------
  -- Ratio of bus clock to core clock (for use in dual clock systems)
  -- 1 = ratio is 1:1
  -- 2 = ratio is 2:1
  ------------------------------------------
  constant IPIF_BUS2CORE_CLK_RATIO        : integer              := 1;

  ------------------------------------------
  -- Width of the slave data bus (32 only)
  ------------------------------------------
  constant USER_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  constant IPIF_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Width of the slave address bus (32 only)
  ------------------------------------------
  constant USER_SLV_AWIDTH                : integer              := C_SPLB_AWIDTH;

  ------------------------------------------
  -- Index for CS/CE
  ------------------------------------------
  constant USER_SLV_CS_INDEX              : integer              := 0;
  constant USER_SLV_CE_INDEX              : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, USER_SLV_CS_INDEX);
  constant USER_MEM0_CS_INDEX             : integer              := 1;
  constant USER_CS_INDEX                  : integer              := USER_MEM0_CS_INDEX;

  constant USER_CE_INDEX                  : integer              := USER_SLV_CE_INDEX;

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations
  ------------------------------------------
  signal ipif_Bus2IP_Clk                : std_logic;
  signal ipif_Bus2IP_Reset              : std_logic;
  signal ipif_IP2Bus_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_IP2Bus_WrAck              : std_logic;
  signal ipif_IP2Bus_RdAck              : std_logic;
  signal ipif_IP2Bus_Error              : std_logic;
  signal ipif_Bus2IP_Addr               : std_logic_vector(0 to C_SPLB_AWIDTH-1);
  signal ipif_Bus2IP_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_Bus2IP_RNW                : std_logic;
  signal ipif_Bus2IP_BE                 : std_logic_vector(0 to IPIF_SLV_DWIDTH/8-1);
  signal ipif_Bus2IP_CS                 : std_logic_vector(0 to ((IPIF_ARD_ADDR_RANGE_ARRAY'length)/2)-1);
  signal ipif_Bus2IP_RdCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal ipif_Bus2IP_WrCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal user_Bus2IP_RdCE               : std_logic_vector(0 to USER_NUM_REG-1);
  signal user_Bus2IP_WrCE               : std_logic_vector(0 to USER_NUM_REG-1);
  signal user_IP2Bus_Data               : std_logic_vector(0 to USER_SLV_DWIDTH-1);
  signal user_IP2Bus_RdAck              : std_logic;
  signal user_IP2Bus_WrAck              : std_logic;
  signal user_IP2Bus_Error              : std_logic;

  ------------------------------------------
  -- Component declaration for verilog user logic
  ------------------------------------------
  component mpmc_ctrl_logic is
    generic
    (
      C_ECC_NUM_REG                  : integer              := 10;
      C_STATIC_PHY_NUM_REG           : integer              := 1;
      C_MPMC_STATUS_NUM_REG          : integer              := 1;
      C_PM_CTRL_NUM_REG              : integer              := 11;
      C_SLV_AWIDTH                   : integer              := 32;
      C_SLV_DWIDTH                   : integer              := 32;
      C_NUM_REG                      : integer              := 1;
      C_NUM_MEM                      : integer              := 1
    );
    port
    (
      MPMC_Clk                       : in  std_logic;
      ECC_Reg_CE                     : out std_logic_vector(C_ECC_NUM_REG-1 downto 0);
      ECC_Reg_Out                    : in  std_logic_vector(C_ECC_NUM_REG*32-1 downto 0);
      ECC_Reg_In                     : out std_logic_vector(31 downto 0);
      Static_Phy_Reg_CE              : out std_logic_vector(C_STATIC_PHY_NUM_REG-1 downto 0);
      Static_Phy_Reg_Out             : in  std_logic_vector(C_STATIC_PHY_NUM_REG*32-1 downto 0);
      Static_Phy_Reg_In              : out std_logic_vector(31 downto 0);
      Debug_Ctrl_Addr                : out std_logic_vector(31 downto 0);
      Debug_Ctrl_WE                  : out std_logic;
      Debug_Ctrl_Out                 : in  std_logic_vector(31 downto 0);
      Debug_Ctrl_In                  : out std_logic_vector(31 downto 0);
      MPMC_Status_Reg_CE             : out std_logic_vector(C_MPMC_STATUS_NUM_REG-1 downto 0);
      MPMC_Status_Reg_Out            : in  std_logic_vector(C_MPMC_STATUS_NUM_REG*32-1 downto 0);
      MPMC_Status_Reg_In             : out std_logic_vector(31 downto 0);
      PM_Ctrl_Reg_CE                 : out std_logic_vector(C_PM_CTRL_NUM_REG-1 downto 0);
      PM_Ctrl_Reg_Out                : in  std_logic_vector(C_PM_CTRL_NUM_REG*32-1 downto 0);
      PM_Ctrl_Reg_In                 : out std_logic_vector(31 downto 0);
      PM_Data_Out                    : in  std_logic_vector(31 downto 0);
      PM_Data_Addr                   : out std_logic_vector(31 downto 0);


      Bus2IP_Clk                     : in  std_logic;
      Bus2IP_Addr                    : in  std_logic_vector(0 to C_SLV_AWIDTH-1);
      Bus2IP_Reset                   : in  std_logic;
      Bus2IP_CS                      : in  std_logic_vector(0 to USER_NUM_MEM-1);
      Bus2IP_RNW                     : in  std_logic;
      Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
      Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
      Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
      Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
      IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
      IP2Bus_RdAck                   : out std_logic;
      IP2Bus_WrAck                   : out std_logic;
      IP2Bus_Error                   : out std_logic

    );
  end component mpmc_ctrl_logic;

begin

  ------------------------------------------
  -- instantiate plbv46_slave_single
  ------------------------------------------
  PLBV46_SLAVE_SINGLE_0 : entity plbv46_slave_single_v1_01_a.plbv46_slave_single
    generic map
    (
      C_ARD_ADDR_RANGE_ARRAY         => IPIF_ARD_ADDR_RANGE_ARRAY,
      C_ARD_NUM_CE_ARRAY             => IPIF_ARD_NUM_CE_ARRAY,
      C_SPLB_P2P                     => C_SPLB_P2P,
      C_BUS2CORE_CLK_RATIO           => IPIF_BUS2CORE_CLK_RATIO,
      C_SPLB_MID_WIDTH               => C_SPLB_MID_WIDTH,
      C_SPLB_NUM_MASTERS             => C_SPLB_NUM_MASTERS,
      C_SPLB_AWIDTH                  => C_SPLB_AWIDTH,
      C_SPLB_DWIDTH                  => C_SPLB_DWIDTH,
      C_SIPIF_DWIDTH                 => IPIF_SLV_DWIDTH,
      C_FAMILY                       => C_FAMILY
    )
    port map
    (
      SPLB_Clk                       => SPLB_Clk,
      SPLB_Rst                       => SPLB_Rst,
      PLB_ABus                       => PLB_ABus,
      PLB_UABus                      => PLB_UABus,
      PLB_PAValid                    => PLB_PAValid,
      PLB_SAValid                    => PLB_SAValid,
      PLB_rdPrim                     => PLB_rdPrim,
      PLB_wrPrim                     => PLB_wrPrim,
      PLB_masterID                   => PLB_masterID,
      PLB_abort                      => PLB_abort,
      PLB_busLock                    => PLB_busLock,
      PLB_RNW                        => PLB_RNW,
      PLB_BE                         => PLB_BE,
      PLB_MSize                      => PLB_MSize,
      PLB_size                       => PLB_size,
      PLB_type                       => PLB_type,
      PLB_lockErr                    => PLB_lockErr,
      PLB_wrDBus                     => PLB_wrDBus,
      PLB_wrBurst                    => PLB_wrBurst,
      PLB_rdBurst                    => PLB_rdBurst,
      PLB_wrPendReq                  => PLB_wrPendReq,
      PLB_rdPendReq                  => PLB_rdPendReq,
      PLB_wrPendPri                  => PLB_wrPendPri,
      PLB_rdPendPri                  => PLB_rdPendPri,
      PLB_reqPri                     => PLB_reqPri,
      PLB_TAttribute                 => PLB_TAttribute,
      Sl_addrAck                     => Sl_addrAck,
      Sl_SSize                       => Sl_SSize,
      Sl_wait                        => Sl_wait,
      Sl_rearbitrate                 => Sl_rearbitrate,
      Sl_wrDAck                      => Sl_wrDAck,
      Sl_wrComp                      => Sl_wrComp,
      Sl_wrBTerm                     => Sl_wrBTerm,
      Sl_rdDBus                      => Sl_rdDBus,
      Sl_rdWdAddr                    => Sl_rdWdAddr,
      Sl_rdDAck                      => Sl_rdDAck,
      Sl_rdComp                      => Sl_rdComp,
      Sl_rdBTerm                     => Sl_rdBTerm,
      Sl_MBusy                       => Sl_MBusy,
      Sl_MWrErr                      => Sl_MWrErr,
      Sl_MRdErr                      => Sl_MRdErr,
      Sl_MIRQ                        => Sl_MIRQ,
      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Reset                   => ipif_Bus2IP_Reset,
      IP2Bus_Data                    => ipif_IP2Bus_Data,
      IP2Bus_WrAck                   => ipif_IP2Bus_WrAck,
      IP2Bus_RdAck                   => ipif_IP2Bus_RdAck,
      IP2Bus_Error                   => ipif_IP2Bus_Error,
      Bus2IP_Addr                    => ipif_Bus2IP_Addr,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_RNW                     => ipif_Bus2IP_RNW,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_CS                      => ipif_Bus2IP_CS,
      Bus2IP_RdCE                    => ipif_Bus2IP_RdCE,
      Bus2IP_WrCE                    => ipif_Bus2IP_WrCE
    );

  ------------------------------------------
  -- instantiate User Logic
  ------------------------------------------
  MPMC_CTRL_LOGIC_0 : component mpmc_ctrl_logic
    generic map
    (
      -- MAP USER GENERICS BELOW THIS LINE ---------------
      C_ECC_NUM_REG                  => C_ECC_NUM_REG,
      C_STATIC_PHY_NUM_REG           => C_STATIC_PHY_NUM_REG,
      C_MPMC_STATUS_NUM_REG          => C_MPMC_STATUS_NUM_REG,
      C_PM_CTRL_NUM_REG              => C_PM_CTRL_NUM_REG,
      -- MAP USER GENERICS ABOVE THIS LINE ---------------

      C_SLV_AWIDTH                   => USER_SLV_AWIDTH,
      C_SLV_DWIDTH                   => USER_SLV_DWIDTH,
      C_NUM_REG                      => USER_NUM_REG,
      C_NUM_MEM                      => USER_NUM_MEM
    )
    port map
    (
      -- MAP USER PORTS BELOW THIS LINE ------------------
      MPMC_Clk                       => MPMC_Clk,
      ECC_Reg_CE                     => ECC_Reg_CE,
      ECC_Reg_In                     => ECC_Reg_In,
      ECC_Reg_Out                    => ECC_Reg_Out,
      Static_Phy_Reg_CE              => Static_Phy_Reg_CE,
      Static_Phy_Reg_In              => Static_Phy_Reg_In,
      Static_Phy_Reg_Out             => Static_Phy_Reg_Out,
      Debug_Ctrl_Addr                => Debug_Ctrl_Addr,
      Debug_Ctrl_WE                  => Debug_Ctrl_WE,
      Debug_Ctrl_In                  => Debug_Ctrl_In,
      Debug_Ctrl_Out                 => Debug_Ctrl_Out,
      MPMC_Status_Reg_CE             => MPMC_Status_Reg_CE,
      MPMC_Status_Reg_In             => MPMC_Status_Reg_In,
      MPMC_Status_Reg_Out            => MPMC_Status_Reg_Out,
      PM_Ctrl_Reg_CE                 => PM_Ctrl_Reg_CE,
      PM_Ctrl_Reg_In                 => PM_Ctrl_Reg_In,
      PM_Ctrl_Reg_Out                => PM_Ctrl_Reg_Out,
      PM_Data_Out                    => PM_Data_Out,
      PM_Data_Addr                   => PM_Data_Addr,

      -- MAP USER PORTS ABOVE THIS LINE ------------------

      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Reset                   => ipif_Bus2IP_Reset,
      Bus2IP_Addr                    => ipif_Bus2IP_Addr,
--      Bus2IP_CS                      => ipif_Bus2IP_CS(USER_CS_INDEX to USER_CS_INDEX+USER_NUM_MEM-1),
      Bus2IP_CS                      => ipif_Bus2IP_CS,
      Bus2IP_RNW                     => ipif_Bus2IP_RNW,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_RdCE                    => user_Bus2IP_RdCE,
      Bus2IP_WrCE                    => user_Bus2IP_WrCE,
      IP2Bus_Data                    => user_IP2Bus_Data,
      IP2Bus_RdAck                   => user_IP2Bus_RdAck,
      IP2Bus_WrAck                   => user_IP2Bus_WrAck,
      IP2Bus_Error                   => user_IP2Bus_Error
    );

  ------------------------------------------
  -- connect internal signals
  ------------------------------------------
  ipif_IP2Bus_Data <= user_IP2Bus_Data;

--  IP2BUS_DATA_MUX_PROC : process( ipif_Bus2IP_CS, user_IP2Bus_Data ) is
--  begin
--
--    case ipif_Bus2IP_CS is
--      when "10000" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
--      when "01000" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
--      when "00100" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
--      when "00010" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
--      when "00001" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
--      when others => ipif_IP2Bus_Data <= (others => '0');
--    end case;
--
--  end process IP2BUS_DATA_MUX_PROC;
--
  ipif_IP2Bus_WrAck <= user_IP2Bus_WrAck;
  ipif_IP2Bus_RdAck <= user_IP2Bus_RdAck;
  ipif_IP2Bus_Error <= user_IP2Bus_Error;

  user_Bus2IP_RdCE <= ipif_Bus2IP_RdCE(USER_CE_INDEX to USER_CE_INDEX+USER_NUM_REG-1);
  user_Bus2IP_WrCE <= ipif_Bus2IP_WrCE(USER_CE_INDEX to USER_CE_INDEX+USER_NUM_REG-1);

end IMP;
