#!/usr/bin/env bash
# Intent: Deterministically build the Offload iOS app for CI with stable paths and simulator targets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/ci/readiness_env.sh"

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/ios/Offload.xcodeproj}"
SCHEME="${SCHEME:-offload}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DEVICE_NAME="${DEVICE_NAME:-${CI_SIM_DEVICE}}"
OS_VERSION="${OS_VERSION:-${CI_SIM_OS}}"
DESTINATION="${DESTINATION:-}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/.ci/DerivedData}"

info() {
  echo "[INFO] $*"
}

main() {
  local selection_output=""
  local selected_udid=""

  if ! selection_output="$("${SCRIPT_DIR}/select-simulator.sh")"; then
    echo "[ERROR] Failed to select simulator UDID." >&2
    exit 1
  fi

  selected_udid="$(printf "%s\n" "${selection_output}" | tail -n 1)"
  if [[ -z "${selected_udid}" ]]; then
    echo "[ERROR] Simulator UDID was not found in selection output." >&2
    exit 1
  fi

  DESTINATION="platform=iOS Simulator,id=${selected_udid}"

  while IFS= read -r line; do
    info "${line}"
  done <<<"${selection_output}"
  info "Resolved destination: ${DESTINATION}"

  DESTINATION="${DESTINATION}" DEVICE_NAME="${DEVICE_NAME}" OS_VERSION="${OS_VERSION}" "${SCRIPT_DIR}/preflight.sh"

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
