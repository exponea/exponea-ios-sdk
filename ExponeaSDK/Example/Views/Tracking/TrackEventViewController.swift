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
    
    private let DEFAULT_EVENT_TYPE = "event_name"
    private let DEFAULT_PROP_KEY = "property"

    @IBOutlet var eventTypeField: UITextField!

    @IBOutlet var keyField1: UITextField!
    @IBOutlet var valueField1: UITextField!

    @IBOutlet var keyField2: UITextField!
    @IBOutlet var valueField2: UITextField!

    @IBOutlet var keyField3: UITextField!
    @IBOutlet var valueField3: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        eventTypeField.placeholder = "default = \"\(DEFAULT_EVENT_TYPE)\""
        keyField1.placeholder = "default = \"\(DEFAULT_PROP_KEY)\""
        keyField2.placeholder = "custom_key_2"
        keyField3.placeholder = "custom_key_3"
        
        SegmentationManager.shared.addCallback(
            callbackData: .init(
                category: .discovery(),
                isIncludeFirstLoad: true,
                onNewData: { segments in
            print(segments)
        }))
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
            return DEFAULT_EVENT_TYPE
        }()

        var properties: [String: JSONConvertible] = [:]

        if let value1 = valueField1.text, !value1.isEmpty {
            var key1 = keyField1.text ?? DEFAULT_PROP_KEY
            if key1.isEmpty {
                key1 = DEFAULT_PROP_KEY
            }
            properties[key1] = value1
        }

        if let key2 = keyField2.text, !key2.isEmpty {
            properties[key2] = valueField2.text ?? ""
        }

        if let key3 = keyField3.text, !key3.isEmpty {
            properties[key3] = valueField3.text ?? ""
        }

        properties["testdictionary"] = ["key1": "value1", "key2": 2, "key3": true]
        properties["testarray"] = [123, "test", false]
        properties["infinityNumber"] = Double.infinity
        properties["infinityNumberInArray"] = [123, "test", false, Double.infinity]
        properties["infinityNumberInMap"] = ["key1": "value1", "key2": 2, "key3": true, "key4": Double.infinity]

        Exponea.shared.trackEvent(properties: properties, timestamp: nil, eventType: eventType)
        dismiss(animated: true, completion: nil)
    }
}
