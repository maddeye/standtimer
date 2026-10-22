// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const test = require("node:test");
const timer = vm.createContext({});
vm.runInContext(fs.readFileSync(require("node:path").join(__dirname, "../Timer.js"), "utf8"), timer);
const plain = value => JSON.parse(JSON.stringify(value));

test("only active seconds advance the cycle, with one transition at each deadline", () => {
    let state = timer.start(1);
    for (let i = 0; i < 59; i++)
        state = timer.tick(state, true, 1, 2);
    assert.deepEqual(plain(state), { phase: "sitting", remainingSeconds: 1 });
    for (let i = 0; i < 3600; i++)
        state = timer.tick(state, false, 1, 2);
    assert.deepEqual(plain(state), { phase: "sitting", remainingSeconds: 1 });
    state = timer.tick(state, true, 1, 2);
    assert.deepEqual(plain(state), { phase: "standing", remainingSeconds: 120 });
    state = timer.tick(state, false, 1, 2);
    assert.deepEqual(plain(state), { phase: "standing", remainingSeconds: 120 });
    for (let i = 0; i < 120; i++)
        state = timer.tick(state, true, 1, 2);
    assert.deepEqual(plain(state), { phase: "sitting", remainingSeconds: 60 });
});

test("daily window includes its start and excludes its end", () => {
    for (const [minute, expected] of [[479, false], [480, true], [1199, true], [1200, false]])
        assert.equal(timer.withinSchedule(true, "08:00", "20:00", minute), expected);
    assert.equal(timer.withinSchedule(false, "08:00", "20:00", 0), true);
});

test("overnight window crosses midnight without allowing the daytime gap", () => {
    for (const [minute, expected] of [[1199, false], [1200, true], [1439, true], [0, true], [479, true], [480, false]])
        assert.equal(timer.withinSchedule(true, "20:00", "08:00", minute), expected);
});

test("time fields accept local clock times and reject malformed settings", () => {
    assert.equal(timer.timeOfDay("00:00"), 0);
    assert.equal(timer.timeOfDay("8:00"), 480);
    assert.equal(timer.timeOfDay("23:59"), 1439);
    for (const value of [undefined, null, 800, {}, "", "24:00", "08:60", "8:0", "08:00pm", " 08:00", "08:00\n"])
        assert.equal(timer.timeOfDay(value), -1);
    assert.equal(timer.withinSchedule(true, "bad", "20:00", 600), false);
    assert.equal(timer.withinSchedule(true, "08:00", "bad", 600), false);
    assert.equal(timer.withinSchedule(true, "08:00", "08:00", 600), false);
    assert.equal(timer.withinSchedule(false, "bad", "bad", 600), true);
});

test("leaving the daily window pauses the countdown and resumes it without a reset", () => {
    let state = { phase: "sitting", remainingSeconds: 1 };
    state = timer.tick(state, timer.withinSchedule(true, "08:00", "20:00", 1200), 45, 10);
    assert.deepEqual(plain(state), { phase: "sitting", remainingSeconds: 1 });
    state = timer.tick(state, timer.withinSchedule(true, "08:00", "20:00", 480), 45, 10);
    assert.deepEqual(plain(state), { phase: "standing", remainingSeconds: 600 });
});

test("reset discards a partial cycle", () => {
    const state = timer.tick(timer.start(3), true, 3, 2);
    assert.deepEqual(plain(state), { phase: "sitting", remainingSeconds: 179 });
    assert.deepEqual(plain(timer.start(4)), { phase: "sitting", remainingSeconds: 240 });
});

test("settings reject malformed values and clamp to supported durations", () => {
    for (const value of [undefined, null, "5", NaN, Infinity, {}, true])
        assert.equal(timer.minutes(value, 45, 240), 45);
    assert.equal(timer.minutes(-2, 45, 240), 1);
    assert.equal(timer.minutes(300, 45, 240), 240);
    assert.equal(timer.minutes(2.7, 45, 240), 3);
});
