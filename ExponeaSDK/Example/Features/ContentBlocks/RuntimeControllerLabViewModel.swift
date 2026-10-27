import Foundation
import UIKit
import ExponeaSDK

/// Scenarios of the runtime in-app content block controller lab. Keep the scenario names, their order and
/// the log line format stable so runs stay comparable.
enum RuntimeLabScenario: String, CaseIterable, Identifiable {
    case prefetch = "prefetch"
    case availability = "availability"
    case eagerInvalidate = "eager invalidate"
    case happyPath = "happy path"
    case postLoginCMS = "post-login CMS"
    case logout = "logout"
    case availabilityTimeout = "availability timeout"
    case anonymizeLifecycleProbe = "anonymize lifecycle probe"
    case identitySwitch = "identity switch"
    case lazyInvalidate = "lazy invalidate"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prefetch: return "Prefetch"
        case .availability: return "Availability"
        case .eagerInvalidate: return "Prefetch → eager invalidate → availability"
        default: return rawValue
        }
    }

    var identifier: String? {
        switch self {
        case .prefetch: return A11yID.contentBlocks.runtimePrefetch
        case .availability: return A11yID.contentBlocks.runtimeAvailability
        case .eagerInvalidate: return A11yID.contentBlocks.runtimeInvalidate
        case .logout: return A11yID.contentBlocks.runtimeLogout
        default: return nil
        }
    }
}

@MainActor
final class RuntimeControllerLabViewModel: ObservableObject {

    private enum Constants {
        static let defaultDeadlineMs = 3000
        static let maxLogLines = 200
        static let lifecycleSettleMs = 3000
        static let lazyInvalidatePauseMs = 500
        static let timeoutProbeDeadlineMs = 1
        static let firstCustomerId = "user_a"
        static let secondCustomerId = "user_b"
    }

    private struct LabError: LocalizedError {
        let errorDescription: String?
    }

    // Inputs survive lab unmounts (switching tabs or screens) for the app session; the log does not.
    private static var lastIdsText = "\(ContentBlocksConstants.placeholderTop), \(ContentBlocksConstants.placeholderPlatform)"
    private static var lastDeadlineText = String(Constants.defaultDeadlineMs)

    @Published var idsText = RuntimeControllerLabViewModel.lastIdsText {
        didSet { Self.lastIdsText = idsText }
    }
    @Published var deadlineText = RuntimeControllerLabViewModel.lastDeadlineText {
        didSet { Self.lastDeadlineText = deadlineText }
    }
    @Published private(set) var isBusy = false
    @Published private(set) var logs: [String] = []
    @Published private(set) var mounted: [String] = []
    @Published private(set) var mountVersion = 0

    /// Set by the view; scenarios that identify or anonymize keep the app's status indicator in sync.
    weak var sdkState: SdkState?

    private let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var isControllerPresent: Bool {
        ExponeaService.inAppContentBlocksController != nil
    }

    var logText: String {
        logs.isEmpty ? "Runtime controller results will appear here." : logs.joined(separator: "\n")
    }

    func log(_ message: String) {
        let line = "\(timestampFormatter.string(from: Date())) \(message)"
        logs = Array(logs.suffix(Constants.maxLogLines - 1)) + [line]
    }

    func clearLog() {
        logs = []
    }

    func copyLog() {
        UIPasteboard.general.string = logs.isEmpty ? "No runtime ICB results yet." : logs.joined(separator: "\n")
    }

    private var runTask: Task<Void, Never>?

    func start(_ scenario: RuntimeLabScenario) {
        guard !isBusy else { return }
        // Set before the task starts so a second tap can't start another run.
        isBusy = true
        runTask = Task { [weak self] in
            await self?.run(scenario)
        }
    }

    /// Stops the running scenario before its next step, e.g. when the lab leaves the screen.
    func cancel() {
        runTask?.cancel()
        runTask = nil
    }

