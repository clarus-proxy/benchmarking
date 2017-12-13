#!/usr/bin/perl -w
#
# ========================================================================
# sar2rrd.pl
# ------------------------------------------------------------------------
#
# This script can be used to parse sar command output.
# It will create RRDTool archives and graphs.
#
# You can use command line arguments to select the graphs
# and the columns you wish.
#
# Common bug: lines of input text must end by '\n' not '\r\n' !
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.6.2
# Date: 05 Sep 2011
#
# Changes:
#	Added a new option on the command line to choose between
#	AVERAGE graphs (the default), MAX or MIN
#	(suggested by Charles Gomes)
#	
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.6.1
# Date: 23 Aug 2011
#
# Changes:
#	Handles SuSE Enterprise 11/RHEL6 format (new kbswpfree data)
#	Changed of CPU data which is now considered to be on a "single block"
#	(thanks to F.Pernet)
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.6
# Date: 01 Aug 2011
#
# Changes:
#	AIX support (thanks to James Moore for his sar output samples)
#	fix around a rrdtool bug that does not allow empty values (new 
#	command line option)
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.5.1
# Date: 15 Jun 2011
#
# Changes:
#	fix a bug when using -C option without _HOST_ macro in rrd & img 
#   	directory names (thanks to Sean Alderman)
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.5
# Date: 10 Jun 2010
#
# Changes:
#   	handle Sar output format of HP-UX 11 : some columns have
#	N/A values (thanks to Paolo Berva)
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.4d
# Date: 01 Jun 2010
#
# Changes:
#	bug fix, upon interruption, the script could leave rrd temporary
#	files that could prohibit a further "rename" of resize.rrd
#	depending of the underlying filesystem
#	when concatenating RRD archives (with the -C option), the temporary
#	resize.rrd file is created in a writeable directory (the one
#	specified with the -r option)
#	also adds the -N option to avoid img and xml files generation
#	(only the rrd files will be generated)
#	(thanks to Roumano)
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.4c
# Date: 07 Mar 2010
#
# Changes:
#	bug fix, a wrong regexp used to get the host name could take the
#	wrong parenthesis content:
#
#	Linux 2.6.27.45rh1 (ss7e55) 	03/07/2010 	_i686_	(8 CPU)
#
#	gives "8 CPU" as the host name !
#	(thanks to Marek Cevenka)
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.4
# Date: 21 Feb 2009
#
# Changes:
#	add a new option on the command line that allows the
#	concatenation of results for the same indicator. Imagine you
#	get one "sar" file per each day, but you want a single graph
#	for multiple days (i.e from multiple "sar" files). This new
#	flag allows this kind of concatenation as long as the data
#	are sampled at the same rate.
#
#	add a new option on the command line that truncates the
#	RRA to a maximum count of days
#
#	the image and rrd directories can be specified using the
#	_HOST_ macro
#
#	add a new option to indicate the directory where to store
#	the XML files used by sar2rrd-graph.pl
#
#	bug fix for Solaris 10, where the year is given with 4 digits
#	(thanks to hans Förtsch)
#
#	bug fix for Solaris 10, where some lines must be skipped, for
#	example, lines containing "unix restarts" (thanks to H.F again)
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.3
# Date: 24 Oct 2008
#
# Changes:
#	bug fix (on Solaris) when keynames for RRD files contain "/"
#	(thanks to Ciro Arierta)
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.2a
# Date: 13 Feb 2008
#
# Changes:
#	bug fix on line 636 and 582: "next" instead of "return"
#
# ------------------------------------------------------------------------
# Author: Jerome Delamarche (jd@maje.biz - jd@trickytools.com)
# Version: 2.2
# Date: 25 Sep 2007
#
# Changes:
#	added a new option ("-c") to ignore error with rrdtool updates
#	option -S (step) can specify an interval smaller than the interval
#		between the 2 first samples (ex: -S 60 when the first
#		interval indicates 61s)
#
# ------------------------------------------------------------------------
# Version: 2.1
# Date: 20 Aug 2007
#
# Changes:
#	Complete rewriting of the parsing loop
#       Handle format of SunOS sar output
#       Handle incomplete lines:
#               timestamp (nothing on the line)
#               timestamp col1 col2 (other columns missing)
#       RRD archive now includes the hostname
# ------------------------------------------------------------------------
#
# On some Solaris, the swpq-sz and %swpocc columns of the runq_sz
# report may be empty. values are no longer reported. This will be fixed
# in the script, but as a workaround you can specify the graph and
# the valid columns using the '-g' option on the command line.
#
# Note: in case of cross-over, there must be at least 3 measures
#	before midnight...
#
# ========================================================================
#
use strict;
use Getopt::Std;
use Time::Local;
use Date::Calc qw(Add_Delta_Days);
use Cwd;
use File::Spec;

# Parameters overridable via the command line:
my $uVerbose 	= 0;
my $uContinueOnErrors = 0;
#my $uDateFormat = "MDY";       # format of the date on the 1st output line
my $uDateFormat = "DMY";       # format of the date on the 1st output line
my $uStartDate 	= "";
my $uEndDate  	= "";
my $uStep	= "";
my $uSarFile 	= "";
my $uConcatenate = 0;
my $uTruncateSpec = 0;
my $uEmpty2Zero = 0;
my $uRRDOnly = 0;
my $uRRDDir	= "./rrd";
my $uXMLDir	= "./xml";
my $uImgDir	= "./img";
my $uImgWidth   = 400;
my $uImgHeight  = 200;
my $uLogarithmic   = "";
my $uGraphNameSpec = "";
my $uGraphColSign  = "";
my @uGraphColSpec  = ();
my $CF = "AVERAGE";		# default Consolidation Function (added from v2.6.2)


# Global parameters:
my $gRRDTool	= "/usr/bin/rrdtool";
my $gOSName 	= "";
my $gHostName	= "";
my $gStartTime 	= "";
my $gStartSec	= "";
my $gStartDay	= "";
my $gStartMonth = "";
my $gStartYear	= "";
my $gEndTime   	= "";
my $gEndSec	= "";
my $gEndDay	= "";
my $gEndMonth 	= "";
my $gEndYear	= "";
my $gDeltaSec	= 0;
my $gCuritem   	= "";
my $gMeasureCount = 0;

# Graph parameters:
my $gLineWidth  = 1;
my @gColors     = ( "FF0000", "0000FF", "00FFFF", "FF00FF", "FFFF00", "00FF00", "000000", "C0C0C0", "FF8C00", "8FBC8F" );
my $gGraphStartSec	= 0;
my $gGraphEndSec	= 0;

# "multiple" graphs are stats like Block Device or CPU Usage that indicate one line per item
#14:46:56          DEV       tps  rd_sec/s  wr_sec/s
#14:47:01       dev1-0      0,00      0,00      0,00
#14:47:01       dev1-1      0,00      0,00      0,00

