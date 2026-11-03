# Exponea iOS SDK example app

SwiftUI example app for the Bloomreach Engagement iOS SDK. Each SDK feature has its own screen, and interactive elements carry stable accessibility identifiers (`Shared/Components/A11yID.swift`), so the app works both as a reference implementation and as a target for UI automation.

## Requirements

- Xcode with an iOS 15.0 or later simulator or device
- [CocoaPods](https://cocoapods.org/)

## Build and run

From the repository root:

```bash
pod install
open ExponeaSDK.xcworkspace
```

Select the **Example** scheme and run it. From the command line:

```bash
xcodebuild build -workspace ExponeaSDK.xcworkspace -scheme Example \
  -destination 'platform=iOS Simulator,name=<iPhone simulator>'
```

The app starts on the **SDK Configuration** screen. After **Start**, bottom navigation opens the **Fetching**, **Tracking**, **Flushing**, **Anonymize** and **In-app CB** screens. The toolbar has the SDK status indicator, the configuration overview, the logs sheet and **Reset**. For a walkthrough, see [Example app for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app).

## App identity

| | Value |
|---|---|
| Bundle identifier | `com.exponea.sdk.example` |
| URL scheme | `exponea` |
| Associated domain | `applinks:mobile-sdk-example-apps.web.app` |
| App group | `group.com.exponea.sdk.example` |

## Prefill the configuration screen

The app reads `EXPONEA_*` values from the launch environment first, then from `Info.plist`:

- **Xcode scheme:** add the keys as environment variables under **Product** > **Scheme** > **Edit Scheme** > **Run** > **Arguments**. They apply only when Xcode launches the app.
- **Credentials file (simulator):** from `ExponeaSDK/Example`, copy the committed template and fill it in. `credentials.json` is git-ignored.

  ```bash
  cp Resources/credentials.example.json Resources/credentials.json
  ./scripts/install_simulator.sh
  ```

  The script builds the **Example** scheme, injects the values into the built app's `Info.plist`, then installs and launches it on the booted simulator. Set `SIMULATOR_UDID` to choose a simulator.

Keys: `EXPONEA_INTEGRATION_MODE` (`project` or `stream`), `EXPONEA_PROJECT_TOKEN`, `EXPONEA_AUTHORIZATION_TOKEN`, `EXPONEA_STREAM_ID`, `EXPONEA_JWT_KEY_ID`, `EXPONEA_JWT_SECRET`, `EXPONEA_BASE_URL`, `EXPONEA_CUSTOMER_ID`, `EXPONEA_AUTO_CONFIGURE`.

With complete credentials the app initializes the SDK at launch. Set `EXPONEA_AUTO_CONFIGURE` to `false` to only prefill the form and tap **Start** yourself.

After a successful **Start**, the app saves the form values (except the JWT secret) and prefills them on the next launch; saved values take precedence over `EXPONEA_*` values. **Clear Local Data** deletes them. This is a demo convenience: production apps shouldn't store API credentials like this, and never ship a JWT signing secret.

Never commit real credentials.

## Push notifications

To receive pushes, [configure Apple Push Notification Service](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configure-apns) for your project. The app delegate subclasses `ExponeaAppDelegate`, which forwards the push token, opened pushes and silent pushes to the SDK.

The `ExampleNotificationService` and `ExampleNotificationContent` extensions (app group `group.com.exponea.sdk.example`) handle images, action buttons and delivery tracking. Rich push needs a physical device.

In debug builds on a physical device, the app turns on the SDK's push setup self-check, which reports its result in an alert a few seconds after **Start**. While the self-check is on, the SDK tracks the push token even if the user hasn't granted notification permission. To turn it off, remove `Exponea.shared.checkPushSetup = true` from `Shared/SDK/ExponeaService.swift`.

## Deeplinks

`exponea://` links and universal links on `mobile-sdk-example-apps.web.app` open the matching screen when the link contains `fetch`, `track`, `flush`, `anonymize` or `inappcb`. `stopAndContinue` and `stopAndRestart` stop the SDK integration. For example:

```bash
xcrun simctl openurl booted "exponea://track"
```

## Tests

The `ExampleTests` target runs with the `Example` scheme's Test action (`Cmd + U`), or from the repository root:

```bash
xcodebuild test -workspace ExponeaSDK.xcworkspace -scheme Example -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The tests check accessibility identifiers against `Tests/Contract/automation_contract.yaml`, app identity, deeplinks, configuration validation and view models. See [Tests/README.md](Tests/README.md).
