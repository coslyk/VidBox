
namespace VideoSplitter {
    public class Application : Gtk.Application {

        // Settings
        public static Settings settings;

        // Main Window
        private MainWindow main_window;

        public Application () {
            Object (
                application_id: "com.github.coslyk.VideoSplitter",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }
        
        protected override void activate () {

            // Init settings
            settings = new Settings ("com.github.coslyk.VideoSplitter");
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
        
        public static int main (string[] args) {

            // Needed by mpv
            Environment.set_variable ("LC_NUMERIC", "C", true);
            Intl.setlocale (LocaleCategory.NUMERIC, "C");

            var app = new Application ();
            return app.run (args);
        }
    }
}
