//
//  WindowHelper.swift
//  ExponeaSDK
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import UIKit

enum WindowHelper {
    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
