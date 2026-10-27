#!/usr/bin/env bash
# Bottom navigation must expose btn_nav_* to XCUITest: a custom bar, not the system TabView.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BAR="${ROOT}/Shared/Components/ExampleBottomNavigation.swift"
TABS="${ROOT}/App/AppTab.swift"

failures=0
fail() {
  echo "FAIL $1" >&2
  failures=$((failures + 1))
}

if grep -rnE "(^|[^A-Za-z])TabView\(|\.tabItem" "${ROOT}/App" --include="*.swift"; then
  fail "system TabView still used for the shell navigation"
fi
if grep -rn "applyTabBarItemIdentifiers" "${ROOT}" --include="*.swift"; then
  fail "UITabBar identifier workaround still present"
fi
[[ -f "${BAR}" ]] || fail "ExampleBottomNavigation.swift missing"
if [[ -f "${BAR}" ]]; then
  grep -q "accessibilityIdentifier(tab.accessibilityId)" "${BAR}" || fail "bottom navigation items do not set btn_nav_* ids"
  grep -q ".isSelected" "${BAR}" || fail "selected tab does not expose the selected trait"
fi
for id in navFetching navTracking navFlushing navAnonymize navContentBlocks; do
  grep -q "A11yID.shell.${id}" "${TABS}" || fail "AppTab does not map ${id}"
done

if [[ ${failures} -gt 0 ]]; then
  exit 1
fi
echo "PASS bottom navigation checks"
