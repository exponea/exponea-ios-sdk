#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/Features/Tracking"
  "${ROOT}/Shared/Components"
  "${ROOT}/Shared/Components/Dialogs"
  "${ROOT}/Shared/Components"
)

TRACKING_IDS=(
  lbl_cookie_id
  btn_copy_cookie_id
  btn_identify_customer
  btn_set_auth_token
  btn_track_custom_event
  btn_track_payment
  btn_track_page_view
  btn_request_push
  btn_track_fcm_token
  btn_track_push_delivered
  btn_track_push_clicked
  btn_identify
  btn_identify_auth
  fld_registered_id
  fld_identify_attr_name
  fld_identify_attr_value
  btn_identify_add_attr
  lbl_identify_attrs_json
  sel_inapp_preset
  fld_event_name
  fld_event_attr_name
  fld_event_attr_value
  btn_event_add_attr
  lbl_event_props_json
  btn_track_event
)

missing=0
for id in "${TRACKING_IDS[@]}"; do
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
    echo "FAIL: tracking contract id '${id}' not found in production Swift" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS tracking contract identifiers present in source (${#TRACKING_IDS[@]} ids)"

# Negative: Tracking must not reintroduce a dedicated In-app Messages section.
TRACKING_DIR="${ROOT}/Features/Tracking"
FORBIDDEN_PATTERNS=(
  "In-app Messages"
  "triggerInAppDemo"
  "show_in_app_demo"
  "A11yID.inAppMessages"
)

forbidden=0
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if [[ -d "${TRACKING_DIR}" ]] && grep -rq --fixed-strings "${pattern}" "${TRACKING_DIR}" --include="*.swift"; then
    echo "FAIL: forbidden Tracking IAM remnant '${pattern}' found under Features/Tracking" >&2
    forbidden=1
  fi
done

if [[ "${forbidden}" -ne 0 ]]; then
  exit 1
fi

echo "PASS tracking has no dedicated In-app Messages section remnants"
