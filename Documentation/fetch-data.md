---
title: Fetch data
excerpt: Fetch data from Bloomreach Engagement using the iOS SDK
slug: ios-sdk-fetch-data
categorySlug: integrations
parentDocSlug: ios-sdk
---

The SDK provides methods to retrieve data from the Engagement platform. Responses are available in a completion handler closure.

## Fetch recommendations

Use the `fetchRecommendation` method to get personalized recommendations for the current customer from an Engagement [recommendation model](https://documentation.bloomreach.com/engagement/docs/recommendations).

The method returns a `RecommendationResponse` object containing the system data (the recommendation engine data and recommended item IDs) and, if applicable, the user-defined data. To specify user-defined properties, you can use the generic type parameter `T: RecommendationUserData`. It's a simple `struct` with coding keys representing your custom properties. If you only need the system properties, you can use `EmptyRecommendationData`.

### Arguments

| Name    | Type                  | Description |
| ------- | --------------------- | ----------- |
| options | RecommendationOptions | Recommendation options (see below for details )

### RecommendationOptions

| Name                       | Type             | Description |
| -------------------------- | ---------------- | ----------- |
| id (required)              | String           | ID of your recommendation model. |
| fillWithRandom             | Bool             | If true, fills the recommendations with random items until size is reached. This is utilized when models cannot recommend enough items. |
| size                       | Int              | Specifies the upper limit for the number of recommendations to return. Defaults to 10. |
| items                      | [String: String] | If present, the recommendations are related not only to a customer, but to products with IDs specified in this array. Item IDs from the catalog used to train the recommendation model must be used. Input product IDs in a dictionary as `[product_id: weight]`, where the value weight determines the preference strength for the given product (bigger number = higher preference).<br/><br/>Example:<br/>`["product_id_1": "1", "product_id_2": "2",]` |
| noTrack                    | Bool             | Default value: false |
| catalogAttributesWhitelist | [String]         | Returns only the specified attributes from catalog items. If empty or not set, returns all attributes.<br/><br/>Example:<br/>`["item_id", "title", "link", "image_link"]` |


### Example

```swift
struct MyRecommendation: RecommendationUserData {
    // put all the custom properties on your recommendations into a struct
    // and call fetchRecommendation with it in results callback
    let 
}

typealias MyRecommendationResponse = RecommendationResponse<MyRecommendation>

// Prepare the recommendation options
let recommendationOptions = RecommendationOptions(
    id: "65c2a2bc0827bbe25d2b67cc",
    fillWithRandom: true,
    size: 5,
    items: ["product456":"10", "product123":"1"]
)

// Get recommendations for the current customer
Exponea.shared.fetchRecommendation(with: recommendationOptions) { (result: Result<MyRecommendationResponse>) in
    if case .success(let recommendation) = result {
        // In case of success, value contains list of recommendations
        print(recommendation.value?[0].userData)
        print(recommendation.value?[0].systemData)
    }
}
```

### Return object

#### RecommendationResponse

| Name    | Type                | Description |
| ------- | ------------------- | ----------- |
| success | Bool                | Whether fetching recommendations was successful. |
| error   | String              | Error message if not successful. |
| value   | [Recommendation<T>] | An array of recommendations. |

#### Recommendation

| Name       | Type                      | Description |
| ---------- | ------------------------- | ----------- |
| systemData | RecommendationSystemData  | System data returned from the server. |
| userData   | T: RecommendationUserData | User-defined data returned from the server. Use your own struct implementing `RecommendationUserData`, data will be decoded into it. |

#### RecommendationSystemData

| Name                    | Type   | Description |
| ----------------------- | ------ | ----------- |
| engineName              | String | Name of the recommendation engine used. |
| itemId                  | String | ID of the recommended item. |
| recommendationId        | String | ID of the recommendation engine (model) used. |
| recommendationVariantId | String | ID of the recommendation engine variant used. |

## Fetch consent categories

Use the `fetchConsents` method to get a list of your consent categories and their definitions.

Use when you want to get a list of your existing consent categories and their properties, such as sources and translations. This is useful when rendering a consent form.

The method returns a `ConsentsResponse` object containing an array of `Consent` objects.

### Example

```swift
// Fetch consents to get existing consent categories.
Exponea.shared.fetchConsents { (result) in
    switch result {
    case .success(let response):
        print(response.consents)
        
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

### Result object

#### ConsentsResponse

| Name     | Type      | Description |
| -------- | --------- | ----------- |
| consents | [Consent] | Contains an array of consent categories. |

#### Consent

| Name               | Type                       | Description |
| -------------------| -------------------------- | ----------- |
| id                 | String                     | Name of the consent category. |
| legitimateInterest | Bool                       | If the user has legitimate interest. |
| sources            | ConsentSources             | The sources of this consent. |
| translations       | [String: [String: String]] | Contains the translations for the consent.<br/><br/>Keys of this dictionary are the short ISO language codes (eg. "en", "cz", "sk"...) and the values are dictionaries containing the translation key as the dictionary key and translation value as the dictionary value. |

#### ConsentSources

| Name                  | Type | Description |
| ----------------------| -------------------------- | ----------- |
| isCreatedFromCRM      | Bool | Manually created from the web application. |
| isImported            | Bool | Imported from the importing wizard. |
| isFromConsentPage     | Bool | Tracked from the consent page. |
| privateAPI            | Bool | API which uses basic authentication. |
| publicAPI             | Bool | API which only uses public token for authentication. |
| isTrackedFromScenario | Bool | Tracked from the scenario from event node. |
