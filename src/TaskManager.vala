
class VideoSplitter.TaskManager : Object, ListModel {

    public bool exact_cut { get; set; default = false; }
    public bool merge { get; set; default = false; }
    public bool keep_audio { get; set; default = true; }

    private Array<TaskItem> items = new Array<TaskItem> ();
    private string filepath;
    private string format;


    // Open a new file, clear the previous list
    public void new_file (string filepath) throws Error {
        this.format = Ffmpeg.detect_format (filepath);
        this.filepath = filepath;
        clear ();
    }


    // Add item
    public TaskItem add_item (double start_pos, double end_pos) {
        var item = new TaskItem (start_pos, end_pos);
        items.append_val (item);
        items_changed (items.length - 1, 0, 1);
        return item;
    }


    // Remove item
    public void remove_item (uint index) {
        items.remove_index (index);
        items_changed (index, 1, 0);
    }


    // Remove all items
    public void clear () {
        if (items.length > 0) {
            items_changed (0, items.length, 0);
            items = new Array<TaskItem> ();
        }
    }


    // Cut!
    public async void run_ffmpeg_cut () throws Error {
        for (uint i = 0; i < items.length ; i++) {
            unowned TaskItem item = items.index (i);
            yield Ffmpeg.cut (filepath, format, item.start_pos, item.end_pos, !exact_cut, keep_audio);
        }
    }


    // Implement ListModel
    public Type get_item_type () {
        return typeof (TaskItem);
    }

    public Object? get_item (uint position) {
        return position < items.length ? items.index (position) : null;
    }

    public uint get_n_items () {
        return items.length;
    }
}