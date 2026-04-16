.PHONY: install build test test-unit test-launcher check ci start clean verify \
        build-macos build-deb build-rpm build-windows build-docker

# Resolve npm so it works whether Node is on PATH or in .tools/
NPM := $(shell command -v npm 2>/dev/null || echo "npm")

install:
	$(NPM) install

build: install
	$(NPM) run build

test: test-unit test-launcher

# Same gate as .github/workflows/code-review.yml (uses npm install + local deps, not npm ci)
check: install
	$(NPM) run build
	$(NPM) run lint
	$(NPM) run typecheck
	$(NPM) run test:unit
	$(NPM) run test:launcher
	./scripts/code-review.sh

ci:
	npm ci
	npm run build
	npm run lint
	npm run typecheck
	npm run test:unit
	npm run test:launcher
	./scripts/code-review.sh

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
