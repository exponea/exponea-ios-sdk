//
//  AppInboxDetailViewController.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 10/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit
import WebKit

open class AppInboxDetailViewController: UIViewController, WKUIDelegate {

    // MARK: - Properties
    public let pushContainer = UIScrollView()
    public let messageImage = UIImageView()
    public let receivedTime = UILabel()
    public let messageTitle = UILabel()
    public let message = UILabel()
    public let actionsContainer = UIStackView()
    public let actionMain = UIButton()
    public let action1 = UIButton()
    public let action2 = UIButton()
    public let action3 = UIButton()
    public let action4 = UIButton()
    public let htmlContainer = WKWebView()

    private let SUPPORTED_MESSAGE_ACTION_TYPES: [MessageItemActionType] = [
        .deeplink, .browser
    ]

    private let SUPPORTED_MESSAGE_TYPES: [String] = [
        "push", "html"
    ]

    private let urlOpener: UrlOpenerType = UrlOpener()
    private var data: MessageItem?
    private var mainAction: MessageItemAction?
    private var shownActions: [MessageItemAction]?
    private var normalizedPayload: NormalizedResult?
    private var actionManager: WebActionManager?

    open func withData(_ source: MessageItem) {
        self.data = source
        self.mainAction = readMainAction(source)
        let actions = source.content?.actions ?? []
        self.shownActions = actions.filter { action in
            return SUPPORTED_MESSAGE_ACTION_TYPES.contains(action.type)
        }
        loadViewIfNeeded()
        applyDataToView()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        addContent()
        hideContainers()
        actionManager = WebActionManager(
            onActionCallback: { [weak self] action in
                guard let self = self,
                      let message = self.data else {
                    Exponea.logger.log(.error, message: "AppInbox action \(action.actionUrl) called but no action or message is provided")
                    return
                }
                self.invokeActionInternally(
                    MessageItemAction(
                        action: self.determineActionType(action).rawValue,
                        title: action.buttonText,
                        url: action.actionUrl
                    ),
                    message
                )
            }
        )
        navigationController?.navigationBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
        applyDataToView()
    }

    private func determineActionType(_ action: ActionInfo) -> MessageItemActionType {
        if action.actionUrl.hasPrefix("http://") || action.actionUrl.hasPrefix("https://") {
            return .browser
        } else {
            return .deeplink
        }
    }

    private func readMainAction(_ source: MessageItem) -> MessageItemAction? {
        guard let mainActionTypeRaw = source.content?.action?.action,
              let mainActionType = MessageItemActionType(rawValue: mainActionTypeRaw),
              let mainActionUrl = source.content?.action?.url else {
            return nil
        }
        if SUPPORTED_MESSAGE_ACTION_TYPES.contains(mainActionType) {
            return MessageItemAction(
                action: mainActionTypeRaw,
                title: NSLocalizedString(
                    "exponea.inbox.mainActionTitle",
                    value: "See more",
                    comment: ""
                ),
                url: mainActionUrl
            )
        }
        return nil
    }

    private func applyDataToView() {
        guard
            let dataType = data?.type,
            SUPPORTED_MESSAGE_TYPES.contains(dataType) else {
            Exponea.logger.log(.warning, message: "Unsupported AppInbox type \(data?.type ?? "nil") to be shown")
            return
        }
        hideContainers()
        switch dataType {
        case "html":
            showHtmlMessage()
        case "push":
            showPushMessage()
        default:
            Exponea.logger.log(.error, message: "Unsupported AppInbox type \(dataType) to be shown")
            return
        }
    }

    private func hideContainers() {
        pushContainer.isHidden = true
        htmlContainer.isHidden = true
    }

