//
//  MockRepository.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Mockingjay

@testable import ExponeaSDK

class MockRepository {
    
    /// Mock server setup.
    typealias DidReceiveDataHandler = (_ session: Foundation.URLSession, _ dataTask: URLSessionDataTask, _ data: Data) -> ()
    
    var didReceiveDataHandler:DidReceiveDataHandler?
    var urlSessionConfiguration:URLSessionConfiguration!
    
    func setUp() {
        var protocolClasses = [AnyClass]()
        protocolClasses.append(MockingjayProtocol.self)
        
        urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.protocolClasses = protocolClasses
    }
    
    /// Bundle to retrive the mock files in the project.
    private let bundle: Bundle!
    
    public internal(set) var configuration: Configuration
    private let session = URLSession.shared
    
    // Initialize the configuration for all HTTP requests
    init(configuration: Configuration) {
        self.configuration = configuration
        bundle = Bundle(for: type(of: self))
    }
    
    func retrieveDataFromFile(with fileName: String, fileType: String) -> Data {
        
        /// Get the json content of file
        guard
            let file = bundle.url(forResource: fileName, withExtension: fileType),
            let data = try? Data(contentsOf: file)
            else {
                fatalError("Something is horribly wrong with the data.")
        }
        return data
    }
    
}

extension MockRepository: TrackingRepository {
    func trackCustomer(with data: [DataType], for customerIds: [String : JSONValue], completion: @escaping ((EmptyResult) -> Void)) {
        
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
        
        // Prepare parameters and request.
        let params = TrackingParameters(customerIds: customerIds, properties: properties)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: params)

        /// Get the json content of file
        let data = retrieveDataFromFile(with: "get-recommendation", fileType: "json")
        
        /// Prepare the stub response.
        guard let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            fatalError("It was not possible to mock the HTTP response.")
        }
        
        /// Add the stub response to the mock server.
        MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
            return true
        }) { (request) -> (Response) in
            return Response.success(stubResponse, .content(data))
        }

        // Run the data task
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    func trackEvent(with data: [DataType], for customerIds: [String : JSONValue], completion: @escaping ((EmptyResult) -> Void)) {
        
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
        
        let data = retrieveDataFromFile(with: "get-recommendation", fileType: "json")
        
        /// Prepare the stub response.
        guard let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            fatalError("It was not possible to mock the HTTP response.")
        }
        
        /// Add the stub response to the mock server.
        MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
            return true
        }) { (request) -> (Response) in
            return Response.success(stubResponse, .content(data))
        }
        
        // Run the data task
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
}

extension MockRepository: FetchRepository {
    func fetchRecommendation(recommendation: RecommendationRequest, for customerIds: [String : JSONValue], completion: @escaping (Result<RecommendationResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .customerRecommendation)
        let parameters = CustomerParameters(customer: customerIds, recommendation: recommendation)
        let request = router.prepareRequest(authorization: configuration.authorization, parameters: parameters)
        
        let data = retrieveDataFromFile(with: "get-recommendation", fileType: "json")
        
        /// Prepare the stub response.
        guard let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            fatalError("It was not possible to mock the HTTP response.")
        }
        
        /// Add the stub response to the mock server.
        MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
            return true
        }) { (request) -> (Response) in
            return Response.success(stubResponse, .content(data))
        }
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    func fetchAttributes(attributes: [AttributesDescription], for customerIds: [String : JSONValue], completion: @escaping (Result<AttributesResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .customerAttributes)
        let parameters = CustomerParameters(customer: customerIds, attributes: attributes)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        let data = retrieveDataFromFile(with: "get-attributes", fileType: "json")
        
        /// Prepare the stub response.
        guard let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            fatalError("It was not possible to mock the HTTP response.")
        }
        
        /// Add the stub response to the mock server.
        MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
            return true
        }) { (request) -> (Response) in
            return Response.success(stubResponse, .content(data))
        }
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    func fetchEvents(events: EventsRequest, for customerIds: [String : JSONValue], completion: @escaping (Result<EventsResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .customerEvents)
        let parameters = CustomerParameters(customer: customerIds, events: events)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: parameters)
        
        let data = retrieveDataFromFile(with: "get-events", fileType: "json")
        
        /// Prepare the stub response.
        guard let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            fatalError("It was not possible to mock the HTTP response.")
        }
        
        /// Add the stub response to the mock server.
        MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
            return true
        }) { (request) -> (Response) in
            return Response.success(stubResponse, .content(data))
        }
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .banners)
        let request = router.prepareRequest(authorization: configuration.authorization)
        
        let data = retrieveDataFromFile(with: "get-banner", fileType: "json")
        
        /// Prepare the stub response.
        guard let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            fatalError("It was not possible to mock the HTTP response.")
        }
        
        /// Add the stub response to the mock server.
        MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
            return true
        }) { (request) -> (Response) in
            return Response.success(stubResponse, .content(data))
        }
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    func fetchPersonalization(with request: PersonalizationRequest, for customerIds: [String : JSONValue], completion: @escaping (Result<PersonalizationResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .personalization)
        let request = router.prepareRequest(authorization: configuration.authorization,
                                            parameters: request,
                                            customerIds: customerIds)
        
        let data = retrieveDataFromFile(with: "get-personalization", fileType: "json")
        
        /// Prepare the stub response.
        guard let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            fatalError("It was not possible to mock the HTTP response.")
        }
        
        /// Add the stub response to the mock server.
        MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
            return true
        }) { (request) -> (Response) in
            return Response.success(stubResponse, .content(data))
        }
        
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
    
    
}
