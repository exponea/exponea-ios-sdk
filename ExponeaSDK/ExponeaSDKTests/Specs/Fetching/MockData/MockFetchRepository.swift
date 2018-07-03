//
//  MockFetchRepository.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

@testable import ExponeaSDK

class MockFetchRepository {
    var configuration: Configuration
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
}

extension MockFetchRepository: FetchRepository {
    
    func fetchRecommendation(recommendation: RecommendationRequest, for customerIds: [String : JSONValue], completion: @escaping (Result<RecommendationResponse>) -> Void) {
        
        let router = RequestFactory(baseURL: configuration.baseURL,
                                    projectToken: Exponea.shared.configuration!.fetchingToken,
                                    route: .customerRecommendation)
        let parameters = CustomerParameters(customer: customerIds, recommendation: recommendation)
        let request = router.prepareRequest(authorization: configuration.authorization, parameters: parameters)
        let bundle = Bundle(for: type(of: self))
        
        guard request.url != nil else {
            fatalError("URL could not be retrieve")
        }
        
        guard
            let file = bundle.url(forResource: "get-recommendation", withExtension: "json"),
            let data = try? Data(contentsOf: file),
            let recommendation = try? JSONDecoder().decode(RecommendationResponse.self, from: data)
            else {
                fatalError("Something is horribly wrong with the data.")
        }
        
        let result = Result.success(recommendation)
        
        completion(result)
    }
    
    func fetchAttributes(attributes: [AttributesDescription], for customerIds: [String : JSONValue], completion: @escaping (Result<AttributesListDescription>) -> Void) {
        return
    }
    
    func fetchEvents(events: EventsRequest, for customerIds: [String : JSONValue], completion: @escaping (Result<EventsResponse>) -> Void) {
        return
    }
    
    func fetchBanners(completion: @escaping (Result<BannerResponse>) -> Void) {
        return
    }
    
    func fetchPersonalization(with request: PersonalizationRequest, for customerIds: [String : JSONValue], completion: @escaping (Result<PersonalizationResponse>) -> Void) {
        return
    }
}

extension MockFetchRepository: RepositoryType {
    func trackCustomer(with data: [DataType], for customerIds: [String : JSONValue], completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
    
    func trackEvent(with data: [DataType], for customerIds: [String : JSONValue], completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
    
    func rotateToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
    
    func revokeToken(projectToken: String, completion: @escaping ((EmptyResult) -> Void)) {
        return
    }
}
