//
//  LogViewController.swift
//  Example
//
//  Created by Dominik Hadl on 29/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class LogViewController: UIViewController {

    @IBOutlet var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.layer.borderColor = UIColor(red: 28/255, green: 23/255, blue: 50/255, alpha: 1.0).cgColor
        textView.layer.borderWidth = 1 / UIScreen.main.scale

        AppDelegate.memoryLogger.delegate = self

        logUpdated()
    }
}

extension LogViewController: MemoryLoggerDelegate {
    func logUpdated() {
        textView.text = AppDelegate.memoryLogger.logs.reversed().joined(separator: "\n\n")
    }
}
