//
//  GdprTrackingSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 28/09/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Nimble
import Quick
import ExponeaSDKShared

final class GdprTrackingSpec: QuickSpec {

    override func spec() {
        it("should results in true from Bool") {
            expect(GdprTracking.readTrackingConsentFlag(true)).to(beTrue())
        }
        it("should results in true from String lowercase") {
            expect(GdprTracking.readTrackingConsentFlag("true")).to(beTrue())
        }
        it("should results in true from String uppercase") {
            expect(GdprTracking.readTrackingConsentFlag("TRUE")).to(beTrue())
        }
        it("should results in true from String anycase") {
            expect(GdprTracking.readTrackingConsentFlag("TrUe")).to(beTrue())
        }
        it("should results in true from String number") {
            expect(GdprTracking.readTrackingConsentFlag("1")).to(beTrue())
        }
        it("should results in true from number") {
            expect(GdprTracking.readTrackingConsentFlag(1)).to(beTrue())
        }
        it("should results in true from default nil") {
            expect(GdprTracking.readTrackingConsentFlag(nil)).to(beTrue())
        }
        it("should results in false from Bool") {
            expect(GdprTracking.readTrackingConsentFlag(false)).to(beFalse())
        }
        it("should results in false from String lowercase") {
            expect(GdprTracking.readTrackingConsentFlag("false")).to(beFalse())
        }
        it("should results in false from String uppercase") {
            expect(GdprTracking.readTrackingConsentFlag("FALSE")).to(beFalse())
        }
        it("should results in false from String anycase") {
            expect(GdprTracking.readTrackingConsentFlag("FaLsE")).to(beFalse())
        }
        it("should results in false from String number") {
            expect(GdprTracking.readTrackingConsentFlag("0")).to(beFalse())
        }
        it("should results in false from number") {
            expect(GdprTracking.readTrackingConsentFlag(0)).to(beFalse())
        }
        it("should results in false from other String") {
            expect(GdprTracking.readTrackingConsentFlag("bla bla")).to(beFalse())
        }
        it("should results in false from anything else") {
            expect(GdprTracking.readTrackingConsentFlag(Date())).to(beFalse())
        }
    }
}
