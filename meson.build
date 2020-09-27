# Project info
project('com.github.coslyk.VideoSplitter', 'vala', 'c', version: '0.1')


# Import vapi
add_project_arguments(['--vapidir', join_paths(meson.source_root(), 'vapi')], language: 'vala')


# Compile resource files
gnome = import('gnome')
videosplitter_gresources = gnome.compile_resources(
    'videosplitter_gresources', join_paths('data', 'com.github.coslyk.VideoSplitter.gresource.xml'),
    source_dir: 'data'
)

# Dependencies
videosplitter_deps = [
    dependency('epoxy'),
    dependency('gdk-wayland-3.0'),
    dependency('gdk-x11-3.0'),
    dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    dependency('json-glib-1.0'),
    dependency('mpv'),
    meson.get_compiler('c').find_library('m', required : true)
]

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('src')