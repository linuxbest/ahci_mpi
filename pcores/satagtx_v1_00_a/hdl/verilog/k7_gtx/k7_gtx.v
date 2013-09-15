//************************** Register Declarations ****************************

    wire            gt0_txfsmresetdone_i;
    wire            gt0_rxfsmresetdone_i;
    reg             gt0_txfsmresetdone_r;
    reg             gt0_txfsmresetdone_r2;
    reg             gt0_rxresetdone_r;
    reg             gt0_rxresetdone_r2;
    reg             gt0_rxresetdone_r3;

    wire            gt1_txfsmresetdone_i;
    wire            gt1_rxfsmresetdone_i;
    reg             gt1_txfsmresetdone_r;
    reg             gt1_txfsmresetdone_r2;
    reg             gt1_rxresetdone_r;
    reg             gt1_rxresetdone_r2;
    reg             gt1_rxresetdone_r3;

    reg [5:0] reset_counter = 0;
    reg     [3:0]   reset_pulse;

//**************************** Wire Declarations ******************************//
    //------------------------ GT Wrapper Wires ------------------------------
    //________________________________________________________________________
    //________________________________________________________________________
    //GT0   (X1Y0)
    //------------------------------- CPLL Ports -------------------------------
    wire            gt0_cpllfbclklost_i;
    wire            gt0_cplllock_i;
    wire            gt0_cpllrefclklost_i;
    wire            gt0_cpllreset_i;
    //-------------------------- Channel - DRP Ports  --------------------------
    wire    [8:0]   gt0_drpaddr_i;
    wire    [15:0]  gt0_drpdi_i;
    wire    [15:0]  gt0_drpdo_i;
    wire            gt0_drpen_i;
    wire            gt0_drprdy_i;
    wire            gt0_drpwe_i;
    //----------------------------- Loopback Ports -----------------------------
    wire    [2:0]   gt0_loopback_i;
    //--------------------------- PCI Express Ports ----------------------------
    wire            gt0_phystatus_i;
    //------------------- RX Initialization and Reset Ports --------------------
    wire            gt0_rxuserrdy_i;
    //------------------------ RX Margin Analysis Ports ------------------------
    wire            gt0_eyescandataerror_i;
    //----------------------- Receive Ports - CDR Ports ------------------------
    wire            gt0_rxcdrlock_i;
    //----------------- Receive Ports - Clock Correction Ports -----------------
    wire    [1:0]   gt0_rxclkcorcnt_i;
    //---------------- Receive Ports - FPGA RX interface Ports -----------------
    wire    [31:0]  gt0_rxdata_i;
    //---------------- Receive Ports - RX 8B/10B Decoder Ports -----------------
    wire    [3:0]   gt0_rxdisperr_i;
    wire    [3:0]   gt0_rxnotintable_i;
    //------------------------- Receive Ports - RX AFE -------------------------
    wire            gt0_gtxrxp_i;
    //---------------------- Receive Ports - RX AFE Ports ----------------------
    wire            gt0_gtxrxn_i;
    //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
    wire    [2:0]   gt0_rxstatus_i;
    //------------ Receive Ports - RX Byte and Word Alignment Ports ------------
    wire            gt0_rxbyteisaligned_i;
    //------------- Receive Ports - RX Fabric Output Control Ports -------------
    wire            gt0_rxoutclk_i;
    //----------- Receive Ports - RX Initialization and Reset Ports ------------
    wire            gt0_gtrxreset_i;
    wire            gt0_rxpmareset_i;
    //----------------- Receive Ports - RX OOB Signaling ports -----------------
    wire            gt0_rxcomsasdet_i;
    wire            gt0_rxcomwakedet_i;
    //---------------- Receive Ports - RX OOB Signaling ports  -----------------
    wire            gt0_rxcominitdet_i;
    //---------------- Receive Ports - RX OOB signalling Ports -----------------
    wire            gt0_rxelecidle_i;
    //----------------- Receive Ports - RX8B/10B Decoder Ports -----------------
    wire    [3:0]   gt0_rxcharisk_i;
    //------------ Receive Ports -RX Initialization and Reset Ports ------------
    wire            gt0_rxresetdone_i;
    //------------------- TX Initialization and Reset Ports --------------------
    wire            gt0_gttxreset_i;
    wire            gt0_txuserrdy_i;
    //------------------- Transmit Ports - PCI Express Ports -------------------
    wire            gt0_txelecidle_i;
    //---------------- Transmit Ports - TX Data Path interface -----------------
    wire    [31:0]  gt0_txdata_i;
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    wire            gt0_gtxtxn_i;
    wire            gt0_gtxtxp_i;
    //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    wire            gt0_txoutclk_i;
    wire            gt0_txoutclkfabric_i;
    wire            gt0_txoutclkpcs_i;
    //------------------- Transmit Ports - TX Gearbox Ports --------------------
    wire    [3:0]   gt0_txcharisk_i;
    //----------- Transmit Ports - TX Initialization and Reset Ports -----------
    wire            gt0_txresetdone_i;
    //---------------- Transmit Ports - TX OOB signalling Ports ----------------
    wire            gt0_txcomfinish_i;
    wire            gt0_txcominit_i;
    wire            gt0_txcomsas_i;
    wire            gt0_txcomwake_i;
    //------------- Transmit Ports - TX Receiver Detection Ports  --------------
    wire            gt0_txdetectrx_i;

    //________________________________________________________________________
    //________________________________________________________________________
    //GT1   (X1Y1)
    //------------------------------- CPLL Ports -------------------------------
    wire            gt1_cpllfbclklost_i;
    wire            gt1_cplllock_i;
    wire            gt1_cpllrefclklost_i;
    wire            gt1_cpllreset_i;
    //-------------------------- Channel - DRP Ports  --------------------------
    wire    [8:0]   gt1_drpaddr_i;
    wire    [15:0]  gt1_drpdi_i;
    wire    [15:0]  gt1_drpdo_i;
    wire            gt1_drpen_i;
    wire            gt1_drprdy_i;
    wire            gt1_drpwe_i;
    //----------------------------- Loopback Ports -----------------------------
    wire    [2:0]   gt1_loopback_i;
    //--------------------------- PCI Express Ports ----------------------------
    wire            gt1_phystatus_i;
    //------------------- RX Initialization and Reset Ports --------------------
    wire            gt1_rxuserrdy_i;
    //------------------------ RX Margin Analysis Ports ------------------------
    wire            gt1_eyescandataerror_i;
    //----------------------- Receive Ports - CDR Ports ------------------------
    wire            gt1_rxcdrlock_i;
    //----------------- Receive Ports - Clock Correction Ports -----------------
    wire    [1:0]   gt1_rxclkcorcnt_i;
    //---------------- Receive Ports - FPGA RX interface Ports -----------------
    wire    [31:0]  gt1_rxdata_i;
    //---------------- Receive Ports - RX 8B/10B Decoder Ports -----------------
    wire    [3:0]   gt1_rxdisperr_i;
    wire    [3:0]   gt1_rxnotintable_i;
    //------------------------- Receive Ports - RX AFE -------------------------
    wire            gt1_gtxrxp_i;
    //---------------------- Receive Ports - RX AFE Ports ----------------------
    wire            gt1_gtxrxn_i;
    //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
    wire    [2:0]   gt1_rxstatus_i;
    //------------ Receive Ports - RX Byte and Word Alignment Ports ------------
    wire            gt1_rxbyteisaligned_i;
    //------------- Receive Ports - RX Fabric Output Control Ports -------------
    wire            gt1_rxoutclk_i;
    //----------- Receive Ports - RX Initialization and Reset Ports ------------
    wire            gt1_gtrxreset_i;
    wire            gt1_rxpmareset_i;
    //----------------- Receive Ports - RX OOB Signaling ports -----------------
    wire            gt1_rxcomsasdet_i;
    wire            gt1_rxcomwakedet_i;
    //---------------- Receive Ports - RX OOB Signaling ports  -----------------
    wire            gt1_rxcominitdet_i;
    //---------------- Receive Ports - RX OOB signalling Ports -----------------
    wire            gt1_rxelecidle_i;
    //----------------- Receive Ports - RX8B/10B Decoder Ports -----------------
    wire    [3:0]   gt1_rxcharisk_i;
    //------------ Receive Ports -RX Initialization and Reset Ports ------------
    wire            gt1_rxresetdone_i;
    //------------------- TX Initialization and Reset Ports --------------------
    wire            gt1_gttxreset_i;
    wire            gt1_txuserrdy_i;
    //------------------- Transmit Ports - PCI Express Ports -------------------
    wire            gt1_txelecidle_i;
    //---------------- Transmit Ports - TX Data Path interface -----------------
    wire    [31:0]  gt1_txdata_i;
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    wire            gt1_gtxtxn_i;
    wire            gt1_gtxtxp_i;
    //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    wire            gt1_txoutclk_i;
    wire            gt1_txoutclkfabric_i;
    wire            gt1_txoutclkpcs_i;
    //------------------- Transmit Ports - TX Gearbox Ports --------------------
    wire    [3:0]   gt1_txcharisk_i;
    //----------- Transmit Ports - TX Initialization and Reset Ports -----------
    wire            gt1_txresetdone_i;
    //---------------- Transmit Ports - TX OOB signalling Ports ----------------
    wire            gt1_txcomfinish_i;
    wire            gt1_txcominit_i;
    wire            gt1_txcomsas_i;
    wire            gt1_txcomwake_i;
    //------------- Transmit Ports - TX Receiver Detection Ports  --------------
    wire            gt1_txdetectrx_i;

    //____________________________COMMON PORTS________________________________
    //----------------------- Common Block - QPLL Ports ------------------------
    wire            gt0_qplllock_i;
    wire            gt0_qpllrefclklost_i;
    wire            gt0_qpllreset_i;


    //----------------------------- Global Signals -----------------------------

    wire            drpclk_in_i;
    wire            gt0_tx_system_reset_c;
    wire            gt0_rx_system_reset_c;
    wire            gt1_tx_system_reset_c;
    wire            gt1_rx_system_reset_c;
    wire            tied_to_ground_i;
    wire    [63:0]  tied_to_ground_vec_i;
    wire            tied_to_vcc_i;
    wire    [7:0]   tied_to_vcc_vec_i;
    wire            GTTXRESET_IN;
    wire            GTRXRESET_IN;
    wire            CPLLRESET_IN;
    wire            QPLLRESET_IN;

     //--------------------------- User Clocks ---------------------------------
    (* keep = "TRUE" *) wire            gt0_txusrclk_i; 
    (* keep = "TRUE" *) wire            gt0_txusrclk2_i; 
    (* keep = "TRUE" *) wire            gt0_rxusrclk_i; 
    (* keep = "TRUE" *) wire            gt0_rxusrclk2_i; 
    (* keep = "TRUE" *) wire            gt1_txusrclk_i; 
    (* keep = "TRUE" *) wire            gt1_txusrclk2_i; 
    (* keep = "TRUE" *) wire            gt1_rxusrclk_i; 
    (* keep = "TRUE" *) wire            gt1_rxusrclk2_i; 
 
    //--------------------------- Reference Clocks ----------------------------
    
    wire            q0_clk1_refclk_i;


    //--------------------- Frame check/gen Module Signals --------------------
    wire            gt0_matchn_i;
    
    wire    [3:0]   gt0_txcharisk_float_i;
   
    wire    [15:0]  gt0_txdata_float16_i;
    wire    [31:0]  gt0_txdata_float_i;
    
    
    wire            gt0_block_sync_i;
    wire            gt0_track_data_i;
    wire    [7:0]   gt0_error_count_i;
    wire            gt0_frame_check_reset_i;
    wire            gt0_inc_in_i;
    wire            gt0_inc_out_i;
    wire    [31:0]  gt0_unscrambled_data_i;

    wire            gt1_matchn_i;
    
    wire    [3:0]   gt1_txcharisk_float_i;
   
    wire    [15:0]  gt1_txdata_float16_i;
    wire    [31:0]  gt1_txdata_float_i;
    
    
    wire            gt1_block_sync_i;
    wire            gt1_track_data_i;
    wire    [7:0]   gt1_error_count_i;
    wire            gt1_frame_check_reset_i;
    wire            gt1_inc_in_i;
    wire            gt1_inc_out_i;
    wire    [31:0]  gt1_unscrambled_data_i;

    wire            reset_on_data_error_i;
    wire            track_data_out_i;
  

    //--------------------- Chipscope Signals ---------------------------------

    wire    [35:0]  tx_data_vio_control_i;
    wire    [35:0]  rx_data_vio_control_i;
    wire    [35:0]  shared_vio_control_i;
    wire    [35:0]  ila_control_i;
    wire    [35:0]  channel_drp_vio_control_i;
    wire    [35:0]  common_drp_vio_control_i;
    wire    [31:0]  tx_data_vio_async_in_i;
    wire    [31:0]  tx_data_vio_sync_in_i;
    wire    [31:0]  tx_data_vio_async_out_i;
    wire    [31:0]  tx_data_vio_sync_out_i;
    wire    [31:0]  rx_data_vio_async_in_i;
    wire    [31:0]  rx_data_vio_sync_in_i;
    wire    [31:0]  rx_data_vio_async_out_i;
    wire    [31:0]  rx_data_vio_sync_out_i;
    wire    [31:0]  shared_vio_in_i;
    wire    [31:0]  shared_vio_out_i;
    wire    [163:0] ila_in_i;
    wire    [31:0]  channel_drp_vio_async_in_i;
    wire    [31:0]  channel_drp_vio_sync_in_i;
    wire    [31:0]  channel_drp_vio_async_out_i;
    wire    [31:0]  channel_drp_vio_sync_out_i;
    wire    [31:0]  common_drp_vio_async_in_i;
    wire    [31:0]  common_drp_vio_sync_in_i;
    wire    [31:0]  common_drp_vio_async_out_i;
    wire    [31:0]  common_drp_vio_sync_out_i;

    wire    [31:0]  gt0_tx_data_vio_async_in_i;
    wire    [31:0]  gt0_tx_data_vio_sync_in_i;
    wire    [31:0]  gt0_tx_data_vio_async_out_i;
    wire    [31:0]  gt0_tx_data_vio_sync_out_i;
    wire    [31:0]  gt0_rx_data_vio_async_in_i;
    wire    [31:0]  gt0_rx_data_vio_sync_in_i;
    wire    [31:0]  gt0_rx_data_vio_async_out_i;
    wire    [31:0]  gt0_rx_data_vio_sync_out_i;
    wire    [163:0] gt0_ila_in_i;
    wire    [31:0]  gt0_channel_drp_vio_async_in_i;
    wire    [31:0]  gt0_channel_drp_vio_sync_in_i;
    wire    [31:0]  gt0_channel_drp_vio_async_out_i;
    wire    [31:0]  gt0_channel_drp_vio_sync_out_i;
    wire    [31:0]  gt0_common_drp_vio_async_in_i;
    wire    [31:0]  gt0_common_drp_vio_sync_in_i;
    wire    [31:0]  gt0_common_drp_vio_async_out_i;
    wire    [31:0]  gt0_common_drp_vio_sync_out_i;

    wire    [31:0]  gt1_tx_data_vio_async_in_i;
    wire    [31:0]  gt1_tx_data_vio_sync_in_i;
    wire    [31:0]  gt1_tx_data_vio_async_out_i;
    wire    [31:0]  gt1_tx_data_vio_sync_out_i;
    wire    [31:0]  gt1_rx_data_vio_async_in_i;
    wire    [31:0]  gt1_rx_data_vio_sync_in_i;
    wire    [31:0]  gt1_rx_data_vio_async_out_i;
    wire    [31:0]  gt1_rx_data_vio_sync_out_i;
    wire    [163:0] gt1_ila_in_i;
    wire    [31:0]  gt1_channel_drp_vio_async_in_i;
    wire    [31:0]  gt1_channel_drp_vio_sync_in_i;
    wire    [31:0]  gt1_channel_drp_vio_async_out_i;
    wire    [31:0]  gt1_channel_drp_vio_sync_out_i;
    wire    [31:0]  gt1_common_drp_vio_async_in_i;
    wire    [31:0]  gt1_common_drp_vio_sync_in_i;
    wire    [31:0]  gt1_common_drp_vio_async_out_i;
    wire    [31:0]  gt1_common_drp_vio_sync_out_i;


    wire            gttxreset_i;
    wire            gtrxreset_i;
    wire            mux_sel_i;

    wire            user_tx_reset_i;
    wire            user_rx_reset_i;
    wire            tx_vio_clk_i;
    wire            tx_vio_clk_mux_out_i;    
    wire            rx_vio_ila_clk_i;
    wire            rx_vio_ila_clk_mux_out_i;

    wire            cpllreset_i;
    


