## 🔍 Configuration

The configuration object must be configured before starting using the SDK.

It's possible to initialize the configuration providing a configuration file with the same structure (keys) from the Configuration structure or just using the configuration methods available in the SDK.

```swift
public struct Configuration: Decodable {
    public internal(set) var projectMapping: [EventType: [String]]?
    public internal(set) var projectToken: String?
    public internal(set) var authorization: Authorization = .none
    public internal(set) var baseURL: String = Constants.Repository.baseURL
    public internal(set) var contentType: String = Constants.Repository.contentType
    public var sessionTimeout: Double = Constants.Session.defaultTimeout
    public var automaticSessionTracking: Bool = true
    public var automaticPushNotificationTracking: Bool = true
}
```


#### projectMapping

* In case you have more than one project token to track for one event, you should provide which "event types" each project token should be track.

#### projectToken

* Is your project token which can be found in the Exponea APP ```Project``` -> ```Overview```

#### authorization

* Basic authentication supported by a combination of public/private token. 
* For more information, please click [here](https://developers.exponea.com/v2/reference#basic-authentication)

#### baseURL

* If you have you custom base URL, you can set up this property.
* Default value `https://api.exponea.com`

#### contentType

* Content type value to make http requests. 
* Default value `application/json`

#### sessionTimeout

* Session is a real time spent in the App, it starts when the App is launched and ends when the App goes to background. 
* This value will be used to calculate the session timing.
* Default value `6.0`

#### automaticSessionTracking
 
* Flag to control the automatic tracking for In-App purchases done at the Google Play Store. 
* When active, the SDK will add the Billing service listeners in order to get payments done in the App.
* Default value `true`

#### automaticPushNotificationTracking

* Controls if the SDK will handle push notifications automatically.
* Default value `true`


### In order to configure your project, you can use one of the following methods:

#### Setting the configuration with project token, authorization and your base URL:

```swift
public func configure(projectToken: String, 
                      authorization: Authorization, 
                      baseURL: String? = nil)
```

#### 💻 Usage

```swift
Exponea.shared.configure(projectToken: "ProjectTokenA",
                         authorization: Authorization.basic("YOUR AUTHORIZATION HASH"),
                         baseURL: "YOUR BASE URL")
```

#### Setting the configuration using configuration file:

```swift
public func configure(plistName: String)
```

#### 💻 Usage

```swift
Exponea.shared.configure(plistName: "ExponeaConfig.plist")
```

#### Setting the configuration using a projectMapping (token mapping) for each type of event. This allows you to track events to multiple projects, even the same event to more project at once.

```swift
public func configure(projectToken: String,
                      projectMapping: [EventType: [String]],
                      authorization: Authorization,
                      baseURL: String? = nil)
```

#### 💻 Usage

```swift
Exponea.shared.configure(projectToken: "ProjectTokenA",
                         projectMapping: [EventType.identifyCustomer: ["ProjectTokenA", "ProjectTokenB"],
                                          EventType.customEvent: ["ProjectTokenD"]],
                         authorization: Authorization.basic("YOUR AUTHORIZATION HASH"),
                         baseURL: "YOUR BASE URL")
```
