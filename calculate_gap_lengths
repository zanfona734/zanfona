#!/usr/bin/perl
# gaplength - contig distance calculator
# v. 1.0
#
# version history
# 1.0 - release candidate
#
# The program takes input from STDIN
# and outputs results on STDOUT.

# pragmas
use strict;

# modules
use List::MoreUtils qw(uniq);

##### MAIN BEGIN

my @file_data;
my @query_lines;
my @queries;
my @header_array;
my $header;
my $colsep = ",";
my $results_all_queries;
my @results_all_queries;

# query line columns
use constant {
	QUERY_ID	=> 0,
	CONTIG_ID	=> 1,
	MIN_START	=> 2,
	MIN_STOP	=> 3,
	MAX_START	=> 4,
	MAX_STOP	=> 5,
	ORIENTATION	=> 6
};

# Read all file data into array.
chomp(@file_data = <>);

# Remove header line from data.
@file_data = grep ! /query/, @file_data;

# Get list of queries from file data (first column).
@query_lines = map { (split(/,/, $_))[QUERY_ID] } @file_data;
@queries = uniq @query_lines;

# Print output header.
@header_array = ("query","first_contig","first_contig_orientation","second_contig","second_contig_orientation","gap_size");
$header = join $colsep, @header_array;
print $header . "\n";

# Process all queries.
foreach (@queries) {
  $results_all_queries = $results_all_queries . doQuery($_, \@file_data) . "\n";
}
@results_all_queries = split(/\n/, $results_all_queries);

# Print results to output.
foreach (@results_all_queries) {
	print $_ . "\n";
}

##### MAIN END

# subroutines

# doQuery 
sub doQuery {
	my $query;
	my @contig_lines;
	my @contigs;
	my @query_lines;
	my $first_contig;
	my $second_contig;
	my $gap_length;
	my @result_array;
	my $result_string = "";
		
	my $query = $_[0];
	
	# Get data for this query from input data.
	@query_lines = grep /^$query,/, @{$_[1]};
	
	# Get list of contigs in this query.
	my @contig_lines = map { (split(/,/, $_))[CONTIG_ID] } @query_lines;
	my @contigs = uniq @contig_lines;
	
	# Only process if there are exactly two contigs.
	# (max index of @contigs is 1)
	if ($#contigs == 1) {
	
		# Determine order of contigs for calculation of gap length.
		if (getContigData(MIN_START, $query, @contigs[0], \@query_lines)
			< getContigData(MIN_START, $query, @contigs[1], \@query_lines)) {
			$first_contig = 0;
			$second_contig = 1;
		} else {
			$first_contig = 1;
			$second_contig = 0;
		}
		
		# Calculate gap length.
		$gap_length =	getContigData(MAX_STOP, $query, @contigs[$first_contig], \@query_lines) -
						getContigData(MIN_START, $query, @contigs[$second_contig], \@query_lines);
		
		# Construct result string.
		@result_array =	(
						$query,
						getContigData(CONTIG_ID, $query, @contigs[$first_contig], \@query_lines),
						getContigData(ORIENTATION, $query, @contigs[$first_contig], \@query_lines),
						getContigData(CONTIG_ID, $query, @contigs[$second_contig], \@query_lines),
						getContigData(ORIENTATION, $query, @contigs[$second_contig], \@query_lines),
						$gap_length
						);
		$result_string = join $colsep, @result_array;
		
	} else {

		# Add message about invalid contig count to STDERR here if desired.

	}
	
	return $result_string;
}

# getContigData
sub getContigData {
	my $column_number = $_[0];
	my $query = $_[1];
	my $contig = $_[2];
	my @query_lines = @{$_[3]};
	my @contig_line;
	my @contig_array;
	my $column_value = "";
		
	# Get data line for this contig from query data.
	@contig_line = grep /^$query,$contig,/, @query_lines;
	
	# Split line into data columns.
	@contig_array = split($colsep, @contig_line[0]);

	# Get desired column value.
	$column_value = @contig_array[$column_number];
	
	# Return data.
	return $column_value;
}
