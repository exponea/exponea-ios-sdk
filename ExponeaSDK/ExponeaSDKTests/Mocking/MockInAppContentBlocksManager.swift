//
//  MockInAppContentBlocksManager.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import UIKit
import WebKit
@testable import ExponeaSDK

final class MockInAppContentBlocksManager:
    InAppContentBlocksManagerType,
    RuntimeInContentBlockManagerType {
    var contentRuleList: WKContentRuleList?
    var refreshCallback: TypeBlock<IndexPath>?

    private(set) var prefetchCallCount = 0
    private(set) var prefetchedIds: [String] = []
    private(set) var invalidatedPlaceholderIds: [[String]] = []
    private(set) var catalogLoadCallCount = 0
    private(set) var anonymizeCallCount = 0
    private let availabilityLock = NSLock()
    private var _availabilityByPlaceholder: [String: InAppContentBlockAvailability] = [:]
    var availabilityByPlaceholder: [String: InAppContentBlockAvailability] {
        get { availabilityLock.withLock { _availabilityByPlaceholder } }
        set { availabilityLock.withLock { _availabilityByPlaceholder = newValue } }
    }
    var prefetchAvailabilityAfterFetch: InAppContentBlockAvailability = .empty
    var prefetchDelay: TimeInterval = 0
    var simulateNetworkError: Bool = false
    var simulateRetryableFailure: Bool = false
    /// When set, the call whose 1-based sequence number matches returns retryableFailure immediately,
    /// bypassing `prefetchDelay` for deterministic test ordering. Prefer `retryableFailureForIds`
    /// when the mock is called concurrently, as call ordering is non-deterministic in that case.
    var retryableFailureOnCallNumber: Int? = nil
    /// When non-empty, any call whose `ids` batch intersects this set returns retryableFailure
    /// immediately. ID-based targeting is deterministic regardless of concurrent call ordering.
    var retryableFailureForIds: Set<String> = []
    var loadsCatalogOnFirstUse = false
    var catalogLoadSucceeds = true
    private var isCatalogReady = false

    func availabilityForPlaceholder(id: String) -> InAppContentBlockAvailability {
        availabilityByPlaceholder[id] ?? .empty
    }

    func invalidatePlaceholders(_ placeholderIds: [String]) {
        availabilityLock.withLock {
            invalidatedPlaceholderIds.append(placeholderIds)
            for id in placeholderIds {
                _availabilityByPlaceholder.removeValue(forKey: id)
            }
        }
    }

    func prepareInAppContentBlockView(placeholderId: String, indexPath: IndexPath) -> UIView {
        UIView()
    }

    func prefetchPlaceholdersWithIds(ids: [String]) {
        prefetchPlaceholdersWithIds(ids: ids, completion: nil)
    }

    func prefetchPlaceholdersWithIds(ids: [String], completion: (() -> Void)?) {
        prefetchRuntimePlaceholdersWithIds(ids: ids) { _ in completion?() }
    }

    func prefetchRuntimePlaceholdersWithIds(
        ids: [String],
        completion: @escaping (RuntimeInContentBlockPrefetchOutcome) -> Void
    ) {
        let shouldLoadCatalog = availabilityLock.withLock { loadsCatalogOnFirstUse && !isCatalogReady }

        if shouldLoadCatalog {
            loadInAppContentBlockMessages(completion: nil)
            let succeeds = availabilityLock.withLock { catalogLoadSucceeds }
            guard succeeds else {
                completion(.retryableFailure)
                return
            }
        }

        availabilityLock.withLock {
            prefetchCallCount += 1
            prefetchedIds.append(contentsOf: ids)
        }
        let delay = availabilityLock.withLock { prefetchDelay }
        let shouldError = availabilityLock.withLock { simulateNetworkError }
        let shouldRetryableFailure = availabilityLock.withLock {
            simulateRetryableFailure
                || retryableFailureOnCallNumber == prefetchCallCount
                || !retryableFailureForIds.isDisjoint(with: ids)
        }
        let availability = availabilityLock.withLock { prefetchAvailabilityAfterFetch }

        if shouldRetryableFailure {
            completion(.retryableFailure)
            return
        }
        if delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                if let self, !shouldError {
                    self.availabilityLock.withLock {
                        for id in ids {
                            self._availabilityByPlaceholder[id] = availability
                        }
                    }
                }
                completion(.completed)
            }
        } else {
            if !shouldError {
                availabilityLock.withLock {
                    for id in ids {
                        _availabilityByPlaceholder[id] = availability
                    }
                }
            }
            completion(.completed)
        }
    }

    func getUsedInAppContentBlocks(placeholder: String, indexPath: IndexPath) -> UsedInAppContentBlocks? {
        nil
    }

    func anonymize() {
        availabilityLock.withLock {
            anonymizeCallCount += 1
            isCatalogReady = false
            _availabilityByPlaceholder.removeAll()
        }
    }

    func initBlocker() {}

    func loadInAppContentBlockMessages(completion: EmptyBlock?) {
        availabilityLock.withLock {
            catalogLoadCallCount += 1
            isCatalogReady = catalogLoadSucceeds
        }
        completion?()
    }

    func updateInteractedState(for messageId: String) {}

    func updateDisplayedState(for messageId: String) {}

    func getDisplayState(of messageId: String) -> InAppContentBlocksDisplayStatus {
        InAppContentBlocksDisplayStatus(displayed: nil, interacted: nil)
    }

    func hasHtmlImages(html: String) -> Bool {
        true
    }

    func getFilteredMessage(message: InAppContentBlockResponse) -> Bool {
        true
    }

    func prefetchPlaceholdersWithIds(
        input: [InAppContentBlockResponse],
        ids: [String]
    ) -> [InAppContentBlockResponse] {
        input.filter { message in
            message.placeholders.contains(where: { ids.contains($0) })
        }
    }

    func filterPriority(input: [InAppContentBlockResponse]) -> [Int: [InAppContentBlockResponse]] {
        [:]
    }

    func refreshStaticViewContent(staticQueueData: StaticQueueData) {}

    func isMessageValid(
        message: InAppContentBlockResponse,
        isValidCompletion: TypeBlock<Bool>?,
        refreshCallback: EmptyBlock?
    ) {
        isValidCompletion?(true)
    }

    func applyDateFilter(message: InAppContentBlockResponse) -> Bool {
        true
    }

    func filterCarouselData(
        placeholder: String,
        continueCallback: TypeBlock<[InAppContentBlockResponse]>?,
        expiredCompletion: EmptyBlock?
    ) {}

    func addMessage(_ message: InAppContentBlockResponse) {}

    func resetPrefetchCalls() {
        availabilityLock.withLock {
            prefetchCallCount = 0
            prefetchedIds = []
            invalidatedPlaceholderIds = []
            catalogLoadCallCount = 0
            anonymizeCallCount = 0
            prefetchDelay = 0
            simulateNetworkError = false
            simulateRetryableFailure = false
            retryableFailureOnCallNumber = nil
            retryableFailureForIds = []
            catalogLoadSucceeds = true
            isCatalogReady = false
        }
    }
}
