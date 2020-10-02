#! /bin/bash

# abort on all errors
set -e

script=$(readlink -f "$0")

show_usage() {
    echo "Usage: $script --appdir <path to AppDir>"
    echo
    echo "Bundles resources for applications that use Gtk 2 or 3 into an AppDir"
}

APPDIR=

while [ "$1" != "" ]; do
    case "$1" in
        --plugin-api-version)
            echo "0"
            exit 0
            ;;
        --appdir)
            APPDIR="$2"
            shift
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Invalid argument: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
done

if [ "$APPDIR" == "" ]; then
    show_usage
    exit 1
fi

mkdir -p "$APPDIR"


echo "Compiling GLib schemas"
glib-compile-schemas "$APPDIR/usr/share/glib-2.0/schemas"
HOOKSDIR="$APPDIR/apprun-hooks"
HOOKFILE="$HOOKSDIR/linuxdeploy-plugin-gtk3.sh"
mkdir -p "$HOOKSDIR"
cat > "$HOOKFILE" <<\EOF
export APPDIR="${APPDIR:-"$(dirname "$(realpath "$0")")"}"
export GSETTINGS_SCHEMA_DIR="$APPDIR/usr/share/glib-2.0/schemas"
EOF

echo "Excluding libraries"
rm -vf $APPDIR/usr/lib/libatk-1.0.so.0
rm -vf $APPDIR/usr/lib/libatk-bridge-2.0.so.0
rm -vf $APPDIR/usr/lib/libcairo.so.2
rm -vf $APPDIR/usr/lib/libcairo-gobject.so.2
rm -vf $APPDIR/usr/lib/libdbus-1.so.3
rm -vf $APPDIR/usr/lib/libepoxy.so.0
rm -vf $APPDIR/usr/lib/libgdk-3.so.0
rm -vf $APPDIR/usr/lib/libgmodule-2.0.so.0
rm -vf $APPDIR/usr/lib/libgtk-3.so.0
