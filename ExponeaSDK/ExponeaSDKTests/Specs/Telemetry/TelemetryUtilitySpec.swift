//
//  TelemetryUtilitySpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class TelemetryUtilitySpec: QuickSpec {
    override func spec() {
        beforeEach {
            IntegrationManager.shared.isStopped = false
        }
        describe("checking if exception stack trace is SDK related") {
            it("should return true for sdk related exception") {
                expect(
                    TelemetryUtility.isSDKRelated(
                        stackTrace: ["something", "something", "something Exponea something", "something"]
                    )
                ).to(beTrue())
                expect(
                    TelemetryUtility.isSDKRelated(
                        stackTrace: ["something", "something", "xxxexponeaxxx", "something"]
                    )
                ).to(beTrue())
            }
            it("should return true for sdk related exception") {
                expect(TelemetryUtility.isSDKRelated(stackTrace: ["something", "anything", "whatever"])).to(beFalse())
            }
        }
        describe("getting install id") {
            it("should generate install id") {
                let userDefaults = MockUserDefaults()
                expect(UUID(uuidString: TelemetryUtility.getInstallId(userDefaults: userDefaults))).notTo(beNil())
            }
            it("should store install id in user defaults") {
                let userDefaults = MockUserDefaults()
                let installId = TelemetryUtility.getInstallId(userDefaults: userDefaults)
                expect(TelemetryUtility.getInstallId(userDefaults: userDefaults)).to(equal(installId))
            }
        }
        describe("formatting configuration for tracking") {
            it("should format default configuration") {
                expect(
                    TelemetryUtility.formatConfigurationForTracking(
                        try! Configuration(
                            projectToken: "token",
                            authorization: .none,
                            baseUrl: Constants.Repository.baseUrl
                        )
                    )
                ).to(
                    equal([
                        "requirePushAuthorization": "true [default]",
                        "tokenTrackFrequency": "onTokenChange [default]",
                        "customAuthProvider": "none",
                        "authorization": "[]",
                        "allowDefaultCustomerProperties": "true [default]",
                        "baseUrl": "https://api.exponea.com [default]",
                        "defaultProperties": "",
                        "inAppContentBlocksPlaceholders": "[default]",
                        "advancedAuthEnabled": "false [default]",
                        "flushEventMaxRetries": "5 [default]",
                        "isDarkModeEnabled": "false [default]",
                        "appInboxDetailImageInset": "56.0 [default]",
                        "manualSessionAutoClose": "true [default]",
                        "automaticSessionTracking": "true [default]",
                        "projectMapping": "",
                        "sessionTimeout": "60.0 [default]",
                        "appGroup": "nil",
                        "automaticPushNotificationTracking": "true [default]"
                    ])
                )
            }
            it("should format non-default configuration") {
                let configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: [EventType.banner: [
                        ExponeaProject(projectToken: "other-mock-project-token", authorization: .none)
                    ]],
                    authorization: .token("mock-authorization"),
                    baseUrl: "http://mock-base-url.com",
                    appGroup: "mock-app-group",
                    defaultProperties: ["default-property": "default-property-value"],
                    sessionTimeout: 12345,
                    automaticSessionTracking: false,
                    automaticPushNotificationTracking: false,
                    tokenTrackFrequency: TokenTrackFrequency.daily,
                    flushEventMaxRetries: 123,
                    allowDefaultCustomerProperties: true,
                    advancedAuthEnabled: false
                )
                expect(TelemetryUtility.formatConfigurationForTracking(configuration)).to(
                    equal([
                        "advancedAuthEnabled": "false [default]",
                        "customAuthProvider": "none",
                        "isDarkModeEnabled": "false [default]",
                        "appGroup": "Optional(\"mock-app-group\")",
                        "automaticSessionTracking": "false",
                        "requirePushAuthorization": "true [default]",
                        "tokenTrackFrequency": "daily",
                        "flushEventMaxRetries": "123",
                        "automaticPushNotificationTracking": "false",
                        "baseUrl": "http://mock-base-url.com",
                        "inAppContentBlocksPlaceholders": "[default]",
                        "allowDefaultCustomerProperties": "true [default]",
                        "sessionTimeout": "12345.0",
                        "authorization": "[REDACTED]",
                        "manualSessionAutoClose": "true [default]",
                        "projectMapping": "[REDACTED]",
                        "appInboxDetailImageInset": "56.0 [default]",
                        "defaultProperties": "[REDACTED]"
                    ])
                )

            }
            it("should parse stacktrace") {
                var stackPart = TelemetryUtility.parseStackTrace(["0   MyAppName                    0x0000000100b3d184 MyClass.myMethod() + 44"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000100b3d184"))
                expect(stackPart.lineNumber).to(equal(44))
                expect(stackPart.symbolName).to(equal("MyClass.myMethod()"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["1   MyAppName                    0x0000000100b3d1ac SomeStruct.performStaticAction() + 28"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000100b3d1ac"))
                expect(stackPart.lineNumber).to(equal(28))
                expect(stackPart.symbolName).to(equal("SomeStruct.performStaticAction()"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["2   MyAppName                    0x0000000100b3d1f0 globalFunction() + 32"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000100b3d1f0"))
                expect(stackPart.lineNumber).to(equal(32))
                expect(stackPart.symbolName).to(equal("globalFunction()"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["3   UIKitCore                    0x00000001a2345e60 -[UIViewController viewDidLoad] + 100"])[0]
                expect(stackPart.symbolAddress).to(equal("0x00000001a2345e60"))
                expect(stackPart.lineNumber).to(equal(100))
                expect(stackPart.symbolName).to(equal("-[UIViewController viewDidLoad]"))
                expect(stackPart.module).to(equal("UIKitCore"))
                stackPart = TelemetryUtility.parseStackTrace(["4   SwiftUI                      0x00000001b234af28 closure #1 in ViewBody.update() + 20"])[0]
                expect(stackPart.symbolAddress).to(equal("0x00000001b234af28"))
                expect(stackPart.lineNumber).to(equal(20))
                expect(stackPart.symbolName).to(equal("closure #1 in ViewBody.update()"))
                expect(stackPart.module).to(equal("SwiftUI"))
                stackPart = TelemetryUtility.parseStackTrace(["5   libdispatch.dylib            0x00000001b69af7f4 _dispatch_call_block_and_release + 24"])[0]
                expect(stackPart.symbolAddress).to(equal("0x00000001b69af7f4"))
                expect(stackPart.lineNumber).to(equal(24))
                expect(stackPart.symbolName).to(equal("_dispatch_call_block_and_release"))
                expect(stackPart.module).to(equal("libdispatch.dylib"))
                stackPart = TelemetryUtility.parseStackTrace(["6   Foundation                   0x00000001a8eaeefc __NSThreadPerformPerform + 120"])[0]
                expect(stackPart.symbolAddress).to(equal("0x00000001a8eaeefc"))
                expect(stackPart.lineNumber).to(equal(120))
                expect(stackPart.symbolName).to(equal("__NSThreadPerformPerform"))
                expect(stackPart.module).to(equal("Foundation"))
                stackPart = TelemetryUtility.parseStackTrace(["7   ???                          0x0000000000000000 0x0 + 0"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000000000000"))
                expect(stackPart.lineNumber).to(equal(0))
                expect(stackPart.symbolName).to(equal("0x0"))
                expect(stackPart.module).to(equal("???"))
                stackPart = TelemetryUtility.parseStackTrace(["8   MyAppName                    0x0000000100b3f480 partial apply for closure #1 in MyViewModel.loadData() + 40"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000100b3f480"))
                expect(stackPart.lineNumber).to(equal(40))
                expect(stackPart.symbolName).to(equal("partial apply for closure #1 in MyViewModel.loadData()"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["9   MyAppName                    0x0000000100a3d140 @UIApplicationMain AppDelegate.application(_:didFinishLaunchingWithOptions:) + 96"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000100a3d140"))
                expect(stackPart.lineNumber).to(equal(96))
                expect(stackPart.symbolName).to(equal("@UIApplicationMain AppDelegate.application(_:didFinishLaunchingWithOptions:)"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["10   UIKitCore               0x00000001a2345e60 -[UIViewController viewDidLoad] + 100"])[0]
                expect(stackPart.symbolAddress).to(equal("0x00000001a2345e60"))
                expect(stackPart.lineNumber).to(equal(100))
                expect(stackPart.symbolName).to(equal("-[UIViewController viewDidLoad]"))
                expect(stackPart.module).to(equal("UIKitCore"))
                stackPart = TelemetryUtility.parseStackTrace(["11   MyAppName               0x0000000100c1aabc -[CustomManager fetchDataWithCompletion:] + 68"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000100c1aabc"))
                expect(stackPart.lineNumber).to(equal(68))
                expect(stackPart.symbolName).to(equal("-[CustomManager fetchDataWithCompletion:]"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["12   MyAppName               0x0000000100c1b2de -[NSString(MyCategory) cleanedString] + 32"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000100c1b2de"))
                expect(stackPart.lineNumber).to(equal(32))
                expect(stackPart.symbolName).to(equal("-[NSString(MyCategory) cleanedString]"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["13   MyAppName               0x0000000100c1b410 __42-[NetworkService performRequestWithBlock:]_block_invoke + 48"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000100c1b410"))
                expect(stackPart.lineNumber).to(equal(48))
                expect(stackPart.symbolName).to(equal("__42-[NetworkService performRequestWithBlock:]_block_invoke"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["14   Foundation              0x00000001a80fc3b4 __CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ + 28"])[0]
                expect(stackPart.symbolAddress).to(equal("0x00000001a80fc3b4"))
                expect(stackPart.lineNumber).to(equal(28))
                expect(stackPart.symbolName).to(equal("__CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__"))
                expect(stackPart.module).to(equal("Foundation"))
                stackPart = TelemetryUtility.parseStackTrace(["15   MyAppName   0x0000000101234567   MyApp.SomeStruct.myFunction(param: Swift.String) -> Swift.Bool"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000101234567"))
                expect(stackPart.lineNumber).to(equal(0))
                expect(stackPart.symbolName).to(equal("MyApp.SomeStruct.myFunction(param: Swift.String) -> Swift.Bool"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["16   MyAppName   0x0000000101234600   MyApp.ViewController.viewDidLoad() -> ()"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000101234600"))
                expect(stackPart.lineNumber).to(equal(0))
                expect(stackPart.symbolName).to(equal("MyApp.ViewController.viewDidLoad() -> ()"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["17   MyAppName   0x0000000101234700   MyApp.NetworkClient<Swift.String>.fetch(url: Swift.String) -> ()"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000101234700"))
                expect(stackPart.lineNumber).to(equal(0))
                expect(stackPart.symbolName).to(equal("MyApp.NetworkClient<Swift.String>.fetch(url: Swift.String) -> ()"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["18   MyAppName   0x0000000101234800   MyApp.APIError.networkError(Swift.Error) -> ()"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000101234800"))
                expect(stackPart.lineNumber).to(equal(0))
                expect(stackPart.symbolName).to(equal("MyApp.APIError.networkError(Swift.Error) -> ()"))
                expect(stackPart.module).to(equal("MyAppName"))
                stackPart = TelemetryUtility.parseStackTrace(["19   MyAppName   0x0000000101234900   MyApp.DataLoader.loadData() async throws -> Swift.Data"])[0]
                expect(stackPart.symbolAddress).to(equal("0x0000000101234900"))
                expect(stackPart.lineNumber).to(equal(0))
                expect(stackPart.symbolName).to(equal("MyApp.DataLoader.loadData() async throws -> Swift.Data"))
                expect(stackPart.module).to(equal("MyAppName"))
            }
            it("should not parse invalid stacktrace, run without crash") {
                expect(
                    TelemetryUtility.parseStackTrace([""])
                ).to(beEmpty())
                expect(
                    TelemetryUtility.parseStackTrace(["19 MyAppName 0x0000000101234900"])
                ).to(beEmpty())
            }
        }
    }
}
