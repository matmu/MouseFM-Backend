package DBI::DBHandler;

use strict;
use warnings;
use DBI;


# -----------------------------------------------
# Constructor
sub new {
# -----------------------------------------------
	my ($class, $configs) = @_;
	
	
	my $self = {};
	
	$self -> {'dbname'} = ${$configs}{'dbname'} or die;
	$self -> {'host'} = ${$configs}{'host'} or die;
	$self -> {'port'} = ${$configs}{'port'} or die;
	$self -> {'user'} = ${$configs}{'user'} or die;
	$self -> {'pass'} = ${$configs}{'pass'} or die;
	$self -> {'mysql_local_infile'} =  ${$configs}{'mysql_local_infile'};
	if (defined $self -> {'mysql_local_infile'}){
		$self -> {'dsn'} = "dbi:mysql:".$self -> {'dbname'}.":".$self -> {'host'}.":".$self -> {'port'}.";mysql_local_infile=".$self -> {'mysql_local_infile'};
	}
	else {
		$self -> {'dsn'} = "dbi:mysql:".$self -> {'dbname'}.":".$self -> {'host'}.":".$self -> {'port'};
	}
	
	bless($self, $class);
	
	return($self);
}


# -----------------------------------------------
sub connect {
# -----------------------------------------------
	my ($self) = @_;
	
	$self -> {'dbh'} = DBI -> connect($self -> {'dsn'}, $self -> {'user'}, $self -> {'pass'}) || die "Connection Error: $DBI::errstr\n";
}


# -----------------------------------------------
sub disconnect {
# -----------------------------------------------
	my $self = shift;
	
	if (defined $self -> {'dbh'}){
		$self -> {'dbh'} -> disconnect();
		
		delete $self -> {'dbh'};
		delete $self -> {'sth'};
	}
}


# -----------------------------------------------
sub update_tables {
# -----------------------------------------------
	my ($self) = @_;
	
	$self -> query("SHOW TABLES");
	my @results = @{$self -> get_results()};
	foreach my $table (@results){
		
		my $table_name = "@{$table}";
		$self -> query("DESCRIBE $table_name");
		my @columns = @{$self -> get_results()};
		
		@{${$self -> {'tables'}}{$table_name}} = ();
		push(@{${$self -> {'tables'}}{$table_name}}, $_ -> [0]) for @columns;
	}
}


# -----------------------------------------------
sub check_if_table_exists {
# -----------------------------------------------
	my ($self, $table) = @_;
	
	$self -> update_tables();

	if (!exists(${$self -> {'tables'}}{$table})){
		return 0;
	}
	else {
		return 1;

	}
}


# -----------------------------------------------
sub query {
# -----------------------------------------------
	my ($self, $sql) = @_;
	
	if (defined $self -> {'dbh'}){
		
		$self -> {'sth'} = $self -> {'dbh'} -> prepare($sql);
		my $success = $self -> {'sth'}  -> execute();
		if (!$success && !defined $DBI::errstr){
			print STDERR "Query not successful. No error message returned. Try to continue.\n";
		}
		elsif (!$success && defined $DBI::errstr){
			die "SQL Error: $DBI::errstr\n";
		}
	}
	else {
		
		die "No connection established.\n";
	}
}


# -----------------------------------------------
sub get_results {
# -----------------------------------------------
	my ($self) = @_;
	
	my @results;
	
	if(defined $self -> {'sth'}){
		while (my @row = $self -> {'sth'} -> fetchrow_array){
			push(@results, \@row);
		}
		$self -> {'sth'}  -> finish();
	}
	
	return \@results;
}


# -----------------------------------------------
sub get_header {
# -----------------------------------------------
	my ($self, $table) = @_;
	
	$self -> query("SELECT * FROM $table WHERE 1=0");
	
	if(defined $self -> {'sth'}){
		
		my $fields = $self -> {'sth'} -> {NAME};
		$self -> {'sth'}  -> finish();
		
		return $fields;
	}
	else {
		return ;
	}	
}


# -----------------------------------------------
sub clear_all_tables {
# -----------------------------------------------
	my ($self) = @_;
	
	$self -> update_tables();
	
	my @keys = keys(%{$self -> {'tables'}});
	foreach my $table (@keys){
		print STDOUT "Clearing table '$table'\n";
		
		$self -> query("DELETE FROM $table");
		# $self -> query("ALTER TABLE $table AUTO_INCREMENT = 1");
	}
}


# -----------------------------------------------
sub clear_table {
# -----------------------------------------------
	my ($self, $table) = @_;
	
	if ($self -> check_if_table_exists($table)){
	
		print STDOUT "Clearing table '$table'\n";
		
		$self -> query("DELETE FROM $table");
	}
}


# -----------------------------------------------
sub drop_all_tables {
# -----------------------------------------------
	my ($self) = @_;
	
	$self -> update_tables();
	
	my @keys = keys(%{$self -> {'tables'}});
	foreach my $table (@keys){
		print STDOUT "Dropping table '$table'\n";
		
		$self -> query("DROP TABLE IF EXISTS $table");
	}
	
	$self -> update_tables();
}


# -----------------------------------------------
sub drop_all_views {
# -----------------------------------------------
	my ($self) = @_;
	
	$self -> update_tables();
	
	my @keys = keys(%{$self -> {'tables'}});
	foreach my $table (@keys){
		
		if ($table =~ /^view_/){
			print STDOUT "Dropping view '$table'\n";
			$self -> query("DROP VIEW IF EXISTS $table");
		}
	}
	
	$self -> update_tables();
}


