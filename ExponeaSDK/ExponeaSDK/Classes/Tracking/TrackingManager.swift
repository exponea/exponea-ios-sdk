//
//  TrackingManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UIKit
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

/// The Tracking Manager class is responsible to manage the automatic tracking events when
/// it's enable and persist the data according to each event type.
class TrackingManager {
    let database: DatabaseManagerType
    let repository: RepositoryType
    let device: DeviceProperties
    let onEventCallback: (EventType, [DataType]) -> Void

    /// The identifiers of the the current customer.
    var customerIds: [String: String] {
        return database.currentCustomer.ids
    }

    var customerCookie: String {
        return database.currentCustomer.uuid.uuidString
    }

    /// Returns the push token of the current customer if there is any.
    var customerPushToken: String? {
        return database.currentCustomer.pushToken
    }

    /// The manager for push registration and delivery tracking
    lazy var notificationsManager: PushNotificationManagerType = PushNotificationManager(
        trackingConsentManager: Exponea.shared.trackingConsentManager!,
        trackingManager: self,
        swizzlingEnabled: repository.configuration.automaticPushNotificationTracking,
        requirePushAuthorization: repository.configuration.requirePushAuthorization,
        appGroup: repository.configuration.appGroup,
        tokenTrackFrequency: repository.configuration.tokenTrackFrequency,
        currentPushToken: database.currentCustomer.pushToken,
        lastTokenTrackDate: database.currentCustomer.lastTokenTrackDate,
        urlOpener: UrlOpener()
    )

    private var flushingManager: FlushingManagerType

    // Manager for  session tracking
    private lazy var sessionManager: SessionManagerType = SessionManager(
        configuration: repository.configuration,
        userDefaults: userDefaults,
        trackingDelegate: self
    )

    /// User defaults used to store basic data and flags.
    private let userDefaults: UserDefaults

    // Background task, if there is any - used to track sessions and flush data.
    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid {
        didSet {
            if backgroundTask == UIBackgroundTaskIdentifier.invalid && backgroundWorkItem != nil {
                Exponea.logger.log(.verbose, message: "Background task ended, stopping background work item.")
                backgroundWorkItem?.cancel()
                backgroundWorkItem = nil
            }
        }
    }

    private var backgroundWorkItem: DispatchWorkItem? {
        didSet {
            // Stop background taks if work item is done
            if backgroundWorkItem == nil && backgroundTask != UIBackgroundTaskIdentifier.invalid {
                Exponea.logger.log(.verbose, message: "Stopping background task after work item done/cancelled.")
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = UIBackgroundTaskIdentifier.invalid
            }
        }
    }

    init(repository: RepositoryType,
         database: DatabaseManagerType,
         device: DeviceProperties = DeviceProperties(),
         flushingManager: FlushingManagerType,
         userDefaults: UserDefaults,
         onEventCallback: @escaping (EventType, [DataType]) -> Void
    ) throws {
        self.repository = repository
        self.database = database
        self.device = device
        self.userDefaults = userDefaults

        self.flushingManager = flushingManager
        self.onEventCallback = onEventCallback

        // Always track when we become active, enter background or terminate (used for both sessions and data flushing)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        initialSetup()
    }

    deinit {
        Exponea.logger.log(.verbose, message: "TrackingManager deallocated.")
    }

    func initialSetup() {
        // Track initial install event if necessary.
        trackInstallEvent()

        if let appGroup = repository.configuration.appGroup {
            database.currentCustomer.saveIdsToUserDefaults(appGroup: appGroup)
        }

        self.sessionManager.applicationDidBecomeActive()
    }

