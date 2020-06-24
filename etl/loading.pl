#!/usr/bin/perl

use lib("modules");

use warnings;
use strict;
use DBI::DBHandler;
use Benchmark;
use File::Tee;
use File::Basename;


my $time_start_total = Benchmark -> new;


# SQL File
my $sql_tables_file = dirname($0)."/sql/tables.sql"; die "File '$sql_tables_file' doesn't exist\n" if (!-e $sql_tables_file);


# Database
my $database = "mousefm";


# Path
my $path = "/home/munz/projects/2019-03_-_Masterand_QTL_finemapping";


# Files
my $info_file = $path."/info_loading.txt";


# Disable buffer for STDOUT and STDERR
STDOUT -> autoflush(1);
STDERR -> autoflush(1);


# Redirect streams
print STDOUT "STDOUT and STDERR are saved to '$info_file'\n";
File::Tee::tee(STDOUT, $info_file);
File::Tee::tee(STDERR, $info_file);


# Table data
my %table2file = (
	'geno' => $path.'/snps.rm.ref.rsids.txt',
);


# Check files
foreach (keys(%table2file)){
	my $file = $table2file{$_};
	if (!-e $file){
		die "File '$file' doesn't exist\n";
	}
}


# DB config
my %dbconfig = (
	'dbname' => $database,
	'host' => 'localhost',
	'port' => 3306,
	'user' => 'mysql',
	'pass' => '8erbahn',
	'mysql_local_infile' => 1
);


my $handler = DBI::DBHandler -> new(\%dbconfig);
$handler -> connect();

my $table2tmp_table = $handler -> create_tmp_tables_from_file($sql_tables_file, \%table2file);
foreach my $table (sort keys(%table2file)){
	
	print "Load data into table '${$table2tmp_table}{$table}'\n";
	
	#print "\t...disable log bin\n";
	#$handler -> query("SET sql_log_bin=0");
	
	print "\t...disable keys\n";
	$handler -> query("ALTER TABLE ".${$table2tmp_table}{$table}." DISABLE KEYS");
	
	my $file;
	my $forkmanager;
	my $job_id;
	if($table2file{$table} =~ /gz$/){
		my $filename = basename($table2file{$table});
		$file = "/tmp/$filename";
		
		print "mkfifo --mode=0666 $file\n";
		unlink($file) if(-e $file);
		system("mkfifo --mode=0666 $file");
		print "gzip --stdout -d $table2file{$table} >$file &\n";
		system("gzip --stdout -d $table2file{$table} >$file &");
	}
	else {
		$file = $table2file{$table};
	}
	
	print "\t...load data from file\n";
	$handler -> load_data_from_tsv_file(${$table2tmp_table}{$table}, $file, 1);
	
	if($table2file{$table} =~ /gz$/){
		print "rm $file\n";
		system("rm $file");
	}
	
	print "\t...count lines in table\n";
	my $lines_table = $handler -> count_lines(${$table2tmp_table}{$table});
	
	print "\t...count lines in file\n";
	my $lines_file = count_lines_in_file($table2file{$table}, 1);

	if ($lines_file > $lines_table){
		print "\tFile '$table2file{$table}' contains more lines ($lines_file) than table '$table' ($lines_table)\n";
	}
	elsif ($lines_file < $lines_table){
		print "\tFile '$table2file{$table}' contains less lines ($lines_file) than table '$table' ($lines_table)\n";
	}
	else {
		print "\tTable '$table' contains $lines_file records\n";
	}
	
	print "\t...enable keys\n";
	$handler -> query("ALTER TABLE ".${$table2tmp_table}{$table}." ENABLE KEYS");
}

$handler -> drop_all_views();
$handler -> rename_tables($table2tmp_table, 1);
$handler -> disconnect();


print STDOUT "Total time: ".timestr(timediff(Benchmark->new, $time_start_total))."\n";


# -----------------------------------------------
sub count_lines_in_file {
# -----------------------------------------------
	my ($file, $skip_n) = @_;
	
	my $count = 0;
	my $in;
	if($file =~ /gz$/){
		open($in, "gunzip -c $file |") or die "Can't open file '$file': $!\n";
		
	}
	else {
		open($in, "<$file") or die "Can't open file '$file': $!\n";
	}
	
	while(<$in>){
		$count++;
	}
	close $in;
	
	$count -= $skip_n;
	$count = 0 if ($count < 0);
	
	return $count;
}
