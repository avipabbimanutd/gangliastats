#!/usr/bin/perl -w 



open(GMD, "<./lib/GmetricDelegate.pm") or die("$!\n");
open(GMC, "<./lib/GmetricDelegate/GmetricCassandra.pm") or die("$!\n");

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
open(TMPL, "<./bin/ganglia_gmetric_tmpl") or die("$!\n");
open(GGM, ">./bin/ganglia_gmetric") or die("$!\n");

print GGM $prepend,"\n";

while(my $line = <TMPL>){
	print GGM $line;
}

close(TMPL);
close(GGM);
	
