#!/usr/bin/env perl
use strict;
my $VERSION = 0.01;

#
# This program is copyright 2010-Forever Dathan Pattishall dathan@rockyou.com
# Feedback and improvements are welcome.
#
# THIS PROGRAM IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, version 2; OR the Perl Artistic License.  On UNIX and similar
# systems, you can issue `man perlgpl' or `man perlartistic' to read these
# licenses.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA  02111-1307  USA.
#



# ###########################################################################
# GmetricDelegate package
#  assume this is a abstract class and getData getCounterMetricHash/getAbsoluteMetricHash need to be defined in the
#  "subclass"
#
package GmetricDelegate;
#
# this is built via a make file
#
my $GMETRIC = "%%GMETRIC_PATH%%";

sub new {
	my $class = shift;
	my $self  = {};
	bless($self, $class);
	return $self;
}

sub getGmetricCMD(){
	my $self = shift;
	return '%%GMETRIC_PATH%%';
}

sub getSaveFileDir(){
	my $self = shift;
	return "/var/tmp";
}

#
# get the last data points for a possible delta
#

sub getLastState { 
	my $self = shift;

	my $tmp_dir_base	= $self->getSaveFileDir();
	my $tmp_stats_file	= $self->getFileName(); 
	if (! -d $tmp_dir_base ){
		system("/bin/mkdir -p $tmp_dir_base");
	}

	if (! -e $tmp_stats_file ){
		return; # 1st run no file?
	}

	open(FH, "<$tmp_stats_file") or die($!);
	while(<FH>){
		my($k,$v) = split(/:/, $_);
		$self->{prev_data}{$k} = $v;
	}
	
	return $self->{prev_data};
}

#
# save it for processing later
#

sub saveState {
	my $self		= shift;
	my $key_value	= shift;

	my $file		= $self->getFileName();

	open(DUMP, ">$file") or die ($!);
	
	for my $k (keys %{$key_value}){
		chomp($k);
		chomp($key_value->{$k});
		print DUMP "$k:$key_value->{$k}\n";
	}
	close(DUMP);
}

#
# define this in the subclass
#
sub getPackagePrefix {
	my $self = shift;
	return '';
}

#
# define this in the subclass
#

sub getCounterMetricHash{
	my $self = shift;
	my $counter = {};

	return $counter; 
}

#
# define this in the subclass
#

sub getAbsoluteMetricHash{
	my $self = shift;
	my $absolute = {};
	return $absolute;
}

#
# define this in the subclass
#

sub getData{
	my $self = shift;
	my $data = {};
	return $data;
}

#
# send the stuff to ganglia
#

sub sendGmetricData($$$){
	my $self			= shift;
	my $dataNow			= shift;
	my $dataLastRun		= shift;

	my $counter_metrics		= $self->getCounterMetricHash();
	my $absolute_metrics	= $self->getAbsoluteMetricHash();
	my $gmetric_command		= $self->getGmetricCMD();
	my $units = '';
	my $ganglia_prefix      = $self->getPackagePrefix();

	#Get the time stamp when the stats file was last modified
	my $old_time = (stat $self->getFileName())[9];
	my $timedelta = 1;
	if ($old_time){
		$timedelta = time() - $old_time;
	}
	foreach my $metric (keys %{$dataNow}){
		my $cmd = '';	
		next if ($dataNow->{$metric} !~ /\d+/); #not a number then skip
		if ($units = $counter_metrics->{$metric}){
			my $rate = ($dataNow->{$metric} - $dataLastRun->{$metric})/$timedelta;
			$cmd  = $gmetric_command . " -u '$units/sec' -tfloat -n $ganglia_prefix" . $metric . " -v " . $rate;
			print $cmd,"\n";

		} else {
			if (!($units = $absolute_metrics->{$metric})){
				$units = 'operations';
			}
			my $absolute = $dataNow->{$metric};
			$cmd = $gmetric_command . " -u '$units/sec' -tfloat -n $ganglia_prefix" . $metric . " -v " . $absolute;
			print $cmd,"\n";
		}
		system($cmd);
	}
}

#
# do it.
#
sub run() {
	my $self = shift;

	my $dataLastRun = $self->getLastState();
	my $dataNow     = $self->getData();
	$self->sendGmetricData($dataNow, $dataLastRun);
	$self->saveState($dataNow);
	return 1;
}

1;
