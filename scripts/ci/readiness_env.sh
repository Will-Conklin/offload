#!/usr/bin/env bash
# Intent: Parse pinned CI environment values strictly from docs/ci/ci-readiness.md and export them for workflows.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOC_PATH="${REPO_ROOT}/docs/ci/ci-readiness.md"

SECTION_START_PATTERN='^## Pinned CI Environment$'
KEY_PATTERN='^(CI_MACOS_RUNNER|CI_XCODE_VERSION|CI_SIM_DEVICE|CI_SIM_OS):[[:space:]]*(.+)$'

err() {
  echo "docs/ci/ci-readiness.md is missing required pinned CI environment keys" >&2
}

parse_values() {
  local in_section=false
  local -A values=()

  while IFS= read -r line; do
    if [[ ${in_section} == false ]]; then
      if [[ ${line} =~ ${SECTION_START_PATTERN} ]]; then
        in_section=true
      fi
      continue
    fi

    if [[ ${line} =~ ^##[[:space:]] ]]; then
      break
    fi

    if [[ ${line} =~ ${KEY_PATTERN} ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"
      if [[ -n ${value} ]]; then
        values["${key}"]="${value}"
      fi
    fi
  done <"${DOC_PATH}"

  for required_key in CI_MACOS_RUNNER CI_XCODE_VERSION CI_SIM_DEVICE CI_SIM_OS; do
    if [[ -z ${values[${required_key}]:-} ]]; then
      return 1
    fi
  done

  export CI_MACOS_RUNNER="${values[CI_MACOS_RUNNER]}"
  export CI_XCODE_VERSION="${values[CI_XCODE_VERSION]}"
  export CI_SIM_DEVICE="${values[CI_SIM_DEVICE]}"
  export CI_SIM_OS="${values[CI_SIM_OS]}"
}

main() {
  if [[ ! -f "${DOC_PATH}" ]]; then
    err
    exit 1
  fi

  if ! parse_values; then
    err
    exit 1
  fi
}

main "$@"
