## In-app messages
Exponea SDK allows you to display native in-app messages based on definitions set up on Exponea web application. You can find information on how to create your messages in [Exponea documentation](https://docs.exponea.com/docs/in-app-messages).

No developer work is required for in-app messages, they work automatically after the SDK is configured.

### Troubleshooting
As with everything that's supposed works automatically, the biggest problem is what to do when it doesn't. 

#### Logging
The SDK logs a lot of useful information about presenting in-app messages in `verbose` mode. To see why each individual message was/wasn't displayed, set `Exponea.logger.logLevel = .verbose` before configuring the SDK.

#### Displaying in-app messages
In-app messages are triggered when an event is tracked based on conditions setup on Exponea backend. Once a message passes those filters, the SDK will try to present the message in the top-most `presentedViewController` (except for slide-in message that uses `UIWindow` directly). If your application decides to present another UIViewController right at the same time a race condition is created and the message might be displayed and immediately dismissed because it's parent will leave the screen. Keep this in mind if the logs tell you your message was displayed but you don't see it.

> Show on `App load` displays in-app message when a `session_start` event is tracked. If you close and quickly reopen the app, it's possible that the session did not timeout and message won't be displayed. If you use manual session tracking, the message won't be displayed unless you track `session_start` event yourself.
