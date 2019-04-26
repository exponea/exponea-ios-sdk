## Release Notes

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
