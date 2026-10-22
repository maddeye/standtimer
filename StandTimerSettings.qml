// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "Timer.js" as TimerLogic

PluginSettings {
    pluginId: "standTimer"

    StyledText {
        width: parent.width
        text: "Alternate sitting and standing reminders. Both timers pause without keyboard or pointer activity, or while the screen is locked. Changing a duration restarts the sitting cycle."
        wrapMode: Text.WordWrap
        color: Theme.surfaceText
    }

    ToggleSetting {
        id: scheduleToggle
        settingKey: "scheduleEnabled"
        label: "Use a daily time window"
        description: "Pause outside these local times. Overnight windows are supported. Activity detection still applies inside the window."
        defaultValue: false
    }

    StringSetting {
        id: startTime
        settingKey: "scheduleStart"
        label: "Active from"
        description: "24-hour local time, HH:MM."
        placeholder: "08:00"
        defaultValue: "08:00"
    }

    StringSetting {
        id: endTime
        settingKey: "scheduleEnd"
        label: "Active until"
        description: "The timer pauses at this time and resumes at the next start time."
        placeholder: "20:00"
        defaultValue: "20:00"
    }

    StyledText {
        width: parent.width
        visible: scheduleToggle.value && (TimerLogic.timeOfDay(startTime.value) < 0
            || TimerLogic.timeOfDay(endTime.value) < 0
            || TimerLogic.timeOfDay(startTime.value) === TimerLogic.timeOfDay(endTime.value))
        text: "Enter valid times as HH:MM. Start and end must differ. The timer stays paused until corrected."
        wrapMode: Text.WordWrap
        color: Theme.error
    }

    SliderSetting {
        settingKey: "sittingMinutes"
        label: "Remind me to stand after"
        defaultValue: 45
        minimum: 1
        maximum: 240
        unit: " min"
    }

    SliderSetting {
        settingKey: "standingMinutes"
        label: "Standing duration"
        defaultValue: 10
        minimum: 1
        maximum: 120
        unit: " min"
    }

    SliderSetting {
        settingKey: "idleSeconds"
        label: "Pause after no input for"
        description: "Reading without input counts as idle after this delay. Video playback does not keep the timer active."
        defaultValue: 60
        minimum: 1
        maximum: 600
        unit: " s"
    }
}
