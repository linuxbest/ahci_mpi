`timescale 1ns / 1ps
`define DLY #1


//***********************************Entity Declaration************************

module v5_gtp_top #
(
    parameter EXAMPLE_SIM_MODE                          =   "FAST", // Set to Fast Functional Simulation Model
    parameter EXAMPLE_SIM_GTXRESET_SPEEDUP              =   0,      // simulation setting for MGT smartmodel
    parameter EXAMPLE_SIM_PLL_PERDIV2                   =   9'h14d, // simulation setting for MGT smartmodel
    parameter C_CHIPSCOPE = 0,
    parameter C_BYPASS_TXBUF = 1,
    parameter C_SATA_SPEED = 2
)
(/*AUTOARG*/
   // Outputs
   TXN0_OUT, TXP0_OUT, TXN1_OUT, TXP1_OUT, refclkout, plllkdet,
   txdatak_pop0, rxdata_fis0, rxcharisk0, link_up0, CommInit0,
   gtx_txdata0, gtx_txdatak0, gtx_rxdata0, gtx_rxdatak0, txdatak_pop1,
   rxdata_fis1, rxcharisk1, link_up1, CommInit1, gtx_txdata1,
   gtx_txdatak1, gtx_rxdata1, gtx_rxdatak1, oob2dbg0, oob2dbg1,
   // Inputs
   GTXRESET_IN, RXN0_IN, RXP0_IN, RXN1_IN, RXP1_IN, refclk,
   dcm_locked, txusrclk0, txusrclk20, txdata_fis0, tx_charisk_fis0,
   phyreset0, phyclk0, StartComm0, gtx_tune0, txdata_fis1,
   tx_charisk_fis1, phyreset1, phyclk1, StartComm1, gtx_tune1,
   phy2cs_data0, phy2cs_k0, phy2cs_data1, phy2cs_k1
   );
