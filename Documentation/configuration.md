---
title: Configuration for iOS SDK
slug: ios-sdk-configuration
category:
  uri: /branches/2/categories/guides/Developers
parent:
  uri: ios-sdk-setup
content:
  excerpt: Full configuration reference for the iOS SDK
---

This page provides an overview of all configuration parameters for the SDK and several examples of how to initialize the SDK with different configurations.

## Configuration parameters

* `projectToken` **(required for Project/{user.mkg} mode)**
   * Your project token. You can find this in the {user.mkg} web app under `Project settings` > `Access management` > `API`.
   * Not used when configuring with Stream integration ({user.dh}).

* `streamId` **(required for Stream/{user.dh} mode)**
   * Your stream ID when using {user.dh} integration.
   * Use `Exponea.StreamSettings(streamId:baseUrl:)` instead of `ProjectSettings` when configuring for Stream mode.
   
* `applicationID`
  * This `applicationID` defines a unique identifier for the mobile app within the {user.mkg} project. Change this value only if your {user.mkg} project contains and supports multiple mobile apps.
  * This identifier distinguishes between different apps in the same project.
  * Your `applicationID` value must be the same as the one defined in your {user.mkg} project settings.
  * If your {user.mkg} project supports only one app, skip the `applicationID` configuration. The SDK will use the default value automatically.
  * Must be in a specific format, see rules:
    * Starts with one or more lowercase letters or digits
    * Additional words are separated by single hyphens or dots
    * No leading or trailing hyphens or dots
    * No consecutive hyphens or dots
    * Maximum length is 50 characters
  * Default value: `default-application`
  
