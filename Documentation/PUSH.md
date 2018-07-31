## 📣  Push Notifications

Exponea SDK allows you to easily create complex scenarios which you can use to send push notifications directly to your customers. The following section explains how to enable receiving push notifications.

For push notifications to work, you need a push notifications certificate with a corresponding private key in a single file in PEM format. The following steps show you how to export one from the Keychain Access application on your Mac:

## 🛠 Setup ##

For push notifications to work, you need a push notifications token with a corresponding key identifier and team identifier. The following steps show you how to create on in the [Apple Developer Center](https://developer.apple.com):

1. Login to your Apple Developer Account and navigate to *Certificates, Identifiers & Profiles*
2. Navigate to a new section *APNs Auth Key* under the *Certificates* tab in the left pane
3. Click the add button in the upper right corner
4. Under *Production* select *Apple Push Notification Authentication Key (Sandbox & Production)* and click continue and a key will be created for you
5. **Download the .p8 key file** and note the **Key ID**
6. While you're in the member center, grab your **Team ID** as well in the membership area
7. The last step is to set up APNs in the Exponea web application, so login to your app and navigate to *Project management -> Project Settings -> Push Notifications*
8. Input the following information:
	-  Open the downloaded .p8 file in TextEdit and copy it's contents the into *ES256 Private Key*
	-  Fill in the *Team ID* as copied from the Member Center
	-  Fill in the *Key ID* provided during key creation (or in .p8 filename)
	-  Fill in the *Application Bundle ID* of your application
	-  Choose if you wish to use production or development API
9. Click *Save* and your project should be connected with Exponea properly 

Now you are ready to implement Push Notifications into your iOS application. You can do that by opening your project in Xcode and then go to your Targets, under your app’s name, select Capabilities and find Push Notifications in the list, switch to *ON*. 

Refer to Apple documentation on how to implement push notification setup in your application and make sure you are also submitting the client token to Exponea either using automatic or manual tracking as described below.

If you had done everything right, you should now be able to send notifications from Exponea to your application. 

## 🔍 Automatic Push Tracking

In the Exponea SDK configuration, you can enable or disable the automatic push notification tracking setting the Boolean value to the `automaticPushNotificationTracking` property.

If the `automaticPushNotificationTracking` is enabled, then the SDK will add track the "campaign" event with the correct properties.

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

#### Track Push Notification Opened

Used to track if a push notificaton was opened in the application and tracks it to Exponea.

```
public func trackPushOpened(with userInfo: [AnyHashable: Any])
```

#### 💻 Usage

```
// Prepare Data
let userInfo = ["action_type": "notification",
                "status": "clicked"]

Exponea.shared.trackPushOpened(with: userInfo)
```
