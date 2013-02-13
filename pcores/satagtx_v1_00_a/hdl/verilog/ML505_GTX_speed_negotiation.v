//*****************************************************************************
// Copyright (c) 2008 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, Inc.
// All Rights Reserved
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: $Name: ml505_GTP_SATA_v1_0 $
//  \   \         Application: XAPP870
//  /   /         Filename: ML505_GTP_spd_neg.v
// /___/   /\     Date Last Modified: $Date: 2008/12/4 00:00:00 $
// \   \  /  \    Date Created: Wed Jan 2 2008
//  \___\/\___\
//
//Device: Virtex-5 LXT
//Design Name: ML505_GTP_speed_negotiation
//Purpose:
// This module handles the SATA Gen1/Gen2 speed negotiation
//    
//Reference:
//Revision History: rev1.1
//*****************************************************************************

module ML505_GTX_speed_negotiation
(/*AUTOARG*/
   // Outputs
   TXP0_OUT, TXN0_OUT, TXP1_OUT, TXN1_OUT, rxdata_fis0, rxcharisk0,
   link_up0, CommInit0, rxdata_fis1, rxcharisk1, link_up1, CommInit1,
   gtx_refclkout, tile_pll_lock_det, dcm_clk_rst_n, dcm_clk_75m,
   dcm_clk_75m_bufg, dcm_clk_150m, oob2dbg0,
   // Inputs
   host_rst, rst_n, RXP0_IN, RXN0_IN, RXP1_IN, RXN1_IN, txdata_fis0,
   tx_charisk_fis0, phyreset0, phyclk0, StartComm0, txdata_fis1,
   tx_charisk_fis1, phyreset1, phyclk1, StartComm1, clk_75m,
   gtx_refclk, clk_150m, phy2cs_data0, phy2cs_k0, phy2cs_data1,
   phy2cs_k1
   );
    parameter   C_DCM_ENABLE = 1;
    // Simulation attributes
    parameter   TILE_SIM_MODE              =   "FAST";  // Set to Fast Functional Simulation Model
    parameter   TILE_SIM_GTXRESET_SPEEDUP  =   0;       // Set to 1 to speed up sim reset
    parameter   TILE_SIM_PLL_PERDIV2       =   9'h140;  // Set to the VCO Unit Interval time
    
    // Channel bonding attributes
    parameter   TILE_CHAN_BOND_MODE_0      =   "OFF";  // "MASTER", "SLAVE", or "OFF"
    parameter   TILE_CHAN_BOND_LEVEL_0     =   0;      // 0 to 7. See UG for details
    
    parameter   TILE_CHAN_BOND_MODE_1      =   "OFF";  // "MASTER", "SLAVE", or "OFF"
    parameter   TILE_CHAN_BOND_LEVEL_1     =   0 ;     // 0 to 7. See UG for details


	input		host_rst;		// Main GTP reset
        input           rst_n;

	input           RXP0_IN;		// Receiver input
	input           RXN0_IN;		// Receiver input
	output		TXP0_OUT;
	output		TXN0_OUT;
	
	input           RXP1_IN;		// Receiver input
	input           RXN1_IN;		// Receiver input
	output		TXP1_OUT;
	output		TXN1_OUT;

        input  [31:0]   txdata_fis0;
        input           tx_charisk_fis0;
        output [31:0]   rxdata_fis0;
        output [3:0]    rxcharisk0;
        input           phyreset0;
        input           phyclk0;
	output		link_up0;
        input           StartComm0;
        output          CommInit0;
        
	input  [31:0]   txdata_fis1;
        input           tx_charisk_fis1;
        output [31:0]   rxdata_fis1;
        output [3:0]    rxcharisk1;
        input           phyreset1;
        input           phyclk1;
	output		link_up1;
        input           StartComm1;
        output          CommInit1;

	input		clk_75m;
        input           gtx_refclk;
        input           clk_150m;
        output          gtx_refclkout;
        output          tile_pll_lock_det;

	output dcm_clk_rst_n;
	output dcm_clk_75m;
	output dcm_clk_75m_bufg;
	output dcm_clk_150m;
	output [127:0] oob2dbg0;

	input [31:0]   phy2cs_data0;
	input          phy2cs_k0;
	input [31:0]   phy2cs_data1;
	input          phy2cs_k1;

	wire        	gtx_rxusrclk, gtx_rxusrclk2;
	wire            gtx_txusrclk, gtx_txusrclk2;
	wire	[3:0]	rxcharisk0;
        wire            tx_charisk_phy0;
	wire	[3:0]	rxcharisk1;
        wire            tx_charisk_phy1;
	wire	[2:0]   rxstatus0;
        wire    [2:0]   rxstatus1;
	wire		txcomtype0, txcomstart0;
	wire		txcomtype1, txcomstart1;
	wire		sync_det_out, align_det_out;
	wire		tx_charisk0;
	wire    [3:0]   rx_charisk_out0;
	wire		tx_charisk1;
	wire    [3:0]   rx_charisk_out1;
	wire		txelecidle0, txelecidle1, rxelecidle0, rxelecidle1, rxenelecidleresetb; 
	wire		resetdone0, resetdone1;
	wire	[31:0]	txdata0, rxdata0, rxdataout0; // TX/RX data
	wire	[31:0]	txdata1, rxdata1, rxdataout1; // TX/RX data
	wire	[3:0]	CurrentState_out;
	wire	[4:0]	state_out;
	wire		rx_sof_det_out, rx_eof_det_out;
	wire		TILE0_PLLLKDET_OUT;
 	wire 		linkup0;
	//wire		clk0, clk2x, dcm_clk0, dcm_clkdv, dcm_clk2x; // DCM output clocks
	wire		usrclk, logic_clk; //GTP user clocks
      	wire		dcm_locked;
	wire		gtx_refclkout;
	wire		GEN2; //this is the selection for GEN2 when set to 1
	wire		system_reset;
 	wire		speed_neg_rst;
	wire	[6:0]	daddr;	//DRP Address
	wire        	den;	//DRP enable
	wire	[15:0]	di;	//DRP data in
	wire	[15:0]	do;	//DRP data out
	wire		drdy;	//DRP ready
	wire		dwe;	//DRP write enable 
	wire		rxreset0;	//GTP Rxreset
        wire            rxreset1;
	wire 				RXBYTEREALIGN0, RXBYTEISALIGNED0;
	wire 		RXRECCLK0;
	//wire 		dcm_reset;
	wire 		rst_0;
	wire 		rst_debounce;
	wire 		push_button_rst;
	wire 		dcm_refclkin;
        //wire            clkdv; 
        wire            linkup1; 
	wire            TXOUTCLK;

	reg  		rst_1;  
	reg  		rst_2;
	reg  		rst_3;
        reg             host_rst_1;
        reg             host_rst_2;
        reg             host_rst_3;
        reg             host_rst_4;
        reg             host_rst_5;
	reg  		rx_sof_det_out_reg, rx_eof_det_out_reg;
	reg	[31:0]	rxdataout_reg;

	wire            gtx_refclkout_i;
