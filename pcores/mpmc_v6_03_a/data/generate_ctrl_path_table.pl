#! /usr/local/gnu/bin/perl5 -w
##-----------------------------------------------------------------------------
##-- (c) Copyright 2006 - 2009 Xilinx, Inc. All rights reserved.
##--
##-- This file contains confidential and proprietary information
##-- of Xilinx, Inc. and is protected under U.S. and
##-- international copyright and other intellectual property
##-- laws.
##--
##-- DISCLAIMER
##-- This disclaimer is not a license and does not grant any
##-- rights to the materials distributed herewith. Except as
##-- otherwise provided in a valid license issued to you by
##-- Xilinx, and to the maximum extent permitted by applicable
##-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
##-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
##-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
##-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
##-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
##-- (2) Xilinx shall not be liable (whether in contract or tort,
##-- including negligence, or under any other theory of
##-- liability) for any loss or damage of any kind or nature
##-- related to, arising under or in connection with these
##-- materials, including for any direct, or any indirect,
##-- special, incidental, or consequential loss or damage
##-- (including loss of data, profits, goodwill, or any type of
##-- loss or damage suffered as a result of any action brought
##-- by a third party) even if such damage or loss was
##-- reasonably foreseeable or Xilinx had been advised of the
##-- possibility of the same.
##--
##-- CRITICAL APPLICATIONS
##-- Xilinx products are not designed or intended to be fail-
##-- safe, or for use in any application requiring fail-safe
##-- performance, such as life-support or safety devices or
##-- systems, Class III medical devices, nuclear facilities,
##-- applications related to the deployment of airbags, or any
##-- other applications that could lead to death, personal
##-- injury, or severe property or environmental damage
##-- (individually and collectively, "Critical
##-- Applications"). Customer assumes the sole risk and
##-- liability of any use of Xilinx products in Critical
##-- Applications, subject only to applicable laws and
##-- regulations governing limitations on product liability.
##--
##-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
##-- PART OF THIS FILE AT ALL TIMES.
##-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# Purpose: This program generates a text file that describes the MPMC Control 
#          Path BRAM contents.
#
#-----------------------------------------------------------------------------
# History: 
#   08/10/2005: Initial Version
#   01/17/2006: Complete re-write to clean up and allow for DDR2 corrections
#   01/25/2006: Needed to add a plus 1 to the DDR2 Ctrl_DP_RdFIFO_Push delay. 
#   02/07/2006: Needed to add a plus 1 to C_CTRL_DP_RDFIFO_WHICHPORT_DELAY.
#   07/18/2006: Added command line parameters tRASmax, nRRD, nCCD and tWTR.  
#               tWTR is not used since we don't do any write to reads. 
#               Use strict has been enabled (requiring us to also use Symbol 
#               for filehandles.)  --CC
#   09/05/2006: The plus 1 for DDR2 Ctrl_DP_RdFIFO_Push delay and 
#               C_CTRL_DP_RDFIFO_WHICHPORT_DELAY in DDR2 designs and lack of 
#               the plus 1 in DDR designs will not always be correct.  
#               Frequency, board trace length, and other parameters may affect
#               this.  See release notes for details.
#   09/05/2006: Added extra bit to control path bram state machine to support
#               DDR2 ODT.
#   12/12/2006: Made modifications to use new V5 MIG Phy IF.
#               Removed initialization sequence.
#               We will need to review the DQS_O and rdfifo_push delays if we
#               decide to remove the address path pipeline stages.
#   02/23/2007: Made modifications to correct delays for new MIG phy.
#   03/12/2007: Added ECC support.
#   05/07/2007: Added future support for mpmc3
#   03/10/2009: Added DDR3 Support and refactored code.
#   01/29/2010: Added ZQCS command for DDR3 
#
#--------------------------------------------------------------------------
#
# General Rules:
#   1. Read sequences are:    Activate,  Read,   Precharge
#   2. Write sequences are:   Activate,  Write,  Precharge
#   3. Refresh sequences are: Precharge, Refresh
#   4. NOP seqences have a minimum length of 6 and do not use the 
#      complete signal.
#   5. The complete signal must be asserted on the 6th to last element of
#      a sequence.
#
# DDR Read Rules:
#   1. Activate to Read has minimum length of nRCD.
#   2. Read to Precharge has a minimum length of num_data_beats.
#   3. Activate to Precharge has a minimum length of nRAS
#   4. Precharge to Activate has a minimum length of nRP.
#   5. Activate to Activate has a minimum length of max(nRC, nRRD).
#
# DDR Write Rules:
#   1. Activate to Write has minimum length of nRCD.
#   2. Write to Precharge has a minimum length of nDQSS + num_data_beats + nWR.
#   3. Activate to Precharge has a minimum length of nRAS
#   4. Precharge to Activate has a minimum length of nRP.
#   5. Activate to Activate has a minimum length of max(nRC, nRRD).
#
# DDR Refresh Rules:
#   1. Precharge to Refresh has a minimum length of nRP.
#   2. Refresh to Activate has a minimum length of nRFC.
#
# DDR2 Read Rules:
#   1. Activate to Read has minimum length of nRCD - nAL.
#   2. Read to Precharge has a minimum length of 
#      nAL + burst_length/2 + nRTP - 2 clocks.
#   3. Activate to Precharge has a minimum length of nRAS
#   4. Precharge to Activate has a minimum length of nRPA.
#   5. Activate to Activate has a minimum length of max(nRC, nRRD).
#
# DDR2 Write Rules:
#   1. Activate to Write has minimum length of nRCD.
#   2. Write to Precharge has a minimum length of 
#      WL + max(burst_length/2, num_data_beats) + nWR.
#   3. Activate to Precharge has a minimum length of nRAS
#   4. Precharge to Activate has a minimum length of nRPA.
#   5. Activate to Activate has a minimum length of max(nRC, nRRD).
#
# DDR2 Refresh Rules:
#   1. Precharge to Refresh has a minimum length of nRPA.
#   2. Refresh to Activate has a minimum length of nRFC.
#
#
#
#--------------------------------------------------------------------------
use POSIX qw(ceil floor);
use strict;
use Symbol;
use Getopt::Long;

# Function Prototypes
# Helper Functions
sub display_help();
sub max($$);
sub bin2dec($);
sub dec2bin($);
sub parameter_error($$);
sub rotate_string_left($$);
sub rotate_string_right($$);
# State machine generation function prototypes
sub activate_to_cmd($$$$$);
sub activate_to_read($$$$);
sub activate_to_write($);
sub read_to_precharge($$$$$$);
sub write_to_precharge($$$$$$);
sub precharge_to_activate($);
sub precharge_to_refresh($);
sub refresh_to_activate($);
sub nop($);

#Define Constants
use constant SEQ_WRITE_OP           => '0';
use constant SEQ_READ_OP            => '1';

use constant SEQ_WORD_WRITE         => '0';
use constant SEQ_WORD_READ          => '1';
use constant SEQ_DWORD_WRITE        => '2';
use constant SEQ_DWORD_READ         => '3';
use constant SEQ_CL4_WRITE          => '4';
use constant SEQ_CL4_READ           => '5';
use constant SEQ_CL8_WRITE          => '6';
use constant SEQ_CL8_READ           => '7';
use constant SEQ_B16_WRITE          => '8';
use constant SEQ_B16_READ           => '9';
use constant SEQ_B32_WRITE          => '10';
use constant SEQ_B32_READ           => '11';
use constant SEQ_B64_WRITE          => '12';
use constant SEQ_B64_READ           => '13';
use constant SEQ_REFRESH            => '14';
use constant SEQ_NOP                => '15';
use constant SEQ_ZQCS               => '16';

use constant BRAM_WIDTH             => '36';

# Ctrl Interface Signals
# Common between DFI and PHYIF
use constant CTRL_COMPLETE              => '0';
use constant CTRL_IS_WRITE              => '1';
use constant CTRL_AP_COL_CNT_LOAD       => '12';
use constant CTRL_AP_COL_CNT_ENABLE     => '13';
use constant CTRL_AP_PRECHARGE_ADDR10   => '14';
use constant CTRL_AP_ROW_COL_SEL        => '15';
use constant CTRL_REPEAT4               => '17';

# PHYIF Mapping
use constant CTRL_PHYIF_RAS_N           => '2';
use constant CTRL_PHYIF_CAS_N           => '3';
use constant CTRL_PHYIF_WE_N            => '4';
use constant CTRL_RMW                   => '6';
use constant CTRL_SKIP_0                => '7';
use constant CTRL_PHYIF_DQS_O           => '8';
use constant CTRL_SKIP_1                => '9';
use constant CTRL_DP_RDFIFO_PUSH        => '10';
use constant CTRL_SKIP_2                => '11';
use constant CTRL_PHYIF_FORCE_DM        => '16';
# DFI Mapping
use constant CTRL_DFI_RAS_N_0         => '2';
use constant CTRL_DFI_CAS_N_0         => '3';
use constant CTRL_DFI_WE_N_0          => '4';
use constant CTRL_DP_WRFIFO_POP       => '8';
use constant CTRL_DFI_WRDATA_EN       => '18';
use constant CTRL_DFI_RDDATA_EN       => '19';
use constant CTRL_DFI_RAS_N_1         => '20';
use constant CTRL_DFI_CAS_N_1         => '21';
use constant CTRL_DFI_WE_N_1          => '22';
use constant CTRL_AP_OTF_ADDR12       => '23';

# setup some global variables
my @Ctrl_Table;
my $Use_DFI;
sub display_help() { 
    print "Usage: perl generate_ctrl_path_table.pl [-options]\n";
    print "         -h                  : help\n";
    print "         -f_txt filename.txt : text output filename\n";
    print "         -f_ver filename.v   : verilog output filename\n";
    print "         -f_err filename.txt : Error log output filename\n";
    print "         -c value            : clock period in picoseconds\n";
    print "         -tRAS value         : value of tRAS  in ps\n";
    print "         -tRCD value         : value of tRCD  in ps\n";
    print "         -tRC value          : value of tRC   in ps\n";
    print "         -tRRD value         : value of tRRD  in ps\n";
    print "         -tWR value          : value of tWR   in ps\n";
    print "         -tRP value          : value of tRP   in ps\n";
    print "         -tRFC value         : value of tRFC  in ps\n";
    print "         -tWTR value         : value of tWTR  in ps\n";
    print "         -cas_latency integer: Memory CAS Latency\n";
    print "         -cas_wr_latency integer: Memory CAS Write Latency\n";
    print "         -reg value          : 1 = memory registered, 0 = memory unbuffered\n";
    print "         -d value            : Size of memory data width in bits\n";
    print "         -part_data_width    : Data width of the part\n";
    print "         -m type             : type of memory -- sdram, ddr, ddr2, or ddr3\n";
    print "         -memory_burst_length value : Memory burst length -- 2, 4, or 8\n";
    print "         -nDQSS value        : value of nDQSS in clks, DDR only\n";
    print "         -nAL value          : value of nAL   in clks, DDR2/3 only\n";
    print "         -tRTP value         : value of tRTP  in ps, DDR2/3 only\n";
    print "         -nCCD value         : value of nCCD  in clks, DDR2/3 only\n";
    print "         -enable_ecc         : 1 -> ECC; 0 -> No ECC\n";
    print "         -static_phy         : 1 -> Static Phy; 0 -> No Static Phy\n";
    print "         -wr_mem_pipeline    : Write FIFO Memory Pipeline Enabled\n";
    print "         -family             : Family name\n";
    exit 0;
}

sub max($$) {
    my $val0 = $_[0];
    my $val1 = $_[1];
    my $result = 0;
    $result = ($val0 > $val1) ? $val0 : $val1;
    return ($result);
}

sub bin2dec($) {
   my $temp = $_[0];
   my $result = 0;
   my $addfactor = 1;
   while ($temp ne "") {
      if (substr($temp, length($temp)-1, 1)) { $result += $addfactor; }
      $addfactor *= 2;
      $temp = substr($temp, 0, length($temp)-1);
   }
   return ($result);
}

sub dec2bin($) {
   my $temp = $_[0];
   my $result = "";
   my $divfactor = 32768;
   foreach my $k (1 .. 16) {
      if (int($temp/$divfactor)) { $result = $result."1"; $temp -= $divfactor; }
      else                       { $result = $result."0"; }
      $divfactor /= 2;
   }
   return ($result);
}

sub parameter_error($$) { 

    my $param = $_[0];
    my $fh = $_[1];

    print "Error: Parameter $param is missing\n";
    print $fh "Error: Parameter $param is missing\n";
}

sub rotate_string_left($$) { 

    my $string = $_[0];
    my $shift_by = $_[1];

    if (length($string) <= $shift_by) { 
        die "Error creating table, can't shift bit string $string by $shift_by.";
    }

    $string =~ s/(.{$shift_by})(.*)/$2$1/;

    return $string;
}

sub rotate_string_right($$) { 

    my $string = $_[0];
    my $shift_by = $_[1];

    if (length($string) <= $shift_by) { 
        die "Error creating table, can't shift bit string $string by $shift_by.";
    }

    $string =~ s/(.*)(.{$shift_by})/$2$1/;

    return $string;
}

# Activate sequence up to either read/write cmd
sub activate_to_cmd($$$$$) { 
    # Inputs
    my ($length, 
        $skip_0, 
        $skip_1, 
        $skip_2, 
        $skip_from_cmd
    ) = @_;

    my @table;

    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = '';
    }

    for (my $i = 0; $i < $length; $i++) { 
        for (my $row = 0; $row < BRAM_WIDTH; $row++) { 

            # default to inactive 
            my $val = $Ctrl_Table[$row]{inactive};

            # Common between DFI and PHYIF
            if ($row == CTRL_AP_COL_CNT_LOAD && $i == 0) { 
#                $val = $Ctrl_Table[$row]{active};
            } elsif ($row == CTRL_AP_ROW_COL_SEL && $i == 0) { 
                $val = $Ctrl_Table[$row]{active};
            } 
            # DFI 
            if ($Use_DFI) {
                if ($row == CTRL_DFI_RAS_N_0 && $i == 0) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            } else { 
                if ($row == CTRL_PHYIF_RAS_N && $i == 0) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_SKIP_0 && $i == ($length - $skip_from_cmd)) { 
                    $val = $skip_0;
                } elsif ($row == CTRL_SKIP_1 && $i == ($length - $skip_from_cmd)) { 
                    $val = $skip_1;
                } elsif ($row == CTRL_SKIP_2 && $i == ($length - $skip_from_cmd)) { 
                    $val = $skip_2;
                }
            }
            # assign value
            $table[$row] = $table[$row] . $val
        }
    }

    # Return Table
    @table;
}

sub activate_to_read($$$$) { 
    my @table = activate_to_cmd($_[0], $_[1], $_[2], $_[3], 2);
}

sub activate_to_write($) { 
    my @table = activate_to_cmd($_[0], 0, 0, 0, 0);
}

# Read command  to precharge
sub read_to_precharge ($$$$$$) {
    my ($mem_type,
        $num_data_beats,
        $burst_length,
        $read_to_precharge,
        $rmw,
        $allow_repeat
       ) = @_;
    my @table;
    my $cmd_length;
    my $data_rate;

    if ($mem_type eq "ddr" || $mem_type eq "ddr2" || $mem_type eq "ddr3") {
        $data_rate = 2;
    } else { # SDR SDRAM
        $data_rate = 1;
    }

    if (($rmw == 1) && ($num_data_beats < $burst_length/$data_rate)) {
        $num_data_beats = $burst_length/$data_rate;
    }
    if ($num_data_beats < $burst_length/$data_rate) {
        $cmd_length = $burst_length/$data_rate;
    }
    else {
        $cmd_length = $num_data_beats;
    }

    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = '';
    }

    my $last_read_cmd = 0;
    for (my $i = 0; $i < $cmd_length; $i++) { 
        for (my $row = 0; $row < BRAM_WIDTH; $row++) { 
            # default to inactive
            my $val = $Ctrl_Table[$row]{inactive};

            # Common 
            if ($row == CTRL_AP_COL_CNT_ENABLE && (($i % ($burst_length/$data_rate)) == 0) && ($i <= $num_data_beats)) { 
                $val = $Ctrl_Table[$row]{active};
            } elsif ($row == CTRL_AP_COL_CNT_LOAD && $i == 0) { 
                $val = $Ctrl_Table[$row]{active};
            } elsif ($row == CTRL_REPEAT4 && $allow_repeat == 1 && $i == 1) {
                $val = $Ctrl_Table[$row]{active};
            }
            # DDR3 Only
            if ($mem_type eq "ddr3") {
                if ($row == CTRL_AP_OTF_ADDR12 && $burst_length == 8 && (($i % ($burst_length/$data_rate)) == 0) && ($i < $num_data_beats) ) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            }
            # DFI
            if ($Use_DFI) { 
                if ($row == CTRL_DFI_CAS_N_0 && (($i % ($burst_length/$data_rate)) == 0) && ($i < $num_data_beats)) {
                    $val = $Ctrl_Table[$row]{active};
                    $last_read_cmd = 0;
                } elsif ($row == CTRL_DFI_RDDATA_EN && ($i < $num_data_beats)) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            } else { # PHYIF
                if ($row == CTRL_PHYIF_CAS_N && (($i % ($burst_length/$data_rate)) == 0) && ($i < $num_data_beats)) {
                    $val = $Ctrl_Table[$row]{active};
                    $last_read_cmd = 0;
                } elsif ($row == CTRL_DP_RDFIFO_PUSH && ($i < $num_data_beats)) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            }

            # assign value
            $table[$row] = $table[$row] . $val;
        }
        $last_read_cmd++;
    }

    for (my $i = $last_read_cmd; $i < $read_to_precharge; $i++) { 
        for (my $row = 0; $row < BRAM_WIDTH; $row++) { 
            $table[$row] = $table[$row] . $Ctrl_Table[$row]{inactive};
        }
    }

    # Return Table
    @table;
}

# Write command to precharge
sub write_to_precharge($$$$$$) {
    my ($nWL, # Same as DQSS
        $num_data_beats,
        $nWR,
        $burst_length,
        $allow_repeat,
        $mem_type
       ) = @_;
    my @table;
    my $cmd_length;
    my @table_tmp;
    my $data_rate;
    
    if ($mem_type eq "ddr" || $mem_type eq "ddr2" || $mem_type eq "ddr3") {
        $data_rate = 2;
    } else { # SDR SDRAM
        $data_rate = 1;
    }

    if ($num_data_beats < $burst_length/$data_rate) {
        $cmd_length = $burst_length/$data_rate;
    }
    else {
        $cmd_length = $num_data_beats;
    }

    for (my $row = 0; $row < BRAM_WIDTH; $row++) {
        $table[$row] = '';
    }

    for (my $i=0; $i < $nWL + $cmd_length + $nWR; $i++) { 
        for (my $row = 0; $row < BRAM_WIDTH; $row++) { 
            # default to inactive
            my $val = $Ctrl_Table[$row]{inactive};

            # Common 
            if ($row == CTRL_AP_COL_CNT_ENABLE && (($i % ($burst_length/$data_rate)) == 0) && ($i <= $num_data_beats)) { 
                $val = $Ctrl_Table[$row]{active};
            } elsif ($row == CTRL_AP_COL_CNT_LOAD && $i == 0) { 
                $val = $Ctrl_Table[$row]{active};
            } elsif ($row == CTRL_REPEAT4 && $allow_repeat == 1 && $i == 1) {
                $val = $Ctrl_Table[$row]{active};
            }
            # DDR3 Only
            if ($mem_type eq "ddr3") {
                if ($row == CTRL_AP_OTF_ADDR12 && $burst_length == 8 && (($i % ($burst_length/$data_rate)) == 0) && ($i < $num_data_beats) ) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            }
            # DFI
            if ($Use_DFI) {
                if ($row == CTRL_DFI_CAS_N_0 && (( $i % ($burst_length/$data_rate) ) == 0) && ($i < $num_data_beats)) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_DFI_WE_N_0 && (( $i % ($burst_length/$data_rate) ) == 0) && ($i < $num_data_beats)) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_DP_WRFIFO_POP && $i < $cmd_length) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_DFI_WRDATA_EN && $i < $cmd_length) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            } else {  #PHYIF
                if ($row == CTRL_PHYIF_CAS_N && (( $i % ($burst_length/$data_rate) ) == 0) && ($i < $num_data_beats)) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_PHYIF_WE_N && (( $i % ($burst_length/$data_rate) ) == 0) && ($i < $num_data_beats)) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_PHYIF_DQS_O && $i < $cmd_length) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_PHYIF_FORCE_DM && $i < $cmd_length && $i >= $num_data_beats) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            }

            $table[$row] = $table[$row] . $val;
        }
    }

    if ($mem_type eq "ddr3") { 
        if ($cmd_length < 4) {
            @table_tmp = &nop((4)-$cmd_length);
            for (my $row = 0; $row < BRAM_WIDTH; $row++) {
                $table[$row] = $table[$row] . $table_tmp[$row];
            }
        }
    }

    # Return Table
    @table;
}

# Precharge to Activate
sub precharge_to_activate($) {
    my $nRP    = $_[0];
    my @table;
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = '';
    }

    for (my $i=0; $i < $nRP; $i++) { 
        for (my $row = 0; $row < BRAM_WIDTH; $row++) { 
            if ($Use_DFI) {
                if ($row == CTRL_DFI_RAS_N_0 && $i == 0) { 
                    $table[$row] = $table[$row] . $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_DFI_WE_N_0 && $i == 0) { 
                    $table[$row] = $table[$row] . $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_AP_PRECHARGE_ADDR10 && $i == 0) { 
                    $table[$row] = $table[$row] . $Ctrl_Table[$row]{active};
                } else { 
                    $table[$row] = $table[$row] . $Ctrl_Table[$row]{inactive};
                }
            } else { 
                if ($row == CTRL_PHYIF_RAS_N && $i == 0) { 
                    $table[$row] = $table[$row] . $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_PHYIF_WE_N && $i == 0) { 
                    $table[$row] = $table[$row] . $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_AP_PRECHARGE_ADDR10 && $i == 0) { 
                    $table[$row] = $table[$row] . $Ctrl_Table[$row]{active};
                } else { 
                    $table[$row] = $table[$row] . $Ctrl_Table[$row]{inactive};
                }
            }
        }
    }
    # Return Table
    @table;
}

# Precharge to Refresh
sub precharge_to_refresh($) {
    my $nRP    = $_[0];
    my @table;

    @table = &precharge_to_activate($nRP);

    # Return Table
    @table;
}

# Refresh to activate
sub refresh_to_activate($) {
    my $nRFC   = $_[0];
    my @table;

    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = '';
    }

    for (my $i = 0; $i < $nRFC; $i++) { 
        for (my $row = 0; $row < BRAM_WIDTH; $row++) { 

            # default to inactive 
            my $val = $Ctrl_Table[$row]{inactive};

            if ($Use_DFI) {
                if ($row == CTRL_DFI_RAS_N_0 && $i == 0) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif($row == CTRL_DFI_CAS_N_0 && $i == 0) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            } else { 
                if ($row == CTRL_PHYIF_RAS_N && $i == 0) { 
                    $val = $Ctrl_Table[$row]{active};
                } elsif ($row == CTRL_PHYIF_CAS_N && $i == 0) { 
                    $val = $Ctrl_Table[$row]{active};
                }
            }
            # assign value
            $table[$row] = $table[$row] . $val
        }
    }

    # Return Table
    @table;
}

# NOP
sub nop ($) {
    my $length = $_[0];
    my @table;
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = '';
    }

    for (my $i = 0; $i < $length; $i++) {
        for (my $j = 0; $j < BRAM_WIDTH; $j++) {
            $table[$j] = $table[$j] . $Ctrl_Table[$j]{inactive};
        }
    }


    @table;
}

#SDRAM/DDR Specific Routines
sub activate_to_read_to_precharge {
    my $nRCD           = $_[0];
    my $num_data_beats = $_[1];
    my $burst_length   = $_[2];
    my $nRAS           = $_[3];
    my $allow_repeat   = $_[4];
    my $family         = $_[5];
    my $errorfile      = $_[6];
    my $mem_type       = $_[7];
    my @table;
    my @table_tmp;
    my $table_length;
    
    ###Get table for activate to read
    @table = &activate_to_read($nRCD, 0, 0, 0);

    ###Append table for read to precharge
    @table_tmp = &read_to_precharge($mem_type, $num_data_beats, $burst_length, 0, 0, $allow_repeat);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    $table_length = length($table[CTRL_COMPLETE]);
    if ($table_length < $nRAS) {
        @table_tmp = &nop($nRAS-$table_length);
        for (my $i = 0; $i < BRAM_WIDTH; $i++) {
            $table[$i] = $table[$i] . $table_tmp[$i];
        }
    }

    # Return Table
    @table;
}

sub activate_to_read_to_write_to_precharge {
    my $nRCD           = $_[0];
    my $nDQSS          = $_[1];
    my $num_data_beats = $_[2];
    my $nWR            = $_[3];
    my $burst_length   = $_[4];
    my $nRAS           = $_[5];
    my $cas_latency    = $_[6];
    my $skip_0         = $_[7];
    my $skip_1         = $_[8];
    my $skip_2         = $_[9];
    my $allow_repeat   = $_[10];
    my $family         = $_[11];
    my $errorfile      = $_[12];
    my $mem_type       = $_[13];
    my @table;
    my @table_tmp;
    my $table_length;
    my $tmp;
    my $mem_data_rate;
    my $rmw_latency;
    if ($mem_type eq "sdram") { 
        $mem_data_rate = 1;
    } elsif ($mem_type eq "ddr" || $mem_type eq "ddr2" || $mem_type eq "ddr3") { 
        $mem_data_rate = 2;
    }
    
    ###Get table for activate to read
    @table = &activate_to_read($nRCD, $skip_0, $skip_1, $skip_2);
    ###Special Case for Spartan3 ECC.  Adds a bubble cycle.
    if ($family eq 'spartan3' && $mem_type eq 'ddr') {
        @table_tmp = &nop(1);
        for (my $i = 0; $i < BRAM_WIDTH; $i++) {
            $table[$i] = $table[$i] . $table_tmp[$i];
        }
    }

    ###Append table for read to precharge
    @table_tmp = &read_to_precharge($mem_type, $num_data_beats, $burst_length, 0, 1, $allow_repeat);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table_tmp[0]);
    if ($num_data_beats > $burst_length/$mem_data_rate) {
        $tmp = $num_data_beats + $cas_latency;
    }
    else {
        $tmp = $burst_length/$mem_data_rate + $cas_latency;
    }
    if ($mem_type eq "sdram") { 
        $rmw_latency = 9;
    } else { 
        $rmw_latency = 10;
    }
    if ($tmp < $burst_length/$mem_data_rate + $cas_latency + $rmw_latency) {
        $tmp = $burst_length/$mem_data_rate + $cas_latency + $rmw_latency;
    }
    if ($family eq 'spartan3' && $mem_type eq "ddr") {
        $tmp = $tmp + 6;
    }
    if ($table_length < $tmp) {
        @table_tmp = &nop($tmp - $table_length);
        for (my $i = 0; $i < BRAM_WIDTH; $i++) {
            $table[$i] = $table[$i] . $table_tmp[$i];
        }
    }

    ###Append table for write to precharge
    @table_tmp = &write_to_precharge($nDQSS, $num_data_beats, $nWR, $burst_length, $allow_repeat, $mem_type);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop($nRAS-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    # Return Table
    @table;
}

sub activate_to_read_to_write_to_precharge_to_activate {
    my $nRCD           = $_[0];
    my $nDQSS          = $_[1];
    my $num_data_beats = $_[2];
    my $nWR            = $_[3];
    my $burst_length   = $_[4];
    my $nRAS           = $_[5];
    my $nRP            = $_[6];
    my $nRC            = $_[7];
    my $nRRD           = $_[8];
    my $cas_latency    = $_[9];
    my $skip_0         = $_[10];
    my $skip_1         = $_[11];
    my $skip_2         = $_[12];
    my $allow_repeat   = $_[13];
    my $family         = $_[14];
    my $errorfile      = $_[15];
    my $mem_type       = $_[16];
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for activate to write to precharge
    @table = &activate_to_read_to_write_to_precharge($nRCD, $nDQSS, $num_data_beats, $nWR, $burst_length, $nRAS, $cas_latency, $skip_0, $skip_1, $skip_2, $allow_repeat, $family, $errorfile, $mem_type);

    ###Append table for precharge to activate
    @table_tmp = &precharge_to_activate($nRP);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(&max($nRC, $nRRD)-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    if (!$Use_DFI) { 
        ### Overwrite Ctrl_RMW Bit
        $table_length = length($table[CTRL_RMW]);
        if ($mem_type eq "ddr") { 
            $table[CTRL_RMW] = $Ctrl_Table[CTRL_RMW]{inactive};
        } else { 
            $table[CTRL_RMW] = $Ctrl_Table[CTRL_RMW]{active};
        }
        for (my $i=1;$i<$table_length;$i++) {
            $table[CTRL_RMW] = $table[CTRL_RMW] . $Ctrl_Table[CTRL_RMW]{active};
        }
    }
    

    # Return Table
    @table;
}

sub activate_to_read_to_precharge_to_activate {
    my $nRCD           = $_[0];
    my $num_data_beats = $_[1];
    my $burst_length   = $_[2];
    my $nRAS           = $_[3];
    my $nRP            = $_[4];
    my $nRC            = $_[5];
    my $nRRD           = $_[6];
    my $allow_repeat   = $_[7];
    my $family         = $_[8];
    my $errorfile      = $_[9];
    my $mem_type       = $_[10];
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for activate to read to precharge
    @table = &activate_to_read_to_precharge($nRCD, $num_data_beats, $burst_length, $nRAS, $allow_repeat, $family, $errorfile, $mem_type);

    ###Append table for precharge to activate
    @table_tmp = &precharge_to_activate($nRP);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop($nRC-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    # Return Table
    @table;
}

sub activate_to_write_to_precharge {
    my $nRCD           = $_[0];
    my $nDQSS          = $_[1];
    my $num_data_beats = $_[2];
    my $nWR            = $_[3];
    my $burst_length   = $_[4];
    my $nRAS           = $_[5];
    my $allow_repeat   = $_[6];
    my $family         = $_[7];
    my $errorfile      = $_[8];
    my $mem_type       = $_[9];
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for activate to write
    @table = &activate_to_write($nRCD);

    ###Append table for write to precharge
    @table_tmp = &write_to_precharge($nDQSS, $num_data_beats, $nWR, $burst_length, $allow_repeat, $mem_type);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop($nRAS-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    # Return Table
    @table;
}

sub activate_to_write_to_precharge_to_activate {
    my $nRCD           = $_[0];
    my $nDQSS          = $_[1];
    my $num_data_beats = $_[2];
    my $nWR            = $_[3];
    my $burst_length   = $_[4];
    my $nRAS           = $_[5];
    my $nRP            = $_[6];
    my $nRC            = $_[7];
    my $nRRD           = $_[8];
    my $allow_repeat   = $_[9];
    my $family         = $_[10];
    my $errorfile      = $_[11];
    my $mem_type       = $_[12];
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for activate to write to precharge
    @table = &activate_to_write_to_precharge($nRCD, $nDQSS, $num_data_beats, $nWR, $burst_length, $nRAS, $allow_repeat, $family, $errorfile, $mem_type);

    ###Append table for precharge to activate
    @table_tmp = &precharge_to_activate($nRP);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(&max($nRC, $nRRD)-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    # Return Table
    @table;
}

sub precharge_to_refresh_to_activate {
    my $nRP    = $_[0];
    my $nRFC   = $_[1];
    my $family = $_[2];
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for precharge to refresh
    @table = &precharge_to_refresh($nRP);

    ###Append table for refresh to activate
    @table_tmp = &refresh_to_activate($nRFC);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    # Return Table
    @table;    
}

# DDR2/DDR3 Routines
sub ddr2_activate_to_read_to_precharge {
    my ($mem_config,
        $num_data_beats,
        $burst_length,
        $allow_repeat,
        $family,
        $errorfile
       ) = @_;
    my @table;
    my @table_tmp;
    my $table_length;
    
    ###Get table for activate to read
    @table = &activate_to_read($mem_config->{nRCD} - $mem_config->{nAL}, 0, 0, 0);

    ###Append table for read to precharge
    @table_tmp = &read_to_precharge($mem_config->{mem_type}, $num_data_beats, $burst_length, $mem_config->{nRTP}+$mem_config->{nAL}, 0, $allow_repeat);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop($mem_config->{nRAS}-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    # Return Table
    @table;
}

sub ddr2_activate_to_read_to_precharge_to_activate {
    my ($mem_config,
        $num_data_beats,
        $burst_length,
        $allow_repeat,
        $family,
        $errorfile
       ) = @_;
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for activate to read to precharge
    @table = &ddr2_activate_to_read_to_precharge($mem_config, $num_data_beats, $burst_length, $allow_repeat, $family, $errorfile);
    
    ###Append table for precharge to activate
    @table_tmp = &precharge_to_activate($mem_config->{nRPA});
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(&max($mem_config->{nRC}, $mem_config->{nRRD})-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

#    $table_length = length($table[CTRL_COMPLETE]);
#    @table_tmp = &nop(2);
#    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
#        $table[$i] = $table[$i] . $table_tmp[$i];
#    }
    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    print $errorfile "After adding NOP: length" . length($table[CTRL_DFI_RDDATA_EN]) . "\n";
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    # Return Table
    @table;
}

sub ddr2_activate_to_read_to_write_to_precharge {
    my ($mem_config, 
        $num_data_beats, 
        $burst_length, 
        $skip_0, 
        $skip_1, 
        $skip_2, 
        $allow_repeat, 
        $family, 
        $errorfile
       ) = @_;
    my @table;
    my @table_tmp;
    my $table_length;
    my $tmp;
    
    ###Get table for activate to read
    @table = &activate_to_read($mem_config->{nRCD}-$mem_config->{nAL}, $skip_0, $skip_1, $skip_2);
    ###Special Case for Spartan3 ECC.  Adds a bubble cycle.
    if ($family eq 'spartan3') {
        @table_tmp = &nop(1);
        for (my $i = 0; $i < BRAM_WIDTH; $i++) {
            $table[$i] = $table[$i] . $table_tmp[$i];
        }
    }

    ###Append table for read to precharge
    @table_tmp = &read_to_precharge($mem_config->{mem_type}, $num_data_beats, $burst_length, 0, 1, $allow_repeat);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table_tmp[0]);
    if ($num_data_beats > $burst_length/2) {
        $tmp = $num_data_beats + $mem_config->{nAL} + $mem_config->{cas_latency};
    }
    else {
        $tmp = $burst_length/2 + $mem_config->{nAL} + $mem_config->{cas_latency};
    }
    if ($tmp < $burst_length/2 + $mem_config->{nAL} + $mem_config->{cas_latency} + 9) {
        $tmp = $burst_length/2 + $mem_config->{nAL} + $mem_config->{cas_latency} + 9;
    }
    if ($family eq 'spartan3') {
        $tmp = $tmp + 6;
    }
    if ($table_length < $tmp) {
        @table_tmp = &nop($tmp - $table_length);
        for (my $i = 0; $i < BRAM_WIDTH; $i++) {
            $table[$i] = $table[$i] . $table_tmp[$i];
        }
    }

    ###Append table for write to precharge
    @table_tmp = &write_to_precharge($mem_config->{nWL}, $num_data_beats, $mem_config->{nWR}, $burst_length, $allow_repeat, $mem_config->{mem_type});
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop($mem_config->{nRAS}-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    # Return Table
    @table;
}

sub ddr2_activate_to_read_to_write_to_precharge_to_activate {
    my $mem_config     = $_[0];
    my $num_data_beats = $_[1];
    my $burst_length   = $_[2];
    my $skip_0         = $_[3];
    my $skip_1         = $_[4];
    my $skip_2         = $_[5];
    my $allow_repeat   = $_[6];
    my $family         = $_[7];
    my $errorfile      = $_[8];
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for activate to read to precharge
    @table = &ddr2_activate_to_read_to_write_to_precharge($mem_config, $num_data_beats, $burst_length, $skip_0, $skip_1, $skip_2, $allow_repeat, $family, $errorfile);
    
    ###Append table for precharge to activate
    @table_tmp = &precharge_to_activate($mem_config->{nRPA});
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(&max($mem_config->{nRC}, $mem_config->{nRRD})-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    if (!$Use_DFI) { 
        ### Overwrite Ctrl_RMW Bit
        $table_length = length($table[CTRL_COMPLETE]);
        $table[CTRL_RMW] = '';
        for (my $i=0;$i<$table_length;$i++) {
            $table[CTRL_RMW] = $table[CTRL_RMW] . $Ctrl_Table[CTRL_RMW]{active};
        }
    }

    # Return Table
    @table;
}

sub ddr2_activate_to_write_to_precharge {
    my $mem_config     = $_[0];
    my $num_data_beats = $_[1];
    my $burst_length   = $_[2];
    my $allow_repeat   = $_[3];
    my $family         = $_[4];
    my $errorfile      = $_[5];
    my @table;
    my @table_tmp;
    my $table_length;
    ###Get table for activate to write
    @table = &activate_to_write($mem_config->{nRCD});

    ###Append table for write to precharge
    @table_tmp = &write_to_precharge($mem_config->{nWL}, $num_data_beats, $mem_config->{nWR}, $burst_length, $allow_repeat, $mem_config->{mem_type});
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop($mem_config->{nRAS}-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    # Return Table
    @table;
}

sub ddr2_activate_to_write_to_precharge_to_activate {
    my $mem_config     = $_[0];
    my $num_data_beats = $_[1];
    my $burst_length   = $_[2];
    my $allow_repeat   = $_[3];
    my $family         = $_[4];
    my $errorfile      = $_[5];
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for activate to write to precharge
    @table = &ddr2_activate_to_write_to_precharge($mem_config, $num_data_beats, $burst_length, $allow_repeat, $family, $errorfile);

    ###Append table for precharge to activate
    @table_tmp = &precharge_to_activate($mem_config->{nRPA});
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Add NOPs to table if necessary
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(&max($mem_config->{nRC}, $mem_config->{nRRD})-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    # Return Table
    @table;
}

sub ddr2_precharge_to_refresh_to_activate {
    my ($mem_config, $family) = @_;
    my @table;
    my @table_tmp;
    my $table_length;

    ###Get table for precharge to refresh
    @table = &precharge_to_refresh($mem_config->{nRPA});

    ###Append table for refresh to activate
    @table_tmp = &refresh_to_activate($mem_config->{nRFC});
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }

    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    # Return Table
    @table;    
}

# ZQCS command  (ddr3 only)
sub ddr3_zqcs_to_activate {
    my ($mem_config, $family, $allow_repeat, $repeat_cnt, $errorfile, $nCK_PER_CLK) = @_;
    my @table;
    my @table_tmp;
    my $table_length;
    my $nop_length = $mem_config->{nZQCS} - ($repeat_cnt*$nCK_PER_CLK*4);
    if ($nop_length < 0) {
        my $error_msg = "ERROR: Error calculating ZQ operation.  For more information regarding this error, please consult the Xilinx Answers Database or open a WebCase with this project attached at http://www.xilinx.com/support.\n";
        print $errorfile $error_msg;
        print $error_msg;
    }


    # Create Table
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = '';
    }
     
    # Issue ZQ then add nops to satisify nZQCS
    # Assume USE_DFI is 1
    for (my $i=0; $i < $nop_length+1; $i++) { 
        for (my $row = 0; $row < BRAM_WIDTH; $row++) { 
            if ($row == CTRL_DFI_WE_N_0 && $i == 0) { 
                $table[$row] = $table[$row] . $Ctrl_Table[$row]{active};
            } elsif ($row == CTRL_REPEAT4 && $allow_repeat == 1 && $i == (1*$nCK_PER_CLK)) {
                $table[$row] = $table[$row] . $Ctrl_Table[$row]{active};
            } else { 
                $table[$row] = $table[$row] . $Ctrl_Table[$row]{inactive};
            }
        }
    }

    ### Overwrite Complete Bit
    $table_length = length($table[CTRL_COMPLETE]);
    @table_tmp = &nop(6-$table_length);
    for (my $i = 0; $i < BRAM_WIDTH; $i++) {
        $table[$i] = $table[$i] . $table_tmp[$i];
    }
    $table_length = length($table[CTRL_COMPLETE]);
    $table[CTRL_COMPLETE] = '';
    for (my $i=0;$i<$table_length-6;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }
    $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
    for (my $i=0;$i<5;$i++) {
        $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
    }

    # Return Table
    @table;    
}

# Main starts here
my $num_data_beats;
my @table;
my @table_tmp;
my @Seq_Table;
my $table_length;
my $nCK_PER_CLK;

# Command line options
my $help;
my $fout_txt = "mpmc_ctrl_path_table.txt";
my $fout_ver = "mpmc_ctrl_path_params.v";
my $fout_err = "ctrl_path_generation_errors.txt";
my %Mem_Config_Hash;
my $Mem_Config = \%Mem_Config_Hash;
my $static_phy;
my $wr_mem_pipeline;
my $family;

my $index;
my $odata;
my $odata_ver;
my @delay;
my $data_rate;

# Get command line options
# Debug
my $args = join(" ", @ARGV);
if (!GetOptions(
        'help|h'            => \$help,
        'fout_txt|f_txt=s'  => \$fout_txt,
        'fout_ver|f_ver=s'  => \$fout_ver,
        'fout_err|f_err=s'  => \$fout_err,
        'clk_period_ps|c=i' => \$Mem_Config->{clk_period_ps},
        'tRAS=i'            => \$Mem_Config->{tRAS},
        'tRCD=i'            => \$Mem_Config->{tRCD},
        'tRC=i'             => \$Mem_Config->{tRC},
        'tRRD=i'            => \$Mem_Config->{tRRD},
        'tWR=i'             => \$Mem_Config->{tWR},
        'tRP=i'             => \$Mem_Config->{tRP},
        'tRFC=i'            => \$Mem_Config->{tRFC},
        'tWTR=i'            => \$Mem_Config->{tWTR},
        'cas_latency=i'     => \$Mem_Config->{cas_latency},
        'cas_wr_latency=i'  => \$Mem_Config->{cas_wr_latency},
        'reg_dimm|reg=i'    => \$Mem_Config->{reg_dimm},
        'data_width|d=i'    => \$Mem_Config->{data_width},
        'part_data_width=i' => \$Mem_Config->{part_data_width},
        'mem_type|m=s'      => \$Mem_Config->{mem_type},
        'burst_length|memory_burst_length=i' =>\$Mem_Config->{burst_length},
        'nDQSS=i'           => \$Mem_Config->{nDQSS},
        'nAL=i'             => \$Mem_Config->{nAL},
        'tRTP=i'            => \$Mem_Config->{tRTP},
        'nCCD=i'            => \$Mem_Config->{nCCD},
        'nZQCS=i'           => \$Mem_Config->{nZQCS},
        'enable_ecc=i'      => \$Mem_Config->{enable_ecc},
        'static_phy=i'      => \$static_phy,
        'wr_mem_pipeline=i' => \$wr_mem_pipeline,
        'family=s'          => \$family))
{
    exit 1;
}
           
if (defined $help) { 
    display_help();
}
my $errorfile = gensym;
open($errorfile, ">$fout_err") || die print "Can't open $fout_err: $!\n";

# Verify command line options
if (not defined $family) {
  parameter_error("family", $errorfile);
  die;
}
if (not defined $Mem_Config->{mem_type}) {
  parameter_error ("mem_type(m)", $errorfile);
  die;
}

# convert any strings to lower case
$Mem_Config->{mem_type} = lc($Mem_Config->{mem_type});
if ($family =~ /spartan3/i) { 
    $family = "spartan3";
}
    
my $error = 0;

$error = parameter_error("clk_period_ps(c)", $errorfile) unless (defined $Mem_Config->{clk_period_ps});
$error = parameter_error("tRAS", $errorfile)            unless (defined $Mem_Config->{tRAS});
$error = parameter_error("tRCD", $errorfile)            unless (defined $Mem_Config->{tRCD});
$error = parameter_error("tRC", $errorfile)             unless (defined $Mem_Config->{tRC});
$error = parameter_error("tRRD", $errorfile)            unless (defined $Mem_Config->{tRRD});
$error = parameter_error("tWR", $errorfile)             unless (defined $Mem_Config->{tWR});
$error = parameter_error("tRP", $errorfile)             unless (defined $Mem_Config->{tRP});
$error = parameter_error("tRFC", $errorfile)            unless (defined $Mem_Config->{tRFC});
$error = parameter_error("cas_latency", $errorfile)     unless (defined $Mem_Config->{cas_latency});
$error = parameter_error("reg_dimm", $errorfile)        unless (defined $Mem_Config->{reg_dimm});
$error = parameter_error("data_width", $errorfile)      unless (defined $Mem_Config->{data_width});
$error = parameter_error("burst_length", $errorfile)    unless (defined $Mem_Config->{burst_length});
$error = parameter_error("enable_ecc", $errorfile)      unless (defined $Mem_Config->{enable_ecc});
$error = parameter_error("static_phy", $errorfile)      unless (defined $static_phy);
$error = parameter_error("wr_mem_pipeline", $errorfile) unless (defined $wr_mem_pipeline);
if ($Mem_Config->{mem_type} eq "ddr") {
  $error = parameter_error("nDQSS", $errorfile)         unless (defined $Mem_Config->{nDQSS});
} 
if ($Mem_Config->{mem_type} eq "ddr2" || $Mem_Config->{mem_type} eq "ddr3") {
  $error = parameter_error("nAL", $errorfile)           unless (defined $Mem_Config->{nAL});
  $error = parameter_error("tRTP", $errorfile)          unless (defined $Mem_Config->{tRTP});
  $error = parameter_error("nCCD", $errorfile)          unless (defined $Mem_Config->{nCCD});
}
if ($Mem_Config->{mem_type} eq "ddr3") { 
  $error = parameter_error("cas_wr_latency", $errorfile) unless (defined $Mem_Config->{cas_wr_latency});
  $error = parameter_error("nZQCS", $errorfile)          unless (defined $Mem_Config->{nZQCS});
}

# When nCK_PER_CLK = 2, the data rate is doubled, however, we will calculate everything for 
# nCK_PER_CLK = 1, and shift everything over after the calculations.
# Therefore data_rate is 1 for SDR SDRAM and 2 for DDRs.
if ($Mem_Config->{mem_type} eq "sdram") { 
    $data_rate = 1;
} else { 
    $data_rate = 2;
}
    

if ($error == 1) {
  die "Aborting Script: Missing arguments\n";
}

# Ratio of Memory clock to Memory Control Clock
if ($family eq "virtex6" && $Mem_Config->{mem_type} eq "ddr2" ||  $Mem_Config->{mem_type} eq "ddr3") { 
    $nCK_PER_CLK = 2;
    $Mem_Config->{clk_period_ps} = $Mem_Config->{clk_period_ps} / $nCK_PER_CLK;
    $Use_DFI = 1;
} else { 
    $nCK_PER_CLK = 1;
    $Use_DFI = 0;
}

# Map out the signals.   
$Ctrl_Table[CTRL_COMPLETE]              = { name => 'CTRL_COMPLETE',             
                                            inactive => '0',
                                            active => '1',
                                            bram_index => CTRL_COMPLETE };
$Ctrl_Table[CTRL_IS_WRITE]              = { name => 'CTRL_IS_WRITE',
                                            inactive => '0',
                                            active => '1',
                                            bram_index => CTRL_IS_WRITE };
$Ctrl_Table[CTRL_AP_COL_CNT_LOAD]       = { name => 'CTRL_AP_COL_CNT_LOAD',
                                            inactive => '0',
                                            active => '1',
                                            bram_index => CTRL_AP_COL_CNT_LOAD };
$Ctrl_Table[CTRL_AP_COL_CNT_ENABLE]     = { name => 'CTRL_AP_COL_CNT_ENABLE',
                                            inactive => '0',
                                            active => '1',
                                            bram_index => CTRL_AP_COL_CNT_ENABLE };
$Ctrl_Table[CTRL_AP_PRECHARGE_ADDR10]   = { name => 'CTRL_AP_PRECHARGE_ADDR10',
                                            inactive => '0',
                                            active => '1',
                                            bram_index => CTRL_AP_PRECHARGE_ADDR10 };
$Ctrl_Table[CTRL_AP_ROW_COL_SEL]        = { name => 'CTRL_AP_ROW_COL_SEL',
                                            inactive => '0',
                                            active => '1',
                                            bram_index => CTRL_AP_ROW_COL_SEL };
$Ctrl_Table[CTRL_REPEAT4]               = { name => 'CTRL_REPEAT4',
                                            inactive => '0',
                                            active => '1',
                                            bram_index => CTRL_REPEAT4 };
if ($Use_DFI) {
    $Ctrl_Table[CTRL_DFI_RAS_N_0]           = { name => 'CTRL_DFI_RAS_N_0',
                                                inactive => '1',
                                                active => '0',
                                                bram_index => CTRL_DFI_RAS_N_0 };
    $Ctrl_Table[CTRL_DFI_CAS_N_0]           = { name => 'CTRL_DFI_CAS_N_0',
                                                inactive => '1',
                                                active => '0',
                                                bram_index => CTRL_DFI_CAS_N_0 };
    $Ctrl_Table[CTRL_DFI_WE_N_0]            = { name => 'CTRL_DFI_WE_N_0',
                                                inactive => '1',
                                                active => '0',
                                                bram_index => CTRL_DFI_WE_N_0 };
    $Ctrl_Table[CTRL_DFI_WRDATA_EN]         = { name => 'CTRL_DFI_WRDATA_EN',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_DFI_WRDATA_EN };
    $Ctrl_Table[CTRL_DP_WRFIFO_POP]         = { name => 'CTRL_DP_WRFIFO_POP',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_DP_WRFIFO_POP };
    $Ctrl_Table[CTRL_DFI_RDDATA_EN]         = { name => 'CTRL_DFI_RDDATA_EN',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_DFI_RDDATA_EN };
    $Ctrl_Table[CTRL_AP_OTF_ADDR12]         = { name => 'CTRL_AP_OTF_ADDR12',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_AP_OTF_ADDR12 };
    if ($nCK_PER_CLK == 2) {
        $Ctrl_Table[CTRL_DFI_RAS_N_1]           = { name => 'CTRL_DFI_RAS_N_1',
                                                    inactive => '1',
                                                    active => '0',
                                                    bram_index => CTRL_DFI_RAS_N_1 };
        $Ctrl_Table[CTRL_DFI_CAS_N_1]           = { name => 'CTRL_DFI_CAS_N_1',
                                                    inactive => '1',
                                                    active => '0',
                                                    bram_index => CTRL_DFI_CAS_N_1 };
        $Ctrl_Table[CTRL_DFI_WE_N_1]            = { name => 'CTRL_DFI_WE_N_1',
                                                    inactive => '1',
                                                    active => '0',
                                                    bram_index => CTRL_DFI_WE_N_1 };
    }
} else {
    $Ctrl_Table[CTRL_PHYIF_RAS_N]           = { name => 'CTRL_PHYIF_RAS_N',
                                                inactive => '1',
                                                active => '0',
                                                bram_index => CTRL_PHYIF_RAS_N };
    $Ctrl_Table[CTRL_PHYIF_CAS_N]           = { name => 'CTRL_PHYIF_CAS_N',
                                                inactive => '1',
                                                active => '0',
                                                bram_index => CTRL_PHYIF_CAS_N };
    $Ctrl_Table[CTRL_PHYIF_WE_N]            = { name => 'CTRL_PHYIF_WE_N',
                                                inactive => '1',
                                                active => '0',
                                                bram_index => CTRL_PHYIF_WE_N };
    $Ctrl_Table[CTRL_RMW]                   = { name => 'CTRL_RMW',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_RMW };
    $Ctrl_Table[CTRL_SKIP_0]                = { name => 'CTRL_SKIP_0',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_SKIP_0 };
    $Ctrl_Table[CTRL_PHYIF_DQS_O]           = { name => 'CTRL_PHYIF_DQS_O',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_PHYIF_DQS_O };
    $Ctrl_Table[CTRL_SKIP_1]                = { name => 'CTRL_SKIP_1',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_SKIP_1 };
    $Ctrl_Table[CTRL_DP_RDFIFO_PUSH]        = { name => 'CTRL_DP_RDFIFO_PUSH',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_DP_RDFIFO_PUSH };
    $Ctrl_Table[CTRL_SKIP_2]                = { name => 'CTRL_SKIP_2',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_SKIP_2 };
    $Ctrl_Table[CTRL_PHYIF_FORCE_DM]        = { name => 'CTRL_PHYIF_FORCE_DM',
                                                inactive => '0',
                                                active => '1',
                                                bram_index => CTRL_PHYIF_FORCE_DM };
}

for (my $i = 0; $i < BRAM_WIDTH; $i++) { 
    if (not defined $Ctrl_Table[$i]) { 
        $Ctrl_Table[$i] = { name => 'UNUSED',
                            inactive => '0',
                            active => '1',
                            param_name => '' };
    }
}

$odata = gensym; 
open($odata, ">$fout_txt")|| die "ERROR: $fout_txt $!\n";
print $odata "// This file has been automatically generated.  Do not modify.\n";
print $odata "// Command Line Options: $args\n";

$odata_ver = gensym; 
open($odata_ver, ">$fout_ver")|| die "ERROR: $fout_ver $!\n";
print $odata_ver "// This file has been automatically generated.  Do not modify.\n";

# convert timing parameters to cycles
$Mem_Config->{nRAS}        = ceil($Mem_Config->{tRAS} / $Mem_Config->{clk_period_ps});
$Mem_Config->{nRCD}        = ($Mem_Config->{mem_type} eq "sdram") ? max(ceil($Mem_Config->{tRCD} / $Mem_Config->{clk_period_ps}), 3) :
                                                                    max(ceil($Mem_Config->{tRCD} / $Mem_Config->{clk_period_ps}), 2); #nRCD has a minimum value of 2 for DDR3
# When use mig DFI, commands must occur on the odd cycle, therefore if nRCD is even, increment it
if ($Use_DFI && $Mem_Config->{nRCD} % 2 == 0) { 
    $Mem_Config->{nRCD}++;
}
$Mem_Config->{nRC}         = ceil($Mem_Config->{tRC} / $Mem_Config->{clk_period_ps});
#tRRD has a minimum value of 4 for DDR3, minimum of 2 for DDR2
$Mem_Config->{nRRD}        = ($Mem_Config->{mem_type} eq "ddr3") ? max(ceil($Mem_Config->{tRRD} / $Mem_Config->{clk_period_ps}), 4) :
                             ($Mem_Config->{mem_type} eq "ddr2") ? max(ceil($Mem_Config->{tRRD} / $Mem_Config->{clk_period_ps}), 2) :
                                ceil($Mem_Config->{tRRD} / $Mem_Config->{clk_period_ps});
$Mem_Config->{nWR}         = ceil($Mem_Config->{tWR} / $Mem_Config->{clk_period_ps});
$Mem_Config->{nRP}         = ceil($Mem_Config->{tRP} / $Mem_Config->{clk_period_ps});
$Mem_Config->{nRFC}        = ceil($Mem_Config->{tRFC} / $Mem_Config->{clk_period_ps}); 
# Memory datasheet defines tRTPmin = greater of 4CK or tRTP for DDR3, greater of 2CK or tRTP for DDR2;
$Mem_Config->{nRTP}        = ($Mem_Config->{mem_type} eq "ddr3") ? max(ceil($Mem_Config->{tRTP}/$Mem_Config->{clk_period_ps}), 4) : 
                             ($Mem_Config->{mem_type} eq "ddr2") ? max(ceil($Mem_Config->{tRTP}/$Mem_Config->{clk_period_ps}), 2) :
                                ceil($Mem_Config->{tRTP}/$Mem_Config->{clk_period_ps});
# Derived Memory timings and parameters
$Mem_Config->{nWL}         = ($Mem_Config->{mem_type} eq "ddr3") ? $Mem_Config->{nAL} + $Mem_Config->{cas_wr_latency} : 
                             ($Mem_Config->{mem_type} eq "ddr2") ? $Mem_Config->{nAL} + $Mem_Config->{cas_latency} - 1 :
                             ($Mem_Config->{mem_type} eq "ddr") ? $Mem_Config->{nAL} + $Mem_Config->{nDQSS} :
                             ($Mem_Config->{mem_type} eq "sdram") ? 0 :
                             -1 ;
$Mem_Config->{nRPA}  = $Mem_Config->{nRP} + 1;

# DFI specific memory timings:
if ($Use_DFI) {
    $Mem_Config->{tRDDATA_EN} = 0;
    $Mem_Config->{tRD_EN2CNFG_WR} = max((7 + floor(0.5*($Mem_Config->{cas_latency}-5))), 5);
    $Mem_Config->{tRD_EN2CNFG_RD} = 1;
    $Mem_Config->{tPHY_WRLAT} = max(floor(0.5*($Mem_Config->{cas_latency}-5)), 0);
    $Mem_Config->{tCNFG2RD_EN} = 2;
    $Mem_Config->{tCNFG2WR_EN} = max((2 + floor(0.5*($Mem_Config->{cas_latency}-5))), 2);
    $Mem_Config->{tWR_EN2CNFG_WR} = 4;
    $Mem_Config->{tWR_EN2CNFG_RD} = 3;

    # This is a rough calculation, 13 is the value for CL5, add 2 cycles for trace lengths and compensate for higher cas latencies
    $Mem_Config->{tPHY_RDLAT} = 13 + floor(0.5*($Mem_Config->{cas_latency}-5)) + 2;
}


my $cp_pipeline = 1;
my $ap_pipeline1 = 1;
my $ap_pipeline2 = 1;

print $odata "//\n";
print $odata "// Timing Parameters:\n";
print $odata "// Memory Clock Period (ps): $Mem_Config->{clk_period_ps} \n";
print $odata "// CAS Latency : $Mem_Config->{cas_latency} \n";
print $odata "// CAS Write Latency : $Mem_Config->{cas_wr_latency} \n" if ($Mem_Config->{mem_type} eq "ddr3");
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n";
print $odata "// |                              |        |  Clocks     |   Nanoseconds   |\n";
print $odata "// |Parameter                     | Symbol | MIN |  MAX  |  MIN  |   MAX   |\n";
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n";
print $odata "// |ACTIVATE to internal READ or  | tRCD   |" . sprintf(" %3d |", $Mem_Config->{nRCD} ) . "   -   |" . sprintf(" %5.1f |", $Mem_Config->{tRCD}/ 1000) . "    -    |\n";
print $odata "// |WRITE delay time*             |        |     |       |       |         |\n";
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n";
print $odata "// |PRECHARGE command period      | tRP    |" . sprintf(" %3d |", $Mem_Config->{nRP}  ) . "   -   |" . sprintf(" %5.1f |", $Mem_Config->{tRP} / 1000) . "    -    |\n";
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n";
print $odata "// |ACTIVATE-to-ACTIVATE or       | tRC    |" . sprintf(" %3d |", $Mem_Config->{nRC}  ) . "   -   |" . sprintf(" %5.1f |", $Mem_Config->{tRC} / 1000) . "    -    |\n";
print $odata "// |REFRESH command period        |        |     |       |       |         |\n";
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n";
print $odata "// |ACTIVATE-to-PRECHARGE         | tRAS   |" . sprintf(" %3d |", $Mem_Config->{nRAS} ) . "   -   |" . sprintf(" %5.1f |", $Mem_Config->{tRAS} / 1000) . "    -    |\n";
print $odata "// |command period                |        |     |       |       |         |\n";
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n";
print $odata "// |ACTIVATE-to-ACTIVATE minimum  | tRRD   |" . sprintf(" %3d |", $Mem_Config->{nRRD} ) . "   -   |" . sprintf(" %5.1f |", $Mem_Config->{tRRD} / 1000) . "    -    |\n";
print $odata "// |command period                |        |     |       |       |         |\n";
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n";
print $odata "// |Write recovery time           | tWR    |" . sprintf(" %3d |", $Mem_Config->{nWR}  ) . "   -   |" . sprintf(" %5.1f |", $Mem_Config->{tWR} / 1000) . "    -    |\n";
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n" if (defined $Mem_Config->{tWTR});
print $odata "// |Delay from start of internal  | tWTR   |" . sprintf("     |"        ) . "   -   |" . sprintf(" %5.1f |", $Mem_Config->{tWTR} / 1000) . "    -    |\n" if (defined $Mem_Config->{tWTR});
print $odata "// |WRITE transaction to internal |        |     |       |       |         |\n" if (defined $Mem_Config->{tWTR});
print $odata "// |READ command                  |        |     |       |       |         |\n" if (defined $Mem_Config->{tWTR});
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n" if (defined $Mem_Config->{nRTP});
print $odata "// |READ-to-PRECHARGE time        | tRTP   |" . sprintf(" %3d |", $Mem_Config->{nRTP} ) . "   -   |" . sprintf(" %5.1f |", $Mem_Config->{tRTP} /  1000) . "    -    |\n" if (defined $Mem_Config->{nRTP});
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n" if (defined $Mem_Config->{nCCD});
print $odata "// |CAS#-to-CAS# command delay    | tCCD   |" . sprintf(" %3d |", $Mem_Config->{nCCD} ) . "   -   |" . sprintf("       |") . "    -    |\n" if (defined $Mem_Config->{nCCD});
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n" if (defined $Mem_Config->{nZQCS});
print $odata "// |ZQCS command: short calib time| nZQCS  |" . sprintf(" %3d |", $Mem_Config->{nZQCS} ) . "   -   |" . sprintf("       |") . "    -    |\n" if (defined $Mem_Config->{nZQCS});
print $odata "// +------------------------------+--------+-----+-------+-------+---------+\n";
print $odata "// * tRCD must be an odd number of clock cycles when using Virtex-6 DDR3 (DFI)\n";


# Parameters to output to mpmc
print $odata_ver "parameter C_NCK_PER_CLK          = ", $nCK_PER_CLK, ";\n";
print $odata_ver "parameter C_TWR                  = ", $Mem_Config->{tWR}, ";\n";
for (my $i = 0; $i < BRAM_WIDTH; $i++) { 
    if (defined $Ctrl_Table[$i] && $Ctrl_Table[$i]{name} ne "UNUSED") { 
        print $odata_ver "parameter C_" . $Ctrl_Table[$i]{name} . "_INDEX = " . $Ctrl_Table[$i]{bram_index} . ";\n";
    }
}

# Calculate Parameterized Delays
for (my $i = 0; $i < BRAM_WIDTH; $i++) {
    $delay[$i] = 0;
}

# Command delays between DFI and PHYIF
$delay[CTRL_COMPLETE]               = 1;
$delay[CTRL_IS_WRITE]               = $ap_pipeline1 + $ap_pipeline2 - 1;
$delay[CTRL_AP_COL_CNT_LOAD]        = $ap_pipeline1;
$delay[CTRL_AP_COL_CNT_ENABLE]      = $ap_pipeline1;
$delay[CTRL_AP_PRECHARGE_ADDR10]    = $ap_pipeline1;
$delay[CTRL_AP_ROW_COL_SEL]         = $ap_pipeline1;
$delay[CTRL_REPEAT4] = 1;

if ($Use_DFI == 1) { 
    $delay[CTRL_DFI_RAS_N_0] = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_DFI_CAS_N_0] = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_DFI_WE_N_0]  = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_DFI_RAS_N_1] = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_DFI_CAS_N_1] = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_DFI_WE_N_1] = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_DP_WRFIFO_POP] = $ap_pipeline1 + $ap_pipeline2 - $wr_mem_pipeline;
    $delay[CTRL_DFI_WRDATA_EN]  = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_DFI_RDDATA_EN]  = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_AP_OTF_ADDR12]  = $ap_pipeline1;
} else { 
    $delay[CTRL_PHYIF_RAS_N] = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_PHYIF_CAS_N] = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_PHYIF_WE_N] = $ap_pipeline1 + $ap_pipeline2;
    $delay[CTRL_RMW] = $ap_pipeline1 + $ap_pipeline2 + $Mem_Config->{cas_latency};
    $delay[CTRL_SKIP_0] = 0;
    $delay[CTRL_PHYIF_DQS_O] = $ap_pipeline1 + $ap_pipeline2 - 2;
    $delay[CTRL_SKIP_1] = 0;
    $delay[CTRL_SKIP_2] = 0;
    $delay[CTRL_DP_RDFIFO_PUSH] = $ap_pipeline1 + $ap_pipeline2 - 1;
    if (($family eq 'spartan3') && ($static_phy == 0) &&
        (($Mem_Config->{mem_type} eq "ddr") || ($Mem_Config->{mem_type} eq "ddr2"))) {
        $delay[CTRL_PHYIF_RAS_N] = $delay[CTRL_PHYIF_RAS_N] - 1;
        $delay[CTRL_PHYIF_CAS_N] = $delay[CTRL_PHYIF_CAS_N] - 1;
        $delay[CTRL_PHYIF_WE_N] = $delay[CTRL_PHYIF_WE_N] - 1;
    }
    if ($family eq "virtex5" && $static_phy == 0 && $Mem_Config->{mem_type} eq "ddr2") { 
        $delay[CTRL_PHYIF_DQS_O]    += 2;
        $delay[CTRL_DP_RDFIFO_PUSH] += 1;
    }


    ### Move Ctrl_Skip and Ctrl_PhyIF_DQS_O forward by 1 cycle if activate takes 3 cycles or longer and not ECC.
    ### Move table back by 1 cycle.
    if ((ceil($Mem_Config->{nRCD}) - 2 > 0) && ($Mem_Config->{enable_ecc}==0)) {
        $delay[CTRL_SKIP_0]++;
        $delay[CTRL_PHYIF_DQS_O]++;
        $delay[CTRL_SKIP_1]++;
        $delay[CTRL_SKIP_2]++;
    }
    ### Special Case for DDR/DDR2 Spartan3 ECC.  Move Ctrl_Skip forward by 1 cycle if Spartan3 and ECC
    if (($family eq 'spartan3') &&
        (($Mem_Config->{mem_type} eq "ddr") || ($Mem_Config->{mem_type} eq "ddr2" || $Mem_Config->{mem_type} eq "ddr3"))) {
        $delay[CTRL_SKIP_0]  = $delay[CTRL_SKIP_0] + 1;
        $delay[CTRL_SKIP_1]  = $delay[CTRL_SKIP_1] + 1;
        $delay[CTRL_SKIP_2]  = $delay[CTRL_SKIP_2] + 1;
    }
    if ($Mem_Config->{mem_type} eq "ddr") {
      $delay[CTRL_PHYIF_FORCE_DM] = $ap_pipeline1 + $ap_pipeline2 + $Mem_Config->{nDQSS} + $Mem_Config->{reg_dimm} - 2 - $wr_mem_pipeline;
    } elsif ($Mem_Config->{mem_type} eq "ddr2" || $Mem_Config->{mem_type} eq "ddr3") {
      $delay[CTRL_PHYIF_FORCE_DM] = $ap_pipeline1 + $ap_pipeline2 + $Mem_Config->{nWL} + $Mem_Config->{reg_dimm} - 2 - $wr_mem_pipeline;
    } elsif ($Mem_Config->{mem_type} eq "sdram") {
      $delay[CTRL_PHYIF_FORCE_DM] = 1 - $wr_mem_pipeline;
    }
}



# Calculate Control Path Tables
my $start_addr = 0;
my $ctrl_bram_index = 0;
my @ctrl_bram_table; 
my @ctrl_bram_tablep; 
my @ctrl_bram_init;
my @ctrl_bram_initp;
my $WRFIFO_POP_DELAY_BY1 = 0;
# These are the different Sequences availabe in the MPMC BRAM State Machine.
# The Pattern Data Width (pattern_dwidth) is the total number of bits transferred in each sequence.
$Seq_Table[SEQ_REFRESH      ] = { pattern_dwidth => 32*0 , name => 'REFRESH'           };
$Seq_Table[SEQ_NOP          ] = { pattern_dwidth => 32*0 , name => 'NOP'               };
$Seq_Table[SEQ_ZQCS         ] = { pattern_dwidth => 32*0 , name => 'ZQCS'              };
$Seq_Table[SEQ_WORD_WRITE   ] = { pattern_dwidth => 32*1 , name => 'WORD WRITE'         ,
                                  skip_2 => 0   , skip_1 => 0   , skip_0 => 1          };
$Seq_Table[SEQ_WORD_READ    ] = { pattern_dwidth => 32*1 , name => 'WORD READ'         };
$Seq_Table[SEQ_DWORD_WRITE  ] = { pattern_dwidth => 32*2 , name => 'DOUBLE WORD WRITE' ,
                                  skip_2 => 0   , skip_1 => 1   , skip_0 => 0          };
$Seq_Table[SEQ_DWORD_READ   ] = { pattern_dwidth => 32*2 , name => 'DOUBLE WORD READ'  };
$Seq_Table[SEQ_CL4_WRITE    ] = { pattern_dwidth => 32*4 , name => 'CACHELINE 4 WRITE' ,
                                  skip_2 => 0   , skip_1 => 1   , skip_0 => 1          };
$Seq_Table[SEQ_CL4_READ     ] = { pattern_dwidth => 32*4 , name => 'CACHELINE 4 READ'  };
$Seq_Table[SEQ_CL8_WRITE    ] = { pattern_dwidth => 32*8 , name => 'CACHELINE 8 WRITE' ,
                                  skip_2 => 1   , skip_1 => 0   , skip_0 => 0          };
$Seq_Table[SEQ_CL8_READ     ] = { pattern_dwidth => 32*8 , name => 'CACHELINE 8 READ'  };
$Seq_Table[SEQ_B16_WRITE    ] = { pattern_dwidth => 32*16, name => 'BURST 16 WRITE'    ,
                                  skip_2 => 1   , skip_1 => 0   , skip_0 => 1          };
$Seq_Table[SEQ_B16_READ     ] = { pattern_dwidth => 32*16, name => 'BURST 16 READ'     };
$Seq_Table[SEQ_B32_WRITE    ] = { pattern_dwidth => 32*32, name => 'BURST 32 WRITE'    ,
                                  skip_2 => 1   , skip_1 => 1   , skip_0 => 0          };
$Seq_Table[SEQ_B32_READ     ] = { pattern_dwidth => 32*32, name => 'BURST 32 READ'     };
$Seq_Table[SEQ_B64_WRITE    ] = { pattern_dwidth => 32*64, name => 'BURST 64 WRITE'    ,
                                  skip_2 => 1   , skip_1 => 1   , skip_0 => 1          };
$Seq_Table[SEQ_B64_READ     ] = { pattern_dwidth => 32*64, name => 'BURST 64 READ'     };

foreach my $seq (@Seq_Table) {

    # Calculate OTF Burst Length:
    # Burst Length is the burst length for each READ/WRITE CMD issued to the RAM.  
    # For SDRAM/DDR/DDR2 this is fixed at a value of 4.  DDR3, the optimal value is 8.  
    # However, DDR3 allows for On The Fly Burst Length selection of 4 or 8.  We choose 4
    # when the burst_length of 8 * mem data_width > pattern dwidth
    if ($Mem_Config->{mem_type} ne "ddr3") { 
        $seq->{burst_length} = $Mem_Config->{burst_length};
    } else { 
        if ($seq->{pattern_dwidth} < $Mem_Config->{data_width} * 8) { 
            $seq->{burst_length} = 4;
        } else  { 
            $seq->{burst_length} = 8;
        }
    }

    # Calculate Pattern Repeat Values:
    # The pattern repeat is used to reduce the number of entries each sequence requires.
    # As the number of data bits transferrered, the number of READ/WRITE CMDs issued must also increase.
    # If the sequences run too long, we run out of block RAM.  The minimum requirement for this to works is
    # if we are performing at least 4 READ/WRITE CMDs.  If this is the case, we will be able to move back 
    # 4 spots from the 3rd READ/WRITE CMD.  This will either cause either 1 more CMD to be issued (SDRAM)
    # or 2 more CMDs to be issued (DDR).  
    # allow repeat --  determines if the sequence will be allowed to use the repeat function
    # repeat value --  indicates the number of times to repeat the pattern.
    # num_data_beats -- Number of data beats in the controller that is required for the sequence,
    # when we used the repeat command, we artificially cap this at 8.
    # Assuming that we are 1:1 controller to memory 
    if (($family eq "virtex6") && ($Mem_Config->{mem_type} eq "ddr2")) { 
        $seq->{allow_repeat} = 0;
        $seq->{repeat_value} = 0;
        $seq->{num_data_beats} = 0;
        while ($seq->{num_data_beats} * $Mem_Config->{data_width} * $data_rate < $seq->{pattern_dwidth}) {
            $seq->{num_data_beats}++;
        }
    } elsif ($Mem_Config->{mem_type} eq "ddr3" && $seq->{name} eq "ZQCS" && $Mem_Config->{nZQCS} > 12) { 
        $seq->{allow_repeat} = 1;
        $seq->{repeat_value} = floor(($Mem_Config->{nZQCS}-(6*$nCK_PER_CLK))/(4*$nCK_PER_CLK));
        $seq->{num_data_beats} = 0;
    } elsif ($Mem_Config->{mem_type} eq "ddr3") { 
        $seq->{allow_repeat} = 0;
        $seq->{repeat_value} = 0;
        $seq->{num_data_beats} = 0;
        while ($seq->{num_data_beats} * $Mem_Config->{data_width} * $data_rate < $seq->{pattern_dwidth}) {
            $seq->{num_data_beats}++;
        }
    } elsif ($seq->{pattern_dwidth} >= 32*32 || ($seq->{pattern_dwidth} >= 16*32 && $Mem_Config->{mem_type} eq "sdram" && $Mem_Config->{enable_ecc} == 1)) { 
        $seq->{allow_repeat}  = 1;
        $seq->{repeat_value}    = $seq->{pattern_dwidth}/$Mem_Config->{data_width}/($seq->{burst_length}*$data_rate)-2;
        $seq->{num_data_beats}  = $seq->{burst_length}*2;
    } else { 
        $seq->{allow_repeat} = 0;
        $seq->{repeat_value} = 0;
        $seq->{num_data_beats} = 0;
        while ($seq->{num_data_beats} * $Mem_Config->{data_width} * $data_rate < $seq->{pattern_dwidth}) {
            $seq->{num_data_beats}++;
        }
    }
}

print $odata_ver "parameter C_B16_REPEAT_CNT = " . $Seq_Table[SEQ_B16_WRITE]{repeat_value} . ";\n";
print $odata_ver "parameter C_B32_REPEAT_CNT = " . $Seq_Table[SEQ_B32_WRITE]{repeat_value} . ";\n";
print $odata_ver "parameter C_B64_REPEAT_CNT = " . $Seq_Table[SEQ_B64_WRITE]{repeat_value} . ";\n";
print $odata_ver "parameter C_ZQCS_REPEAT_CNT = " . $Seq_Table[SEQ_ZQCS]{repeat_value} . ";\n";

