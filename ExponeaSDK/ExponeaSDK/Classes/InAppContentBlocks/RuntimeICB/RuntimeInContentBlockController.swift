//
//  RuntimeInContentBlockController.swift
//  ExponeaSDK
//
//  Created by Bloomreach on 18/08/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

protocol RuntimeInContentBlockManagerType {
    func availabilityForPlaceholder(id: String) -> InAppContentBlockAvailability
    func invalidatePlaceholders(_ ids: [String])
    func prefetchRuntimePlaceholdersWithIds(
        ids: [String],
        completion: @escaping (RuntimeInContentBlockPrefetchOutcome) -> Void
    )
}

enum RuntimeInContentBlockPrefetchOutcome: Equatable {
    case completed
    case retryableFailure
}

/// Describes the public interface of the runtime in-app content block controller.
public protocol RuntimeInContentBlockControllerType: AnyObject {
    func prefetch(ids: [String], deadline: TimeInterval?) async -> [String: InAppContentBlockAvailability]
    func prefetch(
        ids: [String],
        deadline: TimeInterval?,
        completion: @escaping ([String: InAppContentBlockAvailability]) -> Void
    )
    func invalidate(ids: [String], reason: String, mode: InAppContentBlockInvalidateMode)
    func availability(id: String, deadline: TimeInterval) async -> InAppContentBlockAvailabilityDecision
    func availability(
        id: String,
        deadline: TimeInterval,
        completion: @escaping (InAppContentBlockAvailabilityDecision) -> Void
    )
}

public extension RuntimeInContentBlockControllerType {
    func prefetch(ids: [String]) async -> [String: InAppContentBlockAvailability] {
        await prefetch(ids: ids, deadline: nil)
    }

    func prefetch(ids: [String], completion: @escaping ([String: InAppContentBlockAvailability]) -> Void) {
        prefetch(ids: ids, deadline: nil, completion: completion)
    }

    func invalidate(ids: [String], reason: String) {
        invalidate(ids: ids, reason: reason, mode: .eager)
    }
}

/// Coordinates runtime prefetch, invalidation, and bounded availability for in-app content blocks.
///
/// The controller is available from `Exponea.shared` only while the SDK is configured.
public final class RuntimeInContentBlockController: RuntimeInContentBlockControllerType {
    private let dispatchQueue: DispatchQueue
    private let dispatchQueueKey = DispatchSpecificKey<Void>()
    private var state: [String: InAppContentBlockAvailability] = [:]
    private var inFlight: Set<String> = []
    private var lifecycleGeneration: UInt = 0
    private var invalidationGenerations: [String: UInt] = [:]
    /// IDs whose current in-flight fetch was already started in direct response to an invalidation.
    /// Rapid follow-on invalidations for these IDs do not bump the generation counter because the
    /// in-flight fetch is already fetching post-invalidation content.
    private var inFlightDueToInvalidation: Set<String> = []
    /// Records the invalidation mode that last bumped each ID's generation counter. Used in the
    /// stale-fetch detection path to honour `.lazy` semantics (drop state only, no proactive refetch).
    private var invalidationModes: [String: InAppContentBlockInvalidateMode] = [:]
    private let manager: RuntimeInContentBlockManagerType

    var knownIds: [String] {
        syncOnDispatchQueue { Array(state.keys) }
    }

    init(manager: RuntimeInContentBlockManagerType) {
        self.manager = manager
        self.dispatchQueue = DispatchQueue(label: "com.exponea.runtime-icb-controller")
        self.dispatchQueue.setSpecific(key: dispatchQueueKey, value: ())
    }

