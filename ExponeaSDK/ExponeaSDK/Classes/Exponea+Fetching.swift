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
    
    internal func executeWithDependencies<T>(_ closure: (Exponea.Dependencies) throws -> Void,
                                             completion: @escaping (Result<T>) -> Void) {
        do {
            let dependencies = try getDependenciesIfConfigured()
            try closure(dependencies)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
            completion(.failure(error))
        }
    }
    
    public func fetchRecommendation(with request: RecommendationRequest,
                                    completion: @escaping (Result<RecommendationResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchRecommendation(recommendation: request,
                                              for: $0.trackingManager.customerIds,
                                              completion: completion)
        }, completion: completion)
    }
    
    public func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void) {
        executeWithDependencies({
            guard $0.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            
            $0.repository.fetchBanners(completion: completion)
        }, completion: completion)
    }
    
    public func fetchPersonalization(with request: PersonalizationRequest,
                                     completion: @escaping (Result<PersonalizationResponse>) -> Void) {
        executeWithDependencies({
            guard $0.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            
            $0.repository.fetchPersonalization(with: request,
                                               for: $0.trackingManager.customerIds,
                                               completion: completion)
        }, completion: completion)
    }
}
