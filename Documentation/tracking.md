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

> 📘
>
> Also see [Mobile SDK tracking FAQ](https://support.bloomreach.com/hc/en-us/articles/18153058904733-Mobile-SDK-tracking-FAQ) at Bloomreach Support Help Center.

> ❗️ Protect the privacy of your customers

 > Make sure you have obtained and stored tracking consent from your customer before initializing Exponea iOS SDK.
 > 
 > To ensure you're not tracking events without the customer's consent, you can use `Exponea.shared.clearLocalCustomerData(appGroup: String)` when a customer opts out from tracking (this applies to new users or returning customers who have previously opted out). This will bring the SDK to a state as if it was never initialized. This option also prevents reusing existing cookies for returning customers.
 > 
 > Refer to [Clear local customer data](#clear-local-customer-data) for details.
 > 
 > If customer denied tracking consent after Exponea iOS SDK is initialized, you can use `Exponea.shared.stopIntegration()` to stop SDK integration and remove all locally stored data.
 >
 > Refer to [Stop SDK integration](#stop-sdk-integration) for details.

## Events

### Track event

Use the `trackEvent()` method to track any custom event type relevant to your business.

You can use any name for a custom event type. We recommended using a descriptive and human-readable name.

Refer to the [Custom events](https://documentation.bloomreach.com/engagement/docs/custom-events) documentation for an overview of commonly used custom events.

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
> Optionally, you can provide a custom `timestamp` if the event happened at a different time. By default, the current time will be used.

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

> ❗️
>
> Although it's possible to use `identifyCustomer` with a [soft ID](https://documentation.bloomreach.com/engagement/docs/customer-identification#section-soft-id), developers should use caution when doing this. In some cases (for example, after using `anonymize`), this can unintentionally associate the current user with an incorrect customer profile.

> ❗️
>
> The SDK stores data, including customer hard ID, in a local cache on the device. Removing the hard ID from the local cache requires calling [anonymize](#anonymize) in the app.
> If the customer profile is anonymized or deleted in the Bloomreach Engagement webapp, subsequent initialization of the SDK in the app can cause the customer profile to be reidentified or recreated from the locally cached data.

> Always use a [hard ID](https://documentation.bloomreach.com/engagement/docs/customer-identification#hard-id) to identify a customer. Using a soft ID with `identifyCustomer` could unintentionally cause the customer to be associated with an incorrect profile.

#### Arguments

| Name                        | Type                      | Description |
| --------------------------- | ------------------------- | ----------- |
| customerIds **(required)**  | [String: String]          | Dictionary of customer unique identifiers. Only identifiers defined in the Engagement project are accepted. |
| properties                  | [String: JSONConvertible] | Dictionary of customer properties. |
| timestamp                   | Double                    | Unix timestamp specifying when the customer properties were updated. Specify the `nil` value to use the current time. |

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

The default session timeout is 60 seconds. Set `sessionTimeout` in the [SDK configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) to specify a different timeout.

### Track session manually

To disable automatic session tracking, set `automaticSessionTracking` to `false` in the [SDK configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration).

Use the `trackSessionStart()` and `trackSessionEnd()` methods to track sessions manually.

#### Examples

``` swift
Exponea.shared.trackSessionStart()
```

> 👍
>
> The default behavior for manually calling `Exponea.shared.trackSessionStart()` multiple times can be controlled by the `manualSessionAutoClose` flag in the `Configuration`, which is set to `true` by default. If a previous session is still open (i.e., it hasn’t been manually closed with `Exponea.shared.trackSessionEnd()`) before `Exponea.shared.trackSessionStart()` is called again, the SDK will automatically track a `sessionEnd` for the previous session and then trigger a new `sessionStart` event. To prevent this behavior, set the `manualSessionAutoClose` flag in the `Configuration` to `false`.   


``` swift
Exponea.shared.trackSessionEnd()
``` 

## Push notifications

If developers [integrate push notification functionality](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications#integration) in their app, the SDK automatically tracks the push notification token by default.

In the [SDK configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration), you can disable automatic push notification tracking by setting the Boolean value of the `pushNotificationTracking` property to `false`. It is then up to the developer to manually track push notifications.

> ❗️
>
> The behavior of push notification tracking may be affected by the tracking consent feature, which in enabled mode requires explicit consent for tracking. Refer to the [consent documentation](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) for details.

### Track token manually

Use the `trackPushToken()` method to manually track the token for receiving push notifications. The token is assigned to the currently logged-in customer (with the `identifyCustomer` method).

Invoking this method will track a push token immediately regardless of the value of `tokenTrackFrequency` (refer to the [Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) documentation for details).

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

### Track push notification delivery manually

Use the `trackPushReceived()` method to manually track push notification delivery.

You can pass either the notification data or the user info as argument.

#### Arguments

| Name                   | Type                                   | Description |
| -----------------------| -------------------------------------- | ----------- |
| content **(required)** | [UNNotificationContent](https://developer.apple.com/documentation/usernotifications/unnotificationcontent) | Notification data. |

or:

| Name                    | Type                 | Description |
| ------------------------| ---------------------| ----------- |
| userInfo **(required)** | \[AnyHashable: Any\] | User info object from the notification data. |


#### Example

Passing notification data as argument:

```swift
func trackPushNotifReceived() {
    let notifContent = UNMutableNotificationContent()
    notifContent.title = "Example title"
    // ... and anything you need, but only `userInfo` is required for tracking
    notifContent.userInfo = [
        "url": "https://example.com/ios",
        "title": "iOS Title",
        "action": "app",
        "message": "iOS Message",
        "image": "https://example.com/image.jpg",
        "actions": [
            ["title": "Action 1", "action": "app", "url": "https://example.com/action1/ios"],
            ["title": "Action 2", "action": "browser", "url": "https://example.com/action2/ios"]
        ],
        "sound": "default",
        "aps": [
            "alert": ["title": "iOS Alert Title", "body": "iOS Alert Body"],
            "mutable-content": 1
        ],
        "attributes": [
            "event_type": "campaign",
            "campaign_id": "123456",
            "campaign_name": "iOS Campaign",
            "action_id": 1,
            "action_type": "mobile notification",
            "action_name": "iOS Action",
            "campaign_policy": "policy",
            "consent_category": "General consent",
            "subject": "iOS Subject",
            "language": "en",
            "platform": "ios",
            "sent_timestamp": 1631234567.89,
            "recipient": "ios@example.com"
        ],
        "url_params": ["param1": "value1", "param2": "value2"],
        "source": "xnpe_platform",
        "silent": false,
        "has_tracking_consent": true,
        "consent_category_tracking": "iOS Consent"
    ]
    Exponea.shared.trackPushReceived(content: notifContent)
}
```

Passing user info as argument:

```swift
func trackPushNotifReceived() {
    let userInfo: [AnyHashable: Any] = [
        "url": "https://example.com/ios",
        "title": "iOS Title",
        "action": "app",
        "message": "iOS Message",
        "image": "https://example.com/image.jpg",
        "actions": [
            ["title": "Action 1", "action": "app", "url": "https://example.com/action1/ios"],
            ["title": "Action 2", "action": "browser", "url": "https://example.com/action2/ios"]
        ],
        "sound": "default",
        "aps": [
            "alert": ["title": "iOS Alert Title", "body": "iOS Alert Body"],
            "mutable-content": 1
        ],
        "attributes": [
            "event_type": "campaign",
            "campaign_id": "123456",
            "campaign_name": "iOS Campaign",
            "action_id": 1,
            "action_type": "mobile notification",
            "action_name": "iOS Action",
            "campaign_policy": "policy",
            "consent_category": "General consent",
            "subject": "iOS Subject",
            "language": "en",
            "platform": "ios",
            "sent_timestamp": 1631234567.89,
            "recipient": "ios@example.com"
        ],
        "url_params": ["param1": "value1", "param2": "value2"],
        "source": "xnpe_platform",
        "silent": false,
        "has_tracking_consent": true,
        "consent_category_tracking": "iOS Consent"
    ]
    Exponea.shared.trackPushReceived(userInfo: userInfo)
}
```

### Track push notification click manually

Use the `trackPushOpened()` method to manually track push notification clicks.

#### Arguments

| Name                     | Type                 | Description |
| -------------------------| ---------------------| ----------- |
| userInfo **(required)**  | \[AnyHashable: Any\] | User info object from the notification data. |

#### Example

```swift
func trackPushNotifClick() {
    let userInfo: [AnyHashable: Any] = [
        "url": "https://example.com/ios",
        "title": "iOS Title",
        "action": "app",
        "message": "iOS Message",
        "image": "https://example.com/image.jpg",
        "actions": [
            ["title": "Action 1", "action": "app", "url": "https://example.com/action1/ios"],
            ["title": "Action 2", "action": "browser", "url": "https://example.com/action2/ios"]
        ],
        "sound": "default",
        "aps": [
            "alert": ["title": "iOS Alert Title", "body": "iOS Alert Body"],
            "mutable-content": 1
        ],
        "attributes": [
            "event_type": "campaign",
            "campaign_id": "123456",
            "campaign_name": "iOS Campaign",
            "action_id": 1,
            "action_type": "mobile notification",
            "action_name": "iOS Action",
            "campaign_policy": "policy",
            "consent_category": "General consent",
            "subject": "iOS Subject",
            "language": "en",
            "platform": "ios",
            "sent_timestamp": 1631234567.89,
            "recipient": "ios@example.com"
        ],
        "url_params": ["param1": "value1", "param2": "value2"],
        "source": "xnpe_platform",
        "silent": false,
        "has_tracking_consent": true,
        "consent_category_tracking": "iOS Consent"
    ]
    Exponea.shared.trackPushOpened(with: userInfo)
}
```

## Clear local customer data

Your application should always ask customers for consent to track their app usage. If the customer consents to tracking events at the application level but not at the personal data level, using the `anonymize()` method is usually sufficient.

If the customer doesn't consent to any tracking, it's recommended not to initialize the SDK at all.

If the customer asks to delete personalized data, use the `clearLocalCustomerData(appGroup: String)` method to delete all information stored locally before SDK is initialized.

The customer may also revoke all tracking consent after the SDK is fully initialized and tracking is enabled. In this case, you can stop SDK integration and remove all locally stored data using the [stopIntegration](#stop-sdk-integration) method.

Invoking this method will cause the SDK to:

* Remove the push notification token for the current customer from local device storage.
* Clear local repositories and caches, including all previously tracked events that haven't been flushed yet.
* Clear all session start and end information.
* Remove the customer record stored locally.
* Clear any previously loaded in-app messages, in-app content blocks, and app inbox messages.
* Clear the SDK configuration from the last invoked initialization.
* Stop handling of received push notifications.
* Stop tracking of deep links and universal links (your app's handling of them isn't affected).

## Stop SDK integration

❗️ App group must be same for configuration and NotificationServices ❗️
 - otherwise received push could be tracked

Your application should always ask the customer for consent to track their app usage. If the customer consents to tracking of events at the application level but not at the personal data level, using the `anonymize()` method is normally sufficient.

If the customer doesn't consent to any tracking before the SDK is initialized, it's recommended that the SDK isn't initialized at all. For the case of deleting personalized data before SDK initialization, see more info in the usage of the [clearLocalCustomerData](#clear-local-customer-data) method.

The customer may also revoke all tracking consent later, after the SDK is fully initialized and tracking is enabled. In this case, you can stop SDK integration and remove all locally stored data by using the `Exponea.shared.stopIntegration()` method.

Use the `stopIntegration()` method to delete all information stored locally and stop the SDK if it is already running.

Invoking this method will cause the SDK to:

* Remove the push notification token for the current customer from local device storage.
* Clear local repositories and caches, including all previously tracked events that were not flushed yet.
* Clear all session start and end information.
* Remove the customer record stored locally.
* Clear any In-app messages, In-app content blocks, and App inbox messages previously loaded.
* Clear the SDK configuration from the last invoked initialization.
* Stop handling of received push notifications.
* Stop tracking of Deep links and Universal links (your app's handling of them is not affected).

If the SDK is already running, invoking of this method also:

* Stops and disables session start and session end tracking even if your application tries later on.
* Stops and disables any tracking of events even if your application tries later on.
* Stops and disables any flushing of tracked events even if your application tries later on.
* Stops displaying of In-app messages, In-app content blocks, and App inbox messages.
* Already displayed messages are dismissed.
* Please validate dismiss behaviour if you [customized](https://documentation.bloomreach.com/engagement/docs/ios-sdk-app-inbox#customize-app-inbox) the App Inbox UI layout. 

After invoking the `stopIntegration()` method, the SDK will drop any API method invocation until you [initialize the SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#initialize_the_sdk) again. 


### Use cases

Correct usage of the `stopIntegration()` method depends on the use case, so consider all scenarios.

#### Stop the SDK but upload tracked data

The SDK caches data (such as sessions, events, and customer properties) in an internal local database and periodically sends them to Bloomreach Engagement. These data are kept locally if the device has no network or if you configured SDK to upload them less frequently.

Invoking the `stopIntegration()` method will remove all these locally stored data that may not be uploaded yet. To avoid loss of these data, request to flush them before stopping the SDK:

```swift
// SDK is init with flush
Exponea.shared.configure(...)
Exponea.shared.flushData()
// Stop integration
Exponea.shared.stopIntegration()
```

#### Stop the SDK and wipe all tracked data

The SDK caches data (such as sessions, events, and customer properties) in an internal local database and periodically sends them to the Bloomreach Engagement app. If the device has no network or if you configured the SDK to upload them less frequently, these data are kept locally.

You may face the use case where the customer gets removed from the Bloomreach Engagement platform, and subsequently, you want to remove them from local storage too.

Please do not initialize the SDK in this case. Depending on your configuration, the SDK may upload the stored tracked events. This may lead to the customer's profile being recreated in Bloomreach Engagement. Stored events may have been tracked for this customer, and uploading them will result in the recreation of the customer profile based on the assigned customer IDs.

To prevent this from happening, invoke `stopIntegration()` immediately without initializing the SDK:

```swift
Exponea.shared.stopIntegration()
```

This results in all previously stored data being removed from the device. The next SDK initialization will be considered a fresh new start.

#### Stop the already running SDK

The method `stopIntegration()` can be invoked anytime on a configured and running SDK.

This can be used in case the customer previously consented to tracking but revoked their consent later. You may freely invoke `stopIntegration()` with immediate effect.

```swift
// User gave you permission to track
Exponea.shared.configure(...)

// Later, user decides to stop tracking
Exponea.shared.stopIntegration()
```

This results in the SDK stopping all internal processes (such as session tracking and push notifications handling) and removing all locally stored data.

Please be aware that `stopIntegration()` stops any further tracking and flushing of data. If you need to upload tracked data to Bloomreach Engagement, then [flush them synchronously](#stop-the-sdk-but-upload-tracked-data) before stopping the SDK.

#### Customer denies tracking consent

It is recommended to ask the customer for tracking consent as soon as possible in your application. If the customer denies consent, please do not initialize the SDK at all.

❗️ AppInbox remove after `stopIntegration()` 
Add a callback to your viewController with AppInboxButton

```swift
IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
    self?.appInboxButton.removeFromSuperview()
    self?.view.layoutIfNeeded()
}
```

❗️ Stop receiving push after `stopIntegration()` 
You have to override the method in ExponeaAppDelegate
```swift
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        super.userNotificationCenter(.....)
        
        // your code if needed
    }
}
```

If you can't override this method and call super, make sure you add `if` to your method

```swift
if IntegrationManager.shared.isStopped && Exponea.isExponeaNotification(userInfo: notification.request.content.userInfo) {
    Exponea.logger.log(.error, message: "Will present wont finish, SDK is stopping")
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
    completionHandler([])
}
```


## Payments

The SDK tracks in-app purchases automatically.

### Track payment

Use the `trackPayment()` method to track payments manually.

#### Arguments

| Name                      | Type                      | Description |
| ------------------------- | ------------------------- | ----------- |
| properties                | [String: JSONConvertible] | Dictionary of payment properties. |
| timestamp                 | Double                    | Unix timestamp specifying when the event was tracked. Specify the `nil` value to use the current time. |

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

## Default properties

You can configure default properties to be tracked with every event. Note that the value of a default property will be overwritten if the tracking event has a property with the same key.

Refer to `defaultProperties` in the [Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) documentation for details.

After initializing the SDK, you can change the default properties using the `Exponea.shared.defaultProperties()` method.
