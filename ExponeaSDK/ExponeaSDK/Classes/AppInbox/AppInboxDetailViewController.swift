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
    public var messageImage: UIImageView { animatedMessageImage }
    let animatedMessageImage = AppInboxDetailImageView()
    public let receivedTime = UILabel()
    public let messageTitle = UILabel()
    public let message = UILabel()
    public let actionsContainer = UIStackView()
    public let actionMain = UIButton()
    public let action1 = UIButton()
    public let action2 = UIButton()
    public let action3 = UIButton()
    public let action4 = UIButton()
    public let htmlContainer = WKWebView(frame: .zero, configuration: HtmlNormalizer.createWebViewConfiguration())

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
    private var inAppContentBlocksManager: InAppContentBlocksManagerType? = Exponea.shared.inAppContentBlocksManager
    private(set) var messageImageHeightConstraint: NSLayoutConstraint?
    // nil when the image view is collapsed
    private var messageImageAspectRatio: CGFloat?
    // set while the screen is hidden and the image has been released to save memory
    private var messageImageReleased = false
    // keeps the image view's height while a released image is loaded again, so the content doesn't jump
    private var keepsMessageImageHeight = false
    // number of message image loads whose result hasn't been handled yet
    private var pendingMessageImageLoads = 0
    /// True while the message image is being loaded and its result hasn't been handled yet.
    var isLoadingMessageImage: Bool { pendingMessageImageLoads > 0 }

    open func withData(_ source: MessageItem) {
        if let previous = data, previous.id != source.id {
            // an image set by the integrator belongs to the previous message
            animatedMessageImage.resetCustomImage()
        }
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
        convertToDarkIfNeeded()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // the image is released in viewDidDisappear, load it again when returning to this screen
        guard messageImageReleased else { return }
        messageImageReleased = false
        if data?.type == "push" {
            loadMessageImage()
        } else {
            keepsMessageImageHeight = false
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // decoded images can be large, don't keep them while the screen is hidden.
        // An image set by the integrator is kept, the SDK can't load it again.
        guard !animatedMessageImage.hasCustomImage else { return }
        keepsMessageImageHeight = animatedMessageImage.image != nil
        messageImageReleased = true
        animatedMessageImage.clear()
    }

    private func determineActionType(_ action: ActionInfo) -> MessageItemActionType {
        switch action.actionType {
        case .browser:
            return .browser
        case .deeplink:
            return .deeplink
        case .close:
            return .noAction
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
        loadMessageImage()
    }

    /// Loads the message image. Visibility stays under the control of styles and integrators,
    /// a missing image collapses the image view through its height constraint.
    /// An image set directly on `messageImage` is never replaced.
    private func loadMessageImage() {
        guard !animatedMessageImage.hasCustomImage else { return }
        guard let imageUrl = data?.content?.imageUrl else {
            keepsMessageImageHeight = false
            animatedMessageImage.clear()
            return
        }
        pendingMessageImageLoads += 1
        // only weak references off the main queue, so the controller is never released from the background;
        // not .background, which can be starved for seconds on a busy device while the user waits for the image
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let imageData = AppInboxCache.shared.tryGetImageData(at: imageUrl)
            if imageData == nil {
                Exponea.logger.log(.error, message: "Image cannot be shown correctly")
            }
            onMain {
                guard let self else { return }
                self.pendingMessageImageLoads -= 1
                // a result arriving while the screen is hidden is dropped, viewWillAppear loads it again
                guard !self.animatedMessageImage.hasCustomImage, !self.messageImageReleased else { return }
                self.keepsMessageImageHeight = false
                if let imageData {
                    self.animatedMessageImage.loadImage(imageData: imageData)
                } else {
                    self.animatedMessageImage.clear()
                }
            }
        }
    }

    /// Keeps the image view's height in the drawn image's aspect ratio, or collapses it when there is no image.
    /// Runs whenever the image view's `image` or `isHidden` changes, including changes made by integrators.
    func updateMessageImageHeight() {
        var aspectRatio: CGFloat?
        if let size = animatedMessageImage.image?.size,
           !animatedMessageImage.isHidden,
           size.width > 0,
           size.height > 0 {
            aspectRatio = size.height / size.width
        }
        if aspectRatio != nil {
            keepsMessageImageHeight = false
        } else if keepsMessageImageHeight && !animatedMessageImage.isHidden {
            // the released image is being loaded again, keep the current height
            return
        }
        // animated images replace `image` on every frame, keep the constraint while the ratio is unchanged
        if messageImageHeightConstraint != nil && aspectRatio == messageImageAspectRatio {
            return
        }
        messageImageHeightConstraint?.isActive = false
        let constraint: NSLayoutConstraint
        if let aspectRatio {
            constraint = animatedMessageImage.heightAnchor.constraint(
                equalTo: animatedMessageImage.widthAnchor,
                multiplier: aspectRatio
            )
        } else {
            constraint = animatedMessageImage.heightAnchor.constraint(equalToConstant: 0)
        }
        constraint.priority = .required - 1
        constraint.isActive = true
        messageImageHeightConstraint = constraint
        messageImageAspectRatio = aspectRatio
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
        let configuration = htmlContainer.configuration
        if let contentRuleList = inAppContentBlocksManager?.contentRuleList {
            configuration.userContentController.add(contentRuleList)
        }
        htmlContainer.navigationDelegate = self.actionManager
        htmlContainer.uiDelegate = self
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let selfWhileAsync = self else {
                Exponea.logger.log(.error, message: "Showing a HTML AppInbox stops")
                return
            }
            let normalizeConf = HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false
            )
            guard let normalizedPayload = HtmlRenderResourcePreloader().prepareNormalizedHtml(
                html: selfWhileAsync.data?.content?.html ?? "",
                config: normalizeConf
            ) else {
                Exponea.logger.log(.error, message: "AppInbox message contains invalid HTML")
                return
            }
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
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: source, relativeTo: Date())
    }
}

