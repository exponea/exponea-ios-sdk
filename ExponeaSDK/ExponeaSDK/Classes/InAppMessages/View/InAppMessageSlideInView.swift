//
//  InAppMessageSlideInView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine

public final class InAppMessageSlideInViewModel: ObservableObject {

    public var isHeightSet = false
    public let layouConfig: InAppLayoutConfig
    public let buttonsConfig: [InAppButtonConfig]
    public let titleConfig: InAppLabelConfig
    public let bodyConfig: InAppBodyLabelConfig
    public let closeButtonConfig: InAppCloseButtonConfig
    public let imageConfig: InAppImageComponentConfig
    @Published public var height: CGFloat = 0
    @Published public var isBiggerThanScreen = false
    private var areConfigsSet = false
    public var isLoaded = false
    var debouncer = Debouncer(delay: 2)

    init(
        layouConfig: InAppLayoutConfig,
        buttonsConfig: [InAppButtonConfig],
        titleConfig: InAppLabelConfig,
        bodyConfig: InAppBodyLabelConfig,
        closeButtonConfig: InAppCloseButtonConfig,
        imageConfig: InAppImageComponentConfig
    ) {
        self.layouConfig = layouConfig
        self.buttonsConfig = buttonsConfig
        self.titleConfig = titleConfig
        self.bodyConfig = bodyConfig
        self.closeButtonConfig = closeButtonConfig
        self.imageConfig = imageConfig
    }
}

struct InAppMessageSlideInViewSwiftUI: View {

    public let heightCompletion: TypeBlock<CGFloat>?

    @ObservedObject public var viewModel: InAppMessageSlideInViewModel

    private var isTextVisible: Bool {
        viewModel.titleConfig.isVisible || viewModel.bodyConfig.isVisible
    }

    init(
        layouConfig: InAppLayoutConfig,
        buttonsConfig: [InAppButtonConfig],
        titleConfig: InAppLabelConfig,
        bodyConfig: InAppBodyLabelConfig,
        closeButtonConfig: InAppCloseButtonConfig,
        imageConfig: InAppImageComponentConfig,
        heightCompletion: TypeBlock<CGFloat>?
    ) {
        self.heightCompletion = heightCompletion

        viewModel = .init(
            layouConfig: layouConfig,
            buttonsConfig: buttonsConfig,
            titleConfig: titleConfig,
            bodyConfig: bodyConfig,
            closeButtonConfig: closeButtonConfig,
            imageConfig: imageConfig
        )
    }

    private var footer: some View {
        VStack(spacing: 0) {
            buttonArea
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            imageArea
            if isTextVisible {
                if viewModel.closeButtonConfig.visibility && viewModel.imageConfig.isOverlay {
                    textArea
                        .padding(.top, (viewModel.closeButtonConfig.margin.first(where: { $0.edge == .top })?.value ?? 0) + 38)
                } else {
                    textArea
                }
            } else {
                VStack(spacing: 0) {}
                    .frame(width: 600)
            }
        }
    }

    private var imageArea: some View {
        SlideInAppImageComponent(
            config: viewModel.imageConfig,
            layoutConfig: viewModel.layouConfig
        )
    }

    private var buttonArea: some View {
        InAppButtonContainerSwiftUI(
            buttons: viewModel.buttonsConfig,
            alignment: viewModel.layouConfig.buttonsAlign
        )
        .readHeight { height in
            if !viewModel.isHeightSet {
                self.viewModel.height += height
            }
        }
    }

    func setupHeight(height: CGFloat) {
        self.viewModel.height = height
    }

