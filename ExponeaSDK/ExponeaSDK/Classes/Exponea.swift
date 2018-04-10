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
        if let _ = configuration.projectId {
            return true
        }
        return false
    }

    /// ProjectId (token) property
    public var projectId: String? {
        get {
            return configuration.projectId
        }
        set {
            guard configured else {
                // FIXME: Implement Log error!
                fatalError("ExponeaSDK isn't configured.")
            }
            configuration.projectId = newValue
        }
    }

    /// Shared instance of ExponeaSDK
    public static let shared = Exponea()

    public init() {}

}

private extension Exponea {
    private func configure(projectId: String) {
        configuration = Configuration(projectId: projectId)
    }
    private func configure(plistName: String) {
        configuration = Configuration(plistName: plistName)
    }
}

public extension Exponea {

    /// Initialize the configuration with a projectId (token)
    ///
    /// - Parameters:
    ///     - projectId: projectId (token) to be used through the SDK
    public class func configure(projectId: String) {
        shared.configure(projectId: projectId)
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

}
