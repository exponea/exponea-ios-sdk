//
//  APISource.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 05/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// APISource class is responsible to prepare the data used in the http request.
/// It receives all inputs for the call and return a NSMutableURLRequest.
public class APISource {

    func prepareRequest(withURL url: String) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)

        return request
    }

    func prepareRequest(withURL url: String, customerId: KeyValueModel) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()

        var customerParam: [String: Any] {
            return [
                customerId.key: customerId.value
            ]
        }

        let params: [String: Any] = [
            "customer_ids": customerParam
        ]

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }

    func prepareRequest(withURL url: String, customerId: KeyValueModel, properties: [KeyValueModel]) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()

        var customerParam: [String: Any] {
            return [
                customerId.key: customerId.value
            ]
        }

        let propertiesParam = properties.flatMap({[$0.key: $0.value]})

        let params: [String: Any] = [
            "customer_ids": customerParam,
            "properties": propertiesParam
        ]

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }

    func prepareRequest(withURL url: String, customerId: KeyValueModel, properties: [KeyValueModel], timestamp: Int, eventType: String) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()

        var customerParam: [String: Any] {
            return [
                customerId.key: customerId.value
            ]
        }

        let propertiesParam = properties.flatMap({[$0.key: $0.value]})

        let params: [String: Any] = [
            "customer_ids": customerParam,
            "timestamp": timestamp,
            "event_type": eventType,
            "properties": propertiesParam
        ]

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }

    func prepareRequest(withURL url: String, customerId: KeyValueModel, forProperty property: String) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()

        var customerParam: [String: Any] {
            return [
                customerId.key: customerId.value
            ]
        }

        let params: [String: Any] = [
            "customer_ids": customerParam,
            "property": property
        ]

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }

    func prepareRequest(withURL url: String, customerId: KeyValueModel, forId id: String) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()

        var customerParam: [String: Any] {
            return [
                customerId.key: customerId.value
            ]
        }

        let params: [String: Any] = [
            "customer_ids": customerParam,
            "id": id
        ]

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }

    func prepareRequest(withURL url: String, customerId: KeyValueModel, forId id: String, withRecommendation recommendation: CustomerRecommendModel?) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()
        var list: [String: Any] = [:]

        var customerParam: [String: Any] {
            return [
                customerId.key: customerId.value
            ]
        }

        var params: [String: Any] = [
            "customer_ids": customerParam,
            "id": id
        ]

        if let size = recommendation?.size {
            params["size"] = size
        }
        if let strategy = recommendation?.strategy {
            params["strategy"] = strategy
        }
        if let knowItems = recommendation?.knowItems {
            params["consider_known_items"] = knowItems
        }
        if let anti = recommendation?.anti {
            params["anti"] = anti
        }
        if let items = recommendation?.items {
            for item in items {
                list[item.key] = item.value
            }
            params["item"] = list
        }

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }

    func prepareRequest(withURL url: String, customerId: KeyValueModel, withAttributes attributes: [CustomerAttributesListModel]) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()
        var list: [String: Any] = [:]
        var listAppend = [list]
        var attributeList: [String: Any] = [:]

        var customerParam: [String: Any] {
            return [
                customerId.key: customerId.value
            ]
        }

        var params: [String: Any] = [
            "customer_ids": customerParam
        ]

        for attribute in attributes {
            list[attribute.typeKey] = attribute.typeValue
            list[attribute.identificationKey] = attribute.identificationValue
            listAppend.append(list)
        }

        params["attributes"] = listAppend

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }

    func prepareRequest(withURL url: String, customerId: KeyValueModel, forEvents events: CustomerEventsModel) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()
        var list = [String]()

        var customerParam: [String: Any] {
            return [
                customerId.key: customerId.value
            ]
        }

        let params: [String: Any] = [
            "customer_ids": customerParam,
            "event_types": events.eventTypes,
            "order": events.sortOrder,
            "limit": events.limit,
            "skip": events.skip
        ]

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }

    func prepareRequest(withURL url: String, withData data: CustomerExportModel) -> NSMutableURLRequest {

        let request = NSMutableURLRequest()
        var filterList: [String: Any] = [:]
        var attribute: [String: Any] = [:]
        var attributeList = [attribute]
        var attributeComplete: [String: Any] = [:]

        for attrib in data.attributes.list {
            attribute[attrib.typeKey] = attrib.typeValue
            attribute[attrib.identificationKey] = attrib.identificationValue
            attributeList.append(attribute)
        }

        for filter in data.filter {
            filterList[filter.key] = filter.value
        }

        attributeComplete["type"] = data.attributes.type
        attributeComplete["list"] = attributeList

        let params: [String: Any] = [
            "attributes": attributeComplete,
            "filter": filterList,
            "execution_time": data.executionTime,
            "timezone": data.timezone,
            "format": data.responseFormat
        ]

        let body = try? JSONSerialization.data(withJSONObject: params, options: [])

        request.url = URL(fileURLWithPath: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)
        request.httpBody = body

        return request
    }
}
