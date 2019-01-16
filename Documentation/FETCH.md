## 🚀 Fetching Data

Exponea SDK has some methods to retrieve your data from the Exponea APP.
All the responses will be available in a completion handler closure.

#### Get customer recommendation

> **NOTE:** Requires Token authorization

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

