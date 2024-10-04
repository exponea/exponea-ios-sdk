<p align="center">
  <img src="./Documentation/images/logo_engagement.png?raw=true" alt="Exponea"/>
</p>

![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg?style=flat)
![Platform](https://img.shields.io/badge/Swift-4.2+-green.svg?style=flat)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Exponea iOS SDK

This library allows you to interact with Bloomreach Engagement from your application or game. Engagement empowers B2C marketers to raise conversion rates, improve acquisition ROI, and maximize customer lifetime value.

It has been written 100% in Swift with ❤️

> 
> Bloomreach Engagement was formerly known as Exponea. For backward compatibility, the Exponea name continues to be used in the iOS SDK.

## 📦 Installation

### CocoaPods

```ruby
# Add this under your main application target
pod "ExponeaSDK", "~> 2.28.0"

# If you also use rich push notifications,
# add this line to your notification service extension target.
pod "ExponeaSDK-Notifications", "~> 2.28.0"
```

### Carthage

> Carthage will by default build both `ExponeaSDK` and `ExponeaSDKNotifications` frameworks. The latter one is only supposed to be used in a notification service extension if you wish to support rich push notifications. Read more about rich push notifications [here](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications#rich-push-notifications).

```
github "exponea/exponea-ios-sdk" ~> 2.28.0
```
> And then in your Command line tool type ```carthage update --use-xcframeworks --platform ios```

> In your Target's General tab, under section Frameworks, Libraries and Embeeded Content, add the carthage built xcfw into it and set to them 'Embed & Sign'.

## 📱 Example Application

Check out our [example app](https://github.com/exponea/exponea-ios-sdk/tree/master/ExponeaSDK/Example) to try it yourself! 😉

## 💻 Usage

### Getting Started

Follow the detailed [step by step guide here](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup) to get started.

### Documentation

- [Initial SDK Setup](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup)
  - [Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration)
  - [Data Flushing](https://documentation.bloomreach.com/engagement/docs/ios-sdk-data-flushing)
- [Tracking](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking)
- [Universal Links](https://documentation.bloomreach.com/engagement/docs/ios-sdk-universal-links)
- [Push Notifications](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications)
  - [Configure Apple Push Notification Service](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configure-apns)
  - [Notification Extensions](https://documentation.bloomreach.com/engagement/docs/ios-sdk-notification-extensions)
- [Fetch Data](https://documentation.bloomreach.com/engagement/docs/ios-sdk-fetch-data)
- [In-App Personalization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-in-app-personalization)
  - [In-App Messages](https://documentation.bloomreach.com/engagement/docs/ios-sdk-in-app-messages)
  - [In-App Content Blocks](https://documentation.bloomreach.com/engagement/docs/ios-sdk-in-app-content-blocks)
- [App Inbox](https://documentation.bloomreach.com/engagement/docs/ios-sdk-app-inbox)
- [Tracking Consent](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent)
- [Example App](https://documentation.bloomreach.com/engagement/docs/ios-sdk-example-app)
- [Release Notes](https://documentation.bloomreach.com/engagement/docs/ios-sdk-release-notes)
  - [SDK Version Update Guide](https://documentation.bloomreach.com/engagement/docs/ios-sdk-version-update)

## 🔗 Useful links

* [Bloomreach Engagement login](https://app.exponea.com/login)

## 📝 Release Notes

Release notes can be found [here](https://documentation.bloomreach.com/engagement/docs/ios-sdk-release-notes).

## Support

Are you a Bloomreach customer and having some issues with the mobile SDK? You can reach the official Engagement Support [via these recommended ways](https://documentation.bloomreach.com/engagement/docs/engagement-support#contacting-the-support).

Note that Github repository issues and PRs will also be considered but with the lowest priority and without guaranteed output.
