// swift-tools-version:5.1

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
            targets: ["ExponeaSDK"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ExponeaSDK",
            dependencies: [])
    ]
)
