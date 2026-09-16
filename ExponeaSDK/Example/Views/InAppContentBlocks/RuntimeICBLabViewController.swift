//
//  RuntimeICBLabViewController.swift
//  Example
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

final class RuntimeICBLabViewController: UIViewController {

    private enum StorageKey {
        static let placeholderIds = "RuntimeICBLab.placeholderIds"
        static let deadlineSeconds = "RuntimeICBLab.deadlineSeconds"
        static let mirrorSdkLogs = "RuntimeICBLab.mirrorSdkLogs"
    }

    private enum LogCategory: String {
        case session = "SESSION"
        case action = "ACTION"
        case result = "RESULT"
        case scenario = "SCENARIO"
        case sdk = "SDK"
        case view = "VIEW"
        case warn = "WARN"
    }

    private let defaultPlaceholderIds = "example_top, ph_x_example_iOS"
    private let defaultDeadlineSeconds = "3"

    private let sessionId = String(UUID().uuidString.prefix(8)).uppercased()
    private var logSequence = 0
    private var isLifecycleProbeRunning = false
    private var isScenarioRunning = false

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let statusLabel = UILabel()
    private let idsTextView = UITextView()
    private let deadlineField = UITextField()
    private let mirrorLogsSwitch = UISwitch()
    private let placeholdersStack = UIStackView()
    private let logTextView = UITextView()

