--*******************************************************************
-- (c) Copyright 2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
--  All rights reserved.
--
--******************************************************************
--
-- Filename - ObjFifoAsyncDiffW.vhd
-- Creation -  2006/06/14
--
--
--*******************************************************************



-- *********************************************
--
--  *006*   Asynchronous Object FIFO
--
-- Description: FIFO with flags for Object control
-- Technology: RTL
--
-- Revision: 1.1
--
-- *********************************************
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

LIBRARY work;
USE work.memxlib_utils.ALL;

--------------------------------------------------------

entity ObjFifo_cons_ctl_async is
  generic(
      ASYNC_CLOCK       : boolean := TRUE; -- FALSE to remove metastability logic;
      OBJ_SIZE          : integer := 64;   -- Number of Data elements in Object
      AEMPTY_COUNT      : integer := 1;    -- Almost empty threshold
      NO_OBJS           : integer := 8     -- Number of Objects in FIFO
  );
  port(
    sclr : in std_logic                                                         -- Synchronous Clear/Reset.  Active High
      ; clk : in std_logic                                                      -- Consumer Clock Input
      ; AddrIn : in std_logic_vector (logbase2(OBJ_SIZE-1)-1 downto 0)          -- Consumer sub-object Address input
      ; ProdObjPtrIn    : in std_logic_vector(logbase2(NO_OBJS-1) downto 0)     -- Producer Object Pointer in. gray or bin
      ; ModeVal : in std_logic_vector (2 downto 0)                              -- Consumer Mode Input
      ; RamAddr : out std_logic_vector (logbase2(OBJ_SIZE*NO_OBJS-1)-1 downto 0)-- Consumer Ram Address Output
      ; RamMode : out std_logic_vector (1 downto 0)                             -- Consumer RAM Mode output
      ; Enab : out std_logic                                                    -- Consumer Enable. High when FIFO not empty
      ; AlmostEmpty : out std_logic                                             -- Consumer Almost Empty Output
      ; NumOfObjFilled : out std_logic_vector(logbase2(NO_OBJS-1) downto 0)     -- Consumer Number of Filled Objects in FIFO
      ; ConsObjPtrOut : out std_logic_vector (logbase2(NO_OBJS-1) downto 0)     -- Consumer Object Pointer out. gray or bin
  );
