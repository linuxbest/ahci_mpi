//-----------------------------------------------------------------------------
// bfm_tb.v
//-----------------------------------------------------------------------------

`timescale 1 ps / 100 fs

`uselib lib=unisims_ver

// START USER CODE (Do not remove this line)

// User: Put your directives here. Code in this
//       section will not be overwritten.

// END USER CODE (Do not remove this line)

module bfm_tb
  (
  );

  // START USER CODE (Do not remove this line)

  // User: Put your signals here. Code in this
  //       section will not be overwritten.

  // END USER CODE (Do not remove this line)

  real fpga_0_clk_1_sys_clk_pin_PERIOD = 10000.000000;
  real fpga_0_rst_1_sys_rst_pin_LENGTH = 160000;

  reg fpga_0_clk_1_sys_clk_pin;
  reg fpga_0_rst_1_sys_rst_pin;
  wire [1:0] fpga_0_DDR2_SDRAM_DDR2_Clk_pin;
  wire [1:0] fpga_0_DDR2_SDRAM_DDR2_Clk_n_pin;
  wire [0:0] fpga_0_DDR2_SDRAM_DDR2_CE_pin;
  wire [0:0] fpga_0_DDR2_SDRAM_DDR2_CS_n_pin;
  wire [1:0] fpga_0_DDR2_SDRAM_DDR2_ODT_pin;
  wire fpga_0_DDR2_SDRAM_DDR2_RAS_n_pin;
  wire fpga_0_DDR2_SDRAM_DDR2_CAS_n_pin;
  wire fpga_0_DDR2_SDRAM_DDR2_WE_n_pin;
  wire [2:0] fpga_0_DDR2_SDRAM_DDR2_BankAddr_pin;
  wire [13:0] fpga_0_DDR2_SDRAM_DDR2_Addr_pin;
  wire [63:0] fpga_0_DDR2_SDRAM_DDR2_DQ_pin;
  wire [7:0] fpga_0_DDR2_SDRAM_DDR2_DM_pin;
  wire [7:0] fpga_0_DDR2_SDRAM_DDR2_DQS_pin;
  wire [7:0] fpga_0_DDR2_SDRAM_DDR2_DQS_n_pin;
  wire fpga_0_DDR2_SDRAM_DDR2_rst_n_pin;
  reg [31:0] PIM0_Addr;
  reg PIM0_AddrReq;
  wire PIM0_AddrAck;
  reg PIM0_RNW;
  reg [3:0] PIM0_Size;
  reg PIM0_RdModWr;
  reg [63:0] PIM0_WrFIFO_Data;
  reg [7:0] PIM0_WrFIFO_BE;
  reg PIM0_WrFIFO_Push;
  wire [63:0] PIM0_RdFIFO_Data;
  reg PIM0_RdFIFO_Pop;
  wire [3:0] PIM0_RdFIFO_RdWdAddr;
  wire PIM0_WrFIFO_Empty;
  wire PIM0_WrFIFO_AlmostFull;
  reg PIM0_WrFIFO_Flush;
  wire PIM0_RdFIFO_Empty;
  reg PIM0_RdFIFO_Flush;
  wire [1:0] PIM0_RdFIFO_Latency;
  wire PIM0_InitDone;
  wire PIM0_Clk;
  reg [31:0] PIM1_Addr;
  reg PIM1_AddrReq;
  wire PIM1_AddrAck;
  reg PIM1_RNW;
  reg [3:0] PIM1_Size;
  reg PIM1_RdModWr;
  reg [63:0] PIM1_WrFIFO_Data;
  reg [7:0] PIM1_WrFIFO_BE;
  reg PIM1_WrFIFO_Push;
  wire [63:0] PIM1_RdFIFO_Data;
  reg PIM1_RdFIFO_Pop;
  wire [3:0] PIM1_RdFIFO_RdWdAddr;
  wire PIM1_WrFIFO_Empty;
  wire PIM1_WrFIFO_AlmostFull;
  reg PIM1_WrFIFO_Flush;
  wire PIM1_RdFIFO_Empty;
  reg PIM1_RdFIFO_Flush;
  wire [1:0] PIM1_RdFIFO_Latency;
  wire PIM1_InitDone;
  wire PIM1_Clk;

  bfm
    dut (
      .fpga_0_clk_1_sys_clk_pin ( fpga_0_clk_1_sys_clk_pin ),
      .fpga_0_rst_1_sys_rst_pin ( fpga_0_rst_1_sys_rst_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_Clk_pin ( fpga_0_DDR2_SDRAM_DDR2_Clk_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_Clk_n_pin ( fpga_0_DDR2_SDRAM_DDR2_Clk_n_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_CE_pin ( fpga_0_DDR2_SDRAM_DDR2_CE_pin[0:0] ),
      .fpga_0_DDR2_SDRAM_DDR2_CS_n_pin ( fpga_0_DDR2_SDRAM_DDR2_CS_n_pin[0:0] ),
      .fpga_0_DDR2_SDRAM_DDR2_ODT_pin ( fpga_0_DDR2_SDRAM_DDR2_ODT_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_RAS_n_pin ( fpga_0_DDR2_SDRAM_DDR2_RAS_n_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_CAS_n_pin ( fpga_0_DDR2_SDRAM_DDR2_CAS_n_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_WE_n_pin ( fpga_0_DDR2_SDRAM_DDR2_WE_n_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_BankAddr_pin ( fpga_0_DDR2_SDRAM_DDR2_BankAddr_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_Addr_pin ( fpga_0_DDR2_SDRAM_DDR2_Addr_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_DQ_pin ( fpga_0_DDR2_SDRAM_DDR2_DQ_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_DM_pin ( fpga_0_DDR2_SDRAM_DDR2_DM_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_DQS_pin ( fpga_0_DDR2_SDRAM_DDR2_DQS_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_DQS_n_pin ( fpga_0_DDR2_SDRAM_DDR2_DQS_n_pin ),
      .fpga_0_DDR2_SDRAM_DDR2_rst_n_pin ( fpga_0_DDR2_SDRAM_DDR2_rst_n_pin ),
      .PIM0_Addr ( PIM0_Addr ),
      .PIM0_AddrReq ( PIM0_AddrReq ),
      .PIM0_AddrAck ( PIM0_AddrAck ),
      .PIM0_RNW ( PIM0_RNW ),
      .PIM0_Size ( PIM0_Size ),
      .PIM0_RdModWr ( PIM0_RdModWr ),
      .PIM0_WrFIFO_Data ( PIM0_WrFIFO_Data ),
      .PIM0_WrFIFO_BE ( PIM0_WrFIFO_BE ),
      .PIM0_WrFIFO_Push ( PIM0_WrFIFO_Push ),
      .PIM0_RdFIFO_Data ( PIM0_RdFIFO_Data ),
      .PIM0_RdFIFO_Pop ( PIM0_RdFIFO_Pop ),
      .PIM0_RdFIFO_RdWdAddr ( PIM0_RdFIFO_RdWdAddr ),
      .PIM0_WrFIFO_Empty ( PIM0_WrFIFO_Empty ),
      .PIM0_WrFIFO_AlmostFull ( PIM0_WrFIFO_AlmostFull ),
      .PIM0_WrFIFO_Flush ( PIM0_WrFIFO_Flush ),
      .PIM0_RdFIFO_Empty ( PIM0_RdFIFO_Empty ),
      .PIM0_RdFIFO_Flush ( PIM0_RdFIFO_Flush ),
      .PIM0_RdFIFO_Latency ( PIM0_RdFIFO_Latency ),
      .PIM0_InitDone ( PIM0_InitDone ),
      .PIM0_Clk ( PIM0_Clk ),
      .PIM1_Addr ( PIM1_Addr ),
      .PIM1_AddrReq ( PIM1_AddrReq ),
      .PIM1_AddrAck ( PIM1_AddrAck ),
      .PIM1_RNW ( PIM1_RNW ),
      .PIM1_Size ( PIM1_Size ),
      .PIM1_RdModWr ( PIM1_RdModWr ),
      .PIM1_WrFIFO_Data ( PIM1_WrFIFO_Data ),
      .PIM1_WrFIFO_BE ( PIM1_WrFIFO_BE ),
      .PIM1_WrFIFO_Push ( PIM1_WrFIFO_Push ),
      .PIM1_RdFIFO_Data ( PIM1_RdFIFO_Data ),
      .PIM1_RdFIFO_Pop ( PIM1_RdFIFO_Pop ),
      .PIM1_RdFIFO_RdWdAddr ( PIM1_RdFIFO_RdWdAddr ),
      .PIM1_WrFIFO_Empty ( PIM1_WrFIFO_Empty ),
      .PIM1_WrFIFO_AlmostFull ( PIM1_WrFIFO_AlmostFull ),
      .PIM1_WrFIFO_Flush ( PIM1_WrFIFO_Flush ),
      .PIM1_RdFIFO_Empty ( PIM1_RdFIFO_Empty ),
      .PIM1_RdFIFO_Flush ( PIM1_RdFIFO_Flush ),
      .PIM1_RdFIFO_Latency ( PIM1_RdFIFO_Latency ),
      .PIM1_InitDone ( PIM1_InitDone ),
      .PIM1_Clk ( PIM1_Clk )
    );

  // Clock generator for fpga_0_clk_1_sys_clk_pin

  initial
    begin
      fpga_0_clk_1_sys_clk_pin = 1'b0;
      forever #(fpga_0_clk_1_sys_clk_pin_PERIOD/2.00)
        fpga_0_clk_1_sys_clk_pin = ~fpga_0_clk_1_sys_clk_pin;
    end

  // Reset Generator for fpga_0_rst_1_sys_rst_pin

  initial
    begin
      fpga_0_rst_1_sys_rst_pin = 1'b0;
      #(fpga_0_rst_1_sys_rst_pin_LENGTH) fpga_0_rst_1_sys_rst_pin = ~fpga_0_rst_1_sys_rst_pin;
    end

  // START USER CODE (Do not remove this line)

  // User: Put your stimulus here. Code in this
  //       section will not be overwritten.

  // memory controller parameters
   parameter BANK_WIDTH            = 3;      // # of memory bank addr bits
   parameter CKE_WIDTH             = 1;      // # of memory clock enable outputs
   parameter CLK_WIDTH             = 2;      // # of clock outputs
   parameter COL_WIDTH             = 10;     // # of memory column bits
   parameter CS_NUM                = 4;      // # of separate memory chip selects
   parameter CS_WIDTH              = 1;      // # of total memory chip selects
   parameter DM_WIDTH              = 8;      // # of data mask bits
   parameter DQ_WIDTH              = 64;      // # of data width
   parameter DQ_PER_DQS            = 8;      // # of DQ data bits per strobe
   parameter DQS_WIDTH             = 8;      // # of DQS strobes
   parameter DQ_BITS               = 7;      // set to log2(DQS_WIDTH*DQ_PER_DQS)
   parameter DQS_BITS              = 4;      // set to log2(DQS_WIDTH)
   parameter ODT_WIDTH             = 2;      // # of memory on-die term enables
   parameter ROW_WIDTH             = 14;     // # of memory row & # of addr bits
   parameter CLK_PERIOD            = 5000;   // Core/Mem clk period (in ps)
   parameter DEVICE_WIDTH          = 8;      // Memory device data width
   parameter REG_ENABLE            = 1;

  ddr2_dimm
     # (
	// Parameters
	.BANK_WIDTH			(BANK_WIDTH),
	.CKE_WIDTH			(CKE_WIDTH),
	.CLK_WIDTH			(CLK_WIDTH),
	.COL_WIDTH			(COL_WIDTH),
	.CS_NUM				(CS_NUM),
	.CS_WIDTH			(CS_WIDTH),
	.DM_WIDTH			(DM_WIDTH),
	.DQ_WIDTH			(DQ_WIDTH),
	.DQ_PER_DQS			(DQ_PER_DQS),
	.DQS_WIDTH			(DQS_WIDTH),
	.DQ_BITS			(DQ_BITS),
	.DQS_BITS			(DQS_BITS),
	.ODT_WIDTH			(ODT_WIDTH),
	.ROW_WIDTH			(ROW_WIDTH),
	.CLK_PERIOD			(CLK_PERIOD),
	.DEVICE_WIDTH			(DEVICE_WIDTH))
   dimm (
	 // Inputs
	 .ddr2_dq_sdram			(fpga_0_DDR2_SDRAM_DDR2_DQ_pin[DQ_WIDTH-1:0]),
	 .ddr2_dqs_sdram		(fpga_0_DDR2_SDRAM_DDR2_DQS_pin[DQS_WIDTH-1:0]),
	 .ddr2_dqs_n_sdram		(fpga_0_DDR2_SDRAM_DDR2_DQS_n_pin[DQS_WIDTH-1:0]),
	 .ddr2_dm_sdram			(fpga_0_DDR2_SDRAM_DDR2_DM_pin[DM_WIDTH-1:0]),
	 .ddr2_clk_sdram		(fpga_0_DDR2_SDRAM_DDR2_Clk_pin[CLK_WIDTH-1:0]),
	 .ddr2_clk_n_sdram		(fpga_0_DDR2_SDRAM_DDR2_Clk_n_pin[CLK_WIDTH-1:0]),
	 .ddr2_address_sdram		(fpga_0_DDR2_SDRAM_DDR2_Addr_pin[ROW_WIDTH-1:0]),
	 .ddr2_ba_sdram			(fpga_0_DDR2_SDRAM_DDR2_BankAddr_pin[BANK_WIDTH-1:0]),
	 .ddr2_ras_n_sdram		(fpga_0_DDR2_SDRAM_DDR2_RAS_n_pin),
	 .ddr2_cas_n_sdram		(fpga_0_DDR2_SDRAM_DDR2_CAS_n_pin),
	 .ddr2_we_n_sdram		(fpga_0_DDR2_SDRAM_DDR2_WE_n_pin),
	 .ddr2_cs_n_sdram		(fpga_0_DDR2_SDRAM_DDR2_CS_n_pin[CS_WIDTH-1:0]),
	 .ddr2_cke_sdram		(fpga_0_DDR2_SDRAM_DDR2_CE_pin[CKE_WIDTH-1:0]),
	 .ddr2_odt_sdram		(fpga_0_DDR2_SDRAM_DDR2_ODT_pin[ODT_WIDTH-1:0]));

   localparam [2:0]		// ras, cas, we
     C_DDR_NOP = 3'b111,
     C_DDR_ACT = 3'b011,
     C_DDR_READ= 3'b101,
     C_DDR_WRT = 3'b100,
     C_DDR_REF = 3'b001;   
   reg [39:0] 		  cmd_ascii;
   always @(*)
     begin
	case ({fpga_0_DDR2_SDRAM_DDR2_RAS_n_pin, 
	       fpga_0_DDR2_SDRAM_DDR2_CAS_n_pin, 
	       fpga_0_DDR2_SDRAM_DDR2_WE_n_pin})
	  C_DDR_NOP : cmd_ascii = "NOP  ";
	  C_DDR_ACT : cmd_ascii = "ACT  ";
	  C_DDR_READ: cmd_ascii = "READ ";
	  C_DDR_WRT:  cmd_ascii = "WRITE";
	endcase
     end
   parameter C_PIM0_DATA_WIDTH = 64;
   parameter C_GNPI0_ENABLE = 1;
   parameter C_PIM1_DATA_WIDTH = 64;
   parameter C_GNPI1_ENABLE = 1;
  
   wire [31:0] PIM0_Addr_i;
   wire PIM0_AddrReq_i;
   wire PIM0_RNW_i;
   wire [3:0] PIM0_Size_i;
   wire PIM0_RdModWr_i;
   wire PIM0_RdFIFO_Flush_i;
   wire PIM0_RdFIFO_Pop_i;
   wire [C_PIM0_DATA_WIDTH-1:0] PIM0_WrFIFO_Data_i;
   wire [(C_PIM0_DATA_WIDTH/8)-1:0] PIM0_WrFIFO_BE_i;
   wire PIM0_WrFIFO_Push_i;
   wire PIM0_WrFIFO_Flush_i;

   wire [31:0] PIM1_Addr_i;
   wire PIM1_AddrReq_i;
   wire PIM1_RNW_i;
   wire [3:0] PIM1_Size_i;
   wire PIM1_RdModWr_i;
   wire PIM1_RdFIFO_Flush_i;
   wire PIM1_RdFIFO_Pop_i;
   wire [C_PIM1_DATA_WIDTH-1:0] PIM1_WrFIFO_Data_i;
   wire [(C_PIM1_DATA_WIDTH/8)-1:0] PIM1_WrFIFO_BE_i;
   wire PIM1_WrFIFO_Push_i;
   wire PIM1_WrFIFO_Flush_i;
   always @(*)
   begin
      PIM0_Addr         = PIM0_Addr_i;
      PIM0_AddrReq      = PIM0_AddrReq_i;
      PIM0_RNW          = PIM0_RNW_i;
      PIM0_Size         = PIM0_Size_i;
      PIM0_RdModWr      = PIM0_RdModWr_i;
      PIM0_RdFIFO_Flush = PIM0_RdFIFO_Flush_i;
      PIM0_RdFIFO_Pop   = PIM0_RdFIFO_Pop_i;
      PIM0_WrFIFO_Data  = PIM0_WrFIFO_Data_i;
      PIM0_WrFIFO_BE    = PIM0_WrFIFO_BE_i;
      PIM0_WrFIFO_Push  = PIM0_WrFIFO_Push_i;
      PIM0_WrFIFO_Flush = PIM0_WrFIFO_Flush_i;

      PIM1_Addr         = 0; 
      PIM1_AddrReq      = 0; 
      PIM1_RNW          = 0; 
      PIM1_Size         = 0; 
      PIM1_RdModWr      = 0; 
      PIM1_RdFIFO_Flush = 0; 
      PIM1_RdFIFO_Pop   = 0; 
      PIM1_WrFIFO_Data  = 0; 
      PIM1_WrFIFO_BE    = 0; 
      PIM1_WrFIFO_Push  = 0; 
      PIM1_WrFIFO_Flush = 0; 
   end // always @ begin

   npi_ict_top
     npi_ict_top (
		  // Outputs
		  .PIM_Addr		(PIM0_Addr_i[31:0]),
		  .PIM_AddrReq		(PIM0_AddrReq_i),
		  .PIM_RNW		(PIM0_RNW_i),
		  .PIM_RdFIFO_Flush	(PIM0_RdFIFO_Flush_i),
		  .PIM_RdFIFO_Pop	(PIM0_RdFIFO_Pop_i),
		  .PIM_RdModWr		(PIM0_RdModWr_i),
		  .PIM_Size		(PIM0_Size_i[3:0]),
		  .PIM_WrFIFO_BE	(PIM0_WrFIFO_BE_i[(C_PIM0_DATA_WIDTH/8)-1:0]),
		  .PIM_WrFIFO_Data	(PIM0_WrFIFO_Data_i[C_PIM0_DATA_WIDTH-1:0]),
		  .PIM_WrFIFO_Flush	(PIM0_WrFIFO_Flush_i),
		  .PIM_WrFIFO_Push	(PIM0_WrFIFO_Push_i),
		  // Inputs
		  .Clk			(PIM0_Clk),
		  .PIM_AddrAck		(PIM0_AddrAck),
		  .PIM_InitDone		(PIM0_InitDone),
		  .PIM_RdFIFO_Data	(PIM0_RdFIFO_Data[C_PIM0_DATA_WIDTH-1:0]),
		  .PIM_RdFIFO_Empty	(PIM0_RdFIFO_Empty),
		  .PIM_RdFIFO_Latency	(PIM0_RdFIFO_Latency[1:0]),
		  .PIM_RdFIFO_RdWdAddr	(PIM0_RdFIFO_RdWdAddr[3:0]),
		  .PIM_WrFIFO_AlmostFull(PIM0_WrFIFO_AlmostFull),
		  .PIM_WrFIFO_Empty	(PIM0_WrFIFO_Empty),
		  .Rst			(~fpga_0_rst_1_sys_rst_pin));

  // END USER CODE (Do not remove this line)

endmodule

