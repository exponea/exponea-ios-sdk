// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ExponeaSDK",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "ExponeaSDK",
            targets: ["ExponeaSDK"]),
        .library(
            name: "ExponeaSDK-Notifications",
            targets: ["ExponeaSDK-Notifications"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1")
    ],
    targets: [
        // Main library
        .target(
            name: "ExponeaSDK",
            dependencies: ["ExponeaSDKShared", "ExponeaSDKObjC"],
            path: "ExponeaSDK/ExponeaSDK",
            exclude: ["Supporting Files/Info.plist"],
            resources: [.copy("Supporting Files/PrivacyInfo.xcprivacy")]
        ),
        // Notification extension library
        .target(
            name: "ExponeaSDK-Notifications",
            dependencies: ["ExponeaSDKShared"],
            path: "ExponeaSDK/ExponeaSDK-Notifications",
            exclude: ["Supporting Files/Info.plist"],
            resources: [.copy("Supporting Files/PrivacyInfo.xcprivacy")]
        ),
        // Code shared between ExponeaSDK and ExponeaSDK-Notifications
        .target(
            name: "ExponeaSDKShared",
            dependencies: ["SwiftSoup"],
            path: "ExponeaSDK/ExponeaSDKShared",
            exclude: ["Supporting Files/Info.plist"]
        ),
        // ObjC code required by main library
        .target(
            name: "ExponeaSDKObjC",
            dependencies: [],
            path: "ExponeaSDK/ExponeaSDKObjC",
            exclude: ["Info.plist"],
            publicHeadersPath: ".")
    ]
)
