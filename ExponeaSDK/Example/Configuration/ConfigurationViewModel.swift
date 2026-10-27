import Foundation
import Combine
import ExponeaSDK

/// Configuration form input, trimmed. The base URL must be http(s) with a host.
struct ConfigureRequest {
    let mode: IntegrationMode
    let baseUrl: String
    let projectToken: String
    let authToken: String
    let streamId: String
    let jwtKeyId: String
    let jwtSecret: String

    var isBaseUrlValid: Bool {
        guard !baseUrl.isEmpty,
              let url = URL(string: baseUrl),
              let host = url.host,
              !host.isEmpty else {
            return false
        }
        return url.scheme == "http" || url.scheme == "https"
    }

    var isProjectValid: Bool {
        isBaseUrlValid && !projectToken.isEmpty && !authToken.isEmpty
    }

    var isStreamValid: Bool {
        isBaseUrlValid && !streamId.isEmpty
    }

    var isJwtPairValid: Bool {
        jwtKeyId.isEmpty == jwtSecret.isEmpty
    }

    var isValid: Bool {
        guard isJwtPairValid else { return false }
        return mode == .project ? isProjectValid : isStreamValid
    }

    var validationError: String? {
        if !isJwtPairValid {
            return NSLocalizedString("config.error.jwtPair", comment: "")
        }
        switch mode {
        case .project:
            if projectToken.isEmpty || authToken.isEmpty {
                return NSLocalizedString("config.error.missingFields", comment: "")
            }
        case .stream:
            if streamId.isEmpty {
                return NSLocalizedString("config.error.missingFields", comment: "")
            }
        }
        if !isBaseUrlValid {
            return NSLocalizedString("config.error.invalidUrl", comment: "")
        }
        return nil
    }

    static func trimmed(
        mode: IntegrationMode,
        baseUrl: String,
        projectToken: String,
        authToken: String,
        streamId: String,
        jwtKeyId: String,
        jwtSecret: String
    ) -> ConfigureRequest {
        return ConfigureRequest(
            mode: mode,
            baseUrl: trimWhitespace(baseUrl),
            projectToken: trimWhitespace(projectToken),
            authToken: trimWhitespace(authToken),
            streamId: trimWhitespace(streamId),
            jwtKeyId: trimWhitespace(jwtKeyId),
            jwtSecret: trimWhitespace(jwtSecret)
        )
    }

    private static func trimWhitespace(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum IntegrationMode: String, CaseIterable, Identifiable {
    case project = "Project"
    case stream  = "Stream / Data Hub"
    var id: String { rawValue }

    var preferenceValue: String {
        switch self {
        case .project: return "project"
        case .stream: return "stream"
        }
    }

    static func fromPreference(_ value: String?) -> IntegrationMode {
        value == "stream" ? .stream : .project
    }
}

// MARK: - Persisted configuration form

struct AuthFormData {
    var mode: IntegrationMode = .project
    var projectToken: String = ""
    var authToken: String = ""
    var advancedAuthKey: String = ""
    var streamId: String = ""
    var jwtKeyId: String = ""
    var registeredId: String = ""
    var baseUrl: String = ""
    var applicationId: String = ""

    var hasSavedForm: Bool {
        !projectToken.isEmpty || !streamId.isEmpty || !baseUrl.isEmpty
    }
}

/// Saves the configuration form in UserDefaults so the next launch is prefilled. Demo convenience only:
/// production apps shouldn't keep API credentials like this. The JWT secret is never saved; supply it with
/// `EXPONEA_JWT_SECRET` or type it again.
enum AuthPreferences {
    private enum Key {
        static let mode = "integration_mode"
        static let project = "project_token"
        static let auth = "auth_token"
        static let advancedAuth = "advanced_auth_token"
        static let streamId = "stream_id"
        static let jwtKeyId = "jwt_key_id"
        /// Written by earlier builds; removed whenever the form is loaded, saved or cleared.
        static let jwtSecret = "jwt_secret"
        static let registeredId = "registered_id"
        static let baseUrl = "base_url"
        static let applicationId = "application_id"
    }

    static func load() -> AuthFormData {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Key.jwtSecret)
        return AuthFormData(
            mode: IntegrationMode.fromPreference(defaults.string(forKey: Key.mode)),
            projectToken: defaults.string(forKey: Key.project) ?? "",
            authToken: defaults.string(forKey: Key.auth) ?? "",
            advancedAuthKey: defaults.string(forKey: Key.advancedAuth) ?? "",
            streamId: defaults.string(forKey: Key.streamId) ?? "",
            jwtKeyId: defaults.string(forKey: Key.jwtKeyId) ?? "",
            registeredId: defaults.string(forKey: Key.registeredId) ?? "",
            baseUrl: defaults.string(forKey: Key.baseUrl) ?? "",
            applicationId: defaults.string(forKey: Key.applicationId) ?? ""
        )
    }

    static func save(
        mode: IntegrationMode,
        projectToken: String,
        authToken: String,
        advancedAuthKey: String,
        streamId: String,
        jwtKeyId: String,
        registeredId: String,
        baseUrl: String,
        applicationId: String
    ) {
        let defaults = UserDefaults.standard
        defaults.set(mode.preferenceValue, forKey: Key.mode)
        defaults.set(projectToken, forKey: Key.project)
        defaults.set(authToken, forKey: Key.auth)
        defaults.set(advancedAuthKey, forKey: Key.advancedAuth)
        defaults.set(streamId, forKey: Key.streamId)
        defaults.set(jwtKeyId, forKey: Key.jwtKeyId)
        defaults.removeObject(forKey: Key.jwtSecret)
        defaults.set(registeredId, forKey: Key.registeredId)
        defaults.set(baseUrl, forKey: Key.baseUrl)
        defaults.set(applicationId, forKey: Key.applicationId)
    }

    static func clear() {
        let defaults = UserDefaults.standard
        [
            Key.mode, Key.project, Key.auth, Key.advancedAuth, Key.streamId, Key.jwtKeyId, Key.jwtSecret,
            Key.registeredId, Key.baseUrl, Key.applicationId
        ].forEach { defaults.removeObject(forKey: $0) }
    }
}

// MARK: - Credentials from environment variables or Info.plist

struct EnvConfig {
    let projectToken: String
    let authorizationToken: String
    let baseUrl: String
    let customerId: String
    let streamId: String
    let jwtKeyId: String
    let jwtSecret: String
    let integrationMode: String
    let autoConfigure: String

