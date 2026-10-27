#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/Features/ContentBlocks"
  "${ROOT}/Shared/Components"
)

CONTENT_BLOCK_IDS=(
  btn_toggle_carousels
  cb_placeholder_example_top
  cb_placeholder_example_platform
  cb_placeholder_example_list
  cb_carousel_default
  cb_carousel_filtered
  cb_carousel_platform
  lbl_carousel_status
  cb_tab_classic
  cb_tab_runtime_lab
  btn_cb_runtime_prefetch
  btn_cb_runtime_availability
  btn_cb_runtime_invalidate
  btn_cb_runtime_logout
  lbl_cb_runtime_status
)

missing=0
for id in "${CONTENT_BLOCK_IDS[@]}"; do
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
    echo "FAIL: content blocks contract id '${id}' not found in production Swift" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS content blocks contract identifiers present in source (${#CONTENT_BLOCK_IDS[@]} ids)"
