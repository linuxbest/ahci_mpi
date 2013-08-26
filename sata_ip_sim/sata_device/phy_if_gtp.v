module phy_if_gtp (/*AUTOARG*/
   // Outputs
   dev_rx_data, rx_k, tx_data_phy, tx_charisk,
   // Inputs
   clk, clk_2x, host_rst_n, dev_tx_data, link_up, tx_k, rx_data_phy,
   rx_charisk
   );
   //phy if system signal
   input 		 clk;             //75M
   input 		 clk_2x;          //150M
   input 		 host_rst_n;

   //32 bit and 75M clock domain
   input [31:0] 	 dev_tx_data;
   output [31:0] 	 dev_rx_data;
   input 		 link_up;
   output 		 rx_k;
   input 		 tx_k;

   //16 bit and 150M clock domain
   input [15:0] 	 rx_data_phy;
   input [1:0] 		 rx_charisk;
   output [15:0] 	 tx_data_phy;
   output 		 tx_charisk;

   reg [15:0] 		 tx_data_phy;
   reg 			 tx_charisk;
   reg 			 phy_sync_01;
   reg 			 phy_sync_10;
   reg [6:0] 		 phy_wait_cnt;
   reg 			 phy_if_wait_done;
   reg 			 rx_fifo_wr_en;
   reg [32:0] 		 rx_phy_data_fifo_in;
   reg [7:0] 		 rx_link_data_tmp;
   reg 			 rx_dword_01_0011;
   reg 			 rx_dword_10_1001;
   reg 			 rx_k_phy_01;   
   reg 			 rx_k_phy_10;
   reg 			 tx_dword;
   reg 			 tx_fifo_rd_en;

   wire [2:0] 		 phy_rd_addr;
   wire [2:0] 		 phy_wr_addr;
   wire 		 phy_wallow;
   wire [2:0] 		 link_rd_addr;
   wire [2:0] 		 link_wr_addr;
   wire 		 link_wallow;
   wire [32:0] 		 rx_data_fifo_out;
   wire [32:0] 		 tx_link_data_fifo_out;
   
   always @(posedge clk_2x)          //
     if(~host_rst_n)
       begin
          phy_sync_01   <= 0;
          phy_sync_10   <= 0;
          rx_fifo_wr_en <= 0;
          rx_k_phy_01   <= 0;
          rx_k_phy_10   <= 0;
          rx_dword_01_0011          <= 0;
          rx_dword_10_1001          <= 0;
          rx_link_data_tmp          <= 0;
          rx_phy_data_fifo_in       <= 0;
       end
     else if(~link_up)
       begin
          phy_sync_01      <= 0;
          phy_sync_10      <= 0;
          rx_fifo_wr_en    <= 0;           
          rx_dword_01_0011          <= 0;
          rx_dword_10_1001          <= 0;
          rx_link_data_tmp          <= 0;
       end
     else if (((rx_charisk == 2'b01) | phy_sync_01) && ~rx_dword_01_0011 ) 
       begin
          phy_sync_01               <= 1;
          rx_fifo_wr_en             <= 0;
          rx_phy_data_fifo_in[15:0] <= rx_data_phy[15:0];
          rx_dword_01_0011          <= 1;
          if(rx_charisk == 2'b01)
            begin
               rx_k_phy_01                  <= 1;
            end
          else 
            begin
               rx_k_phy_01                  <= 0;
            end
       end
     else if(rx_dword_01_0011)
       begin
          rx_fifo_wr_en             <= 1;
          rx_dword_01_0011          <= 0;
          rx_phy_data_fifo_in[32]   <= rx_k_phy_01;
          rx_phy_data_fifo_in[31:16]<= rx_data_phy[15:0]; 
       end
     else if(((rx_charisk == 2'b10) | phy_sync_10) && ~rx_dword_10_1001)
       begin
          phy_sync_10               <= 1;
          rx_dword_10_1001          <= 1;
          rx_fifo_wr_en             <= 1;
          rx_phy_data_fifo_in[7:0]  <= rx_link_data_tmp[7:0];
          rx_phy_data_fifo_in[31:24]<= rx_data_phy[7:0];
          rx_link_data_tmp[7:0]     <= rx_data_phy[15:8];
          rx_phy_data_fifo_in[32]   <= rx_k_phy_10;          
          if(rx_charisk == 2'b10)
            begin
               rx_k_phy_10          <= 1;
            end
          else 
            begin
               rx_k_phy_10          <= 0;
            end
       end
     else if(rx_dword_10_1001)
       begin
          rx_phy_data_fifo_in[23:8]<= rx_data_phy[15:0];
          rx_fifo_wr_en             <= 0;
          rx_dword_10_1001          <= 0;
       end
   assign dev_rx_data[31:0] = rx_data_fifo_out[31:0];
   assign rx_k               = rx_data_fifo_out[32];
   
   always @(posedge clk_2x)
     if(~host_rst_n)
       begin
          tx_dword     <= 0;
          tx_data_phy  <= 16'h7B4A;
          tx_charisk   <= 0;
          tx_fifo_rd_en <= 0;
       end
     else if(~link_up) 
       begin
          tx_dword     <= 0;
          tx_data_phy  <= 16'h7B4A;
          tx_charisk   <= 0;
          tx_fifo_rd_en <= 0;
       end
     else if(~tx_dword)
       begin
          tx_data_phy <= tx_link_data_fifo_out[15:0];
          tx_dword    <= 1;
          tx_fifo_rd_en <= 1;
          tx_charisk    <= tx_link_data_fifo_out[32];
       end
     else if(tx_dword)
       begin
          tx_data_phy <= tx_link_data_fifo_out[31:16];
          tx_dword    <= 0;
          tx_charisk  <= 0;
          tx_fifo_rd_en <= 0;
       end
   
   fifo_control #(.ADDR_LENGTH(8'h03)) 
   phy_to_link_control     //rx fifo 
     (.rclock_in(clk),
      .wclock_in(clk_2x),
      .renable_in(1'b1),
      .wenable_in(rx_fifo_wr_en),
      .reset_in(~host_rst_n),
      .clear_in(~host_rst_n),
      .almost_empty_out(),
      .almost_full_out(),
      .empty_out(),
      .waddr_out(phy_wr_addr),
      .raddr_out(phy_rd_addr),
      .rallow_out(),
      .wallow_out(phy_wallow),
      .full_out(),
      .half_full_out());
   
   tpram  #(.aw(8'h03),.dw(8'h21))
   phy_to_link_ram 
     (.clk_a(clk_2x),
      .rst_a(~host_rst_n),
      .ce_a(1'b1),
      .oe_a(1'b1),
      .we_a(phy_wallow),
      .addr_a(phy_wr_addr),
      .di_a(rx_phy_data_fifo_in[32:0]),
      .do_a(),

      .clk_b(clk),
      .rst_b(~host_rst_n),
      .ce_b(1'b1),
      .oe_b(1'b1),
      .we_b(1'b0),
      .addr_b(phy_rd_addr),
      .di_b(),
      .do_b(rx_data_fifo_out[32:0]));
   
   fifo_control #(.ADDR_LENGTH(8'h03)) 
   link_to_phy_control      //tx fifo
     (.rclock_in(clk_2x),
      .wclock_in(clk),
      .renable_in(tx_fifo_rd_en),
      .wenable_in(1'b1),
      .reset_in(~host_rst_n),
      .clear_in(~host_rst_n),
      .almost_empty_out(),
      .almost_full_out(),
      .empty_out(),
      .waddr_out(link_wr_addr),
      .raddr_out(link_rd_addr),
      .rallow_out(),
      .wallow_out(link_wallow),
      .full_out(),
      .half_full_out());
   
   tpram  #(.aw(8'h03),.dw(8'h21))
   link_to_phy_ram 
     (.clk_a(clk),
      .rst_a(~host_rst_n),
      .ce_a(1'b1),
      .oe_a(1'b1),
      .we_a(link_wallow),
      .addr_a(link_wr_addr),
      .di_a({tx_k,dev_tx_data[31:0]}),
      .do_a(),

      .clk_b(clk_2x),
      .rst_b(~host_rst_n),
      .ce_b(1'b1),
      .oe_b(1'b1),
      .we_b(1'b0),
      .addr_b(link_rd_addr),
      .di_b(),
      .do_b(tx_link_data_fifo_out[32:0]));
endmodule 
