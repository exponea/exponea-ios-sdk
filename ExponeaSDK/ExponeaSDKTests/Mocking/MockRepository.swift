//
//  MockRepository.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

final class MockRepository: RepositoryType {
    var configuration: Configuration

    var trackCustomerResult: EmptyResult<RepositoryError>? = EmptyResult.failure(RepositoryError.connectionError)
    var trackEventResult: EmptyResult<RepositoryError>? = EmptyResult.failure(RepositoryError.connectionError)
    var fetchRecommendationResult: Result<RecommendationResponse<EmptyRecommendationData>>?
        = Result.failure(RepositoryError.connectionError)
    var fetchBannersResult: Result<BannerResponse>? = Result.failure(RepositoryError.connectionError)
    var fetchPersonalizationResult: Result<PersonalizationResponse>? = Result.failure(RepositoryError.connectionError)
    var fetchConsentsResult: Result<ConsentsResponse>? = Result.failure(RepositoryError.connectionError)
    var fetchInAppMessagesResult: Result<InAppMessagesResponse>? = Result.failure(RepositoryError.connectionError)

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func cancelRequests() {
        fatalError("Not implemented")
    }

    func trackCustomer(
        with data: [DataType],
        for customerIds: [String: JSONValue],
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        if let mockResult = trackCustomerResult {
            completion(mockResult)
        }
    }

    func trackEvent(
        with data: [DataType],
        for customerIds: [String: JSONValue],
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        if let mockResult = trackEventResult {
            completion(mockResult)
        }
    }

    func fetchRecommendation<T>(
        request: RecommendationRequest,
        for customerIds: [String: JSONValue],
        completion: @escaping (Result<RecommendationResponse<T>>) -> Void
    ) where T: RecommendationUserData {
        if let mockResult = fetchRecommendationResult as? Result<RecommendationResponse<T>> {
            completion(mockResult)
        }
    }

    func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void) {
        if let mockResult = fetchBannersResult {
            completion(mockResult)
        }
    }

    func fetchPersonalization(
        with request: PersonalizationRequest,
        for customerIds: [String: JSONValue],
        completion: @escaping (Result<PersonalizationResponse>) -> Void
    ) {
        if let mockResult = fetchPersonalizationResult {
            completion(mockResult)
        }
    }

    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        if let mockResult = fetchConsentsResult {
            completion(mockResult)
        }
    }

    func fetchInAppMessages(
        for customerIds: [String: JSONValue],
        completion: @escaping (Result<InAppMessagesResponse>) -> Void
    ) {
        if let mockResult = fetchInAppMessagesResult {
            completion(mockResult)
        }
    }
}
