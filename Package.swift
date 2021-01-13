// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ExponeaSDK",
    platforms: [
        .iOS(.v10)
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
    ],
    targets: [
        // Main library
        .target(
            name: "ExponeaSDK",
            dependencies: ["ExponeaSDKShared", "ExponeaSDKObjC"],
            path: "ExponeaSDK/ExponeaSDK"),
        // Notification extension library
        .target(
            name: "ExponeaSDK-Notifications",
            dependencies: ["ExponeaSDKShared"],
            path: "ExponeaSDK/ExponeaSDK-Notifications"),
        // Code shared between ExponeaSDK and ExponeaSDK-Notifications
        .target(
            name: "ExponeaSDKShared",
            dependencies: [],
            path: "ExponeaSDK/ExponeaSDKShared"),
        // ObjC code required by main library
        .target(
            name: "ExponeaSDKObjC",
            dependencies: [],
            path: "ExponeaSDK/ExponeaSDKObjC",
            publicHeadersPath: ".")
    ]
)
