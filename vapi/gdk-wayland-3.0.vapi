/*
 * Vala bindings for gdk-wayland-3.0
 * Copyright 2020 Yikun Liu <cos.lyk@gmail.com>
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, you can find it at
 * <https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>
 */

[CCode (cheader_filename = "gdk/gdkwayland.h")]
namespace Gdk.Wayland {

    [CCode (cname = "GDK_IS_WAYLAND_DISPLAY")]
    bool is_wayland_display (Gdk.Display display);

    [CCode (cname = "gdk_wayland_display_get_wl_display")]
    void* get_wayland_display (Gdk.Display display);
}