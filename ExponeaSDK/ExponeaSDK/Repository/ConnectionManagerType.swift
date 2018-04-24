//
//  ConnectionManagerType.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol TrackingRepository {
    func trackCustomer(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel])
    func trackEvents(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel],
                     timestamp: Double?, eventType: String?)
}

protocol TokenRepository {
    func rotateToken(projectToken: String)
    func revokeToken(projectToken: String)
}

protocol FetchRepository {
    func fetchProperty(projectToken: String, customerId: KeyValueModel, property: String)
    func fetchId(projectToken: String, customerId: KeyValueModel, id: String)
    func fetchSegmentation(projectToken: String, customerId: KeyValueModel, id: String)
    func fetchExpression(projectToken: String, customerId: KeyValueModel, id: String)
    func fetchPrediction(projectToken: String, customerId: KeyValueModel, id: String)
    func fetchRecommendation(projectToken: String,
                             customerId: KeyValueModel,
                             recommendation: CustomerRecommendation,
                             completion: @escaping (Result<Recommendation>) -> Void)
    func fetchAttributes(projectToken: String,
                         customerId: KeyValueModel,
                         attributes: [CustomerAttributes])
    func fetchEvents(projectToken: String,
                     customerId: KeyValueModel,
                     events: CustomerEvents,
                     completion: @escaping (Result<Events>) -> Void)
    func fetchAllProperties(projectToken: String, customerId: KeyValueModel)
    func fetchAllCustomers(projectToken: String, data: CustomerExportModel)
    func anonymize(projectToken: String, customerId: KeyValueModel)
}

protocol ConnectionManagerType: class, TrackingRepository, TokenRepository, FetchRepository {
    var configuration: Configuration { get set }
}
