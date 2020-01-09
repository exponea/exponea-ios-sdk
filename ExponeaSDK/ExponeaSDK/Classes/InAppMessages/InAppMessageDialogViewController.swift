//
//  InAppMessageDialogViewController.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 02/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import UIKit

class InAppMessageDialogViewController: UIViewController {

    @IBOutlet weak var backgroundView: UIView!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var titleTextView: UITextView!

    @IBOutlet weak var bodyTextView: UITextView!

    @IBOutlet weak var actionButton: UIButton!
    @IBAction func actionButtonAction(_ sender: Any) {
        dismiss(animated: true)
        actionCallback?()
    }

    @IBOutlet weak var closeButton: UIButton!

    @IBAction func closeButtonAction(_ sender: Any) {
        dismissCallback?()
        dismiss(animated: true)
    }

    var payload: InAppMessagePayload?
    var actionCallback: (() -> Void)?
    var dismissCallback: (() -> Void)?
    var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let payload = payload, let image = image {
            setupView(payload: payload, image: image)
        }
        // touches outside of the dialog should close the dialog
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapOutside))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }

    @objc private func onTapOutside() {
        dismissCallback?()
        dismiss(animated: true)
    }

    private func setupView(payload: InAppMessagePayload, image: UIImage) {
        backgroundView.backgroundColor = UIColor(fromHexString: payload.backgroundColor)
        closeButton.setTitleColor(UIColor(fromHexString: payload.closeButtonColor), for: .normal)
        setupImage(image: image)
        setupTitle(payload: payload)
        setupBody(payload: payload)
        setupButton(payload: payload)
    }

    private func setupImage(image: UIImage) {
        self.view.layoutIfNeeded() // let the image scale horizonally, then we'll set it up vertically
        self.imageView.image = image
        let ratio = image.size.width / image.size.height
        let newHeight = self.imageView.frame.width / ratio
        self.imageViewHeightConstraint.constant = newHeight
    }

    private func setupTitle(payload: InAppMessagePayload) {
        titleTextView.text = payload.title
        titleTextView.textColor = UIColor(fromHexString: payload.titleTextColor)
        titleTextView.font = UIFont(
            name: titleTextView.font!.fontName,
            size: parseFontSize(payload.titleTextSize)
        )
    }

    private func setupButton(payload: InAppMessagePayload) {
        actionButton.setTitle(payload.buttonText, for: .normal)
        actionButton.setTitleColor(UIColor(fromHexString: payload.buttonTextColor), for: .normal)
        actionButton.backgroundColor = UIColor(fromHexString: payload.buttonBackgroundColor)
    }

    private func setupBody(payload: InAppMessagePayload) {
        bodyTextView.text = payload.bodyText
        bodyTextView.textColor = UIColor(fromHexString: payload.bodyTextColor)
        bodyTextView.font = UIFont(
            name: bodyTextView.font!.fontName,
            size: parseFontSize(payload.bodyTextSize)
        )
    }

    private func parseFontSize(_ fontSize: String) -> CGFloat {
        return CGFloat(Float(fontSize.replacingOccurrences(of: "px", with: "")) ?? 16)
    }
}

// recognizes touches outside of the dialog
extension InAppMessageDialogViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view?.isDescendant(of: self.backgroundView) == false
    }
}
