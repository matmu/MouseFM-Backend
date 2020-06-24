#!/usr/bin/perl


use lib("modules");


use strict;
use warnings;
use File::Reader;
use Scalar::Util qw(looks_like_number);


if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2]){
	
	print STDERR "Arguments required: input_file rsid_file output_file\n";

	exit(0);
}


my ($input_file, $rsid_file, $output_file) = @ARGV;
die if(!-e $input_file);
die if(!-e $rsid_file);


my %locus2rsid;
{
	my $reader = File::Reader -> new($rsid_file, {'has_header' => 0});
	while ($reader -> has_next()){
			
		my @row = $reader -> next();
		
		my ($chr, $pos, $ref, $alt, $rsid) = @row;
		
		next if(!($rsid =~ /^rs[0-9]+$/));
		
		if($ref =~ /^[ATGC]$/){

			my @alt;
			push(@alt, $_) for split(",", $alt);
			
			foreach my $a (@alt){

				if($a =~ /^[ATGC]$/){
					$locus2rsid{"$chr:$pos:$ref:$a"} = $rsid;
				}
			}
		}
	}
}


my $n = keys(%locus2rsid);
print "$n variants in hash\n";


open(OUT, ">".$output_file) or die "Cannot open file '$output_file': $!\n";
my $reader = File::Reader -> new($input_file, {'has_header' => 1});
my ($header, $header_inv, $header_mult) = $reader -> get_header();

my @header_string;
push(@header_string, ${$header_inv}{$_}) for sort {$a <=> $b} keys(%{$header_inv});
print OUT join("\t", @header_string)."\n";

while ($reader -> has_next()){
	
	my ($chr, $pos, $ref, $alt, $rsid, @rest) = $reader -> next();
	
	if(exists($locus2rsid{"$chr:$pos:$ref:$alt"})){
		$rsid = $locus2rsid{"$chr:$pos:$ref:$alt"};
	}
	
	print OUT join("\t", ($chr, $pos, $ref, $alt, $rsid, @rest))."\n";
}
close OUT;


