package GmetricCassandra;
use strict;



use base qw(GmetricDelegate);
my $VERSION = 0.01;

sub new {
	my $class = shift;
	my $self  = {};
	bless($self, $class);
	return $self;
}

sub getNodeToolCMD(){

	my $self = shift;

	return "%%NODETOOL_PATH%% -host localhost -port " . $self->getCassandraPort();

}
sub getCassandraPort(){

	my $self = shift;
	
	return "8181";
}

sub getFileName {
	my $self = shift;
	$self->{save_file_name} = $self->getSaveFileDir() . "/cassandra.gmetric.data";
	return $self->{save_file_name};
}

sub setData {
	my $self = shift;
	my $data = shift;
	
	$self->{gmetric_data} = $data;
}

sub getData {
	my $self = shift;
	
	$self->{current_data} = {};
	my $tpstats = $self->gettpstatsData();
	my $cfstats = $self->getcfstatsData();
	foreach my $k(keys %{$tpstats}){
		$self->{current_data}{lc($k)} = $tpstats->{$k};
	}
	foreach my $k(keys %{$cfstats}){
		if ($self->{current_data}{lc($k)}){
			print "What key already exists\n";
		}
		$self->{current_data}{lc($k)} = $cfstats->{$k};
	}
	
	
			

	return $self->{current_data};
	
}

sub gettpstatsData{
	my $self = shift;
	my $cmd  = $self->getNodeToolCMD() . " tpstats";

	open(CMD, $cmd . "|") or die("$cmd:$!\n");
	my $hashref = {};
	while(<CMD>){
		next if ($_ =~ /^Pool Name/);
		my ($key, $active, $pending, $completed) = split(/\s+/, $_);
		$hashref->{$key} = $completed;

	}
	return $hashref;
	close CMD;
}

sub getcfstatsData{
	my $self = shift;
	my $cmd  = $self->getNodeToolCMD() . " cfstats";

	open(CMD, $cmd . "|") or die("$cmd:$!\n");
	my $hashref = {};
	my $found_user_keyspace = 0;
	my $prefix = '';
	while(<CMD>){

		next if ($_ !~ /^--.+/ && $found_user_keyspace == 0);
		$found_user_keyspace = 1;
		
		next if ($_ =~ /^--.+/);
		my $line = $_;
		chomp($line);
		$line =~ s/^\t+//g;
		next if (!$line);

		if ($line =~ /^Keyspace: (\S+)/){
			$prefix = "ks_$1";
			next;
		}

		if ($line =~ /^Column Family: (\S+)/){
			$prefix = "cf_$1";
			next;
		}

		my ($k, $v) = split(":", $line);
		$k =~ s/\s+/_/g;
		$v =~ s/\s+//g;
		$v =~ s/ms\.//g;
		$v =~ s/NaN/0/g;
		$hashref->{$prefix . '_' . $k} = $v;

	}
	return $hashref;
	close CMD;
}

sub getinfoData {
	my $self = shift;
}

sub getPackagePrefix{
	return 'cass_';
}

sub getCounterMetricHash{
	my $self = shift;

	my $counter = {
		'cf_treeclick_write_count' => 'writes',
		'cf_standard2_memtable_switch_count' => 'switches',
		'cf_complex_write_count' => 'writes', 
		'cf_treeclick_memtable_columns_count' => 'columns',
		'cf_treeclick_memtable_switch_count' => 'switches',
		'cf_complex_read_count' => 'reads',
		'cf_standardbytime_read_count' => 'reads',
		'cf_standard2_read_count' => 'reads',
		'cf_standardbytime_write_count' => 'writes',
		'cf_standard2_memtable_columns_count' => 'columns',
		'cf_standardbytime_memtable_switch_count' => 'switches',
		'cf_complex_memtable_columns_count' => 'columns',
		'cf_complex_memtable_switch_count' => 'switches',
		'ks_timeframeclicks_read_count' => 'reads',
		'ks_timeframeclicks_write_count' => 'writes',
		'cf_standard2_write_count' => 'writes',
		'cf_treeclick_read_count' => 'reads',
		'cf_standardbytime_memtable_columns_count' => 'columns',
		'cf_standard2_memtable_data_size' => 'growth',
		'message-deserializer-pool' => 'count',
		'row-mutation-stage' => 'mutation',
		'messaging-service-pool' => 'count',
		'gmfd' => '?',
		'memtable-post-flusher' => 'flushes',
		'row-read-stage' => 'reads',
		'commitlog' => 'commits',
		'flush-writer-pool' => 'writes',
		'compaction-pool' => 'compactions',
		'response-stage' => 'responses',
	};
	return $counter; # I don't know which ones are every increasing need data.
}

sub getAbsoluteMetricHash{
	my $self = shift;
	my $absolute = {};
	return $absolute;
}

1;
