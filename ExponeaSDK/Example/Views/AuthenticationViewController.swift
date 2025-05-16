//
//  ViewController.swift
//  Example
//
//  Created by Dominik Hadl on 01/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK
import SwiftUI

class AuthenticationViewController: UIViewController {

    @IBOutlet weak var tokenField: UITextField! {
        didSet {
            tokenField.delegate = self
            tokenField.addTarget(self, action: #selector(tokenUpdated), for: .editingChanged)

            // load cached
            tokenField.text = UserDefaults.standard.string(forKey: "savedToken") ?? ""
        }
    }
    @IBOutlet weak var authField: UITextField! {
        didSet {
            authField.delegate = self
            // load cached
            authField.text = UserDefaults.standard.string(forKey: "savedAuth") ?? ""
        }
    }
    @IBOutlet var advancedPublicKeyField: UITextField! {
        didSet {
            advancedPublicKeyField.delegate = self
            // load cached
            advancedPublicKeyField.text = UserDefaults.standard.string(forKey: "savedAdvancedAuth") ?? ""
        }
    }

    @IBOutlet weak var urlField: UITextField! {
        didSet {
            urlField.delegate = self
            // load cached
            urlField.text = UserDefaults.standard.string(forKey: "savedUrl") ?? ""
        }
    }
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var clearDataButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        tokenField.attributedPlaceholder = makePlaceholderText(text: tokenField.placeholder)
        authField.attributedPlaceholder = makePlaceholderText(text: authField.placeholder)
        urlField.attributedPlaceholder = makePlaceholderText(text: urlField.placeholder)
        advancedPublicKeyField.attributedPlaceholder = makePlaceholderText(text: advancedPublicKeyField.placeholder)
        tokenUpdated()
    }

    private func makePlaceholderText(text: String?) -> NSAttributedString {
        return NSAttributedString(
            string: text ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
    }
    
    @IBAction func clearTapped() {
        Exponea.shared.clearLocalCustomerData(appGroup: "group.com.exponea.ExponeaSDK-Example2")
    }

    @IBAction func startPressed() {
        guard let token = tokenField.text else {
            return
        }

        var auth: ExponeaSDK.Authorization = .none

        if let text = authField.text, !text.isEmpty {
            auth = .token(text)
        }

        var advancedAuthPubKey: String?
        if let text = advancedPublicKeyField.text, !text.isEmpty {
            advancedAuthPubKey = text
        }
        var baseUrl: String?
        if let text = urlField.text, !text.isEmpty {
            baseUrl = text
        }

        // Prepare Example Advanced Auth
        CustomerTokenStorage.shared.configure(
            host: baseUrl,
            projectToken: token,
            publicKey: advancedAuthPubKey,
            expiration: nil
        )

        let exponea = Exponea.shared.onInitSucceeded {
            Exponea.logger.log(.verbose, message: "Configuration initialization succeeded")
            //Uncomment if you want to test in-app message delegate
//            Exponea.shared.inAppMessagesDelegate = InAppDelegate(overrideDefaultBehavior: true, trackActions: false)
            Coordinator(navigationController: self.navigationController).start()
        }
        Exponea.logger.logLevel = .verbose
        exponea.checkPushSetup = true
        Exponea.logger.log(.verbose, message: "Before Configuration call")
        exponea.configure(
            Exponea.ProjectSettings(
                projectToken: token,
                authorization: auth,
                baseUrl: baseUrl
            ),
            pushNotificationTracking: .enabled(
                appGroup: "group.com.exponea.ExponeaSDK-Example2",
                delegate: UIApplication.shared.delegate as? AppDelegate
            ),
            defaultProperties: [
                "Property01": "String value",
                "Property02": 123
            ],
            advancedAuthEnabled: advancedAuthPubKey?.isEmpty == false
        )
        exponea.inAppMessagesDelegate = TestDefaultInAppDelegate()
        Exponea.logger.log(.verbose, message: "After Configuration call")
        Exponea.shared.appInboxProvider = ExampleAppInboxProvider()
    }

    @objc func tokenUpdated() {
        startButton.isEnabled = (tokenField.text ?? "").count > 0
        startButton.alpha = startButton.isEnabled ? 1.0 : 0.4
    }

    @IBAction func hideKeyboard() {
        view.endEditing(true)
    }
}

extension AuthenticationViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case tokenField:
            UserDefaults.standard.set(textField.text, forKey: "savedToken")

        case authField where authField.text?.isEmpty == false:
            UserDefaults.standard.set(textField.text, forKey: "savedAuth")

        case urlField where urlField.text?.isEmpty == false:
            UserDefaults.standard.set(textField.text, forKey: "savedUrl")

        default:
            break
        }
    }
}

public class TestDefaultInAppDelegate: InAppMessageActionDelegate {
    public let overrideDefaultBehavior = false
    public let trackActions = true

    public func inAppMessageShown(message: InAppMessage) {
        if message.name.lowercased().contains("stop") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                Exponea.shared.stopIntegration()
            }
        }
    }
    public func inAppMessageError(message: InAppMessage?, errorMessage: String) {}
    public func inAppMessageClickAction(message: InAppMessage, button: InAppMessageButton) {
        if messageIsForGdpr(message) {
            handleGdprUserResponse(button: button)
        }
    }
    public func inAppMessageCloseAction(message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
        if messageIsForGdpr(message), interaction {
            Exponea.shared.stopIntegration()
        }
    }

    private func messageIsForGdpr(_ message: InAppMessage) -> Bool {
        message.name.uppercased().contains("GDPR")
    }

    private func handleGdprUserResponse(button: InAppMessageButton) {
        guard let url = button.url else { return }
        switch url {
        case "https://bloomreach.com/tracking/allow":
            Exponea.shared.trackEvent(
                properties: [
                    "status": "allowed"
                ],
                timestamp: nil,
                eventType: "gdpr"
            )
        case "https://bloomreach.com/tracking/deny":
            Exponea.shared.stopIntegration()
        default:
            break
        }
    }
}
