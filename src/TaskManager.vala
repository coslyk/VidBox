
class VideoSplitter.TaskManager : Object, ListModel {

    public bool exact_cut { get; set; default = false; }
    public bool merge { get; set; default = false; }
    public bool keep_audio { get; set; default = true; }

    private GenericArray<TaskItem> items = new GenericArray<TaskItem> ();
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
        items.add (item);
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
            items.remove_range (0, items.length);
        }
    }


    // Cut!
    public async void run_ffmpeg_cut () throws Error {

        // Cut
        var outfiles = new GenericArray<string> (items.length);
        foreach (unowned TaskItem item in items.data) {
            string start_pos_str = Utils.time2str (item.start_pos);
            string end_pos_str = Utils.time2str (item.end_pos);
            string outfile = @"$(filepath)_$(start_pos_str)-$(end_pos_str).$(format)".replace (":", ".");
            yield Ffmpeg.cut (filepath, outfile, format, item.start_pos, item.end_pos, !exact_cut, keep_audio);
            outfiles.add ((owned) outfile);
        }

        // Merge after cut
        if (merge) {
            string merged_file = @"$(filepath)_cut_merge.$(format)";
            yield Ffmpeg.merge (outfiles.data, merged_file, format);

            // Remove cut files
            foreach (unowned string outfile in outfiles.data) {
                var file = File.new_for_path (outfile);
                yield file.delete_async ();
            }
        }
    }


    // Implement ListModel
    public Type get_item_type () {
        return typeof (TaskItem);
    }

    public Object? get_item (uint position) {
        return position < items.length ? items[position] : null;
    }

    public uint get_n_items () {
        return items.length;
    }
}