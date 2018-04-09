//
//  Repository.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

// FIXME: Remove vv when merging with feature/DatabaseManager

public struct KeyValueModel {
    /// Name of the key in the dictionary
    public var key: String
    /// Value for the key in the dictionary
    public var value: String
}

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

// FIXME: Remove ^^ when merging with feature/DatabaseManager

protocol TrackingRepository {
    func trackCustumer(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel])
    func trackEvents(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel], timestamp: Int, eventType: String)
}

protocol TokenRepository {
    func rotateToken(projectId: String)
    func revokeToken(projectId: String)
}

protocol FetchCustomerRepository {
    func fetchProperty(projectId: String, customerId: KeyValueModel, property: String)
    func fetchId(projectId: String, customerId: KeyValueModel, id: String)
    func fetchSegmentation(projectId: String, customerId: KeyValueModel, id: String)
    func fetchExpression(projectId: String, customerId: KeyValueModel, id: String)
    func fetchPrediction(projectId: String, customerId: KeyValueModel, id: String)
    func fetchRecommendation(projectId: String, customerId: KeyValueModel, id: String, recommendation: CustomerRecommendModel?)
    func fetchAttributes(projectId: String, customerId: KeyValueModel, attributes: [CustomerAttributesListModel])
    func fetchEvents(projectId: String, customerId: KeyValueModel, events: CustomerEventsModel)
    func fetchAllProperties(projectId: String, customerId: KeyValueModel)
    func fetchAllCustomers(projectId: String, data: CustomerExportModel)
    func anonymize(projectId: String, customerId: KeyValueModel)
}
