//
//  Configuration.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

struct Configuration {

    internal var projectToken: String?
    internal var authorization: String?
    internal var sessionTimeout: Double {
        get {
            return UserDefaults.standard.double(forKey: Constants.Keys.timeout)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.timeout)
        }
    }
    internal var lastSessionStarted: Double {
        get {
            return UserDefaults.standard.double(forKey: Constants.Keys.sessionStarted)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.sessionStarted)
        }
    }
    internal var lastSessionEndend: Double {
        get {
            return UserDefaults.standard.double(forKey: Constants.Keys.sessionEnded)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.sessionEnded)
        }
    }
    internal var autoSessionTracking: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.Keys.autoSessionTrack)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.autoSessionTrack)
        }
    }

    init() {}

    init(projectToken: String, authorization: String) {
        self.projectToken = projectToken
        self.authorization = authorization
    }

    init(plistName: String) {
        var projectToken: String?
        var authorization: String?

        for bundle in Bundle.allBundles {
            let fileName = plistName.replacingOccurrences(of: ".plist", with: "")
            if let fileURL = bundle.url(forResource: fileName, withExtension: "plist") {

                let object = NSDictionary(contentsOf: fileURL)

                guard let keyDict = object as? [String: AnyObject] else {
                    Exponea.logger.log(.error, message: "Can't parse file \(fileName).plist")
                    fatalError("Can't parse file \(fileName).plist")
                }

                projectToken = keyDict[Constants.Keys.token] as? String
                authorization = keyDict[Constants.Keys.authorization] as? String
                break
            }
        }

        guard let finalProjectToken = projectToken else {
            Exponea.logger.log(.error, message: "Couldn't initialize project token")
            return
        }
        guard let finalAuthorization = authorization else {
            Exponea.logger.log(.error, message: "Couldn't initialize authorization header")
            return
        }

        self.projectToken = finalProjectToken
        self.authorization = finalAuthorization
    }
}
