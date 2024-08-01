---
title: Release Notes
excerpt: Exponea iOS SDK Release Notes
slug: ios-sdk-release-notes
categorySlug: integrations
parentDocSlug: ios-sdk
---

## Release Notes
## Release Notes for 2.28.0
#### August 01, 2024
* Features
  * ContentBlockCarouselCallback extended with additional callback methods.
  * Adds an improvement ensuring that In-App Messages are only fetched while the app is in the foreground.
  * InAppContentBlock.Content struct exposed to have public constructor.
  * PersonalizedInAppContentBlockResponse struct exposed to have public constructor.
  * Tracking of campaign/clicks event updated only for cases when xnpe_cmp is present, described more deeply in documentation.
  * AppInboxListViewController extended with onItemClicked callback.
  * Carousel documentation updated.
* Bug Fixes
  * Fixed: InAppContentBlock deserialisation now able to handle NIL.
  * Fixed: Crash caused by calling track events for not configured SDK from multiple threads fixed by adding atomicity to actionBlocks array in ExpoInitManager.
  * Fixed: Carousel timer inconsistency for next message after resuming from action.
  * Fixed: Duplicity of App Inbox event_type in events - removed from show/click/etc. event.
  * Fixed: Missing UTM params added for HTML App Inbox message markAsRead and trackOpen.
  * Fixed: Possible runtime crash caused by not initialised Tracking manager fixed.


## Release Notes for 2.27.1
#### July 01, 2024
* Fixed:
  * Fixes an issue with wrong minimal iOS version (11 instead of 13 as should be) for SPM causing build error


## Release Notes for 2.27.0
#### June 27, 2024
* Added:
  * Adds support for multiple In-App Content Blocks in the same placeholder through `InAppContentBlockCarouselView`. The SDK will loop through the content blocks one at a time in order of the configured Priority.
  * Adds `inAppMessageShown` and `inAppMessageError` methods to `InAppMessageCallback` to improve support for customized In-App Message behavior.
  * Increases the minimum required iOS version to 13.
  * Adds support for newer Swift versions in Podspec.
* Fixed:
  * Fixes an issue where iPhone 15 devices would not be recognized in tracked events.
  * Fixes a broken README link and outdated info in the Podspec.


## Release Notes for 2.26.2
#### June 19, 2024
* Features
  * Segmentation API documentation improvements
* Bug Fixes
  * Fixed: SDK Privacy manifest value is assigned under wrong key
  * Fixed: App Inbox HTML message ignore data-actiontype parameter for action URL
  * Fixed: In-app content block filtration flag and filter out valid messages without image as images with corrupted image


## Release Notes for 2.26.1
#### May 03, 2024
* Bug Fixes
  * Fixed: In-app content block track dual show event
  * Fixed: In-app message dismiss callback is not called in some specific case
  * Fixed: Generic view in-app content block has default padding on the bottom


## Release Notes for 2.26.0
#### April 26, 2024
* Features
  * Segmentation API feature support


## Release Notes for 2.25.3
#### April 19, 2024
* Bug Fixes
  * Fixed: In-app content blocks ignores handleUrlClick because of nil message state
  * Fixed: In-app content block with not successfully loaded image is shown
  * Fixed: App Inbox HTML message ignore action type
  * Fixed: In-app content blocks logging in debug verbose mode slowing down the app and cause glitching


## Release Notes for 2.25.2
#### April 10, 2024
* Bug Fixes
  * Fixed: SDK Privacy manifest file is not linked correctly for SPM usage


## Release Notes for 2.25.1
#### April 09, 2024
* Bug Fixes
  * Fixed: SDK Privacy manifest file is not linked correctly in bundle


## Release Notes for 2.25.0
#### April 05, 2024
* Features
  * In-app message load refactoring (show on the first load etc.)
  * Logging for In-app content blocks is extended
  * Privacy manifest added
* Bug Fixes
  * Fixed: Some of variables missing self so it is not possible to compile SDK with XCode 14.2
  * Fixed: Documentation contain invalid URLs and not correct info about default session timeout duration
  * Fixed: App Inbox provider setter disable AppInboxButton so it is not possible to click on it


## Release Notes for 2.24.0
#### March 20, 2024
* Features
  * Introducing SDK documentation 2.0
* Bug Fixes
  * Fixed: SDK notifies initialization finish prematurely and causes ignoring of postponed SDK API methods


