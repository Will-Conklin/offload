#!/usr/bin/env bash
# Intent: Claude Code environment startup script - delegates to shared setup.
#
# This is the entry point for Claude Code environments.
# All setup logic is in scripts/setup/environment.sh for sharing with other AI assistants.
#
# Usage:
#   ./.claude/setup.sh                    # Full setup
#   ./.claude/setup.sh --quiet            # Minimal output
#   ./.claude/setup.sh --skip-simulators  # Skip simulator setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SHARED_SETUP="${REPO_ROOT}/scripts/setup/environment.sh"

if [[ ! -f "${SHARED_SETUP}" ]]; then
    echo "[ERROR] Shared setup script not found: ${SHARED_SETUP}" >&2
    exit 1
fi

echo "[Claude] Running shared environment setup..."
exec "${SHARED_SETUP}" "$@"
