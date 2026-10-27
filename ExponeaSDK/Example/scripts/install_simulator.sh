#!/usr/bin/env bash
# Build the example app and reinstall on an iOS Simulator for manual visual review.
# Lives in Example; invokes xcodebuild from the parent iOS SDK repo (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SDK_ROOT="$(cd "${EXAMPLE_ROOT}/../.." && pwd)"
WORKSPACE="${SDK_ROOT}/ExponeaSDK.xcworkspace"

DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/ExampleDerivedData}"
SCHEME="${EXAMPLE_SCHEME:-Example}"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found (install Xcode)." >&2
  exit 1
fi

if [[ ! -d "${WORKSPACE}" ]]; then
  echo "error: workspace not found at ${WORKSPACE}" >&2
  exit 1
fi

resolve_simulator_udid() {
  if [[ -n "${SIMULATOR_UDID:-}" ]]; then
    echo "${SIMULATOR_UDID}"
    return
  fi

  local booted
  booted="$(xcrun simctl list devices booted 2>/dev/null | grep -E '\(Booted\)' | head -1 | sed -E 's/.*\(([A-F0-9-]+)\) \(Booted\).*/\1/' || true)"
  if [[ -n "${booted}" ]]; then
    echo "${booted}"
    return
  fi

  local fallback
  fallback="$(xcrun simctl list devices available 2>/dev/null | grep 'iPhone 17 Pro (' | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || true)"
  if [[ -n "${fallback}" ]]; then
    echo "${fallback}"
    return
  fi

  echo "error: no booted simulator and no iPhone 17 Pro available; set SIMULATOR_UDID." >&2
  exit 1
}

UDID="$(resolve_simulator_udid)"
echo "Using simulator: ${UDID}"

xcrun simctl boot "${UDID}" 2>/dev/null || true
open -a Simulator >/dev/null 2>&1 || true

echo "Building ${SCHEME} for iOS Simulator..."
xcodebuild \
  -workspace "${WORKSPACE}" \
  -scheme "${SCHEME}" \
  -destination "platform=iOS Simulator,id=${UDID}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  build

APP_PATH="${DERIVED_DATA_PATH}/Build/Products/Debug-iphonesimulator/${SCHEME}.app"
if [[ ! -d "${APP_PATH}" ]]; then
  echo "error: built app not found at ${APP_PATH}" >&2
  exit 1
fi

CREDENTIALS_FILE="${EXAMPLE_ROOT}/Resources/credentials.json"
if [[ -f "${CREDENTIALS_FILE}" ]]; then
  echo "Injecting credentials from ${CREDENTIALS_FILE}..."
  python3 "${SCRIPT_DIR}/inject_credentials_plist.py" "${APP_PATH}/Info.plist" "${CREDENTIALS_FILE}"
else
  echo "No ${CREDENTIALS_FILE}; copy credentials.example.json to credentials.json to prefill auth."
fi

BUNDLE_ID="${EXAMPLE_BUNDLE_ID:-}"
if [[ -z "${BUNDLE_ID}" ]]; then
  BUNDLE_ID="$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${APP_PATH}/Info.plist")"
fi

echo "Installing ${APP_PATH}..."
xcrun simctl install "${UDID}" "${APP_PATH}"

echo "Launching ${BUNDLE_ID}..."
xcrun simctl launch "${UDID}" "${BUNDLE_ID}"

echo "Example app reinstalled and launched on simulator ${UDID}."
