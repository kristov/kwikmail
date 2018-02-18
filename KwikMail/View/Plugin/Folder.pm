package KwikMail::View::Plugin::Folder;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG );
use base qw( KwikMail::View::Plugin );

sub menus {
    my ( $self, $menus ) = @_;

    my $folder_menu = [
        { -label => 'Show', -value => sub { $self->folderview() } },
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

    my $folder_list = {
        id   => 'FolderList',
        type => 'Listbox',
        ui_props => {
            -width    => 20,
            -x        => 0,
            -y        => 1,
            -bg     => 'cyan',
            -values => [ 0, 1, 2 ],
            -labels => {
                0 => 'inbox',
                1 => 'drafts',
                2 => 'deleted',
            },
        },
    };

    my $folder_list_window = {
        id   => 'FolderListWindow',
        type => 'Window',
        ui_props => {
            -border => 0,
            -x      => 0,
            -width  => 20,
            -bg     => 'cyan',
        },
        children => [
            {
                id       => 'FolderListLabel',
                type     => 'Label',
                ui_props => {
                    -border => 0,
                    -text   => 'Folders             ',
                    -bold   => 1,
                    -bg     => 'cyan',
                    -fg     => 'white',
                },
            },
            $folder_list,
        ],
    };

    my $folder_window = {
        id       => 'Folders',
        type     => 'Window',
        ui_props => { -y => 1 },
        children => [ $folder_list_window ],
    };

    push @{ $windows }, $folder_window;
}

sub folderview {
    my ( $self ) = @_;
    $self->view->focus_object( 'Folders' );
}

1;
