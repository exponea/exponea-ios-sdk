---
title: Segmentation
excerpt: Implement real-time segments using the iOS SDK
slug: ios-sdk-segmentation
categorySlug: integrations
parentDocSlug: ios-sdk
---

The [real-time segments](https://documentation.bloomreach.com/discovery/docs/real-time-customer-segments-for-discovery) feature personalizes the product search, category and pathway results in real-time based on customer demographic and behavioral data. The feature combines Bloomreach Discovery’s extensive search algorithms and Bloomreach Engagement’s rich customer data to get the best of both worlds.

Refer to the [Discovery real-time segments](https://documentation.bloomreach.com/discovery/docs/real-time-customer-segments-for-discovery) documentation for more details about this feature.

This page describes the integration steps required to retrieve any segmentation data changes assigned to the current customer.

### Use real-time segments

To use real-time segments in your app, you must register one or more customized `SegmentCallbackData` instances.

Each instance must define the following three items:

1. A `category` indicating your point of interest for segmentation:
   * Possible values are `content`, `discovery`, or `merchandise`. You will get updates only for segmentation data assigned to the specified `category`.
2. A boolean flag `includeFirstLoad` to force a fetch of segmentation data:
   * Setting this flag to `true` triggers a segmentation data fetch immediately.
   * The SDK will notify this callback instance with the new data even if the data has not changed from the last known state.
   * If the data has changed, the SDK will also notify any other registered callbacks.
   * Setting this flag to `false` also triggers a segmentation data fetch, but the SDK only notifies the instance if the new data differs from the last known state.
3. A handler method `onNewData` for new segmentation data:
   * The method will receive all segmentation data for `category` assigned to the current customer.
   * The data are provided as a list of `Segment` objects; each `Segment` contains `id` and `segmentation_id` values.

#### Example

```swift
SegmentationManager.shared.addCallback(
    callbackData: .init(
        category: .merchandise(),
        isIncludeFirstLoad: false,
        onNewData: { segments in
    print(segments)
}))
```

### Get segmentation data directly

The SDK provides an API to get segmentation data directly. Invoke the `Exponea.shared.getSegments` method, passing a `category` value as argument:

```swift
Exponea.shared.getSegments(category: .content()) { segments in
    print(segments)
}
```

Segments data received by `getSegments` method are primary loaded from valid cache. Cache is automatically fetched from server if:

* cache is empty or was loaded for previous customer
* cache data are older than 5 seconds
* method is forced to fetch segments from server by developer

If you want to force to fetch segmentations data from server, use `force` parameter with `true` value as argument:
```swift
    Exponea.shared.getSegments(force: true, category: .discovery()) { data in
        print(data)
    }
```

> 👍
>
> The `getSegments` method loads segmentation data for the requested `category` and the current customer as identified by `Exponea.shared.identifyCustomer`. Please bear in mind that the callback is invoked in a background thread.

The data payload of each `Segment` is as follows:
```json
{ 
  "id": "66140257f4cb337324209871",
  "segmentation_id": "66140215fb50effc8a7218b4"
}
```

### Segmentation data reload triggers

There are a few cases when the SDK refreshes segmentation data, and this process could occur multiple times. However, the SDK only notifies registered callbacks if the data have changed or if `includeFirstLoad` is `true`. Refer to [Callback behavior](#callback-behavior) for more details about the callback notification process.

A data reload is triggered in the following cases:

1. When a callback instance is registered while the SDK is fully initialized.
2. During SDK initialization if there is any callback registered.
3. When `Exponea.shared.identifyCustomer` is called with a [hard ID](https://documentation.bloomreach.com/engagement/docs/customer-identification#section-hard-id).
4. When any event is tracked successfully.

When a segmentation data reload is triggered, the process waits 5 seconds before starting, in order to ensure duplicate update requests especially for higher frequency of events tracking.

> ❗️
>
> It is required to [set](https://documentation.bloomreach.com/engagement/docs/ios-sdk-data-flushing#flushing-modes) `Exponea.shared.flushingMode` to `IMMEDIATE` to get accurate results. The process of segment calculation needs all tracked events to be uploaded to server to calculate results effectively.

### Callback behavior

The SDK allows you to register multiple `SegmentCallbackData` instances for multiple categories or for the same category. You may register a callback with the SDK anytime (before and after initialization). Callback instances remain active until the application terminates or until you unregister the callback.

The callback behavior follows the following principles:

* A callback receives data assigned only for the specified `category`.
* A callback is always notified if data differs from the previous reload in the scope of the specified `category`.
* A newly registered callback is also notified for unchanged data if `includeFirstLoad` is `true`, but only once. On subsequent updates, the callback is notified only if the data have changed.
* A deregistered callback stops listening for data changes.
* A callback is always notified in a background thread.

> 👍
>
> Consider keeping the number of callbacks within a reasonable value.

### Deregister a callback

Deregistration of a callback instance is up to the developer. If you don't deregister a callback instance, the SDK will keep it active until the application terminates.

> ❗️
>
> To deregister callback successfully, call `SegmentationManager.shared.removeCallback(callbackData: SegmentCallbackData)` with the callback instance you already registered, otherwise the callback will not be unregistered.

```swift
let callback: SegmentCallbackData = .init(category: .discovery(), isIncludeFirstLoad: false) { _ in }
manager.removeCallback(callbackData: callback)
```

### Troubleshooting

> 👍 Enable Verbose Logging
>
> The SDK logs a lot of useful information related to segmentation data updates on the `VERBOSE` level. You can set the logger level using `Exponea.logger.logLevel` before initializing the SDK.

> 👍
>
> All log messages related to the segmentation process are prefixed with `Segments:` to make them easier to find. Bear in mind that some supporting processes (such as HTTP communication) are logging without this prefix.



The process of updating segmentation data may be canceled due to the current state of the SDK. Segmentation data are assigned to the current customer and the process is active only if there are any callbacks registered. The SDK logs information about all these validations.

#### Log messages

If you are not receiving segmentation data updates, you may see the following log messages:

- ```
  Segments: Skipping segments update process after tracked event due to no callback registered
  ```
  The SDK tracked an event successfully but there is no registered callback for segments. Please register at least one callback.
- ```
  Segments: Skipping segments reload process for no callback
  ```
  The SDK is trying to reload segmentation data but there is no registered callback for segments. Please register at least one callback.
- ```
  Segments: Skipping initial segments update process for no callback
  ```
  The SDK initialization flow tries to reload segmentation data but there is no registered callback for segments. To check segmentation data on SDK initialization, please register at least one callback before SDK initialization.
- ```
  Segments: Skipping initial segments update process as is not required
  ```
  The SDK initialization flow detects that all registered callbacks have `includeFirstLoad` with `false` value. To check segmentation data on SDK initialization, please register at least one callback with `includeFirstLoad` with `true` value before SDK initialization.

If you are not receiving segmentation data while registering a customer, please check your usage of `ExponeaExponea.shared.identifyCustomer` or `Exponea.shared.anonymize`. You may face these logs:

- ```
  Segments: Segments change check has been cancelled meanwhile
  ```
  The segmentation data update process started but was subsequently canceled by an invocation of `Exponea.shared.anonymize`. If this is unwanted behavior, check your `Exponea.shared.anonymize` usage.
- ```
  Segments: Check process was canceled because customer has changed
  ```
  The segmentation data update process started for the current customer but the customer ID was subsequently changed by an invocation of `Exponea.shared.identifyCustomer` for another customer. If this is unwanted behaviour, check your `Exponea.shared.identifyCustomer` usage.
- ```
  Segments: Customer IDs <customer_ids> merge failed, unable to fetch segments
  ```
  The segmentation data update process requires to link IDs but that part of the process failed. Please refer to the error log messages and check your `Exponea.identifyCustomer` usage. This  should not happen, please discuss this with the Bloomreach support team.
- ```
  Segments: New data are ignored because were loaded for different customer
  ```
  The segmentation data update process detects that data has been fetched for a previous customer. This should not lead to any problem as there is another fetch process registered for the new customer, but you may face a short delay for new data retrieval. If you see this log often, check your `Exponea.shared.identifyCustomer` usage.
- ```
  Segments: Fetch of segments failed: <error message>
  ```
  Please read the error message carefully. This message is logged if the data retrieval failed for some technical reason, such as an unstable network connection.