* `authorization` **(required for Project/{user.mkg} mode)**
   * Options are `.none` or `.token(token)`.
   * The token must be an {user.mkg} **public** key. See [Mobile SDKs API Access Management](https://documentation.bloomreach.com/engagement/docs/mobile-sdks-api-access-management) for details.
   * Not used in Stream mode. Stream integration uses JWT via `setSdkAuthToken` instead. See [Stream JWT authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#stream-jwt-authorization-data-hub).
   * For more information, please refer to the {user.mkg} [API documentation](https://documentation.bloomreach.com/engagement/reference/authentication).

* `baseUrl`
  * Your API base URL which can be found in the {user.mkg} web app under `Project settings` > `Access management` > `API`.
  * Default value `https://api.exponea.com`.
  * If you have custom base URL, you must set this property.

* `projectMapping` **(Project/{user.mkg} mode only)**
  * If you need to track events into more than one project, you can define project information for "event types" which should be tracked multiple times.
  * Not available in Stream mode.

* `defaultProperties`
  * A list of properties to be added to all tracking events.
  * Default value: `nil`

* `allowDefaultCustomerProperties`
  * Flag to apply `defaultProperties` list to `identifyCustomer` tracking event
  * Default value: `true`

* `automaticSessionTracking`
  * Flag to control the automatic tracking of `session_start` and `session_end` events.
  * Default value: `true`

* `sessionTimeout`
  * The session is the actual time spent in the app. It starts when the app is launched and ends when the app goes to background.
  * This value is used to calculate the session timing.
  * Default value: `60.0` seconds.
  * The minimum value is `5.0` seconds.
  * The **recommended** maximum value is `120.0` seconds, but the **absolute** max is `180.0` seconds. Higher will cause iOS to kill the session.
  * Read more about [Tracking Sessions](tracking#session)

* `automaticPushNotificationTracking` - DEPRECATED
  * Controls if the SDK will handle push notifications automatically using method swizzling. This feature has been deprecated since its use of method swizzling can cause issues in case the host application uses multiple SDKs that do the same.
  * Replaced by `pushNotificationTracking`. With `pushNotificationTracking` you have more control over what's happening inside your app in addition to making debugging easier. When migrating from `automaticPushNotificationTracking`, some extra work is required. Refer to the [Push notifications for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications) documentation for more details.
  * Default value: `true`

* `pushNotificationTracking`
  * Controls if the SDK will handle push notifications. Registers application to receive push notifications based on `requirePushAuthorization` setting.
  * Default value: `true`

* `appGroup`
  * **Required** for the SDK to track delivered push notifications automatically. Refer to the [Push notifications for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications) documentation for details.

* `requirePushAuthorization`
  * Controls whether the SDK calls `UIApplication.shared.registerForRemoteNotifications()` automatically based on the OS-reported notification authorization status. Your app is responsible for requesting notification permission from the user — the SDK never triggers the permission prompt itself.
  * When `true` (default), the SDK only calls `registerForRemoteNotifications()` once the OS reports `UNAuthorizationStatus.authorized` or `.provisional` ([Apple documentation](https://developer.apple.com/documentation/usernotifications/unnotificationsettings/1648391-authorizationstatus)). Use this when your app prefers not to receive an APNs token (and therefore not to track one) until the user has explicitly granted notification permission.
  * When `false`, the SDK calls `registerForRemoteNotifications()` unconditionally on every launch so the app keeps receiving silent (background) pushes regardless of the user's visible push permission state.
  * This flag doesn't affect the `valid` field in `notification_state` events — `valid` reflects the OS-reported authorization status directly. A token tracked before the user grants permission is reported as `valid=false/description=Permission denied`, and updates to `valid=true/description=Permission granted` once the OS reports `.authorized` or `.provisional`, regardless of how `requirePushAuthorization` is configured.
  * Default value: `true`

* `tokenTrackFrequency`
  * Indicates the frequency with which the APNs token should be tracked to {user.mkg}.
  * Default value: `onTokenChange`
  * Possible values:
    * `onTokenChange` — tracks the push token whenever it differs from the previously tracked one. The SDK also automatically tracks a new `notification_state` event every 30 days, even when the token hasn't changed, to keep customers within the validity window.
    * `everyLaunch` — tracks the push token once per app launch (process start). All other SDK operations during that process reuse this tracking, so each cold launch produces a single frequency-based `notification_state` event. Background-to-foreground transitions within the same process don't re-track unless an override applies (permission change, token change, or manual `trackPushToken()`).
    * `daily` - tracks the push token at most once per local calendar day. The day boundary follows the device's current calendar/timezone, so a track at 23:59 followed by an app open at 00:05 the next day correctly tracks a fresh `notification_state` event.
  * Regardless of the configured frequency, the SDK always tracks a fresh `notification_state` event when the OS push authorization status flips (granted ↔ denied) so the resulting `valid` flag stays in sync with the user's actual permission state.
  * Some operations bypass the `everyLaunch` per-process limit and always trigger tracking mid-process:
    * OS push authorization status flips (granted ↔ denied) since the last tracked `notification_state`.
    * Manual tracking through `trackPushToken()`.
    * Receiving a new token from APNs when the token string changes.
    * Calling `anonymize()` or `stopIntegration()` (these recreate the push-tracking session, so the next track is a fresh per-process launch rather than a mid-process override).
  *  The SDK detects app version or `application_id` changes at startup. The version or ID affect only the `onTokenChange`/`daily` staleness checks, and aren't a mid-process override for `everyLaunch`. A new process always tracks once regardless of any version or application ID changes.

* `regenerateDeviceIdOnAnonymize`
  * When `true`, calling `Exponea.shared.anonymize()` clears the SDK's persisted telemetry `device_id` (a UUID stored in `UserDefaults`) in addition to creating a new customer profile. The next event tracked after anonymization carries a freshly-generated `device_id`, so the new profile can't be linked back to the previous customer's events through the device identifier.
  * Set this to `true` when your privacy requirements call for a sign-out + sign-in flow that produces two unlinkable customer profiles. The default (`false`) preserves the existing behavior where `device_id` persists across `anonymize()` calls for telemetry continuity (for example, crash-rate dashboards keyed on `device_id`).
  * The flag only affects `anonymize()`. The full-teardown behavior `stopIntegration()` always rotates the `device_id` regardless of this flag, as part of its broader teardown contract.
  * Default value: `false`

* `flushEventMaxRetries`
  * Controls how many times an event should be flushed before aborting. Useful for example in case the API is down or some other temporary error happens.
  * Default value: `5`

* `advancedAuthEnabled`
  * If set to `true`, the SDK uses [customer token](https://documentation.bloomreach.com/engagement/docs/customer-token) authorization for communication with the {user.mkg} APIs listed in [Customer Token Authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#customer-token-authorization).
  * Refer the [Authorization for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization) documentation for details.
  * Not used in Stream mode; Stream uses JWT via `setSdkAuthToken` instead.
  * Default value: `false`

### Stream integration ({user.dh})

When integrating with {user.dh}, use `Exponea.StreamSettings` instead of `ProjectSettings`:

```swift
Exponea.shared.configure(
    Exponea.StreamSettings(
        streamId: "YOUR_STREAM_ID",
        baseUrl: "https://api.exponea.com"
    ),
    pushNotificationTracking: .disabled,
    // ... other parameters
)
```

After configuration, provide the Stream JWT token via `Exponea.shared.setSdkAuthToken("YOUR_JWT")` and register a JWT error handler with `setJwtErrorHandler`. See [Stream JWT authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#stream-jwt-authorization-data-hub) for details.

### Parameter availability by integration mode

| Parameter | Project/{user.mkg} | Stream/{user.dh} |
| --- | --- | --- |
| `projectToken` | Required | Not used |
| `streamId` | Not used | Required |
| `authorization` | Required | Not used (JWT via `setSdkAuthToken`) |
| `projectMapping` | Optional | Not available |
| `baseUrl` | Optional | Optional |
| `applicationID` | Optional | Optional |
| `advancedAuthEnabled` | Optional | Not used |
| `pushNotificationTracking` | Optional | Optional |
| `defaultProperties` | Optional | Optional |
| `automaticSessionTracking` | Optional | Optional |
| `sessionTimeout` | Optional | Optional |
| `flushEventMaxRetries` | Optional | Optional |
| `regenerateDeviceIdOnAnonymize` | Optional | Optional |
| `inAppContentBlocksPlaceholders` | Optional | Optional |
| `manualSessionAutoClose` | Optional | Optional |
| `prewarmInAppContentBlocks` | Optional | Optional |

* `inAppContentBlocksPlaceholders`
  * If set, all [In-app content blocks for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-in-app-content-blocks) will be prefetched right after the SDK is initialized.

* `manualSessionAutoClose`
  * Determines whether the SDK automatically tracks `session_end` for sessions that remain open when `Exponea.shared.trackSessionStart()` is called multiple times in manual session tracking mode.
  * Default value: `true`

* `prewarmInAppContentBlocks`
  * When `true`, the SDK prepares in-app content block web views on the main thread before the first content block renders, so content appears faster. It does this shortly after `configure` on the first app start without in-app content block history, such as after you install the app or update from an SDK version without this behavior. It also does this whenever in-app content blocks rendered on this device in the last 30 days, and after a prefetch (see `inAppContentBlocksPlaceholders`) that finds content to show.
  * The first `WKWebView` created in an app process initializes WebKit, which can block the main thread for a few hundred milliseconds on older devices. To skip the preparation, set this to `false`. The SDK then creates no web view until a content block has content to show. The WebKit setup cost moves to the first content block that renders content, and the SDK doesn't keep a spare web view ready for the next placeholder after a render.
  * When this is `false`, in-app content blocks shown through `prepareInAppContentBlockView` in a table or collection view still create their height calculator as soon as they start loading content. Each cell's web view is created when that cell renders.
  * The setting applies from `configure` onward. If your app reads a placeholder's `calculator` before `configure`, the SDK can still keep one spare web view ready.
  * Set it on the `Configuration` object that you pass to `Exponea.shared.configure(with:)`. For details, see [Using a Configuration object](#using-a-configuration-object).
  * Default value: `true`

## Configure the SDK

### Configure the SDK programmatically

Configuration is split into several objects that are passed into the `Exponea.shared.configure()` function. The first parameter accepts either `ProjectSettings` (for {user.mkg}) or `StreamSettings` (for {user.dh}) via the `IntegrationType` protocol:

``` swift
func configure(
    _ integrationConfig: any IntegrationType,
    pushNotificationTracking: PushNotificationTracking,
    automaticSessionTracking: AutomaticSessionTracking = .enabled(),
    defaultProperties: [String: JSONConvertible]? = nil,
    flushingSetup: FlushingSetup = FlushingSetup.default,
    applicationID: String? = nil
)
```

* `integrationConfig` **(required)** — one of:
  * `ProjectSettings` — for Project/{user.mkg} integration. Contains `projectToken` (required), `authorization` (required), `baseUrl` (optional), and `projectMapping` (optional).
  * `StreamSettings` — for Stream/{user.dh} integration. Contains `streamId` (required) and `baseUrl` (optional, defaults to `https://api.exponea.com`). Does not include `authorization` or `projectMapping`; authentication is handled separately via `setSdkAuthToken`.

* `pushNotificationTracking` **(required)**
  * Either `.disabled` or `.enabled(appGroup, delegate, requirePushAuthorization, tokenTrackFrequency)`. Only `appGroup` is required for the SDK to function correctly.
  * Setting `delegate` has the same effect as setting `Exponea.shared.pushNotificationsDelegate`.

* `automaticSessionTracking`
  * Either `.disabled` or `.enabled(timeout)`.
  * Default value: `enabled()` (recommended, uses default session timeout)

* `defaultProperties`
  * As described above in [Configuration Parameters](#configuration-parameters).

* `flushingSetup`
  * Allows you to set up `flushingMode` and `maxRetries`. By default, event flush happens as soon as you track an event (`.immediate`). You can change this behavior to one of `.manual`, `.automatic`, `periodic(period)`.
  * See [Data flushing for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-data-flushing) for details.

#### Project/{user.mkg} examples

Most common use case:

``` swift
Exponea.shared.configure(
    Exponea.ProjectSettings(
        projectToken: "YOUR PROJECT TOKEN",
        authorization: .token("YOUR ACCESS TOKEN")
    ),
    pushNotificationTracking: .enabled(appGroup: "YOUR APP GROUP")
)
```

Disabling all the automatic features of the SDK:

``` swift
Exponea.shared.configure(
    Exponea.ProjectSettings(
        projectToken: "YOUR PROJECT TOKEN",
        authorization: .token("YOUR ACCESS TOKEN")
    ),
    pushNotificationTracking: .disabled,
    automaticSessionTracking: .disabled,
    flushingSetup: Exponea.FlushingSetup(mode: .manual)
)
```

Complex use-case with project mapping and advanced auth:

``` swift
Exponea.shared.configure(
    Exponea.ProjectSettings(
        projectToken: "YOUR PROJECT TOKEN",
        authorization: .token("YOUR ACCESS TOKEN"),
        baseUrl: "YOUR URL",
        projectMapping: [
            .payment: [
                ExponeaProject(
                    baseUrl: "YOUR URL",
                    projectToken: "YOUR OTHER PROJECT TOKEN",
                    authorization: .token("YOUR OTHER ACCESS TOKEN")
                )
            ]
        ]
    ),
    pushNotificationTracking: .enabled(
        appGroup: "YOUR APP GROUP",
        delegate: self,
        requirePushAuthorization: false,
        tokenTrackFrequency: .onTokenChange
    ),
    automaticSessionTracking: .enabled(timeout: 123),
    defaultProperties: ["prop-1": "value-1", "prop-2": 123],
    flushingSetup: Exponea.FlushingSetup(mode: .periodic(100), maxRetries: 5),
    advancedAuthEnabled: true,
    applicationID: "com.yourApplication.org"
)
```

> 📘 Configuration-only flags
>
> `regenerateDeviceIdOnAnonymize`, `prewarmInAppContentBlocks`, and similar advanced flags aren't available as parameters on `Exponea.shared.configure(_:)`. To set them, construct a `Configuration` object directly and pass it to `Exponea.shared.configure(with:)`. For details, see [Using a Configuration object](#using-a-configuration-object).

#### Stream/{user.dh} examples

Simple Stream configuration:

``` swift
Exponea.shared.configure(
    Exponea.StreamSettings(
        streamId: "YOUR_STREAM_ID",
        baseUrl: "https://api.exponea.com"
    ),
    pushNotificationTracking: .disabled
)

// After configuration, provide JWT and register error handler:
Exponea.shared.setJwtErrorHandler { context in
    // Fetch new token from your backend and call setSdkAuthToken
    yourBackend.fetchNewJwt { newToken in
        Exponea.shared.setSdkAuthToken(newToken)
    }
}
Exponea.shared.setSdkAuthToken("YOUR_STREAM_JWT_TOKEN")
```

Stream with push notifications:

``` swift
Exponea.shared.configure(
    Exponea.StreamSettings(
        streamId: "YOUR_STREAM_ID",
        baseUrl: "https://api.exponea.com"
    ),
    pushNotificationTracking: .enabled(appGroup: "YOUR APP GROUP")
)

Exponea.shared.setJwtErrorHandler { context in
    yourBackend.fetchNewJwt { newToken in
        Exponea.shared.setSdkAuthToken(newToken)
    }
}
Exponea.shared.setSdkAuthToken("YOUR_STREAM_JWT_TOKEN")
```

Stream with all options:

``` swift
Exponea.shared.configure(
    Exponea.StreamSettings(
        streamId: "YOUR_STREAM_ID",
        baseUrl: "https://api.exponea.com"
    ),
    pushNotificationTracking: .enabled(
        appGroup: "YOUR APP GROUP",
        delegate: self,
        requirePushAuthorization: false,
        tokenTrackFrequency: .onTokenChange
    ),
    automaticSessionTracking: .enabled(timeout: 123),
    defaultProperties: ["prop-1": "value-1", "prop-2": 123],
    flushingSetup: Exponea.FlushingSetup(mode: .periodic(100), maxRetries: 5),
    applicationID: "com.yourApplication.org"
)

Exponea.shared.setJwtErrorHandler { context in
    yourBackend.fetchNewJwt { newToken in
        Exponea.shared.setSdkAuthToken(newToken)
    }
}
Exponea.shared.setSdkAuthToken("YOUR_STREAM_JWT_TOKEN")
```

> ❗️
>
> In Stream mode, always call `setJwtErrorHandler` before `setSdkAuthToken` so that proactive refresh notifications are handled from the start. See [Stream JWT authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#stream-jwt-authorization-data-hub) for details on JWT lifecycle management.

#### Using a Configuration object

`regenerateDeviceIdOnAnonymize`, `prewarmInAppContentBlocks`, and similar advanced flags aren't available as parameters on `Exponea.shared.configure(_:)`. To set them, construct a `Configuration` object directly and pass it to `Exponea.shared.configure(with:)`.

Project/{user.mkg}:

``` swift
let configuration = try Configuration(
    integrationConfig: Exponea.ProjectSettings(
        projectToken: "YOUR PROJECT TOKEN",
        authorization: .token("YOUR ACCESS TOKEN")
    ),
    appGroup: "YOUR APP GROUP",
    regenerateDeviceIdOnAnonymize: true // opt-in; default `false` preserves legacy behavior
)
Exponea.shared.configure(with: configuration)

// If you relied on the convenience overload's `pushNotificationTracking:` parameter to
// auto-wire a delegate, set `Exponea.shared.pushNotificationsDelegate = self` explicitly
// when using the Configuration-object path.
```

Stream/{user.dh}:

``` swift
let configuration = try Configuration(
    integrationConfig: Exponea.StreamSettings(
        streamId: "YOUR_STREAM_ID",
        baseUrl: "https://api.exponea.com"
    ),
    appGroup: "YOUR APP GROUP",
    regenerateDeviceIdOnAnonymize: true
)
Exponea.shared.configure(with: configuration)

Exponea.shared.setJwtErrorHandler { context in
    yourBackend.fetchNewJwt { newToken in
        Exponea.shared.setSdkAuthToken(newToken)
    }
}
Exponea.shared.setSdkAuthToken("YOUR_STREAM_JWT_TOKEN")
```

To avoid creating in-app content block web views before a content block renders, disable the prewarm:

``` swift
let configuration = try Configuration(
    integrationConfig: Exponea.ProjectSettings(
        projectToken: "YOUR PROJECT TOKEN",
        authorization: .token("YOUR ACCESS TOKEN")
    ),
    appGroup: "YOUR APP GROUP",
    prewarmInAppContentBlocks: false // default `true`
)
Exponea.shared.configure(with: configuration)
```


### Using a configuration file - LEGACY
> ❗️ 
> 
> Configuring the SDK using a `plist` file is deprecated but still supported for backward compatibility.

Create a configuration `.plist` file containing at least the required configuration variables.
``` swift
public func configure(plistName: String)
```

#### Example

```
Exponea.shared.configure(plistName: "ExampleConfig.plist")
```

#### Project plist example

*ExampleConfig.plist*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>projectToken</key>
	<string>testToken</string>
	<key>sessionTimeout</key>
	<integer>20</integer>
	<key>applicationID</key>
	<string>com.yourApplication.org</string>
	<key>projectMapping</key>
	<dict>
		<key>INSTALL</key>
		<array>
			<dict>
				<key>projectToken</key>
				<string>testToken1</string>
				<key>authorization</key>
				<string>Token authToken1</string>
			</dict>
		</array>
		<key>TRACK_EVENT</key>
		<array>
			<dict>
				<key>projectToken</key>
				<string>testToken2</string>
				<key>authorization</key>
				<string>Token authToken2</string>
			</dict>
			<dict>
				<key>projectToken</key>
				<string>testToken3</string>
				<key>authorization</key>
				<string></string>
			</dict>
		</array>
		<key>PAYMENT</key>
		<array>
			<dict>
				<key>baseUrl</key>
				<string>https://mock-base-url.com</string>
				<key>projectToken</key>
				<string>testToken4</string>
				<key>authorization</key>
				<string>Token authToken4</string>
			</dict>
		</array>
	</dict>
	<key>autoSessionTracking</key>
	<false/>
</dict>
</plist>
```

#### Stream plist example

For Stream/{user.dh} integration, use `streamId` instead of `projectToken` and `authorization`:

*StreamConfig.plist*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>streamId</key>
	<string>YOUR_STREAM_ID</string>
	<key>sessionTimeout</key>
	<integer>20</integer>
	<key>automaticSessionTracking</key>
	<false/>
</dict>
</plist>
```

> After plist-based configuration in Stream mode, you still need to provide the JWT token programmatically via `Exponea.shared.setSdkAuthToken("YOUR_JWT")` and register an error handler with `setJwtErrorHandler`.