end ObjFifo_cons_ctl_async;
--------------------------------------------------------
architecture structure of ObjFifo_cons_ctl_async is

  --constant NO_OBJS_BITS : integer := logbase2(NO_OBJS);
  constant NO_OBJS_BITS : integer := 1 + logbase2(NO_OBJS-1);

  signal ObjPtr         : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal ObjPtr_e       : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  --signal ObjPtr_e2      : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal cmp_ObjPtr     : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal GrayObjPtr     : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal BinProdObjPtr  : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal BinProdObjPtr_comb  : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal cmp_BinProdObjPtr  : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal enable         : std_logic;
  
  signal ObjCount       : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal flip_msb       : std_logic;


  attribute SYN_PRESERVE        : boolean;
  attribute KEEP                : boolean;

  attribute SYN_PRESERVE of GrayObjPtr : signal is TRUE;
  attribute KEEP         of GrayObjPtr : signal is TRUE;

  attribute SYN_PRESERVE of BinProdObjPtr: signal is TRUE;
  attribute KEEP         of BinProdObjPtr: signal is TRUE;

  attribute SYN_PRESERVE of AlmostEmpty: signal is TRUE;
  attribute KEEP         of AlmostEmpty: signal is TRUE;

  attribute SYN_PRESERVE of ObjPtr_e : signal is TRUE;
  attribute KEEP         of ObjPtr_e : signal is TRUE;
  begin
    --------------------------------------------------------
    process (clk)
    begin
      if (clk'event and clk = '1') then
        if (sclr = '1') then
          ObjPtr   <= (others => '0');
          GrayObjPtr   <= (others => '0');
          ObjPtr_e   <= conv_std_logic_vector(1, ObjPtr_e'length);
          --ObjPtr_e2  <= conv_std_logic_vector(1, ObjPtr_e2'length);
        else

          -- ObjPtr update
          if(ModeVal(2) = '1') then
            if (ObjPtr_e(NO_OBJS_BITS-2 downto 0) >= (NO_OBJS-1)) then
              ObjPtr_e(NO_OBJS_BITS-1)            <= not ObjPtr_e(NO_OBJS_BITS-1);
              ObjPtr_e(NO_OBJS_BITS-2 downto 0)   <= (others => '0');
            else
              ObjPtr_e <= ObjPtr_e + 1;
            end if;
--            if (ObjPtr_e2(NO_OBJS_BITS-2 downto 0) >= (NO_OBJS-1)) then
--              ObjPtr_e2(NO_OBJS_BITS-1)            <= not ObjPtr_e2(NO_OBJS_BITS-1);
--              ObjPtr_e2(NO_OBJS_BITS-2 downto 0)   <= (others => '0');
--            else
--              ObjPtr_e2 <= ObjPtr_e2 + 1;
--            end if;

      -- delay chain
      ObjPtr <= ObjPtr_e;
      -- Gray Code
            --GrayObjPtr    <= ObjPtr_e2 xor ('0' & ObjPtr_e2(NO_OBJS_BITS-1 downto 1)); -- Gray code encode
            GrayObjPtr    <= ObjPtr_e xor ('0' & ObjPtr_e(NO_OBJS_BITS-1 downto 1)); -- Gray code encode
          end if;

          
        end if;
      end if;
    end process;
        

    --------------------------------------------------------
 
    -- enable / not empty
    process(GrayObjPtr, ProdObjPtrIn)
    --99process(ObjCounter, BinProdObjPtr)
    begin
      if(GrayObjPtr = ProdObjPtrIn) then
      --99if(ObjCounter = BinProdObjPtr) then
        enable <= '0';
      else
        enable <= '1';
      end if;
    end process;

    --------------------------------------------------------
    async_gen: if(ASYNC_CLOCK) generate 
      --GrayObjPtr    <= ObjPtr xor ('0' & ObjPtr(NO_OBJS_BITS-1 downto 1)); -- Gray code encode
      --99process (clk)
      --99begin
      --99  if (clk'event and clk = '1') then
      --99      GrayObjPtr    <= ObjCounter xor ('0' & ObjCounter(NO_OBJS_BITS-1 downto 1)); -- Gray code encode
      --99  end if;
      --99end process;
      
      ConsObjPtrOut <= GrayObjPtr;
    end generate async_gen;

    --------------------------------------------------------
    almost_gen: if(AEMPTY_COUNT >= 0) generate 

      almost_async_gen: if(ASYNC_CLOCK) generate

        BinProdObjPtr_comb(BinProdObjPtr_comb'length-1) <= ProdObjPtrIn(ProdObjPtrIn'length-1);
        GEN_BINPRODPTR: for i in ProdObjPtrIn'length-2 downto 0 generate
          BinProdObjPtr_comb(i) <= ProdObjPtrIn(i) xor BinProdObjPtr_comb(i+1);
        end generate GEN_BINPRODPTR;

        process(clk)
        begin
          if(clk'event and clk = '1') then
            BinProdObjPtr <= BinProdObjPtr_comb;
          end if;
        end process; 
      end generate almost_async_gen;

      process(ObjPtr(NO_OBJS_BITS-1),BinProdObjPtr(NO_OBJS_BITS-1))
      begin
        if ( (BinProdObjPtr(NO_OBJS_BITS-1) = '0') and (ObjPtr(NO_OBJS_BITS-1) = '1') )  then
          flip_msb <= '1';
        else
          flip_msb <= '0';
        end if;
      end process; 
      cmp_ObjPtr(NO_OBJS_BITS-1)          <= flip_msb xor ObjPtr(NO_OBJS_BITS-1);
      cmp_ObjPtr(NO_OBJS_BITS-2 downto 0) <= ObjPtr(NO_OBJS_BITS-2 downto 0);

      cmp_BinProdObjPtr(NO_OBJS_BITS-1)          <= flip_msb xor BinProdObjPtr(NO_OBJS_BITS-1);
      cmp_BinProdObjPtr(NO_OBJS_BITS-2 downto 0) <= BinProdObjPtr(NO_OBJS_BITS-2 downto 0);
      ObjCount <= cmp_BinProdObjPtr - cmp_ObjPtr;

      process(clk)
      begin
        if(clk'event and clk = '1') then
          if(sclr = '1') then
            NumOfObjFilled <= (others => '0');
          else
            NumOfObjFilled <= ObjCount;
          end if;
        end if;
      end process; 

      -- ProdObjPtrIn   = Write Ptr
      -- ObjPtr         = Read Ptr
      --almost_empty: process(ObjCount)
      --begin
      process(clk)
      begin
        if(clk'event and clk = '1') then
          if (ObjCount(logbase2(NO_OBJS-1) downto 0) <= AEMPTY_COUNT) then
              AlmostEmpty <= '1';
          else
              AlmostEmpty <= '0';
          end if;
        end if;
      end process;
    end generate almost_gen;

    --------------------------------------------------------
    Enab          <= enable;
    RamAddr       <= ObjPtr(NO_OBJS_BITS-2 downto 0) & AddrIn;
    
    RamModeComb: process (ModeVal) 
    begin
      if ModeVal(1 downto 0) = "01" then
        RamMode <= "01";
      else
        if ModeVal(1 downto 0) = "10" then
          RamMode <= "10";
        else
          RamMode <= "00";
        end if;
      end if;
    end process; 


end structure;

--------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

LIBRARY work;
USE work.memxlib_utils.ALL;

--------------------------------------------------------

entity ObjFifo_prod_ctl_async is
    generic(
      ASYNC_CLOCK       : boolean := TRUE; -- FALSE to remove metastability logic;
      OBJ_SIZE          : integer := 64;   -- Number of Data elements in Object
      AFULL_COUNT       : integer := 1;    -- Almost Full threshold
      NO_OBJS           : integer := 8     -- Number of Objects in FIFO
    );
    port(
      sclr              : in std_logic                                          -- Synchronous Clear/Reset input.  Active High
      ; clk             : in std_logic                                          -- Producer Clock Input
      ; AddrIn          : in std_logic_vector (logbase2(OBJ_SIZE-1)-1 downto 0) -- Producer sub-object Address Input
      ; ConsObjPtrIn    : in std_logic_vector(logbase2(NO_OBJS-1) downto 0)     -- Consumer Object Pointer in. gray or bin
      ; ModeVal         : in std_logic_vector (2 downto 0)                      -- Producer Mode Input
      ; RamAddr         : out std_logic_vector (logbase2(OBJ_SIZE*NO_OBJS-1)-1 downto 0) -- Producer RAM Address Output
      ; RamMode         : out std_logic_vector (1 downto 0)                     -- Producer RAM Mode Output
      ; Enab            : out std_logic                                         -- Producer not full Output.
      ; AlmostFull      : out std_logic                                         -- Producer Almost Full output. Active High
      ; NumOfObjAvail   : out std_logic_vector(logbase2(NO_OBJS-1) downto 0)    -- Number of Objects Available in FIFO
      ; ProdObjPtrOut   : out std_logic_vector (logbase2(NO_OBJS-1) downto 0)   -- Producer Object Pointer Out. gray or bin
    );
end ObjFifo_prod_ctl_async;

--------------------------------------------------------

architecture structure of ObjFifo_prod_ctl_async is
  
  --constant NO_OBJS_BITS : integer := logbase2(NO_OBJS);
  constant NO_OBJS_BITS : integer := 1 + logbase2(NO_OBJS-1);
  constant AFULL_NUM : integer := NO_OBJS-AFULL_COUNT-1;

  signal ObjPtr         : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal ObjPtr_e       : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal ObjPtr_e2      : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal cmp_ObjPtr     : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal GrayObjPtr     : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal BinConsObjPtr  : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal BinConsObjPtr_comb  : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal cmp_BinConsObjPtr  : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal full_ptr_val   : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal enable         : std_logic;

  signal ObjCount       : std_logic_vector (NO_OBJS_BITS-1 downto 0);
  signal flip_msb       : std_logic;

  attribute SYN_PRESERVE        : boolean;
  attribute KEEP                : boolean;
  --CJM 01.18.2010
  attribute maxdelay            : string;    

  attribute SYN_PRESERVE of GrayObjPtr : signal is TRUE;
  attribute KEEP         of GrayObjPtr : signal is TRUE;
  --CJM 01.18.2010
  attribute maxdelay of GrayObjPtr: signal is "2";  -- Defaults to ns

  attribute SYN_PRESERVE of NumOfObjAvail: signal is TRUE;
  attribute KEEP         of NumOfObjAvail: signal is TRUE;
  attribute SYN_PRESERVE of BinConsObjPtr: signal is TRUE;
  attribute KEEP         of BinConsObjPtr: signal is TRUE;
  attribute SYN_PRESERVE of AlmostFull: signal is TRUE;
  attribute KEEP         of AlmostFull: signal is TRUE;
  begin
    --------------------------------------------------------
    process (clk)
    begin
      if (clk'event and clk = '1') then
        if (sclr = '1') then
          ObjPtr <= (others => '0');
          GrayObjPtr   <= (others => '0');
          ObjPtr_e   <= conv_std_logic_vector(1, ObjPtr_e'length);
          --ObjPtr_e2  <= conv_std_logic_vector(1, ObjPtr_e2'length);
        else

          -- ObjPtr update
          --if (ModeVal = "11") then
          --if ((ModeVal(2) = '1') and (enable = '1')) then
          if (ModeVal(2) = '1') then
            if (ObjPtr_e(NO_OBJS_BITS-2 downto 0) >= (NO_OBJS-1)) then
              ObjPtr_e(NO_OBJS_BITS-1)            <= not ObjPtr_e(NO_OBJS_BITS-1);
              ObjPtr_e(NO_OBJS_BITS-2 downto 0)   <= (others => '0');
            else
              ObjPtr_e <= ObjPtr_e + 1;
            end if;
            --if (ObjPtr_e2(NO_OBJS_BITS-2 downto 0) >= (NO_OBJS-1)) then
            -- ObjPtr_e2(NO_OBJS_BITS-1)            <= not ObjPtr_e2(NO_OBJS_BITS-1);
            --  ObjPtr_e2(NO_OBJS_BITS-2 downto 0)   <= (others => '0');
            --else
            --  ObjPtr_e2 <= ObjPtr_e2 + 1;
            --end if;

      -- delay chain
      ObjPtr <= ObjPtr_e;
      -- Gray Code
            --GrayObjPtr    <= ObjPtr_e2 xor ('0' & ObjPtr_e2(NO_OBJS_BITS-1 downto 1)); -- Gray code encode
            GrayObjPtr    <= ObjPtr_e xor ('0' & ObjPtr_e(NO_OBJS_BITS-1 downto 1)); -- Gray code encode
          end if;

          
        end if;
      end if;
    end process;
        

    --------------------------------------------------------
    async_gen: if(ASYNC_CLOCK) generate 
      GEN_2OBJ: if (NO_OBJS_BITS = 2) generate
        full_ptr_val <=
                    not ConsObjPtrIn(1)
                  & ConsObjPtrIn(0 downto 0);
      end generate GEN_2OBJ;
      GEN_GT2OBJ: if (NO_OBJS_BITS > 2) generate
        full_ptr_val <=
                    not ConsObjPtrIn(NO_OBJS_BITS-1)
                  & not ConsObjPtrIn(NO_OBJS_BITS-2)
                  & ConsObjPtrIn(NO_OBJS_BITS-3 downto 0);
      end generate GEN_GT2OBJ;
 
      -- enable / not full
      process(GrayObjPtr, full_ptr_val)
      begin
            if (GrayObjPtr = full_ptr_val) then
              enable <= '0';
            else
              enable <= '1';
            end if;
      end process;
 
      --GrayObjPtr    <= ObjPtr xor ('0' & ObjPtr(NO_OBJS_BITS-1 downto 1)); -- Gray code encode

--99      process (clk)
--99      begin
--99        if (clk'event and clk = '1') then
--99          --if (sclr = '1') then
--99          --  GrayObjPtr <= (others => '0');
--99          --else
--99            GrayObjPtr    <= ObjCounter xor ('0' & ObjCounter(NO_OBJS_BITS-1 downto 1)); -- Gray code encode
--99          --end if;
--99        end if;
--99      end process;
      
      ProdObjPtrOut <= GrayObjPtr;

    end generate async_gen;

    --------------------------------------------------------
    sync_gen: if(not ASYNC_CLOCK) generate 
      -- enable / not full
      process(ObjPtr, ConsObjPtrIn)
      begin
            if (    (ObjPtr(NO_OBJS_BITS-1)          /= ConsObjPtrIn(NO_OBJS_BITS-1)) 
                and (ObjPtr(NO_OBJS_BITS-2 downto 0) = ConsObjPtrIn(NO_OBJS_BITS-2 downto 0)) 
               ) then
              enable <= '0';
            else
              enable <= '1';
            end if;
      end process;
      
      ProdObjPtrOut <= ObjPtr;
    end generate sync_gen;


    almost_gen: if(AFULL_COUNT >= 0) generate 
      almost_sync_gen: if(not ASYNC_CLOCK) generate
        BinConsObjPtr <= ConsObjPtrIn;
      end generate almost_sync_gen;

      almost_async_gen: if(ASYNC_CLOCK) generate
        BinConsObjPtr_comb(BinConsObjPtr_comb'length-1) <= ConsObjPtrIn(ConsObjPtrIn'length-1);
        GEN_BINCONSPTR: for i in ConsObjPtrIn'length-2 downto 0 generate
          BinConsObjPtr_comb(i) <= ConsObjPtrIn(i) xor BinConsObjPtr_comb(i+1);
        end generate GEN_BINCONSPTR;

        process(clk)
        begin
          if(clk'event and clk = '1') then
            BinConsObjPtr <= BinConsObjPtr_comb;
          end if;
        end process; 
      end generate almost_async_gen;

      process(ObjPtr(NO_OBJS_BITS-1),BinConsObjPtr(NO_OBJS_BITS-1))
      begin
        if ( (BinConsObjPtr(NO_OBJS_BITS-1) = '1') and (ObjPtr(NO_OBJS_BITS-1) = '0') )  then
          flip_msb <= '1';
        else
          flip_msb <= '0';
        end if;
      end process; 
      cmp_ObjPtr(NO_OBJS_BITS-1)          <= flip_msb xor ObjPtr(NO_OBJS_BITS-1);
      cmp_ObjPtr(NO_OBJS_BITS-2 downto 0) <= ObjPtr(NO_OBJS_BITS-2 downto 0);

      cmp_BinConsObjPtr(NO_OBJS_BITS-1)          <= flip_msb xor BinConsObjPtr(NO_OBJS_BITS-1);
      cmp_BinConsObjPtr(NO_OBJS_BITS-2 downto 0) <= BinConsObjPtr(NO_OBJS_BITS-2 downto 0);
      --ObjCount <= cmp_ObjPtr - cmp_BinConsObjPtr;
      ObjCount <= cmp_ObjPtr - cmp_BinConsObjPtr - 1;

      process(clk)
      begin
        if(clk'event and clk = '1') then
          --if(sclr = '1') then
          --  NumOfObjAvail <= conv_std_logic_vector(NO_OBJS-1,NumOfObjAvail'length);
          --else
          --  NumOfObjAvail <= not ObjCount(logbase2(NO_OBJS-1)-1 downto 0);
          --end if;
          NumOfObjAvail(NumOfObjAvail'high) <= ObjCount(ObjCount'high);
          NumOfObjAvail(NumOfObjAvail'high-1 downto 0) <= not ObjCount(logbase2(NO_OBJS-1)-1 downto 0);
        end if;
      end process; 


      -- ObjPtr = Write Ptr
      -- ConsObjPtrIn = Read Ptr
      --almost_full: process(ObjCount)
      --begin
      process(clk)
      begin
        if(clk'event and clk = '1') then
          --if (ObjCount >= AFULL_NUM) then
          if ((ObjCount(ObjCount'high) /= '1') and (ObjCount(logbase2(NO_OBJS-1)-1 downto 0) >= AFULL_NUM)) then
              AlmostFull <= '1';
          else
              AlmostFull <= '0';
          end if;
        end if;
      end process; 
    end generate almost_gen;

    no_almost_gen: if(AFULL_COUNT = 0) generate 
        AlmostFull <= not enable;
    end generate no_almost_gen;
    --------------------------------------------------------
    Enab          <= enable;
    RamAddr       <= ObjPtr(NO_OBJS_BITS-2 downto 0) & AddrIn;
    
    RamModeComb: process (ModeVal) 
    begin
      if ModeVal(1 downto 0) = "01" then
        RamMode <= "01";
      else
        if ModeVal(1 downto 0) = "10" then
          RamMode <= "10";
        else
          RamMode <= "00";
        end if;
      end if;
    end process; 


  end structure;

--------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

LIBRARY work;
USE work.memxlib_utils.ALL;

entity ObjFifoAsyncDiffW is
  generic(
    FAMILY         : string := "S3";            -- Device Family, "S3", or "V4"
    DATA_BITS_PROD : integer := 8;              -- Producer Side Data Width (must be a multiple-of-2 * cons data width)
    DATA_BITS_CONS : integer := 32;             -- Consumer Side Data Width (must be a multiple-of-2 * prod data width)
    NO_OBJS        : integer := 8;              -- FIFO Depth in Number of Objects
    OBJ_SIZE_PROD  : integer := 64;             -- Number of Data Elements within Producer Object
    OBJ_SIZE_CONS  : integer := 16;             -- Number of Data Elements within Consumer Object
    ASYNC_CLOCK    : boolean := TRUE;           -- FALSE to remove metastability logic;
    AEMPTY_COUNT   : integer := 1;              -- Consumer Side: Number of filled Objects during which to assert Almost Empty Flag
    AFULL_COUNT    : integer := 1;              -- Producer Side: Number of empty Objects during which to assert Almost Full Flag
    AUTO_PRODUCER : boolean := FALSE;           -- TRUE to generate ProdA and ProdCommit internally
    AUTO_CONSUMER : boolean := FALSE;           -- TRUE to generate ConsA and ConsRelease internally 

    MEM_TYPE       : string := BLOCK_RAMSTYLE   -- "no_rw_check" = Block Ram, 
                                                -- "select_ram" = Distributed RAM, 
                                                -- "registers" = Register RAM, 
                                                -- "no_rw_check, area" = Block Ram, area optimized
  );
  port(
    sclr : in std_logic;                                                        -- Synchronous Clear/Reset Input. Active High
    Prod_Clk : in std_logic;                                                    -- Producer Clock Input
    Cons_Clk : in std_logic;                                                    -- Consumer Clock Input

    Prod_Full : out std_logic;                                                  -- Producer Full Flag output.  Active High
    Prod_NumObjAvail : out std_logic_vector(logbase2(NO_OBJS-1) downto 0);      -- Producer Number of Object Available in FIFO
    Prod_AlmostFull: out std_logic;                                             -- Producer Almost Full Flag Output.  Active HIgh
    Prod_Write  : in std_logic;                                                 -- Producer Write Enable Input. Active High
    Prod_Read   : in std_logic := '0';                                          -- Producer Read Enable Input. Active High
    Prod_Commit : in std_logic := '0';                                          -- Producer Object Commit Input.  Active High
    Prod_A : in std_logic_vector (logbase2(OBJ_SIZE_PROD-1)-1 downto 0) := (others => '0'); -- Producer sub-object Address
    Prod_D : in std_logic_vector (DATA_BITS_PROD-1 downto 0);                   -- Producer Data Input
    Prod_Q : out std_logic_vector (DATA_BITS_PROD-1 downto 0);                  -- Producer Data Output

    Cons_Empty : out std_logic;                                                 -- Consumer Empty Flag Output. Active high
    Cons_NumObjFilled : out std_logic_vector(logbase2(NO_OBJS-1) downto 0);     -- Consumer Number of Objects Filled in FIFO
    Cons_AlmostEmpty: out std_logic;                                            -- Consumer Almost Empty Flag Output. Active High
    Cons_Write   : in std_logic := '0';                                         -- Consumer Write Enable Input. Active High
    Cons_Read    : in std_logic := '1';                                         -- Consumer Read Enable Input. Active High
    Cons_Release : in std_logic := '0';                                         -- Consumer Object Release Input. Active High
    Cons_A : in std_logic_vector (logbase2(OBJ_SIZE_CONS-1)-1 downto 0) := (others => '0'); -- Consumer sub-object Address input
    Cons_D : in std_logic_vector (DATA_BITS_CONS-1 downto 0) := (others => '0');-- Consumer Data Input
    Cons_Q : out std_logic_vector (DATA_BITS_CONS-1 downto 0)                   -- Consumer Data Output
  );
end ObjFifoAsyncDiffW;

--------------------------------------------------------

architecture rtl of ObjFifoAsyncDiffW is


  -- JLH: Attribute declarations
  attribute SYN_PRESERVE        : boolean;
  attribute KEEP                : boolean;
  attribute maxdelay            : string;    
  attribute syn_keep            : boolean; 

  constant MEM_ADDR_BITS_PROD   : integer := logbase2(OBJ_SIZE_PROD*NO_OBJS-1);
  constant MEM_ADDR_BITS_CONS   : integer := logbase2(OBJ_SIZE_CONS*NO_OBJS-1);
  --constant NO_OBJS_BITS         : integer := logbase2(NO_OBJS);
  constant NO_OBJS_BITS : integer := 1 + logbase2(NO_OBJS-1);

  signal ObjFifo_ram_M1 : std_logic_vector (1 downto 0) ;
  signal ObjFifo_ram_A1 : std_logic_vector (MEM_ADDR_BITS_PROD-1 downto 0) ;
  signal ObjFifo_ram_M2 : std_logic_vector (1 downto 0) ;
  signal ObjFifo_ram_A2 : std_logic_vector (MEM_ADDR_BITS_CONS-1 downto 0) ;

  -- JLH: Timing constraints added
  signal ConsObjPtr     : std_logic_vector(NO_OBJS_BITS-1 downto 0);
  attribute syn_keep of ConsObjPtr : signal is true;
  attribute maxdelay of ConsObjPtr : signal is "2";  -- Defaults to ns
  
  -- JLH: Timing constraints added
  signal ProdObjPtr     : std_logic_vector(NO_OBJS_BITS-1 downto 0);
  attribute syn_keep of ProdObjPtr : signal is true;
  attribute maxdelay of ProdObjPtr : signal is "2";  -- Defaults to ns

  type sync_array is array (1 downto 0) of std_logic_vector(NO_OBJS_BITS-1 downto 0);
  signal ConsObjPtr_sync2prod     : sync_array;
  signal ProdObjPtr_sync2cons     : sync_array;

  signal addra          : std_logic_vector(MEM_ADDR_BITS_PROD-1 downto 0);
  signal addrb          : std_logic_vector(MEM_ADDR_BITS_CONS-1 downto 0);
  signal da,qa          : std_logic_vector(DATA_BITS_PROD-1 downto 0);
  signal db,qb          : std_logic_vector(DATA_BITS_CONS-1 downto 0);
  signal ena,enb,wea,web: std_logic;
 

  signal Prod_Enable    : std_logic;
  signal Cons_Enable    : std_logic;
  signal Prod_M         : std_logic_vector(2 downto 0);
  signal Cons_M         : std_logic_vector(2 downto 0);

  signal prod_commit_int        : std_logic;
  signal cons_release_int       : std_logic;

  signal prod_last    : std_logic;
  signal cons_last    : std_logic;

  signal prod_commit_intOrExt   : std_logic;
  signal cons_release_intOrExt  : std_logic;

  signal prod_a_int : std_logic_vector(logbase2(OBJ_SIZE_PROD-1)-1 downto 0);
  signal cons_a_int : std_logic_vector(logbase2(OBJ_SIZE_CONS-1)-1 downto 0);

  attribute SYN_PRESERVE of ConsObjPtr_sync2prod : signal is TRUE;
  attribute KEEP         of ConsObjPtr_sync2prod : signal is TRUE;

  attribute SYN_PRESERVE of ProdObjPtr_sync2cons : signal is TRUE;
  attribute KEEP         of ProdObjPtr_sync2cons : signal is TRUE;

  signal prod_sclr_d : std_logic_vector(1 downto 0);
  signal prod_sclr   : std_logic;
  signal cons_sclr_d : std_logic_vector(1 downto 0);
  signal cons_sclr   : std_logic;

  attribute SYN_PRESERVE of cons_sclr_d : signal is TRUE;
  attribute KEEP         of cons_sclr_d : signal is TRUE;
  attribute SYN_PRESERVE of prod_sclr_d : signal is TRUE;
  attribute KEEP         of prod_sclr_d : signal is TRUE;
  attribute maxdelay     of sclr        : signal is "2";  -- Defaults to ns

  begin

  prod_commit_intorext  <= prod_commit_int or prod_commit;
  cons_release_intorext <= cons_release_int or cons_release;

  Prod_Full     <= not Prod_Enable;
  Cons_Empty    <= not Cons_Enable;
  Prod_M        <= prod_commit_intOrExt & Prod_Write & Prod_Read when (Prod_enable='1') else "000";
  Cons_M        <= cons_release_intOrExt & Cons_Write & Cons_Read when (Cons_Enable = '1') else "000" ;

  -- conversion of left port
  ena <= '1' when ObjFifo_ram_M1 = "01" else
         '1' when ObjFifo_ram_M1 = "10" else
         '0';

  wea <= '1' when ObjFifo_ram_M1 = "10" else
         '0';
  addra  <= ObjFifo_ram_A1;
  da  <= Prod_D;
  Prod_Q <= qa;

  -- conversion of right port
  enb <= '1' when ObjFifo_ram_M2 = "01" else
         '1' when ObjFifo_ram_M2 = "10" else
         '0';

  web <= '1' when ObjFifo_ram_M2 = "10" else
         '0';
  addrb  <= ObjFifo_ram_A2;
  db  <= Cons_D;
  Cons_Q <= qb;

  memory0: entity work.dp_ram_async_diffw(ramb)
    generic map( 
            FAMILY    => FAMILY,            
            dwidtha   => DATA_BITS_PROD, 
            dwidthb   => DATA_BITS_CONS, 
            input_reg => 0,
            mem_sizea => NO_OBJS*OBJ_SIZE_PROD, 
            mem_sizeb => NO_OBJS*OBJ_SIZE_CONS, 
            mem_type  => MEM_TYPE )
    port map(
        -- Port A 
        da    => da,
        addra => addra,
        wea   => wea,
        qa    => qa,
        clka  => Prod_Clk,
        -- Port B 
        db    => db,
        addrb => addrb,
        web   => web,
        qb    => qb,
        clkb  => Cons_Clk
        );


    ObjFifo_prod_ctl_comp : entity work.ObjFifo_prod_ctl_async
      generic map(
          ASYNC_CLOCK    => ASYNC_CLOCK,
          OBJ_SIZE       => OBJ_SIZE_PROD,
          AFULL_COUNT    => AFULL_COUNT,
          NO_OBJS        => NO_OBJS
      )
      port map (
      sclr => prod_sclr 
    , clk => Prod_Clk
    , AddrIn => prod_a_int
    , ConsObjPtrIn => ConsObjPtr_sync2prod(ConsObjPtr_sync2prod'length-1)
    , ModeVal => Prod_M
    , RamAddr => ObjFifo_ram_A1
    , RamMode => ObjFifo_ram_M1
    , Enab => Prod_Enable 
    , AlmostFull => Prod_AlmostFull
    , NumOfObjAvail => Prod_NumObjAvail
    , ProdObjPtrOut => ProdObjPtr
    );
 
    async_gen: if(ASYNC_CLOCK) generate 
        -- Sync write pointer to read clock domain
          write_address_sync: process(Prod_Clk)
          begin
            if(Prod_Clk'event and Prod_Clk = '1') then
              ConsObjPtr_sync2prod <= ConsObjPtr_sync2prod(ConsObjPtr_sync2prod'length-2 downto 0) & ConsObjPtr;
            end if;
          end process;


        -- Sync read pointer to write clock domain
          read_address_sync: process(Cons_Clk)
          begin
            if(Cons_Clk'event and Cons_Clk = '1') then
              ProdObjPtr_sync2cons <= ProdObjPtr_sync2cons(ProdObjPtr_sync2cons'length-2 downto 0) & ProdObjPtr;
           end if;
         end process;
    end generate async_gen;

    sync_gen: if(not ASYNC_CLOCK) generate 
        ConsObjPtr_sync2prod(ConsObjPtr_sync2prod'length-1) <= ConsObjPtr;
        ProdObjPtr_sync2cons(ProdObjPtr_sync2cons'length-1) <= ProdObjPtr;
    end generate sync_gen;

    ObjFifo_cons_ctl_comp : entity work.ObjFifo_cons_ctl_async(structure)
      generic map(
          ASYNC_CLOCK    => ASYNC_CLOCK,
          OBJ_SIZE       => OBJ_SIZE_CONS,
          AEMPTY_COUNT   => AEMPTY_COUNT,
          NO_OBJS        => NO_OBJS
      )
      port map (
      sclr => cons_sclr
    , clk => Cons_Clk
    , AddrIn => cons_a_int
    , ProdObjPtrIn => ProdObjPtr_sync2cons(ProdObjPtr_sync2cons'length-1)
    , ModeVal => Cons_M
    , RamAddr => ObjFifo_ram_A2
    , RamMode => ObjFifo_ram_M2
    , Enab => Cons_Enable
    , AlmostEmpty => Cons_AlmostEmpty
    , NumOfObjFilled => Cons_NumObjFilled
    , ConsObjPtrOut => ConsObjPtr
    );


    auto_prod_gen: if(AUTO_PRODUCER) generate 
      process(prod_clk)
      begin
        if(prod_clk'event and prod_clk = '1') then
          if(prod_sclr = '1') then
            prod_a_int          <= (others => '0');
            --prod_commit_int     <= '0';
      prod_last <= '0';
          else
      if(Prod_M(0) = '1') then
              if(prod_a_int = (OBJ_SIZE_PROD-2)) then
          prod_last <= '1';
        else
          prod_last <= '0';
        end if;
      end if;

            --if(prod_commit = '1') then
            if(Prod_M(2) = '1') then
              prod_a_int        <= (others => '0');
              --prod_commit_int   <= '0';
        
            elsif(Prod_M(1) = '1') then
              prod_a_int <= prod_a_int + 1;

              --if(prod_a_int = (OBJ_SIZE_PROD-2)) then
              --  prod_commit_int <= '1';
              --else
              --  prod_commit_int <= '0';
              --end if;
            end if;
          end if;
        end if;
      end process;

      prod_commit_int <= '1' when((prod_a_int = (OBJ_SIZE_PROD-1)) and (Prod_M(1) = '1')) else '0';
      --prod_commit_int <= '1' when((prod_last = '1') and (Prod_M(1) = '1')) else '0';

    end generate auto_prod_gen;

    non_auto_prod_gen: if(not AUTO_PRODUCER) generate 
      prod_a_int        <= Prod_A;    
      prod_commit_int   <= '0';
    end generate non_auto_prod_gen;

      process(cons_clk)
      begin
        if(cons_clk'event and cons_clk = '1') then
    cons_sclr_d <= cons_sclr_d(cons_sclr_d'high-1 downto 0) & sclr;
        end if;
      end process;
      cons_sclr <= cons_sclr_d(cons_sclr_d'high);

      process(prod_clk)
      begin
        if(prod_clk'event and prod_clk = '1') then
    prod_sclr_d <= prod_sclr_d(prod_sclr_d'high-1 downto 0) & sclr;
        end if;
      end process;
      prod_sclr <= prod_sclr_d(prod_sclr_d'high);

    auto_cons_gen: if(AUTO_CONSUMER) generate 
      process(cons_clk)
      begin
        if(cons_clk'event and cons_clk = '1') then
          if(cons_sclr = '1') then
            cons_a_int          <= (others => '0');
            --cons_release_int    <= '0';
      cons_last  <= '0';
          else  
      if(Cons_M(0) = '1') then
              if(cons_a_int = (OBJ_SIZE_CONS-2)) then
          cons_last <= '1';
        else
          cons_last <= '0';
        end if;
      end if;

            --if(cons_release = '1') then
            if(Cons_M(2) = '1') then
              cons_a_int        <= (others => '0');
              --cons_release_int  <= '0';
        
            elsif(Cons_M(0) = '1') then
              cons_a_int <= cons_a_int + 1;

              --if(cons_a_int = (OBJ_SIZE_CONS-2)) then
              --  cons_release_int <= '1';
              --else
              --  cons_release_int <= '0';
              --end if;
            end if;
          end if;
        end if;
      end process;

      cons_release_int <= '1' when((cons_a_int = (OBJ_SIZE_CONS-1)) and (Cons_M(0) = '1')) else '0';
      --cons_release_int <= '1' when((cons_last = '1') and (Cons_M(0) = '1')) else '0';

    end generate auto_cons_gen;

    non_auto_cons_gen: if(not AUTO_CONSUMER) generate 
      cons_a_int        <= Cons_A;    
      cons_release_int  <= '0';
    end generate non_auto_cons_gen;

  end rtl;
