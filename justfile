set shell := ["zsh", "-lc"]

default:
    @just --list

xcode-open:
    open ios/Offload.xcodeproj

build:
    xcodebuild -project ios/Offload.xcodeproj -scheme Offload -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath .derivedData/xcodebuild build

test:
    source scripts/ci/readiness-env.sh && destination="platform=iOS Simulator,OS=${CI_SIM_OS},name=${CI_SIM_DEVICE}" && if [[ -n "${CI_SIM_ARCH:-}" ]]; then destination="${destination},arch=${CI_SIM_ARCH}"; fi && xcodebuild test -project ios/Offload.xcodeproj -scheme Offload -destination "${destination}" -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 -derivedDataPath .derivedData/xcodebuild

lint-docs:
    markdownlint --fix .

lint-yaml:
    yamllint .

lint: lint-docs lint-yaml

backend-install:
    python3 -m pip install -e 'backend/api[dev]'

backend-install-uv:
    uv sync --project backend/api --extra dev

backend-lint:
    python3 -m ruff check backend/api/src backend/api/tests

backend-test:
    python3 -m pytest backend/api/tests -q

backend-test-coverage:
    python3 -m pytest backend/api/tests -q --cov=offload_backend --cov-report=term-missing:skip-covered

backend-check-coverage: backend-lint backend-typecheck backend-test-coverage

backend-typecheck:
    python3 -m ty check backend/api/src backend/api/tests

backend-check: backend-lint backend-typecheck backend-test

backend-clean:
    rm -rf .offload-backend backend/api/.offload-backend backend/api/src/offload_backend_api.egg-info

backend-check-ci:
    bash scripts/ci/backend-checks.sh

ios-test-ci:
    bash scripts/ios/test.sh

ci-local:
    just lint && just backend-check && just test

security-deps:
    snyk test --all-projects

security-code:
    snyk code test

security: security-deps security-code
