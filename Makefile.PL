#!/usr/bin/perl -w 
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use strict;

require 5.6.0;

unless (@ARGV) {
	warn <<END;
Notice: Type perl Makefile.PL -h for command-line option summary.

END
}


use Getopt::Long;
#############################################################################################
# Build options passed in to script to support reproducible builds via Makefiles
#############################################################################################
my ($gmetric_path, $nodetool_path);
my $result = GetOptions(
				"gmetric_path=s"   => \$gmetric_path,
				"nodetool_path=s"   => \$nodetool_path,
		);
unless ($result) {
  print STDERR <<END;
Usage: perl Makefile.PL [options]

Configure gmetric_ganglia.pl

 Options:
     -gmetric_path  path            path to gmetric
     -nodetool_path path			path to nodetool

If no options are passed on the command line.  The program will
will prompt for these values interactively.
END
}

sub MY::constants {
   package MY;   # To help SUPER work right 
   my $self = shift; 

   my @m; 
   push(@m, $self->SUPER::constants(@_)); 
   push(@m, 
     "export NODETOOL_PATH = $nodetool_path\n",
     "export GMETRIC_PATH  = $gmetric_path\n"); 

   join "", @m; 
   
} 




if (defined $gmetric_path){
	print "Path to Gmetric [$gmetric_path]\n";
} else {
	warn "\n";
	$gmetric_path = prompt("Where is Gmetric?",'/usr/bin/gmetric');
}

if (defined $nodetool_path){
	print "Path to NodeTool [$nodetool_path]\n";
} else {
	warn "\n";
	$nodetool_path = prompt("Where is Nodetool?", '/opt/cassandra/bin/nodetool');
}

WriteMakefile (
		NAME         => 'GmetricDelegate::GmetricCassandra',
		VERSION      => "0.01",
		PL_FILES     => {'bin/make_test.pl' => 'bin/make_test'},
		'EXE_FILES'	 => [ 'bin/ganglia_gmetric' ],
		'LIBS'		 => [''], # e.g., '-lm'
		'DEFINE'	 => '', # e.g., '-DHAVE_SOMETHING'
		'INC'		 => '', # e.g., '-I/usr/include/other'
		);
