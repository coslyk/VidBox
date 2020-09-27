
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

            settings = new Settings ("com.github.coslyk.VideoSplitter");
            this.main_window = new MainWindow (this);

            // Set menu
            var menu = new Menu ();
            menu.append ("Preference", "app.preference");
            menu.append ("About", "app.about");
            menu.append ("Quit", "app.quit");
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
