// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

import QtQuick
import Quickshell.Io
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root
    property string result: "running"

    QtObject {
        id: fakeDaemon
        property var cycle: ({phase: "sitting", remainingSeconds: 372})
        property bool active: true
    }

    QtObject {
        id: fakeService
        property var pluginDaemonInstances: ({standTimer: fakeDaemon})
        signal pluginDataChanged(string pluginId)
        function getPluginVariants(pluginId) { return []; }
    }

    function assertEqual(actual, expected) {
        if (actual !== expected)
            throw new Error("Expected " + expected + ", got " + actual);
    }

    function run() {
        const component = PluginService.pluginWidgetComponents.standTimer;
        const widgets = [];
        try {
            if (!component)
                throw new Error("Enable Stand timer before running the widget check");
            for (let i = 0; i < 2; i++) {
                const widget = component.createObject(root, {pluginId: "standTimer", pluginService: fakeService});
                if (!widget)
                    throw new Error(component.errorString());
                widgets.push(widget);
                assertEqual(widget.label, "Sit 6:12");
                const horizontal = widget.horizontalBarPill.createObject(root);
                assertEqual(horizontal.text, "Sit 6:12");
                horizontal.destroy();
            }
            fakeDaemon.active = false;
            assertEqual(widgets[0].label, "Sit 6:12 · Paused");
            assertEqual(widgets[1].label, "Sit 6:12 · Paused");
            fakeDaemon.cycle = {phase: "standing", remainingSeconds: 9};
            assertEqual(widgets[0].label, "Stand 0:09 · Paused");
            fakeDaemon.active = true;
            assertEqual(widgets[1].label, "Stand 0:09");
            const vertical = widgets[0].verticalBarPill.createObject(root);
            assertEqual(vertical.children[0].text, "Stand");
            assertEqual(vertical.children[1].text, "0:09");
            assertEqual(vertical.children[2].visible, false);
            fakeDaemon.active = false;
            assertEqual(vertical.children[2].visible, true);
            vertical.destroy();
            fakeDaemon.cycle = {phase: "sitting", remainingSeconds: 14400};
            assertEqual(widgets[0].remaining, "240:00");
            fakeService.pluginDaemonInstances = {};
            assertEqual(widgets[0].label, "Starting --:--");
            fakeService.pluginDaemonInstances = {standTimer: fakeDaemon};
            assertEqual(widgets[0].label, "Sit 240:00 · Paused");
            result = "passed";
            console.info("StandTimerWidgetCheck PASS countdown, phase, pause, orientations, shared state, and daemon replacement");
        } catch (error) {
            result = "failed: " + error.message;
            console.error("StandTimerWidgetCheck " + result);
        } finally {
            for (const widget of widgets)
                widget.destroy();
        }
    }

    Component.onCompleted: Qt.callLater(run)

    IpcHandler {
        target: "standtimer-widget-check"
        function status(): string { return root.result; }
    }
}
