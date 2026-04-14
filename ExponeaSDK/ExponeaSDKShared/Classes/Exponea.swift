//
//  Exponea.swift
//  ExponeaSDKShared
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

public class Exponea {
    public static let version = "3.11.0"
    /// A logger used to log all messages from the SDK.
    public static var logger: Logger = Logger()

    public static func isExponeaNotification(userInfo: [AnyHashable: Any]) -> Bool {
        return userInfo["source"] as? String == "xnpe_platform"
    }
}
