//
//  ExponeaType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 27/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

/// Protocol of what types of events are available in the Exponea SDK.
public protocol ExponeaType: AnyObject {
    /// Configuration status of the SDK
    var isConfigured: Bool { get }
    /// Configurarion object.
    var configuration: Configuration? { get }
    /// Cookie of the current customer. Nil before the SDK is configured
    var customerCookie: String? { get }
    /// Identification of the flushing mode used in to send the data to the Exponea API.
    var flushingMode: FlushingMode { get set }
    /// The delegate that gets callbacks about notification opens and/or actions. Only has effect if automatic
    /// push tracking is enabled, otherwise will never get called.
    var pushNotificationsDelegate: PushNotificationManagerDelegate? { get set }
    /// The delegate that gets callbacks about in app message actions.
    var inAppMessagesDelegate: InAppMessageActionDelegate { get set }
    /// App inbox provider definition
    var appInboxProvider: AppInboxProvider { get set }
    /// In-app content block manager
    var inAppContentBlocksManager: InAppContentBlocksManagerType? { get }

    /// Any NSException inside Exponea SDK will be logged and swallowed if flag is enabled, otherwise
    /// the exception will be rethrown.
    /// Safemode is enabled for release builds and disabled for debug builds.
    /// You can set the value to override this behavior for e.g. unit testing.
    /// We advice strongly against disabling this for production builds.
    var safeModeEnabled: Bool { get set }

    /// To help developers with integration, we can automatically check push notification setup
    /// when application is started in debug mode.
    /// When integrating push notifications(or when testing), we
    /// advise you to turn this feature on before initializing the SDK.
    /// Self-check only runs in debug mode and does not do anything in release builds.
    var checkPushSetup: Bool { get set }

    /// Default properties to be tracked with all events.
    /// Provide default properties when calling Exponea.shared.configure, they're exposed here for run-time changing.
    var defaultProperties: [String: JSONConvertible]? { get set }

    // MARK: - Configure -

    /// Configure the SDK setting configuration properties split into areas of functionality
    func configure(
        _ integrationConfig: any IntegrationType,
        pushNotificationTracking: Exponea.PushNotificationTracking,
        automaticSessionTracking: Exponea.AutomaticSessionTracking,
        defaultProperties: [String: JSONConvertible]?,
        inAppContentBlocksPlaceholders: [String]?,
        flushingSetup: Exponea.FlushingSetup,
        allowDefaultCustomerProperties: Bool?,
        advancedAuthEnabled: Bool?,
        manualSessionAutoClose: Bool,
        applicationID: String?
    )

    /// Initialize the configuration without a projectMapping (token mapping) for each type of event.
    ///
    /// - Parameters:
    ///   - projectToken: Project token to be used through the SDK.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseUrl: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    ///   - appGroup: The app group used to share data among extensions, fx. for push delivered tracking.
    ///   - defaultProperties: A list of properties to be added to all tracking events.
    ///   - allowDefaultCustomerProperties: Flag if apply default properties list to 'identifyCustomer' tracke event
    ///   - advancedAuthEnabled: Flag if advanced authorization used for communication with BE
    func configure(
        projectToken: String,
        authorization: Authorization,
        baseUrl: String?,
        appGroup: String?,
        defaultProperties: [String: JSONConvertible]?,
        inAppContentBlocksPlaceholders: [String]?,
        allowDefaultCustomerProperties: Bool?,
        advancedAuthEnabled: Bool?,
        manualSessionAutoClose: Bool,
        applicationID: String?
    )

