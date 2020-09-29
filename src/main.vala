
namespace VideoSplitter {

    public static int main (string[] args) {

        // Fix i18n in AppImage
        unowned string program_path = Utils.get_program_path ();
        if (program_path.has_suffix ("/bin/com.github.coslyk.VideoSplitter")) {
            string dirname = program_path.replace ("/bin/com.github.coslyk.VideoSplitter", "/share/locale");
            Intl.bindtextdomain ("com.github.coslyk.VideoSplitter", dirname);
        }
        Intl.textdomain ("com.github.coslyk.VideoSplitter");

        // Needed by mpv
        Environment.set_variable ("LC_NUMERIC", "C", true);
        Intl.setlocale (LocaleCategory.NUMERIC, "C");

        var app = new Application ();
        return app.run (args);
    }
}