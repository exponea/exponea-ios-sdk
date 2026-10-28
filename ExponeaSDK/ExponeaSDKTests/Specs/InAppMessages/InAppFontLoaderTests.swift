import XCTest
import UIKit
import CoreText
@testable import ExponeaSDK

final class InAppFontLoaderTests: XCTestCase {
    private var data: Data!
    private var graphicsFont: CGFont!
    private var postScriptName: String!

    override func setUpWithError() throws {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Self.self)
        #endif
        let url = try XCTUnwrap(bundle.url(forResource: "Abel-Regular", withExtension: "ttf"))
        data = try Data(contentsOf: url)
        graphicsFont = try XCTUnwrap(CGFont(try XCTUnwrap(CGDataProvider(data: data as CFData))))
        postScriptName = try XCTUnwrap(graphicsFont.postScriptName as String?)
    }

    private func withRegisteredFont(_ test: () throws -> Void) throws {
        var error: Unmanaged<CFError>?
        XCTAssertTrue(CTFontManagerRegisterGraphicsFont(graphicsFont, &error))
        defer { CTFontManagerUnregisterGraphicsFont(graphicsFont, nil) }
        try test()
    }

    func testAlreadyRegisteredFontResolvesAtRequestedSizeAndRemainsRegistered() throws {
        try withRegisteredFont {
            for size: CGFloat in [13, 19, 27] {
                let font = try XCTUnwrap(InAppFontLoader.load(data: data, size: size))
                XCTAssertEqual(font.fontName, postScriptName)
                XCTAssertEqual(font.pointSize, size)
            }
            // A second registration must still fail: the SDK must not remove the host registration.
            var error: Unmanaged<CFError>?
            let registeredAgain = CTFontManagerRegisterGraphicsFont(graphicsFont, &error)
            if registeredAgain { CTFontManagerUnregisterGraphicsFont(graphicsFont, nil) }
            XCTAssertFalse(registeredAgain)
            let registrationError = try XCTUnwrap(error?.takeRetainedValue())
            XCTAssertTrue([CTFontManagerError.alreadyRegistered.rawValue, CTFontManagerError.duplicatedName.rawValue]
                .contains(CFErrorGetCode(registrationError)))
            XCTAssertNotNil(UIFont(name: postScriptName, size: 16))
        }
    }

    func testUnregisteredFontLoadsAndReleasesOwnedRegistration() throws {
        let font = try XCTUnwrap(InAppFontLoader.load(data: data, size: nil))
        XCTAssertEqual(font.fontName, postScriptName)
        XCTAssertEqual(font.pointSize, 13)
        var error: Unmanaged<CFError>?
        let registered = CTFontManagerRegisterGraphicsFont(graphicsFont, &error)
        defer { if registered { CTFontManagerUnregisterGraphicsFont(graphicsFont, nil) } }
        _ = error?.takeRetainedValue()
        XCTAssertTrue(registered)
    }

    func testButtonFontDataAndCodableRestoreUseRegisteredFont() throws {
        try withRegisteredFont {
            // Omit fontName to force the bytes through registration rather than the postScriptName fast path.
            let original = InAppButtonFontData(fontSize: 23, fontData: data.base64EncodedString())
            XCTAssertEqual(original.loadedFont?.fontName, postScriptName)
            XCTAssertEqual(original.loadedFont?.pointSize, 23)
            let restored = try JSONDecoder().decode(
                InAppButtonFontData.self, from: JSONEncoder().encode(original)
            )
            XCTAssertEqual(restored.loadedFont?.fontName, postScriptName)
            XCTAssertEqual(restored.loadedFont?.pointSize, 23)
        }
    }

    func testCachedTitleBodyAndButtonPayloadResolveRegisteredFont() throws {
        try withRegisteredFont {
            let fontData: [String: Any] = [
                "fontName": postScriptName!, "fontSize": 21, "fontData": data.base64EncodedString()
            ]
            let json: [String: Any] = [
                "buttons": [["button_text": "Continue", "button_enabled": true, "fontData": fontData]],
                "title_enabled": true, "titleFontData": fontData,
                "body_enabled": true, "bodyFontData": fontData
            ]
            let payload = try JSONDecoder().decode(
                RichInAppMessagePayload.self, from: JSONSerialization.data(withJSONObject: json)
            )
            let titleFont = payload.titleFontData?.loadedFont
            let bodyFont = payload.bodyFontData?.loadedFont
            let buttonFont = payload.buttons.first?.buttonConfig?.fontData?.loadedFont
            let fonts: [UIFont?] = [titleFont, bodyFont, buttonFont]
            for font in fonts {
                XCTAssertEqual(font?.fontName, postScriptName)
                XCTAssertEqual(font?.pointSize, 21)
            }
        }
    }

    func testInvalidFontDataReturnsNil() {
        XCTAssertNil(InAppFontLoader.load(data: Data("not a font".utf8), size: 18))
        XCTAssertNil(InAppFontLoader.load(base64: "invalid", size: 18))
        XCTAssertNil(InAppFontLoader.load(base64: nil, size: 18))
    }

    func testFontRegisteredByURLLikeUIAppFontsResolves() throws {
        // Host app registers the same font by URL (as `UIAppFonts` does).
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Abel-Regular.ttf")
        try data.write(to: url)
        var error: Unmanaged<CFError>?
        XCTAssertTrue(CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error))
        defer {
            CTFontManagerUnregisterFontsForURL(url as CFURL, .process, nil)
            try? FileManager.default.removeItem(at: url)
        }
        let font = try XCTUnwrap(InAppFontLoader.load(data: data, size: 17))
        XCTAssertEqual(font.fontName, postScriptName)
        XCTAssertEqual(font.pointSize, 17)
        XCTAssertNotNil(UIFont(name: postScriptName, size: 12), "host registration must survive")
    }
}
