//
//  Repository.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol TrackingRepository {
    func trackCustomer(with data: [DataType], for customer: Customer, completion: @escaping ((EmptyResult) -> Void))
    func trackEvent(with data: [DataType], for customer: Customer, completion: @escaping ((EmptyResult) -> Void))
    func trackEvents(with data: [[DataType]], for customer: Customer, completion: @escaping ((EmptyResult) -> Void))
}

protocol TokenRepository {
    func rotateToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void))
    func revokeToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void))
}

protocol FetchRepository {
    func fetchProperty(projectToken: String, customerId: [AnyHashable: JSONConvertible],
                       property: String, completion: @escaping (Result<StringResponse>) -> Void)
    
    func fetchId(projectToken: String, customerId: [AnyHashable: JSONConvertible], id: String,
                 completion: @escaping (Result<StringResponse>) -> Void)
    
    func fetchSegmentation(projectToken: String, customerId: [AnyHashable: JSONConvertible], id: String)
    
    func fetchExpression(projectToken: String, customerId: [AnyHashable: JSONConvertible], id: String,
                         completion: @escaping (Result<EntityValueResponse>) -> Void)
    
    func fetchPrediction(projectToken: String, customerId: [AnyHashable: JSONConvertible], id: String,
                         completion: @escaping (Result<EntityValueResponse>) -> Void)
    
    func fetchRecommendation(projectToken: String,
                             customerId: [AnyHashable: JSONConvertible],
                             recommendation: RecommendationRequest,
                             completion: @escaping (Result<RecommendationResponse>) -> Void)
    
    func fetchAttributes(projectToken: String,
                         customerId: [AnyHashable: JSONConvertible],
                         attributes: [CustomerAttribute])
    
    func fetchEvents(projectToken: String,
                     customerId: [AnyHashable: JSONConvertible],
                     events: EventsRequest,
                     completion: @escaping (Result<EventsResponse>) -> Void)
    
    func fetchAllProperties(projectToken: String, customerId: [AnyHashable: JSONConvertible])
    
    func fetchAllCustomers(projectToken: String, data: CustomerExport)
    
    func anonymize(projectToken: String, customerId: [AnyHashable: JSONConvertible])
}

protocol RepositoryType: class, TrackingRepository, TokenRepository, FetchRepository {
    var configuration: Configuration { get set }
}
