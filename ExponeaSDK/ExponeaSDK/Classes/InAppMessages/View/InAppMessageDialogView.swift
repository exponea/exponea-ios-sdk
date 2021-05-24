//
//  InAppMessageDialogView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 02/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import UIKit

final class InAppMessageDialogView: UIViewController, InAppMessageView {
    enum TextPosition {
        case top
        case bottom
    }

    let payload: InAppMessagePayload
    let image: UIImage
    let actionCallback: ((InAppMessagePayloadButton) -> Void)
    let dismissCallback: (() -> Void)
    let fullscreen: Bool

    let dialogContainerView: UIView = UIView() // whole dialog
    let dialogStackView: UIStackView = UIStackView()

    let imageView: UIImageView = UIImageView()
    var imageViewHeightConstraint: NSLayoutConstraint?
    let closeButton: UIButton = UIButton()

    let backgroundView: UIView = UIView() // part of dialog that contains texts and button
    let contentsStackView: UIStackView = UIStackView()
    let titleTextView: UITextView = UITextView()
    let bodyTextView: UITextView = UITextView()
    let actionButtonsStackView: UIStackView = UIStackView()
    let actionButton1: InAppMessageActionButton = InAppMessageActionButton()
    let actionButton2: InAppMessageActionButton = InAppMessageActionButton()

    var textPosition: TextPosition {
        return (payload.textPosition == "top") ? .top : .bottom
    }
    var textOverImage: Bool {
        return payload.textOverImage == true
    }

