#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/App"
  "${ROOT}/Shared"
)

assert_contains() {
  local file="$1"
  local text="$2"
  local label="$3"
  if ! grep -Fq "${text}" "${file}"; then
    echo "FAIL ${label}: '${text}' not found in ${file}" >&2
    return 1
  fi
}

assert_contains "${ROOT}/Shared/Components/A11yID.swift" "img_loading_logo" "loading logo contract id"
assert_contains "${ROOT}/App/LoadingView.swift" "A11yID.shell.loadingLogo" "loading logo applied in view"
assert_contains "${ROOT}/App/RootView.swift" "LoadingView()" "loading route in root router"
assert_contains "${ROOT}/App/RootView.swift" "100_000_000" "deterministic loading delay"

echo "PASS loading route wiring present"
