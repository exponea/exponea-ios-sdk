## 🔍 Tracking
Exponea SDK allows you to track events that occur while using the app and add properties of your customer. 
Please, read [Apple User Privacy and Data Use](https://docs.exponea.com/docs/apple-user-privacy-and-data-use) and [iOS 14.5 privacy policy and Exponea iOS SDK](https://docs.exponea.com/docs/ios-145-privacy-policy-and-exponea-ios-sdk) before using tracking capability. 

When SDK is first initialized we generate a cookie for the customer that will be used for all the tracking. You can retrieve that cookie using `Exponea.shared.customerCookie`.

> If you need to reset the tracking and start fresh with a new user, you can use [Anonymize](./ANONYMIZE.md) functionality.

## 🔍 Track Events

> Some events are tracked automatically. We track installation event once for every customer and when `automaticSessionTracking` is enabled in [Configuration](./CONFIG.md) we automatically track session events.

You can define any event types for each of your project based on your business model or your current goals. If you have product e-commerce website, your basic customer journey will probably/most likely be:

* Visiting your App
* Searching for specific product
* Product page
* Adding product to the cart
* Going through ordering process
* Payment

So the possible events for tracking will be: ‘search’, ‘product view’, ‘add product to cart’, ‘checkout’, ‘purchase’. Remember that you can define any event names you wish. Our recommendation is to make them self-descriptive and human understandable.

## 🔍 Track Event

In the SDK you can track an event using the following accessor:

``` swift
public func trackEvent(
  properties: [String: JSONConvertible],
  timestamp: Double?,
  eventType: String?
)
```

#### 💻 Usage

``` swift
// Preparing the data.
let properties = [
  "my_property_1" : "my property 1 value",
  "info" : "test from exponea SDK sample app",
  "some_number" : 5
]

// Call trackEvent to send the event to Exponea API.
Exponea.shared.trackEvent(
  properties: properties,
  timestamp: nil,
  eventType: "my_custom_event_type"
)
```
        
## 🔍 Identify Customer

Save or update your customer data in the Exponea App through this method.

``` swift
public func identifyCustomer(
  customerIds: [String : JSONConvertible]?,
  properties: [String: JSONConvertible],
  timestamp: Double?
)
```

#### 💻 Usage

``` swift
Exponea.shared.identifyCustomer(
  customerIds: ["registered" : "test@test.com"],
  properties: ["custom_property" : "Some Property Value", "first_name" : "test"],
  timestamp: nil
)
```


## 🔍 Track Sessions

Session is a real time spent in the app, it starts when the application is launched and ends when the app goes to background. If the user returns to the app within 60 seconds (you can set the `sessionTimeout` in the Exponea Configuration), application will continue in current session. Tracking of sessions produces two events, `session_start` and `session_end`.

Sessions are tracked automatically by default. To disable it, you can change the `automaticSessionTracking` in the Exponea Configuration.

There are two methods available to track sessions manually.

## 🔍 Default Properties

  It's possible to set values in the [ExponeaConfiguration](../Documentation/CONFIG.md) to be sent in every tracking event. Notice that those values will be overwritten if the tracking event has properties with the same key name.

  > Once Exponea is configured, you can also change default properties setting `Exponea.shared.defaultProperties`.

## 🔍 Tracking special events

### Track Session Start

``` swift
trackSessionStart()
```

#### 💻 Usage

``` swift
Exponea.shared.trackSessionStart()
```

### Track Session End

``` swift
trackSessionEnd()
```

#### 💻 Usage

``` swift
Exponea.shared.trackSessionEnd()
```

### Track Payment

``` swift
trackPayment(properties: [String: JSONConvertible], timestamp: Double?)
```

#### 💻 Usage

``` swift
Exponea.shared.trackPayment(
  properties: ["value": "99", "custom_info": "sample payment"],
  timestamp: nil
)
```