    init(
        payload: InAppMessagePayload,
        image: UIImage,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void),
        dismissCallback: @escaping (() -> Void),
        fullscreen: Bool
    ) {
        self.payload = payload
        self.image = image
        self.actionCallback = actionCallback
        self.dismissCallback = dismissCallback
        self.fullscreen = fullscreen

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func present(in viewController: UIViewController, window: UIWindow?) {
        viewController.present(self, animated: true)
    }

    func dismiss() {
        guard presentingViewController != nil else {
            return
        }
        dismissCallback()
        dismiss(animated: true)
    }

    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDialogContainer()
        setupPositions()
        setupImage()
        setupBackground()
        setupTitle()
        setupBody()
        setupActionButtons()
        setupCloseButton()

        // touches outside of the dialog should close the dialog
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapOutside))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }

    override func viewDidLayoutSubviews() {
        if !fullscreen {
            setupImageHeightConstraint()
        }
    }

    @objc private func onTapOutside() {
        dismissCallback()
        dismiss(animated: true)
    }

    private func setupDialogContainer() {
        dialogContainerView.translatesAutoresizingMaskIntoConstraints = false

        dialogContainerView.layer.cornerRadius = 15
        dialogContainerView.clipsToBounds = true

        view.addSubview(dialogContainerView)

        dialogStackView.translatesAutoresizingMaskIntoConstraints = false
        dialogStackView.axis = .vertical
        dialogContainerView.addSubview(dialogStackView)

        var constraints = [
            dialogStackView.leadingAnchor.constraint(equalTo: dialogContainerView.leadingAnchor),
            dialogStackView.trailingAnchor.constraint(equalTo: dialogContainerView.trailingAnchor),
            dialogStackView.topAnchor.constraint(equalTo: dialogContainerView.topAnchor),
            dialogStackView.bottomAnchor.constraint(equalTo: dialogContainerView.bottomAnchor),
            dialogContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            dialogContainerView.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor)
        ]
        if fullscreen {
            constraints.append(contentsOf: [
                dialogContainerView.topAnchor.constraint(
                    equalTo: view.layoutMarginsGuide.topAnchor,
                    constant: 20
                ),
                dialogContainerView.bottomAnchor.constraint(
                    equalTo: view.layoutMarginsGuide.bottomAnchor,
                    constant: -20
                )
            ])
        } else {
            constraints.append(contentsOf: [
                dialogContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                dialogContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                dialogContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
                dialogContainerView.topAnchor.constraint(
                    greaterThanOrEqualTo: view.layoutMarginsGuide.topAnchor,
                    constant: 20
                ),
                dialogContainerView.bottomAnchor.constraint(
                    lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor,
                    constant: -20
                )
            ])
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func setupPositions() {
        if textOverImage {
            dialogStackView.addArrangedSubview(imageView)
            dialogStackView.addSubview(backgroundView)
            switch textPosition {
            case.top:
                backgroundView.topAnchor.constraint(equalTo: dialogStackView.topAnchor).isActive = true
            case.bottom:
                backgroundView.bottomAnchor.constraint(equalTo: dialogStackView.bottomAnchor).isActive = true
            }
        } else {
            switch textPosition {
            case.top:
                dialogStackView.addArrangedSubview(backgroundView)
                dialogStackView.addArrangedSubview(imageView)
            case.bottom:
                dialogStackView.addArrangedSubview(imageView)
                dialogStackView.addArrangedSubview(backgroundView)
            }
        }
    }

    private func setupImage() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = image

        var constraints = [
            imageView.leadingAnchor.constraint(equalTo: dialogContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: dialogContainerView.trailingAnchor)
        ]
        if !fullscreen {
            let heightConstraint = imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 150)
            constraints.append(heightConstraint)
            imageViewHeightConstraint = heightConstraint
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func setupImageHeightConstraint() {
        let ratio = image.size.width / image.size.height
        let height = imageView.frame.width / ratio
        imageViewHeightConstraint?.constant = height
    }

    private func setupBackground() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        if textOverImage {
            backgroundView.backgroundColor = UIColor.clear
        } else {
            backgroundView.backgroundColor = UIColor(fromHexString: payload.backgroundColor)
        }

        contentsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentsStackView.axis = .vertical
        contentsStackView.alignment = .center
        backgroundView.addSubview(contentsStackView)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: dialogContainerView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: dialogContainerView.trailingAnchor),
            contentsStackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            contentsStackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            contentsStackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 20),
            contentsStackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -20)
        ])
    }

    private func setupTitle() {
        guard payload.title != nil else {
            return
        }
        titleTextView.translatesAutoresizingMaskIntoConstraints = false
        titleTextView.isScrollEnabled = false
        titleTextView.textAlignment = .center
        titleTextView.isEditable = false
        titleTextView.isSelectable = false
        titleTextView.text = payload.title
        titleTextView.textColor = UIColor(fromHexString: payload.titleTextColor)
        titleTextView.backgroundColor = .clear
        titleTextView.font = .boldSystemFont(ofSize: parseFontSize(payload.titleTextSize))
        titleTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        titleTextView.textContainerInset = UIEdgeInsets(top: 0, left: 20, bottom: 10, right: 20)

        contentsStackView.addArrangedSubview(titleTextView)
    }

    private func setupBody() {
        guard payload.bodyText != nil else {
            return
        }
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.isScrollEnabled = false
        bodyTextView.textAlignment = .center
        bodyTextView.isEditable = false
        bodyTextView.isSelectable = false
        bodyTextView.text = payload.bodyText
        bodyTextView.textColor = UIColor(fromHexString: payload.bodyTextColor)
        bodyTextView.backgroundColor = .clear
        bodyTextView.font = .systemFont(ofSize: parseFontSize(payload.bodyTextSize))
        bodyTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        bodyTextView.textContainerInset = UIEdgeInsets(top: 0, left: 20, bottom: 10, right: 20)

        contentsStackView.addArrangedSubview(bodyTextView)
    }

    private func setupActionButtons() {
        guard let buttons = payload.buttons else {
            return
        }
        actionButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsStackView.axis = .horizontal
        actionButtonsStackView.alignment = .center
        actionButtonsStackView.spacing = 20
        contentsStackView.addArrangedSubview(actionButtonsStackView)

        if !buttons.isEmpty {
            setupActionButton(actionButton: actionButton1, payload: buttons[0])
        }
        if buttons.count > 1 {
            setupActionButton(actionButton: actionButton2, payload: buttons[1])
        }
    }

    private func setupActionButton(actionButton: InAppMessageActionButton, payload: InAppMessagePayloadButton) {
        guard payload.buttonText != nil else {
            return
        }
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        actionButton.layer.cornerRadius = 5
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        actionButton.setTitle(payload.buttonText, for: .normal)
        actionButton.setTitleColor(UIColor(fromHexString: payload.buttonTextColor), for: .normal)
        actionButton.backgroundColor = UIColor(fromHexString: payload.buttonBackgroundColor)
        actionButton.payload = payload
        switch payload.buttonType {
        case .cancel:
            actionButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        case .deeplink:
            actionButton.addTarget(self, action: #selector(actionButtonAction), for: .touchUpInside)
        }

        actionButtonsStackView.addArrangedSubview(actionButton)

        NSLayoutConstraint.activate([
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            actionButton.widthAnchor.constraint(lessThanOrEqualTo: actionButtonsStackView.widthAnchor)
        ])
    }

    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.titleLabel?.font = .systemFont(ofSize: 30)
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(UIColor(fromHexString: payload.closeButtonColor), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)

        dialogContainerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: dialogContainerView.topAnchor, constant: -5),
            closeButton.trailingAnchor.constraint(equalTo: dialogContainerView.trailingAnchor, constant: -5)
        ])
    }

    @objc func actionButtonAction(_ sender: InAppMessageActionButton) {
        guard let payload = sender.payload else {
            return
        }
        dismiss(animated: true)
        actionCallback(payload)
    }

    @objc func closeButtonAction(_ sender: Any) {
        dismissCallback()
        dismiss(animated: true)
    }

    private func parseFontSize(_ fontSize: String?) -> CGFloat {
        return CGFloat(Float((fontSize ?? "").replacingOccurrences(of: "px", with: "")) ?? 16)
    }
}

// recognizes touches outside of the dialog
extension InAppMessageDialogView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view?.isDescendant(of: self.view) == false
    }
}
