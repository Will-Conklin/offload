#!/usr/bin/env bash
# Intent: Validate iOS CI readiness by checking tooling, scheme availability, and simulator destinations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/ci/readiness-env.sh"

SIMCTL_RUNTIMES_OUTPUT=""
SIMCTL_DEVICES_OUTPUT=""
DESTINATIONS_OUTPUT=""

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/ios/Offload.xcodeproj}"
SCHEME="${SCHEME:-Offload}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DEVICE_NAME="${DEVICE_NAME:-${CI_SIM_DEVICE}}"
OS_VERSION="${OS_VERSION:-${CI_SIM_OS}}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}}"

err() {
  echo "[ERROR] $*" >&2
}

info() {
  echo "[INFO] $*"
}

log_pinned_destination() {
  info "Pinned simulator device: ${CI_SIM_DEVICE}"
  info "Pinned simulator OS: ${CI_SIM_OS}"
}

log_toolchain_context() {
  echo "[INFO] sw_vers"
  if command -v sw_vers >/dev/null 2>&1; then
    sw_vers || true
  else
    echo "sw_vers not available"
  fi

  echo "[INFO] xcodebuild -version"
  if command -v xcodebuild >/dev/null 2>&1; then
    xcodebuild -version || true
  else
    echo "xcodebuild not available"
  fi
}

log_simulator_inventory() {
  if command -v xcrun >/dev/null 2>&1; then
    echo "[INFO] xcrun simctl list runtimes"
    SIMCTL_RUNTIMES_OUTPUT="$(xcrun simctl list runtimes || true)"
    printf "%s\n" "${SIMCTL_RUNTIMES_OUTPUT}"

    echo "[INFO] xcrun simctl list devices"
    SIMCTL_DEVICES_OUTPUT="$(xcrun simctl list devices || true)"
    printf "%s\n" "${SIMCTL_DEVICES_OUTPUT}"
  else
    err "xcrun not available"
  fi
}

print_diagnostics() {
  echo "[DIAG] sw_vers"
  if command -v sw_vers >/dev/null 2>&1; then
    sw_vers || true
  else
    echo "sw_vers not available"
  fi

  echo "[DIAG] xcodebuild -version"
  if command -v xcodebuild >/dev/null 2>&1; then
    xcodebuild -version || true
  else
    echo "xcodebuild not available"
  fi

  if command -v xcrun >/dev/null 2>&1; then
    echo "[DIAG] simctl list runtimes"
    xcrun simctl list runtimes || true
    echo "[DIAG] simctl list devices"
    xcrun simctl list devices || true
  else
    echo "[DIAG] xcrun not available"
  fi
}

require_command() {
  local command_name=$1
  local install_hint=$2

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    err "Missing required command: ${command_name}"
    err "Install hint: ${install_hint}"
    exit 1
  fi
}

assert_scheme_exists() {
  log_toolchain_context

  local list_output
  local list_stderr
  local list_status=0
  list_stderr="$(mktemp -t xcodebuild-list-stderr)"

  if ! list_output="$(xcodebuild -list -project "${PROJECT_PATH}" 2>"${list_stderr}")"; then
    list_status=$?
    err "Unable to list schemes for ${PROJECT_PATH}"
    err "xcodebuild command: xcodebuild -list -project \"${PROJECT_PATH}\""
    err "exit code: ${list_status}"
    err "stderr:"
    cat "${list_stderr}" >&2
    print_diagnostics
    rm -f "${list_stderr}"
    exit 1
  fi

  rm -f "${list_stderr}"

  if ! printf "%s\n" "${list_output}" | grep -Eq "^[[:space:]]*${SCHEME}[[:space:]]*$"; then
    err "Scheme '${SCHEME}' not found in ${PROJECT_PATH}."
    err "Available schemes:"
    printf "%s\n" "${list_output}" | awk '/Schemes:/{flag=1;next}/^[[:space:]]*$/{flag=0}flag {print "  - "$0}'
    err "If the scheme is new, open Xcode and share it or set SCHEME=YourScheme."
    exit 1
  fi
}

