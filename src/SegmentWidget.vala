
class VideoSplitter.SegmentWidget : Gtk.Box {

    public double start_pos {
        get { return _start_pos; }
        set { update_labels (value, _end_pos); }
    }

    public double end_pos {
        get { return _end_pos; }
        set { update_labels (_start_pos, value); }
    }

    private Gtk.Label time_label;
    private Gtk.Label duration_label;
    private double _start_pos;
    private double _end_pos;

    public SegmentWidget (double duration) {
        Object (orientation: Gtk.Orientation.VERTICAL);

        time_label = new Gtk.Label (null);
        pack_start (time_label);
        time_label.show ();

        duration_label = new Gtk.Label (null);
        pack_start (duration_label);
        duration_label.show ();

        update_labels (0, duration);
    }

    private void update_labels (double start_pos, double end_pos) {
        _start_pos = start_pos;
        _end_pos = end_pos;
        time_label.label = Utils.time2str (start_pos) + " - " + Utils.time2str (end_pos);
        duration_label.label = "Duration: " + Utils.time2str (end_pos - start_pos);
    }
}