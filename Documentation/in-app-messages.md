---
title: In-app messages for iOS SDK
slug: ios-sdk-in-app-messages
category:
  uri: /branches/2/categories/guides/Developers
parent:
  uri: ios-sdk-in-app-personalization
content:
  excerpt: >-
    Display native in-app messages based on definitions set up in Marketing
    using the iOS SDK
---

The SDK enables you to display native in-app messages in your app based on definitions set up in {user.mkg}. 

In-app messages work out-of-the-box once the [Initial setup for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup) is complete in your app; no development work is required. However, you can customize the behavior to meet your specific requirements.

> 📘
>
> Refer to the [In-app messages](https://documentation.bloomreach.com/engagement/docs/in-app-messages) user guide for instructions on how to create in-app messages in the {user.mkg} web app.
> Also see [In-app messages FAQ](https://support.bloomreach.com/hc/en-us/articles/18152718785437-In-App-Messages-FAQ) at {user.br} Support Help Center.

## Tracking

The SDK automatically tracks `banner` events for in-app messages with the following values for the `action` event property:

- `show`
  In-app message displayed to user.
- `click`
  User clicked on action button inside in-app message. The event also contains the corresponding `text` and `link` properties.
- `close`
  User clicked on close button inside in-app message or in-app message has been automatically closed by delay. The event also contains the corresponding `text` property if close button with label has been clicked.
- `error`
  Displaying in-app message failed. The event contains an `error` property with an error message.

> ❗️
>
> The behavior of in-app message tracking may be affected by the tracking consent feature, which in enabled mode requires explicit consent for tracking. Refer to the [Tracking consent for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) documentation for details.


## Customization

### Customize in-app message actions

You can override the SDK's default behavior when an in-app message action (click button or close message) is performed by setting `inAppMessagesDelegate` on the `Exponea` instance.

First, create your own implementation of `InAppMessageActionDelegate`:

```swift
class MyInAppDelegate: InAppMessageActionDelegate {
    // If overrideDefaultBehavior is set to true, default in-app action isn't performed ( e.g. deep link )
    let overrideDefaultBehavior: Bool = true

    // If trackActions is set to false, click and close in-app events isn't tracked automatically
    let trackActions: Bool = false

    // This method will be called when an in-app message action is performed
    func inAppMessageClickAction(message: InAppMessage, button: InAppMessageButton) {
       // Here goes your code  
       // Method called when action button has been clicked by user.
       // The button contains button text and button URL
    }

    // This method will be called when an in-app message is closed
    func inAppMessageCloseAction(message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
        // Here goes your code
        // Method called when in-app message has been closed.
        // On in-app close by click on CANCEL button:
        //  - the `button` isn't null
        //  - the `button` contains button text
        //  - the `interaction` is true
        // On in-app close with default interaction by user (close button, dismiss, etc...):
        //  - the `button` is null
        //  - the `interaction` is true
        // On in-app close without interaction by user (in-app message timeout)
        //  - the `button` is null
        //  - the `interaction` is false
    }

    // Method called when in-app message is shown.
    func inAppMessageShown(message: ExponeaSDK.InAppMessage) {
        // Here goes your code
    }

    // Method called when any error occurs while showing in-app message.
    func inAppMessageError(message: ExponeaSDK.InAppMessage?, errorMessage: String) {
        // Here goes your code
        // In-app message could be NULL if error isn't related to in-app message.
    }
}

```

Then set the delegate:

```swift
Exponea.shared.inAppMessagesDelegate = MyInAppDelegate()
```

If you set `trackActions` to `false` but you still want to track click or close events under some circumstances, you can call the methods `trackInAppMessageClick` or `trackInAppMessageClose` in the action methods:

```swift
func inAppMessageClickAction(message: InAppMessage, button: InAppMessageButton) {
    if <your-special-condition>  { 
        Exponea.shared.trackInAppMessageClick(message: message, buttonText: button.text, buttonLink: button.url)
    } 
}

func inAppMessageCloseAction(message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
    if <your-special-condition>  { 
        Exponea.shared.trackInAppMessageClose(message: message, buttonText: button?.text, isUserInteraction: interaction)
    } 
}
```

The method `trackInAppMessageClose` will track a `close` event with the `interaction` property value `true` by default. Use the optional parameter `interaction` of this method to override this value.

> ❗️
>
> The behaviour of `trackInAppMessageClick` and `trackInAppMessageClose` may be affected by the tracking consent feature, which in enabled mode requires explicit consent for tracking. Refer to the [Tracking consent for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) documentation for details.

### Override button action type in HTML message

The SDK automatically processes button action URLs as follows:

* If the URL starts with `http` or `https`, the action type is set to `browser`.
* In all other cases, the action type is set to `deep-link`.

It's possible to override this behavior by explicitly specifying the optional attribute `data-actiontype` with one of the following values:

* `browser` - web URL, to be opened in a browser
* `deep-link` - custom URL scheme or Universal Link, to be processed by the app accordingly

You can do this in the HTML builder by inserting the `data-actiontype` attribute as in the example below:

```html
<div class="bee-block bee-block-4 bee-button">
   <div data-link="https://example.com" data-actiontype="browser" style="font-size: 14px; background-color: #f84cac; border-bottom: 0px solid transparent; border-left: 0px solid transparent; border-radius: 4px; border-right: 0px solid transparent; border-top: 0px solid transparent; color: #ffffff; direction: ltr; font-family: inherit; font-weight: 700; max-width: 100%; padding-bottom: 4px; padding-left: 18px; padding-right: 18px; padding-top: 4px; width: auto; display: inline-block;" class="bee-button-content"><span style="word-break: break-word; font-size: 14px; line-height: 200%;">Action</span></div>
</div>
```

The SDK also supports the `data-actiontype` attribute in `<a>` elements for compatibility with the Visual Builder:

```html
<div class="bee-block bee-block-4 bee-button">
   <a data-link="https://example.com" data-actiontype="deep-link">Click me</a>
</div>
```

In the Visual Builder, you can set the action type as follows:

1) In the preview, select the button you want to override the action type for
2) In the editor on the right side, scroll down to the `Attributes` section
3) Click on `ADD NEW ATTRIBUTE`
4) Select `data-actiontype`
5) Insert a value (either `browser` or  `deep-link`)

