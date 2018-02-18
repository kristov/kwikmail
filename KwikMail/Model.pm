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
    $self->_load_plugins();
}

sub _load_plugins {
    my ( $self ) = @_;

    my @plugins = $self->plugins();
    for my $plugin ( @plugins ) {
        DEBUG( "processing MODEL plugin: $plugin" );
        my $plugin_obj = $plugin->new( $self );
        $self->_load_messages( $plugin_obj );
        $self->{_plugins}->{$plugin} = $plugin_obj;
    }
}

sub _load_messages {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'messages' ) ) {

        my $messages = $plugin_obj->messages();

        if ( exists $messages->{RECEIVES} ) {
            for my $key ( keys %{ $messages->{RECEIVES} } ) {
                for my $action ( keys %{ $messages->{RECEIVES}->{$key} } ) {
                    push @{ $self->{_messages_receive}->{$key}->{$action} }, $messages->{RECEIVES}->{$key}->{$action};
                    DEBUG( 'added RECEIVE message "%s" action for key "%s"', $action, $key );
                }
            }
        }

        if ( exists $messages->{SENDS} ) {
            for my $key ( keys %{ $messages->{SENDS} } ) {
                for my $action ( keys %{ $messages->{SENDS}->{$key} } ) {
                    $self->{_messages_send}->{$key}->{$action} = $messages->{SENDS}->{$key}->{$action};
                    DEBUG( 'added SEND message "%s" action for key "%s"', $action, $key );
                }
            }
        }
    }
}

sub receive_message {
    my ( $self, $key, $action, $value ) = @_;
    DEBUG( 'received a message - key: "%s", action: "%s"', $key, $action );
    my $messages = $self->{_messages_receive};

    if ( defined $messages->{$key} ) {
        if ( defined $messages->{$key}->{$action} ) {
            my $widgets = $messages->{$key}->{$action};
            for my $widget_callback ( @{ $widgets } ) {
                $widget_callback->( $value );
            }
        }
        else {
            DEBUG( 'could not find action "%s" for key "%s"', $action, $key );
        }
    }
    else {
        DEBUG( 'no model items set up to receive message for key "%s"', $key );
    }
}

sub main_view {
    my ( $self, $view ) = @_;
    if ( $view ) {
        $self->{_main_view} = $view;
    }
    return $self->{_main_view};
}

sub view {
    my ( $self, $class ) = @_;
    if ( exists $self->{_plugins}->{$class} ) {
        return $self->{_plugins}->{$class};
    }
    return undef;
}

1;
