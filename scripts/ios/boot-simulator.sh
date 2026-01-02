#!/bin/bash

# Intent: Boot a CI-created simulator deterministically with retries, defensive cleanup, and high-signal diagnostics.

set -euo pipefail

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

resolve_device_json=$(
python3 <<'PY'
import json
import os
import subprocess
import sys

preferred_udid = os.environ.get("SIMULATOR_UDID", "").strip()


def version_tuple(version: str) -> tuple[int, ...]:
    parts = []
    current = ""
    for ch in version:
        if ch.isdigit():
            current += ch
        elif current:
            parts.append(int(current))
            current = ""
    if current:
        parts.append(int(current))
    return tuple(parts) or (0,)


def load_json(args: list[str]) -> dict:
    try:
        raw = subprocess.check_output(args)
    except subprocess.CalledProcessError as exc:
        print(f"Command failed: {' '.join(args)}", file=sys.stderr)
        print(exc, file=sys.stderr)
        sys.exit(1)
    return json.loads(raw)


runtimes = load_json(["xcrun", "simctl", "list", "runtimes", "-j"]).get("runtimes", [])
available_runtimes = {rt["identifier"]: rt for rt in runtimes if rt.get("isAvailable")}
available_devices = load_json(
    ["xcrun", "simctl", "list", "devices", "available", "-j"]
).get("devices", {})

selected = None
if preferred_udid:
    for runtime_identifier, devices in available_devices.items():
        runtime = available_runtimes.get(runtime_identifier)
        if not runtime or "iOS" not in runtime.get("name", ""):
            continue
        for device in devices:
            if device.get("udid") == preferred_udid and device.get("isAvailable", False):
                selected = {
                    "udid": device.get("udid", ""),
                    "name": device.get("name", ""),
                    "runtime_identifier": runtime_identifier,
                    "runtime_name": runtime.get("name", ""),
                    "runtime_version": runtime.get("version", "0"),
                    "state": device.get("state", "unknown"),
                }
                break
        if selected:
            break

if not selected:
    candidates = []
    for runtime_identifier, devices in available_devices.items():
        runtime = available_runtimes.get(runtime_identifier)
        if not runtime or "iOS" not in runtime.get("name", ""):
            continue
        for device in devices:
            if not device.get("isAvailable", False):
                continue
            if "iPhone" not in device.get("name", ""):
                continue
            candidates.append(
                {
                    "udid": device.get("udid", ""),
                    "name": device.get("name", ""),
                    "runtime_identifier": runtime_identifier,
                    "runtime_name": runtime.get("name", ""),
                    "runtime_version": runtime.get("version", "0"),
                    "state": device.get("state", "unknown"),
                }
            )
    if not candidates:
        print("No available iPhone simulators found.", file=sys.stderr)
        sys.exit(1)
    candidates.sort(key=lambda dev: tuple(-part for part in version_tuple(dev["runtime_version"])))
    selected = candidates[0]

print(json.dumps(selected))
PY
)

UDID="$(echo "$resolve_device_json" | python3 -c "import json,sys;print(json.load(sys.stdin)['udid'])")"
NAME="$(echo "$resolve_device_json" | python3 -c "import json,sys;print(json.load(sys.stdin)['name'])")"
RUNTIME_NAME="$(echo "$resolve_device_json" | python3 -c "import json,sys;print(json.load(sys.stdin)['runtime_name'])")"
RUNTIME_VERSION="$(echo "$resolve_device_json" | python3 -c "import json,sys;print(json.load(sys.stdin)['runtime_version'])")"

if [ -z "$UDID" ] || [ -z "$NAME" ]; then
    echo "❌ Unable to resolve an available simulator UDID."
    exit 1
fi

if [ -n "${GITHUB_ENV:-}" ]; then
    {
        echo "SIMULATOR_UDID=$UDID"
        echo "SIMULATOR_NAME=$NAME"
    } >> "$GITHUB_ENV"
fi

log "Preparing to boot simulator $NAME ($UDID) on runtime $RUNTIME_NAME $RUNTIME_VERSION"

diagnostics() {
    log "Simulator diagnostics (UDID=$UDID):"
    xcrun simctl list devices "$UDID" || true
    xcrun simctl list devices available || true
    xcrun simctl list runtimes || true
    xcrun simctl getenv "$UDID" SIMULATOR_DEVICE_NAME || true
    xcrun simctl spawn "$UDID" launchctl print system || true
    log "Recent CoreSimulator logs:"
    log show --last 5m --predicate 'process == "com.apple.CoreSimulator.CoreSimulatorService"' --style compact || true
}

log "Resetting CoreSimulator services before boot"
killall Simulator || true
killall -9 com.apple.CoreSimulator.CoreSimulatorService || true

attempts=3
sleep_between=20
final_rc=1

echo "-- Current simulator state --"
xcrun simctl list devices "$UDID" || true

for attempt in $(seq 1 "$attempts"); do
    log "Boot attempt $attempt/$attempts for $NAME ($UDID)"

    xcrun simctl shutdown "$UDID" || true
    if [ "$attempt" -gt 1 ]; then
        log "Erasing simulator to recover from previous failure"
        xcrun simctl erase "$UDID" || true
    fi

    start=$(date +%s)
    boot_rc=0
    xcrun simctl boot "$UDID" || boot_rc=$?
    log "simctl boot exit code: $boot_rc"

    bootstatus_rc=0
    xcrun simctl bootstatus "$UDID" -b -t 300 || bootstatus_rc=$?
    log "simctl bootstatus exit code: $bootstatus_rc"
    final_rc=$bootstatus_rc

    if [ "$bootstatus_rc" -eq 0 ]; then
        end=$(date +%s)
        log "Simulator boot ready in $((end - start))s"
        exit 0
    fi

    diagnostics

    if [ "$attempt" -lt "$attempts" ]; then
        log "Boot attempt $attempt failed; retrying after backoff (${sleep_between}s)"
        sleep "$sleep_between"
    fi
done

log "All boot attempts failed for $NAME ($UDID)"
diagnostics
exit "$final_rc"
