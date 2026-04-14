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
    override func spec() {
        context("should parse recommendation response") {
            let options = RecommendationOptions(id: "", fillWithRandom: false)
            
            it("for integrationConfig - streamId") {
                let responseData = TestStream.mockResponse.data(using: .utf8)
                let configuration = try! Configuration(
                    integrationConfig: Exponea.StreamSettings(
                        streamId: UUID().uuidString,
                        baseUrl: "https://mock-base-url.com"
                    )
                )
                fetchTestRecommendation(
                    configuration: configuration,
                    options: options,
                    responseData: responseData,
                    responseValues: TestStream.responseValues
                )
            }
            it("for integrationConfig - projectToken") {
                let responseData = TestProject.mockResponse.data(using: .utf8)
                let configuration = try! Configuration(
                    integrationConfig: Exponea.ProjectSettings(
                        projectToken: UUID().uuidString,
                        authorization: .token("mock-token"),
                        baseUrl: "https://mock-base-url.com"
                    )
                )
                fetchTestRecommendation(
                    configuration: configuration,
                    options: options,
                    responseData: responseData,
                    responseValues: TestProject.responseValues
                )
            }
            it("for deprecated - projectToken") {
                let responseData = TestProject.mockResponse.data(using: .utf8)
                let configuration = try! Configuration(
                    projectToken: UUID().uuidString,
                    authorization: .token("mock-token"),
                    baseUrl: "https://mock-base-url.com"
                )
                fetchTestRecommendation(
                    configuration: configuration,
                    options: options,
                    responseData: responseData,
                    responseValues: TestProject.responseValues
                )
            }
            
            func fetchTestRecommendation<T: RecommendationUserData>(
                configuration: Configuration,
                options: RecommendationOptions,
                responseData: Data?,
                responseValues: [Recommendation<T>]
            ) {
                NetworkStubbing.stubNetwork(
                    forIntegrationType: configuration.integrationConfig.type,
                    withStatusCode: 200,
                    withResponseData: responseData
                )
                waitUntil(timeout: .seconds(5)) { done in
                    ServerRepository(configuration: configuration).fetchRecommendation(
                        options: options,
                        for: ["cookie": "mock cookie"],
                        completion: { (result: Result<RecommendationResponse<T>>) in
                            expect(result.value?.value).to(equal(responseValues))
                            done()
                        }
                    )
                }
            }
        }
        
        context("should fail when recommendation ID doesnt exist - error code 500 (only when integrationConfig - stream)") {
            let options = RecommendationOptions(id: "randomstring", fillWithRandom: false)
            let responseData = "Test recommendation ID does not exist".data(using: .utf8)
            let configuration = try! Configuration(
                integrationConfig: Exponea.StreamSettings(
                    streamId: UUID().uuidString,
                    baseUrl: "https://mock-base-url.com"
                )
            )
            NetworkStubbing.stubNetwork(
                forIntegrationType: .stream(streamId: configuration.integrationId),
                withStatusCode: 500,
                withResponseData: responseData
            )
            waitUntil(timeout: .seconds(5)) { done in
                ServerRepository(configuration: configuration).fetchRecommendation(
                    options: options,
                    for: ["cookie": "mock cookie"],
                    completion: { (result: Result<RecommendationResponse<TestStream.MyResponseData>>) in
                        switch result {
                        case .failure(let error):
                            if let repositoryError = error as? RepositoryError {
                                switch repositoryError {
                                case .missingData(let errorMessage):
                                    expect(errorMessage).to(equal("Test recommendation ID does not exist"))
                                default:
                                    XCTFail("Test should fail with different error.")
                                }
                            } else {
                                XCTFail("Test should fail with different error.")
                            }
                        default:
                            XCTFail("Test should fail with error.")
                        }
                        done()
                    }
                )
            }
        }
    }
}

// MARK: - Test mock data and structures

private struct TestProject {
    struct MyResponseData: RecommendationUserData {
        let name: String
        let image: String
        let price: Double
        let description: String
    }
    
    static let responseValues: [Recommendation<TestProject.MyResponseData>] = [
        Recommendation<TestProject.MyResponseData>(
            systemData: RecommendationSystemData(
                engineName: "random",
                itemId: "1",
                recommendationId: "5dd6af3d147f518cb457c63c",
                recommendationVariantId: nil
            ),
            userData: TestProject.MyResponseData(
                name: "book",
                image: "no image available",
                price: 19.99,
                description: "an awesome book"
            )
        ),
        Recommendation<TestProject.MyResponseData>(
            systemData: RecommendationSystemData(
                engineName: "random",
                itemId: "3",
                recommendationId: "5dd6af3d147f518cb457c63c",
                recommendationVariantId: "mock id"
            ),
            userData: TestProject.MyResponseData(
                name: "mobile phone",
                image: "just google one",
                price: 499.99,
                description: "super awesome off-brand phone"
            )
        )
    ]
    
    static let mockResponse = """
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
}

private struct TestStream {
    struct MyResponseData: RecommendationUserData {
        let brand: String
        let description: String
        let image: String
        let price: Double
        let productId: String
        let recommendationSource: String
        let title: String
        
        enum CodingKeys: String, CodingKey {
            case brand
            case description
            case image
            case price
            case productId = "product_id"
            case recommendationSource = "recommendation_source"
            case title
        }
    }
    
    static let responseValues: [Recommendation<TestStream.MyResponseData>] = [
        Recommendation<TestStream.MyResponseData>(
            systemData: RecommendationSystemData(
                engineName: "random",
                itemId: "002",
                recommendationId: "685a99f9e66ef0389c323250",
                recommendationVariantId: nil
            ),
            userData: TestStream.MyResponseData(
                brand: "11111",
                description: "Desc 1",
                image: "no image available",
                price: 12.3,
                productId: "Laptop",
                recommendationSource: "fallback",
                title: "Title 1"
            )
        ),
        Recommendation<TestStream.MyResponseData>(
            systemData: RecommendationSystemData(
                engineName: "random",
                itemId: "6",
                recommendationId: "685a99f9e66ef0389c323250",
                recommendationVariantId: nil
            ),
            userData: TestStream.MyResponseData(
                brand: "22222",
                description: "Desc 2",
                image: "no image available",
                price: 45.6,
                productId: "TV",
                recommendationSource: "fallback",
                title: "Title 2"
            )
        )
    ]
    
    static let mockResponse: String = """
        {
            "data": [
                {
                    "brand": "11111",
                    "description": "Desc 1",
                    "image": "no image available",
                    "price": 12.3,
                    "title": "Title 1",
                    "engine_name": "random",
                    "item_id": "002",
                    "product_id": "Laptop",
                    "recommendation_id": "685a99f9e66ef0389c323250",
                    "recommendation_source": "fallback",
                    "recommendation_variant_id": null
                },
                {
                    "brand": "22222",
                    "description": "Desc 2",
                    "image": "no image available",
                    "price": 45.6,
                    "title": "Title 2",
                    "engine_name": "random",
                    "item_id": "6",
                    "product_id": "TV",
                    "recommendation_id": "685a99f9e66ef0389c323250",
                    "recommendation_source": "fallback",
                    "recommendation_variant_id": null
                }
          ],
          "errors": "[]",
          "success": true
        }
    """
}
