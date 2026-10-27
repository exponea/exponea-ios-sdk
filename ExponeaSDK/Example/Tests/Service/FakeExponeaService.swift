import Foundation
import ExponeaSDK

/// Deterministic fake for source-only tests; does not invoke ExponeaSDK.
final class FakeExponeaService: ExponeaServicing {
    struct RecordedCall: Equatable {
        let name: String
        let payload: String
    }

    private(set) var recordedCalls: [RecordedCall] = []

    var isConfigured: Bool = false
    var configurationSnapshot: ConfigurationSnapshot?
    var customerCookie: String? = "fake-cookie"
    var inAppContentBlocksController: RuntimeInContentBlockControllerType?
    var flushingMode: FlushingMode = .immediate
    var logLevel: LogLevel = .none
    var flushResult = FlushOutcome(succeeded: true, message: "Flush succeeded (0 events).")
    var segmentsResult: [SegmentDTO] = []
    var consentsResult: Result<ConsentsResponse> = .failure(ExponeaError.notConfigured)
    var recommendationsResult: Result<RecommendationResponse<ExponeaSDK.EmptyRecommendationData>> =
        .failure(ExponeaError.notConfigured)

    private func record(_ name: String, payload: String = "") {
        recordedCalls.append(RecordedCall(name: name, payload: payload))
    }

    func configure(
        integration: any IntegrationType,
        registeredCustomerId: String?,
        applicationID: String?,
        advancedAuthKey: String,
        streamJwtKeyId: String = "",
        streamJwtSecret: String = ""
    ) {
        isConfigured = true
        configurationSnapshot = ConfigurationSnapshot(
            tokenTrackFrequencyLabel: "on token change",
            applicationId: applicationID?.isEmpty == false ? applicationID! : "default-application"
        )
        record(
            "configure",
            payload: "\(registeredCustomerId ?? "")|\(applicationID ?? "")|\(advancedAuthKey)|\(streamJwtKeyId)|\(streamJwtSecret)"
        )
    }

    func identifyCustomer(
        customerIds: [String: String],
        properties: [String: JSONConvertible],
        jwtToken: String?
    ) {
        record("identifyCustomer", payload: customerIds.description)
    }

    func setSdkAuthToken(_ token: String) {
        record("setSdkAuthToken", payload: token)
    }

    func trackEvent(name: String, properties: [String: JSONConvertible]) {
        record("trackEvent", payload: name)
    }

    func trackPageView(screenName: String) {
        record("trackPageView", payload: screenName)
    }

    func trackPayment(properties: [String: JSONConvertible]) {
        record("trackPayment")
    }

    func trackPushToken(_ token: Data) {
        record("trackPushToken")
    }

    func trackDeliveredPush() {
        record("trackDeliveredPush")
    }

    func trackClickedPush() {
        record("trackClickedPush")
    }

    func flushData(completion: @escaping (FlushOutcome) -> Void) {
        record("flushData")
        completion(flushResult)
    }

    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void) {
        record("fetchConsents")
        completion(consentsResult)
    }

    func fetchRecommendations(
        id: String,
        completion: @escaping (Result<RecommendationResponse<ExponeaSDK.EmptyRecommendationData>>) -> Void
    ) {
        record("fetchRecommendations", payload: id)
        completion(recommendationsResult)
    }

    func getSegments(category: SegmentCategory, completion: @escaping ([SegmentDTO]) -> Void) {
        record("getSegments")
        completion(segmentsResult)
    }

    func anonymize(completion: (() -> Void)?) {
        record("anonymize")
        completion?()
    }

    func stopIntegration(completion: (() -> Void)? = nil) {
        isConfigured = false
        configurationSnapshot = nil
        record("stopIntegration")
        completion?()
    }

    func clearLocalCustomerData() {
        record("clearLocalCustomerData")
    }
}
