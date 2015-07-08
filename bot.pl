#!/usr/bin/perl
use Digest::SHA qw/sha256_hex/;
use JSON;
use POSIX qw/floor/;
use List::Util qw/first/;
use POE;
use POE::Component::IRC;
use strict;

{ package Config; do 'config.pm' };

open CHAIN, 'chain.json';
my $chain = JSON->new->utf8->decode(<CHAIN>);
close CHAIN;

sub choice {
    my ($w, $n) = @_;
    my $l = @{$chain->{relations}->{$w}};
    my $i = floor($n * $l);
    return $chain->{relations}->{$w}->[$i];
}

sub indexOf {
    my ($v, $arr) = @_;

    my $index = first { $arr->[$_] eq $v } 0..$#{$arr};

    return $index;
}

sub calculate {
    my ($hashstr) = @_;

    # Start with a word after a period.
    my $w = indexOf('.', $chain->{wordlist});

    my $v = '';
    my $caps = 1;
    for (my $i = 0; $i < length($hashstr); $i += 2) {
        my $n = hex(substr($hashstr, $i, 2));
        my $wn = choice($w, $n / 256);
        my $word = $chain->{wordlist}->[$wn];
        if ($caps) {
            $word = ucfirst $word;
            $caps = 0;
        }
        if ($word =~ /[,.!?;:]/) {
            if ($word eq '.' || $word eq '!' || $word eq '?') {
                $caps = 1;
            }
        } else {
            $v .= ' ';
        }
        $v .= $word;
        $w = $wn;
    }

    $v =~ s/^ //;
    return $v . '.';
}

sub hash {
    my ($str) = @_;

    return calculate(sha256_hex($str));
}

my $irc = POE::Component::IRC->spawn;

POE::Session->create(
    inline_states => {
        _start => \&bot_start,
        irc_001 => \&on_connect,
        irc_public => \&on_public,
    }
);

sub bot_start {
    $irc->yield(register => 'all');
    $irc->yield(
        connect => {
            Nick => $Config::nick,
            Username => $Config::nick,
            Ircname => 'Down the Rabbit Hole',
            server => $Config::server,
            Port => $Config::port,
        }
    );
}

sub on_connect {
    for my $channel (@Config::channels) {
        $irc->yield(join => $channel);
    }
}

sub on_public {
    my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
    if ($msg =~ /^$Config::nick. (.+)/) {
        my $subject = $1;
        $irc->yield(privmsg => $where, hash($subject));
    }
}

$poe_kernel->run;
exit 0;
