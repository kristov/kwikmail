#!/usr/bin/perl

use strict;
use warnings;

use KwikMail::View;
use KwikMail::View::Widget;

my $view = KwikMail::View->new();
my $menu = KwikMail::View::Widget->new( $view );
$view->run();