    private func run(_ scenario: RuntimeLabScenario) async {
        defer { isBusy = false }
        var ids: [String] = []
        for id in idsText.split(whereSeparator: { $0 == "," || $0 == "\n" })
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            where !id.isEmpty && !ids.contains(id) {
            ids.append(id)
        }
        guard !ids.isEmpty,
              let deadline = Int(deadlineText.trimmingCharacters(in: .whitespaces)),
              deadline >= 0 else {
            log("WARN: Enter at least one placeholder ID and a non-negative deadline in milliseconds.")
            return
        }
        let name = scenario.rawValue
        log("BEGIN \(name) ids=\(ids.joined(separator: ", ")) deadline=\(deadline)ms")
        do {
            let controller = try requireController()
            switch scenario {
            case .prefetch:
                let snapshot = await controller.prefetch(ids: ids, deadline: seconds(deadline))
                log("prefetch snapshot: \(encode(snapshot, ids: ids))")
            case .availability:
                try await availability(ids: ids, timeout: deadline)
            case .eagerInvalidate:
                // Deliberately does what the docs warn against: invalidating right after a ready prefetch
                // discards the warmed content. The final availability shows the reload; this is a diagnostic
                // scenario, not an integration pattern.
                try await prefetch(ids)
                try invalidate(ids, mode: .eager, scenario: name)
                try await availability(ids: ids, timeout: deadline)
            case .happyPath:
                try await prefetch(ids)
                try mount(ids)
            case .postLoginCMS:
                try identify(Constants.firstCustomerId)
                try await prefetch(ids)
                try mount(ids)
            case .logout:
                try await prefetch(ids)
                try await anonymize()
                try await prefetch(ids)
            case .availabilityTimeout:
                try invalidate(ids, mode: .eager, scenario: name)
                // A warm/fast response can resolve even within 1ms; report the actual decision.
                try await availability(ids: Array(ids.prefix(1)), timeout: Constants.timeoutProbeDeadlineMs)
            case .anonymizeLifecycleProbe:
                try await prefetch(ids)
                try await anonymize()
                log("Immediate post-anonymize prefetch")
                try await prefetch(ids)
                await pause(Constants.lifecycleSettleMs)
                log("Settled post-anonymize prefetch")
                try await prefetch(ids)
            case .identitySwitch:
                try identify(Constants.firstCustomerId)
                try await prefetch(ids)
                try identify(Constants.secondCustomerId)
                try await prefetch(ids)
            case .lazyInvalidate:
                try await prefetch(ids)
                try invalidate(ids, mode: .lazy, scenario: name)
                log("Pause \(Constants.lazyInvalidatePauseMs)ms without accessing content")
                await pause(Constants.lazyInvalidatePauseMs)
                try await prefetch(ids)
            }
            log("END \(name)")
        } catch is CancellationError {
            log("CANCELLED \(name)")
        } catch {
            log("FAILED \(name): \(error.localizedDescription)")
        }
    }

    /// Every step goes through here, so a cancelled run stops before its next SDK call.
    private func requireController() throws -> RuntimeInContentBlockControllerType {
        try Task.checkCancellation()
        guard let controller = ExponeaService.inAppContentBlocksController else {
            throw LabError(errorDescription: "SDK is not configured")
        }
        return controller
    }

    private func prefetch(_ ids: [String]) async throws {
        let snapshot = try await requireController().prefetch(ids: ids)
        log("prefetch: \(encode(snapshot, ids: ids))")
    }

    private func availability(ids: [String], timeout: Int) async throws {
        for id in ids {
            let decision = try await requireController().availability(id: id, deadline: seconds(timeout))
            log("availability(\(id), \(timeout)ms): \(encode(decision))")
        }
    }

    private func invalidate(_ ids: [String], mode: InAppContentBlockInvalidateMode, scenario: String) throws {
        try requireController().invalidate(ids: ids, reason: "example lab: \(scenario)", mode: mode)
        log("invalidate(\(mode == .eager ? "eager" : "lazy")): accepted; reload completion is checked separately")
    }

    private func mount(_ ids: [String]) throws {
        try Task.checkCancellation()
        mountVersion += 1
        mounted = ids
        log("Mount placeholders after prefetch; the placeholder views load them on mount.")
    }

    /// Returns once the SDK has finished anonymizing, so the next step sees the new anonymous customer.
    private func anonymize() async throws {
        try Task.checkCancellation()
        log("anonymize")
        await withCheckedContinuation { continuation in
            ExponeaService.anonymize { continuation.resume() }
        }
        sdkState?.markAnonymized()
    }

    private func identify(_ customerId: String) throws {
        try Task.checkCancellation()
        let customerIds = ["registered": customerId]
        // With demo JWT keys (Stream mode) the identify carries a token for the new customer;
        // without one the SDK would clear the stored JWT.
        let jwtToken = DemoJwtSession.isConfigured ? DemoJwtSession.generateToken(customerIds: customerIds) : nil
        log("identify registered=\(customerId)")
        ExponeaService.identifyCustomer(customerIds: customerIds, properties: [:], jwtToken: jwtToken)
        sdkState?.markIdentified(registeredId: customerId)
    }

    private func pause(_ milliseconds: Int) async {
        try? await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
    }

    private func seconds(_ milliseconds: Int) -> TimeInterval {
        TimeInterval(milliseconds) / 1000
    }

    // Compact JSON with keys in the requested id order.
    // The braces below are JSON text inside string literals, not code blocks.
    // swiftlint:disable open_brace_spacing close_brace_spacing
    private func encode(_ snapshot: [String: InAppContentBlockAvailability], ids: [String]) -> String {
        let pairs = ids.compactMap { id in snapshot[id].map { "\(quoted(id)):\(quoted(name($0)))" } }
        return "{\(pairs.joined(separator: ","))}"
    }

    private func encode(_ decision: InAppContentBlockAvailabilityDecision) -> String {
        switch decision {
        case let .resolved(availability):
            return "{\"status\":\"resolved\",\"availability\":\(quoted(name(availability)))}"
        case .timedOut:
            return "{\"status\":\"timedOut\"}"
        }
    }
    // swiftlint:enable open_brace_spacing close_brace_spacing

    private func name(_ availability: InAppContentBlockAvailability) -> String {
        switch availability {
        case .ready: return "ready"
        case .loading: return "loading"
        case .empty: return "empty"
        }
    }

    private func quoted(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value), let json = String(data: data, encoding: .utf8) else {
            return "\"\(value)\""
        }
        return json
    }
}
