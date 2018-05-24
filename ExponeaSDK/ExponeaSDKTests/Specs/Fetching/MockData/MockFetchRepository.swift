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

    func fetchProperty(projectToken: String, customerId: [String: JSONConvertible], property: String) {
        return
    }

    func fetchId(projectToken: String, customerId: [String: JSONConvertible], id: String) {
        return
    }

    func fetchSegmentation(projectToken: String, customerId: [String: JSONConvertible], id: String) {
        return
    }

    func fetchExpression(projectToken: String, customerId: [String: JSONConvertible], id: String) {
        return
    }

    func fetchPrediction(projectToken: String, customerId: [String: JSONConvertible], id: String) {
        return
    }

    func fetchRecommendation(projectToken: String,
                             customerId: [String: JSONConvertible],
                             recommendation: CustomerRecommendation,
                             completion: @escaping (Result<Recommendation>) -> Void) {

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
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            trackingParam: nil, customersParam: parameters)
        let bundle = Bundle(for: type(of: self))

        guard request.url != nil else {
            fatalError("URL could not be retrieve")
        }

        guard
            let file = bundle.url(forResource: "get-recommendation", withExtension: "json"),
            let data = try? Data(contentsOf: file),
            let recommendation = try? JSONDecoder().decode(Recommendation.self, from: data)
            else {
                fatalError("Something is horribly wrong with the data.")
        }

        let result = Result.success(recommendation)

        completion(result)
    }

    func fetchAttributes(projectToken: String, customerId: [String: JSONConvertible], attributes: [CustomerAttributes]) {
        return
    }

    func fetchEvents(projectToken: String,
                     customerId: [String: JSONConvertible],
                     events: FetchEventsRequest,
                     completion: @escaping (Result<FetchEventsResponse>) -> Void) {
        return
    }

    func fetchAllProperties(projectToken: String, customerId: [String: JSONConvertible]) {
        return
    }

    func fetchAllCustomers(projectToken: String, data: CustomerExportModel) {
        return
    }

    func anonymize(projectToken: String, customerId: [String: JSONConvertible]) {
        return
    }

}

extension MockFetchRepository: ConnectionManagerType {
    func trackCustomer(projectToken: String,
                       customerId: [String: JSONConvertible],
                       properties: [[String: JSONConvertible]]) {
        return
    }

    func trackEvent(projectToken: String,
                     customerId: [String: JSONConvertible],
                     properties: [[String: JSONConvertible]],
                     timestamp: Double?,
                     eventType: String?) {
        return
    }

    func rotateToken(projectToken: String) {
        return
    }
    func revokeToken(projectToken: String) {
        return
    }
}
