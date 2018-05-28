//
//  Repository.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol TrackingRepository {
    func trackCustomer(with data: [DataType],
                       for customerIds: [AnyHashable: JSONConvertible],
                       completion: @escaping ((EmptyResult) -> Void))
    
    func trackEvent(with data: [DataType],
                    for customerIds: [AnyHashable: JSONConvertible],
                    completion: @escaping ((EmptyResult) -> Void))
}

protocol TokenRepository {
    func rotateToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void))
    func revokeToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void))
}

protocol FetchRepository {
    func fetchProperty(property: String, for customerIds: [AnyHashable: JSONConvertible],
                       completion: @escaping (Result<StringResponse>) -> Void)
    func fetchAllProperties(for customerIds: [AnyHashable: JSONConvertible],
                            completion: @escaping (Result<[StringResponse]>) -> Void)
    
    func fetchId(id: String, for customerIds: [AnyHashable: JSONConvertible],
                 completion: @escaping (Result<StringResponse>) -> Void)
    func fetchSegmentation(id: String, for customerIds: [AnyHashable: JSONConvertible],
                           completion: @escaping (Result<StringResponse>) -> Void)
    func fetchExpression(id: String, for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<EntityValueResponse>) -> Void)
    func fetchPrediction(id: String, for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<EntityValueResponse>) -> Void)
    func fetchRecommendation(recommendation: RecommendationRequest, for customerIds: [AnyHashable: JSONConvertible],
                             completion: @escaping (Result<RecommendationResponse>) -> Void)
    func fetchAttributes(attributes: [CustomerAttribute], for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<CustomerAttributesGroup>) -> Void)
    func fetchEvents(events: EventsRequest, for customerIds: [AnyHashable: JSONConvertible],
                     completion: @escaping (Result<EventsResponse>) -> Void)
    func fetchAllCustomers(data: CustomerExport,
                           completion: @escaping (Result<[StringResponse]>) -> Void)
    
    func anonymize(customerIds: [AnyHashable: JSONConvertible],
                   completion: @escaping (Result<StringResponse>) -> Void)
}

protocol RepositoryType: class, TrackingRepository, TokenRepository, FetchRepository {
    var configuration: Configuration { get set }
}
