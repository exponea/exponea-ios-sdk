//
//  InstallIdResetSpec.swift
//  ExponeaSDKTests
//
//  Verifies that the telemetry install ID (used as device_id in notification_state and other events)
//  is cleared when stopIntegration() or clearLocalCustomerData(appGroup:) is called.
//  Anonymize does NOT clear device_id (install ID is preserved).
//

import Quick
import Nimble

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class InstallIdResetSpec: QuickSpec {
    override func spec() {
        describe("Install ID (device_id) reset on stop and clear") {
            context("stopIntegration") {
                let appGroup = "group.test.exponea.installid.reset"

                beforeEach {
                    IntegrationManager.shared.isStopped = false
                    TelemetryUtility.clearInstallIdFromAllStores(appGroup: appGroup)
                    UserDefaults(suiteName: appGroup)?.removeObject(forKey: Constants.General.lastKnownConfiguration)
                }

                afterEach {
                    IntegrationManager.shared.isStopped = false
                }

                it("clears install ID from app group UserDefaults so next getInstallId returns a new value") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(
                        Exponea.ProjectSettings(projectToken: "test-token", authorization: .token("test")),
                        pushNotificationTracking: .enabled(appGroup: appGroup),
                        flushingSetup: Exponea.FlushingSetup(mode: .manual)
                    )

                    let defaults = TelemetryUtility.getUserDefaults(appGroup: appGroup)
                    let installIdBeforeStop = TelemetryUtility.getInstallId(userDefaults: defaults)
                    expect(installIdBeforeStop).notTo(beEmpty())
                    expect(UUID(uuidString: installIdBeforeStop)).notTo(beNil())

                    Exponea.shared.stopIntegration()

                    let installIdAfterStop = TelemetryUtility.getInstallId(userDefaults: TelemetryUtility.getUserDefaults(appGroup: appGroup))
                    expect(installIdAfterStop).notTo(equal(installIdBeforeStop))
                    expect(UUID(uuidString: installIdAfterStop)).notTo(beNil())
                }
            }

            context("clearLocalCustomerData") {
                let appGroup = "group.test.exponea.clear.installid"

                beforeEach {
                    Exponea.shared = ExponeaInternal()
                    TelemetryUtility.clearInstallIdFromAllStores(appGroup: appGroup)
                    UserDefaults(suiteName: appGroup)?.removeObject(forKey: Constants.General.lastKnownConfiguration)
                }

                it("clears install ID from app group UserDefaults so next getInstallId returns a new value") {
                    let configuration = try! Configuration(
                        projectToken: "test-token",
                        authorization: .none,
                        baseUrl: Constants.Repository.baseUrl,
                        appGroup: appGroup
                    )
                    configuration.saveToUserDefaults()
                    expect(Configuration.loadFromUserDefaults(appGroup: appGroup)).notTo(beNil())

                    let appGroupDefaults = TelemetryUtility.getUserDefaults(appGroup: appGroup)
                    appGroupDefaults.set("old-install-id-in-appgroup", forKey: Constants.General.telemetryInstallId)

                    Exponea.shared.clearLocalCustomerData(appGroup: appGroup)

                    let installIdAfterClear = TelemetryUtility.getInstallId(userDefaults: TelemetryUtility.getUserDefaults(appGroup: appGroup))
                    expect(installIdAfterClear).notTo(equal("old-install-id-in-appgroup"))
                    expect(UUID(uuidString: installIdAfterClear)).notTo(beNil())
                }

                it("clears install ID from UserDefaults.standard when it was stored there (fallback suite)") {
                    let configuration = try! Configuration(
                        projectToken: "test-token",
                        authorization: .none,
                        baseUrl: Constants.Repository.baseUrl,
                        appGroup: appGroup
                    )
                    configuration.saveToUserDefaults()
                    expect(Configuration.loadFromUserDefaults(appGroup: appGroup)).notTo(beNil())

                    UserDefaults.standard.set("old-install-id-in-standard", forKey: Constants.General.telemetryInstallId)

                    Exponea.shared.clearLocalCustomerData(appGroup: appGroup)

                    let installIdAfterClear = TelemetryUtility.getInstallId(userDefaults: UserDefaults.standard)
                    expect(installIdAfterClear).notTo(equal("old-install-id-in-standard"))
                    expect(UUID(uuidString: installIdAfterClear)).notTo(beNil())
                }
            }

            context("anonymize") {
                let appGroup = "group.test.exponea.anonymize.installid"

                beforeEach {
                    IntegrationManager.shared.isStopped = false
                    TelemetryUtility.clearInstallIdFromAllStores(appGroup: appGroup)
                    UserDefaults(suiteName: appGroup)?.removeObject(forKey: Constants.General.lastKnownConfiguration)
                }

                afterEach {
                    IntegrationManager.shared.isStopped = false
                }

                it("does not clear install ID (device_id is preserved across anonymize)") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(
                        Exponea.ProjectSettings(projectToken: "test-token", authorization: .token("test")),
                        pushNotificationTracking: .enabled(appGroup: appGroup),
                        flushingSetup: Exponea.FlushingSetup(mode: .manual)
                    )

                    let defaults = TelemetryUtility.getUserDefaults(appGroup: appGroup)
                    let installIdBeforeAnonymize = TelemetryUtility.getInstallId(userDefaults: defaults)
                    expect(installIdBeforeAnonymize).notTo(beEmpty())
                    expect(UUID(uuidString: installIdBeforeAnonymize)).notTo(beNil())

                    Exponea.shared.anonymize()

                    let installIdAfterAnonymize = TelemetryUtility.getInstallId(userDefaults: TelemetryUtility.getUserDefaults(appGroup: appGroup))
                    expect(installIdAfterAnonymize).to(equal(installIdBeforeAnonymize))
                }
            }
        }
    }
}
