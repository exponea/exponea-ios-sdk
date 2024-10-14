import CoreData
import Foundation
import UIKit
import WebKit

open class AppInboxListViewController: UIViewController {

    public let XMARK_ICON_DATA = "iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAMAAABiM0N1AAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAJcEhZcwAAITgAACE4AUWWMWAAAAA8UExURUdwTCAgICcnJygoKCYmJisrKycnJyYmJigoKCYmJigoKCYmJiYmJicnJycnJyYmJiYmJiUlJScnJyYmJkI9m2kAAAATdFJOUwAQv2DvMN+AIN9Az5+vj1CgYHCbPG4RAAABKklEQVRYw+3YyQ7DIAwE0Owhe9v5/3/tpVUWDIxNDz3EV6MnJMTEpCjuuuu3NdabYnU51qPYcBWAwbFO2wGYS6EzAwqpbQAAq7BTQCF9HDT+lhwU0tcBhMUNL+3OIHRfYKXdQS/1e1JKOayUdjiJcRiJc9IS66Qk3olLGicm6ZywpHVCkt6RJYsjSTbHl6zOVbI7ZynHOUlZzlHKcwTJ6HiS2blIGU5RPHZnzXEO5674msedHOns2KWrY5V8xyYd71efIZ3vqV263ner5OeGTZLyxyLJOaaXQnmolcK5qpNcJFc1kuti+cNLcYeXUg4rpR1OYhxG4py0xDpJabLMmVX4maWcMyPPLN2cWQafWbo5U3pmbZY5sxWPbZmqJ59+ddUt7f1r4q4/rTd0Akh/Hha2MQAAAABJRU5ErkJggg=="

    // MARK: - Properties
    public let statusContainer =  UIStackView()
    public let statusProgress = UIActivityIndicatorView()
    public let statusEmptyTitle = UILabel()
    public let statusEmptyMessage = UILabel()
    public let statusErrorTitle = UILabel()
    public let statusErrorMessage = UILabel()
    public let tableView = UITableView()
    public var onItemClickedOverride: ((MessageItem, Int) -> Void)?

    private var messages: [MessageItem] = [] {
        didSet {
            onMain(self.tableView.reloadData())
        }
    }

    // MARK: - Life-cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        addContent()
        loadMessages()
        convertToDarkIfNeeded()
    }
}

