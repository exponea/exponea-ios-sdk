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
    
    internal func executeWithDependencies<T>(_ closure: (Exponea.Dependencies) -> Void,
                                             completion: @escaping (Result<T>) -> Void) {
        do {
            let dependencies = try getDependenciesIfConfigured()
            closure(dependencies)
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
    
    public func fetchAttributes(with request: AttributesDescription,
                                completion: @escaping (Result<AttributesResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchAttributes(attributes: [request],
                                          for: $0.trackingManager.customerIds,
                                          completion: completion)
        }, completion: completion)
    }
    
    public func fetchEvents(with request: EventsRequest, completion: @escaping (Result<EventsResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchEvents(events: request,
                                      for: $0.trackingManager.customerIds,
                                      completion: completion)
        }, completion: completion)
    }
    
    public func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchBanners(completion: completion)
        }, completion: completion)
    }
    
    public func fetchPersonalization(with request: PersonalizationRequest,
                                     completion: @escaping (Result<PersonalizationResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchPersonalization(with: request,
                                               for: $0.trackingManager.customerIds,
                                               completion: completion)
        }, completion: completion)
    }
}
