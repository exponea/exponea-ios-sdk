//
//  MessageItemSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 10/01/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class MessageItemSpec: QuickSpec {

    func messageRaw() -> String {
        """
        {
           "id":"070384247690685160",
           "type":"push",
           "create_time":1673346347.242,
           "expire_time":1704882347.22,
           "is_read":false,
           "content":{
              "message":"html here",
              "title":"Title",
              "pre_header":"Subject",
              "url_params":[
                 {
                    "utm_source":"bloomreach",
                    "utm_medium":"app_inbox",
                    "utm_campaign":"Adam M3 AppInbox"
                 }
              ],
              "image":"https://www.wildlifetrusts.org/sites/default/files/styles/scaled_default/public/2018-01/Gull%20Herring%20June%202015%20Gillian%20Day.jpg?itok=fWgRlQdW",
              "has_tracking_consent":true,
              "consent_category_tracking":null,
              "attributes":{
                 "campaign_id":"63bd35be94f72bc9ef8bd151",
                 "campaign_name":"Unnamed scenario",
                 "action_id":3,
                 "action_type":"app inbox",
                 "action_name":"Adam M3 AppInbox",
                 "campaign_policy":"Default",
                 "event_type":"campaign"
              },
              "source":"xnpe_platform",
              "silent":false
           }
        }
        """
    }

    override func spec() {
        it("should deserialize HTML from Empty JSON") {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970
            let sampleMessageRaw = "{}".data(using: .utf8)
            guard let sampleMessageRaw = sampleMessageRaw else {
                fail("Message as String is NIL")
                return
            }
            let sampleMessage = try jsonDecoder.decode(MessageItem.self, from: sampleMessageRaw)
            expect(sampleMessage).notTo(beNil())
        }
        it("should deserialize HTML from JSON") {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970
            let sampleMessageRaw = self.messageRaw().data(using: .utf8)
            guard let sampleMessageRaw = sampleMessageRaw else {
                fail("Message as String is NIL")
                return
            }
            let sampleMessage = try jsonDecoder.decode(MessageItem.self, from: sampleMessageRaw)
            expect(sampleMessage).notTo(beNil())
            expect(sampleMessage.rawContent).notTo(beNil())
            expect(sampleMessage.content).notTo(beNil())
        }
    }
}
