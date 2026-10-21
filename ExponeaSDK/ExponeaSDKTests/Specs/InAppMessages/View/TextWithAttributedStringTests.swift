import XCTest
import SwiftUI
import UIKit
@testable import ExponeaSDK

final class TextWithAttributedStringTests: XCTestCase {
    private func label(_ text: String) -> InAppLabelConfig {
        InAppLabelConfig(text: text, size: 16, style: nil, isVisible: true, padding: [], fontData: nil)
    }

    private func fittingHeight(_ config: InAppLabelConfig, width: CGFloat) -> CGFloat {
        TextWithAttributedString.InternalTextView.fittingHeight(
            config: config,
            width: width,
            isCompressionVertical: false
        )
    }

    func testFittingHeightGrowsWithTheText() {
        let short = fittingHeight(label("Hello"), width: 300)
        let long = fittingHeight(label(String(repeating: "Hello world ", count: 40)), width: 300)

        XCTAssertGreaterThan(short, 0)
        XCTAssertGreaterThan(long, short)
    }

    func testFittingHeightIsZeroWithoutAWidth() {
        XCTAssertEqual(fittingHeight(label("Hello"), width: 0), 0)
    }

    func testReportsTheTextHeightOnTheFirstLayoutPass() {
        let config = label(String(repeating: "Hello world ", count: 10))
        let expectedHeight = fittingHeight(config, width: 300)
        let reported = expectation(description: "height reported")
        reported.assertForOverFulfill = false
        var firstReportedHeight: CGFloat?
        let text = TextWithAttributedString(config: config, width: 300) { height in
            if firstReportedHeight == nil {
                firstReportedHeight = height
            }
            reported.fulfill()
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 800))
        window.rootViewController = UIHostingController(rootView: text.frame(width: 300))
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        // Below the 0.5 s the text view used to wait before reporting its height.
        wait(for: [reported], timeout: 0.4)
        XCTAssertEqual(firstReportedHeight, expectedHeight)
        window.isHidden = true
    }
}
