# Example app tests

`ExampleTests` is an XCTest unit-test target hosted by the `Example` app. It runs in the Test action of the `Example` scheme. The tests need no network or credentials and don't call the real SDK.

## Run the tests

In Xcode, select the `Example` scheme and choose **Product** > **Test** (`Cmd + U`).

From the repository root, after `pod install`:

```bash
xcodebuild test \
  -workspace ExponeaSDK.xcworkspace \
  -scheme Example \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

To run the tests from a build artifact on another machine, build with `xcodebuild build-for-testing`, copy the `.xctestrun` file and the `Build/Products` folder, and run `xcodebuild test-without-building -xctestrun <file>`. The test bundle carries every file it reads, so it doesn't need the source checkout.

## What the tests cover

| Test class | Covers |
|-------|--------|
| `AccessibilityContractTests` | Every ID in `A11yID` is in `Contract/automation_contract.yaml` and every contract ID exists in `A11yID`, except the `known_gaps` the app can't apply (which must stay out of `A11yID`). Also checks the contract has no duplicates, IDs are `lower_snake_case`, and every `afterTap` points to a contract ID. |
| `AppIdentityTests` | Bundle ID, display name, URL scheme, app group and associated domain, which test automation and universal links depend on. |
| `DeeplinkActionTests` | `exponea://` and universal link resolution. |
| `ConfigureRequestTests` | Configuration form validation. |
| `EnvConfigTests` | Prefill from `EXPONEA_*` values. |
| `DemoJwtGeneratorTests` | The demo JWT is signed with HS512 and carries the `ids` claim. |
| `ViewModelTests` | Flushing, anonymize, SDK state and the runtime content block lab, through `FakeExponeaService`. |
| `ExponeaServicingContractTests` | `FakeExponeaService` records calls and returns its configured results. |

## Accessibility IDs

The IDs in `A11yID` are shared with test automation and the other Bloomreach SDK example apps. When you add, rename or remove an ID, update `Contract/automation_contract.yaml` too. A shared ID this app can't apply (for example an alert title, which SwiftUI can't give an identifier) stays in the contract and goes into its `known_gaps` list with a reason; once the app applies it, the test asks you to remove it from the list. Keep each `A11yID` namespace a struct with `let` properties: the contract test lists IDs with `Mirror`, which doesn't see `static let`. A new namespace also has to be added to `appNamespaces` in `AccessibilityContractTests`.

The Test action of the `Example` scheme doesn't reuse the Run action's environment and sets `EXPONEA_AUTO_CONFIGURE=false`, so the host app never configures the real SDK during a test run.

The view model tests replace the global `ExponeaService.service`, so the scheme runs `ExampleTests` serially.
