//
//  AnonymizeViewController.swift
//  Example
//
//  Created by Adam Mihalik on 03/07/2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class AnonymizeViewController: UIViewController {
    @IBAction func anonymizePressed(_ sender: Any) {
        Exponea.shared.anonymize()
        let alert = UIAlertController(
            title: "Anonymize",
            message: "User anonymized",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func stopIntegration(_ sender: Any) {
        let alert = UIAlertController(
            title: "SDK stopped!",
            message: "SDK has been de-integrated from your app. You may return app 'Back to Auth' to re-integrate. You may 'Continue' in using app without initialised SDK.",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "Back to auth", style: .default, handler: { _ in
            DeeplinkManager.manager.setDeeplinkType(type: .stopAndRestart)
        }))
        alert.addAction(.init(title: "Continue", style: .default, handler: { _ in
            DeeplinkManager.manager.setDeeplinkType(type: .stopAndContinue)
        }))
        present(alert, animated: true)
    }
}
