//
//  FetchRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

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
        for customerIds: [String: String],
        completion: @escaping (Result<RecommendationResponse<T>>) -> Void
    )

    /// Fetch the list of your existing consent categories.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void)

    func fetchInAppMessages(
        for customerIds: [String: String],
        completion: @escaping (Result<InAppMessagesResponse>) -> Void
    )

    func fetchAppInbox(
        for customerIds: [String: String],
        with syncToken: String?,
        completion: @escaping (Result<AppInboxResponse>) -> Void
    )

    func postReadFlagAppInbox(
        on messageIds: [String],
        for customerIds: [String: String],
        with syncToken: String,
        completion: @escaping (EmptyResult<RepositoryError>) -> Void
    )

    func getInAppContentBlocks(
        completion: @escaping TypeBlock<Result<InAppContentBlocksDataResponse>>
    )

    func personalizedInAppContentBlocks(
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        completion: @escaping TypeBlock<Result<PersonalizedInAppContentBlockResponseData>>
    )

    func getSegmentations(
        cookie: String,
        completion: @escaping TypeBlock<Result<SegmentDataDTO>>
    )

    func getLinkIds(
        cookie: String,
        externalIds: [String: String],
        completion: @escaping TypeBlock<Result<SegmentDataDTO>>
    )
}
