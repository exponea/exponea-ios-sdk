//
//  ExponeaType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 27/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Protocol of what types of events are available in the Exponea SDK.
public protocol ExponeaType: class {
    /// Shared instance of Exponea SDK.
    static var shared: Exponea { get }
    /// Logger shared instance.
    static var logger: Logger { get set }

    /// Configurarion object.
    var configuration: Configuration? { get }
    /// Identification of the flushing mode used in to send the data to the Exponea API.
    var flushingMode: FlushingMode { get set }
    /// The delegate that gets callbacks about notification opens and/or actions. Only has effect if automatic
    /// push tracking is enabled, otherwise will never get called.
    var pushNotificationsDelegate: PushNotificationManagerDelegate? { get set }

    // MARK: - Configure -

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
    ///   - projectMapping: The project token mapping dictionary providing all the tokens.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseUrl: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    ///   - appGroup: The app group used to share data among extensions, fx. for push delivered tracking.
    ///   - defaultProperties: A list of properties to be added to all tracking events.
    func configure(
        projectToken: String,
        projectMapping: [EventType: [String]],
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
        customerIds: [String: JSONConvertible]?,
        properties: [String: JSONConvertible],
        timestamp: Double?
    )

    /// This method can be used to manually flush all available data to Exponea.
    func flushData()

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

    /// Tracks the push notification clicked event to Exponea API.
    func trackPushOpened(with userInfo: [AnyHashable: Any])

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

    /// Fetch all available banners.
    ///
    /// - Parameters:
    ///   - completion: Object containing the request result.
    func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void)

    /// Fetch personalization (all banners) for current customer.
    ///
    /// - Parameters:
    ///   - request: Personalization request containing all the information about the request banners.
    ///   - completion: Object containing the request result.
    func fetchPersonalization(with request: PersonalizationRequest,
                              completion: @escaping (Result<PersonalizationResponse>) -> Void)

    /// Fetch the list of your existing consent categories.
    ///
    /// - Parameter completion: A closure executed upon request completion containing the result
    ///                         which has either the returned data or error.
    func fetchConsents(completion: @escaping (Result<ConsentsResponse>) -> Void)
}
