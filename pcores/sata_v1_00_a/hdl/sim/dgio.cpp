#include <systemc.h>
#include "dgio.h"

SC_MODULE(dgio)
{
 public:
  sc_in<bool> sys_clk;
  sc_in<bool> sys_rst;

  sc_in<bool> MPMC_Clk;
  sc_in<bool> MPMC_Rst;

  sc_in < bool > irq;
  sc_in < sc_uint<32> > readdata;
  sc_out< sc_uint<32> > writedata;
  sc_out< sc_uint<6> >  address;
  sc_out< bool >        write;

  sc_in < bool >        PIM_AddrReq;
  sc_out< bool >        PIM_AddrAck;
  sc_in < sc_uint<32> > PIM_Addr;
  sc_in < sc_uint<4> >  PIM_Size;
  sc_in < bool >        PIM_RNW;
  sc_in < bool >        PIM_RdModWr;

  sc_out< sc_uint<4> >  PIM_RdFIFO_RdWdAddr;
  sc_out< sc_uint<32> > PIM_RdFIFO_Data;
  sc_in < bool >        PIM_RdFIFO_Flush;
  sc_in < bool >        PIM_RdFIFO_Pop;
  sc_out< bool >        PIM_RdFIFO_Empty;
  sc_out< sc_uint<2> >  PIM_RdFIFO_Latency;

  sc_in < sc_uint<32> > PIM_WrFIFO_Data;
  sc_in < sc_uint<4> >  PIM_WrFIFO_BE;
  sc_in < bool >        PIM_WrFIFO_Push;
  sc_in < bool >        PIM_WrFIFO_Flush;
  sc_out< bool >        PIM_WrFIFO_Empty;
  sc_out< bool >        PIM_WrFIFO_AlmostFull;

  sc_out< bool >        PIM_InitDone;

  uint32_t iomem_in32(uint32_t off);
  void iomem_out32(uint32_t off, uint32_t val);
  void dgio_thread();
  void dgio_Mn_thread();
  void dgio_wr_thread();
  void dgio_rd_thread();
  SC_CTOR(dgio)
  {
    SC_THREAD(dgio_thread);
    SC_THREAD(dgio_Mn_thread);
    SC_THREAD(dgio_wr_thread);
    SC_THREAD(dgio_rd_thread);
  };
  
  ~dgio()
    {
    }

  sc_fifo< sc_uint<32> > wrfifo;
  sc_fifo< sc_uint<32> > rdfifo;
};

static dgio *obj;
static uint32_t base = 0x1000000;

int size_to_burst[] = {1, 4, 8, 16, 32, 64};

void dgio::dgio_rd_thread(void)
{
  uint32_t d0 = 0;
  uint32_t d1;
  uint32_t d2;
  
  for (;;) {
    wait(MPMC_Clk->negedge_event());
   
    PIM_RdFIFO_Empty.write(rdfifo.num_available() == 0);
    PIM_RdFIFO_Data.write(d0);
    d1 = d0;
    d2 = d1;

    if (PIM_RdFIFO_Pop.read()) {
      d0 = rdfifo.read();
    }
  }
}

void dgio::dgio_wr_thread(void)
{
  for (;;) {
    wait(MPMC_Clk->negedge_event());
    if (PIM_WrFIFO_Push.read()) {
      uint32_t d0 = PIM_WrFIFO_Data.read();
      wrfifo.write(d0);
    }
  }
}

void dgio::dgio_Mn_thread(void)
{
  PIM_AddrAck.write(0);
  PIM_RdFIFO_RdWdAddr.write(0);
  PIM_RdFIFO_Latency.write(2);
  PIM_WrFIFO_AlmostFull.write(0);
  PIM_InitDone.write(1);

  int rnw = 3;		// 3 idle, 1 read, 0 write
  int burst;
  uint32_t addr;
  
  for (;;) {
    wait(MPMC_Clk->negedge_event());
    
    PIM_AddrAck.write(0);

    if (PIM_AddrReq.read() && rnw == 3) {
      PIM_AddrAck.write(1);
      int size  = PIM_Size.read();
      addr  = PIM_Addr.read();
      rnw   = PIM_RNW.read();
      burst = size_to_burst[size];
    } else if (rnw == 0) {
      if (burst == 1)
	rnw = 3;
      burst --;
      
      addr &= (mem_size-1);
      uint32_t v0 = wrfifo.read();
      base0[addr+3] = (v0 >> 0 ) & 0xff;
      base0[addr+2] = (v0 >> 8 ) & 0xff;
      base0[addr+1] = (v0 >> 16) & 0xff;
      base0[addr+0] = (v0 >> 24) & 0xff;
      printf("%s: Mn_Write %08x to Address(%04x)\n",
	     systemc_time(), v0, addr);
      addr += 4;
    } else if (rnw == 1) {
      if (burst == 1)
	rnw = 3;
      burst --;
      
      addr &= (mem_size-1);      
      uint32_t v0 = (base0[addr+3] << 0)| 
	(base0[addr+2] << 8)|
	(base0[addr+1] << 16)|
	(base0[addr+0] << 24);
      rdfifo.write(v0);
      printf("%s: Mn_Read %08x from Address(%04x)\n",
	     systemc_time(), v0, addr);
      addr += 4;
    }
  }
}

void dgio::dgio_thread(void)
{
  int i; 

  obj = this;

  write = 0;
  writedata = 0;
  address = 0;

  // wait system ready.
  for (i = 0; i < 200; i ++) {
    wait(sys_clk->posedge_event());
  }
  
  // call init.
  osChip_init(base);

  // handle irq
  for (;;) {
    wait(sys_clk->posedge_event());
    if (irq.read())
      osChip_interrupt(base);
  }
}

void dgio::iomem_out32(uint32_t off, uint32_t val)
{
  address = off;
  writedata = val;
  write = 1;
  wait(sys_clk->negedge_event());
  write = 0;
  wait(sys_clk->negedge_event());
}

uint32_t dgio::iomem_in32(uint32_t off)
{
  address = off;
  write = 0;
  wait(sys_clk->negedge_event());
  return readdata.read();
}

uint32_t osChipRegRead(uint32_t chipOffset)
{
  return obj->iomem_in32(chipOffset);
}

void osChipRegWrite(uint32_t chipOffset, uint32_t chipValue)
{
  obj->iomem_out32(chipOffset, chipValue);
}
const char *systemc_time(void)
{
  return sc_time_stamp().to_string().c_str();
}
void systemc_sc_stop(void)
{
  sc_core::sc_stop();
}

SC_MODULE_EXPORT(dgio);
