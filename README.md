# VidBox

A tiny video toolbox.

### Introduction

VidBox is a tiny but useful tool that allows you to split, merge videos and so on. It is a native GTK program written in Vala.

### Homepage

The homepage of VidBox is: https://coslyk.github.io/vidbox.html

Here is the development page of this project. For the program usage information, please visit the homepage.

### Installation

You can download the AppImage directly from the [Release page](https://github.com/coslyk/moonplayer/releases/latest).

### Screenshot

![](https://coslyk.github.io/files/videosplitter-dark.png)

### Development

Following packages are essential for compiling VidBox.

On ArchLinux:

```
    - vala
    - meson
    - libepoxy
    - gtk3
    - json-glib
    - mpv
```

On Debian:

```
    - valac
    - meson
    - libepoxy-dev
    - libgtk-3-dev
    - libjson-glib-dev
    - libmpv-dev
```

Additional runtime dependencies:
```
    - ffmpeg
```

Other Linux: Please diy.

Download the source code, then run:

```bash
meson build
ninja -C build
sudo ninja -C build install
```

### Translation

Translations are welcome. You can edit the .po files in the `po` folder. We recommend you to use [Poedit](https://poedit.net/) to edit po files.

### Technology stack

- [Gtk+](https://www.gtk.org/) (License: LGPL-2.1)

- [libmpv](https://mpv.io/) (License: GPLv2+)

- [ffmpeg](https://ffmpeg.org/) (License: GPLv2+)

- [JSON-GLib](https://gitlab.gnome.org/GNOME/json-glib) (License: LGPL-2.1)

## License

[GPL-3](https://github.com/coslyk/vidbox/blob/develop/LICENSE)