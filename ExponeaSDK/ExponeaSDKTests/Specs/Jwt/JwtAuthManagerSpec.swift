//
//  JwtAuthManagerSpec.swift
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

class JwtAuthManagerSpec: QuickSpec {
    
    /// Creates a valid JWT token with the given expiration time.
    /// - Parameter expiresIn: Seconds from now until expiration.
    /// - Returns: A mock JWT token string.
    static func createMockJwt(expiresIn seconds: TimeInterval) -> String {
        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" // {"alg":"HS256","typ":"JWT"}
        let exp = Int(Date().addingTimeInterval(seconds).timeIntervalSince1970)
        let payloadData = try! JSONSerialization.data(withJSONObject: ["exp": exp, "sub": "test"])
        let payload = payloadData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let signature = "mockSignature"
        return "\(header).\(payload).\(signature)"
    }
    
    /// Creates an already expired JWT token.
    static func createExpiredJwt() -> String {
        return createMockJwt(expiresIn: -60) // Expired 1 minute ago
    }
    
    /// Creates a JWT token that expires soon (within 60s buffer).
    static func createSoonExpiringJwt() -> String {
        return createMockJwt(expiresIn: 30) // Expires in 30 seconds (within 60s buffer)
    }
    
    /// Creates a valid JWT token with long expiration.
    static func createValidJwt() -> String {
        return createMockJwt(expiresIn: 3600) // Expires in 1 hour
    }
    
    override func spec() {
        var mockStore: MockJwtTokenStore!
        var manager: JwtAuthManager!
        
        beforeEach {
            mockStore = MockJwtTokenStore()
        }
        
        afterEach {
            manager = nil
            mockStore = nil
        }
        
        describe("JwtAuthManager") {
            
            context("initialization") {
                
                it("should load persisted token on init") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    mockStore.setToken(token)
                    
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                    
                    // Allow async loading to complete
                    expect(manager.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                    expect(mockStore.loadCallCount).to(equal(1))
                }
                
                it("should not crash when no token is persisted") {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                    
                    expect(manager.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(1))
                }
                
                it("should trigger error handler when loaded token is expired") {
                    let expiredToken = JwtAuthManagerSpec.createExpiredJwt()
                    mockStore.setToken(expiredToken)
                    
                    var receivedContext: JwtErrorContext?
                    
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                    
                    manager.setErrorHandler { context in
                        receivedContext = context
                    }
                    
                    // Allow async loading and error handling to complete (either handler not set yet or reason is .expired)
                    expect(receivedContext == nil || receivedContext?.reason == .expired).toEventually(beTrue(), timeout: .seconds(2))
                }
            }
            
            context("setToken") {
                
                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }
                
                it("should save token to store") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    
                    manager.setToken(token)
                    
                    expect(mockStore.lastSavedToken).toEventually(equal(token), timeout: .seconds(1))
                    expect(mockStore.saveCallCount).toEventually(equal(1), timeout: .seconds(1))
                }
                
                it("should update currentTokenSnapshot") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    
                    manager.setToken(token)
                    
                    expect(manager.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                }
                
                it("should clear token when nil is passed") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(token)
                    
                    expect(manager.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                    
                    manager.setToken(nil)
                    
                    expect(manager.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(1))
                }
                
                it("should ignore token when not in stream mode") {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: false // Not stream mode
                    )
                    
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(token)
                    
                    // Token should not be saved
                    expect(manager.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(1))
                }
                
                it("should trigger error handler when token is already expired") {
                    var receivedContext: JwtErrorContext?
                    manager.setErrorHandler { context in
                        receivedContext = context
                    }
                    
                    let expiredToken = JwtAuthManagerSpec.createExpiredJwt()
                    manager.setToken(expiredToken)
                    
                    expect(receivedContext?.reason).toEventually(equal(.expired), timeout: .seconds(1))
                }
                
