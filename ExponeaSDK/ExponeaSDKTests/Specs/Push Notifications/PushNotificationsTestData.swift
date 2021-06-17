//
//  PushNotificationsTestData.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 10/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

@testable import ExponeaSDK

struct PushNotificationsTestData {
    static let timestamp = 1618210073.185
    let deliveredBasicNotification = """
        {
          "aps" : {
            "alert" : "Test push notification title",
            "mutable-content" : 1
          },
          "source": "xnpe_platform",
          "message" : "test push notification message",
          "action" : "app",
          "legacy_ios_category" : null,
          "title" : "Test push notification title"
        }
    """

    let deliveredDeeplinkNotification = """
        {
          "title" : "Test push notification title",
          "message" : "test push notification message",
          "action" : "deeplink",
          "source": "xnpe_platform",
          "aps" : {
            "alert" : "Test push notification title",
            "mutable-content" : 1
          },
          "legacy_ios_category" : null,
          "url" : "some_url"
        }
    """

    let deliveredBrowserNotification = """
        {
          "message" : "test push notification message",
          "title" : "Test push notification title",
          "legacy_ios_category" : null,
          "source": "xnpe_platform",
          "aps" : {
            "alert" : "Test push notification title",
            "mutable-content" : 1
          },
          "url" : "http://google.com",
          "action" : "browser"
        }
    """

    let deliveredCustomActionsNotification = """
        {
          "legacy_ios_category" : null,
          "actions" : [
            {
              "title" : "Action 1 title",
              "action" : "app"
            },
            {
              "title" : "Action 2 title",
              "action" : "deeplink",
              "url" : "app://deeplink"
            },
            {
              "title" : "Action 3 title",
              "action" : "browser",
              "url" : "http://google.com"
            }
          ],
          "message" : "test push notification message",
          "aps" : {
            "alert" : "Test push notification title",
            "mutable-content" : 1
          },
          "source": "xnpe_platform",
          "action" : "app",
          "title" : "Test push notification title"
        }
    """

    let deliveredExtraDataNotification = """
        {
          "aps" : {
            "alert" : "Test push notification title",
            "mutable-content" : 1
          },
          "source": "xnpe_platform",
          "attributes" : {
            "campaign_id" : "some campaign id",
            "campaign_name" : "some campaign name",
            "action_id" : 123,
            "something_else" : "some other value",
            "something" : "some value"
          },
          "action" : "app",
          "title" : "Test push notification title",
          "legacy_ios_category" : null,
          "message" : "test push notification message"
        }
    """

    let deliveredCustomEventTypeNotification = """
        {
          "aps" : {
            "alert" : "Test push notification title",
            "mutable-content" : 1
          },
          "source": "xnpe_platform",
          "message" : "test push notification message",
          "action" : "app",
          "legacy_ios_category" : null,
          "title" : "Test push notification title",
          "attributes" : {
            "event_type": "custom push opened"
          }
        }
    """

    let deliveredProductionNotification = """
        {
          "url_params" : {
            "utm_campaign":"Testing mobile push",
            "utm_medium":"mobile_push_notification",
            "utm_source":"exponea"
          },
          "attributes" : {
            "subject" : "Notification title",
            "action_name" : "Unnamed mobile push",
            "event_type" : "campaign",
            "action_id" : 2,
            "platform" : "ios",
            "some property" : "some value",
            "language" : "",
            "recipient" : "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47",
            "campaign_policy" : "",
            "campaign_id" : "5db9ab54b073dfb424ccfa6f",
            "action_type" : "mobile notification",
            "campaign_name" : "Wassil's push"
          },
          "source": "xnpe_platform",
          "action" : "app",
          "legacy_ios_category" : null,
          "message" : "Notification text",
          "aps" : {
            "alert" : "Notification title",
            "mutable-content" : 1
          },
          "actions" : [
            {
              "title" : "Action 1 title",
              "action" : "app"
            },
            {
              "title" : "Action 2 title",
              "action" : "deeplink",
              "url" : "http://deeplink?search=something"
            },
            {
              "title" : "Action 3 title",
              "action" : "browser",
              "url" : "http://google.com?search=something"
            }
          ],
          "title" : "Notification title"
        }
    """

