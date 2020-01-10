//
//  InAppMessageDialogViewControllerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class InAppMessageDialogViewControllerSpec: QuickSpec {
    override func spec() {
        let payload = SampleInAppMessage.getSampleInAppMessage().payload
        var dialog: InAppMessageDialogViewController!
        var image: UIImage!

        beforeEach {
            let storyboard = UIStoryboard(name: "InAppMessageDialog", bundle: Bundle(for: ExponeaSDK.Exponea.self))
            guard let dialogVC = storyboard.instantiateViewController(withIdentifier: "InAppMessageDialog")
                as? InAppMessageDialogViewController else {
                    XCTFail("Unable to instantiate dialog")
                    return
            }
            dialog = dialogVC

            let bundle = Bundle(for: InAppMessageDialogViewControllerSpec.self)
            image = UIImage(contentsOfFile: bundle.path(forResource: "lena", ofType: "jpeg")!)
        }

        it("should setup dialog with payload") {
            dialog.image = image
            dialog.payload = payload
            dialog.beginAppearanceTransition(true, animated: false)
            expect(dialog.bodyTextView.text).to(equal(payload.bodyText))
            expect(dialog.titleTextView.text).to(equal(payload.title))
        }
    }
}
