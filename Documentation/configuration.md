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

* `projectToken` **(required for Project/Engagement mode)**
   * Your project token. You can find this in the Engagement web app under `Project settings` > `Access management` > `API`.
   * Not used when configuring with Stream integration (Data hub).

* `streamId` **(required for Stream/Data hub mode)**
   * Your stream ID when using Data hub integration.
   * Use `Exponea.StreamSettings(streamId:baseUrl:)` instead of `ProjectSettings` when configuring for Stream mode.
   
* `applicationID`
  * This `applicationID` defines a unique identifier for the mobile app within the Engagement project. Change this value only if your Engagement project contains and supports multiple mobile apps.
  * This identifier distinguishes between different apps in the same project.
  * Your `applicationID` value must be the same as the one defined in your Engagement project settings.
  * If your Engagement project supports only one app, skip the `applicationID` configuration. The SDK will use the default value automatically.
  * Must be in a specific format, see rules:
    * Starts with one or more lowercase letters or digits
    * Additional words are separated by single hyphens or dots
    * No leading or trailing hyphens or dots
    * No consecutive hyphens or dots
    * Maximum length is 50 characters
  * Default value: `default-application`
  
* `authorization` **(required for Project/Engagement mode)**
   * Options are `.none` or `.token(token)`.
   * The token must be an Engagement **public** key. See [Mobile SDKs API Access Management](https://documentation.bloomreach.com/engagement/docs/mobile-sdks-api-access-management) for details.
   * Not used in Stream mode. Stream integration uses JWT via `setSdkAuthToken` instead. See [Stream JWT authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#stream-jwt-authorization-data-hub).
   * For more information, please refer to the [Bloomreach Engagement API documentation](https://documentation.bloomreach.com/engagement/reference/authentication).

* `baseUrl`
  * Your API base URL which can be found in the Engagement web app under `Project settings` > `Access management` > `API`.
  * Default value `https://api.exponea.com`.
  * If you have custom base URL, you must set this property.

* `projectMapping` **(Project/Engagement mode only)**
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
  * The SDK can check push notification authorization status ([Apple documentation](https://developer.apple.com/documentation/usernotifications/unnotificationsettings/1648391-authorizationstatus)) and only track the push token if the user is authorized to receive push notifications.
  * When disabled, the SDK will automatically register for push notifications on app start and track the token to Engagement so your app can receive silent push notifications. 
  * When enabled, the SDK will automatically register for push notifications if the app is authorized to show push notifications to the user.
  * Default value: `true`

* `tokenTrackFrequency`
  * Indicates the frequency with which the APNs token should be tracked to Engagement.
  * Default value: `onTokenChange`
  * Possible values:
    * `onTokenChange` - tracks push token if it differs from a previously tracked one
    * `everyLaunch` - always tracks push token
    * `daily` - tracks push token once per day

* `flushEventMaxRetries`
  * Controls how many times an event should be flushed before aborting. Useful for example in case the API is down or some other temporary error happens.
  * Default value: `5`

* `advancedAuthEnabled`
  * If set to `true`, the SDK uses [customer token](https://documentation.bloomreach.com/engagement/docs/customer-token) authorization for communication with the Engagement APIs listed in [Customer Token Authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#customer-token-authorization).
  * Refer the [Authorization for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization) documentation for details.
  * Not used in Stream mode; Stream uses JWT via `setSdkAuthToken` instead.
  * Default value: `false`

### Stream integration (Data Hub)

When integrating with Data Hub, use `Exponea.StreamSettings` instead of `ProjectSettings`:

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

| Parameter | Project/Engagement | Stream/Data hub |
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
| `inAppContentBlocksPlaceholders` | Optional | Optional |
| `manualSessionAutoClose` | Optional | Optional |

* `inAppContentBlocksPlaceholders`
  * If set, all [In-app content blocks for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-in-app-content-blocks) will be prefetched right after the SDK is initialized.

* `manualSessionAutoClose`
  * Determines whether the SDK automatically tracks `session_end` for sessions that remain open when `Exponea.shared.trackSessionStart()` is called multiple times in manual session tracking mode.
  * Default value: `true`

## Configure the SDK

### Configure the SDK programmatically

Configuration is split into several objects that are passed into the `Exponea.shared.configure()` function. The first parameter accepts either `ProjectSettings` (for Engagement) or `StreamSettings` (for Data Hub) via the `IntegrationType` protocol:

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
  * `ProjectSettings` — for Project/Engagement integration. Contains `projectToken` (required), `authorization` (required), `baseUrl` (optional), and `projectMapping` (optional).
  * `StreamSettings` — for Stream/Data hub integration. Contains `streamId` (required) and `baseUrl` (optional, defaults to `https://api.exponea.com`). Does not include `authorization` or `projectMapping`; authentication is handled separately via `setSdkAuthToken`.

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

#### Project/Engagement examples

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

#### Stream/Data hub examples

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

For Stream/Data hub integration, use `streamId` instead of `projectToken` and `authorization`:

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


