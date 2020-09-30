# Project info
project('com.github.coslyk.VideoSplitter', 'vala', 'c', version: '0.1')

conf_data = configuration_data()
conf_data.set('APP_ID', meson.project_name())
conf_data.set('VERSION', meson.project_version())


# Import vapi
add_project_arguments(['--vapidir', join_paths(meson.source_root(), 'vapi')], language: 'vala')


# Compile resource files
gnome = import('gnome')
videosplitter_gresources = gnome.compile_resources(
    'videosplitter_gresources', join_paths('data', meson.project_name() + '.gresource.xml'),
    source_dir: 'data'
)


# Translations
i18n = import('i18n')
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')


# Dependencies
videosplitter_deps = [
    dependency('epoxy'),
    dependency('gdk-wayland-3.0'),
    dependency('gdk-x11-3.0'),
    dependency('gio-2.0'),
    dependency('glib-2.0', version: '>=2.38'),
    dependency('gtk+-3.0'),
    dependency('json-glib-1.0'),
    dependency('mpv'),
    meson.get_compiler('c').find_library('m', required : true),
    meson.get_compiler('vala').find_library('posix', required : true)
]

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('meson/post_install.py')