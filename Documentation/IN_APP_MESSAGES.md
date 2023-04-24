## In-app messages
Exponea SDK allows you to display native in-app messages based on definitions set up on Exponea web application. You can find information on how to create your messages in [Exponea documentation](https://docs.exponea.com/docs/in-app-messages).

No developer work is required for in-app messages, they work automatically after the SDK is configured.

## Troubleshooting
As with everything that's supposed works automatically, the biggest problem is what to do when it doesn't. 

### Logging
The SDK logs a lot of useful information about presenting in-app messages in `verbose` mode. To see why each individual message was/wasn't displayed, set `Exponea.logger.logLevel = .verbose` before configuring the SDK.

### Example logs
Let's look at an example of how the logs may look when displaying an in-app message.
1. ```
    Attempting to show in-app message for event with types ["payment"].
    ```
    An event of type `payment` was tracked, we'll look for a message to display.

2. ```
    In-app message data preloaded, picking a message to display
    ```
    In-app message definitions must be preloaded in order to display the message. If the preload is still in progress, we store the events until preload is complete and perform the message picking logic afterwards.
3. ```
    Picking in-app message for eventTypes ["payment"]. 2 messages available: ["Payment in-app message", "App load in-app message"].
    ```
    This log contains list of **all** message names we received from the server. If you don't see your message here, double check the setup on Exponea web application. Make sure your targeting includes the current customer.
4.  ```
    Message 'App load in-app message' failed event filter. Event: [ExponeaSDK.DataType.properties(["value": ExponeaSDK.JSONValue.string("99")]), ExponeaSDK.DataType.timestamp(nil), ExponeaSDK.DataType.eventType("payment")]. Message filter: {"filter":[],"event_type":"session_start"}
    ```
    We show reasons why some messages are not picked. In this example, message failed event filter - the type was set for `session_start`, but `payment` was tracked.
5. ```
    1 messages available after filtering. Picking highest priority message.
    ```
    After applying all the filters, we have one message left. You can set priority on your messages. The highest priority message should be displayed.
6. ```
    Got 1 messages with highest priority. ["Payment in-app message"]
    ```
    There may be a tie between a few messages with the same priority. In that case we pick one at random.
7. ```
    Attempting to show in-app message 'Payment in-app message'
    ```
    The message picked for displaying was `Payment in-app message`
8. ```
    Will attempt to present in-app message on main thread with delay 0.0.
    ```
    Message display request is posted to the main thread, where it will be displayed in the top-most `presentedViewController`. If a failure happens after this point, please check next section about `Displaying in-app messages`.
9. ```
    In-app message presented.
    ```
    Everything went well and you should see your message. It was presented in the top-most `presentedViewController`. In case you don't see the message, it's possible that the view hierarchy changed and message is no longer on screen.

### Displaying in-app messages
In-app messages are triggered when an event is tracked based on conditions setup on Exponea backend. Once a message passes those filters, the SDK will try to present the message in the top-most `presentedViewController` (except for slide-in message that uses `UIWindow` directly). If your application decides to present another UIViewController right at the same time a race condition is created and the message might be displayed and immediately dismissed because it's parent will leave the screen. Keep this in mind if the logs tell you your message was displayed but you don't see it.

> Show on `App load` displays in-app message when a `session_start` event is tracked. If you close and quickly reopen the app, it's possible that the session did not timeout and message won't be displayed. If you use manual session tracking, the message won't be displayed unless you track `session_start` event yourself.

Message is able to be shown only if it is loaded and also its image is loaded too. In case that message is not yet fully loaded (including its image) then the request-to-show is registered in SDK for that message so SDK will show it after full load.
 Due to prevention of unpredicted behaviour (i.e. image loading takes too long) that request-to-show has timeout of 3 seconds.

 > If message loading hits timeout of 3 seconds then message will be shown on 'next request'. For example the 'session_start' event triggers a showing of message that needs to be fully loaded but it timeouts, then message will not be shown. But it will be ready for next `session_start` event so it will be shown on next 'application run'.

### In-app images caching
To reduce the number of API calls and fetching time of in-app messages, SDK is caching the images displayed in messages. Therefore, once the SDK downloads the image, an image with the same URL may not be downloaded again, and will not change, since it was already cached. For this reason, we recommend always using different URLs for different images.

> Image downloads are limited to 10 seconds per image. If the in-app message contains a large image that cannot be downloaded within this time limit, the in-app message will not be displayed. For an HTML in-app message that contains multiple images, this restriction still applies per image, but failure of any image download will prevent this HTML in-app message from being displayed.

### In-app messages loading
 In-app messages reloading is triggered by any case of:
 - when `Exponea.identifyCustomer` is called
 - when `Exponea.anonymize` is called
 - when any event is tracked (except Push clicked, opened or session ends) and In-app messages cache is older then 30 minutes from last load
 Any In-app message images are preloaded too so message is able to be shown after whole process is finished. Please considers it while testing of In-app feature.
 It is common behaviour that if you change an In-app message data on platform then this change is reflected in SDK after 30 minutes due to usage of messages cache. Do call `Exponea.identifyCustomer` or `Exponea.anonymize` if you want to reflect changes immediately.

### Custom in-app message actions
If you want to override default SDK behavior, when in-app message action is performed (button is clicked, message is closed), or you want to add your code to be performed along with code executed by the SDK, you can set up `inAppMessagesDelegate` on Exponea instance. You will first need to create your own implementation of `InAppMessageActionDelegate`

```swift
class MyInAppDelegate: InAppMessageActionDelegate {
    //If overrideDefaultBehavior is set to true, default in-app action will not be performed ( e.g. deep link )
    let overrideDefaultBehavior: Bool = true
    //If trackActions is set to false, click and close in-app events will not be tracked automatically
    let trackActions: Bool = false

    //This method will be called when in-app message action is performed
    func inAppMessageAction(with message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
       //Here goes your code
       //On in-app click, the button contains button text and button URL and the interaction is true  
       //On in-app close, the button is null, and the interaction is false.
    }
}

```

And then you can setup the delegate:

```swift
Exponea.shared.inAppMessagesDelegate = MyInAppDelegate()
```

If you set `trackActions` to **false** but you still want to track click/close event under some circumstances, you can call Exponea methods `trackInAppMessageClick` or `trackInAppMessageClose` in the `inAppMessageAction` method:

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

Method `trackInAppMessageClose` will track a 'close' event with 'interaction' field of TRUE value by default. You are able to use a optional parameter 'interaction' of this method to override this value.

> The behaviour of `trackInAppMessageClick` and `trackInAppMessageClose` may be affected by the tracking consent feature, which in enabled mode considers the requirement of explicit consent for tracking. Read more in [tracking consent documentation](./TRACKING_CONSENT.md).
