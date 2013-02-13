module scrambler(/*AUTOARG*/
   // Outputs
   scrambler,
   // Inputs
   clk_75m, crc_rst, data_valid
   );

   input         clk_75m;
   input         crc_rst;
   input         data_valid;
   output [31:0] scrambler;

   reg [15:0]context;
   wire scrambler_rst;
   assign scrambler_rst = crc_rst;
   always @(posedge clk_75m)
     if(scrambler_rst)
       context <= 16'hF0F6;
     else if(data_valid)
       context <= scrambler[31:16];

   wire [15:0] now;

   wire  [31:0] next;
   assign now = context[15:0];
   assign scrambler = next[31:0];

   assign        next[31] = now[12] ^ now[10] ^ now[7] ^ now[3] ^ now[1] ^ now[0];
   assign        next[30] = now[15] ^ now[14] ^ now[12] ^ now[11] ^ now[9] ^ now[6]    ^  now[3]  ^ now[2]  ^ now[0];
   assign        next[29] = now[15] ^ now[13] ^ now[12] ^ now[11] ^ now[10] ^ now[8]   ^  now[5]  ^ now[3]  ^ now[2]  ^ now[1];
   assign        next[28] = now[14] ^ now[12] ^ now[11] ^ now[10] ^ now[9] ^ now[7]    ^  now[4]  ^ now[2]  ^ now[1]  ^ now[0];
   assign        next[27] = now[15] ^ now[14] ^ now[13] ^ now[12] ^ now[11] ^ now[10]  ^  now[9]  ^ now[8]  ^ now[6]  ^ now[1] ^ now[0];
   assign        next[26] = now[15] ^ now[13] ^ now[11] ^ now[10] ^ now[9] ^ now[8]    ^  now[7]  ^ now[5]  ^ now[3]  ^ now[0];
   assign        next[25] = now[15] ^ now[10] ^ now[9] ^ now[8] ^ now[7] ^ now[6]      ^  now[4]  ^ now[3]  ^ now[2];
   assign        next[24] = now[14] ^ now[9] ^ now[8] ^ now[7] ^ now[6] ^ now[5]       ^  now[3]  ^ now[2]  ^ now[1];
   assign        next[23] = now[13] ^ now[8] ^ now[7] ^ now[6] ^ now[5] ^ now[4]       ^  now[2]  ^ now[1]  ^ now[0];
   assign        next[22] = now[15] ^ now[14] ^ now[7] ^ now[6] ^ now[5] ^ now[4]      ^  now[1]  ^ now[0];
   assign        next[21] = now[15] ^ now[13] ^ now[12] ^ now[6] ^ now[5] ^ now[4]     ^  now[0];
   assign        next[20] = now[15] ^ now[11] ^ now[5] ^ now[4];
   assign        next[19] = now[14] ^ now[10] ^ now[4] ^ now[3];
   assign        next[18] = now[13] ^ now[9] ^ now[3] ^ now[2];
   assign        next[17] = now[12] ^ now[8] ^ now[2] ^ now[1];
   assign        next[16] = now[11] ^ now[7] ^ now[1] ^ now[0];
   /* The following 16 assignments implement the matrix multiplication     */
   /* performed by the box labeled *M2.                                    */
   assign        next[15] = now[15] ^ now[14] ^ now[12] ^ now[10] ^ now[6] ^ now[3]    ^ now[0];
   assign        next[14] = now[15] ^ now[13] ^ now[12] ^ now[11] ^ now[9] ^ now[5]    ^ now[3]   ^ now[2];
   assign        next[13] = now[14] ^ now[12] ^ now[11] ^ now[10] ^ now[8] ^ now[4]    ^ now[2]   ^ now[1];
   assign        next[12] = now[13] ^ now[11] ^ now[10] ^ now[9] ^ now[7] ^ now[3]     ^ now[1]   ^ now[0];
   assign        next[11] = now[15] ^ now[14] ^ now[10] ^ now[9] ^ now[8] ^ now[6]     ^ now[3]   ^ now[2]  ^ now[0];
   assign        next[10] = now[15] ^ now[13] ^ now[12] ^ now[9] ^ now[8] ^ now[7]     ^ now[5]   ^ now[3]  ^ now[2]  ^ now[1];
   assign        next[9] = now[14] ^ now[12] ^ now[11] ^ now[8] ^ now[7] ^ now[6]      ^ now[4]   ^ now[2]  ^ now[1]  ^ now[0];
   assign        next[8] = now[15] ^ now[14] ^ now[13] ^ now[12] ^ now[11] ^ now[10]   ^ now[7]   ^ now[6]  ^ now[5]  ^ now[1] ^ now[0];
   assign        next[7] = now[15] ^ now[13] ^ now[11] ^ now[10] ^ now[9] ^ now[6]     ^ now[5]   ^ now[4]  ^ now[3]  ^ now[0];
   assign        next[6] = now[15] ^ now[10] ^ now[9] ^ now[8] ^ now[5] ^ now[4]       ^ now[2];
   assign        next[5] = now[14] ^ now[9] ^ now[8] ^ now[7] ^ now[4] ^ now[3]        ^ now[1];
   assign        next[4] = now[13] ^ now[8] ^ now[7] ^ now[6] ^ now[3] ^ now[2]        ^ now[0];
   assign        next[3] = now[15] ^ now[14] ^ now[7] ^ now[6] ^ now[5] ^ now[3]       ^ now[2]   ^ now[1];
   assign        next[2] = now[14] ^ now[13] ^ now[6] ^ now[5] ^ now[4] ^ now[2]       ^ now[1]   ^ now[0];
   assign        next[1] = now[15] ^ now[14] ^ now[13] ^ now[5] ^ now[4] ^ now[1]      ^ now[0];
   assign        next[0] = now[15] ^ now[13] ^ now[4] ^ now[0];
endmodule // scrambler
