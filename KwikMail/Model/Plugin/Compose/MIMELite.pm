package KwikMail::Model::Plugin::Compose::MIMELite;

use strict;
use warnings;
use MIME::Lite;
use KwikMail::Logger qw( DEBUG DUMP );

sub messages {
    my ( $self ) = @_;
    return {
        RECEIVES => {
            subject => {
                update => sub { $self->_receive_subject_update( @_ ) },
            },
        },
    };
}

sub new {
    my ( $class ) = @_;
    my $self = bless( {}, $class );
    return $self;
}

sub create_new_email {
    my ( $self ) = @_;
    push @{ $self->{_mails} }, MIME::Lite->new();
    $self->{_selected_mail} = $self->{_mails}->[-1];
    return $self;
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
