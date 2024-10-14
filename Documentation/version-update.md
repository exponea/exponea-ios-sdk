---
title: SDK Version Update Guide
excerpt: Update Exponea iOS SDK in your app to a new version
slug: ios-sdk-version-update
categorySlug: integrations
parentDocSlug: ios-sdk-release-notes
---

This guide will help you upgrade your Exponea SDK to the latest major version.

## Update from version 2.x.x to 3.x.x

Updating Exponea SDK to version 3 or higher requires making some changes related to in-app messages callback implementations.

The `InAppMessageActionDelegate` interface was changed and simplified, so you have to migrate your implementation of in-app message action and close handling. This migration requires to split your implementation from `inAppMessageAction` into `inAppMessageClickAction` and `inAppMessageCloseAction`, respectively.

Your implementation may have been similar to the following example:

```swift
func inAppMessageAction(
    with message: InAppMessage,
    button: InAppMessageButton?,
    interaction: Bool
) {
    if let button {
        // is click action
        Exponea.shared.trackInAppMessageClick(message: message, buttonText: button.text, buttonLink: button.url)
    } else {
        // is close action
        Exponea.shared.trackInAppMessageClose(message: message)
    } 
}
```

To update to version 3 of the SDK, you must remove the `inAppMessageAction` method and refactor your code as follows:

```swift
func inAppMessageClickAction(message: InAppMessage, button: InAppMessageButton) {
    // is click action
    Exponea.shared.trackInAppMessageClick(message: message, buttonText: button.text, buttonLink: button.url)
}

func inAppMessageCloseAction(message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
    // is close action
    Exponea.shared.trackInAppMessageClose(message: message, buttonText: button?.text, isUserInteraction: interaction)
}
```

A benefit of the new behaviour is that the method `inAppMessageCloseAction` can be called with a non-null `button` parameter. This happens when a user clicks on the Cancel button and enables you to determine which button has been clicked by reading the button text.

### SegmentationManager - category change

Category `merchandise` has been changed to `merchandising`.
