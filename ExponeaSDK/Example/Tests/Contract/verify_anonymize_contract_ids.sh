#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/Features/Anonymize"
  "${ROOT}/Shared/Components"
)

ANONYMIZE_IDS=(
  btn_anonymize
  btn_stop_integration
  lbl_anonymized_title
  btn_anonymized_ok
  btn_stop_back_to_auth
  btn_stop_continue
  btn_stop_cancel
)

missing=0
for id in "${ANONYMIZE_IDS[@]}"; do
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
    echo "FAIL: anonymize contract id '${id}' not found in production Swift" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS anonymize contract identifiers present in source (${#ANONYMIZE_IDS[@]} ids)"
