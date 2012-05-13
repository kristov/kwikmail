package KwikMail::LocalStore::MBox;

use strict;
use warnings;

use Data::Dumper;
use File::Find;
use Mail::MboxParser;
use Mail::MboxParser::Mail;

my %month_to_num;
my $BASE = "";
my $DATABASE = "";

sub new {
    my ( $class, $conf ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{dir} = escape_spaces( $conf->{dir} );
    $self->_init();
    return $self;
}

sub _init {
    my ( $self ) = @_;
    my @files = ();
    find( sub { push @files, $File::Find::name; }, $self->{dir} );
    $self->{_files} = [ grep { $_ !~ /\.sbd$/ and $_ !~ /\.msf$/ } @files ];
}

sub search_for_box {
    my ( $self, $regex ) = @_;
    my @searched = grep $_ =~ $regex, @{ $self->{_files} };
    return @searched;
}

sub parse_boxes {
    my @boxes;
    parse_box( $_, 'from' ) foreach @boxes;
}

sub parse_box {
    my ( $mbox, $from_to ) = @_;

    print STDERR "$mbox\n";
    my $name = ( $from_to eq 'from' ) ? 'RECEIVED' : 'SENT';

    my $parseropts = { enable_grep => 1 };
    my $mb = Mail::MboxParser->new(
        $mbox,
        decode     => 'BODY',
        newline    => 'UNIX',
        parseropts => $parseropts,
    );

    my $data = {};
    my $count = 0;
    while (my $msg = $mb->next_message) {
        my $header = $msg->header;

        # get some data
        my $date    = parse_date( $header->{date} );
        my $subject = $header->{subject};
        my $from    = $header->{$from_to};

        my $body_idx = $msg->find_body;
        my $body_obj = $msg->body( $body_idx );
        my $body     = $body_obj->as_string;

        # detect no dates
        print "NODATE: " . $header->{date} if !$date;

        # create a sample of the body
        my $sample = substr( $body, 0, 500 );

        push @{ $data->{$date} }, [ $from, $subject, $sample ];
        print "processing $count in folder          \r";
        $count++;
    }

    foreach my $date ( sort keys %{ $data } ) {
        dump_email( $date, $name, $data->{$date} );
    }
}

sub dump_email {
    my ( $date, $name, $data ) = @_;

    my ( $weekday, $weekend, $special ) = ( 0, 0, 0 );

    my $fh;
    my $datedir = "$DATABASE/$date";

    my @dirs = glob( "$datedir*" );
    return if !@dirs;

    my $dir = $dirs[0];

    if ( $dir =~ /weekend/ ) {
        $weekend++;
    }
    elsif ( $dir =~ /^\d{4}-\d{2}-\d{2}-\S+/ ) {
        $special++;
    }
    else {
        $weekday++;
    }

    #printf( "appended %4d emails %d %d %d\n", scalar( @{ $data } ), $weekend, $weekday, $special );

    print "writing to $dir/$name\n";

    open( $fh, '>>', "$dir/$name" ) || die "could not open file: $dir/$name - $!\n";
    foreach my $email ( @{ $data } ) {
        print $fh "-------------------------------------------------------\n";
        print $fh "| " . sprintf( "%20s", $email->[0] ) . " | " . sprintf( "%20s |\n", $email->[1] );
        print $fh "-------------------------------------------------------\n";
        print $fh $email->[2] . "\n\n";
    }
    close $fh;
}

sub parse_date {
    my ( $date ) = @_;

    %month_to_num = months_to_nums() if !%month_to_num;

    if ( $date =~ /^([a-zA-Z]+,\s+)?(\d+)\s+([a-zA-Z]+)\s+(\d+)\s+([\d:\-]+)/ ) {
        my ( $dname, $day, $mname, $year, $time ) = ( $1, $2, $3, $4, $5 );
        my $month  = sprintf( "%02d", $month_to_num{$mname} );
        my $daytwo = sprintf( "%02d", $day );
        return "$year-$month-$daytwo";
    }

    return;
}

sub escape_spaces {
    my ( $text ) = @_;
    $text =~ tr/ /\ /;
    return $text;
}

sub months_to_nums {
    return qw(
        Jan 1
        Feb 2
        Mar 3
        Apr 4
        May 5
        Jun 6
        Jul 7
        Aug 8
        Sep 9
        Oct 10
        Nov 11
        Dec 12
    );
}

1;
