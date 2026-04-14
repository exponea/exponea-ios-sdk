import Foundation
import Nimble
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class StopIntegrationSpec: QuickSpec {

    override func spec() {
        var exponea: ExponeaInternal!
        var database: MockDatabaseManager!
        var repository: MockRepository!
        var configuration: Configuration!

        describe("stopIntegration") {
            beforeEach {
                exponea = ExponeaInternal()
                Exponea.shared = exponea
                IntegrationManager.shared.isStopped = false

                configuration = try! Configuration(
                    integrationConfig: Exponea.StreamSettings(streamId: UUID().uuidString, baseUrl: "https://google.com"),
                    appGroup: "test-group"
                )
                configuration.automaticSessionTracking = true
                repository = MockRepository(configuration: configuration)
                database = try! MockDatabaseManager()

                let userDefaults = MockUserDefaults()
                let key = Constants.Keys.installTracked + database.currentCustomer.uuid.uuidString
                userDefaults.set(true, forKey: key)

                let flushingManager = try! FlushingManager(
                    database: database,
                    repository: repository,
                    customerIdentifiedHandler: {}
                )
                flushingManager.flushingMode = .manual

                let trackingManager = try! TrackingManager(
                    repository: repository,
                    database: database,
                    flushingManager: flushingManager,
                    inAppMessageManager: nil,
                    trackManagerInitializator: { _ in },
                    userDefaults: userDefaults,
                    campaignRepository: CampaignRepository(userDefaults: userDefaults),
                    requirePushAuthorization: false,
                    onEventCallback: { _, _ in }
                )
                try! trackingManager.track(
                    .registerPushToken,
                    with: [.pushNotificationToken(token: "mock-push-token", authorized: true)]
                )

                exponea.repository = repository
                exponea.trackingManager = trackingManager
                exponea.flushingManager = flushingManager
            }

            it("should track session_end when automatic session tracking is enabled") {
                repository.trackObjectResult = .success
                var flushedEventTypes: [String] = []
                repository.trackObjectHook = { object in
                    if let event = object as? EventTrackingObject,
                       let eventType = event.eventType {
                        flushedEventTypes.append(eventType)
                    }
                }
                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }
                expect(flushedEventTypes).to(contain(Constants.EventTypes.sessionEnd))
                expect(IntegrationManager.shared.isStopped).to(beTrue())
                IntegrationManager.shared.isStopped = false
            }

            it("should NOT track session_end when automatic session tracking is disabled") {
                configuration.automaticSessionTracking = false
                repository = MockRepository(configuration: configuration)
                repository.trackObjectResult = .success
                exponea.repository = repository

                var flushedEventTypes: [String] = []
                repository.trackObjectHook = { object in
                    if let event = object as? EventTrackingObject,
                       let eventType = event.eventType {
                        flushedEventTypes.append(eventType)
                    }
                }
                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }
                expect(flushedEventTypes).toNot(contain(Constants.EventTypes.sessionEnd))
                expect(IntegrationManager.shared.isStopped).to(beTrue())
                IntegrationManager.shared.isStopped = false
            }

            it("should track notification_state with valid false") {
                repository.trackObjectResult = .success
                var flushedEventTypes: [String] = []
                repository.trackObjectHook = { object in
                    if let event = object as? EventTrackingObject,
                       let eventType = event.eventType {
                        flushedEventTypes.append(eventType)
                    }
                }
                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }
                expect(flushedEventTypes).to(contain(Constants.EventTypes.notificationState))
                IntegrationManager.shared.isStopped = false
            }

            it("should call completion on the main thread") {
                repository.trackObjectResult = .success
                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration {
                        expect(Thread.isMainThread).to(beTrue())
                        done()
                    }
                }
                IntegrationManager.shared.isStopped = false
            }

            it("should set isStopped after teardown") {
                repository.trackObjectResult = .success
                expect(IntegrationManager.shared.isStopped).to(beFalse())
                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration {
                        expect(IntegrationManager.shared.isStopped).to(beTrue())
                        done()
                    }
                }
                IntegrationManager.shared.isStopped = false
            }

            it("should handle stopIntegration when SDK is not initialized") {
                let uninitializedExponea = ExponeaInternal()
                Exponea.shared = uninitializedExponea
                waitUntil(timeout: .seconds(5)) { done in
                    uninitializedExponea.stopIntegration {
                        expect(IntegrationManager.shared.isStopped).to(beTrue())
                        done()
                    }
                }
                IntegrationManager.shared.isStopped = false
            }

            it("should handle double stopIntegration without crashing") {
                repository.trackObjectResult = .success
                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }
                expect(IntegrationManager.shared.isStopped).to(beTrue())
                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }
                expect(IntegrationManager.shared.isStopped).to(beTrue())
                IntegrationManager.shared.isStopped = false
            }

            it("should NOT track notification_state when customerPushToken is nil") {
                let noPushTokenExponea = ExponeaInternal()
                Exponea.shared = noPushTokenExponea

                let noPushRepository = MockRepository(configuration: configuration)
                noPushRepository.trackObjectResult = .success
                let noPushDatabase = try! MockDatabaseManager()
                let userDefaults = MockUserDefaults()
                let key = Constants.Keys.installTracked + noPushDatabase.currentCustomer.uuid.uuidString
                userDefaults.set(true, forKey: key)

                let noPushFlushingManager = try! FlushingManager(
                    database: noPushDatabase,
                    repository: noPushRepository,
                    customerIdentifiedHandler: {}
                )
                noPushFlushingManager.flushingMode = .manual

                let noPushTrackingManager = try! TrackingManager(
                    repository: noPushRepository,
                    database: noPushDatabase,
                    flushingManager: noPushFlushingManager,
                    inAppMessageManager: nil,
                    trackManagerInitializator: { _ in },
                    userDefaults: userDefaults,
                    campaignRepository: CampaignRepository(userDefaults: userDefaults),
                    requirePushAuthorization: false,
                    onEventCallback: { _, _ in }
                )

                noPushTokenExponea.repository = noPushRepository
                noPushTokenExponea.trackingManager = noPushTrackingManager
                noPushTokenExponea.flushingManager = noPushFlushingManager

                var flushedEventTypes: [String] = []
                noPushRepository.trackObjectHook = { object in
                    if let event = object as? EventTrackingObject,
                       let eventType = event.eventType {
                        flushedEventTypes.append(eventType)
                    }
                }
                waitUntil(timeout: .seconds(5)) { done in
                    noPushTokenExponea.stopIntegration { done() }
                }
                expect(flushedEventTypes).toNot(contain(Constants.EventTypes.notificationState))
                expect(IntegrationManager.shared.isStopped).to(beTrue())
                IntegrationManager.shared.isStopped = false
            }
        }
    }
}
