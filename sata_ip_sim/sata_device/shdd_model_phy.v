`timescale 1ns / 1ps
module shdd_model_phy(/*AUTOARG*/
   // Outputs
   TXN_OUT0, TXP_OUT0, rx_data_phy, rx_charisk, phy_clk, dev_clk_75M,
   dev_clk_150M, dev_link_up,
   // Inputs
   rst_n, RXN_IN0, RXP_IN0, sata_clk_n, sata_clk_p, tx_data_phy,
   tx_charisk
   );
   parameter EXAMPLE_SIM_GTPRESET_SPEEDUP = 1;       // simulation setting for MGT smartmodel
   parameter EXAMPLE_SIM_PLL_PERDIV2      = 9'h14d;  // simulation setting for MGT smartmodel
   parameter DDR_SIM                      = 1;
   parameter EXAMPLE_SIM_MODE             = "FAST";  // Set to Fast Functional Simulation Model  
   parameter SIM_GTPRESET_SPEEDUP         = 1;       // Set to 1 to speed up sim reset
   parameter SIM_PLL_PERDIV2              = 9'h14d;  // Set to the VCO Unit Interval time

   input  rst_n;

   output TXN_OUT0;
   output TXP_OUT0;
   input  RXN_IN0;
   input  RXP_IN0;
   input  sata_clk_n;
   input  sata_clk_p;

   input [15:0]  tx_data_phy;
   input 	 tx_charisk;
   output [15:0] rx_data_phy;
   output [1:0]  rx_charisk;
   output 	 phy_clk;
   output 	 dev_clk_75M;
   output        dev_clk_150M;
   output        dev_link_up;
   
   wire  [127:0]   write_mem_data;
   wire  [31:0]    mem_addr;
   wire  [2:0]     mem_cmd;
   wire            data_wren,addr_wren;
   wire  [127:0]   read_mem_data;
   wire            write_data_full,addr_almost_full,read_mem_valid,rst0_tb,clk0_tb;

   wire            tile0_refclkout_i,pcie0_plllkdet_i,tile0_txusrclk0_i,tile0_txusrclk20_i,refclkout_dcm0_locked_i,
	           tile0_refclkout_to_dcm_i,refclkout_dcm0_reset_i,TILE0_PLLLKDET_OUT,tile0_plllkdet_i,tile0_gtpreset_i,resetdone0;
   wire            tile0_refclk_i,rxelecidle0,tx_comreset0,tx_comwake0,txelecidle0,tile0_rxelecidle0_out,tile0_resetdone0_i;
   wire [1:0]      tile0_rxchariscomma0_out,tile0_rxlossofsync0_i,tile0_rxcharisk0_out,tile0_rxdisperr0_out,tile0_rxnotintable0_out;
   wire            tile0_txcharisk0_in;
   wire [2:0]      tile0_rxstatus0_i,tile0_loopback0_in;
   wire [15:0]     tile0_rx_data_phy0_out,tile0_tx_data_phy0_in;
   wire            clk0;
   wire            clk0_n;
   wire            clk1;
   wire            clk1_n;
   wire            dclk;
   wire            txenpmaphasealign_i,txpmasetphase_i;
   reg             tile0_resetdone0_r2,tile0_resetdone0_r,calibrated;

   wire            rxbyteisaligned;
   wire            txcomstart;
   wire            txcomtype;
   wire            linkup;
   wire [15:0]     tx_data_phy_oob;
   wire            tx_charisk_oob;
   wire            rxreset;
   wire            rxelecidlereset0;
   wire            rxenelecidleresetb;
  
   assign  dev_clk_150M = tile0_txusrclk20_i;
   assign  tile0_tx_data_phy0_in    = linkup? tx_data_phy : tx_data_phy_oob;
   assign  rx_data_phy              = tile0_rx_data_phy0_out; 
   assign  rx_charisk          = tile0_rxcharisk0_out;
   assign  tile0_txcharisk0_in = linkup ? tx_charisk : tx_charisk_oob; 
   assign  dev_link_up         = linkup; 
   assign  rxelecidlereset0    = (rxelecidle0 && tile0_resetdone0_i);
   assign  rxenelecidleresetb  = !rxelecidlereset0;
   assign  phy_clk             = tile0_txusrclk20_i;
   
   oob_device 
      oob_device(
		 .clk        (tile0_txusrclk20_i),
		 .rst_n      (rst_n),
		 .gtp_locked  (tile0_plllkdet_i),//refclkout_dcm0_locked_i

		 .rxstatus  (tile0_rxstatus0_i),
		 .rxelecidle (rxelecidle0),
		 .rxbyteisaligned (rxbyteisaligned),

		 .txcomstart (txcomstart),
		 .txcomtype  (txcomtype) ,
		 .txelecidle (txelecidle0),
		 .tx_charisk (tx_charisk_oob),
		 .rxreset    (rxreset),

		 .linkup     (linkup),
		 .txdata_out (tx_data_phy_oob),
		 .rx_charisk (rx_charisk),
		 .rxdata_in  (rx_data_phy)
		 );

   //SATA GTP
   IBUFDS tile0_refclk_ibufds_i
     (
      .O                              (tile0_refclk_i), 
      .I                              (sata_clk_p),
      .IB                             (sata_clk_n)
      );

   BUFG refclkout_dcm0_bufg_i
     (
      .I                              (tile0_refclkout_i),
      .O                              (tile0_refclkout_to_dcm_i)
      );

   assign  refclkout_dcm0_reset_i      = ~rst_n && ~tile0_plllkdet_i;
   MGT_USRCLK_SOURCE 
     refclkout_dcm0_i
       (
        .DIV1_OUT                       (tile0_txusrclk0_i),
        .DIV2_OUT                       (tile0_txusrclk20_i),
        .clkdv_i			(dev_clk_75M),
        .DCM_LOCKED_OUT                 (refclkout_dcm0_locked_i),
        .CLK_IN                         (tile0_refclkout_to_dcm_i),
        .DCM_RESET_IN                   (refclkout_dcm0_reset_i)
	);

   GTP_DUAL # 
     (
      //_______________________ Simulation-Only Attributes __________________

      .SIM_GTPRESET_SPEEDUP        (SIM_GTPRESET_SPEEDUP),
      .SIM_PLL_PERDIV2             (SIM_PLL_PERDIV2),

      //___________________________ Shared Attributes _______________________

      //---------------------- Tile and PLL Attributes ----------------------

      .CLK25_DIVIDER               (6), 
      .CLKINDC_B                   ("TRUE"),   
      .OOB_CLK_DIVIDER             (6),
      .OVERSAMPLE_MODE             ("FALSE"),
      .PLL_DIVSEL_FB               (2),
      .PLL_DIVSEL_REF              (1),
      .PLL_TXDIVSEL_COMM_OUT       (1),// 1), //2 for GEN1 and 1 for GEN2
        .TX_SYNC_FILTERB             (1),
        //______________________ Transmit Interface Attributes ________________

        //----------------- TX Buffering and Phase Alignment ------------------   

        .TX_BUFFER_USE_0            ("TRUE"),
        .TX_XCLK_SEL_0              ("TXOUT"),
        .TXRX_INVERT_0              (5'b00000),       

        .TX_BUFFER_USE_1            ("TRUE"),
        .TX_XCLK_SEL_1              ("TXOUT"),
        .TXRX_INVERT_1              (5'b00000),        

        //------------------- TX Serial Line Rate settings --------------------   

        .PLL_TXDIVSEL_OUT_0         (1),//1 ),//2),//2 for GEN1 and 1 for GEN2

        .PLL_TXDIVSEL_OUT_1         (1),//1),//2), 

        //------------------- TX Driver and OOB signalling --------------------  

         .TX_DIFF_BOOST_0           ("TRUE"),

         .TX_DIFF_BOOST_1           ("TRUE"),

        //---------------- TX Pipe Control for PCI Express/SATA ---------------

        .COM_BURST_VAL_0            (4'b0101),

        .COM_BURST_VAL_1            (4'b0101),

        //_______________________ Receive Interface Attributes ________________

        //---------- RX Driver,OOB signalling,Coupling and Eq.,CDR ------------  

        .AC_CAP_DIS_0               ("FALSE"),
        .OOBDETECT_THRESHOLD_0      (3'b111), 
        .PMA_CDR_SCAN_0             (27'h6c08040), 
        .PMA_RX_CFG_0               (25'h0dce111),
        .RCV_TERM_GND_0             ("FALSE"),
        .RCV_TERM_MID_0             ("TRUE"),
        .RCV_TERM_VTTRX_0           ("TRUE"),
        .TERMINATION_IMP_0          (50),

        .AC_CAP_DIS_1               ("FALSE"),
        .OOBDETECT_THRESHOLD_1      (3'b111), 
        .PMA_CDR_SCAN_1             (27'h6c08040), 
        .PMA_RX_CFG_1               (25'h0dce111),  
        .RCV_TERM_GND_1             ("FALSE"),
        .RCV_TERM_MID_1             ("TRUE"),
        .RCV_TERM_VTTRX_1           ("TRUE"),
        .TERMINATION_IMP_1          (50),

        .TERMINATION_CTRL           (5'b10100),
        .TERMINATION_OVRD           ("FALSE"),

        //------------------- RX Serial Line Rate Settings --------------------   

        .PLL_RXDIVSEL_OUT_0         (1),//2),//2 for GEN1 and 1 for GEN2
        .PLL_SATA_0                 ("FALSE"),

        .PLL_RXDIVSEL_OUT_1         (1),
        .PLL_SATA_1                 ("FALSE"),


        //------------------------- PRBS Detection ----------------------------  

        .PRBS_ERR_THRESHOLD_0       (32'h00000008),

        .PRBS_ERR_THRESHOLD_1       (32'h00000008),

        //------------------- Comma Detection and Alignment -------------------  

        .ALIGN_COMMA_WORD_0         (2),
        .COMMA_10B_ENABLE_0         (10'b1111111111),
        .COMMA_DOUBLE_0             ("FALSE"),
        .DEC_MCOMMA_DETECT_0        ("TRUE"),
        .DEC_PCOMMA_DETECT_0        ("TRUE"),
        .DEC_VALID_COMMA_ONLY_0     ("FALSE"),
        .MCOMMA_10B_VALUE_0         (10'b1010000011),
        .MCOMMA_DETECT_0            ("TRUE"),
        .PCOMMA_10B_VALUE_0         (10'b0101111100),
        .PCOMMA_DETECT_0            ("TRUE"),
        .RX_SLIDE_MODE_0            ("PCS"),

        .ALIGN_COMMA_WORD_1         (2),
        .COMMA_10B_ENABLE_1         (10'b1111111111),
        .COMMA_DOUBLE_1             ("FALSE"),
        .DEC_MCOMMA_DETECT_1        ("TRUE"),
        .DEC_PCOMMA_DETECT_1        ("TRUE"),
        .DEC_VALID_COMMA_ONLY_1     ("FALSE"),
        .MCOMMA_10B_VALUE_1         (10'b1010000011),
        .MCOMMA_DETECT_1            ("TRUE"),
        .PCOMMA_10B_VALUE_1         (10'b0101111100),
        .PCOMMA_DETECT_1            ("TRUE"),
        .RX_SLIDE_MODE_1            ("PCS"),


        //------------------- RX Loss-of-sync State Machine -------------------  

        .RX_LOSS_OF_SYNC_FSM_0      ("FALSE"),
        .RX_LOS_INVALID_INCR_0      (8),
        .RX_LOS_THRESHOLD_0         (128),

        .RX_LOSS_OF_SYNC_FSM_1      ("FALSE"),
        .RX_LOS_INVALID_INCR_1      (8),
        .RX_LOS_THRESHOLD_1         (128),

        //------------ RX Elastic Buffer and Phase alignment ports ------------   

        .RX_BUFFER_USE_0            ("TRUE"),
        .RX_XCLK_SEL_0              ("RXREC"),

        .RX_BUFFER_USE_1            ("TRUE"),
        .RX_XCLK_SEL_1              ("RXREC"),

        //--------------------- Clock Correction Attributes -------------------   

        .CLK_CORRECT_USE_0          ("TRUE"),
        .CLK_COR_ADJ_LEN_0          (4),
        .CLK_COR_DET_LEN_0          (4),
        .CLK_COR_INSERT_IDLE_FLAG_0 ("FALSE"),
        .CLK_COR_KEEP_IDLE_0        ("FALSE"),
        .CLK_COR_MAX_LAT_0          (18),
        .CLK_COR_MIN_LAT_0          (16),
        .CLK_COR_PRECEDENCE_0       ("TRUE"),
        .CLK_COR_REPEAT_WAIT_0      (0),
        .CLK_COR_SEQ_1_1_0          (10'b0110111100),
        .CLK_COR_SEQ_1_2_0          (10'b0001001010),
        .CLK_COR_SEQ_1_3_0          (10'b0001001010),
        .CLK_COR_SEQ_1_4_0          (10'b0001111011),
        .CLK_COR_SEQ_1_ENABLE_0     (4'b1111),
        .CLK_COR_SEQ_2_1_0          (10'b0000000000),
        .CLK_COR_SEQ_2_2_0          (10'b0000000000),
        .CLK_COR_SEQ_2_3_0          (10'b0000000000),
        .CLK_COR_SEQ_2_4_0          (10'b0000000000),
        .CLK_COR_SEQ_2_ENABLE_0     (4'b0000),
        .CLK_COR_SEQ_2_USE_0        ("FALSE"),
        .RX_DECODE_SEQ_MATCH_0      ("TRUE"),

        .CLK_CORRECT_USE_1          ("TRUE"),
        .CLK_COR_ADJ_LEN_1          (4),
        .CLK_COR_DET_LEN_1          (4),
        .CLK_COR_INSERT_IDLE_FLAG_1 ("FALSE"),
        .CLK_COR_KEEP_IDLE_1        ("FALSE"),
        .CLK_COR_MAX_LAT_1          (18),
        .CLK_COR_MIN_LAT_1          (16),
        .CLK_COR_PRECEDENCE_1       ("TRUE"),
        .CLK_COR_REPEAT_WAIT_1      (0),
        .CLK_COR_SEQ_1_1_1          (10'b0110111100),
        .CLK_COR_SEQ_1_2_1          (10'b0001001010),
        .CLK_COR_SEQ_1_3_1          (10'b0001001010),
        .CLK_COR_SEQ_1_4_1          (10'b0001111011),
        .CLK_COR_SEQ_1_ENABLE_1     (4'b1111),
        .CLK_COR_SEQ_2_1_1          (10'b0000000000),
        .CLK_COR_SEQ_2_2_1          (10'b0000000000),
        .CLK_COR_SEQ_2_3_1          (10'b0000000000),
        .CLK_COR_SEQ_2_4_1          (10'b0000000000),
        .CLK_COR_SEQ_2_ENABLE_1     (4'b0000),
        .CLK_COR_SEQ_2_USE_1        ("FALSE"),
        .RX_DECODE_SEQ_MATCH_1      ("TRUE"),

        //-------------------- Channel Bonding Attributes ---------------------   

        .CHAN_BOND_1_MAX_SKEW_0     (7),
        .CHAN_BOND_2_MAX_SKEW_0     (7),
        .CHAN_BOND_LEVEL_0          (0),
        .CHAN_BOND_MODE_0           ("OFF"),
        .CHAN_BOND_SEQ_1_1_0        (10'b0000000000),
        .CHAN_BOND_SEQ_1_2_0        (10'b0000000000),
        .CHAN_BOND_SEQ_1_3_0        (10'b0000000000),
        .CHAN_BOND_SEQ_1_4_0        (10'b0000000000),
        .CHAN_BOND_SEQ_1_ENABLE_0   (4'b0000),
        .CHAN_BOND_SEQ_2_1_0        (10'b0000000000),
        .CHAN_BOND_SEQ_2_2_0        (10'b0000000000),
        .CHAN_BOND_SEQ_2_3_0        (10'b0000000000),
        .CHAN_BOND_SEQ_2_4_0        (10'b0000000000),
        .CHAN_BOND_SEQ_2_ENABLE_0   (4'b0000),
        .CHAN_BOND_SEQ_2_USE_0      ("FALSE"),  
        .CHAN_BOND_SEQ_LEN_0        (1),
        .PCI_EXPRESS_MODE_0         ("FALSE"),     
     
        .CHAN_BOND_1_MAX_SKEW_1     (7),
        .CHAN_BOND_2_MAX_SKEW_1     (7),
        .CHAN_BOND_LEVEL_1          (0),
        .CHAN_BOND_MODE_1           ("OFF"),
        .CHAN_BOND_SEQ_1_1_1        (10'b0000000000),
        .CHAN_BOND_SEQ_1_2_1        (10'b0000000000),
        .CHAN_BOND_SEQ_1_3_1        (10'b0000000000),
        .CHAN_BOND_SEQ_1_4_1        (10'b0000000000),
        .CHAN_BOND_SEQ_1_ENABLE_1   (4'b0000),
        .CHAN_BOND_SEQ_2_1_1        (10'b0000000000),
        .CHAN_BOND_SEQ_2_2_1        (10'b0000000000),
        .CHAN_BOND_SEQ_2_3_1        (10'b0000000000),
        .CHAN_BOND_SEQ_2_4_1        (10'b0000000000),
        .CHAN_BOND_SEQ_2_ENABLE_1   (4'b0000),
        .CHAN_BOND_SEQ_2_USE_1      ("FALSE"),  
        .CHAN_BOND_SEQ_LEN_1        (1),
        .PCI_EXPRESS_MODE_1         ("FALSE"),

        //---------------- RX Attributes for PCI Express/SATA ---------------

        .RX_STATUS_FMT_0            ("SATA"),
        .SATA_BURST_VAL_0           (3'b100),
        .SATA_IDLE_VAL_0            (3'b100),
        .SATA_MAX_BURST_0           (7),
        .SATA_MAX_INIT_0            (22),
        .SATA_MAX_WAKE_0            (7),
        .SATA_MIN_BURST_0           (4),
        .SATA_MIN_INIT_0            (12),
        .SATA_MIN_WAKE_0            (4),
        .TRANS_TIME_FROM_P2_0       (16'h0060),
        .TRANS_TIME_NON_P2_0        (16'h0025),
        .TRANS_TIME_TO_P2_0         (16'h0100),

        .RX_STATUS_FMT_1            ("SATA"),
        .SATA_BURST_VAL_1           (3'b100),
        .SATA_IDLE_VAL_1            (3'b100),
        .SATA_MAX_BURST_1           (7),
        .SATA_MAX_INIT_1            (22),
        .SATA_MAX_WAKE_1            (7),
        .SATA_MIN_BURST_1           (4),
        .SATA_MIN_INIT_1            (12),
        .SATA_MIN_WAKE_1            (4),
        .TRANS_TIME_FROM_P2_1       (16'h0060),
        .TRANS_TIME_NON_P2_1        (16'h0025),
        .TRANS_TIME_TO_P2_1         (16'h0100)         
     ) 
     GTP_DUAL_DEVICE_PHY 
     (

        //---------------------- Loopback and Powerdown Ports ----------------------
        .LOOPBACK0                      (3'b000),
        .LOOPBACK1                      (3'b000),
        .RXPOWERDOWN0                   (2'b00),
        .RXPOWERDOWN1                   (2'b00),
        .TXPOWERDOWN0                   (2'b00),
        .TXPOWERDOWN1                   (2'b00),
        //--------------------- Receive Ports - 8b10b Decoder ----------------------
        .RXCHARISCOMMA0                 (),
        .RXCHARISCOMMA1                 (),
        .RXCHARISK0                     (tile0_rxcharisk0_out),
        .RXCHARISK1                     (),
        .RXDEC8B10BUSE0                 (1'b1),
        .RXDEC8B10BUSE1                 (1'b1),
        .RXDISPERR0                     (),
        .RXDISPERR1                     (),
        .RXNOTINTABLE0                  (),
        .RXNOTINTABLE1                  (),
        .RXRUNDISP0                     (),
        .RXRUNDISP1                     (),
        //----------------- Receive Ports - Channel Bonding Ports ------------------
        .RXCHANBONDSEQ0                 (),
        .RXCHANBONDSEQ1                 (),
        .RXCHBONDI0                     (3'b000),
        .RXCHBONDI1                     (3'b000),
        .RXCHBONDO0                     (),
        .RXCHBONDO1                     (),
        .RXENCHANSYNC0                  (1'b1),
        .RXENCHANSYNC1                  (1'b1),
        //----------------- Receive Ports - Clock Correction Ports -----------------
        .RXCLKCORCNT0                   (),
        .RXCLKCORCNT1                   (),
        //------------- Receive Ports - Comma Detection and Alignment --------------
        .RXBYTEISALIGNED0               (rxbyteisaligned),
        .RXBYTEISALIGNED1               (),
        .RXBYTEREALIGN0                 (RXBYTEREALIGN0),
        .RXBYTEREALIGN1                 (),
        .RXCOMMADET0                    (),
        .RXCOMMADET1                    (),
        .RXCOMMADETUSE0                 (1'b1),
        .RXCOMMADETUSE1                 (1'b1),
        .RXENMCOMMAALIGN0               (1'b1),
        .RXENMCOMMAALIGN1               (1'b1),
        .RXENPCOMMAALIGN0               (1'b1),
        .RXENPCOMMAALIGN1               (1'b1),
        .RXSLIDE0                       (1'b0),
        .RXSLIDE1                       (1'b0),
        //--------------------- Receive Ports - PRBS Detection ---------------------
        .PRBSCNTRESET0                  (1'b0),
        .PRBSCNTRESET1                  (1'b0),
        .RXENPRBSTST0                   (2'b00),
        .RXENPRBSTST1                   (2'b00),
        .RXPRBSERR0                     (),
        .RXPRBSERR1                     (),
        //----------------- Receive Ports - RX Data Path interface -----------------
        .RXDATA0                        (tile0_rx_data_phy0_out),
        .RXDATA1                        (),
        .RXDATAWIDTH0                   (1'b1),
        .RXDATAWIDTH1                   (1'b1),
        .RXRECCLK0                      (),
        .RXRECCLK1                      (),
        .RXRESET0                       (!rst_n|!refclkout_dcm0_locked_i),// | rxreset),
        .RXRESET1                       (!rst_n|!refclkout_dcm0_locked_i),// | rxreset),
        .RXUSRCLK0                      (tile0_txusrclk0_i),
        .RXUSRCLK1                      (tile0_txusrclk0_i),
        .RXUSRCLK20                     (tile0_txusrclk20_i),
        .RXUSRCLK21                     (tile0_txusrclk20_i),
        //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        .RXCDRRESET0                    (!rst_n | !refclkout_dcm0_locked_i),
        .RXCDRRESET1                    (!rst_n | !refclkout_dcm0_locked_i),
        .RXELECIDLE0                    (rxelecidle0),
        .RXELECIDLE1                    (rxelecidle1),
        .RXELECIDLERESET0               (rxelecidlereset0),
        .RXELECIDLERESET1               (rxelecidlereset1),
        .RXENEQB0                       (1'b1),
        .RXENEQB1                       (1'b1),
        .RXEQMIX0                       (2'b00),
        .RXEQMIX1                       (2'b00),
        .RXEQPOLE0                      (4'b0000),
        .RXEQPOLE1                      (4'b0000),
        .RXN0                           (RXN_IN0),
        .RXN1                           (),
        .RXP0                           (RXP_IN0),
        .RXP1                           (),
        //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
        .RXBUFRESET0                    (!rst_n | !refclkout_dcm0_locked_i),// | rxreset),
        .RXBUFRESET1                    (!rst_n | !refclkout_dcm0_locked_i),
        .RXBUFSTATUS0                   (),
        .RXBUFSTATUS1                   (),
        .RXCHANISALIGNED0               (),
        .RXCHANISALIGNED1               (),
        .RXCHANREALIGN0                 (),
        .RXCHANREALIGN1                 (),
        .RXPMASETPHASE0                 (1'b0),
        .RXPMASETPHASE1                 (1'b0),
        .RXSTATUS0                      (tile0_rxstatus0_i),
        .RXSTATUS1                      (),
        //------------- Receive Ports - RX Loss-of-sync State Machine --------------
        .RXLOSSOFSYNC0                  (),
        .RXLOSSOFSYNC1                  (),
        //-------------------- Receive Ports - RX Oversampling ---------------------
        .RXENSAMPLEALIGN0               (1'b0),
        .RXENSAMPLEALIGN1               (1'b0),
        .RXOVERSAMPLEERR0               (),
        .RXOVERSAMPLEERR1               (),
        //------------ Receive Ports - RX Pipe Control for PCI Express -------------
        .PHYSTATUS0                     (),
        .PHYSTATUS1                     (),
        .RXVALID0                       (),
        .RXVALID1                       (),
        //--------------- Receive Ports - RX Polarity Control Ports ----------------
        .RXPOLARITY0                    (1'b0),
        .RXPOLARITY1                    (1'b0),
        //----------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
        .DADDR                          (7'b0),
        .DCLK                           (1'b0),//gtp_txusrclk2),
        .DEN                            (1'b0),
        .DI                             (16'h0),
        .DO                             (),
        .DRDY                           (),
        .DWE                            (1'b0),
        //------------------- Shared Ports - Tile and PLL Ports --------------------
        .CLKIN                          (tile0_refclk_i),
        .GTPRESET                       (!rst_n),
        .GTPTEST                        (4'b0000),
        .INTDATAWIDTH                   (1'b1),
        .PLLLKDET                       (tile0_plllkdet_i),
        .PLLLKDETEN                     (1'b1),
        .PLLPOWERDOWN                   (1'b0),
        .REFCLKOUT                      (tile0_refclkout_i),
        .REFCLKPWRDNB                   (1'b1),
        .RESETDONE0                     (tile0_resetdone0_i),
        .RESETDONE1                     (),
        .RXENELECIDLERESETB             (rxenelecidleresetb),
        .TXENPMAPHASEALIGN              (1'b0),
        .TXPMASETPHASE                  (1'b0),
        //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        .TXBYPASS8B10B0                 ({1'b0,1'b0}),
        .TXBYPASS8B10B1                 ({1'b0,1'b0}),
        .TXCHARDISPMODE0                ({1'b0,1'b0}),
        .TXCHARDISPMODE1                ({1'b0,1'b0}),
        .TXCHARDISPVAL0                 ({1'b0,1'b0}),
        .TXCHARDISPVAL1                 ({1'b0,1'b0}),
        .TXCHARISK0                     ({1'b0,tile0_txcharisk0_in}),
        .TXCHARISK1                     ({1'b0,1'b0}),
        .TXENC8B10BUSE0                 (1'b1),
        .TXENC8B10BUSE1                 (1'b1),
        .TXKERR0                        (),
        .TXKERR1                        (),
        .TXRUNDISP0                     (),
        .TXRUNDISP1                     (),
        //----------- Transmit Ports - TX Buffering and Phase Alignment ------------
        .TXBUFSTATUS0                   (),
        .TXBUFSTATUS1                   (),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .TXDATA0                        (tile0_tx_data_phy0_in),
        .TXDATA1                        (),
        .TXDATAWIDTH0                   (1'b1),
        .TXDATAWIDTH1                   (1'b1),
        .TXOUTCLK0                      (),//tile0_refclkout_i),
        .TXOUTCLK1                      (),
        .TXRESET0                       (!rst_n|!refclkout_dcm0_locked_i),
        .TXRESET1                       (),
        .TXUSRCLK0                      (tile0_txusrclk0_i),
        .TXUSRCLK1                      (tile0_txusrclk0_i),
        .TXUSRCLK20                     (tile0_txusrclk20_i),
        .TXUSRCLK21                     (tile0_txusrclk20_i),
        //------------- Transmit Ports - TX Driver and OOB signalling --------------
        .TXBUFDIFFCTRL0                 (3'b001),
        .TXBUFDIFFCTRL1                 (3'b001),
        .TXDIFFCTRL0                    (3'b100),
        .TXDIFFCTRL1                    (3'b100),
        .TXINHIBIT0                     (1'b0),
        .TXINHIBIT1                     (1'b0),
        .TXN0                           (TXN_OUT0),
        .TXN1                           (),
        .TXP0                           (TXP_OUT0),
        .TXP1                           (),
        .TXPREEMPHASIS0                 (3'b011),
        .TXPREEMPHASIS1                 (3'b011),
        //------------------- Transmit Ports - TX PRBS Generator -------------------
        .TXENPRBSTST0                   (0),
        .TXENPRBSTST1                   (0),
        //------------------ Transmit Ports - TX Polarity Control ------------------
        .TXPOLARITY0                    (1'b0),
        .TXPOLARITY1                    (1'b0),
        //--------------- Transmit Ports - TX Ports for PCI Express ----------------
        .TXDETECTRX0                    (1'b0),
        .TXDETECTRX1                    (1'b0),
        .TXELECIDLE0                    (txelecidle0),
        .TXELECIDLE1                    (),
        //------------------- Transmit Ports - TX Ports for SATA -------------------
        .TXCOMSTART0                    (txcomstart),
        .TXCOMSTART1                    (1'b0),
        .TXCOMTYPE0                     (txcomtype), //this is 0 for cominit/comreset/  and 1 for comwake
        .TXCOMTYPE1                     (1'b0)
);
endmodule    
