// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

const assert = require("node:assert/strict");
const { createHash } = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");
const root = path.resolve(__dirname, "..");

function run(command, args) {
    const result = spawnSync(command, args, { cwd: root, encoding: "utf8" });
    assert.equal(result.status, 0, result.error?.message || result.stdout + result.stderr);
    return result.stdout;
}

test("release archive contains installable source, its license, and a portable checksum", () => {
    const output = fs.mkdtempSync(path.join(os.tmpdir(), "standtimer-release-"));
    try {
        run("make", ["package", `OUT_DIR=${output}`]);
        const version = JSON.parse(fs.readFileSync(path.join(root, "plugin.json"), "utf8")).version;
        const name = `standtimer-v${version}.tar.gz`;
        const archive = path.join(output, name);
        const members = run("tar", ["--list", "--gzip", "--file", archive]).trim().split("\n");
        assert.ok(members.every(member => member.startsWith("StandTimer/") && !member.split("/").includes("..")));
        assert.ok(!members.some(member => /(^|\/)(\.git|dist)(\/|$)/.test(member)));
        const unpacked = path.join(output, "unpacked");
        fs.mkdirSync(unpacked);
        run("tar", ["--extract", "--gzip", "--file", archive, "--directory", unpacked]);
        const plugin = path.join(unpacked, "StandTimer");
        const manifest = JSON.parse(fs.readFileSync(path.join(plugin, "plugin.json"), "utf8"));
        assert.equal(manifest.license, "AGPL-3.0-or-later");
        assert.equal(manifest.requires_dms, ">=1.6.1");
        for (const file of [...Object.values(manifest.components), manifest.settings, "Timer.js"]) {
            const shipped = fs.readFileSync(path.join(plugin, file), "utf8");
            assert.match(shipped, /SPDX-License-Identifier: AGPL-3\.0-or-later/);
            assert.equal(shipped, fs.readFileSync(path.join(root, file), "utf8"));
        }
        const license = fs.readFileSync(path.join(plugin, "LICENSE"), "utf8");
        assert.match(license, /GNU AFFERO GENERAL PUBLIC LICENSE/);
        assert.match(license, /13\. Remote Network Interaction/);
        assert.equal(license, fs.readFileSync(path.join(root, "LICENSE"), "utf8"));
        assert.ok(fs.existsSync(path.join(plugin, "Makefile")));
        assert.ok(fs.existsSync(path.join(plugin, "tests", "timer.test.cjs")));
        const hash = createHash("sha256").update(fs.readFileSync(archive)).digest("hex");
        assert.equal(fs.readFileSync(archive + ".sha256", "utf8"), `${hash}  ${name}\n`);
    } finally {
        fs.rmSync(output, { recursive: true, force: true });
    }
});
