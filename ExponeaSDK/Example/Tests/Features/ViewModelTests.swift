import XCTest
@testable import Example

/// View models talk to the SDK through `ExponeaService.service`, so these tests swap in `FakeExponeaService`.
/// The service is global: the `Example` scheme runs ExampleTests serially (`parallelizable = "NO"`).
@MainActor
final class ViewModelTests: XCTestCase {

    private func withFakeService(_ body: (FakeExponeaService) async throws -> Void) async rethrows {
        let fake = FakeExponeaService()
        let previous = ExponeaService.service
        ExponeaService.service = fake
        defer { ExponeaService.service = previous }
        try await body(fake)
    }

    private func waitUntil(_ condition: () -> Bool, file: StaticString = #filePath, line: UInt = #line) async throws {
        for _ in 0..<200 where !condition() {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertTrue(condition(), "condition not met within 2 s", file: file, line: line)
    }

    func testFlushSuccess() async {
        await withFakeService { fake in
            fake.flushResult = FlushOutcome(succeeded: true, message: "Flush succeeded (3 events).")
            let viewModel = FlushingViewModel()
            viewModel.flushData()

            XCTAssertTrue(viewModel.showFlushResultDialog)
            XCTAssertEqual(viewModel.flushResultTitle, "Flush successful")
            XCTAssertNil(viewModel.flushResultMessage)
            XCTAssertFalse(viewModel.isFlushing)
        }
    }

    func testFlushFailure() async {
        await withFakeService { fake in
            fake.flushResult = FlushOutcome(succeeded: false, message: "No connection")
            let viewModel = FlushingViewModel()
            viewModel.flushData()

            XCTAssertTrue(viewModel.showFlushResultDialog)
            XCTAssertEqual(viewModel.flushResultTitle, "Flush failed")
            XCTAssertEqual(viewModel.flushResultMessage, "No connection")
        }
    }

    func testAnonymizeIsSkippedWhileStopped() async throws {
        let warning = "Anonymize skipped: the SDK integration is stopped"
        try await withFakeService { fake in
            let sdkState = SdkState()
            sdkState.markInitialized(registeredId: "user_a")
            sdkState.markStopped()
            let viewModel = AnonymizeViewModel()
            viewModel.sdkState = sdkState
            viewModel.logStore = InAppLogStore.shared

            viewModel.anonymize()

            XCTAssertTrue(viewModel.showStoppedDialog)
            XCTAssertFalse(viewModel.showAnonymizedDialog)
            XCTAssertEqual(fake.recordedCalls.map(\.name), [])
            // The log store appends on the next main-queue turn.
            try await waitUntil { InAppLogStore.shared.entries.contains { $0.message == warning } }
        }
    }

    func testIdentityState() {
        let sdkState = SdkState()
        sdkState.markIdentified(registeredId: "user_a")
        XCTAssertEqual(sdkState.registeredId, "user_a")
        XCTAssertEqual(sdkState.identity, .identified)

        sdkState.markAnonymized()
        XCTAssertEqual(sdkState.registeredId, "")
        XCTAssertEqual(sdkState.identity, .anonymous)
    }

    func testRuntimeLabWithoutSdk() async throws {
        try await withFakeService { fake in
            fake.inAppContentBlocksController = nil
            let viewModel = RuntimeControllerLabViewModel()
            viewModel.start(.prefetch)

            try await waitUntil { !viewModel.isBusy }
            let last = try XCTUnwrap(viewModel.logs.last)
            XCTAssertTrue(last.hasSuffix("FAILED prefetch: SDK is not configured"), last)
        }
    }
}
