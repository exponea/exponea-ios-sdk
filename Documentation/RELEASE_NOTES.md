## Release Notes
## Release Notes for 2.11.1
#### July 06, 2021
* Features
  * The device model property now contains a complete device model name, not only info whether it's iPad or iPhone.
  * Flexible event attributes in mobile push notifications. Custom tracking attributes added into push notification payload are automatically included in the events as properties.
  * Documentation improvements.

* Bug Fixes
  * Fixed: Duplicate tracking of in-app messages close event on X button tap.
  * Fixed: Frameworks not found, when installing via Carthage.
  * Fixed: An in-app message always shown as a modal, regardless of the configuration.
  * Fixed: Event property of list type containing objects not getting tracked.


## Release Notes for 2.11.0
#### April 21, 2021
* Features
  * Added Swift Package Manager support.
  * Push notification events are now chronologically synced (event with status `sent` occurs before event with status `delivered`)
* Bug Fixes
  * Fixed: Configuration of base URL works with and without the trailing slash [Issue #24](https://github.com/exponea/exponea-ios-sdk/issues/24).
  * Fixed: In-app message with A/B testing now correctly handles the control group.


## Release Notes for 2.10.0
#### January 07, 2021
* Features
  * SDK will now hold opened push notifications until `pushNotificationsDelegate` is set.
  * In-app message clicked event now contains property `text` with label of the button that was interacted with.
  * XCode 12.2 and Swift 5.3.1 compatibility.
* Bug Fixes
  * **BREAKING CHANGE:**
  The SDK now processes notification open events that start the application. Before, the app had to running and minimized for the notification to be processed.
  To respond to notifications that start the application, the SDK needs to run some processing in `application:didFinishLaunchingWithOptions`.
  `ExponeaAppDelegate` now implements this method where it processes the notification and sets notification center delegate. Your `AppDelegate application:didFinishLaunchingWithOptions` now requires a `override` keyword and a **call to super** `super.application(application, didFinishLaunchingWithOptions: launchOptions)`. Calling `Exponea.shared.pushNotificationsDelegate = self` is no longer required. See [push notifications documentation](./Guide/PUSH_QUICKSTART.md) for more details.
  * Fixed: Events are now sorted based on timestamp before uploading to Exponea servers.



## Release Notes for 2.9.3
#### November 20, 2020
* Features
  * Updated swiftlint to 0.41.0
  * Documentation improvements
* Bug Fixes
  * Fixed: Carthage build for XCode 12


## Release Notes for 2.9.2
#### October 07, 2020
* Bug Fixes
  * Fixed: Xcode 12 compatibility. Test run was broken, new warnings appeared. Good times.
  * Fixed: Consents fetching issue - consents with null translations caused the request to fail. Translation values are now optional.


## Release Notes for 2.9.1
#### October 06, 2020
* Because of bad push, this release on cocoapods is the same as 2.9.0

## Release Notes for 2.9.0
#### September 09, 2020
* Features
  * Default properties that are tracked with every event can be changed at runtime by setting `Exponea.shared.defaultProperties` property.
  * In-app messages definitions are re-downloaded every time the customer is identified. After customer identification, the set of in-app messages available for the customer may change due to targeting.
* Bug Fixes
  * **BREAKING CHANGE:** The SDK can only be configured once. Reconfiguration of the SDK caused some of the handlers to be registered multiple times which then resulted in automatic events to be tracked multiple times. You should be able to change most of the setting on the fly. To change project tokens, you can use `anonymize()` method (see [ANONYMIZE.md](./ANONYMIZE.md))
  * When a push notification was opened before the SDK was configured(e.g. the app was killed in the background) it was not processed - no event was tracked, action was not resolved. This issue is resolved by saving the “push opening event” until the SDK in configured and tracking/performing action once the SDK is ready.


## Release Notes for 2.8.0
#### August 07, 2020
* Features
  * Support for new in-app message delay and timeout fields soon to be available in Exponea web app.
  * Troubleshooting guide for [In-app messages](IN_APP_MESSAGES.md).
  * **BREAKING CHANGE**: tracking of event properties with array and object type has been overhauled, supporting nesting. The API has changed slightly, but should not affect most developers, since array/object property type is rarely used.
  * Swift 5 added to list of supported swift versions in podspec.
* Bug Fixes
  * Fixed: Push notification registration is now always performed on the main thread.
  * **BREAKING CHANGE**: Only strings are now allowed for customer ids. Exponea would ignore all other types, so this change should not break any functionality, possibly just clean up non-functioning code.
  * Fixed: In-app messages are now stored in Caches directory instead of Documents where users can see them.
  * Fixed: Core Data is now accessed from background thread instead of main thread to prevent blocking the application execution.
  * Fixed: Merge policy has been set on Core Data preventing occasional issues when reporting events.


## Release Notes for 2.7.0
#### July 20, 2020
* Features
  * **DEPRECATION NOTICE**: Automatic push notifications are now deprecated. Please check the [Push notification](./PUSH.md) documentation to see new setup instructions. In most cases, just extending `ExponeaAppDelegate` should be enough. The reason for this change is to remove method swizzling that causes issues when multiple SDKs that handle push notifications are integrated into one application. This way you're more in control of the push notification flow.
  * Silent push notifications support. You're now able to send background updates to your application and respond to them by implementing `silentPushNotificationReceived` method on `PushNotificationManagerDelegate`. Delivery of silent push notifications is tracked to Exponea backend.
  * SDK now supports animated GIFs in push notifications. We advice to keep the images small, official attachment size limit is 10MB, but there is no guarantee.
  * When the application is started from a push notification, resulting session will contain UTM parameters.
  * Updated push notifications documentation and self-check mechanism to make notifications integration easier.


## Release Notes for 2.6.4
#### June 30, 2020
* Features
  * Internal features required for Exponea React Native SDK. Developers using Swift/Objective C can ignore this release completely.


## Release Notes for 2.6.3
#### May 14, 2020
* Bug Fixes
  * Fixed: Properties of ConsentSources and ConsentProperties now have `public` access level.

## Release Notes for 2.6.2
#### May 01, 2020
* Features
  * Switching projects in `anonymize()` method. If you need to switch projects, you can use `anonymize()` method to create a new customer and start fresh tracking into a new project. Please see [ANONYMIZE.md](./ANONYMIZE.md) for more information.
  * Retrieve the cookie of the current customer used for tracking by calling `Exponea.shared.customerCookie`.
  * Improved logging for in-app messages explaining why each message should/shouldn’t be displayed.
* Bug Fixes
  * Fixed: Tracking to multiple projects. It now requires both project token and authorization token. Please see [CONFIG.md](./CONFIG.md) for more information.
  * Removed: Legacy banners implementation that wasn’t working properly.

## Release Notes for 2.6.1
#### March 24, 2020
* Features
  * Push notification delivery is tracked at the time of delivery. Before, the app had to be started again to flush the events to the server.
  * Push notification token is removed from Exponea servers when user changes push notification permission.
* Bug fixes
  * Fixed: Random crash in log reporting.
  * Fixed: Push notification token wasn't tracked in `DAILY` mode.

## Release Notes for 2.6.0
#### March 02, 2020
* Features
  * New in-app messages - display rich messages when app starts or an event is tracked - even when offline. This SDK is fully ready for the feature when it is publicly available soon.
  * The SDK is now able to report the SDK-related crashes to Exponea. This helps us keep the SDK in a good shape and work on fixes as soon as possible.
* Bug fixes
  * Fixed: Browser notification action now always opens the url browser
  * Fixed: Default properties are now added to all events, including system events
  * Removed: Automatic payment tracking was broken and has been removed from the Exponea iOS SDK. In case you're interested in this functionality let us know.

## Release Notes for 2.5.2
#### January 10, 2020
* Bug Fixes
  * Fixed: Fetch recommendations functionality was calling obsolete endpoint. (see [FETCH.md](./FETCH.md))
  * Fixed: Notification image was not displayed when notification did not contain any action buttons.

## Release Notes for 2.5.1
#### December 19, 2019
* Bug Fixes
  * Fixed an issue where anonymize() would fail with automatic push notification tracking enabled on iOS 10

## Release Notes for 2.5.0
#### November 26, 2019
* Features
  * The SDK can now be fully configured also in the code, not only with the configuration file and thus making it more flexible. This new feature is based on https://github.com/exponea/exponea-ios-sdk/issues/10.
* Bug Fixes
  * Fixed: https://github.com/exponea/exponea-ios-sdk/issues/8 - A push notification might have opened the application multiple times if there are multiple SDKs integrated in the application. This shouldn't happen anymore.
  * Fixed: URL link checking is now more robust and handles also incorrectly formatted URL links.

## 2.4.0
#### November 05, 2019
* Features
  * The SDK has a new protective layer for the public API as well as for the interaction with the operating system. It means that in the production setup it prefers to fail silently instead of crashing the whole application.
  * Push notification events now contain more information about campaigns and the action taken and are consistent with Exponea Android SDK.
* Bug Fixes
  * Increased overall code quality by fixing many lint errors. This makes many warnings from the SDK disappear when the application is compiled.
  * The internal mechanisms of the SDK are now really hidden and not usable by the application. It prevents developers from using some undocumented internal part of the SDK in an inappropriate way.
  * Fixed: We fixed a networking issue which cancelled all network requests made by the whole application (not only the SDK) after calling the anonymize() method.
  * Fixed: SDK Initialization now handles database initialization properly. Previously there were some critical errors that could crash the application.
  * There are significant improvements in the unit tests of the SDK.

### 2.3.0
#### September 30, 2019
* Features
	* [Universal link tracking](./UNIVERSAL_LINK.md): SDK can now track app opens from Universal link. Sessions that are started from Universal link contain campaign data.
* Bug Fixes
  * The SDK is now better at handling parallel tasks which lead to nasty crashes in the past.  
  * Fixed: Internal event database thread-safety issues that caused random crashes in previous versions. Database layer only exposes immutable projections of database objects to the outside world. All operations on those objects have to be performed using Database layer itself.
  * Fixed: Event flushing can now only be performed once at a time. Simultaneous calls to `Exponea.shared.flushData()` will only flush data to Exponea once. Flush uses semaphore to ensure that only one thread can perform flushing process.

### 2.2.3
* Configuration now has a token update frequency, which specifies how often should the push token be sent to Exponea (on change, on every start, daily)

### 2.2.2
* Rich push notifications deep link handling mechanism improvements
	- deeplinks which are not a valid URL will not produce a crash on NSUserActivity continuation (eg. MYLINK::HOME:SCREEN:1)

### 2.2.1
* Added option to define default properties (see [FETCH.md](./CONFIG.md))
* Example app updated to use default properties

### 2.2.0
* Added option to fetch consent cateogires (see [FETCH.md](./FETCH.md))
* Raised Swift version to 5.0
* Various small improvements

### 2.1.3
* Improve push notification tracking parameters

### 2.1.2
* Improve push notification tracking parameters
* Handle universal links better when opening them as push actions

### 2.1.1

* Change notification action_type to "mobile notification" for better tracking purposes
* Improve rich push notifications documentation to be explicit about category identifier in content extension

### 2.1.0

* Track additional parameters on automatic push notification clicked tracking
* Add support for tracking push delivered notifications when they are delivered even withou the user opening them, please [see this guide](./PUSH.md) on how to set this up

### 2.0.1

* Fix issues with notification extension when integrating through CocoaPods
	- **Note:** It is now required to add `pod 'ExponeaSDK-Notifications'` to your Podfile instead of the previous `pod 'ExponeaSDK/Notifications'`

### 2.0.0

* Removal of deprecated and unsupported functions
* Documentation improvements
* Support for legacy categories for notification actions
* Better support of dynamic buttons in notification actions in iOS 12+

### 1.2.0-beta5

* Make sure to handle cases where push notification payload does not contain `data` structure

### 1.2.0-beta4

* Add support for rich notification default action on notification tap
* Improve how notification actions (both default and buttons) are parsed and handled

### 1.2.0-beta3

* Fix parsing of button actions
* Make sure notification actions open in foreground

### 1.2.0-beta2

* Fixes for sound not working properly in rich push
* Better campaing data and action info parsing in rich push tracking
* Fix open app action button key for notification service

### 1.2.0-beta1

* Adds support for the new rich push notification feature

### 1.1.8

* Basic authorization and features relying on it (Fetch Events, Fetch Attributes) have been deprecated
* Token authorization has been added and can be now used as for tracking
* Stress unit tests were added
* Issue with creating big amounts of database objects has been fixed

### 1.1.7

* Refactored automatic push notification tracking to support all edge case configurations
* Fix issues when parsing push payload and make sure all parameters related to push are always respected
* Fix crashes related to improper escaping of closures in swizzled push receive methods

### 1.1.6

* Fix issue where timestamp milliseconds were not always respected due to type casting

### 1.1.5

* Improved push handling, prevent crashes caused by swizzling

### 1.1.4

* Minor bugfixes

### 1.1.3

* Improved connection checking
* Fix iOS 12 CoreData scalar type bug with retries

### 1.1.2

* Added better connection handling and flush retrying

### 1.1.1

* Failed requests will now be retried
* Add option to configure the maximum amount of retries (see [Config](./CONFIG.md))
* Documentation improvements

### 1.1.0

* [Anonymize feature](./ANONYMIZE.md)
* Dependencies update
* Crash bugfixes related to CoreData threading
* Various other improvements and bugfixes

### 1.0

Initial release.
