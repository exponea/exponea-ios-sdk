//
//  StyledAppInboxProvider.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import UIKit

public class StyledAppInboxProvider: DefaultAppInboxProvider {
    private let appInboxStyle: AppInboxStyle

    override init() {
        appInboxStyle = AppInboxStyle()
    }

    init(_ style: AppInboxStyle) {
        appInboxStyle = style
    }

    public override func getAppInboxButton() -> UIButton {
        let button = super.getAppInboxButton()
        if let buttonStyle = appInboxStyle.appInboxButton {
            buttonStyle.applyTo(button)
        }
        return button
    }

    public override func getAppInboxListViewController() -> UIViewController {
        let listView = super.getAppInboxListViewController()
        guard let listView = listView as? AppInboxListViewController else {
            Exponea.logger.log(.warning, message: "AppInbox list view impl mismatch - unable to customize")
            return listView
        }
        listView.loadViewIfNeeded()
        if let listViewStyle = appInboxStyle.listView {
            listViewStyle.applyTo(listView)
        }
        return listView
    }

    public override func getAppInboxListTableViewCell(_ cell: UITableViewCell) -> UITableViewCell {
        guard let listViewItem = cell as? MessageItemCell else {
            ExponeaSDK.Exponea.logger.log(.warning, message: "AppInbox list item impl mismatch - unable to customize")
            return cell
        }
        if let listItemViewStyle = appInboxStyle.listView?.list?.item {
            listItemViewStyle.applyTo(listViewItem)
        }
        return listViewItem
    }

    public override func getAppInboxDetailViewController(_ messageId: String) -> UIViewController {
        let detailView = super.getAppInboxDetailViewController(messageId)
        guard let detailView = detailView as? AppInboxDetailViewController else {
            ExponeaSDK.Exponea.logger.log(.warning, message: "AppInbox detail view impl mismatch - unable to customize")
            return detailView
        }
        guard let detailStyle = appInboxStyle.detailView else {
            return detailView
        }
        detailView.loadViewIfNeeded()
        detailStyle.applyTo(detailView)
        return detailView
    }
}
