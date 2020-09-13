
namespace VideoSplitter.Utils {

    public string time2str (double time) {
        int hh = ((int) time) / 3600;
        int mm = ((int) time) % 3600 / 60;
        double ss = time % 60;
        return "%02d:%02d:%06.3f".printf (hh, mm, ss);
    }

    public void* get_wayland_display () {

        unowned Gdk.Display display = Gdk.Display.get_default ();
        if (Gdk.Wayland.is_wayland_display (display)) {
            return Gdk.Wayland.get_wayland_display (display);
        } else {
            return null;
        }
    }

    public void* get_x11_display () {

        unowned Gdk.Display display = Gdk.Display.get_default ();
        if (!Gdk.Wayland.is_wayland_display (display)) {
            return Gdk.X11Display.get_xdisplay (display);
        } else {
            return null;
        }
    }

    public void* get_proc_address (string name) {

        unowned Gdk.Display display = Gdk.Display.get_default ();
        if (Gdk.Wayland.is_wayland_display (display)) {
            return Epoxy.eglGetProcAddress (name);
        } else {
            return Epoxy.glXGetProcAddressARB (name);
        }
    }
}