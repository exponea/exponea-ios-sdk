import Foundation
import ExponeaSDK

@MainActor
final class AnonymizeViewModel: ObservableObject {

    @Published var showAnonymizedDialog = false
    @Published var showStoppedDialog = false
    @Published var showStopConfirmation = false
    @Published var isBusy = false

    weak var sdkState: SdkState?
    weak var logStore: InAppLogStore?

    func anonymize() {
        guard !isBusy else { return }
        // A stopped SDK skips anonymize but still calls the completion, so check first.
        guard sdkState?.isIntegrated ?? ExponeaService.isConfigured else {
            logStore?.append(level: .warning, message: "Anonymize skipped: the SDK integration is stopped")
            showStoppedDialog = true
            return
        }
        isBusy = true
        ExponeaService.anonymize { [weak self] in
            self?.sdkState?.markAnonymized()
            self?.isBusy = false
            self?.showAnonymizedDialog = true
        }
    }

    func stopBackToAuth() {
        guard !isBusy else { return }
        isBusy = true
        ExponeaService.stopIntegration { [weak self] in
            DispatchQueue.main.async {
                self?.logStore?.clear()
                self?.sdkState?.resetToAuthentication()
                self?.isBusy = false
            }
        }
    }

    func stopAndContinue() {
        guard !isBusy else { return }
        isBusy = true
        ExponeaService.stopIntegration { [weak self] in
            DispatchQueue.main.async {
                self?.sdkState?.markStopped()
                self?.isBusy = false
            }
        }
    }
}