    let notificationWithSentTimestampAndType = """
        {
          "url_params" : {
            "utm_campaign":"Testing mobile push",
            "utm_medium":"mobile_push_notification",
            "utm_source":"exponea"
          },
          "attributes" : {
            "subject" : "Notification title",
            "action_name" : "Unnamed mobile push",
            "event_type" : "campaign",
            "action_id" : 2,
            "platform" : "ios",
            "some property" : "some value",
            "language" : "",
            "recipient" : "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47",
            "campaign_policy" : "",
            "campaign_id" : "5db9ab54b073dfb424ccfa6f",
            "action_type" : "mobile notification",
            "campaign_name" : "Wassil's push",
            "sent_timestamp" : 1618210073.185,
            "type" : "push"
          },
          "source": "xnpe_platform",
          "action" : "app",
          "legacy_ios_category" : null,
          "message" : "Notification text",
          "aps" : {
            "alert" : "Notification title",
            "mutable-content" : 1
          },
          "actions" : [
            {
              "title" : "Action 1 title",
              "action" : "app"
            },
            {
              "title" : "Action 2 title",
              "action" : "deeplink",
              "url" : "http://deeplink?search=something"
            },
            {
              "title" : "Action 3 title",
              "action" : "browser",
              "url" : "http://google.com?search=something"
            }
          ],
          "title" : "Notification title"
        }
    """

    let notificationWithNestedAttributes = """
         {
             "attributes": {
                 "first_level_attribute": "some value",
                 "array_attribute": ["a", "r", "r", "a", "y"],
                 "dictionary_attribute": {
                     "second_level_attribute": "second level value",
                     "number_attribute": 43436,
                     "nested_array": [1, 2, 3],
                     "nested_dictionary": {
                         "key1": "value1",
                         "key2": 3524.545
                     }
                 },
                 "product_list": [{
                     "item_id": "1234",
                     "item_quantity": 3
                 }, {
                     "item_id": "2345",
                     "item_quantity": 2
                 }, {
                     "item_id": "6789",
                     "item_quantity": 1
                 }],
                 "product_ids": ["1234", "2345", "6789"],
                 "push_content": {
                     "title": "Hey!",
                     "actions": [{
                         "title": "Action 1 title",
                         "action": "app"
                     }],
                     "message": "We have a great deal for you today, don't miss it!"
                 }
             },
             "source": "xnpe_platform",
             "action": "app",
             "legacy_ios_category": null,
             "message": "Notification text",
             "aps": {
                 "alert": "Notification title",
                 "mutable-content": 1
             },
             "title": "Notification title"
         }
    """

    let openedProductionNotificationData = PushOpenedData(
        silent: false,
        campaignData: CampaignData(
            source: "exponea",
            campaign: "Testing mobile push",
            medium: "mobile_push_notification"
        ),
        actionType: .openApp,
        actionValue: nil,
        eventType: .pushOpened,
        eventData: [
            .properties([
                "status": .string("clicked"),
                "cta": .string("notification"),
                "url": .string("app"),
                "subject": .string("Notification title"),
                "action_name": .string("Unnamed mobile push"),
                "action_id": .int(2),
                "platform": .string("ios"),
                "some property": .string("some value"),
                "recipient": .string("051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"),
                "campaign_id": .string("5db9ab54b073dfb424ccfa6f"),
                "action_type": .string("mobile notification"),
                "campaign_name": .string("Wassil's push"),
                "language": .string(""),
                "campaign_policy": .string(""),
                "utm_source": .string("exponea"),
                "utm_campaign": .string("Testing mobile push"),
                "utm_medium": .string("mobile_push_notification")
            ]),
            .timestamp(timestamp)
        ],
        extraData: [
            "subject": "Notification title",
            "action_name": "Unnamed mobile push",
            "event_type": "campaign",
            "action_id": 2,
            "platform": "ios",
            "some property": "some value",
            "language": "",
            "recipient": "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47",
            "campaign_policy": "",
            "campaign_id": "5db9ab54b073dfb424ccfa6f",
            "action_type": "mobile notification",
            "campaign_name": "Wassil's push"
        ]
    )

    let deliveredSilentNotification = """
        {
            "source": "xnpe_platform",
            "title": "Silent push",
            "action": "app",
            "silent": 1,
            "attributes": { "silent_test": "value" }
        }
    """

    let openedSilentNotificationData = PushOpenedData(
        silent: true,
        campaignData: CampaignData(),
        actionType: .openApp,
        actionValue: nil,
        eventType: .pushOpened,
        eventData: [.properties([
            "status": .string("delivered"),
            "platform": .string("ios"),
            "cta": .string("notification"),
            "url": .string("app"),
            "silent_test": .string("value")
        ]),
        .timestamp(timestamp)],
        extraData: ["silent_test": "value"]
    )
}
