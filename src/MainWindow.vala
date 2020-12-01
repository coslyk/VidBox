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

[GtkTemplate (ui = "/com/github/coslyk/VidBox/MainWindow.ui")]
public class VidBox.MainWindow : Gtk.ApplicationWindow {

    // Common widgets
    [GtkChild] private Gtk.Button back_button;
    [GtkChild] private Gtk.HeaderBar header_bar;
    [GtkChild] private Gtk.Label progress_label;
    [GtkChild] private Gtk.Spinner running_spinner;
    [GtkChild] private Gtk.Stack main_stack;

    // Splitter widgets and controller
    private MpvController mpv;
    private Splitter splitter;
    private SplitterItem? selected_item;
    [GtkChild] private Gtk.DrawingArea splitter_progress_bar;
    [GtkChild] private Gtk.GLArea splitter_video_area;
    [GtkChild] private Gtk.Label splitter_start_pos_label;
    [GtkChild] private Gtk.Label splitter_end_pos_label;
    [GtkChild] private Gtk.ListBox splitter_listbox;
    [GtkChild] private Gtk.MenuButton split_button;

    // Merger widgets and controller
    private Merger merger;
    [GtkChild] private Gtk.Button merger_start_button;
    [GtkChild] private Gtk.ComboBox merger_format_combobox;
    [GtkChild] private Gtk.ListBox merger_listbox;
    [GtkChild] private Gtk.RadioButton merger_losslessmerge_radiobutton;
    [GtkChild] private Gtk.Adjustment merger_width_adjustment;
    [GtkChild] private Gtk.Adjustment merger_height_adjustment;
    [GtkChild] private Gtk.SpinButton merger_width_spinbutton;
    [GtkChild] private Gtk.SpinButton merger_height_spinbutton;
        

    public MainWindow(Gtk.Application application) {
        Object (application: application);
    }

    construct {
        // Init splitter
        splitter = new Splitter ();
        splitter_listbox.bind_model (splitter, (item) => {
            var task = ((SplitterItem) item);
            var label = new Gtk.Label (task.create_description ());
            task.notify.connect ((obj, param) => label.label = ((SplitterItem) obj).create_description ());
            return label;
        });

        // Mpv
        mpv = new MpvController (splitter_video_area);
        mpv.notify["playback-time"].connect (() => splitter_progress_bar.queue_draw ());

        // Merger
        merger = new Merger ();
        merger.progress_updated.connect ((progress) => {
            progress_label.label = ((int) (progress * 100)).to_string () + "%";
        });
        merger_listbox.bind_model (merger, (item) => {
            return new Gtk.Label (((Ffmpeg.VideoInfo) item).filepath);
        });
        merger_losslessmerge_radiobutton.bind_property(
            "active",
            merger_width_spinbutton,
            "sensitive",
            BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE
        );
        merger_losslessmerge_radiobutton.bind_property(
            "active",
            merger_height_spinbutton,
            "sensitive",
            BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE
        );

        // Logo
        try {
            this.icon = new Gdk.Pixbuf.from_resource ("/com/github/coslyk/VidBox/logo.png");
        } catch (Error e) {
            warning ("%s", e.message);
        }

        // Init menus
        var menu_builder = new Gtk.Builder.from_resource ("/com/github/coslyk/VidBox/Menus.ui");
        var cut_menu_model = menu_builder.get_object ("cut-menu") as Menu;
        split_button.set_menu_model (cut_menu_model);

        // Add actions
        add_action (new PropertyAction ("merge", splitter, "merge"));
        add_action (new PropertyAction ("exact-cut", splitter, "exact-cut"));
        add_action (new PropertyAction ("remove-audio", splitter, "remove-audio"));
        var action = new SimpleAction ("cut-video", null);
        action.activate.connect (splitter_run);
        add_action (action);
    }

    [GtkCallback] void on_back_button_clicked () {
        mpv.stop ();
        main_stack.visible_child_name = "home_page";
        back_button.visible = false;
        split_button.visible = false;
        header_bar.subtitle = null;
    }


