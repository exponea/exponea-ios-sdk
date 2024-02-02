## Tracking consent

Based on the recent judgment (May 2022) made by the Federal Court of Justice in Germany (Bundesgerichtshof – BGH) 
regarding the EU Datenschutz Grundverordnung (EU-GDPR), all access to data on the affected person’s device would 
require explicit consent. For more info see [Configuration of the tracking consent categories](https://documentation.bloomreach.com/engagement/docs/configuration-of-tracking-consent).

The SDK is adapted to the rules and is controlled according to the data received from the Push Notifications or InApp Messages.
If the tracking consent feature is disabled, the Push Notifications and InApp Messages data do not contain 'hasTrackingConsent' and their tracking behaviour has not been changed, so if the attribute 'hasTrackingConsent' is not present in data, SDK considers it as 'true'.
If the tracking consent feature is enabled, Push Notifications and InApp Messages data contain 'hasTrackingConsent' and the SDK tracks events according to the boolean value of this field.

Disallowed tracking consent ('hasTrackingConsent' provided with 'false' value) can be overridden with URL query param 'xnpe_force_track' with 'true' value.

### Event for push notification delivery

Event is normally tracked by calling `Exponea.trackDeliveredPush` or `Exponea.handleRemoteMessage`. This methods are tracking
a delivered event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value

If you are using `Exponea.shared.trackDeliveredPush` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackDeliveredPushWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Event for clicked push notification

Event is normally tracked by calling `Exponea.shared.trackPushOpened` or `Exponea.shared.handlePushNotificationOpened`. These methods are tracking a clicked event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value
* Action URL contains 'xnpe_force_track' with 'true' value independently of 'hasTrackingConsent' value

If you are using `Exponea.shared.trackPushOpened` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackPushOpenedWithoutTrackingConsent` instead.
If you are using `Exponea.shared.handlePushNotificationOpened` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.handlePushNotificationOpenedWithoutTrackingConsent` instead.
These methods will do track event ignoring tracking consent state.

### Event for clicked InApp Message

Event is normally tracked by calling `Exponea.shared.trackInAppMessageClick`. This method is tracking a clicked event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value
* Action URL contains 'xnpe_force_track' with 'true' value independently of 'hasTrackingConsent' value

If you are using `Exponea.shared.trackInAppMessageClick` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackInAppMessageClickWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Event for closed InApp Message

Event is normally tracked by calling `Exponea.shared.trackInAppMessageClose`. This method is tracking a delivered event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value

If you are using `Exponea.shared.trackInAppMessageClose` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackInAppMessageCloseWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Event for opened AppInbox Message

Event is normally tracked by calling `Exponea.shared.trackAppInboxOpened`. This method is tracking a delivered event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value

If you are using `Exponea.shared.trackAppInboxOpened` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackAppInboxOpenedWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Event for clicked AppInbox Message action

Event is normally tracked by calling `Exponea.shared.trackAppInboxClick`. This method is tracking a clicked event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value
* Action URL contains 'xnpe_force_track' with 'true' value independently from 'hasTrackingConsent' value

> Event that is tracked because of `xnpe_force_track` (forced tracking) will contains an additional property `tracking_forced` with value `true`

If you are using `Exponea.shared.trackAppInboxClick` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackAppInboxClickWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Event for shown In-app content block

Event is normally tracked by calling `Exponea.shared.trackInAppContentBlockShown`. This method is tracking a clicked event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value

If you are using `Exponea.shared.trackInAppContentBlockShown` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackInAppContentBlockShownWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Event for clicked In-app content block

Event is normally tracked by calling `Exponea.shared.trackInAppContentBlockClick`. This method is tracking a clicked event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value
* Action URL contains 'xnpe_force_track' with 'true' value independently from 'hasTrackingConsent' value

> Event that is tracked because of `xnpe_force_track` (forced tracking) will contains an additional property `tracking_forced` with value `true`

If you are using `Exponea.shared.trackInAppContentBlockClick` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackInAppContentBlockClickWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Event for closed In-app content block

Event is normally tracked by calling `Exponea.shared.trackInAppContentBlockClose`. This method is tracking a delivered event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value

If you are using `Exponea.shared.trackInAppContentBlockClose` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackInAppContentBlockCloseWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.

### Event for error for In-app content block

Event is normally tracked by calling `Exponea.shared.trackInAppContentBlockError` with meaningful `errorMessage` parameter. This method is tracking a delivered event only if:

* Tracking consent feature is disabled
* Tracking consent feature is enabled and 'hasTrackingConsent' has 'true' value

If you are using `Exponea.shared.trackInAppContentBlockError` method manually and you want to avoid to consider tracking, you may use `Exponea.shared.trackInAppContentBlockErrorWithoutTrackingConsent` instead. This method will do track event ignoring tracking consent state.