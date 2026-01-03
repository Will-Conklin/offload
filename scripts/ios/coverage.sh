#!/usr/bin/env bash
# Intent: Generate iOS code coverage reports from existing test result bundles without blocking CI when unavailable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-${REPO_ROOT}/.ci/TestResults.xcresult}"
COVERAGE_DIR="${COVERAGE_DIR:-${REPO_ROOT}/.ci/coverage}"
COVERAGE_JSON="${COVERAGE_JSON:-${COVERAGE_DIR}/coverage.json}"
COVERAGE_TXT="${COVERAGE_TXT:-${COVERAGE_DIR}/coverage.txt}"

info() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

main() {
  if [[ ! -d "${RESULT_BUNDLE_PATH}" ]]; then
    warn "Result bundle not found at ${RESULT_BUNDLE_PATH}. Skipping coverage generation."
    exit 0
  fi

  if ! command -v xcrun >/dev/null 2>&1; then
    warn "xcrun not available. Skipping coverage generation."
    exit 0
  fi

  mkdir -p "${COVERAGE_DIR}"

  info "Generating coverage report from ${RESULT_BUNDLE_PATH}."

  if ! xcrun xccov view --report --json "${RESULT_BUNDLE_PATH}" >"${COVERAGE_JSON}"; then
    warn "Failed to write JSON coverage report to ${COVERAGE_JSON}."
    exit 1
  fi

  if ! xcrun xccov view --report "${RESULT_BUNDLE_PATH}" >"${COVERAGE_TXT}"; then
    warn "Failed to write text coverage report to ${COVERAGE_TXT}."
    exit 1
  fi

  info "Coverage reports saved to ${COVERAGE_DIR}."
  info "Coverage summary:"
  cat "${COVERAGE_TXT}"
}

main "$@"
