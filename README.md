# Video Splitter

A simple tool to split videos.

### Introduction

Video Splitter allows you to split your videos losslessly and conveniently. It is a native GTK program written in Vala.

### Homepage

The homepage of Video Splitter is: https://coslyk.github.io/videosplitter.html

Here is the development page of this project. For the program usage information, please visit the homepage.

### Compile

Following packages are essential for compiling Video Splitter.

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