    private func showPushMessage() {
        pushContainer.isHidden = false
        title = data?.content?.title ?? NSLocalizedString(
            "exponea.inbox.defaultTitle",
            value: "Message",
            comment: ""
        )
        receivedTime.text = translateReceivedTime(data?.receivedTime ?? Date())
        messageTitle.attributedText = asAttributedText(
            data?.content?.title ?? "", kern: 0.25, lineHeightMultiplier: CGFloat(1.01)
        )
        message.attributedText = asAttributedText(
            data?.content?.message ?? "", kern: 0.25, lineHeightMultiplier: CGFloat(1.2)
        )
        setupActionButtons(data)
        if let imageUrl = data?.content?.imageUrl {
            DispatchQueue.global(qos: .background).async {
                guard let imageSource = ImageUtils.tryDownloadImage(imageUrl),
                      let image = ImageUtils.createImage(imageData: imageSource, maxDimensionInPixels: Int(UIScreen.main.bounds.width)) else {
                    Exponea.logger.log(.error, message: "Image cannot be shown")
                    return
                }
                DispatchQueue.main.async {
                    self.messageImage.image = image
                }
            }
        }
    }

    private func asAttributedText(
        _ text: String?,
        kern: NSNumber? = nil,
        lineHeightMultiplier: CGFloat? = nil
    ) -> NSAttributedString? {
        guard let text = text else {
            return nil
        }
        var attrs: [NSAttributedString.Key: Any] = [:]
        if let kern = kern {
            attrs[NSAttributedString.Key.kern] = kern
        }
        if let lineHeightMultiplier = lineHeightMultiplier {
            var paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = lineHeightMultiplier
            attrs[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        }
        return NSMutableAttributedString(string: text, attributes: attrs)
    }

    private func showHtmlMessage() {
        htmlContainer.isHidden = false
        htmlContainer.navigationDelegate = self.actionManager
        htmlContainer.uiDelegate = self
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let selfWhileAsync = self else {
                Exponea.logger.log(.error, message: "Showing a HTML AppInbox stops")
                return
            }
            let normalizeConf = HtmlNormalizerConfig(
                makeImagesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: true
            )
            let normalizedPayload = HtmlNormalizer(selfWhileAsync.data?.content?.html ?? "").normalize(normalizeConf)
            guard
                normalizedPayload.valid
            else {
                Exponea.logger.log(.error, message: "AppInbox message contains invalid HTML")
                return
            }
            selfWhileAsync.normalizedPayload = normalizedPayload
            selfWhileAsync.actionManager?.htmlPayload = normalizedPayload
            DispatchQueue.main.async { [weak selfWhileAsync] in
                guard
                    let selfWhileMain = selfWhileAsync,
                    let normalizedHtml = selfWhileMain.normalizedPayload?.html
                else {
                    Exponea.logger.log(.error, message: "Showing a HTML AppInbox stops")
                    return
                }
                selfWhileMain.htmlContainer.loadHTMLString(normalizedHtml, baseURL: nil)
            }
        }
    }

    @objc func invokeMainAction() {
        guard let action = mainAction,
            let message = data else {
                Exponea.logger.log(.error, message: "AppInbox main action called but no action or message is provided")
                return
        }
        invokeActionInternally(action, message)
    }

    @objc func invokeActionForIndex(_ sender: UIButton) {
        let action = getActionByIndex(sender.tag)
        guard let action = action,
            let message = data else {
                Exponea.logger.log(.error, message: "AppInbox action \(index) called but no action or message is provided")
                return
        }
        invokeActionInternally(action, message)
    }

    private func invokeActionInternally(_ action: MessageItemAction, _ message: MessageItem) {
        Exponea.shared.trackAppInboxClick(action: action, message: message)
        switch action.type {
        case .browser:
            openBrowserAction(action)
        case .deeplink:
            openDeeplinkAction(action)
        default:
            Exponea.logger.log(.warning, message: "No AppInbox action for type \(action.type.rawValue)")
        }
    }

    func openBrowserAction(_ action: MessageItemAction) {
        guard let buttonLink = action.url else {
            Exponea.logger.log(.error, message: "AppInbox action \"\(action.title ?? "<nil>")\" contains invalid browser link \(action.url ?? "<nil>")")
            return
        }
        urlOpener.openBrowserLink(buttonLink)
    }

    func openDeeplinkAction(_ action: MessageItemAction) {
        guard let buttonLink = action.url else {
            Exponea.logger.log(.error, message: "AppInbox action \"\(action.title ?? "<nil>")\" contains invalid universal link \(action.url ?? "<nil>")")
            return
        }
        urlOpener.openDeeplink(buttonLink)
    }

