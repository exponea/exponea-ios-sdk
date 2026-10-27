#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required_patterns=(
  "enum StreamAuthListener"
  "setJwtErrorHandler"
  "onInitSucceeded"
  "StreamAuthListener.stop"
)

missing=0
for pattern in "${required_patterns[@]}"; do
  if ! grep -rq "${pattern}" "${ROOT}/Shared" "${ROOT}/Configuration" --include="*.swift"; then
    echo "FAIL: expected Stream JWT pattern '${pattern}' not found" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS stream auth listener wiring present in source"
