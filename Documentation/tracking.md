---
title: Tracking
excerpt: Track customers and events using the iOS SDK
slug: ios-sdk-tracking
categorySlug: integrations
parentDocSlug: ios-sdk
---

You can track events in Engagement to learn more about your app’s usage patterns and to segment your customers by their interactions.

By default, the SDK tracks certain events automatically, including:

* Installation (after app installation and after invoking [anonymize](#anonymize))
* User session start and end
* Banner event for showing an in-app message or content block

Additionally, you can track any custom event relevant to your business.

## Events

### Track Event

Use the `trackEvent()` method to track any custom event type relevant to your business.

You can use any name for a custom event type. We recommended using a descriptive and human-readable name.

Refer to the [Custom Events](https://documentation.bloomreach.com/engagement/docs/custom-events) documentation for an overview of commonly used custom events.

#### Arguments

| Name                      | Type                      | Description |
| ------------------------- | ------------------------- | ----------- |
| properties                | [String: JSONConvertible] | Dictionary of event properties. |
| timestamp                 | Double                    | Unix timestamp specifying when the event was tracked. Specify `nil` value to use the current time. |
| eventType **(required)**  | String                    | Name of the event type, for example `screen_view`. |

#### Examples

Imagine you want to track which screens a customer views. You can create a custom event `screen_view` for this.

First, create a dictionary with properties you want to track with this event. In our example, you want to track the name of the screen, so you include a property `screen_name` along with any other relevant properties:

```swift
let properties: [String: JSONConvertible] = [
    "screen_name": "dashboard", 
    "other_property": 123.45
]
```

Pass the dictionary to `trackEvent()` along with the `eventType` (`screen_view`) as follows:

```swift
Exponea.shared.trackEvent(properties: properties, 
    timestamp: nil, 
    eventType: "screen_view")
```

The second example below shows how you can use a nested JSON structure for complex properties if needed:

```swift
let properties: [String: JSONConvertible] = [
    "purchase_status": "success",
    "product_list": [
        ["product_id": "abc123", "quantity": 2],
        ["product_id": "abc456", "quantity": 1]
    ],
    "total_price": 7.99,
]
Exponea.shared.trackEvent(properties: properties,
        timestamp: nil,
        eventType: "purchase")
```

> 👍
>
> Optionally, you can provide a custom `timestamp` if the event happened at a different time. By default the current time will be used.

## Customers

[Identifying your customers](https://documentation.bloomreach.com/engagement/docs/customer-identification) allows you to track them across devices and platforms, improving the quality of your customer data.

Without identification, events are tracked for an anonymous customer, only identified by a cookie. Once the customer is identified by a hard ID, these events will be transferred to a newly identified customer.

> 👍
>
> Keep in mind that, while an app user and a customer record can be related by a soft or hard ID, they are separate entities, each with their own lifecycle. Take a moment to consider how their lifecycles relate and when to use [identify](#identify) and [anonymize](#anonymize).

### Identify

Use the `identifyCustomer()` method to identify a customer using their unique [hard ID](https://documentation.bloomreach.com/engagement/docs/customer-identification#hard-id).

The default hard ID is `registered` and its value is typically the customer's email address. However, your Engagement project may define a different hard ID.

Optionally, you can track additional customer properties such as first and last names, age, etc.

#### Arguments

| Name                        | Type                      | Description |
| --------------------------- | ------------------------- | ----------- |
| customerIds **(required)**  | [String: String]          | Dictionary of customer unique identifiers. Only identifiers defined in the Engagement project are accepted. |
| properties                  | [String: JSONConvertible] | Dictionary of customer properties. |
| timestamp                   | Double                    | Unix timestamp specifying when the customer properties were updated. Specify `nil` value to use the current time. |

#### Examples

First, create a dictionary containing at least the customer's hard ID:

```swift
let customerIds: [String: JSONConvertible] = [
    "registered": "jane.doe@example.com"
]
```

Optionally, create a dictionary with additional customer properties:

```swift
let properties: [String: JSONConvertible] = [
    "first_name": "Jane",
    "last_name": "Doe",
    "age": 32 
]
```

Pass the `customerIds` and `properties` dictionaries to `identifyCustomer()`:

```swift
Exponea.identifyCustomer(customerIds: customerIds,
    properties: properties,
    timestamp: nil)
```

If you only want to update the customer ID without any additional properties, you can pass an empty dictionary literal for `properties`:

```swift
Exponea.identifyCustomer(customerIds: customerIds,
    properties: [:],
    timestamp: nil)
```

> 👍
>
> Optionally, you can provide a custom `timestamp` if the identification happened at a different time. By default the current time will be used.

### Anonymize

Use the `anonymize()` method to delete all information stored locally and reset the current SDK state. A typical use case for this is when the user signs out of the app.

Invoking this method will cause the SDK to:

* Remove the push notification token for the current customer from local device storage and the customer profile in Engagement.
* Clear local repositories and caches, excluding tracked events.
* Track a new session start if `automaticSessionTracking` is enabled.
* Create a new customer record in Engagement (a new `cookie` soft ID is generated).
* Assign the previous push notification token to the new customer record.
* Preload in-app messages, in-app content blocks, and app inbox for the new customer.
* Track a new `installation` event for the new customer.

You can also use the `anonymize` method to switch to a different Engagement project. The SDK will then track events to a new customer record in the new project, similar to the first app session after installation on a new device.

#### Examples

```swift
Exponea.shared.anonymize()
```

Switch to a different project:

```swift
Exponea.shared.anonymize(
    exponeaProject: ExponeaProject(
        baseUrl: "https://api.exponea.com",
        projectToken: "YOUR PROJECT TOKEN",
        authorization: .token("YOUR API KEY"),
    ),
    projectMapping: nil
)
```

## Sessions

The SDK tracks sessions automatically by default, producing two events: `session_start` and `session_end`.

The session represents the actual time spent in the app. It starts when the application is launched and ends when it goes into the background. If the user returns to the app before the session times out, the application will continue the current session.

The default session timeout is 6.0 seconds. Set `sessionTimeout` in the [SDK configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) to specify a different timeout.

### Track Session Manually

To disable automatic session tracking, set `automaticSessionTracking` to `false` in the [SDK configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration).

Use the `trackSessionStart()` and `trackSessionEnd()` methods to track sessions manually.

#### Examples

``` swift
Exponea.shared.trackSessionStart()
```

``` swift
Exponea.shared.trackSessionEnd()
```

## Push Notifications

If developers [integrate push notification functionality](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications#integration) in their app, the SDK automatically tracks the push notification token by default.

### Track Token Manually

Use the `trackPushToken()` method to manually track the token for receiving push notifications. The token is assigned to the currently logged-in customer (with the `identifyCustomer` method).

Invoking this method will track a push token immediately regardless of the value of 'tokenTrackFrequency' (refer to the [Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) documentation for details).

Each time the app becomes active, the SDK calls `verifyPushStatusAndTrackPushToken` and tracks the token.

#### Arguments

| Name                 | Type    | Description |
| ---------------------| ------- | ----------- |
| token **(required)** | String  | String containing the push notification token. |

#### Example 

```swift
Exponea.shared.trackPushToken("value-of-push-token")
```

> ❗️
>
> Remember to invoke [anonymize](#anonymize) whenever the user signs out to ensure the push notification token is removed from the user's customer profile. Failing to do this may cause multiple customer profiles share the same token, resulting in duplicate push notifications.

## Payments

The SDK tracks in-app purchases automatically.

### Track Payment

Use the `trackPayment()` method to track payments manually.

#### Arguments

| Name                      | Type                      | Description |
| ------------------------- | ------------------------- | ----------- |
| properties                | [String: JSONConvertible] | Dictionary of payment properties. |
| timestamp                 | Double                    | Unix timestamp specifying when the event was tracked. Specify `nil` value to use the current time. |

#### Example

``` swift
Exponea.shared.trackPayment(
  properties: [
      "productId": "123", 
      "currency": "USD", 
      "price": 123.45, 
      "quantity": 2
  ]
  timestamp: nil
)
```

## Default Properties

You can configure default properties to be tracked with every event. Note that the value of a default property will be overwritten if the tracking event has a property with the same key.

Refer to `defaultProperties` in the [Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) documentation for details.

After initializing the SDK, you can change the default properties using the `Exponea.shared.defaultProperties()` method.
