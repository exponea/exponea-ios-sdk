//
//  SampleInAppContentBlocks.swift
//  ExponeaSDKTests
//
//  Created by Ankmara on 25.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

@testable import ExponeaSDK

struct SampleInAppContentBlocks {

    static let samplePayload = """
    {
        "id": "646233fdefb33d966a49b8c1",
        "name": "Test serving message",
        "date_filter": {
            "enabled": false
        },
        "frequency": "until_visitor_interacts",
        "placeholders": [
            "placeholder"
        ],
        "personalizedMessage": {
            "id": "649053bd2a632dc7d38c4ac2",
            "status": "OK",
            "ttl_seconds": 60,
            "has_tracking_consent": false,
            "variant_id": 0,
            "variant_name": "Variant A",
            "content_type": "html",
            "content": {
                "html": "<!DOCTYPE html>\n<html>\n\n<head>\n\t<title></title>\n\t<meta charset=\"UTF-8\">\n\t<meta name=\"viewport\" content=\"width=device-width\">\n\t<style>\n\t\t.bee-row,\n\t\t.bee-row-content {\n\t\t\tposition: relative\n\t\t}\n\n\t\t.bee-row-1,\n\t\t.bee-row-1 .bee-row-content {\n\t\t\tbackground-repeat: no-repeat\n\t\t}\n\n\t\tbody {\n\t\t\tbackground-color: #fff;\n\t\t\tcolor: #000;\n\t\t\tfont-family: Arial, Helvetica Neue, Helvetica, sans-serif\n\t\t}\n\n\t\ta {\n\t\t\tcolor: #00f\n\t\t}\n\n\t\t* {\n\t\t\tbox-sizing: border-box\n\t\t}\n\n\t\tbody,\n\t\th1 {\n\t\t\tmargin: 0\n\t\t}\n\n\t\t.bee-row-content {\n\t\t\tmax-width: 600px;\n\t\t\tmargin: 0 auto;\n\t\t\tdisplay: flex\n\t\t}\n\n\t\t.bee-row-content .bee-col-w12 {\n\t\t\tflex-basis: 100%\n\t\t}\n\n\t\t.bee-button .content,\n\t\t.bee-html-block {\n\t\t\ttext-align: center\n\t\t}\n\n\t\t.bee-button a {\n\t\t\ttext-decoration: none\n\t\t}\n\n\t\t.bee-row-1 {\n\t\t\tbackground-size: auto\n\t\t}\n\n\t\t.bee-row-1 .bee-row-content {\n\t\t\tbackground-image: url('https://asset-templates.exponea.dev/in-app-messages/assets/promotion/bg.1f45ff010a53b05a8160.jpg');\n\t\t\tbackground-size: cover;\n\t\t\tborder-radius: 6px;\n\t\t\tcolor: #000\n\t\t}\n\n\t\t.bee-row-1 .bee-col-1 {\n\t\t\tpadding-bottom: 5px;\n\t\t\tpadding-top: 5px\n\t\t}\n\n\t\t.bee-row-1 .bee-col-1 .bee-block-3 {\n\t\t\ttext-align: center;\n\t\t\twidth: 100%\n\t\t}\n\n\t\t.bee-row-1 .bee-col-1 .bee-block-4 {\n\t\t\tpadding: 10px;\n\t\t\ttext-align: center\n\t\t}\n\n\t\t@media (max-width:620px) {\n\t\t\t.bee-row-content:not(.no_stack) {\n\t\t\t\tdisplay: block\n\t\t\t}\n\n\t\t\t.bee-row-1 .bee-col-1 {\n\t\t\t\tpadding: 18px !important\n\t\t\t}\n\n\t\t\t.bee-row-1 .bee-col-1 .bee-block-2 {\n\t\t\t\theight: 220px !important\n\t\t\t}\n\n\t\t\t.bee-row-1 .bee-col-1 .bee-block-4 {\n\t\t\t\tpadding: 8px 0 0 !important\n\t\t\t}\n\n\t\t\t.bee-row-1 .bee-col-1 .bee-block-4 .bee-button-content {\n\t\t\t\tfont-size: initial !important;\n\t\t\t\tline-height: normal !important;\n\t\t\t\twidth: 100% !important;\n\t\t\t\ttext-align: center !important\n\t\t\t}\n\n\t\t\t.bee-row-1 .bee-col-1 .bee-block-4 a,\n\t\t\t.bee-row-1 .bee-col-1 .bee-block-4 span {\n\t\t\t\ttext-align: center !important;\n\t\t\t\tfont-size: 14px !important;\n\t\t\t\tline-height: auto !important\n\t\t\t}\n\n\t\t\t.bee-row-1 .bee-col-1 .bee-block-3 h1 {\n\t\t\t\tfont-size: 22px !important\n\t\t\t}\n\t\t}\n\t</style>\n</head>\n\n<body>\n\t<div class=\"bee-page-container\">\n\t\t<div class=\"bee-row bee-row-1\">\n\t\t\t<div class=\"bee-row-content\">\n\t\t\t\t<div class=\"bee-col bee-col-1 bee-col-w12\">\n\t\t\t\t\t<div class=\"bee-block bee-block-1 bee-html-block\">\n\t\t\t\t\t\t<style>\n\t\t\t\t\t\t\t.in-app-message-close-button-wrapper {\n\t\t\t\t\t\t\t\tposition: relative;\n\t\t\t\t\t\t\t}\n\n\t\t\t\t\t\t\t.in-app-message-close-button {\n\t\t\t\t\t\t\t\twidth: 16px;\n\t\t\t\t\t\t\t\theight: 16px;\n\t\t\t\t\t\t\t\tbackground-color: rgba(250, 250, 250, 0.6);\n\t\t\t\t\t\t\t\tborder-radius: 50%;\n\t\t\t\t\t\t\t\tcursor: pointer;\n\t\t\t\t\t\t\t\tposition: absolute;\n\t\t\t\t\t\t\t\ttop: -8px;\n\t\t\t\t\t\t\t\tright: -8px;\n\t\t\t\t\t\t\t}\n\n\t\t\t\t\t\t\t.in-app-message-close-button::before,\n\t\t\t\t\t\t\t.in-app-message-close-button::after {\n\t\t\t\t\t\t\t\tposition: absolute;\n\t\t\t\t\t\t\t\tbackground-color: #000;\n\t\t\t\t\t\t\t\tcontent: \"\";\n\t\t\t\t\t\t\t\theight: 11px;\n\t\t\t\t\t\t\t\twidth: 2px;\n\t\t\t\t\t\t\t\ttop: 2px;\n\t\t\t\t\t\t\t\tleft: 7px;\n\t\t\t\t\t\t\t}\n\n\t\t\t\t\t\t\t.in-app-message-close-button::before {\n\t\t\t\t\t\t\t\ttransform: rotate(45deg);\n\t\t\t\t\t\t\t}\n\n\t\t\t\t\t\t\t.in-app-message-close-button::after {\n\t\t\t\t\t\t\t\ttransform: rotate(-45deg);\n\t\t\t\t\t\t\t}\n\t\t\t\t\t\t</style>\n\n\t\t\t\t\t\t<div class=\"in-app-message-close-button-wrapper\">\n\t\t\t\t\t\t\t<div class=\"in-app-message-close-button\" data-actiontype=\"close\"></div>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class=\"bee-block bee-block-2 bee-spacer\">\n\t\t\t\t\t\t<div class=\"spacer\" style=\"height:60px;\"></div>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class=\"bee-block bee-block-3 bee-heading\">\n\t\t\t\t\t\t<h1 style=\"color:#ffffff;direction:ltr;font-family:Arial, Helvetica Neue, Helvetica, sans-serif;font-size:23px;font-weight:700;letter-spacing:normal;line-height:120%;text-align:center;margin-top:0;margin-bottom:0;\"><span class=\"tinyMce-placeholder\">New arrivals. 222 444!</span> </h1>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class=\"bee-block bee-block-4 bee-button\"><a style=\"font-size: 14px; background-color: #ffa200; border-bottom: 0px solid transparent; border-left: 0px solid transparent; border-radius: 33px; border-right: 0px solid transparent; border-top: 0px solid transparent; color: #002840; direction: ltr; font-family: inherit; font-weight: 700; max-width: 100%; padding-bottom: 4px; padding-left: 0px; padding-right: 0px; padding-top: 4px; width: 50%; display: inAppContentBlocks-block;\" class=\"bee-button-content\" href=\"https://www.seznam.cz\" target=\"_blank\" data-link=\"https://www.seznam.cz\"><span style=\"word-break: break-word; font-size: 14px; line-height: 200%;\">Let’s explore</span></a></div>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t</div>\n</body>\n\n</html>"
            }
        }
    }
    """

