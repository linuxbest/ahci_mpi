`timescale 1ns / 1ps

module device_sim(/*AUTOARG*/
   // Outputs
   TXN_OUT0, TXP_OUT0,
   // Inputs
   RXN_IN0, RXP_IN0
   );

   localparam real SATA_DEVICE_PER = 1000.0/300; // 300Mhz
   localparam real GTP_CLK_REF     = 1000.0/150; // 150Mhz
   
   output 	   TXN_OUT0;
   output 	   TXP_OUT0;
   input 	   RXN_IN0;
   input 	   RXP_IN0;
   
   reg 		   sata_clk_p;
   wire 	   sata_clk_n;
   reg 		   rst_n;
   initial begin
      sata_clk_p = 1'b0;
      #(GTP_CLK_REF/2);
      forever #(GTP_CLK_REF/2) sata_clk_p = ~sata_clk_p;
   end
   assign sata_clk_n = ~sata_clk_p;

   initial begin
      rst_n = 1'b0;
      #200;
      rst_n = 1'b1;
   end
   
   wire 	dev_rx_charisk;
   wire 	dev_clk_150M;	
   wire 	dev_link_up;	
   wire 	dev_tx_charisk;	
   wire [31:0] 	dev_tx_data;	
   wire 	phy_clk;	// unused 
   wire 	phy_rst_n;	// unused
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			dev_clk_75M;		// From shdd_model_phy of shdd_model_phy.v
   wire [31:0]		dev_rx_data;		// From u_phy_if of phy_if_gtp.v
   wire [1:0]		rx_charisk;		// From shdd_model_phy of shdd_model_phy.v
   wire [15:0]		rx_data_phy;		// From shdd_model_phy of shdd_model_phy.v
   wire			tx_charisk;		// From u_phy_if of phy_if_gtp.v
   wire [15:0]		tx_data_phy;		// From u_phy_if of phy_if_gtp.v
   // End of automatics

   wire 		sata_dcm_lock;
   assign sata_dcm_lock = 1'b1;
   
   dev_fsm
     dev_fsm(
	     .link_up			(dev_link_up),
	     /*AUTOINST*/
	     // Outputs
	     .dev_tx_data		(dev_tx_data[31:0]),
	     .dev_tx_charisk		(dev_tx_charisk),
	     .phy_rst_n			(phy_rst_n),
	     // Inputs
	     .dev_clk_75M		(dev_clk_75M),
	     .dev_rx_data		(dev_rx_data[31:0]),
	     .dev_rx_charisk		(dev_rx_charisk),
	     .sata_dcm_lock		(sata_dcm_lock));
   phy_if_gtp
     u_phy_if(
	      .link_up			(dev_link_up),
	      .clk			(dev_clk_75M),
	      .clk_2x			(dev_clk_150M),
	      .host_rst_n		(rst_n),
	      .dev_tx_data		(dev_tx_data[31:0]),
	      .tx_k			(dev_tx_charisk),
	      .rx_k			(dev_rx_charisk),
	      /*AUTOINST*/
	      // Outputs
	      .dev_rx_data		(dev_rx_data[31:0]),
	      .tx_data_phy		(tx_data_phy[15:0]),
	      .tx_charisk		(tx_charisk),
	      // Inputs
	      .rx_data_phy		(rx_data_phy[15:0]),
	      .rx_charisk		(rx_charisk[1:0])); 

   shdd_model_phy 
     shdd_model_phy(.rst_n(rst_n),
		    /*AUTOINST*/
		    // Outputs
		    .TXN_OUT0		(TXN_OUT0),
		    .TXP_OUT0		(TXP_OUT0),
		    .rx_data_phy	(rx_data_phy[15:0]),
		    .rx_charisk		(rx_charisk[1:0]),
		    .phy_clk		(phy_clk),
		    .dev_clk_75M	(dev_clk_75M),
		    .dev_clk_150M	(dev_clk_150M),
		    .dev_link_up	(dev_link_up),
		    // Inputs
		    .RXN_IN0		(RXN_IN0),
		    .RXP_IN0		(RXP_IN0),
		    .sata_clk_n		(sata_clk_n),
		    .sata_clk_p		(sata_clk_p),
		    .tx_data_phy	(tx_data_phy[15:0]),
		    .tx_charisk		(tx_charisk));
endmodule
// Local Variables:
// verilog-library-directories:("." "../pcores/trn_v1_00_a/hdl/verilog" "../pcores/satagtx_v1_00_a/hdl/verilog/" "./sata_device")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:
