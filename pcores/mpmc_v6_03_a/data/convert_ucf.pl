#!/usr/local/bin/perl -w
#******************************************************************************
#
#       XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
#       AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND
#       SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,
#       OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
#       APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION
#       THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
#       AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
#       FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
#       WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
#       IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
#       REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
#       INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#       FOR A PARTICULAR PURPOSE.
#
#       (c) Copyright 2007 Xilinx Inc.
#       All rights reserved.
#
#
#******************************************************************************
use strict;
use Getopt::Long;

# global variables
my %options;
my $mem_type;
my $input_file;
my $mhs_file;
my $batch;
my $output_file;
my $answer;
my %mpmc = ();
my %mhs_inst = ();
my %mhs_port = ();
my $mpmc_core = "mpmc_core_0";
my $mpmc_full_phy_path;
my $mpmc_phy;
my $mpmc_inst;
my $mih;
my $mig;
my $mig_pin_prefix = "cntrl0";
my $count;
my %conversions;
my $linenew;
my $saveline = '';
my $clk_period;
my $clk_width;
my $odt_width;
my $cs_n_width;
my $ce_width;
my $family;
my $comment_mig_only_reason = "# The constraint below commented out because it is a MIG only constraint and is not applicable in MPMC.";
my $comment_clk_reason = "# The constraint below commented out because it is a global clock constraint that should be inherited from the EDK system level UCF.";

my $usage = "This program converts a MIG ucf file to an EDK MPMC ucf file

example usage: 
\tconvert_ucf.pl [--mhs <MHS file>] [--mpmc_clk0_period <clk period>] [--family <family>] <MIG UCF>  <Output UCF>

where:
<MHS file>          is an optional mhs file to read to parse the pin names (recommended)
<clk period>        is the value of C_MPMC_CLK0_PERIOD_PS (recommended if this parameter is not specified in the mhs)
<family>            is the xilinx family. Valid Values: spartan3, virtex4, virtex5 and virtex6.
<MIG UCF>           is the name of the .ucf file generated from Coregen MIG (see user guide for versions supported.) 
<Output UCF>        is the desired name of the output .ucf file (default if not specified: system.ucf). 
\n";

GetOptions ( 
    "mhs=s"         => \$mhs_file,
    "batch+"        => \$batch,
    "mem_type=s"    => \$mem_type,
    "instance=s"    => \$mpmc_inst,
    "clk_width=s"   => \$clk_width,
    "odt_width=s"   => \$odt_width,
    "cs_n_width=s"  => \$cs_n_width,
    "ce_width=s"    => \$ce_width,
    "family=s"      => \$family,
    "mpmc_clk0_period=s" => \$clk_period,
) or die $usage;

if ($#ARGV != 1)
{
    die $usage;
}

$input_file = $ARGV[0];
$output_file = $ARGV[1];

if (defined $mhs_file and defined $batch) { 
    die "ERROR: Can't specify both --mhs_file and --batch options";
}

if (not defined $family) { 
    die "ERROR: --family needs option to be specified.  Possible values are: spartan3, virtex4, virtex5, virtex6\n";
}
if (defined $batch) { 
    if (not defined $clk_width) { 
        die "ERROR: --batch option requires --clk_width option to be specified\n";
    }
    if (not defined $odt_width) { 
        die "ERROR: --batch option requires --odt_width option to be specified\n";
    }
    if (not defined $cs_n_width) { 
        die "ERROR: --batch option requires --cs_n_width option to be specified\n";
    }
    if (not defined $ce_width) { 
        die "ERROR: --batch option requires --ce_width option to be specified\n";
    }
    if (not defined $mem_type) { 
        die "ERROR: --batch option requires --mem_type option to be specified\n";
    }
    if (not defined $mpmc_inst) { 
        die "ERROR: --batch option requires --instance option to be specified\n";
    }
    if (not defined $family) { 
        die "ERROR: --batch option requires --family option to be specified\n";
    }
    if (not defined $clk_period) { 
        die "ERROR: --batch option requires --mpmc_clk0_period (in ps) option to be specified\n";
    }
}
if (defined $family) { 
    $family = lc($family);
}


open (IN, $input_file) ||
    die "ERROR: Couldn't open input data file $input_file\n\n$usage";

if (defined $mhs_file) { 
    open (MHS, $mhs_file) ||
        die "ERROR: Couldn't open input data file $mhs_file\n\n$usage";
}
 
$answer = "";

while ((-e $output_file) && ($answer ne "y") && (not defined $batch))
{
    while (!(($answer eq "y") || ($answer eq "n")))
    {
        print "$output_file already exists, do you want to overwrite the existing file? (y/n)";
        $answer = <STDIN>;
        $answer =~ s/\s*$//g;
        $answer = lc($answer);
    }
    if ($answer eq "n")
    {
        print "please enter a new name for the output file: ";
        $output_file = <STDIN>;
        $output_file =~ s/\s*$//g;
    }

}
 
open (OUT, ">$output_file") ||
    die "ERROR: Couldn't open output file\n";

# Read MHS to get the pin names and parameters, set $mem_type and $mpmc_inst

if (defined $mhs_file)  {
    # First Pass in MHS to get MPMC Instances
    while (<MHS>)
    {
        if (m/^\s*BEGIN\s*mpmc/i..m/^\s*END/i) {
            chomp;
            if (m/^\s*BEGIN\s*mpmc/i) { 
                # create new hash
                %mhs_inst = ();

                # Fill in default memory type
               $mhs_inst{ 'PARAMETER' }{ 'C_MEM_TYPE' } = "DDR2";
               # Fill in default memory
               #$mhs_inst{ 'PARAMETER' }{ 'C_MPMC_CLK0_PERIOD_PS' } = "1";
               $mhs_inst{ 'PARAMETER' }{ 'C_MEM_CLK_WIDTH' } = 1;
               $mhs_inst{ 'PARAMETER' }{ 'C_MEM_ODT_WIDTH' } = 1;
               $mhs_inst{ 'PARAMETER' }{ 'C_MEM_CS_N_WIDTH' } = 1;
               $mhs_inst{ 'PARAMETER' }{ 'C_MEM_CE_WIDTH' } = 1;
               

            } elsif (m/^\s*END/i) { 
                if (defined $mhs_inst{'PARAMETER'}{'INSTANCE'}) {
                    my $inst = $mhs_inst{'PARAMETER'}{'INSTANCE'};
                    # hack until i find a beter way to do the thing below
                    #$mpmc{ $mhs_inst{'PARAMETER'}{'INSTANCE'} } = %mhs_inst;
                    foreach my $keyword (keys %mhs_inst) { 
                        foreach my $key (keys %{$mhs_inst{$keyword}}) { 
                            $mpmc{ $inst }{ $keyword }{ $key } = $mhs_inst{$keyword}{$key};
                        }
                    }
               }
               else {
                   die "Error reading MHS: No instance name found.";
               }

            }
            elsif (m/^\s*(\w+)\s+(\S+)\s*=\s*(\S+).*/)
            {
                my $keyword;
                my $id;
                my $value;

                ($keyword = uc($_)) =~ s/^\s*(\w+)\s+(\S+)\s*=\s*(\S+)/$1/;
                ($id = uc($_)) =~ s/^\s*(\S+)\s+(\S+)\s*=\s*(\S+)/$2/;
                ($value = $_) =~ s/^\s*(\S+)\s+(\S+)\s*=\s*(\S+)/$3/;
                $mhs_inst{ $keyword }{ $id } = $value;
                #print "Middle $mhs_inst{ 'PARAMETER' }{ 'C_MEM_TYPE' }\n";
                #print "$keyword->$id = $value\n";
            }
        }

    }

    # Second Pass in MHS to get External Ports of the mhs
    seek MHS,0,0; 
    while (<MHS>)
    {
        chomp;
        if (m/^\s*BEGIN\s*/i..m/^\s*END/i) {
            # Do nothing if inside an instance
        }
        elsif (m/^\s*(port)\s+(\S+)\s*=\s*(\S+).*/i)
        {
           my $name;
           my $value;
           ($name = $_) =~ s/^\s*(port)\s+(\S+)\s*=\s*(\w+).*/$2/i;
           ($value = $_) =~ s/^\s*(port)\s+(\S+)\s*=\s*(\w+).*/$3/i;
           # store this hash {Internal Port Name} = External Port Name hash for easy lookup
           $mhs_port{ $value }{ 'NAME' } = $name;

           # get attributes so we know if it is a vector or not
           my @attr = split(',');
           shift @attr;

           foreach my $attr (@attr) {
               my $attr_name;
               my $attr_val;
               ($attr_name = $attr) =~ s/\s*(\S+)\s*=\s*(\S+)\s*/$1/;
               ($attr_val = $attr) =~ s/\s*(\S+)\s*=\s*(\S+)\s*/$2/;
               $mhs_port{ $value }{ uc($attr_name) } = $attr_val;
           }
        }

    }
    close MHS;

    # If more than 1 instance of mpmc, pick one.
    if (keys(%mpmc) > 1)
    {
        $answer = 0;

        while ($answer < 1 or $answer > keys(%mpmc))
        {
            print "MPMC Instances found in \"$mhs_file\":\n";
            $count = 1;
            foreach my $inst (sort keys %mpmc) 
            {
                print "\t" . $count . ") " . $inst . "\n";
                $count++;
            }
            print "Multiple MPMC instances found in MHS file.  Please choose the instance the file \"$input_file\" corresponds to (1-" . keys (%mpmc) . "): ";
            $answer = <STDIN>;
            chomp $answer;
            unless ($answer =~ m/^[0-9]+$/) {
                $answer = 0;
            }
        }

    } 

    $count = 1;

    foreach my $inst (sort keys %mpmc) 
    {
        if (((keys %mpmc) == 1) or ($count == $answer)) 
        {
            $mpmc_inst = $inst;
        }
        $count++;
    }

    print "Set MPMC Instance to " . $mpmc_inst . "\n";

    $mem_type = uc($mpmc{$mpmc_inst}{ 'PARAMETER' }{ 'C_MEM_TYPE' });
    print "Mem Type is $mem_type\n";

    unless ($mem_type eq "DDR3" or $mem_type eq "DDR2" or $mem_type eq "DDR")  
    {
        die "Memory type \"$mem_type\" is not supported for this script.\n"
    }

    if (defined $mpmc{$mpmc_inst}->{ 'PARAMETER' }{ 'C_MPMC_CLK0_PERIOD_PS'}) { 
        my $mhs_clk_period = $mpmc{$mpmc_inst}->{ 'PARAMETER' }{ 'C_MPMC_CLK0_PERIOD_PS'};
        print "Clk Period from MHS is $mhs_clk_period ps\n";

        if (not defined $clk_period) { 
            $clk_period = $mhs_clk_period;
        } else { 
            print "Using Clk Period passed on the command line: $clk_period ps\n";
        }
        if ($clk_period != $mhs_clk_period) { 
            print "Warning: Clock Period in the MHS does not match the clock period passed on the command line.\n";
        }
    } else  { 
        $clk_period = 3000;
        print "Warning: Clock period not found in MHS, setting default value to 3000 ps.  If you want the correct clock period, please specify the C_MPMC_CLK0_PERIOD_PS parameter in your MPMC MHS instance.\n";
    }
    $clk_width = $mpmc{$mpmc_inst}->{ 'PARAMETER' }{ 'C_MEM_CLK_WIDTH' };
    $odt_width = $mpmc{$mpmc_inst}->{ 'PARAMETER' }{ 'C_MEM_ODT_WIDTH' };
    $cs_n_width = $mpmc{$mpmc_inst}->{ 'PARAMETER' }{ 'C_MEM_CS_N_WIDTH' };
    $ce_width = $mpmc{$mpmc_inst}->{ 'PARAMETER' }{ 'C_MEM_CE_WIDTH' };
} elsif (not defined $batch) {
    $mpmc_inst = "*";
    $mem_type = "DDR*";
    $clk_period = 3000; # defaulting to worst case speed of 333MHz
}



# set parameters for this design
if (not defined $family) { 
    $mpmc_phy = "gen_??_" . lc($mem_type) . "_phy.mpmc_phy_if_0";
} elsif ($family eq "virtex6") { 
    $mpmc_phy = "gen_v6_" . lc($mem_type) . "_phy.mpmc_phy_if_0";
} elsif ($family eq "virtex5") { 
    $mpmc_phy = "gen_v5_" . lc($mem_type) . "_phy.mpmc_phy_if_0";
} elsif ($family eq "virtex4") { 
    $mpmc_phy = "gen_v4_" . lc($mem_type) . "_phy.mpmc_phy_if_0";
} elsif ($family =~ m/spartan3/) { 
    $mpmc_phy = "gen_s3_" . lc($mem_type) . "_phy.mpmc_phy_if_0";
} else { 
    print "Warning: Family $family not recognized. Using liberal glob/match rules.";
    $mpmc_phy = "gen_??_" . lc($mem_type) . "_phy.mpmc_phy_if_0";
}

if (defined $batch) {
    $mpmc_full_phy_path = "$mpmc_inst/$mpmc_core/$mpmc_phy";
} else { 
    $mpmc_full_phy_path = "*/$mpmc_inst/$mpmc_core/$mpmc_phy";
}
$mig = $mig_pin_prefix . "_" . $mem_type;

## BEGIN Constraints Modifications##

# Comment out Clock/Reset/debug Constraints
$conversions{qr|(net.*sys_clk)|i} = $comment_clk_reason . "#\$1";
$conversions{qr|(net.*idly_clk_)|i} = $comment_clk_reason . "#\$1";
$conversions{qr|(timespec\s*"ts_sys_clk\w*")|i} = "#\$1";
$conversions{qr|(.*clk_dcm0)|i} = "#\$1";
$conversions{qr|(.*clk200)|i} = "#\$1";
$conversions{qr|(.*clk_ref)|i} = "#\$1";
$conversions{qr|(.*u_mmcm.*)|i} = "#\$1";
$conversions{qr/(NET.*(reset_in_n|sys_rst))/i} = "#\$1";
$conversions{qr/NET\s*"((${mig_pin_prefix}_)?(led_error_output1|data_valid_out|(phy_)?init_done))"/} = "#NET  \"\$1\$2\"";   
$conversions{qr|^(.*LOC\s*=\s*IDELAYCTRL)|i} = "#\$1";

# Top level conversions
$conversions{qr|infrastructure_top(0)?|} = "$mpmc_full_phy_path/infrastructure";
$conversions{qr/(top_00|main_00\/top0)/} = "$mpmc_full_phy_path";
$conversions{qr|(\*/)?(u_ddr(1)?_top(_0)?/)?u_mem_if_top/u_phy_top|} = "$mpmc_full_phy_path";
# V6 top level conversion
$conversions{qr|u_memc_ui_top/u_mem_intfc/phy_top0|} = "$mpmc_full_phy_path";
$conversions{qr|\*/phy_top0|} = "$mpmc_full_phy_path";
# The line below is used if we want to include idelayctrl in the ucf.
#$conversions{qr/(\*idelay_ctrl0|u_ddr_idelay_ctrl)?\/IDELAY(CTRL)?_INST\[(\d+)\]\.u_idelayctrl/} = "*/$mpmc_inst/gen_instantiate_idelayctrls[\$3].idelayctrl0";

if (not defined $family or $family =~ m/spartan3/) { 
    # Spartan3 Phy Specific
    # Convert clocks and unconstrained paths
    if (defined $batch) { 
        $conversions{qr|(NET\s*").*("\s*TNM_NET\s*=\s*"clk0")|i} = "\$1MPMC_Clk0\$2";
        $conversions{qr|(NET\s*").*("\s*TNM_NET\s*=\s*"clk90")|i} = "\$1MPMC_Clk90\$2";

    } else { 
        $conversions{qr|(NET\s*").*("\s*TNM_NET\s*=\s*"clk0")|i} = "\$1$mpmc_inst/MPMC_Clk0\$2";
        $conversions{qr|(NET\s*").*("\s*TNM_NET\s*=\s*"clk90")|i} = "\$1$mpmc_inst/MPMC_Clk90\$2";
    }
    $conversions{qr|(NET\s*".*)_controller.*("\s*TNM_NET\s*=\s*"fifo_we_clk")|i} = "\$1/dqs_delayed_col*\$2";
    $conversions{qr|(^.*fifo_waddr_clk)|i} = "#\$1";
    

    
    # Convert suffixes on modules
    $conversions{qr|(/data_path)(0)?|} = "\$1";
    $conversions{qr|(/data_read)(0)?|} = "\$1";
    $conversions{qr|(/data_read_controller)(0)?|} = "\$1";
    $conversions{qr|(/cal_top)(0)?|} = "\$1";
    $conversions{qr|(/cal_ctl)(0)?|} = "\$1";
    $conversions{qr|(/cal_ctl)(0)?"|} = "\$1*\"";
    $conversions{qr|(/tap_dly)(0)?/|} = "\$1/";
    $conversions{qr|(/tap_dly)(0)?"|} = "\$1*\"";
    $conversions{qr|(_controller)(0)?/gen_wr_addr|} = "/gen_wr_addr";

    # Transformations done here.  S3 Has major structural changes
    $conversions{qr|/l(\d+)|} = "/gen_no_sim.l\$1";  # Transform '/l0' to '/gen_no_sim.l0'
    $conversions{qr|gen_tap1|} = "gen_no_sim.gen_tap1";  # Transform 'gen_tap1' to '/gen_no_sim.gen_tap1'
    $conversions{qr|/controller(0)?/rst_dqs_div_r|} = "/dqs_div/dqs_rst_ff";  
    $conversions{qr|gen_delay\*dqs_delay_col\*/delay\*|} = "gen_dqs[*]*u_dqs_delay_col*/delay*";
    $conversions{qr|gen_strobe\[(\d+)\]\.strobe(_n)*/fifo_bit(\d+)|} = "gen_data[\$1]*strobe0\$2/gen_data[\$3]*u_fifo_bit";
    $conversions{qr|gen_delay\[(\d+)\]\.dqs_delay_col(\d+)/(\w+)|} = "gen_dqs[\$1]*u_dqs_delay_col\$2/gen_delay.\$3";
    $conversions{qr|fifo_(\d+)_wr_addr_inst/bit(\d+)|} = "u_fifo_\$1_wr_addr/gen_addr[\$2].u_addr_bit";
    $conversions{qr|gen_wr_en\[(\d+)\]\.fifo_(\d+)_wr_en_inst|} = "gen_wr[\$1].u_fifo_\$2_wr_en/*";
    $conversions{qr|(rst_dqs_div_delayed)/(\w+[^*]")|} = "*\$1/gen_delay.\$2";
    $conversions{qr|(rst_dqs_div_delayed)/(\w+\*")|} = "*\$1/\$2";
    $conversions{qr|data_read(0)?/fifo\*_wr_en\*|} = "fifo*_wr_en*";
    $conversions{qr|fifo\*_wr_addr\[\*\]|} = "fifo*_wr_addr*";
}

##Virtex-4 DDR specific
if (not defined $family or $family eq "virtex4") { 
    $conversions{qr|(/iobs_0)(0)?|} = "\$1";
    $conversions{qr|(/tap_logic_0)(0)?|} = "\$1";
    $conversions{qr|v4_dqs_iob(\d)|} = "gen_v4_phy_dqs_iob[\$1].";
    $conversions{qr|(^.*data_tap_gp\d)|} = "#\$1";
}

#Virtex-5 Specific
# DDR2
if (not defined $family or $family eq "virtex5") { 
    $conversions{qr|"TS_SYS_CLK"\s*\*\s*4|} = ($clk_period * 4) . " ps";
    $conversions{qr|U_PHY|} = ($clk_period * 4) . " ps";
    $conversions{qr|([^\w])\*/u_phy_calib/|} = "\$1$mpmc_full_phy_path/u_phy_io_0/u_phy_calib_0/";
    $conversions{qr|^(.*TNM_RDEN_SEL_MUX)|} = $comment_mig_only_reason . "#\$1"; # not in MPMC
    $conversions{qr|([^\w])\*/u_phy_init/|} = "\$1$mpmc_full_phy_path/u_phy_init_0/";
    # DDR1 uses u_phy_io, DDR2 using u_phy_io_0.  Added the glob to catch both.
    $conversions{qr|([^\w])\*/gen_dq|} = "\$1$mpmc_full_phy_path/u_phy_io*/gen_dq";
    $conversions{qr|([^\w])\*/u_phy_io/|} = "\$1$mpmc_full_phy_path/u_phy_io_0/";
    $conversions{qr|/u_phy_io/u_phy_calib/gen_gate|} = "/u_phy_io_0/u_phy_calib_0/gen_gate";
}

if (not defined $family or $family eq "virtex6") { 
    # specify this constraint as *4 the mpmc_clk0_period_ps which is mpmc_clk_mem_period_ps*8
    $conversions{qr|(.*)"TS_sys_clk"\s*\*\s*(2)|} = "\$1" . $clk_period  . " ps";
    $conversions{qr|(.*)"TS_sys_clk"\s*\*\s*(4)|} = "\$1" . $clk_period*2  . " ps";
    # for v6 DDR2
    $conversions{qr|([^\w])\*/u_phy_init/|} = "\$1$mpmc_full_phy_path/u_phy_init/";
}

# Pin names conversion
# Convert the MIG pin names to the external pin names specified in the MHS. 
# Some of these are more complicated to convert when moving from vector to non-vectors and vice-versa
if (defined $mhs_file) {

    # Clock port is defined as vector in the MHS and we are assuming it's a vector in the UCF
    if (defined $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'VEC' }) {
        for (my $i = 0; $i < 9; $i++ ) { 
            if ( $i < $clk_width) { 
                
                $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK(_P)?\[$i\]|i}       = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'NAME' } . "[$i]";
                $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK_N\[$i\]|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK_N" }}{ 'NAME' } . "[$i]";
            } else { 
                # Comment out the unused CLK ports defined in the UCF.
                $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CK(_P)?(\[$i\]"?)|i}        = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'NAME' } . "\$4";
                $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CK_N(\[$i\]"?)|i}      = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK_N" }}{ 'NAME' } . "\$3";
            }                   
        }
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK(_P)?\[\*\]|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'NAME' } . "[*]";
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK_N\[\*\]|i}    = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK_N" }}{ 'NAME' } . "[*]";
        # if no vector defined on the mig ucf, then we need to assume the vector is 0:0 and convert non-vectors to [0]
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK(_P)?"|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'NAME' } . '[0]"';
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK_N"|i}    = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK_N" }}{ 'NAME' } . '[0]"';
    }
    else {  # this case the mhs has no vector, therefor we are 1 bit wide, use [0] only, but handle case where no vectors in the ucf either
        # Convert CK to CLK.  Covers the case where the ucf is not vectorized.
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK(_P)?"|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'NAME' } . '"';
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK_N"|i}   = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK_N" }}{ 'NAME' } . '"';
        # Converts CK[0] to CLK
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK(_P)?\[0\]|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'NAME' };
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK_N\[0\]|i}   = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK_N" }}{ 'NAME' };
        # Converts CK[*] to CLK
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK(_P)?\[\*\]|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'NAME' };
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK_N\[\*\]|i}    = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK_N" }}{ 'NAME' };
        # Comment out any other Clk pins.  
        for (my $i = 1; $i < 9; $i++ ) { 
           $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CK(_P)?(\[$i\]"?)|i}        = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK"}}{ 'NAME' } . "\$4";
           $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CK_N(\[$i\]"?)|i}      = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CLK_N" }}{ 'NAME' } . "\$3";
       }
    }
    # Clock Enable port is defined as vector in the MHS and we are assuming it's a vector in the UCF
    if (defined $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'VEC' }) {
        for (my $i = 0; $i < 9; $i++ ) { 
            if ( $i < $ce_width) { 
                $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE\[$i\]|i}       = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'NAME' } . "[$i]";
            } else { 
                # Comment out the unused CE ports defined in the UCF.
                $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CKE(\[$i\]"?)|i}        = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'NAME' } . "\$3";
            }                   
        }
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE\[\*\]|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'NAME' } . "[*]";
        # if no vector defined on the mig ucf, then we need to assume the vector is 0:0 and convert non-vectors to [0]
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE"|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'NAME' } . '[0]"';
    }
    else {  # this case the mhs has no vector, therefor we are 1 bit wide, use [0] only, but handle case where no vectors in the ucf either
        # Convert CKE to CE.  Covers the case where the ucf is not vectorized.
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE"|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'NAME' } . '"';
        # Converts CKE[0] to CE
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE\[0\]|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'NAME' };
        # Converts CKE[*] to CE
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE\[\*\]|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'NAME' };
        # Comment out any other CE pins.  
        for (my $i = 1; $i < 9; $i++ ) { 
           $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CKE(\[$i\]"?)|i}        = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CE"}}{ 'NAME' } . "\$3";
       }
    }
    # Chip Select Not port is defined as vector in the MHS and we are assuming it's a vector in the UCF
    if (defined $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'VEC' }) {
        for (my $i = 0; $i < 9; $i++ ) { 
            if ( $i < $cs_n_width) { 
                $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N\[$i\]|i}       = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'NAME' } . "[$i]";
            } else { 
                # Comment out the unused CS_N ports defined in the UCF.
                $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CS_N(\[$i\]"?)|i}        = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'NAME' } . "\$3";
            }                   
        }
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N\[\*\]|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'NAME' } . "[*]";
        # if no vector defined on the mig ucf, then we need to assume the vector is 0:0 and convert non-vectors to [0]
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N"|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'NAME' } . '[0]"';
    }
    else {  # this case the mhs has no vector, therefor we are 1 bit wide, use [0] only, but handle case where no vectors in the ucf either
        # Convert CS_N to CS_N.  Covers the case where the ucf is not vectorized.
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N"|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'NAME' } . '"';
        # Converts CS_N[0] to CS_N
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N\[0\]|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'NAME' };
        # Converts CS_N[*] to CS_N
        $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N\[\*\]|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'NAME' };
        # Comment out any other CS_N pins.  
        for (my $i = 1; $i < 9; $i++ ) { 
           $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CS_N(\[$i\]"?)|i}        = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CS_N"}}{ 'NAME' } . "\$3";
       }
    }
    # Clock Enable port is defined as vector in the MHS and we are assuming it's a vector in the UCF
    if (defined $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}) { 
        if (defined $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'VEC' }) {
            for (my $i = 0; $i < 9; $i++ ) { 
                if ( $i < $ce_width) { 
                    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT\[$i\]|i}       = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'NAME' } . "[$i]";
                } else { 
                    # Comment out the unused ODT ports defined in the UCF.
                    $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_ODT(\[$i\]"?)|i}        = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'NAME' } . "\$3";
                }                   
            }
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT\[\*\]|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'NAME' } . "[*]";
            # if no vector defined on the mig ucf, then we need to assume the vector is 0:0 and convert non-vectors to [0]
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT"|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'NAME' } . '[0]"';
        }
        else {  # this case the mhs has no vector, therefor we are 1 bit wide, use [0] only, but handle case where no vectors in the ucf either
            # Convert ODT to ODT.  Covers the case where the ucf is not vectorized.
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT"|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'NAME' } . '"';
            # Converts ODT[0] to ODT
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT\[0\]|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'NAME' };
            # Converts ODT[*] to ODT
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT\[\*\]|i}      = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'NAME' };
            # Comment out any other ODT pins.  
            for (my $i = 1; $i < 9; $i++ ) { 
               $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_ODT(\[$i\]"?)|i}        = "#\$1" . $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ODT"}}{ 'NAME' } . "\$3";
           }
        }
    }
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_DQS_N|i}         = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS_N"}}{ 'NAME' } if (defined $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS_N"});
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_reset_n|i}       = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_RESET_N"}}{ 'NAME' } if (defined $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_RESET_N"});
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_DQS(_P)?\b|i}    = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS"}}{ 'NAME' };
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_DQ\b|i}          = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQ"}}{ 'NAME' };
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_a(ddr)?\b|i}     = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_ADDR"}}{ 'NAME' };
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_BA|i}            = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_BANKADDR"}}{ 'NAME' };
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_RAS_N|i}         = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_RAS_N"}}{ 'NAME' };
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CAS_N|i}         = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_CAS_N"}}{ 'NAME' };
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_WE_N|i}          = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_WE_N"}}{ 'NAME' };
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_DM|i}            = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DM"}}{ 'NAME' };
    $conversions{qr|${mig_pin_prefix}_rst_dqs_div_in|}  = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS_DIV_I"}}{ 'NAME' } if defined $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS_DIV_I"} and defined $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS_DIV_I"}}{ 'NAME' };
    $conversions{qr|${mig_pin_prefix}_rst_dqs_div_out|} = $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS_DIV_O"}}{ 'NAME' } if defined $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS_DIV_O"} and defined $mhs_port{ $mpmc{$mpmc_inst}->{ 'PORT' }{ "${mem_type}_DQS_DIV_O"}}{ 'NAME' };
} elsif (defined $batch) { 
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_DQS_N|i}           = "${mem_type}_DQS_n";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_reset_n|i}         = "${mem_type}_Reset_n";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_DQS(_P)?\b|i}      = "${mem_type}_DQS";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_DQ\b|i}            = "${mem_type}_DQ";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_a(ddr)?\b|i}       = "${mem_type}_Addr";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_BA|i}              = "${mem_type}_BankAddr";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_RAS_N|i}           = "${mem_type}_RAS_n";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CAS_N|i}           = "${mem_type}_CAS_n";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_WE_N|i}            = "${mem_type}_WE_n";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_DM|i}              = "${mem_type}_DM";
    $conversions{qr|${mig_pin_prefix}_rst_dqs_div_in|}                  = "${mem_type}_DQS_Div_I";
    $conversions{qr|${mig_pin_prefix}_rst_dqs_div_out|}                 = "${mem_type}_DQS_Div_O";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK(_P)?\[\*\]|i}   = "${mem_type}_Clk[*]";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK_N\[\*\]|i}      = "${mem_type}_Clk_n[*]";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT\[\*\]|i}       = "${mem_type}_ODT[*]";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N\[\*\]|i}      = "${mem_type}_CS_n[*]";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE\[\*\]|i}       = "${mem_type}_CE[*]";
    # These are specific for Virtex-4 DDR1
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N"|i}      = "${mem_type}_CS_n[0]\"";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE"|i}       = "${mem_type}_CE[0]\"";
    $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT"|i}       = "${mem_type}_ODT[0]\"";

    for (my $i = 0; $i < 9; $i++ ) { 
        if ( $i < $clk_width) { 
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK(_P)?\[$i\]|i}       = "${mem_type}_Clk[$i]";
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CK_N\[$i\]|i}     = "${mem_type}_Clk_n[$i]";
        } else { 
            $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CK(_P)?(\[$i\]"?)|i}        = "#\$1${mem_type}_Clk\$4";
            $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CK_N(\[$i\]"?)|i}      = "#\$1${mem_type}_Clk_n\$3";
        }                   
        if ($i < $odt_width) { 
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_ODT\[$i\]|i}       = "${mem_type}_ODT[$i]";
        } else { 
            $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_ODT(\[$i\]"?)|i}       = "#\$1${mem_type}_ODT\$3";
        }
        if ($i < $cs_n_width) { 
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CS_N\[$i\]|i}      = "${mem_type}_CS_n[$i]";
        } else { 
            $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CS_N(\[$i\]"?)|i}      = "#\$1${mem_type}_CS_n\$3";
        }
        if ($i < $ce_width) { 
            $conversions{qr|(${mig_pin_prefix}_)?${mem_type}_CKE\[$i\]|i}       = "${mem_type}_CE[$i]";
        } else { 
            $conversions{qr|^(NET\s*"?)(${mig_pin_prefix}_)?${mem_type}_CKE(\[$i\]"?)|i}       = "#\$1${mem_type}_CE\$3";
        }
    }


}

