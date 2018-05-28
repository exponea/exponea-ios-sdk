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
    
    public func fetchProperty(with type: String, completion: @escaping (Result<StringResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchProperty(property: type, for: $0.trackingManager.customerIds, completion: completion)
        }, completion: completion)
    }
    
    public func fetchId(with id: String, completion: @escaping (Result<StringResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchId(id: id, for: $0.trackingManager.customerIds, completion: completion)
        }, completion: completion)
    }
    
    public func fetchExpression(with id: String, completion: @escaping (Result<EntityValueResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchExpression(id: id, for: $0.trackingManager.customerIds, completion: completion)
        }, completion: completion)
    }
    
    public func fetchPrediction(with id: String, completion: @escaping (Result<EntityValueResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchPrediction(id: id, for: $0.trackingManager.customerIds, completion: completion)
        }, completion: completion)
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
                                completion: @escaping (Result<AttributesListDescription>) -> Void) {
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
    
    public func fetchAllProperties(completion: @escaping (Result<[StringResponse]>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchAllProperties(for: $0.trackingManager.customerIds, completion: completion)
        }, completion: completion)
    }
    
    public func fetchAllCustomers(with request: CustomerExport,
                                  completion: @escaping (Result<[StringResponse]>) -> Void) {
        executeWithDependencies({
            $0.repository.fetchAllCustomers(data: request, completion: completion)
        }, completion: completion)
    }
    
    public func anonymize(completion: @escaping (Result<StringResponse>) -> Void) {
        executeWithDependencies({
            $0.repository.anonymize(customerIds: $0.trackingManager.customerIds, completion: completion)
        }, completion: completion)
    }
}
