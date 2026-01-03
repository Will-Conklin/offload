#!/usr/bin/env bash
# Intent: Select a deterministic available iOS simulator UDID using pinned CI defaults with clear fallback logging.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/ci/readiness_env.sh"

info() {
  echo "[INFO] $*"
}

err() {
  echo "[ERROR] $*" >&2
}

select_simulator() {
  local json_data="$1"
  python3 - "${CI_SIM_DEVICE}" "${CI_SIM_OS}" "${json_data}" <<'PY'
import json
import re
import sys
from typing import Dict, Iterable, List, Optional, Tuple

requested_device = sys.argv[1].strip()
requested_os = sys.argv[2].strip()
json_data = sys.argv[3]

def parse_os_tuple(version: str) -> Tuple[int, ...]:
    numbers = re.findall(r"\d+", version)
    return tuple(int(part) for part in numbers)

def runtime_os_tuple(identifier: str) -> Optional[Tuple[int, ...]]:
    match = re.search(r"iOS[- ]([0-9][0-9\.\-]*)", identifier, re.IGNORECASE)
    if not match:
        return None
    return parse_os_tuple(match.group(1))

def find_requested_runtime(devices: Dict[str, Iterable[dict]], os_tuple: Tuple[int, ...]) -> Optional[str]:
    matches: List[str] = []
    for runtime_identifier in devices:
        runtime_tuple = runtime_os_tuple(runtime_identifier)
        if runtime_tuple and runtime_tuple == os_tuple:
            matches.append(runtime_identifier)
    return sorted(matches)[0] if matches else None

def newest_runtime(devices: Dict[str, Iterable[dict]]) -> Optional[str]:
    candidates: List[Tuple[Tuple[int, ...], str]] = []
    for runtime_identifier in devices:
        runtime_tuple = runtime_os_tuple(runtime_identifier)
        if runtime_tuple:
            candidates.append((runtime_tuple, runtime_identifier))
    if not candidates:
        return None
    candidates.sort(key=lambda entry: (entry[0], entry[1]), reverse=True)
    return candidates[0][1]

def normalize_devices(devices: Iterable[dict]) -> List[Tuple[str, str]]:
    return sorted(
        [
            (device.get("name", ""), device.get("udid", ""))
            for device in devices
            if device.get("isAvailable", False)
        ],
        key=lambda entry: (entry[0].lower(), entry[1]),
    )


def find_device_by_name(devices: List[Tuple[str, str]], preferred_name: str) -> Optional[Tuple[str, str]]:
    preferred_name_lower = preferred_name.lower()
    for name, udid in devices:
        if name.lower() == preferred_name_lower:
            return name, udid
    return None


def first_iphone(devices: List[Tuple[str, str]]) -> Optional[Tuple[str, str]]:
    for name, udid in devices:
        if name.lower().startswith("iphone"):
            return name, udid
    return None

def main() -> int:
    try:
        payload = json.loads(json_data)
    except Exception as exc:  # pragma: no cover - diagnostic path
        print(f"[ERROR] Failed to parse simulator JSON: {exc}", file=sys.stderr)
        return 1

    devices: Dict[str, List[dict]] = payload.get("devices", {})
    ios_runtimes = {}
    for runtime, sims in devices.items():
        normalized = normalize_devices(sims)
        if runtime_os_tuple(runtime) and normalized:
            ios_runtimes[runtime] = normalized
    if not ios_runtimes:
        print("[ERROR] No iOS runtimes with available simulators were found.", file=sys.stderr)
        return 1

    requested_tuple = parse_os_tuple(requested_os)
    target_runtime = find_requested_runtime(ios_runtimes, requested_tuple) if requested_tuple else None

    selected_runtime: Optional[str] = None
    selected_device: Optional[str] = None
    selected_udid: Optional[str] = None
    used_fallback = False

    if target_runtime:
        device_choice = find_device_by_name(ios_runtimes[target_runtime], requested_device)
        if device_choice:
            selected_device, selected_udid = device_choice
            selected_runtime = target_runtime
        else:
            used_fallback = True
    else:
        used_fallback = True

    if used_fallback:
        newest = newest_runtime(ios_runtimes)
        if not newest:
            print("[ERROR] Unable to determine newest iOS runtime with available simulators.", file=sys.stderr)
            return 1
        device_choice = find_device_by_name(ios_runtimes[newest], requested_device)
        if not device_choice:
            device_choice = first_iphone(ios_runtimes[newest])
        if not device_choice:
            print(
                f"[ERROR] No matching '{requested_device}' or available iPhone simulators found under runtime '{newest}'.",
                file=sys.stderr,
            )
            return 1
        selected_runtime = newest
        selected_device, selected_udid = device_choice

    runtime_tuple = runtime_os_tuple(selected_runtime) or ()
    runtime_display = ".".join(str(part) for part in runtime_tuple) if runtime_tuple else selected_runtime
    selection_line = (
        f"Selected simulator: {selected_device} (iOS {runtime_display}) "
        f"[runtime: {selected_runtime}]"
    )

    if used_fallback and target_runtime != selected_runtime:
        print(
            f"[INFO] Falling back from requested iOS {requested_os} to newest runtime {runtime_display}.",
            file=sys.stderr,
        )
    elif used_fallback:
        print(
            f"[INFO] Requested device '{requested_device}' not found in runtime '{target_runtime}', "
            f"using available '{selected_device}'.",
            file=sys.stderr,
        )

    print(selection_line)
    print(selected_udid)
    return 0

if __name__ == "__main__":
    sys.exit(main())
PY
}

main() {
  if ! command -v xcrun >/dev/null 2>&1; then
    err "xcrun is not available. Please install Xcode command line tools."
    exit 1
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    err "python3 is required to parse simulator JSON."
    exit 1
  fi

  info "Requested simulator from docs/ci/ci-readiness.md: device='${CI_SIM_DEVICE}', iOS '${CI_SIM_OS}'"

  local simctl_output=""
  local selection_output=""
  if ! simctl_output="$(xcrun simctl list devices -j)"; then
    err "Failed to list available simulators via simctl."
    exit 1
  fi

  echo "[DEBUG] simctl output length: ${#simctl_output} bytes" >&2
  if [[ -z "${simctl_output}" ]]; then
    err "simctl returned empty output"
    exit 1
  fi

  # Show first 200 chars of simctl output for debugging
  echo "[DEBUG] simctl output (first 200 chars): ${simctl_output:0:200}" >&2

  if ! selection_output="$(select_simulator "${simctl_output}")"; then
    err "Simulator selection failed."
    exit 1
  fi

  printf "%s\n" "${selection_output}"
}

main "$@"
