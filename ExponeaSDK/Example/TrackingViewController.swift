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

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = ""
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func customEventPressed(_ sender: Any) {
        Exponea.shared.trackEvent(properties: [
            "my_property_1" : "my property 1 value",
            "info" : "test from exponea SDK sample app",
            "some_number" : 5
            ], timestamp: nil, eventType: "my_custom_event_type")
    }
    
    
    @IBAction func paymentPressed(_ sender: Any) {
        
    }
    
    @IBAction func identifyCustomerPressed(_ sender: Any) {
        Exponea.shared.identifyCustomer(customerId: "test@test.com",
                                         properties: ["custom_property" : "somevalue"],
                                         timestamp: nil)
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
