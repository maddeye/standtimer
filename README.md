# Stand timer for DankMaterialShell

A background plugin that reminds you to stand, then tells you when your standing time is complete.

## Requirements

- Linux with DankMaterialShell 1.6.1 or later and its Quickshell runtime.
- A compositor with Wayland idle-notify support.
- The `dms` command available in your shell's `PATH`.

Tested on Niri with DMS 1.6.1. No extra runtime packages or build step are needed.

## Install and configure

1. Extract the release archive and open a terminal inside its `StandTimer` directory. For a Git checkout, use the project root.

Keep this directory in a permanent location. The installation links to it.

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"
ln -sT "$PWD" "${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins/StandTimer"
dms ipc call plugin-scan scan
```

The link command refuses to replace an existing installation. To update one, follow the update instructions below.

2. Open DMS settings.

```sh
dms ipc call settings openWith plugins
```

3. Enable **Stand timer** and expand its settings.
4. Set the sitting duration, standing duration, and idle delay.

## Show the optional bar widget

1. Open DMS settings and select **Bar → Widgets**.
2. Add **Stand timer** to the bar section you want.

The widget shows the current phase, remaining minutes and seconds, and whether the timer is paused.
It supports horizontal and vertical bars. Each widget reads the same background timer, including on multiple screens.
Removing the widget does not stop reminders.

## Limit reminders to part of the day

1. Open **Plugins → Stand timer** in DMS settings.
2. Set **Active from** and **Active until**, for example `08:00` and `20:00`.
3. Enable **Use a daily time window**.

The window uses your computer's local time. The start is included and the end is excluded.
An end before the start creates an overnight window, such as `20:00` to `08:00`.
Outside the window, the countdown pauses without sending reminders. It resumes from the same remaining time inside the next window, once you are active.
Invalid times or identical start and end times keep the timer paused while the window option is enabled.
The option is off by default. Disable it to allow reminders at any time.

## Timer behavior

The defaults are 45 minutes sitting, 10 minutes standing, and a 60-second idle delay.
Both durations count active computer time. After the idle delay, the timer pauses until you use the keyboard or pointer.
The timer also pauses while DMS locks the screen. Media playback and idle inhibitors do not count as activity.

A reminder starts the next phase automatically. The plugin cannot detect whether you actually stand.
Desktop notifications follow your DMS notification and Do Not Disturb settings.

Changing either duration restarts the sitting cycle. Restarting DMS or reloading the plugin also starts a new sitting cycle.
Configuration persists through DMS. Countdown progress does not persist.
The timer counts one second per tick rather than adding elapsed wall time, so suspension does not cause catch-up reminders.

## Inspect or reset the timer

```sh
dms ipc call standtimer status
dms ipc call standtimer reset
```

## Update or remove the plugin

To update, replace the source files in the linked directory with a new release. For a Git checkout, run `git pull --ff-only`.
Then run `dms restart`. A full restart avoids stale QML imports. Your settings remain, but the countdown starts over.

To remove the installation link, run these commands. Your saved settings remain.

```sh
dms ipc call plugins disable standTimer
unlink "${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins/StandTimer"
dms ipc call plugin-scan scan
```

## Test and package

Development requires Node.js 24 or later, GNU Make, GNU tar, and `sha256sum`.
No npm packages are needed.

```sh
make test
make package
```

The archive and its SHA-256 checksum are written to `dist/`.
The archive includes the plugin's source, tests, documentation, and license.
CI runs the same commands and uploads the archive as a workflow artifact.
Pushing a version tag such as `v1.2.0` also publishes a GitHub release with the archive and checksum attached.
The tag must match the version in `plugin.json`, and all checks must pass before publishing.

See [live DMS checks](docs/TESTING.md) and [publishing a release](docs/RELEASING.md).
Known limits include loss of countdown progress on restart and reminders hidden by Do Not Disturb.
Lock and suspend transitions have not been exercised end to end.