    /// Prefetches content for the supplied placeholder IDs.
    ///
    /// Call this before mounting the corresponding placeholder views. A returned `.empty` value
    /// remains cached until explicit invalidation or an SDK lifecycle reset.
    ///
    /// - Parameters:
    ///   - ids: Placeholder IDs to warm.
    ///   - deadline: Maximum seconds to wait for the fetch. IDs still in-flight at the deadline
    ///     are returned as `.loading`; their background fetch continues and updates the cache.
    /// - Returns: Availability for every requested ID.
    public func prefetch(ids: [String], deadline: TimeInterval? = nil) async -> [String: InAppContentBlockAvailability] {
        guard !ids.isEmpty else { return [:] }
        return await withCheckedContinuation { continuation in
            prefetch(ids: ids, deadline: deadline) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// Prefetches content for the supplied placeholder IDs.
    ///
    /// The completion can run on an arbitrary queue. Callers performing UI work must dispatch to
    /// the main queue.
    ///
    /// - Parameters:
    ///   - ids: Placeholder IDs to warm before mounting their views.
    ///   - deadline: Maximum seconds to wait for the fetch. IDs still in-flight at the deadline
    ///     are returned as `.loading`; their background fetch continues and updates the cache.
    ///   - completion: Availability for every requested ID.
    public func prefetch(
        ids: [String],
        deadline: TimeInterval? = nil,
        completion: @escaping ([String: InAppContentBlockAvailability]) -> Void
    ) {
        guard !ids.isEmpty else {
            completion([:])
            return
        }
        Exponea.logger.log(.verbose, message: "Runtime ICB prefetch ids=\(ids) deadline=\(deadline as Any)")
        guard let deadline else {
            performPrefetch(ids: ids, completion: completion)
            return
        }
        var delivered = false
        let lock = NSLock()
        func deliver(_ result: [String: InAppContentBlockAvailability]) {
            lock.lock()
            defer { lock.unlock() }
            guard !delivered else { return }
            delivered = true
            completion(result)
        }
        let deadlineItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            dispatchQueue.async {
                let snapshot = ids.reduce(into: [String: InAppContentBlockAvailability]()) { acc, id in
                    acc[id] = self.state[id] ?? .loading
                }
                deliver(snapshot)
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + deadline, execute: deadlineItem)
        performPrefetch(ids: ids) { result in
            deadlineItem.cancel()
            deliver(result)
        }
    }

    /// Clears cached content for specific placeholders.
    ///
    /// The reason is written to local verbose logs only. Eager mode starts a background refetch;
    /// lazy mode waits for the next access.
    ///
    /// - Parameters:
    ///   - ids: Placeholder IDs whose cached content should be cleared.
    ///   - reason: A local diagnostic label that is never persisted or sent over the network.
    ///   - mode: Whether to refetch immediately.
    public func invalidate(
        ids: [String],
        reason: String,
        mode: InAppContentBlockInvalidateMode = .eager
    ) {
        guard !ids.isEmpty else { return }

        dispatchQueue.async {
            self.logInvalidate(reason: reason, ids: ids, mode: mode)
            self.manager.invalidatePlaceholders(ids)
            self.applyInvalidateStateChanges(for: ids, mode: mode)
            self.refetchAfterInvalidateIfNeeded(ids: ids, mode: mode)
        }
    }

    /// Waits until a placeholder becomes ready or empty, up to the supplied deadline.
    ///
    /// The async continuation resumes on the main queue. A completed decision never contains
    /// `.resolved(.loading)`.
    ///
    /// - Parameters:
    ///   - id: Placeholder ID to query.
    ///   - deadline: Maximum number of seconds to wait.
    /// - Returns: A terminal availability decision or `.timedOut`.
    public func availability(
        id: String,
        deadline: TimeInterval
    ) async -> InAppContentBlockAvailabilityDecision {
        await withCheckedContinuation { continuation in
            availability(id: id, deadline: deadline) { decision in
                continuation.resume(returning: decision)
            }
        }
    }

    /// Waits until a placeholder becomes ready or empty, up to the supplied deadline.
    ///
    /// The completion is always delivered on the main queue. The deadline is measured from the
    /// moment this method is called, not from when the internal dispatch queue processes the
    /// request. This means the deadline is honored even if the queue is temporarily busy.
    ///
    /// - Parameters:
    ///   - id: Placeholder ID to query.
    ///   - deadline: Maximum number of seconds to wait.
    ///   - completion: A terminal availability decision or `.timedOut`.
    public func availability(
        id: String,
        deadline: TimeInterval,
        completion: @escaping (InAppContentBlockAvailabilityDecision) -> Void
    ) {
        Exponea.logger.log(.verbose, message: "Runtime ICB availability id=\(id) deadline=\(deadline)")
        let absoluteDeadline = DispatchTime.now() + deadline
        let deadlineDate = Date(timeIntervalSinceNow: deadline)
        dispatchQueue.async {
            if let existing = self.state[id], existing == .ready || existing == .empty {
                DispatchQueue.main.async { completion(.resolved(existing)) }
                return
            }

            guard Date() < deadlineDate else {
                DispatchQueue.main.async { completion(.timedOut) }
                return
            }

            let waiterID = UUID()
            let workItem = DispatchWorkItem {
                self.dispatchQueue.async {
                    self.resolveSpecificWaiter(placeholderID: id, waiterID: waiterID, decision: .timedOut)
                }
            }
            self.availabilityWaiters[id, default: []].append(
                AvailabilityWaiter(id: waiterID, workItem: workItem, completion: completion)
            )
            DispatchQueue.global().asyncAfter(deadline: absoluteDeadline, execute: workItem)

            if self.state[id] == nil {
                self.performPrefetchOnQueue(ids: [id])
            }
        }
    }
    
    func clearCachedAvailability() {
        dispatchQueue.async {
            self.state.removeAll()
        }
    }

    func prepareForAnonymize() {
        prepareForCustomerChange()
    }

    func prepareForCustomerChange() {
        syncOnDispatchQueue { resetOnQueue() }
    }

    private func syncOnDispatchQueue<T>(_ action: () -> T) -> T {
        if DispatchQueue.getSpecific(key: dispatchQueueKey) != nil {
            return action()
        }
        return dispatchQueue.sync(execute: action)
    }

    func stopIntegration() {
        dispatchQueue.async { self.resetOnQueue() }
    }

    /// Must be called from within `dispatchQueue`.
    private func resetOnQueue() {
        let knownIds = Array(state.keys)
        let pending = availabilityWaiters
        let pendingPrefetch = prefetchWaiters
        availabilityWaiters.removeAll()
        prefetchWaiters.removeAll()
        lifecycleGeneration &+= 1
        state.removeAll()
        inFlight.removeAll()
        invalidationGenerations.removeAll()
        inFlightDueToInvalidation.removeAll()
        invalidationModes.removeAll()
        if !knownIds.isEmpty {
            manager.invalidatePlaceholders(knownIds)
        }
        for (_, waiters) in pending {
            for waiter in waiters {
                waiter.workItem.cancel()
                DispatchQueue.main.async { waiter.completion(.timedOut) }
            }
        }
        for (_, waiters) in pendingPrefetch {
            waiters.forEach { $0(.loading) }
        }
    }

    private func performPrefetch(
        ids: [String],
        completion: (([String: InAppContentBlockAvailability]) -> Void)? = nil
    ) {
        dispatchQueue.async {
            self.performPrefetchOnQueue(ids: ids, completion: completion)
        }
    }

    private func performPrefetchOnQueue(
        ids: [String],
        dueToInvalidation: Bool = false,
        completion: (([String: InAppContentBlockAvailability]) -> Void)? = nil
    ) {
        var results: [String: InAppContentBlockAvailability] = [:]
        var needsFetching: [String] = []
        var outstandingCount = 0
        var completionFired = false

        func deliver() {
            guard !completionFired && outstandingCount == 0 else { return }
            completionFired = true
            completion?(results)
        }

        for id in ids {
            if let existing = state[id], existing == .ready || existing == .empty {
                results[id] = existing
                continue
            }
            if inFlight.contains(id) {
                outstandingCount += 1
                prefetchWaiters[id, default: []].append { availability in
                    results[id] = availability
                    outstandingCount -= 1
                    deliver()
                }
                continue
            }
            if manager.availabilityForPlaceholder(id: id) == .ready {
                state[id] = .ready
                results[id] = .ready
                resolveWaiterIfReady(id: id)
                continue
            }
            state[id] = .loading
            inFlight.insert(id)
            if dueToInvalidation {
                inFlightDueToInvalidation.insert(id)
            }
            needsFetching.append(id)
        }

        guard !needsFetching.isEmpty else {
            deliver()
            return
        }

        outstandingCount += 1

        let generation = lifecycleGeneration
        let capturedGenerations = Dictionary(
            uniqueKeysWithValues: needsFetching.map { ($0, invalidationGenerations[$0, default: 0]) }
        )
        // Dispatch off dispatchQueue so that any synchronous work inside the manager
        // (e.g. @Atomic lock acquisition, catalog reads) does not stall dispatchQueue
        // and delay unrelated availability deadline timers.
        DispatchQueue.global().async {
            self.manager.prefetchRuntimePlaceholdersWithIds(ids: needsFetching) { outcome in
                self.dispatchQueue.async {
                    guard generation == self.lifecycleGeneration else {
                        for id in needsFetching {
                            self.inFlightDueToInvalidation.remove(id)
                            results[id] = self.state[id] ?? .loading
                        }
                        outstandingCount -= 1
                        deliver()
                        for id in needsFetching {
                            if let waiters = self.prefetchWaiters.removeValue(forKey: id) {
                                waiters.forEach { $0(self.state[id] ?? .loading) }
                            }
                        }
                        return
                    }

                    if outcome == .retryableFailure {
                        for id in needsFetching {
                            self.inFlight.remove(id)
                            self.inFlightDueToInvalidation.remove(id)
                            self.state.removeValue(forKey: id)
                            results[id] = .loading
                        }
                        outstandingCount -= 1
                        deliver()
                        for id in needsFetching {
                            if let waiters = self.prefetchWaiters.removeValue(forKey: id) {
                                waiters.forEach { $0(.loading) }
                            }
                            self.resolveWaiter(id: id, decision: .timedOut)
                        }
                        return
                    }

                    var staleFetchIds: [String] = []
                    for id in needsFetching {
                        self.inFlight.remove(id)
                        self.inFlightDueToInvalidation.remove(id)
                        guard self.invalidationGenerations[id, default: 0] == capturedGenerations[id, default: 0] else {
                            staleFetchIds.append(id)
                            results[id] = .loading
                            continue
                        }
                        // Non-stale: result is committed, mode tracking no longer needed.
                        self.invalidationModes.removeValue(forKey: id)
                        let availability = self.manager.availabilityForPlaceholder(id: id)
                        self.state[id] = availability
                        self.resolveWaiterIfReady(id: id)
                        results[id] = availability
                    }
                    outstandingCount -= 1
                    deliver()
                    for id in needsFetching where !staleFetchIds.contains(id) {
                        if let waiters = self.prefetchWaiters.removeValue(forKey: id) {
                            waiters.forEach { $0(self.state[id] ?? .loading) }
                        }
                    }
                    if !staleFetchIds.isEmpty {
                        // Partition stale IDs by the mode that caused their generation bump so that
                        // .lazy invalidations honour their "no proactive refetch" contract. Both
                        // groups need the manager cache cleared; only .eager IDs trigger a refetch.
                        let eagerStale = staleFetchIds.filter { self.invalidationModes[$0] != .lazy }
                        let lazyStale = staleFetchIds.filter { self.invalidationModes[$0] == .lazy }
                        for id in staleFetchIds { self.invalidationModes.removeValue(forKey: id) }
                        if !eagerStale.isEmpty {
                            self.manager.invalidatePlaceholders(eagerStale)
                            self.performPrefetchOnQueue(ids: eagerStale, dueToInvalidation: true)
                        }
                        if !lazyStale.isEmpty {
                            self.manager.invalidatePlaceholders(lazyStale)
                            // State was already removed in applyInvalidateStateChanges; the next
                            // caller-initiated access (prefetch / availability) will start the fetch.
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - helper methods
    
    private func applyInvalidateStateChanges(for ids: [String], mode: InAppContentBlockInvalidateMode) {
        for id in ids {
            if !inFlightDueToInvalidation.contains(id) {
                invalidationGenerations[id, default: 0] &+= 1
                invalidationModes[id] = mode
            }
            let isUnknown = state[id] == nil
            if isUnknown {
                state[id] = .loading
                continue
            }
            switch mode {
            case .eager:
                state[id] = .loading
            case .lazy:
                state.removeValue(forKey: id)
            }
        }
    }
    
    private func logInvalidate(reason: String, ids: [String], mode: InAppContentBlockInvalidateMode) {
        Exponea.logger.log(
            .verbose,
            message: "Runtime ICB invalidate mode=\(mode) ids=\(ids) reason=\(reason)"
        )
    }
    
    private func refetchAfterInvalidateIfNeeded(ids: [String], mode: InAppContentBlockInvalidateMode) {
        let idsNeedingFetch: [String]
        if mode == .eager {
            idsNeedingFetch = ids
        } else {
            idsNeedingFetch = ids.filter { state[$0] == .loading }
        }
        guard !idsNeedingFetch.isEmpty else { return }
        performPrefetchOnQueue(ids: idsNeedingFetch, dueToInvalidation: true)
    }
    
    private func resolveWaiter(id: String, decision: InAppContentBlockAvailabilityDecision) {
        guard let waiters = availabilityWaiters.removeValue(forKey: id) else { return }
        for waiter in waiters {
            waiter.workItem.cancel()
            DispatchQueue.main.async { waiter.completion(decision) }
        }
    }

    private func resolveSpecificWaiter(placeholderID: String, waiterID: UUID, decision: InAppContentBlockAvailabilityDecision) {
        guard let index = availabilityWaiters[placeholderID]?.firstIndex(where: { $0.id == waiterID }) else { return }
        let waiter = availabilityWaiters[placeholderID]!.remove(at: index)
        if availabilityWaiters[placeholderID]?.isEmpty == true {
            availabilityWaiters.removeValue(forKey: placeholderID)
        }
        waiter.workItem.cancel()
        DispatchQueue.main.async { waiter.completion(decision) }
    }
    
    private func resolveWaiterIfReady(id: String) {
        if let singularState = state[id], singularState != .loading {
            resolveWaiter(id: id, decision: .resolved(singularState))
        }
    }
    
    private struct AvailabilityWaiter {
        let id: UUID
        let workItem: DispatchWorkItem
        let completion: (InAppContentBlockAvailabilityDecision) -> Void
    }
    
    private var availabilityWaiters: [String: [AvailabilityWaiter]] = [:]
    private var prefetchWaiters: [String: [(InAppContentBlockAvailability) -> Void]] = [:]
}
