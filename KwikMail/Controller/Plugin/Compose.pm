package KwikMail::Controller::Plugin::Compose;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG );

sub new {
    my ( $class, $conf ) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _init {
    my ( $self ) = @_;
    $self->{_mails} = [];
}

sub add_mail {
    my ( $self, $mail ) = @_;
    push @{ $self->{_mails} }, $mail;
}

sub get_mail_at_index {
    my ( $self, $idx ) = @_;
    return $self->{_mails}->[$idx];
}

sub delete_mail_at_index {
    my ( $self, $idx ) = @_;
}

sub create_new_mail {
}

1;
