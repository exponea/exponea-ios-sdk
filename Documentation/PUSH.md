## 📣  Push Notifications
Exponea allows you to easily create complex scenarios which you can use to send push notifications directly to your customers. The following section explains how to enable push notifications.

## Quick start

For push notifications to work, you'll need to setup a few things:
- create an Apple Push Notification service(APNs) key
- integrate push notifications into your application 
- set the APNs key in the Exponea web app

We've created a [Quick start guide](./Guide/PUSH_QUICKSTART.md) that will guide you through these steps.

## Deprecating Automatic push notifications
Previous versions of the SDK used method swizzling to automatically register for push notifications. In our experience swizzling causes more problems than it solves, so we chose to move away from it. [Quick start guide](./Guide/PUSH_QUICKSTART.md) contains list of delegates your application needs to implement in order to properly process push notifications.

## Handling push notification opening
Exponea SDK allows you to set a delegate that will be called when push notification is opened, or when silent push notification is received. Delegate will be called with information about action that was selected on the push notification and payload setup in the Exponea web app.
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

## Tracking delivered notifications
Notification service extension is required for tracking push notification delivery. This extension is part of Rich notifications setup described in [Quick start guide](./Guide/PUSH_QUICKSTART.md).

Calling of ExponeaNotificationService.process is allowed before SDK initialization in case that previous initialization process was done. In such a case, ExponeaNotificationService.process will track events with configuration of last initialization. Please consider to do SDK initialization in application(_:didFinishLaunchingWithOptions:) in case of update of your application to apply a fresh new configuration.

## Silent push notifications
Exponea SDK supports both regular "alert" push notifications and silent push notifications(Background Updates). To receive a notification, you need to track your push token to Exponea backend. When push notification tracking is enabled and properly implemented, this will happen automatically. By default, the token is only tracked when the app is authorized to receive *alert* push notifications. You can change this by setting configuration variable `requirePushAuthorization = false`. With this setting, the SDK will register for push notifications and track the push token at application start. Push notification authorization status is tracked as customer property `apple_push_notification_authorized`.

``` swift
    Exponea.shared.configure(
        Exponea.ProjectSettings(
            projectToken: "YOUR-PROJECT-TOKEN",
            authorization: .token("YOUR-AUTHORIZATION-TOKEN"),
            baseUrl: "YOUR-BASE-URL"
        ),
        pushNotificationTracking: .enabled(
            appGroup: "YOUR-APP-GROUP",
            requirePushAuthorized: false
        )
    )
```

To respond to silent push notification, set the `Exponea.shared.pushNotificationsDelegate`. Details are described in `Handling push notification opening` section of this guide.

> Silent push notifications require `Background Modes` `Remote notifications` capability.

> Official Apple documentation states that you should not try to send more than two or three notifications per hour. https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app

## Multiple push notification sources
The SDK only handles push notifications coming from Exponea backend. If you use other servers than Exponea to send push notifications, you'll need to implement some of the logic yourself. 

### Conditional processing
[Quick start guide](./Guide/PUSH_QUICKSTART.md) describes delegates/extensions required for Exponea push notification handling to work. You can use method `Exponea.isExponeaNotification(userInfo:)` in the delegate/extension implementations to check if the notification being processed is coming from Exponea servers and either call Exponea method or process the notification using implementation for other push notification source.

### Manual tracking
You can completely disable notification tracking and use methods `Exponea.shared.trackPushToken` and `Exponea.shared.trackPushOpened` to track push notification events. `trackPushOpened` expects the notification has Exponea format. You can always track `campaign` event manually with any payload you need.

> The behaviour of `trackClickedPush` may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in [tracking consent documentation](./TRACKING_CONSENT.md).

## Custom Notification Actions in iOS 11 and lower
To support the action buttons that can be configured in the Exponea backend on iOS 11 and lower you will need to implement custom notification categories that are used to properly hook up the button actions and titles. ExponeaSDK provides a convenient factory method to simplify creation of such category. 

> **⚠️ Bear in mind that the category identifier you specify here must be identical to the one you specify in Exponea backend.**

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

### Push notification token after anonymization

There is principal usage of `Exponea.shared.anonymize()` as a sign-out feature in some applications. Keep in mind that invoking of `anonymize` will remove also a Push notification token from storage. To load a current token, your application should retrieve a valid token manually before using any Push notification feature. So it may be called right after `anonymize` or before/after `identifyCustomer`, it depends on your Push notifications usage.

> Guide how to retrieve a valid Push notification token is written for [PUSH_QUICKSTART](Guide/PUSH_QUICKSTART.md).

## JSON structure

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

### Show notification if app is in foreground

```swift
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {}
```

This method is called by system if app is in foreground state. Default implementation is to not showing of push notification and userNotificationCenter::didReceive is called automatically what tracks clicked event.

## Work with iOS simulator

Xcode 12+ supports remote push notifications with simulator. Behavior is same as with real device. You'll get the token for APNS, FCM for Firebase etc. from app delegate's methods. 

```swift
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) // Native
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) // Firebase
```
