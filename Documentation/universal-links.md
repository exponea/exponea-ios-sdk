---
title: Universal links for iOS SDK
slug: ios-sdk-universal-links
category:
  uri: /branches/2/categories/guides/Developers
parent:
  uri: ios-sdk
content:
  excerpt: Enable and track universal links in your app using the iOS SDK
---

Universal links allow the links you send through {user.mkg} to open directly in your native mobile application without any redirects that would hinder your users' experience.

For details on how universal links work and how they can improve your users' experience, refer to the [Universal links](https://documentation.bloomreach.com/engagement/docs/universal-link) section in the Campaigns documentation.

This page describes the steps required to support and track incoming universal links in your app using the iOS SDK.

## Enable universal links

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

## Track universal links

When the system opens your app after a user taps or clicks on a universal link, your app receives an `NSUserActivity` object with an `activityType` value of `NSUserActivityTypeBrowsingWeb`. You must forward that activity to the SDK so campaign clicks are tracked in {user.mkg}.

The activity object's `webpageURL` property contains the URL passed to campaign-click tracking.

### UIScene lifecycle (recommended for iOS 27+)

If your app uses `UIApplicationSceneManifest`, UIKit delivers universal links to your `SceneDelegate`, not `AppDelegate.application(_:continue:restorationHandler:)`.

Subclass `ExponeaSceneDelegate` in your scene delegate and call `super` from the scene lifecycle methods:

```swift
import ExponeaSDK

class SceneDelegate: ExponeaSceneDelegate {
    var window: UIWindow?

    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        // cold launch: connectionOptions.userActivities
    }

    override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        super.scene(scene, continue: userActivity)
        // warm launch
    }
}
```

For a fully custom `SceneDelegate`, forward universal links manually:

```swift
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    Exponea.shared.handleUniversalLink(userActivity)
}

func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
) {
    if let activity = connectionOptions.userActivities.first(where: {
        $0.activityType == NSUserActivityTypeBrowsingWeb
    }) {
        Exponea.shared.handleUniversalLink(activity)
    }
}
```

> ❗️
>
> If your custom `SceneDelegate` implements `scene(_:continue:)` for reasons unrelated to the SDK (for example, Handoff or Shortcuts), it must still explicitly call `Exponea.shared.handleUniversalLink(_:)` (or `trackCampaignClick(url:timestamp:)`). The SDK's in-app deeplink handling (`UrlOpener`) can only detect whether your scene delegate implements `scene(_:continue:)` — it can't verify that the implementation forwards to the SDK. 
>
> If your implementation doesn't forward, this affects SDK-initiated deeplinks only (in-app messages, in-app content blocks). The campaign click isn't tracked, and the link itself silently fails to open for that scene: `UrlOpener` treats the scene as having already handled the link and doesn't fall back to opening the URL. 
>
> Real, system-delivered universal links (tapped from Notes, Messages, or Safari) aren't affected, since UIKit always dispatches those directly to your real `SceneDelegate`.

### Legacy AppDelegate lifecycle

If your app **doesn't** use `UIApplicationSceneManifest`, handle universal links in `AppDelegate`:

```swift
func application(_ application: UIApplication,
                 continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard Exponea.shared.handleUniversalLink(userActivity) else { return false }
    // process the universal link and return true once it has been processed
    return true
}
```

You can also call `Exponea.shared.trackCampaignClick(url:timestamp:)` directly if you already extracted `userActivity.webpageURL`.

Universal Link parameters are automatically tracked in `session_start` events when a new session is started for a given Universal Link click. If the URL contains a parameter `xnpe_cmp` then an additional `campaign` event is tracked. The parameter `xnpe_cmp` represents a campaign identifier typically generated for Email or SMS campaigns. 

> ❗️
>
> If an existing session is resumed by opening a universal link, the resumed session is **NOT** attributed to the universal link click, and the universal link click parameters are not tracked in the `session_start` event. Session behavior is determined by the `automaticSessionTracking` and `sessionTimeout` parameters described in [Configuration for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration). Please consider this in case of manual session handling or while testing universal link tracking during the development.

> ❗️
>
> The SDK might not be initialized when `.trackCampaignClick()` is called. In this case, the event will be sent to the {user.mkg} backend **after** the SDK is [initialized](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#initialize-the-sdk) with `Exponea.shared.configure()`. 
