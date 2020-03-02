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

    @IBOutlet var keyField1: UITextField!
    @IBOutlet var valueField1: UITextField!

    @IBOutlet var keyField2: UITextField!
    @IBOutlet var valueField2: UITextField!

    @IBOutlet var keyField3: UITextField!
    @IBOutlet var valueField3: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        eventTypeField.placeholder = "default = \"custom_event\""
        keyField1.placeholder = "custom_key_1"
        keyField2.placeholder = "custom_key_2"
        keyField3.placeholder = "custom_key_3"
    }

    @IBAction func hideKeyboard() {
        view.endEditing(true)
    }

    @IBAction func cancelPressed() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func trackPressed(_ sender: Any) {
        let eventType: String = {
            if let text = eventTypeField.text, !text.isEmpty {
                return text
            }
            return "custom_event"
        }()

        var properties: [String: JSONConvertible] = [:]

        if let key1 = keyField1.text, !key1.isEmpty {
            properties[key1] = valueField1.text ?? ""
        }

        if let key2 = keyField2.text, !key2.isEmpty {
            properties[key2] = valueField2.text ?? ""
        }

        if let key3 = keyField3.text, !key3.isEmpty {
            properties[key3] = valueField3.text ?? ""
        }

        properties["testdictionary"] = ["key1": "value1", "key2": 2, "key3": true]
        properties["testarray"] = [123, "test", false]

        Exponea.shared.trackEvent(properties: properties, timestamp: nil, eventType: eventType)
        dismiss(animated: true, completion: nil)
    }
}