for (my $seq=0; $seq < 17; $seq++) {
    @table = ();
      
    if ($Mem_Config->{mem_type} eq "sdram" || $Mem_Config->{mem_type} eq "ddr") {
        if ((($seq % 2) == SEQ_WRITE_OP) && ($seq < 14)) {
            if ($Mem_Config->{enable_ecc} == 1) {
                @table = &activate_to_read_to_write_to_precharge_to_activate($Mem_Config->{nRCD}, $Mem_Config->{nDQSS}, $Seq_Table[$seq]{num_data_beats}, $Mem_Config->{nWR}, $Seq_Table[$seq]{burst_length}, $Mem_Config->{nRAS}, $Mem_Config->{nRP}, $Mem_Config->{nRC}, $Mem_Config->{nRRD}, $Mem_Config->{cas_latency}, $Seq_Table[$seq]{skip_0}, $Seq_Table[$seq]{skip_1}, $Seq_Table[$seq]{skip_2}, $Seq_Table[$seq]{allow_repeat}, $family, $errorfile, $Mem_Config->{mem_type});
            }
            else {
                @table = &activate_to_write_to_precharge_to_activate($Mem_Config->{nRCD}, $Mem_Config->{nDQSS}, $Seq_Table[$seq]{num_data_beats}, $Mem_Config->{nWR}, $Seq_Table[$seq]{burst_length}, $Mem_Config->{nRAS}, $Mem_Config->{nRP}, $Mem_Config->{nRC}, $Mem_Config->{nRRD}, $Seq_Table[$seq]{allow_repeat}, $family, $errorfile, $Mem_Config->{mem_type});
            }
            # Add extra cycle to write table to account for delayed
            # RAS/CAS/WE.  In future, look at adding stall to arbiter
            # in place of this work around.
            my @table_tmp = &nop(1);
            for (my $j=0;$j<BRAM_WIDTH;$j++) {
                $table[$j] = $table[$j] . $table_tmp[$j];
            }
            my @table_0 = split(//, $table[CTRL_COMPLETE]);
            my $table_0_length = length($table[CTRL_COMPLETE]);
            $table[CTRL_COMPLETE] = $Ctrl_Table[CTRL_COMPLETE]{inactive};
            for (my $j=0;$j<$table_0_length-1;$j++) {
                $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $table_0[$j];
            }

            my $table_1_length = length($table[CTRL_IS_WRITE]);
            $table[CTRL_IS_WRITE] = '';
            for (my $j=0;$j<$table_1_length;$j++) {
                $table[CTRL_IS_WRITE] = $table[CTRL_IS_WRITE] . $Ctrl_Table[CTRL_IS_WRITE]{active};
            }
        }
        elsif ((($seq % 2) == SEQ_READ_OP) && ($seq < 14)) {
            @table = &activate_to_read_to_precharge_to_activate($Mem_Config->{nRCD}, $Seq_Table[$seq]{num_data_beats}, $Seq_Table[$seq]{burst_length}, $Mem_Config->{nRAS}, $Mem_Config->{nRP}, $Mem_Config->{nRC}, $Mem_Config->{nRRD}, $Seq_Table[$seq]{allow_repeat}, $family, $errorfile, $Mem_Config->{mem_type});
        }
        elsif ($seq == SEQ_REFRESH) {
            @table = &precharge_to_refresh_to_activate($Mem_Config->{nRP}, $Mem_Config->{nRFC}, $family);
        }
        elsif ($seq == SEQ_NOP) {
            @table = &nop(2);
        }
        else { 
            next;
        }
    }
    elsif ($Mem_Config->{mem_type} eq "ddr2" || $Mem_Config->{mem_type} eq "ddr3") {
        if ((($seq % 2) == SEQ_WRITE_OP) && ($seq < 14)) {
            if ($Mem_Config->{enable_ecc} == 1) {
                @table = &ddr2_activate_to_read_to_write_to_precharge_to_activate($Mem_Config, $Seq_Table[$seq]{num_data_beats}, $Seq_Table[$seq]{burst_length}, $Seq_Table[$seq]{skip_0}, $Seq_Table[$seq]{skip_1}, $Seq_Table[$seq]{skip_2}, $Seq_Table[$seq]{allow_repeat}, $family);
            }
            else {
                @table = &ddr2_activate_to_write_to_precharge_to_activate($Mem_Config, $Seq_Table[$seq]{num_data_beats}, $Seq_Table[$seq]{burst_length}, $Seq_Table[$seq]{allow_repeat}, $family);
            }
            # Add extra cycle to write table to account for delayed
            # RAS/CAS/WE.  In future, look at adding stall to arbiter
            # in place of this work around.
            my @table_tmp = &nop(1);
            for (my $j=0;$j<BRAM_WIDTH;$j++) {
                $table[$j] = $table[$j] . $table_tmp[$j];
            }

            # I think this delays Ctrl_Complete by one cycle
            # Why not just delay it? -CC 02/17/2009
            my @table_0 = split(//, $table[CTRL_COMPLETE]);
            my $table_0_length = length($table[CTRL_COMPLETE]);
            $table[CTRL_COMPLETE] = $Ctrl_Table[CTRL_COMPLETE]{inactive};
            for (my $j=0;$j<$table_0_length-1;$j++) {
                $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $table_0[$j];
            }

            # Replace Ctrl_Write with all '1's
            my $table_1_length = length($table[CTRL_IS_WRITE]);
            $table[CTRL_IS_WRITE] = '';
            for (my $j=0;$j<$table_1_length;$j++) {
                $table[CTRL_IS_WRITE] = $table[CTRL_IS_WRITE] . $Ctrl_Table[CTRL_IS_WRITE]{active};
            }
        }
        elsif ((($seq % 2) == SEQ_READ_OP) && ($seq < 14)) {
            @table = &ddr2_activate_to_read_to_precharge_to_activate($Mem_Config, $Seq_Table[$seq]{num_data_beats}, $Seq_Table[$seq]{burst_length}, $Seq_Table[$seq]{allow_repeat}, $family, $errorfile);
        }
        elsif ($seq == SEQ_REFRESH) {
            @table = &ddr2_precharge_to_refresh_to_activate($Mem_Config, $family);

        }
        elsif ($seq == SEQ_NOP) {
            @table = &nop(2);
        }
        elsif ($seq == SEQ_ZQCS && $Mem_Config->{mem_type} eq "ddr3") { 
            @table = &ddr3_zqcs_to_activate($Mem_Config, $family, $Seq_Table[$seq]{allow_repeat}, $Seq_Table[$seq]{repeat_value}, $errorfile, $nCK_PER_CLK);
        }
        else { 
            next;
        }



    }

    # Divide table into two.
    if ($nCK_PER_CLK == 2) { 
        my $length = length($table[CTRL_COMPLETE]);
        my @row;
        
        # odd number of entries, extend the table by 1 nop
        if (($length % 2) == 1) { 
            for (my $j=0; $j < BRAM_WIDTH; $j++) { 
                @row = split (//, $table[$j]);
                my $splice = pop(@row);
                $table[$j] = $table[$j] . $splice;
            }
        $length++;
        }
        # Split the table into 2
        for (my $row = 0; $row < BRAM_WIDTH ; $row++) { 
            my @old_row = split (//, $table[$row]);
            if ($row == CTRL_DFI_RAS_N_0 || $row == CTRL_DFI_WE_N_0 || $row == CTRL_DFI_CAS_N_0) { 
                $table[$row] = '';
                $table[$row + BRAM_WIDTH/2] = '';
                for (my $k = 0; $k < $length; $k++) { 
                    if ($k % 2 == 0) { 
                        $table[$row] = $table[$row] . $old_row[$k];
                    } else { 
                        $table[$row + BRAM_WIDTH/2] = $table[$row + BRAM_WIDTH/2] . $old_row[$k];
                    }
                }
            } elsif ($row == CTRL_DFI_RAS_N_1 || $row == CTRL_DFI_WE_N_1 || $row == CTRL_DFI_CAS_N_1) {
                # Do Nothing
            } elsif ($row == CTRL_DFI_RDDATA_EN || $row == CTRL_DFI_WRDATA_EN
                     || $row == CTRL_DP_WRFIFO_POP) {
                $table[$row] = '';
                for (my $k = 0; $k < $length; $k = $k + 2) { 
                    if ($old_row[$k+1] eq '1') { 
                        $table[$row] = $table[$row] . '1';
                    } else { 
                        $table[$row] = $table[$row] . '0';
                    }
                }
            } else { 
                $table[$row] = '';
                # for signals not affected by two memory clocks per control clock 
                for (my $k = 0; $k < $length; $k = $k + 2) { 
                    if ($Ctrl_Table[$row]{inactive} eq '0') { 
                        if ($old_row[$k] eq '1' || $old_row[$k+1] eq '1') { 
                            $table[$row] = $table[$row] . '1';
                        } else { 
                            $table[$row] = $table[$row] . '0';
                        }

                    } else { 
                        if ($old_row[$k] eq '0' 
                            || $old_row[$k+1] eq '0') { 
                            $table[$row] = $table[$row] . '0';
                        } else { 
                            $table[$row] = $table[$row] . '1';
                        }
                    }
                    #$table[$row + BRAM_WIDTH/2] = $table[$row + BRAM_WIDTH/2] . $Ctrl_Table[$row]{inactive}
                }
            }


        }

        # If using DFI make sure we meet tCNF2WR_EN, IOCONFIG is strobed an effective 3 cycles delayed from CTRL_IS_WRITE(magic number derived from sim)
        if ((($seq % 2) == SEQ_WRITE_OP) && $seq < 14) { 

            # Meet timing on tCNFG2WR_EN
            my $inactive = $Ctrl_Table[CTRL_DFI_WRDATA_EN]{inactive};
            my $min_length = 3 + $delay[CTRL_IS_WRITE] + $Mem_Config->{tCNFG2WR_EN} - $delay[CTRL_DFI_WRDATA_EN];
            while (!($table[CTRL_DFI_WRDATA_EN] =~ /^($inactive){$min_length}/)) { 
                # add nop to front of table
                for (my $i = 0; $i < BRAM_WIDTH; $i++) {
                    $table[$i] = $Ctrl_Table[$i]{inactive} . $table[$i] ;
                }
            }


            # Meet timing on tWR_EN2CNFG_*
            $min_length = max($Mem_Config->{tWR_EN2CNFG_WR}, $Mem_Config->{tWR_EN2CNFG_RD}) + $delay[CTRL_DFI_WRDATA_EN] - (3 + $delay[CTRL_IS_WRITE]);
            while (!($table[CTRL_DFI_WRDATA_EN] =~ /($inactive){$min_length}$/)) { 
                # add nop to front of table
                for (my $i = 0; $i < BRAM_WIDTH; $i++) {
                    $table[$i] = $table[$i] . $Ctrl_Table[$i]{inactive};
                }
            }

            # Redo CTRL_IS_WRITE
            my $table_1_length = length($table[CTRL_IS_WRITE]);
            $table[CTRL_IS_WRITE] = '';
            for (my $j=0;$j<$table_1_length;$j++) {
                $table[CTRL_IS_WRITE] = $table[CTRL_IS_WRITE] . $Ctrl_Table[CTRL_IS_WRITE]{active};
            }
        }
        if ((($seq % 2) == SEQ_READ_OP) && $seq < 14) { 

            # Meet timing on tCNFG2RD_EN
            my $inactive = $Ctrl_Table[CTRL_DFI_RDDATA_EN]{inactive};
            my $min_length = 3 + $delay[CTRL_IS_WRITE] + $Mem_Config->{tCNFG2RD_EN} - $delay[CTRL_DFI_RDDATA_EN];
            while (!($table[CTRL_DFI_RDDATA_EN] =~ /^($inactive){$min_length}/)) { 
                # add nop to front of table
                for (my $i = 0; $i < BRAM_WIDTH; $i++) {
                    $table[$i] = $Ctrl_Table[$i]{inactive} . $table[$i] ;
                }
            }
            # Meet timing on tRD_EN2CNFG_*
            $min_length = max($Mem_Config->{tRD_EN2CNFG_WR}, $Mem_Config->{tRD_EN2CNFG_RD}) + $delay[CTRL_DFI_RDDATA_EN] - (3 + $delay[CTRL_IS_WRITE]);
            while (!($table[CTRL_DFI_RDDATA_EN] =~ /($inactive){$min_length}$/)) { 
                # add nop to front of table
                for (my $i = 0; $i < BRAM_WIDTH; $i++) {
                    $table[$i] = $table[$i] . $Ctrl_Table[$i]{inactive};
                }
            }
        }
        # re-encode the complete bit
        # Place it 6 spots back from the end of the table in entry 0
        if ($seq != SEQ_NOP) { 
            $length = length($table[CTRL_COMPLETE]);
            @table_tmp = &nop(6-$length);
            for (my $i = 0; $i < BRAM_WIDTH; $i++) {
                $table[$i] = $table[$i] . $table_tmp[$i];
            }
            $length = length($table[CTRL_COMPLETE]);
            $table[CTRL_COMPLETE] = '';
            for (my $i = 0; $i < $length-6; $i++) {
                $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
            }
            $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{active};
            for (my $i = 0; $i < 5; $i++) {
                $table[CTRL_COMPLETE] = $table[CTRL_COMPLETE] . $Ctrl_Table[CTRL_COMPLETE]{inactive};
            }
        }

    }
    if ($seq != SEQ_NOP) { 
        # here we will check that nCCD is not violated for DDR2/3
        if ($Mem_Config->{mem_type} eq "ddr2" || $Mem_Config->{mem_type} eq "ddr3") { 
          for (my $j=($Mem_Config->{nCCD}-1); $j<length($table[3]) ; $j++) {
            if (substr($table[3], $j, 1) == 0) {
              foreach my $k (1 .. $Mem_Config->{nCCD}-1) {
                if (substr($table[3], $j-$k, 1) == 0) {
                  print "Error: nCCD value of $Mem_Config->{nCCD} has been violated. For more information on this error, please consult the Answers Database or open a WebCase with this project attached at http://www.xilinx.com/support.\n";
                  print $errorfile "Error: nCCD value of $Mem_Config->{nCCD} has been violated. For more information on this error, please consult the Answers Database or open a WebCase with this project attached at http://www.xilinx.com/support.\n";
                  die "Error: nCCD value of $Mem_Config->{nCCD} has been violated. For more information on this error, please consult the Answers Database or open a WebCase with this project attached at http://www.xilinx.com/support.\n"; 
                }
              }
            }
          }
        }
        if ($Use_DFI == 1) { 

            # Data to arrive one cycle after wrdata_en, data takes 3 cycles to arrive after pop, therefore we need to move this up 2 cycles
            # Change the delay value instead if we can't shift 2 spots.
            if ($table[CTRL_DP_WRFIFO_POP] =~ /^00.*/) { 
                $table[CTRL_DP_WRFIFO_POP] = rotate_string_left($table[CTRL_DP_WRFIFO_POP], 2);
            } elsif ($WRFIFO_POP_DELAY_BY1) { 
                $table[CTRL_DP_WRFIFO_POP] = rotate_string_left($table[CTRL_DP_WRFIFO_POP], 1);
            } elsif (($delay[CTRL_DP_WRFIFO_POP] >= 1 && $table[CTRL_DP_WRFIFO_POP] =~ /^01.*/) || $WRFIFO_POP_DELAY_BY1) { 
                $table[CTRL_DP_WRFIFO_POP] = rotate_string_left($table[CTRL_DP_WRFIFO_POP], 1);
                $delay[CTRL_DP_WRFIFO_POP]--;
                $WRFIFO_POP_DELAY_BY1 = 1;
            }

            #$table[CTRL_AP_COL_CNT_ENABLE] = rotate_string_left($table[CTRL_AP_COL_CNT_ENABLE], 1);
            $table[CTRL_AP_COL_CNT_LOAD] = rotate_string_left($table[CTRL_AP_COL_CNT_LOAD], 1);

        } else { 
            ### Move Ctrl_Skip and Ctrl_PhyIF_DQS_O back by 1 cycle if activate takes 3 cycles or longer and not ECC.
            ### Move delay forward by 1 cycle.
            $table[CTRL_AP_COL_CNT_LOAD] = rotate_string_left($table[CTRL_AP_COL_CNT_LOAD], 1);
            if ((ceil($Mem_Config->{nRCD}) - 2 > 0) && ($Mem_Config->{enable_ecc}==0)) {

                $table[CTRL_SKIP_0] = rotate_string_left($table[CTRL_SKIP_0], 1);
                $table[CTRL_SKIP_1] = rotate_string_left($table[CTRL_SKIP_1], 1);
                $table[CTRL_SKIP_2] = rotate_string_left($table[CTRL_SKIP_2], 1);
                $table[CTRL_PHYIF_DQS_O] = rotate_string_left($table[CTRL_PHYIF_DQS_O], 1);
            }

            ### Move Ctrl_DP_RdFIFO_Push back by 1 cycle if not ECC.
            if ($Mem_Config->{enable_ecc} == 0) {
                $table[CTRL_DP_RDFIFO_PUSH] = rotate_string_left($table[CTRL_DP_RDFIFO_PUSH], 1);
            }

            ### else If ECC, move Ctrl_PhyIF_DQS_O back by 2 cycles, otherwise move back
            ### by 1 cycle.
            if ($Mem_Config->{enable_ecc} == 1) {
                $table[CTRL_PHYIF_DQS_O] = rotate_string_left($table[CTRL_PHYIF_DQS_O], 2);
                $table[CTRL_PHYIF_FORCE_DM] = rotate_string_left($table[CTRL_PHYIF_FORCE_DM], 3);
            }
            else {
                $table[CTRL_PHYIF_DQS_O] = rotate_string_left($table[CTRL_PHYIF_DQS_O], 1);
                $table[CTRL_PHYIF_FORCE_DM] = rotate_string_left($table[CTRL_PHYIF_FORCE_DM], 2);
            }

            ### If SDRAM, move Ctrl_PhyIF_Force_DM back by 1 more cycle.
            ### This will not work with ECC.
            if ($Mem_Config->{mem_type} eq "sdram") {
                $table[CTRL_PHYIF_FORCE_DM] = rotate_string_left($table[CTRL_PHYIF_FORCE_DM], 1);
            }

        }
    }


        
    # Check table lengths
    my $tmp = length($table[CTRL_COMPLETE]);
    for (my $j=0;$j<BRAM_WIDTH;$j++) {
        if ($tmp != length($table[$j])) {
            print "Error: $Seq_Table[$seq]{name} table not generated correctly.  Inconsistent lengths.  For more information on this error, please consult the Answers Database or open a WebCase with this project attached at http://www.xilinx.com/support.\n";
            for (my $k=0;$k<BRAM_WIDTH;$k++) {
                print "Table $k: $table[$k]\n";
            }
            print $errorfile "Error: $Seq_Table[$seq]{name} table not generated correctly.  Inconsistent lengths.\n";
            for (my $k=0;$k<BRAM_WIDTH;$k++) {
                print $errorfile "Table $k: $table[$k]\n";
            }
            die "Aborting Script: $Seq_Table[$seq]{name} table not generated correctly.  Inconsistent lengths.  For more information on this error, please consult the Answers Database or open a WebCase with this project attached at http://www.xilinx.com/support.\n";
        }
    }
    
    my $end_addr = $start_addr + length($table[CTRL_COMPLETE]) - 1;
    print $odata_ver "parameter C_BASEADDR_CTRL$seq = 9'h", sprintf("%03x", $start_addr), ";\n";
    print $odata_ver "parameter C_HIGHADDR_CTRL$seq = 9'h", sprintf("%03x", $end_addr), ";\n";
    if ($end_addr > 2**9-1) {
        print "Error: C_HIGHADDR_CTRL$seq too large.  Need to reduce sequence lengths.\n";
        print $errorfile "Error: C_HIGHADDR_CTRL$seq too large.  Need to reduce sequence lengths.\n";
        die "Aborting Script: C_HIGHADDR_CTRL$seq too large.  Need to reduce sequence lengths.\n";
    }

    ### Calculate length of skip
    my $skip_value;
    if ($Mem_Config->{enable_ecc} == 1) {
        my $table_2_length = length($table[2]);
        my @table_2 = split(//, $table[2]);
        my @table_3 = split(//, $table[3]);
        my @table_4 = split(//, $table[4]);
        my $read_index = 0;
        my $write_index = 0;
        for (my $j=0;$j<$table_2_length;$j++) {
            if (($table_2[$j]==1) && ($table_3[$j]==0) && ($table_4[$j]==1)) {
                $read_index = $j;
            }
            if (($table_2[$j]==1) && ($table_3[$j]==0) && ($table_4[$j]==0)) {
                $write_index = $j;
            }
        }
        $skip_value = $write_index - $read_index + 1;
    }
    else {
        $skip_value = 1;
    }
    $skip_value=sprintf("%03x", $skip_value);
    if ($seq == SEQ_WORD_WRITE) {
        print $odata_ver "parameter integer C_SKIP_1_VALUE = 9'h$skip_value;\n";
    }
    elsif ($seq == SEQ_DWORD_WRITE) {
        print $odata_ver "parameter integer C_SKIP_2_VALUE = 9'h$skip_value;\n";
    }
    elsif ($seq == SEQ_CL4_WRITE) {
        print $odata_ver "parameter integer C_SKIP_3_VALUE = 9'h$skip_value;\n";
    }
    elsif ($seq == SEQ_CL8_WRITE) {
        print $odata_ver "parameter integer C_SKIP_4_VALUE = 9'h$skip_value;\n";
    }
    elsif ($seq == SEQ_B16_WRITE) {
        print $odata_ver "parameter integer C_SKIP_5_VALUE = 9'h$skip_value;\n";
    }
    elsif ($seq == SEQ_B32_WRITE) {
        print $odata_ver "parameter integer C_SKIP_6_VALUE = 9'h$skip_value;\n";
    }
    elsif ($seq == SEQ_B64_WRITE) {
        print $odata_ver "parameter integer C_SKIP_7_VALUE = 9'h$skip_value;\n";
    }

    my $cnt = $start_addr;
    # Print out the table for debugging    
    print $odata "//--------------------------------------------------------------------------\n";
    print $odata "//\n";
    #print "FSM PATTERN $seq: $Seq_Table[$seq]{name} created\n";
    print $odata "// FSM PATTERN $seq: $Seq_Table[$seq]{name}\n";
    print $odata "//\n";
    print $odata "// Control Signals                       ";
    for (my $cnt = $start_addr; $cnt <=$end_addr; $cnt++) { 
        if ($cnt % (16*16) == 0 || $cnt == $start_addr || $cnt == $end_addr) { 
            print $odata sprintf("%x", $cnt/(16*16));
        } else { 
            print $odata " ";
        }
    }
    print $odata "\n";
    print $odata "                                         ";
    for (my $cnt = $start_addr; $cnt <=$end_addr; $cnt++) { 
        if ($cnt % 16 == 0 || $cnt == $start_addr || $cnt == $end_addr) { 
            print $odata sprintf("%x", ($cnt % (16*16))/16);
        } else { 
            print $odata " ";
        }
    }
    print $odata "\n";
    print $odata "// (32 Signals)                          ";
    for (my $cnt = $start_addr; $cnt <= $end_addr; $cnt++) { 
        print $odata sprintf("%x", $cnt % 16);
    }
    print $odata "\n";
    print $odata "// ---------------                       --------------------------------  ------------------------------\n";   
    for (my $i = 0; $i < BRAM_WIDTH; $i++) { 
        print $odata "/*    " . sprintf("%2d %-28s", $i, $Ctrl_Table[$i]{name}) . "*/  " . $table[$i]. "  // Delayed by " . $delay[$i] . "\n";
    }

    for (my $col = 0; $col < length($table[CTRL_COMPLETE]); $col++) {
        for (my $table_row = 0; $table_row < 32; $table_row++) {
            unshift (@ctrl_bram_table, (substr($table[$table_row], $col, 1)));
        }
        for (my $table_row = 32; $table_row < BRAM_WIDTH; $table_row++) {
            unshift (@ctrl_bram_tablep, (substr($table[$table_row], $col, 1)));
        }
        $ctrl_bram_index = $ctrl_bram_index + 1;
        if ($ctrl_bram_index % 8 == 0) {
            my $hex_table =  unpack("H*", pack("B*", join("",@ctrl_bram_table)));
            $ctrl_bram_init[($ctrl_bram_index/8)-1] = $hex_table;
            @ctrl_bram_table = ();
        }
        if ($ctrl_bram_index % 64 == 0) {
            my $hex_table =  unpack("H*", pack("B*", join("",@ctrl_bram_tablep)));
            $ctrl_bram_initp[($ctrl_bram_index/64)-1] = $hex_table;
            @ctrl_bram_tablep = ();
        }
    }
    # Next start addr
    $start_addr = $end_addr + 1;

}

# let's pad the rest with no ops
while ($ctrl_bram_index <= 0x40*8) {
    unshift(@ctrl_bram_table, "00000000000000000000001011111100");  # pad with noop commands
    unshift(@ctrl_bram_tablep, "0000");
    $ctrl_bram_index = $ctrl_bram_index + 1;
    if ($ctrl_bram_index % 8 == 0) {
        my $hex_table =  unpack("H*", pack("B*", join("",@ctrl_bram_table)));
        $ctrl_bram_init[($ctrl_bram_index/8)-1] = $hex_table;
        @ctrl_bram_table = ();
    }
    if ($ctrl_bram_index % 64 == 0) {
        my $hex_table =  unpack("H*", pack("B*", join("",@ctrl_bram_tablep)));
        $ctrl_bram_initp[($ctrl_bram_index/64)-1] = $hex_table;
        @ctrl_bram_tablep = ();
    }
}

for (my $i = 0x3F ; $i >= 0; $i-- ) {
    print $odata_ver "parameter C_CTRL_BRAM_INIT_", sprintf("%02X", $i), " = 256'h", uc($ctrl_bram_init[$i]), ";\n";
}
print $odata_ver "parameter C_CTRL_BRAM_SRVAL = 36'h0000002FC;\n";
for (my $i = 0x7 ; $i >= 0; $i-- ) {
    print $odata_ver "parameter C_CTRL_BRAM_INITP_", sprintf("%02X", $i), " = 256'h", uc($ctrl_bram_initp[$i]), ";\n";
}


# Output the delays
for (my $i = 0; $i < BRAM_WIDTH; $i++) { 
    print $odata_ver "parameter C_CTRL_Q" . $i . "_DELAY = " . $delay[$i] . ";\n";
}
# Assign Control Path Delays
if ($delay[CTRL_RMW] >= 2 && $Use_DFI == 0) { 
    print $odata_ver "parameter C_CTRL_ARB_RDMODWR_DELAY = " . ($delay[CTRL_RMW] - 2) . ";\n";
} else { 
    print $odata_ver "parameter C_CTRL_ARB_RDMODWR_DELAY = " . 0 . ";\n";
}
print $odata_ver "parameter C_CTRL_AP_COL_DELAY = " . $ap_pipeline1 . ";\n";
print $odata_ver "parameter C_CTRL_AP_PI_ADDR_CE_DELAY = " . 0 . ";\n";
print $odata_ver "parameter C_CTRL_AP_PORT_SELECT_DELAY = " . 0 . ";\n";
print $odata_ver "parameter C_CTRL_AP_PIPELINE1_CE_DELAY = " . 0 .";\n";
print $odata_ver "parameter C_CTRL_DP_LOAD_RDWDADDR_DELAY = " . ($ap_pipeline1 + 1) . ";\n";

my $C_CTRL_DP_RDFIFO_WHICHPORT_DELAY;

if ($Use_DFI) { 
    # Defined by DFI spec (PHY_RDLAT)
    $C_CTRL_DP_RDFIFO_WHICHPORT_DELAY = $Mem_Config->{tPHY_RDLAT};
} else { 
    $C_CTRL_DP_RDFIFO_WHICHPORT_DELAY = $ap_pipeline1 + $ap_pipeline2 + $Mem_Config->{cas_latency}/$nCK_PER_CLK + $Mem_Config->{nAL} + 7;
    if ($Mem_Config->{mem_type} eq "sdram") { 
        $C_CTRL_DP_RDFIFO_WHICHPORT_DELAY = $C_CTRL_DP_RDFIFO_WHICHPORT_DELAY - 1;
    } elsif ($Mem_Config->{mem_type} eq "ddr" && $family eq "spartan3" && $static_phy == 0) { 
        $C_CTRL_DP_RDFIFO_WHICHPORT_DELAY = $C_CTRL_DP_RDFIFO_WHICHPORT_DELAY + 1;
    }
}
if ($C_CTRL_DP_RDFIFO_WHICHPORT_DELAY >= 18) { 
    print "Error: CAS Latency is too high causing delays outside the hardware design specs.  Please use a lower CAS Latency. Cannot Calculate C_CTRL_DP_RDFIFO_WHICHPORT_DELAY.\n";
    print $errorfile "Error: CAS Latency is too high causing delays outside the hardware design specs.  Please use a lower CAS Latency. Cannot Calculate C_CTRL_DP_RDFIFO_WHICHPORT_DELAY.\n";
    die "Aborting script: Error: CAS Latency is too high causing delays outside the hardware design specs.  Please use a lower CAS Latency. Cannot Calculate C_CTRL_DP_RDFIFO_WHICHPORT_DELAY.\n";
}
print $odata_ver "parameter C_CTRL_DP_RDFIFO_WHICHPORT_DELAY = " . $C_CTRL_DP_RDFIFO_WHICHPORT_DELAY . ";\n";

print $odata_ver "parameter C_CTRL_DP_SIZE_DELAY = " . ($ap_pipeline1 + 1) . ";\n";
if ($Use_DFI) {
    print $odata_ver "parameter C_CTRL_DP_WRFIFO_WHICHPORT_DELAY = " . $delay[CTRL_DP_WRFIFO_POP] . ";\n";
} else { 
    if ($Mem_Config->{mem_type} eq "sdram" || $Mem_Config->{mem_type} eq "ddr") {
        print $odata_ver "parameter C_CTRL_DP_WRFIFO_WHICHPORT_DELAY = " . ($ap_pipeline1 + $ap_pipeline2 + $Mem_Config->{nDQSS}) . ";\n";
    } else {  #ddr2
        print $odata_ver "parameter C_CTRL_DP_WRFIFO_WHICHPORT_DELAY = " . ($ap_pipeline1 + $ap_pipeline2 + $Mem_Config->{nWL}) . ";\n";
    }
}
print $odata_ver "parameter C_CTRL_PHYIF_DUMMYREADSTART_DELAY = " . ($ap_pipeline1 + $ap_pipeline2 + 3) . ";\n";

close($errorfile);
close ($odata);
close ($odata_ver);
