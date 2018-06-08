//
//  TrackEventViewController.swift
//  Example
//
//  Created by Dominik Hadl on 07/06/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class TrackEventViewController: UIViewController {
    
    @IBOutlet var eventTypeField: UITextField!
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventTypeField.placeholder = "default = \"custom_event\""
        
        textView.text = """
        {
        "my_property_1" : "my value",
        "info" : "some other info"
        }
        """
    }
    
    @IBAction func trackPressed(_ sender: Any) {
        let eventType = eventTypeField.text ?? "custom_event"
        let textData = textView.text.data(using: .utf8)!
        
        do {
            let object = try JSONSerialization.jsonObject(with: textData, options: [])
            print(object)
            
            let dict = object as? [String: Any]
            print(dict)
            
            guard let conv = dict as? [String: JSONConvertible] else {
                print("not convertible")
                return
            }
        
            Exponea.shared.trackEvent(properties: conv, timestamp: nil, eventType: eventType)
            dismiss(animated: true, completion: nil)
        } catch {
            print("Error \(error.localizedDescription)")
        }
    }

//    Exponea.shared.trackEvent(properties: [
//    "my_property_1" : "my property 1 value",
//    "info" : "test from exponea SDK sample app",
//    "some_number" : 5
//    ], timestamp: nil, eventType: "my_custom_event_type")

}
