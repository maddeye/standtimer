// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property var daemon: pluginService?.pluginDaemonInstances[pluginId] ?? null
    readonly property string phase: !daemon ? "Starting" : daemon.cycle.phase === "standing" ? "Stand" : "Sit"
    readonly property string remaining: {
        if (!daemon)
            return "--:--";
        const seconds = daemon.cycle.remainingSeconds;
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0");
    }
    readonly property bool paused: daemon !== null && !daemon.active
    readonly property string label: phase + " " + remaining + (paused ? " · Paused" : "")

    horizontalBarPill: Component {
        StyledText {
            text: root.label
            font.pixelSize: Theme.fontSizeSmall
            color: root.paused ? Theme.surfaceVariantText : Theme.surfaceText
            Accessible.name: root.label
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            StyledText {
                text: root.phase
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.remaining
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.paused
                text: "Paused"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
