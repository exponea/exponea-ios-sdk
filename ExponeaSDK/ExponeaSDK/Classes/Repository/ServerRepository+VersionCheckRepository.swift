//
//  ServerRepository+VersionCheckRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 25/04/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//


import Foundation

extension ServerRepository: VersionCheckRepository {

    var baseUrl: String { return "https://api.github.com/repos/exponea/%@/releases/latest" }

    func requestLastSDKVersion(
        completion: @escaping (Result<String>) -> Void
    ) {
        var gitHubProject: String
        if isReactNativeSDK() {
            gitHubProject = "exponea-react-native-sdk"
        } else if isFlutterSDK() {
            gitHubProject = "exponea-flutter-sdk"
        } else if isXamarinSDK() {
            gitHubProject = "exponea-xamarin-sdk"
        } else {
            gitHubProject = "exponea-ios-sdk"
        }
        var request = URLRequest(url: URL(string: String(format: baseUrl, gitHubProject))!)

        // Create the basic request
        request.httpMethod = "GET"
        request.addValue(Constants.Repository.contentType,
                         forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType,
                         forHTTPHeaderField: Constants.Repository.headerAccept)

        session
            .dataTask(with: request, completionHandler: handler(with: completion))
            .resume()
    }

    private func handler(
        with completion: @escaping ((Result<String>) -> Void)) -> ((Data?, URLResponse?, Error?) -> Void
        ) {
        return { (data, response, error) in
            // Check if we have any response at all
            guard let response = response else {
                completion(.failure(RepositoryError.connectionError))
                return
            }

            // Make sure we got the correct response type
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(RepositoryError.invalidResponse(response)))
                return
            }

            if let error = error {
                // handle server errors
                completion(.failure(error))
            } else if httpResponse.statusCode == 200, let data = data {
                do {
                    let jsonDecoder = JSONDecoder()
                    let object = try jsonDecoder.decode(GitHubReleaseResponse.self, from: data)
                    completion(.success(object.version))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}
