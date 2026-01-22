#!/usr/bin/env bash
# Intent: Run backend CI checks using current tooling.

set -euo pipefail

if [[ ! -d "backend" ]]; then
  echo "backend/ directory not found; skipping backend checks." >&2
  exit 1
fi

echo "Backend checks are not yet defined. Add lint/test commands as backend tooling is introduced."