    static func load() -> EnvConfig {
        EnvConfig(
            projectToken: value(for: "EXPONEA_PROJECT_TOKEN"),
            authorizationToken: value(for: "EXPONEA_AUTHORIZATION_TOKEN"),
            baseUrl: value(for: "EXPONEA_BASE_URL"),
            customerId: value(for: "EXPONEA_CUSTOMER_ID"),
            streamId: value(for: "EXPONEA_STREAM_ID"),
            jwtKeyId: value(for: "EXPONEA_JWT_KEY_ID"),
            jwtSecret: value(for: "EXPONEA_JWT_SECRET"),
            integrationMode: value(for: "EXPONEA_INTEGRATION_MODE"),
            autoConfigure: value(for: "EXPONEA_AUTO_CONFIGURE")
        )
    }

    private static func value(for key: String) -> String {
        let fromProcess = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromProcess.isEmpty {
            return fromProcess
        }
        let fromPlist = (Bundle.main.infoDictionary?[key] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fromPlist
    }

    var resolvedMode: IntegrationMode {
        if integrationMode.lowercased() == "stream" {
            return .stream
        }
        if integrationMode.isEmpty && !streamId.isEmpty && projectToken.isEmpty {
            return .stream
        }
        return .project
    }

    var hasProjectCredentials: Bool {
        !projectToken.isEmpty && !authorizationToken.isEmpty && !baseUrl.isEmpty
    }

    var hasStreamCredentials: Bool {
        !streamId.isEmpty && !baseUrl.isEmpty
    }

    var canAutoConfigure: Bool {
        resolvedMode == .stream ? hasStreamCredentials : hasProjectCredentials
    }

    var shouldAutoConfigure: Bool {
        if autoConfigure.lowercased() == "false" {
            return false
        }
        return canAutoConfigure
    }
}

enum AuthFormPrefill {
    static func pick(saved: String, env: String, default defaultValue: String = "") -> String {
        let trimmedSaved = saved.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSaved.isEmpty { return trimmedSaved }
        let trimmedEnv = env.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedEnv.isEmpty { return trimmedEnv }
        return defaultValue
    }

    @MainActor
    static func apply(env: EnvConfig, saved: AuthFormData, to viewModel: ConfigurationViewModel) {
        let mode: IntegrationMode = saved.hasSavedForm
            ? saved.mode
            : env.resolvedMode

        viewModel.mode = mode
        viewModel.projectToken = pick(saved: saved.projectToken, env: env.projectToken)
        viewModel.authToken = pick(saved: saved.authToken, env: env.authorizationToken)
        viewModel.advancedAuthKey = pick(saved: saved.advancedAuthKey, env: "")
        viewModel.streamId = pick(saved: saved.streamId, env: env.streamId)
        viewModel.jwtKeyId = pick(saved: saved.jwtKeyId, env: env.jwtKeyId)
        viewModel.jwtSecret = env.jwtSecret
        viewModel.baseUrl = pick(saved: saved.baseUrl, env: env.baseUrl, default: "https://api.exponea.com")
        viewModel.registeredId = pick(saved: saved.registeredId, env: env.customerId)
        viewModel.applicationId = pick(saved: saved.applicationId, env: "")
    }
}

enum ConfigurationBootstrap {
    @MainActor
    static func runIfNeeded(sdkState: SdkState) {
        guard !sdkState.isInitialized else { return }

        let env = EnvConfig.load()
        guard env.shouldAutoConfigure else { return }
        let viewModel = ConfigurationViewModel(envConfig: env)
        guard viewModel.formIsValid else { return }
        viewModel.configure(sdkState: sdkState)
    }
}

@MainActor
final class ConfigurationViewModel: ObservableObject {

