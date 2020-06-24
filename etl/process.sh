#!/bin/bash


# Download data
wget ftp://ftp-mouse.sanger.ac.uk/current_snps/mgp.v5.merged.snps_all.dbSNP142.vcf.gz
wget ftp://ftp.ensembl.org/pub/release-100/variation/vcf/mus_musculus/mus_musculus.vcf.gz


# Extract relevant columns from VCF files
bcftools +split-vep mgp.v5.merged.snps_all.100-GRCm38.vcf.gz -f '%CHROM\t%POS\t%ID\t%FILTER\t%REF\t%ALT\t%Consequence\t%Existing_variation[\t%GT\t%FI]\n' | gzip -c >mgp.v5.merged.snps_all.100-GRCm38.txt.gz


# Transform to meet table schema
./transformation.pl mgp.v5.merged.snps_all.100-GRCm38.txt.gz snps.txt


# Remove column is_complete
cut -f1-8,10-45 snps.txt >snps.rm.txt


# Add reference strain
cat <(head -n1 snps.rm.txt | sed 's/\t/\tC57BL_6J\t/8') <(sed 's/\t/\t0\t/8' <(sed 1d snps.rm.txt)) >snps.rm.ref.txt


# Statistics
sed 1d snps.rm.ref.txt | cut -f7 | sed 's/,/\n/g' | sort | uniq -c


# Update rsids
zcat mus_musculus.vcf.gz | grep -v "#" | awk '{print $1"\t"$2"\t"$4"\t"$5"\t"$3}' >mus_musculus.rsids.txt
./update_rsids.pl snps.rm.ref.txt mus_musculus.rsids.txt snps.rm.ref.rsids.txt
