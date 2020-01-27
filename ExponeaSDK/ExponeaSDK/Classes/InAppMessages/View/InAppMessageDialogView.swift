//
//  InAppMessageDialogView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 02/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import UIKit

final class InAppMessageDialogView: UIViewController, InAppMessageView {
    var viewController: UIViewController { return self }

    let payload: InAppMessagePayload
    let image: UIImage
    let actionCallback: (() -> Void)
    let dismissCallback: (() -> Void)
    let fullscreen: Bool

    let dialogContainerView: UIView = UIView() // whole dialog

    let imageView: UIImageView = UIImageView()
    var imageViewHeightConstraint: NSLayoutConstraint?
    let closeButton: UIButton = UIButton()

    let backgroundView: UIView = UIView() // part of dialog that contains texts and button
    let titleTextView: UITextView = UITextView()
    let bodyTextView: UITextView = UITextView()
    let actionButton: UIButton = UIButton()

    init(
        payload: InAppMessagePayload,
        image: UIImage,
        actionCallback: @escaping (() -> Void),
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

    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDialogContainer()
        setupImage()
        setupBackground()
        setupTitle()
        setupBody()
        setupActionButton()
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

        var constraints = [
            dialogContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dialogContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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

    private func setupImage() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = image

        dialogContainerView.addSubview(imageView)
        var constraints = [
            imageView.topAnchor.constraint(equalTo: dialogContainerView.topAnchor),
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

        backgroundView.backgroundColor = UIColor(fromHexString: payload.backgroundColor)

        dialogContainerView.addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: dialogContainerView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: dialogContainerView.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: dialogContainerView.bottomAnchor)
        ])
    }

    private func setupTitle() {
        titleTextView.translatesAutoresizingMaskIntoConstraints = false
        titleTextView.isScrollEnabled = false
        titleTextView.textAlignment = .center
        titleTextView.text = payload.title
        titleTextView.textColor = UIColor(fromHexString: payload.titleTextColor)
        titleTextView.backgroundColor = .clear
        titleTextView.font = .boldSystemFont(ofSize: parseFontSize(payload.titleTextSize))
        titleTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        titleTextView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 20)

        backgroundView.addSubview(titleTextView)

        NSLayoutConstraint.activate([
            titleTextView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            titleTextView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            titleTextView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        ])
    }

    private func setupBody() {
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.isScrollEnabled = false
        bodyTextView.textAlignment = .center
        bodyTextView.text = payload.bodyText
        bodyTextView.textColor = UIColor(fromHexString: payload.bodyTextColor)
        bodyTextView.backgroundColor = .clear
        bodyTextView.font = .systemFont(ofSize: parseFontSize(payload.bodyTextSize))
        bodyTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        bodyTextView.textContainerInset = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)

        backgroundView.addSubview(bodyTextView)

        NSLayoutConstraint.activate([
            bodyTextView.topAnchor.constraint(equalTo: titleTextView.bottomAnchor),
            bodyTextView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            bodyTextView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        ])
    }

    private func setupActionButton() {
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        actionButton.layer.cornerRadius = 5
        actionButton.titleEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        actionButton.setTitle(payload.buttonText, for: .normal)
        actionButton.setTitleColor(UIColor(fromHexString: payload.buttonTextColor), for: .normal)
        actionButton.backgroundColor = UIColor(fromHexString: payload.buttonBackgroundColor)
        actionButton.addTarget(self, action: #selector(actionButtonAction), for: .touchUpInside)

        backgroundView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            actionButton.widthAnchor.constraint(lessThanOrEqualTo: backgroundView.widthAnchor),
            actionButton.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -20),
            actionButton.topAnchor.constraint(equalTo: bodyTextView.bottomAnchor)
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

    @objc func actionButtonAction(_ sender: Any) {
        dismiss(animated: true)
        actionCallback()
    }

    @objc func closeButtonAction(_ sender: Any) {
        dismissCallback()
        dismiss(animated: true)
    }

    private func parseFontSize(_ fontSize: String) -> CGFloat {
        return CGFloat(Float(fontSize.replacingOccurrences(of: "px", with: "")) ?? 16)
    }
}

// recognizes touches outside of the dialog
extension InAppMessageDialogView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view?.isDescendant(of: self.backgroundView) == false
    }
}
