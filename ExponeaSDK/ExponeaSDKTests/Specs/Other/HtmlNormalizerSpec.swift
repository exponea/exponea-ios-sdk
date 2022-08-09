//
//  UIColor+FromHexStringSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick
import ExponeaSDKShared

@testable import ExponeaSDK

final class HtmlNormalizerSpec: QuickSpec {
    override func spec() {

        it ("should find Close and Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())
            expect(result.actions.count).to(equal(1))
        }

        it ("should find Close and multiple Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())
            expect(result.actions.count).to(equal(2))
        }

        it ("should find Close and no Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close'>Close</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())
            expect(result.actions.count).to(equal(0))
        }

        it ("should find default Close and Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())    // default close
            expect(result.actions.count).to(equal(1))
        }

        it ("should find default Close and multiple Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())    // default close
            expect(result.actions.count).to(equal(2))
        }

        it ("should find default Close and no Action url") {
            let rawHtml = "<html><body>" +
                    "<div>Hello world</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())    // default close
            expect(result.actions.count).to(equal(0))
        }

        it ("should remove Javascript") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "<script>alert('hello')</script>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.html!.contains("script")).to(equal(false))
        }

        it ("should remove Link") {
            let rawHtml = "<html>" +
                    "<head>" +
                    "<link rel='stylesheet' href='styles.css'>" +
                    "</head>" +
                    "<body>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.html!.contains("<link")).to(equal(false))
            expect(result.html!.contains("styles.css")).to(equal(false))
        }

        /**
         Represents test, that any of HTML JS events are remove
         https://www.w3schools.com/tags/ref_eventattributes.asp
         */
        it ("should remove Inline Javascript") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.html!.contains("onclick")).to(equal(false))
            expect(result.closeActionUrl).toNot(beNil())
        }

        it ("should remove Title") {
            let rawHtml = "<html>" +
                    "<head><title>Should be removed</title></head>" +
                    "<body>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.html!.contains("title")).to(equal(false))
            expect(result.html!.contains("Should be removed")).to(equal(false))
        }

        it ("should remove Meta") {
            let rawHtml = "<html>" +
                    "<head>" +
                    "<meta name='keywords' content='HTML, CSS, JavaScript'>" +
                    "<meta name='author' content='John Doe'>" +
                    "</head>" +
                    "<body>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.html!.contains("meta")).to(equal(false))
            expect(result.html!.contains("HTML, CSS, JavaScript")).to(equal(false))
            expect(result.html!.contains("John Doe")).to(equal(false))
        }

        /**
         Removes any 'href' from file. Final html contains <a href> but only for close and action buttons and only as final HTML.
         See possible tags: https://www.w3schools.com/tags/att_href.asp
         */
        it ("should remove any Href attribute") {
            let rawHtml = "<html>" +
                    "<head>" +
                    "<base href=\"https://example/hreftoremove\" target=\"_blank\">" +
                    "<meta name='keywords' content='HTML, CSS, JavaScript'>" +
                    "<meta name='author' content='John Doe'>" +
                    "<link rel='stylesheet' href='https://example/hreftoremove'>" +
                    "</head>" +
                    "<body>" +
                    "<div href='https://example/hreftoremove'>Unexpected href location</div>" +
                    "<map name=\"workmap\">\n" +
                    "  <area shape=\"rect\" coords=\"34,44,270,350\" alt=\"Computer\" href=\"https://example/hreftoremove\">\n" +
                    "</map>" +
                    "<a href='https://example/hreftoremove'>Valid anchor link but href has to be removed</a>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.html!.contains("https://example/hreftoremove")).to(equal(false))
            expect(result.closeActionUrl).toNot(beNil())
            expect(result.actions.count).to(equal(2))
        }

        it ("should transform Image URL into Base64") {
            let cache = InAppMessagesCache()
            cache.saveImageData(at: "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg", data: "data".data(using: .utf8)!)
            let rawHtml = "<html>" +
                    "<body>" +
                    "<img src='https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg'>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.html!.contains("upload.wikimedia.org")).to(equal(false))
            expect(result.html!.contains("data:image/png;base64")).to(equal(true))
        }

        it ("should NOT transform invalid Image URL into Base64") {
            let rawHtml = "<html>" +
                    "<body>" +
                    "<img src='https://nonexisting.sk/image_that_not_exists.jpg'>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.html).to(beNil())
            expect(result.valid).to(beFalse())
        }

    }

}
