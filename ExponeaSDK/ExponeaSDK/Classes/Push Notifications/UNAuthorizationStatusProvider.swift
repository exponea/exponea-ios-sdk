//
//  UNAuthorizationStatus.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 11/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

class UNAuthorizationStatusProvider {
    // we need to be able to override this in unit tests
    static var current: UNAuthorizationStatusProviding = UNUserNotificationCenter.current()
}

protocol UNAuthorizationStatusProviding {
    func isAuthorized(completion: @escaping (Bool) -> Void)
}

extension UNUserNotificationCenter: UNAuthorizationStatusProviding {
    func isAuthorized(completion: @escaping (Bool) -> Void) {
        getNotificationSettings { settings in
            completion(settings.authorizationStatus.rawValue == UNAuthorizationStatus.authorized.rawValue)
        }
    }
}
