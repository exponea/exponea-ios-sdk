//
//  ManualSegmentationManager.swift
//  ExponeaSDK
//
//  Created by Ankmara on 25.09.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

public struct ManualSegmentsCacheDTO {
    public let timestamp: Double
    public let data: SegmentDataDTO
    public let assignedCustomer: [String: String]
    public var isWithinTime: Bool {
        timestamp + Self.cacheLife > Date().timeIntervalSince1970
    }
    private static let cacheLife: Double = 5
}

public protocol ManualSegmentationManagerType {
    var cache: ManualSegmentsCacheDTO? { get set }
    var dataProvider: SegmentationDataProvider { get set }

    func anonymize()
    func getSegments(
        category: SegmentCategory,
        force: Bool,
        result: @escaping TypeBlock<[SegmentDTO]>
    )
}

public final class ManualSegmentationManager: ManualSegmentationManagerType {
    public var cache: ManualSegmentsCacheDTO?
    public lazy var dataProvider: SegmentationDataProvider = .init()

    // MARK: - Init
    public static let shared = ManualSegmentationManager()

    // Mirrors the Android SDK (SegmentsManagerImpl.fetchSegmentsManually): every caller waits in
    // `manualCallbacks` and one fetch runs at a time. However the fetch ends, all waiting callers
    // are answered exactly once with the segments of their category, or an empty list.
    @Atomic private var manualCallbacks: [SegmentCallbackData] = []
    @Atomic private var isRequestRunning = false

    // Customer IDs of the tracked customer; replaced in tests.
    var customerIdsProvider: () -> [String: String] = {
        Exponea.shared.trackingManager?.customerIds ?? [:]
    }

    private var currentCustomerIds: [String: String] {
        customerIdsProvider()
    }

    private var isStopped: Bool {
        IntegrationManager.shared.isStopped
    }

    private func areCustomerIdsActual(_ customerIds: [String: String]) -> Bool {
        currentCustomerIds.compareWith(other: customerIds)
    }

    private func isCacheAssigned(to customerIds: [String: String]) -> Bool {
        guard let assignedCustomer = cache?.assignedCustomer else { return false }
        return assignedCustomer.compareWith(other: customerIds)
    }

    private func externalIds(of customerIds: [String: String]) -> [String: String] {
        var ids = customerIds
        ids["cookie"] = nil
        return ids
    }

    /// Customer IDs are linked once per customer, before the first fetch for it.
    private func customerIdsMergeIsRequired(_ customerIds: [String: String]) -> Bool {
        !isCacheAssigned(to: customerIds) && !externalIds(of: customerIds).isEmpty
    }

    public func getSegments(
        category: SegmentCategory,
        force: Bool = false,
        result: @escaping TypeBlock<[SegmentDTO]>
    ) {
        guard !isStopped else {
            Exponea.logger.log(.verbose, message: "Segments: Segments fetch failed, SDK is stopping")
            result([])
            return
        }
        let customerIdsForFetch = currentCustomerIds
        let requireFetch = force || !isCacheAssigned(to: customerIdsForFetch) || cache?.isWithinTime != true
        guard requireFetch else {
            result(Self.segments(of: category, in: cache?.data))
            return
        }
        let manual: SegmentCallbackData = .init(
            category: category,
            isIncludeFirstLoad: true
        ) { segments in
            if IntegrationManager.shared.isStopped {
                Exponea.logger.log(.verbose, message: "Segments: Segments fetch failed, SDK is stopping")
                result([])
                return
            }
            result(segments)
        }
        _manualCallbacks.changeValue(with: { $0.append(manual) })
        var shouldStart = false
        _isRequestRunning.changeValue(with: { running in
            shouldStart = !running
            running = true
        })
        guard shouldStart else {
            Exponea.logger.log(.verbose, message: "Segments: Manual fetch is already in progress, waiting for result")
            return
        }
        runManualSegmentsFetch(customerIds: customerIdsForFetch)
    }

