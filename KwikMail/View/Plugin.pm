package KwikMail::View::Plugin;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG );

sub new {
    my ( $class, $view ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{_view} = $view;
    $self->_init();
    return $self;
}

sub _init {
    1;
}

sub view {
    my ( $self ) = @_;
    return $self->{_view};
}

sub send_message {
    my ( $self, $key, $action, $value ) = @_;
    my $map = $self->messages();
    if ( defined $map->{$key} ) {
        if ( defined $map->{$key}->{$action} ) {
            my $sub = $map->{$key}->{$action};
            $sub->( $value );
        }
        else {
            DEBUG( sprintf( 'could not find action "%s" for key "%s"', $action, $key ) );
        }
    }
    else {
        DEBUG( sprintf( 'could not find "%s"', $key ) );
    }
}

1;
