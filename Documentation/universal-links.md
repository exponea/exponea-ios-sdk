---
title: Universal Links
excerpt: Enable and track universal links in your app using the iOS SDK
slug: ios-sdk-universal-links
categorySlug: integrations
parentDocSlug: ios-sdk
---

Universal links allow the links you send through Engagement to open directly in your native mobile application without any redirects that would hinder your users' experience.

For details on how universal links work and how they can improve your users' experience, refer to the [Universal Links](https://documentation.bloomreach.com/engagement/docs/universal-link) section in the Campaigns documentation.

This page describes the steps required to support and track incoming universal links in your app using the iOS SDK.

## Enable Universal Links

To support universal links in your app, you must create a two-way association between your app and your website and specify the URLs that your app handles.

Follow the instructions in [Supporting associated domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains) in the Apple Developer documentation.

- Ensure you have added the [Associated Domains Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_associated-domains) to your application target's `Associated Domains` on the `Signing & Capabilities` tab, for example:
  ```
  applinks:example.com
  webcredentials:example.com
  ```
- Ensure you have set up the `apple-app-site-association` file on your website and that it lists the app identifiers for your domain in the `applinks` service. For example:
  ```
  {
    "applinks": {
      "apps": [],
      "details": [
        {
          "appID": "ABCDE12345.com.example.ExampleApp",
          "paths": [
            "/engagement/*",
            "/*"
          ]
        }
      ]
    }
  }
  ```
  The file must be available on a URL matching the following format.
  ```
  https://<fully qualified domain>/.well-known/apple-app-site-association
  ```

Once the above items are in place, opening universal links should open your app.

> 👍
>
> The easiest way to test the integration is to send yourself an email containing a universal link and open it in your email client in a web browser. Universal links work correctly when a user taps or clicks a link to a different domain. Copy-pasting the URL into Safari doesn't work, neither does following a link to the current domain, or opening the URL with Javascript.

## Track Universal Links

When the system opens your app after a user taps or clicks on a universal link, your app receives an `NSUserActivity` object with an `activityType` value of `NSUserActivityTypeBrowsingWeb`. You must update your app delegate to respond and track the link to the Engagement platform when it receives the `NSUserActivity` object.

The activity object’s `webpageURL` property contains the URL you need to pass on to the SDK’s `.trackCampaignClick()` method.

The code example below shows how to respond to a universal link and track it:

```swift
func application(_ application:UIApplication,
                 continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
        let incomingURL = userActivity.webpageURL
        else { return false }

    Exponea.shared.trackCampaignClick(url: incomingURL, timestamp: nil)
    return true
}
```

> ❗️
>
> If an existing session is resumed by opening a universal link, the resumed session is **NOT** attributed to the universal link click, and the universal link click parameters are not tracked in the `session_start` event. Session behavior is determined by the `automaticSessionTracking` and `sessionTimeout` parameters described in [SDK Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration). Please consider this in case of manual session handling or while testing universal link tracking during the development.

> ❗️
>
> The SDK might not be initialized when `.trackCampaingClick()` is called. In this case, the event will be sent to the Engagement backend **after** the SDK is [initialized](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#initialize-the-sdk) with `Exponea.shared.configure()`. 
