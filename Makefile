.PHONY: install build test test-unit test-launcher start clean verify

# Resolve npm so it works whether Node is on PATH or in .tools/
NPM := $(shell command -v npm 2>/dev/null || echo "npm")

install:
	$(NPM) install

build: install
	$(NPM) run build

test: test-unit test-launcher

test-unit: install
	$(NPM) run test:unit

test-launcher:
	$(NPM) run test:launcher

start: install
	$(NPM) start

verify:
	$(NPM) run verify:nw

clean:
	rm -rf build-macos build-deb js/bundle.js
