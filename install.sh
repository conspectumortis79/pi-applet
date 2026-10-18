#!/bin/sh
set -eu

cd "$(dirname "$0")"

APP_ID="io.github.pmichailidis.PiApplet"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN_DIR="$HOME/.local/bin"
ICON_DIR="$DATA_HOME/icons/hicolor/scalable/apps"
APP_DIR="$DATA_HOME/applications"

sh build.sh

echo
echo "Installiere pi-applet nach ~/.local ..."
install -Dm755 applet/target/release/pi-applet "$BIN_DIR/pi-applet"
install -Dm755 scripts/pi-applet-open "$BIN_DIR/pi-applet-open"
install -Dm644 data/pi-applet.svg "$ICON_DIR/pi-applet.svg"
install -Dm644 data/pi-applet-symbolic.svg "$ICON_DIR/pi-applet-symbolic.svg"

mkdir -p "$APP_DIR"
sed "s|@BIN@|$BIN_DIR/pi-applet|g" "applet/resources/$APP_ID.desktop" \
    > "$APP_DIR/$APP_ID.desktop"
chmod 644 "$APP_DIR/$APP_ID.desktop"

gtk-update-icon-cache -f -t "$DATA_HOME/icons/hicolor" >/dev/null 2>&1 || true
command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

echo
echo "Trage das Applet in die Panel-Konfiguration ein ..."
python3 scripts/panel-config.py add

echo
echo "Fertig."
echo "Falls das π-Symbol noch nicht in der Panel-Leiste steht:"
echo "  Einstellungen → Desktop → Panel → Applet hinzufügen → \"pi\""
echo "(alternativ einmal ab- und wieder anmelden)"
