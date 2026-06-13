// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MusaveraKit",
    platforms: [
        .iOS("27.0"),
        .macOS("27.0"),
        .tvOS("27.0"),
        .watchOS("27.0"),
        .visionOS("27.0")
    ],
    products: [
        .library(name: "MusaveraKit", targets: ["MusaveraKit"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin",
            from: "1.5.0"
        )
    ],
    targets: [
        .target(
            name: "MusaveraKit",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MusaveraKitTests",
            dependencies: ["MusaveraKit"]
        )
    ]
)