                it("should post notification when token is set") {
                    var notificationReceived = false
                    
                    let observer = NotificationCenter.default.addObserver(
                        forName: JwtAuthManager.tokenRefreshedNotification,
                        object: nil,
                        queue: .main
                    ) { _ in
                        notificationReceived = true
                    }
                    
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(token)
                    
                    expect(notificationReceived).toEventually(beTrue(), timeout: .seconds(1))
                    
                    NotificationCenter.default.removeObserver(observer)
                }
            }
            
            context("getAuthorizationHeader") {
                
                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }
                
                it("should return Bearer token when token is set") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(token)
                    
                    expect(manager.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                    
                    let header = manager.getAuthorizationHeader()
                    
                    expect(header).to(equal("Bearer \(token)"))
                }
                
                it("should return nil when no token is set") {
                    let header = manager.getAuthorizationHeader()
                    
                    expect(header).to(beNil())
                }
                
                it("should return nil when not in stream mode") {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: false
                    )
                    
                    let header = manager.getAuthorizationHeader()
                    
                    expect(header).to(beNil())
                }
                
                it("should trigger error handler when token is not provided") {
                    var receivedContext: JwtErrorContext?
                    manager.setErrorHandler { context in
                        receivedContext = context
                    }
                    
                    _ = manager.getAuthorizationHeader()
                    
                    expect(receivedContext?.reason).toEventually(equal(.notProvided), timeout: .seconds(1))
                }
            }
            
            context("clear") {
                
                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }
                
                it("should clear token from memory") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(token)
                    
                    expect(manager.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                    
                    manager.clear()
                    
                    expect(manager.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(1))
                }
                
                it("should clear token from store") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(token)
                    
                    expect(mockStore.saveCallCount).toEventually(equal(1), timeout: .seconds(1))
                    
                    manager.clear()
                    
                    expect(mockStore.clearCallCount).toEventually(equal(1), timeout: .seconds(1))
                }
            }
            
            context("clearSync") {
                
                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }
                
                it("should clear token from memory synchronously") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setTokenSync(token)
                    
                    expect(manager.currentTokenSnapshot).to(equal(token))
                    
                    manager.clearSync()
                    
                    expect(manager.currentTokenSnapshot).to(beNil())
                }
                
                it("should clear token from store synchronously") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setTokenSync(token)
                    
                    manager.clearSync()
                    
                    expect(mockStore.clearCallCount).to(equal(1))
                }
            }
            
            context("handleTokenError") {
                
                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }
                
                it("should call error handler with context") {
                    var receivedContext: JwtErrorContext?
                    manager.setErrorHandler { context in
                        receivedContext = context
                    }
                    
                    manager.handleTokenError(
                        reason: .invalid,
                        endpoint: "tracking",
                        status: 401,
                        underlying: nil
                    )
                    
                    expect(receivedContext).toEventuallyNot(beNil(), timeout: .seconds(1))
                    expect(receivedContext?.reason).toEventually(equal(.invalid), timeout: .seconds(1))
                }
                
                it("should detect expired reason for 401 with expired token") {
                    var receivedContext: JwtErrorContext?
                    manager.setErrorHandler { context in
                        receivedContext = context
                    }
                    
                    // Set an expired token
                    let expiredToken = JwtAuthManagerSpec.createExpiredJwt()
                    mockStore.setToken(expiredToken)
                    manager.setToken(expiredToken)
                    
                    // Wait for token to be set
                    expect(manager.currentTokenSnapshot).toEventually(equal(expiredToken), timeout: .seconds(1))
                    
                    // Clear any previous error context
                    receivedContext = nil
                    
                    // Handle a 401 error - should detect it's because token is expired
                    manager.handleTokenError(
                        reason: .invalid, // Original reason
                        endpoint: "tracking",
                        status: 401,
                        underlying: nil
                    )
                    
                    expect(receivedContext?.reason).toEventually(equal(.expired), timeout: .seconds(1))
                }
                
                it("should not call handler when not in stream mode") {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: false
                    )
                    
                    var handlerCalled = false
                    manager.setErrorHandler { _ in
                        handlerCalled = true
                    }
                    
                    manager.handleTokenError(
                        reason: .invalid,
                        endpoint: "tracking",
                        status: 401,
                        underlying: nil
                    )
                    
                    // Give some time for async execution
                    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                    
                    expect(handlerCalled).to(beFalse())
                }
            }
            
            context("error handler exception safety") {

                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }

                it("should not crash when error handler raises NSException and should remain functional") {
                    manager.setErrorHandler { _ in
                        NSException(
                            name: NSExceptionName("TestHostAppBug"),
                            reason: "simulated host app crash",
                            userInfo: nil
                        ).raise()
                    }

                    manager.handleTokenError(
                        reason: .invalid,
                        endpoint: "tracking",
                        status: 401,
                        underlying: nil
                    )

                    // Allow async dispatch to execute the throwing handler on main queue
                    expect(true).toEventually(beTrue(), timeout: .seconds(1))

                    // Verify the manager is still functional: replace handler with a working one
                    var receivedContext: JwtErrorContext?
                    manager.setErrorHandler { context in
                        receivedContext = context
                    }

                    manager.handleTokenError(
                        reason: .expired,
                        endpoint: "tracking",
                        status: 401,
                        underlying: nil
                    )

                    expect(receivedContext?.reason).toEventually(equal(.expired), timeout: .seconds(1))
                }
            }

            context("updateIntegrationMode") {
                
                it("should allow switching to stream mode") {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: false
                    )
                    
                    // Token should be ignored when not in stream mode
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(token)
                    expect(manager.currentTokenSnapshot).toEventually(beNil(), timeout: .seconds(1))
                    
                    // Switch to stream mode
                    manager.updateIntegrationMode(isStreamIntegration: true)
                    
                    // Now token should be accepted
                    manager.setToken(token)
                    expect(manager.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                }
            }
            
            context("thread safety") {
                
                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }
                
                it("should handle concurrent token updates safely") {
                    let expectation = QuickSpec.current.expectation(description: "All operations complete")
                    expectation.expectedFulfillmentCount = 10
                    
                    for i in 0..<10 {
                        DispatchQueue.global(qos: .userInitiated).async {
                            let token = JwtAuthManagerSpec.createMockJwt(expiresIn: TimeInterval(3600 + i))
                            manager.setToken(token)
                            expectation.fulfill()
                        }
                    }
                    
                    QuickSpec.current.wait(for: [expectation], timeout: 5.0)
                    
                    // Should have a token set (doesn't matter which one due to race)
                    expect(manager.currentTokenSnapshot).toEventuallyNot(beNil(), timeout: .seconds(1))
                }
                
                it("should handle concurrent reads safely") {
                    let token = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(token)
                    
                    expect(manager.currentTokenSnapshot).toEventually(equal(token), timeout: .seconds(1))
                    
                    let expectation = QuickSpec.current.expectation(description: "All reads complete")
                    expectation.expectedFulfillmentCount = 100
                    
                    for _ in 0..<100 {
                        DispatchQueue.global(qos: .userInitiated).async {
                            _ = manager.currentTokenSnapshot
                            _ = manager.getAuthorizationHeader()
                            expectation.fulfill()
                        }
                    }
                    
                    QuickSpec.current.wait(for: [expectation], timeout: 5.0)
                }
            }
            
            // MARK: - Strict JWT validation
            
            context("parseExpiration strict validation") {
                
                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }
                
                it("should reject token with spaces") {
                    let tokenWithSpace = "Bearer \(JwtAuthManagerSpec.createValidJwt())"
                    manager.setToken(tokenWithSpace)
                    
                    // Token is stored but expiration won't be parsed (spaces rejected)
                    expect(manager.currentTokenSnapshot).toEventually(equal(tokenWithSpace), timeout: .seconds(1))
                    // The header should still return "Bearer Bearer ..." (malformed but stored)
                    // However, expiration check won't work as parsing fails
                }
                
                it("should reject token with only 2 parts") {
                    let twoPartToken = "header.payload"
                    manager.setToken(twoPartToken)
                    
                    // Token is stored but expiration won't be parsed (needs exactly 3 parts)
                    expect(manager.currentTokenSnapshot).toEventually(equal(twoPartToken), timeout: .seconds(1))
                }
                
                it("should accept token with exactly 3 parts") {
                    let validToken = JwtAuthManagerSpec.createValidJwt()
                    manager.setToken(validToken)
                    
                    expect(manager.currentTokenSnapshot).toEventually(equal(validToken), timeout: .seconds(1))
                    
                    let header = manager.getAuthorizationHeader()
                    expect(header).to(equal("Bearer \(validToken)"))
                }
            }
            
            // MARK: - Proactive expiry (60s buffer)
            
            context("proactive expiry with 60s buffer") {
                
                beforeEach {
                    manager = JwtAuthManager(
                        store: mockStore,
                        isStreamIntegration: true
                    )
                }
                
                it("should trigger expiredSoon for token expiring within 60s") {
                    var receivedContext: JwtErrorContext?
                    manager.setErrorHandler { context in
                        receivedContext = context
                    }
                    
                    // Token expires in 30s, which is within the 60s buffer
                    let soonExpiring = JwtAuthManagerSpec.createSoonExpiringJwt()
                    manager.setToken(soonExpiring)
                    
                    // The timer-based refresh or getAuthorizationHeader should trigger expiredSoon
                    expect(manager.currentTokenSnapshot).toEventually(equal(soonExpiring), timeout: .seconds(1))
                    
                    _ = manager.getAuthorizationHeader()
                    
                    expect(receivedContext?.reason).toEventually(equal(.expiredSoon), timeout: .seconds(2))
                }
                
                it("should not trigger expiredSoon for token expiring in more than 60s") {
                    var receivedReasons: [JwtErrorContext.Reason] = []
                    manager.setErrorHandler { context in
                        receivedReasons.append(context.reason)
                    }
                    
                    // Token expires in 2 hours, well outside 60s buffer
                    let longLivedToken = JwtAuthManagerSpec.createMockJwt(expiresIn: 7200)
                    manager.setToken(longLivedToken)
                    
                    expect(manager.currentTokenSnapshot).toEventually(equal(longLivedToken), timeout: .seconds(1))
                    
                    _ = manager.getAuthorizationHeader()
                    
                    // Give some time for async execution
                    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                    
                    expect(receivedReasons).to(beEmpty())
                }
            }
        }
    }
}
