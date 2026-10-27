#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/Features/Flushing"
  "${ROOT}/Shared/Components"
)

FLUSHING_IDS=(
  tab_flush_mode
  tab_flush_period
  tab_log_level
  btn_get_flush_mode
  lbl_current_flush_mode
  btn_flush_mode_immediate
  btn_flush_mode_period
  btn_flush_mode_app_close
  btn_flush_mode_manual
  btn_get_flush_period
  lbl_current_flush_period
  btn_flush_period_30
  btn_flush_period_60
  btn_flush_data
  lbl_flush_result_title
  btn_flush_result_ok
  btn_get_log_level
  lbl_current_log_level
  btn_log_off
  btn_log_error
  btn_log_warn
  btn_log_info
  btn_log_debug
  btn_log_verbose
)

missing=0
for id in "${FLUSHING_IDS[@]}"; do
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
    echo "FAIL: flushing contract id '${id}' not found in production Swift" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS flushing contract identifiers present in source (${#FLUSHING_IDS[@]} ids)"
