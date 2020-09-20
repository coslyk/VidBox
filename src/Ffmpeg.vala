
namespace VideoSplitter.Ffmpeg {

    errordomain FfmpegError {
        FORMAT_DETECTION_FAILED
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


    public async void cut (string filepath, string format, double start_pos, double end_pos, bool keyframe_cut, bool keep_audio) {

        string start_pos_str = Utils.time2str (start_pos);
        string end_pos_str = Utils.time2str (end_pos);
        string duration_str = Utils.time2str (end_pos - start_pos);
        string outfile = @"$(filepath)_$(start_pos_str)-$(end_pos_str).$(format)".replace (":", ".");

        (unowned string)[] args = { "ffmpeg", "-hide_banner" };

        // Cut position parameters
        if (keyframe_cut) {
            args += "-ss";
            args += start_pos_str;
            args += "-i";
            args += filepath;
            args += "-t";
            args += duration_str;
            args += "-avoid_negative_ts";
            args += "make_zero";
        } else {
            args += "-i";
            args += filepath;
            args += "-ss";
            args += start_pos_str;
            args += "-t";
            args += duration_str;
        }

        // No re-encoding
        args += "-c";
        args += "copy";
        args += "-ignore_unknown";

        // Enable experimental operation
        args += "-strict";
        args += "experimental";

        // Output format
        args += "-f";
        args += format;

        // Output file
        args += "-y";
        args += outfile;

        // Run ffmpeg
        try {
            Pid child_pid;
            Process.spawn_async (null, args, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid);
            ChildWatch.add (child_pid, (pid, status) => {
                Process.close_pid (pid);
                Idle.add (cut.callback);
            });
            yield;
        }
        catch (SpawnError e) {
            warning ("%s", e.message);
        }
    }
}