//
//  ConnectionManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

// FIXME: Validate documentation

final class ServerRepository {
    
    public internal(set) var configuration: Configuration
    private let session = URLSession.shared
    
    // Initialize the configuration for all HTTP requests
    init(configuration: Configuration) {
        self.configuration = configuration
    }
}

extension ServerRepository: TrackingRepository {
    
    /// Update the properties of a customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    func trackCustomer(with data: [DataType], for customer: Customer, completion: @escaping ((EmptyResult) -> Void)) {
        var token: String?
        var properties: [AnyHashable: JSONConvertible] = [:]
        
        for item in data {
            switch item {
            case .projectToken(let string): token = string
            case .properties(let props): properties.merge(props, uniquingKeysWith: { first, _ in return first })
            default: continue
            }
        }
        
        guard let projectToken = token else {
            completion(.failure(RepositoryError.missingData("Project token not provided.")))
            return
        }
        
        // Setup router
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .identifyCustomer)
        
        // Prepare parameters and request
        let params = TrackingParameters(customerIds: customer.ids, properties: properties)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: params)
        
        // Run the data task
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Add new events into a customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    ///     - eventType: Type of event to be tracked
    func trackEvent(with data: [DataType], for customer: Customer, completion: @escaping ((EmptyResult) -> Void)) {
        var token: String?
        var properties: [AnyHashable: JSONConvertible] = [:]
        var timestamp: Double?
        var eventType: String?
        
        for item in data {
            switch item {
            case .projectToken(let string): token = string
            case .properties(let props): properties.merge(props, uniquingKeysWith: { first, _ in return first })
            case .timestamp(let timeInterval): timestamp = timeInterval ?? Date().timeIntervalSince1970
            case .eventType(let type): eventType = type
            default: continue
            }
        }
        
        guard let projectToken = token else {
            completion(.failure(RepositoryError.missingData("Project token not provided.")))
            return
        }
        
        // Setup router
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customEvent)
        
        // Prepare parameters and request
        let params = TrackingParameters(customerIds: customer.ids, properties: properties,
                                        timestamp: timestamp, eventType: eventType)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: params)
        
        // Run the data task
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    func trackEvents(with data: [[DataType]], for customer: Customer, completion: @escaping ((EmptyResult) -> Void)) {
        // Group by project token
        // FIXME: Fix this
    }
}

extension ServerRepository: TokenRepository {
    
    /// Rotates the token
    /// The old token will still work for next 48 hours. You cannot have more than two private
    /// tokens for one public token, therefore rotating the newly fetched token while the old
    /// token is still working will result in revoking that old token right away. Rotating the
    /// old token twice will result in error, since you cannot have three tokens at the same time.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    func rotateToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void)) {
        let router = RequestFactory(baseURL: configuration.baseURL, projectToken: projectToken, route: .tokenRotate)
        let request = router.prepareRequest(authorization: configuration.authorization)
        
        // Run the data task
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Revoke the token
    /// Please note, that revoking a token can result in losing the access if you haven't revoked a new token before.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    func revokeToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void)) {
        let router = RequestFactory(baseURL: configuration.baseURL, projectToken: projectToken, route: .tokenRotate)
        let request = router.prepareRequest(authorization: configuration.authorization)
        
        // Run the data task
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
}