    private var textArea: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                if viewModel.isBiggerThanScreen {
                    ScrollView(.vertical, showsIndicators: false) {
                        if viewModel.titleConfig.isVisible {
                            TextWithAttributedString(
                                config: viewModel.titleConfig,
                                width: proxy.size.width,
                                isCompressionVertical: true,
                                heightCompletion: { height in
                                    if !viewModel.isHeightSet {
                                        self.viewModel.height += height
                                    }
                                }
                            )
                            .padding(.trailing, viewModel.titleConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                            .padding(.leading, viewModel.titleConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
                        }
                        if viewModel.bodyConfig.isVisible {
                            TextWithAttributedString(
                                config: viewModel.bodyConfig,
                                width: proxy.size.width,
                                isCompressionVertical: true,
                                heightCompletion: { height in
                                    if !viewModel.isHeightSet {
                                        self.viewModel.height += height
                                    }
                                }
                            )
                            .padding(.trailing, viewModel.bodyConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                            .padding(.leading, viewModel.bodyConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
                        }
                    }
                } else {
                    if viewModel.titleConfig.isVisible {
                        TextWithAttributedString(
                            config: viewModel.titleConfig,
                            width: proxy.size.width,
                            isCompressionVertical: true,
                            heightCompletion: { height in
                                if !viewModel.isHeightSet {
                                    self.viewModel.height += height
                                }
                            }
                        )
                        .padding(.trailing, viewModel.titleConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                        .padding(.leading, viewModel.titleConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
                    }
                    if viewModel.bodyConfig.isVisible {
                        TextWithAttributedString(
                            config: viewModel.bodyConfig,
                            width: proxy.size.width,
                            isCompressionVertical: true,
                            heightCompletion: { height in
                                if !viewModel.isHeightSet {
                                    self.viewModel.height += height
                                }
                            }
                        )
                        .padding(.trailing, viewModel.bodyConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                        .padding(.leading, viewModel.bodyConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
                    }
                }
            }
        }
    }

    private var closeButtonView: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                if viewModel.closeButtonConfig.visibility {
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Spacer()
                        VStack(spacing: 0) {
                            InAppCloseButton(config: viewModel.closeButtonConfig)
                                .padding(
                                    .top,
                                    viewModel.closeButtonConfig.margin.first(where: { $0.edge == .top })?.value ?? 0
                                )
                                .padding(
                                    .trailing,
                                    (viewModel.closeButtonConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0)
                                )
                        }
                    }
                    .frame(width: proxy.size.width)
                }
            }
        }
    }

    public var body: some View {
        let topMargin = viewModel.layouConfig.margin.first(where: { $0.edge == .top })?.value ?? 0
        let bottomMargin = viewModel.layouConfig.margin.first(where: { $0.edge == .bottom })?.value ?? 0
        let trailingMargin = viewModel.layouConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0
        let leadingMargin = viewModel.layouConfig.margin.first(where: { $0.edge == .leading })?.value ?? 0
        VStack(spacing: 0) {
            let bottomPadding = viewModel.layouConfig.padding.first(where: { $0.edge == .bottom })?.value ?? 0
            let topPadding = viewModel.layouConfig.padding.first(where: { $0.edge == .top })?.value ?? 0
            let trailingPadding = viewModel.layouConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0
            let leadingPadding = viewModel.layouConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0
            switch true {
            case viewModel.imageConfig.size == .fullscreen && viewModel.imageConfig.isVisible:
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        imageArea
                            .zIndex(1)
                        if viewModel.imageConfig.isOverlay, let overlayColor = viewModel.imageConfig.overlayColor {
                            Color(UIColor.parse(overlayColor) ?? .clear)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .zIndex(2)
                        }
                        VStack(spacing: 0) {
                            if isTextVisible {
                                textArea
                            } else {
                                VStack(spacing: 0) {}
                                    .frame(width: 600)
                            }
                            footer
                        }
                        .zIndex(3)
                        .padding(.bottom, bottomPadding)
                        .padding(.top, topPadding)
                        .padding(.trailing, trailingPadding)
                        .padding(.leading, leadingPadding)
                    }
                }
                .overlay(
                    closeButtonView,
                    alignment: .topTrailing
                )
            case viewModel.layouConfig.textPosition == .leading:
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        textArea
                        buttonArea
                    }
                    imageArea
                        .overlay(
                            closeButtonView,
                            alignment: .topTrailing
                        )
                }
            default:
                HStack(alignment: .top, spacing: 0) {
                    imageArea
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            textArea
                            buttonArea
                        }
                        closeButtonView
                    }
                }
            }
        }
        .background(Color(UIColor.parse(viewModel.layouConfig.backgroundColor) ?? .clear))
        .clipped(antialiased: true)
        .clipShape(RoundedRectangle(cornerRadius: viewModel.layouConfig.cornerRadius))
        .frame(maxWidth: .infinity)
        .readHeight { height in
            if !viewModel.isHeightSet {
                heightCompletion?(height)
            }
        }
        .frame(height: viewModel.height)
        .padding(.bottom, bottomMargin)
        .padding(.top, topMargin)
        .padding(.trailing, trailingMargin)
        .padding(.leading, leadingMargin)
    }
}

final class InAppMessageSlideInView: UIView, InAppMessageView {
    var showCallback: EmptyBlock?
    private let payload: RichInAppMessagePayload
    private let image: UIImage
    private let debouncer = Debouncer(delay: 2)
    let actionCallback: ((InAppMessagePayloadButton) -> Void)
    let dismissCallback: TypeBlock<(Bool, InAppMessagePayloadButton?)>
    var setCloseTimeCallback: EmptyBlock?

