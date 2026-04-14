//
//  ViewController.swift
//  Example
//
//  Created by Dominik Hadl on 01/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK
import SwiftUI

class AuthenticationViewController: UIViewController {

    @IBOutlet weak var pickerField: UITextField! {
        didSet {
            pickerField.returnKeyType = .done
            pickerField.delegate = self
        }
    }
    @IBOutlet weak var authField: UITextField! {
        didSet {
            authField.returnKeyType = .done
            authField.delegate = self
        }
    }
    @IBOutlet var advancedPublicKeyField: UITextField! {
        didSet {
            advancedPublicKeyField.returnKeyType = .done
            advancedPublicKeyField.delegate = self
        }
    }

    @IBOutlet weak var urlField: UITextField! {
        didSet {
            urlField.returnKeyType = .done
            urlField.delegate = self
        }
    }
    
    @IBOutlet weak var applicationIDField: UITextField! {
        didSet {
            applicationIDField.returnKeyType = .done
            applicationIDField.delegate = self
        }
    }

    /// Shown only when Stream is selected. Optional "registered" customer ID to configure SDK with at startup.
    @IBOutlet weak var streamRegisteredIdField: UITextField! {
        didSet {
            streamRegisteredIdField?.returnKeyType = .done
            streamRegisteredIdField?.delegate = self
        }
    }
    @IBOutlet weak var streamRegisteredIdFieldHeightConstraint: NSLayoutConstraint?

