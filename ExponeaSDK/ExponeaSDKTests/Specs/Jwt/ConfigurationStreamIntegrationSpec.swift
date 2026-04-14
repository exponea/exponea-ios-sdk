//
//  ConfigurationStreamIntegrationSpec.swift
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

class ConfigurationStreamIntegrationSpec: QuickSpec {
    
    override func spec() {
        
        describe("Configuration Stream Integration") {
            
            context("usesStreamIntegration") {
                
                it("should return true for stream configuration") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream-id",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    expect(config.usesStreamIntegration).to(beTrue())
                }
                
                it("should return false for project configuration") {
                    let config = try! Configuration(
                        projectToken: "test-project-token",
                        authorization: Authorization.none,
                        baseUrl: "https://api.exponea.com"
                    )
                    
                    expect(config.usesStreamIntegration).to(beFalse())
                }
                
                it("should return false for project settings configuration") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.ProjectSettings(
                            projectToken: "test-project-token",
                            authorization: Authorization.none,
                            baseUrl: "https://api.exponea.com",
                            projectMapping: nil
                        )
                    )
                    
                    expect(config.usesStreamIntegration).to(beFalse())
                }
            }
            
            context("streamId") {
                
                it("should return stream ID for stream configuration") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "my-stream-id",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    expect(config.streamId).to(equal("my-stream-id"))
                }
                
                it("should return nil for project configuration") {
                    let config = try! Configuration(
                        projectToken: "test-project-token",
                        authorization: Authorization.none,
                        baseUrl: "https://api.exponea.com"
                    )
                    
                    expect(config.streamId).to(beNil())
                }
            }
            
            context("streamIdentifierForJwt") {
                
                it("should return stream ID for stream configuration") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "jwt-stream-id",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    expect(config.streamIdentifierForJwt).to(equal("jwt-stream-id"))
                }
                
                it("should return engagement-only for project configuration") {
                    let config = try! Configuration(
                        projectToken: "jwt-project-token",
                        authorization: Authorization.none,
                        baseUrl: "https://api.exponea.com"
                    )
                    
                    expect(config.streamIdentifierForJwt).to(equal("engagement-only"))
                }
            }
            
            context("App Inbox URLs") {
                
                it("should return stream app inbox URL for stream configuration") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    let url = config.appInboxUrl
                    
                    expect(url).to(contain("test-stream"))
                    expect(url).to(contain("appinbox"))
                }
                
                it("should return project app inbox URL for project configuration") {
                    let config = try! Configuration(
                        projectToken: "test-project",
                        authorization: Authorization.none,
                        baseUrl: "https://api.exponea.com"
                    )
                    
                    let url = config.appInboxUrl
                    
                    expect(url).to(contain("test-project"))
                    expect(url).to(contain("appinbox"))
                }
                
                it("streamAppInboxUrl should be consistent") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "consistent-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )
                    
                    expect(config.streamAppInboxUrl).to(equal(config.streamAppInboxUrl))
                }
                
                it("projectAppInboxUrl should be consistent") {
                    let config = try! Configuration(
                        projectToken: "consistent-project",
                        authorization: Authorization.none,
                        baseUrl: "https://api.exponea.com"
                    )
                    
                    expect(config.projectAppInboxUrl).to(equal(config.projectAppInboxUrl))
                }
            }
            
            context("IntegrationSourceType convenience") {
                it("isStream should return true for stream type") {
                    let streamType = IntegrationSourceType.stream(streamId: "test-stream")
                    expect(streamType.isStream).to(beTrue())
                }
                it("isStream should return false for project type") {
                    let projectType = IntegrationSourceType.project(projectToken: "test-project")
                    expect(projectType.isStream).to(beFalse())
                }
            }
            
            context("mutualExponeaProject") {
                
                it("should return stream integration for stream configuration") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        )
                    )

                    let project = config.mutualExponeaProject

                    expect(project.integrationId).to(equal("test-stream"))
                }
                
                it("should return main project for project configuration") {
                    let config = try! Configuration(
                        projectToken: "test-project",
                        authorization: .token("test-auth"),
                        baseUrl: "https://api.exponea.com"
                    )
                    
                    let project = config.mutualExponeaProject
                    
                    expect(project.integrationId).to(equal("test-project"))
                }
            }
            
            context("advanced auth with stream mode") {
                
                it("should allow configuration with advancedAuthEnabled false in stream mode") {
                    expect {
                        try Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        ),
                            advancedAuthEnabled: false
                        )
                    }.notTo(throwError())
                }
                
                it("should allow configuration with advancedAuthEnabled true in stream mode but log warning") {
                    // This should not throw, but should log a warning
                    expect {
                        try Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "test-stream",
                            baseUrl: "https://api.exponea.com"
                        ),
                            advancedAuthEnabled: true
                        )
                    }.notTo(throwError())
                }
            }
        }
    }
}