# -----------------------------------------------
sub drop_table {
# -----------------------------------------------
	my ($self, $table) = @_;
	
	if ($self -> check_if_table_exists($table)){
	
		print STDOUT "Dropping table '$table'\n";
		
		$self -> query("DROP TABLE IF EXISTS $table");
		
		$self -> update_tables();
	}
}


# -----------------------------------------------
sub single_entry {
# -----------------------------------------------
	my ($self, $table, $entry, $disable_warnings) = @_;
	
	if ($self -> check_if_table_exists($table)){
	
		my $sql = "INSERT INTO $table (";
		
		foreach my $col (@{${$self -> {'tables'}}{$table}}){
			$sql = $sql.$col.", ";
		}
		chop($sql);
		chop($sql);
		$sql = $sql.') VALUES (';
		
		foreach my $field (@{$entry}){
			$sql = $sql.$field.", ";
		}
		chop($sql);
		chop($sql);
		$sql = $sql.')';
		
		$self -> query($sql);
		
		if (!defined $disable_warnings or $disable_warnings == 1){
			$self -> show_warnings(9999);
		}
	}
}


# -----------------------------------------------
sub execute_sql_file {
# -----------------------------------------------
	my ($self, $file) = @_;
	
	my @statements = $self -> parse_sql_file($file);
	
	foreach (@statements){
		$self -> query($_);	
		$self -> show_warnings(9999);
	}
}


# -----------------------------------------------
sub parse_sql_file {
# -----------------------------------------------
	my ($self, $file) = @_;
	
	open(IN, "<$file") or die "Can't open file: $!\n";
	my $lines = "";
	while(<IN>){
		$_ =~ s/\n/ /g;
		$lines .= $_;
	}
	close IN;
	
	my @statements = split(/;/, $lines);
	my @trimmed_statements;
	
	foreach (@statements) {
		$_ = trim($_);
		$_ =~ s/\s+/ /g;
		
		if (!($_ eq "")){
			push (@trimmed_statements, $_);
		}
	}
	
	return @trimmed_statements;
}


# -----------------------------------------------
sub create_tmp_tables_from_file {
# -----------------------------------------------
	my ($self, $file, $table_names) = @_;
	
	my @statements = $self -> parse_sql_file($file);
	
	my @tmp_statements;
	my %table_name2tmp_table_name;
	foreach (@statements){
		$_ =~ m/CREATE TABLE `?([A-Za-z0-9_]+)`? \(.*\)/;
		my $table_name = $1;
		
		die if (!defined $table_name);
		
		if (defined $table_names && exists(${$table_names}{$table_name})){
			my $tmp_table_name = "tmp_".$table_name;
			$_ =~ s/$table_name/$tmp_table_name/;
			
			$table_name2tmp_table_name{$table_name} = $tmp_table_name;
			
			$self -> drop_table($tmp_table_name);
			
			print "Create table '$tmp_table_name'\n";
			$self -> query($_);	
			$self -> show_warnings(9999);
		}
	}
	
	$self -> update_tables();
	
	\%table_name2tmp_table_name;
}


# -----------------------------------------------
sub rename_tables {
# -----------------------------------------------	
	my ($self, $table_name2tmp_table_name, $drop) = @_;
	
	foreach my $table (keys(%{$table_name2tmp_table_name})){
		
		if ($self -> check_if_table_exists(${$table_name2tmp_table_name}{$table})){
		
			my $tmp_table = ${$table_name2tmp_table_name}{$table};
			
			if ($drop){
				$self -> drop_table($table);
			}
			
			print STDOUT "Renaming table '$tmp_table' to '$table'\n";
			
			$self -> query("RENAME TABLE $tmp_table TO $table");
			$self -> show_warnings(9999);
		}
	}
	
	$self -> update_tables();
}


# -----------------------------------------------
sub load_data_from_tsv_file {
# -----------------------------------------------
	my ($self, $table, $file, $has_header) = @_;
	
	if ($self -> check_if_table_exists($table)){
	
		my $statement = "LOAD DATA LOCAL INFILE '$file' INTO TABLE $table CHARACTER SET utf8";
		$statement .= " IGNORE 1 LINES" if ($has_header);
		
		print "Load data from file '$file' in table '$table'\n";
		$self -> query($statement);
		$self -> show_warnings(9999);
	}
	else {
		die "Table '$table' doesn't exist\n";
	}
}


# -----------------------------------------------
sub count_lines {
# -----------------------------------------------
	my ($self, $table) = @_;
	
	if ($self -> check_if_table_exists($table)){;
	
		$self -> query("SELECT count(*) FROM $table");
		my @results = @{$self -> get_results()};
	
		return $results[0][0];
	}
	else {
		die "Table '$table' doesn't exist\n";
	}
}


# -----------------------------------------------
sub show_warnings {
# -----------------------------------------------
	my ($self, $max_error_count) = @_;
	
	if (defined $max_error_count){
		$self -> query("SET max_error_count = $max_error_count");
	}
	
	$self -> query("SHOW WARNINGS");
	my @results = @{$self -> get_results()};
	
	print STDERR join("\t", @{$_})."\n" for @results;
}


# -----------------------------------------------
sub trim {
# -----------------------------------------------
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

1;