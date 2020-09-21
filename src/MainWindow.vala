
[GtkTemplate (ui = "/com/github/coslyk/VideoSplitter/MainWindow.ui")]
public class VideoSplitter.MainWindow : Gtk.ApplicationWindow {

    private MpvController mpv;
    private SegmentWidget? current_segment;
    [GtkChild] private Gtk.GLArea video_area;
    [GtkChild] private Gtk.DrawingArea progress_bar;
    [GtkChild] private Gtk.Label start_pos_label;
    [GtkChild] private Gtk.Label end_pos_label;
    [GtkChild] private Gtk.HeaderBar header_bar;
    [GtkChild] private Gtk.MenuButton cut_button;
    [GtkChild] private Gtk.ListBox segments_listbox;
    private TaskManager task_manager;
        

    public MainWindow(Gtk.Application application) {
        Object (application: application);
    }

    construct {
        task_manager = new TaskManager ();
        segments_listbox.bind_model (task_manager, (item) => {
            var task = ((SegmentWidget) item);
            var label = new Gtk.Label (task.create_description ());
            task.notify.connect (() => label.label = task.create_description ());
            return label;
        });

        mpv = new MpvController (video_area);

        mpv.notify["playback-time"].connect (() => progress_bar.queue_draw ());  // Time updated
        mpv.notify["duration"].connect (add_segment);                            // New file loaded

        // Init menus
        var menu_builder = new Gtk.Builder.from_resource ("/com/github/coslyk/VideoSplitter/Menus.ui");
        var cut_menu_model = menu_builder.get_object ("cut-menu") as Menu;
        cut_button.set_menu_model (cut_menu_model);

        ActionEntry win_action_entries[] = {
            ActionEntry () {
                name = "cut_mode",
                parameter_type = "s",
                state = "'seperate'",
                change_state = (action, state) => action.set_state (state)
            },
            ActionEntry () {
                name = "frame_mode",
                parameter_type = "s",
                state = "'keyframe'",
                change_state = (action, state) => action.set_state (state)
            },
            ActionEntry () {
                name = "keep_audio",
                state = "true",
                change_state = (action, state) => action.set_state (state)
            },
            ActionEntry () {
                name = "cut_video",
                activate = () => {
                    run_ffmpeg_cut.begin ();
                }
            }
        };
        add_action_entries (win_action_entries, this);
    }


    // Update progressbar, including time labels
    private void update_progressbar () {
        if (current_segment != null) {
            progress_bar.queue_draw ();
            start_pos_label.label = Utils.time2str (current_segment.start_pos);
            end_pos_label.label = Utils.time2str (current_segment.end_pos);
        }
    }


    // Clear / reinit segments list
    [GtkCallback] private void reinit_segments_list () {
        task_manager.clear ();
        current_segment = null;
    }


    // Add segments
    [GtkCallback] private void add_segment () {
        double duration = mpv.duration;
        if (duration > 0) {
            current_segment = task_manager.add_item (0, duration);
        }
    }

    // Remove selected segment
    [GtkCallback] private void remove_selected_segment () {
        unowned Gtk.ListBoxRow item = segments_listbox.get_selected_row ();
        if (item != null) {
            int index = item.get_index ();
            task_manager.remove_item (index);
            current_segment = (SegmentWidget) task_manager.get_item (0);
            update_progressbar ();
        }
    }


    // Selected segment changes
    [GtkCallback] private void on_segments_listbox_row_activated (Gtk.ListBoxRow row) {
        current_segment = (SegmentWidget) task_manager.get_item (row.get_index ());
        update_progressbar ();
    }


