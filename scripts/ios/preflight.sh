#!/usr/bin/env bash
# Intent: Validate iOS CI readiness by checking tooling, scheme availability, and simulator destinations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PROJECT_PATH="${PROJECT_PATH:-${REPO_ROOT}/ios/Offload.xcodeproj}"
SCHEME="${SCHEME:-Offload}"
DEVICE_NAME="${DEVICE_NAME:-iPhone 15}"
OS_VERSION="${OS_VERSION:-17.5}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}}"

err() {
  echo "[ERROR] $*" >&2
}

info() {
  echo "[INFO] $*"
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
  local list_output
  if ! list_output="$(xcodebuild -list -project "${PROJECT_PATH}" 2>&1)"; then
    err "Unable to list schemes for ${PROJECT_PATH}"
    err "${list_output}"
    exit 1
  fi

  if ! printf "%s\n" "${list_output}" | grep -Eq "^[[:space:]]*${SCHEME}[[:space:]]*$"; then
    err "Scheme '${SCHEME}' not found in ${PROJECT_PATH}."
    err "Available schemes:"
    printf "%s\n" "${list_output}" | awk '/Schemes:/{flag=1;next}/^[[:space:]]*$/{flag=0}flag {print "  - "$0}'
    err "If the scheme is new, open Xcode and share it or set SCHEME=YourScheme."
    exit 1
  fi
}

assert_destination_available() {
  local destinations_output=""
  local destinations_status=0

  if ! destinations_output="$(xcodebuild -showdestinations -project "${PROJECT_PATH}" -scheme "${SCHEME}" 2>&1)"; then
    destinations_status=$?
  fi

  if [[ ${destinations_status} -ne 0 ]]; then
    err "Unable to query destinations with xcodebuild:"
    err "${destinations_output}"
    err "Fallback: ensure simulators are installed via Xcode > Settings > Platforms."
    exit 1
  fi

  if printf "%s\n" "${destinations_output}" | grep -Eq "name:${DEVICE_NAME}.*,.*OS: ?${OS_VERSION}"; then
    return 0
  fi

  err "Destination not found for ${DESTINATION}"
  err "Try installing the simulator (Xcode > Settings > Platforms) or update DEVICE_NAME/OS_VERSION."
  err "Available destinations:"
  printf "%s\n" "${destinations_output}" | sed 's/^/  /'
  exit 1
}

main() {
  info "Project: ${PROJECT_PATH}"
  info "Scheme: ${SCHEME}"
  info "Destination: ${DESTINATION}"

  require_command "xcodebuild" "Install Xcode: https://developer.apple.com/xcode/ or run 'xcode-select --install'."

  assert_scheme_exists
  assert_destination_available

  info "Preflight checks passed."
}

main "$@"
