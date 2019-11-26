## 🔍 Configuration
You can configure the SDK providing a configuration file with configuration variables or using the configuration method available in the SDK.

### Configuration variables

#### projectToken

* Your project token which can be found in the Exponea APP `Project` -> `Overview`

#### authorization

* Two options: `none` and `.token(token)`.
* Some features require specific authorization to be set, if it is not, they will fail gracefully and print an error.
* For more information on how to get authorization tokens, please click [here](https://developers.exponea.com/reference#access-keys).

#### baseUrl

* If you have custom base URL, you can set up this property.
* Default value `https://api.exponea.com`

#### projectMapping

* In case you have more than one project token to track for one event, you should provide which "event types" each project token should be tracked.

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

#### automaticPushNotificationTracking

* Controls if the SDK will handle push notifications automatically.
* Default value `true`

#### appGroup
* **Required** for the SDK to automatically tracks delivered push notifications. You can find more information in [Push Notifications
](./PUSH.md) documentation.

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

### 1. Using a configuration file
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
<dict>
	<key>sessionTimeout</key>
	<integer>20</integer>
	<key>projectToken</key>
	<string>testToken</string>
	<key>projectMapping</key>
	<dict>
		<key>INSTALL</key>
		<array>
			<string>testToken1</string>
		</array>
		<key>TRACK_EVENT</key>
		<array>
			<string>testToken2</string>
			<string>testToken3</string>
		</array>
		<key>PAYMENT</key>
		<array>
			<string>paymentToken</string>
		</array>
	</dict>
	<key>lastSessionStarted</key>
	<integer>0</integer>
	<key>lastSessionEnded</key>
	<integer>0</integer>
	<key>autoSessionTracking</key>
	<false/>
</dict>
</plist>
```

```
Exponea.shared.configure(plistName: "ExponeaConfig.plist")
```

### 2. Configure SDK programmatically
In case you don't want to or cannot use `.plist` configuration, you can setup the sdk with code. Since there is a lot of things to configure, configuration is split into few object that you pass to `Exponea.shared.configure()` function.
``` swift
func configure(
        _ projectSettings: ProjectSettings,
        automaticPushNotificationTracking: AutomaticPushNotificationTracking,
        automaticSessionTracking: AutomaticSessionTracking = .enabled(),
        defaultProperties: [String: JSONConvertible]? = nil,
        flushingSetup: FlushingSetup = FlushingSetup.default
    )
```

#### ProjectSettings *(required)*
Contains your basic project settings: `projectToken`, `authorization`, `baseUrl` and `projectMapping`.
In most use-cases only `projectToken` and `authorization` is required.

#### automaticPushNotificationTracking *(required)*
Either `.disabled` or `.enabled(appGroup, delegate, tokenTrackFrequency)`. Only `appGroup` is required for the SDK to function properly.
Setting up `delegate` is the same as settings `Exponea.shared.pushNotificationsDelegate` and is here only for your convenience.

#### automaticPushNotificationTracking
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
	automaticPushNotificationTracking: .enabled(appGroup: "YOUR APP GROUP")
)
```
Disabling all the automatic features of the SDK:
``` swift
Exponea.shared.configure(
	Exponea.ProjectSettings(
		projectToken: "YOUR PROJECT TOKEN",
		authorization: .token("YOUR ACCESS TOKEN")
	),
	automaticPushNotificationTracking: .disabled,
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
		projectMapping: [.payment: ["OTHER PROJECT ID"]]
	),
	automaticPushNotificationTracking: .enabled(
		appGroup: "YOUR APP GROUP",
		delegate: self,
		tokenTrackFrequency: .onTokenChange
	),
	automaticSessionTracking: .enabled(timeout: 123),
	defaultProperties: ["prop-1": "value-1", "prop-2": 123],
	flushingSetup: Exponea.FlushingSetup(mode: .periodic(100), maxRetries: 5)
)
```
