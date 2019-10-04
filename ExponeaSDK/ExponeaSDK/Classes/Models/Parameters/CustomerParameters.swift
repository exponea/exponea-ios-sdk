//
//  CustomerParameters.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 24/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// A Group of parameters used to update any kind of customer properties.
/// Depending on what king of tracking, you can use a combination of properties.
struct CustomerParameters {
    /// Customer identification.
    var customer: [String: JSONValue]
    /// Name of the property.
    var property: String?
    /// Customer identification.
    var id: String?
    /// Customer recommendation.
    var recommendation: RecommendationRequest?
    /// Array of customer attribytes.
    var attributes: [AttributesDescription]?
    /// Customer events.
    var events: EventsRequest?
    /// Customer data to export multiple properties.
    var data: CustomerExportRequest?

    init(customer: [String: JSONValue],
         property: String? = nil,
         id: String? = nil,
         recommendation: RecommendationRequest? = nil,
         attributes: [AttributesDescription]? = nil,
         events: EventsRequest? = nil,
         data: CustomerExportRequest? = nil) {

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
    var parameters: [String: JSONValue] {

        var preparedParam: [String: JSONValue] = [:]
        var list: [String: JSONValue] = [:]
        var listAppend = [list]
        var filterList: [String: JSONValue] = [:]
        var attributeComplete: [String: JSONValue] = [:]

        /// Preparing customers_ids params
        preparedParam["customer_ids"] =  .dictionary(customer)

        /// Preparing property param
        if let property = property {
            preparedParam["property"] = .string(property)
        }
        /// Preparing id param
        if let id = id {
            preparedParam["id"] = .string(id)
        }
        /// Preparing recommendation param
        if let recommendation = recommendation {

            preparedParam["type"] = .string(recommendation.type)
            preparedParam["id"] = .string(recommendation.id)

            if let size = recommendation.size {
                preparedParam["size"] = .int(size)
            }
            if let strategy = recommendation.strategy {
                preparedParam["strategy"] = .string(strategy)
            }
            if let knowItems = recommendation.knowItems {
                preparedParam["consider_known_items"] = .bool(knowItems)
            }
            if let anti = recommendation.anti {
                preparedParam["anti"] = .bool(anti)
            }
            if let items = recommendation.items {
                for item in items {
                    list[item.key] = item.value
                }
                preparedParam["item"] = .dictionary(list)
                list.removeAll()
            }
        }
        /// Preparing attributes param
        if let attributes = attributes {
            for attribute in attributes {
                list[attribute.typeKey] = .string(attribute.typeValue)
                list[attribute.identificationKey] = .string(attribute.identificationValue)
                listAppend.append(list)
            }

            preparedParam["attributes"] = .array(listAppend.map({ JSONValue.dictionary($0) }))
            listAppend.removeAll()
            list.removeAll()
        }
        /// Preparing events param
        if let events = events {
            preparedParam["event_types"] = .array(events.eventTypes.map({ JSONValue.string($0) }))
            if let sortOrder = events.sortOrder {
                preparedParam["order"] = .string(sortOrder)
            }
            if let limit = events.limit {
                preparedParam["limit"] = .int(limit)
            }

            if let skip = events.skip {
                preparedParam["skip"] = .int(skip)
            }
        }
        /// Preparing data param
        if let data = data {
            if let attributes = data.attributes {
                for attrib in attributes.list {
                    list[attrib.typeKey] = .string(attrib.typeValue)
                    list[attrib.identificationKey] = .string(attrib.identificationValue)
                    listAppend.append(list)
                }

                attributeComplete["type"] = .string(attributes.type)
            }

            if let filters = data.filter {
                for filter in filters {
                    filterList[filter.key] = filter.value
                }
            }

            attributeComplete["list"] = .array(listAppend.map({ JSONValue.dictionary($0) }))

            preparedParam["attributes"] = .dictionary(attributeComplete)
            preparedParam["filter"] = .dictionary(filterList)

            if let time = data.executionTime {
                preparedParam["execution_time"] = .double(Double(time))
            }

            if let timezone = data.timezone {
                preparedParam["timezone"] = .string(timezone)
            }
            preparedParam["format"] = .string(data.responseFormat.rawValue)

            list.removeAll()
            listAppend.removeAll()
        }

        return preparedParam
    }
}
