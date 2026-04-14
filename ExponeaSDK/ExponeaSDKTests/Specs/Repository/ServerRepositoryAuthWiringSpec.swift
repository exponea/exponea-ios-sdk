import Foundation
import Quick
import Nimble

@testable import ExponeaSDK
@testable import ExponeaSDKShared

private final class MockAuthProvider: NSObject, AuthorizationProviderType {
    private let token: String
    private let header: String?

    required override init() {
        self.token = "mock-token"
        self.header = "Bearer mock-token"
        super.init()
    }

    init(token: String, header: String? = nil) {
        self.token = token
        self.header = header ?? "Bearer \(token)"
        super.init()
    }

    func getAuthorizationToken() -> String? { token }
    func getAuthorizationHeader() -> String? { header }
}

final class ServerRepositoryAuthWiringSpec: QuickSpec {
    override func spec() {
        describe("ServerRepository auth wiring") {

            var streamConfig: Configuration!

            beforeEach {
                streamConfig = try! Configuration(
                    integrationConfig: Exponea.StreamSettings(
                        streamId: "test-stream",
                        baseUrl: "https://mock-base-url.com"
                    )
                )
            }

            context("makeRouter") {

                it("should propagate streamAuthProvider to RequestFactory") {
                    let repo = ServerRepository(configuration: streamConfig)
                    let mockProvider = MockAuthProvider(token: "jwt-token")
                    repo.streamAuthProvider = mockProvider

                    let factory = repo.makeRouter(for: .appInbox)

                    expect(factory.streamAuthProvider).toNot(beNil())
                    expect(factory.streamAuthProvider?.getAuthorizationToken()).to(equal("jwt-token"))
                }

                it("should propagate onAuthorizationError to RequestFactory") {
                    let repo = ServerRepository(configuration: streamConfig)
                    var errorCalled = false
                    repo.onAuthorizationError = { _, _, _ in errorCalled = true }

                    let factory = repo.makeRouter(for: .appInbox)

                    expect(factory.onAuthorizationError).toNot(beNil())
                    factory.onAuthorizationError?("test", 401, nil)
                    expect(errorCalled).to(beTrue())
                }

                it("should leave streamAuthProvider nil on RequestFactory when not set") {
                    let repo = ServerRepository(configuration: streamConfig)

                    let factory = repo.makeRouter(for: .appInbox)

                    expect(factory.streamAuthProvider).to(beNil())
                    expect(factory.onAuthorizationError).to(beNil())
                }

                it("should use default project from configuration when project is not specified") {
                    let repo = ServerRepository(configuration: streamConfig)

                    let factory = repo.makeRouter(for: .consents)

                    let path = try? factory.getPath()
                    expect(path).to(contain("test-stream"))
                }

                it("should use provided project when specified") {
                    let repo = ServerRepository(configuration: streamConfig)
                    let customProject = ExponeaIntegration(
                        baseUrl: "https://custom-url.com",
                        streamId: "custom-stream"
                    )

                    let factory = repo.makeRouter(for: .consents, project: customProject)

                    let path = try? factory.getPath()
                    expect(path).to(contain("custom-stream"))
                    expect(path).to(contain("custom-url.com"))
                }

                it("should produce a request with Authorization header when provider is set") {
                    let repo = ServerRepository(configuration: streamConfig)
                    let mockProvider = MockAuthProvider(token: "jwt-token", header: "Bearer jwt-token")
                    repo.streamAuthProvider = mockProvider

                    let factory = repo.makeRouter(for: .appInbox)
                    let request = try? factory.prepareRequest()

                    expect(request).toNot(beNil())
                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Bearer jwt-token"))
                }
            }

            context("Project mode with customAuthProvider") {

                var projectConfig: Configuration!

                beforeEach {
                    projectConfig = try! Configuration(
                        integrationConfig: Exponea.ProjectSettings(
                            projectToken: "test-project-token",
                            authorization: .token("static-token"),
                            baseUrl: "https://mock-base-url.com"
                        )
                    )
                    projectConfig.customAuthProvider = MockAuthProvider(
                        token: "jwt-custom-token",
                        header: "Bearer jwt-custom-token"
                    )
                }

                it("mainProject should use static Token authorization") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .consents, project: projectConfig.mainProject)
                    let request = try? factory.prepareRequest()

                    expect(request).toNot(beNil())
                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Token static-token"))
                }

                it("mutualExponeaProject should use Bearer JWT from customAuthProvider") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .consents)
                    let request = try? factory.prepareRequest()

