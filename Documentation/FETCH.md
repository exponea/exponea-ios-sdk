## 🚀 Fetching Data

Exponea SDK has some methods to retrieve your data from the Exponea APP.
All the responses will be available in a completion handler closure.

### Customer Recommendation

> **NOTE:** Requires Token authorization

Get items recommended for a customer.

```swift
public func fetchRecommendation(with request: RecommendationRequest,
                                completion: @escaping (Result<RecommendationResponse>) -> Void)
)
```

#### 💻 Usage

```swift
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

### Consents

> **NOTE:** Requires Token authorization

Fetch the list of your existing consent categories.

```swift
public func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void)
```

#### 💻 Usage

```swift
// Fetch consents to get existing consent categories.
Exponea.shared.fetchConsents { (result) in
    switch result {
    case .success(let response):
        print(response.data)
        
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

