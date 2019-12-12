//
//  ServerRepositoryFetchRecommendationsSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 12/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

@testable import ExponeaSDK

final class ServerRepositoryFetchRecommendationsSpec: QuickSpec {
    let payload = """
    {
      "results": [
        {
          "success": true,
          "value": [
            {
              "description": "an awesome book",
              "engine_name": "random",
              "image": "no image available",
              "item_id": "1",
              "name": "book",
              "price": 19.99,
              "product_id": "1",
              "recommendation_id": "5dd6af3d147f518cb457c63c",
              "recommendation_variant_id": null
            },
            {
              "description": "super awesome off-brand phone",
              "engine_name": "random",
              "image": "just google one",
              "item_id": "3",
              "name": "mobile phone",
              "price": 499.99,
              "product_id": "3",
              "recommendation_id": "5dd6af3d147f518cb457c63c",
              "recommendation_variant_id": "mock id"
            }
          ]
        }
      ],
      "success": true
    }
    """

    struct MyRecommendationData: RecommendationUserData {
        let name: String
        let image: String
        let price: Double
        let description: String

        public init(name: String, image: String, price: Double, description: String) {
            self.name = name
            self.image = image
            self.price = price
            self.description = description
        }
    }

    override func spec() {
        let configuration = try! Configuration(
            projectToken: UUID().uuidString,
            authorization: .token("mock-token"),
            baseUrl: "https://mock-base-url.com"
        )
        let request = RecommendationRequest(options: RecommendationOptions(id: "", fillWithRandom: false))

        it("should parse recommendation response") {
            NetworkStubbing.stubNetwork(
                forProjectToken: configuration.projectToken!,
                withStatusCode: 200,
                withResponseData: self.payload.data(using: .utf8)
            )
            waitUntil { done in
                ServerRepository(configuration: configuration).fetchRecommendation(
                    request: request,
                    for: ["cookie": .string("mock cookie")],
                    completion: { (result: Result<RecommendationResponse<MyRecommendationData>>) in
                        expect(result.value?.value).to(equal(
                            [
                                Recommendation<MyRecommendationData>(
                                    systemData: RecommendationSystemData(
                                        engineName: "random",
                                        itemId: "1",
                                        recommendationId: "5dd6af3d147f518cb457c63c",
                                        recommendationVariantId: nil
                                    ),
                                    userData: MyRecommendationData(
                                        name: "book",
                                        image: "no image available",
                                        price: 19.99,
                                        description: "an awesome book"
                                    )
                                ),
                                Recommendation<MyRecommendationData>(
                                    systemData: RecommendationSystemData(
                                        engineName: "random",
                                        itemId: "3",
                                        recommendationId: "5dd6af3d147f518cb457c63c",
                                        recommendationVariantId: "mock id"
                                    ),
                                    userData: MyRecommendationData(
                                        name: "mobile phone",
                                        image: "just google one",
                                        price: 499.99,
                                        description: "super awesome off-brand phone"
                                    )
                                )
                            ]
                        ))
                        done()
                    }
                )
            }
        }
    }
}
