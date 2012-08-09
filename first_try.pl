#!/usr/bin/env perl

# Just trying to implement a simple IRC
# bot over ii.

use strict;
use warnings;
use 5.010;
use IO::File;
use MediaWiki::API;
use Text::Match::FastAlternatives;


# Configuration
my $irc_dir = '/home/matael/irc';
my $host = 'irc.freenode.net';
my $chan = '#spi2011';
my $nick = 'teuse';

my $msg_presentation = "Salut, je m'appelle teuse. En fait, je suis sa petite soeur, teuse est morte. Elle était en Python et je suis en Perl ;)";

my $path = "$irc_dir/$host/$chan";
my $path_out = "$path/in"; 
my $path_in = "$path/out"; 

my $in=IO::File->new($path_in, "<")
    or die "Error opening in file : $!\n";

my @old_log = $in-> getlines;
undef @old_log;

my @seen;
push @seen, $nick;
my $line;

my @yops = qw(yop plop bouga salutations ahoy enchantier salut salutations! ahoy! enchantier! salut!);
my @meh = (
    'gné ?',
    'va chier !',
   'may be...',
   'et ta soeur !',
   "le poulet, c'est bon",
   'thx !',
   'youpi !',
   'pelle',
   'un chameau est un dromadaire presque partout'
   );

my @politics = (
    'sarkozy',
    'sarko',
    'melenchon',
    'hollande',
    'aubry',
    'réforme',
    'poutou',
    'NPA',
    'ump', # ps peut être utilisé pour post-scriptum
    'bayrou',
    'eva joly',
    'nathalie arthaud',
    'communiste',
    'capitaliste'
);

my $politics_re = join "|", @politics;
my %actions = (
    #qr/[^<]*<([^>]*)>.*/ => sub { say $1},
    qr/[^<]*<([^>]*)>[^$nick\s?:?].*\s((la|le|une?)\s+[^\s]*)\s?.*$/ => sub {
        my $str = $2;
        $str =~ s/une /la /;
        $str =~ s/un /le /;
        if (defined $1) { IRCsend("$1: c'est ta mère $str!"); }
        else {IRCsend("c'est ta mère $str!");}
    },

    # Politic must die
    $politics_re => sub { IRCsend(`python ./plugins/insulte.py`)},

    # A boire !
#    qr/[^<]*<([^>]*)>\s*$nick\s?:?\s*à?a? boire\s*!?$/ => sub { IRCsend($1." : ".`python ./plugins/choix_boisson.py`);},

    # Rappel Phrase
    qr/[^<]*<([^>]*)>\s*$nick\s?:?\s*retiens\s+(.*)$/ => sub { my $reponse = `./plugins/rappelPhrase.py souvenir $1 $2`; say $reponse; IRCsend($reponse);},
    qr/[^<]*<([^>]*)>\s*$nick\s?:?\s*(tell me more)\s*$/ => sub { IRCsend(" ".`python ./plugins/rappelPhrase.py rappel $1 $2`);},
    qr/[^<]*<([^>]*)>\s*$nick\s?:?\s*(oublie tout)\s*$/ => sub { IRCsend(" ".`python ./plugins/rappelPhrase.py oublis $1 $2`);},


    # Rot13
    qr/[^>]*$nick\s?:?\s*rot13 (.*)$/ => sub {
        my $msg = $1;
        $msg =~ s/\'/#/g;
        $msg = `echo $msg| tr 'A-Za-z' 'N-ZA-Mn-za-m'`;
        $msg =~ s/#/\'/g; IRCsend($msg);
    },

    # Reboot & Cie
	qr/[^<]*@?matael>\s*$nick:? casse toi.*/ => sub { $in->close(); exit 1;},
	qr/[^<]*@?matael>\s*$nick:? reboot now.*/ => sub { $in->close(); system("kill -9 $$; perl first_try.pl");},
    
    # Autres
    qr/[^>]*.*(yop?|bouga|morning|ahoy|plop)\s.*/ => sub { my $i = rand @yops; IRCsend($yops[$i]); },
    qr/[^>]*[^$nick\s*:?].*$nick.*/ => sub { my $i = rand @meh; IRCsend($meh[$i]); },
#   qr/[^>]*[^$nick\s*:?][^(?à boire|rot13)]*$nick [^(?à boire|rot13)]*/ => sub { my $i = rand @meh; IRCsend($meh[$i]); },
	qr/[^>]*$nick:?.* qui es tu.*/ => sub { IRCsend($msg_presentation);},
	qr/[^>]*.*cookie.*/ => sub { IRCsend('Owi ! \o/');},
	qr/[^>]*.*paste\s.*/ => sub { IRCsend('http://pastebin.archlinux.fr/');},
    qr/[^>]* \[Exo::([^\]]*)\].*/ => sub { IRCsend("Check http://exos.matael.org/?n=$1"); },
    qr/[^>]*.*\[~([^\/]*)\/([^\]]*)\].*/ => sub { IRCsend("Check http://matael.org/~$1/$2"); },
    qr/[^>]*.*pelle.*/ => sub { IRCsend("teuse");}

);

while (1){
    $line = $in->getline;
    if (defined $line and !($line =~ m/<$nick>/)) {
        foreach my $reg (keys %actions) {
            if ($line =~ $reg){
                $actions{$reg}->();
            }
        }
    }
    sleep(2);
}

# subroutine to send msgs
sub IRCsend {
    my ($message) = @_;
    my $out=IO::File->new($path_out, ">" )
        or die "Error opening out file : $!\n"; # /!\ we'll write here
    $out->print("$message\n");
    $out->close();
}


# vim: set ts=4 sw=4 et autoindent:
