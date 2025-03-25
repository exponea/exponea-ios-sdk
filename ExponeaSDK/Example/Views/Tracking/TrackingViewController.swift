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

    @IBOutlet weak var automaticSessionTrackingSwitch: UISwitch!
    @IBOutlet weak var sessionStartButton: UIButton!
    @IBOutlet weak var sessionEndButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let config = Exponea.shared.configuration {
            automaticSessionTrackingSwitch.setOn(config.automaticSessionTracking, animated: true)
            sessionStartButton.isEnabled = !config.automaticSessionTracking
            sessionEndButton.isEnabled = !config.automaticSessionTracking
        }
        
        SegmentationManager.shared.addCallback(
            callbackData: .init(
                category: .discovery(),
                isIncludeFirstLoad: true,
                onNewData: { segments in
            print(segments)
        }))
    }

    @IBAction func paymentPressed(_ sender: Any) {
        Exponea.shared.trackPayment(properties: ["value": "99", "custom_info": "sample payment"], timestamp: nil)
    }

    @IBAction func registerForPush() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, _) in
            // Enable or disable features based on authorization.
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    @available(iOS 12.0, *)
    @IBAction func registerForProvisionalPush() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.provisional, .badge, .alert, .sound]) { (granted, _) in
            // Enable or disable features based on authorization.
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    @IBAction func campaignClickPressed(_ sender: Any) {
        // swiftlint:disable:next line_length
        if let url = URL(safeString: "https://panaxeo.com/exponea/product.html?iitt=VuU9RM4lhMPshFWladJLVZ8ARMWsVuegnkU7VkichfYcbdiA&utm_campaign=Test%20direct%20links&utm_source=exponea&utm_medium=email&xnpe_cmp=EiAHASXwhARMc-4pi3HQKTynsFBXa54EjBjb-qh2HAv3kSEpscfCI2HXQQ.XlWYaES2X-r8Nlv4J22eO0M3Rgk") {
        Exponea.shared.trackCampaignClick(url: url, timestamp: nil)
        }
    }

    @IBAction func trackPushNotifReceived(_ sender: Any) {
        let userInfo: [AnyHashable: Any] = [
            "url": "https://example.com/ios",
            "title": "iOS Title",
            "action": "app",
            "message": "iOS Message",
            "image": "https://example.com/image.jpg",
            "actions": [
                ["title": "Action 1", "action": "app", "url": "https://example.com/action1/ios"],
                ["title": "Action 2", "action": "browser", "url": "https://example.com/action2/ios"]
            ],
            "sound": "default",
            "aps": [
                "alert": ["title": "iOS Alert Title", "body": "iOS Alert Body"],
                "mutable-content": 1
            ],
            "attributes": [
                "event_type": "campaign",
                "campaign_id": "123456",
                "campaign_name": "iOS Campaign",
                "action_id": 1,
                "action_type": "mobile notification",
                "action_name": "iOS Action",
                "campaign_policy": "policy",
                "consent_category": "General consent",
                "subject": "iOS Subject",
                "language": "en",
                "platform": "ios",
                "sent_timestamp": 1631234567.89,
                "recipient": "ios@example.com"
            ],
            "url_params": ["param1": "value1", "param2": "value2"],
            "source": "xnpe_platform",
            "silent": false,
            "has_tracking_consent": true,
            "consent_category_tracking": "iOS Consent"
        ]
        Exponea.shared.trackPushReceived(userInfo: userInfo)
    }

    @IBAction func trackPushNotifClick(_ sender: Any) {
        let userInfo: [AnyHashable: Any] = [
            "url": "https://example.com/ios",
            "title": "iOS Title",
            "action": "app",
            "message": "iOS Message",
            "image": "https://example.com/image.jpg",
            "actions": [
                ["title": "Action 1", "action": "app", "url": "https://example.com/action1/ios"],
                ["title": "Action 2", "action": "browser", "url": "https://example.com/action2/ios"]
            ],
            "sound": "default",
            "aps": [
                "alert": ["title": "iOS Alert Title", "body": "iOS Alert Body"],
                "mutable-content": 1
            ],
            "attributes": [
                "event_type": "campaign",
                "campaign_id": "123456",
                "campaign_name": "iOS Campaign",
                "action_id": 1,
                "action_type": "mobile notification",
                "action_name": "iOS Action",
                "campaign_policy": "policy",
                "consent_category": "General consent",
                "subject": "iOS Subject",
                "language": "en",
                "platform": "ios",
                "sent_timestamp": 1631234567.89,
                "recipient": "ios@example.com"
            ],
            "url_params": ["param1": "value1", "param2": "value2"],
            "source": "xnpe_platform",
            "silent": false,
            "has_tracking_consent": true,
            "consent_category_tracking": "iOS Consent"
        ]
        Exponea.shared.trackPushOpened(with: userInfo)
    }

    @IBAction func automaticSessionTrackingChanged(_ sender: UISwitch) {
        let automaticSessionTracking = sender.isOn ?
        Exponea.AutomaticSessionTracking.enabled() : Exponea.AutomaticSessionTracking.disabled
        Exponea.shared.setAutomaticSessionTracking(automaticSessionTracking: automaticSessionTracking)
        if let config = Exponea.shared.configuration {
            sessionStartButton.isEnabled = !config.automaticSessionTracking
            sessionEndButton.isEnabled = !config.automaticSessionTracking
        }
    }
    @IBAction func sessionStartPressed(_ sender: UIButton) {
        Exponea.shared.trackSessionStart()
    }

    @IBAction func sessionEndPressed(_ sender: UIButton) {
        Exponea.shared.trackSessionEnd()
    }
}
