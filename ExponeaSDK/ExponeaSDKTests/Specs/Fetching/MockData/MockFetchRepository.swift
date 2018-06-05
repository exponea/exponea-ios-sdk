//
//  MockFetchRepository.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

@testable import ExponeaSDK

class MockFetchRepository: FetchRepository {
    
    var configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func fetchProperty(projectToken: String, customerId: [String: JSONValue], property: String) {
        return
    }

    func fetchId(projectToken: String, customerId: [String: JSONValue], id: String) {
        return
    }

    func fetchSegmentation(projectToken: String, customerId: [String: JSONValue], id: String) {
        return
    }

    func fetchExpression(projectToken: String, customerId: [String: JSONValue], id: String) {
        return
    }

    func fetchPrediction(projectToken: String, customerId: [String: JSONValue], id: String) {
        return
    }
    
    func fetchProperty(projectToken: String, customerId: [String : JSONConvertible], property: String, completion: @escaping (Result<StringResponse>) -> Void) {
        return
    }
    
    func fetchId(projectToken: String, customerId: [String : JSONConvertible], id: String, completion: @escaping (Result<StringResponse>) -> Void) {
        return
    }
    
    func fetchExpression(projectToken: String, customerId: [String : JSONConvertible], id: String, completion: @escaping (Result<EntityValueResponse>) -> Void) {
        return
    }
    
    func fetchPrediction(projectToken: String, customerId: [String : JSONConvertible], id: String, completion: @escaping (Result<EntityValueResponse>) -> Void) {
        return
    }

    func fetchRecommendation(projectToken: String,
                             customerId: [String: JSONValue],
                             recommendation: RecommendationRequest,
                             completion: @escaping (Result<RecommendationResponse>) -> Void) {

        let router = RequestFactory(baseURL: configuration.baseURL,
                               projectToken: projectToken,
                               route: .customersRecommendation)
        let parameters = CustomerParameters(customer: customerId,
                                              property: nil,
                                              id: nil,
                                              recommendation: recommendation,
                                              attributes: nil,
                                              events: nil,
                                              data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization, parameters: parameters)
        let bundle = Bundle(for: type(of: self))

        guard request.url != nil else {
            fatalError("URL could not be retrieve")
        }

        guard
            let file = bundle.url(forResource: "get-recommendation", withExtension: "json"),
            let data = try? Data(contentsOf: file),
            let recommendation = try? JSONDecoder().decode(RecommendationResponse.self, from: data)
            else {
                fatalError("Something is horribly wrong with the data.")
        }

        let result = Result.success(recommendation)

        completion(result)
    }

    func fetchAttributes(projectToken: String, customerId: [String: JSONValue], attributes: [AttributesDescription]) {
        return
    }

    func fetchEvents(projectToken: String,
                     customerId: [String: JSONValue],
                     events: EventsRequest,
                     completion: @escaping (Result<EventsResponse>) -> Void) {
        return
    }

    func fetchAllProperties(projectToken: String, customerId: [String: JSONValue]) {
        return
    }

    func fetchAllCustomers(projectToken: String, data: CustomerExportRequest) {
        return
    }

    func anonymize(projectToken: String, customerId: [String: JSONValue]) {
        return
    }

}

extension MockFetchRepository: RepositoryType {
    func trackCustomer(with data: [DataType], for customer: Customer, completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
    
    func trackEvent(with data: [DataType], for customer: Customer, completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
    
    func trackEvents(with data: [[DataType]], for customer: Customer, completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
    
    func rotateToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
    
    func revokeToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
}
