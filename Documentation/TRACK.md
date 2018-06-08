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

Save or update your customer data in the Exponea APP through this method.

```
public func identifyCustomer(customerId: String?,
                             properties: [String: JSONConvertible],
                             timestamp: Double?)
```

#### 💻 Usage

```
Exponea.shared.identifyCustomer(customerId: "test@test.com",
                                properties: ["custom_property" : "Some Property Value", "first_name" : "test"],
                                timestamp: nil)
```


## 🔍 Track Sessions

Session is a real time spent in the game or int the app, it starts when the application is launched and ends when the game goes to background. If the user returns to game/app in 60 seconds (To change TIMEOUT value, you can set the `sessionTimeout` in the Exponea Configuration), application will continue in current session. Tracking of sessions produces two events,  `session_start` and  `session_end `.

The sessions are by default tracked automatically. If you want to disable you can change it changing the `automaticSessionTracking` in the Exponea Configuration.

There are also two methods available for you to track the sessions manually.


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