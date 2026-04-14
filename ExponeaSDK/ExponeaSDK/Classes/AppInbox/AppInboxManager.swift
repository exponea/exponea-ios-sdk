//
//  AppInboxManager.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 27/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

final class AppInboxManager: AppInboxManagerType {

    private let repository: RepositoryType
    private let trackingManager: TrackingManagerType
    private let appInboxCache: AppInboxCacheType
    private let databaseManager: DatabaseManagerType
    private var isFetching = false
    private var savedCustomerIds: [[String: String]] = []
    private let fetchLock = NSLock()

    private let SUPPORTED_MESSAGE_TYPES: [String] = [
        "push", "html"
    ]

    init(
        repository: RepositoryType,
        trackingManager: TrackingManagerType,
        cache: AppInboxCacheType = AppInboxCache.shared,
        database: DatabaseManagerType,
        cachedAppId: String = Constants.General.applicationID
    ) {

        self.repository = repository
        self.trackingManager = trackingManager
        self.appInboxCache = cache
        self.databaseManager = database

        if cachedAppId != repository.configuration.applicationID {
            clear()
        }

        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            guard let self else { return }
            self.clear()
        }
    }

    func onEventOccurred(of type: EventType, for event: [DataType]) {
        fetchLock.lock()
        guard !isFetching else {
            if type == .identifyCustomer {
                savedCustomerIds.append(trackingManager.customerIds)
            }
            fetchLock.unlock()
            return
        }
        fetchLock.unlock()
        if type == .identifyCustomer {
            Exponea.logger.log(.verbose, message: "CustomerIDs are updated, clearing AppInbox messages")
            clear()
            self.appInboxCache.setSyncToken(token: nil)
            self.appInboxCache.deleteImages(except: [])
        }
    }

    func fetchAppInbox(customerIds: [String: String]?, completion: @escaping (Result<[MessageItem]>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                Exponea.logger.log(.error, message: "Fetching AppInbox stops due to obsolete thread")
                DispatchQueue.main.async {
                    completion(.failure(ExponeaError.stoppedProcess))
                }
                return
            }
            self.fetchLock.lock()
            self.isFetching = true
            self.fetchLock.unlock()
            let customerIds = customerIds ?? self.trackingManager.customerIds
            guard !IntegrationManager.shared.isStopped else {
                Exponea.logger.log(.error, message: "AppInbox fetch failed, SDK is stopping")
                self.fetchLock.lock()
                self.isFetching = false
                self.fetchLock.unlock()
                DispatchQueue.main.async {
                    completion(.failure(ExponeaError.stoppedProcess))
                }
                return
            }
            self.repository.fetchAppInbox(
                for: customerIds,
                with: self.appInboxCache.getSyncToken()
            ) { result in
                guard !IntegrationManager.shared.isStopped else {
                    Exponea.logger.log(.error, message: "AppInbox fetch failed, SDK is stopping")
                    self.fetchLock.lock()
                    self.isFetching = false
                    self.fetchLock.unlock()
                    DispatchQueue.main.async {
                        completion(.failure(ExponeaError.stoppedProcess))
                    }
                    return
                }
                switch result {
                case .success(let response):
                    self.trackTelemetry(result)
                    self.fetchLock.lock()
                    guard self.savedCustomerIds.last == nil || Exponea.shared.trackingManager?.customerIds == self.savedCustomerIds.last else {
                        let newCustomerIds = self.savedCustomerIds.last
                        self.savedCustomerIds.removeAll()
                        self.fetchLock.unlock()
                        self.clear()
                        if let newCustomerIds {
                            self.fetchAppInbox(customerIds: newCustomerIds, completion: completion)
                        } else {
                            self.fetchLock.lock()
                            self.isFetching = false
                            self.fetchLock.unlock()
                            DispatchQueue.main.async {
                                completion(.failure(ExponeaError.stoppedProcess))
                            }
                        }
                        return
                    }
                    self.savedCustomerIds.removeAll()
                    self.fetchLock.unlock()
                    Exponea.logger.log(.verbose, message: "AppInbox loaded successfully")
                    let enhancedMessages = self.enhanceMessages(response.messages, response.syncToken, customerIds: customerIds)
                    self.onAppInboxDataLoaded(enhancedMessages, response.syncToken, completion)
                case .failure(let error):
                    if self.appInboxCache.getSyncToken() != nil,
                       case .resourceGone = error as? RepositoryError {
                        Exponea.logger.log(
                            .warning,
                            message: "AppInbox sync token is invalid, clearing cache and retrying full sync"
                        )
                        self.clear()
                        self.fetchAppInbox(customerIds: customerIds, completion: completion)
                        return
                    }
                    self.trackTelemetry(result)
                    Exponea.logger.log(.error, message: "AppInbox loading failed. \(error.localizedDescription)")
                    self.fetchLock.lock()
                    self.isFetching = false
                    self.fetchLock.unlock()
                    DispatchQueue.main.async {
                        completion(Result.failure(error))
                    }
                }
            }
        }
    }

    private func trackTelemetry(_ result: Result<AppInboxResponse>) {
        let isInitFetch = self.appInboxCache.getSyncToken() == nil
        let messages = result.value?.messages ?? []
        Exponea.shared.telemetryManager?.report(
            eventWithType: isInitFetch ? .appInboxInitFetch : .appInboxSyncFetch,
            properties: [
                "count": String(messages.count),
                "data": TelemetryUtility.toJson(messages.map { [
                    "type": $0.type,
                    "messageId": $0.id,
                    "campaignId": TelemetryUtility.readAsString($0.content?.trackingData?["campaign_id"]?.rawValue)
                ] })
            ]
        )
    }

    func fetchAppInboxItem(_ messageId: String, completion: @escaping (Result<MessageItem>) -> Void) {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "AppInbox fetch failed, SDK is stopping")
            DispatchQueue.main.async {
                completion(.failure(ExponeaError.stoppedProcess))
            }
            return
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                Exponea.logger.log(.error, message: "Fetch AppInbox item stops due to obsolete thread")
                DispatchQueue.main.async {
                    completion(.failure(ExponeaError.stoppedProcess))
                }
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

    func markMessageAsRead(_ message: MessageItem, _ customerIdsCheck: TypeBlock<Bool>? = nil, _ completion: ((Bool) -> Void)?) {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "AppInbox message \(message.id) not read, SDK is stopping")
            DispatchQueue.main.async {
                completion?(false)
            }
            return
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else {
                Exponea.logger.log(.error, message: "MarkAsRead AppInbox stops due to obsolete thread")
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            guard !message.customerIds.isEmpty, let syncToken = message.syncToken else {
                Exponea.logger.log(.error, message: "Unable to mark message \(message.id) as read, try to fetch AppInbox")
                DispatchQueue.main.async {
                    completion?(false)
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
                        completion?(true)
                    }
                case .failure:
                    DispatchQueue.main.async {
                        completion?(false)
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
            fetchLock.lock()
            isFetching = false
            fetchLock.unlock()
            DispatchQueue.main.async {
                completion(Result.success(allMessages))
            }
            return
        }
        for imageUrlString in imageUrls {
            if appInboxCache.hasImageData(at: imageUrlString) {
                continue
            }
            guard let imageData = ImageUtils.tryDownloadImage(imageUrlString) else {
                continue
            }
            appInboxCache.saveImageData(at: imageUrlString, data: imageData)
        }
        fetchLock.lock()
        isFetching = false
        fetchLock.unlock()
        DispatchQueue.main.async {
            completion(Result.success(allMessages))
        }
    }

    func clear() {
        appInboxCache.clear()
    }
}
