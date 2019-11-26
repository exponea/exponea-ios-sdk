## Release Notes

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