    // Update progressbar, including time labels
    private void update_progressbar () {
        if (selected_item != null) {
            splitter_progress_bar.queue_draw ();
            splitter_start_pos_label.label = Utils.time2str (selected_item.start_pos);
            splitter_end_pos_label.label = Utils.time2str (selected_item.end_pos);
        }
    }


    // Clear list
    [GtkCallback] private void on_splitter_clear_button_clicked () {
        splitter.clear ();
        selected_item = null;
    }


    // Add segments
    [GtkCallback] private void on_splitter_add_button_clicked () {
        double duration = splitter.video_info.duration;
        if (duration > 0) {
            selected_item = splitter.add_item (0, duration);
            update_progressbar ();
        }
    }

    // Remove selected segment
    [GtkCallback] private void on_splitter_remove_button_clicked () {
        unowned Gtk.ListBoxRow item = splitter_listbox.get_selected_row ();
        if (item != null) {
            int index = item.get_index ();
            splitter.remove_item (index);
            selected_item = (SplitterItem) splitter.get_item (0);
            update_progressbar ();
        }
    }


    // Selected segment changes
    [GtkCallback] private void on_splitter_listbox_row_activated (Gtk.ListBoxRow row) {
        selected_item = (SplitterItem) splitter.get_item (row.get_index ());
        update_progressbar ();
    }

    [GtkCallback] private void on_splitter_open_button_clicked () {
        string? filepath = Dialogs.open_file (this);
        if (filepath == null) {
            return;
        }

        try {
            // Get file info
            splitter.new_file (filepath);
            selected_item = (SplitterItem) splitter.get_item(0);
            update_progressbar ();

            // Show splitter
            main_stack.visible_child_name = "splitter_page";
            back_button.visible = true;
            split_button.visible = true;
            string basename = Path.get_basename (filepath);
            if (basename.char_count () > 50) {
                basename = basename.substring (0, basename.index_of_nth_char (50)) + "...";
            }
            header_bar.subtitle = basename;

            // Preview video
            mpv.open (filepath);
        }
        catch (Error e) {
            Dialogs.message (this, Gtk.MessageType.ERROR, _("Error parsing file: ") + e.message);
        }
    }