    private var inAppWindow: UIWindow?
    private var isLoaded = false

    var bottomCons: NSLayoutConstraint?
    var topCons: NSLayoutConstraint?
    var heightCons: NSLayoutConstraint?

    private var slideViewSwiftUI: InAppMessageSlideInViewSwiftUI?
    private var slideView: UIView?
    private var calculatedHeight: CGFloat = 0 {
        willSet {
            debouncer.debounce { [weak self] in
                guard let self else { return }
                if newValue != 0 {
                    var top: CGFloat = 0
                    var bottom: CGFloat = 0
                    if let window = UIApplication.shared.windows.first {
                        top = window.safeAreaInsets.top
                        bottom = window.safeAreaInsets.bottom
                    }
                    let height = newValue + top + bottom
                    if height > UIScreen.main.bounds.height {
                        self.heightCons?.constant = UIScreen.main.bounds.height - top - bottom
                        self.slideViewSwiftUI?.viewModel.isBiggerThanScreen = true
                        if self.slideViewSwiftUI?.viewModel.isHeightSet == false {
                            self.slideViewSwiftUI?.viewModel.isHeightSet = true
                            self.slideViewSwiftUI?.setupHeight(height: UIScreen.main.bounds.height - top - bottom)
                        }
                    } else {
                        self.slideViewSwiftUI?.viewModel.isBiggerThanScreen = false
                        self.heightCons?.constant = newValue
                    }
                    if self.displayOnBottom {
                        self.bottomCons?.constant = -10
                    } else {
                        self.topCons?.constant = 0
                    }
                    guard let view = self.slideView else { return }
                    view.layoutIfNeeded()
                    self.animateIn()
                    self.setCloseTimeCallback?()
                }
            }
        }
    }

    private var displayOnBottom: Bool {
        payload.layoutConfig.messagePosition == .bottom
    }

    private var animationStartY: CGFloat {
        (displayOnBottom ? 1 : -1 ) * 2 * frame.height
    }

    var isPresented: Bool {
        superview != nil
    }

    init(
        payload: RichInAppMessagePayload,
        image: UIImage,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void),
        dismissCallback: @escaping TypeBlock<(Bool, InAppMessagePayloadButton?)>
    ) {
        self.payload = payload
        self.image = image
        self.actionCallback = actionCallback
        self.dismissCallback = dismissCallback

        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func present(in viewController: UIViewController, window: UIWindow?) throws {
        self.inAppWindow = window
        guard let window else {
            throw InAppMessagePresenter.InAppMessagePresenterError.unableToPresentView
        }
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        window.addSubview(self)

        var updatedPayload = payload
        updatedPayload.closeConfig.dismissCallback = { [weak self] in
            self?.dismiss(isUserInteraction: true, cancelButton: nil)
        }

        let slideViewSwiftUI = InAppMessageSlideInViewSwiftUI(
            layouConfig: payload.layoutConfig,
            buttonsConfig: payload.buttons.compactMap { $0.buttonConfig }.filter { $0.isEnabled },
            titleConfig: payload.titleConfig,
            bodyConfig: payload.bodyConfig,
            closeButtonConfig: updatedPayload.closeConfig,
            imageConfig: payload.imageConfig,
            heightCompletion: { newHeight in
                self.debouncer.debounce {
                    if !self.isLoaded {
                        self.isLoaded = true
                        self.calculatedHeight += newHeight
                    }
                }
            }
        )
        self.slideViewSwiftUI = slideViewSwiftUI

        slideView = UIHostingController(
            rootView: self.slideViewSwiftUI
        ).view
        slideView?.backgroundColor = .clear
        slideView?.translatesAutoresizingMaskIntoConstraints = false
        guard let view = slideView else { return }
        if displayOnBottom {
            bottomCons = bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: 1000)
            bottomCons?.isActive = true
        } else {
            if #available(iOS 11.0, *) {
                topCons = topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: -1000)
            } else {
                topCons = topAnchor.constraint(equalTo: window.topAnchor, constant: -1000)
            }
            topCons?.isActive = true
        }

        heightCons = heightAnchor.constraint(equalToConstant: 0)
        heightCons?.isActive = true

        addSubview(view)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 0),
            trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: 0),
            view.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = displayOnBottom ? .down : .up
        addGestureRecognizer(swipeGesture)
    }

    func dismiss(isUserInteraction: Bool, cancelButton: InAppMessagePayloadButton?) {
        dismissCallback((isUserInteraction, cancelButton))
        dismissFromSuperView()
    }

    func dismiss(actionButton: InAppMessagePayloadButton) {
        actionCallback(actionButton)
        dismissFromSuperView()
    }

    func dismissFromSuperView() {
        guard superview != nil else {
            return
        }
        animateOut {
            self.removeFromSuperview()
        }
    }

    @objc func handleSwipe(gesture: UISwipeGestureRecognizer) {
        animateOut()
        dismiss(isUserInteraction: true, cancelButton: nil)
    }

    @objc func actionButtonAction(_ sender: InAppMessageActionButton) {
        guard let payload = sender.payload else {
            return
        }
        dismiss(actionButton: payload)
    }

    @objc func cancelButtonAction(_ sender: InAppMessageActionButton) {
        guard let cancelButtonPayload = sender.payload else {
            return
        }
        dismiss(isUserInteraction: true, cancelButton: cancelButtonPayload)
    }

    func animateIn(completion: (() -> Void)? = nil) {
        layoutIfNeeded()
        transform = CGAffineTransform(translationX: 0, y: animationStartY)
        UIView.animate(
            withDuration: 0.5,
            animations: { self.transform = .identity },
            completion: { _ in completion?() }
        )
    }

    func animateOut(completion: (() -> Void)? = nil) {
        layoutIfNeeded()
        UIView.animate(
            withDuration: 0.5,
            animations: { self.transform = CGAffineTransform(translationX: 0, y: self.animationStartY) },
            completion: { _ in completion?() }
        )
    }

    private func parseFontSize(_ fontSize: String?) -> CGFloat {
        CGFloat(Float((fontSize ?? "").replacingOccurrences(of: "px", with: "")) ?? 16)
    }
}

