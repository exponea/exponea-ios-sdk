---
title: Initial SDK Setup
excerpt: Install and configure the iOS SDK
slug: ios-sdk-setup
categorySlug: integrations
parentDocSlug: ios-sdk
---

## Install the SDK

The Exponea iOS SDK can be installed or updated using [CocoaPods](https://cocoapods.org/), [Carthage](https://github.com/Carthage/Carthage), or [Swift Package Manager](https://www.swift.org/package-manager/).

The instructions below are for Xcode 15.1 and may differ if you use a different Xcode version.

### CocoaPods

1. Install [CocoaPods](https://cocoapods.org/) if you haven't done so yet.
2. Create a file named `Podfile` in your Xcode project folder.
3. Add the following to your `Podfile`
   ```
   platform :ios, '11.0'
   use_frameworks!

   target 'YourAppTarget' do
     pod "ExponeaSDK"
   end
   ```
   (Replace `11.0` with your desired iOS deployment target and `YourAppTarget` with your app target's name)
4. In a terminal window, navigate to your Xcode project folder and run the following command:
    ```
    pod install
    ```
5. Open the file `HelloWorld.xcworkspace`, located in your project folder, in XCode.
6. In Xcode, select your project, then select the `Build Settings` tab. Under `Build Options`, change `User Script Sandboxing` from `Yes` to `No`.

Optionally, you can specify the `ExponeaSDK` version as follows to let `pod` automatically any smaller than minor version updates:
```
pod "ExponeaSDK", "~> 2.22.0"
```
For more information, refer to [Specifying pod versions](https://guides.cocoapods.org/using/the-podfile.html#specifying-pod-versions) in the Cocoapods documentation.

### Carthage

1. Install [Carthage](https://github.com/Carthage/Carthage) if you haven't done so yet.
2. Create a file named `Cartfile` in your Xcode project folder.
3. Add the following line to your `Cartfile`
    ```
    github "exponea/exponea-ios-sdk"
    ```
4. In a terminal window, navigate to your Xcode project folder and run the following command:
    ```
    carthage update exponea-ios-sdk --use-xcframeworks --platform iOS
    ```
5. Open your Xcode project and navigate to your application target's settings. On the `General` tab, find the `Frameworks, Libraries, and Embedded Content` section.
6. Open Finder, navigate to the `Carthage/Build` folder inside your project folder, and drag and drop every `*.xcframework` folder inside it to the `Frameworks, Libraries, and Embedded Content` section in Xcode.
   ![XCFRameworks added to Frameworks, Libraries, and Embedded Content](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/develop/Documentation/images/carthage-xcframeworks.png)

### Swift Package Manager

1. In Xcode, navigate to `Xcode -> Settings -> Accounts` and add your GitHub account if you haven't done so yet. 
2. Open `File -> Add Package Dependencies...`
3. In the dialog that appears, enter the Exponia iOS SDK repository URL `https://github.com/exponea/exponea-ios-sdk` in the search box.
4. In the `Dependency Rule` section, select the SDK version.
   ![Add Package Dependencies dialog](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/develop/Documentation/images/swift-pm-1.png)
5. Click on `Add Package`.
6. In the next dialog, make sure `ExponeaSDK` and `ExponeaSDK-Notifications` are both selected.
   ![Choose Packages dialog](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/develop/Documentation/images/swift-pm-2.png)
7. Click on `Add Package`.

## Initialize the SDK

Now that you have installed the SDK in your project, you must import, configure, and initialize the SDK in your application code.

The required configuration parameters are `projectToken`, `authorization.token`, and `baseUrl`. You can find these as `Project token`, `API Token`, and `API Base URL` in the Bloomreach Engagement webapp under `Project settings` > `Access management` > `API`:

![Project token, API Base URL, and API key](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/develop/Documentation/images/api-access-management.png)

> 📘
>
> Refer to [Mobile SDKs API Access Management](https://documentation.bloomreach.com/engagement/docs/mobile-sdks-api-access-management) for details.

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

## Other SDK Configuration

### Advanced Configuration

The SDK can be further configured by providing additional parameters to the `configure` method. For a complete list of available configuration parameters, refer to the [Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) documentation.

### Log Level

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

### Data Flushing

Read [Data Flushing](https://documentation.bloomreach.com/engagement/docs/ios-sdk-data-flushing) to learn more about how the SDK uploads data to the Engagement API and how to customize this behavior.