##############################################################
#
# Copyright (c) 2010 Beijing Soul, Inc. All rights reserved.
#
# Hu Gang
# 
##############################################################


BEGIN sata

OPTION STYLE = HDL
OPTION IPTYPE = BRIDGE
OPTION IMP_NETLIST = FALSE
OPTION RUN_NGCBUILD = TRUE
OPTION HDL = VERILOG
OPTION LAST_UPDATED = 10.1.2
OPTION DESC = TACHYON
OPTION IP_GROUP = MICROBLAZE:PPC:USER
OPTION PLATGEN_SYSLEVEL_UPDATE_PROC = generate_corelevel_ucf
OPTION ARCH_SUPPORT_MAP = (virtex2p=PREFERRED, virtex4lx=PREFERRED, virtex4sx=PREFERRED, virtex4fx=PREFERRED, virtex5lx=PREFERRED, virtex5sx=PREFERRED, virtex5tx=PREFERRED, virtex5fx=PREFERRED)

PARAMETER C_FAMILY = virtex5, DT = STRING
PARAMETER C_PORT = 4
PARAMETER C_VERSION = 0xdeaddead, DT = STD_LOGIC_VECTOR,  IPLEVEL_UPDATE_VALUE_PROC = update_version_proc
PARAMETER C_NUM_WIDTH = 5, DT = INTEGER, DESC = Width of M_xxNum, LONG_DESC = Width of the M_xxNum signal used to specify the length of a transfer. This value should be at least 5 to allow for full 16-dword fixed-length bursts. It may be larger to enable variable length bursts of arbitrary length.
PARAMETER C_DAT_WIDTH = 64

## Bus Interfaces
BUS_INTERFACE BUS = MLIPIF, BUS_TYPE = INITIATOR, BUS_STD = MLIPIF
PORT M_Clk       	= M_Clk       , DIR = I, SIGIS = CLK, BUS = MLIPIF
PORT M_Reset     	= M_Reset     , DIR = I, SIGIS = RST, BUS = MLIPIF
PORT M_Error     	= M_Error     , DIR = I, BUS = MLIPIF
PORT M_Lock      	= M_Lock      , DIR = O, BUS = MLIPIF
PORT M_rdReq     	= M_rdReq     , DIR = O, BUS = MLIPIF
PORT M_rdAccept  	= M_rdAccept  , DIR = I, BUS = MLIPIF
PORT M_rdAddr    	= M_rdAddr    , DIR = O, VEC = [31:0], BUS = MLIPIF
PORT M_rdNum     	= M_rdNum     , DIR = O, VEC = [(C_NUM_WIDTH-1):0], ENDIAN = LITTLE, BUS = MLIPIF
PORT M_rdBE      	= M_rdBE      , DIR = O, VEC = [(C_DAT_WIDTH-1)/8:0], BUS = MLIPIF
PORT M_rdData    	= M_rdData    , DIR = I, VEC = [(C_DAT_WIDTH-1):0], BUS = MLIPIF
PORT M_rdAck     	= M_rdAck     , DIR = I, BUS = MLIPIF
PORT M_rdComp    	= M_rdComp    , DIR = I, BUS = MLIPIF
PORT M_rdPriority 	= M_rdPriority, DIR = O, VEC = [1:0], BUS = MLIPIF
PORT M_rdType    	= M_rdType    , DIR = O, VEC = [2:0], BUS = MLIPIF
PORT M_rdCompress	= M_rdCompress, DIR = O, BUS = MLIPIF
PORT M_rdGuarded 	= M_rdGuarded , DIR = O, BUS = MLIPIF
PORT M_rdLockErr 	= M_rdLockErr , DIR = O, BUS = MLIPIF
PORT M_rdRearb   	= M_rdRearb   , DIR = I, BUS = MLIPIF
PORT M_rdAbort   	= M_rdAbort   , DIR = O, BUS = MLIPIF
PORT M_rdError   	= M_rdError   , DIR = I, BUS = MLIPIF
PORT M_wrReq     	= M_wrReq     , DIR = O, BUS = MLIPIF
PORT M_wrAccept  	= M_wrAccept  , DIR = I, BUS = MLIPIF
PORT M_wrAddr    	= M_wrAddr    , DIR = O, VEC = [31:0], BUS = MLIPIF
PORT M_wrNum     	= M_wrNum     , DIR = O, VEC = [(C_NUM_WIDTH-1):0], ENDIAN = LITTLE, BUS = MLIPIF
PORT M_wrBE      	= M_wrBE      , DIR = O, VEC = [(C_DAT_WIDTH-1)/8:0], BUS = MLIPIF
PORT M_wrData    	= M_wrData    , DIR = O, VEC = [C_DAT_WIDTH-1:0], BUS = MLIPIF
PORT M_wrRdy     	= M_wrRdy     , DIR = I, BUS = MLIPIF
PORT M_wrAck     	= M_wrAck     , DIR = I, BUS = MLIPIF
PORT M_wrComp    	= M_wrComp    , DIR = I, BUS = MLIPIF
PORT M_wrPriority	= M_wrPriority, DIR = O, VEC = [1:0], BUS = MLIPIF
PORT M_wrType    	= M_wrType    , DIR = O, VEC = [2:0], BUS = MLIPIF
PORT M_wrCompress	= M_wrCompress, DIR = O, BUS = MLIPIF
PORT M_wrGuarded 	= M_wrGuarded , DIR = O, BUS = MLIPIF
PORT M_wrOrdered 	= M_wrOrdered , DIR = O, BUS = MLIPIF
PORT M_wrLockErr 	= M_wrLockErr , DIR = O, BUS = MLIPIF
PORT M_wrRearb   	= M_wrRearb   , DIR = I, BUS = MLIPIF
PORT M_wrAbort   	= M_wrAbort   , DIR = O, BUS = MLIPIF
PORT M_wrError   	= M_wrError   , DIR = I, BUS = MLIPIF


