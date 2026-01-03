#!/usr/bin/env bash
# Intent: Write a diagnostics report with pinned CI environment values and local tool info for iOS CI workflows.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CI_DIR="${REPO_ROOT}/.ci"
REPORT_PATH="${CI_DIR}/env-report.txt"

source "${REPO_ROOT}/scripts/ci/readiness_env.sh"

mkdir -p "${CI_DIR}"

run_best_effort() {
  local description="$1"
  shift

  echo "${description}:"
  if "$@" >/tmp/.env-report.tmp 2>&1; then
    cat /tmp/.env-report.tmp
  else
    cat /tmp/.env-report.tmp
    echo "(command failed but continuing)"
  fi
  echo ""
}

{
  echo "Pinned CI values from docs/ci/ci-readiness.md:"
  echo "CI_MACOS_RUNNER=${CI_MACOS_RUNNER}"
  echo "CI_XCODE_VERSION=${CI_XCODE_VERSION}"
  echo "CI_SIM_DEVICE=${CI_SIM_DEVICE}"
  echo "CI_SIM_OS=${CI_SIM_OS}"
  echo ""

  if command -v sw_vers >/dev/null 2>&1; then
    run_best_effort "sw_vers" sw_vers
  else
    echo "sw_vers not available"
    echo ""
  fi

  if command -v xcodebuild >/dev/null 2>&1; then
    run_best_effort "xcodebuild -version" xcodebuild -version
  else
    echo "xcodebuild not available"
    echo ""
  fi

  if command -v xcrun >/dev/null 2>&1; then
    run_best_effort "simctl list runtimes" xcrun simctl list runtimes
    run_best_effort "simctl list devices" xcrun simctl list devices
  else
    echo "xcrun not available"
    echo ""
  fi
} > "${REPORT_PATH}"

echo "Wrote diagnostics report to ${REPORT_PATH}"
