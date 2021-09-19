#!/usr/bin/perl
# Zanfona - join_contigs - final step
# v. 1.0 development
#
# Development copy, not for distribution.

# path to BBMap shell scripts
my $bbmap_path = '/panfs/pan1.be-md.ncbi.nlm.nih.gov/refseq_wgs/bbmap/bbmap';
$ENV{PATH} = "$ENV{PATH}:$bbmap_path";

# pragmas
use strict;
#use Data::Dump qw(dump);

##### MAIN BEGIN

my @file_data;
my $colsep = ",";
my $reverse_contigs_filename = "reverse_contig_list.txt";
my $gap_filename = "gap.data";
my @joined_contigs;
my $joined_fasta = "joined.fasta";

# query line columns
use constant {
        QUERY_ID                        => 0,
        CONTIG1_ID                      => 1,
        CONTIG1_ORIENTATION     => 2,
        CONTIG2_ID                      => 3,
        CONTIG2_ORIENTATION     => 4,
        GAP_SIZE                        => 5
};

# Clear final output file.
system("cat /dev/null >> " . $joined_fasta);

# Read all file data into array.
chomp(@file_data = <>);

# Remove header line from data.
@file_data = grep ! /query/, @file_data;

# Get list of contigs with reverse orientations.
my @reverse_contigs = ();
foreach (@file_data) {
  my @query_contigs = getReverseContigs($_);
  if (scalar(@query_contigs) > 0) {
        push(@reverse_contigs, @query_contigs[0]);
  }
  if (scalar(@query_contigs) > 1) {
        push(@reverse_contigs, @query_contigs[1]);
  }
}

# Create file of reverse contig names and FASTA file of contigs to reverse.
open(F, '>', $reverse_contigs_filename) or die "Couldn't open temporary file for reverse contigs.\n";
foreach (@reverse_contigs) {
        print F $_ . "\n";
}
close(F);

my $cmd1 = "filterbyname.sh -in=target.fasta -out=reverse_contig_list.fasta -include=t -names=" . $reverse_contigs_filename;
system($cmd1);

# Wait to give system time to free memory from previous call.
my $wait_seconds = 30;
sleep($wait_seconds);

# Create FASTA file of non-reversed contigs.
my $cmd2 = "filterbyname.sh -in=target.fasta -out=dont_reverse_me.fasta -include=f -names=" . $reverse_contigs_filename;
system($cmd2);

# Wait to give system time to free memory from previous call.
$wait_seconds = 30;
sleep($wait_seconds);

# Reverse-complement contigs.
my $cmd3 = "reformat.sh -in=reverse_contig_list.fasta out=reversed.fasta rcomp=t";
system($cmd3);

# Combine the reversed and non-reversed contigs.
my $cmd4 = "cat dont_reverse_me.fasta reversed.fasta > orientation_corrected.fasta";
system($cmd4);

# Loop through queries combining first and second contig where there's a gap.
foreach (@file_data) { 
        # Split line into query data.
        my @query_line = split(",", $_);
        my $contig1 = @query_line[CONTIG1_ID];
        my $contig2 = @query_line[CONTIG2_ID];
        my $gap_size = @query_line[GAP_SIZE];
        $gap_size =~ s/ //g;
        my $nstring = "";

        # for later
        push(@joined_contigs, $contig1);
        push(@joined_contigs, $contig2);

        # Wait to give system time to free memory from previous call.
        $wait_seconds = 30;
        sleep($wait_seconds);

        # Dump first contig to file system.
        my $cmd5 = "filterbyname.sh -in=orientation_corrected.fasta -out=first.fasta -names=" . $contig1 . " -include=true -ow=t";
        system($cmd5);

        # Wait to give system time to free memory from previous call.
        $wait_seconds = 30;
        sleep($wait_seconds);

        # Dump second contig to file system.
        my $cmd6 = "filterbyname.sh -in=orientation_corrected.fasta -out=second.fasta -names=" . $contig2 . " -include=true -ow=t";
        system($cmd6);

        # Remove header from second contig.
        system("grep -v '>' second.fasta > second.data");

        # Handle contigs with gaps.
        if ($gap_size >= 0) {
                # Non-zero length gap; fill with N's.
                if ($gap_size > 0) {
                        $nstring = sprintf("%" . $gap_size . "s", " ");
                        $nstring =~ s/ /N/g;
                }

                # Print gap to file.
                open(F, '>', $gap_filename) or die "Couldn't open temporary file for gap output.\n";
                print F $nstring;
                close(F);

                # Concatenate joined contigs to final results.
                system("cat first.fasta >> " . $joined_fasta);
                system("cat " . $gap_filename . " >> " . $joined_fasta);
                system("cat second.data >> " . $joined_fasta);
        }

        # Handle contigs that overlap.
        if ($gap_size < 0) {
                # Read headerless second contig into string.
                open(F, '<', "second.data") or die "Couldn't open second contig data for reading.\n";
                my $contig2_data = do { local $/; <F> };
                close(F);
                $contig2_data =~ s/\n//g;

                # Cut overlap area from front of second contig data.
                my $join_data = substr($contig2_data, abs($gap_size));

                # Dump join data to file.
                open(F, '>', "join.data") or die "Couldn't open join.data for writing.\n";
                print F $join_data . "\n";
                close(F);

                # Concatenate joined contigs to final result.
                system("cat first.fasta >> " . $joined_fasta);
                system("cat join.data >> " . $joined_fasta);

        }
}

# Create file of list of joined contigs.
open(F, ">", "joined_contigs.txt") or die "Couldn't open joined_contigs.txt for writing.";
foreach(@joined_contigs) {
        print F $_ . "\n";
}
close(F);

# Wait to give system time to free memory from previous call.
my $wait_seconds = 30;
sleep($wait_seconds);

# Remove joined contigs from original FASTA file.
my $cmd7 = "filterbyname.sh -in=target.fasta -out=target_2.fasta -names=joined_contigs.txt -include=f";
system($cmd7);

# Wait to give system time to free memory from previous call.
my $wait_seconds = 30;
sleep($wait_seconds);

# Concatenate joined contigs FASTA with target_2.fasta.
my $cmd8 = "cat " . $joined_fasta . " >> target_2.fasta";
system($cmd8);

# Wait to give system time to free memory from previous call.
my $wait_seconds = 30;
sleep($wait_seconds);

# Reformat target_2.fasta.
my $cmd9 = "reformat.sh -in=target_2.fasta -out=target_out.fasta -fastawrap=70 &
";
system($cmd9);

##### MAIN END

# subroutines

# getReverseContigs
sub getReverseContigs {
        my $query;
        my $contig1;
        my $contig1_orientation;
        my $contig2;
        my $contig2_orientation;

        my @result_array = ();
        my @query_line = split(/,/, $_);

        # Get contig names and orientations.
        $contig1 = @query_line[CONTIG1_ID];
        $contig1_orientation = @query_line[CONTIG1_ORIENTATION];
        $contig2 = @query_line[CONTIG2_ID];
        $contig2_orientation = @query_line[CONTIG2_ORIENTATION];

        #print "DEBUG " . $contig1 . " " . $contig1_orientation . " " . $contig2 . " " . $contig2_orientation . "\n"; 
        # If contig1 has reverse orientation, add it to array.
        if ($contig1_orientation eq "reverse") {
                push(@result_array, $contig1);
        }

        # If contig2 has reverse orientation, add it to array.
        if ($contig2_orientation eq "reverse") {
                push(@result_array, $contig2);
        }

        return @result_array;
}
