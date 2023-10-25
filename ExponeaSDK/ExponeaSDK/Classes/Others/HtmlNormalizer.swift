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
    private let datalinkButtonSelector = "[data-link]"
    private let anchorlinkButtonSelector = "a[href]"

    private let hrefAttr = "href"
    private let anchorTagSelector = "a"
    private let metaTagSelector = "meta:not([name='viewport'])"
    private let scriptTagSelector = "script"
    private let titleTagSelector = "title"
    private let linkTagSelector = "link"
    private let iframeTagSelector = "iframe"

    private let imageMimetype = "image/png"
    private let fontMimetype = "application/font"

    private let cssUrlRegexp = try! NSRegularExpression(
        pattern: "url\\((.+?)\\)",
        options: [.caseInsensitive, .dotMatchesLineSeparators]
    )

    private let cssImportUrlRegexp = try! NSRegularExpression(
        pattern: "@import[\\s]+url\\(.+?\\)",
        options: [.caseInsensitive, .dotMatchesLineSeparators]
    )

    private static let cssKeyFormat = "-?[_a-zA-Z]+[_a-zA-Z0-9-]*"
    private static let cssDelimiterFormat = "[\\s]*:[\\s]*"
    private static let cssValueFormat = "[^;\\n]+"
    private static let keyGroupName = "attrKey"
    private static let valueGroupName = "attrVal"

    /**
     Valid CSS key is defined https://www.w3.org/TR/CSS21/syndata.html#characters
     */
    private let cssAttributeRegexp = try! NSRegularExpression(
        pattern: "(?<\(keyGroupName)>\(cssKeyFormat))\(cssDelimiterFormat)(?<\(valueGroupName)>\(cssValueFormat))",
        options: [.caseInsensitive, .anchorsMatchLines]
    )

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

    private let anchorLinkAttributes = [
        "download", "ping", "target"
    ]

    private let supportedCssUrlProperties = [
        "background", "background-image", "border-image", "border-image-source", "content", "cursor", "filter",
        "list-style", "list-style-image", "mask", "mask-image", "offset-path", "src"
    ]

    private var document: Document?

    private let imageCache: InAppMessagesCacheType

    private let fontCache: FileCacheType

    public init(_ originalHtml: String) {
        imageCache = InAppMessagesCache()
        fontCache = FileCache()
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

    public func normalize(_ config: HtmlNormalizerConfig? = nil) -> NormalizedResult {
        let parsingConf = config ?? HtmlNormalizerConfig(
            makeResourcesOffline: true, ensureCloseButton: true
        )
        var result = NormalizedResult()
        do {
            try cleanHtml()
            if parsingConf.makeResourcesOffline {
                try makeResourcesToBeOffline()
            }
            try result.actions = ensureActionButtons()
            try result.closeActionUrl = detectCloseButton(parsingConf.ensureCloseButton)
            result.html = exportHtml()
        } catch let error {
            Exponea.logger.log(.error, message: "[HTML] Html has not been processed due to error \(error)")
            result.valid = false
        }
        return result
    }

    private func exportHtml() -> String? {
        guard let document = document else {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no HTML to export")
            return nil
        }
        do {
            let result = try document.html()
            Exponea.logger.log(.verbose, message: "[HTML] Output is:\n \(String(describing: result))")
            return result
        } catch let error {
            Exponea.logger.log(.error, message: "[HTML] Output cannot be exported: \(error)")
            return nil
        }
    }

    private func ensureActionButtons() throws -> [ActionInfo] {
        var result: [String: ActionInfo] = [:]
        guard let document = document else {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no Action buttons")
            return []
        }
        // collect 'data-link' first as it may update href
        try collectDataLinkButtons(document).forEach { action in
            result[action.actionUrl] = action
        }
        try collectAnchorLinkButtons(document).forEach { action in
            result[action.actionUrl] = action
        }
        return Array(result.values)
    }

    private func collectAnchorLinkButtons(_ document: Document) throws -> [ActionInfo] {
        var result: [ActionInfo] = []
        let anchorlinkButtons = try document.select(anchorlinkButtonSelector)
        for actionButton in anchorlinkButtons.array() {
            let targetAction = try actionButton.attr(hrefAttr)
            if targetAction.isEmpty {
                Exponea.logger.log(.error, message: "[HTML] Action button found but with empty action")
                continue
            }
            result.append(ActionInfo(buttonText: try actionButton.text(), actionUrl: targetAction))
        }
        return result
    }

    private func collectDataLinkButtons(_ document: Document) throws -> [ActionInfo] {
        var result: [ActionInfo] = []
        let datalinkButtons = try document.select(datalinkButtonSelector)
        for actionButton in datalinkButtons.array() {
            let targetAction = try actionButton.attr(actionButtonAttr)
            if targetAction.isEmpty {
                Exponea.logger.log(.error, message: "[HTML] Action button found but with empty action")
                continue
            }
            if try actionButton.iS(anchorTagSelector) {
                try actionButton.attr(hrefAttr, targetAction)
            } else if try actionButton.parent() == nil || actionButton.parent()!.iS(anchorTagSelector) == false {
                Exponea.logger.log(.verbose, message: "[HTML] Wrapping Action button with a-href")
                // randomize class name => prevents from CSS styles overriding in HTML
                let actionButtonHrefClass = "action-button-href-\(UUID().uuidString)"
                try document.head()?.append("""
                    <style>
                    .\(actionButtonHrefClass) {
                        text-decoration: none;
                    }
                    </style>
                    """)
                try actionButton.wrap("<a href='\(targetAction)' class='\(actionButtonHrefClass)'></a>")
            }
            result.append(ActionInfo(buttonText: try actionButton.text(), actionUrl: targetAction))
        }
        return result
    }

    private func detectCloseButton(_ ensureCloseButton: Bool) throws -> String? {
        guard let document = document,
              let htmlBody = document.body(),
              let htmlHead = document.head() else {
            // defined or default has to exist
            throw ExponeaError.unknownError("Action close cannot be ensured")
        }
        var closeButtons = try document.select(closeButtonSelector)
        if closeButtons.isEmpty() && ensureCloseButton {
            Exponea.logger.log(
                    .verbose,
                    message: "[HTML] Adding default close-button"
            )
            // randomize class name => prevents from CSS styles overriding in HTML
            let closeButtonClass = "close-button-\(UUID().uuidString)"
            let buttonSize = "max(min(5vw, 5vh), 16px)"
            try htmlBody.append("<div \(closeButtonAttrDef) class='\(closeButtonClass)'><div>")
            try htmlHead.append("""
                        <style>
                            .\(closeButtonClass) {
                              display: inline-block;
                              position: absolute;
                              width: \(buttonSize);
                              height: \(buttonSize);
                              top: 10px;
                              right: 10px;
                              cursor: pointer;
                              border-radius: 50%;
                              background-color: rgba(250, 250, 250, 0.6);
                             }
                            .\(closeButtonClass):before {
                              content: '×';
                              position: absolute;
                              display: flex;
                              justify-content: center;
                              width: \(buttonSize);
                              height: \(buttonSize);
                              color: rgb(0, 0, 0);
                              font-size: \(buttonSize);
                              line-height: \(buttonSize);
                            }
                        </style>
                        """)
            closeButtons = try document.select(closeButtonSelector)
        }
        guard let closeButton = closeButtons.first(),
              let closeButtonParent = closeButton.parent() else {
            if ensureCloseButton {
                // defined or default has to exist
                throw ExponeaError.unknownError("Action close cannot be ensured")
            } else {
                return nil
            }
        }
        // randomize class name => prevents from CSS styles overriding in HTML
        let closeButtonHrefClass = "close-button-href-\(UUID().uuidString)"
        // link has to be valid URL, but is handled by String comparison anyway
        let closeActionLink = "https://exponea.com/\(closeActionCommand)"
        if try closeButtonParent.iS(anchorTagSelector) == false {
            Exponea.logger.log(.verbose, message: "[HTML] Wrapping Close button with a-href")
            try closeButton.wrap("<a href='\(closeActionLink)' class='\(closeButtonHrefClass)'></a>")
        } else if try closeButtonParent.attr("href") != closeActionLink {
            Exponea.logger.log(
                    .verbose,
                    message: "[HTML] Fixing parent a-href link to close action"
            )
            try closeButtonParent.attr("href", closeActionLink)
            try closeButtonParent.addClass(closeButtonHrefClass)
        }
        return closeActionLink
    }

    private func makeResourcesToBeOffline() throws {
        guard document != nil else {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no Image to process")
            return
        }
        try makeImageTagsToBeOffline()
        try makeStylesheetsToBeOffline()
        try makeStyleAttributesToBeOffline()
    }

    private func makeImageTagsToBeOffline() throws {
        guard let imageElements = try? document?.select("img").array() else {
            return
        }
        for imageEl in imageElements {
            do {
                try imageEl.attr("src", asBase64Image(imageEl.attr("src")) ?? "")
            } catch let error {
                let elSelector = try? imageEl.cssSelector()
                Exponea.logger.log(
                    .error,
                    message: "[HTML] Image \(elSelector ?? "<unknown>") cannot be processed: \(error.localizedDescription)"
                )
                throw error
            }
        }
    }

    private func makeStyleAttributesToBeOffline() throws {
        guard let styledElements = try? document?.select("[style]").array() else {
            return
        }
        for styledEl in styledElements {
            guard let styleAttrSource = try? styledEl.attr("style") else {
                continue
            }
            do {
                try styledEl.attr("style", downloadOnlineResources(styleAttrSource))
            } catch let error {
                let elSelector = try? styledEl.cssSelector()
                Exponea.logger.log(
                    .error,
                    message: "[HTML] Element \(elSelector ?? "<unknown>") not updated: \(error.localizedDescription)"
                )
                throw error
            }
        }
    }

    private func downloadOnlineResources(_ styleSource: String) -> String {
        let onlineStatements = collectUrlStatements(styleSource)
        var styleTarget = styleSource
        for statement in onlineStatements {
            let dataBase64: String?
            switch statement.mimeType {
            case fontMimetype:
                dataBase64 = try? asFontBase64(statement.url)
            case imageMimetype:
                dataBase64 = try? asBase64Image(statement.url)
            default:
                dataBase64 = nil
                Exponea.logger.log(.error, message: "Unsupported mime type \(statement.mimeType)")
            }
            guard let dataBase64 = dataBase64 else {
                Exponea.logger.log(.error, message: "Unable to make offline resource \(statement.url)")
                continue
            }
            styleTarget = styleTarget.replacingOccurrences(
                of: statement.url,
                with: dataBase64
            )
        }
        return styleTarget
    }

    private func makeStylesheetsToBeOffline() throws {
        guard let styleTags = try? document?.select("style").array() else {
            return
        }
        for styledTag in styleTags {
            let styleSource = styledTag.data()
            do {
                try styledTag.text(downloadOnlineResources(styleSource))
            } catch let error {
                Exponea.logger.log(.error, message: "[HTML] Element <style> not updated: \(error.localizedDescription)")
                throw error
            }
        }
    }

    private func collectUrlStatements(_ cssStyle: String) -> [CssOnlineUrl] {
        var result: [CssOnlineUrl] = []
        // CSS @import search
        let cssImportMatches = cssImportUrlRegexp.matchesAsStrings(in: cssStyle)
        for importRule in cssImportMatches {
            let importUrlMatches = cssUrlRegexp.groupsAsStrings(in: importRule)
            for importUrl in importUrlMatches {
                result.append(CssOnlineUrl(
                    mimeType: fontMimetype,
                    url: importUrl.trimmingCharacters(in: CharacterSet(["'", "\""]))
                ))
            }
        }
        // CSS definitions search
        let cssDefinitionMatches = cssAttributeRegexp.matches(in: cssStyle)
        for cssDefinitionMatch in cssDefinitionMatches {
            let cssKey = cssDefinitionMatch.rangeAsString(
                withName: HtmlNormalizer.keyGroupName,
                from: cssStyle
            )
            if cssKey == nil || !supportedCssUrlProperties.contains(cssKey!.lowercased()) {
                // skip
                continue
            }
            let cssValue = cssDefinitionMatch.rangeAsString(
                withName: HtmlNormalizer.valueGroupName,
                from: cssStyle
            )
            guard let cssValue = cssValue else {
                continue
            }
            let urlValueMatches = cssUrlRegexp.groupsAsStrings(in: cssValue)
            for urlValue in urlValueMatches {
                result.append(CssOnlineUrl(
                    mimeType: cssKey == "src" ? fontMimetype : imageMimetype,
                    url: urlValue.trimmingCharacters(in: CharacterSet(["'", "\""]))
                ))
            }
        }
        return result
    }

    public func collectImages() -> [String] {
        guard let document = document else {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no Image to process")
            return []
        }
        var onlineUrls: [String] = []
        // images
        do {
            for imageEl in try document.select("img").array() {
                guard let imgSrc = try? imageEl.attr("src"),
                      !imgSrc.isEmpty,
                      !isBase64Uri(imgSrc) else {
                    continue    // empty or offline src
                }
                onlineUrls.append(imgSrc)
            }
        } catch let error {
            Exponea.logger.log(.warning, message: "[HTML] Failure while reading image source: \(error)")
        }
        // style tags
        do {
            for styleTag in try document.select("style").array() {
                let styleSource = styleTag.data()
                let onlineSources = collectUrlStatements(styleSource)
                let imageOnlineSources = onlineSources.filter { $0.mimeType == imageMimetype }
                onlineUrls.append(contentsOf: imageOnlineSources.map { $0.url })
            }
        } catch let error {
            Exponea.logger.log(.warning, message: "[HTML] Failure while reading style tag source: \(error)")
        }
        // style attributes
        do {
            for styledEl in try document.select("[style]").array() {
                guard let styleAttrSource = try? styledEl.attr("style") else {
                    continue
                }
                let onlineSources = collectUrlStatements(styleAttrSource)
                let imageOnlineSources = onlineSources.filter { $0.mimeType == imageMimetype }
                onlineUrls.append(contentsOf: imageOnlineSources.map { $0.url })
            }
        } catch let error {
            Exponea.logger.log(.warning, message: "[HTML] Failure while reading style attribute source: \(error)")
        }
        // end
        return onlineUrls
    }

    /**
     According to https://en.wikipedia.org/wiki/Data_URI_scheme#Syntax
     data:[<media type>][;charset=<character set>][;base64],<data>
     */
    private func isBase64Uri(_ uri: String?) -> Bool {
        guard let uri = uri else {
            return false
        }
        return uri.starts(with: "data:") && uri.contains("base64,")
    }

    private func asBase64Image(_ imageSource: String?) throws -> String? {
        guard let imageSource = imageSource else {
            return nil
        }
        if isBase64Uri(imageSource) {
            return imageSource
        }
        var imageData = imageCache.getImageData(at: imageSource)
        if imageData == nil {
            imageData = ImageUtils.tryDownloadImage(imageSource)
            if let imageData = imageData {
                imageCache.saveImageData(at: imageSource, data: imageData)
            }
        }
        guard let imageData = imageData else {
            Exponea.logger.log(
                    .error,
                    message: "[HTML] Image uri \(String(describing: imageSource)) cannot be transformed into Base64"
            )
            throw ParsingError.imageError
        }
        // image type is not needed to be checked from source, WebView will fix it anyway...
        return "data:image/png;base64," + imageData.base64EncodedString()
    }

    private func asFontBase64(_ fontUrl: String?) throws -> String? {
        guard let fontUrl = fontUrl else {
            return nil
        }
        if isBase64Uri(fontUrl) {
            return fontUrl
        }
        var fontData = fontCache.getFileData(at: fontUrl)
        if fontData == nil {
            fontData = FileUtils.tryDownloadFile(fontUrl)
            if let fontData = fontData {
                fontCache.saveFileData(at: fontUrl, data: fontData)
            }
        }
        guard let fontData = fontData else {
            Exponea.logger.log(
                    .error,
                    message: "[HTML] Font uri \(String(describing: fontUrl)) cannot be transformed into Base64"
            )
            throw ParsingError.imageError
        }
        // font type is not needed to be checked from source, WebView will fix it anyway...
        return "data:\(fontMimetype);charset=utf-8;base64," + fontData.base64EncodedString()
    }

    private func cleanHtml() throws {
        // !!! Remove HREF attr has to be called before #ensureCloseButton and #ensureActionButtons.
        try removeAttributes(hrefAttr, skipTag: anchorTagSelector)
        for attribute in anchorLinkAttributes {
            try removeAttributes(attribute)
        }
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
        guard let document = document else {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no elements removing")
            return
        }
        try document.select(selector).remove()
    }

    /**
     Removes 'href' attribute from HTML elements
     */
    private func removeAttributes(_ attribute: String, skipTag: String? = nil) throws {
        guard let document = document else {
            Exponea.logger.log(.warning, message: "[HTML] Document has not been initialized, no Attributes removing")
            return
        }
        try document.select("[\(attribute)]")
            .compactMap { $0 }
            .filter { try skipTag == nil || !$0.iS(skipTag!) }
            .forEach { try $0.removeAttr(attribute) }
    }

}

public enum ParsingError: Error {
    case imageError
}

public struct NormalizedResult {
    public var valid = true
    public var actions: [ActionInfo] = []
    public var closeActionUrl: String?
    public var html: String?
}

public struct ActionInfo {
    public var buttonText: String
    public var actionUrl: String
}

public struct HtmlNormalizerConfig {
    public let makeResourcesOffline: Bool
    public let ensureCloseButton: Bool
}

private struct CssOnlineUrl {
    public let mimeType: String
    public let url: String
}
