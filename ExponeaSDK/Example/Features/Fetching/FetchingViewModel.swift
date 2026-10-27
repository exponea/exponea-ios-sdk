import Foundation
import ExponeaSDK

private let resultPlaceholder = "Tap a fetch action to see results"
private let segmentsFetchTimeout: TimeInterval = 15

enum RecommendationPreferences {
    private static let key = "example_v2_recommendation_id"

    static func load() -> String {
        UserDefaults.standard.string(forKey: key) ?? ""
    }

    static func save(_ id: String) {
        UserDefaults.standard.set(id, forKey: key)
    }
}

@MainActor
final class FetchingViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var resultText = resultPlaceholder
    @Published var showRecommendationDialog = false

    func clearResult() {
        resultText = resultPlaceholder
    }

    func fetchConsents() {
        guard ensureConfigured(for: "fetchConsents") else { return }
        runFetch { done in
            InAppLogStore.shared.append(level: .verbose, message: "fetchConsents started")
            ExponeaService.fetchConsents { result in
                let text: String
                switch result {
                case .success(let response):
                    text = String(describing: response.consents)
                    InAppLogStore.shared.append(
                        level: .verbose,
                        message: "fetchConsents succeeded (\(response.consents.count) items)"
                    )
                case .failure(let error):
                    text = "Error: \(error.localizedDescription)"
                    InAppLogStore.shared.append(level: .error, message: "fetchConsents failed: \(error.localizedDescription)")
                }
                done(text)
            }
        }
    }

    func fetchRecommendations(recommendationId: String) {
        let id = recommendationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        guard ensureConfigured(for: "fetchRecommendations") else { return }
        RecommendationPreferences.save(id)
        runFetch { done in
            InAppLogStore.shared.append(level: .verbose, message: "fetchRecommendations(\(id)) started")
            ExponeaService.fetchRecommendations(id: id) { result in
                let text: String
                switch result {
                case .success(let response):
                    text = String(describing: response)
                    InAppLogStore.shared.append(level: .verbose, message: "fetchRecommendations(\(id)) succeeded")
                case .failure(let error):
                    text = "Error: \(error.localizedDescription)"
                    InAppLogStore.shared.append(
                        level: .error,
                        message: "fetchRecommendations(\(id)) failed: \(error.localizedDescription)"
                    )
                }
                done(text)
            }
        }
    }

    func fetchSegments() {
        guard ensureConfigured(for: "fetchSegments") else { return }
        runFetch { done in
            InAppLogStore.shared.append(level: .verbose, message: "fetchSegments(discovery) started")
            var finished = false
            DispatchQueue.main.asyncAfter(deadline: .now() + segmentsFetchTimeout) {
                guard !finished else { return }
                finished = true
                let message = "Segments fetch timed out after \(Int(segmentsFetchTimeout)) seconds."
                InAppLogStore.shared.append(level: .error, message: message)
                done("Message: \(message)\nJSON: null")
            }
            ExponeaService.getSegments(category: .discovery()) { segments in
                guard !finished else { return }
                finished = true
                let body = segments.map { segment in
                    "[\(segment.id)] segId=\(segment.segmentationId)"
                }.joined(separator: "\n")
                let text = body.isEmpty
                    ? "Segments (discovery):\n"
                    : "Segments (discovery):\n\(body)"
                InAppLogStore.shared.append(
                    level: .verbose,
                    message: "fetchSegments(discovery) returned \(segments.count) segment(s)"
                )
                done(text)
            }
        }
    }

    private func ensureConfigured(for action: String) -> Bool {
        guard ExponeaService.isConfigured else {
            let message = "Error: SDK not configured. Return to Auth and tap Start."
            resultText = message
            InAppLogStore.shared.append(level: .error, message: "\(action) skipped: SDK not configured")
            return false
        }
        return true
    }

    private func runFetch(_ fetch: @escaping (@escaping (String) -> Void) -> Void) {
        isLoading = true
        fetch { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.resultText = result
            }
        }
    }
}