![Screenshot](https://raw.githubusercontent.com/exponea/exponea-ios-sdk/main/Documentation/images/actiontype.png)

## Troubleshooting

This section provides helpful pointers for troubleshooting in-app message issues.

> 👍 Enable Verbose Logging
> The SDK logs a lot of information in verbose mode while loading in-app messages. When troubleshooting in-app message issues, first ensure to [set the SDK's log level](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#log-level) to `.verbose`.

### In-app message not displayed

When troubleshooting why an in-app message didn't display on your device, always first make sure that the in-app message was preloaded to the device, then troubleshoot message display.

#### Troubleshoot in-app messages preloading issues

- The SDK requests in-app messages from the {user.mkg} platform any time one of the following occurs:
  - `Exponea.identifyCustomer` is called
  - `Exponea.anonymize` is called
  - Any event (except push notification clicked or opened, or session ends) is tracked **and** the in-app messages cache is older then 30 minutes
- The SDK should subsequently receive a response from the {user.mkg} platform containing all available in-app messages targeted at the current customer. The SDK preload these messages in a local cache.
- If you create or modify an in-app message in {user.mkg}, typically any changes you made are reflected in the SDK after 30 minutes due to the in-app messages being cached. Call `Exponea.identifyCustomer` or `Exponea.anonymize` to trigger reloading so changes are reflected immediately.
- Analyze the [log messages](#log-messages) (especially examples 3-6) to determine whether the SDK is requesting and receiving in-app messages and your message was preloaded.
- If the SDK is requesting and receiving in-app messages but your message isn't preloaded:
  - The local cache may be outdated. Wait for or trigger the next preload.
  - The current customer may not match the audience targeted by the in-app message. Verify the message's audience in {user.mkg}.

> ❗️
>
> Invoking `Exponea.anonymize` triggers fetching in-app messages immediately but `Exponea.identifyCustomer` needs to be flushed to the backend successfully first. This is because the backend must know the customer so it can assign the in-app messages with matching audience. If you have set `Exponea.flushMode` to anything other then `FlushMode.IMMEDIATE`, you must call `Exponea.flushData()` to finalize the `identifyCustomer` process and trigger an in-app messages fetch.

#### Troubleshoot in-app message display issues

If your app is successfully requesting and receiving in-app messages but they aren't displayed, consider the following:

- In-app messages are triggered when an event is tracked based on conditions set up in {user.mkg}. Once a message passes those filters, the SDK will try to present the message in the top-most `presentedViewController` (except for slide-in messages that use `UIWindow` directly).
  It's possible that your application decides to present another `UIViewController` right at the same time, creating a race condition. In this case, the message might be displayed and immediately dismissed because its parent leaves the screen. Keep this in mind if the [logs](#log-messages) tell you your message was displayed but you don't see it.

- In-app messages configured to show on `App load` display when a `session_start` event is tracked. If you close and quickly reopen the app, the session may not have timed out, so the message won't show. With manual session tracking, the message only displays if you track `session_start` yourself. Tracking it from `applicationDidBecomeActive` (as recommended, see [Track session manually](tracking.md#track-session-manually)) reliably triggers the message once the app is in the foreground, even at the very start of that callback.

- An in-app message can only be displayed if it is loaded, including its images. If the message isn't yet fully loaded, the SDK registers a request-to-show for that message so it will be displayed once it is fully loaded. The request-to-show has a timeout of 3 seconds. This means that in case of unpredicted behavior, such as image loading taking too long, the message may not be displayed directly.

- If in-app message loading hits the timeout of 3 seconds, the message will be displayed the next time its trigger event is tracked. For example, if a `session_start` event triggers an in-app message but loading that message times out, it isn't displayed directly. However, once loaded, it will display the next time a `session_start` event is tracked.

- Image downloads are limited to 10 seconds per image. If an in-app message contains a large image that can't be downloaded within this time limit, the in-app message isn't displayed. For an HTML in-app message that contains multiple images, this restriction applies per image, but failure of any image download will prevent this HTML in-app message from being displayed.

### In-app message shows incorrect image

- To reduce the number of API calls and fetching time of in-app messages, the SDK caches the images contained in messages. Once the SDK downloads an image, an image with the same URL may not be downloaded again. If a message contains a new image with the same URL as a previously used image, the previous image is displayed since it was already cached. For this reason, we recommend always using different URLs for different images.

### In-app message actions not tracked

- If you have implemented a custom `InAppMessageActionDelegate`, actions are only tracked automatically if `trackActions` is set to `true`. If `trackActions` is set to `false`, you must manually track the action in the `inAppMessageAction` method. Refer to [Customize In-App Message Actions](#customize-in-app-message-actions) above for details.

### Close button doesn't match the Visual Builder preview

Earlier iOS SDK versions applied hardcoded padding to the title and body text in rich-style in-app messages (modal, fullscreen, and slide-in) to prevent the close button from overlapping content. This padding varied by layout, so it didn't always match the Visual Builder preview or how the message rendered on Android.

- **Fix:** as of iOS SDK 4.3.0, the close button is positioned consistently at the top-right of the message container, offset only by its `Distance from top` and `Distance from right` settings. iOS rendering now matches the Visual Builder preview and Android.
- **Action:** after updating to SDK 4.3.0, check existing rich-style campaigns for padding added to compensate for the old positioning, for example, extra top padding on the title or body. Remove or adjust that padding in the Visual Builder — most campaigns look correct without it.

This fix applies only to rich-style in-app messages built with the native rich editor. It doesn't affect the legacy native editor or HTML-based in-app messages.

### Log messages

> Note
> 
> All logs assigned to In-app handling process are prefixed with `[InApp]` shortcut to bring easier search-ability to you. Bear in mind that some supporting processes (such as Image caching) are logging without this prefix. 

While troubleshooting in-app message issues, you can follow the process of requesting, receiving, preloading, and displaying in-app messages through the information logged by the SDK at verbose log level. Look for messages similar to the ones below:

1. ```
   Event {eventCategory}:{eventType} occurred, going to trigger In-app show process
   ```
   In-app process has been triggered by SDK usage of identifyCustomer() or event tracking.
2. ```
   Register request for in-app message to be shown for $eventType
   ```
   This request is registered for events other than `identifyCustomer` — an `identifyCustomer` event always downloads in-app messages from the backend.
3. ```
   Skipping messages process for {event} because app isn't in foreground state
   ```
   The in-app message process was triggered while application UI isn't visible to user therefore no in-app message could be shown anyway.
4. ```
   Picking in-app message for eventType {eventType}. {X} messages available: [{message1 name}, {message2 name}, ...].
   ```
   In-app messages must be preloaded before they can be displayed. If the preload hasn't started or is still in progress, the SDK will wait until the preload is complete and only perform the logic to select an in-app message afterward. This log contains the `eventType` for which messages are being searched, followed by the count of `X` messages and the names of **all** messages received from the server.
5. ```
   Message '{message name}' failed event filter. Message filter: {"event_type":"session_start","filter":[]} Event type: payment properties: {price=2011.1, product_title=Item #1} timestamp: 1.59921557821E9
   ```
   We show reasons why some messages aren't picked. In this example, message failed event filter - the type was set for `session_start`, but `payment` was tracked.
6. ```
   Got {X} messages with highest priority for eventType {eventType}. [{message1 name}, {message2 name}, ...]
   ```
   There may be a tie between a few messages with the same priority. All messages with same highest priority are listed.
7. ```
   Picking top message '{message name}' for eventType {eventType}
   ```
   The single message is randomly picked from filtered messages with same highest priority for `eventType`.
8. ```
   Picking in-app message for eventTypes ["payment"]. 2 messages available: ["Payment in-app message", "App load in-app message"].
   ```
   This log message includes a list of **all** in-app messages received from the server and preloaded in the local cache. If you don't see your message here, it's possible it wasn't available yet the last time the SDK requested in-app messages. If you have confirmed the message was available when the last preload occurred, the current user may not match the audience targeted by the in-app message. Check the in-app message set up in {user.mkg}.
9. ```
   Got {X} messages available to show. [{message1 name}, {message2 name}, ...].
   ```
   All `X` messages have been collected for registered 'show requests'. Process continues with selecting of message with highest priority.
10. ```
    1 messages available after filtering. Picking highest priority message.
    ```
    After applying all the filters, there is one in-app message left that satisfies the criteria to be displayed. If more than one message is eligible, the SDK will select the one that has the highest priority configured in {user.mkg}.
11. ```
    Picking top message '{message name}' to be shown.
    ```
    The single message is randomly picked from all filtered messages. This message is going to be shown to the user.
12. ```
    Only logging in-app message for control group '${message.name}'
    ```
    A/B testing In-app message or message without payload isn't shown to user but 'show' event is tracked for your analysis.
13. ```
    Attempting to show in-app message '{message name}'
    ```
    In-app message that is meant to be shown to the user (not A/B testing) is going to be shown.
14. ```
    Posting show to main thread with delay {X}ms.
    ```
    Message display request is posted to the main thread with a delay of `X` milliseconds. Delay is configured by `Display delay` in the in-app message settings. The message will be displayed in the topmost presented view controller.
