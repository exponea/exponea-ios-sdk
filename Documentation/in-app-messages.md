---
title: In-App Messages
excerpt: Display native in-app messages based on definitions set up in Engagement using the iOS SDK
slug: ios-sdk-in-app-messages
categorySlug: integrations
parentDocSlug: ios-sdk-in-app-personalization
---

The SDK enables you to display native in-app messages in your app based on definitions set up in Engagement. 

In-app messages work out-of-the-box once the [SDK is installed and configured](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup) in your app; no development work is required. However, you can customize the behavior to meet your specific requirements.

> 📘
>
> Refer to the [In-App Messages](https://documentation.bloomreach.com/engagement/docs/in-app-messages) user guide for instructions on how to create in-app messages in the Engagement web app.

## Tracking

The SDK automatically tracks `banner` events for in-app messages with the following values for the `action` event property:

- `show`
  In-app message displayed to user.
- `click`
  User clicked on action button inside in-app message. The event also contains the corresponding `text` and `link` properties.
- `close`
  User clicked on close button inside in-app message.
- `error`
  Displaying in-app message failed. The event contains an `error` property with an error message.

> ❗️
>
> The behavior of in-app message tracking may be affected by the tracking consent feature, which in enabled mode requires explicit consent for tracking. Refer to the [consent documentation](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) documentation for details.


## Customization

### Customize In-App Message Actions

You can override the SDK's default behavior when an in-app message action (click button or close message) is performed by setting `inAppMessagesDelegate` on the `Exponea` instance.

First, create your own implementation of `InAppMessageActionDelegate`:

```swift
class MyInAppDelegate: InAppMessageActionDelegate {
    // If overrideDefaultBehavior is set to true, default in-app action will not be performed ( e.g. deep link )
    let overrideDefaultBehavior: Bool = true

    // If trackActions is set to false, click and close in-app events will not be tracked automatically
    let trackActions: Bool = false

    // This method will be called when an in-app message action is performed
    func inAppMessageAction(with message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
       // Here goes your code
       // On in-app click, the button contains button text and button URL and the interaction is true  
       // On in-app close, the button is null, and the interaction is false.
    }

    // Method called when in-app message is shown.
    func inAppMessageShown(message: ExponeaSDK.InAppMessage) {
        // Here goes your code
    }

    // Method called when any error occurs while showing in-app message.
    func inAppMessageError(message: ExponeaSDK.InAppMessage?, errorMessage: String) {
        // Here goes your code
        // In-app message could be NULL if error is not related to in-app message.
    }
}

```

Then set the delegate:

```swift
Exponea.shared.inAppMessagesDelegate = MyInAppDelegate()
```

If you set `trackActions` to `false` but you still want to track click or close events under some circumstances, you can call the methods `trackInAppMessageClick` or `trackInAppMessageClose` in the `inAppMessageAction` method:

```swift
func inAppMessageAction(with message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
    if <your-special-condition>  { 
        if interaction {
            Exponea.shared.trackInAppMessageClick(message: message, buttonText: button?.text, buttonLink: button?.url)
        } else {
            Exponea.shared.trackInAppMessageClose(message: message)
        }
    } 
}
```

The method `trackInAppMessageClose` will track a `close` event with the `interaction` property value `true` by default. Use the optional parameter `interaction` of this method to override this value.

> ❗️
>
> The behaviour of `trackInAppMessageClick` and `trackInAppMessageClose` may be affected by the tracking consent feature, which in enabled mode requires explicit consent for tracking. Refer to the [Tracking Consent](https://documentation.bloomreach.com/engagement/docs/ios-sdk-tracking-consent) documentation for details.

### Override Button Action Type in HTML Message

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

The SDK also supports the `data-actiontype` attribute in `<a>` elements for compatibility with the Visual builder:

```html
<div class="bee-block bee-block-4 bee-button">
   <a data-link="https://example.com" data-actiontype="deep-link">Click me</a>
</div>
```

In the Visual builder, you can set the action type as follows:

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

### In-App Message Not Displayed

When troubleshooting why an in-app message did not display on your device, always first make sure that the in-app message was preloaded to the device, then troubleshoot message display.

#### Troubleshoot In-App Messages Preloading Issues

- The SDK requests in-app messages from the Engagement platform any time one of the following occurs:
  - `Exponea.identifyCustomer` is called
  - `Exponea.anonymize` is called
  - Any event (except push notification clicked or opened, or session ends) is tracked **and** the in-app messages cache is older then 30 minutes
- The SDK should subsequently receive a response from the Engagement platform containing all available in-app messages targeted at the current customer. The SDK preload these messages in a local cache.
- If you create or modify an in-app message in Engagement, typically any changes you made are reflected in the SDK after 30 minutes due to the in-app messages being cached. Call `Exponea.identifyCustomer` or `Exponea.anonymize` to trigger reloading so changes are reflected immediately.
- Analyze the [log messages](#log-messages) (especially examples 2-5) to determine whether the SDK is requesting and receiving in-app messages and your message was preloaded.
- If the SDK is requesting and receiving in-app messages but your message is not preloaded:
  - The local cache may be outdated. Wait for or trigger the next preload.
  - The current customer may not match the audience targeted by the in-app message. Verify the message's audience in Engagement.

> ❗️
>
> Invoking `Exponea.anonymize` triggers fetching in-app messages immediately but `Exponea.identifyCustomer` needs to be flushed to the backend successfully first. This is because the backend must know the customer so it can assign the in-app messages with matching audience. If you have set `Exponea.flushMode` to anything other then `FlushMode.IMMEDIATE`, you must call `Exponea.flushData()` to finalize the `identifyCustomer` process and trigger an in-app messages fetch.

#### Troubleshoot In-App Message Display Issues

If your app is successfully requesting and receiving in-app messages but they are not displayed, consider the following:

- In-app messages are triggered when an event is tracked based on conditions set up in Engagement. Once a message passes those filters, the SDK will try to present the message in the top-most `presentedViewController` (except for slide-in messages that use `UIWindow` directly).
  It's possible that your application decides to present another `UIViewController` right at the same time, creating a race condition. In this case, the message might be displayed and immediately dismissed because its parent leaves the screen. Keep this in mind if the [logs](#log-messages) tell you your message was displayed but you don't see it.

- In-app messages configured to show on `App load` are displayed when a `session_start` event is tracked. If you close and quickly reopen the app, it's possible that the session did not time out and the message won't be displayed. If you use manual session tracking, the message won't be displayed unless you track a `session_start` event yourself.

- An in-app message can only be displayed if it is loaded, including its images. If the message is not yet fully loaded, the SDK registers a request-to-show for that message so it will be displayed once it is fully loaded. The request-to-show has a timeout of 3 seconds. This means that in case of unpredicted behavior, such as image loading taking too long, the message may not be displayed directly.

- If in-app message loading hits the timeout of 3 seconds, the message will be displayed the next time its trigger event is tracked. For example, if a `session_start` event triggers an in-app message but loading that message times out, it will not be displayed directly. However, once loaded, it will display the next time a `session_start` event is tracked.

- Image downloads are limited to 10 seconds per image. If an in-app message contains a large image that cannot be downloaded within this time limit, the in-app message will not be displayed. For an HTML in-app message that contains multiple images, this restriction applies per image, but failure of any image download will prevent this HTML in-app message from being displayed.

### In-App Message Shows Incorrect Image

- To reduce the number of API calls and fetching time of in-app messages, the SDK caches the images contained in messages. Once the SDK downloads an image, an image with the same URL may not be downloaded again. If a message contains a new image with the same URL as a previously used image, the previous image is displayed since it was already cached. For this reason, we recommend always using different URLs for different images.

### In-App Message Actions Not Tracked

- If you have implemented a custom `InAppMessageActionDelegate`, actions are only tracked automatically if `trackActions` is set to `true`. If `trackActions` is set to `false`, you must manually track the action in the `inAppMessageAction` method. Refer to [Customize In-App Message Actions](#customize-in-app-message-actions) above for details.

### Log Messages

> Note: All logs assigned to In-app handling process are prefixed with `[InApp]` shortcut to bring easier search-ability to you. Bear in mind that some supporting processes (such as Image caching) are logging without this prefix. 

While troubleshooting in-app message issues, you can follow the process of requesting, receiving, preloading, and displaying in-app messages through the information logged by the SDK at verbose log level. Look for messages similar to the ones below:

1. ```
   Event {eventCategory}:{eventType} occurred, going to trigger In-app show process
   ```
   In-app process has been triggered by SDK usage of identifyCustomer() or event tracking.
   ```
   Register request for in-app message to be shown for $eventType (not for identifyCustomer). Identify customer event will always download in app messages from backend.
2. ```
   Picking in-app message for eventType {eventType}. {X} messages available: [{message1 name}, {message2 name}, ...].
   ```
   In-app messages must be preloaded before they can be displayed. If the preload hasn't started or is still in progress, the SDK will wait until the preload is complete and only perform the logic to select an in-app message afterward.
   ```
3. ```
   This log contains `eventType` for which the messages going to be searched. Then count of `X` messages and the names of **all** messages received from the server is listed in
   ```   
   Message '{message name}' failed event filter. Message filter: {"event_type":"session_start","filter":[]} Event type: payment properties: {price=2011.1, product_title=Item #1} timestamp: 1.59921557821E9
   ```  
   We show reasons why some messages are not picked. In this example, message failed event filter - the type was set for `session_start`, but `payment` was tracked.
   ```
4. ``` 
   Got {X} messages with highest priority for eventType {eventType}. [{message1 name}, {message2 name}, ...]
   ```
   There may be a tie between a few messages with the same priority. All messages with same highest priority are listed.
   ```
5. ``` 
   Picking top message '{message name}' for eventType {eventType}
   ```
   The single message is randomly picked from filtered messages with same highest priority for `eventType`
   ```
6. ```
   Picking in-app message for eventTypes ["payment"]. 2 messages available: ["Payment in-app message", "App load in-app message"].
   ```
   This log message includes a list of **all** in-app messages received from the server and preloaded in the local cache. If you don't see your message here, it's possible it wasn't available yet the last time the SDK request in-app messages. If you have confirmed the message was available when the last preload occurred, the current user may not match the audience targeted by the in-app message. Check the in-app message set up in Engagement. 
7.  ```
   Got {X} messages available to show. [{message1 name}, {message2 name}, ...].
   ```
   All `X` messages has been collected for registered 'show requests'. Process continues with selecting of message with highest priority.
   ```
8. ```
    1 messages available after filtering. Picking highest priority message.
    ```
    After applying all the filters, there is one in-app message left that satisfies the criteria to be displayed. If more than one messages is eligible, the SDK will select the one that has the highest priority configured in Engagement.
    ```
9. ```
   Picking top message '{message name}' to be shown.
   ```
   The single message is randomly picked from all filtered messages. This message is going to be shown to user.
   ```
10. ```
   Only logging in-app message for control group '${message.name}'
   ```
   A/B testing In-app message or message without payload is not shown to user but 'show' event is tracked for your analysis.
   ```
11. ```
   Attempting to show in-app message '{message name}'
   ```
   In-app message that meant to be show to user (not A/B testing) is going to be shown
   ```
12. ```
   Posting show to main thread with delay {X}ms.
   ```
   Message display request is posted to the main thread with delay of `X` milliseconds. Delay is configured by `Display delay` in In-app message settings. Message will be displayed in the last resumed Activity. 
