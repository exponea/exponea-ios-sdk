# Example app local verification

Executable checks live under `Tests/` and do not require an Xcode test target.

## Run everything

```bash
./Tests/run_all.sh
```

## Checks included

| Check | Script |
|-------|--------|
| App identity | `Tests/Contract/verify_app_identity.sh` |
| Automation manifest integrity (`Tests/Contract/automation_contract.yaml`) | `Tests/Contract/verify_manifest_integrity.sh` |
| Identifier coverage + allowlist | `Tests/Contract/verify_identifier_coverage.sh` |
| Env config / credentials | `Tests/Contract/verify_env_config.sh` |
| ExponeaServicing source contract | `Tests/Service/verify_exponea_servicing_source.sh` |

## Credentials prefill

See [Prefill the configuration screen](../README.md#prefill-the-configuration-screen) in the example app README.

## XCTest status

`Tests/Service/ExponeaServicingContractTests.swift` is **source-only**. It is not wired into an Xcode test target and is **not executed** by `run_all.sh`.

To run XCTest later (manual prerequisite):

1. Add an example app unit-test target in Xcode.
2. Include `Tests/Service/*.swift` in that target.
3. Run tests from Xcode or `xcodebuild test`.

`run_all.sh` verifies the fake service and protocol API via static source checks instead.

## Simulator build

`run_all.sh` does not build the app. Use `scripts/install_simulator.sh` after visual-facing changes.