    /// Initialize the configuration with a projectMapping (token mapping) for each type of event. This allows
    /// you to track events to multiple projects, even the same event to more project at once.
    ///
    /// - Parameters:
    ///   - projectToken: Project token to be used through the SDK, as a fallback to projectMapping.
    ///   - projectMapping: The project mapping dictionary providing all the tokens.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseUrl: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    ///   - appGroup: The app group used to share data among extensions, fx. for push delivered tracking.
    ///   - defaultProperties: A list of properties to be added to all tracking events.
    ///   - allowDefaultCustomerProperties: Flag if apply default properties list to 'identifyCustomer' tracke event
    ///   - advancedAuthEnabled: Flag if advanced authorization used for communication with BE
    func configure(
        projectToken: String,
        projectMapping: [EventType: [ExponeaProject]],
        authorization: Authorization,
        baseUrl: String?,
        appGroup: String?,
        defaultProperties: [String: JSONConvertible]?,
        inAppContentBlocksPlaceholders: [String]?,
        allowDefaultCustomerProperties: Bool?,
        advancedAuthEnabled: Bool?,
        manualSessionAutoClose: Bool,
        applicationID: String?
    )

    /// Initialize the configuration with a plist file containing the keys for the ExponeaSDK.
    ///
    /// - Parameters:
    ///   - plistName: Property list name containing the SDK setup keys
    ///
    /// Mandatory keys:
    ///  - projectToken: Project token to be used through the SDK, as a fallback to projectMapping.
    ///  - authorization: The authorization type used to authenticate with some Exponea endpoints.
    func configure(plistName: String)
    
    /// Configure the SDK with a Configuration object and optional authentication context.
    /// Use this when you want to provide initial customer IDs and/or JWT token during configuration.
    ///
    /// - Parameters:
    ///   - configuration: The SDK configuration object.
    ///   - authContext: Optional authentication context with customer IDs and JWT token.
    func configure(
        with configuration: Configuration,
        authContext: CustomerIdentity?
    )
    
    // MARK: - Stream JWT (Data Hub) -
    
    /// Sets the Stream JWT token for Data Hub authentication.
    /// This token is used for all Stream API requests including tracking and App Inbox.
    /// Only effective when SDK is configured with Stream integration.
    /// JWT is cleared internally on anonymize, identifyCustomer without token, or clearLocalCustomerData.
    ///
    /// - Parameter token: The JWT token string (must be non-empty).
    func setSdkAuthToken(_ token: String)
    
    /// Sets a handler that will be called when JWT-related errors occur.
    /// Use this to refresh the JWT token when it expires or becomes invalid.
    ///
    /// - Parameter handler: Closure called with JWT error context when errors occur.
    func setJwtErrorHandler(_ handler: @escaping (JwtErrorContext) -> Void)
    
    /// Identifies a customer with authentication context.
    /// Use this method when working with Stream JWT authentication.
    ///
    /// - Parameters:
    ///   - context: Authentication context containing customer IDs and optional JWT token.
    ///   - properties: Customer properties to track.
    ///   - timestamp: Optional Unix timestamp when the event was created.
    func identifyCustomer(
        context: CustomerIdentity,
        properties: [String: JSONConvertible],
        timestamp: Double?
    )

    // MARK: - Tracking -

    /// Adds new events to a customer. All events will be stored into coredata
    /// until it will be flushed (send to api).
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    ///     - eventType: Name of event
    func trackEvent(properties: [String: JSONConvertible], timestamp: Double?, eventType: String?)

    /// Adds new campaing click event.
    /// This occures when user has opened the application via universal link
    ///
    /// - Parameters:
    ///     - url: campaign url
    ///     - timestamp: Unix timestamp when the event was created.
    func trackCampaignClick(url: URL, timestamp: Double?)
    /// Adds new payment event to a customer.
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    func trackPayment(properties: [String: JSONConvertible], timestamp: Double?)

    /// Update the informed properties to a specific customer.
    /// All properties will be stored into coredata until it will be flushed (send to api).
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id, for example an email address.
    ///     - properties: Object with properties to be updated.
    ///     - timestamp: Unix timestamp when the event was created.
    @available(*, deprecated, message: "Use identifyCustomer(context:properties:timestamp:) with CustomerIdentity(customerIds:jwtToken:) instead.")
    func identifyCustomer(
        customerIds: [String: String]?,
        properties: [String: JSONConvertible],
        timestamp: Double?
    )

