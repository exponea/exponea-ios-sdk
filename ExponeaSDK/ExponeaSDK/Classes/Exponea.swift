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
    var entitiesManager: EntitiesManager!

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
                Exponea.logger.log(.error, message: "ExponeaSDK isn't configured.")
                fatalError("ExponeaSDK isn't configured.")
            }
            configuration.projectToken = newValue
        }
    }

    /// A logger used to log all messages from the SDK.
    public static var logger: Logger = Logger()

    /// Shared instance of ExponeaSDK
    public static let shared = Exponea()

    init(dbManager: EntitiesManager) {
        self.entitiesManager = dbManager
    }

    public init() {
        self.entitiesManager = EntitiesManager()
    }

}

internal extension Exponea {
    internal func configure(projectToken: String) {
        configuration = Configuration(projectToken: projectToken)
    }
    private func configure(plistName: String) {
        configuration = Configuration(plistName: plistName)
    }
    internal func addCustomerEvent(customerId: KeyValueModel, properties: [KeyValueModel],
                                   timestamp: Double?, eventType: String?) {
        guard configured, let token = projectToken else {
            fatalError("Project token not configured")
        }
        entitiesManager.trackEvents(projectToken: token, customerId: customerId, properties: properties,
                                    timestamp: timestamp, eventType: eventType)
    }
}

public extension Exponea {

    /// Initialize the configuration with a projectId (token)
    ///
    /// - Parameters:
    ///     - projectToken: Project Token to be used through the SDK
    public class func configure(projectToken: String) {
        shared.configure(projectToken: projectToken)
    }

    /// Initialize the configuration with a plist file containing the keys
    /// for the ExponeaSDK
    /// Mandatory key: exponeaProjectIdKey
    ///
    /// - Parameters:
    ///     - plistName: List name containing the SDK setup keys
    public class func configure(plistName: String) {
        shared.configure(plistName: plistName)
    }

    /// Add events for a specific customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    ///     - eventType: Type of event to be tracked
    public class func addCustomerEvent(customerId: KeyValueModel, properties: [KeyValueModel],
                                       timestamp: Double?, eventType: String?) {
        shared.addCustomerEvent(customerId: customerId,
                                properties: properties, timestamp: timestamp, eventType: eventType)
    }

}
