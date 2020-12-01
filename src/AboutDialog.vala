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

class VidBox.AboutDialog : Gtk.AboutDialog {

    public AboutDialog (Gtk.Window window) {
        
        Object (
            transient_for: window,
            modal: true,
            destroy_with_parent: true,
            program_name: "VidBox",
            version: Build.VERSION,
            comments: _("A tiny video toolbox"),
            website: "https://coslyk.github.io/vidbox.html",
            website_label: _("Homepage"),
            copyright: "Copyright © 2020 coslyk",
            authors: new (unowned string)[] {"coslyk"},
            license_type: Gtk.License.GPL_3_0
        );
    }
    
    construct {
        try {
            logo = new Gdk.Pixbuf.from_resource ("/com/github/coslyk/VidBox/logo.png");
        } catch (Error e) {
            warning ("%s", e.message);
        }
    }
}