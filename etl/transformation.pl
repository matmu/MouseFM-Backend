#!/usr/bin/perl


use lib("modules");


use strict;
use warnings;
use File::Reader;
use Scalar::Util qw(looks_like_number);


if (!defined $ARGV[0] || !defined $ARGV[1]){
	
	print STDERR "Arguments required: input_file output_file\n";

	exit(0);
}


my ($input_file, $output_file) = @ARGV;
die if(!-e $input_file);


my %chr;
$chr{$_} = 1 for (1..19);

my @consequences = ("transcript_ablation",
					"splice_acceptor_variant",
					"splice_donor_variant",
					"stop_gained",
					"frameshift_variant",
					"stop_lost",
					"start_lost",
					"transcript_amplification",
					"inframe_insertion",
					"inframe_deletion",
					"missense_variant",
					"protein_altering_variant",
					"splice_region_variant",
					"incomplete_terminal_codon_variant",
					"start_retained_variant",
					"initiator_codon_variant",
					"stop_retained_variant",
					"synonymous_variant",
					"coding_sequence_variant",
					"mature_miRNA_variant",
					"5_prime_UTR_variant",
					"3_prime_UTR_variant",
					"non_coding_transcript_exon_variant",
					"intron_variant",
					"NMD_transcript_variant",
					"non_coding_transcript_variant",
					"upstream_gene_variant",
					"downstream_gene_variant",
					"TFBS_ablation",
					"TFBS_amplification",
					"TF_binding_site_variant",
					"regulatory_region_ablation",
					"regulatory_region_amplification",
					"feature_elongation",
					"regulatory_region_variant",
					"feature_truncation",
					"intergenic_variant");

my @strains = ("129P2_OlaHsd",
			"129S1_SvImJ",
			"129S5SvEvBrd",
			"AKR_J",
			"A_J",
			"BALB_cJ",
			"BTBR",
			"BUB_BnJ",
			"C3H_HeH",
			"C3H_HeJ",
			"C57BL_10J",
			"C57BL_6NJ",
			"C57BR_cdJ",
			"C57L_J",
			"C58_J",
			"CAST_EiJ",
			"CBA_J",
			"DBA_1J",
			"DBA_2J",
			"FVB_NJ",
			"I_LnJ",
			"KK_HiJ",
			"LEWES_EiJ",
			"LP_J",
			"MOLF_EiJ",
			"NOD_ShiLtJ",
			"NZB_B1NJ",
			"NZO_HlLtJ",
			"NZW_LacJ",
			"PWK_PhJ",
			"RF_J",
			"SEA_GnJ",
			"SPRET_EiJ",
			"ST_bJ",
			"WSB_EiJ",
			"ZALENDE_EiJ");
			
my %strains;
foreach my $s (@strains){
	$strains{$s}{"homozygous"} = 0;
	$strains{$s}{"heterozygous"} = 0;
	$strains{$s}{"missing"} = 0;
	$strains{$s}{"multiallelic"} = 0;
	$strains{$s}{"low_confidence"} = 0;
}


open(OUT, ">".$output_file) or die "Cannot open file '$output_file': $!\n";

print OUT join("\t", ("chr", "pos", "ref", "alt", "rsid", "most_severe_consequence", "consequences", "n_genotypes", "is_complete", @strains))."\n";

my $reader = File::Reader -> new($input_file, {'has_header' => 0});
while ($reader -> has_next()){
		
		my @row = $reader -> next();
		
		my ($chr, $pos, $snp, $filter, $ref, $alt, $consequences, $existing_var, @geno) = @row;

		
		next if(!exists($chr{$chr}));
		die if(!looks_like_number($pos));
		die "Unknown reference allele '$ref'\n" if(!($ref =~ /^[ATGC]$/));
		
		my @alt = split(",", $alt);
		my $alt1 = $alt[0];
		die die "Unknown alt allele '$alt1'\n"  if(!($alt1 =~ /^[ATGC]$/));
		
		
		if(!defined $snp || !($snp =~ /^rs[0-9]+$/)){
			$snp = '\N';
		}
		

		my %consequences;
		$consequences{$_} = 1 for split(/[,&]+/, $consequences);
		
		my $most_severe_consequence;
		foreach my $c (@consequences){
			if(exists($consequences{$c})){
				$most_severe_consequence = $c;
				last;
			}
		}
		die "Unknown consequences '$consequences'\n" if(!defined $most_severe_consequence);
		
		
		my $is_complete = 1;
		my $n_geno = 0;
		
		my @genotype;
		for(my $i=0; $i<@geno; $i+=2){
			my $qual = $geno[$i+1];
			my @all = split("/", $geno[$i]);
			
			if($qual eq "0"){
				$is_complete = 0;
				push(@genotype, '\N');
				$strains{$strains[$i/2]}{"low_confidence"}++;
			}
			elsif($qual eq "."){
				$is_complete = 0;
				push(@genotype, '\N');
				$strains{$strains[$i/2]}{"missing"}++;
			}
			else {
				
				if(!($all[0] =~ /^[01]$/ && $all[1] =~ /^[01]$/)){
					$is_complete = 0;
					push(@genotype, '\N');
					$strains{$strains[$i/2]}{"multiallelic"}++;
				}
				elsif($all[0] == 0 && $all[1] == 0){
					$n_geno++;
					push(@genotype, 0);
					$strains{$strains[$i/2]}{"homozygous"}++;
				}
				elsif($all[0] == 1 && $all[1] == 1){
					$n_geno++;
					push(@genotype, 1);
					$strains{$strains[$i/2]}{"homozygous"}++;
				}
				else {
					$is_complete = 0;
					push(@genotype, '\N');
					$strains{$strains[$i/2]}{"heterozygous"}++;
				}
			}
		}
		
		
		if($n_geno == 0){
			print STDERR "No high confidence genotypes for $chr:$pos:$snp. Skip.\n";
			next;
		}

		
		print OUT join("\t", ($chr, $pos, $ref, $alt, $snp, $most_severe_consequence, join(",", sort keys(%consequences)), $n_geno, $is_complete, @genotype))."\n";
}

close OUT;


print join("\t", ("strain", "homozygous", "missing", "multiallelic", "heterozygous", "low_confidence"))."\n";
foreach my $s (sort keys(%strains)){
	print join("\t", ($s, $strains{$s}{"homozygous"}, $strains{$s}{"missing"}, $strains{$s}{"multiallelic"}, $strains{$s}{"heterozygous"}, $strains{$s}{"low_confidence"}))."\n";
}
