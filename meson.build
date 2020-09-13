# Project info
project('com.github.coslyk.VideoSplitter', 'vala', 'c', version: '0.1')


# Import vapi
add_project_arguments(['--vapidir', join_paths(meson.source_root(), 'vapi')], language: 'vala')


# Compile resource files
gnome = import('gnome')
asresources = gnome.compile_resources(
    'as-resources', join_paths('data', 'app.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)
add_project_arguments(['--gresourcesdir', join_paths(meson.source_root(), 'data')], language: 'vala')


# Create a new executable
executable(
    meson.project_name(),
    'src/SliceInfo.vala',
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/MpvController.vala',
    'src/Utils.vala',
    asresources,
    dependencies: [
        dependency('epoxy'),
        dependency('gdk-wayland-3.0'),
        dependency('gdk-x11-3.0'),
        dependency('gtk+-3.0'),
        dependency('mpv'),
        meson.get_compiler('c').find_library('m', required : true)
    ],
    install: true
)