//
//  ExponeaType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 27/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

/// Protocol of what types of events are available in the Exponea SDK.
public protocol ExponeaType: class {
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
        flushingSetup: Exponea.FlushingSetup
    )

    /// Initialize the configuration without a projectMapping (token mapping) for each type of event.
    ///
    /// - Parameters:
    ///   - projectToken: Project token to be used through the SDK.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseUrl: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    ///   - appGroup: The app group used to share data among extensions, fx. for push delivered tracking.
    ///   - defaultProperties: A list of properties to be added to all tracking events.
    func configure(
        projectToken: String,
        authorization: Authorization,
        baseUrl: String?,
        appGroup: String?,
        defaultProperties: [String: JSONConvertible]?
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
    func configure(
        projectToken: String,
        projectMapping: [EventType: [ExponeaProject]],
        authorization: Authorization,
        baseUrl: String?,
        appGroup: String?,
        defaultProperties: [String: JSONConvertible]?
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

    /// Tracks the push notification clicked event to Exponea API.
    func trackPushOpened(with userInfo: [AnyHashable: Any])

    /// Handles push notification opened - user action for alert notifications, delivery into app for silent pushes.
    /// This method will parse the data, track it and perform actions if needed.
    func handlePushNotificationOpened(response: UNNotificationResponse)

    /// Handles push notification opened - user action for alert notifications, delivery into app for silent pushes.
    /// This method will parse the data, track it and perform actions if needed.
    func handlePushNotificationOpened(userInfo: [AnyHashable: Any], actionIdentifier: String?)

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

    // MARK: - Anonymize -

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    func anonymize()

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    /// Switches tracking into provided exponeaProject
    func anonymize(exponeaProject: ExponeaProject, projectMapping: [EventType: [ExponeaProject]]?)
}
