#!/bin/sh
set -eu

cd "$(dirname "$0")"

if ! command -v cargo >/dev/null 2>&1; then
    echo "Fehler: cargo (Rust) wird zum Bauen benötigt." >&2
    echo "Installieren mit: sudo apt install cargo" >&2
    exit 1
fi

# libcosmic braucht libxkbcommon-dev. Falls es fehlt, wird das Debian-Paket
# ohne root in einen dauerhaften Build-Cache entpackt. Der Cache-Pfad bleibt
# gleich, damit cargo nicht bei jedem Build alle abhängigen Crates neu baut.
if ! pkg-config --exists xkbcommon 2>/dev/null; then
    XKB_CACHE="$PWD/applet/target/build-deps/xkbcommon"
    XKB_PC=$(find "$XKB_CACHE/root" -name xkbcommon.pc -print -quit 2>/dev/null || true)

    if [ -z "$XKB_PC" ]; then
        mkdir -p "$XKB_CACHE"
        rm -f "$XKB_CACHE"/libxkbcommon-dev_*.deb
        if (cd "$XKB_CACHE" && apt-get download libxkbcommon-dev >/dev/null 2>&1); then
            XKB_DEB=$(find "$XKB_CACHE" -maxdepth 1 -name 'libxkbcommon-dev_*.deb' -print -quit)
            if [ -n "$XKB_DEB" ]; then
                dpkg-deb -x "$XKB_DEB" "$XKB_CACHE/root"
            fi
        fi
        XKB_PC=$(find "$XKB_CACHE/root" -name xkbcommon.pc -print -quit 2>/dev/null || true)
    fi

    if [ -z "$XKB_PC" ]; then
        echo "Fehler: libxkbcommon-dev fehlt und konnte nicht geladen werden." >&2
        echo "        Bitte ausführen: sudo apt install libxkbcommon-dev" >&2
        exit 1
    fi

    XKB_PC_DIR=$(dirname "$XKB_PC")
    # Stabiler prefix: verhindert Rebuilds durch wechselnde Temp-Pfade.
    sed -i "s|^prefix=.*|prefix=$XKB_CACHE/root/usr|" "$XKB_PC"
    XKB_LIB=$(ldconfig -p 2>/dev/null | awk '/libxkbcommon\.so\.0 /{print $NF; exit}')
    if [ -z "$XKB_LIB" ]; then
        XKB_LIB=$(find /usr/lib /lib -name 'libxkbcommon.so.0' -print -quit 2>/dev/null || true)
    fi
    if [ -n "$XKB_LIB" ]; then
        ln -sf "$XKB_LIB" "$XKB_PC_DIR/../libxkbcommon.so"
    fi
    PKG_CONFIG_PATH="$XKB_PC_DIR${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export PKG_CONFIG_PATH
    echo "libxkbcommon-dev aus dem Build-Cache bereitgestellt."
fi

echo "Baue pi-applet (das kann beim ersten Mal einige Minuten dauern) ..."
(cd applet && cargo build --release --locked)
