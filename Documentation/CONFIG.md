## 🔍 Configuration

The configuration object must be configured before starting using the SDK.

It's possible to initialize the configuration providing a configuration file with the same structure (keys) from the Configuration structure or just using the configuration methods available in the SDK.

```
public struct Configuration: Decodable {
    public internal(set) var projectMapping: [EventType: [String]]?
    public internal(set) var projectToken: String?
    public internal(set) var authorization: Authorization = .none
    public internal(set) var baseURL: String = Constants.Repository.baseUrl
    public internal(set) var contentType: String = Constants.Repository.contentType
    public internal(set) var defaultProperties: [String: JSONConvertible]?
    public var sessionTimeout: Double = Constants.Session.defaultTimeout
    public var automaticSessionTracking: Bool = true
    public var automaticPushNotificationTracking: Bool = true
    public var tokenTrackFrequency: TokenTrackFrequency = .onTokenChange
    public var flushEventMaxRetries: Int = Constants.Session.maxRetries
}
```


#### projectMapping

* In case you have more than one project token to track for one event, you should provide which "event types" each project token should be track.

#### projectToken

* Is your project token which can be found in the Exponea APP ```Project``` -> ```Overview```

#### authorization

* Two options: `none` and `.token(token)`.
* Some features require specific authorization to be set, if it is not, they will fail gracefully and print an error.
* For more information on how to get authorization tokens, please click [here](https://developers.exponea.com/reference#access-keys).

#### baseUrl

* If you have you custom base URL, you can set up this property.
* Default value `https://api.exponea.com`

#### contentType

* Content type value to make http requests.
* Default value `application/json`

#### defaultProperties

* A list of properties to be added to all tracking events
* Default value `nil`

#### sessionTimeout

* Session is the real time spent in the App, it starts when the App is launched and ends when the App goes to background.
* This value will be used to calculate the session timing.
* Default value `6.0` seconds
* The mininum value is `5.0` seconds
* The **recommended** maximum value is `120.0` seconds, but the **absolute** max is `180.0` seconds. More than this, iOS will kill it
* Read more in `Track Events` -> `Track Sessions`

#### automaticSessionTracking

* Flag to control the automatic tracking for In-App purchases done at the Google Play Store.
* When active, the SDK will add the Billing service listeners in order to get payments done in the App.
* Default value `true`

#### automaticPushNotificationTracking

* Controls if the SDK will handle push notifications automatically.
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

### 1. With project token and authorization

```
public func configure(projectToken: String,
                      authorization: Authorization,
                      baseURL: String? = nil) // optional custom base url
```

#### 💻 Usage

```
Exponea.shared.configure(projectToken: "ProjectTokenA",
                         authorization: Authorization.token("12345abcdef"))
```

### 2. Using a configuration file

```
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

### 3. Using project token mapping

```
public func configure(projectToken: String,
                      projectMapping: [EventType: [String]],
                      authorization: Authorization,
                      baseURL: String? = nil)
```

#### 💻 Usage

```
Exponea.shared.configure(projectToken: "ProjectTokenA",
                         projectMapping: [EventType.identifyCustomer: ["ProjectTokenA", "ProjectTokenB"],
                                          EventType.customEvent: ["ProjectTokenD"]],
                         authorization: Authorization.token("12345abcdef"),
                         baseURL: "YOUR BASE URL")
```
