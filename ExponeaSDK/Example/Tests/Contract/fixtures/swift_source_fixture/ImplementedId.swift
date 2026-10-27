import SwiftUI

// Fixture-only source used to test stale allowlist detection.
struct ImplementedIdFixtureView: View {
    var body: some View {
        Text("fixture")
            .accessibilityIdentifier("btn_stale_fixture_id")
    }
}
