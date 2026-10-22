# SPDX-FileCopyrightText: 2026 maddeye
# SPDX-License-Identifier: AGPL-3.0-or-later

VERSION := $(shell node -p "require('./plugin.json').version")
ARCHIVE := standtimer-v$(VERSION).tar.gz
OUT_DIR ?= dist
SOURCES := LICENSE README.md CHANGELOG.md Makefile plugin.json StandTimer.qml StandTimerSettings.qml StandTimerWidget.qml Timer.js scripts tests docs .github

.PHONY: test package

test:
	node --test tests/*.test.cjs

package:
	mkdir -p "$(OUT_DIR)"
	tar --create --gzip --file="$(OUT_DIR)/$(ARCHIVE)" --transform='s,^,StandTimer/,' -- $(SOURCES)
	cd "$(OUT_DIR)" && sha256sum "$(ARCHIVE)" > "$(ARCHIVE).sha256"
