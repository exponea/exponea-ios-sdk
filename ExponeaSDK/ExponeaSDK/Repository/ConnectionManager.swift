//
//  ConnectionManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

final class ConnectionManager {

    let configuration: Configuration
    let apiSource: APISource
    private let session = URLSession.shared

    // Initialize the configuration for all HTTP requests
    init(configuration: Configuration) {
        self.configuration = configuration
        self.apiSource = APISource()
    }
}

extension ConnectionManager: TrackingRepository {

    /// Update the properties of a customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    func trackCustumer(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel]) {

        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .trackCustomers)
        let params = TrackingParams(customer: customerId, properties: properties, timestamp: nil, eventType: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: params, customersParam: nil)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    ///     - eventType: Type of event to be tracked
    func trackEvents(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel],
                     timestamp: Double?, eventType: String?) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .trackEvents)
        let params = TrackingParams(customer: customerId, properties: properties, timestamp: timestamp,
                                    eventType: eventType)
        let request = apiSource.prepareRequest(router: router, trackingParam: params, customersParam: nil)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    func rotateToken(projectToken: String) {

        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .tokenRotate)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: nil)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    func revokeToken(projectToken: String) {

        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .tokenRotate)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: nil)

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

extension ConnectionManager: ConnectionManagerType {

    /// Fetch property for one customer.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - property: Property that should be updated
    func fetchProperty(projectToken: String, customerId: KeyValueModel, property: String) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersProperty)
        let customersParams = CustomersParams(customer: customerId, property: property, id: nil, recommendation: nil,
                                              attributes: nil, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchId(projectToken: String, customerId: KeyValueModel, id: String) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersId)
        let customersParams = CustomersParams(customer: customerId, property: nil, id: id, recommendation: nil,
                                              attributes: nil, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchSegmentation(projectToken: String, customerId: KeyValueModel, id: String) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersSegmentation)
        let customersParams = CustomersParams(customer: customerId, property: nil, id: id, recommendation: nil,
                                              attributes: nil, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchExpression(projectToken: String, customerId: KeyValueModel, id: String) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersExpression)
        let customersParams = CustomersParams(customer: customerId, property: nil, id: id, recommendation: nil,
                                              attributes: nil, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchPrediction(projectToken: String, customerId: KeyValueModel, id: String) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersPrediction)
        let customersParams = CustomersParams(customer: customerId, property: nil, id: id, recommendation: nil,
                                              attributes: nil, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    ///     - recommendation: Recommendations for the customer
    func fetchRecommendation(projectToken: String, customerId: KeyValueModel, id: String,
                             recommendation: CustomerRecommendation?) {

        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersRecommendation)
        let customersParams = CustomersParams(customer: customerId, property: nil, id: id,
                                              recommendation: recommendation, attributes: nil, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - attributes: List of attributes you want to retrieve
    func fetchAttributes(projectToken: String, customerId: KeyValueModel, attributes: [CustomerAttributes]) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersAttributes)
        let customersParams = CustomersParams(customer: customerId, property: nil, id: nil, recommendation: nil,
                                              attributes: attributes, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - events: List of event types you want to retrieve
    func fetchEvents(projectToken: String,
                     customerId: KeyValueModel,
                     events: CustomerEvents,
                     completion: @escaping (Result<EventsResult>) -> Void) {
        let router = APIRouter(baseURL: configuration.baseURL,
                               projectToken: projectToken,
                               route: .customersEvents)
        let customersParams = CustomersParams(customer: customerId,
                                              property: nil,
                                              id: nil,
                                              recommendation: nil,
                                              attributes: nil,
                                              events: events,
                                              data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, _, error) in
            if let error = error {
                Exponea.logger.log(.error, message: "Unresolved error \(String(error.localizedDescription))")
                completion(Result.failure(error))
            } else {
                guard let data = data else {
                    Exponea.logger.log(.error, message: "Could not unwrap data.")
                    return
                }
                do {
                    let events = try JSONDecoder().decode(EventsResult.self, from: data)
                    completion(Result.success(events))
                } catch {
                    Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription)")
                    completion(Result.failure(error))
                }
            }
        })
        task.resume()
    }

    /// Exports all properties, ids and events for one customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    func fetchAllProperties(projectToken: String, customerId: KeyValueModel) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersExportAllProperties)
        let customersParams = CustomersParams(customer: customerId, property: nil, id: nil, recommendation: nil,
                                              attributes: nil, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - data: List of properties to retrieve
    func fetchAllCustomers(projectToken: String, data: CustomerExportModel) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersExportAll)
        let customersParams = CustomersParams(customer: nil, property: nil, id: nil, recommendation: nil,
                                              attributes: nil, events: nil, data: data)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    func anonymize(projectToken: String, customerId: KeyValueModel) {
        let router = APIRouter(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersAnonymize)
        let customersParams = CustomersParams(customer: customerId, property: nil, id: nil, recommendation: nil,
                                              attributes: nil, events: nil, data: nil)
        let request = apiSource.prepareRequest(router: router, trackingParam: nil, customersParam: customersParams)

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
