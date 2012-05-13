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
    my ( $self, $id, $curses_id ) = @_;
    my $obj = $self->{_window_obj}->{$id};
    $self->{_window_obj_changed}->{$id}++;
    my $changed = $self->{_window_obj_changed}->{$id};
    DEBUG( "onchange handler fired $changed times for object: $id (curses id: $curses_id)" );
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
        if ( !exists $self->{_taborder_current}->{$focus} ) {
            $self->{_taborder_current}->{$focus} = 0;
        }
        else {
            $self->{_taborder_current}->{$focus}++;
            $self->{_taborder_current}->{$focus} = 0
                if scalar( @{ $taborder } ) <= $self->{_taborder_current}->{$focus};
        }

        # TODO: If the previous tabbed thing was changed, let the model know!
        my $prev_changed = $self->{_window_obj_changed}->{$focus};

        my $idx = $self->{_taborder_current}->{$focus};
        my $widget_focus = $self->{_taborder}->{$focus}->[$idx];
        DEBUG( "focusing widget at idx %s (%s)", $idx, $widget_focus );
        my $obj = $self->get_object( $widget_focus );
        $obj->focus();
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
        $self->load_menus( $plugin_obj );
        $self->load_shortcuts( $plugin_obj );
        $self->load_windows( $plugin_obj );
        $self->load_taborder( $plugin_obj );
    }
}

sub load_menus {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'menus' ) ) {
        $plugin_obj->menus( $self->{_menus} );
    }
}

sub load_shortcuts {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'shortcuts' ) ) {
        $plugin_obj->shortcuts( $self->{_shortcuts} );
    }
}

sub load_windows {
    my ( $self, $plugin_obj ) = @_;
    if ( $plugin_obj->can( 'windows' ) ) {
        $plugin_obj->windows( $self->{_windows} );
    }
}

sub load_taborder {
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
