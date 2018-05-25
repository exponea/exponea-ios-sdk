//
//  ViewController.swift
//  Example
//
//  Created by Dominik Hadl on 01/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class AuthenticationViewController: UIViewController {
    
    @IBOutlet weak var tokenField: UITextField! {
        didSet {
            tokenField.addTarget(self, action: #selector(tokenUpdated), for: .editingChanged)
        }
    }
    @IBOutlet weak var authField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tokenUpdated()
    }

    @IBAction func startPressed() {
        guard let token = tokenField.text else {
            return
        }
        
        var auth: ExponeaSDK.Authorization = .none
        
        if let text = authField.text {
            auth = .basic(text)
        }
        
        Exponea.configure(projectToken: token, authorization: auth)
        Exponea.shared.flushingMode = .manual
        
        performSegue(withIdentifier: "showMain", sender: nil)
    }
    
    @IBAction func prefillPressed() {
        tokenField.text = "0aef3a96-3804-11e8-b710-141877340e97"
        authField.text = "enN5dTh1bnBreG80dXE0OTVhZWc4Y2E2MzdtbTF1Y3NmeXRram1sdDd4bzBjeXh1bnU5eWpiYjU3MHE1aGlsdDpkN2w3aGEzNGV6cWNjMmRzbnV3Zm9tZnl3ZTU1a2J0NHRhNG1pcjhsanYwbHhuZHFiODk2eGoxaGJnN3A5b2p0"
        tokenUpdated()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func tokenUpdated() {
        startButton.isEnabled = (tokenField.text ?? "").count > 0
        startButton.alpha = startButton.isEnabled ? 1.0 : 0.4
    }
}

