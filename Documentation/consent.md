---
title: Tracking consent
excerpt: Manage tracking consent using the iOS SDK.
slug: ios-sdk-tracking-consent
categorySlug: integrations
parentDocSlug: ios-sdk
---

Depending on local data access regulations, access to data on a user's device may require explicit consent. To follow such requirements, Engagement allows you to enable the standalone "tracking consent" feature. This feature activates the tracking consent option for in-app messages, in-app content blocks, and mobile push notifications.

> 📘
>
> Refer to [Configuration of the tracking consent categories](https://documentation.bloomreach.com/engagement/docs/configuration-of-tracking-consent) in the Engagement Consent Management documentation for more information about the tracking consent feature.

## How the SDK manages tracking consent

If the tracking consent feature is enabled, the Engagement platform sents a `has_tracking_consent` attribute along with push notifications, in-app messages, and in-app content blocks data. The SDK tracks events according to the boolean value of this attribute.

If the tracking consent feature is disabled, the `has_tracking_consent` attribute is not included in push notifications, in-app messages, and in-app content blocks data. In this case, the SDK considers `has_tracking_consent` to be `true` and tracks event accordingly.

In case of clicked events, it is possible to override the value of `has_tracking_consent` and force tracking by including the query parameter `xnpe_force_track` with the value `true` in the action URL.

## How the SDK tracks events depending on tracking consent

### Push notification delivered

The SDK tracks push notification delivery by calling `Exponea.shared.trackDeliveredPush` or `Exponea.shared.handleRemoteMessage`. These methods track a delivered event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.

If you are invoking the `Exponea.shared.trackDeliveredPush` method manually and want to ignore tracking consent, you may use `Exponea.shared.trackDeliveredPushWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.

### Push notification clicked

The SDK tracks push notification clicks by calling `Exponea.shared.trackPushOpened` or `Exponea.shared.handlePushNotificationOpened`. These methods track a clicked event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.
- The action URL contains the query parameter `xnpe_force_track` with the value `true` (overriding `has_tracking_consent`).

> 👍
>
> An event that is tracked because `xnpe_force_track` (forced tracking) is enabled will contain an additional property `tracking_forced` with value `true`.

If you are invoking the `Exponea.shared.trackPushOpened` method manually and you want to ignore tracking consent, you may use `Exponea.shared.trackPushOpenedWithoutTrackingConsent` instead.

If you are invoking the `Exponea.shared.handlePushNotificationOpened` method manually and you want to ignore tracking consent, you may use `Exponea.shared.handlePushNotificationOpenedWithoutTrackingConsent` instead.

These methods will track the event regardless of tracking consent.

### In-app message clicked

The SDK tracks in-app message clicks by calling `Exponea.shared.trackInAppMessageClick`. This method tracks a clicked event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.
- The action URL contains the query parameter `xnpe_force_track` with the value `true` (overriding `has_tracking_consent`).

> 👍
>
> An event that is tracked because `xnpe_force_track` (forced tracking) is enabled will contain an additional property `tracking_forced` with value `true`.

If you are invoking the `Exponea.shared.trackInAppMessageClick` method manually and want to ignore tracking consent, you may use `Exponea.shared.trackInAppMessageClickWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.

### In-app message closed

The SDK tracks in-app message closed events by calling `Exponea.shared.trackInAppMessageClose`. This method tracks a closed event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.

If you are invoking the `Exponea.shared.trackInAppMessageClose` method manually and you want to ignore tracking consent, you may use `Exponea.shared.trackInAppMessageCloseWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.

### App Inbox message opened

The SDK tracks app inbox message opening by calling `Exponea.shared.trackAppInboxOpened`. This method tracks an app inbox message open event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.

If you are invoking the `Exponea.shared.trackAppInboxOpened` method manually and you want to ignore tracking consent, you may use `Exponea.shared.trackAppInboxOpenedWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.

### App Inbox action clicked

The SDK tracks app inbox action clicks by calling `Exponea.shared.trackAppInboxClick`. This method tracks a clicked event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.
- The action URL contains the query parameter `xnpe_force_track` with the value `true` (overriding `has_tracking_consent`).

> 👍
>
> An event that is tracked because `xnpe_force_track` (forced tracking) is enabled will contain an additional property `tracking_forced` with value `true`.

If you are invoking the `Exponea.shared.trackAppInboxClick` method manually and you want to ignore tracking consent, you may use `Exponea.shared.trackAppInboxClickWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.

### In-app content block displayed

The SDK tracks in-app content block display by calling `Exponea.shared.trackInAppContentBlockShown`. This method tracks a displayed event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.

If you are invoking the `Exponea.shared.trackInAppContentBlockShown` method manually and you want to ignore tracking consent, you may use `Exponea.shared.trackInAppContentBlockShownWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.

### In-app content block clicked

The SDK tracks in-app content block clicks by calling `Exponea.shared.trackInAppContentBlockClick`. This method tracks a clicked event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.
- The action URL contains the query parameter `xnpe_force_track` with the value `true` (overriding `has_tracking_consent`).

> 👍
>
> An event that is tracked because `xnpe_force_track` (forced tracking) is enabled will contain an additional property `tracking_forced` with value `true`.

If you are invoking the `Exponea.shared.trackInAppContentBlockClick` method manually and you want to ignore tracking consent, you may use `Exponea.shared.trackInAppContentBlockClickWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.

### In-app content block closed

The SDK tracks in-app content block closed events by calling `Exponea.shared.trackInAppContentBlockClose`. This method tracks a closed event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.

If you are invoking the `Exponea.shared.trackInAppContentBlockClose` method manually and you want to ignore tracking consent, you may use `Exponea.shared.trackInAppContentBlockCloseWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.

### In-app content block error

The SDK tracks in-app content blocks errors by calling `Exponea.shared.trackInAppContentBlockError` with a meaningful `errorMessage` parameter. This method tracks a delivered event only if one of the following is true:

- The tracking consent feature is disabled.
- The tracking consent feature is enabled and `has_tracking_consent` is `true`.

If you are invoking the `Exponea.shared.trackInAppContentBlockError` method manually and you want to ignore tracking consent, you may use `Exponea.shared.trackInAppContentBlockErrorWithoutTrackingConsent` instead. This method will track the event regardless of tracking consent.