// MARK: - Methods
private extension AppInboxListViewController {
    func convertToDarkIfNeeded() {
        guard Exponea.shared.isDarkMode else { return }
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
            tableView.backgroundColor = .secondarySystemBackground
            statusEmptyTitle.textColor = .label
            statusEmptyMessage.textColor = .secondaryLabel
            statusErrorTitle.textColor = .systemRed
            statusErrorMessage.textColor = .secondaryLabel
        }
    }

    func setupElements() {
        view.backgroundColor = .white
        title = NSLocalizedString("exponea.inbox.title", value: "Inbox", comment: "")
        navigationController?.navigationBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
        if let imageData = Data.init(base64Encoded: XMARK_ICON_DATA, options: .init(rawValue: 0)),
           let xmark = UIImage(data: imageData, scale: 3) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: xmark, style: .plain, target: self, action: #selector(close))
        }
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(
            red: CGFloat(237) / 255,
            green: CGFloat(237) / 255,
            blue: CGFloat(237) / 255,
            alpha: 1
        )
        tableView.separatorInset = .zero
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessageItemCell.self)

        statusContainer.axis = .vertical
        statusContainer.alignment = .center
        statusContainer.distribution = .fillProportionally

        statusProgress.startAnimating()

        statusEmptyTitle.font = .boldSystemFont(ofSize: 20)
        statusEmptyTitle.numberOfLines = 0
        statusEmptyTitle.text = NSLocalizedString("exponea.inbox.emptyTitle", value: "Empty Inbox", comment: "")
        statusEmptyMessage.font = .systemFont(ofSize: 14)
        statusEmptyMessage.numberOfLines = 0
        statusEmptyMessage.text = NSLocalizedString("exponea.inbox.emptyMessage", value: "You have no messages yet.", comment: "")

        statusErrorTitle.font = .boldSystemFont(ofSize: 20)
        statusErrorTitle.numberOfLines = 0
        statusErrorTitle.text = NSLocalizedString("exponea.inbox.errorTitle", value: "Something went wrong :(", comment: "")
        statusErrorMessage.font = .systemFont(ofSize: 14)
        statusErrorMessage.numberOfLines = 0
        statusErrorMessage.text = NSLocalizedString("exponea.inbox.errorMessage", value: "We could not retrieve your messages.", comment: "")
    }

    func addElementsToView() {
        view.addSubviews(tableView, statusContainer)
        [   statusProgress,
            statusEmptyTitle,
            statusEmptyMessage,
            statusErrorTitle,
            statusErrorMessage
        ].forEach(statusContainer.addArrangedSubview(_:))
    }

    func setupLayout() {
        tableView
            .padding()
        statusContainer
            .centerY()
            .padding(horizontalConstant: 20)
            .spacing = 8
    }

    func addContent() {
        defer { setupLayout() }
        setupElements()
        addElementsToView()
    }

    func loadMessages() {
        showLoading()
        Exponea.shared.fetchAppInbox { [weak self] result in
            guard let self = self else { return }
            self.stopLoading()
            switch result {
            case let .success(messages):
                guard !messages.isEmpty else {
                    Exponea.logger.log(.verbose, message: "App inbox loaded but is empty")
                    self.showEmptyState()
                    return
                }
                Exponea.logger.log(.verbose, message: "App inbox loaded")
                self.withData(messages)
            case .failure(let error):
                Exponea.logger.log(.verbose, message: "App inbox load failed due error \"\(error.localizedDescription)\"")
                self.showErrorState()
            }
        }
    }

    func showLoading() {
        statusContainer.isHidden = false
        statusProgress.isHidden = false
        statusEmptyTitle.isHidden = true
        statusEmptyMessage.isHidden = true
        statusErrorTitle.isHidden = true
        statusErrorMessage.isHidden = true
        tableView.isHidden = true
    }

    func stopLoading() {
        statusContainer.isHidden = true
        tableView.isHidden = false
    }

    func showEmptyState() {
        statusContainer.isHidden = false
        statusProgress.isHidden = true
        statusEmptyTitle.isHidden = false
        statusEmptyMessage.isHidden = false
        statusErrorTitle.isHidden = true
        statusErrorMessage.isHidden = true
        tableView.isHidden = true
    }

    func showErrorState() {
        statusContainer.isHidden = false
        statusProgress.isHidden = true
        statusEmptyTitle.isHidden = true
        statusEmptyMessage.isHidden = true
        statusErrorTitle.isHidden = false
        statusErrorMessage.isHidden = false
        tableView.isHidden = true
    }

    @objc func close() {
        navigationController?.presentingViewController?.dismiss(animated: true)
    }

    private func onMessageItemClicked(_ message: MessageItem, _ index: Int) {
        let detailView = Exponea.shared.getAppInboxDetailViewController(message.id)
        Exponea.shared.trackAppInboxOpened(message: message)
        navigationController?.pushViewController(detailView, animated: true)
    }

    internal func withData(_ messages: [MessageItem]) {
        self.messages = messages
    }
}

// MARK: - UITableViewDataSource
extension AppInboxListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MessageItemCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        if let message = messages[safeIndex: indexPath.row] {
            cell.showData(message)
        }
        return Exponea.shared.appInboxProvider.getAppInboxListTableViewCell(cell)
    }
}

// MARK: - UITableViewDelegate
extension AppInboxListViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let message = messages[safeIndex: indexPath.row] else { return }
        Exponea.shared.markAppInboxAsRead(message) { [weak self] marked in
            guard let self = self else { return }
            guard marked else { return }
            self.messages[indexPath.row].read = true
            self.tableView.reloadData()
        }
        (onItemClickedOverride ?? onMessageItemClicked)(message, indexPath.row)
    }
}
