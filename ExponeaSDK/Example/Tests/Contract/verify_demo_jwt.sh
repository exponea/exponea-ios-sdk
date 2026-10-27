#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="${ROOT}/Shared/Auth/DemoJwtGenerator.swift"

required_patterns=(
  'defaultExpirationMinutes = 15'
  'algorithmName = "HS512"'
  '"ids": customerIds'
  'HMAC<SHA512>'
)

missing=0
for pattern in "${required_patterns[@]}"; do
  if ! grep -q "${pattern}" "${SOURCE}"; then
    echo "FAIL: Demo JWT pattern not found: ${pattern}" >&2
    missing=1
  fi
done

if grep -q '"sub"' "${SOURCE}" || grep -q 'HS256' "${SOURCE}"; then
  echo "FAIL: Demo JWT must use the ids claim with HS512, not sub/HS256" >&2
  missing=1
fi

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS Demo JWT generator (HS512, ids, 15m)"
