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
        Exponea.shared.flushData()
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
        self.tabBarController?.dismiss(animated: true, completion: nil)
    }
}
