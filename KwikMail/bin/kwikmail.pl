#!/usr/bin/perl -w

use strict;
use warnings;

use KwikMail::Controller;

my $HOME = "/Users/chris";
my $PROFILE = "lscs8yl5.default";
my $BASE = "$HOME/Library/Thunderbird/Profiles/$PROFILE/Mail/Local Folders";

my $app = KwikMail::Controller->new();
$app->run();
