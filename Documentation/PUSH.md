## 📣  Push Notifications

Exponea SDK allows you to easily create complex scenarios which you can use to send push notifications directly to your customers. The following section explains how to enable receiving push notifications.

For push notifications to work, you need a working Google API project. The following steps show you how to create one. If you already have created a Google API project and you have your **project number (or sender ID)** and **Google Cloud Messaging API key**, you may skip this part of the tutorial and proceed directly to enabling of the push notifications in the Exponea SDK.

### Google API project

1) In your preferred browser, navigate to [Google Console](https://console.developers.google.com)
2) Click on **Create Project** button
3) Fill in preferred project name and click **Create** button
4) Please wait for the project to create, it usually takes only a few seconds
5) After the project has been created you will be redirected to the **Project Dashboard** page where you'll find **Project Number** which is needed in the Infinario Android SDK
6) In the left menu, navigate to **APIs & auth -> APIs** and find **Google Cloud Messaging for Android**
7) Please make sure the Google Cloud Messaging for Android is **turned ON**
8) In the left menu, navigate to **APIs & auth -> Credentials** and click on **Create new Key** button
9) Click on **Server key** button and the click on **Create** button
10) Copy the API key which is needed for the Infinario web application

### Infinario web application

Once you have obtained **Google Cloud Messaging API key**, you need to enter it in the input field on the **Company / Settings / Notifications** in the Infinario web application.

## 🔍 Automatic track Push Notification

In the Exponea SDK configuration, you can enable or disable the automatic push notification tracking setting the Boolean value to the `isAutoPushNotification` property.

If the `isAutoPushNotification` is enabled, then the SDK will add track the "campaign" event with the correct properties.

In case you decide to deactivate the automatic push notification, you can still track this event manually.

#### Track FCM Token

```
fun trackFcmToken(
        customerIds: CustomerIds,
        fcmToken: String
)
```

#### 💻 Usage

```
val customerIds = CustomerIds(registered = "john@doe.com")

Exponea.trackFcmToken(
        customerIds = customerIds,
        fcmToken = "382d4221-3441-44b7-a676-3eb5f515157f"
)
```

#### Track Delivered Push Notification

```
fun trackDeliveredPush(
        customerIds: CustomerIds, 
        fcmToken: String, 
        timestamp: Long? = null
)
```

#### 💻 Usage

```
val customerIds = CustomerIds(registered = "john@doe.com")

Exponea.trackDeliveredPush(
        customerIds = customerIds,
        fcmToken = "382d4221-3441-44b7-a676-3eb5f515157f"
        timestamp = Date().time
)
```

#### Track Clicked Push Notification

```
fun trackClickedPush(
        customerIds: CustomerIds, 
        fcmToken: String, 
        timestamp: Long? = null
) 
```

#### 💻 Usage

```
val customerIds = CustomerIds(registered = "john@doe.com")

Exponea.trackClickedPush(
        customerIds = customerIds,
        fcmToken = "382d4221-3441-44b7-a676-3eb5f515157f"
        timestamp = Date().time
)
```