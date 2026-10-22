// SPDX-FileCopyrightText: 2026 maddeye
// SPDX-License-Identifier: AGPL-3.0-or-later

const assert = require("node:assert/strict");
const { version } = require("../plugin.json");

assert.equal(process.env.GITHUB_REF_NAME, `v${version}`, "Release tag must match the version in plugin.json");
