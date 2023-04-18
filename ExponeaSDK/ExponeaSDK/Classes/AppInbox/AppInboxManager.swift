//
//  AppInboxManager.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 27/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit

final class AppInboxManager: AppInboxManagerType {

    private let repository: RepositoryType
    private let trackingManager: TrackingManagerType
    private let appInboxCache: AppInboxCacheType
    private let databaseManager: DatabaseManagerType

    private let SUPPORTED_MESSAGE_TYPES: [String] = [
        "push", "html"
    ]

    init(
        repository: RepositoryType,
        trackingManager: TrackingManagerType,
        cache: AppInboxCacheType = AppInboxCache(),
        database: DatabaseManagerType
    ) {
        self.repository = repository
        self.trackingManager = trackingManager
        self.appInboxCache = cache
        self.databaseManager = database
    }

    func onEventOccurred(of type: EventType, for event: [DataType]) {
        if type == .identifyCustomer {
            Exponea.logger.log(.verbose, message: "CustomerIDs are updated, clearing AppInbox messages")
            clear()
        }
    }

    func fetchAppInbox(completion: @escaping (Result<[MessageItem]>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                Exponea.logger.log(.error, message: "Fetching AppInbox stops due to obsolete thread")
                completion(.failure(ExponeaError.stoppedProcess))
                return
            }
            let customerIds = self.trackingManager.customerIds
            let customerId = self.trackingManager.customerCookie
            self.repository.fetchAppInbox(
                for: customerIds,
                with: self.appInboxCache.getSyncToken()
            ) { result in
                switch result {
                case .success(let response):
                    Exponea.logger.log(.verbose, message: "AppInbox loaded successfully")
                    let enhancedMessages = self.enhanceMessages(response.messages, response.syncToken, customerIds: customerIds)
                    self.onAppInboxDataLoaded(enhancedMessages, response.syncToken, completion)
                case .failure(let error):
                    Exponea.logger.log(.error, message: "AppInbox loading failed. \(error.localizedDescription)")
                    print(error)
                    DispatchQueue.main.async {
                        completion(Result.failure(error))
                    }
                }
            }
        }
    }

    func fetchAppInboxItem(_ messageId: String, completion: @escaping (Result<MessageItem>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                Exponea.logger.log(.error, message: "Fetch AppInbox item stops due to obsolete thread")
                completion(.failure(ExponeaError.stoppedProcess))
                return
            }
            // find message locally
            if let message = self.appInboxCache.getMessages().first(where: { msg in msg.id == messageId }) {
                DispatchQueue.main.async {
                    completion(.success(message))
                }
                return
            }
            // try find message online
            self.fetchAppInbox { _ in
                if let message = self.appInboxCache.getMessages().first(where: { msg in msg.id == messageId }) {
                    DispatchQueue.main.async {
                        completion(.success(message))
                    }
                    return
                }
                Exponea.logger.log(.warning, message: "AppInbox message \(messageId) not found")
                DispatchQueue.main.async {
                    completion(.failure(RepositoryError.missingData("AppInbox message not found")))
                }
            }
        }
    }

    func markMessageAsRead(_ message: MessageItem, _ customerIdsCheck: TypeBlock<Bool>? = nil, _ completition: ((Bool) -> Void)?) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                Exponea.logger.log(.error, message: "MarkAsRead AppInbox stops due to obsolete thread")
                DispatchQueue.main.async {
                    completition?(false)
                }
                return
            }
            guard !message.customerIds.isEmpty, let syncToken = message.syncToken else {
                Exponea.logger.log(.error, message: "Unable to mark message \(message.id) as read, try to fetch AppInbox")
                DispatchQueue.main.async {
                    completition?(false)
                }
                return
            }
            // For test only
            if customerIdsCheck != nil {
                customerIdsCheck?(message.customerIds.first(where: { $0.key == "id" && $0.value == "1" }) != nil)
            }
            self.repository.postReadFlagAppInbox(
                on: [message.id],
                for: message.customerIds,
                with: syncToken
            ) { result in
                switch result {
                case .success:
                    self.markMessageDataAsRead(message.id)
                    DispatchQueue.main.async {
                        completition?(true)
                    }
                case .failure:
                    DispatchQueue.main.async {
                        completition?(false)
                    }
                }
            }
        }
    }

    func markMessageDataAsRead(_ messageId: String) {
        var currentMessages = appInboxCache.getMessages()
        for index in currentMessages.indices {
            if currentMessages[index].id == messageId {
                currentMessages[index].read = true
            }
        }
        appInboxCache.setMessages(messages: currentMessages)
    }

    private func enhanceMessages(_ messages: [MessageItem]?, _ syncToken: String?, customerIds: [String : String]) -> [MessageItem] {
        guard let messages = messages, !messages.isEmpty else {
            return []
        }
        return messages.map { msg in
            var copy = msg
            copy.syncToken = syncToken
            copy.customerIds = customerIds
            return copy
        }
    }

    private func onAppInboxDataLoaded(_ messages: [MessageItem], _ syncToken: String?, _ completion: @escaping (Result<[MessageItem]>) -> Void) {
        if let syncToken = syncToken {
            appInboxCache.setSyncToken(token: syncToken)
        }
        let supportedMessages = messages.filter { msg in
            return SUPPORTED_MESSAGE_TYPES.contains(msg.type)
        }
        appInboxCache.addMessages(messages: supportedMessages)
        let imageUrls: [String] = supportedMessages
            .map { message in message.content?.imageUrl ?? "" }
            .filter { imageUrl in imageUrl.isEmpty == false }
        let allMessages = appInboxCache.getMessages()
        if imageUrls.isEmpty {
            DispatchQueue.main.async {
                completion(Result.success(allMessages))
            }
            return
        }
        for imageUrlString in imageUrls {
            if appInboxCache.hasImageData(at: imageUrlString) {
                continue
            }
            let imageData: Data? = ImageUtils.tryDownloadImage(imageUrlString)
            guard imageData != nil else {
                continue
            }
            appInboxCache.saveImageData(at: imageUrlString, data: imageData!)
        }
        DispatchQueue.main.async {
            completion(Result.success(allMessages))
        }
    }

    func clear() {
        appInboxCache.clear()
    }
}
