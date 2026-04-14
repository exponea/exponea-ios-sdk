//
//  ConnectionManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// The Server Repository class is responsible to manage all the requests for the Exponea API.
public final class ServerRepository {

    public var configuration: Configuration
    public let session = URLSession(configuration: .default)

    private let authLock = NSLock()
    private var _streamAuthProvider: AuthorizationProviderType?
    private var _onAuthorizationError: ((String, Int, Data?) -> Void)?

    /// Runtime auth provider for Stream JWT. Set by the main SDK at initialization.
    /// Thread-safe: all accesses are serialized through `authLock`.
    public var streamAuthProvider: AuthorizationProviderType? {
        get { authLock.lock(); defer { authLock.unlock() }; return _streamAuthProvider }
        set { authLock.lock(); defer { authLock.unlock() }; _streamAuthProvider = newValue }
    }

    /// Callback invoked when a 401/403 error is received from the server.
    /// Parameters: endpoint URL, HTTP status code, response data.
    /// Thread-safe: all accesses are serialized through `authLock`.
    public var onAuthorizationError: ((String, Int, Data?) -> Void)? {
        get { authLock.lock(); defer { authLock.unlock() }; return _onAuthorizationError }
        set { authLock.lock(); defer { authLock.unlock() }; _onAuthorizationError = newValue }
    }

    // Initialize the configuration for all HTTP requests
    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// Creates a RequestFactory pre-configured with the repository's auth provider and error handler.
    public func makeRouter(
        for route: Routes,
        project: (any ExponeaIntegrationType)? = nil
    ) -> RequestFactory {
        RequestFactory(
            exponeaIntegrationType: project ?? configuration.mutualExponeaProject,
            route: route,
            streamAuthProvider: streamAuthProvider,
            onAuthorizationError: onAuthorizationError
        )
    }

    // Gets and cancels all tasks
    public func cancelRequests() {
        session.getAllTasks { (tasks) in
            for task in tasks {
                task.cancel()
            }
        }
    }
}
