package KwikMail::Model::Plugin::Compose::MIMELite;

use strict;
use warnings;
use MIME::Lite;

sub messages {
    my ( $self ) = @_;
    return {
        subject => {
            update => sub { $self->update_subject( @_ ) },
        }
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
    my $set_subject = $self->_get_maybe_add_header( 'Subject', $subject );
}

sub to {
    my ( $self, $to ) = @_;
    return $self->_get_maybe_add_header( 'To', $to );
}

sub _get_maybe_add_header {
    my ( $self, $key, $value ) = @_;

    my $current_value = $self->{_selected_mail}->get( $key );

    if ( $value ) {
        $self->{_selected_mail}->add( $key, $value );

        if ( !$current_value || $value ne $current_value ) {
            $self->view( 'KwikMail::View::Plugin::Compose' )->send_message( $key, 'changed', $value );
        }

        $current_value = $value;
    }

    return $current_value;
}

1;
