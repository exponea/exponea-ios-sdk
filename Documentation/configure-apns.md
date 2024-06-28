---
title: Configure Apple Push Notification Service
excerpt: Configure the Apple Push Notification Service Integration for Engagement
slug: ios-sdk-configure-apns
categorySlug: integrations
parentDocSlug: ios-sdk-push-notifications
---

To be able to send [iOS push notifications](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications) using Engagement, you must obtain an Apple Push Notification service (APNs) authentication token signing key and configure the APNs integration in the Engagement web app.

> 📘
>
> Refer to the [Apple Push Notifications developer documentation](https://developer.apple.com/documentation/usernotifications) for details.

## Obtain an APNs Key

1. In your [Apple Developer account](https://developer.apple.com/account/resources/authkeys/list), navigate to `Certificates, Identifiers & Profiles` > `Keys`.
![Apple Developer - APNs keys](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/apns1.png)

2. Add a new key and select APNs.
![Apple Developer - register a new APNs key](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/apns2.png)

3. Confirm the creation of the key. Click `Download` to generate and download the key. Make note of the `Team id` (in the top right corner) and the `Key Id`.
![Apple Developer - download APNs key](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/apns3.png)

> ❗️
>
> Make sure to save the downloaded key in a secure place, as you cannot download this more than once.

## Add APNs Key to Engagement

1. Open the Engagement web application and navigate to `Data & Assets` > `Integrations`. Click `+ Add new integration`.
![Engagement Integrations - Add new integration](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/apns4.png)

2. Locate `Apple Push Notification Service` and click `+ Add integration`.
![Engagement Integrations - Select Apple Push Notification Service integration](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/apns5.png)

3. Read and accept the terms and conditions.
![Engagement Integrations - Accept terms and conditions](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/apns6.png)

4. Select an `API mode` (`Development` or `Production`) and enter the `Team ID` and `Key ID`. Open the key file you downloaded in a text editor and copy-paste its contents into the `ES256 Private Key` field. Enter your app's `Bundle ID`. Click `Save integration` to finish.
![Engagement Integrations - Configure APNs integration](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/apns7.png)
   > ❗️
   >
   > API environment (`Development` or `Production`) cannot be changed later. You have to create a new integration in case you want to use a different environment. If you encounter BadDeviceToken errors, verify that you have selected the correct API environment.
   
   > ❗️
   >
   > Only one APNs integration can be active at the same time in an Engagement project. If you'd like to use both the development and production APNs environments at the same time, you need two separate Engagement projects.

   > ❗️
   >
   > Ensure the `Application Bundle ID` matches the `Bundle Identifier` in your application target in Xcode. If they don't match, push notification will fail to be delivered.


5. Navigate to `Settings` > `Project settings` > `Channels` > `Push notifications` > `iOS Notification` and set `Apple Push Notification Service integration` to `Apple Push Notification Service`.
![Engagement - Select APNs integration](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/apns8.png)
