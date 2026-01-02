#!/bin/bash

# Intent: Boot a CI-created simulator with diagnostics, surfacing exit codes for RCA.

set -euo pipefail

UDID="${SIMULATOR_UDID:-}"
NAME="${SIMULATOR_NAME:-}"

if [ -z "$UDID" ] || [ -z "$NAME" ]; then
    echo "❌ SIMULATOR_UDID and SIMULATOR_NAME must be set before booting."
    exit 1
fi

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

log "Preparing to boot simulator $NAME ($UDID)"

echo "-- Current simulator state --"
xcrun simctl list devices "$UDID" || true

attempts=3
sleep_between=20
final_rc=1

diagnostics() {
    log "Simulator diagnostics:"
    xcrun simctl list devices "$UDID" || true
    xcrun simctl list devices available iPhone || true
    xcrun simctl list runtimes || true
    xcrun simctl getenv "$UDID" HOME || true
    log "Recent CoreSimulator logs:"
    log show --last 5m --predicate 'process == "com.apple.CoreSimulator.CoreSimulatorService"' --style compact || true
}

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
