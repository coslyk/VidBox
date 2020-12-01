/* Copyright 2020 Yikun Liu <cos.lyk@gmail.com>
 *
 * This program is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see http://www.gnu.org/licenses/.
 */

[GtkTemplate (ui = "/com/github/coslyk/VidBox/PreferenceDialog.ui")]
class VidBox.PreferenceDialog : Gtk.Dialog {

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
            Application.settings.set_string ("output-directory", path_chooser_button.get_file ().get_path ());
        });
    }
}