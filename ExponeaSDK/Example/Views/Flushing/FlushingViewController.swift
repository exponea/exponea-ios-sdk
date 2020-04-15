//
//  FlushingViewController.swift
//  Example
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class FlushingViewController: UIViewController {

    @IBAction func flushData(_ sender: Any) {
        Exponea.shared.flushData { result in
            var message = ""
            switch result {
            case .error(let error): message = "Error while flushing: \(error.localizedDescription)"
            case .success(let count): message = "Flush done, \(count) objects flushed."
            case .flushAlreadyInProgress: message = "Flush already in progress."
            case .noInternetConnection: message = "No internet connection."
            }
            let alert = UIAlertController(
                title: "Flush result",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func logoutPressed(_ sender: Any) {
        self.tabBarController?.dismiss(animated: true, completion: nil)
    }

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
