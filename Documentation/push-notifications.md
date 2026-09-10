---
title: Push notifications for iOS SDK
slug: ios-sdk-push-notifications
category:
  uri: /branches/2/categories/guides/Developers
parent:
  uri: ios-sdk
content:
  excerpt: Enable push notifications in your app using the iOS SDK
---

{user.mkg} enables sending push notifications to your app users using [scenarios](https://documentation.bloomreach.com/engagement/docs/scenarios-1). The mobile application handles the push message using the SDK and renders the notification on the customer's device.

Push notifications can also be silent, used only to update the app’s interface or trigger some background task.

> 📘
>
> To learn how to create push notifications in the {user.mkg} web app, refer to [Mobile push notifications](https://documentation.bloomreach.com/engagement/docs/mobile-push-notifications#creating-a-new-notification).

> 📘
>
> Also see [Mobile push notifications FAQ](https://support.bloomreach.com/hc/en-us/articles/18152713374877-Mobile-Push-Notifications-FAQ) at {user.br} Support Help Center.

> ❗️ Deprecation of automatic push notifications
>
> Previous versions of the SDK used method swizzling to register for push notifications automatically. This sometimes caused issues and, therefore, is no longer supported. Refer to [Implement application delegate methods](#implement-application-delegate-methods) below for a list of delegate methods your application needs to implement to process push notifications properly.

## Prerequisites

To be able to send push notifications from {user.mkg}, you must:

- Obtain an Apple Push Notification service (APNs) authentication token signing key
- Add and configure the Apple Push Notification Service integration in the {user.mkg} web app

> 📘
>
> If you haven't set this up yet, Follow the instructions in [Configure Apple Push Notification Service for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configure-apns).

## Integration

This section describes the steps to add the minimum push notification functionality (receive alert notifications) to your app.

### Step 1: Enable push capabilities

Select your application target in Xcode, and on the `Signing & Capabilities` tab, add the following capabilities:

- `Push Notifications`
   Required for alert push notifications.
- `Background Modes` (select `Remote notifications`)
   Required for silent push notifications.
- `App Groups` (create a new app group for your app)
   Required for application extensions that handle push notification delivery and rich content.

> ❗️
>
> An Apple developer account with a paid membership must add the `Push Notifications` capability.


### Step 2: Configure the SDK

[Configure](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) the SDK with `pushNotificationTracking: .enabled(appGroup:)` to enable push notifications. Use the app group you created in the previous step.

**Project/{user.mkg} mode:**

``` swift
Exponea.shared.configure(
    Exponea.ProjectSettings(
        projectToken: "YOUR_PROJECT_TOKEN",
        authorization: .token("YOUR_API_KEY")
    ),
    pushNotificationTracking: .enabled(appGroup: "YOUR_APP_GROUP")
)
```

**Stream/{user.dh} mode:**

``` swift
Exponea.shared.configure(
    Exponea.StreamSettings(
        streamId: "YOUR_STREAM_ID",
        baseUrl: "https://api.exponea.com"
    ),
    pushNotificationTracking: .enabled(appGroup: "YOUR_APP_GROUP")
)
// Provide JWT after configuration:
Exponea.shared.setJwtErrorHandler { context in
    yourBackend.fetchNewJwt { newToken in
        Exponea.shared.setSdkAuthToken(newToken)
    }
}
Exponea.shared.setSdkAuthToken("YOUR_STREAM_JWT_TOKEN")
```

> Push token tracking (`notification_state` events) and the push self-check work the same way regardless of integration type.

> 👍
>
> The SDK provides a push setup self-check feature to help developers successfully set up push notifications. The self-check will try to track the push token, request the {user.mkg} backend to send a silent push to the device, and check if the app is ready to open push notifications.
>
> To enable the setup check, set `Exponea.shared.checkPushSetup = true` **before** [initializing the SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#initialize-the-sdk):

### Step 3: Implement application delegate methods

For your application to be able to respond to push notification-related events, it must have three delegate methods:

- `application:didRegisterForRemoteNotificationsWithDeviceToken:`
   Called when your application registers for push notifications.
- `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` 
   Called when a silent push notification or alert push notification arrives while your app is in the foreground.
- `userNotificationCenter(_:didReceive:withCompletionHandler:)` 
   Called when the user opens an alert push notification.

The [`ExponeaAppDelegate`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/ExponeaSDK/Classes/ExponeaAppDelegate.swift) class in the SDK provides default implementations of these methods. We recommend that you extend `ExponeaAppDelegate` in your `AppDelegate`. 

For applications using the UIKit lifecycle, ensure that your AppDelegate class subclasses ExponeaAppDelegate:

```swift
@UIApplicationMain
class AppDelegate: ExponeaAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // don't forget to call the super method!!
        super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        Exponea.shared.checkPushSetup = true
        Exponea.shared.configure(...)
        return true
    }
}
```

For applications using the SwiftUI lifecycle, register an UIApplicationDelegateAdaptor referencing an AppDelegate that subclasses ExponeaAppDelegate.

```swift
// YourApp.swift
@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(YourAppDelegate.self) var appDelegate
    init() {
        // ... your app init here
        // you may init SDK here or in AppDelegate implementation
    }
}

// YourAppDelegate.swift
class YourAppDelegate: ExponeaAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // don't forget to call the super method!!
        super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        Exponea.shared.checkPushSetup = true
        Exponea.shared.configure(...)
        return true
    }
}
```

If you don't want to or are unable to extend `ExponeaAppDelegate`, you can use it as a reference for implementing the three delegate methods yourself.

#### Checklist

Make sure that:

 - [ ] Your `application:didRegisterForRemoteNotificationsWithDeviceToken:` delegate method calls `Exponea.shared.handlePushNotificationToken`.
 - [ ] Your `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` and `userNotificationCenter(_:didReceive:withCompletionHandler:)` methods call `Exponea.shared.handlePushNotificationOpened`
 - [ ] You call `UNUserNotificationCenter.current().delegate = self`
 - [ ] When you start your application, self-check should be able to receive and track the push notification token.

> 👍 **Pre-init APNs token buffering**
>
> If `application:didRegisterForRemoteNotificationsWithDeviceToken:` fires before `Exponea.shared.configure(...)` completes — a common timing issue during cold launch — the SDK buffers the token to local storage and replays it through the normal tracking path once configuration is initialized. The buffer persists to disk, so the first APNs token is never lost even if the app crashes between the APNs callback and SDK initialization.
>
> No action is required from the host app — the behavior is automatic. The SDK's token-registration path and [`tokenTrackFrequency`](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) rules handle duplicate replays, so no duplicate `notification_state` events are tracked regardless of which frequency mode is active.

### Step 4: Register to receive push notifications

Your app needs to register to receive push notifications. It’s important to ensure you have the correct authorization to receive push notifications. You require explicit permission from the user to receive "alert" notifications visible to the user. You don't need authorization to receive [silent push notifications](#silent-push-notifications) (background updates).

You can request authorization and subsequently register to receive notifications using the following code:

``` swift 
UNUserNotificationCenter.current()
    .requestAuthorization(options: [.badge, .alert, .sound]) { (granted, _) in
        if granted {
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
```

If the user hasn't granted permission yet, this code will trigger an alert asking the user to allow push notifications. If the user previously granted permission, the `granted` property will be `true`, and the code will directly execute the closure and register the app for receiving notifications.

By default, the SDK only tracks the push notification token if the app is authorized (unless the [push setup check](#configure-the-sdk) is enabled). Refer to [Silent Push Notifications](#silent-push-notifications) below to learn how to track the push token even when the app isn't authorized.

> ❗️Important
>
> SDK versions 3.8.0 and higher use event-based token tracking to support multiple mobile applications per project. Learn more about [Token tracking via notification_state event](#token-tracking-via-notification_state-event).

#### Checklist: 
 - [ ] {user.mkg} should now be able to send push notifications to your device. For instructions, refer to the [Creating a new notification](https://documentation.bloomreach.com/engagement/docs/mobile-push-notifications#creating-a-new-notification) guide.

## Customization

This section describes the customizations you can implement once you have integrated the minimum push notification functionality.

### Handle received push notifications

To handle incoming push notifications, you must specify a delegate to be called when the user opens a push notification or when a [silent push notification](#silent-push-notifications) is received.

The delegate must implement `PushNotificationManagerDelegate` and have the `pushNotificationOpened` method. The notification [payload](#payload-example) and the user's selected action are passed as arguments. Optionally, you can also implement the `silentPushNotificationReceived` method to handle [silent push notifications](#silent-push-notifications).

You can set the delegate by setting `Exponea.shared.pushNotificationsDelegate` directly or by specifying the `delegate` parameter on `pushNotificationTracking: .enabled`.


```swift
import ExponeaSDK
import UserNotifications

@UIApplicationMain
class AppDelegate: ExponeaAppDelegate {

    var window: UIWindow?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        super.application(application, didFinishLaunchingWithOptions: launchOptions)

        Exponea.shared.configure(
            Exponea.ProjectSettings(
                // ...
            ),
            pushNotificationTracking: .enabled(
                appGroup: "YOUR APP GROUP",
                delegate: self,
                requirePushAuthorization: false
            )
        )

    }
}

extension AppDelegate: PushNotificationManagerDelegate {
    func pushNotificationOpened(
        with action: ExponeaNotificationAction, 
        value: String?, 
        extraData: [AnyHashable : Any]?
    ) {
        // app open, browser, deeplink or none(default)
        print("push action: \(action)")
        // deeplink url, nil for open app action
        print("value for action: \(value)") 
        // data payload you specified in Exponea web app
        print("extra payload specified: \(extraData)")
    }

    // this function is optional
    func silentPushNotificationReceived(extraData: [AnyHashable: Any]?) {
        // data payload you specified in Exponea web app
        print("extra payload specified: \(extraData)")
    }
}
```

> 📘
>
> Refer to [`AppDelegate`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/AppDelegate.swift) in the [Example app for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app) for a basic example.

> ❗️Important
>
> SDK versions 3.8.0 and higher use event-based token tracking to support multiple mobile applications per project. Learn more about [Token tracking via notification_state event](#token-tracking-via-notification_state-event).

### Silent push notifications

Silent push notifications don't trigger any visible or audible notifications on the device but wake up the application to allow it to perform tasks in the background.

To receive push notifications, the app must track the push token to the {user.mkg} backend. The SDK does this automatically only if push notification tracking is enabled and properly implemented and the app is [authorized](#register-for-receiving-push-notifications) to receive alert push notifications.

Silent push notifications don't require authorization. To track the push token even when the app isn't authorized, set the configuration variable `requirePushAuthorization` to `false`. This causes the SDK to register for push notifications and track the push token at application startup.

> 📘
>
> The token is still tracked, but the `valid` field on the resulting `notification_state` event reflects the OS authorization status directly — if the user has not granted (or has revoked) push permission, the event carries `valid=false` / `description="Permission denied"` regardless of `requirePushAuthorization`. See the [`valid` / `description` truth table](#understanding-token-states) for all combinations.

``` swift
    Exponea.shared.configure(
        Exponea.ProjectSettings(
            projectToken: "YOUR-PROJECT-TOKEN",
            authorization: .token("YOUR-AUTHORIZATION-TOKEN"),
            baseUrl: "YOUR-BASE-URL"
        ),
        pushNotificationTracking: .enabled(
            appGroup: "YOUR-APP-GROUP",
            requirePushAuthorization: false
        )
    )
```

To respond to silent push notifications, set the `Exponea.shared.pushNotificationsDelegate` and implement the `silentPushNotificationReceived` method. Refer to [Handle received push notifications](#handle-received-push-notifications) above for details.

> 👍
>
> Silent push notifications require `Background Modes` and `Remote notifications` capabilities.

> ❗️
>
> The [Official Apple documentation](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app) states that you should not try to send more than two or three notifications per hour.

> ❗️Important
>
> SDK versions 3.8.0 and higher use event-based token tracking to support multiple mobile applications per project. Learn more about [Token tracking via notification_state event](#token-tracking-via-notification_state-event).

### Rich push notifications

Rich push notifications can contain images, buttons, and audio. To enable this functionality, you must add two application extensions: a **Notification Service Extension** and a **Notification Content Extension**.

For each extension, follow the instructions in [Notification extensions for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-notification-extensions) to set it up correctly to use the Exponea Notification Service included in the SDK.

Using the `ExponeaNotificationContentService.didReceive()` method will enhance the notification body with an image and actions delivered within the UNNotification payload. The notification actions shown by `ExponeaNotificationContentService` are registered with configurations to open your application with the required information and handle campaign clicks automatically.

#### Checklist:
 - [ ] Check that push notifications with images and buttons sent from {user.mkg} are correctly displayed on your device. Push delivery tracking should work.
 - [ ] If you don't see buttons in the expanded push notification, the content extension isn't running. Check `UNNotificationExtensionCategory` in `Info.plist`, and confirm it's nested inside `NSExtensionAttributes`. Also check that the iOS deployment target is iOS 15.0 or higher and matches the main app's target.

### Push notification alert sound

> 👍
>
> You must implement [rich push notifications](#rich-push-notifications) in your app to enable push notification alert sounds.

Received push notifications handled by `ExponeaNotificationService.process()` can play a default or customized sound when the notification is displayed.

To use the default sound for a notification, enter `default` as the value for `Media > Sound` in your push notification scenario in the {user.mkg} web app.
![Configure sound for a push notification](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/push-sound-config.png)

To use a custom sound for a notification, you must create a sound file that [iOS supports](https://developer.apple.com/documentation/usernotifications/unnotificationsound#2943048). Include the sound file in your Xcode project and add it to the app's target.

Once the custom sound is in place in your app, enter the sound file's file name as the value for `Media > Sound` in your push notification scenario in the {user.mkg} web app. Ensure that you enter the exact file name (case sensitive) without an extension.

### Track delivered notifications

To track the delivery of push notifications, implement a **Notification Service Extension** as [described for rich push notifications above](#rich-push-notifications).

Calling `ExponeaNotificationService.process` in `didReceive` will track the notification delivery as a `campaign` event in {user.mkg}.

> 📘 **Delivered event `state` semantics**
>
> The `campaign` event includes a `state` property that indicates whether the notification was visible to the user. The value is determined at delivery time by the Notification Service Extension.

| Value | Meaning |
|-------|---------|
| `shown` | The notification was displayed to the user. |
| `not_shown` | The notification was delivered silently — either a silent-push payload or the user has revoked notification permission. |


> ⚠️ **Upgrading from an earlier SDK version**
>
> After upgrading, `state == "shown"` filters in your scenarios or analytics may return fewer results. Silent and permission-denied deliveries now correctly report `state = "not_shown"`. Review any `state == "shown"` filters and either accept the more accurate behavior or broaden the filter (for example, `state IN ("shown", "not_shown")`) if you need the previous behavior.

### Retrieve push notification token manually

Sometimes, your application may need to retrieve the current push token while running. You can do this using the `Exponea.shared.trackPushToken` method. Refer to [Tracking for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking#track-token-manually) for details.

> ❗️
>
> Note that tracking the push notification token manually isn't necessary after calling the `Exponea.shared.anonymize()` method. In this case, the push notification token is automatically transferred to the new anonymous customer profile and the app will continue to receive push notifications.
>
> When subsequently calling `Exponea.shared.identifyCustomer`, always use a [hard ID](https://documentation.bloomreach.com/engagement/docs/customer-identification#hard-id).  Using a soft ID could unintentionally cause the push notification token to be associated with an incorrect customer profile.

### Show foreground notifications

By default, if an iOS app receives a notification while the app is in the foreground, the notification banner is not displayed.

In iOS 15 and later, show foreground notifications by implementing `UNUserNotificationCenterDelegate` and telling iOS to display the banner.

1. Create a class that implements `UNUserNotificationCenterDelegate`.
2. Override `userNotificationCenter(center:willPresentNotification:withCompletionHandler)` and return at least the alert type to its completion handler
3. Set it as the default `UNUserNotificationCenter`'s delegate.

> 📘
>
> For an example see https://sarunw.com/posts/notification-in-foreground/.

## Token tracking via notification_state event

 Starting with SDK version 3.8.0, push notification tokens are tracked using `notification_state` events instead of customer
profile properties. This change enables support for multiple mobile applications per project,
allowing you to track multiple push tokens for the same customer across different apps and devices.

### Token storage by SDK version

#### SDK versions below 3.8.0:

* Tokens are stored in customer profile properties: `apple_push_notification_id`
* One token per customer profile
* Single application per project

#### SDK versions 3.8.0 and higher:

* Tokens are stored as `notification_state` events
* Multiple tokens per customer (grouped by Application ID)
* Multiple applications per project supported
* Backward compatibility maintained for Application ID `default-application`

### When notification_state events are tracked

The SDK automatically tracks `notification_state` events in the following scenarios:

* SDK initialization
* App transitions from background to foreground — the SDK re-evaluates whether tracking is needed; under `everyLaunch` this doesn't emit again unless an override applies
* New token received from APNs
* Manual token tracking using `Exponea.trackPushToken(...)` (this method allows you to force tracking/sending the current push token via notification_state event)
* User anonymization via `Exponea.anonymize()`
* OS push authorization status flips (granted ↔ denied) since the last tracked `notification_state` — this happens regardless of the configured `tokenTrackFrequency`, so the `valid` flag always reflects the current OS permission.
* SDK version changes (app update)
* `application_id` changes in the SDK configuration
* 30 days have passed since the last successful `notification_state` track — this ensures `onTokenChange` users stay within the validity window when their APNs token hasn't changed. `daily` and `everyLaunch` modes track frequently enough that this doesn't apply in practice.

You can inspect the current authorization state at any time using `UNAuthorizationStatusProvider.current.isAuthorized(...)`; this call only reads the OS-reported status and does not by itself track a `notification_state` event.

```swift
UNAuthorizationStatusProvider.current.isAuthorized { granted ->
    print("Push notifications are allowed: \(granted)")
}
```

The frequency of `notification_state` event tracking depends on the `tokenTrackFrequency` configuration property. [See SDK configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration).

> 📘 Note
>
> When `tokenTrackFrequency` is set to `everyLaunch`, the SDK tracks the push token once per app launch (process start). All other SDK operations during that launch reuse this tracking, so each launch produces a single `notification_state` event.
>
> Some operations bypass this limit and always trigger tracking mid-process:
> - OS push authorization status flips (granted ↔ denied) since the last tracked `notification_state`.
> - Manual tracking through `trackPushToken()`.
> - Receiving a new token from APNs when the token string changes.
> - Calling `anonymize()` or `stopIntegration()` (these recreate the push-tracking session, so the next track is a fresh per-process launch rather than a mid-process override).
>
>  The SDK detects app version or `application_id` changes at startup. The version or ID affect only the `onTokenChange`/`daily` staleness checks, and aren't a mid-process override for `everyLaunch`. A new process always tracks once regardless of any version or application ID changes.

### notification_state event properties

| Property                | Description                              | Example values                          |
|-------------------------|------------------------------------------|-----------------------------------------|
| `push_notification_token` | Current push notification token          | Token string                            |
| `platform` | Mobile platform. Lowercase counterpart of `os_name` — kept on the wire for cross-platform parity and reserved for future multi-OS support. | `ios` |
| `valid`                   | Token validity status                    | `true` or `false`                           |
| `description`             | Token state description                  | `Permission granted`, `Permission denied`, or `Invalidated` |
| `application_id`          | Application identifier from SDK configuration | Custom ID or `default-application` (default) |
| `device_id`               | Unique device identifier                 | UUID string                             |
| `sdk`                     | SDK identifier (constant string tracked by the iOS SDK) | `Exponea iOS SDK`                       |
| `sdk_version`             | Version of the {user.br} iOS SDK        | `4.1.0`                                 |
| `os_name`                 | Operating-system name                    | `iOS`                                   |
| `os_version`              | Operating-system version                 | `17.4`                                  |
| `device_model`            | Device model name resolved from the hardware identifier. Devices released after the SDK version in use report the raw hardware identifier (for example, `iPhone20,1`) instead of the model name, retaining device-specific signal until the SDK is updated. | `iPhone 15 Pro`, `iPad Air (5th generation)` |
| `device_type`             | Device form factor                       | `mobile` or `tablet`                    |
| `app_version`             | Host app version from `CFBundleShortVersionString` | `1.0`, `2.3.1`                |

> 📘 Note
>
> If you don't specify an `application_id` in your SDK configuration, the default value `default-application` is used. [See SDK configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration).
### Understanding token states

The combination of `valid` and `description` properties indicates the token's current state:

| Valid | Description         | When this occurs                                                        |
|-------|---------------------|------------------------------------------------------------------------|
| `false` | `Invalidated`         | New token received \(old token becomes invalid\) or `Exponea.anonymize()` called |
| `false` | `Permission denied`   | The OS push authorization status is neither `authorized` nor `provisional` (for example, the user denied the permission prompt, or hasn't been prompted yet). The `valid` flag reflects the OS authorization state directly and no longer depends on [`requirePushAuthorization`](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration). |
| `true`  | `Permission granted`  | The OS push authorization status is either `authorized` or `provisional` and a token is available \(all other cases\) |

### Configuring Application ID

Each mobile app integrated with the SDK requires an `application_id` that matches the Application ID configured in {user.mkg}. 

For configuration instructions, see [Configure Application ID](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#configure-application-id).

> 📘 Note
>
> The push setup self-check (`Exponea.shared.checkPushSetup = true`) also carries the configured `application_id` in its request to the {user.br} backend. In multi-mobile-app projects, this lets the backend route the test silent push to the correct app/bundle even when several apps in the same {user.br} workspace are running self-check concurrently. If `application_id` is left unset, the default `default-application` value is used.

#### Event creation requirements

The SDK automatically generates `notification_state` events. Before upgrading to SDK 3.8.0 or higher, ensure your {user.mkg} project meets these requirements:

- Event creation is enabled for your project
- If your project uses custom event schemas or restricts event creation, add `notification_state` to the list of allowed events

> ❗️ Important
>
> If your project blocks creation of new event types, push token registration will fail silently. No tokens will appear in customer profiles or the event stream after SDK initialization, and push notifications will not be delivered.
### Verifying token tracking

You can verify that tokens are being tracked correctly in the {user.mkg} web application:

1. Navigate to Data & Assets > Customers
2. Locate the customer profile
3. Check for `notification_state` events in the customer's event history
4. Verify the `push_notification_token` property contains a valid token value 

For SDK versions below 3.8.0, check the customer profile properties `apple_push_notification_id` instead.

## Advanced use cases

### Multiple push notification sources

The SDK only handles push notifications sent from the {user.mkg} platform. If you use platforms other than {user.mkg} to send push notifications, you must implement some of the notification handling logic yourself. 

#### Conditional processing

[Implement application delegate methods](#implement-application-delegate-methods) above describes the delegate methods required for {user.mkg} push notification handling to work. You can use the `Exponea.isExponeaNotification(userInfo:)` method in the delegate implementations to check if an incoming notification is coming from {user.mkg} and, if not, process the notification using an implementation for a different notification source.

#### Manual tracking
You can completely disable notification tracking and use the methods `Exponea.shared.trackPushToken` and `Exponea.shared.trackPushOpened` to track push notification events manually. `trackPushOpened` expects the {user.mkg} [payload format](#payload-example). You can always track a `campaign` event manually for any payload format.

> ❗️
>
> The behavior of `trackPushReceived` and `trackClickedPush` may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in the [Tracking consent for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) documentation.

## Payload example

```json
{
    "url": "https://example.com/ios",
    "title": "iOS Title",
    "action": "app",
    "message": "iOS Message",
    "image": "https://example.com/image.jpg",
    "actions": [
        {"title": "Action 1", "action": "app", "url": "https://example.com/action1/ios"},
        {"title": "Action 2", "action": "browser", "url": "https://example.com/action2/ios"},
    ],
    "sound": "default",
    "aps": {
        "alert": {"title": "iOS Alert Title", "body": "iOS Alert Body"},
        "mutable-content": 1,
    },
    "attributes": {
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
        "recipient": "ios@example.com",
    },
    "url_params": {"param1": "value1", "param2": "value2"},
    "source": "xnpe_platform",
    "silent": false,
    "has_tracking_consent": true,
    "consent_category_tracking": "iOS Consent",
}
```

## Debug with the iOS simulator

Xcode 12+ supports remote push notifications with the simulator. The behavior is the same as with an actual device. You'll get the token for APNs (or FCM for Firebase) from the app delegate's methods. 

```swift
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) // Native
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) // Firebase
```

