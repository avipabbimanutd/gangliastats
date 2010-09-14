
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
# GmetricCassandra package
#  this is a subclass of GmetricDelegate. It defines  getData getCounterMetricHash/getAbsoluteMetricHash
#

package GmetricCassandra;
use strict;



use base qw(GmetricDelegate);
our $VERSION = 0.01;

sub new {
	my $class = shift;
	my $self  = {};
	bless($self, $class);
	return $self;
}


#
# choose this method instead of parsing JMX since its more portable and less dependancies. additionally this is suppose
# to run on the cassandra boxes
#

sub getNodeToolCMD(){

	my $self = shift;

	return "%%NODETOOL_PATH%% --host localhost --port " . $self->getCassandraPort();

}
sub getCassandraPort(){

	my $self = shift;
	
	return '%%JMX_PORT%%';
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
		$k =~ s/\((\S+)\)/$1/g;
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
#
# customize cf and ks stats
#
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
#
# tpstats
#
		'tpc_response-stage' => 'responses',
		'tpc_row-read-stage' => 'row_reads',
		'tpc_lb-operations'  => 'operations',
		'tpc_message-deserializer-pool' => 'deserializations',
		'tpc_gmfd' => '?',
		'tpc_lb-target' => 'operations',
		'tpc_consistency-manager' => 'operations',
		'tpc_row-mutation-stage' => 'mutations',
		'tpc_message-streaming-pool' => 'streams',
		'tpc_load-balancer-stage'    => 'operations',
		'tpc_flush-sorter-pool'      => 'operations',
		'tpc_memtable-post-flusher' => 'flushes',
		'tpc_flush-writer-pool' => 'writes',
		'tpc_ae-service-stage' => 'operations',
		'tpc_hinted-handoff-pool' => 'operations',
		'tpc_messaging-service-pool' => 'operations',
		'tpc_commitlog' => 'commits',
		'tpc_compaction-pool' => 'compactions',
	};
	return $counter;
}

#
# i might remove this as its seen its not needed.
#
sub getAbsoluteMetricHash{
	my $self = shift;
	my $absolute = {
		'tpa_response-stage'                    => 'responses',
		'tpa_row-read-stage'                    => 'row_reads',
		'tpa_lb-operations'                     => 'operations',
		'tpa_message-deserializer-pool'			=> 'deserializations',
		'tpa_gmfd'								=> '?',
		'tpa_lb-target'                         => 'operations',
		'tpa_consistency-manager'               => 'operations',
		'tpa_row-mutation-stage'                => 'mutations',
		'tpa_message-streaming-pool'			=> 'streams',
		'tpa_load-balancer-stage'               => 'operations',
		'tpa_flush-sorter-pool'                 => 'operations',
		'tpa_memtable-post-flusher'             => 'flushes',
		'tpa_flush-writer-pool'                 => 'writes',
		'tpa_ae-service-stage'                  => 'operations',
		'tpa_hinted-handoff-pool'               => 'operations',
		'tpa_messaging-service-pool'			=> 'operations',
		'tpa_commitlog'							=> 'commits',
		'tpa_compaction-pool'                   => 'compactions',
		'tpp_response-stage'                    => 'responses',
		'tpp_row-read-stage'                    => 'row_reads',
		'tpp_lb-operations'						=> 'operations',
		'tpp_message-deserializer-pool'			=> 'deserializations',
		'tpp_gmfd'                              => '?',
		'tpp_lb-target'                         => 'operations',
		'tpp_consistency-manager'               => 'operations',
		'tpp_row-mutation-stage'                => 'mutations',
		'tpp_message-streaming-pool'			=> 'streams',
		'tpp_load-balancer-stage'               => 'operations',
		'tpp_flush-sorter-pool'                 => 'operations',
		'tpp_memtable-post-flusher'             => 'flushes',
		'tpp_flush-writer-pool'                 => 'writes',
		'tpp_ae-service-stage'                  => 'operations',
		'tpp_hinted-handoff-pool'               => 'operations',
		'tpp_messaging-service-pool'			=> 'operations',
		'tpp_commitlog'                         => 'commits',
		'tpp_compaction-pool'                   => 'compactions',

	};
	return $absolute;
}

1;
