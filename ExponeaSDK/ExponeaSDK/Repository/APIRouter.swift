//
//  APIRouter.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 09/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Path route with projectId
struct APIRouter {
    var baseURL: String
    var projectId: String
    var route: Routes

    init(baseURL: String, projectId: String, route: Routes) {
        self.baseURL = baseURL
        self.projectId = projectId
        self.route = route
    }

    var path: String {
        switch self.route {
        case .trackCustomers: return baseURL + "track/v2/\(projectId)/customers"
        case .trackEvents: return baseURL + "track/v2/\(projectId)/events"
        case .tokenRotate: return baseURL + "data/v2/\(projectId)/tokens/rotate"
        case .tokenRevoke: return baseURL + "data/v2/\(projectId)/tokens/revoke"
        case .customersProperty: return baseURL + "data/v2/\(projectId)/customers/property"
        case .customersId: return baseURL + "data/v2/\(projectId)/customers/id"
        case .customersSegmentation: return baseURL + "data/v2/\(projectId)/customers/segmentation"
        case .customersExpression: return baseURL + "data/v2/\(projectId)/customers/expression"
        case .customersPrediction: return baseURL + "data/v2/\(projectId)/customers/prediction"
        case .customersRecommendation: return baseURL + "data/v2/\(projectId)/customers/recommendation"
        case .customersAttributes: return baseURL + "/data/v2/\(projectId)/customers/attributes"
        case .customersEvents: return baseURL + "/data/v2/\(projectId)/customers/events"
        case .customersAnonymize: return baseURL + "/data/v2/\(projectId)/customers/anonymize"
        case .customersExportAllProperties: return baseURL + "/data/v2/\(projectId)/customers/export-one"
        case .customersExportAll: return baseURL + "/data/v2/\(projectId)/customers/export"
        }
    }

    var method: HTTPMethod { return .post }
}

struct TrackingParams {
    var customer: KeyValueModel
    var properties: [KeyValueModel]
    var timestamp: Int?
    var eventType: String?

    init(customer: KeyValueModel, properties: [KeyValueModel], timestamp: Int?, eventType: String?) {
        self.customer = customer
        self.properties = properties
        self.timestamp = timestamp
        self.eventType = eventType
    }

    var params: [String: Any]? {

        var preparedParam: [String: Any] = [:]

        /// Preparing customers_ids params
        var customerParam: [String: Any] {
            return [
                customer.key: customer.value
            ]
        }
        preparedParam["customer_ids"] = customerParam

        /// Preparing properties param
        let propertiesParam = properties.flatMap({[$0.key: $0.value]})
        preparedParam["properties"] = propertiesParam

        /// Preparing timestamp param
        if let timestamp = timestamp {
            preparedParam["timestamp"] = timestamp
        }
        /// Preparing eventType param
        if let eventType = eventType {
            preparedParam["event_type"] = eventType
        }

        return preparedParam
    }
}

struct CustomersParams {
    var customer: KeyValueModel?
    var property: String?
    var id: String?
    var recommendation: CustomerRecommendModel?
    var attributes: [CustomerAttributesListModel]?
    var events: CustomerEventsModel?
    var data: CustomerExportModel?

    init(customer: KeyValueModel?, property: String?, id: String?, recommendation: CustomerRecommendModel?, attributes: [CustomerAttributesListModel]?, events: CustomerEventsModel?, data: CustomerExportModel?) {
        self.customer = customer
        self.property = property
        self.id = id
        self.recommendation = recommendation
        self.attributes = attributes
        self.events = events
        self.data = data
    }

    var params: [String: Any]? {

        var preparedParam: [String: Any] = [:]
        var list: [String: Any] = [:]
        var listAppend = [list]
        var filterList: [String: Any] = [:]
        var attributeComplete: [String: Any] = [:]

        /// Preparing customers_ids params
        if let customer = customer {
            var customerParam: [String: Any] {
                return [
                    customer.key: customer.value
                ]
            }
            preparedParam["customer_ids"] = customerParam
        }

        /// Preparing property param
        if let property = property {
            preparedParam["property"] = property
        }
        /// Preparing id param
        if let id = id {
            preparedParam["id"] = id
        }
        /// Preparing recommendation param
        if let recommendation = recommendation {
            if let size = recommendation.size {
                preparedParam["size"] = size
            }
            if let strategy = recommendation.strategy {
                preparedParam["strategy"] = strategy
            }
            if let knowItems = recommendation.knowItems {
                preparedParam["consider_known_items"] = knowItems
            }
            if let anti = recommendation.anti {
                preparedParam["anti"] = anti
            }
            if let items = recommendation.items {
                for item in items {
                    list[item.key] = item.value
                }
                preparedParam["item"] = list
                list.removeAll()
            }
        }
        /// Preparing attributes param
        if let attributes = attributes {
            for attribute in attributes {
                list[attribute.typeKey] = attribute.typeValue
                list[attribute.identificationKey] = attribute.identificationValue
                listAppend.append(list)
            }

            preparedParam["attributes"] = listAppend
            listAppend.removeAll()
            list.removeAll()
        }
        /// Preparing events param
        if let events = events {
            preparedParam["event_types"] = events.eventTypes
            preparedParam["order"] = events.sortOrder
            preparedParam["limit"] = events.limit
            preparedParam["skip"] = events.skip
        }
        /// Preparing data param
        if let data = data {
            for attrib in data.attributes.list {
                list[attrib.typeKey] = attrib.typeValue
                list[attrib.identificationKey] = attrib.identificationValue
                listAppend.append(list)
            }

            for filter in data.filter {
                filterList[filter.key] = filter.value
            }

            attributeComplete["type"] = data.attributes.type
            attributeComplete["list"] = listAppend

            preparedParam["attributes"] = attributeComplete
            preparedParam["filter"] = filterList
            preparedParam["execution_time"] = data.executionTime
            preparedParam["timezone"] = data.timezone
            preparedParam["format"] = data.responseFormat

            list.removeAll()
            listAppend.removeAll()
        }

        return preparedParam
    }
}
