# alembic
<b><h2>A genome assembly finishing tool</h2></b>
<p>
Alembic is a genome finishing tool used to make additional joins and calculate gaps and overlaps based on one or more reference genomes simultaneously. It uses an iterative pairing approach which does not assume that related species have identical sequence structure.  <p>
Alembic also does not require a high-quality genome assembly to use a a reference.  It can be used on a group of pre-assemblies of related species, each acting as a reference genome for the others.

<b>Getting Started:</b>

#determine order and orientation of preassembly contigs based on one or more reference genomes. <p>
calculate_joins.pl


#calculate gap lengths and overlaps based on one or more reference genomes. <p>
calculate_gap_lengths.pl


<b>Dependencies:</b>

Trimmomatic:
https://github.com/timflutre/trimmomatic

BBmap suite:
https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/bbmap-guide/

Blast suite:
https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download