    /// Installation event is fired only once for the whole lifetime of the app on one
    /// device when the app is launched for the first time.
    internal func trackInstallEvent() {
        /// Checking if the APP was launched before.
        /// If the key value is false, means that the event was not fired before.
        let key = Constants.Keys.installTracked + database.currentCustomer.uuid.uuidString
        guard userDefaults.bool(forKey: key) == false else {
            Exponea.logger.log(.verbose, message: "Install event was already tracked, skipping.")
            return
        }

        /// In case the event was not fired, we call the track manager
        /// passing the install event type.
        do {
            // Get depdencies and track install event
            try track(.install, with: [.properties(device.properties),
                                       .timestamp(Date().timeIntervalSince1970),
                                       .customerIds(customerIds)
            ])

            /// Set the value to true if event was executed successfully
            userDefaults.set(true, forKey: key)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}

// MARK: -

extension TrackingManager: TrackingManagerType {
    public func hasPendingEvent(ofType type: String, withMaxAge maxAge: Double) throws -> Bool {
        let events = try database.fetchTrackEvent()
            .filter({ $0.eventType == type && $0.timestamp + maxAge >= Date().timeIntervalSince1970 })
        return !events.isEmpty
    }

    // Updates last logged event of given type with data
    // Event may be logged multiple times - for every project token
    public func updateLastPendingEvent(ofType type: String, with data: DataType) throws {
        var events = try database.fetchTrackEvent()
            .filter({ $0.eventType == type })
            .sorted(by: { $0.timestamp < $1.timestamp })
        var projectTokens: Set<String> = []
        while !events.isEmpty {
            let event = events.removeLast()
            if let projectToken = event.projectToken, !projectTokens.contains(projectToken) {
                projectTokens.insert(projectToken)
                try database.updateEvent(withId: event.databaseObjectProxy.objectID, withData: data)
            }
        }
    }

    public func processTrack(_ type: EventType, with data: [DataType]?, trackingAllowed: Bool) throws {
        try processTrack(type, with: data, trackingAllowed: trackingAllowed, for: nil)
    }

    public func processTrack(_ type: EventType, with data: [DataType]?, trackingAllowed: Bool, for customerId: String?) throws {
        try trackInternal(type, with: data, trackingAllowed: trackingAllowed, for: customerId)
    }

    public func track(_ type: EventType, with data: [DataType]?) throws {
        try trackInternal(type, with: data, trackingAllowed: true, for: nil)
    }
    
    private func trackInternal(
        _ type: EventType,
        with data: [DataType]?,
        trackingAllowed: Bool,
        for customerId: String?
    ) throws {
        /// Get token mapping or fail if no token provided.
        let projects = repository.configuration.projects(for: type)
        if projects.isEmpty {
            throw TrackingManagerError.unknownError("No project tokens provided.")
        }

        if trackingAllowed {
            Exponea.logger.log(.verbose, message: "Tracking event of type: \(type) with params \(data ?? [])")
        } else {
            Exponea.logger.log(.verbose, message: "Processing event of type: \(type) with params \(data ?? []) with tracking \(trackingAllowed)")
        }

        /// For each project token we have, track the data.
        for project in projects {
            var payload: [DataType] = data ?? []
            if let stringEventType = getEventTypeString(type: type) {
                payload.append(.eventType(stringEventType))
            }
            if canUseDefaultProperties(for: type) {
                payload = payload.addProperties(repository.configuration.defaultProperties)
            }
            switch type {
            case .identifyCustomer,
                 .registerPushToken:
                if let appGroup = repository.configuration.appGroup {
                    database.currentCustomer.saveIdsToUserDefaults(appGroup: appGroup)
                }
                try database.identifyCustomer(with: payload, into: project)
            case .install,
                 .sessionStart,
                 .sessionEnd,
                 .customEvent,
                 .payment,
                 .pushOpened,
                 .pushDelivered,
                 .campaignClick,
                 .banner,
                 .appInbox:
                if trackingAllowed {
                    try database.trackEvent(with: payload, into: project, for: customerId)
                }
            }
            self.onEventCallback(type, payload)
        }

        // If we have immediate flushing mode, flush after tracking
        if case .immediate = self.flushingManager.flushingMode {
            self.flushingManager.flushDataWith(delay: Constants.Tracking.immediateFlushDelay)
        }
    }
    
    private func canUseDefaultProperties(for eventType: EventType) -> Bool {
        return repository.configuration.allowDefaultCustomerProperties || EventType.identifyCustomer != eventType
    }

    public func trackInAppMessageShown(message: InAppMessage, trackingAllowed: Bool) {
        self.track(.show, for: message, trackingAllowed: trackingAllowed)
    }

    public func trackInAppMessageClick(
        message: InAppMessage,
        buttonText: String?,
        buttonLink: String?,
        trackingAllowed: Bool,
        isUserInteraction: Bool) {
            self.track(
                .click(buttonLabel: buttonText ?? "", url: buttonLink ?? "" ),
                for: message,
                trackingAllowed: trackingAllowed,
                isUserInteraction: isUserInteraction
            )
        }

    public func trackInAppContentBlocksClick(
        message: InAppContentBlockResponse,
        trackingAllowed: Bool,
        buttonText: String?,
        buttonLink: String?
    ) {
        track(
            .click(buttonLabel: buttonText ?? "", url: buttonLink ?? "" ),
            for: message,
            trackingAllowed: trackingAllowed,
            isUserInteraction: true
        )
    }

    public func trackInAppContentBlocksClose(message: InAppContentBlockResponse, trackingAllowed: Bool) {
        track(.close, for: message, trackingAllowed: trackingAllowed, isUserInteraction: true)
    }

    public func trackInAppContentBlocksShow(message: InAppContentBlockResponse, trackingAllowed: Bool) {
        track(.show, for: message, trackingAllowed: trackingAllowed)
    }

    public func trackInAppMessageClose(message: InAppMessage, trackingAllowed: Bool, isUserInteraction: Bool) {
        self.track(.close, for: message, trackingAllowed: trackingAllowed, isUserInteraction: isUserInteraction)
    }

    public func trackInAppMessageError(message: InAppMessage, error: String, trackingAllowed: Bool) {
        self.track(.error(message: error), for: message, trackingAllowed: trackingAllowed)
    }

    func getEventTypeString(type: EventType) -> String? {
        switch type {
        case .identifyCustomer: return nil
        case .registerPushToken: return nil
        case .customEvent: return nil
        case .install: return Constants.EventTypes.installation
        case .sessionStart: return Constants.EventTypes.sessionStart
        case .sessionEnd: return Constants.EventTypes.sessionEnd
        case .payment: return Constants.EventTypes.payment
        case .pushOpened: return Constants.EventTypes.pushOpen
        case .pushDelivered: return Constants.EventTypes.pushDelivered
        case .campaignClick: return Constants.EventTypes.campaignClick
        case .banner: return Constants.EventTypes.banner
        case .appInbox: return Constants.EventTypes.appInbox
        }
    }

    func ensureAutomaticSessionStarted() {
        sessionManager.ensureSessionStarted()
    }

    func manualSessionStart() {
        sessionManager.manualSessionStart()
    }

    func manualSessionEnd() {
        sessionManager.manualSessionEnd()
    }

    func setAutomaticSessionTracking(automaticSessionTracking: Exponea.AutomaticSessionTracking) {
        repository.configuration.automaticSessionTracking = automaticSessionTracking.enabled
        repository.configuration.sessionTimeout = automaticSessionTracking.timeout
        sessionManager = SessionManager(
            configuration: repository.configuration,
            userDefaults: userDefaults,
            trackingDelegate: self
        )
    }
}

// MARK: - Session tracking delegate

extension TrackingManager: SessionTrackingDelegate {
    func trackSessionStart(at timestamp: TimeInterval) {
        do {
            try track(
                .sessionStart,
                with: [
                    .eventType(EventType.sessionStart.rawValue),
                    .customerIds(customerIds),
                    .properties(device.properties),
                    .timestamp(timestamp)
                ]
            )
        } catch {
            Exponea.logger.log(.error, message: "Session start tracking error: \(error.localizedDescription)")
        }
    }

    func trackSessionEnd(at timestamp: TimeInterval, withDuration duration: TimeInterval) {
        var properties = device.properties
        properties["duration"] = .double(duration)
        do {
            try track(.sessionEnd, with: [.properties(properties), .timestamp(timestamp)])
        } catch {
            Exponea.logger.log(.error, message: "Session end tracking error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Application lifecycle

extension TrackingManager {
    @objc internal func applicationDidBecomeActive() {
        Exponea.shared.executeSafely {
            self.applicationDidBecomeActiveUnsafe()
        }
    }

    internal func applicationDidBecomeActiveUnsafe() {
        // Cancel background task if we have any
        if let item = backgroundWorkItem {
            item.cancel()
            backgroundWorkItem = nil
        }

        // Let the notification manager know the app has becom active
        notificationsManager.applicationDidBecomeActive()
        flushingManager.applicationDidBecomeActive()
        sessionManager.applicationDidBecomeActive()
    }

    @objc internal func applicationDidEnterBackground() {
        Exponea.shared.executeSafely {
            self.applicationDidEnterBackgroundUnsafe()
        }
    }

    internal func applicationDidEnterBackgroundUnsafe() {
        flushingManager.applicationDidEnterBackground()
        sessionManager.applicationDidEnterBackground()

        // Make sure to not create a new background task, if we already have one.
        guard backgroundTask == UIBackgroundTaskIdentifier.invalid else {
            return
        }

        // Start the background task
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        })

        // Dispatch after default session timeout
        let queue = DispatchQueue.global(qos: .background)
        let item = createBackgroundWorkItem()
        backgroundWorkItem = item

        // Schedule the task to run using delay if applicable
        let shouldDelay = repository.configuration.automaticSessionTracking
        let delay = shouldDelay ? repository.configuration.sessionTimeout : 0
        queue.asyncAfter(deadline: .now() + delay, execute: item)

        Exponea.logger.log(.verbose, message: "Started background task with delay \(delay)s.")
    }

    internal func createBackgroundWorkItem() -> DispatchWorkItem {
        let unsafeWork = { [weak self] in
            guard let `self` = self else { return }
            guard Exponea.shared.isConfigured else { return }

            // If we're cancelled, stop background task
            if self.backgroundWorkItem?.isCancelled ?? false {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
                return
            }

            self.sessionManager.doSessionTimeoutBackgroundWork()

            switch self.flushingManager.flushingMode {
            case .periodic, .automatic, .immediate:
                // Only stop background task after we upload
                self.flushingManager.flushData(completion: { [weak self] _ in
                    guard let weakSelf = self else { return }
                    UIApplication.shared.endBackgroundTask(weakSelf.backgroundTask)
                    weakSelf.backgroundTask = UIBackgroundTaskIdentifier.invalid
                })

            default:
                // We're done
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
            }
        }

        return DispatchWorkItem { Exponea.shared.executeSafely { unsafeWork() } }
    }
}

// MARK: - In-app messages -

extension TrackingManager: InAppMessageTrackingDelegate {
    public func track(_ event: InAppMessageEvent, for message: InAppMessage, trackingAllowed: Bool, isUserInteraction: Bool = false) {
        var eventData: [String: JSONValue] = [
            "action": .string(event.action),
            "banner_id": .string(message.id),
            "banner_name": .string(message.name),
            "banner_type": .string(message.messageType.rawValue),
            "interaction": .bool(isUserInteraction),
            "os": .string("iOS"),
            "type": .string("in-app message"),
            "variant_id": .int(message.variantId),
            "variant_name": .string(message.variantName)
        ]
        if case .click(let text, let url) = event {
            eventData["text"] = .string(text)
            eventData["link"] = .string(url)
            if (GdprTracking.isTrackForced(url)) {
                eventData["tracking_forced"] = .bool(true)
            }
        }
        if case .error(let errorMessage) = event {
            eventData["error"] = .string(errorMessage)
        }
        if (message.consentCategoryTracking != nil) {
            eventData["consent_category_tracking"] = .string(message.consentCategoryTracking!)
        }        
        do {
            try processTrack(
                .banner,
                with: [
                    .properties(device.properties),
                    .properties(eventData)
                ],
                trackingAllowed: trackingAllowed
            )
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}

// MARK: - In-app Content Blocks -

extension TrackingManager: InAppContentBlocksTrackingDelegate {
    public func track(_ event: InAppContentBlocksTrackingEvent, for message: InAppContentBlockResponse, trackingAllowed: Bool, isUserInteraction: Bool = false) {
        var eventData: [String: JSONValue] = [
            "action": .string(event.action),
            "banner_id": .string(message.id),
            "interaction": .bool(isUserInteraction),
            "os": .string("iOS"),
            "type": .string("in-app content block"),
            "banner_type": .string(message.contentType?.rawValue ?? message.personalizedMessage?.contentType?.rawValue ?? "null"),
            "placeholder": .string(message.placeholders.joined(separator: ", ")),
            "banner_name": .string(message.name),
            "platform": .string("ios")
        ]
        if let variantId = message.personalizedMessage?.variantId{
            eventData["variant_id"] = .int(variantId)
        }
        if let variantName = message.personalizedMessage?.variantName{
            eventData["variant_name"] = .string(variantName)
        }
        if let consentCategory = message.trackingConsentCategory {
            eventData["consent_category_tracking"] = .string(consentCategory)
        }
        if case .click(let text, let url) = event {
            eventData["text"] = .string(text)
            eventData["link"] = .string(url)
            if (GdprTracking.isTrackForced(url)) {
                eventData["tracking_forced"] = .bool(true)
            }
        }
        if case .error(let errorMessage) = event {
            eventData["error"] = .string(errorMessage)
        }
        do {
            try processTrack(
                .banner,
                with: [
                    .properties(device.properties),
                    .properties(eventData)
                ],
                trackingAllowed: trackingAllowed
            )
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}

// MARK: - Anonymize -

extension TrackingManager {
    public func anonymize(exponeaProject: ExponeaProject, projectMapping: [EventType: [ExponeaProject]]?) throws {
        let pushToken = customerPushToken
        try track(EventType.registerPushToken, with: [.pushNotificationToken(token: nil, authorized: false)])
        sessionManager.clear()

        repository.configuration.switchProjects(mainProject: exponeaProject, projectMapping: projectMapping)

        database.makeNewCustomer()
        UNAuthorizationStatusProvider.current.isAuthorized { authorized in
            Exponea.shared.executeSafely {
                try self.track(
                    EventType.registerPushToken,
                    with: [.pushNotificationToken(token: pushToken, authorized: authorized)]
                )
            }
        }
        initialSetup()
    }
}
