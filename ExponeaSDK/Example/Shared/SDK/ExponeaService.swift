import Foundation
import ExponeaSDK

// iOS SDK specifics this file relies on:
// - FlushingMode has .immediate, .periodic(Int), .automatic and .manual
// - LogLevel has .none, .error, .warning and .verbose (no info or debug level)
// - clearLocalCustomerData(appGroup:) needs the app group

enum ExampleConstants {
    static let appGroup = "group.com.exponea.sdk.example"
    static let demoDefaultProperties: [String: JSONConvertible] = ["sdk_demo_app": true]
}

struct ConfigurationSnapshot {
    let tokenTrackFrequencyLabel: String
    let applicationId: String
}

/// Result of a manual flush: whether it succeeded, and a message to show.
struct FlushOutcome: Equatable {
    let succeeded: Bool
    let message: String
}

/// Injectable SDK boundary for the example app view models and source-only tests.
protocol ExponeaServicing {
    var isConfigured: Bool { get }
    var configurationSnapshot: ConfigurationSnapshot? { get }
    var customerCookie: String? { get }
    var inAppContentBlocksController: RuntimeInContentBlockControllerType? { get }
    var flushingMode: FlushingMode { get set }
    var logLevel: LogLevel { get set }

    func configure(
        integration: any IntegrationType,
        registeredCustomerId: String?,
        applicationID: String?,
        advancedAuthKey: String,
        streamJwtKeyId: String,
        streamJwtSecret: String
    )

    func identifyCustomer(
        customerIds: [String: String],
        properties: [String: JSONConvertible],
        jwtToken: String?
    )

    func setSdkAuthToken(_ token: String)
    func trackEvent(name: String, properties: [String: JSONConvertible])
    func trackPageView(screenName: String)
    func trackPayment(properties: [String: JSONConvertible])
    func trackPushToken(_ token: Data)
    func trackDeliveredPush()
    func trackClickedPush()
    func flushData(completion: @escaping (FlushOutcome) -> Void)
    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void)
    func fetchRecommendations(
        id: String,
        completion: @escaping (Result<RecommendationResponse<ExponeaSDK.EmptyRecommendationData>>) -> Void
    )
    func getSegments(category: SegmentCategory, completion: @escaping ([SegmentDTO]) -> Void)
    /// The completion runs on the main queue once the SDK has finished anonymizing.
    func anonymize(completion: (() -> Void)?)
    func stopIntegration(completion: (() -> Void)?)
    func clearLocalCustomerData()
}

final class LiveExponeaService: ExponeaServicing {
    private var storedConfigurationSnapshot: ConfigurationSnapshot?

    var isConfigured: Bool { Exponea.shared.isConfigured }

    var configurationSnapshot: ConfigurationSnapshot? { storedConfigurationSnapshot }

    var customerCookie: String? { Exponea.shared.customerCookie }
    var inAppContentBlocksController: RuntimeInContentBlockControllerType? {
        Exponea.shared.inAppContentBlocksController
    }

    var flushingMode: FlushingMode {
        get { Exponea.shared.flushingMode }
        set { Exponea.shared.flushingMode = newValue }
    }

    var logLevel: LogLevel {
        get { Exponea.logger.logLevel }
        set { Exponea.logger.logLevel = newValue }
    }

    func configure(
        integration: any IntegrationType,
        registeredCustomerId: String?,
        applicationID: String?,
        advancedAuthKey: String,
        streamJwtKeyId: String = "",
        streamJwtSecret: String = ""
    ) {
        let trimmedRegisteredId = registeredCustomerId?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let customerIds: [String: String] = trimmedRegisteredId.isEmpty
            ? [:]
            : ["registered": trimmedRegisteredId]

        let isStream = integration is Exponea.StreamSettings
        configureCustomerTokens(integration: integration, advancedAuthKey: advancedAuthKey, customerIds: customerIds)

        if Exponea.shared.isConfigured {
            wireExampleIntegrations(
                isStream: isStream,
                jwtKeyId: streamJwtKeyId,
                jwtSecret: streamJwtSecret,
                customerIds: customerIds
            )
            refreshStreamJwtForActiveSession(customerIds: customerIds)
            ensureConfigurationSnapshot(applicationID: applicationID)
            return
        }

        wireExampleIntegrations(
            isStream: isStream,
            jwtKeyId: streamJwtKeyId,
            jwtSecret: streamJwtSecret,
            customerIds: customerIds
        )

        // Mint the Stream JWT and identify only after SDK init completes. The SDK keeps one such callback;
        // its returned instance is only for chaining.
        _ = Exponea.shared.onInitSucceeded { [customerIds] in
            self.applyStreamJwtAfterInit(customerIds: customerIds)
        }

        // Stream mode authenticates with its own JWT; Project mode uses ExampleAuthProvider when a key is set.
        let advancedAuthForSdk: Bool? = isStream ? false : (advancedAuthKey.isEmpty ? nil : true)

        // The push setup self-check runs in debug builds only and must be enabled before configure. The
        // simulator is skipped: its result alert would appear after every configure there.
        #if !targetEnvironment(simulator)
        Exponea.shared.checkPushSetup = true
        #endif

        Exponea.shared.configure(
            integration,
            pushNotificationTracking: .enabled(
                appGroup: ExampleConstants.appGroup,
                delegate: ExampleListeners.pushDelegate,
                tokenTrackFrequency: .onTokenChange
            ),
            defaultProperties: ExampleConstants.demoDefaultProperties,
            inAppContentBlocksPlaceholders: ContentBlocksConstants.autoloadPlaceholders,
            flushingSetup: .init(mode: .immediate),
            advancedAuthEnabled: advancedAuthForSdk,
            applicationID: applicationID.flatMap { $0.isEmpty ? nil : $0 }
        )

        Exponea.shared.flushingMode = .immediate
        ensureConfigurationSnapshot(applicationID: applicationID)
    }

