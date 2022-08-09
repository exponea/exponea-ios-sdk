//
// Created by Adam Mihalik on 23/06/2022.
// Copyright (c) 2022 Exponea. All rights reserved.
//

import Foundation
import SwiftSoup

public class HtmlNormalizer {

    private let closeActionCommand = "close_action"
    private let closeButtonAttrDef = "data-actiontype='close'"
    private let closeButtonSelector = "[data-actiontype='close']"
    private let actionButtonAttr = "data-link"
    private let actionButtonSelector = "[data-link^=http]"

    private let hrefAttr = "href"
    private let metaTagSelector = "meta"
    private let scriptTagSelector = "script"
    private let titleTagSelector = "title"
    private let linkTagSelector = "link"
    private let iframeTagSelector = "iframe"

    /**
     Inline javascript attributes. Listed here https://www.w3schools.com/tags/ref_eventattributes.asp
     */
    private let inlineScriptAttributes = [
        "onafterprint", "onbeforeprint", "onbeforeunload", "onerror", "onhashchange", "onload", "onmessage",
        "onoffline", "ononline", "onpagehide", "onpageshow", "onpopstate", "onresize", "onstorage", "onunload",
        "onblur", "onchange", "oncontextmenu", "onfocus", "oninput", "oninvalid", "onreset", "onsearch",
        "onselect", "onsubmit", "onkeydown", "onkeypress", "onkeyup", "onclick", "ondblclick", "onmousedown",
        "onmousemove", "onmouseout", "onmouseover", "onmouseup", "onmousewheel", "onwheel", "ondrag",
        "ondragend", "ondragenter", "ondragleave", "ondragover", "ondragstart", "ondrop", "onscroll", "oncopy",
        "oncut", "onpaste", "onabort", "oncanplay", "oncanplaythrough", "oncuechange", "ondurationchange",
        "onemptied", "onended", "onerror", "onloadeddata", "onloadedmetadata", "onloadstart", "onpause",
        "onplay", "onplaying", "onprogress", "onratechange", "onseeked", "onseeking", "onstalled", "onsuspend",
        "ontimeupdate", "onvolumechange", "onwaiting", "ontoggle"
    ]

    private var document: Document?

    private let imageCache: InAppMessagesCacheType

    public init(_ originalHtml: String) {
        imageCache = InAppMessagesCache()
        do {
            document = try SwiftSoup.parse(originalHtml)
        } catch {
            Exponea.logger.log(
                    .verbose,
                    message: "[HTML] Unable to parse original HTML source code \(originalHtml)"
            )
            document = nil
        }
    }

    public func normalize() -> NormalizedResult {
        var result = NormalizedResult()
        do {
            try cleanHtml()
            try makeImagesToBeOffline()
            try result.closeActionUrl = ensureCloseButton()
            try result.actions = ensureActionButtons()
            result.html = exportHtml()
        } catch let error {
            Exponea.logger.log(.error, message: "[HTML] Html has not been processed due to error \(error)")
            result.valid = false
        }
        return result
    }

    private func exportHtml() -> String? {
        if (document == nil) {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no HTML to export")
            return nil
        }
        do {
            let result = try document!.html()
            Exponea.logger.log(.verbose, message: "[HTML] Output is:\n \(String(describing: result))")
            return result
        } catch let error {
            Exponea.logger.log(.error, message: "[HTML] Output cannot be exported: \(error)")
            return nil
        }
    }

    private func ensureActionButtons() throws -> [ActionInfo] {
        var result: [ActionInfo] = []
        if (document == nil) {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no Action buttons")
            return result
        }
        let actionButtons = try document!.select(actionButtonSelector)
        for actionButton in actionButtons.array() {
            let targetAction = try actionButton.attr(actionButtonAttr)
            if (targetAction.isEmpty) {
                // TODO: internal event?
                Exponea.logger.log(.error, message: "[HTML] Action button found but with empty action")
                continue
            }
            if (try actionButton.parent() == nil || actionButton.parent()!.iS("a") == false) {
                Exponea.logger.log(.verbose, message: "[HTML] Wrapping Action button with a-href")
                // randomize class name => prevents from CSS styles overriding in HTML
                let actionButtonHrefClass = "action-button-href-\(UUID().uuidString)"
                try document!.head()?.append("<style>" +
                        ".\(actionButtonHrefClass) {" +
                        "    text-decoration: none;" +
                        "}" +
                        "</style>")
                try actionButton.wrap("<a href='\(targetAction)' class='\(actionButtonHrefClass)'></a>")
            }
            result.append(ActionInfo(buttonText: try actionButton.html(), actionUrl: targetAction))
        }
        return result
    }

