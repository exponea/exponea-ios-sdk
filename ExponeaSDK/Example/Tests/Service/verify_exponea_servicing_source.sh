#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVICE="${ROOT}/Shared/SDK/ExponeaService.swift"
FAKE="${ROOT}/Tests/Service/FakeExponeaService.swift"
TESTS="${ROOT}/Tests/Service/ExponeaServicingContractTests.swift"

require_contains() {
  local file="$1"
  local text="$2"
  local label="$3"
  if ! grep -Fq "${text}" "${file}"; then
    echo "FAIL ${label}: missing '${text}' in ${file}" >&2
    exit 1
  fi
}

for file in "${SERVICE}" "${FAKE}" "${TESTS}"; do
  if [[ ! -f "${file}" ]]; then
    echo "FAIL: missing ${file}" >&2
    exit 1
  fi
done

require_contains "${SERVICE}" "protocol ExponeaServicing" "production protocol"
require_contains "${SERVICE}" "final class LiveExponeaService: ExponeaServicing" "production adapter"
require_contains "${FAKE}" "final class FakeExponeaService: ExponeaServicing" "fake service"
require_contains "${FAKE}" "var recordedCalls" "fake call recording"
require_contains "${TESTS}" "FakeExponeaService()" "contract tests use fake"
require_contains "${TESTS}" "recordedCalls" "contract tests observe calls"
require_contains "${TESTS}" "XCTAssertEqual(fake.recordedCalls" "contract tests assert recording"

echo "PASS ExponeaServicing source contract (XCTest not executed; manual target wiring required)"
