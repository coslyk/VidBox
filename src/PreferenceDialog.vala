
[GtkTemplate (ui = "/com/github/coslyk/VideoSplitter/PreferenceDialog.ui")]
class VideoSplitter.PreferenceDialog : Gtk.Dialog {

    [GtkChild] Gtk.CheckButton dark_mode_button;
    [GtkChild] Gtk.CheckButton same_directory_button;
    [GtkChild] Gtk.FileChooserButton path_chooser_button;

    public PreferenceDialog (Gtk.Window window) {
        Object (
            transient_for: window,
            modal: true,
            destroy_with_parent: true
        );
    }

    construct {
        var settings = Application.settings;
        settings.bind ("dark-mode", dark_mode_button, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("use-input-directory", same_directory_button, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("use-input-directory", path_chooser_button, "sensitive", SettingsBindFlags.GET | SettingsBindFlags.INVERT_BOOLEAN);

        path_chooser_button.set_current_folder (settings.get_string ("output-directory"));
        path_chooser_button.selection_changed.connect (() => {
            settings.set_string ("output-directory", path_chooser_button.get_file ().get_path ());
        });
    }
}