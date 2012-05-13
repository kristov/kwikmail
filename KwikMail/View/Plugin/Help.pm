package KwikMail::View::Plugin::Help;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG );
use base qw( KwikMail::View::Plugin );

sub menus {
    my ( $self, $menus ) = @_;

    my $help_menu = [
        { '-label' => 'Manual  ', '-value' => sub { $self->manual() } },
        { '-label' => 'About   ', '-value' => sub { $self->about() } },
    ];

    push @{ $menus }, { '-label' => 'Help', '-submenu' => $help_menu };
}

sub shortcuts {
    my ( $self, $shortcuts ) = @_;
    my $key = { '-key' => "\cE", '-binding' => sub { $self->view->focus_object() }, '-doc' => 'Exit manual' };
    push @{ $shortcuts->{'-ctrl_keys'} }, $key;
}

sub windows {
    my ( $self, $windows ) = @_;
    push @{ $windows }, {
        id        => 'Manual',
        type      => 'Window',
        ui_props  => {
            -border => 1,
            -y      => 1,
            -bfg    => 'blue',
        },
        children  => [
            {
                id       => 'foo',
                type     => 'Label',
                ui_props => {
                    -x    => 15,
                    -y    => 6,
                    -text => "Page #2.",
                },
            },
        ],
    };
}

sub manual {
    my ( $self ) = @_;
    my $cui = $self->view->cui;
    $self->view->focus_object( 'Manual' );
}

sub about {
}

1;
