## 🔍 Flush events

All tracked events and track customer properties are stored in the internal database in the Exponea SDK. By default, Exponea SDK automatically takes care of flushing events to the Exponea API. This feature can be turned off setting the property FlushMode to MANUAL. Please be careful with turning automatic flushing off because if you turn it off, you need to manually call Exponea.shared.flushData() to flush the tracked events manually every time there is something to flush.


```
public func flushData()
```

#### 💻 Usage
```
Exponea.shared.flushData()
```

When a event was successfully sent to Exponea API, the register will be excluded from the database.


#### 🔧 Flush Configuration

It's possible to change the period to flush the events recorded into the database by setting the property FlushingMode.periodic(Int). The standard value is 60 seconds.

Flushing mode that is used to specify how often or if data is automatically flushed.

```
public enum FlushingMode {
    /// Manual flushing mode disables any automatic upload and it's your responsibility to flush data.
    case manual
    /// Automatic data flushing will flush data when the application will resign active state.
    case automatic
    /// Periodic data flushing will be flushing data in your specified interval (in seconds).
    case periodic(Int)
}
```




