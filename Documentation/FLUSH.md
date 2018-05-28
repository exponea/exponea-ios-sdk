## 🔍 Flush events

All tracked events and track customer properties are stored in the internal database in the Exponea SDK. By default, Exponea SDK automatically takes care of flushing events to the Exponea API. This feature can be turned off setting the property FlushMode to MANUAL. Please be careful with turning automatic flushing off because if you turn it off, you need to manually call Exponea.flush() to flush the tracked events manually every time there is something to flush.


```
fun flush()
```

#### 💻 Usage
```
Exponea.flush()
```

When a event was successfully sent to Exponea API, the register will be excluded from the database.


#### 🔧 Flush Configuration

It's possible to change the period to flush the events recorded into the database by setting the property flushPeriod. The standard value is 60 seconds.

In case you call the flush() method and the service is already running, the SDK will check it and return waiting for the first attempt to flush the events.

The Exponea SDK Flush service will try to flush all registers recorded in the database, but when the maximum limit of retries has achieved, the SDK will delete the specific event from the database and will not try to send it again. You can configure this value by setting the property maxTries in the Exponea Configuration.



