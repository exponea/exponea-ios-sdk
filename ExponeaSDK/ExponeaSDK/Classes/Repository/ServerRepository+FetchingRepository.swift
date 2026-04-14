//
//  ServerRepository+FetchingRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif
import Foundation

extension ServerRepository: FetchRepository {

    /// In Stream mode, JWT is required for App Inbox. If missing, invokes `onAuthorizationError` once so the app can set the token; if still missing, returns an error (caller must not send the request).
    /// - Parameter path: Endpoint path for the error callback (e.g. from `router.getPath()`).
    /// - Returns: `RepositoryError.notAuthorized(nil)` when JWT is still missing after giving the app one chance; `nil` to proceed.
    private func requireStreamJwtForAppInbox(path: String) -> RepositoryError? {
        guard case .stream = configuration.integrationConfig.type else { return nil }
        let token = streamAuthProvider?.getAuthorizationToken()
        guard token == nil || token?.isEmpty == true else { return nil }
        onAuthorizationError?(path, 401, nil)
        let tokenAfter = streamAuthProvider?.getAuthorizationToken()
        guard let tokenAfter, !tokenAfter.isEmpty else {
            return .notAuthorized(nil)
        }
        return nil
    }

    func fetchRecommendation<T: RecommendationUserData>(
        options: RecommendationOptions,
        for customerIds: [String: String],
        completion: @escaping (Result<RecommendationResponse<T>>) -> Void
    ) {
        do {
            let project = configuration.mainProject
            
            switch project.type {
            case .project:
                let parameters = RecommendationRequest(options: options)
                let router = makeRouter(for: .customerAttributes, project: project)
                let request = try router.prepareRequest(parameters: parameters, customerIds: customerIds)

                session
                    .dataTask(
                        with: request,
                        completionHandler: router.handler(
                            with: { (result: Result<WrappedRecommendationResponse<T>>) in
                                if let response = result.value {
                                    if response.success, response.results.count > 0 {
                                        completion(Result.success(response.results[0]))
                                    } else {
                                        completion(Result.failure(RepositoryError.serverError(nil)))
                                    }
                                } else {
                                    completion(Result.failure(result.error ?? RepositoryError.serverError(nil)))
                                }
                            }
                        )
                    )
                    .resume()
            case .stream:
                let parameters = RecommendationsStreamRequest(
                    customerIds: customerIds,
                    engineId: options.id,
                    fillWithRandom: options.fillWithRandom,
                    size: options.size,
                    items: options.items,
                    noTrack: options.noTrack,
                    catalogAttributesWhitelist: options.catalogAttributesWhitelist
                )
                let router = makeRouter(for: .recommendations, project: project)
                var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
                let (handler, startRequest) = router.handler(
                    withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) },
                    completion: { (result: Result<RecommendationsStreamResponse<T>>) in
                        if let response = result.value {
                            if response.success, let data = response.data {
                                let recommendationResponseData = RecommendationResponse(
                                    success: response.success,
                                    error: response.errors,
                                    value: data
                                )
                                completion(Result.success(recommendationResponseData))
                            } else {
                                completion(Result.failure(RepositoryError.serverError(nil)))
                            }
                        } else {
                            completion(Result.failure(result.error ?? RepositoryError.serverError(nil)))
                        }
                    }
                )
                executeRequest = { setRequestHadJwt in
                    do {
                        let request = try router.prepareRequest(parameters: parameters, customerIds: customerIds)
                        setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                        self.session.dataTask(with: request, completionHandler: handler).resume()
                    } catch {
                        completion(.failure(RepositoryError.unknown(error)))
                    }
                }
                startRequest()
            }
        } catch let error {
            completion(.failure(RepositoryError.unknown(error)))
        }
    }

    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        let router = makeRouter(for: .consents, project: configuration.mainProject)
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest()
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }

    func fetchInAppMessages(
        for customerIds: [String: String],
        completion: @escaping (Result<InAppMessagesResponse>) -> Void
    ) {
        let router = makeRouter(for: .inAppMessages, project: configuration.mainProject)
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest(parameters: InAppMessagesRequest(), customerIds: customerIds)
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }

    func fetchAppInbox(
        for customerIds: [String: String],
        with syncToken: String?,
        completion: @escaping (Result<AppInboxResponse>) -> Void
    ) {
        let router = makeRouter(for: .appInbox)
        let path = (try? router.getPath()) ?? ""
        if let error = requireStreamJwtForAppInbox(path: path) {
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest(
                    parameters: AppInboxRequest(
                        syncToken: syncToken,
                        applicationID: self.configuration.applicationID
                    ),
                    customerIds: customerIds
                )
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }

    func postReadFlagAppInbox(
        on messageIds: [String],
        for customerIds: [String: String],
        with syncToken: String,
        completion: @escaping (EmptyResult<RepositoryError>) -> Void
    ) {
        let router = makeRouter(for: .appInboxMarkRead)
        let path = (try? router.getPath()) ?? ""
        if let error = requireStreamJwtForAppInbox(path: path) {
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest(
                    parameters: AppInboxMarkReadRequest(messageIds: messageIds, syncToken: syncToken),
                    customerIds: customerIds
                )
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }

    func getInAppContentBlocks(
        completion: @escaping TypeBlock<Result<InAppContentBlocksDataResponse>>
    ) {
        let router = makeRouter(for: .inAppContentBlocks)
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest()
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }

    func personalizedInAppContentBlocks(
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        completion: @escaping (Result<PersonalizedInAppContentBlockResponseData>) -> Void
    ) {
        let router = makeRouter(for: .personalizedInAppContentBlocks)
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest(
                    parameters: InAppContentBlocksRequest(messageIds: inAppContentBlocksIds),
                    customerIds: customerIds
                )
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }

    func getSegmentations(
        cookie: String,
        completion: @escaping TypeBlock<Result<SegmentDataDTO>>
    ) {
        let router = makeRouter(for: .segmentation(cookie: cookie))
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest()
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }

    func getLinkIds(
        cookie: String,
        externalIds: [String: String],
        completion: @escaping TypeBlock<Result<SegmentDataDTO>>
    ) {
        let router = makeRouter(for: .linkIds(cookie: cookie))
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest(
                    parameters: LinkIdsRequest(externalIds: externalIds)
                )
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }
}