seek IN,0,0; #Restart the input file for the modification pass

while (<IN>)                   #go through the data file
{
    $linenew = $_;
    chomp($linenew);
    if (m/^\s*[^#][^;]+\s*$/) {  # match if we have a valid line and it is not terminated by semicolon
        $saveline =  $saveline . $linenew;
        $_ = '';
    }
    elsif ($saveline ne '') {
        $_ = $saveline . " " . $_  . "\n";
        $saveline = '';
    }
    else {
        $saveline = '';
    }

    foreach my $key (reverse sort (keys %conversions))
    {
        if (/$key/i)
        {
            my $one = $1;
            my $two = $2;
            my $thr = $3;
            my $mod_value = $conversions{$key};
            $one = "" if not defined $one;
            $two = "" if not defined $two;
            $thr = "" if not defined $thr;
            $mod_value =~ s/\$1/$one/ig;
            $mod_value =~ s/\$2/$two/ig;
            $mod_value =~ s/\$3/$thr/ig;
            s/$key/$mod_value/ig;
        }
    }
    print OUT;
}


close (IN);
close (OUT);
print "\nConversion complete.\n";
if (defined $mhs_file) 
{
    print "  Please check UCF file memory port names to ensure they match MHS file external port names.\n";
}
else 
{
    print "  Please modify UCF file memory port names to match MHS file external port names.\n";
    print "  Please modify UCF file clock names (for example: \"*/mpmc_core_0/Clk0\") to match the synthesis name for the outputs of the clock generator module or the DCM's that generate these clocks.\n";
}