define(`SATA_GTX_PORT',
`BUS_INTERFACE BUS = GTXBUS$1, BUS_TYPE = INITIATOR, BUS_STD = GTXIF
PORT phyreset$1       = phyreset,       DIR = O, BUS = GTXBUS$1
PORT phyclk$1         = phyclk,         DIR = I, BUS = GTXBUS$1
PORT txdata$1         = txdata,         DIR = O, BUS = GTXBUS$1, VEC = [31:0]
PORT txdatak$1        = txdatak,        DIR = O, BUS = GTXBUS$1
PORT txdatak_pop$1    = txdatak_pop,    DIR = I, BUS = GTXBUS$1
PORT rxdata$1         = rxdata,         DIR = I, BUS = GTXBUS$1, VEC = [31:0]
PORT rxdatak$1        = rxdatak,        DIR = I, BUS = GTXBUS$1
PORT linkup$1         = linkup,         DIR = I, BUS = GTXBUS$1
PORT plllock$1        = plllock,        DIR = I, BUS = GTXBUS$1
PORT oob2dbg$1        = oob2dbg,        DIR = I, BUS = GTXBUS$1, VEC = [127:0]
PORT StartComm$1      = StartComm,      DIR = O, BUS = GTXBUS$1
PORT CommInit$1       = CommInit,       DIR = I, BUS = GTXBUS$1
PORT gtx_tune$1       = gtx_tune,       DIR = O, BUS = GTXBUS$1, VEC = [31:0]
PORT gtx_txdata$1     = gtx_txdata,     DIR = I, BUS = GTXBUS$1, VEC = [31:0]
PORT gtx_txdatak$1    = gtx_txdatak,    DIR = I, BUS = GTXBUS$1, VEC = [3:0]
PORT gtx_rxdata$1     = gtx_rxdata,     DIR = I, BUS = GTXBUS$1, VEC = [31:0]
PORT gtx_rxdatak$1    = gtx_rxdatak,    DIR = I, BUS = GTXBUS$1, VEC = [3:0]')

SATA_GTX_PORT(0)
SATA_GTX_PORT(1)
SATA_GTX_PORT(2)
SATA_GTX_PORT(3)

# DCR
BUS_INTERFACE BUS = SDCR, BUS_STD = DCR, BUS_TYPE = SLAVE
PORT DCR_Clk = "", DIR = I, SIGIS = CLK
PORT DCR_Rst = "", DIR = I
PORT DCR_Read = DCR_Read, DIR = I, BUS = SDCR
PORT DCR_Write = DCR_Write, DIR = I, BUS = SDCR
PORT DCR_ABus = DCR_ABus, DIR = I, VEC = [0:9], BUS = SDCR
PORT DCR_Sl_DBus = DCR_Sl_DBus, DIR = I, VEC = [0:31], BUS = SDCR
PORT Sl_dcrDBus = Sl_dcrDBus, DIR = O, VEC = [0:31], BUS = SDCR
PORT Sl_dcrAck = Sl_dcrAck, DIR = O, BUS = SDCR

# Interrupt to CPU
#
PORT interrupt         = "",              DIR = O, SIGIS = INTERRUPT, SENSITIVITY = LEVEL_HIGH

PORT sata_ledA0  = "", DIR = O
PORT sata_ledB0  = "", DIR = O
PORT sata_ledA1  = "", DIR = O
PORT sata_ledB1  = "", DIR = O
PORT sata_ledA2  = "", DIR = O
PORT sata_ledB2  = "", DIR = O
PORT sata_ledA3  = "", DIR = O
PORT sata_ledB3  = "", DIR = O

## Bus Interfaces
BUS_INTERFACE BUS = DPLB, BUS_STD = PLBV46, BUS_TYPE = MASTER

PARAMETER C_DPLB_DWIDTH = 32, DT = integer, RANGE = (32,64,128), BUS = DPLB
PARAMETER C_DPLB_NATIVE_DWIDTH = 32, DT = integer, RANGE = (32:32), ASSIGNMENT = CONSTANT, BUS = DPLB
PARAMETER C_DPLB_BURST_EN = 0, DT = integer, RANGE = (0:0), ASSIGNMENT = CONSTANT, BUS = DPLB
PARAMETER C_DPLB_P2P = 0, DT = integer, RANGE = (0:1), BUS = DPLB

## Ports
PORT DPLB_M_ABort = M_ABort, DIR = O, BUS = DPLB
PORT DPLB_M_ABus = M_ABus, DIR = O, VEC = [0:31], BUS = DPLB
PORT DPLB_M_UABus = M_UABus, DIR = O, VEC = [0:31], BUS = DPLB
PORT DPLB_M_BE = M_BE, DIR = O, VEC = [0:(C_DPLB_DWIDTH-1)/8], BUS = DPLB
PORT DPLB_M_busLock = M_busLock, DIR = O, BUS = DPLB
PORT DPLB_M_lockErr = M_lockErr, DIR = O, BUS = DPLB
PORT DPLB_M_MSize = M_MSize, DIR = O, VEC = [0:1], BUS = DPLB
PORT DPLB_M_priority = M_priority, DIR = O, VEC = [0:1], BUS = DPLB
PORT DPLB_M_rdBurst = M_rdBurst, DIR = O, BUS = DPLB
PORT DPLB_M_request = M_request, DIR = O, BUS = DPLB
PORT DPLB_M_RNW = M_RNW, DIR = O, BUS = DPLB
PORT DPLB_M_size = M_size, DIR = O, VEC = [0:3], BUS = DPLB
PORT DPLB_M_TAttribute = M_TAttribute, DIR = O, VEC = [0:15], BUS = DPLB
PORT DPLB_M_type = M_type, DIR = O, VEC = [0:2], BUS = DPLB
PORT DPLB_M_wrBurst = M_wrBurst, DIR = O, BUS = DPLB
PORT DPLB_M_wrDBus = M_wrDBus, DIR = O, VEC = [0:C_DPLB_DWIDTH-1], BUS = DPLB
PORT DPLB_MBusy = PLB_MBusy, DIR = I, BUS = DPLB
PORT DPLB_MRdErr = PLB_MRdErr, DIR = I, BUS = DPLB
PORT DPLB_MWrErr = PLB_MWrErr, DIR = I, BUS = DPLB
PORT DPLB_MIRQ = PLB_MIRQ, DIR = I, BUS = DPLB
PORT DPLB_MWrBTerm = PLB_MWrBTerm, DIR = I, BUS = DPLB
PORT DPLB_MWrDAck = PLB_MWrDAck, DIR = I, BUS = DPLB
PORT DPLB_MAddrAck = PLB_MAddrAck, DIR = I, BUS = DPLB
PORT DPLB_MRdBTerm = PLB_MRdBTerm, DIR = I, BUS = DPLB
PORT DPLB_MRdDAck = PLB_MRdDAck, DIR = I, BUS = DPLB
PORT DPLB_MRdDBus = PLB_MRdDBus, DIR = I, VEC = [0:C_DPLB_DWIDTH-1], BUS = DPLB
PORT DPLB_MRdWdAddr = PLB_MRdWdAddr, DIR = I, VEC = [0:3], BUS = DPLB
PORT DPLB_MRearbitrate = PLB_MRearbitrate, DIR = I, BUS = DPLB
PORT DPLB_MSSize = PLB_MSSize, DIR = I, VEC = [0:1], BUS = DPLB
PORT DPLB_MTimeout = PLB_MTimeout, DIR = I, BUS = DPLB

PARAMETER C_DEBUG_ENABLED = 0, DT = integer, RANGE = (0:1)

BUS_INTERFACE BUS = DEBUG, BUS_STD = XIL_MBDEBUG3, BUS_TYPE = TARGET
PORT DBG_CLK = Dbg_Clk, DIR = I, BUS = DEBUG
PORT DBG_TDI = Dbg_TDI, DIR = I, BUS = DEBUG
PORT DBG_TDO = Dbg_TDO, DIR = O, BUS = DEBUG
PORT DBG_REG_EN = Dbg_Reg_En, DIR = I, VEC = [0:7], BUS = DEBUG
PORT DBG_SHIFT = Dbg_Shift, DIR = I, BUS = DEBUG
PORT DBG_CAPTURE = Dbg_Capture, DIR = I, BUS = DEBUG
PORT DBG_UPDATE = Dbg_Update, DIR = I, BUS = DEBUG
PORT DBG_RST = Debug_Rst, DIR = I, SIGIS = RST, BUS = DEBUG

END
