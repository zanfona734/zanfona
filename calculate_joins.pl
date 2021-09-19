#!/usr/bin/perl
# Zanfona - calculate_joins - contig assembly tool
# v. 1.0
#
# version history
# 1.0 - release candidate
#
# The program takes input from STDIN
# and outputs results on STDOUT.
#
# It does no error checking for input
# validity or available memory and is
# not fault tolerant.
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

my @all_contigs;
my @duplicate_contigs;
my @mod_queries;
my @singleton_queries;
my @mod_results;

# Read all file data into array.
chomp(@file_data = <>);

# Remove comment lines from data.
@file_data = grep ! /\#/, @file_data;

# Get list of queries from file data (first column).
@query_lines = map { (split(/\s+/, $_))[0] } @file_data;
@queries = uniq(\@query_lines);

# Print output header.
@header_array = ("query","contig","min-start","max-start","min-stop","max-stop","orientation");
$header = join $colsep, @header_array;
print $header . "\n";

# Process all queries.
foreach (@queries) {
  $results_all_queries = $results_all_queries . doQuery($_, \@file_data)	;
}
@results_all_queries = split(/\n/, $results_all_queries);

### Remove results where contigs occur in more than one query.

# Find duplicate contigs in results.
@all_contigs = map { (split($colsep, $_))[1] } @results_all_queries;
@duplicate_contigs = multiples(\@all_contigs);

# Strip duplicate contigs from results.
# Results remain in their original order.
@mod_results = @results_all_queries;
foreach my $dc (@duplicate_contigs) {
	@mod_results = grep ! /^\w+[$colsep]($dc)[$colsep]/, @mod_results;
}

# Find queries with only singlton contigs from results.
@mod_queries = map { (split($colsep, $_))[0] } @mod_results;
@singleton_queries = singles(\@mod_queries);

# Strip singleton queries from results.
# Results remain in their original order.
foreach my $sq (@singleton_queries) {
	@mod_results = grep ! /^($sq)[$colsep]/, @mod_results;
}

# Print results to output.
foreach (@mod_results) {
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
	my $results_string = "";
		
	my $query = $_[0];
	
	# Get data for this query from input data.
	@query_lines = grep /^$query\s+/, @{$_[1]};

	# Get list of contigs in this query.
	my @contig_lines = map { (split(/\s+/, $_))[1] } @query_lines;
	my @contigs = uniq(\@contig_lines);
	
	# Only  process if there are exactly two contigs.
	# (max index of @contigs is 1)
	if ($#contigs == 1) {

		# Process contigs and construct results.
		foreach (@contigs) {
			$results_string = $results_string . doContig($query, $_, \@query_lines) . "\n";
		}

	} else {

		# Add message about invalid contig count to STDERR here if desired.

	}
	
	return $results_string;
}

# doContig
sub doContig {
	my $query;
	my $contig;
	my @contig_lines;
	my @contig_starts;
	my @contig_stops;
	my $start_min;
	my $start_max;
	my $stop_min;
	my $stop_max;
	my $direction;
	my @result_array;
	my $result_string;
		
	$query = $_[0];
	$contig = $_[1];
		
	# Get data lines for this contig from query data.
	@contig_lines = grep /^$query\s+$contig\s+/, @{$_[2]};
	
	# Extract contig starts (9'th column).
	@contig_starts = map { (split(/\s+/, $_))[8] } @contig_lines;
	
	# Determine contig start min and max values.
	$start_min = min(@contig_starts);
	$start_max = max(@contig_starts);
	
	# Extract contig stops (10'th column).
	@contig_stops = map { (split(/\s+/, $_))[9] } @contig_lines;

	# Determine contig stop min and max values.
	$stop_min = min(@contig_stops);
	$stop_max = max(@contig_stops);
	
	# Determine contig direction.
	if ($start_min <= $stop_min) {
		$direction = "forward";
	} else {
		$direction = "reverse";
	}
	
	# Construct result string for this contig.
	@result_array = ($query, $contig, $start_min, $start_max, $stop_min, $stop_max, $direction);
	$result_string = join $colsep, @result_array;
	
	return $result_string;
}

# singles - returns a list of array elements that appear once
sub singles {
	my @arr = @{$_[0]};
	my %count;
	my @res;
	
	# Create hash of count of each element.
	foreach my $elem (@arr) {
		$count{$elem} = $count{$elem} + 1;
	}
	
	# Construct list of elements with count = 1.
	foreach (keys %count) {
		if ($count{$_} == 1) {
			push @res, $_;
		}
	}
	
	return @res;
}

# multiples - returns a list of array elements that appear more than once
sub multiples {
	my @arr = @{$_[0]};
	my %count;
	my @res;
	
	# Create hash of count of each element.
	foreach my $elem (@arr) {
		$count{$elem} = $count{$elem} + 1;
	}
	
	# Construct list of elements with count > 1.
	foreach (keys %count) {
		if ($count{$_} > 1) {
			push @res, $_;
		}
	}
	
	return @res;
}

# uniq - returns a list of unique array elements
sub uniq {
	my @arr = @{$_[0]};
	my %count;
	my @res;
	
	# Create result array of unique array elements.
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

# min - returns minimum value from array elements
sub min {
	my @arr = @_;
	my $arrlen = scalar @arr;
	my $minval;
	
	# If array is not empty, loop through to find minimum.
	if ($arrlen > 0) {
		my $minval = @arr[0];
		foreach (@arr) {
			if ($_ < $minval) {
				$minval = $_;
			}
		}
		return $minval;
		
	} else {
		# Array is empty, minimum is undefined.
		return;
	}
}

# max - returns maximum value from array elements
sub max {
	my @arr = @_;
	my $arrlen = scalar @arr;
	my $maxval;
	
	# If array is not empty, loop through to find maximum.
	if ($arrlen > 0) {
		my $maxval = @arr[0];
		foreach (@arr) {
			if ($_ > $maxval) {
				$maxval = $_;
			}
		}
		return $maxval;
		
	} else {
		# Array is empty, maximum is undefined.
		return;
	}
}
