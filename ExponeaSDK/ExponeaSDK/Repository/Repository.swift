//
//  Repository.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct CustomerRecommendModel {
    public var size: Int?
    public var strategy: String?
    public var knowItems: Bool?
    public var anti: Bool?
    public var items: [KeyValueModel]?
}

public struct CustomerEventsModel {
    public var eventTypes: [String]
    public var sortOrder: String = "asc"
    public var limit: Int = 1
    public var skip: Int = 100
}

public struct CustomerExportModel {
    public var attributes: CustomerExportAttributesModel
    public var filter: [KeyValueModel]
    public var executionTime: Int
    public var timezone: String
    public var responseFormat: String
}

public struct CustomerExportAttributesModel {
    public var type: String
    public var list: [CustomerAttributesListModel]
}

public struct CustomerAttributesListModel {
    public var typeKey: String
    public var typeValue: String
    public var identificationKey: String
    public var identificationValue: String
}

protocol TrackingRepository {
    func trackCustumer(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel])
    func trackEvents(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel],
                     timestamp: Double?, eventType: String?)
}

protocol TokenRepository {
    func rotateToken(projectToken: String)
    func revokeToken(projectToken: String)
}

protocol FetchCustomerRepository {
    func fetchProperty(projectToken: String, customerId: KeyValueModel, property: String)
    func fetchId(projectToken: String, customerId: KeyValueModel, id: String)
    func fetchSegmentation(projectToken: String, customerId: KeyValueModel, id: String)
    func fetchExpression(projectToken: String, customerId: KeyValueModel, id: String)
    func fetchPrediction(projectToken: String, customerId: KeyValueModel, id: String)
    func fetchRecommendation(projectToken: String, customerId: KeyValueModel, id: String,
                             recommendation: CustomerRecommendModel?)
    func fetchAttributes(projectToken: String, customerId: KeyValueModel, attributes: [CustomerAttributesListModel])
    func fetchEvents(projectToken: String, customerId: KeyValueModel, events: CustomerEventsModel)
    func fetchAllProperties(projectToken: String, customerId: KeyValueModel)
    func fetchAllCustomers(projectToken: String, data: CustomerExportModel)
    func anonymize(projectToken: String, customerId: KeyValueModel)
}