    private var mountedViews: [StaticInAppContentBlockView] = []
    private var previousMemoryLoggerDelegate: MemoryLoggerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Runtime ICB Lab"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearLog)),
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLog)),
            UIBarButtonItem(title: "Copy", style: .plain, target: self, action: #selector(copyLog))
        ]
        configureLayout()
        restorePersistedValues()
        refreshControllerStatus()
        logSessionHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousMemoryLoggerDelegate = AppDelegate.memoryLogger.delegate
        AppDelegate.memoryLogger.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        persistValues()
        AppDelegate.memoryLogger.delegate = previousMemoryLoggerDelegate
    }

    // MARK: - Layout

    private func configureLayout() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)

        idsTextView.font = .preferredFont(forTextStyle: .body)
        idsTextView.layer.borderColor = UIColor.separator.cgColor
        idsTextView.layer.borderWidth = 1
        idsTextView.layer.cornerRadius = 6
        idsTextView.heightAnchor.constraint(equalToConstant: 72).isActive = true

        deadlineField.borderStyle = .roundedRect
        deadlineField.keyboardType = .decimalPad
        deadlineField.placeholder = "Availability deadline in seconds"

        mirrorLogsSwitch.isOn = true
        mirrorLogsSwitch.addTarget(self, action: #selector(mirrorSwitchChanged), for: .valueChanged)

        placeholdersStack.axis = .vertical
        placeholdersStack.spacing = 8

        logTextView.isEditable = false
        logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.layer.borderColor = UIColor.separator.cgColor
        logTextView.layer.borderWidth = 1
        logTextView.layer.cornerRadius = 6
        logTextView.heightAnchor.constraint(equalToConstant: 320).isActive = true

        contentStack.addArrangedSubview(statusLabel)
        contentStack.addArrangedSubview(makeSectionHeader("Inputs"))
        contentStack.addArrangedSubview(makeCaption("Placeholder IDs (comma-separated)"))
        contentStack.addArrangedSubview(idsTextView)
        contentStack.addArrangedSubview(makeCaption("Availability deadline (seconds)"))
        contentStack.addArrangedSubview(deadlineField)
        contentStack.addArrangedSubview(makeMirrorRow())

        contentStack.addArrangedSubview(makeCaption("Mounted views"))
        contentStack.addArrangedSubview(placeholdersStack)

        contentStack.addArrangedSubview(makeSectionHeader("Scenarios"))
        contentStack.addArrangedSubview(makeButton("1. Happy path: prefetch -> mount -> load", action: #selector(scenarioHappyPathTapped)))
        contentStack.addArrangedSubview(makeButton("2. Invalidate: prefetch -> eager invalidate -> availability", action: #selector(scenarioInvalidateTapped)))
        contentStack.addArrangedSubview(makeButton("3. Post-login CMS: identify (eager reload) -> prefetch reuses catalog -> mount -> load", action: #selector(scenarioPostLoginTapped)))
        contentStack.addArrangedSubview(makeButton("4. Logout: prefetch -> anonymize (eager reload) -> controller prefetch", action: #selector(scenarioLogoutDeferredTapped)))
        contentStack.addArrangedSubview(makeButton("5. Dual entry: manager prefetch -> controller prefetch", action: #selector(scenarioDualEntryTapped)))
        contentStack.addArrangedSubview(makeButton("6. Availability timeout (1ms deadline after invalidate)", action: #selector(scenarioAvailabilityTimeoutTapped)))
        contentStack.addArrangedSubview(makeButton("7. Anonymize lifecycle probe", action: #selector(lifecycleProbeTapped)))
        contentStack.addArrangedSubview(makeButton("8. Identity switch: user_a -> prefetch -> user_b -> prefetch", action: #selector(scenarioIdentitySwitchTapped)))
        contentStack.addArrangedSubview(makeButton("9. Lazy invalidate: prefetch -> lazy invalidate -> pause -> prefetch (fresh fetch on 2nd call)", action: #selector(scenarioLazyInvalidateTapped)))

        contentStack.addArrangedSubview(makeSectionHeader("Log"))
        contentStack.addArrangedSubview(logTextView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func makeMirrorRow() -> UIStackView {
        let label = UILabel()
        label.text = "Mirror ICB-related SDK logs"
        label.font = .preferredFont(forTextStyle: .footnote)
        let row = UIStackView(arrangedSubviews: [label, mirrorLogsSwitch])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .equalSpacing
        return row
    }

    // MARK: - Actions

    @objc private func endEditing() {
        view.endEditing(true)
        persistValues()
    }

    @objc private func mirrorSwitchChanged() {
        persistValues()
        log(.action, "mirror_sdk_logs=\(mirrorLogsSwitch.isOn)")
    }

    // MARK: - View helpers

    private func mountTapped() {
        persistValues()
        guard let ids = requireIds() else { return }
        unmountViews()
        log(.view, "mount deferred views ids=\(ids.joined(separator: ", "))")
        for id in ids {
            let placeholder = StaticInAppContentBlockView(placeholder: id, deferredLoad: true)
            placeholder.behaviourCallback = ExampleInAppContentBlockCallback(
                originalBehaviour: placeholder.behaviourCallback,
                ownerView: placeholder
            )
            placeholder.contentReadyCompletion = { [weak self] loaded in
                self?.log(.view, "contentReady placeholder=\(id) loaded=\(loaded)")
            }
            placeholdersStack.addArrangedSubview(placeholder)
            mountedViews.append(placeholder)
        }
        log(.view, "mounted_count=\(mountedViews.count) (not loaded yet)")
    }

    private func loadMountedTapped() {
        guard !mountedViews.isEmpty else {
            log(.warn, "no mounted views to load")
            return
        }
        log(.view, "load mounted_count=\(mountedViews.count)")
        mountedViews.forEach { $0.load() }
    }

    private func identify(registeredId: String) {
        log(.action, "identify registered=\(registeredId)")
        Exponea.shared.identifyCustomer(
            context: CustomerIdentity(customerIds: ["registered": registeredId]),
            properties: [:],
            timestamp: nil
        )
        refreshControllerStatus()
    }

    // MARK: - Automated scenarios

    @objc private func scenarioHappyPathTapped() {
        runScenario("happy_path") { ids, controller, done in
            controller.prefetch(ids: ids) { [weak self] _ in
                onMain {
                    guard let self else { done(); return }
                    self.mountTapped()
                    self.loadMountedTapped()
                    done()
                }
            }
        }
    }

    @objc private func scenarioInvalidateTapped() {
        runScenario("eager_invalidate") { ids, controller, done in
            controller.prefetch(ids: ids) { [weak self] _ in
                onMain {
                    guard let self else { done(); return }
                    controller.invalidate(ids: ids, reason: "promo code refresh", mode: .eager)
                    self.checkAvailabilityForScenario(ids: ids, controller: controller, index: 0, done: done)
                }
            }
        }
    }

    @objc private func scenarioPostLoginTapped() {
        runScenario("post_login_cms") { ids, controller, done in
            self.identify(registeredId: "user_a")
            controller.prefetch(ids: ids) { [weak self] _ in
                onMain {
                    guard let self else { done(); return }
                    self.mountTapped()
                    self.loadMountedTapped()
                    done()
                }
            }
        }
    }

    @objc private func scenarioLogoutDeferredTapped() {
        runScenario("logout") { ids, controller, done in
            controller.prefetch(ids: ids) { [weak self] _ in
                onMain {
                    guard let self else { done(); return }
                    Exponea.shared.anonymize { [weak self] in
                        onMain {
                            guard let self else { done(); return }
                            controller.prefetch(ids: ids) { _ in
                                onMain { done() }
                            }
                        }
                    }
                }
            }
        }
    }

    @objc private func scenarioDualEntryTapped() {
        runScenario("dual_entry") { ids, controller, done in
            guard let manager = Exponea.shared.inAppContentBlocksManager else {
                self.log(.warn, "manager is nil")
                done()
                return
            }
            manager.prefetchPlaceholdersWithIds(ids: ids)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                controller.prefetch(ids: ids) { _ in onMain { done() } }
            }
        }
    }

    @objc private func scenarioAvailabilityTimeoutTapped() {
        runScenario("availability_timeout") { ids, controller, done in
            guard let firstId = ids.first else {
                self.log(.warn, "need at least one placeholder ID")
                done()
                return
            }
            controller.invalidate(ids: ids, reason: "availability timeout test", mode: .eager)
            controller.availability(id: firstId, deadline: 0.001) { _ in onMain { done() } }
        }
    }

    @objc private func lifecycleProbeTapped() {
        persistValues()
        guard !isLifecycleProbeRunning else {
            log(.warn, "probe already running")
            return
        }
        guard let controller = requireController(), let ids = requireIds() else { return }

        isLifecycleProbeRunning = true
        controller.prefetch(ids: ids) { [weak self] _ in
            onMain {
                guard let self else { return }
                Exponea.shared.anonymize { [weak self] in
                    onMain {
                        guard let self else { return }
                        self.runImmediatePostAnonymizePrefetch(ids: ids)
                    }
                }
            }
        }
    }

    private func runImmediatePostAnonymizePrefetch(ids: [String]) {
        guard let controller = Exponea.shared.inAppContentBlocksController else {
            log(.warn, "lifecycle_probe: controller nil after anonymize")
            isLifecycleProbeRunning = false
            return
        }

        controller.prefetch(ids: ids) { [weak self] _ in
            onMain {
                guard let self else { return }
                self.runSettledPostAnonymizePrefetch(ids: ids)
            }
        }
    }

    private func runSettledPostAnonymizePrefetch(ids: [String]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self, let controller = Exponea.shared.inAppContentBlocksController else {
                self?.log(.warn, "lifecycle_probe: controller unavailable before step4")
                self?.isLifecycleProbeRunning = false
                return
            }
            controller.prefetch(ids: ids) { [weak self] _ in
                onMain { self?.isLifecycleProbeRunning = false }
            }
        }
    }

    @objc private func scenarioIdentitySwitchTapped() {
        runScenario("identity_switch") { ids, controller, done in
            self.identify(registeredId: "user_a")
            controller.prefetch(ids: ids) { [weak self] _ in
                onMain {
                    guard let self else { done(); return }
                    self.identify(registeredId: "user_b")
                    controller.prefetch(ids: ids) { _ in onMain { done() } }
                }
            }
        }
    }

    @objc private func scenarioLazyInvalidateTapped() {
        runScenario("lazy_invalidate") { ids, controller, done in
            controller.prefetch(ids: ids) { [weak self] _ in
                onMain {
                    guard let self else { done(); return }
                    controller.invalidate(ids: ids, reason: "lazy content refresh", mode: .lazy)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        controller.prefetch(ids: ids) { _ in onMain { done() } }
                    }
                }
            }
        }
    }

    private func checkAvailabilityForScenario(
        ids: [String],
        controller: RuntimeInContentBlockControllerType,
        index: Int,
        done: @escaping () -> Void
    ) {
        guard index < ids.count else {
            done()
            return
        }
        let id = ids[index]
        controller.availability(id: id, deadline: parsedDeadline()) { [weak self] _ in
            onMain {
                guard let self else { done(); return }
                self.checkAvailabilityForScenario(ids: ids, controller: controller, index: index + 1, done: done)
            }
        }
    }

    private func runScenario(
        _ name: String,
        steps: @escaping (_ ids: [String], _ controller: RuntimeInContentBlockControllerType, _ done: @escaping () -> Void) -> Void
    ) {
        persistValues()
        guard !isScenarioRunning else {
            log(.warn, "scenario already running; wait for completion")
            return
        }
        guard let controller = requireController(), let ids = requireIds() else { return }
        isScenarioRunning = true
        log(.scenario, "BEGIN \(name) ids=\(ids.joined(separator: ", "))")
        steps(ids, controller) { [weak self] in
            onMain {
                self?.log(.scenario, "END \(name)")
                self?.isScenarioRunning = false
                self?.refreshControllerStatus()
            }
        }
    }

    // MARK: - Log export

    @objc private func clearLog() {
        logTextView.text = ""
        logSequence = 0
        logSessionHeader()
    }

    @objc private func copyLog() {
        UIPasteboard.general.string = fullLogText()
        log(.action, "log copied to pasteboard (\(fullLogText().count) chars)")
    }

    @objc private func shareLog() {
        let text = fullLogText()
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        present(activity, animated: true)
    }

    // MARK: - Helpers

    private func requireController() -> RuntimeInContentBlockControllerType? {
        refreshControllerStatus()
        guard let controller = Exponea.shared.inAppContentBlocksController else {
            log(.warn, "controller is nil")
            return nil
        }
        return controller
    }

    private func requireIds() -> [String]? {
        let ids = parsedIds()
        guard !ids.isEmpty else {
            log(.warn, "enter at least one placeholder ID")
            return nil
        }
        return ids
    }

    private func parsedIds() -> [String] {
        (idsTextView.text ?? "")
            .split { $0 == "," || $0.isNewline }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parsedDeadline() -> TimeInterval {
        let raw = deadlineField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let value = TimeInterval(raw), value > 0 {
            return value
        }
        return TimeInterval(defaultDeadlineSeconds) ?? 3
    }

    private func restorePersistedValues() {
        let storedIds = UserDefaults.standard.string(forKey: StorageKey.placeholderIds)
        idsTextView.text = (storedIds?.isEmpty == false) ? storedIds : defaultPlaceholderIds
        let storedDeadline = UserDefaults.standard.string(forKey: StorageKey.deadlineSeconds)
        deadlineField.text = (storedDeadline?.isEmpty == false) ? storedDeadline : defaultDeadlineSeconds
        if UserDefaults.standard.object(forKey: StorageKey.mirrorSdkLogs) != nil {
            mirrorLogsSwitch.isOn = UserDefaults.standard.bool(forKey: StorageKey.mirrorSdkLogs)
        }
    }

    private func persistValues() {
        UserDefaults.standard.set(idsTextView.text ?? "", forKey: StorageKey.placeholderIds)
        UserDefaults.standard.set(deadlineField.text ?? "", forKey: StorageKey.deadlineSeconds)
        UserDefaults.standard.set(mirrorLogsSwitch.isOn, forKey: StorageKey.mirrorSdkLogs)
    }

    private func refreshControllerStatus() {
        let controllerPresent = Exponea.shared.inAppContentBlocksController != nil
        let managerPresent = Exponea.shared.inAppContentBlocksManager != nil
        statusLabel.text = """
        Session: \(sessionId)
        Controller: \(controllerPresent ? "present" : "nil")
        Manager: \(managerPresent ? "present" : "nil")
        SDK log level: \(Exponea.logger.logLevel.name)
        """
        statusLabel.textColor = controllerPresent ? .label : .systemRed
    }

    private func unmountViews() {
        mountedViews.forEach { $0.removeFromSuperview() }
        mountedViews.removeAll()
        placeholdersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    private func logSessionHeader() {
        appendLine(
            category: .session,
            message: "=== ICB LAB SESSION START session=\(sessionId) ==="
        )
        appendLine(
            category: .session,
            message: "placeholders=\(parsedIds().joined(separator: ", ")) deadline=\(parsedDeadline())s"
        )
        appendLine(
            category: .session,
            message: "tip: run scenarios, then Copy or Share log for export"
        )
        appendLine(category: .session, message: "=== END HEADER ===")
    }

    private func log(_ category: LogCategory, _ message: String) {
        appendLine(category: category, message: message)
        Exponea.logger.log(.verbose, message: "[ICB-LAB|\(sessionId)|\(category.rawValue)] \(message)")
    }

    private func appendLine(category: LogCategory, message: String) {
        logSequence += 1
        let timestamp = Self.logDateFormatter.string(from: Date())
        let line = "[\(sessionId)] #\(String(format: "%03d", logSequence)) [\(timestamp)] [\(category.rawValue)] \(message)"
        if logTextView.text?.isEmpty == false {
            logTextView.text += "\n" + line
        } else {
            logTextView.text = line
        }
        let end = NSRange(location: max(logTextView.text.count - 1, 0), length: 1)
        logTextView.scrollRangeToVisible(end)
    }

    private func fullLogText() -> String {
        let header = """
        Runtime ICB Lab export
        session=\(sessionId)
        exported_at=\(ISO8601DateFormatter().string(from: Date()))
        placeholders=\(parsedIds().joined(separator: ", "))
        deadline=\(parsedDeadline())s

        """
        return header + (logTextView.text ?? "")
    }

    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private static let sdkMirrorKeywords = [
        "runtime icb",
        "in-app content block",
        "inapp content",
        "content_block",
        "catalog",
        "personalized",
        "prefetch",
        "invalidate",
        "anonymize",
        "identify",
        "icb lab"
    ]

    private func shouldMirrorSdkLog(_ message: String) -> Bool {
        let lower = message.lowercased()
        return Self.sdkMirrorKeywords.contains { lower.contains($0) }
    }
}

extension RuntimeICBLabViewController: MemoryLoggerDelegate {
    func logUpdated() {
        guard mirrorLogsSwitch.isOn else { return }
        guard let last = AppDelegate.memoryLogger.logs.last else { return }
        let message = last
        guard shouldMirrorSdkLog(message) else { return }
        let mirrorLine = message.hasPrefix("[ICB-LAB|") ? nil : message
        guard let mirrorLine else { return }
        onMain {
            self.appendLine(category: .sdk, message: mirrorLine)
        }
    }
}
