//
//  InAppMessagesManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class InAppMessagesManager: InAppMessagesManagerType {
    private let repository: RepositoryType
    private let trackingManager: TrackingManagerType
    // cache is synchronous, be careful about calling it from main thread
    private let cache: InAppMessagesCacheType

    init(
        repository: RepositoryType,
        trackingManager: TrackingManagerType,
        cache: InAppMessagesCacheType = InAppMessagesCache()
    ) {
        self.repository = repository
        self.trackingManager = trackingManager
        self.cache = cache
    }

    func preload(completion: (() -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.repository.fetchInAppMessages(for: self.trackingManager.customerIds) { result in
                guard case .success(let response) = result else {
                    Exponea.logger.log(.warning, message: "Fetching in-app messages from server failed.")
                    completion?()
                    return
                }
                self.cache.saveInAppMessages(inAppMessages: response.data)
                completion?()
            }
        }
    }

    func getInAppMessage() -> InAppMessage? {
        return self.cache.getInAppMessages().randomElement()
    }
}
