#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/Features/Fetching"
  "${ROOT}/Shared/Components"
  "${ROOT}/Shared/Components/Dialogs"
  "${ROOT}/Shared/SDK"
)

FETCHING_IDS=(
  btn_fetch_consents
  btn_fetch_recommendations
  btn_fetch_segments
  btn_app_inbox_provider
  btn_open_inbox
  btn_clear_result
  lbl_fetch_result
  status_fetch_loading
  fld_recommendation_id
  btn_recommendation_dialog_fetch
  btn_recommendation_dialog_cancel
)

missing=0
for id in "${FETCHING_IDS[@]}"; do
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
    echo "FAIL: fetching contract id '${id}' not found in production Swift" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS fetching contract identifiers present in source (${#FETCHING_IDS[@]} ids)"