    static func getSampleIninAppContentBlocks(
        id: String = "646233fdefb33d966a49b8c1",
        name: String = "Test serving message",
        dateFilter: InAppContentBlockResponse.DateFilter = .init(enabled: true, fromDate: nil, toDate: nil),
        frequency: InAppContentBlocksFrequency = .always,
        placeholders: [String] = ["placeholder"],
        tags: Set<Int> = [Int.random(in: 0..<100)],
        loadPriority: Int = 1,
        content: Content? = nil,
        personalized: PersonalizedInAppContentBlockResponse? = nil
    ) -> InAppContentBlockResponse {
        .init(
            id: id,
            name: name,
            dateFilter: dateFilter,
            frequency: frequency,
            placeholders: placeholders,
            tags: tags,
            loadPriority: loadPriority,
            content: content,
            personalized: personalized
        )
    }
}

extension PersonalizedInAppContentBlockResponse {
    static func getSample(status: InAppContentBlocksStatus, ttlSeen: Date) -> Self {
        .init(
            id: "649053bd2a632dc7d38c4ac2",
            status: status,
            ttlSeconds: 5,
            variantId: 12,
            hasTrackingConsent: true,
            variantName: "variant",
            contentType: .html,
            content: .init(html: "html"),
            htmlPayload: nil,
            ttlSeen: ttlSeen
        )
    }
}