extension ServerRepository: RepositoryType {
    /// Fetch property for one customer.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - property: Property that should be updated
    func fetchProperty(projectToken: String, customerId: [AnyHashable: JSONConvertible],
                       property: String, completion: @escaping ((Result<StringResponse>) -> Void)) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersProperty)
        let parameters = CustomerParameters(customer: customerId, property: property, id: nil, recommendation: nil,
                                                 attributes: nil, events: nil, data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Fetch an identifier by another known identifier.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchId(projectToken: String, customerId: [AnyHashable: JSONConvertible], id: String,
                 completion: @escaping (Result<StringResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL, projectToken: projectToken, route: .customersId)
        let parameters = CustomerParameters(customer: customerId, property: nil, id: id, recommendation: nil,
                                                 attributes: nil, events: nil, data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session.dataTask(with: request, completionHandler: router.handler(with: completion)).resume()
    }
    
    /// Fetch a segment by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchSegmentation(projectToken: String, customerId: [AnyHashable: JSONConvertible], id: String) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersSegmentation)
        let parameters = CustomerParameters(customer: customerId, property: nil, id: id, recommendation: nil,
                                                 attributes: nil, events: nil, data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        let task = session.dataTask(with: request, completionHandler: { (_, _, error) in
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
    func fetchExpression(projectToken: String, customerId: [AnyHashable: JSONConvertible], id: String,
                         completion: @escaping (Result<EntityValueResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersExpression)
        let parameters = CustomerParameters(customer: customerId, property: nil, id: id, recommendation: nil,
                                                 attributes: nil, events: nil, data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session.dataTask(with: request, completionHandler: router.handler(with: completion)).resume()
    }
    
    /// Fetch a prediction by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchPrediction(projectToken: String, customerId: [AnyHashable: JSONConvertible], id: String,
                         completion: @escaping (Result<EntityValueResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersPrediction)
        let parameters = CustomerParameters(customer: customerId, property: nil, id: id, recommendation: nil,
                                                 attributes: nil, events: nil, data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session.dataTask(with: request, completionHandler: router.handler(with: completion)).resume()
        
    }
    
    /// Fetch a recommendation by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - recommendation: Recommendations for the customer
    func fetchRecommendation(projectToken: String,
                             customerId: [AnyHashable: JSONConvertible],
                             recommendation: RecommendationRequest,
                             completion: @escaping (Result<RecommendationResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersRecommendation)
        let parameters = CustomerParameters(customer: customerId,
                                                 property: nil,
                                                 id: nil,
                                                 recommendation: recommendation,
                                                 attributes: nil,
                                                 events: nil,
                                                 data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session.dataTask(with: request, completionHandler: router.handler(with: completion)).resume()
    }
    
    /// Fetch multiple customer attributes at once
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - attributes: List of attributes you want to retrieve
    func fetchAttributes(projectToken: String,
                         customerId: [AnyHashable: JSONConvertible],
                         attributes: [CustomerAttribute]) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersAttributes)
        let parameters = CustomerParameters(customer: customerId, property: nil, id: nil, recommendation: nil,
                                                 attributes: attributes, events: nil, data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        let task = session.dataTask(with: request, completionHandler: { (_, _, error) in
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
                     customerId: [AnyHashable: JSONConvertible],
                     events: EventsRequest,
                     completion: @escaping (Result<EventsResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersEvents)
        let parameters = CustomerParameters(customer: customerId,
                                                 property: nil,
                                                 id: nil,
                                                 recommendation: nil,
                                                 attributes: nil,
                                                 events: events,
                                                 data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        session.dataTask(with: request, completionHandler: router.handler(with: completion)).resume()
    }
    
    /// Exports all properties, ids and events for one customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    func fetchAllProperties(projectToken: String, customerId: [AnyHashable: JSONConvertible]) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersExportAllProperties)
        let parameters = CustomerParameters(customer: customerId,
                                                 property: nil,
                                                 id: nil,
                                                 recommendation: nil,
                                                 attributes: nil,
                                                 events: nil,
                                                 data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        let task = session.dataTask(with: request, completionHandler: { (_, _, error) in
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
    func fetchAllCustomers(projectToken: String, data: CustomerExport) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersExportAll)
        let parameters = CustomerParameters(customer: nil, property: nil, id: nil, recommendation: nil,
                                                 attributes: nil, events: nil, data: data)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        let task = session.dataTask(with: request, completionHandler: { (_, _, error) in
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
    func anonymize(projectToken: String, customerId: [AnyHashable: JSONConvertible]) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: projectToken,
                                    route: .customersAnonymize)
        let parameters = CustomerParameters(customer: customerId, property: nil, id: nil, recommendation: nil,
                                                 attributes: nil, events: nil, data: nil)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        let task = session.dataTask(with: request, completionHandler: { (_, _, error) in
            if error != nil {
                // TODO: Handle success
            } else {
                // TODO: Handle error
            }
        })
        task.resume()
    }
    
}
