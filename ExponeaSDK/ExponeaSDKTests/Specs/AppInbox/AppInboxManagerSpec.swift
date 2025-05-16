//
//  AppInboxManagerImplSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 21/12/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class AppInboxManagerSpec: QuickSpec {

    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )

    public static let htmlAppInboxMessageContent: String = """
    <style>
                    .in-app-message-wrapper {
                        display: flex;
                        width: 100%;
                        height: 100%;
                        font-family: sans-serif;
                    }

                    .in-app-message {
                        display: block;
                        position: relative;
                        user-select: none;
                        max-height: 600px;
                        margin: auto 22px;
                        border: 0;
                        border-radius: 8px;
                        box-shadow: 0px 4px 8px rgba(102, 103, 128, 0.25);
                        overflow-y: auto;
                        width: 100%;
                    }

                    .in-app-message .image {
                        max-height: 160px;
                        overflow: hidden;
                        display: flex;
                        align-items: center;
                        pointer-events: none;
                    }

                    .in-app-message .image>img {
                        width: 100%;
                        height: auto;
                    }

                    .in-app-message .close-icon {
                        display: inline-block;
                        position: absolute;
                        width: 16px;
                        height: 16px;
                        top: 10px;
                        right: 10px;
                        background-color: rgba(250, 250, 250, 0.6);
                        border-radius: 50%;
                        cursor: pointer;
                    }

                    .in-app-message .close-icon::before,
                    .in-app-message .close-icon::after {
                        content: "";
                        height: 11px;
                        width: 2px;
                        position: absolute;
                        top: 2px;
                        left: 7px;
                    }

                    .in-app-message .close-icon::before {
                        transform: rotate(45deg);
                    }

                    .in-app-message .close-icon::after {
                        transform: rotate(-45deg);
                    }

                    .in-app-message .content {
                        display: flex;
                        font-size: 16px;
                        flex-direction: column;
                        align-items: center;
                        padding: 20px 13px;
                    }

                    .in-app-message .content .title {
                        box-sizing: border-box;
                        font-weight: bold;
                        text-align: center;
                        transition: font-size 300ms ease-in-out;
                    }

                    .in-app-message .content .body {
                        box-sizing: border-box;
                        text-align: center;
                        word-break: break-word;
                        transition: font-size 300ms ease-in-out;
                        margin-top: 8px;
                    }

                    .in-app-message .content .buttons {
                        display: flex;
                        width: 100%;
                        justify-content: center;
                        margin-top: 15px;
                    }

                    .in-app-message .content .buttons .button {
                        max-width: 100%;
                        min-width: 110px;
                        font-size: 14px;
                        text-align: center;
                        border-radius: 4px;
                        padding: 8px;
                        cursor: pointer;
                        white-space: nowrap;
                        overflow: hidden;
                        text-overflow: ellipsis;
                        transition: color, background-color 250ms ease-in-out;
                    }

                    .in-app-message .content .buttons .button:only-child {
                        margin: 0 auto;
                    }

                    .in-app-message.modal-in-app-message>.content>.buttons>.button:nth-child(2) {
                        margin-left: 8px;
                    }

                </style>


                <div class="in-app-message-wrapper">
                    <div class="in-app-message modal-in-app-message " style="background-color: #ffffff">

                        <div class="image">
                            <img src="https://i.ytimg.com/vi/t4nM1FoUqYs/maxresdefault.jpg" />
                        </div>


                        <style>
                            .in-app-message .close-icon::before,
                            .in-app-message .close-icon::after {
                                background-color: #000000;
                            }

                        </style>
                        <div class="close-icon" data-actiontype="close"></div>

                        <div class="content">
                            <span class="title" style="color:#000000;font-size:22px">
                                Book a tour for Antelope Canyon
                            </span>
                            <span class="body" style="color:#000000;font-size:14px">
                                This is an example of your in-app message body text.
                            </span>
                            <div class="buttons">
                                <span class="button" style="color:#ffffff;background-color:#f44cac" data-link="message:%3C3358921718340173851@unknownmsgid%3E">
                                    Deeplink
                                </span>
                                <span class="button" style="color:#ffffff;background-color:#f44cac" data-link="https://exponea.com/web">
                                    Web
                                </span>
                                <span class="button" style="color:#ffffff;background-color:#f44cac" data-link="https://exponea.com/deeplink" data-actiontype="deep-link">
                                    Https as Deeplink
                                </span>
                                <span class="button" style="color:#ffffff;background-color:#f44cac" data-link="message:%3C3358921718340173850@unknownmsgid%3E" data-actiontype="browser">
                                    Forced browser
                                </span>
                                <span class="button" style="color:#ffffff;background-color:#f44cac" data-link="https://exponea.com/fallback" data-actiontype="invalid_type">
                                    Fallback to browser
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
    """

    override func spec() {
        var appInboxManager: AppInboxManager!
        var repository: MockRepository!
        var trackingManager: MockTrackingManager!
        var database: MockDatabaseManager!

        beforeEach {
            IntegrationManager.shared.isStopped = false
            repository = MockRepository(configuration: self.configuration)
            trackingManager = MockTrackingManager(onEventCallback: { _, _ in
                // nothing yet
            })
            database = try! MockDatabaseManager()
            appInboxManager = AppInboxManager(
                repository: repository,
                trackingManager: trackingManager,
                database: database
            )
            AppInboxCache().clear()
        }

        it("should load only supported messages") {
            let now = Date().timeIntervalSince1970.doubleValue
            let response = AppInboxResponse(
                success: true,
                messages: [
                    AppInboxCacheSpec.getSampleMessage(id: "id1", received: now - 20, type: "push"),
                    AppInboxCacheSpec.getSampleMessage(id: "id2", received: now - 20, type: "html"),
                    AppInboxCacheSpec.getSampleMessage(id: "id3", received: now - 20, type: "whatSoEver")
                ],
                syncToken: nil
            )
            repository.fetchAppInboxResult = Result.success(response)
            waitUntil(timeout: .seconds(30)) { done in
                appInboxManager.fetchAppInbox { result in
                    expect(result.value?.count).to(equal(2))
                    done()
                }
            }
        }

        it("should parse PUSH message") {
            let now = Date().timeIntervalSince1970.doubleValue
            let response = AppInboxResponse(
                success: true,
                messages: [
                    AppInboxCacheSpec.getSampleMessage(
                        id: "id1",
                        read: true,
                        received: now - 20,
                        type: "push",
                        data: [
                            "title": .string("Title"),
                            "message": .string("Message"),
                            "actions": .array([
                                .dictionary([
                                    "action": .string("browser"),
                                    "url": .string("https://google.com"),
                                    "title": .string("Web")
                                ]),
                                .dictionary([
                                    "action": .string("deeplink"),
                                    "url": .string("mail:something"),
                                    "title": .string("Deeplink")
                                ])
                            ]),
                            "url_params": .dictionary([
                                "utm_source": .string("source"),
                                "utm_campaign": .string("campaign"),
                                "utm_content": .string("content"),
                                "utm_medium": .string("medium"),
                                "utm_term": .string("term"),
                                "xnpe_cmp": .string("cmp123")
                            ]),
                            "attributes": .dictionary([
                                "event_type": .string("campaign")
                            ])
                        ]
                    )
                ],
                syncToken: nil
            )
            repository.fetchAppInboxResult = Result.success(response)
            waitUntil(timeout: .seconds(30)) { done in
                appInboxManager.fetchAppInbox { result in
                    expect(result.value?.count).to(equal(1))
                    guard let message = result.value?.first else {
                        fail("No message loaded")
                        done()
                        return
                    }
                    guard let messageContent = message.content else {
                        fail("No message content loaded")
                        done()
                        return
                    }
                    expect(message.id).to(equal("id1"))
                    expect(message.type).to(equal("push"))
                    expect(messageContent.title).to(equal("Title"))
                    expect(messageContent.message).to(equal("Message"))
                    expect(messageContent.actions?.count).to(equal(2))
                    guard let webAction = messageContent.actions?.first(where: { item in item.type == .browser }) else {
                        fail("WebAction not found")
                        done()
                        return
                    }
                    expect(webAction.title).to(equal("Web"))
                    expect(webAction.url).to(equal("https://google.com"))
                    guard let deeplinkAction = messageContent.actions?.first(where: { item in item.type == .deeplink }) else {
                        fail("DeeplinkAction not found")
                        done()
                        return
                    }
                    expect(deeplinkAction.title).to(equal("Deeplink"))
                    expect(deeplinkAction.url).to(equal("mail:something"))
                    guard let trackingData = message.content?.trackingData else {
                        fail("Campaign data are empty")
                        done()
                        return
                    }
                    expect(trackingData["utm_source"]?.rawValue as? String).to(equal("source"))
                    expect(trackingData["utm_campaign"]?.rawValue as? String).to(equal("campaign"))
                    expect(trackingData["utm_content"]?.rawValue as? String).to(equal("content"))
                    expect(trackingData["utm_medium"]?.rawValue as? String).to(equal("medium"))
                    expect(trackingData["utm_term"]?.rawValue as? String).to(equal("term"))
                    expect(trackingData["xnpe_cmp"]?.rawValue as? String).to(equal("cmp123"))
                    expect(trackingData["event_type"]).to(beNil())
                    done()
                }
            }
        }

        it("should parse HTML message") {
            let now = Date().timeIntervalSince1970.doubleValue
            let response = AppInboxResponse(
                success: true,
                messages: [
                    AppInboxCacheSpec.getSampleMessage(
                        id: "id1",
                        read: true,
                        received: now - 20,
                        type: "html",
                        data: [
                            "title": .string("Title"),
                            "pre_header": .string("Message"),
                            "message": .string(AppInboxManagerSpec.htmlAppInboxMessageContent),
                            "url_params": .dictionary([
                                "utm_source": .string("source"),
                                "utm_campaign": .string("campaign"),
                                "utm_content": .string("content"),
                                "utm_medium": .string("medium"),
                                "utm_term": .string("term"),
                                "xnpe_cmp": .string("cmp123")
                            ]),
                            "attributes": .dictionary([
                                "event_type": .string("campaign")
                            ])
                        ]
                    )
                ],
                syncToken: nil
            )
            repository.fetchAppInboxResult = Result.success(response)
            waitUntil(timeout: .seconds(30)) { done in
                appInboxManager.fetchAppInbox { result in
                    expect(result.value?.count).to(equal(1))
                    guard let message = result.value?.first else {
                        fail("No message loaded")
                        done()
                        return
                    }
                    guard let messageContent = message.content else {
                        fail("No message content loaded")
                        done()
                        return
                    }
                    expect(message.id).to(equal("id1"))
                    expect(message.type).to(equal("html"))
                    expect(messageContent.title).to(equal("Title"))
                    expect(messageContent.message).to(equal("Message"))
                    expect(messageContent.html).toNot(beEmpty())
                    guard let actions = messageContent.actions else {
                        fail("WebActions not found")
                        done()
                        return
                    }
                    expect(actions.count).to(equal(5))
                    guard let action1 = actions.first(where: { $0.url == "message:%3C3358921718340173851@unknownmsgid%3E" }) else {
                        fail("WebAction not found")
                        done()
                        return
                    }
                    expect(action1.title).to(equal("Deeplink"))
                    expect(action1.type).to(equal(.deeplink))
                    guard let action2 = actions.first(where: { $0.url == "https://exponea.com/web" }) else {
                        fail("WebAction not found")
                        done()
                        return
                    }
                    expect(action2.title).to(equal("Web"))
                    expect(action2.type).to(equal(.browser))
                    guard let action3 = actions.first(where: { $0.url == "https://exponea.com/deeplink" }) else {
                        fail("WebAction not found")
                        done()
                        return
                    }
                    expect(action3.title).to(equal("Https as Deeplink"))
                    expect(action3.type).to(equal(.deeplink))
                    guard let action4 = actions.first(where: { $0.url == "message:%3C3358921718340173850@unknownmsgid%3E" }) else {
                        fail("WebAction not found")
                        done()
                        return
                    }
                    expect(action4.title).to(equal("Forced browser"))
                    expect(action4.type).to(equal(.browser))
                    guard let action5 = actions.first(where: { $0.url == "https://exponea.com/fallback" }) else {
                        fail("WebAction not found")
                        done()
                        return
                    }
                    expect(action5.title).to(equal("Fallback to browser"))
                    expect(action5.type).to(equal(.browser))
                    guard let trackingData = message.content?.trackingData else {
                        fail("Campaign data are empty")
                        done()
                        return
                    }
                    expect(trackingData["utm_source"]?.rawValue as? String).to(equal("source"))
                    expect(trackingData["utm_campaign"]?.rawValue as? String).to(equal("campaign"))
                    expect(trackingData["utm_content"]?.rawValue as? String).to(equal("content"))
                    expect(trackingData["utm_medium"]?.rawValue as? String).to(equal("medium"))
                    expect(trackingData["utm_term"]?.rawValue as? String).to(equal("term"))
                    expect(trackingData["xnpe_cmp"]?.rawValue as? String).to(equal("cmp123"))
                    expect(trackingData["event_type"]).to(beNil())
                    done()
                }
            }
        }

        it("should deny markAsRead action for non-assigned message") {
            var testMessage = AppInboxCacheSpec.getSampleMessage(id: "id1")
            // un-assign message from customer and AppInbox
            testMessage.syncToken = nil
            testMessage.customerIds = [:]
            waitUntil(timeout: .seconds(20)) { done in
                appInboxManager.markMessageAsRead(testMessage) { marked in
                    expect(marked).to(beFalse())
                    done()
                }
            }
        }

        it("should deny markAsRead action for message with non-existing customer") {
            var testMessage = AppInboxCacheSpec.getSampleMessage(id: "id1")
            // assign to AppInbox
            testMessage.syncToken = "some"
            // assign to non-existing customer (random)
            testMessage.customerIds = [:]
            waitUntil(timeout: .seconds(20)) { done in
                appInboxManager.markMessageAsRead(testMessage) { marked in
                    expect(marked).to(beFalse())
                    done()
                }
            }
        }

        it("should enhance AppInbox message while fetching") {
            let receivedSyncToken = "syncToken123"
            let now = Date().timeIntervalSince1970.doubleValue
            let response = AppInboxResponse(
                success: true,
                messages: [
                    AppInboxCacheSpec.getSampleMessage(
                        id: "id1",
                        read: true,
                        received: now - 20,
                        type: "html",
                        data: [
                            "title": .string("Title"),
                            "pre_header": .string("Message"),
                            "message": .string(AppInboxManagerSpec.htmlAppInboxMessageContent)
                        ]
                    )
                ],
                syncToken: receivedSyncToken
            )
            repository.fetchAppInboxResult = Result.success(response)
            waitUntil(timeout: .seconds(40)) { done in
                appInboxManager.fetchAppInbox { result in
                    expect(result.value?.count).to(equal(1))
                    guard let message = result.value?.first else {
                        fail("No message loaded")
                        done()
                        return
                    }
                    expect(message.syncToken).to(equal(receivedSyncToken))
                    done()
                }
            }
        }

        it("should allow markAsRead action for fetched message") {
            let receivedSyncToken = "syncToken123"
            let customerCookie = database.currentCustomer.uuid.uuidString
            trackingManager.customerCookie = customerCookie
            let now = Date().timeIntervalSince1970.doubleValue
            let response = AppInboxResponse(
                success: true,
                messages: [
                    AppInboxCacheSpec.getSampleMessage(
                        id: "id1",
                        read: true,
                        received: now - 20,
                        type: "html",
                        data: [
                            "title": .string("Title"),
                            "pre_header": .string("Message"),
                            "message": .string(AppInboxManagerSpec.htmlAppInboxMessageContent)
                        ],
                        customerIds: ["id": "1"]
                    )
                ],
                syncToken: receivedSyncToken
            )
            repository.fetchAppInboxResult = Result.success(response)
            var fetchedMessage: MessageItem?
            waitUntil(timeout: .seconds(20)) { done in
                appInboxManager.fetchAppInbox { result in
                    expect(result.value?.count).to(equal(1))
                    if let messages = result.value,
                       let message = messages.first {
                        fetchedMessage = message
                    }
                    done()
                }
            }
            fetchedMessage?.customerIds = ["id": "1"]
            fetchedMessage?.syncToken = "token"
            guard let fetchedMessage = fetchedMessage else {
                fail("No message loaded")
                return
            }
            waitUntil(timeout: .seconds(20)) { done in
                appInboxManager.markMessageAsRead(fetchedMessage) { isSuccess in
                    expect(isSuccess).to(beTrue())
                } _: { isMarked in
                    expect(isMarked).to(beTrue())
                    done()
                }
            }
        }
    }
}
