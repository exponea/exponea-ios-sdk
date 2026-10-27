import SwiftUI

struct FeedbackBanner: View {

    let message: String
    let onDismiss: () -> Void

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))
            .cornerRadius(8)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .onTapGesture { onDismiss() }
            // Restarts when the message changes and is cancelled when the banner goes away, so a timer
            // from an earlier message never hides a newer one.
            .task(id: message) {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                onDismiss()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: message)
    }
}
