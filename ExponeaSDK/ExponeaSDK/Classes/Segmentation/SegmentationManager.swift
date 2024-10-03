//
//  SegmentationManager.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.04.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

public enum SegmentTriggerType {
    case `init`
    case register(data: SegmentCallbackData)
    case identify
}

public struct SegmentCallbackData: Equatable {
    let category: SegmentCategory
    let isIncludeFirstLoad: Bool
    let id = UUID()
    var onNewData: TypeBlock<[SegmentDTO]>?

    public init(category: SegmentCategory, isIncludeFirstLoad: Bool, onNewData: TypeBlock<[SegmentDTO]>?) {
        self.category = category
        self.isIncludeFirstLoad = isIncludeFirstLoad
        self.onNewData = onNewData
    }

    public static func == (lhs: SegmentCallbackData, rhs: SegmentCallbackData) -> Bool {
        String(describing: lhs.id) == String(describing: rhs.id)
    }

    public func fireBlock(category: [SegmentDTO]) {
        onNewData?(category)
    }

    public mutating func releaseBlock() {
        onNewData = nil
    }
}

public protocol SegmentationManagerType {
    func getNewbies() -> [SegmentCallbackData]
    func getCallbacks() -> [SegmentCallbackData]
    func processTriggeredBy(type: SegmentTriggerType)
    func unionSegments(first: [SegmentCategory], second: [SegmentCategory]) -> [SegmentCategory]
    func anonymize()
    func removeAll()
    func addCallback(callbackData: SegmentCallbackData)
    func removeCallback(callbackData: SegmentCallbackData)
    func synchronizeSegments(customerIds: [String: String], input: SegmentDataDTO) -> [SegmentCategory]
}

public final class SegmentationManager: SegmentationManagerType {

    // MARK: - Init
    public static let shared = SegmentationManager()

    @Atomic private var callbacks: [SegmentCallbackData] = []
    @Atomic private var newbieCallbacks: [SegmentCallbackData] = []
    private let dataProvider = SegmentationDataProvider()
    private lazy var debouncer = Debouncer(delay: 5)
    private var savedCustomerIds: [String: String] = [:]
    @SegmentationStoring private var storedSegmentations: SegmentStore?
    private var areCustomerIdsEqual: Bool {
        guard let currentCustomerIds = Exponea.shared.trackingManager?.customerIds else { return false }
        let areSame = currentCustomerIds.compareWith(other: savedCustomerIds)
        if !areSame {
            Exponea.logger.log(.verbose, message: "Segments: Check process was canceled because customer has changed")
        }
        return areSame
    }
    private var externalIds: [String: String] {
        guard var ids = Exponea.shared.trackingManager?.customerIds else { return [:] }
        ids["cookie"] = nil
        return ids
    }
    private var customerIdsNeedsSync: Bool {
        areCustomerIdsEqual && !externalIds.isEmpty
    }

    private init() {}
}

// MARK: Methods
extension SegmentationManager {
    // Just for test purpose
    public func removeAll() {

        callbacks.removeAll()
        newbieCallbacks.removeAll()
        debouncer.stop()
        storedSegmentations = nil
    }

    public func anonymize() {
        newbieCallbacks.removeAll()
        storedSegmentations = nil
        debouncer.stop()
        Exponea.logger.log(.verbose, message: "Segments: Segments change check has been cancelled meanwhile")
    }

    public func processTriggeredBy(type: SegmentTriggerType) {
        switch type {
        case .`init`:
            let newbies = callbacks.filter { $0.isIncludeFirstLoad }
            _newbieCallbacks.changeValue(with: { $0.append(contentsOf: newbies) })
            if callbacks.isEmpty {
                Exponea.logger.log(.verbose, message: "Segments: Skipping initial segments update process for no callback")
            }
            processFetch()
        case let .register(data):
            if data.isIncludeFirstLoad {
                _newbieCallbacks.changeValue(with: { $0.append(data) })
            }
            if Exponea.shared.isConfigured {
                processFetch()
            }
        case .identify:
            processFetch()
        }
    }

    private func processFetch() {
        guard !callbacks.isEmpty else {
            Exponea.logger.log(.verbose, message: "Segments: Skipping segments update process after tracked event due to no callback registered")
            return
        }
        segmentChangeCheck()
    }

    private func segmentChangeCheck() {
        savedCustomerIds = Exponea.shared.trackingManager?.customerIds ?? [:]
        debouncer.debounce { [weak self] in
            guard let self else { return }
            let currentCusomterIds = Exponea.shared.trackingManager?.customerIds ?? [:]
            let currentNewbies = self.newbieCallbacks
            if currentNewbies.isEmpty {
                Exponea.logger.log(.verbose, message: "Segments: Skipping initial segments update process as is not required")
            }
            self._newbieCallbacks.changeValue(with: { $0.removeAll() })
            guard self.areCustomerIdsEqual else { return }
            if self.customerIdsNeedsSync {
                linkIds {
                    self.getSegments(customerIds: currentCusomterIds, newbies: currentNewbies)
                }
            } else {
                self.getSegments(customerIds: currentCusomterIds, newbies: currentNewbies)
            }
        }
    }

