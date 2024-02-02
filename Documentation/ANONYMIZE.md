## 🕵 Anonymize

Anonymize will delete all information stored locally and reset the current SDK state. New customer will be generated, install and session start events tracked. Push notification token from the old user will be wiped and tracked for the new user, to make sure the device won't get duplicate push notifications.

Invoking of this method, SDK is going to:

   * Push notification token is wiped from currently logged customer (also removed from online storage) to prevent of receiving notifications for this customer
   * Local repositories and caches are cleared excluding tracked events
   * New session start is tracked if `automaticSessionTracking` is enabled
   * New customer record is created (new soft ID as `cookie` is generated)
   * Previous push notification token is assigned to new customer 
   * In-app messages, In-app content block and App Inbox are preloaded for new customer
   * New `installation` event is tracked for new customer

Typical use-case for `Exponea.anonymize` usage is user logout.

#### 💻 Usage

``` swift
Exponea.shared.anonymize()
```

### Project settings switch
Anonymize also allows you to switch to a different project, keeping the benefits described above. New user will have the same events as if the app was installed on a new device.

#### 💻 Usage

``` swift
Exponea.shared.anonymize(
    exponeaProject: ExponeaProject(
        baseUrl: "https://api.exponea.com",
        projectToken: "project-token",
        authorization: .token("auth-token")
    ),
    projectMapping: nil
)
```
