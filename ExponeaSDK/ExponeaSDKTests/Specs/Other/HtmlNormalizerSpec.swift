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

        it("should find Close and Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())
            expect(result.actions.count).to(equal(1))
        }

        it("should find Action url by datalink and ahref") {
            let rawHtml = "<html><body>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<a href='https://example.com/1'>Action 1</a>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: false, ensureCloseButton: false, allowAnchorButton: true)
            )
            expect(result.closeActionUrl).to(beNil())
            expect(result.actions.count).to(equal(2))
        }

        it("should remove target from ahref even if ahref accepted") {
            let rawHtml = "<html><body>" +
                    "<a href='https://example.com/1' target='_self'>Action 1</a>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: false, ensureCloseButton: false, allowAnchorButton: true)
            )
            expect(result.closeActionUrl).to(beNil())
            expect(result.actions.count).to(equal(1))
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("target")).to(beFalse())
        }

        it("should find Close and multiple Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())
            expect(result.actions.count).to(equal(2))
        }

        it("should find browser action") {
            let rawHtml = "<html><body>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.actions.count).to(equal(1))
            expect(result.actions[0].actionUrl).to(equal("https://example.com/1"))
        }

        it("should find deeplink action") {
            let rawHtml = "<html><body>" +
                    "<div data-link='message:%3C3358921718340173851@unknownmsgid%3E'>Action 1</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.actions.count).to(equal(1))
            expect(result.actions[0].actionUrl).to(equal("message:%3C3358921718340173851@unknownmsgid%3E"))
        }

        it("should find Close and no Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close'>Close</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())
            expect(result.actions.count).to(equal(0))
        }

        it("should find default Close and Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())    // default close
            expect(result.actions.count).to(equal(1))
        }

        it("should find default Close and multiple Action url") {
            let rawHtml = "<html><body>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())    // default close
            expect(result.actions.count).to(equal(2))
        }

        it("should find default Close and no Action url") {
            let rawHtml = "<html><body>" +
                    "<div>Hello world</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            expect(result.closeActionUrl).toNot(beNil())    // default close
            expect(result.actions.count).to(equal(0))
        }

        it("should remove Javascript") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "<script>alert('hello')</script>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("script")).to(equal(false))
        }

        it("should remove Link") {
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
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("<link")).to(equal(false))
            expect(normalizedHtml.contains("styles.css")).to(equal(false))
        }

        /**
         Represents test, that any of HTML JS events are remove
         https://www.w3schools.com/tags/ref_eventattributes.asp
         */
        it("should remove Inline Javascript") {
            let rawHtml = "<html><body>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("onclick")).to(equal(false))
            expect(result.closeActionUrl).toNot(beNil())
        }

        it("should remove Title") {
            let rawHtml = "<html>" +
                    "<head><title>Should be removed</title></head>" +
                    "<body>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("title")).to(equal(false))
            expect(normalizedHtml.contains("Should be removed")).to(equal(false))
        }

        it("should remove Meta") {
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
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("meta")).to(equal(false))
            expect(normalizedHtml.contains("HTML, CSS, JavaScript")).to(equal(false))
            expect(normalizedHtml.contains("John Doe")).to(equal(false))
        }

        /**
         Removes any 'href' from file. Final html contains <a href> but only for close and action buttons and only as final HTML.
         See possible tags: https://www.w3schools.com/tags/att_href.asp
         */
        it("should remove any Href attribute") {
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
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("https://example/hreftoremove")).to(equal(false))
            expect(result.closeActionUrl).toNot(beNil())
            expect(result.actions.count).to(equal(2))
        }

        it("should transform Image URL into Base64") {
            let cache = InAppMessagesCache()
            cache.saveImageData(
                at: "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg",
                data: "data".data(using: .utf8) ?? Data()
            )
            let rawHtml = "<html>" +
                    "<body>" +
                    "<img src='https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg'>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("upload.wikimedia.org")).to(equal(false))
            expect(normalizedHtml.contains("data:image/png;base64")).to(equal(true))
        }

        it("should NOT transform invalid Image URL into Base64") {
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

        it("should parse multiple css rules") {
            let fontImportUrl = "https://fonts.googleapis.com/css2?family=Roboto:wght@100&display=swap"
            let fontSourceUrl = "https://fonts.googleapis.com/css3?family=Roboto:wght@100"
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let imageBgUrl = "https://upload.wikimedia.org/invalid/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let fontCache = FileCache()
            fontCache.saveFileData(at: fontImportUrl, data: fakeData)
            fontCache.saveFileData(at: fontSourceUrl, data: fakeData)
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            imageCache.saveImageData(at: imageBgUrl, data: fakeData)
            let cssStyleString =
                """
                @import url('\(fontImportUrl)');
                @font-face {
                    font-family: 'Open Sans';
                    src: url('\(fontSourceUrl)') format('woff');
                    font-weight: 700;
                    font-style: normal;
                }
                .img-style {
                    background-image: url('\(imageBgImgUrl)')
                }
                .img-style-short {
                    background: url('\(imageBgUrl)') bottom right repeat-x blue;
                }
                """
            let htmlString =
            """
            <html><head><style>\(cssStyleString)</style></head><body></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(fontImportUrl)).to(beFalse())
            expect(htmlOutput.contains(fontSourceUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgUrl)).to(beFalse())
        }

        it("should transform Image URL from CSS into Base64") {
            let cache = InAppMessagesCache()
            cache.saveImageData(
                at: "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg",
                data: "data".data(using: .utf8) ?? Data()
            )
            let rawHtml = "<html>" +
                    "<head>" +
                    "<style>" +
                    ".img-style { background-image: url('https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg') }"
                    "</style>" +
                    "</head>" +
                    "<body>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = HtmlNormalizer(rawHtml).normalize()
            guard let normalizedHtml = result.html else {
                fail("Normalized HTML missing")
                return
            }
            expect(normalizedHtml.contains("upload.wikimedia.org")).to(equal(false))
            expect(normalizedHtml.contains("data:image/png;base64")).to(equal(true))
        }

        it("should parse single lined css rules") {
            let fontImportUrl = "https://fonts.googleapis.com/css2?family=Roboto:wght@100&display=swap"
            let fontSourceUrl = "https://fonts.googleapis.com/css3?family=Roboto:wght@100"
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let imageBgUrl = "https://upload.wikimedia.org/invalid/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let fontCache = FileCache()
            fontCache.saveFileData(at: fontImportUrl, data: fakeData)
            fontCache.saveFileData(at: fontSourceUrl, data: fakeData)
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            imageCache.saveImageData(at: imageBgUrl, data: fakeData)
            let cssStyleString =
                """
                @font-face { font-family: 'Open Sans'; src: url('\(fontSourceUrl)') format('woff'); font-weight: 700; font-style: normal; }
                .img-style { background-image: url('\(imageBgImgUrl)') }
                .img-style-short { background: url('\(imageBgUrl)') bottom right repeat-x blue; }
                """
            let htmlString =
            """
            <html><head><style>\(cssStyleString)</style></head><body></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(fontImportUrl)).to(beFalse())
            expect(htmlOutput.contains(fontSourceUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgUrl)).to(beFalse())
        }

        it("should parse single lined css") {
            let fontImportUrl = "https://fonts.googleapis.com/css2?family=Roboto:wght@100&display=swap"
            let fontSourceUrl = "https://fonts.googleapis.com/css3?family=Roboto:wght@100"
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let imageBgUrl = "https://upload.wikimedia.org/invalid/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let fontCache = FileCache()
            fontCache.saveFileData(at: fontImportUrl, data: fakeData)
            fontCache.saveFileData(at: fontSourceUrl, data: fakeData)
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            imageCache.saveImageData(at: imageBgUrl, data: fakeData)
            let cssStyleString =
                """
                @font-face { font-family: 'Open Sans'; src: url('\(fontSourceUrl)') format('woff'); font-weight: 700; font-style: normal; } .img-style { background-image: url('\(imageBgImgUrl)') } .img-style-short { background: url('\(imageBgUrl)') bottom right repeat-x blue; }
                """
            let htmlString =
            """
            <html><head><style>\(cssStyleString)</style></head><body></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(fontImportUrl)).to(beFalse())
            expect(htmlOutput.contains(fontSourceUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgUrl)).to(beFalse())
        }

        it("should parse single css style attribute") {
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let fontCache = FileCache()
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            let cssAttrStyleString = "background-image: url('\(imageBgImgUrl)')"
            let htmlString =
            """
            <html><body style="\(cssAttrStyleString)"></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
        }

        it("should parse multiple css style attribute") {
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let imageBgUrl = "https://upload.wikimedia.org/invalid/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let fontCache = FileCache()
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            imageCache.saveImageData(at: imageBgUrl, data: fakeData)
            let cssAttrStyleString =
            """
            background-image: url('\(imageBgImgUrl)'); background: url('\(imageBgUrl)') bottom right repeat-x blue
            """
            let htmlString =
            """
            <html><body style="\(cssAttrStyleString)"></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgUrl)).to(beFalse())
        }

        it("should parse single css style attribute with apostrophes") {
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let fontCache = FileCache()
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            let cssAttrStyleString = "background-image: url('\(imageBgImgUrl)')"
            let htmlString =
            """
            <html><body style="\(cssAttrStyleString)"></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
        }

        it("should parse single css style attribute with quotes") {
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            let cssAttrStyleString = "background-image: url(\"\(imageBgImgUrl)\")"
            let htmlString =
            """
            <html><body style="\(cssAttrStyleString)"></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
        }

        it("should parse single css style attribute without punctuation") {
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            let cssAttrStyleString = "background-image: url(\(imageBgImgUrl))"
            let htmlString =
            """
            <html><body style="\(cssAttrStyleString)"></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
        }

        it("should parse multiple css rule without punctuation") {
            let fontImportUrl = "https://fonts.googleapis.com/css2?family=Roboto:wght@100&display=swap"
            let fontSourceUrl = "https://fonts.googleapis.com/css3?family=Roboto:wght@100"
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let imageBgUrl = "https://upload.wikimedia.org/invalid/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let fontCache = FileCache()
            fontCache.saveFileData(at: fontImportUrl, data: fakeData)
            fontCache.saveFileData(at: fontSourceUrl, data: fakeData)
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            imageCache.saveImageData(at: imageBgUrl, data: fakeData)
            let cssStyleString =
                """
                @import url(\(fontImportUrl));
                @font-face {
                    font-family: 'Open Sans';
                    src: url(\(fontSourceUrl)) format('woff');
                    font-weight: 700;
                    font-style: normal;
                }
                .img-style {
                    background-image: url(\(imageBgImgUrl))
                }
                .img-style-short {
                    background: url(\(imageBgUrl)) bottom right repeat-x blue;
                }
                """
            let htmlString =
            """
            <html><head><style>\(cssStyleString)</style></head><body></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(fontImportUrl)).to(beFalse())
            expect(htmlOutput.contains(fontSourceUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgUrl)).to(beFalse())
        }

        it("should parse multiple css rule with quotes") {
            let fontImportUrl = "https://fonts.googleapis.com/css2?family=Roboto:wght@100&display=swap"
            let fontSourceUrl = "https://fonts.googleapis.com/css3?family=Roboto:wght@100"
            let imageBgImgUrl = "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg"
            let imageBgUrl = "https://upload.wikimedia.org/invalid/Gull_portrait_ca_usa.jpg"
            let fakeData = "data".data(using: .utf8) ?? Data()
            let fontCache = FileCache()
            fontCache.saveFileData(at: fontImportUrl, data: fakeData)
            fontCache.saveFileData(at: fontSourceUrl, data: fakeData)
            let imageCache = InAppMessagesCache()
            imageCache.saveImageData(at: imageBgImgUrl, data: fakeData)
            imageCache.saveImageData(at: imageBgUrl, data: fakeData)
            let cssStyleString =
                """
                @import url(\"\(fontImportUrl)\");
                @font-face {
                    font-family: 'Open Sans';
                    src: url(\"\(fontSourceUrl)\") format('woff');
                    font-weight: 700;
                    font-style: normal;
                }
                .img-style {
                    background-image: url(\"\(imageBgImgUrl)\")
                }
                .img-style-short {
                    background: url(\"\(imageBgUrl)\") bottom right repeat-x blue;
                }
                """
            let htmlString =
            """
            <html><head><style>\(cssStyleString)</style></head><body></body></html>
            """
            let result = HtmlNormalizer(htmlString).normalize(HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: false)
            )
            expect(result.valid).to(beTrue())
            guard let htmlOutput = result.html else {
                fail("HTML has not been parsed")
                return
            }
            expect(htmlOutput.contains(fontImportUrl)).to(beFalse())
            expect(htmlOutput.contains(fontSourceUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgImgUrl)).to(beFalse())
            expect(htmlOutput.contains(imageBgUrl)).to(beFalse())
        }

        it("check url") {
            var urls: [String] = [
                "pltapp://category/categories<{defaultcategory2_shopby233}/categories<{defaultcategory2_shopby233_backinstock221}?adjust_tracker=74p1fnr&adjust_campaign=PROMOTIONAL&adjust_adgroup=2023-06-19-ALL-FR&adjust_creative=CATEGORY",
                "pltapp://category/categories<%7Bdefaultcategory2_shopby233%7D/categories<%7Bdefaultcategory2_shopby233_backinstock221%7D?adjust_tracker=74p1fnr&adjust_campaign=PROMOTIONAL&adjust_adgroup=2023-06-19-ALL-FR&adjust_creative=CATEGORY",
                "pltapp://category/categories%3C%7Bdefaultcategory2_shopby233%7D/categories%3C%7Bdefaultcategory2_shopby233_backinstock221%7D?adjust_tracker=74p1fnr&adjust_campaign=PROMOTIONAL&adjust_adgroup=2023-06-19-ALL-FR&adjust_creative=CATEGORY",
            ]
            let cleanedURL = urls.compactMap { $0.cleanedURL() }.count
            expect(cleanedURL).to(equal(3))
            if let firstURL = urls.first?.cleanedURL()?.absoluteString, let lastURL = urls.last {
                expect(firstURL).to(equal(lastURL))
            }
            if let firstURL = urls[2].cleanedURL()?.absoluteString, let lastURL = urls.last {
                expect(firstURL).to(equal(lastURL))
            }
        }
    }
}