# Note about the source names:
# '/' must be substituted by a '_'
# '%' must be substituted by 'prct_'
my %gAllSarStats     = (
	# Linux indicators:
	"linux" => {
                        "proc_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Process per Second",
                                        "unit"          => "count/s",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "runq_sz" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Queue Size and Load Average",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "tps" => {
                                        "ignore_col"    => undef,
                                        "title"         => "I/O Transfer Rate",
                                        "unit"          => "count/s",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "pgpgin_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Paging Statistics",
                                        "unit"          => "count/s",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "DEV" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Block Device Activity",
                                        "unit"          => "count/s",
                                        "multiple"      => 1,
                                        "keysize"       => 1,
                        },
                        "INTR" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Interrupt Count",
                                        "unit"          => "count/s",
                                        "multiple"      => 1,
                                        "keysize"       => 1,
                        },
                        "IFACE" => {
                                        "ignore_col"    => undef,
                                        "title"         => {
                                                                "rxpck_s" => "Network Statistics",
                                                                "rxerr_s" => "Network Failure Statistics",
                                                           },
                                        "unit"          => "count/s",
                                        "multiple"      => 1,
                                        "keysize"       => 2,
                        },
                        "totsck" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Socket Statistics",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "kbmemfree" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Memory and Swap Utilization",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "frmpg_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Memory Statistics",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        #"CPU" => {
                        #                "ignore_col"    => undef,
                        #                "title"         => {
                        #                                        "prct_user" => "CPU Utilization",
                        #                                        "i000_s" => "Interruption Statistics",
                        #                                   },
                        #                "unit"          => "count",
                        #                "multiple"      => 1,
                        #                "keysize"       => 2,
                        #},
			# Modified from v2.6.1
                        "CPU" => {
                                        "ignore_col"    => undef,
                                        "title"         => "CPU Utilization",
                                        "unit"          => "count",
                                        "multiple"      => 1,
                                        "keysize"       => 1,
                        },
                        "dentunusd" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Inode and Files Statistics",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "cswch_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Context Switches per Second",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "pswpin_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Swapping Statistics",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
			# call/s added from version 2.1
			"call_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "NFS Client Activity",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
			},
			# scall/s added from version 2.1
			"scall_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "NFS Server Activity",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
			},
			# scall/s added from version 2.1
			"TTY" => {
                                        "ignore_col"    => undef,
                                        "title"         => "TTY Device Activity",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
			},
			# added from version 2.6.1 
			"kbswpfree" => {
					"ignore_col"    => undef,
					"title"         => "Swap Paging Statistics",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},

	},
	
	# SunOS indicators:
	"sunos" => {
                        "runq_sz" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Queue Size and Load Average",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "iget_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Inode Statistics",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "freemem" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Memory Statistics",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "prct_usr" => {
                                        "ignore_col"    => undef,
                                        "title"         => "CPU Load",
                                        "unit"          => "percentage",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "bread_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Buffer Activity",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "swpin_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Swapping Statistics",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "scall_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "System Calls",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "rawch_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "TTY Device Activity",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "proc_sz" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Process and Inodes Status",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "msg_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Message and Semaphore",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "atch_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Paging Activity",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "pgout_s" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Paging Activity",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "sml_mem" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Kernel Memory Allocation",
                                        "unit"          => "count",
                                        "multiple"      => 0,
                                        "keysize"       => 1,
                        },
                        "device" => {
                                        "ignore_col"    => undef,
                                        "title"         => "Device Activity",
                                        "unit"          => "count",
                                        "multiple"      => 1,
                                        "keysize"       => 1,
                        },
	},

	# HP-UX indicators:
	"hp-ux" => {
			"prct_usr" => {
					"ignore_col"    => undef,
					"title"         => "CPU Load",
					"unit"          => "percentage",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"runq_sz" => {
					"ignore_col"    => undef,
					"title"         => "Queue Size and Load Average",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"swpin_s" => {
					"ignore_col"    => undef,
					"title"         => "Swapping Statistics",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"bread_s" => {
					"ignore_col"    => undef,
					"title"         => "Buffer Activity",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"scall_s" => {
					"ignore_col"    => undef,
					"title"         => "NFS Server Activity",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"iget_s" => {
					"ignore_col"    => undef,
					"title"         => "Inode Statistics",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"rawch_s" => {
					"ignore_col"    => undef,
					"title"         => "TTY Device Activity",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"text_sz" => {
					"ignore_col"    => 1,
					"title"         => "Process Table Stat",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"msg_s" => {
					"ignore_col"    => undef,
					"title"         => "Message and Semaphore",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"device" => {
					"ignore_col"    => undef,
					"title"         => "Device Activity",
					"unit"          => "count",
					"multiple"      => 1,
					"keysize"       => 1,
			},
	},

	# AIX indicators:
	"aix" => {
			"prct_usr" => {
					"ignore_col"    => undef,
					"title"         => "CPU Load",
					"unit"          => "percentage",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"bread_s" => {
					"ignore_col"    => undef,
					"title"         => "Buffer Activity",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"scall_s" => {
					"ignore_col"    => undef,
					"title"         => "NFS Server Activity",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"cswch_s" => {
					"ignore_col"    => undef,
					"title"         => "Context Switches per Second",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"rawch_s" => {
					"ignore_col"    => undef,
					"title"         => "TTY Device Activity",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"iget_s" => {
					"ignore_col"    => undef,
					"title"         => "Inode Statistics",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"runq_sz" => {
					"ignore_col"    => undef,
					"title"         => "Queue Size and Load Average",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"proc_sz" => {
					"ignore_col"    => undef,
					"title"         => "Process and Inodes Status",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"msg_s" => {
					"ignore_col"    => undef,
					"title"         => "Message and Semaphore",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"device" => {
					"ignore_col"    => undef,
					"title"         => "Device Activity",
					"unit"          => "count",
					"multiple"      => 1,
					"keysize"       => 1,
			},
			"ksched_s" => {
					"ignore_col"    => undef,
					"title"         => "Number of Kernel Processus",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
			"slots" => {
					"ignore_col"    => undef,
					"title"         => "Number of Free Pages on the Paging Spaces",
					"unit"          => "count",
					"multiple"      => 0,
					"keysize"       => 1,
			},
	},

);
my $gSarStats;

# ---------------------------------------------------------------------
# Command line analysis:
# ---------------------------------------------------------------------
my %opts         = ();
getopts("?cCNzd:i:x:t:f:oH:W:vS:e:s:g:T:m:",\%opts);
if (exists($opts{'?'})) { Usage(); }
if (exists($opts{'c'})) { $uContinueOnErrors = 1; }
if (exists($opts{'C'})) { $uConcatenate = 1; }
if (exists($opts{'N'})) { $uRRDOnly = 1; }
if (exists($opts{'T'})) { $uTruncateSpec = int($opts{'T'}); }
if (exists($opts{'d'})) { $uRRDDir = $opts{'d'}; }
if (exists($opts{'i'})) { $uImgDir = $opts{'i'}; }
if (exists($opts{'x'})) { $uXMLDir = $opts{'x'}; }
if (exists($opts{'f'})) { $uSarFile = $opts{'f'}; }
if (exists($opts{'t'})) { $uDateFormat = $opts{'t'}; }
if (exists($opts{'H'})) { $uImgHeight = $opts{'H'}; }
if (exists($opts{'W'})) { $uImgWidth = $opts{'W'}; }
if (exists($opts{'o'})) { $uLogarithmic = "-o"; }
if (exists($opts{'z'})) { $uEmpty2Zero = 1; }
if (exists($opts{'s'})) { $uStartDate = $opts{'s'}; }
if (exists($opts{'e'})) { $uEndDate = $opts{'e'}; }
if (exists($opts{'S'})) { $uStep = $opts{'S'}; }
if (exists($opts{'v'})) { $uVerbose = 1; }
if (exists($opts{'m'})) { $CF = $opts{'m'}; }

# Parameters check:
# should specify multiple files ? a hostname ? a range ? data to process ?
die("'$gRRDTool' is not an executable") if ! -x $gRRDTool;
if ($uRRDDir !~ /_HOST_/) {
	die("RRD Directory '$uRRDDir' is not a writeable directory") if ! -d $uRRDDir || ! -w $uRRDDir;
}
if (!$uRRDOnly && $uImgDir !~ /_HOST_/) {
	die("Image Directory '$uImgDir' is not a writeable directory") if ! -d $uImgDir || ! -w $uImgDir;
}
if ($uSarFile eq "") {
        print "sar result file not set. Please use -f option\n";
        Usage();
}
die("sar File '$uSarFile' is not a readable") if ! -r $uSarFile;

if ($uTruncateSpec && !$uConcatenate) {
	print "Option -T ignored : needs the -C option\n";
}

if ($CF ne "AVERAGE" && $CF ne "MIN" && $CF ne "MAX" && $CF ne "LAST") {
	print "Option -m needs value AVERAGE, MIN, MAX or LAST\n";
	Usage();
}

# Added with v1.2:
# Try to determine RRDTool version, because the syntax for the legend has changed between the versions:
my $version = `$gRRDTool | grep Copyright`;
my $dummy;
($dummy,$version) = split(/ /,$version);
my @vparts = split(/\./,$version);
my $gSpecialColon = 1;
if ($vparts[0] < 1 || ($vparts[0] == 1 && $vparts[1] < 2)) {
        $gSpecialColon = 0;
}

# ---------------------------------------------------------------------
# First pass is used to get the OS version, the count of
# measures, the interval between measures and the start/end date:
# ---------------------------------------------------------------------
if ($uTruncateSpec) {
	print "Truncating to $uTruncateSpec days\n";
}

# we determine the time range:
print "First Pass: determine the time range...\n";
ParseFile($uSarFile,\&HeaderCallback,\&StartTimeCallback,\&EndTimeCallback);

# Sanity check:
# we must have a start & endtime and curitem should not be empty:
if ($gStartTime eq "") { die("Could not determine the Start Time from the output file\n"); }
if ($gEndTime eq "") { die("Could not determine the End Time from the output file\n"); }
#if ($gCuritem eq "") { die("No Item to graph found in the file\n"); }

# Handling of graph & columns spec:
if (exists($opts{'g'})) { 
        my @graph_spec_parts = split(/:/,$opts{'g'});
        if (scalar(@graph_spec_parts) < 2) {
                print "Incorrect syntax for '-g' option: should be '-g graphname:(+|-)column,...\n";
                Usage();
        }
        if (!exists($gSarStats->{$graph_spec_parts[0]})) {
                die("Value of graph specification does not start by a valid statistics name (".$graph_spec_parts[0].")\n");
        }
        $uGraphColSign = substr($graph_spec_parts[1],0,1);
        if ($uGraphColSign ne "-" && $uGraphColSign ne "+") {
                print "Incorrect syntax for '-g' option: should be '-g graphname:(+|-)column,...\n";
                Usage();
        }

        $uGraphNameSpec = $graph_spec_parts[0];
        @uGraphColSpec = split(/,/,substr($graph_spec_parts[1],1));

        # Note: column names cannot be checked (or we must store predefined values somewhere ?)
}

# Handle start and end date specified on the command line:
my $user_startsec = 0;
my $user_endsec= 0;
if ($uStartDate ne "") {
        $user_startsec = CheckDate($uStartDate,"start");
}
if ($uEndDate ne "") {
        $user_endsec = CheckDate($uEndDate,"end");
}
if ($user_startsec && $user_endsec && $user_endsec < $user_startsec) {
        die("The specified end date: $uEndDate, is anterior to the specified start date: $uStartDate\n");
}

# Adapt the interval (in seconds) between to measures:
if ($uStep) {
        if (0 && $uStep < $gDeltaSec) {
                die("The specified step ('$uStep') is less than the interval between two values ('$gDeltaSec')\n");
        }
	else {
		$gDeltaSec = $uStep;
	}
}

print "Range starts from $gStartTime to $gEndTime\n";
print "Use Interval of $gDeltaSec seconds\n";

# Adjust the graph time interval:
$gGraphStartSec = ($user_startsec) ? $user_startsec : $gStartSec;
$gGraphEndSec   = ($user_endsec) ? $user_endsec : $gEndSec;

# ---------------------------------------------------------------------
# Second pass:
# create the graphs
# ---------------------------------------------------------------------
print "Second Pass: create the graphs...\n";

# Variables for graphs creation:
my $gSarStat	= "";
my $gSkip	= 0;
my $gFirstValue = 1;    # skip the 1st value which is never significant with sar
my $gFirstTime;


my $nextblock   = 0;
my %graphs      = ();
my $dsheartbeat = 0;
my $dsstring    = "";
my $rras        = "";
my $graphname   = "";
my $dsname      = "";
my $keyname     = "";
my $rrdfile     = "";
my $cmd         = "";
my $title       = "";
my $vlabel      = "";
my $dsnames     = "";
my $ismultiple  = 0;
my $startidx;
my $idx;
my $status;

# To memorize the last graph update:
my $prev_rrdfile = "";
my $prev_cursec = 0;

ParseFile($uSarFile,0,0,0,\&GraphHeaderCallback,\&DataCallback);

# Dump the former graph:
if ($gSarStat ne "") {
        CreateImage();
}

# END

sub HeaderCallback
{
	my ($osname,$hostname) = @_;

	print "Analysing 'sar' output for a $osname System: $hostname\n";
	
	$gOSName = $osname;
	$gHostName = $hostname;
	$gSarStats = $gAllSarStats{$osname};
	
	return 0;
}

sub StartTimeCallback
{
	my ($startday,$startmonth,$startyear,$starttime,$startsec,$deltasec) = @_;

	if ($uVerbose) { print "StartTimeCallback: startday=$startday,startmonth=$startmonth,startyear=$startyear,starttime=$starttime,startsec=$startsec,deltasec=$deltasec\n"; }
	$gStartTime 	= $starttime;
	$gStartSec	= $startsec;
	$gStartDay  	= $startday;
	$gStartMonth 	= $startmonth;
	$gStartYear 	= $startyear;
	$gDeltaSec 	= $deltasec;

	return 0;
}

sub EndTimeCallback
{
	my ($endday,$endmonth,$endyear,$endtime,$endsec,$mcount) = @_;

	if ($uVerbose) { print "EndTimeCallback: endday=$endday,endmonth=$endmonth,endyear=$endyear,endtime=$endtime,endsec=$endsec,mcount=$mcount\n"; }
	$gEndDay 	= $endday;
	$gEndMonth	= $endmonth;
	$gEndYear	= $endyear;
	$gEndTime	= $endtime;
	$gEndSec	= $endsec;
	$gMeasureCount 	= $mcount;

	print "$gMeasureCount measures detected\n";
	
	return 1;	# stop parsing for the 1st pass
}

sub GraphHeaderCallback
{
	my ($parts) = @_;
	my $idx;
	my $columns;

	if ($uVerbose) { print @{$parts},"\n"; }

	# Make sure columns have different names:
	# for example, Solaris sar displays:
	# 11:44:20  proc-sz    ov  inod-sz    ov  file-sz    ov   lock-sz
	# here, the 1st ov will be renames proc-sz_ov, the second one inod-sz_ov
	my %colnames = ();
	for ( $idx = 1 ; $idx < scalar(@{$parts}) ; $idx++ ) {
		if (exists $colnames{${$parts}[$idx]}) {
			${$parts}[$idx] = ${$parts}[$idx-1]."_".${$parts}[$idx];
		}
		$colnames{${$parts}[$idx]} = 1;
	}

	# Do we need to create a new graph ?
	$columns = scalar(@{$parts}) - 1;
	my $line = join(' ',@{$parts}[1..$columns]);
	if ($gSarStat ne $line) {
		# Dump the former graph:
		if ($gSarStat ne "") {
			CreateImage();
		}

		# Create a new graph:
		$dsname = MakeDSName(${$parts}[1]);
		if ($uGraphNameSpec ne "") {
			if ($dsname eq $uGraphNameSpec) {
				print "Analyzing data for $dsname\n";
				$gSkip = 0;
			}
			else {
				print "Skip data for $dsname\n";
				$gSarStat = $line;
				$gSkip = 1; 
				return; 
			}
		}
		else {
			print "Analyzing data for $dsname\n";
		}

		# the DS Name depends on the keysize:
		# Sanity check:
		$keyname = "";
		if (!exists($gSarStats->{$dsname})) {
			die("Unknown dsname: $dsname\n");
		}
		if ($gSarStats->{$dsname}{'keysize'} > 1) {
			$keyname = MakeDSName(${$parts}[2]);
			$keyname = "-".$keyname;
		}

		$dsheartbeat = 2 * $gDeltaSec;
		$dsstring = "";
		$dsnames  = "";

		# Is it a single or a multiple graph ?
		$ismultiple = $gSarStats->{$dsname}{'multiple'};
		$startidx = ($ismultiple) ? 2 : 1;

		for ( $idx = $startidx ; $idx < scalar(@{$parts}) ; $idx++ ) {
			my $ds = MakeDSName(${$parts}[$idx]);
			if ($dsstring ne "") { $dsnames .= ":"; }
			$dsstring .= "DS:$ds:GAUGE:$dsheartbeat:0:U ";
			$dsnames .= $ds;
		}

		$rras = "RRA:$CF:0.5:1:$gMeasureCount";

		if (!$ismultiple) {
			#$rrdfile = "$uRRDDir/$gHostName-$dsname$keyname.rrd";
			$rrdfile = GetNoMacroFilename($uRRDDir,$gHostName,"$dsname$keyname.rrd");
			CreateRRA($rrdfile,$dsstring,$rras);
			$gFirstValue = 1;
		}
		else {
			# we cannot create the RRD now, we must analyse the next lines:
			if ($uVerbose) { print "we must analyse more lines before creating the RRD...\n"; }
			$nextblock = 1;
			%graphs = ();
		}
	}

	$gSarStat = $line;

	return 0;
}

sub DataCallback
{
	my ($cursec,$parts) = @_;
	my $idx;

	# Must skip the whole block in case of multiple graph:
        if ($gFirstValue) { $gFirstValue = 0; $gFirstTime = ${$parts}[0]; return; }
	if (${$parts}[0] eq $gFirstTime) { return; }
        if ($gSkip) { return; }

	if ($uVerbose) { print @{$parts},"\n"; }

        # This is a measure line: we must update the graph
        my $DATA = "$cursec:";
        my $startidx = ($ismultiple) ? 2 : 1;
        for ( $idx = $startidx ; $idx < scalar(@{$parts}) ; $idx++ ) {
                ${$parts}[$idx] =~ s/,/\./g;
                if ($idx > $startidx) { $DATA.= ":"; }

		# Added from v2.5 (patch from Paolo Berva)
		# HP-UX displays N/A for text-sz index
		# 14:45:24 text-sz  ov  proc-sz  ov  inod-sz  ov  file-sz  ov
		# 14:50:24   N/A   N/A 340/4096  0  1677/34816 0  5823/63498 0
		if (${$parts}[$idx] =~ /N\/A/) {
			${$parts}[$idx] = "U";
		}

                # Solaris may display values such as X/Y:
                #11:44:20  proc-sz    ov  inod-sz    ov  file-sz    ov   lock-sz
                #11:44:50  218/30000  0 83463/128248 0 3763/3763    0    0/0
                # We eliminate the /Y... (sorry !)
                if (${$parts}[$idx] =~ /\//) {
                        ${$parts}[$idx] =~ s/(.*)\/.*/$1/;
                }

		# Added from v2.6: substiture empty values by zeroes to avoid rrdtool bug ?
		if (${$parts}[$idx] eq '' && $uEmpty2Zero) {
			$DATA .= "0";
		}
		else {
			$DATA .= ${$parts}[$idx];
		}
        }

	# Check if current line is the header for a multiple graph:
	if ($nextblock) {
		# if the column name is not in the @graphs array, add it
		# create a new graph when array is full:
		my $graphname = ${$parts}[1];

		# fixed from v2.3: on Solaris some device names may contain / !
		# (thanks to Ciro Iriarte)
		# 00:00:01   device        %busy   avque   r+w/s  blks/s  avwait  avserv
		#
		# 00:01:01  10/md200          0     0.0       0       0     0.0     0.0
		#           10/md201          0     0.0       0       0     0.0     0.0
		$graphname =~ s/\//_/g;

		if (exists($graphs{$graphname})) {
			$nextblock = 0;
		}
		else {
			$graphs{$graphname} = 1;
			#my $rrdfile = "$uRRDDir/$gHostName-$dsname$keyname-$graphname.rrd";
			my $rrdfile = GetNoMacroFilename($uRRDDir,$gHostName,"$dsname$keyname-$graphname.rrd");
			CreateRRA($rrdfile,$dsstring,$rras);
			#$cmd = "$gRRDTool create $rrdfile -b $gStartSec -s $gDeltaSec $dsstring $rras";
			#MySystem($cmd);
		}
	}

	# It may happen that the RRD file does not exist:
	# in this example, nfs24 suddenly appears ! we ignore it:
	#10:07:09  nfs1              0     0.0       0       0     0.0     0.0
	#          nfs2              0     0.0       0       0     0.0     0.0
	#          nfs5              0     0.0       0       0     0.0     0.3
	#          nfs21             0     0.0       0       0     0.0     0.0 
	#10:07:39  nfs1              0     0.0       0       0     0.0     0.0 
	#	   nfs2              0     0.0       0       0     0.0     0.0 
	#	   nfs5              0     0.0       0       0     0.0     0.0 
	#	   nfs21             0     0.0       0       0     0.0     0.0 
	#	   nfs24             0     0.0       0       0     0.0     0.0
        if ($ismultiple) {
		# TODO : what about if $parts[1] contains some slashes ?
		#$rrdfile = "$uRRDDir/$gHostName-$dsname$keyname-".${$parts}[1].".rrd";
		$rrdfile = GetNoMacroFilename($uRRDDir,$gHostName,"$dsname$keyname-".${$parts}[1].".rrd");
		if (! -f $rrdfile) { return 0; }
        }

	# Fixed from v2.3: on Solaris, for the same period, they may be
	# multiple lines for the same keys !
	#   ssd109.t          0     0.0    1377   86815     0.0     0.0
	#   ssd109.t          0     0.0       0       0     0.0     0.0
	if ($rrdfile eq $prev_rrdfile && $prev_cursec == $cursec) { return 0; }
	$prev_rrdfile = $rrdfile;
	$prev_cursec = $cursec;

	my $cmd = "$gRRDTool update $rrdfile -t $dsnames $DATA";
	MySystem($cmd);

	return 0;
}

#
# File Parsing Encapsulation:
#
sub ParseFile
{
	my ($fname,$hdrcback,$starttimecback,$endtimecback,$graphhdrcback,$datacback) = @_;
	my ($ST_INIT, $ST_INBLOCK, $ST_NOBLOCK) = (1..10);
	my $curstate = $ST_INIT;
	my $hostname;
	my $uname;
	my $headerline = 0;
	my $curheader = "";
	my $inblock = 0;
	my $curdate;
	my ($startmonth,$startday,$startyear);
	my ($endmonth,$endday,$endyear);
	my $starttime = "";
	my $endtime = "";
	my $secondtime = "";
	my $endtime_sent = 0;
	my @parts;
	my $lasttime;
	my $line;
	my $columns;		# count of columns in the current block
	my $measurecount = 0;
	my $first_over = 1;
	my $days_over_insec = 0;

	open(FD,"<$fname") or die("Could not open file '$fname' in read mode\n");
	while (<FD>) {
		# Added from version 2.0c:
		# eliminate DOS EOL markers
		$_ =~ s/\r\n/\n/;
		chomp;

		# always ignore empty lines, they cannot be considered as block delimitors:
		if ($_ eq "") { next; }
		if ($_ =~ /^[[:space:]]*$/) { next; } # added fom v2.6 for AIX

		if ($uVerbose) { print "($curstate)line:$_\n"; }

		# Eliminate LINUX events:
		# 08:28:54          LINUX RESTART
		# Mmh... not clear. Should stop the analysis because the images may be empty
		if ($_ =~ /LINUX/) { next; }

		# Added from v2.4 for SunOS 10 (thanks to Hans Förtsch):
		# Eliminate unix events:
		# 08:28:54	    unix restarts
		if ($_ =~ /unix/) { next; }

		# From v2.6 and AIX support:
		# Eliminate "System configuration.." lines
		if ($_ =~ /^System configuration/) { next; }

		if ($curstate == $ST_INIT) {
			# Handle the header:

			# The first line should indicate the day:
			# possible formats are: 
			# for Linux:
			#       Linux version (hostname) DD.MM.YYYY
			#   or: Linux version (hostname) DD/MM/YYYY
			#   or: Linux version (hostname) YYYY-MM-DD
			#   (new formats added from version 2.0b)
			#   (thanks to cverhoef@planet.nl)
			#
			# for SunOS (starting in v1.3):
			#       SunOS hostname version release arch MM/DD/YY
			$curdate = $_;
			$hostname = $_;

			if ($curdate =~ /^Linux/i) {
				$curdate =~ s/^.*\(.*\)[^[:digit:]]*([[:digit:]]{2,4}[\.\/-][[:digit:]]{2}[\.\/-][[:digit:]]{2,4}).*$/$1/;
				# Changed from v2.4c (thanks to Marek Cervenka)
				#$hostname =~ s/^.*\((.*)\).*$/$1/;
				$hostname =~ s/^.*?\((.*?)\).*$/$1/;
				$uname = "linux";
			}
			elsif ($curdate =~ /^SunOS/i) {
				# Fixed from v2.4 (thanks to Hans Förtsch): on SunOS the year can be on 4 digits
				#$curdate =~ s/.*([[:digit:]]{2}[\.\/][[:digit:]]{2}[\.\/][[:digit:]]{2}).*$/$1/;
				$curdate =~ s/.*([[:digit:]]{2}[\.\/][[:digit:]]{2}[\.\/][[:digit:]]{2,4}).*$/$1/;
				@parts = split(/ /,$hostname);
				$hostname = $parts[1];
				$uname = "sunos";
			}
			elsif ($curdate =~ /^HP-UX/i) {
				# Added from v2.5 (thanks to Paolo Berva)
				$curdate =~ s/.*([[:digit:]]{2}[\.\/][[:digit:]]{2}[\.\/][[:digit:]]{2,4}).*$/$1/;
				@parts = split(/\s+/,$hostname);
				$hostname = $parts[1];
				$uname = "hp-ux";
			}
			# Added from v2.6 (thnaks to Rick Willmore)
			elsif ($curdate =~ /^AIX/i) {
				$curdate =~ s/.*([[:digit:]]{2}[\.\/][[:digit:]]{2}[\.\/][[:digit:]]{2,4}).*$/$1/;
				@parts = split(/\s+/,$hostname);
				$hostname = $parts[1];
				$uname = "aix";
			}
			else {
				die("Unknown Operating System inside '$curdate'\n");
			}

			if ($uDateFormat eq "MDY") {
				($startmonth,$startday,$startyear) = split(/[\.\/-]/,$curdate);
			}
			elsif ($uDateFormat eq "DMY") {
				($startday,$startmonth,$startyear) = split(/[\.\/-]/,$curdate);
			}
			# New formats added from version 2.0b
			elsif ($uDateFormat eq "YDM") {
				($startyear,$startday,$startmonth) = split(/[\.\/-]/,$curdate);
			}
			elsif ($uDateFormat eq "YMD") {
				($startyear,$startmonth,$startday) = split(/[\.\/-]/,$curdate);
			}
			else {
				die("Unknown Date Format: '$uDateFormat' (supported format are: MDY, DMY, YDM and YMD)\n");
			}
			($endday,$endmonth,$endyear) = ($startday,$startmonth,$startyear);
			$startmonth--;

			if ($hdrcback) { if ($hdrcback->($uname,$hostname)) { last; } }

			$curstate = $ST_NOBLOCK;
			next;
		}

		# Starting from here, we know the header has been analysed:

		# Multiple spaces are considered as a simple char:
		$_ =~ s/([[:space:]]+)/ /g;
		#print $_,"\n";
		@parts = split(/[[:space:]]/);

		if ($curstate == $ST_NOBLOCK) {
			# We expect a block header:
		BLOCKHDR:

			# Lines must start with a time specification:
			#Average   nfs1              0     0.0       0       0     0.0     0.0
			if ($parts[0] !~ /[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]/) { next; }

			$curstate = $ST_INBLOCK;
			StripAMPM(\@parts);

			# Always memorize the last time:
			# since version 2.0c, this assignment is made AFTER StripAMPM() call !
			$lasttime = $parts[0];

			# Indicate a new graph may start here:
			$curheader = $parts[1];
			$columns = scalar(@parts);
			if ($graphhdrcback) { if ($graphhdrcback->(\@parts)) { last; } }

			next;   # the starttime starts AFTER the header line
		}

		if ($curstate == $ST_INBLOCK) {
			StripAMPM(\@parts);

			# Ignore repeated headers such as :
			#11:30:01 PM    proc/s 
			#11:40:01 PM     5.04
			#11:50:01 PM     5.04
			#
			#03:50:01 AM    proc/s
			#04:10:01 AM     18.05
			#04:20:01 AM     17.18
			if ($parts[1] eq $curheader) {
				next;
			}

			# Sometimes the time may be missing (Solaris...):
			#09:55:39  device        %busy   avque   r+w/s  blks/s  avwait  avserv
			#
			#09:56:09  nfs1              0     0.0       0       0     0.0     0.0
			#          nfs2              0     0.0       0       0     0.0     0.0
			#          nfs5              0     0.0       0       2     0.0     3.7
			if ($parts[0] =~ /^[[:space:]]/ || !length($parts[0])) {
				# put the last time back:
				$parts[0] = $lasttime;
				#unshift(@parts,$lasttime);
			}

			# Determine the end of block: empty lines are enough on Linux,
			# not on solaris: 
			# on Solaris, empty lines may not delimit blocks:
			# blocks end with a line such as "^Average....", depending on the locale.
			# Sometimes the new block starts with a new header line...
			#
			#09:55:39  proc-sz    ov  inod-sz    ov  file-sz    ov   lock-sz
			#09:56:09  132/30000    0 91719/128248    0 1895/1895    0    0/0
			#16:35:39  127/30000    0 60543/128248    0 1881/1881    0    0/0
			#
			#09:55:39   msg/s  sema/s
			#09:56:09    0.00    0.10
			#09:56:39    0.00    0.00

			# we consider the end block when 
			# the line starts with a non-digit and non-space char
			# or when the first column changed and is not a number and not a DS Name !

			my $isdsname = MakeDSName($parts[1]);

			if ($parts[0] !~ /^[[:digit:][:space:]]/ ||
			    ($parts[1] !~ /^[0-9]/ && exists($gSarStats->{$isdsname}))) { 
				if ($uVerbose) { print "End of block\n"; }
				# Note: all block is supposed to end with an "Average" line
				if (!$endtime_sent) {
					#print $parts[0]," ",$parts[1]," ",$lasttime,"\n"; die;
					$endtime_sent = 1;
					$endmonth--;
					my $endsec = timelocal(reverse(split(/:/,$endtime)),$endday,$endmonth,$endyear);
					if ($endtimecback) {
						if ($endtimecback->($endday,$endmonth,$endyear,$endtime,$endsec,$measurecount)) { last; }
					}
					$endmonth++;
				}
				$curstate = $ST_NOBLOCK;
				$days_over_insec = 0;
				$starttime = $secondtime = $endtime = $curheader = "";
				$first_over = 1;

				if ($parts[1] !~ /^[0-9]/ && exists($gSarStats->{$isdsname})) {
					goto BLOCKHDR;
				}
				next;
			}

			# Always memorize the last time:
			$lasttime = $parts[0];

			# Skip or add missing parameters to incomplete lines (see Solaris:
			#11:44:20 runq-sz %runocc swpq-sz %swpocc
			#11:44:50     2.5       7
			#11:45:20
			if (scalar(@parts) < 2) { next; }

			my $idx = scalar(@parts);
			for ( ; $idx < $columns ; $idx++ ) {
				$parts[$idx] = "";
			}

			# Is it the first row of real value ?
			# we must memorize the starting date:
			if ($starttime eq "") { $starttime = $parts[0]; }

			# If it is the second row of value, we get the date 
			# to compute the interval between two measures:
			elsif ($secondtime eq "" && $starttime ne $parts[0]) { 
				# Note: we suppose the first and second lines belong to the same day !
				$secondtime = $parts[0]; 
				my $startsec = timelocal(reverse(split(/:/,$starttime)),$startday,$startmonth,$startyear);
				my $secondsec = timelocal(reverse(split(/:/,$secondtime)),$startday,$startmonth,$startyear);
				my $deltasec = $secondsec - $startsec;
				if ($starttimecback) { 
					if ($starttimecback->($startday,$startmonth,$startyear,$starttime,$startsec,$deltasec)) { last; }
				}
			}

			# We also need to compute the measure count:
			# Ignore lines which have identical timestamp (think of multiple CPU !)
			if ($endtime eq "" || $endtime ne $parts[0]) {
				$measurecount++;
			}

			# cross over midnight ?
			if ($starttime gt $parts[0]) {
				if ($first_over) {
					$endmonth--;
					if ($hdrcback) { print "cross over midnight($endyear,$endmonth,$endday)\n"; }
					$endmonth++;
					eval {
						($endyear,$endmonth,$endday) = Add_Delta_Days($endyear,$endmonth,$endday,1);
						$days_over_insec += 86400;
					};
					if ($@) {
						die("Incorrect Date Format on the 1st line\nUse the -t option\n");
					}
					$first_over = 0;
				}
			}
			else {
				$first_over = 1;
			}

			$endtime = $parts[0];

			# This is a measure line:
			if ($datacback) { 
				my $cursec = timelocal(reverse(split(/:/,$parts[0])),$gStartDay,$gStartMonth,$gStartYear);
				$cursec += $days_over_insec;

				if ($datacback->($cursec,\@parts)) { last; } 
			}
			next;
		}

	}
	close(FD);
}

sub CheckDate
{
        my ($date,$label) = @_;
        my @date;
        my $sec;
        my $month;

        @date = split(/[ :-]/,$date);
        $sec = timelocal($date[5],$date[4],$date[3],$date[1],$date[0]-1,$date[2]);
        #print "sec=$sec, startsec=$startsec, endsec=$endsec\n";
        if ($sec < $gStartSec) {
                $month = $gStartMonth+1;
                die("The $label date specified on the command line: $date, is anterior to the first date read in the file: $month-$gStartDay-$gStartYear $gStartTime\n");
        }
        if ($sec > $gEndSec) {
                $month = $gEndMonth+1;
                die("The $label date specified on the command line: $date, is posterior to the last date read in the file: $month-$gEndDay-$gEndYear $gEndTime\n");
        }

        return $sec;
}

sub MakeDSName
{
        my ($name) = @_;

        $name =~ s/%/prct_/g;
        $name =~ s/[^[:alnum:]]/_/g;

        return $name;
}

sub Time24
{
        my ($parts) = @_;

        # Add 12 hours, but 12PM is 12 and 12AM is 00:
        #print "p0=",${$parts}[0],"--";
        my @thetime = split(/:/,${$parts}[0]);

        if (${$parts}[1] eq "AM") {
                if ($thetime[0] eq "12") {
                        ${$parts}[0] = "00:".$thetime[1].":".$thetime[2];
                }
        }
        else {
                if ($thetime[0] ne "12") {
                        ${$parts}[0] = $thetime[0]+12;
                        ${$parts}[0] .= ":".$thetime[1].":".$thetime[2];
                }
        }

        if ($uVerbose) { print "Time24: new time is: ",${$parts}[0],"\n"; }
}

sub StripAMPM
{
	my ($p) = @_;

	# Eliminate the 2nd column if it is a AM or a PM:
	#12:00:01 AM    proc/s
	#12:10:01 AM     17.15
	if ($p->[1] eq "AM" || $p->[1] eq "PM") {
		Time24($p);

		# Eliminate the column:
		my $part0 = $p->[0];
		shift(@{$p});
		shift(@{$p});
		unshift(@{$p},$part0);
	}
}

sub CreateRRA
{
	my ($rrdfile,$dsstring,$rras) = @_;
	if ($uConcatenate) {
		# Check if RRD already exists:
		if (-e $rrdfile) {
			# Get the first update of the current RRD:
			$cmd = "$gRRDTool first $rrdfile";
			my ($firstsec) = `$cmd`;
			chomp $firstsec;
			if ($firstsec < 0) {
				die("'$gRRDTool first $rrdfile' failed");
			}

			# Get the last update of the current RRD:
			$cmd = "$gRRDTool last $rrdfile";
			my ($lastsec) = `$cmd`;
			chomp $lastsec;
			if ($lastsec < 0) {
				die("'$gRRDTool last $rrdfile' failed");
			}

			# Check the new start if greater then the "last" data:
			if ($lastsec >= $gStartSec) {
				die("The last date in the current RRD file is newer than the start date ($lastsec/$gStartSec)");
			}

			# Compute the count of new rows : there is an adjustment
			# to make if the previous and the new one are separated by
			# more than one interval:
			my $morerows = $gMeasureCount + int(($gStartSec - $lastsec) / $gDeltaSec + .5);
			#print $gStartSec - $lastsec;
			#die("rrdtool last: $lastsec startSec: $gStartSec, rras: $rras, measurecount=$gMeasureCount, morerows=$morerows");

			# Change the real StartSec for the graph:
			$gGraphStartSec = $firstsec;

			# From v2.4d, create resize.rrd in a writeable directory
			ResizeRRDFile("0 GROW $morerows",$rrdfile);

			# Truncate if necessary:
			if ($uTruncateSpec) {
				# Get the last update of the current RRD:
				$cmd = "$gRRDTool last $rrdfile";
				$lastsec = `$cmd`;
				chomp $lastsec;
				if ($lastsec < 0) {
					die("'$gRRDTool last $rrdfile' failed");
				}

				# Compute the count of maximum rows:
				my $rowcount = ($lastsec - $firstsec) / $gDeltaSec;	 # actual rows
				$rowcount = int($rowcount + 0.5);
				my $maxrows = ($uTruncateSpec * 24 * 3600) / $gDeltaSec; # max rows
				$maxrows = int($maxrows + 0.5);
				#print "firstsec=$firstsec, lastsec=$lastsec, rowcount=$rowcount, maxrows=$maxrows\n";

				my $removerows;
				if ($maxrows < $rowcount) {
					$removerows = $rowcount - $maxrows;

					# From v2.4d, create resize.rrd in a writeable directory
					ResizeRRDFile("0 SHRINK $removerows",$rrdfile);

					# Shift the start time for the graph:
					$gGraphStartSec = $firstsec + $gDeltaSec * $removerows;
				}
				else {
					print "Archive '$rrdfile' too small to be truncated\n";
				}
			}

			return;
		}
	}

	$cmd = "$gRRDTool create $rrdfile -b $gStartSec -s $gDeltaSec $dsstring $rras";
	MySystem($cmd);
}

sub CreateImage 
{
	my $title;
	my $vlabel;

        if ($gSkip) { return; }

        $title = $gSarStats->{$dsname}{'title'};
        $vlabel = $gSarStats->{$dsname}{'unit'};

        # $dsnames is col1:col2:....
        # we must apply $uGraphColSign and $uGraphColSpec here:

        my @ds = split(/:/,$dsnames);
        my $defs = "";
        my $color;
        my $imgfile;
        COL: for ( my $idx = 0 ; $idx < scalar(@ds) ; $idx++ ) {
                if ($uGraphNameSpec ne "") {
                        my $colname = $ds[$idx];
                        if ($uGraphColSign eq "+") {
                                my $found = 0;
				# Added from v2.2a : empty graph spec means "everything"
				if (!scalar(@uGraphColSpec)) { 
					$found = 1; 
				}
				else {
					# the column must be listed
					foreach my $col (@uGraphColSpec) {
						if ($col eq $colname) {
							$found = 1;
							last;
						}
					}
                                }
                                if (!$found) { next COL; }
                        }
                        else {
                                # the column must not be listed
                                foreach my $col (@uGraphColSpec) {
                                        if ($col eq $colname) {
                                                next COL;
                                        }
                                }
                        }
                }

                $color = $gColors[$idx % scalar(@gColors)];
                if ($ismultiple) {
                        $defs .= "DEF:v$idx=RRDFILE:".$ds[$idx].":$CF LINE$gLineWidth:v$idx#$color:".$ds[$idx]." ";
                }
                else {
                        $defs .= "DEF:v$idx=$rrdfile:".$ds[$idx].":$CF LINE$gLineWidth:v$idx#$color:".$ds[$idx]." ";
                }
        }

        if ($defs eq "") {
                die("No column selected to display the graph\n");
        }

        my $startdate = localtime($gGraphStartSec);
        my $enddate  = localtime($gGraphEndSec);
        if ($gSpecialColon) {
                $startdate =~ s/:/\\:/g;
                $enddate =~ s/:/\\:/g;
        }
        #print $startdate,"\n";
        #print $enddate,"\n";
        my $legend = '"COMMENT:From '.$startdate.', To '.$enddate.'\\c" "COMMENT:\\n"';

        if ($ismultiple) {
                foreach $graphname (keys %graphs) {
						if (!$uRRDOnly) {
							#$imgfile = "$uImgDir/$gHostName-$dsname$keyname-$graphname.png";
							$imgfile = GetNoMacroFilename($uImgDir,$gHostName,"$dsname$keyname-$graphname.png");

							# set the good RRD file name:
							my $defs2 = $defs;
							#$defs2 =~ s!RRDFILE!$uRRDDir/$gHostName-$dsname$keyname-$graphname.rrd!g;
							my $realfname = GetNoMacroFilename($uRRDDir,$gHostName,"$dsname$keyname-$graphname.rrd");
							$defs2 =~ s!RRDFILE!$realfname!g;

							if ($keyname ne "") {
									my $keyname2 = substr($keyname,1); # suppress the leading '-'
									$title = $gSarStats->{$dsname}{'title'}{$keyname2}." for $graphname";
									#print "graphname:$graphname, keyname2:$keyname2, dsname:$dsname\n";
							}
							else {
									$title = $gSarStats->{$dsname}{'title'}." $graphname";
							}

							$cmd = "$gRRDTool graph $imgfile -t '$title' -s $gGraphStartSec -e $gGraphEndSec $uLogarithmic -S $gDeltaSec -v '$vlabel' -w $uImgWidth -h $uImgHeight -a PNG $legend $defs2 >/dev/null";
							MySystem($cmd);
							WriteGraphXML($uXMLDir,$gHostName,$rrdfile,$title,$vlabel,$defs,$imgfile,$gDeltaSec,$uImgWidth,$uImgHeight,$uLogarithmic);
						}
                }
        }
        else {
				if (!$uRRDOnly) {
					#$imgfile = "$uImgDir/$gHostName-$dsname$keyname.png";
					$imgfile = GetNoMacroFilename($uImgDir,$gHostName,"$dsname$keyname.png");

					$cmd = "$gRRDTool graph $imgfile -t '$title' -s $gGraphStartSec -e $gGraphEndSec $uLogarithmic -S $gDeltaSec -v '$vlabel' -w $uImgWidth -h $uImgHeight -a PNG $legend $defs >/dev/null";
					MySystem($cmd);
					WriteGraphXML($uXMLDir,$gHostName,$rrdfile,$title,$vlabel,$defs,$imgfile,$gDeltaSec,$uImgWidth,$uImgHeight,$uLogarithmic);
				}
        }
}
 
 # Added from v2.4:
sub GetNoMacroFilename
{
	my ($dstdir,$hostname,$fname) = @_;
	my $realdstdir;
	my $realfname;

	# Handle the _HOST_ macro:
	$realdstdir = $dstdir;
	if ($dstdir =~ /_HOST_/) {
		$realdstdir =~ s/_HOST_/$hostname/g;
		$realfname = "$realdstdir/$fname";
	}
	else {
		# From v2.5.1: if $fname is empty, we're interested on the directory only
		# we must not concatenate anything with the final dir ! (Sean Alderman)
		if ($fname ne "") {
			$realfname = "$realdstdir/$hostname-$fname";
		}
		else {
			$realfname = $realdstdir;
		}
	}
	if (! -d $realdstdir) {
		mkdir($realdstdir) or die("Could not create '$realdstdir' directory");
	}

	return $realfname;
}

sub MySystem
{
	my ($cmd) = @_;
	my $status;

	if ($uVerbose) { print $cmd,"\n"; }
	if ($status = system($cmd)) {
		if (!$uContinueOnErrors) {
			die("Command '$cmd' failed with return code: $status\n");
		}
	}
}

# This function has been added from v2.4
# The purpose is to store in a XML file the graph characteristics to make possible
# a further graph regenration with rebuilding the RRD file. This XML file can be
# used with the additional sar2rrd-graph.pl script.
sub WriteGraphXML
{
	my ($xmldir,$hostname,$rfile,$title,$vlabel,$defs,$ifile,$delta,$w,$h,$logmic) = @_;

	if ($uRRDOnly) { return; }

	my $fname = $rfile;
	$fname =~ s/\.rrd$/\.xml/;
	my @parts = split(/\//,$fname);
	$fname = GetNoMacroFilename($xmldir,$hostname,$parts[-1]);

	open(XML,">$fname") or die("Could not open file '$fname' in write mode");
	print XML "<sar2rrd>\n";
	print XML "\t<title>$title</title>\n";
	print XML "\t<vlabel>$vlabel</vlabel>\n";
	print XML "\t<rrdfile>$rfile</rrdfile>\n";
	print XML "\t<imgfile>$ifile</imgfile>\n";
	print XML "\t<deltasec>$delta</deltasec>\n";
	print XML "\t<width>$w</width>\n";
	print XML "\t<height>$h</height>\n";
	print XML "\t<logarithmic>$logmic</logarithmic>\n";
	print XML "\t<defs>$defs</defs>\n";
	print XML "</sar2rrd>\n";
	close(XML);
}

# Added for v2.4d
# Rename "resize.rrd" file into $rrdfile
sub ResizeRRDFile
{
	my ($cmdargs,$rrdfile) = @_;

	if ($uVerbose) { print "ResizeRRDFile($rrdfile)\n"; }

	# From v2.4d, create resize.rrd in a writeable directory
	my $absfile = File::Spec->rel2abs($rrdfile);

	my $curdir = Cwd::getcwd();
	my $newdir = GetNoMacroFilename($uRRDDir,$gHostName,"");
	# From v2.5.1: if uRRDir does not contain _HOST_ macro,
	# there is no specific destination directory
	if (!chdir($newdir)) {
		die("Could not change current directory to '$newdir'");
	}

	$cmd = "$gRRDTool resize $absfile $cmdargs";
	MySystem($cmd);

	# Delete the current file if it exists:
	if (-e $rrdfile) {
		if (!unlink($rrdfile)) {
			die("Could not delete '$rrdfile'");
		}
	}

	# Rename 'resize.rrd' into $rrdfile:
	if (!rename("resize.rrd",$absfile)) {
		die("Could not rename 'resize.rrd' into '$absfile'");
	}

	# Restore the initial directory:
	if (!chdir($curdir)) {
		die("Could not change current directory to '$curdir'");
	}
}

sub Usage
{
	print "Usage: $0\t[-?ovcCNz] [-d rrd_dir] [-i img_dir] [-x xml_dir] [-W width] [-H height]\n";
	print "\t\t\t[-s start_date] [-e end_date] [-S step] [-m cf_function]\n";
	print "\t\t\t[-g graph_spec] [-t DMY|MDY|YDM|YMD] [-T days] -f sar_file\n";
	print "Options:\n";
	print "\t-? : this help\n";
	print "\t-v : verbose mode\n";
	print "\t-c : continue on error\n";
	print "\t-C : (concatenate) add sar file content in the current RRD archive\n";
	print "\t-N : (no file) generates RRD files only (no img and no xml files)\n";
	print "\t-o : use a logarithmic scale for Y scale\n";
	print "\t-z : substitute empty values by zeroes to avoid rrdtool update bug (on AIX)\n";
	print "\t-d rrd_dir : directory where RRD files must be created\n";
	print "\t-i img_dir : directory where to place PNG images\n";
	print "\t-x xml_dir : directory where to place XML files (used by sar2rrd-graph.pl)\n";
	print "\t\tnote that these values can contain the _HOST_ macro\n";
	print "\t\tto create directories which depend on the hostname\n";
	print "\t-W width : images width (in pixels)\n";
	print "\t-H height : images height (in pixels)\n";
	print "\t-m cf_function: rrdtool consolidation function, MIN, MAX, LAST or AVERAGE (default)\n";
	print "\t-s start_date : start date (MM-DD-YYYY HH:MM:SS)\n";
	print "\t-e end_date : end date (MM-DD-YYYY HH:MM:SS)\n";
	print "\t-S step : interval (in seconds) between to values in the graph\n";
	print "\t-g graph_spec: by default all possible graphs are created\n";
	print "\t\tgraph_spec syntax is: data:(+|-)[column[,column...]]\n";
	print "\t\tthis creates only the graph and the specified columns\n";
	print "\t\tnote that graph and column name must contain '_' instead of '-'\n";
	print "\t-t MDY|DMY|YDM|YMD: indicates the format for the date displayed on the 1st output line\n";
	print "\t-T days : (truncate) maximum count of days stored in the RRA (only valid with the -C option)\n";
	print "\t-f sar_file : file to analyse - created by the 'sar -f ...' command\n";

	exit(1);
}

exit(0);

# EOF
