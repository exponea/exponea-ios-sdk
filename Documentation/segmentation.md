## Segmentation

Real-Time Segments feature personalizes the product search, category and pathway results in real-time based on customer demographic and behavioral data. More information could found [here](https://documentation.bloomreach.com/discovery/docs/real-time-customer-segments-for-discovery).
This guide provides few integration steps required to retrieve any segmentation data changes assigned to active customer.

### Using Segmentation feature

Only required step is to register one or more of your customized `SegmentCallbackData` instances.
Each instance has to define 3 things to work:

1. Your point of interest for segmentation as field `category`
   1. Possible values are `content`, `discovery` or `merchandise`. You will get update only for segmentation data assigned to given `category`.
2. Boolean flag to force fetch of segmentation data as field `includeFirstLoad`
   1. Setting this flag to TRUE invokes segmentation data fetch immediately
   2. This callback instance is notified with data even if data has not changed from last known state
   3. Other callbacks are also notified but only if data has changed
   4. Setting this flag to FALSE also triggers segmentation data fetch but instance is notified only if new data differs from last known state
3. Handler for new segmentation data as method `onNewData`
   1. It will get all segmentation data for `category` assigned to current customer
   2. Data are list of `Segment` objects; Each `Segment` contains `id` and `segmentation_id` values

```swift
SegmentationManager.shared.addCallback(
    callbackData: .init(
        category: .merchandise(),
        isIncludeFirstLoad: false,
        onNewData: { segments in
    print(segments)
}))
```

### Getter for segmentation data
Exponea SDK contains API to get segmentation data directly. This feature could be invoked easily by `Exponea.shared.getSegments` usage for `category` value.

```swift
Exponea.shared.getSegments(category: .content()) { segments in
    print(segments)
}
```

> Method loads segmentation data for given `category` and currently assigned customer by `Exponea.shared.identifyCustomer`. Bear in mind that callback is invoked in background thread.

Data payload of each `Segment` is:
```json
{ 
  "id": "66140257f4cb337324209871",
  "segmentation_id": "66140215fb50effc8a7218b4"
}
```

### When segmentation data are loaded

There are few cases when segmentation data are refreshed and this process could occur multiple times. But registered callbacks are notified only if these data has changed or if `includeFirstLoad` is TRUE. Behaviour of callback notification process is described later in this documentation with more details.
Data reload is triggered in these cases:

1. On callback instance is registered while SDK is fully initialized
2. While SDK initialization if there is any callback registered
3. On `Exponea.shared.identifyCustomer` if is called with Hard ID
4. On any event has been tracked successfully

When segmentation data reload is triggered then process waits 5 seconds to fully start to eliminate meaningful update requests especially for higher frequency of events tracking.

> It is required to set `Exponea.shared.flushingMode` to `IMMEDIATE` value to get expected results. Process of segment calculation needs to all tracked events to be uploaded to server to calculate results effectively.

### Behaviour of callback

SDK allows you to register multiple `SegmentCallbackData` for multiple or for same `category`. You may register callback into SDK anytime (before and after initialization). Instances of callbacks are hold by SDK until application is terminated or until you unregister callback.
There are some principles how callback is working:

1. Callback got data assigned only for defined `category`
2. Callback is always notified if data differs from previous reload in scope of `category`
3. Newly registered callback is notified also for unchanged data if `includeFirstLoad` is TRUE but only once. Next callback update is called only if data has changed.
4. Unregistered callback stops listening for data change, you should consider to keep number of callbacks within reasonable value
5. Callback is notified always in background thread

### Unregistering of callback

Unregistering of callback is up to developer. SDK will hold callback instance until application is terminated otherwise.

> To unregister callback successfully you have to call `SegmentationManager.shared.removeCallback(callbackData: SegmentCallbackData)` with callback instance you already registered, otherwise callback will not be unregistered.

```swift
let callback: SegmentCallbackData = .init(category: .discovery(), isIncludeFirstLoad: false) { _ in }
manager.removeCallback(callbackData: callback)
```

### Logging

The SDK logs a lot of useful information on the `VERBOSE` level for segmentation data update. You can set the logger level using `Exponea.logger.logLevel` before initializing the SDK.

> Note: All logs assigned to segmentation process are prefixed with `Segments:` to bring easier search-ability to you. Bear in mind that some supporting processes (such as HTTP communication) are logging without this prefix.

#### Log examples

Process of segmentation data update may be canceled due to current state of SDK. Segmentation data are assigned to current customer and whole process is active only if there are any callbacks registered. All these validations are described in logs.

If you are not retrieving segmentation data update, you may see these logs:

- `Segments: Skipping segments update process after tracked event due to no callback registered`
  - SDK tracked event successfully but there is no registered callback for segments. Please register at least one callback.
- `Segments: Skipping segments reload process for no callback`
  - SDK is trying to reload segmentation data but there is no registered callback for segments. Please register at least one callback.
- `Segments: Skipping initial segments update process for no callback`
  - SDK initialization flow tries to reload segmentation data but there is no registered callback for segments. If you want to check segmentation data on SDK init, please register at least one callback before SDK initialization.
- `Segments: Skipping initial segments update process as is not required`
  - SDK initialization flow detects that all registered callbacks have `includeFirstLoad` with FALSE value. If you want to check segmentation data on SDK init, please register at least one callback with `includeFirstLoad` with TRUE value before SDK initialization.

If you are not retrieving segmentation data while registering customer, please check your usage of `ExponeaExponea.shared.identifyCustomer` or `Exponea.shared.anonymize`. You may face these logs:

- `Segments: Segments change check has been cancelled meanwhile`
  - Segmentation data update process started but has been cancelled meanwhile by invoking of `Exponea.shared.anonymize`. If this is unwanted behaviour, check your `Exponea.shared.anonymize` usage.
- `Segments: Check process was canceled because customer has changed`
  - Segmentation data update process started for customer but customer IDs has changed meanwhile by invoking of `Exponea.shared.identifyCustomer` for another customer. If this is unwanted behaviour, check your `Exponea.shared.identifyCustomer` usage.
- `Segments: Customer IDs <customer_ids> merge failed, unable to fetch segments`
  - Segmentation data update process requires to link IDs but that part of process failed. Please see error logs what happen and check your `Exponea.identifyCustomer`. This part should not happen so consider to discuss it with support team.
- `Segments: New data are ignored because were loaded for different customer`
  - Segmentation data update process detects that data has been fetched for previous customer. This should not lead to any problem as there is another fetch process registered for new customer, but you may face a short delay for new data retrieval. If you see this log often, check your `Exponea.shared.identifyCustomer` usage.
- `Segments: Fetch of segments failed: <error message>`
  - Please read error message carefully. This log is print if fetch of data failed by technical reason, probably network connection is not stable.
