//
//  InAppDialogContainerView.swift
//  ExponeaSDK
//
//  Created by Ankmara on 21.11.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import UIKit
import SwiftUI

public final class InAppDialogContainerView: UIViewController, InAppMessageView {

    var actionCallback: ((InAppMessagePayloadButton) -> Void)
    private let dialogContainerView: UIView = UIView()
    private var dialogStackView: UIView = UIView()
    private let backgroundView: UIView = UIView()
    private let isFullscreen: Bool
    internal let dismissCallback: TypeBlock<(Bool, InAppMessagePayloadButton?)>
    private var payLoad: RichInAppMessagePayload
    private var isLoaded = false
    private var isRichPresented = false
    private let debouncer = Debouncer(delay: 2)
    var bottomCons: NSLayoutConstraint?
    var heightCons: NSLayoutConstraint?
    private var inAppView: InAppView?
    var setCloseTimeCallback: EmptyBlock?
    private var calculatedHeight: CGFloat = 0 {
        willSet {
            if newValue != 0 {
                var top: CGFloat = 0
                var bottom: CGFloat = 0
                if let window = UIApplication.shared.windows.first {
                    top = window.safeAreaInsets.top
                    bottom = window.safeAreaInsets.bottom
                }
                var height = newValue
                if isFullscreen {
                    height -= top - bottom
                } else {
                    height += top + bottom
                }
                if height > UIScreen.main.bounds.height {
                    inAppView?.config.shouldBeScrollable = true
                    heightCons?.constant = UIScreen.main.bounds.height - top - bottom
                    bottomCons?.constant = bottom
                } else {
                    heightCons?.constant = newValue
                }
                view.layoutIfNeeded()
                showModal()
                setCloseTimeCallback?()
            }
        }
    }

    var isPresented: Bool {
        presentingViewController != nil || isRichPresented
    }

    public init(
        payLoad: RichInAppMessagePayload,
        isFullscreen: Bool = false,
        dismissCallback: @escaping TypeBlock<(Bool, InAppMessagePayloadButton?)>,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void)
    ) {
        self.payLoad = payLoad
        self.isFullscreen = isFullscreen
        self.dismissCallback = dismissCallback
        self.actionCallback = actionCallback
        super.init(nibName: nil, bundle: nil)

        var updatedPayload = payLoad
        updatedPayload.closeConfig.dismissCallback = { [weak self] in
            self?.closeButtonAction()
        }
        var view: InAppView = .init(
            layouConfig: payLoad.layoutConfig,
            buttonsConfig: payLoad.buttons.compactMap { $0.buttonConfig },
            titleConfig: payLoad.titleConfig,
            bodyConfig: payLoad.bodyConfig,
            closeButtonConfig: updatedPayload.closeConfig,
            imageConfig: payLoad.imageConfig,
            isFullscreen: isFullscreen
        )
        view.textCompletionHeight = { [weak self] height in
            self?.calculatedHeight = height
        }
        inAppView = view
        if let vc = UIHostingController(rootView: view).view {
            dialogStackView = vc
        }
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func showModal() {
        self.view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: 2000)
        self.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        isRichPresented = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.alpha = 1
                self.view.transform = .identity
            })
        }
    }

    func present(in viewController: UIViewController, window: UIWindow?) {
        viewController.addChild(self)
        viewController.view.addSubview(view)
        didMove(toParent: self)
    }

    func dismiss(isUserInteraction: Bool, cancelButton: InAppMessagePayloadButton?) {
        dismissCallback((isUserInteraction, .init(closeConfig: payLoad.closeConfig)))
        dismissFromSuperView()
    }

    func dismiss(actionButton: InAppMessagePayloadButton) {
        dismissFromSuperView()
    }

    func dismissFromSuperView() {
        view.removeFromSuperview()
        removeFromParent()
    }

    public override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.transform = CGAffineTransform(translationX: 0, y: -2000)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupDialogContainer()
    }

    @objc private func onTapOutside() {
        dismiss(isUserInteraction: true, cancelButton: nil)
    }

    private func setupDialogContainer() {
        dialogContainerView.translatesAutoresizingMaskIntoConstraints = false

        dialogContainerView.layer.cornerRadius = 15
        dialogContainerView.clipsToBounds = true

        view.addSubview(dialogContainerView)

        dialogStackView.translatesAutoresizingMaskIntoConstraints = false
        dialogContainerView.addSubview(dialogStackView)

        var constraints = [
            dialogStackView.leadingAnchor.constraint(equalTo: dialogContainerView.leadingAnchor),
            dialogStackView.trailingAnchor.constraint(equalTo: dialogContainerView.trailingAnchor),
            dialogStackView.topAnchor.constraint(equalTo: dialogContainerView.topAnchor),
            dialogStackView.bottomAnchor.constraint(equalTo: dialogContainerView.bottomAnchor),
            dialogContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            dialogContainerView.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor)
        ]
        let leading = payLoad.layoutConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0
        let trailing = payLoad.layoutConfig.margin.first(where: { $0.edge == .leading })?.value ?? 0
        let top = payLoad.layoutConfig.margin.first(where: { $0.edge == .top })?.value ?? 0
        let bottom = payLoad.layoutConfig.margin.first(where: { $0.edge == .bottom })?.value ?? 0
        if isFullscreen {
            var top: CGFloat = 0
            var bottom: CGFloat = 0
            if let window = UIApplication.shared.windows.first {
                top = window.safeAreaInsets.top
                bottom = window.safeAreaInsets.bottom
            }
            constraints.append(
                contentsOf: [
                    dialogContainerView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: leading),
                    dialogContainerView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -trailing),
                    dialogContainerView.topAnchor.constraint(
                        equalTo: view.layoutMarginsGuide.topAnchor,
                        constant: top
                    ),
                    dialogContainerView.bottomAnchor.constraint(
                        equalTo: view.layoutMarginsGuide.bottomAnchor,
                        constant: -bottom
                    )
                ]
            )
        } else {
            var safeTop: CGFloat = 0
            var safeBottom: CGFloat = 0
            if let window = UIApplication.shared.windows.first {
                safeTop = window.safeAreaInsets.top
                safeBottom = window.safeAreaInsets.bottom
            }
            constraints.append(
                contentsOf: [
                    dialogContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    dialogContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    dialogContainerView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: leading),
                    dialogContainerView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -trailing),
                    dialogContainerView.topAnchor.constraint(
                        greaterThanOrEqualTo: view.layoutMarginsGuide.topAnchor,
                        constant: top + safeTop
                    ),
                    dialogContainerView.bottomAnchor.constraint(
                        lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor,
                        constant: -(bottom + safeBottom)
                    )
                ]
            )
            heightCons = dialogContainerView.heightAnchor.constraint(equalToConstant: 0)
            heightCons?.isActive = true
            bottomCons = dialogContainerView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor,
                constant: -20
            )
            bottomCons?.isActive = true
        }
        NSLayoutConstraint.activate(constraints)
    }

    @objc func actionButtonAction(_ sender: InAppMessageActionButton) {
        guard let payload = sender.payload else { return }
        dismiss(actionButton: payload)
    }

    private func closeButtonAction() {
        dismiss(isUserInteraction: true, cancelButton: nil)
    }
}
