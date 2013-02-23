
#define XPAR_MICROBLAZE_DCACHE_LINE_LEN 8
#define XPAR_MICROBLAZE_DCACHE_USE_WRITEBACK 1

#define MSR_BE  (1<<0) /* 0x001 */
#define MSR_IE  (1<<1) /* 0x002 */
#define MSR_C   (1<<2) /* 0x004 */
#define MSR_BIP (1<<3) /* 0x008 */
#define MSR_FSL (1<<4) /* 0x010 */
#define MSR_ICE (1<<5) /* 0x020 */
#define MSR_DZ  (1<<6) /* 0x040 */
#define MSR_DCE (1<<7) /* 0x080 */
#define MSR_EE  (1<<8) /* 0x100 */
#define MSR_EIP (1<<9) /* 0x200 */
#define MSR_CC  (1<<31)


static inline void __invalidate_flush_icache(unsigned int addr)
{
	__asm__ __volatile__ ("wic	%0, r0;"	\
					: : "r" (addr));
}

static inline void __flush_dcache(unsigned int addr)
{
	__asm__ __volatile__ ("wdc.flush	%0, r0;"	\
					: : "r" (addr));
}

static inline void __invalidate_dcache_wb(unsigned int baseaddr,
						unsigned int offset)
{
	__asm__ __volatile__ ("wdc.clear	%0, %1;"	\
					: : "r" (baseaddr), "r" (offset));
}

static inline void __enable_icache_msr(void)
{
	__asm__ __volatile__ ("	msrset	r0, %0;		\
				nop; "			\
			: : "i" (MSR_ICE) : "memory");
}

static inline void __disable_icache_msr(void)
{
	__asm__ __volatile__ ("	msrclr	r0, %0;		\
				nop; "			\
			: : "i" (MSR_ICE) : "memory");
}

static inline void __enable_dcache_msr(void)
{
	__asm__ __volatile__ ("	msrset	r0, %0;		\
				nop; "			\
				:			\
				: "i" (MSR_DCE)		\
				: "memory");
}

static inline void __disable_dcache_msr(void)
{
	__asm__ __volatile__ ("	msrclr	r0, %0;		\
				nop; "			\
				:			\
				: "i" (MSR_DCE)		\
				: "memory");
}

static inline void __enable_icache_nomsr(void)
{
	__asm__ __volatile__ ("	mfs	r12, rmsr;	\
				nop;			\
				ori	r12, r12, %0;	\
				mts	rmsr, r12;	\
				nop; "			\
				:			\
				: "i" (MSR_ICE)		\
				: "memory", "r12");
}

static inline void __disable_icache_nomsr(void)
{
	__asm__ __volatile__ ("	mfs	r12, rmsr;	\
				nop;			\
				andi	r12, r12, ~%0;	\
				mts	rmsr, r12;	\
				nop; "			\
				:			\
				: "i" (MSR_ICE)		\
				: "memory", "r12");
}

static inline void __enable_dcache_nomsr(void)
{
	__asm__ __volatile__ ("	mfs	r12, rmsr;	\
				nop;			\
				ori	r12, r12, %0;	\
				mts	rmsr, r12;	\
				nop; "			\
				:			\
				: "i" (MSR_DCE)		\
				: "memory", "r12");
}

static inline void __disable_dcache_nomsr(void)
{
	__asm__ __volatile__ ("	mfs	r12, rmsr;	\
				nop;			\
				andi	r12, r12, ~%0;	\
				mts	rmsr, r12;	\
				nop; "			\
				:			\
				: "i" (MSR_DCE)		\
				: "memory", "r12");
}

