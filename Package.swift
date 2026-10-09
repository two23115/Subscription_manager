// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SubscriptionManager",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SubscriptionManager", targets: ["SubscriptionManagerApp"])
    ],
    targets: [
        .executableTarget(
            name: "SubscriptionManagerApp",
            path: "SubscriptionManagerApp"
        ),
        .testTarget(
            name: "SubscriptionManagerAppTests",
            dependencies: ["SubscriptionManagerApp"],
            path: "Tests/SubscriptionManagerAppTests"
        )
    ]
)
