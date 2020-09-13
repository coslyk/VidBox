
[CCode (cheader_filename = "gdk/gdkwayland.h")]
namespace Gdk.Wayland {

    [CCode (cname = "GDK_IS_WAYLAND_DISPLAY")]
    bool is_wayland_display (Gdk.Display display);

    [CCode (cname = "gdk_wayland_display_get_wl_display")]
    void* get_wayland_display (Gdk.Display display);
}