## Release Notes for 2.23.0
#### February 15, 2024
* Features
  * App Inbox addSubviews from UIView are now internal
  * In-app messages docu extended describing events and consent more deeply
* Bug Fixes
  * Fixed: Calling anonymize not saving configuration to User Defaults
  * Fixed: Stored unprocessed PUSH events not storing and loading proper configuration in some cases
  * Fixed: PUSH setup docu missing step of setting APNS integration in channels part


## Release Notes for 2.22.0
#### February 02, 2024
* Features
  * New optional data-actiontype attribute added for HTML messages
* Bug Fixes
  * Fixed: In-app content block tracks error for each URL change also for about:blank


## Release Notes for 2.21.3
#### January 11, 2024
* Bug Fixes
  * Fixed: Invoking of In-app content blocks behaviour callback from outside is not reflected to local flags about showing and interaction


## Release Notes for 2.21.2
#### December 23, 2023
* Bug Fixes
  * Fixed: Using of HtmlNormalizer is not available as public, and able to normalization process can not be set


## Release Notes for 2.21.1
#### December 21, 2023
* Features
  * More detailed logging added to In-app content blocks
* Bug Fixes
  * Removed: Explicitly defined arm7 and arm7s arch is causing problem during build
  * Fixed: In-app content block tableView has been shown and tracked for bad placeholderID value


## Release Notes for 2.21.0
#### December 18, 2023
* Features
  * In-app content blocks behaviour handler for view lifecycle events
  * In-app content blocks tracking API with handling of tracking consent according to DSGVO/GDPR
  * In-app content blocks support for height update
* Bug Fixes
  * Removed: Dev debug log in StaticInAppContentBlockView class
  * Fixed: Could not find module 'ExponeaSDK' for simulator target x86_64
  * Fixed: Extensions were defined as public
  * Fixed: AppInbox list item image was stretched by longer dimension
  * Fixed: Showing of alert was causing crash for opened push in Example app


## Release Notes for 2.20.0
#### November 27, 2023
* Features
  * In-app content blocks with deferred load and onContentReady listener
* Bug Fixes
  * Fixed: Xcode 14.2 compiler issue for capture of isDebugModeEnabled


## Release Notes for 2.19.0
#### October 27, 2023
* Features
  * Xcode 15 and iOS 17 support added
    * iOS minimal version increased to 12
  * Push notification token tracking frequency has been documented
  * Anonymize feature has been described with more details in documentation
  * Rich Push notification has clickable image with default action
  * Viewport meta tag was removed from forbidden constructs for all HTML messages due to scaling issues
  * Debug mode was refactored
* Bug Fixes
  * Fixed: Action button not working for HTML In-app messages created via Visual editor
  * Fixed: Push notification payload docu has wrong field names
  * Fixed: Multiple flush timers invocation


## Release Notes for 2.18.0
#### September 14, 2023
* Features
  * Added EXP prefix for for SDK-related log output
  * Added dynamic scaling for App Inbox PUSH message
  * Add support for darkmode in App Inbox PUSH messages and native In-app messages in by isDarkMode
  * Documentation extension with PUSH notification payload structure description, PUSH handling and more
  * Small internal refactoring for better compatibility with MAUI wrapper
* Bug Fixes
  * Fixed: Image is under navbar in App Inbox PUSH message detail


## Release Notes for 2.17.0
#### August 02, 2023
* Features
  * In-app content block feature has been added into SDK
  * Handling of nil/null values inside objects sending tracking in requestFactory to avoid crashes
  * Documentation is updated to describe fetching of In-app messages while identifyCustomer process in detail
  * New devices supported for tracking events
* Bug Fixes
  * Fixed: Action click event from In-app messages, and App Inbox HTML Inbox messages tracked button text with HTML tags
  * Fixed: banner_type for HTML In-app messages is null instead of freeform
  * Fixed: Webview for HTML In-app messages and App Inbox HTML Inbox messages not fully offline

## Release Notes for 2.16.4
#### July 11, 2023
* Features
  * XCode 14.3 support added
* Bug Fixes
  * Fixed: Property `platform` was not tracked for campaign events


## Release Notes for 2.16.3
#### June 01, 2023
* Features
  * Brings public visibility to App Inbox style API 


