if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists dmapath] } { set dmapath "/tb${ps}dma0" }

set binopt {-logic}
set hexopt {-literal -hex}
set ascopt {-literal -asc}

eval add wave -noupdate -divider {"dma"}
eval add wave -noupdate $binopt $dmapath${ps}sys_clk
eval add wave -noupdate $binopt $dmapath${ps}sys_rst

eval add wave -noupdate $binopt $dmapath${ps}irq
eval add wave -noupdate $binopt $dmapath${ps}write
eval add wave -noupdate $hexopt $dmapath${ps}address
eval add wave -noupdate $hexopt $dmapath${ps}writedata
eval add wave -noupdate $hexopt $dmapath${ps}readdata

eval add wave -noupdate -divider {"dcr"}
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}StartComm
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}CommInit
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}phyreset

eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}linkup
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}irq_stat

eval add wave -noupdate $hexopt $dmapath${ps}dcr_if${ps}error_code
eval add wave -noupdate $hexopt $dmapath${ps}dcr_if${ps}dma_address
eval add wave -noupdate $hexopt $dmapath${ps}dcr_if${ps}dma_length
eval add wave -noupdate $hexopt $dmapath${ps}dcr_if${ps}dma_pm
eval add wave -noupdate $hexopt $dmapath${ps}dcr_if${ps}dma_data
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}dma_ok
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}dma_req
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}dma_sync
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}dma_flush
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}dma_eof
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}dma_ack
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}dma_irq

eval add wave -noupdate $hexopt $dmapath${ps}dcr_if${ps}rxfifo_fis_hdr
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}rxfifo_irq
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}cxfifo_irq
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}cxfifo_ack
eval add wave -noupdate $binopt $dmapath${ps}dcr_if${ps}cxfifo_ok

eval add wave -noupdate -divider {"dma"}
eval add wave -noupdate $binopt $dmapath${ps}sys_clk

eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}state
eval add wave -noupdate $ascopt $dmapath${ps}dma${ps}state_ascii

eval add wave -noupdate $binopt $dmapath${ps}dma${ps}rxfifo_almost_empty
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}rxfifo_empty
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}rxfifo_sof
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}rxfifo_eof
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}rxfifo_data
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}rxfifo_rd_en
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}rxfifo_rd_count
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}rxfifo_eof_rdy

eval add wave -noupdate $binopt $dmapath${ps}dma${ps}wr_rdy
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}wr_len

eval add wave -noupdate $binopt $dmapath${ps}sys_clk
eval add wave -noupdate $binopt $dmapath${ps}MPMC_Clk

#eval add wave -noupdate $binopt $dmapath${ps}dma${ps}AddrReq
#eval add wave -noupdate $binopt $dmapath${ps}dma${ps}AddrAck
#eval add wave -noupdate $binopt $dmapath${ps}dma${ps}RdFIFO_Pop
#eval add wave -noupdate $binopt $dmapath${ps}dma${ps}WrFIFO_Push

eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_AddrReq
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_AddrAck
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}PIM_Addr
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}PIM_Size
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_RNW
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_RdModWr

eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}PIM_RdFIFO_RdWdAddr
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}PIM_RdFIFO_Data
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_RdFIFO_Flush
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_RdFIFO_Pop
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_RdFIFO_Empty
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_RdFIFO_Latency

eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}PIM_WrFIFO_Data
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}PIM_WrFIFO_BE
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_WrFIFO_Push
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_WrFIFO_Flush
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_WrFIFO_Empty
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}PIM_WrFIFO_AlmostFull

eval add wave -noupdate $binopt $dmapath${ps}dma${ps}txfifo_wr_en
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}txfifo_sof
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}txfifo_eof
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}txfifo_data
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}txfifo_almost_full
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}txfifo_count
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}txfifo_eof_poped
eval add wave -noupdate $binopt $dmapath${ps}dma${ps}rd_rdy
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}rd_len
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}rlen
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}m_len
eval add wave -noupdate $hexopt $dmapath${ps}dma${ps}m_low

eval add wave -noupdate -divider {"rxll"}
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}sys_clk
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}sys_rst

eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxfifo_data
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxfifo_empty
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxfifo_almost_empty
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxfifo_eof
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxfifo_sof
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxfifo_fis_hdr
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxfifo_rd_count
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxfifo_rd_en
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxfifo_eof_rdy

eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}phyclk
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}phyreset

eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}trn_reof_n
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}trn_rsof_n
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}trn_rsrc_rdy_n
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}trn_rsrc_dsc_n
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}trn_rdst_rdy_n
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}trn_rdst_dsc_n
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}trn_rd

eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxll_ll${ps}ram_di
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_ll${ps}ram_we
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxll_ll${ps}waddr
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxll_ll${ps}rxfis_raddr
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxll_ll${ps}rxfis_rdata

eval add wave -noupdate -divider {"rxll wr side"}
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}rst
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}wr_clk
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxll_fifo${ps}wr_count
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}wr_full
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}wr_almost_full
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxll_fifo${ps}wr_di
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}wr_en

eval add wave -noupdate -divider {"rxll rd side"}
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}rst
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}rd_clk
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxll_fifo${ps}rd_count
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}rd_empty
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}rd_almost_empty
eval add wave -noupdate $hexopt $dmapath${ps}rxll${ps}rxll_fifo${ps}rd_do
eval add wave -noupdate $binopt $dmapath${ps}rxll${ps}rxll_fifo${ps}rd_en

eval add wave -noupdate -divider {"txll"}
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}sys_clk
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}sys_rst

eval add wave -noupdate $hexopt $dmapath${ps}txll${ps}txfifo_data
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}txfifo_almost_full
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}txfifo_eof
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}txfifo_sof
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}txfifo_wr_en

eval add wave -noupdate $binopt $dmapath${ps}txll${ps}phyclk
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}phyreset

eval add wave -noupdate $binopt $dmapath${ps}txll${ps}trn_teof_n
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}trn_tsof_n
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}trn_tsrc_rdy_n
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}trn_tsrc_dsc_n
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}trn_tdst_rdy_n
eval add wave -noupdate $binopt $dmapath${ps}txll${ps}trn_tdst_dsc_n
eval add wave -noupdate $hexopt $dmapath${ps}txll${ps}trn_td

eval add wave -noupdate -divider {"cxll"}
eval add wave -noupdate $binopt $dmapath${ps}cxll${ps}sys_clk
eval add wave -noupdate $binopt $dmapath${ps}cxll${ps}sys_rst

eval add wave -noupdate $hexopt $dmapath${ps}cxll${ps}trn_cd
eval add wave -noupdate $binopt $dmapath${ps}cxll${ps}trn_csrc_rdy_n
eval add wave -noupdate $binopt $dmapath${ps}cxll${ps}trn_cdst_rdy_n
eval add wave -noupdate $binopt $dmapath${ps}cxll${ps}trn_csrc_dsc_n
eval add wave -noupdate $binopt $dmapath${ps}cxll${ps}trn_cdst_dsc_n
eval add wave -noupdate $hexopt $dmapath${ps}cxll${ps}error_code

eval add wave -noupdate $binopt $dmapath${ps}cxll${ps}phyclk
eval add wave -noupdate $binopt $dmapath${ps}cxll${ps}phyreset
