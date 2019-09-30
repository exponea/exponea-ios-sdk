## 🔍 Enabling universal links
The setup process is described in detail in the offical Apple documentation page [Enabling Universal Links](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/enabling_universal_links).

- Ensure you have added the Associated Domains Entitlement to your app in the Capabilities/Associated Domains, e.g.: `applinks:yourdomain.com` and `webcredentials:yourdomain.com`.
- Ensure you have set up the Apple App Site Association file on your website configured properly according to the [Apple’s documentation](https://developer.apple.com/documentation/security/password_autofill/setting_up_an_app_s_associated_domains#3001215).

Once the setup is completed, opening universal link should open your app.

> **NOTE:** Easiest way to test the integration is to send yourself an email containing the Universal link and open it in your email client in web browser. Universal links work correctly when a user taps `<a href="...">` that will drive the user to another domain. Pasting the url into Safari won't work, neither does following the link on the same domain, or opening the url with Javascript.

## 🔍 Tracking universal links
Update your app’s App Delegate to respond to the universal link.

When iOS opens your app as the result of a universal link, your app receives an `NSUserActivity` object with an `activityType` value of `NSUserActivityTypeBrowsingWeb`. The activity object’s `webpageURL` property contains the URL that needs to be passed on to the Exponea SDK’s `.trackCampaignClick()` method.  

#### 💻 Example

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

> **NOTE:** Exponea SDK might not be configured when `.trackCampaingClick()` is called. In this case, the event will be sent to Exponea servers **after** SDK is configured with `Exponea.shared.configure()`. 