module oob_device(/*AUTOARG*/
   // Outputs
   txcomstart, txcomtype, txelecidle, tx_charisk, rxreset, linkup,
   txdata_out,
   // Inputs
   clk, rst_n, gtp_locked, rxstatus, rxelecidle, rxbyteisaligned,
   rxdata_in, rx_charisk
   );

   input              clk;
   input              rst_n;
   input              gtp_locked;

   input [2:0]        rxstatus;
   input              rxelecidle;
   input              rxbyteisaligned;

   output reg         txcomstart;
   output reg         txcomtype;
   output reg         txelecidle;
   output reg         tx_charisk;
   output reg         rxreset;

   output reg         linkup;
   
   output reg [15:0]  txdata_out;

   input [15:0]       rxdata_in; 
   input [1:0]        rx_charisk;

   parameter [3:0] // synopsys enum state_info
		S_IDLE             = 4'h8,
		S_DR_Reset         = 4'h0,
		S_DR_COMINIT       = 4'h1,
		S_DR_AwaitCOMWAKE  = 4'h2,
		S_DR_AwaitNoCOMWAKE= 4'h3,
		S_DR_Calibrate     = 4'h4,
		S_DR_COMWAKE       = 4'h5,
		S_DR_SendAlign     = 4'h6,
		S_DR_Ready         = 4'h7;
   reg [17:0] count;
   reg        count_en;
   reg [3:0]  // synopsys enum state_info
	      state;

   wire       rrdy_det;
   wire       d10_2_det;
   wire       align_det;
   wire       sync_det;
   reg        send_align;
   reg        send_sync;
   reg        align_cnt;

   always @(posedge clk or negedge rst_n)
     begin
	if(~rst_n)
	  begin
             state      <= S_IDLE;
             count_en   <= 0;
             txcomstart <= 0;
             txcomtype  <= 0;
             txelecidle <= 1;
             send_align <= 0;
             send_sync  <= 0;
             rxreset    <= 0; 
	  end
	else if(gtp_locked)
          begin
             case (state)
	       S_IDLE:
		 begin
		    txelecidle <= 1;
                    txcomstart <= 0;
		    if (rxstatus[2])
		      begin
			 state = S_DR_Reset;
		      end		    
		 end
	       S_DR_Reset:
                 begin
		    txelecidle <= 1;
                    txcomstart <= 0;
                    if (rxstatus[2]) // comreset detect
                      begin
			 state <= S_DR_Reset;
                      end 
                    else 
                      begin
                         state <= S_DR_COMINIT;
                      end
                 end
	       S_DR_COMINIT:
                 begin 
                    txcomstart <= 1;
                    txcomtype  <= 0;
		    count_en   <= 1;
		    if (count == 18'h100)
		      begin
			 state <= S_DR_AwaitCOMWAKE;
			 count_en <= 0;			 
		      end
                 end
	       S_DR_AwaitCOMWAKE:
                 begin
                    txcomstart <= 0;
                    txcomtype  <= 0;
		    count_en   <= 1;
		    if (rxstatus[1]) // comwake detect
		      begin
			 state <= S_DR_AwaitNoCOMWAKE;
			 count_en   <= 0;			 			 
		      end
		    else if (count == 18'h800)
		      begin
			 state <= S_DR_Reset;
			 count_en   <= 0;			 			 
		      end
		 end // case: S_DR_AwaitCOMMAKE
	       S_DR_AwaitNoCOMWAKE:
		 begin
		    count_en   <= 0;			 			 		    
		    if (~rxstatus[1])
		      begin
			 state <= S_DR_Calibrate;
		      end
		 end
	       S_DR_Calibrate:
		 begin
		    count_en   <= 0;			 			 		    
		    state      <= S_DR_COMWAKE;
		 end
	       S_DR_COMWAKE:
		 begin
		    txelecidle <= 1'b1;
		    txcomtype  <= 1'b1;
		    txcomstart <= 1'b1;
		    count_en   <= 1'b1;
		    if (count == 18'h100)
		      begin
			 count_en   <= 0;			 			 			 
			 state      <= S_DR_SendAlign;
                         rxreset    <= 1; 
		      end
		 end
	       S_DR_SendAlign:
		 begin
		    txelecidle <= 1'b0;
		    txcomstart <= 1'b0;
		    send_align <= 1'b1;
		    count_en   <= 1'b1;
		    if (align_det && count == 18'h200)
		      begin
			 state <= S_DR_Ready;
		         count_en   <= 1'b0;
		      end
		 end
	       S_DR_Ready:
		 begin
		    send_sync  <= rxelecidle ? 1'b1 : 1'b0;
		    state      <= rxelecidle ? S_IDLE : S_DR_Ready;
		 end
             endcase
          end
     end
   always @(posedge clk)
     if (state == S_DR_Ready)
       linkup <= 1;
     else
       linkup <= 0;
   
   always @(posedge clk or negedge rst_n)
     begin 
	if (!rst_n)
	  begin
	     count = 18'b0;
	  end	
	else if (count_en)
	  begin  
	     count = count + 1;
	  end
     	else
     	  begin
	     count = 18'b0;
	  end
     end

   reg [15:0] rxdatar1;

   always@(posedge clk or negedge rst_n)
     begin 
	if (~rst_n)
	  begin
	     rxdatar1 <= 16'b0;						
	  end	
	else 
	  begin 
	     rxdatar1 <= rxdata_in;
	  end
     end

   assign align_det = (rx_charisk == 2'b01 && rxdata_in == 16'h4ABC && rxdatar1 == 16'h7B4A) ?
		      1'b1 : ((rx_charisk == 2'b10 && rxdata_in == 16'hBC7B && rxdatar1 == 16'h4A4A)? 1'b1:1'b0);
   assign sync_det =  (rx_charisk == 2'b01 && rxdatar1 == 16'hB5B5 && rxdata_in == 16'h957C) ?
		      1'b1 : ((rx_charisk == 2'b10 && rxdata_in == 16'h7CB5 && rxdatar1 == 16'hB595)? 1'b1:1'b0);
   assign rrdy_det  = (rx_charisk == 2'b01 && rxdata_in == 16'h957C && rxdatar1 == 16'h4A4A) ?
		      1'b1 : ((rx_charisk == 2'b10 && rxdata_in == 16'h7C4A && rxdatar1 == 16'h4A95)? 1'b1:1'b0);
   assign d10_2_det = (rxdata_in == 16'h4a4a) && (rxdatar1 == 16'h4a4a) ;//&& rxbyteisaligned;
  
   always @(posedge clk or negedge rst_n)
     begin
        if(~rst_n)
          begin
             txdata_out <= 0;
             align_cnt  <= 0; 
          end
        else if(send_align)
          begin
             if(~align_cnt)
               begin
                  txdata_out <= 16'h4ABC;
                  tx_charisk <= 1'b1;
                  align_cnt <= align_cnt + 1'b1;
               end
             else
               begin
                  txdata_out <= 16'h7B4A;
                  tx_charisk <= 1'b0;
                  align_cnt <= align_cnt + 1'b1;
               end
          end
        else if(send_sync)
          begin
             if(~align_cnt)
               begin
                  txdata_out <= 16'h957C;
                  tx_charisk <= 1'b1;
                  align_cnt <= align_cnt + 1'b1;
               end
             else
               begin
                  txdata_out <= 16'hB5B5;
                  tx_charisk <= 1'b0;
                  align_cnt <= align_cnt + 1'b1;
               end
          end
        else if(linkup)
          begin
             if(~align_cnt)
               begin
                  txdata_out <= 16'h957C;
                  tx_charisk <= 1'b1;
                  align_cnt <= align_cnt + 1'b1;
               end
             else 
               begin
                  txdata_out <= 16'h4A4A;
                  tx_charisk <= 1'b0;
                  align_cnt   <= align_cnt + 1'b1;
               end
          end
     end

   /*AUTOASCIIENUM("state", "state_ascii", "S_")*/
   // Beginning of automatic ASCII enum decoding
   reg [135:0]		state_ascii;		// Decode of state
   always @(state) begin
      case ({state})
	S_IDLE:              state_ascii = "idle             ";
	S_DR_Reset:          state_ascii = "dr_reset         ";
	S_DR_COMINIT:        state_ascii = "dr_cominit       ";
	S_DR_AwaitCOMWAKE:   state_ascii = "dr_awaitcomwake  ";
	S_DR_AwaitNoCOMWAKE: state_ascii = "dr_awaitnocomwake";
	S_DR_Calibrate:      state_ascii = "dr_calibrate     ";
	S_DR_COMWAKE:        state_ascii = "dr_comwake       ";
	S_DR_SendAlign:      state_ascii = "dr_sendalign     ";
	S_DR_Ready:          state_ascii = "dr_ready         ";
	default:             state_ascii = "%Error           ";
      endcase
   end
   // End of automatics
endmodule  
