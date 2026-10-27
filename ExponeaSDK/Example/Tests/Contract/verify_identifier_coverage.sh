#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="${ROOT}/Tests/Contract/check_identifier_coverage.py"
MANIFEST="${ROOT}/Tests/Contract/automation_contract.yaml"
GAPS="${ROOT}/Tests/Contract/known_identifier_gaps.yaml"
FIXTURES="${ROOT}/Tests/Contract/fixtures"

if ! command -v python3 >/dev/null 2>&1; then
  echo "FAIL: python3 is required for identifier coverage checks" >&2
  exit 1
fi

expect_fail() {
  local manifest="$1"
  local gaps="$2"
  local label="$3"
  local source_root="${4:-}"
  if [[ -n "${source_root}" ]]; then
    if python3 "${CHECKER}" "${manifest}" "${gaps}" "${source_root}" >/dev/null 2>&1; then
      echo "FAIL: expected identifier coverage failure for ${label}" >&2
      exit 1
    fi
  elif python3 "${CHECKER}" "${manifest}" "${gaps}" >/dev/null 2>&1; then
    echo "FAIL: expected identifier coverage failure for ${label}" >&2
    exit 1
  fi
}

expect_fail "${FIXTURES}/automation_contract_unknown_gap.yaml" "${FIXTURES}/known_gaps_minimal.yaml" "unknown missing identifier"
expect_fail "${MANIFEST}" "${FIXTURES}/known_gaps_minimal.yaml" "incomplete known-gap allowlist"
expect_fail "${FIXTURES}/automation_contract_stale.yaml" "${FIXTURES}/known_gaps_stale.yaml" "stale allowlist entry" "${FIXTURES}/swift_source_fixture"

python3 "${CHECKER}" "${MANIFEST}" "${GAPS}"

echo "PASS identifier coverage checks"
