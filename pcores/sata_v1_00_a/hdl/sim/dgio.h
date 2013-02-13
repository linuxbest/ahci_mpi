#ifndef _DGIO_H
#define _DGIO_H

#ifdef __cplusplus
extern "C" {
#endif

extern int osChip_init(uint32_t base);
extern int osChip_interrupt(uint32_t base);

extern uint32_t osChipRegRead(uint32_t chipOffset);
extern void     osChipRegWrite(uint32_t chipOffset, uint32_t chipValue);

extern const char *systemc_time(void);
extern void systemc_sc_stop(void);
extern FILE *tfile;
extern unsigned char *base0;
extern int mem_size;

#ifdef __cplusplus
}
#endif

#endif
