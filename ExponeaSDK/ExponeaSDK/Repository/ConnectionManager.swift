//
//  ConnectionManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

final class ConnectionManager {

    let configuration: APIConfiguration
    private let session = URLSession.shared

    // Initialize the configuration for all HTTP requests
    init(configuration: APIConfiguration) {
        self.configuration = configuration
    }
}

extension ConnectionManager: TrackingRepository {

    /// Update the properties of a customer
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    func trackCustumer(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel]) {

        let url = configuration.baseURL + "track/v2/\(projectId)/customers"
        let request = APISource.prepareRequest(withURL: url, customerId: customerId, properties: properties)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Add new events into a customer
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    ///     - eventType: Type of event to be tracked
    func trackEvents(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel], timestamp: Int, eventType: String) {

        let url = configuration.baseURL + "track/v2/\(projectId)/events"
        let request = APISource.prepareRequest(withURL: url, customerId: customerId, properties: properties, timestamp: timestamp, eventType: eventType)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }
}

extension ConnectionManager: TokenRepository {

    func rotateToken(projectId: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/tokens/rotate"
        let request = APISource.prepareRequest(withURL: url)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func revokeToken(projectId: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/tokens/revoke"
        let request = APISource.prepareRequest(withURL: url)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

}

extension ConnectionManager: FetchCustomerRepository {

    func fetchProperty(projectId: String, customerIds: KeyValueModel, property: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/property"
        let request = APISource.prepareRequest(withURL: url, customerId: customerIds, forProperty: property)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchId(projectId: String, customerIds: KeyValueModel, id: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/id"
        let request = APISource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchSegmentation(projectId: String, customerIds: KeyValueModel, id: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/segmentation"
        let request = APISource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchExpression(projectId: String, customerIds: KeyValueModel, id: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/expression"
        let request = APISource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchPrediction(projectId: String, customerIds: KeyValueModel, id: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/prediction"
        let request = APISource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchRecommendation(projectId: String, customerIds: KeyValueModel, id: String, recommendation: CustomerRecommendModel?) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/recommendation"
        let request = APISource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchAttributes(projectId: String, customerId: KeyValueModel, attributes: [CustomerAttributesListModel]) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/attributes"
        let request = APISource.prepareRequest(withURL: url, customerId: customerId, withAttributes: attributes)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchEvents(projectId: String, customerId: KeyValueModel, events: CustomerEventsModel) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/events"
        let request = APISource.prepareRequest(withURL: url, customerId: customerId, forEvents: events)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchAllProperties(projectId: String, customerId: KeyValueModel) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/export-one"
        let request = APISource.prepareRequest(withURL: url, customerId: customerId)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func fetchAllCustomers(projectId: String, data: CustomerExportModel) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/export"
        let request = APISource.prepareRequest(withURL: url, withData: data)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    func anonymize(projectId: String, customerId: KeyValueModel) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/anonymize"
        let request = APISource.prepareRequest(withURL: url, customerId: customerId)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

}