    func setupActionButtons(_ source: MessageItem?) {
        setupMainActionButton(actionMain)
        setupActionButton(action1, 0)
        setupActionButton(action2, 1)
        setupActionButton(action3, 2)
        setupActionButton(action4, 3)
    }

    func setupMainActionButton(_ target: UIButton) {
        setupActionButton(target, self.mainAction)
    }

    func setupActionButton(_ target: UIButton, _ index: Int) {
        let action = getActionByIndex(index)
        setupActionButton(target, action)
    }

    func setupActionButton(_ target: UIButton, _ action: MessageItemAction?) {
        guard let action = action else {
            // no action for index -> no button
            target.isHidden = true
            return
        }
        target.isHidden = false
        target.setTitle(action.title, for: .normal)
    }

    func getActionByIndex(_ index: Int) -> MessageItemAction? {
        return shownActions?.indices.contains(index) == true ? shownActions![index] : nil
    }

    open func translateReceivedTime(_ source: Date) -> String {
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: source, relativeTo: Date())
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .long
            formatter.dateStyle = .long
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: source)
        }
    }
}

// MARK: - Methods
private extension AppInboxDetailViewController {
    func setupElements() {
        view.backgroundColor = .white
        messageImage.contentMode = .scaleAspectFill
        messageImage.backgroundColor = UIColor(
            red: CGFloat(245) / 255,
            green: CGFloat(245) / 255,
            blue: CGFloat(245) / 255,
            alpha: 1.0
        )
        receivedTime.font = .systemFont(ofSize: 12, weight: .regular)
        receivedTime.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        messageTitle.font = .systemFont(ofSize: 20, weight: .semibold)
        messageTitle.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        messageTitle.numberOfLines = 0
        message.font = .systemFont(ofSize: 14, weight: .regular)
        message.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        message.numberOfLines = 0
        action1.tag = 0
        action2.tag = 1
        action3.tag = 2
        action4.tag = 3
        [actionMain, action1, action2, action3, action4].forEach { button in
            button.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
            button.layer.cornerRadius = 10
            button.setTitleColor(UIColor(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
            button.clipsToBounds = true
        }
        setupActions()

        actionsContainer.axis = .vertical
        actionsContainer.spacing = 8
    }

    func addElementsToView() {
        view.addSubviews(htmlContainer, pushContainer)
        [actionMain, action1, action2, action3, action4].forEach(actionsContainer.addArrangedSubview(_:))
        pushContainer.addSubviews(
            messageImage,
            receivedTime,
            messageTitle,
            message,
            actionsContainer
        )
    }

    func setupLayout() {
        htmlContainer
            .padding()
        pushContainer
            .padding()
        messageImage
            .padding(.leading, .top, .trailing, constant: 0)
            .frame(width: view.frame.size.width, height: view.frame.size.width)
        receivedTime
            .padding(messageImage, .top, constant: 16)
            .padding(.leading, .trailing, constant: 16)
        messageTitle
            .padding(receivedTime, .top, constant: 8)
            .padding(.leading, .trailing, constant: 16)
        message
            .padding(messageTitle, .top, constant: 8)
            .padding(.leading, .trailing, constant: 16)
        actionsContainer
            .padding(message, .top, constant: 16)
            .padding(.leading, .trailing, constant: 16)
            .padding(pushContainer, .top, constant: 0)
            .padding(.bottom, constant: 16)
        [actionMain, action1, action2, action3, action4].forEach { button in
            button.frame(height: 48)
        }
    }

    func addContent() {
        defer { setupLayout() }
        setupElements()
        addElementsToView()
    }

    func setupActions() {
        actionMain.addTarget(self, action: #selector(invokeMainAction), for: .primaryActionTriggered)
        action1.addTarget(self, action: #selector(invokeActionForIndex), for: .primaryActionTriggered)
        action2.addTarget(self, action: #selector(invokeActionForIndex), for: .primaryActionTriggered)
        action3.addTarget(self, action: #selector(invokeActionForIndex), for: .primaryActionTriggered)
        action4.addTarget(self, action: #selector(invokeActionForIndex), for: .primaryActionTriggered)
    }
}
