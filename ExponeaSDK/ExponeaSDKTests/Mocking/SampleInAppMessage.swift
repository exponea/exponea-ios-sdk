//
//  ExampleInAppMessage.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

struct SampleInAppMessage {
    static let samplePayload = """
    {
        "id": "5dd86f44511946ea55132f29",
        "name": "Test serving in-app message",
        "message_type": "modal",
        "frequency": "unknown",
        "is_rich_text": false,
        "oldPayload": {
            "image_url":"https://i.ytimg.com/vi/t4nM1FoUqYs/maxresdefault.jpg",
            "title":"filip.vozar@exponea.com",
            "title_text_color":"#000000",
            "title_text_size":"22px",
            "body_text":"This is an example of your in-app message body text.",
            "body_text_color":"#000000",
            "body_text_size":"14px",
            "buttons": [
                {
                    "button_text":"Action",
                    "button_type":"deep-link",
                    "button_link":"https://someaddress.com",
                    "button_text_color":"#ffffff",
                    "button_background_color":"#f44cac"
                }
            ],
            "background_color":"#ffffff",
            "close_button_color":"#ffffff"
        },
        "variant_id": 0,
        "variant_name": "Variant A",
        "trigger": {
            "event_type": "session_start",
            "filter": []
        },
        "date_filter": {
            "enabled": false,
            "from_date": 1570744800,
            "to_date": null
        },
        "load_delay": 1000,
        "close_timeout": 2000,
        "payload_html": "<html></html>",
        "is_html": false
    }
    """

    static let samplePayloadRich = """
    {
        "id": "5dd86f44511946ea55132f29",
        "name": "Test serving in-app message",
        "message_type": "modal",
        "frequency": "unknown",
        "payload": {
            "title": "Richtext Book a tour for Antelope Canyon",
            "body_text": "This is an example of your in-app personalization body text.",
            "image_url": "https://asset-templates.exponea.dev/misc/media/canyon/canyon.jpg",
            "title_text_color": "#ff0000",
            "title_text_size": "22px",
            "body_text_color": "#000000",
            "body_text_size": "14px",
            "background_color": "rgba(48,188,36,0.46)",
            "close_button_color": "rgba(250, 250, 250, 0.6)",
            "container_margin": "16px",
            "container_padding": "0px",
            "container_corner_radius": "24px",
            "overlay_color": "rgba(131,74,74,0.6)",
            "text_position": "left",
            "message_position": "bottom",
            "image_enabled": true,
            "image_size": "auto",
            "image_margin": "0px",
            "image_corner_radius": "0px",
            "image_aspect_ratio_width": "4",
            "image_aspect_ratio_height": "3",
            "image_object_fit": "cover",
            "title_enabled": true,
            "title_format": ["bold", "italic"],
            "title_align": "right",
            "title_line_height": "24px",
            "title_padding": "12px 0px 0px 0px",
            "title_font_family": null,
            "body_enabled": true,
            "body_format": ["bold"],
            "body_align": "left",
            "body_line_height": "16px",
            "body_padding": "12px 0px",
            "body_font_family": null,
            "close_button_enabled": false,
            "close_button_margin": "8px 8px 0px 0px",
            "buttons": [{
                "button_text": "Action",
                "button_type": "deep-link",
                "button_link": "https://bloomreach.com",
                "button_text_color": "#ffffff",
                "button_background_color": "#019ACE",
                "button_width": "fill",
                "button_corner_radius": "10px",
                "button_margin": "10px 20px 18px",
                "button_has_border": true,
                "button_font_size": "14px",
                "button_line_height": "14px",
                "button_padding": "12px 24px",
                "button_align": "left",
                "button_border_color": "#d8ff00",
                "button_border_width": "5px",
                "button_font_family": null,
                "button_enabled": true,
                "button_format": ["italic", "bold"],
                "button_font_url": ""
            }, {
                "button_text": "Action",
                "button_type": "deep-link",
                "button_link": "https://bloomreach.com",
                "button_text_color": "#ffffff",
                "button_background_color": "#019ACE",
                "button_width": "hug_text",
                "button_corner_radius": "4px",
                "button_margin": "10px 0px 18px",
                "button_has_border": false,
                "button_font_size": "14px",
                "button_line_height": "14px",
                "button_padding": "12px 24px",
                "button_align": "center",
                "button_border_color": "#006081",
                "button_border_width": "2px",
                "button_font_family": null,
                "button_enabled": false,
            }, {
                "button_text": "Action",
                "button_type": "deep-link",
                "button_link": "https://bloomreach.com",
                "button_text_color": "#ffffff",
                "button_background_color": "#019ACE",
                "button_width": "hug_text",
                "button_corner_radius": "4px",
                "button_margin": "10px 0px 18px",
                "button_has_border": false,
                "button_font_size": "14px",
                "button_line_height": "14px",
                "button_padding": "12px 24px",
                "button_align": "center",
                "button_border_color": "#006081",
                "button_border_width": "2px",
                "button_font_family": null,
                "button_enabled": false,
            }],
        },
        "is_rich_text": true,
        "variant_id": 0,
        "variant_name": "Variant A",
        "trigger": {
            "event_type": "session_start",
            "filter": []
        },
        "date_filter": {
            "enabled": false,
            "from_date": 1570744800,
            "to_date": null
        },
        "load_delay": 1000,
        "close_timeout": 2000,
        "payload_html": "<html></html>",
        "is_html": false
    }
    """

