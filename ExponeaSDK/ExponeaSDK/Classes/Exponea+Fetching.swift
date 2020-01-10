//
//  Exponea+Fetching.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

// MARK: - Fetching -

extension Exponea {
    public func fetchRecommendation<T: RecommendationUserData>(
        with options: RecommendationOptions,
        completion: @escaping (Result<RecommendationResponse<T>>) -> Void
    ) {
        executeSafelyWithDependencies({
            $0.repository.fetchRecommendation(
                request: RecommendationRequest(options: options),
                for: $0.trackingManager.customerIds,
                completion: $1
            )
        }, completion: completion)
    }

    public func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void) {
        executeSafelyWithDependencies({
            guard $0.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token")
            }

            $0.repository.fetchBanners(completion: $1)
        }, completion: completion)
    }

    public func fetchPersonalization(with request: PersonalizationRequest,
                                     completion: @escaping (Result<PersonalizationResponse>) -> Void) {
        executeSafelyWithDependencies({
            guard $0.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token")
            }

            $0.repository.fetchPersonalization(
                with: request,
                for: $0.trackingManager.customerIds,
                completion: $1
            )
        }, completion: completion)
    }

    /// Fetch the list of your existing consent categories.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    public func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        executeSafelyWithDependencies({
            guard $0.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token")
            }

            $0.repository.fetchConsents(completion: $1)
        }, completion: completion)
    }
}