    @IBOutlet weak var tokenField: UITextField! {
        didSet {
            tokenField.returnKeyType = .done
            tokenField.delegate = self
            tokenField.addTarget(self, action: #selector(tokenUpdated), for: .editingChanged)
        }
    }
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var clearDataButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!

    private let options = AuthType.allCases
    private let picker = UIPickerView()
    private var pickedOption = AuthType.stream

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDropdown()
        setupRightIcon()
        setupKeyboardOffset()
        updateAuthFieldsForCurrentMode()
        urlField.attributedPlaceholder = makePlaceholderText(text: urlField.placeholder)
        applicationIDField.attributedPlaceholder = makePlaceholderText(text: applicationIDField.placeholder)
        tokenUpdated()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    private func setupKeyboardOffset() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        scrollView?.addGestureRecognizer(tap)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameEnd = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        let keyboardTop = view.convert(frameEnd, from: nil).minY
        let bottomInset = max(0, view.bounds.maxY - keyboardTop)
        UIView.animate(withDuration: duration) { [weak self] in
            self?.scrollView?.contentInset.bottom = bottomInset
            self?.scrollView?.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    /// Updates auth/advanced field placeholders and Stream-only field visibility based on pickedOption.
    private func updateAuthFieldsForCurrentMode() {
        switch pickedOption {
        case .project:
            authField.placeholder = "Authorization (optional)"
            advancedPublicKeyField.placeholder = "Advanced Auth (optional)"
            authField.attributedPlaceholder = makePlaceholderText(text: "Authorization (optional)")
            advancedPublicKeyField.attributedPlaceholder = makePlaceholderText(text: "Advanced Auth (optional)")
            streamRegisteredIdField?.isHidden = true
            streamRegisteredIdFieldHeightConstraint?.constant = 0
        case .stream:
            authField.placeholder = "Key ID (optional)"
            advancedPublicKeyField.placeholder = "Key secret (optional)"
            authField.attributedPlaceholder = makePlaceholderText(text: "Key ID (optional)")
            advancedPublicKeyField.attributedPlaceholder = makePlaceholderText(text: "Key secret (optional)")
            streamRegisteredIdField?.placeholder = "Registered customer ID (optional)"
            streamRegisteredIdField?.attributedPlaceholder = makePlaceholderText(text: "Registered customer ID (optional)")
            streamRegisteredIdField?.isHidden = false
            streamRegisteredIdFieldHeightConstraint?.constant = 40
        }
    }
    
    private func setupDropdown() {
        picker.delegate = self
        picker.dataSource = self
        
        // Use picker instead of keyboard
        pickerField.inputView = picker
        
        // Optional: prevent manual typing (dropdown only)
        pickerField.delegate = self
        
        // Optional: default selection
        if !options.isEmpty {
            pickerField.text = options[0].rawValue
            picker.selectRow(0, inComponent: 0, animated: false)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
            tapGesture.cancelsTouchesInView = false  // important: don’t block other controls
            view.addGestureRecognizer(tapGesture)
    }
    
    private func setupRightIcon() {
        let padding: CGFloat = 8
        let iconWidth: CGFloat = 20
        let iconHeight: CGFloat = 20
        
        let button = UIButton(type: .system)
        
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "chevron.down")
            button.setImage(image, for: .normal)
        } else {
            let image = UIImage(named: "chevron_down")
            button.setImage(image, for: .normal)
        }
        
        button.tintColor = .secondaryLabel
        
        // Make the rightView wider than the icon so we have padding space
        let totalWidth = iconWidth + padding
        button.frame = CGRect(x: 0, y: 0, width: totalWidth, height: iconHeight)
        
        // Push the image left inside the button, creating empty space on the right
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: padding)
        
        button.addTarget(self, action: #selector(rightIconTapped), for: .touchUpInside)
        
        pickerField.rightView = button
        pickerField.rightViewMode = .always
    }
    @objc private func rightIconTapped() {
        pickerField.becomeFirstResponder()
    }

    private func makePlaceholderText(text: String?) -> NSAttributedString {
        return NSAttributedString(
            string: text ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
    }
    
    @IBAction func clearTapped() {
        MockJwtService.shared.clear()
        Exponea.shared.clearLocalCustomerData(appGroup: "group.com.exponea.sdk.example")
    }

    @IBAction func startPressed() {
        guard let token = tokenField.text else {
            return
        }

        // Stream: key id and key secret must both be filled or both empty; when either is filled, registered customer ID is required
        if pickedOption == .stream {
            let keyIdFilled = (authField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            let keySecretFilled = (advancedPublicKeyField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            let registeredIdFilled = (streamRegisteredIdField?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

            if keyIdFilled != keySecretFilled {
                let message = keyIdFilled
                    ? "Please enter Key secret when Key ID is provided. When Key ID or Key secret is filled, Registered customer ID is also required."
                    : "Please enter Key ID when Key secret is provided. When Key ID or Key secret is filled, Registered customer ID is also required."
                let alert = UIAlertController(title: "Missing Value", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            if (keyIdFilled || keySecretFilled) && !registeredIdFilled {
                let alert = UIAlertController(
                    title: "Missing Value",
                    message: "When Key ID or Key secret is filled, Registered customer ID must also be filled.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
        }

        var auth: ExponeaSDK.Authorization = Authorization.none

        if let text = authField.text, !text.isEmpty {
            auth = .token(text)
        }

        var advancedAuthPubKey: String?
        if let text = advancedPublicKeyField.text, !text.isEmpty {
            advancedAuthPubKey = text
        }
        var baseUrl: String?
        if let text = urlField.text, !text.isEmpty {
            baseUrl = text
        }

        // CustomerTokenStorage only for Project mode (advanced auth / customer tokens)
        if pickedOption == .project {
            CustomerTokenStorage.shared.configure(
                host: baseUrl,
                projectToken: token,
                publicKey: advancedAuthPubKey,
                expiration: nil
            )
        }
        // Stream JWT is stored only in SDK (KeychainJwtTokenStore), not in CustomerTokenStorage

        var applicationID: String?
        if let text = applicationIDField.text {
            applicationID = text
        }

        let exponea = Exponea.shared.onInitSucceeded { [weak self] in
            guard let self = self else {
                Exponea.logger.log(.error, message: "Configuration initialization failed") 
                return
            }
            Exponea.logger.log(.verbose, message: "Configuration initialization succeeded")

            // Set up Stream JWT and optional initial customer identity when in Stream mode
            if self.pickedOption == .stream {
                
                // Stream: use Mock JWT service – Key ID (kid) + Key secret generate a demo JWT with customer ids in payload
                var streamJwt: String?
                let streamRegisteredId = (pickedOption == .stream ? streamRegisteredIdField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) : nil).flatMap { $0.isEmpty ? nil : $0 }
                let customerIds: [String: String] = streamRegisteredId.map { ["registered": $0] } ?? [:]

                if let keyId = self.authField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !keyId.isEmpty,
                   let keySecret = advancedPublicKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !keySecret.isEmpty {
                    MockJwtService.shared.configure(secret: keySecret, kid: keyId)
                    streamJwt = MockJwtService.shared.generateToken(customerIds: customerIds)
                } else {
                    MockJwtService.shared.clear()
                }

                self.setupStreamJwtHandling(initialJwt: streamJwt, customerIds: customerIds)

                if let registeredId = streamRegisteredId, !registeredId.isEmpty {
                    let identity = CustomerIdentity(
                        customerIds: ["registered": registeredId],
                        jwtToken: streamJwt
                    )
                    Exponea.shared.identifyCustomer(context: identity, properties: [:], timestamp: nil)
                    Exponea.logger.log(.verbose, message: "Configured with registered customer ID: \(registeredId)")
                }
            }

            // Uncomment if you want to test in-app message delegate
//            Exponea.shared.inAppMessagesDelegate = InAppDelegate(overrideDefaultBehavior: true, trackActions: false)
            Coordinator(navigationController: self.navigationController).start()
        }
        Exponea.logger.logLevel = .verbose
        exponea.checkPushSetup = true
        Exponea.logger.log(.verbose, message: "Before Configuration call")
        var setup: any IntegrationType = {
            switch pickedOption {
            case .project:
                return Exponea.ProjectSettings(
                    projectToken: token,
                    authorization: auth,
                    baseUrl: baseUrl
                )
            case .stream:
                return Exponea.StreamSettings(
                    streamId: token,
                    baseUrl: baseUrl
                )
            }
        }()
        exponea.configure(
            setup,
            pushNotificationTracking: .enabled(
                appGroup: "group.com.exponea.sdk.example",
                delegate: UIApplication.shared.delegate as? AppDelegate
            ),
            defaultProperties: [
                "Property01": "String value",
                "Property02": 123
            ],
            advancedAuthEnabled: isAdvancedAuthEnabled(advancedAuthPubKey: advancedAuthPubKey),
            applicationID: applicationID
        )
        exponea.inAppMessagesDelegate = TestDefaultInAppDelegate()
        Exponea.logger.log(.verbose, message: "After Configuration call")
        Exponea.shared.appInboxProvider = ExampleAppInboxProvider()
    }
    
    private func isAdvancedAuthEnabled(advancedAuthPubKey: String?) -> Bool {
        switch pickedOption {
        case .stream:
            return false
        case .project:
            return advancedAuthPubKey?.isEmpty == false
        }
    }
    
    /// Sets up Stream JWT handling: initial token (stored in SDK Keychain via setSdkAuthToken), error handler for refresh, and Bearer header usage.
    /// When a JWT is set, the SDK attaches it as "Authorization: Bearer <token>" to Tracking and WebXP requests.
    /// KeychainJwtTokenStore is used only for Stream; CustomerTokenStorage is not used in Stream mode.
    private func setupStreamJwtHandling(initialJwt: String?, customerIds: [String: String]) {
        // Set initial JWT token if provided (SDK persists it in KeychainJwtTokenStore)
        if let jwt = initialJwt {
            Exponea.shared.setSdkAuthToken(jwt)
            Exponea.logger.log(.verbose, message: "Stream JWT token set; SDK will attach Authorization: Bearer to Tracking/WebXP requests")
        }

        // JWT error handler: refresh token (Example uses MockJwtService; real apps use backend)
        Exponea.shared.setJwtErrorHandler { [weak self] context in
            Exponea.logger.log(.warning, message: "JWT Error: reason=\(context.reason)")

            switch context.reason {
            case .expired, .expiredSoon, .invalid, .notProvided:
                if MockJwtService.shared.isConfigured {
                    let ids = context.customerIds ?? customerIds
                    if let newToken = MockJwtService.shared.generateToken(customerIds: ids) {
                        Exponea.shared.setSdkAuthToken(newToken)
                        Exponea.logger.log(.verbose, message: "JWT refreshed via MockJwtService and set via setSdkAuthToken")
                    }
                } else {
                    Exponea.logger.log(.warning, message: "JWT token needs refresh – provide new token via setSdkAuthToken (e.g. from your backend)")
                }
            case .insufficient:
                Exponea.logger.log(.error, message: "JWT has insufficient permissions for this operation")
            }
        }
    }

    @objc func tokenUpdated() {
        startButton.isEnabled = (tokenField.text ?? "").count > 0
        startButton.alpha = startButton.isEnabled ? 1.0 : 0.4
    }

    @IBAction func hideKeyboard() {
        view.endEditing(true)
    }
}

extension AuthenticationViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {}
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Disallow manual editing; use picker only
        
        return textField != pickerField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

public class TestDefaultInAppDelegate: InAppMessageActionDelegate {
    public let overrideDefaultBehavior = false
    public let trackActions = true

    public func inAppMessageShown(message: InAppMessage) {
        if message.name.lowercased().contains("stop") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                Exponea.shared.stopIntegration()
            }
        }
    }
    public func inAppMessageError(message: InAppMessage?, errorMessage: String) {}
    public func inAppMessageClickAction(message: InAppMessage, button: InAppMessageButton) {
        if messageIsForGdpr(message) {
            handleGdprUserResponse(button: button)
        }
    }
    public func inAppMessageCloseAction(message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
        if messageIsForGdpr(message), interaction {
            Exponea.shared.stopIntegration()
        }
    }

    private func messageIsForGdpr(_ message: InAppMessage) -> Bool {
        message.name.uppercased().contains("GDPR")
    }

    private func handleGdprUserResponse(button: InAppMessageButton) {
        guard let url = button.url else { return }
        switch url {
        case "https://bloomreach.com/tracking/allow":
            Exponea.shared.trackEvent(
                properties: [
                    "status": "allowed"
                ],
                timestamp: nil,
                eventType: "gdpr"
            )
        case "https://bloomreach.com/tracking/deny":
            Exponea.shared.stopIntegration()
        default:
            break
        }
    }
}

private extension AuthenticationViewController {
    enum AuthType: String, CaseIterable {
        case stream = "Stream ID"
        case project = "Project token"
    }
}

extension AuthenticationViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        numberOfRowsInComponent component: Int
    ) -> Int {
        options.count
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        options[row].rawValue
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        pickerField.text = options[row].rawValue
        if options[row] != pickedOption {
            tokenField.text = ""
            authField.text = ""
            advancedPublicKeyField.text = ""
            streamRegisteredIdField?.text = ""
            tokenUpdated()
        }
        pickedOption = options[row]
        tokenField.placeholder = options[row].rawValue
        updateAuthFieldsForCurrentMode()
        tokenUpdated()
    }
}
