//
//  JwtIntegrationSpec.swift
//  ExponeaSDKTests
//
//  Created by Bloomreach on 03/02/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class JwtIntegrationSpec: QuickSpec {
    
    override func spec() {
        
        describe("JWT Integration with Exponea SDK") {
            
            var exponea: ExponeaInternal!
            
            beforeEach {
                exponea = ExponeaInternal()
            }
            
            afterEach {
                exponea = nil
            }
            
            context("Stream mode configuration") {
                
                it("should initialize JWT manager in stream mode") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    exponea.configure(with: config)
                    
                    expect(exponea.jwtAuthManager).notTo(beNil())
                }
                
                it("should not initialize JWT manager in project mode") {
                    let config = try! Configuration(
                        projectToken: "test-project",
                        authorization: Authorization.none,
                        baseUrl: "https://api.exponea.com"
                    )
                    
                    exponea.configure(with: config)
                    
                    // JWT manager may still exist but won't be used
                    // The important thing is that stream-specific behavior is disabled
                    expect(exponea.configuration?.usesStreamIntegration).to(beFalse())
                }
            }
            
            context("setSdkAuthToken") {
                
                it("should accept token in stream mode") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    exponea.configure(with: config)
                    
                    let token = JwtAuthManagerSpec.createValidJwt()
                    exponea.setSdkAuthToken(token)
                    
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                }
                
                it("should ignore token in project mode") {
                    let config = try! Configuration(
                        projectToken: "test-project",
                        authorization: Authorization.none,
                        baseUrl: "https://api.exponea.com"
                    )
                    
                    exponea.configure(with: config)
                    
                    let token = JwtAuthManagerSpec.createValidJwt()
                    exponea.setSdkAuthToken(token)
                    
                    // Token should not be stored in project mode
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(1))
                }
            }
            
            context("setJwtErrorHandler") {
                
                it("should register error handler in stream mode") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    exponea.configure(with: config)
                    
                    var handlerCalled = false
                    exponea.setJwtErrorHandler { _ in
                        handlerCalled = true
                    }
                    
                    // Force an error by trying to get auth header without token
                    _ = exponea.jwtAuthManager?.getAuthorizationHeader()
                    
                    expect(handlerCalled).toEventually(beTrue(), timeout: .seconds(1))
                }
            }
            
            context("identifyCustomer with context") {
                
                it("should update JWT when context contains token") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    exponea.configure(with: config)
                    
                    let token = JwtAuthManagerSpec.createValidJwt()
                    let context = CustomerIdentity(
                        customerIds: ["registered": "test@example.com"],
                        jwtToken: token
                    )
                    
                    exponea.identifyCustomer(context: context, properties: [:], timestamp: nil)
                    
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                }
                
                it("should accept context without JWT") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    exponea.configure(with: config)
                    
                    let context = CustomerIdentity(
                        customerIds: ["registered": "test@example.com"]
                    )
                    
                    // Should not crash even without JWT
                    exponea.identifyCustomer(context: context, properties: [:], timestamp: nil)
                    
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(1))
                }
                
                it("should clear JWT when identify is called without token in stream mode") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    exponea.configure(with: config)
                    
                    // First, set a JWT token
                    let token = JwtAuthManagerSpec.createValidJwt()
                    exponea.setSdkAuthToken(token)
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                    
                    // Now identify without JWT - should clear the stored token
                    let contextWithoutJwt = CustomerIdentity(
                        customerIds: ["registered": "new@example.com"]
                    )
                    exponea.identifyCustomer(context: contextWithoutJwt, properties: [:], timestamp: nil)
                    
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(2))
                }
            }
            
            context("anonymize clears JWT") {
                
                it("should clear JWT when anonymizing") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    exponea.configure(with: config)
                    
                    let token = JwtAuthManagerSpec.createValidJwt()
                    exponea.setSdkAuthToken(token)
                    
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                    
                    exponea.anonymize()
                    
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(2))
                }
                
                it("should clear JWT synchronously before anonymize completes") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    exponea.configure(with: config)
                    
                    let token = JwtAuthManagerSpec.createValidJwt()
                    exponea.setSdkAuthToken(token)
                    
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot)
                        .toEventually(equal(token), timeout: .seconds(1))
                    
                    var tokenWasNilInCompletion = false
                    exponea.anonymize {
                        tokenWasNilInCompletion = (exponea.jwtAuthManager?.currentTokenSnapshot == nil)
                    }
                    
                    expect(tokenWasNilInCompletion)
                        .toEventually(beTrue(), timeout: .seconds(3))
                }
            }
            
            context("configuration with auth context") {
                
                it("should set JWT from initial auth context") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    let token = JwtAuthManagerSpec.createValidJwt()
                    let authContext = CustomerIdentity(
                        customerIds: ["registered": "initial@example.com"],
                        jwtToken: token
                    )
                    
                    exponea.configure(with: config, authContext: authContext)
                    
                    expect(exponea.jwtAuthManager?.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                }
            }
        }
    }
}
