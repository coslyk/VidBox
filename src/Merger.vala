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

class VideoSplitter.Merger : Object, ListModel {

    private GenericArray<Ffmpeg.VideoInfo> items = new GenericArray<Ffmpeg.VideoInfo> ();

    // Add item
    public void add_item (string filepath) throws Error {
        var item = Ffmpeg.parse_video (filepath);
        items.add ((owned) item);
        items_changed (items.length - 1, 0, 1);
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


    // Lossless merge
    public async void run_lossless_merge (string outfile) throws Error {

        if (items.length < 2) {
            return;
        }

        // Cut
        (unowned string)[] infiles = {};
        foreach (unowned Ffmpeg.VideoInfo item in items.data) {
            infiles += item.filepath;
        }
        
        yield Ffmpeg.merge (infiles, outfile, items[0].format);
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