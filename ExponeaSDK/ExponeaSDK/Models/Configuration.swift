//
//  Configuration.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

struct Configuration {

    internal var projectToken: String?

    init() {}

    init(projectToken: String) {
        self.projectToken = projectToken
    }

    init(plistName: String) {
        var projectToken: String?

        for bundle in Bundle.allBundles {
            let fileName = plistName.replacingOccurrences(of: ".plist", with: "")
            if let fileURL = bundle.url(forResource: fileName, withExtension: "plist") {

                let object = NSDictionary(contentsOf: fileURL)

                guard let keyDict = object as? [String: AnyObject] else {
                    Exponea.logger.log(.error, message: "Can't parse file \(fileName).plist")
                    fatalError("Can't parse file \(fileName).plist")
                }

                projectToken = keyDict[Constants.Keys.token] as? String
                break
            }
        }

        guard let finalProjectToken = projectToken else {
            Exponea.logger.log(.error, message: "Couldn't initialize projectId (token)")
            fatalError("Couldn't initialize projectId (token)")
        }

        self.projectToken = finalProjectToken
    }
}