//        assign clk_2x = clk0;      //150m in GEN2
//	assign system_reset = rst_debounce;
//        assign gtx_reset = host_rst || speed_neg_rst;
//	assign gtx_reset = rst_debounce|| speed_neg_rst;	
        assign gtx_reset = 1'b0;
        assign tile_pll_lock_det = TILE0_PLLLKDET_OUT;
	
	assign link_up0 = linkup0;	
	assign link_up1 = linkup1;	

	assign TILE0_PLLLKDET_OUT_N = TILE0_PLLLKDET_OUT;         
	assign  rxelecidlereset0          =   (rxelecidle0 && resetdone0);
	assign  rxenelecidleresetb        =   !rxelecidlereset0; 

assign rst_0 = host_rst;  

wire [31:0] txdata_phy0;
wire [31:0] rxdata_phy0;
wire [31:0] txdata_phy1;
wire [31:0] rxdata_phy1;

assign txdata_phy0 = linkup0? txdata_fis0: txdata0 ;
assign rxdata0 = rxdata_phy0 ;
assign rxdata_fis0  = rxdata_phy0 ;
assign tx_charisk_phy0 = linkup0? tx_charisk_fis0: tx_charisk0;

assign txdata_phy1 = linkup1? txdata_fis1: txdata1 ;
assign rxdata1 = rxdata_phy1 ;
assign rxdata_fis1  = rxdata_phy1 ;
assign tx_charisk_phy1 = linkup1? tx_charisk_fis1: tx_charisk1;

   wire     txenpmaphasealign0_i;
   wire     txenpmaphasealign1_i;
   wire     txpmasetphase0_i;
   wire     txpmasetphase1_i;
   reg 	    tx_resetdone0_r2;
   reg 	    tx_resetdone1_r2;   
   reg 	    tx_resetdone0_r;
   reg 	    tx_resetdone1_r;   
   wire     tx_sync_done0_i;
   wire     tx_sync_done1_i;
   
