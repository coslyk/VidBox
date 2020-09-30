
namespace VideoSplitter {

    public static int main (string[] args) {

        // Fix i18n in AppImage
        unowned string program_path = Utils.get_program_path ();
        if (program_path.has_suffix ("/bin/" + Build.APP_ID)) {
            string dirname = program_path.replace ("/bin/" + Build.APP_ID, "/share/locale");
            Intl.bindtextdomain (Build.APP_ID, dirname);
        }
        Intl.textdomain (Build.APP_ID);

        // Needed by mpv
        Environment.set_variable ("LC_NUMERIC", "C", true);
        Intl.setlocale (LocaleCategory.NUMERIC, "C");

        var app = new Application ();
        return app.run (args);
    }
}