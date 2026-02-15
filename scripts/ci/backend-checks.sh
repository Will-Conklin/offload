#!/usr/bin/env bash
# Intent: Run backend CI checks for API scaffold quality gates.

set -euo pipefail

if [[ ! -d "backend/api" ]]; then
  echo "backend/api directory not found; cannot run backend checks." >&2
  exit 1
fi

if [[ ! -f "backend/api/pyproject.toml" ]]; then
  echo "backend/api/pyproject.toml is required for backend checks." >&2
  exit 1
fi

python3 -m pip install --user -e 'backend/api[dev]'
python3 -m ruff check backend/api/src backend/api/tests
python3 -m ty check backend/api/src backend/api/tests
python3 -m pytest backend/api/tests -q
