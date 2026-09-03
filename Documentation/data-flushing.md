---
title: Data flushing for iOS SDK
slug: ios-sdk-data-flushing
category:
  uri: /branches/2/categories/guides/Developers
parent:
  uri: ios-sdk-setup
content:
  excerpt: >-
    Learn how the iOS SDK uploads data to the Marketing API and how to
    customize this behavior
---

## Data flushing

The SDK caches data (sessions, events, customer properties, etc.) in an internal database and periodically sends it to the {user.mkg} API. After the data has been uploaded, the values in the {user.mkg} web app are updated, and the cached data is removed from the SDK's internal database. This process is called **data flushing**.

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

Use the completion-bearing overload when you need to know the SDK has finished trying to upload pending events—for example, to resolve a `Promise` in a wrapper SDK or to chain the next operation after the flush settles:

```swift
Exponea.shared.flushData { result in
    switch result {
    case .success(let count):
        // count is the number of successfully uploaded objects
        break
    case .flushAlreadyInProgress, .noInternetConnection:
        // The next automatic cycle will retry the flush
        break
    case .error(let error):
        // Inspect the error for the failure cause
        break
    }
}
```

### Completion guarantee

When the SDK is configured and no stop is in progress, `flushData(completion:)` invokes its callback on the main thread on successful completion and on every documented short-circuit path. The SDK queues any call made before `Exponea.shared.configure(...)` finishes. If the deferred call succeeds, the callback is invoked once configuration completes.

`Exponea.logger` logs deferred failures (insufficient authorization, a prior internal exception, or an NSException during deferred execution) and these won't surface in the callback—the deferred-execution path has no error handler wired back to the original caller. If you resolve a `Promise`/`Future` inside the iOS callback, call `flushData(completion:)` only after `Exponea.shared.configure(...)` returns to avoid a callback that never fires.


The short-circuit paths are:

| `FlushResult` value | When it occurs |
| --- | --- |
| `.error(ExponeaError.isStopped)` | The SDK was stopped via `stopIntegration()`, or the stopped flag was flipped between the public-API guard and the internal flushing pipeline. |
| `.error(ExponeaError.nsExceptionInconsistency)` | A prior call hit an internal `NSException` and the SDK is in safe-mode disabled state. |
| `.error(ExponeaError.authorizationInsufficient)` | The current configuration's authorization is `.none` and no custom authorization provider is wired. |
| `.flushAlreadyInProgress` | Another flush is already running. |
| `.noInternetConnection` | The device has no network connection. |
| `.success(0)` | Returned in three cases: the local queue is empty; the SDK filtered out every candidate object before upload (for example, objects with missing customer IDs or an empty Stream-mode update containing only a cookie); or the backend returned errors for every attempted upload. `.success(0)` doesn't distinguish between "nothing to flush" and "all uploads failed"—check `Exponea.logger` `.warning` output (`Flush failed: 0/N objects succeeded.`) to disambiguate. |
| `.success(N)` with `0 < N < attempted` | Partial success — `N` of the attempted tracking objects were uploaded; the remainder stay in the local cache and will be retried on the next flush cycle. |
| `.error(_)` | Database read failed or an unexpected error occurred before the upload pipeline ran. The SDK forwards the underlying error for diagnostics. |

Flutter, React Native, and similar wrapper SDKs that resolve a `Promise` or `Future` inside the iOS callback can rely on this contract for post-configure paths: the callback is delivered exactly once, on the main thread.

## Stream mode flushing behavior

When the SDK is configured with Stream/{user.dh} integration, the flushing behavior has the following differences:

* All flush requests use JWT authentication (Bearer token provided via `setSdkAuthToken`). The SDK attaches the current JWT to each outgoing request.
* If a flush request receives a **401 Unauthorized** response, the SDK invokes the [JWT error handler](https://documentation.bloomreach.com/engagement/docs/ios-sdk-authorization#jwt-error-handling) and retries the request once after a ~1-second delay. If the retry also fails, the event remains in the local cache for the next flush cycle.
* Both `anonymize()` and `stopIntegration()` flush all pending events before clearing the JWT and customer identity. This ensures tracked data is uploaded while the current token is still available.
* Use `anonymize(completion:)` or `stopIntegration(completion:)` to be notified on the main thread when the flush and teardown are complete.

> If no JWT is set when a flush is attempted in Stream mode, the SDK will invoke the error handler with `.notProvided` and defer the flush until a token is available.
