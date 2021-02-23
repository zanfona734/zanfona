#!/usr/bin/perl
# Alembic - calculate_gap_length - contig distance calculator
# v. 1.0
#
# version history
# 1.0 - release candidate
#
# The program takes input from STDIN
# and outputs results on STDOUT.
#
# Copyright 2020 IRIDIAN GENOMES INC
#
# Permission is hereby granted, free of 
# charge, to any person obtaining a copy 
# of this software and associated documentation 
# files (the "Software"), to deal in the 
# Software without restriction, including 
# without limitation the rights to use, copy, 
# modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit 
# persons to whom the Software is furnished to 
# do so, subject to the following conditions:
#
# The above copyright notice and this permission 
# notice shall be included in all copies or 
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT 
# WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
# SOFTWARE.

# pragmas
use strict;

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
@queries = uniq(\@query_lines);

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
	my @contigs = uniq(\@contig_lines);
	
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

# uniq - returns a list of unique array elements
sub uniq {
	my @arr = @{$_[0]};
	my %count;
	my @res;
	
	# Add element to result list exactly once.
	foreach my $elem (@arr) {
		# Keep count of times this element has appeared.
		$count{$elem} = $count{$elem} + 1;
		
		# Add first occurence of element to result array.
		if ($count{$elem} == 1) {
			push @res, $elem;
		}
	}
	
	return @res;
}

