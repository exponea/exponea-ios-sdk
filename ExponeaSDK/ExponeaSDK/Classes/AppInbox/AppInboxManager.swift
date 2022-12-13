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

    private let SUPPORTED_MESSAGE_TYPES: [String] = [
        "push"
    ]

    init(
        repository: RepositoryType,
        trackingManager: TrackingManagerType,
        cache: AppInboxCacheType = AppInboxCache()
    ) {
        self.repository = repository
        self.trackingManager = trackingManager
        self.appInboxCache = cache
    }

    func onEventOccurred(of type: EventType, for event: [DataType]) {
        if (type == .identifyCustomer) {
            Exponea.logger.log(.verbose, message: "CustomerIDs are updated, clearing AppInbox messages")
            clear()
        }
    }

    func fetchAppInbox(completion: @escaping (Result<[MessageItem]>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.repository.fetchAppInbox(
                for: self.trackingManager.customerIds,
                with: self.appInboxCache.getSyncToken()
            ) { result in
                switch result {
                case .success(let response):
                    Exponea.logger.log(.verbose, message: "AppInbox loaded successfully")
                    self.onAppInboxDataLoaded(response, completion)
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
        DispatchQueue.global(qos: .background).async {
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

    func markMessageAsRead(_ messageId: String, _ completition: ((Bool) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.repository.postReadFlagAppInbox(
                on: [messageId],
                for: self.trackingManager.customerIds
            ) { result in
                switch result {
                case .success:
                    self.markMessageDataAsRead(messageId)
                    completition?(true)
                case .failure(_):
                    completition?(false)
                }
            }
        }
    }

    func markMessageDataAsRead(_ messageId: String) {
        var currentMessages = appInboxCache.getMessages()
        for index in currentMessages.indices {
            if (currentMessages[index].id == messageId) {
                currentMessages[index].read = true
            }
        }
        appInboxCache.setMessages(messages: currentMessages)
    }

    func onAppInboxDataLoaded(_ response: AppInboxResponse, _ completion: @escaping (Result<[MessageItem]>) -> Void) {
        if let syncToken = response.syncToken {
            appInboxCache.setSyncToken(token: syncToken)
        }
        let messages = response.messages ?? []
        let supportedMessages = messages.filter { msg in
            return SUPPORTED_MESSAGE_TYPES.contains(msg.type)
        }
        appInboxCache.addMessages(messages: supportedMessages)
        let imageUrls: [String] = supportedMessages
            .map { message in message.content?.imageUrl ?? "" }
            .filter { imageUrl in imageUrl.isEmpty == false}
        let allMessages = appInboxCache.getMessages()
        if (imageUrls.isEmpty) {
            DispatchQueue.main.async {
                completion(Result.success(allMessages))
            }
            return
        }
        for imageUrlString in imageUrls {
            if (appInboxCache.hasImageData(at: imageUrlString)) {
                continue
            }
            let imageData: Data? = tryDownloadImage(imageUrlString)
            guard imageData != nil else {
                continue
            }
            appInboxCache.saveImageData(at: imageUrlString, data: imageData!)
        }
        DispatchQueue.main.async {
            completion(Result.success(allMessages))
        }
    }

    private func tryDownloadImage(_ imageSource: String?) -> Data? {
        guard imageSource != nil,
              let imageUrl = URL(string: imageSource!)
                else {
            Exponea.logger.log(.error, message: "Image cannot be downloaded \(imageSource ?? "<is nil>")")
            return nil
        }
        let semaphore = DispatchSemaphore(value: 0)
        var imageData: Data?
        let dataTask = URLSession.shared.dataTask(with: imageUrl) { data, response, error in {
            imageData = data
            semaphore.signal()
        }() }
        dataTask.resume()
        let awaitResult = semaphore.wait(timeout: .now() + 10.0)
        switch (awaitResult) {
        case .success:
            // Nothing to do, let check imageData
            break
        case .timedOut:
            Exponea.logger.log(.warning, message: "Image \(imageSource!) may be too large or slow connection - aborting")
            dataTask.cancel()
        }
        return imageData
    }

    func clear() {
        self.appInboxCache.clear()
    }
}
