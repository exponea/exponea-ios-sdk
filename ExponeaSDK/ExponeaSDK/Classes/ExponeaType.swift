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
        _ projectSettings: Exponea.ProjectSettings,
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

    /// Fetch the App Inbox message by ID.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    func fetchAppInboxItem(_ messageId: String, completion: @escaping (Result<MessageItem>) -> Void)

    // MARK: - Anonymize -

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    func anonymize()

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    /// Switches tracking into provided exponeaProject
    func anonymize(
        exponeaProject: ExponeaProject,
        projectMapping: [EventType: [ExponeaProject]]?
    )

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
    func stopIntegration()
    func clearLocalCustomerData(appGroup: String)
}
