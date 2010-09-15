#!/usr/bin/perl -w 
#
# some like ganglia_gmetric.pl over ganglia_gmetric
#
my $file = $ARGV[0];

if (!$file){
	die("File needs to be supplied\n");
}
print "Building $file\n";

open(GMD, "<./lib/GmetricDelegate.pm") or die("GmetricDelegate.pm not found: $!\n");
open(GMC, "<./lib/GmetricDelegate/GmetricCassandra.pm") or die("GmetricCassandra.pm not found: $!\n");

#
# now replace the stubs
#

#
# define the gmetric path
#
my $prepend = '';
while(my $line = <GMD>){
	if ($line =~ /%\%GMETRIC_PATH%%/s){
			$line =~ s/%\%GMETRIC_PATH%%/$ENV{'GMETRIC_PATH'}/g;
	}
	$prepend .= $line;
}

#
# define the nodetool path and JMX port
#
while(my $line = <GMC>){
	if ($line =~ /%\%NODETOOL_PATH%%/s){
			$line =~ s/%\%NODETOOL_PATH%%/$ENV{'NODETOOL_PATH'}/g;
	}
	if ($line =~ /%\%JMX_PORT%%/s){
			$line =~ s/%\%JMX_PORT%%/$ENV{'JMX_PORT'}/g;
	}
	$prepend .= $line;
}

#
# close up to be clean
#

close(GMD);
close(GMC);

#
# read the template file
#
open(TMPL, "<./bin/ganglia_gmetric_tmpl") or die("$!\n");

#
# write the destination file
#
open(GGM, ">./bin/$file") or die("$!\n");

print GGM $prepend,"\n";

while(my $line = <TMPL>){
	print GGM $line;
}

chmod(0655, "./bin/$file");

close(TMPL);
close(GGM);
	
