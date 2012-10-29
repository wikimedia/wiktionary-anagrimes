#!/usr/bin/perl -w

# Test the functions ascii etc.
use strict ;
use warnings ;
use Getopt::Std ;

use utf8 ;
use Encode qw(decode encode) ;
use open IO => ':utf8';
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

our %opt ;

#################################################
# Message about this program and how to use it
sub usage
{
	print STDERR "[ $_[0] ]\n" if $_[0] ;
	print STDERR << "EOF";
	
	This script parses a Wikimedia dump and extracts a list of words
	
	usage: $0 [-h] -f file
	
	-h        : this (help) message
	-i <path> : dump path. Can be in xml, xml.gz, xml.bz2
	-o <path> : list of all the words
	-n <path> : list of words not to list
	
	-L <num>  : maximum number of articles to parse
	
	example: $0 -i data/frwikt.xml
EOF
	exit ;
}

##################################
# Command line options processing
sub init()
{
	getopts( 'hi:o:n:L:', \%opt ) or usage() ;
	usage() if $opt{h} ;
	usage( "Dump path needed (-i)" ) if not $opt{i} ;
	
	if ($opt{o}) {
		open(LIST, "> $opt{o}") or die "Couldn't write $opt{o}: $!\n" ;
		close(LIST) ;
	}
}

###################################
sub get_list
{
	my ($input) = @_;
	my %list = ();
	return \%list if not -s $input;
	
	open(LIST, $input) or die "Couldn't open '$input': $!\n";
	while(<LIST>) {
		chomp;
		my $word = split(/\t/, $_);
		$list{$word}++ if $word;
	}
	close(LIST);
	return \%list;
}

sub words
{
	my ($article, $dico, $nolist) = @_ ;
	my $count = 0;
	foreach my $line (@$article) {
		# Split the article in words
		
		# Clean first
		$line =~ s/\{\{[^\}]+\}\}//g;	# No templates
		$line =~ s/\[\[[^\]]+\]\]//g;	# No links
		$line =~ s/\{\|.+$//g;			# No tables
		$line =~ s/^ *\|.+$//;			# No tables
		$line =~ s/<[^>]+>//g;			# No html anchors
		$line =~ s/[\.…,\(\)"«»]//g;	# No punctuation or special chars
		
		#$line =~ s/[\r\n\s\t]+/ /g;
		
		# Split into words
		my @parts = split(/[\s\r\n\t]+/, $line);
		
		foreach my $part (@parts) {
			#next if $line =~ /[;:\?!€\$\*\{\}\[\]=\+0-9\p{Block=Box_drawing}]/;	# No punctuation or special chars
			#next if $part =~ /[&# '_~\/\\\|]|-+/;	# Special words
			#next if length($part) < 2;	# More than 1 letters please
			next if $part =~ /\P{Latin}/;
			next if $nolist->{$part};
			$dico->{$part}++;
			$count++;
		}
	}
	return $count;
}

###################
# MAIN
init() ;

# Connect
# Open file (compressed or not)
my $input = '';
if ($opt{i} =~ /\.bz2$/) {
	$input = "bzcat $opt{i} |";
} elsif ($opt{i} =~ /\.gz$/) {
	$input = "gunzip -c $opt{i} |";
} elsif ($opt{i} =~ /\.7z$/) {
	$input = "7z x -so $opt{i} 2>/dev/null |";
} elsif ($opt{i} =~ /\.xml$/) {
	$input = $opt{i};
} else {
	print STDERR "Error: unsupported file format or compression: $opt{i}\n";
	exit(1);
}
open(DUMP, $input) or die "Couldn't open '$input': $!\n" ;
my $title = '' ;
my ($n, $word_count, $redirect) = (0,0,0) ;
my $complete_article = 0 ;
my @article = () ;
my $dico = {};

# Get list of words not to list
my $nolist = get_list($opt{n});

# Get author type list
$|=1;
while(<DUMP>) {
	if ( /<title>(.+?)<\/title>/ ) {
		$title = $1 ;
		# Exclut toutes les pages en dehors de l'espace principal
		$title = '' if $title =~ /[:\/]/ ;
		
	} elsif ( $title and /<text xml:space="preserve">(.*?)<\/text>/ ) {
		@article = () ;
		push @article, "$1\n" ;
		$complete_article = 1 ;
		
		} elsif ( $title and  /<text xml:space="preserve">(.*?)$/ ) {
		@article = () ;
		push @article, "$1\n" ;
		while ( <DUMP> ) {
			next if /^\s+$/ ;
			if ( /^(.*?)<\/text>/ ) {
				push @article, "$1\n" ;
				last ;
			} else {
				push @article, $_ ;
			}
		}
		$complete_article = 1 ;
	}
	if ($complete_article) {
		if ($article[0] =~ /#redirect/i) {
			$redirect++;
		} else {
			######################################
			# Traiter les articles ici
			$word_count += words(\@article, $dico, $nolist) ;
			
			######################################
			$n++ ;
			if ($n % 100 == 0) {
				my $total_words = keys %$dico;
				print STDERR sprintf("[%d] [%d]   %s                                                         \r", $n, $total_words, $title);
			}
			last if $opt{L} and $n >= $opt{L};
		}
		$complete_article = 0 ;
	}
}
print STDERR "\n";
$|=0;
close(DUMP) ;

print STDERR "Total = $word_count words in $n articles\n" ;
print STDERR "Total_redirects = $redirect\n" ;

# Print the ordered list of words
if ($opt{o}) {
	open(LIST, "> $opt{o}") or die "Couldn't write $opt{o}: $!\n" ;
	foreach my $word (sort {$dico->{$b} <=> $dico->{$a}} keys %$dico) {
		next if not $word;
		print LIST "$word\t$dico->{$word}\n";
	}
	close(LIST) ;
}

__END__
