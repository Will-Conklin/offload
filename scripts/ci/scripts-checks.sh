#!/usr/bin/env bash
# Intent: Run scripts lane checks using built-in shell validation.

set -euo pipefail

mapfile -t script_files < <(find scripts -type f -name '*.sh')

if [[ ${#script_files[@]} -eq 0 ]]; then
  echo "No shell scripts found under scripts/."
  exit 0
fi

echo "Running bash -n for ${#script_files[@]} script(s)."
for script_file in "${script_files[@]}"; do
  bash -n "${script_file}"
done

echo "Shell scripts passed basic syntax checks."
