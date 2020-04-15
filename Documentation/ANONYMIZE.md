## 🕵 Anonymize

Anonymize is a feature that allows you to switch users. Typical use-case is user login/logout.

Anonymize will generate new customer and track install and session start events. Push notification token from the old user will be wiped and tracked for the new user, to make sure the device won't get duplicate push notifications.

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

