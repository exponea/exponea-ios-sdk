#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INFO="${ROOT}/Resources/Info.plist"
ENTITLEMENTS="${ROOT}/Resources/Example.entitlements"
SERVICE="${ROOT}/Shared/SDK/ExponeaService.swift"
DELEGATE="${ROOT}/App/AppDelegate.swift"
DEEPLINKS="${ROOT}/App/Deeplinks.swift"
APP="${ROOT}/App/ExampleApp.swift"
PROJECT="${ROOT}/../ExponeaSDK.xcodeproj/project.pbxproj"

assert_equal() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "FAIL ${label}: expected '${expected}', got '${actual}'" >&2
    return 1
  fi
}

assert_contains() {
  local file="$1"
  local text="$2"
  local label="$3"
  if ! grep -Fq "${text}" "${file}"; then
    echo "FAIL ${label}: '${text}' not found in ${file}" >&2
    return 1
  fi
}

display_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "${INFO}")"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${INFO}")"
url_scheme="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes:0:CFBundleURLSchemes:0' "${INFO}")"
app_group="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.application-groups:0' "${ENTITLEMENTS}")"
associated_domain="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.associated-domains:0' "${ENTITLEMENTS}")"

assert_equal "Bloomreach SDK Demo" "${display_name}" "display name"
assert_equal '$(PRODUCT_BUNDLE_IDENTIFIER)' "${bundle_id}" "bundle id comes from the build setting"
assert_contains "${PROJECT}" 'PRODUCT_BUNDLE_IDENTIFIER = com.exponea.sdk.example;' "bundle id build setting"
assert_equal "exponea" "${url_scheme}" "URL scheme"
assert_equal "group.com.exponea.sdk.example" "${app_group}" "app group"
assert_equal "applinks:mobile-sdk-example-apps.web.app" "${associated_domain}" "associated domain"
assert_contains "${SERVICE}" 'static let appGroup = "group.com.exponea.sdk.example"' "service app group"
assert_contains "${SERVICE}" 'pushNotificationTracking: .enabled(' "automatic push tracking"
assert_contains "${DELEGATE}" '@objc(IsExponeaExampleApp)' "example-app marker"
# Scene-based SwiftUI app: URLs arrive through onOpenURL, not UIApplicationDelegate.
assert_contains "${APP}" '.onOpenURL' "deeplink entry point"
assert_contains "${DEEPLINKS}" 'Exponea.shared.trackCampaignClick(url: url, timestamp: nil)' "campaign click forwarding"
if grep -q "func application(.*open url\|continue userActivity" "${DELEGATE}"; then
  echo "FAIL dead AppDelegate URL handlers still present" >&2
  exit 1
fi

echo "PASS example app identity (name, bundle, scheme, app group, deeplinks)"
