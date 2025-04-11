//
//  FetchViewController.swift
//  Example
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class FetchViewController: UIViewController {

    @IBOutlet var buttonsStack: UIStackView!
    let button = Exponea.shared.getAppInboxButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            self?.button.removeFromSuperview()
            self?.view.layoutIfNeeded()
        }
        self.buttonsStack.addArrangedSubview(button)
        let widthConstraint = button.widthAnchor.constraint(equalToConstant: 48)
        let heightConstraint = button.heightAnchor.constraint(equalToConstant: 48)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint])
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    struct MyRecommendation: RecommendationUserData {
        // put all the custom properties on your recommendations into a struct
        // and call fetchRecommendation with it in results callback
    }

    typealias MyRecommendationResponse = RecommendationResponse<MyRecommendation>

    @IBAction func segment(_ sender: Any) {
        Exponea.shared.getSegments(force: true, category: .content()) { data in
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Segment", message: data.map { segment in
                    "id: \(segment.id), segmentationId: \(segment.segmentationId)\n"
                }.joined(), preferredStyle: .alert)
                alertController.addAction(.init(title: "Ok", style: .default))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    @IBAction func fetchRecommendation(_ sender: Any) {
        let alertController = UIAlertController(title: "Input Recommendation ID", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField: UITextField!) -> Void in
            textField.placeholder = "ID"
        }
        let fetchAction = UIAlertAction(title: "Fetch", style: .default, handler: { _ -> Void in
            let idField = alertController.textFields?[0] as UITextField?
            let options = RecommendationOptions(id: idField?.text ?? "", fillWithRandom: false)
            Exponea.shared.fetchRecommendation(with: options) { (result: Result<MyRecommendationResponse>) in
                switch result {
                case .success(let recommendation):
                    DispatchQueue.main.async {
                        AppDelegate.memoryLogger.logMessage("\(recommendation)")
                        self.showAlert(
                            title: "Fetch Recommendation",
                            message: """
                                Success: \(recommendation.success)
                                Error: \(recommendation.error ?? "")
                                Content: \(recommendation.value ?? [])
                            """
                        )
                    }
                case .failure(let error):
                    AppDelegate.memoryLogger.logMessage(error.localizedDescription)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(cancelAction)
        alertController.addAction(fetchAction)

        present(alertController, animated: true, completion: nil)
    }

    @IBAction func fetchConsents(_ sender: Any) {
        Exponea.shared.fetchConsents { (result) in
            switch result {
            case .success(let response):
                AppDelegate.memoryLogger.logMessage("\(response.consents)")
                self.showAlert(title: "Fetch Consents", message: """
                    \(response.consents)
                    """)
            case .failure(let error):
                AppDelegate.memoryLogger.logMessage(error.localizedDescription)
                self.showAlert(title: "Error", message: "\(error)")
            }
        }
    }
}
