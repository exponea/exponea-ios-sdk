## 📣  Push Notifications

Exponea SDK allows you to easily create complex scenarios which you can use to send push notifications directly to your customers. The following section explains how to enable receiving push notifications.

For push notifications to work, you need a push notifications certificate with a corresponding private key in a single file in PEM format. The following steps show you how to export one from the Keychain Access application on your Mac:

## Apple Push certificate ##

For push notifications to work, you need a push notifications certificate with a corresponding private key in a single file in PEM format. The following steps show you how to export one from the Keychain Access application on your Mac:

* Launch Keychain Access application on your Mac
* Find Apple Push certificate for your app in *Certificates* or *My certificates* section (it should start with **Apple Development IOS Push Services:** for development certificate or **Apple Production IOS Push Services:** for production certificate)
* The certificate should contain a **private key**, select both certificate and its corresponding private key, then right click and click **Export 2 items**
* In the saving modal window, choose a filename and saving location which you prefer and select the file format **Personal Information Exchange (.p12)** and then click **Save**
* In the next modal window, you will be prompted to choose a password, leave the password field blank and click **OK**. Afterwards, you will be prompted with you login password, please enter it.
* Convert p12 file format to PEM format using OpenSSL tools in terminal. Please launch **Terminal** and navigate to the folder, where the .p12 certificate is saved (e.g.  `~/Desktop/ `)
* Run the following command  `openssl pkcs12 -in certificate.p12 -out certificate.pem -clcerts -nodes`, where **certificate.p12** is the exported certificate from Keychain Access and **certificate.pem** is the converted certificate in PEM format containing both Apple Push certificate and its private key
* The last step is to upload the Apple Push certificate to the Exponea web application. In the Exponea web application, navigate to **Project management -> Settings -> Notifications**
* Copy the content of **certificate.pem** into **Apple Push Notifications Certificate** and click **Save**

Now you are ready to implement Push Notifications into your iOS application.

## 🔍 Automatic track Push Notification

In the Exponea SDK configuration, you can enable or disable the automatic push notification tracking setting the Boolean value to the `automaticPushNotificationTracking` property.

If the `automaticPushNotificationTracking` is enabled, then the SDK will add track the "campaign" event with the correct properties.

In case you decide to deactivate the automatic push notification, you can still track this event manually.

#### Track Push Token

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
