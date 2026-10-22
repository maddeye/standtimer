// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

import QtQuick
import Quickshell.Io
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root
    property string result: "running"
    property var daemon: null
    property var savedData: null
    property int remaining: 0
    property int stage: 0

    function check(ok, message) {
        if (!ok)
            throw new Error(message);
    }

    function restore() {
        if (daemon && savedData) {
            daemon.loadPluginData();
            daemon.now = new Date();
        }
    }

    Timer {
        id: runner
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            try {
                if (root.stage === 0) {
                    root.daemon = PluginService.pluginDaemonInstances.standTimer;
                    root.check(!!root.daemon, "Stand timer must be enabled");
                    root.savedData = root.daemon.pluginData;
                    root.daemon.pluginData = Object.assign({}, root.savedData, {
                        scheduleEnabled: true, scheduleStart: "08:00", scheduleEnd: "20:00"
                    });
                    root.daemon.now = new Date(2026, 0, 1, 7, 59);
                    root.check(!root.daemon.scheduleAllowed && !root.daemon.active, "Must pause before start");
                    root.daemon.now = new Date(2026, 0, 1, 8, 0);
                    root.check(root.daemon.scheduleAllowed, "Must include start");
                    root.daemon.now = new Date(2026, 0, 1, 20, 0);
                    root.check(!root.daemon.scheduleAllowed && !root.daemon.active, "Must exclude end");
                    root.daemon.pluginData = Object.assign({}, root.savedData, {
                        scheduleEnabled: true, scheduleStart: "20:00", scheduleEnd: "08:00"
                    });
                    root.daemon.now = new Date(2026, 0, 1, 0, 0);
                    root.check(root.daemon.scheduleAllowed, "Overnight window must include midnight");
                    root.daemon.now = new Date(2026, 0, 1, 12, 0);
                    root.check(!root.daemon.scheduleAllowed, "Overnight window must exclude noon");

                    const component = Qt.createComponent("file://" + PluginService.availablePlugins.standTimer.settingsPath);
                    root.check(component.status === Component.Ready, component.errorString());
                    const settings = component.createObject(root, {width: 500});
                    root.check(!!settings, "Settings screen must instantiate");
                    const keys = [];
                    for (const control of settings.content) {
                        if (control.settingKey)
                            keys.push(control.settingKey);
                    }
                    for (const key of ["scheduleEnabled", "scheduleStart", "scheduleEnd"])
                        root.check(keys.indexOf(key) !== -1, "Missing settings control " + key);
                    settings.destroy();

                    const now = new Date();
                    const from = (now.getHours() + 1) % 24;
                    const until = (from + 1) % 24;
                    root.daemon.pluginData = Object.assign({}, root.savedData, {
                        scheduleEnabled: true, scheduleStart: from + ":00", scheduleEnd: until + ":00"
                    });
                    root.daemon.now = now;
                    root.check(!root.daemon.active, "Current time must be outside test window");
                    root.remaining = root.daemon.cycle.remainingSeconds;
                    root.stage = 1;
                } else {
                    root.check(root.daemon.cycle.remainingSeconds === root.remaining, "Real countdown must remain paused outside window");
                    root.restore();
                    root.result = "passed";
                    console.info("StandTimerScheduleCheck PASS boundaries, overnight window, settings controls, and live countdown pause");
                    runner.stop();
                }
            } catch (error) {
                root.restore();
                root.result = "failed: " + error.message;
                console.error("StandTimerScheduleCheck " + root.result);
                runner.stop();
            }
        }
    }

    Component.onDestruction: restore()

    IpcHandler {
        target: "standtimer-schedule-check"
        function status(): string { return root.result; }
    }
}
