package KwikMail::Logger;

use strict;
use warnings;
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    DEBUG
    DUMP
);
use POSIX qw( strftime );
use Data::Dumper;

my @LOGLINES = ();
my $LOGFILE = './kwikmail.log';
my $LOGFH   = undef;

sub DEBUG {
    my ( $message, @args ) = @_;
    LOG( 'DEBUG', $message, @args );
}

sub LOG {
    my ( $type, $message, @args ) = @_;
    my $sprintf_str = "[%s] %s -- $message";
    my $datetime = strftime( '%Y-%m-%d %H:%M:%S', localtime() );
    my $string = sprintf( $sprintf_str, $type, $datetime, @args );
    open_log() if !defined $LOGFH;
    print $LOGFH "$string\n";
    push @LOGLINES, $string;
}

sub DUMP {
    my ( $data ) = @_;
    my $dump = Data::Dumper->new( [ $data ], [ 'thing' ] )->Indent( 1 )->Dump();

    LOG( 'DUMP ', $dump );
}

sub open_log {
    open( $LOGFH, '>', $LOGFILE ) || die "Could not open log \"$LOGFILE\" for writing: $!";
}

sub close_log {
    close $LOGFH;
}

sub get_log_lines {
    return @LOGLINES;
}

sub END {
    DEBUG( '----------------- END -----------------' );
    close_log();
}

1;
