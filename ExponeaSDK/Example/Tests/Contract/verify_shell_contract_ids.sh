#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/App"
  "${ROOT}/Shared"
  "${ROOT}/Features"
  "${ROOT}/Configuration"
)

SHELL_IDS=(
  btn_nav_fetching
  btn_nav_tracking
  btn_nav_flushing
  btn_nav_anonymize
  btn_nav_content_blocks
  btn_open_logs
  btn_reset_state
  btn_reset_back_to_auth
  btn_reset_stop_and_continue
  btn_reset_cancel
  btn_shell_logo
  btn_config_close
  lbl_config_not_configured
  status_sdk_indicator
)

missing=0
for id in "${SHELL_IDS[@]}"; do
  found=0
  for dir in "${SOURCE_DIRS[@]}"; do
    if grep -rq "${id}" "${dir}" --include="*.swift"; then
      found=1
      break
    fi
  done
  if [[ "${found}" -eq 0 ]]; then
    echo "FAIL: shell contract id '${id}' not found in production Swift" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS shell contract identifiers present in source (${#SHELL_IDS[@]} ids)"
