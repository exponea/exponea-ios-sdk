//
//  ServerRepository+FetchingRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

extension ServerRepository: FetchRepository {
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
