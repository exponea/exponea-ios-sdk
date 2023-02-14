import Foundation
import UIKit
import WebKit
import CoreData

open class AppInboxListViewController: UIViewController, UITableViewDelegate {

    @IBOutlet public var statusContainer: UIStackView!
    @IBOutlet public var statusProgress: UIActivityIndicatorView!
    @IBOutlet public var statusTitle: UILabel!
    @IBOutlet public var statusMessage: UILabel!

    @IBOutlet public var tableView: UITableView!

//    private var dataSourceDelegate = AppInboxDataSource(of: [])
    
    var messages: [MessageItem] = []
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString(
            "exponea.inbox.title",
            value: "Inbox",
            comment: ""
        )
        navigationController?.navigationBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: AppInboxListViewController.self)
        #endif
        #if compiler(>=5)
        let xmark = UIImage(named: "xmark",
                            in: bundle,
                            compatibleWith: nil)
        #else
        let xmark = UIImage(named: "xmark",
                            inBundle: bundle,
                            compatibleWithTraitCollection: nil)
        #endif
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: xmark, style: .plain, target: self, action: #selector(dismissMe))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        showLoading()
        Exponea.shared.fetchAppInbox { result in
            switch result {
            case .success(let messages):
                if messages.isEmpty {
                    Exponea.logger.log(.verbose, message: "App inbox loaded but is empty")
                    self.showEmptyState()
                    self.tableView.reloadData()
                    return
                }
                Exponea.logger.log(.verbose, message: "App inbox loaded")
                self.messages = messages
                self.stopLoading()
                self.tableView.reloadData()
            case .failure(let error):
                Exponea.logger.log(.verbose, message: "App inbox load failed due error \"\(error.localizedDescription)\"")
                self.showErrorState()
            }
        }
    }

    private func showLoading() {
        statusContainer.isHidden = false
        statusProgress.isHidden = false
        statusTitle.isHidden = true
        statusMessage.isHidden = false
        statusMessage.text = NSLocalizedString(
            "exponea.inbox.loading",
            value: "Loading messages...",
            comment: ""
        )
        tableView.isHidden = true
    }

    private func stopLoading() {
        statusContainer.isHidden = true
        tableView.isHidden = false
    }

    private func showEmptyState() {
        statusContainer.isHidden = false
        statusProgress.isHidden = true
        statusTitle.isHidden = false
        statusMessage.isHidden = false
        statusTitle.text = NSLocalizedString(
            "exponea.inbox.emptyTitle",
            value: "Empty Inbox",
            comment: "")
        statusMessage.text = NSLocalizedString(
            "exponea.inbox.emptyMessage",
            value: "You have no messages yet.",
            comment: "")
        tableView.isHidden = true
    }

    private func showErrorState() {
        statusContainer.isHidden = false
        statusProgress.isHidden = true
        statusTitle.isHidden = false
        statusMessage.isHidden = false
        statusTitle.text = NSLocalizedString(
            "exponea.inbox.errorTitle",
            value: "Something went wrong :(",
            comment: ""
        )
        statusMessage.text = NSLocalizedString(
            "exponea.inbox.errorMessage",
            value: "We could not retrieve your messages.",
            comment: ""
        )
        tableView.isHidden = true
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.item]
        Exponea.shared.markAppInboxAsRead(message) { marked in
            guard marked else {
                return
            }
            self.messages[indexPath.item].read = true
            self.tableView.reloadData()
        }
        let detailView = Exponea.shared.getAppInboxDetailViewController(message.id)
        Exponea.shared.trackAppInboxOpened(message: message)
        navigationController?.pushViewController(detailView, animated: true)
    }

    @objc private func dismissMe() {
        navigationController?.presentingViewController?.dismiss(animated: true)
    }
}

extension AppInboxListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell_wrapper") as! MessageItemCell
        populateCell(cell, indexPath.row)
        return cell
    }
    private func populateCell(_ cell: MessageItemCell, _ index: Int) {
        let item = messages[index]
        cell.showData(item)
    }
}
