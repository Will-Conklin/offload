#!/usr/bin/env bash
# Intent: Export pinned CI environment values for workflows and scripts.

set -euo pipefail

# Pinned CI environment values
export CI_MACOS_RUNNER="macos-14"
export CI_XCODE_VERSION="16.2"
export CI_SIM_DEVICE="iPhone 16"
export CI_SIM_OS="18.2"
