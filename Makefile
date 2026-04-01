.PHONY: install build test test-unit test-launcher start clean verify \
        build-macos build-deb build-rpm build-windows build-docker

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

build-macos:
	./build-macos.sh

build-deb:
	./build-deb.sh

build-rpm:
	./rpm/build-rpm.sh

build-windows:
	powershell -ExecutionPolicy Bypass -File ./build-windows.ps1

build-docker:
	./build-docker.sh

clean:
	rm -rf build-macos build-deb build-windows js/bundle.js
