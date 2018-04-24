//
//  ConnectionManagerType.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol TrackingRepository {
    func trackCustomer(projectToken: String, customerId: KeyValueItem, properties: [KeyValueItem])
    func trackEvents(projectToken: String, customerId: KeyValueItem, properties: [KeyValueItem],
                     timestamp: Double?, eventType: String?)
}

protocol TokenRepository {
    func rotateToken(projectToken: String)
    func revokeToken(projectToken: String)
}

protocol FetchRepository {
    func fetchProperty(projectToken: String, customerId: KeyValueItem, property: String)
    func fetchId(projectToken: String, customerId: KeyValueItem, id: String)
    func fetchSegmentation(projectToken: String, customerId: KeyValueItem, id: String)
    func fetchExpression(projectToken: String, customerId: KeyValueItem, id: String)
    func fetchPrediction(projectToken: String, customerId: KeyValueItem, id: String)
    func fetchRecommendation(projectToken: String,
                             customerId: KeyValueItem,
                             recommendation: CustomerRecommendation,
                             completion: @escaping (Result<Recommendation>) -> Void)
    func fetchAttributes(projectToken: String,
                         customerId: KeyValueItem,
                         attributes: [CustomerAttributes])
    func fetchEvents(projectToken: String,
                     customerId: KeyValueItem,
                     events: FetchEventsRequest,
                     completion: @escaping (Result<FetchEventsResponse>) -> Void)
    func fetchAllProperties(projectToken: String, customerId: KeyValueItem)
    func fetchAllCustomers(projectToken: String, data: CustomerExportModel)
    func anonymize(projectToken: String, customerId: KeyValueItem)
}

protocol ConnectionManagerType: class, TrackingRepository, TokenRepository, FetchRepository {
    var configuration: Configuration { get set }
}
