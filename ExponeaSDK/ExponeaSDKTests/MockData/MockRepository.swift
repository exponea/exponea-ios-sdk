//
//  MockRepository.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

@testable import ExponeaSDK

class MockRepository {
    
    public internal(set) var configuration: Configuration
    private let session = URLSession.shared
    
    // Initialize the configuration for all HTTP requests
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
}

extension MockRepository: TrackingRepository {
    func trackCustomer(with data: [DataType], for customerIds: [String : JSONValue], completion: @escaping ((EmptyResult) -> Void)) {
        
    }
    
    func trackEvent(with data: [DataType], for customerIds: [String : JSONValue], completion: @escaping ((EmptyResult) -> Void)) {
        
    }
    
    
}
