//
//  Repository.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Protocol containing the possibles tracking methods.
protocol TrackingRepository {
    /// Tracks the data of the data type property for a customer.
    ///
    /// - Parameters:
    ///     - data: Object containing the data to be used to track a customer data.
    ///     - customerIds: Customer identification.
    ///     - completion: Object containing the request result.
    func trackCustomer(with data: [DataType],
                       for customerIds: [AnyHashable: JSONConvertible],
                       completion: @escaping ((EmptyResult) -> Void))

    /// Tracks new events for a customer.
    ///
    /// - Parameters:
    ///     - data: Object containing the data to be used to track a customer data.
    ///     - customerIds: Customer identification.
    ///     - completion: Object containing the request result.
    func trackEvent(with data: [DataType],
                    for customerIds: [AnyHashable: JSONConvertible],
                    completion: @escaping ((EmptyResult) -> Void))
}

protocol TokenRepository {
    
    /// Rotates the token
    /// The old token will still work for next 48 hours. You cannot have more than two private
    /// tokens for one public token, therefore rotating the newly fetched token while the old
    /// token is still working will result in revoking that old token right away. Rotating the
    /// old token twice will result in error, since you cannot have three tokens at the same time.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    func rotateToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void))

    /// Revoke the token
    /// Please note, that revoking a token can result in losing the access if you haven't revoked a new token before.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    func revokeToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void))
}

protocol FetchRepository {
    /// Fetchs the property for a customer.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - property: Property that should be fetched.
    ///   - completion: Object containing the request result.
    func fetchProperty(property: String, for customerIds: [AnyHashable: JSONConvertible],
                       completion: @escaping (Result<StringResponse>) -> Void)
    /// Fetchs a identifier by another known identifier.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - id: Identifier that you want to retrieve.
    ///   - completion: Object containing the request result.
    func fetchId(id: String, for customerIds: [AnyHashable: JSONConvertible],
                 completion: @escaping (Result<StringResponse>) -> Void)
    
    /// Fetch a segment by its ID for particular customer.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - id: Identifier that you want to retrieve.
    func fetchSegmentation(id: String, for customerIds: [AnyHashable: JSONConvertible],
                           completion: @escaping (Result<StringResponse>) -> Void)

    /// Fetch an expression by its ID for particular customer.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - id: Identifier that you want to retrieve.
    ///   - completion: Object containing the request result.
    func fetchExpression(id: String, for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<EntityValueResponse>) -> Void)
    
    /// Fetch a prediction by its ID for particular customer.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - id: Identifier that you want to retrieve
    ///   - completion: Object containing the request result.
    func fetchPrediction(id: String, for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<EntityValueResponse>) -> Void)

    /// Fetch a recommendation by its ID for particular customer.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - recommendation: Recommendations for the customer.
    ///   - completion: Object containing the request result.
    func fetchRecommendation(recommendation: RecommendationRequest, for customerIds: [AnyHashable: JSONConvertible],
                             completion: @escaping (Result<RecommendationResponse>) -> Void)

    /// Fetch multiple customer attributes at once
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - attributes: List of attributes you want to retrieve.
    func fetchAttributes(attributes: [AttributesDescription], for customerIds: [AnyHashable: JSONConvertible],
                         completion: @escaping (Result<AttributesListDescription>) -> Void)

    /// Fetch customer events by its type.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    ///   - events: List of event types to be retrieve.
    ///   - completion: Object containing the request result.
    func fetchEvents(events: EventsRequest, for customerIds: [AnyHashable: JSONConvertible],
                     completion: @escaping (Result<EventsResponse>) -> Void)
    
    /// Exports all properties, ids and events for one customer.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    func fetchAllProperties(for customerIds: [AnyHashable: JSONConvertible],
                            completion: @escaping (Result<[StringResponse]>) -> Void)

    /// Exports all customers who exist in the project.
    ///
    /// - Parameters:
    ///   - data: List of properties to retrieve.
    func fetchAllCustomers(data: CustomerExport,
                           completion: @escaping (Result<[StringResponse]>) -> Void)

    /// Removes all the external identifiers and assigns a new cookie id.
    /// Removes all personal customer properties.
    ///
    /// - Parameters:
    ///   - customerIds: Identification of a customer.
    func anonymize(customerIds: [AnyHashable: JSONConvertible],
                   completion: @escaping (Result<StringResponse>) -> Void)
}

protocol RepositoryType: class, TrackingRepository, TokenRepository, FetchRepository {
    var configuration: Configuration { get set }
}
