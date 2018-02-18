package KwikMail::Model::Plugin::Server::IMAP;

use strict;
use warnings;
use Mail::IMAPClient;
use IO::Socket::SSL;
use KwikMail::Logger qw( DEBUG DUMP );

sub messages {
    my ( $self ) = @_;
    return {
        RECEIVES => {
            remote => {
                connect => sub { $self->_connect_remote( @_ ) },
            },
        },
    };
}

sub new {
    my ( $class ) = @_;
    my $self = bless( {}, $class );
    $self->_connect_remote();
    return $self;
}

sub create_new_email {
}

sub _connect_remote {
    my ( $self ) = @_;

    DEBUG( 'creating new SSL connection' );

    my $socket = IO::Socket::SSL->new(
        PeerAddr => 'imap.gmail.com',
        PeerPort => 993,
    ) or die "socket(): $@";

    # get rid of server greeting me
    my $greeting = <$socket>;
    my ( $id, $answer ) = split( /\s+/, $greeting );
    if ( $answer ne 'OK' ) {
        DEBUG( 'unable to connect to server: %s', $greeting );
        $self->{_connected} = 0;
    }

    # Build up a client attached to the SSL socket and login
    my $client = Mail::IMAPClient->new(
        Socket   => $socket,
        User     => 'youraccount',
        Password => 'yourpass',
    )
    or die "new(): $@";

    $client->State( Mail::IMAPClient::Connected() );
    $client->login() or die 'login(): ' . $client->LastError();

    # Do something just to see that it's all ok
    print "I'm authenticated\n" if $client->IsAuthenticated();
    my @folders = $client->folders();
    DEBUG( 'Folders: %s', join( ', ', @folders ) );
   
    # Say bye
    $client->logout();
}

sub subject {
    my ( $self, $subject ) = @_;
    my $set_subject = $self->_get_maybe_add_header( 'subject', 'Subject', $subject );
}

sub to {
    my ( $self, $to ) = @_;
    return $self->_get_maybe_add_header( 'to', 'To', $to );
}

sub _get_maybe_add_header {
    my ( $self, $key, $header, $value ) = @_;

    my $current_value = $self->{_selected_mail}->get( $header );

    if ( $value ) {
        $self->{_selected_mail}->add( $header, $value );

        if ( !$current_value || $value ne $current_value ) {
            $self->view->send_message( $key, 'update', $value );
        }

        $current_value = $value;
    }

    return $current_value;
}

sub _receive_subject_update {
    my ( $self, $value ) = @_;
    DEBUG( 'updating subject to "%s"', $value );
}

1;
