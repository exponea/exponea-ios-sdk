---
title: Push Notifications
excerpt: Enable push notifications in your app using the iOS SDK
slug: ios-sdk-push-notifications
categorySlug: integrations
parentDocSlug: ios-sdk
---

Engagement enables sending push notifications to your app users using [scenarios](https://documentation.bloomreach.com/engagement/docs/scenarios-1). The mobile application handles the push message using the SDK and renders the notification on the customer's device.

Push notifications can also be silent, used only to update the app’s interface or trigger some background task.

> 📘
>
> Refer to [Mobile Push Notifications](https://documentation.bloomreach.com/engagement/docs/mobile-push-notifications#creating-a-new-notification) to learn how to create push notifications in the Engagement web app.

> ❗️ Deprecation of automatic push notifications
>
> Previous versions of the SDK used method swizzling to automatically register for push notifications. This sometimes caused issues and therefore is no longer supported. Refer to [Application Delegate Methods](#implement-application-delegate-methods) below for a list of delegate methods your application needs to implement in order to properly process push notifications.

## Prerequisites

To be able to send push notifications from Engagement, you must:

- Obtain an Apple Push Notification service (APNs) authentication token signing key
- Add and configure the Apple Push Notification Service integration in the Engagement web app

> 📘
>
> Follow the instructions in [Configure Apple Push Notification Service](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configure-apns) if you haven't set this up yet.

## Integration

This section describes the steps to add the minimum push notification functionality (receive alert notifications) to your app.

### Step 1: Enable Push Capabilities

Select your application target in Xcode, and on the `Signing & Capabilities` tab, add the following capabilities:

- `Push Notifications`
   Required for alert push notifications.
- `Background Modes` (select `Remote notifications`)
   Required for silent push notifications.
- `App Groups` (create a new app group for your app)
   Required for application extensions that handle push notification delivery and rich content.

> ❗️
>
> An Apple developer account with a paid membership is required to add the `Push Notifications` capability.


### Step 2: Configure the SDK

[Configure](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) the SDK with `pushNotificationTracking: .enabled(appGroup:)` to enable push notifications. Use the app group you created in the previous step.

``` swift
Exponea.shared.configure(
    Exponea.projectSettings(...),
    pushNotificationTracking: .enabled(appGroup: "YOUR_APP_GROUP")
)
```

> 👍
>
> The SDK provides a push setup self-check feature to help developers successfully set up push notifications. The self-check will try to track the push token, request the Engagement backend to send a silent push to the device, and check if the app is ready to open push notifications.
>
> To enable the setup check, set `Exponea.shared.checkPushSetup = true` **before** [initializing the SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#initialize-the-sdk):

### Step 3: Implement Application Delegate Methods

For your application to be able to respond to push notification-related events, it must have three delegate methods:

- `application:didRegisterForRemoteNotificationsWithDeviceToken:`
   Called when your application registers for push notifications.
- `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` 
   Called when a silent push notification or alert push notification arrives while your app is in the foreground.
- `userNotificationCenter(_:didReceive:withCompletionHandler:)` 
   Called when the user opens an alert push notification.

The [`ExponeaAppDelegate`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/ExponeaSDK/Classes/ExponeaAppDelegate.swift) class in the SDK provides default implementations of these methods. We recommend that you extend `ExponeaAppDelegate` in your `AppDelegate`. 

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
    }
}
```

If, for some reason, you don't want to or are not able to extend `ExponeaAppDelegate`, you can use it as a reference for implementing the three delegate methods yourself.

#### Checklist

Make sure that:

 - [ ] Your `application:didRegisterForRemoteNotificationsWithDeviceToken:` delegate method calls `Exponea.shared.handlePushNotificationToken`.
 - [ ] Your `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` and `userNotificationCenter(_:didReceive:withCompletionHandler:)` methods call `Exponea.shared.handlePushNotificationOpened`
 - [ ] You call `UNUserNotificationCenter.current().delegate = self`
 - [ ] When you start your application, self-check should be able to receive and track the push notification token.

### Step 4: Register for Receiving Push Notifications

Your app needs to register to receive push notifications. It’s important to ensure you have the correct authorization to receive push notifications. You require explicit permission from the user to receive "alert" notifications visible to the user. You don't need authorization to receive [silent push notifications](#silent-push-notifications) (background updates).

You can request authorization and subsequently register for receiving notifications using the following code:

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

By default, the SDK only tracks the push notification token if the app is authorized (unless the [push setup check](#configure-the-sdk) is enabled). Refer to [Silent Push Notifications](#silent-push-notifications) below to learn how to track the push token even when the app is not authorized.

#### Checklist: 
 - [ ] Engagement should now be able to send push notifications to your device. Refer to the [Creating a new notification](https://documentation.bloomreach.com/engagement/docs/mobile-push-notifications#creating-a-new-notification) guide for instructions.

## Customization

This section describes the customizations you can implement once you have integrated the minimum push notification functionality.

### Handle Received Push Notifications

To handle incoming push notifications, you must specify a delegate to be called when the user opens a push notification or when a [silent push notification](#silent-push-notifications) is received.

The delegate must implement `PushNotificationManagerDelegate` and have the `pushNotificationOpened` method. The notification [payload](#payload-example) and the action the user selected are passed as arguments. Optionally, you can also implement the `silentPushNotificationReceived` method to handle [silent push notifications](#silent-push-notifications).

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
> Refer to [`AppDelegate`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/AppDelegate.swift) in the [example app](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app) for a basic example.

### Silent Push Notifications

Silent push notifications don't trigger any visible or audible notifications on the device but wake up the application to allow it to perform tasks in the background.

The app must track the push token to the Engagement backend to receive push notifications. The SDK does this automatically only if push notification tracking is enabled and properly implemented, and the app is [authorized](#register-for-receiving-push-notifications) to receive alert push notifications.

Silent push notifications don't require authorization. To track the push token even when the app is not authorized, set the configuration variable `requirePushAuthorization` to `false`. This causes the SDK to register for push notifications and track the push token at application startup.

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

To respond to silent push notifications, set the `Exponea.shared.pushNotificationsDelegate` and implement the `silentPushNotificationReceived` method. Refer to [Handle Received Push Notifications](#handle-received-push-notifications) above for details.

> 👍
>
> Silent push notifications require `Background Modes` `Remote notifications` capability.

> ❗️
>
> The [Official Apple documentation](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app) states that you should not try to send more than two or three notifications per hour.

### Rich Push Notifications

Rich push notifications can contain images and buttons. To enable this functionality, you must add two application extensions: a **Notification Service Extension** and a **Notification Content Extension**.

For each extension, follow the instructions in [Notification Extensions](https://documentation.bloomreach.com/engagement/docs/ios-sdk-notification-extensions) to set it up correctly to use the Exponea Notification Service included in the SDK.

Using of `ExponeaNotificationContentService.didReceive()` method will enhance notification body with image and actions that are delivered within UNNotification payload. Notification actions shown by `ExponeaNotificationContentService` are registered with configurations to open your application with required information and to handle campaign click automatically.

#### Checklist:
 - [ ] Check that push notifications with images and buttons sent from Engagement are correctly displayed on your device. Push delivery tracking should work.
 - [ ] If you don't see buttons in the expanded push notification, the content extension is **not** running. Double check `UNNotificationExtensionCategory` in `Info.plist` - notice the placement inside `NSExtensionAttributes`. Check that the `iOS Deployment Target` is the same for the extensions and the main app.

### Push notification alert sound

Received push notifications handled by `ExponeaNotificationService.process()` can play a default or customized sound when the notification is displayed.

To use the default sound for a notification, enter `default` as value for `Media > Sound` in your push notification scenario in the Engagement web app.
![Configure sound for a push notification in Engagement](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/push-sound-config.png)

To use a custom sound for a notification, you must create a sound file that [iOS supports](https://developer.apple.com/documentation/usernotifications/unnotificationsound#2943048). Include the sound file in your Xcode project and add it to the app's target.

Once the custom sound is in place in your app, enter the file name of the sound file as value for `Media > Sound` in your push notification scenario in the Engagement web app. Ensure that you enter the exact file name (case sensitive) without extension.

### Track Delivered Notifications

To track the delivery of push notifications, implement a **Notification Service Extension** as [described for rich push notifications above](#notification-service-extension).

Calling `ExponeaNotificationService.process` in `didReceive` will track the notification delivery as a `campaign` event in Engagement.

### Retrieve Push Notification Token Manually

Sometimes, your application may need to retrieve the current push token while running. You can do this using the `Exponea.shared.trackPushToken` method.

A common use case is when the `Exponea.shared.anonymize()` method is called. Invoking `anonymize` removes the push notification token from local storage. Hence, it needs to be updated right after `anonymize`, or before or after `identifyCustomer`, depending on your push notifications usage.

``` swift
class YourClass {
    func signOutAndSignIn() {
        Exponea.shared.anonymize()
        // anonymize removed Push token, so another identifyCustomer will not be assigned to push notifications
        Exponea.shared.identifyCustomer(...)
        Messaging.messaging().token { token, error in
          if let token = token {
            Exponea.shared.trackPushToken(token)
          }
        }
    }
}
```

### Show Foreground Notifications

By default, if an iOS app gets a notification while the app is in the foreground, the notification banner won't be displayed.

In iOS 10 and later, you can show foreground notifications by implementing a `UNUserNotificationCenterDelegate` and telling iOS to display the banner.

1. Create a class that implements `UNUserNotificationCenterDelegate`.
2. Override `userNotificationCenter(center:willPresentNotification:withCompletionHandler)` and return at least the alert type to its completion handler
3. Set it as the default `UNUserNotificationCenter`'s delegate.

> 📘
>
> For an example see https://sarunw.com/posts/notification-in-foreground/.

## Advanced Use Cases

### Multiple Push Notification Sources

The SDK only handles push notifications sent from the Engagement platform. If you use platforms other than Engagement to send push notifications, you must implement some of the notification handling logic yourself. 

#### Conditional processing
[Implement Application Delegate Methods](#implement-application-delegate-methods) above describes the delegate methods required for Engagement push notification handling to work. You can use the `Exponea.isExponeaNotification(userInfo:)` method in the delegate implementations to check if an incoming notification is coming from Engagement and, if not, process the notification using an implementation for a different notification source.

#### Manual tracking
You can completely disable notification tracking and use the methods `Exponea.shared.trackPushToken` and `Exponea.shared.trackPushOpened` to track push notification events manually. `trackPushOpened` expects the [Engagement payload format](#payload-example). You can always track a `campaign` event manually for any payload format.

> ❗️
>
> The behavior of `trackPushReceived` and `trackClickedPush` may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in the [tracking consent](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) documentation.

### Custom Notification Actions in iOS 11 and Lower

To support the action buttons on iOS 11 and lower that can be configured in the Engagement web app, you must implement custom notification categories that are used to hook up the button actions and titles. The SDK provides a convenient factory method to simplify the creation of such a category.

> ❗️
>
> The category identifier you specify here must be identical to the one you specify in the Engagement backend.

```swift
// Set legacy exponea categories
let category1 = UNNotificationCategory(
    identifier: "EXAMPLE_LEGACY_CATEGORY_1",
    actions: [
        ExponeaNotificationAction.createNotificationAction(
            type: .openApp, 
            title: "Hardcoded open app", 
            index: 0
        ),
        ExponeaNotificationAction.createNotificationAction(
            type: .deeplink, 
            title: "Hardcoded deeplink", 
            index: 1
        )
    ], 
    intentIdentifiers: [], 
    options: []
)
    
UNUserNotificationCenter.current().setNotificationCategories([category1])
```

## Payload Example

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

## Debug with the iOS Simulator

Xcode 12+ supports remote push notifications with the simulator. The behavior is the same as with an actual device. You'll get the token for APNs (or FCM for Firebase) from the app delegate's methods. 

```swift
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) // Native
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) // Firebase
```