    /// This method can be used to manually flush all available data to Exponea.
    func flushData()

    /// This method can be used to manually flush all available data to Exponea.
    func flushData(completion: ((FlushResult) -> Void)?)

    // MARK: - Push -

    /// Tracks the push notification token to Exponea API with struct.
    ///
    /// - Parameter token: Token data.
    func trackPushToken(_ token: Data)

    /// Tracks the push notification token to Exponea API with string.
    ///
    /// - Parameter token: String containing the push notification token.
    ///                    If nil, it will delete existing push token.
    func trackPushToken(_ token: String?)

    /// Handles push notification token registration - compared to trackPushToken respects requirePushAuthorization
    func handlePushNotificationToken(deviceToken: Data)
    
    /// Handles the change of push notifications permissions and tracks current push notification token
    func trackCurrentPushNotificationToken()

    /// Handles push notification token registration - compared to trackPushToken respects requirePushAuthorization
    func handlePushNotificationToken(token: String)

    /// Tracks push notification delivery
    func trackPushReceived(content: UNNotificationContent)

    /// Tracks push notification delivery
    func trackPushReceived(userInfo: [AnyHashable: Any])

    /// Tracks push notification delivery
    /// Event is tracked even if  notification and action link have not a tracking consent.
    func trackPushReceivedWithoutTrackingConsent(content: UNNotificationContent)

    /// Tracks push notification delivery
    /// Event is tracked even if  notification and action link have not a tracking consent.
    func trackPushReceivedWithoutTrackingConsent(userInfo: [AnyHashable: Any])

    /// Tracks the push notification clicked event to Exponea API.
    func trackPushOpened(with userInfo: [AnyHashable: Any])

    /// Handles push notification opened - user action for alert notifications, delivery into app for silent pushes.
    /// This method will parse the data, track it and perform actions if needed.
    func handlePushNotificationOpened(response: UNNotificationResponse)

    /// Handles push notification opened - user action for alert notifications, delivery into app for silent pushes.
    /// This method will parse the data, track it and perform actions if needed.
    func handlePushNotificationOpened(userInfo: [AnyHashable: Any], actionIdentifier: String?)

    /// Tracks the push notification clicked event to Exponea API.
    /// Event is tracked even if  notification and action link have not a tracking consent.
    func trackPushOpenedWithoutTrackingConsent(with userInfo: [AnyHashable: Any])

    /// Handles push notification opened - user action for alert notifications, delivery into app for silent pushes.
    /// This method will parse the data, track it and perform actions if needed.
    /// Event is tracked even if Notification and button link have not a tracking consent.
    func handlePushNotificationOpenedWithoutTrackingConsent(userInfo: [AnyHashable: Any], actionIdentifier: String?)

    /// Track in-app message banner click event
    /// Event is tracked even if InAppMessage and button link have not a tracking consent.
    func trackInAppMessageClickWithoutTrackingConsent(message: InAppMessage, buttonText: String?, buttonLink: String?)

    /// Track in-app message banner close event
    func trackInAppMessageCloseClickWithoutTrackingConsent(message: InAppMessage, buttonText: String?, isUserInteraction: Bool?)

    /// Track AppInbox message detail opened event
    /// Event is tracked if parameter 'message' has TRUE value of 'hasTrackingConsent' property
    func trackAppInboxOpened(message: MessageItem)

    /// Track AppInbox message detail opened event
    func trackAppInboxOpenedWithoutTrackingConsent(message: MessageItem)

    /// Track AppInbox message click event
    /// Event is tracked if one or both conditions met:
    ///     - parameter 'message' has TRUE value of 'hasTrackingConsent' property
    ///     - parameter 'buttonLink' has TRUE value of query parameter 'xnpe_force_track'
    func trackAppInboxClick(action: MessageItemAction, message: MessageItem)

