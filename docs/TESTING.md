# Check the plugin in DMS

Run these checks on a Linux Wayland desktop with Stand timer installed and enabled.
Run all commands from the project root.

## Run automated checks

```sh
make test
```

This runs the timer tests and builds, extracts, and checks a release archive.
The headless tests do not run QML or send desktop notifications.

## Run live QML checks

1. Install the temporary test plugin links.

```sh
plugins="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"
ln -sT "$PWD/tests/widget-check" "$plugins/StandTimerWidgetCheck"
ln -sT "$PWD/tests/schedule-check" "$plugins/StandTimerScheduleCheck"
dms ipc call plugin-scan scan
```

2. After DMS discovers the test plugins, enable them.

```sh
dms ipc call plugins enable standTimerWidgetCheck
dms ipc call plugins enable standTimerScheduleCheck
```

3. Wait three seconds, then query their results. Both commands must report `passed`.

```sh
dms ipc call standtimer-widget-check status
dms ipc call standtimer-schedule-check status
```

The widget check uses a fake timer. It checks countdown formatting, phases, pauses, both bar orientations, and shared state.
The schedule check temporarily changes the running daemon's in-memory schedule and restores it afterward.
It checks local-time boundaries, overnight windows, settings controls, and countdown pausing without changing your saved configuration or system clock.

4. Disable the helpers and remove only their installation links.

```sh
dms ipc call plugins disable standTimerWidgetCheck
dms ipc call plugins disable standTimerScheduleCheck
unlink "$plugins/StandTimerWidgetCheck"
unlink "$plugins/StandTimerScheduleCheck"
dms ipc call plugin-scan scan
```

## Check reminders manually

Set both durations to one minute. Stay active until the standing and sitting reminders appear.
Then restore your preferred durations. Check idle pausing through `dms ipc call standtimer status`.
To check a schedule, enable a window that excludes the current local time and confirm that the countdown stops.

Inspect the bar widget on your target screen. QML assertions do not replace a visual layout check.
Lock, unlock, and suspend transitions still need manual testing on the target compositor.
