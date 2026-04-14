//
//  ServerRepository+SelfCheckRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 26/05/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif
import Foundation

extension ServerRepository: SelfCheckRepository {
    func requestSelfCheckPush(
        for customerIds: [String: String],
        pushToken: String,
        completion: @escaping (EmptyResult<RepositoryError>) -> Void
    ) {
        let router = makeRouter(for: .pushSelfCheck, project: configuration.mainProject)
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(
            withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) },
            completion: completion
        )
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest(
                    parameters: PushSelfCheckRequest(pushToken: pushToken),
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
}
