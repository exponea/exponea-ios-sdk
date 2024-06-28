//
//  DefaultAppInboxProvider.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 14/11/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit

open class DefaultAppInboxProvider: AppInboxProvider {

    public let APPINBOX_BUTTON_ICON_DATA = "iVBORw0KGgoAAAANSUhEUgAAAEUAAABICAMAAACXzcjFAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAJcEhZcwAAITgAACE4AUWWMWAAAAA/UExURUdwTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALoT4l0AAAAUdFJOUwDvMHAgvxDfn0Bgz4BQr5B/j7CgEZfI5wAAAcJJREFUWMPtl9mWhCAMRBtFNlF74f+/dZBwRoNBQftpxnrpPqjXUFRQH49bt74o0ejrEC6dk+IqRTkve5XSzRR1U/4oRRirlHphih9RduDFcQ1J85HFFBh0qozTMLdHcZLXQHKUEszcfQeUAgxAWMu9MMUPNC0U2h1AnunNkpWOpT53IQNUAhCR1AK2waT0sSltdLkXC4V3scIWqhUHQY319/6fx0RK4L9XJ41lpnRg42f+mUS/mMrZUjAhjaYMuXnZcMW4siua55o9UyyOX+iGUJf8vWzasWZcopamOFl9Afd7ZU1hnM4xzmtc7q01nDqwYJLQt9tbrpKvMl216ZyO7ASTaTPAEOOMijBYa+iV64gehjlNeDCkyvUKK1B1WGGTHOqpKTlaGrfpRrKIYvAETlIm9OpwlsIESlMRha3tg0T0YhX5cX08S0FjIt7NaN1K4pIySuzclewZipDHHhSMNTKzM1RR0M6w6YJiis99FxnbJ0cFxbujB9NQe2MVJat/RHEVXw2corCad7Z56eLmSO3pHl6oePobU6w7pWS7F+wMRNJPhkoNG7/q58QMtXYfWTUbK/Lfq4Xilz9Ib926qB8ZxV6DpmAIowAAAABJRU5ErkJggg=="

    public init() { }

    open func getAppInboxButton() -> UIButton {
        let button = UIButton()
        var buttonFrame = button.frame
        buttonFrame.size = CGSize(width: 48, height: 48)
        button.frame = buttonFrame
        button.backgroundColor = UIColor(red: 0.0, green: 122.0, blue: 255.0, alpha: 1.0)
        if let imageData = Data.init(base64Encoded: APPINBOX_BUTTON_ICON_DATA, options: .init(rawValue: 0)),
           let trayDown = UIImage(data: imageData, scale: 3) {
            button.setImage(trayDown, for: .normal)
        }
        button.setTitle(NSLocalizedString(
            "exponea.inbox.button",
            value: "Inbox",
            comment: ""
        ), for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(Exponea.shared, action: #selector(Exponea.shared.openAppInboxList), for: .touchUpInside)
        return button
    }

    open func getAppInboxListViewController() -> UIViewController {
        AppInboxListViewController()
    }

    open func getAppInboxDetailViewController(_ messageId: String) -> UIViewController {
        let detailViewController = AppInboxDetailViewController()
        Exponea.shared.fetchAppInboxItem(messageId) { result in
            switch result {
            case .success(let message):
                detailViewController.withData(message)
            case .failure:
                Exponea.logger.log(.error, message: "AppInbox message not found for ID \(messageId)")
            }
        }
        return detailViewController
    }

    open func getAppInboxListTableViewCell(_ cell: UITableViewCell) -> UITableViewCell {
        cell
    }
}
