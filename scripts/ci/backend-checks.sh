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

VENV_PATH="backend/api/.venv"

python3 -m venv "${VENV_PATH}"
"${VENV_PATH}/bin/python" -m pip install --upgrade pip
"${VENV_PATH}/bin/python" -m pip install -e 'backend/api[dev]'
"${VENV_PATH}/bin/python" -m ruff check backend/api/src backend/api/tests
"${VENV_PATH}/bin/python" -m ty check \
  --project backend/api \
  --extra-search-path backend/api/src \
  backend/api/src backend/api/tests
"${VENV_PATH}/bin/python" -m pytest backend/api/tests -q