    // Draw progressbar
    [GtkCallback] private bool on_splitter_progress_bar_draw (Gtk.Widget widget, Cairo.Context cr) {

        // Draw background
        int width = splitter_progress_bar.get_allocated_width ();
        int height = splitter_progress_bar.get_allocated_height ();
        double duration = splitter.video_info.duration;
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
    [GtkCallback] private bool on_splitter_progress_bar_pressed (Gtk.Widget widget, Gdk.EventButton event) {
        int width = widget.get_allocated_width ();
        mpv.playback_time = event.x * splitter.video_info.duration / width;
        return true;
    }


    // Frame navigation
    [GtkCallback] private void on_splitter_prev_frame_button_clicked () {
        mpv.previous_frame ();
    }

    [GtkCallback] private void on_splitter_next_frame_button_clicked () {
        mpv.next_frame ();
    }


    // Set start position
    [GtkCallback] private void on_splitter_set_start_button_clicked () {
        if (selected_item != null) {
            double pos = mpv.playback_time;
            selected_item.start_pos = pos;
            splitter_start_pos_label.label = Utils.time2str (pos);

            if (pos > selected_item.end_pos) {
                double duration = splitter.video_info.duration;
                selected_item.end_pos = duration;
                splitter_end_pos_label.label = Utils.time2str (duration);
            }

            splitter_progress_bar.queue_draw ();
        }
    }


    // Set end position
    [GtkCallback] private void on_splitter_set_end_button_clicked () {
        if (selected_item != null) {
            double pos = mpv.playback_time;
            selected_item.end_pos = pos;
            splitter_end_pos_label.label = Utils.time2str (pos);

            if (pos < selected_item.start_pos) {
                selected_item.start_pos = 0;
                splitter_start_pos_label.label = Utils.time2str (0);
            }

            splitter_progress_bar.queue_draw ();
        }
    }


    // Jump to start position
    [GtkCallback] private void on_splitter_jump_start_button_clicked () {
        if (selected_item != null) {
            mpv.pause = true;
            mpv.playback_time = selected_item.start_pos;
        }
    }


    // Jump to end position
    [GtkCallback] private void on_splitter_jump_end_button_clicked () {
        if (selected_item != null) {
            mpv.pause = true;
            mpv.playback_time = selected_item.end_pos;
        }
    }


    // Play / Pause
    [GtkCallback] private void on_splitter_pause_button_clicked () {
        mpv.pause = !mpv.pause;
    }


    // Cut!
    private void splitter_run () {

        split_button.sensitive = false;
        running_spinner.start ();

        splitter.run_ffmpeg_cut.begin ((obj, res) => {

            running_spinner.stop ();
            split_button.sensitive = true;

            try {
                splitter.run_ffmpeg_cut.end (res);
                Dialogs.message (this, Gtk.MessageType.INFO, _("Finished!"));
                splitter.clear ();
            }
            catch (Error e) {
                Dialogs.message (this, Gtk.MessageType.ERROR, _("Fails to cut: ") + e.message);
            }
        });
    }


    // Merger
    [GtkCallback] private void on_merger_open_button_clicked () {
        main_stack.visible_child_name = "merger_page";
        back_button.visible = true;
    }


    // Open files
    [GtkCallback] private void on_merger_add_button_clicked () {
        var files = Dialogs.open_files (this);
        if (files == null) {
            return;
        }

        try {
            foreach (unowned string filepath in files) {
                merger.add_item (filepath);
            }
        } catch (Error e) {
            Dialogs.message (this, Gtk.MessageType.ERROR, _("Cannot add file: ") + e.message);
        }
    }


    // Remove item
    [GtkCallback] private void on_merger_remove_button_clicked () {
        unowned Gtk.ListBoxRow item = merger_listbox.get_selected_row ();
        if (item != null) {
            int index = item.get_index ();
            merger.remove_item (index);
        }
    }


    // Clear items
    [GtkCallback] private void on_merger_clear_button_clicked () {
        merger.clear ();
    }


    // Move items
    [GtkCallback] private void on_merger_up_button_clicked () {
        unowned Gtk.ListBoxRow item = merger_listbox.get_selected_row ();
        if (item != null) {
            int index = item.get_index ();
            if (index > 0) {
                merger.move_up_item (index);
                merger_listbox.select_row (merger_listbox.get_row_at_index (index - 1));
            }
        }
    }

    [GtkCallback] private void on_merger_down_button_clicked () {
        unowned Gtk.ListBoxRow item = merger_listbox.get_selected_row ();
        if (item != null) {
            int index = item.get_index ();
            if (index < merger.get_n_items () - 1) {
                merger.move_down_item (index);
                merger_listbox.select_row (merger_listbox.get_row_at_index (index + 1));
            }
        }
    }


    // Merge!
    [GtkCallback] private void on_merger_start_button_clicked () {

        string? outfile = Dialogs.save_file (this);
        if (outfile == null) {
            return;
        }

        merger_start_button.sensitive = false;
        progress_label.visible = true;
        running_spinner.start ();
        merger.run_merge.begin (
            (owned) outfile,
            merger_losslessmerge_radiobutton.active,
            (int64) merger_width_adjustment.value,
            (int64) merger_height_adjustment.value,
            merger_format_combobox.active_id,
            (obj, res) => {
                try {
                    merger_start_button.sensitive = true;
                    progress_label.visible = false;
                    running_spinner.stop ();
                    merger.run_merge.end (res);
                    Dialogs.message (this, Gtk.MessageType.INFO, _("Merge finished!"));
                } catch (Error e) {
                    Dialogs.message (this, Gtk.MessageType.ERROR, e.message);
                }
            }
        );
    }
}