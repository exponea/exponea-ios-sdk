//
//  UIApplication+HasUIApplicationDelegate.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 07/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@objc protocol UIApplicationDelegating {
    var delegate: UIApplicationDelegate? { get set }
}

extension UIApplication: UIApplicationDelegating {}

final class BasicUIApplicationDelegating: NSObject, UIApplicationDelegating {
    // swiftlint:disable:next weak_delegate
    dynamic var delegate: UIApplicationDelegate?
}
