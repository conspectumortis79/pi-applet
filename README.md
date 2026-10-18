# pi-applet

A COSMIC panel applet for **Pop!_OS 24.04**: clicking the π icon opens a COSMIC
terminal running **pi**. When pi exits, an interactive **zsh** stays open in the
same window.

```
Panel:  [ π ]  ──click──▶  cosmic-term  ──▶  pi
                                             │
                                  (on exit) │
                                             ▼
                                       zsh -i
```

## Features

- Real COSMIC panel applet (Rust/libcosmic), not a wrapper around another app
- Symbolic π icon that follows the light/dark theme
- Starts in the home directory
- Fast startup: pi is launched directly, without loading the full interactive
  zsh configuration first (`~/.zshenv` is still loaded). When pi exits, a
  normal interactive zsh opens in the same window (and loads `~/.zshrc` as
  usual)
- Behaviour can be changed without rebuilding via `~/.local/bin/pi-applet-open`
- Installs entirely to `~/.local`, no root required

## Requirements

- Pop!_OS 24.04 with a COSMIC session
- `cargo` / Rust (build only)
- `libxkbcommon-dev` (`build.sh` fetches it from the Debian package without
  root if it is missing)
- `cosmic-term`, `zsh`, `pi`, `python3`

## Installation

```sh
cd ~/Code/pi-applet
./install.sh
```

The script

1. builds the applet (`applet/target/release/pi-applet`),
2. installs the binary, launcher, icons and `.desktop` file into `~/.local`,
3. adds the applet to the panel configuration (with a backup).

If the icon does not show up immediately, open
**Settings → Desktop → Panel → Add applet → "pi"**, or log out and back in once.

`build.sh` caches the `libxkbcommon-dev` package it may need under
`applet/target/build-deps/`, so repeated builds are incremental.

## Usage

Click the π icon in the panel. A terminal opens with pi. Other mouse buttons
have no special behaviour.

## Customisation

The launcher lives at `~/.local/bin/pi-applet-open` and can be edited directly.
Alternatively, set environment variables:

| Variable             | Default                | Meaning                             |
| -------------------- | ---------------------- | ----------------------------------- |
| `PI_APPLET_TERMINAL` | `cosmic-term`          | Terminal emulator                   |
| `PI_APPLET_DIR`      | `$HOME`                | Working directory                   |
| `PI_APPLET_PI`       | auto-detected          | Path to the `pi` executable         |
| `PI_APPLET_CMD`      | unset (fast path)      | Full command run by `zsh -ic`       |

The applet uses the launcher when it sits next to the binary (as installed by
`install.sh`). Without it, the applet starts `cosmic-term` directly with the
same defaults.

### Fast startup

By default the launcher resolves the `pi` executable (including nvm installs)
and runs it directly in the terminal. Without this, `zsh -ic` loads
oh-my-zsh, powerlevel10k, nvm and completion before `pi` even starts, which
takes about a second on a typical setup. The interactive zsh is only started
after `pi` exits. On the development machine this reduced click-to-pi from
about 1.3 s to about 0.4 s.

The fast path still runs through `zsh -c`, so `~/.zshenv` is loaded (tokens,
`JAVA_HOME`, `PATH` additions). Only the expensive interactive `~/.zshrc` is
skipped. If `pi` needs environment or shell setup from `~/.zshrc`, set
`PI_APPLET_CMD` to restore the old behaviour:

```sh
PI_APPLET_CMD='pi; exec /bin/zsh -i'
```

Example: always start pi in `~/Code`:

```sh
# e.g. in ~/.config/environment.d/pi-applet.conf
PI_APPLET_DIR="$HOME/Code"
```

## Uninstall

```sh
./uninstall.sh
```

Removes the binary, launcher, icons, desktop entry and panel entry (backups of
the panel configuration are kept).

## Project layout

```
pi-applet/
├── applet/
│   ├── Cargo.toml            # libcosmic dependency (pinned revision)
│   ├── Cargo.lock
│   ├── resources/
│   │   └── io.github.pmichailidis.PiApplet.desktop
│   └── src/
│       ├── main.rs
│       └── app.rs            # applet: click → terminal with pi
├── data/
│   ├── pi-applet.svg         # app icon
│   └── pi-applet-symbolic.svg
├── scripts/
│   ├── pi-applet-open        # terminal/shell launcher
│   └── panel-config.py       # edit the COSMIC panel configuration
├── build.sh
├── install.sh
├── uninstall.sh
└── Makefile
```

## Troubleshooting

- **Applet missing from "Add applet":** check that
  `~/.local/share/applications/io.github.pmichailidis.PiApplet.desktop` exists
  and contains `X-CosmicApplet=true`.
- **π icon not visible:** run
  `gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor` and log in again.
- **Terminal does not open:** run the binary directly to see the error:
  `~/.local/bin/pi-applet` (stop with Ctrl+C). Most common cause:
  `cosmic-term` is missing or the path in the `.desktop` file is wrong.
- **`pi` not found:** set `PI_APPLET_PI` to the output of
  `zsh -ic 'command -v pi'`, or set `PI_APPLET_CMD='pi; exec /bin/zsh -i'`
  to resolve `pi` through your normal zsh configuration.
- **Environment from `~/.zshrc` missing in pi:** set
  `PI_APPLET_CMD='pi; exec /bin/zsh -i'`. The fast path intentionally skips
  the interactive zsh startup; `~/.zshenv` is still loaded, but other shell
  setup happens only after pi exits.
- **Duplicate panel entry:** remove the extra applet in the panel settings;
  `uninstall.sh` only cleans up the entry it added itself.