                    expect(request).toNot(beNil())
                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Bearer jwt-custom-token"))
                }

                it("consents endpoint should use static Token auth via mainProject") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .consents, project: projectConfig.mainProject)
                    let request = try? factory.prepareRequest()

                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Token static-token"))
                }

                it("inAppMessages endpoint should use static Token auth via mainProject") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .inAppMessages, project: projectConfig.mainProject)
                    let request = try? factory.prepareRequest()

                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Token static-token"))
                }

                it("customerAttributes endpoint should use static Token auth via mainProject") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .customerAttributes, project: projectConfig.mainProject)
                    let request = try? factory.prepareRequest()

                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Token static-token"))
                }

                it("pushSelfCheck endpoint should use static Token auth via mainProject") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .pushSelfCheck, project: projectConfig.mainProject)
                    let request = try? factory.prepareRequest()

                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Token static-token"))
                }

                it("appInbox endpoint should use Bearer JWT via default mutualExponeaProject") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .appInbox)
                    let request = try? factory.prepareRequest()

                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Bearer jwt-custom-token"))
                }

                it("personalizedInAppContentBlocks should use Bearer JWT via default mutualExponeaProject") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .personalizedInAppContentBlocks)
                    let request = try? factory.prepareRequest()

                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Bearer jwt-custom-token"))
                }

                it("segmentation endpoint should use Bearer JWT via default mutualExponeaProject") {
                    let repo = ServerRepository(configuration: projectConfig)
                    let factory = repo.makeRouter(for: .segmentation(cookie: "test-cookie"))
                    let request = try? factory.prepareRequest()

                    let authHeader = request?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    expect(authHeader).to(equal("Bearer jwt-custom-token"))
                }
            }

            context("Project mode without customAuthProvider") {

                it("mainProject and default should produce the same Token auth") {
                    let config = try! Configuration(
                        integrationConfig: Exponea.ProjectSettings(
                            projectToken: "test-project-token",
                            authorization: .token("static-token"),
                            baseUrl: "https://mock-base-url.com"
                        )
                    )
                    let repo = ServerRepository(configuration: config)

                    let explicitFactory = repo.makeRouter(for: .consents, project: config.mainProject)
                    let defaultFactory = repo.makeRouter(for: .consents)

                    let explicitRequest = try? explicitFactory.prepareRequest()
                    let defaultRequest = try? defaultFactory.prepareRequest()

                    let explicitAuth = explicitRequest?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)
                    let defaultAuth = defaultRequest?.value(forHTTPHeaderField: Constants.Repository.headerAuthorization)

                    expect(explicitAuth).to(equal("Token static-token"))
                    expect(defaultAuth).to(equal("Token static-token"))
                }
            }

            context("clearAllDependencies teardown") {

                it("should nil out streamAuthProvider and onAuthorizationError after stopIntegration") {
                    let repo = ServerRepository(configuration: streamConfig)
                    repo.streamAuthProvider = MockAuthProvider(token: "will-be-cleared")
                    repo.onAuthorizationError = { _, _, _ in }

                    expect(repo.streamAuthProvider).toNot(beNil())
                    expect(repo.onAuthorizationError).toNot(beNil())

                    repo.streamAuthProvider = nil
                    repo.onAuthorizationError = nil

                    expect(repo.streamAuthProvider).to(beNil())
                    expect(repo.onAuthorizationError).to(beNil())
                }
            }
        }
    }
}

