//
//  VersionChecker.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 25/04/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//


import Foundation

public protocol ExponeaVersionProvider {
    init()
    func getVersion() -> String
}

internal class VersionChecker {
    internal let repository: ServerRepository
    internal init(repository: ServerRepository) {
        self.repository = repository
    }

    func warnIfNotLatestSDKVersion() {
        var actualVersion: String?
        var gitProject: String
        if isReactNativeSDK() {
            actualVersion = getReactNativeSDKVersion()
            gitProject = "exponea-react-native-sdk"
        } else if isFlutterSDK() {
            actualVersion = getFlutterSDKVersion()
            gitProject = "exponea-flutter-sdk"
        } else if isXamarinSDK() {
            actualVersion = getXamarinSDKVersion()
            gitProject = "exponea-xamarin-sdk"
        } else {
            actualVersion = Exponea.version
            gitProject = "exponea-ios-sdk"
        }

        if let actualVersion = actualVersion {
            repository.requestLastSDKVersion(completion: { result in
                if let error = result.error {
                    Exponea.logger.log(
                        LogLevel.error,
                        message: "Failed to retrieve last Exponea SDK version: \(error)."
                    )
                } else if let lastVersion = result.value {
                    if actualVersion.versionCompare(lastVersion) < 0 {
                        Exponea.logger.log(
                            LogLevel.error,
                            message: "\n####\n" +
                            "#### A newer version of the Exponea SDK is available!\n" +
                            "#### Your version: \(actualVersion)  Last version: \(lastVersion)\n" +
                            "#### Upgrade to the latest version to benefit from the new features " +
                                    "and better stability:\n" +
                            "#### https://github.com/exponea/\(gitProject)/releases\n" +
                            "####"
                        )
                    }
                }
            })
        } else {
            Exponea.logger.log(
                LogLevel.error,
                message: "Failed to retrieve last Exponea SDK version."
            )
        }
    }
}

extension String {
    func versionCompare(_ otherVersion: String) -> Int {
        return self.compare(otherVersion, options: .numeric).rawValue
    }
}
