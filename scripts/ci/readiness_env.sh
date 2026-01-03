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
  local ci_macos_runner=""
  local ci_xcode_version=""
  local ci_sim_device=""
  local ci_sim_os=""

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
        case "${key}" in
          CI_MACOS_RUNNER) ci_macos_runner="${value}" ;;
          CI_XCODE_VERSION) ci_xcode_version="${value}" ;;
          CI_SIM_DEVICE) ci_sim_device="${value}" ;;
          CI_SIM_OS) ci_sim_os="${value}" ;;
        esac
      fi
    fi
  done <"${DOC_PATH}"

  for required_key in CI_MACOS_RUNNER CI_XCODE_VERSION CI_SIM_DEVICE CI_SIM_OS; do
    case "${required_key}" in
      CI_MACOS_RUNNER)
        [[ -z ${ci_macos_runner} ]] && return 1
        ;;
      CI_XCODE_VERSION)
        [[ -z ${ci_xcode_version} ]] && return 1
        ;;
      CI_SIM_DEVICE)
        [[ -z ${ci_sim_device} ]] && return 1
        ;;
      CI_SIM_OS)
        [[ -z ${ci_sim_os} ]] && return 1
        ;;
    esac
  done

  export CI_MACOS_RUNNER="${ci_macos_runner}"
  export CI_XCODE_VERSION="${ci_xcode_version}"
  export CI_SIM_DEVICE="${ci_sim_device}"
  export CI_SIM_OS="${ci_sim_os}"
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
