#!/usr/bin/perl

use strict;
use warnings;
use lib qw( /Users/chris/lib );

use KwikMail::LocalStore::MBox;

my $HOME = "/Users/chris";
my $PROFILE = "lscs8yl5.default";
my $BASE = "$HOME/Library/Thunderbird/Profiles/$PROFILE/Mail/Local Folders";

my $mbox = KwikMail::LocalStore::MBox->new( {
    dir => $BASE,
} );

my @boxes = $mbox->search_for_box( qr(INBOX) );

print Data::Dumper::Dumper( \@boxes );
