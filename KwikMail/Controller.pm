package KwikMail::Controller;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG DUMP );
use Module::Pluggable search_path => 'KwikMail::Controller::Plugin', require => 1;

use KwikMail::View;
use KwikMail::Model;

sub new {
    my ( $class, $conf ) = @_;
    DEBUG( '---------------- START ----------------' );
    my $self = {};
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _init {
    my ( $self ) = @_;

    DEBUG( 'Installing die handler' );
    $SIG{__DIE__} = sub {
        DEBUG( 'DIE: %s', $_[0] );
    };

    $self->load_plugins();

    DEBUG( 'Creating View' );
    $self->{_view} = KwikMail::View->new();

    DEBUG( 'Creating Model' );
    $self->{_model} = KwikMail::Model->new();

    # Let the model know the view
    $self->model->view( $self->{_view} );

    # Let the view know the model. Note: this deviates from MVC - see notes
    $self->view->model( $self->{_model} );
}

sub load_plugins {
    my ( $self ) = @_;

    my @plugins = $self->plugins();
    for my $plugin ( @plugins ) {
        DEBUG( "processing CONTROLLER plugin: $plugin" );
        my $plugin_obj = $plugin->new( $self );
    }
}

sub view {
    my ( $self ) = @_;
    return $self->{_view};
}

sub model {
    my ( $self ) = @_;
    return $self->{_model};
}

sub run {
    my ( $self ) = @_;
    DEBUG( 'Running View' );
    $self->{_view}->run();
}

1;
