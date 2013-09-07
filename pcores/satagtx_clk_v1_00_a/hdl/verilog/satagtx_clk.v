// satagtx_clk.v --- 
// 
// Filename: satagtx_clk.v
// Description: 
// Author: Hu Gang
// Maintainer: 
// Created: Sat Oct 16 15:52:09 2010 (+0800)
// Version: 
// Last-Updated: 
//           By: 
//     Update #: 0
// URL: 
// Keywords: 
// Compatibility: 
// 
// 

// Commentary: 
// 
// 
// 
// 

// Change log:
// 
// 
// 

// Copyright (C) 2008,2009 Beijing Soul tech.
// -------------------------------------
// Naming Conventions:
// 	active low signals                 : "*_n"
// 	clock signals                      : "clk", "clk_div#", "clk_#x"
// 	reset signals                      : "rst", "rst_n"
// 	generics                           : "C_*"
// 	user defined types                 : "*_TYPE"
// 	state machine next state           : "*_ns"
// 	state machine current state        : "*_cs"
// 	combinatorial signals              : "*_com"
// 	pipelined or register delay signals: "*_d#"
// 	counter signals                    : "*cnt*"
// 	clock enable signals               : "*_ce"
// 	internal version of output port    : "*"
// 	device pins                        : "*_pin"
// 	ports                              : - Names begin with Uppercase
// Code:
module satagtx_clk (/*AUTOARG*/
   // Outputs
   tile0_refclk, refclkout_dcm0_locked, tile0_txusrclk0,
   tile0_txusrclk20,
   // Inputs
   TILE0_REFCLK_PAD_P_IN, TILE0_REFCLK_PAD_N_IN, tile0_refclkout,
   tile0_plllkdet, tile0_gtpclkfb
   );
   parameter C_FAMILY = "virtex5";
   parameter C_SATA_SPEED = 1;
   
   input TILE0_REFCLK_PAD_P_IN;
   input TILE0_REFCLK_PAD_N_IN;
   output tile0_refclk;

   input tile0_refclkout;
   input tile0_plllkdet;
   input tile0_gtpclkfb;
   
   output refclkout_dcm0_locked;
   output tile0_txusrclk0;
   output tile0_txusrclk20;
   
    //---------------------Dedicated GTX Reference Clock Inputs ---------------
    // The dedicated reference clock inputs you selected in the GUI are implemented using
    // IBUFDS instances.
    //
    // In the UCF file for this example design, you will see that each of
    // these IBUFDS instances has been LOCed to a particular set of pins. By LOCing to these
    // locations, we tell the tools to use the dedicated input buffers to the GTX reference
    // clock network, rather than general purpose IOs. To select other pins, consult the 
    // Implementation chapter of UG196, or rerun the wizard.
    //
    // This network is the highest performace (lowest jitter) option for providing clocks
    // to the GTX transceivers.
    
    IBUFDS tile0_refclkbufds
    (
        .O                              (tile0_refclk), 
        .I                              (TILE0_REFCLK_PAD_P_IN),
        .IB                             (TILE0_REFCLK_PAD_N_IN)
    );

    //--------------------------------- User Clocks ---------------------------
    
    // The clock resources in this section were added based on userclk source selections on
    // the Latency, Buffering, and Clocking page of the GUI. A few notes about user clocks:
    // * The userclk and userclk2 for each GTX datapath (TX and RX) must be phase aligned to 
    //   avoid data errors in the fabric interface whenever the datapath is wider than 10 bits
    // * To minimize clock resources, you can share clocks between GTXs. GTXs using the same frequency
    //   or multiples of the same frequency can be accomadated using DCMs and PLLs. Use caution when
    //   using RXRECCLK as a clock source, however - these clocks can typically only be shared if all
    //   the channels using the clock are receiving data from TX channels that share a reference clock 
    //   source with each other.

    assign  refclkout_dcm0_reset          =  !tile0_plllkdet;

    wire tile0_refclkout_to_dcm;
generate
if (C_FAMILY == "virtex5")
begin
    BUFG refclkout_dcm0_bufg
    (
        .I                              (tile0_refclkout),
        .O                              (tile0_refclkout_to_dcm)
    );
    MGT_USRCLK_SOURCE_GTX #
    (
        .FREQUENCY_MODE                 ("HIGH"),
        .PERFORMANCE_MODE               ("MAX_SPEED")
    )
    refclkout_dcm0
    (
        .DIV1_OUT                       (tile0_txusrclk0),
        .DIV2_OUT                       (tile0_txusrclk20),
        .DCM_LOCKED_OUT                 (refclkout_dcm0_locked),
        .CLK_IN                         (tile0_refclkout_to_dcm),
        .DCM_RESET_IN                   (refclkout_dcm0_reset)
    );
end
if (C_FAMILY == "spartan6")
begin
    wire pll0_fb_in;
    wire pll0_fb_out;
    BUFIO2   #
    (
	    .DIVIDE_BYPASS("TRUE"), 
	    .DIVIDE(1)
    )
    pll0_bufg0 
    (
	    .I           (tile0_refclkout),
	    .DIVCLK      (tile0_refclkout_to_dcm),
	    .IOCLK       (),
	    .SERDESSTROBE()
    );
    BUFIO2FB #
    (
	    .DIVIDE_BYPASS("TRUE")
    )
    pll0_bufg1 
    (
	    .I(tile0_gtpclkfb), 
	    .O(pll0_fb_in)
    );
    MGT_USRCLK_SOURCE_PLL #
    (
	 .MULT                          (C_SATA_SPEED == 2 ? 2 : 4),
	 .DIVIDE                        (C_SATA_SPEED == 2 ? 2 : 4),
	 .FEEDBACK                      ("CLKOUT0"),
	 .CLK_PERIOD                    (C_SATA_SPEED == 2 ? 3.333 : 6.667),
	 .OUT0_DIVIDE                   (C_SATA_SPEED == 2 ? 2 : 4),
	 .OUT1_DIVIDE                   (C_SATA_SPEED == 2 ? 8 : 16),
	 .OUT2_DIVIDE                   (1),
	 .OUT3_DIVIDE                   (1)
    )
    gtpclkout0_0_pll0
    (
	 .CLK0_OUT                      (tile0_txusrclk0),
	 .CLK1_OUT                      (tile0_txusrclk20),
	 .CLK2_OUT                      (),
	 .CLK3_OUT                      (),
	 .CLK_IN                        (tile0_refclkout_to_dcm),
	 .CLKFB_IN                      (pll0_fb_in),
	 .CLKFB_OUT                     (pll0_fb_out),
	 .PLL_LOCKED_OUT                (refclkout_dcm0_locked),
	 .PLL_RESET_IN                  (refclkout_dcm0_reset)
    );
end
endgenerate

    /* synthesis attribute keep of tile0_txusrclk0  is "true" */
    /* synthesis attribute keep of tile0_txusrclk20 is "true" */
    /* synthesis attribute keep of tile0_refclk     is "true" */
endmodule
// 
// satagtx_clk.v ends here
