//
//  Exponea.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

///
public class Exponea {

    /// The configuration object containing all the config data for the shared instance.
    fileprivate(set) var configuration: Configuration!

    /// Boolean identifier that returns if the SDK is configured or not.
    public var configured: Bool {
        if configuration.projectToken != nil {
            return true
        }
        return false
    }

    /// ProjectId (token) property
    public var projectToken: String? {
        get {
            return configuration.projectToken
        }
        set {
            guard configured else {
                Exponea.logger.log(.error, message: Constants.ErrorMessages.sdkNotConfigured)
                fatalError(Constants.ErrorMessages.sdkNotConfigured)
            }
            configuration.projectToken = newValue
        }
    }

    /// A logger used to log all messages from the SDK.
    public static var logger: Logger = Logger()

    /// Shared instance of ExponeaSDK
    public static let shared = Exponea()

    let trackingManager: TrackingManagerType

    init(database: DatabaseManagerType, repository: TrackingRepository) {
        self.trackingManager = TrackingManager(database: database, repository: repository)
    }

    public init() {
        let database = DatabaseManager()

        let configuration = APIConfiguration(baseURL: Constants.Repository.baseURL,
                                             contentType: Constants.Repository.contentType)
        let repository = ConnectionManager(configuration: configuration)

        self.trackingManager = TrackingManager(database: database, repository: repository)
    }

}

internal extension Exponea {

    internal func configure(projectToken: String) {
        configuration = Configuration(projectToken: projectToken)
    }
    internal func configure(plistName: String) {
        configuration = Configuration(plistName: plistName)
    }

    /// Installation event is fired only once for the whole lifetime of the app on one
    /// device when the app is launched for the first time.
    internal func trackInstallEvent() {
        /// Checking if the APP was launched before.
        /// If the key value is false, means that the event was not fired before.
        guard !UserDefaults.standard.bool(forKey: Constants.Keys.launchedBefore) else {
            return
        }
        /// In case the event was not fired, we call the track manager
        /// passing the install event type.
        guard trackingManager.trackEvent(.install, customData: nil) else {
            return
        }
        /// Set the value to true if event was executed successfully
        UserDefaults.standard.set(true, forKey: Constants.Keys.launchedBefore)
    }

    internal func addCustomerEvent(customerId: KeyValueModel, properties: [KeyValueModel],
                                   timestamp: Double?, eventType: String?) {
        guard configured else {
            Exponea.logger.log(.error,
                               message: Constants.ErrorMessages.tokenNotConfigured)
            return
        }

        var customData: [String: Any] = ["customerId": customerId,
                                         "properties": properties]

        if let projectToken = self.projectToken {
            customData["projectToken"] = projectToken
        }
        if let timestamp = timestamp {
            customData["timestamp"] = timestamp
        }
        if let eventType = eventType {
            customData["eventType"] = eventType
        }

        trackingManager.trackEvent(.event, customData: customData)
    }
}

public extension Exponea {

    /// Initialize the configuration with a projectId (token)
    ///
    /// - Parameters:
    ///     - projectToken: Project Token to be used through the SDK
    public class func configure(projectToken: String) {
        shared.configure(projectToken: projectToken)
        shared.trackInstallEvent()
    }

    /// Initialize the configuration with a plist file containing the keys
    /// for the ExponeaSDK
    /// Mandatory key: exponeaProjectIdKey
    ///
    /// - Parameters:
    ///     - plistName: List name containing the SDK setup keys
    public class func configure(plistName: String) {
        shared.configure(plistName: plistName)
        shared.trackInstallEvent()
    }

    /// Add events for a specific customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    ///     - eventType: Type of event to be tracked
    public class func addCustomerEvent(customerId: KeyValueModel,
                                       properties: [KeyValueModel],
                                       timestamp: Double?,
                                       eventType: String?) {
        shared.addCustomerEvent(customerId: customerId,
                                properties: properties,
                                timestamp: timestamp,
                                eventType: eventType)
    }

}
