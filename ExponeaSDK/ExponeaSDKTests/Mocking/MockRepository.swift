//
//  MockRepository.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

final class MockRepository: RepositoryType {
    func getSegmentations(cookie: String, completion: @escaping TypeBlock<Result<SegmentDataDTO>>) {
        
    }
    
    func getLinkIds(cookie: String, externalIds: [String : String], completion: @escaping TypeBlock<Result<SegmentDataDTO>>) {
        
    }
    
    
    func getInAppContentBlocks(
        completion: @escaping TypeBlock<Result<InAppContentBlocksDataResponse>>
    ) {
        completion(fetchInAppContentBlocksPlaceholdersResult)
    }

    func personalizedInAppContentBlocks(
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        completion: @escaping TypeBlock<Result<PersonalizedInAppContentBlockResponseData>>
    ) {
        completion(fetchInAppContentBlocksResult)
    }

    var configuration: Configuration

    var trackObjectResult: EmptyResult<RepositoryError> = EmptyResult.failure(RepositoryError.connectionError)
    var trackObjectHook: ((TrackingObject) -> Void)?
    var fetchRecommendationResult: Result<RecommendationResponse<EmptyRecommendationData>>
        = Result.failure(RepositoryError.connectionError)
    var fetchConsentsResult: Result<ConsentsResponse> = Result.failure(RepositoryError.connectionError)
    var fetchInAppMessagesResult: Result<InAppMessagesResponse> = Result.failure(RepositoryError.connectionError)
    var fetchAppInboxResult: Result<AppInboxResponse> = Result.failure(RepositoryError.connectionError)
    var fetchAppInboxAction: ((_ syncToken: String?, _ completion: @escaping (Result<AppInboxResponse>) -> Void) -> Void)?
    var fetchInAppContentBlocksPlaceholdersResult: Result<InAppContentBlocksDataResponse> = Result.failure(RepositoryError.connectionError)
    var fetchInAppContentBlocksResult: Result<PersonalizedInAppContentBlockResponseData> = Result.failure(RepositoryError.connectionError)

    init(configuration: Configuration) {
        IntegrationManager.shared.isStopped = false
        self.configuration = configuration
    }

    func cancelRequests() {
        fatalError("Not implemented")
    }

    func trackObject(
        _ object: TrackingObject,
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        trackObjectHook?(object)
        completion(trackObjectResult)
    }

    func fetchRecommendation<T>(
        options: RecommendationOptions,
        for customerIds: [String: String],
        completion: @escaping (Result<RecommendationResponse<T>>) -> Void
    ) where T: RecommendationUserData {
        fatalError("Only implemented for EmptyRecommendationData")
    }

    func fetchRecommendation(
        options: RecommendationOptions,
        for customerIds: [String: String],
        completion: @escaping (Result<RecommendationResponse<EmptyRecommendationData>>) -> Void
    ) {
        completion(fetchRecommendationResult)
    }

    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        completion(fetchConsentsResult)
    }

    func fetchInAppMessages(
        for customerIds: [String: String],
        completion: @escaping (Result<InAppMessagesResponse>) -> Void
    ) {
        completion(fetchInAppMessagesResult)
    }

    func requestSelfCheckPush(
        for customerIds: [String: String],
        pushToken: String,
        completion: @escaping (EmptyResult<RepositoryError>) -> Void
    ) {
        completion(EmptyResult.success)
    }

    func requestLastSDKVersion(
        completion: @escaping (Result<String>) -> Void
    ) {
        completion(.success("1.0.0"))
    }

    func fetchAppInbox(
        for customerIds: [String : String],
        with syncToken: String?,
        completion: @escaping (Result<AppInboxResponse>) -> Void
    ) {
        if let action = fetchAppInboxAction {
            action(syncToken, completion)
        } else {
            completion(fetchAppInboxResult)
        }
    }

    func postReadFlagAppInbox(
        on messageIds: [String],
        for customerIds: [String: String],
        with syncToken: String,
        completion: @escaping (EmptyResult<RepositoryError>) -> Void
    ) {
        completion(.success)
    }
}
