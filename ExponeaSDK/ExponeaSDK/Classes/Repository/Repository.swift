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
    func fetchProperty(projectToken: String, customerId: KeyValueItem,
                       property: String, completion: @escaping (Result<ValueResponse>) -> Void)
    
    func fetchId(projectToken: String, customerId: KeyValueItem, id: String,
                 completion: @escaping (Result<ValueResponse>) -> Void)
    
    func fetchSegmentation(projectToken: String, customerId: KeyValueItem, id: String)
    
    func fetchExpression(projectToken: String, customerId: KeyValueItem, id: String,
                         completion: @escaping (Result<EntityValueResponse>) -> Void)
    
    func fetchPrediction(projectToken: String, customerId: KeyValueItem, id: String,
                         completion: @escaping (Result<EntityValueResponse>) -> Void)
    
    func fetchRecommendation(projectToken: String,
                             customerId: KeyValueItem,
                             recommendation: CustomerRecommendation,
                             completion: @escaping (Result<Recommendation>) -> Void)
    
    func fetchAttributes(projectToken: String,
                         customerId: KeyValueItem,
                         attributes: [CustomerAttributes])
    
    func fetchEvents(projectToken: String,
                     customerId: KeyValueItem,
                     events: FetchEventsRequest,
                     completion: @escaping (Result<FetchEventsResponse>) -> Void)
    
    func fetchAllProperties(projectToken: String, customerId: KeyValueItem)
    
    func fetchAllCustomers(projectToken: String, data: CustomerExportModel)
    
    func anonymize(projectToken: String, customerId: KeyValueItem)
}

protocol RepositoryType: class, TrackingRepository, TokenRepository, FetchRepository {
    var configuration: Configuration { get set }
}
