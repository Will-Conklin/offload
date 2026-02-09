set shell := ["zsh", "-lc"]

default:
    @just --list

xcode-open:
    open ios/Offload.xcodeproj

build:
    xcodebuild -project ios/Offload.xcodeproj -scheme Offload -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath .derivedData/xcodebuild build

test:
    source scripts/ci/readiness-env.sh && xcodebuild test -project ios/Offload.xcodeproj -scheme Offload -destination "platform=iOS Simulator,name=${CI_SIM_DEVICE}" -derivedDataPath .derivedData/xcodebuild

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