## Release Notes for 2.16.2
#### May 22, 2023
* Features
  * New AppInbox provider has been created for easier styling of UI components
  * API for push token handling as string and push notification tracking
  * Small internal refactoring for better compatibility with other wrappers
  * Documentation about FCMID handling was described more deeply


## Release Notes for 2.16.1
#### May 04, 2023
* Bug Fixes
  * Fixed: Carthage dependency linking and wrong file name


## Release Notes for 2.16.0
#### April 25, 2023
* Features
  * Ability to track a user 'interaction' while closing InApp message
  * Support section added to main Readme
  * InApp loading flow has been described more deeply in documentation
  * Push notification track action has been described more deeply in documentation
  * SDK initialization performance improve
* Bug Fixes
  * Fixed: SwiftSoup takes large space because of xcframework assignment
  * Fixed: Marking of App Inbox message as read failed due to invalid usage of Customer IDs
  * Fixed: Empty in-app message response did not clear the cache so previously loaded messages persisted there
  * Fixed: Remove invalid link to developers hub from Useful links


## Release Notes for 2.15.2
#### March 06, 2023
* Bug Fixes
  * Fixed: AppInbox detail layout fixes


## Release Notes for 2.15.1
#### February 27, 2023
* Bug Fixes
  * Fixed: Fixed: App Inbox layout was reworked from using storyboard to native code implementation for better compatibility with SDK wrappers


## Release Notes for 2.15.0
#### February 16, 2023
* Features
  * Extended App Inbox functionality with new HTML message type - Inbox message
  * All SDK methods are invoked after SDK has been initialised
  * Added support for Customer token authorization

## Release Notes for 2.14.0
#### December 15, 2022
* Features
  * Added App Inbox feature with PUSH message type support

## Release Notes for 2.13.1
#### November 24, 2022
* Features
  * Added Configuration flag to be able to disable tracking of default properties along with customer properties
  * Increased support for iOS SDK 11+
  * Updated guide documentation for Push notifications service setup
* Bug Fixes
  * Fixed: Handling of InApp messages may cause race-condition crash
  * Fixed: Handling of universal links in HTML InApp messages was not working properly


## Release Notes for 2.13.0
#### October 19, 2022
* Features
  * Added feature to handle tracking consent according to DSGVO/GDPR
  * Guiding documentation added for Push notification update after certain circumstances
* Bug Fixes
  * Fixed: Webview configuration updated according to newer XCode14


## Release Notes for 2.12.3
#### September 20, 2022
* Bug Fixes
  * Fixed: Webview configuration setup compatible with swift5.7


## Release Notes for 2.12.2
#### September 06, 2022
* Bug Fixes
  * Fixed: DatabaseManager init with Bundle creation for Swift Package Manager usage


## Release Notes for 2.12.1
#### September 01, 2022
* Bug Fixes
  * Fixed: License established to MIT
  * Fixed: Warn log for developer for old SDK usage has been fixed for compatibility with SDK wrappers


## Release Notes for 2.12.0
#### August 09, 2022
* Features
  * Added a support of HTML InApp messages


## Release Notes for 2.11.4
#### May 30, 2022
* Features
  * Shows a warn log for developer if old SDK version is used
  * Documentation note for Universal Links data tracking with new vs resumed session
  * List of human-readable model names are updated to latest models
  * Documentation update for recommendation_id to match Android SDK example
  * Provisional push notifications support for iOS 12+
* Bug Fixes
  * Fixed: Track internal development and tests to special internal app center project
  * Fixed: Duplicated push open action track is not called on app cold start 


## Release Notes for 2.11.3
#### March 03, 2022
* Features
  * Delegate for reacting on in-app message action clicks - check [In-app messages documentation](./IN_APP_MESSAGES.md) 

## Release Notes for 2.11.2
#### January 13, 2022
* Features
  * Tracking button URL as link attribute for banner click event [Issue #31](https://github.com/exponea/exponea-ios-sdk/issues/31)
* Bug Fixes
  * Fixed: ExponeaSDKObjC and ExponeaSDKShared frameworks are no longer embedded [Issue #33](https://github.com/exponea/exponea-ios-sdk/issues/33)
  * Fixed: UI blocking when fetching in-app messages
  * Fixed: Caching in-app message images
  * Fixed: Padding and text truncating differences in In-app message buttons on web preview and in the app
  * Fixed: Warnings appearing with XCode12 and above [Issue #35](https://github.com/exponea/exponea-ios-sdk/issues/35)


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
