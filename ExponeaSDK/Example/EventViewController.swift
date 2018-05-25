//
//  EventViewController.swift
//  Example
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class EventViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = ""
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func recommendationPressed(_ sender: Any) {
        let recomm = CustomerRecommendation(type: "", id: "", size: nil,
                                            strategy: nil, knowItems: nil, anti: nil, items: nil)
        Exponea.fetchRecommendation(
            projectToken: Exponea.shared.configuration!.projectToken!,
            customerId: [:],
            recommendation: recomm) { (result) in
                switch result {
                case .success(let recom):
                    self.textView.text = "\(recom)"
                case .failure(let error):
                    self.textView.text = error.localizedDescription
                }
        }
    }
    
    @IBAction func personalisationPressed(_ sender: Any) {
        let req = FetchEventsRequest(eventTypes: ["my_custom_event_type"])
        Exponea.fetchCustomerEvents(
            projectToken: Exponea.shared.configuration!.projectToken!,
            customerId: [:],
            events: req) { (result) in
                switch result {
                case .success(let recom):
                    self.textView.text = "\(recom)"
                case .failure(let error):
                    self.textView.text = error.localizedDescription
                }
        }
    }
    
    @IBAction func attributesPressed(_ sender: Any) {
        let req = FetchEventsRequest(eventTypes: ["my_custom_event_type"])
        Exponea.fetchCustomerEvents(
            projectToken: Exponea.shared.configuration!.projectToken!,
            customerId: [:],
            events: req) { (result) in
                switch result {
                case .success(let recom):
                    self.textView.text = "\(recom)"
                case .failure(let error):
                    self.textView.text = error.localizedDescription
                }
        }
    }
    
    @IBAction func eventsPressed(_ sender: Any) {
        let req = FetchEventsRequest(eventTypes: ["my_custom_event_type"])
        Exponea.fetchCustomerEvents(
            projectToken: Exponea.shared.configuration!.projectToken!,
            customerId: [:],
            events: req) { (result) in
                switch result {
                case .success(let recom):
                    self.textView.text = "\(recom)"
                case .failure(let error):
                    self.textView.text = error.localizedDescription
                }
        }
    }
    
    @IBAction func customerPressed(_ sender: Any) {
        
    }
}