// MARK: - Methods
private extension AppInboxDetailViewController {
    func convertToDarkIfNeeded() {
        guard Exponea.shared.isDarkMode else { return }
        view.backgroundColor = .systemBackground
        messageImage.backgroundColor = .secondarySystemBackground
        messageTitle.textColor = .label
        message.textColor = .secondaryLabel
        htmlContainer.backgroundColor = .systemBackground
    }

    func setupElements() {
        view.backgroundColor = .white
        animatedMessageImage.onDisplayStateChanged = { [weak self] in
            self?.updateMessageImageHeight()
        }
        messageImage.contentMode = .scaleAspectFit
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
            .padding(.leading, .trailing, constant: 0)
            .padding(.top, constant: Exponea.shared.configuration?.appInboxDetailImageInset ?? 0)
        messageImage.widthAnchor.constraint(equalTo: pushContainer.frameLayoutGuide.widthAnchor).isActive = true
        updateMessageImageHeight()
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

/// Image view of the detail screen that reports every change of its displayed image or visibility,
/// so the screen can keep the view's height in sync even when integrators set them directly.
final class AppInboxDetailImageView: UIAnimatedImageView {

    var onDisplayStateChanged: (() -> Void)?
    /// True while an image set from outside the SDK is shown; the SDK then doesn't load its own image.
    private(set) var hasCustomImage = false

    override var image: UIImage? {
        didSet {
            if !isSettingOwnImage {
                hasCustomImage = image != nil
                stopFrameAnimation()
            }
            onDisplayStateChanged?()
        }
    }

    func resetCustomImage() {
        hasCustomImage = false
    }

    override var isHidden: Bool {
        didSet {
            guard isHidden != oldValue else { return }
            onDisplayStateChanged?()
        }
    }
}