//**************************** Main Body of Code *******************************

    //  Static signal Assigments    
    assign tied_to_ground_i             = 1'b0;
    assign tied_to_ground_vec_i         = 64'h0000000000000000;
    assign tied_to_vcc_i                = 1'b1;
    assign tied_to_vcc_vec_i            = 8'hff;

    //***********************************************************************//
    //                                                                       //
    //--------------------------- The GT Wrapper ----------------------------//
    //                                                                       //
    //***********************************************************************//
    
    // Use the instantiation template in the example directory to add the GT wrapper to your design.
    // In this example, the wrapper is wired up for basic operation with a frame generator and frame 
    // checker. The GTs will reset, then attempt to align and transmit data. If channel bonding is 
    // enabled, bonding should occur after alignment.
    
    gtwizard_v2_6_init #
    (
        .EXAMPLE_SIM_GTRESET_SPEEDUP    (EXAMPLE_SIM_GTRESET_SPEEDUP),
        .EXAMPLE_SIMULATION             (EXAMPLE_SIMULATION),
        .STABLE_CLOCK_PERIOD            (STABLE_CLOCK_PERIOD),
        .EXAMPLE_USE_CHIPSCOPE          (EXAMPLE_USE_CHIPSCOPE)
    )
    gtwizard_v2_6_init_i
    (
        .SYSCLK_IN                      (drpclk_in_i),
        .SOFT_RESET_IN                  (tied_to_ground_i),
	.DONT_RESET_ON_DATA_ERROR_IN    (tied_to_ground_i),
        .GT0_TX_FSM_RESET_DONE_OUT      (gt0_txfsmresetdone_i),
        .GT0_RX_FSM_RESET_DONE_OUT      (gt0_rxfsmresetdone_i),
        .GT0_DATA_VALID_IN              (gt0_track_data_i),
        .GT1_TX_FSM_RESET_DONE_OUT      (gt1_txfsmresetdone_i),
        .GT1_RX_FSM_RESET_DONE_OUT      (gt1_rxfsmresetdone_i),
        .GT1_DATA_VALID_IN              (gt1_track_data_i),
 
 

        //_____________________________________________________________________
        //_____________________________________________________________________
        //GT0  (X1Y0)

        //------------------------------- CPLL Ports -------------------------------
        .GT0_CPLLFBCLKLOST_OUT          (gt0_cpllfbclklost_i),
        .GT0_CPLLLOCK_OUT               (gt0_cplllock_i),
        .GT0_CPLLLOCKDETCLK_IN          (drpclk_in_i),
        .GT0_CPLLRESET_IN               (gt0_cpllreset_i),
        //------------------------ Channel - Clocking Ports ------------------------
        .GT0_GTREFCLK0_IN               (q0_clk1_refclk_i),
        //-------------------------- Channel - DRP Ports  --------------------------
        .GT0_DRPADDR_IN                 (gt0_drpaddr_i),
        .GT0_DRPCLK_IN                  (drpclk_in_i),
        .GT0_DRPDI_IN                   (gt0_drpdi_i),
        .GT0_DRPDO_OUT                  (gt0_drpdo_i),
        .GT0_DRPEN_IN                   (gt0_drpen_i),
        .GT0_DRPRDY_OUT                 (gt0_drprdy_i),
        .GT0_DRPWE_IN                   (gt0_drpwe_i),
        //----------------------------- Loopback Ports -----------------------------
        .GT0_LOOPBACK_IN                (gt0_loopback_i),
        //--------------------------- PCI Express Ports ----------------------------
        .GT0_PHYSTATUS_OUT              (gt0_phystatus_i),
        //------------------- RX Initialization and Reset Ports --------------------
        .GT0_RXUSERRDY_IN               (gt0_rxuserrdy_i),
        //------------------------ RX Margin Analysis Ports ------------------------
        .GT0_EYESCANDATAERROR_OUT       (gt0_eyescandataerror_i),
        //----------------------- Receive Ports - CDR Ports ------------------------
        .GT0_RXCDRLOCK_OUT              (gt0_rxcdrlock_i),
        //----------------- Receive Ports - Clock Correction Ports -----------------
        .GT0_RXCLKCORCNT_OUT            (gt0_rxclkcorcnt_i),
        //---------------- Receive Ports - FPGA RX Interface Ports -----------------
        .GT0_RXUSRCLK_IN                (gt0_txusrclk_i),
        .GT0_RXUSRCLK2_IN               (gt0_txusrclk_i),
        //---------------- Receive Ports - FPGA RX interface Ports -----------------
        .GT0_RXDATA_OUT                 (gt0_rxdata_i),
        //---------------- Receive Ports - RX 8B/10B Decoder Ports -----------------
        .GT0_RXDISPERR_OUT              (gt0_rxdisperr_i),
        .GT0_RXNOTINTABLE_OUT           (gt0_rxnotintable_i),
        //------------------------- Receive Ports - RX AFE -------------------------
        .GT0_GTXRXP_IN                  (RXP_IN[0]),
        //---------------------- Receive Ports - RX AFE Ports ----------------------
        .GT0_GTXRXN_IN                  (RXN_IN[0]),
        //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
        .GT0_RXSTATUS_OUT               (gt0_rxstatus_i),
        //------------ Receive Ports - RX Byte and Word Alignment Ports ------------
        .GT0_RXBYTEISALIGNED_OUT        (gt0_rxbyteisaligned_i),
        //----------- Receive Ports - RX Initialization and Reset Ports ------------
        .GT0_GTRXRESET_IN               (gt0_gtrxreset_i),
        .GT0_RXPMARESET_IN              (gt0_rxpmareset_i),
        //----------------- Receive Ports - RX OOB Signaling ports -----------------
        .GT0_RXCOMSASDET_OUT            (gt0_rxcomsasdet_i),
        .GT0_RXCOMWAKEDET_OUT           (gt0_rxcomwakedet_i),
        //---------------- Receive Ports - RX OOB Signaling ports  -----------------
        .GT0_RXCOMINITDET_OUT           (gt0_rxcominitdet_i),
        //---------------- Receive Ports - RX OOB signalling Ports -----------------
        .GT0_RXELECIDLE_OUT             (gt0_rxelecidle_i),
        //----------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        .GT0_RXCHARISK_OUT              (gt0_rxcharisk_i),
        //------------ Receive Ports -RX Initialization and Reset Ports ------------
        .GT0_RXRESETDONE_OUT            (gt0_rxresetdone_i),
        //------------------- TX Initialization and Reset Ports --------------------
        .GT0_GTTXRESET_IN               (gt0_gttxreset_i),
        .GT0_TXUSERRDY_IN               (gt0_txuserrdy_i),
        //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
        .GT0_TXUSRCLK_IN                (gt0_txusrclk_i),
        .GT0_TXUSRCLK2_IN               (gt0_txusrclk_i),
        //------------------- Transmit Ports - PCI Express Ports -------------------
        .GT0_TXELECIDLE_IN              (gt0_txelecidle_i),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .GT0_TXDATA_IN                  (gt0_txdata_i),
        //-------------- Transmit Ports - TX Driver and OOB signaling --------------
        .GT0_GTXTXN_OUT                 (TXN_OUT[0]),
        .GT0_GTXTXP_OUT                 (TXP_OUT[0]),
        //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        .GT0_TXOUTCLK_OUT               (gt0_txoutclk_i),
        .GT0_TXOUTCLKFABRIC_OUT         (gt0_txoutclkfabric_i),
        .GT0_TXOUTCLKPCS_OUT            (gt0_txoutclkpcs_i),
        //------------------- Transmit Ports - TX Gearbox Ports --------------------
        .GT0_TXCHARISK_IN               (gt0_txcharisk_i),
        //----------- Transmit Ports - TX Initialization and Reset Ports -----------
        .GT0_TXRESETDONE_OUT            (gt0_txresetdone_i),
        //---------------- Transmit Ports - TX OOB signalling Ports ----------------
        .GT0_TXCOMFINISH_OUT            (gt0_txcomfinish_i),
        .GT0_TXCOMINIT_IN               (gt0_txcominit_i),
        .GT0_TXCOMSAS_IN                (gt0_txcomsas_i),
        .GT0_TXCOMWAKE_IN               (gt0_txcomwake_i),
        //------------- Transmit Ports - TX Receiver Detection Ports  --------------
        .GT0_TXDETECTRX_IN              (gt0_txdetectrx_i),


 
 

        //_____________________________________________________________________
        //_____________________________________________________________________
        //GT1  (X1Y1)

        //------------------------------- CPLL Ports -------------------------------
        .GT1_CPLLFBCLKLOST_OUT          (gt1_cpllfbclklost_i),
        .GT1_CPLLLOCK_OUT               (gt1_cplllock_i),
        .GT1_CPLLLOCKDETCLK_IN          (drpclk_in_i),
        .GT1_CPLLRESET_IN               (gt1_cpllreset_i),
        //------------------------ Channel - Clocking Ports ------------------------
        .GT1_GTREFCLK0_IN               (q0_clk1_refclk_i),
        //-------------------------- Channel - DRP Ports  --------------------------
        .GT1_DRPADDR_IN                 (gt1_drpaddr_i),
        .GT1_DRPCLK_IN                  (drpclk_in_i),
        .GT1_DRPDI_IN                   (gt1_drpdi_i),
        .GT1_DRPDO_OUT                  (gt1_drpdo_i),
        .GT1_DRPEN_IN                   (gt1_drpen_i),
        .GT1_DRPRDY_OUT                 (gt1_drprdy_i),
        .GT1_DRPWE_IN                   (gt1_drpwe_i),
        //----------------------------- Loopback Ports -----------------------------
        .GT1_LOOPBACK_IN                (gt1_loopback_i),
        //--------------------------- PCI Express Ports ----------------------------
        .GT1_PHYSTATUS_OUT              (gt1_phystatus_i),
        //------------------- RX Initialization and Reset Ports --------------------
        .GT1_RXUSERRDY_IN               (gt1_rxuserrdy_i),
        //------------------------ RX Margin Analysis Ports ------------------------
        .GT1_EYESCANDATAERROR_OUT       (gt1_eyescandataerror_i),
        //----------------------- Receive Ports - CDR Ports ------------------------
        .GT1_RXCDRLOCK_OUT              (gt1_rxcdrlock_i),
        //----------------- Receive Ports - Clock Correction Ports -----------------
        .GT1_RXCLKCORCNT_OUT            (gt1_rxclkcorcnt_i),
        //---------------- Receive Ports - FPGA RX Interface Ports -----------------
        .GT1_RXUSRCLK_IN                (gt0_txusrclk_i),
        .GT1_RXUSRCLK2_IN               (gt0_txusrclk_i),
        //---------------- Receive Ports - FPGA RX interface Ports -----------------
        .GT1_RXDATA_OUT                 (gt1_rxdata_i),
        //---------------- Receive Ports - RX 8B/10B Decoder Ports -----------------
        .GT1_RXDISPERR_OUT              (gt1_rxdisperr_i),
        .GT1_RXNOTINTABLE_OUT           (gt1_rxnotintable_i),
        //------------------------- Receive Ports - RX AFE -------------------------
        .GT1_GTXRXP_IN                  (RXP_IN[1]),
        //---------------------- Receive Ports - RX AFE Ports ----------------------
        .GT1_GTXRXN_IN                  (RXN_IN[1]),
        //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
        .GT1_RXSTATUS_OUT               (gt1_rxstatus_i),
        //------------ Receive Ports - RX Byte and Word Alignment Ports ------------
        .GT1_RXBYTEISALIGNED_OUT        (gt1_rxbyteisaligned_i),
        //----------- Receive Ports - RX Initialization and Reset Ports ------------
        .GT1_GTRXRESET_IN               (gt1_gtrxreset_i),
        .GT1_RXPMARESET_IN              (gt1_rxpmareset_i),
        //----------------- Receive Ports - RX OOB Signaling ports -----------------
        .GT1_RXCOMSASDET_OUT            (gt1_rxcomsasdet_i),
        .GT1_RXCOMWAKEDET_OUT           (gt1_rxcomwakedet_i),
        //---------------- Receive Ports - RX OOB Signaling ports  -----------------
        .GT1_RXCOMINITDET_OUT           (gt1_rxcominitdet_i),
        //---------------- Receive Ports - RX OOB signalling Ports -----------------
        .GT1_RXELECIDLE_OUT             (gt1_rxelecidle_i),
        //----------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        .GT1_RXCHARISK_OUT              (gt1_rxcharisk_i),
        //------------ Receive Ports -RX Initialization and Reset Ports ------------
        .GT1_RXRESETDONE_OUT            (gt1_rxresetdone_i),
        //------------------- TX Initialization and Reset Ports --------------------
        .GT1_GTTXRESET_IN               (gt1_gttxreset_i),
        .GT1_TXUSERRDY_IN               (gt1_txuserrdy_i),
        //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
        .GT1_TXUSRCLK_IN                (gt0_txusrclk_i),
        .GT1_TXUSRCLK2_IN               (gt0_txusrclk_i),
        //------------------- Transmit Ports - PCI Express Ports -------------------
        .GT1_TXELECIDLE_IN              (gt1_txelecidle_i),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .GT1_TXDATA_IN                  (gt1_txdata_i),
        //-------------- Transmit Ports - TX Driver and OOB signaling --------------
        .GT1_GTXTXN_OUT                 (TXN_OUT[1]),
        .GT1_GTXTXP_OUT                 (TXP_OUT[1]),
        //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        .GT1_TXOUTCLK_OUT               (gt1_txoutclk_i),
        .GT1_TXOUTCLKFABRIC_OUT         (gt1_txoutclkfabric_i),
        .GT1_TXOUTCLKPCS_OUT            (gt1_txoutclkpcs_i),
        //------------------- Transmit Ports - TX Gearbox Ports --------------------
        .GT1_TXCHARISK_IN               (gt1_txcharisk_i),
        //----------- Transmit Ports - TX Initialization and Reset Ports -----------
        .GT1_TXRESETDONE_OUT            (gt1_txresetdone_i),
        //---------------- Transmit Ports - TX OOB signalling Ports ----------------
        .GT1_TXCOMFINISH_OUT            (gt1_txcomfinish_i),
        .GT1_TXCOMINIT_IN               (gt1_txcominit_i),
        .GT1_TXCOMSAS_IN                (gt1_txcomsas_i),
        .GT1_TXCOMWAKE_IN               (gt1_txcomwake_i),
        //------------- Transmit Ports - TX Receiver Detection Ports  --------------
        .GT1_TXDETECTRX_IN              (gt1_txdetectrx_i),




    //____________________________COMMON PORTS________________________________
        //-------------------- Common Block  - Ref Clock Ports ---------------------
        .GT0_GTREFCLK0_COMMON_IN        (q0_clk1_refclk_i),
        //----------------------- Common Block - QPLL Ports ------------------------
        .GT0_QPLLLOCK_OUT               (gt0_qplllock_i),
        .GT0_QPLLLOCKDETCLK_IN          (drpclk_in_i),
        .GT0_QPLLRESET_IN               (gt0_qpllreset_i)

    );

 
    //***********************************************************************//
    //                                                                       //
    //--------------------------- User Module Resets-------------------------//
    //                                                                       //
    //***********************************************************************//
    // All the User Modules i.e. FRAME_GEN, FRAME_CHECK and the sync modules
    // are held in reset till the RESETDONE goes high. 
    // The RESETDONE is registered a couple of times on *USRCLK2 and connected 
    // to the reset of the modules
    
    always @(posedge gt0_txusrclk_i or negedge gt0_rxresetdone_i)

    begin
        if (!gt0_rxresetdone_i)
        begin
            gt0_rxresetdone_r    <=   `DLY 1'b0;
            gt0_rxresetdone_r2   <=   `DLY 1'b0;
        end
        else
        begin
            gt0_rxresetdone_r    <=   `DLY gt0_rxresetdone_i;
            gt0_rxresetdone_r2   <=   `DLY gt0_rxresetdone_r;
            gt0_rxresetdone_r3   <=   `DLY gt0_rxresetdone_r2;
        end
    end

    
    
    always @(posedge gt0_txusrclk_i or negedge gt0_txfsmresetdone_i)

    begin
        if (!gt0_txfsmresetdone_i)
        begin
            gt0_txfsmresetdone_r    <=   `DLY 1'b0;
            gt0_txfsmresetdone_r2   <=   `DLY 1'b0;
        end
        else
        begin
            gt0_txfsmresetdone_r    <=   `DLY gt0_txfsmresetdone_i;
            gt0_txfsmresetdone_r2   <=   `DLY gt0_txfsmresetdone_r;
        end
    end

    always @(posedge gt0_txusrclk_i or negedge gt1_rxresetdone_i)

    begin
        if (!gt1_rxresetdone_i)
        begin
            gt1_rxresetdone_r    <=   `DLY 1'b0;
            gt1_rxresetdone_r2   <=   `DLY 1'b0;
        end
        else
        begin
            gt1_rxresetdone_r    <=   `DLY gt1_rxresetdone_i;
            gt1_rxresetdone_r2   <=   `DLY gt1_rxresetdone_r;
            gt1_rxresetdone_r3   <=   `DLY gt1_rxresetdone_r2;
        end
    end

    
    
    always @(posedge gt0_txusrclk_i or negedge gt1_txfsmresetdone_i)

    begin
        if (!gt1_txfsmresetdone_i)
        begin
            gt1_txfsmresetdone_r    <=   `DLY 1'b0;
            gt1_txfsmresetdone_r2   <=   `DLY 1'b0;
        end
        else
        begin
            gt1_txfsmresetdone_r    <=   `DLY gt1_txfsmresetdone_i;
            gt1_txfsmresetdone_r2   <=   `DLY gt1_txfsmresetdone_r;
        end
    end
