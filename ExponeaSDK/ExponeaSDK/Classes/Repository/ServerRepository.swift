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
    private let session = URLSession(configuration: .default)

    // Initialize the configuration for all HTTP requests
    init(configuration: Configuration) {
        self.configuration = configuration
    }
}

extension ServerRepository: TrackingRepository {
    func trackObject(
        _ trackingObject: TrackingObject,
        for customerIds: [String: JSONValue],
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        var properties: [String: JSONValue] = [:]

        for item in trackingObject.dataTypes {
            switch item {
            case .properties(let props): properties.merge(props, uniquingKeysWith: { first, _ in return first })
            default: continue
            }
        }

        guard let projectToken = trackingObject.projectToken else {
            completion(.failure(RepositoryError.missingData("Project token not provided.")))
            return
        }

        if let customer = trackingObject as? CustomerTrackingObject {
            uploadTrackingData(
                projectToken: projectToken,
                trackingParameters: TrackingParameters(
                    customerIds: customerIds,
                    properties: properties,
                    timestamp: customer.timestamp
                ),
                route: .identifyCustomer,
                completion: completion
            )
        } else if let event = trackingObject as? EventTrackingObject {
            uploadTrackingData(
                projectToken: projectToken,
                trackingParameters: TrackingParameters(
                    customerIds: customerIds,
                    properties: properties,
                    timestamp: event.timestamp,
                    eventType: event.eventType
                ),
                route: event.eventType == Constants.EventTypes.campaignClick ? .campaignClick : .customEvent,
                completion: completion
            )
        } else {
            fatalError("Unknown tracking object type")
        }
    }

    func uploadTrackingData(
        projectToken: String,
        trackingParameters: TrackingParameters,
        route: Routes,
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        let router = RequestFactory(
            baseUrl: configuration.baseUrl,
            projectToken: projectToken,
            route: route
        )
        let request = router.prepareRequest(
            authorization: configuration.authorization,
            parameters: trackingParameters
        )

        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
}

extension ServerRepository: RepositoryType {
    func fetchRecommendation<T: RecommendationUserData>(
        request: RecommendationRequest,
        for customerIds: [String: JSONValue],
        completion: @escaping (Result<RecommendationResponse<T>>) -> Void
    ) {
        let router = RequestFactory(
            baseUrl: configuration.baseUrl,
            projectToken: configuration.fetchingToken,
            route: .customerAttributes
        )
        let request = router.prepareRequest(
            authorization: configuration.authorization,
            parameters: request,
            customerIds: customerIds
        )

        session
            .dataTask(
                with: request,
                completionHandler: router.handler(
                    with: { (result: Result<WrappedRecommendationResponse<T>>) in
                        if let response = result.value {
                            // response is wrapped into an array of results for requests.
                            // we only sent one request, so we only care about first result
                            if response.success, response.results.count > 0 {
                                completion(Result.success(response.results[0]))
                            } else {
                                completion(Result.failure(RepositoryError.serverError(nil)))
                            }
                        } else {
                            completion(Result.failure(result.error ?? RepositoryError.serverError(nil)))
                        }
                    }
                )
            )
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
                              for customerIds: [String: JSONValue],
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

    /// Fetch the list of your existing consent categories.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        let router = RequestFactory(baseUrl: configuration.baseUrl,
                                    projectToken: configuration.fetchingToken,
                                    route: .consents)
        let request = router.prepareRequest(authorization: configuration.authorization)
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }

    func fetchInAppMessages(
        for customerIds: [String: JSONValue],
        completion: @escaping (Result<InAppMessagesResponse>) -> Void
    ) {
        let router = RequestFactory(
            baseUrl: configuration.baseUrl,
            projectToken: configuration.fetchingToken,
            route: .inAppMessages
        )
        let request = router.prepareRequest(
            authorization: configuration.authorization,
            parameters: InAppMessagesRequest(),
            customerIds: customerIds
        )
        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
}

extension ServerRepository {

    // Gets and cancels all tasks
    func cancelRequests() {
        session.getAllTasks { (tasks) in
            for task in tasks {
                task.cancel()
            }
        }
    }
}
