import SwiftUI

enum CustomerIdentityState {
    case anonymous
    case identified
}

enum SemaphoreState {
    case notInitialized
    case anonymous
    case identified

    var color: Color {
        switch self {
        case .notInitialized: return BrandColors.red
        case .anonymous:      return BrandColors.brYellow
        case .identified:     return BrandColors.green
        }
    }

    var label: String {
        switch self {
        case .notInitialized: return "Not initialized"
        case .anonymous:      return "Anonymous"
        case .identified:     return "Identified"
        }
    }
}

@MainActor
final class SdkState: ObservableObject {

    @Published private(set) var isInitialized: Bool = false
    @Published private(set) var identity: CustomerIdentityState = .anonymous
    @Published private(set) var isIntegrated: Bool = false
    @Published private(set) var isStreamMode: Bool = false
    /// The `registered` customer ID of the current customer; empty while anonymous.
    @Published private(set) var registeredId: String = ""

    var semaphore: SemaphoreState {
        guard isInitialized && isIntegrated else { return .notInitialized }
        return identity == .identified ? .identified : .anonymous
    }

    func markInitialized(registeredId: String, streamMode: Bool = false) {
        isInitialized = true
        isIntegrated  = true
        markIdentified(registeredId: registeredId)
        isStreamMode  = streamMode
    }

    func markIdentified(registeredId: String) {
        self.registeredId = registeredId
        identity = registeredId.isEmpty ? .anonymous : .identified
    }

    func markAnonymized() {
        registeredId = ""
        identity = .anonymous
    }

    func markStopped() {
        isIntegrated = false
    }

    func resetToAuthentication() {
        isInitialized = false
        isIntegrated = false
        identity = .anonymous
        registeredId = ""
        isStreamMode = false
    }
}