wire StartComm_reg0;
oob_control oob_control_0 
    (
     	.clk				(phyclk0),
 	.reset		      		(phyreset0),
 	.link_reset			(1'b0),
 	.rx_locked			(TILE0_PLLLKDET_OUT && tx_sync_done0_i),
 	.tx_datain			(10'h0),		// User datain port
 	.tx_dataout			(txdata0),		// outgoing GTP data
 	.tx_charisk			(tx_charisk0),          
	.rx_charisk			(rxcharisk0),                             
 	.rx_datain			(rxdata0),              	// incoming GTP data 
 	.rx_dataout			(rxdataout0),         	// User dataout port
 	.rx_charisk_out			(rx_charisk_out0),         	// User charisk port 	
 	.linkup                 	(linkup0),
	.gen2             		(1'b1),//GEN2),
	.rxreset			(rxreset0),
 	.txcomstart			(txcomstart0),
 	.txcomtype			(txcomtype0),
 	.rxstatus			(rxstatus0),
 	.rxelecidle			(rxelecidle0),
 	.txelecidle			(txelecidle0),
 	.rxbyteisaligned		(RXBYTEISALIGNED0), 	
 	.CurrentState_out       	(CurrentState_out),
 	.align_det_out          	(),
 	.sync_det_out           	(),
 	.rx_sof_det_out         	(),
 	.rx_eof_det_out         	(),
	.oob2dbg                        (),
	.StartComm                      (StartComm0),
	.CommInit                       (CommInit0),
	.StartComm_reg                  (StartComm_reg0)
    );

oob_control oob_control_1 
    (
     	.clk				(phyclk1),
 	.reset		      		(phyreset1),
 	.link_reset			(1'b0),
 	.rx_locked			(TILE0_PLLLKDET_OUT && tx_sync_done1_i),
 	.tx_datain			(10'h0),		// User datain port
 	.tx_dataout			(txdata1),		// outgoing GTP data
 	.tx_charisk			(tx_charisk1),          
	.rx_charisk			(rxcharisk1),                             
 	.rx_datain			(rxdata1),              	// incoming GTP data 
 	.rx_dataout			(rxdataout1),         	// User dataout port
 	.rx_charisk_out			(rx_charisk_out1),         	// User charisk port 	
 	.linkup                 	(linkup1),
	.gen2             		(1'b1),//GEN2),
	.rxreset			(rxreset1),
 	.txcomstart			(txcomstart1),
 	.txcomtype			(txcomtype1),
 	.rxstatus			(rxstatus1),
 	.rxelecidle			(rxelecidle1),
 	.txelecidle			(txelecidle1),
 	.rxbyteisaligned		(RXBYTEISALIGNED1), 	
 	.CurrentState_out       	(),
 	.align_det_out          	(),
 	.sync_det_out           	(),
 	.rx_sof_det_out         	(),
 	.rx_eof_det_out         	(),
	.StartComm                      (StartComm1),
	.CommInit                       (CommInit1)
    );

   
    //------------------------- GTX Instantiations  --------------------------   

    GTX_DUAL # 
    (
        //_______________________ Simulation-Only Attributes __________________

        .SIM_RECEIVER_DETECT_PASS_0  ("TRUE"),
        
        .SIM_RECEIVER_DETECT_PASS_1  ("TRUE"),

        .SIM_MODE                    (TILE_SIM_MODE), 
        .SIM_GTXRESET_SPEEDUP        (TILE_SIM_GTXRESET_SPEEDUP),
        .SIM_PLL_PERDIV2             (TILE_SIM_PLL_PERDIV2),
 

        //___________________________ Shared Attributes _______________________
         
        //---------------------- Tile and PLL Attributes ----------------------

        .CLK25_DIVIDER               (6), 
        .CLKINDC_B                   ("TRUE"),
        .CLKRCV_TRST                 ("TRUE"),
        .OOB_CLK_DIVIDER             (6),
        .OVERSAMPLE_MODE             ("FALSE"),
        .PLL_COM_CFG                 (24'h21680a),
        .PLL_CP_CFG                  (8'h00),
        .PLL_DIVSEL_FB               (2),
        .PLL_DIVSEL_REF              (1),
        .PLL_FB_DCCEN                ("FALSE"),
        .PLL_LKDET_CFG               (3'b101),
        .PLL_TDCC_CFG                (3'b000),
        .PMA_COM_CFG                 (69'h000000000000000000),

        //______________________ Transmit Interface Attributes ________________

 
        //----------------- TX Buffering and Phase Alignment ------------------   

        .TX_BUFFER_USE_0            ("FALSE"),
        .TX_XCLK_SEL_0              ("TXUSR"),
        .TXRX_INVERT_0              (3'b111),        

        .TX_BUFFER_USE_1            ("FALSE"),
        .TX_XCLK_SEL_1              ("TXUSR"),
        .TXRX_INVERT_1              (3'b111),        

        //------------------- TX Gearbox Settings -----------------------------

        .GEARBOX_ENDEC_0            (3'b000), 
        .TXGEARBOX_USE_0            ("FALSE"),

        .GEARBOX_ENDEC_1            (3'b000), 
        .TXGEARBOX_USE_1            ("FALSE"),

        //------------------- TX Serial Line Rate settings --------------------   

        .PLL_TXDIVSEL_OUT_0         (1),
	
        .PLL_TXDIVSEL_OUT_1         (1), 

        //------------------- TX Driver and OOB signalling --------------------  
       
        .CM_TRIM_0                 (2'b10),
        .PMA_TX_CFG_0              (20'h80082),
        .TX_DETECT_RX_CFG_0        (14'h1832),
        .TX_IDLE_DELAY_0           (3'b010),
        
        .CM_TRIM_1                 (2'b10),
        .PMA_TX_CFG_1              (20'h80082),
        .TX_DETECT_RX_CFG_1        (14'h1832),
        .TX_IDLE_DELAY_1           (3'b010),

        //---------------- TX Pipe Control for PCI Express/SATA ---------------

        .COM_BURST_VAL_0            (4'b1111),

        .COM_BURST_VAL_1            (4'b1111),

        //_______________________ Receive Interface Attributes ________________


        //---------- RX Driver,OOB signalling,Coupling and Eq.,CDR ------------  
        
        .AC_CAP_DIS_0               ("TRUE"),
        .OOBDETECT_THRESHOLD_0      (3'b110),
        .PMA_CDR_SCAN_0             (27'h640403b), 
        .PMA_RX_CFG_0               (25'h0f44089),
        .RCV_TERM_GND_0             ("FALSE"),
        .RCV_TERM_VTTRX_0           ("TRUE"),
        .TERMINATION_IMP_0          (50),

        .AC_CAP_DIS_1               ("TRUE"),
        .OOBDETECT_THRESHOLD_1      (3'b110),
        .PMA_CDR_SCAN_1             (27'h640403b), 
        .PMA_RX_CFG_1               (25'h0f44089),  
        .RCV_TERM_GND_1             ("FALSE"),
        .RCV_TERM_VTTRX_1           ("TRUE"),
        .TERMINATION_IMP_1          (50),

        .TERMINATION_CTRL           (5'b10100),
        .TERMINATION_OVRD           ("FALSE"),

        //-------------- RX Decision Feedback Equalizer(DFE)  ----------------  

        .DFE_CFG_0                  (10'b1001111011),
                  
        .DFE_CFG_1                  (10'b1001111011),

        .DFE_CAL_TIME               (5'b00110),

        //------------------- RX Serial Line Rate Settings --------------------   

        .PLL_RXDIVSEL_OUT_0         (1),
        .PLL_SATA_0                 ("FALSE"),

        .PLL_RXDIVSEL_OUT_1         (1),
        .PLL_SATA_1                 ("FALSE"),


        //------------------------- PRBS Detection ----------------------------  

        .PRBS_ERR_THRESHOLD_0       (32'h00000001),

        .PRBS_ERR_THRESHOLD_1       (32'h00000001),

        //------------------- Comma Detection and Alignment -------------------  

        .ALIGN_COMMA_WORD_0         (1),
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

        .ALIGN_COMMA_WORD_1         (1),
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

        //------------------- RX Gearbox Settings -----------------------------

        .RXGEARBOX_USE_0            ("FALSE"),

        .RXGEARBOX_USE_1            ("FALSE"),

        //------------ RX Elastic Buffer and Phase alignment ports ------------   
        
        .PMA_RXSYNC_CFG_0           (7'h00),
        .RX_BUFFER_USE_0            ("TRUE"),
        .RX_XCLK_SEL_0              ("RXREC"),

        .PMA_RXSYNC_CFG_1           (7'h00),
        .RX_BUFFER_USE_1            ("TRUE"),
        .RX_XCLK_SEL_1              ("RXREC"),

        //--------------------- Clock Correction Attributes -------------------   

        .CLK_CORRECT_USE_0          ("TRUE"),
        .CLK_COR_ADJ_LEN_0          (4),
        .CLK_COR_DET_LEN_0          (4),
        .CLK_COR_INSERT_IDLE_FLAG_0 ("FALSE"),
        .CLK_COR_KEEP_IDLE_0        ("FALSE"),
        .CLK_COR_MAX_LAT_0          (22),
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
        .CLK_COR_MAX_LAT_1          (22),
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

        .CB2_INH_CC_PERIOD_0        (8),
        .CHAN_BOND_1_MAX_SKEW_0     (1),
        .CHAN_BOND_2_MAX_SKEW_0     (1),
        .CHAN_BOND_KEEP_ALIGN_0     ("FALSE"),
        .CHAN_BOND_LEVEL_0          (TILE_CHAN_BOND_LEVEL_0),
        .CHAN_BOND_MODE_0           (TILE_CHAN_BOND_MODE_0),
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
     
        .CB2_INH_CC_PERIOD_1        (8),
        .CHAN_BOND_1_MAX_SKEW_1     (1),
        .CHAN_BOND_2_MAX_SKEW_1     (1),
        .CHAN_BOND_KEEP_ALIGN_1     ("FALSE"),
        .CHAN_BOND_LEVEL_1          (TILE_CHAN_BOND_LEVEL_1),
        .CHAN_BOND_MODE_1           (TILE_CHAN_BOND_MODE_1),
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

        //------ RX Attributes to Control Reset after Electrical Idle  ------

        .RX_EN_IDLE_HOLD_DFE_0      ("TRUE"),
        .RX_EN_IDLE_RESET_BUF_0     ("TRUE"),
        .RX_IDLE_HI_CNT_0           (4'b1000),
        .RX_IDLE_LO_CNT_0           (4'b0000),

        .RX_EN_IDLE_HOLD_DFE_1      ("TRUE"),
        .RX_EN_IDLE_RESET_BUF_1     ("TRUE"),
        .RX_IDLE_HI_CNT_1           (4'b1000),
        .RX_IDLE_LO_CNT_1           (4'b0000),


        .CDR_PH_ADJ_TIME            (5'b01010),
        .RX_EN_IDLE_RESET_FR        ("TRUE"),
        .RX_EN_IDLE_HOLD_CDR        ("FALSE"),
        .RX_EN_IDLE_RESET_PH        ("TRUE"),

        //---------------- RX Attributes for PCI Express/SATA ---------------
        
        .RX_STATUS_FMT_0            ("SATA"),
        .SATA_BURST_VAL_0           (3'b100),
        .SATA_IDLE_VAL_0            (3'b011),
        .SATA_MAX_BURST_0           (7),
        .SATA_MAX_INIT_0            (22),
        .SATA_MAX_WAKE_0            (7),
        .SATA_MIN_BURST_0           (4),
        .SATA_MIN_INIT_0            (12),
        .SATA_MIN_WAKE_0            (4),
        .TRANS_TIME_FROM_P2_0       (16'h003c),
        .TRANS_TIME_NON_P2_0        (16'h0019),
        .TRANS_TIME_TO_P2_0         (16'h0064),

        .RX_STATUS_FMT_1            ("SATA"),
        .SATA_BURST_VAL_1           (3'b100),
        .SATA_IDLE_VAL_1            (3'b011),
        .SATA_MAX_BURST_1           (7),
        .SATA_MAX_INIT_1            (22),
        .SATA_MAX_WAKE_1            (7),
        .SATA_MIN_BURST_1           (4),
        .SATA_MIN_INIT_1            (12),
        .SATA_MIN_WAKE_1            (4),
        .TRANS_TIME_FROM_P2_1       (16'h003c),
        .TRANS_TIME_NON_P2_1        (16'h0019),
        .TRANS_TIME_TO_P2_1         (16'h0064)         
     ) 
     gtx_dual_i 
     (

        //---------------------- Loopback and Powerdown Ports ----------------------
        .LOOPBACK0                      (3'b000),
        .LOOPBACK1                      (3'b000),
        .RXPOWERDOWN0                   (2'b00),
        .RXPOWERDOWN1                   (2'b00),
        .TXPOWERDOWN0                   (2'b00),
        .TXPOWERDOWN1                   (2'b00),
        //------------ Receive Ports - 64b66b and 64b67b Gearbox Ports -------------
        .RXDATAVALID0                   (),
        .RXDATAVALID1                   (),
        .RXGEARBOXSLIP0                 (1'b0),
        .RXGEARBOXSLIP1                 (1'b0),
        .RXHEADER0                      (),
        .RXHEADER1                      (),
        .RXHEADERVALID0                 (),
        .RXHEADERVALID1                 (),
        .RXSTARTOFSEQ0                  (),
        .RXSTARTOFSEQ1                  (),
        //--------------------- Receive Ports - 8b10b Decoder ----------------------
        .RXCHARISCOMMA0                 (RXCHARISCOMMA0_OUT),
        .RXCHARISCOMMA1                 (RXCHARISCOMMA1_OUT),
        .RXCHARISK0                     (rxcharisk0[3:0]),
        .RXCHARISK1                     (rxcharisk1[3:0]),
        .RXDEC8B10BUSE0                 (1'b1),
        .RXDEC8B10BUSE1                 (1'b1),
        .RXDISPERR0                     (RXDISPERR0_OUT),
        .RXDISPERR1                     (RXDISPERR1_OUT),
        .RXNOTINTABLE0                  (RXNOTINTABLE0_OUT),
        .RXNOTINTABLE1                  (RXNOTINTABLE1_OUT),
        .RXRUNDISP0                     (),
        .RXRUNDISP1                     (),
        //----------------- Receive Ports - Channel Bonding Ports ------------------
        .RXCHANBONDSEQ0                 (),
        .RXCHANBONDSEQ1                 (),
        .RXCHBONDI0                     (4'b0000),
        .RXCHBONDI1                     (4'b0000),
        .RXCHBONDO0                     (),
        .RXCHBONDO1                     (),
        .RXENCHANSYNC0                  (1'b1),
        .RXENCHANSYNC1                  (1'b1),
        //----------------- Receive Ports - Clock Correction Ports -----------------
        .RXCLKCORCNT0                   (RXCLKCORCNT0_OUT),
        .RXCLKCORCNT1                   (RXCLKCORCNT1_OUT),
        //------------- Receive Ports - Comma Detection and Alignment --------------
        .RXBYTEISALIGNED0               (RXBYTEISALIGNED0_OUT),
        .RXBYTEISALIGNED1               (RXBYTEISALIGNED1_OUT),
        .RXBYTEREALIGN0                 (),
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
        .RXDATA0                        (rxdata_phy0),
        .RXDATA1                        (rxdata_phy1),
        .RXDATAWIDTH0                   (2'b10),
        .RXDATAWIDTH1                   (2'b10),
        .RXRECCLK0                      (),
        .RXRECCLK1                      (),
        .RXRESET0                       (rxreset0),
        .RXRESET1                       (rxreset1),
        .RXUSRCLK0                      (gtx_rxusrclk),
        .RXUSRCLK1                      (gtx_rxusrclk),
        .RXUSRCLK20                     (gtx_rxusrclk2),
        .RXUSRCLK21                     (gtx_rxusrclk2),
        //---------- Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
        .DFECLKDLYADJ0                  (6'b000000),
        .DFECLKDLYADJ1                  (6'b000000),
        .DFECLKDLYADJMONITOR0           (),
        .DFECLKDLYADJMONITOR1           (),
        .DFEEYEDACMONITOR0              (),
        .DFEEYEDACMONITOR1              (),
        .DFESENSCAL0                    (),
        .DFESENSCAL1                    (),
        .DFETAP10                       (5'b00000),
        .DFETAP11                       (5'b00000),
        .DFETAP1MONITOR0                (),
        .DFETAP1MONITOR1                (),
        .DFETAP20                       (5'b00000),
        .DFETAP21                       (5'b00000),
        .DFETAP2MONITOR0                (),
        .DFETAP2MONITOR1                (),
        .DFETAP30                       (4'b0000),
        .DFETAP31                       (4'b0000),
        .DFETAP3MONITOR0                (),
        .DFETAP3MONITOR1                (),
        .DFETAP40                       (4'b0000),
        .DFETAP41                       (4'b0000),
        .DFETAP4MONITOR0                (),
        .DFETAP4MONITOR1                (),
        //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        .RXCDRRESET0                    (1'b0),
        .RXCDRRESET1                    (1'b0),
        .RXELECIDLE0                    (rxelecidle0),
        .RXELECIDLE1                    (rxelecidle1),
        .RXENEQB0                       (1'b0),
        .RXENEQB1                       (1'b0),
        .RXEQMIX0                       (2'b00),
        .RXEQMIX1                       (2'b00),
        .RXEQPOLE0                      (4'b0000),
        .RXEQPOLE1                      (4'b0000),
        .RXN0                           (RXN0_IN),
        .RXN1                           (RXN1_IN),
        .RXP0                           (RXP0_IN),
        .RXP1                           (RXP1_IN),
        //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
        .RXBUFRESET0                    (1'b0),
        .RXBUFRESET1                    (1'b0),
        .RXBUFSTATUS0                   (),
        .RXBUFSTATUS1                   (),
        .RXCHANISALIGNED0               (),
        .RXCHANISALIGNED1               (),
        .RXCHANREALIGN0                 (),
        .RXCHANREALIGN1                 (),
        .RXENPMAPHASEALIGN0             (1'b0),
        .RXENPMAPHASEALIGN1             (1'b0),
        .RXPMASETPHASE0                 (1'b0),
        .RXPMASETPHASE1                 (1'b0),
        .RXSTATUS0                      (rxstatus0),
        .RXSTATUS1                      (rxstatus1),
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
        .DADDR                          (7'b0000000),
        .DCLK                           (1'b0),
        .DEN                            (1'b0),
        .DI                             (16'b0000000000000000),
        .DO                             (),
        .DRDY                           (),
        .DWE                            (1'b0),
        //------------------- Shared Ports - Tile and PLL Ports --------------------
        .CLKIN                          (gtx_refclk),
        .GTXRESET                       (~rst_n),
        .GTXTEST                        (14'b10000000000000),
        .INTDATAWIDTH                   (1'b1),
        .PLLLKDET                       (TILE0_PLLLKDET_OUT),
        .PLLLKDETEN                     (1'b1),
        .PLLPOWERDOWN                   (1'b0),
        .REFCLKOUT                      (gtx_refclkout_i),
        .REFCLKPWRDNB                   (1'b1),
        .RESETDONE0                     (resetdone0),
        .RESETDONE1                     (resetdone1),
        //------------ Transmit Ports - 64b66b and 64b67b Gearbox Ports ------------
        .TXGEARBOXREADY0                (),
        .TXGEARBOXREADY1                (),
        .TXHEADER0                      (3'b000),
        .TXHEADER1                      (3'b000),
        .TXSEQUENCE0                    (7'b0000000),
        .TXSEQUENCE1                    (7'b0000000),
        .TXSTARTSEQ0                    (1'b0),
        .TXSTARTSEQ1                    (1'b0),
        //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        .TXBYPASS8B10B0                 (4'b0000),
        .TXBYPASS8B10B1                 (4'b0000),
        .TXCHARDISPMODE0                (4'b0000),
        .TXCHARDISPMODE1                (4'b0000),
        .TXCHARDISPVAL0                 (4'b0000),
        .TXCHARDISPVAL1                 (4'b0000),
        .TXCHARISK0                     ({3'b000,tx_charisk_phy0}),
        .TXCHARISK1                     ({3'b000,tx_charisk_phy1}),
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
        .TXDATA0                        (txdata_phy0),
        .TXDATA1                        (txdata_phy1),
        .TXDATAWIDTH0                   (2'b10),
        .TXDATAWIDTH1                   (2'b10),
        .TXOUTCLK0                      (TXOUTCLK),
        .TXOUTCLK1                      (),
        .TXRESET0                       (!dcm_locked),
        .TXRESET1                       (!dcm_locked),
        .TXUSRCLK0                      (gtx_txusrclk),
        .TXUSRCLK1                      (gtx_txusrclk),
        .TXUSRCLK20                     (gtx_txusrclk2),
        .TXUSRCLK21                     (gtx_txusrclk2),
        //------------- Transmit Ports - TX Driver and OOB signalling --------------
        .TXBUFDIFFCTRL0                 (3'b101),
        .TXBUFDIFFCTRL1                 (3'b101),
        .TXDIFFCTRL0                    (3'b000),
        .TXDIFFCTRL1                    (3'b000),
        .TXINHIBIT0                     (1'b0),
        .TXINHIBIT1                     (1'b0),
        .TXN0                           (TXN0_OUT),
        .TXN1                           (TXN1_OUT),
        .TXP0                           (TXP0_OUT),
        .TXP1                           (TXP1_OUT),
        .TXPREEMPHASIS0                 (4'b0000),
        .TXPREEMPHASIS1                 (4'b0000),
        //------ Transmit Ports - TX Elastic Buffer and Phase Alignment Ports ------
        .TXENPMAPHASEALIGN0             (txenpmaphasealign0_i),
        .TXENPMAPHASEALIGN1             (txenpmaphasealign1_i),
        .TXPMASETPHASE0                 (txpmasetphase0_i),
        .TXPMASETPHASE1                 (txpmasetphase1_i),
        //------------------- Transmit Ports - TX PRBS Generator -------------------
        .TXENPRBSTST0                   (2'b00),
        .TXENPRBSTST1                   (2'b00),
        //------------------ Transmit Ports - TX Polarity Control ------------------
        .TXPOLARITY0                    (1'b0),
        .TXPOLARITY1                    (1'b0),
        //--------------- Transmit Ports - TX Ports for PCI Express ----------------
        .TXDETECTRX0                    (1'b0),
        .TXDETECTRX1                    (1'b0),
        .TXELECIDLE0                    (txelecidle0),
        .TXELECIDLE1                    (txelecidle1),
        //------------------- Transmit Ports - TX Ports for SATA -------------------
        .TXCOMSTART0                    (txcomstart0),
        .TXCOMSTART1                    (txcomstart1),
        .TXCOMTYPE0                     (txcomtype0),
        .TXCOMTYPE1                     (txcomtype1)

     );
     BUFG refclkout_i (.I(gtx_refclkout_i), .O(gtx_refclkout));

     assign gtx_txusrclk  = clk_150m;
     assign gtx_rxusrclk  = clk_150m;
     assign gtx_txusrclk2 = clk_75m;
     assign gtx_rxusrclk2 = clk_75m;

   TX_SYNC #(.PLL_DIVSEL_OUT(1),
             .TILE_SIM_GTXRESET_SPEEDUP(TILE_SIM_GTXRESET_SPEEDUP))
   tx_sync0_i (.TXENPMAPHASEALIGN(txenpmaphasealign0_i),
	       .TXPMASETPHASE(txpmasetphase0_i),
	       .SYNC_DONE(tx_sync_done0_i),
	       .USER_CLK(gtx_txusrclk2),
	       .RESET(!tx_resetdone0_r2));
   always @(posedge gtx_txusrclk2 or negedge resetdone0)
     begin
	if (!resetdone0)
	  begin
	     tx_resetdone0_r <= #1 1'b0;
	     tx_resetdone0_r2<= #1 1'b0;
	  end
	else
	  begin
	     tx_resetdone0_r <= #1 resetdone0;
	     tx_resetdone0_r2<= #1 tx_resetdone0_r;	     
	  end
     end // always @ (posedge gtx_txusrclk2 or negedge resetdone0)
   
   TX_SYNC #(.PLL_DIVSEL_OUT(1),
             .TILE_SIM_GTXRESET_SPEEDUP(TILE_SIM_GTXRESET_SPEEDUP))
   tx_sync1_i (.TXENPMAPHASEALIGN(txenpmaphasealign1_i),
	       .TXPMASETPHASE(txpmasetphase1_i),
	       .SYNC_DONE(tx_sync_done1_i),
	       .USER_CLK(gtx_txusrclk2),
	       .RESET(!tx_resetdone1_r2));
   always @(posedge gtx_txusrclk2 or negedge resetdone1)
     begin
	if (!resetdone1)
	  begin
	     tx_resetdone1_r <= #1 1'b0;
	     tx_resetdone1_r2<= #1 1'b0;
	  end
	else
	  begin
	     tx_resetdone1_r <= #1 resetdone1;
	     tx_resetdone1_r2<= #1 tx_resetdone1_r;	     
	  end
     end // always @ (posedge gtx_txusrclk2 or negedge resetdone0)
   
(* PERIOD = "13333ps" *) /* 75Mhz  */
wire clk0;
(* PERIOD = "13333ps" *) /* 75Mhz  */
wire dcm_clk0; 
(* PERIOD = "13333ps" *) /* 75Mhz  */
wire dcm_clkdv;
(* PERIOD = "13333ps" *) /* 75Mhz  */
wire clkdv;
(* PERIOD = "06666ps" *) /* 150Mhz */
wire clk2x; 
(* PERIOD = "06666ps" *) /* 150Mhz */
wire dcm_clk2x;

wire dcm_reset;
wire dcm_clk_in;

generate if (C_DCM_ENABLE == 1)
begin
assign dcm_clk_in = gtx_refclkout;
//assign dcm_reset  = 1'b0;
assign dcm_reset = ~TILE0_PLLLKDET_OUT;
//BUFG txout (.I(TXOUTCLK),.O(dcm_clk_in));

BUFG dcm_clk0_bufg (
   .I (dcm_clk0), 
   .O (clk0)
   );
   
BUFG dcm_clkdv_bufg (
   .I (dcm_clkdv), 
   .O (clkdv)
   );   
   
BUFG dcm_clk2x_bufg (
   .I (dcm_clk2x), 
   .O (clk2x)
   );

// DCM for GTP clocks   
DCM_BASE #(
   .CLKDV_DIVIDE          (2.0),
   .CLKIN_PERIOD          (6.666),
   .DLL_FREQUENCY_MODE    ("HIGH"),
   .DUTY_CYCLE_CORRECTION ("TRUE"),
   .FACTORY_JF            (16'hF0F0)
   ) 
GEN2_DCM(
   .CLK0     (dcm_clk0),             // 0 degree DCM CLK ouptput
   .CLK180   (),                     // 180 degree DCM CLK output
   .CLK270   (),                     // 270 degree DCM CLK output
   .CLK2X    (dcm_clk2x),            // 2X DCM CLK output
   .CLK2X180 (), 	             // 2X, 180 degree DCM CLK out
   .CLK90    (),                     // 90 degree DCM CLK output
   .CLKDV    (dcm_clkdv),            // Divided DCM CLK out (CLKDV_DIVIDE)
   .CLKFX    (),                     // DCM CLK synthesis out (M/D)
   .CLKFX180 (), 	             // 180 degree CLK synthesis out
   .LOCKED   (dcm_locked),           // DCM LOCK status output
   .CLKFB    (clk0),                 // DCM clock feedback   
   .CLKIN    (dcm_clk_in),            // Clock input (from IBUFG, BUFG or DCM)
   .RST      (dcm_reset)//gtp_reset)             // DCM asynchronous reset input
   ); 
   assign dcm_clk_rst_n    = dcm_locked;
   assign dcm_clk_75m      = clkdv;
   assign dcm_clk_150m     = clk0;
   //assign dcm_clk_75m_bufg = clkdv;
   BUFG clk75m_bufg (.I(clkdv), .O(dcm_clk_75m_bufg));
end
endgenerate

wire [63:0] gtxdata2dbg;
wire [31:0] gtxctrl2dbg;

assign oob2dbg0[127:64]     = gtxdata2dbg;
assign oob2dbg0[63:32]      = gtxctrl2dbg;
assign oob2dbg0[31:0]       = phy2cs_data0;

assign gtxdata2dbg[31:00]  = txdata_phy0;
assign gtxdata2dbg[63:32]  = rxdata_phy0;

assign gtxctrl2dbg[3:0]    = rxcharisk0;
assign gtxctrl2dbg[7:4]    = {3'b000, tx_charisk_phy0};

assign gtxctrl2dbg[8]      = dcm_reset;
assign gtxctrl2dbg[9]      = dcm_locked;
assign gtxctrl2dbg[10]     = TILE0_PLLLKDET_OUT;
assign gtxctrl2dbg[11]     = linkup0;
assign gtxctrl2dbg[12]     = rxelecidle0;
assign gtxctrl2dbg[13]     = resetdone0;
assign gtxctrl2dbg[14]     = txcomstart0;
assign gtxctrl2dbg[15]     = txcomtype0;
assign gtxctrl2dbg[18:16]  = rxstatus0;
assign gtxctrl2dbg[19]     = phy2cs_k0;
assign gtxctrl2dbg[20]     = StartComm0;
assign gtxctrl2dbg[21]     = StartComm_reg0;
assign gtxctrl2dbg[31:28]  = CurrentState_out;

endmodule
