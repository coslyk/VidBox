
[GtkTemplate (ui = "/com/github/coslyk/VideoSplitter/MainWindow.ui")]
public class VideoSplitter.MainWindow : Gtk.ApplicationWindow {

    private MpvController mpv;
    private SliceInfo? current_slice;
    [GtkChild] private Gtk.GLArea video_area;
    [GtkChild] private Gtk.DrawingArea progress_bar;
    [GtkChild] private Gtk.Label start_pos_label;
    [GtkChild] private Gtk.Label end_pos_label;
    [GtkChild] private Gtk.HeaderBar header_bar;
        

    public MainWindow(Gtk.Application application) {
        Object (application: application);
    }

    construct {
        mpv = new MpvController (video_area);

        mpv.notify["playback-time"].connect (() => {
            progress_bar.queue_draw ();
        });

        mpv.notify["duration"].connect (() => {
            current_slice = new SliceInfo (mpv.filename, mpv.duration);
            progress_bar.queue_draw ();
            start_pos_label.label = Utils.time2str (0);
            end_pos_label.label = Utils.time2str (mpv.duration);
        });
    }


    // Open file
    [GtkCallback] private void on_open_button_clicked () {

        var dialog = new Gtk.FileChooserDialog (
            "Open file", this, Gtk.FileChooserAction.OPEN,
            "Cancel", Gtk.ResponseType.CANCEL,
            "Open", Gtk.ResponseType.ACCEPT
        );
        var result = dialog.run ();
        if (result == Gtk.ResponseType.ACCEPT) {
            string filename = dialog.get_filename ();
            mpv.open (filename);
            string basename = Path.get_basename (filename);
            if (basename.char_count () > 50) {
                basename = basename.substring (0, basename.index_of_nth_char (50)) + "...";
            }
            header_bar.subtitle = basename;
        }
        dialog.destroy ();
    }


    // Draw progressbar
    [GtkCallback] private bool on_progress_bar_draw (Gtk.Widget widget, Cairo.Context cr) {

        // Draw background
        int width = progress_bar.get_allocated_width ();
        int height = progress_bar.get_allocated_height ();
        cr.set_source_rgb (0.3, 0.3, 0.3);
        cr.paint ();
        
        if (mpv.duration > 0) {
            // Draw slice
            double duration = mpv.duration;
            double start_pos = current_slice.start_pos * width / duration;
            double end_pos = current_slice.end_pos * width / duration;

            cr.set_source_rgb (0.3, 0.6, 0.3);
            cr.rectangle (start_pos, 0, end_pos - start_pos, height);
            cr.fill ();

            // Draw current pos
            int pos = (int) (mpv.playback_time * width / duration);
            cr.set_source_rgb (1, 1, 1);
            cr.set_line_width (1);
            cr.move_to (pos, 0);
            cr.line_to (pos, height);
            cr.stroke ();

            cr.set_source_rgba (0, 0, 0, 0.4);
            cr.rectangle (width / 2 - 60, 2, 120, 31);
            cr.fill ();

            cr.move_to (width / 2 - 52, 26);
            cr.set_source_rgb (1, 1, 1);
            cr.set_font_size (18);
            cr.show_text (Utils.time2str (mpv.playback_time));
        }
        return true;
    }


    // Set playback time
    [GtkCallback] private bool on_progress_bar_pressed (Gtk.Widget widget, Gdk.EventButton event) {
        int width = widget.get_allocated_width ();
        double pos = event.x * mpv.duration / width;
        mpv.seek (pos);
        return true;
    }


    // Set start position
    [GtkCallback] private void on_set_start_button_clicked () {
        if (current_slice != null) {
            double pos = mpv.playback_time;
            current_slice.start_pos = pos;
            start_pos_label.label = Utils.time2str (pos);

            if (pos > current_slice.end_pos) {
                current_slice.end_pos = mpv.duration;
                end_pos_label.label = Utils.time2str (mpv.duration);
            }

            progress_bar.queue_draw ();
        }
    }


    // Set start position
    [GtkCallback] private void on_set_end_button_clicked () {
        if (current_slice != null) {
            double pos = mpv.playback_time;
            current_slice.end_pos = pos;
            end_pos_label.label = Utils.time2str (pos);

            if (pos < current_slice.start_pos) {
                current_slice.start_pos = 0;
                start_pos_label.label = "00:00:00.000";
            }

            progress_bar.queue_draw ();
        }
    }


    // Play / Pause
    [GtkCallback] private void on_pause_button_clicked () {
        mpv.pause = !mpv.pause;
    }
}