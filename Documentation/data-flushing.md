---
title: Data flushing for iOS SDK
slug: ios-sdk-data-flushing
category:
  uri: /branches/2/categories/guides/Developers
parent:
  uri: ios-sdk-setup
content:
  excerpt: >-
    Learn how the iOS SDK uploads data to the Engagement API and how to
    customize this behavior
---

## Data flushing

The SDK caches data (sessions, events, customer properties, etc.) in an internal database and periodically sends it to the Engagement API. After the data has been uploaded, the values in the Engagement web app are updated, and the cached data is removed from the SDK's internal database. This process is called **data flushing**.

By default, the SDK automatically flushes the data as soon as it is tracked or when the application is backgrounded. You can configure the [flushing mode](#flushing-modes) to customize this behavior to suit your needs.
 
 You can also turn off automatic flushing completely. In this case, you must [manually flush](#manual-flushing) every time there is data to flush.

The SDK will only flush data when the device has a stable network connection. If a connection error occurs while flushing, it will keep the data cached until the connection is stable and the data is flushed successfully.

## Flushing modes

The SDK supports the following 4 flushing modes to specify how often or if data is flushed automatically.

| Name                   | Description |
| ---------------------- | ----------- |
| `.immediate` (default) | Flushes all data immediately as it is received. |
| `.automatic`           | Flush data any time the application resigns active state. |
| `.periodic(Int)`       | Flushes data in the specified interval (in seconds) and when the application is closed or goes to the background. |
| `.manual`              | Disables any automatic upload. It's the responsibility of the developer to [flush data manually](#manual-flushing). |

To set the flushing mode, [initialize the SDK](https://documentation.bloomreach.com/engagement/docs/ios-sdk-setup) first, then set `flushingMode` directly on the `Exponea` singleton:

```swift
Exponea.shared.flushingMode = .periodic(10)
```

## Manual flushing

To manually trigger a data flush to the API, use the following method:

```swift
Exponea.shared.flushData()
```

## Stream mode flushing behavior

When the SDK is configured with Stream/Data hub integration, the flushing behavior has the following differences:

* All flush requests use JWT authentication (Bearer token provided via `setSdkAuthToken`). The SDK attaches the current JWT to each outgoing request.
* If a flush request receives a **401 Unauthorized** response, the SDK invokes the [JWT error handler](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#jwt-error-handling) and retries the request once after a ~1-second delay. If the retry also fails, the event remains in the local cache for the next flush cycle.
* Both `anonymize()` and `stopIntegration()` flush all pending events before clearing the JWT and customer identity. This ensures tracked data is uploaded while the current token is still available.
* Use `anonymize(completion:)` or `stopIntegration(completion:)` to be notified on the main thread when the flush and teardown are complete.

> If no JWT is set when a flush is attempted in Stream mode, the SDK will invoke the error handler with `.notProvided` and defer the flush until a token is available.
