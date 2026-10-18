#!/bin/sh
set -eu

cd "$(dirname "$0")"

APP_ID="io.github.pmichailidis.PiApplet"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN_DIR="$HOME/.local/bin"

echo "Entferne pi-applet ..."
rm -f "$BIN_DIR/pi-applet" "$BIN_DIR/pi-applet-open"
rm -f "$DATA_HOME/icons/hicolor/scalable/apps/pi-applet.svg"
rm -f "$DATA_HOME/icons/hicolor/scalable/apps/pi-applet-symbolic.svg"
rm -f "$DATA_HOME/applications/$APP_ID.desktop"

gtk-update-icon-cache -f -t "$DATA_HOME/icons/hicolor" >/dev/null 2>&1 || true

python3 scripts/panel-config.py remove

echo "Fertig. Ein eventuell noch sichtbares Panel-Symbol verschwindet nach"
echo "Ab- und Anmelden oder nach dem Entfernen in den Panel-Einstellungen."
