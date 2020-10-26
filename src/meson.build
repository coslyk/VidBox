
videosplitter_srcs = [
    'AboutDialog.vala',
    'Application.vala',
    'Dialogs.vala',
    'Ffmpeg.vala',
    'MainWindow.vala',
    'Merger.vala',
    'MpvController.vala',
    'PreferenceDialog.vala',
    'SplitterItem.vala',
    'Splitter.vala',
    'Utils.vala',
    'main.vala'
]

config_file = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

# Create a new executable
executable(
    meson.project_name(),
    videosplitter_srcs,
    videosplitter_gresources,
    config_file,
    dependencies: videosplitter_deps,
    install: true
)