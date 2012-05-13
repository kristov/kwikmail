package KwikMail::Model;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG DUMP );
use Module::Pluggable search_path => 'KwikMail::Model::Plugin', require => 1;

sub new {
    my ( $class, $conf ) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _init {
    my ( $self ) = @_;
    $self->load_plugins();
}

sub load_plugins {
    my ( $self ) = @_;

    my @plugins = $self->plugins();
    for my $plugin ( @plugins ) {
        DEBUG( "processing MODEL plugin: $plugin" );
        my $plugin_obj = $plugin->new( $self );
        $self->load_messages( $plugin_obj );
        $self->{_plugins}->{$plugin} = $plugin_obj;
    }
}

sub load_messages {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'messages' ) ) {
        my $messages = $plugin_obj->messages();
        for my $key ( keys %{ $messages } ) {
            for my $action ( keys %{ $messages->{$key} } ) {
                push @{ $self->{_messages}->{$key}->{$action} }, $messages->{$key}->{$action};
            }
        }
    }
}

sub send_message {
    my ( $self, $key, $action, $value ) = @_;
    my $map = $self->messages();
    if ( defined $map->{$key} ) {
        if ( defined $map->{$key}->{$action} ) {
            my $widgets = $map->{$key}->{$action};
            for my $widget_callback ( @{ $widgets } ) {
                $widget_callback->( $value );
            }
        }
        else {
            DEBUG( sprintf( 'could not find action "%s" for key "%s"', $action, $key ) );
        }
    }
    else {
        DEBUG( sprintf( 'no model items set up to receive message for key "%s"', $key ) );
    }
}

sub main_view {
    my ( $self, $view ) = @_;
    if ( $view ) {
        $self->{_main_view} = $view;
    }
    return $self->{_main_view};
}

sub messages {
    my ( $self ) = @_;
    return $self->{_messages};
}

sub view {
    my ( $self, $class ) = @_;
    if ( exists $self->{_plugins}->{$class} ) {
        return $self->{_plugins}->{$class};
    }
    return undef;
}

1;
