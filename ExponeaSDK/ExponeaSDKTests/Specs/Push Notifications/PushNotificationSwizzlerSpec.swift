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
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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

    class AppDelegateWithDeprecatedReceive: UIResponder, UIApplicationDelegate {
        var receiveCalls: [[AnyHashable: Any]] = []
        func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
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

    // This simulates system calling notification opened
    // First try notification center delegate, then try open push with handler, then try just open push
    func openNotification(uiApplication: UIApplicationDelegating, notificationCenter: BasicUNUserNotificationCenterDelegating) {
        let notificationDelegateSelector = PushSelectorMapping.Original.newReceive
        if let notificationDelegate = notificationCenter.delegate,
           class_getInstanceMethod(type(of: notificationDelegate), notificationDelegateSelector) != nil {
            notificationCenter.delegate?.userNotificationCenter?(
                UNUserNotificationCenter.current(),
                didReceive: mock_notification_response([:]),
                withCompletionHandler: {}
            )
            return
        }
        guard let appDelegate = uiApplication.delegate else {
            fatalError("There has to be UIApplication delegate")
        }
        let appPrefferedSelector =
            #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        let appDeprecatedSelector =
            NSSelectorFromString("application:didReceiveRemoteNotification:") // using string because of deprecation warning
        if class_getInstanceMethod(type(of: appDelegate), appPrefferedSelector) != nil {
            appDelegate.application?(UIApplication.shared, didReceiveRemoteNotification: [:], fetchCompletionHandler: {_ in })
        } else if class_getInstanceMethod(type(of: appDelegate), appDeprecatedSelector) != nil {
            appDelegate.perform(appDeprecatedSelector, with: UIApplication.shared, with: [:]) // because of deprecation warning
        }
    }

    override func spec() {
        _ = MockUserNotificationCenter.shared

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

        func openNotification() {
            self.openNotification(uiApplication: mockApplication, notificationCenter: mockCenter)
        }

        describe("token registration swizzling") {
            let selector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))

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
                it("should call handle push") {
                    setup(appDelegate: EmptyAppDelegate())
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                }
            }

            context("UI application delegate deprecated handler defined") {
                it("should call handle push, call original method") {
                    let appDelegate = AppDelegateWithDeprecatedReceive()
                    setup(appDelegate: appDelegate)
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(appDelegate.receiveCalls.count).to(equal(1))
                }
            }

            context("UI application delegate preffered handler defined") {
                it("should call handle push, call original method") {
                    let appDelegate = AppDelegateWithReceive()
                    setup(appDelegate: appDelegate)
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(appDelegate.receiveCalls.count).to(equal(1))
                }
            }

            context("Notification center empty delegate") {
                it("should call handle push when added before") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: EmptyCenterDelegate())
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                }
                it("should call handle push when added after") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: nil)
                    mockCenter.delegate = EmptyCenterDelegate()
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                }
                it("should call handle push when changed to nil") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: nil)
                    mockCenter.delegate = EmptyCenterDelegate()
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    mockCenter.delegate = nil
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(2))
                }
            }

            context("Notification center delegate with handler") {
                it("should call handle push, call original method when added before") {
                    let centerDelegate = CenterDelegate()
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: centerDelegate)
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                }
                it("should call handle push, call original method when added after") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: nil)
                    let centerDelegate = CenterDelegate()
                    mockCenter.delegate = centerDelegate
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                }
                it("should call handle push, call original method when changed to nil") {
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: nil)
                    let centerDelegate = CenterDelegate()
                    mockCenter.delegate = centerDelegate
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                    mockCenter.delegate = nil
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(2))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                    mockCenter.delegate = nil
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(3))
                    expect(centerDelegate.receiveCalls.count).to(equal(1))
                }
            }

            context("changing center delegate") {
                it("should call handle push") {
                    let delegate = CenterDelegate()
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: delegate)
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(delegate.receiveCalls.count).to(equal(1))
                    let otherDelegate = OtherCenterDelegate()
                    mockCenter.delegate = otherDelegate
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(2))
                    expect(delegate.receiveCalls.count).to(equal(1))
                    expect(otherDelegate.receiveCalls.count).to(equal(1))
                }
            }

            context("wrapping delegate") {
                it("should call handle push") {
                    let delegate = CenterDelegate()
                    setup(appDelegate: EmptyAppDelegate(), centerDelegate: delegate)
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(1))
                    expect(delegate.receiveCalls.count).to(equal(1))
                    let wrappingDelegate = WrappingCenterDelegate(original: mockCenter.delegate!)
                    mockCenter.delegate = wrappingDelegate
                    openNotification()
                    expect(manager.handlePushOpenedCalls.count).to(equal(2))
                    expect(delegate.receiveCalls.count).to(equal(2))
                    expect(wrappingDelegate.receiveCalls.count).to(equal(1))
                }
            }
        }
    }
}
