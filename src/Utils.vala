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

namespace VideoSplitter.Utils {

    // Convert time to format string
    public string time2str (double time) {
        int hh = ((int) time) / 3600;
        int mm = ((int) time) % 3600 / 60;
        double ss = time % 60;
        return "%02d:%02d:%06.3f".printf (hh, mm, ss);
    }


    // Get Wayland Display
    public void* get_wayland_display () {

        unowned Gdk.Display display = Gdk.Display.get_default ();
        if (Gdk.Wayland.is_wayland_display (display)) {
            return Gdk.Wayland.get_wayland_display (display);
        } else {
            return null;
        }
    }


    // Get X11 Display
    public void* get_x11_display () {

        unowned Gdk.Display display = Gdk.Display.get_default ();
        if (!Gdk.Wayland.is_wayland_display (display)) {
            return Gdk.X11Display.get_xdisplay (display);
        } else {
            return null;
        }
    }


    // Get function pointers of OpenGL
    public void* get_proc_address (string name) {

        unowned Gdk.Display display = Gdk.Display.get_default ();
        if (Gdk.Wayland.is_wayland_display (display)) {
            return Epoxy.eglGetProcAddress (name);
        } else {
            return Epoxy.glXGetProcAddressARB (name);
        }
    }


    // Get program path
    private char _program_path[500];
    public unowned string get_program_path () {
        Posix.readlink ("/proc/self/exe", _program_path);
        return (string) _program_path;
    }


    errordomain ProcessError {
        STDERR
    }

    // Run external program
    public async string run_process (string[] args, string? input = null) throws Error {

        SourceFunc callback = run_process.callback;
        Pid child_pid;
        int standard_input;
        int standard_output;
        int standard_error;
        int[] exit_status = new int[1];
        Process.spawn_async_with_pipes (null,
            args,
            null,
            SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
            null,
            out child_pid,
            out standard_input,
            out standard_output,
            out standard_error
        );

        // Write input
        if (input != null) {
            IOChannel in_pipe = new IOChannel.unix_new (standard_input);
            size_t bytes_written;
            in_pipe.write_chars (input.to_utf8 (), out bytes_written);
            in_pipe.shutdown (true);
        }

        // Wait until finish
        ChildWatch.add (child_pid, (pid, status) => {
            exit_status[0] = status;
            Idle.add ((owned) callback);
        });
        yield;

        // Error?
        if (exit_status[0] != 0) {
            IOChannel err_pipe = new IOChannel.unix_new (standard_error);
            string errstr;
            size_t errstr_len;
            err_pipe.read_to_end (out errstr, out errstr_len);
            Process.close_pid (child_pid);
            throw new ProcessError.STDERR (errstr);
        }

        // Read output and return
        IOChannel out_pipe = new IOChannel.unix_new (standard_output);
        string outstr;
        size_t outstr_len;
        out_pipe.read_to_end (out outstr, out outstr_len);
        Process.close_pid (child_pid);
        return outstr;
    }
}