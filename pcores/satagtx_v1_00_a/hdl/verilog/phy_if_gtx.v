module phy_if_gtx(/*AUTOARG*/
   // Outputs
   phy2cs_data, phy2cs_k, txdata_fis, tx_charisk_fis,
   // Inputs
   clk_75m, host_rst, cs2phy_data, link_up, fsm2phy_k, rxdata_fis,
   rxcharisk
   );
   //phy if system signal
   input 		 clk_75m;             //75M
   input 		 host_rst;

   //32 bit and 75M clock domain
   input [31:0] 	 cs2phy_data;
   output reg [31:0] 	 phy2cs_data;
   input 		 link_up;
   output reg		 phy2cs_k;
   input 		 fsm2phy_k;

   //32 bit and 75M clock domain
   input  [31:0] 	 rxdata_fis;
   input  [3:0] 	 rxcharisk;
   output [31:0] 	 txdata_fis;
   output 		 tx_charisk_fis;
   
   reg    [31:0]         rx_data_link_tmp;
   reg                   phy_sync_0001;  
   reg                   phy_sync_0010;
   reg                   phy_sync_0100;
   reg                   phy_sync_1000;

   assign txdata_fis = cs2phy_data;
   assign tx_charisk_fis  = fsm2phy_k;

   always @(posedge clk_75m)
     if(host_rst)
       begin
          phy2cs_data <= 32'hb5b5_957c;
          phy_sync_0001 <= 0;
          phy_sync_0010 <= 0;
          phy_sync_0100 <= 0;
          phy_sync_1000 <= 0;
          rx_data_link_tmp <= 0;
       end
     else if(~link_up)
       begin
          phy2cs_data <= 32'hb5b5_957c;
          phy_sync_0001 <= 0;
          phy_sync_0010 <= 0;
          phy_sync_0100 <= 0;
          phy_sync_1000 <= 0;
          rx_data_link_tmp <= 0;
       end
     else 
       begin
          if(rxcharisk == 4'b0001 | phy_sync_0001)
            begin
               phy2cs_data  <= rxdata_fis;
               phy_sync_0001 <= 1;
            end
          else if(rxcharisk == 4'b0010 | phy_sync_0010)
            begin
               rx_data_link_tmp <= rxdata_fis;
               phy2cs_data     <= {rxdata_fis[7:0],rx_data_link_tmp[31:8]};
               phy_sync_0010    <= 1;
            end
          else if(rxcharisk == 4'b0100 | phy_sync_0100)
            begin
               rx_data_link_tmp <= rxdata_fis;
               phy2cs_data     <= {rxdata_fis[15:0],rx_data_link_tmp[31:16]};
               phy_sync_0100    <= 1;
            end
          else if(rxcharisk == 4'b1000 | phy_sync_1000)
            begin
               rx_data_link_tmp <= rxdata_fis;
               phy2cs_data     <= {rxdata_fis[23:0],rx_data_link_tmp[31:24]};
               phy_sync_1000    <= 1;
            end
       end
   
   reg rx_k_tmp;
   
   always @(posedge clk_75m)    //for lost primitive 3737b57c
     if(~link_up)
       begin
          rx_k_tmp <= 0;
       end                
     else if(rxcharisk[1] | rxcharisk[2] | rxcharisk[3]) 
       begin
          rx_k_tmp <= 1;
       end
     else 
       begin
          rx_k_tmp <= 0;
       end

   always @(posedge clk_75m) 
     if(~link_up)
       begin
          phy2cs_k    <= 0;
       end
     else if(rxcharisk[0])
       begin
          phy2cs_k    <= 1;
       end
     else 
       begin
          phy2cs_k    <= rx_k_tmp;
       end

endmodule 
