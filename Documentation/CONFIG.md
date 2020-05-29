## 🔍 Configuration
You can configure the SDK providing a configuration file with configuration variables or using the configuration method available in the SDK.

### Configuration variables

#### projectToken

* Your project token which can be found in the Exponea APP `Project` -> `Overview`

#### authorization

* Options are `.none` or `.token(token)`.
* Token is an Exponea **public** key. [Configuration guide](./Guide/CONFIGURATION.md) shows where to find it in the Exponea web app.
* For more information, please see [Exponea API documentation](https://docs.exponea.com/reference#access-keys)

#### baseUrl

* If you have custom base URL, you can set up this property.
* Default value `https://api.exponea.com`

#### projectMapping

* In case you need to track events into more than one project, you can define project information for "event types" which should be tracked multiple times.

#### defaultProperties

* A list of properties to be added to all tracking events
* Default value `nil`

#### automaticSessionTracking

* Flag to control the automatic tracking of `session_start` and `session_end` events.
* Default value `true`

#### sessionTimeout

* Session is the real time spent in the App, it starts when the App is launched and ends when the App goes to background.
* This value will be used to calculate the session timing.
* Default value `6.0` seconds
* The minimum value is `5.0` seconds
* The **recommended** maximum value is `120.0` seconds, but the **absolute** max is `180.0` seconds. More than this, iOS will kill it
* Read more in `Track Events` -> `Track Sessions`

#### automaticPushNotificationTracking - DEPRECATED

* Controls if the SDK will handle push notifications automatically using method swizzling. We decided to deprecate this feature since it uses method swizzling that causes issues when the host application uses multiple SDKs that do the same.

* It is replaced by `pushNotificationTracking`. With `pushNotificationTracking` you're more in control of what's happening inside your app and it also makes debugging easier. When migrating from `automaticPushNotificationTracking` some extra work is required. Please check [Push notifications](./PUSH.md) documentation for more details.
* Default value `true`

#### pushNotificationTracking

* Controls if the SDK will handle push notifications. Registers application to receive push notifications based on `requirePushAuthorization` setting.
* Default value `true`

#### appGroup
* **Required** for the SDK to automatically tracks delivered push notifications. You can find more information in [Push Notifications
](./PUSH.md) documentation.

#### requirePushAuthorization
* SDK can check push notification authorization status([Apple documentation](https://developer.apple.com/documentation/usernotifications/unnotificationsettings/1648391-authorizationstatus)) and only track the push token when the user is authorized to receive push notifications. 
* When disabled, SDK will automatically register for push notifications on app start and track the token to Exponea so your app can receive silent push notifications. 
* When enabled, SDK will automatically register for push notifications if the app is authorized to show push notifications to the user.
* Default value `true`

#### tokenTrackFrequency
	
* Indicates the frequency which the APNS token should be tracked to Exponea
* Default value is `onTokenChange`
* Possible values:
	* `onTokenChange`
	* `everyLaunch`
	* `daily`

#### flushEventMaxRetries

* Controls how many times an event should be flushed before aborting. Useful for example if the API is down or some other temporary error happens.
* Default value is `5`.


## Configuring the SDK

### 1. Configure SDK programmatically
Since there is a lot of things to configure, configuration is split into few objects that you pass to `Exponea.shared.configure()` function.
``` swift
func configure(
        _ projectSettings: ProjectSettings,
        pushNotificationTracking: PushNotificationTracking,
        automaticSessionTracking: AutomaticSessionTracking = .enabled(),
        defaultProperties: [String: JSONConvertible]? = nil,
        flushingSetup: FlushingSetup = FlushingSetup.default
    )
```

#### ProjectSettings *(required)*
Contains your basic project settings: `projectToken`, `authorization`, `baseUrl` and `projectMapping`.
In most use-cases only `projectToken` and `authorization` is required.

#### PushNotificationTracking *(required)*
Either `.disabled` or `.enabled(appGroup, delegate, requirePushAuthorization, tokenTrackFrequency)`. Only `appGroup` is required for the SDK to function properly.
Setting up `delegate` is the same as settings `Exponea.shared.pushNotificationsDelegate` and is here only for your convenience.

#### automaticSessionTracking
Either `.disabled` or `.enabled(timeout)`. We suggest you use default sessionTimeout and use `.enabled()`, which is also the default value.

#### defaultProperties
As described in configuration variables.

#### flushingSetup
Allows you to setup `flushingMode` and `maxRetries`. By default event flush happens as soon as you track an event(`.immediate`). You can change this behaviour to one of `.manual`, `.automatic`, `periodic(period)`.

#### 💻 Usage
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
		baseUrl: "https://YOUR URL",
		projectMapping: [
			.payment: [
				ExponeaProject(
					baseUrl: "https://YOUR URL",
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
	flushingSetup: Exponea.FlushingSetup(mode: .periodic(100), maxRetries: 5)
)
```


### 2. Using a configuration file - LEGACY
> Configuring the SDK programmatically is preferred. SDK still supports configuring the SDK using a plist file for backwards compatibility.

Create a configuration `.plist` file containing configuration variables. You need to specify all the required ones. For the rest, default values will be used.
``` swift
public func configure(plistName: String)
```

#### 💻 Usage

*ExponeaConfig.plist*

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

```
Exponea.shared.configure(plistName: "ExponeaConfig.plist")
```