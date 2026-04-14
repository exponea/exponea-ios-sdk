//
//  BuildConfigurationShared.swift
//  ExponeaSDKShared
//
//  Created by Adam Mihalik on 17/07/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

public struct BuildConfigurationShared {
    public static func isReactNativeSDK() -> Bool {
        // Our react native SDK contains a protocol IsExponeaReactNativeSDK. We only use it for this purpose.
        return NSProtocolFromString("IsExponeaReactNativeSDK") != nil
    }

    public static func isFlutterSDK() -> Bool {
        // Our flutter SDK contains a protocol IsExponeaFlutterSDK. We only use it for this purpose.
        return NSProtocolFromString("IsExponeaFlutterSDK") != nil
    }

    public static func isXamarinSDK() -> Bool {
        // Our Xamarin SDK contains a protocol IsExponeaFlutterSDK. We only use it for this purpose.
        return NSProtocolFromString("IsExponeaXamarinSDK") != nil
    }

    public static func isMauiSDK() -> Bool {
        NSProtocolFromString("IsBloomreachMauiSDK") != nil
    }

    public static func isCalledFromExampleApp() -> Bool {
        return NSProtocolFromString("IsExponeaExampleApp") != nil
    }

    public static func isCalledFromSDKTests() -> Bool {
        return NSProtocolFromString("IsExponeaSDKTest") != nil
    }
}