    public func unionSegments(first: [SegmentCategory], second: [SegmentCategory]) -> [SegmentCategory] {
        let source = first + second
        var toReturn: [SegmentCategory] = []
        for s in source {
            if !toReturn.contains(where: { $0.id == s.id }) {
                toReturn.append(s)
            } else if let found = toReturn.first(where: { $0.id == s.id }) {
                switch s {
                case let .content(data):
                    if case let .content(storeData) = found, let index = toReturn.firstIndex(where: { $0.id == s.id }) {
                        toReturn[index] = .content(data: Array(Set(data + storeData)))
                    }
                case let .discovery(data):
                    if case let .discovery(storeData) = found, let index = toReturn.firstIndex(where: { $0.id == s.id }) {
                        toReturn[index] = .discovery(data: Array(Set(data + storeData)))
                    }
                case let .merchandise(data):
                    if case let .merchandise(storeData) = found, let index = toReturn.firstIndex(where: { $0.id == s.id }) {
                        toReturn[index] = .merchandise(data: Array(Set(data + storeData)))
                    }
                case .other: continue
                }
            }
        }
        return toReturn
    }

    private func getSegments(customerIds: [String: String], newbies: [SegmentCallbackData]) {
        guard let cookie = customerIds["cookie"] else { return }
        dataProvider.getSegmentations(data: SegmentDataDTO.self, cookie: cookie) { [weak self] response in
            guard let self,
                  let result = response.data,
                  self.areCustomerIdsEqual else {
                if let error = response.error {
                    Exponea.logger.log(.verbose, message: "Segments: Fetch of segments failed: \(error)")
                } else {
                    Exponea.logger.log(.verbose, message: "Segments: New data are ignored because were loaded for different customer")
                }
                return
            }
            let storeSegments = self.storedSegmentations?.segmentData.categories ?? []
            let syncStatus = synchronizeSegments(customerIds: customerIds, input: result)
            let union = unionSegments(first: result.categories, second: storeSegments)
            guard !union.isEmpty else {
                Exponea.logger.log(.verbose, message: "Segments: Empty data from server and store.")
                self.newbieCallbacks.forEach { callback in
                    callback.fireBlock(category: [])
                }
                return
            }
            union.forEach { category in
                guard !self.callbacks.isEmpty else {
                    Exponea.logger.log(.verbose, message: "Segments: Skipping segments reload process for no callback")
                    return
                }
                for callback in self.callbacks where callback.category.id == category.id {
                    switch category {
                    case let .discovery(data),
                        let .content(data),
                        let .merchandise(data):
                        if newbies.contains(where: { $0.id == callback.id }) {
                            callback.fireBlock(category: data)
                        } else if syncStatus.contains(where: { $0.id == category.id }) {
                            callback.fireBlock(category: data)
                        } else {
                            callback.fireBlock(category: [])
                        }
                    case .other: break
                    }
                }
            }
        }
    }

    public func synchronizeSegments(customerIds: [String: String], input: SegmentDataDTO) -> [SegmentCategory] {
        guard let store = storedSegmentations, customerIds.compareWith(other: store.customerIds) else {
            storedSegmentations = .init(customerIds: customerIds, segmentData: input)
            return input.categories
        }
        let synchronizedCategories = input.categories.compactMap { category in
            switch category {
            case let .discovery(fetchData):
                if case let .discovery(storeData) = store.segmentData.categories.first(where: { $0 == .discovery() }) {
                    if !fetchData.diff(from: storeData).isEmpty {
                        return SegmentCategory(type: "discovery", data: fetchData)
                    }
                }
                return nil
            case let .merchandise(fetchData):
                if case let .merchandise(storeData) = store.segmentData.categories.first(where: { $0 == .merchandise() }) {
                    if !fetchData.diff(from: storeData).isEmpty {
                        return SegmentCategory(type: "merchandise", data: fetchData)
                    }
                }
                return nil
            case let .content(fetchData):
                if case let .content(storeData) = store.segmentData.categories.first(where: { $0 == .content() }) {
                    if !fetchData.diff(from: storeData).isEmpty {
                        return SegmentCategory(type: "content", data: fetchData)
                    }
                }
                return nil
            case .other:
                return nil
            }
        }
        storedSegmentations = .init(customerIds: customerIds, segmentData: input)
        return synchronizedCategories
    }

    private func linkIds(completion: @escaping EmptyBlock) {
        
        guard let cookie = Exponea.shared.customerCookie, let ids = Exponea.shared.trackingManager?.customerIds else { return }
        dataProvider.linkIds(data: EmptyDTO.self, cookie: cookie, externalIds: externalIds) { response in
            if response.error != nil {
                Exponea.logger.log(.warning, message: "Segments: Customer IDs \(ids) merge failed, unable to fetch segments due to \(String(describing: response.error?.localizedDescription))")
            }
            completion()
        }
    }

    public func addCallback(callbackData: SegmentCallbackData) {
        _callbacks.changeValue(with: { $0.append(callbackData) })
        processTriggeredBy(type: .register(data: callbackData))
    }

    public func removeCallback(callbackData: SegmentCallbackData) {
        _callbacks.changeValue(with: { $0.removeAll(where: { $0.id == callbackData.id }) })
        _newbieCallbacks.changeValue(with: { $0.removeAll(where: { $0.id == callbackData.id }) })
    }

    public func getNewbies() -> [SegmentCallbackData] {
        newbieCallbacks
    }

    public func getCallbacks() -> [SegmentCallbackData] {
        callbacks
    }
}

extension Array where Element: Hashable {
    func diff(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
