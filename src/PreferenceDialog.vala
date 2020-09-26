
[GtkTemplate (ui = "/com/github/coslyk/VideoSplitter/PreferenceDialog.ui")]
class VideoSplitter.PreferenceDialog : Gtk.Dialog {

    public PreferenceDialog (Gtk.Window window) {
        Object (
            transient_for: window,
            modal: true,
            destroy_with_parent: true
        );
    }
}