extension NSLayoutConstraint {
    func withPriority(_ priority: Float) -> NSLayoutConstraint {
        self.priority = UILayoutPriority(priority)
        return self
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    func readHeight(onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: HeightPreferenceKey.self, value: geometryProxy.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
    }
}

// OLD

final class OldInAppMessageSlideInView: UIView, InAppMessageView {
    var showCallback: EmptyBlock?

    private let payload: InAppMessagePayload
    private let image: UIImage
    let actionCallback: ((InAppMessagePayloadButton) -> Void)
    let dismissCallback: TypeBlock<(Bool, InAppMessagePayloadButton?)>

    private let imageView: UIImageView = UIImageView()

    private let stackView: UIStackView = UIStackView()
    private let titleTextView: UITextView = UITextView()
    private let bodyTextView: UITextView = UITextView()
    private let actionButtonsStackView: UIStackView = UIStackView()
    private let actionButton1: InAppMessageActionButton = InAppMessageActionButton()
    private let actionButton2: InAppMessageActionButton = InAppMessageActionButton()

    private var displayOnBottom: Bool {
        return payload.messagePosition == "bottom"
    }

    private var animationStartY: CGFloat {
        return (displayOnBottom ? 1 : -1 ) * 2 * frame.height
    }

    var isPresented: Bool {
        return superview != nil
    }

