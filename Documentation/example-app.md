---
title: Example app for iOS SDK
slug: ios-sdk-example-app
category:
  uri: /branches/2/categories/guides/Developers
parent:
  uri: ios-sdk
content:
  excerpt: 'Build, run, and navigate the example app included with the iOS SDK'
---

The Exponea iOS SDK includes an example application you can use as a reference implementation. You can build and run the app, test Engagement features, and compare the code and behavior of your implementation with the expected behavior and code in the example app.

## Prerequisites

You must have the following software installed to be able to build and run the example app:

- Xcode
- [CocoaPods](https://cocoapods.org/)

In Xcode, navigate to **Xcode** > **Settings** > **Locations** and make sure `Command Line Tools` is set to your Xcode version.

## Build and run the example app

1. Clone the [exponea-ios-sdk](https://github.com/exponea/exponea-ios-sdk) repository on GitHub:
   ```shell
   git clone https://github.com/exponea/exponea-ios-sdk.git
   ```
2. Run the following CocoaPods command:
   ```shell
   pod install
   ```
3. Open the `ExponeaSDK.xcworkspace` file to open the project in Xcode.
4. In the Project navigator in Xcode, select the `ExponeaSDK` project.
5. Navigate to the `Example` application target's settings. On the **General** tab, find the `Frameworks, Libraries, and Embedded Content` section and verify that `ExponeaSDK.framework` is listed.
6. Navigate to **Product** > **Scheme** and select `Example`.
7. Select **Product** > **Build** (Cmd + B).
8. Select **Product** > **Run** (Cmd + R) to run the example app in the simulator.

> 📘
>
> To enable push notifications in the example app, you must also [Configure Apple Push Notification Service for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configure-apns) in the Engagement web app.

## Navigate the example app

![Example app screens: authorization](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/ios-example-app-auth-screen-variants.png)
![Example app screens: fetching, tracking, track event, identify customer](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/ios-example-app-screens-1.png)

When you run the app in the simulator, you'll see the **Authentication** view. The screen fields change depending on the selected integration type. Here's how to set it up:
1. Select your integration type from the dropdown: **Stream ID** or **Project token**.
2. For **Stream ID**:
   - Enter your `Stream ID`.
   - **Optional:** Enter `Key ID` and `Key secret` to enable local JWT token generation for testing. Both must be provided together. Refer to [SDK auth token authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#sdk-auth-token-authorization) for details.
   - **Optional:** Enter a `Registered customer ID` to identify the customer at startup. When `Key ID` and `Key secret` are provided, the registered customer ID is required.
3. For **Project token**:
   - Enter your `Project token`.
   - **Optional:** Enter the `Authorization` (API key).
   - **Optional:** Enter the `Advanced Auth` key to enable [customer token authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#customer-token-authorization).
4. Enter the `Base (API) URL` (API base URL for the Bloomreach platform).
5. **Optional:** Enter an `Application ID` if your Engagement project supports multiple mobile apps. If you leave this blank, the SDK uses the default value `default-application`. [Learn more about Configuration for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration).
6. Click **Start** to [initialize the SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#initialize-the-sdk).

The **Clear local data** button invokes `Exponea.shared.clearLocalCustomerData(appGroup:)` to delete all locally stored data without initializing the SDK.

> [`AuthenticationViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/AuthenticationViewController.swift)

> 👍
>
> When using **Project token**, make sure to prefix your API key with `Token `, for example:
> `Token 0b7uuqicb0fwuv1tqz7ubesxzj3kc3dje3lqyqhzd94pgwnypdiwxz45zqkhjmbf`.

The app provides several views, accessible using the bottom navigation, to test the different SDK features:

- The **Fetching** view enables you to fetch recommendations, consents, and segments, as well as open the app inbox.
  > [`FetchViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Fetching/FetchViewController.swift)

- The **Tracking** view enables you to test tracking of different events and properties. The `Custom Event` and `Identify Customer` buttons lead to their separate views to enter test data.
  > [`TrackingViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Tracking/TrackingViewController.swift)
  > [`TrackEventViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Tracking/TrackEventViewController.swift)
  > [`IdentifyCustomerViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Tracking/IdentifyCustomerViewController.swift)

- The **Flushing** view lets you trigger a manual data flush and log out.
  > [`FlushingViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Flushing/FlushingViewController.swift)

- The **Anonymize** view lets you anonymize the current user and stop the SDK integration.
  > [`AnonymizeViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Anonymize/AnonymizeViewController.swift)

- The **In-app Content Blocks** view displays in-app content blocks. Use placeholder IDs `example_top`, `ph_x_example_iOS`, `example_list`, `example_carousel`, and `example_carousel_ios` in your in-app content block settings.
  > [`InAppContentBlocksViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/InAppContentBlocks/InAppContentBlocksViewController.swift)
  > [`InAppContentBlockCarouselViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/InAppContentBlocks/InAppContentBlockCarouselViewController.swift)

- The **Logging** view displays log messages from the SDK.
  > [`LogViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Logging/LogViewController.swift)

Try out the different features in the app, then find the customer profile in the Engagement web app (under `Data & Assets` > `Customers`) to see the properties and events tracked by the SDK.

If you enter a `Registered customer ID` on the authentication screen (Stream ID mode), the customer is identified from startup and can be found in the Engagement web app by their registered ID.

If you left the `Registered customer ID` field blank, or are using Project token mode, the customer is tracked anonymously using a cookie soft ID. You can look up the cookie value in the logs and find the corresponding profile in the Engagement web app.

If you use `Identify Customer` in the app to set the `registered` hard ID (use an email address as value), the customer is identified and can be found in the Engagement web app by their email address.

> 📘
>
> Refer to [Customer identification](https://documentation.bloomreach.com/engagement/docs/customer-identification) for more information on soft IDs and hard IDs.

![Example app screens: flushing, anonymize, logging, content blocks](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/ios-example-app-screens-2.png)

## Troubleshooting

If you encounter any issues building the example app, the following may help:

- Remove the `Pods` folder and the `Podfile.lock` file from the project folder and rerun the `pod install` command.
- In Xcode, select `Product` > `Clean Build Folder` (Cmd + Shift + K), then `Product` > `Build` (Cmd + B).
