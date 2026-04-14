//
//  FlushingManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 13/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

class FlushingManager: FlushingManagerType {
    private let database: DatabaseManagerType
    private let repository: RepositoryType

    private let reachability: ExponeaReachability

    private let flushingSemaphore = DispatchSemaphore(value: 1)
    private var isFlushingData: Bool = false
    /// Used for periodic data flushing.
    private var flushingTimer: Timer?
    internal var inAppRefreshCallback: EmptyBlock?
    private var customerIdentifiedHandler: () -> Void
    
    public var flushingMode: FlushingMode = .immediate {
        didSet {
            Exponea.logger.log(.verbose, message: "Flushing mode updated to: \(flushingMode).")
            stopPeriodicFlushTimer()

            switch flushingMode {
            case .immediate:
                flushDataWith(delay: Constants.Tracking.immediateFlushDelay)
            case .periodic:
                startPeriodicFlushTimer()
            default:
                break
            }
        }
    }

    init(
        database: DatabaseManagerType,
        repository: RepositoryType,
        customerIdentifiedHandler: @escaping () -> Void
     ) throws {
        self.database = database
        self.repository = repository
        self.customerIdentifiedHandler = customerIdentifiedHandler

        // Start reachability
        guard let reachability = ExponeaReachability(hostname: repository.configuration.hostname) else {
            throw TrackingManagerError.cannotStartReachability
        }
        self.reachability = reachability
        try? self.reachability.startNotifier()
    }

    func applicationDidBecomeActive() {
        startPeriodicFlushTimer()
    }

    func applicationDidEnterBackground() {
        stopPeriodicFlushTimer()
    }

    private func startPeriodicFlushTimer() {
        if case let .periodic(interval) = flushingMode {
            stopPeriodicFlushTimer()
            flushingTimer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(interval),
                repeats: true
            ) { _ in self.flushData() }
        }
    }

    private func stopPeriodicFlushTimer() {
        self.flushingTimer?.invalidate()
        self.flushingTimer = nil
    }

    func flushDataWith(delay: Double, completion: ((FlushResult) -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let `self` = self else { return }
            self.flushData()
        }
    }

    /// Method that flushes all data to the API.
    ///
    /// - Parameter completion: A completion that is called after all calls succeed or fail.
    func flushData(isFromIdentify: Bool = false, completion: ((FlushResult) -> Void)?) {
        guard !IntegrationManager.shared.isStopped else {
            stopPeriodicFlushTimer()
            Exponea.logger.log(.error, message: "Flushing has been denied, SDK is stopping")
            completion?(.error(ExponeaError.stoppedProcess))
            return
        }
        do {
            // Check if flush is in progress
            flushingSemaphore.wait()
            guard !isFlushingData else {
                Exponea.logger.log(.warning, message: "Data flushing in progress, ignoring another flush call.")
                flushingSemaphore.signal()
                completion?(.flushAlreadyInProgress)
                return
            }
            isFlushingData = true
            flushingSemaphore.signal()

            // Check if we have an internet connection otherwise bail
            guard reachability.connection != .none else {
                Exponea.logger.log(.warning, message: "Connection issues when flushing data, not flushing.")
                isFlushingData = false
                completion?(.noInternetConnection)
                return
            }

            // Pull from db
            let events = try database.fetchTrackEvent()
            let customers = try database.fetchTrackCustomer()

            if isFromIdentify && customers.isEmpty {
                inAppRefreshCallback?()
            }
            // Check if we have any data otherwise bail
            guard !events.isEmpty || !customers.isEmpty else {
                isFlushingData = false
                completion?(.success(0))
                return
            }

            Exponea.logger.log(
                .verbose,
                message: """
                Flushing data: \(events.count + customers.count) total objects to upload, \
                \(events.count) events and \(customers.count) customer updates.
                """
            )
            flushTrackingObjects(customers + events) { result in
                self.isFlushingData = false
                completion?(result)
            }
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
            self.isFlushingData = false
            completion?(.error(error))
        }
    }

    func flushTrackingObjects(_ flushableObjects: [FlushableObject], completion: ((FlushResult) -> Void)? = nil) {
        guard !flushableObjects.isEmpty else {
            completion?(.success(0))
            return
        }

        // Resolve tracking objects up-front so we can partition into sendable vs skipped
        // and compute the count as an immutable value before any async work begins.
        let resolved = flushableObjects.map { ($0, getTrackingObject(for: $0)) }

        for (flushableObject, trackingObject) in resolved where trackingObject.customerIds.isEmpty {
            Exponea.logger.log(
                .warning,
                message: """
                Skipping tracking object \(flushableObject.databaseObjectProxy.objectID): \
                no customer IDs available after applying defaults.
                """
            )
        }

        var candidates: [(FlushableObject, any TrackingObject)] = []
        for (flushableObject, trackingObject) in resolved {
            if isEmptyUntrustedCustomerUpdate(trackingObject) {
                Exponea.logger.log(
                    .verbose,
                    message: """
                    Skipping empty customer update for stream integration \
                    (only cookie ID, no properties): \(flushableObject.databaseObjectProxy.objectID)
                    """
                )
                do {
                    try database.delete(flushableObject.databaseObjectProxy)
                } catch {
                    Exponea.logger.log(
                        .error,
                        message: """
                        Failed to remove skipped empty customer update from database: \
                        \(flushableObject.databaseObjectProxy.objectID). \(error.localizedDescription)
                        """
                    )
                }
            } else {
                candidates.append((flushableObject, trackingObject))
            }
        }

        let sendable = candidates.filter { !$0.1.customerIds.isEmpty }
        let attemptedCount = sendable.count

        guard attemptedCount > 0 else {
            completion?(.success(0))
            return
        }

        let lock = NSLock()
        var successCount = 0

        let group = DispatchGroup()
        for (flushableObject, trackingObject) in sendable {
            group.enter()
            repository.trackObject(trackingObject) { [weak self] result in
                if case .success = result {
                    lock.withLock { successCount += 1 }
                }
                self?.onObjectFlush(flushableObject: flushableObject, result: result)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if successCount == 0 {
                Exponea.logger.log(
                    .warning,
                    message: "Flush failed: 0/\(attemptedCount) objects succeeded."
                )
            } else if successCount < attemptedCount {
                Exponea.logger.log(
                    .warning,
                    message: "Flush partially failed: \(successCount)/\(attemptedCount) objects succeeded."
                )
            }
            completion?(.success(successCount))
        }
    }

    func onObjectFlush(flushableObject: FlushableObject, result: EmptyResult<RepositoryError>) {
        switch result {
        case .success:
            Exponea.logger.log(
                .verbose,
                message: "Successfully uploaded tracking object: \(flushableObject.databaseObjectProxy.objectID)."
            )
            do {
                let trackingObject = getTrackingObject(for: flushableObject)
                
                if trackingObject is CustomerTrackingObject {
                    customerIdentifiedHandler()
                    inAppRefreshCallback?()
                }
                try database.delete(flushableObject.databaseObjectProxy)
            } catch {
                Exponea.logger.log(
                    .error,
                    message: """
                    Failed to remove tracking object from database: \(flushableObject.databaseObjectProxy.objectID).
                    \(error.localizedDescription)
                    """
                )
            }
        case .failure(let error):
            switch error {
            case .connectionError, .serverError(nil):
                // If server or connection error, bail here and do not increase retry count
                Exponea.logger.log(
                    .warning,
                    message: """
                    Failed to upload customer event due to connection or server error. \
                    \(error.localizedDescription)
                    """
                )
            default:
                Exponea.logger.log(
                    .error,
                    message: "Failed to upload customer update. \(error.localizedDescription)"
                )
                increaseRetry(for: flushableObject.databaseObjectProxy)
            }
        }
    }

    func increaseRetry(for databaseObjectProxy: DatabaseObjectProxy) {
        do {
            let max = repository.configuration.flushEventMaxRetries
            if databaseObjectProxy.retries + 1 >= max {
                Exponea.logger.log(
                    .error,
                    message: """
                    Maximum retry count reached, deleting tracking object: \(databaseObjectProxy.objectID)
                    """
                )
                try database.delete(databaseObjectProxy)
            } else {
                Exponea.logger.log(
                    .error,
                    message: """
                    Increasing retry count (\(databaseObjectProxy.retries)) for tracking object: \
                    \(databaseObjectProxy.objectID)
                    """
                )
                try database.addRetry(databaseObjectProxy)
            }
        } catch {
            Exponea.logger.log(
                .error,
                message: """
                Failed to update retry count or remove object from database: \
                \(databaseObjectProxy.objectID). \(error.localizedDescription)
                """
            )
        }
    }

    func hasPendingData() -> Bool {
        guard !isFlushingData else { return true }
        let events = (try? database.fetchTrackEvent()) ?? []
        let customers = (try? database.fetchTrackCustomer()) ?? []
        return !events.isEmpty || !customers.isEmpty
    }
}

