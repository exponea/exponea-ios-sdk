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

    private let reachability: Reachability

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
        guard let reachability = Reachability(hostname: repository.configuration.hostname) else {
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
            let events = try database.fetchTrackEvent().reversed()
            let customers = try database.fetchTrackCustomer().reversed()

            Exponea.logger.log(.verbose, message: """
                Flushing data: \(events.count + customers.count) total objects to upload, \
                \(events.count) events and \(customers.count) customer updates.
                """)

            // Check if we have any data otherwise bail
            guard !events.isEmpty || !customers.isEmpty else {
                isFlushingData = false
                completion?()
                return
            }

            var customersDone = false
            var eventsDone = false

            flushCustomerTracking(Array(customers), completion: {
                customersDone = true
                if eventsDone && customersDone {
                    self.isFlushingData = false
                    completion?()
                }
            })

            flushEventTracking(Array(events), completion: {
                eventsDone = true
                if eventsDone && customersDone {
                    self.isFlushingData = false
                    completion?()
                }
            })
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
            self.isFlushingData = false
            completion?()
        }
    }

    func flushCustomerTracking(_ customers: [TrackCustomerThreadSafe], completion: (() -> Void)? = nil) {
        var counter = customers.count
        for customer in customers {
            repository.trackCustomer(with: customer.dataTypes, for: database.customer.ids) { [weak self] (result) in
                switch result {
                case .success:
                    Exponea.logger.log(.verbose, message: """
                        Successfully uploaded customer update: \(customer.managedObjectID).
                        """)
                    do {
                        try self?.database.delete(customer)
                    } catch {
                        Exponea.logger.log(.error, message: """
                            Failed to remove object from database: \(customer.managedObjectID).
                            \(error.localizedDescription)
                            """)
                    }
                case .failure(let error):
                    switch error {
                    case .connectionError, .serverError(nil):
                        // If server or connection error, bail here and do not increase retry count
                        Exponea.logger.log(.warning, message: """
                            Failed to upload customer event due to connection or server error. \
                            \(error.localizedDescription)
                            """)

                    default:
                        // Handle all other errors regularly
                        Exponea.logger.log(.error, message: """
                            Failed to upload customer update. \(error.localizedDescription)
                            """)

                        // If we have reached the max count of retries, delete the object.
                        // Otherwise save changes and try again next time.
                        do {
                            let max = self?.repository.configuration.flushEventMaxRetries
                                ?? Constants.Session.maxRetries
                            if customer.retries + 1 >= max {
                                Exponea.logger.log(.error, message: """
                                    Maximum retry count reached, deleting customer event: \(customer.managedObjectID)
                                    """)
                                try self?.database.delete(customer)
                            } else {
                                Exponea.logger.log(.error, message: """
                                    Increasing retry count (\(customer.retries)) for customer event: \
                                    \(customer.managedObjectID)
                                    """)
                                try self?.database.addRetry(customer)
                            }
                        } catch {
                            Exponea.logger.log(.error, message: """
                                Failed to update retry count or remove object from database: \
                                \(customer.managedObjectID). \(error.localizedDescription)
                                """)
                        }
                    }
                }

                // Handle request counter, potentially call completion
                counter -= 1
                if counter == 0 {
                    completion?()
                }
            }
        }

        // If we have no customer updates, call completion
        if customers.isEmpty {
            completion?()
        }
    }

    func flushEventTracking(_ events: [TrackEventThreadSafe], completion: (() -> Void)? = nil) {
        var counter = events.count
        for event in events {
            repository.trackEvent(with: event.dataTypes, for: database.customer.ids) { [weak self] (result) in
                switch result {
                case .success:
                    Exponea.logger.log(.verbose, message: "Successfully uploaded event: \(event.managedObjectID).")
                    do {
                        try self?.database.delete(event)
                    } catch {
                        Exponea.logger.log(.error, message: """
                            Failed to remove object from database: \(event.managedObjectID). \
                            \(error.localizedDescription)
                            """)
                    }
                case .failure(let error):
                    switch error {
                    case .connectionError, .serverError:
                        // If server or connection error, bail here and do not increase retry count
                        Exponea.logger.log(.warning, message: """
                            Failed to upload event due to connection or server error. \
                            \(error.localizedDescription)
                            """)

                    default:
                        Exponea.logger.log(.error, message: "Failed to upload event. \(error.localizedDescription)")

                        // If we have reached the max count of retries, delete the object.
                        // Otherwise save changes and try again next time.
                        do {
                            let max = self?.repository.configuration.flushEventMaxRetries
                                ?? Constants.Session.maxRetries
                            if event.retries + 1 >= max {
                                Exponea.logger.log(.error, message: """
                                    Maximum retry count reached, deleting event: \(event.managedObjectID)
                                    """)
                                try self?.database.delete(event)
                            } else {
                                Exponea.logger.log(.error, message: """
                                    Increasing retry count (\(event.retries)) for event: \(event.managedObjectID)
                                    """)
                                try self?.database.addRetry(event)
                            }
                        } catch {
                            Exponea.logger.log(.error, message: """
                                Failed to update retry count or remove object from database: \(event.managedObjectID).
                                \(error.localizedDescription)
                                """)
                        }
                    }
                }

                // Handle request counter, potentially call completion
                counter -= 1
                if counter == 0 {
                    completion?()
                }
            }
        }

        // If we have no events, call completion
        if events.isEmpty {
            completion?()
        }
    }
}
