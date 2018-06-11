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

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func fetchRecommendation(_ sender: Any) {
        let recomm = RecommendationRequest(type: "", id: "")
        Exponea.shared.fetchRecommendation(with: recomm) { (result) in
            switch result {
            case .success(let recom):
                AppDelegate.memoryLogger.logMessage("\(recom)")
                self.showAlert(title: "Fetch Recommendation", message: """
                    Success: \(recom.success ?? false)
                    Content: \(recom.results ?? [])
                    """)
            case .failure(let error):
                AppDelegate.memoryLogger.logMessage(error.localizedDescription)
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    @IBAction func fetchEvents(_ sender: Any) {
        let alertController = UIAlertController(title: "Input event types",
                                                message: "You can input multiple, comma separated values.",
                                                preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "ID"
        }
        let saveAction = UIAlertAction(title: "Fetch", style: .default, handler: { alert -> Void in
            let idField = alertController.textFields![0] as UITextField
            let req = EventsRequest(eventTypes: [idField.text ?? ""])
            
            DispatchQueue.main.async {
                
                Exponea.shared.fetchEvents(with: req) { (result) in
                    switch result {
                    case .success(let events):
                        AppDelegate.memoryLogger.logMessage("\(events)")
                        self.showAlert(title: "Fetch Events", message: """
                            Success: \(events.success)
                            Content: \(events.data)
                            """)
                    case .failure(let error):
                        AppDelegate.memoryLogger.logMessage(error.localizedDescription)
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func fetchAttributes(_ sender: Any) {
        let alertController = UIAlertController(title: "Fetch Attributes Config", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Key"
        }
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Value"
        }
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Identification Key"
        }
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Identification Value"
        }
        let saveAction = UIAlertAction(title: "Fetch", style: .default, handler: { alert -> Void in
            let keyField = alertController.textFields![0] as UITextField
            let valueField = alertController.textFields![1] as UITextField
            let idKeyField = alertController.textFields![2] as UITextField
            let idValueField = alertController.textFields![3] as UITextField
            let req = AttributesDescription(key: keyField.text ?? "",
                                            value: valueField.text ?? "",
                                            identificationKey: idKeyField.text ?? "",
                                            identificationValue: idValueField.text ?? "")
            
            DispatchQueue.main.async {
                Exponea.shared.fetchAttributes(with: req) { (result) in
                    switch result {
                    case .success(let recom):
                        AppDelegate.memoryLogger.logMessage("\(recom)")
                        self.showAlert(title: "Fetch Attributes", message: """
                            Type: \(recom.type)
                            List: \(recom.list)
                            """)
                    case .failure(let error):
                        AppDelegate.memoryLogger.logMessage(error.localizedDescription)
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func fetchBanners(_ sender: Any) {
        Exponea.shared.fetchBanners { (result) in
            switch result {
            case .success(let banners):
                AppDelegate.memoryLogger.logMessage("\(banners)")
                self.showAlert(title: "Fetch Attributes", message: """
                    \(banners.data)
                    """)
            case .failure(let error):
                AppDelegate.memoryLogger.logMessage(error.localizedDescription)
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func fetchPersonalization(_ sender: Any) {
        let alertController = UIAlertController(title: "Input Banner ID", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "ID"
        }
        let saveAction = UIAlertAction(title: "Fetch", style: .default, handler: { alert -> Void in
            let idField = alertController.textFields![0] as UITextField
            let request = PersonalizationRequest(ids: [idField.text ?? ""])
            
            DispatchQueue.main.async {
                Exponea.shared.fetchPersonalization(with: request, completion: { (result) in
                    switch result {
                    case .success(let personalization):
                        AppDelegate.memoryLogger.logMessage("\(personalization)")
                        self.showAlert(title: "Fetch Personalisation", message: """
                            ID: \(idField.text ?? "")
                            \(personalization)
                            """)
                    case .failure(let error):
                        AppDelegate.memoryLogger.logMessage(error.localizedDescription)
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                })
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
