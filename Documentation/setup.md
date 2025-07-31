---
title: Initial SDK setup
excerpt: Install and configure the iOS SDK
slug: ios-sdk-setup
categorySlug: integrations
parentDocSlug: ios-sdk
---

## Install the SDK

The Exponea iOS SDK can be installed or updated using [CocoaPods](https://cocoapods.org/) or [Swift Package Manager](https://www.swift.org/package-manager/).

The instructions below are for Xcode 15.1 and may differ if you use a different Xcode version.

### CocoaPods

1. Install [CocoaPods](https://cocoapods.org/) if you haven't done so yet.
2. Create a file named `Podfile` in your Xcode project folder.
3. Add the following to your `Podfile`
   ```
   platform :ios, '13.0'
   use_frameworks!

   target 'YourAppTarget' do
     pod "ExponeaSDK"
   end
   ```
   (Replace `13.0` with your desired iOS deployment target and `YourAppTarget` with your app target's name)
4. In a terminal window, navigate to your Xcode project folder and run the following command:
    ```
    pod install
    ```
5. Open the file `HelloWorld.xcworkspace`, located in your project folder, in XCode.
6. In Xcode, select your project, then select the `Build Settings` tab. Under `Build Options`, change `User Script Sandboxing` from `Yes` to `No`.

Optionally, you can specify the `ExponeaSDK` version as follows to let `pod` automatically any smaller than minor version updates:
```
pod "ExponeaSDK", "~> 3.6.0"
```
For more information, refer to [Specifying pod versions](https://guides.cocoapods.org/using/the-podfile.html#specifying-pod-versions) in the Cocoapods documentation.

### Swift Package Manager

1. In Xcode, navigate to `Xcode -> Settings -> Accounts` and add your GitHub account if you haven't already. 
2. Open `File -> Add Package Dependencies...`
3. In the dialog that appears, enter the Exponia iOS SDK repository URL `https://github.com/exponea/exponea-ios-sdk` in the search box.
4. In the `Dependency Rule` section, select the SDK version.
   ![Add Package Dependencies dialog](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/swift-pm-1.png)
5. Click on `Add Package`.
6. In the next dialog, make sure `ExponeaSDK` and `ExponeaSDK-Notifications` are both selected.
   ![Choose Packages dialog](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/swift-pm-2.png)
7. Click on `Add Package`.

## Initialize the SDK

Now that you have installed the SDK in your project, you must import, configure, and initialize the SDK in your application code.

> ❗️ Protect the privacy of your customers
 >
 > Make sure you have obtained and stored tracking consent from your customer before initializing Exponea iOS SDK.
 >
 > To ensure you're not tracking events without the customer's consent, you can use `Exponea.shared.clearLocalCustomerData(appGroup: String)` when a customer opts out from tracking (this applies to new users or returning customers who have previously opted out). This will bring the SDK to a state as if it was never initialized. This option also prevents reusing existing cookies for returning customers.
 >
 > Refer to [Clear local customer data](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking#clear-local-customer-data) for details.
 >
 > If the customer denies tracking consent after Exponea iOS SDK is initialized, you can use `Exponea.shared.stopIntegration()` to stop SDK integration and remove all locally stored data.
 >
 > Refer to [Stop SDK integration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking#stop-sdk-integration) for details.


The required configuration parameters are `projectToken`, `authorization.token`, and `baseUrl`. You can find these as `Project token`, `API Token`, and `API Base URL` in the Bloomreach Engagement webapp under `Project settings` > `Access management` > `API`:

![Project token, API Base URL, and API key](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/api-access-management.png)

> 📘
>
> Refer to [Mobile SDKs API access management](https://documentation.bloomreach.com/engagement/docs/mobile-sdks-api-access-management) for details.

Import the SDK:

```swift
import ExponeaSDK
```

Initialize the SDK:

```swift
Exponea.shared.configure(
	Exponea.ProjectSettings(
		projectToken: "YOUR PROJECT TOKEN",
		authorization: .token("YOUR API KEY"),
		baseUrl: "https://api.exponea.com"
	),
	pushNotificationTracking: .disabled
)
```

Your `AppDelegate`'s `application:didFinishLaunchingWithOptions` method is typically a good place to do the initialization but, depending on your application design, it can be anywhere in your code.

At this point, the SDK is active and should now be tracking customers and events in your app.

SDK initialization immediately creates a new customer profile with a new cookie [soft ID](https://documentation.bloomreach.com/engagement/docs/customer-identification#soft-id) unless the customer has been [identified](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking#identify) previously.

> 📘
>
> Refer to [Tracking](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking) for details on which events are automatically tracked by the SDK.

> ❗️ 
> 
> [Configuring the SDK using a `plist` file](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration#using-a-configuration-file---legacy) is deprecated but still supported for backward compatibility.

## Other SDK configuration

### Advanced configuration

The SDK can be further configured by providing additional parameters to the `configure` method. For a complete list of available configuration parameters, refer to the [Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) documentation.

### Log level

The SDK supports the following log levels:

| Log level  | Description |
| -----------| ----------- |
| `.none`    | Disables all logging |
| `.error`   | Serious errors or breaking issues |
| `.warning` | Warnings and recommendations + `.error` |
| `.verbose` | Information about all SDK actions + `.warning` + `.error`. |

The default log level is `.warn`. While developing or debugging, setting the log level to `.verbose` can be helpful.

You can set the log level at runtime as follows:

```swift
Exponea.logger.logLevel = .verbose
```
  
> 👍 
> 
> For better visibility, log messages from the SDK are prefixed with `[EXP-iOS]`.

### Authorization

Read [Authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization) to learn more about the different authorization modes supported by the SDK and how to use [customer token](https://documentation.bloomreach.com/engagement/docs/customer-token) authorization.

### Data flushing

Read [Data flushing](https://documentation.bloomreach.com/engagement/docs/ios-sdk-data-flushing) to learn more about how the SDK uploads data to the Engagement API and how to customize this behavior.
