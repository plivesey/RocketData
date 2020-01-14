// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "RocketData",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "RocketData", targets: ["RocketData"]),
    ],
    dependencies: [
        .package(url: "https://github.com/plivesey/ConsistencyManager-iOS", .branch("master"))
    ],
    targets: [
        .target(
            name: "RocketData", 
            dependencies: ["ConsistencyManager"],
            path: "RocketData"
        ),
        .testTarget(
            name: "RocketDataTests",
            dependencies: ["RocketData", "ConsistencyManager"],
            path: "RocketDataTests"
        )
    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
