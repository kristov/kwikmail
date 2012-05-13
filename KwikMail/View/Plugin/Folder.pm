package KwikMail::View::Plugin::Folder;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG );
use base qw( KwikMail::View::Plugin );

sub menus {
    my ( $self, $menus ) = @_;

    my $folder_menu = [
        { '-label' => 'Exit', '-value' => sub { $self->exit_dialog() } },
    ];

    my $new_menu = [];
    for my $menu_item ( @{ $menus } ) {
        push @{ $new_menu }, $menu_item;
        if ( $menu_item->{'-label'} eq 'File' ) {
            push @{ $new_menu }, { '-label' => 'Folder', '-submenu' => $folder_menu };
        }
    }

    $self->view->menus( $new_menu );
}

sub shortcuts {
    my ( $self, $shortcuts ) = @_;
}

sub windows {
    my ( $self, $windows ) = @_;
}

1;
