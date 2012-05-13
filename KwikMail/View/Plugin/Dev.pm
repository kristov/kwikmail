package KwikMail::View::Plugin::Dev;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG );
use base qw( KwikMail::View::Plugin );

sub menus {
    my ( $self, $menus ) = @_;

    my $dev_menu = [
        { '-label' => 'View log', '-value' => sub { $self->log_view() } },
    ];

    # Add before the Help menu
    my $found = 0;
    my $new_menu = [];
    for my $menu ( @{ $menus } ) {
        if ( $menu->{'-label'} eq 'Help' ) {
            push @{ $new_menu }, { '-label' => 'Dev', '-submenu' => $dev_menu };
            $found = 1;
        }
        push @{ $new_menu }, $menu;
    }

    # Add it on the end if there is no Help menu
    push @{ $new_menu }, { '-label' => 'Dev', '-submenu' => $dev_menu } if !$found;

    $self->view->menus( $new_menu );
}

sub shortcuts {
    my ( $self, $shortcuts ) = @_;
}

sub windows {
    my ( $self, $windows ) = @_;
    push @{ $windows }, {
        id        => 'Log',
        type      => 'Window',
        ui_props  => {
            -border => 1,
            -y      => 1,
            -bfg    => 'blue',
        },
        children  => [
            {
                id       => 'LogView',
                type     => 'TextEditor',
                ui_props => {
                    -text => "Loading log file...",
                    -vscrollbar => 1,
                    -wrapping   => 0,
                    -readonly   => 1,
                },
            },
        ],
    };
}

sub log_view {
    my ( $self ) = @_;
    my $cui = $self->view->cui;
    $self->view->focus_object( 'LogView' );
    my $texted = $self->view->get_object( 'LogView' );
    my @lines = KwikMail::Logger->get_log_lines();
    $texted->text( join( "\n", @lines ) );
    $texted->draw();
}

sub about {
}

1;
