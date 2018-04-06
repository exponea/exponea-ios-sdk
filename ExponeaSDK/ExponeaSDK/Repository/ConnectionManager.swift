//
//  ConnectionManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

final public class ConnectionManager {

    let configuration: APIConfiguration
    let apiSource: APISource
    private let session = URLSession.shared

    // Initialize the configuration for all HTTP requests
    init(configuration: APIConfiguration) {
        self.configuration = configuration
        self.apiSource = APISource()
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
        let request = apiSource.prepareRequest(withURL: url, customerId: customerId, properties: properties)

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
        let request = apiSource.prepareRequest(withURL: url, customerId: customerId, properties: properties, timestamp: timestamp, eventType: eventType)

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

    /// Rotates the token
    /// The old token will still work for next 48 hours. You cannot have more than two private
    /// tokens for one public token, therefore rotating the newly fetched token while the old
    /// token is still working will result in revoking that old token right away. Rotating the
    /// old token twice will result in error, since you cannot have three tokens at the same time.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    func rotateToken(projectId: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/tokens/rotate"
        let request = apiSource.prepareRequest(withURL: url)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Revoke the token
    /// Please note, that revoking a token can result in losing the access if you haven't revoked a new token before.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    func revokeToken(projectId: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/tokens/revoke"
        let request = apiSource.prepareRequest(withURL: url)

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

    /// Fetch property for one customer.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - property: Property that should be updated
    func fetchProperty(projectId: String, customerIds: KeyValueModel, property: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/property"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerIds, forProperty: property)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Fetch an identifier by another known identifier.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchId(projectId: String, customerIds: KeyValueModel, id: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/id"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Fetch a segment by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchSegmentation(projectId: String, customerIds: KeyValueModel, id: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/segmentation"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Fetch an expression by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchExpression(projectId: String, customerIds: KeyValueModel, id: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/expression"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Fetch a prediction by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchPrediction(projectId: String, customerIds: KeyValueModel, id: String) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/prediction"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Fetch a recommendation by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    ///     - recommendation: Recommendations for the customer
    func fetchRecommendation(projectId: String, customerIds: KeyValueModel, id: String, recommendation: CustomerRecommendModel?) {
        let url = configuration.baseURL + "data/v2/\(projectId)/customers/recommendation"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerIds, forId: id)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Fetch multiple customer attributes at once
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - attributes: List of attributes you want to retrieve
    func fetchAttributes(projectId: String, customerId: KeyValueModel, attributes: [CustomerAttributesListModel]) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/attributes"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerId, withAttributes: attributes)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Fetch customer events by it's type
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - events: List of event types you want to retrieve
    func fetchEvents(projectId: String, customerId: KeyValueModel, events: CustomerEventsModel) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/events"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerId, forEvents: events)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Exports all properties, ids and events for one customer
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    func fetchAllProperties(projectId: String, customerId: KeyValueModel) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/export-one"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerId)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Exports all customers who exist in the project
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - data: List of properties to retrieve
    func fetchAllCustomers(projectId: String, data: CustomerExportModel) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/export"
        let request = apiSource.prepareRequest(withURL: url, withData: data)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }

    /// Removes all the external identifiers and assigns a new cookie id.
    /// Removes all personal customer properties
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    func anonymize(projectId: String, customerId: KeyValueModel) {
        let url = configuration.baseURL + "/data/v2/\(projectId)/customers/anonymize"
        let request = apiSource.prepareRequest(withURL: url, customerId: customerId)

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
