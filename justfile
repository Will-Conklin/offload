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

security-deps:
    snyk test --all-projects

security-code:
    snyk code test

security: security-deps security-code
