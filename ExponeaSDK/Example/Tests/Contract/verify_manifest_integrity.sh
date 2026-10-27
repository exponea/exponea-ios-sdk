#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="${ROOT}/Tests/Contract/check_manifest_integrity.py"
MANIFEST="${ROOT}/Tests/Contract/automation_contract.yaml"
FIXTURES="${ROOT}/Tests/Contract/fixtures"

if ! command -v python3 >/dev/null 2>&1; then
  echo "FAIL: python3 is required for manifest integrity checks" >&2
  exit 1
fi

if ! command -v ruby >/dev/null 2>&1; then
  echo "FAIL: ruby is required to parse the manifest as YAML (macOS ships it)" >&2
  exit 1
fi

# check_manifest_integrity.py reads the manifest line by line, so it can't catch YAML syntax errors.
yaml_parses() {
  ruby -ryaml -e 'YAML.load_file(ARGV[0])' "$1" >/dev/null 2>&1
}

if yaml_parses "${FIXTURES}/automation_contract_bad_indent.yaml"; then
  echo "FAIL: expected YAML parse error for mis-indented key" >&2
  exit 1
fi

if ! yaml_parses "${MANIFEST}"; then
  echo "FAIL: ${MANIFEST} is not valid YAML" >&2
  ruby -ryaml -e 'YAML.load_file(ARGV[0])' "${MANIFEST}" 2>&1 | head -1 >&2
  exit 1
fi

expect_reject() {
  local fixture="$1"
  local label="$2"
  if python3 "${CHECKER}" "${fixture}" >/dev/null 2>&1; then
    echo "FAIL: expected rejection for ${label} (${fixture})" >&2
    exit 1
  fi
}

expect_reject "${FIXTURES}/automation_contract_duplicate.yaml" "duplicate semantic id"
expect_reject "${FIXTURES}/automation_contract_malformed.yaml" "malformed empty semantic id"
expect_reject "${FIXTURES}/automation_contract_invalid_id.yaml" "invalid semantic id format"

python3 "${CHECKER}" "${MANIFEST}"

echo "PASS manifest integrity checks"
