package KwikMail::View::Plugin::Compose;

use strict;
use warnings;
use KwikMail::Logger qw( DEBUG DUMP );
use base qw( KwikMail::View::Plugin );

sub messages {
    my ( $self ) = @_;
    return {
        subject => {
            update => sub { $self->update_subject( @_ ) },
        }
    };
}

sub menus {
    my ( $self, $menus ) = @_;

    my $newmail = { -label => 'New mail', -value => sub { $self->newmail() } };

    MENU:
    for my $menu ( @{ $menus } ) {
        if ( $menu->{'-label'} eq 'File' ) {
            my $submenu = $menu->{'-submenu'} || [];
            my $new_submenu = [];
            my $exit_found = 0;
            for my $item ( @{ $submenu } ) {
                if ( $item->{'-label'} =~ /^Exit/ ) {
                    push @{ $new_submenu }, $newmail;
                    $exit_found = 1;
                }
                push @{ $new_submenu }, $item;
            }
            push @{ $new_submenu }, $newmail if !$exit_found;
            $menu->{'-submenu'} = $new_submenu;
        }
    }
}

sub shortcuts {
    my ( $self, $shortcuts ) = @_;
}

sub taborder {
    my ( $self, $taborder ) = @_;
    $taborder->{NewMail} = [ qw(
        NewMailList
        RecipientList
        SubjectLine
        MailBody
    ) ];
}

sub windows {
    my ( $self, $windows ) = @_;

    my $recipient_list = {
        id       => 'RecipientList',
        type     => 'Listbox',
        ui_props => {
            -bg       => 'magenta',
            -height   => 6,
            -values   => [],
        },
    };

    my $mail_window = {
        id       => 'BlankNewMail',
        type     => 'Window',
        ui_props => {
            -border => 0,
            -x      => 20,
            -height => 40,
        },
        children => [
            $recipient_list,
            {
                id       => 'SubjectLine',
                type     => 'TextEntry',
                message  => 'subject',
                ui_props => {
                    -bg => 'cyan',
                    -y  => 6,
                },
            },
            {
                id       => 'MailBody',
                type     => 'TextEditor',
                message  => 'body',
                ui_props => {
                    -bg => 'white',
                    -fg => 'black',
                    -y  => 7,
                },
            },
        ],
    };

    my $mail_list = {
        id   => 'NewMailList',
        type => 'Listbox',
        ui_props => {
            -width    => 20,
            -x        => 0,
            -y        => 1,
            -bg     => 'cyan',
            -values   => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 ],
            -labels   => {
                1 => '(no subject)',
                2 => '',
            },
        },
    };

    my $mail_list_window = {
        id   => 'NewMailListWindow',
        type => 'Window',
        ui_props => {
            -border => 0,
            -x      => 0,
            -width  => 20,
            -bg     => 'cyan',
        },
        children => [
            {
                id       => 'MailListLabel',
                type     => 'Label',
                ui_props => {
                    -border => 0,
                    -text   => 'In progress         ',
                    -bold   => 1,
                    -bg     => 'cyan',
                    -fg     => 'white',
                },
            },
            $mail_list,
        ],
    };

    my $main_mail_window = {
        id       => 'NewMail',
        type     => 'Window',
        ui_props => { -y => 1 },
        children => [ $mail_list_window, $mail_window ],
    };

    push @{ $windows }, $main_mail_window;
}

sub newmail {
    my ( $self ) = @_;
    my $mail = $self->view->focus_object( 'NewMail' );
}

1;
