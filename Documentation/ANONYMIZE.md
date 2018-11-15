## 🕵 Anonymize

A new feature called Anonymize has been introduced in SDK 1.1.0. It will delete all stored 
information, reset the customer, generate a new cookie, track new installment and session start 
event, thus completely anonymizing the user.

This feature will also transfer the push notification token from the old user to the new user if there was any registered.

#### 💻 Usage

```swift
Exponea.shared.anonymize()
```