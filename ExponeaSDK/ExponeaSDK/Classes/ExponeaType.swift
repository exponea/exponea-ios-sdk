//
//  ExponeaType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 27/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public protocol ExponeaType: class {
    static var shared: Exponea { get }
    static var logger: Logger { get set }
    
    var configuration: Configuration? { get }
    var flushingMode: FlushingMode { get set }
    
    // MARK: - Configure -
    
    func configure(projectToken: String, authorization: Authorization, baseURL: String?)
    func configure(projectToken: String, projectMapping: [EventType: [String]],
                   authorization: Authorization, baseURL: String?)
    func configure(plistName: String)
    
    // MARK: - Tracking -
    
    func trackEvent(properties: [AnyHashable: JSONConvertible], timestamp: Double?, eventType: String?)
    func identifyCustomer(customerId: String?, properties: [AnyHashable: JSONConvertible], timestamp: Double?)
    
    func flushData()
    
    // MARK: - Push -
    
    func trackPushToken(_ token: Data)
    func trackPushToken(_ token: String)
    func trackPushClicked()
    
    // MARK: - Sessions -
    
    func trackSessionStart()
    func trackSessionEnd()
    
    // MARK: - Data Fetching -
    
    func fetchEvents(with request: EventsRequest,
                     completion: @escaping (Result<EventsResponse>) -> Void)
    
    func fetchAttributes(with request: AttributesDescription,
                         completion: @escaping (Result<AttributesListDescription>) -> Void)
    
    func fetchRecommendation(with request: RecommendationRequest,
                             completion: @escaping (Result<RecommendationResponse>) -> Void)
    
}