    // MARK: - Mode

    @Published var mode: IntegrationMode = .project

    // MARK: - Project fields

    @Published var projectToken: String  = ""
    @Published var authToken: String     = ""
    @Published var advancedAuthKey: String = ""

    // MARK: - Stream fields

    @Published var streamId: String   = ""
    @Published var jwtKeyId: String   = ""
    @Published var jwtSecret: String  = ""

    // MARK: - Common fields (C4)

    @Published var baseUrl: String      = "https://api.exponea.com"
    @Published var registeredId: String = ""
    @Published var applicationId: String = ""

    // MARK: - State

    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published private(set) var formIsValid: Bool = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Validation

    var isValid: Bool { formIsValid }

    var validationError: String? {
        currentRequest.validationError
    }

    private var currentRequest: ConfigureRequest {
        ConfigureRequest.trimmed(
            mode: mode,
            baseUrl: baseUrl,
            projectToken: projectToken,
            authToken: authToken,
            streamId: streamId,
            jwtKeyId: jwtKeyId,
            jwtSecret: jwtSecret
        )
    }

    init(envConfig: EnvConfig = EnvConfig.load()) {
        AuthFormPrefill.apply(env: envConfig, saved: AuthPreferences.load(), to: self)

        let publishers: [AnyPublisher<Void, Never>] = [
            $mode.map { _ in }.eraseToAnyPublisher(),
            $projectToken.map { _ in }.eraseToAnyPublisher(),
            $authToken.map { _ in }.eraseToAnyPublisher(),
            $advancedAuthKey.map { _ in }.eraseToAnyPublisher(),
            $streamId.map { _ in }.eraseToAnyPublisher(),
            $jwtKeyId.map { _ in }.eraseToAnyPublisher(),
            $jwtSecret.map { _ in }.eraseToAnyPublisher(),
            $baseUrl.map { _ in }.eraseToAnyPublisher(),
            $registeredId.map { _ in }.eraseToAnyPublisher(),
            $applicationId.map { _ in }.eraseToAnyPublisher()
        ]
        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshFormValidity()
            }
            .store(in: &cancellables)
        refreshFormValidity()
    }

    private func refreshFormValidity() {
        formIsValid = currentRequest.isValid
    }

    // MARK: - Actions

    func start(sdkState: SdkState) {
        refreshFormValidity()
        guard validationError == nil else {
            errorMessage = validationError
            return
        }
        configure(sdkState: sdkState)
    }

    func configure(sdkState: SdkState) {
        performConfigure(sdkState: sdkState)
    }

    /// Deletes the SDK's local customer data and the saved form, then refills the form from
    /// `EXPONEA_*` values or the defaults.
    func clearLocalData() {
        ExponeaService.clearLocalCustomerData()
        AuthPreferences.clear()
        AuthFormPrefill.apply(env: EnvConfig.load(), saved: AuthFormData(), to: self)
        errorMessage = nil
    }

    // MARK: - Private

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func performConfigure(sdkState: SdkState) {
        isLoading = true
        errorMessage = nil

        let request = currentRequest
        let trimmedBaseUrl = request.baseUrl
        let trimmedRegisteredId = trimmed(registeredId)
        let trimmedApplicationId = trimmed(applicationId)

        Exponea.logger.logLevel = .verbose

        let integration: any IntegrationType
        switch request.mode {
        case .project:
            integration = Exponea.ProjectSettings(
                projectToken: request.projectToken,
                authorization: .token(request.authToken),
                baseUrl: trimmedBaseUrl
            )
        case .stream:
            integration = Exponea.StreamSettings(
                streamId: request.streamId,
                baseUrl: trimmedBaseUrl
            )
        }

        ExponeaService.configure(
            integration: integration,
            registeredCustomerId: trimmedRegisteredId,
            applicationID: trimmedApplicationId,
            advancedAuthKey: trimmed(advancedAuthKey),
            streamJwtKeyId: request.jwtKeyId,
            streamJwtSecret: request.jwtSecret
        )
        if !ExponeaService.isConfigured {
            InAppLogStore.shared.append(
                level: .verbose,
                message: "Configure submitted; waiting for async SDK init to finish"
            )
        }
        sdkState.markInitialized(registeredId: trimmedRegisteredId, streamMode: request.mode == .stream)
        AuthPreferences.save(
            mode: request.mode,
            projectToken: request.projectToken,
            authToken: request.authToken,
            advancedAuthKey: trimmed(advancedAuthKey),
            streamId: request.streamId,
            jwtKeyId: request.jwtKeyId,
            registeredId: trimmedRegisteredId,
            baseUrl: trimmedBaseUrl,
            applicationId: trimmedApplicationId
        )
        isLoading = false
    }
}
