//
//  ManualSegmentationManager.swift
//  ExponeaSDK
//
//  Created by Ankmara on 25.09.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

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

    @Atomic private var manualCallbacks: [SegmentCallbackData] = []
    private var isRequestRunning = false
    private func areCustomerIdsEqual(customerIds: [String: String]) -> Bool {
        guard let currentCustomerIds = Exponea.shared.trackingManager?.customerIds else { return false }
        let areSame = currentCustomerIds.compareWith(other: customerIds)
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
    private func customerIdsNeedsSync(currentCustomer: [String: String]) -> Bool {
        areCustomerIdsEqual(customerIds: currentCustomer) && !externalIds.isEmpty
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

    private func fetchSegments(
        category: SegmentCategory,
        result: @escaping TypeBlock<[SegmentDTO]>,
        cookie: String,
        customerIds: [String: String]
    ) {
        dataProvider.getSegmentations(
            data: SegmentDataDTO.self,
            cookie: cookie
        ) { [weak self] response in
            guard let self, let data = response.data else {
                if let error = response.error {
                    Exponea.logger.log(.error, message: "Segments: Fetch of segments failed: \(error)")
                }
                self?.manualCallbacks.forEach { $0.fireBlock(category: []) }
                return
            }
            guard self.areCustomerIdsEqual(customerIds: customerIds) else {
                invokeFetch(
                    customerIds: customerIds,
                    category: category,
                    result: result,
                    cookie: cookie
                )
                return
            }
            cache = .init(
                timestamp: Date().timeIntervalSince1970,
                data: data,
                assignedCustomer: customerIds
            )
            self.isRequestRunning = false
            cache?.data.categories.forEach { [weak self] category in
                guard let self else { return }
                guard !self.manualCallbacks.isEmpty else {
                    Exponea.logger.log(.verbose, message: "Segments: Skipping segments reload process for no callback")
                    return
                }
                for callback in self.manualCallbacks where callback.category.id == category.id {
                    switch category {
                    case let .discovery(data),
                        let .content(data),
                        let .merchandise(data):
                        callback.fireBlock(category: data)
                        if let index = self.manualCallbacks.firstIndex(where: { $0.category.id == category.id }) {
                            self._manualCallbacks.changeValue(with: { $0.remove(at: index) })
                        }
                    case .other: break
                    }
                }
            }
        }
    }

    public func getSegments(
        category: SegmentCategory,
        force: Bool = false,
        result: @escaping TypeBlock<[SegmentDTO]>
    ) {
        guard force ||
                cache?.assignedCustomer == nil ||
                cache?.isWithinTime == false
        else {
            cache?.data.categories.forEach { category in
                switch category {
                case let .discovery(data),
                    let .content(data),
                    let .merchandise(data):
                    result(data)
                case .other: break
                }
            }
            return
        }
        if let cachedCustomerIds = cache?.assignedCustomer, !areCustomerIdsEqual(customerIds: cachedCustomerIds) {
            result([])
            return
        }
        let manual: SegmentCallbackData = .init(
            category: category,
            isIncludeFirstLoad: true,
            onNewData: result
        )
        guard !isRequestRunning else {
            Exponea.logger.log(.verbose, message: "Segments: Manual fetch is already in progress, waiting for result")
            return
        }
        guard let customerIds = cache?.assignedCustomer,
              let cookie = customerIds["cookie"] else {
            Exponea.logger.log(.verbose, message: "Segments: Customer in not identified")
            result([])
            return
        }
        _manualCallbacks.changeValue(with: { $0.append(manual) })
        invokeFetch(
            customerIds: customerIds,
            category: category,
            result: result,
            cookie: cookie
        )
    }

    private func invokeFetch(
        customerIds: [String: String],
        category: SegmentCategory,
        result: @escaping TypeBlock<[SegmentDTO]>,
        cookie: String
    ) {
        guard areCustomerIdsEqual(customerIds: customerIds) else {
            invokeFetch(
                customerIds: Exponea.shared.trackingManager?.customerIds ?? [:],
                category: category,
                result: result,
                cookie: cookie
            )
            return
        }
        isRequestRunning = true
        if customerIdsNeedsSync(currentCustomer: customerIds) {
            linkIds { [weak self] in
                self?.fetchSegments(
                    category: category,
                    result: result,
                    cookie: cookie,
                    customerIds: customerIds
                )
            }
        } else {
            fetchSegments(
                category: category,
                result: result,
                cookie: cookie,
                customerIds: customerIds
            )
        }
    }

    public func anonymize() {
        cache = nil
        manualCallbacks.forEach { $0.fireBlock(category: []) }
        manualCallbacks.removeAll()
        Exponea.logger.log(.verbose, message: "Segments: Segments change check has anonymized")
    }
}
