## 🔍 Flush events

> By default, Exponea SDK automatically takes care of flushing events to the Exponea API (using the `.immediate` mode), flushing the data as soon as it is tracked and/or when the application is backgrounded. 
> 
> This feature can be turned off setting the property FlushMode to `.manual`. Be careful when turning automatic flushing off, because if you do then you need to manually flush the data every time there is something to flush.

All tracked events and track customer properties are stored in the internal database in the Exponea SDK. When an event was successfully sent to Exponea API, the object will be deleted from the local database.

Exponea SDK will only flush data when the device has a stable internet connection. If when flushing the data, a connection/server error occurs,  it will keep the data stored until it can be flushed at a later time.

You can configure the flushing mode to work differently to suit your needs.

#### 🔧 Flush Configuration

Flushing mode that is used to specify how often or if data is automatically flushed.

```swift
public enum FlushingMode {
    /// Manual flushing mode disables any automatic upload and it's your responsibility to flush data.
    case manual
    
    /// Automatic data flushing will flush data when the application will resign active state.
    case automatic
    
    /// Periodic data flushing will be flushing data in your specified interval (in seconds)
    /// and when you background or quit the application.
    case periodic(Int)
    
    /// Flushes all data immediately as it is received.
    case immediate
}
```

To set the flushing mode, initialise Exponea first and then set it directly on the Exponea singleton:

```swift
Exponea.shared.flushingMode = .periodic(10)
```

#### 💻 Manual Flushing

To manually trigger a data flush to the API, use the following method.

```swift
Exponea.shared.flushData()
```