    // Open file
    [GtkCallback] private void on_open_button_clicked () {

        // Show dialog
        var dialog = new Gtk.FileChooserDialog (
            "Open file", this, Gtk.FileChooserAction.OPEN,
            "Cancel", Gtk.ResponseType.CANCEL,
            "Open", Gtk.ResponseType.ACCEPT
        );
        var result = dialog.run ();

        // File selected?
        if (result != Gtk.ResponseType.ACCEPT) {
            dialog.destroy ();
            return;
        }
        
        string filepath = dialog.get_filename ();
        dialog.destroy ();

        try {
            // Get file info
            task_manager.new_file (filepath);

            // Open file
            mpv.open (filepath);
            string basename = Path.get_basename (filepath);
            if (basename.char_count () > 50) {
                basename = basename.substring (0, basename.index_of_nth_char (50)) + "...";
            }
            header_bar.subtitle = basename;
        }
        catch (Error e) {
            var msgdlg = new Gtk.MessageDialog (
                this,
                Gtk.DialogFlags.DESTROY_WITH_PARENT,
                Gtk.MessageType.ERROR,
                Gtk.ButtonsType.CLOSE,
                "Error parsing file: %s", e.message
            );
            msgdlg.run ();
            msgdlg.destroy ();
        }
    }


    // Draw progressbar
    [GtkCallback] private bool on_progress_bar_draw (Gtk.Widget widget, Cairo.Context cr) {

        // Draw background
        int width = progress_bar.get_allocated_width ();
        int height = progress_bar.get_allocated_height ();
        double duration = mpv.duration;
        cr.set_source_rgb (0.3, 0.3, 0.3);
        cr.paint ();
        
        if (duration > 0 && current_segment != null) {
            // Draw slice
            double start_pos = current_segment.start_pos * width / duration;
            double end_pos = current_segment.end_pos * width / duration;

            cr.set_source_rgb (0.3, 0.6, 0.3);
            cr.rectangle (start_pos, 0, end_pos - start_pos, height);
            cr.fill ();

            // Draw current pos
            double playback_time = mpv.playback_time;
            int pos = (int) (playback_time * width / duration);
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
            cr.show_text (Utils.time2str (playback_time));
        }
        return true;
    }


    // Set playback time
    [GtkCallback] private bool on_progress_bar_pressed (Gtk.Widget widget, Gdk.EventButton event) {
        int width = widget.get_allocated_width ();
        mpv.playback_time = event.x * mpv.duration / width;
        return true;
    }


    // Frame navigation
    [GtkCallback] private void on_prev_frame_button_clicked () {
        mpv.previous_frame ();
    }

    [GtkCallback] private void on_next_frame_button_clicked () {
        mpv.next_frame ();
    }


    // Set start position
    [GtkCallback] private void on_set_start_button_clicked () {
        if (current_segment != null) {
            double pos = mpv.playback_time;
            current_segment.start_pos = pos;
            start_pos_label.label = Utils.time2str (pos);

            if (pos > current_segment.end_pos) {
                current_segment.end_pos = mpv.duration;
                end_pos_label.label = Utils.time2str (mpv.duration);
            }

            progress_bar.queue_draw ();
        }
    }


    // Set end position
    [GtkCallback] private void on_set_end_button_clicked () {
        if (current_segment != null) {
            double pos = mpv.playback_time;
            current_segment.end_pos = pos;
            end_pos_label.label = Utils.time2str (pos);

            if (pos < current_segment.start_pos) {
                current_segment.start_pos = 0;
                start_pos_label.label = "00:00:00.000";
            }

            progress_bar.queue_draw ();
        }
    }


    // Play / Pause
    [GtkCallback] private void on_pause_button_clicked () {
        mpv.pause = !mpv.pause;
    }


    // Cut!
    private async void run_ffmpeg_cut () {
        try {
            yield task_manager.run_ffmpeg_cut ();
        } catch (Error e) {
            var msgdlg = new Gtk.MessageDialog (
                this,
                Gtk.DialogFlags.DESTROY_WITH_PARENT,
                Gtk.MessageType.ERROR,
                Gtk.ButtonsType.CLOSE,
                "Fails to cut: %s", e.message
            );
            msgdlg.run ();
            msgdlg.destroy ();
        }
    }
}