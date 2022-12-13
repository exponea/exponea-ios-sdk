//
//  ExampleAppInboxProvider.swift
//  Example
//
//  Created by Adam Mihalik on 14/11/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit
import ExponeaSDK

public class ExampleAppInboxProvider: DefaultAppInboxProvider {
    override init() {
        super.init()
    }
    public override func getAppInboxButton() -> UIButton {
        let button = super.getAppInboxButton()
        button.backgroundColor = UIColor(red: 255/255, green: 213/255, blue: 0/255, alpha: 1.0)
        button.layer.cornerRadius = 4
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        return button
    }
    public override func getAppInboxListViewController() -> UIViewController {
        let listController = super.getAppInboxListViewController()
        let typedListController = listController as! AppInboxListViewController
        typedListController.loadViewIfNeeded()
        typedListController.statusTitle.textColor = .red
        return typedListController
    }
    public override func getAppInboxDetailViewController(_ messageId: String) -> UIViewController {
        let detailProvider = super.getAppInboxDetailViewController(messageId)
        let typedDetailProvider = detailProvider as! AppInboxDetailViewController
        typedDetailProvider.loadViewIfNeeded()
        typedDetailProvider.messageTitle.font = .systemFont(ofSize: 32)
        stylizeActionButton(typedDetailProvider.actionMain)
        stylizeActionButton(typedDetailProvider.action1)
        stylizeActionButton(typedDetailProvider.action2)
        stylizeActionButton(typedDetailProvider.action3)
        stylizeActionButton(typedDetailProvider.action4)
        return typedDetailProvider
    }
    private func stylizeActionButton(_ button: UIButton) {
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        button.backgroundColor = UIColor(red: 255/255, green: 213/255, blue: 0/255, alpha: 1.0)
    }
}
