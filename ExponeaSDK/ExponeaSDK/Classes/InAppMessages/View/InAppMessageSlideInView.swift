//
//  InAppMessageSlideInView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import UIKit

final class InAppMessageSlideInView: UIView, InAppMessageView {
    private let payload: InAppMessagePayload
    private let image: UIImage
    let actionCallback: (() -> Void)
    let dismissCallback: (() -> Void)

    private let imageView: UIImageView = UIImageView()

    private let stackView: UIStackView = UIStackView()
    private let titleTextView: UITextView = UITextView()
    private let bodyTextView: UITextView = UITextView()
    private let actionButton: UIButton = UIButton()

    private var displayOnBottom: Bool {
        return payload.messagePosition == "bottom"
    }

    private var animationStartY: CGFloat {
        return (displayOnBottom ? 1 : -1 ) * 2 * frame.height
    }

    init(
        payload: InAppMessagePayload,
        image: UIImage,
        actionCallback: @escaping (() -> Void),
        dismissCallback: @escaping (() -> Void)
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

        animateIn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                self?.animateOut {
                    self?.removeFromSuperview()
                    self?.dismissCallback()
                }
            }
        }
    }

    @objc func handleSwipe(gesture: UISwipeGestureRecognizer) {
        animateOut {
            self.removeFromSuperview()
            self.dismissCallback()
        }
    }

    @objc func actionButtonAction(_ sender: Any) {
        removeFromSuperview()
        actionCallback()
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
        setupActionButton()
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

    private func setupActionButton() {
        guard let titleLabel = actionButton.titleLabel, payload.buttonText != nil else {
            return
        }

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        actionButton.layer.cornerRadius = 5
        titleLabel.font = .boldSystemFont(ofSize: 12)
        actionButton.setTitle(payload.buttonText, for: .normal)
        actionButton.setTitleColor(UIColor(fromHexString: payload.buttonTextColor), for: .normal)
        actionButton.backgroundColor = UIColor(fromHexString: payload.buttonBackgroundColor)
        actionButton.addTarget(self, action: #selector(actionButtonAction), for: .touchUpInside)

        stackView.addArrangedSubview(actionButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: 5),
            titleLabel.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: -5)
        ])
    }

    private func parseFontSize(_ fontSize: String?) -> CGFloat {
        return CGFloat(Float((fontSize ?? "").replacingOccurrences(of: "px", with: "")) ?? 16)
    }
}
