#!/usr/bin/perl
use JSON;
use Getopt::Long;
use strict;

my (%wordlist, @wordlist, %db, $js);

GetOptions(
	"js" => \$js,
);

my $lastword;
my $c = 0;

sub w_index {
    my $word = shift;
    if (!exists $wordlist{$word}) {
        $wordlist{$word} = $c++;
        push @wordlist, $word;
    }
    return $wordlist{$word};
}

while (<>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    s/--/ /g;
    s/['"()\][<>*&^@~]//g;
    my @words = split(/\s+/, $_);
    # Make punctuation its own "word"
    @words = map {
        /^([\w-]+)([,.!?;:])$/ ?
            ($1, $2) :
            $_;
    } @words;

    for my $w (@words) {
        my $wi = w_index(lc $w);
        if (not defined $lastword) {
            $lastword = $wi;
            next;
        }

        $db{$lastword} = []
            unless exists $db{$lastword};

        push @{$db{$lastword}}, $wi;

        $lastword = $wi;
    }
}

if ($js) {
	print "var chain = ";
}

print JSON->new->utf8->encode({wordlist => \@wordlist, relations => \%db});

if ($js) {
	print ";";
}

print "\n";
