//
//  PushNotificationDelegateObserverSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 07/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class PushNotificationDelegateObserverSpec: QuickSpec {
    class EmptyDelegate: NSObject, UNUserNotificationCenterDelegate {}

    private var calls: [NSKeyValueObservedChange<UNUserNotificationCenterDelegate?>] = []
    private func notificationsDelegateChanged(_ change: NSKeyValueObservedChange<UNUserNotificationCenterDelegate?>) {
        calls.append(change)
    }
    override func spec() {
        afterEach {
            self.calls = []
        }
        it("should observe delegate change") {
            let observable = BasicUNUserNotificationCenterDelegating()
            let observer = PushNotificationDelegateObserver(
                observable: observable,
                callback: self.notificationsDelegateChanged
            )
            expect(observer.observation).notTo(beNil())
            expect(self.calls).to(beEmpty())
            observable.delegate = EmptyDelegate()
            expect(self.calls[0].oldValue).to(beNil())
            expect(self.calls[0].newValue).notTo(beNil())
        }
        it("should observe delegate change to nil") {
            let observable = BasicUNUserNotificationCenterDelegating()
            observable.delegate = EmptyDelegate()
            let observer = PushNotificationDelegateObserver(
                observable: observable,
                callback: self.notificationsDelegateChanged
            )
            expect(observer.observation).notTo(beNil())
            expect(self.calls).to(beEmpty())
            observable.delegate = nil
            expect(self.calls[0].oldValue).notTo(beNil())
            expect(self.calls[0].newValue).to(beNil())
        }
        it("should observe delegate change to other instance") {
            let observable = BasicUNUserNotificationCenterDelegating()
            observable.delegate = EmptyDelegate()
            let observer = PushNotificationDelegateObserver(
                observable: observable,
                callback: self.notificationsDelegateChanged
            )
            expect(observer.observation).notTo(beNil())
            expect(self.calls).to(beEmpty())
            observable.delegate = EmptyDelegate()
            expect(self.calls[0].oldValue).notTo(beNil())
            expect(self.calls[0].newValue).notTo(beNil())
        }
        it("should not observe nil-nil change") {
            let observable = BasicUNUserNotificationCenterDelegating()
            let observer = PushNotificationDelegateObserver(
                observable: observable,
                callback: self.notificationsDelegateChanged
            )
            expect(observer.observation).notTo(beNil())
            expect(self.calls).to(beEmpty())
            observable.delegate = nil
            expect(self.calls).to(beEmpty())
            observable.delegate = nil
            expect(self.calls).to(beEmpty())
        }
        it("should not observe same instance change") {
            let observable = BasicUNUserNotificationCenterDelegating()
            let delegate = EmptyDelegate()
            observable.delegate = delegate
            let observer = PushNotificationDelegateObserver(
                observable: observable,
                callback: self.notificationsDelegateChanged
            )
            expect(observer.observation).notTo(beNil())
            observable.delegate = delegate
            expect(self.calls).to(beEmpty())
        }
    }
}