    init(
        payload: InAppMessagePayload,
        image: UIImage,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void),
        dismissCallback: @escaping TypeBlock<(Bool, InAppMessagePayloadButton?)>
    ) {
        self.payload = payload
        self.image = image
        self.actionCallback = actionCallback
        self.dismissCallback = dismissCallback

        super.init(frame: UIScreen.main.bounds)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func present(in viewController: UIViewController, window: UIWindow?) throws {
        guard let window = window else {
            throw InAppMessagePresenter.InAppMessagePresenterError.unableToPresentView
        }

        window.addSubview(self)

        if displayOnBottom {
            bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -10).isActive = true
        } else {
            if #available(iOS 11.0, *) {
                topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor).isActive = true
            } else {
                topAnchor.constraint(equalTo: window.topAnchor).isActive = true
            }
        }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 10),
            trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -10)
        ])

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = displayOnBottom ? .down : .up
        addGestureRecognizer(swipeGesture)

        animateIn()
    }

    func dismiss(isUserInteraction: Bool, cancelButton: InAppMessagePayloadButton?) {
        dismissCallback((isUserInteraction, cancelButton))
        dismissFromSuperView()
    }
    
    func dismiss(actionButton: InAppMessagePayloadButton) {
        actionCallback(actionButton)
        dismissFromSuperView()
    }
    
    func dismissFromSuperView() {
        guard superview != nil else {
            return
        }
        animateOut {
            self.removeFromSuperview()
        }
    }

    @objc func handleSwipe(gesture: UISwipeGestureRecognizer) {
        dismiss(isUserInteraction: true, cancelButton: nil)
    }

    @objc func actionButtonAction(_ sender: InAppMessageActionButton) {
        guard let payload = sender.payload else {
            return
        }
        dismiss(actionButton: payload)
    }

    @objc func cancelButtonAction(_ sender: InAppMessageActionButton) {
        guard let cancelButtonPayload = sender.payload else {
            return
        }
        dismiss(isUserInteraction: true, cancelButton: cancelButtonPayload)
    }

    func animateIn(completion: (() -> Void)? = nil) {
        layoutIfNeeded()
        transform = CGAffineTransform(translationX: 0, y: animationStartY)
        UIView.animate(
            withDuration: 0.5,
            animations: { self.transform = CGAffineTransform(translationX: 0, y: 0) },
            completion: { _ in completion?() }
        )
    }

    func animateOut(completion: (() -> Void)? = nil) {
        layoutIfNeeded()
        UIView.animate(
            withDuration: 0.5,
            animations: { self.transform = CGAffineTransform(translationX: 0, y: self.animationStartY) },
            completion: { _ in completion?() }
        )
    }

    func setup() {
        setupContainer()
        setupImage()
        setupStack()
        setupTitle()
        setupBody()
        setupActionButtons()
    }

    private func setupContainer() {
        translatesAutoresizingMaskIntoConstraints = false

        layer.cornerRadius = 10
        clipsToBounds = true
        backgroundColor = UIColor(fromHexString: payload.backgroundColor)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }

    private func setupImage() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = image

        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true

        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    private func setupStack() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }

    private func setupTitle() {
        guard payload.title != nil else {
            return
        }
        titleTextView.translatesAutoresizingMaskIntoConstraints = false
        titleTextView.isScrollEnabled = false
        titleTextView.textAlignment = .left
        titleTextView.text = payload.title
        titleTextView.isEditable = false
        titleTextView.isSelectable = false
        titleTextView.textColor = UIColor(fromHexString: payload.titleTextColor)
        titleTextView.backgroundColor = .clear
        titleTextView.font = .boldSystemFont(ofSize: parseFontSize(payload.titleTextSize))
        titleTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        titleTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        stackView.addArrangedSubview(titleTextView)
    }

    private func setupBody() {
        guard payload.bodyText != nil else {
            return
        }
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.isScrollEnabled = false
        bodyTextView.textAlignment = .left
        bodyTextView.text = payload.bodyText
        bodyTextView.isEditable = false
        bodyTextView.isSelectable = false
        bodyTextView.textColor = UIColor(fromHexString: payload.bodyTextColor)
        bodyTextView.backgroundColor = .clear
        bodyTextView.font = .systemFont(ofSize: parseFontSize(payload.bodyTextSize))
        bodyTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        bodyTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        stackView.addArrangedSubview(bodyTextView)
    }

    private func setupActionButtons() {
        actionButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsStackView.axis = .horizontal
        actionButtonsStackView.alignment = .center
        actionButtonsStackView.spacing = 10
        stackView.addArrangedSubview(actionButtonsStackView)

        guard let buttons = payload.buttons else {
            return
        }
        if !buttons.isEmpty {
            setupActionButton(actionButton: actionButton1, payload: buttons[0])
        }
        if buttons.count > 1 {
            setupActionButton(actionButton: actionButton2, payload: buttons[1])
        }
    }

    private func setupActionButton(actionButton: InAppMessageActionButton, payload: InAppMessagePayloadButton) {
        guard let titleLabel = actionButton.titleLabel, payload.buttonText != nil else {
            return
        }

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        actionButton.layer.cornerRadius = 5
        titleLabel.font = .boldSystemFont(ofSize: 12)
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        actionButton.setTitle(payload.buttonText, for: .normal)
        actionButton.setTitleColor(UIColor(fromHexString: payload.buttonTextColor), for: .normal)
        actionButton.backgroundColor = UIColor(fromHexString: payload.buttonBackgroundColor)
        actionButton.payload = payload
        switch payload.buttonType {
        case .cancel:
            actionButton.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        case .deeplink, .browser:
            actionButton.addTarget(self, action: #selector(actionButtonAction), for: .touchUpInside)
        }

        actionButtonsStackView.addArrangedSubview(actionButton)
    }

    private func parseFontSize(_ fontSize: String?) -> CGFloat {
        return CGFloat(Float((fontSize ?? "").replacingOccurrences(of: "px", with: "")) ?? 16)
    }
}
