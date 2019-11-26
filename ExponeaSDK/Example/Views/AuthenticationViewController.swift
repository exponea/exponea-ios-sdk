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
            tokenField.text = UserDefaults.standard.string(forKey: "savedToken")
        }
    }
    @IBOutlet weak var authField: UITextField! {
        didSet {
            authField.delegate = self
            // load cached
            authField.text = UserDefaults.standard.string(forKey: "savedAuth")
        }
    }

    @IBOutlet weak var urlField: UITextField! {
        didSet {
            urlField.delegate = self
            // load cached
            urlField.text = UserDefaults.standard.string(forKey: "savedUrl") ?? "https://api.exponea.com"
        }
    }
    @IBOutlet weak var startButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        tokenUpdated()
    }

    @IBAction func startPressed() {
        guard let token = tokenField.text else {
            return
        }

        var auth: ExponeaSDK.Authorization = .none

        if let text = authField.text, !text.isEmpty {
            auth = .token(text)
        }

        Exponea.shared.configure(
            Exponea.ProjectSettings(
                projectToken: token,
                authorization: auth,
                baseUrl: urlField.text?.isEmpty == true ? nil : urlField.text
            ),
            automaticPushNotificationTracking: .enabled(
                appGroup: "group.com.Exponea.ExponeaSDK-Example",
                delegate: UIApplication.shared.delegate as? AppDelegate
            ),
            defaultProperties: [
                "Property01": "String value",
                "Property02": 123
            ]
        )

        performSegue(withIdentifier: "showMain", sender: nil)
    }

    @objc func tokenUpdated() {
        startButton.isEnabled = (tokenField.text ?? "").count > 0
        startButton.alpha = startButton.isEnabled ? 1.0 : 0.4
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
