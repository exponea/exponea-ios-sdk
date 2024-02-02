//
//  BuildConfiguration.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 24/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

func isReactNativeSDK() -> Bool {
    // Our react native SDK contains a protocol IsExponeaReactNativeSDK. We only use it for this purpose.
    return NSProtocolFromString("IsExponeaReactNativeSDK") != nil
}

func isCapacitorSDK() -> Bool {
    // Our Capacitor SDK contains a protocol IsExponeaCapacitorSDK. We only use it for this purpose.
    return NSProtocolFromString("IsExponeaCapacitorSDK") != nil
}

func isFlutterSDK() -> Bool {
    // Our flutter SDK contains a protocol IsExponeaFlutterSDK. We only use it for this purpose.
    return NSProtocolFromString("IsExponeaFlutterSDK") != nil
}

func isXamarinSDK() -> Bool {
    // Our Xamarin SDK contains a protocol IsExponeaFlutterSDK. We only use it for this purpose.
    return NSProtocolFromString("IsExponeaXamarinSDK") != nil
}

func isMauiSDK() -> Bool {
    NSProtocolFromString("IsBloomreachMauiSDK") != nil
}

func isCalledFromExampleApp() -> Bool {
    return NSProtocolFromString("IsExponeaExampleApp") != nil
}

func isCalledFromSDKTests() -> Bool {
    return NSProtocolFromString("IsExponeaSDKTest") != nil
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
