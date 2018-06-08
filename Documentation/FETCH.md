## 🚀 Fetching Data

Exponea SDK has some methods to retrieve your data from the Exponea APP.
All the responses will be available in a completion handler closure.

#### Get customer property

Retrieve a property from a customer.

```
public func fetchProperty(with type: String, completion: @escaping (Result<StringResponse>) -> Void)
```

#### 💻 Usage

```
Exponea.shared.fetchProperty(with: "first_name") { (result) in
	// SDK will return a StringResponse object.
}
```

#### Get customer ID

Retrieve a Id from a customer. The ID is the name of external ID that you want to retrieve

```
public func fetchId(with id: String, completion: @escaping (Result<StringResponse>) -> Void)
```

#### 💻 Usage

```
Exponea.shared.fetchId(with: "registered") { (result) in
	// SDK will return a StringResponse object.
}
```

#### Get customer Expression

Retrieve an expression from a customer. The ID is the identification of the expression that you want to retrieve

```
public func fetchExpression(with id: String, completion: @escaping (Result<EntityValueResponse>) -> Void)
```

#### 💻 Usage

```
Exponea.shared.fetchExpression(with: "my_expression") { (result) in
	// SDK will return a EntityValueResponse object.
}
```

#### Get customer Prediction

Retrieve a prediction from a customer. The ID is the identification of the prediction that you want to retrieve

```
public func fetchPrediction(with id: String, completion: @escaping (Result<EntityValueResponse>) -> Void)
```

#### 💻 Usage

```
Exponea.shared.fetchPrediction(with: "my_prediction") { (result) in
	// SDK will return a EntityValueResponse object.
}
```

#### Get customer recommendation

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

#### Get customer attributes

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

#### Get customer events

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

#### Get all properties from a customer

Export all the properties for a specific customer.

```
public func fetchAllProperties(completion: @escaping (Result<[StringResponse]>) -> Void)
```

#### 💻 Usage

```
// Call fetchAllProperties to get the properties.
Exponea.shared.fetchAllProperties { (result) in
  	// SDK will return a array of StringResponse object.
}
```

#### Get all Customers from a project

Export all customers for a specific project.

```
public func fetchAllCustomers(with request: CustomerExportRequest,
                              completion: @escaping (Result<[StringResponse]>) -> Void)
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

let attributes = AttributesListDescription(
        type: "some",
        list: [attributes]
)

let request = CustomerExportRequest(
        attributes = ["session_start", "payment"],
        filter = ["type": JSONValue.string("segment"),
                  "segmentation_id": JSONValue.string("592ff585fb60094e02bfaf6a")],
        executionTime = 123456,
        timezone = "Europe/Bratislava",
        responseFormat = ExportFormat.nativeJSON
)

// Call fetchAllCustomers to get the customers.
Exponea.shared.fetchAllCustomers(with: request) { (result) in
  	// SDK will return a array of StringResponse object.
}
```

#### Get all properties from a customer

Export all the properties for a specific customer.

```
public func anonymize(completion: @escaping (Result<StringResponse>) -> Void)
```

#### 💻 Usage

```
// Call anonymize to get the properties.
Exponea.shared.anonymize { (result) in
  	// SDK will return a StringResponse object.
}
```