    static func getSampleInAppMessage(
        id: String? = nil,
        dateFilter: DateFilter? = nil,
        trigger: EventFilter? = nil,
        frequency: InAppMessageFrequency? = nil,
        imageUrl: String? = nil,
        priority: Int? = nil,
        delayMS: Int? = nil,
        timeoutMS: Int? = nil,
        hasTrackingConsent: Bool? = nil,
        consentCategoryTracking: String? = nil,
        messageType: String? = "modal",
        isHtml: Bool? = false
    ) -> InAppMessage {
        return InAppMessage(
            id: id ?? "5dd86f44511946ea55132f29",
            name: "Test serving in-app message",
            rawMessageType: messageType,
            rawFrequency: frequency?.rawValue ?? "unknown",
            payload: nil,
            oldPayload: InAppMessagePayload(
                imageUrl: imageUrl ?? "https://i.ytimg.com/vi/t4nM1FoUqYs/maxresdefault.jpg",
                title: "filip.vozar@exponea.com",
                titleTextColor: "#000000",
                titleTextSize: "22px",
                bodyText: "This is an example of your in-app message body text.",
                bodyTextColor: "#000000",
                bodyTextSize: "14px",
                buttons: [
                    InAppMessagePayloadButton(
                        buttonText: "Action",
                        rawButtonType: "deep-link",
                        buttonLink: "https://someaddress.com",
                        buttonTextColor: "#ffffff",
                        buttonBackgroundColor: "#f44cac"
                    )
                ],
                backgroundColor: "#ffffff",
                closeButtonColor: "#ffffff",
                messagePosition: nil,
                textPosition: nil,
                textOverImage: nil
            ),
            variantId: 0,
            variantName: "Variant A",
            trigger: trigger ?? EventFilter(eventType: "session_start", filter: []),
            dateFilter: dateFilter ?? DateFilter(
                enabled: false,
                startDate: Date(timeIntervalSince1970: 1570744800),
                endDate: nil
            ),
            priority: priority,
            delayMS: delayMS,
            timeoutMS: timeoutMS,
            payloadHtml: "<html></html>",
            isHtml: isHtml,
            hasTrackingConsent: hasTrackingConsent,
            consentCategoryTracking: consentCategoryTracking,
            isRichText: false
        )
    }

    static func getSampleInAppMessage(
        payload: InAppMessagePayload?,
        variantName: String,
        variantId: Int
    ) -> InAppMessage {
        return InAppMessage(
            id: "5dd86f44511946ea55132f29",
            name: "Test serving in-app message",
            rawMessageType: "modal",
            rawFrequency: "unknown",
            payload: nil,
            oldPayload: payload,
            variantId: variantId,
            variantName: variantName,
            trigger: EventFilter(eventType: "session_start", filter: []),
            dateFilter: DateFilter(
                enabled: false,
                startDate: Date(timeIntervalSince1970: 1570744800),
                endDate: nil
            ),
            priority: nil,
            delayMS: nil,
            timeoutMS: nil,
            payloadHtml: "<html></html>",
            isHtml: false,
            hasTrackingConsent: nil,
            consentCategoryTracking: nil,
            isRichText: false
        )
    }
}
