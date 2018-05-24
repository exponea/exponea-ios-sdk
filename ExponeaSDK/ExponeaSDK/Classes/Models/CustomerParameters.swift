//
//  CustomerParameters.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 24/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol RequestParametersType {
    var parameters: [String: JSONConvertible] { get }
}

struct CustomerParameters {
    var customer: [String: JSONConvertible]?
    var property: String?
    var id: String?
    var recommendation: CustomerRecommendation?
    var attributes: [CustomerAttributes]?
    var events: FetchEventsRequest?
    var data: CustomerExportModel?

    init(customer: [String: JSONConvertible]?,
         property: String?,
         id: String?,
         recommendation: CustomerRecommendation?,
         attributes: [CustomerAttributes]?,
         events: FetchEventsRequest?,
         data: CustomerExportModel?) {

        self.customer = customer
        self.property = property
        self.id = id
        self.recommendation = recommendation
        self.attributes = attributes
        self.events = events
        self.data = data
    }
}

extension CustomerParameters: RequestParametersType {
    var parameters: [String: JSONConvertible] {
        
        var preparedParam: [String: JSONConvertible] = [:]
        var list: [String: JSONConvertible] = [:]
        var listAppend = [list]
        var filterList: [String: JSONConvertible] = [:]
        var attributeComplete: [String: JSONConvertible] = [:]
        
        /// Preparing customers_ids params
        if let customer = customer {
            preparedParam["customer_ids"] = customer
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
            
            preparedParam["type"] = recommendation.type
            preparedParam["id"] = recommendation.id
            
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
