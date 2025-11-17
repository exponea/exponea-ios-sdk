---
title: SDK Version Update Guide
excerpt: Update Exponea iOS SDK in your app to a new version
slug: ios-sdk-version-update
categorySlug: integrations
parentDocSlug: ios-sdk-release-notes
---

This guide will help you upgrade your Exponea SDK to the latest major version.

## Update to version 3.8.0 or higher

SDK versions 3.8.0 and higher support multiple mobile applications within a single Bloomreach Engagement project.

This update introduces two major changes:

 ### 1. **Application ID configuration**

Each mobile application integrated with the SDK can now have its own unique `applicationID`. This identifier distinguishes between different applications within the same project.

**When to configure Application ID:**

- **Multiple mobile apps:** You must specify a unique `applicationID` for each app in the SDK configuration. The value must match the Application ID configured in Bloomreach Engagement under **Project Settings > Campaigns > Channels > Push Notifications.**
- **Single mobile app:** If you use only one mobile application, you don't need to set `applicationID`. The SDK uses the default value `default-application` automatically.

Learn more about [SDK configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) and [Configure Application ID](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#configure-application-id).

### 2. **Push notification token tracking**

Push notification tokens are now tracked using `notification_state` events instead of customer properties (`apple_push_notification_id`). This change enables tracking multiple push tokens for the same customer across different applications and devices.

**Important prerequisites before upgrading:**

The SDK automatically generates `notification_state` events. Before upgrading to version 3.8.0 or higher:

- Ensure event creation is enabled for your Bloomreach Engagement project
- If your project uses custom event schemas or restricts event creation, add `notification_state` to the list of allowed events
- If your project blocks creation of new event types, push token registration will fail silently

**Symptoms of blocked event creation:**

- No new tokens appear in customer profiles or the event stream after SDK initialization
- Push notifications are not delivered

Learn more about [Token tracking via notification_state event](https://documentation.bloomreach.com/engagement/docs/ios-sdk-push-notifications#token-tracking-via-notification_state-event).

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
