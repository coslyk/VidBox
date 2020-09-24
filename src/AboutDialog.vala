
class VideoSplitter.AboutDialog : Gtk.AboutDialog {

    public AboutDialog (Gtk.Window window) {
        
        Object (
            transient_for: window,
            modal: true,
            destroy_with_parent: true,
            program_name: "VideoSplitter",
            version: "0.1",
            comments: "A simple tool to split videos",
            website: "https://coslyk.github.io/videosplitter.html",
            website_label: "Homepage",
            copyright: "Copyright © 2020 coslyk",
            authors: new (unowned string)[] {"coslyk"},
            license_type: Gtk.License.GPL_3_0
        );
    }
    
    construct {
        try {
            logo = new Gdk.Pixbuf.from_resource ("/com/github/coslyk/VideoSplitter/logo.png");
        } catch (Error e) {
            warning ("%s", e.message);
        }
    }
}