## 📣  Push Notifications

Exponea SDK allows you to easily create complex scenarios which you can use to send push notifications directly to your customers. The following section explains how to enable receiving and tracking push notifications.

* [Setup](#🛠-Setup)
* [Automatic Push Tracking](#🔍-Automatic-Push-Tracking)
* [Manual Push Tracking](#Manual-Push-Tracking)
* [Rich Push Notifications](#Rich-Push-Notifications)


## 🛠 Setup

For push notifications to work, you need a push notifications token with a corresponding key identifier and team identifier. The following steps show you how to create on in the [Apple Developer Center](https://developer.apple.com):

1. Login to your Apple Developer Account and navigate to *Certificates, Identifiers & Profiles*
2. Navigate to a new section *APNs Auth Key* under the *Certificates* tab in the left pane
3. Click the add button in the upper right corner
4. Under *Production* select *Apple Push Notification Authentication Key (Sandbox & Production)* and click continue and a key will be created for you
5. **Download the .p8 key file** and note the **Key ID**
6. While you're in the member center, grab your **Team ID** as well in the membership area
7. The last step is to set up APNs in the Exponea web application, so login to your app and navigate to *Project management -> Project Settings -> Push Notifications*
8. Input the following information:
	-  Open the downloaded .p8 file in TextEdit and copy it's contents into the *ES256 Private Key*
	-  Fill in the *Team ID* as copied from the Member Center
	-  Fill in the *Key ID* provided during key creation (or in .p8 filename)
	-  Fill in the *Application Bundle ID* of your application
	-  Choose if you wish to use production or development API
9. Click *Save* and your project should be connected with Exponea properly 

Now you are ready to implement Push Notifications into your iOS application. You can do that by opening your project in Xcode and then go to your Targets, under your app’s name, select Capabilities and find Push Notifications in the list, switch to *ON*. 

Refer to Apple documentation on how to implement push notification setup in your application and make sure you are also submitting the client token to Exponea either using automatic or manual tracking as described below.

If you had done everything right, you should now be able to send notifications from Exponea to your application. 

Next step is to configure [automatic push notification tracking](#Automatic-Push-Tracking) or [manual push notification tracking](#Manual-Push-Tracking) if you wish to get information about push notifications being delivered or clicked.

## 🔍 Automatic Push Tracking

In the Exponea SDK configuration, you can enable or disable the automatic push notification tracking setting the Boolean value to the `automaticPushNotificationTracking` property and setting up the desired frequency to the `tokenTrackFrequency`.

If the `automaticPushNotificationTracking` is enabled, then the SDK will add track the "campaign" event with the correct properties.

### Tracking delivered notifications

If you wish to automatically track delivered notifications, additional setup is needed. These are the minimuim required steps:

1. Implement a notification service extension
2. Setup app groups to be able to share information between app and extension
3. Finish SDK integration and keep automatic push tracking enabled

#### 1. Implement a notification service extension

Please, see setup for [rich push notifications](#Rich-Push-Notifications), it is the same setup you need to do for the service extension. If you wish to also support custom rich push features like dynamic buttons, images and more then follow the rich push notifications guide further and then come back to delivered push tracking setup.

#### 2. Setting up App Groups

You can read more about how to setup App Groups in the official Apple documentation [here](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html) under the heading **Sharing Data with Your Containing App**.

In practice this means enabling App Groups in your Xcode project settings Capabilites tab and then inputing the app group identifier as per the screenshot below. 

> ⚠️ Keep in mind that **you need to do this for both the containing app and the extension**.

![](./Guide/pics/appgroup.png)

After you have setup the app groups, the last step is to finish SDK integration.

#### 3. Finishing up SDK integration

Finally, you need to make two modifications to make automatic delivered push notification tracking work, one in the app and one in the extension code.

1. Make sure that the configuration you used to setup Exponea SDK contains the same `appGroup` as you setup in previous step. Either add the key to your `.plist` or if you configured the SDK programmatically, check your `automaticPushNotificationTracking`, it should be `.enabled(appGroup: "YOUR APP GROUP" ...)`
2. In the extension, modify the code where you create the `ExponeaNotificationService` to look like the following:

   ```
   let exponeaService = ExponeaNotificationService(appGroup: "group.com.Exponea.ExponeaSDK-Example")
   ```

> Make sure the app group identifier match with what you set up in your project settings.

## Manual Push Tracking

In case you decide to deactivate the automatic push notification, you can still track this event manually.

#### Track Push Token

It's is important to implement this method and correctly track the push token if you are not using automatic push tracking. Without sending the client token to Exponea you will not be able to receive push notifications.

```
// Tracks the push notification token to Exponea API with struct.
public func trackPushToken(_ token: Data)

/// Tracks the push notification token to Exponea API with string.
public func trackPushToken(_ token: String)
```

#### 💻 Usage

```
Exponea.shared.trackPushToken("my_push_token")
```

#### Track Push Notification Delivered

Used to track if a push notificaton was delivered to the device and tracks it to Exponea. It is up to you to handle when and what should be tracked to Exponea to mark the notification as delivered.

A typicial implementation would require a custom `NotificationServiceExtension` and an Application Group (to enable data sharing between app and extension). The extension code would then check the notification payload when it is received and validate it is a notification sent from Exponea or simply a notification that should be tracked. A timestamp and additional data would then be saved in the app group (for example using `UserDefaults` with the shared suite name) and when the app launches it would look for such entries and track them to Exponea with the correct timestamp using the method below.

The Exponea SDK is currently not extension-safe and as such tracking the delivered state at the moment it occurs is not possible.

```
public func trackPushDelivered(with userInfo: [AnyHashable: Any])
```

#### Track Push Notification Opened

Used to track if a push notificaton was opened in the application and tracks it to Exponea.

```
public func trackPushOpened(with userInfo: [AnyHashable: Any])
```

#### 💻 Usage

```
// Prepare Data
func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        Exponea.shared.trackPushOpened(with: userInfo)
        completionHandler()
}

```

## Rich Push Notifications

Exponea SDK offers complex support for rich notifications that can be created in the Exponea web application. These notifications can show a custom image, action buttons, sound and even extra payload that you might want to provide with your push. 

There are three ways of how you can integrate rich push notifications with your application:

1. Using `ExponeaSDKNotifications` framework in notification service and content extension and automatic push tracking enabled when configuring `ExponeaSDK` in your application. *(easiest option)*
2. Using `ExponeaSDKNotifications` framework in notification service extension and handling push tracking manually in your app *(quick rich push implementation with custom handling)*
3. Handling everything manually *(total freedom, but lots of extra work)*

### Setup

The following points describe the setup for option 1 where everything is done automatically. If you wish to do some parts of the process manually please refer to the [Manual Push Tracking](#Manual-Push-Tracking) section above or the push payload at the bottom of this section.

#### 1. Notification Service Extension

This extension will handle modifying the content of the push notification before it gets displayed, fx. downloads the image and assigns correct category for custom action buttons. Follow the steps below to use the Exponea provided handler that will handle all of this in one line of code. Otherwise you can implement this yourself based on the push payload specified in the bottom of this section or the source code.

1. Create a new notification service extension target in your application, please refer to [official Apple documentation](https://developer.apple.com/documentation/usernotifications/modifying_content_in_newly_delivered_notifications) or a tutorial like [this one](https://code.tutsplus.com/tutorials/ios-10-notification-service-extensions--cms-27550) for example.
2. If you're using **Cocoapods**, make sure you add the `pod 'ExponeaSDK/Notifications` line to your Podfile under the service extension target. If you're using **Carthage** then add the `ExponeaSDKNotifications` framework as a linked framework to the new service extension target along with the carthage script to strip unnecessary architectures.
3. Open the newly created `NotificationService.swift` file and replace the contents with the code below:

```swift
import UserNotifications
import ExponeaSDKNotifications

class NotificationService: UNNotificationServiceExtension {

    let exponeaService = ExponeaNotificationService()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        exponeaService.process(request: request, contentHandler: contentHandler)
    }

    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    override func serviceExtensionTimeWillExpire() {
        exponeaService.serviceExtensionTimeWillExpire()
    }
}
```

#### 2. Notification Content Extension

The notification content extension is necessary to properly handle custom button actions and titles in the notification in iOS 12+. 

1. Create a new notification service extension target in your application, please refer to [official Apple documentation and guide](https://developer.apple.com/documentation/usernotificationsui/customizing_the_appearance_of_notifications) or a tutorial like [this one](https://www.shinobicontrols.com/blog/ios-10-day-by-day-day-6-notification-content-extensions/) for example.
2. Modify your content extension plist to have `EXPONEA_ACTIONABLE` as the value for the `UNNotificationExtensionCategory` key and optionally initial content size ratio to be 0 (test this with your notifications for best look)
![](./Guide/pics/push_content_extension_category.png)
3. If you're using **Cocoapods**, make sure you add the `pod 'ExponeaSDK/Notifications` line to your Podfile under the content extension target. If you're using **Carthage** then add the `ExponeaSDKNotifications` framework as a linked framework to the new service extension target along with the carthage script to strip unnecessary architectures.
4. Open the newly created `NotificationViewController.swift` file and replace the contents with the code below:

```swift
import UIKit
import UserNotifications
import UserNotificationsUI
import ExponeaSDKNotifications

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    let exponeaService = ExponeaNotificationContentService()
    
    func didReceive(_ notification: UNNotification) {
        exponeaService.didReceive(notification, context: extensionContext, viewController: self)
    }
}
```

> If you don't need support for iOS 11 and lower please skip the next step.

#### 3. Custom Notification Actions in iOS 11 and lower (optional)

To support the action buttons that can be configured in the Exponea backend on iOS 11 and lower you will need to implement custom notification categories that are used to properly hook up the button actions and titles. ExponeaSDK provides a convenient factory method to simplify creation of such category. 

> **⚠️ Bear in mind that the category identifier you specify here must be identical to the one you specify in Exponea backend.**

```swift
// Set legacy exponea categories
let category1 = UNNotificationCategory(identifier: "EXAMPLE_LEGACY_CATEGORY_1",
                                      actions: [
    ExponeaNotificationAction.createNotificationAction(type: .openApp, title: "Hardcoded open app", index: 0),
    ExponeaNotificationAction.createNotificationAction(type: .deeplink, title: "Hardcoded deeplink", index: 1)
    ], intentIdentifiers: [], options: [])
    
UNUserNotificationCenter.current().setNotificationCategories([category1])
```

#### 3. Rich Notifications Callbacks

> This step assumes you have **automatic push tracking enabled**, otherwise this will not work and you have to implement this manually. Also note, this will get called even if a notification doesn't have any special rich features like an image or action buttons.

Last step is to listen to the rich push notifications callbacks and handle them in any way you desire. To do that you need to implement a `PushNotificationManagerDelegate` protocol in your class responsible for handling push or your `AppDelegate` and set that class as the push delegate on the Exponea singleton. See the below code for an example:

**IMPORTANT:** You can only set the delegate after Exponea has been configured properly, so please make sure that is done first.

```swift

import ExponeaSDK
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                     
        // Your custom code...
                     
        // Configure Exponea first
        Exponea.shared.configure(projectToken: "mytoken", authorization: .token("key"))
        
        // Set the notification delegate (needs to be done after configuring)
        Exponea.shared.pushNotificationsDelegate = self
    }
}

extension AppDelegate: PushNotificationManagerDelegate {
    func pushNotificationOpened(with action: ExponeaNotificationAction, value: String?, extraData: [AnyHashable : Any]?) {
        // app open, browser, deeplink or none (means no custom button was tapped)
        print("push action: \(action)")
        
        // usually a url, fx. if deeplink, can be nil if action is app open or none
        print("value for action: \(value)") 
        
        // any data payload you specified in Exponea web app
        print("extra payload specified: \(extraData)")
    }
}
```

## Rich Push Notification Payload

If you wish to implement the above steps manually, here is an example payload that will be sent from Exponea web application when using the mobile push notification feature with all options enabled/specified:

```json
{
    "aps": {
        "alert": "Notification title",
        "mutable-content": 1
    },
    "title": "Notification title",
    "message": "Notification text",
    "action": "app",
    "actions": [
        {
            "title": "Open",
            "action": "app"
        },
        {
            "title": "Go to website",
            "action": "browser",
            "url": "https://exponea.com"
        }
    ],
    "image": "https://www.greenflag.com/img/article/l/push-car-safely.jpg",
    "sound": "beep.wav",
    "badge": "increment",
    "attributes": {
        "age": 24,
        "gender": "male"
    }
}
```
