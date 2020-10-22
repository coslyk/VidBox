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

namespace VideoSplitter.Ffmpeg {

    errordomain FfmpegError {
        FORMAT_DETECTION_FAILED,
        CONVERT_FAILED
    }

    
    // Detect format of video
    public string detect_format (string filepath) throws Error {

        // Run ffprobe
        (unowned string)[] args = 
            { "ffprobe", "-hide_banner", "-loglevel", "warning", "-of", "json", "-show_format", "-i", filepath };
        string output;
        string err;
        int exit_status;
        Process.spawn_sync (null, args, null, SpawnFlags.SEARCH_PATH, null, out output, out err, out exit_status);
        if (err.length != 0) {
            throw new FfmpegError.FORMAT_DETECTION_FAILED (err);
        }

        // Parse output
        var parser = new Json.Parser ();
        parser.load_from_data (output);
        unowned string format_str = parser.get_root ().get_object ().get_object_member ("format").get_string_member ("format_name");
        string[] formats = format_str.split(",");

        // Compare with filename
        int idx = filepath.last_index_of_char ('.');
        if (idx != -1) {
            string ext = filepath.substring (idx + 1);
            if (ext in formats) {
                return ext;
            }
        }
        return (owned) formats[0];
    }


    // Cut videos
    public async void cut (string infile, string outfile, string format, double start_pos, double end_pos,
                           bool keyframe_cut, bool remove_audio) throws Error {

        string start_pos_str = Utils.time2str (start_pos);
        string duration_str = Utils.time2str (end_pos - start_pos);

        var args = new GenericArray<unowned string?> ();
        args.add ("ffmpeg");
        args.add ("-hide_banner");
        args.add ("-loglevel");
        args.add ("warning");

        // Cut position parameters
        if (keyframe_cut) {
            args.add ("-ss");
            args.add (start_pos_str);
            args.add ("-i");
            args.add (infile);
            args.add ("-t");
            args.add (duration_str);
            args.add ("-avoid_negative_ts");
            args.add ("make_zero");
        } else {
            args.add ("-i");
            args.add (infile);
            args.add ("-ss");
            args.add (start_pos_str);
            args.add ("-t");
            args.add (duration_str);
        }

        // No re-encoding
        args.add ("-c");
        args.add ("copy");

        // Remove audio
        if (remove_audio) {
            args.add ("-an");
        }
        
        args.add ("-ignore_unknown");

        // Enable experimental operation
        args.add ("-strict");
        args.add ("experimental");

        // Output format
        args.add ("-f");
        args.add (format);

        // Output file
        args.add ("-y");
        args.add (outfile);
        args.add (null);

        // Run ffmpeg
        yield Utils.run_process (args.data);
    }


    // Merge videos
    public async void merge (string[] infiles, string outfile, string format) throws Error {

        // FFMpeg args
        (unowned string)[] args = {
            "ffmpeg", "-hide_banner",
            "-loglevel", "warning",    // less output
            "-f", "concat",            // merge files
            "-safe", "0",              // Disable safe check
            "-protocol_whitelist","file,pipe",
            "-i", "-",                 // Read file list from pipe
            "-c", "copy",              // No re-encoding
            "-ignore_unknown",
            "-strict", "experimental", // Enable experimental operation
            "-f", format,              // Output file format
            "-y", outfile              // Output file
        };

        // Generate list of files for concat
        var entries = new GenericArray<string> ();
        foreach (unowned string infile in infiles) {
            entries.add ("file '%s'".printf (infile.replace ("'", "'\\''")));
        }
        var concat_text = string.joinv ("\n", entries.data);

        // Run ffmpeg
        yield Utils.run_process (args, concat_text);
    }
}