query_destinations() {
  local destinations_status=0
  destination_id=""

  if [[ ${DESTINATION} =~ id=([^,]+) ]]; then
    destination_id="${BASH_REMATCH[1]}"
  fi

  if ! DESTINATIONS_OUTPUT="$(xcodebuild -showdestinations -project "${PROJECT_PATH}" -scheme "${SCHEME}" 2>&1)"; then
    destinations_status=$?
  fi

  if [[ ${destinations_status} -ne 0 ]]; then
    err "Unable to query destinations with xcodebuild:"
    err "${DESTINATIONS_OUTPUT}"
    err "Fallback: ensure simulators are installed via Xcode > Settings > Platforms."
    print_diagnostics
    exit 1
  fi
}

print_available_ios_runtimes() {
  if [[ -z ${SIMCTL_RUNTIMES_OUTPUT} ]]; then
    echo "  (no runtimes found via xcrun simctl list runtimes)"
    return
  fi

  printf "%s\n" "${SIMCTL_RUNTIMES_OUTPUT}" | awk '/iOS/ {print "  - " $0}'
}

print_devices_for_pinned_runtime() {
  local runtime_header="-- iOS ${OS_VERSION} --"

  if [[ -z ${SIMCTL_DEVICES_OUTPUT} ]]; then
    echo "  (no devices found via xcrun simctl list devices)"
    return
  fi

  if ! printf "%s\n" "${SIMCTL_DEVICES_OUTPUT}" | grep -Fq -- "${runtime_header}"; then
    echo "  (no devices found for ${runtime_header})"
    return
  fi

  printf "%s\n" "${SIMCTL_DEVICES_OUTPUT}" | awk -v header="${runtime_header}" '
    $0 == header {flag=1; next}
    /^-- / {flag=0}
    flag && NF {sub(/^[[:space:]]*/, ""); print "  - " $0}
  '
}

assert_destination_available() {
  query_destinations

  if [[ -n ${destination_id} ]]; then
    # Validate UDID against simctl output (authoritative source for simulators)
    # xcodebuild -showdestinations may not list specific UDIDs on CI runners
    if printf "%s\n" "${SIMCTL_DEVICES_OUTPUT}" | grep -Fq "${destination_id}"; then
      info "Validated simulator UDID ${destination_id} exists in simctl output"
      return 0
    fi

    err "Destination not found for simulator id ${destination_id}"
    err "The UDID was not found in 'xcrun simctl list devices' output."
    err "Available devices for chosen runtime:"
    print_devices_for_pinned_runtime >&2
    print_diagnostics
    exit 1
  else
    if printf "%s\n" "${DESTINATIONS_OUTPUT}" | grep -Eq "OS: ?${OS_VERSION}.*,.*name:${DEVICE_NAME}"; then
      return 0
    fi
  fi

  err "Destination not found for ${DESTINATION}"
  err "Available iOS runtimes:"
  print_available_ios_runtimes >&2
  err "Available devices for chosen runtime:"
  print_devices_for_pinned_runtime >&2
  err "Available destinations from xcodebuild:"
  printf "%s\n" "${DESTINATIONS_OUTPUT}" | sed 's/^/  /' >&2
  exit 1
}

main() {
  info "Project: ${PROJECT_PATH}"
  info "Scheme: ${SCHEME}"
  info "Destination: ${DESTINATION}"
  log_pinned_destination
  log_simulator_inventory

  require_command "xcodebuild" "Install Xcode: https://developer.apple.com/xcode/ or run 'xcode-select --install'."

  local xcode_version_output
  xcode_version_output="$(xcodebuild -version 2>&1 || true)"
  if [[ -z ${xcode_version_output} ]]; then
    err "xcodebuild -version returned no output"
    print_diagnostics
    exit 1
  fi

  if ! grep -Fq "${CI_XCODE_VERSION}" <<<"${xcode_version_output}"; then
    err "Pinned CI_XCODE_VERSION in docs/ci/ci-readiness.md does not match runner Xcode"
    err "Expected: ${CI_XCODE_VERSION}"
    err "Actual xcodebuild -version: ${xcode_version_output//$'\n'/; }"
    print_diagnostics
    exit 1
  fi

  assert_scheme_exists
  assert_destination_available

  info "Preflight checks passed."
}

main "$@"
