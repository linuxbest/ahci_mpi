//-----------------------------------------------------------------------------
// ppc440mc_ddr2_0_wrapper.v
//-----------------------------------------------------------------------------

`timescale 1 ps / 100 fs

`uselib lib=unisims_ver lib=proc_common_v3_00_a lib=plbv46_slave_single_v1_01_a lib=mpmc_v6_03_a

module ppc440mc_ddr2_0_wrapper
  (
    FSL0_M_Clk,
    FSL0_M_Write,
    FSL0_M_Data,
    FSL0_M_Control,
    FSL0_M_Full,
    FSL0_S_Clk,
    FSL0_S_Read,
    FSL0_S_Data,
    FSL0_S_Control,
    FSL0_S_Exists,
    FSL0_B_M_Clk,
    FSL0_B_M_Write,
    FSL0_B_M_Data,
    FSL0_B_M_Control,
    FSL0_B_M_Full,
    FSL0_B_S_Clk,
    FSL0_B_S_Read,
    FSL0_B_S_Data,
    FSL0_B_S_Control,
    FSL0_B_S_Exists,
    SPLB0_Clk,
    SPLB0_Rst,
    SPLB0_PLB_ABus,
    SPLB0_PLB_PAValid,
    SPLB0_PLB_SAValid,
    SPLB0_PLB_masterID,
    SPLB0_PLB_RNW,
    SPLB0_PLB_BE,
    SPLB0_PLB_UABus,
    SPLB0_PLB_rdPrim,
    SPLB0_PLB_wrPrim,
    SPLB0_PLB_abort,
    SPLB0_PLB_busLock,
    SPLB0_PLB_MSize,
    SPLB0_PLB_size,
    SPLB0_PLB_type,
    SPLB0_PLB_lockErr,
    SPLB0_PLB_wrPendReq,
    SPLB0_PLB_wrPendPri,
    SPLB0_PLB_rdPendReq,
    SPLB0_PLB_rdPendPri,
    SPLB0_PLB_reqPri,
    SPLB0_PLB_TAttribute,
    SPLB0_PLB_rdBurst,
    SPLB0_PLB_wrBurst,
    SPLB0_PLB_wrDBus,
    SPLB0_Sl_addrAck,
    SPLB0_Sl_SSize,
    SPLB0_Sl_wait,
    SPLB0_Sl_rearbitrate,
    SPLB0_Sl_wrDAck,
    SPLB0_Sl_wrComp,
    SPLB0_Sl_wrBTerm,
    SPLB0_Sl_rdDBus,
    SPLB0_Sl_rdWdAddr,
    SPLB0_Sl_rdDAck,
    SPLB0_Sl_rdComp,
    SPLB0_Sl_rdBTerm,
    SPLB0_Sl_MBusy,
    SPLB0_Sl_MRdErr,
    SPLB0_Sl_MWrErr,
    SPLB0_Sl_MIRQ,
    SDMA0_Clk,
    SDMA0_Rx_IntOut,
    SDMA0_Tx_IntOut,
    SDMA0_RstOut,
    SDMA0_TX_D,
    SDMA0_TX_Rem,
    SDMA0_TX_SOF,
    SDMA0_TX_EOF,
    SDMA0_TX_SOP,
    SDMA0_TX_EOP,
    SDMA0_TX_Src_Rdy,
    SDMA0_TX_Dst_Rdy,
    SDMA0_RX_D,
    SDMA0_RX_Rem,
    SDMA0_RX_SOF,
    SDMA0_RX_EOF,
    SDMA0_RX_SOP,
    SDMA0_RX_EOP,
    SDMA0_RX_Src_Rdy,
    SDMA0_RX_Dst_Rdy,
    SDMA_CTRL0_Clk,
    SDMA_CTRL0_Rst,
    SDMA_CTRL0_PLB_ABus,
    SDMA_CTRL0_PLB_PAValid,
    SDMA_CTRL0_PLB_SAValid,
    SDMA_CTRL0_PLB_masterID,
    SDMA_CTRL0_PLB_RNW,
    SDMA_CTRL0_PLB_BE,
    SDMA_CTRL0_PLB_UABus,
    SDMA_CTRL0_PLB_rdPrim,
    SDMA_CTRL0_PLB_wrPrim,
    SDMA_CTRL0_PLB_abort,
    SDMA_CTRL0_PLB_busLock,
    SDMA_CTRL0_PLB_MSize,
    SDMA_CTRL0_PLB_size,
    SDMA_CTRL0_PLB_type,
    SDMA_CTRL0_PLB_lockErr,
    SDMA_CTRL0_PLB_wrPendReq,
    SDMA_CTRL0_PLB_wrPendPri,
    SDMA_CTRL0_PLB_rdPendReq,
    SDMA_CTRL0_PLB_rdPendPri,
    SDMA_CTRL0_PLB_reqPri,
    SDMA_CTRL0_PLB_TAttribute,
    SDMA_CTRL0_PLB_rdBurst,
    SDMA_CTRL0_PLB_wrBurst,
    SDMA_CTRL0_PLB_wrDBus,
    SDMA_CTRL0_Sl_addrAck,
    SDMA_CTRL0_Sl_SSize,
    SDMA_CTRL0_Sl_wait,
    SDMA_CTRL0_Sl_rearbitrate,
    SDMA_CTRL0_Sl_wrDAck,
    SDMA_CTRL0_Sl_wrComp,
    SDMA_CTRL0_Sl_wrBTerm,
    SDMA_CTRL0_Sl_rdDBus,
    SDMA_CTRL0_Sl_rdWdAddr,
    SDMA_CTRL0_Sl_rdDAck,
    SDMA_CTRL0_Sl_rdComp,
    SDMA_CTRL0_Sl_rdBTerm,
    SDMA_CTRL0_Sl_MBusy,
    SDMA_CTRL0_Sl_MRdErr,
    SDMA_CTRL0_Sl_MWrErr,
    SDMA_CTRL0_Sl_MIRQ,
    PIM0_Addr,
    PIM0_AddrReq,
    PIM0_AddrAck,
    PIM0_RNW,
    PIM0_Size,
    PIM0_RdModWr,
    PIM0_WrFIFO_Data,
    PIM0_WrFIFO_BE,
    PIM0_WrFIFO_Push,
    PIM0_RdFIFO_Data,
    PIM0_RdFIFO_Pop,
    PIM0_RdFIFO_RdWdAddr,
    PIM0_WrFIFO_Empty,
    PIM0_WrFIFO_AlmostFull,
    PIM0_WrFIFO_Flush,
    PIM0_RdFIFO_Empty,
    PIM0_RdFIFO_Flush,
    PIM0_RdFIFO_Latency,
    PIM0_InitDone,
    PPC440MC0_MIMCReadNotWrite,
    PPC440MC0_MIMCAddress,
    PPC440MC0_MIMCAddressValid,
    PPC440MC0_MIMCWriteData,
    PPC440MC0_MIMCWriteDataValid,
    PPC440MC0_MIMCByteEnable,
    PPC440MC0_MIMCBankConflict,
    PPC440MC0_MIMCRowConflict,
    PPC440MC0_MCMIReadData,
    PPC440MC0_MCMIReadDataValid,
    PPC440MC0_MCMIReadDataErr,
    PPC440MC0_MCMIAddrReadyToAccept,
    VFBC0_Cmd_Clk,
    VFBC0_Cmd_Reset,
    VFBC0_Cmd_Data,
    VFBC0_Cmd_Write,
    VFBC0_Cmd_End,
    VFBC0_Cmd_Full,
    VFBC0_Cmd_Almost_Full,
    VFBC0_Cmd_Idle,
    VFBC0_Wd_Clk,
    VFBC0_Wd_Reset,
    VFBC0_Wd_Write,
    VFBC0_Wd_End_Burst,
    VFBC0_Wd_Flush,
    VFBC0_Wd_Data,
    VFBC0_Wd_Data_BE,
    VFBC0_Wd_Full,
    VFBC0_Wd_Almost_Full,
    VFBC0_Rd_Clk,
    VFBC0_Rd_Reset,
    VFBC0_Rd_Read,
    VFBC0_Rd_End_Burst,
    VFBC0_Rd_Flush,
    VFBC0_Rd_Data,
    VFBC0_Rd_Empty,
    VFBC0_Rd_Almost_Empty,
    MCB0_cmd_clk,
    MCB0_cmd_en,
    MCB0_cmd_instr,
    MCB0_cmd_bl,
    MCB0_cmd_byte_addr,
    MCB0_cmd_empty,
    MCB0_cmd_full,
    MCB0_wr_clk,
    MCB0_wr_en,
    MCB0_wr_mask,
    MCB0_wr_data,
    MCB0_wr_full,
    MCB0_wr_empty,
    MCB0_wr_count,
    MCB0_wr_underrun,
    MCB0_wr_error,
    MCB0_rd_clk,
    MCB0_rd_en,
    MCB0_rd_data,
    MCB0_rd_full,
    MCB0_rd_empty,
    MCB0_rd_count,
    MCB0_rd_overflow,
    MCB0_rd_error,
    FSL1_M_Clk,
    FSL1_M_Write,
    FSL1_M_Data,
    FSL1_M_Control,
    FSL1_M_Full,
    FSL1_S_Clk,
    FSL1_S_Read,
    FSL1_S_Data,
    FSL1_S_Control,
    FSL1_S_Exists,
    FSL1_B_M_Clk,
    FSL1_B_M_Write,
    FSL1_B_M_Data,
    FSL1_B_M_Control,
    FSL1_B_M_Full,
    FSL1_B_S_Clk,
    FSL1_B_S_Read,
    FSL1_B_S_Data,
    FSL1_B_S_Control,
    FSL1_B_S_Exists,
    SPLB1_Clk,
    SPLB1_Rst,
    SPLB1_PLB_ABus,
    SPLB1_PLB_PAValid,
    SPLB1_PLB_SAValid,
    SPLB1_PLB_masterID,
    SPLB1_PLB_RNW,
    SPLB1_PLB_BE,
    SPLB1_PLB_UABus,
    SPLB1_PLB_rdPrim,
    SPLB1_PLB_wrPrim,
    SPLB1_PLB_abort,
    SPLB1_PLB_busLock,
    SPLB1_PLB_MSize,
    SPLB1_PLB_size,
    SPLB1_PLB_type,
    SPLB1_PLB_lockErr,
    SPLB1_PLB_wrPendReq,
    SPLB1_PLB_wrPendPri,
    SPLB1_PLB_rdPendReq,
    SPLB1_PLB_rdPendPri,
    SPLB1_PLB_reqPri,
    SPLB1_PLB_TAttribute,
    SPLB1_PLB_rdBurst,
    SPLB1_PLB_wrBurst,
    SPLB1_PLB_wrDBus,
    SPLB1_Sl_addrAck,
    SPLB1_Sl_SSize,
    SPLB1_Sl_wait,
    SPLB1_Sl_rearbitrate,
    SPLB1_Sl_wrDAck,
    SPLB1_Sl_wrComp,
    SPLB1_Sl_wrBTerm,
    SPLB1_Sl_rdDBus,
    SPLB1_Sl_rdWdAddr,
    SPLB1_Sl_rdDAck,
    SPLB1_Sl_rdComp,
    SPLB1_Sl_rdBTerm,
    SPLB1_Sl_MBusy,
    SPLB1_Sl_MRdErr,
    SPLB1_Sl_MWrErr,
    SPLB1_Sl_MIRQ,
    SDMA1_Clk,
    SDMA1_Rx_IntOut,
    SDMA1_Tx_IntOut,
    SDMA1_RstOut,
    SDMA1_TX_D,
    SDMA1_TX_Rem,
    SDMA1_TX_SOF,
    SDMA1_TX_EOF,
    SDMA1_TX_SOP,
    SDMA1_TX_EOP,
    SDMA1_TX_Src_Rdy,
    SDMA1_TX_Dst_Rdy,
    SDMA1_RX_D,
    SDMA1_RX_Rem,
    SDMA1_RX_SOF,
    SDMA1_RX_EOF,
    SDMA1_RX_SOP,
    SDMA1_RX_EOP,
    SDMA1_RX_Src_Rdy,
    SDMA1_RX_Dst_Rdy,
    SDMA_CTRL1_Clk,
    SDMA_CTRL1_Rst,
    SDMA_CTRL1_PLB_ABus,
    SDMA_CTRL1_PLB_PAValid,
    SDMA_CTRL1_PLB_SAValid,
    SDMA_CTRL1_PLB_masterID,
    SDMA_CTRL1_PLB_RNW,
    SDMA_CTRL1_PLB_BE,
    SDMA_CTRL1_PLB_UABus,
    SDMA_CTRL1_PLB_rdPrim,
    SDMA_CTRL1_PLB_wrPrim,
    SDMA_CTRL1_PLB_abort,
    SDMA_CTRL1_PLB_busLock,
    SDMA_CTRL1_PLB_MSize,
    SDMA_CTRL1_PLB_size,
    SDMA_CTRL1_PLB_type,
    SDMA_CTRL1_PLB_lockErr,
    SDMA_CTRL1_PLB_wrPendReq,
    SDMA_CTRL1_PLB_wrPendPri,
    SDMA_CTRL1_PLB_rdPendReq,
    SDMA_CTRL1_PLB_rdPendPri,
    SDMA_CTRL1_PLB_reqPri,
    SDMA_CTRL1_PLB_TAttribute,
    SDMA_CTRL1_PLB_rdBurst,
    SDMA_CTRL1_PLB_wrBurst,
    SDMA_CTRL1_PLB_wrDBus,
    SDMA_CTRL1_Sl_addrAck,
    SDMA_CTRL1_Sl_SSize,
    SDMA_CTRL1_Sl_wait,
    SDMA_CTRL1_Sl_rearbitrate,
    SDMA_CTRL1_Sl_wrDAck,
    SDMA_CTRL1_Sl_wrComp,
    SDMA_CTRL1_Sl_wrBTerm,
    SDMA_CTRL1_Sl_rdDBus,
    SDMA_CTRL1_Sl_rdWdAddr,
    SDMA_CTRL1_Sl_rdDAck,
    SDMA_CTRL1_Sl_rdComp,
    SDMA_CTRL1_Sl_rdBTerm,
    SDMA_CTRL1_Sl_MBusy,
    SDMA_CTRL1_Sl_MRdErr,
    SDMA_CTRL1_Sl_MWrErr,
    SDMA_CTRL1_Sl_MIRQ,
    PIM1_Addr,
    PIM1_AddrReq,
    PIM1_AddrAck,
    PIM1_RNW,
    PIM1_Size,
    PIM1_RdModWr,
    PIM1_WrFIFO_Data,
    PIM1_WrFIFO_BE,
    PIM1_WrFIFO_Push,
    PIM1_RdFIFO_Data,
    PIM1_RdFIFO_Pop,
    PIM1_RdFIFO_RdWdAddr,
    PIM1_WrFIFO_Empty,
    PIM1_WrFIFO_AlmostFull,
    PIM1_WrFIFO_Flush,
    PIM1_RdFIFO_Empty,
    PIM1_RdFIFO_Flush,
    PIM1_RdFIFO_Latency,
    PIM1_InitDone,
    PPC440MC1_MIMCReadNotWrite,
    PPC440MC1_MIMCAddress,
    PPC440MC1_MIMCAddressValid,
    PPC440MC1_MIMCWriteData,
    PPC440MC1_MIMCWriteDataValid,
    PPC440MC1_MIMCByteEnable,
    PPC440MC1_MIMCBankConflict,
    PPC440MC1_MIMCRowConflict,
    PPC440MC1_MCMIReadData,
    PPC440MC1_MCMIReadDataValid,
    PPC440MC1_MCMIReadDataErr,
    PPC440MC1_MCMIAddrReadyToAccept,
    VFBC1_Cmd_Clk,
    VFBC1_Cmd_Reset,
    VFBC1_Cmd_Data,
    VFBC1_Cmd_Write,
    VFBC1_Cmd_End,
    VFBC1_Cmd_Full,
    VFBC1_Cmd_Almost_Full,
    VFBC1_Cmd_Idle,
    VFBC1_Wd_Clk,
    VFBC1_Wd_Reset,
    VFBC1_Wd_Write,
    VFBC1_Wd_End_Burst,
    VFBC1_Wd_Flush,
    VFBC1_Wd_Data,
    VFBC1_Wd_Data_BE,
    VFBC1_Wd_Full,
    VFBC1_Wd_Almost_Full,
    VFBC1_Rd_Clk,
    VFBC1_Rd_Reset,
    VFBC1_Rd_Read,
    VFBC1_Rd_End_Burst,
    VFBC1_Rd_Flush,
    VFBC1_Rd_Data,
    VFBC1_Rd_Empty,
    VFBC1_Rd_Almost_Empty,
    MCB1_cmd_clk,
    MCB1_cmd_en,
    MCB1_cmd_instr,
    MCB1_cmd_bl,
    MCB1_cmd_byte_addr,
    MCB1_cmd_empty,
    MCB1_cmd_full,
    MCB1_wr_clk,
    MCB1_wr_en,
    MCB1_wr_mask,
    MCB1_wr_data,
    MCB1_wr_full,
    MCB1_wr_empty,
    MCB1_wr_count,
    MCB1_wr_underrun,
    MCB1_wr_error,
    MCB1_rd_clk,
    MCB1_rd_en,
    MCB1_rd_data,
    MCB1_rd_full,
    MCB1_rd_empty,
    MCB1_rd_count,
    MCB1_rd_overflow,
    MCB1_rd_error,
    FSL2_M_Clk,
    FSL2_M_Write,
    FSL2_M_Data,
    FSL2_M_Control,
    FSL2_M_Full,
    FSL2_S_Clk,
    FSL2_S_Read,
    FSL2_S_Data,
    FSL2_S_Control,
    FSL2_S_Exists,
    FSL2_B_M_Clk,
    FSL2_B_M_Write,
    FSL2_B_M_Data,
    FSL2_B_M_Control,
    FSL2_B_M_Full,
    FSL2_B_S_Clk,
    FSL2_B_S_Read,
    FSL2_B_S_Data,
    FSL2_B_S_Control,
    FSL2_B_S_Exists,
    SPLB2_Clk,
    SPLB2_Rst,
    SPLB2_PLB_ABus,
    SPLB2_PLB_PAValid,
    SPLB2_PLB_SAValid,
    SPLB2_PLB_masterID,
    SPLB2_PLB_RNW,
    SPLB2_PLB_BE,
    SPLB2_PLB_UABus,
    SPLB2_PLB_rdPrim,
    SPLB2_PLB_wrPrim,
    SPLB2_PLB_abort,
    SPLB2_PLB_busLock,
    SPLB2_PLB_MSize,
    SPLB2_PLB_size,
    SPLB2_PLB_type,
    SPLB2_PLB_lockErr,
    SPLB2_PLB_wrPendReq,
    SPLB2_PLB_wrPendPri,
    SPLB2_PLB_rdPendReq,
    SPLB2_PLB_rdPendPri,
    SPLB2_PLB_reqPri,
    SPLB2_PLB_TAttribute,
    SPLB2_PLB_rdBurst,
    SPLB2_PLB_wrBurst,
    SPLB2_PLB_wrDBus,
    SPLB2_Sl_addrAck,
    SPLB2_Sl_SSize,
    SPLB2_Sl_wait,
    SPLB2_Sl_rearbitrate,
    SPLB2_Sl_wrDAck,
    SPLB2_Sl_wrComp,
    SPLB2_Sl_wrBTerm,
    SPLB2_Sl_rdDBus,
    SPLB2_Sl_rdWdAddr,
    SPLB2_Sl_rdDAck,
    SPLB2_Sl_rdComp,
    SPLB2_Sl_rdBTerm,
    SPLB2_Sl_MBusy,
    SPLB2_Sl_MRdErr,
    SPLB2_Sl_MWrErr,
    SPLB2_Sl_MIRQ,
    SDMA2_Clk,
    SDMA2_Rx_IntOut,
    SDMA2_Tx_IntOut,
    SDMA2_RstOut,
    SDMA2_TX_D,
    SDMA2_TX_Rem,
    SDMA2_TX_SOF,
    SDMA2_TX_EOF,
    SDMA2_TX_SOP,
    SDMA2_TX_EOP,
    SDMA2_TX_Src_Rdy,
    SDMA2_TX_Dst_Rdy,
    SDMA2_RX_D,
    SDMA2_RX_Rem,
    SDMA2_RX_SOF,
    SDMA2_RX_EOF,
    SDMA2_RX_SOP,
    SDMA2_RX_EOP,
    SDMA2_RX_Src_Rdy,
    SDMA2_RX_Dst_Rdy,
    SDMA_CTRL2_Clk,
    SDMA_CTRL2_Rst,
    SDMA_CTRL2_PLB_ABus,
    SDMA_CTRL2_PLB_PAValid,
    SDMA_CTRL2_PLB_SAValid,
    SDMA_CTRL2_PLB_masterID,
    SDMA_CTRL2_PLB_RNW,
    SDMA_CTRL2_PLB_BE,
    SDMA_CTRL2_PLB_UABus,
    SDMA_CTRL2_PLB_rdPrim,
    SDMA_CTRL2_PLB_wrPrim,
    SDMA_CTRL2_PLB_abort,
    SDMA_CTRL2_PLB_busLock,
    SDMA_CTRL2_PLB_MSize,
    SDMA_CTRL2_PLB_size,
    SDMA_CTRL2_PLB_type,
    SDMA_CTRL2_PLB_lockErr,
    SDMA_CTRL2_PLB_wrPendReq,
    SDMA_CTRL2_PLB_wrPendPri,
    SDMA_CTRL2_PLB_rdPendReq,
    SDMA_CTRL2_PLB_rdPendPri,
    SDMA_CTRL2_PLB_reqPri,
    SDMA_CTRL2_PLB_TAttribute,
    SDMA_CTRL2_PLB_rdBurst,
    SDMA_CTRL2_PLB_wrBurst,
    SDMA_CTRL2_PLB_wrDBus,
    SDMA_CTRL2_Sl_addrAck,
    SDMA_CTRL2_Sl_SSize,
    SDMA_CTRL2_Sl_wait,
    SDMA_CTRL2_Sl_rearbitrate,
    SDMA_CTRL2_Sl_wrDAck,
    SDMA_CTRL2_Sl_wrComp,
    SDMA_CTRL2_Sl_wrBTerm,
    SDMA_CTRL2_Sl_rdDBus,
    SDMA_CTRL2_Sl_rdWdAddr,
    SDMA_CTRL2_Sl_rdDAck,
    SDMA_CTRL2_Sl_rdComp,
    SDMA_CTRL2_Sl_rdBTerm,
    SDMA_CTRL2_Sl_MBusy,
    SDMA_CTRL2_Sl_MRdErr,
    SDMA_CTRL2_Sl_MWrErr,
    SDMA_CTRL2_Sl_MIRQ,
    PIM2_Addr,
    PIM2_AddrReq,
    PIM2_AddrAck,
    PIM2_RNW,
    PIM2_Size,
    PIM2_RdModWr,
    PIM2_WrFIFO_Data,
    PIM2_WrFIFO_BE,
    PIM2_WrFIFO_Push,
    PIM2_RdFIFO_Data,
    PIM2_RdFIFO_Pop,
    PIM2_RdFIFO_RdWdAddr,
    PIM2_WrFIFO_Empty,
    PIM2_WrFIFO_AlmostFull,
    PIM2_WrFIFO_Flush,
    PIM2_RdFIFO_Empty,
    PIM2_RdFIFO_Flush,
    PIM2_RdFIFO_Latency,
    PIM2_InitDone,
    PPC440MC2_MIMCReadNotWrite,
    PPC440MC2_MIMCAddress,
    PPC440MC2_MIMCAddressValid,
    PPC440MC2_MIMCWriteData,
    PPC440MC2_MIMCWriteDataValid,
    PPC440MC2_MIMCByteEnable,
    PPC440MC2_MIMCBankConflict,
    PPC440MC2_MIMCRowConflict,
    PPC440MC2_MCMIReadData,
    PPC440MC2_MCMIReadDataValid,
    PPC440MC2_MCMIReadDataErr,
    PPC440MC2_MCMIAddrReadyToAccept,
    VFBC2_Cmd_Clk,
    VFBC2_Cmd_Reset,
    VFBC2_Cmd_Data,
    VFBC2_Cmd_Write,
    VFBC2_Cmd_End,
    VFBC2_Cmd_Full,
    VFBC2_Cmd_Almost_Full,
    VFBC2_Cmd_Idle,
    VFBC2_Wd_Clk,
    VFBC2_Wd_Reset,
    VFBC2_Wd_Write,
    VFBC2_Wd_End_Burst,
    VFBC2_Wd_Flush,
    VFBC2_Wd_Data,
    VFBC2_Wd_Data_BE,
    VFBC2_Wd_Full,
    VFBC2_Wd_Almost_Full,
    VFBC2_Rd_Clk,
    VFBC2_Rd_Reset,
    VFBC2_Rd_Read,
    VFBC2_Rd_End_Burst,
    VFBC2_Rd_Flush,
    VFBC2_Rd_Data,
    VFBC2_Rd_Empty,
    VFBC2_Rd_Almost_Empty,
    MCB2_cmd_clk,
    MCB2_cmd_en,
    MCB2_cmd_instr,
    MCB2_cmd_bl,
    MCB2_cmd_byte_addr,
    MCB2_cmd_empty,
    MCB2_cmd_full,
    MCB2_wr_clk,
    MCB2_wr_en,
    MCB2_wr_mask,
    MCB2_wr_data,
    MCB2_wr_full,
    MCB2_wr_empty,
    MCB2_wr_count,
    MCB2_wr_underrun,
    MCB2_wr_error,
    MCB2_rd_clk,
    MCB2_rd_en,
    MCB2_rd_data,
    MCB2_rd_full,
    MCB2_rd_empty,
    MCB2_rd_count,
    MCB2_rd_overflow,
    MCB2_rd_error,
    FSL3_M_Clk,
    FSL3_M_Write,
    FSL3_M_Data,
    FSL3_M_Control,
    FSL3_M_Full,
    FSL3_S_Clk,
    FSL3_S_Read,
    FSL3_S_Data,
    FSL3_S_Control,
    FSL3_S_Exists,
    FSL3_B_M_Clk,
    FSL3_B_M_Write,
    FSL3_B_M_Data,
    FSL3_B_M_Control,
    FSL3_B_M_Full,
    FSL3_B_S_Clk,
    FSL3_B_S_Read,
    FSL3_B_S_Data,
    FSL3_B_S_Control,
    FSL3_B_S_Exists,
    SPLB3_Clk,
    SPLB3_Rst,
    SPLB3_PLB_ABus,
    SPLB3_PLB_PAValid,
    SPLB3_PLB_SAValid,
    SPLB3_PLB_masterID,
    SPLB3_PLB_RNW,
    SPLB3_PLB_BE,
    SPLB3_PLB_UABus,
    SPLB3_PLB_rdPrim,
    SPLB3_PLB_wrPrim,
    SPLB3_PLB_abort,
    SPLB3_PLB_busLock,
    SPLB3_PLB_MSize,
    SPLB3_PLB_size,
    SPLB3_PLB_type,
    SPLB3_PLB_lockErr,
    SPLB3_PLB_wrPendReq,
    SPLB3_PLB_wrPendPri,
    SPLB3_PLB_rdPendReq,
    SPLB3_PLB_rdPendPri,
    SPLB3_PLB_reqPri,
    SPLB3_PLB_TAttribute,
    SPLB3_PLB_rdBurst,
    SPLB3_PLB_wrBurst,
    SPLB3_PLB_wrDBus,
    SPLB3_Sl_addrAck,
    SPLB3_Sl_SSize,
    SPLB3_Sl_wait,
    SPLB3_Sl_rearbitrate,
    SPLB3_Sl_wrDAck,
    SPLB3_Sl_wrComp,
    SPLB3_Sl_wrBTerm,
    SPLB3_Sl_rdDBus,
    SPLB3_Sl_rdWdAddr,
    SPLB3_Sl_rdDAck,
    SPLB3_Sl_rdComp,
    SPLB3_Sl_rdBTerm,
    SPLB3_Sl_MBusy,
    SPLB3_Sl_MRdErr,
    SPLB3_Sl_MWrErr,
    SPLB3_Sl_MIRQ,
    SDMA3_Clk,
    SDMA3_Rx_IntOut,
    SDMA3_Tx_IntOut,
    SDMA3_RstOut,
    SDMA3_TX_D,
    SDMA3_TX_Rem,
    SDMA3_TX_SOF,
    SDMA3_TX_EOF,
    SDMA3_TX_SOP,
    SDMA3_TX_EOP,
    SDMA3_TX_Src_Rdy,
    SDMA3_TX_Dst_Rdy,
    SDMA3_RX_D,
    SDMA3_RX_Rem,
    SDMA3_RX_SOF,
    SDMA3_RX_EOF,
    SDMA3_RX_SOP,
    SDMA3_RX_EOP,
    SDMA3_RX_Src_Rdy,
    SDMA3_RX_Dst_Rdy,
    SDMA_CTRL3_Clk,
    SDMA_CTRL3_Rst,
    SDMA_CTRL3_PLB_ABus,
    SDMA_CTRL3_PLB_PAValid,
    SDMA_CTRL3_PLB_SAValid,
    SDMA_CTRL3_PLB_masterID,
    SDMA_CTRL3_PLB_RNW,
    SDMA_CTRL3_PLB_BE,
    SDMA_CTRL3_PLB_UABus,
    SDMA_CTRL3_PLB_rdPrim,
    SDMA_CTRL3_PLB_wrPrim,
    SDMA_CTRL3_PLB_abort,
    SDMA_CTRL3_PLB_busLock,
    SDMA_CTRL3_PLB_MSize,
    SDMA_CTRL3_PLB_size,
    SDMA_CTRL3_PLB_type,
    SDMA_CTRL3_PLB_lockErr,
    SDMA_CTRL3_PLB_wrPendReq,
    SDMA_CTRL3_PLB_wrPendPri,
    SDMA_CTRL3_PLB_rdPendReq,
    SDMA_CTRL3_PLB_rdPendPri,
    SDMA_CTRL3_PLB_reqPri,
    SDMA_CTRL3_PLB_TAttribute,
    SDMA_CTRL3_PLB_rdBurst,
    SDMA_CTRL3_PLB_wrBurst,
    SDMA_CTRL3_PLB_wrDBus,
    SDMA_CTRL3_Sl_addrAck,
    SDMA_CTRL3_Sl_SSize,
    SDMA_CTRL3_Sl_wait,
    SDMA_CTRL3_Sl_rearbitrate,
    SDMA_CTRL3_Sl_wrDAck,
    SDMA_CTRL3_Sl_wrComp,
    SDMA_CTRL3_Sl_wrBTerm,
    SDMA_CTRL3_Sl_rdDBus,
    SDMA_CTRL3_Sl_rdWdAddr,
    SDMA_CTRL3_Sl_rdDAck,
    SDMA_CTRL3_Sl_rdComp,
    SDMA_CTRL3_Sl_rdBTerm,
    SDMA_CTRL3_Sl_MBusy,
    SDMA_CTRL3_Sl_MRdErr,
    SDMA_CTRL3_Sl_MWrErr,
    SDMA_CTRL3_Sl_MIRQ,
    PIM3_Addr,
    PIM3_AddrReq,
    PIM3_AddrAck,
    PIM3_RNW,
    PIM3_Size,
    PIM3_RdModWr,
    PIM3_WrFIFO_Data,
    PIM3_WrFIFO_BE,
    PIM3_WrFIFO_Push,
    PIM3_RdFIFO_Data,
    PIM3_RdFIFO_Pop,
    PIM3_RdFIFO_RdWdAddr,
    PIM3_WrFIFO_Empty,
    PIM3_WrFIFO_AlmostFull,
    PIM3_WrFIFO_Flush,
    PIM3_RdFIFO_Empty,
    PIM3_RdFIFO_Flush,
    PIM3_RdFIFO_Latency,
    PIM3_InitDone,
    PPC440MC3_MIMCReadNotWrite,
    PPC440MC3_MIMCAddress,
    PPC440MC3_MIMCAddressValid,
    PPC440MC3_MIMCWriteData,
    PPC440MC3_MIMCWriteDataValid,
    PPC440MC3_MIMCByteEnable,
    PPC440MC3_MIMCBankConflict,
    PPC440MC3_MIMCRowConflict,
    PPC440MC3_MCMIReadData,
    PPC440MC3_MCMIReadDataValid,
    PPC440MC3_MCMIReadDataErr,
    PPC440MC3_MCMIAddrReadyToAccept,
    VFBC3_Cmd_Clk,
    VFBC3_Cmd_Reset,
    VFBC3_Cmd_Data,
    VFBC3_Cmd_Write,
    VFBC3_Cmd_End,
    VFBC3_Cmd_Full,
    VFBC3_Cmd_Almost_Full,
    VFBC3_Cmd_Idle,
    VFBC3_Wd_Clk,
    VFBC3_Wd_Reset,
    VFBC3_Wd_Write,
    VFBC3_Wd_End_Burst,
    VFBC3_Wd_Flush,
    VFBC3_Wd_Data,
    VFBC3_Wd_Data_BE,
    VFBC3_Wd_Full,
    VFBC3_Wd_Almost_Full,
    VFBC3_Rd_Clk,
    VFBC3_Rd_Reset,
    VFBC3_Rd_Read,
    VFBC3_Rd_End_Burst,
    VFBC3_Rd_Flush,
    VFBC3_Rd_Data,
    VFBC3_Rd_Empty,
    VFBC3_Rd_Almost_Empty,
    MCB3_cmd_clk,
    MCB3_cmd_en,
    MCB3_cmd_instr,
    MCB3_cmd_bl,
    MCB3_cmd_byte_addr,
    MCB3_cmd_empty,
    MCB3_cmd_full,
    MCB3_wr_clk,
    MCB3_wr_en,
    MCB3_wr_mask,
    MCB3_wr_data,
    MCB3_wr_full,
    MCB3_wr_empty,
    MCB3_wr_count,
    MCB3_wr_underrun,
    MCB3_wr_error,
    MCB3_rd_clk,
    MCB3_rd_en,
    MCB3_rd_data,
    MCB3_rd_full,
    MCB3_rd_empty,
    MCB3_rd_count,
    MCB3_rd_overflow,
    MCB3_rd_error,
    FSL4_M_Clk,
    FSL4_M_Write,
    FSL4_M_Data,
    FSL4_M_Control,
    FSL4_M_Full,
    FSL4_S_Clk,
    FSL4_S_Read,
    FSL4_S_Data,
    FSL4_S_Control,
    FSL4_S_Exists,
    FSL4_B_M_Clk,
    FSL4_B_M_Write,
    FSL4_B_M_Data,
    FSL4_B_M_Control,
    FSL4_B_M_Full,
    FSL4_B_S_Clk,
    FSL4_B_S_Read,
    FSL4_B_S_Data,
    FSL4_B_S_Control,
    FSL4_B_S_Exists,
    SPLB4_Clk,
    SPLB4_Rst,
    SPLB4_PLB_ABus,
    SPLB4_PLB_PAValid,
    SPLB4_PLB_SAValid,
    SPLB4_PLB_masterID,
    SPLB4_PLB_RNW,
    SPLB4_PLB_BE,
    SPLB4_PLB_UABus,
    SPLB4_PLB_rdPrim,
    SPLB4_PLB_wrPrim,
    SPLB4_PLB_abort,
    SPLB4_PLB_busLock,
    SPLB4_PLB_MSize,
    SPLB4_PLB_size,
    SPLB4_PLB_type,
    SPLB4_PLB_lockErr,
    SPLB4_PLB_wrPendReq,
    SPLB4_PLB_wrPendPri,
    SPLB4_PLB_rdPendReq,
    SPLB4_PLB_rdPendPri,
    SPLB4_PLB_reqPri,
    SPLB4_PLB_TAttribute,
    SPLB4_PLB_rdBurst,
    SPLB4_PLB_wrBurst,
    SPLB4_PLB_wrDBus,
    SPLB4_Sl_addrAck,
    SPLB4_Sl_SSize,
    SPLB4_Sl_wait,
    SPLB4_Sl_rearbitrate,
    SPLB4_Sl_wrDAck,
    SPLB4_Sl_wrComp,
    SPLB4_Sl_wrBTerm,
    SPLB4_Sl_rdDBus,
    SPLB4_Sl_rdWdAddr,
    SPLB4_Sl_rdDAck,
    SPLB4_Sl_rdComp,
    SPLB4_Sl_rdBTerm,
    SPLB4_Sl_MBusy,
    SPLB4_Sl_MRdErr,
    SPLB4_Sl_MWrErr,
    SPLB4_Sl_MIRQ,
    SDMA4_Clk,
    SDMA4_Rx_IntOut,
    SDMA4_Tx_IntOut,
    SDMA4_RstOut,
    SDMA4_TX_D,
    SDMA4_TX_Rem,
    SDMA4_TX_SOF,
    SDMA4_TX_EOF,
    SDMA4_TX_SOP,
    SDMA4_TX_EOP,
    SDMA4_TX_Src_Rdy,
    SDMA4_TX_Dst_Rdy,
    SDMA4_RX_D,
    SDMA4_RX_Rem,
    SDMA4_RX_SOF,
    SDMA4_RX_EOF,
    SDMA4_RX_SOP,
    SDMA4_RX_EOP,
    SDMA4_RX_Src_Rdy,
    SDMA4_RX_Dst_Rdy,
    SDMA_CTRL4_Clk,
    SDMA_CTRL4_Rst,
    SDMA_CTRL4_PLB_ABus,
    SDMA_CTRL4_PLB_PAValid,
    SDMA_CTRL4_PLB_SAValid,
    SDMA_CTRL4_PLB_masterID,
    SDMA_CTRL4_PLB_RNW,
    SDMA_CTRL4_PLB_BE,
    SDMA_CTRL4_PLB_UABus,
    SDMA_CTRL4_PLB_rdPrim,
    SDMA_CTRL4_PLB_wrPrim,
    SDMA_CTRL4_PLB_abort,
    SDMA_CTRL4_PLB_busLock,
    SDMA_CTRL4_PLB_MSize,
    SDMA_CTRL4_PLB_size,
    SDMA_CTRL4_PLB_type,
    SDMA_CTRL4_PLB_lockErr,
    SDMA_CTRL4_PLB_wrPendReq,
    SDMA_CTRL4_PLB_wrPendPri,
    SDMA_CTRL4_PLB_rdPendReq,
    SDMA_CTRL4_PLB_rdPendPri,
    SDMA_CTRL4_PLB_reqPri,
    SDMA_CTRL4_PLB_TAttribute,
    SDMA_CTRL4_PLB_rdBurst,
    SDMA_CTRL4_PLB_wrBurst,
    SDMA_CTRL4_PLB_wrDBus,
    SDMA_CTRL4_Sl_addrAck,
    SDMA_CTRL4_Sl_SSize,
    SDMA_CTRL4_Sl_wait,
    SDMA_CTRL4_Sl_rearbitrate,
    SDMA_CTRL4_Sl_wrDAck,
    SDMA_CTRL4_Sl_wrComp,
    SDMA_CTRL4_Sl_wrBTerm,
    SDMA_CTRL4_Sl_rdDBus,
    SDMA_CTRL4_Sl_rdWdAddr,
    SDMA_CTRL4_Sl_rdDAck,
    SDMA_CTRL4_Sl_rdComp,
    SDMA_CTRL4_Sl_rdBTerm,
    SDMA_CTRL4_Sl_MBusy,
    SDMA_CTRL4_Sl_MRdErr,
    SDMA_CTRL4_Sl_MWrErr,
    SDMA_CTRL4_Sl_MIRQ,
    PIM4_Addr,
    PIM4_AddrReq,
    PIM4_AddrAck,
    PIM4_RNW,
    PIM4_Size,
    PIM4_RdModWr,
    PIM4_WrFIFO_Data,
    PIM4_WrFIFO_BE,
    PIM4_WrFIFO_Push,
    PIM4_RdFIFO_Data,
    PIM4_RdFIFO_Pop,
    PIM4_RdFIFO_RdWdAddr,
    PIM4_WrFIFO_Empty,
    PIM4_WrFIFO_AlmostFull,
    PIM4_WrFIFO_Flush,
    PIM4_RdFIFO_Empty,
    PIM4_RdFIFO_Flush,
    PIM4_RdFIFO_Latency,
    PIM4_InitDone,
    PPC440MC4_MIMCReadNotWrite,
    PPC440MC4_MIMCAddress,
    PPC440MC4_MIMCAddressValid,
    PPC440MC4_MIMCWriteData,
    PPC440MC4_MIMCWriteDataValid,
    PPC440MC4_MIMCByteEnable,
    PPC440MC4_MIMCBankConflict,
    PPC440MC4_MIMCRowConflict,
    PPC440MC4_MCMIReadData,
    PPC440MC4_MCMIReadDataValid,
    PPC440MC4_MCMIReadDataErr,
    PPC440MC4_MCMIAddrReadyToAccept,
    VFBC4_Cmd_Clk,
    VFBC4_Cmd_Reset,
    VFBC4_Cmd_Data,
    VFBC4_Cmd_Write,
    VFBC4_Cmd_End,
    VFBC4_Cmd_Full,
    VFBC4_Cmd_Almost_Full,
    VFBC4_Cmd_Idle,
    VFBC4_Wd_Clk,
    VFBC4_Wd_Reset,
    VFBC4_Wd_Write,
    VFBC4_Wd_End_Burst,
    VFBC4_Wd_Flush,
    VFBC4_Wd_Data,
    VFBC4_Wd_Data_BE,
    VFBC4_Wd_Full,
    VFBC4_Wd_Almost_Full,
    VFBC4_Rd_Clk,
    VFBC4_Rd_Reset,
    VFBC4_Rd_Read,
    VFBC4_Rd_End_Burst,
    VFBC4_Rd_Flush,
    VFBC4_Rd_Data,
    VFBC4_Rd_Empty,
    VFBC4_Rd_Almost_Empty,
    MCB4_cmd_clk,
    MCB4_cmd_en,
    MCB4_cmd_instr,
    MCB4_cmd_bl,
    MCB4_cmd_byte_addr,
    MCB4_cmd_empty,
    MCB4_cmd_full,
    MCB4_wr_clk,
    MCB4_wr_en,
    MCB4_wr_mask,
    MCB4_wr_data,
    MCB4_wr_full,
    MCB4_wr_empty,
    MCB4_wr_count,
    MCB4_wr_underrun,
    MCB4_wr_error,
    MCB4_rd_clk,
    MCB4_rd_en,
    MCB4_rd_data,
    MCB4_rd_full,
    MCB4_rd_empty,
    MCB4_rd_count,
    MCB4_rd_overflow,
    MCB4_rd_error,
    FSL5_M_Clk,
    FSL5_M_Write,
    FSL5_M_Data,
    FSL5_M_Control,
    FSL5_M_Full,
    FSL5_S_Clk,
    FSL5_S_Read,
    FSL5_S_Data,
    FSL5_S_Control,
    FSL5_S_Exists,
    FSL5_B_M_Clk,
    FSL5_B_M_Write,
    FSL5_B_M_Data,
    FSL5_B_M_Control,
    FSL5_B_M_Full,
    FSL5_B_S_Clk,
    FSL5_B_S_Read,
    FSL5_B_S_Data,
    FSL5_B_S_Control,
    FSL5_B_S_Exists,
    SPLB5_Clk,
    SPLB5_Rst,
    SPLB5_PLB_ABus,
    SPLB5_PLB_PAValid,
    SPLB5_PLB_SAValid,
    SPLB5_PLB_masterID,
    SPLB5_PLB_RNW,
    SPLB5_PLB_BE,
    SPLB5_PLB_UABus,
    SPLB5_PLB_rdPrim,
    SPLB5_PLB_wrPrim,
    SPLB5_PLB_abort,
    SPLB5_PLB_busLock,
    SPLB5_PLB_MSize,
    SPLB5_PLB_size,
    SPLB5_PLB_type,
    SPLB5_PLB_lockErr,
    SPLB5_PLB_wrPendReq,
    SPLB5_PLB_wrPendPri,
    SPLB5_PLB_rdPendReq,
    SPLB5_PLB_rdPendPri,
    SPLB5_PLB_reqPri,
    SPLB5_PLB_TAttribute,
    SPLB5_PLB_rdBurst,
    SPLB5_PLB_wrBurst,
    SPLB5_PLB_wrDBus,
    SPLB5_Sl_addrAck,
    SPLB5_Sl_SSize,
    SPLB5_Sl_wait,
    SPLB5_Sl_rearbitrate,
    SPLB5_Sl_wrDAck,
    SPLB5_Sl_wrComp,
    SPLB5_Sl_wrBTerm,
    SPLB5_Sl_rdDBus,
    SPLB5_Sl_rdWdAddr,
    SPLB5_Sl_rdDAck,
    SPLB5_Sl_rdComp,
    SPLB5_Sl_rdBTerm,
    SPLB5_Sl_MBusy,
    SPLB5_Sl_MRdErr,
    SPLB5_Sl_MWrErr,
    SPLB5_Sl_MIRQ,
    SDMA5_Clk,
    SDMA5_Rx_IntOut,
    SDMA5_Tx_IntOut,
    SDMA5_RstOut,
    SDMA5_TX_D,
    SDMA5_TX_Rem,
    SDMA5_TX_SOF,
    SDMA5_TX_EOF,
    SDMA5_TX_SOP,
    SDMA5_TX_EOP,
    SDMA5_TX_Src_Rdy,
    SDMA5_TX_Dst_Rdy,
    SDMA5_RX_D,
    SDMA5_RX_Rem,
    SDMA5_RX_SOF,
    SDMA5_RX_EOF,
    SDMA5_RX_SOP,
    SDMA5_RX_EOP,
    SDMA5_RX_Src_Rdy,
    SDMA5_RX_Dst_Rdy,
    SDMA_CTRL5_Clk,
    SDMA_CTRL5_Rst,
    SDMA_CTRL5_PLB_ABus,
    SDMA_CTRL5_PLB_PAValid,
    SDMA_CTRL5_PLB_SAValid,
    SDMA_CTRL5_PLB_masterID,
    SDMA_CTRL5_PLB_RNW,
    SDMA_CTRL5_PLB_BE,
    SDMA_CTRL5_PLB_UABus,
    SDMA_CTRL5_PLB_rdPrim,
    SDMA_CTRL5_PLB_wrPrim,
    SDMA_CTRL5_PLB_abort,
    SDMA_CTRL5_PLB_busLock,
    SDMA_CTRL5_PLB_MSize,
    SDMA_CTRL5_PLB_size,
    SDMA_CTRL5_PLB_type,
    SDMA_CTRL5_PLB_lockErr,
    SDMA_CTRL5_PLB_wrPendReq,
    SDMA_CTRL5_PLB_wrPendPri,
    SDMA_CTRL5_PLB_rdPendReq,
    SDMA_CTRL5_PLB_rdPendPri,
    SDMA_CTRL5_PLB_reqPri,
    SDMA_CTRL5_PLB_TAttribute,
    SDMA_CTRL5_PLB_rdBurst,
    SDMA_CTRL5_PLB_wrBurst,
    SDMA_CTRL5_PLB_wrDBus,
    SDMA_CTRL5_Sl_addrAck,
    SDMA_CTRL5_Sl_SSize,
    SDMA_CTRL5_Sl_wait,
    SDMA_CTRL5_Sl_rearbitrate,
    SDMA_CTRL5_Sl_wrDAck,
    SDMA_CTRL5_Sl_wrComp,
    SDMA_CTRL5_Sl_wrBTerm,
    SDMA_CTRL5_Sl_rdDBus,
    SDMA_CTRL5_Sl_rdWdAddr,
    SDMA_CTRL5_Sl_rdDAck,
    SDMA_CTRL5_Sl_rdComp,
    SDMA_CTRL5_Sl_rdBTerm,
    SDMA_CTRL5_Sl_MBusy,
    SDMA_CTRL5_Sl_MRdErr,
    SDMA_CTRL5_Sl_MWrErr,
    SDMA_CTRL5_Sl_MIRQ,
    PIM5_Addr,
    PIM5_AddrReq,
    PIM5_AddrAck,
    PIM5_RNW,
    PIM5_Size,
    PIM5_RdModWr,
    PIM5_WrFIFO_Data,
    PIM5_WrFIFO_BE,
    PIM5_WrFIFO_Push,
    PIM5_RdFIFO_Data,
    PIM5_RdFIFO_Pop,
    PIM5_RdFIFO_RdWdAddr,
    PIM5_WrFIFO_Empty,
    PIM5_WrFIFO_AlmostFull,
    PIM5_WrFIFO_Flush,
    PIM5_RdFIFO_Empty,
    PIM5_RdFIFO_Flush,
    PIM5_RdFIFO_Latency,
    PIM5_InitDone,
    PPC440MC5_MIMCReadNotWrite,
    PPC440MC5_MIMCAddress,
    PPC440MC5_MIMCAddressValid,
    PPC440MC5_MIMCWriteData,
    PPC440MC5_MIMCWriteDataValid,
    PPC440MC5_MIMCByteEnable,
    PPC440MC5_MIMCBankConflict,
    PPC440MC5_MIMCRowConflict,
    PPC440MC5_MCMIReadData,
    PPC440MC5_MCMIReadDataValid,
    PPC440MC5_MCMIReadDataErr,
    PPC440MC5_MCMIAddrReadyToAccept,
    VFBC5_Cmd_Clk,
    VFBC5_Cmd_Reset,
    VFBC5_Cmd_Data,
    VFBC5_Cmd_Write,
    VFBC5_Cmd_End,
    VFBC5_Cmd_Full,
    VFBC5_Cmd_Almost_Full,
    VFBC5_Cmd_Idle,
    VFBC5_Wd_Clk,
    VFBC5_Wd_Reset,
    VFBC5_Wd_Write,
    VFBC5_Wd_End_Burst,
    VFBC5_Wd_Flush,
    VFBC5_Wd_Data,
    VFBC5_Wd_Data_BE,
    VFBC5_Wd_Full,
    VFBC5_Wd_Almost_Full,
    VFBC5_Rd_Clk,
    VFBC5_Rd_Reset,
    VFBC5_Rd_Read,
    VFBC5_Rd_End_Burst,
    VFBC5_Rd_Flush,
    VFBC5_Rd_Data,
    VFBC5_Rd_Empty,
    VFBC5_Rd_Almost_Empty,
    MCB5_cmd_clk,
    MCB5_cmd_en,
    MCB5_cmd_instr,
    MCB5_cmd_bl,
    MCB5_cmd_byte_addr,
    MCB5_cmd_empty,
    MCB5_cmd_full,
    MCB5_wr_clk,
    MCB5_wr_en,
    MCB5_wr_mask,
    MCB5_wr_data,
    MCB5_wr_full,
    MCB5_wr_empty,
    MCB5_wr_count,
    MCB5_wr_underrun,
    MCB5_wr_error,
    MCB5_rd_clk,
    MCB5_rd_en,
    MCB5_rd_data,
    MCB5_rd_full,
    MCB5_rd_empty,
    MCB5_rd_count,
    MCB5_rd_overflow,
    MCB5_rd_error,
    FSL6_M_Clk,
    FSL6_M_Write,
    FSL6_M_Data,
    FSL6_M_Control,
    FSL6_M_Full,
    FSL6_S_Clk,
    FSL6_S_Read,
    FSL6_S_Data,
    FSL6_S_Control,
    FSL6_S_Exists,
    FSL6_B_M_Clk,
    FSL6_B_M_Write,
    FSL6_B_M_Data,
    FSL6_B_M_Control,
    FSL6_B_M_Full,
    FSL6_B_S_Clk,
    FSL6_B_S_Read,
    FSL6_B_S_Data,
    FSL6_B_S_Control,
    FSL6_B_S_Exists,
    SPLB6_Clk,
    SPLB6_Rst,
    SPLB6_PLB_ABus,
    SPLB6_PLB_PAValid,
    SPLB6_PLB_SAValid,
    SPLB6_PLB_masterID,
    SPLB6_PLB_RNW,
    SPLB6_PLB_BE,
    SPLB6_PLB_UABus,
    SPLB6_PLB_rdPrim,
    SPLB6_PLB_wrPrim,
    SPLB6_PLB_abort,
    SPLB6_PLB_busLock,
    SPLB6_PLB_MSize,
    SPLB6_PLB_size,
    SPLB6_PLB_type,
    SPLB6_PLB_lockErr,
    SPLB6_PLB_wrPendReq,
    SPLB6_PLB_wrPendPri,
    SPLB6_PLB_rdPendReq,
    SPLB6_PLB_rdPendPri,
    SPLB6_PLB_reqPri,
    SPLB6_PLB_TAttribute,
    SPLB6_PLB_rdBurst,
    SPLB6_PLB_wrBurst,
    SPLB6_PLB_wrDBus,
    SPLB6_Sl_addrAck,
    SPLB6_Sl_SSize,
    SPLB6_Sl_wait,
    SPLB6_Sl_rearbitrate,
    SPLB6_Sl_wrDAck,
    SPLB6_Sl_wrComp,
    SPLB6_Sl_wrBTerm,
    SPLB6_Sl_rdDBus,
    SPLB6_Sl_rdWdAddr,
    SPLB6_Sl_rdDAck,
    SPLB6_Sl_rdComp,
    SPLB6_Sl_rdBTerm,
    SPLB6_Sl_MBusy,
    SPLB6_Sl_MRdErr,
    SPLB6_Sl_MWrErr,
    SPLB6_Sl_MIRQ,
    SDMA6_Clk,
    SDMA6_Rx_IntOut,
    SDMA6_Tx_IntOut,
    SDMA6_RstOut,
    SDMA6_TX_D,
    SDMA6_TX_Rem,
    SDMA6_TX_SOF,
    SDMA6_TX_EOF,
    SDMA6_TX_SOP,
    SDMA6_TX_EOP,
    SDMA6_TX_Src_Rdy,
    SDMA6_TX_Dst_Rdy,
    SDMA6_RX_D,
    SDMA6_RX_Rem,
    SDMA6_RX_SOF,
    SDMA6_RX_EOF,
    SDMA6_RX_SOP,
    SDMA6_RX_EOP,
    SDMA6_RX_Src_Rdy,
    SDMA6_RX_Dst_Rdy,
    SDMA_CTRL6_Clk,
    SDMA_CTRL6_Rst,
    SDMA_CTRL6_PLB_ABus,
    SDMA_CTRL6_PLB_PAValid,
    SDMA_CTRL6_PLB_SAValid,
    SDMA_CTRL6_PLB_masterID,
    SDMA_CTRL6_PLB_RNW,
    SDMA_CTRL6_PLB_BE,
    SDMA_CTRL6_PLB_UABus,
    SDMA_CTRL6_PLB_rdPrim,
    SDMA_CTRL6_PLB_wrPrim,
    SDMA_CTRL6_PLB_abort,
    SDMA_CTRL6_PLB_busLock,
    SDMA_CTRL6_PLB_MSize,
    SDMA_CTRL6_PLB_size,
    SDMA_CTRL6_PLB_type,
    SDMA_CTRL6_PLB_lockErr,
    SDMA_CTRL6_PLB_wrPendReq,
    SDMA_CTRL6_PLB_wrPendPri,
    SDMA_CTRL6_PLB_rdPendReq,
    SDMA_CTRL6_PLB_rdPendPri,
    SDMA_CTRL6_PLB_reqPri,
    SDMA_CTRL6_PLB_TAttribute,
    SDMA_CTRL6_PLB_rdBurst,
    SDMA_CTRL6_PLB_wrBurst,
    SDMA_CTRL6_PLB_wrDBus,
    SDMA_CTRL6_Sl_addrAck,
    SDMA_CTRL6_Sl_SSize,
    SDMA_CTRL6_Sl_wait,
    SDMA_CTRL6_Sl_rearbitrate,
    SDMA_CTRL6_Sl_wrDAck,
    SDMA_CTRL6_Sl_wrComp,
    SDMA_CTRL6_Sl_wrBTerm,
    SDMA_CTRL6_Sl_rdDBus,
    SDMA_CTRL6_Sl_rdWdAddr,
    SDMA_CTRL6_Sl_rdDAck,
    SDMA_CTRL6_Sl_rdComp,
    SDMA_CTRL6_Sl_rdBTerm,
    SDMA_CTRL6_Sl_MBusy,
    SDMA_CTRL6_Sl_MRdErr,
    SDMA_CTRL6_Sl_MWrErr,
    SDMA_CTRL6_Sl_MIRQ,
    PIM6_Addr,
    PIM6_AddrReq,
    PIM6_AddrAck,
    PIM6_RNW,
    PIM6_Size,
    PIM6_RdModWr,
    PIM6_WrFIFO_Data,
    PIM6_WrFIFO_BE,
    PIM6_WrFIFO_Push,
    PIM6_RdFIFO_Data,
    PIM6_RdFIFO_Pop,
    PIM6_RdFIFO_RdWdAddr,
    PIM6_WrFIFO_Empty,
    PIM6_WrFIFO_AlmostFull,
    PIM6_WrFIFO_Flush,
    PIM6_RdFIFO_Empty,
    PIM6_RdFIFO_Flush,
    PIM6_RdFIFO_Latency,
    PIM6_InitDone,
    PPC440MC6_MIMCReadNotWrite,
    PPC440MC6_MIMCAddress,
    PPC440MC6_MIMCAddressValid,
    PPC440MC6_MIMCWriteData,
    PPC440MC6_MIMCWriteDataValid,
    PPC440MC6_MIMCByteEnable,
    PPC440MC6_MIMCBankConflict,
    PPC440MC6_MIMCRowConflict,
    PPC440MC6_MCMIReadData,
    PPC440MC6_MCMIReadDataValid,
    PPC440MC6_MCMIReadDataErr,
    PPC440MC6_MCMIAddrReadyToAccept,
    VFBC6_Cmd_Clk,
    VFBC6_Cmd_Reset,
    VFBC6_Cmd_Data,
    VFBC6_Cmd_Write,
    VFBC6_Cmd_End,
    VFBC6_Cmd_Full,
    VFBC6_Cmd_Almost_Full,
    VFBC6_Cmd_Idle,
    VFBC6_Wd_Clk,
    VFBC6_Wd_Reset,
    VFBC6_Wd_Write,
    VFBC6_Wd_End_Burst,
    VFBC6_Wd_Flush,
    VFBC6_Wd_Data,
    VFBC6_Wd_Data_BE,
    VFBC6_Wd_Full,
    VFBC6_Wd_Almost_Full,
    VFBC6_Rd_Clk,
    VFBC6_Rd_Reset,
    VFBC6_Rd_Read,
    VFBC6_Rd_End_Burst,
    VFBC6_Rd_Flush,
    VFBC6_Rd_Data,
    VFBC6_Rd_Empty,
    VFBC6_Rd_Almost_Empty,
    MCB6_cmd_clk,
    MCB6_cmd_en,
    MCB6_cmd_instr,
    MCB6_cmd_bl,
    MCB6_cmd_byte_addr,
    MCB6_cmd_empty,
    MCB6_cmd_full,
    MCB6_wr_clk,
    MCB6_wr_en,
    MCB6_wr_mask,
    MCB6_wr_data,
    MCB6_wr_full,
    MCB6_wr_empty,
    MCB6_wr_count,
    MCB6_wr_underrun,
    MCB6_wr_error,
    MCB6_rd_clk,
    MCB6_rd_en,
    MCB6_rd_data,
    MCB6_rd_full,
    MCB6_rd_empty,
    MCB6_rd_count,
    MCB6_rd_overflow,
    MCB6_rd_error,
    FSL7_M_Clk,
    FSL7_M_Write,
    FSL7_M_Data,
    FSL7_M_Control,
    FSL7_M_Full,
    FSL7_S_Clk,
    FSL7_S_Read,
    FSL7_S_Data,
    FSL7_S_Control,
    FSL7_S_Exists,
    FSL7_B_M_Clk,
    FSL7_B_M_Write,
    FSL7_B_M_Data,
    FSL7_B_M_Control,
    FSL7_B_M_Full,
    FSL7_B_S_Clk,
    FSL7_B_S_Read,
    FSL7_B_S_Data,
    FSL7_B_S_Control,
    FSL7_B_S_Exists,
    SPLB7_Clk,
    SPLB7_Rst,
    SPLB7_PLB_ABus,
    SPLB7_PLB_PAValid,
    SPLB7_PLB_SAValid,
    SPLB7_PLB_masterID,
    SPLB7_PLB_RNW,
    SPLB7_PLB_BE,
    SPLB7_PLB_UABus,
    SPLB7_PLB_rdPrim,
    SPLB7_PLB_wrPrim,
    SPLB7_PLB_abort,
    SPLB7_PLB_busLock,
    SPLB7_PLB_MSize,
    SPLB7_PLB_size,
    SPLB7_PLB_type,
    SPLB7_PLB_lockErr,
    SPLB7_PLB_wrPendReq,
    SPLB7_PLB_wrPendPri,
    SPLB7_PLB_rdPendReq,
    SPLB7_PLB_rdPendPri,
    SPLB7_PLB_reqPri,
    SPLB7_PLB_TAttribute,
    SPLB7_PLB_rdBurst,
    SPLB7_PLB_wrBurst,
    SPLB7_PLB_wrDBus,
    SPLB7_Sl_addrAck,
    SPLB7_Sl_SSize,
    SPLB7_Sl_wait,
    SPLB7_Sl_rearbitrate,
    SPLB7_Sl_wrDAck,
    SPLB7_Sl_wrComp,
    SPLB7_Sl_wrBTerm,
    SPLB7_Sl_rdDBus,
    SPLB7_Sl_rdWdAddr,
    SPLB7_Sl_rdDAck,
    SPLB7_Sl_rdComp,
    SPLB7_Sl_rdBTerm,
    SPLB7_Sl_MBusy,
    SPLB7_Sl_MRdErr,
    SPLB7_Sl_MWrErr,
    SPLB7_Sl_MIRQ,
    SDMA7_Clk,
    SDMA7_Rx_IntOut,
    SDMA7_Tx_IntOut,
    SDMA7_RstOut,
    SDMA7_TX_D,
    SDMA7_TX_Rem,
    SDMA7_TX_SOF,
    SDMA7_TX_EOF,
    SDMA7_TX_SOP,
    SDMA7_TX_EOP,
    SDMA7_TX_Src_Rdy,
    SDMA7_TX_Dst_Rdy,
    SDMA7_RX_D,
    SDMA7_RX_Rem,
    SDMA7_RX_SOF,
    SDMA7_RX_EOF,
    SDMA7_RX_SOP,
    SDMA7_RX_EOP,
    SDMA7_RX_Src_Rdy,
    SDMA7_RX_Dst_Rdy,
    SDMA_CTRL7_Clk,
    SDMA_CTRL7_Rst,
    SDMA_CTRL7_PLB_ABus,
    SDMA_CTRL7_PLB_PAValid,
    SDMA_CTRL7_PLB_SAValid,
    SDMA_CTRL7_PLB_masterID,
    SDMA_CTRL7_PLB_RNW,
    SDMA_CTRL7_PLB_BE,
    SDMA_CTRL7_PLB_UABus,
    SDMA_CTRL7_PLB_rdPrim,
    SDMA_CTRL7_PLB_wrPrim,
    SDMA_CTRL7_PLB_abort,
    SDMA_CTRL7_PLB_busLock,
    SDMA_CTRL7_PLB_MSize,
    SDMA_CTRL7_PLB_size,
    SDMA_CTRL7_PLB_type,
    SDMA_CTRL7_PLB_lockErr,
    SDMA_CTRL7_PLB_wrPendReq,
    SDMA_CTRL7_PLB_wrPendPri,
    SDMA_CTRL7_PLB_rdPendReq,
    SDMA_CTRL7_PLB_rdPendPri,
    SDMA_CTRL7_PLB_reqPri,
    SDMA_CTRL7_PLB_TAttribute,
    SDMA_CTRL7_PLB_rdBurst,
    SDMA_CTRL7_PLB_wrBurst,
    SDMA_CTRL7_PLB_wrDBus,
    SDMA_CTRL7_Sl_addrAck,
    SDMA_CTRL7_Sl_SSize,
    SDMA_CTRL7_Sl_wait,
    SDMA_CTRL7_Sl_rearbitrate,
    SDMA_CTRL7_Sl_wrDAck,
    SDMA_CTRL7_Sl_wrComp,
    SDMA_CTRL7_Sl_wrBTerm,
    SDMA_CTRL7_Sl_rdDBus,
    SDMA_CTRL7_Sl_rdWdAddr,
    SDMA_CTRL7_Sl_rdDAck,
    SDMA_CTRL7_Sl_rdComp,
    SDMA_CTRL7_Sl_rdBTerm,
    SDMA_CTRL7_Sl_MBusy,
    SDMA_CTRL7_Sl_MRdErr,
    SDMA_CTRL7_Sl_MWrErr,
    SDMA_CTRL7_Sl_MIRQ,
    PIM7_Addr,
    PIM7_AddrReq,
    PIM7_AddrAck,
    PIM7_RNW,
    PIM7_Size,
    PIM7_RdModWr,
    PIM7_WrFIFO_Data,
    PIM7_WrFIFO_BE,
    PIM7_WrFIFO_Push,
    PIM7_RdFIFO_Data,
    PIM7_RdFIFO_Pop,
    PIM7_RdFIFO_RdWdAddr,
    PIM7_WrFIFO_Empty,
    PIM7_WrFIFO_AlmostFull,
    PIM7_WrFIFO_Flush,
    PIM7_RdFIFO_Empty,
    PIM7_RdFIFO_Flush,
    PIM7_RdFIFO_Latency,
    PIM7_InitDone,
    PPC440MC7_MIMCReadNotWrite,
    PPC440MC7_MIMCAddress,
    PPC440MC7_MIMCAddressValid,
    PPC440MC7_MIMCWriteData,
    PPC440MC7_MIMCWriteDataValid,
    PPC440MC7_MIMCByteEnable,
    PPC440MC7_MIMCBankConflict,
    PPC440MC7_MIMCRowConflict,
    PPC440MC7_MCMIReadData,
    PPC440MC7_MCMIReadDataValid,
    PPC440MC7_MCMIReadDataErr,
    PPC440MC7_MCMIAddrReadyToAccept,
    VFBC7_Cmd_Clk,
    VFBC7_Cmd_Reset,
    VFBC7_Cmd_Data,
    VFBC7_Cmd_Write,
    VFBC7_Cmd_End,
    VFBC7_Cmd_Full,
    VFBC7_Cmd_Almost_Full,
    VFBC7_Cmd_Idle,
    VFBC7_Wd_Clk,
    VFBC7_Wd_Reset,
    VFBC7_Wd_Write,
    VFBC7_Wd_End_Burst,
    VFBC7_Wd_Flush,
    VFBC7_Wd_Data,
    VFBC7_Wd_Data_BE,
    VFBC7_Wd_Full,
    VFBC7_Wd_Almost_Full,
    VFBC7_Rd_Clk,
    VFBC7_Rd_Reset,
    VFBC7_Rd_Read,
    VFBC7_Rd_End_Burst,
    VFBC7_Rd_Flush,
    VFBC7_Rd_Data,
    VFBC7_Rd_Empty,
    VFBC7_Rd_Almost_Empty,
    MCB7_cmd_clk,
    MCB7_cmd_en,
    MCB7_cmd_instr,
    MCB7_cmd_bl,
    MCB7_cmd_byte_addr,
    MCB7_cmd_empty,
    MCB7_cmd_full,
    MCB7_wr_clk,
    MCB7_wr_en,
    MCB7_wr_mask,
    MCB7_wr_data,
    MCB7_wr_full,
    MCB7_wr_empty,
    MCB7_wr_count,
    MCB7_wr_underrun,
    MCB7_wr_error,
    MCB7_rd_clk,
    MCB7_rd_en,
    MCB7_rd_data,
    MCB7_rd_full,
    MCB7_rd_empty,
    MCB7_rd_count,
    MCB7_rd_overflow,
    MCB7_rd_error,
    MPMC_CTRL_Clk,
    MPMC_CTRL_Rst,
    MPMC_CTRL_PLB_ABus,
    MPMC_CTRL_PLB_PAValid,
    MPMC_CTRL_PLB_SAValid,
    MPMC_CTRL_PLB_masterID,
    MPMC_CTRL_PLB_RNW,
    MPMC_CTRL_PLB_BE,
    MPMC_CTRL_PLB_UABus,
    MPMC_CTRL_PLB_rdPrim,
    MPMC_CTRL_PLB_wrPrim,
    MPMC_CTRL_PLB_abort,
    MPMC_CTRL_PLB_busLock,
    MPMC_CTRL_PLB_MSize,
    MPMC_CTRL_PLB_size,
    MPMC_CTRL_PLB_type,
    MPMC_CTRL_PLB_lockErr,
    MPMC_CTRL_PLB_wrPendReq,
    MPMC_CTRL_PLB_wrPendPri,
    MPMC_CTRL_PLB_rdPendReq,
    MPMC_CTRL_PLB_rdPendPri,
    MPMC_CTRL_PLB_reqPri,
    MPMC_CTRL_PLB_TAttribute,
    MPMC_CTRL_PLB_rdBurst,
    MPMC_CTRL_PLB_wrBurst,
    MPMC_CTRL_PLB_wrDBus,
    MPMC_CTRL_Sl_addrAck,
    MPMC_CTRL_Sl_SSize,
    MPMC_CTRL_Sl_wait,
    MPMC_CTRL_Sl_rearbitrate,
    MPMC_CTRL_Sl_wrDAck,
    MPMC_CTRL_Sl_wrComp,
    MPMC_CTRL_Sl_wrBTerm,
    MPMC_CTRL_Sl_rdDBus,
    MPMC_CTRL_Sl_rdWdAddr,
    MPMC_CTRL_Sl_rdDAck,
    MPMC_CTRL_Sl_rdComp,
    MPMC_CTRL_Sl_rdBTerm,
    MPMC_CTRL_Sl_MBusy,
    MPMC_CTRL_Sl_MRdErr,
    MPMC_CTRL_Sl_MWrErr,
    MPMC_CTRL_Sl_MIRQ,
    MPMC_Clk0,
    MPMC_Clk0_DIV2,
    MPMC_Clk90,
    MPMC_Clk_200MHz,
    MPMC_Rst,
    MPMC_Clk_Mem,
    MPMC_Clk_Mem_2x,
    MPMC_Clk_Mem_2x_180,
    MPMC_Clk_Mem_2x_CE0,
    MPMC_Clk_Mem_2x_CE90,
    MPMC_Clk_Rd_Base,
    MPMC_Clk_Mem_2x_bufpll_o,
    MPMC_Clk_Mem_2x_180_bufpll_o,
    MPMC_Clk_Mem_2x_CE0_bufpll_o,
    MPMC_Clk_Mem_2x_CE90_bufpll_o,
    MPMC_PLL_Lock_bufpll_o,
    MPMC_PLL_Lock,
    MPMC_Idelayctrl_Rdy_I,
    MPMC_Idelayctrl_Rdy_O,
    MPMC_InitDone,
    MPMC_ECC_Intr,
    MPMC_DCM_PSEN,
    MPMC_DCM_PSINCDEC,
    MPMC_DCM_PSDONE,
    MPMC_MCB_DRP_Clk,
    SDRAM_Clk,
    SDRAM_CE,
    SDRAM_CS_n,
    SDRAM_RAS_n,
    SDRAM_CAS_n,
    SDRAM_WE_n,
    SDRAM_BankAddr,
    SDRAM_Addr,
    SDRAM_DQ,
    SDRAM_DM,
    DDR_Clk,
    DDR_Clk_n,
    DDR_CE,
    DDR_CS_n,
    DDR_RAS_n,
    DDR_CAS_n,
    DDR_WE_n,
    DDR_BankAddr,
    DDR_Addr,
    DDR_DQ,
    DDR_DM,
    DDR_DQS,
    DDR_DQS_Div_O,
    DDR_DQS_Div_I,
    DDR2_Clk,
    DDR2_Clk_n,
    DDR2_CE,
    DDR2_CS_n,
    DDR2_ODT,
    DDR2_RAS_n,
    DDR2_CAS_n,
    DDR2_WE_n,
    DDR2_BankAddr,
    DDR2_Addr,
    DDR2_DQ,
    DDR2_DM,
    DDR2_DQS,
    DDR2_DQS_n,
    DDR2_DQS_Div_O,
    DDR2_DQS_Div_I,
    DDR3_Clk,
    DDR3_Clk_n,
    DDR3_CE,
    DDR3_CS_n,
    DDR3_ODT,
    DDR3_RAS_n,
    DDR3_CAS_n,
    DDR3_WE_n,
    DDR3_BankAddr,
    DDR3_Addr,
    DDR3_DQ,
    DDR3_DM,
    DDR3_Reset_n,
    DDR3_DQS,
    DDR3_DQS_n,
    mcbx_dram_addr,
    mcbx_dram_ba,
    mcbx_dram_ras_n,
    mcbx_dram_cas_n,
    mcbx_dram_we_n,
    mcbx_dram_cke,
    mcbx_dram_clk,
    mcbx_dram_clk_n,
    mcbx_dram_dq,
    mcbx_dram_dqs,
    mcbx_dram_dqs_n,
    mcbx_dram_udqs,
    mcbx_dram_udqs_n,
    mcbx_dram_udm,
    mcbx_dram_ldm,
    mcbx_dram_odt,
    mcbx_dram_ddr3_rst,
    selfrefresh_enter,
    selfrefresh_mode,
    calib_recal,
    rzq,
    zio
  );
  input FSL0_M_Clk;
  input FSL0_M_Write;
  input [0:31] FSL0_M_Data;
  input FSL0_M_Control;
  output FSL0_M_Full;
  input FSL0_S_Clk;
  input FSL0_S_Read;
  output [0:31] FSL0_S_Data;
  output FSL0_S_Control;
  output FSL0_S_Exists;
  input FSL0_B_M_Clk;
  input FSL0_B_M_Write;
  input [0:31] FSL0_B_M_Data;
  input FSL0_B_M_Control;
  output FSL0_B_M_Full;
  input FSL0_B_S_Clk;
  input FSL0_B_S_Read;
  output [0:31] FSL0_B_S_Data;
  output FSL0_B_S_Control;
  output FSL0_B_S_Exists;
  input SPLB0_Clk;
  input SPLB0_Rst;
  input [0:31] SPLB0_PLB_ABus;
  input SPLB0_PLB_PAValid;
  input SPLB0_PLB_SAValid;
  input [0:0] SPLB0_PLB_masterID;
  input SPLB0_PLB_RNW;
  input [0:7] SPLB0_PLB_BE;
  input [0:31] SPLB0_PLB_UABus;
  input SPLB0_PLB_rdPrim;
  input SPLB0_PLB_wrPrim;
  input SPLB0_PLB_abort;
  input SPLB0_PLB_busLock;
  input [0:1] SPLB0_PLB_MSize;
  input [0:3] SPLB0_PLB_size;
  input [0:2] SPLB0_PLB_type;
  input SPLB0_PLB_lockErr;
  input SPLB0_PLB_wrPendReq;
  input [0:1] SPLB0_PLB_wrPendPri;
  input SPLB0_PLB_rdPendReq;
  input [0:1] SPLB0_PLB_rdPendPri;
  input [0:1] SPLB0_PLB_reqPri;
  input [0:15] SPLB0_PLB_TAttribute;
  input SPLB0_PLB_rdBurst;
  input SPLB0_PLB_wrBurst;
  input [0:63] SPLB0_PLB_wrDBus;
  output SPLB0_Sl_addrAck;
  output [0:1] SPLB0_Sl_SSize;
  output SPLB0_Sl_wait;
  output SPLB0_Sl_rearbitrate;
  output SPLB0_Sl_wrDAck;
  output SPLB0_Sl_wrComp;
  output SPLB0_Sl_wrBTerm;
  output [0:63] SPLB0_Sl_rdDBus;
  output [0:3] SPLB0_Sl_rdWdAddr;
  output SPLB0_Sl_rdDAck;
  output SPLB0_Sl_rdComp;
  output SPLB0_Sl_rdBTerm;
  output [0:0] SPLB0_Sl_MBusy;
  output [0:0] SPLB0_Sl_MRdErr;
  output [0:0] SPLB0_Sl_MWrErr;
  output [0:0] SPLB0_Sl_MIRQ;
  input SDMA0_Clk;
  output SDMA0_Rx_IntOut;
  output SDMA0_Tx_IntOut;
  output SDMA0_RstOut;
  output [0:31] SDMA0_TX_D;
  output [0:3] SDMA0_TX_Rem;
  output SDMA0_TX_SOF;
  output SDMA0_TX_EOF;
  output SDMA0_TX_SOP;
  output SDMA0_TX_EOP;
  output SDMA0_TX_Src_Rdy;
  input SDMA0_TX_Dst_Rdy;
  input [0:31] SDMA0_RX_D;
  input [0:3] SDMA0_RX_Rem;
  input SDMA0_RX_SOF;
  input SDMA0_RX_EOF;
  input SDMA0_RX_SOP;
  input SDMA0_RX_EOP;
  input SDMA0_RX_Src_Rdy;
  output SDMA0_RX_Dst_Rdy;
  input SDMA_CTRL0_Clk;
  input SDMA_CTRL0_Rst;
  input [0:31] SDMA_CTRL0_PLB_ABus;
  input SDMA_CTRL0_PLB_PAValid;
  input SDMA_CTRL0_PLB_SAValid;
  input [0:0] SDMA_CTRL0_PLB_masterID;
  input SDMA_CTRL0_PLB_RNW;
  input [0:7] SDMA_CTRL0_PLB_BE;
  input [0:31] SDMA_CTRL0_PLB_UABus;
  input SDMA_CTRL0_PLB_rdPrim;
  input SDMA_CTRL0_PLB_wrPrim;
  input SDMA_CTRL0_PLB_abort;
  input SDMA_CTRL0_PLB_busLock;
  input [0:1] SDMA_CTRL0_PLB_MSize;
  input [0:3] SDMA_CTRL0_PLB_size;
  input [0:2] SDMA_CTRL0_PLB_type;
  input SDMA_CTRL0_PLB_lockErr;
  input SDMA_CTRL0_PLB_wrPendReq;
  input [0:1] SDMA_CTRL0_PLB_wrPendPri;
  input SDMA_CTRL0_PLB_rdPendReq;
  input [0:1] SDMA_CTRL0_PLB_rdPendPri;
  input [0:1] SDMA_CTRL0_PLB_reqPri;
  input [0:15] SDMA_CTRL0_PLB_TAttribute;
  input SDMA_CTRL0_PLB_rdBurst;
  input SDMA_CTRL0_PLB_wrBurst;
  input [0:63] SDMA_CTRL0_PLB_wrDBus;
  output SDMA_CTRL0_Sl_addrAck;
  output [0:1] SDMA_CTRL0_Sl_SSize;
  output SDMA_CTRL0_Sl_wait;
  output SDMA_CTRL0_Sl_rearbitrate;
  output SDMA_CTRL0_Sl_wrDAck;
  output SDMA_CTRL0_Sl_wrComp;
  output SDMA_CTRL0_Sl_wrBTerm;
  output [0:63] SDMA_CTRL0_Sl_rdDBus;
  output [0:3] SDMA_CTRL0_Sl_rdWdAddr;
  output SDMA_CTRL0_Sl_rdDAck;
  output SDMA_CTRL0_Sl_rdComp;
  output SDMA_CTRL0_Sl_rdBTerm;
  output [0:0] SDMA_CTRL0_Sl_MBusy;
  output [0:0] SDMA_CTRL0_Sl_MRdErr;
  output [0:0] SDMA_CTRL0_Sl_MWrErr;
  output [0:0] SDMA_CTRL0_Sl_MIRQ;
  input [31:0] PIM0_Addr;
  input PIM0_AddrReq;
  output PIM0_AddrAck;
  input PIM0_RNW;
  input [3:0] PIM0_Size;
  input PIM0_RdModWr;
  input [63:0] PIM0_WrFIFO_Data;
  input [7:0] PIM0_WrFIFO_BE;
  input PIM0_WrFIFO_Push;
  output [63:0] PIM0_RdFIFO_Data;
  input PIM0_RdFIFO_Pop;
  output [3:0] PIM0_RdFIFO_RdWdAddr;
  output PIM0_WrFIFO_Empty;
  output PIM0_WrFIFO_AlmostFull;
  input PIM0_WrFIFO_Flush;
  output PIM0_RdFIFO_Empty;
  input PIM0_RdFIFO_Flush;
  output [1:0] PIM0_RdFIFO_Latency;
  output PIM0_InitDone;
  input PPC440MC0_MIMCReadNotWrite;
  input [0:35] PPC440MC0_MIMCAddress;
  input PPC440MC0_MIMCAddressValid;
  input [0:127] PPC440MC0_MIMCWriteData;
  input PPC440MC0_MIMCWriteDataValid;
  input [0:15] PPC440MC0_MIMCByteEnable;
  input PPC440MC0_MIMCBankConflict;
  input PPC440MC0_MIMCRowConflict;
  output [0:127] PPC440MC0_MCMIReadData;
  output PPC440MC0_MCMIReadDataValid;
  output PPC440MC0_MCMIReadDataErr;
  output PPC440MC0_MCMIAddrReadyToAccept;
  input VFBC0_Cmd_Clk;
  input VFBC0_Cmd_Reset;
  input [31:0] VFBC0_Cmd_Data;
  input VFBC0_Cmd_Write;
  input VFBC0_Cmd_End;
  output VFBC0_Cmd_Full;
  output VFBC0_Cmd_Almost_Full;
  output VFBC0_Cmd_Idle;
  input VFBC0_Wd_Clk;
  input VFBC0_Wd_Reset;
  input VFBC0_Wd_Write;
  input VFBC0_Wd_End_Burst;
  input VFBC0_Wd_Flush;
  input [31:0] VFBC0_Wd_Data;
  input [3:0] VFBC0_Wd_Data_BE;
  output VFBC0_Wd_Full;
  output VFBC0_Wd_Almost_Full;
  input VFBC0_Rd_Clk;
  input VFBC0_Rd_Reset;
  input VFBC0_Rd_Read;
  input VFBC0_Rd_End_Burst;
  input VFBC0_Rd_Flush;
  output [31:0] VFBC0_Rd_Data;
  output VFBC0_Rd_Empty;
  output VFBC0_Rd_Almost_Empty;
  input MCB0_cmd_clk;
  input MCB0_cmd_en;
  input [2:0] MCB0_cmd_instr;
  input [5:0] MCB0_cmd_bl;
  input [29:0] MCB0_cmd_byte_addr;
  output MCB0_cmd_empty;
  output MCB0_cmd_full;
  input MCB0_wr_clk;
  input MCB0_wr_en;
  input [7:0] MCB0_wr_mask;
  input [63:0] MCB0_wr_data;
  output MCB0_wr_full;
  output MCB0_wr_empty;
  output [6:0] MCB0_wr_count;
  output MCB0_wr_underrun;
  output MCB0_wr_error;
  input MCB0_rd_clk;
  input MCB0_rd_en;
  output [63:0] MCB0_rd_data;
  output MCB0_rd_full;
  output MCB0_rd_empty;
  output [6:0] MCB0_rd_count;
  output MCB0_rd_overflow;
  output MCB0_rd_error;
  input FSL1_M_Clk;
  input FSL1_M_Write;
  input [0:31] FSL1_M_Data;
  input FSL1_M_Control;
  output FSL1_M_Full;
  input FSL1_S_Clk;
  input FSL1_S_Read;
  output [0:31] FSL1_S_Data;
  output FSL1_S_Control;
  output FSL1_S_Exists;
  input FSL1_B_M_Clk;
  input FSL1_B_M_Write;
  input [0:31] FSL1_B_M_Data;
  input FSL1_B_M_Control;
  output FSL1_B_M_Full;
  input FSL1_B_S_Clk;
  input FSL1_B_S_Read;
  output [0:31] FSL1_B_S_Data;
  output FSL1_B_S_Control;
  output FSL1_B_S_Exists;
  input SPLB1_Clk;
  input SPLB1_Rst;
  input [0:31] SPLB1_PLB_ABus;
  input SPLB1_PLB_PAValid;
  input SPLB1_PLB_SAValid;
  input [0:0] SPLB1_PLB_masterID;
  input SPLB1_PLB_RNW;
  input [0:7] SPLB1_PLB_BE;
  input [0:31] SPLB1_PLB_UABus;
  input SPLB1_PLB_rdPrim;
  input SPLB1_PLB_wrPrim;
  input SPLB1_PLB_abort;
  input SPLB1_PLB_busLock;
  input [0:1] SPLB1_PLB_MSize;
  input [0:3] SPLB1_PLB_size;
  input [0:2] SPLB1_PLB_type;
  input SPLB1_PLB_lockErr;
  input SPLB1_PLB_wrPendReq;
  input [0:1] SPLB1_PLB_wrPendPri;
  input SPLB1_PLB_rdPendReq;
  input [0:1] SPLB1_PLB_rdPendPri;
  input [0:1] SPLB1_PLB_reqPri;
  input [0:15] SPLB1_PLB_TAttribute;
  input SPLB1_PLB_rdBurst;
  input SPLB1_PLB_wrBurst;
  input [0:63] SPLB1_PLB_wrDBus;
  output SPLB1_Sl_addrAck;
  output [0:1] SPLB1_Sl_SSize;
  output SPLB1_Sl_wait;
  output SPLB1_Sl_rearbitrate;
  output SPLB1_Sl_wrDAck;
  output SPLB1_Sl_wrComp;
  output SPLB1_Sl_wrBTerm;
  output [0:63] SPLB1_Sl_rdDBus;
  output [0:3] SPLB1_Sl_rdWdAddr;
  output SPLB1_Sl_rdDAck;
  output SPLB1_Sl_rdComp;
  output SPLB1_Sl_rdBTerm;
  output [0:0] SPLB1_Sl_MBusy;
  output [0:0] SPLB1_Sl_MRdErr;
  output [0:0] SPLB1_Sl_MWrErr;
  output [0:0] SPLB1_Sl_MIRQ;
  input SDMA1_Clk;
  output SDMA1_Rx_IntOut;
  output SDMA1_Tx_IntOut;
  output SDMA1_RstOut;
  output [0:31] SDMA1_TX_D;
  output [0:3] SDMA1_TX_Rem;
  output SDMA1_TX_SOF;
  output SDMA1_TX_EOF;
  output SDMA1_TX_SOP;
  output SDMA1_TX_EOP;
  output SDMA1_TX_Src_Rdy;
  input SDMA1_TX_Dst_Rdy;
  input [0:31] SDMA1_RX_D;
  input [0:3] SDMA1_RX_Rem;
  input SDMA1_RX_SOF;
  input SDMA1_RX_EOF;
  input SDMA1_RX_SOP;
  input SDMA1_RX_EOP;
  input SDMA1_RX_Src_Rdy;
  output SDMA1_RX_Dst_Rdy;
  input SDMA_CTRL1_Clk;
  input SDMA_CTRL1_Rst;
  input [0:31] SDMA_CTRL1_PLB_ABus;
  input SDMA_CTRL1_PLB_PAValid;
  input SDMA_CTRL1_PLB_SAValid;
  input [0:0] SDMA_CTRL1_PLB_masterID;
  input SDMA_CTRL1_PLB_RNW;
  input [0:7] SDMA_CTRL1_PLB_BE;
  input [0:31] SDMA_CTRL1_PLB_UABus;
  input SDMA_CTRL1_PLB_rdPrim;
  input SDMA_CTRL1_PLB_wrPrim;
  input SDMA_CTRL1_PLB_abort;
  input SDMA_CTRL1_PLB_busLock;
  input [0:1] SDMA_CTRL1_PLB_MSize;
  input [0:3] SDMA_CTRL1_PLB_size;
  input [0:2] SDMA_CTRL1_PLB_type;
  input SDMA_CTRL1_PLB_lockErr;
  input SDMA_CTRL1_PLB_wrPendReq;
  input [0:1] SDMA_CTRL1_PLB_wrPendPri;
  input SDMA_CTRL1_PLB_rdPendReq;
  input [0:1] SDMA_CTRL1_PLB_rdPendPri;
  input [0:1] SDMA_CTRL1_PLB_reqPri;
  input [0:15] SDMA_CTRL1_PLB_TAttribute;
  input SDMA_CTRL1_PLB_rdBurst;
  input SDMA_CTRL1_PLB_wrBurst;
  input [0:63] SDMA_CTRL1_PLB_wrDBus;
  output SDMA_CTRL1_Sl_addrAck;
  output [0:1] SDMA_CTRL1_Sl_SSize;
  output SDMA_CTRL1_Sl_wait;
  output SDMA_CTRL1_Sl_rearbitrate;
  output SDMA_CTRL1_Sl_wrDAck;
  output SDMA_CTRL1_Sl_wrComp;
  output SDMA_CTRL1_Sl_wrBTerm;
  output [0:63] SDMA_CTRL1_Sl_rdDBus;
  output [0:3] SDMA_CTRL1_Sl_rdWdAddr;
  output SDMA_CTRL1_Sl_rdDAck;
  output SDMA_CTRL1_Sl_rdComp;
  output SDMA_CTRL1_Sl_rdBTerm;
  output [0:0] SDMA_CTRL1_Sl_MBusy;
  output [0:0] SDMA_CTRL1_Sl_MRdErr;
  output [0:0] SDMA_CTRL1_Sl_MWrErr;
  output [0:0] SDMA_CTRL1_Sl_MIRQ;
  input [31:0] PIM1_Addr;
  input PIM1_AddrReq;
  output PIM1_AddrAck;
  input PIM1_RNW;
  input [3:0] PIM1_Size;
  input PIM1_RdModWr;
  input [63:0] PIM1_WrFIFO_Data;
  input [7:0] PIM1_WrFIFO_BE;
  input PIM1_WrFIFO_Push;
  output [63:0] PIM1_RdFIFO_Data;
  input PIM1_RdFIFO_Pop;
  output [3:0] PIM1_RdFIFO_RdWdAddr;
  output PIM1_WrFIFO_Empty;
  output PIM1_WrFIFO_AlmostFull;
  input PIM1_WrFIFO_Flush;
  output PIM1_RdFIFO_Empty;
  input PIM1_RdFIFO_Flush;
  output [1:0] PIM1_RdFIFO_Latency;
  output PIM1_InitDone;
  input PPC440MC1_MIMCReadNotWrite;
  input [0:35] PPC440MC1_MIMCAddress;
  input PPC440MC1_MIMCAddressValid;
  input [0:127] PPC440MC1_MIMCWriteData;
  input PPC440MC1_MIMCWriteDataValid;
  input [0:15] PPC440MC1_MIMCByteEnable;
  input PPC440MC1_MIMCBankConflict;
  input PPC440MC1_MIMCRowConflict;
  output [0:127] PPC440MC1_MCMIReadData;
  output PPC440MC1_MCMIReadDataValid;
  output PPC440MC1_MCMIReadDataErr;
  output PPC440MC1_MCMIAddrReadyToAccept;
  input VFBC1_Cmd_Clk;
  input VFBC1_Cmd_Reset;
  input [31:0] VFBC1_Cmd_Data;
  input VFBC1_Cmd_Write;
  input VFBC1_Cmd_End;
  output VFBC1_Cmd_Full;
  output VFBC1_Cmd_Almost_Full;
  output VFBC1_Cmd_Idle;
  input VFBC1_Wd_Clk;
  input VFBC1_Wd_Reset;
  input VFBC1_Wd_Write;
  input VFBC1_Wd_End_Burst;
  input VFBC1_Wd_Flush;
  input [31:0] VFBC1_Wd_Data;
  input [3:0] VFBC1_Wd_Data_BE;
  output VFBC1_Wd_Full;
  output VFBC1_Wd_Almost_Full;
  input VFBC1_Rd_Clk;
  input VFBC1_Rd_Reset;
  input VFBC1_Rd_Read;
  input VFBC1_Rd_End_Burst;
  input VFBC1_Rd_Flush;
  output [31:0] VFBC1_Rd_Data;
  output VFBC1_Rd_Empty;
  output VFBC1_Rd_Almost_Empty;
  input MCB1_cmd_clk;
  input MCB1_cmd_en;
  input [2:0] MCB1_cmd_instr;
  input [5:0] MCB1_cmd_bl;
  input [29:0] MCB1_cmd_byte_addr;
  output MCB1_cmd_empty;
  output MCB1_cmd_full;
  input MCB1_wr_clk;
  input MCB1_wr_en;
  input [7:0] MCB1_wr_mask;
  input [63:0] MCB1_wr_data;
  output MCB1_wr_full;
  output MCB1_wr_empty;
  output [6:0] MCB1_wr_count;
  output MCB1_wr_underrun;
  output MCB1_wr_error;
  input MCB1_rd_clk;
  input MCB1_rd_en;
  output [63:0] MCB1_rd_data;
  output MCB1_rd_full;
  output MCB1_rd_empty;
  output [6:0] MCB1_rd_count;
  output MCB1_rd_overflow;
  output MCB1_rd_error;
  input FSL2_M_Clk;
  input FSL2_M_Write;
  input [0:31] FSL2_M_Data;
  input FSL2_M_Control;
  output FSL2_M_Full;
  input FSL2_S_Clk;
  input FSL2_S_Read;
  output [0:31] FSL2_S_Data;
  output FSL2_S_Control;
  output FSL2_S_Exists;
  input FSL2_B_M_Clk;
  input FSL2_B_M_Write;
  input [0:31] FSL2_B_M_Data;
  input FSL2_B_M_Control;
  output FSL2_B_M_Full;
  input FSL2_B_S_Clk;
  input FSL2_B_S_Read;
  output [0:31] FSL2_B_S_Data;
  output FSL2_B_S_Control;
  output FSL2_B_S_Exists;
  input SPLB2_Clk;
  input SPLB2_Rst;
  input [0:31] SPLB2_PLB_ABus;
  input SPLB2_PLB_PAValid;
  input SPLB2_PLB_SAValid;
  input [0:0] SPLB2_PLB_masterID;
  input SPLB2_PLB_RNW;
  input [0:7] SPLB2_PLB_BE;
  input [0:31] SPLB2_PLB_UABus;
  input SPLB2_PLB_rdPrim;
  input SPLB2_PLB_wrPrim;
  input SPLB2_PLB_abort;
  input SPLB2_PLB_busLock;
  input [0:1] SPLB2_PLB_MSize;
  input [0:3] SPLB2_PLB_size;
  input [0:2] SPLB2_PLB_type;
  input SPLB2_PLB_lockErr;
  input SPLB2_PLB_wrPendReq;
  input [0:1] SPLB2_PLB_wrPendPri;
  input SPLB2_PLB_rdPendReq;
  input [0:1] SPLB2_PLB_rdPendPri;
  input [0:1] SPLB2_PLB_reqPri;
  input [0:15] SPLB2_PLB_TAttribute;
  input SPLB2_PLB_rdBurst;
  input SPLB2_PLB_wrBurst;
  input [0:63] SPLB2_PLB_wrDBus;
  output SPLB2_Sl_addrAck;
  output [0:1] SPLB2_Sl_SSize;
  output SPLB2_Sl_wait;
  output SPLB2_Sl_rearbitrate;
  output SPLB2_Sl_wrDAck;
  output SPLB2_Sl_wrComp;
  output SPLB2_Sl_wrBTerm;
  output [0:63] SPLB2_Sl_rdDBus;
  output [0:3] SPLB2_Sl_rdWdAddr;
  output SPLB2_Sl_rdDAck;
  output SPLB2_Sl_rdComp;
  output SPLB2_Sl_rdBTerm;
  output [0:0] SPLB2_Sl_MBusy;
  output [0:0] SPLB2_Sl_MRdErr;
  output [0:0] SPLB2_Sl_MWrErr;
  output [0:0] SPLB2_Sl_MIRQ;
  input SDMA2_Clk;
  output SDMA2_Rx_IntOut;
  output SDMA2_Tx_IntOut;
  output SDMA2_RstOut;
  output [0:31] SDMA2_TX_D;
  output [0:3] SDMA2_TX_Rem;
  output SDMA2_TX_SOF;
  output SDMA2_TX_EOF;
  output SDMA2_TX_SOP;
  output SDMA2_TX_EOP;
  output SDMA2_TX_Src_Rdy;
  input SDMA2_TX_Dst_Rdy;
  input [0:31] SDMA2_RX_D;
  input [0:3] SDMA2_RX_Rem;
  input SDMA2_RX_SOF;
  input SDMA2_RX_EOF;
  input SDMA2_RX_SOP;
  input SDMA2_RX_EOP;
  input SDMA2_RX_Src_Rdy;
  output SDMA2_RX_Dst_Rdy;
  input SDMA_CTRL2_Clk;
  input SDMA_CTRL2_Rst;
  input [0:31] SDMA_CTRL2_PLB_ABus;
  input SDMA_CTRL2_PLB_PAValid;
  input SDMA_CTRL2_PLB_SAValid;
  input [0:0] SDMA_CTRL2_PLB_masterID;
  input SDMA_CTRL2_PLB_RNW;
  input [0:7] SDMA_CTRL2_PLB_BE;
  input [0:31] SDMA_CTRL2_PLB_UABus;
  input SDMA_CTRL2_PLB_rdPrim;
  input SDMA_CTRL2_PLB_wrPrim;
  input SDMA_CTRL2_PLB_abort;
  input SDMA_CTRL2_PLB_busLock;
  input [0:1] SDMA_CTRL2_PLB_MSize;
  input [0:3] SDMA_CTRL2_PLB_size;
  input [0:2] SDMA_CTRL2_PLB_type;
  input SDMA_CTRL2_PLB_lockErr;
  input SDMA_CTRL2_PLB_wrPendReq;
  input [0:1] SDMA_CTRL2_PLB_wrPendPri;
  input SDMA_CTRL2_PLB_rdPendReq;
  input [0:1] SDMA_CTRL2_PLB_rdPendPri;
  input [0:1] SDMA_CTRL2_PLB_reqPri;
  input [0:15] SDMA_CTRL2_PLB_TAttribute;
  input SDMA_CTRL2_PLB_rdBurst;
  input SDMA_CTRL2_PLB_wrBurst;
  input [0:63] SDMA_CTRL2_PLB_wrDBus;
  output SDMA_CTRL2_Sl_addrAck;
  output [0:1] SDMA_CTRL2_Sl_SSize;
  output SDMA_CTRL2_Sl_wait;
  output SDMA_CTRL2_Sl_rearbitrate;
  output SDMA_CTRL2_Sl_wrDAck;
  output SDMA_CTRL2_Sl_wrComp;
  output SDMA_CTRL2_Sl_wrBTerm;
  output [0:63] SDMA_CTRL2_Sl_rdDBus;
  output [0:3] SDMA_CTRL2_Sl_rdWdAddr;
  output SDMA_CTRL2_Sl_rdDAck;
  output SDMA_CTRL2_Sl_rdComp;
  output SDMA_CTRL2_Sl_rdBTerm;
  output [0:0] SDMA_CTRL2_Sl_MBusy;
  output [0:0] SDMA_CTRL2_Sl_MRdErr;
  output [0:0] SDMA_CTRL2_Sl_MWrErr;
  output [0:0] SDMA_CTRL2_Sl_MIRQ;
  input [31:0] PIM2_Addr;
  input PIM2_AddrReq;
  output PIM2_AddrAck;
  input PIM2_RNW;
  input [3:0] PIM2_Size;
  input PIM2_RdModWr;
  input [63:0] PIM2_WrFIFO_Data;
  input [7:0] PIM2_WrFIFO_BE;
  input PIM2_WrFIFO_Push;
  output [63:0] PIM2_RdFIFO_Data;
  input PIM2_RdFIFO_Pop;
  output [3:0] PIM2_RdFIFO_RdWdAddr;
  output PIM2_WrFIFO_Empty;
  output PIM2_WrFIFO_AlmostFull;
  input PIM2_WrFIFO_Flush;
  output PIM2_RdFIFO_Empty;
  input PIM2_RdFIFO_Flush;
  output [1:0] PIM2_RdFIFO_Latency;
  output PIM2_InitDone;
  input PPC440MC2_MIMCReadNotWrite;
  input [0:35] PPC440MC2_MIMCAddress;
  input PPC440MC2_MIMCAddressValid;
  input [0:127] PPC440MC2_MIMCWriteData;
  input PPC440MC2_MIMCWriteDataValid;
  input [0:15] PPC440MC2_MIMCByteEnable;
  input PPC440MC2_MIMCBankConflict;
  input PPC440MC2_MIMCRowConflict;
  output [0:127] PPC440MC2_MCMIReadData;
  output PPC440MC2_MCMIReadDataValid;
  output PPC440MC2_MCMIReadDataErr;
  output PPC440MC2_MCMIAddrReadyToAccept;
  input VFBC2_Cmd_Clk;
  input VFBC2_Cmd_Reset;
  input [31:0] VFBC2_Cmd_Data;
  input VFBC2_Cmd_Write;
  input VFBC2_Cmd_End;
  output VFBC2_Cmd_Full;
  output VFBC2_Cmd_Almost_Full;
  output VFBC2_Cmd_Idle;
  input VFBC2_Wd_Clk;
  input VFBC2_Wd_Reset;
  input VFBC2_Wd_Write;
  input VFBC2_Wd_End_Burst;
  input VFBC2_Wd_Flush;
  input [31:0] VFBC2_Wd_Data;
  input [3:0] VFBC2_Wd_Data_BE;
  output VFBC2_Wd_Full;
  output VFBC2_Wd_Almost_Full;
  input VFBC2_Rd_Clk;
  input VFBC2_Rd_Reset;
  input VFBC2_Rd_Read;
  input VFBC2_Rd_End_Burst;
  input VFBC2_Rd_Flush;
  output [31:0] VFBC2_Rd_Data;
  output VFBC2_Rd_Empty;
  output VFBC2_Rd_Almost_Empty;
  input MCB2_cmd_clk;
  input MCB2_cmd_en;
  input [2:0] MCB2_cmd_instr;
  input [5:0] MCB2_cmd_bl;
  input [29:0] MCB2_cmd_byte_addr;
  output MCB2_cmd_empty;
  output MCB2_cmd_full;
  input MCB2_wr_clk;
  input MCB2_wr_en;
  input [7:0] MCB2_wr_mask;
  input [63:0] MCB2_wr_data;
  output MCB2_wr_full;
  output MCB2_wr_empty;
  output [6:0] MCB2_wr_count;
  output MCB2_wr_underrun;
  output MCB2_wr_error;
  input MCB2_rd_clk;
  input MCB2_rd_en;
  output [63:0] MCB2_rd_data;
  output MCB2_rd_full;
  output MCB2_rd_empty;
  output [6:0] MCB2_rd_count;
  output MCB2_rd_overflow;
  output MCB2_rd_error;
  input FSL3_M_Clk;
  input FSL3_M_Write;
  input [0:31] FSL3_M_Data;
  input FSL3_M_Control;
  output FSL3_M_Full;
  input FSL3_S_Clk;
  input FSL3_S_Read;
  output [0:31] FSL3_S_Data;
  output FSL3_S_Control;
  output FSL3_S_Exists;
  input FSL3_B_M_Clk;
  input FSL3_B_M_Write;
  input [0:31] FSL3_B_M_Data;
  input FSL3_B_M_Control;
  output FSL3_B_M_Full;
  input FSL3_B_S_Clk;
  input FSL3_B_S_Read;
  output [0:31] FSL3_B_S_Data;
  output FSL3_B_S_Control;
  output FSL3_B_S_Exists;
  input SPLB3_Clk;
  input SPLB3_Rst;
  input [0:31] SPLB3_PLB_ABus;
  input SPLB3_PLB_PAValid;
  input SPLB3_PLB_SAValid;
  input [0:0] SPLB3_PLB_masterID;
  input SPLB3_PLB_RNW;
  input [0:7] SPLB3_PLB_BE;
  input [0:31] SPLB3_PLB_UABus;
  input SPLB3_PLB_rdPrim;
  input SPLB3_PLB_wrPrim;
  input SPLB3_PLB_abort;
  input SPLB3_PLB_busLock;
  input [0:1] SPLB3_PLB_MSize;
  input [0:3] SPLB3_PLB_size;
  input [0:2] SPLB3_PLB_type;
  input SPLB3_PLB_lockErr;
  input SPLB3_PLB_wrPendReq;
  input [0:1] SPLB3_PLB_wrPendPri;
  input SPLB3_PLB_rdPendReq;
  input [0:1] SPLB3_PLB_rdPendPri;
  input [0:1] SPLB3_PLB_reqPri;
  input [0:15] SPLB3_PLB_TAttribute;
  input SPLB3_PLB_rdBurst;
  input SPLB3_PLB_wrBurst;
  input [0:63] SPLB3_PLB_wrDBus;
  output SPLB3_Sl_addrAck;
  output [0:1] SPLB3_Sl_SSize;
  output SPLB3_Sl_wait;
  output SPLB3_Sl_rearbitrate;
  output SPLB3_Sl_wrDAck;
  output SPLB3_Sl_wrComp;
  output SPLB3_Sl_wrBTerm;
  output [0:63] SPLB3_Sl_rdDBus;
  output [0:3] SPLB3_Sl_rdWdAddr;
  output SPLB3_Sl_rdDAck;
  output SPLB3_Sl_rdComp;
  output SPLB3_Sl_rdBTerm;
  output [0:0] SPLB3_Sl_MBusy;
  output [0:0] SPLB3_Sl_MRdErr;
  output [0:0] SPLB3_Sl_MWrErr;
  output [0:0] SPLB3_Sl_MIRQ;
  input SDMA3_Clk;
  output SDMA3_Rx_IntOut;
  output SDMA3_Tx_IntOut;
  output SDMA3_RstOut;
  output [0:31] SDMA3_TX_D;
  output [0:3] SDMA3_TX_Rem;
  output SDMA3_TX_SOF;
  output SDMA3_TX_EOF;
  output SDMA3_TX_SOP;
  output SDMA3_TX_EOP;
  output SDMA3_TX_Src_Rdy;
  input SDMA3_TX_Dst_Rdy;
  input [0:31] SDMA3_RX_D;
  input [0:3] SDMA3_RX_Rem;
  input SDMA3_RX_SOF;
  input SDMA3_RX_EOF;
  input SDMA3_RX_SOP;
  input SDMA3_RX_EOP;
  input SDMA3_RX_Src_Rdy;
  output SDMA3_RX_Dst_Rdy;
  input SDMA_CTRL3_Clk;
  input SDMA_CTRL3_Rst;
  input [0:31] SDMA_CTRL3_PLB_ABus;
  input SDMA_CTRL3_PLB_PAValid;
  input SDMA_CTRL3_PLB_SAValid;
  input [0:0] SDMA_CTRL3_PLB_masterID;
  input SDMA_CTRL3_PLB_RNW;
  input [0:7] SDMA_CTRL3_PLB_BE;
  input [0:31] SDMA_CTRL3_PLB_UABus;
  input SDMA_CTRL3_PLB_rdPrim;
  input SDMA_CTRL3_PLB_wrPrim;
  input SDMA_CTRL3_PLB_abort;
  input SDMA_CTRL3_PLB_busLock;
  input [0:1] SDMA_CTRL3_PLB_MSize;
  input [0:3] SDMA_CTRL3_PLB_size;
  input [0:2] SDMA_CTRL3_PLB_type;
  input SDMA_CTRL3_PLB_lockErr;
  input SDMA_CTRL3_PLB_wrPendReq;
  input [0:1] SDMA_CTRL3_PLB_wrPendPri;
  input SDMA_CTRL3_PLB_rdPendReq;
  input [0:1] SDMA_CTRL3_PLB_rdPendPri;
  input [0:1] SDMA_CTRL3_PLB_reqPri;
  input [0:15] SDMA_CTRL3_PLB_TAttribute;
  input SDMA_CTRL3_PLB_rdBurst;
  input SDMA_CTRL3_PLB_wrBurst;
  input [0:63] SDMA_CTRL3_PLB_wrDBus;
  output SDMA_CTRL3_Sl_addrAck;
  output [0:1] SDMA_CTRL3_Sl_SSize;
  output SDMA_CTRL3_Sl_wait;
  output SDMA_CTRL3_Sl_rearbitrate;
  output SDMA_CTRL3_Sl_wrDAck;
  output SDMA_CTRL3_Sl_wrComp;
  output SDMA_CTRL3_Sl_wrBTerm;
  output [0:63] SDMA_CTRL3_Sl_rdDBus;
  output [0:3] SDMA_CTRL3_Sl_rdWdAddr;
  output SDMA_CTRL3_Sl_rdDAck;
  output SDMA_CTRL3_Sl_rdComp;
  output SDMA_CTRL3_Sl_rdBTerm;
  output [0:0] SDMA_CTRL3_Sl_MBusy;
  output [0:0] SDMA_CTRL3_Sl_MRdErr;
  output [0:0] SDMA_CTRL3_Sl_MWrErr;
  output [0:0] SDMA_CTRL3_Sl_MIRQ;
  input [31:0] PIM3_Addr;
  input PIM3_AddrReq;
  output PIM3_AddrAck;
  input PIM3_RNW;
  input [3:0] PIM3_Size;
  input PIM3_RdModWr;
  input [63:0] PIM3_WrFIFO_Data;
  input [7:0] PIM3_WrFIFO_BE;
  input PIM3_WrFIFO_Push;
  output [63:0] PIM3_RdFIFO_Data;
  input PIM3_RdFIFO_Pop;
  output [3:0] PIM3_RdFIFO_RdWdAddr;
  output PIM3_WrFIFO_Empty;
  output PIM3_WrFIFO_AlmostFull;
  input PIM3_WrFIFO_Flush;
  output PIM3_RdFIFO_Empty;
  input PIM3_RdFIFO_Flush;
  output [1:0] PIM3_RdFIFO_Latency;
  output PIM3_InitDone;
  input PPC440MC3_MIMCReadNotWrite;
  input [0:35] PPC440MC3_MIMCAddress;
  input PPC440MC3_MIMCAddressValid;
  input [0:127] PPC440MC3_MIMCWriteData;
  input PPC440MC3_MIMCWriteDataValid;
  input [0:15] PPC440MC3_MIMCByteEnable;
  input PPC440MC3_MIMCBankConflict;
  input PPC440MC3_MIMCRowConflict;
  output [0:127] PPC440MC3_MCMIReadData;
  output PPC440MC3_MCMIReadDataValid;
  output PPC440MC3_MCMIReadDataErr;
  output PPC440MC3_MCMIAddrReadyToAccept;
  input VFBC3_Cmd_Clk;
  input VFBC3_Cmd_Reset;
  input [31:0] VFBC3_Cmd_Data;
  input VFBC3_Cmd_Write;
  input VFBC3_Cmd_End;
  output VFBC3_Cmd_Full;
  output VFBC3_Cmd_Almost_Full;
  output VFBC3_Cmd_Idle;
  input VFBC3_Wd_Clk;
  input VFBC3_Wd_Reset;
  input VFBC3_Wd_Write;
  input VFBC3_Wd_End_Burst;
  input VFBC3_Wd_Flush;
  input [31:0] VFBC3_Wd_Data;
  input [3:0] VFBC3_Wd_Data_BE;
  output VFBC3_Wd_Full;
  output VFBC3_Wd_Almost_Full;
  input VFBC3_Rd_Clk;
  input VFBC3_Rd_Reset;
  input VFBC3_Rd_Read;
  input VFBC3_Rd_End_Burst;
  input VFBC3_Rd_Flush;
  output [31:0] VFBC3_Rd_Data;
  output VFBC3_Rd_Empty;
  output VFBC3_Rd_Almost_Empty;
  input MCB3_cmd_clk;
  input MCB3_cmd_en;
  input [2:0] MCB3_cmd_instr;
  input [5:0] MCB3_cmd_bl;
  input [29:0] MCB3_cmd_byte_addr;
  output MCB3_cmd_empty;
  output MCB3_cmd_full;
  input MCB3_wr_clk;
  input MCB3_wr_en;
  input [7:0] MCB3_wr_mask;
  input [63:0] MCB3_wr_data;
  output MCB3_wr_full;
  output MCB3_wr_empty;
  output [6:0] MCB3_wr_count;
  output MCB3_wr_underrun;
  output MCB3_wr_error;
  input MCB3_rd_clk;
  input MCB3_rd_en;
  output [63:0] MCB3_rd_data;
  output MCB3_rd_full;
  output MCB3_rd_empty;
  output [6:0] MCB3_rd_count;
  output MCB3_rd_overflow;
  output MCB3_rd_error;
  input FSL4_M_Clk;
  input FSL4_M_Write;
  input [0:31] FSL4_M_Data;
  input FSL4_M_Control;
  output FSL4_M_Full;
  input FSL4_S_Clk;
  input FSL4_S_Read;
  output [0:31] FSL4_S_Data;
  output FSL4_S_Control;
  output FSL4_S_Exists;
  input FSL4_B_M_Clk;
  input FSL4_B_M_Write;
  input [0:31] FSL4_B_M_Data;
  input FSL4_B_M_Control;
  output FSL4_B_M_Full;
  input FSL4_B_S_Clk;
  input FSL4_B_S_Read;
  output [0:31] FSL4_B_S_Data;
  output FSL4_B_S_Control;
  output FSL4_B_S_Exists;
  input SPLB4_Clk;
  input SPLB4_Rst;
  input [0:31] SPLB4_PLB_ABus;
  input SPLB4_PLB_PAValid;
  input SPLB4_PLB_SAValid;
  input [0:0] SPLB4_PLB_masterID;
  input SPLB4_PLB_RNW;
  input [0:7] SPLB4_PLB_BE;
  input [0:31] SPLB4_PLB_UABus;
  input SPLB4_PLB_rdPrim;
  input SPLB4_PLB_wrPrim;
  input SPLB4_PLB_abort;
  input SPLB4_PLB_busLock;
  input [0:1] SPLB4_PLB_MSize;
  input [0:3] SPLB4_PLB_size;
  input [0:2] SPLB4_PLB_type;
  input SPLB4_PLB_lockErr;
  input SPLB4_PLB_wrPendReq;
  input [0:1] SPLB4_PLB_wrPendPri;
  input SPLB4_PLB_rdPendReq;
  input [0:1] SPLB4_PLB_rdPendPri;
  input [0:1] SPLB4_PLB_reqPri;
  input [0:15] SPLB4_PLB_TAttribute;
  input SPLB4_PLB_rdBurst;
  input SPLB4_PLB_wrBurst;
  input [0:63] SPLB4_PLB_wrDBus;
  output SPLB4_Sl_addrAck;
  output [0:1] SPLB4_Sl_SSize;
  output SPLB4_Sl_wait;
  output SPLB4_Sl_rearbitrate;
  output SPLB4_Sl_wrDAck;
  output SPLB4_Sl_wrComp;
  output SPLB4_Sl_wrBTerm;
  output [0:63] SPLB4_Sl_rdDBus;
  output [0:3] SPLB4_Sl_rdWdAddr;
  output SPLB4_Sl_rdDAck;
  output SPLB4_Sl_rdComp;
  output SPLB4_Sl_rdBTerm;
  output [0:0] SPLB4_Sl_MBusy;
  output [0:0] SPLB4_Sl_MRdErr;
  output [0:0] SPLB4_Sl_MWrErr;
  output [0:0] SPLB4_Sl_MIRQ;
  input SDMA4_Clk;
  output SDMA4_Rx_IntOut;
  output SDMA4_Tx_IntOut;
  output SDMA4_RstOut;
  output [0:31] SDMA4_TX_D;
  output [0:3] SDMA4_TX_Rem;
  output SDMA4_TX_SOF;
  output SDMA4_TX_EOF;
  output SDMA4_TX_SOP;
  output SDMA4_TX_EOP;
  output SDMA4_TX_Src_Rdy;
  input SDMA4_TX_Dst_Rdy;
  input [0:31] SDMA4_RX_D;
  input [0:3] SDMA4_RX_Rem;
  input SDMA4_RX_SOF;
  input SDMA4_RX_EOF;
  input SDMA4_RX_SOP;
  input SDMA4_RX_EOP;
  input SDMA4_RX_Src_Rdy;
  output SDMA4_RX_Dst_Rdy;
  input SDMA_CTRL4_Clk;
  input SDMA_CTRL4_Rst;
  input [0:31] SDMA_CTRL4_PLB_ABus;
  input SDMA_CTRL4_PLB_PAValid;
  input SDMA_CTRL4_PLB_SAValid;
  input [0:0] SDMA_CTRL4_PLB_masterID;
  input SDMA_CTRL4_PLB_RNW;
  input [0:7] SDMA_CTRL4_PLB_BE;
  input [0:31] SDMA_CTRL4_PLB_UABus;
  input SDMA_CTRL4_PLB_rdPrim;
  input SDMA_CTRL4_PLB_wrPrim;
  input SDMA_CTRL4_PLB_abort;
  input SDMA_CTRL4_PLB_busLock;
  input [0:1] SDMA_CTRL4_PLB_MSize;
  input [0:3] SDMA_CTRL4_PLB_size;
  input [0:2] SDMA_CTRL4_PLB_type;
  input SDMA_CTRL4_PLB_lockErr;
  input SDMA_CTRL4_PLB_wrPendReq;
  input [0:1] SDMA_CTRL4_PLB_wrPendPri;
  input SDMA_CTRL4_PLB_rdPendReq;
  input [0:1] SDMA_CTRL4_PLB_rdPendPri;
  input [0:1] SDMA_CTRL4_PLB_reqPri;
  input [0:15] SDMA_CTRL4_PLB_TAttribute;
  input SDMA_CTRL4_PLB_rdBurst;
  input SDMA_CTRL4_PLB_wrBurst;
  input [0:63] SDMA_CTRL4_PLB_wrDBus;
  output SDMA_CTRL4_Sl_addrAck;
  output [0:1] SDMA_CTRL4_Sl_SSize;
  output SDMA_CTRL4_Sl_wait;
  output SDMA_CTRL4_Sl_rearbitrate;
  output SDMA_CTRL4_Sl_wrDAck;
  output SDMA_CTRL4_Sl_wrComp;
  output SDMA_CTRL4_Sl_wrBTerm;
  output [0:63] SDMA_CTRL4_Sl_rdDBus;
  output [0:3] SDMA_CTRL4_Sl_rdWdAddr;
  output SDMA_CTRL4_Sl_rdDAck;
  output SDMA_CTRL4_Sl_rdComp;
  output SDMA_CTRL4_Sl_rdBTerm;
  output [0:0] SDMA_CTRL4_Sl_MBusy;
  output [0:0] SDMA_CTRL4_Sl_MRdErr;
  output [0:0] SDMA_CTRL4_Sl_MWrErr;
  output [0:0] SDMA_CTRL4_Sl_MIRQ;
  input [31:0] PIM4_Addr;
  input PIM4_AddrReq;
  output PIM4_AddrAck;
  input PIM4_RNW;
  input [3:0] PIM4_Size;
  input PIM4_RdModWr;
  input [63:0] PIM4_WrFIFO_Data;
  input [7:0] PIM4_WrFIFO_BE;
  input PIM4_WrFIFO_Push;
  output [63:0] PIM4_RdFIFO_Data;
  input PIM4_RdFIFO_Pop;
  output [3:0] PIM4_RdFIFO_RdWdAddr;
  output PIM4_WrFIFO_Empty;
  output PIM4_WrFIFO_AlmostFull;
  input PIM4_WrFIFO_Flush;
  output PIM4_RdFIFO_Empty;
  input PIM4_RdFIFO_Flush;
  output [1:0] PIM4_RdFIFO_Latency;
  output PIM4_InitDone;
  input PPC440MC4_MIMCReadNotWrite;
  input [0:35] PPC440MC4_MIMCAddress;
  input PPC440MC4_MIMCAddressValid;
  input [0:127] PPC440MC4_MIMCWriteData;
  input PPC440MC4_MIMCWriteDataValid;
  input [0:15] PPC440MC4_MIMCByteEnable;
  input PPC440MC4_MIMCBankConflict;
  input PPC440MC4_MIMCRowConflict;
  output [0:127] PPC440MC4_MCMIReadData;
  output PPC440MC4_MCMIReadDataValid;
  output PPC440MC4_MCMIReadDataErr;
  output PPC440MC4_MCMIAddrReadyToAccept;
  input VFBC4_Cmd_Clk;
  input VFBC4_Cmd_Reset;
  input [31:0] VFBC4_Cmd_Data;
  input VFBC4_Cmd_Write;
  input VFBC4_Cmd_End;
  output VFBC4_Cmd_Full;
  output VFBC4_Cmd_Almost_Full;
  output VFBC4_Cmd_Idle;
  input VFBC4_Wd_Clk;
  input VFBC4_Wd_Reset;
  input VFBC4_Wd_Write;
  input VFBC4_Wd_End_Burst;
  input VFBC4_Wd_Flush;
  input [31:0] VFBC4_Wd_Data;
  input [3:0] VFBC4_Wd_Data_BE;
  output VFBC4_Wd_Full;
  output VFBC4_Wd_Almost_Full;
  input VFBC4_Rd_Clk;
  input VFBC4_Rd_Reset;
  input VFBC4_Rd_Read;
  input VFBC4_Rd_End_Burst;
  input VFBC4_Rd_Flush;
  output [31:0] VFBC4_Rd_Data;
  output VFBC4_Rd_Empty;
  output VFBC4_Rd_Almost_Empty;
  input MCB4_cmd_clk;
  input MCB4_cmd_en;
  input [2:0] MCB4_cmd_instr;
  input [5:0] MCB4_cmd_bl;
  input [29:0] MCB4_cmd_byte_addr;
  output MCB4_cmd_empty;
  output MCB4_cmd_full;
  input MCB4_wr_clk;
  input MCB4_wr_en;
  input [7:0] MCB4_wr_mask;
  input [63:0] MCB4_wr_data;
  output MCB4_wr_full;
  output MCB4_wr_empty;
  output [6:0] MCB4_wr_count;
  output MCB4_wr_underrun;
  output MCB4_wr_error;
  input MCB4_rd_clk;
  input MCB4_rd_en;
  output [63:0] MCB4_rd_data;
  output MCB4_rd_full;
  output MCB4_rd_empty;
  output [6:0] MCB4_rd_count;
  output MCB4_rd_overflow;
  output MCB4_rd_error;
  input FSL5_M_Clk;
  input FSL5_M_Write;
  input [0:31] FSL5_M_Data;
  input FSL5_M_Control;
  output FSL5_M_Full;
  input FSL5_S_Clk;
  input FSL5_S_Read;
  output [0:31] FSL5_S_Data;
  output FSL5_S_Control;
  output FSL5_S_Exists;
  input FSL5_B_M_Clk;
  input FSL5_B_M_Write;
  input [0:31] FSL5_B_M_Data;
  input FSL5_B_M_Control;
  output FSL5_B_M_Full;
  input FSL5_B_S_Clk;
  input FSL5_B_S_Read;
  output [0:31] FSL5_B_S_Data;
  output FSL5_B_S_Control;
  output FSL5_B_S_Exists;
  input SPLB5_Clk;
  input SPLB5_Rst;
  input [0:31] SPLB5_PLB_ABus;
  input SPLB5_PLB_PAValid;
  input SPLB5_PLB_SAValid;
  input [0:0] SPLB5_PLB_masterID;
  input SPLB5_PLB_RNW;
  input [0:7] SPLB5_PLB_BE;
  input [0:31] SPLB5_PLB_UABus;
  input SPLB5_PLB_rdPrim;
  input SPLB5_PLB_wrPrim;
  input SPLB5_PLB_abort;
  input SPLB5_PLB_busLock;
  input [0:1] SPLB5_PLB_MSize;
  input [0:3] SPLB5_PLB_size;
  input [0:2] SPLB5_PLB_type;
  input SPLB5_PLB_lockErr;
  input SPLB5_PLB_wrPendReq;
  input [0:1] SPLB5_PLB_wrPendPri;
  input SPLB5_PLB_rdPendReq;
  input [0:1] SPLB5_PLB_rdPendPri;
  input [0:1] SPLB5_PLB_reqPri;
  input [0:15] SPLB5_PLB_TAttribute;
  input SPLB5_PLB_rdBurst;
  input SPLB5_PLB_wrBurst;
  input [0:63] SPLB5_PLB_wrDBus;
  output SPLB5_Sl_addrAck;
  output [0:1] SPLB5_Sl_SSize;
  output SPLB5_Sl_wait;
  output SPLB5_Sl_rearbitrate;
  output SPLB5_Sl_wrDAck;
  output SPLB5_Sl_wrComp;
  output SPLB5_Sl_wrBTerm;
  output [0:63] SPLB5_Sl_rdDBus;
  output [0:3] SPLB5_Sl_rdWdAddr;
  output SPLB5_Sl_rdDAck;
  output SPLB5_Sl_rdComp;
  output SPLB5_Sl_rdBTerm;
  output [0:0] SPLB5_Sl_MBusy;
  output [0:0] SPLB5_Sl_MRdErr;
  output [0:0] SPLB5_Sl_MWrErr;
  output [0:0] SPLB5_Sl_MIRQ;
  input SDMA5_Clk;
  output SDMA5_Rx_IntOut;
  output SDMA5_Tx_IntOut;
  output SDMA5_RstOut;
  output [0:31] SDMA5_TX_D;
  output [0:3] SDMA5_TX_Rem;
  output SDMA5_TX_SOF;
  output SDMA5_TX_EOF;
  output SDMA5_TX_SOP;
  output SDMA5_TX_EOP;
  output SDMA5_TX_Src_Rdy;
  input SDMA5_TX_Dst_Rdy;
  input [0:31] SDMA5_RX_D;
  input [0:3] SDMA5_RX_Rem;
  input SDMA5_RX_SOF;
  input SDMA5_RX_EOF;
  input SDMA5_RX_SOP;
  input SDMA5_RX_EOP;
  input SDMA5_RX_Src_Rdy;
  output SDMA5_RX_Dst_Rdy;
  input SDMA_CTRL5_Clk;
  input SDMA_CTRL5_Rst;
  input [0:31] SDMA_CTRL5_PLB_ABus;
  input SDMA_CTRL5_PLB_PAValid;
  input SDMA_CTRL5_PLB_SAValid;
  input [0:0] SDMA_CTRL5_PLB_masterID;
  input SDMA_CTRL5_PLB_RNW;
  input [0:7] SDMA_CTRL5_PLB_BE;
  input [0:31] SDMA_CTRL5_PLB_UABus;
  input SDMA_CTRL5_PLB_rdPrim;
  input SDMA_CTRL5_PLB_wrPrim;
  input SDMA_CTRL5_PLB_abort;
  input SDMA_CTRL5_PLB_busLock;
  input [0:1] SDMA_CTRL5_PLB_MSize;
  input [0:3] SDMA_CTRL5_PLB_size;
  input [0:2] SDMA_CTRL5_PLB_type;
  input SDMA_CTRL5_PLB_lockErr;
  input SDMA_CTRL5_PLB_wrPendReq;
  input [0:1] SDMA_CTRL5_PLB_wrPendPri;
  input SDMA_CTRL5_PLB_rdPendReq;
  input [0:1] SDMA_CTRL5_PLB_rdPendPri;
  input [0:1] SDMA_CTRL5_PLB_reqPri;
  input [0:15] SDMA_CTRL5_PLB_TAttribute;
  input SDMA_CTRL5_PLB_rdBurst;
  input SDMA_CTRL5_PLB_wrBurst;
  input [0:63] SDMA_CTRL5_PLB_wrDBus;
  output SDMA_CTRL5_Sl_addrAck;
  output [0:1] SDMA_CTRL5_Sl_SSize;
  output SDMA_CTRL5_Sl_wait;
  output SDMA_CTRL5_Sl_rearbitrate;
  output SDMA_CTRL5_Sl_wrDAck;
  output SDMA_CTRL5_Sl_wrComp;
  output SDMA_CTRL5_Sl_wrBTerm;
  output [0:63] SDMA_CTRL5_Sl_rdDBus;
  output [0:3] SDMA_CTRL5_Sl_rdWdAddr;
  output SDMA_CTRL5_Sl_rdDAck;
  output SDMA_CTRL5_Sl_rdComp;
  output SDMA_CTRL5_Sl_rdBTerm;
  output [0:0] SDMA_CTRL5_Sl_MBusy;
  output [0:0] SDMA_CTRL5_Sl_MRdErr;
  output [0:0] SDMA_CTRL5_Sl_MWrErr;
  output [0:0] SDMA_CTRL5_Sl_MIRQ;
  input [31:0] PIM5_Addr;
  input PIM5_AddrReq;
  output PIM5_AddrAck;
  input PIM5_RNW;
  input [3:0] PIM5_Size;
  input PIM5_RdModWr;
  input [63:0] PIM5_WrFIFO_Data;
  input [7:0] PIM5_WrFIFO_BE;
  input PIM5_WrFIFO_Push;
  output [63:0] PIM5_RdFIFO_Data;
  input PIM5_RdFIFO_Pop;
  output [3:0] PIM5_RdFIFO_RdWdAddr;
  output PIM5_WrFIFO_Empty;
  output PIM5_WrFIFO_AlmostFull;
  input PIM5_WrFIFO_Flush;
  output PIM5_RdFIFO_Empty;
  input PIM5_RdFIFO_Flush;
  output [1:0] PIM5_RdFIFO_Latency;
  output PIM5_InitDone;
  input PPC440MC5_MIMCReadNotWrite;
  input [0:35] PPC440MC5_MIMCAddress;
  input PPC440MC5_MIMCAddressValid;
  input [0:127] PPC440MC5_MIMCWriteData;
  input PPC440MC5_MIMCWriteDataValid;
  input [0:15] PPC440MC5_MIMCByteEnable;
  input PPC440MC5_MIMCBankConflict;
  input PPC440MC5_MIMCRowConflict;
  output [0:127] PPC440MC5_MCMIReadData;
  output PPC440MC5_MCMIReadDataValid;
  output PPC440MC5_MCMIReadDataErr;
  output PPC440MC5_MCMIAddrReadyToAccept;
  input VFBC5_Cmd_Clk;
  input VFBC5_Cmd_Reset;
  input [31:0] VFBC5_Cmd_Data;
  input VFBC5_Cmd_Write;
  input VFBC5_Cmd_End;
  output VFBC5_Cmd_Full;
  output VFBC5_Cmd_Almost_Full;
  output VFBC5_Cmd_Idle;
  input VFBC5_Wd_Clk;
  input VFBC5_Wd_Reset;
  input VFBC5_Wd_Write;
  input VFBC5_Wd_End_Burst;
  input VFBC5_Wd_Flush;
  input [31:0] VFBC5_Wd_Data;
  input [3:0] VFBC5_Wd_Data_BE;
  output VFBC5_Wd_Full;
  output VFBC5_Wd_Almost_Full;
  input VFBC5_Rd_Clk;
  input VFBC5_Rd_Reset;
  input VFBC5_Rd_Read;
  input VFBC5_Rd_End_Burst;
  input VFBC5_Rd_Flush;
  output [31:0] VFBC5_Rd_Data;
  output VFBC5_Rd_Empty;
  output VFBC5_Rd_Almost_Empty;
  input MCB5_cmd_clk;
  input MCB5_cmd_en;
  input [2:0] MCB5_cmd_instr;
  input [5:0] MCB5_cmd_bl;
  input [29:0] MCB5_cmd_byte_addr;
  output MCB5_cmd_empty;
  output MCB5_cmd_full;
  input MCB5_wr_clk;
  input MCB5_wr_en;
  input [7:0] MCB5_wr_mask;
  input [63:0] MCB5_wr_data;
  output MCB5_wr_full;
  output MCB5_wr_empty;
  output [6:0] MCB5_wr_count;
  output MCB5_wr_underrun;
  output MCB5_wr_error;
  input MCB5_rd_clk;
  input MCB5_rd_en;
  output [63:0] MCB5_rd_data;
  output MCB5_rd_full;
  output MCB5_rd_empty;
  output [6:0] MCB5_rd_count;
  output MCB5_rd_overflow;
  output MCB5_rd_error;
  input FSL6_M_Clk;
  input FSL6_M_Write;
  input [0:31] FSL6_M_Data;
  input FSL6_M_Control;
  output FSL6_M_Full;
  input FSL6_S_Clk;
  input FSL6_S_Read;
  output [0:31] FSL6_S_Data;
  output FSL6_S_Control;
  output FSL6_S_Exists;
  input FSL6_B_M_Clk;
  input FSL6_B_M_Write;
  input [0:31] FSL6_B_M_Data;
  input FSL6_B_M_Control;
  output FSL6_B_M_Full;
  input FSL6_B_S_Clk;
  input FSL6_B_S_Read;
  output [0:31] FSL6_B_S_Data;
  output FSL6_B_S_Control;
  output FSL6_B_S_Exists;
  input SPLB6_Clk;
  input SPLB6_Rst;
  input [0:31] SPLB6_PLB_ABus;
  input SPLB6_PLB_PAValid;
  input SPLB6_PLB_SAValid;
  input [0:0] SPLB6_PLB_masterID;
  input SPLB6_PLB_RNW;
  input [0:7] SPLB6_PLB_BE;
  input [0:31] SPLB6_PLB_UABus;
  input SPLB6_PLB_rdPrim;
  input SPLB6_PLB_wrPrim;
  input SPLB6_PLB_abort;
  input SPLB6_PLB_busLock;
  input [0:1] SPLB6_PLB_MSize;
  input [0:3] SPLB6_PLB_size;
  input [0:2] SPLB6_PLB_type;
  input SPLB6_PLB_lockErr;
  input SPLB6_PLB_wrPendReq;
  input [0:1] SPLB6_PLB_wrPendPri;
  input SPLB6_PLB_rdPendReq;
  input [0:1] SPLB6_PLB_rdPendPri;
  input [0:1] SPLB6_PLB_reqPri;
  input [0:15] SPLB6_PLB_TAttribute;
  input SPLB6_PLB_rdBurst;
  input SPLB6_PLB_wrBurst;
  input [0:63] SPLB6_PLB_wrDBus;
  output SPLB6_Sl_addrAck;
  output [0:1] SPLB6_Sl_SSize;
  output SPLB6_Sl_wait;
  output SPLB6_Sl_rearbitrate;
  output SPLB6_Sl_wrDAck;
  output SPLB6_Sl_wrComp;
  output SPLB6_Sl_wrBTerm;
  output [0:63] SPLB6_Sl_rdDBus;
  output [0:3] SPLB6_Sl_rdWdAddr;
  output SPLB6_Sl_rdDAck;
  output SPLB6_Sl_rdComp;
  output SPLB6_Sl_rdBTerm;
  output [0:0] SPLB6_Sl_MBusy;
  output [0:0] SPLB6_Sl_MRdErr;
  output [0:0] SPLB6_Sl_MWrErr;
  output [0:0] SPLB6_Sl_MIRQ;
  input SDMA6_Clk;
  output SDMA6_Rx_IntOut;
  output SDMA6_Tx_IntOut;
  output SDMA6_RstOut;
  output [0:31] SDMA6_TX_D;
  output [0:3] SDMA6_TX_Rem;
  output SDMA6_TX_SOF;
  output SDMA6_TX_EOF;
  output SDMA6_TX_SOP;
  output SDMA6_TX_EOP;
  output SDMA6_TX_Src_Rdy;
  input SDMA6_TX_Dst_Rdy;
  input [0:31] SDMA6_RX_D;
  input [0:3] SDMA6_RX_Rem;
  input SDMA6_RX_SOF;
  input SDMA6_RX_EOF;
  input SDMA6_RX_SOP;
  input SDMA6_RX_EOP;
  input SDMA6_RX_Src_Rdy;
  output SDMA6_RX_Dst_Rdy;
  input SDMA_CTRL6_Clk;
  input SDMA_CTRL6_Rst;
  input [0:31] SDMA_CTRL6_PLB_ABus;
  input SDMA_CTRL6_PLB_PAValid;
  input SDMA_CTRL6_PLB_SAValid;
  input [0:0] SDMA_CTRL6_PLB_masterID;
  input SDMA_CTRL6_PLB_RNW;
  input [0:7] SDMA_CTRL6_PLB_BE;
  input [0:31] SDMA_CTRL6_PLB_UABus;
  input SDMA_CTRL6_PLB_rdPrim;
  input SDMA_CTRL6_PLB_wrPrim;
  input SDMA_CTRL6_PLB_abort;
  input SDMA_CTRL6_PLB_busLock;
  input [0:1] SDMA_CTRL6_PLB_MSize;
  input [0:3] SDMA_CTRL6_PLB_size;
  input [0:2] SDMA_CTRL6_PLB_type;
  input SDMA_CTRL6_PLB_lockErr;
  input SDMA_CTRL6_PLB_wrPendReq;
  input [0:1] SDMA_CTRL6_PLB_wrPendPri;
  input SDMA_CTRL6_PLB_rdPendReq;
  input [0:1] SDMA_CTRL6_PLB_rdPendPri;
  input [0:1] SDMA_CTRL6_PLB_reqPri;
  input [0:15] SDMA_CTRL6_PLB_TAttribute;
  input SDMA_CTRL6_PLB_rdBurst;
  input SDMA_CTRL6_PLB_wrBurst;
  input [0:63] SDMA_CTRL6_PLB_wrDBus;
  output SDMA_CTRL6_Sl_addrAck;
  output [0:1] SDMA_CTRL6_Sl_SSize;
  output SDMA_CTRL6_Sl_wait;
  output SDMA_CTRL6_Sl_rearbitrate;
  output SDMA_CTRL6_Sl_wrDAck;
  output SDMA_CTRL6_Sl_wrComp;
  output SDMA_CTRL6_Sl_wrBTerm;
  output [0:63] SDMA_CTRL6_Sl_rdDBus;
  output [0:3] SDMA_CTRL6_Sl_rdWdAddr;
  output SDMA_CTRL6_Sl_rdDAck;
  output SDMA_CTRL6_Sl_rdComp;
  output SDMA_CTRL6_Sl_rdBTerm;
  output [0:0] SDMA_CTRL6_Sl_MBusy;
  output [0:0] SDMA_CTRL6_Sl_MRdErr;
  output [0:0] SDMA_CTRL6_Sl_MWrErr;
  output [0:0] SDMA_CTRL6_Sl_MIRQ;
  input [31:0] PIM6_Addr;
  input PIM6_AddrReq;
  output PIM6_AddrAck;
  input PIM6_RNW;
  input [3:0] PIM6_Size;
  input PIM6_RdModWr;
  input [63:0] PIM6_WrFIFO_Data;
  input [7:0] PIM6_WrFIFO_BE;
  input PIM6_WrFIFO_Push;
  output [63:0] PIM6_RdFIFO_Data;
  input PIM6_RdFIFO_Pop;
  output [3:0] PIM6_RdFIFO_RdWdAddr;
  output PIM6_WrFIFO_Empty;
  output PIM6_WrFIFO_AlmostFull;
  input PIM6_WrFIFO_Flush;
  output PIM6_RdFIFO_Empty;
  input PIM6_RdFIFO_Flush;
  output [1:0] PIM6_RdFIFO_Latency;
  output PIM6_InitDone;
  input PPC440MC6_MIMCReadNotWrite;
  input [0:35] PPC440MC6_MIMCAddress;
  input PPC440MC6_MIMCAddressValid;
  input [0:127] PPC440MC6_MIMCWriteData;
  input PPC440MC6_MIMCWriteDataValid;
  input [0:15] PPC440MC6_MIMCByteEnable;
  input PPC440MC6_MIMCBankConflict;
  input PPC440MC6_MIMCRowConflict;
  output [0:127] PPC440MC6_MCMIReadData;
  output PPC440MC6_MCMIReadDataValid;
  output PPC440MC6_MCMIReadDataErr;
  output PPC440MC6_MCMIAddrReadyToAccept;
  input VFBC6_Cmd_Clk;
  input VFBC6_Cmd_Reset;
  input [31:0] VFBC6_Cmd_Data;
  input VFBC6_Cmd_Write;
  input VFBC6_Cmd_End;
  output VFBC6_Cmd_Full;
  output VFBC6_Cmd_Almost_Full;
  output VFBC6_Cmd_Idle;
  input VFBC6_Wd_Clk;
  input VFBC6_Wd_Reset;
  input VFBC6_Wd_Write;
  input VFBC6_Wd_End_Burst;
  input VFBC6_Wd_Flush;
  input [31:0] VFBC6_Wd_Data;
  input [3:0] VFBC6_Wd_Data_BE;
  output VFBC6_Wd_Full;
  output VFBC6_Wd_Almost_Full;
  input VFBC6_Rd_Clk;
  input VFBC6_Rd_Reset;
  input VFBC6_Rd_Read;
  input VFBC6_Rd_End_Burst;
  input VFBC6_Rd_Flush;
  output [31:0] VFBC6_Rd_Data;
  output VFBC6_Rd_Empty;
  output VFBC6_Rd_Almost_Empty;
  input MCB6_cmd_clk;
  input MCB6_cmd_en;
  input [2:0] MCB6_cmd_instr;
  input [5:0] MCB6_cmd_bl;
  input [29:0] MCB6_cmd_byte_addr;
  output MCB6_cmd_empty;
  output MCB6_cmd_full;
  input MCB6_wr_clk;
  input MCB6_wr_en;
  input [7:0] MCB6_wr_mask;
  input [63:0] MCB6_wr_data;
  output MCB6_wr_full;
  output MCB6_wr_empty;
  output [6:0] MCB6_wr_count;
  output MCB6_wr_underrun;
  output MCB6_wr_error;
  input MCB6_rd_clk;
  input MCB6_rd_en;
  output [63:0] MCB6_rd_data;
  output MCB6_rd_full;
  output MCB6_rd_empty;
  output [6:0] MCB6_rd_count;
  output MCB6_rd_overflow;
  output MCB6_rd_error;
  input FSL7_M_Clk;
  input FSL7_M_Write;
  input [0:31] FSL7_M_Data;
  input FSL7_M_Control;
  output FSL7_M_Full;
  input FSL7_S_Clk;
  input FSL7_S_Read;
  output [0:31] FSL7_S_Data;
  output FSL7_S_Control;
  output FSL7_S_Exists;
  input FSL7_B_M_Clk;
  input FSL7_B_M_Write;
  input [0:31] FSL7_B_M_Data;
  input FSL7_B_M_Control;
  output FSL7_B_M_Full;
  input FSL7_B_S_Clk;
  input FSL7_B_S_Read;
  output [0:31] FSL7_B_S_Data;
  output FSL7_B_S_Control;
  output FSL7_B_S_Exists;
  input SPLB7_Clk;
  input SPLB7_Rst;
  input [0:31] SPLB7_PLB_ABus;
  input SPLB7_PLB_PAValid;
  input SPLB7_PLB_SAValid;
  input [0:0] SPLB7_PLB_masterID;
  input SPLB7_PLB_RNW;
  input [0:7] SPLB7_PLB_BE;
  input [0:31] SPLB7_PLB_UABus;
  input SPLB7_PLB_rdPrim;
  input SPLB7_PLB_wrPrim;
  input SPLB7_PLB_abort;
  input SPLB7_PLB_busLock;
  input [0:1] SPLB7_PLB_MSize;
  input [0:3] SPLB7_PLB_size;
  input [0:2] SPLB7_PLB_type;
  input SPLB7_PLB_lockErr;
  input SPLB7_PLB_wrPendReq;
  input [0:1] SPLB7_PLB_wrPendPri;
  input SPLB7_PLB_rdPendReq;
  input [0:1] SPLB7_PLB_rdPendPri;
  input [0:1] SPLB7_PLB_reqPri;
  input [0:15] SPLB7_PLB_TAttribute;
  input SPLB7_PLB_rdBurst;
  input SPLB7_PLB_wrBurst;
  input [0:63] SPLB7_PLB_wrDBus;
  output SPLB7_Sl_addrAck;
  output [0:1] SPLB7_Sl_SSize;
  output SPLB7_Sl_wait;
  output SPLB7_Sl_rearbitrate;
  output SPLB7_Sl_wrDAck;
  output SPLB7_Sl_wrComp;
  output SPLB7_Sl_wrBTerm;
  output [0:63] SPLB7_Sl_rdDBus;
  output [0:3] SPLB7_Sl_rdWdAddr;
  output SPLB7_Sl_rdDAck;
  output SPLB7_Sl_rdComp;
  output SPLB7_Sl_rdBTerm;
  output [0:0] SPLB7_Sl_MBusy;
  output [0:0] SPLB7_Sl_MRdErr;
  output [0:0] SPLB7_Sl_MWrErr;
  output [0:0] SPLB7_Sl_MIRQ;
  input SDMA7_Clk;
  output SDMA7_Rx_IntOut;
  output SDMA7_Tx_IntOut;
  output SDMA7_RstOut;
  output [0:31] SDMA7_TX_D;
  output [0:3] SDMA7_TX_Rem;
  output SDMA7_TX_SOF;
  output SDMA7_TX_EOF;
  output SDMA7_TX_SOP;
  output SDMA7_TX_EOP;
  output SDMA7_TX_Src_Rdy;
  input SDMA7_TX_Dst_Rdy;
  input [0:31] SDMA7_RX_D;
  input [0:3] SDMA7_RX_Rem;
  input SDMA7_RX_SOF;
  input SDMA7_RX_EOF;
  input SDMA7_RX_SOP;
  input SDMA7_RX_EOP;
  input SDMA7_RX_Src_Rdy;
  output SDMA7_RX_Dst_Rdy;
  input SDMA_CTRL7_Clk;
  input SDMA_CTRL7_Rst;
  input [0:31] SDMA_CTRL7_PLB_ABus;
  input SDMA_CTRL7_PLB_PAValid;
  input SDMA_CTRL7_PLB_SAValid;
  input [0:0] SDMA_CTRL7_PLB_masterID;
  input SDMA_CTRL7_PLB_RNW;
  input [0:7] SDMA_CTRL7_PLB_BE;
  input [0:31] SDMA_CTRL7_PLB_UABus;
  input SDMA_CTRL7_PLB_rdPrim;
  input SDMA_CTRL7_PLB_wrPrim;
  input SDMA_CTRL7_PLB_abort;
  input SDMA_CTRL7_PLB_busLock;
  input [0:1] SDMA_CTRL7_PLB_MSize;
  input [0:3] SDMA_CTRL7_PLB_size;
  input [0:2] SDMA_CTRL7_PLB_type;
  input SDMA_CTRL7_PLB_lockErr;
  input SDMA_CTRL7_PLB_wrPendReq;
  input [0:1] SDMA_CTRL7_PLB_wrPendPri;
  input SDMA_CTRL7_PLB_rdPendReq;
  input [0:1] SDMA_CTRL7_PLB_rdPendPri;
  input [0:1] SDMA_CTRL7_PLB_reqPri;
  input [0:15] SDMA_CTRL7_PLB_TAttribute;
  input SDMA_CTRL7_PLB_rdBurst;
  input SDMA_CTRL7_PLB_wrBurst;
  input [0:63] SDMA_CTRL7_PLB_wrDBus;
  output SDMA_CTRL7_Sl_addrAck;
  output [0:1] SDMA_CTRL7_Sl_SSize;
  output SDMA_CTRL7_Sl_wait;
  output SDMA_CTRL7_Sl_rearbitrate;
  output SDMA_CTRL7_Sl_wrDAck;
  output SDMA_CTRL7_Sl_wrComp;
  output SDMA_CTRL7_Sl_wrBTerm;
  output [0:63] SDMA_CTRL7_Sl_rdDBus;
  output [0:3] SDMA_CTRL7_Sl_rdWdAddr;
  output SDMA_CTRL7_Sl_rdDAck;
  output SDMA_CTRL7_Sl_rdComp;
  output SDMA_CTRL7_Sl_rdBTerm;
  output [0:0] SDMA_CTRL7_Sl_MBusy;
  output [0:0] SDMA_CTRL7_Sl_MRdErr;
  output [0:0] SDMA_CTRL7_Sl_MWrErr;
  output [0:0] SDMA_CTRL7_Sl_MIRQ;
  input [31:0] PIM7_Addr;
  input PIM7_AddrReq;
  output PIM7_AddrAck;
  input PIM7_RNW;
  input [3:0] PIM7_Size;
  input PIM7_RdModWr;
  input [63:0] PIM7_WrFIFO_Data;
  input [7:0] PIM7_WrFIFO_BE;
  input PIM7_WrFIFO_Push;
  output [63:0] PIM7_RdFIFO_Data;
  input PIM7_RdFIFO_Pop;
  output [3:0] PIM7_RdFIFO_RdWdAddr;
  output PIM7_WrFIFO_Empty;
  output PIM7_WrFIFO_AlmostFull;
  input PIM7_WrFIFO_Flush;
  output PIM7_RdFIFO_Empty;
  input PIM7_RdFIFO_Flush;
  output [1:0] PIM7_RdFIFO_Latency;
  output PIM7_InitDone;
  input PPC440MC7_MIMCReadNotWrite;
  input [0:35] PPC440MC7_MIMCAddress;
  input PPC440MC7_MIMCAddressValid;
  input [0:127] PPC440MC7_MIMCWriteData;
  input PPC440MC7_MIMCWriteDataValid;
  input [0:15] PPC440MC7_MIMCByteEnable;
  input PPC440MC7_MIMCBankConflict;
  input PPC440MC7_MIMCRowConflict;
  output [0:127] PPC440MC7_MCMIReadData;
  output PPC440MC7_MCMIReadDataValid;
  output PPC440MC7_MCMIReadDataErr;
  output PPC440MC7_MCMIAddrReadyToAccept;
  input VFBC7_Cmd_Clk;
  input VFBC7_Cmd_Reset;
  input [31:0] VFBC7_Cmd_Data;
  input VFBC7_Cmd_Write;
  input VFBC7_Cmd_End;
  output VFBC7_Cmd_Full;
  output VFBC7_Cmd_Almost_Full;
  output VFBC7_Cmd_Idle;
  input VFBC7_Wd_Clk;
  input VFBC7_Wd_Reset;
  input VFBC7_Wd_Write;
  input VFBC7_Wd_End_Burst;
  input VFBC7_Wd_Flush;
  input [31:0] VFBC7_Wd_Data;
  input [3:0] VFBC7_Wd_Data_BE;
  output VFBC7_Wd_Full;
  output VFBC7_Wd_Almost_Full;
  input VFBC7_Rd_Clk;
  input VFBC7_Rd_Reset;
  input VFBC7_Rd_Read;
  input VFBC7_Rd_End_Burst;
  input VFBC7_Rd_Flush;
  output [31:0] VFBC7_Rd_Data;
  output VFBC7_Rd_Empty;
  output VFBC7_Rd_Almost_Empty;
  input MCB7_cmd_clk;
  input MCB7_cmd_en;
  input [2:0] MCB7_cmd_instr;
  input [5:0] MCB7_cmd_bl;
  input [29:0] MCB7_cmd_byte_addr;
  output MCB7_cmd_empty;
  output MCB7_cmd_full;
  input MCB7_wr_clk;
  input MCB7_wr_en;
  input [7:0] MCB7_wr_mask;
  input [63:0] MCB7_wr_data;
  output MCB7_wr_full;
  output MCB7_wr_empty;
  output [6:0] MCB7_wr_count;
  output MCB7_wr_underrun;
  output MCB7_wr_error;
  input MCB7_rd_clk;
  input MCB7_rd_en;
  output [63:0] MCB7_rd_data;
  output MCB7_rd_full;
  output MCB7_rd_empty;
  output [6:0] MCB7_rd_count;
  output MCB7_rd_overflow;
  output MCB7_rd_error;
  input MPMC_CTRL_Clk;
  input MPMC_CTRL_Rst;
  input [0:31] MPMC_CTRL_PLB_ABus;
  input MPMC_CTRL_PLB_PAValid;
  input MPMC_CTRL_PLB_SAValid;
  input [0:0] MPMC_CTRL_PLB_masterID;
  input MPMC_CTRL_PLB_RNW;
  input [0:7] MPMC_CTRL_PLB_BE;
  input [0:31] MPMC_CTRL_PLB_UABus;
  input MPMC_CTRL_PLB_rdPrim;
  input MPMC_CTRL_PLB_wrPrim;
  input MPMC_CTRL_PLB_abort;
  input MPMC_CTRL_PLB_busLock;
  input [0:1] MPMC_CTRL_PLB_MSize;
  input [0:3] MPMC_CTRL_PLB_size;
  input [0:2] MPMC_CTRL_PLB_type;
  input MPMC_CTRL_PLB_lockErr;
  input MPMC_CTRL_PLB_wrPendReq;
  input [0:1] MPMC_CTRL_PLB_wrPendPri;
  input MPMC_CTRL_PLB_rdPendReq;
  input [0:1] MPMC_CTRL_PLB_rdPendPri;
  input [0:1] MPMC_CTRL_PLB_reqPri;
  input [0:15] MPMC_CTRL_PLB_TAttribute;
  input MPMC_CTRL_PLB_rdBurst;
  input MPMC_CTRL_PLB_wrBurst;
  input [0:63] MPMC_CTRL_PLB_wrDBus;
  output MPMC_CTRL_Sl_addrAck;
  output [0:1] MPMC_CTRL_Sl_SSize;
  output MPMC_CTRL_Sl_wait;
  output MPMC_CTRL_Sl_rearbitrate;
  output MPMC_CTRL_Sl_wrDAck;
  output MPMC_CTRL_Sl_wrComp;
  output MPMC_CTRL_Sl_wrBTerm;
  output [0:63] MPMC_CTRL_Sl_rdDBus;
  output [0:3] MPMC_CTRL_Sl_rdWdAddr;
  output MPMC_CTRL_Sl_rdDAck;
  output MPMC_CTRL_Sl_rdComp;
  output MPMC_CTRL_Sl_rdBTerm;
  output [0:0] MPMC_CTRL_Sl_MBusy;
  output [0:0] MPMC_CTRL_Sl_MRdErr;
  output [0:0] MPMC_CTRL_Sl_MWrErr;
  output [0:0] MPMC_CTRL_Sl_MIRQ;
  input MPMC_Clk0;
  input MPMC_Clk0_DIV2;
  input MPMC_Clk90;
  input MPMC_Clk_200MHz;
  input MPMC_Rst;
  input MPMC_Clk_Mem;
  input MPMC_Clk_Mem_2x;
  input MPMC_Clk_Mem_2x_180;
  input MPMC_Clk_Mem_2x_CE0;
  input MPMC_Clk_Mem_2x_CE90;
  input MPMC_Clk_Rd_Base;
  output MPMC_Clk_Mem_2x_bufpll_o;
  output MPMC_Clk_Mem_2x_180_bufpll_o;
  output MPMC_Clk_Mem_2x_CE0_bufpll_o;
  output MPMC_Clk_Mem_2x_CE90_bufpll_o;
  output MPMC_PLL_Lock_bufpll_o;
  input MPMC_PLL_Lock;
  input MPMC_Idelayctrl_Rdy_I;
  output MPMC_Idelayctrl_Rdy_O;
  output MPMC_InitDone;
  output MPMC_ECC_Intr;
  output MPMC_DCM_PSEN;
  output MPMC_DCM_PSINCDEC;
  input MPMC_DCM_PSDONE;
  input MPMC_MCB_DRP_Clk;
  output [1:0] SDRAM_Clk;
  output [0:0] SDRAM_CE;
  output [0:0] SDRAM_CS_n;
  output SDRAM_RAS_n;
  output SDRAM_CAS_n;
  output SDRAM_WE_n;
  output [2:0] SDRAM_BankAddr;
  output [13:0] SDRAM_Addr;
  inout [63:0] SDRAM_DQ;
  output [7:0] SDRAM_DM;
  output [1:0] DDR_Clk;
  output [1:0] DDR_Clk_n;
  output [0:0] DDR_CE;
  output [0:0] DDR_CS_n;
  output DDR_RAS_n;
  output DDR_CAS_n;
  output DDR_WE_n;
  output [2:0] DDR_BankAddr;
  output [13:0] DDR_Addr;
  inout [63:0] DDR_DQ;
  output [7:0] DDR_DM;
  inout [7:0] DDR_DQS;
  output DDR_DQS_Div_O;
  input DDR_DQS_Div_I;
  output [1:0] DDR2_Clk;
  output [1:0] DDR2_Clk_n;
  output [0:0] DDR2_CE;
  output [0:0] DDR2_CS_n;
  output [1:0] DDR2_ODT;
  output DDR2_RAS_n;
  output DDR2_CAS_n;
  output DDR2_WE_n;
  output [2:0] DDR2_BankAddr;
  output [13:0] DDR2_Addr;
  inout [63:0] DDR2_DQ;
  output [7:0] DDR2_DM;
  inout [7:0] DDR2_DQS;
  inout [7:0] DDR2_DQS_n;
  output DDR2_DQS_Div_O;
  input DDR2_DQS_Div_I;
  output [1:0] DDR3_Clk;
  output [1:0] DDR3_Clk_n;
  output [0:0] DDR3_CE;
  output [0:0] DDR3_CS_n;
  output [1:0] DDR3_ODT;
  output DDR3_RAS_n;
  output DDR3_CAS_n;
  output DDR3_WE_n;
  output [2:0] DDR3_BankAddr;
  output [13:0] DDR3_Addr;
  inout [63:0] DDR3_DQ;
  output [7:0] DDR3_DM;
  output DDR3_Reset_n;
  inout [7:0] DDR3_DQS;
  inout [7:0] DDR3_DQS_n;
  output [13:0] mcbx_dram_addr;
  output [2:0] mcbx_dram_ba;
  output mcbx_dram_ras_n;
  output mcbx_dram_cas_n;
  output mcbx_dram_we_n;
  output mcbx_dram_cke;
  output mcbx_dram_clk;
  output mcbx_dram_clk_n;
  inout [63:0] mcbx_dram_dq;
  inout mcbx_dram_dqs;
  inout mcbx_dram_dqs_n;
  inout mcbx_dram_udqs;
  inout mcbx_dram_udqs_n;
  output mcbx_dram_udm;
  output mcbx_dram_ldm;
  output mcbx_dram_odt;
  output mcbx_dram_ddr3_rst;
  input selfrefresh_enter;
  output selfrefresh_mode;
  input calib_recal;
  inout rzq;
  inout zio;

  mpmc
    #(
      .C_FAMILY ( "virtex5" ),
      .C_BASEFAMILY ( "virtex5" ),
      .C_SPEEDGRADE_INT ( 1 ),
      .C_NUM_PORTS ( 2 ),
      .C_PORT_CONFIG ( 1 ),
      .C_ALL_PIMS_SHARE_ADDRESSES ( 1 ),
      .C_MPMC_BASEADDR ( 32'h00000000 ),
      .C_MPMC_HIGHADDR ( 32'h3fffffff ),
      .C_SDMA_CTRL_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL_HIGHADDR ( 32'h00000000 ),
      .C_MPMC_CTRL_BASEADDR ( 32'hFFFFFFFF ),
      .C_MPMC_CTRL_HIGHADDR ( 32'h00000000 ),
      .C_MPMC_CTRL_AWIDTH ( 32 ),
      .C_MPMC_CTRL_DWIDTH ( 64 ),
      .C_MPMC_CTRL_NATIVE_DWIDTH ( 32 ),
      .C_MPMC_CTRL_NUM_MASTERS ( 1 ),
      .C_MPMC_CTRL_MID_WIDTH ( 1 ),
      .C_MPMC_CTRL_P2P ( 1 ),
      .C_MPMC_CTRL_SUPPORT_BURSTS ( 0 ),
      .C_MPMC_CTRL_SMALLEST_MASTER ( 32 ),
      .C_NUM_IDELAYCTRL ( 3 ),
      .C_IODELAY_GRP ( "ppc440mc_ddr2_0" ),
      .C_MAX_REQ_ALLOWED ( 1 ),
      .C_ARB_PIPELINE ( 1 ),
      .C_WR_DATAPATH_TML_PIPELINE ( 1 ),
      .C_RD_DATAPATH_TML_MAX_FANOUT ( 0 ),
      .C_ARB_USE_DEFAULT ( 0 ),
      .C_ARB0_ALGO ( "ROUND_ROBIN" ),
      .C_ARB0_NUM_SLOTS ( 8 ),
      .C_PM_ENABLE ( 0 ),
      .C_PM_DC_WIDTH ( 48 ),
      .C_PM_GC_CNTR ( 1 ),
      .C_PM_GC_WIDTH ( 48 ),
      .C_PM_SHIFT_CNT_BY ( 1 ),
      .C_SKIP_SIM_INIT_DELAY ( 1 ),
      .C_USE_MIG_S3_PHY ( 0 ),
      .C_USE_MIG_V4_PHY ( 0 ),
      .C_USE_MIG_V5_PHY ( 0 ),
      .C_USE_MIG_V6_PHY ( 0 ),
      .C_USE_MCB_S6_PHY ( 0 ),
      .C_USE_STATIC_PHY ( 1 ),
      .C_STATIC_PHY_RDDATA_CLK_SEL ( 0 ),
      .C_STATIC_PHY_RDDATA_SWAP_RISE ( 0 ),
      .C_STATIC_PHY_RDEN_DELAY ( 5 ),
      .C_DEBUG_REG_ENABLE ( 0 ),
      .C_SPECIAL_BOARD ( "NONE" ),
      .C_MEM_ADDR_ORDER ( "BANK_ROW_COLUMN" ),
      .C_MEM_CALIBRATION_MODE ( 1 ),
      .C_MEM_CALIBRATION_DELAY ( "HALF" ),
      .C_MEM_CALIBRATION_SOFT_IP ( "FALSE" ),
      .C_MEM_CALIBRATION_BYPASS ( "NO" ),
      .C_MPMC_MCB_DRP_CLK_PRESENT ( 0 ),
      .C_MEM_SKIP_IN_TERM_CAL ( 1 ),
      .C_MEM_SKIP_DYNAMIC_CAL ( 1 ),
      .C_MEM_SKIP_DYN_IN_TERM ( 1 ),
      .C_MEM_INCDEC_THRESHOLD ( 'h02 ),
      .C_MEM_CHECK_MAX_INDELAY ( 0 ),
      .C_MEM_CHECK_MAX_TAP_REG ( 0 ),
      .C_MEM_TZQINIT_MAXCNT ( 528 ),
      .C_MPMC_CLK_MEM_2X_PERIOD_PS ( 1250 ),
      .C_MCB_USE_EXTERNAL_BUFPLL ( 0 ),
      .C_MCB_LDQSP_TAP_DELAY_VAL ( 0 ),
      .C_MCB_UDQSP_TAP_DELAY_VAL ( 0 ),
      .C_MCB_LDQSN_TAP_DELAY_VAL ( 0 ),
      .C_MCB_UDQSN_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ0_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ1_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ2_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ3_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ4_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ5_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ6_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ7_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ8_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ9_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ10_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ11_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ12_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ13_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ14_TAP_DELAY_VAL ( 0 ),
      .C_MCB_DQ15_TAP_DELAY_VAL ( 0 ),
      .C_MEM_TYPE ( "DDR2" ),
      .C_MEM_PART_NUM_BANK_BITS ( 3 ),
      .C_MEM_PART_NUM_ROW_BITS ( 14 ),
      .C_MEM_PART_NUM_COL_BITS ( 10 ),
      .C_MEM_PART_TRAS ( 40000 ),
      .C_MEM_PART_TRCD ( 15000 ),
      .C_MEM_PART_TWR ( 15000 ),
      .C_MEM_PART_TRP ( 15000 ),
      .C_MEM_PART_TRFC ( 127500 ),
      .C_MEM_PART_TREFI ( 7800000 ),
      .C_MEM_PART_TWTR ( 10000 ),
      .C_MEM_PART_TRTP ( 7500 ),
      .C_MEM_PART_TPRDI ( 1000000 ),
      .C_MEM_PART_TZQI ( 128000000 ),
      .C_MPMC_CLK0_PERIOD_PS ( 5000 ),
      .C_MEM_CAS_LATENCY ( 3 ),
      .C_MEM_ODT_TYPE ( 1 ),
      .C_MEM_REDUCED_DRV ( 0 ),
      .C_MEM_REG_DIMM ( 1 ),
      .C_MEM_CLK_WIDTH ( 2 ),
      .C_MEM_ODT_WIDTH ( 2 ),
      .C_MEM_CE_WIDTH ( 1 ),
      .C_MEM_CS_N_WIDTH ( 1 ),
      .C_MEM_ADDR_WIDTH ( 14 ),
      .C_MEM_BANKADDR_WIDTH ( 3 ),
      .C_MEM_DATA_WIDTH ( 64 ),
      .C_MEM_BITS_DATA_PER_DQS ( 8 ),
      .C_MEM_DM_WIDTH ( 8 ),
      .C_MEM_DQS_WIDTH ( 8 ),
      .C_MEM_NUM_DIMMS ( 1 ),
      .C_MEM_NUM_RANKS ( 1 ),
      .C_MEM_DQS_IO_COL ( 72'h000000000000000000 ),
      .C_MEM_DQ_IO_MS ( 72'h000000000000000000 ),
      .C_DDR2_DQSN_ENABLE ( 1 ),
      .C_INCLUDE_ECC_SUPPORT ( 0 ),
      .C_ECC_DEFAULT_ON ( 1 ),
      .C_INCLUDE_ECC_TEST ( 0 ),
      .C_ECC_SEC_THRESHOLD ( 1 ),
      .C_ECC_DEC_THRESHOLD ( 1 ),
      .C_ECC_PEC_THRESHOLD ( 1 ),
      .C_ECC_DATA_WIDTH ( 0 ),
      .C_ECC_DM_WIDTH ( 0 ),
      .C_ECC_DQS_WIDTH ( 0 ),
      .C_MEM_PA_SR ( 0 ),
      .C_MEM_CAS_WR_LATENCY ( 5 ),
      .C_MEM_AUTO_SR ( "ENABLED" ),
      .C_MEM_HIGH_TEMP_SR ( "NORMAL" ),
      .C_MEM_DYNAMIC_WRITE_ODT ( "OFF" ),
      .C_MEM_WRLVL ( 1 ),
      .C_IDELAY_CLK_FREQ ( "DEFAULT" ),
      .C_MEM_PHASE_DETECT ( "DEFAULT" ),
      .C_MEM_IBUF_LPWR_MODE ( "DEFAULT" ),
      .C_MEM_IODELAY_HP_MODE ( "DEFAULT" ),
      .C_MEM_SIM_INIT_OPTION ( "DEFAULT" ),
      .C_MEM_SIM_CAL_OPTION ( "DEFAULT" ),
      .C_MEM_CAL_WIDTH ( "DEFAULT" ),
      .C_MEM_NDQS_COL0 ( 8 ),
      .C_MEM_NDQS_COL1 ( 0 ),
      .C_MEM_NDQS_COL2 ( 0 ),
      .C_MEM_NDQS_COL3 ( 0 ),
      .C_MEM_DQS_LOC_COL0 ( 144'h0706050403020100 ),
      .C_MEM_DQS_LOC_COL1 ( 144'h000000000000000000000000000000000000 ),
      .C_MEM_DQS_LOC_COL2 ( 144'h000000000000000000000000000000000000 ),
      .C_MEM_DQS_LOC_COL3 ( 144'h000000000000000000000000000000000000 ),
      .C_MAINT_PRESCALER_PERIOD ( 200000 ),
      .C_TBY4TAPVALUE ( 9999 ),
      .C_PIM0_BASEADDR ( 32'hFFFFFFFF ),
      .C_PIM0_HIGHADDR ( 32'h00000000 ),
      .C_PIM0_OFFSET ( 32'h00000000 ),
      .C_PIM0_DATA_WIDTH ( 64 ),
      .C_PIM0_BASETYPE ( 4 ),
      .C_PIM0_SUBTYPE ( "NPI" ),
      .C_XCL0_LINESIZE ( 4 ),
      .C_XCL0_WRITEXFER ( 1 ),
      .C_XCL0_PIPE_STAGES ( 2 ),
      .C_XCL0_B_IN_USE ( 0 ),
      .C_PIM0_B_SUBTYPE ( "NPI" ),
      .C_XCL0_B_LINESIZE ( 4 ),
      .C_XCL0_B_WRITEXFER ( 1 ),
      .C_SPLB0_AWIDTH ( 32 ),
      .C_SPLB0_DWIDTH ( 64 ),
      .C_SPLB0_NATIVE_DWIDTH ( 64 ),
      .C_SPLB0_NUM_MASTERS ( 1 ),
      .C_SPLB0_MID_WIDTH ( 1 ),
      .C_SPLB0_P2P ( 1 ),
      .C_SPLB0_SUPPORT_BURSTS ( 0 ),
      .C_SPLB0_SMALLEST_MASTER ( 32 ),
      .C_SDMA_CTRL0_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL0_HIGHADDR ( 32'h00000000 ),
      .C_SDMA_CTRL0_AWIDTH ( 32 ),
      .C_SDMA_CTRL0_DWIDTH ( 64 ),
      .C_SDMA_CTRL0_NATIVE_DWIDTH ( 32 ),
      .C_SDMA_CTRL0_NUM_MASTERS ( 1 ),
      .C_SDMA_CTRL0_MID_WIDTH ( 1 ),
      .C_SDMA_CTRL0_P2P ( 1 ),
      .C_SDMA_CTRL0_SUPPORT_BURSTS ( 0 ),
      .C_SDMA_CTRL0_SMALLEST_MASTER ( 32 ),
      .C_SDMA0_COMPLETED_ERR_TX ( 1 ),
      .C_SDMA0_COMPLETED_ERR_RX ( 1 ),
      .C_SDMA0_PRESCALAR ( 1023 ),
      .C_SDMA0_PI2LL_CLK_RATIO ( 1 ),
      .C_PPC440MC0_BURST_LENGTH ( 4 ),
      .C_PPC440MC0_PIPE_STAGES ( 1 ),
      .C_VFBC0_CMD_FIFO_DEPTH ( 32 ),
      .C_VFBC0_CMD_AFULL_COUNT ( 3 ),
      .C_VFBC0_RDWD_DATA_WIDTH ( 32 ),
      .C_VFBC0_RDWD_FIFO_DEPTH ( 1024 ),
      .C_VFBC0_RD_AEMPTY_WD_AFULL_COUNT ( 3 ),
      .C_PI0_RD_FIFO_TYPE ( "BRAM" ),
      .C_PI0_WR_FIFO_TYPE ( "BRAM" ),
      .C_PI0_ADDRACK_PIPELINE ( 1 ),
      .C_PI0_RD_FIFO_APP_PIPELINE ( 1 ),
      .C_PI0_RD_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI0_WR_FIFO_APP_PIPELINE ( 1 ),
      .C_PI0_WR_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI0_PM_USED ( 1 ),
      .C_PI0_PM_DC_CNTR ( 1 ),
      .C_PIM1_BASEADDR ( 32'hFFFFFFFF ),
      .C_PIM1_HIGHADDR ( 32'h00000000 ),
      .C_PIM1_OFFSET ( 32'h00000000 ),
      .C_PIM1_DATA_WIDTH ( 64 ),
      .C_PIM1_BASETYPE ( 4 ),
      .C_PIM1_SUBTYPE ( "INACTIVE" ),
      .C_XCL1_LINESIZE ( 4 ),
      .C_XCL1_WRITEXFER ( 1 ),
      .C_XCL1_PIPE_STAGES ( 2 ),
      .C_XCL1_B_IN_USE ( 0 ),
      .C_PIM1_B_SUBTYPE ( "INACTIVE" ),
      .C_XCL1_B_LINESIZE ( 4 ),
      .C_XCL1_B_WRITEXFER ( 1 ),
      .C_SPLB1_AWIDTH ( 32 ),
      .C_SPLB1_DWIDTH ( 64 ),
      .C_SPLB1_NATIVE_DWIDTH ( 64 ),
      .C_SPLB1_NUM_MASTERS ( 1 ),
      .C_SPLB1_MID_WIDTH ( 1 ),
      .C_SPLB1_P2P ( 1 ),
      .C_SPLB1_SUPPORT_BURSTS ( 0 ),
      .C_SPLB1_SMALLEST_MASTER ( 32 ),
      .C_SDMA_CTRL1_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL1_HIGHADDR ( 32'h00000000 ),
      .C_SDMA_CTRL1_AWIDTH ( 32 ),
      .C_SDMA_CTRL1_DWIDTH ( 64 ),
      .C_SDMA_CTRL1_NATIVE_DWIDTH ( 32 ),
      .C_SDMA_CTRL1_NUM_MASTERS ( 1 ),
      .C_SDMA_CTRL1_MID_WIDTH ( 1 ),
      .C_SDMA_CTRL1_P2P ( 1 ),
      .C_SDMA_CTRL1_SUPPORT_BURSTS ( 0 ),
      .C_SDMA_CTRL1_SMALLEST_MASTER ( 32 ),
      .C_SDMA1_COMPLETED_ERR_TX ( 1 ),
      .C_SDMA1_COMPLETED_ERR_RX ( 1 ),
      .C_SDMA1_PRESCALAR ( 1023 ),
      .C_SDMA1_PI2LL_CLK_RATIO ( 1 ),
      .C_PPC440MC1_BURST_LENGTH ( 4 ),
      .C_PPC440MC1_PIPE_STAGES ( 1 ),
      .C_VFBC1_CMD_FIFO_DEPTH ( 32 ),
      .C_VFBC1_CMD_AFULL_COUNT ( 3 ),
      .C_VFBC1_RDWD_DATA_WIDTH ( 32 ),
      .C_VFBC1_RDWD_FIFO_DEPTH ( 1024 ),
      .C_VFBC1_RD_AEMPTY_WD_AFULL_COUNT ( 3 ),
      .C_PI1_RD_FIFO_TYPE ( "BRAM" ),
      .C_PI1_WR_FIFO_TYPE ( "BRAM" ),
      .C_PI1_ADDRACK_PIPELINE ( 1 ),
      .C_PI1_RD_FIFO_APP_PIPELINE ( 1 ),
      .C_PI1_RD_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI1_WR_FIFO_APP_PIPELINE ( 1 ),
      .C_PI1_WR_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI1_PM_USED ( 1 ),
      .C_PI1_PM_DC_CNTR ( 1 ),
      .C_PIM2_BASEADDR ( 32'hFFFFFFFF ),
      .C_PIM2_HIGHADDR ( 32'h00000000 ),
      .C_PIM2_OFFSET ( 32'h00000000 ),
      .C_PIM2_DATA_WIDTH ( 64 ),
      .C_PIM2_BASETYPE ( 0 ),
      .C_PIM2_SUBTYPE ( "INACTIVE" ),
      .C_XCL2_LINESIZE ( 4 ),
      .C_XCL2_WRITEXFER ( 1 ),
      .C_XCL2_PIPE_STAGES ( 2 ),
      .C_XCL2_B_IN_USE ( 0 ),
      .C_PIM2_B_SUBTYPE ( "INACTIVE" ),
      .C_XCL2_B_LINESIZE ( 4 ),
      .C_XCL2_B_WRITEXFER ( 1 ),
      .C_SPLB2_AWIDTH ( 32 ),
      .C_SPLB2_DWIDTH ( 64 ),
      .C_SPLB2_NATIVE_DWIDTH ( 64 ),
      .C_SPLB2_NUM_MASTERS ( 1 ),
      .C_SPLB2_MID_WIDTH ( 1 ),
      .C_SPLB2_P2P ( 1 ),
      .C_SPLB2_SUPPORT_BURSTS ( 0 ),
      .C_SPLB2_SMALLEST_MASTER ( 32 ),
      .C_SDMA_CTRL2_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL2_HIGHADDR ( 32'h00000000 ),
      .C_SDMA_CTRL2_AWIDTH ( 32 ),
      .C_SDMA_CTRL2_DWIDTH ( 64 ),
      .C_SDMA_CTRL2_NATIVE_DWIDTH ( 32 ),
      .C_SDMA_CTRL2_NUM_MASTERS ( 1 ),
      .C_SDMA_CTRL2_MID_WIDTH ( 1 ),
      .C_SDMA_CTRL2_P2P ( 1 ),
      .C_SDMA_CTRL2_SUPPORT_BURSTS ( 0 ),
      .C_SDMA_CTRL2_SMALLEST_MASTER ( 32 ),
      .C_SDMA2_COMPLETED_ERR_TX ( 1 ),
      .C_SDMA2_COMPLETED_ERR_RX ( 1 ),
      .C_SDMA2_PRESCALAR ( 1023 ),
      .C_SDMA2_PI2LL_CLK_RATIO ( 1 ),
      .C_PPC440MC2_BURST_LENGTH ( 4 ),
      .C_PPC440MC2_PIPE_STAGES ( 1 ),
      .C_VFBC2_CMD_FIFO_DEPTH ( 32 ),
      .C_VFBC2_CMD_AFULL_COUNT ( 3 ),
      .C_VFBC2_RDWD_DATA_WIDTH ( 32 ),
      .C_VFBC2_RDWD_FIFO_DEPTH ( 1024 ),
      .C_VFBC2_RD_AEMPTY_WD_AFULL_COUNT ( 3 ),
      .C_PI2_RD_FIFO_TYPE ( "BRAM" ),
      .C_PI2_WR_FIFO_TYPE ( "BRAM" ),
      .C_PI2_ADDRACK_PIPELINE ( 1 ),
      .C_PI2_RD_FIFO_APP_PIPELINE ( 1 ),
      .C_PI2_RD_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI2_WR_FIFO_APP_PIPELINE ( 1 ),
      .C_PI2_WR_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI2_PM_USED ( 1 ),
      .C_PI2_PM_DC_CNTR ( 1 ),
      .C_PIM3_BASEADDR ( 32'hFFFFFFFF ),
      .C_PIM3_HIGHADDR ( 32'h00000000 ),
      .C_PIM3_OFFSET ( 32'h00000000 ),
      .C_PIM3_DATA_WIDTH ( 64 ),
      .C_PIM3_BASETYPE ( 0 ),
      .C_PIM3_SUBTYPE ( "INACTIVE" ),
      .C_XCL3_LINESIZE ( 4 ),
      .C_XCL3_WRITEXFER ( 1 ),
      .C_XCL3_PIPE_STAGES ( 2 ),
      .C_XCL3_B_IN_USE ( 0 ),
      .C_PIM3_B_SUBTYPE ( "INACTIVE" ),
      .C_XCL3_B_LINESIZE ( 4 ),
      .C_XCL3_B_WRITEXFER ( 1 ),
      .C_SPLB3_AWIDTH ( 32 ),
      .C_SPLB3_DWIDTH ( 64 ),
      .C_SPLB3_NATIVE_DWIDTH ( 64 ),
      .C_SPLB3_NUM_MASTERS ( 1 ),
      .C_SPLB3_MID_WIDTH ( 1 ),
      .C_SPLB3_P2P ( 1 ),
      .C_SPLB3_SUPPORT_BURSTS ( 0 ),
      .C_SPLB3_SMALLEST_MASTER ( 32 ),
      .C_SDMA_CTRL3_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL3_HIGHADDR ( 32'h00000000 ),
      .C_SDMA_CTRL3_AWIDTH ( 32 ),
      .C_SDMA_CTRL3_DWIDTH ( 64 ),
      .C_SDMA_CTRL3_NATIVE_DWIDTH ( 32 ),
      .C_SDMA_CTRL3_NUM_MASTERS ( 1 ),
      .C_SDMA_CTRL3_MID_WIDTH ( 1 ),
      .C_SDMA_CTRL3_P2P ( 1 ),
      .C_SDMA_CTRL3_SUPPORT_BURSTS ( 0 ),
      .C_SDMA_CTRL3_SMALLEST_MASTER ( 32 ),
      .C_SDMA3_COMPLETED_ERR_TX ( 1 ),
      .C_SDMA3_COMPLETED_ERR_RX ( 1 ),
      .C_SDMA3_PRESCALAR ( 1023 ),
      .C_SDMA3_PI2LL_CLK_RATIO ( 1 ),
      .C_PPC440MC3_BURST_LENGTH ( 4 ),
      .C_PPC440MC3_PIPE_STAGES ( 1 ),
      .C_VFBC3_CMD_FIFO_DEPTH ( 32 ),
      .C_VFBC3_CMD_AFULL_COUNT ( 3 ),
      .C_VFBC3_RDWD_DATA_WIDTH ( 32 ),
      .C_VFBC3_RDWD_FIFO_DEPTH ( 1024 ),
      .C_VFBC3_RD_AEMPTY_WD_AFULL_COUNT ( 3 ),
      .C_PI3_RD_FIFO_TYPE ( "BRAM" ),
      .C_PI3_WR_FIFO_TYPE ( "BRAM" ),
      .C_PI3_ADDRACK_PIPELINE ( 1 ),
      .C_PI3_RD_FIFO_APP_PIPELINE ( 1 ),
      .C_PI3_RD_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI3_WR_FIFO_APP_PIPELINE ( 1 ),
      .C_PI3_WR_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI3_PM_USED ( 1 ),
      .C_PI3_PM_DC_CNTR ( 1 ),
      .C_PIM4_BASEADDR ( 32'hFFFFFFFF ),
      .C_PIM4_HIGHADDR ( 32'h00000000 ),
      .C_PIM4_OFFSET ( 32'h00000000 ),
      .C_PIM4_DATA_WIDTH ( 64 ),
      .C_PIM4_BASETYPE ( 0 ),
      .C_PIM4_SUBTYPE ( "INACTIVE" ),
      .C_XCL4_LINESIZE ( 4 ),
      .C_XCL4_WRITEXFER ( 1 ),
      .C_XCL4_PIPE_STAGES ( 2 ),
      .C_XCL4_B_IN_USE ( 0 ),
      .C_PIM4_B_SUBTYPE ( "INACTIVE" ),
      .C_XCL4_B_LINESIZE ( 4 ),
      .C_XCL4_B_WRITEXFER ( 1 ),
      .C_SPLB4_AWIDTH ( 32 ),
      .C_SPLB4_DWIDTH ( 64 ),
      .C_SPLB4_NATIVE_DWIDTH ( 64 ),
      .C_SPLB4_NUM_MASTERS ( 1 ),
      .C_SPLB4_MID_WIDTH ( 1 ),
      .C_SPLB4_P2P ( 1 ),
      .C_SPLB4_SUPPORT_BURSTS ( 0 ),
      .C_SPLB4_SMALLEST_MASTER ( 32 ),
      .C_SDMA_CTRL4_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL4_HIGHADDR ( 32'h00000000 ),
      .C_SDMA_CTRL4_AWIDTH ( 32 ),
      .C_SDMA_CTRL4_DWIDTH ( 64 ),
      .C_SDMA_CTRL4_NATIVE_DWIDTH ( 32 ),
      .C_SDMA_CTRL4_NUM_MASTERS ( 1 ),
      .C_SDMA_CTRL4_MID_WIDTH ( 1 ),
      .C_SDMA_CTRL4_P2P ( 1 ),
      .C_SDMA_CTRL4_SUPPORT_BURSTS ( 0 ),
      .C_SDMA_CTRL4_SMALLEST_MASTER ( 32 ),
      .C_SDMA4_COMPLETED_ERR_TX ( 1 ),
      .C_SDMA4_COMPLETED_ERR_RX ( 1 ),
      .C_SDMA4_PRESCALAR ( 1023 ),
      .C_SDMA4_PI2LL_CLK_RATIO ( 1 ),
      .C_PPC440MC4_BURST_LENGTH ( 4 ),
      .C_PPC440MC4_PIPE_STAGES ( 1 ),
      .C_VFBC4_CMD_FIFO_DEPTH ( 32 ),
      .C_VFBC4_CMD_AFULL_COUNT ( 3 ),
      .C_VFBC4_RDWD_DATA_WIDTH ( 32 ),
      .C_VFBC4_RDWD_FIFO_DEPTH ( 1024 ),
      .C_VFBC4_RD_AEMPTY_WD_AFULL_COUNT ( 3 ),
      .C_PI4_RD_FIFO_TYPE ( "BRAM" ),
      .C_PI4_WR_FIFO_TYPE ( "BRAM" ),
      .C_PI4_ADDRACK_PIPELINE ( 1 ),
      .C_PI4_RD_FIFO_APP_PIPELINE ( 1 ),
      .C_PI4_RD_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI4_WR_FIFO_APP_PIPELINE ( 1 ),
      .C_PI4_WR_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI4_PM_USED ( 1 ),
      .C_PI4_PM_DC_CNTR ( 1 ),
      .C_PIM5_BASEADDR ( 32'hFFFFFFFF ),
      .C_PIM5_HIGHADDR ( 32'h00000000 ),
      .C_PIM5_OFFSET ( 32'h00000000 ),
      .C_PIM5_DATA_WIDTH ( 64 ),
      .C_PIM5_BASETYPE ( 0 ),
      .C_PIM5_SUBTYPE ( "INACTIVE" ),
      .C_XCL5_LINESIZE ( 4 ),
      .C_XCL5_WRITEXFER ( 1 ),
      .C_XCL5_PIPE_STAGES ( 2 ),
      .C_XCL5_B_IN_USE ( 0 ),
      .C_PIM5_B_SUBTYPE ( "INACTIVE" ),
      .C_XCL5_B_LINESIZE ( 4 ),
      .C_XCL5_B_WRITEXFER ( 1 ),
      .C_SPLB5_AWIDTH ( 32 ),
      .C_SPLB5_DWIDTH ( 64 ),
      .C_SPLB5_NATIVE_DWIDTH ( 64 ),
      .C_SPLB5_NUM_MASTERS ( 1 ),
      .C_SPLB5_MID_WIDTH ( 1 ),
      .C_SPLB5_P2P ( 1 ),
      .C_SPLB5_SUPPORT_BURSTS ( 0 ),
      .C_SPLB5_SMALLEST_MASTER ( 32 ),
      .C_SDMA_CTRL5_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL5_HIGHADDR ( 32'h00000000 ),
      .C_SDMA_CTRL5_AWIDTH ( 32 ),
      .C_SDMA_CTRL5_DWIDTH ( 64 ),
      .C_SDMA_CTRL5_NATIVE_DWIDTH ( 32 ),
      .C_SDMA_CTRL5_NUM_MASTERS ( 1 ),
      .C_SDMA_CTRL5_MID_WIDTH ( 1 ),
      .C_SDMA_CTRL5_P2P ( 1 ),
      .C_SDMA_CTRL5_SUPPORT_BURSTS ( 0 ),
      .C_SDMA_CTRL5_SMALLEST_MASTER ( 32 ),
      .C_SDMA5_COMPLETED_ERR_TX ( 1 ),
      .C_SDMA5_COMPLETED_ERR_RX ( 1 ),
      .C_SDMA5_PRESCALAR ( 1023 ),
      .C_SDMA5_PI2LL_CLK_RATIO ( 1 ),
      .C_PPC440MC5_BURST_LENGTH ( 4 ),
      .C_PPC440MC5_PIPE_STAGES ( 1 ),
      .C_VFBC5_CMD_FIFO_DEPTH ( 32 ),
      .C_VFBC5_CMD_AFULL_COUNT ( 3 ),
      .C_VFBC5_RDWD_DATA_WIDTH ( 32 ),
      .C_VFBC5_RDWD_FIFO_DEPTH ( 1024 ),
      .C_VFBC5_RD_AEMPTY_WD_AFULL_COUNT ( 3 ),
      .C_PI5_RD_FIFO_TYPE ( "BRAM" ),
      .C_PI5_WR_FIFO_TYPE ( "BRAM" ),
      .C_PI5_ADDRACK_PIPELINE ( 1 ),
      .C_PI5_RD_FIFO_APP_PIPELINE ( 1 ),
      .C_PI5_RD_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI5_WR_FIFO_APP_PIPELINE ( 1 ),
      .C_PI5_WR_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI5_PM_USED ( 1 ),
      .C_PI5_PM_DC_CNTR ( 1 ),
      .C_PIM6_BASEADDR ( 32'hFFFFFFFF ),
      .C_PIM6_HIGHADDR ( 32'h00000000 ),
      .C_PIM6_OFFSET ( 32'h00000000 ),
      .C_PIM6_DATA_WIDTH ( 64 ),
      .C_PIM6_BASETYPE ( 0 ),
      .C_PIM6_SUBTYPE ( "INACTIVE" ),
      .C_XCL6_LINESIZE ( 4 ),
      .C_XCL6_WRITEXFER ( 1 ),
      .C_XCL6_PIPE_STAGES ( 2 ),
      .C_XCL6_B_IN_USE ( 0 ),
      .C_PIM6_B_SUBTYPE ( "INACTIVE" ),
      .C_XCL6_B_LINESIZE ( 4 ),
      .C_XCL6_B_WRITEXFER ( 1 ),
      .C_SPLB6_AWIDTH ( 32 ),
      .C_SPLB6_DWIDTH ( 64 ),
      .C_SPLB6_NATIVE_DWIDTH ( 64 ),
      .C_SPLB6_NUM_MASTERS ( 1 ),
      .C_SPLB6_MID_WIDTH ( 1 ),
      .C_SPLB6_P2P ( 1 ),
      .C_SPLB6_SUPPORT_BURSTS ( 0 ),
      .C_SPLB6_SMALLEST_MASTER ( 32 ),
      .C_SDMA_CTRL6_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL6_HIGHADDR ( 32'h00000000 ),
      .C_SDMA_CTRL6_AWIDTH ( 32 ),
      .C_SDMA_CTRL6_DWIDTH ( 64 ),
      .C_SDMA_CTRL6_NATIVE_DWIDTH ( 32 ),
      .C_SDMA_CTRL6_NUM_MASTERS ( 1 ),
      .C_SDMA_CTRL6_MID_WIDTH ( 1 ),
      .C_SDMA_CTRL6_P2P ( 1 ),
      .C_SDMA_CTRL6_SUPPORT_BURSTS ( 0 ),
      .C_SDMA_CTRL6_SMALLEST_MASTER ( 32 ),
      .C_SDMA6_COMPLETED_ERR_TX ( 1 ),
      .C_SDMA6_COMPLETED_ERR_RX ( 1 ),
      .C_SDMA6_PRESCALAR ( 1023 ),
      .C_SDMA6_PI2LL_CLK_RATIO ( 1 ),
      .C_PPC440MC6_BURST_LENGTH ( 4 ),
      .C_PPC440MC6_PIPE_STAGES ( 1 ),
      .C_VFBC6_CMD_FIFO_DEPTH ( 32 ),
      .C_VFBC6_CMD_AFULL_COUNT ( 3 ),
      .C_VFBC6_RDWD_DATA_WIDTH ( 32 ),
      .C_VFBC6_RDWD_FIFO_DEPTH ( 1024 ),
      .C_VFBC6_RD_AEMPTY_WD_AFULL_COUNT ( 3 ),
      .C_PI6_RD_FIFO_TYPE ( "BRAM" ),
      .C_PI6_WR_FIFO_TYPE ( "BRAM" ),
      .C_PI6_ADDRACK_PIPELINE ( 1 ),
      .C_PI6_RD_FIFO_APP_PIPELINE ( 1 ),
      .C_PI6_RD_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI6_WR_FIFO_APP_PIPELINE ( 1 ),
      .C_PI6_WR_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI6_PM_USED ( 1 ),
      .C_PI6_PM_DC_CNTR ( 1 ),
      .C_PIM7_BASEADDR ( 32'hFFFFFFFF ),
      .C_PIM7_HIGHADDR ( 32'h00000000 ),
      .C_PIM7_OFFSET ( 32'h00000000 ),
      .C_PIM7_DATA_WIDTH ( 64 ),
      .C_PIM7_BASETYPE ( 0 ),
      .C_PIM7_SUBTYPE ( "INACTIVE" ),
      .C_XCL7_LINESIZE ( 4 ),
      .C_XCL7_WRITEXFER ( 1 ),
      .C_XCL7_PIPE_STAGES ( 2 ),
      .C_XCL7_B_IN_USE ( 0 ),
      .C_PIM7_B_SUBTYPE ( "INACTIVE" ),
      .C_XCL7_B_LINESIZE ( 4 ),
      .C_XCL7_B_WRITEXFER ( 1 ),
      .C_SPLB7_AWIDTH ( 32 ),
      .C_SPLB7_DWIDTH ( 64 ),
      .C_SPLB7_NATIVE_DWIDTH ( 64 ),
      .C_SPLB7_NUM_MASTERS ( 1 ),
      .C_SPLB7_MID_WIDTH ( 1 ),
      .C_SPLB7_P2P ( 1 ),
      .C_SPLB7_SUPPORT_BURSTS ( 0 ),
      .C_SPLB7_SMALLEST_MASTER ( 32 ),
      .C_SDMA_CTRL7_BASEADDR ( 32'hFFFFFFFF ),
      .C_SDMA_CTRL7_HIGHADDR ( 32'h00000000 ),
      .C_SDMA_CTRL7_AWIDTH ( 32 ),
      .C_SDMA_CTRL7_DWIDTH ( 64 ),
      .C_SDMA_CTRL7_NATIVE_DWIDTH ( 32 ),
      .C_SDMA_CTRL7_NUM_MASTERS ( 1 ),
      .C_SDMA_CTRL7_MID_WIDTH ( 1 ),
      .C_SDMA_CTRL7_P2P ( 1 ),
      .C_SDMA_CTRL7_SUPPORT_BURSTS ( 0 ),
      .C_SDMA_CTRL7_SMALLEST_MASTER ( 32 ),
      .C_SDMA7_COMPLETED_ERR_TX ( 1 ),
      .C_SDMA7_COMPLETED_ERR_RX ( 1 ),
      .C_SDMA7_PRESCALAR ( 1023 ),
      .C_SDMA7_PI2LL_CLK_RATIO ( 1 ),
      .C_PPC440MC7_BURST_LENGTH ( 4 ),
      .C_PPC440MC7_PIPE_STAGES ( 1 ),
      .C_VFBC7_CMD_FIFO_DEPTH ( 32 ),
      .C_VFBC7_CMD_AFULL_COUNT ( 3 ),
      .C_VFBC7_RDWD_DATA_WIDTH ( 32 ),
      .C_VFBC7_RDWD_FIFO_DEPTH ( 1024 ),
      .C_VFBC7_RD_AEMPTY_WD_AFULL_COUNT ( 3 ),
      .C_PI7_RD_FIFO_TYPE ( "BRAM" ),
      .C_PI7_WR_FIFO_TYPE ( "BRAM" ),
      .C_PI7_ADDRACK_PIPELINE ( 1 ),
      .C_PI7_RD_FIFO_APP_PIPELINE ( 1 ),
      .C_PI7_RD_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI7_WR_FIFO_APP_PIPELINE ( 1 ),
      .C_PI7_WR_FIFO_MEM_PIPELINE ( 1 ),
      .C_PI7_PM_USED ( 1 ),
      .C_PI7_PM_DC_CNTR ( 1 ),
      .C_WR_TRAINING_PORT ( 0 ),
      .C_ARB_BRAM_INIT_00 ( 256'b0000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111010001000011000000001111111111110010000110100000000011111111111100001101000100000000111111111111011010001000 ),
      .C_ARB_BRAM_INIT_01 ( 256'b0000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111111111111111 ),
      .C_ARB_BRAM_INIT_02 ( 256'b0000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111011010001000000000001111111111110110100010000000000011111111111101101000100000000000111111111111011010001000 ),
      .C_ARB_BRAM_INIT_03 ( 256'b0000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111111111111111 ),
      .C_ARB_BRAM_INIT_04 ( 256'b0000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111010001000011000000001111111111110010000110100000000011111111111100001101000100000000111111111111011010001000 ),
      .C_ARB_BRAM_INIT_05 ( 256'b0000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111111111111111 ),
      .C_ARB_BRAM_INIT_06 ( 256'b0000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111011010001000000000001111111111110110100010000000000011111111111101101000100000000000111111111111011010001000 ),
      .C_ARB_BRAM_INIT_07 ( 256'b0000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111111111111111000000001111111111111111111111110000000011111111111111111111111100000000111111111111111111111111 ),
      .C_NCK_PER_CLK ( 1 ),
      .C_TWR ( 15000 ),
      .C_CTRL_COMPLETE_INDEX ( 0 ),
      .C_CTRL_IS_WRITE_INDEX ( 1 ),
      .C_CTRL_PHYIF_RAS_N_INDEX ( 2 ),
      .C_CTRL_PHYIF_CAS_N_INDEX ( 3 ),
      .C_CTRL_PHYIF_WE_N_INDEX ( 4 ),
      .C_CTRL_RMW_INDEX ( 6 ),
      .C_CTRL_SKIP_0_INDEX ( 7 ),
      .C_CTRL_PHYIF_DQS_O_INDEX ( 8 ),
      .C_CTRL_SKIP_1_INDEX ( 9 ),
      .C_CTRL_DP_RDFIFO_PUSH_INDEX ( 10 ),
      .C_CTRL_SKIP_2_INDEX ( 11 ),
      .C_CTRL_AP_COL_CNT_LOAD_INDEX ( 12 ),
      .C_CTRL_AP_COL_CNT_ENABLE_INDEX ( 13 ),
      .C_CTRL_AP_PRECHARGE_ADDR10_INDEX ( 14 ),
      .C_CTRL_AP_ROW_COL_SEL_INDEX ( 15 ),
      .C_CTRL_PHYIF_FORCE_DM_INDEX ( 16 ),
      .C_CTRL_REPEAT4_INDEX ( 17 ),
      .C_CTRL_DFI_RAS_N_0_INDEX ( 0 ),
      .C_CTRL_DFI_CAS_N_0_INDEX ( 0 ),
      .C_CTRL_DFI_WE_N_0_INDEX ( 0 ),
      .C_CTRL_DFI_RAS_N_1_INDEX ( 0 ),
      .C_CTRL_DFI_CAS_N_1_INDEX ( 0 ),
      .C_CTRL_DFI_WE_N_1_INDEX ( 0 ),
      .C_CTRL_DP_WRFIFO_POP_INDEX ( 0 ),
      .C_CTRL_DFI_WRDATA_EN_INDEX ( 0 ),
      .C_CTRL_DFI_RDDATA_EN_INDEX ( 0 ),
      .C_CTRL_AP_OTF_ADDR12_INDEX ( 0 ),
      .C_CTRL_ARB_RDMODWR_DELAY ( 3 ),
      .C_CTRL_AP_COL_DELAY ( 1 ),
      .C_CTRL_AP_PI_ADDR_CE_DELAY ( 0 ),
      .C_CTRL_AP_PORT_SELECT_DELAY ( 0 ),
      .C_CTRL_AP_PIPELINE1_CE_DELAY ( 0 ),
      .C_CTRL_DP_LOAD_RDWDADDR_DELAY ( 2 ),
      .C_CTRL_DP_RDFIFO_WHICHPORT_DELAY ( 12 ),
      .C_CTRL_DP_SIZE_DELAY ( 2 ),
      .C_CTRL_DP_WRFIFO_WHICHPORT_DELAY ( 4 ),
      .C_CTRL_PHYIF_DUMMYREADSTART_DELAY ( 5 ),
      .C_CTRL_Q0_DELAY ( 1 ),
      .C_CTRL_Q1_DELAY ( 1 ),
      .C_CTRL_Q2_DELAY ( 2 ),
      .C_CTRL_Q3_DELAY ( 2 ),
      .C_CTRL_Q4_DELAY ( 2 ),
      .C_CTRL_Q5_DELAY ( 0 ),
      .C_CTRL_Q6_DELAY ( 5 ),
      .C_CTRL_Q7_DELAY ( 1 ),
      .C_CTRL_Q8_DELAY ( 3 ),
      .C_CTRL_Q9_DELAY ( 1 ),
      .C_CTRL_Q10_DELAY ( 2 ),
      .C_CTRL_Q11_DELAY ( 1 ),
      .C_CTRL_Q12_DELAY ( 1 ),
      .C_CTRL_Q13_DELAY ( 1 ),
      .C_CTRL_Q14_DELAY ( 1 ),
      .C_CTRL_Q15_DELAY ( 1 ),
      .C_CTRL_Q16_DELAY ( 2 ),
      .C_CTRL_Q17_DELAY ( 1 ),
      .C_CTRL_Q18_DELAY ( 0 ),
      .C_CTRL_Q19_DELAY ( 0 ),
      .C_CTRL_Q20_DELAY ( 0 ),
      .C_CTRL_Q21_DELAY ( 0 ),
      .C_CTRL_Q22_DELAY ( 0 ),
      .C_CTRL_Q23_DELAY ( 0 ),
      .C_CTRL_Q24_DELAY ( 0 ),
      .C_CTRL_Q25_DELAY ( 0 ),
      .C_CTRL_Q26_DELAY ( 0 ),
      .C_CTRL_Q27_DELAY ( 0 ),
      .C_CTRL_Q28_DELAY ( 0 ),
      .C_CTRL_Q29_DELAY ( 0 ),
      .C_CTRL_Q30_DELAY ( 0 ),
      .C_CTRL_Q31_DELAY ( 0 ),
      .C_CTRL_Q32_DELAY ( 0 ),
      .C_CTRL_Q33_DELAY ( 0 ),
      .C_CTRL_Q34_DELAY ( 0 ),
      .C_CTRL_Q35_DELAY ( 0 ),
      .C_SKIP_1_VALUE ( 'h001 ),
      .C_SKIP_2_VALUE ( 'h001 ),
      .C_SKIP_3_VALUE ( 'h001 ),
      .C_SKIP_4_VALUE ( 'h001 ),
      .C_SKIP_5_VALUE ( 'h001 ),
      .C_SKIP_6_VALUE ( 'h001 ),
      .C_SKIP_7_VALUE ( 'h001 ),
      .C_B16_REPEAT_CNT ( 0 ),
      .C_B32_REPEAT_CNT ( 0 ),
      .C_B64_REPEAT_CNT ( 2 ),
      .C_ZQCS_REPEAT_CNT ( 0 ),
      .C_BASEADDR_CTRL0 ( 12'h000 ),
      .C_HIGHADDR_CTRL0 ( 12'h00e ),
      .C_BASEADDR_CTRL1 ( 12'h00f ),
      .C_HIGHADDR_CTRL1 ( 12'h01a ),
      .C_BASEADDR_CTRL2 ( 12'h01b ),
      .C_HIGHADDR_CTRL2 ( 12'h029 ),
      .C_BASEADDR_CTRL3 ( 12'h02a ),
      .C_HIGHADDR_CTRL3 ( 12'h035 ),
      .C_BASEADDR_CTRL4 ( 12'h036 ),
      .C_HIGHADDR_CTRL4 ( 12'h044 ),
      .C_BASEADDR_CTRL5 ( 12'h045 ),
      .C_HIGHADDR_CTRL5 ( 12'h050 ),
      .C_BASEADDR_CTRL6 ( 12'h051 ),
      .C_HIGHADDR_CTRL6 ( 12'h05f ),
      .C_BASEADDR_CTRL7 ( 12'h060 ),
      .C_HIGHADDR_CTRL7 ( 12'h06b ),
      .C_BASEADDR_CTRL8 ( 12'h06c ),
      .C_HIGHADDR_CTRL8 ( 12'h07c ),
      .C_BASEADDR_CTRL9 ( 12'h07d ),
      .C_HIGHADDR_CTRL9 ( 12'h088 ),
      .C_BASEADDR_CTRL10 ( 12'h089 ),
      .C_HIGHADDR_CTRL10 ( 12'h09d ),
      .C_BASEADDR_CTRL11 ( 12'h09e ),
      .C_HIGHADDR_CTRL11 ( 12'h0ac ),
      .C_BASEADDR_CTRL12 ( 12'h0ad ),
      .C_HIGHADDR_CTRL12 ( 12'h0c1 ),
      .C_BASEADDR_CTRL13 ( 12'h0c2 ),
      .C_HIGHADDR_CTRL13 ( 12'h0d0 ),
      .C_BASEADDR_CTRL14 ( 12'h0d1 ),
      .C_HIGHADDR_CTRL14 ( 12'h0ee ),
      .C_BASEADDR_CTRL15 ( 12'h0ef ),
      .C_HIGHADDR_CTRL15 ( 12'h0f0 ),
      .C_BASEADDR_CTRL16 ( 12'h0d9 ),
      .C_HIGHADDR_CTRL16 ( 12'h0da ),
      .C_CTRL_BRAM_INIT_3F ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_3E ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_3D ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_3C ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_3B ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_3A ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_39 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_38 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_37 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_36 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_35 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_34 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_33 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_32 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_31 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_30 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_2F ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_2E ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_2D ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_2C ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_2B ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_2A ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_29 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_28 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_27 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_26 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_25 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_24 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_23 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_22 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_21 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_20 ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_1F ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC000002FC ),
      .C_CTRL_BRAM_INIT_1E ( 256'h000002FC000002FC000002FC000002FC000002FC000002FC000002FC0000001C ),
      .C_CTRL_BRAM_INIT_1D ( 256'h0000001C0000001C0000001C0000001C0000001C0000001C0000001D0000001C ),
      .C_CTRL_BRAM_INIT_1C ( 256'h0000001C0000001C0000001C0000001C0000001C0000001C0000001C0000001C ),
      .C_CTRL_BRAM_INIT_1B ( 256'h0000001C0000001C0000001C0000001C0000001C0000001C0000001C0000001C ),
      .C_CTRL_BRAM_INIT_1A ( 256'h0000001C0000001C000000100000001C0000001C0000001C000040080000001C ),
      .C_CTRL_BRAM_INIT_19 ( 256'h0000001C0000001C000040080000001C000024150000041C000024140000041C ),
      .C_CTRL_BRAM_INIT_18 ( 256'h000024140002041C000024140000141C0000001C000080180000001E0000001E ),
      .C_CTRL_BRAM_INIT_17 ( 256'h0000001E0000001E0000400A0000001F0000001E0000001E0000001E0000201E ),
      .C_CTRL_BRAM_INIT_16 ( 256'h0000001E000020060000011E000021060000011E000021060002011E00002106 ),
      .C_CTRL_BRAM_INIT_15 ( 256'h0000111E0000011E0000801A0000001C0000001C0000001C000040080000001C ),
      .C_CTRL_BRAM_INIT_14 ( 256'h000024150000041C000024140000041C000024140002041C000024140000141C ),
      .C_CTRL_BRAM_INIT_13 ( 256'h0000001C000080180000001E0000001E0000001E0000001E0000400A0000001F ),
      .C_CTRL_BRAM_INIT_12 ( 256'h0000001E0000001E0000001E0000201E0000001E000020060000011E00002106 ),
      .C_CTRL_BRAM_INIT_11 ( 256'h0000011E000021060002011E000021060000111E0000011E0000801A0000001C ),
      .C_CTRL_BRAM_INIT_10 ( 256'h0000001C0000001C000040080000001C0000001D000024140000041C00002414 ),
      .C_CTRL_BRAM_INIT_0F ( 256'h0000141C0000001C000080180000001E0000001E0000001E0000001E0000400A ),
      .C_CTRL_BRAM_INIT_0E ( 256'h0000001F0000001E0000001E0000001E0000201E0000001E000020060000011E ),
      .C_CTRL_BRAM_INIT_0D ( 256'h000021060000111E0000011E0000801A0000001C0000001C0000001C00004008 ),
      .C_CTRL_BRAM_INIT_0C ( 256'h0000001C0000001D0000001C0000001C000024140000141C0000001C00008018 ),
      .C_CTRL_BRAM_INIT_0B ( 256'h0000001E0000001E0000001E0000001E0000400A0000001F0000001E0000001E ),
      .C_CTRL_BRAM_INIT_0A ( 256'h0000001E0000201E0000001E000020060000111E0000011E0000801A0000001C ),
      .C_CTRL_BRAM_INIT_09 ( 256'h0000001C0000001C000040080000001C0000001D0000001C0000001C00002014 ),
      .C_CTRL_BRAM_INIT_08 ( 256'h0000141C0000001C000080180000001E0000001E0000001E0000001E0000400A ),
      .C_CTRL_BRAM_INIT_07 ( 256'h0000001F0000001E0000001E0000001E0000001E0000001E000020060001111E ),
      .C_CTRL_BRAM_INIT_06 ( 256'h0000011E0000801A0000001C0000001C0000001C000040080000001C0000001D ),
      .C_CTRL_BRAM_INIT_05 ( 256'h0000001C0000001C000020140000141C0000001C000080180000001E0000001E ),
      .C_CTRL_BRAM_INIT_04 ( 256'h0000001E0000001E0000400A0000001F0000001E0000001E0000001E0000001E ),
      .C_CTRL_BRAM_INIT_03 ( 256'h0000001E000020060001111E0000011E0000801A0000001C0000001C0000001C ),
      .C_CTRL_BRAM_INIT_02 ( 256'h000040080000001C0000001D0000001C0000001C000020140000141C0000001C ),
      .C_CTRL_BRAM_INIT_01 ( 256'h000080180000001E0000001E0000001E0000001E0000400A0000001F0000001E ),
      .C_CTRL_BRAM_INIT_00 ( 256'h0000001E0000001E0000001E0000001E000020060001111E0000011E0000801A ),
      .C_CTRL_BRAM_SRVAL ( 36'h0000002FC ),
      .C_CTRL_BRAM_INITP_07 ( 256'h0000000000000000000000000000000000000000000000000000000000000000 ),
      .C_CTRL_BRAM_INITP_06 ( 256'h0000000000000000000000000000000000000000000000000000000000000000 ),
      .C_CTRL_BRAM_INITP_05 ( 256'h0000000000000000000000000000000000000000000000000000000000000000 ),
      .C_CTRL_BRAM_INITP_04 ( 256'h0000000000000000000000000000000000000000000000000000000000000000 ),
      .C_CTRL_BRAM_INITP_03 ( 256'h0000000000000000000000000000000000000000000000000000000000000000 ),
      .C_CTRL_BRAM_INITP_02 ( 256'h0000000000000000000000000000000000000000000000000000000000000000 ),
      .C_CTRL_BRAM_INITP_01 ( 256'h0000000000000000000000000000000000000000000000000000000000000000 ),
      .C_CTRL_BRAM_INITP_00 ( 256'h0000000000000000000000000000000000000000000000000000000000000000 )
    )
    ppc440mc_ddr2_0 (
      .FSL0_M_Clk ( FSL0_M_Clk ),
      .FSL0_M_Write ( FSL0_M_Write ),
      .FSL0_M_Data ( FSL0_M_Data ),
      .FSL0_M_Control ( FSL0_M_Control ),
      .FSL0_M_Full ( FSL0_M_Full ),
      .FSL0_S_Clk ( FSL0_S_Clk ),
      .FSL0_S_Read ( FSL0_S_Read ),
      .FSL0_S_Data ( FSL0_S_Data ),
      .FSL0_S_Control ( FSL0_S_Control ),
      .FSL0_S_Exists ( FSL0_S_Exists ),
      .FSL0_B_M_Clk ( FSL0_B_M_Clk ),
      .FSL0_B_M_Write ( FSL0_B_M_Write ),
      .FSL0_B_M_Data ( FSL0_B_M_Data ),
      .FSL0_B_M_Control ( FSL0_B_M_Control ),
      .FSL0_B_M_Full ( FSL0_B_M_Full ),
      .FSL0_B_S_Clk ( FSL0_B_S_Clk ),
      .FSL0_B_S_Read ( FSL0_B_S_Read ),
      .FSL0_B_S_Data ( FSL0_B_S_Data ),
      .FSL0_B_S_Control ( FSL0_B_S_Control ),
      .FSL0_B_S_Exists ( FSL0_B_S_Exists ),
      .SPLB0_Clk ( SPLB0_Clk ),
      .SPLB0_Rst ( SPLB0_Rst ),
      .SPLB0_PLB_ABus ( SPLB0_PLB_ABus ),
      .SPLB0_PLB_PAValid ( SPLB0_PLB_PAValid ),
      .SPLB0_PLB_SAValid ( SPLB0_PLB_SAValid ),
      .SPLB0_PLB_masterID ( SPLB0_PLB_masterID ),
      .SPLB0_PLB_RNW ( SPLB0_PLB_RNW ),
      .SPLB0_PLB_BE ( SPLB0_PLB_BE ),
      .SPLB0_PLB_UABus ( SPLB0_PLB_UABus ),
      .SPLB0_PLB_rdPrim ( SPLB0_PLB_rdPrim ),
      .SPLB0_PLB_wrPrim ( SPLB0_PLB_wrPrim ),
      .SPLB0_PLB_abort ( SPLB0_PLB_abort ),
      .SPLB0_PLB_busLock ( SPLB0_PLB_busLock ),
      .SPLB0_PLB_MSize ( SPLB0_PLB_MSize ),
      .SPLB0_PLB_size ( SPLB0_PLB_size ),
      .SPLB0_PLB_type ( SPLB0_PLB_type ),
      .SPLB0_PLB_lockErr ( SPLB0_PLB_lockErr ),
      .SPLB0_PLB_wrPendReq ( SPLB0_PLB_wrPendReq ),
      .SPLB0_PLB_wrPendPri ( SPLB0_PLB_wrPendPri ),
      .SPLB0_PLB_rdPendReq ( SPLB0_PLB_rdPendReq ),
      .SPLB0_PLB_rdPendPri ( SPLB0_PLB_rdPendPri ),
      .SPLB0_PLB_reqPri ( SPLB0_PLB_reqPri ),
      .SPLB0_PLB_TAttribute ( SPLB0_PLB_TAttribute ),
      .SPLB0_PLB_rdBurst ( SPLB0_PLB_rdBurst ),
      .SPLB0_PLB_wrBurst ( SPLB0_PLB_wrBurst ),
      .SPLB0_PLB_wrDBus ( SPLB0_PLB_wrDBus ),
      .SPLB0_Sl_addrAck ( SPLB0_Sl_addrAck ),
      .SPLB0_Sl_SSize ( SPLB0_Sl_SSize ),
      .SPLB0_Sl_wait ( SPLB0_Sl_wait ),
      .SPLB0_Sl_rearbitrate ( SPLB0_Sl_rearbitrate ),
      .SPLB0_Sl_wrDAck ( SPLB0_Sl_wrDAck ),
      .SPLB0_Sl_wrComp ( SPLB0_Sl_wrComp ),
      .SPLB0_Sl_wrBTerm ( SPLB0_Sl_wrBTerm ),
      .SPLB0_Sl_rdDBus ( SPLB0_Sl_rdDBus ),
      .SPLB0_Sl_rdWdAddr ( SPLB0_Sl_rdWdAddr ),
      .SPLB0_Sl_rdDAck ( SPLB0_Sl_rdDAck ),
      .SPLB0_Sl_rdComp ( SPLB0_Sl_rdComp ),
      .SPLB0_Sl_rdBTerm ( SPLB0_Sl_rdBTerm ),
      .SPLB0_Sl_MBusy ( SPLB0_Sl_MBusy ),
      .SPLB0_Sl_MRdErr ( SPLB0_Sl_MRdErr ),
      .SPLB0_Sl_MWrErr ( SPLB0_Sl_MWrErr ),
      .SPLB0_Sl_MIRQ ( SPLB0_Sl_MIRQ ),
      .SDMA0_Clk ( SDMA0_Clk ),
      .SDMA0_Rx_IntOut ( SDMA0_Rx_IntOut ),
      .SDMA0_Tx_IntOut ( SDMA0_Tx_IntOut ),
      .SDMA0_RstOut ( SDMA0_RstOut ),
      .SDMA0_TX_D ( SDMA0_TX_D ),
      .SDMA0_TX_Rem ( SDMA0_TX_Rem ),
      .SDMA0_TX_SOF ( SDMA0_TX_SOF ),
      .SDMA0_TX_EOF ( SDMA0_TX_EOF ),
      .SDMA0_TX_SOP ( SDMA0_TX_SOP ),
      .SDMA0_TX_EOP ( SDMA0_TX_EOP ),
      .SDMA0_TX_Src_Rdy ( SDMA0_TX_Src_Rdy ),
      .SDMA0_TX_Dst_Rdy ( SDMA0_TX_Dst_Rdy ),
      .SDMA0_RX_D ( SDMA0_RX_D ),
      .SDMA0_RX_Rem ( SDMA0_RX_Rem ),
      .SDMA0_RX_SOF ( SDMA0_RX_SOF ),
      .SDMA0_RX_EOF ( SDMA0_RX_EOF ),
      .SDMA0_RX_SOP ( SDMA0_RX_SOP ),
      .SDMA0_RX_EOP ( SDMA0_RX_EOP ),
      .SDMA0_RX_Src_Rdy ( SDMA0_RX_Src_Rdy ),
      .SDMA0_RX_Dst_Rdy ( SDMA0_RX_Dst_Rdy ),
      .SDMA_CTRL0_Clk ( SDMA_CTRL0_Clk ),
      .SDMA_CTRL0_Rst ( SDMA_CTRL0_Rst ),
      .SDMA_CTRL0_PLB_ABus ( SDMA_CTRL0_PLB_ABus ),
      .SDMA_CTRL0_PLB_PAValid ( SDMA_CTRL0_PLB_PAValid ),
      .SDMA_CTRL0_PLB_SAValid ( SDMA_CTRL0_PLB_SAValid ),
      .SDMA_CTRL0_PLB_masterID ( SDMA_CTRL0_PLB_masterID ),
      .SDMA_CTRL0_PLB_RNW ( SDMA_CTRL0_PLB_RNW ),
      .SDMA_CTRL0_PLB_BE ( SDMA_CTRL0_PLB_BE ),
      .SDMA_CTRL0_PLB_UABus ( SDMA_CTRL0_PLB_UABus ),
      .SDMA_CTRL0_PLB_rdPrim ( SDMA_CTRL0_PLB_rdPrim ),
      .SDMA_CTRL0_PLB_wrPrim ( SDMA_CTRL0_PLB_wrPrim ),
      .SDMA_CTRL0_PLB_abort ( SDMA_CTRL0_PLB_abort ),
      .SDMA_CTRL0_PLB_busLock ( SDMA_CTRL0_PLB_busLock ),
      .SDMA_CTRL0_PLB_MSize ( SDMA_CTRL0_PLB_MSize ),
      .SDMA_CTRL0_PLB_size ( SDMA_CTRL0_PLB_size ),
      .SDMA_CTRL0_PLB_type ( SDMA_CTRL0_PLB_type ),
      .SDMA_CTRL0_PLB_lockErr ( SDMA_CTRL0_PLB_lockErr ),
      .SDMA_CTRL0_PLB_wrPendReq ( SDMA_CTRL0_PLB_wrPendReq ),
      .SDMA_CTRL0_PLB_wrPendPri ( SDMA_CTRL0_PLB_wrPendPri ),
      .SDMA_CTRL0_PLB_rdPendReq ( SDMA_CTRL0_PLB_rdPendReq ),
      .SDMA_CTRL0_PLB_rdPendPri ( SDMA_CTRL0_PLB_rdPendPri ),
      .SDMA_CTRL0_PLB_reqPri ( SDMA_CTRL0_PLB_reqPri ),
      .SDMA_CTRL0_PLB_TAttribute ( SDMA_CTRL0_PLB_TAttribute ),
      .SDMA_CTRL0_PLB_rdBurst ( SDMA_CTRL0_PLB_rdBurst ),
      .SDMA_CTRL0_PLB_wrBurst ( SDMA_CTRL0_PLB_wrBurst ),
      .SDMA_CTRL0_PLB_wrDBus ( SDMA_CTRL0_PLB_wrDBus ),
      .SDMA_CTRL0_Sl_addrAck ( SDMA_CTRL0_Sl_addrAck ),
      .SDMA_CTRL0_Sl_SSize ( SDMA_CTRL0_Sl_SSize ),
      .SDMA_CTRL0_Sl_wait ( SDMA_CTRL0_Sl_wait ),
      .SDMA_CTRL0_Sl_rearbitrate ( SDMA_CTRL0_Sl_rearbitrate ),
      .SDMA_CTRL0_Sl_wrDAck ( SDMA_CTRL0_Sl_wrDAck ),
      .SDMA_CTRL0_Sl_wrComp ( SDMA_CTRL0_Sl_wrComp ),
      .SDMA_CTRL0_Sl_wrBTerm ( SDMA_CTRL0_Sl_wrBTerm ),
      .SDMA_CTRL0_Sl_rdDBus ( SDMA_CTRL0_Sl_rdDBus ),
      .SDMA_CTRL0_Sl_rdWdAddr ( SDMA_CTRL0_Sl_rdWdAddr ),
      .SDMA_CTRL0_Sl_rdDAck ( SDMA_CTRL0_Sl_rdDAck ),
      .SDMA_CTRL0_Sl_rdComp ( SDMA_CTRL0_Sl_rdComp ),
      .SDMA_CTRL0_Sl_rdBTerm ( SDMA_CTRL0_Sl_rdBTerm ),
      .SDMA_CTRL0_Sl_MBusy ( SDMA_CTRL0_Sl_MBusy ),
      .SDMA_CTRL0_Sl_MRdErr ( SDMA_CTRL0_Sl_MRdErr ),
      .SDMA_CTRL0_Sl_MWrErr ( SDMA_CTRL0_Sl_MWrErr ),
      .SDMA_CTRL0_Sl_MIRQ ( SDMA_CTRL0_Sl_MIRQ ),
      .PIM0_Addr ( PIM0_Addr ),
      .PIM0_AddrReq ( PIM0_AddrReq ),
      .PIM0_AddrAck ( PIM0_AddrAck ),
      .PIM0_RNW ( PIM0_RNW ),
      .PIM0_Size ( PIM0_Size ),
      .PIM0_RdModWr ( PIM0_RdModWr ),
      .PIM0_WrFIFO_Data ( PIM0_WrFIFO_Data ),
      .PIM0_WrFIFO_BE ( PIM0_WrFIFO_BE ),
      .PIM0_WrFIFO_Push ( PIM0_WrFIFO_Push ),
      .PIM0_RdFIFO_Data ( PIM0_RdFIFO_Data ),
      .PIM0_RdFIFO_Pop ( PIM0_RdFIFO_Pop ),
      .PIM0_RdFIFO_RdWdAddr ( PIM0_RdFIFO_RdWdAddr ),
      .PIM0_WrFIFO_Empty ( PIM0_WrFIFO_Empty ),
      .PIM0_WrFIFO_AlmostFull ( PIM0_WrFIFO_AlmostFull ),
      .PIM0_WrFIFO_Flush ( PIM0_WrFIFO_Flush ),
      .PIM0_RdFIFO_Empty ( PIM0_RdFIFO_Empty ),
      .PIM0_RdFIFO_Flush ( PIM0_RdFIFO_Flush ),
      .PIM0_RdFIFO_Latency ( PIM0_RdFIFO_Latency ),
      .PIM0_InitDone ( PIM0_InitDone ),
      .PPC440MC0_MIMCReadNotWrite ( PPC440MC0_MIMCReadNotWrite ),
      .PPC440MC0_MIMCAddress ( PPC440MC0_MIMCAddress ),
      .PPC440MC0_MIMCAddressValid ( PPC440MC0_MIMCAddressValid ),
      .PPC440MC0_MIMCWriteData ( PPC440MC0_MIMCWriteData ),
      .PPC440MC0_MIMCWriteDataValid ( PPC440MC0_MIMCWriteDataValid ),
      .PPC440MC0_MIMCByteEnable ( PPC440MC0_MIMCByteEnable ),
      .PPC440MC0_MIMCBankConflict ( PPC440MC0_MIMCBankConflict ),
      .PPC440MC0_MIMCRowConflict ( PPC440MC0_MIMCRowConflict ),
      .PPC440MC0_MCMIReadData ( PPC440MC0_MCMIReadData ),
      .PPC440MC0_MCMIReadDataValid ( PPC440MC0_MCMIReadDataValid ),
      .PPC440MC0_MCMIReadDataErr ( PPC440MC0_MCMIReadDataErr ),
      .PPC440MC0_MCMIAddrReadyToAccept ( PPC440MC0_MCMIAddrReadyToAccept ),
      .VFBC0_Cmd_Clk ( VFBC0_Cmd_Clk ),
      .VFBC0_Cmd_Reset ( VFBC0_Cmd_Reset ),
      .VFBC0_Cmd_Data ( VFBC0_Cmd_Data ),
      .VFBC0_Cmd_Write ( VFBC0_Cmd_Write ),
      .VFBC0_Cmd_End ( VFBC0_Cmd_End ),
      .VFBC0_Cmd_Full ( VFBC0_Cmd_Full ),
      .VFBC0_Cmd_Almost_Full ( VFBC0_Cmd_Almost_Full ),
      .VFBC0_Cmd_Idle ( VFBC0_Cmd_Idle ),
      .VFBC0_Wd_Clk ( VFBC0_Wd_Clk ),
      .VFBC0_Wd_Reset ( VFBC0_Wd_Reset ),
      .VFBC0_Wd_Write ( VFBC0_Wd_Write ),
      .VFBC0_Wd_End_Burst ( VFBC0_Wd_End_Burst ),
      .VFBC0_Wd_Flush ( VFBC0_Wd_Flush ),
      .VFBC0_Wd_Data ( VFBC0_Wd_Data ),
      .VFBC0_Wd_Data_BE ( VFBC0_Wd_Data_BE ),
      .VFBC0_Wd_Full ( VFBC0_Wd_Full ),
      .VFBC0_Wd_Almost_Full ( VFBC0_Wd_Almost_Full ),
      .VFBC0_Rd_Clk ( VFBC0_Rd_Clk ),
      .VFBC0_Rd_Reset ( VFBC0_Rd_Reset ),
      .VFBC0_Rd_Read ( VFBC0_Rd_Read ),
      .VFBC0_Rd_End_Burst ( VFBC0_Rd_End_Burst ),
      .VFBC0_Rd_Flush ( VFBC0_Rd_Flush ),
      .VFBC0_Rd_Data ( VFBC0_Rd_Data ),
      .VFBC0_Rd_Empty ( VFBC0_Rd_Empty ),
      .VFBC0_Rd_Almost_Empty ( VFBC0_Rd_Almost_Empty ),
      .MCB0_cmd_clk ( MCB0_cmd_clk ),
      .MCB0_cmd_en ( MCB0_cmd_en ),
      .MCB0_cmd_instr ( MCB0_cmd_instr ),
      .MCB0_cmd_bl ( MCB0_cmd_bl ),
      .MCB0_cmd_byte_addr ( MCB0_cmd_byte_addr ),
      .MCB0_cmd_empty ( MCB0_cmd_empty ),
      .MCB0_cmd_full ( MCB0_cmd_full ),
      .MCB0_wr_clk ( MCB0_wr_clk ),
      .MCB0_wr_en ( MCB0_wr_en ),
      .MCB0_wr_mask ( MCB0_wr_mask ),
      .MCB0_wr_data ( MCB0_wr_data ),
      .MCB0_wr_full ( MCB0_wr_full ),
      .MCB0_wr_empty ( MCB0_wr_empty ),
      .MCB0_wr_count ( MCB0_wr_count ),
      .MCB0_wr_underrun ( MCB0_wr_underrun ),
      .MCB0_wr_error ( MCB0_wr_error ),
      .MCB0_rd_clk ( MCB0_rd_clk ),
      .MCB0_rd_en ( MCB0_rd_en ),
      .MCB0_rd_data ( MCB0_rd_data ),
      .MCB0_rd_full ( MCB0_rd_full ),
      .MCB0_rd_empty ( MCB0_rd_empty ),
      .MCB0_rd_count ( MCB0_rd_count ),
      .MCB0_rd_overflow ( MCB0_rd_overflow ),
      .MCB0_rd_error ( MCB0_rd_error ),
      .FSL1_M_Clk ( FSL1_M_Clk ),
      .FSL1_M_Write ( FSL1_M_Write ),
      .FSL1_M_Data ( FSL1_M_Data ),
      .FSL1_M_Control ( FSL1_M_Control ),
      .FSL1_M_Full ( FSL1_M_Full ),
      .FSL1_S_Clk ( FSL1_S_Clk ),
      .FSL1_S_Read ( FSL1_S_Read ),
      .FSL1_S_Data ( FSL1_S_Data ),
      .FSL1_S_Control ( FSL1_S_Control ),
      .FSL1_S_Exists ( FSL1_S_Exists ),
      .FSL1_B_M_Clk ( FSL1_B_M_Clk ),
      .FSL1_B_M_Write ( FSL1_B_M_Write ),
      .FSL1_B_M_Data ( FSL1_B_M_Data ),
      .FSL1_B_M_Control ( FSL1_B_M_Control ),
      .FSL1_B_M_Full ( FSL1_B_M_Full ),
      .FSL1_B_S_Clk ( FSL1_B_S_Clk ),
      .FSL1_B_S_Read ( FSL1_B_S_Read ),
      .FSL1_B_S_Data ( FSL1_B_S_Data ),
      .FSL1_B_S_Control ( FSL1_B_S_Control ),
      .FSL1_B_S_Exists ( FSL1_B_S_Exists ),
      .SPLB1_Clk ( SPLB1_Clk ),
      .SPLB1_Rst ( SPLB1_Rst ),
      .SPLB1_PLB_ABus ( SPLB1_PLB_ABus ),
      .SPLB1_PLB_PAValid ( SPLB1_PLB_PAValid ),
      .SPLB1_PLB_SAValid ( SPLB1_PLB_SAValid ),
      .SPLB1_PLB_masterID ( SPLB1_PLB_masterID ),
      .SPLB1_PLB_RNW ( SPLB1_PLB_RNW ),
      .SPLB1_PLB_BE ( SPLB1_PLB_BE ),
      .SPLB1_PLB_UABus ( SPLB1_PLB_UABus ),
      .SPLB1_PLB_rdPrim ( SPLB1_PLB_rdPrim ),
      .SPLB1_PLB_wrPrim ( SPLB1_PLB_wrPrim ),
      .SPLB1_PLB_abort ( SPLB1_PLB_abort ),
      .SPLB1_PLB_busLock ( SPLB1_PLB_busLock ),
      .SPLB1_PLB_MSize ( SPLB1_PLB_MSize ),
      .SPLB1_PLB_size ( SPLB1_PLB_size ),
      .SPLB1_PLB_type ( SPLB1_PLB_type ),
      .SPLB1_PLB_lockErr ( SPLB1_PLB_lockErr ),
      .SPLB1_PLB_wrPendReq ( SPLB1_PLB_wrPendReq ),
      .SPLB1_PLB_wrPendPri ( SPLB1_PLB_wrPendPri ),
      .SPLB1_PLB_rdPendReq ( SPLB1_PLB_rdPendReq ),
      .SPLB1_PLB_rdPendPri ( SPLB1_PLB_rdPendPri ),
      .SPLB1_PLB_reqPri ( SPLB1_PLB_reqPri ),
      .SPLB1_PLB_TAttribute ( SPLB1_PLB_TAttribute ),
      .SPLB1_PLB_rdBurst ( SPLB1_PLB_rdBurst ),
      .SPLB1_PLB_wrBurst ( SPLB1_PLB_wrBurst ),
      .SPLB1_PLB_wrDBus ( SPLB1_PLB_wrDBus ),
      .SPLB1_Sl_addrAck ( SPLB1_Sl_addrAck ),
      .SPLB1_Sl_SSize ( SPLB1_Sl_SSize ),
      .SPLB1_Sl_wait ( SPLB1_Sl_wait ),
      .SPLB1_Sl_rearbitrate ( SPLB1_Sl_rearbitrate ),
      .SPLB1_Sl_wrDAck ( SPLB1_Sl_wrDAck ),
      .SPLB1_Sl_wrComp ( SPLB1_Sl_wrComp ),
      .SPLB1_Sl_wrBTerm ( SPLB1_Sl_wrBTerm ),
      .SPLB1_Sl_rdDBus ( SPLB1_Sl_rdDBus ),
      .SPLB1_Sl_rdWdAddr ( SPLB1_Sl_rdWdAddr ),
      .SPLB1_Sl_rdDAck ( SPLB1_Sl_rdDAck ),
      .SPLB1_Sl_rdComp ( SPLB1_Sl_rdComp ),
      .SPLB1_Sl_rdBTerm ( SPLB1_Sl_rdBTerm ),
      .SPLB1_Sl_MBusy ( SPLB1_Sl_MBusy ),
      .SPLB1_Sl_MRdErr ( SPLB1_Sl_MRdErr ),
      .SPLB1_Sl_MWrErr ( SPLB1_Sl_MWrErr ),
      .SPLB1_Sl_MIRQ ( SPLB1_Sl_MIRQ ),
      .SDMA1_Clk ( SDMA1_Clk ),
      .SDMA1_Rx_IntOut ( SDMA1_Rx_IntOut ),
      .SDMA1_Tx_IntOut ( SDMA1_Tx_IntOut ),
      .SDMA1_RstOut ( SDMA1_RstOut ),
      .SDMA1_TX_D ( SDMA1_TX_D ),
      .SDMA1_TX_Rem ( SDMA1_TX_Rem ),
      .SDMA1_TX_SOF ( SDMA1_TX_SOF ),
      .SDMA1_TX_EOF ( SDMA1_TX_EOF ),
      .SDMA1_TX_SOP ( SDMA1_TX_SOP ),
      .SDMA1_TX_EOP ( SDMA1_TX_EOP ),
      .SDMA1_TX_Src_Rdy ( SDMA1_TX_Src_Rdy ),
      .SDMA1_TX_Dst_Rdy ( SDMA1_TX_Dst_Rdy ),
      .SDMA1_RX_D ( SDMA1_RX_D ),
      .SDMA1_RX_Rem ( SDMA1_RX_Rem ),
      .SDMA1_RX_SOF ( SDMA1_RX_SOF ),
      .SDMA1_RX_EOF ( SDMA1_RX_EOF ),
      .SDMA1_RX_SOP ( SDMA1_RX_SOP ),
      .SDMA1_RX_EOP ( SDMA1_RX_EOP ),
      .SDMA1_RX_Src_Rdy ( SDMA1_RX_Src_Rdy ),
      .SDMA1_RX_Dst_Rdy ( SDMA1_RX_Dst_Rdy ),
      .SDMA_CTRL1_Clk ( SDMA_CTRL1_Clk ),
      .SDMA_CTRL1_Rst ( SDMA_CTRL1_Rst ),
      .SDMA_CTRL1_PLB_ABus ( SDMA_CTRL1_PLB_ABus ),
      .SDMA_CTRL1_PLB_PAValid ( SDMA_CTRL1_PLB_PAValid ),
      .SDMA_CTRL1_PLB_SAValid ( SDMA_CTRL1_PLB_SAValid ),
      .SDMA_CTRL1_PLB_masterID ( SDMA_CTRL1_PLB_masterID ),
      .SDMA_CTRL1_PLB_RNW ( SDMA_CTRL1_PLB_RNW ),
      .SDMA_CTRL1_PLB_BE ( SDMA_CTRL1_PLB_BE ),
      .SDMA_CTRL1_PLB_UABus ( SDMA_CTRL1_PLB_UABus ),
      .SDMA_CTRL1_PLB_rdPrim ( SDMA_CTRL1_PLB_rdPrim ),
      .SDMA_CTRL1_PLB_wrPrim ( SDMA_CTRL1_PLB_wrPrim ),
      .SDMA_CTRL1_PLB_abort ( SDMA_CTRL1_PLB_abort ),
      .SDMA_CTRL1_PLB_busLock ( SDMA_CTRL1_PLB_busLock ),
      .SDMA_CTRL1_PLB_MSize ( SDMA_CTRL1_PLB_MSize ),
      .SDMA_CTRL1_PLB_size ( SDMA_CTRL1_PLB_size ),
      .SDMA_CTRL1_PLB_type ( SDMA_CTRL1_PLB_type ),
      .SDMA_CTRL1_PLB_lockErr ( SDMA_CTRL1_PLB_lockErr ),
      .SDMA_CTRL1_PLB_wrPendReq ( SDMA_CTRL1_PLB_wrPendReq ),
      .SDMA_CTRL1_PLB_wrPendPri ( SDMA_CTRL1_PLB_wrPendPri ),
      .SDMA_CTRL1_PLB_rdPendReq ( SDMA_CTRL1_PLB_rdPendReq ),
      .SDMA_CTRL1_PLB_rdPendPri ( SDMA_CTRL1_PLB_rdPendPri ),
      .SDMA_CTRL1_PLB_reqPri ( SDMA_CTRL1_PLB_reqPri ),
      .SDMA_CTRL1_PLB_TAttribute ( SDMA_CTRL1_PLB_TAttribute ),
      .SDMA_CTRL1_PLB_rdBurst ( SDMA_CTRL1_PLB_rdBurst ),
      .SDMA_CTRL1_PLB_wrBurst ( SDMA_CTRL1_PLB_wrBurst ),
      .SDMA_CTRL1_PLB_wrDBus ( SDMA_CTRL1_PLB_wrDBus ),
      .SDMA_CTRL1_Sl_addrAck ( SDMA_CTRL1_Sl_addrAck ),
      .SDMA_CTRL1_Sl_SSize ( SDMA_CTRL1_Sl_SSize ),
      .SDMA_CTRL1_Sl_wait ( SDMA_CTRL1_Sl_wait ),
      .SDMA_CTRL1_Sl_rearbitrate ( SDMA_CTRL1_Sl_rearbitrate ),
      .SDMA_CTRL1_Sl_wrDAck ( SDMA_CTRL1_Sl_wrDAck ),
      .SDMA_CTRL1_Sl_wrComp ( SDMA_CTRL1_Sl_wrComp ),
      .SDMA_CTRL1_Sl_wrBTerm ( SDMA_CTRL1_Sl_wrBTerm ),
      .SDMA_CTRL1_Sl_rdDBus ( SDMA_CTRL1_Sl_rdDBus ),
      .SDMA_CTRL1_Sl_rdWdAddr ( SDMA_CTRL1_Sl_rdWdAddr ),
      .SDMA_CTRL1_Sl_rdDAck ( SDMA_CTRL1_Sl_rdDAck ),
      .SDMA_CTRL1_Sl_rdComp ( SDMA_CTRL1_Sl_rdComp ),
      .SDMA_CTRL1_Sl_rdBTerm ( SDMA_CTRL1_Sl_rdBTerm ),
      .SDMA_CTRL1_Sl_MBusy ( SDMA_CTRL1_Sl_MBusy ),
      .SDMA_CTRL1_Sl_MRdErr ( SDMA_CTRL1_Sl_MRdErr ),
      .SDMA_CTRL1_Sl_MWrErr ( SDMA_CTRL1_Sl_MWrErr ),
      .SDMA_CTRL1_Sl_MIRQ ( SDMA_CTRL1_Sl_MIRQ ),
      .PIM1_Addr ( PIM1_Addr ),
      .PIM1_AddrReq ( PIM1_AddrReq ),
      .PIM1_AddrAck ( PIM1_AddrAck ),
      .PIM1_RNW ( PIM1_RNW ),
      .PIM1_Size ( PIM1_Size ),
      .PIM1_RdModWr ( PIM1_RdModWr ),
      .PIM1_WrFIFO_Data ( PIM1_WrFIFO_Data ),
      .PIM1_WrFIFO_BE ( PIM1_WrFIFO_BE ),
      .PIM1_WrFIFO_Push ( PIM1_WrFIFO_Push ),
      .PIM1_RdFIFO_Data ( PIM1_RdFIFO_Data ),
      .PIM1_RdFIFO_Pop ( PIM1_RdFIFO_Pop ),
      .PIM1_RdFIFO_RdWdAddr ( PIM1_RdFIFO_RdWdAddr ),
      .PIM1_WrFIFO_Empty ( PIM1_WrFIFO_Empty ),
      .PIM1_WrFIFO_AlmostFull ( PIM1_WrFIFO_AlmostFull ),
      .PIM1_WrFIFO_Flush ( PIM1_WrFIFO_Flush ),
      .PIM1_RdFIFO_Empty ( PIM1_RdFIFO_Empty ),
      .PIM1_RdFIFO_Flush ( PIM1_RdFIFO_Flush ),
      .PIM1_RdFIFO_Latency ( PIM1_RdFIFO_Latency ),
      .PIM1_InitDone ( PIM1_InitDone ),
      .PPC440MC1_MIMCReadNotWrite ( PPC440MC1_MIMCReadNotWrite ),
      .PPC440MC1_MIMCAddress ( PPC440MC1_MIMCAddress ),
      .PPC440MC1_MIMCAddressValid ( PPC440MC1_MIMCAddressValid ),
      .PPC440MC1_MIMCWriteData ( PPC440MC1_MIMCWriteData ),
      .PPC440MC1_MIMCWriteDataValid ( PPC440MC1_MIMCWriteDataValid ),
      .PPC440MC1_MIMCByteEnable ( PPC440MC1_MIMCByteEnable ),
      .PPC440MC1_MIMCBankConflict ( PPC440MC1_MIMCBankConflict ),
      .PPC440MC1_MIMCRowConflict ( PPC440MC1_MIMCRowConflict ),
      .PPC440MC1_MCMIReadData ( PPC440MC1_MCMIReadData ),
      .PPC440MC1_MCMIReadDataValid ( PPC440MC1_MCMIReadDataValid ),
      .PPC440MC1_MCMIReadDataErr ( PPC440MC1_MCMIReadDataErr ),
      .PPC440MC1_MCMIAddrReadyToAccept ( PPC440MC1_MCMIAddrReadyToAccept ),
      .VFBC1_Cmd_Clk ( VFBC1_Cmd_Clk ),
      .VFBC1_Cmd_Reset ( VFBC1_Cmd_Reset ),
      .VFBC1_Cmd_Data ( VFBC1_Cmd_Data ),
      .VFBC1_Cmd_Write ( VFBC1_Cmd_Write ),
      .VFBC1_Cmd_End ( VFBC1_Cmd_End ),
      .VFBC1_Cmd_Full ( VFBC1_Cmd_Full ),
      .VFBC1_Cmd_Almost_Full ( VFBC1_Cmd_Almost_Full ),
      .VFBC1_Cmd_Idle ( VFBC1_Cmd_Idle ),
      .VFBC1_Wd_Clk ( VFBC1_Wd_Clk ),
      .VFBC1_Wd_Reset ( VFBC1_Wd_Reset ),
      .VFBC1_Wd_Write ( VFBC1_Wd_Write ),
      .VFBC1_Wd_End_Burst ( VFBC1_Wd_End_Burst ),
      .VFBC1_Wd_Flush ( VFBC1_Wd_Flush ),
      .VFBC1_Wd_Data ( VFBC1_Wd_Data ),
      .VFBC1_Wd_Data_BE ( VFBC1_Wd_Data_BE ),
      .VFBC1_Wd_Full ( VFBC1_Wd_Full ),
      .VFBC1_Wd_Almost_Full ( VFBC1_Wd_Almost_Full ),
      .VFBC1_Rd_Clk ( VFBC1_Rd_Clk ),
      .VFBC1_Rd_Reset ( VFBC1_Rd_Reset ),
      .VFBC1_Rd_Read ( VFBC1_Rd_Read ),
      .VFBC1_Rd_End_Burst ( VFBC1_Rd_End_Burst ),
      .VFBC1_Rd_Flush ( VFBC1_Rd_Flush ),
      .VFBC1_Rd_Data ( VFBC1_Rd_Data ),
      .VFBC1_Rd_Empty ( VFBC1_Rd_Empty ),
      .VFBC1_Rd_Almost_Empty ( VFBC1_Rd_Almost_Empty ),
      .MCB1_cmd_clk ( MCB1_cmd_clk ),
      .MCB1_cmd_en ( MCB1_cmd_en ),
      .MCB1_cmd_instr ( MCB1_cmd_instr ),
      .MCB1_cmd_bl ( MCB1_cmd_bl ),
      .MCB1_cmd_byte_addr ( MCB1_cmd_byte_addr ),
      .MCB1_cmd_empty ( MCB1_cmd_empty ),
      .MCB1_cmd_full ( MCB1_cmd_full ),
      .MCB1_wr_clk ( MCB1_wr_clk ),
      .MCB1_wr_en ( MCB1_wr_en ),
      .MCB1_wr_mask ( MCB1_wr_mask ),
      .MCB1_wr_data ( MCB1_wr_data ),
      .MCB1_wr_full ( MCB1_wr_full ),
      .MCB1_wr_empty ( MCB1_wr_empty ),
      .MCB1_wr_count ( MCB1_wr_count ),
      .MCB1_wr_underrun ( MCB1_wr_underrun ),
      .MCB1_wr_error ( MCB1_wr_error ),
      .MCB1_rd_clk ( MCB1_rd_clk ),
      .MCB1_rd_en ( MCB1_rd_en ),
      .MCB1_rd_data ( MCB1_rd_data ),
      .MCB1_rd_full ( MCB1_rd_full ),
      .MCB1_rd_empty ( MCB1_rd_empty ),
      .MCB1_rd_count ( MCB1_rd_count ),
      .MCB1_rd_overflow ( MCB1_rd_overflow ),
      .MCB1_rd_error ( MCB1_rd_error ),
      .FSL2_M_Clk ( FSL2_M_Clk ),
      .FSL2_M_Write ( FSL2_M_Write ),
      .FSL2_M_Data ( FSL2_M_Data ),
      .FSL2_M_Control ( FSL2_M_Control ),
      .FSL2_M_Full ( FSL2_M_Full ),
      .FSL2_S_Clk ( FSL2_S_Clk ),
      .FSL2_S_Read ( FSL2_S_Read ),
      .FSL2_S_Data ( FSL2_S_Data ),
      .FSL2_S_Control ( FSL2_S_Control ),
      .FSL2_S_Exists ( FSL2_S_Exists ),
      .FSL2_B_M_Clk ( FSL2_B_M_Clk ),
      .FSL2_B_M_Write ( FSL2_B_M_Write ),
      .FSL2_B_M_Data ( FSL2_B_M_Data ),
      .FSL2_B_M_Control ( FSL2_B_M_Control ),
      .FSL2_B_M_Full ( FSL2_B_M_Full ),
      .FSL2_B_S_Clk ( FSL2_B_S_Clk ),
      .FSL2_B_S_Read ( FSL2_B_S_Read ),
      .FSL2_B_S_Data ( FSL2_B_S_Data ),
      .FSL2_B_S_Control ( FSL2_B_S_Control ),
      .FSL2_B_S_Exists ( FSL2_B_S_Exists ),
      .SPLB2_Clk ( SPLB2_Clk ),
      .SPLB2_Rst ( SPLB2_Rst ),
      .SPLB2_PLB_ABus ( SPLB2_PLB_ABus ),
      .SPLB2_PLB_PAValid ( SPLB2_PLB_PAValid ),
      .SPLB2_PLB_SAValid ( SPLB2_PLB_SAValid ),
      .SPLB2_PLB_masterID ( SPLB2_PLB_masterID ),
      .SPLB2_PLB_RNW ( SPLB2_PLB_RNW ),
      .SPLB2_PLB_BE ( SPLB2_PLB_BE ),
      .SPLB2_PLB_UABus ( SPLB2_PLB_UABus ),
      .SPLB2_PLB_rdPrim ( SPLB2_PLB_rdPrim ),
      .SPLB2_PLB_wrPrim ( SPLB2_PLB_wrPrim ),
      .SPLB2_PLB_abort ( SPLB2_PLB_abort ),
      .SPLB2_PLB_busLock ( SPLB2_PLB_busLock ),
      .SPLB2_PLB_MSize ( SPLB2_PLB_MSize ),
      .SPLB2_PLB_size ( SPLB2_PLB_size ),
      .SPLB2_PLB_type ( SPLB2_PLB_type ),
      .SPLB2_PLB_lockErr ( SPLB2_PLB_lockErr ),
      .SPLB2_PLB_wrPendReq ( SPLB2_PLB_wrPendReq ),
      .SPLB2_PLB_wrPendPri ( SPLB2_PLB_wrPendPri ),
      .SPLB2_PLB_rdPendReq ( SPLB2_PLB_rdPendReq ),
      .SPLB2_PLB_rdPendPri ( SPLB2_PLB_rdPendPri ),
      .SPLB2_PLB_reqPri ( SPLB2_PLB_reqPri ),
      .SPLB2_PLB_TAttribute ( SPLB2_PLB_TAttribute ),
      .SPLB2_PLB_rdBurst ( SPLB2_PLB_rdBurst ),
      .SPLB2_PLB_wrBurst ( SPLB2_PLB_wrBurst ),
      .SPLB2_PLB_wrDBus ( SPLB2_PLB_wrDBus ),
      .SPLB2_Sl_addrAck ( SPLB2_Sl_addrAck ),
      .SPLB2_Sl_SSize ( SPLB2_Sl_SSize ),
      .SPLB2_Sl_wait ( SPLB2_Sl_wait ),
      .SPLB2_Sl_rearbitrate ( SPLB2_Sl_rearbitrate ),
      .SPLB2_Sl_wrDAck ( SPLB2_Sl_wrDAck ),
      .SPLB2_Sl_wrComp ( SPLB2_Sl_wrComp ),
      .SPLB2_Sl_wrBTerm ( SPLB2_Sl_wrBTerm ),
      .SPLB2_Sl_rdDBus ( SPLB2_Sl_rdDBus ),
      .SPLB2_Sl_rdWdAddr ( SPLB2_Sl_rdWdAddr ),
      .SPLB2_Sl_rdDAck ( SPLB2_Sl_rdDAck ),
      .SPLB2_Sl_rdComp ( SPLB2_Sl_rdComp ),
      .SPLB2_Sl_rdBTerm ( SPLB2_Sl_rdBTerm ),
      .SPLB2_Sl_MBusy ( SPLB2_Sl_MBusy ),
      .SPLB2_Sl_MRdErr ( SPLB2_Sl_MRdErr ),
      .SPLB2_Sl_MWrErr ( SPLB2_Sl_MWrErr ),
      .SPLB2_Sl_MIRQ ( SPLB2_Sl_MIRQ ),
      .SDMA2_Clk ( SDMA2_Clk ),
      .SDMA2_Rx_IntOut ( SDMA2_Rx_IntOut ),
      .SDMA2_Tx_IntOut ( SDMA2_Tx_IntOut ),
      .SDMA2_RstOut ( SDMA2_RstOut ),
      .SDMA2_TX_D ( SDMA2_TX_D ),
      .SDMA2_TX_Rem ( SDMA2_TX_Rem ),
      .SDMA2_TX_SOF ( SDMA2_TX_SOF ),
      .SDMA2_TX_EOF ( SDMA2_TX_EOF ),
      .SDMA2_TX_SOP ( SDMA2_TX_SOP ),
      .SDMA2_TX_EOP ( SDMA2_TX_EOP ),
      .SDMA2_TX_Src_Rdy ( SDMA2_TX_Src_Rdy ),
      .SDMA2_TX_Dst_Rdy ( SDMA2_TX_Dst_Rdy ),
      .SDMA2_RX_D ( SDMA2_RX_D ),
      .SDMA2_RX_Rem ( SDMA2_RX_Rem ),
      .SDMA2_RX_SOF ( SDMA2_RX_SOF ),
      .SDMA2_RX_EOF ( SDMA2_RX_EOF ),
      .SDMA2_RX_SOP ( SDMA2_RX_SOP ),
      .SDMA2_RX_EOP ( SDMA2_RX_EOP ),
      .SDMA2_RX_Src_Rdy ( SDMA2_RX_Src_Rdy ),
      .SDMA2_RX_Dst_Rdy ( SDMA2_RX_Dst_Rdy ),
      .SDMA_CTRL2_Clk ( SDMA_CTRL2_Clk ),
      .SDMA_CTRL2_Rst ( SDMA_CTRL2_Rst ),
      .SDMA_CTRL2_PLB_ABus ( SDMA_CTRL2_PLB_ABus ),
      .SDMA_CTRL2_PLB_PAValid ( SDMA_CTRL2_PLB_PAValid ),
      .SDMA_CTRL2_PLB_SAValid ( SDMA_CTRL2_PLB_SAValid ),
      .SDMA_CTRL2_PLB_masterID ( SDMA_CTRL2_PLB_masterID ),
      .SDMA_CTRL2_PLB_RNW ( SDMA_CTRL2_PLB_RNW ),
      .SDMA_CTRL2_PLB_BE ( SDMA_CTRL2_PLB_BE ),
      .SDMA_CTRL2_PLB_UABus ( SDMA_CTRL2_PLB_UABus ),
      .SDMA_CTRL2_PLB_rdPrim ( SDMA_CTRL2_PLB_rdPrim ),
      .SDMA_CTRL2_PLB_wrPrim ( SDMA_CTRL2_PLB_wrPrim ),
      .SDMA_CTRL2_PLB_abort ( SDMA_CTRL2_PLB_abort ),
      .SDMA_CTRL2_PLB_busLock ( SDMA_CTRL2_PLB_busLock ),
      .SDMA_CTRL2_PLB_MSize ( SDMA_CTRL2_PLB_MSize ),
      .SDMA_CTRL2_PLB_size ( SDMA_CTRL2_PLB_size ),
      .SDMA_CTRL2_PLB_type ( SDMA_CTRL2_PLB_type ),
      .SDMA_CTRL2_PLB_lockErr ( SDMA_CTRL2_PLB_lockErr ),
      .SDMA_CTRL2_PLB_wrPendReq ( SDMA_CTRL2_PLB_wrPendReq ),
      .SDMA_CTRL2_PLB_wrPendPri ( SDMA_CTRL2_PLB_wrPendPri ),
      .SDMA_CTRL2_PLB_rdPendReq ( SDMA_CTRL2_PLB_rdPendReq ),
      .SDMA_CTRL2_PLB_rdPendPri ( SDMA_CTRL2_PLB_rdPendPri ),
      .SDMA_CTRL2_PLB_reqPri ( SDMA_CTRL2_PLB_reqPri ),
      .SDMA_CTRL2_PLB_TAttribute ( SDMA_CTRL2_PLB_TAttribute ),
      .SDMA_CTRL2_PLB_rdBurst ( SDMA_CTRL2_PLB_rdBurst ),
      .SDMA_CTRL2_PLB_wrBurst ( SDMA_CTRL2_PLB_wrBurst ),
      .SDMA_CTRL2_PLB_wrDBus ( SDMA_CTRL2_PLB_wrDBus ),
      .SDMA_CTRL2_Sl_addrAck ( SDMA_CTRL2_Sl_addrAck ),
      .SDMA_CTRL2_Sl_SSize ( SDMA_CTRL2_Sl_SSize ),
      .SDMA_CTRL2_Sl_wait ( SDMA_CTRL2_Sl_wait ),
      .SDMA_CTRL2_Sl_rearbitrate ( SDMA_CTRL2_Sl_rearbitrate ),
      .SDMA_CTRL2_Sl_wrDAck ( SDMA_CTRL2_Sl_wrDAck ),
      .SDMA_CTRL2_Sl_wrComp ( SDMA_CTRL2_Sl_wrComp ),
      .SDMA_CTRL2_Sl_wrBTerm ( SDMA_CTRL2_Sl_wrBTerm ),
      .SDMA_CTRL2_Sl_rdDBus ( SDMA_CTRL2_Sl_rdDBus ),
      .SDMA_CTRL2_Sl_rdWdAddr ( SDMA_CTRL2_Sl_rdWdAddr ),
      .SDMA_CTRL2_Sl_rdDAck ( SDMA_CTRL2_Sl_rdDAck ),
      .SDMA_CTRL2_Sl_rdComp ( SDMA_CTRL2_Sl_rdComp ),
      .SDMA_CTRL2_Sl_rdBTerm ( SDMA_CTRL2_Sl_rdBTerm ),
      .SDMA_CTRL2_Sl_MBusy ( SDMA_CTRL2_Sl_MBusy ),
      .SDMA_CTRL2_Sl_MRdErr ( SDMA_CTRL2_Sl_MRdErr ),
      .SDMA_CTRL2_Sl_MWrErr ( SDMA_CTRL2_Sl_MWrErr ),
      .SDMA_CTRL2_Sl_MIRQ ( SDMA_CTRL2_Sl_MIRQ ),
      .PIM2_Addr ( PIM2_Addr ),
      .PIM2_AddrReq ( PIM2_AddrReq ),
      .PIM2_AddrAck ( PIM2_AddrAck ),
      .PIM2_RNW ( PIM2_RNW ),
      .PIM2_Size ( PIM2_Size ),
      .PIM2_RdModWr ( PIM2_RdModWr ),
      .PIM2_WrFIFO_Data ( PIM2_WrFIFO_Data ),
      .PIM2_WrFIFO_BE ( PIM2_WrFIFO_BE ),
      .PIM2_WrFIFO_Push ( PIM2_WrFIFO_Push ),
      .PIM2_RdFIFO_Data ( PIM2_RdFIFO_Data ),
      .PIM2_RdFIFO_Pop ( PIM2_RdFIFO_Pop ),
      .PIM2_RdFIFO_RdWdAddr ( PIM2_RdFIFO_RdWdAddr ),
      .PIM2_WrFIFO_Empty ( PIM2_WrFIFO_Empty ),
      .PIM2_WrFIFO_AlmostFull ( PIM2_WrFIFO_AlmostFull ),
      .PIM2_WrFIFO_Flush ( PIM2_WrFIFO_Flush ),
      .PIM2_RdFIFO_Empty ( PIM2_RdFIFO_Empty ),
      .PIM2_RdFIFO_Flush ( PIM2_RdFIFO_Flush ),
      .PIM2_RdFIFO_Latency ( PIM2_RdFIFO_Latency ),
      .PIM2_InitDone ( PIM2_InitDone ),
      .PPC440MC2_MIMCReadNotWrite ( PPC440MC2_MIMCReadNotWrite ),
      .PPC440MC2_MIMCAddress ( PPC440MC2_MIMCAddress ),
      .PPC440MC2_MIMCAddressValid ( PPC440MC2_MIMCAddressValid ),
      .PPC440MC2_MIMCWriteData ( PPC440MC2_MIMCWriteData ),
      .PPC440MC2_MIMCWriteDataValid ( PPC440MC2_MIMCWriteDataValid ),
      .PPC440MC2_MIMCByteEnable ( PPC440MC2_MIMCByteEnable ),
      .PPC440MC2_MIMCBankConflict ( PPC440MC2_MIMCBankConflict ),
      .PPC440MC2_MIMCRowConflict ( PPC440MC2_MIMCRowConflict ),
      .PPC440MC2_MCMIReadData ( PPC440MC2_MCMIReadData ),
      .PPC440MC2_MCMIReadDataValid ( PPC440MC2_MCMIReadDataValid ),
      .PPC440MC2_MCMIReadDataErr ( PPC440MC2_MCMIReadDataErr ),
      .PPC440MC2_MCMIAddrReadyToAccept ( PPC440MC2_MCMIAddrReadyToAccept ),
      .VFBC2_Cmd_Clk ( VFBC2_Cmd_Clk ),
      .VFBC2_Cmd_Reset ( VFBC2_Cmd_Reset ),
      .VFBC2_Cmd_Data ( VFBC2_Cmd_Data ),
      .VFBC2_Cmd_Write ( VFBC2_Cmd_Write ),
      .VFBC2_Cmd_End ( VFBC2_Cmd_End ),
      .VFBC2_Cmd_Full ( VFBC2_Cmd_Full ),
      .VFBC2_Cmd_Almost_Full ( VFBC2_Cmd_Almost_Full ),
      .VFBC2_Cmd_Idle ( VFBC2_Cmd_Idle ),
      .VFBC2_Wd_Clk ( VFBC2_Wd_Clk ),
      .VFBC2_Wd_Reset ( VFBC2_Wd_Reset ),
      .VFBC2_Wd_Write ( VFBC2_Wd_Write ),
      .VFBC2_Wd_End_Burst ( VFBC2_Wd_End_Burst ),
      .VFBC2_Wd_Flush ( VFBC2_Wd_Flush ),
      .VFBC2_Wd_Data ( VFBC2_Wd_Data ),
      .VFBC2_Wd_Data_BE ( VFBC2_Wd_Data_BE ),
      .VFBC2_Wd_Full ( VFBC2_Wd_Full ),
      .VFBC2_Wd_Almost_Full ( VFBC2_Wd_Almost_Full ),
      .VFBC2_Rd_Clk ( VFBC2_Rd_Clk ),
      .VFBC2_Rd_Reset ( VFBC2_Rd_Reset ),
      .VFBC2_Rd_Read ( VFBC2_Rd_Read ),
      .VFBC2_Rd_End_Burst ( VFBC2_Rd_End_Burst ),
      .VFBC2_Rd_Flush ( VFBC2_Rd_Flush ),
      .VFBC2_Rd_Data ( VFBC2_Rd_Data ),
      .VFBC2_Rd_Empty ( VFBC2_Rd_Empty ),
      .VFBC2_Rd_Almost_Empty ( VFBC2_Rd_Almost_Empty ),
      .MCB2_cmd_clk ( MCB2_cmd_clk ),
      .MCB2_cmd_en ( MCB2_cmd_en ),
      .MCB2_cmd_instr ( MCB2_cmd_instr ),
      .MCB2_cmd_bl ( MCB2_cmd_bl ),
      .MCB2_cmd_byte_addr ( MCB2_cmd_byte_addr ),
      .MCB2_cmd_empty ( MCB2_cmd_empty ),
      .MCB2_cmd_full ( MCB2_cmd_full ),
      .MCB2_wr_clk ( MCB2_wr_clk ),
      .MCB2_wr_en ( MCB2_wr_en ),
      .MCB2_wr_mask ( MCB2_wr_mask ),
      .MCB2_wr_data ( MCB2_wr_data ),
      .MCB2_wr_full ( MCB2_wr_full ),
      .MCB2_wr_empty ( MCB2_wr_empty ),
      .MCB2_wr_count ( MCB2_wr_count ),
      .MCB2_wr_underrun ( MCB2_wr_underrun ),
      .MCB2_wr_error ( MCB2_wr_error ),
      .MCB2_rd_clk ( MCB2_rd_clk ),
      .MCB2_rd_en ( MCB2_rd_en ),
      .MCB2_rd_data ( MCB2_rd_data ),
      .MCB2_rd_full ( MCB2_rd_full ),
      .MCB2_rd_empty ( MCB2_rd_empty ),
      .MCB2_rd_count ( MCB2_rd_count ),
      .MCB2_rd_overflow ( MCB2_rd_overflow ),
      .MCB2_rd_error ( MCB2_rd_error ),
      .FSL3_M_Clk ( FSL3_M_Clk ),
      .FSL3_M_Write ( FSL3_M_Write ),
      .FSL3_M_Data ( FSL3_M_Data ),
      .FSL3_M_Control ( FSL3_M_Control ),
      .FSL3_M_Full ( FSL3_M_Full ),
      .FSL3_S_Clk ( FSL3_S_Clk ),
      .FSL3_S_Read ( FSL3_S_Read ),
      .FSL3_S_Data ( FSL3_S_Data ),
      .FSL3_S_Control ( FSL3_S_Control ),
      .FSL3_S_Exists ( FSL3_S_Exists ),
      .FSL3_B_M_Clk ( FSL3_B_M_Clk ),
      .FSL3_B_M_Write ( FSL3_B_M_Write ),
      .FSL3_B_M_Data ( FSL3_B_M_Data ),
      .FSL3_B_M_Control ( FSL3_B_M_Control ),
      .FSL3_B_M_Full ( FSL3_B_M_Full ),
      .FSL3_B_S_Clk ( FSL3_B_S_Clk ),
      .FSL3_B_S_Read ( FSL3_B_S_Read ),
      .FSL3_B_S_Data ( FSL3_B_S_Data ),
      .FSL3_B_S_Control ( FSL3_B_S_Control ),
      .FSL3_B_S_Exists ( FSL3_B_S_Exists ),
      .SPLB3_Clk ( SPLB3_Clk ),
      .SPLB3_Rst ( SPLB3_Rst ),
      .SPLB3_PLB_ABus ( SPLB3_PLB_ABus ),
      .SPLB3_PLB_PAValid ( SPLB3_PLB_PAValid ),
      .SPLB3_PLB_SAValid ( SPLB3_PLB_SAValid ),
      .SPLB3_PLB_masterID ( SPLB3_PLB_masterID ),
      .SPLB3_PLB_RNW ( SPLB3_PLB_RNW ),
      .SPLB3_PLB_BE ( SPLB3_PLB_BE ),
      .SPLB3_PLB_UABus ( SPLB3_PLB_UABus ),
      .SPLB3_PLB_rdPrim ( SPLB3_PLB_rdPrim ),
      .SPLB3_PLB_wrPrim ( SPLB3_PLB_wrPrim ),
      .SPLB3_PLB_abort ( SPLB3_PLB_abort ),
      .SPLB3_PLB_busLock ( SPLB3_PLB_busLock ),
      .SPLB3_PLB_MSize ( SPLB3_PLB_MSize ),
      .SPLB3_PLB_size ( SPLB3_PLB_size ),
      .SPLB3_PLB_type ( SPLB3_PLB_type ),
      .SPLB3_PLB_lockErr ( SPLB3_PLB_lockErr ),
      .SPLB3_PLB_wrPendReq ( SPLB3_PLB_wrPendReq ),
      .SPLB3_PLB_wrPendPri ( SPLB3_PLB_wrPendPri ),
      .SPLB3_PLB_rdPendReq ( SPLB3_PLB_rdPendReq ),
      .SPLB3_PLB_rdPendPri ( SPLB3_PLB_rdPendPri ),
      .SPLB3_PLB_reqPri ( SPLB3_PLB_reqPri ),
      .SPLB3_PLB_TAttribute ( SPLB3_PLB_TAttribute ),
      .SPLB3_PLB_rdBurst ( SPLB3_PLB_rdBurst ),
      .SPLB3_PLB_wrBurst ( SPLB3_PLB_wrBurst ),
      .SPLB3_PLB_wrDBus ( SPLB3_PLB_wrDBus ),
      .SPLB3_Sl_addrAck ( SPLB3_Sl_addrAck ),
      .SPLB3_Sl_SSize ( SPLB3_Sl_SSize ),
      .SPLB3_Sl_wait ( SPLB3_Sl_wait ),
      .SPLB3_Sl_rearbitrate ( SPLB3_Sl_rearbitrate ),
      .SPLB3_Sl_wrDAck ( SPLB3_Sl_wrDAck ),
      .SPLB3_Sl_wrComp ( SPLB3_Sl_wrComp ),
      .SPLB3_Sl_wrBTerm ( SPLB3_Sl_wrBTerm ),
      .SPLB3_Sl_rdDBus ( SPLB3_Sl_rdDBus ),
      .SPLB3_Sl_rdWdAddr ( SPLB3_Sl_rdWdAddr ),
      .SPLB3_Sl_rdDAck ( SPLB3_Sl_rdDAck ),
      .SPLB3_Sl_rdComp ( SPLB3_Sl_rdComp ),
      .SPLB3_Sl_rdBTerm ( SPLB3_Sl_rdBTerm ),
      .SPLB3_Sl_MBusy ( SPLB3_Sl_MBusy ),
      .SPLB3_Sl_MRdErr ( SPLB3_Sl_MRdErr ),
      .SPLB3_Sl_MWrErr ( SPLB3_Sl_MWrErr ),
      .SPLB3_Sl_MIRQ ( SPLB3_Sl_MIRQ ),
      .SDMA3_Clk ( SDMA3_Clk ),
      .SDMA3_Rx_IntOut ( SDMA3_Rx_IntOut ),
      .SDMA3_Tx_IntOut ( SDMA3_Tx_IntOut ),
      .SDMA3_RstOut ( SDMA3_RstOut ),
      .SDMA3_TX_D ( SDMA3_TX_D ),
      .SDMA3_TX_Rem ( SDMA3_TX_Rem ),
      .SDMA3_TX_SOF ( SDMA3_TX_SOF ),
      .SDMA3_TX_EOF ( SDMA3_TX_EOF ),
      .SDMA3_TX_SOP ( SDMA3_TX_SOP ),
      .SDMA3_TX_EOP ( SDMA3_TX_EOP ),
      .SDMA3_TX_Src_Rdy ( SDMA3_TX_Src_Rdy ),
      .SDMA3_TX_Dst_Rdy ( SDMA3_TX_Dst_Rdy ),
      .SDMA3_RX_D ( SDMA3_RX_D ),
      .SDMA3_RX_Rem ( SDMA3_RX_Rem ),
      .SDMA3_RX_SOF ( SDMA3_RX_SOF ),
      .SDMA3_RX_EOF ( SDMA3_RX_EOF ),
      .SDMA3_RX_SOP ( SDMA3_RX_SOP ),
      .SDMA3_RX_EOP ( SDMA3_RX_EOP ),
      .SDMA3_RX_Src_Rdy ( SDMA3_RX_Src_Rdy ),
      .SDMA3_RX_Dst_Rdy ( SDMA3_RX_Dst_Rdy ),
      .SDMA_CTRL3_Clk ( SDMA_CTRL3_Clk ),
      .SDMA_CTRL3_Rst ( SDMA_CTRL3_Rst ),
      .SDMA_CTRL3_PLB_ABus ( SDMA_CTRL3_PLB_ABus ),
      .SDMA_CTRL3_PLB_PAValid ( SDMA_CTRL3_PLB_PAValid ),
      .SDMA_CTRL3_PLB_SAValid ( SDMA_CTRL3_PLB_SAValid ),
      .SDMA_CTRL3_PLB_masterID ( SDMA_CTRL3_PLB_masterID ),
      .SDMA_CTRL3_PLB_RNW ( SDMA_CTRL3_PLB_RNW ),
      .SDMA_CTRL3_PLB_BE ( SDMA_CTRL3_PLB_BE ),
      .SDMA_CTRL3_PLB_UABus ( SDMA_CTRL3_PLB_UABus ),
      .SDMA_CTRL3_PLB_rdPrim ( SDMA_CTRL3_PLB_rdPrim ),
      .SDMA_CTRL3_PLB_wrPrim ( SDMA_CTRL3_PLB_wrPrim ),
      .SDMA_CTRL3_PLB_abort ( SDMA_CTRL3_PLB_abort ),
      .SDMA_CTRL3_PLB_busLock ( SDMA_CTRL3_PLB_busLock ),
      .SDMA_CTRL3_PLB_MSize ( SDMA_CTRL3_PLB_MSize ),
      .SDMA_CTRL3_PLB_size ( SDMA_CTRL3_PLB_size ),
      .SDMA_CTRL3_PLB_type ( SDMA_CTRL3_PLB_type ),
      .SDMA_CTRL3_PLB_lockErr ( SDMA_CTRL3_PLB_lockErr ),
      .SDMA_CTRL3_PLB_wrPendReq ( SDMA_CTRL3_PLB_wrPendReq ),
      .SDMA_CTRL3_PLB_wrPendPri ( SDMA_CTRL3_PLB_wrPendPri ),
      .SDMA_CTRL3_PLB_rdPendReq ( SDMA_CTRL3_PLB_rdPendReq ),
      .SDMA_CTRL3_PLB_rdPendPri ( SDMA_CTRL3_PLB_rdPendPri ),
      .SDMA_CTRL3_PLB_reqPri ( SDMA_CTRL3_PLB_reqPri ),
      .SDMA_CTRL3_PLB_TAttribute ( SDMA_CTRL3_PLB_TAttribute ),
      .SDMA_CTRL3_PLB_rdBurst ( SDMA_CTRL3_PLB_rdBurst ),
      .SDMA_CTRL3_PLB_wrBurst ( SDMA_CTRL3_PLB_wrBurst ),
      .SDMA_CTRL3_PLB_wrDBus ( SDMA_CTRL3_PLB_wrDBus ),
      .SDMA_CTRL3_Sl_addrAck ( SDMA_CTRL3_Sl_addrAck ),
      .SDMA_CTRL3_Sl_SSize ( SDMA_CTRL3_Sl_SSize ),
      .SDMA_CTRL3_Sl_wait ( SDMA_CTRL3_Sl_wait ),
      .SDMA_CTRL3_Sl_rearbitrate ( SDMA_CTRL3_Sl_rearbitrate ),
      .SDMA_CTRL3_Sl_wrDAck ( SDMA_CTRL3_Sl_wrDAck ),
      .SDMA_CTRL3_Sl_wrComp ( SDMA_CTRL3_Sl_wrComp ),
      .SDMA_CTRL3_Sl_wrBTerm ( SDMA_CTRL3_Sl_wrBTerm ),
      .SDMA_CTRL3_Sl_rdDBus ( SDMA_CTRL3_Sl_rdDBus ),
      .SDMA_CTRL3_Sl_rdWdAddr ( SDMA_CTRL3_Sl_rdWdAddr ),
      .SDMA_CTRL3_Sl_rdDAck ( SDMA_CTRL3_Sl_rdDAck ),
      .SDMA_CTRL3_Sl_rdComp ( SDMA_CTRL3_Sl_rdComp ),
      .SDMA_CTRL3_Sl_rdBTerm ( SDMA_CTRL3_Sl_rdBTerm ),
      .SDMA_CTRL3_Sl_MBusy ( SDMA_CTRL3_Sl_MBusy ),
      .SDMA_CTRL3_Sl_MRdErr ( SDMA_CTRL3_Sl_MRdErr ),
      .SDMA_CTRL3_Sl_MWrErr ( SDMA_CTRL3_Sl_MWrErr ),
      .SDMA_CTRL3_Sl_MIRQ ( SDMA_CTRL3_Sl_MIRQ ),
      .PIM3_Addr ( PIM3_Addr ),
      .PIM3_AddrReq ( PIM3_AddrReq ),
      .PIM3_AddrAck ( PIM3_AddrAck ),
      .PIM3_RNW ( PIM3_RNW ),
      .PIM3_Size ( PIM3_Size ),
      .PIM3_RdModWr ( PIM3_RdModWr ),
      .PIM3_WrFIFO_Data ( PIM3_WrFIFO_Data ),
      .PIM3_WrFIFO_BE ( PIM3_WrFIFO_BE ),
      .PIM3_WrFIFO_Push ( PIM3_WrFIFO_Push ),
      .PIM3_RdFIFO_Data ( PIM3_RdFIFO_Data ),
      .PIM3_RdFIFO_Pop ( PIM3_RdFIFO_Pop ),
      .PIM3_RdFIFO_RdWdAddr ( PIM3_RdFIFO_RdWdAddr ),
      .PIM3_WrFIFO_Empty ( PIM3_WrFIFO_Empty ),
      .PIM3_WrFIFO_AlmostFull ( PIM3_WrFIFO_AlmostFull ),
      .PIM3_WrFIFO_Flush ( PIM3_WrFIFO_Flush ),
      .PIM3_RdFIFO_Empty ( PIM3_RdFIFO_Empty ),
      .PIM3_RdFIFO_Flush ( PIM3_RdFIFO_Flush ),
      .PIM3_RdFIFO_Latency ( PIM3_RdFIFO_Latency ),
      .PIM3_InitDone ( PIM3_InitDone ),
      .PPC440MC3_MIMCReadNotWrite ( PPC440MC3_MIMCReadNotWrite ),
      .PPC440MC3_MIMCAddress ( PPC440MC3_MIMCAddress ),
      .PPC440MC3_MIMCAddressValid ( PPC440MC3_MIMCAddressValid ),
      .PPC440MC3_MIMCWriteData ( PPC440MC3_MIMCWriteData ),
      .PPC440MC3_MIMCWriteDataValid ( PPC440MC3_MIMCWriteDataValid ),
      .PPC440MC3_MIMCByteEnable ( PPC440MC3_MIMCByteEnable ),
      .PPC440MC3_MIMCBankConflict ( PPC440MC3_MIMCBankConflict ),
      .PPC440MC3_MIMCRowConflict ( PPC440MC3_MIMCRowConflict ),
      .PPC440MC3_MCMIReadData ( PPC440MC3_MCMIReadData ),
      .PPC440MC3_MCMIReadDataValid ( PPC440MC3_MCMIReadDataValid ),
      .PPC440MC3_MCMIReadDataErr ( PPC440MC3_MCMIReadDataErr ),
      .PPC440MC3_MCMIAddrReadyToAccept ( PPC440MC3_MCMIAddrReadyToAccept ),
      .VFBC3_Cmd_Clk ( VFBC3_Cmd_Clk ),
      .VFBC3_Cmd_Reset ( VFBC3_Cmd_Reset ),
      .VFBC3_Cmd_Data ( VFBC3_Cmd_Data ),
      .VFBC3_Cmd_Write ( VFBC3_Cmd_Write ),
      .VFBC3_Cmd_End ( VFBC3_Cmd_End ),
      .VFBC3_Cmd_Full ( VFBC3_Cmd_Full ),
      .VFBC3_Cmd_Almost_Full ( VFBC3_Cmd_Almost_Full ),
      .VFBC3_Cmd_Idle ( VFBC3_Cmd_Idle ),
      .VFBC3_Wd_Clk ( VFBC3_Wd_Clk ),
      .VFBC3_Wd_Reset ( VFBC3_Wd_Reset ),
      .VFBC3_Wd_Write ( VFBC3_Wd_Write ),
      .VFBC3_Wd_End_Burst ( VFBC3_Wd_End_Burst ),
      .VFBC3_Wd_Flush ( VFBC3_Wd_Flush ),
      .VFBC3_Wd_Data ( VFBC3_Wd_Data ),
      .VFBC3_Wd_Data_BE ( VFBC3_Wd_Data_BE ),
      .VFBC3_Wd_Full ( VFBC3_Wd_Full ),
      .VFBC3_Wd_Almost_Full ( VFBC3_Wd_Almost_Full ),
      .VFBC3_Rd_Clk ( VFBC3_Rd_Clk ),
      .VFBC3_Rd_Reset ( VFBC3_Rd_Reset ),
      .VFBC3_Rd_Read ( VFBC3_Rd_Read ),
      .VFBC3_Rd_End_Burst ( VFBC3_Rd_End_Burst ),
      .VFBC3_Rd_Flush ( VFBC3_Rd_Flush ),
      .VFBC3_Rd_Data ( VFBC3_Rd_Data ),
      .VFBC3_Rd_Empty ( VFBC3_Rd_Empty ),
      .VFBC3_Rd_Almost_Empty ( VFBC3_Rd_Almost_Empty ),
      .MCB3_cmd_clk ( MCB3_cmd_clk ),
      .MCB3_cmd_en ( MCB3_cmd_en ),
      .MCB3_cmd_instr ( MCB3_cmd_instr ),
      .MCB3_cmd_bl ( MCB3_cmd_bl ),
      .MCB3_cmd_byte_addr ( MCB3_cmd_byte_addr ),
      .MCB3_cmd_empty ( MCB3_cmd_empty ),
      .MCB3_cmd_full ( MCB3_cmd_full ),
      .MCB3_wr_clk ( MCB3_wr_clk ),
      .MCB3_wr_en ( MCB3_wr_en ),
      .MCB3_wr_mask ( MCB3_wr_mask ),
      .MCB3_wr_data ( MCB3_wr_data ),
      .MCB3_wr_full ( MCB3_wr_full ),
      .MCB3_wr_empty ( MCB3_wr_empty ),
      .MCB3_wr_count ( MCB3_wr_count ),
      .MCB3_wr_underrun ( MCB3_wr_underrun ),
      .MCB3_wr_error ( MCB3_wr_error ),
      .MCB3_rd_clk ( MCB3_rd_clk ),
      .MCB3_rd_en ( MCB3_rd_en ),
      .MCB3_rd_data ( MCB3_rd_data ),
      .MCB3_rd_full ( MCB3_rd_full ),
      .MCB3_rd_empty ( MCB3_rd_empty ),
      .MCB3_rd_count ( MCB3_rd_count ),
      .MCB3_rd_overflow ( MCB3_rd_overflow ),
      .MCB3_rd_error ( MCB3_rd_error ),
      .FSL4_M_Clk ( FSL4_M_Clk ),
      .FSL4_M_Write ( FSL4_M_Write ),
      .FSL4_M_Data ( FSL4_M_Data ),
      .FSL4_M_Control ( FSL4_M_Control ),
      .FSL4_M_Full ( FSL4_M_Full ),
      .FSL4_S_Clk ( FSL4_S_Clk ),
      .FSL4_S_Read ( FSL4_S_Read ),
      .FSL4_S_Data ( FSL4_S_Data ),
      .FSL4_S_Control ( FSL4_S_Control ),
      .FSL4_S_Exists ( FSL4_S_Exists ),
      .FSL4_B_M_Clk ( FSL4_B_M_Clk ),
      .FSL4_B_M_Write ( FSL4_B_M_Write ),
      .FSL4_B_M_Data ( FSL4_B_M_Data ),
      .FSL4_B_M_Control ( FSL4_B_M_Control ),
      .FSL4_B_M_Full ( FSL4_B_M_Full ),
      .FSL4_B_S_Clk ( FSL4_B_S_Clk ),
      .FSL4_B_S_Read ( FSL4_B_S_Read ),
      .FSL4_B_S_Data ( FSL4_B_S_Data ),
      .FSL4_B_S_Control ( FSL4_B_S_Control ),
      .FSL4_B_S_Exists ( FSL4_B_S_Exists ),
      .SPLB4_Clk ( SPLB4_Clk ),
      .SPLB4_Rst ( SPLB4_Rst ),
      .SPLB4_PLB_ABus ( SPLB4_PLB_ABus ),
      .SPLB4_PLB_PAValid ( SPLB4_PLB_PAValid ),
      .SPLB4_PLB_SAValid ( SPLB4_PLB_SAValid ),
      .SPLB4_PLB_masterID ( SPLB4_PLB_masterID ),
      .SPLB4_PLB_RNW ( SPLB4_PLB_RNW ),
      .SPLB4_PLB_BE ( SPLB4_PLB_BE ),
      .SPLB4_PLB_UABus ( SPLB4_PLB_UABus ),
      .SPLB4_PLB_rdPrim ( SPLB4_PLB_rdPrim ),
      .SPLB4_PLB_wrPrim ( SPLB4_PLB_wrPrim ),
      .SPLB4_PLB_abort ( SPLB4_PLB_abort ),
      .SPLB4_PLB_busLock ( SPLB4_PLB_busLock ),
      .SPLB4_PLB_MSize ( SPLB4_PLB_MSize ),
      .SPLB4_PLB_size ( SPLB4_PLB_size ),
      .SPLB4_PLB_type ( SPLB4_PLB_type ),
      .SPLB4_PLB_lockErr ( SPLB4_PLB_lockErr ),
      .SPLB4_PLB_wrPendReq ( SPLB4_PLB_wrPendReq ),
      .SPLB4_PLB_wrPendPri ( SPLB4_PLB_wrPendPri ),
      .SPLB4_PLB_rdPendReq ( SPLB4_PLB_rdPendReq ),
      .SPLB4_PLB_rdPendPri ( SPLB4_PLB_rdPendPri ),
      .SPLB4_PLB_reqPri ( SPLB4_PLB_reqPri ),
      .SPLB4_PLB_TAttribute ( SPLB4_PLB_TAttribute ),
      .SPLB4_PLB_rdBurst ( SPLB4_PLB_rdBurst ),
      .SPLB4_PLB_wrBurst ( SPLB4_PLB_wrBurst ),
      .SPLB4_PLB_wrDBus ( SPLB4_PLB_wrDBus ),
      .SPLB4_Sl_addrAck ( SPLB4_Sl_addrAck ),
      .SPLB4_Sl_SSize ( SPLB4_Sl_SSize ),
      .SPLB4_Sl_wait ( SPLB4_Sl_wait ),
      .SPLB4_Sl_rearbitrate ( SPLB4_Sl_rearbitrate ),
      .SPLB4_Sl_wrDAck ( SPLB4_Sl_wrDAck ),
      .SPLB4_Sl_wrComp ( SPLB4_Sl_wrComp ),
      .SPLB4_Sl_wrBTerm ( SPLB4_Sl_wrBTerm ),
      .SPLB4_Sl_rdDBus ( SPLB4_Sl_rdDBus ),
      .SPLB4_Sl_rdWdAddr ( SPLB4_Sl_rdWdAddr ),
      .SPLB4_Sl_rdDAck ( SPLB4_Sl_rdDAck ),
      .SPLB4_Sl_rdComp ( SPLB4_Sl_rdComp ),
      .SPLB4_Sl_rdBTerm ( SPLB4_Sl_rdBTerm ),
      .SPLB4_Sl_MBusy ( SPLB4_Sl_MBusy ),
      .SPLB4_Sl_MRdErr ( SPLB4_Sl_MRdErr ),
      .SPLB4_Sl_MWrErr ( SPLB4_Sl_MWrErr ),
      .SPLB4_Sl_MIRQ ( SPLB4_Sl_MIRQ ),
      .SDMA4_Clk ( SDMA4_Clk ),
      .SDMA4_Rx_IntOut ( SDMA4_Rx_IntOut ),
      .SDMA4_Tx_IntOut ( SDMA4_Tx_IntOut ),
      .SDMA4_RstOut ( SDMA4_RstOut ),
      .SDMA4_TX_D ( SDMA4_TX_D ),
      .SDMA4_TX_Rem ( SDMA4_TX_Rem ),
      .SDMA4_TX_SOF ( SDMA4_TX_SOF ),
      .SDMA4_TX_EOF ( SDMA4_TX_EOF ),
      .SDMA4_TX_SOP ( SDMA4_TX_SOP ),
      .SDMA4_TX_EOP ( SDMA4_TX_EOP ),
      .SDMA4_TX_Src_Rdy ( SDMA4_TX_Src_Rdy ),
      .SDMA4_TX_Dst_Rdy ( SDMA4_TX_Dst_Rdy ),
      .SDMA4_RX_D ( SDMA4_RX_D ),
      .SDMA4_RX_Rem ( SDMA4_RX_Rem ),
      .SDMA4_RX_SOF ( SDMA4_RX_SOF ),
      .SDMA4_RX_EOF ( SDMA4_RX_EOF ),
      .SDMA4_RX_SOP ( SDMA4_RX_SOP ),
      .SDMA4_RX_EOP ( SDMA4_RX_EOP ),
      .SDMA4_RX_Src_Rdy ( SDMA4_RX_Src_Rdy ),
      .SDMA4_RX_Dst_Rdy ( SDMA4_RX_Dst_Rdy ),
      .SDMA_CTRL4_Clk ( SDMA_CTRL4_Clk ),
      .SDMA_CTRL4_Rst ( SDMA_CTRL4_Rst ),
      .SDMA_CTRL4_PLB_ABus ( SDMA_CTRL4_PLB_ABus ),
      .SDMA_CTRL4_PLB_PAValid ( SDMA_CTRL4_PLB_PAValid ),
      .SDMA_CTRL4_PLB_SAValid ( SDMA_CTRL4_PLB_SAValid ),
      .SDMA_CTRL4_PLB_masterID ( SDMA_CTRL4_PLB_masterID ),
      .SDMA_CTRL4_PLB_RNW ( SDMA_CTRL4_PLB_RNW ),
      .SDMA_CTRL4_PLB_BE ( SDMA_CTRL4_PLB_BE ),
      .SDMA_CTRL4_PLB_UABus ( SDMA_CTRL4_PLB_UABus ),
      .SDMA_CTRL4_PLB_rdPrim ( SDMA_CTRL4_PLB_rdPrim ),
      .SDMA_CTRL4_PLB_wrPrim ( SDMA_CTRL4_PLB_wrPrim ),
      .SDMA_CTRL4_PLB_abort ( SDMA_CTRL4_PLB_abort ),
      .SDMA_CTRL4_PLB_busLock ( SDMA_CTRL4_PLB_busLock ),
      .SDMA_CTRL4_PLB_MSize ( SDMA_CTRL4_PLB_MSize ),
      .SDMA_CTRL4_PLB_size ( SDMA_CTRL4_PLB_size ),
      .SDMA_CTRL4_PLB_type ( SDMA_CTRL4_PLB_type ),
      .SDMA_CTRL4_PLB_lockErr ( SDMA_CTRL4_PLB_lockErr ),
      .SDMA_CTRL4_PLB_wrPendReq ( SDMA_CTRL4_PLB_wrPendReq ),
      .SDMA_CTRL4_PLB_wrPendPri ( SDMA_CTRL4_PLB_wrPendPri ),
      .SDMA_CTRL4_PLB_rdPendReq ( SDMA_CTRL4_PLB_rdPendReq ),
      .SDMA_CTRL4_PLB_rdPendPri ( SDMA_CTRL4_PLB_rdPendPri ),
      .SDMA_CTRL4_PLB_reqPri ( SDMA_CTRL4_PLB_reqPri ),
      .SDMA_CTRL4_PLB_TAttribute ( SDMA_CTRL4_PLB_TAttribute ),
      .SDMA_CTRL4_PLB_rdBurst ( SDMA_CTRL4_PLB_rdBurst ),
      .SDMA_CTRL4_PLB_wrBurst ( SDMA_CTRL4_PLB_wrBurst ),
      .SDMA_CTRL4_PLB_wrDBus ( SDMA_CTRL4_PLB_wrDBus ),
      .SDMA_CTRL4_Sl_addrAck ( SDMA_CTRL4_Sl_addrAck ),
      .SDMA_CTRL4_Sl_SSize ( SDMA_CTRL4_Sl_SSize ),
      .SDMA_CTRL4_Sl_wait ( SDMA_CTRL4_Sl_wait ),
      .SDMA_CTRL4_Sl_rearbitrate ( SDMA_CTRL4_Sl_rearbitrate ),
      .SDMA_CTRL4_Sl_wrDAck ( SDMA_CTRL4_Sl_wrDAck ),
      .SDMA_CTRL4_Sl_wrComp ( SDMA_CTRL4_Sl_wrComp ),
      .SDMA_CTRL4_Sl_wrBTerm ( SDMA_CTRL4_Sl_wrBTerm ),
      .SDMA_CTRL4_Sl_rdDBus ( SDMA_CTRL4_Sl_rdDBus ),
      .SDMA_CTRL4_Sl_rdWdAddr ( SDMA_CTRL4_Sl_rdWdAddr ),
      .SDMA_CTRL4_Sl_rdDAck ( SDMA_CTRL4_Sl_rdDAck ),
      .SDMA_CTRL4_Sl_rdComp ( SDMA_CTRL4_Sl_rdComp ),
      .SDMA_CTRL4_Sl_rdBTerm ( SDMA_CTRL4_Sl_rdBTerm ),
      .SDMA_CTRL4_Sl_MBusy ( SDMA_CTRL4_Sl_MBusy ),
      .SDMA_CTRL4_Sl_MRdErr ( SDMA_CTRL4_Sl_MRdErr ),
      .SDMA_CTRL4_Sl_MWrErr ( SDMA_CTRL4_Sl_MWrErr ),
      .SDMA_CTRL4_Sl_MIRQ ( SDMA_CTRL4_Sl_MIRQ ),
      .PIM4_Addr ( PIM4_Addr ),
      .PIM4_AddrReq ( PIM4_AddrReq ),
      .PIM4_AddrAck ( PIM4_AddrAck ),
      .PIM4_RNW ( PIM4_RNW ),
      .PIM4_Size ( PIM4_Size ),
      .PIM4_RdModWr ( PIM4_RdModWr ),
      .PIM4_WrFIFO_Data ( PIM4_WrFIFO_Data ),
      .PIM4_WrFIFO_BE ( PIM4_WrFIFO_BE ),
      .PIM4_WrFIFO_Push ( PIM4_WrFIFO_Push ),
      .PIM4_RdFIFO_Data ( PIM4_RdFIFO_Data ),
      .PIM4_RdFIFO_Pop ( PIM4_RdFIFO_Pop ),
      .PIM4_RdFIFO_RdWdAddr ( PIM4_RdFIFO_RdWdAddr ),
      .PIM4_WrFIFO_Empty ( PIM4_WrFIFO_Empty ),
      .PIM4_WrFIFO_AlmostFull ( PIM4_WrFIFO_AlmostFull ),
      .PIM4_WrFIFO_Flush ( PIM4_WrFIFO_Flush ),
      .PIM4_RdFIFO_Empty ( PIM4_RdFIFO_Empty ),
      .PIM4_RdFIFO_Flush ( PIM4_RdFIFO_Flush ),
      .PIM4_RdFIFO_Latency ( PIM4_RdFIFO_Latency ),
      .PIM4_InitDone ( PIM4_InitDone ),
      .PPC440MC4_MIMCReadNotWrite ( PPC440MC4_MIMCReadNotWrite ),
      .PPC440MC4_MIMCAddress ( PPC440MC4_MIMCAddress ),
      .PPC440MC4_MIMCAddressValid ( PPC440MC4_MIMCAddressValid ),
      .PPC440MC4_MIMCWriteData ( PPC440MC4_MIMCWriteData ),
      .PPC440MC4_MIMCWriteDataValid ( PPC440MC4_MIMCWriteDataValid ),
      .PPC440MC4_MIMCByteEnable ( PPC440MC4_MIMCByteEnable ),
      .PPC440MC4_MIMCBankConflict ( PPC440MC4_MIMCBankConflict ),
      .PPC440MC4_MIMCRowConflict ( PPC440MC4_MIMCRowConflict ),
      .PPC440MC4_MCMIReadData ( PPC440MC4_MCMIReadData ),
      .PPC440MC4_MCMIReadDataValid ( PPC440MC4_MCMIReadDataValid ),
      .PPC440MC4_MCMIReadDataErr ( PPC440MC4_MCMIReadDataErr ),
      .PPC440MC4_MCMIAddrReadyToAccept ( PPC440MC4_MCMIAddrReadyToAccept ),
      .VFBC4_Cmd_Clk ( VFBC4_Cmd_Clk ),
      .VFBC4_Cmd_Reset ( VFBC4_Cmd_Reset ),
      .VFBC4_Cmd_Data ( VFBC4_Cmd_Data ),
      .VFBC4_Cmd_Write ( VFBC4_Cmd_Write ),
      .VFBC4_Cmd_End ( VFBC4_Cmd_End ),
      .VFBC4_Cmd_Full ( VFBC4_Cmd_Full ),
      .VFBC4_Cmd_Almost_Full ( VFBC4_Cmd_Almost_Full ),
      .VFBC4_Cmd_Idle ( VFBC4_Cmd_Idle ),
      .VFBC4_Wd_Clk ( VFBC4_Wd_Clk ),
      .VFBC4_Wd_Reset ( VFBC4_Wd_Reset ),
      .VFBC4_Wd_Write ( VFBC4_Wd_Write ),
      .VFBC4_Wd_End_Burst ( VFBC4_Wd_End_Burst ),
      .VFBC4_Wd_Flush ( VFBC4_Wd_Flush ),
      .VFBC4_Wd_Data ( VFBC4_Wd_Data ),
      .VFBC4_Wd_Data_BE ( VFBC4_Wd_Data_BE ),
      .VFBC4_Wd_Full ( VFBC4_Wd_Full ),
      .VFBC4_Wd_Almost_Full ( VFBC4_Wd_Almost_Full ),
      .VFBC4_Rd_Clk ( VFBC4_Rd_Clk ),
      .VFBC4_Rd_Reset ( VFBC4_Rd_Reset ),
      .VFBC4_Rd_Read ( VFBC4_Rd_Read ),
      .VFBC4_Rd_End_Burst ( VFBC4_Rd_End_Burst ),
      .VFBC4_Rd_Flush ( VFBC4_Rd_Flush ),
      .VFBC4_Rd_Data ( VFBC4_Rd_Data ),
      .VFBC4_Rd_Empty ( VFBC4_Rd_Empty ),
      .VFBC4_Rd_Almost_Empty ( VFBC4_Rd_Almost_Empty ),
      .MCB4_cmd_clk ( MCB4_cmd_clk ),
      .MCB4_cmd_en ( MCB4_cmd_en ),
      .MCB4_cmd_instr ( MCB4_cmd_instr ),
      .MCB4_cmd_bl ( MCB4_cmd_bl ),
      .MCB4_cmd_byte_addr ( MCB4_cmd_byte_addr ),
      .MCB4_cmd_empty ( MCB4_cmd_empty ),
      .MCB4_cmd_full ( MCB4_cmd_full ),
      .MCB4_wr_clk ( MCB4_wr_clk ),
      .MCB4_wr_en ( MCB4_wr_en ),
      .MCB4_wr_mask ( MCB4_wr_mask ),
      .MCB4_wr_data ( MCB4_wr_data ),
      .MCB4_wr_full ( MCB4_wr_full ),
      .MCB4_wr_empty ( MCB4_wr_empty ),
      .MCB4_wr_count ( MCB4_wr_count ),
      .MCB4_wr_underrun ( MCB4_wr_underrun ),
      .MCB4_wr_error ( MCB4_wr_error ),
      .MCB4_rd_clk ( MCB4_rd_clk ),
      .MCB4_rd_en ( MCB4_rd_en ),
      .MCB4_rd_data ( MCB4_rd_data ),
      .MCB4_rd_full ( MCB4_rd_full ),
      .MCB4_rd_empty ( MCB4_rd_empty ),
      .MCB4_rd_count ( MCB4_rd_count ),
      .MCB4_rd_overflow ( MCB4_rd_overflow ),
      .MCB4_rd_error ( MCB4_rd_error ),
      .FSL5_M_Clk ( FSL5_M_Clk ),
      .FSL5_M_Write ( FSL5_M_Write ),
      .FSL5_M_Data ( FSL5_M_Data ),
      .FSL5_M_Control ( FSL5_M_Control ),
      .FSL5_M_Full ( FSL5_M_Full ),
      .FSL5_S_Clk ( FSL5_S_Clk ),
      .FSL5_S_Read ( FSL5_S_Read ),
      .FSL5_S_Data ( FSL5_S_Data ),
      .FSL5_S_Control ( FSL5_S_Control ),
      .FSL5_S_Exists ( FSL5_S_Exists ),
      .FSL5_B_M_Clk ( FSL5_B_M_Clk ),
      .FSL5_B_M_Write ( FSL5_B_M_Write ),
      .FSL5_B_M_Data ( FSL5_B_M_Data ),
      .FSL5_B_M_Control ( FSL5_B_M_Control ),
      .FSL5_B_M_Full ( FSL5_B_M_Full ),
      .FSL5_B_S_Clk ( FSL5_B_S_Clk ),
      .FSL5_B_S_Read ( FSL5_B_S_Read ),
      .FSL5_B_S_Data ( FSL5_B_S_Data ),
      .FSL5_B_S_Control ( FSL5_B_S_Control ),
      .FSL5_B_S_Exists ( FSL5_B_S_Exists ),
      .SPLB5_Clk ( SPLB5_Clk ),
      .SPLB5_Rst ( SPLB5_Rst ),
      .SPLB5_PLB_ABus ( SPLB5_PLB_ABus ),
      .SPLB5_PLB_PAValid ( SPLB5_PLB_PAValid ),
      .SPLB5_PLB_SAValid ( SPLB5_PLB_SAValid ),
      .SPLB5_PLB_masterID ( SPLB5_PLB_masterID ),
      .SPLB5_PLB_RNW ( SPLB5_PLB_RNW ),
      .SPLB5_PLB_BE ( SPLB5_PLB_BE ),
      .SPLB5_PLB_UABus ( SPLB5_PLB_UABus ),
      .SPLB5_PLB_rdPrim ( SPLB5_PLB_rdPrim ),
      .SPLB5_PLB_wrPrim ( SPLB5_PLB_wrPrim ),
      .SPLB5_PLB_abort ( SPLB5_PLB_abort ),
      .SPLB5_PLB_busLock ( SPLB5_PLB_busLock ),
      .SPLB5_PLB_MSize ( SPLB5_PLB_MSize ),
      .SPLB5_PLB_size ( SPLB5_PLB_size ),
      .SPLB5_PLB_type ( SPLB5_PLB_type ),
      .SPLB5_PLB_lockErr ( SPLB5_PLB_lockErr ),
      .SPLB5_PLB_wrPendReq ( SPLB5_PLB_wrPendReq ),
      .SPLB5_PLB_wrPendPri ( SPLB5_PLB_wrPendPri ),
      .SPLB5_PLB_rdPendReq ( SPLB5_PLB_rdPendReq ),
      .SPLB5_PLB_rdPendPri ( SPLB5_PLB_rdPendPri ),
      .SPLB5_PLB_reqPri ( SPLB5_PLB_reqPri ),
      .SPLB5_PLB_TAttribute ( SPLB5_PLB_TAttribute ),
      .SPLB5_PLB_rdBurst ( SPLB5_PLB_rdBurst ),
      .SPLB5_PLB_wrBurst ( SPLB5_PLB_wrBurst ),
      .SPLB5_PLB_wrDBus ( SPLB5_PLB_wrDBus ),
      .SPLB5_Sl_addrAck ( SPLB5_Sl_addrAck ),
      .SPLB5_Sl_SSize ( SPLB5_Sl_SSize ),
      .SPLB5_Sl_wait ( SPLB5_Sl_wait ),
      .SPLB5_Sl_rearbitrate ( SPLB5_Sl_rearbitrate ),
      .SPLB5_Sl_wrDAck ( SPLB5_Sl_wrDAck ),
      .SPLB5_Sl_wrComp ( SPLB5_Sl_wrComp ),
      .SPLB5_Sl_wrBTerm ( SPLB5_Sl_wrBTerm ),
      .SPLB5_Sl_rdDBus ( SPLB5_Sl_rdDBus ),
      .SPLB5_Sl_rdWdAddr ( SPLB5_Sl_rdWdAddr ),
      .SPLB5_Sl_rdDAck ( SPLB5_Sl_rdDAck ),
      .SPLB5_Sl_rdComp ( SPLB5_Sl_rdComp ),
      .SPLB5_Sl_rdBTerm ( SPLB5_Sl_rdBTerm ),
      .SPLB5_Sl_MBusy ( SPLB5_Sl_MBusy ),
      .SPLB5_Sl_MRdErr ( SPLB5_Sl_MRdErr ),
      .SPLB5_Sl_MWrErr ( SPLB5_Sl_MWrErr ),
      .SPLB5_Sl_MIRQ ( SPLB5_Sl_MIRQ ),
      .SDMA5_Clk ( SDMA5_Clk ),
      .SDMA5_Rx_IntOut ( SDMA5_Rx_IntOut ),
      .SDMA5_Tx_IntOut ( SDMA5_Tx_IntOut ),
      .SDMA5_RstOut ( SDMA5_RstOut ),
      .SDMA5_TX_D ( SDMA5_TX_D ),
      .SDMA5_TX_Rem ( SDMA5_TX_Rem ),
      .SDMA5_TX_SOF ( SDMA5_TX_SOF ),
      .SDMA5_TX_EOF ( SDMA5_TX_EOF ),
      .SDMA5_TX_SOP ( SDMA5_TX_SOP ),
      .SDMA5_TX_EOP ( SDMA5_TX_EOP ),
      .SDMA5_TX_Src_Rdy ( SDMA5_TX_Src_Rdy ),
      .SDMA5_TX_Dst_Rdy ( SDMA5_TX_Dst_Rdy ),
      .SDMA5_RX_D ( SDMA5_RX_D ),
      .SDMA5_RX_Rem ( SDMA5_RX_Rem ),
      .SDMA5_RX_SOF ( SDMA5_RX_SOF ),
      .SDMA5_RX_EOF ( SDMA5_RX_EOF ),
      .SDMA5_RX_SOP ( SDMA5_RX_SOP ),
      .SDMA5_RX_EOP ( SDMA5_RX_EOP ),
      .SDMA5_RX_Src_Rdy ( SDMA5_RX_Src_Rdy ),
      .SDMA5_RX_Dst_Rdy ( SDMA5_RX_Dst_Rdy ),
      .SDMA_CTRL5_Clk ( SDMA_CTRL5_Clk ),
      .SDMA_CTRL5_Rst ( SDMA_CTRL5_Rst ),
      .SDMA_CTRL5_PLB_ABus ( SDMA_CTRL5_PLB_ABus ),
      .SDMA_CTRL5_PLB_PAValid ( SDMA_CTRL5_PLB_PAValid ),
      .SDMA_CTRL5_PLB_SAValid ( SDMA_CTRL5_PLB_SAValid ),
      .SDMA_CTRL5_PLB_masterID ( SDMA_CTRL5_PLB_masterID ),
      .SDMA_CTRL5_PLB_RNW ( SDMA_CTRL5_PLB_RNW ),
      .SDMA_CTRL5_PLB_BE ( SDMA_CTRL5_PLB_BE ),
      .SDMA_CTRL5_PLB_UABus ( SDMA_CTRL5_PLB_UABus ),
      .SDMA_CTRL5_PLB_rdPrim ( SDMA_CTRL5_PLB_rdPrim ),
      .SDMA_CTRL5_PLB_wrPrim ( SDMA_CTRL5_PLB_wrPrim ),
      .SDMA_CTRL5_PLB_abort ( SDMA_CTRL5_PLB_abort ),
      .SDMA_CTRL5_PLB_busLock ( SDMA_CTRL5_PLB_busLock ),
      .SDMA_CTRL5_PLB_MSize ( SDMA_CTRL5_PLB_MSize ),
      .SDMA_CTRL5_PLB_size ( SDMA_CTRL5_PLB_size ),
      .SDMA_CTRL5_PLB_type ( SDMA_CTRL5_PLB_type ),
      .SDMA_CTRL5_PLB_lockErr ( SDMA_CTRL5_PLB_lockErr ),
      .SDMA_CTRL5_PLB_wrPendReq ( SDMA_CTRL5_PLB_wrPendReq ),
      .SDMA_CTRL5_PLB_wrPendPri ( SDMA_CTRL5_PLB_wrPendPri ),
      .SDMA_CTRL5_PLB_rdPendReq ( SDMA_CTRL5_PLB_rdPendReq ),
      .SDMA_CTRL5_PLB_rdPendPri ( SDMA_CTRL5_PLB_rdPendPri ),
      .SDMA_CTRL5_PLB_reqPri ( SDMA_CTRL5_PLB_reqPri ),
      .SDMA_CTRL5_PLB_TAttribute ( SDMA_CTRL5_PLB_TAttribute ),
      .SDMA_CTRL5_PLB_rdBurst ( SDMA_CTRL5_PLB_rdBurst ),
      .SDMA_CTRL5_PLB_wrBurst ( SDMA_CTRL5_PLB_wrBurst ),
      .SDMA_CTRL5_PLB_wrDBus ( SDMA_CTRL5_PLB_wrDBus ),
      .SDMA_CTRL5_Sl_addrAck ( SDMA_CTRL5_Sl_addrAck ),
      .SDMA_CTRL5_Sl_SSize ( SDMA_CTRL5_Sl_SSize ),
      .SDMA_CTRL5_Sl_wait ( SDMA_CTRL5_Sl_wait ),
      .SDMA_CTRL5_Sl_rearbitrate ( SDMA_CTRL5_Sl_rearbitrate ),
      .SDMA_CTRL5_Sl_wrDAck ( SDMA_CTRL5_Sl_wrDAck ),
      .SDMA_CTRL5_Sl_wrComp ( SDMA_CTRL5_Sl_wrComp ),
      .SDMA_CTRL5_Sl_wrBTerm ( SDMA_CTRL5_Sl_wrBTerm ),
      .SDMA_CTRL5_Sl_rdDBus ( SDMA_CTRL5_Sl_rdDBus ),
      .SDMA_CTRL5_Sl_rdWdAddr ( SDMA_CTRL5_Sl_rdWdAddr ),
      .SDMA_CTRL5_Sl_rdDAck ( SDMA_CTRL5_Sl_rdDAck ),
      .SDMA_CTRL5_Sl_rdComp ( SDMA_CTRL5_Sl_rdComp ),
      .SDMA_CTRL5_Sl_rdBTerm ( SDMA_CTRL5_Sl_rdBTerm ),
      .SDMA_CTRL5_Sl_MBusy ( SDMA_CTRL5_Sl_MBusy ),
      .SDMA_CTRL5_Sl_MRdErr ( SDMA_CTRL5_Sl_MRdErr ),
      .SDMA_CTRL5_Sl_MWrErr ( SDMA_CTRL5_Sl_MWrErr ),
      .SDMA_CTRL5_Sl_MIRQ ( SDMA_CTRL5_Sl_MIRQ ),
      .PIM5_Addr ( PIM5_Addr ),
      .PIM5_AddrReq ( PIM5_AddrReq ),
      .PIM5_AddrAck ( PIM5_AddrAck ),
      .PIM5_RNW ( PIM5_RNW ),
      .PIM5_Size ( PIM5_Size ),
      .PIM5_RdModWr ( PIM5_RdModWr ),
      .PIM5_WrFIFO_Data ( PIM5_WrFIFO_Data ),
      .PIM5_WrFIFO_BE ( PIM5_WrFIFO_BE ),
      .PIM5_WrFIFO_Push ( PIM5_WrFIFO_Push ),
      .PIM5_RdFIFO_Data ( PIM5_RdFIFO_Data ),
      .PIM5_RdFIFO_Pop ( PIM5_RdFIFO_Pop ),
      .PIM5_RdFIFO_RdWdAddr ( PIM5_RdFIFO_RdWdAddr ),
      .PIM5_WrFIFO_Empty ( PIM5_WrFIFO_Empty ),
      .PIM5_WrFIFO_AlmostFull ( PIM5_WrFIFO_AlmostFull ),
      .PIM5_WrFIFO_Flush ( PIM5_WrFIFO_Flush ),
      .PIM5_RdFIFO_Empty ( PIM5_RdFIFO_Empty ),
      .PIM5_RdFIFO_Flush ( PIM5_RdFIFO_Flush ),
      .PIM5_RdFIFO_Latency ( PIM5_RdFIFO_Latency ),
      .PIM5_InitDone ( PIM5_InitDone ),
      .PPC440MC5_MIMCReadNotWrite ( PPC440MC5_MIMCReadNotWrite ),
      .PPC440MC5_MIMCAddress ( PPC440MC5_MIMCAddress ),
      .PPC440MC5_MIMCAddressValid ( PPC440MC5_MIMCAddressValid ),
      .PPC440MC5_MIMCWriteData ( PPC440MC5_MIMCWriteData ),
      .PPC440MC5_MIMCWriteDataValid ( PPC440MC5_MIMCWriteDataValid ),
      .PPC440MC5_MIMCByteEnable ( PPC440MC5_MIMCByteEnable ),
      .PPC440MC5_MIMCBankConflict ( PPC440MC5_MIMCBankConflict ),
      .PPC440MC5_MIMCRowConflict ( PPC440MC5_MIMCRowConflict ),
      .PPC440MC5_MCMIReadData ( PPC440MC5_MCMIReadData ),
      .PPC440MC5_MCMIReadDataValid ( PPC440MC5_MCMIReadDataValid ),
      .PPC440MC5_MCMIReadDataErr ( PPC440MC5_MCMIReadDataErr ),
      .PPC440MC5_MCMIAddrReadyToAccept ( PPC440MC5_MCMIAddrReadyToAccept ),
      .VFBC5_Cmd_Clk ( VFBC5_Cmd_Clk ),
      .VFBC5_Cmd_Reset ( VFBC5_Cmd_Reset ),
      .VFBC5_Cmd_Data ( VFBC5_Cmd_Data ),
      .VFBC5_Cmd_Write ( VFBC5_Cmd_Write ),
      .VFBC5_Cmd_End ( VFBC5_Cmd_End ),
      .VFBC5_Cmd_Full ( VFBC5_Cmd_Full ),
      .VFBC5_Cmd_Almost_Full ( VFBC5_Cmd_Almost_Full ),
      .VFBC5_Cmd_Idle ( VFBC5_Cmd_Idle ),
      .VFBC5_Wd_Clk ( VFBC5_Wd_Clk ),
      .VFBC5_Wd_Reset ( VFBC5_Wd_Reset ),
      .VFBC5_Wd_Write ( VFBC5_Wd_Write ),
      .VFBC5_Wd_End_Burst ( VFBC5_Wd_End_Burst ),
      .VFBC5_Wd_Flush ( VFBC5_Wd_Flush ),
      .VFBC5_Wd_Data ( VFBC5_Wd_Data ),
      .VFBC5_Wd_Data_BE ( VFBC5_Wd_Data_BE ),
      .VFBC5_Wd_Full ( VFBC5_Wd_Full ),
      .VFBC5_Wd_Almost_Full ( VFBC5_Wd_Almost_Full ),
      .VFBC5_Rd_Clk ( VFBC5_Rd_Clk ),
      .VFBC5_Rd_Reset ( VFBC5_Rd_Reset ),
      .VFBC5_Rd_Read ( VFBC5_Rd_Read ),
      .VFBC5_Rd_End_Burst ( VFBC5_Rd_End_Burst ),
      .VFBC5_Rd_Flush ( VFBC5_Rd_Flush ),
      .VFBC5_Rd_Data ( VFBC5_Rd_Data ),
      .VFBC5_Rd_Empty ( VFBC5_Rd_Empty ),
      .VFBC5_Rd_Almost_Empty ( VFBC5_Rd_Almost_Empty ),
      .MCB5_cmd_clk ( MCB5_cmd_clk ),
      .MCB5_cmd_en ( MCB5_cmd_en ),
      .MCB5_cmd_instr ( MCB5_cmd_instr ),
      .MCB5_cmd_bl ( MCB5_cmd_bl ),
      .MCB5_cmd_byte_addr ( MCB5_cmd_byte_addr ),
      .MCB5_cmd_empty ( MCB5_cmd_empty ),
      .MCB5_cmd_full ( MCB5_cmd_full ),
      .MCB5_wr_clk ( MCB5_wr_clk ),
      .MCB5_wr_en ( MCB5_wr_en ),
      .MCB5_wr_mask ( MCB5_wr_mask ),
      .MCB5_wr_data ( MCB5_wr_data ),
      .MCB5_wr_full ( MCB5_wr_full ),
      .MCB5_wr_empty ( MCB5_wr_empty ),
      .MCB5_wr_count ( MCB5_wr_count ),
      .MCB5_wr_underrun ( MCB5_wr_underrun ),
      .MCB5_wr_error ( MCB5_wr_error ),
      .MCB5_rd_clk ( MCB5_rd_clk ),
      .MCB5_rd_en ( MCB5_rd_en ),
      .MCB5_rd_data ( MCB5_rd_data ),
      .MCB5_rd_full ( MCB5_rd_full ),
      .MCB5_rd_empty ( MCB5_rd_empty ),
      .MCB5_rd_count ( MCB5_rd_count ),
      .MCB5_rd_overflow ( MCB5_rd_overflow ),
      .MCB5_rd_error ( MCB5_rd_error ),
      .FSL6_M_Clk ( FSL6_M_Clk ),
      .FSL6_M_Write ( FSL6_M_Write ),
      .FSL6_M_Data ( FSL6_M_Data ),
      .FSL6_M_Control ( FSL6_M_Control ),
      .FSL6_M_Full ( FSL6_M_Full ),
      .FSL6_S_Clk ( FSL6_S_Clk ),
      .FSL6_S_Read ( FSL6_S_Read ),
      .FSL6_S_Data ( FSL6_S_Data ),
      .FSL6_S_Control ( FSL6_S_Control ),
      .FSL6_S_Exists ( FSL6_S_Exists ),
      .FSL6_B_M_Clk ( FSL6_B_M_Clk ),
      .FSL6_B_M_Write ( FSL6_B_M_Write ),
      .FSL6_B_M_Data ( FSL6_B_M_Data ),
      .FSL6_B_M_Control ( FSL6_B_M_Control ),
      .FSL6_B_M_Full ( FSL6_B_M_Full ),
      .FSL6_B_S_Clk ( FSL6_B_S_Clk ),
      .FSL6_B_S_Read ( FSL6_B_S_Read ),
      .FSL6_B_S_Data ( FSL6_B_S_Data ),
      .FSL6_B_S_Control ( FSL6_B_S_Control ),
      .FSL6_B_S_Exists ( FSL6_B_S_Exists ),
      .SPLB6_Clk ( SPLB6_Clk ),
      .SPLB6_Rst ( SPLB6_Rst ),
      .SPLB6_PLB_ABus ( SPLB6_PLB_ABus ),
      .SPLB6_PLB_PAValid ( SPLB6_PLB_PAValid ),
      .SPLB6_PLB_SAValid ( SPLB6_PLB_SAValid ),
      .SPLB6_PLB_masterID ( SPLB6_PLB_masterID ),
      .SPLB6_PLB_RNW ( SPLB6_PLB_RNW ),
      .SPLB6_PLB_BE ( SPLB6_PLB_BE ),
      .SPLB6_PLB_UABus ( SPLB6_PLB_UABus ),
      .SPLB6_PLB_rdPrim ( SPLB6_PLB_rdPrim ),
      .SPLB6_PLB_wrPrim ( SPLB6_PLB_wrPrim ),
      .SPLB6_PLB_abort ( SPLB6_PLB_abort ),
      .SPLB6_PLB_busLock ( SPLB6_PLB_busLock ),
      .SPLB6_PLB_MSize ( SPLB6_PLB_MSize ),
      .SPLB6_PLB_size ( SPLB6_PLB_size ),
      .SPLB6_PLB_type ( SPLB6_PLB_type ),
      .SPLB6_PLB_lockErr ( SPLB6_PLB_lockErr ),
      .SPLB6_PLB_wrPendReq ( SPLB6_PLB_wrPendReq ),
      .SPLB6_PLB_wrPendPri ( SPLB6_PLB_wrPendPri ),
      .SPLB6_PLB_rdPendReq ( SPLB6_PLB_rdPendReq ),
      .SPLB6_PLB_rdPendPri ( SPLB6_PLB_rdPendPri ),
      .SPLB6_PLB_reqPri ( SPLB6_PLB_reqPri ),
      .SPLB6_PLB_TAttribute ( SPLB6_PLB_TAttribute ),
      .SPLB6_PLB_rdBurst ( SPLB6_PLB_rdBurst ),
      .SPLB6_PLB_wrBurst ( SPLB6_PLB_wrBurst ),
      .SPLB6_PLB_wrDBus ( SPLB6_PLB_wrDBus ),
      .SPLB6_Sl_addrAck ( SPLB6_Sl_addrAck ),
      .SPLB6_Sl_SSize ( SPLB6_Sl_SSize ),
      .SPLB6_Sl_wait ( SPLB6_Sl_wait ),
      .SPLB6_Sl_rearbitrate ( SPLB6_Sl_rearbitrate ),
      .SPLB6_Sl_wrDAck ( SPLB6_Sl_wrDAck ),
      .SPLB6_Sl_wrComp ( SPLB6_Sl_wrComp ),
      .SPLB6_Sl_wrBTerm ( SPLB6_Sl_wrBTerm ),
      .SPLB6_Sl_rdDBus ( SPLB6_Sl_rdDBus ),
      .SPLB6_Sl_rdWdAddr ( SPLB6_Sl_rdWdAddr ),
      .SPLB6_Sl_rdDAck ( SPLB6_Sl_rdDAck ),
      .SPLB6_Sl_rdComp ( SPLB6_Sl_rdComp ),
      .SPLB6_Sl_rdBTerm ( SPLB6_Sl_rdBTerm ),
      .SPLB6_Sl_MBusy ( SPLB6_Sl_MBusy ),
      .SPLB6_Sl_MRdErr ( SPLB6_Sl_MRdErr ),
      .SPLB6_Sl_MWrErr ( SPLB6_Sl_MWrErr ),
      .SPLB6_Sl_MIRQ ( SPLB6_Sl_MIRQ ),
      .SDMA6_Clk ( SDMA6_Clk ),
      .SDMA6_Rx_IntOut ( SDMA6_Rx_IntOut ),
      .SDMA6_Tx_IntOut ( SDMA6_Tx_IntOut ),
      .SDMA6_RstOut ( SDMA6_RstOut ),
      .SDMA6_TX_D ( SDMA6_TX_D ),
      .SDMA6_TX_Rem ( SDMA6_TX_Rem ),
      .SDMA6_TX_SOF ( SDMA6_TX_SOF ),
      .SDMA6_TX_EOF ( SDMA6_TX_EOF ),
      .SDMA6_TX_SOP ( SDMA6_TX_SOP ),
      .SDMA6_TX_EOP ( SDMA6_TX_EOP ),
      .SDMA6_TX_Src_Rdy ( SDMA6_TX_Src_Rdy ),
      .SDMA6_TX_Dst_Rdy ( SDMA6_TX_Dst_Rdy ),
      .SDMA6_RX_D ( SDMA6_RX_D ),
      .SDMA6_RX_Rem ( SDMA6_RX_Rem ),
      .SDMA6_RX_SOF ( SDMA6_RX_SOF ),
      .SDMA6_RX_EOF ( SDMA6_RX_EOF ),
      .SDMA6_RX_SOP ( SDMA6_RX_SOP ),
      .SDMA6_RX_EOP ( SDMA6_RX_EOP ),
      .SDMA6_RX_Src_Rdy ( SDMA6_RX_Src_Rdy ),
      .SDMA6_RX_Dst_Rdy ( SDMA6_RX_Dst_Rdy ),
      .SDMA_CTRL6_Clk ( SDMA_CTRL6_Clk ),
      .SDMA_CTRL6_Rst ( SDMA_CTRL6_Rst ),
      .SDMA_CTRL6_PLB_ABus ( SDMA_CTRL6_PLB_ABus ),
      .SDMA_CTRL6_PLB_PAValid ( SDMA_CTRL6_PLB_PAValid ),
      .SDMA_CTRL6_PLB_SAValid ( SDMA_CTRL6_PLB_SAValid ),
      .SDMA_CTRL6_PLB_masterID ( SDMA_CTRL6_PLB_masterID ),
      .SDMA_CTRL6_PLB_RNW ( SDMA_CTRL6_PLB_RNW ),
      .SDMA_CTRL6_PLB_BE ( SDMA_CTRL6_PLB_BE ),
      .SDMA_CTRL6_PLB_UABus ( SDMA_CTRL6_PLB_UABus ),
      .SDMA_CTRL6_PLB_rdPrim ( SDMA_CTRL6_PLB_rdPrim ),
      .SDMA_CTRL6_PLB_wrPrim ( SDMA_CTRL6_PLB_wrPrim ),
      .SDMA_CTRL6_PLB_abort ( SDMA_CTRL6_PLB_abort ),
      .SDMA_CTRL6_PLB_busLock ( SDMA_CTRL6_PLB_busLock ),
      .SDMA_CTRL6_PLB_MSize ( SDMA_CTRL6_PLB_MSize ),
      .SDMA_CTRL6_PLB_size ( SDMA_CTRL6_PLB_size ),
      .SDMA_CTRL6_PLB_type ( SDMA_CTRL6_PLB_type ),
      .SDMA_CTRL6_PLB_lockErr ( SDMA_CTRL6_PLB_lockErr ),
      .SDMA_CTRL6_PLB_wrPendReq ( SDMA_CTRL6_PLB_wrPendReq ),
      .SDMA_CTRL6_PLB_wrPendPri ( SDMA_CTRL6_PLB_wrPendPri ),
      .SDMA_CTRL6_PLB_rdPendReq ( SDMA_CTRL6_PLB_rdPendReq ),
      .SDMA_CTRL6_PLB_rdPendPri ( SDMA_CTRL6_PLB_rdPendPri ),
      .SDMA_CTRL6_PLB_reqPri ( SDMA_CTRL6_PLB_reqPri ),
      .SDMA_CTRL6_PLB_TAttribute ( SDMA_CTRL6_PLB_TAttribute ),
      .SDMA_CTRL6_PLB_rdBurst ( SDMA_CTRL6_PLB_rdBurst ),
      .SDMA_CTRL6_PLB_wrBurst ( SDMA_CTRL6_PLB_wrBurst ),
      .SDMA_CTRL6_PLB_wrDBus ( SDMA_CTRL6_PLB_wrDBus ),
      .SDMA_CTRL6_Sl_addrAck ( SDMA_CTRL6_Sl_addrAck ),
      .SDMA_CTRL6_Sl_SSize ( SDMA_CTRL6_Sl_SSize ),
      .SDMA_CTRL6_Sl_wait ( SDMA_CTRL6_Sl_wait ),
      .SDMA_CTRL6_Sl_rearbitrate ( SDMA_CTRL6_Sl_rearbitrate ),
      .SDMA_CTRL6_Sl_wrDAck ( SDMA_CTRL6_Sl_wrDAck ),
      .SDMA_CTRL6_Sl_wrComp ( SDMA_CTRL6_Sl_wrComp ),
      .SDMA_CTRL6_Sl_wrBTerm ( SDMA_CTRL6_Sl_wrBTerm ),
      .SDMA_CTRL6_Sl_rdDBus ( SDMA_CTRL6_Sl_rdDBus ),
      .SDMA_CTRL6_Sl_rdWdAddr ( SDMA_CTRL6_Sl_rdWdAddr ),
      .SDMA_CTRL6_Sl_rdDAck ( SDMA_CTRL6_Sl_rdDAck ),
      .SDMA_CTRL6_Sl_rdComp ( SDMA_CTRL6_Sl_rdComp ),
      .SDMA_CTRL6_Sl_rdBTerm ( SDMA_CTRL6_Sl_rdBTerm ),
      .SDMA_CTRL6_Sl_MBusy ( SDMA_CTRL6_Sl_MBusy ),
      .SDMA_CTRL6_Sl_MRdErr ( SDMA_CTRL6_Sl_MRdErr ),
      .SDMA_CTRL6_Sl_MWrErr ( SDMA_CTRL6_Sl_MWrErr ),
      .SDMA_CTRL6_Sl_MIRQ ( SDMA_CTRL6_Sl_MIRQ ),
      .PIM6_Addr ( PIM6_Addr ),
      .PIM6_AddrReq ( PIM6_AddrReq ),
      .PIM6_AddrAck ( PIM6_AddrAck ),
      .PIM6_RNW ( PIM6_RNW ),
      .PIM6_Size ( PIM6_Size ),
      .PIM6_RdModWr ( PIM6_RdModWr ),
      .PIM6_WrFIFO_Data ( PIM6_WrFIFO_Data ),
      .PIM6_WrFIFO_BE ( PIM6_WrFIFO_BE ),
      .PIM6_WrFIFO_Push ( PIM6_WrFIFO_Push ),
      .PIM6_RdFIFO_Data ( PIM6_RdFIFO_Data ),
      .PIM6_RdFIFO_Pop ( PIM6_RdFIFO_Pop ),
      .PIM6_RdFIFO_RdWdAddr ( PIM6_RdFIFO_RdWdAddr ),
      .PIM6_WrFIFO_Empty ( PIM6_WrFIFO_Empty ),
      .PIM6_WrFIFO_AlmostFull ( PIM6_WrFIFO_AlmostFull ),
      .PIM6_WrFIFO_Flush ( PIM6_WrFIFO_Flush ),
      .PIM6_RdFIFO_Empty ( PIM6_RdFIFO_Empty ),
      .PIM6_RdFIFO_Flush ( PIM6_RdFIFO_Flush ),
      .PIM6_RdFIFO_Latency ( PIM6_RdFIFO_Latency ),
      .PIM6_InitDone ( PIM6_InitDone ),
      .PPC440MC6_MIMCReadNotWrite ( PPC440MC6_MIMCReadNotWrite ),
      .PPC440MC6_MIMCAddress ( PPC440MC6_MIMCAddress ),
      .PPC440MC6_MIMCAddressValid ( PPC440MC6_MIMCAddressValid ),
      .PPC440MC6_MIMCWriteData ( PPC440MC6_MIMCWriteData ),
      .PPC440MC6_MIMCWriteDataValid ( PPC440MC6_MIMCWriteDataValid ),
      .PPC440MC6_MIMCByteEnable ( PPC440MC6_MIMCByteEnable ),
      .PPC440MC6_MIMCBankConflict ( PPC440MC6_MIMCBankConflict ),
      .PPC440MC6_MIMCRowConflict ( PPC440MC6_MIMCRowConflict ),
      .PPC440MC6_MCMIReadData ( PPC440MC6_MCMIReadData ),
      .PPC440MC6_MCMIReadDataValid ( PPC440MC6_MCMIReadDataValid ),
      .PPC440MC6_MCMIReadDataErr ( PPC440MC6_MCMIReadDataErr ),
      .PPC440MC6_MCMIAddrReadyToAccept ( PPC440MC6_MCMIAddrReadyToAccept ),
      .VFBC6_Cmd_Clk ( VFBC6_Cmd_Clk ),
      .VFBC6_Cmd_Reset ( VFBC6_Cmd_Reset ),
      .VFBC6_Cmd_Data ( VFBC6_Cmd_Data ),
      .VFBC6_Cmd_Write ( VFBC6_Cmd_Write ),
      .VFBC6_Cmd_End ( VFBC6_Cmd_End ),
      .VFBC6_Cmd_Full ( VFBC6_Cmd_Full ),
      .VFBC6_Cmd_Almost_Full ( VFBC6_Cmd_Almost_Full ),
      .VFBC6_Cmd_Idle ( VFBC6_Cmd_Idle ),
      .VFBC6_Wd_Clk ( VFBC6_Wd_Clk ),
      .VFBC6_Wd_Reset ( VFBC6_Wd_Reset ),
      .VFBC6_Wd_Write ( VFBC6_Wd_Write ),
      .VFBC6_Wd_End_Burst ( VFBC6_Wd_End_Burst ),
      .VFBC6_Wd_Flush ( VFBC6_Wd_Flush ),
      .VFBC6_Wd_Data ( VFBC6_Wd_Data ),
      .VFBC6_Wd_Data_BE ( VFBC6_Wd_Data_BE ),
      .VFBC6_Wd_Full ( VFBC6_Wd_Full ),
      .VFBC6_Wd_Almost_Full ( VFBC6_Wd_Almost_Full ),
      .VFBC6_Rd_Clk ( VFBC6_Rd_Clk ),
      .VFBC6_Rd_Reset ( VFBC6_Rd_Reset ),
      .VFBC6_Rd_Read ( VFBC6_Rd_Read ),
      .VFBC6_Rd_End_Burst ( VFBC6_Rd_End_Burst ),
      .VFBC6_Rd_Flush ( VFBC6_Rd_Flush ),
      .VFBC6_Rd_Data ( VFBC6_Rd_Data ),
      .VFBC6_Rd_Empty ( VFBC6_Rd_Empty ),
      .VFBC6_Rd_Almost_Empty ( VFBC6_Rd_Almost_Empty ),
      .MCB6_cmd_clk ( MCB6_cmd_clk ),
      .MCB6_cmd_en ( MCB6_cmd_en ),
      .MCB6_cmd_instr ( MCB6_cmd_instr ),
      .MCB6_cmd_bl ( MCB6_cmd_bl ),
      .MCB6_cmd_byte_addr ( MCB6_cmd_byte_addr ),
      .MCB6_cmd_empty ( MCB6_cmd_empty ),
      .MCB6_cmd_full ( MCB6_cmd_full ),
      .MCB6_wr_clk ( MCB6_wr_clk ),
      .MCB6_wr_en ( MCB6_wr_en ),
      .MCB6_wr_mask ( MCB6_wr_mask ),
      .MCB6_wr_data ( MCB6_wr_data ),
      .MCB6_wr_full ( MCB6_wr_full ),
      .MCB6_wr_empty ( MCB6_wr_empty ),
      .MCB6_wr_count ( MCB6_wr_count ),
      .MCB6_wr_underrun ( MCB6_wr_underrun ),
      .MCB6_wr_error ( MCB6_wr_error ),
      .MCB6_rd_clk ( MCB6_rd_clk ),
      .MCB6_rd_en ( MCB6_rd_en ),
      .MCB6_rd_data ( MCB6_rd_data ),
      .MCB6_rd_full ( MCB6_rd_full ),
      .MCB6_rd_empty ( MCB6_rd_empty ),
      .MCB6_rd_count ( MCB6_rd_count ),
      .MCB6_rd_overflow ( MCB6_rd_overflow ),
      .MCB6_rd_error ( MCB6_rd_error ),
      .FSL7_M_Clk ( FSL7_M_Clk ),
      .FSL7_M_Write ( FSL7_M_Write ),
      .FSL7_M_Data ( FSL7_M_Data ),
      .FSL7_M_Control ( FSL7_M_Control ),
      .FSL7_M_Full ( FSL7_M_Full ),
      .FSL7_S_Clk ( FSL7_S_Clk ),
      .FSL7_S_Read ( FSL7_S_Read ),
      .FSL7_S_Data ( FSL7_S_Data ),
      .FSL7_S_Control ( FSL7_S_Control ),
      .FSL7_S_Exists ( FSL7_S_Exists ),
      .FSL7_B_M_Clk ( FSL7_B_M_Clk ),
      .FSL7_B_M_Write ( FSL7_B_M_Write ),
      .FSL7_B_M_Data ( FSL7_B_M_Data ),
      .FSL7_B_M_Control ( FSL7_B_M_Control ),
      .FSL7_B_M_Full ( FSL7_B_M_Full ),
      .FSL7_B_S_Clk ( FSL7_B_S_Clk ),
      .FSL7_B_S_Read ( FSL7_B_S_Read ),
      .FSL7_B_S_Data ( FSL7_B_S_Data ),
      .FSL7_B_S_Control ( FSL7_B_S_Control ),
      .FSL7_B_S_Exists ( FSL7_B_S_Exists ),
      .SPLB7_Clk ( SPLB7_Clk ),
      .SPLB7_Rst ( SPLB7_Rst ),
      .SPLB7_PLB_ABus ( SPLB7_PLB_ABus ),
      .SPLB7_PLB_PAValid ( SPLB7_PLB_PAValid ),
      .SPLB7_PLB_SAValid ( SPLB7_PLB_SAValid ),
      .SPLB7_PLB_masterID ( SPLB7_PLB_masterID ),
      .SPLB7_PLB_RNW ( SPLB7_PLB_RNW ),
      .SPLB7_PLB_BE ( SPLB7_PLB_BE ),
      .SPLB7_PLB_UABus ( SPLB7_PLB_UABus ),
      .SPLB7_PLB_rdPrim ( SPLB7_PLB_rdPrim ),
      .SPLB7_PLB_wrPrim ( SPLB7_PLB_wrPrim ),
      .SPLB7_PLB_abort ( SPLB7_PLB_abort ),
      .SPLB7_PLB_busLock ( SPLB7_PLB_busLock ),
      .SPLB7_PLB_MSize ( SPLB7_PLB_MSize ),
      .SPLB7_PLB_size ( SPLB7_PLB_size ),
      .SPLB7_PLB_type ( SPLB7_PLB_type ),
      .SPLB7_PLB_lockErr ( SPLB7_PLB_lockErr ),
      .SPLB7_PLB_wrPendReq ( SPLB7_PLB_wrPendReq ),
      .SPLB7_PLB_wrPendPri ( SPLB7_PLB_wrPendPri ),
      .SPLB7_PLB_rdPendReq ( SPLB7_PLB_rdPendReq ),
      .SPLB7_PLB_rdPendPri ( SPLB7_PLB_rdPendPri ),
      .SPLB7_PLB_reqPri ( SPLB7_PLB_reqPri ),
      .SPLB7_PLB_TAttribute ( SPLB7_PLB_TAttribute ),
      .SPLB7_PLB_rdBurst ( SPLB7_PLB_rdBurst ),
      .SPLB7_PLB_wrBurst ( SPLB7_PLB_wrBurst ),
      .SPLB7_PLB_wrDBus ( SPLB7_PLB_wrDBus ),
      .SPLB7_Sl_addrAck ( SPLB7_Sl_addrAck ),
      .SPLB7_Sl_SSize ( SPLB7_Sl_SSize ),
      .SPLB7_Sl_wait ( SPLB7_Sl_wait ),
      .SPLB7_Sl_rearbitrate ( SPLB7_Sl_rearbitrate ),
      .SPLB7_Sl_wrDAck ( SPLB7_Sl_wrDAck ),
      .SPLB7_Sl_wrComp ( SPLB7_Sl_wrComp ),
      .SPLB7_Sl_wrBTerm ( SPLB7_Sl_wrBTerm ),
      .SPLB7_Sl_rdDBus ( SPLB7_Sl_rdDBus ),
      .SPLB7_Sl_rdWdAddr ( SPLB7_Sl_rdWdAddr ),
      .SPLB7_Sl_rdDAck ( SPLB7_Sl_rdDAck ),
      .SPLB7_Sl_rdComp ( SPLB7_Sl_rdComp ),
      .SPLB7_Sl_rdBTerm ( SPLB7_Sl_rdBTerm ),
      .SPLB7_Sl_MBusy ( SPLB7_Sl_MBusy ),
      .SPLB7_Sl_MRdErr ( SPLB7_Sl_MRdErr ),
      .SPLB7_Sl_MWrErr ( SPLB7_Sl_MWrErr ),
      .SPLB7_Sl_MIRQ ( SPLB7_Sl_MIRQ ),
      .SDMA7_Clk ( SDMA7_Clk ),
      .SDMA7_Rx_IntOut ( SDMA7_Rx_IntOut ),
      .SDMA7_Tx_IntOut ( SDMA7_Tx_IntOut ),
      .SDMA7_RstOut ( SDMA7_RstOut ),
      .SDMA7_TX_D ( SDMA7_TX_D ),
      .SDMA7_TX_Rem ( SDMA7_TX_Rem ),
      .SDMA7_TX_SOF ( SDMA7_TX_SOF ),
      .SDMA7_TX_EOF ( SDMA7_TX_EOF ),
      .SDMA7_TX_SOP ( SDMA7_TX_SOP ),
      .SDMA7_TX_EOP ( SDMA7_TX_EOP ),
      .SDMA7_TX_Src_Rdy ( SDMA7_TX_Src_Rdy ),
      .SDMA7_TX_Dst_Rdy ( SDMA7_TX_Dst_Rdy ),
      .SDMA7_RX_D ( SDMA7_RX_D ),
      .SDMA7_RX_Rem ( SDMA7_RX_Rem ),
      .SDMA7_RX_SOF ( SDMA7_RX_SOF ),
      .SDMA7_RX_EOF ( SDMA7_RX_EOF ),
      .SDMA7_RX_SOP ( SDMA7_RX_SOP ),
      .SDMA7_RX_EOP ( SDMA7_RX_EOP ),
      .SDMA7_RX_Src_Rdy ( SDMA7_RX_Src_Rdy ),
      .SDMA7_RX_Dst_Rdy ( SDMA7_RX_Dst_Rdy ),
      .SDMA_CTRL7_Clk ( SDMA_CTRL7_Clk ),
      .SDMA_CTRL7_Rst ( SDMA_CTRL7_Rst ),
      .SDMA_CTRL7_PLB_ABus ( SDMA_CTRL7_PLB_ABus ),
      .SDMA_CTRL7_PLB_PAValid ( SDMA_CTRL7_PLB_PAValid ),
      .SDMA_CTRL7_PLB_SAValid ( SDMA_CTRL7_PLB_SAValid ),
      .SDMA_CTRL7_PLB_masterID ( SDMA_CTRL7_PLB_masterID ),
      .SDMA_CTRL7_PLB_RNW ( SDMA_CTRL7_PLB_RNW ),
      .SDMA_CTRL7_PLB_BE ( SDMA_CTRL7_PLB_BE ),
      .SDMA_CTRL7_PLB_UABus ( SDMA_CTRL7_PLB_UABus ),
      .SDMA_CTRL7_PLB_rdPrim ( SDMA_CTRL7_PLB_rdPrim ),
      .SDMA_CTRL7_PLB_wrPrim ( SDMA_CTRL7_PLB_wrPrim ),
      .SDMA_CTRL7_PLB_abort ( SDMA_CTRL7_PLB_abort ),
      .SDMA_CTRL7_PLB_busLock ( SDMA_CTRL7_PLB_busLock ),
      .SDMA_CTRL7_PLB_MSize ( SDMA_CTRL7_PLB_MSize ),
      .SDMA_CTRL7_PLB_size ( SDMA_CTRL7_PLB_size ),
      .SDMA_CTRL7_PLB_type ( SDMA_CTRL7_PLB_type ),
      .SDMA_CTRL7_PLB_lockErr ( SDMA_CTRL7_PLB_lockErr ),
      .SDMA_CTRL7_PLB_wrPendReq ( SDMA_CTRL7_PLB_wrPendReq ),
      .SDMA_CTRL7_PLB_wrPendPri ( SDMA_CTRL7_PLB_wrPendPri ),
      .SDMA_CTRL7_PLB_rdPendReq ( SDMA_CTRL7_PLB_rdPendReq ),
      .SDMA_CTRL7_PLB_rdPendPri ( SDMA_CTRL7_PLB_rdPendPri ),
      .SDMA_CTRL7_PLB_reqPri ( SDMA_CTRL7_PLB_reqPri ),
      .SDMA_CTRL7_PLB_TAttribute ( SDMA_CTRL7_PLB_TAttribute ),
      .SDMA_CTRL7_PLB_rdBurst ( SDMA_CTRL7_PLB_rdBurst ),
      .SDMA_CTRL7_PLB_wrBurst ( SDMA_CTRL7_PLB_wrBurst ),
      .SDMA_CTRL7_PLB_wrDBus ( SDMA_CTRL7_PLB_wrDBus ),
      .SDMA_CTRL7_Sl_addrAck ( SDMA_CTRL7_Sl_addrAck ),
      .SDMA_CTRL7_Sl_SSize ( SDMA_CTRL7_Sl_SSize ),
      .SDMA_CTRL7_Sl_wait ( SDMA_CTRL7_Sl_wait ),
      .SDMA_CTRL7_Sl_rearbitrate ( SDMA_CTRL7_Sl_rearbitrate ),
      .SDMA_CTRL7_Sl_wrDAck ( SDMA_CTRL7_Sl_wrDAck ),
      .SDMA_CTRL7_Sl_wrComp ( SDMA_CTRL7_Sl_wrComp ),
      .SDMA_CTRL7_Sl_wrBTerm ( SDMA_CTRL7_Sl_wrBTerm ),
      .SDMA_CTRL7_Sl_rdDBus ( SDMA_CTRL7_Sl_rdDBus ),
      .SDMA_CTRL7_Sl_rdWdAddr ( SDMA_CTRL7_Sl_rdWdAddr ),
      .SDMA_CTRL7_Sl_rdDAck ( SDMA_CTRL7_Sl_rdDAck ),
      .SDMA_CTRL7_Sl_rdComp ( SDMA_CTRL7_Sl_rdComp ),
      .SDMA_CTRL7_Sl_rdBTerm ( SDMA_CTRL7_Sl_rdBTerm ),
      .SDMA_CTRL7_Sl_MBusy ( SDMA_CTRL7_Sl_MBusy ),
      .SDMA_CTRL7_Sl_MRdErr ( SDMA_CTRL7_Sl_MRdErr ),
      .SDMA_CTRL7_Sl_MWrErr ( SDMA_CTRL7_Sl_MWrErr ),
      .SDMA_CTRL7_Sl_MIRQ ( SDMA_CTRL7_Sl_MIRQ ),
      .PIM7_Addr ( PIM7_Addr ),
      .PIM7_AddrReq ( PIM7_AddrReq ),
      .PIM7_AddrAck ( PIM7_AddrAck ),
      .PIM7_RNW ( PIM7_RNW ),
      .PIM7_Size ( PIM7_Size ),
      .PIM7_RdModWr ( PIM7_RdModWr ),
      .PIM7_WrFIFO_Data ( PIM7_WrFIFO_Data ),
      .PIM7_WrFIFO_BE ( PIM7_WrFIFO_BE ),
      .PIM7_WrFIFO_Push ( PIM7_WrFIFO_Push ),
      .PIM7_RdFIFO_Data ( PIM7_RdFIFO_Data ),
      .PIM7_RdFIFO_Pop ( PIM7_RdFIFO_Pop ),
      .PIM7_RdFIFO_RdWdAddr ( PIM7_RdFIFO_RdWdAddr ),
      .PIM7_WrFIFO_Empty ( PIM7_WrFIFO_Empty ),
      .PIM7_WrFIFO_AlmostFull ( PIM7_WrFIFO_AlmostFull ),
      .PIM7_WrFIFO_Flush ( PIM7_WrFIFO_Flush ),
      .PIM7_RdFIFO_Empty ( PIM7_RdFIFO_Empty ),
      .PIM7_RdFIFO_Flush ( PIM7_RdFIFO_Flush ),
      .PIM7_RdFIFO_Latency ( PIM7_RdFIFO_Latency ),
      .PIM7_InitDone ( PIM7_InitDone ),
      .PPC440MC7_MIMCReadNotWrite ( PPC440MC7_MIMCReadNotWrite ),
      .PPC440MC7_MIMCAddress ( PPC440MC7_MIMCAddress ),
      .PPC440MC7_MIMCAddressValid ( PPC440MC7_MIMCAddressValid ),
      .PPC440MC7_MIMCWriteData ( PPC440MC7_MIMCWriteData ),
      .PPC440MC7_MIMCWriteDataValid ( PPC440MC7_MIMCWriteDataValid ),
      .PPC440MC7_MIMCByteEnable ( PPC440MC7_MIMCByteEnable ),
      .PPC440MC7_MIMCBankConflict ( PPC440MC7_MIMCBankConflict ),
      .PPC440MC7_MIMCRowConflict ( PPC440MC7_MIMCRowConflict ),
      .PPC440MC7_MCMIReadData ( PPC440MC7_MCMIReadData ),
      .PPC440MC7_MCMIReadDataValid ( PPC440MC7_MCMIReadDataValid ),
      .PPC440MC7_MCMIReadDataErr ( PPC440MC7_MCMIReadDataErr ),
      .PPC440MC7_MCMIAddrReadyToAccept ( PPC440MC7_MCMIAddrReadyToAccept ),
      .VFBC7_Cmd_Clk ( VFBC7_Cmd_Clk ),
      .VFBC7_Cmd_Reset ( VFBC7_Cmd_Reset ),
      .VFBC7_Cmd_Data ( VFBC7_Cmd_Data ),
      .VFBC7_Cmd_Write ( VFBC7_Cmd_Write ),
      .VFBC7_Cmd_End ( VFBC7_Cmd_End ),
      .VFBC7_Cmd_Full ( VFBC7_Cmd_Full ),
      .VFBC7_Cmd_Almost_Full ( VFBC7_Cmd_Almost_Full ),
      .VFBC7_Cmd_Idle ( VFBC7_Cmd_Idle ),
      .VFBC7_Wd_Clk ( VFBC7_Wd_Clk ),
      .VFBC7_Wd_Reset ( VFBC7_Wd_Reset ),
      .VFBC7_Wd_Write ( VFBC7_Wd_Write ),
      .VFBC7_Wd_End_Burst ( VFBC7_Wd_End_Burst ),
      .VFBC7_Wd_Flush ( VFBC7_Wd_Flush ),
      .VFBC7_Wd_Data ( VFBC7_Wd_Data ),
      .VFBC7_Wd_Data_BE ( VFBC7_Wd_Data_BE ),
      .VFBC7_Wd_Full ( VFBC7_Wd_Full ),
      .VFBC7_Wd_Almost_Full ( VFBC7_Wd_Almost_Full ),
      .VFBC7_Rd_Clk ( VFBC7_Rd_Clk ),
      .VFBC7_Rd_Reset ( VFBC7_Rd_Reset ),
      .VFBC7_Rd_Read ( VFBC7_Rd_Read ),
      .VFBC7_Rd_End_Burst ( VFBC7_Rd_End_Burst ),
      .VFBC7_Rd_Flush ( VFBC7_Rd_Flush ),
      .VFBC7_Rd_Data ( VFBC7_Rd_Data ),
      .VFBC7_Rd_Empty ( VFBC7_Rd_Empty ),
      .VFBC7_Rd_Almost_Empty ( VFBC7_Rd_Almost_Empty ),
      .MCB7_cmd_clk ( MCB7_cmd_clk ),
      .MCB7_cmd_en ( MCB7_cmd_en ),
      .MCB7_cmd_instr ( MCB7_cmd_instr ),
      .MCB7_cmd_bl ( MCB7_cmd_bl ),
      .MCB7_cmd_byte_addr ( MCB7_cmd_byte_addr ),
      .MCB7_cmd_empty ( MCB7_cmd_empty ),
      .MCB7_cmd_full ( MCB7_cmd_full ),
      .MCB7_wr_clk ( MCB7_wr_clk ),
      .MCB7_wr_en ( MCB7_wr_en ),
      .MCB7_wr_mask ( MCB7_wr_mask ),
      .MCB7_wr_data ( MCB7_wr_data ),
      .MCB7_wr_full ( MCB7_wr_full ),
      .MCB7_wr_empty ( MCB7_wr_empty ),
      .MCB7_wr_count ( MCB7_wr_count ),
      .MCB7_wr_underrun ( MCB7_wr_underrun ),
      .MCB7_wr_error ( MCB7_wr_error ),
      .MCB7_rd_clk ( MCB7_rd_clk ),
      .MCB7_rd_en ( MCB7_rd_en ),
      .MCB7_rd_data ( MCB7_rd_data ),
      .MCB7_rd_full ( MCB7_rd_full ),
      .MCB7_rd_empty ( MCB7_rd_empty ),
      .MCB7_rd_count ( MCB7_rd_count ),
      .MCB7_rd_overflow ( MCB7_rd_overflow ),
      .MCB7_rd_error ( MCB7_rd_error ),
      .MPMC_CTRL_Clk ( MPMC_CTRL_Clk ),
      .MPMC_CTRL_Rst ( MPMC_CTRL_Rst ),
      .MPMC_CTRL_PLB_ABus ( MPMC_CTRL_PLB_ABus ),
      .MPMC_CTRL_PLB_PAValid ( MPMC_CTRL_PLB_PAValid ),
      .MPMC_CTRL_PLB_SAValid ( MPMC_CTRL_PLB_SAValid ),
      .MPMC_CTRL_PLB_masterID ( MPMC_CTRL_PLB_masterID ),
      .MPMC_CTRL_PLB_RNW ( MPMC_CTRL_PLB_RNW ),
      .MPMC_CTRL_PLB_BE ( MPMC_CTRL_PLB_BE ),
      .MPMC_CTRL_PLB_UABus ( MPMC_CTRL_PLB_UABus ),
      .MPMC_CTRL_PLB_rdPrim ( MPMC_CTRL_PLB_rdPrim ),
      .MPMC_CTRL_PLB_wrPrim ( MPMC_CTRL_PLB_wrPrim ),
      .MPMC_CTRL_PLB_abort ( MPMC_CTRL_PLB_abort ),
      .MPMC_CTRL_PLB_busLock ( MPMC_CTRL_PLB_busLock ),
      .MPMC_CTRL_PLB_MSize ( MPMC_CTRL_PLB_MSize ),
      .MPMC_CTRL_PLB_size ( MPMC_CTRL_PLB_size ),
      .MPMC_CTRL_PLB_type ( MPMC_CTRL_PLB_type ),
      .MPMC_CTRL_PLB_lockErr ( MPMC_CTRL_PLB_lockErr ),
      .MPMC_CTRL_PLB_wrPendReq ( MPMC_CTRL_PLB_wrPendReq ),
      .MPMC_CTRL_PLB_wrPendPri ( MPMC_CTRL_PLB_wrPendPri ),
      .MPMC_CTRL_PLB_rdPendReq ( MPMC_CTRL_PLB_rdPendReq ),
      .MPMC_CTRL_PLB_rdPendPri ( MPMC_CTRL_PLB_rdPendPri ),
      .MPMC_CTRL_PLB_reqPri ( MPMC_CTRL_PLB_reqPri ),
      .MPMC_CTRL_PLB_TAttribute ( MPMC_CTRL_PLB_TAttribute ),
      .MPMC_CTRL_PLB_rdBurst ( MPMC_CTRL_PLB_rdBurst ),
      .MPMC_CTRL_PLB_wrBurst ( MPMC_CTRL_PLB_wrBurst ),
      .MPMC_CTRL_PLB_wrDBus ( MPMC_CTRL_PLB_wrDBus ),
      .MPMC_CTRL_Sl_addrAck ( MPMC_CTRL_Sl_addrAck ),
      .MPMC_CTRL_Sl_SSize ( MPMC_CTRL_Sl_SSize ),
      .MPMC_CTRL_Sl_wait ( MPMC_CTRL_Sl_wait ),
      .MPMC_CTRL_Sl_rearbitrate ( MPMC_CTRL_Sl_rearbitrate ),
      .MPMC_CTRL_Sl_wrDAck ( MPMC_CTRL_Sl_wrDAck ),
      .MPMC_CTRL_Sl_wrComp ( MPMC_CTRL_Sl_wrComp ),
      .MPMC_CTRL_Sl_wrBTerm ( MPMC_CTRL_Sl_wrBTerm ),
      .MPMC_CTRL_Sl_rdDBus ( MPMC_CTRL_Sl_rdDBus ),
      .MPMC_CTRL_Sl_rdWdAddr ( MPMC_CTRL_Sl_rdWdAddr ),
      .MPMC_CTRL_Sl_rdDAck ( MPMC_CTRL_Sl_rdDAck ),
      .MPMC_CTRL_Sl_rdComp ( MPMC_CTRL_Sl_rdComp ),
      .MPMC_CTRL_Sl_rdBTerm ( MPMC_CTRL_Sl_rdBTerm ),
      .MPMC_CTRL_Sl_MBusy ( MPMC_CTRL_Sl_MBusy ),
      .MPMC_CTRL_Sl_MRdErr ( MPMC_CTRL_Sl_MRdErr ),
      .MPMC_CTRL_Sl_MWrErr ( MPMC_CTRL_Sl_MWrErr ),
      .MPMC_CTRL_Sl_MIRQ ( MPMC_CTRL_Sl_MIRQ ),
      .MPMC_Clk0 ( MPMC_Clk0 ),
      .MPMC_Clk0_DIV2 ( MPMC_Clk0_DIV2 ),
      .MPMC_Clk90 ( MPMC_Clk90 ),
      .MPMC_Clk_200MHz ( MPMC_Clk_200MHz ),
      .MPMC_Rst ( MPMC_Rst ),
      .MPMC_Clk_Mem ( MPMC_Clk_Mem ),
      .MPMC_Clk_Mem_2x ( MPMC_Clk_Mem_2x ),
      .MPMC_Clk_Mem_2x_180 ( MPMC_Clk_Mem_2x_180 ),
      .MPMC_Clk_Mem_2x_CE0 ( MPMC_Clk_Mem_2x_CE0 ),
      .MPMC_Clk_Mem_2x_CE90 ( MPMC_Clk_Mem_2x_CE90 ),
      .MPMC_Clk_Rd_Base ( MPMC_Clk_Rd_Base ),
      .MPMC_Clk_Mem_2x_bufpll_o ( MPMC_Clk_Mem_2x_bufpll_o ),
      .MPMC_Clk_Mem_2x_180_bufpll_o ( MPMC_Clk_Mem_2x_180_bufpll_o ),
      .MPMC_Clk_Mem_2x_CE0_bufpll_o ( MPMC_Clk_Mem_2x_CE0_bufpll_o ),
      .MPMC_Clk_Mem_2x_CE90_bufpll_o ( MPMC_Clk_Mem_2x_CE90_bufpll_o ),
      .MPMC_PLL_Lock_bufpll_o ( MPMC_PLL_Lock_bufpll_o ),
      .MPMC_PLL_Lock ( MPMC_PLL_Lock ),
      .MPMC_Idelayctrl_Rdy_I ( MPMC_Idelayctrl_Rdy_I ),
      .MPMC_Idelayctrl_Rdy_O ( MPMC_Idelayctrl_Rdy_O ),
      .MPMC_InitDone ( MPMC_InitDone ),
      .MPMC_ECC_Intr ( MPMC_ECC_Intr ),
      .MPMC_DCM_PSEN ( MPMC_DCM_PSEN ),
      .MPMC_DCM_PSINCDEC ( MPMC_DCM_PSINCDEC ),
      .MPMC_DCM_PSDONE ( MPMC_DCM_PSDONE ),
      .MPMC_MCB_DRP_Clk ( MPMC_MCB_DRP_Clk ),
      .SDRAM_Clk ( SDRAM_Clk ),
      .SDRAM_CE ( SDRAM_CE ),
      .SDRAM_CS_n ( SDRAM_CS_n ),
      .SDRAM_RAS_n ( SDRAM_RAS_n ),
      .SDRAM_CAS_n ( SDRAM_CAS_n ),
      .SDRAM_WE_n ( SDRAM_WE_n ),
      .SDRAM_BankAddr ( SDRAM_BankAddr ),
      .SDRAM_Addr ( SDRAM_Addr ),
      .SDRAM_DQ ( SDRAM_DQ ),
      .SDRAM_DM ( SDRAM_DM ),
      .DDR_Clk ( DDR_Clk ),
      .DDR_Clk_n ( DDR_Clk_n ),
      .DDR_CE ( DDR_CE ),
      .DDR_CS_n ( DDR_CS_n ),
      .DDR_RAS_n ( DDR_RAS_n ),
      .DDR_CAS_n ( DDR_CAS_n ),
      .DDR_WE_n ( DDR_WE_n ),
      .DDR_BankAddr ( DDR_BankAddr ),
      .DDR_Addr ( DDR_Addr ),
      .DDR_DQ ( DDR_DQ ),
      .DDR_DM ( DDR_DM ),
      .DDR_DQS ( DDR_DQS ),
      .DDR_DQS_Div_O ( DDR_DQS_Div_O ),
      .DDR_DQS_Div_I ( DDR_DQS_Div_I ),
      .DDR2_Clk ( DDR2_Clk ),
      .DDR2_Clk_n ( DDR2_Clk_n ),
      .DDR2_CE ( DDR2_CE ),
      .DDR2_CS_n ( DDR2_CS_n ),
      .DDR2_ODT ( DDR2_ODT ),
      .DDR2_RAS_n ( DDR2_RAS_n ),
      .DDR2_CAS_n ( DDR2_CAS_n ),
      .DDR2_WE_n ( DDR2_WE_n ),
      .DDR2_BankAddr ( DDR2_BankAddr ),
      .DDR2_Addr ( DDR2_Addr ),
      .DDR2_DQ ( DDR2_DQ ),
      .DDR2_DM ( DDR2_DM ),
      .DDR2_DQS ( DDR2_DQS ),
      .DDR2_DQS_n ( DDR2_DQS_n ),
      .DDR2_DQS_Div_O ( DDR2_DQS_Div_O ),
      .DDR2_DQS_Div_I ( DDR2_DQS_Div_I ),
      .DDR3_Clk ( DDR3_Clk ),
      .DDR3_Clk_n ( DDR3_Clk_n ),
      .DDR3_CE ( DDR3_CE ),
      .DDR3_CS_n ( DDR3_CS_n ),
      .DDR3_ODT ( DDR3_ODT ),
      .DDR3_RAS_n ( DDR3_RAS_n ),
      .DDR3_CAS_n ( DDR3_CAS_n ),
      .DDR3_WE_n ( DDR3_WE_n ),
      .DDR3_BankAddr ( DDR3_BankAddr ),
      .DDR3_Addr ( DDR3_Addr ),
      .DDR3_DQ ( DDR3_DQ ),
      .DDR3_DM ( DDR3_DM ),
      .DDR3_Reset_n ( DDR3_Reset_n ),
      .DDR3_DQS ( DDR3_DQS ),
      .DDR3_DQS_n ( DDR3_DQS_n ),
      .mcbx_dram_addr ( mcbx_dram_addr ),
      .mcbx_dram_ba ( mcbx_dram_ba ),
      .mcbx_dram_ras_n ( mcbx_dram_ras_n ),
      .mcbx_dram_cas_n ( mcbx_dram_cas_n ),
      .mcbx_dram_we_n ( mcbx_dram_we_n ),
      .mcbx_dram_cke ( mcbx_dram_cke ),
      .mcbx_dram_clk ( mcbx_dram_clk ),
      .mcbx_dram_clk_n ( mcbx_dram_clk_n ),
      .mcbx_dram_dq ( mcbx_dram_dq ),
      .mcbx_dram_dqs ( mcbx_dram_dqs ),
      .mcbx_dram_dqs_n ( mcbx_dram_dqs_n ),
      .mcbx_dram_udqs ( mcbx_dram_udqs ),
      .mcbx_dram_udqs_n ( mcbx_dram_udqs_n ),
      .mcbx_dram_udm ( mcbx_dram_udm ),
      .mcbx_dram_ldm ( mcbx_dram_ldm ),
      .mcbx_dram_odt ( mcbx_dram_odt ),
      .mcbx_dram_ddr3_rst ( mcbx_dram_ddr3_rst ),
      .selfrefresh_enter ( selfrefresh_enter ),
      .selfrefresh_mode ( selfrefresh_mode ),
      .calib_recal ( calib_recal ),
      .rzq ( rzq ),
      .zio ( zio )
    );

endmodule

