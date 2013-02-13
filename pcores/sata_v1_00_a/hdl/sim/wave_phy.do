if { [info exists PathSeparator] } { set ps $PathSeparator } else { set ps "/" }
if { ![info exists tbpath] } { set tbpath "/tb" }

set binopt {-logic}
set hexopt {-literal -hex}
set ascopt {-literal -ascii}

eval add wave -noupdate -divider {"satagtx_internal"}
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}phyreset0

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

eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_txusrclk20_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}phyreset0
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_txcomstart0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_txcomtype0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_rxelecidle0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_txelecidle0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}StartComm0
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}CommInit0
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_resetdone0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_txenpmaphasealign0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_txpmasetphase0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_tx_resetdone0_r2
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_tx_sync_done0_i

eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_txdata0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_txcharisk0_i

eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_rxdata0_i
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}tile0_rxcharisk0_i

eval add wave -noupdate -divider {"host oob"}
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}gtx_oob_0${ps}sys_clk
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}gtx_oob_0${ps}sys_rst
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}gtx_oob_0${ps}StartComm_sync
eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}gtx_oob_0${ps}StartComm
eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}gtx_oob_0${ps}state
eval add wave -noupdate $ascopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}gtx_oob_0${ps}state_ascii
eval add wave -noupdate $hexopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}gtx_oob_0${ps}count

eval add wave -noupdate $binopt $tbpath${ps}gtx_0${ps}sata_gtx_phy${ps}gtx_oob_0${ps}rxstatus

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
