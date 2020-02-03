//
//  InAppMessageAlertViewSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 27/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class InAppMessageAlertViewSpec: QuickSpec {
    override func spec() {
        let payload = SampleInAppMessage.getSampleInAppMessage().payload

        it("should setup dialog with payload") {
            let alertView = InAppMessageAlertView(
                payload: payload,
                actionCallback: {},
                dismissCallback: {}
            )
            guard let alertController = alertView.viewController as? UIAlertController else {
                XCTFail("In-app message alert view should create UIAlertController")
                return
            }
            expect(alertController.title).to(equal(payload.title))
            expect(alertController.message).to(equal(payload.bodyText))
            expect(alertController.actions.count).to(equal(2))
            expect(alertController.actions[0].title).to(equal(payload.buttonText))
            expect(alertController.actions[0].style).to(equal(.default))
            expect(alertController.actions[1].title).to(equal("Cancel"))
            expect(alertController.actions[1].style).to(equal(.cancel))

        }
    }
}
