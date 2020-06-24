package File::Reader;

use strict;
use warnings;
use PerlIO::gzip;
use Scalar::Util qw(looks_like_number);


# -----------------------------------------------
# Constructor
sub new {
# -----------------------------------------------
	my ($class, $file, $configs) = @_;
	
	die "File '$file' doesn't exist\n" if (!-e $file);
	
	my $self = {};
	$self -> {'file'} = $file;
	$self -> {'has_header'} = (exists(${$configs}{'has_header'})) ? ${$configs}{'has_header'} : 0;
	$self -> {'skip'} = (exists(${$configs}{'skip'})) ? ${$configs}{'skip'} : '#';
	$self -> {'is_compressed'} = ($file =~ /\.gz$/) ? 1 : 0;
	$self -> {'sep'} = (exists(${$configs}{'sep'})) ? ${$configs}{'sep'} : _guess_seperator($file, $self->{'skip'}, $self->{'is_compressed'});
	
	if ($self -> {'has_header'}){
		($self -> {'header'}, $self -> {'header_inv'}, $self -> {'header_mult'}, $self -> {'header_string'}) = _read_header($file, $self->{'skip'}, $self->{'sep'}, $self->{'is_compressed'});
	}
	
	$self -> {'meta'} = _read_meta($file, $self->{'skip'}, $self->{'is_compressed'});
	
	$self -> {'handle'} = _get_handle($file, $self -> {'has_header'}, $self -> {'skip'}, $self->{'is_compressed'}); 
	
	bless($self, $class);
	
	return($self);
}


# -----------------------------------------------
sub has_next {
# -----------------------------------------------
	my ($self) = @_;
	my $handle = $self -> {'handle'};
	return !eof($handle);
}


# -----------------------------------------------
sub next {
# -----------------------------------------------
	my ($self, $n_splits) = @_;
	
	my $handle = $self -> {'handle'};
	my $sep = $self -> {'sep'};
	
	if (!eof($handle)){
		my $line = readline($handle);
		return _split($line, $sep, $n_splits);
	}
	else {
		return;
	}
}


# -----------------------------------------------
sub get_header {
# -----------------------------------------------
	my ($self) = @_;
	return  $self -> {'header'}, $self -> {'header_inv'}, $self -> {'header_mult'};
}


# -----------------------------------------------
sub get_header_string {
# -----------------------------------------------
	my ($self) = @_;
	return  $self -> {'header_string'};
}


# -----------------------------------------------
sub get_meta {
# -----------------------------------------------
	my ($self) = @_;
	return $self -> {'meta'};
}


# -----------------------------------------------
sub _get_handle {
# -----------------------------------------------
	my ($file, $has_header, $skip, $is_compressed) = @_;
	
	
	my $handle_ready;
	
	
	my $handle;
	if($is_compressed){
		open($handle, "<:gzip", "$file") or die "Cannot open file '$file': $!\n";
	}
	else {
		open($handle, "<".$file) or die "Cannot open file '$file': $!\n";
	}
	
	
	if ($has_header){
		while(<$handle>){
			chomp($_);
			if (defined $skip && $_ =~ /^$skip/ || $_ eq ""){
				last if (!$has_header);
			}
			elsif($has_header){
				last;
			}
		}
		
		$handle_ready = $handle;
	}
	else {
		
		my $i=0;
		my $in;
		
		if($is_compressed){
			open($in, "<:gzip", "$file") or die "Cannot open file '$file': $!\n";
		}
		else {
			open($in, "<".$file) or die "Cannot open file '$file': $!\n";
		}
		while(<$in>){
			chomp($_);
			if (defined $skip && $_ =~ /^$skip/ || $_ eq ""){
				$i++;
			}
			else{
				last;
			}
		}
		
		
		if($i > 0){
			while(<$handle>){
				$i--;
				last if($i == 0);
			}	
		}
		$handle_ready = $handle;
	}
	
	return $handle_ready;
}


# -----------------------------------------------
sub _read_header {
# -----------------------------------------------
	my ($file, $skip, $sep, $is_compressed) = @_;
	
	my %header;
	my %header_inv;
	my %header_mult;
	my $header_string;
	my $in;
	if($is_compressed){
		open($in, "<:gzip", "$file") or die "Cannot open file '$file': $!\n";
	}
	else {
		open($in, "<".$file) or die "Cannot open file '$file': $!\n";
	}
	while(<$in>){
		chomp($_);
		if (defined $skip && $_ =~ /^$skip/ || $_ eq ""){}
		else {
			$header_string = $_;
			my @row = _split($header_string, $sep);
			
			my $i=0;
			$header{$_} = $i++ for @row;
			
			my $j=0;
			$header_inv{$j++} = $_ for @row;
			
			my $m=0;
			push(@{$header_mult{$_}}, $m++) for @row;
			
			last; 
		}
	}

	return \%header, \%header_inv, \%header_mult, $header_string;
}


# -----------------------------------------------
sub _read_meta {
# -----------------------------------------------
	my ($file, $skip, $is_compressed) = @_; 
	
	my @meta;
	my $in;
	if($is_compressed){
		open($in, "<:gzip", "$file") or die "Cannot open file '$file': $!\n";
	}
	else {
		open($in, "<".$file) or die "Cannot open file '$file': $!\n";
	}
	while(<$in>){
		chomp($_);
		if (defined $skip && $_ =~ /^$skip/){
			push(@meta, $_);
		}
		elsif($_ ne ""){
			last;
		}
	}
	
	
	return \@meta;
}


# -----------------------------------------------
sub _split {
# -----------------------------------------------
	my ($str, $sep, $n_splits) = @_;
	
	chomp($str);
	
	
	if(defined $sep){
		if(looks_like_number($n_splits)){
			return split(/$sep/, $str, $n_splits);
		}
		else {
			return split(/$sep/, $str);
		}
	}
	else {
		return ($str);
	}
}


# -----------------------------------------------
sub _guess_seperator {
# -----------------------------------------------
	my ($file, $skip, $is_compressed) = @_;


	my $in;
	if($is_compressed){
		open($in, "<:gzip", "$file") or die "Cannot open file '$file': $!\n";
	}
	else {
		open($in, "<".$file) or die "Cannot open file '$file': $!\n";
	}
	while(<$in>){
		
		my $line = $_;
		
		chomp($line);
		
		if (defined $skip && $line =~ /^$skip/ || $line eq ""){}
		else {
			
			if ($line =~ /\t/){
				return '\t';
			}
			else {
				return '\s+';
			}
			
			last;
		}
	}

}


1;