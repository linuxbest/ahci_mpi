module crc (/*AUTOARG*/
   // Outputs
   crc_out,
   // Inputs
   clk_75m, crc_rst, data_in, data_valid
   );
   // system signal
   input clk_75m;
   input crc_rst;

   // CRC comput signal
   input [31:0] data_in;
   input data_valid;
   output [31:0] crc_out;

   reg 		crc_valid;
   wire [31:0] 	new_bit;
   wire [31:0] 	crc_bit;
   reg  [31:0]	crc_out;

   always @(posedge clk_75m)
     begin
	if(crc_rst) 
          crc_out <= 32'h52325032;
	else if(data_valid)
          begin
             crc_out <= new_bit;
          end
     end   

   assign crc_bit = data_in ^ crc_out ; 

   assign new_bit[31] = crc_bit[31] ^ crc_bit[30] ^ crc_bit[29] ^
			crc_bit[28] ^ crc_bit[27] ^ crc_bit[25] ^
			crc_bit[24] ^ crc_bit[23] ^ crc_bit[15] ^
			crc_bit[11] ^ crc_bit[9]  ^ crc_bit[8]  ^ crc_bit[5];
   assign new_bit[30] = crc_bit[30] ^ crc_bit[29] ^ crc_bit[28] ^
			crc_bit[27] ^ crc_bit[26] ^ crc_bit[24] ^
			crc_bit[23] ^ crc_bit[22] ^ crc_bit[14] ^
			crc_bit[10] ^ crc_bit[8]  ^ crc_bit[7]  ^ crc_bit[4];
   assign new_bit[29] = crc_bit[31] ^ crc_bit[29] ^ crc_bit[28] ^
			crc_bit[27] ^ crc_bit[26] ^ crc_bit[25] ^
			crc_bit[23] ^ crc_bit[22] ^ crc_bit[21] ^
			crc_bit[13] ^ crc_bit[9]  ^ crc_bit[7]  ^
			crc_bit[6]  ^ crc_bit[3];
   assign new_bit[28] = crc_bit[30] ^ crc_bit[28] ^ crc_bit[27] ^
			crc_bit[26] ^ crc_bit[25] ^ crc_bit[24] ^
			crc_bit[22] ^ crc_bit[21] ^ crc_bit[20] ^
			crc_bit[12] ^ crc_bit[8]  ^ crc_bit[6]  ^
			crc_bit[5]  ^ crc_bit[2];
   assign new_bit[27] = crc_bit[29] ^ crc_bit[27] ^ crc_bit[26] ^
			crc_bit[25] ^ crc_bit[24] ^ crc_bit[23] ^
			crc_bit[21] ^ crc_bit[20] ^ crc_bit[19] ^
			crc_bit[11] ^ crc_bit[7]  ^ crc_bit[5]  ^
			crc_bit[4]  ^ crc_bit[1];
   assign new_bit[26] = crc_bit[31] ^ crc_bit[28] ^ crc_bit[26] ^
			crc_bit[25] ^ crc_bit[24] ^ crc_bit[23] ^
			crc_bit[22] ^ crc_bit[20] ^ crc_bit[19] ^
			crc_bit[18] ^ crc_bit[10] ^ crc_bit[6]  ^
			crc_bit[4]  ^ crc_bit[3]  ^ crc_bit[0];
   assign new_bit[25] = crc_bit[31] ^ crc_bit[29] ^ crc_bit[28] ^
			crc_bit[22] ^ crc_bit[21] ^ crc_bit[19] ^
			crc_bit[18] ^ crc_bit[17] ^ crc_bit[15] ^
			crc_bit[11] ^ crc_bit[8]  ^ crc_bit[3]  ^ crc_bit[2];
   assign new_bit[24] = crc_bit[30] ^ crc_bit[28] ^ crc_bit[27] ^
			crc_bit[21] ^ crc_bit[20] ^ crc_bit[18] ^
			crc_bit[17] ^ crc_bit[16] ^ crc_bit[14] ^
			crc_bit[10] ^ crc_bit[7]  ^ crc_bit[2]  ^ crc_bit[1];
   assign new_bit[23] = crc_bit[31] ^ crc_bit[29] ^ crc_bit[27] ^
			crc_bit[26] ^ crc_bit[20] ^ crc_bit[19] ^
			crc_bit[17] ^ crc_bit[16] ^ crc_bit[15] ^
			crc_bit[13] ^ crc_bit[9]  ^ crc_bit[6]  ^
			crc_bit[1]  ^ crc_bit[0];
   assign new_bit[22] = crc_bit[31] ^ crc_bit[29] ^ crc_bit[27] ^
			crc_bit[26] ^ crc_bit[24] ^ crc_bit[23] ^
			crc_bit[19] ^ crc_bit[18] ^ crc_bit[16] ^
			crc_bit[14] ^ crc_bit[12] ^ crc_bit[11] ^
			crc_bit[9]  ^ crc_bit[0];
   assign new_bit[21] = crc_bit[31] ^ crc_bit[29] ^ crc_bit[27] ^
			crc_bit[26] ^ crc_bit[24] ^ crc_bit[22] ^
			crc_bit[18] ^ crc_bit[17] ^ crc_bit[13] ^
			crc_bit[10] ^ crc_bit[9]  ^ crc_bit[5];
   assign new_bit[20] = crc_bit[30] ^ crc_bit[28] ^ crc_bit[26] ^
			crc_bit[25] ^ crc_bit[23] ^ crc_bit[21] ^
			crc_bit[17] ^ crc_bit[16] ^ crc_bit[12] ^
			crc_bit[9]  ^ crc_bit[8]  ^ crc_bit[4];
   assign new_bit[19] = crc_bit[29] ^ crc_bit[27] ^ crc_bit[25] ^
			crc_bit[24] ^ crc_bit[22] ^ crc_bit[20] ^
			crc_bit[16] ^ crc_bit[15] ^ crc_bit[11] ^
			crc_bit[8]  ^ crc_bit[7]  ^ crc_bit[3];
   assign new_bit[18] = crc_bit[31] ^ crc_bit[28] ^ crc_bit[26] ^
			crc_bit[24] ^ crc_bit[23] ^ crc_bit[21] ^
			crc_bit[19] ^ crc_bit[15] ^ crc_bit[14] ^
			crc_bit[10] ^ crc_bit[7]  ^ crc_bit[6]  ^ crc_bit[2];
   assign new_bit[17] = crc_bit[31] ^ crc_bit[30] ^ crc_bit[27] ^
			crc_bit[25] ^ crc_bit[23] ^ crc_bit[22] ^
			crc_bit[20] ^ crc_bit[18] ^ crc_bit[14] ^
			crc_bit[13] ^ crc_bit[9]  ^ crc_bit[6]  ^
			crc_bit[5]  ^ crc_bit[1];
   assign new_bit[16] = crc_bit[30] ^ crc_bit[29] ^ crc_bit[26] ^
			crc_bit[24] ^ crc_bit[22] ^ crc_bit[21] ^
			crc_bit[19] ^ crc_bit[17] ^ crc_bit[13] ^
			crc_bit[12] ^ crc_bit[8]  ^ crc_bit[5]  ^
			crc_bit[4]  ^ crc_bit[0];
   assign new_bit[15] = crc_bit[30] ^ crc_bit[27] ^ crc_bit[24] ^
			crc_bit[21] ^ crc_bit[20] ^ crc_bit[18] ^
			crc_bit[16] ^ crc_bit[15] ^ crc_bit[12] ^
			crc_bit[9]  ^ crc_bit[8]  ^ crc_bit[7]  ^
			crc_bit[5]  ^ crc_bit[4]  ^ crc_bit[3];
   assign new_bit[14] = crc_bit[29] ^ crc_bit[26] ^ crc_bit[23] ^
			crc_bit[20] ^ crc_bit[19] ^ crc_bit[17] ^
			crc_bit[15] ^ crc_bit[14] ^ crc_bit[11] ^
			crc_bit[8]  ^ crc_bit[7]  ^ crc_bit[6]  ^
			crc_bit[4]  ^ crc_bit[3]  ^ crc_bit[2];
   assign new_bit[13] = crc_bit[31] ^ crc_bit[28] ^ crc_bit[25] ^
			crc_bit[22] ^ crc_bit[19] ^ crc_bit[18] ^
			crc_bit[16] ^ crc_bit[14] ^ crc_bit[13] ^
			crc_bit[10] ^ crc_bit[7]  ^ crc_bit[6]  ^
			crc_bit[5]  ^ crc_bit[3]  ^ crc_bit[2]  ^ crc_bit[1];
   assign new_bit[12] = crc_bit[31] ^ crc_bit[30] ^ crc_bit[27] ^
			crc_bit[24] ^ crc_bit[21] ^ crc_bit[18] ^
			crc_bit[17] ^ crc_bit[15] ^ crc_bit[13] ^
			crc_bit[12] ^ crc_bit[9]  ^ crc_bit[6]  ^
			crc_bit[5]  ^ crc_bit[4]  ^ crc_bit[2]  ^
			crc_bit[1]  ^ crc_bit[0];
   assign new_bit[11] = crc_bit[31] ^ crc_bit[28] ^ crc_bit[27] ^
			crc_bit[26] ^ crc_bit[25] ^ crc_bit[24] ^
			crc_bit[20] ^ crc_bit[17] ^ crc_bit[16] ^
			crc_bit[15] ^ crc_bit[14] ^ crc_bit[12] ^
			crc_bit[9]  ^ crc_bit[4]  ^ crc_bit[3]  ^
			crc_bit[1]  ^ crc_bit[0];
   assign new_bit[10] = crc_bit[31] ^ crc_bit[29] ^ crc_bit[28] ^
			crc_bit[26] ^ crc_bit[19] ^ crc_bit[16] ^
			crc_bit[14] ^ crc_bit[13] ^ crc_bit[9] ^
			crc_bit[5]  ^ crc_bit[3]  ^ crc_bit[2] ^ crc_bit[0];
   assign new_bit[9] = crc_bit[29] ^ crc_bit[24] ^ crc_bit[23] ^
		       crc_bit[18] ^ crc_bit[13] ^ crc_bit[12] ^
		       crc_bit[11] ^ crc_bit[9]  ^ crc_bit[5]  ^
		       crc_bit[4]  ^ crc_bit[2]  ^ crc_bit[1];
   assign new_bit[8] = crc_bit[31] ^ crc_bit[28] ^ crc_bit[23] ^
		       crc_bit[22] ^ crc_bit[17] ^ crc_bit[12] ^
		       crc_bit[11] ^ crc_bit[10] ^ crc_bit[8]  ^
		       crc_bit[4]  ^ crc_bit[3]  ^ crc_bit[1]  ^ crc_bit[0];
   assign new_bit[7] = crc_bit[29] ^ crc_bit[28] ^ crc_bit[25] ^
		       crc_bit[24] ^ crc_bit[23] ^ crc_bit[22] ^
		       crc_bit[21] ^ crc_bit[16] ^ crc_bit[15] ^
		       crc_bit[10] ^ crc_bit[8]  ^ crc_bit[7]  ^
		       crc_bit[5]  ^ crc_bit[3]  ^ crc_bit[2]  ^ crc_bit[0];
   assign new_bit[6] = crc_bit[30] ^ crc_bit[29] ^ crc_bit[25] ^
		       crc_bit[22] ^ crc_bit[21] ^ crc_bit[20] ^
		       crc_bit[14] ^ crc_bit[11] ^ crc_bit[8]  ^
		       crc_bit[7]  ^ crc_bit[6]  ^ crc_bit[5]  ^
		       crc_bit[4]  ^ crc_bit[2]  ^ crc_bit[1];
   assign new_bit[5] = crc_bit[29] ^ crc_bit[28] ^ crc_bit[24] ^
		       crc_bit[21] ^ crc_bit[20] ^ crc_bit[19] ^
		       crc_bit[13] ^ crc_bit[10] ^ crc_bit[7]  ^
		       crc_bit[6]  ^ crc_bit[5]  ^ crc_bit[4]  ^
		       crc_bit[3]  ^ crc_bit[1]  ^ crc_bit[0];
   assign new_bit[4] = crc_bit[31] ^ crc_bit[30] ^ crc_bit[29] ^
		       crc_bit[25] ^ crc_bit[24] ^ crc_bit[20] ^
		       crc_bit[19] ^ crc_bit[18] ^ crc_bit[15] ^
		       crc_bit[12] ^ crc_bit[11] ^ crc_bit[8]  ^
		       crc_bit[6]  ^ crc_bit[4]  ^ crc_bit[3]  ^
		       crc_bit[2]  ^ crc_bit[0];
   assign new_bit[3] = crc_bit[31] ^ crc_bit[27] ^ crc_bit[25] ^
		       crc_bit[19] ^ crc_bit[18] ^ crc_bit[17] ^
		       crc_bit[15] ^ crc_bit[14] ^ crc_bit[10] ^
		       crc_bit[9]  ^ crc_bit[8]  ^ crc_bit[7]  ^
		       crc_bit[3]  ^ crc_bit[2]  ^ crc_bit[1];
   assign new_bit[2] = crc_bit[31] ^ crc_bit[30] ^ crc_bit[26] ^
		       crc_bit[24] ^ crc_bit[18] ^ crc_bit[17] ^
		       crc_bit[16] ^ crc_bit[14] ^ crc_bit[13] ^
		       crc_bit[9]  ^ crc_bit[8]  ^ crc_bit[7]  ^
		       crc_bit[6]  ^ crc_bit[2]  ^ crc_bit[1]  ^ crc_bit[0];
   assign new_bit[1] = crc_bit[28] ^ crc_bit[27] ^ crc_bit[24] ^
		       crc_bit[17] ^ crc_bit[16] ^ crc_bit[13] ^
		       crc_bit[12] ^ crc_bit[11] ^ crc_bit[9]  ^
		       crc_bit[7]  ^ crc_bit[6]  ^ crc_bit[1]  ^ crc_bit[0];
   assign new_bit[0] = crc_bit[31] ^ crc_bit[30] ^ crc_bit[29] ^
		       crc_bit[28] ^ crc_bit[26] ^ crc_bit[25] ^
		       crc_bit[24] ^ crc_bit[16] ^ crc_bit[12] ^
		       crc_bit[10] ^ crc_bit[9]  ^ crc_bit[6]  ^ crc_bit[0];

endmodule
