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
}
