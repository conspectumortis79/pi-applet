#!/usr/bin/env python3
"""pi-applet in der COSMIC-Panel-Konfiguration eintragen/entfernen.

Aufruf:
    panel-config.py add
    panel-config.py remove
"""

from __future__ import annotations

import datetime
import pathlib
import re
import shutil
import sys

APPLET_ID = "io.github.pmichailidis.PiApplet"
ENTRY = f'"{APPLET_ID}"'
ENTRY_RE = re.compile(r'^[ \t]*"' + re.escape(APPLET_ID) + r'",?[ \t]*\n?', re.MULTILINE)


def panel_configs() -> list[pathlib.Path]:
    cosmic = pathlib.Path.home() / ".config" / "cosmic"
    candidates = [
        cosmic / "com.system76.CosmicPanel.Panel" / "v1" / "plugins_wings",
        cosmic / "com.system76.CosmicPanel" / "v1" / "plugins_wings",
    ]
    return [path for path in candidates if path.is_file()]


def backup(path: pathlib.Path) -> None:
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    target = path.with_name(f"{path.name}.bak-{stamp}")
    shutil.copy2(path, target)
    print(f"  Backup: {target}")


def add(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if APPLET_ID in text:
        print(f"  bereits eingetragen: {path}")
        return False

    # plugins_wings hat die Form: Some(([ links ], [ rechts ]))
    # -> als ersten Eintrag in den rechten Flügel setzen.
    new_text, count = re.subn(r"\],\s*\[", "], [\n    " + ENTRY + ",", text, count=1)
    if count == 0:
        print(
            f"  Konnte {path} nicht automatisch bearbeiten – bitte in\n"
            "  Einstellungen → Desktop → Panel → Applet hinzufügen → \"pi\" eintragen.",
            file=sys.stderr,
        )
        return False

    backup(path)
    path.write_text(new_text, encoding="utf-8")
    print(f"  hinzugefügt: {path}")
    return True


def remove(path: pathlib.Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if APPLET_ID not in text:
        print(f"  nicht vorhanden: {path}")
        return False

    backup(path)
    new_text = ENTRY_RE.sub("", text, count=1)
    if APPLET_ID in new_text:
        # Eintrag stand unerwartet in einer anderen Zeile – konservativ ersetzen.
        new_text = new_text.replace(ENTRY + ",", "").replace(ENTRY, "")
    path.write_text(new_text, encoding="utf-8")
    print(f"  entfernt: {path}")
    return True


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"add", "remove"}:
        print(__doc__, file=sys.stderr)
        return 2

    action = add if sys.argv[1] == "add" else remove
    configs = panel_configs()
    if not configs:
        print("  Keine COSMIC-Panel-Konfiguration gefunden.")
        return 0

    for path in configs:
        action(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
