//
//  IdentifyCustomerViewController.swift
//  Example
//
//  Created by Dominik Hadl on 07/06/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class IdentifyCustomerViewController: UIViewController {

    @IBOutlet var idKeyField: UITextField!
    @IBOutlet var idValueField: UITextField!

    @IBOutlet var keyField1: UITextField!
    @IBOutlet var valueField1: UITextField!

    @IBOutlet var keyField2: UITextField!
    @IBOutlet var valueField2: UITextField!

    @IBOutlet var keyField3: UITextField!
    @IBOutlet var valueField3: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        idKeyField.placeholder = "registered"
        idValueField.placeholder = "fx. email@address.com"

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
        let ids: [String: String]?
        if let idKey = idKeyField.text, !idKey.isEmpty,
            let idValue = idValueField.text, !idValue.isEmpty {
            ids = [idKey: idValue]
        } else {
            ids = nil
        }

        var properties: [String: String] = [:]

        if let key1 = keyField1.text, !key1.isEmpty {
            properties[key1] = valueField1.text ?? ""
        }

        if let key2 = keyField2.text, !key2.isEmpty {
            properties[key2] = valueField2.text ?? ""
        }

        if let key3 = keyField3.text, !key3.isEmpty {
            properties[key3] = valueField3.text ?? ""
        }

        Exponea.shared.identifyCustomer(customerIds: ids, properties: properties, timestamp: nil)
        dismiss(animated: true, completion: nil)
    }

}
