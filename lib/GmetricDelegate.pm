#!/usr/bin/perl
package GmetricDelegate;
use strict;


my $GMETRIC = "%%GMETRIC_PATH%%";
my $VERSION = 0.01;

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
sub getPackagePrefix {
	my $self = shift;
	return '';
}

sub getCounterMetricHash{
	my $self = shift;
	my $counter = {};

	return $counter; # I don't know which ones are every increasing need data.
}

sub getAbsoluteMetricHash{
	my $self = shift;
	my $absolute = {};
	return $absolute;
}
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
		if ($units = $counter_metrics->{$metric}){
			my $rate = $dataNow->{$metric} - $dataLastRun->{$metric}/$timedelta;
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

sub run() {
	my $self = shift;

	my $dataLastRun = $self->getLastState();
	my $dataNow     = $self->getData();
	$self->sendGmetricData($dataNow, $dataLastRun);
	$self->saveState($dataNow);
	return 1;
}

1;
