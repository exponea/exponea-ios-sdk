#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIRS=(
  "${ROOT}/Configuration"
  "${ROOT}/Shared/Components"
)

AUTH_IDS=(
  lbl_auth_title
  btn_auth_mode_project
  btn_auth_mode_stream
  fld_auth_project_token
  fld_auth_authorization_token
  fld_auth_advanced_auth
  fld_auth_stream_id
  fld_auth_jwt_key_id
  fld_auth_jwt_secret
  fld_auth_registered_id
  fld_auth_api_url
  fld_auth_application_id
  btn_auth_start
  btn_auth_clear_local_data
)

missing=0
for id in "${AUTH_IDS[@]}"; do
  found=0
  for dir in "${SOURCE_DIRS[@]}"; do
    if grep -rq "${id}" "${dir}" --include="*.swift"; then
      found=1
      break
    fi
  done
  if [[ "${found}" -eq 0 ]]; then
    echo "FAIL: auth contract id '${id}' not found in production Swift" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "PASS auth contract identifiers present in source (${#AUTH_IDS[@]} ids)"
