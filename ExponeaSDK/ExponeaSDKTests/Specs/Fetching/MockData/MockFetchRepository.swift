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

    let configuration: Configuration
    let apiSource = APISource()

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func fetchProperty(projectToken: String, customerId: KeyValueModel, property: String) {
        return
    }

    func fetchId(projectToken: String, customerId: KeyValueModel, id: String) {
        return
    }

    func fetchSegmentation(projectToken: String, customerId: KeyValueModel, id: String) {
        return
    }

    func fetchExpression(projectToken: String, customerId: KeyValueModel, id: String) {
        return
    }

    func fetchPrediction(projectToken: String, customerId: KeyValueModel, id: String) {
        return
    }

    func fetchRecommendation(projectToken: String,
                             customerId: KeyValueModel,
                             recommendation: CustomerRecommendation,
                             completion: @escaping (Result<Recommendation>) -> Void) {

        let router = APIRouter(baseURL: configuration.baseURL,
                               projectToken: projectToken,
                               route: .customersRecommendation)
        let customersParams = CustomersParams(customer: customerId,
                                              property: nil,
                                              id: nil,
                                              recommendation: recommendation,
                                              attributes: nil,
                                              events: nil,
                                              data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)
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

    func fetchAttributes(projectToken: String, customerId: KeyValueModel, attributes: [CustomerAttributes]) {
        return
    }

    func fetchEvents(projectToken: String,
                     customerId: KeyValueModel,
                     events: CustomerEvents,
                     completion: @escaping (Result<Events>) -> Void) {
        return
    }

    func fetchAllProperties(projectToken: String, customerId: KeyValueModel) {
        return
    }

    func fetchAllCustomers(projectToken: String, data: CustomerExportModel) {
        return
    }

    func anonymize(projectToken: String, customerId: KeyValueModel) {
        return
    }

}

extension MockFetchRepository: ConnectionManagerType {
    func trackCustumer(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel]) {
        return
    }
    func trackEvents(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel], timestamp: Double?, eventType: String?) {
        return
    }
    func rotateToken(projectToken: String) {
        return
    }
    func revokeToken(projectToken: String) {
        return
    }
}