private extension FlushingManager {
    /// Detects customer updates that carry only an untrusted cookie ID and empty
    /// properties in stream mode. The backend rejects these, so the SDK filters
    /// them at flush time to avoid wasted retry cycles.
    func isEmptyUntrustedCustomerUpdate(_ trackingObject: TrackingObject) -> Bool {
        guard trackingObject is CustomerTrackingObject else { return false }
        guard trackingObject.exponeaProject.type.isStream else { return false }

        let hasOnlyCookie = trackingObject.customerIds.count == 1
            && trackingObject.customerIds.keys.contains("cookie")
        guard hasOnlyCookie else { return false }

        var mergedProperties: [String: JSONValue] = [:]
        for item in trackingObject.dataTypes {
            if case .properties(let props) = item {
                mergedProperties.merge(props, uniquingKeysWith: { first, _ in first })
            }
        }
        return mergedProperties.isEmpty
    }

    func getTrackingObject(for flushableObject: FlushableObject) -> any TrackingObject {
        // Use mainProject (static auth) for baseUrl, integrationId, and default authorization.
        // Tracking endpoints should not receive the advanced-auth JWT Bearer token.
        // Stream: pass .none — JWT is injected at request time in RequestFactory from ServerRepository.streamAuthProvider.
        let currentProject = repository.configuration.mainProject
        let defaultAuth: Authorization
        if let project = currentProject as? ExponeaProject {
            defaultAuth = project.authorization
        } else {
            defaultAuth = Authorization.none
        }
        return flushableObject.getTrackingObject(
            defaultBaseUrl: currentProject.baseUrl,
            defaultIntegrationId: currentProject.integrationId,
            defaultAuthorization: defaultAuth
        )
    }
}
