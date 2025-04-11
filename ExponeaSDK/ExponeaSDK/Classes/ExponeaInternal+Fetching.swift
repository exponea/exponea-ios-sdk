//
//  ExponeaInternal+Fetching.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

// MARK: - Fetching -

extension ExponeaInternal {
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
            self.telemetryManager?.report(eventWithType: .fetchRecommendation, properties: [:])
        }, completion: completion)
    }

    /// Fetch the list of your existing consent categories.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    public func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        executeSafelyWithDependencies({
            guard $0.configuration.authorization != Authorization.none else {
                if IntegrationManager.shared.isStopped {
                    completion(.failure(ExponeaError.isStopped))
                }
                throw ExponeaError.authorizationInsufficient
            }

            $0.repository.fetchConsents(completion: $1)

            self.telemetryManager?.report(eventWithType: .fetchConsents, properties: [:])
        }, completion: completion)
    }

    public func fetchAppInbox(completion: @escaping (Result<[MessageItem]>) -> Void) {
        executeSafelyWithDependencies({
            guard $0.configuration.authorization != Authorization.none else {
                if IntegrationManager.shared.isStopped {
                    completion(.failure(ExponeaError.isStopped))
                }
                throw ExponeaError.authorizationInsufficient
            }
            $0.appInboxManager.fetchAppInbox(completion: $1)
            self.telemetryManager?.report(eventWithType: .fetchAppInbox, properties: [:])
        }, completion: completion)
    }

    public func fetchAppInboxItem(_ messageId: String, completion: @escaping (Result<MessageItem>) -> Void) {
        executeSafelyWithDependencies({
            guard $0.configuration.authorization != Authorization.none else {
                if IntegrationManager.shared.isStopped {
                    completion(.failure(ExponeaError.isStopped))
                }
                throw ExponeaError.authorizationInsufficient
            }
            $0.appInboxManager.fetchAppInboxItem(messageId, completion: $1)
        }, completion: completion)
    }
}
