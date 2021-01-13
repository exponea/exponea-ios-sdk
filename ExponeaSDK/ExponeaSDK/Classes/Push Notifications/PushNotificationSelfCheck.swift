//
//  PushNotificationSelfCheck.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 26/05/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import UIKit

final class PushNotificationSelfCheck {
    private let steps = [
        "App delegate",
        "Token callback",
        "Receive callback",
        "Notification center delegate",
        "Get push token",
        "Request self-check push",
        "Receive self-check push"
    ]

    private let timeout = 5.0

    private let trackingManager: TrackingManagerType
    private let flushingManager: FlushingManagerType
    private let repository: RepositoryType

    init(trackingManager: TrackingManagerType, flushingManager: FlushingManagerType, repository: RepositoryType) {
        self.trackingManager = trackingManager
        self.flushingManager = flushingManager
        self.repository = repository
    }

    private enum Selectors {
        static let pushToken = #selector(
            UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
        )

        static let receive = NSSelectorFromString(
            "application:didReceiveRemoteNotification:fetchCompletionHandler:"
        )
    }

    func start() {
        DispatchQueue.global(qos: .background).async {
            self.startInternal()
        }
    }

    func startInternal() {
        checkDelegates { [weak self] in
            guard let self = self else { return }
            self.waitForPushToken(delay: self.timeout / 10, retries: 10) { [weak self] pushToken in
                guard let self = self else { return }
                self.requestSelfCheckPush(pushToken: pushToken) {
                    self.waitForSelfCheckPush(delay: self.timeout / 10, retries: 10) { [weak self] in
                        guard let self = self else { return }
                        Exponea.shared.telemetryManager?.report(eventWithType: .selfCheck, properties: ["step": "7"])
                        self.showResult(
                            step: 7,
                            message: "You are now ready to receive push notifications from Exponea." +
                                " Check the documentation to learn how to setup rich push notifications"
                        )
                    }
                }
            }
        }
    }

    func checkDelegates(completion: @escaping () -> Void) {
        // querying UIApplication.shared needs to be done on main thread
        DispatchQueue.main.async {
            Exponea.shared.telemetryManager?.report(eventWithType: .selfCheck, properties: ["step": "0"])
            guard let appDelegate = UIApplication.shared.delegate else {
                self.showResult(
                    step: 0,
                    message: "UIApplication has no UIApplicationDelegate, something is terribly wrong."
                )
                return
            }
            Exponea.shared.telemetryManager?.report(eventWithType: .selfCheck, properties: ["step": "1"])
            guard class_getInstanceMethod(type(of: appDelegate), Selectors.pushToken) != nil else {
                self.showResult(
                    step: 1,
                    message: "Callback for push token registration not implemented." +
                    " Use ExponeaAppDelegate helper or your own implementation " +
                    "with a call to Exponea.shared.trackPushToken. "
                )
                return
            }
            Exponea.shared.telemetryManager?.report(eventWithType: .selfCheck, properties: ["step": "2"])
            guard class_getInstanceMethod(type(of: appDelegate), Selectors.receive) != nil else {
                self.showResult(
                    step: 2,
                    message: "Callback for push notification received not implemented." +
                    " Use ExponeaAppDelegate helper or your own implementation " +
                    "with a call to Exponea.shared.handlePushNotificationOpened. "
                )
                return
            }
            Exponea.shared.telemetryManager?.report(eventWithType: .selfCheck, properties: ["step": "3"])
            guard UNUserNotificationCenter.current().delegate != nil else {
                self.showResult(
                    step: 3,
                    message: "To receive push notifications you need to setup UNUserNotificationCenter delegate. " +
                    " Use ExponeaAppDelegate helper or your own implementation " +
                    "with call to Exponea.shared.handlePushNotificationOpened."
                )
                return
            }
            completion()
        }
    }

    func waitForPushToken(delay: TimeInterval, retries: Int, completion: @escaping (String) -> Void) {
        Exponea.shared.telemetryManager?.report(eventWithType: .selfCheck, properties: ["step": "4"])
        guard retries > 0 else {
            showResult(
                step: 4,
                message: "Unable to get push notification token. App needs Push Notifications capability. " +
                "Push notifications only work on a real device, not on an emulator."
            )
            return
        }
        if let pushToken = trackingManager.customerPushToken {
            if flushingManager.hasPendingData() {
                flushingManager.flushData()
            } else {
                // we need to allow some time for Exponea servers to process the push token
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
                    completion(pushToken)
                }
                return
            }
        }
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) {
            self.waitForPushToken(delay: delay, retries: retries - 1, completion: completion)
        }
    }

    func requestSelfCheckPush(pushToken: String, completion: @escaping () -> Void) {
        Exponea.shared.telemetryManager?.report(eventWithType: .selfCheck, properties: ["step": "5"])
        repository.requestSelfCheckPush(
            for: trackingManager.customerIds,
            pushToken: pushToken,
            completion: { result in
                guard result.error == nil else {
                    self.showResult(
                        step: 5,
                        message: "Unable to request push notification from exponea server. " +
                        "Check your setup in Exponea settings."
                    )
                    return
                }
                completion()
            }
        )
    }

    func waitForSelfCheckPush(delay: TimeInterval, retries: Int, completion: @escaping() -> Void) {
        Exponea.shared.telemetryManager?.report(eventWithType: .selfCheck, properties: ["step": "6"])
        guard retries > 0 else {
            self.showResult(
                step: 6,
                message: "Unable to receive push notification from exponea server. " +
                "Check your setup in Exponea settings. " +
                "Make sure you're calling Exponea.shared.handlePushNotificationOpened"
            )
            return
        }
        if trackingManager.notificationsManager.didReceiveSelfPushCheck {
            completion()
            return
        }
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) {
            self.waitForSelfCheckPush(delay: delay, retries: retries - 1, completion: completion)
        }
    }

    func showResult(step: Int, message: String) {
        let finished = step == steps.count
        let title = "Push notification setup self-check \(finished ? "succeeded" : "failed")"

        let messageWithDetails = "\(message) \n\nSelf-check only runs in debug builds.\n" +
            "To disable it, set Exponea.shared.checkPushSetup = false"
        Exponea.logger.log(
            finished ? .verbose : .error,
            message: "\(title) \(messageWithDetails.replacingOccurrences(of: "\n", with: ""))"
        )
        DispatchQueue.main.async {
            guard let viewController = InAppMessagePresenter.getTopViewController(window: nil) else {
                return
            }
            let alertController = UIAlertController(
                title: title,
                message: "\(self.getStepStatus(step: step))\n\n\(messageWithDetails)",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
            viewController.present(alertController, animated: true)
        }
    }

    func getStepStatus(step: Int) -> String {
        var stepsStatus = ""
        for doneStep in 0...min(step, steps.count - 1) {
            stepsStatus += "\(doneStep < step ? "✓" : "✘") \(steps[doneStep])\n"
        }
        return stepsStatus
    }
}
