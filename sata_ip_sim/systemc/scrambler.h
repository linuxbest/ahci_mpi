void Sata_scrambler(uint32_t *buf, int size)
{
   int                i, j;
   unsigned  short    context;        /*  The 16 bit register that holds the context or state */
   unsigned  long     scrambler;      /*  The 32 bit output of the circuit     */
   unsigned  char     now[16];        /*  The individual bits of context       */
   unsigned  char     next[32];       /*  The computed bits of scrambler       */
   /* Parallelized versions of the scrambler are initialized to a value        */
   /* derived from the initialization value of 0xFFFF defined in the           */
   /* specification. This implementation is initialized to 0xF0F6. Other       */
   /* parallel implementations have different initial values. The              */
   /* important point is that the first Dword output of any implementation     */
   /* needs to equal 0xC2D2768D.                                               */
   context = 0xF0F6;
   for (i = 0; i <= size; ++i) {
       /* Split the register contents (the variable context) up into its       */
       /* individual bits for easy handling.                                   */
       for (j = 0; j < 16; ++j) {
          now[j] = (context >> j) & 0x01;
       }
       /* The following 16 assignments implement the matrix multiplication     */
       /* performed by the box labeled *M1.                                    */
       /* Notice that there are lots of shared terms in these assignments.     */
       next[31] = now[12] ^ now[10] ^ now[7] ^ now[3] ^ now[1] ^ now[0];
       next[30] = now[15] ^ now[14] ^ now[12] ^ now[11] ^ now[9] ^ now[6]    ^  now[3]  ^ now[2]  ^ now[0];
       next[29] = now[15] ^ now[13] ^ now[12] ^ now[11] ^ now[10] ^ now[8]   ^  now[5]  ^ now[3]  ^ now[2]  ^ now[1];
       next[28] = now[14] ^ now[12] ^ now[11] ^ now[10] ^ now[9] ^ now[7]    ^  now[4]  ^ now[2]  ^ now[1]  ^ now[0];
       next[27] = now[15] ^ now[14] ^ now[13] ^ now[12] ^ now[11] ^ now[10]  ^  now[9]  ^ now[8]  ^ now[6]  ^ now[1] ^ now[0];
       next[26] = now[15] ^ now[13] ^ now[11] ^ now[10] ^ now[9] ^ now[8]    ^  now[7]  ^ now[5]  ^ now[3]  ^ now[0];
       next[25] = now[15] ^ now[10] ^ now[9] ^ now[8] ^ now[7] ^ now[6]      ^  now[4]  ^ now[3]  ^ now[2];
       next[24] = now[14] ^ now[9] ^ now[8] ^ now[7] ^ now[6] ^ now[5]       ^  now[3]  ^ now[2]  ^ now[1];
       next[23] = now[13] ^ now[8] ^ now[7] ^ now[6] ^ now[5] ^ now[4]       ^  now[2]  ^ now[1]  ^ now[0];
       next[22] = now[15] ^ now[14] ^ now[7] ^ now[6] ^ now[5] ^ now[4]      ^  now[1]  ^ now[0];
       next[21] = now[15] ^ now[13] ^ now[12] ^ now[6] ^ now[5] ^ now[4]     ^  now[0];
       next[20] = now[15] ^ now[11] ^ now[5] ^ now[4];
       next[19] = now[14] ^ now[10] ^ now[4] ^ now[3];
       next[18] = now[13] ^ now[9] ^ now[3] ^ now[2];
       next[17] = now[12] ^ now[8] ^ now[2] ^ now[1];
       next[16] = now[11] ^ now[7] ^ now[1] ^ now[0];
       /* The following 16 assignments implement the matrix multiplication     */
       /* performed by the box labeled *M2.                                    */
       next[15] = now[15] ^ now[14] ^ now[12] ^ now[10] ^ now[6] ^ now[3]    ^ now[0];
       next[14] = now[15] ^ now[13] ^ now[12] ^ now[11] ^ now[9] ^ now[5]    ^ now[3]   ^ now[2];
       next[13] = now[14] ^ now[12] ^ now[11] ^ now[10] ^ now[8] ^ now[4]    ^ now[2]   ^ now[1];
       next[12] = now[13] ^ now[11] ^ now[10] ^ now[9] ^ now[7] ^ now[3]     ^ now[1]   ^ now[0];
       next[11] = now[15] ^ now[14] ^ now[10] ^ now[9] ^ now[8] ^ now[6]     ^ now[3]   ^ now[2]  ^ now[0];
       next[10] = now[15] ^ now[13] ^ now[12] ^ now[9] ^ now[8] ^ now[7]     ^ now[5]   ^ now[3]  ^ now[2]  ^ now[1];
       next[9] = now[14] ^ now[12] ^ now[11] ^ now[8] ^ now[7] ^ now[6]      ^ now[4]   ^ now[2]  ^ now[1]  ^ now[0];
       next[8] = now[15] ^ now[14] ^ now[13] ^ now[12] ^ now[11] ^ now[10]   ^ now[7]   ^ now[6]  ^ now[5]  ^ now[1] ^ now[0];
       next[7] = now[15] ^ now[13] ^ now[11] ^ now[10] ^ now[9] ^ now[6]     ^ now[5]   ^ now[4]  ^ now[3]  ^ now[0];
       next[6] = now[15] ^ now[10] ^ now[9] ^ now[8] ^ now[5] ^ now[4]       ^ now[2];
       next[5] = now[14] ^ now[9] ^ now[8] ^ now[7] ^ now[4] ^ now[3]        ^ now[1];
       next[4] = now[13] ^ now[8] ^ now[7] ^ now[6] ^ now[3] ^ now[2]        ^ now[0];
       next[3] = now[15] ^ now[14] ^ now[7] ^ now[6] ^ now[5] ^ now[3]       ^ now[2]   ^ now[1];
       next[2] = now[14] ^ now[13] ^ now[6] ^ now[5] ^ now[4] ^ now[2]       ^ now[1]   ^ now[0];
       next[1] = now[15] ^ now[14] ^ now[13] ^ now[5] ^ now[4] ^ now[1]      ^ now[0];
       next[0] = now[15] ^ now[13] ^ now[4] ^ now[0];
       /* The 32 bits of the output have been generated in the "next" array. */
       /* Reassemble the bits into a 32 bit Dword.                             */
       scrambler = 0;
       for (j = 31; j >= 0; --j) {
          scrambler = scrambler << 1;
        scrambler |= next[j];
     }
     /* The upper half of the scrambler output is stored backed into the */
     /* register as the saved context for the next cycle.                */
     context = scrambler >> 16;
     printf("scramber = 0x%08X\n", scrambler);
     printf("buf = 0x%08X\n", *buf);
     *buf ^= scrambler;
     printf("descrambler = 0x%08X\n", *buf);
     buf++;
  }
  return (void)0;
}
