// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RoundsImageKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "RoundsImageKit",
            targets: ["RoundsImageKit"]
        )
    ],
    targets: [
        .target(
            name: "RoundsImageKit",
            path: "Sources/RoundsImageKit"
        ),
        .testTarget(
            name: "RoundsImageKitTests",
            dependencies: ["RoundsImageKit"],
            path: "Tests/RoundsImageKitTests"
        )
    ]
)
