import XCTest
@testable import Example

/// Checks that FakeExponeaService records calls and returns its configured results.
final class ExponeaServicingContractTests: XCTestCase {

    func testFakeRecordsTrackEvent() {
        let fake = FakeExponeaService()
        fake.trackEvent(name: "demo_event", properties: [:])

        XCTAssertEqual(fake.recordedCalls.count, 1)
        XCTAssertEqual(fake.recordedCalls[0].name, "trackEvent")
        XCTAssertEqual(fake.recordedCalls[0].payload, "demo_event")
    }

    func testFakeFlushUsesConfiguredResult() {
        let fake = FakeExponeaService()
        fake.flushResult = FlushOutcome(succeeded: true, message: "Flush succeeded (3 events).")

        var outcome: FlushOutcome?
        fake.flushData { outcome = $0 }

        XCTAssertEqual(outcome, FlushOutcome(succeeded: true, message: "Flush succeeded (3 events)."))
        XCTAssertEqual(fake.recordedCalls.map(\.name), ["flushData"])
    }

    func testFakeIdentifyCustomerRecordsCall() {
        let fake = FakeExponeaService()
        fake.identifyCustomer(customerIds: ["registered": "abc"], properties: [:], jwtToken: nil)

        XCTAssertEqual(fake.recordedCalls.first?.name, "identifyCustomer")
    }
}
