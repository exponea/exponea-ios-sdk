<p align="center">
  <img src="./Documentation/logo_yellow.png?raw=true" alt="Exponea"/>
</p>

![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg?style=flat)
![Platform](https://img.shields.io/badge/Swift-4.1-green.svg?style=flat)
[![License](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://opensource.org/licenses/Apache-2.0)

## Exponea iOS SDK

This library allows you to interact from your application or game with the Exponea App. Exponea empowers B2C marketers to raise conversion rates, improve acquisition ROI, and maximize customer lifetime value.

It has been written 100% in Swift with ❤️


## 📦 Installation

### CocoaPods

```ruby
# Add this under your main application target
pod "ExponeaSDK", "~> 2.5.1"

# If you also use rich push notifications,
# add this line to your notification service extension target.
pod "ExponeaSDK-Notifications", "~> 2.5.1"
```

> Read more about rich push notifications support [here](./Documentation/PUSH.md).

### Carthage

> Carthage will by default build both `ExponeaSDK` and `ExponeaSDKNotifications` frameworks. The latter one is only supposed to be used in a notification service extension if you wish support rich push notifications. Read more about rich push notifications [here](./Documentation/PUSH.md).

```
github "exponea/exponea-ios-sdk" ~> 2.5.1
```

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
* [Payments](./Documentation/PAYMENT.md)
* [Anonymize](./Documentation/ANONYMIZE.md)

## 🔗 Useful links

* [Exponea Developer Hub](https://developers.exponea.com)
* [Exponea App](https://app.exponea.com/login)

## 📝 Release Notes

Release notes can be found [here](./Documentation/RELEASE_NOTES.md).


## 📄 License

**ExponeaSDK** is available under the Apache 2.0 license. See the [LICENSE](https://opensource.org/licenses/Apache-2.0) file for more info.

```
   Copyright 2019 Exponea

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