    private func ensureCloseButton() throws -> String {
        if (document == nil) {
            // defined or default has to exist
            throw ExponeaError.unknownError("Action close cannot be ensured")
        }
        var closeButtons = try document!.select(closeButtonSelector)
        if (closeButtons.isEmpty()) {
            Exponea.logger.log(
                    .verbose,
                    message: "[HTML] Adding default close-button"
            )
            // randomize class name => prevents from CSS styles overriding in HTML
            let closeButtonClass = "close-button-\(UUID().uuidString)"
            try document!.body()!.append("<div \(closeButtonAttrDef) class='\(closeButtonClass)'><div>")
            try document!.head()!.append("""
                        <style>
                            .\(closeButtonClass) {
                              display: inline-block;
                              position: absolute;
                              width: 36px;
                              height: 36px;
                              top: 10px;
                              right: 10px;
                              border: 2px solid #C0C0C099;
                              border-radius: 50%;
                              background-color: #FAFAFA99;
                             }
                            .\(closeButtonClass):before {
                              content: '×';
                              position: absolute;
                              display: flex;
                              justify-content: center;
                              width: 36px;
                              height: 36px;
                              color: #C0C0C099;
                              font-size: 36px;
                              line-height: 36px;
                            }
                        </style>
                        """)
            closeButtons = try document!.select(closeButtonSelector)
        }
        if (closeButtons.isEmpty()) {
            // defined or default has to exist
            throw ExponeaError.unknownError("Action close cannot be ensured")
        }
        // randomize class name => prevents from CSS styles overriding in HTML
        let closeButtonHrefClass = "close-button-href-\(UUID().uuidString)"
        // link has to be valid URL, but is handled by String comparison anyway
        let closeActionLink = "https://exponea.com/\(closeActionCommand)"
        let closeButton = closeButtons.first()!
        if (try closeButton.parent()!.iS("a") == false) {
            Exponea.logger.log(.verbose, message: "[HTML] Wrapping Close button with a-href")
            try closeButton.wrap("<a href='\(closeActionLink)' class='\(closeButtonHrefClass)'></a>")
        } else if (try closeButton.parent()!.attr("href") != closeActionLink) {
            Exponea.logger.log(
                    .verbose,
                    message: "[HTML] Fixing parent a-href link to close action"
            )
            try closeButton.parent()!.attr("href", closeActionLink)
            try closeButton.parent()!.addClass(closeButtonHrefClass)
        }
        return closeActionLink
    }

    private func makeImagesToBeOffline() throws {
        if (document == nil) {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no Image to process")
            return
        }
        for imageEl in try document!.select("img").array() {
            try imageEl.attr("src", asBase64Image(imageEl.attr("src")) ?? "")
        }
    }

    public func collectImages() -> [String]? {
        if (document == nil) {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no Image to process")
            return []
        }
        var target: [String] = []
        do {
            for imageEl in try document!.select("img").array() {
                guard let imgSrc = try? imageEl.attr("src"), !imgSrc.isEmpty else {
                    continue    // empty src
                }
                target.append(imgSrc)
            }
        } catch let error {
            Exponea.logger.log(.warning, message: "[HTML] Failure while reading image source: \(error)")
        }
        return target
    }

    /**
     According to https://en.wikipedia.org/wiki/Data_URI_scheme#Syntax
     data:[<media type>][;charset=<character set>][;base64],<data>
     */
    private func isBase64Uri(_ uri: String?) -> Bool {
        uri?.starts(with: "data:image/") ?? false && uri?.contains("base64,") ?? false
    }

    private func asBase64Image(_ imageSource: String?) throws -> String? {
        if (imageSource == nil) {
            return nil
        }
        if (isBase64Uri(imageSource)) {
            return imageSource
        }
        let imageData = imageCache.getImageData(at: imageSource!)
        if (imageData == nil) {
            Exponea.logger.log(
                    .error,
                    message: "[HTML] Image uri \(String(describing: imageSource)) cannot be transformed into Base64"
            )
            throw ParsingError.imageError
        }
        // image type is not needed to be checked from source, WebView will fix it anyway...
        return "data:image/png;base64," + imageData!.base64EncodedString()
    }

    private func cleanHtml() throws {
        try removeAttributes(hrefAttr)   // !!! Has to be called before #ensureCloseButton and #ensureActionButtons.
        for attribute in inlineScriptAttributes {
            try removeAttributes(attribute)
        }
        try removeElements(metaTagSelector)
        try removeElements(scriptTagSelector)
        try removeElements(titleTagSelector)
        try removeElements(linkTagSelector)
        try removeElements(iframeTagSelector)
    }

    private func removeElements(_ selector: String) throws {
        if (document == nil) {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no elements removing")
            return
        }
        try document!.select(selector).remove()
    }

    /**
     Removes 'href' attribute from HTML elements
     !!! Has to be called before 'ensureCloseButton' and 'ensureActionButtons'
     */
    private func removeAttributes(_ attribute: String) throws {
        if (document == nil) {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no Attributes removing")
            return
        }
        try document!.select("[\(attribute)]").removeAttr(attribute)
    }

}

public enum ParsingError: Error {
    case imageError
}

public struct NormalizedResult {
    public var valid = true
    public var actions: [ActionInfo] = []
    public var closeActionUrl: String? = nil
    public var html: String? = nil
}

public struct ActionInfo {
    public var buttonText: String
    public var actionUrl: String
}
