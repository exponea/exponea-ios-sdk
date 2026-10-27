#!/usr/bin/env bash
# Example app local verification entry point (no Xcode test target required).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTRACT="${ROOT}/Tests/Contract"

run_check() {
  local name="$1"
  local script="$2"
  echo "== ${name} =="
  if ! "${script}"; then
    echo "FAIL: ${name}" >&2
    exit 1
  fi
}

run_check "app identity" "${CONTRACT}/verify_app_identity.sh"
run_check "loading route" "${CONTRACT}/verify_loading_route.sh"
run_check "manifest integrity" "${CONTRACT}/verify_manifest_integrity.sh"
run_check "identifier coverage" "${CONTRACT}/verify_identifier_coverage.sh"
run_check "shell contract ids" "${CONTRACT}/verify_shell_contract_ids.sh"
run_check "configure validation" "${CONTRACT}/verify_configure_request_validation.sh"
run_check "env config" "${CONTRACT}/verify_env_config.sh"
run_check "auth contract ids" "${CONTRACT}/verify_auth_contract_ids.sh"
run_check "stream auth listener" "${CONTRACT}/verify_stream_auth_listener.sh"
run_check "demo jwt" "${CONTRACT}/verify_demo_jwt.sh"
run_check "tracking contract ids" "${CONTRACT}/verify_tracking_contract_ids.sh"
run_check "fetching contract ids" "${CONTRACT}/verify_fetching_contract_ids.sh"
run_check "flushing contract ids" "${CONTRACT}/verify_flushing_contract_ids.sh"
run_check "anonymize contract ids" "${CONTRACT}/verify_anonymize_contract_ids.sh"
run_check "content blocks contract ids" "${CONTRACT}/verify_content_blocks_contract_ids.sh"
run_check "logs contract ids" "${CONTRACT}/verify_logs_contract_ids.sh"
run_check "brand palette" "${CONTRACT}/verify_brand_palette.sh"
run_check "bottom navigation" "${CONTRACT}/verify_bottom_navigation.sh"
run_check "ExponeaServicing source contract" "${ROOT}/Tests/Service/verify_exponea_servicing_source.sh"

echo "PASS example app local verification (all checks)"