    private func applyStreamJwtAfterInit(customerIds: [String: String]) {
        guard StreamAuthListener.isActive else { return }
        StreamAuthListener.registerHandlerIfNeeded()
        guard let token = StreamAuthListener.initialToken(customerIds: customerIds) else { return }
        Exponea.shared.setSdkAuthToken(token)
        if let registered = customerIds["registered"], !registered.isEmpty {
            identifyCustomer(customerIds: customerIds, properties: [:], jwtToken: token)
        }
    }

    private func refreshStreamJwtForActiveSession(customerIds: [String: String]) {
        guard StreamAuthListener.isActive, Exponea.shared.isConfigured else { return }
        StreamAuthListener.registerHandlerIfNeeded()
        guard let token = StreamAuthListener.initialToken(customerIds: customerIds) else { return }
        Exponea.shared.setSdkAuthToken(token)
    }

    /// Advanced auth in Project mode: `ExampleAuthProvider` fetches customer tokens with the auth key.
    private func configureCustomerTokens(
        integration: any IntegrationType,
        advancedAuthKey: String,
        customerIds: [String: String]
    ) {
        guard !advancedAuthKey.isEmpty, let project = integration as? Exponea.ProjectSettings else { return }
        CustomerTokenStorage.shared.configure(
            host: project.baseUrl,
            projectToken: project.projectToken,
            publicKey: advancedAuthKey,
            // Without a registered id the token is requested after Identify Customer.
            customerIds: customerIds.isEmpty ? nil : customerIds
        )
    }

    private func wireExampleIntegrations(
        isStream: Bool,
        jwtKeyId: String,
        jwtSecret: String,
        customerIds: [String: String]
    ) {
        Exponea.shared.appInboxProvider = ExampleAppInboxProvider()
        ExampleListeners.register()

        let jwtKey = jwtKeyId.trimmingCharacters(in: .whitespacesAndNewlines)
        let jwtSecret = jwtSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        if isStream && !jwtKey.isEmpty && !jwtSecret.isEmpty {
            StreamAuthListener.prepare(keyId: jwtKey, secret: jwtSecret, customerIds: customerIds)
            StreamAuthListener.registerHandlerIfNeeded()
        } else {
            StreamAuthListener.stop()
        }
    }

    private func ensureConfigurationSnapshot(applicationID: String?) {
        let resolvedApplicationId = applicationID?.trimmingCharacters(in: .whitespaces)
        let displayApplicationId = (resolvedApplicationId?.isEmpty == false)
            ? resolvedApplicationId!
            : "default-application"
        storedConfigurationSnapshot = ConfigurationSnapshot(
            tokenTrackFrequencyLabel: "on token change",
            applicationId: displayApplicationId
        )
    }

    func identifyCustomer(
        customerIds: [String: String],
        properties: [String: JSONConvertible],
        jwtToken: String?
    ) {
        let token = jwtToken.flatMap { $0.isEmpty ? nil : $0 }
        if token == nil {
            CustomerTokenStorage.shared.configure(customerIds: customerIds)
        }
        // In Stream mode the SDK replaces the stored JWT with this one before tracking the identify event.
        Exponea.shared.identifyCustomer(
            context: CustomerIdentity(customerIds: customerIds, jwtToken: token),
            properties: properties,
            timestamp: nil
        )
    }

    func setSdkAuthToken(_ token: String) {
        Exponea.shared.setSdkAuthToken(token)
    }

    func trackEvent(name: String, properties: [String: JSONConvertible]) {
        Exponea.shared.trackEvent(properties: properties, timestamp: nil, eventType: name)
    }

    func trackPageView(screenName: String) {
        trackEvent(name: "page_view", properties: ["screen_name": screenName])
    }

    func trackPayment(properties: [String: JSONConvertible]) {
        Exponea.shared.trackPayment(properties: properties, timestamp: nil)
    }

    func trackPushToken(_ token: Data) {
        Exponea.shared.trackPushToken(token)
    }

    func trackDeliveredPush() {
        Exponea.shared.trackPushReceived(userInfo: ["campaign_id": "demo"])
    }

