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
