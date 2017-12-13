#!/usr/bin/perl -w
#
# ========================================================================
# sar2rrd-graph.pl
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
# ========================================================================
#
use strict;
use Getopt::Std;
use Time::Local;
use Date::Calc qw(Add_Delta_Days);
use XML::Simple;

# Global parameters:
my $gRRDTool	= "/usr/bin/rrdtool";

# Parameters overridable via the command line:
my $uVerbose 	= 0;
my $uContinueOnErrors = 0;
my $uStartDate 	= "";
my $uEndDate  	= "";
my $uPeriod	= "";
my $uStep	= "";
my $uXMLSpec	= "";
my $uImgHeight  = 0;
my $uImgWidth   = 0;
my $uLogarithmic = "";

# Graph parameters:
my $gGraphStartSec	= 0;
my $gGraphEndSec	= 0;
my $gTitle = "";
my $gVlabel = "";
my $gRRDName = "";
my $gImgName = "";
my $gDefs = "";

# ---------------------------------------------------------------------
# Command line analysis:
# ---------------------------------------------------------------------
my %opts         = ();
getopts("?coH:W:vS:e:s:x:p:",\%opts);
if (exists($opts{'?'})) { Usage(); }
if (exists($opts{'c'})) { $uContinueOnErrors = 1; }
if (exists($opts{'H'})) { $uImgHeight = $opts{'H'}; }
if (exists($opts{'W'})) { $uImgWidth = $opts{'W'}; }
if (exists($opts{'o'})) { $uLogarithmic = "-o"; }
if (exists($opts{'s'})) { $uStartDate = $opts{'s'}; }
if (exists($opts{'e'})) { $uEndDate = $opts{'e'}; }
if (exists($opts{'S'})) { $uStep = $opts{'S'}; }
if (exists($opts{'x'})) { $uXMLSpec = $opts{'x'}; }
if (exists($opts{'p'})) { $uPeriod = $opts{'p'}; }
if (exists($opts{'v'})) { $uVerbose = 1; }

# Parameters check:
# should specify multiple files ? a hostname ? a range ? data to process ?
die("'$gRRDTool' is not an executable") if ! -x $gRRDTool;
die("The XML Graph Specification is missing (option -x)") if $uXMLSpec eq "";
die("The XML Graph Specification '$uXMLSpec' is not readable") if ! -r $uXMLSpec;

if ($uPeriod ne "" && ($uStartDate ne "" || $uEndDate ne "")) {
	die("The '-p' option is exclusive with the '-s' and '-e' options");
}
if ($uPeriod ne "") {
	if ($uPeriod ne "lastday" && $uPeriod ne "lastweek" && 
	    $uPeriod ne "lastmonth" && $uPeriod ne "lastyear") {
		die("The value for parameter '-p' is invalid - must be lastday, lastweek, lastmonth or lastyear");
	}
}

# Read XML Spec content:
my $xmlcontent = XMLin($uXMLSpec);
if ($uImgHeight == 0) { $uImgHeight = $xmlcontent->{height}; }
if ($uImgWidth == 0) { $uImgWidth = $xmlcontent->{width}; }
if ($uLogarithmic eq "") { 
	$uLogarithmic = $xmlcontent->{logarithmic}; 
	if (ref($uLogarithmic) eq "HASH") { $uLogarithmic = ""; }
}
$gVlabel = $xmlcontent->{vlabel};
$gTitle = $xmlcontent->{title};
$gRRDName = $xmlcontent->{rrdfile};
if ($uStep eq "") { $uStep = $xmlcontent->{deltasec}; }
$gImgName = $xmlcontent->{imgfile};
$gDefs = $xmlcontent->{defs};

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

# Compute the start and end date:
my $startdate;
my $enddate;
my $legend;
my $cmd;
if ($uPeriod ne "") {
	$cmd = "$gRRDTool last $gRRDName";
	$uEndDate = `$cmd`;
	chomp $uEndDate;
	if ($uEndDate < 0) {
		die("'$gRRDTool last $gRRDName' failed");
	}

	if ($uPeriod eq "lastday") {
		$uStartDate = $uEndDate - 3600 * 24;
		$legend = 'Last Day';
	}
	elsif ($uPeriod eq "lastweek") {
		$uStartDate = $uEndDate - 3600 * 24 * 7;
		$legend = 'Last Week';
	}
	elsif ($uPeriod eq "lastmonth") {
		$uStartDate = $uEndDate - 3600 * 24 *  30;
		$legend = 'Last Month';
	}
	elsif ($uPeriod eq "lastyear") {
		$uStartDate = $uEndDate - 3600 * 24 * 365;
		$legend = 'Last Year';
	}
	$legend = '"COMMENT:'.$legend.'\\c" "COMMENT:\\n"';
}
else {
	if ($uStartDate eq "") {
		my $cmd = "$gRRDTool first $gRRDName";
		$uStartDate = `$cmd`;
		chomp $uStartDate;
		if ($uStartDate < 0) {
			die("'$gRRDTool first $gRRDName' failed");
		}
	}

	if ($uEndDate eq "") {
		$cmd = "$gRRDTool last $gRRDName";
		$uEndDate = `$cmd`;
		chomp $uEndDate;
		if ($uEndDate < 0) {
			die("'$gRRDTool last $gRRDName' failed");
		}
	}

	$startdate = localtime($uStartDate);
	$enddate  = localtime($uEndDate);

	if ($gSpecialColon) {
		$startdate =~ s/:/\\:/g;
		$enddate =~ s/:/\\:/g;
	}
	$legend = '"COMMENT:From '.$startdate.', To '.$enddate.'\\c" "COMMENT:\\n"';
}

$cmd = "$gRRDTool graph $gImgName -t '$gTitle' -s $uStartDate -e $uEndDate $uLogarithmic -S $uStep -v '$gVlabel' -w $uImgWidth -h $uImgHeight -a PNG $legend $gDefs >/dev/null";
MySystem($cmd);
 
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

sub Usage
{
	print "Usage: $0\t[-?ovc] [-W width] [-H height]\n";
	print "\t\t\t[-s start_date] [-e end_date] [-S step]\n";
	print "\t\t\t[-p lastday|lastweek|lastmonth|lastyear] -x XMLSpec\n";
	print "Options:\n";
	print "\t-? : this help\n";
	print "\t-v : verbose mode\n";
	print "\t-c : continue on error\n";
	print "\t-o : use a logarithmic scale for Y scale\n";
	print "\t-W width : images width (in pixels)\n";
	print "\t-H height : images height (in pixels)\n";
	print "\t-s start_date : start date (MM-DD-YYYY HH:MM:SS)\n";
	print "\t-e end_date : end date (MM-DD-YYYY HH:MM:SS)\n";
	print "\t-S step : interval (in seconds) between to values in the graph\n";
	print "\t-p period : exclusive with -s and -e\n";
	print "\t-x XMLFileSpec : name of XML file which describes the graph to generate\n";

	exit(1);
}

exit(0);

# EOF
