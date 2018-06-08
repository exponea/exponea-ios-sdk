//
//  TrackingViewController.swift
//  Example
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK
import UserNotifications

class TrackingViewController: UIViewController {

    @IBAction func paymentPressed(_ sender: Any) {
        Exponea.shared.trackPayment(properties: ["value" : "99", "custom_info" : "sample payment"], timestamp: nil)
    }
    
    @IBAction func registerForPush() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
