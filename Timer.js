// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

function minutes(value, fallback, maximum) {
    return typeof value === "number" && isFinite(value)
        ? Math.max(1, Math.min(maximum, Math.round(value))) : fallback;
}

function timeOfDay(value) {
    if (typeof value !== "string" || !/^([01]?\d|2[0-3]):[0-5]\d$/.test(value))
        return -1;
    const parts = value.split(":");
    return Number(parts[0]) * 60 + Number(parts[1]);
}

function withinSchedule(enabled, start, end, minute) {
    if (!enabled)
        return true;
    const from = timeOfDay(start);
    const until = timeOfDay(end);
    if (from < 0 || until < 0 || from === until)
        return false;
    return from < until ? minute >= from && minute < until : minute >= from || minute < until;
}

function start(sittingMinutes) {
    return { phase: "sitting", remainingSeconds: sittingMinutes * 60 };
}

function tick(state, active, sittingMinutes, standingMinutes) {
    if (!active)
        return state;
    if (state.remainingSeconds > 1)
        return { phase: state.phase, remainingSeconds: state.remainingSeconds - 1 };
    const phase = state.phase === "sitting" ? "standing" : "sitting";
    return {
        phase: phase,
        remainingSeconds: (phase === "standing" ? standingMinutes : sittingMinutes) * 60
    };
}
