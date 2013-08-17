-------------------------------------------------------------------------------
-- system.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library iomodule_v1_00_a;
use iomodule_v1_00_a.iomodule;

library microblaze_v8_20_b;
use microblaze_v8_20_b.microblaze;

library lmb_v10_v2_00_b;
use lmb_v10_v2_00_b.lmb_v10;

library lmb_bram_if_cntlr_v3_00_b;
use lmb_bram_if_cntlr_v3_00_b.lmb_bram_if_cntlr;

--library mdm_v2_00_b;
--use mdm_v2_00_b.mdm;

library microblaze_mcs_v1_0;
use microblaze_mcs_v1_0.all;

entity microblaze_mcs is
  generic (
    -- MicroBlaze Micro Controller System Generics
    C_FAMILY              : string := "virtex5" ;
    C_XDEVICE             : string := "xc5vlx50t";
    C_XPACKAGE            : string := "ff1136";
    C_XSPEEDGRADE         : string := "-1";
    C_MICROBLAZE_INSTANCE : string := "microblaze_0";
    C_PATH                : string := "mb/U0";
    C_FREQ                : integer := 100000000;

    -- LMB BRAM Generics
    C_MEMSIZE_I : integer := 16#2000#;
    C_MEMSIZE_D : integer := 16#2000#;

    -- Debug and Trace
    C_DEBUG_ENABLED : integer := 0;
    C_TRACE         : integer := 0;

    -- IO Module Generics
    -- IO Bus
    C_USE_IO_BUS           : integer               := 0;

    -- UART generics
    C_USE_UART_RX          : integer               := 0;
    C_USE_UART_TX          : integer               := 0;
    C_UART_BAUDRATE        : integer               := 9600;
    C_UART_DATA_BITS       : integer range 5 to 8  := 8;
    C_UART_USE_PARITY      : integer               := 0;
    C_UART_ODD_PARITY      : integer               := 0;
    C_UART_RX_INTERRUPT    : integer               := 0;
    C_UART_TX_INTERRUPT    : integer               := 0;
    C_UART_ERROR_INTERRUPT : integer               := 0;

    -- FIT generics
    C_USE_FIT1        : integer               := 0;
    C_FIT1_No_CLOCKS  : integer               := 6216;
    C_FIT1_INTERRUPT  : integer               := 0;
    C_USE_FIT2        : integer               := 0;
    C_FIT2_No_CLOCKS  : integer               := 6216;
    C_FIT2_INTERRUPT  : integer               := 0;
    C_USE_FIT3        : integer               := 0;
    C_FIT3_No_CLOCKS  : integer               := 6216;
    C_FIT3_INTERRUPT  : integer               := 0;
    C_USE_FIT4        : integer               := 0;
    C_FIT4_No_CLOCKS  : integer               := 6216;
    C_FIT4_INTERRUPT  : integer               := 0;

    -- PIT generics
    C_USE_PIT1       : integer               := 0;
    C_PIT1_SIZE      : integer range 1 to 32 := 32;
    C_PIT1_READABLE  : integer               := 1;
    C_PIT1_PRESCALER : integer range 0 to 9  := 0;
    C_PIT1_INTERRUPT : integer               := 0;
    C_USE_PIT2       : integer               := 0;
    C_PIT2_SIZE      : integer range 1 to 32 := 32;
    C_PIT2_READABLE  : integer               := 1;
    C_PIT2_PRESCALER : integer range 0 to 9  := 0;
    C_PIT2_INTERRUPT : integer               := 0;
    C_USE_PIT3       : integer               := 0;
    C_PIT3_SIZE      : integer range 1 to 32 := 32;
    C_PIT3_READABLE  : integer               := 1;
    C_PIT3_PRESCALER : integer range 0 to 9  := 0;
    C_PIT3_INTERRUPT : integer               := 0;
    C_USE_PIT4       : integer               := 0;
    C_PIT4_SIZE      : integer range 1 to 32 := 32;
    C_PIT4_READABLE  : integer               := 1;
    C_PIT4_PRESCALER : integer range 0 to 9  := 0;
    C_PIT4_INTERRUPT : integer               := 0;

    -- GPO Generics
    C_USE_GPO1  : integer := 0;
    C_GPO1_SIZE : integer range 1 to 32 := 32;
    C_GPO1_INIT : std_logic_vector(31 downto 0) := (others => '0');
    C_USE_GPO2  : integer := 0;
    C_GPO2_SIZE : integer range 1 to 32 := 32;
    C_GPO2_INIT : std_logic_vector(31 downto 0) := (others => '0');
    C_USE_GPO3  : integer := 0;
    C_GPO3_SIZE : integer range 1 to 32 := 32;
    C_GPO3_INIT : std_logic_vector(31 downto 0) := (others => '0');
    C_USE_GPO4  : integer := 0;
    C_GPO4_SIZE : integer range 1 to 32 := 32;
    C_GPO4_INIT : std_logic_vector(31 downto 0) := (others => '0');

    -- GPI Generics
    C_USE_GPI1  : integer := 0;
    C_GPI1_SIZE : integer range 1 to 32 := 32;
    C_USE_GPI2  : integer := 0;
    C_GPI2_SIZE : integer range 1 to 32 := 32;
    C_USE_GPI3  : integer := 0;
    C_GPI3_SIZE : integer range 1 to 32 := 32;
    C_USE_GPI4  : integer := 0;
    C_GPI4_SIZE : integer range 1 to 32 := 32;

    -- Interrupt Handler Generics
    C_INTC_USE_EXT_INTR : integer                   := 0;
    C_INTC_INTR_SIZE    : integer range 1 to 16     := 1;
    C_INTC_LEVEL_EDGE   : std_logic_vector(15 downto 0) := X"0000";
    C_INTC_POSITIVE     : std_logic_vector(15 downto 0) := X"FFFF";
    
    C_DPLB_DWIDTH        : integer := 128;
    C_DPLB_NATIVE_DWIDTH : integer := 32;
    C_DPLB_BURST_EN      : integer := 0;
    C_DPLB_P2P           : integer := 0
    );
  port (
    Clk                    : in std_logic;
    Reset                  : in std_logic;
    -- IO Module
    IO_Addr_Strobe         : out std_logic;
    IO_Read_Strobe         : out std_logic;
    IO_Write_Strobe        : out std_logic;
    IO_Address             : out std_logic_vector(31 downto 0);
    IO_Byte_Enable         : out std_logic_vector(3  downto 0);
    IO_Write_Data          : out std_logic_vector(31 downto 0);
    IO_Read_Data           : in  std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    IO_Ready               : in  std_logic := '0';
    UART_Rx                : in  std_logic := '0';
    UART_Tx                : out std_logic;
    UART_Interrupt         : out std_logic;
    FIT1_Interrupt         : out std_logic;
    FIT1_Toggle            : out std_logic;
    FIT2_Interrupt         : out std_logic;
    FIT2_Toggle            : out std_logic;
    FIT3_Interrupt         : out std_logic;
    FIT3_Toggle            : out std_logic;
    FIT4_Interrupt         : out std_logic;
    FIT4_Toggle            : out std_logic;
    PIT1_Enable            : in  std_logic := '0';
    PIT1_Interrupt         : out std_logic;
    PIT1_Toggle            : out std_logic;
    PIT2_Enable            : in  std_logic := '0';
    PIT2_Interrupt         : out std_logic;
    PIT2_Toggle            : out std_logic;
    PIT3_Enable            : in  std_logic := '0';
    PIT3_Interrupt         : out std_logic;
    PIT3_Toggle            : out std_logic;
    PIT4_Enable            : in  std_logic := '0';
    PIT4_Interrupt         : out std_logic;
    PIT4_Toggle            : out std_logic;
    GPO1                   : out std_logic_vector(C_GPO1_SIZE-1 downto 0);
    GPO2                   : out std_logic_vector(C_GPO2_SIZE-1 downto 0);
    GPO3                   : out std_logic_vector(C_GPO3_SIZE-1 downto 0);
    GPO4                   : out std_logic_vector(C_GPO4_SIZE-1 downto 0);
    GPI1                   : in  std_logic_vector(C_GPI1_SIZE-1 downto 0) := (C_GPI1_SIZE-1 downto 0 => '0');
    GPI2                   : in  std_logic_vector(C_GPI2_SIZE-1 downto 0) := (C_GPI2_SIZE-1 downto 0 => '0');
    GPI3                   : in  std_logic_vector(C_GPI3_SIZE-1 downto 0) := (C_GPI3_SIZE-1 downto 0 => '0');
    GPI4                   : in  std_logic_vector(C_GPI4_SIZE-1 downto 0) := (C_GPI4_SIZE-1 downto 0 => '0');
    INTC_Interrupt         : in  std_logic_vector(C_INTC_INTR_SIZE-1 downto 0) := (C_INTC_INTR_SIZE-1 downto 0 => '0');
    INTC_IRQ               : out std_logic;
    -- TRACE bus interface
    Trace_Instruction      : out std_logic_vector(0 to 31);
    Trace_Valid_Instr      : out std_logic;
    Trace_PC               : out std_logic_vector(0 to 31);
    Trace_Reg_Write        : out std_logic;
    Trace_Reg_Addr         : out std_logic_vector(0 to 4);
    Trace_MSR_Reg          : out std_logic_vector(0 to 14);
    Trace_PID_Reg          : out std_logic_vector(0 to 7);
    Trace_New_Reg_Value    : out std_logic_vector(0 to 31);
    Trace_Exception_Taken  : out std_logic;
    Trace_Exception_Kind   : out std_logic_vector(0 to 4);
    Trace_Jump_Taken       : out std_logic;
    Trace_Delay_Slot       : out std_logic;
    Trace_Data_Address     : out std_logic_vector(0 to 31);
    Trace_Data_Access      : out std_logic;
    Trace_Data_Read        : out std_logic;
    Trace_Data_Write       : out std_logic;
    Trace_Data_Write_Value : out std_logic_vector(0 to 31);
    Trace_Data_Byte_Enable : out std_logic_vector(0 to 3);
    Trace_DCache_Req       : out std_logic;
    Trace_DCache_Hit       : out std_logic;
    Trace_DCache_Rdy       : out std_logic;
    Trace_DCache_Read      : out std_logic;
    Trace_ICache_Req       : out std_logic;
    Trace_ICache_Hit       : out std_logic;
    Trace_ICache_Rdy       : out std_logic;
    Trace_OF_PipeRun       : out std_logic;
    Trace_EX_PipeRun       : out std_logic;
    Trace_MEM_PipeRun      : out std_logic;
    Trace_MB_Halted        : out std_logic;
    Trace_Jump_Hit         : out std_logic;
    -- Jtag 
    DBG_CLK                : in std_logic;
    DBG_TDI                : in std_logic;
    DBG_TDO                : out std_logic;
    DBG_REG_EN             : in std_logic_vector(0 to 7);
    DBG_SHIFT              : in std_logic;
    DBG_CAPTURE            : in std_logic;
    DBG_UPDATE             : in std_logic;
    DBG_RST                : in std_logic;
    DBG_STOP               : in std_logic;
    -- Data CACHE interface
    ICACHE_FSL_IN_CLK      : out std_logic;
    ICACHE_FSL_IN_READ     : out std_logic;
    ICACHE_FSL_IN_DATA     : in  std_logic_vector(0 to 31);
    ICACHE_FSL_IN_CONTROL  : in  std_logic;
    ICACHE_FSL_IN_EXISTS   : in  std_logic;
    ICACHE_FSL_OUT_CLK     : out std_logic;
    ICACHE_FSL_OUT_WRITE   : out std_logic;
    ICACHE_FSL_OUT_DATA    : out std_logic_vector(0 to 31);
    ICACHE_FSL_OUT_CONTROL : out std_logic;
    ICACHE_FSL_OUT_FULL    : in  std_logic;
    DCACHE_FSL_IN_CLK      : out std_logic;
    DCACHE_FSL_IN_READ     : out std_logic;
    DCACHE_FSL_IN_DATA     : in  std_logic_vector(0 to 31);
    DCACHE_FSL_IN_CONTROL  : in  std_logic;
    DCACHE_FSL_IN_EXISTS   : in  std_logic;
    DCACHE_FSL_OUT_CLK     : out std_logic;
    DCACHE_FSL_OUT_WRITE   : out std_logic;
    DCACHE_FSL_OUT_DATA    : out std_logic_vector(0 to 31);
    DCACHE_FSL_OUT_CONTROL : out std_logic;
    DCACHE_FSL_OUT_FULL    : in  std_logic;
  --- data & instr bram ---
  dlmb_BRAM_Addr    : in  std_logic_vector(0 to 31);
  dlmb_BRAM_Clk     : in  std_logic;
  dlmb_BRAM_Din     : out std_logic_vector(0 to 31);
  dlmb_BRAM_Dout    : in  std_logic_vector(0 to 31);
  dlmb_BRAM_EN      : in  std_logic;
  dlmb_BRAM_Rst     : in  std_logic;
  dlmb_BRAM_WEN     : in  std_logic_vector(0 to 3);
  ilmb_BRAM_Addr    : in  std_logic_vector(0 to 31);
  ilmb_BRAM_Clk     : in  std_logic;
  ilmb_BRAM_Din     : out std_logic_vector(0 to 31);
  ilmb_BRAM_Dout    : in  std_logic_vector(0 to 31);
  ilmb_BRAM_EN      : in  std_logic;
  ilmb_BRAM_Rst     : in  std_logic;
  ilmb_BRAM_WEN     : in  std_logic_vector(0 to 3)
  );
end microblaze_mcs;

