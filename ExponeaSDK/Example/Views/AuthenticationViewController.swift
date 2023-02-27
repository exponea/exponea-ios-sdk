//
//  ViewController.swift
//  Example
//
//  Created by Dominik Hadl on 01/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class AuthenticationViewController: UIViewController {

    @IBOutlet weak var tokenField: UITextField! {
        didSet {
            tokenField.delegate = self
            tokenField.addTarget(self, action: #selector(tokenUpdated), for: .editingChanged)

            // load cached
            tokenField.text = UserDefaults.standard.string(forKey: "savedToken") ?? "2c869bfe-90c9-11ed-886a-8a4fe782ab61"
        }
    }
    @IBOutlet weak var authField: UITextField! {
        didSet {
            authField.delegate = self
            // load cached
            authField.text = UserDefaults.standard.string(forKey: "savedAuth") ?? "rini57s5uwrrxl4nrw8s5hfwa3mrphefm6vdtvdwzayfg2dy8j5i0wq41bs5t89r"
        }
    }
    @IBOutlet var advancedPublicKeyField: UITextField! {
        didSet {
            advancedPublicKeyField.delegate = self
            // load cached
            advancedPublicKeyField.text = UserDefaults.standard.string(forKey: "savedAdvancedAuth") ?? "7x89k27lzclzivn9pqhbi27dcb2z38godezn5y9p4xszceipt9213sz5t3irig6f"
        }
    }

    @IBOutlet weak var urlField: UITextField! {
        didSet {
            urlField.delegate = self
            // load cached
            urlField.text = UserDefaults.standard.string(forKey: "savedUrl") ?? "https://at1.api.exponea.dev"
        }
    }
    @IBOutlet weak var startButton: UIButton!

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

        performSegue(withIdentifier: "showMain", sender: nil)

        // Prepare Example Advanced Auth
        CustomerTokenStorage.shared.configure(
            host: baseUrl,
            projectToken: token,
            publicKey: advancedAuthPubKey,
            expiration: nil
        )

        Exponea.shared.checkPushSetup = true
        Exponea.shared.configure(
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
        // Uncomment if you want to test in-app message delegate
        // Exponea.shared.inAppMessagesDelegate = InAppDelegate(overrideDefaultBehavior: true, trackActions: false)
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
