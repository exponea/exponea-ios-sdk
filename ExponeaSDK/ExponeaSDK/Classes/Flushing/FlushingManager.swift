//
//  FlushingManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 13/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

class FlushingManager: FlushingManagerType {
    private let database: DatabaseManagerType
    private let repository: RepositoryType

    private let reachability: ExponeaReachability

    private let flushingSemaphore = DispatchSemaphore(value: 1)
    private var isFlushingData: Bool = false
    /// Used for periodic data flushing.
    private var flushingTimer: Timer?

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

    init(database: DatabaseManagerType, repository: RepositoryType) throws {
        self.database = database
        self.repository = repository

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

    func flushDataWith(delay: Double, completion: (() -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let `self` = self else { return }
            self.flushData()
        }
    }

    /// Method that flushes all data to the API.
    ///
    /// - Parameter completion: A completion that is called after all calls succeed or fail.
    func flushData(completion: (() -> Void)?) {
        do {
            // Check if flush is in progress
            flushingSemaphore.wait()
            guard !isFlushingData else {
                Exponea.logger.log(.warning, message: "Data flushing in progress, ignoring another flush call.")
                flushingSemaphore.signal()
                completion?()
                return
            }
            isFlushingData = true
            flushingSemaphore.signal()

            // Check if we have an internet connection otherwise bail
            guard reachability.connection != .none else {
                Exponea.logger.log(.warning, message: "Connection issues when flushing data, not flushing.")
                isFlushingData = false
                completion?()
                return
            }

            // Pull from db
            let events = try database.fetchTrackEvent()
            let customers = try database.fetchTrackCustomer()

            Exponea.logger.log(
                .verbose,
                message: """
                Flushing data: \(events.count + customers.count) total objects to upload, \
                \(events.count) events and \(customers.count) customer updates.
                """
            )

            // Check if we have any data otherwise bail
            guard !events.isEmpty || !customers.isEmpty else {
                isFlushingData = false
                completion?()
                return
            }

            flushTrackingObjects((customers + events).reversed()) {
                self.isFlushingData = false
                completion?()
            }
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
            self.isFlushingData = false
            completion?()
        }
    }

    func flushTrackingObjects(_ flushableObjects: [FlushableObject], completion: (() -> Void)? = nil) {
        var counter = flushableObjects.count
        guard counter > 0 else {
            completion?()
            return
        }
        for flushableObject in flushableObjects {
            // older events in database might be missing some of the information, let's use current settings as defaults
            let trackingObject = flushableObject.getTrackingObject(
                defaultBaseUrl: repository.configuration.baseUrl,
                defaultProjectToken: repository.configuration.projectToken,
                defaultAuthorization: repository.configuration.authorization
            )
            repository.trackObject(trackingObject, for: database.customer.ids) { [weak self] (result) in
                self?.onObjectFlush(flushableObject: flushableObject, result: result)
                counter -= 1
                if counter == 0 {
                    completion?()
                }
            }
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
}
