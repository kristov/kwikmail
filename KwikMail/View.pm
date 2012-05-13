package KwikMail::View;

use strict;
use warnings;
use Curses::UI;
use KwikMail::Logger qw( DEBUG DUMP );
use Module::Pluggable search_path => 'KwikMail::View::Plugin', require => 1;

sub new {
    my ( $class, $conf ) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _init {
    my ( $self ) = @_;

    my $cui = Curses::UI->new( '-color_support' => 1, '-mouse_support' => 1 );
    $self->{_cui} = $cui;

    $self->load_plugins();
    $self->build_ui();
}

sub build_ui {
    my ( $self ) = @_;
    my $cui = $self->cui();

    DEBUG( 'Adding menu' );
    $self->{_menu_obj} = $cui->add(
        'menu'  => 'Menubar',
        '-menu' => $self->{_menus},
        '-fg'   => "blue",
    );

    $cui->set_binding( sub { $self->{_menu_obj}->focus() }, "\cX" );
    #$cui->set_binding( sub { $self->exit_dialog() }, "\cQ" );

    DEBUG( 'Adding Ctrl keys' );
    for my $ctrl_key ( @{ $self->{_shortcuts}->{'-ctrl_keys'} } ) {
        $cui->set_binding( $ctrl_key->{'-binding'}, $ctrl_key->{'-key'} );
    }

    DEBUG( 'Adding objects' );
    for my $object ( @{ $self->{_windows} } ) {
        $self->create_object( $cui, $object );
    }

    $self->{_has_focus}  = '::main::';
    $self->{_last_focus} = '::main::';

    DEBUG( 'done creating UI' );
}

sub create_object {
    my ( $self, $parent, $object ) = @_;

    my $id       = $object->{id};
    my $type     = $object->{type};
    my $ui_props = $object->{ui_props};

    $ui_props ||= {};
    $ui_props->{-onchange} = sub { $self->onchange_handler( $id, @_ ) };

    DEBUG( "Creating a '%s' with id '%s'", $type, $id );

    my $obj = $parent->add(
        $id => $type,
        %{ $ui_props },
    );

    if ( !$obj ) {
        DEBUG( "Could not create a new '%s' with id '%s' because '\$parent->add()' returned nothing", $type, $id );
    }

    $self->{_window_obj}->{$id} = $obj;

    if ( $object->{children} ) {
        for my $child_object ( @{ $object->{children} } ) {
            $self->create_object( $obj, $child_object );
        }
    }
}

sub onchange_handler {
    my ( $self, $id, $curses_obj ) = @_;
    $self->{_window_obj_changed}->{$id}++;

    if ( exists $self->{_messages_send}->{$id} ) {
        for my $key ( keys %{ $self->{_messages_send}->{$id} } ) {
            if ( exists $self->{_messages_send}->{$id}->{$key}->{onchange} ) {
                my $sub = $self->{_messages_send}->{$id}->{$key}->{onchange};
                if ( $sub ) {
                    DEBUG( 'widget "%s" was onchanged - calling "%s"', $id, $key );
                    my $value = $sub->( $curses_obj );
                }
            }
            else {
                DEBUG( 'widget "%s", key "%s" not configured for update', $id, $key );
            }
        }
    }
    else {
        DEBUG( 'widget "%s" not configured to send', $id );
    }
}

sub load_base {
    my ( $self ) = @_;

    # Basic exit menu - can be removed / hacked by plugins
    $self->{_menus} = [
        {
            '-label'   => 'File',
            '-submenu' => [
                {
                    '-label' => 'Exit     ^Q',
                    '-value' => sub { $self->exit_dialog() },
                },
            ],
        },
    ];

    # Basic keycombos
    $self->{_shortcuts} = {
        '-verbs' => [
            { '-key' => 'i', '-doc' => 'Insert' },
            { '-key' => 'd', '-doc' => 'Delete' },
        ],
        '-nouns' => [
            { '-key' => 'm', '-doc' => 'Mail' },
            { '-key' => 'f', '-doc' => 'Folder' },
        ],
        '-ctrl_keys' => [
            { '-key' => "\t",  '-binding' => sub { $self->do_tab_press() }, '-doc' => 'Process tab press' },
            { '-key' => "\cQ", '-binding' => sub { $self->exit_dialog() }, '-doc' => 'Quit' },
            { '-key' => "\cF", '-binding' => sub { $self->focus_object( '::main::' ) }, '-doc' => 'Quit (no prompt)' },
        ],
    };

    # Basic windows
    push @{ $self->{_windows} }, {
        id       => '::main::',
        type     => 'Window',
        ui_props => {
            -border => 1,
            -y      => 1,
            -bfg    => 'blue',
        },
    };

    $self->{_taborder} = {};
    $self->{_taborder_current} = {};
}

sub do_tab_press {
    my ( $self ) = @_;
    my $focus = $self->{_has_focus};
    DEBUG( "processing tab press on focus '%s'", $focus );

    if ( exists $self->{_taborder}->{$focus} ) {
        my $taborder = $self->{_taborder}->{$focus};
        my $prev_idx = 0;
        if ( !exists $self->{_taborder_current}->{$focus} ) {
            $self->{_taborder_current}->{$focus} = 0;
        }
        else {
            $prev_idx = $self->{_taborder_current}->{$focus};
            $self->{_taborder_current}->{$focus}++;
            $self->{_taborder_current}->{$focus} = 0
                if scalar( @{ $taborder } ) <= $self->{_taborder_current}->{$focus};
        }

        my $idx = $self->{_taborder_current}->{$focus};
        my $widget_focus = $self->{_taborder}->{$focus}->[$idx];

        my $prev_widget = $self->{_taborder}->{$focus}->[$prev_idx];
        $self->_process_changed_widget( $prev_widget );

        DEBUG( "focusing widget at idx %s (%s)", $idx, $widget_focus );
        my $obj = $self->get_object( $widget_focus );
        $obj->focus();
    }
}

sub _process_changed_widget {
    my ( $self, $id ) = @_;

    my $prev_changed = $self->{_window_obj_changed}->{$id};

    if ( $prev_changed ) {
        # The last widget focussed was changed
        if ( exists $self->{_messages_send}->{$id} ) {
            # The last widget is set up to send a message
            for my $key ( keys %{ $self->{_messages_send}->{$id} } ) {
                if ( exists $self->{_messages_send}->{$id}->{$key}->{update} ) {
                    my $sub = $self->{_messages_send}->{$id}->{$key}->{update};
                    if ( $sub ) {
                        DEBUG( 'widget "%s" was changed - sending "%s" update', $id, $key );
                        my $value = $sub->( $self->get_object( $id ) );
                        $self->model->send_message( $key, 'update', $value );
                    }
                }
                else {
                    DEBUG( 'widget "%s", key "%s" not configured for update', $id, $key );
                }
            }
        }
        else {
            DEBUG( 'widget "%s" not configured to send', $id );
        }
    }
}

sub focus_object {
    my ( $self, $id ) = @_;
    $self->{_last_focus} = $self->{_has_focus};
    if ( !$id ) {
        $id = $self->{_last_focus};
        DEBUG( "Using last focus" );
    }
    DEBUG( "Focus: '$id'" );
    $self->{_window_obj}->{$id}->focus();
    $self->{_has_focus} = $id;

    $self->do_first_tab_focus( $id );
}

sub do_first_tab_focus {
    my ( $self, $focus ) = @_;
    if ( exists $self->{_taborder}->{$focus} ) {
        $self->{_taborder_current}->{$focus} = 0;
        my $idx = $self->{_taborder_current}->{$focus};
        my $widget_focus = $self->{_taborder}->{$focus}->[$idx];
        DEBUG( "focusing widget at idx %s (%s)", $idx, $widget_focus );
        my $obj = $self->get_object( $widget_focus );
        $obj->focus();
    }
}

sub get_object {
    my ( $self, $id ) = @_;
    DEBUG( "Returning widget for '$id'" );
    return $self->{_window_obj}->{$id};
}

sub load_plugins {
    my ( $self ) = @_;

    # Load a base set of functionality for plugins to build on
    $self->load_base();

    my @plugins = $self->plugins();
    for my $plugin ( @plugins ) {
        DEBUG( "processing VIEW plugin: $plugin" );
        my $plugin_obj = $plugin->new( $self );
        $self->_load_messages( $plugin_obj );
        $self->_load_menus( $plugin_obj );
        $self->_load_shortcuts( $plugin_obj );
        $self->_load_windows( $plugin_obj );
        $self->_load_taborder( $plugin_obj );
    }
}

sub _load_messages {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'messages' ) ) {

        my $messages = $plugin_obj->messages();

        # Keys and their actions that are received by this plugin
        if ( exists $messages->{RECEIVES} ) {
            for my $key ( keys %{ $messages->{RECEIVES} } ) {
                for my $action ( keys %{ $messages->{RECEIVES}->{$key} } ) {
                    push @{ $self->{_messages_receive}->{$key}->{$action} }, $messages->{RECEIVES}->{$key}->{$action};
                    DEBUG( 'added RECEIVE message "%s" action for key "%s"', $action, $key );
                }
            }
        }

        # Widgets, keys and their actions that send (and how to get the value they send)
        if ( exists $messages->{SENDS} ) {
            for my $id ( keys %{ $messages->{SENDS} } ) {
                for my $key ( keys %{ $messages->{SENDS}->{$id} } ) {
                    for my $action ( keys %{ $messages->{SENDS}->{$id}->{$key} } ) {
                        $self->{_messages_send}->{$id}->{$key}->{$action} = $messages->{SENDS}->{$id}->{$key}->{$action};
                        DEBUG( 'added SEND message "%s" action for key "%s" for widget "%s"', $action, $key, $id );
                    }
                }
            }
        }
    }
}

sub _load_menus {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'menus' ) ) {
        $plugin_obj->menus( $self->{_menus} );
    }
}

sub _load_shortcuts {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'shortcuts' ) ) {
        $plugin_obj->shortcuts( $self->{_shortcuts} );
    }
}

sub _load_windows {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'windows' ) ) {
        $plugin_obj->windows( $self->{_windows} );
    }
}

sub _load_taborder {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'taborder' ) ) {
        $plugin_obj->taborder( $self->{_taborder} );
    }
}

sub menus {
    my ( $self, $menus ) = @_;
    $self->{_menus} = $menus if defined $menus;
    return $self->{_menus};
}

sub cui {
    my ( $self ) = @_;
    return $self->{_cui};
}

sub model {
    my ( $self, $model ) = @_;
    $self->{_model} = $model if defined $model;
    return $self->{_model};
}

sub run {
    my ( $self ) = @_;
    $self->{_cui}->mainloop();
}

sub exit_dialog {
    my ( $self ) = @_;

    my $return = $self->{_cui}->dialog(
        '-message'   => "Do you really want to quit?",
        '-title'     => "Are you sure?",
        '-buttons'   => ['yes', 'no'],
        '-bfg'       => 'blue',
    );

    exit(0) if $return;
}

1;
