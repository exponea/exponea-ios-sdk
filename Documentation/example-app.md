---
title: Example App
excerpt: Build, run, and navigate the example app included with the iOS SDK
slug: ios-sdk-example-app
categorySlug: integrations
parentDocSlug: ios-sdk
---

The Exponea iOS SDK includes an example application you can use as a reference implementation. You can build and run the app, test Engagement features, and compare the code and behavior of your implementation with the expected behavior and code in the example app.

## Prerequisites

You must have the following software installed to be able to build and run the example app:

- Xcode
- [CocoaPods](https://cocoapods.org/)
- [Carthage](https://github.com/Carthage/Carthage)

In Xcode, navigate to `Xcode` > `Preferences` > `Locations` and make sure `Command Line Tools` is set to your Xcode version.

## Build and Run the Example App

1. Clone the [exponea-ios-sdk](https://github.com/exponea/exponea-ios-sdk) repository on GitHub:
   ```shell
   git clone https://github.com/exponea/exponea-ios-sdk.git
   ```
2. Run the following CocoaPods command:
   ```shell
   pod install
   ```
3. Run the following Carthage command:
   ```shell
   carthage update --use-xcframeworks --platform iOS
   ```
4. Open the `ExponeaSDK.xcworkspace` file to open the project in Xcode.
5. In the Project navigator in Xcode, select the `ExponeaSDK` project.
6. Navigate to the `Example` application target's settings. On the `General` tab, find the `Frameworks, Libraries, and Embedded Content` section.
7. Open Finder, navigate to the `Carthage/Build` folder inside the `exponea-ios-sdk` folder, and drag and drop every `*.xcframework` folder inside it to the `Frameworks, Libraries, and Embedded Content` section in Xcode.
8. Navigate to `Product` > `Scheme` and select `Example`.
9. Select `Product` > `Build` (Cmd + B).
10. Select `Product` > `Run` (Cmd + R) to run the example app in the simulator.

> 📘
>
> To enable push notifications in the example app, you must also [configure the Apple Push Notification Service integration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configure-apns) in the Exponea web app.

## Navigate the Example App

![Example app screens: configuration, fetch, track, track event](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/sample-app-1.png)

When you run the app in the simulator, you'll see the **Authentication** view. Enter your [project token, API token, and API base URL](https://documentation.bloomreach.com/engagement/docs/mobile-sdks-api-access-management), then click `Start` to [initialize the SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#initialize-the-sdk).
> [`AuthenticationViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/AuthenticationViewController.swift)

The app provides several views, accessible using the bottom navigation, to test the different SDK features:

- The **Fetch Data** view enables you to fetch recommendations and consents as well as open the app inbox.
  > [`FetchViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Fetching/FetchViewController.swift)

- The **Tracking** view enables you to test tracking of different events and properties. The `Custom Event` and `Identify Customer` buttons lead to their separate views to enter test data.
  > [`TrackingViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Tracking/TrackingViewController.swift)
  > [`TrackEventViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Tracking/TrackEventViewController.swift)
  > [`IdentifyCustomerViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Tracking/IdentifyCustomerViewController.swift)

- The **Flushing** view lets you trigger a manual data flush, anonymize the customer data, and log out.
  > [`FlushingViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Flushing/FlushingViewController.swift)

- The **Logging** view displays log messages from the SDK.
  > [`LogViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/Logging/LogViewController.swift)

- The **In-app Content Blocks** view displays in-app content blocks. Use placeholder IDs `example_top`, `ph_x_example_iOS`, and `example_list` in your in-app content block settings.
  > [`InAppContentBlocksViewController.swift`](https://github.com/exponea/exponea-ios-sdk/blob/main/ExponeaSDK/Example/Views/InAppContentBlocks/InAppContentBlocksViewController.swift)

Try out the different features in the app, then find the customer profile in the Engagement web app (under `Data & Assets` > `Customers`) to see the properties and events tracked by the SDK.

Until you use `Identify Customer` in the app, the customer is tracked anonymously using a cookie soft ID. You can look up the cookie value in the logs and find the corresponding profile in the Engagement web app.

Once you use `Identify Customer` in the app to set the `registered` hard ID (use an email address as value), the customer is identified and can be found in Engagement web app by their email address.

> 📘
>
> Refer to [Customer Identification](https://documentation.bloomreach.com/engagement/docs/customer-identification) for more information on soft IDs and hard IDs.

![Example app screens: identify, flushing, logging, content blocks](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/sample-app-2.png)

## Troubleshooting

If you encounter any issues building the example app, the following may help:

- Remove the `Pods` folder and the `Podfile.lock` file from the project folder and rerun the `pod install` command.
- Remove the `Carthage` folder and the `Cartfile.resolved` file from the project folder and rerun the full `carthage update` command above.
- In Xcode, select `Product` > `Clean Build Folder` (Cmd + Shift + K), then `Product` > `Build` (Cmd + B).