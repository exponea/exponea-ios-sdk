<p align="center">
  <img src="./Documentation/logo_yellow.png?raw=true" alt="Exponea"/>
</p>

![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg?style=flat)
![Platform](https://img.shields.io/badge/Swift-4.2+-green.svg?style=flat)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Exponea iOS SDK

This library allows you to interact from your application or game with the Exponea App. Exponea empowers B2C marketers to raise conversion rates, improve acquisition ROI, and maximize customer lifetime value.

It has been written 100% in Swift with ❤️

## 📦 Installation

### CocoaPods

```ruby
# Add this under your main application target
pod "ExponeaSDK", "~> 2.18.0"

# If you also use rich push notifications,
# add this line to your notification service extension target.
pod "ExponeaSDK-Notifications", "~> 2.18.0"
```

> Read more about rich push notifications support [here](./Documentation/PUSH.md).

### Carthage

> Carthage will by default build both `ExponeaSDK` and `ExponeaSDKNotifications` frameworks. The latter one is only supposed to be used in a notification service extension if you wish support rich push notifications. Read more about rich push notifications [here](./Documentation/PUSH.md).

```
github "exponea/exponea-ios-sdk" ~> 2.18.0
```
> And then in your Command line tool type ```carthage update --use-xcframeworks --platform ios```

> In your Target's General tab, under section Frameworks, Libraries and Embeeded Content, add the carthage built xcfw into it and set to them 'Embed & Sign'.

## 📱 Demo Application

Check out our [sample project](https://github.com/exponea/exponea-ios-sdk/tree/master/ExponeaSDK/Example) to try it yourself! 😉

## 💻 Usage

### Getting Started

Check the detailed [step by step guide here](./Documentation/Guide/GUIDE.md) to get started.

### Documentation

To implement the Exponea SDK you must configure the SDK first:

* [Configuration](./Documentation/CONFIG.md)

Then you can start using all the other features:

* [Track Events & Customer Properties](./Documentation/TRACK.md)
* [Track Campaigns(Universal links)](./Documentation/UNIVERSAL_LINK.md)
* [Data Flushing](./Documentation/FLUSH.md)
* [Push Notifications](./Documentation/PUSH.md)
* [Fetch Data](./Documentation/FETCH.md)
* [Anonymize](./Documentation/ANONYMIZE.md)
* In-App Perzonalization
  * [In-app messages](./Documentation/IN_APP_MESSAGES.md)
  * [In-app content blocks](./Documentation/IN_APP_CONTENT_BLOCKS.md)
* [App Inbox](./Documentation/APP_INBOX.md)

## 🔗 Useful links

* [Exponea App](https://app.exponea.com/login)

## 📝 Release Notes

Release notes can be found [here](./Documentation/RELEASE_NOTES.md).

## Support

Are you a Bloomreach customer and dealing with some issues on mobile SDK? You can reach the official Engagement Support [via these recommended ways](https://documentation.bloomreach.com/engagement/docs/engagement-support#contacting-the-support).
Note that Github repository issues and PRs will also be considered but with the lowest priority and without guaranteed output.