    private func runManualSegmentsFetch(customerIds: [String: String]) {
        guard areCustomerIdsActual(customerIds) else {
            Exponea.logger.log(.warning, message: "Segments: Repeating manual fetch because customer has changed")
            runManualSegmentsFetch(customerIds: currentCustomerIds)
            return
        }
        guard !isStopped else {
            Exponea.logger.log(.verbose, message: "Segments: Segments fetch failed, SDK is stopping")
            finishManualFetch(with: nil)
            return
        }
        guard let cookie = customerIds["cookie"] else {
            Exponea.logger.log(.warning, message: "Segments: Fetch of segments for no cookie ID is forbidden")
            finishManualFetch(with: nil)
            return
        }
        guard customerIdsMergeIsRequired(customerIds) else {
            fetchSegments(customerIds: customerIds, cookie: cookie)
            return
        }
        Exponea.logger.log(.verbose, message: "Segments: Current customer IDs require to be linked")
        dataProvider.linkIds(
            data: EmptyDTO.self,
            cookie: cookie,
            externalIds: externalIds(of: customerIds)
        ) { [weak self] response in
            guard let self else { return }
            if let error = response.error {
                Exponea.logger.log(
                    .error,
                    message: "Segments: Customer IDs \(customerIds.keys.sorted()) merge failed, unable to fetch segments: \(error)"
                )
                self.finishManualFetch(with: nil)
                return
            }
            guard !self.isStopped else {
                Exponea.logger.log(.verbose, message: "Segments: Segments fetch failed, SDK is stopping")
                self.finishManualFetch(with: nil)
                return
            }
            self.fetchSegments(customerIds: customerIds, cookie: cookie)
        }
    }

    private func fetchSegments(customerIds: [String: String], cookie: String) {
        dataProvider.getSegmentations(data: SegmentDataDTO.self, cookie: cookie) { [weak self] response in
            guard let self else { return }
            guard !self.isStopped else {
                Exponea.logger.log(.verbose, message: "Segments: Segments fetch failed, SDK is stopping")
                self.finishManualFetch(with: nil)
                return
            }
            guard let data = response.data else {
                Exponea.logger.log(
                    .error,
                    message: "Segments: Fetch of segments failed: \(String(describing: response.error))"
                )
                self.finishManualFetch(with: nil)
                return
            }
            Exponea.logger.log(
                .verbose,
                message: "Segments: Manual Data load is done successfully, size: \(data.categories.count)"
            )
            guard self.areCustomerIdsActual(customerIds) else {
                Exponea.logger.log(
                    .warning,
                    message: "Segments: New data are ignored because were manually loaded for different customer"
                )
                self.runManualSegmentsFetch(customerIds: self.currentCustomerIds)
                return
            }
            self.cache = .init(
                timestamp: Date().timeIntervalSince1970,
                data: data,
                assignedCustomer: customerIds
            )
            self.finishManualFetch(with: data)
        }
    }

    private func finishManualFetch(with data: SegmentDataDTO?) {
        isRequestRunning = false
        notifyManualCallbacks(data: data)
    }

    /// Answers and releases every waiting caller with the segments of its category. The backend
    /// omits categories without segments (`{}` for a fresh customer), so a missing category, a
    /// failure or a reset all yield an empty list.
    private func notifyManualCallbacks(data: SegmentDataDTO?) {
        var pending: [SegmentCallbackData] = []
        _manualCallbacks.changeValue(with: {
            pending = $0
            $0.removeAll()
        })
        pending.forEach { callback in
            callback.fireBlock(category: Self.segments(of: callback.category, in: data))
        }
    }

    private static func segments(of category: SegmentCategory, in data: SegmentDataDTO?) -> [SegmentDTO] {
        guard let match = data?.categories.first(where: { $0.id == category.id }) else { return [] }
        switch match {
        case let .discovery(segments),
            let .content(segments),
            let .merchandising(segments):
            return segments
        case .other:
            return []
        }
    }

    public func anonymize() {
        cache = nil
        notifyManualCallbacks(data: nil)
        Exponea.logger.log(.verbose, message: "Segments: Segments change check has anonymized")
    }
}
