//
//  BuildConfiguration.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 24/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

// based on https://forums.swift.org/t/support-debug-only-code/11037

func inDebugBuild(_ code: () -> Void) {
    assert({
        code()
        return true
        }()
    )
}

func inReleaseBuild(_ code: () -> Void) {
    var skip: Bool = false
    inDebugBuild { skip = true }

    if !skip {
        code()
    }
}

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
