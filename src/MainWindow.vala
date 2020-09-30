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

[GtkTemplate (ui = "/com/github/coslyk/VideoSplitter/MainWindow.ui")]
public class VideoSplitter.MainWindow : Gtk.ApplicationWindow {

    private MpvController mpv;
    private TaskManager task_manager;
    private TaskItem? selected_item;
    [GtkChild] private Gtk.GLArea video_area;
    [GtkChild] private Gtk.DrawingArea progress_bar;
    [GtkChild] private Gtk.Label start_pos_label;
    [GtkChild] private Gtk.Label end_pos_label;
    [GtkChild] private Gtk.HeaderBar header_bar;
    [GtkChild] private Gtk.MenuButton cut_button;
    [GtkChild] private Gtk.ListBox listbox;
    [GtkChild] private Gtk.Spinner running_spinner;
        

    public MainWindow(Gtk.Application application) {
        Object (application: application);
    }

    construct {
        task_manager = new TaskManager ();
        listbox.bind_model (task_manager, (item) => {
            var task = ((TaskItem) item);
            var label = new Gtk.Label (task.create_description ());
            task.notify.connect (() => label.label = task.create_description ());
            return label;
        });

        mpv = new MpvController (video_area);
        
        // Time updated
        mpv.notify["playback-time"].connect (() => progress_bar.queue_draw ());

        // New file loaded
        mpv.notify["duration"].connect (() => {
            selected_item = task_manager.add_item (0, mpv.duration);
            update_progressbar ();
        });

        // Logo
        try {
            this.icon = new Gdk.Pixbuf.from_resource ("/com/github/coslyk/VideoSplitter/logo.png");
        } catch (Error e) {
            warning ("%s", e.message);
        }

        // Init menus
        var menu_builder = new Gtk.Builder.from_resource ("/com/github/coslyk/VideoSplitter/Menus.ui");
        var cut_menu_model = menu_builder.get_object ("cut-menu") as Menu;
        cut_button.set_menu_model (cut_menu_model);

        // Add actions
        add_action (new PropertyAction ("merge", task_manager, "merge"));
        add_action (new PropertyAction ("exact-cut", task_manager, "exact-cut"));
        add_action (new PropertyAction ("remove-audio", task_manager, "remove-audio"));
        var action = new SimpleAction ("cut-video", null);
        action.activate.connect (run_ffmpeg_cut);
        add_action (action);

        // Enable drag and drops
        const Gtk.TargetEntry[] targets = {
            {"text/uri-list", 0, 0}
        };
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
    }


    // Update progressbar, including time labels
    private void update_progressbar () {
        if (selected_item != null) {
            progress_bar.queue_draw ();
            start_pos_label.label = Utils.time2str (selected_item.start_pos);
            end_pos_label.label = Utils.time2str (selected_item.end_pos);
        }
    }


    // Clear list
    [GtkCallback] private void on_clear_button_clicked () {
        task_manager.clear ();
        selected_item = null;
    }


    // Add segments
    [GtkCallback] private void on_add_button_clicked () {
        double duration = mpv.duration;
        if (duration > 0) {
            selected_item = task_manager.add_item (0, duration);
            update_progressbar ();
        }
    }

    // Remove selected segment
    [GtkCallback] private void on_remove_button_clicked () {
        unowned Gtk.ListBoxRow item = listbox.get_selected_row ();
        if (item != null) {
            int index = item.get_index ();
            task_manager.remove_item (index);
            selected_item = (TaskItem) task_manager.get_item (0);
            update_progressbar ();
        }
    }


    // Selected segment changes
    [GtkCallback] private void on_listbox_row_activated (Gtk.ListBoxRow row) {
        selected_item = (TaskItem) task_manager.get_item (row.get_index ());
        update_progressbar ();
    }


