//
//  PushNotificationSwizzlerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 07/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class PushNotificationSwizzlerSpec: QuickSpec {
    class EmptyAppDelegate: UIResponder, UIApplicationDelegate {}

    class AppDelegateWithPushTokenRegistration: UIResponder, UIApplicationDelegate {
        var registerCalls: [Data] = []
        func application(
            _ application: UIApplication,
            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
        ) {
            registerCalls.append(deviceToken)
        }
    }

    class AppDelegateWithReceive: UIResponder, UIApplicationDelegate {
        var receiveCalls: [[AnyHashable: Any]] = []
        func application(
            _ application: UIApplication,
            didReceiveRemoteNotification userInfo: [AnyHashable: Any],
            fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void
        ) {
            receiveCalls.append(userInfo)
        }
    }

    class EmptyCenterDelegate: NSObject, UNUserNotificationCenterDelegate {}

    class CenterDelegate: NSObject, UNUserNotificationCenterDelegate {
        var receiveCalls: [UNNotificationResponse] = []
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            receiveCalls.append(response)
        }
    }

    class OtherCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
        var receiveCalls: [UNNotificationResponse] = []
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            receiveCalls.append(response)
        }
    }

    class WrappingCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
        let original: UNUserNotificationCenterDelegate
        var receiveCalls: [UNNotificationResponse] = []
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            original.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
            receiveCalls.append(response)
        }

        init(original: UNUserNotificationCenterDelegate) {
            self.original = original
        }
    }
    
    fileprivate class TestNotificationCoder: NSCoder {

        private enum FieldKey: String {
            case date, request, sourceIdentifier, intentIdentifiers, notification, actionIdentifier, originIdentifier, targetConnectionEndpoint, targetSceneIdentifier
        }
        private let testIdentifier = "testIdentifier"
        private let request: UNNotificationRequest
        override var allowsKeyedCoding: Bool { true }

        init(with request: UNNotificationRequest) {
            self.request = request
        }

        override func decodeObject(forKey key: String) -> Any? {
            let fieldKey = FieldKey(rawValue: key)
            switch fieldKey {
            case .date:
                return Date()
            case .request:
                return request
            case .sourceIdentifier, .actionIdentifier, .originIdentifier:
                return testIdentifier
            case .notification:
                return UNNotification(coder: self)
            default:
                return nil
            }
        }
    }
    
    private func mock_notification_response() -> UNNotificationResponse {
        let content = UNMutableNotificationContent()
        content.userInfo = [:]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        let response = UNNotificationResponse(coder: TestNotificationCoder(with: request))!

        return response
    }

    // This simulates system calling notification opened
    // When app is opened use notification center delegate, otherwise app delegate
    func openNotification(
        appOpened: Bool,
        uiApplication: UIApplicationDelegating,
        notificationCenter: BasicUNUserNotificationCenterDelegating
    ) {
        if !appOpened {
            let notificationDelegateSelector = PushSelectorMapping.Original.centerDelegateReceive
            if let notificationDelegate = notificationCenter.delegate,
               class_getInstanceMethod(type(of: notificationDelegate), notificationDelegateSelector) != nil {
                notificationCenter.delegate?.userNotificationCenter?(
                    UNUserNotificationCenter.current(),
                    didReceive: mock_notification_response(),
                    withCompletionHandler: {}
                )
                return
            }
        } else {
            guard let appDelegate = uiApplication.delegate else {
                return
            }
            let appPrefferedSelector =
                #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
            if class_getInstanceMethod(type(of: appDelegate), appPrefferedSelector) != nil {
                appDelegate.application?(
                    UIApplication.shared,
                    didReceiveRemoteNotification: [:],
                    fetchCompletionHandler: { _ in }
                )
            }
        }
    }

    override func spec() {
        var mockApplication: UIApplicationDelegating!
        var mockCenter: BasicUNUserNotificationCenterDelegating!
        var manager: MockPushNotificationManager!
        var swizzler: PushNotificationSwizzler!

        func setup(appDelegate: UIApplicationDelegate, centerDelegate: UNUserNotificationCenterDelegate? = nil) {
            manager = MockPushNotificationManager()
            mockApplication = BasicUIApplicationDelegating()
            mockCenter = BasicUNUserNotificationCenterDelegating()
            mockApplication.delegate = appDelegate
            mockCenter.delegate = centerDelegate
            swizzler = PushNotificationSwizzler(
                manager,
                uiApplicationDelegating: mockApplication,
                unUserNotificationCenterDelegating: mockCenter
            )
            swizzler.addAutomaticPushTracking()
        }

        func openNotification(appOpened: Bool) {
            self.openNotification(appOpened: appOpened, uiApplication: mockApplication, notificationCenter: mockCenter)
        }

        describe("token registration swizzling") {
            let selector = #selector(
                UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
            )

            context("without existing method") {
                it("should call handle push registered") {
                    let appDelegate = EmptyAppDelegate()
                    setup(appDelegate: appDelegate)
                    appDelegate.perform(selector, with: "mock token".data(using: .utf8)!)
                    expect(manager.handlePushTokenRegisteredCalls.count).to(equal(1))
                }
            }

            context("with existing method") {
                it("should call handle push registered and original handler") {
                    let appDelegate = AppDelegateWithPushTokenRegistration()
                    setup(appDelegate: appDelegate)
                    appDelegate.perform(selector, with: "mock token".data(using: .utf8)!)
                    expect(manager.handlePushTokenRegisteredCalls.count).to(equal(1))
                    expect(appDelegate.registerCalls.count).to(equal(1))
                }
            }
        }

        describe("push received swizzling") {
            context("no push receive in host app") {
                it("should call handle push when app is opened") {
                    setup(appDelegate: EmptyAppDelegate())
                    openNotification(appOpened: true)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                }
                it("should call handle push when app is closed") {
                    setup(appDelegate: EmptyAppDelegate())
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                }
            }

            context("UI application delegate preffered handler defined") {
                it("should call handle push, call original method") {
                    let appDelegate = AppDelegateWithReceive()
                    setup(appDelegate: appDelegate)
                    openNotification(appOpened: true)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(appDelegate.receiveCalls.count).to(equal(1))
                }
            }

            context("Notification center empty delegate") {
                it("should call handle push when added before") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: EmptyCenterDelegate())
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                }
                it("should call handle push when added after") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: nil)
                    mockCenter.delegate = EmptyCenterDelegate()
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                }
                it("should call handle push when changed to nil") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: nil)
                    mockCenter.delegate = EmptyCenterDelegate()
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    mockCenter.delegate = nil
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(2))
                }
            }

            context("Notification center delegate with handler") {
                it("should call handle push, call original method when added before") {
                    let centerDelegate = CenterDelegate()
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: centerDelegate)
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                }
                it("should call handle push, call original method when added after") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: nil)
                    let centerDelegate = CenterDelegate()
                    mockCenter.delegate = centerDelegate
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                }
                it("should call handle push, call original method when changed to nil") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: nil)
                    let centerDelegate = CenterDelegate()
                    mockCenter.delegate = centerDelegate
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                    mockCenter.delegate = nil
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(2))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                    mockCenter.delegate = nil
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(3))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                }
            }

            context("changing center delegate") {
                it("should call handle push") {
                    let delegate = CenterDelegate()
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: delegate)
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(delegate.receiveCalls.count).to(equal(1))
                    let otherDelegate = OtherCenterDelegate()
                    mockCenter.delegate = otherDelegate
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(2))
                    expect(delegate.receiveCalls.count).to(equal(1))
                    expect(otherDelegate.receiveCalls.count).to(equal(1))
                }
            }

            context("wrapping delegate") {
                it("should call handle push") {
                    let delegate = CenterDelegate()
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: delegate)
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(delegate.receiveCalls.count).to(equal(1))
                    let wrappingDelegate = WrappingCenterDelegate(original: mockCenter.delegate!)
                    mockCenter.delegate = wrappingDelegate
                    openNotification(appOpened: false)
                    expect(manager.handlePushOpenedCalls.count).to(equal(2))
                    expect(delegate.receiveCalls.count).to(equal(2))
                    expect(wrappingDelegate.receiveCalls.count).to(equal(1))
                }
            }
        }
    }
}
