
namespace VideoSplitter {
    public class Application : Gtk.Application {

        // Main Window
        private MainWindow main_window;

        public Application () {
            Object (
                application_id: "com.github.coslyk.VideoSplitter",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }
        
        protected override void activate () {
            this.main_window = new MainWindow (this);
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
