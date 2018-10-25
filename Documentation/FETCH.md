## 🚀 Fetching Data

Exponea SDK has some methods to retrieve your data from the Exponea APP.
All the responses will be available in a completion handler closure.

#### Get customer recommendation

> **NOTE:** Requires Token or Basic authorization.

Get items recommended for a customer.

```
public func fetchRecommendation(with request: RecommendationRequest,
                                completion: @escaping (Result<RecommendationResponse>) -> Void)
)
```

#### 💻 Usage

```
// Preparing the data.
let recommendation = CustomerRecommendation(
        type = "recommendation",
        id =  "592ff585fb60094e02bfaf6a",
        size = 10,
        strategy = "winner",
        knowItems = false,
        anti = false,
        items = MutableList(hashMapOf(
                Pair("123": 2),
                Pair("234": 4))
        )
)

// Call fetchRecommendation to get the customer attributes.
Exponea.shared.fetchRecommendation(with: recommendation) { (result) in
	// SDK will return a RecommendationResponse object.
}
```

#### Get customer attributes (⚠️ DEPRECATED)

> **NOTE:** Requires Basic authorization. Deprecated method as basic authorization will be removed in the next major release, alongside this method.

It's possible to get all the customer attributes you have sent to the Exponea APP through the following method.


```
public func fetchAttributes(with request: AttributesDescription,
                            completion: @escaping (Result<AttributesListDescription>) -> Void)
```

#### 💻 Usage

```
// Preparing the data.
let attributes = AttributesDescription(
        key = "type",
        value = "property"
        identificationKey = "property"
        identificationValue = "first_name"
)

// Call fetchAttributes to get the customer attributes.
Exponea.shared.fetchAttributes(with: attributes) { (result) in
	// SDK will return a AttributesListDescription object.
}
```

#### Get customer events (⚠️ DEPRECATED)

> **NOTE:** Requires Basic authorization. Deprecated method as basic authorization will be removed in the next major release, alongside this method.

Export all the events for a specific customer.

```
public func fetchEvents(with request: EventsRequest, 
                        completion: @escaping (Result<EventsResponse>) -> Void)
```

#### 💻 Usage

```
// Preparing the data.
let events = EventsRequest(
        eventTypes = ["session_start", "payment"],
        sortOrder = "asc",
        limit = 1,
        skip = 0
)

// Call fetchEvents to get the customer attributes.
Exponea.shared.fetchEvents(with: events) { (result) in
  	// SDK will return a EventsResponse object.
}
```