    /// Track AppInbox message click event
    func trackAppInboxClickWithoutTrackingConsent(action: MessageItemAction, message: MessageItem)

    /// Marks AppInbox message as read
    func markAppInboxAsRead(_ message: MessageItem, completition: ((Bool) -> Void)?)

    /// Retrieves Button for opening of AppInbox list
    func getAppInboxButton() -> UIButton

    /// Retrieves UIViewController for AppInbox list with default behaviour
    func getAppInboxListViewController() -> UIViewController
    
    /// Retrieves UIViewController for AppInbox list with overriden onItemClicked behaviour
    func getAppInboxListViewController(onItemClicked: @escaping (MessageItem, Int) -> Void) -> UIViewController

    /// Retrieves UIViewController for AppInbox message detail
    func getAppInboxDetailViewController(_ messageId: String) -> UIViewController

    // MARK: - Sessions -

    /// Tracks the start of the user session.
    func trackSessionStart()

    /// Tracks the end of the user session.
    func trackSessionEnd()

    // MARK: - Data Fetching -

    /// Fetch recommendations for customer.
    /// Recommendations contain fields as defined on Exponea backend.
    /// You have to define your own struct for contents of those fields
    ///  and call this generic function with it in callback.
    ///
    /// - Parameters:
    ///   - options: Parameters for recommendation request
    ///   - completion: Object containing the request result.
    func fetchRecommendation<T: RecommendationUserData>(
        with options: RecommendationOptions,
        completion: @escaping (Result<RecommendationResponse<T>>) -> Void
    )

    /// Fetch the list of your existing consent categories.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void)

    /// Fetch the App Inbox list.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    func fetchAppInbox(completion: @escaping (Result<[MessageItem]>) -> Void)

    /// Fetch App Inbox messages using appropriate auth:
    /// - Engagement mode: Customer Token (legacy)
    /// - Stream mode: Stream JWT (Data Hub)
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result.
    func fetchAppInboxMessages(completion: @escaping (Result<[MessageItem]>) -> Void)

    /// Fetch the App Inbox message by ID.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    func fetchAppInboxItem(_ messageId: String, completion: @escaping (Result<MessageItem>) -> Void)

    // MARK: - Anonymize -

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    ///
    /// > **Warning — non-anonymous (Stream / JWT) integrations:**
    /// > `anonymize()` generates anonymous events (`installation`, `session_start`) after clearing the
    /// > current identity. If your integration requires that every event is associated with an authenticated
    /// > customer and a valid JWT (e.g. CDE / Stream / Data Hub), call `stopIntegration(completion:)`
    /// > on logout instead. `stopIntegration` does not generate anonymous events.
    func anonymize()

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    /// Switches tracking into provided exponeaProject
    @available(*, deprecated, message: """
        Please use following function instead:
        func anonymize(exponeaIntegrationType: any ExponeaIntegrationType, exponeaProjectMapping: [EventType: [ExponeaProject]]? = nil) throws
    """)
    func anonymize(
        exponeaProject: ExponeaProject,
        projectMapping: [EventType: [ExponeaProject]]?
    )
    
    func anonymize(
        exponeaIntegrationType: any ExponeaIntegrationType,
        exponeaProjectMapping: [EventType: [ExponeaProject]]?
    )

    /// Anonymizes the user with a completion callback.
    /// In Stream mode, pending events are flushed with the current JWT before the identity is cleared.
    /// The completion is called on the main thread once the anonymize (and optional flush) finishes.
    func anonymize(completion: (() -> Void)?)

    func trackInAppMessageClick(message: InAppMessage, buttonText: String?, buttonLink: String?)

    func trackInAppMessageClose(message: InAppMessage, buttonText: String?, isUserInteraction: Bool?)

