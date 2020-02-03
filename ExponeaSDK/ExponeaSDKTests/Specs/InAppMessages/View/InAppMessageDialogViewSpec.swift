//
//  InAppMessageDialogViewSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class InAppMessageDialogViewSpec: QuickSpec {
    override func spec() {
        let payload = SampleInAppMessage.getSampleInAppMessage().payload
        var image: UIImage!

        beforeEach {
            let bundle = Bundle(for: InAppMessageDialogViewSpec.self)
            image = UIImage(contentsOfFile: bundle.path(forResource: "lena", ofType: "jpeg")!)
        }

        it("should setup dialog with payload") {
            let dialog: InAppMessageDialogView = InAppMessageDialogView(
                payload: payload,
                image: image,
                actionCallback: {},
                dismissCallback: {}
            )
            dialog.viewController.beginAppearanceTransition(true, animated: false)
            expect(dialog.bodyTextView.text).to(equal(payload.bodyText))
            expect(dialog.titleTextView.text).to(equal(payload.title))
        }
    }
}
