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

class VideoSplitter.Splitter : Object, ListModel {

    public bool exact_cut { get; set; default = false; }
    public bool merge { get; set; default = false; }
    public bool remove_audio { get; set; default = false; }
    public Ffmpeg.VideoInfo video_info { get { return info; } }

    private GenericArray<SplitterItem> items = new GenericArray<SplitterItem> ();
    private string filepath;
    private Ffmpeg.VideoInfo info;


    // Open a new file, clear the previous list
    public void new_file (string filepath) throws Error {
        info = Ffmpeg.parse_video (filepath);
        this.filepath = filepath;
        clear ();
        add_item (0, info.duration);
    }


    // Add item
    public SplitterItem add_item (double start_pos, double end_pos) {
        var item = new SplitterItem (start_pos, end_pos);
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

        // Where to store output files?
        var settings = Application.settings;
        string outfile_base;
        if (settings.get_boolean ("use-input-directory")) {
            outfile_base = filepath;
        } else {
            outfile_base = Path.build_filename (settings.get_string ("output-directory"), Path.get_basename (filepath));
        }

        // Cut
        var outfiles = new GenericArray<string> ();
        foreach (unowned SplitterItem item in items.data) {
            string start_pos_str = Utils.time2str (item.start_pos).replace (":", ".");
            string end_pos_str = Utils.time2str (item.end_pos).replace (":", ".");
            string outfile = @"$(outfile_base)_$(start_pos_str)-$(end_pos_str).$(info.format)";
            yield Ffmpeg.cut (filepath, outfile, info.format, item.start_pos, item.end_pos, !exact_cut, remove_audio);
            outfiles.add ((owned) outfile);
        }

        // Merge after cut
        if (merge) {
            string merged_file = @"$(outfile_base)_cut_merge.$(info.format)";
            yield Ffmpeg.merge (outfiles.data, merged_file, info.format);

            // Remove cut files
            foreach (unowned string outfile in outfiles.data) {
                var file = File.new_for_path (outfile);
                yield file.delete_async ();
            }
        }
    }


    // Implement ListModel
    public Type get_item_type () {
        return typeof (SplitterItem);
    }

    public Object? get_item (uint position) {
        return position < items.length ? items[position] : null;
    }

    public uint get_n_items () {
        return items.length;
    }
}