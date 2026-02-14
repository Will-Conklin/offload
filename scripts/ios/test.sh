#!/usr/bin/env bash
# Intent: Run deterministic iOS simulator tests with explicit destinations and captured result bundles.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/ci/readiness-env.sh"

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/ios/Offload.xcodeproj}"
SCHEME="${SCHEME:-Offload}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DEVICE_NAME="${DEVICE_NAME:-${CI_SIM_DEVICE}}"
OS_VERSION="${OS_VERSION:-${CI_SIM_OS}}"
DESTINATION="${DESTINATION:-}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/.ci/DerivedData}"
RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-${REPO_ROOT}/.ci/TestResults.xcresult}"
CI_FULL_RUN="${CI_FULL_RUN:-false}"

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

  local selection_output=""
  local selected_udid=""

  if ! selection_output="$("${SCRIPT_DIR}/select-simulator.sh")"; then
    warn "Failed to select simulator UDID."
    exit 1
  fi

  selected_udid="$(printf "%s\n" "${selection_output}" | tail -n 1)"
  if [[ -z "${selected_udid}" ]]; then
    warn "Simulator UDID was not found in selection output."
    exit 1
  fi

  DESTINATION="platform=iOS Simulator,id=${selected_udid}"

  while IFS= read -r line; do
    info "${line}"
  done <<<"${selection_output}"
  info "Resolved destination: ${DESTINATION}"

  DESTINATION="${DESTINATION}" DEVICE_NAME="${DEVICE_NAME}" OS_VERSION="${OS_VERSION}" "${SCRIPT_DIR}/preflight.sh"

  # Boot the simulator before running tests to prevent timeout errors
  info "Booting simulator before running tests..."
  if ! "${SCRIPT_DIR}/boot-simulator.sh" "${selected_udid}"; then
    warn "Failed to boot simulator ${selected_udid}"
    exit 1
  fi

  mkdir -p "$(dirname "${RESULT_BUNDLE_PATH}")"
  rm -rf "${RESULT_BUNDLE_PATH}"
  mkdir -p "${DERIVED_DATA_PATH}"

  info "Testing scheme '${SCHEME}' on '${DESTINATION}'."
  info "Result bundle: ${RESULT_BUNDLE_PATH}"
  info "DerivedData: ${DERIVED_DATA_PATH}"

  local full_run=false
  case "${CI_FULL_RUN}" in
    true|TRUE|True|1|yes|YES|Yes)
      full_run=true
      ;;
  esac

  if [[ "${full_run}" == "true" ]]; then
    info "Full CI test mode enabled: running complete scheme tests with coverage."
  else
    info "Fast CI test mode enabled: running unit tests only and skipping performance benchmarks."
  fi

  set +e
  if [[ "${full_run}" == "true" ]]; then
    xcodebuild \
      -project "${PROJECT_PATH}" \
      -scheme "${SCHEME}" \
      -configuration "${CONFIGURATION}" \
      -destination "${DESTINATION}" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      -resultBundlePath "${RESULT_BUNDLE_PATH}" \
      -enableCodeCoverage YES \
      COMPILER_INDEX_STORE_ENABLE=NO \
      test
  else
    xcodebuild \
      -project "${PROJECT_PATH}" \
      -scheme "${SCHEME}" \
      -configuration "${CONFIGURATION}" \
      -destination "${DESTINATION}" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      -resultBundlePath "${RESULT_BUNDLE_PATH}" \
      -enableCodeCoverage NO \
      -only-testing:OffloadTests \
      -skip-testing:OffloadTests/PerformanceBenchmarkTests \
      COMPILER_INDEX_STORE_ENABLE=NO \
      test
  fi
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
