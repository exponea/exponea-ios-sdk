//
//  ConnectionManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// The Server Repository class is responsible to manage all the requests for the Exponea API.
final class ServerRepository {
    
    public internal(set) var configuration: Configuration
    private let session = URLSession.shared
    
    // Initialize the configuration for all HTTP requests
    init(configuration: Configuration) {
        self.configuration = configuration
    }
}

extension ServerRepository: TrackingRepository {
    
    /// Tracks the data of the data type property for a customer.
    ///
    /// - Parameters:
    ///     - data: Object containing the data to be used to track a customer data.
    ///     - customer: Customer identification.
    ///     - completion: Object containing the request result.
    func trackCustomer(with data: [DataType], for customerIds: [String: String],
                       completion: @escaping ((EmptyResult) -> Void)) {
        var token: String?
        var properties: [String: JSONValue] = [:]
        
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
    func trackEvent(with data: [DataType], for customerIds: [String: String],
                    completion: @escaping ((EmptyResult) -> Void)) {
        var token: String?
        var properties: [String: JSONValue] = [:]
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
    
    /// Fetchs the property for a customer.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - property: Property that should be fetched.
    ///   - completion: Object containing the request result.
    func fetchProperty(property: String, for customerIds: [String: String],
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
    
    /// Fetchs a identifier by another known identifier.
    ///
    /// - Parameters:
    ///   - customerId: Identification of a customer.
    ///   - id: Identifier that you want to retrieve.
    ///   - completion: Object containing the request result.
    func fetchId(id: String, for customerIds: [String: String],
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
    ///   - customerId: Identification of a customer.
    ///   - id: Identifier that you want to retrieve.
    func fetchSegmentation(id: String, for customerIds: [String: String],
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
    func fetchExpression(id: String, for customerIds: [String: String],
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
    ///   - id: Identifier that you want to retrieve
    ///   - customerIds: Identification of a customer.
    ///   - completion: Object containing the request result.
    func fetchPrediction(id: String, for customerIds: [String: String],
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
    ///   - recommendation: Recommendations for the customer.
    ///   - customerIds: Identification of a customer.
    ///   - completion: Object containing the request result.
    func fetchRecommendation(recommendation: RecommendationRequest, for customerIds: [String: String],
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
    ///   - attributes: List of attributes you want to retrieve.
    ///   - customerIds: Identification of a customer.
    func fetchAttributes(attributes: [AttributesDescription], for customerIds: [String: String],
                         completion: @escaping (Result<AttributesListDescription>) -> Void) {
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
    ///   - events: List of event types to be retrieve.
    ///   - customerId: Identification of a customer.
    ///   - completion: Object containing the request result.
    func fetchEvents(events: EventsRequest, for customerIds: [String: String],
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
    ///   - customerId: Identification of a customer.
    ///   - completion: Object containing the request result.
    func fetchAllProperties(for customerIds: [String: String],
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
    ///   - data: List of properties to retrieve.
    ///   - completion: Object containing the request result.
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
    /// Removes all personal customer properties.
    ///
    /// - Parameters:
    ///   - customerId: Identification of a customer.
    ///   - completion: Object containing the request result.
    func anonymize(customerIds: [String: String],
                   completion: @escaping (Result<StringResponse>) -> Void) {
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
