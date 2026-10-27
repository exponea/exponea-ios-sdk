import Foundation
import ExponeaSDK

enum FlushingScreenTab: String, CaseIterable, Identifiable {
    case flushMode = "Flush Mode"
    case flushPeriod = "Flush Period"
    case logLevel = "Log Level"

    var id: String { rawValue }
}

@MainActor
final class FlushingViewModel: ObservableObject {

    @Published var selectedTab: FlushingScreenTab = .flushMode
    @Published var currentModeLabel = "…"
    @Published var currentPeriodLabel = "…"
    @Published var currentLogLevelLabel = "…"
    @Published var feedback: String?
    @Published var showFlushResultDialog = false
    @Published var flushResultTitle = ""
    @Published var flushResultMessage: String?
    @Published var isFlushing = false

    private var logLevelDisplayOverride: String?

    func onAppear() {
        refreshAll()
    }

    func refreshAll() {
        refreshMode()
        refreshPeriod()
        refreshLogLevel()
    }

    func refreshMode(showFeedback: Bool = false) {
        let mode = ExponeaService.flushingMode
        currentModeLabel = Self.modeLabel(for: mode)
        refreshPeriod()
        if showFeedback {
            showFeedbackBanner("Current mode: \(currentModeLabel)")
        }
    }

    func refreshPeriod(showFeedback: Bool = false) {
        let mode = ExponeaService.flushingMode
        guard case let .periodic(seconds) = mode else {
            currentPeriodLabel = "—"
            if showFeedback {
                showFeedbackBanner(periodGuardMessage(for: mode))
            }
            return
        }
        currentPeriodLabel = "\(seconds)"
        if showFeedback {
            showFeedbackBanner("Current period: \(seconds) seconds")
        }
    }

    func refreshLogLevel(showFeedback: Bool = false) {
        if let override = logLevelDisplayOverride {
            currentLogLevelLabel = override
        } else {
            currentLogLevelLabel = Self.logLevelLabel(for: ExponeaService.logLevel)
        }
        if showFeedback {
            showFeedbackBanner("Current log level: \(currentLogLevelLabel)")
        }
    }

    func setFlushModeImmediate() {
        applyFlushMode(.immediate)
    }

    func setFlushModePeriod() {
        let seconds = currentPeriodicSeconds(default: 30)
        applyFlushMode(.periodic(seconds))
    }

    func setFlushModeAppClose() {
        applyFlushMode(.automatic)
    }

    func setFlushModeManual() {
        applyFlushMode(.manual)
    }

    func setFlushPeriod30() {
        setPeriodicInterval(30)
    }

    func setFlushPeriod60() {
        setPeriodicInterval(60)
    }

    func flushData() {
        isFlushing = true
        ExponeaService.flushData { [weak self] outcome in
            guard let self else { return }
            self.isFlushing = false
            self.flushResultTitle = outcome.succeeded ? "Flush successful" : "Flush failed"
            self.flushResultMessage = outcome.succeeded ? nil : outcome.message
            self.showFlushResultDialog = true
        }
    }

    func setLogLevelOff() {
        applyLogLevel(sdk: .none, display: "OFF")
    }

    func setLogLevelError() {
        applyLogLevel(sdk: .error, display: "ERROR")
    }

    func setLogLevelWarn() {
        applyLogLevel(sdk: .warning, display: "WARN")
    }

    // The iOS SDK has no INFO or DEBUG level (only none, error, warning and verbose), so both set VERBOSE.
    // The screen keeps showing the chosen label because the shared automation tests read it back.
    func setLogLevelInfo() {
        applyVerboseLogLevel(display: "INFO")
    }

    func setLogLevelDebug() {
        applyVerboseLogLevel(display: "DEBUG")
    }

    private func applyVerboseLogLevel(display: String) {
        logLevelDisplayOverride = display
        ExponeaService.logLevel = .verbose
        currentLogLevelLabel = display
        InAppLogStore.shared.append(
            level: .verbose,
            message: "The iOS SDK has no \(display) log level; the SDK logs at VERBOSE"
        )
    }

    func setLogLevelVerbose() {
        applyLogLevel(sdk: .verbose, display: "VERBOSE")
    }

    private func applyFlushMode(_ mode: FlushingMode) {
        ExponeaService.flushingMode = mode
        refreshMode()
    }

    private func setPeriodicInterval(_ seconds: Int) {
        let mode = ExponeaService.flushingMode
        guard case .periodic = mode else {
            showFeedbackBanner(periodGuardMessage(for: mode))
            return
        }
        ExponeaService.flushingMode = .periodic(seconds)
        refreshPeriod()
        showFeedbackBanner("Flush period → \(seconds) seconds")
    }

    private func applyLogLevel(sdk: LogLevel, display: String) {
        logLevelDisplayOverride = nil
        ExponeaService.logLevel = sdk
        currentLogLevelLabel = display
    }

    private func currentPeriodicSeconds(default defaultValue: Int) -> Int {
        if case let .periodic(seconds) = ExponeaService.flushingMode, seconds > 0 {
            return seconds
        }
        return defaultValue
    }

    private func periodGuardMessage(for mode: FlushingMode) -> String {
        "Flush period requires PERIOD mode (current: \(Self.modeLabel(for: mode))). Tap PERIOD first."
    }

    private func showFeedbackBanner(_ message: String) {
        feedback = message
    }

    static func modeLabel(for mode: FlushingMode) -> String {
        switch mode {
        case .immediate: return "IMMEDIATE"
        case .manual: return "MANUAL"
        case .automatic: return "APP_CLOSE"
        case .periodic: return "PERIOD"
        }
    }

    static func logLevelLabel(for level: LogLevel) -> String {
        switch level {
        case .none: return "OFF"
        case .error: return "ERROR"
        case .warning: return "WARN"
        case .verbose: return "VERBOSE"
        }
    }
}
