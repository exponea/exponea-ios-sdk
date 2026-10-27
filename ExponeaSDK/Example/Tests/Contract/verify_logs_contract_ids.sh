#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/Shared/Logging"
  "${ROOT}/Shared/Components"
)

LOGS_IDS=(
  btn_logs_close
  btn_logs_copy
  btn_logs_clear
  btn_logs_filter_all
  btn_logs_filter_verbose
  btn_logs_filter_debug
  btn_logs_filter_info
  btn_logs_filter_warn
  btn_logs_filter_error
)

missing=0
for id in "${LOGS_IDS[@]}"; do
  found=0
  for dir in "${SOURCE_DIRS[@]}"; do
    if [[ -d "${dir}" ]] && grep -rq "${id}" "${dir}" --include="*.swift"; then
      found=1
      break
    fi
  done
  if [[ "${found}" -eq 0 ]] && grep -rq "${id}" "${ROOT}/Shared/Components/A11yID.swift"; then
    found=1
  fi
  if [[ "${found}" -eq 0 ]]; then
    echo "FAIL: logs contract id '${id}' not found in production Swift" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS logs contract identifiers present in source (${#LOGS_IDS[@]} ids)"