    /// Tracks 'click' event for given In-app content block action.
    /// Event is tracked if one or both conditions met:
    ///     - parameter 'message' has TRUE value of 'hasTrackingConsent' property
    ///     - parameter 'action.url' has TRUE value of query parameter 'xnpe_force_track'
    func trackInAppContentBlockClick(
        placeholderId: String,
        action: InAppContentBlockAction,
        message: InAppContentBlockResponse
    )

    /// Tracks 'click' event for given In-app content block action.
    func trackInAppContentBlockClickWithoutTrackingConsent(
        placeholderId: String,
        action: InAppContentBlockAction,
        message: InAppContentBlockResponse
    )

    /// Tracks 'close' event for given In-app content block.
    /// Event is tracked if one or both conditions met:
    ///     - parameter 'message' has TRUE value of 'hasTrackingConsent' property
    func trackInAppContentBlockClose(
        placeholderId: String,
        message: InAppContentBlockResponse
    )

    /// Tracks 'close' event for given In-app content block.
    func trackInAppContentBlockCloseWithoutTrackingConsent(
        placeholderId: String,
        message: InAppContentBlockResponse
    )

    /// Tracks 'show' event for given In-app content block.
    /// Event is tracked if one or both conditions met:
    ///     - parameter 'message' has TRUE value of 'hasTrackingConsent' property
    func trackInAppContentBlockShown(
        placeholderId: String,
        message: InAppContentBlockResponse
    )

    /// Tracks 'show' event for given In-app content block.
    func trackInAppContentBlockShownWithoutTrackingConsent(
        placeholderId: String,
        message: InAppContentBlockResponse
    )

    /// Tracks 'error' event for given In-app content block.
    /// Event is tracked if one or both conditions met:
    ///     - parameter 'message' has TRUE value of 'hasTrackingConsent' property
    func trackInAppContentBlockError(
        placeholderId: String,
        message: InAppContentBlockResponse,
        errorMessage: String
    )

    /// Tracks 'error' event for given In-app content block.
    func trackInAppContentBlockErrorWithoutTrackingConsent(
        placeholderId: String,
        message: InAppContentBlockResponse,
        errorMessage: String
    )

    func getSegments(force: Bool, category: SegmentCategory, result: @escaping TypeBlock<[SegmentDTO]>)

    /// Stops the SDK integration synchronously (fire-and-forget).
    ///
    /// This is a convenience wrapper for `stopIntegration(completion: nil)`.
    ///
    /// > **Behavioral change (4.0.0):** This method now tracks `session_end` (when automatic session
    /// > tracking is enabled) and sends a `notification_state` event with `valid: false` to invalidate
    /// > the push token before flushing. Callers that previously relied on a silent, event-free stop
    /// > (e.g. GDPR data removal, consent gating) should be aware that these events will be sent.
    /// >
    /// > If you need to act after teardown is complete, use `stopIntegration(completion:)` instead.
    func stopIntegration()

    /// Stops the SDK integration, tracking logout events and flushing pending data before teardown.
    ///
    /// Use this instead of `anonymize()` when non-anonymous traffic is required (e.g. CDE / Stream JWT mode).
    /// The SDK will, in order:
    ///   1. Track `session_end` if automatic session tracking is enabled. Apps using manual
    ///      session tracking should call `trackSessionEnd()` themselves before this method.
    ///   2. Invalidate the push notification token (`notification_state` with `valid: false`).
    ///   3. Flush all pending events to the server while the current JWT is still live.
    ///   4. Tear down all SDK state.
    ///   5. Invoke `completion` on the main thread.
    ///
    /// The host app may safely call `Exponea.shared.configure(...)` again inside the completion handler.
    ///
    /// - Parameter completion: Optional block invoked on the main thread after full teardown.
    func stopIntegration(completion: (() -> Void)?)

    func clearLocalCustomerData(appGroup: String)
}