    func trackClickedPush() {
        Exponea.shared.trackPushOpened(with: ["campaign_id": "demo"])
    }

    func flushData(completion: @escaping (FlushOutcome) -> Void) {
        Exponea.shared.flushData { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let count):
                    completion(FlushOutcome(succeeded: true, message: "Flush succeeded (\(count) events)."))
                case .flushAlreadyInProgress:
                    completion(FlushOutcome(succeeded: false, message: "Flush already in progress."))
                case .noInternetConnection:
                    completion(FlushOutcome(succeeded: false, message: "No internet connection — events queued."))
                case .error(let error):
                    completion(FlushOutcome(succeeded: false, message: "Flush failed: \(error.localizedDescription)"))
                }
            }
        }
    }

    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        Exponea.shared.fetchConsents(completion: completion)
    }

    func fetchRecommendations(
        id: String,
        completion: @escaping (Result<RecommendationResponse<ExponeaSDK.EmptyRecommendationData>>) -> Void
    ) {
        let options = RecommendationOptions(id: id, fillWithRandom: true)
        Exponea.shared.fetchRecommendation(with: options, completion: completion)
    }

    func getSegments(category: SegmentCategory = .discovery(), completion: @escaping ([SegmentDTO]) -> Void) {
        Exponea.shared.getSegments(force: true, category: category) { segments in
            DispatchQueue.main.async { completion(segments) }
        }
    }

    func anonymize(completion: (() -> Void)?) {
        Exponea.shared.anonymize {
            DispatchQueue.main.async { completion?() }
        }
    }

    func stopIntegration(completion: (() -> Void)? = nil) {
        storedConfigurationSnapshot = nil
        StreamAuthListener.stop()
        ExampleListeners.cancelScheduledStop()
        Exponea.shared.stopIntegration(completion: completion)
    }

    func clearLocalCustomerData() {
        Exponea.shared.clearLocalCustomerData(appGroup: ExampleConstants.appGroup)
    }
}

enum ExponeaService {
    static var service: ExponeaServicing = LiveExponeaService()

    static var isConfigured: Bool { service.isConfigured }

    static var configurationSnapshot: ConfigurationSnapshot? { service.configurationSnapshot }

    static var customerCookie: String? { service.customerCookie }

    static var inAppContentBlocksController: RuntimeInContentBlockControllerType? {
        service.inAppContentBlocksController
    }

    static var flushingMode: FlushingMode {
        get { service.flushingMode }
        set { service.flushingMode = newValue }
    }

    static var logLevel: LogLevel {
        get { service.logLevel }
        set { service.logLevel = newValue }
    }

    static func configure(
        integration: any IntegrationType,
        registeredCustomerId: String?,
        applicationID: String?,
        advancedAuthKey: String,
        streamJwtKeyId: String = "",
        streamJwtSecret: String = ""
    ) {
        service.configure(
            integration: integration,
            registeredCustomerId: registeredCustomerId,
            applicationID: applicationID,
            advancedAuthKey: advancedAuthKey,
            streamJwtKeyId: streamJwtKeyId,
            streamJwtSecret: streamJwtSecret
        )
    }

    static func identifyCustomer(
        customerIds: [String: String],
        properties: [String: JSONConvertible],
        jwtToken: String?
    ) {
        service.identifyCustomer(customerIds: customerIds, properties: properties, jwtToken: jwtToken)
    }

    static func setSdkAuthToken(_ token: String) {
        service.setSdkAuthToken(token)
    }

    static func trackEvent(name: String, properties: [String: JSONConvertible]) {
        service.trackEvent(name: name, properties: properties)
    }

    static func trackPageView(screenName: String) {
        service.trackPageView(screenName: screenName)
    }

    static func trackPayment(properties: [String: JSONConvertible]) {
        service.trackPayment(properties: properties)
    }

    static func trackPushToken(_ token: Data) {
        service.trackPushToken(token)
    }

    static func trackDeliveredPush() {
        service.trackDeliveredPush()
    }

    static func trackClickedPush() {
        service.trackClickedPush()
    }

    static func flushData(completion: @escaping (FlushOutcome) -> Void) {
        service.flushData(completion: completion)
    }

    static func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        service.fetchConsents(completion: completion)
    }

    static func fetchRecommendations(
        id: String,
        completion: @escaping (Result<RecommendationResponse<ExponeaSDK.EmptyRecommendationData>>) -> Void
    ) {
        service.fetchRecommendations(id: id, completion: completion)
    }

    static func getSegments(category: SegmentCategory = .discovery(), completion: @escaping ([SegmentDTO]) -> Void) {
        service.getSegments(category: category, completion: completion)
    }

    static func anonymize(completion: (() -> Void)? = nil) {
        service.anonymize(completion: completion)
    }

    static func stopIntegration(completion: (() -> Void)? = nil) {
        service.stopIntegration(completion: completion)
    }

    static func clearLocalCustomerData() {
        service.clearLocalCustomerData()
    }
}
