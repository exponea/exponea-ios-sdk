## 🚀 Fetching Data

Exponea iOS SDK has some methods to retrieve your data from the Exponea web application. All the responses will be available in a completion handler closure.

### Customer Recommendation

Get items recommended for a customer.

```swift
public func fetchRecommendation<T: RecommendationUserData>(
        with options: RecommendationOptions,
        completion: @escaping (Result<RecommendationResponse<T>>) -> Void
    )
)
```
Resulting object contains the system data (the recommendation engine data and `itemId`) and possibly also the user defined data. Generic parameter `T: RecommendationUserData` is the struct that will contain the fields that you defined for your items in the Exponea web application. It's just a simple struct with coding keys representing the custom fields you defined. If you only need the system properties, you can use `EmptyRecommendationData`.

#### 💻 Usage

```swift

struct MyRecommendation: RecommendationUserData {
    // put all the custom properties on your recommendations into a struct
    // and call fetchRecommendation with it in results callback
}

typealias MyRecommendationResponse = RecommendationResponse<MyRecommendation>

// Preparing the data.
let recommendationOptions = RecommendationOptions(
    id =  "592ff585fb60094e02bfaf6a",
    fillWithRandom = true,
    size = 10
)

// Call fetchRecommendation to get the customer attributes.
Exponea.shared.fetchRecommendation(with: recommendation) { (: Result<MyRecommendationResponse>) in
    if case .success(let recommendation) = result {
        // In case of success, value contains list of recommendations
        print(recommendation.value?[0].userData)
        print(recommendation.value?[0].systemData)
    }
}
```

### Consents
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

