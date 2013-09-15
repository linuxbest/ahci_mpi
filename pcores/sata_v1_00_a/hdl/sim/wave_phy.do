if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "/tb" }

set binopt {-logic}
set hexopt {-literal -hex}
set ascopt {-literal -ascii}

set v5_cmp [string compare $C_FAMILY "virtex5"]
set v6_cmp [string compare $C_FAMILY "spartan6"]
set k7_cmp [string compare $C_FAMILY "kirtex7"]

if {$v5_cmp == 0} {
	set lltype "v5_gtx_top"
}
if {$v6_cmp == 0} {
	set lltype "s6_gtp_top"
}
if {$k7_cmp == 0} {
	set lltype "k7_gtx_top"
}

#eval add wave -noupdate -divider {"gtp internal"}
#set gtp $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}rocketio_wrapper_i${ps}tile0_s6_gtpwizard_v1_11_i
#eval add wave -noupdate $binopt $gtp${ps}gtpa1_dual_i${ps}CLK00
#eval add wave -noupdate $binopt $gtp${ps}gtpa1_dual_i${ps}CLK01
#eval add wave -noupdate $binopt $gtp${ps}gtpa1_dual_i${ps}GTPRESET0
#eval add wave -noupdate $binopt $gtp${ps}gtpa1_dual_i${ps}GTPRESET1
#eval add wave -noupdate $binopt $gtp${ps}gtpa1_dual_i${ps}PLLLKDET0
#eval add wave -noupdate $binopt $gtp${ps}gtpa1_dual_i${ps}PLLLKDET1


eval add wave -noupdate -divider {"satagtx_internal"}

eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}phy_if_gtx0${ps}phy2cs_k
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}phy_if_gtx0${ps}rx_k_tmp
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}phy_if_gtx0${ps}rxcharisk
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}phy_if_gtx0${ps}phy_sync_0001
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}phy_if_gtx0${ps}phy_sync_0010
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}phy_if_gtx0${ps}phy_sync_0100
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}phy_if_gtx0${ps}phy_sync_1000

eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}dcm_locked
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}txusrclk0
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}txusrclk20

eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}refclk
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}GTXRESET_IN
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}txusrclk0
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}txusrclk20
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}phyreset0
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}txcomstart
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}txcomtype
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}txelecidle
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}rxelecidle
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}StartComm0
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}CommInit0

#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}tile0_resetdone0_i
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}tile0_txenpmaphasealign0_i
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}tile0_txpmasetphase0_i
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}tile0_tx_resetdone0_r2
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}tile0_tx_sync_done0_i

eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}txdata
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}txdatak

eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}rxdata_fis0
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}rxcharisk0

#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}EXAMPLE_SIM_GTXRESET_SPEEDUP

#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}BYPASS_TXBUF_1${ps}tile0_txsync0_i${ps}USER_CLK
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}BYPASS_TXBUF_1${ps}tile0_txsync0_i${ps}RESET
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}BYPASS_TXBUF_1${ps}tile0_txsync0_i${ps}TXENPMAPHASEALIGN
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}BYPASS_TXBUF_1${ps}tile0_txsync0_i${ps}TXPMASETPHASE
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}BYPASS_TXBUF_1${ps}tile0_txsync0_i${ps}SYNC_DONE
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}BYPASS_TXBUF_1${ps}tile0_txsync0_i${ps}phase_align_r
#eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}BYPASS_TXBUF_1${ps}tile0_txsync0_i${ps}count_setphase_complete_r
#eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}BYPASS_TXBUF_1${ps}tile0_txsync0_i${ps}sync_counter_r


eval add wave -noupdate -divider {"host oob"}
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}sys_clk
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}sys_rst
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}StartComm_sync
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}StartComm
eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}state
eval add wave -noupdate $ascopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}state_ascii
eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}count

eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}rxstatus
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}${lltype}${ps}sata_gtx_phy${ps}gtx_oob_0${ps}phy_ready

eval add wave -noupdate -divider {"device oob 0"}
eval add wave -noupdate $hexopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}state
eval add wave -noupdate $ascopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}state_ascii

