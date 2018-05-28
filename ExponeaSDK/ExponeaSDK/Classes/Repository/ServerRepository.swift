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
    func trackCustomer(with data: [DataType], for customerIds: [AnyHashable: JSONConvertible], completion: @escaping ((EmptyResult) -> Void)) {
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
        let params = TrackingParameters(customerIds: customerIds, properties: properties)
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
    func trackEvent(with data: [DataType], for customerIds: [AnyHashable: JSONConvertible], completion: @escaping ((EmptyResult) -> Void)) {
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
        let params = TrackingParameters(customerIds: customerIds, properties: properties,
                                        timestamp: timestamp, eventType: eventType)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: params)
        
        // Run the data task
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
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
    func fetchProperty(property: String, for customerIds: [AnyHashable: JSONConvertible],
                       completion: @escaping ((Result<StringResponse>) -> Void)) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersProperty)
        let parameters = CustomerParameters(customer: customerIds, property: property)
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
    func fetchId(id: String, for customerIds: [AnyHashable: JSONConvertible],
                 completion: @escaping (Result<StringResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersId)
        
        let parameters = CustomerParameters(customer: customerIds, id: id)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Fetch a segment by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchSegmentation(id: String, for customerIds: [AnyHashable: JSONConvertible],
                           completion: @escaping (Result<StringResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersSegmentation)
        
        let parameters = CustomerParameters(customer: customerIds, id: id)
        
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Fetch an expression by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - id: Identifier that you want to retrieve
    func fetchExpression(id: String, for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<EntityValueResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersExpression)
        let parameters = CustomerParameters(customer: customerIds, id: id)
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
    func fetchPrediction(id: String, for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<EntityValueResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersPrediction)
        let parameters = CustomerParameters(customer: customerIds, id: id)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
        
    }
    
    /// Fetch a recommendation by its ID for particular customer.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - recommendation: Recommendations for the customer
    func fetchRecommendation(recommendation: RecommendationRequest, for customerIds: [AnyHashable: JSONConvertible],
                             completion: @escaping (Result<RecommendationResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersRecommendation)
        let parameters = CustomerParameters(customer: customerIds, recommendation: recommendation)
        let request = router.prepareRequest(authorization: configuration.authorization, parameters: parameters)
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Fetch multiple customer attributes at once
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - attributes: List of attributes you want to retrieve
    func fetchAttributes(attributes: [CustomerAttribute], for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<CustomerAttributesGroup>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersAttributes)
        let parameters = CustomerParameters(customer: customerIds, attributes: attributes)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)

        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Fetch customer events by it's type
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - events: List of event types you want to retrieve
    func fetchEvents(events: EventsRequest, for customerIds: [AnyHashable: JSONConvertible],
                     completion: @escaping (Result<EventsResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersEvents)
        let parameters = CustomerParameters(customer: customerIds, events: events)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Exports all properties, ids and events for one customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    func fetchAllProperties(for customerIds: [AnyHashable: JSONConvertible],
                            completion: @escaping (Result<[StringResponse]>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersExportAllProperties)
        let parameters = CustomerParameters(customer: customerIds)
        
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Exports all customers who exist in the project
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - data: List of properties to retrieve
    func fetchAllCustomers(data: CustomerExport, completion: @escaping (Result<[StringResponse]>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersExportAll)
        let parameters = CustomerParameters(customer: [:], data: data)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Removes all the external identifiers and assigns a new cookie id.
    /// Removes all personal customer properties
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    func anonymize(customerIds: [AnyHashable: JSONConvertible], completion: @escaping (Result<StringResponse>) -> Void) {
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: configuration.fetchingToken,
                                    route: .customersAnonymize)
        let parameters = CustomerParameters(customer: customerIds)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
}
