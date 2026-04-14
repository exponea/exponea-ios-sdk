//
//  BuildConfiguration.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 24/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

func isReactNativeSDK() -> Bool {
    BuildConfigurationShared.isReactNativeSDK()
}

func isFlutterSDK() -> Bool {
    BuildConfigurationShared.isFlutterSDK()
}

func isXamarinSDK() -> Bool {
    BuildConfigurationShared.isXamarinSDK()
}

func isMauiSDK() -> Bool {
    BuildConfigurationShared.isMauiSDK()
}

func isCalledFromExampleApp() -> Bool {
    BuildConfigurationShared.isCalledFromExampleApp()
}

func isCalledFromSDKTests() -> Bool {
    BuildConfigurationShared.isCalledFromSDKTests()
}

func getReactNativeSDKVersion() -> String? {
    getVersionFromClass("ExponeaRNVersion")
}

func getFlutterSDKVersion() -> String? {
    getVersionFromClass("ExponeaFlutterVersion")
}

func getXamarinSDKVersion() -> String? {
    getVersionFromClass("ExponeaXamarinVersion")
}

func getMauiVersion() -> String? {
    getVersionFromClass("BloomreachMauiVersion")
}

private func getVersionFromClass(_ className: String) -> String? {
    guard let foundClass = NSClassFromString(className) else {
        Exponea.logger.log(.error, message: "Missing '\(className)' class")
        return nil
    }
    guard let asNSObjectClass = foundClass as? NSObject.Type else {
        Exponea.logger.log(.error, message: "Class '\(className)' does not conform to NSObject")
        return nil
    }
    guard let asProviderClass = asNSObjectClass as? ExponeaVersionProvider.Type else {
        Exponea.logger.log(.error, message: "Class '\(className)' does not conform to ExponeaVersionProvider")
        return nil
    }
    let providerInstance = asProviderClass.init()
    Exponea.logger.log(.verbose, message: "Version provider \(className) has been found")
    return providerInstance.getVersion()
}
