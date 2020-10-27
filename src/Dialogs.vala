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

namespace VideoSplitter.Dialogs {

    // Show message dialog
    public void message (Gtk.Window? parent, Gtk.MessageType type, string msg) {
        var dialog = new Gtk.MessageDialog (
            parent,
            Gtk.DialogFlags.DESTROY_WITH_PARENT,
            type,
            Gtk.ButtonsType.CLOSE,
            "%s", msg
        );
        dialog.run ();
        dialog.destroy ();
    }


    // Open single file
    public string? open_file (Gtk.Window? parent) {
        var dialog = new Gtk.FileChooserDialog (
            _("Open file"), parent, Gtk.FileChooserAction.OPEN,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            _("Open"), Gtk.ResponseType.ACCEPT
        );
        var result = dialog.run ();

        // File selected?
        if (result != Gtk.ResponseType.ACCEPT) {
            dialog.destroy ();
            return null;
        }
        
        string? filepath = dialog.get_filename ();
        dialog.destroy ();
        return filepath;
    }


    // Open multiple files
    public SList<string>? open_files (Gtk.Window? parent) {
        var dialog = new Gtk.FileChooserDialog (
            _("Open files"), parent, Gtk.FileChooserAction.OPEN,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            _("Open"), Gtk.ResponseType.ACCEPT
        );
        dialog.select_multiple = true;
        var result = dialog.run ();

        // File selected?
        if (result != Gtk.ResponseType.ACCEPT) {
            dialog.destroy ();
            return null;
        }
        
        var files = dialog.get_filenames ();
        dialog.destroy ();
        return files;
    }
}