eval add wave -noupdate $binopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}rxstatus
eval add wave -noupdate $hexopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}count
eval add wave -noupdate $binopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}txcomstart
eval add wave -noupdate $binopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}txcomtype
eval add wave -noupdate $binopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}rxelecidle
eval add wave -noupdate $binopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}d10_2_det
eval add wave -noupdate $binopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}align_det

eval add wave -noupdate $hexopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}txdata_out
eval add wave -noupdate $binopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}tx_charisk

eval add wave -noupdate $hexopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}rxdata_in
eval add wave -noupdate $binopt ${tbpath}${ps}dev0${ps}shdd_model_phy${ps}oob_device${ps}rx_charisk

#eval add wave -noupdate -divider {"device oob 1"}
#eval add wave -noupdate $hexopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}state
#eval add wave -noupdate $ascopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}state_ascii
#
#eval add wave -noupdate $binopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}rxstatus
#eval add wave -noupdate $hexopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}count
#eval add wave -noupdate $binopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}txcomstart
#eval add wave -noupdate $binopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}txcomtype
#eval add wave -noupdate $binopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}rxelecidle
#eval add wave -noupdate $binopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}d10_2_det
#eval add wave -noupdate $binopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}align_det
#
#eval add wave -noupdate $hexopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}txdata_out
#eval add wave -noupdate $binopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}tx_charisk
#
#eval add wave -noupdate $hexopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}rxdata_in
#eval add wave -noupdate $binopt ${tbpath}${ps}dev1${ps}shdd_model_phy${ps}oob_device${ps}rx_charisk

eval add wave -noupdate -divider {"link fsm"}
if { ![info exists lfsm] } { set lfsm "${tbpath}${ps}dma0${ps}sata_link${ps}link_fsm" }
eval add wave -noupdate $hexopt $lfsm${ps}state
eval add wave -noupdate $ascopt $lfsm${ps}state_ascii

eval add wave -noupdate $ascopt $lfsm${ps}cs2link_char_ascii
eval add wave -noupdate $ascopt $lfsm${ps}link2cs_char_ascii

eval add wave -noupdate $binopt $lfsm${ps}trn_tfifo_rst
eval add wave -noupdate $hexopt $lfsm${ps}trn_cd
eval add wave -noupdate $binopt $lfsm${ps}trn_csrc_rdy_n
eval add wave -noupdate $binopt $lfsm${ps}trn_cdst_rdy_n
eval add wave -noupdate $binopt $lfsm${ps}trn_csof_n
eval add wave -noupdate $binopt $lfsm${ps}trn_ceof_n

eval add wave -noupdate $binopt $lfsm${ps}trn_cdst_dsc_n

eval add wave -noupdate -divider {"rx_cs"}
if { ![info exists rxcs ] } { set rxcs "${tbpath}${ps}dma0${ps}sata_link${ps}rx_cs" }
eval add wave -noupdate $binopt $rxcs${ps}err_req
eval add wave -noupdate $binopt $rxcs${ps}err_ack_dfis
eval add wave -noupdate $binopt $rxcs${ps}err_ack_ndfis
eval add wave -noupdate $binopt $rxcs${ps}fake_crc_err_dfis
eval add wave -noupdate $binopt $rxcs${ps}fake_crc_err_ndfis
eval add wave -noupdate $binopt $rxcs${ps}cs2link_crc_rdy
eval add wave -noupdate $binopt $rxcs${ps}trn_rsof_n
eval add wave -noupdate $hexopt $rxcs${ps}trn_rd

eval add wave -noupdate $binopt $rxcs${ps}crc_valid
eval add wave -noupdate $binopt $rxcs${ps}crc_rdy
eval add wave -noupdate $hexopt $rxcs${ps}crc_out

eval add wave -noupdate $binopt $rxcs${ps}wr_en
eval add wave -noupdate $hexopt $rxcs${ps}wr_di

eval add wave -noupdate $binopt $rxcs${ps}cs_sof
eval add wave -noupdate $binopt $rxcs${ps}cs_eof

eval add wave -noupdate $hexopt $rxcs${ps}C_HW_CRC