`include "sata.v"
//***********************************Ports Declaration*******************************
   input           GTXRESET_IN;
   input           RXN0_IN;
   input           RXP0_IN;
   output          TXN0_OUT;
   output          TXP0_OUT;
   input           RXN1_IN;
   input           RXP1_IN;
   output          TXN1_OUT;
   output          TXP1_OUT;

   input           refclk;
   output 	   refclkout;
   output 	   plllkdet;
   
   input 	   dcm_locked;
   input 	   txusrclk0;
   input 	   txusrclk20;

   input [31:0]    txdata_fis0;
   input           tx_charisk_fis0;
   output 	   txdatak_pop0;
   output [31:0]   rxdata_fis0;
   output [3:0]    rxcharisk0;
   input           phyreset0;
   input           phyclk0;
   output 	   link_up0;
   input           StartComm0;
   output          CommInit0;
   input [31:0]    gtx_tune0;
   output [31:0]   gtx_txdata0;
   output [3:0]	   gtx_txdatak0;
   output [31:0]   gtx_rxdata0;
   output [3:0]	   gtx_rxdatak0;
   
   input [31:0]    txdata_fis1;
   input           tx_charisk_fis1;
   output 	   txdatak_pop1;   
   output [31:0]   rxdata_fis1;
   output [3:0]    rxcharisk1;
   input           phyreset1;
   input           phyclk1;
   output 	   link_up1;
   input           StartComm1;
   output          CommInit1;   
   input [31:0]    gtx_tune1;
   output [31:0]   gtx_txdata1;
   output [3:0]	   gtx_txdatak1;
   output [31:0]   gtx_rxdata1;
   output [3:0]	   gtx_rxdatak1;   

   input [31:0]    phy2cs_data0;
   input           phy2cs_k0;
   input [31:0]    phy2cs_data1;
   input           phy2cs_k1;

   output [127:0]  oob2dbg0;
   output [127:0]  oob2dbg1;
//************************** Register Declarations ****************************

    reg     [84:0]  ila_in0_r;
    reg     [84:0]  ila_in1_r;
    reg             tile0_tx_resetdone0_r;
    reg             tile0_tx_resetdone0_r2;
    reg             tile0_rx_resetdone0_r;
    reg             tile0_rx_resetdone0_r2;
    reg             tile0_tx_resetdone1_r;
    reg             tile0_tx_resetdone1_r2;
    reg             tile0_rx_resetdone1_r;
    reg             tile0_rx_resetdone1_r2;
    

//**************************** Wire Declarations ******************************

    //------------------------ MGT Wrapper Wires ------------------------------
    

    //________________________________________________________________________
    //________________________________________________________________________
    //TILE0   (X0Y7)

    //---------------------- Loopback and Powerdown Ports ----------------------
    wire    [2:0]   tile0_loopback0_i;
    wire    [2:0]   tile0_loopback1_i;
    //--------------------- Receive Ports - 8b10b Decoder ----------------------
    wire    [3:0]   tile0_rxchariscomma0_i;
    wire    [3:0]   tile0_rxchariscomma1_i;
    wire    [3:0]   tile0_rxcharisk0_i;
    wire    [3:0]   tile0_rxcharisk1_i;
    wire    [3:0]   tile0_rxdisperr0_i;
    wire    [3:0]   tile0_rxdisperr1_i;
    wire    [3:0]   tile0_rxnotintable0_i;
    wire    [3:0]   tile0_rxnotintable1_i;
    //----------------- Receive Ports - Clock Correction Ports -----------------
    wire    [2:0]   tile0_rxclkcorcnt0_i;
    wire    [2:0]   tile0_rxclkcorcnt1_i;
    //------------- Receive Ports - Comma Detection and Alignment --------------
    wire            tile0_rxbyteisaligned0_i;
    wire            tile0_rxbyteisaligned1_i;
    wire            tile0_rxenmcommaalign0_i;
    wire            tile0_rxenmcommaalign1_i;
    wire            tile0_rxenpcommaalign0_i;
    wire            tile0_rxenpcommaalign1_i;
    //----------------- Receive Ports - RX Data Path interface -----------------
    wire    [31:0]  tile0_rxdata0_i;
    wire    [31:0]  tile0_rxdata1_i;
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    wire            tile0_rxelecidle0_i;
    wire            tile0_rxelecidle1_i;
    wire    [1:0]   tile0_rxeqmix0_i;
    wire    [1:0]   tile0_rxeqmix1_i;
    //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    wire    [2:0]   tile0_rxstatus0_i;
    wire    [2:0]   tile0_rxstatus1_i;
    //------------------- Shared Ports - Tile and PLL Ports --------------------
    wire            tile0_gtxreset_i;
    wire            tile0_plllkdet_i;
    wire            tile0_refclkout_i;
    wire            tile0_resetdone0_i;
    wire            tile0_resetdone1_i;
    //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
    wire    [3:0]   tile0_txcharisk0_i;
    wire    [3:0]   tile0_txcharisk1_i;
    //---------------- Transmit Ports - TX Data Path interface -----------------
    wire    [31:0]  tile0_txdata0_i;
    wire    [31:0]  tile0_txdata1_i;
    //------------- Transmit Ports - TX Driver and OOB signalling --------------
    wire    [2:0]   tile0_txdiffctrl0_i;
    wire    [2:0]   tile0_txdiffctrl1_i;
    wire    [2:0]   tile0_txpreemphasis0_i;
    wire    [2:0]   tile0_txpreemphasis1_i;
    //------ Transmit Ports - TX Elastic Buffer and Phase Alignment Ports ------
    wire            tile0_txenpmaphasealign0_i;
    wire            tile0_txenpmaphasealign1_i;
    wire            tile0_txpmasetphase0_i;
    wire            tile0_txpmasetphase1_i;
    //------------------- Transmit Ports - TX Ports for SATA -------------------
    wire            tile0_txcomstart0_i;
    wire            tile0_txcomstart1_i;
    wire            tile0_txcomtype0_i;
    wire            tile0_txcomtype1_i;


    //----------------------------- Global Signals -----------------------------
    wire            tile0_tx_system_reset0_c;
    wire            tile0_rx_system_reset0_c;
    wire            tile0_tx_system_reset1_c;
    wire            tile0_rx_system_reset1_c;
    wire            tied_to_ground_i;
    wire    [63:0]  tied_to_ground_vec_i;
    wire            tied_to_vcc_i;
    wire    [7:0]   tied_to_vcc_vec_i;
    wire            drp_clk_in_i;
    
    wire            tile0_refclkout_bufg_i;
    
    
    //--------------------------- User Clocks ---------------------------------
    wire            tile0_txusrclk0_i;
    wire            tile0_txusrclk20_i;
    wire            refclkout_dcm0_locked_i;
    wire            refclkout_dcm0_reset_i;
    wire            tile0_refclkout_to_dcm_i;


    //--------------------- Frame check/gen Module Signals --------------------
    wire            tile0_refclk_i;
    wire            tile0_matchn0_i;
    
    wire    [7:0]   tile0_txdata0_float_i;
    
    
    wire            tile0_block_sync0_reset_i;
    wire            tile0_track_data0_i;
    wire    [7:0]   tile0_error_count0_i;
    wire            tile0_frame_check0_reset_i;
    wire            tile0_inc_in0_i;
    wire            tile0_inc_out0_i;
    wire    [31:0]  tile0_unscrambled_data0_i;
    wire            tile0_matchn1_i;
    
    wire    [7:0]   tile0_txdata1_float_i;
    
    
    wire            tile0_block_sync1_reset_i;
    wire            tile0_track_data1_i;
    wire    [7:0]   tile0_error_count1_i;
    wire            tile0_frame_check1_reset_i;
    wire            tile0_inc_in1_i;
    wire            tile0_inc_out1_i;
    wire    [31:0]  tile0_unscrambled_data1_i;

    wire            reset_on_data_error_i;
    wire            track_data_out_i;

    //----------------------- Sync Module Signals -----------------------------


    wire            tile0_tx_sync_done0_i;
    wire            tile0_tx_sync_done1_i;

    //--------------------- Chipscope Signals ---------------------------------

    wire    [35:0]  shared_vio_control_i;
    wire    [35:0]  tx_data_vio_control0_i;
    wire    [35:0]  tx_data_vio_control1_i;
    wire    [35:0]  rx_data_vio_control0_i;
    wire    [35:0]  rx_data_vio_control1_i;
    wire    [35:0]  ila_control0_i;
    wire    [35:0]  ila_control1_i;
    wire    [31:0]  shared_vio_in_i;
    wire    [31:0]  shared_vio_out_i;
    wire    [31:0]  tx_data_vio_in0_i;
    wire    [31:0]  tx_data_vio_out0_i;
    wire    [31:0]  tx_data_vio_in1_i;
    wire    [31:0]  tx_data_vio_out1_i;
    wire    [31:0]  rx_data_vio_in0_i;
    wire    [31:0]  rx_data_vio_out0_i;
    wire    [31:0]  rx_data_vio_in1_i;
    wire    [31:0]  rx_data_vio_out1_i;
    wire    [84:0]  ila_in0_i;
    wire    [84:0]  ila_in1_i;

    wire    [31:0]  tile0_tx_data_vio_in0_i;
    wire    [31:0]  tile0_tx_data_vio_out0_i;
    wire    [31:0]  tile0_tx_data_vio_in1_i;
    wire    [31:0]  tile0_tx_data_vio_out1_i;
    wire    [31:0]  tile0_rx_data_vio_in0_i;
    wire    [31:0]  tile0_rx_data_vio_out0_i;
    wire    [31:0]  tile0_rx_data_vio_in1_i;
    wire    [31:0]  tile0_rx_data_vio_out1_i;
    wire    [84:0]  tile0_ila_in0_i;
    wire    [84:0]  tile0_ila_in1_i;


    wire            gtxreset_i;
    wire            user_tx_reset_i;
    wire            user_rx_reset_i;


   wire 	    tile0_rxreset0_i;
   wire 	    tile0_rxreset1_i;
   wire 	    tile0_txelecidle0_i;
   wire 	    tile0_txelecidle1_i;   
   
//**************************** Main Body of Code *******************************

    //  Static signal Assigments    
    assign tied_to_ground_i             = 1'b0;
    assign tied_to_ground_vec_i         = 64'h0000000000000000;
    assign tied_to_vcc_i                = 1'b1;
    assign tied_to_vcc_vec_i            = 8'hff;


    //--------------------------- The GTX Wrapper -----------------------------
    
    // Use the instantiation template in the project directory to add the GTX wrapper to your design.
    // In this example, the wrapper is wired up for basic operation with a frame generator and frame 
    // checker. The GTXs will reset, then attempt to align and transmit data. If channel bonding is 
    // enabled, bonding should occur after alignment.
 
    
    // Wire all PLLLKDET signals to the top level as output ports
    assign TILE0_PLLLKDET_OUT = tile0_plllkdet_i;


    V5_GTPWIZARD_V2_1 #
    (
        .WRAPPER_SIM_MODE               (EXAMPLE_SIM_MODE),
        .WRAPPER_SIM_GTPRESET_SPEEDUP   (EXAMPLE_SIM_GTXRESET_SPEEDUP),
        .WRAPPER_SIM_PLL_PERDIV2        (EXAMPLE_SIM_PLL_PERDIV2)/*,
	.C_BYPASS_TXBUF                 (C_BYPASS_TXBUF)*/
    )
    rocketio_wrapper_i
    (
        //_____________________________________________________________________
        //_____________________________________________________________________
        //TILE0  (X0Y7)

        //---------------------- Loopback and Powerdown Ports ----------------------
        .TILE0_LOOPBACK0_IN             (tile0_loopback0_i),
        .TILE0_LOOPBACK1_IN             (tile0_loopback1_i),
        //--------------------- Receive Ports - 8b10b Decoder ----------------------
        .TILE0_RXCHARISCOMMA0_OUT       (tile0_rxchariscomma0_i),
        .TILE0_RXCHARISCOMMA1_OUT       (tile0_rxchariscomma1_i),
        .TILE0_RXCHARISK0_OUT           (tile0_rxcharisk0_i),
        .TILE0_RXCHARISK1_OUT           (tile0_rxcharisk1_i),
        .TILE0_RXDISPERR0_OUT           (tile0_rxdisperr0_i),
        .TILE0_RXDISPERR1_OUT           (tile0_rxdisperr1_i),
        .TILE0_RXNOTINTABLE0_OUT        (tile0_rxnotintable0_i),
        .TILE0_RXNOTINTABLE1_OUT        (tile0_rxnotintable1_i),
        //----------------- Receive Ports - Clock Correction Ports -----------------
        .TILE0_RXCLKCORCNT0_OUT         (tile0_rxclkcorcnt0_i),
        .TILE0_RXCLKCORCNT1_OUT         (tile0_rxclkcorcnt1_i),
        //------------- Receive Ports - Comma Detection and Alignment --------------
        .TILE0_RXBYTEISALIGNED0_OUT     (tile0_rxbyteisaligned0_i),
        .TILE0_RXBYTEISALIGNED1_OUT     (tile0_rxbyteisaligned1_i),
        .TILE0_RXENMCOMMAALIGN0_IN      (tile0_rxenmcommaalign0_i),
        .TILE0_RXENMCOMMAALIGN1_IN      (tile0_rxenmcommaalign1_i),
        .TILE0_RXENPCOMMAALIGN0_IN      (tile0_rxenpcommaalign0_i),
        .TILE0_RXENPCOMMAALIGN1_IN      (tile0_rxenpcommaalign1_i),
        //----------------- Receive Ports - RX Data Path interface -----------------
        .TILE0_RXDATA0_OUT              (tile0_rxdata0_i),
        .TILE0_RXDATA1_OUT              (tile0_rxdata1_i),
        .TILE0_RXRESET0_IN              (phyreset0),
        .TILE0_RXRESET1_IN              (phyreset1),
        .TILE0_RXUSRCLK0_IN             (tile0_txusrclk0_i),
        .TILE0_RXUSRCLK1_IN             (tile0_txusrclk0_i),
        .TILE0_RXUSRCLK20_IN            (tile0_txusrclk20_i),
        .TILE0_RXUSRCLK21_IN            (tile0_txusrclk20_i),
        //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        .TILE0_RXELECIDLE0_OUT          (tile0_rxelecidle0_i),
        .TILE0_RXELECIDLE1_OUT          (tile0_rxelecidle1_i),
        .TILE0_TXELECIDLE0_IN           (tile0_txelecidle0_i),
        .TILE0_TXELECIDLE1_IN           (tile0_txelecidle1_i),     
        .TILE0_RXEQMIX0_IN              (tile0_rxeqmix0_i),
        .TILE0_RXEQMIX1_IN              (tile0_rxeqmix1_i),
	.TILE0_RXEQPOLE0_IN             (4'h0),
	.TILE0_RXEQPOLE1_IN             (4'h0),
        .TILE0_RXN0_IN                  (RXN0_IN),
        .TILE0_RXN1_IN                  (RXN1_IN),
        .TILE0_RXP0_IN                  (RXP0_IN),
        .TILE0_RXP1_IN                  (RXP1_IN),
        //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
        .TILE0_RXSTATUS0_OUT            (tile0_rxstatus0_i),
        .TILE0_RXSTATUS1_OUT            (tile0_rxstatus1_i),
        //------------------- Shared Ports - Tile and PLL Ports --------------------
        .TILE0_CLKIN_IN                 (tile0_refclk_i),
        .TILE0_GTPRESET_IN              (tile0_gtxreset_i),
        .TILE0_PLLLKDET_OUT             (tile0_plllkdet_i),
        .TILE0_REFCLKOUT_OUT            (tile0_refclkout_i),
        .TILE0_RESETDONE0_OUT           (tile0_resetdone0_i),
        .TILE0_RESETDONE1_OUT           (tile0_resetdone1_i),
        //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        .TILE0_TXCHARISK0_IN            (tile0_txcharisk0_i),
        .TILE0_TXCHARISK1_IN            (tile0_txcharisk1_i),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .TILE0_TXDATA0_IN               (tile0_txdata0_i),
        .TILE0_TXDATA1_IN               (tile0_txdata1_i),
        .TILE0_TXRESET0_IN              (phyreset0),
        .TILE0_TXRESET1_IN              (phyreset1),
        .TILE0_TXUSRCLK0_IN             (tile0_txusrclk0_i),
        .TILE0_TXUSRCLK1_IN             (tile0_txusrclk0_i),
        .TILE0_TXUSRCLK20_IN            (tile0_txusrclk20_i),
        .TILE0_TXUSRCLK21_IN            (tile0_txusrclk20_i),
        //------------- Transmit Ports - TX Driver and OOB signalling --------------
        .TILE0_TXDIFFCTRL0_IN           (tile0_txdiffctrl0_i),
        .TILE0_TXDIFFCTRL1_IN           (tile0_txdiffctrl1_i),
        .TILE0_TXN0_OUT                 (TXN0_OUT),
        .TILE0_TXN1_OUT                 (TXN1_OUT),
        .TILE0_TXP0_OUT                 (TXP0_OUT),
        .TILE0_TXP1_OUT                 (TXP1_OUT),
        //------ Transmit Ports - TX Elastic Buffer and Phase Alignment Ports ------
        .TILE0_TXENPMAPHASEALIGN_IN     (tile0_txenpmaphasealign0_i),
        .TILE0_TXPMASETPHASE_IN         (tile0_txpmasetphase0_i),
        //------------------- Transmit Ports - TX Ports for SATA -------------------
        .TILE0_TXCOMSTART0_IN           (tile0_txcomstart0_i),
        .TILE0_TXCOMSTART1_IN           (tile0_txcomstart1_i),
        .TILE0_TXCOMTYPE0_IN            (tile0_txcomtype0_i),
        .TILE0_TXCOMTYPE1_IN            (tile0_txcomtype1_i)
    );
generate if (C_BYPASS_TXBUF == 1) 
begin
    //---------------------------- TXSYNC module ------------------------------
    // The TXSYNC module performs phase synchronization for all the active TX datapaths. It
    // waits for the user clocks to be stable, then drives the phase align signals on each
    // GTX. When phase synchronization is complete, it asserts SYNC_DONE
    
    // Include the TX_SYNC module in your own design to perform phase synchronization if
    // your protocol bypasses the TX Buffers
    TX_SYNC tile0_txsync0_i 
    (
        .TXENPMAPHASEALIGN(tile0_txenpmaphasealign0_i),
        .TXPMASETPHASE(tile0_txpmasetphase0_i),
        .SYNC_DONE(tile0_tx_sync_done0_i),
        .USER_CLK(tile0_txusrclk20_i),
        .RESET(!tile0_tx_resetdone0_r2)
    );
  
    TX_SYNC tile0_txsync1_i 
    (
        .TXENPMAPHASEALIGN(tile0_txenpmaphasealign1_i),
        .TXPMASETPHASE(tile0_txpmasetphase1_i),
        .SYNC_DONE(tile0_tx_sync_done1_i),
        .USER_CLK(tile0_txusrclk20_i),
        .RESET(!tile0_tx_resetdone1_r2)
    );
end
endgenerate
generate if (C_BYPASS_TXBUF == 0)
begin
    assign tile0_txenpmaphasealign0_i = 1'b0;
    assign tile0_txpmasetphase0_i     = 1'b0;
    assign tile0_tx_sync_done0_i      = 1'b1;
    assign tile0_txenpmaphasealign1_i = 1'b0;
    assign tile0_txpmasetphase1_i     = 1'b0;
    assign tile0_tx_sync_done1_i      = 1'b1;
end
endgenerate

    //------------------------ User Module Resets -----------------------------
    // All the User Modules i.e. FRAME_GEN, FRAME_CHECK and the sync modules
    // are held in reset till the RESETDONE goes high. 
    // The RESETDONE is registered a couple of times on *USRCLK2 and connected 
    // to the reset of the modules
    
    always @(posedge tile0_txusrclk20_i or negedge tile0_resetdone0_i)

    begin
        if (!tile0_resetdone0_i )
        begin
            tile0_rx_resetdone0_r    <=   `DLY 1'b0;
            tile0_rx_resetdone0_r2   <=   `DLY 1'b0;
        end
        else
        begin
            tile0_rx_resetdone0_r    <=   `DLY tile0_resetdone0_i;
            tile0_rx_resetdone0_r2   <=   `DLY tile0_rx_resetdone0_r;
        end
    end
    
    
    always @(posedge tile0_txusrclk20_i or negedge tile0_resetdone0_i)

    begin
        if (!tile0_resetdone0_i )
        begin
            tile0_tx_resetdone0_r    <=   `DLY 1'b0;
            tile0_tx_resetdone0_r2   <=   `DLY 1'b0;
        end
        else
        begin
            tile0_tx_resetdone0_r    <=   `DLY tile0_resetdone0_i;
            tile0_tx_resetdone0_r2   <=   `DLY tile0_tx_resetdone0_r;
        end
    end
    always @(posedge tile0_txusrclk20_i or negedge tile0_resetdone1_i)

    begin
        if (!tile0_resetdone1_i )
        begin
            tile0_rx_resetdone1_r    <=   `DLY 1'b0;
            tile0_rx_resetdone1_r2   <=   `DLY 1'b0;
        end
        else
        begin
            tile0_rx_resetdone1_r    <=   `DLY tile0_resetdone1_i;
            tile0_rx_resetdone1_r2   <=   `DLY tile0_rx_resetdone1_r;
        end
    end
    
    always @(posedge tile0_txusrclk20_i or negedge tile0_resetdone1_i)

    begin
        if (!tile0_resetdone1_i )
        begin
            tile0_tx_resetdone1_r    <=   `DLY 1'b0;
            tile0_tx_resetdone1_r2   <=   `DLY 1'b0;
        end
        else
        begin
            tile0_tx_resetdone1_r    <=   `DLY tile0_resetdone1_i;
            tile0_tx_resetdone1_r2   <=   `DLY tile0_tx_resetdone1_r;
        end
    end
   wire [35:0] CONTROL0;
   wire [35:0] CONTROL1;
   wire [35:0] CONTROL2;
   wire trig0;
   wire trig1;
   wire trig2;
   reg [31:0] gtx_txdata0;
   reg [3:0]  gtx_txdatak0;
   reg [31:0] gtx_rxdata0;
   reg [3:0]  gtx_rxdatak0;
   reg [31:0] gtx_txdata1;
   reg [3:0]  gtx_txdatak1;
   reg [31:0] gtx_rxdata1;
   reg [3:0]  gtx_rxdatak1;
   //************************** OOB0 ****************************
   assign rxdata_fis0        = tile0_rxdata0_i;
   assign rxcharisk0         = tile0_rxcharisk0_i;
   gtx_oob #(.C_CHIPSCOPE(C_CHIPSCOPE))
   gtx_oob_0
     (
      // Outputs
      .CommInit				(CommInit0),
      .link_up				(link_up0),
      .txcomstart			(tile0_txcomstart0_i),
      .txcomtype			(tile0_txcomtype0_i),
      .txelecidle			(tile0_txelecidle0_i),
      .rxreset				(tile0_rxreset0_i),
      .txdata				(tile0_txdata0_i),
      .txdatak				(tile0_txcharisk0_i),
      .txdatak_pop                      (txdatak_pop0),
      .trig_o				(trig0),
      // Inouts
      .CONTROL				(CONTROL0[35:0]),
      // Inputs
      .sys_clk				(tile0_txusrclk20_i),
      .sys_rst				(phyreset0),
      .StartComm			(StartComm0),
      .rxstatus				(tile0_rxstatus0_i[2:0]),
      .rxbyteisaligned			(tile0_rxbyteisaligned0_i),
      .plllkdet				(plllkdet),
      .rxdata				(gtx_rxdata0[31:0]),
      .rxdatak				(gtx_rxdatak0[3:0]),
      .rxelecidle                       (tile0_rxelecidle0_i),
      .tx_sync_done                     (tile0_tx_sync_done0_i),
      .txdata_ll                        (txdata_fis0),
      .txdatak_ll                       (tx_charisk_fis0),
      .gtx_tune                         (gtx_tune0),
      .trig_i				(trig2));
   //************************** OOB1 ****************************
   assign rxdata_fis1        = tile0_rxdata1_i;
   assign rxcharisk1         = tile0_rxcharisk1_i;
   gtx_oob #(.C_CHIPSCOPE(C_CHIPSCOPE))
   gtx_oob_1
     (
      // Outputs
      .CommInit				(CommInit1),
      .link_up				(link_up1),
      .txcomstart			(tile0_txcomstart1_i),
      .txcomtype			(tile0_txcomtype1_i),
      .txelecidle			(tile0_txelecidle1_i),
      .rxreset				(tile0_rxreset1_i),
      .txdata				(tile0_txdata1_i),
      .txdatak				(tile0_txcharisk1_i),
      .txdatak_pop                      (txdatak_pop1),
      .trig_o				(trig1),
      // Inouts
      .CONTROL				(CONTROL1[35:0]),
      // Inputs
      .sys_clk				(tile0_txusrclk20_i),
      .sys_rst				(phyreset1),
      .StartComm			(StartComm1),
      .rxstatus				(tile0_rxstatus1_i[2:0]),
      .rxbyteisaligned			(tile0_rxbyteisaligned1_i),
      .plllkdet				(plllkdet),
      .rxdata				(gtx_rxdata1[31:0]),
      .rxdatak				(gtx_rxdatak1[3:0]),
      .rxelecidle                       (tile0_rxelecidle1_i),
      .tx_sync_done                     (tile0_tx_sync_done1_i),
      .txdata_ll                        (txdata_fis1),
      .txdatak_ll                       (tx_charisk_fis1),      
      .gtx_tune                         (gtx_tune1),
      .trig_i				(trig2));
   assign  tile0_gtxreset_i = GTXRESET_IN;

    // assign resets for frame_gen modules
    assign  tile0_tx_system_reset0_c = !tile0_tx_sync_done0_i;
    assign  tile0_tx_system_reset1_c = !tile0_tx_sync_done1_i;

    // assign resets for frame_check modules
    assign  tile0_rx_system_reset0_c = !tile0_rx_resetdone0_r2;
    assign  tile0_rx_system_reset1_c = !tile0_rx_resetdone1_r2;

    assign  gtxreset_i                      =  tied_to_ground_i;
    assign  user_tx_reset_i                 =  tied_to_ground_i;
    assign  user_rx_reset_i                 =  tied_to_ground_i;

    assign  tile0_loopback0_i               =  gtx_tune0[2:0];
    assign  tile0_txdiffctrl0_i             =  gtx_tune0[5:3];
    assign  tile0_txpreemphasis0_i          =  gtx_tune0[8:6];
    assign  tile0_rxeqmix0_i                =  gtx_tune0[17:16];
    assign  tile0_loopback1_i               =  gtx_tune1[2:0];
    assign  tile0_txdiffctrl1_i             =  gtx_tune1[5:3];
    assign  tile0_txpreemphasis1_i          =  gtx_tune1[8:6];
    assign  tile0_rxeqmix1_i                =  gtx_tune1[17:16];

    assign  tile0_rxenmcommaalign0_i = 1'b1;
    assign  tile0_rxenmcommaalign1_i = 1'b1;
    assign  tile0_rxenpcommaalign0_i = 1'b1;
    assign  tile0_rxenpcommaalign1_i = 1'b1;

   assign refclkout               = tile0_refclkout_i;
   assign plllkdet                = tile0_plllkdet_i;
   assign refclkout_dcm0_locked_i = dcm_locked;
   assign tile0_txusrclk0_i       = txusrclk0;
   assign tile0_txusrclk20_i      = txusrclk20;
   assign tile0_refclk_i          = refclk;

   /* synthesis attribute keep of txusrclk0  is "true" */
   /* synthesis attribute keep of txusrclk20 is "true" */
   always @(posedge tile0_txusrclk20_i)
     begin
	gtx_txdata0  <= #1 tile0_txdata0_i;
	gtx_txdatak0 <= #1 tile0_txcharisk0_i;
	gtx_rxdata0  <= #1 tile0_rxdata0_i;
	gtx_rxdatak0 <= #1 tile0_rxcharisk0_i;

	gtx_txdata1  <= #1 tile0_txdata1_i;
	gtx_txdatak1 <= #1 tile0_txcharisk1_i;
	gtx_rxdata1  <= #1 tile0_rxdata1_i;
	gtx_rxdatak1 <= #1 tile0_rxcharisk1_i;
     end
    /* synthesis attribute keep of gtx_rxdata0 is "true" */
    /* synthesis attribute keep of gtx_rxdatak0 is "true" */
    /* synthesis attribute keep of gtx_rxdata1 is "true" */
    /* synthesis attribute keep of gtx_rxdatak1 is "true" */

   assign oob2dbg0[31:0]  = tile0_txdata0_i;
   assign oob2dbg0[63:32] = tile0_rxdata0_i;
   assign oob2dbg0[67:64] = tile0_txcharisk0_i;
   assign oob2dbg0[71:68] = tile0_rxcharisk0_i;
   assign oob2dbg0[79:72] = encode_prim(tile0_txdata0_i);
   assign oob2dbg0[87:80] = encode_prim(tile0_rxdata0_i);
   assign oob2dbg0[119:88]= phy2cs_data0;
   assign oob2dbg0[120]   = phy2cs_k0;

   assign oob2dbg1[31:0]  = tile0_txdata1_i;
   assign oob2dbg1[63:32] = tile0_rxdata1_i;
   assign oob2dbg1[67:64] = tile0_txcharisk1_i;
   assign oob2dbg1[71:68] = tile0_rxcharisk1_i;
   assign oob2dbg1[79:72] = encode_prim(tile0_txdata1_i);
   assign oob2dbg1[87:80] = encode_prim(tile0_rxdata1_i);
   assign oob2dbg1[119:88]= phy2cs_data1;
   assign oob2dbg1[120]   = phy2cs_k1;
   
     wire [127:0] dbg2;
generate if (C_CHIPSCOPE == 1)
begin
	chipscope_icon3
	icon (.CONTROL0   (CONTROL0[35:0]),
	      .CONTROL1   (CONTROL1[35:0]),
	      .CONTROL2   (CONTROL2[35:0]));
	chipscope_ila_128x1
	dbX2 (.TRIG_OUT (trig2),
	      .CONTROL  (CONTROL2[35:0]),
	      .CLK      (phyclk0),
	      .TRIG0    (dbg2));
        assign dbg2[127] = trig0;
	assign dbg2[126] = trig1;
	assign dbg2[31:0]= tile0_txdata0_i;
	assign dbg2[63:32]=tile0_rxdata0_i;
	assign dbg2[71:64]=tile0_txcharisk0_i;
	assign dbg2[79:72]=tile0_rxcharisk0_i;
	assign dbg2[87:80]=4'h0;
	assign dbg2[111:88]=phy2cs_data0;
	assign dbg2[120]   =phy2cs_k0;
end
endgenerate

endmodule

module chipscope_icon3 (
CONTROL0, CONTROL1, CONTROL2
)/* synthesis syn_black_box syn_noprune=1 */;
  inout [35 : 0] CONTROL0;
  inout [35 : 0] CONTROL1;
  inout [35 : 0] CONTROL2;
 
endmodule

module chipscope_ila_128x1 (
  CLK, TRIG_OUT, CONTROL, TRIG0
)/* synthesis syn_black_box syn_noprune=1 */;
  input CLK;
  output TRIG_OUT;
  inout [35 : 0] CONTROL;
  input [127 : 0] TRIG0;
 
endmodule
