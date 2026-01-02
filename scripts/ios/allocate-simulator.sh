#!/bin/bash

# Intent: Allocate a fresh iPhone simulator for CI, preferring modern devices and exporting metadata for downstream steps.

set -euo pipefail

echo "=== Allocating simulator for CI ==="

PREFERRED_DEVICES=(
    "iPhone 16 Pro"
    "iPhone 16"
    "iPhone 15 Pro"
    "iPhone 15"
    "iPhone 14 Pro"
    "iPhone 14"
)

echo "-- Listing runtimes --"
xcrun simctl list runtimes

echo "-- Listing device types --"
xcrun simctl list devicetypes | head -n 100

python3 <<'PY'
import json
import os
import subprocess
import sys

preferred_devices = [
    "iPhone 16 Pro",
    "iPhone 16",
    "iPhone 15 Pro",
    "iPhone 15",
    "iPhone 14 Pro",
    "iPhone 14",
]


def is_available(device: dict) -> bool:
    if "isAvailable" in device:
        return bool(device.get("isAvailable"))
    availability = str(device.get("availability", "")).lower()
    return "available" in availability


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


def run_json(args: list[str]) -> dict:
    try:
        raw = subprocess.check_output(args)
    except subprocess.CalledProcessError as exc:
        print(f"Command failed: {' '.join(args)}", file=sys.stderr)
        print(exc, file=sys.stderr)
        sys.exit(1)
    return json.loads(raw)


raw_runtimes = run_json(["xcrun", "simctl", "list", "runtimes", "-j"]).get(
    "runtimes", []
)
ios_runtimes = [
    rt for rt in raw_runtimes if rt.get("isAvailable") and "iOS" in rt.get("name", "")
]

if not ios_runtimes:
    print("No available iOS runtimes found", file=sys.stderr)
    sys.exit(1)

ios_runtimes.sort(key=lambda rt: version_tuple(rt.get("version", "0")), reverse=True)
runtime = ios_runtimes[0]

devices_by_runtime = run_json(["xcrun", "simctl", "list", "devices", "available", "-j"]).get("devices", {})
runtime_by_id = {rt["identifier"]: rt for rt in raw_runtimes}

candidates: list[dict] = []
for runtime_identifier, devices in devices_by_runtime.items():
    runtime_info = runtime_by_id.get(runtime_identifier) or {}
    if "iOS" not in runtime_info.get("name", "") or not runtime_info.get("isAvailable"):
        continue
    for device in devices:
        if not is_available(device):
            continue
        if "iPhone" not in device.get("name", ""):
            continue
        candidates.append(
            {
                "name": device.get("name", ""),
                "udid": device.get("udid", ""),
                "runtime_identifier": runtime_identifier,
                "runtime_name": runtime_info.get("name", runtime_identifier),
                "runtime_version": runtime_info.get("version", "0"),
                "state": device.get("state", "unknown"),
                "device_type_identifier": device.get("deviceTypeIdentifier", ""),
                "is_available": is_available(device),
            }
        )

if candidates:
    def candidate_sort_key(device: dict) -> tuple[int, tuple[int, ...]]:
        try:
            preferred_index = preferred_devices.index(device["name"])
        except ValueError:
            preferred_index = len(preferred_devices)
        version_key = tuple(-part for part in version_tuple(device["runtime_version"]))
        return (preferred_index, version_key)

    candidates.sort(key=candidate_sort_key)
    selected = candidates[0]
    udid = selected["udid"]
    sim_name = selected["name"]
    runtime_identifier = selected["runtime_identifier"]
    runtime_version = selected["runtime_version"]
    runtime_name = selected["runtime_name"]
    device_type_identifier = selected.get("device_type_identifier") or selected["name"]
    print("Reusing available simulator:")
    print(json.dumps(selected, indent=2))
else:
    devicetypes = run_json(["xcrun", "simctl", "list", "devicetypes", "-j"]).get(
        "devicetypes", []
    )

    selected_type = None
    for name in preferred_devices:
        for dev_type in devicetypes:
            if dev_type.get("name") == name:
                selected_type = dev_type
                break
        if selected_type:
            break

    if selected_type is None:
        for dev_type in devicetypes:
            if "iPhone" in dev_type.get("name", ""):
                selected_type = dev_type
                break

    if selected_type is None:
        print("No iPhone device types available", file=sys.stderr)
        sys.exit(1)

    sim_name = f"CI {selected_type['name']} ({runtime['version']})"
    create_cmd = [
        "xcrun",
        "simctl",
        "create",
        sim_name,
        selected_type["identifier"],
        runtime["identifier"],
    ]

    result = subprocess.run(create_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("Failed to create simulator", file=sys.stderr)
        print(result.stdout, file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(result.returncode)

    udid = result.stdout.strip()
    runtime_identifier = runtime["identifier"]
    runtime_version = runtime["version"]
    runtime_name = runtime["name"]
    device_type_identifier = selected_type.get("identifier", "")
    print(f"Selected runtime: {runtime_name} ({runtime_identifier})")
    print(f"Selected device type: {selected_type['name']} ({selected_type['identifier']})")
    print(f"Created simulator: {sim_name} ({udid})")

env_path = os.environ.get("GITHUB_ENV")
for key, value in [
    ("SIMULATOR_UDID", udid),
    ("SIMULATOR_NAME", sim_name),
    ("SIMULATOR_RUNTIME", runtime_identifier),
    ("SIMULATOR_RUNTIME_VERSION", runtime_version),
    ("SIMULATOR_DEVICE_TYPE", device_type_identifier),
]:
    line = f"{key}={value}\n"
    sys.stdout.write(line)
    if env_path:
        with open(env_path, "a", encoding="utf-8") as env_file:
            env_file.write(line)
PY

echo "-- Listing available devices after creation --"
xcrun simctl list devices available iPhone || true

exit 0
