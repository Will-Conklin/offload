#!/usr/bin/env bash
# Intent: Deterministically build the Offload iOS app for CI with stable paths and simulator targets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/ci/readiness_env.sh"

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/ios/Offload.xcodeproj}"
SCHEME="${SCHEME:-Offload}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DEVICE_NAME="${DEVICE_NAME:-${CI_SIM_DEVICE}}"
OS_VERSION="${OS_VERSION:-${CI_SIM_OS}}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/.ci/DerivedData}"

info() {
  echo "[INFO] $*"
}

main() {
  "${SCRIPT_DIR}/preflight.sh"

  mkdir -p "${DERIVED_DATA_PATH}"

  info "Building scheme '${SCHEME}' with configuration '${CONFIGURATION}'."
  info "DerivedData: ${DERIVED_DATA_PATH}"
  info "Destination: ${DESTINATION}"

  xcodebuild \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -destination "${DESTINATION}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    COMPILER_INDEX_STORE_ENABLE=NO \
    build
}

main "$@"
