#!/usr/bin/env bash
# Bloomreach brand checks: palette, yellow as fill only, button style, logo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
THEME="${ROOT}/Shared/Theme/ExampleTheme.swift"
SOURCES=("${ROOT}/App" "${ROOT}/Configuration" "${ROOT}/Features" "${ROOT}/Shared")

failures=0
fail() {
  echo "FAIL $1" >&2
  failures=$((failures + 1))
}

for token in 0xFFD500 0x111111 0xF5F5F5 0xEEEEEE 0xDDDDDD 0xBDBDBD 0x666666 0x424242 0xD32F2F 0x2E7D32; do
  grep -q "${token}" "${THEME}" || fail "palette token ${token} missing in ExampleTheme.swift"
done

# Rejected colours: #FEED1B, #FFD400, #009ACE (hex or 0-255 component form).
if grep -rniE "FEED1B|FFD400|009ACE|green: 237 / 255|green: 154 / 255, blue: 206" "${SOURCES[@]}" --include="*.swift"; then
  fail "rejected brand colour found"
fi

if grep -rnE "\.(tint|foregroundColor|foregroundStyle|accentColor)\((BrandColors\.brYellow|\.brYellow|Color\.yellow)" "${SOURCES[@]}" --include="*.swift"; then
  fail "yellow used as a text/tint colour (yellow is a fill only)"
fi

if grep -rnF 'Text("b")' "${SOURCES[@]}" --include="*.swift"; then
  fail "text glyph used as the Bloomreach logo"
fi

primary="$(awk '/struct ExamplePrimaryButtonStyle/,/^}/' "${THEME}")"
grep -q "minHeight: 44" <<<"${primary}" || fail "primary button min height is not 44"
grep -q "weight: .bold" <<<"${primary}" || fail "primary button text is not bold"

if [[ ${failures} -gt 0 ]]; then
  exit 1
fi
echo "PASS brand palette and component checks"
