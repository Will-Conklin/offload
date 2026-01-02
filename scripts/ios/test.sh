#!/usr/bin/env bash
# Intent: Run deterministic iOS simulator tests with explicit destinations and captured result bundles.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/ios/Offload.xcodeproj}"
SCHEME="${SCHEME:-Offload}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DEVICE_NAME="${DEVICE_NAME:-iPhone 15}"
OS_VERSION="${OS_VERSION:-17.5}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/.ci/DerivedData}"
RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-${REPO_ROOT}/.ci/TestResults.xcresult}"

info() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

print_versions() {
  info "xcodebuild version:"
  xcodebuild -version || warn "Unable to read xcodebuild version."

  if command -v sw_vers >/dev/null 2>&1; then
    info "macOS version:"
    sw_vers
  else
    warn "sw_vers not available (expected on macOS)."
  fi
}

main() {
  print_versions
  "${SCRIPT_DIR}/preflight.sh"

  mkdir -p "$(dirname "${RESULT_BUNDLE_PATH}")"
  rm -rf "${RESULT_BUNDLE_PATH}"
  mkdir -p "${DERIVED_DATA_PATH}"

  info "Testing scheme '${SCHEME}' on '${DESTINATION}'."
  info "Result bundle: ${RESULT_BUNDLE_PATH}"
  info "DerivedData: ${DERIVED_DATA_PATH}"

  set +e
  xcodebuild \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -destination "${DESTINATION}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -resultBundlePath "${RESULT_BUNDLE_PATH}" \
    COMPILER_INDEX_STORE_ENABLE=NO \
    test
  status=$?
  set -e

  if [[ -d "${RESULT_BUNDLE_PATH}" ]]; then
    info "Result bundle saved to ${RESULT_BUNDLE_PATH}"
  else
    warn "Result bundle not found at ${RESULT_BUNDLE_PATH}"
  fi

  exit "${status}"
}

main "$@"