architecture STRUCTURE of microblaze_mcs is

  component microblaze is
    generic (
      C_SCO                       : integer;
      C_FREQ                      : integer;
      C_FAULT_TOLERANT            : integer;
      C_ECC_USE_CE_EXCEPTION      : integer;
      C_LOCKSTEP_SLAVE            : integer;
      C_ENDIANNESS                : integer;
      C_FAMILY                    : string;
      C_DATA_SIZE                 : integer;
      C_INSTANCE                  : string;
      C_AVOID_PRIMITIVES          : integer;
      C_AREA_OPTIMIZED            : integer;
      C_OPTIMIZATION              : integer;
      C_INTERCONNECT              : integer;
      C_STREAM_INTERCONNECT       : integer;
      C_M_AXI_DP_THREAD_ID_WIDTH  : integer;
      C_M_AXI_DP_DATA_WIDTH       : integer;
      C_M_AXI_DP_ADDR_WIDTH       : integer;
      C_M_AXI_DP_EXCLUSIVE_ACCESS : integer;
      C_M_AXI_D_BUS_EXCEPTION     : integer;
      C_DPLB_DWIDTH               : integer;
      C_DPLB_NATIVE_DWIDTH        : integer;
      C_DPLB_BURST_EN             : integer;
      C_DPLB_P2P                  : integer;
      C_M_AXI_IP_THREAD_ID_WIDTH  : integer;
      C_M_AXI_IP_DATA_WIDTH       : integer;
      C_M_AXI_IP_ADDR_WIDTH       : integer;
      C_M_AXI_I_BUS_EXCEPTION     : integer;
      C_IPLB_DWIDTH               : integer;
      C_IPLB_NATIVE_DWIDTH        : integer;
      C_IPLB_BURST_EN             : integer;
      C_IPLB_P2P                  : integer;
      C_D_AXI                     : integer;
      C_D_PLB                     : integer;
      C_D_LMB                     : integer;
      C_I_AXI                     : integer;
      C_I_PLB                     : integer;
      C_I_LMB                     : integer;
      C_USE_MSR_INSTR             : integer;
      C_USE_PCMP_INSTR            : integer;
      C_USE_BARREL                : integer;
      C_USE_DIV                   : integer;
      C_USE_HW_MUL                : integer;
      C_USE_FPU                   : integer;
      C_UNALIGNED_EXCEPTIONS      : integer;
      C_ILL_OPCODE_EXCEPTION      : integer;
      C_IPLB_BUS_EXCEPTION        : integer;
      C_DPLB_BUS_EXCEPTION        : integer;
      C_DIV_ZERO_EXCEPTION        : integer;
      C_FPU_EXCEPTION             : integer;
      C_FSL_EXCEPTION             : integer;
      C_USE_STACK_PROTECTION      : integer;
      C_USE_INTERRUPT             : integer;
      C_USE_EXT_BRK               : integer;
      C_USE_EXT_NM_BRK            : integer;
      C_USE_MMU                   : integer;
      C_MMU_DTLB_SIZE             : integer;
      C_MMU_ITLB_SIZE             : integer;
      C_MMU_TLB_ACCESS            : integer;
      C_MMU_ZONES                 : integer;
      C_MMU_PRIVILEGED_INSTR      : integer;
      C_USE_BRANCH_TARGET_CACHE   : integer;
      C_BRANCH_TARGET_CACHE_SIZE  : integer;
      C_PVR                       : integer;
      C_PVR_USER1                 : std_logic_vector(0 to 7);
      C_PVR_USER2                 : std_logic_vector(0 to 31);
      C_DYNAMIC_BUS_SIZING        : integer;
      C_RESET_MSR                 : std_logic_vector;
      C_OPCODE_0x0_ILLEGAL        : integer;
      C_DEBUG_ENABLED             : integer;
      C_NUMBER_OF_PC_BRK          : integer;
      C_NUMBER_OF_RD_ADDR_BRK     : integer;
      C_NUMBER_OF_WR_ADDR_BRK     : integer;
      C_INTERRUPT_IS_EDGE         : integer;
      C_EDGE_IS_POSITIVE          : integer;
      C_ASYNC_INTERRUPT           : integer;
      C_FSL_LINKS                 : integer;
      C_FSL_DATA_SIZE             : integer;
      C_USE_EXTENDED_FSL_INSTR    : integer;
      C_M0_AXIS_DATA_WIDTH        : integer;
      C_S0_AXIS_DATA_WIDTH        : integer;
      C_M1_AXIS_DATA_WIDTH        : integer;
      C_S1_AXIS_DATA_WIDTH        : integer;
      C_M2_AXIS_DATA_WIDTH        : integer;
      C_S2_AXIS_DATA_WIDTH        : integer;
      C_M3_AXIS_DATA_WIDTH        : integer;
      C_S3_AXIS_DATA_WIDTH        : integer;
      C_M4_AXIS_DATA_WIDTH        : integer;
      C_S4_AXIS_DATA_WIDTH        : integer;
      C_M5_AXIS_DATA_WIDTH        : integer;
      C_S5_AXIS_DATA_WIDTH        : integer;
      C_M6_AXIS_DATA_WIDTH        : integer;
      C_S6_AXIS_DATA_WIDTH        : integer;
      C_M7_AXIS_DATA_WIDTH        : integer;
      C_S7_AXIS_DATA_WIDTH        : integer;
      C_M8_AXIS_DATA_WIDTH        : integer;
      C_S8_AXIS_DATA_WIDTH        : integer;
      C_M9_AXIS_DATA_WIDTH        : integer;
      C_S9_AXIS_DATA_WIDTH        : integer;
      C_M10_AXIS_DATA_WIDTH       : integer;
      C_S10_AXIS_DATA_WIDTH       : integer;
      C_M11_AXIS_DATA_WIDTH       : integer;
      C_S11_AXIS_DATA_WIDTH       : integer;
      C_M12_AXIS_DATA_WIDTH       : integer;
      C_S12_AXIS_DATA_WIDTH       : integer;
      C_M13_AXIS_DATA_WIDTH       : integer;
      C_S13_AXIS_DATA_WIDTH       : integer;
      C_M14_AXIS_DATA_WIDTH       : integer;
      C_S14_AXIS_DATA_WIDTH       : integer;
      C_M15_AXIS_DATA_WIDTH       : integer;
      C_S15_AXIS_DATA_WIDTH       : integer;
      C_ICACHE_BASEADDR           : std_logic_vector;
      C_ICACHE_HIGHADDR           : std_logic_vector;
      C_USE_ICACHE                : integer;
      C_ALLOW_ICACHE_WR           : integer;
      C_ADDR_TAG_BITS             : integer;
      C_CACHE_BYTE_SIZE           : integer;
      C_ICACHE_USE_FSL            : integer;
      C_ICACHE_LINE_LEN           : integer;
      C_ICACHE_ALWAYS_USED        : integer;
      C_ICACHE_INTERFACE          : integer;
      C_ICACHE_STREAMS            : integer;
      C_ICACHE_VICTIMS            : integer;
      C_ICACHE_FORCE_TAG_LUTRAM   : integer;
      C_ICACHE_DATA_WIDTH         : integer;
      C_M_AXI_IC_THREAD_ID_WIDTH  : integer;
      C_M_AXI_IC_DATA_WIDTH       : integer;
      C_M_AXI_IC_ADDR_WIDTH       : integer;
      C_M_AXI_IC_USER_VALUE       : integer;
      C_M_AXI_IC_AWUSER_WIDTH     : integer;
      C_M_AXI_IC_ARUSER_WIDTH     : integer;
      C_M_AXI_IC_WUSER_WIDTH      : integer;
      C_M_AXI_IC_RUSER_WIDTH      : integer;
      C_M_AXI_IC_BUSER_WIDTH      : integer;
      C_DCACHE_BASEADDR           : std_logic_vector;
      C_DCACHE_HIGHADDR           : std_logic_vector;
      C_USE_DCACHE                : integer;
      C_ALLOW_DCACHE_WR           : integer;
      C_DCACHE_ADDR_TAG           : integer;
      C_DCACHE_BYTE_SIZE          : integer;
      C_DCACHE_USE_FSL            : integer;
      C_DCACHE_LINE_LEN           : integer;
      C_DCACHE_ALWAYS_USED        : integer;
      C_DCACHE_INTERFACE          : integer;
      C_DCACHE_USE_WRITEBACK      : integer;
      C_DCACHE_VICTIMS            : integer;
      C_DCACHE_FORCE_TAG_LUTRAM   : integer;
      C_DCACHE_DATA_WIDTH         : integer;
      C_M_AXI_DC_THREAD_ID_WIDTH  : integer;
      C_M_AXI_DC_DATA_WIDTH       : integer;
      C_M_AXI_DC_ADDR_WIDTH       : integer;
      C_M_AXI_DC_EXCLUSIVE_ACCESS : integer;
      C_M_AXI_DC_USER_VALUE       : integer;
      C_M_AXI_DC_AWUSER_WIDTH     : integer;
      C_M_AXI_DC_ARUSER_WIDTH     : integer;
      C_M_AXI_DC_WUSER_WIDTH      : integer;
      C_M_AXI_DC_RUSER_WIDTH      : integer;
      C_M_AXI_DC_BUSER_WIDTH      : integer
    );
    port (
      CLK                    : in  std_logic;
      RESET                  : in  std_logic;
      MB_RESET               : in  std_logic;
      INTERRUPT              : in  std_logic;
      EXT_BRK                : in  std_logic;
      EXT_NM_BRK             : in  std_logic;
      DBG_STOP               : in  std_logic;
      MB_Halted              : out std_logic;
      MB_Error               : out std_logic;
      LOCKSTEP_Slave_In      : in  std_logic_vector(0 to 4095);
      LOCKSTEP_Master_Out    : out std_logic_vector(0 to 4095);
      LOCKSTEP_Out           : out std_logic_vector(0 to 4095);
      INSTR_ADDR             : out std_logic_vector(0 to 31);
      INSTR                  : in  std_logic_vector(0 to 31);
      IREADY                 : in  std_logic;
      IWAIT                  : in  std_logic;
      ICE                    : in  std_logic;
      IUE                    : in  std_logic;
      IFETCH                 : out std_logic;
      I_AS                   : out std_logic;
      IPLB_M_ABort           : out std_logic;
      IPLB_M_ABus            : out std_logic_vector(0 to 31);
      IPLB_M_UABus           : out std_logic_vector(0 to 31);
      IPLB_M_BE              : out std_logic_vector(0 to (C_IPLB_DWIDTH-1)/8);
      IPLB_M_busLock         : out std_logic;
      IPLB_M_lockErr         : out std_logic;
      IPLB_M_MSize           : out std_logic_vector(0 to 1);
      IPLB_M_priority        : out std_logic_vector(0 to 1);
      IPLB_M_rdBurst         : out std_logic;
      IPLB_M_request         : out std_logic;
      IPLB_M_RNW             : out std_logic;
      IPLB_M_size            : out std_logic_vector(0 to 3);
      IPLB_M_TAttribute      : out std_logic_vector(0 to 15);
      IPLB_M_type            : out std_logic_vector(0 to 2);
      IPLB_M_wrBurst         : out std_logic;
      IPLB_M_wrDBus          : out std_logic_vector(0 to C_IPLB_DWIDTH-1);
      IPLB_MBusy             : in  std_logic;
      IPLB_MRdErr            : in  std_logic;
      IPLB_MWrErr            : in  std_logic;
      IPLB_MIRQ              : in  std_logic;
      IPLB_MWrBTerm          : in  std_logic;
      IPLB_MWrDAck           : in  std_logic;
      IPLB_MAddrAck          : in  std_logic;
      IPLB_MRdBTerm          : in  std_logic;
      IPLB_MRdDAck           : in  std_logic;
      IPLB_MRdDBus           : in  std_logic_vector(0 to C_IPLB_DWIDTH-1);
      IPLB_MRdWdAddr         : in  std_logic_vector(0 to 3);
      IPLB_MRearbitrate      : in  std_logic;
      IPLB_MSSize            : in  std_logic_vector(0 to 1);
      IPLB_MTimeout          : in  std_logic;
      DATA_READ              : in  std_logic_vector(0 to 31);
      DREADY                 : in  std_logic;
      DWAIT                  : in  std_logic;
      DCE                    : in  std_logic;
      DUE                    : in  std_logic;
      DATA_WRITE             : out std_logic_vector(0 to 31);
      DATA_ADDR              : out std_logic_vector(0 to 31);
      D_AS                   : out std_logic;
      READ_STROBE            : out std_logic;
      WRITE_STROBE           : out std_logic;
      BYTE_ENABLE            : out std_logic_vector(0 to 3);
      DPLB_M_ABort           : out std_logic;
      DPLB_M_ABus            : out std_logic_vector(0 to 31);
      DPLB_M_UABus           : out std_logic_vector(0 to 31);
      DPLB_M_BE              : out std_logic_vector(0 to (C_DPLB_DWIDTH-1)/8);
      DPLB_M_busLock         : out std_logic;
      DPLB_M_lockErr         : out std_logic;
      DPLB_M_MSize           : out std_logic_vector(0 to 1);
      DPLB_M_priority        : out std_logic_vector(0 to 1);
      DPLB_M_rdBurst         : out std_logic;
      DPLB_M_request         : out std_logic;
      DPLB_M_RNW             : out std_logic;
      DPLB_M_size            : out std_logic_vector(0 to 3);
      DPLB_M_TAttribute      : out std_logic_vector(0 to 15);
      DPLB_M_type            : out std_logic_vector(0 to 2);
      DPLB_M_wrBurst         : out std_logic;
      DPLB_M_wrDBus          : out std_logic_vector(0 to C_DPLB_DWIDTH-1);
      DPLB_MBusy             : in  std_logic;
      DPLB_MRdErr            : in  std_logic;
      DPLB_MWrErr            : in  std_logic;
      DPLB_MIRQ              : in  std_logic;
      DPLB_MWrBTerm          : in  std_logic;
      DPLB_MWrDAck           : in  std_logic;
      DPLB_MAddrAck          : in  std_logic;
      DPLB_MRdBTerm          : in  std_logic;
      DPLB_MRdDAck           : in  std_logic;
      DPLB_MRdDBus           : in  std_logic_vector(0 to C_DPLB_DWIDTH-1);
      DPLB_MRdWdAddr         : in  std_logic_vector(0 to 3);
      DPLB_MRearbitrate      : in  std_logic;
      DPLB_MSSize            : in  std_logic_vector(0 to 1);
      DPLB_MTimeout          : in  std_logic;
      M_AXI_IP_AWID          : out std_logic_vector((C_M_AXI_IP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IP_AWADDR        : out std_logic_vector((C_M_AXI_IP_ADDR_WIDTH-1) downto 0);
      M_AXI_IP_AWLEN         : out std_logic_vector(7 downto 0);
      M_AXI_IP_AWSIZE        : out std_logic_vector(2 downto 0);
      M_AXI_IP_AWBURST       : out std_logic_vector(1 downto 0);
      M_AXI_IP_AWLOCK        : out std_logic;
      M_AXI_IP_AWCACHE       : out std_logic_vector(3 downto 0);
      M_AXI_IP_AWPROT        : out std_logic_vector(2 downto 0);
      M_AXI_IP_AWQOS         : out std_logic_vector(3 downto 0);
      M_AXI_IP_AWVALID       : out std_logic;
      M_AXI_IP_AWREADY       : in  std_logic;
      M_AXI_IP_WDATA         : out std_logic_vector((C_M_AXI_IP_DATA_WIDTH-1) downto 0);
      M_AXI_IP_WSTRB         : out std_logic_vector(((C_M_AXI_IP_DATA_WIDTH/8)-1) downto 0);
      M_AXI_IP_WLAST         : out std_logic;
      M_AXI_IP_WVALID        : out std_logic;
      M_AXI_IP_WREADY        : in  std_logic;
      M_AXI_IP_BID           : in  std_logic_vector((C_M_AXI_IP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IP_BRESP         : in  std_logic_vector(1 downto 0);
      M_AXI_IP_BVALID        : in  std_logic;
      M_AXI_IP_BREADY        : out std_logic;
      M_AXI_IP_ARID          : out std_logic_vector((C_M_AXI_IP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IP_ARADDR        : out std_logic_vector((C_M_AXI_IP_ADDR_WIDTH-1) downto 0);
      M_AXI_IP_ARLEN         : out std_logic_vector(7 downto 0);
      M_AXI_IP_ARSIZE        : out std_logic_vector(2 downto 0);
      M_AXI_IP_ARBURST       : out std_logic_vector(1 downto 0);
      M_AXI_IP_ARLOCK        : out std_logic;
      M_AXI_IP_ARCACHE       : out std_logic_vector(3 downto 0);
      M_AXI_IP_ARPROT        : out std_logic_vector(2 downto 0);
      M_AXI_IP_ARQOS         : out std_logic_vector(3 downto 0);
      M_AXI_IP_ARVALID       : out std_logic;
      M_AXI_IP_ARREADY       : in  std_logic;
      M_AXI_IP_RID           : in  std_logic_vector((C_M_AXI_IP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IP_RDATA         : in  std_logic_vector((C_M_AXI_IP_DATA_WIDTH-1) downto 0);
      M_AXI_IP_RRESP         : in  std_logic_vector(1 downto 0);
      M_AXI_IP_RLAST         : in  std_logic;
      M_AXI_IP_RVALID        : in  std_logic;
      M_AXI_IP_RREADY        : out std_logic;
      M_AXI_DP_AWID          : out std_logic_vector((C_M_AXI_DP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DP_AWADDR        : out std_logic_vector((C_M_AXI_DP_ADDR_WIDTH-1) downto 0);
      M_AXI_DP_AWLEN         : out std_logic_vector(7 downto 0);
      M_AXI_DP_AWSIZE        : out std_logic_vector(2 downto 0);
      M_AXI_DP_AWBURST       : out std_logic_vector(1 downto 0);
      M_AXI_DP_AWLOCK        : out std_logic;
      M_AXI_DP_AWCACHE       : out std_logic_vector(3 downto 0);
      M_AXI_DP_AWPROT        : out std_logic_vector(2 downto 0);
      M_AXI_DP_AWQOS         : out std_logic_vector(3 downto 0);
      M_AXI_DP_AWVALID       : out std_logic;
      M_AXI_DP_AWREADY       : in  std_logic;
      M_AXI_DP_WDATA         : out std_logic_vector((C_M_AXI_DP_DATA_WIDTH-1) downto 0);
      M_AXI_DP_WSTRB         : out std_logic_vector(((C_M_AXI_DP_DATA_WIDTH/8)-1) downto 0);
      M_AXI_DP_WLAST         : out std_logic;
      M_AXI_DP_WVALID        : out std_logic;
      M_AXI_DP_WREADY        : in  std_logic;
      M_AXI_DP_BID           : in  std_logic_vector((C_M_AXI_DP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DP_BRESP         : in  std_logic_vector(1 downto 0);
      M_AXI_DP_BVALID        : in  std_logic;
      M_AXI_DP_BREADY        : out std_logic;
      M_AXI_DP_ARID          : out std_logic_vector((C_M_AXI_DP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DP_ARADDR        : out std_logic_vector((C_M_AXI_DP_ADDR_WIDTH-1) downto 0);
      M_AXI_DP_ARLEN         : out std_logic_vector(7 downto 0);
      M_AXI_DP_ARSIZE        : out std_logic_vector(2 downto 0);
      M_AXI_DP_ARBURST       : out std_logic_vector(1 downto 0);
      M_AXI_DP_ARLOCK        : out std_logic;
      M_AXI_DP_ARCACHE       : out std_logic_vector(3 downto 0);
      M_AXI_DP_ARPROT        : out std_logic_vector(2 downto 0);
      M_AXI_DP_ARQOS         : out std_logic_vector(3 downto 0);
      M_AXI_DP_ARVALID       : out std_logic;
      M_AXI_DP_ARREADY       : in  std_logic;
      M_AXI_DP_RID           : in  std_logic_vector((C_M_AXI_DP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DP_RDATA         : in  std_logic_vector((C_M_AXI_DP_DATA_WIDTH-1) downto 0);
      M_AXI_DP_RRESP         : in  std_logic_vector(1 downto 0);
      M_AXI_DP_RLAST         : in  std_logic;
      M_AXI_DP_RVALID        : in  std_logic;
      M_AXI_DP_RREADY        : out std_logic;
      M_AXI_IC_AWID          : out std_logic_vector((C_M_AXI_IC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IC_AWADDR        : out std_logic_vector((C_M_AXI_IC_ADDR_WIDTH-1) downto 0);
      M_AXI_IC_AWLEN         : out std_logic_vector(7 downto 0);
      M_AXI_IC_AWSIZE        : out std_logic_vector(2 downto 0);
      M_AXI_IC_AWBURST       : out std_logic_vector(1 downto 0);
      M_AXI_IC_AWLOCK        : out std_logic;
      M_AXI_IC_AWCACHE       : out std_logic_vector(3 downto 0);
      M_AXI_IC_AWPROT        : out std_logic_vector(2 downto 0);
      M_AXI_IC_AWQOS         : out std_logic_vector(3 downto 0);
      M_AXI_IC_AWVALID       : out std_logic;
      M_AXI_IC_AWREADY       : in  std_logic;
      M_AXI_IC_AWUSER        : out std_logic_vector((C_M_AXI_IC_AWUSER_WIDTH-1) downto 0);
      M_AXI_IC_WDATA         : out std_logic_vector((C_M_AXI_IC_DATA_WIDTH-1) downto 0);
      M_AXI_IC_WSTRB         : out std_logic_vector(((C_M_AXI_IC_DATA_WIDTH/8)-1) downto 0);
      M_AXI_IC_WLAST         : out std_logic;
      M_AXI_IC_WVALID        : out std_logic;
      M_AXI_IC_WREADY        : in  std_logic;
      M_AXI_IC_WUSER         : out std_logic_vector((C_M_AXI_IC_WUSER_WIDTH-1) downto 0);
      M_AXI_IC_BID           : in  std_logic_vector((C_M_AXI_IC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IC_BRESP         : in  std_logic_vector(1 downto 0);
      M_AXI_IC_BVALID        : in  std_logic;
      M_AXI_IC_BREADY        : out std_logic;
      M_AXI_IC_BUSER         : in  std_logic_vector((C_M_AXI_IC_BUSER_WIDTH-1) downto 0);
      M_AXI_IC_ARID          : out std_logic_vector((C_M_AXI_IC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IC_ARADDR        : out std_logic_vector((C_M_AXI_IC_ADDR_WIDTH-1) downto 0);
      M_AXI_IC_ARLEN         : out std_logic_vector(7 downto 0);
      M_AXI_IC_ARSIZE        : out std_logic_vector(2 downto 0);
      M_AXI_IC_ARBURST       : out std_logic_vector(1 downto 0);
      M_AXI_IC_ARLOCK        : out std_logic;
      M_AXI_IC_ARCACHE       : out std_logic_vector(3 downto 0);
      M_AXI_IC_ARPROT        : out std_logic_vector(2 downto 0);
      M_AXI_IC_ARQOS         : out std_logic_vector(3 downto 0);
      M_AXI_IC_ARVALID       : out std_logic;
      M_AXI_IC_ARREADY       : in  std_logic;
      M_AXI_IC_ARUSER        : out std_logic_vector((C_M_AXI_IC_ARUSER_WIDTH-1) downto 0);
      M_AXI_IC_RID           : in  std_logic_vector((C_M_AXI_IC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IC_RDATA         : in  std_logic_vector((C_M_AXI_IC_DATA_WIDTH-1) downto 0);
      M_AXI_IC_RRESP         : in  std_logic_vector(1 downto 0);
      M_AXI_IC_RLAST         : in  std_logic;
      M_AXI_IC_RVALID        : in  std_logic;
      M_AXI_IC_RREADY        : out std_logic;
      M_AXI_IC_RUSER         : in  std_logic_vector((C_M_AXI_IC_RUSER_WIDTH-1) downto 0);
      M_AXI_DC_AWID          : out std_logic_vector((C_M_AXI_DC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DC_AWADDR        : out std_logic_vector((C_M_AXI_DC_ADDR_WIDTH-1) downto 0);
      M_AXI_DC_AWLEN         : out std_logic_vector(7 downto 0);
      M_AXI_DC_AWSIZE        : out std_logic_vector(2 downto 0);
      M_AXI_DC_AWBURST       : out std_logic_vector(1 downto 0);
      M_AXI_DC_AWLOCK        : out std_logic;
      M_AXI_DC_AWCACHE       : out std_logic_vector(3 downto 0);
      M_AXI_DC_AWPROT        : out std_logic_vector(2 downto 0);
      M_AXI_DC_AWQOS         : out std_logic_vector(3 downto 0);
      M_AXI_DC_AWVALID       : out std_logic;
      M_AXI_DC_AWREADY       : in  std_logic;
      M_AXI_DC_AWUSER        : out std_logic_vector((C_M_AXI_DC_AWUSER_WIDTH-1) downto 0);
      M_AXI_DC_WDATA         : out std_logic_vector((C_M_AXI_DC_DATA_WIDTH-1) downto 0);
      M_AXI_DC_WSTRB         : out std_logic_vector(((C_M_AXI_DC_DATA_WIDTH/8)-1) downto 0);
      M_AXI_DC_WLAST         : out std_logic;
      M_AXI_DC_WVALID        : out std_logic;
      M_AXI_DC_WREADY        : in  std_logic;
      M_AXI_DC_WUSER         : out std_logic_vector((C_M_AXI_DC_WUSER_WIDTH-1) downto 0);
      M_AXI_DC_BID           : in  std_logic_vector((C_M_AXI_DC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DC_BRESP         : in  std_logic_vector(1 downto 0);
      M_AXI_DC_BVALID        : in  std_logic;
      M_AXI_DC_BREADY        : out std_logic;
      M_AXI_DC_BUSER         : in  std_logic_vector((C_M_AXI_DC_BUSER_WIDTH-1) downto 0);
      M_AXI_DC_ARID          : out std_logic_vector((C_M_AXI_DC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DC_ARADDR        : out std_logic_vector((C_M_AXI_DC_ADDR_WIDTH-1) downto 0);
      M_AXI_DC_ARLEN         : out std_logic_vector(7 downto 0);
      M_AXI_DC_ARSIZE        : out std_logic_vector(2 downto 0);
      M_AXI_DC_ARBURST       : out std_logic_vector(1 downto 0);
      M_AXI_DC_ARLOCK        : out std_logic;
      M_AXI_DC_ARCACHE       : out std_logic_vector(3 downto 0);
      M_AXI_DC_ARPROT        : out std_logic_vector(2 downto 0);
      M_AXI_DC_ARQOS         : out std_logic_vector(3 downto 0);
      M_AXI_DC_ARVALID       : out std_logic;
      M_AXI_DC_ARREADY       : in  std_logic;
      M_AXI_DC_ARUSER        : out std_logic_vector((C_M_AXI_DC_ARUSER_WIDTH-1) downto 0);
      M_AXI_DC_RID           : in  std_logic_vector((C_M_AXI_DC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DC_RDATA         : in  std_logic_vector((C_M_AXI_DC_DATA_WIDTH-1) downto 0);
      M_AXI_DC_RRESP         : in  std_logic_vector(1 downto 0);
      M_AXI_DC_RLAST         : in  std_logic;
      M_AXI_DC_RVALID        : in  std_logic;
      M_AXI_DC_RREADY        : out std_logic;
      M_AXI_DC_RUSER         : in  std_logic_vector((C_M_AXI_DC_RUSER_WIDTH-1) downto 0);
      DBG_CLK                : in  std_logic;
      DBG_TDI                : in  std_logic;
      DBG_TDO                : out std_logic;
      DBG_REG_EN             : in  std_logic_vector(0 to 7);
      DBG_SHIFT              : in  std_logic;
      DBG_CAPTURE            : in  std_logic;
      DBG_UPDATE             : in  std_logic;
      DEBUG_RST              : in  std_logic;
      Trace_Instruction      : out std_logic_vector(0 to 31);
      Trace_Valid_Instr      : out std_logic;
      Trace_PC               : out std_logic_vector(0 to 31);
      Trace_Reg_Write        : out std_logic;
      Trace_Reg_Addr         : out std_logic_vector(0 to 4);
      Trace_MSR_Reg          : out std_logic_vector(0 to 14);
      Trace_PID_Reg          : out std_logic_vector(0 to 7);
      Trace_New_Reg_Value    : out std_logic_vector(0 to 31);
      Trace_Exception_Taken  : out std_logic;
      Trace_Exception_Kind   : out std_logic_vector(0 to 4);
      Trace_Jump_Taken       : out std_logic;
      Trace_Delay_Slot       : out std_logic;
      Trace_Data_Address     : out std_logic_vector(0 to 31);
      Trace_Data_Access      : out std_logic;
      Trace_Data_Read        : out std_logic;
      Trace_Data_Write       : out std_logic;
      Trace_Data_Write_Value : out std_logic_vector(0 to 31);
      Trace_Data_Byte_Enable : out std_logic_vector(0 to 3);
      Trace_DCache_Req       : out std_logic;
      Trace_DCache_Hit       : out std_logic;
      Trace_DCache_Rdy       : out std_logic;
      Trace_DCache_Read      : out std_logic;
      Trace_ICache_Req       : out std_logic;
      Trace_ICache_Hit       : out std_logic;
      Trace_ICache_Rdy       : out std_logic;
      Trace_OF_PipeRun       : out std_logic;
      Trace_EX_PipeRun       : out std_logic;
      Trace_MEM_PipeRun      : out std_logic;
      Trace_MB_Halted        : out std_logic;
      Trace_Jump_Hit         : out std_logic;
      FSL0_S_CLK             : out std_logic;
      FSL0_S_READ            : out std_logic;
      FSL0_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL0_S_CONTROL         : in  std_logic;
      FSL0_S_EXISTS          : in  std_logic;
      FSL0_M_CLK             : out std_logic;
      FSL0_M_WRITE           : out std_logic;
      FSL0_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL0_M_CONTROL         : out std_logic;
      FSL0_M_FULL            : in  std_logic;
      FSL1_S_CLK             : out std_logic;
      FSL1_S_READ            : out std_logic;
      FSL1_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL1_S_CONTROL         : in  std_logic;
      FSL1_S_EXISTS          : in  std_logic;
      FSL1_M_CLK             : out std_logic;
      FSL1_M_WRITE           : out std_logic;
      FSL1_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL1_M_CONTROL         : out std_logic;
      FSL1_M_FULL            : in  std_logic;
      FSL2_S_CLK             : out std_logic;
      FSL2_S_READ            : out std_logic;
      FSL2_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL2_S_CONTROL         : in  std_logic;
      FSL2_S_EXISTS          : in  std_logic;
      FSL2_M_CLK             : out std_logic;
      FSL2_M_WRITE           : out std_logic;
      FSL2_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL2_M_CONTROL         : out std_logic;
      FSL2_M_FULL            : in  std_logic;
      FSL3_S_CLK             : out std_logic;
      FSL3_S_READ            : out std_logic;
      FSL3_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL3_S_CONTROL         : in  std_logic;
      FSL3_S_EXISTS          : in  std_logic;
      FSL3_M_CLK             : out std_logic;
      FSL3_M_WRITE           : out std_logic;
      FSL3_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL3_M_CONTROL         : out std_logic;
      FSL3_M_FULL            : in  std_logic;
      FSL4_S_CLK             : out std_logic;
      FSL4_S_READ            : out std_logic;
      FSL4_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL4_S_CONTROL         : in  std_logic;
      FSL4_S_EXISTS          : in  std_logic;
      FSL4_M_CLK             : out std_logic;
      FSL4_M_WRITE           : out std_logic;
      FSL4_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL4_M_CONTROL         : out std_logic;
      FSL4_M_FULL            : in  std_logic;
      FSL5_S_CLK             : out std_logic;
      FSL5_S_READ            : out std_logic;
      FSL5_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL5_S_CONTROL         : in  std_logic;
      FSL5_S_EXISTS          : in  std_logic;
      FSL5_M_CLK             : out std_logic;
      FSL5_M_WRITE           : out std_logic;
      FSL5_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL5_M_CONTROL         : out std_logic;
      FSL5_M_FULL            : in  std_logic;
      FSL6_S_CLK             : out std_logic;
      FSL6_S_READ            : out std_logic;
      FSL6_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL6_S_CONTROL         : in  std_logic;
      FSL6_S_EXISTS          : in  std_logic;
      FSL6_M_CLK             : out std_logic;
      FSL6_M_WRITE           : out std_logic;
      FSL6_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL6_M_CONTROL         : out std_logic;
      FSL6_M_FULL            : in  std_logic;
      FSL7_S_CLK             : out std_logic;
      FSL7_S_READ            : out std_logic;
      FSL7_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL7_S_CONTROL         : in  std_logic;
      FSL7_S_EXISTS          : in  std_logic;
      FSL7_M_CLK             : out std_logic;
      FSL7_M_WRITE           : out std_logic;
      FSL7_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL7_M_CONTROL         : out std_logic;
      FSL7_M_FULL            : in  std_logic;
      FSL8_S_CLK             : out std_logic;
      FSL8_S_READ            : out std_logic;
      FSL8_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL8_S_CONTROL         : in  std_logic;
      FSL8_S_EXISTS          : in  std_logic;
      FSL8_M_CLK             : out std_logic;
      FSL8_M_WRITE           : out std_logic;
      FSL8_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL8_M_CONTROL         : out std_logic;
      FSL8_M_FULL            : in  std_logic;
      FSL9_S_CLK             : out std_logic;
      FSL9_S_READ            : out std_logic;
      FSL9_S_DATA            : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL9_S_CONTROL         : in  std_logic;
      FSL9_S_EXISTS          : in  std_logic;
      FSL9_M_CLK             : out std_logic;
      FSL9_M_WRITE           : out std_logic;
      FSL9_M_DATA            : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL9_M_CONTROL         : out std_logic;
      FSL9_M_FULL            : in  std_logic;
      FSL10_S_CLK            : out std_logic;
      FSL10_S_READ           : out std_logic;
      FSL10_S_DATA           : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL10_S_CONTROL        : in  std_logic;
      FSL10_S_EXISTS         : in  std_logic;
      FSL10_M_CLK            : out std_logic;
      FSL10_M_WRITE          : out std_logic;
      FSL10_M_DATA           : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL10_M_CONTROL        : out std_logic;
      FSL10_M_FULL           : in  std_logic;
      FSL11_S_CLK            : out std_logic;
      FSL11_S_READ           : out std_logic;
      FSL11_S_DATA           : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL11_S_CONTROL        : in  std_logic;
      FSL11_S_EXISTS         : in  std_logic;
      FSL11_M_CLK            : out std_logic;
      FSL11_M_WRITE          : out std_logic;
      FSL11_M_DATA           : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL11_M_CONTROL        : out std_logic;
      FSL11_M_FULL           : in  std_logic;
      FSL12_S_CLK            : out std_logic;
      FSL12_S_READ           : out std_logic;
      FSL12_S_DATA           : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL12_S_CONTROL        : in  std_logic;
      FSL12_S_EXISTS         : in  std_logic;
      FSL12_M_CLK            : out std_logic;
      FSL12_M_WRITE          : out std_logic;
      FSL12_M_DATA           : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL12_M_CONTROL        : out std_logic;
      FSL12_M_FULL           : in  std_logic;
      FSL13_S_CLK            : out std_logic;
      FSL13_S_READ           : out std_logic;
      FSL13_S_DATA           : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL13_S_CONTROL        : in  std_logic;
      FSL13_S_EXISTS         : in  std_logic;
      FSL13_M_CLK            : out std_logic;
      FSL13_M_WRITE          : out std_logic;
      FSL13_M_DATA           : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL13_M_CONTROL        : out std_logic;
      FSL13_M_FULL           : in  std_logic;
      FSL14_S_CLK            : out std_logic;
      FSL14_S_READ           : out std_logic;
      FSL14_S_DATA           : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL14_S_CONTROL        : in  std_logic;
      FSL14_S_EXISTS         : in  std_logic;
      FSL14_M_CLK            : out std_logic;
      FSL14_M_WRITE          : out std_logic;
      FSL14_M_DATA           : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL14_M_CONTROL        : out std_logic;
      FSL14_M_FULL           : in  std_logic;
      FSL15_S_CLK            : out std_logic;
      FSL15_S_READ           : out std_logic;
      FSL15_S_DATA           : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL15_S_CONTROL        : in  std_logic;
      FSL15_S_EXISTS         : in  std_logic;
      FSL15_M_CLK            : out std_logic;
      FSL15_M_WRITE          : out std_logic;
      FSL15_M_DATA           : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL15_M_CONTROL        : out std_logic;
      FSL15_M_FULL           : in  std_logic;
      M0_AXIS_TLAST          : out std_logic;
      M0_AXIS_TDATA          : out std_logic_vector(C_M0_AXIS_DATA_WIDTH-1 downto 0);
      M0_AXIS_TVALID         : out std_logic;
      M0_AXIS_TREADY         : in  std_logic;
      S0_AXIS_TLAST          : in  std_logic;
      S0_AXIS_TDATA          : in  std_logic_vector(C_S0_AXIS_DATA_WIDTH-1 downto 0);
      S0_AXIS_TVALID         : in  std_logic;
      S0_AXIS_TREADY         : out std_logic;
      M1_AXIS_TLAST          : out std_logic;
      M1_AXIS_TDATA          : out std_logic_vector(C_M1_AXIS_DATA_WIDTH-1 downto 0);
      M1_AXIS_TVALID         : out std_logic;
      M1_AXIS_TREADY         : in  std_logic;
      S1_AXIS_TLAST          : in  std_logic;
      S1_AXIS_TDATA          : in  std_logic_vector(C_S1_AXIS_DATA_WIDTH-1 downto 0);
      S1_AXIS_TVALID         : in  std_logic;
      S1_AXIS_TREADY         : out std_logic;
      M2_AXIS_TLAST          : out std_logic;
      M2_AXIS_TDATA          : out std_logic_vector(C_M2_AXIS_DATA_WIDTH-1 downto 0);
      M2_AXIS_TVALID         : out std_logic;
      M2_AXIS_TREADY         : in  std_logic;
      S2_AXIS_TLAST          : in  std_logic;
      S2_AXIS_TDATA          : in  std_logic_vector(C_S2_AXIS_DATA_WIDTH-1 downto 0);
      S2_AXIS_TVALID         : in  std_logic;
      S2_AXIS_TREADY         : out std_logic;
      M3_AXIS_TLAST          : out std_logic;
      M3_AXIS_TDATA          : out std_logic_vector(C_M3_AXIS_DATA_WIDTH-1 downto 0);
      M3_AXIS_TVALID         : out std_logic;
      M3_AXIS_TREADY         : in  std_logic;
      S3_AXIS_TLAST          : in  std_logic;
      S3_AXIS_TDATA          : in  std_logic_vector(C_S3_AXIS_DATA_WIDTH-1 downto 0);
      S3_AXIS_TVALID         : in  std_logic;
      S3_AXIS_TREADY         : out std_logic;
      M4_AXIS_TLAST          : out std_logic;
      M4_AXIS_TDATA          : out std_logic_vector(C_M4_AXIS_DATA_WIDTH-1 downto 0);
      M4_AXIS_TVALID         : out std_logic;
      M4_AXIS_TREADY         : in  std_logic;
      S4_AXIS_TLAST          : in  std_logic;
      S4_AXIS_TDATA          : in  std_logic_vector(C_S4_AXIS_DATA_WIDTH-1 downto 0);
      S4_AXIS_TVALID         : in  std_logic;
      S4_AXIS_TREADY         : out std_logic;
      M5_AXIS_TLAST          : out std_logic;
      M5_AXIS_TDATA          : out std_logic_vector(C_M5_AXIS_DATA_WIDTH-1 downto 0);
      M5_AXIS_TVALID         : out std_logic;
      M5_AXIS_TREADY         : in  std_logic;
      S5_AXIS_TLAST          : in  std_logic;
      S5_AXIS_TDATA          : in  std_logic_vector(C_S5_AXIS_DATA_WIDTH-1 downto 0);
      S5_AXIS_TVALID         : in  std_logic;
      S5_AXIS_TREADY         : out std_logic;
      M6_AXIS_TLAST          : out std_logic;
      M6_AXIS_TDATA          : out std_logic_vector(C_M6_AXIS_DATA_WIDTH-1 downto 0);
      M6_AXIS_TVALID         : out std_logic;
      M6_AXIS_TREADY         : in  std_logic;
      S6_AXIS_TLAST          : in  std_logic;
      S6_AXIS_TDATA          : in  std_logic_vector(C_S6_AXIS_DATA_WIDTH-1 downto 0);
      S6_AXIS_TVALID         : in  std_logic;
      S6_AXIS_TREADY         : out std_logic;
      M7_AXIS_TLAST          : out std_logic;
      M7_AXIS_TDATA          : out std_logic_vector(C_M7_AXIS_DATA_WIDTH-1 downto 0);
      M7_AXIS_TVALID         : out std_logic;
      M7_AXIS_TREADY         : in  std_logic;
      S7_AXIS_TLAST          : in  std_logic;
      S7_AXIS_TDATA          : in  std_logic_vector(C_S7_AXIS_DATA_WIDTH-1 downto 0);
      S7_AXIS_TVALID         : in  std_logic;
      S7_AXIS_TREADY         : out std_logic;
      M8_AXIS_TLAST          : out std_logic;
      M8_AXIS_TDATA          : out std_logic_vector(C_M8_AXIS_DATA_WIDTH-1 downto 0);
      M8_AXIS_TVALID         : out std_logic;
      M8_AXIS_TREADY         : in  std_logic;
      S8_AXIS_TLAST          : in  std_logic;
      S8_AXIS_TDATA          : in  std_logic_vector(C_S8_AXIS_DATA_WIDTH-1 downto 0);
      S8_AXIS_TVALID         : in  std_logic;
      S8_AXIS_TREADY         : out std_logic;
      M9_AXIS_TLAST          : out std_logic;
      M9_AXIS_TDATA          : out std_logic_vector(C_M9_AXIS_DATA_WIDTH-1 downto 0);
      M9_AXIS_TVALID         : out std_logic;
      M9_AXIS_TREADY         : in  std_logic;
      S9_AXIS_TLAST          : in  std_logic;
      S9_AXIS_TDATA          : in  std_logic_vector(C_S9_AXIS_DATA_WIDTH-1 downto 0);
      S9_AXIS_TVALID         : in  std_logic;
      S9_AXIS_TREADY         : out std_logic;
      M10_AXIS_TLAST         : out std_logic;
      M10_AXIS_TDATA         : out std_logic_vector(C_M10_AXIS_DATA_WIDTH-1 downto 0);
      M10_AXIS_TVALID        : out std_logic;
      M10_AXIS_TREADY        : in  std_logic;
      S10_AXIS_TLAST         : in  std_logic;
      S10_AXIS_TDATA         : in  std_logic_vector(C_S10_AXIS_DATA_WIDTH-1 downto 0);
      S10_AXIS_TVALID        : in  std_logic;
      S10_AXIS_TREADY        : out std_logic;
      M11_AXIS_TLAST         : out std_logic;
      M11_AXIS_TDATA         : out std_logic_vector(C_M11_AXIS_DATA_WIDTH-1 downto 0);
      M11_AXIS_TVALID        : out std_logic;
      M11_AXIS_TREADY        : in  std_logic;
      S11_AXIS_TLAST         : in  std_logic;
      S11_AXIS_TDATA         : in  std_logic_vector(C_S11_AXIS_DATA_WIDTH-1 downto 0);
      S11_AXIS_TVALID        : in  std_logic;
      S11_AXIS_TREADY        : out std_logic;
      M12_AXIS_TLAST         : out std_logic;
      M12_AXIS_TDATA         : out std_logic_vector(C_M12_AXIS_DATA_WIDTH-1 downto 0);
      M12_AXIS_TVALID        : out std_logic;
      M12_AXIS_TREADY        : in  std_logic;
      S12_AXIS_TLAST         : in  std_logic;
      S12_AXIS_TDATA         : in  std_logic_vector(C_S12_AXIS_DATA_WIDTH-1 downto 0);
      S12_AXIS_TVALID        : in  std_logic;
      S12_AXIS_TREADY        : out std_logic;
      M13_AXIS_TLAST         : out std_logic;
      M13_AXIS_TDATA         : out std_logic_vector(C_M13_AXIS_DATA_WIDTH-1 downto 0);
      M13_AXIS_TVALID        : out std_logic;
      M13_AXIS_TREADY        : in  std_logic;
      S13_AXIS_TLAST         : in  std_logic;
      S13_AXIS_TDATA         : in  std_logic_vector(C_S13_AXIS_DATA_WIDTH-1 downto 0);
      S13_AXIS_TVALID        : in  std_logic;
      S13_AXIS_TREADY        : out std_logic;
      M14_AXIS_TLAST         : out std_logic;
      M14_AXIS_TDATA         : out std_logic_vector(C_M14_AXIS_DATA_WIDTH-1 downto 0);
      M14_AXIS_TVALID        : out std_logic;
      M14_AXIS_TREADY        : in  std_logic;
      S14_AXIS_TLAST         : in  std_logic;
      S14_AXIS_TDATA         : in  std_logic_vector(C_S14_AXIS_DATA_WIDTH-1 downto 0);
      S14_AXIS_TVALID        : in  std_logic;
      S14_AXIS_TREADY        : out std_logic;
      M15_AXIS_TLAST         : out std_logic;
      M15_AXIS_TDATA         : out std_logic_vector(C_M15_AXIS_DATA_WIDTH-1 downto 0);
      M15_AXIS_TVALID        : out std_logic;
      M15_AXIS_TREADY        : in  std_logic;
      S15_AXIS_TLAST         : in  std_logic;
      S15_AXIS_TDATA         : in  std_logic_vector(C_S15_AXIS_DATA_WIDTH-1 downto 0);
      S15_AXIS_TVALID        : in  std_logic;
      S15_AXIS_TREADY        : out std_logic;
      ICACHE_FSL_IN_CLK      : out std_logic;
      ICACHE_FSL_IN_READ     : out std_logic;
      ICACHE_FSL_IN_DATA     : in  std_logic_vector(0 to 31);
      ICACHE_FSL_IN_CONTROL  : in  std_logic;
      ICACHE_FSL_IN_EXISTS   : in  std_logic;
      ICACHE_FSL_OUT_CLK     : out std_logic;
      ICACHE_FSL_OUT_WRITE   : out std_logic;
      ICACHE_FSL_OUT_DATA    : out std_logic_vector(0 to 31);
      ICACHE_FSL_OUT_CONTROL : out std_logic;
      ICACHE_FSL_OUT_FULL    : in  std_logic;
      DCACHE_FSL_IN_CLK      : out std_logic;
      DCACHE_FSL_IN_READ     : out std_logic;
      DCACHE_FSL_IN_DATA     : in  std_logic_vector(0 to 31);
      DCACHE_FSL_IN_CONTROL  : in  std_logic;
      DCACHE_FSL_IN_EXISTS   : in  std_logic;
      DCACHE_FSL_OUT_CLK     : out std_logic;
      DCACHE_FSL_OUT_WRITE   : out std_logic;
      DCACHE_FSL_OUT_DATA    : out std_logic_vector(0 to 31);
      DCACHE_FSL_OUT_CONTROL : out std_logic;
      DCACHE_FSL_OUT_FULL    : in  std_logic
    );
  end component;

  component lmb_v10 is
    generic (
      C_LMB_NUM_SLAVES : integer;
      C_LMB_AWIDTH     : integer;
      C_LMB_DWIDTH     : integer;
      C_EXT_RESET_HIGH : integer
      );
    port (
      LMB_Clk         : in  std_logic;
      SYS_Rst         : in  std_logic;
      LMB_Rst         : out std_logic;
      M_ABus          : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
      M_ReadStrobe    : in  std_logic;
      M_WriteStrobe   : in  std_logic;
      M_AddrStrobe    : in  std_logic;
      M_DBus          : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
      M_BE            : in  std_logic_vector(0 to (C_LMB_DWIDTH+7)/8-1);
      Sl_DBus         : in  std_logic_vector(0 to (C_LMB_DWIDTH*C_LMB_NUM_SLAVES)-1);
      Sl_Ready        : in  std_logic_vector(0 to C_LMB_NUM_SLAVES-1);
      Sl_Wait         : in  std_logic_vector(0 to C_LMB_NUM_SLAVES-1);
      Sl_UE           : in  std_logic_vector(0 to C_LMB_NUM_SLAVES-1);
      Sl_CE           : in  std_logic_vector(0 to C_LMB_NUM_SLAVES-1);
      LMB_ABus        : out std_logic_vector(0 to C_LMB_AWIDTH-1);
      LMB_ReadStrobe  : out std_logic;
      LMB_WriteStrobe : out std_logic;
      LMB_AddrStrobe  : out std_logic;
      LMB_ReadDBus    : out std_logic_vector(0 to C_LMB_DWIDTH-1);
      LMB_WriteDBus   : out std_logic_vector(0 to C_LMB_DWIDTH-1);
      LMB_Ready       : out std_logic;
      LMB_Wait        : out std_logic;
      LMB_UE          : out std_logic;
      LMB_CE          : out std_logic;
      LMB_BE          : out std_logic_vector(0 to (C_LMB_DWIDTH+7)/8-1)
      );
  end component;

  component lmb_bram_if_cntlr is
    generic (
      C_BASEADDR                 : std_logic_vector(0 to 31);
      C_HIGHADDR                 : std_logic_vector(0 to 31);
      C_FAMILY                   : string;
      C_MASK                     : std_logic_vector(0 to 31);
      C_LMB_AWIDTH               : integer;
      C_LMB_DWIDTH               : integer;
      C_ECC                      : integer;
      C_INTERCONNECT             : integer;
      C_FAULT_INJECT             : integer;
      C_CE_FAILING_REGISTERS     : integer;
      C_UE_FAILING_REGISTERS     : integer;
      C_ECC_STATUS_REGISTERS     : integer;
      C_ECC_ONOFF_REGISTER       : integer;
      C_ECC_ONOFF_RESET_VALUE    : integer;
      C_CE_COUNTER_WIDTH         : integer;
      C_WRITE_ACCESS             : integer;
      C_SPLB_CTRL_BASEADDR       : std_logic_vector;
      C_SPLB_CTRL_HIGHADDR       : std_logic_vector;
      C_SPLB_CTRL_AWIDTH         : integer;
      C_SPLB_CTRL_DWIDTH         : integer;
      C_SPLB_CTRL_P2P            : integer;
      C_SPLB_CTRL_MID_WIDTH      : integer;
      C_SPLB_CTRL_NUM_MASTERS    : integer;
      C_SPLB_CTRL_SUPPORT_BURSTS : integer;
      C_SPLB_CTRL_NATIVE_DWIDTH  : integer;
      C_S_AXI_CTRL_BASEADDR      : std_logic_vector(31 downto 0);
      C_S_AXI_CTRL_HIGHADDR      : std_logic_vector(31 downto 0);
      C_S_AXI_CTRL_ADDR_WIDTH    : integer;
      C_S_AXI_CTRL_DATA_WIDTH    : integer
      );
    port (
      LMB_Clk                  : in  std_logic;
      LMB_Rst                  : in  std_logic;
      LMB_ABus                 : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
      LMB_WriteDBus            : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
      LMB_AddrStrobe           : in  std_logic;
      LMB_ReadStrobe           : in  std_logic;
      LMB_WriteStrobe          : in  std_logic;
      LMB_BE                   : in  std_logic_vector(0 to C_LMB_DWIDTH/8-1);
      Sl_DBus                  : out std_logic_vector(0 to C_LMB_DWIDTH-1);
      Sl_Ready                 : out std_logic;
      Sl_Wait                  : out std_logic;
      Sl_UE                    : out std_logic;
      Sl_CE                    : out std_logic;
      BRAM_Rst_A               : out std_logic;
      BRAM_Clk_A               : out std_logic;
      BRAM_EN_A                : out std_logic;
      BRAM_WEN_A               : out std_logic_vector(0 to ((C_LMB_DWIDTH+8*C_ECC)/8)-1);
      BRAM_Addr_A              : out std_logic_vector(0 to C_LMB_AWIDTH-1);
      BRAM_Din_A               : in  std_logic_vector(0 to C_LMB_DWIDTH-1+8*C_ECC);
      BRAM_Dout_A              : out std_logic_vector(0 to C_LMB_DWIDTH-1+8*C_ECC);
      Interrupt                : out std_logic;
      SPLB_CTRL_PLB_ABus       : in  std_logic_vector(0 to 31);
      SPLB_CTRL_PLB_PAValid    : in  std_logic;
      SPLB_CTRL_PLB_masterID   : in  std_logic_vector(0 to (C_SPLB_CTRL_MID_WIDTH-1));
      SPLB_CTRL_PLB_RNW        : in  std_logic;
      SPLB_CTRL_PLB_BE         : in  std_logic_vector(0 to ((C_SPLB_CTRL_DWIDTH/8)-1));
      SPLB_CTRL_PLB_size       : in  std_logic_vector(0 to 3);
      SPLB_CTRL_PLB_type       : in  std_logic_vector(0 to 2);
      SPLB_CTRL_PLB_wrDBus     : in  std_logic_vector(0 to (C_SPLB_CTRL_DWIDTH-1));
      SPLB_CTRL_Sl_addrAck     : out std_logic;
      SPLB_CTRL_Sl_SSize       : out std_logic_vector(0 to 1);
      SPLB_CTRL_Sl_wait        : out std_logic;
      SPLB_CTRL_Sl_rearbitrate : out std_logic;
      SPLB_CTRL_Sl_wrDAck      : out std_logic;
      SPLB_CTRL_Sl_wrComp      : out std_logic;
      SPLB_CTRL_Sl_rdDBus      : out std_logic_vector(0 to (C_SPLB_CTRL_DWIDTH-1));
      SPLB_CTRL_Sl_rdDAck      : out std_logic;
      SPLB_CTRL_Sl_rdComp      : out std_logic;
      SPLB_CTRL_Sl_MBusy       : out std_logic_vector(0 to (C_SPLB_CTRL_NUM_MASTERS-1));
      SPLB_CTRL_Sl_MWrErr      : out std_logic_vector(0 to (C_SPLB_CTRL_NUM_MASTERS-1));
      SPLB_CTRL_Sl_MRdErr      : out std_logic_vector(0 to (C_SPLB_CTRL_NUM_MASTERS-1));
      SPLB_CTRL_PLB_UABus      : in  std_logic_vector(0 to 31);
      SPLB_CTRL_PLB_SAValid    : in  std_logic;
      SPLB_CTRL_PLB_rdPrim     : in  std_logic;
      SPLB_CTRL_PLB_wrPrim     : in  std_logic;
      SPLB_CTRL_PLB_abort      : in  std_logic;
      SPLB_CTRL_PLB_busLock    : in  std_logic;
      SPLB_CTRL_PLB_MSize      : in  std_logic_vector(0 to 1);
      SPLB_CTRL_PLB_lockErr    : in  std_logic;
      SPLB_CTRL_PLB_wrBurst    : in  std_logic;
      SPLB_CTRL_PLB_rdBurst    : in  std_logic;
      SPLB_CTRL_PLB_wrPendReq  : in  std_logic;
      SPLB_CTRL_PLB_rdPendReq  : in  std_logic;
      SPLB_CTRL_PLB_wrPendPri  : in  std_logic_vector(0 to 1);
      SPLB_CTRL_PLB_rdPendPri  : in  std_logic_vector(0 to 1);
      SPLB_CTRL_PLB_reqPri     : in  std_logic_vector(0 to 1);
      SPLB_CTRL_PLB_TAttribute : in  std_logic_vector(0 to 15);
      SPLB_CTRL_Sl_wrBTerm     : out std_logic;
      SPLB_CTRL_Sl_rdWdAddr    : out std_logic_vector(0 to 3);
      SPLB_CTRL_Sl_rdBTerm     : out std_logic;
      SPLB_CTRL_Sl_MIRQ        : out std_logic_vector(0 to (C_SPLB_CTRL_NUM_MASTERS-1));
      S_AXI_CTRL_ACLK          : in  std_logic;
      S_AXI_CTRL_ARESETN       : in  std_logic;
      S_AXI_CTRL_AWADDR        : in  std_logic_vector((C_S_AXI_CTRL_ADDR_WIDTH-1) downto 0);
      S_AXI_CTRL_AWVALID       : in  std_logic;
      S_AXI_CTRL_AWREADY       : out std_logic;
      S_AXI_CTRL_WDATA         : in  std_logic_vector((C_S_AXI_CTRL_DATA_WIDTH-1) downto 0);
      S_AXI_CTRL_WSTRB         : in  std_logic_vector(((C_S_AXI_CTRL_DATA_WIDTH/8)-1) downto 0);
      S_AXI_CTRL_WVALID        : in  std_logic;
      S_AXI_CTRL_WREADY        : out std_logic;
      S_AXI_CTRL_BRESP         : out std_logic_vector(1 downto 0);
      S_AXI_CTRL_BVALID        : out std_logic;
      S_AXI_CTRL_BREADY        : in  std_logic;
      S_AXI_CTRL_ARADDR        : in  std_logic_vector((C_S_AXI_CTRL_ADDR_WIDTH-1) downto 0);
      S_AXI_CTRL_ARVALID       : in  std_logic;
      S_AXI_CTRL_ARREADY       : out std_logic;
      S_AXI_CTRL_RDATA         : out std_logic_vector((C_S_AXI_CTRL_DATA_WIDTH-1) downto 0);
      S_AXI_CTRL_RRESP         : out std_logic_vector(1 downto 0);
      S_AXI_CTRL_RVALID        : out std_logic;
      S_AXI_CTRL_RREADY        : in  std_logic
    );
  end component;

  component lmb_bram is
    generic (
      C_MEMSIZE             : integer := 16#8000#;
      C_MICROBLAZE_INSTANCE : string  := "microblaze_0";
      C_FAMILY              : string  := "virtex5");
    port (
      BRAM_Rst_A  : in  std_logic;
      BRAM_Clk_A  : in  std_logic;
      BRAM_EN_A   : in  std_logic;
      BRAM_WEN_A  : in  std_logic_vector(0 to 3);
      BRAM_Addr_A : in  std_logic_vector(0 to 31);
      BRAM_Din_A  : in  std_logic_vector(0 to 31);
      BRAM_Dout_A : out std_logic_vector(0 to 31);
      BRAM_Rst_B  : in  std_logic;
      BRAM_Clk_B  : in  std_logic;
      BRAM_EN_B   : in  std_logic;
      BRAM_WEN_B  : in  std_logic_vector(0 to 3);
      BRAM_Addr_B : in  std_logic_vector(0 to 31);
      BRAM_Din_B  : in  std_logic_vector(0 to 31);
      BRAM_Dout_B : out std_logic_vector(0 to 31));
  end component;

--  component mdm is
--    generic (
--      C_FAMILY              : string;
--      C_JTAG_CHAIN          : integer;
--      C_INTERCONNECT        : integer;
--      C_BASEADDR            : std_logic_vector;
--      C_HIGHADDR            : std_logic_vector;
--      C_SPLB_AWIDTH         : integer;
--      C_SPLB_DWIDTH         : integer;
--      C_SPLB_P2P            : integer;
--      C_SPLB_MID_WIDTH      : integer;
--      C_SPLB_NUM_MASTERS    : integer;
--      C_SPLB_NATIVE_DWIDTH  : integer;
--      C_SPLB_SUPPORT_BURSTS : integer;
--      C_MB_DBG_PORTS        : integer;
--      C_USE_UART            : integer;
--      C_S_AXI_ADDR_WIDTH    : integer;
--      C_S_AXI_DATA_WIDTH    : integer
--      );
--    port (
--      Interrupt        : out std_logic;
--      Debug_SYS_Rst    : out std_logic;
--      Ext_BRK          : out std_logic;
--      Ext_NM_BRK       : out std_logic;
--      S_AXI_ACLK       : in  std_logic;
--      S_AXI_ARESETN    : in  std_logic;
--      S_AXI_AWADDR     : in  std_logic_vector(31 downto 0);
--      S_AXI_AWVALID    : in  std_logic;
--      S_AXI_AWREADY    : out std_logic;
--      S_AXI_WDATA      : in  std_logic_vector(31 downto 0);
--      S_AXI_WSTRB      : in  std_logic_vector(3 downto 0);
--      S_AXI_WVALID     : in  std_logic;
--      S_AXI_WREADY     : out std_logic;
--      S_AXI_BRESP      : out std_logic_vector(1 downto 0);
--      S_AXI_BVALID     : out std_logic;
--      S_AXI_BREADY     : in  std_logic;
--      S_AXI_ARADDR     : in  std_logic_vector(31 downto 0);
--      S_AXI_ARVALID    : in  std_logic;
--      S_AXI_ARREADY    : out std_logic;
--      S_AXI_RDATA      : out std_logic_vector(31 downto 0);
--      S_AXI_RRESP      : out std_logic_vector(1 downto 0);
--      S_AXI_RVALID     : out std_logic;
--      S_AXI_RREADY     : in  std_logic;
--      SPLB_Clk         : in  std_logic;
--      SPLB_Rst         : in  std_logic;
--      PLB_ABus         : in  std_logic_vector(0 to 31);
--      PLB_UABus        : in  std_logic_vector(0 to 31);
--      PLB_PAValid      : in  std_logic;
--      PLB_SAValid      : in  std_logic;
--      PLB_rdPrim       : in  std_logic;
--      PLB_wrPrim       : in  std_logic;
--      PLB_masterID     : in  std_logic_vector(0 to 2);
--      PLB_abort        : in  std_logic;
--      PLB_busLock      : in  std_logic;
--      PLB_RNW          : in  std_logic;
--      PLB_BE           : in  std_logic_vector(0 to 3);
--      PLB_MSize        : in  std_logic_vector(0 to 1);
--      PLB_size         : in  std_logic_vector(0 to 3);
--      PLB_type         : in  std_logic_vector(0 to 2);
--      PLB_lockErr      : in  std_logic;
--      PLB_wrDBus       : in  std_logic_vector(0 to 31);
--      PLB_wrBurst      : in  std_logic;
--      PLB_rdBurst      : in  std_logic;
--      PLB_wrPendReq    : in  std_logic;
--      PLB_rdPendReq    : in  std_logic;
--      PLB_wrPendPri    : in  std_logic_vector(0 to 1);
--      PLB_rdPendPri    : in  std_logic_vector(0 to 1);
--      PLB_reqPri       : in  std_logic_vector(0 to 1);
--      PLB_TAttribute   : in  std_logic_vector(0 to 15);
--      Sl_addrAck       : out std_logic;
--      Sl_SSize         : out std_logic_vector(0 to 1);
--      Sl_wait          : out std_logic;
--      Sl_rearbitrate   : out std_logic;
--      Sl_wrDAck        : out std_logic;
--      Sl_wrComp        : out std_logic;
--      Sl_wrBTerm       : out std_logic;
--      Sl_rdDBus        : out std_logic_vector(0 to 31);
--      Sl_rdWdAddr      : out std_logic_vector(0 to 3);
--      Sl_rdDAck        : out std_logic;
--      Sl_rdComp        : out std_logic;
--      Sl_rdBTerm       : out std_logic;
--      Sl_MBusy         : out std_logic_vector(0 to 7);
--      Sl_MWrErr        : out std_logic_vector(0 to 7);
--      Sl_MRdErr        : out std_logic_vector(0 to 7);
--      Sl_MIRQ          : out std_logic_vector(0 to 7);
--      Dbg_Clk_0        : out std_logic;
--      Dbg_TDI_0        : out std_logic;
--      Dbg_TDO_0        : in  std_logic;
--      Dbg_Reg_En_0     : out std_logic_vector(0 to 7);
--      Dbg_Capture_0    : out std_logic;
--      Dbg_Shift_0      : out std_logic;
--      Dbg_Update_0     : out std_logic;
--      Dbg_Rst_0        : out std_logic;
--      Dbg_Clk_1        : out std_logic;
--      Dbg_TDI_1        : out std_logic;
--      Dbg_TDO_1        : in  std_logic;
--      Dbg_Reg_En_1     : out std_logic_vector(0 to 7);
--      Dbg_Capture_1    : out std_logic;
--      Dbg_Shift_1      : out std_logic;
--      Dbg_Update_1     : out std_logic;
--      Dbg_Rst_1        : out std_logic;
--      Dbg_Clk_2        : out std_logic;
--      Dbg_TDI_2        : out std_logic;
--      Dbg_TDO_2        : in  std_logic;
--      Dbg_Reg_En_2     : out std_logic_vector(0 to 7);
--      Dbg_Capture_2    : out std_logic;
--      Dbg_Shift_2      : out std_logic;
--      Dbg_Update_2     : out std_logic;
--      Dbg_Rst_2        : out std_logic;
--      Dbg_Clk_3        : out std_logic;
--      Dbg_TDI_3        : out std_logic;
--      Dbg_TDO_3        : in  std_logic;
--      Dbg_Reg_En_3     : out std_logic_vector(0 to 7);
--      Dbg_Capture_3    : out std_logic;
--      Dbg_Shift_3      : out std_logic;
--      Dbg_Update_3     : out std_logic;
--      Dbg_Rst_3        : out std_logic;
--      Dbg_Clk_4        : out std_logic;
--      Dbg_TDI_4        : out std_logic;
--      Dbg_TDO_4        : in  std_logic;
--      Dbg_Reg_En_4     : out std_logic_vector(0 to 7);
--      Dbg_Capture_4    : out std_logic;
--      Dbg_Shift_4      : out std_logic;
--      Dbg_Update_4     : out std_logic;
--      Dbg_Rst_4        : out std_logic;
--      Dbg_Clk_5        : out std_logic;
--      Dbg_TDI_5        : out std_logic;
--      Dbg_TDO_5        : in  std_logic;
--      Dbg_Reg_En_5     : out std_logic_vector(0 to 7);
--      Dbg_Capture_5    : out std_logic;
--      Dbg_Shift_5      : out std_logic;
--      Dbg_Update_5     : out std_logic;
--      Dbg_Rst_5        : out std_logic;
--      Dbg_Clk_6        : out std_logic;
--      Dbg_TDI_6        : out std_logic;
--      Dbg_TDO_6        : in  std_logic;
--      Dbg_Reg_En_6     : out std_logic_vector(0 to 7);
--      Dbg_Capture_6    : out std_logic;
--      Dbg_Shift_6      : out std_logic;
--      Dbg_Update_6     : out std_logic;
--      Dbg_Rst_6        : out std_logic;
--      Dbg_Clk_7        : out std_logic;
--      Dbg_TDI_7        : out std_logic;
--      Dbg_TDO_7        : in  std_logic;
--      Dbg_Reg_En_7     : out std_logic_vector(0 to 7);
--      Dbg_Capture_7    : out std_logic;
--      Dbg_Shift_7      : out std_logic;
--      Dbg_Update_7     : out std_logic;
--      Dbg_Rst_7        : out std_logic;
--      bscan_tdi        : out std_logic;
--      bscan_reset      : out std_logic;
--      bscan_shift      : out std_logic;
--      bscan_update     : out std_logic;
--      bscan_capture    : out std_logic;
--      bscan_sel1       : out std_logic;
--      bscan_drck1      : out std_logic;
--      bscan_tdo1       : in  std_logic;
--      Ext_JTAG_DRCK    : out std_logic;
--      Ext_JTAG_RESET   : out std_logic;
--      Ext_JTAG_SEL     : out std_logic;
--      Ext_JTAG_CAPTURE : out std_logic;
--      Ext_JTAG_SHIFT   : out std_logic;
--      Ext_JTAG_UPDATE  : out std_logic;
--      Ext_JTAG_TDI     : out std_logic;
--      Ext_JTAG_TDO     : in  std_logic
--      );
--  end component;
--
  component iomodule is
    generic (
      C_FAMILY                : string                    := "Virtex5";
      C_FREQ                  : integer                   := 100000000;
      C_INSTANCE              : string                    := "iomodule";

      -- Local Memory Bus generics
      C_HIGHADDR              : std_logic_vector(0 to 31) := X"00000000";
      C_BASEADDR              : std_logic_vector(0 to 31) := X"FFFFFFFF";
      C_MASK                  : std_logic_vector(0 to 31) := X"FFFFFFFF";
      C_IO_HIGHADDR           : std_logic_vector(0 to 31) := X"00000000";
      C_IO_BASEADDR           : std_logic_vector(0 to 31) := X"FFFFFFFF";
      C_IO_MASK               : std_logic_vector(0 to 31) := X"FFFFFFFF";
      C_LMB_AWIDTH            : integer                   := 32;
      C_LMB_DWIDTH            : integer                   := 32;

      -- IO Bus
      C_USE_IO_BUS           : integer               := 0;

      -- UART generics
      C_USE_UART_RX          : integer               := 0;
      C_USE_UART_TX          : integer               := 0;
      C_UART_BAUDRATE        : integer               := 9600;
      C_UART_DATA_BITS       : integer range 5 to 8  := 8;
      C_UART_USE_PARITY      : integer               := 0;
      C_UART_ODD_PARITY      : integer               := 0;
      C_UART_RX_INTERRUPT    : integer               := 0;
      C_UART_TX_INTERRUPT    : integer               := 0;
      C_UART_ERROR_INTERRUPT : integer               := 0;

      -- FIT generics
      C_USE_FIT1        : integer               := 0;
      C_FIT1_No_CLOCKS  : integer               := 6216;
      C_FIT1_INTERRUPT  : integer               := 0;
      C_USE_FIT2        : integer               := 0;
      C_FIT2_No_CLOCKS  : integer               := 6216;
      C_FIT2_INTERRUPT  : integer               := 0;
      C_USE_FIT3        : integer               := 0;
      C_FIT3_No_CLOCKS  : integer               := 6216;
      C_FIT3_INTERRUPT  : integer               := 0;
      C_USE_FIT4        : integer               := 0;
      C_FIT4_No_CLOCKS  : integer               := 6216;
      C_FIT4_INTERRUPT  : integer               := 0;

      -- PIT generics
      C_USE_PIT1       : integer               := 0;
      C_PIT1_SIZE      : integer range 1 to 32 := 32;
      C_PIT1_READABLE  : integer               := 1;
      C_PIT1_PRESCALER : integer range 0 to 9  := 0;
      C_PIT1_INTERRUPT : integer               := 0;
      C_USE_PIT2       : integer               := 0;
      C_PIT2_SIZE      : integer range 1 to 32 := 32;
      C_PIT2_READABLE  : integer               := 1;
      C_PIT2_PRESCALER : integer range 0 to 9  := 0;
      C_PIT2_INTERRUPT : integer               := 0;
      C_USE_PIT3       : integer               := 0;
      C_PIT3_SIZE      : integer range 1 to 32 := 32;
      C_PIT3_READABLE  : integer               := 1;
      C_PIT3_PRESCALER : integer range 0 to 9  := 0;
      C_PIT3_INTERRUPT : integer               := 0;
      C_USE_PIT4       : integer               := 0;
      C_PIT4_SIZE      : integer range 1 to 32 := 32;
      C_PIT4_READABLE  : integer               := 1;
      C_PIT4_PRESCALER : integer range 0 to 9  := 0;
      C_PIT4_INTERRUPT : integer               := 0;

      -- GPO Generics
      C_USE_GPO1  : integer := 0;
      C_GPO1_SIZE : integer range 1 to 32 := 32;
      C_GPO1_INIT : std_logic_vector(31 downto 0) := (others => '0');
      C_USE_GPO2  : integer := 0;
      C_GPO2_SIZE : integer range 1 to 32 := 32;
      C_GPO2_INIT : std_logic_vector(31 downto 0) := (others => '0');
      C_USE_GPO3  : integer := 0;
      C_GPO3_SIZE : integer range 1 to 32 := 32;
      C_GPO3_INIT : std_logic_vector(31 downto 0) := (others => '0');
      C_USE_GPO4  : integer := 0;
      C_GPO4_SIZE : integer range 1 to 32 := 32;
      C_GPO4_INIT : std_logic_vector(31 downto 0) := (others => '0');

      -- GPI Generics
      C_USE_GPI1  : integer := 0;
      C_GPI1_SIZE : integer range 1 to 32 := 32;
      C_USE_GPI2  : integer := 0;
      C_GPI2_SIZE : integer range 1 to 32 := 32;
      C_USE_GPI3  : integer := 0;
      C_GPI3_SIZE : integer range 1 to 32 := 32;
      C_USE_GPI4  : integer := 0;
      C_GPI4_SIZE : integer range 1 to 32 := 32;

      -- Interrupt Handler Generics
      C_INTC_USE_EXT_INTR : integer                   := 0;
      C_INTC_INTR_SIZE    : integer range 1 to 16     := 1;
      C_INTC_LEVEL_EDGE   : std_logic_vector(15 downto 0) := X"0000";
      C_INTC_POSITIVE     : std_logic_vector(15 downto 0) := X"FFFF"
    );
    port (
      CLK             : in  std_logic;
      Rst             : in  std_logic;
      IO_Addr_Strobe  : out std_logic;
      IO_Read_Strobe  : out std_logic;
      IO_Write_Strobe : out std_logic;
      IO_Address      : out std_logic_vector(C_LMB_AWIDTH-1 downto 0);
      IO_Byte_Enable  : out std_logic_vector((C_LMB_DWIDTH/8 - 1) downto 0);
      IO_Write_Data   : out std_logic_vector(C_LMB_DWIDTH-1 downto 0);
      IO_Read_Data    : in  std_logic_vector(C_LMB_DWIDTH-1 downto 0);
      IO_Ready        : in  std_logic;
      UART_Rx         : in  std_logic;
      UART_Tx         : out std_logic;
      UART_Interrupt  : out std_logic;
      FIT1_Interrupt  : out std_logic;
      FIT1_Toggle     : out std_logic;
      FIT2_Interrupt  : out std_logic;
      FIT2_Toggle     : out std_logic;
      FIT3_Interrupt  : out std_logic;
      FIT3_Toggle     : out std_logic;
      FIT4_Interrupt  : out std_logic;
      FIT4_Toggle     : out std_logic;
      PIT1_Enable     : in  std_logic;
      PIT1_Interrupt  : out std_logic;
      PIT1_Toggle     : out std_logic;
      PIT2_Enable     : in  std_logic;
      PIT2_Interrupt  : out std_logic;
      PIT2_Toggle     : out std_logic;
      PIT3_Enable     : in  std_logic;
      PIT3_Interrupt  : out std_logic;
      PIT3_Toggle     : out std_logic;
      PIT4_Enable     : in  std_logic;
      PIT4_Interrupt  : out std_logic;
      PIT4_Toggle     : out std_logic;
      GPO1            : out std_logic_vector(C_GPO1_SIZE-1 downto 0);
      GPO2            : out std_logic_vector(C_GPO2_SIZE-1 downto 0);
      GPO3            : out std_logic_vector(C_GPO3_SIZE-1 downto 0);
      GPO4            : out std_logic_vector(C_GPO4_SIZE-1 downto 0);
      GPI1            : in  std_logic_vector(C_GPI1_SIZE-1 downto 0);
      GPI2            : in  std_logic_vector(C_GPI2_SIZE-1 downto 0);
      GPI3            : in  std_logic_vector(C_GPI3_SIZE-1 downto 0);
      GPI4            : in  std_logic_vector(C_GPI4_SIZE-1 downto 0);
      INTC_Interrupt  : in  std_logic_vector(C_INTC_INTR_SIZE-1 downto 0);
      INTC_IRQ        : out std_logic;
      LMB_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
      LMB_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
      LMB_AddrStrobe  : in  std_logic;
      LMB_ReadStrobe  : in  std_logic;
      LMB_WriteStrobe : in  std_logic;
      LMB_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
      Sl_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
      Sl_Ready        : out std_logic;
      Sl_Wait         : out std_logic;
      Sl_UE           : out std_logic;
      Sl_CE           : out std_logic
    );
  end component;

  function MemSize2Addr(MemSize : integer) return std_logic_vector is
  begin
    case MemSize is
      when 16#800#   => return X"00000800";
      when 16#1000#  => return X"00001000";
      when 16#2000#  => return X"00002000";
      when 16#4000#  => return X"00004000";
      when 16#8000#  => return X"00008000";
      when 16#10000# => return X"00010000";
      when 16#20000# => return X"00020000";
      when others    => return X"00000000";
    end case;
  end function MemSize2Addr;

  function MemSize2HighAddr(MemSize : integer) return std_logic_vector is
  begin
    case MemSize is
      when 16#800#   => return X"000007FF";
      when 16#1000#  => return X"00000FFF";
      when 16#2000#  => return X"00001FFF";
      when 16#4000#  => return X"00003FFF";
      when 16#8000#  => return X"00007FFF";
      when 16#10000# => return X"0000FFFF";
      when 16#20000# => return X"0001FFFF";
      when others    => return X"00000000";
    end case;
  end function MemSize2HighAddr;

  -- Internal signals
  signal Debug_SYS_Rst                    : std_logic;
  signal Ext_BRK                          : std_logic;
  signal Ext_NM_BRK                       : std_logic;
  signal Interrupt                        : std_logic;
  signal LMB_Rst                          : std_logic;
  signal dlmb_LMB_ABus                    : std_logic_vector(0 to 31);
  signal dlmb_LMB_AddrStrobe              : std_logic;
  signal dlmb_LMB_BE                      : std_logic_vector(0 to 3);
  signal dlmb_LMB_CE                      : std_logic;
  signal dlmb_LMB_ReadDBus                : std_logic_vector(0 to 31);
  signal dlmb_LMB_ReadStrobe              : std_logic;
  signal dlmb_LMB_Ready                   : std_logic;
  signal dlmb_LMB_Rst                     : std_logic;
  signal dlmb_LMB_UE                      : std_logic;
  signal dlmb_LMB_Wait                    : std_logic;
  signal dlmb_LMB_WriteDBus               : std_logic_vector(0 to 31);
  signal dlmb_LMB_WriteStrobe             : std_logic;
  signal dlmb_M_ABus                      : std_logic_vector(0 to 31);
  signal dlmb_M_AddrStrobe                : std_logic;
  signal dlmb_M_BE                        : std_logic_vector(0 to 3);
  signal dlmb_M_DBus                      : std_logic_vector(0 to 31);
  signal dlmb_M_ReadStrobe                : std_logic;
  signal dlmb_M_WriteStrobe               : std_logic;
  signal dlmb_Sl_CE                       : std_logic_vector(0 to 1);
  signal dlmb_Sl_DBus                     : std_logic_vector(0 to 63);
  signal dlmb_Sl_Ready                    : std_logic_vector(0 to 1);
  signal dlmb_Sl_UE                       : std_logic_vector(0 to 1);
  signal dlmb_Sl_Wait                     : std_logic_vector(0 to 1);
  signal dlmb_port_BRAM_Addr              : std_logic_vector(0 to 31);
  signal dlmb_port_BRAM_Clk               : std_logic;
  signal dlmb_port_BRAM_Din               : std_logic_vector(0 to 31);
  signal dlmb_port_BRAM_Dout              : std_logic_vector(0 to 31);
  signal dlmb_port_BRAM_EN                : std_logic;
  signal dlmb_port_BRAM_Rst               : std_logic;
  signal dlmb_port_BRAM_WEN               : std_logic_vector(0 to 3);
  signal ilmb_LMB_ABus                    : std_logic_vector(0 to 31);
  signal ilmb_LMB_AddrStrobe              : std_logic;
  signal ilmb_LMB_BE                      : std_logic_vector(0 to 3);
  signal ilmb_LMB_CE                      : std_logic;
  signal ilmb_LMB_ReadDBus                : std_logic_vector(0 to 31);
  signal ilmb_LMB_ReadStrobe              : std_logic;
  signal ilmb_LMB_Ready                   : std_logic;
  signal ilmb_LMB_Rst                     : std_logic;
  signal ilmb_LMB_UE                      : std_logic;
  signal ilmb_LMB_Wait                    : std_logic;
  signal ilmb_LMB_WriteDBus               : std_logic_vector(0 to 31);
  signal ilmb_LMB_WriteStrobe             : std_logic;
  signal ilmb_M_ABus                      : std_logic_vector(0 to 31);
  signal ilmb_M_AddrStrobe                : std_logic;
  signal ilmb_M_ReadStrobe                : std_logic;
  signal ilmb_Sl_CE                       : std_logic_vector(0 to 0);
  signal ilmb_Sl_DBus                     : std_logic_vector(0 to 31);
  signal ilmb_Sl_Ready                    : std_logic_vector(0 to 0);
  signal ilmb_Sl_UE                       : std_logic_vector(0 to 0);
  signal ilmb_Sl_Wait                     : std_logic_vector(0 to 0);
  signal ilmb_port_BRAM_Addr              : std_logic_vector(0 to 31);
  signal ilmb_port_BRAM_Clk               : std_logic;
  signal ilmb_port_BRAM_Din               : std_logic_vector(0 to 31);
  signal ilmb_port_BRAM_Dout              : std_logic_vector(0 to 31);
  signal ilmb_port_BRAM_EN                : std_logic;
  signal ilmb_port_BRAM_Rst               : std_logic;
  signal ilmb_port_BRAM_WEN               : std_logic_vector(0 to 3);
  signal microblaze_0_mdm_bus_Dbg_Capture : std_logic;
  signal microblaze_0_mdm_bus_Dbg_Clk     : std_logic;
  signal microblaze_0_mdm_bus_Dbg_Reg_En  : std_logic_vector(0 to 7);
  signal microblaze_0_mdm_bus_Dbg_Shift   : std_logic;
  signal microblaze_0_mdm_bus_Dbg_TDI     : std_logic;
  signal microblaze_0_mdm_bus_Dbg_TDO     : std_logic;
  signal microblaze_0_mdm_bus_Dbg_Update  : std_logic;
  signal microblaze_0_mdm_bus_Debug_Rst   : std_logic;
  signal trace_instruction_i              : std_logic_vector(0 to 31);
  signal trace_valid_instr_i              : std_logic;
  signal trace_pc_i                       : std_logic_vector(0 to 31);
  signal trace_reg_write_i                : std_logic;
  signal trace_reg_addr_i                 : std_logic_vector(0 to 4);
  signal trace_msr_reg_i                  : std_logic_vector(0 to 14);
  signal trace_new_reg_value_i            : std_logic_vector(0 to 31);
  signal trace_jump_taken_i               : std_logic;
  signal trace_delay_slot_i               : std_logic;
  signal trace_data_address_i             : std_logic_vector(0 to 31);
  signal trace_data_access_i              : std_logic;
  signal trace_data_read_i                : std_logic;
  signal trace_data_write_i               : std_logic;
  signal trace_data_write_value_i         : std_logic_vector(0 to 31);
  signal trace_data_byte_enable_i         : std_logic_vector(0 to 3);
  signal trace_mb_halted_i                : std_logic;
  signal net_gnd0                         : std_logic;
  signal net_gnd1                         : std_logic_vector(0 downto 0);
  signal net_gnd2                         : std_logic_vector(0 to 1);
  signal net_gnd3                         : std_logic_vector(0 to 2);
  signal net_gnd4                         : std_logic_vector(0 to 3);
  signal net_gnd15                        : std_logic_vector(0 to 14);
  signal net_gnd16                        : std_logic_vector(0 to 15);
  signal net_gnd32                        : std_logic_vector(0 to 31);
  signal net_vcc0                         : std_logic;

begin

  -- Internal assignments

  net_gnd0 <= '0';
  net_gnd1(0 downto 0) <= B"0";
  net_gnd15(0 to 14) <= B"000000000000000";
  net_gnd16(0 to 15) <= B"0000000000000000";
  net_gnd2(0 to 1) <= B"00";
  net_gnd3(0 to 2) <= B"000";
  net_gnd32(0 to 31) <= B"00000000000000000000000000000000";
  net_gnd4(0 to 3) <= B"0000";
  net_vcc0 <= '1';

  filter_reset : process(Clk) is
    variable reset_vec : std_logic_vector(0 to 3);
  begin
    if (Clk'event and Clk = '1') then
      reset_Vec(3) := reset_vec(2);
      reset_Vec(2) := reset_vec(1);
      reset_Vec(1) := reset_vec(0);
      reset_Vec(0) := Debug_Sys_Rst or Reset;
      LMB_Rst      <= (reset_vec(3) and reset_vec(2)) or (reset_vec(2) and reset_vec(1));
    end if;
  end process filter_reset;

  microblaze_I : microblaze
    generic map (
      C_SCO                       => 0,
      C_FREQ                      => C_FREQ,
      C_FAULT_TOLERANT            => 0,
      C_ECC_USE_CE_EXCEPTION      => 0,
      C_LOCKSTEP_SLAVE            => 0,
      C_ENDIANNESS                => 1,
      C_FAMILY                    => C_FAMILY,
      C_DATA_SIZE                 => 32,
      C_INSTANCE                  => "mb_" & C_MICROBLAZE_INSTANCE,
      C_AVOID_PRIMITIVES          => 0,
      C_AREA_OPTIMIZED            => 0,
      C_OPTIMIZATION              => 0,
      C_INTERCONNECT              => 1,
      C_STREAM_INTERCONNECT       => 0,
      C_M_AXI_DP_THREAD_ID_WIDTH  => 1,
      C_M_AXI_DP_DATA_WIDTH       => 32,
      C_M_AXI_DP_ADDR_WIDTH       => 32,
      C_M_AXI_DP_EXCLUSIVE_ACCESS => 0,
      C_M_AXI_D_BUS_EXCEPTION     => 0,
      C_DPLB_DWIDTH               => 32,
      C_DPLB_NATIVE_DWIDTH        => 32,
      C_DPLB_BURST_EN             => 0,
      C_DPLB_P2P                  => 0,
      C_M_AXI_IP_THREAD_ID_WIDTH  => 1,
      C_M_AXI_IP_DATA_WIDTH       => 32,
      C_M_AXI_IP_ADDR_WIDTH       => 32,
      C_M_AXI_I_BUS_EXCEPTION     => 0,
      C_IPLB_DWIDTH               => 32,
      C_IPLB_NATIVE_DWIDTH        => 32,
      C_IPLB_BURST_EN             => 0,
      C_IPLB_P2P                  => 0,
      C_D_AXI                     => 0,
      C_D_PLB                     => 0,
      C_D_LMB                     => 1,
      C_I_AXI                     => 0,
      C_I_PLB                     => 0,
      C_I_LMB                     => 1,
      C_USE_MSR_INSTR             => 1,
      C_USE_PCMP_INSTR            => 1,
      C_USE_BARREL                => 1,
      C_USE_DIV                   => 0,
      C_USE_HW_MUL                => 1,
      C_USE_FPU                   => 0,
      C_UNALIGNED_EXCEPTIONS      => 0,
      C_ILL_OPCODE_EXCEPTION      => 0,
      C_IPLB_BUS_EXCEPTION        => 0,
      C_DPLB_BUS_EXCEPTION        => 0,
      C_DIV_ZERO_EXCEPTION        => 0,
      C_FPU_EXCEPTION             => 0,
      C_FSL_EXCEPTION             => 0,
      C_USE_STACK_PROTECTION      => 0,
      C_USE_INTERRUPT             => 1,
      C_USE_EXT_BRK               => C_DEBUG_ENABLED,
      C_USE_EXT_NM_BRK            => C_DEBUG_ENABLED,
      C_USE_MMU                   => 0,
      C_MMU_DTLB_SIZE             => 4,
      C_MMU_ITLB_SIZE             => 2,
      C_MMU_TLB_ACCESS            => 3,
      C_MMU_ZONES                 => 16,
      C_MMU_PRIVILEGED_INSTR      => 0,
      C_USE_BRANCH_TARGET_CACHE   => 1,
      C_BRANCH_TARGET_CACHE_SIZE  => 5,
      C_PVR                       => 0,
      C_PVR_USER1                 => X"00",
      C_PVR_USER2                 => X"00000000",
      C_DYNAMIC_BUS_SIZING        => 1,
      C_RESET_MSR                 => X"00000000",
      C_OPCODE_0x0_ILLEGAL        => 0,
      C_DEBUG_ENABLED             => C_DEBUG_ENABLED,
      C_NUMBER_OF_PC_BRK          => C_DEBUG_ENABLED,
      C_NUMBER_OF_RD_ADDR_BRK     => 0,
      C_NUMBER_OF_WR_ADDR_BRK     => 0,
      C_INTERRUPT_IS_EDGE         => 0,
      C_EDGE_IS_POSITIVE          => 1,
      C_ASYNC_INTERRUPT           => 0,
      C_FSL_LINKS                 => 0,
      C_FSL_DATA_SIZE             => 32,
      C_USE_EXTENDED_FSL_INSTR    => 0,
      C_M0_AXIS_DATA_WIDTH        => 32,
      C_S0_AXIS_DATA_WIDTH        => 32,
      C_M1_AXIS_DATA_WIDTH        => 32,
      C_S1_AXIS_DATA_WIDTH        => 32,
      C_M2_AXIS_DATA_WIDTH        => 32,
      C_S2_AXIS_DATA_WIDTH        => 32,
      C_M3_AXIS_DATA_WIDTH        => 32,
      C_S3_AXIS_DATA_WIDTH        => 32,
      C_M4_AXIS_DATA_WIDTH        => 32,
      C_S4_AXIS_DATA_WIDTH        => 32,
      C_M5_AXIS_DATA_WIDTH        => 32,
      C_S5_AXIS_DATA_WIDTH        => 32,
      C_M6_AXIS_DATA_WIDTH        => 32,
      C_S6_AXIS_DATA_WIDTH        => 32,
      C_M7_AXIS_DATA_WIDTH        => 32,
      C_S7_AXIS_DATA_WIDTH        => 32,
      C_M8_AXIS_DATA_WIDTH        => 32,
      C_S8_AXIS_DATA_WIDTH        => 32,
      C_M9_AXIS_DATA_WIDTH        => 32,
      C_S9_AXIS_DATA_WIDTH        => 32,
      C_M10_AXIS_DATA_WIDTH       => 32,
      C_S10_AXIS_DATA_WIDTH       => 32,
      C_M11_AXIS_DATA_WIDTH       => 32,
      C_S11_AXIS_DATA_WIDTH       => 32,
      C_M12_AXIS_DATA_WIDTH       => 32,
      C_S12_AXIS_DATA_WIDTH       => 32,
      C_M13_AXIS_DATA_WIDTH       => 32,
      C_S13_AXIS_DATA_WIDTH       => 32,
      C_M14_AXIS_DATA_WIDTH       => 32,
      C_S14_AXIS_DATA_WIDTH       => 32,
      C_M15_AXIS_DATA_WIDTH       => 32,
      C_S15_AXIS_DATA_WIDTH       => 32,
      C_ICACHE_BASEADDR           => X"00000000",
      C_ICACHE_HIGHADDR           => X"3FFFFFFF",
      C_USE_ICACHE                => 0,
      C_ALLOW_ICACHE_WR           => 1,
      C_ADDR_TAG_BITS             => 0,
      C_CACHE_BYTE_SIZE           => 8192,
      C_ICACHE_USE_FSL            => 1,
      C_ICACHE_LINE_LEN           => 4,
      C_ICACHE_ALWAYS_USED        => 0,
      C_ICACHE_INTERFACE          => 0,
      C_ICACHE_STREAMS            => 0,
      C_ICACHE_VICTIMS            => 0,
      C_ICACHE_FORCE_TAG_LUTRAM   => 0,
      C_ICACHE_DATA_WIDTH         => 0,
      C_M_AXI_IC_THREAD_ID_WIDTH  => 1,
      C_M_AXI_IC_DATA_WIDTH       => 32,
      C_M_AXI_IC_ADDR_WIDTH       => 32,
      C_M_AXI_IC_USER_VALUE       => 2#11111#,
      C_M_AXI_IC_AWUSER_WIDTH     => 5,
      C_M_AXI_IC_ARUSER_WIDTH     => 5,
      C_M_AXI_IC_WUSER_WIDTH      => 1,
      C_M_AXI_IC_RUSER_WIDTH      => 1,
      C_M_AXI_IC_BUSER_WIDTH      => 1,
      C_DCACHE_BASEADDR           => X"C0000000",
      C_DCACHE_HIGHADDR           => X"FFFFFFFF",
      C_USE_DCACHE                => 1,
      C_ALLOW_DCACHE_WR           => 1,
      C_DCACHE_ADDR_TAG           => 17,
      C_DCACHE_BYTE_SIZE          => 8192,
      C_DCACHE_USE_FSL            => 1,
      C_DCACHE_LINE_LEN           => 8,
      C_DCACHE_ALWAYS_USED        => 1,
      C_DCACHE_INTERFACE          => 1,
      C_DCACHE_USE_WRITEBACK      => 1,
      C_DCACHE_VICTIMS            => 0,
      C_DCACHE_FORCE_TAG_LUTRAM   => 0,
      C_DCACHE_DATA_WIDTH         => 0,
      C_M_AXI_DC_THREAD_ID_WIDTH  => 1,
      C_M_AXI_DC_DATA_WIDTH       => 32,
      C_M_AXI_DC_ADDR_WIDTH       => 32,
      C_M_AXI_DC_EXCLUSIVE_ACCESS => 0,
      C_M_AXI_DC_USER_VALUE       => 2#11111#,
      C_M_AXI_DC_AWUSER_WIDTH     => 5,
      C_M_AXI_DC_ARUSER_WIDTH     => 5,
      C_M_AXI_DC_WUSER_WIDTH      => 1,
      C_M_AXI_DC_RUSER_WIDTH      => 1,
      C_M_AXI_DC_BUSER_WIDTH      => 1
      )
    port map (
      CLK                    => Clk,
      RESET                  => ilmb_LMB_Rst,
      MB_RESET               => '0',
      INTERRUPT              => Interrupt,
      EXT_BRK                => Ext_BRK,
      EXT_NM_BRK             => Ext_NM_BRK,
      DBG_STOP               => DBG_STOP,
      MB_Halted              => open,
      MB_Error               => open,
      LOCKSTEP_Slave_In      => (others => '0'),
      LOCKSTEP_Master_Out    => open,
      LOCKSTEP_Out           => open,
      INSTR                  => ilmb_LMB_ReadDBus,
      IREADY                 => ilmb_LMB_Ready,
      IWAIT                  => ilmb_LMB_Wait,
      ICE                    => ilmb_LMB_CE,
      IUE                    => ilmb_LMB_UE,
      INSTR_ADDR             => ilmb_M_ABus,
      IFETCH                 => ilmb_M_ReadStrobe,
      I_AS                   => ilmb_M_AddrStrobe,
      IPLB_M_ABort           => open,
      IPLB_M_ABus            => open,
      IPLB_M_UABus           => open,
      IPLB_M_BE              => open,
      IPLB_M_busLock         => open,
      IPLB_M_lockErr         => open,
      IPLB_M_MSize           => open,
      IPLB_M_priority        => open,
      IPLB_M_rdBurst         => open,
      IPLB_M_request         => open,
      IPLB_M_RNW             => open,
      IPLB_M_size            => open,
      IPLB_M_TAttribute      => open,
      IPLB_M_type            => open,
      IPLB_M_wrBurst         => open,
      IPLB_M_wrDBus          => open,
      IPLB_MBusy             => net_gnd0,
      IPLB_MRdErr            => net_gnd0,
      IPLB_MWrErr            => net_gnd0,
      IPLB_MIRQ              => net_gnd0,
      IPLB_MWrBTerm          => net_gnd0,
      IPLB_MWrDAck           => net_gnd0,
      IPLB_MAddrAck          => net_gnd0,
      IPLB_MRdBTerm          => net_gnd0,
      IPLB_MRdDAck           => net_gnd0,
      IPLB_MRdDBus           => net_gnd32,
      IPLB_MRdWdAddr         => net_gnd4,
      IPLB_MRearbitrate      => net_gnd0,
      IPLB_MSSize            => net_gnd2,
      IPLB_MTimeout          => net_gnd0,
      DATA_READ              => dlmb_LMB_ReadDBus,
      DREADY                 => dlmb_LMB_Ready,
      DWAIT                  => dlmb_LMB_Wait,
      DCE                    => dlmb_LMB_CE,
      DUE                    => dlmb_LMB_UE,
      DATA_WRITE             => dlmb_M_DBus,
      DATA_ADDR              => dlmb_M_ABus,
      D_AS                   => dlmb_M_AddrStrobe,
      READ_STROBE            => dlmb_M_ReadStrobe,
      WRITE_STROBE           => dlmb_M_WriteStrobe,
      BYTE_ENABLE            => dlmb_M_BE,
      DPLB_M_ABort           => open,     
      DPLB_M_ABus            => open,     
      DPLB_M_UABus           => open,     
      DPLB_M_BE              => open,     
      DPLB_M_busLock         => open,     
      DPLB_M_lockErr         => open,     
      DPLB_M_MSize           => open,     
      DPLB_M_priority        => open,     
      DPLB_M_rdBurst         => open,     
      DPLB_M_request         => open,     
      DPLB_M_RNW             => open,     
      DPLB_M_size            => open,     
      DPLB_M_TAttribute      => open,     
      DPLB_M_type            => open,     
      DPLB_M_wrBurst         => open,     
      DPLB_M_wrDBus          => open,     
      DPLB_MBusy             => net_gnd0, 
      DPLB_MRdErr            => net_gnd0, 
      DPLB_MWrErr            => net_gnd0, 
      DPLB_MIRQ              => net_gnd0, 
      DPLB_MWrBTerm          => net_gnd0, 
      DPLB_MWrDAck           => net_gnd0, 
      DPLB_MAddrAck          => net_gnd0, 
      DPLB_MRdBTerm          => net_gnd0, 
      DPLB_MRdDAck           => net_gnd0, 
      DPLB_MRdDBus           => net_gnd32,
      DPLB_MRdWdAddr         => net_gnd4, 
      DPLB_MRearbitrate      => net_gnd0, 
      DPLB_MSSize            => net_gnd2, 
      DPLB_MTimeout          => net_gnd0, 
      M_AXI_IP_AWID          => open,
      M_AXI_IP_AWADDR        => open,
      M_AXI_IP_AWLEN         => open,
      M_AXI_IP_AWSIZE        => open,
      M_AXI_IP_AWBURST       => open,
      M_AXI_IP_AWLOCK        => open,
      M_AXI_IP_AWCACHE       => open,
      M_AXI_IP_AWPROT        => open,
      M_AXI_IP_AWQOS         => open,
      M_AXI_IP_AWVALID       => open,
      M_AXI_IP_AWREADY       => net_gnd0,
      M_AXI_IP_WDATA         => open,
      M_AXI_IP_WSTRB         => open,
      M_AXI_IP_WLAST         => open,
      M_AXI_IP_WVALID        => open,
      M_AXI_IP_WREADY        => net_gnd0,
      M_AXI_IP_BID           => net_gnd1(0 downto 0),
      M_AXI_IP_BRESP         => net_gnd2(0 to 1),
      M_AXI_IP_BVALID        => net_gnd0,
      M_AXI_IP_BREADY        => open,
      M_AXI_IP_ARID          => open,
      M_AXI_IP_ARADDR        => open,
      M_AXI_IP_ARLEN         => open,
      M_AXI_IP_ARSIZE        => open,
      M_AXI_IP_ARBURST       => open,
      M_AXI_IP_ARLOCK        => open,
      M_AXI_IP_ARCACHE       => open,
      M_AXI_IP_ARPROT        => open,
      M_AXI_IP_ARQOS         => open,
      M_AXI_IP_ARVALID       => open,
      M_AXI_IP_ARREADY       => net_gnd0,
      M_AXI_IP_RID           => net_gnd1(0 downto 0),
      M_AXI_IP_RDATA         => net_gnd32(0 to 31),
      M_AXI_IP_RRESP         => net_gnd2(0 to 1),
      M_AXI_IP_RLAST         => net_gnd0,
      M_AXI_IP_RVALID        => net_gnd0,
      M_AXI_IP_RREADY        => open,
      M_AXI_DP_AWID          => open,
      M_AXI_DP_AWADDR        => open,
      M_AXI_DP_AWLEN         => open,
      M_AXI_DP_AWSIZE        => open,
      M_AXI_DP_AWBURST       => open,
      M_AXI_DP_AWLOCK        => open,
      M_AXI_DP_AWCACHE       => open,
      M_AXI_DP_AWPROT        => open,
      M_AXI_DP_AWQOS         => open,
      M_AXI_DP_AWVALID       => open,
      M_AXI_DP_AWREADY       => net_gnd0,
      M_AXI_DP_WDATA         => open,
      M_AXI_DP_WSTRB         => open,
      M_AXI_DP_WLAST         => open,
      M_AXI_DP_WVALID        => open,
      M_AXI_DP_WREADY        => net_gnd0,
      M_AXI_DP_BID           => net_gnd1(0 downto 0),
      M_AXI_DP_BRESP         => net_gnd2(0 to 1),
      M_AXI_DP_BVALID        => net_gnd0,
      M_AXI_DP_BREADY        => open,
      M_AXI_DP_ARID          => open,
      M_AXI_DP_ARADDR        => open,
      M_AXI_DP_ARLEN         => open,
      M_AXI_DP_ARSIZE        => open,
      M_AXI_DP_ARBURST       => open,
      M_AXI_DP_ARLOCK        => open,
      M_AXI_DP_ARCACHE       => open,
      M_AXI_DP_ARPROT        => open,
      M_AXI_DP_ARQOS         => open,
      M_AXI_DP_ARVALID       => open,
      M_AXI_DP_ARREADY       => net_gnd0,
      M_AXI_DP_RID           => net_gnd1(0 downto 0),
      M_AXI_DP_RDATA         => net_gnd32(0 to 31),
      M_AXI_DP_RRESP         => net_gnd2(0 to 1),
      M_AXI_DP_RLAST         => net_gnd0,
      M_AXI_DP_RVALID        => net_gnd0,
      M_AXI_DP_RREADY        => open,
      M_AXI_IC_AWID          => open,
      M_AXI_IC_AWADDR        => open,
      M_AXI_IC_AWLEN         => open,
      M_AXI_IC_AWSIZE        => open,
      M_AXI_IC_AWBURST       => open,
      M_AXI_IC_AWLOCK        => open,
      M_AXI_IC_AWCACHE       => open,
      M_AXI_IC_AWPROT        => open,
      M_AXI_IC_AWQOS         => open,
      M_AXI_IC_AWVALID       => open,
      M_AXI_IC_AWREADY       => net_gnd0,
      M_AXI_IC_AWUSER        => open,
      M_AXI_IC_WDATA         => open,
      M_AXI_IC_WSTRB         => open,
      M_AXI_IC_WLAST         => open,
      M_AXI_IC_WVALID        => open,
      M_AXI_IC_WREADY        => net_gnd0,
      M_AXI_IC_WUSER         => open,
      M_AXI_IC_BID           => net_gnd1(0 downto 0),
      M_AXI_IC_BRESP         => net_gnd2(0 to 1),
      M_AXI_IC_BVALID        => net_gnd0,
      M_AXI_IC_BREADY        => open,
      M_AXI_IC_BUSER         => net_gnd1(0 downto 0),
      M_AXI_IC_ARID          => open,
      M_AXI_IC_ARADDR        => open,
      M_AXI_IC_ARLEN         => open,
      M_AXI_IC_ARSIZE        => open,
      M_AXI_IC_ARBURST       => open,
      M_AXI_IC_ARLOCK        => open,
      M_AXI_IC_ARCACHE       => open,
      M_AXI_IC_ARPROT        => open,
      M_AXI_IC_ARQOS         => open,
      M_AXI_IC_ARVALID       => open,
      M_AXI_IC_ARREADY       => net_gnd0,
      M_AXI_IC_ARUSER        => open,
      M_AXI_IC_RID           => net_gnd1(0 downto 0),
      M_AXI_IC_RDATA         => net_gnd32(0 to 31),
      M_AXI_IC_RRESP         => net_gnd2(0 to 1),
      M_AXI_IC_RLAST         => net_gnd0,
      M_AXI_IC_RVALID        => net_gnd0,
      M_AXI_IC_RREADY        => open,
      M_AXI_IC_RUSER         => net_gnd1(0 downto 0),
      M_AXI_DC_AWID          => open,
      M_AXI_DC_AWADDR        => open,
      M_AXI_DC_AWLEN         => open,
      M_AXI_DC_AWSIZE        => open,
      M_AXI_DC_AWBURST       => open,
      M_AXI_DC_AWLOCK        => open,
      M_AXI_DC_AWCACHE       => open,
      M_AXI_DC_AWPROT        => open,
      M_AXI_DC_AWQOS         => open,
      M_AXI_DC_AWVALID       => open,
      M_AXI_DC_AWREADY       => net_gnd0,
      M_AXI_DC_AWUSER        => open,
      M_AXI_DC_WDATA         => open,
      M_AXI_DC_WSTRB         => open,
      M_AXI_DC_WLAST         => open,
      M_AXI_DC_WVALID        => open,
      M_AXI_DC_WREADY        => net_gnd0,
      M_AXI_DC_WUSER         => open,
      M_AXI_DC_BID           => net_gnd1(0 downto 0),
      M_AXI_DC_BRESP         => net_gnd2(0 to 1),
      M_AXI_DC_BVALID        => net_gnd0,
      M_AXI_DC_BREADY        => open,
      M_AXI_DC_BUSER         => net_gnd1(0 downto 0),
      M_AXI_DC_ARID          => open,
      M_AXI_DC_ARADDR        => open,
      M_AXI_DC_ARLEN         => open,
      M_AXI_DC_ARSIZE        => open,
      M_AXI_DC_ARBURST       => open,
      M_AXI_DC_ARLOCK        => open,
      M_AXI_DC_ARCACHE       => open,
      M_AXI_DC_ARPROT        => open,
      M_AXI_DC_ARQOS         => open,
      M_AXI_DC_ARVALID       => open,
      M_AXI_DC_ARREADY       => net_gnd0,
      M_AXI_DC_ARUSER        => open,
      M_AXI_DC_RID           => net_gnd1(0 downto 0),
      M_AXI_DC_RDATA         => net_gnd32(0 to 31),
      M_AXI_DC_RRESP         => net_gnd2(0 to 1),
      M_AXI_DC_RLAST         => net_gnd0,
      M_AXI_DC_RVALID        => net_gnd0,
      M_AXI_DC_RREADY        => open,
      M_AXI_DC_RUSER         => net_gnd1(0 downto 0),
      DBG_CLK                => DBG_CLK,
      DBG_TDI                => DBG_TDI,
      DBG_TDO                => DBG_TDO,
      DBG_REG_EN             => DBG_REG_EN,
      DBG_SHIFT              => DBG_SHIFT,
      DBG_CAPTURE            => DBG_CAPTURE,
      DBG_UPDATE             => DBG_UPDATE,
      DEBUG_RST              => DBG_RST,
      Trace_Instruction      => Trace_Instruction,
      Trace_Valid_Instr      => Trace_Valid_Instr,
      Trace_PC               => Trace_PC,
      Trace_Reg_Write        => Trace_Reg_Write,
      Trace_Reg_Addr         => Trace_Reg_Addr,
      Trace_MSR_Reg          => Trace_MSR_Reg,
      Trace_PID_Reg          => Trace_PID_Reg,
      Trace_New_Reg_Value    => Trace_New_Reg_Value,
      Trace_Exception_Taken  => Trace_Exception_Taken,
      Trace_Exception_Kind   => Trace_Exception_Kind,
      Trace_Jump_Taken       => Trace_Jump_Taken,
      Trace_Delay_Slot       => Trace_Delay_Slot,
      Trace_Data_Address     => Trace_Data_Address,
      Trace_Data_Access      => Trace_Data_Access,
      Trace_Data_Read        => Trace_Data_Read,
      Trace_Data_Write       => Trace_Data_Write,
      Trace_Data_Write_Value => Trace_Data_Write_Value,
      Trace_Data_Byte_Enable => Trace_Data_Byte_Enable,
      Trace_DCache_Req       => Trace_DCache_Req,
      Trace_DCache_Hit       => Trace_DCache_Hit,
      Trace_DCache_Rdy       => Trace_DCache_Rdy,
      Trace_DCache_Read      => Trace_DCache_Read,
      Trace_ICache_Req       => Trace_ICache_Req,
      Trace_ICache_Hit       => Trace_ICache_Hit,
      Trace_ICache_Rdy       => Trace_ICache_Rdy,
      Trace_OF_PipeRun       => Trace_OF_PipeRun,
      Trace_EX_PipeRun       => Trace_EX_PipeRun,
      Trace_MEM_PipeRun      => Trace_MEM_PipeRun,     
      Trace_MB_Halted        => Trace_MB_Halted,
      Trace_Jump_Hit         => Trace_Jump_Hit,
      FSL0_S_CLK             => open,
      FSL0_S_READ            => open,
      FSL0_S_DATA            => net_gnd32,
      FSL0_S_CONTROL         => net_gnd0,
      FSL0_S_EXISTS          => net_gnd0,
      FSL0_M_CLK             => open,
      FSL0_M_WRITE           => open,
      FSL0_M_DATA            => open,
      FSL0_M_CONTROL         => open,
      FSL0_M_FULL            => net_gnd0,
      FSL1_S_CLK             => open,
      FSL1_S_READ            => open,
      FSL1_S_DATA            => net_gnd32,
      FSL1_S_CONTROL         => net_gnd0,
      FSL1_S_EXISTS          => net_gnd0,
      FSL1_M_CLK             => open,
      FSL1_M_WRITE           => open,
      FSL1_M_DATA            => open,
      FSL1_M_CONTROL         => open,
      FSL1_M_FULL            => net_gnd0,
      FSL2_S_CLK             => open,
      FSL2_S_READ            => open,
      FSL2_S_DATA            => net_gnd32,
      FSL2_S_CONTROL         => net_gnd0,
      FSL2_S_EXISTS          => net_gnd0,
      FSL2_M_CLK             => open,
      FSL2_M_WRITE           => open,
      FSL2_M_DATA            => open,
      FSL2_M_CONTROL         => open,
      FSL2_M_FULL            => net_gnd0,
      FSL3_S_CLK             => open,
      FSL3_S_READ            => open,
      FSL3_S_DATA            => net_gnd32,
      FSL3_S_CONTROL         => net_gnd0,
      FSL3_S_EXISTS          => net_gnd0,
      FSL3_M_CLK             => open,
      FSL3_M_WRITE           => open,
      FSL3_M_DATA            => open,
      FSL3_M_CONTROL         => open,
      FSL3_M_FULL            => net_gnd0,
      FSL4_S_CLK             => open,
      FSL4_S_READ            => open,
      FSL4_S_DATA            => net_gnd32,
      FSL4_S_CONTROL         => net_gnd0,
      FSL4_S_EXISTS          => net_gnd0,
      FSL4_M_CLK             => open,
      FSL4_M_WRITE           => open,
      FSL4_M_DATA            => open,
      FSL4_M_CONTROL         => open,
      FSL4_M_FULL            => net_gnd0,
      FSL5_S_CLK             => open,
      FSL5_S_READ            => open,
      FSL5_S_DATA            => net_gnd32,
      FSL5_S_CONTROL         => net_gnd0,
      FSL5_S_EXISTS          => net_gnd0,
      FSL5_M_CLK             => open,
      FSL5_M_WRITE           => open,
      FSL5_M_DATA            => open,
      FSL5_M_CONTROL         => open,
      FSL5_M_FULL            => net_gnd0,
      FSL6_S_CLK             => open,
      FSL6_S_READ            => open,
      FSL6_S_DATA            => net_gnd32,
      FSL6_S_CONTROL         => net_gnd0,
      FSL6_S_EXISTS          => net_gnd0,
      FSL6_M_CLK             => open,
      FSL6_M_WRITE           => open,
      FSL6_M_DATA            => open,
      FSL6_M_CONTROL         => open,
      FSL6_M_FULL            => net_gnd0,
      FSL7_S_CLK             => open,
      FSL7_S_READ            => open,
      FSL7_S_DATA            => net_gnd32,
      FSL7_S_CONTROL         => net_gnd0,
      FSL7_S_EXISTS          => net_gnd0,
      FSL7_M_CLK             => open,
      FSL7_M_WRITE           => open,
      FSL7_M_DATA            => open,
      FSL7_M_CONTROL         => open,
      FSL7_M_FULL            => net_gnd0,
      FSL8_S_CLK             => open,
      FSL8_S_READ            => open,
      FSL8_S_DATA            => net_gnd32,
      FSL8_S_CONTROL         => net_gnd0,
      FSL8_S_EXISTS          => net_gnd0,
      FSL8_M_CLK             => open,
      FSL8_M_WRITE           => open,
      FSL8_M_DATA            => open,
      FSL8_M_CONTROL         => open,
      FSL8_M_FULL            => net_gnd0,
      FSL9_S_CLK             => open,
      FSL9_S_READ            => open,
      FSL9_S_DATA            => net_gnd32,
      FSL9_S_CONTROL         => net_gnd0,
      FSL9_S_EXISTS          => net_gnd0,
      FSL9_M_CLK             => open,
      FSL9_M_WRITE           => open,
      FSL9_M_DATA            => open,
      FSL9_M_CONTROL         => open,
      FSL9_M_FULL            => net_gnd0,
      FSL10_S_CLK            => open,
      FSL10_S_READ           => open,
      FSL10_S_DATA           => net_gnd32,
      FSL10_S_CONTROL        => net_gnd0,
      FSL10_S_EXISTS         => net_gnd0,
      FSL10_M_CLK            => open,
      FSL10_M_WRITE          => open,
      FSL10_M_DATA           => open,
      FSL10_M_CONTROL        => open,
      FSL10_M_FULL           => net_gnd0,
      FSL11_S_CLK            => open,
      FSL11_S_READ           => open,
      FSL11_S_DATA           => net_gnd32,
      FSL11_S_CONTROL        => net_gnd0,
      FSL11_S_EXISTS         => net_gnd0,
      FSL11_M_CLK            => open,
      FSL11_M_WRITE          => open,
      FSL11_M_DATA           => open,
      FSL11_M_CONTROL        => open,
      FSL11_M_FULL           => net_gnd0,
      FSL12_S_CLK            => open,
      FSL12_S_READ           => open,
      FSL12_S_DATA           => net_gnd32,
      FSL12_S_CONTROL        => net_gnd0,
      FSL12_S_EXISTS         => net_gnd0,
      FSL12_M_CLK            => open,
      FSL12_M_WRITE          => open,
      FSL12_M_DATA           => open,
      FSL12_M_CONTROL        => open,
      FSL12_M_FULL           => net_gnd0,
      FSL13_S_CLK            => open,
      FSL13_S_READ           => open,
      FSL13_S_DATA           => net_gnd32,
      FSL13_S_CONTROL        => net_gnd0,
      FSL13_S_EXISTS         => net_gnd0,
      FSL13_M_CLK            => open,
      FSL13_M_WRITE          => open,
      FSL13_M_DATA           => open,
      FSL13_M_CONTROL        => open,
      FSL13_M_FULL           => net_gnd0,
      FSL14_S_CLK            => open,
      FSL14_S_READ           => open,
      FSL14_S_DATA           => net_gnd32,
      FSL14_S_CONTROL        => net_gnd0,
      FSL14_S_EXISTS         => net_gnd0,
      FSL14_M_CLK            => open,
      FSL14_M_WRITE          => open,
      FSL14_M_DATA           => open,
      FSL14_M_CONTROL        => open,
      FSL14_M_FULL           => net_gnd0,
      FSL15_S_CLK            => open,
      FSL15_S_READ           => open,
      FSL15_S_DATA           => net_gnd32,
      FSL15_S_CONTROL        => net_gnd0,
      FSL15_S_EXISTS         => net_gnd0,
      FSL15_M_CLK            => open,
      FSL15_M_WRITE          => open,
      FSL15_M_DATA           => open,
      FSL15_M_CONTROL        => open,
      FSL15_M_FULL           => net_gnd0,
      M0_AXIS_TLAST          => open,
      M0_AXIS_TDATA          => open,
      M0_AXIS_TVALID         => open,
      M0_AXIS_TREADY         => net_gnd0,
      S0_AXIS_TLAST          => net_gnd0,
      S0_AXIS_TDATA          => net_gnd32(0 to 31),
      S0_AXIS_TVALID         => net_gnd0,
      S0_AXIS_TREADY         => open,
      M1_AXIS_TLAST          => open,
      M1_AXIS_TDATA          => open,
      M1_AXIS_TVALID         => open,
      M1_AXIS_TREADY         => net_gnd0,
      S1_AXIS_TLAST          => net_gnd0,
      S1_AXIS_TDATA          => net_gnd32(0 to 31),
      S1_AXIS_TVALID         => net_gnd0,
      S1_AXIS_TREADY         => open,
      M2_AXIS_TLAST          => open,
      M2_AXIS_TDATA          => open,
      M2_AXIS_TVALID         => open,
      M2_AXIS_TREADY         => net_gnd0,
      S2_AXIS_TLAST          => net_gnd0,
      S2_AXIS_TDATA          => net_gnd32(0 to 31),
      S2_AXIS_TVALID         => net_gnd0,
      S2_AXIS_TREADY         => open,
      M3_AXIS_TLAST          => open,
      M3_AXIS_TDATA          => open,
      M3_AXIS_TVALID         => open,
      M3_AXIS_TREADY         => net_gnd0,
      S3_AXIS_TLAST          => net_gnd0,
      S3_AXIS_TDATA          => net_gnd32(0 to 31),
      S3_AXIS_TVALID         => net_gnd0,
      S3_AXIS_TREADY         => open,
      M4_AXIS_TLAST          => open,
      M4_AXIS_TDATA          => open,
      M4_AXIS_TVALID         => open,
      M4_AXIS_TREADY         => net_gnd0,
      S4_AXIS_TLAST          => net_gnd0,
      S4_AXIS_TDATA          => net_gnd32(0 to 31),
      S4_AXIS_TVALID         => net_gnd0,
      S4_AXIS_TREADY         => open,
      M5_AXIS_TLAST          => open,
      M5_AXIS_TDATA          => open,
      M5_AXIS_TVALID         => open,
      M5_AXIS_TREADY         => net_gnd0,
      S5_AXIS_TLAST          => net_gnd0,
      S5_AXIS_TDATA          => net_gnd32(0 to 31),
      S5_AXIS_TVALID         => net_gnd0,
      S5_AXIS_TREADY         => open,
      M6_AXIS_TLAST          => open,
      M6_AXIS_TDATA          => open,
      M6_AXIS_TVALID         => open,
      M6_AXIS_TREADY         => net_gnd0,
      S6_AXIS_TLAST          => net_gnd0,
      S6_AXIS_TDATA          => net_gnd32(0 to 31),
      S6_AXIS_TVALID         => net_gnd0,
      S6_AXIS_TREADY         => open,
      M7_AXIS_TLAST          => open,
      M7_AXIS_TDATA          => open,
      M7_AXIS_TVALID         => open,
      M7_AXIS_TREADY         => net_gnd0,
      S7_AXIS_TLAST          => net_gnd0,
      S7_AXIS_TDATA          => net_gnd32(0 to 31),
      S7_AXIS_TVALID         => net_gnd0,
      S7_AXIS_TREADY         => open,
      M8_AXIS_TLAST          => open,
      M8_AXIS_TDATA          => open,
      M8_AXIS_TVALID         => open,
      M8_AXIS_TREADY         => net_gnd0,
      S8_AXIS_TLAST          => net_gnd0,
      S8_AXIS_TDATA          => net_gnd32(0 to 31),
      S8_AXIS_TVALID         => net_gnd0,
      S8_AXIS_TREADY         => open,
      M9_AXIS_TLAST          => open,
      M9_AXIS_TDATA          => open,
      M9_AXIS_TVALID         => open,
      M9_AXIS_TREADY         => net_gnd0,
      S9_AXIS_TLAST          => net_gnd0,
      S9_AXIS_TDATA          => net_gnd32(0 to 31),
      S9_AXIS_TVALID         => net_gnd0,
      S9_AXIS_TREADY         => open,
      M10_AXIS_TLAST         => open,
      M10_AXIS_TDATA         => open,
      M10_AXIS_TVALID        => open,
      M10_AXIS_TREADY        => net_gnd0,
      S10_AXIS_TLAST         => net_gnd0,
      S10_AXIS_TDATA         => net_gnd32(0 to 31),
      S10_AXIS_TVALID        => net_gnd0,
      S10_AXIS_TREADY        => open,
      M11_AXIS_TLAST         => open,
      M11_AXIS_TDATA         => open,
      M11_AXIS_TVALID        => open,
      M11_AXIS_TREADY        => net_gnd0,
      S11_AXIS_TLAST         => net_gnd0,
      S11_AXIS_TDATA         => net_gnd32(0 to 31),
      S11_AXIS_TVALID        => net_gnd0,
      S11_AXIS_TREADY        => open,
      M12_AXIS_TLAST         => open,
      M12_AXIS_TDATA         => open,
      M12_AXIS_TVALID        => open,
      M12_AXIS_TREADY        => net_gnd0,
      S12_AXIS_TLAST         => net_gnd0,
      S12_AXIS_TDATA         => net_gnd32(0 to 31),
      S12_AXIS_TVALID        => net_gnd0,
      S12_AXIS_TREADY        => open,
      M13_AXIS_TLAST         => open,
      M13_AXIS_TDATA         => open,
      M13_AXIS_TVALID        => open,
      M13_AXIS_TREADY        => net_gnd0,
      S13_AXIS_TLAST         => net_gnd0,
      S13_AXIS_TDATA         => net_gnd32(0 to 31),
      S13_AXIS_TVALID        => net_gnd0,
      S13_AXIS_TREADY        => open,
      M14_AXIS_TLAST         => open,
      M14_AXIS_TDATA         => open,
      M14_AXIS_TVALID        => open,
      M14_AXIS_TREADY        => net_gnd0,
      S14_AXIS_TLAST         => net_gnd0,
      S14_AXIS_TDATA         => net_gnd32(0 to 31),
      S14_AXIS_TVALID        => net_gnd0,
      S14_AXIS_TREADY        => open,
      M15_AXIS_TLAST         => open,
      M15_AXIS_TDATA         => open,
      M15_AXIS_TVALID        => open,
      M15_AXIS_TREADY        => net_gnd0,
      S15_AXIS_TLAST         => net_gnd0,
      S15_AXIS_TDATA         => net_gnd32(0 to 31),
      S15_AXIS_TVALID        => net_gnd0,
      S15_AXIS_TREADY        => open,
      ICACHE_FSL_IN_CLK      =>ICACHE_FSL_IN_CLK,
      ICACHE_FSL_IN_READ     =>ICACHE_FSL_IN_READ,    
      ICACHE_FSL_IN_DATA     =>ICACHE_FSL_IN_DATA,   
      ICACHE_FSL_IN_CONTROL  =>ICACHE_FSL_IN_CONTROL,
      ICACHE_FSL_IN_EXISTS   =>ICACHE_FSL_IN_EXISTS,  
      ICACHE_FSL_OUT_CLK     =>ICACHE_FSL_OUT_CLK,
      ICACHE_FSL_OUT_WRITE   =>ICACHE_FSL_OUT_WRITE,  
      ICACHE_FSL_OUT_DATA    =>ICACHE_FSL_OUT_DATA,   
      ICACHE_FSL_OUT_CONTROL =>ICACHE_FSL_OUT_CONTROL,
      ICACHE_FSL_OUT_FULL    =>ICACHE_FSL_OUT_FULL,
      DCACHE_FSL_IN_CLK      =>DCACHE_FSL_IN_CLK,
      DCACHE_FSL_IN_READ     =>DCACHE_FSL_IN_READ,
      DCACHE_FSL_IN_DATA     =>DCACHE_FSL_IN_DATA,
      DCACHE_FSL_IN_CONTROL  =>DCACHE_FSL_IN_CONTROL,
      DCACHE_FSL_IN_EXISTS   =>DCACHE_FSL_IN_EXISTS,
      DCACHE_FSL_OUT_CLK     =>DCACHE_FSL_OUT_CLK,
      DCACHE_FSL_OUT_WRITE   =>DCACHE_FSL_OUT_WRITE, 
      DCACHE_FSL_OUT_DATA    =>DCACHE_FSL_OUT_DATA,
      DCACHE_FSL_OUT_CONTROL =>DCACHE_FSL_OUT_CONTROL,
      DCACHE_FSL_OUT_FULL    =>DCACHE_FSL_OUT_FULL
    );

  ilmb : lmb_v10
    generic map (
      C_LMB_NUM_SLAVES => 1,
      C_LMB_AWIDTH     => 32,
      C_LMB_DWIDTH     => 32,
      C_EXT_RESET_HIGH => 1
      )
    port map (
      LMB_Clk         => Clk,
      SYS_Rst         => LMB_Rst,
      LMB_Rst         => ilmb_LMB_Rst,
      M_ABus          => ilmb_M_ABus,
      M_ReadStrobe    => ilmb_M_ReadStrobe,
      M_WriteStrobe   => net_gnd0,
      M_AddrStrobe    => ilmb_M_AddrStrobe,
      M_DBus          => net_gnd32,
      M_BE            => net_gnd4,
      Sl_DBus         => ilmb_Sl_DBus,
      Sl_Ready        => ilmb_Sl_Ready(0 to 0),
      Sl_Wait         => ilmb_Sl_Wait(0 to 0),
      Sl_UE           => ilmb_Sl_UE(0 to 0),
      Sl_CE           => ilmb_Sl_CE(0 to 0),
      LMB_ABus        => ilmb_LMB_ABus,
      LMB_ReadStrobe  => ilmb_LMB_ReadStrobe,
      LMB_WriteStrobe => ilmb_LMB_WriteStrobe,
      LMB_AddrStrobe  => ilmb_LMB_AddrStrobe,
      LMB_ReadDBus    => ilmb_LMB_ReadDBus,
      LMB_WriteDBus   => ilmb_LMB_WriteDBus,
      LMB_Ready       => ilmb_LMB_Ready,
      LMB_Wait        => ilmb_LMB_Wait,
      LMB_UE          => ilmb_LMB_UE,
      LMB_CE          => ilmb_LMB_CE,
      LMB_BE          => ilmb_LMB_BE
    );

  dlmb : lmb_v10
    generic map (
      C_LMB_NUM_SLAVES => 2,
      C_LMB_AWIDTH     => 32,
      C_LMB_DWIDTH     => 32,
      C_EXT_RESET_HIGH => 1
      )
    port map (
      LMB_Clk         => Clk,
      SYS_Rst         => LMB_Rst,
      LMB_Rst         => dlmb_LMB_Rst,
      M_ABus          => dlmb_M_ABus,
      M_ReadStrobe    => dlmb_M_ReadStrobe,
      M_WriteStrobe   => dlmb_M_WriteStrobe,
      M_AddrStrobe    => dlmb_M_AddrStrobe,
      M_DBus          => dlmb_M_DBus,
      M_BE            => dlmb_M_BE,
      Sl_DBus         => dlmb_Sl_DBus,
      Sl_Ready        => dlmb_Sl_Ready,
      Sl_Wait         => dlmb_Sl_Wait,
      Sl_UE           => dlmb_Sl_UE,
      Sl_CE           => dlmb_Sl_CE,
      LMB_ABus        => dlmb_LMB_ABus,
      LMB_ReadStrobe  => dlmb_LMB_ReadStrobe,
      LMB_WriteStrobe => dlmb_LMB_WriteStrobe,
      LMB_AddrStrobe  => dlmb_LMB_AddrStrobe,
      LMB_ReadDBus    => dlmb_LMB_ReadDBus,
      LMB_WriteDBus   => dlmb_LMB_WriteDBus,
      LMB_Ready       => dlmb_LMB_Ready,
      LMB_Wait        => dlmb_LMB_Wait,
      LMB_UE          => dlmb_LMB_UE,
      LMB_CE          => dlmb_LMB_CE,
      LMB_BE          => dlmb_LMB_BE
    );

  dlmb_cntlr : lmb_bram_if_cntlr
    generic map (
      C_BASEADDR                 => MemSize2Addr(C_MEMSIZE_I),
      C_HIGHADDR                 => MemSize2HighAddr(C_MEMSIZE_I+C_MEMSIZE_D),
      C_FAMILY                   => C_FAMILY,
      C_MASK                     => X"F0000000",
      C_LMB_AWIDTH               => 32,
      C_LMB_DWIDTH               => 32,
      C_ECC                      => 0,
      C_INTERCONNECT             => 0,
      C_FAULT_INJECT             => 0,
      C_CE_FAILING_REGISTERS     => 0,
      C_UE_FAILING_REGISTERS     => 0,
      C_ECC_STATUS_REGISTERS     => 0,
      C_ECC_ONOFF_REGISTER       => 0,
      C_ECC_ONOFF_RESET_VALUE    => 1,
      C_CE_COUNTER_WIDTH         => 0,
      C_WRITE_ACCESS             => 2,
      C_SPLB_CTRL_BASEADDR       => X"FFFFFFFF",
      C_SPLB_CTRL_HIGHADDR       => X"00000000",
      C_SPLB_CTRL_AWIDTH         => 32,
      C_SPLB_CTRL_DWIDTH         => 32,
      C_SPLB_CTRL_P2P            => 0,
      C_SPLB_CTRL_MID_WIDTH      => 1,
      C_SPLB_CTRL_NUM_MASTERS    => 1,
      C_SPLB_CTRL_SUPPORT_BURSTS => 0,
      C_SPLB_CTRL_NATIVE_DWIDTH  => 32,
      C_S_AXI_CTRL_BASEADDR      => X"FFFFFFFF",
      C_S_AXI_CTRL_HIGHADDR      => X"00000000",
      C_S_AXI_CTRL_ADDR_WIDTH    => 32,
      C_S_AXI_CTRL_DATA_WIDTH    => 32
      )
    port map (
      LMB_Clk                  => Clk,
      LMB_Rst                  => dlmb_LMB_Rst,
      LMB_ABus                 => dlmb_LMB_ABus,
      LMB_WriteDBus            => dlmb_LMB_WriteDBus,
      LMB_AddrStrobe           => dlmb_LMB_AddrStrobe,
      LMB_ReadStrobe           => dlmb_LMB_ReadStrobe,
      LMB_WriteStrobe          => dlmb_LMB_WriteStrobe,
      LMB_BE                   => dlmb_LMB_BE,
      Sl_DBus                  => dlmb_Sl_DBus(0 to 31),
      Sl_Ready                 => dlmb_Sl_Ready(0),
      Sl_Wait                  => dlmb_Sl_Wait(0),
      Sl_UE                    => dlmb_Sl_UE(0),
      Sl_CE                    => dlmb_Sl_CE(0),
      BRAM_Rst_A               => dlmb_port_BRAM_Rst,
      BRAM_Clk_A               => dlmb_port_BRAM_Clk,
      BRAM_EN_A                => dlmb_port_BRAM_EN,
      BRAM_WEN_A               => dlmb_port_BRAM_WEN,
      BRAM_Addr_A              => dlmb_port_BRAM_Addr,
      BRAM_Din_A               => dlmb_port_BRAM_Din,
      BRAM_Dout_A              => dlmb_port_BRAM_Dout,
      Interrupt                => open,
      SPLB_CTRL_PLB_ABus       => net_gnd32,
      SPLB_CTRL_PLB_PAValid    => net_gnd0,
      SPLB_CTRL_PLB_masterID   => net_gnd1(0 downto 0),
      SPLB_CTRL_PLB_RNW        => net_gnd0,
      SPLB_CTRL_PLB_BE         => net_gnd4,
      SPLB_CTRL_PLB_size       => net_gnd4,
      SPLB_CTRL_PLB_type       => net_gnd3,
      SPLB_CTRL_PLB_wrDBus     => net_gnd32,
      SPLB_CTRL_Sl_addrAck     => open,
      SPLB_CTRL_Sl_SSize       => open,
      SPLB_CTRL_Sl_wait        => open,
      SPLB_CTRL_Sl_rearbitrate => open,
      SPLB_CTRL_Sl_wrDAck      => open,
      SPLB_CTRL_Sl_wrComp      => open,
      SPLB_CTRL_Sl_rdDBus      => open,
      SPLB_CTRL_Sl_rdDAck      => open,
      SPLB_CTRL_Sl_rdComp      => open,
      SPLB_CTRL_Sl_MBusy       => open,
      SPLB_CTRL_Sl_MWrErr      => open,
      SPLB_CTRL_Sl_MRdErr      => open,
      SPLB_CTRL_PLB_UABus      => net_gnd32,
      SPLB_CTRL_PLB_SAValid    => net_gnd0,
      SPLB_CTRL_PLB_rdPrim     => net_gnd0,
      SPLB_CTRL_PLB_wrPrim     => net_gnd0,
      SPLB_CTRL_PLB_abort      => net_gnd0,
      SPLB_CTRL_PLB_busLock    => net_gnd0,
      SPLB_CTRL_PLB_MSize      => net_gnd2,
      SPLB_CTRL_PLB_lockErr    => net_gnd0,
      SPLB_CTRL_PLB_wrBurst    => net_gnd0,
      SPLB_CTRL_PLB_rdBurst    => net_gnd0,
      SPLB_CTRL_PLB_wrPendReq  => net_gnd0,
      SPLB_CTRL_PLB_rdPendReq  => net_gnd0,
      SPLB_CTRL_PLB_wrPendPri  => net_gnd2,
      SPLB_CTRL_PLB_rdPendPri  => net_gnd2,
      SPLB_CTRL_PLB_reqPri     => net_gnd2,
      SPLB_CTRL_PLB_TAttribute => net_gnd16,
      SPLB_CTRL_Sl_wrBTerm     => open,
      SPLB_CTRL_Sl_rdWdAddr    => open,
      SPLB_CTRL_Sl_rdBTerm     => open,
      SPLB_CTRL_Sl_MIRQ        => open,
      S_AXI_CTRL_ACLK          => net_vcc0,
      S_AXI_CTRL_ARESETN       => net_gnd0,
      S_AXI_CTRL_AWADDR        => net_gnd32(0 to 31),
      S_AXI_CTRL_AWVALID       => net_gnd0,
      S_AXI_CTRL_AWREADY       => open,
      S_AXI_CTRL_WDATA         => net_gnd32(0 to 31),
      S_AXI_CTRL_WSTRB         => net_gnd4(0 to 3),
      S_AXI_CTRL_WVALID        => net_gnd0,
      S_AXI_CTRL_WREADY        => open,
      S_AXI_CTRL_BRESP         => open,
      S_AXI_CTRL_BVALID        => open,
      S_AXI_CTRL_BREADY        => net_gnd0,
      S_AXI_CTRL_ARADDR        => net_gnd32(0 to 31),
      S_AXI_CTRL_ARVALID       => net_gnd0,
      S_AXI_CTRL_ARREADY       => open,
      S_AXI_CTRL_RDATA         => open,
      S_AXI_CTRL_RRESP         => open,
      S_AXI_CTRL_RVALID        => open,
      S_AXI_CTRL_RREADY        => net_gnd0
    );

  ilmb_cntlr : lmb_bram_if_cntlr
    generic map (
      C_BASEADDR                 => X"00000000",
      C_HIGHADDR                 => MemSize2HighAddr(C_MEMSIZE_I),
      C_FAMILY                   => C_FAMILY,
      C_MASK                     => X"F0000000",
      C_LMB_AWIDTH               => 32,
      C_LMB_DWIDTH               => 32,
      C_ECC                      => 0,
      C_INTERCONNECT             => 0,
      C_FAULT_INJECT             => 0,
      C_CE_FAILING_REGISTERS     => 0,
      C_UE_FAILING_REGISTERS     => 0,
      C_ECC_STATUS_REGISTERS     => 0,
      C_ECC_ONOFF_REGISTER       => 0,
      C_ECC_ONOFF_RESET_VALUE    => 1,
      C_CE_COUNTER_WIDTH         => 0,
      C_WRITE_ACCESS             => 2,
      C_SPLB_CTRL_BASEADDR       => X"FFFFFFFF",
      C_SPLB_CTRL_HIGHADDR       => X"00000000",
      C_SPLB_CTRL_AWIDTH         => 32,
      C_SPLB_CTRL_DWIDTH         => 32,
      C_SPLB_CTRL_P2P            => 0,
      C_SPLB_CTRL_MID_WIDTH      => 1,
      C_SPLB_CTRL_NUM_MASTERS    => 1,
      C_SPLB_CTRL_SUPPORT_BURSTS => 0,
      C_SPLB_CTRL_NATIVE_DWIDTH  => 32,
      C_S_AXI_CTRL_BASEADDR      => X"FFFFFFFF",
      C_S_AXI_CTRL_HIGHADDR      => X"00000000",
      C_S_AXI_CTRL_ADDR_WIDTH    => 32,
      C_S_AXI_CTRL_DATA_WIDTH    => 32
      )
    port map (
      LMB_Clk                  => Clk,
      LMB_Rst                  => ilmb_LMB_Rst,
      LMB_ABus                 => ilmb_LMB_ABus,
      LMB_WriteDBus            => ilmb_LMB_WriteDBus,
      LMB_AddrStrobe           => ilmb_LMB_AddrStrobe,
      LMB_ReadStrobe           => ilmb_LMB_ReadStrobe,
      LMB_WriteStrobe          => ilmb_LMB_WriteStrobe,
      LMB_BE                   => ilmb_LMB_BE,
      Sl_DBus                  => ilmb_Sl_DBus,
      Sl_Ready                 => ilmb_Sl_Ready(0),
      Sl_Wait                  => ilmb_Sl_Wait(0),
      Sl_UE                    => ilmb_Sl_UE(0),
      Sl_CE                    => ilmb_Sl_CE(0),
      BRAM_Rst_A               => ilmb_port_BRAM_Rst,
      BRAM_Clk_A               => ilmb_port_BRAM_Clk,
      BRAM_EN_A                => ilmb_port_BRAM_EN,
      BRAM_WEN_A               => ilmb_port_BRAM_WEN,
      BRAM_Addr_A              => ilmb_port_BRAM_Addr,
      BRAM_Din_A               => ilmb_port_BRAM_Din,
      BRAM_Dout_A              => ilmb_port_BRAM_Dout,
      Interrupt                => open,
      SPLB_CTRL_PLB_ABus       => net_gnd32,
      SPLB_CTRL_PLB_PAValid    => net_gnd0,
      SPLB_CTRL_PLB_masterID   => net_gnd1(0 downto 0),
      SPLB_CTRL_PLB_RNW        => net_gnd0,
      SPLB_CTRL_PLB_BE         => net_gnd4,
      SPLB_CTRL_PLB_size       => net_gnd4,
      SPLB_CTRL_PLB_type       => net_gnd3,
      SPLB_CTRL_PLB_wrDBus     => net_gnd32,
      SPLB_CTRL_Sl_addrAck     => open,
      SPLB_CTRL_Sl_SSize       => open,
      SPLB_CTRL_Sl_wait        => open,
      SPLB_CTRL_Sl_rearbitrate => open,
      SPLB_CTRL_Sl_wrDAck      => open,
      SPLB_CTRL_Sl_wrComp      => open,
      SPLB_CTRL_Sl_rdDBus      => open,
      SPLB_CTRL_Sl_rdDAck      => open,
      SPLB_CTRL_Sl_rdComp      => open,
      SPLB_CTRL_Sl_MBusy       => open,
      SPLB_CTRL_Sl_MWrErr      => open,
      SPLB_CTRL_Sl_MRdErr      => open,
      SPLB_CTRL_PLB_UABus      => net_gnd32,
      SPLB_CTRL_PLB_SAValid    => net_gnd0,
      SPLB_CTRL_PLB_rdPrim     => net_gnd0,
      SPLB_CTRL_PLB_wrPrim     => net_gnd0,
      SPLB_CTRL_PLB_abort      => net_gnd0,
      SPLB_CTRL_PLB_busLock    => net_gnd0,
      SPLB_CTRL_PLB_MSize      => net_gnd2,
      SPLB_CTRL_PLB_lockErr    => net_gnd0,
      SPLB_CTRL_PLB_wrBurst    => net_gnd0,
      SPLB_CTRL_PLB_rdBurst    => net_gnd0,
      SPLB_CTRL_PLB_wrPendReq  => net_gnd0,
      SPLB_CTRL_PLB_rdPendReq  => net_gnd0,
      SPLB_CTRL_PLB_wrPendPri  => net_gnd2,
      SPLB_CTRL_PLB_rdPendPri  => net_gnd2,
      SPLB_CTRL_PLB_reqPri     => net_gnd2,
      SPLB_CTRL_PLB_TAttribute => net_gnd16,
      SPLB_CTRL_Sl_wrBTerm     => open,
      SPLB_CTRL_Sl_rdWdAddr    => open,
      SPLB_CTRL_Sl_rdBTerm     => open,
      SPLB_CTRL_Sl_MIRQ        => open,
      S_AXI_CTRL_ACLK          => net_vcc0,
      S_AXI_CTRL_ARESETN       => net_gnd0,
      S_AXI_CTRL_AWADDR        => net_gnd32(0 to 31),
      S_AXI_CTRL_AWVALID       => net_gnd0,
      S_AXI_CTRL_AWREADY       => open,
      S_AXI_CTRL_WDATA         => net_gnd32(0 to 31),
      S_AXI_CTRL_WSTRB         => net_gnd4(0 to 3),
      S_AXI_CTRL_WVALID        => net_gnd0,
      S_AXI_CTRL_WREADY        => open,
      S_AXI_CTRL_BRESP         => open,
      S_AXI_CTRL_BVALID        => open,
      S_AXI_CTRL_BREADY        => net_gnd0,
      S_AXI_CTRL_ARADDR        => net_gnd32(0 to 31),
      S_AXI_CTRL_ARVALID       => net_gnd0,
      S_AXI_CTRL_ARREADY       => open,
      S_AXI_CTRL_RDATA         => open,
      S_AXI_CTRL_RRESP         => open,
      S_AXI_CTRL_RVALID        => open,
      S_AXI_CTRL_RREADY        => net_gnd0
    );

  lmb_ibram_I : lmb_bram
    generic map (
      C_MEMSIZE             => C_MEMSIZE_I,
      C_MICROBLAZE_INSTANCE => "instr_" & C_MICROBLAZE_INSTANCE,
      C_FAMILY              => C_FAMILY)
    port map (
      BRAM_Rst_A  => ilmb_port_BRAM_Rst,
      BRAM_Clk_A  => ilmb_port_BRAM_Clk,
      BRAM_EN_A   => ilmb_port_BRAM_EN,
      BRAM_WEN_A  => ilmb_port_BRAM_WEN,
      BRAM_Addr_A => ilmb_port_BRAM_Addr,
      BRAM_Din_A  => ilmb_port_BRAM_Dout,
      BRAM_Dout_A => ilmb_port_BRAM_Din,
      BRAM_Rst_B  => ilmb_BRAM_Rst,
      BRAM_Clk_B  => ilmb_BRAM_Clk,
      BRAM_EN_B   => ilmb_BRAM_EN,
      BRAM_WEN_B  => ilmb_BRAM_WEN,
      BRAM_Addr_B => ilmb_BRAM_Addr,
      BRAM_Din_B  => ilmb_BRAM_Dout,
      BRAM_Dout_B => ilmb_BRAM_Din
    );

  lmb_dbram_I : lmb_bram
    generic map (
      C_MEMSIZE             => C_MEMSIZE_D,
      C_MICROBLAZE_INSTANCE => "data_" & C_MICROBLAZE_INSTANCE,
      C_FAMILY              => C_FAMILY)
    port map (
      BRAM_Rst_A  => dlmb_port_BRAM_Rst,
      BRAM_Clk_A  => dlmb_port_BRAM_Clk,
      BRAM_EN_A   => dlmb_port_BRAM_EN,
      BRAM_WEN_A  => dlmb_port_BRAM_WEN,
      BRAM_Addr_A => dlmb_port_BRAM_Addr,
      BRAM_Din_A  => dlmb_port_BRAM_Dout,
      BRAM_Dout_A => dlmb_port_BRAM_Din,
      BRAM_Rst_B  => dlmb_BRAM_Rst,
      BRAM_Clk_B  => dlmb_BRAM_Clk,
      BRAM_EN_B   => dlmb_BRAM_EN,
      BRAM_WEN_B  => dlmb_BRAM_WEN,
      BRAM_Addr_B => dlmb_BRAM_Addr,
      BRAM_Din_B  => dlmb_BRAM_Dout,
      BRAM_Dout_B => dlmb_BRAM_Din
    );

  iomodule_0 : iomodule
    generic map (
      C_FAMILY               => C_FAMILY,
      C_FREQ                 => C_FREQ,
      C_INSTANCE             => "iomodule",
      C_BASEADDR             => X"B0000000",
      C_HIGHADDR             => X"B000FFFF",
      C_MASK                 => X"F0000000",
      C_IO_BASEADDR          => X"A0000000",
      C_IO_HIGHADDR          => X"AFFFFFFF",
      C_IO_MASK              => X"F0000000",
      C_LMB_AWIDTH           => 32,
      C_LMB_DWIDTH           => 32,
      C_USE_IO_BUS           => C_USE_IO_BUS,
      C_USE_UART_RX          => C_USE_UART_RX,
      C_USE_UART_TX          => C_USE_UART_TX,
      C_UART_BAUDRATE        => C_UART_BAUDRATE,
      C_UART_DATA_BITS       => C_UART_DATA_BITS,
      C_UART_USE_PARITY      => C_UART_USE_PARITY,
      C_UART_ODD_PARITY      => C_UART_ODD_PARITY,
      C_UART_RX_INTERRUPT    => C_UART_RX_INTERRUPT,
      C_UART_TX_INTERRUPT    => C_UART_TX_INTERRUPT,
      C_UART_ERROR_INTERRUPT => C_UART_ERROR_INTERRUPT,
      C_USE_FIT1             => C_USE_FIT1,
      C_FIT1_No_CLOCKS       => C_FIT1_No_CLOCKS,
      C_FIT1_INTERRUPT       => C_FIT1_INTERRUPT,
      C_USE_FIT2             => C_USE_FIT2,
      C_FIT2_No_CLOCKS       => C_FIT2_No_CLOCKS,
      C_FIT2_INTERRUPT       => C_FIT2_INTERRUPT,
      C_USE_FIT3             => C_USE_FIT3,
      C_FIT3_No_CLOCKS       => C_FIT3_No_CLOCKS,
      C_FIT3_INTERRUPT       => C_FIT3_INTERRUPT,
      C_USE_FIT4             => C_USE_FIT4,
      C_FIT4_No_CLOCKS       => C_FIT4_No_CLOCKS,
      C_FIT4_INTERRUPT       => C_FIT4_INTERRUPT,
      C_USE_PIT1             => C_USE_PIT1,
      C_PIT1_SIZE            => C_PIT1_SIZE,
      C_PIT1_READABLE        => C_PIT1_READABLE,
      C_PIT1_PRESCALER       => C_PIT1_PRESCALER,
      C_PIT1_INTERRUPT       => C_PIT1_INTERRUPT,
      C_USE_PIT2             => C_USE_PIT2,
      C_PIT2_SIZE            => C_PIT2_SIZE,
      C_PIT2_READABLE        => C_PIT2_READABLE,
      C_PIT2_PRESCALER       => C_PIT2_PRESCALER,
      C_PIT2_INTERRUPT       => C_PIT2_INTERRUPT,
      C_USE_PIT3             => C_USE_PIT3,
      C_PIT3_SIZE            => C_PIT3_SIZE,
      C_PIT3_READABLE        => C_PIT3_READABLE,
      C_PIT3_PRESCALER       => C_PIT3_PRESCALER,
      C_PIT3_INTERRUPT       => C_PIT3_INTERRUPT,
      C_USE_PIT4             => C_USE_PIT4,
      C_PIT4_SIZE            => C_PIT4_SIZE,
      C_PIT4_READABLE        => C_PIT4_READABLE,
      C_PIT4_PRESCALER       => C_PIT4_PRESCALER,
      C_PIT4_INTERRUPT       => C_PIT4_INTERRUPT,
      C_USE_GPO1             => C_USE_GPO1,
      C_GPO1_SIZE            => C_GPO1_SIZE,
      C_GPO1_INIT            => C_GPO1_INIT,
      C_USE_GPO2             => C_USE_GPO2,
      C_GPO2_SIZE            => C_GPO2_SIZE,
      C_GPO2_INIT            => C_GPO2_INIT,
      C_USE_GPO3             => C_USE_GPO3,
      C_GPO3_SIZE            => C_GPO3_SIZE,
      C_GPO3_INIT            => C_GPO3_INIT,
      C_USE_GPO4             => C_USE_GPO4,
      C_GPO4_SIZE            => C_GPO4_SIZE,
      C_GPO4_INIT            => C_GPO4_INIT,
      C_USE_GPI1             => C_USE_GPI1,
      C_GPI1_SIZE            => C_GPI1_SIZE,
      C_USE_GPI2             => C_USE_GPI2,
      C_GPI2_SIZE            => C_GPI2_SIZE,
      C_USE_GPI3             => C_USE_GPI3,
      C_GPI3_SIZE            => C_GPI3_SIZE,
      C_USE_GPI4             => C_USE_GPI4,
      C_GPI4_SIZE            => C_GPI4_SIZE,
      C_INTC_USE_EXT_INTR    => C_INTC_USE_EXT_INTR,
      C_INTC_INTR_SIZE       => C_INTC_INTR_SIZE,
      C_INTC_LEVEL_EDGE      => C_INTC_LEVEL_EDGE,
      C_INTC_POSITIVE        => C_INTC_POSITIVE
      )
    port map (
      CLK             => Clk,
      Rst             => LMB_Rst,
      IO_Addr_Strobe  => IO_Addr_Strobe,
      IO_Read_Strobe  => IO_Read_Strobe,
      IO_Write_Strobe => IO_Write_Strobe,
      IO_Address      => IO_Address,
      IO_Byte_Enable  => IO_Byte_Enable,
      IO_Write_Data   => IO_Write_Data,
      IO_Read_Data    => IO_Read_Data,
      IO_Ready        => IO_Ready,
      UART_Rx         => UART_Rx,
      UART_Tx         => UART_Tx,
      UART_Interrupt  => UART_Interrupt,
      FIT1_Interrupt  => FIT1_Interrupt,
      FIT1_Toggle     => FIT1_Toggle,
      FIT2_Interrupt  => FIT2_Interrupt,
      FIT2_Toggle     => FIT2_Toggle,
      FIT3_Interrupt  => FIT3_Interrupt,
      FIT3_Toggle     => FIT3_Toggle,
      FIT4_Interrupt  => FIT4_Interrupt,
      FIT4_Toggle     => FIT4_Toggle,
      PIT1_Enable     => PIT1_Enable,
      PIT1_Interrupt  => PIT1_Interrupt,
      PIT1_Toggle     => PIT1_Toggle,
      PIT2_Enable     => PIT2_Enable,
      PIT2_Interrupt  => PIT2_Interrupt,
      PIT2_Toggle     => PIT2_Toggle,
      PIT3_Enable     => PIT3_Enable,
      PIT3_Interrupt  => PIT3_Interrupt,
      PIT3_Toggle     => PIT3_Toggle,
      PIT4_Enable     => PIT4_Enable,
      PIT4_Interrupt  => PIT4_Interrupt,
      PIT4_Toggle     => PIT4_Toggle,
      GPO1            => GPO1,
      GPO2            => GPO2,
      GPO3            => GPO3,
      GPO4            => GPO4,
      GPI1            => GPI1,
      GPI2            => GPI2,
      GPI3            => GPI3,
      GPI4            => GPI4,
      INTC_Interrupt  => INTC_Interrupt,
      INTC_IRQ        => Interrupt,
      LMB_ABus        => dlmb_LMB_ABus,
      LMB_WriteDBus   => dlmb_LMB_WriteDBus,
      LMB_AddrStrobe  => dlmb_LMB_AddrStrobe,
      LMB_ReadStrobe  => dlmb_LMB_ReadStrobe,
      LMB_WriteStrobe => dlmb_LMB_WriteStrobe,
      LMB_BE          => dlmb_LMB_BE,
      Sl_DBus         => dlmb_Sl_DBus(32 to 63),
      Sl_Ready        => dlmb_Sl_Ready(1),
      Sl_Wait         => dlmb_Sl_Wait(1),
      Sl_UE           => dlmb_Sl_UE(1),
      Sl_CE           => dlmb_Sl_CE(1)
    );

    INTC_IRQ <= Interrupt;

end architecture STRUCTURE;
