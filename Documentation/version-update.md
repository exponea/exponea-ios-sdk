---
title: SDK version update guide for iOS SDK
slug: ios-sdk-version-update
category:
  uri: /branches/2/categories/guides/Developers
parent:
  uri: ios-sdk-release-notes
content:
  excerpt: Update Exponea iOS SDK in your app to a new version
---

This guide will help you upgrade your Exponea SDK to the latest major version.

## Update from version 3.x.x to 4.x.x

Version 4.0.0 introduces support for [Data hub event stream](https://documentation.bloomreach.com/data-hub/docs/event-streams) integration as an alternative to the existing Project/Engagement integration. The `configure` method now accepts either `Exponea.ProjectSettings` or the new `Exponea.StreamSettings` via the `IntegrationType` protocol.

Existing integrations using `Exponea.ProjectSettings` continue to work without changes. The sections below describe the deprecated APIs and breaking changes.

### Deprecated configure methods

The convenience methods `configure(projectToken:authorization:baseUrl:...)` and `configure(projectToken:projectMapping:authorization:baseUrl:...)` are **deprecated**. Use `configure(_:pushNotificationTracking:...)` with a `ProjectSettings` or `StreamSettings` object instead:

```swift
// Deprecated
Exponea.shared.configure(
    projectToken: "YOUR_PROJECT_TOKEN",
    authorization: .token("YOUR_API_KEY"),
    baseUrl: "https://api.exponea.com",
    appGroup: "YOUR_APP_GROUP"
)

// Use instead
Exponea.shared.configure(
    Exponea.ProjectSettings(
        projectToken: "YOUR_PROJECT_TOKEN",
        authorization: .token("YOUR_API_KEY"),
        baseUrl: "https://api.exponea.com"
    ),
    pushNotificationTracking: .enabled(appGroup: "YOUR_APP_GROUP")
)
```

If you used `projectMapping`, it moves into `Exponea.ProjectSettings`:

```swift
Exponea.shared.configure(
    Exponea.ProjectSettings(
        projectToken: "YOUR_PROJECT_TOKEN",
        authorization: .token("YOUR_API_KEY"),
        baseUrl: "https://api.exponea.com",
        projectMapping: YOUR_PROJECT_MAPPING
    ),
    pushNotificationTracking: .enabled(appGroup: "YOUR_APP_GROUP")
)
```

### Deprecated identifyCustomer method

`identifyCustomer(customerIds:properties:timestamp:)` is **deprecated**. Use `identifyCustomer(context:properties:timestamp:)` with `CustomerIdentity` instead:

```swift
// Deprecated
Exponea.shared.identifyCustomer(
    customerIds: ["registered": "jane.doe@example.com"],
    properties: ["first_name": "Jane"],
    timestamp: nil
)

// Use instead
Exponea.shared.identifyCustomer(
    context: CustomerIdentity(
        customerIds: ["registered": "jane.doe@example.com"]
    ),
    properties: ["first_name": "Jane"],
    timestamp: nil
)
```

`CustomerIdentity` also accepts an optional `jwtToken` for Stream integrations.

### Deprecated anonymize overload

`anonymize(exponeaProject:projectMapping:)` is **deprecated**. Use `anonymize(exponeaIntegrationType:exponeaProjectMapping:)`:

```swift
// Deprecated
Exponea.shared.anonymize(
    exponeaProject: ExponeaProject(
        baseUrl: "https://api.exponea.com",
        projectToken: "YOUR_PROJECT_TOKEN",
        authorization: .token("YOUR_API_KEY")
    ),
    projectMapping: nil
)

// Use instead
Exponea.shared.anonymize(
    exponeaIntegrationType: ExponeaProject(
        baseUrl: "https://api.exponea.com",
        projectToken: "YOUR_PROJECT_TOKEN",
        authorization: .token("YOUR_API_KEY")
    ),
    exponeaProjectMapping: nil
)
```

A new `anonymize(completion:)` overload is also available for cases where you need a callback after flush and teardown completion.

### Deprecated Configuration properties

The following properties on the `Configuration` struct are **deprecated**. Use the corresponding values from `integrationConfig` (of type `any IntegrationType`) instead:

- `projectToken` — use `integrationConfig` (available via `Exponea.ProjectSettings`)
- `authorization` — use `integrationConfig` (available via `Exponea.ProjectSettings`)
- `baseUrl` — use `integrationConfig.baseUrl`
- `projectMapping` — pass the mapping via `Exponea.ProjectSettings(projectMapping:)` when constructing `integrationConfig`

The `Configuration` initializer `init(projectToken:projectMapping:authorization:baseUrl:...)` is also deprecated. Use `init(integrationConfig:...)` instead.

### Configuration property type changes

The following `Configuration` properties now return `any ExponeaIntegrationType` instead of `ExponeaProject`:

- `mainProject`
- `mutualExponeaProject`
- `projects(for:)` (returns `[any ExponeaIntegrationType]`)

If your code accesses these properties with a concrete `ExponeaProject` type, you must update it to use the protocol type or cast as needed.

### New: Stream integration (Data hub)

For stream-based integrations, configure the SDK with `Exponea.StreamSettings` and manage [authentication via JWT](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#stream-jwt-authorization-data-hub):

```swift
Exponea.shared.configure(
    Exponea.StreamSettings(
        streamId: "YOUR_STREAM_ID",
        baseUrl: "https://api.exponea.com"
    ),
    pushNotificationTracking: .enabled(appGroup: "YOUR_APP_GROUP")
)

Exponea.shared.setJwtErrorHandler { context in
    let newToken = fetchFreshToken(for: context.customerIds)
    Exponea.shared.setSdkAuthToken(newToken)
}
Exponea.shared.setSdkAuthToken("YOUR_JWT_TOKEN")
```

For logout in Stream mode, use `stopIntegration()` instead of `anonymize()` to avoid generating anonymous events:

```swift
Exponea.shared.stopIntegration {
    // SDK is fully torn down; safe to re-configure if needed
}
```

Refer to the [Authorization](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#stream-jwt-authorization-data-hub) and [Configuration](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) documentation for full details.

---

## Update to version 3.8.0 or higher

SDK versions 3.8.0 and higher support multiple mobile applications within a single Bloomreach Engagement project.

This update introduces two major changes:

 ### 1. **Application ID configuration**

Each mobile application integrated with the SDK can now have its own unique `applicationID`. This identifier distinguishes between different applications within the same project.

**When to configure Application ID:**

- **Multiple mobile apps:** You must specify a unique `applicationID` for each app in the SDK configuration. The value must match the Application ID configured in Bloomreach Engagement under **Project Settings > Campaigns > Channels > Push Notifications.**
- **Single mobile app:** If you use only one mobile application, you don't need to set `applicationID`. The SDK uses the default value `default-application` automatically.

Learn more about [Configuration for iOS SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-configuration) and [Configure Application ID](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup#configure-application-id).

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
