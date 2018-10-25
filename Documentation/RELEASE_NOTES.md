## Release Notes

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