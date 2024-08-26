---
title: Configuration
excerpt: Full configuration reference for the iOS SDK
slug: ios-sdk-configuration
categorySlug: integrations
parentDocSlug: ios-sdk-setup
---

This page provides an overview of all configuration parameters for the SDK and several examples of how to initialize the SDK with different configurations.

## Configuration parameters

* `projectToken` **(required)**
   * Your project token. You can find this in the Engagement web app under `Project settings` > `Access management` > `API`.

* `authorization` **(required)**
   * Options are `.none` or `.token(token)`.
   * The token must be an Engagement **public** key. See [Mobile SDKs API Access Management](https://documentation.bloomreach.com/engagement/docs/mobile-sdks-api-access-management) for details.
   * For more information, please refer to the [Bloomreach Engagement API documentation](https://documentation.bloomreach.com/engagement/reference/authentication).

* `baseUrl`
  * Your API base URL which can be found in the Engagement web app under `Project settings` > `Access management` > `API`.
  * Default value `https://api.exponea.com`.
  * If you have custom base URL, you must set this property.

* `projectMapping`
  * If you need to track events into more than one project, you can define project information for "event types" which should be tracked multiple times.

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
  * Default value: `6.0` seconds.
  * The minimum value is `5.0` seconds.
  * The **recommended** maximum value is `120.0` seconds, but the **absolute** max is `180.0` seconds. Higher will cause iOS to kill the session.
  * Read more about [Tracking Sessions](tracking#session)

* `automaticPushNotificationTracking` - DEPRECATED
  * Controls if the SDK will handle push notifications automatically using method swizzling. This feature has been deprecated since its use of method swizzling can cause issues in case the host application uses multiple SDKs that do the same.
  * Replaced by `pushNotificationTracking`. With `pushNotificationTracking` you have more control over what's happening inside your app in addition to making debugging easier. When migrating from `automaticPushNotificationTracking`, some extra work is required. Refer to the [Push notifications](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications) documentation for more details.
  * Default value: `true`

* `pushNotificationTracking`
  * Controls if the SDK will handle push notifications. Registers application to receive push notifications based on `requirePushAuthorization` setting.
  * Default value: `true`

* `appGroup`
  * **Required** for the SDK to track delivered push notifications automatically. Refer to the [Push Notifications](https://documentation.bloomreach.com/engagement/docs/io-sdk-push-notifications) documentation for details.

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
  * Refer the [authorization documentation](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization) for details.
  * Default value: `false`

* `inAppContentBlocksPlaceholders`
  * If set, all [In-app content blocks](https://documentation.bloomreach.com/engagement/docs/ios-sdk-in-app-content-blocks) will be prefetched right after the SDK is initialized.

* `manualSessionAutoClose`
  * Determines whether the SDK automatically tracks `session_end` for sessions that remain open when `Exponea.shared.trackSessionStart()` is called multiple times in manual session tracking mode.
  * Default value: `true`

## Configure the SDK

### Configure the SDK Programmatically
Configuration is split into several objects that are passed into the `Exponea.shared.configure()` function.
``` swift
func configure(
        _ projectSettings: ProjectSettings,
        pushNotificationTracking: PushNotificationTracking,
        automaticSessionTracking: AutomaticSessionTracking = .enabled(),
        defaultProperties: [String: JSONConvertible]? = nil,
        flushingSetup: FlushingSetup = FlushingSetup.default
    )
```

* `ProjectSettings` **(required)**
  * Contains the basic project settings: `projectToken`, `authorization`, `baseUrl`, and `projectMapping`.
  * In most use cases, only `projectToken`` and `authorization` are required.

* `pushNotificationTracking` **(required)**
  * Either `.disabled` or `.enabled(appGroup, delegate, requirePushAuthorization, tokenTrackFrequency)`. Only `appGroup` is required for the SDK to function correctly.
  * Setting `delegate` has the same effect as setting `Exponea.shared.pushNotificationsDelegate`.

* `automaticSessionTracking`
  * Either `.disabled` or `.enabled(timeout)`.
  * Default value: `enabled()` (recommended, uses default session timeout)

* `defaultProperties`
  * As described above in [Configuration Parameters](#configuration-parameters).

* `flushingSetup`
  * Allows you to set up `flushingMode` and `maxRetries`. By default, event flush happens as soon as you track an event(`.immediate`). You can change this behavior to one of `.manual`, `.automatic`, `periodic(period)`.
  * See [Data Flushing](https://documentation.bloomreach.com/engagement/docs/ios-sdk-data-flushing) for details.

#### Examples
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
Complex use-case:
``` swift
Exponea.shared.configure(
	Exponea.ProjectSettings(
		projectToken: "YOUR PROJECT TOKEN",
		authorization: .token("YOUR ACCESS TOKEN")
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
	advancedAuthEnabled: true
)
```


### Using a Configuration File - LEGACY
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


*ExampleConfig.plist*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<plist version="1.0">
<dict>
	<key>projectToken</key>
	<string>testToken</string>
	<key>sessionTimeout</key>
	<integer>20</integer>
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