    // Open file
    private void open_file (string filepath) {

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
                _("Error parsing file: %s"), e.message
            );
            msgdlg.run ();
            msgdlg.destroy ();
        }
    }

    [GtkCallback] private void on_open_button_clicked () {

        // Show dialog
        var dialog = new Gtk.FileChooserDialog (
            _("Open file"), this, Gtk.FileChooserAction.OPEN,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            _("Open"), Gtk.ResponseType.ACCEPT
        );
        var result = dialog.run ();

        // File selected?
        if (result != Gtk.ResponseType.ACCEPT) {
            dialog.destroy ();
            return;
        }
        
        string filepath = dialog.get_filename ();
        dialog.destroy ();

        open_file (filepath);
    }


    // Drop files
    [GtkCallback] private void on_drag_data_received (Gdk.DragContext ctx, int x, int y, Gtk.SelectionData data, uint info, uint time) {
        string[] uris = data.get_uris ();
        if (uris.length > 0) {
            string file = uris[0].replace("file://","").replace("file:/","");
            file = Uri.unescape_string (file);
            open_file (file);
        }
        Gtk.drag_finish (ctx, true, false, time);
    }


    // Draw progressbar
    [GtkCallback] private bool on_progress_bar_draw (Gtk.Widget widget, Cairo.Context cr) {

        // Draw background
        int width = progress_bar.get_allocated_width ();
        int height = progress_bar.get_allocated_height ();
        double duration = mpv.duration;
        cr.set_source_rgb (0.3, 0.3, 0.3);
        cr.paint ();
        
        // Draw slice
        if (duration > 0 && selected_item != null) {
            double start_pos = selected_item.start_pos * width / duration;
            double end_pos = selected_item.end_pos * width / duration;

            cr.set_source_rgb (0.3, 0.6, 0.3);
            cr.rectangle (start_pos, 0, end_pos - start_pos, height);
            cr.fill ();
        }

        // Draw current pos
        if (duration > 0) {
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
        if (selected_item != null) {
            double pos = mpv.playback_time;
            selected_item.start_pos = pos;
            start_pos_label.label = Utils.time2str (pos);

            if (pos > selected_item.end_pos) {
                selected_item.end_pos = mpv.duration;
                end_pos_label.label = Utils.time2str (mpv.duration);
            }

            progress_bar.queue_draw ();
        }
    }


    // Set end position
    [GtkCallback] private void on_set_end_button_clicked () {
        if (selected_item != null) {
            double pos = mpv.playback_time;
            selected_item.end_pos = pos;
            end_pos_label.label = Utils.time2str (pos);

            if (pos < selected_item.start_pos) {
                selected_item.start_pos = 0;
                start_pos_label.label = Utils.time2str (0);
            }

            progress_bar.queue_draw ();
        }
    }


    // Jump to start position
    [GtkCallback] private void on_jump_start_button_clicked () {
        if (selected_item != null) {
            mpv.pause = true;
            mpv.playback_time = selected_item.start_pos;
        }
    }


    // Jump to end position
    [GtkCallback] private void on_jump_end_button_clicked () {
        if (selected_item != null) {
            mpv.pause = true;
            mpv.playback_time = selected_item.end_pos;
        }
    }


    // Play / Pause
    [GtkCallback] private void on_pause_button_clicked () {
        mpv.pause = !mpv.pause;
    }


    // Cut!
    private void run_ffmpeg_cut () {

        cut_button.sensitive = false;
        running_spinner.start ();

        task_manager.run_ffmpeg_cut.begin ((obj, res) => {

            running_spinner.stop ();
            cut_button.sensitive = true;

            try {
                task_manager.run_ffmpeg_cut.end (res);
                var msgdlg = new Gtk.MessageDialog (
                    this,
                    Gtk.DialogFlags.DESTROY_WITH_PARENT,
                    Gtk.MessageType.INFO,
                    Gtk.ButtonsType.CLOSE,
                    _("Finished!")
                );
                msgdlg.run ();
                msgdlg.destroy ();
                task_manager.clear ();
            }
            catch (Error e) {
                var msgdlg = new Gtk.MessageDialog (
                    this,
                    Gtk.DialogFlags.DESTROY_WITH_PARENT,
                    Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.CLOSE,
                    _("Fails to cut: %s"), e.message
                );
                msgdlg.run ();
                msgdlg.destroy ();
            }
        });
    }
}