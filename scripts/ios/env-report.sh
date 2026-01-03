#!/usr/bin/env bash
# Intent: Summarize iOS CI environment settings, tooling, and destinations for quick diagnostics.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/ios/Offload.xcodeproj}"
SCHEME="${SCHEME:-offload}"
DEVICE_NAME="${DEVICE_NAME:-iPhone 15}"
OS_VERSION="${OS_VERSION:-17.5}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/.ci/DerivedData}"
RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-${REPO_ROOT}/.ci/TestResults.xcresult}"

info() {
  echo "[INFO] $*"
}

print_versions() {
  info "xcodebuild version:"
  if ! xcodebuild -version; then
    echo "[WARN] Unable to read xcodebuild version. Is Xcode installed?" >&2
  fi

  if command -v sw_vers >/dev/null 2>&1; then
    info "macOS version:"
    sw_vers
  else
    echo "[WARN] sw_vers not available (expected on macOS)." >&2
  fi
}

main() {
  info "Project: ${PROJECT_PATH}"
  info "Scheme: ${SCHEME}"
  info "Destination: ${DESTINATION}"
  info "DerivedData: ${DERIVED_DATA_PATH}"
  info "Result bundle path: ${RESULT_BUNDLE_PATH}"

  print_versions

  info "Available destinations (filtered):"
  if xcodebuild -showdestinations -project "${PROJECT_PATH}" -scheme "${SCHEME}" 2>/dev/null | grep -E "iOS Simulator" | sed 's/^/  /'; then
    :
  else
    echo "[WARN] Unable to list destinations; ensure Xcode and simulators are installed." >&2
  fi
}

main "$@"
