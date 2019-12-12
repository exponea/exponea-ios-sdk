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
                       for customerIds: [String: JSONValue],
                       completion: @escaping ((EmptyResult<RepositoryError>) -> Void))

    /// Tracks new events for a customer.
    ///
    /// - Parameters:
    ///     - data: Object containing the data to be used to track a customer data.
    ///     - customerIds: Customer identification.
    ///     - completion: Object containing the request result.
    func trackEvent(with data: [DataType],
                    for customerIds: [String: JSONValue],
                    completion: @escaping ((EmptyResult<RepositoryError>) -> Void))
}

protocol FetchRepository {
    /// Fetch a recommendation by its ID for particular customer.
    /// Recommendations contain fields as defined on Exponea backend.
    /// You can define your own struct for contents of those fields and call this generic function with that struct.
    ///
    /// - Parameters:
    ///   - request: Recommendations request.
    ///   - customerIds: Identification of a customer.
    ///   - completion: Object containing the request result.
    func fetchRecommendation<T: RecommendationUserData>(
        request: RecommendationRequest,
        for customerIds: [String: JSONValue],
        completion: @escaping (Result<RecommendationResponse<T>>
    ) -> Void)

    /// Fetch all available banners.
    ///
    /// - Parameters:
    ///   - completion: Object containing the request result.
    func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void)

    /// Fetch personalization (all banners) for current customer.
    ///
    /// - Parameters:
    ///   - request: Personalization request containing all the information about the request banners.
    ///   - customerIds: Identification of a customer.
    ///   - completion: Object containing the request result.
    func fetchPersonalization(with request: PersonalizationRequest, for customerIds: [String: JSONValue],
                              completion: @escaping (Result<PersonalizationResponse>) -> Void)

    /// Fetch the list of your existing consent categories.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void)

    func fetchInAppMessages(
        for customerIds: [String: JSONValue],
        completion: @escaping (Result<InAppMessagesResponse>) -> Void
    )
}

protocol RepositoryType: class, TrackingRepository, FetchRepository {
    var configuration: Configuration { get set }

    /// Cancels all requests that are currently underway.
    func cancelRequests()
}
