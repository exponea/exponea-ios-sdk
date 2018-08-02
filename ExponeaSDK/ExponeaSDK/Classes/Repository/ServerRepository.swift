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
    func trackCustomer(with data: [DataType], for customerIds: [String: JSONValue],
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
        let router = RequestFactory(baseUrl: configuration.baseUrl,
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
    func trackEvent(with data: [DataType], for customerIds: [String: JSONValue],
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
        let router = RequestFactory(baseUrl: configuration.baseUrl,
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

extension ServerRepository: RepositoryType {
    /// Fetch a recommendation by its ID for particular customer.
    ///
    /// - Parameters:
    ///   - recommendation: Recommendations for the customer.
    ///   - customerIds: Identification of a customer.
    ///   - completion: Object containing the request result.
    func fetchRecommendation(recommendation: RecommendationRequest, for customerIds: [String: JSONValue],
                             completion: @escaping (Result<RecommendationResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .customerRecommendation)
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
    func fetchAttributes(attributes: [AttributesDescription],
                         for customerIds: [String: JSONValue],
                         completion: @escaping (Result<AttributesResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .customerAttributes)
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
    func fetchEvents(events: EventsRequest,
                     for customerIds: [String: JSONValue],
                     completion: @escaping (Result<EventsResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .customerEvents)
        let parameters = CustomerParameters(customer: customerIds, events: events)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Fetch all available banners.
    ///
    /// - Parameters:
    ///   - completion: Object containing the request result.
    func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .banners)
        let request = router.prepareRequest(authorization: configuration.authorization)
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    /// Fetch personalization (all banners) for current customer.
    ///
    /// - Parameters:
    ///   - request: Personalization request containing all the information about the request banners.
    ///   - customerIds: Identification of a customer.
    ///   - completion: Object containing the request result.
    func fetchPersonalization(with request: PersonalizationRequest,
                              for customerIds: [String : JSONValue],
                              completion: @escaping (Result<PersonalizationResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .personalization)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: request,
                                            customerIds: customerIds)
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
}
