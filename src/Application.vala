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

namespace VideoSplitter {
    public class Application : Gtk.Application {

        // Settings
        public static Settings settings;

        // Main Window
        private MainWindow main_window;

        public Application () {
            Object (
                application_id: Build.APP_ID,
                flags: ApplicationFlags.FLAGS_NONE
            );
        }
        
        protected override void activate () {

            // Init settings
            settings = new Settings (Build.APP_ID);
            settings.bind ("dark-mode", Gtk.Settings.get_default (), "gtk-application-prefer-dark-theme", SettingsBindFlags.GET);
            if (settings.get_string ("output-directory") == "") {
                settings.set_string ("output-directory", Environment.get_home_dir ());
            }

            this.main_window = new MainWindow (this);

            // Set menu
            var menu = new Menu ();
            menu.append (_("Preference"), "app.preference");
            menu.append (_("About"), "app.about");
            menu.append (_("Quit"), "app.quit");
            this.app_menu = menu;

            // Add actions
            var action = new SimpleAction ("about", null);
            action.activate.connect (() => {
                var about_dialog = new AboutDialog (main_window);
                about_dialog.present ();
            });
            add_action (action);

            action = new SimpleAction ("preference", null);
            action.activate.connect (() => {
                var dialog = new PreferenceDialog (main_window);
                dialog.present ();
            });
            add_action (action);

            action = new SimpleAction ("quit", null);
            action.activate.connect (this.quit);
            add_action (action);

            this.main_window.show ();
        }
    }
}
