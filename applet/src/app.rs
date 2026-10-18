//! pi-applet – a COSMIC panel applet that opens a terminal with zsh + pi.

use std::process::{Command, Stdio};

use cosmic::app::{Core, Task};
use cosmic::surface::Action as SurfaceAction;
use cosmic::Element;

/// Reverse-DNS id. Must match the name of the installed `.desktop` file
/// (`io.github.pmichailidis.PiApplet.desktop`).
const APP_ID: &str = "io.github.pmichailidis.PiApplet";

/// Fallback command used when the user-editable wrapper script
/// `pi-applet-open` (installed next to this binary) is not present.
const SHELL_COMMAND: &str = "pi; exec /bin/zsh -i";

pub struct AppModel {
    core: Core,
}

#[derive(Debug, Clone)]
pub enum Message {
    /// Open a new terminal window running pi.
    OpenPi,
    /// Required by the tooltip widget that draws outside the panel.
    Surface(SurfaceAction<Message>),
}

impl cosmic::Application for AppModel {
    type Executor = cosmic::executor::Default;
    type Flags = ();
    type Message = Message;

    const APP_ID: &'static str = APP_ID;

    fn core(&self) -> &Core {
        &self.core
    }

    fn core_mut(&mut self) -> &mut Core {
        &mut self.core
    }

    fn init(core: Core, _flags: Self::Flags) -> (Self, Task<Self::Message>) {
        (Self { core }, Task::none())
    }

    fn update(&mut self, message: Self::Message) -> Task<Self::Message> {
        match message {
            Message::OpenPi => {
                if let Err(err) = open_pi() {
                    eprintln!("pi-applet: failed to open terminal: {err}");
                }
                Task::none()
            }
            Message::Surface(action) => cosmic::task::message(cosmic::Action::Surface(action)),
        }
    }

    fn view(&self) -> Element<'_, Self::Message> {
        let button = self
            .core
            .applet
            .icon_button("pi-applet-symbolic")
            .on_press(Message::OpenPi);

        self.core
            .applet
            .applet_tooltip::<Message>(
                button,
                "pi öffnen",
                false,
                Message::Surface,
                None,
            )
            .into()
    }

    fn style(&self) -> Option<cosmic::iced::theme::Style> {
        Some(cosmic::applet::style())
    }
}

/// Spawn the launcher wrapper if installed, otherwise talk to cosmic-term
/// directly. Both variants return immediately; the terminal runs detached.
fn open_pi() -> std::io::Result<()> {
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            let launcher = dir.join("pi-applet-open");
            if launcher.is_file() {
                let mut cmd = Command::new(launcher);
                return spawn_detached(&mut cmd);
            }
        }
    }

    // cosmic-term supports `-- <command> <args...>`.
    let home = std::env::var("HOME").unwrap_or_else(|_| "/".to_owned());
    let mut cmd = Command::new("cosmic-term");
    cmd.arg("-w")
        .arg(home)
        .arg("--")
        .arg("/bin/zsh")
        .arg("-ic")
        .arg(SHELL_COMMAND);
    spawn_detached(&mut cmd)
}

fn spawn_detached(cmd: &mut Command) -> std::io::Result<()> {
    let mut child = cmd
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()?;

    // cosmic-term daemonizes, so the spawned process exits almost immediately.
    // Reap it in the background; otherwise every click leaves a zombie behind.
    std::thread::spawn(move || {
        let _ = child.wait();
    });

    Ok(())
}
