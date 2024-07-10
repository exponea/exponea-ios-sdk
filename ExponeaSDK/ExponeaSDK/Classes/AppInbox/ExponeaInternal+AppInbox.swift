//
// Created by Adam Mihalik on 05/10/2022.
//

import Foundation
import UIKit

extension ExponeaInternal {

    /// Retrieves Button for opening of AppInbox list
    ///
    public func getAppInboxButton() -> UIButton {
        return appInboxProvider.getAppInboxButton()
    }

    public func getAppInboxListViewController() -> UIViewController {
        return appInboxProvider.getAppInboxListViewController()
    }
    
    public func getAppInboxListViewController(onItemClicked: @escaping (MessageItem, Int) -> Void) -> UIViewController {
        let listController = getAppInboxListViewController()
        if let appInboxListController = listController as? AppInboxListViewController {
            appInboxListController.onItemClickedOverride = onItemClicked
        }
        return listController
    }

    public func getAppInboxDetailViewController(_ messageId: String) -> UIViewController {
        return appInboxProvider.getAppInboxDetailViewController(messageId)
    }

}
