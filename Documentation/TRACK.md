## 🔍 Track Events

You can define any event types for each of your project based on your business model or your current goals. If you have product e-commerce website, your basic customer journey will probably/most likely be:

* Visiting your App
* Searching for specific product
* Product page
* Adding product to the cart
* Going through ordering process
* Payment

So the possible events for tracking will be: ‘search’, ‘product view’, ‘add product to cart’, ‘checkout’, ‘purchase’. Remember that you can define any event names you wish. Our recommendation is to make them self-descriptive and human understandable.

## 🔍 Track Event

> **NOTE:** Requires Token authorization.

In the SDK you can track an event using the following accessor:

```
public func trackEvent(properties: [String: JSONConvertible], 
                       timestamp: Double?, 
                       eventType: String?)
)
```

#### 💻 Usage

```
// Preparing the data.
let properties = ["my_property_1" : "my property 1 value",
                  "info" : "test from exponea SDK sample app",
                  "some_number" : 5]

// Call trackEvent to send the event to Exponea API.
Exponea.shared.trackEvent(properties: properties, 
                          timestamp: nil, 
                          eventType: "my_custom_event_type")
```
        
## 🔍 Identify Customer

> **NOTE:** Requires Token authorization.

Save or update your customer data in the Exponea App through this method.

```
public func identifyCustomer(customerIds: [String : JSONConvertible]?,
                             properties: [String: JSONConvertible],
                             timestamp: Double?)
```

#### 💻 Usage

```
Exponea.shared.identifyCustomer(customerIds: ["registered" : "test@test.com"],
                                properties: ["custom_property" : "Some Property Value", "first_name" : "test"],
                                timestamp: nil)
```


## 🔍 Track Sessions

> **NOTE:** Requires Token authorization.

Session is a real time spent in the app, it starts when the application is launched and ends when the app goes to background. If the user returns to the app within 60 seconds (you can set the `sessionTimeout` in the Exponea Configuration), application will continue in current session. Tracking of sessions produces two events, `session_start` and `session_end`.

Sessions are tracked automatically by default. To disable it, you can change the `automaticSessionTracking` in the Exponea Configuration.

There are two methods available to track sessions manually.

## 🔍 Default Properties

  It's possible to set values in the [`ExponeaConfiguration`](../Documentation/CONFIG.md) to be sent in every tracking event. Notice that those values will be overwritten if the tracking event has properties with the same key name.
  
💻 Usage

```
Exponea.shared.configure(projectToken: "ProjectTokenA",
                         authorization: Authorization.token("12345abcdef"),
                         baseURL: "YOUR BASE URL",
                         defaultProperties: ["MyKey": "Value"])

```


### Track Session Start

```
trackSessionStart()
```

#### 💻 Usage

```
Exponea.shared.trackSessionStart()
```

### Track Session End

```
trackSessionEnd()
```

#### 💻 Usage

```
Exponea.shared.trackSessionEnd()
```

### Track Payment

```
trackPayment(properties: [String: JSONConvertible], timestamp: Double?)
```

#### 💻 Usage

```
Exponea.shared.trackPayment(properties: ["value": "99", "custom_info": "sample payment"], timestamp: nil)
```
