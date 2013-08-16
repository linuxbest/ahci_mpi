-------------------------------------------------------------------------------
-- $Header: /devl/xcs/repo/env/Databases/ip2/processor/hardware/dcr_v29/dcr_v29_v1_00_b/hdl/src/vhdl/Attic/dcr_v29_wrp.vhd,v 1.1.4.1 2009/10/06 21:09:10 gburch Exp $
-------------------------------------------------------------------------------
--
-- *************************************************************************
-- **                                                                     **
-- ** DISCLAIMER OF LIABILITY                                             **
-- **                                                                     **
-- ** This text/file contains proprietary, confidential                   **
-- ** information of Xilinx, Inc., is distributed under                   **
-- ** license from Xilinx, Inc., and may be used, copied                  **
-- ** and/or disclosed only pursuant to the terms of a valid              **
-- ** license agreement with Xilinx, Inc. Xilinx hereby                   **
-- ** grants you a license to use this text/file solely for               **
-- ** design, simulation, implementation and creation of                  **
-- ** design files limited to Xilinx devices or technologies.             **
-- ** Use with non-Xilinx devices or technologies is expressly            **
-- ** prohibited and immediately terminates your license unless           **
-- ** covered by a separate agreement.                                    **
-- **                                                                     **
-- ** Xilinx is providing this design, code, or information               **
-- ** "as-is" solely for use in developing programs and                   **
-- ** solutions for Xilinx devices, with no obligation on the             **
-- ** part of Xilinx to provide support. By providing this design,        **
-- ** code, or information as one possible implementation of              **
-- ** this feature, application or standard, Xilinx is making no          **
-- ** representation that this implementation is free from any            **
-- ** claims of infringement. You are responsible for obtaining           **
-- ** any rights you may require for your implementation.                 **
-- ** Xilinx expressly disclaims any warranty whatsoever with             **
-- ** respect to the adequacy of the implementation, including            **
-- ** but not limited to any warranties or representations that this      **
-- ** implementation is free from claims of infringement, implied         **
-- ** warranties of merchantability or fitness for a particular           **
-- ** purpose.                                                            **
-- **                                                                     **
-- ** Xilinx products are not intended for use in life support            **
-- ** appliances, devices, or systems. Use in such applications is        **
-- ** expressly prohibited.                                               **
-- **                                                                     **
-- ** Any modifications that are made to the Source Code are              **
-- ** done at the user’s sole risk and will be unsupported.               **
-- ** The Xilinx Support Hotline does not have access to source           **
-- ** code and therefore cannot answer specific questions related         **
-- ** to source HDL. The Xilinx Hotline support of original source        **
-- ** code IP shall only address issues and questions related             **
-- ** to the standard Netlist version of the core (and thus               **
-- ** indirectly, the original core source).                              **
-- **                                                                     **
-- ** Copyright (c) 2003,2009 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- BEGIN_CHANGELOG EDK_Im_SP1
-- Updated Release For V5 Porting
-- END_CHANGELOG
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library dcr_v29_v1_00_b;
use dcr_v29_v1_00_b.all;

ENTITY dcr_v29_wrp IS

    -- Declare wrapper generic parameters here
            generic (
                C_DCR_NUM_SLAVES    : INTEGER  := 1;
                C_DCR_AWIDTH        : INTEGER  := 10;
                C_DCR_DWIDTH        : INTEGER  := 32;
                C_USE_LUT_OR        : INTEGER  := 1
                );

    -- Declare wrapper ports here
          port (
            -- Master outputs
            M_dcrABus           : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
            M_dcrDBus           : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
            M_dcrRead           : in  std_logic;
            M_dcrWrite          : in  std_logic;

            -- Master inputs
            DCR_M_DBus          : out std_logic_vector(0 to C_DCR_DWIDTH-1);
            DCR_Ack             : out std_logic;

            -- Slave inputs
            DCR_ABus            : out  std_logic_vector(0 to C_DCR_AWIDTH*C_DCR_NUM_SLAVES-1);
            DCR_Sl_DBus         : out  std_logic_vector(0 to C_DCR_DWIDTH*C_DCR_NUM_SLAVES-1);
            DCR_Read            : out  std_logic_vector(0 to C_DCR_NUM_SLAVES-1);
            DCR_Write           : out  std_logic_vector(0 to C_DCR_NUM_SLAVES-1);

            -- slave outputs
            Sl_dcrDBus          : in  std_logic_vector(0 to C_DCR_DWIDTH*C_DCR_NUM_SLAVES-1);
            Sl_dcrAck           : in  std_logic_vector(0 to C_DCR_NUM_SLAVES-1)
            );

END ENTITY dcr_v29_wrp;


architecture implementation of dcr_v29_wrp is

  COMPONENT dcr_v29 IS

    -- Declare generic parameters here
            generic (
                C_DCR_NUM_SLAVES    : integer;
                C_DCR_AWIDTH        : integer;
                C_DCR_DWIDTH        : integer;
                C_USE_LUT_OR        : integer
                );

    -- Declare ports here
          port (
            -- Master outputs
            M_dcrABus           : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
            M_dcrDBus           : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
            M_dcrRead           : in  std_logic;
            M_dcrWrite          : in  std_logic;

            -- Master inputs
            DCR_M_DBus          : out std_logic_vector(0 to C_DCR_DWIDTH-1);
            DCR_Ack             : out std_logic;

            -- Slave inputs
            DCR_ABus            : out  std_logic_vector(0 to C_DCR_AWIDTH*C_DCR_NUM_SLAVES-1);
            DCR_Sl_DBus         : out  std_logic_vector(0 to C_DCR_DWIDTH*C_DCR_NUM_SLAVES-1);
            DCR_Read            : out  std_logic_vector(0 to C_DCR_NUM_SLAVES-1);
            DCR_Write           : out  std_logic_vector(0 to C_DCR_NUM_SLAVES-1);

            -- slave outputs
            Sl_dcrDBus          : in  std_logic_vector(0 to C_DCR_DWIDTH*C_DCR_NUM_SLAVES-1);
            Sl_dcrAck           : in  std_logic_vector(0 to C_DCR_NUM_SLAVES-1)
            );

  END COMPONENT dcr_v29;

BEGIN -- architecture implementation

  dcr_v29_imp : dcr_v29

    GENERIC MAP (   -- Declare generic map here
            C_DCR_NUM_SLAVES            => C_DCR_NUM_SLAVES,
            C_DCR_AWIDTH                => C_DCR_AWIDTH,
            C_DCR_DWIDTH                => C_DCR_DWIDTH,
            C_USE_LUT_OR                => C_USE_LUT_OR
                )

    PORT MAP (      -- Declare port map here
            M_dcrABus                   => M_dcrABus,
            M_dcrDBus                   => M_dcrDBus,
            M_dcrRead                   => M_dcrRead,
            M_dcrWrite                  => M_dcrWrite,
            DCR_M_DBus                  => DCR_M_DBus,
            DCR_Ack                     => DCR_Ack,
            DCR_ABus                    => DCR_ABus,
            DCR_Sl_DBus                 => DCR_Sl_DBus,
            DCR_Read                    => DCR_Read,
            DCR_Write                   => DCR_Write,
            Sl_dcrDBus                  => Sl_dcrDBus,
            Sl_dcrAck                   => Sl_dcrAck
            );

END ARCHITECTURE implementation;
