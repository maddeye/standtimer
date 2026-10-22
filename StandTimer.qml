// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import qs.Services
import qs.Modules.Plugins
import "Timer.js" as TimerLogic

PluginComponent {
    id: root

    readonly property int sittingMinutes: TimerLogic.minutes(pluginData.sittingMinutes, 45, 240)
    readonly property int standingMinutes: TimerLogic.minutes(pluginData.standingMinutes, 10, 120)
    readonly property int idleSeconds: TimerLogic.minutes(pluginData.idleSeconds, 60, 600)
    readonly property bool scheduleEnabled: pluginData.scheduleEnabled === true
    readonly property string scheduleStart: pluginData.scheduleStart ?? "08:00"
    readonly property string scheduleEnd: pluginData.scheduleEnd ?? "20:00"
    property date now: new Date()
    readonly property bool scheduleAllowed: TimerLogic.withinSchedule(
        scheduleEnabled, scheduleStart, scheduleEnd, now.getHours() * 60 + now.getMinutes())
    readonly property bool active: scheduleAllowed && !activity.isIdle && !IdleService.isShellLocked
    property var cycle: TimerLogic.start(sittingMinutes)

    onSittingMinutesChanged: Qt.callLater(resetCycle)
    onStandingMinutesChanged: Qt.callLater(resetCycle)

    function resetCycle() {
        cycle = TimerLogic.start(sittingMinutes);
    }

    IdleMonitor {
        id: activity
        timeout: root.idleSeconds
        // Video playback and idle inhibitors do not count as user input.
        respectInhibitors: false
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.now = new Date();
            const next = TimerLogic.tick(root.cycle, root.active, root.sittingMinutes, root.standingMinutes);
            const changed = next.phase !== root.cycle.phase;
            root.cycle = next;
            if (!changed)
                return;
            const standing = next.phase === "standing";
            reminder.command = [
                "dms", "notify",
                standing ? "Time to stand up" : "Standing time complete",
                standing ? "Raise your desk and stand for " + root.standingMinutes + " active minutes."
                         : "You can sit down. Next standing reminder in " + root.sittingMinutes + " active minutes.",
                "--app", "Stand timer", "--icon", "preferences-desktop-accessibility",
                "--timeout", "15000"
            ];
            reminder.running = true;
        }
    }

    Process {
        id: reminder
        onExited: exitCode => {
            if (exitCode !== 0)
                ToastService.showError("Stand timer could not send a reminder", "dms notify exited with code " + exitCode);
        }
    }

    IpcHandler {
        target: "standtimer"

        function status(): string {
            return JSON.stringify({
                phase: root.cycle.phase,
                remainingSeconds: root.cycle.remainingSeconds,
                active: root.active,
                idle: activity.isIdle,
                locked: IdleService.isShellLocked,
                sittingMinutes: root.sittingMinutes,
                standingMinutes: root.standingMinutes,
                idleSeconds: root.idleSeconds,
                scheduleEnabled: root.scheduleEnabled,
                scheduleStart: root.scheduleStart,
                scheduleEnd: root.scheduleEnd,
                scheduleAllowed: root.scheduleAllowed
            });
        }

        function reset(): string {
            root.resetCycle();
            return "Sitting cycle restarted";
        }
    }
}
