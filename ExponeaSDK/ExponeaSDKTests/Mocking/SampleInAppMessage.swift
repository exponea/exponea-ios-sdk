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
        "payload": {
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
        "close_timeout": 2000
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
        timeoutMS: Int? = nil
    ) -> InAppMessage {
        return InAppMessage(
            id: id ?? "5dd86f44511946ea55132f29",
            name: "Test serving in-app message",
            rawMessageType: "modal",
            rawFrequency: frequency?.rawValue ?? "unknown",
            payload: InAppMessagePayload(
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
            timeoutMS: timeoutMS
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
            payload: payload,
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
            timeoutMS: nil
        )
    }
}
